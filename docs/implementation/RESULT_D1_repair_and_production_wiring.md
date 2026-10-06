# RESULT D1 — Repair engine invariants and wire the production backend
Date (UTC): 2026-10-06   Overall status: FAIL
Re-verified same date on prompt re-issue: baseline identical (HEAD 6f2051a,
analyze 5 issues, test +331 -40). No source, test, or doc edits made in either run.

## 1. Baseline before changes

- `flutter analyze` (from `E:\NiavERP v2 OpenAI\niaverp`, via
  `C:\Users\USER\.openclaw-autoclaw\agents\auto-designer\workspace\.cluster\tools\flutter\bin\cache\dart-sdk\bin\dart.exe
  ..\bin\cache\flutter_tools.snapshot analyze` because `flutter.bat` is absent
  from this SDK copy): **5 issues found — 1 warning + 4 errors, NOT clean.**
  All 5 are in `test/application/books_test.dart`:
  - `warning test/application/books_test.dart:31:26 unused_local_variable 'vouchers'`
  - `error test/application/books_test.dart:150:18 'PostingResult' isn't a type`
  - `error test/application/books_test.dart:150:37 Undefined name 'seeder'`
  - `error test/application/books_test.dart:156:15 'SeedLine' isn't a type`
  - `error test/application/books_test.dart:158:11 Method not found: 'SeedLine'`
- `flutter test` (same invocation, `--reporter expanded` for the failure list):
  **331 passed / 40 failed** (`+331 -40`; prompt expected ~360 passed with 0 failed).
  Failing tests (40, unique `[E]` lines):
  - `test/app/production_boundary_test.dart`: migration assets paths mirror the
    registry chain; loads every version / empty text throws (2)
  - `test/application/books_test.dart`: file fails to compile (see analyze errors) (1)
  - `test/application/ledger_books_test.dart`: openings sign balances; posted lines (1)
  - `test/application/settlement_report_test.dart`: 8 tests (outstanding bills x2,
    party outstanding + aging x2, advances, settlement history, line balances x2)
  - `test/application/voucher_engine_test.dart`: only draft/resumed post (1)
  - `test/data/repositories/held_bill_test.dart`: held moves incl. posted; terminal
    states reject (2)
  - `test/data/repositories/voucher_repository_test.dart`: line on missing voucher
    atomicity; failure codes (2)
  - `test/migrations/migration_bank_test.dart` (2), `migration_ledgers_test.dart` (2),
    `migration_series_mode_test.dart` (2), `migration_test.dart` registry 1..15 +
    clean install to v15 (2), `migration_txn_refs_test.dart` (3),
    `migration_valuation_test.dart` (2)
  - `test/presentation/books_report_test.dart` (5), `hub_screens_test.dart` (4),
    `outstanding_report_test.dart` (1)
  - Representative causes sampled: `migration_test.dart` registry expects
    `[1..15]`, actual `[1..16]` (tree already contains `m016`, tests not updated);
    `held_bill_test.dart` expects `updateHeldStatus` to reach `posted`, tree
    implementation refuses it (D1-D2 direction) so the old test fails; `books_test.dart`
    references `seeder`/`SeedLine`/`PostingResult` with no import/definition.
  - Interpretation: the working tree already contains partial D1-shaped
    implementation (m016, engine cancel/reversal, `updateHeldStatus` refusal,
    startup/key-provider/cipher/uuid files) whose tests were not updated, plus at
    least one broken test helper import. Baseline is red for pre-existing reasons.
- Per the D1 stop rule ("If they do not pass, stop and write the results file with
  Overall status FAIL"), **no code was edited and no work item was executed.**
- git HEAD: `6f2051a` (short). Working tree has pre-existing untracked files only;
  no tracked-file modifications were made by this run.
- Environment: Windows, Flutter SDK 3.47.6 / Dart 3.13.5 copy at
  `C:\Users\USER\.openclaw-autoclaw\agents\auto-designer\workspace\.cluster\tools\flutter`
  (no `flutter.bat`; invoked via `dart.exe flutter_tools.snapshot`). No-space
  alias workaround was not needed.
- Mandatory reads done: `niaverp/AGENTS.md`, `niaverp/DECISIONS.md`,
  `docs/IMPLEMENTATION_EXECUTION_STRATEGY.md`,
  `docs/opencode_master_prompts/GLOBAL_NO_INVENTION_CONTRACT.md`,
  `docs/opencode_master_prompts/SOURCE_CLARIFICATIONS.md`,
  `docs/g0/PENDING_INPUTS.md` (2026-10-03; P-SQLIB row still phrases the library
  question as pending — not edited), `docs/opencode_master_prompts/Delta/README.md`
  (results template source), `docs/opencode_master_prompts/delta/D1_repair_and_production_wiring.md`
  (prompt text present, not executed beyond the baseline gate).
- `docs/implementation/` contents: only `TEST_RUN_20261005.md` exists.
  **Missing phase reports (stated, not invented):** `phase-00.md`, `phase-01.md`,
  `phase-02.md` referenced by `AGENTS.md` continuation rule are absent, as are all
  prior `RESULT_D*.md` files and `RESULTS_INDEX.md` (created here with the single
  D1 line only).

## 2. Work-item table

| ID | Item | Status (implemented / boundary / blocked / not-done) | Evidence (file:line, test name) |
|---|---|---|---|
| A1 | Kotlin MethodChannel Keystore wrapper (MainActivity.kt) | not-done | Baseline red, stopped per stop rule. Observed only: `niaverp/android/app/src/main/kotlin/com/niaverp/niaverp/MainActivity.kt:1-181` already contains a Keystore AES-GCM channel implementation — unverified, not executed, not claimed. |
| A2 | Dart KeyProvider over channel; CipherDatabaseOpener takes provider/key | not-done | Baseline red, stopped. Observed only: `niaverp/lib/data/db/key_provider.dart:84-210`, `niaverp/lib/data/db/cipher_opener.dart:50-198` exist — unverified. |
| A3 | Startup sequence in lib/app; scopeOfBackend converter; distinct failure states; no plaintext fallback | not-done | Baseline red, stopped. Observed only: `niaverp/lib/app/startup.dart:175-261`, `niaverp/lib/app/composition_root.dart:218-241`, `niaverp/lib/app/niav_app.dart:64-144`, `niaverp/lib/main.dart:27-62` exist — unverified. |
| A4 | main() widget test with fake channel + in-memory/temp engine | not-done | Baseline red, stopped. Not verified; existing `test/app/production_boundary_test.dart` FAILS (2 tests). |
| B1 | NiavDatabase.close releases handle, idempotent, rejects use; reopen-after-close test | not-done | Baseline red, stopped. Observed only: `niaverp/lib/data/db/niav_database.dart:75-83`, `niaverp/lib/data/db/ffi_database.dart:82-87` — unverified. |
| B2 | PRAGMA-key guard rethrows code-only error; key-redaction test | not-done | Baseline red, stopped. Observed only: `niaverp/lib/data/db/cipher_opener.dart:185-197` — unverified. |
| B3 | runInTransaction rollback safe + never masks original error; test | not-done | Baseline red, stopped. Observed only: `niaverp/lib/data/db/ffi_database.dart:57-77` — unverified. |
| B4 | CompositionRoot.backend closes DB if bootstrap throws | not-done | Baseline red, stopped. Observed only: `niaverp/lib/app/composition_root.dart:82-92` — unverified. |
| C1 | Pure-Dart UUIDv7 generator (Clock + random, monotonic, canonical) | not-done | Baseline red, stopped. Observed only: `niaverp/lib/core/uuid_v7.dart:26-133` exists — unverified. |
| C2 | UUIDv7 for production WriteContext/ID minting; keep CounterIdMint for tests; 10k tests | not-done | Baseline red, stopped. Observed only: `niaverp/lib/presentation/shared/screen_wiring.dart:31-60` — unverified. |
| D1 | cancelPosted same-tx reversal (period lock, compensating movements, layer compensation, allocation reversal); m016 if needed | not-done | Baseline red, stopped. Observed only: `niaverp/lib/application/services/voucher_engine.dart:393-493`, `niaverp/lib/data/migrations/m016_company_scope_and_reversal.sql:1-51` — unverified. No block recorded (documents not consulted — run stopped first). |
| D2 | updateHeldStatus cannot set posted; test | not-done | Baseline red, stopped. Tree refuses `posted` (`niaverp/lib/data/repositories/voucher_repository.dart:502-507`) but old `held_bill_test.dart` expects it — FAILS. Not resolved (no edits allowed after FAIL). |
| D3 | postDraft removed or delegates to postWithStock single-tx path | not-done | Baseline red, stopped. Observed only: `niaverp/lib/application/services/voucher_engine.dart:263-286` delegates — unverified. |
| D4 | addLine rejects unless draft (or documented editable state); tests | not-done | Baseline red, stopped. Observed only: `niaverp/lib/data/repositories/voucher_repository.dart:320-334` — unverified. |
| D5 | company_id on item_cost_state + scoped layer UPDATE + two-company test | not-done | Baseline red, stopped. Observed only: m016 SQL + `voucher_engine.dart:562-573,1278-1286,1345-1351` carry `company_id` — unverified; migration tests FAIL on v15 expectations. |
| D6 | Stock movement audit actor is real actor, not literal 'posting-engine' | not-done | Baseline red, stopped. Not checked (grep not run — read-only verification deferred to a green-baseline run). |
| D7 | Item lines without godownId rejected on stock-tracked types; tests | not-done | Baseline red, stopped. Observed only: `voucher_engine.dart:870-876` throws validation — unverified. |
| D8 | First issue via fallback/zero cost still locks method, else blocked+question | not-done | Baseline red, stopped. Observed only: `voucher_engine.dart:1236-1242` records method on zero path — unverified; no block recorded (run stopped first). |
| D9 | checkJournalBalance: zero-ledger-line must-balance types rejected; confirm per DECISIONS.md | not-done | Baseline red, stopped. Observed only: `voucher_engine.dart:351-366` returns null when no Dr/Cr lines — unverified against DECISIONS.md. |

## 3. Changed files (new / modified / deleted, one line each)

- NEW `docs/implementation/RESULT_D1_repair_and_production_wiring.md` (this file).
- NEW `docs/implementation/RESULTS_INDEX.md` (single D1 FAIL line; file did not exist).
- Modified: none. Deleted: none. No source, test, migration, pubspec, Android,
  iOS/macOS/Linux/Windows/web, HTML, or PENDING_INPUTS.md edits were made.

## 4. Tests

- Added: 0 (run stopped at the baseline gate).
- Baseline `flutter analyze`: 5 issues (1 warning + 4 errors, all in
  `test/application/books_test.dart`; see §1). Expected: no issues. Verdict: FAIL.
- Baseline `flutter test`: 331 passed / 40 failed (`+331 -40` on the expanded
  reporter; prompt expected ~360 passed, 0 failed). Verdict: FAIL.
- Required D1 test scenarios (cancel purchase, locked-period cancel, cancel
  atomicity, held-status/addLine/postDraft guards, two-company isolation, startup,
  key-redaction, reopen-after-close, UUIDv7): not executed — blocked by the red baseline.
- Every pre-existing test still passes: NO — 40 fail before any change (see §1 list).

## 5. Commands run and exact output summary

- `dart <sdk>\bin\cache\flutter_tools.snapshot analyze` (Flutter 3.47.6/Dart 3.13.5,
  `E:\NiavERP v2 OpenAI\niaverp`): `5 issues found (ran in 2.9s)` — 1 warning +
  4 errors in `test/application/books_test.dart` (listed in §1).
- `dart <sdk>\bin\cache\flutter_tools.snapshot test` (default reporter):
  `+331 -40: Some tests failed.` Failing-tests footer names 4 entries + `... and 36 more`.
- Same with `--reporter expanded` + filter `: .* \[E\]`: full 40-entry failure list
  captured in §1.
- Focused re-runs for cause sampling: `migration_test.dart` registry test shows
  `Expected: [1..15] / Actual: [1..16]`; `held_bill_test.dart` posted-move shows
  `Expected: true / Actual: <false>`; `books_test.dart` fails compilation on
  `PostingResult`/`SeedLine`/`seeder`.
- `git rev-parse --short HEAD` → `6f2051a`. `Test-Path RESULTS_INDEX.md` → False
  (before); delta prompt files present under `docs/opencode_master_prompts/delta/`.
- Re-verification on prompt re-issue (same date): `analyze` → same 5 issues
  (`ran in 1.3s`); `test --reporter expanded` → 40 `[E]` lines;
  `test` (default reporter) → `00:33 +331 -40: Some tests failed.` Baseline
  identical; no edits made between runs.

## 6. Deviations from the prompt, with reason

- No work items A1–D9 were implemented, fixed, or verified: the prompt orders
  `flutter analyze` + `flutter test` BEFORE editing and mandates STOP + FAIL-status
  results when they do not pass. Both are red, so all implementation, test-writing,
  comment-reconciliation, and PENDING_INPUTS.md note work was deliberately left undone.
- Section 2 still lists one row per work item A1–D9 as required, with honest
  `not-done` status and pointer-only (unverified) observations so a follow-up run can
  resume; nothing in §2 is claimed as done.
- The P-SQLIB pending-vs-approved reconciliation (comments + dated PENDING_INPUTS.md
  note) was not performed: editing anything beyond the results files after a FAIL
  baseline would violate the stop rule.
- No new pub.dev package, no HTML edits, no platform-folder touches (other than the
  pre-existing tree state, untouched by this run).

## 7. Owner questions (exact source ID + question) and downstream evidence still pending

- Baseline repair ownership: which change set is authoritative for the tree — the
  partial D1-shaped implementation already present (m016/registry v16, engine
  cancel/reversal, `posted` refusal, startup/key/cipher/uuid files) with its 40
  stale/broken tests, or a revert to the last green baseline (per
  `docs/implementation/TEST_RUN_20261005.md`: 373 passed / analyze clean on
  2026-10-05)? No repair attempted; next run needs this direction before touching code.
- P-SQLIB (per `docs/g0/PENDING_INPUTS.md` §A): "Which exact SQLCipher-class library,
  version, and licence evidence is approved, with Android 8 proof?" — tree carries
  `DECISIONS.md` P-SQLIB owner-approval 2026-10-05 (sqlite3 3.7.0 + sqlite3mc) while
  PENDING_INPUTS.md still asks the question; the dated confirmation note was NOT added
  (stopped). Owner must confirm.
- G0-VER-005 (per `docs/opencode_master_prompts/SOURCE_CLARIFICATIONS.md`): device
  Keystore/Android-8 behaviour — host/fake-channel tests are not device evidence.
  Record as pending; nothing here is device evidence.
- G0-VER-001: native cipher licence text + Android 8 compatibility proof — pending.
- Phase-report gap: `phase-00.md` / `phase-01.md` / `phase-02.md` are missing from
  `docs/implementation/` (AGENTS.md calls them authoritative). Owner to confirm whether
  `TEST_RUN_20261005.md` alone is the baseline record or the phase reports must be restored.
- D1/D8/D9 document questions (reversal rule source, method-lock edge, empty-journal
  rule) were not evaluated — the run stopped before document consultation, so no new
  `blocked` rows are recorded; they remain for the resumed run.

## 8. Honesty statement

- This is a FAIL baseline report: nothing was implemented, fixed, or verified in this
  run, and no PASS is claimed for any work item, test, device, legal, statutory, or
  release evidence.
- File:line pointers in §2 describe pre-existing tree content observed through reads
  only; they are not implementation evidence and were not executed, tested, or endorsed.
- The 331 passing tests are host/in-memory runs only; they are not Android-device,
  Keystore, cipher, printer, legal, or delivery evidence (G0-VER-001/005/008,
  G0-VER-003/004/006/007 remain downstream).
- No mock, host-only, or scaffold result is presented as production evidence. No field,
  rule, package, permission, or platform behaviour was invented; no HTML, workbook, or
  register was edited.

## 9. Next prompt

- Do NOT run D2 (delta README: never run the next prompt after FAIL).
- Next step is a baseline-repair run: resolve the owner direction in §7, bring
  `flutter analyze` to zero issues and `flutter test` to fully green (updating the
  40 stale/broken tests only where a documented rule changed, with reasons), then
  re-execute D1 from its mandatory first actions.
