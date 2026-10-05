-- NiAvERP migration v2 — G0-SCH-001: cost layers and stock movements (gate G1).
-- FIFO / weighted-average costing structures with negative-stock fallback
-- (last-known-cost) and later reconciliation. V1 never rewrites history:
-- reconciliation appends `reconciled` movements.
-- Money INTEGER paise; quantity INTEGER x10^4 (D-M4). Unit cost is derived
-- from (value_paise, qty_q4), never stored (DB/DSS D-M4 resolution).
-- Traceability: DB/DSS G0-SCH-001; D-M5/D-08/OD-DB-002; FR-M07-003.

CREATE TABLE IF NOT EXISTS stock_cost_layer (
  layer_id         TEXT PRIMARY KEY,
  company_id       TEXT NOT NULL REFERENCES company (company_id),
  item_id          TEXT NOT NULL REFERENCES item (item_id),
  godown_id        TEXT NOT NULL REFERENCES godown (godown_id),
  voucher_line_id  TEXT REFERENCES voucher_line (voucher_line_id),
  qty_q4           INTEGER NOT NULL,
  value_paise      INTEGER NOT NULL CHECK (value_paise >= 0),
  created_at       INTEGER NOT NULL,
  record_version   INTEGER NOT NULL DEFAULT 1 CHECK (record_version >= 1)
);
CREATE INDEX IF NOT EXISTS idx_layer_item_godown
  ON stock_cost_layer (company_id, item_id, godown_id);

CREATE TABLE IF NOT EXISTS stock_movement (
  movement_id       TEXT PRIMARY KEY,
  company_id        TEXT NOT NULL REFERENCES company (company_id),
  item_id           TEXT NOT NULL REFERENCES item (item_id),
  godown_id         TEXT NOT NULL REFERENCES godown (godown_id),
  qty_delta_q4      INTEGER NOT NULL CHECK (qty_delta_q4 != 0),
  cost_paise        INTEGER NOT NULL CHECK (cost_paise >= 0),
  cost_source       TEXT NOT NULL,
  voucher_line_id   TEXT REFERENCES voucher_line (voucher_line_id),
  operation_id      TEXT REFERENCES operation (op_id),
  created_at        INTEGER NOT NULL,
  record_version    INTEGER NOT NULL DEFAULT 1 CHECK (record_version >= 1)
);
CREATE INDEX IF NOT EXISTS idx_movement_item_godown
  ON stock_movement (company_id, item_id, godown_id);
CREATE INDEX IF NOT EXISTS idx_movement_voucher_line
  ON stock_movement (voucher_line_id);

-- Approved last-known-cost fallback store (negative-stock pricing when no
-- layer exists; later reconciliation appends, never rewrites).
CREATE TABLE IF NOT EXISTS item_cost_state (
  item_id                 TEXT PRIMARY KEY REFERENCES item (item_id),
  last_known_cost_paise   INTEGER NOT NULL CHECK (last_known_cost_paise >= 0),
  updated_at              INTEGER NOT NULL
);
