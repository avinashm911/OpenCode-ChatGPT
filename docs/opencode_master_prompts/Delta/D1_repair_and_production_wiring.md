# D1 — Repair engine invariants and wire the production backend

## Mandatory first actions
1. Read `niaverp/AGENTS.md`, `niaverp/DECISIONS.md`, `docs/IMPLEMENTATION_EXECUTION_STRATEGY.md`,
   `docs/opencode_master_prompts/GLOBAL_NO_INVENTION_CONTRACT.md`, `docs/opencode_master_prompts/SOURCE_CLARIFICATIONS.md`,
   `docs/g0/PENDING_INPUTS.md`, and every file in `docs/implementation/` that exists. If a phase report is missing, say so in the
   results file; never invent one.
2. Run `flutter analyze` and `flutter test` BEFORE editing and record the totals (expected about 360 passed). If they do not pass,
   stop and write the results file with Overall status FAIL.
3. Do not edit the 15 HTML documents. Add no new pub.dev package. Do not touch iOS/macOS/Linux/Windows/web folders.
4. Never invent a field, rule, package, permission or platform behaviour. If a required rule is not in the source documents, stop
   only that item, mark it `blocked` with the exact source ID and question, and continue with independent items.

## Context
A review found the backend is well tested but the shipped app does not open a database: `lib/main.dart` runs
`NiavApp(root: CompositionRoot.system())` with no company scope, so every tab shows "Company data is unavailable until the encrypted
database is ready". `CipherDatabaseOpener`, `CompositionRoot.backend` and `loadMigrationSqlAssets` are only called from tests. P-SQLIB is
recorded as owner-approved 2026-10-05 in `pubspec.yaml` (sqlite3 build hook source `sqlite3mc`) even though some comments and
`docs/g0/PENDING_INPUTS.md` still say pending; reconcile the comments, but do not edit PENDING_INPUTS.md beyond adding a dated
note that approval exists in pubspec (owner must confirm).

## Work items

### A. Production wiring (no new Dart packages)
A1. Provide the app files directory and a Keystore-wrapped database key through a Kotlin `MethodChannel` in
`android/app/src/main/kotlin/com/niaverp/niaverp/MainActivity.kt` (Android Keystore AES-GCM key wraps a random 32-byte DB key stored in
app-private storage). Follow the contract in `lib/data/security/key_lifecycle.dart` and `lib/data/db/key_provider.dart` exactly
(missing/available/locked/failed; no recovery API; codes only, never key bytes in messages or logs). minSdk stays 26.
A2. Implement a Dart `KeyProvider` over that channel and make `CipherDatabaseOpener` take the provider (or a key obtained from it); keep the
existing tests green.
A3. In `lib/app`, add a startup sequence: load migration assets (`migration_assets.dart`), obtain key, open the encrypted database, build
`CompositionRoot.backend(...)`, convert the `BackendBundle` to `CompanyScope` with a real `scopeOfBackend`-style function (the shell
comment says a converter exists; add or fix it), and pass it to `NiavShell`. Show distinct, non-technical states for: starting, key
failure (codes only), database failure, newer-schema refusal. Never fall back to plaintext or to an unencrypted engine.
A4. `main()` must be exercised by a widget test that runs the real startup sequence with an injected fake channel and an in-memory or
temp-file engine, and proves: tabs show real data after startup; key failure shows the failure state; no plaintext fallback path exists.

### B. Resource lifecycle and key hygiene
B1. `NiavDatabase.close()` must really release the native handle (close the underlying engine/`FfiDatabase`), be idempotent, and reject
further use. The opener must keep what it needs to close. Add a test that reopening the same file after close works.
B2. In `CipherDatabaseOpener`, wrap the `PRAGMA key` execution so any exception is rethrown as a code-only error that cannot contain the
key text. Add a test with a throwing engine proving the key hex never appears in the error string or `toString()`.
B3. `FfiDatabase.runInTransaction`: if the body fails, make the rollback safe when SQLite already rolled back, and never mask the original error.
Add a test.
B4. `CompositionRoot.backend` must close the database if bootstrap throws.

### C. Identifier policy (D-M4: UUIDv7 text IDs)
C1. Add a pure-Dart UUIDv7 generator in `lib/core` (injectable `Clock` and random source, monotonic within a millisecond, lowercase canonical text).
C2. Use it for production `WriteContext`/ID minting (replace `CounterIdMint` in production wiring; keep it for tests). Add tests for format,
version/variant bits, ordering and uniqueness over 10,000 values.

### D. Voucher-engine invariants (all must be in `lib/application/services/voucher_engine.dart` and repositories, not widgets)
D1. `cancelPosted` must also (in the SAME transaction as the status move): refuse if the voucher date is in a locked period (reuse
`isDateLocked`), write compensating stock movements (opposite sign, same item/godown/value, linked to the original movement and cancelled
voucher) and adjust cost layers by compensating records without rewriting history, and reverse the voucher's bill allocations by marking them reversed with
audit. Stock/layer reversal must follow `docs/g0/MIGRATION_DESIGN.md`, the Data Schema/Database Schema documents and D-M5 (no retroactive
revaluation). If the existing schema cannot express the reversal without a new column or table, add the smallest additive repeat-safe
migration `m016_*` (ADD COLUMN guards, FK/CHECK, downgrade refusal) and update `kLatestVersion`, assets in `pubspec.yaml` and migration tests. If the documents do not define the
reversal rule, mark D1 `blocked` with the question and do not guess.
D2. `VoucherRepository.updateHeldStatus` must not be able to set `posted`. Posting goes only through the engine. Add a test that
attempting it fails and leaves the voucher unchanged.
D3. `postDraft`: remove it from the public API or make it delegate to the same transactional path as `postWithStock` (validation and status
move inside ONE transaction, with stock effects and allocations). No posting path may skip validation, Dr=Cr, period lock, stock effects or numbering.
D4. `VoucherRepository.addLine`: reject unless the voucher is `draft` (or the documented editable state). Add tests for posted and cancelled vouchers.
D5. Company scope: add `company_id` to `item_cost_state` (additive migration with backfill from `item`), key and index it accordingly,
update `voucher_engine.dart` reads/writes, and add `AND company_id = ?` to the `UPDATE stock_cost_layer ... WHERE layer_id = ?` statement
(and any other unscoped statement you find by grep). Add a test using two companies that share an item code and prove costs do not leak.
D6. Stock movement audit actor must be the real actor passed in, not the literal `'posting-engine'`.
D7. Item lines without a `godownId` must not be silently ignored when the item is stock-tracked: return a validation error (or the documented
warning). Add tests.
D8. Method-lock edge case: first issue via fallback/zero cost must still lock the costing method per D-M5, or record `blocked` with the question.
D9. `checkJournalBalance`: a voucher type that must balance (Journal, Contra, Debit/Credit Note without items) with zero ledger lines must be rejected.
Confirm per `DECISIONS.md`; if the documents allow empty, leave it and note why.

## Required tests (minimum)
- Cancel a purchase: on-hand returns to the pre-purchase quantity, a compensating movement exists, original rows are untouched, allocations show reversed, one audit event exists.
- Cancel in a locked period is refused and nothing changes.
- Cancel is atomic: inject a failure after stock reversal and prove everything rolls back.
- updateHeldStatus→posted refused; addLine on posted/cancelled refused; postDraft cannot bypass checks.
- Two-company cost isolation.
- Startup test for A4; key-redaction test for B2; reopen-after-close test for B1; UUIDv7 tests for C.
Final `flutter analyze` must report no issues and every pre-existing test must still pass (fix tests only when the documented rule changed, and say why in section 6).

## Do not
Do not add invoice ledger/GST posting (that is D3). Do not change document-flow, UI screens other than the startup/error states, or any file in the HTML set. Do not mark device,
Keystore-on-device, or Android 8 behaviour as PASS: host and fake-channel tests are not device evidence. Record them as pending under `G0-VER-005`.

## Required output
Write `docs/implementation/RESULT_D1_repair_and_production_wiring.md` using the template in `delta/README.md` (all nine sections), with one
row per work item A1–D9 in section 2. Append one line to `docs/implementation/RESULTS_INDEX.md`:
`D1 | <date> | <overall status> | tests <passed>/<failed> | <one-line summary>`.
End your final chat message with the Overall status and the path of the results file only.
