-- NiAvERP migration v5 — G0-SCH-004: tax/HSN and layout profiles (gate G1).
-- Effective-dated tax/HSN rows (rates in INTEGER basis points; table ships
-- EMPTY — statutory values wait for verified schemas, DSS-O03 / Phase 4/G3)
-- plus versioned layout profiles with sync/backup lineage hooks (S1).
-- Traceability: DB/DSS G0-SCH-004; OD-DB-003; FR-M16; MPL 7.4.

CREATE TABLE IF NOT EXISTS tax_rate_hsn (
  rate_id         TEXT PRIMARY KEY,
  company_id      TEXT NOT NULL REFERENCES company (company_id),
  hsn_code        TEXT NOT NULL,
  rate_bps        INTEGER NOT NULL CHECK (rate_bps >= 0),
  effective_from  TEXT NOT NULL,
  effective_to    TEXT CHECK (effective_to IS NULL OR effective_to >= effective_from),
  record_version  INTEGER NOT NULL DEFAULT 1 CHECK (record_version >= 1)
);
CREATE INDEX IF NOT EXISTS idx_tax_hsn_from
  ON tax_rate_hsn (company_id, hsn_code, effective_from);

CREATE TABLE IF NOT EXISTS layout_profile (
  profile_id          TEXT PRIMARY KEY,
  company_id          TEXT NOT NULL REFERENCES company (company_id),
  profile_key         TEXT NOT NULL,
  version             INTEGER NOT NULL CHECK (version > 0),
  layout_json         TEXT NOT NULL,
  updated_at          INTEGER NOT NULL,
  synced_at           INTEGER,
  backup_manifest_id  TEXT,
  record_version      INTEGER NOT NULL DEFAULT 1 CHECK (record_version >= 1),
  UNIQUE (company_id, profile_key, version)
);
