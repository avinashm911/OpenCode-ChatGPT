// Fixture tests: voucher-line discounts — Phase 2.
// Fixture IDs F-DISC-001…006. Expectations hand-computed and frozen.
// Calculation rule (PROPOSED for Phase 2 confirmation, implemented in
// validators.dart): explicit positive amount wins over rate; otherwise rate
// bps with round-half-up; net floored at zero. Tax-base rule (PROPOSED):
// taxable value = gross − discount; GST computed on the net base.
// Traceability: G0-SCH-007 (G1); FRD voucher lines; D-M4.

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/data/accounting/gst.dart';
import 'package:niaverp/data/migrations/validators.dart';

void main() {
  group('F-DISC-001 explicit amount behavior', () {
    test('Rs100 gross minus Rs10 amount discount = Rs90 net', () {
      // gross = lineAmount(20000, 5000): 2 units × Rs50 = Rs100 → 10000p.
      final int gross = lineAmount(20000, 5000);
      expect(gross, 10000);
      expect(discountFor(gross, 1000, 0), 1000);
      expect(lineNet(gross, 1000, 0), 9000);
    });
  });

  group('F-DISC-002 percentage behavior (10%)', () {
    test('10% of Rs100 = Rs10 discount', () {
      // 10000 × 1000 / 10⁴ = 1000.0 → 1000.
      expect(discountFor(10000, 0, 1000), 1000);
      expect(lineNet(10000, 0, 1000), 9000);
    });
  });

  group('F-DISC-003 amount wins over rate', () {
    test('explicit Rs15 beats 10% rate on Rs100', () {
      expect(discountFor(10000, 1500, 1000), 1500);
      expect(lineNet(10000, 1500, 1000), 8500);
    });
  });

  group('F-DISC-004 discount rounding boundary', () {
    test('2.5p rate discount becomes 3p (half-up)', () {
      // 25 × 1000 / 10⁴ = 2.5 → 3.
      expect(discountFor(25, 0, 1000), 3);
    });
  });

  group('F-DISC-005 discount never pays out', () {
    test('oversize discount clamps net at zero', () {
      expect(lineNet(1000, 5000, 0), 0);
    });
  });

  group('F-DISC-006 tax base impact (PROPOSED: tax on net)', () {
    test('Rs100 − 10% → taxable Rs90 → GST 18% = Rs16.20', () {
      const int gross = 10000;
      final int discount = discountFor(gross, 0, 1000);
      final int taxable = lineNet(gross, 0, 1000);
      // 9000 × 1800 / 10⁴ = 1620.0 → 1620.
      final int tax = gstTotal(taxable, 1800);
      expect(discount, 1000);
      expect(taxable, 9000);
      expect(tax, 1620);
      expect(taxable + tax, 10620);
    });
  });
}
