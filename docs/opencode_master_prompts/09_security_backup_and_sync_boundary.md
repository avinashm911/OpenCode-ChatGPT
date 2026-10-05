# NiAvERP OpenCode master prompt v1.1 — security backup and sync boundary

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

## Owned IDs (10)

- `FG-009`
- `FG-010`
- `FR-M22-001`
- `FR-M22-002`
- `FR-M22-003`
- `G0-SCH-005`
- `M22`
- `OD-DB-004`
- `OD-DB-005`
- `OD-DB-006`

### `FG-009` — Active P1; deferred P2

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: FG-009 — Manual remote operation-file sync — NIAV-ZCP §6; NIAV-MPL non-goals — Partial — Manual encrypted remote operation-file exchange is recognized; managed relay/cloud sync is deferred. — Ordering, replay, conflict and partial-transfer behavior need explicit protocol.
- **Verification task:** V-FG-009: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_Database_Schema_Document_v0.1.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html


### `FG-010` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: FG-010 — User-selected external/cloud backup — NIAV-ZCP M22; NIAV-MPL §2 — Partial — User-selected external storage/file-provider workflows are supported; managed cloud backup service is deferred. — Scheduling, provider permissions and restore semantics need detail.
- **Verification task:** V-FG-010: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_Database_Schema_Document_v0.1.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html


### `FR-M22-001` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Destination; backup ID; timestamp; schema version; company ID; encrypted payload. State: Created → Verified. Validation: Backup integrity/authenticity and encryption must satisfy SEC; restore must not silently overwrite live data.. Interaction: Create backup → file provider/share.. Downstream: Disaster recovery.. Source requirement: Backup creation shall capture backup destination, manifest/version, company identity and encrypted backup payload.
- **Verification task:** V-FR-M22-001: test required data/input (Destination; backup ID; timestamp; schema version; company ID; encrypted payload), state (Created → Verified), validation (Backup integrity/authenticity and encryption must satisfy SEC; restore must not silently overwrite live data.), interaction (Create backup → file provider/share.) and downstream effect (Disaster recovery.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Database_Schema_Document_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M22-002` — Boundary

- **Implementation task:** Implement only the safe documented boundary and its validation/replay behavior. Keep the unresolved downstream behavior blocked. Source: LAN/hotspot sync shall accept pairing, sync request, operation batches and conflict-resolution decisions.
- **Verification task:** V-FR-M22-002: boundary test proves allowed local behavior, rejects unsupported behavior, and records the downstream gate.
- **Source references:** NiAv_Database_Schema_Document_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M22-003` — Boundary

- **Implementation task:** Implement only the safe documented boundary and its validation/replay behavior. Keep the unresolved downstream behavior blocked. Source: Manual remote operation-file exchange shall support export/import of encrypted/signed batches through user-controlled transport when accepted.
- **Verification task:** V-FR-M22-003: boundary test proves allowed local behavior, rejects unsupported behavior, and records the downstream gate.
- **Source references:** NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html


### `G0-SCH-005` — Active schema change

- **Implementation task:** Implement the approved schema change exactly, including migration, compatibility, rollback and tests. Source: G0-SCH-005 — Record/operation versioning — record version plus operation.base_version and operation.dependencies — SYNC 3/6
- **Verification task:** V-G0-SCH-005: migration applies on a clean and existing database, preserves data, supports compatibility checks and has rollback evidence.
- **Source references:** NiAv_Data_Schema_Specification_v0.1.html, NiAv_Database_Schema_Document_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_Sync_Protocol_Specification_v0.1.html, NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html


### `M22` — Active implementation

- **Implementation task:** Implement only the P1 sub-modules of M22 in the current release. Enumerate every P2/P3/TBC sub-module from the Modules Register as deferred or blocked with its gate; do not silently omit or implement them. Module priority: P1. Gate: not stated. Source: M22 — Backup, Sync, Security & Audit — P1
- **Verification task:** V-M22: module acceptance test covers each registered sub-module, persistence/restart and integration with its dependent module.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html


### `OD-DB-004` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: OD-DB-004 — Audit payload representation — Field-level old/new deltas as JSON; sensitive fields hash-only; hash chain over canonical record — Decided: proposed value — G1
- **Verification task:** V-OD-DB-004: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html, NiAv_Data_Schema_Specification_v0.1.html, NiAv_Database_Schema_Document_v0.1.html, NiAv_Functional_Design_Document_v0.1.html


### `OD-DB-005` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: OD-DB-005 / O-FG-015 — Attachment storage and file types — Allowed: JPEG, PNG, PDF; max 5 MB each; images downscaled; magic-byte validation; never executed; app-private storage, per-file AES-GCM with keys wrapped by DB key. Imports: .xlsx/.csv only; 10 MB and 50,000-row caps — Decided: proposed value — G1
- **Verification task:** V-OD-DB-005: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html, NiAv_Data_Schema_Specification_v0.1.html, NiAv_Database_Schema_Document_v0.1.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html


### `OD-DB-006` — Boundary

- **Implementation task:** Implement only the safe documented boundary and its validation/replay behavior. Keep the unresolved downstream behavior blocked. Source: OD-DB-006 — Conflict record structure — Table sync_conflict: conflict_id, entity, entity_id, losing_op_id, winning_op_id, base_version, status, resolution, resolver, resolved_at — Decided: proposed value — S1
- **Verification task:** V-OD-DB-006: boundary test proves allowed local behavior, rejects unsupported behavior, and records the downstream gate.
- **Source references:** NiAv_Data_Schema_Specification_v0.1.html, NiAv_Database_Schema_Document_v0.1.html, NiAv_Sync_Protocol_Specification_v0.1.html, NiAv_UX_Specification_v0.2.html
