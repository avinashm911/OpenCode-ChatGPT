// Entry-field parsing for voucher forms (D3-B1, application layer).
// Pure functions shared by the billing and inventory forms: user-typed
// quantities (units → ×10⁴), money (rupees → paise) and percents (→ basis
// points). Invalid input yields -1 (empty money/percent yields 0); widgets
// keep their own messages and states. Moved out of voucher_form_screen.dart
// so parsing is tested once and reused, never reimplemented per screen.
// Traceability: D-M4 (paise/Q4/bps); D3 (B1/B2).

/// Parse a quantity in units to ×10⁴, or -1 when invalid (D3-B1).
int parseQuantityQ4(String raw) {
  final String t = raw.trim();
  if (t.isEmpty) return -1;
  final int dot = t.indexOf('.');
  if (dot == -1) {
    final int? v = int.tryParse(t);
    if (v == null || v <= 0) return -1;
    return v * 10000;
  }
  final String intPart = t.substring(0, dot);
  final String decPart = t.substring(dot + 1);
  if (intPart.isEmpty || decPart.isEmpty || decPart.length > 4 || intPart.contains('-')) return -1;
  if (!RegExp(r'^\d+$').hasMatch(intPart) || !RegExp(r'^\d+$').hasMatch(decPart)) return -1;
  final int intVal = int.parse(intPart);
  if (intVal <= 0) return -1;
  final int decVal = int.parse(decPart.padRight(4, '0').substring(0, 4));
  return intVal * 10000 + decVal;
}

/// Parse rupees to integer paise (empty counts as zero), or -1 when invalid.
int parsePaise(String raw) {
  final String t = raw.trim();
  if (t.isEmpty) return 0;
  final int dot = t.indexOf('.');
  if (dot == -1) {
    final int? v = int.tryParse(t);
    if (v == null || v < 0) return -1;
    return v * 100;
  }
  final String intPart = t.substring(0, dot);
  final String decPart = t.substring(dot + 1);
  if (decPart.length > 2 || !RegExp(r'^\d+$').hasMatch(intPart) || !RegExp(r'^\d+$').hasMatch(decPart)) return -1;
  final int intVal = int.parse(intPart);
  if (intVal < 0) return -1;
  final int decVal = int.parse(decPart.padRight(2, '0').substring(0, 2));
  return intVal * 100 + decVal;
}

/// Parse percent to integer basis points (empty counts as zero), or -1 when
/// invalid (negative or above 100%).
int parsePercentBps(String raw) {
  final String t = raw.trim();
  if (t.isEmpty) return 0;
  final int dot = t.indexOf('.');
  if (dot == -1) {
    final int? v = int.tryParse(t);
    if (v == null || v < 0 || v > 100) return -1;
    return v * 100;
  }
  final String intPart = t.substring(0, dot);
  final String decPart = t.substring(dot + 1);
  if (decPart.length > 2 || !RegExp(r'^\d+$').hasMatch(intPart) || !RegExp(r'^\d+$').hasMatch(decPart)) return -1;
  final int intVal = int.parse(intPart);
  if (intVal < 0 || intVal > 100) return -1;
  final int decVal = int.parse(decPart.padRight(2, '0').substring(0, 2));
  final int result = intVal * 100 + decVal;
  if (result > 10000) return -1;
  return result;
}
