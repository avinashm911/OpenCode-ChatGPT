// NiAvERP key-provider interface — implementation Phase 01, production wiring
// in D1.
// Bridges the approved D-06 key lifecycle (see
// lib/data/security/key_lifecycle.dart) and database bootstrap: the database
// opens only while a usable wrapped key exists. Failures carry codes only —
// never key bytes.
// [ChannelKeyProvider] is the production implementation: a Kotlin
// MethodChannel (MainActivity.kt) generates a random 32-byte database key,
// wraps it with an Android Keystore AES-GCM key and returns the plaintext key
// bytes only over that channel, in memory, for the open. The provider never
// logs them and never exposes a recovery path (a wiped Keystore key means
// re-provisioning, per key_lifecycle.dart). Android 8 / real-device behaviour
// of that channel is G0-VER-005 evidence and is NOT claimed by host tests.
// Traceability: D-06; G0-VER-001/005; P-SQLIB/P-KEYSTORE; D1 (A1/A2).

import 'package:flutter/services.dart';
import 'package:niaverp/core/result.dart';
import 'package:niaverp/data/security/key_lifecycle.dart';

/// Supplies the database key gate for bootstrap. Production implementations
/// wrap [KeyLifecycle] over the Android Keystore; tests supply a scripted
/// lifecycle. There is deliberately no recovery API (see key_lifecycle.dart).
abstract class KeyProvider {
  /// Current lifecycle (missing/available/locked/failed).
  KeyState get state;

  /// True only when the database may be opened with the wrapped key.
  bool get canOpenDatabase;

  /// Report a platform failure through the lifecycle; returns the
  /// failure code for the caller to record. Never carries key material.
  Result<void> reportFailure(KeyFailure failure);
}

/// Key provider driven directly by a [KeyLifecycle]. Used by tests and by
/// the future Keystore-backed provider, which will own the lifecycle object.
class LifecycleKeyProvider implements KeyProvider {
  LifecycleKeyProvider(this.lifecycle);

  final KeyLifecycle lifecycle;

  @override
  KeyState get state => lifecycle.state;

  @override
  bool get canOpenDatabase => lifecycle.canUseKey;

  @override
  Result<void> reportFailure(KeyFailure failure) {
    final KeyResult r = lifecycle.reportFailure(failure);
    if (r.isOk) return ok(null);
    return err<void>(r.failure!.name, r.message);
  }
}

/// Outcome of asking the platform for the wrapped database key.
class ChannelKeyResult {
  const ChannelKeyResult.missing() : bytes = null, failure = null;
  const ChannelKeyResult.available(this.bytes) : failure = null;
  const ChannelKeyResult.failed(this.failure) : bytes = null;

  /// Plaintext key bytes, present only for [available]. The caller owns them
  /// for the duration of the database open and must not log or store them.
  final Uint8List? bytes;
  final KeyFailure? failure;

  bool get hasKey => bytes != null;
}

/// Production [KeyProvider] over the Android Keystore MethodChannel.
///
/// The channel contract (see MainActivity.kt):
///   method `getDatabaseKey` → map with
///     `state`: one of `missing` | `available` | `locked` | `failed`
///     `key`:   32 raw bytes (present only when state is `available`)
///     `failure`: one of `keystoreUnavailable` | `authFailed` |
///                `corruptWrapper` | `wipedByUninstall` (when state is
///                `failed` or `missing` after a wipe)
/// A `locked` state returns no key and no recovery: the caller surfaces the
/// locked state, and only a fresh platform unlock (device auth) can change it.
/// A malformed reply is treated as `failed` with [KeyFailure.corruptWrapper] —
/// never as a usable key. No code path here logs the bytes or includes them in
/// an error message.
class ChannelKeyProvider implements KeyProvider {
  ChannelKeyProvider({
    MethodChannel? channel,
    KeyLifecycle? lifecycle,
  })  : channel = channel ?? const MethodChannel(kKeyChannelName),
        lifecycle = lifecycle ?? KeyLifecycle();

  /// Channel name shared with MainActivity.kt.
  static const String kKeyChannelName = 'com.niaverp.niaverp/keystore';

  final MethodChannel channel;

  /// The D-06 lifecycle this provider drives; the channel reply is projected
  /// onto its states so the rest of the app sees one vocabulary.
  final KeyLifecycle lifecycle;

  @override
  KeyState get state => lifecycle.state;

  @override
  bool get canOpenDatabase => lifecycle.canUseKey;

  @override
  Result<void> reportFailure(KeyFailure failure) {
    final KeyResult r = lifecycle.reportFailure(failure);
    if (r.isOk) return ok(null);
    return err<void>(r.failure!.name, r.message);
  }

  /// Ask the platform for the key and project the reply onto [lifecycle].
  /// Never throws: transport and protocol errors become a `failed` lifecycle
  /// with a code, because there is no plaintext fallback and no recovery API.
  Future<ChannelKeyResult> obtainKey() async {
    Map<Object?, Object?>? reply;
    try {
      reply = await channel.invokeMethod<Map<Object?, Object?>>(
        'getDatabaseKey',
      );
    } on MissingPluginException {
      lifecycle.reportFailure(KeyFailure.keystoreUnavailable);
      return const ChannelKeyResult.failed(KeyFailure.keystoreUnavailable);
    } on PlatformException catch (e) {
      final KeyFailure failure = _failureFromCode(e.code);
      lifecycle.reportFailure(failure);
      return ChannelKeyResult.failed(failure);
    }
    return _interpret(reply);
  }

  /// Project one channel reply onto the lifecycle. Exposed (package-visible by
  /// test construction) so the state machine can be proven without a device.
  ChannelKeyResult _interpret(Map<Object?, Object?>? reply) {
    if (reply == null) {
      lifecycle.reportFailure(KeyFailure.keystoreUnavailable);
      return const ChannelKeyResult.failed(KeyFailure.keystoreUnavailable);
    }
    final Object? rawState = reply['state'];
    final Object? rawKey = reply['key'];
    final Object? rawFailure = reply['failure'];
    final String stateText = rawState is String ? rawState : '';
    switch (stateText) {
      case 'missing':
        lifecycle.reportFailure(
            rawFailure == null ? KeyFailure.wipedByUninstall : _failureFromCode('$rawFailure'));
        return const ChannelKeyResult.missing();
      case 'locked':
        lifecycle.lock();
        return const ChannelKeyResult.failed(KeyFailure.authFailed);
      case 'failed':
        lifecycle.reportFailure(
            rawFailure == null ? KeyFailure.keystoreUnavailable : _failureFromCode('$rawFailure'));
        return ChannelKeyResult.failed(
            rawFailure == null ? KeyFailure.keystoreUnavailable : _failureFromCode('$rawFailure'));
      case 'available':
        final Uint8List? bytes = _asKeyBytes(rawKey);
        if (bytes == null) {
          // A reply that claims a key but carries none (or a wrong length) is
          // a corrupt wrapper, never a usable key and never a fallback.
          lifecycle.reportFailure(KeyFailure.corruptWrapper);
          return const ChannelKeyResult.failed(KeyFailure.corruptWrapper);
        }
        final KeyResult unlocked = lifecycle.unlock(deviceAuthPassed: true);
        if (!unlocked.isOk) {
          return ChannelKeyResult.failed(unlocked.failure!);
        }
        return ChannelKeyResult.available(bytes);
      default:
        lifecycle.reportFailure(KeyFailure.corruptWrapper);
        return const ChannelKeyResult.failed(KeyFailure.corruptWrapper);
    }
  }

  /// Key bytes arrive as `Uint8List` (standard codec) or as a `List<int>`.
  /// Only exactly 32 bytes are accepted (D-06, 256-bit).
  static Uint8List? _asKeyBytes(Object? raw) {
    if (raw is Uint8List) {
      return raw.length == 32 ? raw : null;
    }
    if (raw is List<int>) {
      if (raw.length != 32) return null;
      bool allByte = true;
      for (final int b in raw) {
        if (b < 0 || b > 255) {
          allByte = false;
          break;
        }
      }
      if (!allByte) return null;
      return Uint8List.fromList(raw);
    }
    return null;
  }

  static KeyFailure _failureFromCode(String code) {
    switch (code) {
      case 'authFailed':
        return KeyFailure.authFailed;
      case 'corruptWrapper':
        return KeyFailure.corruptWrapper;
      case 'wipedByUninstall':
        return KeyFailure.wipedByUninstall;
      case 'keystoreUnavailable':
      default:
        return KeyFailure.keystoreUnavailable;
    }
  }
}
