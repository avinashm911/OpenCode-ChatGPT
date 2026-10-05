// Encrypted production database opener — production DB boundary (P-SQLIB).
// Owner-approved 2026-10-05: package:sqlite3 3.7.0 with build-hook source
// sqlite3mc (SQLite3MultipleCiphers); Dart-package licences MIT. Opens the
// per-company file database, keys it with the Keystore-wrapped 256-bit
// [DbKey] (raw hex literal — never a logged passphrase), PROVES the cipher
// build via `PRAGMA cipher_version` (an empty result means a plaintext
// build, which must never carry production data), then bootstraps the
// audited migration chain. Any failure disposes the handle and throws with
// codes only — there is no plaintext fallback, ever. The [DbKey] bytes come
// from the platform vault (KeyProvider seam); the DB file path comes from
// the app sandbox (path decision with main() wiring — path_provider remains
// an unapproved candidate until the owner confirms it).
// Traceability: P-SQLIB / G0-VER-001; D-06; DSS-C-007.

import 'dart:typed_data';

import 'package:sqlite3/sqlite3.dart';

import '../../core/clock.dart';
import '../security/key_lifecycle.dart';
import 'ffi_database.dart';
import 'niav_database.dart';

/// Opens the encrypted per-company database file.
class CipherDatabaseOpener implements EncryptedDatabaseOpener {
  CipherDatabaseOpener({
    required this.dbPath,
    required DbKey dbKey,
    required this.sqlByVersion,
    this.clock = const SystemClock(),
  }) : _dbKey = DbKey(Uint8List.fromList(dbKey.bytes));

  final String dbPath;
  final DbKey _dbKey;
  final Map<int, String> sqlByVersion;
  final Clock clock;

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
    final Database raw = sqlite3.open(dbPath);
    try {
      raw.execute("PRAGMA key = \"x'${keyHex(_dbKey)}'\";");
      // Prove the cipher build: SQLite3MultipleCiphers registers its own
      // functions (plain SQLite builds have none of these). `PRAGMA
      // cipher_version` is NOT a valid probe here — MC returns zero rows
      // for it — so an empty result below means a plaintext build, which
      // must never carry production data.
      final ResultSet codec = raw.select(
        "SELECT name FROM pragma_function_list WHERE name LIKE 'sqlite3mc%' LIMIT 1",
      );
      if (codec.isEmpty) {
        throw StateError(
          'cipher build unavailable: refusing to carry data as plaintext',
        );
      }
      final FfiDatabase engine = FfiDatabase.wrap(raw);
      final NiavDatabase db = NiavDatabase(engine, clock: clock)
        ..sqlByVersion = sqlByVersion;
      db.bootstrap();
      return db;
    } catch (_) {
      raw.close();
      rethrow;
    }
  }
}
