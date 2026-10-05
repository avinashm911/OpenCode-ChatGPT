-- NiAvERP migration v10 — DSS transaction enrichment (gate G1).
-- Source-specified columns only (DSS §3 table catalogue + DB §3 entity
-- catalogue, corroborated by both documents):
--   voucher: narration, actor (= DSS "user", house term per audit_event),
--     device (all nullable TEXT; fy/type/series FK conversion waits on the
--     financial_year table and the TEXT-registry numbering design — pending).
--   voucher_line: ledger_id, party_id, godown_id, batch_id (nullable refs;
--     party/godown FK-enforced, tables exist; ledger/batch plain TEXT until
--     ledger masters / batch P2 land). Tax columns wait on G3 schema
--     verification (OD-DB-003); Dr/Cr sign convention waits on its spec;
--     uq_series_scope stays a repo-level guard until a rebuild migration.
--   document_link: lineage table exactly per spec (link/company/source +
--     target voucher+line refs, qty, status) + house record_version.
-- D-M4 storage rules throughout: TEXT UUIDv7 ids, INTEGER paise/Q4, ISO dates.
-- Traceability: DSS §3 (voucher/voucher_line/document_link rows); DB §3;
-- FR-M04–M09; DSS-C-001.

-- __ADD_COLUMN__ voucher narration
ALTER TABLE voucher ADD COLUMN narration TEXT NULL;
-- __ADD_COLUMN__ voucher actor
ALTER TABLE voucher ADD COLUMN actor TEXT NULL;
-- __ADD_COLUMN__ voucher device
ALTER TABLE voucher ADD COLUMN device TEXT NULL;

-- __ADD_COLUMN__ voucher_line ledger_id
ALTER TABLE voucher_line ADD COLUMN ledger_id TEXT NULL;
-- __ADD_COLUMN__ voucher_line party_id
ALTER TABLE voucher_line ADD COLUMN party_id TEXT NULL REFERENCES party (party_id);
-- __ADD_COLUMN__ voucher_line godown_id
ALTER TABLE voucher_line ADD COLUMN godown_id TEXT NULL REFERENCES godown (godown_id);
-- __ADD_COLUMN__ voucher_line batch_id
ALTER TABLE voucher_line ADD COLUMN batch_id TEXT NULL;

CREATE TABLE IF NOT EXISTS document_link (
  link_id             TEXT PRIMARY KEY,
  company_id          TEXT NOT NULL REFERENCES company (company_id),
  source_voucher_id   TEXT NOT NULL REFERENCES voucher (voucher_id),
  source_line_id      TEXT REFERENCES voucher_line (voucher_line_id),
  target_voucher_id   TEXT NOT NULL REFERENCES voucher (voucher_id),
  target_line_id      TEXT REFERENCES voucher_line (voucher_line_id),
  qty_q4              INTEGER NOT NULL,
  status              TEXT NOT NULL,
  created_at          INTEGER NOT NULL,
  record_version      INTEGER NOT NULL DEFAULT 1 CHECK (record_version >= 1)
);
CREATE INDEX IF NOT EXISTS idx_doc_link_source_target
  ON document_link (company_id, source_voucher_id, target_voucher_id);
