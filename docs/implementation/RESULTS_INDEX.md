D1 | 2026-10-06 | FAIL | tests 331/40 | Baseline red (analyze 5 issues, 40 failing tests on partial D1 tree); stopped per stop rule, no code changed.
D1 re-run | 2026-10-06 | FAIL | tests 331/40 | Re-verified identical red baseline on prompt re-issue (HEAD 6f2051a); stopped per stop rule, no code changed.
D0 | 2026-10-06 | PASS | tests 374/0 | Baseline triaged green (analyze clean); test-only repairs, no production changes; D1 inventory recorded.
D1 | 2026-10-06 | PASS | tests 404/0 | Engine invariants repaired and production backend wired (+30 tests: startup, cancel/atomicity, uuid, key/channel, lifecycle); analyze clean.
D0 | 2026-10-06 | PASS | tests 404/0 | Re-run: baseline green, no repairs needed; prompt coverage audit 00-13 added (07-11 partial, 12-13 not run).
D1 | 2026-10-06 | PASS | tests 404/0 | Re-verification: all items present-and-tested re-verified green (A1 by read, device pending); no code or test changes.
D2 | 2026-10-06 | PASS | tests 431/0 | Schema/security hardening: m017 triggers/vocab/index/checksum/chain/clock, MAC interface, Android guards; analyze clean.
D3 | 2026-10-06 | PASS | tests 451/0 | Invoice ledger posting (MPL templates, round-off, cancel mirrors), GST subset, ledger forms, parser; tax split/material/journal/export blocked or boundary with questions.
D4 | 2026-10-06 | PASS-WITH-BLOCKS | tests 449/1 | Localisation (en/hi/gu ARB), More tab (company/financial year/settings/period lock/language/about/disabled backup), formatter (Indian digit grouping), accessibility basics, lazy tabs/home caching, robustness; 1 pre-existing shell company-switch test blocked by lazy-tab C1; translator review list + deferred-feature list recorded.

E1 | 2026-10-06 | BLOCKED-DEPENDENT | protect: A1 (device-id rule missing) + A9 (sqlite3mc pin doc); A2-A8/A10 host-verified; 450/1 preserved; G0-VER-005/008 still missing | docs/implementation/RESULT_E1_make_app_start_on_device.md

E1b | 2026-10-06 | BLOCKED-DEPENDENT | A1: implemented-pending-approval (proposal in DECISIONS.md); A9: BLOCKED (sqlite3mc docs for 3.7.0 unconfirmed); source evidence quoted; file docs/g0/evidence/SQLITE3MC_CONFIG_20261006.md; result docs/implementation/RESULT_E1b_close_device_id_and_cipher_pin.md

E2 | 2026-10-06 | PASS-WITH-BLOCKS | A company-switch fixed (key + reset); B GST BLOCKED (memo OWNER_DECISION_MEMO_GST_POSTING.md); C backup MAC mandatory; D localisation source + machine-drafted hi/gu; 450/1 preserved | docs/implementation/RESULT_E2_correctness_fixes.md
