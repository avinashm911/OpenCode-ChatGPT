# RESULT D0 — Baseline triage: restore a green, honest baseline
Date (UTC): 2026-10-06   Overall status: PASS

## 1. Baseline before changes

- `flutter analyze` (from `E:\NiavERP v2 OpenAI\niaverp`, via
  `C:\Users\USER\.openclaw-autoclaw\agents\auto-designer\workspace\.cluster\tools\flutter\bin\cache\dart-sdk\bin\dart.exe
  ..\bin\cache\flutter_tools.snapshot analyze` — `flutter.bat` is absent from
  this SDK copy; Flutter 3.47.6 / Dart 3.13.5): **5 issues, all in
  `test/application/books_test.dart`** (1 `unused_local_variable` warning +
  4 errors: `PostingResult`/`SeedLine`/`seeder` undefined).
- `flutter test`: **331 passed / 40 failed** (`+331 -40`). Last known green
  record `docs/implementation/TEST_RUN_20261005.md`: 373 passed, analyze clean.
- git (repo root `E:\NiavERP v2 OpenAI`): HEAD was `6f2051a6360ca8403e493c1d86b41a04394e3187`
  (short `6f2051a`); `git status --short` showed **36 untracked files, 0 tracked
  modifications**; `git diff --stat` empty. I.e. the partial D1-shaped work is
  committed at HEAD; only helper scripts and the two D1 results files were
  untracked. No-space drive alias was not needed.
- Mandatory reads done: `niaverp/AGENTS.md`, `niaverp/DECISIONS.md`,
  `docs/IMPLEMENTATION_EXECUTION_STRATEGY.md`,
  `docs/opencode_master_prompts/GLOBAL_NO_INVENTION_CONTRACT.md`,
  `docs/g0/PENDING_INPUTS.md` (2026-10-03, unedited),
  `docs/implementation/TEST_RUN_20261005.md`,
  `docs/implementation/RESULT_D1_repair_and_production_wiring.md` (FAIL).
  Missing phase reports (stated, not invented): `phase-00.md`, `phase-01.md`,
  `phase-02.md` referenced by `AGENTS.md` are absent from `docs/implementation/`.
- Safety: new branch `baseline-triage-20261006`, `git add -A`, commit
  `e93944a "WIP before D0 triage"`. Not pushed. Nothing reset, cleaned or deleted.
  All triage edits below are on this branch.

## 2. Work-item table

### B. Failing-test classification (40/40 + compile failure; each run in isolation)

Class key: S = `stale-by-documented-rule`, H = `broken-helper`.
No test classified `real-regression`, `environment` or `unknown`.

| # | Test | Class | Cause | Evidence |
|---|---|---|---|---|
| 1 | migration_test: registry versions contiguous 1..15 | S | Pins `[1..15]`/`kLatestVersion==15`; registry is at v16 (m016, D1-D5) | `Expected: [1..15] / Actual: [1..16]`, `migration_registry.dart:142-143` (`kLatestVersion = 16`) |
| 2 | migration_test: clean install migrates to v15 | S | Same version pin; ledger expects 15 rows | Same `[1..15]` vs `[1..16]` diff |
| 3 | migration_bank: columns/bank table exist at v15 | S | `schemaVersion==15` vs actual 16 | `Expected: <15> / Actual: <16>` |
| 4 | migration_bank: staged v13→v15 preserves rows | S | Same pin after full bootstrap | `Expected: <15> / Actual: <16>` |
| 5 | migration_ledgers: tables/columns exist at v13 file, latest assert | S | Same pin | `Expected: <15> / Actual: <16>` |
| 6 | migration_ledgers: staged v12→v13 preserves rows | S | Same pin | `Expected: <15> / Actual: <16>` |
| 7 | migration_series_mode: mode column exists | S | Same pin | `Expected: <15> / Actual: <16>` |
| 8 | migration_series_mode: staged v11→v12 preserves series | S | Same pin | `Expected: <15> / Actual: <16>` |
| 9 | migration_txn_refs: staged v9→v11 preserves rows | S | Same pin | `Expected: <15> / Actual: <16>` |
| 10 | migration_txn_refs: FY + Dr/Cr exist | S | Same pin | `Expected: <15> / Actual: <16>` |
| 11 | migration_txn_refs: staged v10→v11 preserves rows | S | Same pin | `Expected: <15> / Actual: <16>` |
| 12 | migration_valuation: columns exist at v15 | S | Same pin | `Expected: <15> / Actual: <16>` |
| 13 | migration_valuation: staged v14→v15 backfill | S | Same pin | `Expected: <15> / Actual: <16>` |
| 14 | production_boundary: paths mirror registry chain | S | Hardcodes last asset `m015…`; registry ends `m016…` (pubspec already lists m016) | `Expected m015… / Actual m016…`, `pubspec.yaml:89` |
| 15 | production_boundary: loads every version | S | Same hardcoded `m015` expectation | `does not contain 'm015…'` (chain now ends m016) |
| 16 | books_test: file does not compile | H | Uses `seeder`/`SeedLine`/`PostingResult` with no import and no `seeder` variable; symbols exist only in `test/helpers/seeded_post.dart` (`VoucherSeeder`, `SeedLine`) | analyze errors `books_test.dart:150,156,158`; helper file read verified |
| 17 | ledger_books: openings sign balances; posted lines move them | S | `createJournal` creates status `posted` then `addLine` — forbidden by D1-D4 (draft/held only) | Fail at `ledger_books_test.dart:136` (`expect(l.isOk)` false) |
| 18–25 | settlement_report: all 8 tests | S | `createVoucher(status:'posted')` + `addLine` — same D1-D4 seeding | Fail at `settlement_report_test.dart:145` in every test |
| 26 | voucher_engine: only draft/resumed post | S | `resumed` voucher created directly then `addLine` — D1-D4 keeps resumed non-editable | Fail at `voucher_engine_test.dart:250` via helper `:149` |
| 27 | held_bill: held moves to resumed/cancelled/posted | S | Expects `updateHeldStatus→posted` ok — refused by D1-D2 (posting only via engine) | `Expected: true / Actual: <false>` at `held_bill_test.dart:134` |
| 28 | held_bill: terminal and non-held states reject | S | Same: moves to `posted` first — refused by D1-D2 | Fail at `held_bill_test.dart:147` |
| 29 | voucher_repository: line on missing voucher atomic | S | Expects code `foreign-key`; D1-D4 parent pre-check reports `validation` before any insert (atomicity assertions still hold) | `Expected: 'foreign-key' / Actual: 'validation'` |
| 30 | voucher_repository: failures carry codes | S | Same code change | `Expected: 'foreign-key' / Actual: 'validation'` |
| 31–35 | books_report: day book ×2, trial ×2, ledger account ×1 | S | `post()` creates status `posted` then `addLine` — D1-D4 | Fail at `books_report_test.dart:150` in all five |
| 36–39 | hub_screens: home, billing hub, entries, reports hub ×4 | S | setUp creates status `posted` then `addLine` — D1-D4 | Fail at `hub_screens_test.dart:153` (shared setUp) |
| 40 | outstanding_report: open bills list amounts/states/totals | S | `createBill` creates status `posted` then `addLine` — D1-D4 | Fail at `outstanding_report_test.dart:106` |

Repairs (test files only; zero production-code changes):
- v15 pins → v16 with `// registry ends at v16 (m016, D1-D5)` comment (13 migration asserts);
  `migration_test.dart` also extended: ledger list `[1..16]`, plus new asserts that a
  clean install carries `item_cost_state.company_id` and
  `stock_movement.reverses_movement_id`/`cost_method` (proves m016 applied).
- `production_boundary_test.dart`: last-asset/`kLatestVersion` expects → m016.
- `books_test.dart`: import `seeded_post.dart` + `voucher_engine.dart` (types),
  instantiate `VoucherSeeder` in setUp, removed the unused `vouchers` field
  (clears the warning), and implemented the previously dead `post:false` branch so
  `v-draft` truly stays a draft (old code posted it anyway — would have failed
  `dayBook` expectations once compiling).
- Seeding converted to draft → lines → engine post: `ledger_books_test`
  (via `VoucherSeeder`), `books_report_test` (+ new `p-b` party fixture — the one
  `Sales Invoice` seeding needs a party on a line per the engine party rule),
  `hub_screens_test` (via `scope.engine`), `outstanding_report_test` (new engine
  wiring), `settlement_report_test` (creates draft; `addLine` posts via engine when
  intent was `posted`; each fixture voucher carries exactly one line — noted in code).
- `voucher_engine_test` resumed case now builds via the documented path:
  held → add lines → `updateHeldStatus(resumed)` → engine post (production
  `addLine` untouched; resumed stays non-editable).
- `held_bill_test`: loop narrowed to resumed/cancelled; new test proves
  `posted` is refused with `validation`, status stays `held`, no lineage row added.
  Engine-post path for resumed is proven by `voucher_engine_test` (cited in code).
- `voucher_repository_test`: expected code `foreign-key` → `validation` with
  D1-D4 comment; atomicity/no-lineage assertions unchanged and passing.

### D. D1 work-item inventory (code read + tests run; `present-and-tested` names the test)

| ID | Item | Inventory | Evidence |
|---|---|---|---|
| A1 | Kotlin Keystore channel | present-untested | `MainActivity.kt:40-181` implements the contract; no host test exercises `ChannelKeyProvider` mapping (device proof stays G0-VER-005) |
| A2 | Dart KeyProvider + opener takes key | partial | `key_provider.dart:84-210`, `cipher_opener.dart:63-69/165-180` present; `cipher_opener_test` covers open/bootstrap/wrong-key, not the channel state mapping |
| A3 | Startup sequence + scopeOfBackend + states | partial | `startup.dart:175-261`, `composition_root.dart:218-241`, `niav_app.dart:64-144` present; `shell_test` covers `scopeOfBackend`/`NiavApp` with injected scope only |
| A4 | main() widget test over real startup | absent | No test references `runStartup`/`StartupOutcome`/fake key channel |
| B1 | Close releases handle, idempotent, reopen works | present-and-tested | `cipher_opener_test: 'close then reopen with the same key preserves rows'`; `persistence_reload_test: 'rows written before close are visible after reopen'`; `niav_database.dart:75-83`, `ffi_database.dart:82-87` |
| B2 | PRAGMA-key guard, code-only, redaction test | partial | Guard present (`cipher_opener.dart:185-197`); no throwing-engine redaction test |
| B3 | Safe rollback, never masks original | partial | Present (`ffi_database.dart:57-77`); general atomicity tested (`voucher_posting_test: 'allocation rides the same transaction; failure aborts all'`) but not the already-rolled-back path |
| B4 | backend() closes DB if bootstrap throws | present-untested | Present (`composition_root.dart:82-92`); no throw-path test |
| C1 | UUIDv7 generator | partial | `core/uuid_v7.dart:26-133` present; no generator tests (format/bits/ordering/10k uniqueness) |
| C2 | UUIDv7 production minting | partial | `UuidV7WriteContext` used by `startup.dart:254`; no minting tests; `CounterIdMint` still used by widget-test scopes (correct per D1: tests only) |
| D1 | cancelPosted full reversal | partial | Basic cancel tested (`business_cycles: 'posted rows never rewrite; correction compensates'`, engine reason/terminal test); required scenarios absent: purchase on-hand restoration, compensating-movement + untouched-originals assertions, allocation-reversal audit, locked-period refusal, atomicity-injection |
| D2 | updateHeldStatus refuses posted | present-and-tested | New `held_bill_test: 'posted is refused here; the voucher is left unchanged'` |
| D3 | postDraft delegates to postWithStock path | present-and-tested | `voucher_engine.dart:263-286`; all engine post tests run through it |
| D4 | addLine draft/held only | partial | Guard present (`voucher_repository.dart:320-334`); explicit refused-on-posted/cancelled tests absent |
| D5 | company_id cost scoping | partial | m016 + scoped reads/writes present; dedicated two-company cost-isolation test absent |
| D6 | Real actor on movement audit | present-untested | No `'posting-engine'` literal anywhere (grep); actor threaded (`voucher_engine.dart` movement/audit writes); no dedicated assertion found |
| D7 | Missing godown rejected | present-untested | Guard present (`voucher_engine.dart:870-876` per prior read); no dedicated test found |
| D8 | Fallback/zero first issue locks method | present-untested | Method recorded on zero path (prior read `:1236-1242`); lock tested for priced issues (`stock_valuation_test: 'method locks at first priced issue'`), not for fallback/zero |
| D9 | Empty must-balance journal rejected | partial | `checkJournalBalance` present; DECISIONS.md confirmation + zero-ledger-line test absent — D1 must confirm per DECISIONS.md |

## 3. Changed files (new / modified / deleted, one line each)

Modified (test only — no `lib/`, `android/`, pubspec, HTML, or register edits):
- niaverp/test/migrations/migration_test.dart (v16 pins + m016 column asserts)
- niaverp/test/migrations/migration_bank_test.dart (v16 pins)
- niaverp/test/migrations/migration_ledgers_test.dart (v16 pins)
- niaverp/test/migrations/migration_series_mode_test.dart (v16 pins)
- niaverp/test/migrations/migration_txn_refs_test.dart (v16 pins)
- niaverp/test/migrations/migration_valuation_test.dart (v16 pins)
- niaverp/test/app/production_boundary_test.dart (m016 asset expects)
- niaverp/test/application/books_test.dart (helper import + seeder + post:false branch)
- niaverp/test/application/ledger_books_test.dart (engine-path seeding)
- niaverp/test/application/settlement_report_test.dart (draft + deferred engine post)
- niaverp/test/application/voucher_engine_test.dart (resumed via held path)
- niaverp/test/data/repositories/held_bill_test.dart (refusal test + narrowed loop)
- niaverp/test/data/repositories/voucher_repository_test.dart (validation code)
- niaverp/test/presentation/books_report_test.dart (engine post + party fixture)
- niaverp/test/presentation/hub_screens_test.dart (draft + engine post)
- niaverp/test/presentation/outstanding_report_test.dart (engine wiring + post)
New: docs/implementation/RESULT_D0_baseline_triage.md (this file).
Deleted: none.

## 4. Tests

- Added: 1 test (`held_bill_test: 'posted is refused here; the voucher is left
  unchanged'`); `books_test` `post:false` branch is newly real (was dead code).
- Final: `flutter analyze` → **No issues found** (was 5 issues).
- Final: `flutter test` → **374 passed / 0 failed** (`+374: All tests passed`;
  was 331/40; last green was 373/0 — net +1: the new refusal test).
- Previously-failing scenarios now covered: every one of the 40 runs green —
  migration chain to v16 incl. m016 columns, asset/chain parity, books/ledger/
  settlement reports over engine-posted history, resumed-posting via held queue,
  held-posted refusal with unchanged voucher, missing-parent validation with no
  lineage, all hub/report widgets over posted fixtures.
- No test was deleted or weakened: assertions were updated only where a committed
  rule changed (v16 registry; D1-D2/D4 guards), each with a code comment naming it.

## 5. Commands run and exact output summary

- `git rev-parse HEAD` → `6f2051a…` (pre-triage); `git status --short` → 36
  untracked, 0 modified; `git diff --stat` → empty.
- `git switch -c baseline-triage-20261006; git add -A; git commit -m "WIP before
  D0 triage"` → `e93944a`, tree clean. Not pushed.
- `flutter analyze` before edits: `5 issues found`; after: `No issues found!`.
- `flutter test` before: `+331 -40: Some tests failed`; 16 per-file isolation runs
  (expanded reporter) to classify all 40; after repairs, per-file runs of all 16
  touched files green; full suite: `+374: All tests passed!` (~29s).
- Read-only greps for inventory: `posting-engine` → no matches in repo;
  `UuidV7|runStartup|ChannelKeyProvider|getDatabaseKey` → no test matches;
  `scopeOfBackend` in tests only via `shell_test` (injected scope).
- Environment: same SDK path as RESULT_D1 §1; no alias needed.

## 6. Deviations from the prompt, with reason

- No production-code change was needed: classification found zero
  `real-regression`. Two judgment calls, both keeping production untouched:
  (a) resumed vouchers stay non-editable in `addLine` — the test seeds resumed via
  the documented held path instead (FR-M11-003 documents held→resumed; nothing
  documents adding lines to resumed); (b) missing-parent code is now `validation`
  rather than `foreign-key` — the D1-D4 guard necessarily pre-checks the parent
  before any insert, and atomicity assertions still pass.
- Fixture completion (not weakening): `books_report` Sales Invoice seeding carries
  a real `p-b` party line because the engine party rule requires it; report
  assertions unchanged. `books_test` dead `post:false` param implemented — without
  it the draft test would fail.
- C4 did not occur: nothing classified `unknown`/`environment`; no blocked items.

## 7. Owner questions (exact source ID + question) and downstream evidence still pending

- P-SQLIB (`docs/g0/PENDING_INPUTS.md` §A): "Which exact SQLCipher-class library,
  version, and licence evidence is approved, with Android 8 proof?" — tree carries
  DECISIONS.md approval (sqlite3 3.7.0 + sqlite3mc, 2026-10-05) while PENDING_INPUTS
  still asks; the dated confirmation note belongs to the D1 run (not added here —
  D0 must not edit PENDING_INPUTS.md).
- G0-VER-001/005/008: native cipher licence text, on-device Keystore behaviour,
  Android 8 compatibility — pending; all channel/cipher evidence here is
  host-only and is not claimed as device evidence.
- Missing `phase-00/01/02.md` reports: owner to confirm whether
  `TEST_RUN_20261005.md` alone is the baseline record.
- D9 carries into D1: confirm per DECISIONS.md whether must-balance types with
  zero ledger lines are rejected.

## 8. Honesty statement

- 374 passing tests are host/in-memory runs (sqlite3, fake-free but host-side);
  nothing here is device, printer, legal, statutory, or release evidence.
- The D1 inventory (§2-D) is based on code reads plus targeted test-name greps;
  `present-untested` rows name what the D1 run must still prove. No mock or
  scaffold result is presented as production evidence. No field, rule, package,
  permission, or platform behaviour was invented; no HTML, workbook, or register
  was edited; no test was deleted or weakened.

## 9. Next prompt

- D1 (`delta/D1_repair_and_production_wiring.md`) may run now: baseline is green
  (analyze clean, 374/0). Per §2-D it may treat D2 as done (tested), must still
  deliver A4, B2–B4 tests, C tests, D1 scenarios, D4/D5 tests, D6–D9 proof, and the
  P-SQLIB comment reconciliation + dated PENDING_INPUTS.md note (owner confirms).
