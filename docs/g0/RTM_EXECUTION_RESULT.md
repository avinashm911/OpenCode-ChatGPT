# RTM execution result — Phase 7 (v0.8)

Date (UTC): 2026-10-03
Prompt authority: `NiAv_G0_Prompts_Pack_v0.8.md` Phase 7
Full-suite command (workdir `E:\NiavERP v2 OpenAI\niaverp`):
`flutter test` → **+94: All tests passed!**; `flutter analyze` → **No issues found!**
Env: Windows 10 Pro 22H2; Flutter 3.47.5 / Dart 3.13.4; `sqlite3` dev-only disposable DBs.
Source registers/HTML/workbooks untouched (read-only); PENDING-INPUT detail in `PENDING_INPUTS.md`.

> Every G0 schema change has implementation + test traceability below. Every
> verification record has evidence or a PENDING_INPUTS row with its closing
> step. No PENDING-INPUT was converted to PASS for lack of a test.

## 1. Seven approved schema changes (G0-SCH-001…007)

| ID (gate) | Implementation file(s) | Migration / fixture | Test case(s) | Result | Evidence path | Defect / owner action |
|---|---|---|---|---|---|---|
| G0-SCH-001 (G1) cost layers + movements, FIFO/WA, negative-stock fallback + reconciliation | `lib/data/migrations/m002_sch001_cost_layers.sql`; `lib/data/accounting/costing.dart` | Migration v2; fixtures F-COST-001…005, F-NEG-001/002 | `test/migrations/migration_test.dart` (registry/clean/upgrade/repeat/constraints); `test/accounting/costing_test.dart` (7) | PASS | `docs/g0/MIGRATION_DESIGN.md` §3; `docs/g0/evidence/migrations/migration-test-20261003.log.md`; `docs/g0/evidence/fixtures/F-COST-layers.md`, `F-NEG-fallback.md` | None on host; method-lock UX + reconciliation policy are app logic (later phases) |
| G0-SCH-002 (G1) period lock | `m003_sch002_period_lock.sql`; `validators.dart:validatePeriodLock` | Migration v3 | migration_test (constraints: date CHECK, unlock-triple validator) | PASS | Same migration log + design doc | Unlock authorisation + audit linkage enforced app-side (Phase 2+); no defect |
| G0-SCH-003 (G1) bill allocation | `m004_sch003_bill_allocation.sql`; `lib/data/accounting/settlement.dart` | Migration v4; fixtures F-SETL-001…006 | migration_test; `test/accounting/settlement_test.dart` (6, DB-backed) | PASS | `F-SETL-settlement.md`; migration log | Reversal lifecycle beyond active/reversed is later policy; no defect |
| G0-SCH-004 (G1) tax/HSN + layout profiles | `m005_sch004_tax_layout.sql`; `lib/data/accounting/gst.dart` | Migration v5; fixtures F-GST-001…008 | migration_test (empty-tax-table assertion: no invented seed); `test/accounting/gst_test.dart` (10) | PASS | `F-GST-rounding.md`; migration log | Statutory field values await verified schemas (P-EINV/GSTR/EWAY-SCH); tables ship empty by design |
| G0-SCH-005 (S1) record/operation versioning | `m006_sch005_versioning.sql` (record_version, base_version, operation_dependency, sync_conflict) | Migration v6 | migration_test (versioning/backfill/dependency/conflict-shape assertions) | PASS | Migration log; design doc §3 | Full conflict-policy implementation is S1 outside this pack (fields only) |
| G0-SCH-006 (G0) trial anchor + denylist | `m007_sch006_trial_denylist.sql`; `lib/data/security/entitlements.dart` | Migration v7 | migration_test (UNIQUE anchor/hash); `test/security/entitlements_test.dart` (6 incl. DB tie-in) | PASS | Migration log; `security-test-20261003.log.md` | On-device lifecycle run PENDING-INPUT (P-KEYSTORE) |
| G0-SCH-007 (G1) voucher-line discount | `m008_sch007_discount.sql`; `validators.dart:discountFor/lineNet` | Migration v8; fixtures F-DISC-001…006 | migration_test; `test/accounting/discount_test.dart` (6) | PASS | `F-DISC-discounts.md`; migration log | Precedence + tax-base PROPOSED (P-DISC-PREC) |

## 2. Verification records (8)

| Record (gate) | Implementation / evidence | Tests | Result | Evidence path | Owner action |
|---|---|---|---|---|---|
| G0-VER-001 (G0) encrypted SQLite lib for Drift/Android 8+ | Approach recorded; NO dependency added until confirmed | — (no lib to test) | PENDING-INPUT | `PROJECT_BASELINE.md` §7; `PENDING_INPUTS.md` P-SQLIB | Supply library/version/licence + Android 8 proof |
| G0-VER-002 (G0) GST rounding rule + golden fixture | `gst.dart` + F-GST fixtures (PROPOSED from D-M4) | gst_test 10 pass | PENDING-INPUT (source) / PASS (fixtures) | `F-GST-rounding.md`; P-GST-SRC | Attach official rule source |
| G0-VER-003 (G3) GST/e-invoice/e-way schemas | Boundary: no columns, no API, no credentials; pointers recorded | `test/adapters/statutory_boundary_test.dart` 4 pass | PENDING-INPUT (field list + schemas) | `G0_BOUNDARY.md`; P-FIELD-LIST/P-EINV/P-GSTR/P-EWAY-SCH | Supply field list + pinned versions + samples |
| G0-VER-004 (G5) WhatsApp/email delivery + checksums | `release_delivery.dart` + PS verifier; 2 local PASS runs (mechanism only) | `test/release/release_test.dart` 4 pass | PENDING-INPUT (APK/ZIP + channel receipts) | `RELEASE_DELIVERY.md`; P-APK/ZIP/CH-* | Cut release build; run channel tests |
| G0-VER-005 (G0) Keystore on Android 8 | `key_lifecycle.dart` contract; failure-safe, redacted | `key_lifecycle_test.dart` 7 pass (host) | PENDING-INPUT (device) | `security-test-20261003.log.md`; `DEVICE_MATRIX.md`; `DEVICE_TEST_PROCEDURE.md`; P-KEYSTORE | Assign devices + lib; run D-KEY steps |
| G0-VER-006 (G5) printer compatibility (≥3) | `print/template.dart`, `escpos.dart`, `pdf_layout.dart`; golden tests | print tests 16 pass | PENDING-INPUT (physical) | `print-test-20261003.log.md`; `PRINTER_TEST_SHEET.md`; P-PRN-* | Freeze OD-FD-006 matrix; run sheet |
| G0-VER-007 (G5) data-protection obligations + control map | `LEGAL_CONTROL_MAP_DRAFT.md` (DRAFT, not a legal review) | — (review activity) | PENDING-INPUT (reviewer/date/retention/interpretation) | Legal draft; P-LEGAL-001…005 | Name reviewer; set date; review |
| G0-VER-008 (G5) file-provider/share/restore | `share_policy.dart` + `backup.dart` guards | share 5 + backup 5 pass (host) | PENDING-INPUT (device) | security log; DEVICE docs; P-KEYSTORE | Run D-SHARE/D-BKP steps on device |

## 3. Contradiction families + exclusions (G0-CON-001…005, voice)

| ID | Code boundary (attested) | Result | Evidence |
|---|---|---|---|
| G0-CON-001 TDS/TCS later, PF/ESI/payroll out | No TDS/TCS/payroll code in `lib/` (grep: no match beyond template prose) | PASS | This file + grep run 2026-10-03 |
| G0-CON-002 Tally/Busy native = R3 only | No native adapter code; Excel path only (no xls parser added) | PASS | Same |
| G0-CON-003 rollback = uninstall→install→restore; no in-place downgrade | No DOWN migrations; `backup.dart:checkRestorable` refuses newer-schema; tested | PASS | `backup_test.dart` downgrade-refusal; `MIGRATION_DESIGN.md` §2 |
| G0-CON-004 field merge, host-arrival-wins, loser logged | `sync_conflict` shape per OD-DB-006; versioning fields; no invented policy engine | PASS (fields) | `m006_sch005_versioning.sql`; full policy is S1 outside pack |
| G0-CON-005 Home, Billing, Parties & Items, Reports, More | No contradictory nav variant in code (no nav code in G0 scope) | PASS | Baseline §1; Phase 8 re-checks documents |
| Voice (G0-OWN-002, rejected) | No voice code/permission/UI in `lib/`; no `speech_to_text` dep | PASS (excluded) | pubspec + grep 2026-10-03 |
| Direct e-invoice/e-way APIs; server/cloud; TDS/TCS; transliteration | None in `lib/`; no `http/dio`; no credentials | PASS (excluded) | pubspec + `statutory_boundary_test.dart` |

## 4. Deferred (not counted as passed)

G0-DEF-001 (R3), G0-DEF-002 (Later release), G0-DEF-003 (R2) — see `PENDING_INPUTS.md` §B. G0-DEF-004 does not exist; field capture is PENDING-INPUT, not DEFERRED.

## 5. Machine-readable summary

`docs/g0/TEST_SUMMARY.json` (counts, command, env, status). Source registers untouched.
