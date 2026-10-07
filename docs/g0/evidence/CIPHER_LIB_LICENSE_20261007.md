# Bundled cipher library licence — COMPLETE (text) / device proof still pending
Date (UTC): 2026-10-07  Source: P-SQLIB / G0-VER-001  Previous: `CIPHER_LIB_LICENSE_20261006.md` (PARTIAL)
Status: COMPLETE for licence text. Method per instruction: build works, so extraction from built artifacts was attempted FIRST; the `.so` embeds no licence text (see §1), therefore the text below is taken from the UPSTREAM repository (fallback allowed).

## 1. Built-artifact extraction attempt (real, this PC)
- Files: `niaverp/build/app/intermediates/merged_jni_libs/debug/mergeDebugJniLibFolders/out/{arm64-v8a,armeabi-v7a,x86_64}/libsqlite3mc.so` (from the passing `flutter build apk --debug`, 2026-10-07).
- Method: printable-string extraction over the arm64-v8a binary (8520 strings ≥ 5 chars; 267 cipher/licence-keyword hits, full log `outputs/so_strings_cipher.txt`).
- Result: NO licence/copyright/permission strings embedded (no "General Public License", "Redistribution", "THIS SOFTWARE", "Permission is hereby", "Copyright", "utelle", "Zetetic"). Version string found: `SQLite3 Multiple Ciphers 2.5.0`.

## 2. Upstream licence text (fetched 2026-10-07 from https://raw.githubusercontent.com/utelle/SQLite3MultipleCiphers/main/LICENSE; repo sidebar also labels it "MIT license")
```
MIT License

Copyright (c) 2019-2026 Ulrich Telle

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## 3. Adjacent licences (decided, not invented)
- package:sqlite3 3.7.0 (Dart side): MIT, Copyright (c) 2020 Simon Binder — read from pub-cache `LICENSE` (real file).
- Plain SQLite: public domain (per sqlite3 hook.md quote in SQLITE3MC_CONFIG_20261007 §2).

## 4. Still pending (not converted to PASS)
- Android 8 on-device cipher proof (G0-VER-001/005) — host evidence only.
