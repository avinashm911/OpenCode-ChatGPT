Subject: NiAvERP — 5 GST questions before we implement tax posting

Dear Sir/Madam,

Our billing app is ready to post GST lines on invoices, but we will not implement anything until you confirm the rules. The full one-page brief is attached (`OWNER_DECISION_MEMO_GST_POSTING.md`); the questions in short:

1. **Place of supply** — same-state sale → CGST+SGST split equally; different states → IGST; state unknown → treat as inter-state with a warning. Correct? Please cite the IGST Act sections we should reference.
2. **Ship-to vs bill-to** — when they are in different states, which address decides the tax type? What if only one is recorded?
3. **Rounding** — we store money in paise and compute tax on net amounts (odd paise to CGST). Please state the exact per-line and per-invoice rounding rule.
4. **Ledger names** — please confirm the exact tax ledger names and debit/credit sides (e.g. Output CGST/SGST/IGST on sales, Input CGST/SGST/IGST on purchases, plus the round-off line), and whether reverse charge / exempt / nil-rated stay OUT of version 1.
5. **Extra question on authority** — our records cite CGST Act Section 170 for rounding. Is Section 170 the right authority for **line-level paise rounding on invoices**, or does it cover **only rounding the total payable tax to the nearest rupee**? If the latter, which provision/rule governs invoice-line rounding?

Background for Q5 — our working assumptions (amount-wins, tax-on-net, odd-paise-to-CGST) are adopted provisionally only and will be replaced by your answers.

Thank you,
(owner name) — please reply in writing; your answers become the build specification.
