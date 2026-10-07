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
      expect(parseQuantityQ4('1.12345'), -1); // >4 decimals rejected
    });

    test('rupees scale to paise, empty is zero, invalid yields -1', () {
      expect(parsePaise('50'), 5000);
      expect(parsePaise('9.99'), 999);
      expect(parsePaise(''), 0);
      expect(parsePaise('   '), 0);
      expect(parsePaise('0'), 0);
      expect(parsePaise('-1'), -1);
      expect(parsePaise('lots'), -1);
      expect(parsePaise('9.999'), -1); // >2 decimals rejected
      expect(parsePaise('10.1'), 1010);
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

    test('quantities below one unit parse (total decides, not whole part)', () {
      expect(parseQuantityQ4('0.5'), 5000);
      expect(parseQuantityQ4('0.0001'), 1);
      expect(parseQuantityQ4('.5'), 5000);
      expect(parseQuantityQ4('1.5'), 15000);
      expect(parseQuantityQ4('100'), 1000000);
      expect(parseQuantityQ4('0.00001'), -1); // >4 decimals rejected
      expect(parseQuantityQ4('5.'), -1); // malformed
      expect(parseQuantityQ4('1e3'), -1); // no exponents
      expect(parseQuantityQ4('0.0000'), -1); // total is zero
      expect(parseQuantityQ4('99999999999999999999'), -1); // overflow-safe
      expect(parseQuantityQ4('99999999999999999999.9999'), -1); // overflow-safe
    });

    test('paise edge cases (total decides; .5 counts)', () {
      expect(parsePaise('0.50'), 50);
      expect(parsePaise('.5'), 50);
      expect(parsePaise('0.05'), 5);
      expect(parsePaise('100.00'), 10000);
      expect(parsePaise('100.01'), 10001);
      expect(parsePaise('5.'), -1);
      expect(parsePaise('99999999999999999999'), -1); // overflow-safe
    });

    test('percent edge cases (.5 counts; cap holds)', () {
      expect(parsePercentBps('.5'), 50);
      expect(parsePercentBps('0.05'), 5);
      expect(parsePercentBps('100.00'), 10000);
      expect(parsePercentBps('100.01'), -1);
      expect(parsePercentBps('5.'), -1);
    });

    test('non-finite, exponent and oversized inputs are rejected', () {
      // double.tryParse accepts all of these — the integer parser must not.
      for (final String bad in <String>[
        '1e5',
        '1E5',
        '1e-3',
        'Infinity',
        '-Infinity',
        'NaN',
        '99999999999999999999999',
        '99999999999999999999999.9999',
      ]) {
        expect(parseQuantityQ4(bad), -1, reason: 'qty $bad');
        expect(parsePaise(bad), -1, reason: 'paise $bad');
      }
      // Empty quantity is invalid; empty money counts as zero (unchanged).
      expect(parseQuantityQ4(''), -1);
      expect(parseQuantityQ4('   '), -1);
      expect(parsePaise(''), 0);
      expect(parsePaise('   '), 0);
      // 1.005: too many decimals for rupees, fine for quantity (3 <= 4).
      expect(parsePaise('1.005'), -1);
      expect(parseQuantityQ4('1.005'), 10050);
      // 0.29 parses in both.
      expect(parsePaise('0.29'), 29);
      expect(parseQuantityQ4('0.29'), 2900);
    });
  });
}
