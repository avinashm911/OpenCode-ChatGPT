<!-- Part 2 of 6 of 00_resume_baseline_and_traceability.md — read in order; see 00_resume_baseline_and_traceability.SPLIT_INDEX.md -->
### `D-M3` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: D-M2 / D-M3 / O-M05 — Release train — R1a (Simple, single device) then R1b (Advanced, multi-device); if S2/S3 slip, R1b ships with file merge, LAN sync as R1b.1 — Decided: proposed value — G6
- **Verification task:** V-D-M3: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html


### `D-M6` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: D-M6 — Whether orders reserve stock — Superseded by workbook reconciliation: Resolved
- **Verification task:** V-D-M6: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Data_Schema_Specification_v0.1.html, NiAv_Database_Schema_Document_v0.1.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html


### `D-M7` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: D-M7 — Code layering rule: domain core independent of Flutter/DB — Decided (architecture principle)
- **Verification task:** V-D-M7: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Universal Master Plan v0.2.html


### `DSS-O03` — Active implementation

- **Implementation task:** Apply this exact data/schema control to the local backend design and migration only where the source row authorizes it. Preserve existing migrations and stop on missing SQLCipher/licence decisions. Source: DSS-O03 Detailed statutory/GST fields and response artifacts Verify before final physical schema
- **Verification task:** V-DSS-O03: verify the exact schema/control row against migrations, repository behavior and persistence tests; report missing encryption or licence evidence as BLOCKED.
- **Source references:** NiAv_Data_Schema_Specification_v0.1.html


### `DSS-O04` — Active implementation

- **Implementation task:** Apply this exact data/schema control to the local backend design and migration only where the source row authorizes it. Preserve existing migrations and stop on missing SQLCipher/licence decisions. Source: DSS-O04 Audit old/new payload representation Owner/security decision
- **Verification task:** V-DSS-O04: verify the exact schema/control row against migrations, repository behavior and persistence tests; report missing encryption or licence evidence as BLOCKED.
- **Source references:** NiAv_Data_Schema_Specification_v0.1.html


### `DSS-O05` — Active implementation

- **Implementation task:** Apply this exact data/schema control to the local backend design and migration only where the source row authorizes it. Preserve existing migrations and stop on missing SQLCipher/licence decisions. Source: DSS-O05 Attachment encrypted container/provider semantics Security/Android verification
- **Verification task:** V-DSS-O05: verify the exact schema/control row against migrations, repository behavior and persistence tests; report missing encryption or licence evidence as BLOCKED.
- **Source references:** NiAv_Data_Schema_Specification_v0.1.html


### `FR-M01` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: AC-001: valid company context is required before transactions.. State: TC-M01-001, TC-M01-002. Validation: read the source row. Interaction: read the source row. Downstream: read the source row. Source requirement: As an owner, I can create/open a company with FY and configuration.
- **Verification task:** V-FR-M01: test required data/input (AC-001: valid company context is required before transactions.), state (TC-M01-001, TC-M01-002), validation (source row), interaction (source row) and downstream effect (source row); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `FR-M02` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: AC-002: labels, entry and errors use selected locale where supported.. State: TC-M02-001, TC-M02-002. Validation: read the source row. Interaction: read the source row. Downstream: read the source row. Source requirement: As a shopkeeper, I can use the configured language/native script.
- **Verification task:** V-FR-M02: test required data/input (AC-002: labels, entry and errors use selected locale where supported.), state (TC-M02-001, TC-M02-002), validation (source row), interaction (source row) and downstream effect (source row); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `FR-M03` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: read the source row. State: read the source row. Validation: read the source row. Interaction: read the source row. Downstream: read the source row. Source requirement: groups, ledger, party, bank, item, unit, godown, batch, price
- **Verification task:** V-FR-M03: test required data/input (source row), state (source row), validation (source row), interaction (source row) and downstream effect (source row); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Data_Schema_Specification_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html


### `FR-M04` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: read the source row. State: read the source row. Validation: read the source row. Interaction: read the source row. Downstream: read the source row. Source requirement: voucher type/series/voucher/line/document_link
- **Verification task:** V-FR-M04: test required data/input (source row), state (source row), validation (source row), interaction (source row) and downstream effect (source row); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Data_Schema_Specification_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_UX_Specification_v0.2.html


### `FR-M05` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: read the source row. State: read the source row. Validation: read the source row. Interaction: read the source row. Downstream: read the source row. Source requirement: Transactional rows/lineage
- **Verification task:** V-FR-M05: test required data/input (source row), state (source row), validation (source row), interaction (source row) and downstream effect (source row); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Database_Schema_Document_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html


### `FR-M06` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Approved design change — implementation required. State: Approved: Add bill_allocation and settlement lineage fields and tests.. Validation: G1. Interaction: . Downstream: read the source row. Source requirement: FR-M06
- **Verification task:** V-FR-M06: test required data/input (Approved design change — implementation required), state (Approved: Add bill_allocation and settlement lineage fields and tests.), validation (G1), interaction () and downstream effect (source row); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Data_Schema_Specification_v0.1.html, NiAv_Database_Schema_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html


### `FR-M08` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: AC-006: source/target links and quantities are retained.. State: TC-DOC-001…006. Validation: read the source row. Interaction: read the source row. Downstream: read the source row. Source requirement: As a user, I can create commercial documents and convert them with lineage.
- **Verification task:** V-FR-M08: test required data/input (AC-006: source/target links and quantities are retained.), state (TC-DOC-001…006), validation (source row), interaction (source row) and downstream effect (source row); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `FR-M10` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: read the source row. State: read the source row. Validation: read the source row. Interaction: read the source row. Downstream: read the source row. Source requirement: approval_rule/approval_instance
- **Verification task:** V-FR-M10: test required data/input (source row), state (source row), validation (source row), interaction (source row) and downstream effect (source row); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Data_Schema_Specification_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_UX_Specification_v0.2.html


### `FR-M11` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: AC-008: core bill flow works offline with preserved totals.. State: TC-QB-001…010. Validation: read the source row. Interaction: read the source row. Downstream: read the source row. Source requirement: As a counter user, I can create a fast bill, hold it and finalize it.
- **Verification task:** V-FR-M11: test required data/input (AC-008: core bill flow works offline with preserved totals.), state (TC-QB-001…010), validation (source row), interaction (source row) and downstream effect (source row); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `FR-M12` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: AC-009: search returns scoped records and stock policy is enforced.. State: TC-SRCH-001…006. Validation: read the source row. Interaction: read the source row. Downstream: read the source row. Source requirement: As a user, I can search and manage stock/counts.
- **Verification task:** V-FR-M12: test required data/input (AC-009: search returns scoped records and stock policy is enforced.), state (TC-SRCH-001…006), validation (source row), interaction (source row) and downstream effect (source row); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `FR-M14` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: read the source row. State: read the source row. Validation: read the source row. Interaction: read the source row. Downstream: read the source row. Source requirement: bank statement + outstanding derived data
- **Verification task:** V-FR-M14: test required data/input (source row), state (source row), validation (source row), interaction (source row) and downstream effect (source row); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Data_Schema_Specification_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html


### `FR-M16` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: FR-M16. State: read the source row. Validation: read the source row. Interaction: read the source row. Downstream: read the source row. Source requirement: Freeze detailed GST/statutory fields after current schema verification.
- **Verification task:** V-FR-M16: test required data/input (FR-M16), state (source row), validation (source row), interaction (source row) and downstream effect (source row); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Database_Schema_Document_v0.1.html, NiAv_Functional_Design_Document_v0.1.html


### `FR-M17` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: read the source row. State: read the source row. Validation: read the source row. Interaction: read the source row. Downstream: read the source row. Source requirement: import batch/error/reconciliation evidence
- **Verification task:** V-FR-M17: test required data/input (source row), state (source row), validation (source row), interaction (source row) and downstream effect (source row); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Data_Schema_Specification_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_UX_Specification_v0.2.html


### `FR-M18` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: read the source row. State: read the source row. Validation: read the source row. Interaction: read the source row. Downstream: read the source row. Source requirement: audit, user/role/device/licence
- **Verification task:** V-FR-M18: test required data/input (source row), state (source row), validation (source row), interaction (source row) and downstream effect (source row); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Data_Schema_Specification_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html


### `FR-M21` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: AC-013: output, backup and sync operations are explicit and recoverable.. State: TC-OPS-001…014. Validation: read the source row. Interaction: read the source row. Downstream: read the source row. Source requirement: As a user, I can print/share, back up/sync, customize and get help.
- **Verification task:** V-FR-M21: test required data/input (AC-013: output, backup and sync operations are explicit and recoverable.), state (TC-OPS-001…014), validation (source row), interaction (source row) and downstream effect (source row); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `FR-M22` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: read the source row. State: read the source row. Validation: read the source row. Interaction: read the source row. Downstream: read the source row. Source requirement: backup manifest, operation, sync peer
- **Verification task:** V-FR-M22: test required data/input (source row), state (source row), validation (source row), interaction (source row) and downstream effect (source row); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Data_Schema_Specification_v0.1.html, NiAv_UX_Specification_v0.2.html


### `G0-CON-001` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: G0-CON-001 — Body contradiction — O-FG-007 / O-FG-008 — Decided — Make V1 text authoritative: TDS/TCS later release; PF/ESI/payroll out of scope. — G0
- **Verification task:** V-G0-CON-001: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Release_and_Support_Playbook_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_Sync_Protocol_Specification_v0.1.html


### `G0-CON-002` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: G0-CON-002 — Body contradiction — O-FG-006 / A-FG-006 — Decided — Replace V1 native-import promise with the Excel-template boundary. — G0
- **Verification task:** V-G0-CON-002: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html


### `G0-CON-003` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: G0-CON-003 — Body contradiction — RSP 5 / DSS-C-007 — Decided — Retain one authoritative rollback procedure and cross-link all references. — G5
- **Verification task:** V-G0-CON-003: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_Data_Schema_Specification_v0.1.html, NiAv_Release_and_Support_Playbook_v0.1.html, NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html

