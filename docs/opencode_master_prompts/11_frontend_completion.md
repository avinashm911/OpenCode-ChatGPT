# NiAvERP OpenCode master prompt v1.1 — frontend completion

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

## Frontend directive

Replace placeholder tabs and wire screens only to real application services/use cases. The navigation decision alone is not frontend completion. Every completed screen requires loading, empty, validation, locked/conflict, success and recoverable-error states.

## Owned IDs (41)

- `OD-001`
- `OD-002`
- `OD-003`
- `OD-004`
- `OD-005`
- `OD-006`
- `OD-007`
- `OD-008`
- `OD-009`
- `OD-010`
- `OD-UI-001`
- `OD-UI-002`
- `OD-UI-003`
- `OD-UI-004`
- `UI-001`
- `UI-002`
- `UI-003`
- `UI-004`
- `UI-005`
- `UI-006`
- `UI-007`
- `UI-008`
- `UI-009`
- `UI-010`
- `UI-011`
- `UI-012`
- `UI-013`
- `UI-014`
- `UI-015`
- `UI-016`
- `UI-017`
- `UI-018`
- `UX-001`
- `UX-002`
- `UX-003`
- `UX-004`
- `UX-005`
- `UX-006`
- `UX-007`
- `UX-008`
- `UX-009`

### `OD-001` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: OD-001 / O-08 — Voucher series scope and gap policy — Invoice will have limited series, as CA advice on keeping number of invoice series to be minimum — Decided: owner value — G1
- **Verification task:** V-OD-001: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_Data_Schema_Specification_v0.1.html, NiAv_Database_Schema_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_Sync_Protocol_Specification_v0.1.html


### `OD-002` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: OD-002 — M02 — Voice input is rejected; no V1 voice capability or voice privacy/performance requirement — Voice input is rejected; no acceptance criteria or implementation in V1. — REG M02.5; ZCP M02
- **Verification task:** V-OD-002: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `OD-003` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: OD-003 — FRD OD-003 (subject not captured) — Rejected — FRD OD-003 is withdrawn; no requirement is admitted under this ID. — Rejected: explicit owner instruction — G1
- **Verification task:** V-OD-003: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `OD-004` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: D-M5 / D-08 / D-FG-013 / O-09 / OD-004 / OD-FD-001 — Valuation policy — (1) Methods: Weighted Average and FIFO only. (2) Item overrides group; default Weighted Average. (3) Method locked after first posted stock movement; no change in V1. (4) Negative stock allowed with warning; no-layer issues costed at last known cost; no retro revaluation in V1. (5) Period lock by date; unlock needs right + reason + audit. (6) Orders never reserve stock (D-M6 = No). (7) Golden ledgers: opening, purchase, sale, returns, adjustment, negative-stock sale, lock/unlock — Decided: proposed value — G1
- **Verification task:** V-OD-004: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Data_Schema_Specification_v0.1.html, NiAv_Database_Schema_Document_v0.1.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html


### `OD-005` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: OD-005 — M16 — Current statutory applicability, schemas and exact file/response contracts — Sources require official verification before implementation. — REG M16; FGA FG-002/003/007/008
- **Verification task:** V-OD-005: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `OD-006` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: OD-006 — M17 — Tally/Busy versions, data types and history period supported — Native formats require feasibility/representative-file verification. — O-13; FGA FG-006
- **Verification task:** V-OD-006: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `OD-007` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: D-10 / O-06 / O-15 / OD-007 — Simple vs Advanced boundary — Simple (R1a): masters, P1 dual+accounting vouchers, Delivery Note, Stock Transfer/Journal, basic quotation/order, Quick Bill, search, core reports, GST reports, Excel import/export, backup, en/hi/gu, 1 device. Advanced (R1b+): all Simple + multi-user/roles, approvals, document-flow automation, Material Issue/Receive, batch/expiry, price lists, multi-godown reports, LAN/hotspot + file sync, audit/admin tools — Decided: proposed value — G5
- **Verification task:** V-OD-007: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_Sync_Protocol_Specification_v0.1.html


### `OD-008` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: O-12 / O-M07 / OD-008 — Printing hardware — Bluetooth ESC/POS thermal 58 mm and 80 mm + PDF via Android print/share for A4/A5; Indic text rendered as raster image; USB/Wi-Fi printers later; test on >=3 printers; failures visible — Decided: proposed value — G5
- **Verification task:** V-OD-008: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html, NiAv_UX_Specification_v0.2.html


### `OD-009` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: OD-009 — M22 — Backup scheduling semantics and external file-provider behavior — Manual/scheduled and cloud/local wording needs detailed acceptance. — FGA FG-010
- **Verification task:** V-OD-009: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `OD-010` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: OD-010 — Cross-cutting — Exact numeric performance targets — Search and fast-billing benchmarks need measurable definitions. — REG M11.1/M12.8; MPL performance tests
- **Verification task:** V-OD-010: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `OD-UI-001` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: OD-UI-001 — Navigation hierarchy — Adopt MPL bottom bar: Home, Billing, Parties & Items, Reports, More; mark UIUX tree superseded — Decided: proposed value — G0
- **Verification task:** V-OD-UI-001: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Universal Master Plan v0.2.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html, NiAv_UX_Specification_v0.2.html


### `OD-UI-002` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: OD-UI-002 — Printer matrix — Freeze supported printer/connection UX and failure recovery. — FR-M21-001
- **Verification task:** V-OD-UI-002: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_UI_UX_Specification_Document_v0.1.html


### `OD-UI-003` — Excluded

- **Implementation task:** Do not implement this item. Add a negative test proving the excluded capability is not exposed. Preserve the source decision: OD-UI-003 / FR-M02-002 — Voice input feasibility — Rejected by owner; no R3 gate — Rejected: owner rejected voice input for V1 — R3
- **Verification task:** V-OD-UI-003: static scan plus negative UI/domain test confirms the excluded feature is absent.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html, NiAv_UX_Specification_v0.2.html


### `OD-UI-004` — Decision/design control

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: O-07 / OD-FD-004 / OD-UI-004 — Approval scope — Single-level approval by amount threshold and voucher type; no parallel; maker may recall before action; dashboard badge + inbox; no push notifications in V1; approval never bypasses posting validation — Decided: proposed value — R1b
- **Verification task:** V-OD-UI-004: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html


### `UI-001` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: UI-001 Home/Dashboard Company context, quick actions, recent documents, outstanding alerts M01/M11/M14/M12
- **Verification task:** V-UI-001: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_UI_UX_Specification_Document_v0.1.html


### `UI-002` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: UI-002 Company Setup Stepper for identity, FY, GST, inventory and configuration M01
- **Verification task:** V-UI-002: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_UI_UX_Specification_Document_v0.1.html


### `UI-003` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: UI-003 Master List/Form List + search + add/edit; reusable form sections M03 Resolved: Verify GST/e-invoice/e-way schemas from official sources; record in verification logs (Decided: owner value)
- **Verification task:** V-UI-003: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_UI_UX_Specification_Document_v0.1.html


### `UI-004` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: UI-004 Voucher List/Form Header, party, rows, totals, tax, references, attachments M04–M07
- **Verification task:** V-UI-004: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_UI_UX_Specification_Document_v0.1.html, NiAv_UX_Specification_v0.2.html


### `UI-005` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: UI-005 Fast Billing Single-screen item search, barcode, cart, payment, hold/finalize M11
- **Verification task:** V-UI-005: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_UI_UX_Specification_Document_v0.1.html, NiAv_UX_Specification_v0.2.html


### `UI-006` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: UI-006 Quotation/Order Commercial document entry, status and conversion actions M08/M09 Resolved: Decide before go-live (Decided: owner value)
- **Verification task:** V-UI-006: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_UI_UX_Specification_Document_v0.1.html


### `UI-007` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: UI-007 Approval Inbox Pending approvals, detail, approve/reject/send-back M10
- **Verification task:** V-UI-007: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_UI_UX_Specification_Document_v0.1.html, NiAv_UX_Specification_v0.2.html


### `UI-008` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: UI-008 Search/Pickers Universal search and contextual entity pickers M12
- **Verification task:** V-UI-008: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_UI_UX_Specification_Document_v0.1.html


### `UI-009` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: UI-009 Inventory Stock, transfers, counts, batch/expiry and negative-stock warnings M13
- **Verification task:** V-UI-009: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_UI_UX_Specification_Document_v0.1.html


### `UI-010` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: UI-010 Reports/BRS Filters, report view, statement import and match workspace M14/M15
- **Verification task:** V-UI-010: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_UI_UX_Specification_Document_v0.1.html


### `UI-011` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: UI-011 GST/Statutory GST setup, period preparation, file generation and result import M16
- **Verification task:** V-UI-011: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_UI_UX_Specification_Document_v0.1.html


### `UI-012` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: UI-012 Migration Import File select → mapping → validation → preview → commit → reconciliation M17
- **Verification task:** V-UI-012: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_UI_UX_Specification_Document_v0.1.html, NiAv_UX_Specification_v0.2.html


### `UI-013` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: UI-013 Users/Roles User, role, rights, device/pairing administration M18/M19
- **Verification task:** V-UI-013: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_UI_UX_Specification_Document_v0.1.html


### `UI-014` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: UI-014 Licence Trial/licence state, activation/import of signed licence M20
- **Verification task:** V-UI-014: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_UI_UX_Specification_Document_v0.1.html


### `UI-015` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: UI-015 Print/Share Output preview, printer/share target, UPI QR M21
- **Verification task:** V-UI-015: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_UI_UX_Specification_Document_v0.1.html


### `UI-016` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: UI-016 Backup/Sync Backup/restore, LAN sync, remote operation-file exchange, conflicts M22
- **Verification task:** V-UI-016: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_UI_UX_Specification_Document_v0.1.html, NiAv_UX_Specification_v0.2.html


### `UI-017` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: UI-017 Preferences Language, UI customization, defaults and shortcuts M02/M23
- **Verification task:** V-UI-017: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_UI_UX_Specification_Document_v0.1.html


### `UI-018` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: UI-018 Help/Support Help topics and user-mediated support sharing M24
- **Verification task:** V-UI-018: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_UI_UX_Specification_Document_v0.1.html


### `UX-001` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: UX-001 Form Sectioned forms, sticky primary action, inline validation, preserve draft on error. All entry screens
- **Verification task:** V-UX-001: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_UI_UX_Specification_Document_v0.1.html


### `UX-002` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: UX-002 Grid Keyboard-friendly row entry, duplicate-row action, visible totals and error markers. Voucher/import grids
- **Verification task:** V-UX-002: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_UI_UX_Specification_Document_v0.1.html


### `UX-003` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: UX-003 Picker Search-first picker with code/barcode/alias and recent/favourite options. Masters/vouchers
- **Verification task:** V-UX-003: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_UI_UX_Specification_Document_v0.1.html


### `UX-004` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: UX-004 Destructive action Confirm with consequence; require reason where audit policy requires. Cancel/delete/reversal
- **Verification task:** V-UX-004: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_UI_UX_Specification_Document_v0.1.html


### `UX-005` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: UX-005 Import Progressive disclosure: file → mapping → validation → preview → commit. M16/M17/M22
- **Verification task:** V-UX-005: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_UI_UX_Specification_Document_v0.1.html


### `UX-006` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: UX-006 Conflict Show both local/remote context and safe resolution actions; never silently overwrite. M19/M22
- **Verification task:** V-UX-006: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_UI_UX_Specification_Document_v0.1.html


### `UX-007` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: UX-007 Offline Persistent but non-alarming offline indicator; distinguish local save from sync state. All
- **Verification task:** V-UX-007: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_UI_UX_Specification_Document_v0.1.html


### `UX-008` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: UX-008 Localization Resource-based labels/errors; native-script input; avoid text embedded in icons. M02
- **Verification task:** V-UX-008: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_UI_UX_Specification_Document_v0.1.html


### `UX-009` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: UX-009 Accessibility Touch targets, contrast, scalable text, focus order, error announcement. All
- **Verification task:** V-UX-009: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_UI_UX_Specification_Document_v0.1.html
