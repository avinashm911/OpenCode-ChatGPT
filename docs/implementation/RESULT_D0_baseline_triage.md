# RESULT D0 — Baseline triage: restore a green, honest baseline (re-run with prompt coverage audit)
Date (UTC): 2026-10-06   Overall status: PASS

## 1. Baseline before changes

- `flutter analyze` (from `E:\NiavERP v2 OpenAI\niaverp`, via
  `C:\Users\USER\.openclaw-autoclaw\agents\auto-designer\workspace\.cluster\tools\flutter\bin\cache\dart-sdk\bin\dart.exe
  ..\bin\cache\flutter_tools.snapshot analyze` — Flutter 3.47.6 / Dart 3.13.5):
  **No issues found**.
- `flutter test`: **404 passed / 0 failed** (`+404: All tests passed!`).
- git (repo root `E:\NiavERP v2 OpenAI`): HEAD was `e93944a` on branch
  `baseline-triage-20261006`; `git status --short` showed the committed D0
  repairs plus the D1 work (38 entries); `git diff --stat` against HEAD: only
  working-tree content already described in RESULT_D1. No-space alias not needed.
- Mandatory reads done: `niaverp/AGENTS.md`, `niaverp/DECISIONS.md`,
  `docs/IMPLEMENTATION_EXECUTION_STRATEGY.md`,
  `docs/opencode_master_prompts/GLOBAL_NO_INVENTION_CONTRACT.md`,
  `docs/g0/PENDING_INPUTS.md` (2026-10-03 + D1 §F note, unedited by this run),
  `docs/implementation/TEST_RUN_20261005.md`,
  `docs/implementation/RESULT_D1_repair_and_production_wiring.md` (now PASS).
  Missing phase reports (stated, not invented): `phase-00.md`, `phase-01.md`,
  `phase-02.md` referenced by `AGENTS.md` are absent from `docs/implementation/`.
- Note on the Situation text: it describes the pre-first-D0 state (331/40).
  That state no longer exists: the first D0 run repaired it (374/0) and the D1
  run extended it (404/0). This re-run therefore classifies zero failing tests.
- Safety: new branch `baseline-triage-20261006-d0r2`, `git add -A`, commit
  `e67af1c "WIP before D0 triage"`. Not pushed. Nothing reset, cleaned or deleted.

## 2. Work-item table

### B. Failing-test classification (this run: none)

Full-suite result is 404/0, so there are no failing tests to classify and no
repairs to order — C1–C4 do not trigger. The 40 pre-first-D0 failures (13
migration v15 pins + 2 asset-list pins + 1 broken helper + 24 stale seedings,
all classed `stale-by-documented-rule` except the one `broken-helper`) were
classified row-by-row and repaired in the first D0 run; the full 40-row table
is preserved in git commit `e67af1c`
(`docs/implementation/RESULT_D0_baseline_triage.md` as committed there).
Spot-verification this run: the green 404 total includes every previously
failing file (migrations, boundary, books, ledger_books, settlement_report,
voucher_engine, held_bill, voucher_repository, books_report, hub_screens,
outstanding_report) — all pass unmodified since D1.

### D. D1 work-item inventory, post-D1 state (code read + tests run)

| ID | Item | Inventory | Evidence |
|---|---|---|---|
| A1 | Kotlin Keystore channel | present-untested | `MainActivity.kt:40-181`; minSdk 26 (`build.gradle.kts:21`); no host test can exercise on-device Keystore — device proof stays G0-VER-005 |
| A2 | Dart KeyProvider + opener takes key | present-and-tested | `channel_key_provider_test.dart` (6 mapping tests); `key_provider.dart` provision fix |
| A3 | Startup sequence + scopeOfBackend + states | present-and-tested | Exercised end-to-end by `startup_test.dart` |
| A4 | main()/startup widget test | present-and-tested | `startup_test.dart` (ready data, key-failure state, no-fallback) |
| B1 | Close releases handle + reopen | present-and-tested | `cipher_opener_test` reopen; `ffi_database_test` close group |
| B2 | PRAGMA-key guard + redaction | present-and-tested | `cipher_opener_test` wrong-key + junk-file redaction tests |
| B3 | Safe rollback | present-and-tested | `ffi_database_test` rollback + already-ended tests |
| B4 | backend() closes on bootstrap throw | present-and-tested | `production_boundary_test` bootstrap-failure test; `CloseableMigrationDb` cascade |
| C1 | UUIDv7 generator | present-and-tested | `test/core/uuid_v7_test.dart` (6 incl. 10k uniqueness) |
| C2 | UUIDv7 production minting | present-and-tested | `UuidV7WriteContext` via startup; `CounterIdMint` tests-only |
| D1 | cancelPosted full reversal | present-and-tested | `voucher_cancel_test.dart` (restore + locked refusal + atomicity) |
| D2 | updateHeldStatus refuses posted | present-and-tested | `held_bill_test` refusal test |
| D3 | postDraft single-tx path | present-and-tested | Delegates (`voucher_engine.dart:263-286`); engine post tests |
| D4 | addLine draft/held only | present-and-tested | Posted/cancelled refusal test |
| D5 | company_id cost scoping | present-and-tested | Two-company same-code test |
| D6 | Real actor on movement audit | present-and-tested | Actor assertion in cancel test; no `'posting-engine'` literal in repo |
| D7 | Missing godown rejected | present-and-tested | `voucher_posting_test` godown rejection test |
| D8 | Fallback/zero first issue locks method | present-and-tested | Zero-lock test in `voucher_cancel_test.dart` |
| D9 | Empty must-balance journal | present-and-tested | Behaviour confirmed per DECISIONS.md (allows empty) + documenting test |

### E. Prompt coverage audit 00–13 (evidence in tree, not file names alone)

`docs/implementation/` holds only `TEST_RUN_20261005.md`,
`RESULT_D0_baseline_triage.md`, `RESULT_D1_repair_and_production_wiring.md`,
`RESULTS_INDEX.md` — no per-prompt phase reports exist (00–13).

| Prompt | Verdict | Concrete artifacts / gap |
|---|---|---|
| 00 resume baseline | partial | Intake performed (D0/D1 reads, TEST_RUN, triage reports); `phase-00/01/02.md` missing so full comparison impossible |
| 01 local backend | partial | m001–m016 + registry/runner, all repositories, cipher/key/startup wiring, 404 host tests; production-encryption/device proof pending (G0-VER-001/005) |
| 02 onboarding/localisation | partial | `onboarding_screen` + company setup + tests; native-script search present; no locale bundles (no `.arb`), no glossary artifact found |
| 03 masters/search | complete | m009, party/item/unit/godown/series/type/alias repos, `MasterSearch`, all tested; FR-M03-008/009 deferred by design (STATUS_LEDGER) |
| 04 voucher engine/orders | complete | Engine + 19 types + numbering + settlement + orders-guard + tests; ledger/GST posting explicitly downstream (D3) |
| 05 document flow/approvals/counter | partial | `document_flow` + links + held/counter queue + tests; M10 approval matrix absent (P2 per STATUS_LEDGER) |
| 06 inventory/accounting/reports | partial | Costing, books/outstanding/stock reports + screens + tests; P&L/Balance Sheet/GST pending (P-BOOKS) |
| 07 import/GST/statutory | partial | Statutory boundary only (`statutory_boundary_test` negatives, empty m005 tables); no import pipeline — no `import_export` code, no mapping/preview/commit UI |
| 08 admin/users/licensing | partial | Entitlements/trial/denylist + period-lock admin + tests; no users/roles slice, no admin screens, unlock rights pending M19 |
| 09 security/backup/sync | partial | `backup.dart` + restore validation + share policy + key lifecycle + op-log/sync fields (m006) + tests; no sync transport (S1 by design) |
| 10 outputs/customisation/support | partial | ESC/POS + PDF + templates + layout profiles + `release_delivery` + tests; no help/support screens (M24 P2); physical print proof pending |
| 11 frontend completion | partial | Five tabs bound to real services, startup states, billing/inventory forms, widget tests; full per-screen state matrix not audited in this run |
| 12 hardware/release/evidence | not-run | No APK/ZIP/device/printer evidence records; the prompt's own IDs are blocked-evidence |
| 13 final verification | not-run | No gate report; only TEST_RUN + RESULT files exist |

Still to run after the D1–D4 deltas: 07, 08, 09, 10, 11 (missing parts) and 12, 13 (not run).

## 3. Changed files (new / modified / deleted, one line each)

- This run: no source, test, migration, pubspec, Android, HTML, or register
  edits (baseline was already green; B/C triggered nothing).
- NEW/OVERWRITTEN docs/implementation/RESULT_D0_baseline_triage.md (this file:
  re-verified baseline + post-D1 inventory + new §E audit).
- Deleted: none.

## 4. Tests

- Added: 0. `flutter analyze` → No issues found. `flutter test` → 404/0.
- Nothing repaired (nothing failing); nothing skipped (full suite run).

## 5. Commands run and exact output summary

- `git rev-parse --short HEAD` → `e93944a` (pre-run); branch shown
  `baseline-triage-20261006`.
- `git switch -c baseline-triage-20261006-d0r2; git add -A; git commit -m "WIP
  before D0 triage"` → `e67af1c`, tree clean. Not pushed.
- `flutter analyze` → `No issues found! (ran in 1.3s)`.
- `flutter test --reporter expanded` → `+404: All tests passed!` (~31s).
- Read-only greps for §E: `approv*` (no approval-matrix code, only boundary
  comments), `*.arb` (none), `data/import_export/**` (none), users/roles slice
  (absent; M19 pending), presentation screens list (19 screens; no
  admin/backup/import/help/users screens).
- Environment: same SDK invocation as D0/D1; no alias needed.

## 6. Deviations from the prompt, with reason

- No B-classification rows for new failures: there are none. The full
  historical 40-row table is preserved in git (`e67af1c`) rather than
  duplicated here; §2-B records the carry-over and its verification.
- No repairs, no test changes at all: C-ordering was vacuous on a green
  baseline, and the prompt forbids weakening tests and starting D1 features.
- §E verdicts use `partial` for boundary-by-design gaps (deferred/excluded IDs
  are recorded as such, not as missing work).

## 7. Owner questions (exact source ID + question) and downstream evidence still pending

- P-SQLIB (`docs/g0/PENDING_INPUTS.md` §A, still PENDING-INPUT): "Which exact
  SQLCipher-class library, version, and licence evidence is approved, with
  Android 8 proof?" — D1 §F note added; owner must confirm to close.
- G0-VER-001/005/008 and G0-VER-003/004/006/007: device, cipher-licence,
  statutory, printer, legal, and delivery evidence — all pending; nothing here
  converts host evidence into PASS.
- Missing `phase-00/01/02.md` reports: owner to confirm whether
  `TEST_RUN_20261005.md` alone is the baseline record (repeated).
- No new `blocked` items from this run.

## 8. Honesty statement

- 404 passing tests are host/in-memory runs; nothing here is device, printer,
  legal, statutory, or release evidence.
- §E is based on tree reads (file listings, targeted greps, test inventory);
  verdicts cite concrete artifacts or their verified absence. No mock or
  scaffold result is presented as production evidence. No field, rule, package,
  permission, or platform behaviour was invented; no HTML, workbook, or register
  was edited; no test was added, deleted, or weakened in this run.

## 9. Next prompt

- D2 (`delta/D2_schema_and_security_hardening.md`) remains next per the Delta
  order (do not run it after FAIL — this run is PASS). After D2–D4, run master
  prompts 07, 08, 09, 10, 11 (missing parts) then 12, 13.
