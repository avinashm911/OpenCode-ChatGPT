// Channel key-provider mapping tests (D-06 / D1-A2, host-side).
// A fake MethodChannel stands in for MainActivity.kt: proves the Dart side
// projects every platform reply onto the key lifecycle with codes only —
// never key bytes in errors, never a usable key from a malformed reply, and
// never a recovery path. On-device Keystore behaviour stays G0-VER-005
// evidence; these host runs are not device evidence.
// Traceability: D-06; G0-VER-005; P-SQLIB/P-KEYSTORE; D1 (A2).

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:niaverp/data/db/key_provider.dart';
import 'package:niaverp/data/security/key_lifecycle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel =
      MethodChannel(ChannelKeyProvider.kKeyChannelName);

  Map<String, Object?>? nextReply;
  PlatformException? nextError;
  bool noPlugin = false;

  setUp(() {
    nextReply = null;
    nextError = null;
    noPlugin = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      if (noPlugin || call.method != 'getDatabaseKey') {
        throw MissingPluginException();
      }
      if (nextError != null) throw nextError!;
      return nextReply;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Uint8List key32() =>
      Uint8List.fromList(List<int>.generate(32, (int i) => i));

  group('ChannelKeyProvider.obtainKey (D1-A2)', () {
    test('available with 32 bytes yields the key and opens the gate', () async {
      nextReply = <String, Object?>{'state': 'available', 'key': key32()};
      final ChannelKeyProvider provider = ChannelKeyProvider(channel: channel);
      final ChannelKeyResult result = await provider.obtainKey();
      expect(result.hasKey, isTrue);
      expect(result.bytes, key32());
      expect(provider.canOpenDatabase, isTrue);
    });

    test('missing yields no key and denies the gate', () async {
      nextReply = const <String, Object?>{
        'state': 'missing',
        'failure': 'wipedByUninstall'
      };
      final ChannelKeyProvider provider = ChannelKeyProvider(channel: channel);
      final ChannelKeyResult result = await provider.obtainKey();
      expect(result.hasKey, isFalse);
      expect(provider.state, KeyState.missing);
      expect(provider.canOpenDatabase, isFalse);
    });

    test('locked yields no key and a failed result (no recovery API)', () async {
      nextReply = const <String, Object?>{'state': 'locked'};
      final ChannelKeyProvider provider = ChannelKeyProvider(channel: channel);
      final ChannelKeyResult result = await provider.obtainKey();
      expect(result.hasKey, isFalse);
      expect(result.failure, KeyFailure.authFailed);
      expect(provider.canOpenDatabase, isFalse);
    });

    test('failed maps the platform code and denies the gate', () async {
      nextReply = const <String, Object?>{
        'state': 'failed',
        'failure': 'corruptWrapper'
      };
      final ChannelKeyProvider provider = ChannelKeyProvider(channel: channel);
      final ChannelKeyResult result = await provider.obtainKey();
      expect(result.hasKey, isFalse);
      expect(result.failure, KeyFailure.corruptWrapper);
      expect(provider.state, KeyState.failed);
      expect(provider.canOpenDatabase, isFalse);
    });

    test('malformed replies are corrupt wrappers, never usable keys', () async {
      final ChannelKeyProvider provider = ChannelKeyProvider(channel: channel);
      // Available without key bytes.
      nextReply = const <String, Object?>{'state': 'available'};
      expect((await provider.obtainKey()).failure, KeyFailure.corruptWrapper);
      // Wrong key length.
      nextReply = <String, Object?>{
        'state': 'available',
        'key': Uint8List(31),
      };
      final ChannelKeyProvider second = ChannelKeyProvider(channel: channel);
      final ChannelKeyResult short = await second.obtainKey();
      expect(short.hasKey, isFalse);
      expect(short.failure, KeyFailure.corruptWrapper);
      // Unknown state word.
      nextReply = const <String, Object?>{'state': 'present'};
      final ChannelKeyProvider third = ChannelKeyProvider(channel: channel);
      expect((await third.obtainKey()).failure, KeyFailure.corruptWrapper);
      expect(third.canOpenDatabase, isFalse);
    });

    test('transport faults become codes, never throws', () async {
      final ChannelKeyProvider provider = ChannelKeyProvider(channel: channel);
      nextError = PlatformException(code: 'authFailed');
      expect((await provider.obtainKey()).failure, KeyFailure.authFailed);
      noPlugin = true;
      nextError = null;
      final ChannelKeyProvider second = ChannelKeyProvider(channel: channel);
      expect((await second.obtainKey()).failure,
          KeyFailure.keystoreUnavailable);
    });
  });
}
