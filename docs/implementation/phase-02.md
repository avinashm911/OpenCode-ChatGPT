# Implementation Phase 02 — masters and search

Date (UTC): 2026-10-03
Prompt: `docs/opencode_master_prompts/02_masters_and_search.md`
Contract: `docs/opencode_master_prompts/GLOBAL_NO_INVENTION_CONTRACT.md`
Authority: `docs/IMPLEMENTATION_EXECUTION_STRATEGY.md` Slice 2; `NiAv_G0_Prompts_Pack_v0.9.md`;
  `niaverp/AGENTS.md`; `niaverp/DECISIONS.md`; DSS §3 Table catalogue; DB §3 entity
  catalogue; REG M03.3/M03.8/M03.9/M03.10/M03.16/M03.19, M12.3; `docs/g0/MIGRATION_DESIGN.md`;
  `docs/g0/PENDING_INPUTS.md` (21 open + 2 owner-decided); 15 HTML (read-only).
Previous phase report: `docs/implementation/phase-01.md`.
Field authorities (all columns trace to these, nothing invented):
  party shape DSS §3/DB §3 + M03.3 (customer/supplier, ledger hook, GSTIN,
  state, addresses, terms; mobile via M12.3 match field); item M03.8 + DB §3
  (code/barcode/HSN/GST-rate/tax-link/group/unit-link); units M03.9 (base
  unit, factor, scale); godown M03.10 (name uniqueness); type/series DSS §3
  + M03.16/M04 (storage only); tax masters M03.19 (link to existing
  tax_rate_hsn, no data invented); search M12.3 (stored-field + alias LIKE).

## Objective

First persisted vertical slice: M03 masters (party, unit, group, godown,
voucher type/series, item master columns), alias-backed universal search
subset, and onboarding + Parties & Items screens over real repositories.

## Changed files

Schema (new migration, G0 chain preserved):
- `niaverp/lib/data/migrations/m009_m03_masters.sql` — v9: `party`,
  `party_address`, `unit` (uq per company), `item_group` (tree, uq per
  company), `voucher_type`, `voucher_series`, `search_alias` (CHECK
  party|item), item ADD COLUMNs (code/barcode/hsn_code/gst_rate_bps/
  tax_rate_id→tax_rate_hsn/group_id/unit_id) with PRAGMA-guarded markers.
- `niaverp/lib/data/migrations/migration_registry.dart` — v9 appended
  (g0Id 'M03'), `kLatestVersion` 8→9. v1..v8 untouched.

New production code (no new packages):
- `lib/data/repositories/party_repository.dart` — create/update/get/
  listByCompany(+role)/addAddress/addressesFor; role CHECK pair enforced
  pre-DB; GSTIN/mobile as-entered (format pending M17/G3); ledger hook
  nullable (ledger masters = prompt 04).
- `lib/data/repositories/unit_group_repository.dart` — `UnitRepository`
  (uq conflict, factor/scale validation; conversion math = prompt 04),
  `ItemGroupRepository` (tree links).
- `lib/data/repositories/voucher_type_repository.dart` — type/series
  registry CRUD; `GodownRepository` (repo-level name uq with rebuild
  boundary). Numbering behavior explicitly NOT implemented (prompt 03A).
- `lib/data/repositories/alias_repository.dart` — as-typed alias storage
  (entity party|item); no transliteration, no fuzzy.
- `lib/data/repositories/item_repository.dart` (extended) — `Item` gains
  nullable M03.8 fields; `updateMaster` + `rename` with old/new lineage.
- `lib/application/queries/master_search.dart` — `MasterSearch`:
  party (name/GSTIN/mobile/alias) + item (name/code/barcode/alias) LIKE
  search, prefix-first ordering, wildcard escaping, company scope,
  empty-matches-nothing, cap 50 (implementation default; M12.8 TBC).
- `lib/presentation/shared/screen_wiring.dart` — `WriteContext` +
  `CounterIdMint` (UUIDv7 minting = platform slice; documented boundary).
- `lib/presentation/onboarding/onboarding_screen.dart` — company
  create/list/open; loading/empty/validation/creating/recoverable-error.
- `lib/presentation/parties_items/parties_items_screen.dart` — Parties +
  Items tabs; live search, add/edit dialogs (role dropdown = documented
  pair), inline validation, SnackBar failures (codes only).

Tests (new, 38): `test/data/db` reload (1, temp-FILE close→reopen at v9);
  `masters_repository_test` (13); `master_search_test` (10, incl. native-
  script alias, wildcard-literality, isolation); `item_master_test` (6);
  `onboarding_test` (3), `parties_items_test` (5) — all widget tests drive
  REAL repositories over a REAL migrated database, no fakes.
Helpers: `TestDatabase.open` + `testClock` in `test/helpers/test_database.dart`.

Touched prototypes (mechanical, behavior preserved): 2 G0 migration-test
  assertions extended 1..8→1..9 with preservation comments (G0-delta mapping
  test untouched); 5 test adapters (phase-01 interface follow-up).

Untouched: 15 HTML/workbooks/registers; `pubspec.yaml` (Drift/SQLCipher
  still unselected); accounting/security/print engines; `NiavShell` tabs
  still placeholders (no prod engine in `main()` — same block as phase-01).

## Decisions / blockers (no invention)

- Party schema question from phase-01 CLOSED by documents above (no owner
  input needed): columns implement exactly the DSS/DB/REG-listed sets.
- NOT built (explicit boundaries, later slices): ledger/account/bank/cost-
  centre/currency masters (prompt 04); item prices/MRP/min/max/reorder/
  opening (Slice 4); batch/expiry (P2 M03.11), serials (P3), price
  lists/schemes (P2), salesperson/commission (P3), narrations (P2),
  currencies (P3 TBC), numbering engine + uq_series_scope (prompt 03A),
  fuzzy search (P2 M12.4), transliteration (excluded), latency targets
  (TBC M12.8), recents/favourites (M12.6, no approved table), M03.20
  duplicate-merge utilities (P2 — only documented DB uniques enforced),
  GSTIN/mobile format rules (pending M17/G3), UUIDv7 minting (platform
  slice), shell wiring into `main()` (no prod engine — P-SQLIB).
- P-SQLIB still open: no library selected, no encryption claimed.

## Commands and environment

Workdir `E:\NiavERP v2 OpenAI\niaverp`; Flutter 3.47.5 / Dart 3.13.4;
Windows 10 Pro 22H2; disposable SQLite (in-memory + one temp-FILE reload).

- `flutter analyze` → **No issues found!**
- `flutter test` → **+166: All tests passed!**
  (128 prior + 38 new; pre-existing subset re-verified at 121 with zero
  regressions; 2 G0 assertions extended, G0-delta mapping untouched.)

## Traceability IDs

REG M03.3/M03.7/M03.8/M03.9/M03.10/M03.16/M03.19, M12.3; DSS §3; DB §3;
DSS-C-001/004; OD-DB-004; D-M4; FR-COM-001; G0-DEF-003; M03.11(P2)/M03.12(P3)/
M03.13(P2)/M03.14(P2)/M03.17(P3)/M03.18(P2)/M03.20(P2)/M12.4(P2)/M12.8(TBC).

## Unresolved items / downstream pending evidence

P-SQLIB (prod encryption + shell wiring), P-DEVICE-8/CUR + P-KEYSTORE,
P-FIELD-LIST + P-EINV/GSTR/EWAY-SCH (G3/R1a), P-LEGAL-001…005,
P-PRN-001…003 + P-APK/ZIP-SHA + P-CH-WA/EM/LINK (G5). Deferred:
G0-DEF-001:R3, G0-DEF-002:Later-release, G0-DEF-003:R2.

## Acceptance check

- [x] Create, edit, search work; file-DB close→reopen preserves rows
  (host reload semantics; not an app-restart/device claim).
- [x] No fake repository in completed flows (screens + tests use real
  repos over real SQLite; `main()` wiring honestly still blocked).
- [x] Money/quantity stay integer (no new money/qty code; typed VOs exist).
- [x] `flutter analyze` + `flutter test` pass (+166).
- [x] Locked states N/A for masters (period locks gate vouchers, prompt 03).

## Next gate

Prompt 02A — onboarding and localisation (M01 completion, M02): FY/company
context, first-user setup, en/hi/gu resources, native-script entry/search,
glossary, formatting. Then prompt 03 billing vertical slice.
