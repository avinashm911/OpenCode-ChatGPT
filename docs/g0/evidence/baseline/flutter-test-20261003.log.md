# Baseline scaffold test evidence — 2026-10-03 (UTC)

## Command
Workdir: `E:\NiavERP v2 OpenAI\niaverp`
```
& "C:\Users\USER\.openclaw-autoclaw\agents\auto-designer\workspace\.cluster\tools\flutter\bin\flutter.bat" test
```

## Environment
- OS: Microsoft Windows 10 Pro 64-bit, 22H2 (Build 10.0.19045.6466), locale en-IN
- Flutter: 3.47.5, channel stable, Framework revision 6a19cca564 (2026-09-17), Engine revision af7e796e16
- Dart: 3.13.4, DevTools 2.60.0
- Flutter SDK path: `C:\Users\USER\.openclaw-autoclaw\agents\auto-designer\workspace\.cluster\tools\flutter`
- Android SDK: `C:\Users\USER\AppData\Local\Android\sdk`, SDK 36.0.0, Platform android-37.0, build-tools 36.0.0
- Java: OpenJDK 25.0.3 (Android Studio JBR at `C:\Program Files\Android\Android Studio\jbr\bin\java`); app compileOptions JavaVersion.VERSION_17
- Project: `niaverp` 1.0.0+1, `com.niaverp.niaverp`, minSdk 26 (pinned for G0), targetSdk/compileSdk = flutter-resolved

## Result
```
00:00 +0: loading E:/NiavERP v2 OpenAI/niaverp/test/widget_test.dart
00:00 +0: Counter increments smoke test
00:00 +1: All tests passed!
```
- Passed: 1 (default template `Counter increments smoke test` in `niaverp/test/widget_test.dart`)
- Failed: 0
- Blocked: 0 (baseline scaffold only; no business fixtures exist yet)

## Notes
- This is the unmodified Flutter template smoke test. It proves the scaffold builds and the test harness runs.
- It does NOT prove any NiAvERP business rule (GST rounding, costing, settlement, locks, sync, security, print). Those fixtures belong to Phases 1-6.
- Traceability: scaffold validation only; business traceability IDs are listed in `docs/g0/PROJECT_BASELINE.md`.
