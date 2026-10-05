// Prompt-10 tests: printer capability validation (FR-M21-001).
// Pure unit tests (no database, no device): only the two approved thermal
// profiles pass; anything else fails with a visible message naming the
// width. Physical-printer behavior stays G5 evidence (G0-VER-006).
// Traceability: FR-M21-001 (unsupported capabilities fail visibly).

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/data/print/escpos.dart';

void main() {
  group('printer capabilities (FR-M21-001)', () {
    test('approved 58/80 mm profiles pass', () {
      expect(checkPrinterCols(kCols58), isNull);
      expect(checkPrinterCols(kCols80), isNull);
      expect(checkPrinterCols(32), isNull);
      expect(checkPrinterCols(48), isNull);
    });

    test('unsupported widths fail visibly (invalid cases)', () {
      for (final int cols in <int>[0, -1, 20, 42, 80, 100]) {
        final String? error = checkPrinterCols(cols);
        expect(error, isNotNull);
        expect(error, contains('$cols'));
      }
    });
  });
}
