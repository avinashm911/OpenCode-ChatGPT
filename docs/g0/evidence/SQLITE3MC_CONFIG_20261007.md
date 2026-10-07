# SQLITE3MC_CONFIG — cipher scheme + key-derivation evidence (A9 closed)
Date (UTC): 2026-10-07  Source IDs: P-SQLIB / G0-VER-001; E1b-A9; D-06
Status: CONFIRMED — docs give exact syntax; pin implemented in `lib/data/db/cipher_opener.dart` with live tests
Supersedes: `docs/g0/evidence/SQLITE3MC_CONFIG_20261006.md` (was BLOCKED for lack of pragma vocabulary)

## 1. Version / build (real, this PC)
- package:sqlite3 3.7.0, hook `user_defines: {sqlite3: {source: sqlite3mc}}` (`niaverp/pubspec.yaml:50-53`).
- Bundled native build identifies itself as `SQLite3 Multiple Ciphers 2.5.0` (string extracted from the built `libsqlite3mc.so`, arm64-v8a, `niaverp/build/.../mergeDebugJniLibFolders/out/arm64-v8a/`). Upstream latest is 2.5.1 (Aug 2026, WASM-only fix — irrelevant to Android).
- Cipher names present in the built binary: `aes256cbc`, `chacha20`, `sqlcipher`; config params present: `default:cipher`, `default:kdf_iter`, `kdf_iter`, `fast_kdf_iter`, `hmac_algorithm`, `cipher_salt`. Full extraction log: `outputs/so_strings_cipher.txt` (267 keyword strings from 8520).

## 2. sqlite3 package docs — build-hook user_defines (local file, quoted)
Source: pub cache `sqlite3-3.7.0/doc/hook.md` (lines 49-64, 66-69):
- "For each platform, three sets of binaries are available: ... The [SQLite3MultipleCiphers build](https://github.com/utelle/SQLite3MultipleCiphers/releases) providing encryption support."
- "SQLite3MultipleCiphers can be selected through user defines, e.g. by adding this to `pubspec.yaml`:" + `source: sqlite3mc # for SQLite3MultipleCiphers, default is sqlite3. sqlcipher is also available.`
- "> [!IMPORTANT] > While SQLite3 is released into the [public domain](https://sqlite.org/copyright.html), SQLite3 Multiple Ciphers and SQLCipher have their own licenses."

## 3. Official SQLite3MultipleCiphers docs (fetched 2026-10-07, quoted)
Base: https://utelle.github.io/SQLite3MultipleCiphers/ — "Documentation of the currently supported cipher schemes and the C and SQL interfaces is provided on the SQLite3 Multiple Ciphers website."
- Overview: "Currently 6 different encryption cipher schemes are supported" (aes128cbc, aes256cbc, chacha20, sqlcipher, rc4, ascon, aegis listed).
- "The cipher scheme ChaCha20 - Poly1305 HMAC is currently the recommended default cipher scheme". KDF note: "A key derivation function (PBKDF2) is used to reduce vulnerability to brute force attacks." (passphrase path).
- SQL API: "PRAGMA key allows to set the passphrase." / "PRAGMA rekey allows to change the passphrase." / "A more detailed description (especially, how to configure cipher schemes) can be found here" → SQL pragmas page.

SQL pragmas page: https://utelle.github.io/SQLite3MultipleCiphers/docs/configuration/config_sql_pragmas/
- Order (3 steps): "1. Optionally select the cipher scheme using PRAGMA cipher / 2. Optionally set configuration parameters ... / 3. Apply the encryption key using PRAGMA key". "Step 1 is only required, if a non-default encryption scheme should be used." "Step 3 is always required."
- `PRAGMA cipher`: "The `PRAGMA cipher` allows to select the cipher to be used for encrypting the database, and has the following syntax: `PRAGMA cipher = { ciphername | 'ciphername' | "ciphername" };`" with names `aes128cbc`, `aes256cbc`, `chacha20`, `sqlcipher`, `rc4`, `ascon128`, `aegis`. Example: `PRAGMA cipher = 'aes256cbc';`
- Raw key (no derivation): "it is possible to specify an exact byte sequence for the encryption key using a blob literal ... In this case it is the responsibility of the application to ensure that the provided literal corresponds to a 64 character hex string, which will be converted directly to 32 bytes (256 bits) of key data." Examples: `PRAGMA key = "x'5468...2E'";` (SQLCipher form) and `PRAGMA key = 'raw:5468...2E';` (sqleet form); "Currently only the cipher schemes sqleet: ChaCha20 and SQLCipher: AES 256 Bit support this method ... All named ciphers accept the raw key material in both forms."
- Key check: "These pragmas return `ok` even if the provided key isn't correct. ... To check whether the provided key was actually correct, you must execute a simple query like e.g. `SELECT * FROM sqlite_master;`" (our opener instead bootstraps the migration chain — first real read — which fails closed on a wrong key; proven by existing tests).
- `PRAGMA kdf_iter`: "Applicable to: wxSQLite3: AES 256 Bit, sqleet: ChaCha20, SQLCipher: AES 256 Bit, Ascon" — "Most key derivation functions perform a certain number of iterations ... `PRAGMA kdf_iter = { number-of-iterations };`"

## 4. Live verification against the bundled build (this PC, real runs)
- `PRAGMA cipher;` with no selection returns `chacha20` → documented default holds in the bundled build.
- `PRAGMA cipher = 'chacha20';` executes; read-back returns `chacha20`.
- `PRAGMA cipher = 'nosuchcipher';` throws `SqliteException(1): ... Cipher 'nosuchcipher' unknown.` and the setting stays `chacha20` (not silently changed) → read-back equality is a meaningful check.
- Probe file was scratch (`cipher_pin_probe_test.dart`), run twice, then deleted; it was never part of the suite.

## 5. Decision — what is pinned and what is not
- PINNED: cipher scheme `chacha20`, executed before every `PRAGMA key`, read back after the key; mismatch throws code-only `cipher-pin-mismatch`. This is the documented default (verified live), so databases created before the pin reopen unchanged (proven by new test `databases created before the pin reopen under the pin`).
- NOT pinned (deliberately, with doc basis): `kdf_iter` / `fast_kdf_iter` / `hmac_*` / KDF algorithm. Our opener uses raw 256-bit keys (`x'<64-hex>'` = "Raw key data (without key derivation)"), so no KDF runs and there is no iteration count to pin; the docs list `kdf_iter` only for passphrase-derived keys. Inventing KDF values for raw keys would be fabrication.
- Raw-key form kept as `x'...'` (documented for both sqleet/chacha20 and SQLCipher; no change needed).

## 6. What is still missing / not claimed
- On-device (Android 8) cipher proof remains G0-VER-001/005 evidence (host runs are not device evidence). Upstream 2.5.1 not adopted (WASM-only delta; no Android effect claimed).
