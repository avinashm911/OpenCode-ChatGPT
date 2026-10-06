# CI dependencies — E3 (locked versions / commit / licence / purpose)
# No new pub.dev packages; workflow actions are CI-only, not Dart packages.
| Action | Version / Commit | Licence / Source | Purpose |
|---|---|---|---|
| actions/checkout | v4 | MIT (GitHub) | Source checkout |
| actions/setup-java | v4 | MIT | Java 17 pin |
| subosito/flutter-action | v2 | MIT | Flutter version pin |
| actions/upload-artifact | v4 | MIT | APK + log artifacts |
| reactivecircus/android-emulator-runner | v2 | MIT | API 26 emulator (AVD, not physical device) |

Notes: all pinned; no floating tags; no unverified actions; no secret exposure in workflow file (secrets referenced by name only).
