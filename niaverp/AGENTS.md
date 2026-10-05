# NiAvERP OpenCode agent instructions

## Project scope

NiAvERP is a standalone, offline-first Android APK. The implementation is
already in progress. Before changing code, inspect the existing phase reports
and preserve completed work; do not treat the repository as an empty scaffold.
The local application backend inside the Flutter app includes:
database, migrations, repositories, domain services, validation, audit,
backup/restore, import/export, search and platform adapters.

Do not create a cloud backend, REST service, hosted database or telemetry
dependency unless a later approved project decision explicitly authorises it.

## Required reading before every task

Read these files before changing code:

1. `../docs/IMPLEMENTATION_EXECUTION_STRATEGY.md`
2. `../docs/opencode_master_prompts/README.md`
3. `../docs/opencode_master_prompts/SOURCE_INVENTORY.md`
4. `../docs/opencode_master_prompts/TRACEABILITY_MATRIX.md` or the current
   prompt's traceability slice
5. `DECISIONS.md`
6. `../docs/g0/PENDING_INPUTS.md`
7. The relevant principal HTML documents in `..\`
8. The previous phase report under `../docs/implementation/`, if present

The current prompt pack is v1.1. The old v0.9 pack was deleted. Historical
phase reports may mention old prompt paths; preserve those reports and use the
v1.1 migration map for continuation.

Use the relevant Data Schema, Database Schema, Functional Requirements,
Functional Design, UI/UX, UX, Security, Sync, Release and Test documents for
the current task.

## Authority and no-invention rules

- Active reconciled decisions in the principal documents and decision ledger
  are authoritative; historical rows are history only.
- Never invent fields, voucher types, posting rules, tax treatment, legal
  positions, packages, licences, APIs, permissions, workflow states,
  performance targets, release channels or data-retention rules.
- If a required value is missing or contradictory, stop only the affected
  work, record the exact source ID and owner question in the phase report, and
  continue independent work.
- Never call a mock, host-only test, emulator-only test, public source or
  scaffold result physical, legal, production or delivery evidence.
- Do not edit the 15 principal HTML documents, decision workbooks or source
  registers from implementation work.

## Technical baseline

- Flutter/Dart, CLI-only build and test.
- Android V1, minimum API 26 / Android 8.
- Local encrypted SQLite using the approved SQLCipher-class approach once the
  library/version/licence decision is confirmed.
- Drift is the intended data-access architecture only when its dependency and
  licence choices are confirmed.
- Money is integer paise.
- Quantity is integer ×10^4.
- No floating-point arithmetic for accounting.
- Posted history is immutable; corrections use compensating records/events.
- All material writes require company scope, transaction boundaries, audit and
  operation lineage.

## Explicit V1 exclusions

Do not implement or expose as live capability:

- voice input;
- native Tally/Busy import adapters;
- TDS/TCS in V1;
- PF/ESI and payroll;
- automatic cross-script transliteration;
- direct e-invoice/e-way portal APIs;
- automated WhatsApp/SMS APIs;
- cloud backup or server relay;
- in-place APK downgrade.

Use Excel/CSV mapping for Tally/Busy exports and user-mediated/file-first
statutory workflows where the documents allow them.

## Implementation discipline

Use vertical slices: schema → repository → use case → UI → tests → evidence.
Do not build screens over permanent fake repositories. Keep domain rules out of
widgets. Reuse the shared voucher engine and invoice/report models.

Every task must finish with:

1. changed files;
2. commands and environment;
3. test/analyze results;
4. requirement and traceability IDs;
5. unresolved decisions and downstream pending evidence;
6. the next gate.

Do not claim completion when a test failed. Do not convert PENDING-INPUT into
PASS without the required evidence.

## Continuation rule

The existing baseline reports are authoritative for completed work:

- `../docs/implementation/phase-00.md` — shell and core value objects;
- `../docs/implementation/phase-01.md` — engine-neutral database/repository
  foundation and 128-test state;
- `../docs/implementation/phase-02.md` — M03 masters/onboarding/search and
  166-test state.

Do not rebuild or overwrite completed slices. Verify them, continue only from
their stated next gate, and record any repair separately. Prompt 01 may stop at
the approved SQLCipher/Drift/Keystore decision boundary, but it owns the
continuation of the local backend rather than merely recording evidence.
