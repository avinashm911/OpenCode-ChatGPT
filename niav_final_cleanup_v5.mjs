import fs from 'node:fs/promises'; import path from 'node:path';
const root=process.cwd(), date='2026-10-03';
const versions={
 'NiAv_ Modules & Sub-Modules Register v0.4.html':['v0.8','v0.9'],
 'NiAv_ Universal Master Plan v0.2.html':['v0.6','v0.7'],
 'NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html':['v0.9','v0.10'],
 'NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html':['v0.5','v0.6'],
 'NiAv_Functional_Requirements_Input_Data_v0.1.html':['v0.5','v0.6'],
 'NiAv_Release_and_Support_Playbook_v0.1.html':['v0.5','v0.6'],
 'NiAv_Sync_Protocol_Specification_v0.1.html':['v0.5','v0.6'],
 'NiAv_UI_UX_Specification_Document_v0.1.html':['v0.4','v0.5'],
 'NiAv_UX_Specification_v0.2.html':['v0.5','v0.6']
};
const backup=path.join(root,'niav_final_cleanup_v5_backups_20261003'); await fs.mkdir(backup,{recursive:true});
for(const [file,[from,to]] of Object.entries(versions)){
 const full=path.join(root,file); let h=await fs.readFile(full,'utf8'); await fs.copyFile(full,path.join(backup,file));
 if(file.includes('Functional_Requirements')){
  h=h.replaceAll('Voice input feasibility and privacy/performance requirements','Voice input is rejected; no V1 voice capability or voice privacy/performance requirement');
  h=h.replaceAll('No final acceptance criteria for voice input.','Voice input is rejected; no acceptance criteria or implementation in V1.');
  h=h.replaceAll('Conditional on feasibility; currently deferred.','Rejected; excluded from V1.');
 }
 if(file.includes('Modules & Sub-Modules')) h=h.replaceAll('voice input, TDS/TCS, PF/ESI/payroll and direct native-file import are excluded or deferred; advanced analytics','TDS/TCS, PF/ESI/payroll and direct native-file import are excluded or deferred; voice input is rejected; advanced analytics');
 if(file.includes('Universal Master Plan')) h=h.replaceAll('voice input — rejected; excluded from V1, direct native-file import feasibility','direct native-file import feasibility (R3 only)');
 if(file.includes('UI_UX')) h=h.replaceAll('Exact navigation grouping remains subject to owner review; module scope comes from REG.','Module scope comes from REG; the owner-approved five-item navigation model is authoritative.');
 if(file.includes('Functional_Requirements')||file.includes('UI_UX')||file.includes('UX_Specification')) h=h.replaceAll('<td>No effective value recorded</td>','<td>Rejected by owner; no R3 gate</td>');
 h=h.replaceAll('<h2>1. Source baseline</h2>','<h2>1. Source baseline (versions at authoring time)</h2>');
 h=h.replaceAll(`<h2>G0 Final Reconciliation — ${from}</h2>`,`<h2>G0 Final Reconciliation — ${to}</h2>`).replaceAll(`<h2>Workbook Reconciliation — ${from}</h2>`,`<h2>Workbook Reconciliation — ${to}</h2>`);
 if(file.includes('Universal Master Plan')) h=h.replaceAll('<strong>Version:</strong> 0.2 (draft)','<strong>Version:</strong> 0.7 (draft)');
 if(file.includes('Fit-Gap')) h=h.replaceAll('<strong>Version:</strong> v0.5','<strong>Version:</strong> v0.6');
 if(file.includes('Functional_Requirements')) h=h.replaceAll('<strong>Version:</strong> v0.5','<strong>Version:</strong> v0.6');
 if(file.includes('Release')) h=h.replaceAll('<strong>Version:</strong> v0.5','<strong>Version:</strong> v0.6');
 if(file.includes('Sync')) h=h.replaceAll('<strong>Version:</strong> v0.5','<strong>Version:</strong> v0.6');
 if(file.includes('UI_UX')) h=h.replaceAll('<strong>Version:</strong> v0.4','<strong>Version:</strong> v0.5');
 if(file.includes('UX_Specification')) h=h.replaceAll('<strong>Version:</strong> v0.5','<strong>Version:</strong> v0.6');
 if(file.includes('Zero-Cost')) h=h.replaceAll('· v0.9 · Status:','· v0.10 · Status:');
 h=h.replace(/\s*<section id="niav-g0-final-cleanup-v5"[\s\S]*?<\/section>\s*/gi,'');
 const extra=`<section id="niav-g0-final-cleanup-v5"><h2>G0 Final Cleanup — ${date}</h2><p>Voice input is rejected for V1. The owner-approved navigation model is Home, Billing, Parties &amp; Items, Reports, More. Source-baseline tables are frozen snapshots of versions at authoring time.</p><table><tr><th>Version</th><th>Date</th><th>Change</th></tr><tr><td>${to}</td><td>${date}</td><td>Final voice/navigation cleanup, header alignment and source-baseline snapshot clarification.</td></tr></table></section>`;
 h=h.replace(/<body[^>]*>/i,m=>m+extra); await fs.writeFile(full,h,'utf8');
}
console.log(JSON.stringify({updated:Object.keys(versions).length,backup},null,2));
