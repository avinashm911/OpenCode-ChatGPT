// Shared screen wiring — Phase 02.
// [IdMint] supplies op/event/entity ids for writes. Production minting is
// UUIDv7 (D-M4) and lands with the platform/device slice; tests and the
// offline host shell pass an explicit counter-based mint so no id scheme is
// silently invented as production behavior. [WriteContext] bundles the
// caller-supplied device identity + actor (platform device id at S1).
// Traceability: FR-COM-001 (unique ids); D-M4 (UUIDv7 text).

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

/// Counter-based mint for tests and host flows (NOT production UUIDv7).
class CounterIdMint {
  CounterIdMint();

  int _n = 0;

  String call(String prefix) {
    _n += 1;
    return '$prefix-test-$_n';
  }
}
