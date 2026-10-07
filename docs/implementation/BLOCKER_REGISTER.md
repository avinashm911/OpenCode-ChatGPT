# BLOCKER_REGISTER — one row per blocker
Date (UTC): 2026-10-07. Status vocabulary: PENDING-INPUT (waiting on someone) / BLOCKED (cannot proceed) / FAIL (test fails now) / NOT-RUN (proof never executed). Nothing here is decided; owner ticks live in `docs/owner/DECISIONS_TO_APPROVE.md`.

| ID | Owner (who must act) | Status | Evidence path |
|---|---|---|---|
| P-SQLIB (device proof remainder) | Owner (assign device/run) | PENDING-INPUT | docs/g0/PENDING_INPUTS.md §A; docs/g0/evidence/CIPHER_LIB_LICENSE_20261007.md; docs/g0/evidence/SQLITE3MC_CONFIG_20261007.md |
| P-DEVICE-8 (Android 8 device) | Owner | PENDING-INPUT | docs/g0/PENDING_INPUTS.md §A; docs/g0/evidence/android/EMULATOR_API26_RUN_20261006.md |
| P-DEVICE-CUR (current-Android record device) | Owner | PENDING-INPUT | docs/g0/PENDING_INPUTS.md §A |
| P-KEYSTORE (on-device Keystore runs) | Owner (device) | PENDING-INPUT | docs/g0/PENDING_INPUTS.md §A |
| GST-TAX-POSTING (B3–B5 implementation) | CA (answers) + Owner (sign-off) | FIXED 2026-10-07 (CA reply applied: place-of-supply, blocks, separate-halves math, mirroring, Dr=Cr; see DECISIONS.md P-GST-POST) | docs/implementation/evidence/CA_REPLY_TEXT_20261007.txt; niaverp/lib/application/tax/gst_posting.dart; niaverp/test/application/gst_posting_test.dart; niaverp/test/application/gst_posting_engine_test.dart |
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
| TEST-entry_parsing (D3-B1 quantity expectation) | Implementation | FIXED 2026-10-07 (regression from rewrite bc75024, not pre-existing; sub-unit totals now decide) | docs/implementation/evidence/entry_parsing_before_fix.txt; docs/implementation/evidence/entry_parsing_after_fix.txt; niaverp/test/application/entry_parsing_test.dart |
| TEST-localization_source (ARB asset load) | Implementation | FIXED 2026-10-07 (hi/gu ARB corrupt-newline repair + test rewritten on dart:io with full parity checks; no missing keys found) | docs/implementation/evidence/localization_source_after_fix.txt; docs/implementation/evidence/flutter_test_full_20261007_l10nfix.txt; niaverp/test/presentation/localization_source_test.dart |
| CI-RUN (first green run 37576254060) | Owner (push + Run workflow) | GREEN 2026-10-07 — run 37576254060: Debug success, Release skipped by design | docs/implementation/evidence/ci_run_jobs_20261007.txt; .github/workflows/build.yml; docs/implementation/CI_DEPENDENCIES.md |
| EMULATOR-RUN (API 26 AVD smoke) | Owner (run CI) | AVD-PASS 2026-10-07 — run 37576254060: app installed/launched/alive, 0 FATAL EXCEPTION (AVD only; physical device still pending — see P-DEVICE-8, unchanged) | docs/g0/evidence/android/EMULATOR_API26_RUN_20261006.md; docs/g0/evidence/android/emulator-api26-37576254060/ |
| RELEASE-KEYSTORE (4 GitHub secrets unset) | Owner | PENDING-INPUT | .github/workflows/build.yml (job build-release); docs/owner/DECISIONS_TO_APPROVE.md §8 |
| TRANSLATIONS (hi/gu native review) | Native speakers + Owner | PENDING-INPUT | docs/owner/DECISIONS_TO_APPROVE.md §5 |

Closed and NOT listed above (for the record): P-GST-SRC rounding + P-DISC-PREC (owner decisions recorded, PENDING_INPUTS §E); cipher pin E1b-A9 (implemented + tested 2026-10-07); device_id P-DEVICEID (recorded, awaiting confirming tick in DECISIONS_TO_APPROVE §1); debug/release signing guard (proven by builds 2026-10-07).
