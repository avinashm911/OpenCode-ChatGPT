// Production FFI database engine — production DB boundary.
// [FfiDatabase] is the production [MigrationDb]: package:sqlite3 over a
// real database (file or in-memory), with parameterized statements for every
// value and atomic transactions. It is engine-agnostic: against a
// SQLite3MultipleCiphers build it carries encrypted bytes (opened only
// through [CipherDatabaseOpener], which keys it and proves the cipher);
// against a plain build it is plaintext — which is why production NEVER
// constructs this class directly. Failure messages carry no key material.
// Traceability: P-SQLIB; DSS-C-007; D-06 (no plaintext fallback).

import 'package:sqlite3/sqlite3.dart';

import '../migrations/migration_runner.dart';
import 'niav_database.dart';

/// Production [MigrationDb] over one sqlite3 database handle.
class FfiDatabase implements MigrationDb, CloseableMigrationDb {
  FfiDatabase._(this._raw);

  /// Wrap an already-open handle (opener owns keying + cipher proof).
  factory FfiDatabase.wrap(Database raw) => FfiDatabase._(raw);

  final Database _raw;
  bool _closed = false;

  void _guardOpen() {
    if (_closed) throw StateError('FfiDatabase is closed');
  }

  @override
  void execute(String sql) {
    _guardOpen();
    _raw.execute(sql);
  }

  @override
  void executeArgs(String sql, List<Object?> args) {
    _guardOpen();
    _raw.execute(sql, args);
  }

  @override
  List<Map<String, Object?>> query(String sql) =>
      queryArgs(sql, <Object?>[]);

  @override
  List<Map<String, Object?>> queryArgs(String sql, List<Object?> args) {
    _guardOpen();
    final ResultSet rs = _raw.select(sql, args);
    return <Map<String, Object?>>[
      for (final Row row in rs)
        <String, Object?>{for (final String c in rs.columnNames) c: row[c]},
    ];
  }

  @override
  void runInTransaction(void Function() body) {
    _guardOpen();
    _raw.execute('BEGIN');
    try {
      body();
      _raw.execute('COMMIT');
    } catch (error) {
      // The rollback is best-effort: a failing statement may already have
      // rolled the transaction back (SQLite rolls back on some constraint
      // failures), and a ROLLBACK then throws "no transaction is active".
      // That second failure must never replace [error] — the caller's cause is
      // the one that matters, so it is rethrown untouched and the rollback
      // failure is attached to nothing (never logged, never a new message).
      try {
        _raw.execute('ROLLBACK');
      } catch (_) {
        // Already rolled back (or rolled back automatically): keep the cause.
      }
      rethrow;
    }
  }

  /// Release the native handle. Idempotent; every operation afterwards is
  /// rejected by the guard.
  @override
  void close() {
    if (!_closed) {
      _closed = true;
      _raw.close();
    }
  }
}
