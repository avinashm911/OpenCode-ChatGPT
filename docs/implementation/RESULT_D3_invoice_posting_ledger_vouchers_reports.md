# RESULT D3 — Invoice ledger posting, ledger vouchers and books
Date (UTC): 2026-10-06   Overall status: PASS

## 1. Baseline before changes

- `flutter analyze` before editing: **No issues found** (Flutter 3.47.6 /
  Dart 3.13.5 via `dart.exe flutter_tools.snapshot`).
- `flutter test` before editing: **431 passed / 0 failed**.
- RESULT_D1 + RESULT_D2 both PASS (verified headers); D0 inventory consumed.
- Mandatory reads: `niaverp/AGENTS.md`, `niaverp/DECISIONS.md`,
  `docs/IMPLEMENTATION_EXECUTION_STRATEGY.md`, `GLOBAL_NO_INVENTION_CONTRACT`,
  `SOURCE_CLARIFICATIONS.md`, `STATUS_LEDGER.md`, `docs/g0/PENDING_INPUTS.md`,
  `docs/g0/MIGRATION_DESIGN.md` (re-read for reversal rules), the D1/D2 result
  files, `docs/g0/evidence/fixtures/F-GST-rounding.md`, and — read-only, never
  edited — the FR/Functional-Design/Data-Schema/DB-Schema/UI-UX/UX HTML
  sections (MPL §8 posting templates; REG M05–M07/M16 entry fields; D-10
  edition boundary; ZCP job-work table; D-M4/fixture math). Missing phase
  reports (stated, not invented): `phase-00/01/02.md`.
- Decisive source findings (all cited by section below): MPL §8 default
  templates for all 14 voucher groups incl. Dr/Cr arms and stock effects;
  m013 header "balances derived from posted voucher lines (ledger refs +
  Dr/Cr)"; D-10 places Material Issue/Receive in Advanced R1b+ (ZCP: R2 skip);
  OD-FD-001 leaves stock-journal valuation open; place-of-supply determination
  rule is nowhere defined (only named); FY/status vocabularies stay free;
  Excel import/export approved (D-10) but writer packages unverified.
- git: branch `baseline-triage-20261006-d0r2`; no-space alias not needed.

## 2. Work-item table

| ID | Item | Status (implemented / boundary / blocked / not-done) | Evidence (file:line, test name) |
|---|---|---|---|
| A1 | Posting templates for the 4 invoice types (same-tx arms, Dr=Cr, role resolution, no auto-create) | implemented | `voucher_engine.dart` `_postLedgerArms/_writeLedgerArm/_roleLedger/_partyPostingLedger` (MPL §8); `invoice_posting_test.dart` arm-shape/mirror/missing-role/atomicity tests (11 incl. postDraft path) |
| A2 | GST amounts + CGST/SGST-vs-IGST split | implemented (subset) / blocked (determination) | Subset: `lineGstPaise` in `gst.dart` (D-M4 math + P-DISC-PREC odd-to-CGST) + split tests. Blocked: intra/inter determination — no document defines the company-state vs party/place-of-supply comparison (G0-VER-003). Question: which master/field comparison selects CGST+SGST vs IGST? |
| A3 | Round-off persisted as separate ledger line | implemented | `invoiceRoundOff` (D-M4/F-GST-006) persisted as ± arm in `_postLedgerArms` (negative stored positive on opposite side, G0 CHECK holds); up/down/exact tests (`invoice_posting_test`); form comment updated |
| A4 | Return tax/discount semantics | implemented (mirror, untaxed) | Template mirror arms implemented (MPL §8 "Reverse of sale/purchase"); tax reversal blocked with A2 (no determination); discount already in line net (P-DISC-PREC); explicit untaxed warning = existing `pendingEffects` GST note. No link-to-original invented (no FR-M05 link requirement found) |
| A5 | Material Issue/Receive stock + Stock Journal rule | boundary / blocked | Material Issue/Receive: boundary — effect defined (MPL §8 "Out to/In from party location") but gated R1b+ (D-10) / R2 skip (ZCP); engine R1b pending-effect unchanged, no code change. Stock Journal: blocked — balancing/value rule open per OD-FD-001. Question: freeze stock-journal valuation/balancing (OD-FD-001)? |
| A6 | Cancel reverses ledger lines too (same tx) | implemented | `_reverseLedgerArms` (mirror every Dr/Cr line, originals untouched) called in `cancelPosted` before the status move; `invoice_posting_test` cancel test + form cancel test (4 lines incl. mirrors) |
| B1 | Receipt/Payment/Contra/Journal forms + app-layer parser | implemented | `ledger_voucher_form_screen.dart` (4 configs) + hub entries; `entry_parsing.dart` + tests; `voucher_form_screen.dart` delegates to parser; `ledger_voucher_form_test.dart` (post/day-book, validation, locked, party, cancel, receipt-advance) |
| B2 | Debit/Credit Note forms | implemented | Same screen (2 configs, party-required); Debit party-requirement widget test |
| C1 | Ledger/Day-Book/Trial on queries with scope | implemented | Pre-existing and re-verified: `ledgerBalance`/`ledgerAccount` (date range), `dayBook` (type/series/date), `trialBalance`/`groupTrialBalance`, `books_report_screen`; arms flow through automatically. FY filtering not invented (no documented FY report scope) |
| C2 | Cancelled consistency across reports | implemented | `invoice_posting_test` C2 test (cancelled purchase: ledger 0, trial 0, outstanding empty, stock 0); `bills()`/`voucherOpenBalance`/invoice-view read document lines only so arms never inflate bills |
| C3 | Report export | not-done (question) | Question: which format — D-10 approves Excel import/export but writer packages are unverified (no new packages allowed) and CSV alone is unspecified, so no export was added |

## 3. Changed files (new / modified / deleted, one line each)

Engine + queries:
- MOD niaverp/lib/application/services/voucher_engine.dart (`_postLedgerArms`, `_writeLedgerArm`, `_reverseLedgerArms`, role/party resolvers, `_LedgerArm`, cancel hook, gst import)
- MOD niaverp/lib/data/accounting/gst.dart (`lineGstPaise` documented subset)
- MOD niaverp/lib/application/queries/outstanding.dart (`bills()` + `voucherOpenBalance` exclude ledger-marked arms)
Application layer:
- NEW niaverp/lib/application/parsing/entry_parsing.dart (qty/paise/bps parser)
Presentation:
- NEW niaverp/lib/presentation/billing/ledger_voucher_form_screen.dart (6 configs, states, allocation, cancel)
- MOD niaverp/lib/presentation/billing/billing_hub_screen.dart (6 additive entries)
- MOD niaverp/lib/presentation/billing/invoice_view_screen.dart (document-line totals/rows/open/allocation; `_isDocLine`)
- MOD niaverp/lib/presentation/billing/voucher_form_screen.dart (parser delegation + round-off comment)
Tests (new / modified):
- NEW niaverp/test/application/invoice_posting_test.dart (11: arms ×4 types, round-off ×3, missing roles, atomicity, cancel agreement, trial-zero, two-company, GST subset ×2)
- NEW niaverp/test/application/entry_parsing_test.dart (3)
- NEW niaverp/test/presentation/ledger_voucher_form_test.dart (6: contra post/day-book, validation, locked, debit-party, cancel mirrors, receipt advance)
- MOD 15 test files (D3-A1 fixtures: role ledgers + party links via `VoucherSeeder.ensurePostingLedgers/linkPartyLedgers`)
- MOD niaverp/test/helpers/seeded_post.dart (fixture helpers incl. multi-company idSuffix)
- MOD niaverp/test/application/voucher_cancel_test.dart (multi-company fixture ids), business_cycles (mirror-aware cancel asserts), report_consistency + books_report (day-book gross now includes arms, journal-consistent), voucher_posting (open-balance filter check)
Deleted: none (two temporary probe files created during debugging, removed).

## Posting-template table (MPL §8; implemented arms)

| Voucher type | Dr lines | Cr lines | Source section |
|---|---|---|---|
| Sales Invoice | Party (net+ro) [Round Off if ro<0] | Sales (net) [Round Off if ro>0] | MPL §8; D-M4/F-GST-006 (ro) |
| Purchase Invoice | Purchases (net) [Round Off if ro>0] | Party (net+ro) [Round Off if ro<0] | MPL §8; D-M4/F-GST-006 |
| Sales Return / Credit Note with items | Sales Return (net) [Round Off if ro>0] | Party (net+ro) [Round Off if ro<0] | MPL §8 "Reverse of sale" |
| Purchase Return / Debit Note with items | Party (net+ro) [Round Off if ro<0] | Purchase Return (net) [Round Off if ro>0] | MPL §8 "Reverse of purchase" |
| Cancel of any voucher with ledger lines | Mirror of each Cr line | Mirror of each Dr line | MPL §8 invariants ("cancelled vouchers reverse cleanly"); D1 compensating-history |
| (Blocked) Output/Input GST arms | — | — | Awaiting intra/inter determination (G0-VER-003); F-GST-SPLIT convention recorded |
| (Boundary) Material Issue/Receive stock | — | — | Effect defined, gated R1b+ (D-10) / R2 (ZCP); engine R1b pending-effect kept |

Role resolution (documented arm names, exact master match, missing → validation
error naming the role; party arm via DB §3 party→ledger link; no auto-create):
Sales, Purchases, Sales Return, Purchase Return, Round Off, party ledger.
Tax/discount: no arms — discount lives in line net (P-DISC-PREC); tax arms await A2.

## 4. Tests

- Added: 20 tests (invoice_posting 11, entry_parsing 3, ledger forms 6).
- Final: `flutter analyze` → No issues found; `flutter test` → **451 passed /
  0 failed** (431 + 20).
- Required D3 scenarios: per-type balance + stock/ledger agreement (invoice
  posting tests); GST intra split cases (computation); round-off up/down/exact
  persisted; two-company isolation; period-lock refusal (existing + form
  locked test); atomic rollback on injected arm-id collision (+ existing
  allocation atomicity); trial Dr=Cr mixed set; widget tests per new form
  family incl. receipt advance + cancel mirrors; golden fixtures untouched
  (D-M4 rule unchanged).
- Pre-existing tests: fixtures extended with documented role ledgers (no
  invented masters); expectations updated only where D3 changes stored truth
  (day-book gross now includes arms like journals; cancel appends mirror arm
  audits) — each with a code comment naming the rule.

## 5. Commands run and exact output summary

- `flutter analyze` before: No issues; after: No issues found.
- `flutter test` before: +431; mid-work: 40 fixture failures (missing role
  ledgers — expected, then resolved file by file); after: **+451: All tests
  passed!** (~35s).
- Three mechanical fixture batches delegated to subagents (file-disjoint,
  fixtures-only); all expectation updates and new work done directly;
  re-verified by full suite + diff review.
- Widget-debugging notes (recorded for D4): `scrollUntilVisible` without an
  explicit scrollable throws on multiple scrollables — use `ensureVisible`;
  finders skip offstage widgets — resolve keys with `skipOffstage: false`;
  widget-test real IO (files/sqlite) needs `tester.runAsync` (FakeAsync).
- Greps: no `posting-engine` literal; all layer/cost statements company-scoped;
  no report export writer exists in lib/.
- Environment: same SDK invocation; no alias needed.

## 6. Deviations from the prompt, with reason

- No tax ledger arms (A2-blocked): posting Sales/Purchases/Returns/Round-off
  arms without tax keeps Dr=Cr and the documented template structure; adding
  CGST/SGST/IGST arms would require inventing the place-of-supply comparison.
- Returns post untaxed with the existing GST pending-effect as the explicit
  warning (A4); no original-linking invented (no FR-M05 link requirement found
  in the HTML set — engine FR-M05-xxx citations in old comments refer to
  register rows at module granularity only).
- Material Issue/Receive stock effects NOT added (would breach the D-10 R1b+
  edition boundary, which outranks prompt wording per AGENTS.md); Stock
  Journal value rule NOT added (OD-FD-001 open).
- `bills()`/`voucherOpenBalance`/invoice views read document lines
  (`dr_cr IS NULL`); day-book keeps SUM(all) journal-consistent with updated
  expectations; `partyOutstanding` needed no change (arms never carry a party).
- No report export (C3 question); no FY report scope (not in documents); no
  statutory fields/columns/APIs anywhere (G0-VER-003 boundary held).
- Journal/Contra/Debit/Credit forms share one parameterized screen (shapes
  differ only by config); receipt/payment allocation attaches to each bill's
  first document line (documented in code).

## 7. Owner questions (exact source ID + question) and downstream evidence still pending

- D3-A2 (G0-VER-003): which master/field comparison selects CGST+SGST vs IGST
  (company state vs party/place-of-supply state)? Split convention F-GST-SPLIT
  stays PROPOSED (P-DISC-PREC closed only amount-wins/tax-on-net/odd-to-CGST).
- D3-A5 (OD-FD-001): freeze stock-journal valuation/balancing behaviour?
- D3-C3: approve a report-export format achievable without unverified packages
  (D-10 names Excel; writer packages unconfirmed; CSV alone unspecified)?
- Carried: P-SQLIB confirmation + G0-VER-001; G0-VER-005/008, 003/004/006/007;
  D2-B4 uniqueness; D2-E1 MAC KDF; D2-F1 package id/label/channel; D2-F3
  drift; missing phase-00/01/02 reports.
- No other new `blocked` items (A5-material is boundary R1b+, not blocked).

## 8. Honesty statement

- 451 passing tests are host/in-memory runs (sqlite3 incl. sqlite3mc, temp
  files, fake channel); nothing here is Android-device, printer, legal,
  statutory, or GST-filing evidence. The F-GST fixtures remain PROPOSED
  (G0-VER-002 open); no statutory schema was touched.
- Posting templates implement only MPL §8 arms with documented names; tax,
  RCM, credit-note timing and composition handling were left out exactly where
  the documents mark VERIFY/owner-decision. No field, rule, package,
  permission, or platform behaviour was invented; no HTML, workbook, or
  register was edited; no test was deleted (expectations moved only with the
  stored-truth change, each commented).

## 9. Next prompt

- D4 (`delta/D4_localisation_more_tab_and_polish.md`) is next per the Delta
  order. After D4, master prompts 07–11 (missing parts) then 12, 13 (per the
  D0 coverage audit). D4 must not alter posting math or arm semantics.
