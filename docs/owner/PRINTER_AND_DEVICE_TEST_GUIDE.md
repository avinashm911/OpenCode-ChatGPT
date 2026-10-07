# Printer + device test guide (shop-floor steps, Windows PC + Android phone)
Date (UTC): 2026-10-07. Plain-English version of `docs/g0/evidence/printers/PRINTER_TEST_SHEET.md` and `docs/g0/evidence/android/DEVICE_TEST_PROCEDURE.md`. Nothing is decided here; you only run steps and save proof. No row passes without its evidence file.

## You need
1. The test APK installed on the phone (ask the team which build; write its version below).
2. A Windows PC with `adb` (comes with Android Studio): plug the phone in with USB, allow USB debugging when asked.
3. Check the connection on the PC:
   ```powershell
   adb devices
   ```
   Your phone's serial must appear. If not, stop — fix the cable/drivers first.
4. Printers (ask the owner which exact models — the frozen list): one 58 mm thermal, one 80 mm thermal; PDF needs no printer (share to WhatsApp/email/Drive and open it).

## Where to save photos (exact folders)
- Printer photos/PDFs: `docs/g0/evidence/printers/` (name like `58mm-<model>-<date>.jpg`)
- Phone screenshots + log files: `docs/g0/evidence/android/` (name like `D-KEY-01-<model>-<date>.txt`)
- Write the phone's fingerprint FIRST (all 4 lines) into each result note:
  ```powershell
  adb shell getprop ro.product.model
  adb shell getprop ro.build.version.release
  adb shell getprop ro.build.version.sdk
  adb shell getprop ro.build.display.id
  ```

## Part A — Printer checks (one block per printer, copy this)
1. In the app, open any posted sales bill → **Print/Share** → send to the printer (or share the PDF).
2. Check and tick: text readable [ ]; shop name + items correct [ ]; amounts/paise exact [ ]; tax lines match the bill [ ]; nothing cut off at edges [ ]; Hindi/Gujarati prints as proper letters (not boxes) [ ].
3. For thermal: pull the plug mid-print once, then reprint — tick: reprint works [ ].
4. Save a photo of every printout in the printers folder. Fill one result block per printer:
   `Printer / Connection / Android+model / Paper size / PASS-or-FAIL per check above / photo path`.

## Part B — Phone checks (tap sequences; save what the app shows)
1. **First open:** fresh install → open app → tick: company screen opens, no error [ ]. Save: photo.
2. **Lock test:** lock the phone, unlock, reopen app → tick: app asks/stays locked as designed, no data visible while locked [ ]. Save: photo.
3. **Wrong PIN:** enter a wrong PIN/biometric → tick: stays locked, no fallback [ ]. Save: the exact message shown.
4. **Clock test:** change phone date past the trial end, reopen → tick: app shows read-only + still allows export/backup; your data is NOT deleted [ ]. Set the date back afterwards. Save: photos.
5. **Backup test:** in-app backup → copy the backup file to the PC → restore it → tick: opens fine [ ]. Then change one letter in the copied file, restore → tick: app REFUSES it [ ]. Save: both results.
6. **Reinstall test:** uninstall the app, reinstall, try to open old data → tick: app demands setup again instead of silently opening [ ]. Save: photo.
7. Collect the app's internal log after any failure: `adb logcat -d > D-<step>-<model>-<date>.txt` and save it in the android folder.

APK version tested: __________ Phone model(s): __________ Date: __________ Tester name: __________
