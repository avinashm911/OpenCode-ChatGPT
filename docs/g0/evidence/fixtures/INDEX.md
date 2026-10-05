# Fixture evidence index — Phase 2 (2026-10-03 UTC)

Deterministic accounting/statutory fixture engine. Every fixture file carries
its ID, human-readable inputs, expected postings/balances, rounding/costing
explanation, command + result, and traceability. No random data. No expected
value was changed to match implementation (all expectations hand-computed and
frozen before the green run).

| Area | Evidence file | Fixtures | Tests |
|---|---|---|---|
| GST rounding (boundaries, line vs invoice, ≤2 decimals) | `F-GST-rounding.md` | F-GST-001…008 | `test/accounting/gst_test.dart` (10) |
| FIFO / weighted-average layers | `F-COST-layers.md` | F-COST-001…005 | `test/accounting/costing_test.dart` (7 with F-NEG) |
| Negative-stock fallback + reconciliation | `F-NEG-fallback.md` | F-NEG-001/002 | same file |
| Voucher-line discounts (+ PROPOSED tax base) | `F-DISC-discounts.md` | F-DISC-001…006 | `test/accounting/discount_test.dart` (6) |
| Bill-wise settlement (+ reversal/duplicates) | `F-SETL-settlement.md` | F-SETL-001…006 | `test/accounting/settlement_test.dart` (6) |

Implementation libs (all pure-Dart, dependency-free):
`lib/data/accounting/gst.dart`, `costing.dart`, `settlement.dart`
(extends Phase 1 `migrations/validators.dart` — untouched).

Results: `flutter.bat test test\accounting` → +29 pass;
full `flutter.bat test` → **+47 pass** (17 migration + 29 fixture + 1 smoke);
`flutter.bat analyze` → clean. Reproducible from a clean checkout:
migrate disposable DB → seed fixed rows → run (no randomness, no clock reads
in assertions, fixed IDs).

## Change log (Phase 2)
| Date | Change | Traceability |
|---|---|---|
| 2026-10-03 | GST rounding lib + 10 tests / 8 fixtures | D-M4; G0-SCH-004/007; FR-M16 |
| 2026-10-03 | FIFO/WA + negative-stock engine + 9 tests / 7 fixtures | D-M5; G0-SCH-001; FR-M07-003 |
| 2026-10-03 | Discount chain fixtures (6 tests; amount-wins + tax-on-net PROPOSED) | G0-SCH-007 |
| 2026-10-03 | Settlement engine + 6 DB-backed tests | G0-SCH-003; FR-M06 |
| 2026-10-03 | Evidence files F-GST/F-COST/F-NEG/F-DISC/F-SETL + this index | Phase 2 acceptance |

## Still BLOCKED (carried, not closed)
- G0-VER-002: official GST rule-source attachment (fixtures are PROPOSED
  golden, built strictly from D-M4).
- Discount precedence + tax-on-net + CGST/SGST remainder: PROPOSED
  conventions, owner/tax review pending.
- Full trial/grace/entitlement, print, sync-conflict and device evidence:
  later phases/gates.
