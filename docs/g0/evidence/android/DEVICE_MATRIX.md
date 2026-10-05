# Android device matrix — Phase 3 (2026-10-03 UTC)

The phase requires tests on the declared minimum Android version AND a
current supported version, with model/version/build recorded. This file is
that record. Items that could not be executed are BLOCKED (never
simulated-pass), with the exact missing input and the ready-to-run manual
procedure.

## Declared targets (O-M04)

| Slot | Requirement | Device available in this run |
|---|---|---|
| Minimum | Android 8 (API 26, minSdk 26) | **NONE — BLOCKED** (no API-26 hardware or AVD on this host) |
| Current | Supported release | **Emulator** (see fingerprint below) |

## Current-side device (booted live during this phase)

| Field | Value (measured via adb) |
|---|---|
| `flutter devices` before boot | Windows, Chrome, Edge only — no Android device |
| AVD | `niav_test` (target android-36, x86_64, no Play Store) |
| Boot command | `emulator -avd niav_test -no-snapshot -no-audio -no-boot-anim` → `emulator-5554 device`, `sys.boot_completed=1` (~60 s) |
| Model (`ro.product.model`) | sdk_gphone64_x86_64 |
| Manufacturer | Google |
| Android release / SDK | **16 / API 36** |
| Build (`ro.build.display.id`) | sdk_gphone64_x86_64-userdebug 16 BE2A.250530.026.F3 (dev-keys) |
| On-device SQLite | **3.44.3** (Docker: our DDL uses only basic CREATE/CHECK/FK syntax + PRAGMA guards, compatible) |
| Keystore stack | Present: `IKeyMintDevice`, `IRemotelyProvisionedComponent`, `IKeystoreAuthorization`, `ILegacyKeystore`, `IKeystoreMaintenance`, Gatekeeper + Fingerprint HALs |

## Per-item disposition

| Control | Host evidence (PASS) | On-device execution |
|---|---|---|
| Encrypted DB + key handling (D-06 shape) | Key lifecycle/failure contract + redaction tests PASS (`security-test-20261003.log.md`) | **BLOCKED**: SQLCipher-class library unconfirmed (G0-VER-001); no native wiring built on an unconfirmed lib |
| Keystore gen/wrap/fail on min Android | Failure taxonomy + safe-state tests PASS | **BLOCKED (min)**: no API-26 device. **BLOCKED (current)**: needs app platform wiring; emulator characterized and ready |
| Trial anchor lifecycle + denylist | Entitlement boundaries + DB tie-in tests PASS | On-device behavior run pending app build — **BLOCKED** |
| File-provider / share | Allowlist policy tests PASS (spoof/oversize/unknown denied) | Provider authority + on-device share sheet — **BLOCKED** |
| Backup / restore (incl. post-reinstall) | Manifest integrity, tamper detection, downgrade refusal, re-provision plan tests PASS | Encrypted round-trip on device — **BLOCKED** (needs lib + wiring) |

## Ready manual procedures (execute when blockers clear)

1. **Keystore (current emulator, repeat on min device)**: install trial APK →
   `adb shell dumpsys android.security.keystore` shows app alias; rotate device
   lock; revoke auth → app reports `authFailed`, stays locked (no fallback);
   `adb uninstall` → reinstall → restore backup → app demands re-provisioning
   (never auto-decrypts). Record logcat lines + screenshots under this dir.
2. **Trial/denylist**: set device clock across trial end / grace day 10 / day
   11 boundaries; confirm full function → reminder → read-only + export +
   backup; add key hash to denylist → denied everywhere.
3. **Share**: attempt share of jpg/png/pdf/xlsx/csv (allowed) and apk/db/txt
   (denied) via the share sheet; confirm receiving app gets bytes only for
   allowed.
4. **Backup/restore**: create backup → copy off-device → tamper one byte →
   restore refuses (hash); craft newer-schema manifest → restore refuses
   (downgrade); uninstall → reinstall → restore → re-provision demanded.

## Smallest owner questions
1. Which physical or AVD **Android 8 (API 26)** device is assigned for the min-side run (model, build)? — affects G0-VER-005/008.
2. Which **SQLCipher-class library + version + licence evidence** is approved (G0-VER-001), so native wiring may be built and the current-side emulator run executed?
