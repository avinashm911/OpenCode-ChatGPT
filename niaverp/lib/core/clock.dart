// NiAvERP clock abstraction — Phase 00.
// Timestamps are epoch-ms UTC. Production code uses [SystemClock]; tests use
// [TestClock] for determinism. The clock never invents business time policy.
// Traceability: D-M4 (epoch-ms UTC); strategy Slice 0.

/// Source of epoch-milliseconds UTC.
abstract class Clock {
  int nowMs();
}

/// Production clock.
class SystemClock implements Clock {
  const SystemClock();

  @override
  int nowMs() => DateTime.now().toUtc().millisecondsSinceEpoch;
}

/// Deterministic test clock. Starts at [fixedMs], advances via [advanceBy].
class TestClock implements Clock {
  TestClock(this._nowMs);

  int _nowMs;

  @override
  int nowMs() => _nowMs;

  void advanceBy(int deltaMs) {
    _nowMs += deltaMs;
  }
}
