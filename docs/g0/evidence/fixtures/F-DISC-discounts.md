# Fixture evidence: voucher-line discounts — Phase 2 (2026-10-03 UTC)

Calculation rule (PROPOSED for fixture confirmation — stated, not smuggled):
explicit positive `discount_amount_paise` wins over `discount_rate_bps`;
otherwise rate applies with round-half-up; net floored at zero; integers only.
Tax-base rule (PROPOSED): taxable value = gross − discount; GST is computed
on the net base. Both proposals are implemented in `validators.dart` +
`niaverp/lib/data/accounting/gst.dart` and frozen by the tests below; final
policy confirmation belongs to the owner/tax review (G0-VER-002 family).
Tests: `niaverp/test/accounting/discount_test.dart` (6 tests).
Traceability: G0-SCH-007 (G1); FRD voucher lines; D-M4.

## F-DISC-001 — explicit amount behavior
| Input | Value |
|---|---|
| Gross | lineAmount(20000, 5000) = 2u × Rs50 → **10000p** |
| Discount amount | 1000p, rate 0 |
| Expected postings | discount **1000p**; net **9000p** |
| Explanation | Positive amount is authoritative; rate ignored. |

## F-DISC-002 — percentage behavior (10%)
| Input | Value |
|---|---|
| Gross 10000p, rate 1000 bps | (10000 × 1000 + 5000) ÷ 10000 = 1000.0 → **1000p** |
| Expected postings | discount **1000p**; net **9000p** |
| Explanation | Rate path with half-up; complements F-DISC-001. |

## F-DISC-003 — amount wins over rate
| Input | Value |
|---|---|
| Gross 10000p, amount 1500p + rate 1000 bps | discount **1500p**; net **8500p** |
| Explanation | Precedence is deterministic and recorded here (PROPOSED). |

## F-DISC-004 — discount rounding boundary
| Input | Value |
|---|---|
| Gross 25p, rate 1000 bps | (25 × 1000 + 5000) ÷ 10000 = 2.5 → **3p** |
| Explanation | Exact-half rate discount rounds half-up, mirroring GST boundary F-GST-003. |

## F-DISC-005 — discount never pays out
| Input | Value |
|---|---|
| Gross 1000p, amount 5000p | net **0p** (1000 − 5000 clamped) |
| Explanation | Oversize discounts floor at zero; no negative line amounts. |

## F-DISC-006 — tax base impact (PROPOSED: tax on net)
| Input | Value |
|---|---|
| Gross 10000p, 10% rate → discount 1000p → taxable **9000p** | GST 18%: (9000 × 1800 + 5000) ÷ 10000 = 1620.0 → **1620p** |
| Expected postings | discount 1000p; taxable 9000p; tax 1620p; line total **10620p** |
| Explanation | Full chain gross → discount → net base → tax in one asserted fixture. |

## Executed command and result
Workdir `E:\NiavERP v2 OpenAI\niaverp`;
`flutter.bat test test\accounting` → `+29: All tests passed!` (6 discount tests
included); full `flutter.bat test` → `+47: All tests passed!`;
`flutter.bat analyze` → `No issues found!`
Env: Windows 10 Pro 22H2; Flutter 3.47.5 / Dart 3.13.4.
