# NiAvERP OpenCode master prompt v1.1 — masters and search continuation

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

## Masters/search continuation directive

Treat phase-02 masters/search as completed baseline. Verify it, repair only evidence-backed gaps, and implement only the explicitly owned P1 items not already present. Do not recreate m009 or replace existing repository tests.

## Owned IDs (12)

- `FR-M03-001`
- `FR-M03-002`
- `FR-M03-003`
- `FR-M03-004`
- `FR-M03-005`
- `FR-M03-006`
- `FR-M03-007`
- `FR-M03-008`
- `FR-M03-009`
- `FR-M12-001`
- `M03`
- `M12`

### `FR-M03-001` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Group name; parent group; classification. State: Active. Validation: No circular hierarchy; group must be valid for ledger creation.. Interaction: Form with parent picker.. Downstream: Ledger classification and reports.. Source requirement: Account Group input shall support predefined primary groups and user-defined sub-groups.
- **Verification task:** V-FR-M03-001: test required data/input (Group name; parent group; classification), state (Active), validation (No circular hierarchy; group must be valid for ledger creation.), interaction (Form with parent picker.) and downstream effect (Ledger classification and reports.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Database_Schema_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M03-002` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Ledger name; group; opening Dr/Cr; bill-wise; credit limit/days; GST; contact/address; bank. State: Active. Validation: Opening balance side must be explicit; duplicate ledger handling required.. Interaction: Form; quick-add from voucher.. Downstream: Accounting postings, outstanding and GST.. Source requirement: Ledger input shall support group, opening balance Dr/Cr, bill-wise flag, credit limit/days, GST details, contact, address and bank details.
- **Verification task:** V-FR-M03-002: test required data/input (Ledger name; group; opening Dr/Cr; bill-wise; credit limit/days; GST; contact/address; bank), state (Active), validation (Opening balance side must be explicit; duplicate ledger handling required.), interaction (Form; quick-add from voucher.) and downstream effect (Accounting postings, outstanding and GST.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M03-003` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Party role; ledger; GSTIN; state; price list; salesperson; terms; addresses. State: Active. Validation: GST/identity formats are configurable/VERIFY; customer/supplier role must be explicit.. Interaction: Party form; quick-add.. Downstream: Sales/purchase vouchers and outstanding.. Source requirement: Party input shall support customer/supplier ledger linkage, GSTIN, state, price list, salesperson, credit terms and multiple addresses.
- **Verification task:** V-FR-M03-003: test required data/input (Party role; ledger; GSTIN; state; price list; salesperson; terms; addresses), state (Active), validation (GST/identity formats are configurable/VERIFY; customer/supplier role must be explicit.), interaction (Party form; quick-add.) and downstream effect (Sales/purchase vouchers and outstanding.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M03-004` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Bank ledger; account no.; IFSC; UPI ID. State: Active. Validation: Format rules must be defined/verified before release.. Interaction: Bank master form.. Downstream: Payment/receipt/contra and UPI QR.. Source requirement: Bank-account input shall support bank ledger, account number, IFSC and UPI ID.
- **Verification task:** V-FR-M03-004: test required data/input (Bank ledger; account no.; IFSC; UPI ID), state (Active), validation (Format rules must be defined/verified before release.), interaction (Bank master form.) and downstream effect (Payment/receipt/contra and UPI QR.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M03-005` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Name; alias; code; barcode; group; unit; HSN/SAC; GST rate; MRP; sale/purchase price; min/max; reorder; opening qty/rate/value. State: Active. Validation: Unit, tax and numeric precision must be valid; duplicate code/barcode policy required.. Interaction: Item form; barcode scan; quick-add.. Downstream: Inventory, billing, GST and reports.. Source requirement: Item input shall support name, alias, code, barcode, group, unit, HSN/SAC, GST rate, MRP, sale/purchase price, stock controls and opening stock.
- **Verification task:** V-FR-M03-005: test required data/input (Name; alias; code; barcode; group; unit; HSN/SAC; GST rate; MRP; sale/purchase price; min/max; reorder; opening qty/rate/value), state (Active), validation (Unit, tax and numeric precision must be valid; duplicate code/barcode policy required.), interaction (Item form; barcode scan; quick-add.) and downstream effect (Inventory, billing, GST and reports.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M03-006` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Unit name; symbol; base unit; conversion factor. State: Active. Validation: Conversion factor must be positive and deterministic.. Interaction: Unit master form.. Downstream: Quantity normalization in vouchers and reports.. Source requirement: Unit input shall support simple and compound units and conversion factors.
- **Verification task:** V-FR-M03-006: test required data/input (Unit name; symbol; base unit; conversion factor), state (Active), validation (Conversion factor must be positive and deterministic.), interaction (Unit master form.) and downstream effect (Quantity normalization in vouchers and reports.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M03-007` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Name; code; address/notes; opening stock linkage. State: Active. Validation: Location identifiers unique within company; branch scope TBD.. Interaction: Godown form.. Downstream: Stock balances and transfers.. Source requirement: Godown/location input shall support locations and opening stock by location.
- **Verification task:** V-FR-M03-007: test required data/input (Name; code; address/notes; opening stock linkage), state (Active), validation (Location identifiers unique within company; branch scope TBD.), interaction (Godown form.) and downstream effect (Stock balances and transfers.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M03-008` — Deferred by priority P2

- **Implementation task:** Do not implement this item in the current release. Record priority P2 and gate not stated, and keep it out of active acceptance criteria. Source: Optional batch/expiry input shall capture batch number, manufacturing date and expiry date where batch/expiry is enabled.
- **Verification task:** V-FR-M03-008: priority/gate ledger confirms deferred status (P2, not stated); no active V1 acceptance test is allowed.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M03-009` — Deferred by priority P2

- **Implementation task:** Do not implement this item in the current release. Record priority P2 and gate not stated, and keep it out of active acceptance criteria. Source: Price-list input shall support multiple lists, party-wise applicability and effective-date pricing.
- **Verification task:** V-FR-M03-009: priority/gate ledger confirms deferred status (P2, not stated); no active V1 acceptance test is allowed.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M12-001` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Query; entity type; filters; sort. State: Search input. Validation: No network required; fuzzy/transliteration remains conditional.. Interaction: Type-ahead search/picker.. Downstream: Faster data entry and navigation.. Source requirement: Global and in-form search shall accept name, alias, code, barcode, partial text, mobile number and voucher number; native-script matching is conditional.
- **Verification task:** V-FR-M12-001: test required data/input (Query; entity type; filters; sort), state (Search input), validation (No network required; fuzzy/transliteration remains conditional.), interaction (Type-ahead search/picker.) and downstream effect (Faster data entry and navigation.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `M03` — Active implementation

- **Implementation task:** Implement only the P1 sub-modules of M03 in the current release. Enumerate every P2/P3/TBC sub-module from the Modules Register as deferred or blocked with its gate; do not silently omit or implement them. Module priority: P1. Gate: not stated. Source: M03 — Masters (Accounts, Inventory, Others) — P1
- **Verification task:** V-M03: module acceptance test covers each registered sub-module, persistence/restart and integration with its dependent module.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html


### `M12` — Active implementation

- **Implementation task:** Implement only the P1 sub-modules of M12 in the current release. Enumerate every P2/P3/TBC sub-module from the Modules Register as deferred or blocked with its gate; do not silently omit or implement them. Module priority: P1. Gate: not stated. Source: M12 — Universal Search [U6] — P1
- **Verification task:** V-M12: module acceptance test covers each registered sub-module, persistence/restart and integration with its dependent module.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html
