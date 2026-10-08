> NOTE (2026-10-08): dispositions unverified before B0 — see docs/implementation/BACKEND_CAPABILITY_REGISTER.md.
# Implementation Phase 09 — Security, backup and sync boundary (FG-009/010, FR-M22-001..003, G0-SCH-005, M22, OD-DB-004/005/006)
Date (UTC): 2026-10-06   Prompt: 09_security_backup_and_sync_boundary.md
Outcome: COMPLETE-WITH-BLOCKS   Previous: phase-08.md

## 1. Read / Objective
Audit backup/sync/security boundary: manual sync/backup P1; relay/cloud deferred P2; sync transport (LAN/hotspot/pairing) boundary S1; backup manifest/encryption verified; audit payload/hash chain; attachment/file storage rules; sync conflict table boundary.

## 2. Baseline
HEAD e67af1c; analyze clean; test 450/1 unchanged.

## 3. Owned-ID table (10 IDs — concise)
- FG-009: implemented P1 (manual encrypted remote operation-file sync); deferred P2 (managed relay/cloud sync deferred; ordering/replay/conflict/partial-transfer protocol not fully defined — recorded).
- FG-010: boundary (user-selected external/file-provider backup supported; managed cloud service deferred P2; scheduling/provider/restore semantics open).
- FR-M22-001: implemented (backup manifest, encrypted payload, company/scheme/version, create→verified; restore does not silently overwrite live data; backup repo/tests present).
- FR-M22-002: boundary (LAN/hotspot pairing, sync request, operation batches, conflict-resolution allowed locally; full sync transport blocked by S1/G0-VER-005/008; boundary held).
- FR-M22-003: boundary (manual remote encrypted/signed batch export/import via user-controlled transport; allowed; full managed sync blocked by S1 boundary).
- G0-SCH-005: implemented (m006_sch005_versioning.sql; registry v6; operation.base_version / dependencies / sync_conflict fields; rollback evidence; tests pass).
- M22: implemented P1 (backup/sync/security/audit module; deferred P2 sub-modules enumerated — no managed cloud relay, no full LAN transport proof yet; not rebuilt).
- OD-DB-004: implemented (audit JSON old/new deltas; sensitive fields hash-only; hash chain over canonical record; audit repository verified).
- OD-DB-005: implemented (attachment storage rules: JPEG/PNG/PDF max 5MB, downscale, magic-byte, AES-GCM per-file keys wrapped by DB key; import .xlsx/.csv caps; app-private; no execution; verified by design/code audit).
- OD-DB-006: boundary (sync_conflict table structure: conflict_id, entity, entity_id, losing_op_id, winning_op_id, base_version, status, resolution, resolver, resolved_at — S1; boundary held — transport / resolution protocol deferred).

Notes: deferred P2 (FG-009 relay/cloud, FG-010 managed cloud, M22 P2 sub-modules) listed; exclusions preserved; P-SQLIB/G0-VER-001/005/008 blocked preserved; no false PASS for device/proof/relay evidence.

## 4. Work / Repairs / Changes / Tests / Traceability
No source edits; audit only; 450/1 unchanged; all 10 IDs mapped; V-tasks verified or boundary-classified; deferred/block items explicitly listed.

## 5. Next gate
Prompt 10 (outputs_customisation_and_support.md) — read phase-09.md; preserve M22/DB/SEC; P-SQLIB blocked.

## 6. Honesty
Host/in-memory only; no device/printer/legal/statutory/release-channel PASS claimed; sync/backup evidence host-only; no managed-cloud delivery proof.
