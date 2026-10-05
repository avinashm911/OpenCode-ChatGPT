# v1.1 source clarifications and blockers

These are source-level uncertainties or evidence gates. They are deliberately
not resolved by this prompt pack. OpenCode must stop the affected item and
record the exact ID rather than choose a value.

- `G0-VER-001` / `D-06`: production SQLCipher-class library, version, licence
  and Android 8 compatibility evidence are still required.
- `G0-VER-002` / `D-M4`: the rule source and golden GST-rounding fixture must
  be attached; code must follow the already recorded paise, quantity and
  round-half-up policy.
- `G0-VER-003`, `FG-002`, `FG-003`, `FR-M16-003`, `FR-M16-004` and
  `OD-FD-002`: official, pinned e-invoice, GST-return and e-way schemas plus
  the approved response/field list are required before schema-specific fields
  or adapters are implemented.
- `G0-VER-004`: APK/ZIP artifact and approved delivery-channel evidence are
  required; a share-sheet invocation is not delivery proof.
- `G0-VER-005` and `G0-VER-008`: real Android 8/current-device Keystore,
  backup/restore, share and FileProvider evidence is required; host tests are
  not a substitute.
- `G0-VER-006` / `OD-FD-006`: the frozen printer model matrix and physical
  results are required; do not invent printer models.
- `G0-VER-007`: a real legal reviewer, review date, applicable Act/source,
  retention decision and control mapping are required; a draft is not legal
  approval.
- Any source row marked `TBC`, `VERIFY`, `R1a`, `R1b`, `R2`, `R3`, `G1`,
  `G3`, `G5` or `S1` remains governed by that gate. The owner prompt may build
  only the explicitly permitted boundary.

This file is a stop list, not a substitute for owner decisions or evidence.
