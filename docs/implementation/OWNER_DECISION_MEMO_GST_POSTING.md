# OWNER DECISION MEMO — GST tax posting (B2 / E2 section B)
Date (UTC): 2026-10-06   Source IDs: FR-M03-002 / M03 / G0-VER-003 / DECISIONS.md P-BILLDEF / P-GST-SRC / P-DISC-PREC
Status: BLOCKED — no recorded owner decision for intra-/inter-state rule or tax ledger roles; this memo is for owner sign-off before B3-B5 can proceed.

## What exists (verified by read)
- `DECISIONS.md`: P-BILLDEF (settlement types: Payment/Receipt/Contra/Journal are not receivables; advances); P-GST-SRC (rounding: amount-wins; tax on net; CGST receives odd paise); P-DISC-PREC (same). No intra-/inter-state rule. No tax-ledger names or roles.
- `docs/g0/evidence/owner/PUBLIC_SOURCE_EVIDENCE_20261003.md`: P-GST-SRC points to CGST Act Section 170; no state/place-of-supply definition adopted.
- `PENDING_INPUTS.md`: P-GST-SRC CLOSED (rounding only); P-FIELD-LIST deferred for R1a; no GST tax-ledger design recorded.
- Source (`lib/application/services/voucher_engine.dart`, `ledger.dart`, `voucher_posting_test.dart`): no tax-ledger posting code present.

## What is missing (exact owner questions)
1. Intra-/inter-state rule: when company state equals party state → CGST+SGST; when different → IGST; state unknown → what? (Reference needed: CGST Act Section 170 / IGST Act sections defining place of supply; official source or owner-approved fixture required.)
2. Tax-ledger roles/names: proposed `Output CGST`, `Output SGST`, `Output IGST`, `Input CGST`, `Input SGST`, `Input IGST`; roles (debit/credit per transaction type); whether tax arms use separate ledger accounts or sub-ledger lines.
3. Reverse charge, exempt, nil-rated, zero-rated handling: out of scope unless defined by source; memo states out-of-scope unless owner approves inclusion.
4. Multi-rate invoice (B4): rate grouping per line; how partial-rate invoices aggregate tax by rate/state.
5. Returns / cancel: tax reversal mirrors original posting; period-lock interaction (tax must reverse within same lock or require unlock).

## Proposed (NOT approved) — for owner review only
- Intra-state: company state == party state → CGST + SGST (equal split per state convention); inter-state → IGST; unknown state → treat as inter-state (IGST) with warning; never guess.
- Tax-ledger roles (additive only; no schema change unless owner approves): `Output CGST` (credit), `Output SGST` (credit), `Output IGST` (credit), `Input CGST` (debit), `Input SGST` (debit), `Input IGST` (debit); separate `Tax Round-Off` line (debit/credit) for odd-paise remainder per P-DISC-PREC.
- Rounding: line-level amount-wins; net-amount tax; CGST receives remainder per P-DISC-PREC; total of tax lines must equal total tax computed.
- Returns: reverse original tax arms exactly; cancel: reverse including tax; Dr=Cr enforced (tax total must balance).
- Multi-rate: group by rate/state; aggregate per group; total must match line-level sum.
- Scope exclusions preserved unless owner approves: reverse charge, exempt/nil-rated categories not implemented here (no statutory schema for them in V1).

## Required approvals (before B3-B5)
- [ ] Approved by: _______________ (named reviewer per P-LEGAL-001 / G0-VER-007)
- [ ] Date: _______________
- [ ] Source IDs cited: FR-M03-002 / M03 / G0-VER-003 / P-GST-SRC / P-DISC-PREC / DECISIONS.md (P-BILLDEF)
- [ ] Confirm intra-state / inter-state / unknown-state rule (referenced statutory source)
- [ ] Confirm tax-ledger names and roles (additive only)
- [ ] Confirm exclusions (reverse charge / exempt / nil-rated out of scope unless specified)
- [ ] Confirm schema change scope (additive only; repeat-safe migration; version increment)

Until all approvals filled, B3-B5 remain BLOCKED; no tax-ledger code added.
