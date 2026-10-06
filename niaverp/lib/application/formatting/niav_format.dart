// NiAvERP display formatter — D4-A3 (M02.6, single formatter).
// One place for paise→rupee display, ISO date display and quantity display.
// ISO storage is never altered: these functions render only. Indian digit
// grouping (lakh/crore: last 3 digits, then pairs) with the ₹ symbol (M02.6).
// Western digits render in every locale: no source fixes a Devanagari/
// Gujarati digit shape, so none is invented (translator-review list, D4 §7).
// Pure Dart, no packages. Traceability: M02.6; FR-M02-001; D-M4 (paise/Q4).

/// Display formatting for NiAvERP amounts, dates and quantities.
class NiavFormat {
  const NiavFormat(this.localeCode);

  /// 'en', 'hi' or 'gu'. Grouping rules are identical (M02.6 fixes the
  /// Indian system, not per-locale digit shapes).
  final String localeCode;

  /// Render integer [paise] as '₹1,00,000.00' (Indian grouping, 2 decimals).
  /// Negative renders '-₹...'. Storage stays integer paise.
  String paise(int paise) {
    final String sign = paise < 0 ? '-' : '';
    final int mag = paise.abs();
    final int rupees = mag ~/ 100;
    final String ps = (mag % 100).toString().padLeft(2, '0');
    return '$sign₹${_groupIndian(rupees)}.$ps';
  }

  /// Group [rupees] per the Indian system: '100000' → '1,00,000'.
  static String _groupIndian(int rupees) {
    final String s = rupees.toString();
    if (s.length <= 3) return s;
    final String tail = s.substring(s.length - 3);
    String head = s.substring(0, s.length - 3);
    final List<String> parts = <String>[];
    while (head.length > 2) {
      parts.add(head.substring(head.length - 2));
      head = head.substring(0, head.length - 2);
    }
    parts.add(head);
    return '${parts.reversed.join(',')},$tail';
  }

  /// Render an ISO 'YYYY-MM-DD' date for display. Returns the input
  /// unchanged when it is not a valid ISO date (never throws for display).
  String date(String iso) {
    final RegExp m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
    final RegExpMatch? hit = m.firstMatch(iso.trim());
    if (hit == null) return iso;
    final int month = int.tryParse(hit.group(2)!) ?? 0;
    if (month < 1 || month > 12) return iso;
    final String mon = _monthShort(month, localeCode);
    return '${hit.group(3)} $mon ${hit.group(1)}';
  }

  /// Render integer ×10⁴ [qtyQ4] with [decimals] unit places.
  String qty(int qtyQ4, int decimals) {
    final int d = decimals.clamp(0, 4);
    final int divisor = <int>[1, 10, 100, 1000, 10000][d];
    final String sign = qtyQ4 < 0 ? '-' : '';
    final int mag = qtyQ4.abs();
    final String whole = (mag ~/ divisor).toString();
    if (d == 0) return '$sign$whole';
    final String frac =
        (mag % divisor).toString().padLeft(d, '0');
    return '$sign$whole.$frac';
  }

  static const Map<int, List<String>> _months = <int, List<String>>{
    1: <String>['Jan', 'जन', 'જાન્યુ'],
    2: <String>['Feb', 'फ़र', 'ફેબ્રુ'],
    3: <String>['Mar', 'मार्च', 'માર્ચ'],
    4: <String>['Apr', 'अप्रै', 'એપ્રિલ'],
    5: <String>['May', 'मई', 'મે'],
    6: <String>['Jun', 'जून', 'જૂન'],
    7: <String>['Jul', 'जुल', 'જુલાઈ'],
    8: <String>['Aug', 'अग', 'ઑગ'],
    9: <String>['Sep', 'सित', 'સપ્ટે'],
    10: <String>['Oct', 'अक्तू', 'ઑક્ટો'],
    11: <String>['Nov', 'नव', 'નવે'],
    12: <String>['Dec', 'दिस', 'ડિસે'],
  };

  static String _monthShort(int month, String locale) {
    final List<String>? names = _months[month];
    if (names == null) return month.toString().padLeft(2, '0');
    switch (locale) {
      case 'hi':
        return names[1];
      case 'gu':
        return names[2];
      default:
        return names[0];
    }
  }
}
