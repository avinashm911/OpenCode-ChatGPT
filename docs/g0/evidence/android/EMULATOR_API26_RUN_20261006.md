# Emulator API 26 run — E3 (AVD EVIDENCE, not a physical device)
Date (UTC): 2026-10-07. Status: EXECUTED — real GitHub Actions run, emulator (AVD) evidence only. This is NOT physical-device evidence: G0-VER-005/008 and P-DEVICE-8/CUR stay PENDING-INPUT.

## Run (real values from the GitHub API)
- Run: https://github.com/avinashm911/OpenCode-ChatGPT/actions/runs/37576254060
- Commit: 1d9ebd5d198479386f061f538b7883245113bffc · Branch: e3-20261006 · Event: push · Created: 2026-10-07T05:25:45Z
- Job conclusions: `Debug APK (no secrets)` = success · `Release APK (keystore secrets)` = skipped (manual-only by design) · `Android 8 emulator smoke test` = success

## Device fingerprint (real, from `emulator-fingerprint.txt`)
- ro.product.model: `Android SDK built for x86_64`
- ro.build.version.release: `8.0.0`
- ro.build.version.sdk: `26`
- ro.build.display.id: NOT captured (the smoke script does not read it — not invented here)

## Smoke result (real, from the job + captured logcat)
- `adb install apk/app-debug.apk`: succeeded (job would fail otherwise)
- `adb shell am start -n com.niaverp.niaverp/com.niaverp.niaverp.MainActivity`: START logged (`ActivityManager: START u0 ... cmp=com.niaverp.niaverp/.MainActivity`), process started (`Start proc 2853:com.niaverp.niaverp/u0a65`)
- `pidof com.niaverp.niaverp` at +25s: non-empty (job asserts this; a missing process fails the job, and the job passed)
- `FATAL EXCEPTION` in captured logcat: 0 occurrences (counted locally)
- `has died` / `has crashed` / `ANR in com.niaverp` in captured logcat: none found

## Artifacts (downloaded from the run, unmodified)
- `docs/g0/evidence/android/emulator-api26-37576254060/emulator-api26-logcat.txt` (541,150 bytes)
- `docs/g0/evidence/android/emulator-api26-37576254060/emulator-fingerprint.txt` (38 bytes)

## NOT covered (still pending, not claimed)
- No APK SHA-256 (the debug job does not compute one; only the release job does, and it was skipped)
- No relaunch-on-same-database check on the emulator (smoke launches once)
- No D-KEY/D-TRIAL/D-SHARE/D-BKP device steps (procedure `DEVICE_TEST_PROCEDURE.md` §B untouched)
- No physical Android 8 device: P-DEVICE-8/P-DEVICE-CUR unchanged
