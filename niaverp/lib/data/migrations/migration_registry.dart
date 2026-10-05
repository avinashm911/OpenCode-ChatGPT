// NiAvERP G0 migration registry — Phase 1.
// Fixed, ordered list of approved schema versions. Order is part of the
// design (docs/g0/MIGRATION_DESIGN.md §2); the runner refuses out-of-order
// application. Traceability: G0-SCH-001…007; DB/DSS v0.4.

/// One approved schema version.
class Migration {
  const Migration({
    required this.version,
    required this.g0Id,
    required this.description,
    required this.fileName,
  });

  /// Sequential schema version (1-based). Never reused, never reordered.
  final int version;

  /// G0 design ID, or 'baseline' for the pre-G0 migration baseline.
  final String g0Id;

  /// Human-readable change description (also written to schema_migrations).
  final String description;

  /// SQL file under lib/data/migrations/.
  final String fileName;
}

/// Authoritative migration chain. Latest version is [kLatestVersion].
const List<Migration> kMigrations = <Migration>[
  Migration(
    version: 1,
    g0Id: 'baseline',
    description: 'Pre-G0 baseline: ledger + minimal parents (company, item, '
        'godown, voucher, voucher_line, operation, audit_event)',
    fileName: 'm001_base.sql',
  ),
  Migration(
    version: 2,
    g0Id: 'G0-SCH-001',
    description: 'Cost layers and stock movements (FIFO/weighted-average, '
        'negative-stock fallback, reconciliation)',
    fileName: 'm002_sch001_cost_layers.sql',
  ),
  Migration(
    version: 3,
    g0Id: 'G0-SCH-002',
    description: 'Period lock (range, scope, status, unlock actor/reason, audit)',
    fileName: 'm003_sch002_period_lock.sql',
  ),
  Migration(
    version: 4,
    g0Id: 'G0-SCH-003',
    description: 'Bill allocation (source/settlement lineage, amount, operation)',
    fileName: 'm004_sch003_bill_allocation.sql',
  ),
  Migration(
    version: 5,
    g0Id: 'G0-SCH-004',
    description: 'Effective-dated tax/HSN + versioned layout profiles',
    fileName: 'm005_sch004_tax_layout.sql',
  ),
  Migration(
    version: 6,
    g0Id: 'G0-SCH-005',
    description: 'Record versioning + operation.base_version/dependencies + '
        'sync_conflict (S1 fields only)',
    fileName: 'm006_sch005_versioning.sql',
  ),
  Migration(
    version: 7,
    g0Id: 'G0-SCH-006',
    description: 'Trial anchor + denylist storage (lifecycle, revoke, audit)',
    fileName: 'm007_sch006_trial_denylist.sql',
  ),
  Migration(
    version: 8,
    g0Id: 'G0-SCH-007',
    description: 'Voucher-line discount fields (amount paise + rate bps)',
    fileName: 'm008_sch007_discount.sql',
  ),
  Migration(
    version: 9,
    g0Id: 'M03',
    description: 'M03 masters: party/address, unit, item group, voucher '
        'type/series, search aliases; item M03.8 nullable columns',
    fileName: 'm009_m03_masters.sql',
  ),
  Migration(
    version: 10,
    g0Id: 'DSS-TXN',
    description: 'DSS transaction enrichment: voucher narration/actor/device; '
        'voucher_line ledger/party/godown/batch refs; document_link lineage',
    fileName: 'm010_dss_txn_refs.sql',
  ),
  Migration(
    version: 11,
    g0Id: 'DSS-TXN',
    description: 'DSS financial year + Dr/Cr convention: financial_year '
        'table; voucher fy_id; voucher_line dr_cr with value check',
    fileName: 'm011_dss_fy_drcr.sql',
  ),
  Migration(
    version: 12,
    g0Id: 'M04',
    description: 'Series numbering mode: voucher_series auto/manual mode '
        'with value check (manual default)',
    fileName: 'm012_series_mode.sql',
  ),
  Migration(
    version: 13,
    g0Id: 'M04',
    description: 'Ledger masters: account_group tree and ledger identity, '
        'opening side/value and bill-wise flag (balances derived by query)',
    fileName: 'm013_ledger_masters.sql',
  ),
];

/// Highest approved schema version.
const int kLatestVersion = 13;
