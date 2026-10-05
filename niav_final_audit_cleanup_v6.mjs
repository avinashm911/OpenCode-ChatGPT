import fs from 'node:fs/promises'; import path from 'node:path';
const root=process.cwd(), date='2026-10-03';
const files={
 'NiAv_ Modules & Sub-Modules Register v0.4.html':['v0.9','v0.9'],
 'NiAv_ Universal Master Plan v0.2.html':['v0.7','v0.7'],
 'NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html':['v0.10','v0.10'],
 'NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html':['v0.6','v0.6'],
 'NiAv_Functional_Requirements_Input_Data_v0.1.html':['v0.6','v0.6'],
 'NiAv_Release_and_Support_Playbook_v0.1.html':['v0.6','v0.6'],
 'NiAv_Sync_Protocol_Specification_v0.1.html':['v0.6','v0.6'],
 'NiAv_UI_UX_Specification_Document_v0.1.html':['v0.5','v0.5'],
 'NiAv_UX_Specification_v0.2.html':['v0.6','v0.6']
};
const backup=path.join(root,'niav_final_audit_cleanup_v6_backups_20261003'); await fs.mkdir(backup,{recursive:true});
for(const [file,[ver]] of Object.entries(files)){
 const full=path.join(root,file); let h=await fs.readFile(full,'utf8'); await fs.copyFile(full,path.join(backup,file));
 if(file.includes('Fit-Gap')){
  h=h.replace('Local calculation/records and applicable file workflows are named, but schemas, source data and filing lifecycle are not specified.','TDS/TCS is deferred to a later release; no V1 implementation or file workflow is permitted.');
  h=h.replace('Limit V1 to verified file preparation/export/import backed by existing accounting data; do not build a full filing service.','Keep TDS/TCS out of V1; any later release requires owner-approved scope, official schemas and separate acceptance evidence.');
  h=h.replace('File preparation is contemplated where required payroll source data exists; a full payroll engine is out of scope unless separately confirmed.','PF/ESI and payroll are out of scope for V1; no statutory file-preparation workflow is permitted.');
  h=h.replace('Define source contract; if absent, keep workflow disabled; export only after schema verification.','Do not build in V1; any future release requires an owner-approved payroll source contract and official schemas.');
  h=h.replace('class="status">Gap / Verify</td><td>File preparation','class="status">Out of scope</td><td>File preparation');
 }
 h=h.replaceAll('<td>Rejected by owner; no R3 gate</td><td>R3</td>','<td>Rejected by owner; no R3 gate</td><td>n/a</td>');
 if(file.includes('Modules & Sub-Modules')){h=h.replace('Functional modules register (v0.8, living document)','Functional modules register (v0.9, living document)').replace('· v0.8 · Status:','· v0.9 · Status:');}
 if(file.includes('Universal Master Plan')) h=h.replace('· v0.6 · Status:','· v0.7 · Status:');
 if(file.includes('Zero-Cost')) h=h.replace('Living document, v0.9 (draft)','Living document, v0.10 (draft)');
 h=h.replace(/<h2>1\. Source baseline<\/h2>/g,'<h2>1. Source baseline (versions at authoring time)</h2>');
 const titles={
  'NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html':'NiAv Fit-Gap Analysis &amp; Workaround Register v0.6',
  'NiAv_Functional_Requirements_Input_Data_v0.1.html':'NiAv Functional Requirements — Input Data &amp; Data Entry Specification v0.6',
  'NiAv_Release_and_Support_Playbook_v0.1.html':'NiAv Release and Support Playbook v0.6',
  'NiAv_Sync_Protocol_Specification_v0.1.html':'NiAv Sync Protocol Specification v0.6',
  'NiAv_UX_Specification_v0.2.html':'NiAv UX Specification v0.6',
  'NiAv_UI_UX_Specification_Document_v0.1.html':'NiAv UI/UX Specification v0.5'
 };
 if(titles[file]) h=h.replace(/<title>[^<]*<\/title>/i,`<title>${titles[file]}</title>`);
 if(file.includes('Zero-Cost')) h=h.replace(/\s*<section id="niav-g0-final-audit-cleanup-v6"[\s\S]*?<\/section>\s*/gi,'');
 if(file.includes('Zero-Cost')) h=h.replace(/<body[^>]*>/i,m=>m+`<section id="niav-g0-final-audit-cleanup-v6"><h2>G0 Final Audit Cleanup — ${date}</h2><table><tr><th>Version</th><th>Date</th><th>Change</th></tr><tr><td>v0.10</td><td>${date}</td><td>Aligned document status with the v0.10 change log and confirmed voice input rejected for V1.</td></tr></table></section>`);
 await fs.writeFile(full,h,'utf8');
}
console.log(JSON.stringify({updated:Object.keys(files).length,backup},null,2));
