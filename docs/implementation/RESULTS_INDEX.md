D1 | 2026-10-06 | FAIL | tests 331/40 | Baseline red (analyze 5 issues, 40 failing tests on partial D1 tree); stopped per stop rule, no code changed.
D1 re-run | 2026-10-06 | FAIL | tests 331/40 | Re-verified identical red baseline on prompt re-issue (HEAD 6f2051a); stopped per stop rule, no code changed.
D0 | 2026-10-06 | PASS | tests 374/0 | Baseline triaged green (analyze clean); test-only repairs, no production changes; D1 inventory recorded.
D1 | 2026-10-06 | PASS | tests 404/0 | Engine invariants repaired and production backend wired (+30 tests: startup, cancel/atomicity, uuid, key/channel, lifecycle); analyze clean.
D0 | 2026-10-06 | PASS | tests 404/0 | Re-run: baseline green, no repairs needed; prompt coverage audit 00-13 added (07-11 partial, 12-13 not run).
D1 | 2026-10-06 | PASS | tests 404/0 | Re-verification: all items present-and-tested re-verified green (A1 by read, device pending); no code or test changes.
D2 | 2026-10-06 | PASS | tests 431/0 | Schema/security hardening: m017 triggers/vocab/index/checksum/chain/clock, MAC interface, Android guards; analyze clean.
D3 | 2026-10-06 | PASS | tests 451/0 | Invoice ledger posting (MPL templates, round-off, cancel mirrors), GST subset, ledger forms, parser; tax split/material/journal/export blocked or boundary with questions.
D4 | 2026-10-06 | PASS-WITH-BLOCKS | tests 449/1 | Localisation (en/hi/gu ARB), More tab (company/financial year/settings/period lock/language/about/disabled backup), formatter (Indian digit grouping), accessibility basics, lazy tabs/home caching, robustness; 1 pre-existing shell company-switch test blocked by lazy-tab C1; translator review list + deferred-feature list recorded.
