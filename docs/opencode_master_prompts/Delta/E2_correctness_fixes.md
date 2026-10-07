# E2 — Correctness: company switch, GST tax posting (after owner memo), backup integrity, localisation source

## Mandatory first actions
Same as E1 (read rules and results, record green baseline, new branch `e2-<date>`, no HTML edits, no new packages, no weakened tests). Also read `docs/implementation/RESULT_E1_*.md` (must be PASS or PASS-WITH-BLOCKS).

## Work

### A. Company switch shows stale data (fix test at `test/presentation/shell_test.dart` ~line 180)
Review finding: Home builds its future once in `initState` with no `didUpdateWidget`; tab keys (`ValueKey('tab-page-home')` etc.) do not include the company id, so state survives a switch.
A1. Verify this yourself by reading `niav_shell.dart`, `home_dashboard_screen.dart`, `billing_hub_screen.dart`, `reports_hub_screen.dart`, `more_tab_screen.dart`.
A2. Fix: include the company id in every tab key; on company change reset visited-tab state so unvisited tabs stay lazy. Do not change the test's expectation; fix the product.
A3. Add a test that visits Billing and Reports, switches company, and proves no old-company data remains on any tab. The previously failing test must pass unchanged.

### B. GST tax posting on invoices
B1. Read `docs/g0/evidence/owner/` for any owner decision on GST place of supply and tax ledger roles. Also read `DECISIONS.md`.
B2. If NO recorded owner decision exists for (a) the intra-/inter-state rule and (b) tax ledger names and roles, do NOT implement. Write `docs/implementation/OWNER_DECISION_MEMO_GST_POSTING.md` for the owner to sign, stating exactly: proposed rule (company state equals party state: CGST+SGST; otherwise IGST; unknown state: state what happens), proposed ledger roles (Output/Input CGST, SGST, IGST), rounding as already decided (P-GST-SRC, P-DISC-PREC), reverse charge/exempt/nil handling as out of scope unless documents define it, with the source IDs and a "Approved by / date" line. Mark B3-B5 `blocked` pending sign-off and stop this section.
B3. If the decision exists: post tax arms in `_postLedgerArms` in the same transaction; party arm includes tax; returns mirror; cancel reverses tax arms; Dr=Cr enforced; separate round-off line retained.
B4. Tests: intra-state, inter-state, returns, cancel, round-off, multi-rate invoice, period lock.
B5. Update `statutory_boundary_test` expectations only where the documented rule changed.

### C. Backup integrity (design only where restore code does not exist yet)
C1. In `lib/data/security/backup.dart` make the MAC mandatory: a manifest with a missing MAC or a missing key is rejected. Bind the hash to company id and schema version. Add downgrade/strip tests.
C2. Do not implement restore here (E4 does).

### D. Localisation source of truth
D1. Make the ARB files the source: generate or verify `app_localizations_maps.dart` from them, or add a test that fails when runtime maps and ARB keys/values differ (no new packages; use a Dart test reading the ARB JSON).
D2. Localise the party/item dialog strings in `parties_items_screen.dart` (en/hi/gu). Mark Hindi/Gujarati as machine-drafted pending native review; do not claim reviewed.

## Required output
`docs/implementation/RESULT_E2_correctness_fixes.md` (nine sections; one row per item), index line `E2 | ...`. If B2 triggered, status is PASS-WITH-BLOCKS and the memo path goes in section 7. End the chat message with Overall status and the results path only.
