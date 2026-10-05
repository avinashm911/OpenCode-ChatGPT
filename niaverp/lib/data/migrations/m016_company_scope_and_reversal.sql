-- NiAvERP migration v16 — company scope + reversal/costing link columns (D1).
-- Additive only, repeat-safe through the runner's __ADD_COLUMN__ guards, and
-- free of any retro revaluation: existing rows keep their values and existing
-- balances are untouched (D-M5/D-08 "no retro revaluation in V1").
--
--   item_cost_state.company_id: DSS-C-001 states every company-owned entity is
--     directly or transitively scoped to company_id. The last-known-cost store
--     was the one costing table read/written without company scope. Backfilled
--     from the owning item (its company), then indexed with the item id. Rows
--     stay one-per-item (item_id remains the key) so no unique index change is
--     needed and no rebuild is required.
--
--   stock_movement.reverses_movement_id: compensating (neutralising) stock
--     movements. The Functional Design defines a cancelled/reversed voucher as
--     one whose "effect is neutralized through an auditable operation, not
--     silent deletion" (M04 common states; DSS-C-003). The reversal is written
--     as a NEW movement row with the opposite quantity, carrying a self
--     reference to the movement it neutralises plus the cancelled voucher's
--     own line, so the pair is traceable without rewriting either row.
--
--   stock_movement.cost_method: D-M5 records that the valuation method locks
--     after the first posted stock MOVEMENT — not only after a layer-priced
--     one. A first issue priced by the fallback (last-known cost) or at zero
--     binds a method that cost_source alone cannot express, so the method
--     resolved at post time is persisted here (values 'fifo'/'wa'). NULL means
--     "not recorded" (pre-v16 rows); the lock then falls back to the historical
--     cost_source derivation, which leaves existing books unchanged.
--
-- Traceability: DSS-C-001 (company scope); DSS-C-003 + M04 common states
-- (cancelled/reversed = neutralised by auditable operation); D-M5/D-08;
-- FR-M05-001/FR-M07-001/002/003 (stock locations); D1 review item.

-- __ADD_COLUMN__ item_cost_state company_id
ALTER TABLE item_cost_state ADD COLUMN company_id TEXT NULL REFERENCES company (company_id);

-- Backfill from the owning item: one item, one company, so no ambiguity.
UPDATE item_cost_state
SET company_id = (SELECT company_id FROM item WHERE item.item_id = item_cost_state.item_id)
WHERE company_id IS NULL;

CREATE INDEX IF NOT EXISTS idx_cost_state_company_item
  ON item_cost_state (company_id, item_id);

-- __ADD_COLUMN__ stock_movement reverses_movement_id
ALTER TABLE stock_movement ADD COLUMN reverses_movement_id TEXT NULL REFERENCES stock_movement (movement_id);

CREATE INDEX IF NOT EXISTS idx_movement_reverses
  ON stock_movement (reverses_movement_id);

-- __ADD_COLUMN__ stock_movement cost_method
ALTER TABLE stock_movement ADD COLUMN cost_method TEXT NULL CHECK (cost_method IS NULL OR cost_method IN ('fifo', 'wa'));