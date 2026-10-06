// m014 migration tests: ledger detail + bank masters (gate G1).
// Disposable databases only. Proves: bank_account table + ledger detail
// columns exist at latest (v17), staged v13 upgrade to latest preserves
// ledger rows,
// UNIQUE (company, ledger) collides, credit CHECKs are enforced, and
// re-bootstrap is repeat-safe.
// Traceability: DB §3 (ledger, bank_account); FR-M03-002/004; DSS-C-007.

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

  group('m014 ledger detail + bank', () {
    test('columns and bank table exist at latest', () {
      db = openTestDatabase();
      addTearDown(() => rawEngineOf(db).close());
      expect(db.schemaVersion, 17); // registry ends at v17 (m017, D2)
      expect(
        columns(db, 'ledger'),
        containsAll(<String>[
          'credit_limit_paise',
          'credit_days',
          'contact',
          'address',
          'bank_details',
        ]),
      );
      final List<Map<String, Object?>> tables = db.query(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'bank_account'",
      );
      expect(tables, hasLength(1));
      expect(
        columns(db, 'bank_account'),
        containsAll(<String>[
          'bank_account_id',
          'company_id',
          'ledger_id',
          'account_no',
          'ifsc',
          'upi_id',
        ]),
      );
    });

    test('staged v13 upgrade to latest preserves rows; constraints enforced', () {
      final NiavDatabase v13 = openTestDatabase(upTo: 13);
      v13.executeArgs(
        'INSERT INTO company (company_id, name, created_at) VALUES (?, ?, ?)',
        <Object?>['c-u', 'Upgrade Co', 1700000000000],
      );
      v13.executeArgs(
        'INSERT INTO account_group (group_id, company_id, name, created_at) '
        'VALUES (?, ?, ?, ?)',
        <Object?>['g-u', 'c-u', 'Bank', 1700000000000],
      );
      v13.executeArgs(
        'INSERT INTO ledger (ledger_id, company_id, group_id, name, '
        'opening_side, opening_paise, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
        <Object?>['l-u', 'c-u', 'g-u', 'Cash', 'Dr', 1000, 1700000000000],
      );
      final NiavDatabase v14 =
          NiavDatabase(rawEngineOf(v13), clock: testClock());
      v14.sqlByVersion = loadMigrationSql();
      v14.bootstrap();
      addTearDown(() => rawEngineOf(v14).close());
      expect(v14.schemaVersion, 17); // staged v13, then full bootstrap to latest v17
      expect(
        v14
            .queryArgs(
              'SELECT name, opening_paise, credit_limit_paise FROM ledger '
              'WHERE ledger_id = ?',
              <Object?>['l-u'],
            )
            .single,
        containsPair('name', 'Cash'),
      );
      // One bank row per ledger per company.
      v14.executeArgs(
        'INSERT INTO bank_account (bank_account_id, company_id, ledger_id, '
        'account_no, created_at) VALUES (?, ?, ?, ?, ?)',
        <Object?>['b-1', 'c-u', 'l-u', '123', 1700000000000],
      );
      expect(
        () => v14.executeArgs(
          'INSERT INTO bank_account (bank_account_id, company_id, ledger_id, '
          'created_at) VALUES (?, ?, ?, ?)',
          <Object?>['b-2', 'c-u', 'l-u', 1700000000000],
        ),
        throwsException,
      );
      // Negative credit limit / days refused.
      expect(
        () => v14.executeArgs(
          'UPDATE ledger SET credit_limit_paise = ? WHERE ledger_id = ?',
          <Object?>[-1, 'l-u'],
        ),
        throwsException,
      );
      expect(
        () => v14.executeArgs(
          'UPDATE ledger SET credit_days = ? WHERE ledger_id = ?',
          <Object?>[-2, 'l-u'],
        ),
        throwsException,
      );
      final NiavDatabase again =
          NiavDatabase(rawEngineOf(v14), clock: testClock());
      again.sqlByVersion = loadMigrationSql();
      again.bootstrap();
      expect(again.schemaVersion, 17); // re-bootstrap stays at latest v17
    });
  });
}
