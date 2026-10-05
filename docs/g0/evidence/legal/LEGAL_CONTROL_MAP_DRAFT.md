# DRAFT — not a legal review.

# NiAvERP G0 — Data-protection legal/control review (Phase 5)

Date (UTC): 2026-10-03
Prompt authority: `NiAv_G0_Prompts_Pack_v0.8.md` Phase 5
Verification record: O-14 / R-13 (G0-VER-007, gate G5)
Status vocabulary (v0.8): items PASS / FAIL / PENDING-INPUT / DEFERRED; phases COMPLETE / PARTIAL / FAIL.

> This file is a **DRAFT control map only**. It is **not a legal review** and
> does not claim legal compliance. No source interpretation, retention/deletion
> decision, or obligation reading is closed by this draft. The named legal
> reviewer, review date, and every decision below remain **PENDING-INPUT**
> until the owner supplies them.

Global rules applied: standalone Android APK baseline only; no invented
requirements, tax, accounting, permission, sync, or security behavior; money
integer paise / quantity ×10⁴ (unchanged); no server/cloud dependency added;
no excluded capability built; requirements HTML/workbooks/registers untouched
(read-only inputs).

---

## 1. Applicable official source (recorded, not interpreted)

| Item | Value |
|---|---|
| Official source on record | Digital Personal Data Protection Act, 2023 — as cited in `NiAv_G0_Verification_Evidence_Register_v0.1.xlsx` (Verification Evidence sheet, row O-14/R-13) |
| Source pointer (evidence-register value, not vendored) | `https://www.meity.gov.in/writereaddata/files/Digital%20Personal%20Data%20Protection%20Act%202023.pdf` |
| Source status | **Recorded as pointer only. UNCONFIRMED as to exact reviewed version/date until the legal reviewer pins it.** No PDF was downloaded into the repo; no section is quoted as authoritative here. |
| What this phase does | Records the pointer above + drafts the candidate control mapping below. |
| What this phase does NOT do | Interpret the Act; state obligations as settled law; choose retention periods; approve consent notice wording; claim compliance from citation or from this draft. |

Traceability: O-14 (data hosting/privacy); R-13 (reclassified 'Accepted - mitigated' / local-only minimal-collection per ZCP reconciliation); G0-VER-007 (gate G5); SEC data-model/audit sections; RSP backup/support sections.

---

## 2. Candidate obligation → NiAvERP control mapping (DRAFT)

Each row maps a *likely* obligation area (as named by the pack — not a
lawyer's reading) to the NiAvERP control that exists in the approved baseline
or implementation, or to the explicit owner decision still needed. Where the
control exists, the implementation file or schema object is cited. Where it
does not, the row ends in PENDING-INPUT with the smallest owner question.

| # | Likely obligation area (pack-named, DRAFT) | NiAvERP control (baseline / implementation) | Evidence / file | Disposition |
|---|---|---|---|---|
| L-01 | Local-only storage; no telemetry | Standalone APK; one encrypted DB per company; no server/cloud dependency in V1 baseline; no telemetry collection point in `niaverp/lib/` | `docs/g0/PROJECT_BASELINE.md` §1; `niaverp/lib/data/security/*`; pack global rule 2 | PASS (baseline recorded; device proof PENDING-INPUT per Phase 3) — legal reading of "local-only suffices" stays PENDING-INPUT |
| L-02 | Minimal / necessary collection | Company/FY/user/device context only where applicable (FR-COM-002); masters/vouchers carry only documented fields; no IRN/ack/e-way columns invented without owner field list (Phase 4 boundary) | `docs/g0/evidence/adapters/G0_BOUNDARY.md`; FR-COM-002 | PASS (boundary attested) — whether the collected set is *legally* minimal stays PENDING-INPUT (reviewer) |
| L-03 | Backup handling (confidentiality + integrity of copies) | External backup with SHA-256 manifest; restore re-verifies hash before touching live DB; newer-schema restore refused (no in-place downgrade); after uninstall/reinstall Keystore keys are gone so restore forces key re-provisioning, never silent decrypt | `niaverp/lib/data/security/backup.dart`; `niaverp/test/security/backup_test.dart`; RSP 5 / DSS-C-007 | PASS (host logic tested) — on-device encrypted round-trip stays PENDING-INPUT (DEVICE + SQLCipher lib) |
| L-04 | Access / recovery behavior (authorised use, PIN/biometric gating, no hidden recovery path) | 256-bit DB key wrapped by Android Keystore; PIN/biometric gates key *use*; Keystore failure taxonomy fails safely (locked, no fallback, no plaintext); uninstall wipe returns to missing (re-provision required); no hidden recovery path | `niaverp/lib/data/security/key_lifecycle.dart`; `niaverp/test/security/key_lifecycle_test.dart`; `niaverp/lib/data/security/entitlements.dart` | PASS (host contract tested) — on-device Keystore behavior stays PENDING-INPUT (DEVICE, G0-VER-005) |
| L-05 | Retention / deletion decisions | **No retention period, deletion workflow, or purge rule is stated in the approved documents.** Posted records are never destructively deleted per DSS-C-003 (append-only audit); trial/grace expiry is read-only + export + backup with data never deleted (D-04). Whether that satisfies any legal retention/deletion duty is **undecided**. | DSS-C-003; D-04/O-05 | **PENDING-INPUT** — owner + legal reviewer must supply the retention/deletion decision (see §3 Q-3) |
| L-06 | Incident / audit evidence (what happened, when, to what) | Field-level old/new deltas as JSON; sensitive fields hash-only; hash chain over canonical record (OD-DB-004); `audit_event` append-only table (migration v1); `operation` envelope with `base_version`/`dependencies`; backup manifest + `schema_migrations` ledger as recovery evidence | `niaverp/lib/data/migrations/m001_base.sql` (`audit_event`); OD-DB-004; DSS §6 | PASS (schema + rule recorded) — sufficiency of this audit trail for any legal incident duty stays PENDING-INPUT (reviewer) |
| L-07 | Sharing / disclosure boundaries | Default-deny share allowlist: attachments JPEG/PNG/PDF ≤5 MB magic-validated; imports `.xlsx`/`.csv` ≤10 MB; APK/DB/executables/unknown denied; app-private storage; FileProvider-scoped exposure (host policy tested, device sheet pending) | `niaverp/lib/data/security/share_policy.dart`; `niaverp/test/security/share_policy_test.dart` | PASS (host policy tested) — on-device FileProvider/share-sheet proof stays PENDING-INPUT (DEVICE, G0-VER-008) |

No consent-notice wording, no grievance/time-limit reading, no cross-border
statement, and no penalty/registration reading is offered here — those are
legal-reviewer inputs, not implementation assumptions.

---

## 3. PENDING-INPUT items (exact missing input + smallest owner question)

| ID | Exact missing input | Smallest owner question | Closing step |
|---|---|---|---|
| P-LEGAL-001 | Named legal reviewer (name + role) for O-14/R-13 | Who is the named legal reviewer for O-14/R-13? | Record name/role in this file + verification register; re-run Phase 7/8 |
| P-LEGAL-002 | Legal review date (or scheduled date) | On what date did (or will) the legal review occur? | Record date; attach signed review note under `docs/g0/evidence/legal/` |
| P-LEGAL-003 | Retention/deletion decision (periods, purge workflow, purge authorisation + audit) | What are the approved retention periods and the deletion/purge workflow (actor, authorisation, audit)? | Implement per decision; add migration/fixture if schema change needed |
| P-LEGAL-004 | Source interpretation: which DPDP Act version/date is reviewed + which obligation readings are confirmed vs not-applicable at V1 | Which Act version/date is authoritative, and which rows in §2 are confirmed, narrowed, or not-applicable at V1? | Reviewer annotates §2; update each row disposition; do not change PASS rows to legal-PASS without reviewer sign-off |
| P-LEGAL-005 | Any R-13 vs O-14 scope confirmation (ZCP notes R-13 'Accepted - mitigated' / 'not applicable at V1' in closure ledger — needs reviewer alignment) | Does the reviewer confirm the R-13 disposition as recorded, or narrow it? | Record reviewer statement verbatim; carry gate G5 |

Until P-LEGAL-001/002/004 close, **no item in this phase is marked PASS as a
legal review**. The draft map itself (§2) is PASS as a *drafting activity*
(host-side document exists and covers each listed control area); the
*review* items above are PENDING-INPUT.

---

## 4. Change log (Phase 5)

| Date | Change | Traceability |
|---|---|---|
| 2026-10-03 | Draft control map created (this file); official DPDP Act 2023 pointer recorded as UNCONFIRMED; reviewer/date/interpretation/retention left PENDING-INPUT; no legal compliance claimed | O-14/R-13; G0-VER-007 (G5); pack v0.8 Phase 5 |

## 5. Evidence

- This file: `docs/g0/evidence/legal/LEGAL_CONTROL_MAP_DRAFT.md`
- Official source pointer: evidence register `NiAv_G0_Verification_Evidence_Register_v0.1.xlsx` (O-14/R-13 row) — not vendored here
- Control implementations cited in §2 (security libs + migration v1 + Phase 4 boundary); host tests already logged under `docs/g0/evidence/android/security-test-20261003.log.md` and `docs/g0/evidence/adapters/statutory-boundary-test-20261003.log.md`

---

## G0 PHASE RESULT

```text
G0 PHASE RESULT
Phase: 5 — Data-protection legal/control review
Phase status: PARTIAL
Commands run:
- (no code commands; document creation only — prior host test logs reused, not re-claimed)
Changed files:
- docs/g0/evidence/legal/LEGAL_CONTROL_MAP_DRAFT.md (new)
Tests:
- Passed: (none new; host security/boundary tests from Phases 3-4 remain +74 green, not re-counted here)
- Failed: 0
- Pending input: P-LEGAL-001/002/003/004/005
Evidence:
- docs/g0/evidence/legal/LEGAL_CONTROL_MAP_DRAFT.md
Traceability IDs:
- O-14, R-13, G0-VER-007 (G5)
Item statuses:
- L-DRAFT: PASS — draft map exists, covers each listed control area, headed "DRAFT — not a legal review"
- L-SOURCE: PENDING-INPUT — official source recorded as UNCONFIRMED pointer until reviewer pins version/date
- L-REVIEWER: PENDING-INPUT — named reviewer + date missing
- L-RETENTION: PENDING-INPUT — retention/deletion decision missing
- L-INTERP: PENDING-INPUT — source interpretation + R-13 scope confirmation missing
Pending inputs and owner questions:
- P-LEGAL-001: named legal reviewer (name + role) — Who is the reviewer for O-14/R-13?
- P-LEGAL-002: review date — On what date did/will the review occur?
- P-LEGAL-003: retention/deletion decision — What are the approved periods + purge workflow?
- P-LEGAL-004: Act version/date + confirmed readings — Which version is authoritative and which §2 rows are confirmed?
- P-LEGAL-005: R-13 scope — Does the reviewer confirm the recorded R-13 disposition?
Next gate:
- Phase 6 — Printer and release-delivery verification (independent; may run while legal inputs pending)
```
