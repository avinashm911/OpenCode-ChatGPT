// NiAvERP dependency-injection composition root — Phase 00,
// extended with the production backend bundle (production DB boundary).
// Hand-rolled: Riverpod/go_router/PDF/Excel/barcode/ESC-POS remain UNVERIFIED
// candidates (PROJECT_BASELINE.md §6; PENDING_INPUTS.md) and must not be
// locked in until the owner confirms package + version + licence.
// The encrypted engine itself stays pending (P-SQLIB): production callers
// inject any [MigrationDb] engine (today the test engine; after the cipher
// decision, the SQLCipher/SQLite3MC engine via EncryptedDatabaseOpener) and
// the root builds the database, repositories and queries over it. Widgets
// never create services directly. Traceability: strategy Slice 0/1; AGENTS.md.

import '../application/queries/ledger.dart';
import '../application/queries/master_search.dart';
import '../application/queries/stock_levels.dart';
import '../application/services/document_flow.dart';
import '../application/services/numbering.dart';
import '../application/services/voucher_engine.dart';
import '../core/clock.dart';
import '../data/db/niav_database.dart';
import '../data/migrations/migration_runner.dart';
import '../data/repositories/alias_repository.dart';
import '../data/repositories/audit_log.dart';
import '../data/repositories/bill_allocation_repository.dart';
import '../data/repositories/company_repository.dart';
import '../data/repositories/document_link_repository.dart';
import '../data/repositories/financial_year_repository.dart';
import '../data/repositories/item_repository.dart';
import '../data/repositories/layout_profile_repository.dart';
import '../data/repositories/ledger_masters.dart';
import '../data/repositories/operation_log.dart';
import '../data/repositories/party_repository.dart';
import '../data/repositories/repository.dart';
import '../data/repositories/unit_group_repository.dart';
import '../data/repositories/voucher_repository.dart';
import '../data/repositories/voucher_type_repository.dart';

/// Static application configuration (no secrets, no business state).
class AppConfig {
  const AppConfig({this.appTitle = 'NiAvERP'});

  final String appTitle;
}

/// Composition root owned by `main()` and shared by the widget tree.
class CompositionRoot {
  const CompositionRoot({required this.config, required this.clock});

  final AppConfig config;
  final Clock clock;

  /// Production wiring.
  factory CompositionRoot.system({AppConfig config = const AppConfig()}) {
    return CompositionRoot(config: config, clock: const SystemClock());
  }

  /// Test wiring with a deterministic clock.
  factory CompositionRoot.forTest({
    AppConfig config = const AppConfig(),
    int fixedMs = 0,
  }) {
    return CompositionRoot(config: config, clock: TestClock(fixedMs));
  }

  /// Production backend over an injected [engine].
  ///
  /// The engine is supplied by the opener: test harness today, the
  /// Keystore-wrapped encrypted engine after P-SQLIB closes. The root
  /// bootstraps migrations ([sqlByVersion] loaded via migration_assets),
  /// then builds the repository/query graph. Throws exactly as
  /// [NiavDatabase.bootstrap] does on a newer-schema database.
  static BackendBundle backend({
    required MigrationDb engine,
    required Map<int, String> sqlByVersion,
    required Clock clock,
  }) {
    final NiavDatabase database = NiavDatabase(engine, clock: clock)
      ..sqlByVersion = sqlByVersion
      ..bootstrap();
    final RepositoryContext ctx = RepositoryContext(db: database, clock: clock);
    final OperationLog ops = OperationLog(ctx);
    final AuditLog audit = AuditLog(ctx);
    final VoucherRepository voucherRepo =
        VoucherRepository(ctx, ops: ops, audit: audit);
    final VoucherTypeRepository typeRepo =
        VoucherTypeRepository(ctx, ops: ops, audit: audit);
    final DocumentLinkRepository linkRepo =
        DocumentLinkRepository(ctx, ops: ops, audit: audit);
    final BillAllocationRepository allocationRepo =
        BillAllocationRepository(ctx, ops: ops, audit: audit);
    return BackendBundle(
      database: database,
      ops: ops,
      audit: audit,
      companies: CompanyRepository(ctx, ops: ops, audit: audit),
      fyYears: FinancialYearRepository(ctx, ops: ops, audit: audit),
      accountGroups:
          AccountGroupRepository(ctx, ops: ops, audit: audit),
      ledgers: LedgerRepository(ctx, ops: ops, audit: audit),
      allocations: allocationRepo,
      parties: PartyRepository(ctx, ops: ops, audit: audit),
      items: ItemRepository(ctx, ops: ops, audit: audit),
      units: UnitRepository(ctx, ops: ops, audit: audit),
      groups: ItemGroupRepository(ctx, ops: ops, audit: audit),
      types: typeRepo,
      godowns: GodownRepository(ctx, ops: ops, audit: audit),
      aliases: AliasRepository(ctx, ops: ops, audit: audit),
      vouchers: voucherRepo,
      layoutProfiles: LayoutProfileRepository(ctx, ops: ops, audit: audit),
      links: linkRepo,
      search: MasterSearch(database),
      stock: StockLevels(database),
      books: LedgerBooks(database),
      numbering: SeriesNumbering(database),
      engine: VoucherEngine(
        ctx,
        ops: ops,
        audit: audit,
        vouchers: voucherRepo,
        types: typeRepo,
        allocationRepo: allocationRepo,
      ),
      flow: DocumentFlow(
        ctx,
        ops: ops,
        audit: audit,
        vouchers: voucherRepo,
        links: linkRepo,
      ),
    );
  }
}

/// The wired production backend: one bootstrapped database, one repository
/// graph, one query set. Owned by `main()` after the engine exists.
class BackendBundle {
  const BackendBundle({
    required this.database,
    required this.ops,
    required this.audit,
    required this.companies,
    required this.fyYears,
    required this.accountGroups,
    required this.ledgers,
    required this.allocations,
    required this.parties,
    required this.items,
    required this.units,
    required this.groups,
    required this.types,
    required this.godowns,
    required this.aliases,
    required this.vouchers,
    required this.layoutProfiles,
    required this.links,
    required this.search,
    required this.stock,
    required this.books,
    required this.numbering,
    required this.engine,
    required this.flow,
  });

  final NiavDatabase database;
  final OperationLog ops;
  final AuditLog audit;
  final CompanyRepository companies;
  final FinancialYearRepository fyYears;
  final AccountGroupRepository accountGroups;
  final LedgerRepository ledgers;
  final BillAllocationRepository allocations;
  final PartyRepository parties;
  final ItemRepository items;
  final UnitRepository units;
  final ItemGroupRepository groups;
  final VoucherTypeRepository types;
  final GodownRepository godowns;
  final AliasRepository aliases;
  final VoucherRepository vouchers;
  final LayoutProfileRepository layoutProfiles;
  final DocumentLinkRepository links;
  final MasterSearch search;
  final StockLevels stock;
  final LedgerBooks books;
  final SeriesNumbering numbering;
  final VoucherEngine engine;
  final DocumentFlow flow;
}
