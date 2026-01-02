param(
  [switch]$DoReset,
  [switch]$NoCommit,
  [switch]$NoPush
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host ''
Write-Host 'ROOTED: CANONICAL GATE V4 — normalize ALL function + DO + EXECUTE dollar blocks (ONE SHOT)' -ForegroundColor Cyan

$repoRoot = (git rev-parse --show-toplevel)
Set-Location $repoRoot

# --- Auto-stash if dirty (and restore at end) ---
$didStash = $false
$porcelain = (git status --porcelain)
if (-not [string]::IsNullOrWhiteSpace($porcelain)) {
  $stamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
  $msg = "ROOTED:auto-stash_before_migration_gate_v4_$stamp"
  Write-Host ("ROOTED: Auto-stashing dirty working tree: " + $msg) -ForegroundColor Yellow
  git stash push -u -m $msg | Out-Host
  $didStash = $true
}

$migrationsDir = Join-Path $repoRoot 'supabase/migrations'
if (!(Test-Path -LiteralPath $migrationsDir)) { throw "Missing migrations dir: $migrationsDir" }

$files = Get-ChildItem -LiteralPath $migrationsDir -Filter '*.sql' -File
if ($files.Count -eq 0) { throw "No .sql migrations found in: $migrationsDir" }

# -----------------------------
# Regexes
# -----------------------------
$reDoOpenAny    = [regex]::new('(?i)^\s*do\s+(\$\$|\$sql\$|\$do\$)\s*$', 'Multiline')
$reDoCloseAny   = [regex]::new('(?i)^\s*(\$\$|\$sql\$|\$do\$)\s*;\s*$', 'Multiline')
$reDoOpenDo     = [regex]::new('(?i)^\s*do\s+\$do\$\s*$', 'Multiline')
$reDoCloseDo    = [regex]::new('(?i)^\s*\$do\$\s*;\s*$', 'Multiline')

$reExecOpenAny  = [regex]::new('(?i)^\s*execute\s+(\$q\$|\$\$)\s*$', 'Multiline')
$reExecOpenQ    = [regex]::new('(?i)^\s*execute\s+\$q\$\s*$', 'Multiline')
$reExecCloseQ   = [regex]::new('(?i)^\s*\$q\$\s*;\s*$', 'Multiline')

$reCreateFnLine = [regex]::new('(?i)^\s*create\s+or\s+replace\s+function\b')
$reAsAnyLine    = [regex]::new('(?i)^\s*as\s+(\$\$|\$fn\$)\s*$', 'Multiline')
$reAsInlineAny  = [regex]::new('(?i)\bas\s+(\$\$|\$fn\$)\b')
$reFnCloseLine  = [regex]::new('(?i)^\s*(\$\$|\$fn\$)\s*;\s*$')
$reBareClose    = [regex]::new('(?i)^\s*(\$\$|\$fn\$)\s*$')

# Fast check: likely DO needs canonicalization
$reNeedsCanonicalDo = [regex]::new('(?i)\bexecute\s+(\$q\$|\$\$)\b|\$q\$|\bas\s+\$\$\b|\bas\s+\$fn\$\b', 'Multiline')

function NextMeaningfulIdx([System.Collections.Generic.List[string]]$lines, [int]$start, [int]$limitExclusive) {
  for ($i=$start; $i -lt $limitExclusive; $i++) {
    $t = $lines[$i].Trim()
    if ($t -eq '') { continue }
    if ($t -like '--*') { continue }
    return $i
  }
  return -1
}

# Split multi-function execute payloads (V3 behavior), but with stronger $fn$ close guarantee.
function SplitExecuteBlockIfMultipleFunctions(
  [System.Collections.Generic.List[string]]$lines,
  [int]$execOpenIdx,
  [int]$execCloseIdx
) {
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

    # Normalize AS $$ -> AS $fn$ and inline replacements
    for ($i=0; $i -lt $chunk.Count; $i++) {
      $t = $chunk[$i].Trim()
      if ($t -match '(?i)^as\s+\$\$\s*$') { $chunk[$i] = '    as $fn$' }
      else { $chunk[$i] = ($chunk[$i] -replace '(?i)\bas\s+\$\$\b', 'as $fn$') }
    }

    # Ensure $fn$; close exists at end of this function statement
    $hasClose = $false
    for ($i=$chunk.Count-1; $i -ge 0; $i--) {
      $t = $chunk[$i].Trim()
      if ($t -eq '$$')   { $chunk[$i] = '    $fn$';  $hasClose = $true; break }
      if ($t -eq '$$;')  { $chunk[$i] = '    $fn$;'; $hasClose = $true; break }
      if ($t -eq '$fn$') { $chunk[$i] = '    $fn$';  $hasClose = $true; break }
      if ($t -eq '$fn$;'){ $chunk[$i] = '    $fn$;'; $hasClose = $true; break }
    }
    if (-not $hasClose) { $chunk += '    $fn$;' }

    $newBlock.Add('  execute $q$') | Out-Null
    foreach ($cl in $chunk) { $newBlock.Add($cl) | Out-Null }
    $newBlock.Add('$q$;') | Out-Null
    $newBlock.Add('') | Out-Null
  }

  for ($i=$execCloseIdx; $i -ge $execOpenIdx; $i--) { $lines.RemoveAt($i) }
  for ($i=0; $i -lt $newBlock.Count; $i++) { $lines.Insert($execOpenIdx + $i, $newBlock[$i]) }
  return $true
}

# -----------------------------
# NORMALIZATION PASS
# -----------------------------
$changed = [System.Collections.Generic.List[string]]::new()

foreach ($f in $files) {
  $path = $f.FullName
  $arr = Get-Content -LiteralPath $path -ErrorAction Stop
  if ($null -eq $arr) { $arr = @() }
  if ($arr -isnot [System.Array]) { $arr = @($arr) }

  $lines = [System.Collections.Generic.List[string]]::new()
  foreach ($x in $arr) { [void]$lines.Add([string]$x) }

  $touched = $false

  # (A) Global function canonicalization (top-level + within execute):
  # - Any "as $$" => "as $fn$"
  # - Any "$$;" close that is likely function close => "$fn$;"
  for ($i=0; $i -lt $lines.Count; $i++) {
    $t = $lines[$i].Trim()

    # Normalize any standalone "as $$" line
    if ($t -match '(?i)^as\s+\$\$\s*$') { $lines[$i] = ($lines[$i] -replace '(?i)as\s+\$\$', 'as $fn$'); $touched = $true; continue }

    # Normalize inline "as $$"
    if ($lines[$i] -match '(?i)\bas\s+\$\$\b') { $lines[$i] = ($lines[$i] -replace '(?i)\bas\s+\$\$\b', 'as $fn$'); $touched = $true }

    # Normalize "$$;" to "$fn$;" ONLY if it looks like it is closing a function:
    # heuristic: previous meaningful line contains SQL and we're not inside a DO close line
    if ($t -eq '$$;') {
      $prev = NextMeaningfulIdx $lines 0 ($i) # we'll compute by scanning backward manually (fast enough)
      for ($p=$i-1; $p -ge 0; $p--) {
        $pt = $lines[$p].Trim()
        if ($pt -eq '' -or $pt -like '--*') { continue }
        $prev = $p
        break
      }
      if ($prev -ge 0) {
        # If above we recently saw "as $fn$" in the last ~200 lines, treat $$; as function close.
        $foundAsFn = $false
        for ($p=$i-1; $p -ge 0 -and $p -ge ($i-200); $p--) {
          if ($lines[$p] -match '(?i)\bas\s+\$fn\$\b') { $foundAsFn = $true; break }
        }
        if ($foundAsFn) { $lines[$i] = ($lines[$i] -replace '\$\$;', '$fn$;'); $touched = $true }
      }
    }
  }

  # (B) DO canonicalization + EXECUTE handling (including splits)
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
    $mustCanonicalDo = $reNeedsCanonicalDo.IsMatch($bodyText) -or $true  # V4: canonicalize ALL DO blocks

    if ($mustCanonicalDo) {
      if (-not $reDoOpenDo.IsMatch($lines[$i])) { $lines[$i] = 'do $do$'; $touched = $true }
      if (-not $reDoCloseDo.IsMatch($lines[$close])) { $lines[$close] = '$do$;'; $touched = $true }
    }

    # Inside DO: normalize execute blocks to execute $q$ ... $q$;
    for ($k=$i+1; $k -lt $close; $k++) {
      if (-not $reExecOpenAny.IsMatch($lines[$k])) { continue }

      if (-not $reExecOpenQ.IsMatch($lines[$k])) { $lines[$k] = '  execute $q$'; $touched = $true }

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

      # Split if multi-function payload
      $didSplit = SplitExecuteBlockIfMultipleFunctions -lines $lines -execOpenIdx $k -execCloseIdx $qEnd
      if ($didSplit) {
        $touched = $true
        # DO close index likely shifted; refind nearest $do$; close after original region
        # (safe: scan forward)
        $newClose = -1
        for ($z=$k; $z -lt $lines.Count; $z++) {
          if ($reDoCloseDo.IsMatch($lines[$z])) { $newClose = $z; break }
        }
        if ($newClose -ge 0) { $close = $newClose }
        continue
      }

      # Otherwise ensure any AS $$ / $$ closers within execute are normalized
      for ($m=$k+1; $m -lt $qEnd; $m++) {
        $t = $lines[$m].Trim()
        if ($t -match '(?i)^as\s+\$\$\s*$') { $lines[$m] = '    as $fn$'; $touched = $true; continue }
        if ($lines[$m] -match '(?i)\bas\s+\$\$\b') { $lines[$m] = ($lines[$m] -replace '(?i)\bas\s+\$\$\b', 'as $fn$'); $touched = $true; continue }
        if ($t -eq '$$')  { $lines[$m] = '    $fn$';  $touched = $true; continue }
        if ($t -eq '$$;') { $lines[$m] = '    $fn$;'; $touched = $true; continue }
      }

      $k = $qEnd
    }

    $i = $close
  }

  # (C) Ensure every "as $fn$" has a matching "$fn$;" close later.
  # We do a simple single-file scan: whenever we see "as $fn$", we must see a "$fn$;" before the next CREATE FUNCTION
  # or before end-of-file.
  for ($i=0; $i -lt $lines.Count; $i++) {
    if (-not ($lines[$i] -match '(?i)\bas\s+\$fn\$\b')) { continue }

    $foundClose = $false
    for ($j=$i+1; $j -lt $lines.Count; $j++) {
      $tj = $lines[$j].Trim()
      if ($reCreateFnLine.IsMatch($lines[$j])) { break }
      if ($tj -eq '$fn$;') { $foundClose = $true; break }
      if ($tj -eq '$$;') { # normalize and accept
        $lines[$j] = ($lines[$j] -replace '\$\$;', '$fn$;')
        $touched = $true
        $foundClose = $true
        break
      }
    }
    if (-not $foundClose) {
      # Insert a close right before the next CREATE FUNCTION or EOF
      $insertAt = $lines.Count
      for ($j=$i+1; $j -lt $lines.Count; $j++) {
        if ($reCreateFnLine.IsMatch($lines[$j])) { $insertAt = $j; break }
      }
      $lines.Insert($insertAt, '    $fn$;')
      $touched = $true
    }
  }

  # (D) Stray "$fn$;" closers with no AS $fn$ above: convert them to "$$;" (least destructive)
  for ($i=0; $i -lt $lines.Count; $i++) {
    if ($lines[$i].Trim() -ne '$fn$;') { continue }
    $hasAsFnAbove = $false
    for ($p=$i-1; $p -ge 0 -and $p -ge ($i-300); $p--) {
      if ($lines[$p] -match '(?i)\bas\s+\$fn\$\b') { $hasAsFnAbove = $true; break }
      if ($reCreateFnLine.IsMatch($lines[$p])) { break }
    }
    if (-not $hasAsFnAbove) { $lines[$i] = ($lines[$i] -replace '\$fn\$\;', '$$;'); $touched = $true }
  }

  if ($touched) {
    $marker = '-- ROOTED: CANONICAL_MIGRATION_GATE_V4 (one-shot)'
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
Write-Host 'ROOTED: Validating migrations (DO vs FN bodies vs EXECUTE pairing) ...' -ForegroundColor Cyan

$errors = [System.Collections.Generic.List[string]]::new()
function AddErr([string]$file, [int]$lineNo, [string]$msg) { [void]$errors.Add(("{0}:{1}: {2}" -f $file, $lineNo, $msg)) }

foreach ($f in $files) {
  $path = $f.FullName
  $arr = Get-Content -LiteralPath $path -ErrorAction Stop
  if ($null -eq $arr) { $arr = @() }
  if ($arr -isnot [System.Array]) { $arr = @($arr) }

  $doStack   = New-Object System.Collections.Stack
  $fnStack   = New-Object System.Collections.Stack
  $execStack = New-Object System.Collections.Stack

  for ($i=0; $i -lt $arr.Count; $i++) {
    $ln = [string]$arr[$i]
    $trim = $ln.Trim()

    if ($trim -match '(?i)^execute\s+(\$q\$|\$\$)\s*$') { $execStack.Push(@($Matches[1].ToLowerInvariant(), $i+1)); continue }
    if ($trim -match '(?i)^\$q\$\s*;\s*$') {
      if ($execStack.Count -eq 0) { AddErr $path ($i+1) '$q$; close without execute open' }
      else {
        $top = $execStack.Pop()
        if ($top[0] -ne '$q$') { AddErr $path ($i+1) ("execute opened with '{0}' at line {1} but closed with $q$;" -f $top[0], $top[1]) }
      }
      continue
    }

    if ($trim -match '(?i)\bas\s+(\$fn\$)\s*$') { $fnStack.Push(@('$fn$', $i+1)); continue }
    if ($trim -match '(?i)^do\s+(\$do\$)\s*$') { $doStack.Push(@('$do$', $i+1)); continue }

    if ($trim -match '(?i)^(\$fn\$|\$do\$)\s*;\s*$') {
      $tag = $Matches[1].ToLowerInvariant()

      if ($fnStack.Count -gt 0 -and $tag -eq '$fn$') { [void]$fnStack.Pop(); continue }
      if ($doStack.Count -gt 0 -and $tag -eq '$do$') { [void]$doStack.Pop(); continue }

      AddErr $path ($i+1) ("close '{0};' without corresponding open" -f $tag)
      continue
    }
  }

  while ($execStack.Count -gt 0) { $top = $execStack.Pop(); AddErr $path $top[1] ("execute open '{0}' not closed with $q$;" -f $top[0]) }
  while ($fnStack.Count -gt 0)   { $top = $fnStack.Pop();   AddErr $path $top[1] ("function body open '{0}' not closed" -f $top[0]) }
  while ($doStack.Count -gt 0)   { $top = $doStack.Pop();   AddErr $path $top[1] ("do open '{0}' not closed" -f $top[0]) }

  $text = ($arr -join "`n")
  if ($text -match '(?is)\bas\s+\$\$\b') { AddErr $path 1 "Found 'as $$' still present (must be 'as $fn$')." }
  if ($text -match '(?is)^\s*do\s+(\$\$|\$sql\$)\s*$' -and $text -notmatch '(?is)^\s*do\s+\$do\$\s*$') { AddErr $path 1 "Found non-canonical DO tag (must be do $do$)." }
}

if ($errors.Count -gt 0) {
  Write-Host ''
  Write-Host ('ROOTED: VALIDATION FAILED ({0} issue(s)) — refusing to reset until clean.' -f $errors.Count) -ForegroundColor Red
  $errors | ForEach-Object { Write-Host (' - ' + $_) -ForegroundColor Red }
  throw 'ROOTED: Migration gate failed validation.'
}

Write-Host 'ROOTED: Validation OK.' -ForegroundColor Green

# -----------------------------
# Commit/push (only if changes)
# -----------------------------
$pending = (git status --porcelain)
if (-not [string]::IsNullOrWhiteSpace($pending)) {
  if (-not $NoCommit) {
    git add $migrationsDir | Out-Host
    git add (Join-Path $repoRoot 'scripts/ROOTED_CANONICAL_MIGRATION_NORMALIZE_VALIDATE_GATE_V4.ps1') 2>$null | Out-Host
    git commit -m 'fix(migrations): canonical gate V4 (normalize ALL DO + function $fn$ bodies + execute $q$ blocks) (ONE SHOT)' | Out-Host
    if (-not $NoPush) { git push | Out-Host } else { Write-Host 'ROOTED: NoPush set — skipping git push.' -ForegroundColor DarkGray }
  } else {
    Write-Host 'ROOTED: NoCommit set — leaving changes uncommitted.' -ForegroundColor Yellow
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