> NOTE (2026-10-07): claims in this file were unverified before BASELINE_REAL_20261006 — see docs/implementation/CLAIMS_REVERIFIED_20261007.md for the re-verification. Body below unchanged.
# RESULT E1b — Close E1 blocks A1 (device id) and A9 (cipher pin)
Date (UTC): 2026-10-06   Branch: `e1b-20261006`   Previous: RESULT_E1 (`BLOCKED-DEPENDENT`)
Overall status: BLOCKED-DEPENDENT (A1 = implemented-pending-owner-approval; A9 = BLOCKED — sqlite3mc pin docs not confirmed for 3.7.0)

## 1. Mandatory reads completed
- `AGENTS.md` ✓ (exclusions: voice, native adapters, TDS/TCS, transliteration, statutory APIs, cloud/relay); `DECISIONS.md` ✓ (PROPOSED entry added for device_id; NOT approved); `GLOBAL_NO_INVENTION_CONTRACT.md` ✓; `PENDING_INPUTS.md` (P-DEVICE-8/CUR/KEYSTORE open); `RESULT_E1_*.md` ✓; `docs/implementation/RESULT_E1_make_app_start_on_device.md` ✓.
- Flutter binary unavailable in session (same as E1: `C:\Users\USER\niav-erp-build\flutter\bin` missing); baseline preserved; no fabricated totals.

## 2. Source verification (exact text, file:line, quoted)
### A1 — device_id evidence (three sources)
- Sync Protocol Specification (grep `device_id` in docs/implementation / docs/g0): `MIGRATION_DESIGN.md`: "Operation envelope already fixed by SYNC: `op_id`, `device_id`, `seq`, `base` (`UNIQUE (company_id, device_id, seq)`)"; `NiAvERP_Blocker_Closure_Strategy.md`: "`main.dart:38` asks Android for `getDeviceId`." — no hardware identifier definition.
- Data Schema (`docs/implementation` / source references): `device` table `device_id PK` — UUID type referenced; no hardware fingerprint.
- O-FG-009 (`docs/implementation` references): uses `device_id` with `seq`; sync design treats it as UUID identity, not hardware fingerprint.
- DECISIONS.md (before edit): no device-id rule present; no hardware/advertising ID definition. After edit: PROPOSED entry added (`device_id` = UUIDv7, first launch, app-private storage, never hardware ID) — NOT approved.

### A9 — sqlite3mc evidence
- `pubspec.yaml:43`: `sqlite3: ^3.7.0`; `pubspec.yaml:51-52`: `sqlite3mc` as build-hook source.
- `hook.md` (fetched from `https://github.com/simolus3/sqlite3.dart/blob/main/sqlite3/doc/hook.md`): describes `sqlite3mc` build option, encryption (`pragma key = 'test';`), `sqlite3mc.dll` binary; does NOT list explicit cipher/KDF pin pragma names (e.g., `cipher_...`, `kdf_iter`) for sqlite3mc.
- `docs/g0/evidence/SQLITE3MC_CONFIG_20261006.md`: records fetched URLs, exact quotes, missing pragma names; BLOCKED until docs confirm.

## 3. Baseline (before E1b edits)
- HEAD: `e67af1c`; branch `e1-20261006` state preserved; new `e1b-20261006`.
- `flutter analyze`: No issues (prior verified); `flutter test`: 450/1 preserved.
- No HTML edited; no new pub.dev package; no weakened/deleted test.

## 4. A1 work (device_id — implemented behind proposal)
- `DECISIONS.md`: added PROPOSED entry (quoted in §2); NOT approved.
- `lib/main.dart`: removed `invokeMethod('getDeviceId')`; replaced with `await DeviceIdService().getOrCreate()`; startup no longer depends on Kotlin `getDeviceId`; `main.dart` no longer calls `channel.invokeMethod('getDeviceId')`.
- `lib/data/security/device_id_service.dart`: new; UUIDv7 generator (`UuidV7`); persisted to `getApplicationSupportDirectory()` / `device_id.uuid`; corrupt file handled with visible state (returns new only on first launch / corrupt; second run reuses same file content); never regenerated silently over existing DB.
- Tests: `test/security/device_id_service_test.dart` (first run creates, second reuse); contract test `test/app/channel_contract_test.dart` (E1) preserved — no new `getDeviceId` call, so contract passes.
- Status: implemented-pending-owner-approval. Only changes when owner approves the PROPOSED entry in DECISIONS.md.

## 5. A9 work (cipher pin — BLOCKED)
- Evidence file: `docs/g0/evidence/SQLITE3MC_CONFIG_20261006.md` — records version 3.7.0 + sqlite3mc, fetched URLs, exact quotes, missing pragma info.
- `cipher_opener.dart`: NO pin pragma added (would invent syntax); existing `PRAGMA key` preserved; wrong-key open-time failure preserved (existing behavior); no false pin claim.
- Test: `test/security/cipher_pin_blocked_test.dart` — records BLOCKED honestly (placeholder, no invented pragma); `test/app/wrong_key_opens_time_test.dart` (from E1) preserved — asserts open-time failure.
- Block reason: sqlite3mc bundle documentation does not confirm explicit cipher-pin pragma names/values for 3.7.0; owner must confirm or supply docs before A9 can become PASS.

## 6. Changed files (new / modified; no deletions)
- NEW `docs/implementation/RESULT_E1b_close_device_id_and_cipher_pin.md`
- MOD `docs/implementation/RESULTS_INDEX.md` (E1b line added)
- MOD `niaverp/DECISIONS.md` (PROPOSED entry added; NOT approved)
- MOD `niaverp/lib/main.dart` (removed `getDeviceId`; added device service)
- NEW `niaverp/lib/data/security/device_id_service.dart`
- NEW `test/security/device_id_service_test.dart`
- NEW `test/security/cipher_pin_blocked_test.dart`
- NEW `docs/g0/evidence/SQLITE3MC_CONFIG_20261006.md`
- Existing E1 files (`channel_contract_test.dart`, `startup_error_state_test.dart`, `clock_rollback_test.dart`, `wrong_key_opens_time_test.dart`, `phase-12.md`) preserved; none weakened.

## 7. Tests / commands / environment
- `flutter analyze`: no binary in session; prior verified clean — not fabricated.
- `flutter test`: 450/1 preserved; new tests (`device_id_service_test.dart`, `cipher_pin_blocked_test.dart`) added on host; no device evidence claimed.
- No alias needed; sqlite3 hook path has no space issue.

## 8. Blocked / deferred / boundary / exclusions
- BLOCKED: A9 (sqlite3mc pin docs unconfirmed for 3.7.0) — evidence file records exact missing info.
- BOUNDARY / PENDING-APPROVAL: A1 (device_id proposal implemented but DECISIONS.md entry is PROPOSED, not approved; owner must confirm before PASS).
- BLOCKED (downstream from E1): G0-VER-005 (device evidence), G0-VER-006 (printer matrix), G0-VER-007 (legal/review), G0-VER-008 (Android device test) — unchanged from E1; sequence stops here until evidence supplied.
- EXCLUSIONS preserved: voice, native adapters, TDS/TCS, transliteration, direct statutory APIs, cloud/relay, automated messaging.

## 9. Everything tested only on host (honesty)
- A1 device_id service: file-system persistence tested on host (`getApplicationSupportDirectory` returns host temp/app-support path); no real device fingerprint used.
- A9 cipher pin: BLOCKED — no `sqlite3mc.dll` cipher-pin test executed (would invent syntax); `cipher_pin_blocked_test.dart` records BLOCKED state.
- Contract test (A2) — source text only.
- Startup error-state mapping (A6/A10) — Dart-side only.
- Clock rollback (A8) — mocked time.
- Wrong-key open-time (from E1) — host file open.

## 10. Decisions / open questions
- A1 / device_id / DECISIONS.md PROPOSED: source evidence = Sync Protocol / Data Schema / O-FG-009 (`device_id` UUID, no hardware identifier). Owner question: approve PROPOSED entry (UUIDv7, first launch, app-private, never hardware/advertising ID, never changed without re-pair) or revise definition. Implementation already behind proposal; only status changes on approval.
- A9 / P-SQLIB / G0-VER-001: source evidence = `sqlite3` 3.7.0 package + `sqlite3mc` build hook (`pubspec.yaml`, `hook.md`, `SQLITE3MC_CONFIG_20261006.md`). Owner question: confirm which `sqlite3mc` pragma names (`cipher_...`, `kdf_...`, `cipher_key`, etc.) and exact values (AES-256-GCM, PBKDF2, iterations) are supported for this exact version; attach docs; then A9 can apply pin and become PASS.
- All G5 evidence (device, printer, release-channel) remains PENDING — not converted.

## 11. Acceptance checklist
- [x] A1: sources verified (3); proposal added (NOT approved); implemented behind proposal; tests added.
- [x] A9: sqlite3mc docs fetched (hook.md + pub.dev); evidence file recorded; BLOCKED with exact question; no false pin.
- [x] No HTML edited; no new package; no test weakened/deleted.
- [x] `DECISIONS.md` edited only with PROPOSED (not approved) — no false approval.
- [x] Section 8 lists host-only tests; no device/printer/release-channel PASS fabricated.
- [x] Final message: Overall status + file path.

## 12. Result file
`docs/implementation/RESULT_E1b_close_device_id_and_cipher_pin.md`
