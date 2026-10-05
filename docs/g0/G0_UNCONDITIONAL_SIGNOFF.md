# G0 baseline acceptance only — downstream gates remain open (v0.9 Phase 8)

Date (UTC): 2026-10-03
Prompt authority: `NiAv_G0_Prompts_Pack_v0.9.md` Phase 8
Prior baseline: CONDITIONAL per `niav_g0_closeout_report_20261001.json` + `docs/g0/G0_CONDITIONAL_OR_BLOCKED.md` (v0.8). This record supersedes that CONDITIONAL **only for G0 baseline scope** under the v0.9 decision rule. It is NOT product, security, legal, hardware, or release sign-off.
Status vocabulary (v0.9): items PASS / FAIL / PENDING-INPUT / DEFERRED; phases COMPLETE / PARTIAL / FAIL. Phase COMPLETE = every G0-scope item PASS or DEFERRED; downstream-gate PENDING-INPUTs may remain without blocking G0 baseline acceptance.
Source registers, HTML, workbooks untouched (read-only). No HTML, workbook, or register edited in this phase.

## Decision

**G0 baseline ACCEPTED.** All G0-scoped checks pass, zero G0-scoped FAIL, zero document findings at checked active locations (scope note in §1). All remaining PENDING-INPUTs are downstream-gate items tracked in `docs/g0/PENDING_INPUTS.md` — they are NOT misrepresented as G0 evidence. Downstream implementation/evidence (device, SQLCipher production compat, printers, legal review, release artifacts/channels, G3/R1a schemas) still requires its own gate closure via the Resume prompt + affected-phase re-run.

## 1. Document re-check (G0-CON-001…005 + voice; read-only, 2026-10-03)

Method: `Select-String` over on-disk `*.html` for active corrected statements (same locations as v0.8 Phase 8). Historical change logs and backup directories are history by design; reconciliation/correction sections plus `niav_final_reconciliation_report_20261001.json` are authoritative where they conflict with older body text. No HTML edited.

| Family | Active corrected statement observed | Count (hits) | Verdict |
|---|---|---|---|
| G0-CON-001 TDS/TCS later-release; PF/ESI/payroll out of scope | TDS/TCS later-release rows present (7 hits for exact phrase); PF/ESI/payroll out-of-scope rows in REG/MPL/ZCP reconciliation sections | 7 | PASS at checked active locations |
| G0-CON-002 Tally/Busy native = R3 feasibility only; V1 = Excel templates | R3-feasibility / no-V1-import boundary rows | 15 | PASS |
| G0-CON-003 rollback = uninstall current → install previous → restore external backup; no in-place downgrade | Exact rollback sentence + no-in-place-downgrade rows (RSP) | 3 | PASS |
| G0-CON-004 field merge, host-arrival-wins, loser logged | host-arrival-wins + loser-logged rows (SYNC §6 + ZCP) | 11 | PASS (fields; full policy S1 outside pack) |
| G0-CON-005 Home, Billing, Parties & Items, Reports, More | Five-item model rows (MPL/UIUX/UX) | 16 | PASS |
| Voice input rejected/excluded from V1 | "Voice input is rejected for V1" in final-cleanup/nav-voice sections | 9 | PASS (excluded) |

Document findings: **none** at checked active locations. Scope limit (stated, not hidden): targeted active-text re-check, not exhaustive per-paragraph audit of every historical row — historical rows retained as history by design per prior independent audit + correction-v2/final-cleanup-v5 passes. Any future full-text audit finding should be appended as a finding; none observed in this run.

Code-boundary attestation (2026-10-03, `niaverp/lib`, `pubspec.yaml`):
- No voice code/permission/dep (`speech_to_text|VoiceInput`: 0 hits); no `http/dio`, no endpoint, no credentials (0 hits); no TDS/TCS/payroll/transliteration code (0 hits); no IRN/ack/e-way columns in `migrations/*.sql` (0 hits); no DOWN migrations shipped (only `godown_*` false positives on substring `down`); downgrade refusal via `backup.dart:checkRestorable` (refuses newer-schema, tested in `backup_test.dart`).

## 2. Seven acceptance checks (v0.9 Phase 8)

| # | Check | Verdict |
|---|---|---|
| 1 | All owner decisions recorded | PASS — `niav_final_reconciliation_report_20261001.json` (OWN/DEF/VER/CON/SCH rows) + Exception Register v0.1 + closeout CONDITIONAL baseline |
| 2 | All deferred items have a gate (date where set) and remain out of current acceptance scope | PASS — G0-DEF-001 R3, G0-DEF-002 Later release, G0-DEF-003 R2 (no dates set in source; "date where set" satisfied as none set); G0-DEF-004 absent → field capture stays PENDING-INPUT, not DEFERRED |
| 3 | G0-scoped evidence acceptable: seven schema changes migrated/tested or explicitly implementation-pending, host tests reproducible, no G0 design contradiction | PASS — v1→v8 migrations + 17 migration tests; 29 accounting fixture tests; full host suite +94/0 reproducible this run; contradictions §1 PASS |
| 4 | All seven schema changes migrated and tested where implementation exists | PASS — `m001`–`m008` + `migration_registry.dart`/`migration_runner.dart`/`validators.dart`; clean-install + upgrade + repeat-safe + CHECK/FK assertions |
| 5 | RTM + host regression contain no unresolved critical/high defect | PASS — `flutter test` +94 pass / 0 fail; `flutter analyze` clean; `RTM_EXECUTION_RESULT.md` + `REGRESSION_RESULT.md` carry forward with no new defect |
| 6 | Named contradiction families reconciled in every listed document | PASS at checked active locations (§1 + scope note) |
| 7 | Downstream-gate evidence listed separately, not misrepresented as G0 evidence | PASS — see §5 downstream ledger (Android/Keystore, prod SQLCipher compat, physical printers, legal review, release APK/ZIP + channels, G3/R1a schemas/fixtures). Host tests stated as host-only in evidence files. |

G0 FAIL items: none. G0 document findings: none (§1).

## 3. Build / schema / test versions

- App: `com.niaverp.niaverp` / `niaverp` 1.0.0+1; minSdk 26 / Android 8 pinned in `niaverp/android/app/build.gradle.kts`
- Schema: v1→v8 (`m001_base` … `m008_sch007_discount`); `schema_migrations` ledger; rollback = uninstall → install previous → restore external backup (no in-place downgrade)
- Host suite (reproduced this phase, workdir `E:\NiavERP v2 OpenAI\niaverp`): `flutter test` → **+94: All tests passed!** (breakdown migration 17, accounting fixtures 29, security 23, statutory boundary 4, print 16, release 4, smoke 1); `flutter analyze` → **No issues found!**
- Env: Windows 10 Pro 22H2; Flutter 3.47.5 / Dart 3.13.4; deps `flutter, cupertino_icons, crypto` + dev `flutter_test, flutter_lints, sqlite3`; disposable in-memory SQLite only; no production data touched
- Prior evidence carried forward (not re-claimed as new): `docs/g0/evidence/migrations/migration-test-20261003.log.md`, `evidence/fixtures/INDEX.md` + `F-*.md`, `evidence/android/security-test-20261003.log.md` + `DEVICE_MATRIX.md` + `DEVICE_TEST_PROCEDURE.md`, `evidence/adapters/G0_BOUNDARY.md`, `evidence/legal/LEGAL_CONTROL_MAP_DRAFT.md` (DRAFT), `evidence/printers/print-test-20261003.log.md` + `PRINTER_TEST_SHEET.md`, `evidence/release/RELEASE_DELIVERY.md`

## 4. Evidence index (this acceptance)

- `docs/g0/G0_UNCONDITIONAL_SIGNOFF.md` (this file — G0 baseline acceptance record per v0.9)
- `docs/g0/G0_CONDITIONAL_OR_BLOCKED.md` (v0.8 CONDITIONAL record; retained as history, superseded only for G0 scope)
- `docs/g0/PENDING_INPUTS.md` (downstream-gate ledger — authoritative pending list, unchanged)
- `docs/g0/PROJECT_BASELINE.md`, `docs/g0/MIGRATION_DESIGN.md`, `docs/g0/VERIFICATION_EXECUTION.md`, `docs/g0/RTM_EXECUTION_RESULT.md`, `docs/g0/REGRESSION_RESULT.md`, `docs/g0/TEST_SUMMARY.json`
- Closeout/reconciliation sources (read-only): `niav_g0_closeout_report_20261001.json`, `niav_final_reconciliation_report_20261001.json`, `outputs/…/NiAv_G0_Exception_Register_v0.1.xlsx`, `outputs/…/NiAv_G0_Verification_Evidence_Register_v0.1.xlsx`

## 5. Downstream-gate ledger (PENDING-INPUT; do NOT block G0 baseline per v0.9)

Authoritative detail per row (missing input + owner question + closing command): `docs/g0/PENDING_INPUTS.md` §A. Summary:

- Prod encryption compat: P-SQLIB (library/version/licence + Android 8 proof; approach recorded, no dependency added) — G0/G1/G3 downstream wiring
- Devices/Keystore/share/restore: P-DEVICE-8, P-DEVICE-CUR, P-KEYSTORE (D-KEY-01…D-BKP-04 procedure + template ready; host 7+5+5 tests prove host only)
- Accounting conventions (PROPOSED, host fixtures pass, statutory truth pending): P-GST-SRC (official rounding source for G0-VER-002; F-GST-001…008 PROPOSED from D-M4), P-DISC-PREC (amount-wins, tax-on-net, CGST-remainder; G1)
- Statutory G3/R1a (boundary holds: no columns, no API, no credentials; 4 boundary tests pass): P-FIELD-LIST (IRN/ack/e-way field list or G0-DEF-004), P-EINV-SCH, P-GSTR-SCH, P-EWAY-SCH (pinned versions + samples; observed e-way v1.03 UNCONFIRMED)
- Legal G5 (DRAFT map only, not a review): P-LEGAL-001…005 (reviewer, date, retention/deletion, Act version/readings, R-13 scope)
- Printers G5 (16 golden tests pass host-only; sheet ready): P-PRN-001 (58mm), P-PRN-002 (80mm), P-PRN-003 (PDF A4/A5); matrix OD-FD-006 unfrozen
- Release/channels G5 (checksum mechanism + 2 local runs pass; artifacts/channels pending): P-APK-SHA, P-ZIP-SHA, P-CH-WA, P-CH-EM, P-CH-LINK

Each closes via its Resume prompt + scaffolding in `PENDING_INPUTS.md` §C (supply input → re-verify listed IDs only → update evidence + verification register + PENDING_INPUTS → re-run affected downstream phase; do not change G0 PASS rows).

## 6. Deferred (not counted as passed)

G0-DEF-001 → R3 (Tally/Busy native adapters; V1 = Excel templates); G0-DEF-002 → Later release (TDS/TCS; PF/ESI/payroll out of scope); G0-DEF-003 → R2 (auto-transliteration; V1 = native-script + Latin search + aliases). G0-DEF-004 does not exist.

Excluded (boundary holds, attested §1): voice input (rejected); direct e-invoice/e-way APIs, server/cloud deps; in-place downgrade (refusal tested).

## 7. Approvers

No owner approver names/roles supplied in this run — recorded as pending owner input, not invented. Unconditional product/security/legal/hardware/release sign-off is explicitly NOT issued by this file.

---

## G0 PHASE RESULT

```text
G0 PHASE RESULT
Phase: 8 — G0 baseline acceptance (v0.9)
Phase status: COMPLETE (G0 baseline acceptance only — downstream gates remain open)
Commands run:
- & "<flutter-sdk>\bin\flutter.bat" test (in E:\NiavERP v2 OpenAI\niaverp) → +94 pass, 0 fail
- & "<flutter-sdk>\bin\flutter.bat" analyze (in E:\NiavERP v2 OpenAI\niaverp) → No issues found!
- Select-String re-checks over *.html (CON-001…005 + voice + rollback + sync + nav), E:\NiavERP v2 OpenAI (read-only)
- Select-String boundary checks over niaverp/lib + pubspec (voice/http/dio/TDS/IRN/DOWN) (read-only)
Changed files:
- docs/g0/G0_UNCONDITIONAL_SIGNOFF.md (new; this file — G0 baseline acceptance record per v0.9 decision rule)
- (No HTML/workbook/register edited; PENDING_INPUTS.md unchanged as downstream ledger)
Tests:
- Passed: 94 (full host suite, reproduced this phase)
- Failed: 0
- Pending input: 23 downstream-gate rows in docs/g0/PENDING_INPUTS.md §A (do not block G0 baseline per v0.9)
Evidence:
- docs/g0/G0_UNCONDITIONAL_SIGNOFF.md
- docs/g0/PENDING_INPUTS.md (downstream ledger)
- docs/g0/G0_CONDITIONAL_OR_BLOCKED.md (v0.8 history)
- docs/g0/RTM_EXECUTION_RESULT.md + REGRESSION_RESULT.md + VERIFICATION_EXECUTION.md + TEST_SUMMARY.json
Traceability IDs:
- G0-SCH-001…007; G0-CON-001…005; G0-VER-001…008; G0-OWN-001/002; G0-DEF-001/002/003; (G0-DEF-004 absent)
Item statuses:
- G0-BASELINE: PASS — G0-scoped checks 1–6 pass, zero G0 FAIL, zero document findings at checked locations
- G0-DOCS: PASS at checked active locations (historical rows retained by design; scope note §1)
- Downstream PENDING-INPUT (23): PENDING-INPUT — tracked separately, scaffolding ready, not misrepresented as G0 evidence
- DEFERRED: G0-DEF-001:R3, G0-DEF-002:Later-release, G0-DEF-003:R2 — out of G0 acceptance scope
- G0-FAIL: none
Pending inputs and owner questions:
- See docs/g0/PENDING_INPUTS.md §A (smallest question per row; e.g. SQLCipher lib/version/licence? Android 8 device? IRN field list or G0-DEF-004? printer matrix OD-FD-006? legal reviewer + date? release build artifacts?)
Next gate:
- Resume prompt per downstream input → re-run affected downstream phase → Phases 7–8 refresh ledger. This file must never be read as product, security, legal, hardware, or release sign-off.
```
