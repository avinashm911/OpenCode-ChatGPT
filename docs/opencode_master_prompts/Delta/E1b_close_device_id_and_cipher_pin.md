# E1b — Close E1 blocks A1 (device id) and A9 (cipher pin)

## Mandatory first actions
Read `niaverp/AGENTS.md`, `DECISIONS.md`, `GLOBAL_NO_INVENTION_CONTRACT.md`, `docs/implementation/RESULT_E1_*.md`. Run `flutter analyze` and `flutter test`, record totals; stop with FAIL if not green. New branch `e1b-<date>`. No HTML edits, no new packages, no weakened tests.

## A1. device_id
Source evidence: the Sync Protocol Specification defines `device_id` as type UUID, "Originating trusted device"; the Data Schema has `device(device_id PK, ...)`; O-FG-009 uses `device_id` with `seq`. No document defines a hardware identifier.
1. Re-verify those three sources by grep and cite file and text in the results file.
2. Add a proposed entry to `DECISIONS.md` under a heading "PROPOSED (needs owner approval)": device_id = UUIDv7 generated once at first launch, persisted in app-private storage, never a hardware or advertising ID, never changed on restore without an explicit re-pair flow. Do NOT mark it approved.
3. Implement behind that proposal: remove the `getDeviceId` channel call from `main.dart`; generate and persist the id with the existing UUIDv7 generator; the contract test from E1 must still pass; add tests (first run creates, second run reuses, corrupt file handled with a visible state, never regenerated silently over an existing database).
4. Mark in the results file that A1 is implemented-pending-owner-approval.

## A9. cipher pin
1. Find the exact sqlite3mc version bundled by the `sqlite3` package version in `pubspec.lock`/hook configuration. Read its official documentation (WebFetch the project's documentation) for: default cipher, KDF iterations, and the pragma names to pin them.
2. Record in `docs/g0/evidence/` a file `SQLITE3MC_CONFIG_<date>.md` with the version, exact pragma names/values, and source URLs. Quote, do not paraphrase from memory. If the docs for that exact version cannot be fetched, mark BLOCKED with the exact question and stop this item.
3. If found: apply the pins right after `PRAGMA key` in `cipher_opener.dart`, add a test that a wrong key fails at open time, and a test that the pins are issued in the expected order using a recording engine.
4. Do not claim on-device verification.

## Required output
`docs/implementation/RESULT_E1b_close_device_id_and_cipher_pin.md` (nine sections), index line `E1b | ...`. End the final chat message with Overall status and path only.
