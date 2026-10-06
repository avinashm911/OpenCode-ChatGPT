// m012 migration tests: series numbering mode (gate G1).
// Disposable databases only. Proves: mode column exists at v12, staged
// v11→v12 upgrade preserves series rows, bad modes are refused by the
// schema CHECK, and re-bootstrap is repeat-safe.
// Traceability: DB §3 (voucher_series mode); FR-M04-002; DSS-C-007.

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

  group('m012 series mode', () {
    test('mode column exists at v12', () {
      db = openTestDatabase();
      addTearDown(() => rawEngineOf(db).close());
      expect(db.schemaVersion, 17); // registry ends at v17 (m017, D2);
      expect(columns(db, 'voucher_series'), contains('mode'));
    });

    test('staged v11→v12 upgrade preserves series; CHECK enforced', () {
      final NiavDatabase v11 = openTestDatabase(upTo: 11);
      v11.executeArgs(
        'INSERT INTO company (company_id, name, created_at) VALUES (?, ?, ?)',
        <Object?>['c-u', 'Upgrade Co', 1700000000000],
      );
      v11.executeArgs(
        'INSERT INTO voucher_type (type_id, company_id, base_type, name, '
        'created_at) VALUES (?, ?, ?, ?, ?)',
        <Object?>['t-u', 'c-u', 'Sales Invoice', 'SI', 1700000000000],
      );
      v11.executeArgs(
        'INSERT INTO voucher_series (series_id, company_id, type_id, name, '
        'created_at) VALUES (?, ?, ?, ?, ?)',
        <Object?>['s-u', 'c-u', 't-u', 'MAIN', 1700000000000],
      );
      final NiavDatabase v12 =
          NiavDatabase(rawEngineOf(v11), clock: testClock());
      v12.sqlByVersion = loadMigrationSql();
      v12.bootstrap();
      addTearDown(() => rawEngineOf(v12).close());
      expect(v12.schemaVersion, 17); // registry ends at v17 (m017, D2);
      final List<Map<String, Object?>> rows = v12.queryArgs(
        'SELECT mode FROM voucher_series WHERE series_id = ?',
        <Object?>['s-u'],
      );
      expect(rows.single['mode'], isNull);
      expect(
        () => v12.executeArgs(
          'UPDATE voucher_series SET mode = ? WHERE series_id = ?',
          <Object?>['sometimes', 's-u'],
        ),
        throwsException,
      );
      v12.executeArgs(
        'UPDATE voucher_series SET mode = ? WHERE series_id = ?',
        <Object?>['auto', 's-u'],
      );
      final NiavDatabase again =
          NiavDatabase(rawEngineOf(v12), clock: testClock());
      again.sqlByVersion = loadMigrationSql();
      again.bootstrap();
      expect(again.schemaVersion, 17); // registry ends at v17 (m017, D2);
    });
  });
}
