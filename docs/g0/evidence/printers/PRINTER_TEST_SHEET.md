# Printer test sheet — Phase 6 (v0.8)

Date (UTC): 2026-10-03
Prompt authority: `NiAv_G0_Prompts_Pack_v0.8.md` Phase 6
Traceability: O-12 / O-M07 / OD-008; FR-M21-001; G0-VER-006 (gate G5)

> Host golden tests prove ONLY host byte generation / geometry. They do
> **not** prove behavior on a physical printer. No printer row below is PASS
> without physical or captured output evidence. The printer model matrix is
> **not named in the documents** — the owner freezes it under OD-FD-006
> (≥3 printers). Until then every printer row is PENDING-INPUT.

## Approved output profiles (implemented + host-tested)

- Bluetooth ESC/POS thermal **58 mm (32 cols)** and **80 mm (48 cols)** —
  `niaverp/lib/data/print/escpos.dart`; golden bytes in
  `niaverp/test/print/escpos_test.dart` (INIT/align/cut, widths, currency,
  tax, totals, Indic-as-raster).
- PDF via Android print/share **A4 (595×842pt)** and **A5 (420×595pt)** —
  `niaverp/lib/data/print/pdf_layout.dart`; geometry in
  `niaverp/test/print/pdf_layout_test.dart` (523/348pt content widths,
  page-breaks, currency, tax, Indic raster flags).
- Indic text rendered as **raster image** on both paths —
  `containsIndic()` (Devanagari U+0900–U+097F) → `rasterMarker()` (thermal)
  / `raster:true` (PDF). Same `InvoiceTemplate` model on both paths.
- Currency: thermal `Rs.154.00` form (code-page safe); PDF `₹` source
  strings (rasterised at print). Tax/subtotal/round-off/TOTAL lines on both.

Host result: `flutter test test\print` → **16 pass** (7 ESC/POS + 5 PDF +
4 template/model — see `docs/g0/evidence/printers/print-test-20261003.log.md`).

## Frozen matrix (owner input — currently missing)

| Slot | Make / model | Connection | Paper / profile | Status |
|---|---|---|---|---|
| P-PRN-001 | *TBD — owner to freeze under OD-FD-006* | Bluetooth (thermal) | 58 mm | PENDING-INPUT |
| P-PRN-002 | *TBD — owner to freeze under OD-FD-006* | Bluetooth (thermal) | 80 mm | PENDING-INPUT |
| P-PRN-003 | *TBD — owner to freeze under OD-FD-006* | Android print/share | A4 + A5 PDF | PENDING-INPUT |

Smallest owner question: what is the frozen ≥3-printer matrix under OD-FD-006
(make/model, connection method, paper width for each)?

## Result template (copy one block per printer)

```text
Printer: <make / model>
Connection: <Bluetooth / Android print-share>
Android: <release> / API <sdk> + device model + build id
Paper / profile: <58mm-32col | 80mm-48col | A4 | A5>
Template: <InvoiceTemplate fixture id + checksum>
Sample: <invoice no + report type>
Character result: <PASS/FAIL — legible glyphs / raster image attached>
Alignment result: <PASS/FAIL — centre/left as laid out>
Currency result: <PASS/FAIL — Rs./₹ + paise exact>
Tax result: <PASS/FAIL — tax lines reconcile to fixture>
Page-break result: <PASS/FAIL — thermal wrap / PDF pages as computed>
Retry/offline behavior: <PASS/FAIL — disconnect mid-job, reprint, offline queue>
Evidence: <photo path / captured output path under docs/g0/evidence/printers/>
Status: PASS | FAIL | PENDING-INPUT
```

## Open rows (v0.8 PENDING-INPUT)

| Row | Status | Missing input | Closing step |
|---|---|---|---|
| P-PRN-001 physical result | PENDING-INPUT | Frozen matrix + 58 mm printer + device | Run template above; attach photo/capture; re-run Phases 7–8 |
| P-PRN-002 physical result | PENDING-INPUT | Frozen matrix + 80 mm printer + device | Same |
| P-PRN-003 physical result | PENDING-INPUT | Frozen matrix + PDF path + device | Same; attach printed/shared PDF |
| Failed-target support claim | — | None claimed | Failed targets remain explicitly unsupported with owner action (none observed on host; physical failures to be recorded here, not hidden) |

## Change log

| Date | Change | Traceability |
|---|---|---|
| 2026-10-03 | Renderers + golden tests + this sheet; no physical PASS claimed; matrix left PENDING-INPUT | FR-M21-001; G0-VER-006; OD-FD-006 |
