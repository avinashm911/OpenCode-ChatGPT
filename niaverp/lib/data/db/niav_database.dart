// NiAvERP production database abstraction — implementation Phase 01.
// Engine-neutral bootstrap over [MigrationDb]: clean install, ordered
// upgrade, repeat-safe re-run, and newer-schema refusal. The SQL text stays
// the audited G0 migration chain (MIGRATION_DESIGN.md §2); this class only
// orchestrates it. Encrypted-engine construction stays BLOCKED on P-SQLIB
// (G0-VER-001); see [EncryptedDatabaseOpener].
// Traceability: DSS §6; DB §8; DSS-C-007; RSP 5 / G0-CON-003; G0-SCH-001…007.

import '../migrations/migration_registry.dart';
import '../migrations/migration_runner.dart';
import '../../core/clock.dart';

/// Production database handle. Created by an engine opener (test factory,
///
/// Drift/SQLCipher wiring once P-SQLIB closes) and bootstrapped before use.
class NiavDatabase implements MigrationDb {
  NiavDatabase(this._engine, {required this._clock});

  final MigrationDb _engine;
  final Clock _clock;
  bool _closed = false;

  /// The wrapped engine (test factories cast this to their adapter).
  MigrationDb get engine => _engine;

  /// SQL text per migration version, loaded once by the opener from the
  /// audited `lib/data/migrations/*.sql` files.
  Map<int, String> sqlByVersion = <int, String>{};

  void _guardOpen() {
    if (_closed) {
      throw StateError('NiavDatabase is closed');
    }
  }

  /// Bootstrap: enforce FK semantics on the connection, refuse a
  /// newer-schema database (downgrade refusal, DSS-C-007 / G0-CON-003), then
  /// apply pending migrations idempotently.
  void bootstrap() {
    _guardOpen();
    _engine.execute('PRAGMA foreign_keys = ON');
    final int at = currentVersion(_engine);
    if (at > kLatestVersion) {
      throw StateError(
        'schema v$at is newer than app v$kLatestVersion: '
        'restore refused (no in-place downgrade)',
      );
    }
    migrate(_engine, sqlByVersion, clockMs: _clock.nowMs);
  }

  /// Highest applied schema version (0 on a fresh database).
  int get schemaVersion {
    _guardOpen();
    return currentVersion(_engine);
  }

  /// Release the underlying connection. The opener owns native cleanup.
  void close() {
    _closed = true;
  }

  @override
  void execute(String sql) {
    _guardOpen();
    _engine.execute(sql);
  }

  @override
  void executeArgs(String sql, List<Object?> args) {
    _guardOpen();
    _engine.executeArgs(sql, args);
  }

  @override
  List<Map<String, Object?>> query(String sql) {
    _guardOpen();
    return _engine.query(sql);
  }

  @override
  List<Map<String, Object?>> queryArgs(String sql, List<Object?> args) {
    _guardOpen();
    return _engine.queryArgs(sql, args);
  }

  @override
  void runInTransaction(void Function() body) {
    _guardOpen();
    _engine.runInTransaction(body);
  }
}

/// Constructs the encrypted engine for production use. No implementation
/// exists until P-SQLIB closes (confirmed SQLCipher-class library, version,
/// licence, Android 8 proof). Implementations must open the database with
/// the Keystore-wrapped [DbKey] (D-06) and hand the live connection to
/// [NiavDatabase]; they must never fall back to plaintext.
abstract class EncryptedDatabaseOpener {
  /// Open (creating if needed) the per-company encrypted database and run
  /// [NiavDatabase.bootstrap] before returning it.
  NiavDatabase openCompanyDatabase();
}
