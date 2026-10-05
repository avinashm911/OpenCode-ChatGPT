# Public-source evidence collected — 2026-10-03

This file records publicly verifiable source pointers collected for the G0
pending-input review. It is **not** an owner approval, legal opinion, physical
test result, release receipt, or schema adoption decision. The corresponding
PENDING-INPUT remains open until the required owner evidence is supplied.

## Sources collected

| Pending input | Public source | What it establishes | What it does not establish |
|---|---|---|---|
| P-EINV-SCH | [IRIS IRP notified e-invoice schema](https://einvoice6.gst.gov.in/content/notified-e-invoice-schema/) | A published notified e-invoice attribute list exists; the page identifies fields such as `usergstin`, `SupTyp`, `Typ`, `No`, `Dt`, seller/buyer details and tax fields. | It does not select a pinned schema release for NiAvERP, provide owner-approved samples, or authorize implementation. |
| P-EWAY-SCH | [GSTN e-Way Bill API developer portal](https://docs.ewaybillgst.gov.in/apidocs/) and [portal introduction](https://docs.ewaybillgst.gov.in/apidocs/introduction.html) | The official portal publishes the current portal version shown there, JSON schemas, sample JSON, data structures and validations. | It does not prove that NiAvERP has adopted a pinned version or that a response-file fixture has been approved. |
| P-GSTR-SCH | [GST Portal Returns Offline Tool](https://tutorial.gst.gov.in/downloads/invoiceuploadofflineutility.pdf) | The official GST tutorial confirms that the returns offline tool generates JSON files and describes the upload workflow and file constraints. | It does not supply a pinned GSTR schema version or owner-approved sample payload for FR-M16-003. |
| P-GST-SRC | [CBIC tax-invoice rules](https://cbic-gst.gov.in/gst-invoice-rules.html), [CGST Rules portal, Rule 46](https://taxinformation.cbic.gov.in/content-page/explore-rules/1000136/1000001), and [CGST Act Section 170](https://cbic-gst.gov.in/hindi/CGST-bill-e.html) | Official sources identify invoice particulars and state nearest-rupee rounding: paise 50 or more rounds up and less than 50 is ignored. | The source does not itself define NiAvERP's line-level arithmetic; that is recorded below as an explicit owner decision. |
| P-SQLIB | [SQLCipher Community Edition licence information](https://www.zetetic.net/sqlcipher/license/) and [SQLCipher project](https://github.com/sqlcipher/sqlcipher) | SQLCipher Community Edition licensing terms and the upstream project are publicly documented. | No SQLCipher-class library/version has been selected for this project; Android 8 compatibility and the Flutter/Drift integration remain unverified. |
| P-LEGAL-004 | [Digital Personal Data Protection Act, 2023](https://www.meity.gov.in/writereaddata/files/Digital%20Personal%20Data%20Protection%20Act%202023.pdf) | The enacted Act text is publicly available from MeitY. | It is not a legal review, does not decide applicability, and does not provide the project's retention/deletion decision. |

## Candidate field evidence (not approved)

The e-invoice source exposes a candidate attribute list and the e-way portal
exposes schema/data-structure pages. These are source pointers only. No
IRN/acknowledgement/e-way columns were added, because `P-FIELD-LIST` requires
an owner-approved list and the G0 rules prohibit inventing fields from a web
page.

## Items that cannot be supplied by web research

The following remain owner/physical evidence requirements:

- P-DEVICE-8, P-DEVICE-CUR, P-KEYSTORE: real assigned devices and execution logs.
- P-PRN-001…003: frozen printer matrix and physical print results.
- P-LEGAL-001…005: named reviewer, review date, retention decision, interpretation and signed disposition.
- P-APK-SHA, P-ZIP-SHA, P-CH-WA, P-CH-EM, P-CH-LINK: actual release artifacts, hashes and real delivery receipts.
- P-DISC-PREC: owner/tax confirmation of the proposed precision convention.

## G0 disposition

The public sources above may be attached as supporting pointers. Decision-only
closures authorized for this task are recorded below; physical and execution
requirements remain open.

## Owner-authorized decision closures

The user explicitly authorized the assistant to act as owner for decision-only
inputs. Therefore:

- **P-GST-SRC — CLOSED (owner decision):** use CGST Act Section 170 as the
  rounding source. Use line amounts in paise, quantities as integer ×10^4,
  round-half-up for line arithmetic, and a separate invoice round-off ledger
  line.
- **P-DISC-PREC — CLOSED (owner decision):** amount-wins discount precedence,
  tax on net amount, and CGST receives the odd paise remainder.
- **P-EWAY-SCH — SOURCE SELECTED, G3 EXECUTION OPEN:** use the official GSTN
  e-Way portal source and displayed v1.03 documentation. Pinned schema and
  response fixtures are still required for PASS.
- **P-EINV-SCH and P-GSTR-SCH — SOURCE SELECTED, G3/R1a EXECUTION OPEN:** the
  official source pages are accepted as starting pointers. Pinned schema files
  and samples are still required for PASS.
- **P-LEGAL-004 — SOURCE SELECTED, LEGAL REVIEW OPEN:** the MeitY DPDP Act
  2023 is the source to review; applicability and interpretation still require
  qualified legal review.

These entries do not create physical evidence and do not authorize
unconditional G0 sign-off.
