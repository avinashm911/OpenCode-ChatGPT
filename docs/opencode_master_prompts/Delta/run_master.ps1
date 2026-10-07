# Runs the master prompt repeatedly (one numbered prompt per opencode invocation) until DONE or a stop state.
# Usage (PowerShell, from the repository root):  .\run_master.ps1   [-MaxRuns 14]
param([int]$MaxRuns = 14)
$ErrorActionPreference = 'Stop'
$repo  = (Get-Location).Path
$proj  = Join-Path $repo 'niaverp'
$state = Join-Path $repo 'docs\implementation\MASTER_STATE.md'
$prompt = Join-Path $repo 'docs\opencode_master_prompts\delta\MASTER_run_prompts_00_to_13.md'
if (-not (Test-Path $prompt)) { throw "Master prompt not found: $prompt" }
Set-Location $proj
for ($i = 1; $i -le $MaxRuns; $i++) {
  if (Test-Path $state) {
    $text = Get-Content $state -Raw
    if ($text -match 'Status:\s*(DONE|STOPPED-FAIL|STOPPED-BLOCKED)') { Write-Host "Stopped: $($Matches[1]). Read $state"; break }
  }
  Write-Host "=== Master run $i ==="
  opencode run -f $prompt "Execute the attached master prompt exactly. Run only the next unfinished numbered prompt."
  if ($LASTEXITCODE -ne 0) { Write-Host "opencode exited with $LASTEXITCODE; stopping."; break }
}
Set-Location $repo
Get-Content $state -ErrorAction SilentlyContinue | Select-Object -First 40
