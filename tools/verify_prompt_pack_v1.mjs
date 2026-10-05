import fs from 'node:fs';
import path from 'node:path';

const root = process.cwd();
const dir = path.join(root, 'docs', 'opencode_master_prompts');
const htmlFiles = fs.readdirSync(root).filter((f) => f.endsWith('.html')).sort();
const coreIdRe = /\b(?:FR-COM-\d{3}|FR-M\d{2}(?:-\d{3})?|OD-(?:DB|FD|UI)-\d{3}|OD-\d{3}|FG-\d{3}|G0-(?:CON|DEF|SCH|VER|OWN)-\d{3}|D-M\d+|D-\d+|M\d{2}|DSS-C-\d{3}|DSS-O\d+|DB-\d{3}|TC-[A-Z0-9-]+|US-\d{3}|AC-\d{3}|RLS-\d{3}|WP-\d{2}|W-\d{2}|TD-[A-Z0-9-]+|UI-\d{3}|UX-\d{3}|REG-[A-Z0-9-]+|RTM-[A-Z0-9-]+|O-[A-Z0-9?]+(?:-\d+)?|A-(?:FG-\d+|\d+)|R-\d+|V-FG-\d+)\b/g;

if (htmlFiles.length !== 15) throw new Error(`FAIL: expected 15 HTML documents, found ${htmlFiles.length}`);
const html = htmlFiles.map((f) => fs.readFileSync(path.join(root, f), 'utf8')).join('\n');
const cells = [...html.matchAll(/<(?:td|th)[^>]*>([\s\S]*?)<\/(?:td|th)>/gi)].map((m) => m[1]).join('\n');
const sourceIds = [...new Set(cells.match(coreIdRe) ?? [])].sort();
const matrix = fs.readFileSync(path.join(dir, 'TRACEABILITY_MATRIX.md'), 'utf8');
const matrixIds = [...matrix.matchAll(/^\| `([^`]+)` \|/gm)].map((m) => m[1]);
const catalog = fs.readFileSync(path.join(dir, 'VERIFICATION_CATALOG.md'), 'utf8');
const verificationIds = [...catalog.matchAll(/\*\*V-([^*]+)\*\*/g)].map((m) => m[1]);
const promptFiles = fs.readdirSync(dir).filter((f) => /^\d\d_.*\.md$/.test(f));
const ownerIds = promptFiles.flatMap((f) => {
  const text = fs.readFileSync(path.join(dir, f), 'utf8');
  return [...text.matchAll(/^- `([^`]+)`$/gm)].map((m) => m[1]);
});

function counts(values) {
  const result = new Map();
  for (const value of values) result.set(value, (result.get(value) ?? 0) + 1);
  return result;
}
function missingOrNotOnce(expected, actual) {
  const c = counts(actual);
  return expected.filter((id) => c.get(id) !== 1);
}
function extra(expected, actual) {
  const e = new Set(expected);
  return [...new Set(actual)].filter((id) => !e.has(id));
}

const failures = [];
if (missingOrNotOnce(sourceIds, matrixIds).length) failures.push(`matrix missing/duplicate: ${missingOrNotOnce(sourceIds, matrixIds).join(', ')}`);
if (missingOrNotOnce(sourceIds, ownerIds).length) failures.push(`owner missing/duplicate: ${missingOrNotOnce(sourceIds, ownerIds).join(', ')}`);
if (missingOrNotOnce(sourceIds, verificationIds).length) failures.push(`verification missing/duplicate: ${missingOrNotOnce(sourceIds, verificationIds).join(', ')}`);
if (extra(sourceIds, matrixIds).length) failures.push(`matrix has unknown IDs: ${extra(sourceIds, matrixIds).join(', ')}`);
if (extra(sourceIds, ownerIds).length) failures.push(`owner prompts have unknown IDs: ${extra(sourceIds, ownerIds).join(', ')}`);
if (extra(sourceIds, verificationIds).length) failures.push(`verification catalog has unknown IDs: ${extra(sourceIds, verificationIds).join(', ')}`);
for (const file of promptFiles) {
  const text = fs.readFileSync(path.join(dir, file), 'utf8');
  const match = text.match(/^## Owned IDs \((\d+)\)/m);
  if (!match || Number(match[1]) === 0) failures.push(`empty or malformed prompt: ${file}`);
  if (!text.includes('AGENTS.md') || !text.includes('DECISIONS.md') || !text.includes('GLOBAL_NO_INVENTION_CONTRACT.md')) failures.push(`governance reads missing: ${file}`);
}
for (const required of ['AGENTS.md', 'DECISIONS.md', 'SOURCE_INVENTORY.md', 'TRACEABILITY_MATRIX.md', 'STATUS_LEDGER.md', 'SOURCE_CLARIFICATIONS.md']) {
  if (!fs.existsSync(path.join(root, required === 'AGENTS.md' || required === 'DECISIONS.md' ? 'niaverp' : 'docs/opencode_master_prompts', required))) failures.push(`missing required file: ${required}`);
}

if (failures.length) {
  console.error('PROMPT PACK v1.1 VERIFY: FAIL');
  for (const failure of failures) console.error(`- ${failure}`);
  process.exit(1);
}
console.log(`PROMPT PACK v1.1 VERIFY: PASS — 15 HTML documents, ${sourceIds.length} core IDs, ${promptFiles.length} non-empty prompts, one owner and one verification task per ID.`);
