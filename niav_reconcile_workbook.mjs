import fs from 'node:fs/promises';
import path from 'node:path';
import { FileBlob, SpreadsheetFile } from 'file:///C:/Users/USER/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/@oai/artifact-tool/dist/artifact_tool.mjs';

const root = process.cwd();
const workbookPath = 'C:/Users/USER/Downloads/NiAv_Decisions_Workbook_v0.1.xlsx';
const runDate = '2026-10-01';
const stamp = '20261001';
const backupDir = path.join(root, `niav_reconciliation_backups_${stamp}`);
const reportPath = path.join(root, `niav_reconciliation_report_${stamp}.json`);

const docs = [
  ['REG', 'NiAv_ Modules & Sub-Modules Register v0.4.html', 'v0.4', 'v0.5'],
  ['SEC', 'NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html', 'v0.4', 'v0.5'],
  ['MPL', 'NiAv_ Universal Master Plan v0.2.html', 'v0.2', 'v0.3'],
  ['ZCP', 'NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html', 'v0.5', 'v0.6'],
  ['DSS', 'NiAv_Data_Schema_Specification_v0.1.html', 'v0.1', 'v0.2'],
  ['DB', 'NiAv_Database_Schema_Document_v0.1.html', 'v0.1', 'v0.2'],
  ['FGA', 'NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html', 'v0.1', 'v0.2'],
  ['FDD', 'NiAv_Functional_Design_Document_v0.1.html', 'v0.1', 'v0.2'],
  ['FRD', 'NiAv_Functional_Requirements_Input_Data_v0.1.html', 'v0.1', 'v0.2'],
  ['RSP', 'NiAv_Release_and_Support_Playbook_v0.1.html', 'v0.1', 'v0.2'],
  ['RTM', 'NiAv_Requirements_Traceability_Matrix_v0.1.html', 'v0.1', 'v0.2'],
  ['SYNC', 'NiAv_Sync_Protocol_Specification_v0.1.html', 'v0.1', 'v0.2'],
  ['TEST', 'NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html', 'v0.1', 'v0.2'],
  ['UIUX', 'NiAv_UI_UX_Specification_Document_v0.1.html', 'v0.1', 'v0.2'],
  ['UX', 'NiAv_UX_Specification_v0.2.html', 'v0.2', 'v0.3'],
];

const aliases = [
  ['REG', /\bREG\b|Modules\s*&\s*Sub-Modules/i], ['MPL', /\bMPL\b|Master\s*Plan/i],
  ['ZCP', /\bZCP\b|Zero-Cost/i], ['SEC', /\bSEC\b|Security/i], ['FGA', /\bFGA\b|Fit-Gap/i],
  ['FRD', /\bFRD\b|Functional\s*Requirements/i], ['FDD', /\bFDD\b|Functional\s*Design/i],
  ['DB', /(?:^|[\s/])DB(?:$|[\s/])|Database/i], ['DSS', /\bDSS\b|Data\s*Schema/i],
  ['SYNC', /\bSYNC\b|Sync\s*Protocol/i], ['TEST', /\bTEST\b|Test\s*Plan/i],
  ['UIUX', /\bUIUX\b|UI\/UX/i], ['UX', /UX\s*Spec/i], ['RTM', /\bRTM\b|Traceability/i],
  ['RSP', /\bRSP\b|Release\s*and\s*Support/i],
];

const esc = (v) => String(v ?? '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
const plain = (v) => String(v ?? '').replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();
const idsFrom = (v) => String(v ?? '').split('/').map(x => x.trim().replace(/\s*\([^)]*\)/g, '')).filter(Boolean);
const refsFrom = (v) => (String(v ?? '').match(/\b(?:RTM-O\d+|OD-(?:FD|DB|UI)-\d+|FR-[A-Z0-9-]+|FG-\d+)\b/gi) || []).map(x => x.toUpperCase());

function statusFor(row) {
  const idText = String(row[0] ?? '');
  if (idText.includes('OD-003')) return { effective: 'Rejected — FRD OD-003 is withdrawn; no requirement is admitted under this ID.', status: 'Rejected: explicit owner instruction', action: 'Reject' };
  if (/^O-15\b|OD-007\s*\(limits\)/.test(idText)) return { effective: String(row[8]), status: 'Decided: owner value', action: 'Override' };
  const action = String(row[7] ?? '').trim();
  const value = String(row[11] ?? '').trim();
  const final = String(row[12] ?? '').trim();
  if (value && !value.startsWith('#') && final && !final.startsWith('#')) return { effective: value, status: final, action };
  if (action === 'Defer') return { effective: '', status: 'Deferred: owner gate/date required', action };
  if (action === 'Reject') return { effective: 'Rejected by owner.', status: 'Rejected', action };
  if (action === 'Override' && row[8]) return { effective: String(row[8]), status: 'Decided: owner value', action };
  if (action === 'Confirm' && row[4]) return { effective: String(row[4]), status: 'Decided: proposed value', action };
  return { effective: value || String(row[4] ?? ''), status: final || 'Pending: workbook formula/value incomplete', action };
}

function renderDecisionTable(items, title = 'Workbook-authoritative decision integration') {
  const body = items.map(x => `<tr><td><code>${esc(x.ids.join(' / '))}</code></td><td>${esc(x.topic)}</td><td>${esc(x.effective || 'No effective value recorded')}</td><td>${esc(x.status)}</td><td>${esc(x.gate)}</td></tr>`).join('');
  return `<h3>${title}</h3><table class="niav-reconciliation-table"><thead><tr><th>ID(s)</th><th>Topic</th><th>Effective value</th><th>Final status</th><th>Gate</th></tr></thead><tbody>${body}</tbody></table>`;
}

function integrationSection(items, version) {
  const note = 'Source: NiAv_Decisions_Workbook_v0.1.xlsx Decisions sheet. Effective value and final status are authoritative for this reconciliation. Original history is retained; deferred and verification-dependent items are not represented as closed.';
  return `<section id="niav-workbook-reconciliation" data-generated-by="niav_reconcile_workbook.mjs"><h2>Workbook Reconciliation — ${esc(version)}</h2><p>${esc(note)}</p>${renderDecisionTable(items)}</section>`;
}

function appendLedger(html, items) {
  if (!items.length) return html;
  const table = renderDecisionTable(items, 'Workbook reconciliation status');
  if (html.includes('id="niav-closure-ledger"')) {
    return html.replace(/(<section id="niav-closure-ledger"[\s\S]*?<\/section>)/i, (section) => section.replace(/<h3>Workbook reconciliation status<\/h3><table[\s\S]*?<\/table>/i, '').replace(/<\/section>\s*$/i, table + '</section>'));
  }
  return html.replace(/<\/body>/i, `<section id="niav-closure-ledger" class="niav-linker-ledger"><h2>NiAv Cross-Document Closure Ledger</h2>${table}</section></body>`);
}

function replaceVersion(html, from, to) {
  let out = html.replaceAll(from, to);
  if (to === 'v0.3' && /NiAv UX Specification/i.test(out)) {
    out = out.replace(/(<title>NiAv UX Specification )v0\.1(<\/title>)/i, '$1v0.3$2');
    out = out.replace(/(Document ID:<\/strong>\s*NIAV-UX-SPEC\s*·\s*<strong>Version:<\/strong>\s*)v0\.1/i, '$1v0.3');
  }
  return out;
}

function injectBodyResolutions(html, items) {
  let out = html;
  for (const item of items) {
    if (!item.effective || item.status.startsWith('Deferred') || item.status.startsWith('Pending')) continue;
    const idPattern = item.matchIds.map(x => x.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')).join('|');
    const marker = `data-niav-applied="${item.ids[0]}"`;
    if (out.includes(marker)) continue;
    const statusText = item.status.startsWith('Rejected') ? 'Rejected' : item.status.startsWith('Deferred') ? 'Deferred' : 'Resolved';
    const callout = `<div class="niav-applied-resolution" ${marker}><strong>${statusText}:</strong> ${esc(item.effective)} <span class="niav-resolution-status">(${esc(item.status)})</span></div>`;
    const elementRe = new RegExp(`(<(?:tr|p|li)\\b[^>]*>[\\s\\S]*?(?:${idPattern})[\\s\\S]*?<\\/(?:tr|p|li)>)`, 'i');
    out = out.replace(elementRe, (block) => {
      let revised = block.replace(/>(Open|Blocked|TBD|TBC|Pending|Check:\s*name a gate)</gi, `>Superseded by workbook reconciliation: ${statusText}<`);
      if (/^<tr\b/i.test(revised)) {
        const cells = Math.max(1, (revised.match(/<t[dh]\b/gi) || []).length);
        return revised.replace(/<\/tr>\s*$/i, `<tr><td colspan="${cells}" class="niav-applied-resolution">${callout}</td></tr>`);
      }
      return revised.replace(new RegExp(`</(tr|p|li)>$`, 'i'), `${callout}</$1>`);
    });
  }
  return out;
}

function changelog(html, version, itemCount) {
  const row = `<tr data-generated-by="niav-reconcile-workbook"><td>${esc(version)}</td><td>${runDate}</td><td>Workbook reconciliation applied: ${itemCount} decision row(s) integrated into body text, closure status, and cross-document traceability; deferred/verification-dependent items remain explicitly non-closed.</td></tr>`;
  const match = html.match(/(<h2[^>]*>\s*Change log\s*<\/h2>[\s\S]*?<table[\s\S]*?<\/table>)/i);
  if (match) return html.replace(match[1], match[1].replace(/<tr data-generated-by="niav-reconcile-workbook">[\s\S]*?<\/tr>/gi, '').replace(/<\/table>\s*$/i, row + '</table>'));
  return html.replace(/<\/body>/i, `<section id="niav-reconciliation-change-log"><h2>Change log</h2><table><tr><th>Version</th><th>Date</th><th>Change</th></tr>${row}</table></section></body>`);
}

const workbook = await SpreadsheetFile.importXlsx(await FileBlob.load(workbookPath));
const sheet = workbook.worksheets.getItem('Decisions');
const values = sheet.getRange('A1:N51').values;
const decisions = values.slice(1).map(row => {
  const s = statusFor(row);
  const ids = idsFrom(row[0]);
  return { ids, matchIds: [...new Set([...ids, ...refsFrom(row[13])])], area: String(row[1] ?? ''), topic: String(row[2] ?? ''), gate: String(row[6] ?? ''), affected: String(row[13] ?? ''), proposed: String(row[4] ?? ''), digest: String(row[5] ?? ''), action: s.action, effective: s.effective, status: s.status };
});

await fs.mkdir(backupDir, { recursive: true });
const report = { source: workbookPath, date: runDate, documents: [], decisions: decisions.map(x => ({ ids: x.ids, status: x.status, effective: x.effective })) };
for (const [key, filename, fromVersion, toVersion] of docs) {
  const full = path.join(root, filename);
  let html = await fs.readFile(full, 'utf8');
  await fs.copyFile(full, path.join(backupDir, filename));
  const relevant = decisions.filter(d => /All ledgers/i.test(d.affected) || aliases.some(([alias, re]) => alias === key && re.test(d.affected)) || d.matchIds.some(id => new RegExp(`\\b${id.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}\\b`, 'i').test(html)));
  html = html.replace(/\s*<section id="niav-workbook-reconciliation"[\s\S]*?<\/section>\s*/gi, '\n');
  html = html.replace(/\s*<section id="niav-reconciliation-change-log"[\s\S]*?<\/section>\s*/gi, '\n');
  html = html.replace(/<tr[^>]*>\s*<td[^>]*class="niav-applied-resolution"[\s\S]*?<\/tr>/gi, '');
  html = html.replace(/<div class="niav-applied-resolution"[^>]*>[\s\S]*?<\/div>/gi, '');
  html = html.replace(/Superseded by workbook reconciliation: (Resolved|Rejected|Deferred)\/td>/gi, 'Superseded by workbook reconciliation: $1</td>');
  html = replaceVersion(html, fromVersion, toVersion);
  html = injectBodyResolutions(html, relevant);
  const section = integrationSection(relevant, toVersion);
  html = html.replace(/<body[^>]*>/i, match => `${match}${section}`);
  html = appendLedger(html, relevant);
  html = changelog(html, toVersion, relevant.length);
  await fs.writeFile(full, html, 'utf8');
  report.documents.push({ key, filename, fromVersion, toVersion, integratedRows: relevant.length, ids: [...new Set(relevant.flatMap(x => x.ids))] });
}
await fs.writeFile(reportPath, JSON.stringify(report, null, 2), 'utf8');
console.log(JSON.stringify({ reportPath, backupDir, documents: report.documents.length, decisions: decisions.length, integratedRows: report.documents.reduce((n, d) => n + d.integratedRows, 0) }, null, 2));
