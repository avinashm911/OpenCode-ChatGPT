# G0 PENDING-INPUTS and DEFERRED register — Phase 7 (v0.9)

Date (UTC): 2026-10-03
Prompt authority: `NiAv_G0_Prompts_Pack_v0.9.md` Phase 7
Status vocabulary: PASS / FAIL / PENDING-INPUT / DEFERRED (items); COMPLETE / PARTIAL / FAIL (phases). PENDING-INPUT rows retain their own gate; downstream-gate rows do not block G0 baseline acceptance.
Source registers (`outputs/…/*.xlsx`, HTML, workbooks) are read-only and untouched; this file is the executable consolidation Phase 8 reads.

> No PENDING-INPUT was converted to PASS for lack of a test. Every row below
> names the scaffolding already in the repo that closes it (test code or
> procedure + evidence template + exact command/step).

## A. PENDING-INPUT items (scaffolding ready; owner/device/reviewer input missing)

This is a cross-gate ledger. Rows gated G1, G3, R1a or G5 are downstream
readiness items, not G0 baseline blockers. G0 accepts requirements/design and
reproducible host evidence; later gates close physical, legal, production
database, statutory and release evidence.

| ID | Exact missing input (affected IDs) | Smallest owner question | Command / step that closes it | Gate |
|---|---|---|---|---|
| P-SQLIB | Confirmed SQLCipher-class library name + exact version + licence text/evidence + Android 8 compatibility evidence (G0-VER-001; affects Phase 0 §7, Phase 1 prod wiring, Phase 3 D-KEY/BKP) | Which exact SQLCipher-class library, version, and licence evidence is approved, with Android 8 proof? | Record in `docs/g0/PROJECT_BASELINE.md` §7 addendum (no HTML edit); add dependency via `flutter pub add` with version+licence log; re-run `flutter test`, `flutter analyze`, Phases 1/3/7/8 | G0 |
| P-DEVICE-8 | Assigned Android 8 (API 26) device: model, Android version, build number (G0-VER-005/008; Phase 3 D-KEY/TRIAL/SHARE/BKP min-side) | Which physical or AVD Android 8 device is assigned? | Boot/record fingerprint per `DEVICE_TEST_PROCEDURE.md` §B; run D-KEY-01…D-BKP-04; fill result blocks; attach logs/photos | G0 |
| P-DEVICE-CUR | Current-Android device assignment confirmation for the record (emulator `niav_test` API 36 already characterized; app wiring pending P-SQLIB) | Which current-Android device is the G0 record device? | Same procedure on assigned device; attach evidence | G0 |
| P-KEYSTORE | On-device Keystore gen/wrap/fail + trial/denylist/share/backup runs (G0-VER-005/008; Phase 3) | (covered by P-SQLIB + P-DEVICE-8/CUR) | `DEVICE_TEST_PROCEDURE.md` steps D-KEY-01…D-BKP-04; `adb shell dumpsys android.security.keystore` + logcat + screenshots | G0/G5 |
| P-GST-SRC | **CLOSED — owner decision:** CGST Act Section 170 is the source; fixtures use the recorded NiAvERP paise/quantity and round-half-up convention. | Decision recorded by authorized owner; fixture rerun remains a verification action. | Re-run `flutter test test/accounting`; do not reopen as an owner question. | G0 |
| P-DISC-PREC | **CLOSED — owner decision:** amount-wins + tax-on-net + CGST receives odd paise remainder. | Decision recorded by authorized owner; affected fixture rerun remains a verification action. | Update fixture evidence and rerun tests; do not reopen as an owner question. | G1 |
| P-FIELD-LIST | Owner-approved IRN / acknowledgement / e-way field list for R1a capture (O-10/O-FG-002/003; DSS-O03; G0-VER-003). No G0-DEF-004 exists in the Exception Register, so this is PENDING-INPUT, not DEFERRED. No columns created. | Please supply the exact R1a field list — or record G0-DEF-004 deferral to R1a review if fields stay deferred? | Supply list → define fields + lineage + fixtures; or record G0-DEF-004 → close as DEFERRED (G3); re-run Phases 4/7/8 | G3 |
| P-EINV-SCH | Official e-invoice schema pinned version + sample response files (FG-002; G0-VER-003) | Which pinned e-invoice schema version + samples are authoritative for G3? | Pin version; attach samples (pointers only, nothing vendored without approval); G3 workflow implements | G3 |
| P-GSTR-SCH | Official GST return JSON schema source/version for FR-M16-003 (R1a requirement) | Which GST-return JSON schema source/version is authoritative? | Same as above (R1a) | R1a/G3 |
| P-EWAY-SCH | Official e-way schema pinned version + samples (O-FG-003; G0-VER-003) | Which pinned e-way version (observed v1.03 current 2026-10-03, UNCONFIRMED) + samples are authoritative? | Same as above (G3) | G3 |
| P-LEGAL-001 | Named legal reviewer name + role (O-14/R-13; G0-VER-007) | Who is the named legal reviewer? | Record in `LEGAL_CONTROL_MAP_DRAFT.md` + verification execution file; re-run Phases 7/8 | G5 |
| P-LEGAL-002 | Legal review date (actual or scheduled) | On what date did/will the review occur? | Record date; attach signed note under `docs/g0/evidence/legal/` | G5 |
| P-LEGAL-003 | Retention/deletion decision (periods, purge workflow, authorisation, audit) | What are the approved retention periods + purge workflow? | Implement per decision (migration/fixture if schema changes) | G5 |
| P-LEGAL-004 | DPDP Act reviewed version/date + confirmed obligation readings (§2 rows) | Which Act version/date is authoritative and which rows are confirmed? | Reviewer annotates §2; update dispositions | G5 |
| P-LEGAL-005 | R-13 scope confirmation vs O-14 | Does the reviewer confirm the recorded R-13 disposition? | Record verbatim statement | G5 |
| P-PRN-001 | Physical 58 mm thermal result (matrix slot 1; OD-FD-006 unfrozen) | What is the frozen matrix + 58 mm printer? | `PRINTER_TEST_SHEET.md` template block; attach photo/capture | G5 |
| P-PRN-002 | Physical 80 mm thermal result (slot 2) | What is the frozen matrix + 80 mm printer? | Same | G5 |
| P-PRN-003 | Physical PDF A4/A5 result (slot 3) | What is the frozen matrix + PDF path printer? | Same; attach printed/shared PDF | G5 |
| P-APK-SHA | Release APK bytes + versionName/versionCode + SHA-256 | When is the first release build cut, and which APK is verified? | Build APK → `verify_checksums.ps1 -Artifact <apk> -ExpectedHex <hex>` → record | G5 |
| P-ZIP-SHA | ZIP fallback bytes + SHA-256 | Which ZIP is verified? | Same for ZIP | G5 |
| P-CH-WA | Real WhatsApp delivery test + receipt | (covered by P-APK/ZIP-SHA + channel run) | Send via channel; attach receipt + hash match | G5 |
| P-CH-EM | Real email delivery test + receipt | Same | Same | G5 |
| P-CH-LINK | Real ₹0 hosted-link fetch + captured bytes | Same | Fetch; verify hash; attach log | G5 |

## B. DEFERRED items (owner-deferred with recorded gate; not counted as passed)

| ID | Deferred topic | Gate | Evidence of deferral (read-only source, not edited) |
|---|---|---|---|
| G0-DEF-001 | Tally/Busy native adapters → R3 feasibility only (V1 = Excel templates) | R3 | Exception Register + reconciliation G0-DEF-001; code has no native adapter (grep attested) |
| G0-DEF-002 | TDS/TCS → later release; PF/ESI/payroll → out of scope (not in V1) | Later release | Exception Register + reconciliation G0-DEF-002; code has no TDS/TCS/payroll (grep attested) |
| G0-DEF-003 | Automatic cross-script transliteration → R2 (V1 = native-script + Latin search + aliases) | R2 | Exception Register + reconciliation G0-DEF-003; code has no transliteration |
| (G0-DEF-004) | IRN/ack/e-way field capture deferral — **does not exist** in the Exception Register or reconciliation JSON as of 2026-10-03 | — | Absence verified by search; therefore Phase 4 field capture is PENDING-INPUT (P-FIELD-LIST), NOT DEFERRED |

Excluded (not DEFERRED, not PENDING — boundary holds, attested by absence in `lib/`):

- Voice input (G0-OWN-002, rejected): no voice code, no permission, no UI affordance.
- Direct e-invoice/e-way APIs, server/cloud deps: no `http/dio`, no endpoint, no credentials in `lib/`.
- In-place downgrade: no DOWN migrations; downgrade refusal tested (`backup_test.dart`).

## C. Resume order (when inputs arrive)

1. Supply one input → run the Resume prompt for the listed IDs only (pack §Resume).
2. Re-verify only those items with the scaffolding above; update evidence + this file + verification execution file.
3. Do not change PASS rows. If input is still incomplete, leave PENDING-INPUT with what is still missing.
4. Re-run Phases 7 and 8 to refresh RTM/regression/sign-off.

## D. Public-source evidence collected (2026-10-03)

`docs/g0/evidence/owner/PUBLIC_SOURCE_EVIDENCE_20261003.md` records official
public source pointers for P-SQLIB, P-GST-SRC, P-EINV-SCH, P-GSTR-SCH,
P-EWAY-SCH and P-LEGAL-004. These pointers are supporting evidence only; they
do not close the rows because owner selection, approval, compatibility proof,
field adoption, legal interpretation, and project-specific fixtures are still
missing. No status in §A is changed by the web research.

## E. Owner decision update (2026-10-03)

The user explicitly authorized the assistant to act as owner for decision-only
inputs. The following rows are closed as decisions and must not be requested
again as owner questions:

| ID | Owner decision | Evidence / remaining boundary |
|---|---|---|
| P-GST-SRC | CGST Act Section 170 is the rounding source; use paise, quantity ×10^4, round-half-up line arithmetic, and a separate round-off ledger line. | Source and decision recorded in `evidence/owner/PUBLIC_SOURCE_EVIDENCE_20261003.md`; fixtures still need rerun. |
| P-DISC-PREC | Amount-wins; tax on net; CGST receives the odd paise remainder. | Owner decision recorded; affected fixtures still need rerun. |

The following source selections are recorded but are not execution closures:

- P-EWAY-SCH: official GSTN e-Way portal, displayed v1.03; pinned schema and
  response fixtures remain required at G3.
- P-EINV-SCH and P-GSTR-SCH: official source pages selected; pinned schema
  files and samples remain required at G3/R1a.
- P-LEGAL-004: MeitY DPDP Act 2023 selected; qualified legal review remains
  required.

All physical, delivery, compatibility, licence-selection, field-list and
legal-review evidence rows remain `PENDING-INPUT`. Therefore this register is
updated but G0 is **not unconditionally closed**.

## F. D1 note (2026-10-06, addition only — no row status changed)

P-SQLIB approval is recorded in `niaverp/pubspec.yaml` (owner-approved
2026-10-05: package:sqlite3 3.7.0 with build-hook source `sqlite3mc`;
DECISIONS.md P-SQLIB). The §A P-SQLIB row still reads as an open question, so
it stays `PENDING-INPUT` until the owner confirms this approval and the
remaining G0-VER-001 evidence (native cipher licence text from the bundled
asset manifest + Android 8 compatibility proof on device) is attached.
