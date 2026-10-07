# CLAIMS RE-VERIFIED — E1 to E3 against real test output

Date (UTC): 2026-10-07
Branch: `e3-20261006` (HEAD `da93cd0` at time of run)
Tool: `E:\niaverp-root\tools\flutter\bin\flutter.bat` — Flutter 3.47.6 / Dart 3.13.5
Workdir for tests: `E:\niaverp-root\niaverp` (no-space path; sqlite3 native-asset build succeeds)
Scope: every claim saying "fixed" or "implemented" in RESULT_E1, E1b, E2, E3.
Method: for each claim, the proving test was located and executed in this session.
Verdicts: PROVEN (test ran now and passed) / UNPROVEN (no test, skipped, or template-only) / CONTRADICTED (test ran now and failed).
No code was fixed in this prompt — verification only.

## 0. Test-file existence check (run 2026-10-07)

Command: `Test-Path` for the three E1-named tests.

```
False  test/app/channel_contract_test.dart
False  test/app/wrong_key_opens_time_test.dart
False  test/app/startup_error_state_test.dart
True   test/security/device_id_service_test.dart
True   test/security/clock_rollback_test.dart
True   test/security/cipher_pin_blocked_test.dart
True   test/presentation/localization_source_test.dart
```

The three E1-claimed test files do not exist in this tree. Verdicts below record substitutes where they exist.

## 1. E1 — Make the app start on a real Android device

Source: `docs/implementation/RESULT_E1_make_app_start_on_device.md` §3 (A1–A10).

| ID | Claim | Proving test | Verdict | Real output (this session) |
|---|---|---|---|---|
| A1 | BLOCKED (no fix claimed) | — | N/A — BLOCKED, no "fixed/implemented" claim | `MainActivity.kt` has no `getDeviceId` handler; E1b supersedes (see §2). |
| A2 | "implemented" — channel contract test | `test/app/channel_contract_test.dart` (claimed) | UNPROVEN | File does not exist (see §0). Dart-side channel projection is instead covered by `test/data/db/channel_key_provider_test.dart`, which passed (see A6 row). The claimed test itself proves nothing because it is absent. |
| A3 | "implemented" — `wrappingKey()` never mints over existing blob; returns `wipedByUninstall`/`corruptWrapper` (Kotlin) | No Dart test; host substitute `test/security/key_lifecycle_test.dart` + `test/data/db/channel_key_provider_test.dart` | UNPROVEN (Kotlin runtime); Dart projection PROVEN | Substitutes passed: key_lifecycle + channel_key_provider + ffi + niav_database = `+25: All tests passed!` (full tail in A6/A7 evidence). The Kotlin Keystore path itself has no host-executable test and no device run — the E1 report's own §8 concedes "host-only". |
| A4 | "implemented" — one-file atomic write (IV prefix + renameTo), old two-file read-compatible (Kotlin) | None in tree | UNPROVEN | No test references the atomic-write path. Source-only claim. |
| A5 | "implemented" — refuse provisioning when `niaverp.db` exists; Dart maps `existingDataLocked` | `test/app/startup_test.dart` ("key failure shows the failure state and creates nothing"; "a missing key never opens anything") | PROVEN (host) | `flutter test test/app/startup_test.dart` → `00:01 +4: All tests passed!` (3 startup tests + persistence when co-run; startup-only rerun identical). Key line: `expect(File('${tmp.path}/niav.db').existsSync(), isFalse)` passes — no DB created on key failure. |
| A6 | "implemented" — `KeystoreUnavailable` thrown; all 5 Kotlin codes mapped; dup branches removed | `test/data/db/channel_key_provider_test.dart` | PROVEN (host-side mapping) | Ran with key_lifecycle + ffi + niav_database: `+25: All tests passed!`. Channel provider maps `available/missing/failed` replies to the lifecycle with codes only. Kotlin throw itself is source-inspection only (no device). |
| A7 | "implemented" — zero key bytes after use; codes only in errors | `test/security/key_lifecycle_test.dart` (redaction) + `test/data/db/cipher_opener_test.dart` (code-only failures) | PROVEN (host-side) | key_lifecycle redaction tests pass (inside the +25 run). cipher_opener: `wrong-key failure is code-only: the key hex never leaks` and `unreadable-file failure is code-only` both pass (see §5). Kotlin `Arrays.fill` zeroing is source-inspection only. |
| A8 | "implemented" — `observeDeviceClock()` post-open; failure visible | `test/security/clock_rollback_test.dart` | PROVEN (host, mocked time) | `flutter test device_id + clock_rollback + cipher_pin_blocked` → `00:00 +8 ~2: All tests passed!` (2 device_id + 6 clock pass, 2 cipher_pin skip). Clock cases: first-observation, forward-progress, behind-mark rollback, no-trial-regain, grace, missing-anchor — all pass. |
| A9 | BLOCKED/boundary — wrong-key open-time failure; pin pragma unconfirmed | `test/app/wrong_key_opens_time_test.dart` (claimed, E1) | UNPROVEN as named test; PROVEN via substitute (see §5) | Named file does not exist (§0). Substitute `cipher_opener_test.dart` wrong-key cases pass. E1b keeps the pin itself BLOCKED (see §2). |
| A10 | "implemented" — per-Kotlin-code startup UI states | `test/app/startup_error_state_test.dart` (claimed) | UNPROVEN as named test; partial PROVEN via substitutes | Named file does not exist (§0). Substitutes: `startup_test.dart` (keyFailure → `Secure key unavailable`, missing key → exception, ready → tabs) passed `+4`; `channel_key_provider_test.dart` projections passed. No single test covers all 5 codes → distinct-state mapping. |

## 2. E1b — Close A1 (device id) and A9 (cipher pin)

Source: `docs/implementation/RESULT_E1b_close_device_id_and_cipher_pin.md` §§4–5.

| ID | Claim | Proving test | Verdict | Real output (this session) |
|---|---|---|---|---|
| A1 | "implemented-pending-owner-approval" — `DeviceIdService.getOrCreate()` (UUIDv7, app-private file, never hardware ID) | `test/security/device_id_service_test.dart` | PROVEN (host) | `first run creates device_id` +1, `second run reuses same id` +2 — both pass with mocked path_provider (inside the `+8 ~2` run above). Persistence is to host temp dir, not a device. |
| A9 | BLOCKED — no pin pragma emitted (honest, not "implemented") | `test/security/cipher_pin_blocked_test.dart` | UNPROVEN by design (2 skipped) | `A9 cipher pin BLOCKED: no invented pragma emitted — Skip: BLOCKED — sqlite3mc docs unconfirmed`; `A9 wrong-key fails at open time — Skip: Verified by cipher_opener tests; BLOCKED until sqlite3mc docs confirm pin order`. Shown as `~2` in the passing run. This is the report honestly refusing to invent syntax. |

## 3. E2 — Correctness fixes

Source: `docs/implementation/RESULT_E2_correctness_fixes.md` §§2–5.

| ID | Claim | Proving test | Verdict | Real output (this session) |
|---|---|---|---|---|
| A (company switch) | "fixed" — tab keys include company id; `openCompany` clears `_built`; `didUpdateWidget` resets | `test/presentation/shell_test.dart` → `opening another company rebinds the tabs` | PROVEN | `flutter test test/presentation/shell_test.dart` → `00:01 +6: All tests passed!` Full list: five destinations render; scope gate; onboarding gate; each tab real destination; **opening another company rebinds the tabs** (+4); composition-root config (+5). The rebinding test asserts `Second Co` found / `Nav Co` gone after `openCompany(CompanyId('c-second'))` — no stale data. |
| B (GST posting) | BLOCKED — memo only, no code | — | N/A — no "fixed/implemented" claim | `docs/implementation/OWNER_DECISION_MEMO_GST_POSTING.md` exists; B3–B5 deferred. Nothing to run. |
| C (backup integrity) | "implemented (design guard)" — `checkRestorable()` rejects missing-MAC manifest when `macKey != null` (`backup.dart:179-181`); hash bound to company+version | `test/security/backup_integrity_test.dart` (+ `backup_test.dart`, `backup_company_guard_test.dart`) | PROVEN | `flutter test backup_integrity + backup + backup_company_guard` → `+12: All tests passed!` Including: `backup with no MAC is refused when macKey is supplied` (+1); keyed-manifest verifies / tamper breaks MAC / wrong key fails (backup_test +5..+8); company-guard refusals (company_guard +9..+11). Guard text: `errors.add('manifest MAC missing: backup requires authentication')`. Note: full restore flow is deferred to E4 per the E2 report — this proves the guard, not a restore. |
| D (localisation) | "implemented" — ARB source test + dialog strings localised | `test/presentation/localization_source_test.dart` | CONTRADICTED | `flutter test ... localization_source_test.dart` → `00:00 +8 ~2 -1: Some tests failed.` Failing test: `D1 ARB source matches runtime maps (en/hi/gu) — host only [E]` — `Unable to load asset: "lib/l10n/app_en.arb". The asset does not exist or has empty data.` at `test/presentation/localization_source_test.dart 14:49` via `rootBundle.loadString`. The test as written cannot pass under `flutter test` (assets not on the test bundle). The ARB files and dialog edits may exist, but the claimed proof test fails. |

## 4. E3 — CI build and Android 8 proof

Source: `docs/implementation/RESULT_E3_ci_build_and_android8_proof.md` §§3–5. The report itself labels these template/partial.

| ID | Claim | Proving test | Verdict | Real output (this session) |
|---|---|---|---|---|
| A1–A3 (build config) | "implemented" — applicationId kept, release-signing guard, CI version inputs | None (file inspection only) | UNPROVEN | No compile was executed from this session (Android SDK/emulator not present; `flutter build apk` not run). `build.gradle.kts` edits are source text only. |
| B1–B3 (CI workflow) | "template (not executed)" | None | UNPROVEN | `.github/workflows/build.yml` exists (`Test-Path True`) but no GitHub Actions run was executed here — the E3 report concedes this. |
| C1 (emulator run) | "template only; PENDING-INPUT" | None | UNPROVEN | `docs/g0/evidence/android/EMULATOR_API26_RUN_20261006.md` exists and states: "no real GitHub Actions run executed … No APK hash, no fingerprint, no logcat recorded here." |
| C2 (cipher licence) | "partial" | None | UNPROVEN / PARTIAL | `docs/g0/evidence/CIPHER_LIB_LICENSE_20261006.md` exists (`Test-Path True`); embedded licence text not extracted on host per the E3 report. |
| C3 (pending-inputs note) | "note added" | — | N/A (process step, verified present) | Addition recorded; no row status changed per E3 §5. |

## 5. The four directed checks

### (a) Company switch shows no stale data — PROVEN

- Test: `test/presentation/shell_test.dart` → `opening another company rebinds the tabs`.
- Command: `flutter test test/presentation/shell_test.dart`
- Output: `00:01 +6: All tests passed!` (tail: `+4: … opening another company rebinds the tabs`, `+5: … composition root injects config without widget state`, `+6: All tests passed!`).
- What it asserts: after `openCompany(CompanyId('c-second'))`, `find.text('Second Co')` findsOne, `find.text('Nav Co')` findsNothing.

### (b) Backup restore is rejected when the MAC is missing — PROVEN (guard; restore flow deferred)

- Test: `test/security/backup_integrity_test.dart` → `backup with no MAC is refused when macKey is supplied`.
- Command: `flutter test test/security/backup_integrity_test.dart test/security/backup_test.dart test/security/backup_company_guard_test.dart`
- Output: `+12: All tests passed!` (full per-test list in §3-C row).
- Source anchor: `niaverp/lib/data/security/backup.dart:179-185` — `if (macKey != null) { if (manifest.macHex == null) errors.add('manifest MAC missing: backup requires authentication'); … }`.
- Boundary: E2 §4 is explicit that no restore implementation was added (deferred to E4) — the verdict covers the `checkRestorable` guard, not an end-to-end restore.

### (c) Wrong key fails at open time — PROVEN via substitute; NAMED test missing

- Claimed test `test/app/wrong_key_opens_time_test.dart`: does not exist → UNPROVEN as named.
- Substitute test: `test/data/db/cipher_opener_test.dart` → `wrong key refuses to open (no plaintext, no partial state)` + `wrong-key failure is code-only`.
- Command: `flutter test test/data/db/cipher_opener_test.dart`
- Output: `00:00 +6: All tests passed!` — `key hex is 64 lowercase hex chars` (+1); `opens encrypted and bootstraps to latest schema` (+2); `close then reopen with the same key preserves rows` (+3); **`wrong key refuses to open`** (+4); `wrong-key failure is code-only` (+5); `unreadable-file failure is code-only` (+6).
- Cipher-pin ordering itself remains BLOCKED (E1b A9, skips recorded in §2).

### (d) App starts and relaunches on the same database — PROVEN (host; not a device restart)

- Tests: `test/app/startup_test.dart` (encrypted start) + `test/data/db/cipher_opener_test.dart` (`close then reopen with the same key preserves rows`) + `test/data/db/persistence_reload_test.dart` (`rows written before close are visible after reopen`).
- Commands/outputs:
  - `flutter test test/app/startup_test.dart test/data/db/persistence_reload_test.dart` → startup ready/key-failure/missing-key pass (`+4: All tests passed!` for the startup file).
  - `flutter test test/data/db/persistence_reload_test.dart` → `+1: All tests passed!` (`rows written before close are visible after reopen`).
  - cipher_opener close→reopen case passes inside the `+6` run above, including the ciphertext check (`rawText.startsWith('SQLite format 3')` isFalse; `contains('Persist Co')` isFalse) and row survival under the same key.
- Boundary: this is host temp-file close→reopen semantics through the real encrypted opener and the real `runStartup` sequence — not a physical Android process kill + relaunch (G0-VER-005/008 still PENDING-INPUT; E3 C1 template only).

## 6. Summary verdict table

| Claim thread | Verdict |
|---|---|
| E1 A2 channel contract (named test) | UNPROVEN — file absent |
| E1 A3/A4 Kotlin key-wrap + atomic file | UNPROVEN — no host/device executable test |
| E1 A5 existing-DB refusal / A6 code mapping / A7 redaction | PROVEN (host substitutes) |
| E1 A8 clock observation | PROVEN (host, mocked time) |
| E1 A9 wrong-key open-time (named test) | UNPROVEN as named; PROVEN via `cipher_opener_test.dart` |
| E1 A10 startup states (named test) | UNPROVEN as named; partial PROVEN via substitutes |
| E1b A1 device_id service | PROVEN (host) |
| E1b A9 cipher pin | UNPROVEN by design (honest BLOCKED, 2 skips) |
| E2 A company switch, no stale data | PROVEN |
| E2 B GST posting | BLOCKED — no implemented claim |
| E2 C MAC-missing guard | PROVEN (guard only; restore deferred E4) |
| E2 D localisation source test | CONTRADICTED — test fails (`Unable to load asset: "lib/l10n/app_en.arb"`) |
| E3 A build config / B CI / C1 emulator / C2 licence | UNPROVEN (template/partial; no execution) |
| Directed (a) company switch | PROVEN |
| Directed (b) MAC-missing rejection | PROVEN |
| Directed (c) wrong key open-time | PROVEN via substitute (named file missing) |
| Directed (d) start + relaunch same DB | PROVEN (host close→reopen; not device restart) |

## 7. What this re-verification did not do

- No source, test, config, or HTML file was edited; no fix attempted (per prompt).
- No `flutter build`, CI run, emulator run, or physical-device run was performed — E3 evidence stays PENDING-INPUT.
- Full-suite `flutter test` was not executed; only the claim-linked files above were run.
- Kotlin Keystore behaviour, atomic rename durability under power loss, and release signing were not executed — source-inspection claims stay UNPROVEN beyond their Dart projections.
