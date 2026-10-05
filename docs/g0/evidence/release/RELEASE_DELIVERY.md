# Release-delivery verification — Phase 6 (v0.8)

Date (UTC): 2026-10-03
Prompt authority: `NiAv_G0_Prompts_Pack_v0.8.md` Phase 6
Traceability: R-04; G0-VER-004 (gate G5); RSP release sections

## Approved channels (fixed, not invented)

- WhatsApp/email
- ZIP fallback
- ₹0 hosted link (recorded as `Rs0 hosted link` in ASCII code)

Defined in `niaverp/lib/data/print/release_delivery.dart` (`kApprovedChannels`);
contract tests in `niaverp/test/release/release_test.dart` (4 pass, incl. FIPS
SHA-256("abc") vector).

## Checksum mechanism (host PASS)

- Dart contract: `sha256HexBytes()` / `verifyPayload()` (package:crypto).
- PowerShell mirror: `docs/g0/evidence/release/verify_checksums.ps1`
  (`-Artifact <path> -ExpectedHex <64-hex>`; exit 0 = match).
- Local runs (Windows 10 Pro 22H2, PowerShell 5.1):

```powershell
powershell -ExecutionPolicy Bypass -File verify_checksums.ps1 `
  -Artifact niaverp\pubspec.yaml `
  -ExpectedHex 5998b942fcde576b113d54155b241411a96ca2916e0809b535b691178c5be1a6
# → VERIFY PASS + SHA256 printed, EXIT 0

powershell -ExecutionPolicy Bypass -File verify_checksums.ps1 `
  -Artifact docs\g0\evidence\printers\PRINTER_TEST_SHEET.md `
  -ExpectedHex 7afcf5423135a415c73f3ba7da2c0c5d6f3250d5422377f903ef4337d8cb07aa
# → VERIFY PASS + SHA256 printed, EXIT 0
```

These runs prove the **script works** on representative files. They are not
claimed as APK/ZIP delivery evidence.

## Why no APK/ZIP hashes are recorded here

G0 is the acceptance baseline, not a release cut. No release APK or ZIP
fallback was built in this phase (the scaffold `niaverp/` app is a template
counter app, not a NiAvERP release candidate — building it as a "release"
would fabricate evidence). Committing template-APK hashes as release checksums
would violate global rule 15 (never fabricate evidence).

## Open rows (v0.8 PENDING-INPUT)

| Row | Status | Missing input | Closing step |
|---|---|---|---|
| R-APK-SHA | PENDING-INPUT | Release APK bytes + versionName/versionCode | Build release APK → `verify_checksums.ps1 -Artifact <apk> -ExpectedHex <hex>` → record hash + command + env in this dir |
| R-ZIP-SHA | PENDING-INPUT | ZIP fallback bytes | Same for the ZIP |
| R-CH-WA | PENDING-INPUT (channel) | Real WhatsApp delivery test with captured receipt | Send APK/ZIP via approved channel; attach receipt + hash match |
| R-CH-EM | PENDING-INPUT (channel) | Real email delivery test with captured receipt | Same |
| R-CH-LINK | PENDING-INPUT (channel) | Real ₹0 hosted-link fetch with captured bytes | Fetch link; verify hash; attach log |

Smallest owner question: when is the first release build cut, and which
APK/ZIP artifacts + channel receipts should be verified (or confirm G0 needs
only the mechanism, with artifact hashes deferred to the release gate)?

## Change log

| Date | Change | Traceability |
|---|---|---|
| 2026-10-03 | Checksum contract + tests + PS verifier + 2 local PASS runs; APK/ZIP/channel rows left PENDING-INPUT; no delivery claimed | R-04; G0-VER-004; pack v0.8 Phase 6 |
