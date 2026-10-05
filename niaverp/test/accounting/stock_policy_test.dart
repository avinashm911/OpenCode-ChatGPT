// Prompt-06 tests: negative-stock policy vocabulary (FR-M13-001).
// Pure domain tests (no database): strict parsing plus the allow/warn/block
// decision matrix over integer ×10⁴ arithmetic.
// Traceability: FR-M13-001 (policy explicit before posting); D-M5(4).

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/data/accounting/stock_policy.dart';

void main() {
  group('stock policy (FR-M13-001)', () {
    test('parses exactly allow/warn/block', () {
      expect(parseStockPolicy('allow'), StockPolicy.allow);
      expect(parseStockPolicy('warn'), StockPolicy.warn);
      expect(parseStockPolicy('block'), StockPolicy.block);
    });

    test('rejects unknown policy text (invalid cases)', () {
      for (final String bad in <String>['', 'Allow', 'WARN', 'yes', ' allow']) {
        expect(() => parseStockPolicy(bad), throwsArgumentError);
      }
    });

    test('allow always approves without warning', () {
      const StockCheck c =
          StockCheck(approved: true, warning: false); // shape guard
      expect(c.approved, isTrue);
      final StockCheck r = checkStockMove(
        policy: StockPolicy.allow,
        onHandQ4: 10000,
        moveQ4: -50000,
      );
      expect(r.approved, isTrue);
      expect(r.warning, isFalse);
    });

    test('warn approves, warning only when driven negative', () {
      final StockCheck ok = checkStockMove(
        policy: StockPolicy.warn,
        onHandQ4: 50000,
        moveQ4: -20000,
      );
      expect(ok.approved, isTrue);
      expect(ok.warning, isFalse);
      final StockCheck exact = checkStockMove(
        policy: StockPolicy.warn,
        onHandQ4: 50000,
        moveQ4: -50000,
      );
      expect(exact.approved, isTrue);
      expect(exact.warning, isFalse);
      final StockCheck neg = checkStockMove(
        policy: StockPolicy.warn,
        onHandQ4: 50000,
        moveQ4: -50001,
      );
      expect(neg.approved, isTrue);
      expect(neg.warning, isTrue);
    });

    test('block denies only negative landings', () {
      final StockCheck ok = checkStockMove(
        policy: StockPolicy.block,
        onHandQ4: 50000,
        moveQ4: -50000,
      );
      expect(ok.approved, isTrue);
      expect(ok.warning, isFalse);
      final StockCheck denied = checkStockMove(
        policy: StockPolicy.block,
        onHandQ4: 50000,
        moveQ4: -50001,
      );
      expect(denied.approved, isFalse);
      expect(denied.warning, isFalse);
    });

    test('inward moves approve; warning follows the landing balance', () {
      for (final StockPolicy p in StockPolicy.values) {
        // Still negative after the inward move: warn approves with warning,
        // allow approves silently, block denies (any negative landing).
        final StockCheck stillNeg = checkStockMove(
          policy: p,
          onHandQ4: -10000,
          moveQ4: 5000,
        );
        expect(stillNeg.approved, p != StockPolicy.block);
        expect(stillNeg.warning, p == StockPolicy.warn);
        // Resolved to non-negative: no warning under any policy.
        final StockCheck resolved = checkStockMove(
          policy: p,
          onHandQ4: -10000,
          moveQ4: 15000,
        );
        expect(resolved.approved, isTrue);
        expect(resolved.warning, isFalse);
      }
    });
  });
}
