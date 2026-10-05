// m013 migration tests: ledger masters (gate G1).
// Disposable databases only. Proves: account_group + ledger tables exist
// at v13, staged v12→v13 upgrade preserves rows, UNIQUEs collide per
// company, value CHECKs are enforced, and re-bootstrap is repeat-safe.
// Traceability: DB §3 (account_group, ledger); FR-M03-002; DSS-C-007.

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/data/db/niav_database.dart';
import 'package:niaverp/data/migrations/migration_runner.dart';

import '../helpers/test_database.dart';

void main() {
  late NiavDatabase db;

  List<String> columns(MigrationDb db, String table) {
    final List<Map<String, Object?>> rows =
        db.query('PRAGMA table_info($table)');
    return <String>[for (final Map<String, Object?> r in rows) r['name'] as String];
  }

  group('m013 ledger masters', () {
    test('tables and key columns exist at v13', () {
      db = openTestDatabase();
      addTearDown(() => rawEngineOf(db).close());
      expect(db.schemaVersion, 15);
      for (final String t in <String>['account_group', 'ledger']) {
        final List<Map<String, Object?>> rows = db.query(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = '$t'",
        );
        expect(rows, hasLength(1), reason: t);
      }
      expect(columns(db, 'ledger'),
          containsAll(<String>['opening_side', 'opening_paise', 'billwise']));
    });

    test('staged v12→v13 upgrade preserves rows; constraints enforced', () {
      final NiavDatabase v12 = openTestDatabase(upTo: 12);
      v12.executeArgs(
        'INSERT INTO company (company_id, name, created_at) VALUES (?, ?, ?)',
        <Object?>['c-u', 'Upgrade Co', 1700000000000],
      );
      final NiavDatabase v13 =
          NiavDatabase(rawEngineOf(v12), clock: testClock());
      v13.sqlByVersion = loadMigrationSql();
      v13.bootstrap();
      addTearDown(() => rawEngineOf(v13).close());
      expect(v13.schemaVersion, 15);
      v13.executeArgs(
        'INSERT INTO account_group (group_id, company_id, name, created_at) '
        'VALUES (?, ?, ?, ?)',
        <Object?>['g-u', 'c-u', 'Assets', 1700000000000],
      );
      expect(
        v13
            .queryArgs(
              'SELECT name FROM account_group WHERE group_id = ?',
              <Object?>['g-u'],
            )
            .single['name'],
        'Assets',
      );
      // Duplicate ledger names collide per company.
      v13.executeArgs(
        'INSERT INTO ledger (ledger_id, company_id, group_id, name, '
        'created_at) VALUES (?, ?, ?, ?, ?)',
        <Object?>['l-1', 'c-u', 'g-u', 'Cash', 1700000000000],
      );
      expect(
        () => v13.executeArgs(
          'INSERT INTO ledger (ledger_id, company_id, group_id, name, '
          'created_at) VALUES (?, ?, ?, ?, ?)',
          <Object?>['l-2', 'c-u', 'g-u', 'Cash', 1700000000000],
        ),
        throwsException,
      );
      // Bad opening side and negative opening refused.
      expect(
        () => v13.executeArgs(
          'INSERT INTO ledger (ledger_id, company_id, group_id, name, '
          'opening_side, created_at) VALUES (?, ?, ?, ?, ?, ?)',
          <Object?>['l-3', 'c-u', 'g-u', 'Bad', 'Dx', 1700000000000],
        ),
        throwsException,
      );
      expect(
        () => v13.executeArgs(
          'INSERT INTO ledger (ledger_id, company_id, group_id, name, '
          'opening_paise, created_at) VALUES (?, ?, ?, ?, ?, ?)',
          <Object?>['l-4', 'c-u', 'g-u', 'Neg', -5, 1700000000000],
        ),
        throwsException,
      );
      final NiavDatabase again =
          NiavDatabase(rawEngineOf(v13), clock: testClock());
      again.sqlByVersion = loadMigrationSql();
      again.bootstrap();
      expect(again.schemaVersion, 15);
    });
  });
}
