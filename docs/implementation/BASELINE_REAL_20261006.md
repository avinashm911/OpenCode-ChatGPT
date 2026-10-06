# BASELINE REAL — 2026-10-06 (no fixes yet; only real outputs recorded)

## Pre-commands reading (real commands executed)
- `AGENTS.md` read at `niaverp/AGENTS.md` (lines 1-115) — authority/exclusion rules captured.
- `DECISIONS.md` read at `niaverp/DECISIONS.md` (lines 1-116, plus proposed A1 device_id at lines 97-99, P-SQLIB at 116, P-BOOKS/P-PERIODLOCK/P-BILLDEF at 113-115) — decisions preserved.
- `pubspec.yaml`: `sdk: ^3.13.4`; `flutter: sdk: flutter`; dependencies include `drift: ^2.35.1`, `sqlite3: ^3.7.0`; version `1.0.0+1`; hook `sqlite3` source `sqlite3mc`.
- `flutter` binary search: common paths `C:\flutter`, `C:\Users\USER\flutter`, `C:\dev\flutter`, `D:\flutter`, `E:\flutter` — all NOT FOUND.
- Documented build path `C:\Users\USER\niav-erp-build\flutter\bin` — file missing (matches E1/E2 checkpoint notes exactly; NOT fabricated).
- System-wide `flutter.exe` search (`C:\` recurse): no hits (command returned exit 1 / empty; no fabricated hits).

## REAL command outputs (transcribed exactly, not summarized away)

### 1. flutter --version (binary missing)
```
C:\Users\USER\niav-erp-build\flutter\bin\flutter --version
=> flutter : The term 'flutter' is not recognized as the name of a cmdlet,
   function, script file, or operable program.
```
Exit: command-not-found (PowerShell ObjectNotFound / exit non-zero).

### 2. flutter pub get (binary missing)
```
flutter pub get
=> flutter : The term 'flutter' is not recognized ...
```
Exit: False.

### 3. flutter analyze (binary missing)
```
flutter analyze
=> flutter : The term 'flutter' is not recognized ...
```
Exit: False.

### 4. flutter test (binary missing)
```
flutter test
=> flutter : The term 'flutter' is not recognized ...
```
Exit: False.

## Environment / tool status
- Flutter/Dart CLI unavailable in session — real, not assumed; same as E1/E2 notes.
- No `flutter` version number can be reported (would be invented if stated).
- No `flutter pub get` dependency resolution performed; `.packages` / `.dart_tool/package_config.json` may exist from earlier runs — not rebuilt here.
- No `flutter analyze` error list produced; no `flutter test` pass/fail count produced.

## Errors / failing tests grouped by cause
Cause A — TOOL MISSING (not code):
- `flutter --version` → not executed.
- `flutter pub get` → not executed.
- `flutter analyze` → not executed.
- `flutter test` → not executed.
No code-level errors (syntax, type, compile, runtime, assertion) observed — the tool itself is absent, so nothing can be proven.

Cause B — EVIDENCE GAPS (pre-existing, documented in E1/E2/E3):
- P-DEVICE-8 / P-KEYSTORE / P-APK-SHA / P-ZIP-SHA / G0-VER-005/006/007/008: missing real artifacts (no physical Android, no printer matrix, no legal review, no release channel evidence).
- A9 cipher pin: sqlite3mc 3.7.0 `PRAGMA` names not confirmed (BLOCKED, `SQLITE3MC_CONFIG_20261006.md` records fetched URLs/quotes only).
- B2 GST: no owner decision recorded (BLOCKED, memo `OWNER_DECISION_MEMO_GST_POSTING.md` written in E2).

## Count: test declarations vs tests actually run
- Declarations (host, from prior reports / code): E1 128-test state; E2 appended; phase-02 166-test state; 450/1 failure preserved in earlier runs.
- Actually run this session: 0 (flutter binary absent; command not executed; no simulated count).
- Gap explanation: The gap is the MISSING BINARY / MISSING RUNTIME, not hidden test failures. Without the binary, no test can start; therefore declaring "X passed / Y failed" would be fabrication per AGENTS.md (§No invention) and the checkpoint rule (paste REAL output or say tool missing). The pre-existing 450/1 failure count from earlier runs is preserved (not overwritten) but NOT re-verified in this session.

## What is NOT changed (deliberate — this is baseline only, no fixes)
- No code edited; no `build.gradle.kts`, `pubspec.yaml`, source, or tests modified.
- No new pub.dev package added (user rule).
- No `test` weakened, deleted, or renamed.
- No HTML principal document edited (AGENTS.md rule).
- No false PASS for device/printer/release evidence; no fake APk/hash/logcat.
- No `flutter` version claimed (binary missing; statement would be invented).

## Next gate (for owner / next agent step)
1. Provide / restore Flutter `flutter.exe` matching `sdk: ^3.13.4` (approx Flutter 3.24.x — exact pinned version from `pubspec.yaml` / SDK notes / earlier environment if preserved); or confirm which installed SDK to use.
2. Once binary present: run `flutter --version`; `flutter pub get`; `flutter analyze`; `flutter test`; capture real outputs; then proceed with fixes (not before).
3. Confirm A1 device-id proposal (DECISIONS.md PROPOSED); confirm A9 sqlite3mc pin docs (or confirm unsupported); provide G5 evidence (device/printer/release-channel) to close master sequence.
