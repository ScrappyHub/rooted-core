param(
  [switch]$DoReset,
  [switch]$NoCommit,
  [switch]$NoPush
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Literal dollar-tags for messages (avoid PowerShell $var interpolation accidents)
$LIT_DO = '$do

Write-Host ''
Write-Host 'ROOTED: CANONICAL GATE V5 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â canonical DO $do$, EXECUTE $q$, and FUNCTION bodies as $fn$ ... $fn$ (NO semicolon)' -ForegroundColor Cyan

$repoRoot = (git rev-parse --show-toplevel)
Set-Location $repoRoot

# --- Auto-stash if dirty (and restore at end) ---
$didStash = $false
$porcelain = (git status --porcelain)
if (-not [string]::IsNullOrWhiteSpace($porcelain)) {
  $stamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
  $msg = "ROOTED:auto-stash_before_migration_gate_v5_$stamp"
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
$reAsLine       = [regex]::new('(?i)^\s*as\s+(\$\$|\$fn\$)\s*$', 'Multiline')
$reAsInline     = [regex]::new('(?i)\bas\s+(\$\$|\$fn\$)\b')
$reFnCloseBare  = [regex]::new('(?i)^\s*(\$\$|\$fn\$)\s*$')      # $$ or $fn$
$reFnCloseSemi  = [regex]::new('(?i)^\s*(\$\$|\$fn\$)\s*;\s*$')  # $$; or $fn$;  (we will heal to bare)

$reLanguageLine = [regex]::new('(?i)^\s*language\b')

function NextMeaningfulIdx([System.Collections.Generic.List[string]]$lines, [int]$start, [int]$limitExclusive) {
  for ($i=$start; $i -lt $limitExclusive; $i++) {
    $t = $lines[$i].Trim()
    if ($t -eq '') { continue }
    if ($t -like '--*') { continue }
    return $i
  }
  return -1
}

function PrevMeaningfulIdx([System.Collections.Generic.List[string]]$lines, [int]$startInclusive) {
  for ($i=$startInclusive; $i -ge 0; $i--) {
    $t = $lines[$i].Trim()
    if ($t -eq '') { continue }
    if ($t -like '--*') { continue }
    return $i
  }
  return -1
}

function EnsureEndsWithSemicolon([string]$line) {
  if ($line.TrimEnd() -match ';\s*$') { return $line }
  return ($line + ';')
}

# Split multi-function execute payloads into multiple execute blocks.
# V5 RULE: function body closes with $fn$ (bare), and statement ends on LANGUAGE ...;
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

    # Normalize AS $$ -> AS $fn$
    for ($i=0; $i -lt $chunk.Count; $i++) {
      $t = $chunk[$i].Trim()
      if ($t -match '(?i)^as\s+\$\$\s*$') { $chunk[$i] = '    as $fn$' }
      else { $chunk[$i] = ($chunk[$i] -replace '(?i)\bas\s+\$\$\b', 'as $fn$') }
    }

    # Normalize any close delimiter variants to "$fn$" (bare)
    for ($i=0; $i -lt $chunk.Count; $i++) {
      $t = $chunk[$i].Trim()
      if ($t -eq '$$')   { $chunk[$i] = '    $fn$' }
      if ($t -eq '$$;')  { $chunk[$i] = '    $fn$' }
      if ($t -eq '$fn$;'){ $chunk[$i] = '    $fn$' }
    }

    # Ensure there is a $fn$ close somewhere after "as $fn$"
    $hasAs = $false
    $hasClose = $false
    for ($i=0; $i -lt $chunk.Count; $i++) {
      if ($chunk[$i] -match '(?i)^\s*as\s+\$fn\$\s*$') { $hasAs = $true }
      if ($hasAs -and $chunk[$i].Trim() -eq '$fn$') { $hasClose = $true; break }
    }
    if ($hasAs -and -not $hasClose) {
      $chunk += '    $fn$'
    }

    # Ensure LANGUAGE line exists and ends with semicolon inside the statement
    $foundLang = $false
    for ($i=0; $i -lt $chunk.Count; $i++) {
      if ($reLanguageLine.IsMatch($chunk[$i])) {
        $chunk[$i] = EnsureEndsWithSemicolon $chunk[$i]
        $foundLang = $true
        break
      }
    }
    # If language is missing entirely, we do NOT invent it ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â but we leave chunk as-is.
    # (You likely already have it; this just avoids breaking.)
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

  # (1) Canonicalize AS $$ -> AS $fn$ globally (safe)
  for ($i=0; $i -lt $lines.Count; $i++) {
    $t = $lines[$i].Trim()
    if ($t -match '(?i)^as\s+\$\$\s*$') { $lines[$i] = ($lines[$i] -replace '(?i)as\s+\$\$', 'as $fn$'); $touched = $true; continue }
    if ($lines[$i] -match '(?i)\bas\s+\$\$\b') { $lines[$i] = ($lines[$i] -replace '(?i)\bas\s+\$\$\b', 'as $fn$'); $touched = $true }
  }

  # (2) Heal any "$fn$;" that would break CREATE FUNCTION (typically followed by LANGUAGE)
  for ($i=0; $i -lt $lines.Count; $i++) {
    if ($lines[$i].Trim() -ne '$fn$;') { continue }
    $n = NextMeaningfulIdx $lines ($i+1) $lines.Count
    if ($n -ge 0 -and $reLanguageLine.IsMatch($lines[$n])) {
      $lines[$i] = '    $fn$'
      $touched = $true
    } else {
      # Even if not followed by language, canonical delimiter is bare
      $lines[$i] = '    $fn$'
      $touched = $true
    }
  }
  for ($i=0; $i -lt $lines.Count; $i++) {
    if ($lines[$i].Trim() -ne '$$;') { continue }
    # treat $$; as a delimiter line and canonicalize to $fn$ (bare) ONLY if we're in a function-ish region
    $lines[$i] = '    $fn$'
    $touched = $true
  }

  # (3) Canonicalize DO blocks to do $do$ ... $do$; and normalize execute $q$ blocks inside
  for ($i=0; $i -lt $lines.Count; $i++) {
    if (-not $reDoOpenAny.IsMatch($lines[$i])) { continue }

    $close = -1
    for ($j=$i+1; $j -lt $lines.Count; $j++) {
      if ($reDoCloseAny.IsMatch($lines[$j])) { $close = $j; break }
      if ($j -gt $i+1 -and $reDoOpenAny.IsMatch($lines[$j])) { break }
    }
    if ($close -lt 0) { continue }

    if (-not $reDoOpenDo.IsMatch($lines[$i])) { $lines[$i] = 'do $do$'; $touched = $true }
    if (-not $reDoCloseDo.IsMatch($lines[$close])) { $lines[$close] = '$do$;'; $touched = $true }

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

      $didSplit = SplitExecuteBlockIfMultipleFunctions -lines $lines -execOpenIdx $k -execCloseIdx $qEnd
      if ($didSplit) {
        $touched = $true
        # refind do close safely
        for ($z=$k; $z -lt $lines.Count; $z++) { if ($reDoCloseDo.IsMatch($lines[$z])) { $close = $z; break } }
        continue
      }

      # normalize payload delimiters inside execute: $$ / $$; / $fn$; => $fn$
      for ($m=$k+1; $m -lt $qEnd; $m++) {
        $t = $lines[$m].Trim()
        if ($t -match '(?i)^as\s+\$\$\s*$') { $lines[$m] = '    as $fn$'; $touched = $true; continue }
        if ($lines[$m] -match '(?i)\bas\s+\$\$\b') { $lines[$m] = ($lines[$m] -replace '(?i)\bas\s+\$\$\b', 'as $fn$'); $touched = $true; continue }
        if ($t -eq '$$' -or $t -eq '$$;' -or $t -eq '$fn$;') { $lines[$m] = '    $fn$'; $touched = $true; continue }
      }

      $k = $qEnd
    }

    $i = $close
  }

  # (4) For each "as $fn$" ensure we have a later "$fn$" delimiter before the next CREATE FUNCTION
  for ($i=0; $i -lt $lines.Count; $i++) {
    if (-not ($lines[$i].Trim() -match '(?i)^as\s+\$fn\$\s*$')) { continue }

    $foundClose = $false
    for ($j=$i+1; $j -lt $lines.Count; $j++) {
      if ($reCreateFnLine.IsMatch($lines[$j])) { break }
      $tj = $lines[$j].Trim()
      if ($tj -eq '$fn$') { $foundClose = $true; break }
      if ($tj -eq '$fn$;') { $lines[$j] = '    $fn$'; $touched = $true; $foundClose = $true; break }
      if ($tj -eq '$$' -or $tj -eq '$$;') { $lines[$j] = '    $fn$'; $touched = $true; $foundClose = $true; break }
    }
    if (-not $foundClose) {
      $insertAt = $lines.Count
      for ($j=$i+1; $j -lt $lines.Count; $j++) { if ($reCreateFnLine.IsMatch($lines[$j])) { $insertAt = $j; break } }
      $lines.Insert($insertAt, '    $fn$')
      $touched = $true
    }
  }

  # (5) Ensure LANGUAGE lines end with semicolon (harmless and helps completeness)
  for ($i=0; $i -lt $lines.Count; $i++) {
    if ($reLanguageLine.IsMatch($lines[$i])) {
      $nl = EnsureEndsWithSemicolon $lines[$i]
      if ($nl -ne $lines[$i]) { $lines[$i] = $nl; $touched = $true }
    }
  }

  if ($touched) {
    $marker = '-- ROOTED: CANONICAL_MIGRATION_GATE_V5 (one-shot)'
    if ($lines.Count -gt 0 -and ($lines[0] -ne $marker)) { $lines.Insert(0, $marker) }
    [IO.File]::WriteAllText($path, ($lines -join "`r`n"), (New-Object System.Text.UTF8Encoding($false)))
    [void]$changed.Add($path)
  }
}

Write-Host ("ROOTED: Normalization touched {0} migration(s)." -f $changed.Count) -ForegroundColor Green

# -----------------------------
# VALIDATION (DO/FN/EXEC stacks)
# -----------------------------
Write-Host ''
Write-Host 'ROOTED: Validating migrations (DO vs FN vs EXECUTE pairing) ...' -ForegroundColor Cyan

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

    if ($trim -match '(?i)^\s*as\s+\$fn\$\s*$') { $fnStack.Push(@('$fn$', $i+1)); continue }
    if ($trim -match '(?i)^do\s+\$do\$\s*$') { $doStack.Push(@('$do$', $i+1)); continue }

    # function delimiter close (bare)
    if ($trim -eq '$fn$') {
      if ($fnStack.Count -eq 0) { AddErr $path ($i+1) "close '$fn$' without corresponding 'as $fn$' open" }
      else { [void]$fnStack.Pop() }
      continue
    }

    # do close
    if ($trim -eq '$do$;') {
      if ($doStack.Count -eq 0) { AddErr $path ($i+1) "close '$do$;' without corresponding 'do $do$' open" }
      else { [void]$doStack.Pop() }
      continue
    }

    # Disallow legacy delimiters lingering
    if ($trim -match '(?i)\bas\s+\$\$\b') { AddErr $path ($i+1) "Found legacy 'as $$' (must be 'as $fn$')." }
    if ($trim -match '(?i)^do\s+(\$\$|\$sql\$)\s*$') { AddErr $path ($i+1) "Found non-canonical DO opener (must be 'do $do$')." }
    if ($trim -match '(?i)^\s*(\$\$|\$sql\$)\s*;\s*$') { AddErr $path ($i+1) "Found non-canonical DO closer (must be '$do$;')." }
    if ($trim -eq '$fn$;') { AddErr $path ($i+1) "Found invalid '$fn$;' delimiter (must be '$fn$' then LANGUAGE ...;)." }
  }

  while ($execStack.Count -gt 0) { $top = $execStack.Pop(); AddErr $path $top[1] ("execute open '{0}' not closed with $q$;" -f $top[0]) }
  while ($fnStack.Count -gt 0)   { $top = $fnStack.Pop();   AddErr $path $top[1] ("function body open '{0}' not closed with '$fn$'" -f $top[0]) }
  while ($doStack.Count -gt 0)   { $top = $doStack.Pop();   AddErr $path $top[1] ("do open '{0}' not closed with '$do$;'" -f $top[0]) }
}

if ($errors.Count -gt 0) {
  Write-Host ''
  Write-Host ('ROOTED: VALIDATION FAILED ({0} issue(s)) ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â refusing to reset until clean.' -f $errors.Count) -ForegroundColor Red
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
    git add (Join-Path $repoRoot 'scripts/ROOTED_CANONICAL_MIGRATION_NORMALIZE_VALIDATE_GATE_V5.ps1') 2>$null | Out-Host
    git commit -m 'fix(migrations): canonical gate V5 (function delimiters $fn$ bare + canonical DO/EXECUTE) (ONE SHOT)' | Out-Host
    if (-not $NoPush) { git push | Out-Host } else { Write-Host 'ROOTED: NoPush set ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â skipping git push.' -ForegroundColor DarkGray }
  } else {
    Write-Host 'ROOTED: NoCommit set ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â leaving changes uncommitted.' -ForegroundColor Yellow
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
$LIT_FN = '$fn

Write-Host ''
Write-Host 'ROOTED: CANONICAL GATE V5 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â canonical DO $do$, EXECUTE $q$, and FUNCTION bodies as $fn$ ... $fn$ (NO semicolon)' -ForegroundColor Cyan

$repoRoot = (git rev-parse --show-toplevel)
Set-Location $repoRoot

# --- Auto-stash if dirty (and restore at end) ---
$didStash = $false
$porcelain = (git status --porcelain)
if (-not [string]::IsNullOrWhiteSpace($porcelain)) {
  $stamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
  $msg = "ROOTED:auto-stash_before_migration_gate_v5_$stamp"
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
$reAsLine       = [regex]::new('(?i)^\s*as\s+(\$\$|\$fn\$)\s*$', 'Multiline')
$reAsInline     = [regex]::new('(?i)\bas\s+(\$\$|\$fn\$)\b')
$reFnCloseBare  = [regex]::new('(?i)^\s*(\$\$|\$fn\$)\s*$')      # $$ or $fn$
$reFnCloseSemi  = [regex]::new('(?i)^\s*(\$\$|\$fn\$)\s*;\s*$')  # $$; or $fn$;  (we will heal to bare)

$reLanguageLine = [regex]::new('(?i)^\s*language\b')

function NextMeaningfulIdx([System.Collections.Generic.List[string]]$lines, [int]$start, [int]$limitExclusive) {
  for ($i=$start; $i -lt $limitExclusive; $i++) {
    $t = $lines[$i].Trim()
    if ($t -eq '') { continue }
    if ($t -like '--*') { continue }
    return $i
  }
  return -1
}

function PrevMeaningfulIdx([System.Collections.Generic.List[string]]$lines, [int]$startInclusive) {
  for ($i=$startInclusive; $i -ge 0; $i--) {
    $t = $lines[$i].Trim()
    if ($t -eq '') { continue }
    if ($t -like '--*') { continue }
    return $i
  }
  return -1
}

function EnsureEndsWithSemicolon([string]$line) {
  if ($line.TrimEnd() -match ';\s*$') { return $line }
  return ($line + ';')
}

# Split multi-function execute payloads into multiple execute blocks.
# V5 RULE: function body closes with $fn$ (bare), and statement ends on LANGUAGE ...;
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

    # Normalize AS $$ -> AS $fn$
    for ($i=0; $i -lt $chunk.Count; $i++) {
      $t = $chunk[$i].Trim()
      if ($t -match '(?i)^as\s+\$\$\s*$') { $chunk[$i] = '    as $fn$' }
      else { $chunk[$i] = ($chunk[$i] -replace '(?i)\bas\s+\$\$\b', 'as $fn$') }
    }

    # Normalize any close delimiter variants to "$fn$" (bare)
    for ($i=0; $i -lt $chunk.Count; $i++) {
      $t = $chunk[$i].Trim()
      if ($t -eq '$$')   { $chunk[$i] = '    $fn$' }
      if ($t -eq '$$;')  { $chunk[$i] = '    $fn$' }
      if ($t -eq '$fn$;'){ $chunk[$i] = '    $fn$' }
    }

    # Ensure there is a $fn$ close somewhere after "as $fn$"
    $hasAs = $false
    $hasClose = $false
    for ($i=0; $i -lt $chunk.Count; $i++) {
      if ($chunk[$i] -match '(?i)^\s*as\s+\$fn\$\s*$') { $hasAs = $true }
      if ($hasAs -and $chunk[$i].Trim() -eq '$fn$') { $hasClose = $true; break }
    }
    if ($hasAs -and -not $hasClose) {
      $chunk += '    $fn$'
    }

    # Ensure LANGUAGE line exists and ends with semicolon inside the statement
    $foundLang = $false
    for ($i=0; $i -lt $chunk.Count; $i++) {
      if ($reLanguageLine.IsMatch($chunk[$i])) {
        $chunk[$i] = EnsureEndsWithSemicolon $chunk[$i]
        $foundLang = $true
        break
      }
    }
    # If language is missing entirely, we do NOT invent it ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â but we leave chunk as-is.
    # (You likely already have it; this just avoids breaking.)
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

  # (1) Canonicalize AS $$ -> AS $fn$ globally (safe)
  for ($i=0; $i -lt $lines.Count; $i++) {
    $t = $lines[$i].Trim()
    if ($t -match '(?i)^as\s+\$\$\s*$') { $lines[$i] = ($lines[$i] -replace '(?i)as\s+\$\$', 'as $fn$'); $touched = $true; continue }
    if ($lines[$i] -match '(?i)\bas\s+\$\$\b') { $lines[$i] = ($lines[$i] -replace '(?i)\bas\s+\$\$\b', 'as $fn$'); $touched = $true }
  }

  # (2) Heal any "$fn$;" that would break CREATE FUNCTION (typically followed by LANGUAGE)
  for ($i=0; $i -lt $lines.Count; $i++) {
    if ($lines[$i].Trim() -ne '$fn$;') { continue }
    $n = NextMeaningfulIdx $lines ($i+1) $lines.Count
    if ($n -ge 0 -and $reLanguageLine.IsMatch($lines[$n])) {
      $lines[$i] = '    $fn$'
      $touched = $true
    } else {
      # Even if not followed by language, canonical delimiter is bare
      $lines[$i] = '    $fn$'
      $touched = $true
    }
  }
  for ($i=0; $i -lt $lines.Count; $i++) {
    if ($lines[$i].Trim() -ne '$$;') { continue }
    # treat $$; as a delimiter line and canonicalize to $fn$ (bare) ONLY if we're in a function-ish region
    $lines[$i] = '    $fn$'
    $touched = $true
  }

  # (3) Canonicalize DO blocks to do $do$ ... $do$; and normalize execute $q$ blocks inside
  for ($i=0; $i -lt $lines.Count; $i++) {
    if (-not $reDoOpenAny.IsMatch($lines[$i])) { continue }

    $close = -1
    for ($j=$i+1; $j -lt $lines.Count; $j++) {
      if ($reDoCloseAny.IsMatch($lines[$j])) { $close = $j; break }
      if ($j -gt $i+1 -and $reDoOpenAny.IsMatch($lines[$j])) { break }
    }
    if ($close -lt 0) { continue }

    if (-not $reDoOpenDo.IsMatch($lines[$i])) { $lines[$i] = 'do $do$'; $touched = $true }
    if (-not $reDoCloseDo.IsMatch($lines[$close])) { $lines[$close] = '$do$;'; $touched = $true }

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

      $didSplit = SplitExecuteBlockIfMultipleFunctions -lines $lines -execOpenIdx $k -execCloseIdx $qEnd
      if ($didSplit) {
        $touched = $true
        # refind do close safely
        for ($z=$k; $z -lt $lines.Count; $z++) { if ($reDoCloseDo.IsMatch($lines[$z])) { $close = $z; break } }
        continue
      }

      # normalize payload delimiters inside execute: $$ / $$; / $fn$; => $fn$
      for ($m=$k+1; $m -lt $qEnd; $m++) {
        $t = $lines[$m].Trim()
        if ($t -match '(?i)^as\s+\$\$\s*$') { $lines[$m] = '    as $fn$'; $touched = $true; continue }
        if ($lines[$m] -match '(?i)\bas\s+\$\$\b') { $lines[$m] = ($lines[$m] -replace '(?i)\bas\s+\$\$\b', 'as $fn$'); $touched = $true; continue }
        if ($t -eq '$$' -or $t -eq '$$;' -or $t -eq '$fn$;') { $lines[$m] = '    $fn$'; $touched = $true; continue }
      }

      $k = $qEnd
    }

    $i = $close
  }

  # (4) For each "as $fn$" ensure we have a later "$fn$" delimiter before the next CREATE FUNCTION
  for ($i=0; $i -lt $lines.Count; $i++) {
    if (-not ($lines[$i].Trim() -match '(?i)^as\s+\$fn\$\s*$')) { continue }

    $foundClose = $false
    for ($j=$i+1; $j -lt $lines.Count; $j++) {
      if ($reCreateFnLine.IsMatch($lines[$j])) { break }
      $tj = $lines[$j].Trim()
      if ($tj -eq '$fn$') { $foundClose = $true; break }
      if ($tj -eq '$fn$;') { $lines[$j] = '    $fn$'; $touched = $true; $foundClose = $true; break }
      if ($tj -eq '$$' -or $tj -eq '$$;') { $lines[$j] = '    $fn$'; $touched = $true; $foundClose = $true; break }
    }
    if (-not $foundClose) {
      $insertAt = $lines.Count
      for ($j=$i+1; $j -lt $lines.Count; $j++) { if ($reCreateFnLine.IsMatch($lines[$j])) { $insertAt = $j; break } }
      $lines.Insert($insertAt, '    $fn$')
      $touched = $true
    }
  }

  # (5) Ensure LANGUAGE lines end with semicolon (harmless and helps completeness)
  for ($i=0; $i -lt $lines.Count; $i++) {
    if ($reLanguageLine.IsMatch($lines[$i])) {
      $nl = EnsureEndsWithSemicolon $lines[$i]
      if ($nl -ne $lines[$i]) { $lines[$i] = $nl; $touched = $true }
    }
  }

  if ($touched) {
    $marker = '-- ROOTED: CANONICAL_MIGRATION_GATE_V5 (one-shot)'
    if ($lines.Count -gt 0 -and ($lines[0] -ne $marker)) { $lines.Insert(0, $marker) }
    [IO.File]::WriteAllText($path, ($lines -join "`r`n"), (New-Object System.Text.UTF8Encoding($false)))
    [void]$changed.Add($path)
  }
}

Write-Host ("ROOTED: Normalization touched {0} migration(s)." -f $changed.Count) -ForegroundColor Green

# -----------------------------
# VALIDATION (DO/FN/EXEC stacks)
# -----------------------------
Write-Host ''
Write-Host 'ROOTED: Validating migrations (DO vs FN vs EXECUTE pairing) ...' -ForegroundColor Cyan

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

    if ($trim -match '(?i)^\s*as\s+\$fn\$\s*$') { $fnStack.Push(@('$fn$', $i+1)); continue }
    if ($trim -match '(?i)^do\s+\$do\$\s*$') { $doStack.Push(@('$do$', $i+1)); continue }

    # function delimiter close (bare)
    if ($trim -eq '$fn$') {
      if ($fnStack.Count -eq 0) { AddErr $path ($i+1) "close '$fn$' without corresponding 'as $fn$' open" }
      else { [void]$fnStack.Pop() }
      continue
    }

    # do close
    if ($trim -eq '$do$;') {
      if ($doStack.Count -eq 0) { AddErr $path ($i+1) "close '$do$;' without corresponding 'do $do$' open" }
      else { [void]$doStack.Pop() }
      continue
    }

    # Disallow legacy delimiters lingering
    if ($trim -match '(?i)\bas\s+\$\$\b') { AddErr $path ($i+1) "Found legacy 'as $$' (must be 'as $fn$')." }
    if ($trim -match '(?i)^do\s+(\$\$|\$sql\$)\s*$') { AddErr $path ($i+1) "Found non-canonical DO opener (must be 'do $do$')." }
    if ($trim -match '(?i)^\s*(\$\$|\$sql\$)\s*;\s*$') { AddErr $path ($i+1) "Found non-canonical DO closer (must be '$do$;')." }
    if ($trim -eq '$fn$;') { AddErr $path ($i+1) "Found invalid '$fn$;' delimiter (must be '$fn$' then LANGUAGE ...;)." }
  }

  while ($execStack.Count -gt 0) { $top = $execStack.Pop(); AddErr $path $top[1] ("execute open '{0}' not closed with $q$;" -f $top[0]) }
  while ($fnStack.Count -gt 0)   { $top = $fnStack.Pop();   AddErr $path $top[1] ("function body open '{0}' not closed with '$fn$'" -f $top[0]) }
  while ($doStack.Count -gt 0)   { $top = $doStack.Pop();   AddErr $path $top[1] ("do open '{0}' not closed with '$do$;'" -f $top[0]) }
}

if ($errors.Count -gt 0) {
  Write-Host ''
  Write-Host ('ROOTED: VALIDATION FAILED ({0} issue(s)) ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â refusing to reset until clean.' -f $errors.Count) -ForegroundColor Red
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
    git add (Join-Path $repoRoot 'scripts/ROOTED_CANONICAL_MIGRATION_NORMALIZE_VALIDATE_GATE_V5.ps1') 2>$null | Out-Host
    git commit -m 'fix(migrations): canonical gate V5 (function delimiters $fn$ bare + canonical DO/EXECUTE) (ONE SHOT)' | Out-Host
    if (-not $NoPush) { git push | Out-Host } else { Write-Host 'ROOTED: NoPush set ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â skipping git push.' -ForegroundColor DarkGray }
  } else {
    Write-Host 'ROOTED: NoCommit set ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â leaving changes uncommitted.' -ForegroundColor Yellow
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
$LIT_Q  = '$q

Write-Host ''
Write-Host 'ROOTED: CANONICAL GATE V5 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â canonical DO $do$, EXECUTE $q$, and FUNCTION bodies as $fn$ ... $fn$ (NO semicolon)' -ForegroundColor Cyan

$repoRoot = (git rev-parse --show-toplevel)
Set-Location $repoRoot

# --- Auto-stash if dirty (and restore at end) ---
$didStash = $false
$porcelain = (git status --porcelain)
if (-not [string]::IsNullOrWhiteSpace($porcelain)) {
  $stamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
  $msg = "ROOTED:auto-stash_before_migration_gate_v5_$stamp"
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
$reAsLine       = [regex]::new('(?i)^\s*as\s+(\$\$|\$fn\$)\s*$', 'Multiline')
$reAsInline     = [regex]::new('(?i)\bas\s+(\$\$|\$fn\$)\b')
$reFnCloseBare  = [regex]::new('(?i)^\s*(\$\$|\$fn\$)\s*$')      # $$ or $fn$
$reFnCloseSemi  = [regex]::new('(?i)^\s*(\$\$|\$fn\$)\s*;\s*$')  # $$; or $fn$;  (we will heal to bare)

$reLanguageLine = [regex]::new('(?i)^\s*language\b')

function NextMeaningfulIdx([System.Collections.Generic.List[string]]$lines, [int]$start, [int]$limitExclusive) {
  for ($i=$start; $i -lt $limitExclusive; $i++) {
    $t = $lines[$i].Trim()
    if ($t -eq '') { continue }
    if ($t -like '--*') { continue }
    return $i
  }
  return -1
}

function PrevMeaningfulIdx([System.Collections.Generic.List[string]]$lines, [int]$startInclusive) {
  for ($i=$startInclusive; $i -ge 0; $i--) {
    $t = $lines[$i].Trim()
    if ($t -eq '') { continue }
    if ($t -like '--*') { continue }
    return $i
  }
  return -1
}

function EnsureEndsWithSemicolon([string]$line) {
  if ($line.TrimEnd() -match ';\s*$') { return $line }
  return ($line + ';')
}

# Split multi-function execute payloads into multiple execute blocks.
# V5 RULE: function body closes with $fn$ (bare), and statement ends on LANGUAGE ...;
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

    # Normalize AS $$ -> AS $fn$
    for ($i=0; $i -lt $chunk.Count; $i++) {
      $t = $chunk[$i].Trim()
      if ($t -match '(?i)^as\s+\$\$\s*$') { $chunk[$i] = '    as $fn$' }
      else { $chunk[$i] = ($chunk[$i] -replace '(?i)\bas\s+\$\$\b', 'as $fn$') }
    }

    # Normalize any close delimiter variants to "$fn$" (bare)
    for ($i=0; $i -lt $chunk.Count; $i++) {
      $t = $chunk[$i].Trim()
      if ($t -eq '$$')   { $chunk[$i] = '    $fn$' }
      if ($t -eq '$$;')  { $chunk[$i] = '    $fn$' }
      if ($t -eq '$fn$;'){ $chunk[$i] = '    $fn$' }
    }

    # Ensure there is a $fn$ close somewhere after "as $fn$"
    $hasAs = $false
    $hasClose = $false
    for ($i=0; $i -lt $chunk.Count; $i++) {
      if ($chunk[$i] -match '(?i)^\s*as\s+\$fn\$\s*$') { $hasAs = $true }
      if ($hasAs -and $chunk[$i].Trim() -eq '$fn$') { $hasClose = $true; break }
    }
    if ($hasAs -and -not $hasClose) {
      $chunk += '    $fn$'
    }

    # Ensure LANGUAGE line exists and ends with semicolon inside the statement
    $foundLang = $false
    for ($i=0; $i -lt $chunk.Count; $i++) {
      if ($reLanguageLine.IsMatch($chunk[$i])) {
        $chunk[$i] = EnsureEndsWithSemicolon $chunk[$i]
        $foundLang = $true
        break
      }
    }
    # If language is missing entirely, we do NOT invent it ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â but we leave chunk as-is.
    # (You likely already have it; this just avoids breaking.)
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

  # (1) Canonicalize AS $$ -> AS $fn$ globally (safe)
  for ($i=0; $i -lt $lines.Count; $i++) {
    $t = $lines[$i].Trim()
    if ($t -match '(?i)^as\s+\$\$\s*$') { $lines[$i] = ($lines[$i] -replace '(?i)as\s+\$\$', 'as $fn$'); $touched = $true; continue }
    if ($lines[$i] -match '(?i)\bas\s+\$\$\b') { $lines[$i] = ($lines[$i] -replace '(?i)\bas\s+\$\$\b', 'as $fn$'); $touched = $true }
  }

  # (2) Heal any "$fn$;" that would break CREATE FUNCTION (typically followed by LANGUAGE)
  for ($i=0; $i -lt $lines.Count; $i++) {
    if ($lines[$i].Trim() -ne '$fn$;') { continue }
    $n = NextMeaningfulIdx $lines ($i+1) $lines.Count
    if ($n -ge 0 -and $reLanguageLine.IsMatch($lines[$n])) {
      $lines[$i] = '    $fn$'
      $touched = $true
    } else {
      # Even if not followed by language, canonical delimiter is bare
      $lines[$i] = '    $fn$'
      $touched = $true
    }
  }
  for ($i=0; $i -lt $lines.Count; $i++) {
    if ($lines[$i].Trim() -ne '$$;') { continue }
    # treat $$; as a delimiter line and canonicalize to $fn$ (bare) ONLY if we're in a function-ish region
    $lines[$i] = '    $fn$'
    $touched = $true
  }

  # (3) Canonicalize DO blocks to do $do$ ... $do$; and normalize execute $q$ blocks inside
  for ($i=0; $i -lt $lines.Count; $i++) {
    if (-not $reDoOpenAny.IsMatch($lines[$i])) { continue }

    $close = -1
    for ($j=$i+1; $j -lt $lines.Count; $j++) {
      if ($reDoCloseAny.IsMatch($lines[$j])) { $close = $j; break }
      if ($j -gt $i+1 -and $reDoOpenAny.IsMatch($lines[$j])) { break }
    }
    if ($close -lt 0) { continue }

    if (-not $reDoOpenDo.IsMatch($lines[$i])) { $lines[$i] = 'do $do$'; $touched = $true }
    if (-not $reDoCloseDo.IsMatch($lines[$close])) { $lines[$close] = '$do$;'; $touched = $true }

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

      $didSplit = SplitExecuteBlockIfMultipleFunctions -lines $lines -execOpenIdx $k -execCloseIdx $qEnd
      if ($didSplit) {
        $touched = $true
        # refind do close safely
        for ($z=$k; $z -lt $lines.Count; $z++) { if ($reDoCloseDo.IsMatch($lines[$z])) { $close = $z; break } }
        continue
      }

      # normalize payload delimiters inside execute: $$ / $$; / $fn$; => $fn$
      for ($m=$k+1; $m -lt $qEnd; $m++) {
        $t = $lines[$m].Trim()
        if ($t -match '(?i)^as\s+\$\$\s*$') { $lines[$m] = '    as $fn$'; $touched = $true; continue }
        if ($lines[$m] -match '(?i)\bas\s+\$\$\b') { $lines[$m] = ($lines[$m] -replace '(?i)\bas\s+\$\$\b', 'as $fn$'); $touched = $true; continue }
        if ($t -eq '$$' -or $t -eq '$$;' -or $t -eq '$fn$;') { $lines[$m] = '    $fn$'; $touched = $true; continue }
      }

      $k = $qEnd
    }

    $i = $close
  }

  # (4) For each "as $fn$" ensure we have a later "$fn$" delimiter before the next CREATE FUNCTION
  for ($i=0; $i -lt $lines.Count; $i++) {
    if (-not ($lines[$i].Trim() -match '(?i)^as\s+\$fn\$\s*$')) { continue }

    $foundClose = $false
    for ($j=$i+1; $j -lt $lines.Count; $j++) {
      if ($reCreateFnLine.IsMatch($lines[$j])) { break }
      $tj = $lines[$j].Trim()
      if ($tj -eq '$fn$') { $foundClose = $true; break }
      if ($tj -eq '$fn$;') { $lines[$j] = '    $fn$'; $touched = $true; $foundClose = $true; break }
      if ($tj -eq '$$' -or $tj -eq '$$;') { $lines[$j] = '    $fn$'; $touched = $true; $foundClose = $true; break }
    }
    if (-not $foundClose) {
      $insertAt = $lines.Count
      for ($j=$i+1; $j -lt $lines.Count; $j++) { if ($reCreateFnLine.IsMatch($lines[$j])) { $insertAt = $j; break } }
      $lines.Insert($insertAt, '    $fn$')
      $touched = $true
    }
  }

  # (5) Ensure LANGUAGE lines end with semicolon (harmless and helps completeness)
  for ($i=0; $i -lt $lines.Count; $i++) {
    if ($reLanguageLine.IsMatch($lines[$i])) {
      $nl = EnsureEndsWithSemicolon $lines[$i]
      if ($nl -ne $lines[$i]) { $lines[$i] = $nl; $touched = $true }
    }
  }

  if ($touched) {
    $marker = '-- ROOTED: CANONICAL_MIGRATION_GATE_V5 (one-shot)'
    if ($lines.Count -gt 0 -and ($lines[0] -ne $marker)) { $lines.Insert(0, $marker) }
    [IO.File]::WriteAllText($path, ($lines -join "`r`n"), (New-Object System.Text.UTF8Encoding($false)))
    [void]$changed.Add($path)
  }
}

Write-Host ("ROOTED: Normalization touched {0} migration(s)." -f $changed.Count) -ForegroundColor Green

# -----------------------------
# VALIDATION (DO/FN/EXEC stacks)
# -----------------------------
Write-Host ''
Write-Host 'ROOTED: Validating migrations (DO vs FN vs EXECUTE pairing) ...' -ForegroundColor Cyan

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

    if ($trim -match '(?i)^\s*as\s+\$fn\$\s*$') { $fnStack.Push(@('$fn$', $i+1)); continue }
    if ($trim -match '(?i)^do\s+\$do\$\s*$') { $doStack.Push(@('$do$', $i+1)); continue }

    # function delimiter close (bare)
    if ($trim -eq '$fn$') {
      if ($fnStack.Count -eq 0) { AddErr $path ($i+1) "close '$fn$' without corresponding 'as $fn$' open" }
      else { [void]$fnStack.Pop() }
      continue
    }

    # do close
    if ($trim -eq '$do$;') {
      if ($doStack.Count -eq 0) { AddErr $path ($i+1) "close '$do$;' without corresponding 'do $do$' open" }
      else { [void]$doStack.Pop() }
      continue
    }

    # Disallow legacy delimiters lingering
    if ($trim -match '(?i)\bas\s+\$\$\b') { AddErr $path ($i+1) "Found legacy 'as $$' (must be 'as $fn$')." }
    if ($trim -match '(?i)^do\s+(\$\$|\$sql\$)\s*$') { AddErr $path ($i+1) "Found non-canonical DO opener (must be 'do $do$')." }
    if ($trim -match '(?i)^\s*(\$\$|\$sql\$)\s*;\s*$') { AddErr $path ($i+1) "Found non-canonical DO closer (must be '$do$;')." }
    if ($trim -eq '$fn$;') { AddErr $path ($i+1) "Found invalid '$fn$;' delimiter (must be '$fn$' then LANGUAGE ...;)." }
  }

  while ($execStack.Count -gt 0) { $top = $execStack.Pop(); AddErr $path $top[1] ("execute open '{0}' not closed with $q$;" -f $top[0]) }
  while ($fnStack.Count -gt 0)   { $top = $fnStack.Pop();   AddErr $path $top[1] ("function body open '{0}' not closed with '$fn$'" -f $top[0]) }
  while ($doStack.Count -gt 0)   { $top = $doStack.Pop();   AddErr $path $top[1] ("do open '{0}' not closed with '$do$;'" -f $top[0]) }
}

if ($errors.Count -gt 0) {
  Write-Host ''
  Write-Host ('ROOTED: VALIDATION FAILED ({0} issue(s)) ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â refusing to reset until clean.' -f $errors.Count) -ForegroundColor Red
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
    git add (Join-Path $repoRoot 'scripts/ROOTED_CANONICAL_MIGRATION_NORMALIZE_VALIDATE_GATE_V5.ps1') 2>$null | Out-Host
    git commit -m 'fix(migrations): canonical gate V5 (function delimiters $fn$ bare + canonical DO/EXECUTE) (ONE SHOT)' | Out-Host
    if (-not $NoPush) { git push | Out-Host } else { Write-Host 'ROOTED: NoPush set ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â skipping git push.' -ForegroundColor DarkGray }
  } else {
    Write-Host 'ROOTED: NoCommit set ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â leaving changes uncommitted.' -ForegroundColor Yellow
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

Write-Host ''
Write-Host 'ROOTED: CANONICAL GATE V5 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â canonical DO $do$, EXECUTE $q$, and FUNCTION bodies as $fn$ ... $fn$ (NO semicolon)' -ForegroundColor Cyan

$repoRoot = (git rev-parse --show-toplevel)
Set-Location $repoRoot

# --- Auto-stash if dirty (and restore at end) ---
$didStash = $false
$porcelain = (git status --porcelain)
if (-not [string]::IsNullOrWhiteSpace($porcelain)) {
  $stamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
  $msg = "ROOTED:auto-stash_before_migration_gate_v5_$stamp"
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
$reAsLine       = [regex]::new('(?i)^\s*as\s+(\$\$|\$fn\$)\s*$', 'Multiline')
$reAsInline     = [regex]::new('(?i)\bas\s+(\$\$|\$fn\$)\b')
$reFnCloseBare  = [regex]::new('(?i)^\s*(\$\$|\$fn\$)\s*$')      # $$ or $fn$
$reFnCloseSemi  = [regex]::new('(?i)^\s*(\$\$|\$fn\$)\s*;\s*$')  # $$; or $fn$;  (we will heal to bare)

$reLanguageLine = [regex]::new('(?i)^\s*language\b')

function NextMeaningfulIdx([System.Collections.Generic.List[string]]$lines, [int]$start, [int]$limitExclusive) {
  for ($i=$start; $i -lt $limitExclusive; $i++) {
    $t = $lines[$i].Trim()
    if ($t -eq '') { continue }
    if ($t -like '--*') { continue }
    return $i
  }
  return -1
}

function PrevMeaningfulIdx([System.Collections.Generic.List[string]]$lines, [int]$startInclusive) {
  for ($i=$startInclusive; $i -ge 0; $i--) {
    $t = $lines[$i].Trim()
    if ($t -eq '') { continue }
    if ($t -like '--*') { continue }
    return $i
  }
  return -1
}

function EnsureEndsWithSemicolon([string]$line) {
  if ($line.TrimEnd() -match ';\s*$') { return $line }
  return ($line + ';')
}

# Split multi-function execute payloads into multiple execute blocks.
# V5 RULE: function body closes with $fn$ (bare), and statement ends on LANGUAGE ...;
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

    # Normalize AS $$ -> AS $fn$
    for ($i=0; $i -lt $chunk.Count; $i++) {
      $t = $chunk[$i].Trim()
      if ($t -match '(?i)^as\s+\$\$\s*$') { $chunk[$i] = '    as $fn$' }
      else { $chunk[$i] = ($chunk[$i] -replace '(?i)\bas\s+\$\$\b', 'as $fn$') }
    }

    # Normalize any close delimiter variants to "$fn$" (bare)
    for ($i=0; $i -lt $chunk.Count; $i++) {
      $t = $chunk[$i].Trim()
      if ($t -eq '$$')   { $chunk[$i] = '    $fn$' }
      if ($t -eq '$$;')  { $chunk[$i] = '    $fn$' }
      if ($t -eq '$fn$;'){ $chunk[$i] = '    $fn$' }
    }

    # Ensure there is a $fn$ close somewhere after "as $fn$"
    $hasAs = $false
    $hasClose = $false
    for ($i=0; $i -lt $chunk.Count; $i++) {
      if ($chunk[$i] -match '(?i)^\s*as\s+\$fn\$\s*$') { $hasAs = $true }
      if ($hasAs -and $chunk[$i].Trim() -eq '$fn$') { $hasClose = $true; break }
    }
    if ($hasAs -and -not $hasClose) {
      $chunk += '    $fn$'
    }

    # Ensure LANGUAGE line exists and ends with semicolon inside the statement
    $foundLang = $false
    for ($i=0; $i -lt $chunk.Count; $i++) {
      if ($reLanguageLine.IsMatch($chunk[$i])) {
        $chunk[$i] = EnsureEndsWithSemicolon $chunk[$i]
        $foundLang = $true
        break
      }
    }
    # If language is missing entirely, we do NOT invent it ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â but we leave chunk as-is.
    # (You likely already have it; this just avoids breaking.)
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

  # (1) Canonicalize AS $$ -> AS $fn$ globally (safe)
  for ($i=0; $i -lt $lines.Count; $i++) {
    $t = $lines[$i].Trim()
    if ($t -match '(?i)^as\s+\$\$\s*$') { $lines[$i] = ($lines[$i] -replace '(?i)as\s+\$\$', 'as $fn$'); $touched = $true; continue }
    if ($lines[$i] -match '(?i)\bas\s+\$\$\b') { $lines[$i] = ($lines[$i] -replace '(?i)\bas\s+\$\$\b', 'as $fn$'); $touched = $true }
  }

  # (2) Heal any "$fn$;" that would break CREATE FUNCTION (typically followed by LANGUAGE)
  for ($i=0; $i -lt $lines.Count; $i++) {
    if ($lines[$i].Trim() -ne '$fn$;') { continue }
    $n = NextMeaningfulIdx $lines ($i+1) $lines.Count
    if ($n -ge 0 -and $reLanguageLine.IsMatch($lines[$n])) {
      $lines[$i] = '    $fn$'
      $touched = $true
    } else {
      # Even if not followed by language, canonical delimiter is bare
      $lines[$i] = '    $fn$'
      $touched = $true
    }
  }
  for ($i=0; $i -lt $lines.Count; $i++) {
    if ($lines[$i].Trim() -ne '$$;') { continue }
    # treat $$; as a delimiter line and canonicalize to $fn$ (bare) ONLY if we're in a function-ish region
    $lines[$i] = '    $fn$'
    $touched = $true
  }

  # (3) Canonicalize DO blocks to do $do$ ... $do$; and normalize execute $q$ blocks inside
  for ($i=0; $i -lt $lines.Count; $i++) {
    if (-not $reDoOpenAny.IsMatch($lines[$i])) { continue }

    $close = -1
    for ($j=$i+1; $j -lt $lines.Count; $j++) {
      if ($reDoCloseAny.IsMatch($lines[$j])) { $close = $j; break }
      if ($j -gt $i+1 -and $reDoOpenAny.IsMatch($lines[$j])) { break }
    }
    if ($close -lt 0) { continue }

    if (-not $reDoOpenDo.IsMatch($lines[$i])) { $lines[$i] = 'do $do$'; $touched = $true }
    if (-not $reDoCloseDo.IsMatch($lines[$close])) { $lines[$close] = '$do$;'; $touched = $true }

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

      $didSplit = SplitExecuteBlockIfMultipleFunctions -lines $lines -execOpenIdx $k -execCloseIdx $qEnd
      if ($didSplit) {
        $touched = $true
        # refind do close safely
        for ($z=$k; $z -lt $lines.Count; $z++) { if ($reDoCloseDo.IsMatch($lines[$z])) { $close = $z; break } }
        continue
      }

      # normalize payload delimiters inside execute: $$ / $$; / $fn$; => $fn$
      for ($m=$k+1; $m -lt $qEnd; $m++) {
        $t = $lines[$m].Trim()
        if ($t -match '(?i)^as\s+\$\$\s*$') { $lines[$m] = '    as $fn$'; $touched = $true; continue }
        if ($lines[$m] -match '(?i)\bas\s+\$\$\b') { $lines[$m] = ($lines[$m] -replace '(?i)\bas\s+\$\$\b', 'as $fn$'); $touched = $true; continue }
        if ($t -eq '$$' -or $t -eq '$$;' -or $t -eq '$fn$;') { $lines[$m] = '    $fn$'; $touched = $true; continue }
      }

      $k = $qEnd
    }

    $i = $close
  }

  # (4) For each "as $fn$" ensure we have a later "$fn$" delimiter before the next CREATE FUNCTION
  for ($i=0; $i -lt $lines.Count; $i++) {
    if (-not ($lines[$i].Trim() -match '(?i)^as\s+\$fn\$\s*$')) { continue }

    $foundClose = $false
    for ($j=$i+1; $j -lt $lines.Count; $j++) {
      if ($reCreateFnLine.IsMatch($lines[$j])) { break }
      $tj = $lines[$j].Trim()
      if ($tj -eq '$fn$') { $foundClose = $true; break }
      if ($tj -eq '$fn$;') { $lines[$j] = '    $fn$'; $touched = $true; $foundClose = $true; break }
      if ($tj -eq '$$' -or $tj -eq '$$;') { $lines[$j] = '    $fn$'; $touched = $true; $foundClose = $true; break }
    }
    if (-not $foundClose) {
      $insertAt = $lines.Count
      for ($j=$i+1; $j -lt $lines.Count; $j++) { if ($reCreateFnLine.IsMatch($lines[$j])) { $insertAt = $j; break } }
      $lines.Insert($insertAt, '    $fn$')
      $touched = $true
    }
  }

  # (5) Ensure LANGUAGE lines end with semicolon (harmless and helps completeness)
  for ($i=0; $i -lt $lines.Count; $i++) {
    if ($reLanguageLine.IsMatch($lines[$i])) {
      $nl = EnsureEndsWithSemicolon $lines[$i]
      if ($nl -ne $lines[$i]) { $lines[$i] = $nl; $touched = $true }
    }
  }

  if ($touched) {
    $marker = '-- ROOTED: CANONICAL_MIGRATION_GATE_V5 (one-shot)'
    if ($lines.Count -gt 0 -and ($lines[0] -ne $marker)) { $lines.Insert(0, $marker) }
    [IO.File]::WriteAllText($path, ($lines -join "`r`n"), (New-Object System.Text.UTF8Encoding($false)))
    [void]$changed.Add($path)
  }
}

Write-Host ("ROOTED: Normalization touched {0} migration(s)." -f $changed.Count) -ForegroundColor Green

# -----------------------------
# VALIDATION (DO/FN/EXEC stacks)
# -----------------------------
Write-Host ''
Write-Host 'ROOTED: Validating migrations (DO vs FN vs EXECUTE pairing) ...' -ForegroundColor Cyan

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

    if ($trim -match '(?i)^\s*as\s+\$fn\$\s*$') { $fnStack.Push(@('$fn$', $i+1)); continue }
    if ($trim -match '(?i)^do\s+\$do\$\s*$') { $doStack.Push(@('$do$', $i+1)); continue }

    # function delimiter close (bare)
    if ($trim -eq '$fn$') {
      if ($fnStack.Count -eq 0) { AddErr $path ($i+1) "close '$fn$' without corresponding 'as $fn$' open" }
      else { [void]$fnStack.Pop() }
      continue
    }

    # do close
    if ($trim -eq '$do$;') {
      if ($doStack.Count -eq 0) { AddErr $path ($i+1) "close '$do$;' without corresponding 'do $do$' open" }
      else { [void]$doStack.Pop() }
      continue
    }

    # Disallow legacy delimiters lingering
    if ($trim -match '(?i)\bas\s+\$\$\b') { AddErr $path ($i+1) "Found legacy 'as $$' (must be 'as $fn$')." }
    if ($trim -match '(?i)^do\s+(\$\$|\$sql\$)\s*$') { AddErr $path ($i+1) "Found non-canonical DO opener (must be 'do $do$')." }
    if ($trim -match '(?i)^\s*(\$\$|\$sql\$)\s*;\s*$') { AddErr $path ($i+1) "Found non-canonical DO closer (must be '$do$;')." }
    if ($trim -eq '$fn$;') { AddErr $path ($i+1) "Found invalid '$fn$;' delimiter (must be '$fn$' then LANGUAGE ...;)." }
  }

  while ($execStack.Count -gt 0) { $top = $execStack.Pop(); AddErr $path $top[1] ("execute open '{0}' not closed with $q$;" -f $top[0]) }
  while ($fnStack.Count -gt 0)   { $top = $fnStack.Pop();   AddErr $path $top[1] ("function body open '{0}' not closed with '$fn$'" -f $top[0]) }
  while ($doStack.Count -gt 0)   { $top = $doStack.Pop();   AddErr $path $top[1] ("do open '{0}' not closed with '$do$;'" -f $top[0]) }
}

if ($errors.Count -gt 0) {
  Write-Host ''
  Write-Host ('ROOTED: VALIDATION FAILED ({0} issue(s)) ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â refusing to reset until clean.' -f $errors.Count) -ForegroundColor Red
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
    git add (Join-Path $repoRoot 'scripts/ROOTED_CANONICAL_MIGRATION_NORMALIZE_VALIDATE_GATE_V5.ps1') 2>$null | Out-Host
    git commit -m 'fix(migrations): canonical gate V5 (function delimiters $fn$ bare + canonical DO/EXECUTE) (ONE SHOT)' | Out-Host
    if (-not $NoPush) { git push | Out-Host } else { Write-Host 'ROOTED: NoPush set ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â skipping git push.' -ForegroundColor DarkGray }
  } else {
    Write-Host 'ROOTED: NoCommit set ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â leaving changes uncommitted.' -ForegroundColor Yellow
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