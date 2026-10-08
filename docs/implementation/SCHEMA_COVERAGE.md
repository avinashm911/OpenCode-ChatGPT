# SCHEMA_COVERAGE — spec vs migrations m001–m018 (B0, read-only audit)

Date (UTC): 2026-10-08. Branch: `b0-20261008` (from `bb215de`).
Sources (read-only): `NiAv_Data_Schema_Specification_v0.1.html` §3 + §G0 banner, `NiAv_Database_Schema_Document_v0.1.html` §3 + §G0 banner, `niaverp/lib/data/migrations/migration_registry.dart:29-162` (`kLatestVersion = 18`), m001–m018 SQL files.
Rule: present = `CREATE TABLE` in named migration; ALTER-only columns noted separately; no migrations created by B0.

## 1. Migration chain (registry)
| v | g0Id | file |
|---|---|---|
| 1 | baseline | m001_base.sql |
| 2 | G0-SCH-001 | m002_sch001_cost_layers.sql |
| 3 | G0-SCH-002 | m003_sch002_period_lock.sql |
| 4 | G0-SCH-003 | m004_sch003_bill_allocation.sql |
| 5 | G0-SCH-004 | m005_sch004_tax_layout.sql |
| 6 | G0-SCH-005 | m006_sch005_versioning.sql |
| 7 | G0-SCH-006 | m007_sch006_trial_denylist.sql |
| 8 | G0-SCH-007 | m008_sch007_discount.sql (ALTER only) |
| 9 | M03 | m009_m03_masters.sql |
| 10 | DSS-TXN | m010_dss_txn_refs.sql (1 new table + ALTERs) |
| 11 | DSS-TXN | m011_dss_fy_drcr.sql (1 new table + ALTERs) |
| 12 | M04 | m012_series_mode.sql (ALTER only) |
| 13 | M04 | m013_ledger_masters.sql |
| 14 | M03 | m014_ledger_bank.sql (1 new table + ALTERs) |
| 15 | M13 | m015_stock_valuation.sql (ALTER only) |
| 16 | D1 | m016_company_scope_and_reversal.sql (ALTER only) |
| 17 | D2 | m017_schema_hardening.sql (ALTER + triggers/indexes only) |
| 18 | G3 | m018_gst_posting.sql (ALTER only) |

## 2. Spec tables (§3 catalogues, both docs — identical vocabulary, different grouping)
company, financial_year, user, role, device, account_group, ledger, party, bank_account, item_group, unit, item, godown, batch, price_list, price_list_line, voucher_type, voucher_series (spec grouped row `voucher_type / series`), voucher, voucher_line, document_link, approval_rule, approval_instance, stock_balance (derived), outstanding (derived), bank_statement_batch, bank_statement_line, import_batch, import_error, audit_event, operation, sync_peer, backup_manifest, licence, attachment.
§G0 banner additions (both docs): stock_cost_layer, stock_movement (+item_cost_state implied), period_lock, bill_allocation, tax_rate_hsn, layout_profile, operation.base_version + dependencies (→operation_dependency), trial_anchor, denylist_entry. Neither §3 lists the G0 tables.

## 3. Present (CREATE TABLE in migrations, with anchor)
| Spec entity | Migration |
|---|---|
| company | m001_base.sql:12 |
| financial_year | m011_dss_fy_drcr.sql:19 |
| account_group | m013_ledger_masters.sql:12 |
| ledger | m013_ledger_masters.sql:24 |
| party | m009_m03_masters.sql:16 |
| bank_account | m014_ledger_bank.sql:26 |
| item_group | m009_m03_masters.sql:57 |
| unit | m009_m03_masters.sql:44 |
| item | m001_base.sql:18 |
| godown | m001_base.sql:27 |
| voucher_type | m009_m03_masters.sql:68 |
| voucher_series (spec `series`) | m009_m03_masters.sql:78; mode added m012:13 |
| voucher | m001_base.sql:34 |
| voucher_line | m001_base.sql:47 |
| document_link | m010_dss_txn_refs.sql:34 |
| audit_event | m001_base.sql:74 |
| operation | m001_base.sql:60 |
| stock_cost_layer (G0) | m002_sch001_cost_layers.sql:9 |
| stock_movement (G0) | m002_sch001_cost_layers.sql:23 |
| item_cost_state (G0 implied) | m002_sch001_cost_layers.sql:43 |
| period_lock (G0) | m003_sch002_period_lock.sql:6 |
| bill_allocation (G0) | m004_sch003_bill_allocation.sql:7 |
| tax_rate_hsn (G0) | m005_sch004_tax_layout.sql:7 |
| layout_profile (G0) | m005_sch004_tax_layout.sql:19 |
| operation_dependency (G0-SCH-005 physicalization) | m006_sch005_versioning.sql:25 |
| sync_conflict (conflict persistence; DB-doc OD-DB-006) | m006_sch005_versioning.sql:32 |
| trial_anchor (G0) | m007_sch006_trial_denylist.sql:9 |
| denylist_entry (G0) | m007_sch006_trial_denylist.sql:19 |
| schema_migrations (infra only) | m001_base.sql:6 |

## 4. Missing (spec entity, no CREATE TABLE anywhere in m001–m018)
| Spec entity | Evidence of absence | Owning B prompt |
|---|---|---|
| user | no migration; only TEXT actor/device cols (m010:19-23) | B4 |
| role | no migration | B4 |
| device | no migration; only TEXT device cols | B4 |
| batch | no `batch` table; only `voucher_line.batch_id` TEXT (m010:32) | B6 |
| price_list | no migration | B6 |
| price_list_line | no migration | B6 |
| approval_rule | no migration | B7 (M10 P2 deferred) |
| approval_instance | no migration | B7 (M10 P2 deferred) |
| stock_balance (derived) | no migration by design (rebuildable) | B8 |
| outstanding (derived) | no migration by design (rebuildable) | B8 |
| bank_statement_batch (BRS) | no migration | B9 (deferred live feeds) |
| bank_statement_line (BRS) | no migration | B9 (deferred live feeds) |
| import_batch | no migration | B9 |
| import_error | no migration | B9 |
| sync_peer | no migration | B12 |
| backup_manifest | no migration | B3 |
| licence | no migration (only trial_anchor/denylist) | B5 |
| attachment | no migration | B11/B13 |

## 5. Differing / naming notes
- `voucher_series` (migrations) vs `series` (spec grouped row) — same concept, different name.
- `party_address` (m009:33) and `search_alias` (m009:96): migration extras with no §3 row (addresses folded into party; alias is search index).
- `operation_dependency` / `sync_conflict`: physicalizations of G0-SCH-005/OD-DB-006, not §3 rows.
- Correctly ALTER-only (not missing): G0-SCH-005 `operation.base_version` (m006:22); G0-SCH-007 discount cols (m008:8,11); DSS-TXN narration/actor/device + line refs (m010:19-32); FY `voucher.fy_id` + `dr_cr` (m011:32,34); GST G3 cols (m018:15-60: company.state_code, party.registration_type, voucher bill/ship/third-party/supply/pos/tax_type, voucher_line rate_bps + cgst/sgst/igst_paise).
- m017 adds only triggers/indexes/checksums (audit/operation append-only, posted-lifecycle, vocab, company guards, checksums, record_version, hash chain) — no new tables.
