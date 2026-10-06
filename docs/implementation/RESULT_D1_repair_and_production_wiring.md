# RESULT D1 — Repair engine invariants and wire the production backend (re-verification run)
Date (UTC): 2026-10-06   Overall status: PASS

## 1. Baseline before changes

- D0 triage report `docs/implementation/RESULT_D0_baseline_triage.md` exists
  with Overall status PASS (re-run incl. prompt coverage audit 00–13) — D1 gate open.
- `flutter analyze` before editing (Flutter 3.47.6 / Dart 3.13.5 via
  `dart.exe flutter_tools.snapshot`): **No issues found**.
- `flutter test` before editing: **404 passed / 0 failed** (`+404`).
- git: branch `baseline-triage-20261006-d0r2`, HEAD `e67af1c`; working tree held
  only the D0 re-run's two doc edits. The D1 implementation + 30 tests from the
  prior D1 run are committed and untouched. No-space alias not needed.
- Mandatory reads: `niaverp/AGENTS.md`, `niaverp/DECISIONS.md`,
  `docs/IMPLEMENTATION_EXECUTION_STRATEGY.md`,
  `docs/opencode_master_prompts/GLOBAL_NO_INVENTION_CONTRACT.md`,
  `docs/opencode_master_prompts/SOURCE_CLARIFICATIONS.md`,
  `docs/g0/PENDING_INPUTS.md` (2026-10-03 + D1 §F note), every file in
  `docs/implementation/` (`TEST_RUN_20261005.md`, prior RESULT_D1 (PASS),
  `RESULTS_INDEX.md`, `RESULT_D0_baseline_triage.md`). Missing phase reports
  (stated, not invented): `phase-00.md`, `phase-01.md`, `phase-02.md`.
- Per the D0 inventory (post-D1 state), every item below is `present-and-tested`
  except A1 (`present-untested`, Kotlin/on-device). This run therefore
  re-verifies and records evidence; no working code was rewritten.

## 2. Work-item table

| ID | Item | Status (implemented / boundary / blocked / not-done) | Evidence (file:line, test name) |
|---|---|---|---|
| A1 | Kotlin Keystore channel (files dir + wrapped 32-byte key, contract codes, minSdk 26) | implemented | Re-verified unchanged on disk: `MainActivity.kt:40-181` (missing/available/locked/failed, AES-GCM wrap, app-private storage, no recovery API, codes only); minSdk 26 (`build.gradle.kts:21`). No host test can execute Kotlin — device behaviour stays pending under G0-VER-005 (§7) |
| A2 | Dart KeyProvider over channel; opener takes key | implemented | Re-verified green: `channel_key_provider_test.dart` (6 mapping tests incl. `provision()` on available); `key_provider.dart`, `cipher_opener.dart` unchanged since passing D1 run |
| A3 | Startup sequence, scopeOfBackend, distinct states, no plaintext fallback | implemented | Re-verified green via `startup_test.dart`; `startup.dart`, `composition_root.dart` (`scopeOfBackend`), `niav_app.dart` states, `main.dart` unchanged |
| A4 | main()/startup widget test over real sequence | implemented | Re-verified green: `test/app/startup_test.dart` — ready path shows `A4 Co` tab data; key failure shows `Secure key unavailable` + code; missing key creates no file |
| B1 | close() releases handle, idempotent, reopen works | implemented | Re-verified green: `cipher_opener_test` reopen; `ffi_database_test` close group; `CloseableMigrationDb` cascade in `niav_database.dart` |
| B2 | PRAGMA-key guard → code-only; redaction test | implemented | Re-verified green: guard `cipher_opener.dart:185-197`; wrong-key + junk-file tests assert `key-application-failed` with hex absent |
| B3 | Safe rollback, original never masked | implemented | Re-verified green: `ffi_database.dart:57-77`; rollback + already-ended tests |
| B4 | backend() closes DB if bootstrap throws | implemented | Re-verified green: `production_boundary_test` bootstrap-failure test |
| C1 | Pure-Dart UUIDv7 generator | implemented | Re-verified green: `test/core/uuid_v7_test.dart` (6: format, version/variant bits text + bytes, ordering, 10k uniqueness) |
| C2 | UUIDv7 production minting; CounterIdMint tests-only | implemented | Re-verified: `UuidV7WriteContext` via startup; scopes in widget tests use `CounterIdMint` |
| D1 | cancelPosted same-tx reversal (lock, compensating movements + layers, allocation reversal) | implemented | Re-verified green: `voucher_cancel_test.dart` — purchase restore + untouched originals + reversed allocation + audits; locked-period refusal; op-conflict atomicity rollback |
| D2 | updateHeldStatus refuses posted | implemented | Re-verified green: `held_bill_test` refusal test (unchanged voucher, no lineage) |
| D3 | postDraft delegates to postWithStock path | implemented | Re-verified: `voucher_engine.dart:263-286`; all engine post tests run through it |
| D4 | addLine draft/held only | implemented | Re-verified green: posted/cancelled refusal test (`validation`, lines stay empty) |
| D5 | item_cost_state.company_id + scoped UPDATEs | implemented | Re-verified green: two-company same-code test (c-y prices zero, c-x book untouched); m016 + scoped statements unchanged |
| D6 | Real actor on movement audit | implemented | Re-verified green: compensating-movement audit actor `'tester'`; no `'posting-engine'` literal in repo |
| D7 | Missing godown rejected | implemented | Re-verified green: `voucher_posting_test` godown rejection test |
| D8 | Fallback/zero first issue locks method | implemented | Re-verified green: zero-lock test (`locked to fifo`); no block needed |
| D9 | Empty must-balance journal | implemented | Re-verified: documents allow empty (no DECISIONS.md non-empty rule; M06 header-amount profile); code unchanged; documenting test green |

## 3. Changed files (new / modified / deleted, one line each)

- This run: no source, test, migration, pubspec, Android, HTML, or register
  edits. The D1 implementation + 30 tests were delivered and verified in the
  prior D1 run on this same tree; this run re-verified them green.
- MOD docs/implementation/RESULT_D1_repair_and_production_wiring.md (this file).
- Deleted: none.

## 4. Tests

- Added: 0 (all 30 D1 tests already exist and pass).
- `flutter analyze` → No issues found. `flutter test` → 404/0 — every
  pre-existing test passes, including all D1-required scenarios (cancel
  restore/locked/atomicity, held-posted + addLine refusals, two-company
  isolation, startup ready/key-failure/no-fallback, key redaction ×2,
  reopen-after-close, UUIDv7 format/bits/ordering/10k).
- No test added, deleted, or weakened in this run.

## 5. Commands run and exact output summary

- `git rev-parse --short HEAD` → `e67af1c`; branch
  `baseline-triage-20261006-d0r2`; pre-run `git status --short` → 2 doc files.
- `flutter analyze` → `No issues found!`. `flutter test --reporter expanded` →
  `+404: All tests passed!` (~31s).
- Read-only confirmation: `MainActivity.kt` contract + `minSdk = 26`
  unchanged; `posting-engine` still absent from the repo.
- Environment: same SDK invocation as D0/D1; no alias needed.

## 6. Deviations from the prompt, with reason

- None beyond the standing D1 record: this is a re-verification run, so per
  the prompt's own inventory rule no working code was rewritten and no new
  tests were needed. The two D1 behaviour fixes (`provision()` on available
  reply; `CloseableMigrationDb` cascade) and all supporting reasons remain
  documented in the prior D1 report version (git history).
- No item invented, blocked, or left not-done; D8/D9 needed no `blocked` rows.

## 7. Owner questions (exact source ID + question) and downstream evidence still pending

- P-SQLIB (`docs/g0/PENDING_INPUTS.md` §A, still PENDING-INPUT): "Which exact
  SQLCipher-class library, version, and licence evidence is approved, with
  Android 8 proof?" — D1 §F note present; owner must confirm to close.
  Remaining: native cipher licence text + Android 8 proof (G0-VER-001).
- G0-VER-005 (and G0-VER-001/008, 003/004/006/007): device Keystore/cipher,
  statutory, printer, legal, delivery evidence — pending. Host and
  fake-channel runs here are not device evidence.
- Missing `phase-00/01/02.md` reports: owner to confirm whether
  `TEST_RUN_20261005.md` alone is the baseline record (repeated).
- No new `blocked` items from this run.

## 8. Honesty statement

- 404 passing tests are host/in-memory runs (sqlite3 incl. sqlite3mc build,
  temp files, fake platform channel); nothing here is Android-device, printer,
  legal, statutory, or release evidence. A1's Kotlin side is re-verified by
  reading only.
- No mock, host-only, or scaffold result is presented as production evidence.
  No field, rule, package, permission, or platform behaviour was invented; no
  HTML, workbook, or register was edited; no test was added, deleted, or
  weakened in this run.

## 9. Next prompt

- D2 (`delta/D2_schema_and_security_hardening.md`) is next per the Delta order.
  After D2–D4, master prompts 07–11 (missing parts) then 12, 13 (per the D0
  coverage audit).
