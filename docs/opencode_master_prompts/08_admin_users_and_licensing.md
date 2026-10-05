# NiAvERP OpenCode master prompt v1.1 — admin users and licensing

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

## Owned IDs (15)

- `FG-012`
- `FG-014`
- `FR-M18-001`
- `FR-M18-002`
- `FR-M19-001`
- `FR-M19-002`
- `FR-M19-003`
- `FR-M20-001`
- `FR-M20-002`
- `G0-SCH-006`
- `M18`
- `M19`
- `M20`
- `OD-FD-005`
- `OD-UI-005`

### `FG-012` — Active P1; deferred P2

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: FG-012 — External/manual UPI licence payment — NIAV-REG M20.5; NIAV-ZCP §7; NIAV-SEC §3 — Partial — Offline signed licences are core; in-app payment gateways are excluded; external/manual payment can precede key issuance. — Payment-to-licence operational handoff is unspecified.
- **Verification task:** V-FG-012: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Release_and_Support_Playbook_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html


### `FG-014` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: FG-014 — Edition and licence boundaries — NIAV-REG M20; NIAV-MPL §2; NIAV-ZCP §7; NIAV-SEC §3 — Partial — Simple/Advanced and monthly/annual/lifetime licensing exist conceptually, but boundaries and grace/lifetime definitions remain open. — Feature gating cannot be tested reliably.
- **Verification task:** V-FG-014: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Release_and_Support_Playbook_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html


### `FR-M18-001` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Admin action; target; reason; effective date. State: Requested → Applied. Validation: Privileged actions require authorization and audit trail.. Interaction: Admin console.. Downstream: Configuration/security state.. Source requirement: Admin input shall support company create/backup/restore/delete/lock, user administration, rights, data restrictions and voucher controls according to role.
- **Verification task:** V-FR-M18-001: test required data/input (Admin action; target; reason; effective date), state (Requested → Applied), validation (Privileged actions require authorization and audit trail.), interaction (Admin console.) and downstream effect (Configuration/security state.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M18-002` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Action; entity; old value; new value; actor; time; device; reason. State: Append-only event. Validation: Audit events must not be silently editable/deletable by ordinary users.. Interaction: Automatic; review screen.. Downstream: Audit and security evidence.. Source requirement: Audit-log records shall capture create/alter/delete/login and old-vs-new values for auditable changes.
- **Verification task:** V-FR-M18-002: test required data/input (Action; entity; old value; new value; actor; time; device; reason), state (Append-only event), validation (Audit events must not be silently editable/deletable by ordinary users.), interaction (Automatic; review screen.) and downstream effect (Audit and security evidence.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Database_Schema_Document_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M19-001` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Mobile; password/PIN credential; biometric enrollment state. State: Unconfigured → Active/Locked. Validation: Credential rules per SEC; secrets never stored in plaintext.. Interaction: On-device setup/unlock.. Downstream: Access control.. Source requirement: Authentication input shall support the selected mobile/password/PIN/biometric mechanism without making the app dependent on a paid server.
- **Verification task:** V-FR-M19-001: test required data/input (Mobile; password/PIN credential; biometric enrollment state), state (Unconfigured → Active/Locked), validation (Credential rules per SEC; secrets never stored in plaintext.), interaction (On-device setup/unlock.) and downstream effect (Access control.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M19-002` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: User; role; permissions; defaults. State: Active/Disabled. Validation: Rights must be checked at action level, not only menu visibility.. Interaction: Admin forms.. Downstream: Authorization and data-entry defaults.. Source requirement: User/role input shall support predefined roles, custom roles and user-wise defaults for series, godown, cash ledger and counter.
- **Verification task:** V-FR-M19-002: test required data/input (User; role; permissions; defaults), state (Active/Disabled), validation (Rights must be checked at action level, not only menu visibility.), interaction (Admin forms.) and downstream effect (Authorization and data-entry defaults.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M19-003` — Boundary

- **Implementation task:** Implement only the safe documented boundary and its validation/replay behavior. Keep the unresolved downstream behavior blocked. Source: Sync-device pairing input shall identify company, device and user and record trust/revocation state for LAN/hotspot sync.
- **Verification task:** V-FR-M19-003: boundary test proves allowed local behavior, rejects unsupported behavior, and records the downstream gate.
- **Source references:** NiAv_Database_Schema_Document_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M20-001` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Activation date; licence key; edition; term; device/user binding; state. State: Trial → Licensed/Expired/Grace/Read-only as defined. Validation: Signature/entitlement verified locally; exact grace/lifetime definitions remain open.. Interaction: Activation/import licence flow.. Downstream: Feature gates and post-expiry behavior.. Source requirement: Trial/licence input shall accept activation context and signed licence key data and expose current entitlement state.
- **Verification task:** V-FR-M20-001: test required data/input (Activation date; licence key; edition; term; device/user binding; state), state (Trial → Licensed/Expired/Grace/Read-only as defined), validation (Signature/entitlement verified locally; exact grace/lifetime definitions remain open.), interaction (Activation/import licence flow.) and downstream effect (Feature gates and post-expiry behavior.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Database_Schema_Document_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html


### `FR-M20-002` — Deferred by priority P2

- **Implementation task:** Do not implement this item in the current release. Record priority P2 and gate not stated, and keep it out of active acceptance criteria. Source: The customer-facing payment workflow shall not require in-app payment in V1; payment evidence is handled externally before licence issuance if that workaround is adopted.
- **Verification task:** V-FR-M20-002: priority/gate ledger confirms deferred status (P2, not stated); no active V1 acceptance test is allowed.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `G0-SCH-006` — Active schema change

- **Implementation task:** Implement the approved schema change exactly, including migration, compatibility, rollback and tests. Source: G0-SCH-006 — Schema design gap — SEC licence controls — Approved design change — implementation required — Approved: Add storage and lifecycle rules for trial anchor, denylist and audit evidence. — G0
- **Verification task:** V-G0-SCH-006: migration applies on a clean and existing database, preserves data, supports compatibility checks and has rollback evidence.
- **Source references:** NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html, NiAv_Data_Schema_Specification_v0.1.html, NiAv_Database_Schema_Document_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html


### `M18` — Active P1; deferred P2

- **Implementation task:** Implement only the P1 sub-modules of M18 in the current release. Enumerate every P2/P3/TBC sub-module from the Modules Register as deferred or blocked with its gate; do not silently omit or implement them. Module priority: P1/P2. Gate: not stated. Source: M18 — Admin Module (Super User) [U8] — P1/P2
- **Verification task:** V-M18: module acceptance test covers each registered sub-module, persistence/restart and integration with its dependent module.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html


### `M19` — Active implementation

- **Implementation task:** Implement only the P1 sub-modules of M19 in the current release. Enumerate every P2/P3/TBC sub-module from the Modules Register as deferred or blocked with its gate; do not silently omit or implement them. Module priority: P1. Gate: not stated. Source: M19 — Users, Roles & Multi-user [U9] — P1
- **Verification task:** V-M19: module acceptance test covers each registered sub-module, persistence/restart and integration with its dependent module.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html


### `M20` — Active implementation

- **Implementation task:** Implement only the P1 sub-modules of M20 in the current release. Enumerate every P2/P3/TBC sub-module from the Modules Register as deferred or blocked with its gate; do not silently omit or implement them. Module priority: P1. Gate: not stated. Source: M20 — Licensing & Trial [U9] — P1
- **Verification task:** V-M20: module acceptance test covers each registered sub-module, persistence/restart and integration with its dependent module.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Data_Schema_Specification_v0.1.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html


### `OD-FD-005` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: OD-FD-005 — Licence — Freeze edition × term × trial × grace × device/user entitlement matrix. — FR-M20-001/002
- **Verification task:** V-OD-FD-005: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_Functional_Design_Document_v0.1.html


### `OD-UI-005` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: OD-UI-005 — Licence messaging — Freeze grace/read-only wording and entitlement states. — FR-M20-001
- **Verification task:** V-OD-UI-005: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_UI_UX_Specification_Document_v0.1.html
