# NiAvERP OpenCode master prompt v1.1 — import gst brs and statutory boundary

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

## Owned IDs (25)

- `A-FG-006`
- `FG-001`
- `FG-002`
- `FG-003`
- `FG-004`
- `FG-005`
- `FG-006`
- `FG-007`
- `FG-008`
- `FG-015`
- `FR-M16-001`
- `FR-M16-002`
- `FR-M16-003`
- `FR-M16-004`
- `FR-M17-001`
- `FR-M17-002`
- `FR-M17-003`
- `FR-M17-004`
- `FR-M17-005`
- `G0-SCH-004`
- `M16`
- `M17`
- `OD-DB-003`
- `OD-FD-002`
- `OD-FD-003`

### `A-FG-006` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: O-FG-006 / A-FG-006 / O-13 Tally/Busy native import V1/R2: Excel import with documented templates; native adapters = R3 feasibility; FG-006 marked Deferred Decided: proposed value G4 G0 Deferred — R3: Owner confirmed deferment: Confirm the R3 feasibility gate and evidence required. G0 Decided: Replace V1 native-import promise with the Excel-template boundary.
- **Verification task:** V-A-FG-006: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html


### `FG-001` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: FG-001 — Integration model — NIAV-ZCP §2A; NIAV-MPL §2 — Partial — Level 0–5 integration is defined, but there is no single acceptance rule for when a file workflow is sufficient versus when an API is required. — Scope drift; API-first assumptions can return.
- **Verification task:** V-FG-001: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FG-002` — Boundary / blocked until verified source

- **Implementation task:** Implement only the safe documented boundary and its validation/replay behavior. Keep the unresolved downstream behavior blocked. Source: FG-002 / 003 / 004 — Statutory schema verification — Verify GST/e-invoice/e-way schemas from official sources; record in verification logs — Decided: owner value — G1
- **Verification task:** V-FG-002: boundary test proves allowed local behavior, rejects unsupported behavior, and records the downstream gate.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Data_Schema_Specification_v0.1.html, NiAv_Database_Schema_Document_v0.1.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Release_and_Support_Playbook_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html, NiAv_UX_Specification_v0.2.html


### `FG-003` — Boundary / blocked until verified source

- **Implementation task:** Implement only the safe documented boundary and its validation/replay behavior. Keep the unresolved downstream behavior blocked. Source: FG-003 — E-way bill — NIAV-REG M16; NIAV-ZCP §11 — Partial — JSON preparation, user-mediated upload and result import are targeted; direct API is separate. — Bulk/consolidated and response variants may differ by workflow/version.
- **Verification task:** V-FG-003: boundary test proves allowed local behavior, rejects unsupported behavior, and records the downstream gate.
- **Source references:** NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html


### `FG-004` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: FG-004 — Government File Export Engine — NIAV-REG M16/M17; NIAV-ZCP §11 — Partial — GST exports and statutory file workflows are named, but a reusable engine for schema versioning, validation, response import and reconciliation is not fully specified. — Duplicate implementations and inconsistent error handling.
- **Verification task:** V-FG-004: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FG-005` — Active P1; deferred P2

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: FG-005 — Bank statement / BRS — NIAV-REG M14.8; NIAV-MPL R2 — Partial — Bank reconciliation is scoped, while statement import is not fully specified. — Missing input formats, matching rules, tolerances and exception workflow.
- **Verification task:** V-FG-005: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_Database_Schema_Document_v0.1.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html


### `FG-006` — Deferred

- **Implementation task:** Do not implement this item in the current release. Record priority P1/P2 and gate Verify, and keep it out of active acceptance criteria. Source: FG-006 — Tally/Busy native-file import — NIAV-REG M17.11; NIAV-ZCP M17 — Partial / Verify — Direct native import deferred to R3 feasibility; V1 Excel-template import is targeted only for validated formats and representative sample files. — Versions and native formats vary; supported coverage is undefined.
- **Verification task:** V-FG-006: priority/gate ledger confirms deferred status (P1/P2, Verify); no active V1 acceptance test is allowed.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_Database_Schema_Document_v0.1.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FG-007` — Deferred

- **Implementation task:** Do not implement this item in the current release. Record priority P2 and gate Verify, and keep it out of active acceptance criteria. Source: FG-007 — TDS/TCS statutory files — NIAV-REG M16; NIAV-ZCP M16 — Gap / Verify — TDS/TCS is deferred to a later release; no V1 implementation or file workflow is permitted. — Large statutory scope and high error cost.
- **Verification task:** V-FG-007: priority/gate ledger confirms deferred status (P2, Verify); no active V1 acceptance test is allowed.
- **Source references:** NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html


### `FG-008` — Excluded

- **Implementation task:** Do not implement this item. Add a negative test proving the excluded capability is not exposed. Preserve the source decision: FG-008 — PF/ESI statutory files — NIAV-REG M16; NIAV-ZCP M16 — Out of scope — PF/ESI and payroll are out of scope for V1; full payroll remains out of scope. — Prerequisite employee/payroll data model is undefined.
- **Verification task:** V-FG-008: static scan plus negative UI/domain test confirms the excluded feature is absent.
- **Source references:** NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html


### `FG-015` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: FG-015 — Security of imported/exported files — NIAV-SEC §4–§8; NIAV-ZCP file-first workflows — Partial — Security covers malicious imports, backups and sync peers, but file-first workflows add more untrusted-input boundaries. — Generic import controls may miss adapter-specific attacks.
- **Verification task:** V-FG-015: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_Database_Schema_Document_v0.1.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html


### `FR-M16-001` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: GSTIN; registration type; state; HSN/SAC; rate; classification. State: Configured. Validation: Current statutory rules and exact registration choices must be verified.. Interaction: GST setup/master forms.. Downstream: GST calculation/reporting.. Source requirement: GST setup shall capture GSTIN, registration type, state, HSN/SAC and tax rates applicable to the company/items.
- **Verification task:** V-FR-M16-001: test required data/input (GSTIN; registration type; state; HSN/SAC; rate; classification), state (Configured), validation (Current statutory rules and exact registration choices must be verified.), interaction (GST setup/master forms.) and downstream effect (GST calculation/reporting.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M16-002` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Place of supply; tax category; RCM flag; exemption/nil/non-GST; tax lines. State: Draft → Validated → Posted. Validation: Current official GST rules are VERIFY; calculation must be deterministic.. Interaction: Conditional tax section on voucher.. Downstream: GST totals and reports.. Source requirement: GST voucher input shall capture or derive place of supply, tax treatment, reverse charge and exempt/nil/non-GST classification where applicable.
- **Verification task:** V-FR-M16-002: test required data/input (Place of supply; tax category; RCM flag; exemption/nil/non-GST; tax lines), state (Draft → Validated → Posted), validation (Current official GST rules are VERIFY; calculation must be deterministic.), interaction (Conditional tax section on voucher.) and downstream effect (GST totals and reports.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M16-003` — Boundary / blocked until verified source

- **Implementation task:** Implement only the safe documented boundary and its validation/replay behavior. Keep the unresolved downstream behavior blocked. Source: GST return/export preparation shall produce the locally generated file/data required by the supported workflow, with schema version recorded.
- **Verification task:** V-FR-M16-003: boundary test proves allowed local behavior, rejects unsupported behavior, and records the downstream gate.
- **Source references:** NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M16-004` — Boundary / blocked until verified source

- **Implementation task:** Implement only the safe documented boundary and its validation/replay behavior. Keep the unresolved downstream behavior blocked. Source: E-invoice/e-way input adapters shall prepare locally validated payload data and support user-mediated submission and response/result import when the verified format is available.
- **Verification task:** V-FR-M16-004: boundary test proves allowed local behavior, rejects unsupported behavior, and records the downstream gate.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M17-001` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: File; template version; sheet; rows. State: Selected → Validated → Previewed → Imported. Validation: Template version must match adapter; mandatory/duplicate/unknown references checked.. Interaction: File picker → mapping/validation → preview → commit.. Downstream: Creates/updates domain data in a batch.. Source requirement: Import shall accept versioned NiAv Excel templates for masters, opening balances and transaction data.
- **Verification task:** V-FR-M17-001: test required data/input (File; template version; sheet; rows), state (Selected → Validated → Previewed → Imported), validation (Template version must match adapter; mandatory/duplicate/unknown references checked.), interaction (File picker → mapping/validation → preview → commit.) and downstream effect (Creates/updates domain data in a batch.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Database_Schema_Document_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M17-002` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Ledger; Dr/Cr; bill refs; item; qty; rate; value; godown; batch. State: Import batch. Validation: Dr/Cr consistency and stock valuation rules must be satisfied.. Interaction: Template import + preview.. Downstream: Opening balances and reconciliation.. Source requirement: Opening-balance import shall capture ledger Dr/Cr balances, bill-wise outstanding and item opening stock by quantity/rate/value and location/batch where applicable.
- **Verification task:** V-FR-M17-002: test required data/input (Ledger; Dr/Cr; bill refs; item; qty; rate; value; godown; batch), state (Import batch), validation (Dr/Cr consistency and stock valuation rules must be satisfied.), interaction (Template import + preview.) and downstream effect (Opening balances and reconciliation.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M17-003` — Boundary

- **Implementation task:** Implement only the safe documented boundary and its validation/replay behavior. Keep the unresolved downstream behavior blocked. Source: Excel-template mapping and reconciliation for V1; native adapters are R3 feasibility only.
- **Verification task:** V-FR-M17-003: boundary test proves allowed local behavior, rejects unsupported behavior, and records the downstream gate.
- **Source references:** NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M17-004` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Mode; batch ID; row result; error code; rollback action. State: Validated → Preview → Commit/Rollback. Validation: No partial commit unless user explicitly selects partial-accept and the source specifies it.. Interaction: Preview/error grid; commit button.. Downstream: Controlled migration.. Source requirement: Import shall provide dry-run preview, row-level error report, configurable create/update/skip-duplicate modes, and batch-level rollback where implemented.
- **Verification task:** V-FR-M17-004: test required data/input (Mode; batch ID; row result; error code; rollback action), state (Validated → Preview → Commit/Rollback), validation (No partial commit unless user explicitly selects partial-accept and the source specifies it.), interaction (Preview/error grid; commit button.) and downstream effect (Controlled migration.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M17-005` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Source totals; NiAv totals; variance; status. State: Pending → Reconciled/Exception. Validation: Tolerance rules TBD; exceptions must remain visible.. Interaction: Reconciliation screen/export.. Downstream: Migration sign-off.. Source requirement: Migration reconciliation shall compare post-import trial balance and stock totals against source totals.
- **Verification task:** V-FR-M17-005: test required data/input (Source totals; NiAv totals; variance; status), state (Pending → Reconciled/Exception), validation (Tolerance rules TBD; exceptions must remain visible.), interaction (Reconciliation screen/export.) and downstream effect (Migration sign-off.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `G0-SCH-004` — Active schema change

- **Implementation task:** Implement the approved schema change exactly, including migration, compatibility, rollback and tests. Source: G0-SCH-004 — Schema design gap — MPL 7.4 / profiles — Approved design change — implementation required — Approved: Add effective-dated tax/HSN and synced/backed-up layout-profile structures. — G1
- **Verification task:** V-G0-SCH-004: migration applies on a clean and existing database, preserves data, supports compatibility checks and has rollback evidence.
- **Source references:** NiAv_ Universal Master Plan v0.2.html, NiAv_Data_Schema_Specification_v0.1.html, NiAv_Database_Schema_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html, NiAv_UX_Specification_v0.2.html


### `M16` — Active P1; deferred P2

- **Implementation task:** Implement only the P1 sub-modules of M16 in the current release. Enumerate every P2/P3/TBC sub-module from the Modules Register as deferred or blocked with its gate; do not silently omit or implement them. Module priority: P1/P2. Gate: not stated. Source: M16 — GST & Statutory (India) — P1/P2
- **Verification task:** V-M16: module acceptance test covers each registered sub-module, persistence/restart and integration with its dependent module.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html


### `M17` — Active implementation

- **Implementation task:** Implement only the P1 sub-modules of M17 in the current release. Enumerate every P2/P3/TBC sub-module from the Modules Register as deferred or blocked with its gate; do not silently omit or implement them. Module priority: P1. Gate: not stated. Source: M17 — Data Import / Migration (Excel) [U4][U5] — P1
- **Verification task:** V-M17: module acceptance test covers each registered sub-module, persistence/restart and integration with its dependent module.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html


### `OD-DB-003` — Boundary / blocked until verified source

- **Implementation task:** Implement only the safe documented boundary and its validation/replay behavior. Keep the unresolved downstream behavior blocked. Source: OD-DB-003 — Detailed GST/statutory table fields — Effective-dated, data-driven rate/HSN tables; statutory fields after schema verification — Decided: owner value — G1
- **Verification task:** V-OD-DB-003: boundary test proves allowed local behavior, rejects unsupported behavior, and records the downstream gate.
- **Source references:** NiAv_Data_Schema_Specification_v0.1.html, NiAv_Database_Schema_Document_v0.1.html


### `OD-FD-002` — Boundary / blocked until verified source

- **Implementation task:** Implement only the safe documented boundary and its validation/replay behavior. Keep the unresolved downstream behavior blocked. Source: OD-FD-002 — Statutory adapters — Verify current schemas, applicability and response formats before adapter sign-off. — FR-M16-003/004
- **Verification task:** V-OD-FD-002: boundary test proves allowed local behavior, rejects unsupported behavior, and records the downstream gate.
- **Source references:** NiAv_Functional_Design_Document_v0.1.html


### `OD-FD-003` — Boundary

- **Implementation task:** Implement only the safe documented boundary and its validation/replay behavior. Keep the unresolved downstream behavior blocked. Source: OD-FD-003 — Tally/Busy — Verify representative native files, supported versions and extraction/mapping coverage. — FR-M17-003
- **Verification task:** V-OD-FD-003: boundary test proves allowed local behavior, rejects unsupported behavior, and records the downstream gate.
- **Source references:** NiAv_Functional_Design_Document_v0.1.html
