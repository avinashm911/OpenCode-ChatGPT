# NiAvERP G0 — Migration Design (Phase 1)

Date (UTC): 2026-10-03
Prompt authority: `NiAv_G0_Prompts_Pack_v0.7.md` Phase 1
Design status: reviewed against DB v0.4 / DSS v0.4; implementation follows in this phase.
G0 sign-off baseline: CONDITIONAL (unchanged by this phase).

Global rules applied: money INTEGER paise; quantity INTEGER ×10⁴; line amount
round-half-up `(qty × rate) / 10⁴`; invoice round-off separate ledger line (D-M4);
migrations deterministic, idempotent, auditable; rollback ONLY via approved
procedure (uninstall current APK → install previous APK → restore external backup;
in-place downgrade NOT supported; RSP 5 / G0-CON-003). No server/cloud dependency.
No excluded capability is built. Tests run only against disposable databases.

---

## 1. DB/DSS review (what the approved baseline already gives us)

DB v0.4 (NIAV-DB) and DSS v0.4 (NIAV-DSS) define the logical baseline this design
extends. Points relied upon — nothing here is newly decided:

- V1 authoritative store is local SQLite/Drift, one encrypted database per company;
  Drift provides typed access and migrations (DSS §2). Final SQLCipher-class
  library choice stays BLOCKED (G0-VER-001); DDL below uses only widely-supported
  SQLite syntax so it runs on host SQLite and old Android SQLite alike.
- Physical-type rule actually applied: IDs UUIDv7 TEXT PK (DB-001 + D-M4);
  money INTEGER paise; quantity INTEGER ×10⁴; dates ISO TEXT; timestamps INTEGER
  epoch-ms UTC (DB-002 + D-M4 resolution). No REAL/FLOAT anywhere in money/qty.
- Company isolation: every company-owned entity carries `company_id`
  (DSS-C-001). Voucher-number uniqueness lives at series scope (DSS-C-002);
  posted records are never destructively deleted (DSS-C-003); operations are
  replay-safe by `op_id` + device/seq (DSS-C-004); derived data is rebuildable
  (DSS-C-006 / DB-006).
- Migration discipline already required by the documents: schema version stored
  locally; each release declares its migration range; migrations deterministic and
  tested against representative prior databases; backup/recovery point before
  destructive transformation; failure leaves source recoverable, no silent
  partial conversion (DB §8); numbered migration per release, downgrade refused
  unless a future design supports it (DSS-C-007); run in transaction where
  practical, validate invariants + derived rebuild, commit version only after
  validation, record result + build (DSS §6).
- Operation envelope already fixed by SYNC: `op_id`, `device_id`, `seq`,
  timestamp, `company_id`, entity, `entity_id`, action, `base_version`
  (SYNC §3). Conflict rule already fixed: masters field-merge, same-field clash
  host-arrival-wins + loser logged; vouchers/drafts/approvals go to Conflicts
  queue (SYNC §6 / G0-CON-004). Conflict record shape already fixed:
  `sync_conflict(conflict_id, entity, entity_id, losing_op_id, winning_op_id,
  base_version, status, resolution, resolver, resolved_at)` (OD-DB-006).
- Audit payload rule already fixed: field-level old/new deltas as JSON,
  sensitive fields hash-only, hash chain over canonical record (OD-DB-004).
  Licence shape already fixed: trial 3 months full-set; 10-day grace full
  function + daily reminder then read-only + export + backup, data never
  deleted; `entitlements.json` single source
  (D-04/O-05/D-FG-014, D-11/D-13/A-R2); prepaid keys with expiry; reissue
  limit 20 (D-FG-012).
- Valuation rule already fixed: Weighted Average + FIFO only, item overrides
  group, default Weighted Average, locked after first posted stock movement,
  negative stock allowed with warning, no-layer issues at last known cost, no
  retro revaluation in V1, period lock by date with right + reason + audit,
  orders never reserve stock (D-M5 …, gate G1).
- Open items this design does NOT close: detailed GST/statutory fields and
  response artifacts (DSS-O03 → Phase 4/G3, IRN/ack/e-way field list BLOCKED);
  audit old/new representation beyond the fixed rule (DSS-O04 → applied as
  stated); attachment container/provider semantics (DSS-O05 → Phase 3);
  exact GST rounding golden fixture (G0-VER-002 → Phase 2); any lifecycle enum
  freeze beyond what is written below (status/scope columns are TEXT; lifecycle
  transitions are Phase 2+ app logic, not schema CHECKs).

Baseline entity catalogue reused as FK parents (DB §3 / DSS §3): `company`,
`item`, `godown`, `voucher`, `voucher_line`, `operation`, `audit_event`.
Migration `m001` creates only the minimal columns of these parents needed to
host the seven deltas — it is a migration baseline, not the full ERP domain
schema (full domain tables land with their own gated phases).

---

## 2. Migration layout and ordering

Files live under `niaverp/lib/data/migrations/` (versioned `.sql`, auditable
text) plus a Dart registry + runner + pure-Dart validators. Production Drift
wiring consumes the same SQL; test harness executes it against disposable
SQLite databases via `package:sqlite3` (dev-only).

| Version | File | G0 ID | Content | Depends on |
|---|---|---|---|---|
| 1 | `m001_base.sql` | (baseline) | `schema_migrations` ledger; minimal parents: `company`, `item`, `godown`, `voucher`, `voucher_line` (pre-discount), `operation` (pre-versioning), `audit_event` | — |
| 2 | `m002_sch001_cost_layers.sql` | G0-SCH-001 (G1) | `stock_cost_layer`, `stock_movement`, `item_cost_state` | v1 |
| 3 | `m003_sch002_period_lock.sql` | G0-SCH-002 (G1) | `period_lock` | v1 |
| 4 | `m004_sch003_bill_allocation.sql` | G0-SCH-003 (G1) | `bill_allocation` | v1 (voucher_line) |
| 5 | `m005_sch004_tax_layout.sql` | G0-SCH-004 (G1) | `tax_rate_hsn`, `layout_profile` | v1 |
| 6 | `m006_sch005_versioning.sql` | G0-SCH-005 (S1) | `record_version` on domain tables; `operation.base_version`; `operation_dependency`; `sync_conflict` | v1–v5 tables exist |
| 7 | `m007_sch006_trial_denylist.sql` | G0-SCH-006 (G0) | `trial_anchor`, `denylist_entry` | v1 |
| 8 | `m008_sch007_discount.sql` | G0-SCH-007 (G1) | `voucher_line.discount_amount_paise`, `voucher_line.discount_rate_bps` | v1 |

Order rationale: base first; additive tables next (no interdependency except on
base); versioning (v6) after all tables it versions exist; discount alter (v8)
last so the bill-allocation FKs (v4) reference the pre-discount line shape first
— order is fixed and recorded in `migration_registry.dart`; the runner refuses
out-of-order application.

Upgrade approach: each migration runs inside one SQLite transaction; the
`schema_migrations(version, applied_at, description)` row is written in the same
transaction, so a failure rolls back DDL + ledger together — never a half
version. `CREATE TABLE IF NOT EXISTS` / `CREATE INDEX IF NOT EXISTS` plus a
`PRAGMA table_info` guard before each `ADD COLUMN` (old Android SQLite has no
`ADD COLUMN IF NOT EXISTS`) make re-application safe: applied versions are
skipped by ledger, unapplied-but-present objects are completed without error.

Rollback: follows ONLY the approved procedure — uninstall current APK, install
previous APK, restore the external backup (RSP 5 / G0-CON-003). In-place
downgrade is not supported and no `DOWN` migrations are shipped (consistent
with DSS-C-007). The design doc records this; the test suite asserts no
downgrade path is claimed.

Seed/backfill: clean install seeds NO business rows (no invented masters, no
invented tax rates — statutory rows wait for verified schemas, DSS-O03).
Upgrade backfills are deterministic defaults only: new `record_version` /
`base_version` = 1 (genesis: pre-G0 rows predate versioning), discount columns
= 0, `cost_source` existing rows N/A (no stock tables pre-G0, so no backfill
needed). Backfill statements are part of the migration files, hence audited.

---

## 3. Per-delta definitions

Common column conventions (from D-M4, applied uniformly, not repeated below):
IDs `TEXT PRIMARY KEY` (UUIDv7, app-generated); `company_id TEXT NOT NULL`
+ FK; money `INTEGER` paise; qty `INTEGER` ×10⁴; dates ISO `TEXT`;
timestamps `INTEGER` epoch-ms UTC; `record_version INTEGER NOT NULL DEFAULT 1
CHECK (record_version >= 1)` on every domain table created here (consistency
rule for G0-SCH-005; `operation`/`audit_event` append-only log tables and the
`schema_migrations` ledger itself are excluded).

### G0-SCH-001 — Cost layers and stock movements (gate G1; D-M5/D-08/OD-DB-002)

Tables: `stock_cost_layer`, `stock_movement`, `item_cost_state`
(see `m002_sch001_cost_layers.sql` for exact DDL).

- `stock_cost_layer(layer_id PK, company_id FK, item_id FK, godown_id FK,
  voucher_line_id NULL FK, qty_q4 INTEGER NOT NULL, value_paise INTEGER NOT NULL
  CHECK >= 0, created_at, record_version)`.
  Per D-M4 “stock value in paise; unit cost derived”: the layer stores
  quantity + value; unit cost is derived on read, never stored.
- `stock_movement(movement_id PK, company_id FK, item_id FK, godown_id FK,
  qty_delta_q4 INTEGER NOT NULL CHECK (!= 0), cost_paise INTEGER NOT NULL
  CHECK >= 0, cost_source TEXT NOT NULL, voucher_line_id NULL FK,
  operation_id NULL FK, created_at, record_version)`.
  `cost_source` records `layer | last_known | reconciled` as TEXT (which
  fallback priced the movement; reconciliation later appends a `reconciled`
  movement — V1 never rewrites history, per “no retro revaluation”).
- `item_cost_state(item_id PK FK, last_known_cost_paise INTEGER NOT NULL
  CHECK >= 0, updated_at)` — the approved last-known-cost fallback store.
- Indexes: `(company_id, item_id, godown_id)` on both layer and movement
  (DB §7 stock-read pattern); `voucher_line_id` lookups.
- Invariants: layer `qty_q4` may be zero (consumed layer retained for audit)
  but never edited in place — consumption appends movements; method
  (FIFO vs weighted-average) is an app-level costing choice locked after first
  posted movement (D-M5) and is NOT a schema enum; `qty_delta_q4 != 0`;
  `cost_source` non-empty (lifecycle values frozen with costing logic, Phase 2).
- Traceability: DB G0-SCH-001; DSS valuation rows; FR-M07-003 (OD-DB-002);
  D-M5/D-08/D-FG-013/O-09/OD-004/OD-FD-001.

### G0-SCH-002 — Period lock (gate G1; D-M5)

Table: `period_lock` (see `m003_sch002_period_lock.sql`).

- `period_lock(lock_id PK, company_id FK, scope TEXT NOT NULL,
  date_from TEXT NOT NULL, date_to TEXT NOT NULL
  CHECK (date_to >= date_from), status TEXT NOT NULL,
  locked_by TEXT NOT NULL, locked_at INTEGER NOT NULL,
  unlock_actor TEXT, unlock_reason TEXT, unlocked_at INTEGER,
  audit_event_id NULL FK, record_version)`.
- Scope covers date range + applicability (company/FY/voucher-type as TEXT —
  exact scope vocabulary is app policy, Phase 2+, not a schema CHECK).
- Invariants: `date_to >= date_from` (DB CHECK); unlock triple
  (`unlock_actor`, `unlock_reason`, `unlocked_at`) all-set or all-NULL
  (Dart validator + test; keeps NULL semantics portable across SQLite
  versions); unlock requires authorised actor + reason + audit link
  (D-M5 — enforced app-side, evidence row referenced); locks never delete
  history (DSS-C-003).
- Traceability: DB/DSS G0-SCH-002; FR-COM-002 (date policy respects locks);
  D-M5.

### G0-SCH-003 — Bill allocation (gate G1; FR-M06)

Table: `bill_allocation` (see `m004_sch003_bill_allocation.sql`).

- `bill_allocation(allocation_id PK, company_id FK,
  source_voucher_line_id NOT NULL FK, settlement_voucher_line_id NOT NULL FK
  CHECK (settlement != source), allocated_amount_paise INTEGER NOT NULL
  CHECK >= 0, allocation_date TEXT NOT NULL, status TEXT NOT NULL,
  operation_id NOT NULL FK, created_at, record_version)`.
- Indexes: source-line, settlement-line, `(company_id, allocation_date)`.
- Invariants: settlement line differs from source line (DB CHECK);
  amount non-negative (DB CHECK); over-allocation rejection, partial
  settlement arithmetic and reversal lifecycle are Phase 2 fixture logic
  operating on this table (no invented ledger policy here).
- Traceability: DB/DSS G0-SCH-003; FR-M06.

### G0-SCH-004 — Tax/HSN and layout profiles (gate G1; MPL 7.4 / OD-DB-003)

Tables: `tax_rate_hsn`, `layout_profile` (see `m005_sch004_tax_layout.sql`).

- `tax_rate_hsn(rate_id PK, company_id FK, hsn_code TEXT NOT NULL,
  rate_bps INTEGER NOT NULL CHECK >= 0, effective_from TEXT NOT NULL,
  effective_to TEXT NULL CHECK (effective_to IS NULL OR effective_to >=
  effective_from), record_version)`.
  Rates as INTEGER basis points (consistent with `discount_rate_bps`
  representation; no statutory rate values seeded — DSS-O03 rows wait for
  verified schemas, Phase 4/G3).
- `layout_profile(profile_id PK, company_id FK, profile_key TEXT NOT NULL,
  version INTEGER NOT NULL CHECK > 0, layout_json TEXT NOT NULL,
  updated_at INTEGER NOT NULL, synced_at INTEGER NULL,
  backup_manifest_id TEXT NULL, record_version,
  UNIQUE (company_id, profile_key, version))`.
  Sync/backup metadata columns are the G0-required lineage hooks; sync
  protocol behavior itself stays S1.
- Invariants: effective range sane (DB CHECK); profile version strictly
  positive and unique per key (DB constraints); no overlapping-range
  arbitration in schema (app/deterministic rule, Phase 2+ if required).
- Traceability: DB/DSS G0-SCH-004; OD-DB-003; FR-M16 (fields pending
  verification — table intentionally ships empty).

### G0-SCH-005 — Record/operation versioning (gate S1; SYNC 3/6)

(see `m006_sch005_versioning.sql`).

- `record_version INTEGER NOT NULL DEFAULT 1 CHECK (>= 1)` added (guarded by
  `PRAGMA table_info`) to: `item`, `voucher`, `voucher_line` (base tables)
  and every G0 table (layers, movements, locks, allocations, tax, layouts,
  anchors, denylist). `operation` and `audit_event` are append-only and
  excluded; `schema_migrations` excluded. Backfill: existing rows → 1.
- `operation.base_version INTEGER NOT NULL DEFAULT 1 CHECK (>= 1)`
  (the record version the operation was based on; SYNC §3 envelope).
- `operation_dependency(operation_op_id FK, depends_on_op_id FK,
  PRIMARY KEY (operation_op_id, depends_on_op_id))` — relational form of
  `operation.dependencies` (ordered replay / gap detection support, S1).
- `sync_conflict(conflict_id PK, company_id FK, entity TEXT NOT NULL,
  entity_id TEXT NOT NULL, losing_op_id FK, winning_op_id FK,
  base_version INTEGER NOT NULL, status TEXT NOT NULL DEFAULT 'open',
  resolution TEXT NULL, resolver TEXT NULL, resolved_at INTEGER NULL,
  created_at)` exactly per OD-DB-006 (status default `open` is the approved
  initial state of a queued conflict; resolution lifecycle is S1 app logic).
- Invariants: versions monotonic per record (app-enforced on write; schema
  guarantees presence + floor); `op_id` + device/seq uniqueness already in
  base (`UNIQUE (company_id, device_id, seq)`); duplicates never apply twice
  (DSS-C-004; runner + S1 replay logic).
- Traceability: DB/DSS G0-SCH-005; SYNC 3/6; OD-DB-006; G0-CON-004 (fields
  only — full conflict-policy implementation remains S1, outside this pack).

### G0-SCH-006 — Trial anchor and denylist (gate G0; SEC licence controls)

Tables: `trial_anchor`, `denylist_entry` (see `m007_sch006_trial_denylist.sql`).

- `trial_anchor(anchor_id PK, company_id FK UNIQUE, installed_at INTEGER NOT
  NULL, trial_ends_at INTEGER NOT NULL CHECK (trial_ends_at > installed_at),
  status TEXT NOT NULL, created_at, record_version)`.
  One anchor per company (UNIQUE); status/lifecycle transitions (trial →
  grace → licensed/read-only) are entitlement logic over this row
  (D-04/O-05/D-FG-014) — schema stores state, policy lives app-side.
- `denylist_entry(entry_id PK, key_hash TEXT NOT NULL UNIQUE,
  reason TEXT NOT NULL, revoked_at INTEGER NULL, status TEXT NOT NULL,
  audit_event_id NULL FK, created_at, record_version)`.
  Per OD-DB-004 sensitive fields are hash-only: the raw licence/key value is
  NEVER stored, only `key_hash`; revoke state + audit evidence columns are
  the approved lifecycle hooks.
- Invariants: one anchor per company (DB UNIQUE); key-hash uniqueness (DB
  UNIQUE); anchor window sane (DB CHECK); lifecycle evaluation (3-month
  trial, 10-day grace, reissue limit 20) is entitlement logic tested in
  Phase 3/G5, not schema CHECKs.
- Traceability: DB/DSS G0-SCH-006; SEC licence controls; D-04/O-05/D-FG-014,
  D-11/D-13/A-R2, D-14, D-FG-012, OD-DB-004.

### G0-SCH-007 — Voucher-line discount (gate G1; FRD voucher lines)

(see `m008_sch007_discount.sql`).

- `voucher_line.discount_amount_paise INTEGER NOT NULL DEFAULT 0
  CHECK (>= 0)`; `voucher_line.discount_rate_bps INTEGER NOT NULL DEFAULT 0
  CHECK (0..10000)`. Added via guarded `ADD COLUMN`; backfill 0 (no discount).
- Explicit calculation rule (implemented in `validators.dart`, tested):
  `gross = roundHalfUp(qty_q4 × rate_paise / 10⁴)` (D-M4);
  `discount = discount_amount_paise > 0 ? discount_amount_paise :
  roundHalfUp(gross × discount_rate_bps / 10000)`;
  `net = max(gross − discount, 0)`.
  Precedence (explicit amount wins over rate) is an implementation rule
  recorded here as PROPOSED for Phase 2 fixture confirmation; tax-base impact
  of discounts is Phase 2 scope. Invoice-level round-off stays a separate
  ledger line (D-M4) and is untouched by this delta.
- Invariants: both columns non-negative; rate ≤ 10000 bps (= 100%);
  net never negative (clamp); all arithmetic in integers, round-half-up only.
- Traceability: DB/DSS G0-SCH-007; FRD voucher lines; D-M4.

---

## 4. Determinism / idempotency / auditability

- Deterministic: fixed version order in `migration_registry.dart`; each file
  is content-stable; `applied_at` is evidence only, never logic.
- Idempotent: ledger-skip for applied versions; `IF NOT EXISTS` objects;
  `PRAGMA`-guarded `ADD COLUMN`; re-run of the full chain is a tested no-op.
- Auditable: `schema_migrations` rows (version, applied_at, description) are
  written in the same transaction as their DDL; design-to-file map is this
  document §2–§3; test evidence under `docs/g0/evidence/migrations/`.
- Recoverable: transaction-scoped migrations (failure = clean rollback, ledger
  unwritten); production recovery follows the approved uninstall / install /
  restore procedure — no DOWN migrations exist by design.

## 5. Change log

| Date | Change | Traceability |
|---|---|---|
| 2026-10-03 | Migration design + 8 versioned migration files + runner/validators + migration tests (this phase) | G0-SCH-001…007; DB/DSS v0.4; SYNC 3/6; SEC licence; D-M4/D-M5 |

## 6. Open / blocked items carried forward (not closed by Phase 1)

- SQLCipher-class library + licence + Android 8 evidence (G0-VER-001) and
  Keystore behavior (G0-VER-005): production encryption wiring stays BLOCKED;
  tests use disposable unencrypted SQLite.
- IRN/ack/e-way field list + official schemas (Phase 4/G3): tax tables ship
  empty by design.
- Discount amount-vs-rate precedence + tax-base impact: PROPOSED rule above,
  final confirmation via Phase 2 fixtures.
- Lifecycle enums (lock/allocation/conflict/licence statuses): stored as TEXT,
  transitions are app logic in later phases.
