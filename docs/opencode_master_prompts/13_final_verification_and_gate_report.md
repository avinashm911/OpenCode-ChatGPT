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


### `R-03` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: R-03 Sideload friction / Play Protect warnings Lower installs Install guide, checksum, consider Play Store later when budget allows
- **Verification task:** V-R-03: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html


### `R-04` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: R-04 WhatsApp/email delivery Official channel limits attached; delivery/checksum test pending
- **Verification task:** V-R-04: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Release_and_Support_Playbook_v0.1.html


### `R-05` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: R-05 Sync complexity for a sole developer Delays / data inconsistencies Op-log from day one, staged gates S1 to S3, heavy merge tests, fall back to file merge or V1.1
- **Verification task:** V-R-05: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html


### `R-06` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: R-06 Accounting logic errors Trust damage Heavy automated tests, pilot shops, CA review (volunteer)
- **Verification task:** V-R-06: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html


### `R-07` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: R-07 Statutory changes (GST) Non-compliance Keep tax logic data-driven; monitor official notices; disclaimers
- **Verification task:** V-R-07: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html


### `R-08` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: R-08 Free library abandoned or licence changes Rework Pin versions, prefer well-maintained packages, isolate behind interfaces
- **Verification task:** V-R-08: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html


### `R-09` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: R-09 Indian-script rendering bugs on low-end phones Poor UX Early real-device tests, bundled fonts
- **Verification task:** V-R-09: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html


### `R-10` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: R-10 Keystore loss Cannot ship updates Multiple secure backups of keystore and passwords
- **Verification task:** V-R-10: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html


### `R-11` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: R-11 Performance on low-end phones with big data Slow billing/search Indexes, pagination, benchmark tests
- **Verification task:** V-R-11: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html


### `R-12` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: R-12 Third-party licence compliance Maintain open-source licence inventory and in-app 'Open-source licences' screen Decided: proposed value G5
- **Verification task:** V-R-12: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_UI_UX_Specification_Document_v0.1.html


### `R-13` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: O-14/R-13 DPDP obligations Official Act source attached; control/legal review pending
- **Verification task:** V-R-13: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Release_and_Support_Playbook_v0.1.html


### `R-14` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: R-14 Exploitation of licence/trial Revenue loss Security & Anti-Exploitation Plan; accepted residual risks RR1 to RR6
- **Verification task:** V-R-14: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html


### `RLS-001` — Active implementation

- **Implementation task:** Trace this exact user/acceptance/release/RTM row to the owning implementation without changing its scope. If the row is deferred or gated, record that boundary instead of implementing it. Source: RLS-001 — Source documents and child specs version aligned — Owner
- **Verification task:** V-RLS-001: inspect the exact traceability row, link it to the implementation and evidence, and classify PASS, BLOCKED, DEFERRED or EXCLUDED without inventing acceptance criteria.
- **Source references:** NiAv_Release_and_Support_Playbook_v0.1.html


### `RLS-002` — Active implementation

- **Implementation task:** Trace this exact user/acceptance/release/RTM row to the owning implementation without changing its scope. If the row is deferred or gated, record that boundary instead of implementing it. Source: RLS-002 — All release-blocking tests/gates pass — Test
- **Verification task:** V-RLS-002: inspect the exact traceability row, link it to the implementation and evidence, and classify PASS, BLOCKED, DEFERRED or EXCLUDED without inventing acceptance criteria.
- **Source references:** NiAv_Release_and_Support_Playbook_v0.1.html


### `RLS-003` — Active implementation

- **Implementation task:** Trace this exact user/acceptance/release/RTM row to the owning implementation without changing its scope. If the row is deferred or gated, record that boundary instead of implementing it. Source: RLS-003 — DB migration tested from supported prior versions — Engineering
- **Verification task:** V-RLS-003: inspect the exact traceability row, link it to the implementation and evidence, and classify PASS, BLOCKED, DEFERRED or EXCLUDED without inventing acceptance criteria.
- **Source references:** NiAv_Release_and_Support_Playbook_v0.1.html


### `RLS-004` — Active implementation

- **Implementation task:** Trace this exact user/acceptance/release/RTM row to the owning implementation without changing its scope. If the row is deferred or gated, record that boundary instead of implementing it. Source: RLS-004 — Backup/restore verified — Engineering
- **Verification task:** V-RLS-004: inspect the exact traceability row, link it to the implementation and evidence, and classify PASS, BLOCKED, DEFERRED or EXCLUDED without inventing acceptance criteria.
- **Source references:** NiAv_Release_and_Support_Playbook_v0.1.html


### `RLS-005` — Active implementation

- **Implementation task:** Trace this exact user/acceptance/release/RTM row to the owning implementation without changing its scope. If the row is deferred or gated, record that boundary instead of implementing it. Source: RLS-005 — Licence/trial/edition matrix verified — Owner/Security
- **Verification task:** V-RLS-005: inspect the exact traceability row, link it to the implementation and evidence, and classify PASS, BLOCKED, DEFERRED or EXCLUDED without inventing acceptance criteria.
- **Source references:** NiAv_Release_and_Support_Playbook_v0.1.html


### `RLS-006` — Active implementation

- **Implementation task:** Trace this exact user/acceptance/release/RTM row to the owning implementation without changing its scope. If the row is deferred or gated, record that boundary instead of implementing it. Source: RLS-006 — APK integrity/hash and signing verified — Release
- **Verification task:** V-RLS-006: inspect the exact traceability row, link it to the implementation and evidence, and classify PASS, BLOCKED, DEFERRED or EXCLUDED without inventing acceptance criteria.
- **Source references:** NiAv_Release_and_Support_Playbook_v0.1.html


### `RLS-007` — Active implementation

- **Implementation task:** Trace this exact user/acceptance/release/RTM row to the owning implementation without changing its scope. If the row is deferred or gated, record that boundary instead of implementing it. Source: RLS-007 — Install/update smoke test on target devices — Release
- **Verification task:** V-RLS-007: inspect the exact traceability row, link it to the implementation and evidence, and classify PASS, BLOCKED, DEFERRED or EXCLUDED without inventing acceptance criteria.
- **Source references:** NiAv_Release_and_Support_Playbook_v0.1.html


### `RLS-008` — Active implementation

- **Implementation task:** Trace this exact user/acceptance/release/RTM row to the owning implementation without changing its scope. If the row is deferred or gated, record that boundary instead of implementing it. Source: RLS-008 — Support/incident instructions updated — Support
- **Verification task:** V-RLS-008: inspect the exact traceability row, link it to the implementation and evidence, and classify PASS, BLOCKED, DEFERRED or EXCLUDED without inventing acceptance criteria.
- **Source references:** NiAv_Release_and_Support_Playbook_v0.1.html


### `TC-ADM-001` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by TC-ADM-001. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: REG-M18–M20 / FR-M18–M20 — US-012 — As an admin, I can manage users, devices, audit and licence state. — AC-012: rights, entitlement and audit boundaries are enforced in the domain layer. — TC-ADM-001…010
- **Verification task:** V-TC-ADM-001: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `TC-APR` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by TC-APR. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: UI-007 — Approval Inbox — FR-M10 — TC-APR suite
- **Verification task:** V-TC-APR: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_UX_Specification_v0.2.html


### `TC-APR-001` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by TC-APR-001. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: REG-M10 / FR-M10 — US-007 — As an approver, I can review and act on pending documents. — AC-007: unauthorized or invalid transitions are rejected and audited. — TC-APR-001…006
- **Verification task:** V-TC-APR-001: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `TC-COM-001` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by TC-COM-001. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: FR-COM-001 — US-COM-001 — Stable ID for persistent objects — ID is unique, immutable and reusable for lineage/sync. — TC-COM-001
- **Verification task:** V-TC-COM-001: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `TC-COM-002` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by TC-COM-002. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: FR-COM-002 — US-COM-002 — Context is captured for each transaction — Company/FY/date/user/device context is valid before save/post. — TC-COM-002
- **Verification task:** V-TC-COM-002: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `TC-COM-003` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by TC-COM-003. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: FR-COM-003 — US-COM-003 — State transitions are controlled — Only permitted transitions occur; blocked transitions are explainable. — TC-COM-003
- **Verification task:** V-TC-COM-003: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `TC-COM-004` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by TC-COM-004. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: FR-COM-004 — US-COM-004 — Mandatory fields are enforced — Missing required input cannot be posted/imported. — TC-COM-004
- **Verification task:** V-TC-COM-004: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `TC-COM-005` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by TC-COM-005. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: FR-COM-005 — US-COM-005 — Money/quantity precision is deterministic — Golden fixtures reproduce exact expected values. — TC-COM-005
- **Verification task:** V-TC-COM-005: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `TC-COM-006` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by TC-COM-006. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: FR-COM-006 — US-COM-006 — Duplicates/replays are prevented — Same operation/batch cannot create a second authoritative effect. — TC-COM-006
- **Verification task:** V-TC-COM-006: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `TC-COM-007` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by TC-COM-007. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: FR-COM-007 — US-COM-007 — Attachments can be associated safely — Metadata/hash/storage reference are retained and access controlled. — TC-COM-007
- **Verification task:** V-TC-COM-007: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `TC-DOC-001` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by TC-DOC-001. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: REG-M08–M09 / FR-M08–M09 — US-006 — As a user, I can create commercial documents and convert them with lineage. — AC-006: source/target links and quantities are retained. — TC-DOC-001…006
- **Verification task:** V-TC-DOC-001: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `TC-M01-001` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by TC-M01-001. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: REG-M01 / FR-M01 — US-001 — As an owner, I can create/open a company with FY and configuration. — AC-001: valid company context is required before transactions. — TC-M01-001, TC-M01-002
- **Verification task:** V-TC-M01-001: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `TC-M01-002` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by TC-M01-002. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: REG-M01 / FR-M01 — US-001 — As an owner, I can create/open a company with FY and configuration. — AC-001: valid company context is required before transactions. — TC-M01-001, TC-M01-002
- **Verification task:** V-TC-M01-002: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `TC-M02-001` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by TC-M02-001. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: REG-M02 / FR-M02 — US-002 — As a shopkeeper, I can use the configured language/native script. — AC-002: labels, entry and errors use selected locale where supported. — TC-M02-001, TC-M02-002
- **Verification task:** V-TC-M02-001: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `TC-M02-002` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by TC-M02-002. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: REG-M02 / FR-M02 — US-002 — As a shopkeeper, I can use the configured language/native script. — AC-002: labels, entry and errors use selected locale where supported. — TC-M02-001, TC-M02-002
- **Verification task:** V-TC-M02-002: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `TC-M03-001` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by TC-M03-001. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: REG-M03 / FR-M03 — US-003 — As a user, I can create and maintain accounting/inventory masters. — AC-003: duplicate/invalid master data is blocked with actionable errors. — TC-M03-001…008
- **Verification task:** V-TC-M03-001: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `TC-M04-001` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by TC-M04-001. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: REG-M04 / FR-M04 — US-004 — As a user, I can configure voucher types and numbering series. — AC-004: numbering is unique within its defined scope and respects series ownership. — TC-M04-001…004
- **Verification task:** V-TC-M04-001: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `TC-MIG` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by TC-MIG. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: UI-012 — Migration Import — FR-M17 — TC-MIG suite
- **Verification task:** V-TC-MIG: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_UX_Specification_v0.2.html


### `TC-MIG-001` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by TC-MIG-001. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: REG-M17 / FR-M17 — US-011 — As a migrating user, I can import data with mapping, preview and reconciliation. — AC-011: invalid batches do not silently partially commit. — TC-MIG-001…012
- **Verification task:** V-TC-MIG-001: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `TC-OPS-001` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by TC-OPS-001. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: REG-M21–M24 / FR-M21–M24 — US-013 — As a user, I can print/share, back up/sync, customize and get help. — AC-013: output, backup and sync operations are explicit and recoverable. — TC-OPS-001…014
- **Verification task:** V-TC-OPS-001: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `TC-QB` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by TC-QB. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: UI-005 — Quick Bill — FR-M11-001…003 — TC-QB suite
- **Verification task:** V-TC-QB: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_UX_Specification_v0.2.html


### `TC-QB-001` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by TC-QB-001. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: REG-M11 / FR-M11 — US-008 — As a counter user, I can create a fast bill, hold it and finalize it. — AC-008: core bill flow works offline with preserved totals. — TC-QB-001…010
- **Verification task:** V-TC-QB-001: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `TC-RPT-001` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by TC-RPT-001. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: REG-M14–M16 / FR-M14–M16 — US-010 — As an accountant, I can run reports, reconcile bank files and prepare statutory files. — AC-010: imported statements/files are validated and reconciled before commit/use. — TC-RPT-001…012
- **Verification task:** V-TC-RPT-001: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `TC-SRCH-001` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by TC-SRCH-001. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: REG-M12–M13 / FR-M12–M13 — US-009 — As a user, I can search and manage stock/counts. — AC-009: search returns scoped records and stock policy is enforced. — TC-SRCH-001…006
- **Verification task:** V-TC-SRCH-001: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `TC-SYNC` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by TC-SYNC. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: UI-016 — Backup/Sync — FR-M22 — TC-SYNC/RESTORE suite
- **Verification task:** V-TC-SYNC: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_UX_Specification_v0.2.html


### `TC-VCH` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by TC-VCH. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: UI-004 — Voucher List/Form — FR-M04…M07 — TC-VCH suite
- **Verification task:** V-TC-VCH: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_UX_Specification_v0.2.html


### `TC-VCH-001` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by TC-VCH-001. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: REG-M05–M07 / FR-M05–M07 — US-005 — As a user, I can enter, validate and post accounting/inventory vouchers. — AC-005: only valid state transitions can create authoritative posting effects. — TC-VCH-001…020
- **Verification task:** V-TC-VCH-001: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_Requirements_Traceability_Matrix_v0.1.html


### `TD-001` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by TD-001. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: TD-001 — Minimal company — 1 FY, 2 users, 1 role, 2 devices — Bootstrap, auth, sync
- **Verification task:** V-TD-001: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html


### `TD-002` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by TD-002. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: TD-002 — Masters — 10 parties, 20 items, 4 units, 2 godowns, batches — Search, voucher entry
- **Verification task:** V-TD-002: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html


### `TD-003` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by TD-003. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: TD-003 — Accounting golden — Opening balances + payment/receipt/contra/journal — Ledger/report reconciliation
- **Verification task:** V-TD-003: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html


### `TD-004` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by TD-004. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: TD-004 — Inventory golden — Purchases/sales/transfers/counts with controlled valuation fixture — Stock reconciliation
- **Verification task:** V-TD-004: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html


### `TD-005` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by TD-005. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: TD-005 — GST fixture — Representative taxable/exempt/return scenarios after schema verification — Tax/file adapter
- **Verification task:** V-TD-005: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html


### `TD-006` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by TD-006. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: TD-006 — Migration workbook — Valid + invalid rows + duplicates + missing masters — Import pipeline
- **Verification task:** V-TD-006: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html


### `TD-007` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by TD-007. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: TD-007 — Bank statement — CSV/Excel representative statement with matched/unmatched lines — BRS
- **Verification task:** V-TD-007: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html


### `TD-008` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by TD-008. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: TD-008 — Sync conflict — Two/three device concurrent edits and approval race — S1–S3
- **Verification task:** V-TD-008: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html


### `TD-009` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by TD-009. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: TD-009 — Security corpus — Tampered import, replayed op, revoked peer, modified backup — SEC regression
- **Verification task:** V-TD-009: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html


### `TD-010` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by TD-010. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: TD-010 — Licence corpus — Trial/expiry/grace/edition/device entitlement cases — Licence engine
- **Verification task:** V-TD-010: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html


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


### `WP-02` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by WP-02. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: WP-02 — Core vouchers: dual, accounting, Delivery Note, Stock Transfer/Journal, basic print — R1a — 25 — 35 — 30.0 — 65.0 — 17
- **Verification task:** V-WP-02: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_ Universal Master Plan v0.2.html


### `WP-03` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by WP-03. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: WP-03 — Universal search, fast billing, UI customisation basics — R1a — 15 — 22 — 18.5 — 83.5 — 21
- **Verification task:** V-WP-03: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_ Universal Master Plan v0.2.html


### `WP-04` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by WP-04. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: WP-04 — Core accounting and inventory reports — R1a — 20 — 28 — 24.0 — 107.5 — 27
- **Verification task:** V-WP-04: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_ Universal Master Plan v0.2.html


### `WP-05` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by WP-05. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: WP-05 — Excel import/export and migration tooling — R1a — 12 — 18 — 15.0 — 122.5 — 31
- **Verification task:** V-WP-05: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_ Universal Master Plan v0.2.html


### `WP-06` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by WP-06. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: WP-06 — GST calculation, reports, portal-format exports — R1a — 12 — 18 — 15.0 — 137.5 — 35
- **Verification task:** V-WP-06: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_ Universal Master Plan v0.2.html


### `WP-07` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by WP-07. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: WP-07 — Licence, trial, hardening, encrypted backup, packaging, issuer CLI — R1a — 15 — 22 — 18.5 — 156.0 — 39
- **Verification task:** V-WP-07: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_ Universal Master Plan v0.2.html


### `WP-08` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by WP-08. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: WP-08 — Localisation (English, Hindi, Gujarati) and QA — R1a — 8 — 12 — 10.0 — 166.0 — 42
- **Verification task:** V-WP-08: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_ Universal Master Plan v0.2.html


### `WP-09` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by WP-09. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: WP-09 — Docs, install guides, in-app help — R1a — 5 — 8 — 6.5 — 172.5 — 44
- **Verification task:** V-WP-09: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_ Universal Master Plan v0.2.html


### `WP-10` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by WP-10. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: WP-10 — Pilot 1 (Simple edition) and fixes — R1a — 10 — 15 — 12.5 — 185.0 — 47
- **Verification task:** V-WP-10: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_ Universal Master Plan v0.2.html


### `WP-11` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by WP-11. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: WP-11 — Users, roles, admin console, audit tools — R1b — 15 — 22 — 18.5 — 203.5 — 51
- **Verification task:** V-WP-11: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_ Universal Master Plan v0.2.html


### `WP-12` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by WP-12. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: WP-12 — Approval matrix engine — R1b — 10 — 15 — 12.5 — 216.0 — 54
- **Verification task:** V-WP-12: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_ Universal Master Plan v0.2.html


### `WP-13` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by WP-13. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: WP-13 — Quotation/Order/Document-flow automation, Material Issue/Receive — R1b — 12 — 18 — 15.0 — 231.0 — 58
- **Verification task:** V-WP-13: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_ Universal Master Plan v0.2.html


### `WP-14` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by WP-14. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: WP-14 — Sync part 1: operation-log exchange and file transport (Gate S1) — R1b — 12 — 18 — 15.0 — 246.0 — 62
- **Verification task:** V-WP-14: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_ Universal Master Plan v0.2.html


### `WP-15` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by WP-15. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: WP-15 — Sync part 2: LAN/hotspot sync, pairing, conflicts queue (Gates S2, S3) — R1b — 15 — 24 — 19.5 — 265.5 — 67
- **Verification task:** V-WP-15: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_ Universal Master Plan v0.2.html


### `WP-16` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by WP-16. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: WP-16 — Advanced inventory: batch/expiry, price lists, multi-godown reports — R1b — 12 — 18 — 15.0 — 280.5 — 71
- **Verification task:** V-WP-16: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_ Universal Master Plan v0.2.html


### `WP-17` — Active implementation

- **Implementation task:** Execute or implement the exact source test/work-package/data row identified by WP-17. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: WP-17 — Pilot 2 (Advanced edition) and fixes — R1b — 8 — 12 — 10.0 — 290.5 — 73
- **Verification task:** V-WP-17: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.
- **Source references:** NiAv_ Universal Master Plan v0.2.html

## Final one-to-one audit

Read the matrix and verify mechanically that every core ID appears once in an implementation-owner column and once in a verification-task column. Re-scan all 15 HTML files. Report any missing, duplicate, unclassified or newly discovered ID as FAIL. Do not issue unconditional sign-off if any active ID is unresolved, blocked or lacks evidence.
