# G0 acceptance review — superseded conditional record (v0.8 Phase 8)

> Superseded for scope interpretation by `docs/g0/G0_UNCONDITIONAL_SIGNOFF.md`
> and `NiAv_G0_Prompts_Pack_v0.9.md`. This file remains as the historical
> record of the earlier over-scoped conditional review.

Date (UTC): 2026-10-03
Prompt authority: `NiAv_G0_Prompts_Pack_v0.8.md` Phase 8
Closeout baseline: **CONDITIONAL** per `niav_g0_closeout_report_20261001.json` (8 verification records, 7 schema changes). This phase is read-only for requirements documents — no HTML, workbook, or register was edited.
Full-suite: `flutter test` → **+94 pass, 0 fail**; `flutter analyze` → **clean**. No unconditional sign-off is issued (PENDING-INPUT items remain — see below). A conditional result is a normal outcome, not an error.

## Decision

**G0 remains CONDITIONAL.** `docs/g0/G0_UNCONDITIONAL_SIGNOFF.md` is NOT issued. This file (`G0_CONDITIONAL_OR_BLOCKED.md`) is the Phase 8 record. Unconditional sign-off requires: every PENDING-INPUT closed via the Resume prompt, Phases 7–8 re-run, zero PENDING-INPUT/FAIL, and zero document findings.

## 1. Document re-check (G0-CON-001…005 + voice; read-only greps 2026-10-03)

Method: `Select-String` over on-disk HTML for active corrected statements and G0 sections (`niav-g0-body-corrections`, `niav-g0-correction-v2`, `niav-g0-nav-voice-v3`, `niav-g0-final-reconciliation`, `niav-g0-verification-evidence`, workbook-reconciliation). Historical change logs and backup directories are history by design; the reconciliation/correction sections plus `niav_final_reconciliation_report_20261001.json` are authoritative where they conflict with older body text. No HTML was edited to fix anything.

| Family | Listed locations checked | Active corrected statement observed | Verdict |
|---|---|---|---|
| G0-CON-001 TDS/TCS later-release; PF/ESI/payroll out of scope | ZCP, MPL (+ REG/FGA/FRD §10 per reconciliation) | ZCP/MPL active sections carry "TDS/TCS is later-release; PF/ESI and payroll are out of scope"; body-corrections sections present in REG, FGA, FRD; FG-007/008 rows reconciled as deferred/out-of-scope | PASS at checked active locations; historical superseded rows retained by design, not counted as active contradiction |
| G0-CON-002 Tally/Busy native = R3 feasibility only; V1 = Excel templates | FR-M17-003, FG-006, REG M17.11, ZCP, MPL, FGA | "FG-006 Tally/Busy native formats — R3 feasibility only; no V1 import" + Excel-template boundary observed in FRD/FGA reconciliation rows; no native adapter in `lib/` | PASS (same historical-row note) |
| G0-CON-003 rollback = uninstall current → install previous → restore external backup; no in-place downgrade | RSP | RSP row: "Uninstall the current APK, install the previous APK, then restore the external backup; in-place downgrade is not supported"; no DOWN migrations shipped; downgrade refusal tested | PASS |
| G0-CON-004 field merge, host-arrival-wins on same-field clash, loser logged | ZCP, SYNC | SYNC §6 conflict-rules + reconciliation rows carry the rule; `sync_conflict` shape per OD-DB-006 in migration v6; code implements fields only (full policy S1 outside pack) | PASS (fields; policy implementation remains S1 by scope) |
| G0-CON-005 Home, Billing, Parties & Items, Reports, More; no contradicting variant | MPL, UIUX §3, UX §2 | Five-item model observed in MPL/UIUX/UX active sections (`Home, Billing, Parties` hits); nav-voice corrections present; no active variant contradicts at checked locations | PASS (same historical-row note) |
| Voice input rejected/excluded from V1 | REG M02.5, MPL roadmap, FR-M02-002, FRD OD-002, FRD input-methods Voice row, UIUX/UX OD-UI-003, all reconciliation rows | "Voice input is rejected for V1" in final-cleanup/nav-voice sections of REG/MPL/FRD (+ ZCP/RSP/SYNC closure ledgers); no conditional/deferred voice capability in active text; no voice code/permission/dep in `lib/` or pubspec | PASS (excluded) |

Document findings: **none** at checked active locations. Scope limit (stated, not hidden): this was a targeted active-text re-check, not an exhaustive per-paragraph audit of every historical row — historical rows are retained as history by design and were the subject of the prior independent audit + `correction-v2`/`final-cleanup-v5` passes. Any future full-text audit that finds a missed active contradiction should append it here as a finding; none was observed in this run.

## 2. Seven acceptance checks

| # | Check | Verdict |
|---|---|---|
| 1 | All owner decisions recorded | PASS — `niav_final_reconciliation_report_20261001.json` (OWN/DEF/VER/CON/SCH rows) + Exception Register v0.1 + closeout CONDITIONAL; code respects decided boundaries (exclusions grep 2026-10-03) |
| 2 | All deferred items have a gate (date where set) and remain out of current scope | PASS — G0-DEF-001 R3, G0-DEF-002 Later release, G0-DEF-003 R2 (no dates set in source; "date where set" satisfied as none set); G0-DEF-004 absent → field capture is PENDING-INPUT, not DEFERRED |
| 3 | All 8 verification records contain acceptable evidence, incl. separate legal-review result for O-14/R-13 | PENDING-INPUT — host/draft/pointer evidence exists for all 8 (`VERIFICATION_EXECUTION.md`), but execution/device/physical/legal-review closures remain open (see §3); legal result is a DRAFT, explicitly not a review |
| 4 | All 7 schema changes migrated and tested | PASS — v1→v8 clean-install + upgrade + repeat-safe + CHECK/FK assertions (17 migration tests) + fixture libs |
| 5 | RTM + regression contain no unresolved critical/high defect | PASS — +94 pass, 0 fail; `RTM_EXECUTION_RESULT.md` + `REGRESSION_RESULT.md`; no high-severity regression open |
| 6 | Named contradiction families reconciled in every listed document | PASS at checked active locations (see §1 table + scope note) |
| 7 | Release, rollback, and support evidence present | PARTIAL — rollback procedure documented + downgrade-refusal tested (PASS); release checksum mechanism + 2 local runs recorded (PASS as mechanism); APK/ZIP artifact hashes + channel receipts PENDING-INPUT |

## 3. Every PENDING-INPUT item (with exact closing step)

See `docs/g0/PENDING_INPUTS.md` §A (authoritative list). Summary: P-SQLIB (G0), P-DEVICE-8/CUR + P-KEYSTORE (G0/G5), P-GST-SRC (G0), P-DISC-PREC (G1), P-FIELD-LIST + P-EINV/P-GSTR/P-EWAY-SCH (G3/R1a), P-LEGAL-001…005 (G5), P-PRN-001…003 (G5), P-APK/ZIP-SHA + P-CH-WA/EM/LINK (G5). Each row names the scaffolding in the repo (test code/procedure + evidence template + exact command/step). FAIL items: none.

## 4. Every DEFERRED item with its gate

G0-DEF-001 → R3; G0-DEF-002 → Later release; G0-DEF-003 → R2 (`PENDING_INPUTS.md` §B). Not counted as passed. G0-DEF-004 does not exist — not claimed.

## 5. FAIL items and document findings

- FAIL: none (`flutter test` +94/0; `flutter analyze` clean).
- Document findings: none at checked active locations (§1; scope note applies).

## 6. What closes G0 to unconditional

1. Supply each §3 input (Resume prompt per `PENDING_INPUTS.md` §C; do not change PASS rows).
2. Re-run Phases 7 and 8.
3. Phase 8 issues `G0_UNCONDITIONAL_SIGNOFF.md` only when: zero PENDING-INPUT, zero FAIL, zero document findings — with decision/date, build/schema versions, evidence index, test summary, deferred future-release items, and owner approver names/roles.

## 7. Phase statuses (v0.8 vocabulary)

Phase 0 PARTIAL (scaffold + inventory PASS; SQLCipher/device/printer/schema/legal inputs PENDING-INPUT) · Phase 1 PARTIAL→COMPLETE on host (v1–v8 migrations + 17 tests PASS; prod encryption wiring awaits P-SQLIB) · Phase 2 PARTIAL (29 fixture tests PASS; rule-source + conventions PENDING-INPUT) · Phase 3 PARTIAL (23 host tests PASS; device runs PENDING-INPUT with procedure + template ready) · Phase 4 PARTIAL (4 boundary tests PASS; field list + schemas PENDING-INPUT, no columns) · Phase 5 PARTIAL (draft map PASS; reviewer/date/retention/interpretation PENDING-INPUT) · Phase 6 PARTIAL (20 print/release tests + script runs PASS; physical/channel rows PENDING-INPUT) · Phase 7 PARTIAL (RTM/regression green; PENDING-INPUTs consolidated) · Phase 8 CONDITIONAL (this file).

---

## G0 PHASE RESULT

```text
G0 PHASE RESULT
Phase: 8 — Final G0 sign-off
Phase status: FAIL (blocked for unconditional; CONDITIONAL record issued — not an error)
Commands run:
- Select-String re-checks over *.html (CON-001…005 + voice + rollback + sync + nav), E:\NiavERP v2 OpenAI (read-only)
- flutter test → +94 pass, 0 fail; flutter analyze → clean (reused from Phase 7, not re-claimed as new)
- powershell verify_checksums.ps1 ×2 → PASS (reused from Phase 6)
Changed files:
- docs/g0/G0_CONDITIONAL_OR_BLOCKED.md (new; this file)
- (Phases 5–7 files listed in their own G0 PHASE RESULT blocks; no HTML/workbook/register edited)
Tests:
- Passed: 94 (full suite, Phase 7)
- Failed: 0
- Pending input: all rows in docs/g0/PENDING_INPUTS.md §A
Evidence:
- docs/g0/G0_CONDITIONAL_OR_BLOCKED.md
- docs/g0/PENDING_INPUTS.md
- docs/g0/RTM_EXECUTION_RESULT.md
- docs/g0/REGRESSION_RESULT.md
- docs/g0/VERIFICATION_EXECUTION.md
- docs/g0/TEST_SUMMARY.json
Traceability IDs:
- G0-SCH-001…007; G0-CON-001…005; G0-VER-001…008; G0-OWN-001/002; G0-DEF-001/002/003; (G0-DEF-004 absent)
Item statuses:
- G0-SIGNOFF: PENDING-INPUT (CONDITIONAL) — unconditional sign-off impossible while §3 rows are PENDING-INPUT
- G0-DOCS: PASS at checked active locations (historical rows retained by design; scope note in §1)
- G0-FAIL: none (0 failed tests, 0 violated invariants)
Pending inputs and owner questions:
- See docs/g0/PENDING_INPUTS.md §A (smallest question per row; e.g. SQLCipher lib/version/licence? Android 8 device? IRN field list or G0-DEF-004? printer matrix OD-FD-006? legal reviewer + date? release build artifacts?)
Next gate:
- Resume prompt per input → re-run Phases 7–8 → G0_UNCONDITIONAL_SIGNOFF.md only when zero PENDING-INPUT/FAIL/findings
```
