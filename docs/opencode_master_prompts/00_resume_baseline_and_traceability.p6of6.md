<!-- Part 6 of 6 of 00_resume_baseline_and_traceability.md — read in order; see 00_resume_baseline_and_traceability.SPLIT_INDEX.md -->
### `REG-SYNC` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: REG-SYNC Replay, ordering, conflicts, pairing, revocation TD-008
- **Verification task:** V-REG-SYNC: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html


### `REG-UX` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: REG-UX Quick Bill, voucher, localization, accessibility TD-001/002
- **Verification task:** V-REG-UX: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html


### `RTM-O01` — Active implementation

- **Implementation task:** Trace this exact user/acceptance/release/RTM row to the owning implementation without changing its scope. If the row is deferred or gated, record that boundary instead of implementing it. Source: RTM-O01 — Exact user-story granularity for all 75 FRs — Generate one row per FR before baseline 1.0.
- **Verification task:** V-RTM-O01: inspect the exact traceability row, link it to the implementation and evidence, and classify PASS, BLOCKED, DEFERRED or EXCLUDED without inventing acceptance criteria.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `RTM-O02` — Active implementation

- **Implementation task:** Trace this exact user/acceptance/release/RTM row to the owning implementation without changing its scope. If the row is deferred or gated, record that boundary instead of implementing it. Source: RTM-O02 — Exact statutory schemas — Populate only after verification of supported schemas/response contracts.
- **Verification task:** V-RTM-O02: inspect the exact traceability row, link it to the implementation and evidence, and classify PASS, BLOCKED, DEFERRED or EXCLUDED without inventing acceptance criteria.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `RTM-O03` — Active implementation

- **Implementation task:** Trace this exact user/acceptance/release/RTM row to the owning implementation without changing its scope. If the row is deferred or gated, record that boundary instead of implementing it. Source: RTM-O03 — Exact valuation behavior — Populate after inventory valuation decision.
- **Verification task:** V-RTM-O03: inspect the exact traceability row, link it to the implementation and evidence, and classify PASS, BLOCKED, DEFERRED or EXCLUDED without inventing acceptance criteria.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `RTM-O04` — Active implementation

- **Implementation task:** Trace this exact user/acceptance/release/RTM row to the owning implementation without changing its scope. If the row is deferred or gated, record that boundary instead of implementing it. Source: RTM-O04 — Edition/licence boundaries — Populate after entitlement matrix is frozen.
- **Verification task:** V-RTM-O04: inspect the exact traceability row, link it to the implementation and evidence, and classify PASS, BLOCKED, DEFERRED or EXCLUDED without inventing acceptance criteria.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html
