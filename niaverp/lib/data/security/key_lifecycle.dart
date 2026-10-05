// NiAvERP G0 key lifecycle — Phase 3.
// Dart-side contract for the APPROVED D-06 shape (random 256-bit DB key,
// wrapped by Android Keystore, PIN/biometric gates key use). The native
// Keystore wiring and the SQLCipher-class library stay BLOCKED (G0-VER-001 /
// G0-VER-005); this file defines states, failure handling and the
// no-plaintext-export invariant so behavior is frozen before wiring lands.
// There is deliberately NO recovery/escrow API: a wiped key is gone and the
// only path is re-provisioning (see backup.dart restore plan).

import 'dart:typed_data';

/// 256-bit database key (D-06). Key bytes never appear in logs: [toString]
/// and [debugDescribe] are redacted by construction.
class DbKey {
  DbKey(this.bytes) {
    if (bytes.length != 32) {
      throw ArgumentError('DB key must be 32 bytes (256-bit, D-06)');
    }
  }
  final Uint8List bytes;

  @override
  String toString() => 'DbKey(<redacted 256-bit>)';

  String debugDescribe() => 'DbKey(<redacted 256-bit>)';
}

/// Lifecycle states of the wrapped DB key on one install.
enum KeyState { missing, available, locked, failed }

/// Keystore failures, mapped to safe handling (never plaintext fallback).
enum KeyFailure {
  /// Keystore service unreachable / hardware absent.
  keystoreUnavailable,

  /// PIN/biometric gate rejected the unlock.
  authFailed,

  /// Wrapped blob present but undecryptable (tamper/version skew).
  corruptWrapper,

  /// Uninstall/reinstall wiped Keystore keys (expected Android behavior).
  wipedByUninstall,
}

/// Outcome of a key operation. Failures carry only the enum + a static
/// message — never key material.
class KeyResult {
  const KeyResult.ok() : failure = null, message = 'ok';
  const KeyResult.fail(this.failure, this.message);

  final KeyFailure? failure;
  final String message;

  bool get isOk => failure == null;

  @override
  String toString() =>
      isOk ? 'KeyResult(ok)' : 'KeyResult(fail:$failure)';
}

/// Dart-side lifecycle for the wrapped DB key.
class KeyLifecycle {
  KeyLifecycle() : state = KeyState.missing;

  KeyState state;
  KeyFailure? lastFailure;

  /// First provision (or re-provision after wipe/failure): stores the
  /// Keystore-wrapped key and makes it usable. Raw bytes are held only by
  /// the platform vault, never by this object.
  KeyResult provision() {
    state = KeyState.available;
    lastFailure = null;
    return const KeyResult.ok();
  }

  /// Lock on background/timeout: key use requires fresh device auth.
  void lock() {
    if (state == KeyState.available) state = KeyState.locked;
  }

  /// Unlock gate: [deviceAuthPassed] is the platform PIN/biometric verdict.
  KeyResult unlock({required bool deviceAuthPassed}) {
    if (state != KeyState.locked && state != KeyState.failed) {
      return const KeyResult.ok();
    }
    if (!deviceAuthPassed) {
      state = KeyState.failed;
      lastFailure = KeyFailure.authFailed;
      return const KeyResult.fail(
          KeyFailure.authFailed, 'device auth rejected; key stays unusable');
    }
    state = KeyState.available;
    lastFailure = null;
    return const KeyResult.ok();
  }

  /// Report a platform failure. The key becomes unusable; there is no
  /// fallback path that yields plaintext.
  KeyResult reportFailure(KeyFailure failure) {
    state = failure == KeyFailure.wipedByUninstall
        ? KeyState.missing
        : KeyState.failed;
    lastFailure = failure;
    switch (failure) {
      case KeyFailure.keystoreUnavailable:
        return const KeyResult.fail(KeyFailure.keystoreUnavailable,
            'keystore unavailable; key unusable until service returns');
      case KeyFailure.authFailed:
        return const KeyResult.fail(KeyFailure.authFailed,
            'device auth rejected; key stays unusable');
      case KeyFailure.corruptWrapper:
        return const KeyResult.fail(KeyFailure.corruptWrapper,
            'wrapped key undecryptable; re-provision required');
      case KeyFailure.wipedByUninstall:
        return const KeyResult.fail(KeyFailure.wipedByUninstall,
            'keystore wiped by reinstall; re-provision required');
    }
  }

  /// True only when the key may be used for DB open. Every other state
  /// denies silently-safe (no exception text carries secrets).
  bool get canUseKey => state == KeyState.available;
}
