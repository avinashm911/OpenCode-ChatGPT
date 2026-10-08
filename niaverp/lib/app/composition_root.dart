// NiAvERP dependency-injection composition root — Phase 00,
// extended with the production backend bundle (production DB boundary).
// Hand-rolled: Riverpod/go_router/PDF/Excel/barcode/ESC-POS remain UNVERIFIED
// candidates (PROJECT_BASELINE.md §6; PENDING_INPUTS.md) and must not be
// locked in until the owner confirms package + version + licence.
// The encrypted engine is owner-approved (P-SQLIB, 2026-10-05: package:sqlite3
// with build-hook source `sqlite3mc`): production callers inject any
// inject any [MigrationDb] engine (today the test engine; after the cipher
// decision, the SQLCipher/SQLite3MC engine via EncryptedDatabaseOpener) and
// the root builds the database, repositories and queries over it. Widgets
// never create services directly. Traceability: strategy Slice 0/1; AGENTS.md.

import '../application/queries/ledger.dart';
import '../application/queries/master_search.dart';
import '../application/queries/outstanding.dart';
import '../application/queries/stock_levels.dart';
import '../application/services/document_flow.dart';
import '../application/services/numbering.dart';
import '../application/services/voucher_engine.dart';
import '../core/clock.dart';
import '../core/result.dart';
import '../core/value_objects/niav_date.dart';
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
import '../data/repositories/period_lock.dart';
import '../data/repositories/repository.dart';
import '../data/security/entitlements.dart';
import '../data/security/trial_service.dart';
import '../data/security/trial_store.dart';
import '../data/repositories/unit_group_repository.dart';
import '../data/repositories/voucher_repository.dart';
import '../data/repositories/voucher_type_repository.dart';
import '../presentation/shared/company_scope.dart';
import '../presentation/shared/screen_wiring.dart';

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
  /// The engine is supplied by the opener: the test harness in host runs, the
  /// Keystore-wrapped encrypted engine in production. The root bootstraps
  /// migrations ([sqlByVersion] loaded via migration_assets), then builds the
  /// repository/query graph. Throws exactly as [NiavDatabase.bootstrap] does
  /// on a newer-schema database — and closes the handle first, so a failed
  /// bootstrap never leaves a live connection behind (D1-B4).
  static BackendBundle backend({
    required MigrationDb engine,
    required Map<int, String> sqlByVersion,
    required Clock clock,

    /// Platform device identity for the denylist check. Null only in test
    /// scaffolding (denylist unchecked — documented gap; production always
    /// supplies it via runStartup).
    String? deviceId,

    /// App-private install-copy store. Null in tests (database anchors
    /// alone govern); production supplies the real sandbox store.
    TrialFileStore? trialFiles,
  }) {
    final NiavDatabase database = NiavDatabase(engine, clock: clock)
      ..sqlByVersion = sqlByVersion;
    try {
      database.bootstrap();
    } catch (_) {
      // Newer-schema refusal (G0-CON-003), missing SQL or a failing migration:
      // release the native handle before the error propagates. Closing is
      // idempotent and never masks the original failure.
      database.close();
      rethrow;
    }
    // B1 trial service + single write choke point (A5). Every material write
    // funnels through recordLineage, which consults this gate. Reads, audit
    // appends, clock observations and anchor bootstrapping stay ungated.
    final TrialService trial = TrialService(
      db: database,
      clock: clock,
      files: trialFiles,
      deviceId: deviceId,
    );
    final RepositoryContext ctx = RepositoryContext(
      db: database,
      clock: clock,
      gate: TrialWriteGate(trial),
      trialFiles: trialFiles,
    );
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
    final BankAccountRepository bankRepo =
        BankAccountRepository(ctx, ops: ops, audit: audit);
    return BackendBundle(
      database: database,
      ops: ops,
      audit: audit,
      companies: CompanyRepository(ctx, ops: ops, audit: audit),
      fyYears: FinancialYearRepository(ctx, ops: ops, audit: audit),
      accountGroups:
          AccountGroupRepository(ctx, ops: ops, audit: audit),
      ledgers: LedgerRepository(ctx, ops: ops, audit: audit),
      banks: bankRepo,
      allocations: allocationRepo,
      periodLocks:
          PeriodLockRepository(ctx, ops: ops, audit: audit),
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
      outstanding: OutstandingReport(database),
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
      trial: trial,
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
    required this.banks,
    required this.allocations,
    required this.periodLocks,
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
    required this.outstanding,
    required this.numbering,
    required this.engine,
    required this.flow,
    required this.trial,
  });

  final NiavDatabase database;
  final OperationLog ops;
  final AuditLog audit;
  final CompanyRepository companies;
  final FinancialYearRepository fyYears;
  final AccountGroupRepository accountGroups;
  final LedgerRepository ledgers;
  final BankAccountRepository banks;
  final BillAllocationRepository allocations;
  final PeriodLockRepository periodLocks;
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
  final OutstandingReport outstanding;
  final SeriesNumbering numbering;
  final VoucherEngine engine;
  final DocumentFlow flow;

  /// Trial/clock/entitlement service (B1: M20.1/M20.2/M20.6, M22.4).
  final TrialService trial;

  /// Entitlement state of one company at the service clock (A4).
  EntitlementState entitlementState(String companyId) =>
      trial.evaluate(companyId, trial.clock.nowMs()).state;

  /// Whole days left with full function; zero when expired/denied (A4).
  int daysLeft(String companyId) {
    final TrialEvaluation e = trial.evaluate(companyId, trial.clock.nowMs());
    return trialDaysLeft(e.state, e.effectiveEndsAtMs, e.trustedNowMs);
  }

  /// Daily expiry reminder is due only during grace (A4).
  bool reminderDue(String companyId) =>
      needsExpiryReminder(entitlementState(companyId));

  /// True when the latest clock observation for [companyId] reported a
  /// rollback (A4). Rollback never blocks writes; the warning surfaces here.
  bool clockWarning(String companyId) => trial.clockWarning(companyId);

  /// Export + backup stay allowed in every non-denied state (D-04).
  /// Reads never consult the write gate; this documents the guarantee.
  bool exportBackupAllowed(String companyId) =>
      canExportBackup(entitlementState(companyId));

  /// Clock guard for company open/switch (A3). Observes the device clock,
  /// keeps the observation on the facade, audits rollbacks. The shell calls
  /// this from `openCompany` (see UI_HANDOFF_B1.md); startup calls it per
  /// company after the backend is built.
  Result<ClockObservation> guardCompanyOpen({
    required String companyId,
    required int deviceNowMs,
    required String actor,
    required String eventId,
  }) =>
      trial.observeAndGuard(
        companyId: companyId,
        deviceNowMs: deviceNowMs,
        actor: actor,
        eventId: eventId,
        ops: ops,
        audit: audit,
      );
}

/// Map a wired backend to the tab scope: the repositories/queries the five
/// destinations need, plus the caller-supplied write identity and report
/// date. Pure mapping — no business logic.
CompanyScope scopeOfBackend(
  BackendBundle backend, {
  required WriteContext write,
  required NiavDate today,
}) {
  return CompanyScope(
    companies: backend.companies,
    parties: backend.parties,
    items: backend.items,
    aliases: backend.aliases,
    search: backend.search,
    godowns: backend.godowns,
    stock: backend.stock,
    books: backend.books,
    ledgers: backend.ledgers,
    outstanding: backend.outstanding,
    vouchers: backend.vouchers,
    types: backend.types,
    numbering: backend.numbering,
    engine: backend.engine,
    write: write,
    today: today,
    layouts: backend.layoutProfiles,
    fyYears: backend.fyYears,
    periodLocks: backend.periodLocks,
  );
}
