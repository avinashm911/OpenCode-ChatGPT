<!-- Part 4 of 5 of 13_final_verification_and_gate_report.md — read in order; see 13_final_verification_and_gate_report.SPLIT_INDEX.md -->
### `TD-PERF-01` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by TD-PERF-01. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: D-09 / O-03 / O-M03 — 10-second bill benchmark — From New Bill to Pay & Finish (cash): <=10 s and <=10 touch interactions; scripted harness + 3 volunteer timings; fixture TD-PERF-01 (5,000 items, 500 parties, 20,000 vouchers) — Decided: proposed value — G2
- **Verification task:** V-TD-PERF-01: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html, NiAv_UX_Specification_v0.2.html


### `US-001` — Active implementation

- **Implementation task:** Trace this exact user/acceptance/release/RTM row to the owning implementation without changing its scope. If the row is deferred or gated, record that boundary instead of implementing it. Source: REG-M01 / FR-M01 — US-001 — As an owner, I can create/open a company with FY and configuration. — AC-001: valid company context is required before transactions. — TC-M01-001, TC-M01-002
- **Verification task:** V-US-001: inspect the exact traceability row, link it to the implementation and evidence, and classify PASS, BLOCKED, DEFERRED or EXCLUDED without inventing acceptance criteria.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `US-002` — Active implementation

- **Implementation task:** Trace this exact user/acceptance/release/RTM row to the owning implementation without changing its scope. If the row is deferred or gated, record that boundary instead of implementing it. Source: REG-M02 / FR-M02 — US-002 — As a shopkeeper, I can use the configured language/native script. — AC-002: labels, entry and errors use selected locale where supported. — TC-M02-001, TC-M02-002
- **Verification task:** V-US-002: inspect the exact traceability row, link it to the implementation and evidence, and classify PASS, BLOCKED, DEFERRED or EXCLUDED without inventing acceptance criteria.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `US-003` — Active implementation

- **Implementation task:** Trace this exact user/acceptance/release/RTM row to the owning implementation without changing its scope. If the row is deferred or gated, record that boundary instead of implementing it. Source: REG-M03 / FR-M03 — US-003 — As a user, I can create and maintain accounting/inventory masters. — AC-003: duplicate/invalid master data is blocked with actionable errors. — TC-M03-001…008
- **Verification task:** V-US-003: inspect the exact traceability row, link it to the implementation and evidence, and classify PASS, BLOCKED, DEFERRED or EXCLUDED without inventing acceptance criteria.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `US-004` — Active implementation

- **Implementation task:** Trace this exact user/acceptance/release/RTM row to the owning implementation without changing its scope. If the row is deferred or gated, record that boundary instead of implementing it. Source: REG-M04 / FR-M04 — US-004 — As a user, I can configure voucher types and numbering series. — AC-004: numbering is unique within its defined scope and respects series ownership. — TC-M04-001…004
- **Verification task:** V-US-004: inspect the exact traceability row, link it to the implementation and evidence, and classify PASS, BLOCKED, DEFERRED or EXCLUDED without inventing acceptance criteria.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `US-005` — Active implementation

- **Implementation task:** Trace this exact user/acceptance/release/RTM row to the owning implementation without changing its scope. If the row is deferred or gated, record that boundary instead of implementing it. Source: REG-M05–M07 / FR-M05–M07 — US-005 — As a user, I can enter, validate and post accounting/inventory vouchers. — AC-005: only valid state transitions can create authoritative posting effects. — TC-VCH-001…020
- **Verification task:** V-US-005: inspect the exact traceability row, link it to the implementation and evidence, and classify PASS, BLOCKED, DEFERRED or EXCLUDED without inventing acceptance criteria.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `US-006` — Active implementation

- **Implementation task:** Trace this exact user/acceptance/release/RTM row to the owning implementation without changing its scope. If the row is deferred or gated, record that boundary instead of implementing it. Source: REG-M08–M09 / FR-M08–M09 — US-006 — As a user, I can create commercial documents and convert them with lineage. — AC-006: source/target links and quantities are retained. — TC-DOC-001…006
- **Verification task:** V-US-006: inspect the exact traceability row, link it to the implementation and evidence, and classify PASS, BLOCKED, DEFERRED or EXCLUDED without inventing acceptance criteria.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `US-007` — Active implementation

- **Implementation task:** Trace this exact user/acceptance/release/RTM row to the owning implementation without changing its scope. If the row is deferred or gated, record that boundary instead of implementing it. Source: REG-M10 / FR-M10 — US-007 — As an approver, I can review and act on pending documents. — AC-007: unauthorized or invalid transitions are rejected and audited. — TC-APR-001…006
- **Verification task:** V-US-007: inspect the exact traceability row, link it to the implementation and evidence, and classify PASS, BLOCKED, DEFERRED or EXCLUDED without inventing acceptance criteria.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `US-008` — Active implementation

- **Implementation task:** Trace this exact user/acceptance/release/RTM row to the owning implementation without changing its scope. If the row is deferred or gated, record that boundary instead of implementing it. Source: REG-M11 / FR-M11 — US-008 — As a counter user, I can create a fast bill, hold it and finalize it. — AC-008: core bill flow works offline with preserved totals. — TC-QB-001…010
- **Verification task:** V-US-008: inspect the exact traceability row, link it to the implementation and evidence, and classify PASS, BLOCKED, DEFERRED or EXCLUDED without inventing acceptance criteria.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `US-009` — Active implementation

- **Implementation task:** Trace this exact user/acceptance/release/RTM row to the owning implementation without changing its scope. If the row is deferred or gated, record that boundary instead of implementing it. Source: REG-M12–M13 / FR-M12–M13 — US-009 — As a user, I can search and manage stock/counts. — AC-009: search returns scoped records and stock policy is enforced. — TC-SRCH-001…006
- **Verification task:** V-US-009: inspect the exact traceability row, link it to the implementation and evidence, and classify PASS, BLOCKED, DEFERRED or EXCLUDED without inventing acceptance criteria.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `US-010` — Active implementation

- **Implementation task:** Trace this exact user/acceptance/release/RTM row to the owning implementation without changing its scope. If the row is deferred or gated, record that boundary instead of implementing it. Source: REG-M14–M16 / FR-M14–M16 — US-010 — As an accountant, I can run reports, reconcile bank files and prepare statutory files. — AC-010: imported statements/files are validated and reconciled before commit/use. — TC-RPT-001…012
- **Verification task:** V-US-010: inspect the exact traceability row, link it to the implementation and evidence, and classify PASS, BLOCKED, DEFERRED or EXCLUDED without inventing acceptance criteria.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `US-011` — Active implementation

- **Implementation task:** Trace this exact user/acceptance/release/RTM row to the owning implementation without changing its scope. If the row is deferred or gated, record that boundary instead of implementing it. Source: REG-M17 / FR-M17 — US-011 — As a migrating user, I can import data with mapping, preview and reconciliation. — AC-011: invalid batches do not silently partially commit. — TC-MIG-001…012
- **Verification task:** V-US-011: inspect the exact traceability row, link it to the implementation and evidence, and classify PASS, BLOCKED, DEFERRED or EXCLUDED without inventing acceptance criteria.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `US-012` — Active implementation

- **Implementation task:** Trace this exact user/acceptance/release/RTM row to the owning implementation without changing its scope. If the row is deferred or gated, record that boundary instead of implementing it. Source: REG-M18–M20 / FR-M18–M20 — US-012 — As an admin, I can manage users, devices, audit and licence state. — AC-012: rights, entitlement and audit boundaries are enforced in the domain layer. — TC-ADM-001…010
- **Verification task:** V-US-012: inspect the exact traceability row, link it to the implementation and evidence, and classify PASS, BLOCKED, DEFERRED or EXCLUDED without inventing acceptance criteria.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `US-013` — Active implementation

- **Implementation task:** Trace this exact user/acceptance/release/RTM row to the owning implementation without changing its scope. If the row is deferred or gated, record that boundary instead of implementing it. Source: REG-M21–M24 / FR-M21–M24 — US-013 — As a user, I can print/share, back up/sync, customize and get help. — AC-013: output, backup and sync operations are explicit and recoverable. — TC-OPS-001…014
- **Verification task:** V-US-013: inspect the exact traceability row, link it to the implementation and evidence, and classify PASS, BLOCKED, DEFERRED or EXCLUDED without inventing acceptance criteria.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `V-FG-001` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: V-FG-001 SQLCipher/Drift Android 8+ Documentary source attached; Android 8 smoke test pending
- **Verification task:** V-V-FG-001: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Data_Schema_Specification_v0.1.html, NiAv_Database_Schema_Document_v0.1.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Release_and_Support_Playbook_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html, NiAv_UX_Specification_v0.2.html


### `V-FG-002` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: V-FG-002 Representative Tally/Busy native files and supported versions REG / ZCP Superseded by workbook reconciliation: Resolved Licensed-version sample files Superseded by workbook reconciliation: Resolved
- **Verification task:** V-V-FG-002: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html


### `V-FG-003` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: V-FG-003 GST/e-invoice/e-way schemas Official e-way API/schema sources attached; adapter test pending
- **Verification task:** V-V-FG-003: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Release_and_Support_Playbook_v0.1.html, NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html


### `W-01` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by W-01. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: W-01 · File-first integration — An external system exposes a usable file workflow but API automation is unavailable/out of ₹0 scope. — Local validation → versioned export → user submission → response import → reconciliation.
- **Verification task:** V-W-01: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html


### `W-02` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by W-02. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: W-02 · Adapter boundary — External formats vary by provider/version. — Convert into a stable NiAv intermediate model; keep provider/version logic outside the domain engine.
- **Verification task:** V-W-02: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html


### `W-03` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by W-03. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: W-03 · Human-mediated transport — WhatsApp/email/USB/file-provider can move a file. — Encrypt/sign where appropriate; record batch/hash; user initiates transfer; never infer delivery from share-sheet invocation.
- **Verification task:** V-W-03: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html


### `W-04` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by W-04. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: W-04 · Transactional import — External files can change accounting/inventory data. — Quarantine → parse → validate → preview → commit in one transaction → audit batch; rollback on failure.
- **Verification task:** V-W-04: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html


### `W-05` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by W-05. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: W-05 · Universal fallback — Native/official format is unsupported or changes. — Keep Excel/CSV/manual mapping as a documented fallback instead of blocking the workflow.
- **Verification task:** V-W-05: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html


### `W-06` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by W-06. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: W-06 · Deferred automation layer — Direct API is useful but not required for the business process. — Stable internal interface now; API adapter later without changing accounting logic.
- **Verification task:** V-W-06: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html


### `WP-00` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by WP-00. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: WP-00 — Foundation: repo, tooling, l10n skeleton, DB skeleton, release script — R1a — 8 — 12 — 10.0 — 10.0 — 3
- **Verification task:** V-WP-00: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_ Universal Master Plan v0.2.html


### `WP-01` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by WP-01. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: WP-01 — Masters + voucher, numbering, posting and stock engines (incl. op-log write path) — R1a — 20 — 30 — 25.0 — 35.0 — 9
- **Verification task:** V-WP-01: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_ Universal Master Plan v0.2.html

