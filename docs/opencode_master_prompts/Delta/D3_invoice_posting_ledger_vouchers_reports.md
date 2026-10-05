# D3 — Invoice ledger posting, ledger vouchers and books

## Mandatory first actions
1. Read `niaverp/AGENTS.md`, `niaverp/DECISIONS.md`, `docs/IMPLEMENTATION_EXECUTION_STRATEGY.md`,
   `docs/opencode_master_prompts/GLOBAL_NO_INVENTION_CONTRACT.md`, `SOURCE_CLARIFICATIONS.md`, `STATUS_LEDGER.md`, `docs/g0/PENDING_INPUTS.md`, and the results files
   `docs/implementation/RESULT_D1_*.md` and `RESULT_D2_*.md` (both must be PASS or PASS-WITH-BLOCKS; otherwise stop with FAIL).
2. Read, read-only: Functional Requirements (FR-M05, FR-M06, FR-M07, FR-M13, FR-M14, FR-M16), Functional Design Document, Data Schema Specification, Database Schema Document,
   UI/UX Specification and UX Specification sections for these modules, and `docs/g0/evidence/fixtures/F-GST-rounding.md`.
3. Run `flutter analyze` and `flutter test` first; record totals.

## Rule for this prompt
Every posting template, ledger name, tax rule and screen field must come from those documents. The statutory file boundary stays closed: no e-invoice/e-way/GST-return
schema fields, no direct portal calls (G0-VER-003, FG-002/003, FR-M16-003/004 remain blocked). Local GST CALCULATION and ledger posting are allowed only as far as the documents define them.
When a rule is absent, mark that voucher type or item `blocked` with the exact source ID and question, leave its current behaviour unchanged, and continue.

## Work items

### A. Posting templates for invoices (engine, not widgets)
A1. Sales Invoice, Purchase Invoice, Sales Return and Purchase Return: post balanced ledger lines in the SAME transaction as stock effects (party, sales/purchase,
tax, discount where documented, round-off). Dr must equal Cr. Use only ledgers the documents define; if the document names ledger roles (e.g. party control, sales, purchase, CGST/SGST/IGST output/input)
resolve them through the ledger masters created in m013; if a company lacks a required ledger, return a clear validation error naming the missing role (do not auto-create unspecified ledgers).
A2. GST amounts: use `lib/data/accounting/gst.dart` (integer paise, round-half-up per D-M4 and the golden fixture). Implement the CGST+SGST versus IGST split ONLY if the documents define the
intra/inter-state determination (company state vs party/place-of-supply state). If they do not fully define place of supply, implement the documented subset behind an explicit boundary and mark the rest `blocked`.
A3. Invoice round-off is a separate ledger line (D-M4). Persist it (the round-off function exists but is never persisted today). Test rounding up, down and exact.
A4. Return lines: today `gstTotal` and discount return 0 for non-positive amounts, so returns carry no tax or discount. Replace clamping with the documented return semantics (tax and discount reverse the
original per document rules, link to the original voucher where FR-M05 requires). If the documents do not define it, mark `blocked` with the question and keep returns untaxed with an explicit warning.
A5. Material Issue to Party / Material Receive from Party: add the stock effect the documents define (FR-M07). Stock Journal: enforce the documented balancing/value rule.
A6. Cancel (from D1) must reverse the ledger lines too, by compensating entries, in the same transaction.

### B. Ledger-voucher screens (Billing tab, thin widgets over engine/application services)
B1. Receipt, Payment, Contra and Journal forms with: ledger/party lookup, Dr/Cr entry, bill-wise allocation for receipt/payment (existing `BillAllocationRepository`), narration, date, series
numbering, post and cancel through the engine, loading/empty/validation/locked-period/success/recoverable-failure states. Money and quantity parsing (rupees to paise, percent to basis points) must live
in an application-layer parser with tests, not in widgets; move the existing parsing out of `voucher_form_screen.dart` into it.
B2. Debit Note and Credit Note without items (same form pattern).

### C. Books and reports (queries over persisted data only; no fixtures)
C1. Ledger report (per ledger, date range, running balance), Day Book, and Trial Balance, built on `lib/application/queries/ledger.dart` (extend if needed), with screens in the Reports tab and company/FY/date scope.
C2. Reports must exclude cancelled vouchers and include compensating entries consistently; test that a cancelled invoice leaves ledger, outstanding and stock reports in agreement.
C3. Export only to formats the documents approve; if none is specified, do not add export and record the question.

### D. Tests (minimum)
Per voucher type: posted lines balance; stock and ledger agree after post and after cancel; GST split cases (intra, inter if defined); round-off up/down; two-company isolation; period-lock refusal; atomic rollback on
injected failure mid-posting; trial balance Dr=Cr over a mixed set of vouchers; widget tests for each new form driving real repositories over a real migrated test database (no fakes). Update golden fixtures only with the documented rule.
Final `flutter analyze` clean; all prior tests pass.

## Do not
No statutory file schemas, no e-invoice/e-way payload fields, no invented ledger names, no new packages, no UI redesign, no localisation (D4), no edits to HTML documents. Do not call host tests physical, legal or statutory evidence.

## Required output
Write `docs/implementation/RESULT_D3_invoice_posting_ledger_vouchers_reports.md` using the template in `delta/README.md`, one row per item A1–C3 in section 2, and a posting-template table in section 3 (voucher type,
Dr lines, Cr lines, source document section). Append to `docs/implementation/RESULTS_INDEX.md`:
`D3 | <date> | <overall status> | tests <passed>/<failed> | <one-line summary>`.
End your final chat message with the Overall status and the path of the results file only.
