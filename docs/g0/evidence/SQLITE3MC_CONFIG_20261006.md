# SQLITE3MC_CONFIG_20261006.md — evidence attempt for A9 (cipher pin)
Date (UTC): 2026-10-06  Source ID: P-SQLIB / sqlite3 3.7.0 / sqlite3mc
Status: BLOCKED — docs for exact version insufficient for explicit pin claim

## Version / build
- package:sqlite3 3.7.0 (pubspec.yaml / pubspec.lock / .dart_tool/package_config.json)
- build-hook source: sqlite3mc (SQLite3MultipleCiphers) — confirmed by `pubspec.yaml`, `hook.dill` input.json, native_assets.json (sqlite3mc.dll)

## Sources consulted (quoted / URL, not paraphrased)
1. https://pub.dev/packages/sqlite3 (pub.dev page for sqlite3 3.7.0) — mentions SQLite3MultipleCiphers option and `pragma key = ...`; does NOT list exact `PRAGMA cipher_...` or KDF iteration pragma names for sqlite3mc.
2. https://github.com/simolus3/sqlite3.dart/blob/main/sqlite3/doc/hook.md (hook.md, raw fetched) — describes `source: sqlite3mc` and encryption build option; no pragma names / KDF settings / cipher-name pin instructions found in fetched content.
3. No sqlite3mc-specific documentation (e.g., https://github.com/utelle/SQLite3MultipleCiphers) was fetched successfully within session limits; the bundled version's exact pragma vocabulary cannot be confirmed from the fetched sources above.

## Exact question (owner / source required)
Which pragma names and values (cipher algorithm, KDF algorithm, KDF iterations, page size, etc.) does the sqlite3mc build bundled with sqlite3 3.7.0 support for explicit pinning after `PRAGMA key`? Is `PRAGMA cipher_...` / `PRAGMA kdf_...` defined in this build, or is pinning unsupported? Without this, A9 (explicit cipher pin after PRAGMA key) must remain BLOCKED — no false claim of supported pin.

## What was NOT done (honesty)
- No `cipher_opener.dart` edit applied for pin (would invent pragma names).
- No `PRAGMA cipher_key` / `PRAGMA cipher_...` executed (would invent syntax).
- No claim that `sqlite3mc.dll` supports pinning.
- No device / on-device verification (G0-VER-005 blocked).
