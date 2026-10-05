# Android device test procedure — Phase 3 (v0.8 scaffolding)

Date (UTC): 2026-10-03
Prompt authority: `NiAv_G0_Prompts_Pack_v0.8.md` Phase 3
Related: `DEVICE_MATRIX.md` (measured fingerprint), `security-test-20261003.log.md` (host PASS)
Status vocabulary (v0.8): device items are PENDING-INPUT (DEVICE) until executed on hardware; host tests prove only what they run on — stated plainly in evidence.

> Host-side tests do **not** prove Android Keystore or FileProvider behavior
> on a device. Every device row below is PENDING-INPUT until run on the named
> device with captured evidence. Do not simulate a pass.

Global rules applied: no weakened encryption, no licence bypass, no hidden
recovery path; uninstall removes Keystore keys so encrypted-backup restore
after reinstall must demand re-provisioning.

---

## A. What is ready to run

On-device tests exist as **manual procedures + future integration tests**
(host contracts in `niaverp/lib/data/security/` are the frozen behavior the
device run must confirm):

- `key_lifecycle.dart` — provision → available → lock → unlock; auth-fail stays unusable; corrupt/unavailable fails safely; wipe → missing (re-provision only).
- `entitlements.dart` — trialActive → graceActive (10-day, daily reminder) → expired (read-only + export + backup, data never deleted); denylisted denies in every clock state.
- `share_policy.dart` — allowlist enforced at the provider boundary.
- `backup.dart` — manifest hash re-verified before touching live DB; newer-schema refused; post-reinstall re-provision forced.

A future `integration_test/` harness (to be added when the SQLCipher-class
library is confirmed under G0-VER-001) will drive these contracts on-device.
Until then, the manual steps below are the executable procedure.

---

## B. Manual procedure (execute per device: Android 8 + current)

### Preconditions

1. Install the trial APK on the device (exact build recorded in result row).
2. Record fingerprint first:
   `adb shell getprop ro.product.model`, `ro.product.manufacturer`,
   `ro.build.version.release`, `ro.build.version.sdk`,
   `ro.build.display.id`, plus `adb shell sqlite3 --version` (or app-reported SQLite version).
3. Confirm Keystore stack present (current-side reference):
   `adb shell dumpsys android.security.keystore` shows app alias after provision.

### Steps

| Step | Action | Expected (app must show) | Record |
|---|---|---|---|
| D-KEY-01 | Fresh install → provision trial key → open DB | DB opens; alias visible in keystore dumpsys | logcat + dumpsys excerpt |
| D-KEY-02 | Background/lock → foreground without auth | App reports locked; key unusable; no data shown | screenshot + logcat |
| D-KEY-03 | Unlock with wrong PIN/biometric | `authFailed`; stays locked; no fallback/plaintext | logcat line |
| D-KEY-04 | Corrupt wrapped blob (test build flag) or revoke auth | Safe failure; re-provision demanded; no plaintext | logcat line |
| D-KEY-05 | `adb uninstall` → reinstall → attempt open without re-provision | Refused; re-provisioning demanded (keys do not survive uninstall) | screenshot + logcat |
| D-TRIAL-01 | Set clock across trial end / grace day 10 / day 11 boundaries | Full function → full + daily reminder → read-only + export + backup | screenshots per boundary |
| D-TRIAL-02 | Add install key hash to `denylist_entry` → every screen | Denied everywhere regardless of clock | screenshot + DB row |
| D-SHARE-01 | Share jpg/png/pdf/xlsx/csv via sheet | Receiving app gets bytes only for allowed; correct sizes | captured files + log |
| D-SHARE-02 | Attempt apk/db/exe/txt/oversize/spoofed-magic share | Denied at boundary; nothing leaves app-private storage | log line per attempt |
| D-BKP-01 | Create backup → copy off-device → restore intact | Opens; manifest hash matches; version accepted | manifest + log |
| D-BKP-02 | Tamper one payload byte → restore | Refused: `payload hash mismatch` | log line |
| D-BKP-03 | Craft newer-schema manifest → restore on older app | Refused: `newer than app` (no in-place downgrade) | log line |
| D-BKP-04 | Uninstall → reinstall → restore encrypted backup | Decrypt **not** attempted until re-provision completes | logcat + screenshot |

Exact owner command per row: the `adb` command or manual tap sequence above,
run on the assigned device. No step may be marked PASS without the evidence
file named in the result row.

---

## C. Result template (copy one block per device × step)

```text
Device: <model> / <manufacturer>
Android: <release> / API <sdk>
Build: <ro.build.display.id>
SQLite: <version>
APK build: <versionName/versionCode + checksum>
Step: <D-KEY-01 … D-BKP-04>
Command / manual step: <exact adb command or tap sequence>
Result: PASS | FAIL | PENDING-INPUT (DEVICE)
Evidence path: <docs/g0/evidence/android/<file>>
Notes: <logcat lines / screenshots / deviations>
```

### Current open rows (v0.8 PENDING-INPUT)

| Row | Device slot | Status | Missing input |
|---|---|---|---|
| D-KEY-01…05 (min) | Android 8 / API 26 | PENDING-INPUT (DEVICE) | Android 8 device (model/version/build) + confirmed SQLCipher-class lib (G0-VER-001) + Keystore run (G0-VER-005) |
| D-KEY-01…05 (current) | Current Android | PENDING-INPUT (DEVICE) | App platform wiring on confirmed lib; emulator `niav_test` (API 36, BE2A.250530.026.F3) characterized and ready |
| D-TRIAL/SHARE/BKP (both) | Both | PENDING-INPUT (DEVICE) | Same as above + FileProvider authority wiring (G0-VER-008) |

Smallest owner questions:

1. Which physical or AVD **Android 8 (API 26)** device is assigned (model, version, build)? — closes min-side rows (G0-VER-005/008).
2. Which **SQLCipher-class library + version + licence evidence** is approved (G0-VER-001), so native wiring + current-side emulator run may be executed?

---

## D. Change log

| Date | Change | Traceability |
|---|---|---|
| 2026-10-03 | v0.8 scaffolding: manual procedure + result template created; no device PASS claimed; host evidence cited, not re-claimed | Phase 3; D-06; G0-VER-001/005/008; O-M04 |
