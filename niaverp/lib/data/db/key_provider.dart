// NiAvERP key-provider interface — implementation Phase 01.
// Bridges the approved D-06 key lifecycle (see
// lib/data/security/key_lifecycle.dart) and database bootstrap: the database
// opens only while a usable wrapped key exists. Native Keystore wiring stays
// BLOCKED (G0-VER-005, P-KEYSTORE); this file defines the seam so behavior
// is frozen before wiring lands. Failures carry codes only — never key bytes.
// Traceability: D-06; G0-VER-001/005; P-SQLIB/P-KEYSTORE.

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
