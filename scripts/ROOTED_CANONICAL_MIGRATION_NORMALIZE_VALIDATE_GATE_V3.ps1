param(
  [switch]$DoReset,
  [switch]$NoCommit,
  [switch]$NoPush
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host ''
Write-Host 'ROOTED: CANONICAL GATE V3 — normalize + validate + (commit/push) + optional reset (ONE SHOT)' -ForegroundColor Cyan

$repoRoot = (git rev-parse --show-toplevel)
Set-Location $repoRoot

# --- Auto-stash if dirty (and restore at end) ---
$didStash = $false
$porcelain = (git status --porcelain)
if (-not [string]::IsNullOrWhiteSpace($porcelain)) {
  $stamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
  $msg = "ROOTED:auto-stash_before_migration_gate_v3_$stamp"
  Write-Host ("ROOTED: Auto-stashing dirty working tree: " + $msg) -ForegroundColor Yellow
  git stash push -u -m $msg | Out-Host
  $didStash = $true
}

$migrationsDir = Join-Path $repoRoot 'supabase/migrations'
if (!(Test-Path -LiteralPath $migrationsDir)) { throw "Missing migrations dir: $migrationsDir" }

$files = Get-ChildItem -LiteralPath $migrationsDir -Filter '*.sql' -File
if ($files.Count -eq 0) { throw "No .sql migrations found in: $migrationsDir" }

# -----------------------------
# Canonical dollar-tag policy:
# - DO blocks containing EXECUTE:  do $do$ ... $do$;
# - Dynamic SQL:                 execute $q$ ... $q$;
# - Function bodies inside EXECUTE: as $fn$ ... $fn$;
# -----------------------------

# DO open/close (any tag)
$reDoOpenAny  = [regex]::new('(?i)^\s*do\s+(\$\$|\$sql\$|\$do\$)\s*$', 'Multiline')
$reDoCloseAny = [regex]::new('(?i)^\s*(\$\$|\$sql\$|\$do\$)\s*;\s*$', 'Multiline')

# Canonical DO $do$
$reDoOpenDo   = [regex]::new('(?i)^\s*do\s+\$do\$\s*$', 'Multiline')
$reDoCloseDo  = [regex]::new('(?i)^\s*\$do\$\s*;\s*$', 'Multiline')

# EXECUTE open/close
$reExecOpenAny = [regex]::new('(?i)^\s*execute\s+(\$q\$|\$\$)\s*$', 'Multiline') # execute $q$ OR execute $$
$reExecOpenQ   = [regex]::new('(?i)^\s*execute\s+\$q\$\s*$', 'Multiline')
$reExecCloseQ  = [regex]::new('(?i)^\s*\$q\$\s*;\s*$', 'Multiline')

# Inside execute: create function detection
$reCreateFnLine = [regex]::new('(?i)^\s*create\s+or\s+replace\s+function\b')
$reAsDollarsLine = [regex]::new('(?i)^\s*as\s+\$\$\s*$', 'Multiline') # line exactly: as $$
$reAsInlineDollars = [regex]::new('(?i)\bas\s+\$\$\b')
$reAsFnInline = [regex]::new('(?i)\bas\s+\$fn\$\b')
$reFnCloseLine = [regex]::new('(?i)^\s*(\$\$|\$fn\$)\s*;\s*$') # $$; or $fn$;
$reFnCloseBare = [regex]::new('(?i)^\s*(\$\$|\$fn\$)\s*$')      # $$ or $fn$

# Whether a DO must be canonicalized (contains dynamic EXECUTE or $q$ or as $$)
$reNeedsCanonicalDo = [regex]::new('(?i)\bexecute\s+(\$q\$|\$\$)\b|\$q\$|\bas\s+\$\$\b|\bas\s+\$fn\$\b', 'Multiline')

# Helper: get next meaningful line index (skip blank/comments)
function NextMeaningfulIdx([System.Collections.Generic.List[string]]$lines, [int]$start, [int]$limitExclusive) {
  for ($i=$start; $i -lt $limitExclusive; $i++) {
    $t = $lines[$i].Trim()
    if ($t -eq '') { continue }
    if ($t -like '--*') { continue }
    return $i
  }
  return -1
}

# Helper: ensure a statement line ends with semicolon (unless it already does)
function EnsureSemicolon([string]$line) {
  $t = $line.TrimEnd()
  if ($t -match ';\s*$') { return $line }
  return ($line + ';')
}

# Helper: split one execute $q$ block containing multiple CREATE FUNCTIONs into multiple execute blocks
function SplitExecuteBlockIfMultipleFunctions(
  [System.Collections.Generic.List[string]]$lines,
  [int]$execOpenIdx,
  [int]$execCloseIdx
) {
  # Collect function start indices inside execute block
  $starts = New-Object System.Collections.Generic.List[int]
  for ($i=$execOpenIdx+1; $i -lt $execCloseIdx; $i++) {
    if ($reCreateFnLine.IsMatch($lines[$i])) { [void]$starts.Add($i) }
  }

  if ($starts.Count -le 1) { return $false } # nothing to split

  # Build new content: multiple execute $q$ blocks, one per function chunk
  $newBlock = New-Object System.Collections.Generic.List[string]

  for ($s=0; $s -lt $starts.Count; $s++) {
    $startIdx = $starts[$s]
    $endIdx = if ($s -lt $starts.Count-1) { $starts[$s+1]-1 } else { $execCloseIdx-1 }

    # Extract chunk lines
    $chunk = @()
    for ($i=$startIdx; $i -le $endIdx; $i++) { $chunk += $lines[$i] }

    # Normalize AS $$ -> AS $fn$ within this chunk (both "as $$" lines and inline)
    for ($i=0; $i -lt $chunk.Count; $i++) {
      if ($chunk[$i].Trim() -match '(?i)^as\s+\$\$\s*$') { $chunk[$i] = '    as $fn$' }
      else { $chunk[$i] = ($chunk[$i] -replace '(?i)\bas\s+\$\$\b', 'as $fn$') }
    }

    # Ensure we have a $fn$; closer before the next function starts:
    # Find last close line ($fn$ or $$) in chunk
    $hasClose = $false
    for ($i=$chunk.Count-1; $i -ge 0; $i--) {
      $t = $chunk[$i].Trim()
      if ($reFnCloseLine.IsMatch($t) -or ($reFnCloseBare.IsMatch($t) -and $t -in @('$$','$fn$'))) {
        $hasClose = $true
        # Normalize any $$ or $$; to $fn$ / $fn$;
        if ($t -eq '$$')      { $chunk[$i] = '    $fn$' }
        elseif ($t -eq '$$;') { $chunk[$i] = '    $fn$;' }
        elseif ($t -eq '$fn$') { $chunk[$i] = '    $fn$' }
        elseif ($t -eq '$fn$;') { $chunk[$i] = '    $fn$;' }
        break
      }
    }

    if (-not $hasClose) {
      # Insert $fn$; at end of chunk
      $chunk += '    $fn$;'
    }

    # Ensure the CREATE FUNCTION statement ends with semicolon after the $fn$; close is okay; we also ensure
    # the line immediately after $fn$; isn't missing.
    # (The function statement terminator is the $fn$; line; that's enough.)

    # Wrap this single function chunk in its own execute $q$ ... $q$;
    $newBlock.Add('  execute $q$') | Out-Null
    foreach ($cl in $chunk) { $newBlock.Add($cl) | Out-Null }
    $newBlock.Add('$q$;') | Out-Null
    $newBlock.Add('') | Out-Null
  }

  # Replace original execute block body with newBlock (keeping the original execute open line indentation style)
  # We will replace from execOpenIdx..execCloseIdx inclusive with new lines.
  for ($i=$execCloseIdx; $i -ge $execOpenIdx; $i--) { $lines.RemoveAt($i) }
  # Insert new block at execOpenIdx
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
      if ($j -gt $i+1 -and $reDoOpenAny.IsMatch($lines[$j])) { break } # malformed nesting
    }
    if ($close -lt 0) { continue }

    $bodyText = ''
    if ($close -gt $i+1) { $bodyText = ($lines[($i+1)..($close-1)] -join "`n") }

    $mustCanonicalDo = $reNeedsCanonicalDo.IsMatch($bodyText)

    # (1) Canonicalize outer DO delimiter to $do$ if needed
    if ($mustCanonicalDo) {
      if (-not $reDoOpenDo.IsMatch($lines[$i])) { $lines[$i] = 'do $do$'; $touched = $true }
      if (-not $reDoCloseDo.IsMatch($lines[$close])) { $lines[$close] = '$do$;'; $touched = $true }
    }

    # (2) Inside canonical DO: normalize/split EXECUTE blocks
    if ($mustCanonicalDo) {
      for ($k=$i+1; $k -lt $close; $k++) {
        if (-not $reExecOpenAny.IsMatch($lines[$k])) { continue }

        # normalize execute opener to "execute $q$"
        if (-not $reExecOpenQ.IsMatch($lines[$k])) { $lines[$k] = '  execute $q$'; $touched = $true }

        # find $q$; close, else insert one before DO close
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

        # IMPORTANT FIX (the one you are hitting):
        # If execute $q$ contains multiple CREATE FUNCTION blocks, split them into multiple execute blocks
        $didSplit = SplitExecuteBlockIfMultipleFunctions -lines $lines -execOpenIdx $k -execCloseIdx $qEnd
        if ($didSplit) {
          $touched = $true
          # After split, the current $k line is still execute $q$ of the first block.
          # We need to rescan from here because indices changed.
          $close = $lines.FindIndex($close, { param($x) $reDoCloseAny.IsMatch($x) })
          if ($close -lt 0) { break }
          continue
        }

        # If not split, still normalize function-body dollars inside the single execute payload:
        for ($m=$k+1; $m -lt $qEnd; $m++) {
          $ln = $lines[$m]
          $t = $ln.Trim()

          # AS $$ -> AS $fn$
          if ($t -match '(?i)^as\s+\$\$\s*$') { $lines[$m] = '    as $fn$'; $touched = $true; continue }
          if ($reAsInlineDollars.IsMatch($ln)) { $lines[$m] = ($ln -replace '(?i)\bas\s+\$\$\b', 'as $fn$'); $touched = $true; continue }

          # $$ or $$; -> $fn$ / $fn$;
          if ($t -eq '$$')  { $lines[$m] = '    $fn$';  $touched = $true; continue }
          if ($t -eq '$$;') { $lines[$m] = '    $fn$;'; $touched = $true; continue }
        }

        $k = $qEnd
      }
    }

    $i = $close
  }

  if ($touched) {
    $marker = '-- ROOTED: CANONICAL_MIGRATION_GATE_V3 (one-shot)'
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

    # EXECUTE open/close
    if ($trim -match '(?i)^execute\s+(\$q\$|\$\$)\s*$') { $execStack.Push(@($Matches[1].ToLowerInvariant(), $i+1)); continue }
    if ($trim -match '(?i)^\$q\$\s*;\s*$') {
      if ($execStack.Count -eq 0) { AddErr $path ($i+1) '$q$; close without execute open' }
      else {
        $top = $execStack.Pop()
        if ($top[0] -ne '$q$') { AddErr $path ($i+1) ("execute opened with '{0}' at line {1} but closed with $q$; (normalize opener to execute $q$)" -f $top[0], $top[1]) }
      }
      continue
    }

    # Function-body open
    if ($trim -match '(?i)\bas\s+(\$\$|\$fn\$)\s*$') { $fnStack.Push(@($Matches[1].ToLowerInvariant(), $i+1)); continue }

    # DO open
    if ($trim -match '(?i)^do\s+(\$\$|\$sql\$|\$do\$)\s*$') { $doStack.Push(@($Matches[1].ToLowerInvariant(), $i+1)); continue }

    # Close line could be $$; $fn$; $do$; $sql$;
    if ($trim -match '(?i)^(\$\$|\$fn\$|\$do\$|\$sql\$)\s*;\s*$') {
      $tag = $Matches[1].ToLowerInvariant()

      # Prefer closing function body first
      if ($fnStack.Count -gt 0) {
        $top = $fnStack.Peek()
        if ($top[0] -eq $tag) { [void]$fnStack.Pop(); continue }

        # Mismatch (real)
        AddErr $path ($i+1) ("function body close '{0}' mismatches open '{1}' at line {2}" -f $tag, $top[0], $top[1])
        [void]$fnStack.Pop()
        continue
      }

      # Then close DO if open
      if ($doStack.Count -gt 0) {
        $top = $doStack.Pop()
        if ($top[0] -ne $tag) { AddErr $path ($i+1) ("DO close tag '{0}' mismatches open '{1}' at line {2}" -f $tag, $top[0], $top[1]) }
        continue
      }

      # No stacks: only complain for non-$$ closers
      if ($tag -ne '$$') { AddErr $path ($i+1) ("close '{0};' without corresponding open" -f $tag) }
      continue
    }
  }

  while ($execStack.Count -gt 0) { $top = $execStack.Pop(); AddErr $path $top[1] ("execute open '{0}' not closed with $q$;" -f $top[0]) }
  while ($fnStack.Count -gt 0)   { $top = $fnStack.Pop();   AddErr $path $top[1] ("function body open '{0}' not closed" -f $top[0]) }
  while ($doStack.Count -gt 0)   { $top = $doStack.Pop();   AddErr $path $top[1] ("do open '{0}' not closed" -f $top[0]) }

  # Safety: no 'as $$' inside execute $q$ blocks
  $text = ($arr -join "`n")
  if ($text -match '(?is)execute\s+\$q\$\s*.*?\bas\s+\$\$\b') { AddErr $path 1 "Found 'as $$' inside an execute $q$ block (must be 'as $fn$' + '$fn$;')." }
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
    git add (Join-Path $repoRoot 'scripts/ROOTED_CANONICAL_MIGRATION_NORMALIZE_VALIDATE_GATE_V3.ps1') 2>$null | Out-Host
    git commit -m 'fix(migrations): canonical gate V3 (split multi-function execute $q$ blocks + normalize DO/EXECUTE/FN dollars) (ONE SHOT)' | Out-Host
    if (-not $NoPush) { git push | Out-Host } else { Write-Host 'ROOTED: NoPush set — skipping git push.' -ForegroundColor DarkGray }
  } else {
    Write-Host 'ROOTED: NoCommit set — leaving changes uncommitted.' -ForegroundColor Yellow
  }
} else {
  Write-Host 'ROOTED: No git changes to commit.' -ForegroundColor DarkGray
}

# Restore stash if we created one
if ($didStash) {
  Write-Host 'ROOTED: Restoring auto-stash (git stash pop)...' -ForegroundColor Yellow
  git stash pop | Out-Host
}

# Optional reset (ONLY if explicitly requested)
if ($DoReset) {
  Write-Host ''
  Write-Host 'ROOTED: Running supabase db reset --debug (explicit -DoReset)...' -ForegroundColor Cyan
  supabase db reset --debug | Out-Host
} else {
  Write-Host ''
  Write-Host 'ROOTED: Skipping supabase db reset (run with -DoReset to execute).' -ForegroundColor DarkGray
}