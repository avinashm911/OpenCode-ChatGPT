-- NiAvERP migration v4 — G0-SCH-003: bill allocation (gate G1).
-- Source voucher line + settlement voucher line + allocated amount + date +
-- status + operation lineage. Over-allocation rejection and settlement
-- arithmetic are Phase 2 fixture logic over this table.
-- Traceability: DB/DSS G0-SCH-003; FR-M06.

CREATE TABLE IF NOT EXISTS bill_allocation (
  allocation_id              TEXT PRIMARY KEY,
  company_id                 TEXT NOT NULL REFERENCES company (company_id),
  source_voucher_line_id     TEXT NOT NULL REFERENCES voucher_line (voucher_line_id),
  settlement_voucher_line_id TEXT NOT NULL REFERENCES voucher_line (voucher_line_id),
  allocated_amount_paise     INTEGER NOT NULL CHECK (allocated_amount_paise >= 0),
  allocation_date            TEXT NOT NULL,
  status                     TEXT NOT NULL,
  operation_id               TEXT NOT NULL REFERENCES operation (op_id),
  created_at                 INTEGER NOT NULL,
  record_version             INTEGER NOT NULL DEFAULT 1 CHECK (record_version >= 1),
  CHECK (settlement_voucher_line_id != source_voucher_line_id)
);
CREATE INDEX IF NOT EXISTS idx_alloc_source
  ON bill_allocation (source_voucher_line_id);
CREATE INDEX IF NOT EXISTS idx_alloc_settlement
  ON bill_allocation (settlement_voucher_line_id);
CREATE INDEX IF NOT EXISTS idx_alloc_company_date
  ON bill_allocation (company_id, allocation_date);
