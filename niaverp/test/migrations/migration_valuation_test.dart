// m015 migration tests: valuation method + layer books (gate G1).
// Disposable databases only. Proves: cost_method columns exist on
// item/item_group at latest (v17), remaining columns exist on stock_cost_layer,
// staged v14 upgrade to latest backfills remaining balances without touching
// receipt values, method CHECKs are enforced, and re-bootstrap is
// repeat-safe.
// Traceability: D-M5/D-08; DB §3; FR-M07-003; DSS-C-007.

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

  group('m015 stock valuation', () {
    test('columns exist at latest', () {
      db = openTestDatabase();
      addTearDown(() => rawEngineOf(db).close());
      expect(db.schemaVersion, 18); // registry ends at v18 (m018, G3)
      expect(columns(db, 'item'), contains('cost_method'));
      expect(columns(db, 'item_group'), contains('cost_method'));
      expect(
        columns(db, 'stock_cost_layer'),
        containsAll(<String>['remaining_qty_q4', 'remaining_value_paise']),
      );
    });

    test('staged v14 upgrade to latest backfills books; CHECKs enforced', () {
      final NiavDatabase v14 = openTestDatabase(upTo: 14);
      v14.executeArgs(
        'INSERT INTO company (company_id, name, created_at) VALUES (?, ?, ?)',
        <Object?>['c-u', 'Upgrade Co', 1700000000000],
      );
      v14.executeArgs(
        'INSERT INTO item (item_id, company_id, name, unit, created_at) '
        'VALUES (?, ?, ?, ?, ?)',
        <Object?>['i-u', 'c-u', 'Widget', 'pcs', 1700000000000],
      );
      v14.executeArgs(
        'INSERT INTO godown (godown_id, company_id, name, created_at) '
        'VALUES (?, ?, ?, ?)',
        <Object?>['g-u', 'c-u', 'Main', 1700000000000],
      );
      v14.executeArgs(
        'INSERT INTO stock_cost_layer (layer_id, company_id, item_id, '
        'godown_id, qty_q4, value_paise, created_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?)',
        <Object?>['l-u', 'c-u', 'i-u', 'g-u', 100000, 10000, 1700000000000],
      );
      final NiavDatabase v15 =
          NiavDatabase(rawEngineOf(v14), clock: testClock());
      v15.sqlByVersion = loadMigrationSql();
      v15.bootstrap();
      addTearDown(() => rawEngineOf(v15).close());
      expect(v15.schemaVersion, 18); // staged v14, then full bootstrap to latest v18
      // Receipt record untouched; remaining backfilled to full.
      final Map<String, Object?> layer = v15
          .queryArgs(
            'SELECT qty_q4, value_paise, remaining_qty_q4, '
            'remaining_value_paise FROM stock_cost_layer WHERE layer_id = ?',
            <Object?>['l-u'],
          )
          .single;
      expect(layer['qty_q4'], 100000);
      expect(layer['value_paise'], 10000);
      expect(layer['remaining_qty_q4'], 100000);
      expect(layer['remaining_value_paise'], 10000);
      // Method vocabulary enforced.
      expect(
        () => v15.executeArgs(
          'UPDATE item SET cost_method = ? WHERE item_id = ?',
          <Object?>['lifo', 'i-u'],
        ),
        throwsException,
      );
      v15.executeArgs(
        'UPDATE item SET cost_method = ? WHERE item_id = ?',
        <Object?>['fifo', 'i-u'],
      );
      expect(
        v15
            .queryArgs(
              'SELECT cost_method FROM item WHERE item_id = ?',
              <Object?>['i-u'],
            )
            .single['cost_method'],
        'fifo',
      );
      final NiavDatabase again =
          NiavDatabase(rawEngineOf(v15), clock: testClock());
      again.sqlByVersion = loadMigrationSql();
      again.bootstrap();
      expect(again.schemaVersion, 18); // re-bootstrap stays at latest v18
      expect(
        again
            .queryArgs(
              'SELECT remaining_qty_q4 FROM stock_cost_layer WHERE layer_id = ?',
              <Object?>['l-u'],
            )
            .single['remaining_qty_q4'],
        100000,
      );
    });
  });
}
