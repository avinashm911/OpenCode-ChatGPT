-- NiAvERP migration v3 — G0-SCH-002: period lock (gate G1).
-- Date range + scope + status + authorised unlock actor/reason/timestamp +
-- audit linkage. Locks never delete history (DSS-C-003).
-- Traceability: DB/DSS G0-SCH-002; D-M5; FR-COM-002.

CREATE TABLE IF NOT EXISTS period_lock (
  lock_id         TEXT PRIMARY KEY,
  company_id      TEXT NOT NULL REFERENCES company (company_id),
  scope           TEXT NOT NULL,
  date_from       TEXT NOT NULL,
  date_to         TEXT NOT NULL CHECK (date_to >= date_from),
  status          TEXT NOT NULL,
  locked_by       TEXT NOT NULL,
  locked_at       INTEGER NOT NULL,
  unlock_actor    TEXT,
  unlock_reason   TEXT,
  unlocked_at     INTEGER,
  audit_event_id  TEXT REFERENCES audit_event (event_id),
  record_version  INTEGER NOT NULL DEFAULT 1 CHECK (record_version >= 1)
);
CREATE INDEX IF NOT EXISTS idx_period_lock_company_dates
  ON period_lock (company_id, date_from, date_to);
