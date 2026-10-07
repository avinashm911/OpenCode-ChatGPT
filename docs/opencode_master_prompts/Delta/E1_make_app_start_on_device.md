# E1 — Make the app start on a real Android device (channel contract, Keystore hardening, clock guard)

## Mandatory first actions
1. Read `niaverp/AGENTS.md`, `niaverp/DECISIONS.md`, `docs/opencode_master_prompts/GLOBAL_NO_INVENTION_CONTRACT.md`, `docs/g0/PENDING_INPUTS.md`, and `docs/implementation/RESULT_D1_*.md`, `RESULT_D2_*.md`.
2. Run `flutter analyze` and `flutter test` first and record totals. If not green, stop with Overall status FAIL. (If the sqlite3 hook fails on a path with a space, use a no-space drive alias and record it.)
3. Work on a new branch `e1-<date>`. Do not edit the 15 HTML documents. Add no pub.dev package. Never weaken or delete a test to make it pass. Do not mark anything device-verified: host/fake-channel results are not device evidence (G0-VER-005).

## Known defects to fix (found by code review; re-verify each yourself before editing)
A1. `lib/main.dart` calls `invokeMethod('getDeviceId')` but `MainActivity.kt` handles only `getDatabaseKey` and `getFilesDirectory`, so startup ends in `databaseFailure`. Decide: implement `getDeviceId` in Kotlin per the documented device-id rule (find it in the docs/DECISIONS; if undefined, mark BLOCKED with the exact question and make Dart not depend on it), or remove the call.
A2. Add a **channel contract test**: a test that extracts every method name Dart invokes on the channel and every name Kotlin handles (read the Kotlin source as text), and fails if any Dart call has no Kotlin handler.
A3. `wrappingKey()` silently generates a new Keystore key when the alias is missing. Change: when a wrapped blob exists but the alias is missing or decryption fails, return a distinct code (`wipedByUninstall` / `corruptWrapper`), never mint a new key.
A4. The wrapped key and its IV are saved as two non-atomic files. Store them as ONE file (IV prefix + ciphertext) written via temp file + atomic rename, with a read path that still understands the old two-file layout if present.
A5. Provisioning must refuse to create a new key when `niaverp.db` already exists (return a code; UI shows a non-technical "cannot unlock existing data" state). Never overwrite.
A6. `KeystoreUnavailable` is declared but never thrown: throw it for Keystore provider exceptions and map every Kotlin error code to a Dart state in `startup.dart`; remove the unreachable states or make them reachable. Replace the substring check for "schema too new" with a typed error. Remove duplicated identical branches near `startup.dart:225-231`.
A7. Zero key byte arrays after use on the Kotlin side where possible; never log or return key text in errors (keep the existing redaction test).
A8. Call `observeDeviceClock` (entitlements) from startup after the database opens; do not swallow its failures with `catch (_) {}` — record them as a visible diagnostic. Add tests with a rolled-back clock.
A9. Pin the cipher explicitly (cipher name and KDF settings) after `PRAGMA key`, only if sqlite3mc documentation for the bundled version supports it; otherwise record BLOCKED with the question. Add a test that opening with a wrong key fails at open time, not later.
A10. Add a startup test for each Kotlin error code reaching a distinct UI state.

## Required tests
Contract test (A2), wiped-alias (A3), atomic blob (A4), refuse-over-existing-db (A5), each error state (A6/A10), clock rollback (A8), wrong-key (A9).

## Do not
No new features, no UI beyond the startup/error states, no schema changes unless unavoidable (then additive, repeat-safe, with kLatestVersion and tests).

## Required output
Write `docs/implementation/RESULT_E1_make_app_start_on_device.md` using the nine-section template in `delta/README.md` (one row per A1-A10). Append `E1 | <date> | <status> | tests <passed>/<failed> | <summary>` to `docs/implementation/RESULTS_INDEX.md`. Section 8 must list everything tested only on host. End your final chat message with the Overall status and the results file path only.
