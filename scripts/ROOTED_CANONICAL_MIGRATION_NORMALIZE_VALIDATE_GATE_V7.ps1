param(
  [switch]$DoReset,
  [switch]$NoCommit,
  [switch]$NoPush
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host ''
Write-Host 'ROOTED: CANONICAL GATE V7 — DO $do$ ; EXECUTE $q$ ; FN $fn$ (StrictMode-safe + validator handles $$ language ...;)' -ForegroundColor Cyan

$repoRoot = (git rev-parse --show-toplevel)
Set-Location $repoRoot

# --- Auto-stash if dirty (and restore at end, even on failure) ---
$didStash = $false
$stashMsg = $null
$porcelain = (git status --porcelain)
if (-not [string]::IsNullOrWhiteSpace($porcelain)) {
  $stamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
  $stashMsg = "ROOTED:auto-stash_before_migration_gate_v7_$stamp"
  Write-Host ("ROOTED: Auto-stashing dirty working tree: " + $stashMsg) -ForegroundColor Yellow
  git stash push -u -m $stashMsg | Out-Host
  $didStash = $true
}

try {

  $migrationsDir = Join-Path $repoRoot 'supabase/migrations'
  if (!(Test-Path -LiteralPath $migrationsDir)) { throw "Missing migrations dir: $migrationsDir" }

  $files = Get-ChildItem -LiteralPath $migrationsDir -Filter '*.sql' -File
  if ($files.Count -eq 0) { throw "No .sql migrations found in: $migrationsDir" }

  # Canonical tags (single-quoted so StrictMode never tries to read $do/$fn/$q variables)
  $TAG_DO = '$do$'
  $TAG_Q  = '$q$'
  $TAG_FN = '$fn$'

  # --- Regexes (openers/closers can have trailing stuff; validator must accept $$ language ...;) ---
  $reDoOpenAny  = [regex]::new('(?i)^\s*do\s+(\$\$|\$sql\$|\$do\$)\b', 'Multiline')
  $reDoCloseAny = [regex]::new('(?i)^\s*(\$\$|\$sql\$|\$do\$)\s*;\s*.*$', 'Multiline')
  $reDoOpenDo   = [regex]::new('(?i)^\s*do\s+\$do\$\b', 'Multiline')
  $reDoCloseDo  = [regex]::new('(?i)^\s*\$do\$\s*;\s*.*$', 'Multiline')

  $reExecOpenAny = [regex]::new('(?i)^\s*execute\s+(\$q\$|\$\$)\b', 'Multiline')
  $reExecOpenQ   = [regex]::new('(?i)^\s*execute\s+\$q\$\b', 'Multiline')
  $reExecCloseAny = [regex]::new('(?i)^\s*(\$q\$|\$\$)\s*;\s*.*$', 'Multiline')
  $reExecCloseQ  = [regex]::new('(?i)^\s*\$q\$\s*;\s*.*$', 'Multiline')

  $reCreateFnLine = [regex]::new('(?i)^\s*create\s+or\s+replace\s+function\b')
  $reAsAny        = [regex]::new('(?i)\bas\s+(\$\$|\$fn\$)\b')
  $reAsLineAny    = [regex]::new('(?i)^\s*as\s+(\$\$|\$fn\$)\s*$', 'Multiline')
  $reAsInlineDollars = [regex]::new('(?i)\bas\s+\$\$\b')

  # function close can be: $$ ; $$; $$ language ...; $fn$ language ...;
  $reFnCloseAny = [regex]::new('(?i)^\s*(\$\$|\$fn\$)\s*(;|\blanguage\b).*$', 'Multiline')
  $reFnCloseBare = [regex]::new('(?i)^\s*(\$\$|\$fn\$)\s*$', 'Multiline')

  function NormalizeFnChunk([string[]]$chunk) {
    # In execute $q$ payloads, force function bodies to use $fn$ delimiters.
    $out = New-Object System.Collections.Generic.List[string]
    foreach ($ln in $chunk) {
      $t = $ln.Trim()

      # AS $$  -> AS $fn$
      if ($t -match '(?i)^as\s+\$\$\s*$') {
        $out.Add('    as $fn$') | Out-Null
        continue
      }

      # inline "as $$" -> "as $fn$"
      if ($reAsInlineDollars.IsMatch($ln)) {
        $out.Add(($ln -replace '(?i)\bas\s+\$\$\b', 'as $fn$')) | Out-Null
        continue
      }

      # close delimiter on its own line
      if ($t -eq '$$') { $out.Add('    $fn$') | Out-Null; continue }
      if ($t -eq '$$;') { $out.Add('    $fn$;') | Out-Null; continue }

      # close delimiter with LANGUAGE / semicolon (common Postgres style)
      if ($ln -match '(?i)^\s*\$\$\s*(;|\blanguage\b)') {
        $out.Add(($ln -replace '^\s*\$\$', '    $fn$')) | Out-Null
        continue
      }

      # if someone already used $fn$ close with LANGUAGE/; keep as-is
      $out.Add($ln) | Out-Null
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

      # ALWAYS canonicalize DO opener/closer (no heuristic)
      if (-not $reDoOpenDo.IsMatch($lines[$i])) { $lines[$i] = 'do $do$'; $touched = $true }
      if (-not $reDoCloseDo.IsMatch($lines[$close])) { $lines[$close] = '$do$;'; $touched = $true }

      # Canonicalize EXECUTE open/close tags inside this DO
      for ($k=$i+1; $k -lt $close; $k++) {
        if (-not $reExecOpenAny.IsMatch($lines[$k])) { continue }

        if (-not $reExecOpenQ.IsMatch($lines[$k])) { $lines[$k] = '  execute $q$'; $touched = $true }

        # find execute close (either $q$; or $$; -> normalize to $q$;)
        $qEnd = -1
        for ($m=$k+1; $m -lt $close; $m++) {
          if ($reExecCloseAny.IsMatch($lines[$m])) { $qEnd = $m; break }
          if ($reExecOpenAny.IsMatch($lines[$m])) { break }
        }
        if ($qEnd -lt 0) {
          $lines.Insert($close, '$q$;')
          $close++
          $qEnd = $close - 1
          $touched = $true
        } else {
          if (-not $reExecCloseQ.IsMatch($lines[$qEnd])) { $lines[$qEnd] = '$q$;'; $touched = $true }
        }

        # split multi-function execute blocks
        $didSplit = SplitExecuteBlockIfMultipleFunctions -lines $lines -execOpenIdx $k -execCloseIdx $qEnd
        if ($didSplit) { $touched = $true; break }

        # normalize fn chunk inside single execute payload
        $payload = @()
        for ($m=$k+1; $m -lt $qEnd; $m++) { $payload += $lines[$m] }
        $payload2 = NormalizeFnChunk -chunk $payload

        if (($payload2 -join "`n") -ne ($payload -join "`n")) {
          $idx = 0
          for ($m=$k+1; $m -lt $qEnd; $m++) { $lines[$m] = $payload2[$idx]; $idx++ }
          $touched = $true
        }

        $k = $qEnd
      }

      $i = $close
    }

    if ($touched) {
      $marker = '-- ROOTED: CANONICAL_MIGRATION_GATE_V7 (one-shot)'
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

      # EXECUTE open
      if ($trim -match '(?i)^execute\s+(\$q\$|\$\$)\b') { $execStack.Push(@($Matches[1].ToLowerInvariant(), $i+1)); continue }

      # EXECUTE close: $q$; (allow trailing comments)
      if ($trim -match '(?i)^(?:\$q\$|\$\$)\s*;\s*.*$') {
        $tag = ($trim -match '(?i)^\$\$') ? '$$' : '$q$'
        if ($execStack.Count -eq 0) { AddErr $path ($i+1) ('Found ' + $tag + '; close without execute open.') }
        else {
          $top = $execStack.Pop()
          # In V7 we canonicalize to $q$, but tolerate legacy $$ execute closer too.
          if ($tag -eq '$q$' -and $top[0] -ne '$q$') { AddErr $path ($i+1) ('Execute opened with ' + $top[0] + ' at line ' + $top[1] + ' but closed with $q$; (normalize opener to execute $q$).') }
        }
        continue
      }

      # FN open (as $$ / as $fn$) anywhere on line
      if ($trim -match '(?i)\bas\s+(\$\$|\$fn\$)\b') { $fnStack.Push(@($Matches[1].ToLowerInvariant(), $i+1)); continue }

      # DO open
      if ($trim -match '(?i)^do\s+(\$\$|\$sql\$|\$do\$)\b') { $doStack.Push(@($Matches[1].ToLowerInvariant(), $i+1)); continue }

      # FN close (bare OR with ; OR with language ...)
      if ($trim -match '(?i)^(\$\$|\$fn\$)\s*(;|\blanguage\b).*') {
        if ($fnStack.Count -gt 0) {
          $top = $fnStack.Peek()
          $tag = $Matches[1].ToLowerInvariant()
          if ($top[0] -eq $tag) { [void]$fnStack.Pop(); continue }
          AddErr $path ($i+1) ('Function body close ' + $tag + ' mismatches open ' + $top[0] + ' at line ' + $top[1] + '.')
          [void]$fnStack.Pop()
        }
        continue
      }
      if ($trim -match '(?i)^(\$\$|\$fn\$)\s*$') {
        if ($fnStack.Count -gt 0) {
          $top = $fnStack.Peek()
          $tag = $Matches[1].ToLowerInvariant()
          if ($top[0] -eq $tag) { [void]$fnStack.Pop(); continue }
          AddErr $path ($i+1) ('Function body close ' + $tag + ' mismatches open ' + $top[0] + ' at line ' + $top[1] + '.')
          [void]$fnStack.Pop()
        }
        continue
      }

      # DO close ($do$; / $sql$; / $$;) allow trailing comments
      if ($trim -match '(?i)^(\$\$|\$do\$|\$sql\$)\s*;\s*.*$') {
        $tag = $Matches[1].ToLowerInvariant()
        if ($doStack.Count -eq 0) {
          if ($tag -ne '$$') { AddErr $path ($i+1) ('Close ' + $tag + '; without corresponding DO open.') }
        } else {
          $top = $doStack.Pop()
          if ($top[0] -ne $tag) { AddErr $path ($i+1) ('DO close tag ' + $tag + ' mismatches open ' + $top[0] + ' at line ' + $top[1] + '.') }
        }
        continue
      }
    }

    while ($execStack.Count -gt 0) { $top = $execStack.Pop(); AddErr $path $top[1] ('Execute open ' + $top[0] + ' not closed.') }
    while ($fnStack.Count -gt 0)   { $top = $fnStack.Pop();   AddErr $path $top[1] ('Function body open ' + $top[0] + ' not closed.') }
    while ($doStack.Count -gt 0)   { $top = $doStack.Pop();   AddErr $path $top[1] ('DO open ' + $top[0] + ' not closed.') }

    # Hard checks (post-normalization)
    $text = ($arr -join "`n")
    if ($text -match '(?im)^\s*do\s+\$\$\b') { AddErr $path 1 'Found non-canonical DO opener (must be do $do$).' }
    if ($text -match '(?is)execute\s+\$q\$\s*.*?\bas\s+\$\$\b') { AddErr $path 1 'Found as $$ inside execute $q$ block (must be as $fn$ ... $fn$).' }
  }

  if ($errors.Count -gt 0) {
    Write-Host ''
    Write-Host ('ROOTED: VALIDATION FAILED (' + $errors.Count + ' issue(s)) — refusing to reset until clean.') -ForegroundColor Red
    $errors | ForEach-Object { Write-Host (' - ' + $_) -ForegroundColor Red }
    throw 'ROOTED: Migration gate failed validation.'
  }

  Write-Host 'ROOTED: Validation OK.' -ForegroundColor Green

  # Commit/push (only if changes)
  $pending = (git status --porcelain)
  if (-not [string]::IsNullOrWhiteSpace($pending)) {
    if (-not $NoCommit) {
      git add $migrationsDir | Out-Host
      git add (Join-Path $repoRoot 'scripts/ROOTED_CANONICAL_MIGRATION_NORMALIZE_VALIDATE_GATE_V7.ps1') 2>$null | Out-Host
      git commit -m 'fix(migrations): canonical gate V7 (normalize all DO blocks + validator handles $$ language ...; closers)' | Out-Host
      if (-not $NoPush) { git push | Out-Host } else { Write-Host 'ROOTED: NoPush set — skipping git push.' -ForegroundColor DarkGray }
    } else {
      Write-Host 'ROOTED: NoCommit set — leaving changes uncommitted.' -ForegroundColor Yellow
    }
  } else {
    Write-Host 'ROOTED: No git changes to commit.' -ForegroundColor DarkGray
  }

  if ($DoReset) {
    Write-Host ''
    Write-Host 'ROOTED: Running supabase db reset --debug (explicit -DoReset)...' -ForegroundColor Cyan
    supabase db reset --debug | Out-Host
  } else {
    Write-Host ''
    Write-Host 'ROOTED: Skipping supabase db reset (run with -DoReset to execute).' -ForegroundColor DarkGray
  }

} finally {
  if ($didStash) {
    Write-Host 'ROOTED: Restoring auto-stash (git stash pop)...' -ForegroundColor Yellow
    git stash pop | Out-Host
  }
}