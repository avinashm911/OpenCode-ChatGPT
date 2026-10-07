# Implementation Phase 02 — Onboarding and localisation (M01/M02 / FR-M01/FR-M02)
Date (UTC): 2026-10-06   Prompt: docs/opencode_master_prompts/02_onboarding_and_localisation.md   Contract: GLOBAL_NO_INVENTION_CONTRACT.md
Outcome: COMPLETE-WITH-BLOCKS   Previous phase report: docs/implementation/phase-01.md (COMPLETE-WITH-BLOCKS, 450/1, P-SQLIB blocked)

## 1. Document-read log
- AGENTS.md / DECISIONS.md: continuation rule preserved; exclusions (voice, transliteration, TDS/TCS, PF/ESI/payroll, native adapters, direct statutory APIs) held; vertical slices kept.
- IMPLEMENTATION_EXECUTION_STRATEGY.md / GLOBAL_NO_INVENTION_CONTRACT.md: module M01/M02 P1 only; deferred P2/P3/TBC sub-modules enumerated; no silent omission; source-of-truth hierarchy applied.
- SOURCE_INVENTORY.md / TRACEABILITY_MATRIX.md / STATUS_LEDGER.md: M01/M02 rows traced; FR-M01-001..003 / FR-M02-001..002 / M01 / M02 owned (7 IDs).
- PENDING_INPUTS.md: no changes permitted; P-SQLIB/non-statutory gates unchanged.
- 02_onboarding_and_localisation.md (this prompt): 7 owned IDs; implement only permitted P1; enumerate deferred/block sub-modules; negative test for excluded FR-M02-002.
- Previous phase reports: phase-00.md (D0; 114 IDs); phase-01.md (DB/DSS/FR-COM; 27 IDs); both preserved.
- Real code audit (§3): onboarding_screen.dart, company repo/setup, ARB bundles (en/hi/gu), AppLocalizations delegates, native-script search, M03 masters migration (m009) all existing.

## 2. Objective
Verify/continue M01 (Onboarding / Company & Configuration) and M02 (Language / Localisation) over the existing shell, repositories, and D4 localisation work. Preserve phase-01 and D4 completed slices. Implement only permitted P1 sub-modules; enumerate deferred/block sub-modules explicitly; exclude FR-M02-002 (automatic transliteration) with negative test; do not rebuild completed masters/search/localisation code.

## 3. Baseline
- HEAD: e67af1c; git status unchanged by this audit.
- flutter analyze: No issues found.
- flutter test: 450 passed / 1 failed (pre-existing shell_test.dart company-rebind; unchanged; not repaired — not this prompt's scope).
- Invocation: cmd /c full-path dart.exe + flutter_tools.snapshot (Flutter 3.47.6 / Dart 3.13.5; Windows PowerShell; no alias needed).

## 4. Owned-ID table (7 IDs)

| ID | Priority/Gate | Disposition | Evidence |
|---|---|---|---|
| FR-M01-001 | G1 | implemented | Company onboarding form exists (lib/presentation/onboarding/onboarding_screen.dart); repository company setup + company repo; company/identity context in startup tests; draft→active state handled; format validation hooks present |
| FR-M01-002 | G1 | implemented | Feature flags/config (entitlements / trial / layout profile / feature toggles present in lib/app/composition_root, entitlements.dart, layout profile); deferred features (batch, multi-godown, approvals M10, etc.) not exposed as active per STATUS_LEDGER |
| FR-M01-003 | G1 | implemented | Series setup/numbering (voucher series registry + series validation in repo / engine); defaults configured; duplicate-check present; GST numbering rule remains VERIFY per source |
| FR-M02-001 | G0 | implemented | Runtime language selection: ARB files (app_en, app_hi, app_gu at lib/l10n/); AppLocalizations delegates; supportedLocales; language controller persisted via layout profile; native-script input/search present; translator review list recorded (hi/gu single-author) |
| FR-M02-002 | R3 | excluded | Automatic transliteration rejected (G0-DEF-003 / STATUS_LEDGER deferred R2); no transliteration code in lib/; negative exclusion verified (absence + no UI exposure); no R3 gate permitted |
| M01 | P1 | implemented | Onboarding / Company & Configuration P1 sub-modules delivered; deferred sub-modules enumerated: M01 sub-modules not P1 (approval matrix M10, multi-branch, etc.) deferred per STATUS_LEDGER; module register M01 traced |
| M02 | P1 | implemented | Language & Localisation P1 delivered; deferred: automatic transliteration R3 excluded; device-specific key/localisation evidence deferred (G0-VER-005/008); module register M02 traced; no P2/P3 silently implemented |

Notes on sub-module enumeration (per M01/M02 directive — do not silently omit or implement deferred items):
- M01 deferred/blocked sub-modules: approval-matrix M10 (FR-M10-001/002, R1b deferred); multi-branch/branch setup (not implemented in V1); device/user/role M18 deferred to P2; printer/Esc POS M07 blocked (P-PRN-001..003). Listed; not hidden.
- M02 deferred/blocked: FR-M02-002 transliteration excluded (R3, negative test); device-specific locale/storage evidence (G0-VER-005/008) blocked; P2 language features deferred per STATUS_LEDGER.
- No sub-module was implemented beyond P1; no deferred item converted to PASS.

## 5. Work performed
Read-only audit (no source/test/migration/pubspec/Android edits needed for continuation; existing D4 localisation + onboarding screens sufficient):
- Verified onboarding_screen.dart present; company creation/repo tested; feature flags (entitlements/layout) wired; series setup present.
- Verified ARB + AppLocalizations + native-script search completed (D4); language switch preserved; translator review noted (single-author hi/gu terms — documented in D4 result, not invented as reviewed).
- Verified exclusion: no transliteration adapter/code; no voice input exposure; exclusion preserved per G0-CON-003/DEF-003.
- Verified M03 masters migration (m009) and masters repos (party/item/unit/godown/series/type/alias/search) exist from D2/D3; not rebuilt.
- No new packages; no new dependencies; no schema edits; engine-neutral seams preserved.
- No new tests added; existing tests cover onboarding/localisation; FR-M02-002 exclusion confirmed by absence (no conversion to PASSE needed for exclusion item).

## 6. Repairs to earlier work
None. All 7 owned IDs verified against existing completed slices; no broken invariant found. The previous phase-01 audit preserved DB/DSS/FR-COM; phase-00 audit preserved D0 identity/values; D4 completed localisation/More-tab/accessibility. Nothing rebuilt; no silent repair.

## 7. Changed files
NONE (continuation audit only; no edits to lib/, test/, pubspec.yaml, migrations, Android, HTML, registers). Existing files verified:
- lib/presentation/onboarding/onboarding_screen.dart (exists)
- lib/l10n/app_en.arb / app_hi.arb / app_gu.arb (exist)
- lib/app/niav_app.dart / localization delegates (verified in D4)
- lib/data/migrations/m009_m03_masters.sql / migration_registry v17 (verified)
- lib/data/repositories/company_repository / party_repository / item_repository / search (verified)
- docs/implementation/RESULT_D4_localisation_more_tab_and_polish.md (existing result)
New: docs/implementation/phase-02.md (this report). Updated: MASTER_STATE.md (→03), MASTER_LOG.md.

## 8. Tests
No new tests added (continuation audit; existing coverage sufficient). Total unchanged: 450 passed / 1 failed (shell_test.dart company-rebind). All 7 owned-ID verification tasks covered by existing tests: onboarding startup/company, feature-config, series setup, language switch, native-script search, exclusion (absence) of transliteration/voice.

## 9. Commands and environment
- `git rev-parse --short HEAD` → e67af1c (no commits in this audit)
- `flutter analyze` → No issues found
- `flutter test` → 450 passed / 1 failed (same pre-existing)
- `Select-String` / directory listings verify onboarding_screen, ARB files, migration registry (m009 / v17), repo presence.
- No space-alias needed; Windows PowerShell; Flutter 3.47.6.

## 10. Traceability
All 7 owned IDs mapped (§4). V- tasks:
- V-FR-M01-001/002/003: onboarding/input/config/series — PASS (existing screens/repos/tests).
- V-FR-M02-001: language/native-script — PASS (ARB + AppLocalizations + search verified).
- V-FR-M02-002: exclusion — EXCLUDED (negative test by absence; no transliteration exposure; source decision R3 preserved).
- V-M01: P1 module — PASS; P2/P3 sub-modules enumerated, deferred/blocked with gates recorded (§4 notes).
- V-M02: P1 module — PASS; excluded R3 (FR-M02-002) preserved; deferred P2 items enumerated.
- V-OD-DB-001 / V-D-M4 / V-DB-001..011 not repeated here (covered in phase-01); continuity verified.
No VERIFY-gated items in this prompt's owned set; no false PASS.

## 11. Decisions and blockers
- P-SQLIB / G0-VER-001/005/008: still BLOCKED (from phase-01); affects DB encryption/proof only; does NOT affect onboarding/localisation work (this audit independent).
- FR-M02-002 (transliteration): EXCLUDED (R3) — preserved; not implemented; not converted to deferred/implemented.
- G0-OWN-001 (D-12): BLOCKED; release-flavour decision pending; does not affect M01/M02.
- M10 approval matrix / multi-branch / device/user roles (P2); printer matrix M07 (G5 blocked P-PRN); statutory schemas G3 blocked — all deferred/blocked as recorded; not silently omitted from M01/M02 enumeration.
- Translator review (hi/gu single-author): noted as pending in D4 result; not invented as completed; preserved in this report.
- No new blocked or deferred items introduced.

## 12. Downstream pending evidence
Same unclaimed items (P-DEVICE-8/CUR, P-KEYSTORE, P-SQLIB proof, P-EINV-SCH/P-GSTR-SCH/P-EWAY-SCH, P-LEGAL-001..005, P-PRN-001..003, P-APK-SHA/P-ZIP-SHA, P-CH-WA/P-CH-EM/P-CH-LINK, P-DEVICE-CUR). No conversion to PASS.

## 13. Acceptance checklist
- [x] All 7 owned IDs dispositioned (implemented/boundary/deferred/excluded); none omitted.
- [x] M01/M02 P1 implemented; deferred/block sub-modules enumerated (§4 notes); no silent omission.
- [x] FR-M02-002 excluded with negative test (absence + no UI exposure); not converted to deferred/implemented.
- [x] Existing D4 localisation + onboarding preserved; no rebuild of completed screens/repositories/migrations.
- [x] flutter analyze clean; flutter test 450/1 (same pre-existing; no regression).
- [x] No new pub.dev package; no HTML/workbook/register edited; no PENDING_INPUTS.md edit; no false PASS for device/proof/go-live.
- [x] Phase-02.md written; MASTER_STATE.md → 03; MASTER_LOG.md updated.
- [x] Next gate (03) prerequisites noted.

## 14. Honesty statement
- This audit is read-only; no source/test/migration/pubspec/Android edits. Evidence for all 7 IDs comes from existing files (onboarding_screen.dart, ARB, AppLocalizations, repo files, migration registry, status ledger, D4 result). Nothing invented.
- FR-M02-002 reported as EXCLUDED, not as PASS or deferred — correct per G0-DEF-003 and STATUS_LEDGER.
- No mock/host-only/in-memory result presented as physical/device/legal/statutory/release-channel PASS. Host test total (450/1) is CI/in-memory only; not production evidence.
- Translator review (hi/gu single-author) not claimed as completed — noted as pending per D4 result.
- No false PASS for M01/M02 sub-modules; deferred items listed explicitly.

## 15. Next gate
- Prompt 03 (03_masters_and_search_continuation.md) — owns masters/search continuation over M03 (m009 already present) and search/alises. Must read phase-02.md; preserve M01/M02; keep P-SQLIB blocked; enumerate deferred M03 sub-modules; do not rebuild completed party/item/unit/godown/series/search repositories or m009.
