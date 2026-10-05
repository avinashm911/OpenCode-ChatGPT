# OpenCode G0 resume handoff

Date: 2026-10-03
Project: `E:\NiavERP v2 OpenAI\niaverp`
Prompt pack: `E:\NiavERP v2 OpenAI\NiAv_G0_Prompts_Pack_v0.9.md`

## Current verified baseline

- Existing G0 record: `docs/g0/G0_CONDITIONAL_OR_BLOCKED.md`.
- Existing pending-input authority: `docs/g0/PENDING_INPUTS.md`.
- Existing test summary: `docs/g0/TEST_SUMMARY.json`.
- Existing RTM/regression records: `docs/g0/RTM_EXECUTION_RESULT.md` and `docs/g0/REGRESSION_RESULT.md`.
- The prior recorded baseline is 94 tests passed, 0 failed, with host-only limitations explicitly recorded.
- The local checksum verifier was re-run against the two recorded representative files and passed with exit code 0. This does not close APK/ZIP or channel evidence.
- No owner evidence was found for the pending device, printer, legal, release-channel, SQLCipher, GST-source, or statutory-schema rows.
- The Flutter SDK is referenced by `niaverp/android/local.properties`; it is not on PATH. Use that configured SDK path or the user's working Flutter environment. Do not interpret an SDK process/access failure as a test failure.

## Mandatory boundary

Do not edit the 15 HTML requirements documents, any workbook/register, or their historical rows. Do not invent owner decisions, device results, printer results, legal approval, schema versions, APK/ZIP hashes, delivery receipts, or library licences. A missing input remains `PENDING-INPUT`. A host test cannot close a physical-device, physical-printer, legal-review, statutory-source, or real-channel row.

## Resume procedure

1. Work from `E:\NiavERP v2 OpenAI\niaverp` and read the files listed above before changing anything.
2. Inspect any owner-input files supplied after this handoff. Accept an input only when it contains the required identity, source/version, result, date, or receipt specified in `docs/g0/PENDING_INPUTS.md`.
3. For each accepted input, update only the relevant G0 evidence file and `docs/g0/PENDING_INPUTS.md`. Preserve PASS rows and retain the original evidence trail.
4. Run the smallest affected verification first, then run the full reproducible suite:

```powershell
$flutter = '<configured-flutter-sdk>\bin\flutter.bat'
& $flutter --version
& $flutter analyze
& $flutter test
& $flutter test test\print test\release
powershell -ExecutionPolicy Bypass -File docs\g0\evidence\release\verify_checksums.ps1 -Artifact <artifact> -ExpectedHex <64-hex>
```

5. For real Android evidence, use `docs/g0/evidence/android/DEVICE_TEST_PROCEDURE.md` on both an assigned API-26 device and an assigned current-Android device. Attach logs/screenshots; never mark the row PASS from an emulator description alone.
6. For printers, first freeze the OD-FD-006 matrix with at least the required 58 mm, 80 mm, and PDF/A4-A5 targets, then attach physical test results to `PRINTER_TEST_SHEET.md`.
7. For legal evidence, record the named reviewer, review date, Act/source version, retention/deletion decision, and signed disposition in `LEGAL_CONTROL_MAP_DRAFT.md`.
8. For release evidence, verify the actual release APK and ZIP bytes, then attach real WhatsApp, email, and hosted-link receipts. Do not use the template counter APK as a NiAvERP release artifact.
9. Rerun Phases 7 and 8 after G0-scope work. Issue `docs/g0/G0_UNCONDITIONAL_SIGNOFF.md` when G0-scoped checks pass and no G0-scoped FAIL or document finding remains. Carry Android, printer, legal, production SQLCipher, statutory-schema, APK/ZIP and channel rows as downstream-gate PENDING-INPUT; do not treat them as G0 blockers.

## Exact OpenCode instruction

Run this from the project directory:

```text
Read NiAv_G0_Prompts_Pack_v0.9.md and docs/g0/PENDING_INPUTS.md, TEST_SUMMARY.json, RTM_EXECUTION_RESULT.md, REGRESSION_RESULT.md, VERIFICATION_EXECUTION.md, and G0_UNCONDITIONAL_SIGNOFF.md. Inspect all owner-input files currently present in this project. Resume only G0-scope work for which real evidence exists. Do not edit HTML requirements documents, workbooks, or registers. Do not invent or simulate device, printer, legal, statutory-schema, SQLCipher-licence, APK/ZIP, or channel evidence. Run the affected host tests and checksum verifier where applicable. Update only docs/g0 evidence outputs and PENDING_INPUTS.md. Keep downstream-gate evidence separate and do not block G0 baseline acceptance on it.
```

## CLI continuation form

If the previous OpenCode session is still resumable:

```powershell
cd "E:\NiavERP v2 OpenAI\niaverp"
opencode run --continue "Read ..\NiAv_G0_Prompts_Pack_v0.9.md and docs/g0/OPEN_CODE_G0_RESUME_HANDOFF.md. Follow the handoff exactly, inspect current owner inputs, run only reproducible checks, update only allowed docs/g0 evidence outputs, and rerun Phases 7-8. Do not hallucinate evidence or edit HTML/workbooks/registers. Treat downstream device, printer, legal, production SQLCipher, statutory-schema, APK/ZIP and channel evidence as later-gate items, not G0 blockers."
```

If no prior session can be continued, start a new OpenCode run in the same directory with the exact instruction above. The existing `docs/g0` records are the restart checkpoint.
