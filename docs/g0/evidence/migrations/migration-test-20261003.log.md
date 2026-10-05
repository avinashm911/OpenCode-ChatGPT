# Migration test evidence — Phase 1 — 2026-10-03 (UTC)

## Commands (workdir `E:\NiavERP v2 OpenAI\niaverp`, full-path flutter binary)
```
flutter.bat pub add --dev sqlite3
flutter.bat test test\migrations\migration_test.dart
flutter.bat test
flutter.bat analyze
```
Flutter SDK: `C:\Users\USER\.openclaw-autoclaw\agents\auto-designer\workspace\.cluster\tools\flutter`

## Environment
- OS: Windows 10 Pro 64-bit 22H2 (10.0.19045.6466)
- Flutter 3.47.5 stable (Framework 6a19cca564), Dart 3.13.4, DevTools 2.60.0
- `package:sqlite3 ^3.7.0` (resolved 3.7.0, direct **dev** dependency — disposable
  test databases only; production stays Drift + SQLCipher-class, library BLOCKED
  per G0-VER-001). Transitives added: ffi, file, glob, code_assets, hooks, etc.;
  `meta` bumped 1.18.3 → 1.19.0 by the resolver.
- Host SQLite (test execution): 3.53.4 in-memory. DDL restricted to
  widely-supported syntax (no ADD COLUMN IF NOT EXISTS — PRAGMA-guarded in the
  runner) so it also applies on old Android SQLite. On-device Android 8
  verification remains BLOCKED (G0-VER-005/008 — no test device supplied).

## Results
- `test test\migrations\migration_test.dart` → **00:00 +17: All tests passed!**
  (registry 2, clean-install 1, upgrade 1, repeat/failure-safe 2, constraints 8,
  validators 3)
- Full `flutter test` → **+18: All tests passed!** (17 migration + 1 template smoke)
- `flutter analyze` → **No issues found!**

## Coverage → acceptance
- Clean install creates complete schema: PASS (v8, 8-row ordered ledger, every
  G0-SCH table/column/index inspected via sqlite_master + PRAGMA table_info;
  tax tables verified EMPTY — no invented seed).
- Upgrade from previous schema succeeds: PASS (staged v1 + user rows → v8;
  rows intact, backfills record_version/base_version = 1, discounts = 0,
  PRAGMA foreign_key_check empty).
- Repeat-safe / fails safely: PASS (second run no-op; broken v8 leaves v7 + no
  partial columns).
- Schema inspection proves all seven deltas: PASS (per-delta table/column/index
  assertions, G0-SCH-001…007 each mapped exactly once in registry test).
- Rollback procedure documented; no in-place downgrade claimed: recorded in
  `docs/g0/MIGRATION_DESIGN.md` §2 (uninstall → install previous → restore
  external backup; no DOWN migrations by design, DSS-C-007).

## Notes
- All databases were disposable in-memory SQLite instances. No production data
  touched (none exists — greenfield).
- Discount amount-wins-over-rate precedence is PROPOSED for Phase 2 fixture
  confirmation; lifecycle enums stay TEXT (transitions are later-phase app logic).
