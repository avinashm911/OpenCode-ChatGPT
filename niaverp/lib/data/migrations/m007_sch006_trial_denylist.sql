-- NiAvERP migration v7 — G0-SCH-006: trial anchor and denylist (gate G0).
-- Storage + lifecycle hooks for trial anchor, denylist and audit evidence.
-- Per OD-DB-004 sensitive fields are hash-only: the raw licence/key value is
-- NEVER stored, only key_hash. Lifecycle evaluation (3-month trial, 10-day
-- grace, reissue limit 20) is entitlement logic over these rows (Phase 3/G5).
-- Traceability: DB/DSS G0-SCH-006; SEC licence controls;
-- D-04/O-05/D-FG-014; D-11/D-13/A-R2; D-14; D-FG-012; OD-DB-004.

CREATE TABLE IF NOT EXISTS trial_anchor (
  anchor_id       TEXT PRIMARY KEY,
  company_id      TEXT NOT NULL UNIQUE REFERENCES company (company_id),
  installed_at    INTEGER NOT NULL,
  trial_ends_at   INTEGER NOT NULL CHECK (trial_ends_at > installed_at),
  status          TEXT NOT NULL,
  created_at      INTEGER NOT NULL,
  record_version  INTEGER NOT NULL DEFAULT 1 CHECK (record_version >= 1)
);

CREATE TABLE IF NOT EXISTS denylist_entry (
  entry_id        TEXT PRIMARY KEY,
  key_hash        TEXT NOT NULL UNIQUE,
  reason          TEXT NOT NULL,
  revoked_at      INTEGER,
  status          TEXT NOT NULL,
  audit_event_id  TEXT REFERENCES audit_event (event_id),
  created_at      INTEGER NOT NULL,
  record_version  INTEGER NOT NULL DEFAULT 1 CHECK (record_version >= 1)
);
