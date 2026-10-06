# RESULT D1 — Repair engine invariants and wire the production backend
Date (UTC): 2026-10-06   Overall status: PASS

## 1. Baseline before changes

- D0 triage report `docs/implementation/RESULT_D0_baseline_triage.md` exists
  with Overall status PASS (verified; its inventory table drove this run).
- `flutter analyze` before editing (same SDK invocation as D0: Flutter 3.47.6 /
  Dart 3.13.5 via `dart.exe flutter_tools.snapshot`): **No issues found**.
- `flutter test` before editing: **374 passed / 0 failed** (`+374`).
- git: branch `baseline-triage-20261006`, HEAD `e93944a` (D0 safety commit) plus
  uncommitted D0 test repairs; no other changes. No-space alias not needed.
- Mandatory reads: `niaverp/AGENTS.md`, `niaverp/DECISIONS.md`,
  `docs/IMPLEMENTATION_EXECUTION_STRATEGY.md`,
  `docs/opencode_master_prompts/GLOBAL_NO_INVENTION_CONTRACT.md`,
  `docs/opencode_master_prompts/SOURCE_CLARIFICATIONS.md`,
  `docs/g0/PENDING_INPUTS.md`, every file in `docs/implementation/`
  (`TEST_RUN_20261005.md`, `RESULT_D1_repair_and_production_wiring.md` (prior
  FAIL, overwritten by this file), `RESULTS_INDEX.md`,
  `RESULT_D0_baseline_triage.md`). Missing phase reports (stated, not
  invented): `phase-00.md`, `phase-01.md`, `phase-02.md`.

## 2. Work-item table

| ID | Item | Status (implemented / boundary / blocked / not-done) | Evidence (file:line, test name) |
|---|---|---|---|
| A1 | Kotlin Keystore channel (files dir + wrapped 32-byte key, contract codes, minSdk 26) | implemented | Re-verified unchanged: `MainActivity.kt:40-181` (states missing/available/locked/failed, AES-GCM wrap, app-private storage, no recovery API, no key logging); minSdk 26 pinned `build.gradle.kts:21`. Device behaviour stays pending under G0-VER-005 (§7) |
| A2 | Dart KeyProvider over channel; opener takes key | implemented | `key_provider.dart:84-210` (+ fix: `available` reply now calls `lifecycle.provision()` so `canOpenDatabase` reflects the proved key); `cipher_opener.dart:63-69`. Tests: `channel_key_provider_test.dart` (6: available/missing/locked/failed/malformed/transport) |
| A3 | Startup sequence, scopeOfBackend, distinct states, no plaintext fallback | implemented | Re-verified: `startup.dart:175-261`, `composition_root.dart:218-241`, `niav_app.dart:64-144`, `main.dart:27-62`. Exercised end-to-end by the A4 tests |
| A4 | main()/startup widget test (fake channel, temp-file engine) | implemented | `test/app/startup_test.dart` (3): ready path shows-tab real data (`find.text('A4 Co')`); key failure shows `Secure key unavailable` + code; missing key creates no file (no plaintext path) |
| B1 | close() releases handle, idempotent, rejects use; opener keeps handle; reopen test | implemented | Re-verified `niav_database.dart:75-83`, `ffi_database.dart:82-87`; `cipher_opener_test: 'close then reopen…'`; new `ffi_database_test` close group (idempotent + reject-use + cascade) |
| B2 | PRAGMA-key guard → code-only error; key-redaction test | implemented | Guard re-verified `cipher_opener.dart:185-197`; new `cipher_opener_test` ×2: wrong-key and junk-file failures assert code-only (`key-application-failed`) with key hex absent from message and `toString()` |
| B3 | Safe rollback, original error never masked; test | implemented | Re-verified `ffi_database.dart:57-77`; new `ffi_database_test` ×2: rollback + original rethrown; already-committed body still surfaces the original |
| B4 | backend() closes DB if bootstrap throws | implemented | Fix: `NiavDatabase implements CloseableMigrationDb` (`niav_database.dart:29-35`) so the close cascades through the backend wrapper to the native handle; `TestDatabase` mirrors it. Test: `production_boundary_test: 'bootstrap failure closes the database'` (poisoned v1016 → throws + `isClosed` + use rejected) |
| C1 | Pure-Dart UUIDv7 (Clock + random, monotonic, canonical) | implemented | Re-verified `core/uuid_v7.dart:26-133`; new `test/core/uuid_v7_test.dart` (6) |
| C2 | UUIDv7 production minting; CounterIdMint tests-only; format/bits/order/10k tests | implemented | `UuidV7WriteContext` already wired by `startup.dart:254`; widget tests keep `CounterIdMint`; 10,000-value uniqueness + ordering test included |
| D1 | cancelPosted same-tx reversal (lock, compensating movements + layers, allocation reversal; m016) | implemented | Reversal rule grounded in M04 common states + DSS-C-003 + D-M5 (see m016 header `m016_company_scope_and_reversal.sql:1-31`); m016 already additive/repeat-safe (D0). New `voucher_cancel_test.dart` ×3: purchase restore + compensating row + untouched originals + reversed allocation + audits; locked-period refusal with nothing changed; injected op-conflict proves full rollback |
| D2 | updateHeldStatus cannot set posted | implemented | Re-verified (D0 test): `held_bill_test: 'posted is refused here; the voucher is left unchanged'` |
| D3 | postDraft delegates to postWithStock single-tx path | implemented | Re-verified `voucher_engine.dart:263-286`; all engine post tests run through it |
| D4 | addLine rejects unless draft/held; posted/cancelled tests | implemented | Re-verified guard `voucher_repository.dart:320-334`; new test `'lines are refused on posted and cancelled vouchers'` (code `validation`, lines stay empty) |
| D5 | item_cost_state.company_id + scoped layer UPDATEs; two-company test | implemented | m016 + scoped reads/writes re-verified (`voucher_engine.dart:562-573,1278-1286,1345-1351` carry `company_id`); grep found no other unscoped `stock_cost_layer`/`item_cost_state` statement. New test: same item code in c-x/c-y — c-y issue prices zero (never c-x's cost), c-x book untouched |
| D6 | Real actor on movement audit | implemented | No `'posting-engine'` literal in repo (grep); cancel test asserts the compensating-movement audit actor is `'tester'` |
| D7 | Item lines without godownId rejected | implemented | Re-verified guard (`voucher_engine.dart` godown check); new `voucher_posting_test: 'item lines without a godown are rejected, never ignored'` (code `validation`, message names godown, draft intact, no movements) |
| D8 | Fallback/zero first issue locks method | implemented | No block needed: implementation records the resolved method on the zero path and the new test proves it — zero-priced fifo first issue binds `fifo`; switching the master to `wa` is refused (`locked to fifo`) |
| D9 | Empty must-balance journal: reject or document why | implemented | Confirmed per DECISIONS.md: no non-empty rule exists for these types; M06 vouchers capture header amounts (engine profile `requiresLines:false`, `checkJournalBalance` constrains only Dr/Cr-marked lines). Code left as-is; new test `'journal with no ledger lines still posts'` documents the allowed behaviour with the rationale |

## 3. Changed files (new / modified / deleted, one line each)

Production (`lib/`, 2 behaviour changes + comment reconciliation):
- MOD niaverp/lib/data/db/niav_database.dart (`CloseableMigrationDb` cascade, D1-B4)
- MOD niaverp/lib/data/db/key_provider.dart (`provision()` on available reply, D1-A2)
- MOD niaverp/lib/app/composition_root.dart, app/migration_assets.dart,
  presentation/shell/niav_shell.dart, presentation/shared/company_scope.dart,
  presentation/reports/books_report_screen.dart,
  presentation/reports/outstanding_report_screen.dart,
  presentation/reports/stock_report_screen.dart,
  data/security/key_lifecycle.dart (P-SQLIB comments reconciled to owner-approved
  2026-10-05; device proof still pending)
Tests (new / modified):
- NEW niaverp/test/core/uuid_v7_test.dart (C, 6 tests)
- NEW niaverp/test/data/db/ffi_database_test.dart (B1/B3, 4 tests)
- NEW niaverp/test/data/db/channel_key_provider_test.dart (A2, 6 tests)
- NEW niaverp/test/app/startup_test.dart (A4, 3 tests)
- NEW niaverp/test/application/voucher_cancel_test.dart (D1/D5/D6/D8, 5 tests)
- MOD niaverp/test/helpers/test_database.dart (`CloseableMigrationDb` + P-SQLIB comment)
- MOD niaverp/test/data/db/cipher_opener_test.dart (B2, +2 tests)
- MOD niaverp/test/app/production_boundary_test.dart (B4, +1 test)
- MOD niaverp/test/data/repositories/voucher_repository_test.dart (D4, +1 test)
- MOD niaverp/test/application/voucher_posting_test.dart (D7, +1 test)
- MOD niaverp/test/application/voucher_engine_test.dart (D9, +1 test)
Docs:
- MOD docs/g0/PENDING_INPUTS.md (new §F dated P-SQLIB note only; no row touched)
- MOD docs/implementation/RESULT_D1_repair_and_production_wiring.md (this file, overwrite of prior FAIL)
Deleted: none (a temporary hang-probe test was created during debugging and removed before finishing).

## 4. Tests

- Added: 30 tests — uuid_v7 6, ffi_database 4, channel_key_provider 6,
  cipher_opener +2, production_boundary +1, voucher_cancel 5,
  voucher_repository +1, voucher_posting +1, voucher_engine +1, startup 3.
- Final: `flutter analyze` → **No issues found** (was clean at baseline, still clean).
- Final: `flutter test` → **404 passed / 0 failed** (baseline 374/0; +30 new, 0 broken).
- Required D1 scenarios all covered: purchase-cancel restore + compensating row +
  untouched originals + reversed allocation + audits (`voucher_cancel_test`);
  locked-period refusal; atomicity via injected op-conflict; held-posted refusal;
  addLine posted/cancelled refusal; postDraft same-path (existing engine tests);
  two-company isolation; startup ready/key-failure/no-fallback; key redaction ×2;
  reopen-after-close; UUIDv7 format/bits/ordering/10k.
- Every pre-existing test still passes (404 includes all 374 baseline tests).

## 5. Commands run and exact output summary

- `flutter analyze` before edits: `No issues found!`; after all edits: `No issues found!`.
- `flutter test` before edits: `+374: All tests passed!`; after: `+404: All tests passed!` (~33s).
- New/changed suites run individually during development (uuid, ffi, channel,
  cipher, boundary, cancel, repo, posting, engine) — all green; two genuine
  findings fixed (see §6).
- `startup_test.dart` initially hung the runner (>110s, twice): root cause is
  widget-test FakeAsync vs real file/sqlite IO — fixed with
  `tester.runAsync(...)` around `runStartup`; a stale `flutter_tester` from the
  hung run was killed before re-running (per TEST_RUN_20261005 procedure note).
- Greps: `posting-engine` → no matches; `stock_cost_layer`/`item_cost_state`
  statements all carry `company_id`; `UuidV7|runStartup|ChannelKeyProvider` now
  covered by tests; minSdk 26 confirmed in `build.gradle.kts:21`.
- Environment: same SDK invocation as D0; no alias needed.

## 6. Deviations from the prompt, with reason

- Two behaviour fixes beyond pure test-adding (both minimal, both covered):
  (a) `ChannelKeyProvider` available-reply now calls `lifecycle.provision()` —
  without it `canOpenDatabase` stayed false after a proved key (found by the new
  A2 test); app flow unchanged (`runStartup` consumes the bytes directly).
  (b) `NiavDatabase implements CloseableMigrationDb` — without it B4's close on
  bootstrap failure stopped at the backend wrapper and never reached the native
  handle through the double-wrapped production path.
- Test-expectation correction (not weakening): wrong-key open fails with
  `key-application-failed` (cipher-proof read inside the guarded key step), not
  `bootstrap-failed`; the test pins the actual code-only behaviour.
- Widget-test mechanics: `runStartup` runs inside `tester.runAsync` (FakeAsync
  cannot do real file/sqlite IO); this is test-harness mechanics, not product
  behaviour.
- Fresh-provider `locked` platform reply maps to `key-missing` in startup
  (`KeyLifecycle.lock()` only transitions `available → locked`): left untouched
  per the no-rewrite rule — both are non-technical key-failure states with codes,
  no recovery/plaintext impact. Device flow can revisit with G0-VER-005.
- D9: code deliberately unchanged (documents allow empty — see §2); D8: no
  `blocked` row (implementation locks; test proves it). No other item needed
  invention or blocking.
- Line-level file surgery on `startup_test.dart` fell back to PowerShell
  (the edit tool repeatedly failed to match that one file); content verified via
  analyze + tests.

## 7. Owner questions (exact source ID + question) and downstream evidence still pending

- P-SQLIB (`docs/g0/PENDING_INPUTS.md` §A, still PENDING-INPUT): "Which exact
  SQLCipher-class library, version, and licence evidence is approved, with
  Android 8 proof?" — dated §F note added (approval recorded in pubspec,
  2026-10-05); owner must confirm to close the row. Remaining evidence:
  native cipher licence text from the bundled asset manifest + Android 8 proof.
- G0-VER-005 (and G0-VER-001/008): real-device Keystore, cipher, Android 8,
  backup/share behaviour — pending. All channel/cipher/startup tests here are
  host or fake-channel runs and are recorded as such, never as device evidence.
- Missing `phase-00/01/02.md` reports: owner to confirm whether
  `TEST_RUN_20261005.md` alone is the baseline record (repeated from D0).
- No new `blocked` items from this run.

## 8. Honesty statement

- 404 passing tests are host/in-memory runs (sqlite3 incl. the sqlite3mc build,
  temp files, fake platform channel); nothing here is Android-device, printer,
  legal, statutory, or release evidence.
- A1's Kotlin side was re-verified by reading only; no on-device run exists.
- No mock, host-only, or scaffold result is presented as production evidence. No
  field, rule, package, permission, or platform behaviour was invented; no HTML,
  workbook, or register was edited; no test was deleted or weakened (assertions
  changed only for the two documented behaviours above, with reasons in §6).

## 9. Next prompt

- D2 (`delta/D2_schema_and_security_hardening.md`) may run now: baseline is
  green (analyze clean, 404/0). It inherits the D1 inventory (§2) and the
  pending device/owner evidence (§7).
