# NiAvERP OpenCode master prompt v1.1 — voucher engine and orders

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

## Owned IDs (25)

- `FR-M04-001`
- `FR-M04-002`
- `FR-M04-003`
- `FR-M05-001`
- `FR-M05-002`
- `FR-M05-003`
- `FR-M05-004`
- `FR-M06-001`
- `FR-M06-002`
- `FR-M06-003`
- `FR-M06-004`
- `FR-M06-005`
- `FR-M07-001`
- `FR-M07-002`
- `FR-M07-003`
- `FR-M08-001`
- `FR-M08-002`
- `FR-M08-003`
- `G0-SCH-003`
- `G0-SCH-007`
- `M04`
- `M05`
- `M06`
- `M07`
- `M08`

### `FR-M04-001` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Type name; base type; series links. State: Configured. Validation: Base type must exist; accounting/inventory behavior cannot be changed beyond supported rules.. Interaction: Voucher-type configuration.. Downstream: Controls entry form and posting behavior.. Source requirement: Voucher-type input shall allow predefined types and user-created types derived from a base type.
- **Verification task:** V-FR-M04-001: test required data/input (Type name; base type; series links), state (Configured), validation (Base type must exist; accounting/inventory behavior cannot be changed beyond supported rules.), interaction (Voucher-type configuration.) and downstream effect (Controls entry form and posting behavior.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Database_Schema_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M04-002` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: All numbering fields. State: Configured. Validation: No duplicate active series configuration that can generate same number within its scope; scope rules TBD.. Interaction: Series wizard.. Downstream: Generates document numbers and gap reports.. Source requirement: Series input shall support prefix/suffix/start number/width/separator/restart cycle/manual-vs-auto and duplicate-number checking.
- **Verification task:** V-FR-M04-002: test required data/input (All numbering fields), state (Configured), validation (No duplicate active series configuration that can generate same number within its scope; scope rules TBD.), interaction (Series wizard.) and downstream effect (Generates document numbers and gap reports.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M04-003` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Date; narration; attachment; reference; post-date flag. State: Draft. Validation: Date restrictions, edit/delete locks and post-dated behavior must follow admin policy.. Interaction: Common voucher header.. Downstream: Audit, posting and document lineage.. Source requirement: Common voucher input shall capture date, narration, attachment, reference number and support post-dated entry where permitted.
- **Verification task:** V-FR-M04-003: test required data/input (Date; narration; attachment; reference; post-date flag), state (Draft), validation (Date restrictions, edit/delete locks and post-dated behavior must follow admin policy.), interaction (Common voucher header.) and downstream effect (Audit, posting and document lineage.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M05-001` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Party; invoice date/no.; item rows; qty; rate; discount; tax; charges; round-off; bill reference; godown; payment mode/amount; classification; place of supply. State: Draft → Posted. Validation: Dr/Cr and tax totals must calculate consistently; B2B/B2C, place of supply and GST applicability rules require verification.. Interaction: Fast single-screen and full voucher entry.. Downstream: Sales, stock out, receivable, GST and print/share.. Source requirement: Sales Invoice entry shall capture party, items, quantity, rate, discount, CGST/SGST/IGST, additional charges, round-off, bill-wise reference, godown and payment received.
- **Verification task:** V-FR-M05-001: test required data/input (Party; invoice date/no.; item rows; qty; rate; discount; tax; charges; round-off; bill reference; godown; payment mode/amount; classification; place of supply), state (Draft → Posted), validation (Dr/Cr and tax totals must calculate consistently; B2B/B2C, place of supply and GST applicability rules require verification.), interaction (Fast single-screen and full voucher entry.) and downstream effect (Sales, stock out, receivable, GST and print/share.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M05-002` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Supplier; supplier inv no/date; item rows; tax; freight; other charges; RCM; landed cost. State: Draft → Posted. Validation: Supplier invoice identity and tax rules; landed-cost treatment TBD.. Interaction: Purchase voucher form/import.. Downstream: Purchase, stock in, payable and GST.. Source requirement: Purchase Invoice entry shall capture supplier, supplier invoice number/date, items, taxes, freight/other charges, RCM handling and landed-cost fields if accepted.
- **Verification task:** V-FR-M05-002: test required data/input (Supplier; supplier inv no/date; item rows; tax; freight; other charges; RCM; landed cost), state (Draft → Posted), validation (Supplier invoice identity and tax rules; landed-cost treatment TBD.), interaction (Purchase voucher form/import.) and downstream effect (Purchase, stock in, payable and GST.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M05-003` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Original invoice; return rows; qty; reason; tax reversal. State: Draft → Posted. Validation: Return quantity cannot exceed eligible quantity unless override is explicitly allowed.. Interaction: Return voucher with source-document picker.. Downstream: Stock in, receivable and tax reversal.. Source requirement: Sales Return shall link to original sales document, capture returned quantity and tax reversal.
- **Verification task:** V-FR-M05-003: test required data/input (Original invoice; return rows; qty; reason; tax reversal), state (Draft → Posted), validation (Return quantity cannot exceed eligible quantity unless override is explicitly allowed.), interaction (Return voucher with source-document picker.) and downstream effect (Stock in, receivable and tax reversal.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M05-004` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Original purchase; return rows; qty; reason; tax reversal. State: Draft → Posted. Validation: Return quantity eligibility and tax treatment must be enforced.. Interaction: Return voucher with source-document picker.. Downstream: Stock out, payable and tax reversal.. Source requirement: Purchase Return shall link to original purchase, capture return quantity and tax reversal.
- **Verification task:** V-FR-M05-004: test required data/input (Original purchase; return rows; qty; reason; tax reversal), state (Draft → Posted), validation (Return quantity eligibility and tax treatment must be enforced.), interaction (Return voucher with source-document picker.) and downstream effect (Stock out, payable and tax reversal.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M06-001` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Date; payer/payee ledger; mode; amount; bill allocation; cheque no/date/bank; narration. State: Draft → Posted. Validation: Total allocated cannot exceed permitted amount; cheque fields conditional on mode.. Interaction: Payment form with bill allocation.. Downstream: Cash/bank balance and outstanding settlement.. Source requirement: Payment voucher shall support single/multi-line cash, bank or UPI payments, bill-wise settlement and cheque details.
- **Verification task:** V-FR-M06-001: test required data/input (Date; payer/payee ledger; mode; amount; bill allocation; cheque no/date/bank; narration), state (Draft → Posted), validation (Total allocated cannot exceed permitted amount; cheque fields conditional on mode.), interaction (Payment form with bill allocation.) and downstream effect (Cash/bank balance and outstanding settlement.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M06-002` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Party; mode; amount; advance/reference allocation; cheque details; narration. State: Draft → Posted. Validation: Allocation totals must reconcile to receipt amount.. Interaction: Receipt form.. Downstream: Cash/bank and receivable settlement.. Source requirement: Receipt voucher shall support receipt mode, advance receipts and against-reference allocation.
- **Verification task:** V-FR-M06-002: test required data/input (Party; mode; amount; advance/reference allocation; cheque details; narration), state (Draft → Posted), validation (Allocation totals must reconcile to receipt amount.), interaction (Receipt form.) and downstream effect (Cash/bank and receivable settlement.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M06-003` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: From account; to account; amount; date; reference; narration. State: Draft → Posted. Validation: Source and destination cannot be the same ledger; amount > 0.. Interaction: Contra form.. Downstream: Cash/bank transfer.. Source requirement: Contra voucher shall capture source and destination cash/bank accounts and transfer amount.
- **Verification task:** V-FR-M06-003: test required data/input (From account; to account; amount; date; reference; narration), state (Draft → Posted), validation (Source and destination cannot be the same ledger; amount > 0.), interaction (Contra form.) and downstream effect (Cash/bank transfer.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M06-004` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Lines: ledger; Dr/Cr; amount; tax details; narration; reference. State: Draft → Posted. Validation: Total Dr = total Cr; tax applicability must be valid for account/transaction.. Interaction: Multi-line journal grid.. Downstream: General ledger and reports.. Source requirement: Journal voucher shall support multi-line Dr/Cr adjustments and applicable GST expense entries.
- **Verification task:** V-FR-M06-004: test required data/input (Lines: ledger; Dr/Cr; amount; tax details; narration; reference), state (Draft → Posted), validation (Total Dr = total Cr; tax applicability must be valid for account/transaction.), interaction (Multi-line journal grid.) and downstream effect (General ledger and reports.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M06-005` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Party; note type; amount; reason; GST; reference. State: Draft → Posted. Validation: Tax treatment and original-document linkage where applicable must be defined.. Interaction: Note form.. Downstream: Party balance and GST.. Source requirement: Debit/Credit Note without items shall capture party, reason/charge/discount, amount and GST treatment.
- **Verification task:** V-FR-M06-005: test required data/input (Party; note type; amount; reason; GST; reference), state (Draft → Posted), validation (Tax treatment and original-document linkage where applicable must be defined.), interaction (Note form.) and downstream effect (Party balance and GST.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M07-001` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Party; date/no.; item; qty; godown; order reference; transport/reference data if required. State: Draft → Posted. Validation: Quantity and stock availability follow configured negative-stock policy.. Interaction: Delivery form.. Downstream: Stock out and pending-to-bill tracking.. Source requirement: Delivery Note shall capture party, items, quantities and source order where applicable, without prematurely treating it as an invoice.
- **Verification task:** V-FR-M07-001: test required data/input (Party; date/no.; item; qty; godown; order reference; transport/reference data if required), state (Draft → Posted), validation (Quantity and stock availability follow configured negative-stock policy.), interaction (Delivery form.) and downstream effect (Stock out and pending-to-bill tracking.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M07-002` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: From location; to location; item; qty; date; reference; in-transit data if supported. State: Draft → Posted. Validation: Source ≠ destination; stock policy; in-transit behavior TBD.. Interaction: Transfer form.. Downstream: Location stock balances.. Source requirement: Stock Transfer shall capture source and destination godown/branch, items and quantities.
- **Verification task:** V-FR-M07-002: test required data/input (From location; to location; item; qty; date; reference; in-transit data if supported), state (Draft → Posted), validation (Source ≠ destination; stock policy; in-transit behavior TBD.), interaction (Transfer form.) and downstream effect (Location stock balances.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M07-003` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Item; qty in/out; valuation; reason; source/destination where transform; date. State: Draft → Posted. Validation: Stock and valuation effects depend on valuation-method decision.. Interaction: Stock journal grid.. Downstream: Inventory valuation and reports.. Source requirement: Stock Journal shall capture adjustment/transform lines including wastage, breakage, samples and physical reconciliation.
- **Verification task:** V-FR-M07-003: test required data/input (Item; qty in/out; valuation; reason; source/destination where transform; date), state (Draft → Posted), validation (Stock and valuation effects depend on valuation-method decision.), interaction (Stock journal grid.) and downstream effect (Inventory valuation and reports.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Database_Schema_Document_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M08-001` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Party; items; qty; rate; discount; validity; terms; notes. State: Draft → Open/Converted. Validation: No accounting/stock posting until the relevant conversion stage.. Interaction: Quotation form.. Downstream: M09 conversion and print/share.. Source requirement: Sales quotation/proforma input shall capture party, items, prices, validity date and terms and support conversion.
- **Verification task:** V-FR-M08-001: test required data/input (Party; items; qty; rate; discount; validity; terms; notes), state (Draft → Open/Converted), validation (No accounting/stock posting until the relevant conversion stage.), interaction (Quotation form.) and downstream effect (M09 conversion and print/share.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M08-002` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Party; item rows; qty; rate; due date; terms; references. State: Draft → Open/Partially fulfilled/Closed/Cancelled. Validation: Status transition and reservation behavior are subject to O-09.. Interaction: Order form.. Downstream: Pending orders and conversion.. Source requirement: Sales Order and Purchase Order input shall capture party, items, quantities, rates and due dates, with partial-fulfilment tracking.
- **Verification task:** V-FR-M08-002: test required data/input (Party; item rows; qty; rate; due date; terms; references), state (Draft → Open/Partially fulfilled/Closed/Cancelled), validation (Status transition and reservation behavior are subject to O-09.), interaction (Order form.) and downstream effect (Pending orders and conversion.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M08-003` — Deferred by priority P2

- **Implementation task:** Do not implement this item in the current release. Record priority P2 and gate not stated, and keep it out of active acceptance criteria. Source: Purchase quotation input shall record supplier quotes; comparison is deferred unless accepted.
- **Verification task:** V-FR-M08-003: priority/gate ledger confirms deferred status (P2, not stated); no active V1 acceptance test is allowed.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `G0-SCH-003` — Active schema change

- **Implementation task:** Implement the approved schema change exactly, including migration, compatibility, rollback and tests. Source: G0-SCH-003 — Bill-wise settlement — bill_allocation with source/settlement lineage, amount, date, status and operation id — FR-M06
- **Verification task:** V-G0-SCH-003: migration applies on a clean and existing database, preserves data, supports compatibility checks and has rollback evidence.
- **Source references:** NiAv_Data_Schema_Specification_v0.1.html, NiAv_Database_Schema_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html


### `G0-SCH-007` — Active schema change

- **Implementation task:** Implement the approved schema change exactly, including migration, compatibility, rollback and tests. Source: G0-SCH-007 — Voucher-line discount — voucher_line.discount_amount_paise and discount_rate_bps with calculation rule — FRD voucher lines
- **Verification task:** V-G0-SCH-007: migration applies on a clean and existing database, preserves data, supports compatibility checks and has rollback evidence.
- **Source references:** NiAv_Data_Schema_Specification_v0.1.html, NiAv_Database_Schema_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html, NiAv_UX_Specification_v0.2.html


### `M04` — Active implementation

- **Implementation task:** Implement only the P1 sub-modules of M04 in the current release. Enumerate every P2/P3/TBC sub-module from the Modules Register as deferred or blocked with its gate; do not silently omit or implement them. Module priority: P1. Gate: not stated. Source: M04 — Voucher Engine & Multi-Series Numbering [U2][U7] — P1
- **Verification task:** V-M04: module acceptance test covers each registered sub-module, persistence/restart and integration with its dependent module.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html


### `M05` — Active implementation

- **Implementation task:** Implement only the P1 sub-modules of M05 in the current release. Enumerate every P2/P3/TBC sub-module from the Modules Register as deferred or blocked with its gate; do not silently omit or implement them. Module priority: P1. Gate: not stated. Source: M05 — Dual Vouchers (Accounting + Inventory) — P1
- **Verification task:** V-M05: module acceptance test covers each registered sub-module, persistence/restart and integration with its dependent module.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Functional_Requirements_Input_Data_v0.1.html


### `M06` — Active implementation

- **Implementation task:** Implement only the P1 sub-modules of M06 in the current release. Enumerate every P2/P3/TBC sub-module from the Modules Register as deferred or blocked with its gate; do not silently omit or implement them. Module priority: P1. Gate: not stated. Source: M06 — Accounting Vouchers — P1
- **Verification task:** V-M06: module acceptance test covers each registered sub-module, persistence/restart and integration with its dependent module.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Functional_Requirements_Input_Data_v0.1.html


### `M07` — Active P1; deferred P2

- **Implementation task:** Implement only the P1 sub-modules of M07 in the current release. Enumerate every P2/P3/TBC sub-module from the Modules Register as deferred or blocked with its gate; do not silently omit or implement them. Module priority: P1/P2. Gate: not stated. Source: M07 — Inventory Vouchers — P1/P2
- **Verification task:** V-M07: module acceptance test covers each registered sub-module, persistence/restart and integration with its dependent module.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Database_Schema_Document_v0.1.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_Requirements_Traceability_Matrix_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html, NiAv_UX_Specification_v0.2.html


### `M08` — Active P1; deferred P2

- **Implementation task:** Implement only the P1 sub-modules of M08 in the current release. Enumerate every P2/P3/TBC sub-module from the Modules Register as deferred or blocked with its gate; do not silently omit or implement them. Module priority: P1/P2. Gate: not stated. Source: M08 — Order & Quotation Processing [U11] — P1/P2
- **Verification task:** V-M08: module acceptance test covers each registered sub-module, persistence/restart and integration with its dependent module.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html
