# Bundled cipher library licence — E3 / G0-VER-001 evidence
Date (UTC): 2026-10-06  Source: package:sqlite3 3.7.0 build-hook source `sqlite3mc` (SQLite3MultipleCiphers)
Status: PARTIAL — binary present (`sqlite3mc.dll`, 2,136,576 bytes, built 2026-10-05); native licence text not extractable on host; source docs (hook.md / pub.dev) reference MIT for sqlite3 package, SQLCipher / SQLite3MultipleCiphers have separate licences (SQLCipher links OpenSSL; license varies by build).
Evidence: binary file path; `pubspec.yaml` version; `hook.md` fetched content; no embedded licence header readable from `.dart_tool/lib/sqlite3mc.dll` via host tools.
Next: attach official SQLite3MultipleCiphers / SQLCipher licence text from upstream source when confirmed; do not invent text.
