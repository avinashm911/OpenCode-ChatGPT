# NiAvERP OpenCode master prompt v1.1 — inventory accounting and reports

## Mandatory first actions

1. Read the project-root `AGENTS.md`.
2. Read the project-root `DECISIONS.md`.
3. Read `../GLOBAL_NO_INVENTION_CONTRACT.md`.
4. Read `../BASELINE_AND_MIGRATION_MAP.md`, `../SOURCE_INVENTORY.md`, the relevant slice of `../TRACEABILITY_MATRIX.md`, `../STATUS_LEDGER.md`, `../SOURCE_CLARIFICATIONS.md`, `../g0/PENDING_INPUTS.md`, the relevant living HTML rows and the previous phase report.
5. If either governance file is missing or unreadable, stop with `BLOCKED`.

The existing source and phase reports are part of the working baseline. Do not rebuild completed phases. Verify them, repair only evidence-backed gaps, and continue from the stated next gate.

Never invent fields, posting/tax rules, legal conclusions, package/licence choices, APIs, permissions, workflow states, schemas, performance targets or release channels. Do not edit the 15 HTML documents, workbooks or registers. Preserve standalone/offline-first V1 and all exclusions.

## Required result

Implement only the owned IDs below and only for their permitted priority/gate. For every ID, report its disposition exactly as `implemented`, `boundary`, `deferred`, `blocked` or `excluded`. Add code/tests only for permitted work. End with changed files, commands/results, test results, ID traceability, unresolved questions and the next gate.

## Owned IDs (14)

- `D-M5`
- `FG-013`
- `FR-M13-001`
- `FR-M13-002`
- `FR-M14-001`
- `FR-M14-002`
- `FR-M14-003`
- `G0-SCH-001`
- `G0-SCH-002`
- `M13`
- `M14`
- `M15`
- `OD-DB-002`
- `OD-FD-001`

### `D-M5` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: D-M5 / D-08 / D-FG-013 / O-09 / OD-004 / OD-FD-001 — Valuation policy — (1) Methods: Weighted Average and FIFO only. (2) Item overrides group; default Weighted Average. (3) Method locked after first posted stock movement; no change in V1. (4) Negative stock allowed with warning; no-layer issues costed at last known cost; no retro revaluation in V1. (5) Period lock by date; unlock needs right + reason + audit. (6) Orders never reserve stock (D-M6 = No). (7) Golden ledgers: opening, purchase, sale, returns, adjustment, negative-stock sale, lock/unlock — Decided: proposed value — G1
- **Verification task:** V-D-M5: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Data_Schema_Specification_v0.1.html, NiAv_Database_Schema_Document_v0.1.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html, NiAv_UX_Specification_v0.2.html


### `FG-013` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: FG-013 — Accounting/inventory valuation detail — NIAV-MPL open items; NIAV-REG M13/M14 — Partial — Core accounting/inventory scope is broad, but valuation methods and some acceptance details remain open. — Different valuation methods change stock and profit results.
- **Verification task:** V-FG-013: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Data_Schema_Specification_v0.1.html, NiAv_Database_Schema_Document_v0.1.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html


### `FR-M13-001` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Policy: allow/warn/block. State: Configured. Validation: Policy must be explicit before stock posting.. Interaction: Configuration.. Downstream: Stock validation.. Source requirement: Inventory control input shall capture negative-stock policy and use it consistently during stock-affecting entry.
- **Verification task:** V-FR-M13-001: test required data/input (Policy: allow/warn/block), state (Configured), validation (Policy must be explicit before stock posting.), interaction (Configuration.) and downstream effect (Stock validation.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M13-002` — Deferred by priority P2

- **Implementation task:** Do not implement this item in the current release. Record priority P2 and gate not stated, and keep it out of active acceptance criteria. Source: Physical-stock count input shall capture counted quantity and variance for stock-journal posting.
- **Verification task:** V-FR-M13-002: priority/gate ledger confirms deferred status (P2, not stated); no active V1 acceptance test is allowed.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M14-001` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Bill reference; due date; amount; allocation. State: Open → Settled/Part-settled. Validation: Allocation cannot exceed open balance.. Interaction: Picker/grid inside receipt/payment.. Downstream: Outstanding reports.. Source requirement: Outstanding input/allocation shall support bill-wise receivable/payable references and due dates where enabled.
- **Verification task:** V-FR-M14-001: test required data/input (Bill reference; due date; amount; allocation), state (Open → Settled/Part-settled), validation (Allocation cannot exceed open balance.), interaction (Picker/grid inside receipt/payment.) and downstream effect (Outstanding reports.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M14-002` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: read the source row. State: read the source row. Validation: read the source row. Interaction: read the source row. Downstream: read the source row. Source requirement: BRS
- **Verification task:** V-FR-M14-002: test required data/input (source row), state (source row), validation (source row), interaction (source row) and downstream effect (source row); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Database_Schema_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M14-003` — Deferred by priority P2

- **Implementation task:** Do not implement this item in the current release. Record priority P2 and gate not stated, and keep it out of active acceptance criteria. Source: Payment reminder preparation shall generate reminder text and/or statement artifacts for user-mediated sharing.
- **Verification task:** V-FR-M14-003: priority/gate ledger confirms deferred status (P2, not stated); no active V1 acceptance test is allowed.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `G0-SCH-001` — Active schema change

- **Implementation task:** Implement the approved schema change exactly, including migration, compatibility, rollback and tests. Source: G0-SCH-001 — Schema design gap — D-M5 / D-08 / OD-DB-002 — Approved design change — implementation required — Approved: Add cost-layer and stock-movement structures plus negative-stock costing/reconciliation rules. — G1
- **Verification task:** V-G0-SCH-001: migration applies on a clean and existing database, preserves data, supports compatibility checks and has rollback evidence.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Data_Schema_Specification_v0.1.html, NiAv_Database_Schema_Document_v0.1.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html


### `G0-SCH-002` — Active schema change

- **Implementation task:** Implement the approved schema change exactly, including migration, compatibility, rollback and tests. Source: G0-SCH-002 — Schema design gap — D-M5 — Approved design change — implementation required — Approved: Add period-lock entity, rights, unlock reason and audit linkage. — G1
- **Verification task:** V-G0-SCH-002: migration applies on a clean and existing database, preserves data, supports compatibility checks and has rollback evidence.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Data_Schema_Specification_v0.1.html, NiAv_Database_Schema_Document_v0.1.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html, NiAv_UX_Specification_v0.2.html


### `M13` — Active P1; deferred P2

- **Implementation task:** Implement only the P1 sub-modules of M13 in the current release. Enumerate every P2/P3/TBC sub-module from the Modules Register as deferred or blocked with its gate; do not silently omit or implement them. Module priority: P1/P2. Gate: not stated. Source: M13 — Inventory Management (stock features) — P1/P2
- **Verification task:** V-M13: module acceptance test covers each registered sub-module, persistence/restart and integration with its dependent module.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html


### `M14` — Active implementation

- **Implementation task:** Implement only the P1 sub-modules of M14 in the current release. Enumerate every P2/P3/TBC sub-module from the Modules Register as deferred or blocked with its gate; do not silently omit or implement them. Module priority: P1. Gate: not stated. Source: M14 — Accounting Books & Financial Reports — P1
- **Verification task:** V-M14: module acceptance test covers each registered sub-module, persistence/restart and integration with its dependent module.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html


### `M15` — Active implementation

- **Implementation task:** Implement only the P1 sub-modules of M15 in the current release. Enumerate every P2/P3/TBC sub-module from the Modules Register as deferred or blocked with its gate; do not silently omit or implement them. Module priority: P1. Gate: not stated. Source: M15 — Inventory Reports — P1
- **Verification task:** V-M15: module acceptance test covers each registered sub-module, persistence/restart and integration with its dependent module.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html


### `OD-DB-002` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: OD-DB-002 — Valuation — Freeze authoritative stock valuation columns and calculation method. — FR-M07-003
- **Verification task:** V-OD-DB-002: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Data_Schema_Specification_v0.1.html, NiAv_Database_Schema_Document_v0.1.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html


### `OD-FD-001` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: D-M5 / D-08 / D-FG-013 / O-09 / OD-004 / OD-FD-001 — Valuation policy — (1) Methods: Weighted Average and FIFO only. (2) Item overrides group; default Weighted Average. (3) Method locked after first posted stock movement; no change in V1. (4) Negative stock allowed with warning; no-layer issues costed at last known cost; no retro revaluation in V1. (5) Period lock by date; unlock needs right + reason + audit. (6) Orders never reserve stock (D-M6 = No). (7) Golden ledgers: opening, purchase, sale, returns, adjustment, negative-stock sale, lock/unlock — Decided: proposed value — G1
- **Verification task:** V-OD-FD-001: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Data_Schema_Specification_v0.1.html, NiAv_Database_Schema_Document_v0.1.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html
