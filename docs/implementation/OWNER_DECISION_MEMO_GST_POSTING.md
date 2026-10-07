# GST posting — one-page brief for the Chartered Accountant
Date (UTC): 2026-10-07 · Replaces the 2026-10-06 memo (same file) · Source IDs: FR-M03-002 / G0-VER-003 · Status: awaiting your answers — nothing decided

## Context (what the app already does — figures only, no tax logic yet)
NiAvERP is an offline billing app. All money is stored as integer paise (no decimals in storage); quantities use 4 implied decimals. The project has provisionally adopted three working assumptions, all subject to your correction: (a) tax is computed on the net line amount ("amount-wins"); (b) any odd single-paise remainder goes to the CGST line; (c) CGST Act Section 170 was noted as the rounding source. No tax postings exist in the software yet — your answers below become the specification.

## Q1 — Place-of-supply rule (CGST+SGST vs IGST)
Which rule should the app apply? Our draft (unapproved): same-state company and party → CGST+SGST split equally; different states → IGST; state unknown → treat as inter-state with a warning. Please confirm, correct, or replace — with the statutory reference (IGST Act place-of-supply sections) we should cite in the code comments.
- CA answer: ___________________________________________________

## Q2 — Ship-to versus bill-to
When the bill-to and ship-to parties/addresses are in different states, which address decides the tax type above? What should the app do if only one of the two is recorded?
- CA answer: ___________________________________________________

## Q3 — Rounding authority (is Section 170 the right citation for line-level paise rounding?)
Our records cite CGST Act Section 170 for rounding, but we are not certain it covers line-level paise rounding and the odd-paise-to-CGST convention in accounting software. Please confirm whether Section 170 (or another provision/rule, e.g. a specific CGST Rule) is the correct authority, and state the exact rounding rule we must implement per line and per invoice total.
- CA answer: ___________________________________________________

## Q4 — Tax ledger names and posting sides
Please give the exact ledger account names and debit/credit sides the app must post, e.g. Output CGST / SGST / IGST (credit on sales) and Input CGST / SGST / IGST (debit on purchases), plus where the round-off difference line goes. Also confirm: reverse charge, exempt, nil-rated and zero-rated supplies stay OUT of scope for version 1 (yes / no)?
- CA answer: ___________________________________________________

## After your answers
We implement exactly what you write above (equal-split CGST/SGST only if you confirm it), add tests proving tax lines always balance (Dr = Cr), and re-present the result for sign-off. Until then, tax posting stays blocked; non-tax billing is unaffected.

CA name / signature / date: _________________________ · Owner sign-off: _________________________
