# NiAvERP OpenCode master prompt v1.1 — outputs customisation and support

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

## Owned IDs (8)

- `FG-011`
- `FR-M21-001`
- `FR-M21-002`
- `FR-M23-001`
- `FR-M24-001`
- `M21`
- `M23`
- `M24`

### `FG-011` — Active P1; deferred P2

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: FG-011 — Payment reminders and bulk sharing — NIAV-REG M14.7/M21.6; NIAV-ZCP M21 — Partial — Reminder/statement generation and human-mediated share-sheet sending are in scope; automated messaging APIs are not. — Bulk preparation and send-status semantics are undefined.
- **Verification task:** V-FG-011: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html


### `FR-M21-001` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Format; device; output type; recipient/share action. State: Prepared → Output. Validation: Unsupported printer capabilities must fail visibly; exact hardware matrix TBD.. Interaction: Print/share sheet/Bluetooth.. Downstream: Customer document delivery.. Source requirement: Print/share input shall allow selection of print format, printer/share target and document/report output.
- **Verification task:** V-FR-M21-001: test required data/input (Format; device; output type; recipient/share action), state (Prepared → Output), validation (Unsupported printer capabilities must fail visibly; exact hardware matrix TBD.), interaction (Print/share sheet/Bluetooth.) and downstream effect (Customer document delivery.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html


### `FR-M21-002` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: UPI ID; amount; invoice/reference; QR mode. State: Configured/Generated. Validation: Exact QR payload rules TBD/VERIFY.. Interaction: QR setup and invoice output.. Downstream: Payment presentation.. Source requirement: UPI QR configuration shall accept static/dynamic QR parameters required for invoice presentation.
- **Verification task:** V-FR-M21-002: test required data/input (UPI ID; amount; invoice/reference; QR mode), state (Configured/Generated), validation (Exact QR payload rules TBD/VERIFY.), interaction (QR setup and invoice output.) and downstream effect (Payment presentation.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M23-001` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Layout preference; menu visibility; shortcut/favourite. State: Saved. Validation: Preferences must not bypass rights or expose disabled edition features.. Interaction: Settings/customization screen.. Downstream: UI behavior only.. Source requirement: UI customisation input shall store user/company layout preferences locally.
- **Verification task:** V-FR-M23-001: test required data/input (Layout preference; menu visibility; shortcut/favourite), state (Saved), validation (Preferences must not bypass rights or expose disabled edition features.), interaction (Settings/customization screen.) and downstream effect (UI behavior only.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M24-001` — Deferred by priority P2

- **Implementation task:** Do not implement this item in the current release. Record priority P2 and gate not stated, and keep it out of active acceptance criteria. Source: Support input shall allow users to view in-app help/guides and initiate support through existing WhatsApp/email channels.
- **Verification task:** V-FR-M24-001: priority/gate ledger confirms deferred status (P2, not stated); no active V1 acceptance test is allowed.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `M21` — Active implementation

- **Implementation task:** Implement only the P1 sub-modules of M21 in the current release. Enumerate every P2/P3/TBC sub-module from the Modules Register as deferred or blocked with its gate; do not silently omit or implement them. Module priority: P1. Gate: not stated. Source: M21 — Printing, Sharing & Communication — P1
- **Verification task:** V-M21: module acceptance test covers each registered sub-module, persistence/restart and integration with its dependent module.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html


### `M23` — Active P1; deferred P2

- **Implementation task:** Implement only the P1 sub-modules of M23 in the current release. Enumerate every P2/P3/TBC sub-module from the Modules Register as deferred or blocked with its gate; do not silently omit or implement them. Module priority: P1/P2. Gate: not stated. Source: M23 — UI Customisation Framework [U3] — P1/P2
- **Verification task:** V-M23: module acceptance test covers each registered sub-module, persistence/restart and integration with its dependent module.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html


### `M24` — Deferred by priority P2

- **Implementation task:** Do not implement this item in the current release. Record priority P2 and gate not stated, and keep it out of active acceptance criteria. Source: M24 — Utilities & Support — P2
- **Verification task:** V-M24: priority/gate ledger confirms deferred status (P2, not stated); no active V1 acceptance test is allowed.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html
