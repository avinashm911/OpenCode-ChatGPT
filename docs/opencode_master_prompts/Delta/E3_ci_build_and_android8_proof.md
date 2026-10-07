# E3 — Automated build and Android 8 emulator proof

## Mandatory first actions
Same as E1; branch `e3-<date>`; read `RESULT_E1_*`, `RESULT_E2_*`, `docs/g0/DEVICE_TEST_PROCEDURE.md` if present (find it with a search under `docs/g0`), `docs/g0/PENDING_INPUTS.md` rows P-SQLIB, P-DEVICE-8, P-KEYSTORE, P-APK-SHA. No new pub.dev packages (CI workflow actions are not Dart packages). Never print or commit keystore files or passwords.

## Work
A. Build configuration (`niaverp/android/app/build.gradle.kts`, `pubspec.yaml`)
A1. Replace the template `applicationId` `com.niaverp.niaverp`: use the id recorded in docs/DECISIONS. If none is recorded, keep the current id and list it as an owner question (changing it later breaks upgrades). Same for app label and launcher icon: do not invent branding.
A2. The release-signing guard must fail only when a release task is requested, never on debug builds. Check that the keystore file exists, not just the property. Read all four `NIAV_RELEASE_*` properties from the environment/Gradle properties.
A3. Take version name and code from CI inputs (`--build-name`, `--build-number`) and document it.

B. CI workflow `.github/workflows/build.yml` (only if the repo is hosted on GitHub, which it is)
B1. Steps: checkout; pin Java 17; pin the Flutter version already used (read it from the environment notes or `pubspec.yaml` `environment`); accept Android licences; generate `local.properties`; `flutter pub get`; `flutter analyze`; `flutter test`; `flutter build apk --release` with signing from repository secrets; compute SHA-256 of the APK; upload APK, checksum and logs as artifacts.
B2. A second job runs on an **API 26 emulator** (use a maintained emulator-runner action; pin by version) that installs the debug or release APK, launches it, and captures logcat. Add a small instrumented smoke check that the app reaches the home screen (the encrypted DB opened), and that a relaunch still opens the same data.
B3. Pin every third-party action to a version or commit; record each with its licence/purpose in `docs/implementation/CI_DEPENDENCIES.md`.

C. Evidence records (honesty rules apply)
C1. Under `docs/g0/evidence/android/`, add `EMULATOR_API26_RUN_<date>.md` from the real CI logs only (fingerprint, API level, logcat excerpt, result). If CI cannot be run from this session, create the templates and mark the evidence PENDING-INPUT; do not write results you did not observe.
C2. Record the bundled cipher library licence text from the native asset manifest in `docs/g0/evidence/` (read it from the build output; if unavailable, say so).
C3. Do not change any row in `PENDING_INPUTS.md`; add a dated addition-only note. An emulator run is labelled "AVD evidence", never "physical device".

## Owner actions (list them, do not attempt)
Create the four repository secrets; confirm that an AVD is acceptable for G0-VER-001/005; decide applicationId/app name/icon if undecided.

## Required output
`docs/implementation/RESULT_E3_ci_build_and_android8_proof.md` (nine sections), index line `E3 | ...`, final message with Overall status and path only.
