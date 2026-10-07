<!-- Part 4 of 6 of 00_resume_baseline_and_traceability.md — read in order; see 00_resume_baseline_and_traceability.SPLIT_INDEX.md -->
### `O-15` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: D-10 / O-06 / O-15 / OD-007 Simple vs Advanced boundary Simple (R1a): masters, P1 dual+accounting vouchers, Delivery Note, Stock Transfer/Journal, basic quotation/order, Quick Bill, search, core reports, GST reports, Excel import/export, backup, en/hi/gu, 1 device. Advanced (R1b+): all Simple + multi-user/roles, approvals, document-flow automation, Material Issue/Receive, batch/expiry, price lists, multi-godown reports, LAN/hotspot + file sync, audit/admin tools Decided: proposed value G5
- **Verification task:** V-O-15: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_Sync_Protocol_Specification_v0.1.html


### `O-FG` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: O-FG Closed out of scope. NiAv_Functional_Requirements_Input_Data_v0.5.html 2026-10-01T14:14:07
- **Verification task:** V-O-FG: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `O-FG-001` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: FG-001 Integration model NIAV-ZCP §2A; NIAV-MPL §2 Partial Level 0–5 integration is defined, but there is no single acceptance rule for when a file workflow is sufficient versus when an API is required. Scope drift; API-first assumptions can return. Adopt Levels 0–4 as the default V1 completion path; Level 5 is an optional automation layer. Record input, validation, export, submission, response import, reconciliation and audit trail for every external workflow. Promote only after owner decision. P1 D-FG-001 / O-FG-001 Workflow acceptance tests
- **Verification task:** V-O-FG-001: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html


### `O-FG-002` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: O-10 / O-FG-002 / O-FG-003 E-invoice / e-way bill Stay in R3 as JSON export/manual upload (Level 0-4); capture IRN/ack/e-way fields in data model from R1a; GST return JSON stays R1a Decided: proposed value G3 G0 Evidence still required — owner confirmed action: Owner confirmed: Attach official schema/version evidence and update verification logs.
- **Verification task:** V-O-FG-002: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Data_Schema_Specification_v0.1.html, NiAv_Database_Schema_Document_v0.1.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Release_and_Support_Playbook_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html, NiAv_UX_Specification_v0.2.html


### `O-FG-003` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: O-10 / O-FG-002 / O-FG-003 E-invoice / e-way bill Stay in R3 as JSON export/manual upload (Level 0-4); capture IRN/ack/e-way fields in data model from R1a; GST return JSON stays R1a Decided: proposed value G3 G0 Evidence still required — owner confirmed action: Owner confirmed: Attach official schema/version evidence and update verification logs.
- **Verification task:** V-O-FG-003: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Data_Schema_Specification_v0.1.html, NiAv_Database_Schema_Document_v0.1.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Release_and_Support_Playbook_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html, NiAv_UX_Specification_v0.2.html


### `O-FG-005` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: O-FG-005 Matching tolerance Auto-match only if amount exact (0 paise) AND reference unique; otherwise suggestions with date window +/-3 days (cheques +/-7); user always confirms; CSV/XLSX first, PDF later Decided: proposed value R2
- **Verification task:** V-O-FG-005: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_Database_Schema_Document_v0.1.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html


### `O-FG-006` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: O-FG-006 / A-FG-006 / O-13 Tally/Busy native import V1/R2: Excel import with documented templates; native adapters = R3 feasibility; FG-006 marked Deferred Decided: proposed value G4 G0 Deferred — R3: Owner confirmed deferment: Confirm the R3 feasibility gate and evidence required. G0 Decided: Replace V1 native-import promise with the Excel-template boundary.
- **Verification task:** V-O-FG-006: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html


### `O-FG-007` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: O-FG-007 / O-FG-008 TDS/TCS deferred; PF/ESI and payroll out of scope TDS/TCS deferred to later release; PF/ESI and payroll out of scope; remove from V1 scope text and RTM Decided: proposed value G0 G0 Deferred — Later release: Owner confirmed deferment: Confirm the later-release gate for TDS/TCS and removal from V1 traceability. G0 Decided: Make V1 text authoritative: TDS/TCS later release; PF/ESI/payroll out of scope.
- **Verification task:** V-O-FG-007: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html


### `O-FG-008` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: O-FG-007 / O-FG-008 TDS/TCS deferred; PF/ESI and payroll out of scope TDS/TCS deferred to later release; PF/ESI and payroll out of scope; remove from V1 scope text and RTM Decided: proposed value G0 G0 Deferred — Later release: Owner confirmed deferment: Confirm the later-release gate for TDS/TCS and removal from V1 traceability. G0 Decided: Make V1 text authoritative: TDS/TCS later release; PF/ESI/payroll out of scope.
- **Verification task:** V-O-FG-008: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html


### `O-FG-009` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: O-FG-009 Manual remote operation files Signed + encrypted .niavops batch with company_id, device_id, seq range, dependencies; split at 10 MB; preview, atomic apply, acknowledgement file; replay detection by op_id and device+seq Decided: proposed value S1
- **Verification task:** V-O-FG-009: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Sync_Protocol_Specification_v0.1.html, NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html


### `O-FG-010` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: FG-010 User-selected external/cloud backup NIAV-ZCP M22; NIAV-MPL §2 Partial User-selected external storage/file-provider workflows are supported; managed cloud backup service is deferred. Scheduling, provider permissions and restore semantics need detail. Use Android document/file-provider selection and portable encrypted backups. Create backup → user selects destination → manifest/version → explicit restore validation/migration → SEC reactivation checks. P1 O-FG-010 Backup/restore matrix
- **Verification task:** V-O-FG-010: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html


### `O-FG-011` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: O-FG-011 Payment reminders Prepare -> preview -> user-initiated share; status Prepared / Sent-by-user / Not-sent per item Decided: proposed value R1b
- **Verification task:** V-O-FG-011: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html


### `O-FG-012` — Active P1; deferred P2

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: FG-012 External/manual UPI licence payment NIAV-REG M20.5; NIAV-ZCP §7; NIAV-SEC §3 Partial Offline signed licences are core; in-app payment gateways are excluded; external/manual payment can precede key issuance. Payment-to-licence operational handoff is unspecified. Use payment instructions/UPI QR outside the app, then issue/import a signed licence key. Customer pays externally → operator verifies → signed licence issued → customer imports → SEC verifies. P1/P2 D-FG-012 / O-FG-012 Licence issuance procedure + audit trail Resolved: reissue limit - 20 (Decided: owner value)
- **Verification task:** V-O-FG-012: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html


### `O-FG-013` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: FR-COM-005 Common Money values shall be entered and stored without binary floating-point ambiguity; quantity precision shall follow configured unit rules. Amount; rate; discount; tax; quantity; precision Input → normalized value Precision/rounding rules must be defined before implementation of each calculation domain. Numeric keypad; locale-aware separators; explicit rounding display where applicable. Accounting, stock and GST calculations. P1 MPL architecture; ZCP stack O-FG-013 Resolved: (1) Methods: Weighted Average and FIFO only. (2) Item overrides group; default Weighted Average. (3) Method locked after first posted stock movement; no change in V1. (4) Negative stock allowed with warning; no-layer issues costed at last known cost; no retro revaluation in V1. (5) Period lock by date; unlock needs right + reason + audit. (6) Orders never reserve stock (D-M6 = No). (7) Golden ledgers: opening, purchase, sale, returns, adjustment, negative-stock sale, lock/unlock (Decided: proposed value) Resolved: Money INTEGER paise. Quantity INTEGER x10^4 (per-unit display precision: pcs 0, kg/litre 3, other <=4). Line amount = round-half-up(qty x rate / 10^4); invoice round-off separate ledger line to nearest rupee. Stock value in paise; unit cost derived. IDs UUIDv7 TEXT. Dates ISO TEXT; timestamps INTEGER epoch ms UTC (Decided: proposed value)
- **Verification task:** V-O-FG-013: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `O-FG-014` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: FR-COM-003 Common The system shall support Draft/Save/Cancel/Alter/Review/Approve/Reject/Post states where the relevant module defines them. State; remarks; actor; timestamp State transition Only permitted transitions; approval/posting rules configurable where specified. Buttons/actions appropriate to role; no destructive hidden actions. Workflow, posting, audit and document lineage. P1 REG M04/M09/M10/M18; SEC O-FG-014 Resolved: Verify GST/e-invoice/e-way schemas from official sources; record in verification logs (Decided: owner value)
- **Verification task:** V-O-FG-014: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `O-FG-015` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: OD-DB-005 / O-FG-015 Attachment storage and file types Allowed: JPEG, PNG, PDF; max 5 MB each; images downscaled; magic-byte validation; never executed; app-private storage, per-file AES-GCM with keys wrapped by DB key. Imports: .xlsx/.csv only; 10 MB and 50,000-row caps Decided: proposed value G1
- **Verification task:** V-O-FG-015: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html, NiAv_Data_Schema_Specification_v0.1.html, NiAv_Database_Schema_Document_v0.1.html, NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html


### `O-M` — Active implementation

- **Implementation task:** Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: O-M Closed valuation-method matrix is weighted average or FIFI applicable at item master level or item group level, locked when a transaction is done, Golden ledgers for opening stock, purchase, sale, returns, adjustments - > recommendation needed by AI tool and to be verified by owner, negative stock allowed, rounding - standard functionality and period locks - yes, once locked, provision to unlock again by authorised user NiAv_Fit-Gap_Analysis_Workaround_Register_v0.5.html 2026-10-01T14:15:11
- **Verification task:** V-O-M: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.
- **Source references:** NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html

