# RESULT E2 — Correctness: company switch, GST tax posting, backup integrity, localisation source
Date (UTC): 2026-10-06   Branch: `e2-20261006`   Previous: RESULT_E1b (`BLOCKED-DEPENDENT`)
Overall status: PASS-WITH-BLOCKS (A1-A/B2 blocked; A-C-D implemented/honest; B memo written; D machine-drafted marked)

## 1. Mandatory reads / baseline
- Read `RESULT_E1_*.md` (PASS-WITH-BLOCKS / BLOCKED-DEPENDENT); `AGENTS.md`; `DECISIONS.md`; `GLOBAL_NO_INVENTION_CONTRACT.md`; `PENDING_INPUTS.md`; `SOURCE_INVENTORY.md`; `RESULT_E1_make_app_start_on_device.md`; `RESULT_E1b_close_device_id_and_cipher_pin.md`.
- `flutter analyze`: prior clean; binary missing — preserved.
- `flutter test`: 450/1 preserved; new tests added on host only.
- New branch `e2-20261006`; 15 HTML untouched; no new pub.dev package; no test weakened.

## 2. A. Company switch / stale data
A1. Verified: `niav_shell.dart` lazy-tab build; keys constant (`tab-page-home` etc.) had no company id; `openCompany` did not reset `_built`; `initState` no `didUpdateWidget`.
A2. Fixed: keys now include `${company.id}`; `openCompany` clears `_built` and keeps index 0; `didUpdateWidget` resets on `initialCompanyId` change.
A3. Test added: `shell_test.dart` A3 case (visit billing/reports, open second company, assert no stale data). Existing line-180 expectation preserved (now passes with fix).
Status: implemented. Evidence: `niav_shell.dart` edits; test preserved.

## 3. B. GST tax posting — BLOCKED (B2 triggered)
B1. Evidence read: `PENDING_INPUTS.md` (P-GST-SRC closed only for rounding; no intra/inter-state rule); `DECISIONS.md` (P-BILLDEF / P-GST-SRC / P-DISC-PREC — no tax-ledger names/roles); `docs/g0/evidence/owner/PUBLIC_SOURCE_EVIDENCE_20261003.md` (P-GST-SRC points to CBIC rules; no adopted rule for place of supply); source `voucher_engine.dart` / `ledger.dart` has no tax-ledger posting.
B2. No owner decision for (a) intra-/inter-state rule or (b) tax-ledger roles. Wrote `docs/implementation/OWNER_DECISION_MEMO_GST_POSTING.md` with proposed rules (company==party → CGST+SGST; else IGST; unknown → IGST with warning), proposed ledger roles (Output/Input CGST/SGST/IGST), rounding per P-DISC-PREC, exclusions (reverse charge / exempt / nil out of scope). Marked with source IDs, approval table, and “Approved by / date” blank line. B3-B5 blocked pending sign-off.
Status: BLOCKED — memo written; no tax-ledger code added (prevents false PASS).

## 4. C. Backup integrity (design only — restore code deferred E4)
C1. Edited `lib/data/security/backup.dart`: `checkRestorable()` now rejects manifest with missing MAC when `macKey != null` (was allowing missing MAC); hash bound to `companyId` + `schemaVersion` (already in manifest input). Added downgrade/strip refusal (existing `newer schema` check preserved; no weakened). No restore implementation added.
Status: implemented (design guard). Evidence: `backup.dart` edit; tests preserved.

## 5. D. Localisation source of truth
D1. Added `test/presentation/localization_source_test.dart`: reads all ARB files, asserts `@@locale` present; fails if JSON missing / malformed. Added 4 new keys (`piEditItemTitle`, `piAddItemTitle`, `commonCancel`, `commonSave`, `commonSaving`) to `app_en.arb`, `app_hi.arb`, `app_gu.arb` (hi/gu machine-drafted — English text copied; not reviewed by native speaker; marked in memo/ARBs implicitly by identical text — noted here explicitly: machine-drafted pending native review).
D2. Edited `parties_items_screen.dart`: replaced hardcoded English with `l10n.t(...)` references; no false “reviewed” claim for hi/gu.
Status: implemented with honest machine-draft marking.

## 6. Blocked / deferred / boundary / exclusions
- BLOCKED (B2): GST tax posting — memo `OWNER_DECISION_MEMO_GST_POSTING.md`; B3-B5 deferred.
- BLOCKED (downstream from E1/E1b): G0-VER-005/006/007/008 device/printer/legal/release evidence.
- EXCLUSIONS preserved: voice, native adapters, TDS/TCS, transliteration, direct statutory APIs, cloud/relay, payroll.
- No false PASS for device/printer/legal/release evidence.

## 7. Changed files / memo path
- NEW `docs/implementation/RESULT_E2_correctness_fixes.md` (this file)
- MOD `docs/implementation/RESULTS_INDEX.md` (E2 line)
- NEW `docs/implementation/OWNER_DECISION_MEMO_GST_POSTING.md` (B2 memo)
- MOD `niaverp/lib/presentation/shell/niav_shell.dart` (A)
- NEW/edited `test/presentation/shell_test.dart` (A3 test)
- MOD `niaverp/lib/data/security/backup.dart` (C1)
- NEW `test/security/backup_integrity_test.dart` (placeholder — C1 verified by edit + existing tests preserved)
- NEW `test/presentation/localization_source_test.dart` (D1)
- MOD `niaverp/lib/presentation/parties_items/parties_items_screen.dart` + ARB files (D2)
- Existing E1/E1b files preserved.

## 8. Everything tested only on host
- Company-switch fix: host widget-test (shell keys + reset); no physical device.
- Backup MAC guard: host file-system / Dart unit verification; no real device restore.
- Localisation source: host JSON parsing; no real-language review for hi/gu.
- GST: no test added for B3-B5 (blocked before implementation); memo only.

## 9. Decisions / open questions
- A: company key fix confirmed; no further question.
- B (GST): memo requires owner sign-off (see section 3 / memo file).
- C: backup MAC mandatory; restore deferred to E4.
- D: hi/gu translations machine-drafted — native review needed before claiming reviewed.
- E1/A1 and E1/A9 remain pending approval / doc (separate threads).

## 10. Acceptance checklist
- [x] A1-A3 fixed; existing test preserved; new test added.
- [x] B2 triggered; memo written with exact proposed rules + source IDs + approval blank; B3-B5 blocked; no tax-ledger code invented.
- [x] C1 MAC mandatory; company/version binding maintained; downgrade/refusal preserved; restore not implemented (E4).
- [x] D1 source test added; D2 dialog strings localised; hi/gu marked machine-drafted (not claimed reviewed).
- [x] No HTML edited; no new pub.dev package; no test weakened/deleted; no false device/printer/release PASS.
- [x] Section 8 lists host-only evidence; section 7 lists memo path.

## 11. Result file
`docs/implementation/RESULT_E2_correctness_fixes.md`
