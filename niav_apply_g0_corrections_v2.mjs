import fs from 'node:fs/promises'; import path from 'node:path';
const root=process.cwd(), date='2026-10-03';
const files={
 'NiAv_ Modules & Sub-Modules Register v0.4.html':['v0.7','v0.8'],
 'NiAv_ Universal Master Plan v0.2.html':['v0.5','v0.6'],
 'NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html':['v0.8','v0.9'],
 'NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html':['v0.4','v0.5'],
 'NiAv_Functional_Requirements_Input_Data_v0.1.html':['v0.4','v0.5'],
 'NiAv_Release_and_Support_Playbook_v0.1.html':['v0.4','v0.5'],
 'NiAv_Sync_Protocol_Specification_v0.1.html':['v0.4','v0.5']
};
const backup=path.join(root,'niav_g0_correction_v2_backups_20261003'); await fs.mkdir(backup,{recursive:true});
const repl={
 'NiAv_ Modules & Sub-Modules Register v0.4.html':[
  ['<td>M02.5 Voice input</td>','<td>M02.5 Voice input — rejected; not in V1</td>'],
  ['<td>P1</td><td>Feasibility TBC</td>','<td>Rejected</td><td>Excluded from V1; no implementation</td>'],
  ['TDS/TCS/PF/ESI statutory files','TDS/TCS deferred; PF/ESI and payroll out of scope'],
  ['TDS/TCS, voice input, direct native-file import (if feasible), advanced analytics','voice input, TDS/TCS, PF/ESI/payroll and direct native-file import are excluded or deferred; advanced analytics'],
  ['Expanded zero-cost file/user-mediated workflows: bank statement import, government JSON workflows and response import, Tally/Busy native import feasibility, TDS/TCS/PF/ESI statutory files','Expanded zero-cost file/user-mediated workflows: bank statement import, government JSON workflows and response import; Tally/Busy native import is R3 feasibility only; TDS/TCS is deferred and PF/ESI/payroll are out of scope']
 ],
 'NiAv_ Universal Master Plan v0.2.html':[
  ['direct Tally/Busy native-file import for validated formats, and applicable TDS/TCS/PF/ESI statutory files','Tally/Busy native import is R3 feasibility only; TDS/TCS is deferred to a later release; PF/ESI and payroll are out of scope'],
  ['Voice input','Voice input — rejected for V1'],
  ['M02.5','M02.5 — rejected for V1']
 ],
 'NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html':[
  ['GST calculation + reports + Excel/JSON export ✅ <strong>[VERIFY formats]</strong>. E-invoice/e-way/TDS/TCS deferred; PF/ESI and payroll out of scope file workflows: targeted via local export + user-mediated submission + response import where formats are verified; direct APIs remain ⏭️','GST calculation + reports + Excel/JSON export ✅ <strong>[VERIFY formats]</strong>. E-invoice/e-way remain R3/G3; TDS/TCS is deferred to a later release; PF/ESI and payroll are out of scope. No direct statutory APIs in V1.'],
  ['Excel templates, validation, error report, import batch rollback, plus validated direct Tally/Busy native-file import paths. Unsupported versions/formats remain ⏭️','Excel templates, validation, error report, import batch rollback and reconciliation. Tally/Busy native-file import is R3 feasibility only; unsupported versions/formats remain excluded.'],
  ['In addition, investigate and, for validated formats, implement <strong>direct Tally/Busy native-file import</strong> without requiring an intermediate spreadsheet. Coverage is version/file-format specific and must be gated on representative sample files and reconciliation tests <strong>[VERIFY]</strong>.','Native Tally/Busy import is not a V1 implementation. Record it only as an R3 feasibility study requiring representative files and reconciliation tests.'],
  ['<strong>TDS/TCS:</strong> support local calculation/records and applicable statutory file export/import workflows; exact schemas and filing rules require official-source verification.','<strong>TDS/TCS:</strong> deferred to a later release; excluded from V1 implementation and acceptance.'],
  ['<strong>PF/ESI:</strong> support statutory file preparation/export where required source payroll data exists; a full payroll engine remains out of scope unless separately confirmed.','<strong>PF/ESI and payroll:</strong> out of scope for V1.'],
  ['TDS/TCS deferred; PF/ESI and payroll out of scope file workflows','TDS/TCS deferred; PF/ESI and payroll out of scope'],
  ['validated direct Tally/Busy native-file import paths','R3 feasibility study for Tally/Busy native-file import']
 ],
 'NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html':[
  ['Adapter-per-format, Excel fallback, reconciliation.','Excel-template mapping and reconciliation for V1; native adapters are R3 feasibility only.'],
  ['E-invoice, e-way, TDS/TCS and PF/ESI file workflows are named but verification-dependent.','E-invoice/e-way are R3/G3; TDS/TCS is later release; PF/ESI and payroll are out of V1 scope.'],
  ['Government File Adapter Specification:</strong> shared engine plus GST/e-invoice/e-way/TDS/TCS/PF/ESI adapter contracts.','Government file boundary:</strong> GST return JSON remains R1a; e-invoice/e-way are R3/G3; TDS/TCS later release; PF/ESI/payroll out of scope.'],
  ['Migration Adapter Specification:</strong> Excel plus Tally/Busy native-format adapters and reconciliation.','Migration Adapter Specification:</strong> Excel templates and reconciliation in V1; Tally/Busy native-format adapters are R3 feasibility only.'],
  ['Adapter-per-format with universal Excel mapping fallback','Excel-template mapping and reconciliation; adapter-per-format native import is R3 feasibility only.'],
  ['Tally/Busy native-format adapters','Tally/Busy native-format adapters (R3 feasibility only)']
 ],
 'NiAv_Functional_Requirements_Input_Data_v0.1.html':[
  ['shall map source Tally/Busy exports into NiAv templates','shall map approved Excel templates populated from Tally/Busy exports into NiAv'],
  ['FG-006 Tally/Busy native formats (R3 feasibility only) import','FG-006 Tally/Busy native formats — R3 feasibility only; no V1 import'],
  ['Tally/Busy native formats (R3 feasibility only) import','Tally/Busy native formats — R3 feasibility only; no V1 import'],
  ['targets e-invoice/e-way/TDS/TCS/PF/ESI workflows','covers GST return JSON in R1a; e-invoice/e-way are R3/G3; TDS/TCS later release; PF/ESI/payroll out of scope'],
  ['Voice input (M02.5):','Voice input (M02.5) rejected:']
 ],
 'NiAv_Release_and_Support_Playbook_v0.1.html':[
  ["Replace 'rollback to previous APK' with: uninstall, install previous APK, restore external backup.","Approved rollback: uninstall the current APK, install the previous APK, then restore the external backup; in-place downgrade is not supported."],
  ['Rollback to previous supported APK + restore backup if required.','Uninstall the current APK, install the previous APK, then restore the external backup; in-place downgrade is not supported.'],
  ['Replace \'uninstall current APK, install previous APK…\' with: uninstall, install previous APK…','Approved rollback procedure is uninstall current APK, install previous APK, then restore external backup.']
 ],
 'NiAv_Sync_Protocol_Specification_v0.1.html':[
  ['Last-writer-wins may be used with audit history, subject to final implementation tests.','Field-by-field merge; on a same-field clash, host arrival wins and the loser is logged.'],
  ['last-writer-wins','field merge; host arrival wins on a same-field clash and the loser is logged']
 ]
};
const logSection=(ver,change)=>`<section id="niav-g0-correction-v2"><h2>G0 Correction Update — ${date}</h2><p>Active body text corrected after the independent audit. Historical records are retained as history; the active requirements are the corrected statements.</p><table><tr><th>Version</th><th>Date</th><th>Change</th></tr><tr><td>${ver}</td><td>${date}</td><td>${change}</td></tr></table></section>`;
for(const [file,[from,to]] of Object.entries(files)){const full=path.join(root,file);let h=await fs.readFile(full,'utf8');await fs.copyFile(full,path.join(backup,file));for(const [a,b] of (repl[file]||[]))h=h.split(a).join(b);h=h.replace(/\s*<section id="niav-g0-correction-v2"[\s\S]*?<\/section>\s*/gi,'');h=h.replaceAll(from,to);h=h.replace(/<body[^>]*>/i,m=>m+logSection(to,'Corrected audited body-text residue for G0-CON-001 through G0-CON-005; corrected voice-input rejection and added explicit active change log.'));await fs.writeFile(full,h,'utf8');}
console.log(JSON.stringify({updated:Object.keys(files).length,backup},null,2));
