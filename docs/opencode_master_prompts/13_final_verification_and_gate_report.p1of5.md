<!-- Part 1 of 5 of 13_final_verification_and_gate_report.md — read in order; see 13_final_verification_and_gate_report.SPLIT_INDEX.md -->
# NiAvERP OpenCode master prompt v1.1 — final verification and gate report

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

## Final verification directive

Read the full verification catalog and the Test Plan identifiers. Verify implementation against existing phase reports and run only reproducible checks available in the environment. Do not convert host-only, legal, device, printer or delivery evidence into PASS.

## Owned IDs (117)

- `AC-001`
- `AC-002`
- `AC-003`
- `AC-004`
- `AC-005`
- `AC-006`
- `AC-007`
- `AC-008`
- `AC-009`
- `AC-010`
- `AC-011`
- `AC-012`
- `AC-013`
- `G0-VER-001`
- `G0-VER-002`
- `G0-VER-003`
- `G0-VER-005`
- `R-01`
- `R-02`
- `R-03`
- `R-04`
- `R-05`
- `R-06`
- `R-07`
- `R-08`
- `R-09`
- `R-10`
- `R-11`
- `R-12`
- `R-13`
- `R-14`
- `RLS-001`
- `RLS-002`
- `RLS-003`
- `RLS-004`
- `RLS-005`
- `RLS-006`
- `RLS-007`
- `RLS-008`
- `TC-ADM-001`
- `TC-APR`
- `TC-APR-001`
- `TC-COM-001`
- `TC-COM-002`
- `TC-COM-003`
- `TC-COM-004`
- `TC-COM-005`
- `TC-COM-006`
- `TC-COM-007`
- `TC-DOC-001`
- `TC-M01-001`
- `TC-M01-002`
- `TC-M02-001`
- `TC-M02-002`
- `TC-M03-001`
- `TC-M04-001`
- `TC-MIG`
- `TC-MIG-001`
- `TC-OPS-001`
- `TC-QB`
- `TC-QB-001`
- `TC-RPT-001`
- `TC-SRCH-001`
- `TC-SYNC`
- `TC-VCH`
- `TC-VCH-001`
- `TD-001`
- `TD-002`
- `TD-003`
- `TD-004`
- `TD-005`
- `TD-006`
- `TD-007`
- `TD-008`
- `TD-009`
- `TD-010`
- `TD-PERF-01`
- `US-001`
- `US-002`
- `US-003`
- `US-004`
- `US-005`
- `US-006`
- `US-007`
- `US-008`
- `US-009`
- `US-010`
- `US-011`
- `US-012`
- `US-013`
- `V-FG-001`
- `V-FG-002`
- `V-FG-003`
- `W-01`
- `W-02`
- `W-03`
- `W-04`
- `W-05`
- `W-06`
- `WP-00`
- `WP-01`
- `WP-02`
- `WP-03`
- `WP-04`
- `WP-05`
- `WP-06`
- `WP-07`
- `WP-08`
- `WP-09`
- `WP-10`
- `WP-11`
- `WP-12`
- `WP-13`
- `WP-14`
- `WP-15`
- `WP-16`
- `WP-17`

### `AC-001` — Active implementation

- **Implementation task:** Trace this exact user/acceptance/release/RTM row to the owning implementation without changing its scope. If the row is deferred or gated, record that boundary instead of implementing it. Source: REG-M01 / FR-M01 — US-001 — As an owner, I can create/open a company with FY and configuration. — AC-001: valid company context is required before transactions. — TC-M01-001, TC-M01-002
- **Verification task:** V-AC-001: inspect the exact traceability row, link it to the implementation and evidence, and classify PASS, BLOCKED, DEFERRED or EXCLUDED without inventing acceptance criteria.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `AC-002` — Active implementation

- **Implementation task:** Trace this exact user/acceptance/release/RTM row to the owning implementation without changing its scope. If the row is deferred or gated, record that boundary instead of implementing it. Source: REG-M02 / FR-M02 — US-002 — As a shopkeeper, I can use the configured language/native script. — AC-002: labels, entry and errors use selected locale where supported. — TC-M02-001, TC-M02-002
- **Verification task:** V-AC-002: inspect the exact traceability row, link it to the implementation and evidence, and classify PASS, BLOCKED, DEFERRED or EXCLUDED without inventing acceptance criteria.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `AC-003` — Active implementation

- **Implementation task:** Trace this exact user/acceptance/release/RTM row to the owning implementation without changing its scope. If the row is deferred or gated, record that boundary instead of implementing it. Source: REG-M03 / FR-M03 — US-003 — As a user, I can create and maintain accounting/inventory masters. — AC-003: duplicate/invalid master data is blocked with actionable errors. — TC-M03-001…008
- **Verification task:** V-AC-003: inspect the exact traceability row, link it to the implementation and evidence, and classify PASS, BLOCKED, DEFERRED or EXCLUDED without inventing acceptance criteria.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `AC-004` — Active implementation

- **Implementation task:** Trace this exact user/acceptance/release/RTM row to the owning implementation without changing its scope. If the row is deferred or gated, record that boundary instead of implementing it. Source: REG-M04 / FR-M04 — US-004 — As a user, I can configure voucher types and numbering series. — AC-004: numbering is unique within its defined scope and respects series ownership. — TC-M04-001…004
- **Verification task:** V-AC-004: inspect the exact traceability row, link it to the implementation and evidence, and classify PASS, BLOCKED, DEFERRED or EXCLUDED without inventing acceptance criteria.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `AC-005` — Active implementation

- **Implementation task:** Trace this exact user/acceptance/release/RTM row to the owning implementation without changing its scope. If the row is deferred or gated, record that boundary instead of implementing it. Source: REG-M05–M07 / FR-M05–M07 — US-005 — As a user, I can enter, validate and post accounting/inventory vouchers. — AC-005: only valid state transitions can create authoritative posting effects. — TC-VCH-001…020
- **Verification task:** V-AC-005: inspect the exact traceability row, link it to the implementation and evidence, and classify PASS, BLOCKED, DEFERRED or EXCLUDED without inventing acceptance criteria.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `AC-006` — Active implementation

- **Implementation task:** Trace this exact user/acceptance/release/RTM row to the owning implementation without changing its scope. If the row is deferred or gated, record that boundary instead of implementing it. Source: REG-M08–M09 / FR-M08–M09 — US-006 — As a user, I can create commercial documents and convert them with lineage. — AC-006: source/target links and quantities are retained. — TC-DOC-001…006
- **Verification task:** V-AC-006: inspect the exact traceability row, link it to the implementation and evidence, and classify PASS, BLOCKED, DEFERRED or EXCLUDED without inventing acceptance criteria.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `AC-007` — Active implementation

- **Implementation task:** Trace this exact user/acceptance/release/RTM row to the owning implementation without changing its scope. If the row is deferred or gated, record that boundary instead of implementing it. Source: REG-M10 / FR-M10 — US-007 — As an approver, I can review and act on pending documents. — AC-007: unauthorized or invalid transitions are rejected and audited. — TC-APR-001…006
- **Verification task:** V-AC-007: inspect the exact traceability row, link it to the implementation and evidence, and classify PASS, BLOCKED, DEFERRED or EXCLUDED without inventing acceptance criteria.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `AC-008` — Active implementation

- **Implementation task:** Trace this exact user/acceptance/release/RTM row to the owning implementation without changing its scope. If the row is deferred or gated, record that boundary instead of implementing it. Source: REG-M11 / FR-M11 — US-008 — As a counter user, I can create a fast bill, hold it and finalize it. — AC-008: core bill flow works offline with preserved totals. — TC-QB-001…010
- **Verification task:** V-AC-008: inspect the exact traceability row, link it to the implementation and evidence, and classify PASS, BLOCKED, DEFERRED or EXCLUDED without inventing acceptance criteria.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `AC-009` — Active implementation

- **Implementation task:** Trace this exact user/acceptance/release/RTM row to the owning implementation without changing its scope. If the row is deferred or gated, record that boundary instead of implementing it. Source: REG-M12–M13 / FR-M12–M13 — US-009 — As a user, I can search and manage stock/counts. — AC-009: search returns scoped records and stock policy is enforced. — TC-SRCH-001…006
- **Verification task:** V-AC-009: inspect the exact traceability row, link it to the implementation and evidence, and classify PASS, BLOCKED, DEFERRED or EXCLUDED without inventing acceptance criteria.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `AC-010` — Active implementation

- **Implementation task:** Trace this exact user/acceptance/release/RTM row to the owning implementation without changing its scope. If the row is deferred or gated, record that boundary instead of implementing it. Source: REG-M14–M16 / FR-M14–M16 — US-010 — As an accountant, I can run reports, reconcile bank files and prepare statutory files. — AC-010: imported statements/files are validated and reconciled before commit/use. — TC-RPT-001…012
- **Verification task:** V-AC-010: inspect the exact traceability row, link it to the implementation and evidence, and classify PASS, BLOCKED, DEFERRED or EXCLUDED without inventing acceptance criteria.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `AC-011` — Active implementation

- **Implementation task:** Trace this exact user/acceptance/release/RTM row to the owning implementation without changing its scope. If the row is deferred or gated, record that boundary instead of implementing it. Source: REG-M17 / FR-M17 — US-011 — As a migrating user, I can import data with mapping, preview and reconciliation. — AC-011: invalid batches do not silently partially commit. — TC-MIG-001…012
- **Verification task:** V-AC-011: inspect the exact traceability row, link it to the implementation and evidence, and classify PASS, BLOCKED, DEFERRED or EXCLUDED without inventing acceptance criteria.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `AC-012` — Active implementation

- **Implementation task:** Trace this exact user/acceptance/release/RTM row to the owning implementation without changing its scope. If the row is deferred or gated, record that boundary instead of implementing it. Source: REG-M18–M20 / FR-M18–M20 — US-012 — As an admin, I can manage users, devices, audit and licence state. — AC-012: rights, entitlement and audit boundaries are enforced in the domain layer. — TC-ADM-001…010
- **Verification task:** V-AC-012: inspect the exact traceability row, link it to the implementation and evidence, and classify PASS, BLOCKED, DEFERRED or EXCLUDED without inventing acceptance criteria.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `AC-013` — Active implementation

- **Implementation task:** Trace this exact user/acceptance/release/RTM row to the owning implementation without changing its scope. If the row is deferred or gated, record that boundary instead of implementing it. Source: REG-M21–M24 / FR-M21–M24 — US-013 — As a user, I can print/share, back up/sync, customize and get help. — AC-013: output, backup and sync operations are explicit and recoverable. — TC-OPS-001…014
- **Verification task:** V-AC-013: inspect the exact traceability row, link it to the implementation and evidence, and classify PASS, BLOCKED, DEFERRED or EXCLUDED without inventing acceptance criteria.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `G0-VER-001` — Blocked evidence

- **Implementation task:** Do not manufacture evidence. Create/update the named evidence record and stop this item as blocked until the owner supplies the source evidence. Source: G0-VER-001 — Verification evidence missing — V-FG-001 / D-06 — Evidence still required — owner confirmed action — Owner confirmed: Attach official library/version/licence and Android 8 compatibility evidence. — G0
- **Verification task:** V-G0-VER-001: evidence-record check confirms the exact required artifact is present, attributable and not simulated; otherwise status remains BLOCKED.
- **Source references:** NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Data_Schema_Specification_v0.1.html, NiAv_Database_Schema_Document_v0.1.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html


### `G0-VER-002` — Blocked evidence

- **Implementation task:** Do not manufacture evidence. Create/update the named evidence record and stop this item as blocked until the owner supplies the source evidence. Source: G0-VER-002 — Verification evidence missing — GST rounding / D-M4 — Evidence still required — owner confirmed action — Owner confirmed: Attach the rule source and a passing golden rounding fixture. — G0
- **Verification task:** V-G0-VER-002: evidence-record check confirms the exact required artifact is present, attributable and not simulated; otherwise status remains BLOCKED.
- **Source references:** NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Data_Schema_Specification_v0.1.html, NiAv_Database_Schema_Document_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html


### `G0-VER-003` — Blocked evidence

- **Implementation task:** Do not manufacture evidence. Create/update the named evidence record and stop this item as blocked until the owner supplies the source evidence. Source: G0-VER-003 — Verification evidence missing — V-FG-001 / O-FG-002/O-FG-003 — Evidence still required — owner confirmed action — Owner confirmed: Attach official schema/version evidence and update verification logs. — G3
- **Verification task:** V-G0-VER-003: evidence-record check confirms the exact required artifact is present, attributable and not simulated; otherwise status remains BLOCKED.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Data_Schema_Specification_v0.1.html, NiAv_Database_Schema_Document_v0.1.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Release_and_Support_Playbook_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html, NiAv_UX_Specification_v0.2.html


### `G0-VER-005` — Blocked evidence

- **Implementation task:** Do not manufacture evidence. Create/update the named evidence record and stop this item as blocked until the owner supplies the source evidence. Source: G0-VER-005 — Verification evidence missing — D-06 / SEC §5 — Evidence still required — owner confirmed action — Owner confirmed: Attach Android 8 Keystore test result and key-wrap behaviour. — G0
- **Verification task:** V-G0-VER-005: evidence-record check confirms the exact required artifact is present, attributable and not simulated; otherwise status remains BLOCKED.
- **Source references:** NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Data_Schema_Specification_v0.1.html, NiAv_Database_Schema_Document_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html


### `R-01` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: R-01 No server means trial reset/piracy Lost licence revenue Installation-ID-bound keys, secure storage, commercial trust, later server-based licensing
- **Verification task:** V-R-01: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html


### `R-02` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: R-02 Data loss (lost/broken phone, uninstall) Severe for customers Prominent backup prompts, auto-backup, restore drills
- **Verification task:** V-R-02: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html

