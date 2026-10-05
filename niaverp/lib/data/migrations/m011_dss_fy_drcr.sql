-- NiAvERP migration v11 — DSS financial year + Dr/Cr convention (gate G1).
-- Source-specified only (DB §3 entity catalogue):
--   financial_year: fy_id PK, company FK, start/end/status (UNIQUE per
--     company+start = uq_company_fy). Status stays free TEXT: the open/
--     closed vocabulary is unspecified — recorded open.
--   voucher.fy_id: nullable FK (existing rows predate FY context; company
--     FY-start/books-begin config in FR-M01-001 still pending, so no
--     enforcement reads this column yet).
--   voucher_line.dr_cr: nullable TEXT CHECK IN ('Dr','Cr') — the DSS
--     "Dr/Cr" field, values literal from source. Convention (owner-directed):
--     item-quantity lines carry signed qty and must NOT carry Dr/Cr
--     (established by lineAmount sign behavior); ledger-amount lines use
--     Dr/Cr once ledger masters exist (full enforcement then).
-- NOT in this migration (recorded boundaries): tax columns (G3 schema
-- verification, OD-DB-003), uq_series_scope rebuild, ledger/batch masters.
-- Traceability: DB §3 (financial_year, voucher fy, voucher_line Dr/Cr);
-- DSS §3; FR-M04–M07; D-M4 (ISO dates).

CREATE TABLE IF NOT EXISTS financial_year (
  fy_id         TEXT PRIMARY KEY,
  company_id    TEXT NOT NULL REFERENCES company (company_id),
  start_date    TEXT NOT NULL,
  end_date      TEXT NOT NULL CHECK (end_date >= start_date),
  status        TEXT NOT NULL,
  created_at    INTEGER NOT NULL,
  record_version INTEGER NOT NULL DEFAULT 1 CHECK (record_version >= 1),
  UNIQUE (company_id, start_date)
);
CREATE INDEX IF NOT EXISTS idx_fy_company ON financial_year (company_id);

-- __ADD_COLUMN__ voucher fy_id
ALTER TABLE voucher ADD COLUMN fy_id TEXT NULL REFERENCES financial_year (fy_id);
-- __ADD_COLUMN__ voucher_line dr_cr
ALTER TABLE voucher_line ADD COLUMN dr_cr TEXT NULL
  CHECK (dr_cr IS NULL OR dr_cr IN ('Dr', 'Cr'));
