# Fixture evidence: FIFO / weighted-average costing — Phase 2 (2026-10-03 UTC)

Basis: D-M5 (Weighted Average + FIFO only; negative stock at last known cost;
no retro revaluation; method locked after first movement — selection/lock UX
is app logic, pricing here is per-issue). Implementation:
`niaverp/lib/data/accounting/costing.dart` + real migrated disposable DB
(`stock_cost_layer`, `stock_movement`). Tests:
`niaverp/test/accounting/costing_test.dart` (F-COST only in this file).
Quantities ×10⁴, money paise, round-half-up (D-M4). Unit cost always derived
from (qty, value), never stored.

Common receipts used below — L1: 100 units (1000000 q4) / Rs1000 (100000p,
@Rs10/u, opening); L2: 50 units (500000 q4) / Rs600 (60000p, @Rs12/u,
purchase). Book: 150 units / Rs1600.

## F-COST-001 — FIFO issue across two layers
| Input | Value |
|---|---|
| Issue | 120 units (1200000 q4) |
| Draw L1 (whole layer) | 1000000 q4 → **100000p exact** (no rounding on whole-layer take) |
| Draw L2 (partial) | 200000 q4 → (200000 × 60000 + 250000) ÷ 500000 = 24000.0 → **24000p** |
| Expected postings | COGS **124000p** (Rs1240); L2 remainder 300000 q4 / 36000p |
| Explanation | Oldest layer first; partial draw pro-rates with half-up; whole-layer take is exact so rounding never drifts book value. |
| Traceability | D-M5; G0-SCH-001; FR-M07-003 |

## F-COST-002 — weighted-average issue
| Input | Value |
|---|---|
| Book | 1500000 q4 / 160000p; issue 1200000 q4 |
| Computation | (1200000 × 160000 + 750000) ÷ 1500000 = 128000.0 → **128000p** |
| Expected postings | COGS **128000p** (Rs1280); book remainder 300000 q4 / 32000p |
| Explanation | Single book rate applied to the issue; remainder keeps book consistency (160000 − 128000 = 32000). |
| Traceability | D-M5; G0-SCH-001 |

## F-COST-003 — partial consumption of one layer
| Input | Value |
|---|---|
| Issue 30 units from L1 | (300000 × 100000 + 500000) ÷ 1000000 = 30000.0 → **30000p** |
| Expected postings | COGS 30000p; L1 retains 700000 q4 / 70000p |
| Explanation | FIFO degenerates correctly to a single-layer draw. |
| Traceability | D-M5; G0-SCH-001 |

## F-COST-004 — purchase return reduces the latest layer
| Input | Value |
|---|---|
| Return 10 units @ Rs12 against L2 | L2: 500000 − 100000 = **400000 q4**; 60000 − 12000 = **48000p** |
| Expected postings | Layer shrunk at its own derived unit cost; no other layer touched |
| Explanation | Returns adjust the originating layer at cost (no profit/loss invented at return time). |
| Traceability | D-M5; G0-SCH-001 |

## F-COST-005 — godown transfer preserves value
| Input | Value |
|---|---|
| Move 10 units g1 → g2 from L2 | (100000 × 60000 + 250000) ÷ 500000 = 12000.0 → **12000p** moved |
| Expected postings | g2 layer +100000 q4 / +12000p; book total unchanged at 160000p |
| Explanation | Transfers relocate cost; they never create or destroy value. |
| Traceability | D-M5; G0-SCH-001 |

## Executed command and result
Workdir `E:\NiavERP v2 OpenAI\niaverp`;
`flutter.bat test test\accounting` → `+29: All tests passed!` (7 costing tests
included); full `flutter.bat test` → `+47: All tests passed!`;
`flutter.bat analyze` → `No issues found!`
Env: Windows 10 Pro 22H2; Flutter 3.47.5 / Dart 3.13.4; sqlite3 3.7.0 dev-only.
