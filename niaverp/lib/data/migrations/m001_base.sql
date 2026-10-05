-- NiAvERP migration v1 — pre-G0 baseline (migration baseline, not full ERP domain).
-- Creates the minimal FK parents that host the seven G0 deltas, plus the
-- schema_migrations audit ledger. No business rows are seeded.
-- Traceability: DB v0.4 §3 catalogue; DSS v0.4 §3; DB-001, DB-002/D-M4, DSS-C-001/002/004.

CREATE TABLE IF NOT EXISTS schema_migrations (
  version      INTEGER PRIMARY KEY,
  applied_at   INTEGER NOT NULL,
  description  TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS company (
  company_id  TEXT PRIMARY KEY,
  name        TEXT NOT NULL,
  created_at  INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS item (
  item_id     TEXT PRIMARY KEY,
  company_id  TEXT NOT NULL REFERENCES company (company_id),
  name        TEXT NOT NULL,
  unit        TEXT NOT NULL DEFAULT 'pcs',
  created_at  INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_item_company ON item (company_id);

CREATE TABLE IF NOT EXISTS godown (
  godown_id   TEXT PRIMARY KEY,
  company_id  TEXT NOT NULL REFERENCES company (company_id),
  name        TEXT NOT NULL,
  created_at  INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS voucher (
  voucher_id    TEXT PRIMARY KEY,
  company_id    TEXT NOT NULL REFERENCES company (company_id),
  voucher_type  TEXT NOT NULL,
  series        TEXT NOT NULL,
  voucher_no    TEXT NOT NULL,
  voucher_date  TEXT NOT NULL,
  status        TEXT NOT NULL DEFAULT 'draft',
  created_at    INTEGER NOT NULL,
  UNIQUE (company_id, series, voucher_no)
);
CREATE INDEX IF NOT EXISTS idx_voucher_company_date ON voucher (company_id, voucher_date);

CREATE TABLE IF NOT EXISTS voucher_line (
  voucher_line_id  TEXT PRIMARY KEY,
  voucher_id       TEXT NOT NULL REFERENCES voucher (voucher_id),
  company_id       TEXT NOT NULL REFERENCES company (company_id),
  line_no          INTEGER NOT NULL CHECK (line_no > 0),
  item_id          TEXT REFERENCES item (item_id),
  qty_q4           INTEGER NOT NULL,
  rate_paise       INTEGER NOT NULL CHECK (rate_paise >= 0),
  amount_paise     INTEGER NOT NULL CHECK (amount_paise >= 0),
  created_at       INTEGER NOT NULL,
  UNIQUE (voucher_id, line_no)
);

CREATE TABLE IF NOT EXISTS operation (
  op_id       TEXT PRIMARY KEY,
  company_id  TEXT NOT NULL REFERENCES company (company_id),
  device_id   TEXT NOT NULL,
  seq         INTEGER NOT NULL CHECK (seq > 0),
  entity      TEXT NOT NULL,
  entity_id   TEXT NOT NULL,
  action      TEXT NOT NULL,
  payload_hash TEXT,
  created_at  INTEGER NOT NULL,
  UNIQUE (company_id, device_id, seq)
);
CREATE INDEX IF NOT EXISTS idx_operation_entity ON operation (company_id, entity, entity_id);

CREATE TABLE IF NOT EXISTS audit_event (
  event_id    TEXT PRIMARY KEY,
  company_id  TEXT NOT NULL REFERENCES company (company_id),
  entity      TEXT NOT NULL,
  entity_id   TEXT NOT NULL,
  old_data    TEXT,
  new_data    TEXT,
  actor       TEXT NOT NULL,
  created_at  INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_audit_entity ON audit_event (company_id, entity, entity_id);
