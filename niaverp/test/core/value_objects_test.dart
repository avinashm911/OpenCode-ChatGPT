// Phase 00 tests: typed value objects + test clock.
// D-M4 fixtures are hand-computed below and frozen; the implementation must
// satisfy them, never the reverse.
// Traceability: D-M4/OD-DB-001; DECISIONS.md (D-M4).

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/core/clock.dart';
import 'package:niaverp/core/value_objects/ids.dart';
import 'package:niaverp/core/value_objects/money.dart';
import 'package:niaverp/core/value_objects/niav_date.dart';
import 'package:niaverp/core/value_objects/quantity.dart';

void main() {
  group('MoneyPaise (integer paise, D-M4)', () {
    test('stores raw paise and renders ≤2 decimals', () {
      expect(const MoneyPaise(10000).paise, 10000);
      expect(const MoneyPaise(10000).toRupeesString(), '100.00');
      expect(const MoneyPaise(5).toRupeesString(), '0.05');
      expect(const MoneyPaise(-50).toRupeesString(), '-0.50');
      expect(MoneyPaise.zero.toRupeesString(), '0.00');
    });

    test('addition is integer-exact', () {
      expect(
        (const MoneyPaise(999) + const MoneyPaise(1)).paise,
        1000,
      );
    });
  });

  group('QuantityQ4 (integer ×10^4, D-M4)', () {
    test('stores raw q4 and formats with explicit scale', () {
      expect(const QuantityQ4(10000).q4, 10000);
      expect(const QuantityQ4(10000).format(), '1.0000');
      expect(const QuantityQ4(2500).format(fractionDigits: 3), '0.250');
      expect(const QuantityQ4(10000).format(fractionDigits: 0), '1');
    });

    test('rejects out-of-range scales', () {
      expect(() => const QuantityQ4(1).format(fractionDigits: 5), throwsArgumentError);
    });
  });

  group('EntityId / CompanyId (UUIDv7 text, app-generated)', () {
    test('accepts non-empty ids, keeps company scope distinct', () {
      final EntityId e = EntityId('0193f123-0000-7000-8000-000000000001');
      final CompanyId c = CompanyId('0193f123-0000-7000-8000-000000000002');
      expect(e.value, isNotEmpty);
      expect(c.value, isNotEmpty);
      expect(e.runtimeType == c.runtimeType, isFalse);
    });

    test('rejects empty ids', () {
      expect(() => EntityId(''), throwsArgumentError);
      expect(() => CompanyId(''), throwsArgumentError);
    });
  });

  group('NiavDate (ISO YYYY-MM-DD)', () {
    test('accepts calendar dates, rejects other shapes', () {
      expect(NiavDate('2026-04-01').iso, '2026-04-01');
      expect(() => NiavDate('01-04-2026'), throwsArgumentError);
      expect(() => NiavDate(''), throwsArgumentError);
    });
  });

  group('TestClock determinism', () {
    test('fixed start and explicit advance', () {
      final TestClock clock = TestClock(1000);
      expect(clock.nowMs(), 1000);
      clock.advanceBy(500);
      expect(clock.nowMs(), 1500);
    });
  });
}
