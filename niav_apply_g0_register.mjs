import fs from 'node:fs/promises';
import path from 'node:path';
import { FileBlob, SpreadsheetFile } from 'file:///C:/Users/USER/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/@oai/artifact-tool/dist/artifact_tool.mjs';

const root = process.cwd();
const source = 'E:/NiavERP v2 OpenAI/outputs/01a0f1dd-b8a2-7ba3-9346-01abef17f993/NiAv_G0_Exception_Register_v0.1.xlsx';
const date = '2026-10-01';
const backupDir = path.join(root, 'niav_final_reconciliation_backups_20261001');

const docs = [
  ['REG','NiAv_ Modules & Sub-Modules Register v0.4.html','v0.5','v0.6'],['SEC','NiAv_ Security & Anti-Exploitation Plan (V1) v0.4.html','v0.5','v0.6'],['MPL','NiAv_ Universal Master Plan v0.2.html','v0.3','v0.4'],['ZCP','NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html','v0.6','v0.7'],['DSS','NiAv_Data_Schema_Specification_v0.1.html','v0.2','v0.3'],['DB','NiAv_Database_Schema_Document_v0.1.html','v0.2','v0.3'],['FGA','NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html','v0.2','v0.3'],['FDD','NiAv_Functional_Design_Document_v0.1.html','v0.2','v0.3'],['FRD','NiAv_Functional_Requirements_Input_Data_v0.1.html','v0.2','v0.3'],['RSP','NiAv_Release_and_Support_Playbook_v0.1.html','v0.2','v0.3'],['RTM','NiAv_Requirements_Traceability_Matrix_v0.1.html','v0.2','v0.3'],['SYNC','NiAv_Sync_Protocol_Specification_v0.1.html','v0.2','v0.3'],['TEST','NiAv_Test_Plan_and_Test_Data_Plan_v0.1.html','v0.2','v0.3'],['UIUX','NiAv_UI_UX_Specification_Document_v0.1.html','v0.2','v0.3'],['UX','NiAv_UX_Specification_v0.2.html','v0.3','v0.4']
];
const esc = v => String(v ?? '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
const ids = v => (String(v ?? '').match(/\b(?:O-[A-Z0-9-]+|OD-(?:FD|DB|UI)-\d+|D-[A-Z0-9-]+|A-[A-Z0-9-]+|R-[A-Z0-9-]+|WP-[A-Z0-9-]+|FR-[A-Z0-9-]+|RTM-O\d+|V-FG-\d+|G0-[A-Z]+-\d+)\b/gi) || []).map(x=>x.toUpperCase());
function outcome(row) {
  const id=row[0], category=row[1], gate=row[6], action=row[7], ownerValue=row[8], deferDate=row[9], notes=row[10], effective=row[11], final=row[12], affected=row[13], evidence=row[14];
  const cat=String(category||''), act=String(action||''), base=String(effective||'').trim(), fin=String(final||'').trim();
  if (cat === 'Deferred item') return { status:`Deferred — ${gate}${deferDate ? `; revisit ${deferDate}` : ''}`, effective:`Owner confirmed deferment: ${base || row[5]}` };
  if (cat === 'Verification evidence missing') return { status:'Evidence still required — owner confirmed action', effective:`Owner confirmed: ${base || row[5]}` };
  if (cat === 'Schema design gap') return { status:'Approved design change — implementation required', effective:`Approved: ${base || row[5]}` };
  if (act === 'Reject' || fin === 'Rejected') return { status:'Rejected', effective:base || ownerValue || 'Rejected by owner' };
  return { status:fin || (act ? 'Decided' : 'Pending'), effective:base || ownerValue || row[5] || '' };
}
function table(rows) { return `<table class="niav-g0-final-table"><thead><tr><th>Exception</th><th>Category</th><th>Source</th><th>Final status</th><th>Applied value/action</th><th>Gate</th><th>Owner notes</th></tr></thead><tbody>${rows.map(r=>`<tr><td><code>${esc(r.id)}</code></td><td>${esc(r.category)}</td><td>${esc(r.source)}</td><td>${esc(r.status)}</td><td>${esc(r.effective)}</td><td>${esc(r.gate)}</td><td>${esc(r.notes)}</td></tr>`).join('')}</tbody></table>`; }
function finalSection(rows, version) { return `<section id="niav-g0-final-reconciliation" data-generated-by="niav_apply_g0_register.mjs"><h2>G0 Final Reconciliation — ${esc(version)}</h2><p>Source: NiAv G0 Exception Register v0.1.xlsx, owner inputs applied on ${date}. Confirmed verification actions remain evidence-required; approved schema gaps remain implementation/design work. This section is authoritative for the current G0 disposition while prior history is retained.</p>${table(rows)}</section>`; }
function clean(html) { return html.replace(/\s*<section id="niav-g0-final-reconciliation"[\s\S]*?<\/section>\s*/gi,'\n').replace(/\s*<section id="niav-g0-final-change-log"[\s\S]*?<\/section>\s*/gi,'\n').replace(/<div class="niav-g0-applied"[^>]*>[\s\S]*?<\/div>/gi,''); }
function normalizeVersion(html, from, to) { let x=html.replaceAll(from,to); if(/NiAv UX Specification/i.test(x)&&to==='v0.4'){x=x.replace(/(<title>NiAv UX Specification )v0\.3(<\/title>)/i,'$1v0.4$2').replace(/(NIAV-UX-SPEC\s*·\s*<strong>Version:<\/strong>\s*)v0\.3/i,'$1v0.4')} return x; }
function injectCalls(html, rows) {
  let out=html;
  for(const r of rows){ if(!r.effective) continue; const pat=r.matchIds.map(x=>x.replace(/[.*+?^${}()|[\]\\]/g,'\\$&')).join('|'); const mark=`data-g0-applied="${r.id}"`; if(out.includes(mark)) continue; const call=`<div class="niav-g0-applied" ${mark}><strong>G0 ${esc(r.status)}:</strong> ${esc(r.effective)}</div>`; const re=new RegExp(`(<(?:p|li|tr)\\b[^>]*>[\\s\\S]*?(?:${pat})[\\s\\S]*?<\\/(?:p|li|tr)>)`,'i'); out=out.replace(re,b=>b.replace(new RegExp(`</(p|li|tr)>$`,'i'),`${call}</$1>`)); }
  return out;
}

await fs.mkdir(backupDir,{recursive:true});
const wb=await SpreadsheetFile.importXlsx(await FileBlob.load(source));
const vals=wb.worksheets.getItem('Exceptions').getRange('A1:O26').values;
const raw=vals.slice(1).map(row=>{ const o=outcome(row); const sourceIds=String(row[2]||''); const matchIds=[...new Set([...ids(row[0]),...ids(sourceIds),...ids(row[13])])]; return {id:String(row[0]),category:String(row[1]),source:sourceIds,topic:String(row[3]),effective:o.effective,status:o.status,gate:String(row[6]||''),notes:String(row[10]||''),affected:String(row[13]||''),matchIds}; });
const report={source,date,documents:[],rows:raw};
for(const [key,file,from,to] of docs){const full=path.join(root,file);let html=await fs.readFile(full,'utf8');await fs.copyFile(full,path.join(backupDir,file));html=clean(html);html=normalizeVersion(html,from,to);const relevant=raw.filter(r=>/All ledgers/i.test(r.affected)||r.affected.toUpperCase().includes(key)||r.matchIds.some(id=>new RegExp(`\\b${id.replace(/[.*+?^${}()|[\]\\]/g,'\\$&')}\\b`,'i').test(html)));html=injectCalls(html,relevant);html=html.replace(/<body[^>]*>/i,m=>m+finalSection(relevant,to));html=html.replace(/<\/body>/i,`<section id="niav-g0-final-change-log"><h2>Change log</h2><table><tr><th>Version</th><th>Date</th><th>Change</th></tr><tr><td>${to}</td><td>${date}</td><td>G0 exception register owner inputs applied; final reconciliation status recorded across ${relevant.length} linked exception rows.</td></tr></table></section></body>`);report.documents.push({key,file,version:to,rows:relevant.length});await fs.writeFile(full,html,'utf8');}
await fs.writeFile(path.join(root,'niav_final_reconciliation_report_20261001.json'),JSON.stringify(report,null,2),'utf8');
console.log(JSON.stringify({documents:report.documents.length,rows:raw.length,backupDir},null,2));
