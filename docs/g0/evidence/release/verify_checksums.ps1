#Requires -Version 5.1
<#
  NiAvERP G0 release checksum verifier — Phase 6.
  Verifies one artifact (APK, ZIP fallback, or any file) against an expected
  SHA-256 hex string. Mirrors the Dart contract in
  niaverp/lib/data/print/release_delivery.dart (verifyPayload).
  Usage:
    powershell -ExecutionPolicy Bypass -File verify_checksums.ps1 `
      -Artifact <path> -ExpectedHex <64-hex>
  Exit 0 = match; exit 1 = mismatch/missing.
  Traceability: R-04; G0-VER-004 (G5).
#>
param(
  [Parameter(Mandatory = $true)][string]$Artifact,
  [Parameter(Mandatory = $true)][string]$ExpectedHex
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $Artifact)) {
  Write-Output "VERIFY FAIL: artifact not found: $Artifact"
  exit 1
}
$actual = (Get-FileHash -LiteralPath $Artifact -Algorithm SHA256).Hash.ToLowerInvariant()
$expected = $ExpectedHex.ToLowerInvariant()
if ($actual -eq $expected) {
  Write-Output "VERIFY PASS: $Artifact"
  Write-Output "SHA256: $actual"
  exit 0
} else {
  Write-Output "VERIFY FAIL: $Artifact"
  Write-Output "expected: $expected"
  Write-Output "actual:   $actual"
  exit 1
}
