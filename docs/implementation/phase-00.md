# Implementation Phase 00 — intake and architecture

Date (UTC): 2026-10-03
Prompt: `docs/opencode_master_prompts/00_intake_and_architecture.md`
Contract: `docs/opencode_master_prompts/GLOBAL_NO_INVENTION_CONTRACT.md`
Authority: `docs/IMPLEMENTATION_EXECUTION_STRATEGY.md` Slice 0; `NiAv_G0_Prompts_Pack_v0.9.md`;
  `niaverp/DECISIONS.md`; `docs/g0/PENDING_INPUTS.md`; `docs/g0/G0_UNCONDITIONAL_SIGNOFF.md`
  (G0 baseline only — downstream gates open); 15 HTML requirement documents (read-only).
Previous phase report: none (first implementation prompt).

## Objective

Replace the Flutter counter scaffold with a clean NiAvERP application
foundation. No business features; no database wiring.

## Changed files

New foundation (all new, no prototype modified):
- `niaverp/lib/main.dart` (rewritten) — owns `CompositionRoot.system()`, runs `NiavApp`.
- `niaverp/lib/app/niav_app.dart` — MaterialApp root over the five-item shell.
- `niaverp/lib/app/composition_root.dart` — hand-rolled DI (AppConfig + Clock).
- `niaverp/lib/core/result.dart` — sealed `Result<T>` (`Ok`/`Err`) + `AppError(code,message)` + `mapResult`.
- `niaverp/lib/core/clock.dart` — `Clock` / `SystemClock` / `TestClock`.
- `niaverp/lib/core/value_objects/money.dart` — `MoneyPaise` (int paise, ≤2-decimal render).
- `niaverp/lib/core/value_objects/quantity.dart` — `QuantityQ4` (int ×10⁴, explicit 0–4 scale format).
- `niaverp/lib/core/value_objects/ids.dart` — `EntityId` / `CompanyId` (non-empty text; UUIDv7 generation later).
- `niaverp/lib/core/value_objects/niav_date.dart` — `NiavDate` (ISO YYYY-MM-DD validation).
- `niaverp/lib/domain/domain.dart` — boundary placeholder (no invented behavior).
- `niaverp/lib/application/application.dart` — boundary placeholder.
- `niaverp/lib/presentation/shell/niav_shell.dart` — five-item shell (`NiavDestination`, `NiavShell` + `IndexedStack` + `BottomNavigationBar`).

Tests (new):
- `niaverp/test/core/result_test.dart` (3 tests).
- `niaverp/test/core/value_objects_test.dart` (8 tests: money 2, quantity 2, ids 2, date 1, clock 1).
- `niaverp/test/presentation/shell_test.dart` (3 widget tests: five destinations render, tab switching, config injection).

Removed:
- `niaverp/test/widget_test.dart` (Flutter template counter test; superseded by shell tests).

Untouched (still compiling, behavior preserved):
- `niaverp/lib/data/**` (accounting, migrations incl. 8 SQL files, security, print prototypes).
- All 15 HTML documents, workbooks, source registers (read-only; never edited from implementation).
- `niaverp/pubspec.yaml` (no package added), Android Gradle files (minSdk 26 intact).

## Decisions / blockers (no invention)

- No package selected: Riverpod/go_router/PDF/Excel/barcode/ESC-POS stay UNVERIFIED
  candidates per `docs/g0/PROJECT_BASELINE.md` §6 and `PENDING_INPUTS.md` P-SQLIB row.
  Shell uses `BottomNavigationBar` + `IndexedStack`; DI is hand-rolled. Blocker recorded,
  dependent change stopped — no silent selection.
- No database wiring started (per prompt §“Do not start database wiring”): Drift/SQLCipher
  integration waits on P-SQLIB (library/version/licence + Android 8 proof) — prompt 01 gate.
- Value objects enforce storage shapes only (D-M4); rounding/posting/tax/period/entitlement
  rules stay in existing engines and later slices. UUIDv7 generation, unit-specific display
  decimals, and financial-year policy are explicitly later concerns.
- Shell holds only the selected tab index (navigation chrome). No voucher/stock/accounting
  state in widgets.

## Commands and environment

Workdir `E:\NiavERP v2 OpenAI\niaverp`; Flutter 3.47.5 / Dart 3.13.4; Windows 10 Pro 22H2.
Flutter SDK: `C:\Users\USER\.openclaw-autoclaw\agents\auto-designer\workspace\.cluster\tools\flutter\bin\flutter.bat`.

- `flutter analyze` → **No issues found!**
- `flutter test` → **+107: All tests passed!**
  (94 prior − 1 counter removed + 14 new: result 3, value objects 8, shell 3; all 14 pre-existing
  suites — migration 17, accounting 29, security 23, boundary 4, print 16, release 4 — still green.)

## Traceability IDs

OD-UI-001 / G0-CON-005 (five-item shell); D-M4/OD-DB-001 (paise, Q4, ISO date, epoch-ms);
DSS-C-001 (company scope via distinct `CompanyId` type); AGENTS.md + strategy Slice 0
 Result/error model, DI root, no-widget-business-state).

## Unresolved items / downstream pending evidence

Carried from `docs/g0/PENDING_INPUTS.md` (unchanged by this prompt):
P-SQLIB (blocks prompt 01 DB wiring), P-DEVICE-8/CUR + P-KEYSTORE (device runs),
P-FIELD-LIST + P-EINV/GSTR/EWAY-SCH (G3/R1a), P-LEGAL-001…005 (G5),
P-PRN-001…003 + P-APK/ZIP-SHA + P-CH-WA/EM/LINK (G5). P-GST-SRC / P-DISC-PREC are
owner-decided; their fixture reruns remain verification actions. Deferred:
G0-DEF-001:R3, G0-DEF-002:Later-release, G0-DEF-003:R2.

## Acceptance check

- [x] App launches to the five-item shell (Home, Billing, Parties & Items, Reports, More).
- [x] No business state stored only in widgets (shell keeps tab index only).
- [x] `flutter analyze` clean.
- [x] `flutter test` passes (+107).
- [x] This report records changed files, commands, results, unresolved items.

## Next gate

Prompt 01 — local backend foundation (strategy Slice 1 / train `01`): record/select the
SQLCipher-class library decision or stop at that boundary; wire Keystore-wrapped key +
Drift over encrypted SQLite; convert migration runner into repository/database service.
Do not build business screens before the persisted backend slice works.
