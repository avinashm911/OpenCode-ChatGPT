# NiAvERP OpenCode master prompt v1.1 — onboarding and localisation

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

## Onboarding continuation directive

Implement the unfinished M01/M02 work over the existing shell and repositories. Preserve phase-00 and phase-02 code; do not rebuild the Parties & Items or masters slice.

## Owned IDs (7)

- `FR-M01-001`
- `FR-M01-002`
- `FR-M01-003`
- `FR-M02-001`
- `FR-M02-002`
- `M01`
- `M02`

### `FR-M01-001` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Name; address; state; PIN; contact; GSTIN; PAN; FY start; books-begin; currency. State: Draft → Active. Validation: Format checks for identifiers; current statutory validation rules remain VERIFY.. Interaction: Onboarding form; progressive sections.. Downstream: Company context for every subsequent input.. Source requirement: Company creation shall capture company identity, address, state, PIN, contact, GSTIN, PAN, financial-year start, books-begin date and base currency (INR).
- **Verification task:** V-FR-M01-001: test required data/input (Name; address; state; PIN; contact; GSTIN; PAN; FY start; books-begin; currency), state (Draft → Active), validation (Format checks for identifiers; current statutory validation rules remain VERIFY.), interaction (Onboarding form; progressive sections.) and downstream effect (Company context for every subsequent input.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M01-002` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Feature flags. State: Configured. Validation: Dependencies must be respected; unsupported/deferred features must not be exposed as active.. Interaction: Toggle/configuration screen.. Downstream: Controls fields and workflows throughout the app.. Source requirement: Company configuration shall capture feature toggles for inventory, GST, batch, expiry, serial numbers, multi-godown, cost centres, bill-wise and approvals.
- **Verification task:** V-FR-M01-002: test required data/input (Feature flags), state (Configured), validation (Dependencies must be respected; unsupported/deferred features must not be exposed as active.), interaction (Toggle/configuration screen.) and downstream effect (Controls fields and workflows throughout the app.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M01-003` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Series; prefix; suffix; start no.; width; separator; restart cycle; manual/auto; print format; defaults. State: Configured. Validation: Duplicate numbering and invalid pattern checks; GST numbering rule remains VERIFY.. Interaction: Series setup form.. Downstream: Determines voucher creation defaults and numbering.. Source requirement: Voucher-series configuration shall accept numbering pattern, print format, mandatory fields, narration requirement and default ledgers.
- **Verification task:** V-FR-M01-003: test required data/input (Series; prefix; suffix; start no.; width; separator; restart cycle; manual/auto; print format; defaults), state (Configured), validation (Duplicate numbering and invalid pattern checks; GST numbering rule remains VERIFY.), interaction (Series setup form.) and downstream effect (Determines voucher creation defaults and numbering.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M02-001` — Active implementation

- **Implementation task:** Implement the source requirement exactly. Required input/data: Language; native-script text. State: User setting / Input. Validation: Text must be stored without destructive transliteration; launch language set is decided.. Interaction: Language switch; native keyboard/input.. Downstream: All user-visible labels, master names and documents.. Source requirement: The system shall allow runtime language selection among English, Hindi and Gujarati and permit native-script entry.
- **Verification task:** V-FR-M02-001: test required data/input (Language; native-script text), state (User setting / Input), validation (Text must be stored without destructive transliteration; launch language set is decided.), interaction (Language switch; native keyboard/input.) and downstream effect (All user-visible labels, master names and documents.); include persistence/restart and at least one invalid/denied case.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html


### `FR-M02-002` — Excluded

- **Implementation task:** Do not implement this item. Add a negative test proving the excluded capability is not exposed. Preserve the source decision: Rejected by owner; no R3 gate
- **Verification task:** V-FR-M02-002: static scan plus negative UI/domain test confirms the excluded feature is absent.
- **Source references:** NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html, NiAv_UX_Specification_v0.2.html


### `M01` — Active implementation

- **Implementation task:** Implement only the P1 sub-modules of M01 in the current release. Enumerate every P2/P3/TBC sub-module from the Modules Register as deferred or blocked with its gate; do not silently omit or implement them. Module priority: P1. Gate: not stated. Source: M01 — Onboarding, Company & Configuration — P1
- **Verification task:** V-M01: module acceptance test covers each registered sub-module, persistence/restart and integration with its dependent module.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Functional_Design_Document_v0.1.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html


### `M02` — Active implementation

- **Implementation task:** Implement only the P1 sub-modules of M02 in the current release. Enumerate every P2/P3/TBC sub-module from the Modules Register as deferred or blocked with its gate; do not silently omit or implement them. Module priority: P1. Gate: not stated. Source: M02 — Language & Localisation [U1] — P1
- **Verification task:** V-M02: module acceptance test covers each registered sub-module, persistence/restart and integration with its dependent module.
- **Source references:** NiAv_ Modules & Sub-Modules Register v0.4.html, NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html, NiAv_ Universal Master Plan v0.2.html, NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html, NiAv_Functional_Requirements_Input_Data_v0.1.html, NiAv_UI_UX_Specification_Document_v0.1.html
