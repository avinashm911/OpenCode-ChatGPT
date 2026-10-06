# BASELINE REAL — 2026-10-06 (FLUTTER NOW FOUND; REAL OUTPUTS SAVED)

## Tool found (real command, not assumed)
- Path: `E:\NiavERP v2 OpenAI\tools\flutter\bin\flutter.bat`
- `flutter --version` real output: `Flutter 3.47.6 • channel stable • ... • Dart 3.13.5`
- This matches earlier run notes (`3.47.x`); `pubspec.yaml` `sdk: ^3.13.4` satisfied (Dart 3.13.5).

## Commands executed with REAL pasted output

### 1. flutter --version (real)
```
Flutter 3.47.6 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 5fc346839b ... 2026-09-30
Engine • hash b8c8d3d8d5d0095127057f8a29ca8cc53da2167c ... 2026-09-30
Tools • Dart 3.13.5 • DevTools 2.60.0
```

### 2. flutter pub get (from niaverp, real)
```
Resolving dependencies...
Downloading packages...
  cupertino_icons 1.0.9 (2.0.0 available)
  material_color_utilities 0.13.0 (0.13.1 available)
  test_api 0.7.12 (0.7.14 available)
  vector_math 2.4.0 (2.4.3 available)
Got dependencies!
4 packages have newer versions incompatible with dependency constraints.
```
Exit: success (True). No fabricated dependency resolution.

### 3. flutter analyze (real — embedded full text; 30 lines; 20 issues)
```
Analyzing niaverp...
   info - imported package 'path_provider' isn't a dependency ... device_id_service.dart:5:8
  error - Target of URI doesn't exist ... device_id_service.dart:5:8
  error - undefined_method 'getApplicationSupportDirectory' ... device_id_service.dart:15:23
  error - Undefined name 'l10n' ... parties_items_screen.dart:698:29 / 698:57 / 751:23 / 756:33 / 756:58
  error - The getter 'id' isn't defined for the type 'CompanyId' ... niav_shell.dart:147:58 / 153:61 / 159:66 / 169:61 / 175:58
  error - property 'isNotEmpty' can't be unconditionally accessed ... localization_source_test.dart:15:44
   info - Missing type annotation ... shell_test.dart:200:5
  error - Expected an identifier ... shell_test.dart:200:17 / 200:88
  error - Expected to find ')' ... shell_test.dart:200:110
  error - A function body must be provided ... shell_test.dart:214:7
flutter.bat : 20 issues found. (ran in 5.4s)
```
Full saved at workspace `analyze_full_20261006.txt`.

### 4. flutter test (real — embedded full text; 25 lines; build hook failure)
```
flutter.bat : 'E:\NiavERP' is not recognized ... (path split by space in workspace folder)
Building native assets for package:sqlite3 failed.
Compilation of hook returned with exit code: 1.
... build.dart stderr: 'E:\NiavERP' is not recognized ...
Building native assets failed. See the logs for more details.
```
Full saved at workspace `test_full_20261006.txt`.
Root cause (honest, not invented): workspace path `E:\NiavERP v2 OpenAI` contains spaces; sqlite3 3.7.0 build hook (`hook/build.dart`) splits on spaces incorrectly when compiling the kernel. No code fix yet attempted.

## Errors grouped by cause (from REAL outputs)
A. MISSING DEPENDENCY (analyze, 3 errors):
- `device_id_service.dart`: `path_provider` not in `pubspec.yaml`; `getApplicationSupportDirectory` undefined.
B. EDITING ERRORS FROM E2 / E3 (analyze, 11 errors):
- `parties_items_screen.dart`: `l10n` undefined at lines 698/751/756 (my E2 edit used `l10n.t` without importing / defining localizations variable — real error, real fix needed).
- `niav_shell.dart`: `CompanyId.id` getter missing at 147/153/159/169/175 (my E2 edit added `${company.id}` key injection but `CompanyId` value object doesn't expose `.id`; real error).
- `test/presentation/localization_source_test.dart`: null-check missing at 15 (new E2 test needs fix).
- `test/presentation/shell_test.dart`: syntax broken at 200/214 (my E2 A3 test insertion corrupted syntax — real error).
C. BUILD HOOK / RUNTIME (test, 1 group):
- `sqlite3` native asset compilation fails due to space-in-path; test never starts.

## Count: test declarations vs actually run
- Declarations (prior reports / code): E1 128-test state; E2 added tests; total ~450/1 pre-existing failure preserved.
- Actually executed this session: 0 test cases completed (test binary never reached test runner; native-asset build blocked). Analyze completed (20 issues).
- Gap explanation: gap is BUILD-PIPELINE / PATH + EDIT ERRORS, not hidden passing tests. The 450/1 failure count from earlier runs is preserved but NOT re-verified because the tool never reached execution.

## What changed (only documentation / baseline — NO code fixes yet, per instruction)
- Read AGENTS.md, DECISIONS.md.
- Found Flutter 3.47.6 / Dart 3.13.5.
- Ran `pub get` (success), `analyze` (20 issues), `test` (build blocked).
- Created/updated `docs/implementation/BASELINE_REAL_20261006.md`; saved `analyse_full_20261006.txt` and `test_full_20261006.txt`.
- No code edited; no tests weakened/deleted; no false PASS.
- One git commit on `e3-20261006`: `020220d`.

## What still needs the owner (plain-English, non-technical)
- Confirm whether workspace can be moved to a folder without spaces (e.g., `E:\niaverp`) so the cipher library builds — OR tell me how to handle the path split.
- Confirm `device_id` proposal (DECISIONS.md PROPOSED) — implement or reject before fixing `device_id_service.dart`.
- Confirm `path_provider` is allowed / needed; or provide the correct dependency.
- Confirm localizations setup (`l10n`) for party/item dialog strings (E2 edits used it without full import); or revert edits.
- Confirm `CompanyId.id` getter definition (or use the correct property) before fixing shell tabs.
- Fix the broken `shell_test.dart` syntax from E2 A3 test insertion.
- Supply G5 evidence (device/printer/release) or confirm A9 pin status to close master sequence.
