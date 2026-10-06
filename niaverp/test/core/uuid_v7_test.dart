// UUIDv7 generator tests (D-M4: UUIDv7 text IDs).
// Pure-Dart unit tests, no device. Proves: canonical lowercase shape,
// version (7) and variant (10xx) bits in text and raw bytes, strict ordering
// within one millisecond (monotonic counter) and across milliseconds, and
// uniqueness over 10,000 values from a fixed clock.
// Traceability: D-M4; D1 (C1/C2).

import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/core/clock.dart';
import 'package:niaverp/core/uuid_v7.dart';

void main() {
  group('UuidV7 (D-M4)', () {
    test('emits canonical lowercase text with version 7 and variant bits', () {
      final UuidV7 gen = UuidV7(
        clock: TestClock(1700000000000),
        random: Random(7),
      );
      final String id = gen.next();
      expect(UuidV7.isCanonicalV7(id), isTrue);
      expect(id, id.toLowerCase());
      expect(id, hasLength(36));
      // Version nibble is the first char of the third group.
      expect(id[14], '7');
      // Variant field is the first char of the fourth group: 8/9/a/b.
      expect('89ab'.contains(id[19]), isTrue);
    });

    test('raw bytes carry the version and variant in the right octets', () {
      final UuidV7 gen = UuidV7(
        clock: TestClock(1700000000000),
        random: Random(7),
      );
      final Uint8List b = gen.nextBytes();
      expect(b, hasLength(16));
      expect(b[6] >> 4, 0x7);
      expect(b[8] >> 6, 0x2);
    });

    test('successive ids in one millisecond are strictly increasing', () {
      final TestClock clock = TestClock(1700000000000);
      final UuidV7 gen = UuidV7(clock: clock, random: Random(11));
      String prev = gen.next();
      for (int i = 0; i < 100; i++) {
        final String next = gen.next();
        expect(next.compareTo(prev) > 0, isTrue, reason: '$prev -> $next');
        prev = next;
      }
    });

    test('a later millisecond sorts after earlier ids', () {
      final TestClock clock = TestClock(1700000000000);
      final UuidV7 gen = UuidV7(clock: clock, random: Random(11));
      final String first = gen.next();
      clock.advanceBy(1);
      final String second = gen.next();
      expect(second.compareTo(first) > 0, isTrue);
    });

    test('10,000 ids from a fixed clock are unique and canonical', () {
      final UuidV7 gen = UuidV7(
        clock: TestClock(1700000000000),
        random: Random(99),
      );
      final Set<String> seen = <String>{};
      String prev = '';
      for (int i = 0; i < 10000; i++) {
        final String id = gen.next();
        expect(UuidV7.isCanonicalV7(id), isTrue, reason: 'index $i');
        expect(seen.add(id), isTrue, reason: 'duplicate at index $i');
        if (prev.isNotEmpty) {
          expect(id.compareTo(prev) > 0, isTrue);
        }
        prev = id;
      }
      expect(seen, hasLength(10000));
    });

    test('a zero random source still yields well-formed monotonic ids', () {
      Uint8List zeroes(int length) => Uint8List(length);
      final UuidV7 gen = UuidV7(
        clock: TestClock(1700000000000),
        randomBytes: zeroes,
      );
      final String first = gen.next();
      final String second = gen.next();
      expect(UuidV7.isCanonicalV7(first), isTrue);
      expect(UuidV7.isCanonicalV7(second), isTrue);
      expect(first == second, isFalse);
    });
  });
}
