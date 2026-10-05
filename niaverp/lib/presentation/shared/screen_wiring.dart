// Shared screen wiring — Phase 02, production ID policy in D1.
// [IdMint] supplies op/event/entity ids for writes. Production minting is
// UUIDv7 text (D-M4) and is provided by [UuidV7WriteContext]; tests and the
// offline host shell pass an explicit counter-based mint so no id scheme is
// silently invented as production behavior. [WriteContext] bundles the
// caller-supplied device identity + actor (platform device id at S1).
// Traceability: FR-COM-001 (unique ids); D-M4 (UUIDv7 text); DSS-C-004.

import '../../core/uuid_v7.dart';

/// Mints a unique id string for the given [prefix].
typedef IdMint = String Function(String prefix);

/// Caller-supplied write identity for screens.
class WriteContext {
  const WriteContext({
    required this.deviceId,
    required this.actor,
    required this.idMint,
  });

  final String deviceId;
  final String actor;
  final IdMint idMint;
}

/// Production write identity: UUIDv7 text ids (D-M4). The device identity is
/// supplied by the platform layer; the actor is the signed-in user when the
/// users/roles slice lands (M19) — today it is the caller's own value, never
/// invented here.
class UuidV7WriteContext extends WriteContext {
  UuidV7WriteContext({
    required super.deviceId,
    required super.actor,
    UuidV7? generator,
  })  : _generator = generator ?? UuidV7(),
        super(idMint: _unusedMint);

  final UuidV7 _generator;

  /// Never used: the production mint is [mintId] below, which wraps the UUIDv7
  /// generator instead of the counter.
  static String _unusedMint(String prefix) =>
      throw StateError('UuidV7WriteContext mints through mintId');

  /// Mint one production id for [prefix].
  String mintId(String prefix) => '$prefix-${_generator.next()}';
}

/// Counter-based mint for tests and host flows (NOT production UUIDv7).
class CounterIdMint {
  CounterIdMint();

  int _n = 0;

  String call(String prefix) {
    _n += 1;
    return '$prefix-test-$_n';
  }
}