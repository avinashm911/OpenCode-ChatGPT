# D2 — Schema and security hardening

## Mandatory first actions
1. Read `niaverp/AGENTS.md`, `niaverp/DECISIONS.md`, `docs/IMPLEMENTATION_EXECUTION_STRATEGY.md`,
   `docs/opencode_master_prompts/GLOBAL_NO_INVENTION_CONTRACT.md`, `SOURCE_CLARIFICATIONS.md`, `docs/g0/PENDING_INPUTS.md`,
   `docs/g0/MIGRATION_DESIGN.md`, and `docs/implementation/RESULT_D1_repair_and_production_wiring.md` (must exist with status PASS or
   PASS-WITH-BLOCKS; otherwise stop with FAIL).
2. Read the relevant living HTML sections (read-only): Data Schema Specification, Database Schema Document, Security & Anti-Exploitation Plan,
   Sync Protocol Specification. Every constraint, index, hash or MAC you add must trace to a section or decision ID; if the documents do not
   define it, mark the item `blocked` with the exact question instead of choosing.
3. Run `flutter analyze` and `flutter test` first; record totals.

## Context
A review found: no triggers anywhere, so audit/operation rows and posted vouchers are immutable only by convention; almost no CHECK
constraints on status/enum columns; no indexes on `voucher_line(item_id/party_id/ledger_id/godown_id)` or `voucher(company_id, fy_id)` /
`(company_id, voucher_type, voucher_date)`; `record_version` never incremented; audit update rows lack old values; code comments mention a
audit "hash chain" that does not exist; `schema_migrations` has no checksum; backup manifest uses an unkeyed SHA-256 (detects corruption, not tampering)
and no restore implementation exists; entitlement trusts the device clock; Android release signing uses the debug key and `allowBackup` is unset.

## Work items (each additive, repeat-safe, covered by migration tests; new migrations continue after the last existing number)

### A. Immutability enforcement
A1. Triggers making `audit_event` and `operation` append-only (reject UPDATE and DELETE). If any current code updates them, fix the code, not the trigger.
A2. Triggers protecting posted vouchers: reject UPDATE/DELETE of `voucher_line` rows whose voucher is posted/cancelled; reject changes to posted `voucher`
rows except the single documented transition posted→cancelled (with the fields the engine writes). Prove with tests that the engine's legitimate paths still work.
A3. Resolve the "hash chain" claim: if the documents require an audit hash chain, implement it (`prev_hash`/`row_hash`, deterministic canonical form, verify function, tamper test).
If not required, delete the misleading comments. State which in section 2.

### B. Integrity constraints
B1. Enum/status validation for: `voucher.status`, `period_lock.status`/`scope`, `bill_allocation.status`, `document_link.status`,
`stock_movement.cost_source`, `financial_year.status`, `operation.action`. SQLite cannot add CHECK to an existing table without a rebuild;
use validation triggers (BEFORE INSERT/UPDATE with RAISE(ABORT)) unless a safe table rebuild is justified and tested with data preserved. Allowed values must come from existing code and docs only.
B2. Cross-company reference guards (trigger or repository check, whichever is testable): a `voucher_line` item/party/ledger/godown must belong to the voucher's company.
B3. Missing foreign keys that the documents specify (e.g. `party.ledger_id`, `voucher_line.ledger_id`); add only where documented and data-safe, otherwise guard with triggers.
B4. Uniqueness per `(company_id, name)` for item, party, godown, voucher_type, voucher_series ONLY where the documents say names are unique (existing phase-02 rules
say godown name uniqueness is repository-level pending a rebuild boundary; resolve it now).
B5. `schema_migrations`: add a checksum of each applied migration's SQL; on startup, refuse to run if an already-applied migration's checksum differs. Provide a deterministic
backfill for existing databases and a test that editing an applied migration is detected.

### C. Performance indexes (only for queries that exist in `lib/application/queries`)
C1. Indexes on `voucher_line(company_id,item_id)`, `(company_id,party_id)`, `(company_id,ledger_id)`, `(company_id,godown_id)`; `voucher(company_id,fy_id)` and
`(company_id,voucher_type,voucher_date)`; company-scoped party name/GSTIN index; `audit_event`/`operation` index on `(company_id, created_at, id)` and make `forEntity`
ordering deterministic. For each index, add a test using `EXPLAIN QUERY PLAN` showing the target query uses it. Do not invent latency targets (M12.8 is TBC).

### D. Versioning and audit fidelity
D1. Increment `record_version` on every UPDATE of versioned tables (G0-SCH-005) through repositories, and write `base_version` where the operation envelope requires it. Tests per repository.
D2. Audit update events must carry old and new values for the changed fields (voucher status, narration, party, item). Add a shared helper so repositories stop duplicating audit boilerplate; refactor without changing behaviour; tests unchanged or extended.

### E. Backup and entitlement
E1. Backup manifest authentication: implement a keyed MAC (HMAC-SHA256 with the existing `crypto` package) per the Security plan, covering the manifest AND per-file hashes. If the plan does not define
the key-derivation source, mark `blocked` with the question and implement only the verification interface plus tests with an injected key.
E2. Implement restore validation (verify MAC, schema version, company, no downgrade) as pure logic with tests. Physical restore on device stays pending `G0-VER-008`.
E3. Entitlement clock-rollback guard: persist a last-seen-time high-water mark (use the `trial_anchor` table from G0-SCH-006 as documented) and make `evaluateEntitlement` treat a clock earlier than the mark as rollback per D-04/FG-014. Tests: normal progress, rollback, grace, expiry (data never deleted).

### F. Android configuration (no invented values)
F1. Set `android:allowBackup="false"` and `android:fullBackupContent="false"` unless the documents specify otherwise; add the smallest data-extraction rules needed. Do not invent a package id, app label or release channel: record them as owner questions.
F2. Release signing: leave the debug key, but fail the release build with a clear message unless a signing config is supplied (gradle property check). Do not create or commit keystores.
F3. `drift` is declared but never imported. Do NOT remove or adopt it. List it as an owner question (strategy: Drift only when confirmed).

## Required tests (minimum)
Trigger tests (each rejects what it should and allows the engine's real paths), migration chain test from an empty database and from a database at the previous latest version with seeded data,
checksum tamper test, EXPLAIN QUERY PLAN tests, record_version tests, audit old/new test, MAC tamper/replay tests, rollback-clock test. Final `flutter analyze` clean; all prior tests pass.

## Do not
Do not weaken any existing constraint, do not drop or rewrite existing columns, do not touch voucher posting rules (D3), UI, or HTML documents. Cipher behaviour and on-device behaviour remain pending evidence (G0-VER-001/005/008); host tests are not device evidence.

## Required output
Write `docs/implementation/RESULT_D2_schema_and_security_hardening.md` using the template in `delta/README.md`, with one row per item A1–F3 in section 2 (include migration numbers and the
trigger/index names you created in section 3). Append to `docs/implementation/RESULTS_INDEX.md`:
`D2 | <date> | <overall status> | tests <passed>/<failed> | <one-line summary>`.
End your final chat message with the Overall status and the path of the results file only.
