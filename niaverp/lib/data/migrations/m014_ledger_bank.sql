-- NiAvERP migration v14 — ledger detail + bank masters (gate G1).
-- Source-specified (DB §3 entity catalogue + FR-M03-002/004):
--   ledger: credit limit/days, contact, address, bank details (nullable;
--     credit values >= 0). GST detail columns stay OUT: tax schemas wait on
--     G3 verification (OD-DB-003, P-FIELD-LIST) — recorded, not built.
--   bank_account: identity + company/ledger FKs + account no./IFSC/UPI ID
--     (nullable TEXT, stored as-entered; format rules are VERIFY before
--     release per FR-M03-004 — no format regex invented here). One account
--     row per ledger per company (bank ledger 1:1).
-- Cost centres (M03.5 P3) and currencies (M03.6 P3 TBC, V1 non-goal) are
-- explicitly NOT created here.
-- Traceability: DB §3 (ledger tax/bank metadata, bank_account); FR-M03-002
-- (REG M03.2); FR-M03-004 (REG M03.4); M03 P1 scope.
--
-- __ADD_COLUMN__ ledger credit_limit_paise
ALTER TABLE ledger ADD COLUMN credit_limit_paise INTEGER NULL CHECK (credit_limit_paise IS NULL OR credit_limit_paise >= 0);
-- __ADD_COLUMN__ ledger credit_days
ALTER TABLE ledger ADD COLUMN credit_days INTEGER NULL CHECK (credit_days IS NULL OR credit_days >= 0);
-- __ADD_COLUMN__ ledger contact
ALTER TABLE ledger ADD COLUMN contact TEXT NULL;
-- __ADD_COLUMN__ ledger address
ALTER TABLE ledger ADD COLUMN address TEXT NULL;
-- __ADD_COLUMN__ ledger bank_details
ALTER TABLE ledger ADD COLUMN bank_details TEXT NULL;

CREATE TABLE IF NOT EXISTS bank_account (
  bank_account_id TEXT PRIMARY KEY,
  company_id      TEXT NOT NULL REFERENCES company (company_id),
  ledger_id       TEXT NOT NULL REFERENCES ledger (ledger_id),
  account_no      TEXT NULL,
  ifsc            TEXT NULL,
  upi_id          TEXT NULL,
  created_at      INTEGER NOT NULL,
  record_version  INTEGER NOT NULL DEFAULT 1 CHECK (record_version >= 1),
  UNIQUE (company_id, ledger_id)
);
CREATE INDEX IF NOT EXISTS idx_bank_account_ledger
  ON bank_account (company_id, ledger_id);
