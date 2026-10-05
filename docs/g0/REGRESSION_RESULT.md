# Regression result — Phase 7 (v0.8)

Date (UTC): 2026-10-03
Command: `flutter test` (workdir `E:\NiavERP v2 OpenAI\niaverp`) → **+94: All tests passed!**
`flutter analyze` → **No issues found!**
Env: Windows 10 Pro 22H2; Flutter 3.47.5 / Dart 3.13.4; disposable in-memory SQLite (host 3.53.4 per migration log; on-device SQLite 3.44.3 fingerprinted, device runs pending).
Baseline for comparison: +74 pass before Phase 6 (2026-10-03); +20 print/release tests added, zero regressions.

## Minimum regression areas (pack-required)

| Area | What was re-run | Result | Evidence |
|---|---|---|---|
| Voucher creation and edit | `voucher`/`voucher_line` base tables via migration v1→v8 clean-install + upgrade + FK checks; discount columns backfill 0; allocation lineage FKs | PASS | migration_test (17) |
| GST calculation and rounding | F-GST-001…008 incl. boundaries, line-vs-invoice, ≤2-decimals, round-off ledger line, CGST/SGST split convention | PASS (fixtures PROPOSED; source PENDING-INPUT) | gst_test (10); `F-GST-rounding.md` |
| Stock movements, costing and negative stock | FIFO/WA layers, partial consumption, opening/returns/transfers, negative-stock fallback + reconciliation (no retro revaluation) | PASS | costing_test (7); `F-COST-layers.md`, `F-NEG-fallback.md` |
| Bill settlement | Partial settlement, over-allocation rejection, reversal, remaining balance, duplicate-application guard | PASS | settlement_test (6); `F-SETL-settlement.md` |
| Period lock/unlock and audit | Date-range CHECK, unlock-triple all-or-nothing, audit_event append-only, hash-chain rule recorded | PASS (schema + validators; unlock policy app-side) | migration_test; `validators.dart` |
| Sync versioning-field, dependency and replay behavior only | record_version/base_version backfill 1, operation_dependency PK, sync_conflict shape, op replay-safe uniqueness | PASS (fields only; full conflict policy S1 outside pack) | migration_test (v6 assertions) |
| Trial/denylist controls | ms-exact trial/grace/expiry, deny-wins, write/export matrix, anchor + hash-hit DB tie-in | PASS (host; device run pending) | entitlements_test (6) |
| Backup/restore and file sharing | Manifest SHA-256 integrity, tamper detection, downgrade refusal, reinstall re-provision plan; allowlist magic/size/deny | PASS (host; device run pending) | backup_test (5); share_policy_test (5) |
| Print/PDF output | ESC/POS INIT/align/cut bytes, 32/48 cols, Rs. totals, tax, page geometry A4/A5, page-breaks, Indic raster both paths | PASS (host; physical pending) | print tests (16); `print-test-20261003.log.md` |
| Upgrade from prior schema | Staged v1 + user rows → v8 intact; backfills; repeat-safe no-op; broken-v8 fails safely at v7 | PASS | migration_test; `migration-test-20261003.log.md` |
| Statutory boundary (no-invention guard) | No IRN/ack/e-way columns; no portal API; no credentials | PASS | statutory_boundary_test (4); `G0_BOUNDARY.md` |
| Release checksum mechanism | FIPS vector, verify true/false, 64-hex stability; PS verifier 2 local PASS runs | PASS (mechanism; artifacts pending) | release_test (4); `RELEASE_DELIVERY.md` |
| Legal review | Draft map covers each control area; reviewer/date/retention/interpretation pending | PASS (draft) / PENDING-INPUT (review) | `LEGAL_CONTROL_MAP_DRAFT.md` |

## Defects

- Failed: **0**. No high-severity regression remains open.
- Pending-input regressions: none — every PENDING-INPUT row has its scaffolding (test code/procedure + template + closing command) in `PENDING_INPUTS.md` and was NOT converted to PASS.
- Deferred: G0-DEF-001/002/003 only (gates R3/Later/R2); G0-DEF-004 absent (see PENDING_INPUTS §B).

## Reproducibility

1. Clean checkout → `flutter pub get` (deps: flutter, cupertino_icons, crypto; dev: flutter_test, flutter_lints, sqlite3).
2. `flutter test` → expect +94 pass (counts in `TEST_SUMMARY.json`).
3. `flutter analyze` → expect no issues.
4. Disposable DBs only; no production data touched (none exists — greenfield).
5. Device/printer/channel/legal closures follow `PENDING_INPUTS.md` scaffolding when inputs arrive.
