# Fixture evidence: bill-wise settlement — Phase 2 (2026-10-03 UTC)

Rule: only `status='active'` rows consume a balance; reversal marks
`reversed` (history preserved, DSS-C-003); over-allocation and duplicate
application are rejected, never clamped; impossible balances throw instead of
going negative. Implementation: `niaverp/lib/data/accounting/settlement.dart`
+ `bill_allocation` rows (G0-SCH-003) in a migrated disposable DB, so PK/FK
guards are proven as well as engine guards. Tests:
`niaverp/test/accounting/settlement_test.dart` (6 tests).
Traceability: G0-SCH-003 (G1); FR-M06; DSS-C-003/004.

Setup (all fixtures): invoice line L1 = **10000p** (Rs100); receipt lines P1 =
4000p, P2 = 6000p, P3 = 7000p; operations O1…O4.

## F-SETL-001 — partial settlement
| Input | Allocate A1: L1 ← P1, 4000p, op O1 |
| Expected postings/balances | row active; remaining **6000p** |
| Explanation | Guard passes clean; balance = 10000 − 4000. |

## F-SETL-002 — full settlement to zero
| Input | A1 (4000p) + A2: L1 ← P2, 6000p, op O2 |
| Expected postings/balances | remaining **0p** (invoice closed, two active rows) |
| Explanation | Exact-cover settlement is accepted; zero is a valid terminal balance. |

## F-SETL-003 — over-allocation rejection
| Input | After A1 (4000p): attempt A2: L1 ← P3, 7000p (remaining only 6000p) |
| Expected postings/balances | guard returns over-allocation error; **no row written**; remaining stays **6000p** |
| Explanation | The engine refuses before touching the DB; the balance is untouched. |

## F-SETL-004 — reversal restores the balance
| Input | A1 (4000p) + A2 (6000p) settled → reverse A1 (cheque bounced; audit E1) |
| Expected postings/balances | A1 `reversed` (+ audit row); active total 6000p; remaining **4000p**; re-reversal of A1 refused |
| Explanation | Reversal is a status transition with audit evidence, not a delete; reversed rows stop consuming balance. |

## F-SETL-005 — duplicate application rejected
| Input | A1 active (L1 ← P1, 4000p, O1) |
| Expected postings/balances | same `allocation_id` → engine + PK refuse; same (source, settlement, operation) under a fresh id → replay guard refuses |
| Explanation | Identity duplicates and lineage replays are two distinct rejections; both proven (DSS-C-004). |

## F-SETL-006 — impossible balances detected, never clamped
| Input | Corrupt/double-applied history: active 20000p against source 10000p (written past the engine) |
| Expected postings/balances | `remainingBalance` throws `StateError`; **no negative balance is ever returned** |
| Explanation | Invariant failure surfaces loudly for repair instead of silently clamping to zero. |

## Executed command and result
Workdir `E:\NiavERP v2 OpenAI\niaverp`;
`flutter.bat test test\accounting` → `+29: All tests passed!` (6 settlement
tests included); full `flutter.bat test` → `+47: All tests passed!`;
`flutter.bat analyze` → `No issues found!`
Env: Windows 10 Pro 22H2; Flutter 3.47.5 / Dart 3.13.4; sqlite3 3.7.0 dev-only.
