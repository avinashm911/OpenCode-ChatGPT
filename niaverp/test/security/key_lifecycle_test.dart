// Tests: key lifecycle + failure safety + no-secret logging — Phase 3.
// Traceability: D-06; G0-VER-001/005 (wiring/evidence pending — contract only).

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/data/security/key_lifecycle.dart';

Uint8List _keyBytes() => Uint8List.fromList(List<int>.generate(32, (int i) => i));

void main() {
  group('DbKey shape (D-06: 256-bit)', () {
    test('accepts 32 bytes, rejects other lengths', () {
      expect(DbKey(_keyBytes()).bytes.length, 32);
      expect(() => DbKey(Uint8List(16)), throwsArgumentError);
      expect(() => DbKey(Uint8List(0)), throwsArgumentError);
    });

    test('no secrets are logged: string forms never carry key bytes', () {
      final DbKey key = DbKey(_keyBytes());
      final String hexOfKey = key.bytes
          .map((int b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      expect(key.toString().contains(hexOfKey), isFalse);
      expect(key.debugDescribe().contains(hexOfKey), isFalse);
      expect(key.toString(), contains('redacted'));
    });
  });

  group('lifecycle transitions', () {
    test('provision → available → lock → unlock', () {
      final KeyLifecycle lc = KeyLifecycle();
      expect(lc.canUseKey, isFalse);
      expect(lc.provision().isOk, isTrue);
      expect(lc.canUseKey, isTrue);
      lc.lock();
      expect(lc.canUseKey, isFalse);
      expect(lc.unlock(deviceAuthPassed: true).isOk, isTrue);
      expect(lc.canUseKey, isTrue);
    });

    test('failed auth keeps the key unusable', () {
      final KeyLifecycle lc = KeyLifecycle()..provision()..lock();
      final KeyResult r = lc.unlock(deviceAuthPassed: false);
      expect(r.isOk, isFalse);
      expect(r.failure, KeyFailure.authFailed);
      expect(lc.canUseKey, isFalse);
    });

    test('uninstall wipe returns to missing (re-provision required)', () {
      final KeyLifecycle lc = KeyLifecycle()..provision();
      final KeyResult r = lc.reportFailure(KeyFailure.wipedByUninstall);
      expect(r.failure, KeyFailure.wipedByUninstall);
      expect(lc.state, KeyState.missing);
      expect(lc.canUseKey, isFalse);
      expect(lc.provision().isOk, isTrue); // only path back
    });

    test('corrupt wrapper fails safely with no plaintext fallback', () {
      final KeyLifecycle lc = KeyLifecycle()..provision();
      final KeyResult r = lc.reportFailure(KeyFailure.corruptWrapper);
      expect(r.isOk, isFalse);
      expect(lc.state, KeyState.failed);
      expect(lc.canUseKey, isFalse);
    });

    test('keystore outage is reported, never bypassed', () {
      final KeyLifecycle lc = KeyLifecycle();
      final KeyResult r = lc.reportFailure(KeyFailure.keystoreUnavailable);
      expect(r.failure, KeyFailure.keystoreUnavailable);
      expect(lc.canUseKey, isFalse);
    });

    test('failure strings carry no key material', () {
      final KeyLifecycle lc = KeyLifecycle()..provision();
      for (final KeyFailure f in KeyFailure.values) {
        final KeyResult r = lc.reportFailure(f);
        expect(r.toString().contains('Uint8List'), isFalse);
        expect(r.message.length < 200, isTrue);
      }
    });
  });
}
