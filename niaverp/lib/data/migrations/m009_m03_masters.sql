-- NiAvERP migration v9 — M03 masters (implementation Phase 02, gate G1).
-- New master tables per DSS §3 catalogue + DB §3 entity catalogue + REG M03:
-- party (+ addresses), unit, item_group, voucher_type, voucher_series, and a
-- generic search_alias table (strategy Slice 2; M12.3 alias matching without
-- transliteration, G0-DEF-003). Extends item with the documented M03.8
-- nullable columns only (code/barcode/HSN/GST-rate/tax-link/group/unit-link).
-- Columns NOT created (explicit boundaries, later slices): ledger/account
-- masters (prompt 04), price/MRP/stock-level/opening columns (Slice 4),
-- batch/serial (M03.11 P2 / M03.12 P3), price lists/schemes (P2),
-- salesperson/commission (P3), narration templates (P2), currencies (P3 TBC),
-- numbering behavior (prompt 03A; registry storage only here).
-- Party ledger linkage is a nullable TEXT hook (no ledger table yet).
-- GSTIN/mobile stored as-entered text (format rules pending M17/G3).
-- Traceability: DSS §3; DB §3; REG M03.3/8/9/10/16/19, M12.3; D-M4; DSS-C-001.

CREATE TABLE IF NOT EXISTS party (
  party_id    TEXT PRIMARY KEY,
  company_id  TEXT NOT NULL REFERENCES company (company_id),
  ledger_id   TEXT NULL,
  name        TEXT NOT NULL,
  role        TEXT NOT NULL CHECK (role IN ('customer', 'supplier')),
  gstin       TEXT NULL,
  state       TEXT NULL,
  mobile      TEXT NULL,
  address     TEXT NULL,
  terms       TEXT NULL,
  created_at  INTEGER NOT NULL,
  record_version INTEGER NOT NULL DEFAULT 1 CHECK (record_version >= 1)
);
CREATE INDEX IF NOT EXISTS idx_party_company_name ON party (company_id, name);
CREATE INDEX IF NOT EXISTS idx_party_name_gstin ON party (name, gstin);

CREATE TABLE IF NOT EXISTS party_address (
  address_id  TEXT PRIMARY KEY,
  company_id  TEXT NOT NULL REFERENCES company (company_id),
  party_id    TEXT NOT NULL REFERENCES party (party_id),
  label       TEXT NULL,
  address     TEXT NOT NULL,
  created_at  INTEGER NOT NULL,
  record_version INTEGER NOT NULL DEFAULT 1 CHECK (record_version >= 1)
);
CREATE INDEX IF NOT EXISTS idx_party_address_party ON party_address (party_id);

CREATE TABLE IF NOT EXISTS unit (
  unit_id       TEXT PRIMARY KEY,
  company_id    TEXT NOT NULL REFERENCES company (company_id),
  name          TEXT NOT NULL,
  base_unit_id  TEXT NULL REFERENCES unit (unit_id),
  factor        INTEGER NOT NULL DEFAULT 1 CHECK (factor > 0),
  scale         INTEGER NULL CHECK (scale IS NULL OR (scale >= 0 AND scale <= 4)),
  created_at    INTEGER NOT NULL,
  record_version INTEGER NOT NULL DEFAULT 1 CHECK (record_version >= 1),
  UNIQUE (company_id, name)
);
CREATE INDEX IF NOT EXISTS idx_unit_company ON unit (company_id);

CREATE TABLE IF NOT EXISTS item_group (
  group_id    TEXT PRIMARY KEY,
  company_id  TEXT NOT NULL REFERENCES company (company_id),
  parent_id   TEXT NULL REFERENCES item_group (group_id),
  name        TEXT NOT NULL,
  created_at  INTEGER NOT NULL,
  record_version INTEGER NOT NULL DEFAULT 1 CHECK (record_version >= 1),
  UNIQUE (company_id, name)
);
CREATE INDEX IF NOT EXISTS idx_item_group_parent ON item_group (parent_id);

CREATE TABLE IF NOT EXISTS voucher_type (
  type_id     TEXT PRIMARY KEY,
  company_id  TEXT NOT NULL REFERENCES company (company_id),
  base_type   TEXT NOT NULL,
  name        TEXT NOT NULL,
  created_at  INTEGER NOT NULL,
  record_version INTEGER NOT NULL DEFAULT 1 CHECK (record_version >= 1)
);
CREATE INDEX IF NOT EXISTS idx_voucher_type_company ON voucher_type (company_id);

CREATE TABLE IF NOT EXISTS voucher_series (
  series_id   TEXT PRIMARY KEY,
  company_id  TEXT NOT NULL REFERENCES company (company_id),
  type_id     TEXT NOT NULL REFERENCES voucher_type (type_id),
  name        TEXT NOT NULL,
  prefix      TEXT NULL,
  suffix      TEXT NULL,
  start_no    INTEGER NOT NULL DEFAULT 1 CHECK (start_no > 0),
  width       INTEGER NOT NULL DEFAULT 0 CHECK (width >= 0),
  restart     TEXT NULL,
  created_at  INTEGER NOT NULL,
  record_version INTEGER NOT NULL DEFAULT 1 CHECK (record_version >= 1)
);
CREATE INDEX IF NOT EXISTS idx_voucher_series_type ON voucher_series (company_id, type_id);

-- Generic alias infrastructure: user-entered Latin/native-script spellings
-- per entity (no automatic transliteration, G0-DEF-003). Entity vocabulary
-- here is exactly the two mastered entities of this migration.
CREATE TABLE IF NOT EXISTS search_alias (
  alias_id    TEXT PRIMARY KEY,
  company_id  TEXT NOT NULL REFERENCES company (company_id),
  entity      TEXT NOT NULL CHECK (entity IN ('party', 'item')),
  entity_id   TEXT NOT NULL,
  alias       TEXT NOT NULL,
  created_at  INTEGER NOT NULL,
  UNIQUE (company_id, entity, entity_id, alias)
);
CREATE INDEX IF NOT EXISTS idx_search_alias_text ON search_alias (company_id, entity, alias);

-- __ADD_COLUMN__ item code
ALTER TABLE item ADD COLUMN code TEXT NULL;
-- __ADD_COLUMN__ item barcode
ALTER TABLE item ADD COLUMN barcode TEXT NULL;
-- __ADD_COLUMN__ item hsn_code
ALTER TABLE item ADD COLUMN hsn_code TEXT NULL;
-- __ADD_COLUMN__ item gst_rate_bps
ALTER TABLE item ADD COLUMN gst_rate_bps INTEGER NULL CHECK (gst_rate_bps IS NULL OR (gst_rate_bps >= 0 AND gst_rate_bps <= 10000));
-- __ADD_COLUMN__ item tax_rate_id
ALTER TABLE item ADD COLUMN tax_rate_id TEXT NULL REFERENCES tax_rate_hsn (rate_id);
-- __ADD_COLUMN__ item group_id
ALTER TABLE item ADD COLUMN group_id TEXT NULL REFERENCES item_group (group_id);
-- __ADD_COLUMN__ item unit_id
ALTER TABLE item ADD COLUMN unit_id TEXT NULL REFERENCES unit (unit_id);
CREATE INDEX IF NOT EXISTS idx_item_code_barcode ON item (company_id, code, barcode);
