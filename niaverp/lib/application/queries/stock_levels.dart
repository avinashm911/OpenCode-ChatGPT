// NiAvERP stock read models — prompt 06 (M15 P1, gate G1).
// Day-one inventory reports as queries over persisted rows (strategy Slice 5
// rule: every report is a query over persisted data): per-(item, godown)
// balances from stock_movement deltas, movement history, and cost-layer value
// totals from stock_cost_layer. Read-only; company scope always enforced.
// Ageing buckets, reorder math and physical-count flows stay downstream
// (FR-M13-002 P2; no approved bucket/reorder columns).
// Traceability: M15; D-M4 (paise/Q4 integers); G0-SCH-001.

import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/data/migrations/migration_runner.dart';

/// Caller-overridable row cap. An implementation safety default, NOT a
/// documented performance target.
const int kDefaultStockRowLimit = 200;

/// On-hand balance of one item in one godown (integer ×10⁴, may be negative
/// where negative stock was allowed with warning).
class StockBalance {
  const StockBalance({
    required this.itemId,
    required this.godownId,
    required this.qtyQ4,
  });

  final EntityId itemId;
  final EntityId godownId;
  final int qtyQ4;
}

/// Live book valuation of one item in one godown: movement-derived
/// quantity plus remaining-layer value (paise). The report consequence of
/// posted receipts, issues, returns, adjustments and transfers.
class StockValuation {
  const StockValuation({
    required this.itemId,
    required this.godownId,
    required this.qtyQ4,
    required this.valuePaise,
  });

  final EntityId itemId;
  final EntityId godownId;
  final int qtyQ4;
  final int valuePaise;
}

/// One persisted stock movement, newest-last in listings.
class StockMovementView {
  const StockMovementView({
    required this.movementId,
    required this.itemId,
    required this.godownId,
    required this.qtyDeltaQ4,
    required this.costPaise,
    required this.costSource,
    required this.createdAt,
  });

  final String movementId;
  final EntityId itemId;
  final EntityId godownId;
  final int qtyDeltaQ4;
  final int costPaise;
  final String costSource;
  final int createdAt;

  static StockMovementView fromRow(Map<String, Object?> r) => StockMovementView(
        movementId: r['movement_id'] as String,
        itemId: EntityId(r['item_id'] as String),
        godownId: EntityId(r['godown_id'] as String),
        qtyDeltaQ4: r['qty_delta_q4'] as int,
        costPaise: r['cost_paise'] as int,
        costSource: r['cost_source'] as String,
        createdAt: r['created_at'] as int,
      );
}

/// Read-only stock queries over the G0-SCH-001 tables.
class StockLevels {
  const StockLevels(this._db);

  final MigrationDb _db;

  /// Balance per (item, godown) with at least one movement. Optional
  /// item/godown filters narrow the report; scope is always the company.
  List<StockBalance> balances(
    CompanyId companyId, {
    EntityId? itemId,
    EntityId? godownId,
  }) {
    final StringBuffer sql = StringBuffer(
      'SELECT item_id, godown_id, SUM(qty_delta_q4) AS qty '
      'FROM stock_movement WHERE company_id = ?',
    );
    final List<Object?> args = <Object?>[companyId.value];
    if (itemId != null) {
      sql.write(' AND item_id = ?');
      args.add(itemId.value);
    }
    if (godownId != null) {
      sql.write(' AND godown_id = ?');
      args.add(godownId.value);
    }
    sql.write(' GROUP BY item_id, godown_id ORDER BY item_id, godown_id');
    final List<Map<String, Object?>> rows = _db.queryArgs(sql.toString(), args);
    return <StockBalance>[
      for (final Map<String, Object?> r in rows)
        StockBalance(
          itemId: EntityId(r['item_id'] as String),
          godownId: EntityId(r['godown_id'] as String),
          qtyQ4: r['qty'] as int,
        ),
    ];
  }

  /// Movement history, oldest first, capped. Filters behave as in [balances].
  List<StockMovementView> movements(
    CompanyId companyId, {
    EntityId? itemId,
    EntityId? godownId,
    int limit = kDefaultStockRowLimit,
  }) {
    final StringBuffer sql = StringBuffer(
      'SELECT movement_id, item_id, godown_id, qty_delta_q4, cost_paise, '
      'cost_source, created_at FROM stock_movement WHERE company_id = ?',
    );
    final List<Object?> args = <Object?>[companyId.value];
    if (itemId != null) {
      sql.write(' AND item_id = ?');
      args.add(itemId.value);
    }
    if (godownId != null) {
      sql.write(' AND godown_id = ?');
      args.add(godownId.value);
    }
    sql.write(' ORDER BY created_at, movement_id LIMIT ?');
    args.add(limit);
    final List<Map<String, Object?>> rows = _db.queryArgs(sql.toString(), args);
    return <StockMovementView>[
      for (final Map<String, Object?> r in rows) StockMovementView.fromRow(r),
    ];
  }

  /// Total live layer value (paise) held for one item in one godown:
  /// remaining balances after posted consumption (COALESCE keeps
  /// raw-seeded pre-v15 layers readable).
  int layerValuePaise(
    CompanyId companyId,
    EntityId itemId,
    EntityId godownId,
  ) {
    final List<Map<String, Object?>> rows = _db.queryArgs(
      'SELECT SUM(COALESCE(remaining_value_paise, value_paise)) AS v '
      'FROM stock_cost_layer '
      'WHERE company_id = ? AND item_id = ? AND godown_id = ?',
      <Object?>[companyId.value, itemId.value, godownId.value],
    );
    return (rows.first['v'] as int?) ?? 0;
  }

  /// Valuation per (item, godown) with live book value: every balance from
  /// [balances] joined with its remaining-layer value. Optional item/godown
  /// filters narrow the report; scope is always the company.
  List<StockValuation> valuation(
    CompanyId companyId, {
    EntityId? itemId,
    EntityId? godownId,
  }) {
    final List<StockBalance> held =
        balances(companyId, itemId: itemId, godownId: godownId);
    return <StockValuation>[
      for (final StockBalance b in held)
        StockValuation(
          itemId: b.itemId,
          godownId: b.godownId,
          qtyQ4: b.qtyQ4,
          valuePaise: layerValuePaise(companyId, b.itemId, b.godownId),
        ),
    ];
  }
}
