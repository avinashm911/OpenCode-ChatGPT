// Host tests: release-delivery checksum contract — Phase 6.
// SHA-256 computation + verification + approved-channel list.
// Computing a hash locally proves nothing about WhatsApp/email/hosted-link
// delivery — channel rows stay PENDING-INPUT until captured.
// Traceability: R-04; G0-VER-004 (G5).

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/data/print/release_delivery.dart';

void main() {
  group('approved channels (fixed)', () {
    test('exactly the three approved channels', () {
      expect(kApprovedChannels, <String>[
        'WhatsApp/email',
        'ZIP fallback',
        'Rs0 hosted link',
      ]);
    });
  });

  group('SHA-256 contract (golden vector)', () {
    test('SHA-256("abc") matches the FIPS vector', () {
      // Well-known test vector; proves the hash function, not any delivery.
      expect(
        sha256HexBytes('abc'.codeUnits),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
    });
    test('verifyPayload accepts exact match, rejects tamper', () {
      const String good =
          'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad';
      expect(verifyPayload('abc'.codeUnits, good), isTrue);
      expect(verifyPayload('abd'.codeUnits, good), isFalse);
      expect(verifyPayload('abc'.codeUnits, good.toUpperCase()), isTrue);
    });
    test('different payloads hash differently (64-hex stable)', () {
      final String h1 = sha256HexBytes('apk-bytes-v1'.codeUnits);
      final String h2 = sha256HexBytes('apk-bytes-v2'.codeUnits);
      expect(h1.length, 64);
      expect(h2.length, 64);
      expect(h1 == h2, isFalse);
    });
  });
}
