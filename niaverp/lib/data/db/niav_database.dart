// NiAvERP production database abstraction — implementation Phase 01.
// Engine-neutral bootstrap over [MigrationDb]: clean install, ordered
// upgrade, repeat-safe re-run, and newer-schema refusal. The SQL text stays
// the audited G0 migration chain (MIGRATION_DESIGN.md §2); this class only
// orchestrates it. The production encrypted engine is owner-approved and
// wired in `cipher_opener.dart` (P-SQLIB, sqlite3 build hook source
// `sqlite3mc`); on-device proof is still G0-VER-005 evidence.
// [close] releases the native handle when the engine owns one and is
// idempotent: every later call is rejected instead of using a dead handle.
// Traceability: DSS §6; DB §8; DSS-C-007; RSP 5 / G0-CON-003; G0-SCH-001…007;
// P-SQLIB; D1 (resource lifecycle).

import '../migrations/migration_registry.dart';
import '../migrations/migration_runner.dart';
import '../../core/clock.dart';

/// Engines that own a native/database handle they can release. Implemented
/// by the production [FfiDatabase] and the test factory; the narrow shape
/// keeps [MigrationDb] free of lifecycle methods that a pure in-memory double
/// has no reason to implement.
abstract class CloseableMigrationDb {
  /// Release the handle. Implementations make this idempotent.
  void close();
}

/// Production database handle. Created by an engine opener (test factory,
/// FfiDatabase over the encrypted file in production) and bootstrapped before
/// use.
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

  /// Release the handle: marks this database closed AND releases the native
  /// handle when the engine owns one (production FFI, test factory). Calling
  /// it twice is safe; any database use afterwards is rejected instead of
  /// touching a released handle. The opener keeps nothing else to clean up.
  void close() {
    if (_closed) return;
    _closed = true;
    final Object engine = _engine;
    if (engine is CloseableMigrationDb) engine.close();
  }

  /// True once [close] has run (guards every operation).
  bool get isClosed => _closed;

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

/// Constructs the encrypted engine for production use. The library choice is
/// owner-approved (P-SQLIB: package:sqlite3 with build-hook source
/// `sqlite3mc`/SQLite3MultipleCiphers); on-device Android 8 proof stays
/// G0-VER-001/005 evidence. Implementations open the database with the
/// Keystore-wrapped [DbKey] (D-06) and hand the live connection to
/// [NiavDatabase]; they never fall back to plaintext.
abstract class EncryptedDatabaseOpener {
  /// Open (creating if needed) the per-company encrypted database and run
  /// [NiavDatabase.bootstrap] before returning it.
  NiavDatabase openCompanyDatabase();
}
