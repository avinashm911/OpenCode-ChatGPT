# Fixture evidence: negative-stock fallback + reconciliation — Phase 2 (2026-10-03 UTC)

Basis: D-M5 (negative stock allowed with warning; no-layer issues costed at
last known cost; no retro revaluation in V1). Storage: `item_cost_state`
fallback cost + `stock_movement.cost_source` ∈ layer/last_known/reconciled.
Reconciliation appends; history is never rewritten (DSS-C-003).
Tests: `niaverp/test/accounting/costing_test.dart` (F-NEG group), end-to-end
against a migrated disposable DB.

## F-NEG-001 — fallback costing on empty stock
| Input | Value |
|---|---|
| On hand | 0 units (no layers) |
| Last known cost | 950p/u (`item_cost_state`) |
| Issue | 10 units (100000 q4) |
| Layer draw | none (shortfall = full 100000 q4) |
| Fallback value | (100000 × 950 + 5000) ÷ 10000 = 9500.0 → **9500p** |
| Expected postings | `stock_movement M1`: qty −100000 q4, cost 9500p, source **`last_known`**; on-hand **−100000 q4** |
| Explanation | Approved negative stock: the issue is priced, flagged by source, and the balance goes negative instead of failing. |
| Traceability | D-M5; G0-SCH-001; OD-DB-002 |

## F-NEG-002 — reconciliation when stock arrives (no restatement)
| Input | Value |
|---|---|
| Prior state | M1 as above (−10u @ 9500p, last_known) |
| Arrival | 20 units @ Rs10 → layer L9: 200000 q4 / 20000p; movement M2 (+200000, 20000p, `layer`) |
| Last-known update | 950p → **1000p/u** |
| Reconciliation evidence | `audit_event E1`: M1 `last_known/9500` → covered by M2, `restated: false` |
| Expected postings/balances | M1 row **unchanged** (9500p, `last_known`); on-hand −100000 + 200000 = **+100000 q4** (10u); fallback cost now 1000p/u |
| Explanation | V1 reconciliation covers the negative balance and refreshes the fallback cost going forward; the past issue keeps its approved fallback price — nothing is restated. |
| Traceability | D-M5; G0-SCH-001; DB-004/audit; DSS-C-003 |

## Executed command and result
Workdir `E:\NiavERP v2 OpenAI\niaverp`;
`flutter.bat test test\accounting` → `+29: All tests passed!` (F-NEG-001/002
included); full `flutter.bat test` → `+47: All tests passed!`;
`flutter.bat analyze` → `No issues found!`
Env: Windows 10 Pro 22H2; Flutter 3.47.5 / Dart 3.13.4; sqlite3 3.7.0 dev-only.
