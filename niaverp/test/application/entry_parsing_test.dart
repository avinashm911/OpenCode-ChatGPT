// Entry-parsing tests (D3-B1): the shared application-layer parser.
// Proves: quantities scale to ×10⁴; rupees to paise; percents to basis
// points; empty money/percent counts as zero; invalid input yields -1.
// Traceability: D-M4; D3 (B1).

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/application/parsing/entry_parsing.dart';

void main() {
  group('entry parsing (D3-B1)', () {
    test('quantities scale to x10^4, invalid yields -1', () {
      expect(parseQuantityQ4('1'), 10000);
      expect(parseQuantityQ4('2.5'), 25000);
      expect(parseQuantityQ4(' 0.0001 '), 1);
      expect(parseQuantityQ4(''), -1);
      expect(parseQuantityQ4('0'), -1);
      expect(parseQuantityQ4('-2'), -1);
      expect(parseQuantityQ4('many'), -1);
    });

    test('rupees scale to paise, empty is zero, invalid yields -1', () {
      expect(parsePaise('50'), 5000);
      expect(parsePaise('9.99'), 999);
      expect(parsePaise(''), 0);
      expect(parsePaise('   '), 0);
      expect(parsePaise('0'), 0);
      expect(parsePaise('-1'), -1);
      expect(parsePaise('lots'), -1);
    });

    test('percents scale to basis points with 0..100 guard', () {
      expect(parsePercentBps('10'), 1000);
      expect(parsePercentBps('2.5'), 250);
      expect(parsePercentBps(''), 0);
      expect(parsePercentBps('0'), 0);
      expect(parsePercentBps('100'), 10000);
      expect(parsePercentBps('100.01'), -1);
      expect(parsePercentBps('-5'), -1);
      expect(parsePercentBps('half'), -1);
    });
  });
}
