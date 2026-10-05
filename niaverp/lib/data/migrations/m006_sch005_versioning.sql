-- NiAvERP migration v6 — G0-SCH-005: record/operation versioning (gate S1).
-- Adds record_version to every domain table and base_version + dependencies
-- to the operation log, plus the approved sync_conflict record (OD-DB-006).
-- This migration covers ONLY G0 schema versioning fields for sync, not the
-- complete sync implementation (pack rule 12).
-- Traceability: DB/DSS G0-SCH-005; SYNC 3/6; OD-DB-006; G0-CON-004.

-- record_version on base tables (G0 tables already carry it from creation).
-- Guarded in the Dart runner via PRAGMA table_info (old Android SQLite has no
-- ADD COLUMN IF NOT EXISTS); the raw statements below are the audited source.

-- __ADD_COLUMN__ item record_version INTEGER NOT NULL DEFAULT 1 CHECK (record_version >= 1)
ALTER TABLE item ADD COLUMN record_version INTEGER NOT NULL DEFAULT 1 CHECK (record_version >= 1);

-- __ADD_COLUMN__ voucher record_version INTEGER NOT NULL DEFAULT 1 CHECK (record_version >= 1)
ALTER TABLE voucher ADD COLUMN record_version INTEGER NOT NULL DEFAULT 1 CHECK (record_version >= 1);

-- __ADD_COLUMN__ voucher_line record_version INTEGER NOT NULL DEFAULT 1 CHECK (record_version >= 1)
ALTER TABLE voucher_line ADD COLUMN record_version INTEGER NOT NULL DEFAULT 1 CHECK (record_version >= 1);

-- __ADD_COLUMN__ operation base_version INTEGER NOT NULL DEFAULT 1 CHECK (base_version >= 1)
ALTER TABLE operation ADD COLUMN base_version INTEGER NOT NULL DEFAULT 1 CHECK (base_version >= 1);

-- Relational form of operation.dependencies (SYNC replay / gap detection).
CREATE TABLE IF NOT EXISTS operation_dependency (
  operation_op_id   TEXT NOT NULL REFERENCES operation (op_id),
  depends_on_op_id  TEXT NOT NULL REFERENCES operation (op_id),
  PRIMARY KEY (operation_op_id, depends_on_op_id)
);

-- Approved conflict record shape (OD-DB-006); resolution lifecycle is S1.
CREATE TABLE IF NOT EXISTS sync_conflict (
  conflict_id   TEXT PRIMARY KEY,
  company_id    TEXT NOT NULL REFERENCES company (company_id),
  entity        TEXT NOT NULL,
  entity_id     TEXT NOT NULL,
  losing_op_id  TEXT REFERENCES operation (op_id),
  winning_op_id TEXT REFERENCES operation (op_id),
  base_version  INTEGER NOT NULL,
  status        TEXT NOT NULL DEFAULT 'open',
  resolution    TEXT,
  resolver      TEXT,
  resolved_at   INTEGER,
  created_at    INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_conflict_entity
  ON sync_conflict (company_id, entity, entity_id);
