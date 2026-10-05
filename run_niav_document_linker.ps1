param([int]$Port = 8765)

$python = $null
foreach ($candidate in @('python', 'py')) {
    $command = Get-Command $candidate -ErrorAction SilentlyContinue
    if ($command) {
        & $command.Source --version *> $null
        if ($LASTEXITCODE -eq 0) { $python = $command; break }
    }
}
if (-not $python) {
    Write-Error "Python 3 is required to run NiAv Document Linker. Install Python 3, then run this script again."
    exit 1
}

& $python.Source ".\niav_document_linker.py" "--port" $Port
