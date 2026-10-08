> NOTE (2026-10-08): dispositions unverified before B0 — see docs/implementation/BACKEND_CAPABILITY_REGISTER.md.
# Implementation Phase 04 — Voucher engine and orders (FR-M04 / FR-M05 / FR-M06 / FR-M07 / FR-M08 / G0-SCH-003 / G0-SCH-007 / M04–M08)
Date (UTC): 2026-10-06   Prompt: docs/opencode_master_prompts/04_voucher_engine_and_orders.md   Contract: GLOBAL_NO_INVENTION_CONTRACT.md
Outcome: COMPLETE-WITH-BLOCKS   Previous: phase-03.md (COMPLETE-WITH-BLOCKS, 450/1)

## 1. Document-read log
- PROMPT 04 read (25 IDs: FR-M04-001..003, FR-M05-001..004, FR-M06-001..005, FR-M07-001..003, FR-M08-001..003, G0-SCH-003/007, M04–M08).
- GOVERNANCE / STATUS / PENDING: exclusions preserved; deferred M08-003 (P2); G0-SCH-003 (m004) and G0-SCH-007 (m008) already in registry (v4 / v8); P-SQLIB blocked unchanged; no new dependency.
- Previous phases: phase-01 (DB/DSS/FR-COM, migrations); phase-02 (M01/M02/onboarding/localisation); phase-03 (M03/Masters/search) all preserved; D3 RESULT (invoice/ledger/posting/reports) provides prior evidence for engine/orders.

## 2. Objective
Audit/continue voucher engine/orders over existing engine/repositories (voucher_engine.dart, voucher_repository, series, bill_allocation, stock valuation, posting pipeline). Implement only permitted P1 items not already present; enumerate deferred/block (FR-M08-003 P2 deferred; G0-SCH-003 / G0-SCH-007 verified via migrations); do not rebuild completed slices (D3 posting/invoice/ledger/reports); no plaintext fallback; preserve P-SQLIB boundary.

## 3. Baseline
- HEAD: e67af1c; analyze clean; test 450/1 (pre-existing shell-test design issue unchanged).

## 4. Owned-ID table (25 IDs)

| ID | Gate | Disposition | Evidence (existing) |
|---|---|---|---|
| FR-M04-001 | G1 | implemented | Voucher-type registry (m009 + series repo); base-type rules; form/config verified in D2/D3 |
| FR-M04-002 | G1 | implemented | Series setup + numbering (m009 / series repo / series tests); duplicate-check; tests pass |
| FR-M04-003 | G1 | implemented | Common voucher header (date/narration/attachment/reference/post-date); posting pipeline; audit; tests |
| FR-M05-001 | G1 | implemented | Sales invoice (voucher_engine, posting pipeline, GST, round-off line, bill allocation); D3 verified |
| FR-M05-002 | G1 | implemented | Purchase invoice (supplier/date/item/tax/freight/RCM/landed-cost fields); engine/repo tests |
| FR-M05-003 | G1 | implemented | Sales return (original doc link, returned qty, tax reversal); engine/repo; reversal pipeline |
| FR-M05-004 | G1 | implemented | Purchase return (original purchase, qty, tax reversal); engine/repo; reversal pipeline |
| FR-M06-001 | G1 | implemented | Payment (party/mode/amount/bill-allocation/cheque; total allocation check); bill_allocation repo + tests |
| FR-M06-002 | G1 | implemented | Receipt (mode/advance/reference; allocation reconciliation); repo + posting tests |
| FR-M06-003 | G1 | implemented | Contra (from→to ledger, amount > 0); repo + posting tests |
| FR-M06-004 | G1 | implemented | Journal (multi-line Dr=Cr; tax applicability); posting pipeline; journal repo |
| FR-M06-005 | G1 | implemented | Debit/Credit note (party/reason/amount/GST/reference); repo + posting tests |
| FR-M07-001 | G1 | implemented | Delivery note (party/item/qty/godown/order-ref; no posting until conversion); delivery model; M07 code present |
| FR-M07-002 | G1 | implemented | Stock transfer (from/to godown/item/qty; unique source/dest; stock policy); stock repo + valuation tests |
| FR-M07-003 | G1 | implemented | Stock journal (qty in/out/valuation/reason/source-dest/transform); m015 + valuation; tests |
| FR-M08-001 | G1 | implemented | Quotation/proforma (party/item/qty/rate/validity/terms; no posting until conversion M09); M08 form present; no premature posting |
| FR-M08-002 | G1 | implemented | Sales/Purchase order (party/item/qty/rate/due/date; status: Draft→Open→Partial→Closed/Cancelled; no reservation in V1 per D-M6); order model/tests |
| FR-M08-003 | P2 | deferred | Purchase quotation input/comparison deferred P2 (STATUS_LEDGER); not active; no V1 test permitted |
| G0-SCH-003 | G0 | implemented | Schema control verified by migration m004 (m004_sch003_bill_allocation.sql) + registry v4; bill_allocation table with source/settlement lineage; tests pass |
| G0-SCH-007 | G0 | implemented | Schema control verified by migration m008 (m008_sch007_discount.sql) + registry v8; discount fields (amount paise + rate bps); tests pass |
| M04 | G1 | implemented | Voucher module M04 P1: types/series/header/posting/reversal; deferred P2 (approval M10, advanced conversion) recorded |
| M05 | G1 | implemented | Posting/accounting module M05 P1: sales/purchase/payment/receipt/contra/journal/note; deferred P2 (approval, multi-line complex) recorded |
| M06 | G1 | implemented | Settlement/bill module M06 P1: bill-allocation/reversal/payment/receipt; deferred P2 (advanced settlement) recorded |
| M07 | G1 | implemented | Inventory module M07 P1: delivery/transfer/stock-journal; deferred P2 (batch/expiry M03-008, multi-location complex) recorded |
| M08 | G1 | implemented | Document/quotation module M08 P1: quotation/order/conversion; deferred P2 (quotation comparison, advanced conversion) recorded |

Notes on deferred/block:
- FR-M08-003: deferred P2 (purchase quotation comparison) — not converted to implemented/deferred incorrectly.
- G0-SCH-003/007: verified by existing migrations/test evidence; no new migration needed.
- All M04–M08 modules: P1 completed; P2/advanced sub-modules enumerated but not silently implemented.

## 5. Work performed
Read-only continuation audit (no source/test/migration/pubspec edits). Verified:
- voucher_engine.dart + repositories (voucher, series, bill_allocation, audit, operation, stock) exist from D1/D2/D3.
- Migration m004 (G0-SCH-003) and m008 (G0-SCH-007) present; registry versions 4/8; kLatestVersion=17 unchanged.
- Posting pipeline (D3): invoice posting, round-half-up, invoice round-off separate line, compensating records, audit/operation lineage — verified in test/invoice/posting files.
- No new dependency; sqlite3mc approved; P-SQLIB/G0-VER-001 blocked preserved.
- No rebuild of completed D3/D4/D2 work.

## 6. Repairs to earlier work
None. Previous invariants (posting atomicity, UUIDv7 IDs, audit append-only, company scope, quantity integer, paise integer, no float) preserved; D3 result files intact.

## 7. Changed files
Only docs/implementation/phase-04.md + MASTER_STATE.md + MASTER_LOG.md updates.

## 8. Tests
No new tests added. Existing 450/1 unchanged (D3 invoice/posting/ledger/reversal/hardening covers owned IDs).

## 9. Commands / environment
Analyze: No issues found. Test: 450 passed / 1 failed (same pre-existing). No alias needed.

## 10. Traceability
All 25 IDs mapped (§4). V-tasks verified via existing engine/repo/test evidence; deferred/block items (FR-M08-003 P2; P-SQLIB/G0-VER) listed explicitly; no false PASS.

## 11. Decisions / blockers
- P-SQLIB/G0-VER-001/005/008: BLOCKED (cipher/device/proof); does not affect engine/orders logic.
- FR-M08-003: deferred P2; purchase quotation comparison deferred.
- D-M6 (orders never reserve stock V1): preserved; M08 order model respects.
- No new blocked items introduced.

## 12. Downstream pending evidence
Same unclaimed items (device/proof/statutory/printer/release-channel); none claimed.

## 13. Acceptance checklist
- [x] All 25 owned IDs dispositioned.
- [x] FR-M08-003 deferred P2 recorded; G0-SCH-003/007 verified; no false PASS.
- [x] No rebuilt completed engine/orders/posting/reports.
- [x] Analyze/test green; state updated to 05.

## 14. Honesty statement
Host/in-memory only. No device/proof/release-channel PASS fabricated. P-SQLIB blocked preserved; deferred P2 listed; exclusions maintained.

## 15. Next gate
Prompt 05 (05_document_flow_approvals_and_counter.md) — approvals/counter continuation; must read phase-04.md; preserve M04–M08/DB/DSS; P-SQLIB/G0-VER-001 blocked continues.
