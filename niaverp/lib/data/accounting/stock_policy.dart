// NiAvERP negative-stock policy — prompt 06 (M13 P1, gate G1).
// Explicit allow/warn/block vocabulary (FR-M13-001): a stock-affecting write
// must name its policy before posting, and the decision returned here must
// be applied consistently. The posting path that calls this lands with the
// stock-write slice; this unit stores no policy and invents no thresholds.
// D-M5(4) context: negative stock is allowed with warning, no-layer issues
// are costed at last known cost, and there is no retro revaluation in V1.
// Traceability: FR-M13-001; D-M5; O-09.

/// Negative-stock policy. Parsed strictly — unknown text is rejected so a
/// misconfigured caller can never post under an assumed policy.
enum StockPolicy { allow, warn, block }

/// Parse the exact policy vocabulary. Throws [ArgumentError] otherwise.
StockPolicy parseStockPolicy(String raw) {
  switch (raw) {
    case 'allow':
      return StockPolicy.allow;
    case 'warn':
      return StockPolicy.warn;
    case 'block':
      return StockPolicy.block;
    default:
      throw ArgumentError.value(raw, 'raw', 'must be allow/warn/block');
  }
}

/// Decision for a stock move of [moveQ4] (negative = issue) against
/// [onHandQ4] (both integer ×10⁴).
class StockCheck {
  const StockCheck({required this.approved, required this.warning});

  /// Whether the move may post under the policy.
  final bool approved;

  /// True only under `warn` when the move drives the balance negative: the
  /// caller must surface the warning; posting stays allowed.
  final bool warning;
}

/// Apply [policy] to a prospective move. Pure arithmetic, no storage.
StockCheck checkStockMove({
  required StockPolicy policy,
  required int onHandQ4,
  required int moveQ4,
}) {
  final int after = onHandQ4 + moveQ4;
  switch (policy) {
    case StockPolicy.allow:
      return const StockCheck(approved: true, warning: false);
    case StockPolicy.warn:
      return StockCheck(approved: true, warning: after < 0);
    case StockPolicy.block:
      return StockCheck(approved: after >= 0, warning: false);
  }
}
