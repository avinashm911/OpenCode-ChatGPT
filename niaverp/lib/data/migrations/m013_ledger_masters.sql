-- NiAvERP migration v13 — ledger masters (gate G1).
-- Source-specified (DB §3 entity catalogue + FR-M03-002):
--   account_group: group/company/parent/name (self-tree like item_group).
--   ledger: identity + company/group FKs + name + opening side/value +
--     bill-wise flag. Contact/address/bank/GST detail columns wait on their
--     specs (FR-M03-002/004, G3 for tax); duplicate names collide per
--     company (FR-M03-002 duplicate handling).
-- Balances are NOT stored here: per DSS they are derived from posted
-- voucher lines (ledger refs + Dr/Cr) and rebuilt by query.
-- Traceability: DB §3 (account_group, ledger); FR-M03-002; DSS-C-001.

CREATE TABLE IF NOT EXISTS account_group (
  group_id    TEXT PRIMARY KEY,
  company_id  TEXT NOT NULL REFERENCES company (company_id),
  parent_group_id TEXT NULL REFERENCES account_group (group_id),
  name        TEXT NOT NULL,
  created_at  INTEGER NOT NULL,
  record_version INTEGER NOT NULL DEFAULT 1 CHECK (record_version >= 1),
  UNIQUE (company_id, name)
);
CREATE INDEX IF NOT EXISTS idx_account_group_parent
  ON account_group (parent_group_id);

CREATE TABLE IF NOT EXISTS ledger (
  ledger_id     TEXT PRIMARY KEY,
  company_id    TEXT NOT NULL REFERENCES company (company_id),
  group_id      TEXT NOT NULL REFERENCES account_group (group_id),
  name          TEXT NOT NULL,
  opening_side  TEXT NULL CHECK (opening_side IS NULL OR opening_side IN ('Dr', 'Cr')),
  opening_paise INTEGER NOT NULL DEFAULT 0 CHECK (opening_paise >= 0),
  billwise      INTEGER NOT NULL DEFAULT 0 CHECK (billwise IN (0, 1)),
  created_at    INTEGER NOT NULL,
  record_version INTEGER NOT NULL DEFAULT 1 CHECK (record_version >= 1),
  UNIQUE (company_id, name)
);
CREATE INDEX IF NOT EXISTS idx_ledger_group ON ledger (company_id, group_id);
