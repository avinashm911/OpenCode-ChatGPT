# RESULT D2 — Schema and security hardening
Date (UTC): 2026-10-06   Overall status: PASS

## 1. Baseline before changes

- `flutter analyze` before editing: **No issues found** (Flutter 3.47.6 /
  Dart 3.13.5 via `dart.exe flutter_tools.snapshot`).
- `flutter test` before editing: **404 passed / 0 failed**.
- RESULT_D1 status PASS (verified §1); D0 inventory consumed.
- Mandatory source reads (all read-only; HTML never edited): Data Schema
  Specification (§3 catalogue, DSS-C-001…C-007, open decisions), Database
  Schema Document (§3 entity catalogue, §6 DB-001…007, OD-DB-004 resolution),
  Security & Anti-Exploitation Plan (§3.5 trusted_now, backup encryption from
  user passphrase, no MAC/KDF defined, tamper/response rows), Sync Protocol
  (op envelope §3 — via MIGRATION_DESIGN), plus `docs/g0/MIGRATION_DESIGN.md`
  (§6 lifecycle enums are app logic, not schema CHECKs — see §6 below).
- Missing phase reports (stated, not invented): `phase-00/01/02.md`.
- git: branch `baseline-triage-20261006-d0r2`; no-space alias not needed.

## 2. Work-item table

| ID | Item | Status (implemented / boundary / blocked / not-done) | Evidence (file:line, test name) |
|---|---|---|---|
| A1 | audit/operation append-only triggers | implemented | `m017` `trg_audit_event_no_update/delete`, `trg_operation_no_update/delete` (DB-004, DSS-C-003); no lib/test code touches those tables (`migration_hardening_test: 'audit_event and operation reject UPDATE and DELETE'`) |
| A2 | Posted-voucher triggers (only posted→cancelled; lines frozen) | implemented | `m017` `trg_voucher_posted_update/delete`, `trg_voucher_line_posted_update/delete` (DSS-C-003, M04); engine post/cancel paths proven by the unchanged suite (404) + direct-transition tests in `migration_hardening_test` |
| A3 | Audit hash chain | implemented | Required, not comment-only: OD-DB-004 resolution ("hash chain over canonical record") + Security "audit chain detects casual tampering". `audit_event.prev_hash/row_hash` (m017), writer chains, `verifyAuditChain` + tamper/legacy tests (`migration_hardening_test` chain group) |
| B1 | Enum/status vocabulary triggers | implemented | 12 triggers for voucher.status (5 values), period_lock.status, bill_allocation.status, document_link.status, stock_movement.cost_source (9), operation.action (8) — values from code+docs only. Excluded per sources: period_lock.scope (MIGRATION_DESIGN: app policy, not schema) and financial_year.status (m011: vocabulary unspecified — recorded open) |
| B2 | Cross-company line guards | implemented | `m017` `trg_voucher_line_company_ins/upd` (DSS-C-001); same-company passes, foreign item/party/ledger/godown rejected with `validation` (`migration_hardening_test`, updated ghost tests) |
| B3 | Documented ledger FKs | implemented | DB §3 catalogue documents party/voucher_line ledger FKs; enforced by the B2 triggers (existence + same-company) instead of a table rebuild (rebuild not justified, data-safe trigger equivalent). bank_account.ledger already has a real FK (m014) |
| B4 | (company,name) uniqueness | blocked | Question: which entities, if any, require DB-level UNIQUE(company,name)? Documents specify it only for unit, item_group, account_group, ledger, role, FY-start and bank-ledger — all already built. item/party/godown/type/series names are idx-only in the catalogue; godown uniqueness stays repository-level (phase-02 rule). No constraint invented |
| B5 | Migration checksums + refuse on mismatch | implemented | `schema_migrations.checksum` (m017) + runner verify/backfill/refuse (`migration_runner.dart`); staged-upgrade + tamper-refusal tests (`migration_hardening_test`); trust-on-first-use backfill documented |
| C1 | Query-backed indexes + EXPLAIN + deterministic forEntity | implemented | 9 indexes (m017); EXPLAIN tests for all 9 (`migration_hardening_test`); `forEntity` deterministic (audit `created_at,rowid`; operation `seq,op_id`); no latency target invented (M12.8 TBC) |
| D1 | record_version on every UPDATE + base_version | implemented | Bumps on all 10 versioned-table UPDATE paths (voucher×2, allocation×2, doclink, period, item×2, party, layer×2); `item_cost_state` has no record_version column and company has no update path (noted, not invented). `ops.append(baseVersion:)` already existed — tested default 1 + explicit |
| D2 | Audit old/new on updates + shared helper | implemented | oldRow added to all 6 update paths lacking it (voucher moves, allocation/doclink reversals, unlock); `recordLineage` helper used by every repository + engine lineage site (creates and updates, same args/maps/codes — suite green, no behaviour change) |
| E1 | Backup manifest MAC | blocked | Question: what is the manifest-MAC key-derivation source? The Security plan derives backup encryption from a user-passphrase flow that does not exist in the app — no MAC KDF defined. Implemented instead: injected-key HMAC interface + verification + tamper/replay/wrong-key tests (`backup_test.dart`) |
| E2 | Restore validation as pure logic | implemented | `checkRestorable` (+ optional keyed MAC check) covers MAC/schema/company/downgrade with tests; physical restore on device stays pending G0-VER-008 |
| E3 | Entitlement clock-rollback guard | implemented | SEC §3.5 `trusted_now` + `trial_anchor.last_seen_at` high-water (m017) + `observeDeviceClock` + progress/rollback/grace/expiry tests (`clock_rollback_test.dart`); data never deleted. Warning surfacing + security-event logging belong to the caller (no UI changes in D2) |
| F1 | allowBackup flags | implemented | `allowBackup="false"` + `fullBackupContent="false"`; no rules file needed (nothing allowlisted). Owner questions in §7 (package id, app label, release channel) |
| F2 | Release signing guard | implemented | `build.gradle.kts` release block throws unless `NIAV_RELEASE_*` properties supplied; debug key never used silently; no keystores created or committed |
| F3 | Unused drift dependency | implemented | Untouched as ordered; recorded as owner question in §7 (strategy: Drift only when confirmed) |

## 3. Changed files (new / modified / deleted, one line each)

Migration (v17):
- NEW niaverp/lib/data/migrations/m017_schema_hardening.sql (4 guarded ADD COLUMNs; 26 triggers: trg_audit_event_no_update/delete, trg_operation_no_update/delete, trg_voucher_posted_update/delete, trg_voucher_line_posted_update/delete, 12 vocabulary ins/upd, trg_voucher_line_company_ins/upd, trg_party_ledger_ins/upd; 9 indexes: idx_voucher_line_company_{item,party,ledger,godown}, idx_voucher_company_{fy,type_date}, idx_party_company_name_gstin, idx_audit_company_time, idx_operation_company_time)
- MOD niaverp/lib/data/migrations/migration_registry.dart (v17 entry, kLatestVersion 17)
- MOD niaverp/pubspec.yaml (m017 asset)
- MOD niaverp/lib/data/migrations/migration_runner.dart (checksum column in ledger DDL, verify/backfill/refuse, checksum on apply)
Production code:
- MOD niaverp/lib/data/repositories/audit_log.dart (chain write, deterministic forEntity, verifyAuditChain, recordLineage helper)
- MOD niaverp/lib/data/repositories/operation_log.dart (deterministic forEntity ordering)
- MOD niaverp/lib/data/repositories/repository.dart (trigger-marker → validation mapping in dbError)
- MOD niaverp/lib/application/services/voucher_engine.dart (version bumps ×3, oldRow on status move, lineage refactor)
- MOD 13 repository files (version bumps on all UPDATE paths; oldRow on all update audits; recordLineage refactor of every lineage site)
- MOD niaverp/lib/data/security/backup.dart (fileHashes/macHex, HMAC interface + verify, keyed checkRestorable)
- MOD niaverp/lib/data/security/entitlements.dart (trusted_now, high-water observe)
- MOD niaverp/android/app/src/main/AndroidManifest.xml (backup flags)
- MOD niaverp/android/app/build.gradle.kts (release signing guard)
Tests (new / modified):
- NEW niaverp/test/migrations/migration_hardening_test.dart (18: triggers, vocab, guards, staged upgrade, checksum tamper, 9 EXPLAIN groups, versions, old/new, chain)
- NEW niaverp/test/security/clock_rollback_test.dart (6)
- MOD niaverp/test/security/backup_test.dart (+3 MAC tests)
- MOD niaverp/test/migrations/migration_test.dart (v17 chain + m017 object asserts)
- MOD 5 migration test files + production_boundary_test.dart (16→17 pins, m017 asset)
- MOD niaverp/test/data/repositories/bank_account_test.dart, voucher_refs_test.dart (ghost-ref expectations → fail-fast validation; see §6)
- MOD niaverp/test/application/voucher_posting_test.dart, voucher_cancel_test.dart (layer version asserts)
Deleted: none.

## 4. Tests

- Added: 27 tests (hardening 18, backup MAC 3, clock 6). Final: `flutter
  analyze` → No issues found; `flutter test` → **431 passed / 0 failed**.
- Required D2 scenarios covered: trigger allow/reject incl. engine real paths
  (suite), staged v16→v17 with seeded rows, checksum tamper + backfill, 9
  EXPLAIN proofs, version bumps per table, audit old/new, chain verify + tamper
  + legacy prefix, MAC tamper/replay/wrong-key + legacy hash path, clock
  progress/rollback/grace/expiry (+ exports survive expiry).
- Pre-existing tests: two ghost-ref expectations updated to the documented
  fail-fast direction (see §6); everything else passes unchanged.

## 5. Commands run and exact output summary

- `flutter analyze` before: No issues; after: No issues found.
- `flutter test` before: +404; after: **+431: All tests passed!** (~32s).
- Per-file isolation runs during development (migrations, bank, refs,
  hardening, backup, clock, voucher suites) — one genuine interaction found
  and resolved (§6); three mechanical lineage refactors delegated to
  subagents (file-disjoint batches A/B/C), each verified by the agent with
  analyze + targeted tests, re-verified here by full suite + diff review.
- Greps: `posting-engine` still absent; all `stock_cost_layer`/`item_cost_state`
  statements carry `company_id`; operation.action vocabulary covers all 34
  call sites; no lib/ UPDATE/DELETE touches audit_event/operation (the negative
  test scans for exactly this).
- Environment: same SDK invocation; no alias needed.

## 6. Deviations from the prompt, with reason

- `dbError` maps the m017 trigger markers to `validation` (rule breach, not DB
  failure): without it every guard rejection would surface as opaque `db`.
  Marker strings are fixed, value-free codes.
- Ghost-ref tests (`bank_account`, `voucher_refs`) now expect `validation` at
  `addLine` instead of engine/post-time rejection: the B2 guard (documented DB
  §3 FK) fails fast at write time — same direction as the D0 FK→validation
  precedent; engine grounding retained.
- `recordLineage` refactor touched ~30 call sites with identical args/maps/codes;
  the full suite (431) proves no behaviour change. `party.addAddress` included.
- Single-line trigger bodies: the runner splits statements on line-final
  semicolons, so multi-line `BEGIN…END` would corrupt parsing; one trigger per
  line, noted in the migration header.
- Checksum backfill is trust-on-first-use for pre-m017 ledgers (documented in
  m017 + runner comment); pre-checksum ledgers skip verification for one pass.
- `operation.forEntity` keeps `seq` ordering (+ `op_id` tiebreak) instead of
  the index's `created_at` order — causal replay order is existing behaviour;
  the mandated index serves time-ordered sync scans (SYNC §3 envelope), proven
  by EXPLAIN. Audit uses `created_at, rowid` (insertion-stable, back-compat).
- B4, E1 recorded `blocked` with exact questions (§7); FY-status and
  period-lock-scope excluded from B1 per m011/MIGRATION_DESIGN; B3 done via
  triggers (rebuild not justified); F1 needs no rules file; E3 warning/event
  surfacing is caller-owned (D2 forbids UI changes); `item_cost_state` has no
  version column (not added — out of scope).

## 7. Owner questions (exact source ID + question) and downstream evidence still pending

- D2-B4: which entities, if any, require DB-level UNIQUE(company_id, name)?
  (Documents specify uniqueness only for already-built cases; nothing invented.)
- D2-E1: what is the manifest-MAC key-derivation source? (Security plan has no
  MAC KDF; injected-key interface + tests delivered instead.)
- D2-F1: confirm the package id (`com.niaverp.niaverp`, TODO in gradle), the app
  label (`niaverp`), and the release channel (none defined — G0-VER-004).
- D2-F3: `drift` is declared but never imported — adopt, remove, or keep held?
  (Strategy: Drift only when its dependency/licence choice is confirmed.)
- Carried: P-SQLIB owner confirmation + G0-VER-001 device/cipher proof;
  G0-VER-005/008, 003/004/006/007 evidence; missing phase-00/01/02 reports.
- No other new `blocked` items.

## 8. Honesty statement

- 431 passing tests are host/in-memory runs (sqlite3 incl. sqlite3mc build,
  temp files); trigger/vocab/guard behaviour is proven on host SQLite only —
  nothing here is Android-device, printer, legal, statutory, or release
  evidence (G0-VER-001/005/008 explicitly pending).
- The release-signing guard and manifest flags were edited but no APK was
  built; no keystores exist. No mock or scaffold result is presented as
  production evidence. No field, rule, package, permission, or platform
  behaviour was invented; no HTML, workbook, or register was edited; no test
  was deleted (two ghost expectations moved to the documented fail-fast point,
  §6).

## 9. Next prompt

- D3 (`delta/D3_invoice_posting_ledger_vouchers_reports.md`) is next per the
  Delta order. After D3–D4, master prompts 07–11 (missing parts) then 12, 13
  (per the D0 coverage audit). D3 owns invoice ledger/GST posting — untouched
  here by design.
