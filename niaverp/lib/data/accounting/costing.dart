// NiAvERP G0 costing engine — Phase 2.
// FIFO and weighted-average consumption over stock_cost_layer rows, with the
// approved negative-stock fallback (last known cost, warning) and later
// reconciliation WITHOUT retro revaluation (D-M5: no-layer issues costed at
// last known cost; no retro revaluation in V1).
// Method lock (after first posted movement), FIFO-vs-WA selection and the
// warning UX are app logic; this engine prices a single issue event.
// Money paise, qty ×10⁴, round-half-up (D-M4).
// Traceability: D-M5/D-08/D-FG-013/O-09/OD-004/OD-FD-001; G0-SCH-001 (G1).

/// One available cost layer (projection of a stock_cost_layer row).
class CostLayer {
  CostLayer({required this.layerId, required this.qtyQ4, required this.valuePaise});
  final String layerId;
  final int qtyQ4;
  final int valuePaise;
}

/// Quantity taken from a single layer at that layer's unit cost.
class LayerDraw {
  LayerDraw({required this.layerId, required this.qtyQ4, required this.valuePaise});
  final String layerId;
  final int qtyQ4;
  final int valuePaise;
}

/// Result of pricing an issue: per-layer draws plus any shortfall that must
/// be priced at fallback cost (negative stock).
class IssuePricing {
  IssuePricing({required this.draws, required this.shortfallQ4});
  final List<LayerDraw> draws;
  final int shortfallQ4;

  /// Value taken from layers (fallback shortfall excluded).
  int get layersValuePaise =>
      draws.fold(0, (int s, LayerDraw d) => s + d.valuePaise);

  /// Quantity taken from layers.
  int get layersQtyQ4 => draws.fold(0, (int s, LayerDraw d) => s + d.qtyQ4);
}

/// FIFO draw across [layers] in list order (oldest first) for [qtyOutQ4].
/// Never throws on shortage: the uncovered remainder is returned as
/// [IssuePricing.shortfallQ4] for fallback pricing (approved negative stock).
/// Per-unit layer cost is derived (value×10⁴/qty) with round-half-up; a draw
/// never exceeds its layer's remaining value (last unit absorbs rounding).
IssuePricing priceFifoIssue(List<CostLayer> layers, int qtyOutQ4) {
  if (qtyOutQ4 <= 0) throw ArgumentError('qtyOutQ4 must be positive');
  final List<LayerDraw> draws = <LayerDraw>[];
  int remaining = qtyOutQ4;
  for (final CostLayer layer in layers) {
    if (remaining <= 0) break;
    if (layer.qtyQ4 <= 0) continue;
    final int take = remaining < layer.qtyQ4 ? remaining : layer.qtyQ4;
    int value;
    if (take == layer.qtyQ4) {
      value = layer.valuePaise; // whole layer: exact, no rounding drift
    } else {
      value = ((take * layer.valuePaise) + layer.qtyQ4 ~/ 2) ~/ layer.qtyQ4;
      if (value > layer.valuePaise) value = layer.valuePaise;
    }
    draws.add(LayerDraw(layerId: layer.layerId, qtyQ4: take, valuePaise: value));
    remaining -= take;
  }
  return IssuePricing(draws: draws, shortfallQ4: remaining);
}

/// Weighted-average issue value for [qtyOutQ4] against book totals
/// (totalQtyQ4 on hand, totalValuePaise): round-half-up(qty × value / qty).
int weightedIssueValue(int qtyOutQ4, int totalQtyQ4, int totalValuePaise) {
  if (qtyOutQ4 <= 0) throw ArgumentError('qtyOutQ4 must be positive');
  if (totalQtyQ4 <= 0) throw ArgumentError('no stock to average against');
  return ((qtyOutQ4 * totalValuePaise) + totalQtyQ4 ~/ 2) ~/ totalQtyQ4;
}

/// Fallback value for negative-stock shortfall at last known unit cost
/// (paise per whole unit): round-half-up(shortfallQ4 × cost / 10⁴).
int fallbackShortfallValue(int shortfallQ4, int lastKnownCostPaise) {
  if (shortfallQ4 <= 0) return 0;
  if (lastKnownCostPaise < 0) throw ArgumentError('cost must be >= 0');
  return ((shortfallQ4 * lastKnownCostPaise) + 5000) ~/ 10000;
}

/// Valuation-method vocabulary (D-M5: Weighted Average and FIFO only).
/// Stored as TEXT 'fifo'/'wa' on item (override) and item_group (default);
/// NULL means unset at that level.
const String kCostMethodFifo = 'fifo';
const String kCostMethodWa = 'wa';

/// True when [method] is an allowed stored value (or null = unset).
bool isValidCostMethod(String? method) =>
    method == null || method == kCostMethodFifo || method == kCostMethodWa;

/// Resolve the effective method: item override wins over the group default,
/// and an unset chain falls back to Weighted Average (D-M5 default).
/// Throws [ArgumentError] on an invalid stored value (never silently mapped).
String resolveCostMethod(String? itemMethod, String? groupMethod) {
  if (!isValidCostMethod(itemMethod) || !isValidCostMethod(groupMethod)) {
    throw ArgumentError('cost method must be fifo, wa or unset');
  }
  return itemMethod ?? groupMethod ?? kCostMethodWa;
}

/// Movement cost-source family produced by layer-priced issues. Only these
/// sources lock the valuation method of a book (fallback/zero issues price
/// nothing from layers, so they bind nothing).
const Set<String> kMethodLockSources = <String>{
  'average',
  'fifo',
  'fifo-fallback',
};

/// Effective method behind a layer-priced movement source.
String? methodOfPricedSource(String costSource) {
  switch (costSource) {
    case 'average':
      return kCostMethodWa;
    case 'fifo':
    case 'fifo-fallback':
      return kCostMethodFifo;
    default:
      return null;
  }
}
