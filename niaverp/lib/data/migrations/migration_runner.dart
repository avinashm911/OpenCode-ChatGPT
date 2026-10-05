// NiAvERP G0 migration runner — Phase 1.
// Deterministic, idempotent, auditable application of the registry chain.
// Each migration runs inside one transaction together with its
// schema_migrations ledger row: failure rolls back DDL + ledger together.
// Rollback of a RELEASE follows only the approved procedure (uninstall,
// install previous APK, restore external backup); no DOWN migrations exist.
// Traceability: DSS §6 migration spec; DB §8; DSS-C-007; RSP 5 / G0-CON-003.

import 'migration_registry.dart';

/// Minimal database surface the runner needs. Implemented by the test
/// harness with package:sqlite3 and later by the Drift wiring over the same
/// SQL files. Kept interface-narrow so the audited SQL stays engine-neutral.
abstract class MigrationDb {
  /// Execute one DDL/DML statement (no result rows expected).
  void execute(String sql);

  /// Execute one DML statement with `?` positional arguments. Repositories
  /// must use this (never string-interpolated values) for all user- or
  /// app-supplied data. Added in implementation Phase 01.
  void executeArgs(String sql, List<Object?> args);

  /// Run a SELECT/PRAGMA and return rows as column-name maps.
  List<Map<String, Object?>> query(String sql);

  /// Parameterized SELECT for repository reads (`?` placeholders).
  List<Map<String, Object?>> queryArgs(String sql, List<Object?> args);

  /// Run [body] atomically; roll back and rethrow on error.
  void runInTransaction(void Function() body);
}

/// One parsed statement plus its optional ADD COLUMN idempotency guard.
class ParsedStatement {
  ParsedStatement(this.sql, this.guardTable, this.guardColumn);
  final String sql;
  final String? guardTable;
  final String? guardColumn;
}

/// Split migration SQL into statements. A line comment of the form
/// `-- __ADD_COLUMN__ <table> <column> ...` immediately before an ALTER
/// marks it for a PRAGMA table_info guard (old Android SQLite has no
/// `ADD COLUMN IF NOT EXISTS`).
List<ParsedStatement> parseMigrationSql(String text) {
  final List<ParsedStatement> out = <ParsedStatement>[];
  String? guardTable;
  String? guardColumn;
  final StringBuffer buf = StringBuffer();
  final RegExp guardRe = RegExp(r'--\s*__ADD_COLUMN__\s+(\S+)\s+(\S+)');
  for (final String rawLine in text.split('\n')) {
    final String line = rawLine.trim();
    if (line.startsWith('--')) {
      final RegExpMatch? m = guardRe.firstMatch(line);
      if (m != null) {
        guardTable = m.group(1);
        guardColumn = m.group(2);
      }
      continue;
    }
    if (line.isEmpty) continue;
    buf.write(rawLine);
    buf.write('\n');
    if (line.endsWith(';')) {
      out.add(ParsedStatement(buf.toString(), guardTable, guardColumn));
      buf.clear();
      guardTable = null;
      guardColumn = null;
    }
  }
  if (buf.toString().trim().isNotEmpty) {
    throw StateError('Unterminated statement in migration SQL: ${buf.toString()}');
  }
  return out;
}

const String _ledgerDdl = '''
CREATE TABLE IF NOT EXISTS schema_migrations (
  version      INTEGER PRIMARY KEY,
  applied_at   INTEGER NOT NULL,
  description  TEXT NOT NULL
)''';

/// Highest applied version recorded in the ledger (0 when empty/absent).
int currentVersion(MigrationDb db) {
  db.execute(_ledgerDdl);
  final List<Map<String, Object?>> rows =
      db.query('SELECT MAX(version) AS v FROM schema_migrations');
  final Object? v = rows.isEmpty ? null : rows.first['v'];
  if (v == null) return 0;
  return (v as int);
}

/// Apply every pending migration in registry order. Re-running is a no-op.
/// Throws on the first failing migration WITHOUT recording it (the wrapping
/// transaction rolls its DDL back), so the database is never half-versioned.
void migrate(
  MigrationDb db,
  Map<int, String> sqlByVersion, {
  int Function()? clockMs,

  /// Apply versions up to and including [upTo] (default: whole chain).
  /// Used by upgrade-path tests to stage a pre-G0 install first.
  int upTo = kLatestVersion,
}) {
  final int now = clockMs != null ? clockMs() : DateTime.now().millisecondsSinceEpoch;
  // Refuse gaps: registry order is the only legal order.
  int expected = currentVersion(db) + 1;
  for (final Migration m in kMigrations) {
    if (m.version > upTo) break;
    if (m.version < expected) continue; // already applied: ledger-skip
    if (m.version != expected) {
      throw StateError(
          'Migration order violation: expected v$expected, found v${m.version}');
    }
    final String? sql = sqlByVersion[m.version];
    if (sql == null) {
      throw StateError('Missing SQL for migration v${m.version}');
    }
    db.runInTransaction(() {
      for (final ParsedStatement st in parseMigrationSql(sql)) {
        if (st.guardTable != null && st.guardColumn != null) {
          final List<Map<String, Object?>> cols =
              db.query('PRAGMA table_info(${st.guardTable})');
          final bool exists = cols.any((Map<String, Object?> c) =>
              (c['name'] as String?) == st.guardColumn);
          if (exists) continue;
        }
        db.execute(st.sql);
      }
      final String safeDesc = m.description.replaceAll("'", "''");
      db.execute(
          "INSERT INTO schema_migrations (version, applied_at, description) "
          "VALUES (${m.version}, $now, '$safeDesc')");
    });
    expected = m.version + 1;
  }
}
