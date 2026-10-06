// Deterministic test database factory — dev-only test helper.
// Disposable in-memory SQLite via package:sqlite3 (dev_dependency). Never
// production data, never shipped: production opens through
// CipherDatabaseOpener (P-SQLIB owner-approved 2026-10-05). Foreign keys are
// enforced so repository tests run with real SQLite semantics.
// Traceability: strategy Slice 1; P-SQLIB (device/prod proof pending).

import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import 'package:niaverp/core/clock.dart';
import 'package:niaverp/data/db/niav_database.dart';
import 'package:niaverp/data/migrations/migration_registry.dart';
import 'package:niaverp/data/migrations/migration_runner.dart';
import 'package:niaverp/data/repositories/repository.dart';

/// MigrationDb over one disposable in-memory database.
///
/// Implements [CloseableMigrationDb] so close-cascading through
/// [NiavDatabase] (D1-B4) is exercised by tests exactly as production
/// FfiDatabase engines behave.
class TestDatabase implements MigrationDb, CloseableMigrationDb {
  TestDatabase._(this.raw);

  /// Wrap an already-opened database (e.g. a temp-file database for
  /// persistence-reload tests). The caller owns closing.
  factory TestDatabase.open(Database raw) => TestDatabase._(raw);

  final Database raw;
  bool _closed = false;

  @override
  void execute(String sql) => raw.execute(sql);

  @override
  void executeArgs(String sql, List<Object?> args) =>
      raw.execute(sql, args);

  @override
  List<Map<String, Object?>> query(String sql) =>
      queryArgs(sql, <Object?>[]);

  @override
  List<Map<String, Object?>> queryArgs(String sql, List<Object?> args) {
    final ResultSet rs = raw.select(sql, args);
    return <Map<String, Object?>>[
      for (final Row row in rs)
        <String, Object?>{for (final String c in rs.columnNames) c: row[c]},
    ];
  }

  @override
  void runInTransaction(void Function() body) {
    raw.execute('BEGIN');
    try {
      body();
      raw.execute('COMMIT');
    } catch (_) {
      raw.execute('ROLLBACK');
      rethrow;
    }
  }

  @override
  void close() {
    if (!_closed) {
      _closed = true;
      raw.close();
    }
  }
}

Map<int, String> loadMigrationSql() {
  final Map<int, String> out = <int, String>{};
  for (final Migration m in kMigrations) {
    out[m.version] =
        File('lib/data/migrations/${m.fileName}').readAsStringSync();
  }
  return out;
}

/// Open a fresh in-memory database bootstrapped to [upTo] with a fixed clock
/// ([fixedMs]) so ledger timestamps are deterministic. The caller owns
/// closing via [TestDatabase.close] (use tearDown).
NiavDatabase openTestDatabase({int upTo = kLatestVersion, int fixedMs = 1700000000000}) {
  final TestDatabase engine = TestDatabase._(sqlite3.openInMemory());
  final NiavDatabase db =
      NiavDatabase(engine, clock: TestClock(fixedMs));
  db.sqlByVersion = loadMigrationSql();
  if (upTo == kLatestVersion) {
    db.bootstrap();
  } else {
    engine.execute('PRAGMA foreign_keys = ON');
    migrate(engine, db.sqlByVersion,
        clockMs: () => fixedMs, upTo: upTo);
  }
  return db;
}

/// The raw engine behind a bootstrapped [NiavDatabase] for direct asserts.
TestDatabase rawEngineOf(NiavDatabase db) => db.engine as TestDatabase;

/// Deterministic context (fixed clock) over a fresh migrated database.
RepositoryContext testContext(NiavDatabase db, {int fixedMs = 1700000000000}) {
  return RepositoryContext(db: db, clock: TestClock(fixedMs));
}

/// Fixed clock for tests that build their own context.
TestClock testClock({int fixedMs = 1700000000000}) => TestClock(fixedMs);
