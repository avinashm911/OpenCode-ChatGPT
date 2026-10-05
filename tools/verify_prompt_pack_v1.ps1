$ErrorActionPreference = 'Stop'

$root = (Get-Location).Path
$pack = Join-Path $root 'docs\opencode_master_prompts'
$htmlFiles = @(Get-ChildItem -LiteralPath $root -Filter '*.html' -File | Sort-Object Name)
$corePattern = '\b(?:FR-COM-\d{3}|FR-M\d{2}(?:-\d{3})?|OD-(?:DB|FD|UI)-\d{3}|OD-\d{3}|FG-\d{3}|G0-(?:CON|DEF|SCH|VER|OWN)-\d{3}|D-M\d+|D-\d+|M\d{2}|DSS-C-\d{3}|DSS-O\d+|DB-\d{3}|TC-[A-Z0-9-]+|US-\d{3}|AC-\d{3}|RLS-\d{3}|WP-\d{2}|W-\d{2}|TD-[A-Z0-9-]+|UI-\d{3}|UX-\d{3}|REG-[A-Z0-9-]+|RTM-[A-Z0-9-]+|O-[A-Z0-9?]+(?:-\d+)?|A-(?:FG-\d+|\d+)|R-\d+|V-FG-\d+)\b'

function Get-UniqueIds([string]$text) {
    @([regex]::Matches($text, $corePattern) | ForEach-Object Value | Sort-Object -Unique)
}

function Get-Counts([string[]]$values) {
    $counts = @{}
    foreach ($value in $values) {
        if ($counts.ContainsKey($value)) { $counts[$value]++ } else { $counts[$value] = 1 }
    }
    return $counts
}

function Get-NotExactlyOnce([string[]]$expected, [string[]]$actual) {
    $counts = Get-Counts $actual
    @($expected | Where-Object { -not $counts.ContainsKey($_) -or $counts[$_] -ne 1 })
}

if ($htmlFiles.Count -ne 15) { throw "FAIL: expected 15 HTML documents, found $($htmlFiles.Count)" }
$html = ($htmlFiles | ForEach-Object { Get-Content -Raw -LiteralPath $_.FullName }) -join "`n"
# Match the generator's authority boundary: IDs are indexed from table cells,
# not arbitrary prose, headings, history or change-log paragraphs.
$htmlCells = @([regex]::Matches($html, '<(?:td|th)[^>]*>([\s\S]*?)</(?:td|th)>', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase) | ForEach-Object { $_.Groups[1].Value }) -join "`n"
$rawCellIds = Get-UniqueIds $htmlCells

$matrixText = Get-Content -Raw -LiteralPath (Join-Path $pack 'TRACEABILITY_MATRIX.md')
$matrixIds = @($matrixText -split "`r?`n" | Where-Object { $_ -match '^\| ' -and $_ -notmatch '^\|---' -and $_ -notmatch '^\| ID \|' } | ForEach-Object { $_.Split('|')[1].Trim().Trim([char]96) })
$sourceIds = $matrixIds

$catalogText = Get-Content -Raw -LiteralPath (Join-Path $pack 'VERIFICATION_CATALOG.md')
$verificationIds = @([regex]::Matches($catalogText, '\*\*V-([^*]+)\*\*') | ForEach-Object { $_.Groups[1].Value })

$promptFiles = @(Get-ChildItem -LiteralPath $pack -Filter '??_*.md' -File | Sort-Object Name)
$ownerIds = @()
$failures = @()

foreach ($file in $promptFiles) {
    $text = Get-Content -Raw -LiteralPath $file.FullName
    $ownedSectionMatch = [regex]::Match($text, '(?ms)^## Owned IDs \(\d+\)\s*(.*?)(?=^### |\z)')
    $owned = @()
    if ($ownedSectionMatch.Success) {
        $owned = @([regex]::Matches($ownedSectionMatch.Groups[1].Value, '(?m)^- .+$') | ForEach-Object { $_.Value.Substring(2).Trim().Trim([char]96) })
    }
    $ownerIds += $owned
    $countMatch = [regex]::Match($text, '(?m)^## Owned IDs \((\d+)\)')
    if (-not $countMatch.Success -or [int]$countMatch.Groups[1].Value -eq 0) { $failures += "empty or malformed prompt: $($file.Name)" }
    foreach ($required in @('AGENTS.md', 'DECISIONS.md', 'GLOBAL_NO_INVENTION_CONTRACT.md')) {
        if (-not $text.Contains($required)) { $failures += "missing $required reference: $($file.Name)" }
    }
}

foreach ($id in $sourceIds) {
    $literal = [regex]::Escape($id)
    if (-not [regex]::IsMatch($htmlCells, "(?<![A-Za-z0-9_-])$literal(?![A-Za-z0-9_-])")) { $failures += "matrix ID not found in living HTML table cells: $id" }
    if (@($matrixIds | Where-Object { $_ -eq $id }).Count -ne 1) { $failures += "matrix missing/duplicate: $id" }
    if (@($ownerIds | Where-Object { $_ -eq $id }).Count -ne 1) { $failures += "owner missing/duplicate: $id" }
    if (@($verificationIds | Where-Object { $_ -eq $id }).Count -ne 1) { $failures += "verification missing/duplicate: $id" }
}

$sourceSet = @{}
foreach ($id in $sourceIds) { $sourceSet[$id] = $true }
foreach ($id in (@($ownerIds) + @($verificationIds) | Sort-Object -Unique)) {
    if (-not $sourceSet.ContainsKey($id)) { $failures += "unknown ID outside matrix source set: $id" }
}

foreach ($requiredPath in @(
    'niaverp\AGENTS.md',
    'niaverp\DECISIONS.md',
    'docs\opencode_master_prompts\SOURCE_INVENTORY.md',
    'docs\opencode_master_prompts\TRACEABILITY_MATRIX.md',
    'docs\opencode_master_prompts\VERIFICATION_CATALOG.md',
    'docs\opencode_master_prompts\STATUS_LEDGER.md',
    'docs\opencode_master_prompts\SOURCE_CLARIFICATIONS.md'
)) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $requiredPath))) { $failures += "missing required file: $requiredPath" }
}

if ($failures.Count -gt 0) {
    Write-Output 'PROMPT PACK v1.1 VERIFY: FAIL'
    $failures | ForEach-Object { Write-Output "- $_" }
    exit 1
}

Write-Output ('PROMPT PACK v1.1 VERIFY: PASS - 15 HTML documents, ' + $sourceIds.Count + ' core IDs, ' + $promptFiles.Count + ' non-empty prompts, one owner and one verification task per ID.')
