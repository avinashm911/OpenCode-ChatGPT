# New-PC setup (Windows, plain English, numbered steps)
Date (UTC): 2026-10-07. Reference versions below are measured on the first PC (see `docs/implementation/evidence/setup_new_pc_versions_20261007.txt`).

## Part A — One-time setup
1. Install **Git for Windows** (default options) and **Android Studio** (this installs the Android SDK + a Java).
2. Clone into a folder **without spaces** (the cipher library build breaks on spaced paths):
   ```powershell
   git clone <repo-url> E:\niaverp-root
   cd E:\niaverp-root
   ```
3. Install **Flutter 3.47.6 (stable)** — the project's `tools/flutter` folder is NOT in git, so each PC installs its own. Unzip to a no-space path (e.g. `E:\tools\flutter`) and add `E:\tools\flutter\bin` to your user PATH.
4. Check the version (must say 3.47.6 / Dart 3.13.5):
   ```powershell
   flutter --version
   ```
5. Accept Android licences and verify the toolchain:
   ```powershell
   flutter doctor --android-licenses
   flutter doctor
   ```
   Expect on a healthy PC: Android SDK 36.0.0 present, all licences accepted. Notes from PC1: Java comes bundled with Android Studio (PC1: OpenJDK 25.0.3; no separate Java 17 install needed locally — CI uses Temurin 17 itself); Visual Studio "not installed" is fine (we build Android only, not Windows desktop).
6. Get the app packages (from inside the app folder):
   ```powershell
   cd E:\niaverp-root\niaverp
   flutter pub get
   ```
7. Prove the PC works — analyze and full test:
   ```powershell
   flutter analyze
   flutter test
   ```
   Healthy baseline (2026-10-07): analyze clean on changed files; suite **466 passed / 0 failed / 2 skipped**. Any failure here stops you — do not build until tests pass.
8. Optional: confirm a debug build works with no keystore: `flutter build apk --debug`.

## Part B — Daily routine (both PCs)
1. Morning: `git pull` (on branch `e3-20261006` unless told otherwise). If it reports a conflict, STOP and resolve by hand — never force-push.
2. Work, then check what changed: `git status`.
3. Stage only intended files (`git add <paths>`), commit with a clear message (`git commit -m "..."`), then `git push origin e3-20261006`.
4. Never commit: `*.jks`, `*.b64`, passwords, or anything under `build/` (git already ignores `build/` and `outputs/`).
5. End of day: push so the other PC can pull tomorrow.
