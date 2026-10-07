# CI dependencies — locked versions / commit / licence / purpose (rewritten 2026-10-07)
# No new pub.dev packages; workflow actions are CI-only, not Dart packages.
# SHAs below were resolved with `git ls-remote` on 2026-10-07 and are the exact
# commits the tags pointed to that day. `# vX` comments in build.yml record the tag.
| Action | Pinned commit (SHA) | Tag at pin time | Licence / Source | Purpose |
|---|---|---|---|---|
| actions/checkout | 11d5960a326750d5838078e36cf38b85af677262 | v4 (v4.4.0) | MIT (GitHub) | Source checkout (all jobs) |
| actions/setup-java | cf277c60eb25467037889841efdb72551f06f6c3 | v4 (v4.9.1) | MIT | Java 17 (temurin) pin |
| subosito/flutter-action | 1a449444c387b1966244ae4d4f8c696479add0b2 | v2 | MIT | Flutter 3.47.6 pin (matches pubspec sdk ^3.13.4; Dart 3.13.5) |
| actions/upload-artifact | ea165f8d65b6e75b540449e92b4886f43607fa02 | v4 (v4.6.2) | MIT | Upload debug APK; release APK + SHA; emulator logcat |
| actions/download-artifact | d3f86a106a0bac45b974a628896c90dbdf5c8093 | v4 (v4.3.0) | MIT | Emulator job downloads the debug APK artifact |
| reactivecircus/android-emulator-runner | a421e43855164a8197daf9d8d40fe71c6996bb0d | v2 | MIT | API 26 x86_64 emulator; single-line `script: bash ci/emulator_smoke.sh` (AVD, not physical device) |

Notes: every `uses:` is pinned to a full commit SHA (no floating tags); no unverified actions; secrets referenced by name only, values never printed.
Emulator job extras (no new actions): KVM group-permissions step, verbatim from the android-emulator-runner README at the pinned commit; smoke logic lives in committed `ci/emulator_smoke.sh` (`set -euo pipefail`).
Toolchain: Flutter 3.47.6 / Java 17 temurin, declared once in workflow `env`.
Secrets (release job only; debug + emulator jobs use none): `NIAV_RELEASE_KEYSTORE_B64`, `NIAV_RELEASE_STORE_PASSWORD`, `NIAV_RELEASE_KEY_ALIAS`, `NIAV_RELEASE_KEY_PASSWORD`.
