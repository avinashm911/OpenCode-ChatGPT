// NiAvERP repository base — implementation Phase 01.
// Shared SQLite-error mapping and write helpers. All repositories work over
// the engine-neutral [MigrationDb], use `?` placeholders for every value,
// and return [Result]. Failure messages carry stable codes plus column/table
// context only — never key material or secrets.
// Traceability: DSS §6; DSS-C-004 (replay-safe op identity); OD-DB-004 (audit).

import 'package:niaverp/core/clock.dart';
import 'package:niaverp/core/result.dart';
import 'package:niaverp/data/migrations/migration_runner.dart';
import 'package:niaverp/data/security/trial_store.dart';

/// Maps a database engine exception to a stable [AppError].
AppError dbError(Object e, String op) {
  final String text = e.toString();
  // D2 integrity-guard rejections (m017 triggers) raise controlled,
  // value-free markers: they are rule breaches, not database failures.
  const List<String> guardMarkers = <String>[
    'audit-event-append-only',
    'operation-append-only',
    'voucher-posted-immutable',
    'voucher-line-posted-immutable',
    'voucher-status-vocab',
    'period-lock-status-vocab',
    'bill-allocation-status-vocab',
    'document-link-status-vocab',
    'movement-cost-source-vocab',
    'operation-action-vocab',
    'voucher-line-foreign-company',
    'party-ledger-foreign-company',
  ];
  for (final String marker in guardMarkers) {
    if (text.contains(marker)) {
      return AppError('validation', marker);
    }
  }
  if (text.contains('UNIQUE constraint failed')) {
    return const AppError('conflict', 'duplicate record (unique constraint)');
  }
  if (text.contains('FOREIGN KEY constraint failed')) {
    return const AppError('foreign-key', 'referenced parent row is missing');
  }
  if (text.contains('CHECK constraint failed')) {
    return const AppError('check', 'row violates a CHECK constraint');
  }
  return AppError('db', 'database failure during $op');
}

/// Next replay-safe sequence for (company, device) per DSS-C-004.
int nextOperationSeq(MigrationDb db, String companyId, String deviceId) {
  final List<Map<String, Object?>> rows = db.queryArgs(
    'SELECT MAX(seq) AS s FROM operation WHERE company_id = ? AND device_id = ?',
    <Object?>[companyId, deviceId],
  );
  final Object? s = rows.isEmpty ? null : rows.first['s'];
  return (s == null ? 0 : (s as int)) + 1;
}

/// Sentinel to abort a transaction when an inner step already produced a
/// mapped [AppError] (stored by the caller in a local). Carries no data so
/// failure messages can never leak values through the abort path.
class RepositoryAbort implements Exception {
  const RepositoryAbort();
}

/// Carries a mapped [AppError] out of a transaction body (the adapter rolls
/// back on any throw). Services compose multi-write pipelines with it so a
/// single failure aborts every effect atomically; it never escapes a public
/// method (mapped to [Result] at the boundary).
class TxFailure implements Exception {
  const TxFailure(this.error);
  final AppError error;
}

/// Current time source shared by repositories (inject a [TestClock] in tests).
class RepositoryContext {
  const RepositoryContext(
      {required this.db, required this.clock, this.gate, this.trialFiles});

  final MigrationDb db;
  final Clock clock;

  /// Write gate consulted by [recordLineage] before any material write.
  /// Null means allow-all: test scaffolding that builds its own context.
  /// Production always supplies the enforcing gate via
  /// `CompositionRoot.backend` (B1). Reads, audit appends and clock
  /// observations never consult the gate.
  final EntitlementGate? gate;

  /// App-private trial install-copy store (B1). Null in test scaffolding;
  /// production wires the real sandbox store so new companies inherit the
  /// installation's start even on the repository path. Read-only use: row
  /// creation never writes the file (runStartup owns first-launch creation).
  final TrialFileStore? trialFiles;
}

/// Write gate for material writes (B1, A5). Implemented by the trial service
/// (`TrialWriteGate`); the B4 permission hook rides the same gate.
abstract class EntitlementGate {
  const EntitlementGate();

  /// True when [companyId] currently has full function (trial or grace).
  bool canWrite(String companyId);
}
