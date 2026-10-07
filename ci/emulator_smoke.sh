#!/usr/bin/env bash
# NiAvERP API-26 emulator smoke test.
# Executed by android-emulator-runner's single-line `script:` input as
# `bash ci/emulator_smoke.sh` (the action runs each script line separately,
# so multi-line shell control flow lives here instead of in build.yml).
# Expects the debug APK at apk/app-debug.apk (download-artifact step) and the
# repo root as working directory. Writes emulator-api26-logcat.txt and
# emulator-fingerprint.txt to the repo root for the upload step.
set -euo pipefail

APK="apk/app-debug.apk"
PKG="com.niaverp.niaverp"
MAIN="$PKG/$PKG.MainActivity"

if [ ! -f "$APK" ]; then
  echo "FATAL: $APK not found (did the download-artifact step run?)"
  exit 1
fi
adb install "$APK"
adb shell am start -n "$MAIN"
sleep 25
APP_PID="$(adb shell pidof "$PKG" | tr -d '\r')"
echo "app pid: $APP_PID"
if [ -z "$APP_PID" ]; then
  echo "FATAL: $PKG process is not alive after launch"
  adb logcat -d > emulator-api26-logcat.txt || true
  exit 1
fi
adb logcat -d > emulator-api26-logcat.txt
if grep -q "FATAL EXCEPTION" emulator-api26-logcat.txt; then
  echo "FATAL: FATAL EXCEPTION found in logcat"
  exit 1
fi
{
  adb shell getprop ro.product.model
  adb shell getprop ro.build.version.release
  adb shell getprop ro.build.version.sdk
} > emulator-fingerprint.txt
echo "SMOKE PASS: process alive, no FATAL EXCEPTION"
