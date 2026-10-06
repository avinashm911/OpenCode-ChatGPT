-- NiAvERP migration v17 — schema and security hardening (D2).
-- Additive only, repeat-safe (IF NOT EXISTS objects, guarded ADD COLUMNs), no
-- retro revaluation, no column dropped or rewritten.
-- NOTE on single-line triggers: the migration runner splits statements on
-- line-final semicolons, so every trigger body below is written on ONE line.
--
--   A1 (DB-004 append-only audit; DSS-C-003): audit_event and operation reject
--     UPDATE and DELETE outright. No lib/ or test code updates those tables
--     (audit_append_only_test proves the absence statically).
--   A2 (DSS-C-003 no destructive posted delete; M04 common states): posted or
--     cancelled voucher rows accept only the posted→cancelled status move with
--     all other columns unchanged (record_version may stay or increment by
--     one, per D1); voucher_line rows of a posted/cancelled voucher accept no
--     UPDATE or DELETE. Draft/held/resumed rows are unaffected.
--   A3 (OD-DB-004 hash chain): audit_event gains prev_hash/row_hash (NULL for
--     pre-chain rows); the Dart writer chains them, verifyAuditChain checks.
--   B1 (vocabularies from code+docs only): BEFORE INSERT/UPDATE validation
--     triggers with RAISE(ABORT). Values: voucher.status draft/held/resumed/
--     posted/cancelled (engine + updateHeldStatus); period_lock.status
--     locked/unlocked (P-PERIODLOCK) — scope intentionally NOT constrained
--     (MIGRATION_DESIGN: scope vocabulary is app policy, not schema);
--     bill_allocation active/reversed (settlement.dart); document_link
--     active/reversed (document_link_repository); stock_movement.cost_source
--     layer/last_known/reconciled (MIGRATION_DESIGN G0-SCH-001) + average/fifo/
--     fifo-fallback (costing.dart priced sources) + fallback/zero (engine
--     shortfall paths) + reversal (D1 compensating movements);
--     operation.action create/post/correct/reverse/consume/status-change/
--     update/unlock (all ops.append call sites). financial_year.status stays
--     free TEXT (m011 documents the vocabulary as unspecified — recorded
--     open); lifecycle TRANSITIONS stay app logic, these triggers check
--     vocabulary only.
--   B2/B3 (DSS-C-001 company isolation; DB §3 catalogue FKs): voucher_line
--     item/party/ledger/godown refs must resolve in the voucher's own company
--     (covers the documented voucher_line.ledger FK without a table rebuild);
--     party.ledger_id must resolve in the party's company (documented
--     company_id/ledger FKs). bank_account.ledger already has a real FK.
--   B4: NO name-uniqueness constraint added — the documents specify
--     UNIQUE(company,name) only for unit, item_group, account_group, ledger,
--     role, financial_year start and bank (company,ledger), all already built;
--     item/party/godown/voucher_type/voucher_series names are idx-only in the
--     Data Schema catalogue, and phase-02 keeps godown uniqueness at
--     repository level. Recorded blocked (D2-B4 question).
--   B5 (DSS-C-007/DB §8 migration integrity): schema_migrations.checksum holds
--     the SHA-256 of the applied migration text; the runner backfills legacy
--     NULLs (trust-on-first-use, documented) and refuses to run on mismatch.
--   C1 (query-backed indexes only): company-scoped voucher_line item/party/
--     ledger/godown; voucher (company,fy) and (company,type,date); party
--     (company,name,gstin); audit_event and operation (company,created_at,id)
--     for time-ordered reads. No latency target invented (M12.8 TBC).
--   E3 (SEC §3.5 trusted_now): trial_anchor.last_seen_at persists the clock
--     high-water mark; evaluation uses trusted_now = max(device, mark).
--
-- Traceability: DB-004/DB-005/DSS-C-001/C-003/C-007; OD-DB-004/006; D-M5; D-04;
-- FR-M06/M11/M18-002; SEC §3.5; D2 (A1-A3/B1-B3/B5/C1/E3).

-- __ADD_COLUMN__ audit_event prev_hash
ALTER TABLE audit_event ADD COLUMN prev_hash TEXT NULL;

-- __ADD_COLUMN__ audit_event row_hash
ALTER TABLE audit_event ADD COLUMN row_hash TEXT NULL;

-- __ADD_COLUMN__ schema_migrations checksum
ALTER TABLE schema_migrations ADD COLUMN checksum TEXT NULL;

-- __ADD_COLUMN__ trial_anchor last_seen_at
ALTER TABLE trial_anchor ADD COLUMN last_seen_at INTEGER NULL;

-- A1: append-only audit_event and operation.
CREATE TRIGGER IF NOT EXISTS trg_audit_event_no_update BEFORE UPDATE ON audit_event BEGIN SELECT RAISE(ABORT, 'audit-event-append-only'); END;
CREATE TRIGGER IF NOT EXISTS trg_audit_event_no_delete BEFORE DELETE ON audit_event BEGIN SELECT RAISE(ABORT, 'audit-event-append-only'); END;
CREATE TRIGGER IF NOT EXISTS trg_operation_no_update BEFORE UPDATE ON operation BEGIN SELECT RAISE(ABORT, 'operation-append-only'); END;
CREATE TRIGGER IF NOT EXISTS trg_operation_no_delete BEFORE DELETE ON operation BEGIN SELECT RAISE(ABORT, 'operation-append-only'); END;

-- A2: posted/cancelled voucher protection (only posted→cancelled, other columns frozen).
CREATE TRIGGER IF NOT EXISTS trg_voucher_posted_update BEFORE UPDATE ON voucher WHEN OLD.status IN ('posted', 'cancelled') BEGIN SELECT CASE WHEN NOT (OLD.status = 'posted' AND NEW.status = 'cancelled' AND NEW.voucher_id IS OLD.voucher_id AND NEW.company_id IS OLD.company_id AND NEW.voucher_type IS OLD.voucher_type AND NEW.series IS OLD.series AND NEW.voucher_no IS OLD.voucher_no AND NEW.voucher_date IS OLD.voucher_date AND NEW.created_at IS OLD.created_at AND NEW.narration IS OLD.narration AND NEW.actor IS OLD.actor AND NEW.device IS OLD.device AND NEW.fy_id IS OLD.fy_id AND (NEW.record_version IS OLD.record_version OR NEW.record_version = OLD.record_version + 1)) THEN RAISE(ABORT, 'voucher-posted-immutable') END; END;
CREATE TRIGGER IF NOT EXISTS trg_voucher_posted_delete BEFORE DELETE ON voucher WHEN OLD.status IN ('posted', 'cancelled') BEGIN SELECT RAISE(ABORT, 'voucher-posted-immutable'); END;
CREATE TRIGGER IF NOT EXISTS trg_voucher_line_posted_update BEFORE UPDATE ON voucher_line WHEN (SELECT v.status FROM voucher v WHERE v.voucher_id = OLD.voucher_id) IN ('posted', 'cancelled') BEGIN SELECT RAISE(ABORT, 'voucher-line-posted-immutable'); END;
CREATE TRIGGER IF NOT EXISTS trg_voucher_line_posted_delete BEFORE DELETE ON voucher_line WHEN (SELECT v.status FROM voucher v WHERE v.voucher_id = OLD.voucher_id) IN ('posted', 'cancelled') BEGIN SELECT RAISE(ABORT, 'voucher-line-posted-immutable'); END;

-- B1: enum/status vocabulary validation (vocabulary only; transitions stay app logic).
CREATE TRIGGER IF NOT EXISTS trg_voucher_status_ins BEFORE INSERT ON voucher WHEN NEW.status NOT IN ('draft', 'held', 'resumed', 'posted', 'cancelled') BEGIN SELECT RAISE(ABORT, 'voucher-status-vocab'); END;
CREATE TRIGGER IF NOT EXISTS trg_voucher_status_upd BEFORE UPDATE ON voucher WHEN NEW.status NOT IN ('draft', 'held', 'resumed', 'posted', 'cancelled') BEGIN SELECT RAISE(ABORT, 'voucher-status-vocab'); END;
CREATE TRIGGER IF NOT EXISTS trg_period_lock_status_ins BEFORE INSERT ON period_lock WHEN NEW.status NOT IN ('locked', 'unlocked') BEGIN SELECT RAISE(ABORT, 'period-lock-status-vocab'); END;
CREATE TRIGGER IF NOT EXISTS trg_period_lock_status_upd BEFORE UPDATE ON period_lock WHEN NEW.status NOT IN ('locked', 'unlocked') BEGIN SELECT RAISE(ABORT, 'period-lock-status-vocab'); END;
CREATE TRIGGER IF NOT EXISTS trg_bill_alloc_status_ins BEFORE INSERT ON bill_allocation WHEN NEW.status NOT IN ('active', 'reversed') BEGIN SELECT RAISE(ABORT, 'bill-allocation-status-vocab'); END;
CREATE TRIGGER IF NOT EXISTS trg_bill_alloc_status_upd BEFORE UPDATE ON bill_allocation WHEN NEW.status NOT IN ('active', 'reversed') BEGIN SELECT RAISE(ABORT, 'bill-allocation-status-vocab'); END;
CREATE TRIGGER IF NOT EXISTS trg_doc_link_status_ins BEFORE INSERT ON document_link WHEN NEW.status NOT IN ('active', 'reversed') BEGIN SELECT RAISE(ABORT, 'document-link-status-vocab'); END;
CREATE TRIGGER IF NOT EXISTS trg_doc_link_status_upd BEFORE UPDATE ON document_link WHEN NEW.status NOT IN ('active', 'reversed') BEGIN SELECT RAISE(ABORT, 'document-link-status-vocab'); END;
CREATE TRIGGER IF NOT EXISTS trg_movement_cost_source_ins BEFORE INSERT ON stock_movement WHEN NEW.cost_source NOT IN ('layer', 'last_known', 'reconciled', 'average', 'fifo', 'fifo-fallback', 'fallback', 'zero', 'reversal') BEGIN SELECT RAISE(ABORT, 'movement-cost-source-vocab'); END;
CREATE TRIGGER IF NOT EXISTS trg_movement_cost_source_upd BEFORE UPDATE ON stock_movement WHEN NEW.cost_source NOT IN ('layer', 'last_known', 'reconciled', 'average', 'fifo', 'fifo-fallback', 'fallback', 'zero', 'reversal') BEGIN SELECT RAISE(ABORT, 'movement-cost-source-vocab'); END;
CREATE TRIGGER IF NOT EXISTS trg_operation_action_ins BEFORE INSERT ON operation WHEN NEW.action NOT IN ('create', 'post', 'correct', 'reverse', 'consume', 'status-change', 'update', 'unlock') BEGIN SELECT RAISE(ABORT, 'operation-action-vocab'); END;
CREATE TRIGGER IF NOT EXISTS trg_operation_action_upd BEFORE UPDATE ON operation WHEN NEW.action NOT IN ('create', 'post', 'correct', 'reverse', 'consume', 'status-change', 'update', 'unlock') BEGIN SELECT RAISE(ABORT, 'operation-action-vocab'); END;

-- B2/B3: voucher_line refs resolve in the voucher's own company (existence + scope, no rebuild).
CREATE TRIGGER IF NOT EXISTS trg_voucher_line_company_ins BEFORE INSERT ON voucher_line BEGIN SELECT CASE WHEN NOT ((NEW.item_id IS NULL OR EXISTS (SELECT 1 FROM item i WHERE i.item_id = NEW.item_id AND i.company_id = (SELECT v.company_id FROM voucher v WHERE v.voucher_id = NEW.voucher_id))) AND (NEW.party_id IS NULL OR EXISTS (SELECT 1 FROM party p WHERE p.party_id = NEW.party_id AND p.company_id = (SELECT v.company_id FROM voucher v WHERE v.voucher_id = NEW.voucher_id))) AND (NEW.ledger_id IS NULL OR EXISTS (SELECT 1 FROM ledger l WHERE l.ledger_id = NEW.ledger_id AND l.company_id = (SELECT v.company_id FROM voucher v WHERE v.voucher_id = NEW.voucher_id))) AND (NEW.godown_id IS NULL OR EXISTS (SELECT 1 FROM godown g WHERE g.godown_id = NEW.godown_id AND g.company_id = (SELECT v.company_id FROM voucher v WHERE v.voucher_id = NEW.voucher_id)))) THEN RAISE(ABORT, 'voucher-line-foreign-company') END; END;
CREATE TRIGGER IF NOT EXISTS trg_voucher_line_company_upd BEFORE UPDATE OF item_id, party_id, ledger_id, godown_id ON voucher_line BEGIN SELECT CASE WHEN NOT ((NEW.item_id IS NULL OR EXISTS (SELECT 1 FROM item i WHERE i.item_id = NEW.item_id AND i.company_id = (SELECT v.company_id FROM voucher v WHERE v.voucher_id = NEW.voucher_id))) AND (NEW.party_id IS NULL OR EXISTS (SELECT 1 FROM party p WHERE p.party_id = NEW.party_id AND p.company_id = (SELECT v.company_id FROM voucher v WHERE v.voucher_id = NEW.voucher_id))) AND (NEW.ledger_id IS NULL OR EXISTS (SELECT 1 FROM ledger l WHERE l.ledger_id = NEW.ledger_id AND l.company_id = (SELECT v.company_id FROM voucher v WHERE v.voucher_id = NEW.voucher_id))) AND (NEW.godown_id IS NULL OR EXISTS (SELECT 1 FROM godown g WHERE g.godown_id = NEW.godown_id AND g.company_id = (SELECT v.company_id FROM voucher v WHERE v.voucher_id = NEW.voucher_id)))) THEN RAISE(ABORT, 'voucher-line-foreign-company') END; END;
CREATE TRIGGER IF NOT EXISTS trg_party_ledger_ins BEFORE INSERT ON party WHEN NEW.ledger_id IS NOT NULL BEGIN SELECT CASE WHEN NOT EXISTS (SELECT 1 FROM ledger l WHERE l.ledger_id = NEW.ledger_id AND l.company_id = NEW.company_id) THEN RAISE(ABORT, 'party-ledger-foreign-company') END; END;
CREATE TRIGGER IF NOT EXISTS trg_party_ledger_upd BEFORE UPDATE OF ledger_id ON party WHEN NEW.ledger_id IS NOT NULL BEGIN SELECT CASE WHEN NOT EXISTS (SELECT 1 FROM ledger l WHERE l.ledger_id = NEW.ledger_id AND l.company_id = NEW.company_id) THEN RAISE(ABORT, 'party-ledger-foreign-company') END; END;

-- C1: company-scoped read indexes (query-backed; no latency target invented).
CREATE INDEX IF NOT EXISTS idx_voucher_line_company_item ON voucher_line (company_id, item_id);
CREATE INDEX IF NOT EXISTS idx_voucher_line_company_party ON voucher_line (company_id, party_id);
CREATE INDEX IF NOT EXISTS idx_voucher_line_company_ledger ON voucher_line (company_id, ledger_id);
CREATE INDEX IF NOT EXISTS idx_voucher_line_company_godown ON voucher_line (company_id, godown_id);
CREATE INDEX IF NOT EXISTS idx_voucher_company_fy ON voucher (company_id, fy_id);
CREATE INDEX IF NOT EXISTS idx_voucher_company_type_date ON voucher (company_id, voucher_type, voucher_date);
CREATE INDEX IF NOT EXISTS idx_party_company_name_gstin ON party (company_id, name, gstin);
CREATE INDEX IF NOT EXISTS idx_audit_company_time ON audit_event (company_id, created_at, event_id);
CREATE INDEX IF NOT EXISTS idx_operation_company_time ON operation (company_id, created_at, op_id);
