# Print golden-test evidence — Phase 6 — 2026-10-03 (UTC)

## Commands (workdir `E:\NiavERP v2 OpenAI\niaverp`, full-path flutter binary)

```
flutter.bat test test\print test\release
flutter.bat analyze
flutter.bat test
```

Flutter SDK: `C:\Users\USER\.openclaw-autoclaw\agents\auto-designer\workspace\.cluster\tools\flutter`
OS: Windows 10 Pro 64-bit 22H2 (10.0.19045.6466)
Flutter 3.47.5 stable / Dart 3.13.4 (same toolchain as Phases 0–4).
No new pub dependencies (print libs are pure-Dart; `crypto` already direct for SHA-256).

## Results

- `test test\print test\release` → **+20: All tests passed!**
  (ESC/POS 7: init/align/cut bytes, 32/48 cols, P58 TOTAL Rs.154.00 + TAX/SUBTOTAL,
  P80 same total + width fit, Indic GS-v-0 marker with no glyph leak;
  PDF 5: A4 523pt / A5 348pt widths, A5 fewer lines/page, ₹ totals, 2-line single
  page vs 80-line multi-page with sequential numbers, Indic raster flag;
  template 4: Rs./₹ forms, total arithmetic, validation;
  release 4: 3-channel list, FIPS SHA-256("abc") vector, verify true/false/case, 64-hex stability)
- Full `flutter test` → **+94: All tests passed!**
  (17 migration + 29 fixture + 23 security + 4 statutory-boundary + 20 print/release + 1 smoke)
- `flutter analyze` → **No issues found!**

## Coverage → acceptance (host-provable part)

- Renderers + golden tests pass on the host: PASS.
- Same `InvoiceTemplate` model on both paths: PASS (`template.dart` imported by both).
- 58 mm / 80 mm widths, A4/A5 geometry, currency, tax, page-breaks, Indic-as-raster: PASS (asserted).
- Host tests prove ONLY host generation — physical printer behavior stays PENDING-INPUT (see `PRINTER_TEST_SHEET.md`).
- Failed targets: none observed on host; physical failures to be recorded explicitly, never hidden.
