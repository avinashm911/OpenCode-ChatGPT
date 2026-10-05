# Security test evidence — Phase 3 host suite (2026-10-03 UTC)

## Commands (workdir `E:\NiavERP v2 OpenAI\niaverp`)
```
flutter.bat pub add crypto
flutter.bat test test\security
flutter.bat test
flutter.bat analyze
```

## Environment
- Windows 10 Pro 64-bit 22H2; Flutter 3.47.5 / Dart 3.13.4
- `crypto 3.0.7` promoted transitive → direct (Dart-team, BSD-3, local-only;
  backup-manifest SHA-256). `sqlite3 3.7.0` dev-only (unchanged).
- Current-side emulator live: sdk_gphone64_x86_64, Android 16 / API 36, build
  BE2A.250530.026.F3; on-device SQLite 3.44.3; Keystore2/KeyMint present
  (see `DEVICE_MATRIX.md`). No Android 8 device exists on this host.

## Results
- `test\security` → **+23: All tests passed!**
  (key lifecycle/redaction 7, entitlements incl. DB tie-in 6, share allowlist 5,
  backup integrity/refusal/plan 5)
- Full `flutter test` → **+70: All tests passed!**
  (17 migration + 29 fixture + 23 security + 1 smoke)
- `flutter analyze` → **No issues found!**

## Acceptance mapping (host-provable part)
- No secrets logged: PASS — `DbKey`/result string forms asserted free of key
  bytes; failure messages are short static strings.
- Backup/restore guards: PASS — tamper detected (SHA-256), newer-schema
  restore refused (no in-place downgrade), post-reinstall re-provision forced.
- File sharing allowlist: PASS — spoofed magic, oversize, apk/exe/db/txt and
  extensionless files denied; approved jpg/png/pdf/xlsx/csv allowed.
- Keystore failure safety: PASS — outage/auth-fail/corrupt/wipe map to
  unusable states with re-provision as the only path back; no escrow API exists.
- Trial/denylist: PASS — ms-exact trial/grace/expiry boundaries, deny-wins,
  write/export capability matrix, anchor + hash-hit read from migrated DB.
- On-device execution (min + current): BLOCKED per `DEVICE_MATRIX.md` —
  recorded as blockers with procedures, never simulated-pass.

## Change log (Phase 3)
| Date | Change | Traceability |
|---|---|---|
| 2026-10-03 | Key lifecycle contract + 7 tests | D-06; G0-VER-001/005 |
| 2026-10-03 | Entitlement evaluation + 6 tests (trial/grace/deny) | D-04/O-05; G0-SCH-006 |
| 2026-10-03 | Share allowlist + 5 tests | OD-DB-005; G0-VER-008 |
| 2026-10-03 | Backup manifest/refusal/plan + 5 tests; crypto 3.0.7 direct | DB §8; DSS-C-007; RSP 5 |
| 2026-10-03 | Device matrix (API-36 emulator fingerprinted; API-26 BLOCKED) | O-M04; Phase 3 acceptance |
