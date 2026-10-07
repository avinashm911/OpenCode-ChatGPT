# Implementation Phase 08 — Admin users and licensing (FG-012/014, FR-M18/19/20, G0-SCH-006, M18/M19/M20, OD-FD-005/OD-UI-005)
Date (UTC): 2026-10-06   Prompt: 08_admin_users_and_licensing.md
Outcome: COMPLETE-WITH-BLOCKS   Previous: phase-07.md

## 1. Read / Objective
Audit admin/user/licence/trial/security. Preserve exclusions (no server/auth server dependency, no in-app payment gateway V1, no cloud). Verify G0-SCH-006 (m007), FR-M18-001/002 (admin/audit), FR-M19-001/002/003 (auth/user/roles), FR-M20-001 (trial/licence), M18/M19/M20 modules. Enumerate deferred/block.

## 2. Baseline
HEAD e67af1c; analyze clean; test 450/1 unchanged.

## 3. Owned-ID table (15 IDs — concise)
- FG-012: boundary (offline signed licence core implemented; external/manual payment before key issuance; payment-to-licence handoff unspecified — not converted).
- FG-014: boundary (edition/licence boundaries conceptual; grace/lifetime definitions open; feature gating not fully testable — not PASS).
- FR-M18-001: implemented (admin actions: company/backup/restore/lock/user/admin; audit trail; authorization checks).
- FR-M18-002: implemented (audit events append-only; old/new values; actor/time/device/reason; protected from ordinary edit/deletion — audit repo + audit_event table verified).
- FR-M19-001: implemented (mobile/password/PIN/biometric mechanism supported locally; secrets protected; no server dependency; authentication state Unconfigured→Active/Locked).
- FR-M19-002: implemented (user/role/permissions/defaults; predefined + custom roles; action-level rights checks; Active/Disabled state).
- FR-M19-003: boundary (device pairing for sync — allowed local identification/revocation; downstream LAN sync transport blocked by S1 boundary / G0-VER-005/008; not converted to PASS).
- FR-M20-001: implemented (trial/licence activation; signed licence key locally verified; edition/term/device-binding/state Trial→Licensed/Expired/Grace/Read-only; feature gates; exact grace/lifetime definitions open — recorded as boundary note, not converted).
- FR-M20-002: deferred P2 (customer-facing payment workflow deferred; no in-app payment required V1; external/manual evidence handled separately).
- G0-SCH-006: implemented (m007_sch006_trial_denylist.sql; registry v7; trial anchor / denylist / audit lifecycle; rollback evidence; tests pass).
- M18: implemented (admin P1: company/admin/user/admin controls; deferred P2: advanced user/admin sub-modules enumerated; not rebuilt).
- M19: implemented (users/roles/auth P1; deferred P2 multi-user/sub-modules listed; no multi-user transport V1 — S1 boundary preserved).
- M20: deferred P2 (licence/payment/deferred; no V1 implementation of payment/licence issuance beyond local entitlement verification; deferred per STATUS_LEDGER / G0-VER-005).
- OD-FD-005: boundary (security plan design control — trusted_now / backup encryption / MAC KDF interface delivered; physical/legal/proof evidence missing — G0-VER-001/005; not PASS).
- OD-UI-005: boundary (UI simplification / advanced-mode boundary — simple/advanced gating present; full advanced feature set deferred M18/M19/M20 P2; not converted).

Notes: deferred P2 (FR-M20-002, M20 P2, M19 P2 sub-modules) listed explicitly; boundary items (FG-012, FG-014, FR-M19-003, FR-M20-001 grace/lifetime open, OD-FD-005) preserved; exclusions (voice, TDS/TCS, native adapters, payroll, automatic transliteration, direct statutory APIs) maintained.

## 4. Work / Repairs / Changes
No edits to lib/test/pubspec/Android. Read-only audit of admin/config/auth/repo/trial/license. Phase-08.md only.

## 5. Tests / Traceability / Blockers
450/1 unchanged. Blocked: P-SQLIB/G0-VER-001/005 (cipher/device/proof affects OD-FD-005); G0-VER-003 (statutory schemas); deferred P2 (FR-M20-002, M20); exclusions preserved.

## 6. Next gate
Prompt 09 (security_backup_sync_boundary.md) — must read phase-08.md; preserve admin/auth/licence/trial; P-SQLIB blocked continues.

## 7. Honesty
Host/in-memory only. No device/proof/release/licence/legal PASS fabricated. Deferred/block listed; exclusions preserved.
