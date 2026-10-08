# BACKEND_CAPABILITY_REGISTER — code-true audit (B0)

Date (UTC): 2026-10-08. Branch: `b0-20261008` (from `bb215de`). Baseline: `flutter analyze` clean; `flutter test` 508 passed / 0 failed / 2 skipped (evidence `docs/implementation/evidence/flutter_test_full_20261008_b0.txt`, `analyze_20261008_b0.txt`).
Built from code, not reports. Call-chain root for all WIRED rows: `lib/main.dart:70 runStartup` → `lib/app/startup.dart:277 CompositionRoot.backend` → `lib/app/composition_root.dart:107-150 BackendBundle` → field below.
Status vocabulary: WIRED+TESTED / ISLAND / PARTIAL / ABSENT / BOUNDARY / BLOCKED / DEFERRED / EXCLUDED / CONTRADICTED. No `lib/application/commands/` exists; all presentation writes call `scope.<repo>` directly (bypass inventory §A4) — recorded per row as the B1/B4 choke-point gap. Tests named are real files under `niaverp/test` run in the baseline above (host, real encrypted SQLite file).

## Register-vs-reconciled priority conflicts
| ID | Register | Reconciled | Resolution |
|---|---|---|---|
| M10.* (10 rows) | P2 | P2 DEFERRED (`STATUS_LEDGER.md:19`) | no conflict; B7 owns boundary only |
| M24.* (5 rows) | P2/P3 | M24 P2 DEFERRED + FR-M24-001 deferred (`STATUS_LEDGER.md:15,20`) | no conflict; B11 owns boundary only |
| FR-M03-008/009 (M03.11/M03.13) | P2 | DEFERRED P2 (`STATUS_LEDGER.md:7-8`) | no conflict; B6 owns boundary only |
| FR-M08-003 (M08.2 part) | P2/partial P3 | deferred unless accepted (`STATUS_LEDGER.md:9`) | no conflict |
| FR-M10-001/002 | P2 | deferred (`STATUS_LEDGER.md:10-11`) | no conflict |
| FR-M13-002 (M13.6) | P2 | deferred (`STATUS_LEDGER.md:12`) | no conflict |
| FR-M14-003 (M14.7) | P2 | TBC channel (`STATUS_LEDGER.md:13`) | no conflict; channel decision pending |
| FR-M20-002 (M20.5) | P2 | deferred (`STATUS_LEDGER.md:14`) | no conflict |
| M14.11 budgets | P3 | Resolved—superseded by workbook reconciliation (`STATUS_LEDGER.md`) | register P3 not implemented; no build |
| M16.8 TDS / M16.9 payroll | P3 | deferred later / out-of-scope V1 (`STATUS_LEDGER.md:7,41`) | EXCLUDED from V1 build |
| M17.11 native import | P3 | R3 feasibility only (`STATUS_LEDGER.md:6,16`) | DEFERRED R3; V1 Excel only (B9) |
| M02.5 voice | P3 rejected | Rejected, no R3 gate (`STATUS_LEDGER.md:42-44`) | EXCLUDED |
| TBC rows (M01.4/M01.6/M02.4/M02.8/M03.6/M03.12/M03.15/M03.17/M04.4/M07.4/M10.2/M10.4/M10.6/M12.3/M12.8/M13.1/M14.7/M14.9/M14.10/M16.1/M18.10/M20.2/M20.3/M20.5/M20.6/M24.4) | TBC in register | gate held by source row; no invented value | BLOCKED/DEFERRED per row, never PASS |
| VERIFY rows (M04.8/M16.1-7/M22.6) | VERIFY | official schema/rule evidence required | BLOCKED until evidence (B10/B14) |

## M01 Onboarding, Company & Configuration → B6 (trial/clock parts → B1, crypto → B2)
| ID | name | Reg | reconciled | FR/FG/OD | status | call chain from main.dart | test name | gap in one line | B |
|---|---|---|---|---|---|---|---|---|---|
| M01.1 | Company creation | P1 | P1 active | FR-M01-001/002/003, DSS-C-001 | WIRED+TESTED | bundle `companies:190` → `data/repositories/company_repository.dart` | company_item_repository_test (create/get/lineage, isolation) + onboarding_test | no application command; presentation writes repo directly (choke-point gap) | B6+B1 |
| M01.2 | Multi-company | P1 | P1 active | FR-M01-001, DSS-C-001 | WIRED+TESTED | bundle `companies:190` + `CompanyScope` | company isolation cases + shell_test company-rebind | — | B6 |
| M01.3 | Financial year management | P1 | P1 active | FR-M01-001, DB §3 | WIRED+TESTED | bundle `fyYears:191` → `financial_year_repository.dart` | financial_year_test | — | B6 |
| M01.4 | Company features (multi-currency TBC) | P1 | P1 + TBC currency | FR-M01-003 | PARTIAL | bundle `layoutProfiles:205` → `layout_profile_repository.dart` | layout_profile_test | multi-currency undecided, no currency table | B6 |
| M01.5 | Voucher configuration | P1 | P1 active | FR-M04-002, M04 | WIRED+TESTED | bundle `types:201` + `numbering:211` → `voucher_type_repository.dart`, `services/numbering.dart:80` | voucher_registry_test + numbering_test | — | B6 |
| M01.6 | Business-type presets (exact list TBC) | P2 | P2 TBC | FR-M01-003 | DEFERRED | — (no code) | — | exact preset list missing | B6 |
| M01.7 | Security setup | P1 | P1 active, device proof pending | D-06, G0-VER-005/008 | PARTIAL | `startup.dart:211-270` key obtain + cipher open → `data/db/cipher_opener.dart`, `channel_key_provider.dart` | cipher_opener_test + channel_key_provider_test + key_lifecycle_test | host-only; Keystore/device runs pending (P-KEYSTORE) | B2+B1 |
| M01.8 | Branches / locations | P2 | P2 | FR-M01-003 | ABSENT | — (no branch table) | — | no schema, no repo | B6 |

## M02 Language & Localisation → B6
| M02.1 | Language switch | P1 | P1 active | FR-M02-001 | WIRED+TESTED | bundle `layoutProfiles:205` + `presentation/localization/app_localizations.dart:234 latest()` | localization_source_test | hi/gu native review pending (TRANSLATIONS) | B6 |
| M02.2 | Language pack framework | P1 | P1 active | FR-M02-001 | WIRED+TESTED | `lib/l10n/app_en|hi|gu.arb` + `app_localizations.dart` | localization_source_test | machine-drafted hi/gu, review pending | B6 |
| M02.3 | Launch language list en/hi/gu | P1 | P1 decided D-R1 | FR-M02-001 | WIRED+TESTED | same as M02.2 | localization_source_test | — | B6 |
| M02.4 | Native-script data entry | P1 | P1 + TBC aid | FR-M02-001, M12.3 | PARTIAL | bundle `search:207` + `aliases:203` → `queries/master_search.dart:43,80` | master_search_test | transliteration aid TBC/excluded (G0-DEF-003) | B6 |
| M02.5 | Voice input | P3 rej | EXCLUDED (`STATUS_LEDGER.md:42-44`) | FR-M02-002, G0-OWN-002 | EXCLUDED | — (grep-proven absent) | exclusion_voice_test (negative) | rejected for V1 | — |
| M02.6 | Numerals and formats | P1 | P1 active | FR-M02-001, D-M4 | WIRED+TESTED | `application/formatting/niav_format.dart:19,44,55` (ISLAND-adjacent pure; called by presentation) | value_objects_test + formatting via books/stock tests | pure helpers, no backend state | B6 |
| M02.7 | Bilingual printing | P2 | P2 | FR-M21-001 | PARTIAL | `data/print/*` models (pure) | escpos_test + pdf_layout_test + template_test | native-script PDF route undecided (B11 question) | B11 |
| M02.8 | Simplified terminology mode | P2 | P2 TBC wording | FR-M02-001 | DEFERRED | — | — | wording per language missing | B6 |

## M03 Masters → B6
| M03.1 | Account Groups | P1 | P1 active | FR-M03-001/002 | WIRED+TESTED | bundle `accountGroups:192` → `ledger_masters.dart` | ledger_masters_test | direct presentation writes (choke gap) | B6 |
| M03.2 | Account Ledgers | P1 | P1 active | FR-M03-001/002 | WIRED+TESTED | bundle `ledgers:193` | ledger_masters_test + bank_account_test (detail fields) | — | B6 |
| M03.3 | Party master | P1 | P1 active | FR-M03-001/003 | WIRED+TESTED | bundle `parties:197` → `party_repository.dart` | masters_repository_test | — | B6 |
| M03.4 | Bank accounts | P1 | P1 active | FR-M03-001/004 | WIRED+TESTED | bundle `banks:194` | bank_account_test | — | B6 |
| M03.5 | Cost centres | P3 | P3 | FR-M03-001 | ABSENT | — | — | no table | B6 |
| M03.6 | Currencies (whether needed TBC) | P3 | P3 TBC | FR-M03-001 | ABSENT | — | — | TBC | B6 |
| M03.7 | Item Groups | P1 | P1 active | FR-M03-001 | WIRED+TESTED | bundle `groups:200` | item_group_hierarchy_test | — | B6 |
| M03.8 | Item master | P1 | P1 active | FR-M03-001 | WIRED+TESTED | bundle `items:198` → `item_repository.dart` | item_master_test + company_item_repository_test | — | B6 |
| M03.9 | Units of Measure | P1 | P1 active | FR-M03-001 | WIRED+TESTED | bundle `units:199` | masters_repository_test (unit+factor) | — | B6 |
| M03.10 | Godowns / Locations | P1 | P1 active | FR-M03-001 | WIRED+TESTED | bundle `godowns:202` | masters_repository_test (godown conflict) | — | B6 |
| M03.11 | Batch / Expiry | P2 | P2 DEFERRED (FR-M03-008) | FR-M03-008 | ABSENT | — (only `voucher_line.batch_id` TEXT, m010:32) | — | no batch table | B6 |
| M03.12 | Serial numbers (TBC) | P3 | P3 TBC | FR-M03-001 | ABSENT | — | — | — | B6 |
| M03.13 | Price Lists | P2 | P2 DEFERRED (FR-M03-009) | FR-M03-009 | ABSENT | — | — | no price tables | B6 |
| M03.14 | Discount schemes | P2 | P2 | FR-M03-001 | PARTIAL | `voucher_line.discount_*` (m008) via `vouchers.addLine` | discount_test | line discounts wired; no scheme table | B6 |
| M03.15 | Bill of Materials (scope TBC) | P3 | P3 TBC | FR-M03-001 | ABSENT | — | — | — | B6 |
| M03.16 | Voucher Types and Series | P1 | P1 active | FR-M04-001/002 | WIRED+TESTED | bundle `types:201` | voucher_registry_test | — | B6 |
| M03.17 | Salespersons / Agents (commission TBC) | P3 | P3 TBC | FR-M03-001 | ABSENT | — | — | — | B6 |
| M03.18 | Narration templates | P2 | P2 | FR-M03-001 | ABSENT | — (narration col only, m010:19) | — | no template store | B6 |
| M03.19 | Tax masters | P1 | P1 + VERIFY rules | FR-M16-001, OD-DB-003 | PARTIAL | `tax_rate_hsn` (m005) + `queries/tax_rates.dart:16 hsnRateBps` | tax_rates_test | effective-dated rates wired; statutory fields after schema verify | B10 |
| M03.20 | Master utilities (duplicates/aliases) | P2 | P2 | FR-M03-001 | PARTIAL | bundle `aliases:203` → `alias_repository.dart` | masters_repository_test + duplicate-conflict cases | alias add wired via presentation; no fuzzy/transliteration | B6 |

## M04 Voucher Engine & Numbering → B6 (engine behaviour → B7)
| M04.1 | Voucher type registry | P1 | P1 active | FR-M04-001 | WIRED+TESTED | bundle `types:201` | voucher_registry_test (19 canonical types) | — | B6 |
| M04.2 | Multiple series per type | P1 | P1 active | FR-M04-002 | WIRED+TESTED | bundle `types:201` series ops | voucher_registry_test | — | B6 |
| M04.3 | Numbering rules | P1 | P1 active | FR-M04-002, DSS-C-002 | WIRED+TESTED | bundle `numbering:211` → `services/numbering.dart:80 nextNumber` | numbering_test | — | B6 |
| M04.4 | Series scoping (which scopes TBC) | P2 | P2 TBC | FR-M04-002 | PARTIAL | same as M04.3 | numbering_test | scope list unconfirmed | B6 |
| M04.5 | Default series | P1 | P1 active | FR-M04-002 | WIRED+TESTED | `seriesForType` via `voucher_type_repository.dart` | voucher_registry_test | — | B6 |
| M04.6 | Series-wise settings | P1 | P1 active | FR-M04-002 | WIRED+TESTED | `voucher_series.mode` (m012) | migration_series_mode_test | — | B6 |
| M04.7 | Gap and continuity control | P1 | P1 active | FR-M04-002 | WIRED+TESTED | `services/numbering.dart:97 seriesGaps` | numbering_test | — | B6 |
| M04.8 | GST-compliant numbering checks (VERIFY rule text) | P1 | P1 VERIFY | FR-M04-002 | BLOCKED | same wiring as M04.3 | numbering_test | current rule text unverified | B6+B10 |
| M04.9 | Voucher common features (header/post/audit) | P1 | P1 active | FR-M04-003 | WIRED+TESTED | bundle `vouchers:204` + `engine:212` → `services/voucher_engine.dart:265 postDraft, :395 cancelPosted, :684 postWithStock` | voucher_posting_test + voucher_engine_test | engine reachable; masters bypass it (gap) | B7 |

## M05 Dual Vouchers → B7
| M05.1 | Sales Invoice | P1 | P1 active | FR-M05-001 | WIRED+TESTED | bundle `engine:212 postWithStock` + GST arms (P-GST-POST) | invoice_posting_test + gst_posting_engine_test + billing_flow_test | — | B7 |
| M05.2 | Purchase Invoice (landed cost TBC) | P1 | P1 + TBC | FR-M05-002 | PARTIAL | same engine | purchase_transfer_flow_test | landed-cost rule missing | B7 |
| M05.3 | Sales Return (Credit Note with items) | P1 | P1 active | FR-M05-003 | WIRED+TESTED | engine cancel/mirror + `links:206` | voucher_posting_test (returns) + business_cycles_test | — | B7 |
| M05.4 | Purchase Return (Debit Note with items) | P1 | P1 active | FR-M05-004 | WIRED+TESTED | same engine | voucher_posting_test | — | B7 |

## M06 Accounting Vouchers → B7
| M06.1 | Payment | P1 | P1 active | FR-M06-001 | WIRED+TESTED | bundle `allocations:195` + engine | bill_allocation_test + ledger_voucher_form_test | settlement types excluded from bills per P-BILLDEF | B7 |
| M06.2 | Receipt | P1 | P1 active | FR-M06-002 | WIRED+TESTED | same | bill_allocation_test + ledger_voucher_form_test | — | B7 |
| M06.3 | Contra | P1 | P1 active | FR-M06-003 | WIRED+TESTED | engine | voucher_posting_test | — | B7 |
| M06.4 | Journal | P1 | P1 active | FR-M06-004 | WIRED+TESTED | engine `checkJournalBalance:353` | voucher_posting_test (unbalanced rejected) | — | B7 |
| M06.5 | Debit Note (without items) | P1 | P1 active | FR-M06-005 | WIRED+TESTED | engine | voucher_posting_test | — | B7 |
| M06.6 | Credit Note (without items) | P1 | P1 active | FR-M06-005 | WIRED+TESTED | engine | voucher_posting_test | — | B7 |

## M07 Inventory Vouchers → B7
| M07.1 | Delivery Note / Challan | P1 | P1 active | FR-M07-001 | WIRED+TESTED | engine (no posting until conversion) | delivery_journal_flow_test | — | B7 |
| M07.2 | Material Issue to Party | P2 | P2 | FR-M07-002 | WIRED+TESTED | bundle `vouchers:204` + engine (transfer screen path) | purchase_transfer_flow_test (transfer invalid refused) | job-work pending quantities via M15 | B7 |
| M07.3 | Material Receive from Party | P2 | P2 | FR-M07-003 | WIRED+TESTED | same | purchase_transfer_flow_test | — | B7 |
| M07.4 | Stock Transfer (in-transit TBC) | P1 | P1 + TBC | FR-M07-002 | PARTIAL | same | purchase_transfer_flow_test | in-transit handling undecided | B7 |
| M07.5 | Stock Journal | P1 | P1 active | FR-M07-003 | WIRED+TESTED | engine | delivery_journal_flow_test (priced stock-out refused) | — | B7 |

## M08 Orders & Quotations → B7
| M08.1 | Sales Quotation / Proforma | P1 | P1 active | FR-M08-001 | WIRED+TESTED | bundle `vouchers:204` (draft, no post until conversion) | voucher_posting_test (orders never post) | — | B7 |
| M08.2 | Purchase Quotation (compare P3) | P2 | P2 (+compare deferred) | FR-M08-002/003 | PARTIAL | same draft path | voucher_posting_test | comparison absent (P3) | B7 |
| M08.3 | Sales Order | P1 | P1 active | FR-M08-002 | WIRED+TESTED | same (Draft→Open→Partial→Closed/Cancelled, D-M6 no reservation) | voucher_posting_test | — | B7 |
| M08.4 | Purchase Order | P1 | P1 active | FR-M08-002 | WIRED+TESTED | same | voucher_posting_test | — | B7 |
| M08.5 | Order status & tracking | P1 | P1 active | FR-M08-002 | PARTIAL | bundle `links:206` + `flow:213` lineage | document_flow_test + document_link_test | tracking via links; no dedicated status report | B7 |

## M09 Document Flow → B7
| M09.1 | Manual conversion | P1 | P1 active | FR-M09-001 | WIRED+TESTED | bundle `flow:213` → `services/document_flow.dart:101 convert` | document_flow_test | — | B7 |
| M09.2 | Auto conversion rules | P2 | P2 | FR-M09-001 | ABSENT | — | — | no rule engine | B7 |
| M09.3 | Partial and multiple conversion | P1 | P1 active | FR-M09-001 | WIRED+TESTED | `document_flow.dart:44 convertedLineQty, :58 convertedVoucherQty, :69 remainingLineQty` | document_flow_test | — | B7 |
| M09.4 | Skip-stage rules | P1 | P1 active | FR-M09-001 | WIRED+TESTED | same convert path | document_flow_test | — | B7 |
| M09.5 | Quantity/rate tracking | P1 | P1 active | FR-M09-001 | WIRED+TESTED | same qty functions | document_flow_test | — | B7 |
| M09.6 | Receipt/Payment linking | P1 | P1 active | FR-M09-002 | WIRED+TESTED | bundle `allocations:195` + `links:206` | bill_allocation_test + document_link_test | — | B7 |
| M09.7 | Document lineage view | P1 | P1 active | FR-M09-002 | WIRED+TESTED | bundle `links:206` list-both-ways | document_link_test | view is presentation; data wired | B7 |
| M09.8 | Reversal handling | P1 | P1 active | FR-M09-002 | WIRED+TESTED | engine `cancelPosted:395` + allocation reversal | voucher_cancel_test + bill_allocation_test | — | B7 |

## M10 Approval Matrix & Workflows → B7, all P2 DEFERRED
| M10.1 | Approval matrix master | P2 | P2 DEFERRED | FR-M10-001 | DEFERRED | — (no tables) | — | schema absent | B7 |
| M10.2 | Approval levels (parallel TBC) | P2 | P2 DEFERRED+TBC | FR-M10-001 | DEFERRED | — | — | — | B7 |
| M10.3 | Approver assignment | P2 | P2 DEFERRED | FR-M10-001 | DEFERRED | — | — | — | B7 |
| M10.4 | Document states (list TBC) | P2 | P2 DEFERRED+TBC | FR-M10-001 | DEFERRED | — | — | voucher status exists but approval states absent | B7 |
| M10.5 | Actions | P2 | P2 DEFERRED | FR-M10-002 | DEFERRED | — | — | — | B7 |
| M10.6 | Notifications (channel TBC) | P2 | P2 DEFERRED+TBC | FR-M10-002 | DEFERRED | — | — | — | B7 |
| M10.7 | Effect of approval | P2 | P2 DEFERRED | FR-M10-002 | DEFERRED | — | — | — | B7 |
| M10.8 | Approval audit trail | P2 | P2 DEFERRED | FR-M10-002 | DEFERRED | — (audit infra exists, no approval events) | audit_append_only_test (infra only) | infra ready, domain absent | B7 |
| M10.9 | Approval reports | P2 | P2 DEFERRED | FR-M10-002 | DEFERRED | — | — | — | B7 |
| M10.10 | Non-voucher workflows | P2 | P2 DEFERRED | FR-M10-002 | DEFERRED | — | — | — | B7 |

## M11 Fast Billing / Counter → B7
| M11.1 | Quick bill screen (backend: draft/post) | P1 | P1 active | FR-M11-001 | WIRED+TESTED | engine `postWithStock` | billing_flow_test (flagship sale→settled) | screen is UI; backend path wired | B7 |
| M11.2 | Item entry shortcuts | P1 | P1 active | FR-M11-002 | WIRED+TESTED | bundle `search:207 searchItems` | master_search_test | — | B7 |
| M11.3 | Default party | P1 | P1 active | FR-M11-002 | PARTIAL | `parties` repo (no default-party store) | masters_repository_test | no default-party field | B7 |
| M11.4 | Payment shortcuts | P1 | P1 active | FR-M11-002 | WIRED+TESTED | allocations + settlement queries | settlement_posting_test | — | B7 |
| M11.5 | Hold & resume bills | P1 | P1 active | FR-M11-003 | WIRED+TESTED | `voucher` held statuses via `vouchers` repo | held_bill_test | — | B7 |
| M11.6 | Auto price fetch | P1 | P1 active | FR-M11-002 | PARTIAL | item rate fields (no price-list tables) | item_master_test | price lists absent so fetch is master rate only | B7+B9 |
| M11.7 | Instant output | P1 | P1 active | FR-M11-001 | PARTIAL | print models (pure) | template_test | transport pending (B13) | B11 |
| M11.8 | Offline billing (see M22) | P1 | P1 active | FR-M11-001 | WIRED+TESTED | local encrypted DB path (`startup.dart:243`) | persistence_reload_test | — | B3 |
| M11.9 | Counter mode | P2 | P2 | FR-M11-001 | ABSENT | — | — | no mode store | B7 |
| M11.10 | Return at counter | P2 | P2 | FR-M11-003 | ABSENT | — (returns exist as vouchers, no counter flow) | voucher_posting_test (returns only) | flow absent | B7 |
| M11.11 | Day-end / cash close | P2 | P2 | FR-M11-001 | ABSENT | — | — | no close procedure | B7 |

## M12 Universal Search → B8
| M12.1 | Global search | P1 | P1 active | FR-M12-001 | WIRED+TESTED | bundle `search:207` → `master_search.dart:43,80,113` | master_search_test + master_search_voucher_test | — | B8 |
| M12.2 | Instant results | P1 | P1 active | FR-M12-001 | WIRED+TESTED | same | master_search_test | latency target unmeasured (see M12.8) | B8 |
| M12.3 | Match logic (native/transliteration TBC) | P1 | P1 + TBC | FR-M12-001 | PARTIAL | same (LIKE + aliases; no transliteration) | master_search_test | transliteration excluded | B8 |
| M12.4 | Fuzzy / typo tolerance | P2 | P2 | FR-M12-001 | ABSENT | — (explicit out-of-slice comment `master_search.dart:7`) | — | — | B8 |
| M12.5 | Filters and sorting | P2 | P2 | FR-M12-001 | PARTIAL | query params (limit; bills filters in `outstanding.dart:281`) | settlement_report_test | global filters absent | B8 |
| M12.6 | Recent / favourites | P1 | P1 active | FR-M12-001 | ABSENT | — | — | no recent store | B8 |
| M12.7 | In-form pickers | P1 | P1 active | FR-M12-001 | WIRED+TESTED | same search calls from forms | parties_items_test | — | B8 |
| M12.8 | Performance target (numeric + low-end TBC) | P1 | P1 TBC | FR-M12-001, G2 | BLOCKED | same | — | target + low-end test missing | B8+B14 |

## M13 Inventory Management → B8
| M13.1 | Stock valuation methods (final list TBC) | P1 | P1 + TBC | D-M5, FG-013 | PARTIAL | cost layers (m002/m015) + `stock_levels.dart:165 valuation` | costing_test + stock_valuation_test | FIFO/WA wired; final list + lock-after-first-move needs B8 proof | B8 |
| M13.2 | Multi-godown stock | P1 | P1 active | FR-M13-001 | WIRED+TESTED | `stock_levels.dart:87 balances` company+godown scoped | stock_levels_test | — | B8 |
| M13.3 | Negative stock control | P1 | P1 active | FR-M13-001 | WIRED+TESTED | engine policy + last-known-cost | stock_policy_test + form_states_test (blocked policy) | — | B8 |
| M13.4 | Reorder management (auto-PO P3) | P2 | P2 (+P3 part) | FR-M13-001 | PARTIAL | balances query (no reorder store) | stock_levels_test | reorder point + auto-draft absent | B8 |
| M13.5 | Batch/expiry management | P2 | P2 | FR-M03-008 | ABSENT | — (no batch table) | — | — | B6+B8 |
| M13.6 | Physical stock | P2 | P2 DEFERRED (FR-M13-002) | FR-M13-002 | ABSENT | — | — | count/variance absent | B8 |
| M13.7 | Barcode/label | P2 | P2 | FR-M13-001 | PARTIAL | item barcode/code fields (no print path) | item_master_test | label transport pending | B11 |
| M13.8 | Multiple units | P1 | P1 active | FR-M13-001 | WIRED+TESTED | unit factor + Q4 qty | value_objects_test + masters_repository_test | conversion factors stored; cross-unit pricing via price lists absent | B8 |

## M14 Accounting Books & Financial Reports → B8
| M14.1 | Books of accounts | P1 | P1 active | FR-M14-001/002, P-BOOKS | WIRED+TESTED | bundle `books:209` → `queries/ledger.dart:212 dayBook, :285 ledgerAccount` | books_test + ledger_books_test | openings full-count convention per P-BOOKS | B8 |
| M14.2 | Trial Balance | P1 | P1 active | FR-M14-001/002, P-BOOKS | WIRED+TESTED | `ledger.dart:186 trialBalance, :350 groupTrialBalance` | books_test | group classification for P&L/BS still missing (see M14.3) | B8 |
| M14.3 | Profit & Loss Account | P1 | P1 BLOCKED (group classification) | FR-M14-003, P-BOOKS | BLOCKED | — | — | no group-classification vocabulary/store (owner question) | B8 |
| M14.4 | Balance Sheet | P1 | P1 BLOCKED (same) | FR-M14-003, P-BOOKS | BLOCKED | — | — | same | B8 |
| M14.5 | Trading Account | P2 | P2 | FR-M14-003 | ABSENT | — | — | — | B8 |
| M14.6 | Outstanding management | P1 | P1 active | FR-M14-001, P-BILLDEF | WIRED+TESTED | bundle `outstanding:210` → `outstanding.dart:281 bills, :411 aging, :507 advances` | outstanding_test + settlement_report_test | — | B8 |
| M14.7 | Payment reminders (channel TBC) | P2 | P2 TBC | FR-M14-003 | DEFERRED | — | — | text/statement artifacts absent; channel undecided | B11 |
| M14.8 | Bank reconciliation (live feeds deferred) | P2 | P2 deferred feeds | FG-005 | DEFERRED | — (no statement tables) | — | file boundary only (B9) | B9 |
| M14.9 | Cheque management (printing TBC) | P3 | P3 TBC | FR-M06-001 | ABSENT | — | — | — | B8 |
| M14.10 | Interest calculation (TBC) | P3 | P3 TBC | FR-M14-002 | ABSENT | — | — | — | B8 |
| M14.11 | Budgets & cost-centre reports | P3 | superseded (workbook) | FR-M14-002 | DEFERRED | — | — | resolved-superseded; no build | B8 |
| M14.12 | Ratio/cash-flow/fund-flow | P3 | P3 | FR-M14-002 | ABSENT | — | — | — | B8 |
| M14.13 | Common report features | P1 | P1 active | FR-M14-001/002 | WIRED+TESTED | books/outstanding/stock queries | report_consistency_test (one story agrees) | export absent (B9) | B8+B9 |

## M15 Inventory Reports (15 unnumbered P1/P2/P3 rows) → B8
| M15-a | Stock Summary (item/group/godown-wise) | P1 | P1 active | FR-M13-001, M15 | WIRED+TESTED | bundle `stock:208 balances` | stock_levels_test + stock_report_test | export absent | B8 |
| M15-b | Stock Ledger / Item Register | P1 | P1 active | M15 | WIRED+TESTED | bundle `stock:208 movements:118` | stock_levels_test | — | B8 |
| M15-c | Stock Valuation | P1 | P1 active | M15 | WIRED+TESTED | `stock_levels.dart:148 layerValuePaise, :165 valuation` | stock_valuation_test | — | B8 |
| M15-d | Item-wise sales / purchase analysis | P1 | P1 active | M15 | PARTIAL | voucher search + books (no dedicated analysis query) | master_search_voucher_test + books_test | analysis query absent | B8 |
| M15-e | Party-wise sales / purchase analysis | P1 | P1 active | M15 | PARTIAL | same | same | — | B8 |
| M15-f | Reorder / low-stock report | P1 | P1 active | M15 | PARTIAL | balances (no reorder-point store) | stock_levels_test | thresholds absent | B8 |
| M15-g | Pending Sales / Purchase Orders | P1 | P1 active | M15 | PARTIAL | vouchers by status + links | document_link_test | status report query absent | B8 |
| M15-h | Pending Delivery Notes (unbilled) | P1 | P1 active | M15 | PARTIAL | same | same | — | B8 |
| M15-i | Quotation status | P2 | P2 | M15 | ABSENT | — | — | — | B8 |
| M15-j | Batch-wise and expiry report | P2 | P2 | M15 | ABSENT | — (no batch table) | — | — | B8 |
| M15-k | Stock ageing / slow / dead stock | P2 | P2 | M15 | ABSENT | — (bill ageing exists `outstanding.dart:411`, stock ageing absent) | settlement_report_test (bill ageing only) | stock-ageing query absent | B8 |
| M15-l | Godown-wise stock and transfer report | P2 | P2 | M15 | PARTIAL | balances by godown | stock_levels_test | transfer report absent | B8 |
| M15-m | Material issue/receive pending (job work) | P2 | P2 | M15 | PARTIAL | links + transfer vouchers | document_link_test | pending query absent | B8 |
| M15-n | Gross profit (item/party/invoice-wise) | P2 | P2 | M15 | ABSENT | — | — | cost-to-price join absent | B8 |
| M15-o | Price-list and discount reports | P3 | P3 | M15 | ABSENT | — | — | — | B8 |

## M16 GST & Statutory → B10
| M16.1 | GST setup (reg-type TBC; VERIFY rules) | P1 | P1 TBC+VERIFY | FR-M16-001, OD-DB-003 | PARTIAL | m018 cols + `tax/gst_posting.dart:106 determinePlaceOfSupply` | gst_posting_test + tax_rates_test | setup values pending CA/owner field list | B10 |
| M16.2 | GST on vouchers | P1 | P1 VERIFY | FR-M16-002 | WIRED+TESTED | engine GST arms (P-GST-POST) | gst_posting_engine_test | UTGST same-code pairs post CGST+SGST in v1 (deferred) | B10 |
| M16.3 | GST reports | P1/P2 | VERIFY | FR-M16-003 | BLOCKED | — (projection queries only, no filed report) | tax_rates_test (rates only) | schemas + return format missing (P-GSTR-SCH) | B10 |
| M16.4 | Return data export | P2 | VERIFY format | FR-M16-003 | BLOCKED | boundary only (`adapters/statutory_boundary_test.dart`) | statutory_boundary_test | pinned schema + samples missing | B10 |
| M16.5 | E-invoice (turnover VERIFY) | P3 | VERIFY | FR-M16-004 | BLOCKED | boundary only | statutory_boundary_test | IRN field list + schema missing (P-FIELD-LIST/P-EINV-SCH) | B10 |
| M16.6 | E-way bill | P3 | VERIFY | FR-M16-004 | BLOCKED | boundary only | statutory_boundary_test | schema missing (P-EWAY-SCH) | B10 |
| M16.7 | Composition scheme (VERIFY) | P2 | VERIFY | FR-M16-002 | BLOCKED | engine refuses composition category (P-GST-POST) | gst_posting_test (refusal) | support deferred until schema verify | B10 |
| M16.8 | TDS / TCS (later release) | P3 | deferred/excluded V1 | FG-007, G0-DEF-002 | EXCLUDED | — (grep-absent) | — | — | — |
| M16.9 | Other statutory (PF/ESI/payroll) | P3 | out-of-scope V1 | FG-008 | EXCLUDED | — (grep-absent) | exclusion_payroll_test (negative) | — | — |

## M17 Data Import / Migration → B9
| M17.1 | Standard Excel templates | P1 | P1 active | FR-M17-001 | ABSENT | — (only file-type allow/deny `security/share_policy.dart`) | share_policy_test (gate only) | template columns undecided (B9 question) | B9 |
| M17.2 | Masters bulk import | P1 | P1 active | FR-M17-002 | ABSENT | — | — | no import pipeline; no import_batch tables | B9 |
| M17.3 | Opening balances import | P1 | P1 active | FR-M17-003 | ABSENT | — | — | — | B9 |
| M17.4 | Legacy transaction import | P1 | P1 active | FR-M17-004 | ABSENT | — | — | — | B9 |
| M17.5 | Tally/Busy mapping guide (Excel) | P1 | P1 active | FR-M17-005 | ABSENT | — | — | guide absent | B9 |
| M17.6 | Validation | P1 | P1 active | FR-M17-002 | ABSENT | — | — | — | B9 |
| M17.7 | Preview and error report | P1 | P1 active | FR-M17-003 | ABSENT | — | — | no import_error table | B9 |
| M17.8 | Import modes | P1 | P1 active | FR-M17-004 | ABSENT | — | — | — | B9 |
| M17.9 | Import log and rollback | P2 | P2 | FR-M17-004 | ABSENT | — | — | — | B9 |
| M17.10 | Export | P1 | P1 active | FR-M17-005 | ABSENT | — (report export absent; share path is platform B13) | — | XLSX approach undecided | B9 |
| M17.11 | Tally/Busy native import (R3 only) | P3 | R3 DEFERRED | FG-006, G0-DEF-001 | DEFERRED | — (grep-absent) | — | R3 feasibility only | B9 |
| M17.12 | Migration reconciliation | P1 | P1 active | FR-M17-004 | ABSENT | — | report_consistency_test (reports agree; not migration) | procedure absent | B9 |

## M18 Admin Module → B4
| M18.1 | Super User console | P1 | P1 active | FR-M18-001 | ABSENT | — (no user table) | — | first-user rule undecided (B4 question) | B4 |
| M18.2 | Company administration | P1 | P1 active | FR-M18-001 | WIRED+TESTED | bundle `companies:190` | company_item_repository_test | — | B4 |
| M18.3 | User administration | P1 | P1 active | FR-M18-001 | ABSENT | — | — | — | B4 |
| M18.4 | Role and rights matrix | P1 | P1 active | FR-M18-001 | ABSENT | — (undefined rights open — B4 question) | — | rights undefined | B4 |
| M18.5 | Data-level restrictions | P2 | P2 | FR-M18-001 | ABSENT | — | — | — | B4 |
| M18.6 | Voucher controls (locks/series/auth) | P1 | P1 active | FR-M18-001 | WIRED+TESTED | bundle `periodLocks:196` → `period_lock.dart` + engine `isDateLocked` | business_cycles_test (lock→reject→unlock→post) | unlock rights wait M19 (P-PERIODLOCK) | B4 |
| M18.7 | Configuration lock | P1 | P1 active | FR-M18-001 | PARTIAL | layout features save (presentation-direct) | layout_profile_test | lock semantics absent | B4 |
| M18.8 | Audit trail and activity log | P1 | P1 active | FR-M18-002, OD-DB-004 | WIRED+TESTED | bundle `audit:189` → `audit_log.dart` + triggers (m017) | audit_append_only_test + migration_hardening_test | viewer is UI (B-series UI handoff) | B4 |
| M18.9 | Data utilities (rebuild/verify) | P2 | P2 | FR-M18-001 | PARTIAL | `NiavDatabase` bootstrap + migration rerun (no rebuild utility) | migration_test (repeat-safe) | rebuild utility absent | B4 |
| M18.10 | Device and access control (login TBC) | P3 | P3 TBC | FR-M18-001 | ABSENT | device_id exists (`data/security/device_id_service.dart`) but no access-control wiring | device_id_service_test (id only) | login restrictions undecided | B4 |
| M18.11 | Licence and subscription view (see M20) | P1 | P1 active | FR-M20-001 | ABSENT | — | entitlements_test (evaluation only) | view absent | B5 |

## M19 Users, Roles & Multi-user → B4 (transport → B12)
| M19.1 | Authentication (incl. OTP-boundary) | P1 | P1 active | FR-M19-001 | ABSENT | — (no user/role tables; OTP needs SMS = BOUNDARY) | — | local auth design absent | B4 |
| M19.2 | Multi-user concurrency (LAN/hotspot file merge) | P1 | P1 S1 (ZCP §6) | FR-M19-002 | BOUNDARY | bundle `ops:188` → `operation_log.dart` (envelope exists; transport absent) | migration_hardening_test (record_version/chain only) | transport + conflict policy deferred S1 | B12 |
| M19.3 | Predefined roles (list to confirm) | P1 | P1 list-open | FR-M19-002 | ABSENT | — | — | role list unconfirmed | B4 |
| M19.4 | Custom roles | P1 | P1 active | FR-M19-002 | ABSENT | — | — | — | B4 |
| M19.5 | User-wise defaults | P1 | P1 active | FR-M19-002 | ABSENT | — | — | — | B4 |
| M19.6 | Multi-device | P2 | P2 | FR-M19-002 | ABSENT | device_id only | device_id_service_test | pairing/re-pair flow absent | B12 |
| M19.7 | Password policy | P2 | P2 | FR-M19-002 | ABSENT | — | — | lockout delays undecided (B4 question) | B4 |

## M20 Licensing & Trial → B5
| M20.1 | Free trial | P1 | P1 active | FR-M20-001 | WIRED+TESTED | `lib/main.dart:70 runStartup` → `lib/app/startup.dart:277 CompositionRoot.backend` → bundle `trial:211` → `data/security/trial_service.dart` (`ensureCompanyAnchor`, `evaluate`) + `data/security/trial_store.dart` | trial_service_test (anchor lifecycle, earliest-wins, R1 named) + write_gate_test (table) | activation/key format waits B5 (denylist preimage = sha256(deviceId), documented) | B5 |
| M20.2 | Trial rules (edition-in-trial TBC) | P1 | P1 TBC | FR-M20-001 | PARTIAL | same as M20.1 + `entitlements.json` trial cell | trial_service_test (JSON parity) | edition-in-trial undecided; month arithmetic PROPOSAL P-TRIAL-END | B5 |
| M20.3 | Paid licences (prices TBC) | P1 | P1 TBC prices | FR-M20-001 | ABSENT | — (no licence table) | — | licence structure undecided (B5 question) | B5 |
| M20.4 | Licence activation | P1 | P1 active | FR-M20-001 | ABSENT | — | — | key/signature absent | B5 |
| M20.5 | Renewal and payment (mechanism TBC) | P2 | P2 TBC | FR-M20-002 deferred | DEFERRED | — | — | no in-app payment in V1 | B5 |
| M20.6 | Post-expiry behaviour (grace TBC) | P1 | P1 TBC grace | D-04 | WIRED+TESTED | bundle facade `entitlementState/daysLeft/reminderDue/exportBackupAllowed` (`composition_root.dart`) + choke `TrialWriteGate` via `recordLineage` | write_gate_test (expired/denied refuse, reads+export survive) | grace length per D-10/R1a; banner copy is UI work (UI_HANDOFF_B1) | B5 |
| M20.7 | Vendor-side licence admin | P2 | P2 | FR-M20-001 | ABSENT | — | — | — | B5 |

## M21 Printing, Sharing & Communication → B11 (transport → B13)
| M21.1 | Print formats | P1 | P1 active | FR-M21-001 | PARTIAL | pure models `data/print/*` (no bundle field; presentation-called) — ISLAND-adjacent | template_test + escpos_test + pdf_layout_test | shared print model exists; device matrix pending | B11 |
| M21.2 | Print devices (matrix TBD) | P1 | P1 + G5 matrix | FR-M21-001, G0-VER-006 | BLOCKED | same models (transport absent) | printer_caps_test (caps only) | frozen matrix + physical 58/80mm + PDF missing | B11+B13 |
| M21.3 | Share (FileProvider allowlist) | P1 | P1 active | FR-M21-001 | PARTIAL | `security/share_policy.dart` gates + `data/print/release_delivery.dart` OUT-list | share_policy_test | FileProvider/device proof pending (G0-VER-008) | B13 |
| M21.4 | UPI QR | P1 | P1 active | FR-M21-001 | PARTIAL | QR payload helper in print models (encoder choice open) | template_test | QR encoder undecided (B11 question) | B11 |
| M21.5 | Statement / reminder templates | P2 | P2 | FR-M21-002 | ABSENT | — | — | — | B11 |
| M21.6 | Bulk send | P3 | P3 | FR-M21-002 | ABSENT | — (human-mediated only per FG-011) | — | automated APIs excluded | B11 |

## M22 Backup, Sync, Security & Audit → B3/B12/B2/B4/B13
| M22.1 | Offline-first storage | P1 | P1 active | FR-M22-001 | WIRED+TESTED | `startup.dart:243` encrypted open + `NiavDatabase.bootstrap` | cipher_opener_test + persistence_reload_test | — | B3 |
| M22.2 | Device sync (cloud relay deferred) | P1 | P1 S1 (D-R6/ZCP §6) | FG-009/010, G0-SCH-005 | BOUNDARY | `ops` + `operation_dependency` + `sync_conflict` tables; no transport | migration_hardening_test (version/chain) | open points undecided (B12 question) | B12 |
| M22.3 | Backup / restore | P1 | P1 active | FR-M22-001 | PARTIAL | `data/security/backup.dart:179 checkRestorable` guard (no full restore flow; no manifest table) | backup_test + backup_integrity_test + backup_company_guard_test | container/extension/passphrase/schedule undecided (B3); restore flow deferred | B3 |
| M22.4 | Data security (Keystore/cipher) | P1 | P1 active, device pending | D-06, DB-011 | PARTIAL | `key_lifecycle.dart` + `cipher_opener.dart` (chacha20 pin read-back) + B1 `guardCompanyOpen` clock observation w/ rollback audit | key_lifecycle_test + cipher_opener_test + trial_service_test (clock guard) | KDF/AEAD/signatures undecided (B2); device proof pending | B2 |
| M22.5 | Audit trail (see M18.8) | P1 | P1 active | FR-M18-002 | WIRED+TESTED | bundle `audit:189` + m017 append-only triggers | audit_append_only_test | — | B4 |
| M22.6 | Data privacy compliance (VERIFY law) | P2 | P2 VERIFY | O-14/R-13, G0-VER-007 | BLOCKED | — (draft map only) | — | reviewer + retention + DPDP readings missing | B4+B14 |
| M22.7 | Platform support (Android-only V1) | P1 | P1 decided D-05 | FR-M22-001 | WIRED+TESTED | Android Keystore channel + `MainActivity.kt` (no-op without device) | production_boundary_test + startup_error_state_test | iOS/web deferred; adapters pending B13 | B13 |

## M23 UI Customisation Framework → B11
| M23.1 | Screen visibility | P1 | P1 active | FR-M23-001 | PARTIAL | bundle `layoutProfiles:205` versions (no per-screen visibility store) | layout_profile_test | visibility schema absent | B11 |
| M23.2 | Home dashboard designer | P1 | P1 active | FR-M23-001 | ABSENT | — (dashboard screen exists, designer absent) | hub_screens_test (screens only) | — | B11 |
| M23.3 | Voucher form customiser | P1 | P1 active | FR-M23-001 | ABSENT | — | — | — | B11 |
| M23.4 | Simple vs. Advanced mode | P1 | P1 R1a boundary (D-10) | FR-M23-001 | ABSENT | — | — | mode gate absent | B11 |
| M23.5 | Report customiser | P2 | P2 | FR-M23-001 | ABSENT | — | — | — | B11 |
| M23.6 | Theme and font size | P2 | P2 | FR-M23-001 | PARTIAL | app theme + text-scale (D4) — presentation only | shell_test | backend store absent | B11 |
| M23.7 | Shortcut/favourites bar | P1 | P1 active | FR-M23-001 | ABSENT | — | — | — | B11 |

## M24 Utilities & Support → B11, all P2/P3
| M24.1 | Dashboard and insights | P1 | P1 active | FR-M24-001 | PARTIAL | dashboard reads (books/stock/outstanding via scope) | hub_screens_test + report_consistency_test | insights absent | B11 |
| M24.2 | Notifications centre | P2 | P2 DEFERRED | FR-M24-001 | DEFERRED | — | — | — | B11 |
| M24.3 | Help and onboarding | P2 | P2 DEFERRED | FR-M24-001 | DEFERRED | onboarding screen exists (M01) but help content absent | onboarding_test (setup only) | guides absent | B11 |
| M24.4 | Support (mechanism TBC) | P2 | P2 DEFERRED+TBC | FR-M24-001 | DEFERRED | — | — | channel mechanism undecided | B11 |
| M24.5 | Reminders and to-do | P3 | P3 | FR-M24-001 | ABSENT | — | — | — | B11 |
