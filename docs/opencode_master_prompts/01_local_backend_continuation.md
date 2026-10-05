# NiAvERP OpenCode master prompt v1.1 — local backend continuation

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

## Local-backend continuation directive

This prompt owns the outstanding Slice 1 continuation. Inspect the existing migration runner, repositories, tests and phase-01 report first. Complete only the approved SQLCipher/Drift/Keystore wiring if P-SQLIB/P-KEYSTORE are supplied. If they remain open, preserve the engine-neutral seams, add no plaintext fallback, and stop only production encryption/wiring while continuing independent database work. Do not recreate migrations m001–m009 or replace passing tests.

## Owned IDs (27)

- `D-M4`
- `DB-001`
- `DB-002`
- `DB-003`
- `DB-004`
- `DB-005`
- `DB-006`
- `DB-007`
- `DB-008`
- `DB-009`
- `DB-010`
- `DB-011`
- `DSS-C-001`
- `DSS-C-002`
- `DSS-C-003`
- `DSS-C-004`
- `DSS-C-005`
- `DSS-C-006`
- `DSS-C-007`
- `FR-COM-001`
- `FR-COM-002`
- `FR-COM-003`
- `FR-COM-004`
- `FR-COM-005`
- `FR-COM-006`
- `FR-COM-007`
- `OD-DB-001`

### `D-M4` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: D-M4 / OD-DB-001 — Quantity scale and physical types — Money INTEGER paise. Quantity INTEGER x10^4 (per-unit display precision: pcs 0, kg/litre 3, other <=4). Line amount = round-half-up(qty x rate / 10^4); invoice round-off separate ledger line to nearest rupee. Stock value in paise; unit cost derived. IDs UUIDv7 TEXT. Dates ISO TEXT; timestamps INTEGER epoch ms UTC — Decided: proposed value — G0
- **Verification task:** V-D-M4: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Data_Schema_Specification_v0.1.html, NiAv_Database_Schema_Document_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html


### `DB-001` — Active implementation

- **Implementation task:** Apply this exact data/schema control to the local backend design and migration only where the source row authorizes it. Preserve existing migrations and stop on missing SQLCipher/licence decisions. Source: DB-001 IDs Use stable UUID-style IDs for persistent entities; human voucher numbers are separate business identifiers. MPL/SEC/FR-COM-001
- **Verification task:** V-DB-001: verify the exact schema/control row against migrations, repository behavior and persistence tests; report missing encryption or licence evidence as BLOCKED.
- **Source references:** NiAv_Database_Schema_Document_v0.1.html


### `DB-002` — Active implementation

- **Implementation task:** Apply this exact data/schema control to the local backend design and migration only where the source row authorizes it. Preserve existing migrations and stop on missing SQLCipher/licence decisions. Source: DB-002 Money Store monetary values as integer paise or equivalent fixed-point representation; never binary floating point for authoritative money. MPL/ZCP/FR-COM-005 Resolved: Money INTEGER paise. Quantity INTEGER x10^4 (per-unit display precision: pcs 0, kg/litre 3, other <=4). Line amount = round-half-up(qty x rate / 10^4); invoice round-off separate ledger line to nearest rupee. Stock value in paise; unit cost derived. IDs UUIDv7 TEXT. Dates ISO TEXT; timestamps INTEGER epoch ms UTC (Decided: proposed value)
- **Verification task:** V-DB-002: verify the exact schema/control row against migrations, repository behavior and persistence tests; report missing encryption or licence evidence as BLOCKED.
- **Source references:** NiAv_Database_Schema_Document_v0.1.html


### `DB-003` — Active implementation

- **Implementation task:** Apply this exact data/schema control to the local backend design and migration only where the source row authorizes it. Preserve existing migrations and stop on missing SQLCipher/licence decisions. Source: DB-003 Quantity Use fixed-point quantity representation with explicit unit/precision metadata. MPL/ZCP/FR-COM-005 Resolved: Verify GST/e-invoice/e-way schemas from official sources; record in verification logs (Decided: owner value)
- **Verification task:** V-DB-003: verify the exact schema/control row against migrations, repository behavior and persistence tests; report missing encryption or licence evidence as BLOCKED.
- **Source references:** NiAv_Database_Schema_Document_v0.1.html


### `DB-004` — Active implementation

- **Implementation task:** Apply this exact data/schema control to the local backend design and migration only where the source row authorizes it. Preserve existing migrations and stop on missing SQLCipher/licence decisions. Source: DB-004 Audit Audit events are append-oriented and protected from ordinary modification. SEC/FR-M18-002
- **Verification task:** V-DB-004: verify the exact schema/control row against migrations, repository behavior and persistence tests; report missing encryption or licence evidence as BLOCKED.
- **Source references:** NiAv_Database_Schema_Document_v0.1.html


### `DB-005` — Active implementation

- **Implementation task:** Apply this exact data/schema control to the local backend design and migration only where the source row authorizes it. Preserve existing migrations and stop on missing SQLCipher/licence decisions. Source: DB-005 Operation log Operations carry device/sequence/dependency identity to support LAN/file sync and rebuild/audit. MPL/ZCP/SEC
- **Verification task:** V-DB-005: verify the exact schema/control row against migrations, repository behavior and persistence tests; report missing encryption or licence evidence as BLOCKED.
- **Source references:** NiAv_Database_Schema_Document_v0.1.html


### `DB-006` — Active implementation

- **Implementation task:** Apply this exact data/schema control to the local backend design and migration only where the source row authorizes it. Preserve existing migrations and stop on missing SQLCipher/licence decisions. Source: DB-006 Derived data Stock balances, search indexes and other read models are rebuildable where practical. MPL
- **Verification task:** V-DB-006: verify the exact schema/control row against migrations, repository behavior and persistence tests; report missing encryption or licence evidence as BLOCKED.
- **Source references:** NiAv_Database_Schema_Document_v0.1.html


### `DB-007` — Active implementation

- **Implementation task:** Apply this exact data/schema control to the local backend design and migration only where the source row authorizes it. Preserve existing migrations and stop on missing SQLCipher/licence decisions. Source: DB-007 Import isolation Import batches/errors are stored separately from authoritative domain data until commit. FR-M17-001…004
- **Verification task:** V-DB-007: verify the exact schema/control row against migrations, repository behavior and persistence tests; report missing encryption or licence evidence as BLOCKED.
- **Source references:** NiAv_Database_Schema_Document_v0.1.html


### `DB-008` — Active implementation

- **Implementation task:** Apply this exact data/schema control to the local backend design and migration only where the source row authorizes it. Preserve existing migrations and stop on missing SQLCipher/licence decisions. Source: DB-008 Tenant boundary Every company-owned table carries company scope directly or through a constrained parent relationship. MPL/SEC
- **Verification task:** V-DB-008: verify the exact schema/control row against migrations, repository behavior and persistence tests; report missing encryption or licence evidence as BLOCKED.
- **Source references:** NiAv_Database_Schema_Document_v0.1.html


### `DB-009` — Active implementation

- **Implementation task:** Apply this exact data/schema control to the local backend design and migration only where the source row authorizes it. Preserve existing migrations and stop on missing SQLCipher/licence decisions. Source: DB-009 Soft deletion Do not use silent destructive deletion for posted/audited records; use status/reversal/void mechanisms. REG/SEC
- **Verification task:** V-DB-009: verify the exact schema/control row against migrations, repository behavior and persistence tests; report missing encryption or licence evidence as BLOCKED.
- **Source references:** NiAv_Database_Schema_Document_v0.1.html


### `DB-010` — Active implementation

- **Implementation task:** Apply this exact data/schema control to the local backend design and migration only where the source row authorizes it. Preserve existing migrations and stop on missing SQLCipher/licence decisions. Source: DB-010 Schema migration Every database release has a numbered migration; old data is transformed deterministically and tested before release. MPL
- **Verification task:** V-DB-010: verify the exact schema/control row against migrations, repository behavior and persistence tests; report missing encryption or licence evidence as BLOCKED.
- **Source references:** NiAv_Database_Schema_Document_v0.1.html


### `DB-011` — Active implementation

- **Implementation task:** Apply this exact data/schema control to the local backend design and migration only where the source row authorizes it. Preserve existing migrations and stop on missing SQLCipher/licence decisions. Source: DB-011 Secrets Credential/key material is not stored as ordinary exportable business fields; protected platform storage is required where applicable. SEC
- **Verification task:** V-DB-011: verify the exact schema/control row against migrations, repository behavior and persistence tests; report missing encryption or licence evidence as BLOCKED.
- **Source references:** NiAv_Database_Schema_Document_v0.1.html


### `DSS-C-001` — Active implementation

- **Implementation task:** Apply this exact data/schema control to the local backend design and migration only where the source row authorizes it. Preserve existing migrations and stop on missing SQLCipher/licence decisions. Source: DSS-C-001 Company isolation Every company-owned entity is directly or transitively scoped to company_id.
- **Verification task:** V-DSS-C-001: verify the exact schema/control row against migrations, repository behavior and persistence tests; report missing encryption or licence evidence as BLOCKED.
- **Source references:** NiAv_Data_Schema_Specification_v0.1.html


### `DSS-C-002` — Active implementation

- **Implementation task:** Apply this exact data/schema control to the local backend design and migration only where the source row authorizes it. Preserve existing migrations and stop on missing SQLCipher/licence decisions. Source: DSS-C-002 Voucher uniqueness Human voucher number uniqueness is enforced at the configured series scope.
- **Verification task:** V-DSS-C-002: verify the exact schema/control row against migrations, repository behavior and persistence tests; report missing encryption or licence evidence as BLOCKED.
- **Source references:** NiAv_Data_Schema_Specification_v0.1.html


### `DSS-C-003` — Active implementation

- **Implementation task:** Apply this exact data/schema control to the local backend design and migration only where the source row authorizes it. Preserve existing migrations and stop on missing SQLCipher/licence decisions. Source: DSS-C-003 No destructive posted delete Posted/audited records are reversed/cancelled through controlled operations. Resolved: Verify GST/e-invoice/e-way schemas from official sources; record in verification logs (Decided: owner value)
- **Verification task:** V-DSS-C-003: verify the exact schema/control row against migrations, repository behavior and persistence tests; report missing encryption or licence evidence as BLOCKED.
- **Source references:** NiAv_Data_Schema_Specification_v0.1.html


### `DSS-C-004` — Active implementation

- **Implementation task:** Apply this exact data/schema control to the local backend design and migration only where the source row authorizes it. Preserve existing migrations and stop on missing SQLCipher/licence decisions. Source: DSS-C-004 Replay safety op_id and device+sequence identity make repeated operations detectable.
- **Verification task:** V-DSS-C-004: verify the exact schema/control row against migrations, repository behavior and persistence tests; report missing encryption or licence evidence as BLOCKED.
- **Source references:** NiAv_Data_Schema_Specification_v0.1.html


### `DSS-C-005` — Active implementation

- **Implementation task:** Apply this exact data/schema control to the local backend design and migration only where the source row authorizes it. Preserve existing migrations and stop on missing SQLCipher/licence decisions. Source: DSS-C-005 Import atomicity Authoritative tables are not changed until import validation/commit succeeds.
- **Verification task:** V-DSS-C-005: verify the exact schema/control row against migrations, repository behavior and persistence tests; report missing encryption or licence evidence as BLOCKED.
- **Source references:** NiAv_Data_Schema_Specification_v0.1.html


### `DSS-C-006` — Active implementation

- **Implementation task:** Apply this exact data/schema control to the local backend design and migration only where the source row authorizes it. Preserve existing migrations and stop on missing SQLCipher/licence decisions. Source: DSS-C-006 Derived rebuild Defined derived tables can be regenerated from authoritative transaction data.
- **Verification task:** V-DSS-C-006: verify the exact schema/control row against migrations, repository behavior and persistence tests; report missing encryption or licence evidence as BLOCKED.
- **Source references:** NiAv_Data_Schema_Specification_v0.1.html


### `DSS-C-007` — Active implementation

- **Implementation task:** Apply this exact data/schema control to the local backend design and migration only where the source row authorizes it. Preserve existing migrations and stop on missing SQLCipher/licence decisions. Source: DSS-C-007 Schema migration Every release has a numbered migration; downgrade is refused unless explicitly supported by a future design.
- **Verification task:** V-DSS-C-007: verify the exact schema/control row against migrations, repository behavior and persistence tests; report missing encryption or licence evidence as BLOCKED.
- **Source references:** NiAv_Data_Schema_Specification_v0.1.html, NiAv_Release_and_Support_Playbook_v0.1.html, NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html


### `FR-COM-001` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: UUID/record ID; entity type. State: Create → Active. Validation: Unique within company/data domain; immutable after creation.. Interaction: Automatic on first save; never user-entered unless explicitly supported for an external reference.. Downstream: Primary key and cross-document lineage.. Source requirement: The system shall create a unique record identifier for every persistent master, voucher, document, import batch, sync batch, backup manifest and licence object.
- **Verification task:** V-FR-COM-001: test required data/input (UUID/record ID; entity type), state (Create → Active), validation (Unique within company/data domain; immutable after creation.), interaction (Automatic on first save; never user-entered unless explicitly supported for an external reference.) and downstream effect (Primary key and cross-document lineage.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Data_Schema_Specification_v0.1.html, NiAv_Database_Schema_Document_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html


### `FR-COM-002` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Company ID; FY; date; time; user ID; device ID. State: Draft → Saved/Posted. Validation: Company/FY must be valid; date policy must respect configured lock rules.. Interaction: Prefilled from context; editable fields subject to rights.. Downstream: Posting, audit trail, sync and reporting.. Source requirement: Every data-entry transaction shall carry company, financial-year, document date/time context and creating user/device context where applicable.
- **Verification task:** V-FR-COM-002: test required data/input (Company ID; FY; date; time; user ID; device ID), state (Draft → Saved/Posted), validation (Company/FY must be valid; date policy must respect configured lock rules.), interaction (Prefilled from context; editable fields subject to rights.) and downstream effect (Posting, audit trail, sync and reporting.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html


### `FR-COM-003` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: State; remarks; actor; timestamp. State: State transition. Validation: Only permitted transitions; approval/posting rules configurable where specified.. Interaction: Buttons/actions appropriate to role; no destructive hidden actions.. Downstream: Workflow, posting, audit and document lineage.. Source requirement: The system shall support Draft/Save/Cancel/Alter/Review/Approve/Reject/Post states where the relevant module defines them.
- **Verification task:** V-FR-COM-003: test required data/input (State; remarks; actor; timestamp), state (State transition), validation (Only permitted transitions; approval/posting rules configurable where specified.), interaction (Buttons/actions appropriate to role; no destructive hidden actions.) and downstream effect (Workflow, posting, audit and document lineage.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html


### `FR-COM-004` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Field-level required flags; rule source. State: Validation. Validation: Requiredness shall be driven by company/voucher/series configuration where supported.. Interaction: Inline errors plus summary of unresolved fields.. Downstream: Prevents invalid posting/import.. Source requirement: Mandatory fields shall be enforced before the transaction can reach the state that requires them.
- **Verification task:** V-FR-COM-004: test required data/input (Field-level required flags; rule source), state (Validation), validation (Requiredness shall be driven by company/voucher/series configuration where supported.), interaction (Inline errors plus summary of unresolved fields.) and downstream effect (Prevents invalid posting/import.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html


### `FR-COM-005` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Amount; rate; discount; tax; quantity; precision. State: Input → normalized value. Validation: Precision/rounding rules must be defined before implementation of each calculation domain.. Interaction: Numeric keypad; locale-aware separators; explicit rounding display where applicable.. Downstream: Accounting, stock and GST calculations.. Source requirement: Money values shall be entered and stored without binary floating-point ambiguity; quantity precision shall follow configured unit rules.
- **Verification task:** V-FR-COM-005: test required data/input (Amount; rate; discount; tax; quantity; precision), state (Input → normalized value), validation (Precision/rounding rules must be defined before implementation of each calculation domain.), interaction (Numeric keypad; locale-aware separators; explicit rounding display where applicable.) and downstream effect (Accounting, stock and GST calculations.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Database_Schema_Document_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html


### `FR-COM-006` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Idempotency key; source batch ID; external reference. State: Duplicate check. Validation: Duplicate criteria must be deterministic per entity/workflow.. Interaction: Retry-safe Save/Import/Sync actions.. Downstream: Posting, import and sync integrity.. Source requirement: The system shall prevent accidental duplicate creation when a user retries a save or an imported/synced batch is replayed.
- **Verification task:** V-FR-COM-006: test required data/input (Idempotency key; source batch ID; external reference), state (Duplicate check), validation (Duplicate criteria must be deterministic per entity/workflow.), interaction (Retry-safe Save/Import/Sync actions.) and downstream effect (Posting, import and sync integrity.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html


### `FR-COM-007` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Attachment; reference no.; source metadata. State: Attached / Unattached. Validation: File must pass import/security limits; exact file types TBD.. Interaction: Camera/file picker/share import as supported.. Downstream: Audit evidence and document record.. Source requirement: Users shall be able to attach a photo/PDF or external reference to supported vouchers.
- **Verification task:** V-FR-COM-007: test required data/input (Attachment; reference no.; source metadata), state (Attached / Unattached), validation (File must pass import/security limits; exact file types TBD.), interaction (Camera/file picker/share import as supported.) and downstream effect (Audit evidence and document record.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Database_Schema_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html


### `OD-DB-001` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: D-M4 / OD-DB-001 — Quantity scale and physical types — Money INTEGER paise. Quantity INTEGER x10^4 (per-unit display precision: pcs 0, kg/litre 3, other <=4). Line amount = round-half-up(qty x rate / 10^4); invoice round-off separate ledger line to nearest rupee. Stock value in paise; unit cost derived. IDs UUIDv7 TEXT. Dates ISO TEXT; timestamps INTEGER epoch ms UTC — Decided: proposed value — G0
- **Verification task:** V-OD-DB-001: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Data_Schema_Specification_v0.1.html, NiAv_Database_Schema_Document_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html
