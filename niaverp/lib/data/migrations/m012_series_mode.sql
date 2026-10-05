-- NiAvERP migration v12 — series numbering mode (gate G1).
-- Source-specified (DB §3 series row lists "mode"; FR-M04-002 requires
-- manual-vs-auto): mode TEXT NULL CHECK IN ('auto','manual'). NULL means
-- manual — generation never surprises (safe default, recorded).
-- Deliberately absent (recorded boundaries, schema docs carry no home):
-- separator column (prefix/suffix are literal affixes and already contain
-- any separators, e.g. prefix 'INV-'), restart vocabulary (any non-null,
-- non-'never' restart is rejected by the engine until decided), and a
-- series-scope UNIQUE rebuild (repo-level guard stands, godown precedent).
-- Traceability: DB §3 (voucher_series mode); FR-M04-002; DSS-C-002; OD-001.

-- __ADD_COLUMN__ voucher_series mode
ALTER TABLE voucher_series ADD COLUMN mode TEXT NULL
  CHECK (mode IS NULL OR mode IN ('auto', 'manual'));
