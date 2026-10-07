# CA Reply — GST Posting Rules (Signed Off)

**Source document:** `docs/owner/Your_Reply_Completed.docx`  
**Converted to markdown:** 2026-10-07  
**Status:** CA SIGNED OFF — research-based response, not a certified professional opinion; practitioner sign-off required before go-live.  
**Date of advice:** 07/10/2026  
**Basis:** Public web research on 07/10/2026 — ClearTax articles where ClearTax covers the point, plus official statute/circular text (CBIC, GST Council, ICAI mirrors) where it does not.

---

## 1. Place of Supply

**Original assumption:** Same state → CGST+SGST (equal split); different state → IGST; state unknown → inter-state with warning.

**Verdict:** ✅ Confirmed with changes

**Rule to implement:**
- Tax type depends on location of **SUPPLIER vs PLACE OF SUPPLY** — not simply the "party's state".
- Same State/UT → intra-state → CGST + SGST (UTGST in a UT without legislature).
- Different State/UT → inter-state → IGST.
- For goods (IGST Act s.10):
  - (a) Goods moved → where movement terminates.
  - (b) Delivered on direction of a third person → third person's principal place of business.
  - (c) No movement → location of goods at delivery.
  - (ca) Unregistered buyer → address recorded on the invoice, else supplier's location.
- Always IGST for export and SEZ supplies.
- CGST and SGST are each half of the GST rate.
- Services follow s.12 (e.g., registered recipient → recipient's location) — **keep services out of the automatic rule until separately specified**.

**Treatment when state is unknown:**
- **Registered buyer:** Derive state from the first two digits of the GSTIN; if no valid GSTIN/state, **BLOCK posting** — do not guess.
- **Unregistered buyer (goods) with no address recorded:** Place of supply is the supplier's location, i.e., intra-state, per s.10(1)(ca).
- **Never default silently to IGST** — wrong head of tax is a real compliance error.

**Authority:** IGST Act s.7 (inter-state), s.8 (intra-state), s.10(1)(a),(b),(c),(ca) (goods), s.12 (services), s.7(5) (export/SEZ). CGST Rule 46 (invoice contents).

**Evidence:** ClearTax: cleartax.in/s/place-of-supply-gst/; ClearTax bill-to-ship-to article; Statute text of s.7: taxinformation.cbic.gov.in; s.10(1)(ca) text: caclub.in / cggst.com mirror.

---

## 2. Ship-to vs Bill-to

**Question:** Which address decides tax type when they differ?

**Answer:** Neither automatically — depends on who the ship-to party is.

**Rule:**
1. **Goods delivered to another person on the bill-to party's direction** (instruction before or during movement) → bill-to party's principal place of business decides [s.10(1)(b)]. Two supplies result: supplier→bill-to party, and bill-to party→ship-to party, each taxed by its own place of supply.
2. **Otherwise, goods moved to the buyer** → ship-to / delivery state [s.10(1)(a)].
3. **Unregistered buyer** → address recorded on the invoice; where billing and delivery addresses differ the supplier may record the delivery address as the recipient's address [s.10(1)(ca), Circular 209/3/2024].
4. The app therefore needs a **"delivered on third-party direction? Y/N" field** — it cannot be inferred from addresses alone.

**If only one address is recorded:** Use that address's state (for a registered party, the state in its GSTIN). Treat it as both bill-to and ship-to.

**If neither is recorded:**
- Registered buyer: **block posting**.
- Unregistered goods buyer: supplier's location (s.10(1)(ca)), i.e., intra-state.

**Authority:** IGST Act s.10(1)(a), (b), (ca); GST Council Circular No. 209/3/2024-GST dated 26 June 2024 (clause (ca) clarification).

**Evidence:** ClearTax bill-to-ship-to article; Circular 209/3/2024: gstcouncil.gov.in.

---

## 3. Rounding

**Original assumption:** Amounts stored in paise; tax computed on net amounts; odd paise to CGST.

### Per-line rule
**Keep paise.** Compute tax on the **NET taxable value** (after discount; Rule 46(k)):
- CGST = taxable × (rate ÷ 2) and SGST = taxable × (rate ÷ 2), computed **separately**, each rounded half-up to the nearest paisa.
- IGST = taxable × rate, rounded half-up to the paisa.
- **Do not round tax to whole rupees at line level.**

### Per-invoice rule
**Sum of lines.** Invoice CGST/SGST/IGST = sum of the line amounts of that head.
- Do **not** recompute tax on the invoice total (the e-invoice portal checks that item-level tax totals equal the invoice totals).

### Round to nearest rupee?
**Optional, at invoice TOTAL level only**, via the "Round Off" ledger line, as a separate line.
- Never alter taxable value or any tax line to force a round total.
- Cap the app's round-off at **±50 paise** (nearest rupee).
- Section 170 rounding of amounts payable to the Government is a **return/payment-level matter**, not something to apply inside each invoice line.

### Odd-paise rule for CGST/SGST split
**Not needed** — compute CGST and SGST separately from the half-rate, so they are always equal.
- If any code path computes total tax first and then splits, an odd paisa is only a software convention with no statutory basis — **avoid that path**.

### Worked example
- Line 1: taxable ₹1,234.57 @ 18% → half-rate 9%: 123,457 paise × 9% = 11,111.13 paise → ₹111.11 each CGST and SGST.
- Line 2: taxable ₹99.99 @ 5% → half-rate 2.5%: 9,999 × 2.5% = 249.975 paise → ₹2.50 each.
- Invoice: taxable ₹1,334.56; CGST ₹113.61; SGST ₹113.61; exact total ₹1,561.78; rounded to ₹1,562.00; Round Off = +₹0.22.

### Posting (sale)
```
Dr Debtors     ₹1,562.00
Cr Sales       ₹1,334.56
Cr Output CGST ₹113.61
Cr Output SGST ₹113.61
Cr Round Off   ₹0.22
Debits = Credits = ₹1,562.00
```

**Authority:** No provision found prescribing paise rounding at invoice-line level. Rule 46 requires taxable value, rate and amount of tax to be shown but does not state a rounding method. Section 170 CGST Act covers amounts payable/refundable. The GST portal accepts amounts to two decimals; NIC e-invoice validations (v1.03, 2020) compute CGST/SGST as taxable value × rate ÷ 2 per item and accept item values between the exact amount and that amount rounded up to the next rupee.

**Evidence:** ClearTax CGST Rules Chapter 6 page (Rule 46); Section 170 text: cggst.com / ICAI (vasai.icai.org); E-invoice validations: taxguru.in article dated 6 Aug 2020.

---

## 4. Ledger Names and Sides

| Transaction | Ledger Name (exact) | Debit / Credit | Note |
|---|---|---|---|
| Sale - intra-state | Output CGST | Credit | Equal half of GST rate on taxable value |
| Sale - intra-state | Output SGST | Credit | Use UTGST ledger instead if place of supply is a UT without legislature |
| Sale - inter-state | Output IGST | Credit | Also forced for export / SEZ (IGST Act s.7(5)) |
| Purchase - intra-state | Input CGST | Debit | Only eligible ITC |
| Purchase - intra-state | Input SGST | Debit | Only eligible ITC |
| Purchase - inter-state | Input IGST | Debit | Only eligible ITC |
| Rounding | Round Off | Debit or Credit by sign | Sale: invoice rounded UP = Credit, rounded DOWN = Debit. Purchase: mirror image |

**Ledger names to change (if any):** None required for v1. The ledger names match the account list in ClearTax's GST accounting article (Input/Output CGST, SGST, IGST). The law prescribes no particular ledger names, so these are accounting conventions. Add Output/Input UTGST (and Cess) only when those supplies are brought into scope.

**Version 1 scope — keep OUT:**
- ✅ Reverse charge
- ✅ Exempt
- ✅ Nil-rated

**Comments / any I should NOT exclude:**
- Also keep **zero-rated (export/SEZ)** out, or force IGST for them.
- Do **not** silently post tax on excluded cases — detect and block them:
  - (a) Reverse charge — the recipient pays tax in cash, it cannot be paid from ITC, and credit arises only after payment, so posting it as a normal Input ledger would be wrong.
  - (b) Exempt/nil-rated/non-GST supplies and supplies by composition dealers carry no tax — the app must allow tax-free lines and must not claim input credit on them.
  - (c) Credit/debit notes reverse the sides above.
- ITC eligibility rules (e.g., blocked credits) not researched; posting to Input ledgers should be limited to eligible ITC.

**Evidence:** ClearTax: cleartax.in/s/accounting-entries-under-gst; Reverse charge: cleartax.in/s/reverse-charge-gst; GST Council reverse charge flyer.

---

## 5. Authority for Rounding (CGST Act Section 170)

| Question | Answer |
|---|---|
| Does Section 170 cover line-level paise rounding on invoices? | **No** |
| Does it cover only rounding of total tax payable to the nearest rupee? | **Yes (with nuance)** — the text covers amounts payable and refunds due: tax, interest, penalty, fine or any other sum. Fifty paise or more rounds up to the next rupee; less than fifty paise is ignored. It says **nothing about invoice lines**. |
| Provision / rule that governs invoice-line rounding? | **None found.** Rule 46 (invoice contents) is silent on method. |

**If none specifically governs it, recommended practice:**
- Keep paise on every line.
- Compute CGST and SGST separately and equally.
- Sum lines for invoice totals.
- Round only the invoice total, through a separate Round Off line.
- Keep taxable value and tax lines untouched.
- Ensure each posting balances (Dr = Cr).

**Evidence:** Statute text of Section 170 verified on cggst.com, caclub.in and ICAI chapter sites. The memo's concern was right: Section 170 is not a line-level rounding authority, so code comments should not cite it for that.

---

## Additional Points

### Risks / compliance issues
1. Wrong tax head (CGST+SGST instead of IGST, or the reverse) is a genuine error with relief available only in specified cases (IGST Act s.19; CGST Act s.77) — so **never default silently**.
2. Unknown or invalid state must **stop posting**.
3. Capture the "third-party direction" flag for bill-to/ship-to.
4. Rule 46 detail for unregistered recipients depends on invoice value (the ₹50,000 threshold).
5. Round-off is an invoice-total item only.
6. Re-verify NIC/IRP validation limits against the current schema before building e-invoice export.

### Turnover / composition / registration dependencies
- E-invoicing (IRN/QR code) depends on aggregate turnover above a notified threshold — the figure has changed since 2020 and I have not verified the current one.
- Composition dealers do not charge tax on invoices and need a tax-free bill of supply.
- Unregistered suppliers charge no GST.
- Anyone liable under reverse charge must register regardless of turnover.
- A buyer's registration type (registered / unregistered / SEZ) changes the place-of-supply rule, so **store it on the party**.

### Notifications/circulars relied on (with date)
- GST Council Circular No. 209/3/2024-GST dated 26 June 2024 (s.10(1)(ca)).
- IGST Amendment Act 2023, clause (ca) effective 01 October 2023.
- CGST Rules 2017, Rule 46.
- Notification No. 60/2020-Central Tax (e-invoice schema; sources I saw give different months for its date, so verify).
- A 57th GST Council meeting was reported as scheduled for 8 October 2026; I have not reviewed any outcome.

---

**This advice is based on the law as of: 07 / 10 / 2026**

**Disclaimer:** This is a research-based response, not a signed or certified professional opinion. Please have a practising CA sign off before go-live.