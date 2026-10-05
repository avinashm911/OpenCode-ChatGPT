# Implementation Phase 01 — local backend foundation

Date (UTC): 2026-10-03
Prompt: `docs/opencode_master_prompts/01_local_backend_foundation.md`
Contract: `docs/opencode_master_prompts/GLOBAL_NO_INVENTION_CONTRACT.md`
Authority: `docs/IMPLEMENTATION_EXECUTION_STRATEGY.md` Slice 1; `NiAv_G0_Prompts_Pack_v0.9.md`;
  `niaverp/AGENTS.md`; `niaverp/DECISIONS.md`; `docs/g0/MIGRATION_DESIGN.md` §§1–2;
  `docs/g0/PENDING_INPUTS.md`; 15 HTML requirement documents (read-only).
Previous phase report: `docs/implementation/phase-00.md`.

## Objective

Production database abstraction over the audited G0 migration chain:
bootstrap, key-provider seam, repositories with transaction boundaries —
without claiming SQLCipher production support.

## Changed files

Interface (extended, engine-neutral):
- `niaverp/lib/data/migrations/migration_runner.dart` — `MigrationDb` gains
  `executeArgs` + `queryArgs` (`?` placeholders). DDL path (`migrate`) untouched.

New production code (`lib/`, no new packages):
- `niaverp/lib/data/db/niav_database.dart` — `NiavDatabase` (bootstrap: FK
  pragma, newer-schema refusal per DSS-C-007/G0-CON-003, idempotent migrate;
  `schemaVersion`; guarded `close`); `EncryptedDatabaseOpener` interface
  (BLOCKED until P-SQLIB closes; no plaintext fallback permitted).
- `niaverp/lib/data/db/key_provider.dart` — `KeyProvider` /
  `LifecycleKeyProvider` over the approved `KeyLifecycle` (D-06); failures
  carry codes only, never key bytes.
- `niaverp/lib/data/repositories/repository.dart` — `RepositoryContext`
  (db + clock), `nextOperationSeq` (DSS-C-004), `dbError` mapping
  (UNIQUE→conflict, FK→foreign-key, CHECK→check, else db), `RepositoryAbort`.
- `niaverp/lib/data/repositories/operation_log.dart` — append-only SYNC §3
  envelope (+ base_version default 1, payload hash).
- `niaverp/lib/data/repositories/audit_log.dart` — append-only OD-DB-004
  events (JSON deltas, SHA-256 canonical payload hash via package:crypto,
  already a dependency).
- `niaverp/lib/data/repositories/company_repository.dart` — create/get over
  m001 `company` with op + audit lineage in one transaction.
- `niaverp/lib/data/repositories/item_repository.dart` — create/get/
  listByCompany over m001 `item` (existing columns only; HSN/aliases/search
  are prompt 02/M03 scope).
- `niaverp/lib/data/repositories/voucher_repository.dart` — header create,
  `addLine` (amount via approved `lineAmount`, discounts validated via
  `validateDiscountInputs`, stored as given), get-with-lines, listByCompany.
  Type/status stay free TEXT (19-type registry + transitions = prompt 03A).

Test-only (dev dependencies only, never shipped):
- `niaverp/test/helpers/test_database.dart` — deterministic in-memory
  factory (`openTestDatabase(upTo, fixedMs)` with `TestClock`, FK enforced).

Tests (new, 21):
- `niaverp/test/data/db/niav_database_test.dart` (7) — clean install v8,
  repeat-safe re-bootstrap, staged v1→v8 upgrade preserves rows,
  newer-schema refusal, FK + CHECK enforcement.
- `niaverp/test/data/repositories/company_item_repository_test.dart` (7) —
  round-trips, duplicate→conflict, missing-company→foreign-key with no
  lineage residue, company isolation, op + audit lineage.
- `niaverp/test/data/repositories/voucher_repository_test.dart` (7) —
  D-M4 line math (2.5 × Rs 9.99 → 2498p), series+no duplicate→conflict,
  discount validation pre-DB, ghost-line atomicity (no lineage residue),
  failures carry codes not values, cross-company invisibility.

Touched prototypes (mechanical, behavior preserved):
- 5 test adapters (`migration`, `costing`, `settlement`, `entitlements`,
  `statutory_boundary`) gain the two new `MigrationDb` methods.

Untouched: 15 HTML, workbooks, registers (read-only); `pubspec.yaml`
(no package added — Drift/SQLCipher stay unselected candidates);
`lib/data/accounting/*`, `lib/data/security/*`, `lib/data/print/*`;
`CompositionRoot` (DB wiring into the app is a later slice).

## Decisions / blockers (no invention)

- P-SQLIB OPEN (no owner input this run): no library chosen, no dependency
  added, no production encryption claimed. `EncryptedDatabaseOpener` is an
  interface only. Owner question: which exact SQLCipher-class library,
  version, and licence evidence is approved, with Android 8 proof?
- Native Keystore wiring OPEN (P-KEYSTORE/G0-VER-005): `KeyProvider` is a
  seam over the host-tested `KeyLifecycle`; device runs pending.
- PARTY DAO STOPPED (not omitted silently): m001 defines no party table
  (company/item/godown/voucher/line/operation/audit only; full domain tables
  land with gated phases per MIGRATION_DESIGN.md §1). Owner/design question:
  which approved party-master field list (columns, constraints, FRD/DSS
  source IDs) should prompt 02 (M03 work package) implement?
- UUIDv7 generation pending: repositories accept caller-supplied IDs
  (tests use fixed IDs); no generator invented.
- Voucher-type/status vocabularies pending (prompt 03A): stored as TEXT,
  validated non-empty only.

## Commands and environment

Workdir `E:\NiavERP v2 OpenAI\niaverp`; Flutter 3.47.5 / Dart 3.13.4;
Windows 10 Pro 22H2; disposable in-memory SQLite only.

- `flutter analyze` → **No issues found!**
- `flutter test` → **+128: All tests passed!**
  (107 prior + 21 new; zero regressions across all 14 pre-existing suites.)

## Traceability IDs

DSS §6; DB §8; DSS-C-001/004/007; SYNC §3; OD-DB-004/006; D-M4 (lineAmount);
D-06 (key shape); RSP 5 / G0-CON-003 (downgrade refusal); G0-SCH-001…007
(chain preserved); G0-VER-001/005 (blocked); M03 (party master, prompt 02).

## Unresolved items / downstream pending evidence

P-SQLIB (blocks encrypted prod wiring + prompt 01 completion claim),
P-DEVICE-8/CUR + P-KEYSTORE (device runs), party-master field list
(prompt 02 question above), P-FIELD-LIST + P-EINV/GSTR/EWAY-SCH (G3/R1a),
P-LEGAL-001…005, P-PRN-001…003 + P-APK/ZIP-SHA + P-CH-WA/EM/LINK (G5).
Deferred: G0-DEF-001:R3, G0-DEF-002:Later-release, G0-DEF-003:R2.

## Acceptance check

- [x] Clean install and v1→v8 upgrade tests pass (real SQLite).
- [x] Repeat migration is safe (ledger-skip + guarded re-bootstrap).
- [x] Database failures do not expose key material (codes only; redacted DbKey).
- [x] Repository tests use real SQLite semantics (FK/CHECK/UNIQUE enforced).
- [x] `flutter analyze` + `flutter test` pass (+128).
- [x] No screens started in this prompt.

## Next gate

Prompt 02 — masters and search backend (M03 work package + party-master
field decision): company/party/item/godown repositories on approved schema,
units/HSN refs, duplicate detection, audit history, search indexes/aliases.
Encrypted production wiring still waits on P-SQLIB.
