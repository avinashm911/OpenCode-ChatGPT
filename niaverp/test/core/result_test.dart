// Phase 00 tests: Result/error model.
// Traceability: AGENTS.md (Result/error model); strategy Slice 0.

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/core/result.dart';

void main() {
  group('Result ok/err', () {
    test('ok carries value and reports isOk', () {
      const Result<int> r = Ok<int>(7);
      expect(r.isOk, isTrue);
      expect(r.isErr, isFalse);
      expect((r as Ok<int>).value, 7);
    });

    test('err carries code/message and reports isErr', () {
      const Result<int> r = Err<int>(AppError('locked', 'period locked'));
      expect(r.isErr, isTrue);
      expect(r.isOk, isFalse);
      expect((r as Err<int>).error.code, 'locked');
    });

    test('mapResult transforms Ok and passes Err through', () {
      expect(mapResult<int, int>(ok(3), (int v) => v * 2), isA<Ok<int>>());
      expect(
        (mapResult<int, int>(ok(3), (int v) => v * 2) as Ok<int>).value,
        6,
      );
      const Result<int> e = Err<int>(AppError('x', 'y'));
      final Result<int> mapped = mapResult<int, int>(e, (int v) => v);
      expect(mapped, isA<Err<int>>());
      expect((mapped as Err<int>).error.code, 'x');
    });
  });
}
