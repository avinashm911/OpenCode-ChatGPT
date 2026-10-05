// NiAvERP quantity value object — Phase 00.
// D-M4: quantity is integer quantity × 10^4. Unit-specific display decimals
// (pcs 0, kg/litre 3, other ≤ 4) are per-item policy applied by later slices;
// this type stores the raw integer and formats with an explicit scale.
// Traceability: D-M4/OD-DB-001; DECISIONS.md (D-M4).

/// Integer quantity in units of quantity × 10^4.
class QuantityQ4 {
  const QuantityQ4(this.q4);

  /// Raw stored integer.
  final int q4;

  static const QuantityQ4 zero = QuantityQ4(0);

  /// Formats with [fractionDigits] (0–4) without floating-point arithmetic.
  /// Throws [ArgumentError] for out-of-range scales.
  String format({int fractionDigits = 4}) {
    if (fractionDigits < 0 || fractionDigits > 4) {
      throw ArgumentError.value(
        fractionDigits,
        'fractionDigits',
        'must be 0..4',
      );
    }
    final int divisor = _pow10(4 - fractionDigits);
    final int scaled = q4 ~/ divisor;
    if (fractionDigits == 0) return '$scaled';
    final int base = _pow10(fractionDigits);
    final String frac =
        (scaled.abs() % base).toString().padLeft(fractionDigits, '0');
    return '${scaled ~/ base}.$frac';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is QuantityQ4 && other.q4 == q4);

  @override
  int get hashCode => q4.hashCode;

  @override
  String toString() => 'QuantityQ4($q4)';
}

int _pow10(int n) {
  var r = 1;
  for (var i = 0; i < n; i++) {
    r *= 10;
  }
  return r;
}
