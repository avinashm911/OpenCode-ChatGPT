import fs from 'node:fs';
import path from 'node:path';

const root = process.cwd();
const outDir = path.join(root, 'docs', 'opencode_master_prompts');
const htmlFiles = fs.readdirSync(root).filter((name) => name.endsWith('.html')).sort();

if (htmlFiles.length !== 15) {
  throw new Error(`Expected exactly 15 living HTML documents; found ${htmlFiles.length}`);
}

const coreIdRe = /\b(?:FR-COM-\d{3}|FR-M\d{2}(?:-\d{3})?|OD-(?:DB|FD|UI)-\d{3}|OD-\d{3}|FG-\d{3}|G0-(?:CON|DEF|SCH|VER|OWN)-\d{3}|D-M\d+|D-\d+|M\d{2}|DSS-C-\d{3}|DSS-O\d+|DB-\d{3}|TC-[A-Z0-9-]+|US-\d{3}|AC-\d{3}|RLS-\d{3}|WP-\d{2}|W-\d{2}|TD-[A-Z0-9-]+|UI-\d{3}|UX-\d{3}|REG-[A-Z0-9-]+|RTM-[A-Z0-9-]+|O-[A-Z0-9?]+(?:-\d+)?|A-(?:FG-\d+|\d+)|R-\d+|V-FG-\d+)\b/g;
const auxiliaryIdRe = /\b(?:O-[A-Z0-9?]+(?:-\d+)?|A-FG-\d+|R-\d+|V-FG-\d+)\b/g;

function clean(value) {
  return value
    .replace(/<[^>]*>/g, ' ')
    .replace(/&amp;/g, '&').replace(/&gt;/g, '>').replace(/&lt;/g, '<')
    .replace(/&#39;/g, "'").replace(/&quot;/g, '"')
    .replace(/&nbsp;/g, ' ').replace(/\s+/g, ' ').trim();
}

function esc(value) {
  return String(value ?? '').replaceAll('|', '\\|').replaceAll('\n', ' ');
}

function rowsOf(file) {
  const raw = fs.readFileSync(path.join(root, file), 'utf8');
  return [...(raw.match(/<tr[\s\S]*?<\/tr>/gi) ?? [])].map((row) => ({
    file,
    raw: row,
    text: clean(row),
    cells: [...row.matchAll(/<(?:td|th)[^>]*>([\s\S]*?)<\/(?:td|th)>/gi)].map((m) => clean(m[1])),
  }));
}

const rows = htmlFiles.flatMap(rowsOf);
const sourceIndex = new Map();
const auxiliary = new Map();
for (const row of rows) {
  for (const id of new Set(row.cells.flatMap((cell) => cell.match(coreIdRe) ?? []))) {
    if (!sourceIndex.has(id)) sourceIndex.set(id, []);
    sourceIndex.get(id).push(row);
  }
  for (const id of new Set(row.text.match(auxiliaryIdRe) ?? [])) {
    if (!auxiliary.has(id)) auxiliary.set(id, new Set());
    auxiliary.get(id).add(row.file);
  }
}

const promptFiles = {
  p00: '00_resume_baseline_and_traceability.md',
  p01: '01_local_backend_continuation.md',
  p02: '02_onboarding_and_localisation.md',
  p03: '03_masters_and_search_continuation.md',
  p04: '04_voucher_engine_and_orders.md',
  p05: '05_document_flow_approvals_and_counter.md',
  p06: '06_inventory_accounting_and_reports.md',
  p07: '07_import_gst_brs_and_statutory_boundary.md',
  p08: '08_admin_users_and_licensing.md',
  p09: '09_security_backup_and_sync_boundary.md',
  p10: '10_outputs_customisation_and_support.md',
  p11: '11_frontend_completion.md',
  p12: '12_hardware_release_and_evidence.md',
  p13: '13_final_verification_and_gate_report.md',
};

function owner(id) {
  if (/^G0-(?:CON|DEF|OWN)-/.test(id) || /^D-(?:\d+|M[1237])$/.test(id)) return 'p00';
  if (/^G0-VER-(?:004|006|007|008)$/.test(id)) return 'p12';
  if (/^G0-VER-/.test(id)) return 'p13';
  if (id === 'D-M4' || /^FR-COM-/.test(id) || id === 'OD-DB-001') return 'p01';
  if (/^M0[12]$/.test(id) || /^FR-M0[12]-/.test(id)) return 'p02';
  if (id === 'M03' || id === 'M12' || /^FR-M03-/.test(id) || /^FR-M12-/.test(id)) return 'p03';
  if (/^M0[4-8]$/.test(id) || /^FR-M0[4-8]-/.test(id) || id === 'G0-SCH-003' || id === 'G0-SCH-007') return 'p04';
  if (/^M(09|10|11)$/.test(id) || /^FR-M(09|10|11)-/.test(id) || id === 'OD-FD-004') return 'p05';
  if (/^M(13|14|15)$/.test(id) || /^FR-M(13|14)-/.test(id) || id === 'D-M5' || id === 'FG-013' || id === 'OD-FD-001' || id === 'OD-DB-002' || id === 'G0-SCH-001' || id === 'G0-SCH-002') return 'p06';
  if (/^M(16|17)$/.test(id) || /^FR-M(16|17)-/.test(id) || /^FG-00[1-8]$/.test(id) || id === 'FG-015' || id === 'OD-FD-002' || id === 'OD-FD-003' || id === 'OD-DB-003' || id === 'G0-SCH-004') return 'p07';
  if (/^M(18|19|20)$/.test(id) || /^FR-M(18|19|20)-/.test(id) || /^FG-(012|014)$/.test(id) || id === 'OD-FD-005' || id === 'OD-UI-005' || id === 'G0-SCH-006') return 'p08';
  if (id === 'M22' || /^FR-M22-/.test(id) || id === 'OD-DB-004' || id === 'OD-DB-005' || id === 'OD-DB-006' || /^FG-(009|010)$/.test(id) || id === 'G0-SCH-005') return 'p09';
  if (id === 'OD-FD-006') return 'p12';
  if (/^M(21|23|24)$/.test(id) || /^FR-M(21|23|24)-/.test(id) || id === 'G0-SCH-004' || id === 'FG-011') return 'p10';
  if (/^OD-UI-/.test(id)) return 'p11';
  if (/^OD-/.test(id)) return 'p11';
  if (/^(?:DSS-C|DSS-O|DB)-/.test(id)) return 'p01';
  if (/^(?:UI|UX)-/.test(id)) return 'p11';
  if (/^(?:TC|US|AC|RLS|TD|WP|W|R|V-FG)-/.test(id)) return 'p13';
  if (/^A-FG-/.test(id)) return 'p07';
  if (/^(?:REG|RTM)-/.test(id)) return 'p00';
  if (/^FG-/.test(id)) return 'p07';
  if (/^G0-SCH-/.test(id)) return 'p01';
  if (/^M\d{2}$/.test(id)) return 'p00';
  return 'p00';
}

function disposition(id) {
  if (id === 'FR-M02-002' || id === 'OD-UI-003' || id === 'G0-OWN-002' || id === 'FG-008') return 'Excluded';
  if (id === 'G0-DEF-001' || id === 'G0-DEF-002' || id === 'G0-DEF-003' || id === 'FG-006' || id === 'FG-007') return 'Deferred';
  if (/^G0-VER-/.test(id)) return 'Blocked evidence';
  if (id === 'FG-002' || id === 'FG-003' || id === 'OD-FD-002' || id === 'OD-DB-003' || id === 'FR-M16-003' || id === 'FR-M16-004') return 'Boundary / blocked until verified source';
  if (id === 'FR-M17-003' || id === 'FR-M19-003' || id === 'FR-M22-002' || id === 'FR-M22-003' || id === 'OD-FD-003' || id === 'OD-DB-006') return 'Boundary';
  if (/^G0-SCH-/.test(id)) return 'Active schema change';
  const priority = priorityOf(id);
  if (/^P[23]$/.test(priority)) return `Deferred by priority ${priority}`;
  if (/^P1\s*\/\s*P[23]$/.test(priority)) return `Active P1; deferred ${priority.split('/')[1].trim()}`;
  if (/^G0-(?:CON|OWN)-/.test(id) || /^D-/.test(id) || /^OD-/.test(id) || /^FG-/.test(id)) return 'Decision/design control';
  return 'Active implementation';
}

function preferredRows(id) {
  const candidates = sourceIndex.get(id) ?? [];
  const preferred = /^(?:TC-|TD-|WP-|W-)/.test(id) ? 'NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html'
    : /^(?:US-|AC-|RLS-|RTM-)/.test(id) ? 'NiAv_Requirements_Traceability_Matrix_v0.1.html'
    : /^(?:DSS-C-|DSS-O|DB-)/.test(id) ? 'NiAv_Data_Schema_Specification_v0.1.html'
    : id.startsWith('FR-') ? 'NiAv_Functional_Requirements_Input_Data_v0.1.html'
    : id.startsWith('M') ? 'NiAv_ Modules & Sub-Modules Register v0.4.html'
    : id.startsWith('FG-') ? 'NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html'
    : id.startsWith('OD-FD-') ? 'NiAv_Functional_Design_Document_v0.1.html'
    : id.startsWith('OD-UI-') ? 'NiAv_UI_UX_Specification_Document_v0.1.html'
    : id.startsWith('OD-DB-') ? 'NiAv_Data_Schema_Specification_v0.1.html'
    : id.startsWith('G0-') ? 'NiAv_ Modules & Sub-Modules Register v0.4.html'
    : 'NiAv_ Universal Master Plan v0.2.html';
  const escaped = id.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const cellRe = new RegExp(`(^|[^A-Za-z0-9_-])${escaped}([^A-Za-z0-9_-]|$)`);
  const score = (row) => {
    const first = row.cells[0] ?? '';
    let value = row.file === preferred ? 20 : 0;
    if (cellRe.test(first)) value += 100;
    else if (row.cells.some((cell) => cellRe.test(cell))) value += 35;
    if (/change\s*log|history|historical/i.test(row.text)) value -= 80;
    if (!id.startsWith('G0-VER-') && /G0-VER-/.test(first)) value -= 40;
    return value;
  };
  return [...candidates].sort((a, b) => score(b) - score(a));
}

function statement(id) {
  const row = preferredRows(id)[0];
  if (!row) return 'No canonical table row found; inspect the 15-document source set before implementation.';
  if (/^(?:TC-|TD-|WP-|W-|US-|AC-|RLS-|RTM-)/.test(id)) return row.cells.slice(0, 8).join(' — ');
  if (id.startsWith('FR-') && row.cells.length >= 3) return row.cells[2];
  if (id.startsWith('M') && row.cells.length >= 2) return row.cells.slice(0, 4).join(' — ');
  if (/^(?:OD-|FG-|G0-|D-)/.test(id) && row.cells.length >= 3) return row.cells.slice(0, 6).join(' — ');
  return row.text;
}

function sourceRow(id) {
  return preferredRows(id)[0] ?? { cells: [] };
}

function priorityOf(id) {
  const row = sourceRow(id);
  const explicit = row.cells.find((cell) => /^P[123](?:\s*\/\s*P[123])?$/.test(cell.trim()));
  if (explicit) return explicit.trim();
  const match = row.text.match(/\bP[123](?:\s*\/\s*P[123])?\b/);
  return match ? match[0] : 'not stated';
}

function gateOf(id) {
  const row = sourceRow(id);
  const match = row.text.match(/\b(?:G0|G1|G2|G3|G4|G5|S1|S2|S3|R1a|R1b|R2|R3|Later release|Go-live|VERIFY|TBC)\b/i);
  return match ? match[0] : 'not stated';
}

function task(id) {
  const s = statement(id);
  if (disposition(id) === 'Excluded') return `Do not implement this item. Add a negative test proving the excluded capability is not exposed. Preserve the source decision: ${s}`;
  if (disposition(id).startsWith('Deferred')) return `Do not implement this item in the current release. Record priority ${priorityOf(id)} and gate ${gateOf(id)}, and keep it out of active acceptance criteria. Source: ${s}`;
  if (disposition(id) === 'Blocked evidence') return `Do not manufacture evidence. Create/update the named evidence record and stop this item as blocked until the owner supplies the source evidence. Source: ${s}`;
  if (disposition(id).startsWith('Boundary')) return `Implement only the safe documented boundary and its validation/replay behavior. Keep the unresolved downstream behavior blocked. Source: ${s}`;
  if (id.startsWith('M')) return `Implement only the P1 sub-modules of ${id} in the current release. Enumerate every P2/P3/TBC sub-module from the Modules Register as deferred or blocked with its gate; do not silently omit or implement them. Module priority: ${priorityOf(id)}. Gate: ${gateOf(id)}. Source: ${s}`;
  if (id.startsWith('FR-')) {
    const c = sourceRow(id).cells;
    return `Implement the source requirement exactly. Required input/data: ${c[3] ?? 'read the source row'}. State: ${c[4] ?? 'read the source row'}. Validation: ${c[5] ?? 'read the source row'}. Interaction: ${c[6] ?? 'read the source row'}. Downstream: ${c[7] ?? 'read the source row'}. Source requirement: ${s}`;
  }
  if (/^(?:TC-|TD-|WP-|W-)/.test(id)) return `Execute or implement the exact source test/work-package/data row identified by ${id}. Use only its stated preconditions, steps, expected result and evidence fields; do not invent substitute coverage. Source: ${s}`;
  if (/^(?:US-|AC-|RLS-|RTM-)/.test(id)) return `Trace this exact user/acceptance/release/RTM row to the owning implementation without changing its scope. If the row is deferred or gated, record that boundary instead of implementing it. Source: ${s}`;
  if (/^(?:DSS-C-|DSS-O|DB-)/.test(id)) return `Apply this exact data/schema control to the local backend design and migration only where the source row authorizes it. Preserve existing migrations and stop on missing SQLCipher/licence decisions. Source: ${s}`;
  if (id.startsWith('G0-SCH-')) return `Implement the approved schema change exactly, including migration, compatibility, rollback and tests. Source: ${s}`;
  return `Apply this decision/design constraint as an implementation rule only where the active reconciled row authorizes it; do not infer additional behavior. Source: ${s}`;
}

function verification(id) {
  const d = disposition(id);
  if (d === 'Excluded') return `V-${id}: static scan plus negative UI/domain test confirms the excluded feature is absent.`;
  if (d.startsWith('Deferred')) return `V-${id}: priority/gate ledger confirms deferred status (${priorityOf(id)}, ${gateOf(id)}); no active V1 acceptance test is allowed.`;
  if (d === 'Blocked evidence') return `V-${id}: evidence-record check confirms the exact required artifact is present, attributable and not simulated; otherwise status remains BLOCKED.`;
  if (d.startsWith('Boundary')) return `V-${id}: boundary test proves allowed local behavior, rejects unsupported behavior, and records the downstream gate.`;
  if (id.startsWith('FR-')) {
    const c = sourceRow(id).cells;
    return `V-${id}: test required data/input (${c[3] ?? 'source row'}), state (${c[4] ?? 'source row'}), validation (${c[5] ?? 'source row'}), interaction (${c[6] ?? 'source row'}) and downstream effect (${c[7] ?? 'source row'}); include persistence/restart and at least one invalid/denied case.`;
  }
  if (/^(?:TC-|TD-|WP-|W-)/.test(id)) return `V-${id}: execute the exact source test/work-package/data case and attach reproducible output; a generic unit test is not a substitute.`;
  if (/^(?:US-|AC-|RLS-|RTM-)/.test(id)) return `V-${id}: inspect the exact traceability row, link it to the implementation and evidence, and classify PASS, BLOCKED, DEFERRED or EXCLUDED without inventing acceptance criteria.`;
  if (/^(?:DSS-C-|DSS-O|DB-)/.test(id)) return `V-${id}: verify the exact schema/control row against migrations, repository behavior and persistence tests; report missing encryption or licence evidence as BLOCKED.`;
  if (id.startsWith('M')) return `V-${id}: module acceptance test covers each registered sub-module, persistence/restart and integration with its dependent module.`;
  if (id.startsWith('G0-SCH-')) return `V-${id}: migration applies on a clean and existing database, preserves data, supports compatibility checks and has rollback evidence.`;
  return `V-${id}: traceability review proves the active decision/design is applied once, historical/superseded text is not implemented, and the source gate is respected.`;
}

const ids = [...sourceIndex.keys()].sort();
const missing = ids.filter((id) => !owner(id) || !statement(id));
if (missing.length) throw new Error(`Missing owner or source statement for: ${missing.join(', ')}`);

fs.mkdirSync(outDir, { recursive: true });

const baseline = `# v1.1 continuation baseline and prompt migration map

The source tree is not empty. OpenCode must continue from these verified phase
reports and must not rebuild completed work:

- \`docs/implementation/phase-00.md\`: shell/value objects complete; +107 tests.
- \`docs/implementation/phase-01.md\`: engine-neutral database/repository foundation complete; +128 cumulative tests; encrypted production wiring remains blocked by P-SQLIB/P-KEYSTORE.
- \`docs/implementation/phase-02.md\`: M03 masters, onboarding/Parties & Items foundation and search slice complete; +166 cumulative tests; placeholder shell wiring and later-gate features remain open.

The next implementation gate is local-backend continuation and then the next
unfinished slice. Each prompt must inspect the previous report and skip or
repair completed work rather than recreate migrations or screens.

## Migration from deleted v0.9 prompt names

Historical reports may mention the deleted v0.9 paths. Use this mapping:

| Historical prompt | v1.1 continuation prompt |
|---|---|
| 00_intake_and_architecture.md | 00_resume_baseline_and_traceability.md |
| 01_local_backend_foundation.md | 01_local_backend_continuation.md |
| 02_masters_and_search.md | 03_masters_and_search_continuation.md |
| 02A_onboarding_and_localisation.md | 02_onboarding_and_localisation.md |
| Remaining v0.9 prompts | Matching v1.1 numbered prompt after source/priority/gate review |

The reports remain historical records and must not be rewritten merely to
replace old prompt filenames.
`;
fs.writeFileSync(path.join(outDir, 'BASELINE_AND_MIGRATION_MAP.md'), baseline);

const sourceInventory = `# NiAvERP prompt pack v1.0 — source inventory\n\nThis pack is generated from these 15 living HTML documents in the project root. They are the only requirements authority for this pack.\n\n${htmlFiles.map((f, i) => `${i + 1}. \`${f}\``).join('\n')}\n\n## Identifier counts\n\n- Core traceability IDs found: **${ids.length}**.\n- The earlier “156” count excluded the 7 \`FR-COM-*\` IDs and 16 short-form \`D-01\`–\`D-16\` IDs; this pack includes them.\n- Auxiliary source cross-reference IDs found: **${auxiliary.size}** (\`O-*\`, \`R-*\`, \`V-*\`, \`A-FG-*\`). They are indexed below but are not silently treated as separate functional requirements.\n\n## Authority rule\n\nFor repeated IDs, the active reconciled row controls. Historical rows, old change-log text and superseded rows are evidence of history only. If the active status cannot be established, the owning prompt must report BLOCKED and must not choose a value.\n\n## Auxiliary cross-reference index\n\n${[...auxiliary.entries()].sort().map(([id, files]) => `- \`${id}\` — ${[...files].sort().map(esc).join(', ')}`).join('\n')}\n`;

const matrixHeader = `# NiAvERP prompt pack v1.1 — complete requirement-level traceability matrix\n\nGenerated from the 15 living HTML documents. Each source ID has exactly one implementation owner and exactly one verification task. Priority and gate are source-derived; they are not permission to invent missing decisions.\n\n| ID | Class | Priority | Gate | Source documents | Disposition | Implementation prompt | Explicit implementation task | Exactly-one verification task |\n|---|---|---|---|---|---|---|---|---|`;
const matrixRows = ids.map((id) => {
  const files = [...new Set((sourceIndex.get(id) ?? []).map((r) => r.file))].sort().join('<br>');
  const cls = id.startsWith('FR-') ? 'FR' : id.startsWith('OD-') ? 'OD' : id.startsWith('FG-') ? 'FG' : id.startsWith('G0-') ? 'G0' : id.startsWith('M') ? 'Module' : 'Decision';
  return `| \`${id}\` | ${cls} | ${esc(priorityOf(id))} | ${esc(gateOf(id))} | ${files} | ${esc(disposition(id))} | [${promptFiles[owner(id)]}](./${promptFiles[owner(id)]}) | ${esc(task(id))} | ${esc(verification(id))} |`;
}).join('\n');
fs.writeFileSync(path.join(outDir, 'TRACEABILITY_MATRIX.md'), `${matrixHeader}\n${matrixRows}\n`);
fs.writeFileSync(path.join(outDir, 'VERIFICATION_CATALOG.md'), `# v1.0 verification catalog\n\nEvery core ID has exactly one verification task. The final prompt must execute or explicitly classify every task below.\n\n${ids.map((id, i) => `${i + 1}. **V-${id}** — ${verification(id)} — Source: ${(sourceIndex.get(id) ?? []).map((r) => r.file).filter((v, j, a) => a.indexOf(v) === j).sort().join(', ')}`).join('\n')}\n`);

const groups = new Map(Object.keys(promptFiles).map((key) => [key, []]));
for (const id of ids) groups.get(owner(id)).push(id);

function directive(key) {
  if (key === 'p00') return `\n## Resume/baseline directive\n\nThis is a read-only intake and continuation plan. Compare the current tree with phase-00, phase-01 and phase-02 reports; record what is complete, what is genuinely missing and the next executable gate. Do not rebuild code or migrations in this prompt.\n`;
  if (key === 'p01') return `\n## Local-backend continuation directive\n\nThis prompt owns the outstanding Slice 1 continuation. Inspect the existing migration runner, repositories, tests and phase-01 report first. Complete only the approved SQLCipher/Drift/Keystore wiring if P-SQLIB/P-KEYSTORE are supplied. If they remain open, preserve the engine-neutral seams, add no plaintext fallback, and stop only production encryption/wiring while continuing independent database work. Do not recreate migrations m001–m009 or replace passing tests.\n`;
  if (key === 'p02') return `\n## Onboarding continuation directive\n\nImplement the unfinished M01/M02 work over the existing shell and repositories. Preserve phase-00 and phase-02 code; do not rebuild the Parties & Items or masters slice.\n`;
  if (key === 'p03') return `\n## Masters/search continuation directive\n\nTreat phase-02 masters/search as completed baseline. Verify it, repair only evidence-backed gaps, and implement only the explicitly owned P1 items not already present. Do not recreate m009 or replace existing repository tests.\n`;
  if (key === 'p11') return `\n## Frontend directive\n\nReplace placeholder tabs and wire screens only to real application services/use cases. The navigation decision alone is not frontend completion. Every completed screen requires loading, empty, validation, locked/conflict, success and recoverable-error states.\n`;
  if (key === 'p13') return `\n## Final verification directive\n\nRead the full verification catalog and the Test Plan identifiers. Verify implementation against existing phase reports and run only reproducible checks available in the environment. Do not convert host-only, legal, device, printer or delivery evidence into PASS.\n`;
  return '';
}

const common = `\n## Mandatory first actions\n\n1. Read the project-root \`AGENTS.md\`.\n2. Read the project-root \`DECISIONS.md\`.\n3. Read \`../GLOBAL_NO_INVENTION_CONTRACT.md\`.\n4. Read \`../BASELINE_AND_MIGRATION_MAP.md\`, \`../SOURCE_INVENTORY.md\`, the relevant slice of \`../TRACEABILITY_MATRIX.md\`, \`../STATUS_LEDGER.md\`, \`../SOURCE_CLARIFICATIONS.md\`, \`../g0/PENDING_INPUTS.md\`, the relevant living HTML rows and the previous phase report.\n5. If either governance file is missing or unreadable, stop with \`BLOCKED\`.\n\nThe existing source and phase reports are part of the working baseline. Do not rebuild completed phases. Verify them, repair only evidence-backed gaps, and continue from the stated next gate.\n\nNever invent fields, posting/tax rules, legal conclusions, package/licence choices, APIs, permissions, workflow states, schemas, performance targets or release channels. Do not edit the 15 HTML documents, workbooks or registers. Preserve standalone/offline-first V1 and all exclusions.\n\n## Required result\n\nImplement only the owned IDs below and only for their permitted priority/gate. For every ID, report its disposition exactly as \`implemented\`, \`boundary\`, \`deferred\`, \`blocked\` or \`excluded\`. Add code/tests only for permitted work. End with changed files, commands/results, test results, ID traceability, unresolved questions and the next gate.\n`;

for (const [key, file] of Object.entries(promptFiles)) {
  const owned = groups.get(key);
  const title = file.replace(/\.md$/, '').replace(/^\d+_/, '').replaceAll('_', ' ');
  const sections = owned.map((id) => `\n### \`${id}\` — ${disposition(id)}\n\n- **Implementation task:** ${task(id)}\n- **Verification task:** ${verification(id)}\n- **Source references:** ${(sourceIndex.get(id) ?? []).map((r) => r.file).filter((v, i, a) => a.indexOf(v) === i).sort().join(', ')}\n`).join('\n');
  const extra = key === 'p13' ? `\n## Final one-to-one audit\n\nRead the matrix and verify mechanically that every core ID appears once in an implementation-owner column and once in a verification-task column. Re-scan all 15 HTML files. Report any missing, duplicate, unclassified or newly discovered ID as FAIL. Do not issue unconditional sign-off if any active ID is unresolved, blocked or lacks evidence.\n` : '';
  fs.writeFileSync(path.join(outDir, file), `# NiAvERP OpenCode master prompt v1.1 — ${title}\n${common}${directive(key)}\n## Owned IDs (${owned.length})\n\n${owned.map((id) => `- \`${id}\``).join('\n')}\n${sections}${extra}`);
}

const deferred = ids.filter((id) => disposition(id).startsWith('Deferred'));
const blocked = ids.filter((id) => disposition(id) === 'Blocked evidence' || disposition(id).includes('blocked'));
const excluded = ids.filter((id) => disposition(id) === 'Excluded');
fs.writeFileSync(path.join(outDir, 'STATUS_LEDGER.md'), `# v1.0 status ledger\n\n## Deferred\n\n${deferred.map((id) => `- \`${id}\` — ${statement(id)}`).join('\n')}\n\n## Blocked or boundary-blocked\n\n${blocked.map((id) => `- \`${id}\` — ${statement(id)}`).join('\n')}\n\n## Excluded\n\n${excluded.map((id) => `- \`${id}\` — ${statement(id)}`).join('\n')}\n\nAn item may move from blocked/deferred only when the exact source decision or evidence is supplied. No prompt may convert these statuses into PASS by assumption.\n`);

const readme = `# NiAvERP OpenCode master prompts v1.0\n\nThis is the replacement prompt pack. The previous prompt pack was deleted. Run from:\n\n\`\`\`powershell\ncd "E:\\NiavERP v2 OpenAI\\niaverp"\n\`\`\`\n\n## Mandatory order\n\n1. \`00_governance_intake_and_traceability.md\`\n2. \`01_architecture_and_common_requirements.md\`\n3. \`02_onboarding_and_localisation.md\`\n4. \`03_masters_and_search.md\`\n5. \`04_voucher_engine_and_orders.md\`\n6. \`05_document_flow_approvals_and_counter.md\`\n7. \`06_inventory_accounting_and_reports.md\`\n8. \`07_import_gst_brs_and_statutory_boundary.md\`\n9. \`08_admin_users_and_licensing.md\`\n10. \`09_security_backup_and_sync_boundary.md\`\n11. \`10_outputs_customisation_and_support.md\`\n12. \`11_frontend_completion.md\`\n13. \`12_hardware_release_and_evidence.md\`\n14. \`13_final_verification_and_gate_report.md\`\n\nRun one prompt at a time:\n\n\`\`\`powershell\nopencode run --prompt-file ..\\docs\\opencode_master_prompts\\00_governance_intake_and_traceability.md\n\`\`\`\n\nDo not run the next prompt after FAIL or after a blocked decision affecting that prompt. Every prompt explicitly requires \`AGENTS.md\` and \`DECISIONS.md\` first.\n\n## Coverage guarantee\n\n- \`TRACEABILITY_MATRIX.md\` contains every one of the ${ids.length} core IDs extracted from the 15 HTML documents.\n- Each ID has exactly one owner prompt and exactly one verification task.\n- \`STATUS_LEDGER.md\` separates deferred, blocked/boundary-blocked and excluded items.\n- The final prompt must re-scan the HTML files and fail on any missing, duplicate or newly discovered core ID.\n\n## Regenerate after source changes\n\nFrom the repository root, run:\n\n\`\`\`powershell\nnode tools\\generate_prompt_pack_v1.mjs\n\`\`\`\n\nRegeneration is required whenever a living HTML document changes. Review the generated diff before executing prompts.\n`;
fs.writeFileSync(path.join(outDir, 'README.md'), readme);
fs.writeFileSync(path.join(outDir, 'SOURCE_INVENTORY.md'), sourceInventory);
fs.writeFileSync(path.join(outDir, 'GLOBAL_NO_INVENTION_CONTRACT.md'), `# Global no-invention contract v1.0\n\nOpenCode must read \`AGENTS.md\`, \`DECISIONS.md\`, \`SOURCE_INVENTORY.md\` and \`TRACEABILITY_MATRIX.md\` before editing. Missing or unreadable governance files mean BLOCKED.\n\nThe 15 living HTML documents are the only requirements authority. Active reconciled rows control; historical and superseded rows do not. Do not invent a field, voucher, posting/tax rule, legal position, package, licence, API, permission, workflow state, schema, performance target or release channel. Do not edit principal documents from implementation prompts. Do not add cloud/server dependencies to standalone V1. Do not implement voice input, native Tally/Busy adapters, TDS/TCS, PF/ESI/payroll, automatic transliteration or direct statutory APIs.\n\nFor every owned ID, report one and only one of: implemented, boundary, deferred, blocked or excluded. Never report evidence as PASS unless the evidence is real, attributable and appropriate to the gate.\n`);

// Normalize generated support-file metadata and commands so regeneration cannot
// reintroduce the retired v0.9 names or the invalid --prompt-file option.
for (const file of ['SOURCE_INVENTORY.md', 'VERIFICATION_CATALOG.md', 'STATUS_LEDGER.md', 'GLOBAL_NO_INVENTION_CONTRACT.md']) {
  const filePath = path.join(outDir, file);
  let text = fs.readFileSync(filePath, 'utf8').replaceAll('v1.0', 'v1.1');
  if (file === 'SOURCE_INVENTORY.md') text = text.replace('Auxiliary source cross-reference IDs found:', 'Auxiliary source cross-reference IDs also found; canonical rows are included in the core matrix where applicable:');
  fs.writeFileSync(filePath, text);
}
let normalizedReadme = fs.readFileSync(path.join(outDir, 'README.md'), 'utf8')
  .replaceAll('v1.0', 'v1.1')
  .replace('00_governance_intake_and_traceability.md', '00_resume_baseline_and_traceability.md')
  .replace('01_architecture_and_common_requirements.md', '01_local_backend_continuation.md')
  .replace('03_masters_and_search.md', '03_masters_and_search_continuation.md')
  .replace('opencode run --prompt-file ..\\docs\\opencode_master_prompts\\00_governance_intake_and_traceability.md', 'opencode run -f ..\\docs\\opencode_master_prompts\\00_resume_baseline_and_traceability.md "Execute the attached prompt exactly."');
fs.writeFileSync(path.join(outDir, 'README.md'), normalizedReadme);

console.log(`Generated v1.1 prompt pack: ${ids.length} core IDs, ${auxiliary.size} auxiliary IDs, ${Object.keys(promptFiles).length} prompts.`);
