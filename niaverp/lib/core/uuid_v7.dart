// NiAvERP UUIDv7 text identifiers — D-M4 (UUIDv7 text IDs).
// Pure Dart, no package: RFC 9562 layout, lowercase canonical 36-char text
// `xxxxxxxx-xxxx-7xxx-yxxx-xxxxxxxxxxxx` where `y` carries the variant bits
// (10xx). Layout: 48-bit big-endian unix-milliseconds, 4-bit version (7),
// 12-bit `rand_a`, 2-bit variant, 62-bit `rand_b`.
// Monotonic within one millisecond: the generator keeps the last timestamp
// and a 12-bit counter seeded from the random source; calls inside the same
// millisecond increment the counter, and a counter overflow advances the
// timestamp by one millisecond rather than repeating a value (RFC 9562
// "monotonic random" method). Ids therefore sort by creation time, which is
// why D-M4 accepts them as TEXT PRIMARY KEYs.
// The clock and the random source are injected, so ids are deterministic in
// tests and no global state leaks between them. Production uses
// [SystemClock] and a cryptographically seeded source.
// Traceability: D-M4; DSS-C-004 (operation identity); OD-DB-004.

import 'dart:math';
import 'dart:typed_data';

import 'clock.dart';

/// Injectable randomness for id generation (tests pass a seeded source).
typedef RandomBytes = Uint8List Function(int length);

/// RFC 9562 UUIDv7 generator with millisecond monotonicity.
class UuidV7 {
  UuidV7({
    Clock? clock,
    RandomBytes? randomBytes,
    Random? random,
  })  : _clock = clock ?? const SystemClock(),
        _randomBytes = randomBytes ?? _secureRandomBytes,
        _random = random; // ignore: prefer_initializing_formals

  final Clock _clock;
  final RandomBytes _randomBytes;
  final Random? _random;

  int _lastMs = -1;
  int _counter = 0;

  /// True when this instance has already produced a value (test helper for
  /// the monotonic seeding path).
  bool get hasIssued => _lastMs >= 0;

  /// Next canonical lowercase UUIDv7 string.
  String next() => _format(_nextBytes());

  /// Next id as raw bytes (16, big-endian layout).
  Uint8List nextBytes() => _nextBytes();

  static const int _maxCounter = 0x1000; // 12 bits

  Uint8List _nextBytes() {
    int ms = _clock.nowMs();
    int counter;
    if (ms > _lastMs) {
      // New millisecond: seed the counter from fresh randomness (12 bits).
      counter = _randomInt(12);
      _lastMs = ms;
    } else {
      // Same millisecond (or a clock that went backwards): increment, and on
      // overflow advance the timestamp so values stay strictly increasing.
      ms = _lastMs;
      counter = _counter + 1;
      if (counter >= _maxCounter) {
        ms = _lastMs + 1;
        counter = 0;
        _lastMs = ms;
      }
    }
    _counter = counter;
    final Uint8List rand = _randomBytes(10);
    final Uint8List out = Uint8List(16);
    // 48-bit unix milliseconds, big-endian.
    out[0] = (ms >> 40) & 0xff;
    out[1] = (ms >> 32) & 0xff;
    out[2] = (ms >> 24) & 0xff;
    out[3] = (ms >> 16) & 0xff;
    out[4] = (ms >> 8) & 0xff;
    out[5] = ms & 0xff;
    // version 7 in the high nibble of octet 6, rand_a in the low 12 bits.
    out[6] = 0x70 | (counter >> 8);
    out[7] = counter & 0xff;
    // variant 10xx in the high bits of octet 8, then 62 random bits.
    out[8] = 0x80 | (rand[0] & 0x3f);
    out[9] = rand[1];
    out[10] = rand[2];
    out[11] = rand[3];
    out[12] = rand[4];
    out[13] = rand[5];
    out[14] = rand[6];
    out[15] = rand[7];
    return out;
  }

  int _randomInt(int bits) {
    final Random? rng = _random;
    if (rng != null) return rng.nextInt(1 << bits);
    return _randomBytes((bits + 7) ~/ 8).first & ((1 << bits) - 1);
  }

  static final RegExp _canonical =
      RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-'
          r'[0-9a-f]{12}$');

  /// True when [text] is a canonical lowercase UUIDv7 string.
  static bool isCanonicalV7(String text) => _canonical.hasMatch(text);

  /// True when [text] is a canonical lowercase UUID of any version.
  static bool isCanonicalUuid(String text) =>
      RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')
          .hasMatch(text);

  /// Format 16 raw bytes as canonical lowercase text.
  static String _format(Uint8List b) {
    final StringBuffer out = StringBuffer();
    for (int i = 0; i < 16; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) out.write('-');
      out.write(b[i].toRadixString(16).padLeft(2, '0'));
    }
    return out.toString();
  }

  static Uint8List _secureRandomBytes(int length) {
    final Random rng = Random.secure();
    final Uint8List out = Uint8List(length);
    for (int i = 0; i < length; i++) {
      out[i] = rng.nextInt(256);
    }
    return out;
  }
}