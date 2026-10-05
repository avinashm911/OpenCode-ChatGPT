# NiAvERP OpenCode master prompt v1.1 — document flow approvals and counter

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

## Owned IDs (11)

- `FR-M09-001`
- `FR-M09-002`
- `FR-M10-001`
- `FR-M10-002`
- `FR-M11-001`
- `FR-M11-002`
- `FR-M11-003`
- `M09`
- `M10`
- `M11`
- `OD-FD-004`

### `FR-M09-001` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Source document; selected lines/qty; target document type. State: Conversion draft → Saved. Validation: Only eligible quantities may be converted; partial/multiple conversion supported.. Interaction: Convert action with editable target draft.. Downstream: Document lineage and pending quantities.. Source requirement: Manual document conversion shall allow the user to select a source document and carry forward eligible party/item/rate data.
- **Verification task:** V-FR-M09-001: test required data/input (Source document; selected lines/qty; target document type), state (Conversion draft → Saved), validation (Only eligible quantities may be converted; partial/multiple conversion supported.), interaction (Convert action with editable target draft.) and downstream effect (Document lineage and pending quantities.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M09-002` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Source ID; target ID; conversion qty; status. State: Linked state. Validation: No orphaned conversion links; reversals must reopen eligible quantities.. Interaction: Lineage view.. Downstream: Traceability and outstanding status.. Source requirement: The system shall maintain document lineage and status across quotation/order/delivery/invoice/receipt and purchase chains.
- **Verification task:** V-FR-M09-002: test required data/input (Source ID; target ID; conversion qty; status), state (Linked state), validation (No orphaned conversion links; reversals must reopen eligible quantities.), interaction (Lineage view.) and downstream effect (Traceability and outstanding status.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M10-001` — Deferred by priority P2

- **Implementation task:** Do not implement this item in the current release. Record priority P2 and gate TBC, and keep it out of active acceptance criteria. Source: Approval-matrix input shall define rules by document type, series, amount threshold, party, branch and user/role.
- **Verification task:** V-FR-M10-001: priority/gate ledger confirms deferred status (P2, TBC); no active V1 acceptance test is allowed.
- **Source references:** NiAv_Database_Schema_Document_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M10-002` — Deferred by priority P2

- **Implementation task:** Do not implement this item in the current release. Record priority P2 and gate not stated, and keep it out of active acceptance criteria. Source: Approvers shall be able to approve, reject with remarks, send back or recall applicable documents.
- **Verification task:** V-FR-M10-002: priority/gate ledger confirms deferred status (P2, not stated); no active V1 acceptance test is allowed.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html


### `FR-M11-001` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Item; qty; rate; discount; tax; payment mode; amount. State: Draft → Posted. Validation: Same calculation rules as M05; defaults should minimize taps.. Interaction: Single-screen quick bill; barcode/item shortcuts.. Downstream: Sales invoice plus payment and output.. Source requirement: Fast Billing shall allow single-screen item entry, quantity, total, payment mode and save/share.
- **Verification task:** V-FR-M11-001: test required data/input (Item; qty; rate; discount; tax; payment mode; amount), state (Draft → Posted), validation (Same calculation rules as M05; defaults should minimize taps.), interaction (Single-screen quick bill; barcode/item shortcuts.) and downstream effect (Sales invoice plus payment and output.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_UX_Specification_v0.2.html


### `FR-M11-002` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Barcode/code; item; party mobile. State: Input shortcuts. Validation: Unknown barcode must offer create/search path rather than silent failure.. Interaction: Camera/scanner/grid/recent actions.. Downstream: Feeds M05 invoice input.. Source requirement: Fast billing shall support barcode scan, item code, favourites, recent items, repeat-last-bill and quick-add walk-in party.
- **Verification task:** V-FR-M11-002: test required data/input (Barcode/code; item; party mobile), state (Input shortcuts), validation (Unknown barcode must offer create/search path rather than silent failure.), interaction (Camera/scanner/grid/recent actions.) and downstream effect (Feeds M05 invoice input.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M11-003` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Held bill ID; current rows; timestamp; counter/user. State: Held → Resumed/Cancelled/Posted. Validation: Held data must not affect accounting/stock until posting.. Interaction: Hold/resume queue.. Downstream: Counter workflow.. Source requirement: Held bills shall be saved as incomplete working documents and resumable without posting until finalized.
- **Verification task:** V-FR-M11-003: test required data/input (Held bill ID; current rows; timestamp; counter/user), state (Held → Resumed/Cancelled/Posted), validation (Held data must not affect accounting/stock until posting.), interaction (Hold/resume queue.) and downstream effect (Counter workflow.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `M09` — Active P1; deferred P2

- **Implementation task:** Implement only the P1 sub-modules of M09 in the current release. Enumerate every P2/P3/TBC sub-module from the Modules Register as deferred or blocked with its gate; do not silently omit or implement them. Module priority: P1/P2. Gate: not stated. Source: M09 — Document Flow / Conversion Engine [U11] — P1/P2
- **Verification task:** V-M09: module acceptance test covers each registered sub-module, persistence/restart and integration with its dependent module.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Data_Schema_Specification_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html


### `M10` — Deferred by priority P2

- **Implementation task:** Do not implement this item in the current release. Record priority P2 and gate not stated, and keep it out of active acceptance criteria. Source: M10 — Approval Matrix & Workflows [U10] — P2
- **Verification task:** V-M10: priority/gate ledger confirms deferred status (P2, not stated); no active V1 acceptance test is allowed.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html


### `M11` — Active implementation

- **Implementation task:** Implement only the P1 sub-modules of M11 in the current release. Enumerate every P2/P3/TBC sub-module from the Modules Register as deferred or blocked with its gate; do not silently omit or implement them. Module priority: P1. Gate: not stated. Source: M11 — Fast Billing / Mobile Counter [U3] — P1
- **Verification task:** V-M11: module acceptance test covers each registered sub-module, persistence/restart and integration with its dependent module.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html


### `OD-FD-004` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: O-07 / OD-FD-004 / OD-UI-004 — Approval scope — Single-level approval by amount threshold and voucher type; no parallel; maker may recall before action; dashboard badge + inbox; no push notifications in V1; approval never bypasses posting validation — Decided: proposed value — R1b
- **Verification task:** V-OD-FD-004: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html
