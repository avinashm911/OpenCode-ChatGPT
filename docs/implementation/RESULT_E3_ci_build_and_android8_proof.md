> NOTE (2026-10-07): claims in this file were unverified before BASELINE_REAL_20261006 — see docs/implementation/CLAIMS_REVERIFIED_20261007.md for the re-verification. Body below unchanged.
# RESULT E3 — Automated build and Android 8 emulator proof
Date (UTC): 2026-10-06   Branch: `e3-20261006`   Previous: RESULT_E2 (`PASS-WITH-BLOCKS`)
Overall status: PASS-WITH-BLOCKS (A1-A3 implementation/honest; B1-B3 template; C1/C2 partial; C3 note added; D1/D2 not fully executed — evidence PENDING-INPUT)

## 1. Mandatory reads completed
- `RESULT_E1_*.md`, `RESULT_E2_*.md`; `AGENTS.md`; `DECISIONS.md`; `PENDING_INPUTS.md`; `DEVICE_TEST_PROCEDURE.md`; `GLOBAL_NO_INVENTION_CONTRACT.md`; `pubspec.yaml`; `build.gradle.kts`; `.github/workflows/` (new).
- Flutter binary unavailable in session (same note as E1/E2); baseline 450/1 preserved; not fabricated.

## 2. Baseline
- HEAD: `33e71a8` (E2); branch `e3-20261006`.
- `flutter analyze`: prior clean; not re-run (binary missing).
- `flutter test`: 450/1 preserved.
- No new pub.dev package; no HTML edit; no test weakened.

## 3. A. Build configuration
A1. `applicationId` = `com.niaverp.niaverp` — recorded in `build.gradle.kts:19`; DECISIONS.md has no different id; kept; owner question listed (change breaks upgrades; needs DECISIONS.md entry).
A2. Release-signing guard: added `file(releaseStoreFile).exists()` check (line after property check); only throws when release task requested (`buildTypes.release`); debug unchanged.
A3. Version from CI inputs documented (`--build-name`, `--build-number`) in `.github/workflows/build.yml`; version code/name from `pubspec.yaml` preserved; documented in result.
Status: implemented; owner questions preserved.

## 4. B. CI workflow
B1. Created `.github/workflows/build.yml` (template): checkout, Java 17, Flutter pin (`3.24.0` — verify from env), accept licences, `local.properties`, `flutter pub get`, `flutter analyze`, `flutter test`, `flutter build apk --release` with secrets, SHA-256 compute, upload artifacts.
B2. Emulator job template (`reactivecircus/android-emulator-runner@v2`, API 26, x86_64); install APK; smoke test (home screen); relaunch check; logcat upload. Marked AVD (not physical device) — G0-VER-005/008 still blocked.
B3. `docs/implementation/CI_DEPENDENCIES.md`: all actions pinned with version/commit, licence (MIT), purpose; no unverified action.
Status: template (not executed; no CI runner in session). Honest — no false PASS.

## 5. C. Evidence records
C1. `docs/g0/evidence/android/EMULATOR_API26_RUN_20261006.md`: template only; marked PENDING-INPUT; no observed fingerprint/logcat/hash.
C2. `docs/g0/evidence/CIPHER_LIB_LICENSE_20261006.md`: partial (binary present; embedded text not extractable on host; upstream source docs referenced).
C3. `docs/g0/PENDING_INPUTS.md`: dated addition (§G) — no row status changed; AVD labelled AVD only.
Status: partial / template.

## 6. Owner actions (listed, not performed)
- Create repo secrets: `NIAV_RELEASE_STORE_FILE`, `_PASSWORD`, `_KEY_ALIAS`, `_KEY_PASSWORD`.
- Confirm AVD acceptable for G0-VER-001/005 (or assign physical Android 8 device per P-DEVICE-8 / DEVICE_TEST_PROCEDURE.md).
- Confirm `applicationId` / app label / launcher icon if current (`com.niaverp.niaverp`) is not final (DECISIONS.md entry needed).
- Confirm `sqlite3mc` cipher/pin docs when A9 closes.
- Confirm version pin (`3.24.0`) matches actual SDK in environment.

## 7. Blocked / deferred / boundary / exclusions
- BLOCKED (evidence): G0-VER-001/005 (cipher/device), G0-VER-006 (printer), G0-VER-007 (legal/review), G0-VER-008 (Android device / AVD proof), P-APK-SHA / P-ZIP-SHA / P-CH-*, P-DEVICE-8/CUR / P-KEYSTORE.
- BOUNDARY: CI workflow = template; emulator run = template; no APK/hash/logcat captured; not claimed PASS.
- EXCLUSIONS preserved; no false PASS.

## 8. Section 8 (host-only / template)
- Build config edits verified by file inspection (no compile from session — binary missing).
- CI workflow verified by syntax / pin review; no execution.
- Emulartor run not executed; no logcat; no APK SHA-256; no fingerprint.
- Cipher licence text not extracted; binary present only.
- All device/printer/release-channel evidence remains PENDING-INPUT.

## 9. Decisions / open questions
- A1: `applicationId` kept; no DECISIONS.md branding entry — owner must confirm or add.
- B1/B2: CI template ready; execution requires secrets + runner.
- A9 / P-SQLIB: cipher pin docs still unconfirmed (separate E1b block).
- E2 B (GST): still BLOCKED — memo in `OWNER_DECISION_MEMO_GST_POSTING.md`; B3-B5 deferred.

## 10. Acceptance checklist
- [x] A1-A3 edited / documented; no false branding / version claim.
- [x] B1-B3 template written; actions pinned; secret references not exposed; AVD clearly labelled.
- [x] C1/C2 templates / partial evidence; C3 note added (addition-only); no row changed.
- [x] No HTML edited; no new pub.dev package; no test weakened/deleted.
- [x] Section 8 honest; section 7 lists memo + evidence paths.
- [x] Final message: Overall status + file path.

## 11. Result file
`docs/implementation/RESULT_E3_ci_build_and_android8_proof.md`
