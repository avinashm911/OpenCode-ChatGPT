// Encrypted production database opener — production DB boundary (P-SQLIB).
// Owner-approved 2026-10-05 (DECISIONS.md P-SQLIB, pubspec.yaml): package:sqlite3
// 3.7.0 with build-hook source sqlite3mc (SQLite3MultipleCiphers);
// Dart-package licences MIT. Opens the per-company file database, keys it with
// the Keystore-wrapped 256-bit [DbKey] (raw hex literal — never a logged
// passphrase), PROVES the cipher build via the SQLite3MultipleCiphers
// function list (an empty result means a plaintext build, which must never
// carry production data), then bootstraps the audited migration chain. Any
// failure disposes the handle and throws with codes only — there is no
// plaintext fallback, ever. The [DbKey] comes from the platform vault
// ([KeyProvider]); the DB file path comes from the app sandbox handed over by
// the Kotlin channel.
// Key hygiene (D1/B2): the `PRAGMA key` statement and everything after it
// run inside a guarded helper. A native exception is rethrown as
// [CipherOpenException] whose code never contains the key hex, so a
// misconfigured driver, a driver that echoes the statement, or a bad key can
// never leak key material through an error string or `toString()`.
// The opener keeps the [FfiDatabase] it created, so [closeHandle] releases the
// native handle; [NiavDatabase.close] does the same through the engine.
// Android 8 / on-device cipher and Keystore proof stays G0-VER-001/005
// evidence — host tests here are not device evidence.
// Traceability: P-SQLIB / G0-VER-001/005; D-06; DSS-C-007; D1 (A2/B1/B2).

import 'dart:typed_data';

import 'package:sqlite3/sqlite3.dart';

import '../../core/clock.dart';
import '../security/key_lifecycle.dart';
import 'ffi_database.dart';
import 'key_provider.dart';
import 'niav_database.dart';

/// Code-only failure of the encrypted open. The message is a fixed string per
/// code: it can never carry the key hex, the SQL text or a driver message.
class CipherOpenException implements Exception {
  const CipherOpenException(this.code, this.message);

  /// Stable machine-readable code (never free-form driver text).
  final String code;

  /// Fixed human-readable message for [code] only.
  final String message;

  @override
  String toString() => 'CipherOpenException($code)';
}

/// Opens the encrypted per-company database file.
class CipherDatabaseOpener implements EncryptedDatabaseOpener {
  CipherDatabaseOpener({
    required this.dbPath,
    required DbKey dbKey,
    required this.sqlByVersion,
    this.clock = const SystemClock(),
  })  : _dbKey = DbKey(Uint8List.fromList(dbKey.bytes)),
        _keyBytesFn = null;

  /// Builds the opener from a key callback. [keyBytes] is invoked once during
  /// [openCompanyDatabase]; a null/failed result throws a code-only error (no
  /// plaintext, no unencrypted engine). Production passes a callback that
  /// returns the Keystore-wrapped key obtained from [ChannelKeyProvider].
  CipherDatabaseOpener.fromKeyBytes({
    required this.dbPath,
    required Uint8List? Function() keyBytes,
    required this.sqlByVersion,
    this.clock = const SystemClock(),
  })  : _keyBytesFn = keyBytes,
        _dbKey = null;

  final String dbPath;
  final DbKey? _dbKey;
  final Uint8List? Function()? _keyBytesFn;
  final Map<int, String> sqlByVersion;
  final Clock clock;

  /// The engine of the last successful open, so the caller can release the
  /// native handle explicitly. Null before the first successful open.
  FfiDatabase? _lastEngine;

  /// Raw 32-byte key as lowercase hex for the `PRAGMA key` literal.
  static String keyHex(DbKey key) {
    final StringBuffer out = StringBuffer();
    for (final int b in key.bytes) {
      out.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return out.toString();
  }

  @override
  NiavDatabase openCompanyDatabase() {
    final DbKey key = _resolveKey();
    final String hex = keyHex(key);
    Database? raw;
    try {
      raw = sqlite3.open(dbPath);
    } catch (_) {
      // Opening the file failed (permissions, missing directory, bad path).
      // The path may be app data; it is not key material, but the message is
      // fixed anyway so nothing platform-specific leaks.
      throw const CipherOpenException(
          'db-open-failed', 'encrypted database could not be opened');
    }
    try {
      // Key application and cipher proof run inside the guard: any exception
      // (driver error, wrong key, SQLITE_NOTADB) becomes a code-only error
      // that cannot contain the key hex.
      _guarded(() {
        raw!.execute("PRAGMA key = \"x'$hex'\";");
        // Prove the cipher build: SQLite3MultipleCiphers registers its own
        // functions (plain SQLite builds have none of these).
        // `PRAGMA cipher_version` is NOT a valid probe here — MC returns zero
        // rows for it — so an empty result below means a plaintext build,
        // which must never carry production data.
        final ResultSet codec = raw.select(
          "SELECT name FROM pragma_function_list WHERE name LIKE 'sqlite3mc%' LIMIT 1",
        );
        if (codec.isEmpty) {
          throw const _CipherBuildUnavailable();
        }
      }, 'key-application-failed');
      final FfiDatabase engine = FfiDatabase.wrap(raw);
      final NiavDatabase db = NiavDatabase(engine, clock: clock)
        ..sqlByVersion = sqlByVersion;
      try {
        db.bootstrap();
      } on StateError {
        // Newer-schema refusal and migration failures propagate their own
        // meaning but never the key; dispose the handle first.
        engine.close();
        raw = null;
        rethrow;
      } catch (_) {
        engine.close();
        raw = null;
        throw const CipherOpenException(
            'bootstrap-failed', 'database bootstrap failed');
      }
      _lastEngine = engine;
      raw = null; // ownership transferred to the engine
      return db;
    } catch (e) {
      if (raw != null) {
        try {
          raw.close();
        } catch (_) {
          // Best-effort disposal; the thrown error is what matters.
        }
      }
      if (e is CipherOpenException) rethrow;
      throw const CipherOpenException(
          'key-application-failed', 'encrypted database could not be opened');
    }
  }

  /// Release the native handle of the last successful open, if any.
  /// Idempotent; used by callers that drop the backend without a full
  /// shutdown path.
  void closeHandle() {
    final FfiDatabase? engine = _lastEngine;
    _lastEngine = null;
    engine?.close();
  }

  DbKey _resolveKey() {
    final DbKey? direct = _dbKey;
    if (direct != null) return direct;
    final Uint8List? Function()? fn = _keyBytesFn;
    if (fn == null) {
      throw const CipherOpenException(
          'key-unavailable', 'database key is unavailable');
    }
    final Uint8List? bytes = fn();
    if (bytes == null || bytes.length != 32) {
      // Missing/locked/failed key: no plaintext, no unencrypted engine.
      throw const CipherOpenException(
          'key-unavailable', 'database key is unavailable');
    }
    return DbKey(Uint8List.fromList(bytes));
  }

  /// Run [body], converting ANY exception into a fixed code-only error. The
  /// key hex lives only in this closure's local scope and never reaches an
  /// error object, a log line or `toString()`.
  void _guarded(void Function() body, String code) {
    try {
      body();
    } on _CipherBuildUnavailable {
      throw const CipherOpenException(
          'cipher-build-unavailable',
          'cipher build unavailable; refusing to carry data as plaintext');
    } on CipherOpenException {
      rethrow;
    } catch (_) {
      throw CipherOpenException(code, 'encrypted database could not be opened');
    }
  }
}

/// Internal marker: the loaded SQLite has no SQLite3MultipleCiphers
/// functions, so the file would be plaintext. Never leaves [_guarded].
class _CipherBuildUnavailable implements Exception {
  const _CipherBuildUnavailable();
}