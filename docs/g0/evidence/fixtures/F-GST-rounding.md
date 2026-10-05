# Fixture evidence: GST rounding — Phase 2 (2026-10-03 UTC)

Arithmetic basis: D-M4 (integer paise, round-half-up; invoice round-off as a
separate ledger line to the nearest rupee). Implementation:
`niaverp/lib/data/accounting/gst.dart`. Tests:
`niaverp/test/accounting/gst_test.dart` (10 tests, all pass — see command
below). No random data. Expected values below were hand-computed and frozen
before the run; none was adjusted to match output.

G0-VER-002 (official rule-source attachment) is NOT closed by these fixtures;
they are PROPOSED golden fixtures built strictly from D-M4.

## F-GST-001 — standard slab rate
| Input | Value |
|---|---|
| Taxable base | 10000p (Rs100.00) |
| Rate | 1800 bps (18%) |
| Computation | (10000 × 1800 + 5000) ÷ 10000 = 1800.0 → **1800p** |
| Expected postings | GST 1800p (Rs18.00) |
| Explanation | Exact product; rounding is a no-op. |
| Traceability | D-M4; G0-SCH-004 |

## F-GST-002 — fractional slab rate
| Input | Value |
|---|---|
| Taxable base | 999p (Rs9.99) |
| Rate | 500 bps (5%) |
| Computation | (999 × 500 + 5000) ÷ 10000 = 49.95 → **50p** |
| Expected postings | GST 50p |
| Explanation | Standard half-up of a fractional paise result. |
| Traceability | D-M4; G0-SCH-004 |

## F-GST-003 — exact-half boundary rounds up
| Input | Value |
|---|---|
| Taxable base | 25p (Rs0.25) |
| Rate | 1800 bps (18%) |
| Computation | (25 × 1800 + 5000) ÷ 10000 = 4.5 → **5p** |
| Expected postings | GST 5p |
| Explanation | Exact .5 boundary proves half-up (not banker's, not truncation). |
| Traceability | D-M4 |

## F-GST-004 — sub-paise fraction rounds down
| Input | Value |
|---|---|
| Taxable base | 3p |
| Rate | 500 bps (5%) |
| Computation | (3 × 500 + 5000) ÷ 10000 = 0.15 → **0p** |
| Expected postings | GST 0p |
| Explanation | Below-half fractions vanish; no minimum-1p rule is invented. |
| Traceability | D-M4 |

## F-GST-005 — line-level vs invoice-level rounding
| Input | Value |
|---|---|
| Line 1 base / Line 2 base | 25p each @ 18% → 5p + 5p = **10p** |
| Invoice-level on summed base | 50p @ 18% → (50 × 1800 + 5000) ÷ 10000 = 9.0 → **9p** |
| Expected postings | Total GST **10p** (line-level authoritative per D-M4) |
| Explanation | The 1p gap is exactly why the approved rule prices each line; invoice-level computation would understate tax by 1p. |
| Traceability | D-M4; G0-SCH-007 (line amounts) |

## F-GST-006 — invoice round-off ledger line (nearest rupee)
| Invoice total | Round-off line | Rounded bill |
|---|---|---|
| 100045p (Rs1000.45) | **−45p** | 100000p |
| 100078p (Rs1000.78) | **+22p** | 100100p |
| 100050p (exact half-rupee) | **+50p** | 100100p |
| Explanation | Half-up to the rupee; the round-off is its own ledger line (D-M4), never folded into a tax or line amount. |
| Traceability | D-M4 |

## F-GST-007 — maximum two-decimal output
| Check | Result |
|---|---|
| formatRupees(1) | `0.01` |
| formatRupees(100045) | `1000.45` |
| formatRupees(−45) | `-0.45` |
| Explanation | Integer paise can express at most two decimals by construction; the formatter is asserted, and a 3-decimal probe (`1.005`) is correctly rejected by the guard. |
| Traceability | D-M4/OD-DB-001 |

## F-GST-008 — CGST/SGST split (convention F-GST-SPLIT, PROPOSED)
| GST total | CGST | SGST |
|---|---|---|
| 1801p (odd) | **901p** (remainder to CGST) | 900p |
| 1800p (even) | 900p | 900p |
| Explanation | 1 paise cannot be halved; the remainder convention is stated in-code and needs owner confirmation — it is not claimed as statutory text. |
| Traceability | D-M4 (amounts); split convention PROPOSED |

## Executed command and result
Workdir `E:\NiavERP v2 OpenAI\niaverp`;
`flutter.bat test test\accounting` → `+29: All tests passed!` (10 GST tests
included); full `flutter.bat test` → `+47: All tests passed!`;
`flutter.bat analyze` → `No issues found!`
Env: Windows 10 Pro 22H2; Flutter 3.47.5 / Dart 3.13.4; sqlite3 3.7.0 dev-only
(disposable in-memory DBs where used).
