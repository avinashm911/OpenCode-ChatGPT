// Entry-field parsing for voucher forms (D3-B1, application layer).
// Pure functions shared by the billing and inventory forms: user-typed
// quantities (units → ×10⁴), money (rupees → paise) and percents (→ basis
// points). Invalid input yields -1 (empty money/percent yields 0); widgets
// keep their own messages and states. Moved out of voucher_form_screen.dart
// so parsing is tested once and reused, never reimplemented per screen.
// Traceability: D-M4 (paise/Q4/bps); D3 (B1/B2).

/// Largest 64-bit signed int (Dart ints are fixed 64-bit on the VM).
const int _kMaxInt64 = 9223372036854775807;

/// Max whole units whose ×10⁴ scaling cannot overflow (remainder 5807).
const int _kMaxQ4Whole = _kMaxInt64 ~/ 10000; // 922337203685477
const int _kMaxQ4Remainder = _kMaxInt64 % 10000; // 5807

/// Max whole rupees whose ×100 scaling cannot overflow (remainder 7).
const int _kMaxPaiseWhole = _kMaxInt64 ~/ 100; // 92233720368547758
const int _kMaxPaiseRemainder = _kMaxInt64 % 100; // 7

final RegExp _kDigits = RegExp(r'^\d+$');

/// Parse a quantity in units to ×10⁴, or -1 when invalid (D3-B1).
/// Integer arithmetic only. The total decides: -1 only when the total is
/// <= 0 or the input is malformed. A leading `.5` counts as 0.5; `5.`,
/// exponents, text, empties, negatives and >4 decimals are malformed.
/// Totals that would overflow 64-bit are rejected, never wrapped.
int parseQuantityQ4(String raw) {
  final String t = raw.trim();
  if (t.isEmpty) return -1;
  final int dot = t.indexOf('.');
  if (dot == -1) {
    final int? v = int.tryParse(t);
    if (v == null || v <= 0 || v > _kMaxQ4Whole) return -1;
    return v * 10000;
  }
  String intPart = t.substring(0, dot);
  final String decPart = t.substring(dot + 1);
  if (decPart.isEmpty || decPart.length > 4) return -1;
  if (intPart.isEmpty) intPart = '0';
  if (!_kDigits.hasMatch(intPart) || !_kDigits.hasMatch(decPart)) return -1;
  final int? intVal = int.tryParse(intPart);
  if (intVal == null || intVal > _kMaxQ4Whole) return -1;
  final int decVal = int.parse(decPart.padRight(4, '0').substring(0, 4));
  if (intVal == _kMaxQ4Whole && decVal > _kMaxQ4Remainder) return -1;
  final int total = intVal * 10000 + decVal;
  if (total <= 0) return -1;
  return total;
}

/// Parse rupees to integer paise (empty counts as zero), or -1 when invalid.
/// Integer arithmetic only; same total-based rule as quantities (`.5` = 50p).
/// Totals that would overflow 64-bit are rejected, never wrapped.
int parsePaise(String raw) {
  final String t = raw.trim();
  if (t.isEmpty) return 0;
  final int dot = t.indexOf('.');
  if (dot == -1) {
    final int? v = int.tryParse(t);
    if (v == null || v < 0 || v > _kMaxPaiseWhole) return -1;
    return v * 100;
  }
  String intPart = t.substring(0, dot);
  final String decPart = t.substring(dot + 1);
  if (decPart.isEmpty || decPart.length > 2) return -1;
  if (intPart.isEmpty) intPart = '0';
  if (!_kDigits.hasMatch(intPart) || !_kDigits.hasMatch(decPart)) return -1;
  final int? intVal = int.tryParse(intPart);
  if (intVal == null || intVal > _kMaxPaiseWhole) return -1;
  final int decVal = int.parse(decPart.padRight(2, '0').substring(0, 2));
  if (intVal == _kMaxPaiseWhole && decVal > _kMaxPaiseRemainder) return -1;
  return intVal * 100 + decVal;
}

/// Parse percent to integer basis points (empty counts as zero), or -1 when
/// invalid (negative or above 100%). Integer arithmetic only; `.5` = 50bps.
int parsePercentBps(String raw) {
  final String t = raw.trim();
  if (t.isEmpty) return 0;
  final int dot = t.indexOf('.');
  if (dot == -1) {
    final int? v = int.tryParse(t);
    if (v == null || v < 0 || v > 100) return -1;
    return v * 100;
  }
  String intPart = t.substring(0, dot);
  final String decPart = t.substring(dot + 1);
  if (decPart.isEmpty || decPart.length > 2) return -1;
  if (intPart.isEmpty) intPart = '0';
  if (!_kDigits.hasMatch(intPart) || !_kDigits.hasMatch(decPart)) return -1;
  final int? intVal = int.tryParse(intPart);
  if (intVal == null || intVal < 0 || intVal > 100) return -1;
  final int decVal = int.parse(decPart.padRight(2, '0').substring(0, 2));
  final int result = intVal * 100 + decVal;
  if (result > 10000) return -1;
  return result;
}
