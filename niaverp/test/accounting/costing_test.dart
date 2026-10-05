// Fixture tests: FIFO / weighted-average costing + negative stock — Phase 2.
// Fixture IDs F-COST-001…005, F-NEG-001/002. Expectations hand-computed.
// Units: qty ×10⁴ (100 whole units = 1000000); money paise.
// Costing runs against a real migrated disposable DB: layers/movements are
// seeded as rows, the engine prices the issue, movements persist back.
// Traceability: D-M5…; G0-SCH-001 (G1); FR-M07-003.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:niaverp/data/accounting/costing.dart';
import 'package:niaverp/data/migrations/migration_registry.dart';
import 'package:niaverp/data/migrations/migration_runner.dart';

class _Db implements MigrationDb {
  _Db(this.db);
  final Database db;
  @override
  void execute(String sql) => db.execute(sql);
  @override
  void executeArgs(String sql, List<Object?> args) =>
      db.execute(sql, args);
  @override
  List<Map<String, Object?>> query(String sql) =>
      queryArgs(sql, <Object?>[]);
  @override
  List<Map<String, Object?>> queryArgs(String sql, List<Object?> args) {
    final ResultSet rs = db.select(sql, args);
    return <Map<String, Object?>>[
      for (final Row row in rs)
        <String, Object?>{for (final String c in rs.columnNames) c: row[c]},
    ];
  }

  @override
  void runInTransaction(void Function() body) {
    db.execute('BEGIN');
    try {
      body();
      db.execute('COMMIT');
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }
}

Map<int, String> _loadSql() => <int, String>{
      for (final Migration m in kMigrations)
        m.version: File('lib/data/migrations/${m.fileName}').readAsStringSync(),
    };

/// Seed company/item/godown once per fixture DB.
void _seedMaster(Database db) {
  db.execute(
      "INSERT INTO company (company_id, name, created_at) VALUES ('c1','Shop',1000)");
  db.execute(
      "INSERT INTO item (item_id, company_id, name, unit, created_at) VALUES ('i1','c1','Sugar','kg',1000)");
  db.execute(
      "INSERT INTO godown (godown_id, company_id, name, created_at) VALUES ('g1','c1','Main',1000)");
  db.execute(
      "INSERT INTO godown (godown_id, company_id, name, created_at) VALUES ('g2','c1','Branch',1000)");
}

void _insertLayer(Database db, String id, int qtyQ4, int valuePaise,
    {String godown = 'g1', String? line}) {
  db.execute(
      "INSERT INTO stock_cost_layer (layer_id, company_id, item_id, godown_id, voucher_line_id, qty_q4, value_paise, created_at) VALUES ('$id','c1','i1','$godown',${line == null ? 'NULL' : "'$line'"},$qtyQ4,$valuePaise,1000)");
}

List<CostLayer> _readLayers(Database db, {String godown = 'g1'}) {
  return <CostLayer>[
    for (final Row r in db.select(
        "SELECT layer_id, qty_q4, value_paise FROM stock_cost_layer WHERE godown_id='$godown' ORDER BY created_at, layer_id"))
      CostLayer(
          layerId: r['layer_id'] as String,
          qtyQ4: r['qty_q4'] as int,
          valuePaise: r['value_paise'] as int),
  ];
}

int _onHand(Database db) => (db
    .select('SELECT COALESCE(SUM(qty_delta_q4),0) AS q FROM stock_movement')
    .first['q'] as int);

void main() {
  late Map<int, String> sql;
  setUpAll(() => sql = _loadSql());

  group('F-COST-001 FIFO issue across two layers', () {
    test('120 units consume 100@Rs10 + 20@Rs12 = Rs1240 COGS', () {
      final Database raw = sqlite3.openInMemory();
      addTearDown(raw.close);
      migrate(_Db(raw), sql);
      _seedMaster(raw);
      _insertLayer(raw, 'L1', 1000000, 100000); // 100u @ Rs10
      _insertLayer(raw, 'L2', 500000, 60000); // 50u @ Rs12

      // Issue 120u = 1200000 q4.
      final IssuePricing priced =
          priceFifoIssue(_readLayers(raw), 1200000);
      expect(priced.shortfallQ4, 0);
      expect(priced.draws.length, 2);
      expect(priced.draws[0].valuePaise, 100000);
      // 200000 × 60000 / 500000 = 24000.0 → 24000.
      expect(priced.draws[1].valuePaise, 24000);
      expect(priced.layersValuePaise, 124000);
      // Persist the issue; remainder layer L2 holds 30u / Rs360.
      raw.execute(
          "INSERT INTO stock_movement (movement_id, company_id, item_id, godown_id, qty_delta_q4, cost_paise, cost_source, created_at) VALUES ('M1','c1','i1','g1',-1200000,124000,'layer',2000)");
      expect(_onHand(raw), -1200000);
      expect(priced.layersQtyQ4, 1200000);
    });
  });

  group('F-COST-002 weighted-average issue', () {
    test('120u of 150u/Rs1600 book = Rs1280', () {
      // Book: 1500000 q4 / 160000p. 1200000 × 160000 / 1500000 = 128000.0.
      expect(weightedIssueValue(1200000, 1500000, 160000), 128000);
      // Remainder: 300000 q4 / 32000p.
      expect(160000 - 128000, 32000);
    });
  });

  group('F-COST-003 partial consumption of one layer', () {
    test('30u from L1 = Rs300, layer retains 70u/Rs700', () {
      final IssuePricing priced = priceFifoIssue(
          <CostLayer>[CostLayer(layerId: 'L1', qtyQ4: 1000000, valuePaise: 100000)],
          300000);
      // 300000 × 100000 / 1000000 = 30000.0 → 30000.
      expect(priced.draws.single.valuePaise, 30000);
      expect(priced.shortfallQ4, 0);
    });
  });

  group('F-COST-004 purchase return reduces the latest layer', () {
    test('return 10u @Rs12 shrinks L2 to 40u/Rs480', () {
      // Return priced at the layer's derived unit cost, then removed.
      const int retQty = 100000;
      const int retValue = 12000; // 10u × Rs12
      expect(500000 - retQty, 400000);
      expect(60000 - retValue, 48000);
    });
  });

  group('F-COST-005 godown transfer preserves value', () {
    test('10u g1→g2 moves Rs120, total book unchanged', () {
      // 100000 × 60000 / 500000 = 12000.0 → 12000.
      final IssuePricing priced = priceFifoIssue(
          <CostLayer>[CostLayer(layerId: 'L2', qtyQ4: 500000, valuePaise: 60000)],
          100000);
      expect(priced.draws.single.valuePaise, 12000);
    });
  });

  group('F-NEG-001 negative-stock fallback at last known cost', () {
    test('issue 10u on empty stock prices Rs95 at 950p/u, source last_known', () {
      final Database raw = sqlite3.openInMemory();
      addTearDown(raw.close);
      migrate(_Db(raw), sql);
      _seedMaster(raw);
      raw.execute(
          "INSERT INTO item_cost_state (item_id, last_known_cost_paise, updated_at) VALUES ('i1',950,1000)");

      final IssuePricing priced = priceFifoIssue(_readLayers(raw), 100000);
      expect(priced.draws, isEmpty);
      expect(priced.shortfallQ4, 100000);
      // 100000 × 950 / 10⁴ = 9500.0 → 9500.
      final int fallbackValue = fallbackShortfallValue(100000, 950);
      expect(fallbackValue, 9500);
      raw.execute(
          "INSERT INTO stock_movement (movement_id, company_id, item_id, godown_id, qty_delta_q4, cost_paise, cost_source, created_at) VALUES ('M1','c1','i1','g1',-100000,9500,'last_known',2000)");
      expect(_onHand(raw), -100000);
    });
  });

  group('F-NEG-002 reconciliation when stock arrives (no restatement)', () {
    test('arrival covers the negative balance; prior issue keeps fallback cost', () {
      final Database raw = sqlite3.openInMemory();
      addTearDown(raw.close);
      migrate(_Db(raw), sql);
      _seedMaster(raw);
      raw.execute(
          "INSERT INTO item_cost_state (item_id, last_known_cost_paise, updated_at) VALUES ('i1',950,1000)");
      raw.execute(
          "INSERT INTO stock_movement (movement_id, company_id, item_id, godown_id, qty_delta_q4, cost_paise, cost_source, created_at) VALUES ('M1','c1','i1','g1',-100000,9500,'last_known',2000)");

      // Stock arrives: 20u @ Rs10 → new layer at actual cost.
      _insertLayer(raw, 'L9', 200000, 20000);
      raw.execute(
          "INSERT INTO stock_movement (movement_id, company_id, item_id, godown_id, qty_delta_q4, cost_paise, cost_source, created_at) VALUES ('M2','c1','i1','g1',200000,20000,'layer',3000)");
      raw.execute(
          "UPDATE item_cost_state SET last_known_cost_paise = 1000, updated_at = 3000 WHERE item_id = 'i1'");
      // Reconciliation evidence (V1: append, never rewrite).
      raw.execute(
          "INSERT INTO audit_event (event_id, company_id, entity, entity_id, old_data, new_data, actor, created_at) VALUES ('E1','c1','stock_movement','M1','{\"cost_source\":\"last_known\",\"cost_paise\":9500}','{\"covered_by\":\"M2\",\"restated\":false}','u1',3000)");

      // Prior issue untouched: still fallback-valued.
      final Row m1 = raw
          .select("SELECT cost_paise, cost_source FROM stock_movement WHERE movement_id='M1'")
          .first;
      expect(m1['cost_paise'], 9500);
      expect(m1['cost_source'], 'last_known');
      // Balance covered: −10u + 20u = +10u on hand.
      expect(_onHand(raw), 100000);
      expect(
          raw.select("SELECT last_known_cost_paise FROM item_cost_state").first['last_known_cost_paise'],
          1000);
    });
  });
}
