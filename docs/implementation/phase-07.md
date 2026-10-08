> NOTE (2026-10-08): dispositions unverified before B0 — see docs/implementation/BACKEND_CAPABILITY_REGISTER.md.
# Implementation Phase 07 — Import, GST, BRS and statutory boundary (FG-001..008/015, FR-M16-001..004, FR-M17-001..005, G0-SCH-004, M16/M17, OD-DB-003, OD-FD-002/003)
Date (UTC): 2026-10-06   Prompt: 07_import_gst_brs_and_statutory_boundary.md
Outcome: COMPLETE-WITH-BLOCKS   Previous: phase-06.md

## 1. Read / Objective
Audit statutory/import/report boundary over existing migrations (m005 G0-SCH-004), repositories, D2/D3/D4 results, STATUS_LEDGER exclusions/deferred. Implement only permitted P1; enumerate deferred/block explicitly; preserve exclusions (FG-006 native import deferred R3, FG-007 TDS/TCS deferred, FG-008 transliteration excluded). No new statutory APIs or cloud connections.

## 2. Baseline
HEAD e67af1c; analyze clean; test 450/1 unchanged.

## 3. Owned-ID table (25 IDs — summary)
- FG-001 (integration model, partial) — boundary (no single acceptance rule).
- FG-002 / FG-003 (statutory schema: GST/e-invoice/e-way) — BLOCKED (P-SQLIB / G0-VER-003 / P-EINV-SCH / P-GSTR-SCH / P-EWAY-SCH); boundary only (local JSON/file prep allowed; direct API excluded).
- FG-004 (government file export engine) — boundary (engine partial; no full schema-versioning/reconciliation spec).
- FG-005 (bank statement/BRS) — P1 implemented (bank/account repo, outstanding reports); deferred P2 (statement import format missing) listed.
- FG-006 (Tally/Busy native import) — deferred R3 (Excel-template boundary only; no native adapter); negative exclusion test preserved.
- FG-007 (TDS/TCS) — deferred P2 / Verify; excluded from V1.
- FG-008 (automatic transliteration) — excluded; negative test preserved (G0-DEF-003).
- FG-015 (attachment share) — boundary (share policy present; device/proof pending G0-VER-008).
- FR-M16-001 — implemented (GST reports as projection queries; schema verification pending).
- FR-M16-002 — deferred / verify (BRS format verify pending).
- FR-M16-003 / FR-M16-004 — blocked (statutory fields frozen; P-GSTR-SCH pending; G0-VER-003).
- FR-M17-001..005 — boundary / deferred P2 (import pipeline: Excel-template only; validation/preview/commit not fully specified; pipeline deferred); no import_export code in lib/ beyond boundary.
- G0-SCH-004 — implemented (m005_sch004_tax_layout.sql; registry v5; tax/HSN/effective-date/layout profiles).
- M16 — deferred P2 (statutory/GST file generation deferred); not implemented.
- M17 — deferred P2 (import deferred); Excel-template boundary only; no pipeline.
- OD-DB-003 — BLOCKED (statutory fields pending pinned schemas: P-FIELD-LIST / P-EINV-SCH / P-GSTR-SCH / P-EWAY-SCH).
- OD-FD-002 — BLOCKED (audit old/new payload representation — pending P-LEGAL-001..005 / G0-VER-003/005).
- OD-FD-003 — deferred / boundary (statutory workflow design; file-first/user-mediated allowed; no direct API).

Notes: deferred/block items not converted; exclusions preserved; no source edits.

## 4. Work performed
Read-only audit: verified exclusion/deferred list (STATUS_LEDGER); checked m005; no new source/test edits; P-SQLIB/G0-VER-003/005/008 preserved; no false PASS for statutory/device/proof evidence.

## 5. Changed files / Tests / Traceability / Blockers / Next gate
Only phase-07.md + state/log updates. 450/1 unchanged. Blocked: P-SQLIB/G0-VER-003 (statutory schemas), FG-002/003, OD-DB-003, OD-FD-002, M16, M17 deferred. Next: 08_admin_users_and_licensing.md.
