# BLOCKER_REGISTER — one row per blocker
Date (UTC): 2026-10-07. Status vocabulary: PENDING-INPUT (waiting on someone) / BLOCKED (cannot proceed) / FAIL (test fails now) / NOT-RUN (proof never executed). Nothing here is decided; owner ticks live in `docs/owner/DECISIONS_TO_APPROVE.md`.

| ID | Owner (who must act) | Status | Evidence path |
|---|---|---|---|
| P-SQLIB (device proof remainder) | Owner (assign device/run) | PENDING-INPUT | docs/g0/PENDING_INPUTS.md §A; docs/g0/evidence/CIPHER_LIB_LICENSE_20261007.md; docs/g0/evidence/SQLITE3MC_CONFIG_20261007.md |
| P-DEVICE-8 (Android 8 device) | Owner | PENDING-INPUT | docs/g0/PENDING_INPUTS.md §A; docs/g0/evidence/android/EMULATOR_API26_RUN_20261006.md |
| P-DEVICE-CUR (current-Android record device) | Owner | PENDING-INPUT | docs/g0/PENDING_INPUTS.md §A |
| P-KEYSTORE (on-device Keystore runs) | Owner (device) | PENDING-INPUT | docs/g0/PENDING_INPUTS.md §A |
| GST-TAX-POSTING (B3–B5 implementation) | CA (answers) + Owner (sign-off) | BLOCKED | docs/implementation/OWNER_DECISION_MEMO_GST_POSTING.md |
| P-FIELD-LIST (R1a field list) | Owner | PENDING-INPUT | docs/g0/PENDING_INPUTS.md §A |
| P-EINV-SCH (e-invoice schema) | Owner | PENDING-INPUT | docs/g0/PENDING_INPUTS.md §A |
| P-GSTR-SCH (GST return schema) | Owner | PENDING-INPUT | docs/g0/PENDING_INPUTS.md §A |
| P-EWAY-SCH (e-way schema) | Owner | PENDING-INPUT | docs/g0/PENDING_INPUTS.md §A |
| P-LEGAL-001 (named reviewer) | Owner | PENDING-INPUT | docs/g0/PENDING_INPUTS.md §A |
| P-LEGAL-002 (review date) | Legal reviewer | PENDING-INPUT | docs/g0/PENDING_INPUTS.md §A |
| P-LEGAL-003 (retention/deletion) | Legal reviewer + Owner | PENDING-INPUT | docs/g0/PENDING_INPUTS.md §A |
| P-LEGAL-004 (DPDP readings) | Legal reviewer | PENDING-INPUT | docs/g0/PENDING_INPUTS.md §A |
| P-LEGAL-005 (R-13 scope) | Legal reviewer | PENDING-INPUT | docs/g0/PENDING_INPUTS.md §A |
| P-PRN-001 (58 mm print) | Owner (freeze matrix + hardware) | PENDING-INPUT | docs/g0/PENDING_INPUTS.md §A |
| P-PRN-002 (80 mm print) | Owner (freeze matrix + hardware) | PENDING-INPUT | docs/g0/PENDING_INPUTS.md §A |
| P-PRN-003 (PDF print) | Owner | PENDING-INPUT | docs/g0/PENDING_INPUTS.md §A |
| P-APK-SHA (release APK + hash) | Owner (keystore + first build) | PENDING-INPUT | docs/g0/PENDING_INPUTS.md §A; .github/workflows/build.yml (job build-release) |
| P-ZIP-SHA (ZIP fallback + hash) | Owner | PENDING-INPUT | docs/g0/PENDING_INPUTS.md §A |
| P-CH-WA (WhatsApp delivery) | Owner | PENDING-INPUT | docs/g0/PENDING_INPUTS.md §A |
| P-CH-EM (email delivery) | Owner | PENDING-INPUT | docs/g0/PENDING_INPUTS.md §A |
| P-CH-LINK (hosted-link fetch) | Owner | PENDING-INPUT | docs/g0/PENDING_INPUTS.md §A |
| TEST-entry_parsing (D3-B1 quantity expectation) | Implementation | FAIL | outputs/flutter_test_full_20261007_cipherpin.txt (see Failing tests); niaverp/test/application/entry_parsing_test.dart:15 |
| TEST-localization_source (ARB asset load) | Implementation | FAIL | outputs/flutter_test_full_20261007_cipherpin.txt (see Failing tests); niaverp/test/presentation/localization_source_test.dart:14 |
| CI-RUN (workflow never executed) | Owner (push + Run workflow) | NOT-RUN | .github/workflows/build.yml; docs/implementation/CI_DEPENDENCIES.md |
| EMULATOR-RUN (API 26 smoke never executed) | Owner (run CI) | NOT-RUN | .github/workflows/build.yml (job emulator-api26); docs/g0/evidence/android/EMULATOR_API26_RUN_20261006.md |
| RELEASE-KEYSTORE (4 GitHub secrets unset) | Owner | PENDING-INPUT | .github/workflows/build.yml (job build-release); docs/owner/DECISIONS_TO_APPROVE.md §8 |
| TRANSLATIONS (hi/gu native review) | Native speakers + Owner | PENDING-INPUT | docs/owner/DECISIONS_TO_APPROVE.md §5 |

Closed and NOT listed above (for the record): P-GST-SRC rounding + P-DISC-PREC (owner decisions recorded, PENDING_INPUTS §E); cipher pin E1b-A9 (implemented + tested 2026-10-07); device_id P-DEVICEID (recorded, awaiting confirming tick in DECISIONS_TO_APPROVE §1); debug/release signing guard (proven by builds 2026-10-07).
