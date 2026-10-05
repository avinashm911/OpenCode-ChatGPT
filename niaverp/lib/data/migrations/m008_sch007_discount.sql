-- NiAvERP migration v8 — G0-SCH-007: voucher-line discount (gate G1).
-- Discount amount (paise) + rate (basis points) with explicit calculation and
-- rounding behavior (see validators.dart: amount wins over rate; net floored
-- at zero; integers + round-half-up only; D-M4). Backfill: 0 (no discount).
-- Traceability: DB/DSS G0-SCH-007; FRD voucher lines; D-M4.

-- __ADD_COLUMN__ voucher_line discount_amount_paise INTEGER NOT NULL DEFAULT 0 CHECK (discount_amount_paise >= 0)
ALTER TABLE voucher_line ADD COLUMN discount_amount_paise INTEGER NOT NULL DEFAULT 0 CHECK (discount_amount_paise >= 0);

-- __ADD_COLUMN__ voucher_line discount_rate_bps INTEGER NOT NULL DEFAULT 0 CHECK (discount_rate_bps >= 0 AND discount_rate_bps <= 10000)
ALTER TABLE voucher_line ADD COLUMN discount_rate_bps INTEGER NOT NULL DEFAULT 0 CHECK (discount_rate_bps >= 0 AND discount_rate_bps <= 10000);
