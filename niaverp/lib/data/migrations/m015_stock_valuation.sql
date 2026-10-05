-- NiAvERP migration v15 — stock valuation method + layer books (gate G1).
-- Source-specified (D-M5/D-08 valuation policy; DB §3; FR-M07-003):
--   item_group.cost_method / item.cost_method: nullable TEXT 'fifo'/'wa'.
--     Item overrides group; group overrides the default Weighted Average
--     (NULL/NULL resolves to 'wa' at post time — no stored default needed).
--   stock_cost_layer.remaining_qty_q4 / remaining_value_paise: the live book
--     balances. qty_q4/value_paise stay the immutable receipt record;
--     remaining_* are decremented by outbound consumption (FIFO draws and
--     weighted-average book-keeping). Backfilled to full for pre-v15 layers.
-- Method lock needs no new column: it is derived from posted movement
-- history (first layer-priced outbound movement wins; see voucher engine).
-- No retro revaluation: this migration never touches existing values.
-- Traceability: D-M5/D-08 (D-FG-013/O-09/OD-004/OD-FD-001); FR-M07-003;
-- FR-M13-001 (policy); DB §3; DSS-C-007.
--
-- __ADD_COLUMN__ item_group cost_method
ALTER TABLE item_group ADD COLUMN cost_method TEXT NULL CHECK (cost_method IS NULL OR cost_method IN ('fifo', 'wa'));
-- __ADD_COLUMN__ item cost_method
ALTER TABLE item ADD COLUMN cost_method TEXT NULL CHECK (cost_method IS NULL OR cost_method IN ('fifo', 'wa'));
-- __ADD_COLUMN__ stock_cost_layer remaining_qty_q4
ALTER TABLE stock_cost_layer ADD COLUMN remaining_qty_q4 INTEGER NULL CHECK (remaining_qty_q4 IS NULL OR remaining_qty_q4 >= 0);
-- __ADD_COLUMN__ stock_cost_layer remaining_value_paise
ALTER TABLE stock_cost_layer ADD COLUMN remaining_value_paise INTEGER NULL CHECK (remaining_value_paise IS NULL OR remaining_value_paise >= 0);

UPDATE stock_cost_layer
SET remaining_qty_q4 = qty_q4, remaining_value_paise = value_paise
WHERE remaining_qty_q4 IS NULL OR remaining_value_paise IS NULL;
