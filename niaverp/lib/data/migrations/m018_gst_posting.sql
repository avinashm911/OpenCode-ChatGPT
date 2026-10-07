-- NiAvERP migration v18 — GST tax posting context (CA reply 2026-10-07).
-- Additive only, repeat-safe through the runner's __ADD_COLUMN__ guards.
-- Carries the CA-approved inputs and audit trail for per-line tax posting:
-- supplier location (company.state_code), buyer classification
-- (party.registration_type), voucher place-of-supply context (bill/ship
-- states, third-party-direction flag, supply category) and the determined
-- values written at posting (pos_state, tax_type), plus per-line rate and
-- computed tax amounts. No tax logic in SQL: all rules live in the Dart tax
-- service and the voucher engine. UTGST/Cess ledgers and columns are NOT
-- created (out of v1 scope per the CA reply; see DECISIONS.md P-GST-POST).
-- Traceability: FR-M03-002; G0-VER-003; CA reply 2026-10-07 (Q1-Q4).

-- Supplier location: 2-digit GST state code of the company (supplier).
-- __ADD_COLUMN__ company state_code
ALTER TABLE company ADD COLUMN state_code TEXT NULL;

-- Buyer classification for place-of-supply rules. Free text validated in
-- Dart (registered / unregistered / composition); vocabulary deliberately
-- NOT CHECK-constrained (not specified in the documents).
-- __ADD_COLUMN__ party registration_type
ALTER TABLE party ADD COLUMN registration_type TEXT NULL;

-- Voucher place-of-supply context (all NULL = unspecified / legacy).
-- __ADD_COLUMN__ voucher bill_state
ALTER TABLE voucher ADD COLUMN bill_state TEXT NULL;

-- __ADD_COLUMN__ voucher ship_state
ALTER TABLE voucher ADD COLUMN ship_state TEXT NULL;

-- 1 = goods delivered on a third party's direction (IGST Act s.10(1)(b)).
-- __ADD_COLUMN__ voucher third_party_direction
ALTER TABLE voucher ADD COLUMN third_party_direction INTEGER NULL DEFAULT 0 CHECK (third_party_direction IS NULL OR third_party_direction IN (0, 1));

-- Supply category. NULL/regular = normal taxable supply; any other value
-- restricts posting (reverse_charge / export_sez / zero_rated / composition /
-- services block auto-posting; exempt / nil_rated allow tax-free lines only).
-- Vocabulary validated in Dart (CA reply Q2/Q4).
-- __ADD_COLUMN__ voucher supply_category
ALTER TABLE voucher ADD COLUMN supply_category TEXT NULL;

-- Determined at posting time (audit trail, never an input).
-- __ADD_COLUMN__ voucher pos_state
ALTER TABLE voucher ADD COLUMN pos_state TEXT NULL;

-- __ADD_COLUMN__ voucher tax_type
ALTER TABLE voucher ADD COLUMN tax_type TEXT NULL;

-- Per-line GST rate in basis points. NULL = tax-free line (always allowed).
-- __ADD_COLUMN__ voucher_line rate_bps
ALTER TABLE voucher_line ADD COLUMN rate_bps INTEGER NULL CHECK (rate_bps IS NULL OR (rate_bps >= 0 AND rate_bps <= 10000));

-- Per-line computed tax (written at posting for audit; arms carry the money).
-- __ADD_COLUMN__ voucher_line cgst_paise
ALTER TABLE voucher_line ADD COLUMN cgst_paise INTEGER NOT NULL DEFAULT 0 CHECK (cgst_paise >= 0);

-- __ADD_COLUMN__ voucher_line sgst_paise
ALTER TABLE voucher_line ADD COLUMN sgst_paise INTEGER NOT NULL DEFAULT 0 CHECK (sgst_paise >= 0);

-- __ADD_COLUMN__ voucher_line igst_paise
ALTER TABLE voucher_line ADD COLUMN igst_paise INTEGER NOT NULL DEFAULT 0 CHECK (igst_paise >= 0);
