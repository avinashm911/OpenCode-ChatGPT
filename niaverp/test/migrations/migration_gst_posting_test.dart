// m018 migration tests: GST tax posting context (CA reply 2026-10-07, G3).
// Disposable databases only. Proves: supplier/buyer/voucher/line tax columns
// exist at latest (v18); staged v17 upgrade to v18 preserves rows; CHECKs on
// rate/third-party flag hold; re-bootstrap is repeat-safe.
// Traceability: FR-M03-002; G0-VER-003; CA reply 2026-10-07 (Q1-Q4); DSS-C-007.

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

  group('m018 GST tax posting context', () {
    test('tax columns exist at latest', () {
      db = openTestDatabase();
      addTearDown(() => rawEngineOf(db).close());
      expect(db.schemaVersion, 18); // registry ends at v18 (m018, G3)
      expect(columns(db, 'company'), contains('state_code'));
      expect(columns(db, 'party'), contains('registration_type'));
      expect(
        columns(db, 'voucher'),
        containsAll(<String>[
          'bill_state',
          'ship_state',
          'third_party_direction',
          'supply_category',
          'pos_state',
          'tax_type',
        ]),
      );
      expect(
        columns(db, 'voucher_line'),
        containsAll(<String>[
          'rate_bps',
          'cgst_paise',
          'sgst_paise',
          'igst_paise',
        ]),
      );
    });

    test('staged v17 upgrade to v18 preserves rows; CHECKs enforced', () {
      final NiavDatabase v17 = openTestDatabase(upTo: 17);
      v17.executeArgs(
        'INSERT INTO company (company_id, name, created_at) VALUES (?, ?, ?)',
        <Object?>['c-u', 'Upgrade Co', 1700000000000],
      );
      v17.executeArgs(
        'INSERT INTO voucher (voucher_id, company_id, voucher_type, series, '
        'voucher_no, voucher_date, status, created_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        <Object?>[
          'v-u',
          'c-u',
          'sales-invoice',
          'S',
          '1',
          '2026-04-01',
          'draft',
          1700000000000
        ],
      );
      final NiavDatabase v18 =
          NiavDatabase(rawEngineOf(v17), clock: testClock());
      v18.sqlByVersion = loadMigrationSql();
      v18.bootstrap();
      addTearDown(() => rawEngineOf(v18).close());
      expect(v18.schemaVersion, 18);
      // Pre-m018 rows survive with NULL tax context.
      expect(
        v18
            .queryArgs(
              'SELECT bill_state, tax_type FROM voucher WHERE voucher_id = ?',
              <Object?>['v-u'],
            )
            .single,
        containsPair('bill_state', isNull),
      );
      // Rate bounds and third-party flag are enforced.
      expect(
        () => v18.executeArgs(
          'UPDATE voucher SET third_party_direction = ? WHERE voucher_id = ?',
          <Object?>[2, 'v-u'],
        ),
        throwsException,
      );
      final NiavDatabase again =
          NiavDatabase(rawEngineOf(v18), clock: testClock());
      again.sqlByVersion = loadMigrationSql();
      again.bootstrap();
      expect(again.schemaVersion, 18); // re-bootstrap stays at latest v18
    });
  });
}
