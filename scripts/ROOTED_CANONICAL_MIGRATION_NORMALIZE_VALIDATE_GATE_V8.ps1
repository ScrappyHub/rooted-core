param(
  [switch]$DoReset,
  [switch]$NoCommit,
  [switch]$NoPush
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host ''
Write-Host 'ROOTED: CANONICAL GATE V6 â€” canonical DO $do$, EXECUTE $q$, FN bodies $fn$ (parse-safe / StrictMode-safe)' -ForegroundColor Cyan

$repoRoot = (git rev-parse --show-toplevel)
Set-Location $repoRoot

# --- Auto-stash if dirty (and restore at end) ---
$didStash = $false
$porcelain = (git status --porcelain)
if (-not [string]::IsNullOrWhiteSpace($porcelain)) {
  $stamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
  $msg = "ROOTED:auto-stash_before_migration_gate_v6_$stamp"
  Write-Host ("ROOTED: Auto-stashing dirty working tree: " + $msg) -ForegroundColor Yellow
  git stash push -u -m $msg | Out-Host
  $didStash = $true
}

$migrationsDir = Join-Path $repoRoot 'supabase/migrations'
if (!(Test-Path -LiteralPath $migrationsDir)) { throw "Missing migrations dir: $migrationsDir" }

$files = Get-ChildItem -LiteralPath $migrationsDir -Filter '*.sql' -File
if ($files.Count -eq 0) { throw "No .sql migrations found in: $migrationsDir" }

# Canonical tags (single-quoted so StrictMode never tries to read $do/$fn/$q variables)
$TAG_DO = '$do$'
$TAG_Q  = '$q$'
$TAG_FN = '$fn$'

# --- Regexes ---
$reDoOpenAny  = [regex]::new('(?i)^\s*do\s+(\$\$|\$sql\$|\$do\$)\s*$', 'Multiline')
$reDoCloseAny = [regex]::new('(?i)^\s*(\$\$|\$sql\$|\$do\$)\s*;\s*$', 'Multiline')

$reDoOpenDo   = [regex]::new('(?i)^\s*do\s+\$do\$\s*$', 'Multiline')
$reDoCloseDo  = [regex]::new('(?i)^\s*\$do\$\s*;\s*$', 'Multiline')

$reExecOpenAny = [regex]::new('(?i)^\s*execute\s+(\$q\$|\$\$)\s*$', 'Multiline')
$reExecOpenQ   = [regex]::new('(?i)^\s*execute\s+\$q\$\s*$', 'Multiline')
$reExecCloseQ  = [regex]::new('(?i)^\s*\$q\$\s*;\s*$', 'Multiline')

$reCreateFnLine = [regex]::new('(?i)^\s*create\s+or\s+replace\s+function\b')
$reAsLineAny     = [regex]::new('(?i)^\s*as\s+(\$\$|\$fn\$)\s*$', 'Multiline')  # line: as $$ or as $fn$
$reAsInlineDollars = [regex]::new('(?i)\bas\s+\$\$\b')
$reFnCloseBare = [regex]::new('(?i)^\s*(\$\$|\$fn\$)\s*$') # $$ or $fn$ (NO semicolon)
$reFnCloseWithSemi = [regex]::new('(?i)^\s*(\$\$|\$fn\$)\s*;\s*$') # $$; or $fn$;

$reNeedsCanonicalDo = [regex]::new('(?i)\bexecute\s+(\$q\$|\$\$)\b|\$q\$|\bas\s+\$\$\b|\bas\s+\$fn\$\b', 'Multiline')

function NormalizeFnChunk([string[]]$chunk) {
  # Convert AS $$ -> AS $fn$ ; convert $$ -> $fn$ (bare close, no semicolon)
  $out = New-Object System.Collections.Generic.List[string]
  foreach ($ln in $chunk) {
    $t = $ln.Trim()
    if ($t -match '(?i)^as\s+\$\$\s*$') {
      $out.Add('    as $fn$') | Out-Null
      continue
    }
    if ($reAsInlineDollars.IsMatch($ln)) {
      $out.Add(($ln -replace '(?i)\bas\s+\$\$\b', 'as $fn$')) | Out-Null
      continue
    }
    if ($t -eq '$$') {
      $out.Add('    $fn$') | Out-Null
      continue
    }
    if ($t -eq '$$;') {
      # if someone wrote $$; we canonicalize to bare close + add separate ; later if needed
      $out.Add('    $fn$') | Out-Null
      continue
    }
    $out.Add($ln) | Out-Null
  }

  # Ensure we have a bare $fn$ close somewhere after "as $fn$"
  $hasAs = $false
  $hasClose = $false
  for ($i=0; $i -lt $out.Count; $i++) {
    if ($out[$i].Trim() -match '(?i)^as\s+\$fn\$\s*$') { $hasAs = $true }
    if ($out[$i].Trim() -eq '$fn$') { $hasClose = $true }
  }

  if ($hasAs -and -not $hasClose) {
    $out.Add('    $fn$') | Out-Null
  }

  return ,$out.ToArray()
}

function SplitExecuteBlockIfMultipleFunctions([System.Collections.Generic.List[string]]$lines, [int]$execOpenIdx, [int]$execCloseIdx) {
  $starts = New-Object System.Collections.Generic.List[int]
  for ($i=$execOpenIdx+1; $i -lt $execCloseIdx; $i++) {
    if ($reCreateFnLine.IsMatch($lines[$i])) { [void]$starts.Add($i) }
  }
  if ($starts.Count -le 1) { return $false }

  $newBlock = New-Object System.Collections.Generic.List[string]

  for ($s=0; $s -lt $starts.Count; $s++) {
    $startIdx = $starts[$s]
    $endIdx = if ($s -lt $starts.Count-1) { $starts[$s+1]-1 } else { $execCloseIdx-1 }

    $chunk = @()
    for ($i=$startIdx; $i -le $endIdx; $i++) { $chunk += $lines[$i] }

    $chunk = NormalizeFnChunk -chunk $chunk

    # wrap in execute $q$ ... $q$;
    $newBlock.Add('  execute $q$') | Out-Null
    foreach ($cl in $chunk) { $newBlock.Add($cl) | Out-Null }
    $newBlock.Add('$q$;') | Out-Null
    $newBlock.Add('') | Out-Null
  }

  for ($i=$execCloseIdx; $i -ge $execOpenIdx; $i--) { $lines.RemoveAt($i) }
  for ($i=0; $i -lt $newBlock.Count; $i++) { $lines.Insert($execOpenIdx + $i, $newBlock[$i]) }

  return $true
}

$changed = [System.Collections.Generic.List[string]]::new()

foreach ($f in $files) {
  $path = $f.FullName
  $arr = Get-Content -LiteralPath $path -ErrorAction Stop
  if ($null -eq $arr) { $arr = @() }
  if ($arr -isnot [System.Array]) { $arr = @($arr) }

  $lines = [System.Collections.Generic.List[string]]::new()
  foreach ($x in $arr) { [void]$lines.Add([string]$x) }

  $touched = $false

  for ($i=0; $i -lt $lines.Count; $i++) {
    if (-not $reDoOpenAny.IsMatch($lines[$i])) { continue }

    # find DO close
    $close = -1
    for ($j=$i+1; $j -lt $lines.Count; $j++) {
      if ($reDoCloseAny.IsMatch($lines[$j])) { $close = $j; break }
      if ($j -gt $i+1 -and $reDoOpenAny.IsMatch($lines[$j])) { break }
    }
    if ($close -lt 0) { continue }

    $bodyText = ''
    if ($close -gt $i+1) { $bodyText = ($lines[($i+1)..($close-1)] -join "`n") }
    $mustCanonicalDo = $reNeedsCanonicalDo.IsMatch($bodyText)

    if ($mustCanonicalDo) {
      if (-not $reDoOpenDo.IsMatch($lines[$i])) { $lines[$i] = 'do $do$'; $touched = $true }
      if (-not $reDoCloseDo.IsMatch($lines[$close])) { $lines[$close] = '$do$;'; $touched = $true }
    }

    if ($mustCanonicalDo) {
      for ($k=$i+1; $k -lt $close; $k++) {
        if (-not $reExecOpenAny.IsMatch($lines[$k])) { continue }

        if (-not $reExecOpenQ.IsMatch($lines[$k])) { $lines[$k] = '  execute $q$'; $touched = $true }

        # find $q$; close, else insert before DO close
        $qEnd = -1
        for ($m=$k+1; $m -lt $close; $m++) {
          if ($reExecCloseQ.IsMatch($lines[$m])) { $qEnd = $m; break }
          if ($reExecOpenAny.IsMatch($lines[$m])) { break }
        }
        if ($qEnd -lt 0) {
          $lines.Insert($close, '$q$;')
          $close++
          $qEnd = $close - 1
          $touched = $true
        }

        # split multi-function execute blocks
        $didSplit = SplitExecuteBlockIfMultipleFunctions -lines $lines -execOpenIdx $k -execCloseIdx $qEnd
        if ($didSplit) { $touched = $true; break }

        # otherwise normalize fn chunk inside single execute payload
        $payload = @()
        for ($m=$k+1; $m -lt $qEnd; $m++) { $payload += $lines[$m] }
        $payload2 = NormalizeFnChunk -chunk $payload
        if ($payload2.Count -ne $payload.Count -or ($payload2 -join "`n") -ne ($payload -join "`n")) {
          # write back
          $idx = 0
          for ($m=$k+1; $m -lt $qEnd; $m++) { $lines[$m] = $payload2[$idx]; $idx++ }
          $touched = $true
        }

        $k = $qEnd
      }
    }

    $i = $close
  }

  if ($touched) {
    $marker = '-- ROOTED: CANONICAL_MIGRATION_GATE_V6 (one-shot)'
    if ($lines.Count -gt 0 -and ($lines[0] -ne $marker)) { $lines.Insert(0, $marker) }
    [IO.File]::WriteAllText($path, ($lines -join "`r`n"), (New-Object System.Text.UTF8Encoding($false)))
    [void]$changed.Add($path)
  }
}

Write-Host ("ROOTED: Normalization touched {0} migration(s)." -f $changed.Count) -ForegroundColor Green
if ($changed.Count -gt 0) { ($changed | Sort-Object -Unique) | ForEach-Object { Write-Host (" + " + $_) } }

# -----------------------------
# VALIDATION (DO/FN/EXEC stacks)
# -----------------------------
Write-Host ''
Write-Host ''
Write-Host 'ROOTED: Validating migrations (EXECUTE $q$ pairing + payload safety) ...' -ForegroundColor Cyan

$errors = [System.Collections.Generic.List[string]]::new()
function AddErr([string]$file, [int]$lineNo, [string]$msg) { [void]$errors.Add(('{0}:{1}: {2}' -f $file, $lineNo, $msg)) }

foreach ($f in $files) {
  $path = $f.FullName
  $arr = Get-Content -LiteralPath $path -ErrorAction Stop
  if ($null -eq $arr) { $arr = @() }
  if ($arr -isnot [System.Array]) { $arr = @($arr) }

  $execStack = New-Object System.Collections.Stack
  $inExec = $false

  for ($i=0; $i -lt $arr.Count; $i++) {
    $ln = [string]$arr[$i]
    $trim = $ln.Trim()

    if ($trim -match '(?i)^execute\s+(\$q\$|\\$\$)\s*$') {
      $tag = $Matches[1].ToLowerInvariant()
      $execStack.Push(@($tag, $i+1))
      $inExec = $true
      if ($tag -ne '$q$') {
        AddErr $path ($i+1) ("execute opened with '{0}' (must be execute $q$)" -f $tag)
      }
      continue
    }

    if ($trim -match '(?i)^\$q\$\s*;\s*$') {
      if ($execStack.Count -eq 0) {
        AddErr $path ($i+1) '$q$; close without execute open'
      } else {
        $top = $execStack.Pop()
        if ($top[0] -ne '$q$') {
          AddErr $path ($i+1) ("execute opened with '{0}' at line {1} but closed with $q$;" -f $top[0], $top[1])
        }
      }
      $inExec = ($execStack.Count -gt 0)
      continue
    }

    if ($inExec) {
      if ($trim -match '^\\$\$\s*;?\s*$') {
        AddErr $path ($i+1) 'Found "}" inside execute $q$ payload (invalid). Use $fn$ for function bodies; $q$ only for execute wrapper.'
        continue
      }
      if ($trim -match '(?i)\bas\s+\\$\$\b') {
        AddErr $path ($i+1) "Found 'as }' inside execute $q$ payload (invalid). Must be 'as $fn$' + '$fn$;'"
        continue
      }
      if ($trim -eq '$\$;') {
        AddErr $path ($i+1) 'Found "};" inside execute $q$ payload (invalid). Must close function bodies with "$fn$;"'
        continue
      }
    }
  }

  while ($execStack.Count -gt 0) {
    $top = $execStack.Pop()
    AddErr $path $top[1] ("execute open '{0}' not closed with $q$;" -f $top[0])
  }
}

if ($errors.Count -gt 0) {
  Write-Host ''
  Write-Host (('ROOTED: VALIDATION FAILED ({0} issue(s)) — refusing to reset until clean.' -f $errors.Count)) -ForegroundColor Red
  $errors | ForEach-Object { Write-Host (' - ' + $_) -ForegroundColor Red }
  throw 'ROOTED: Migration gate failed validation.'
}

Write-Host 'ROOTED: Validation OK.' -ForegroundColor Green

# Commit/push (only if changes)
$pending = (git status --porcelain)
if (-not [string]::IsNullOrWhiteSpace($pending)) {
  if (-not $NoCommit) {
    git add $migrationsDir | Out-Host
    git add (Join-Path $repoRoot 'scripts/ROOTED_CANONICAL_MIGRATION_NORMALIZE_VALIDATE_GATE_V6.ps1') 2>$null | Out-Host
    git commit -m 'fix(migrations): canonical gate V6 (StrictMode-safe $do$/$q$/$fn$ handling + split multi-function execute blocks)' | Out-Host
    if (-not $NoPush) { git push | Out-Host } else { Write-Host 'ROOTED: NoPush set â€” skipping git push.' -ForegroundColor DarkGray }
  } else {
    Write-Host 'ROOTED: NoCommit set â€” leaving changes uncommitted.' -ForegroundColor Yellow
  }
} else {
  Write-Host 'ROOTED: No git changes to commit.' -ForegroundColor DarkGray
}

if ($didStash) {
  Write-Host 'ROOTED: Restoring auto-stash (git stash pop)...' -ForegroundColor Yellow
  git stash pop | Out-Host
}

if ($DoReset) {
  Write-Host ''
  Write-Host 'ROOTED: Running supabase db reset --debug (explicit -DoReset)...' -ForegroundColor Cyan
  supabase db reset --debug | Out-Host
} else {
  Write-Host ''
  Write-Host 'ROOTED: Skipping supabase db reset (run with -DoReset to execute).' -ForegroundColor DarkGray
}
