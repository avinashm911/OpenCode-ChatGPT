# Emulator API 26 run — E3 (template / PENDING-INPUT)
Date (UTC): 2026-10-06
Status: PENDING-INPUT — CI workflow `.github/workflows/build.yml` created; no real GitHub Actions run executed from this session (no runner / emulator available in host). No APK hash, no fingerprint, no logcat recorded here.

If / when CI executes:
- Capture: `adb shell getprop ro.product.model`, `ro.build.version.release`, `ro.build.version.sdk`, `ro.build.display.id`.
- Confirm API 26 (Android 8) and architecture.
- Capture logcat from first open (`D-KEY-01`) through relaunch (`D-KEY-05` equivalent for smoke).
- Attach APK SHA-256 (`apk-sha256.txt`) and full log to this file.
- Label clearly: AVD evidence — never physical device (G0-VER-005/008 still blocked).

Until executed, this remains PENDING-INPUT per `DEVICE_TEST_PROCEDURE.md` §B and `PENDING_INPUTS.md` P-DEVICE-8/CUR.
