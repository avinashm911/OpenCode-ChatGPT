// NiAvERP money value object — Phase 00.
// D-M4: money is integer paise. No floating-point arithmetic for accounting.
// This type only stores and renders the stored integer; rounding/posting
// rules live in the accounting engines (lib/data/accounting/*).
// Traceability: D-M4/OD-DB-001; DECISIONS.md (D-M4).

/// Integer paise amount. Negative values are allowed at the type level
/// (e.g. round-off lines may be negative); per-field non-negativity is
/// enforced by schema CHECKs and validators, not by this type.
class MoneyPaise {
  const MoneyPaise(this.paise);

  /// Amount in integer paise.
  final int paise;

  static const MoneyPaise zero = MoneyPaise(0);

  MoneyPaise operator +(MoneyPaise other) => MoneyPaise(paise + other.paise);
  MoneyPaise operator -(MoneyPaise other) => MoneyPaise(paise - other.paise);

  /// Renders integer paise as a decimal rupee string (always ≤ 2 decimals).
  String toRupeesString() {
    final String sign = paise < 0 ? '-' : '';
    final int mag = paise.abs();
    final String p = mag.remainder(100).toString().padLeft(2, '0');
    return '$sign${mag ~/ 100}.$p';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MoneyPaise && other.paise == paise);

  @override
  int get hashCode => paise.hashCode;

  @override
  String toString() => 'MoneyPaise($paise)';
}
