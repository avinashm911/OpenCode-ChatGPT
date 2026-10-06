import fs from 'node:fs/promises'; import path from 'node:path';
const root=process.cwd(), date='2026-10-03';
const targets={
 'NiAv_UI_UX_Specification_Document_v0.1.html':['v0.4','v0.5'],
 'NiAv_UX_Specification_v0.2.html':['v0.5','v0.6'],
 'NiAv_Release_and_Support_Playbook_v0.1.html':['v0.5','v0.6'],
 'NiAv_Sync_Protocol_Specification_v0.1.html':['v0.5','v0.6'],
 'NiAv_Functional_Requirements_Input_Data_v0.1.html':['v0.5','v0.6'],
 'NiAv_Fit-Gap_Analysis_Workaround_Register_v0.1.html':['v0.5','v0.6'],
 'NiAv_ Modules & Sub-Modules Register v0.4.html':['v0.8','v0.9'],
 'NiAv_ Universal Master Plan v0.2.html':['v0.6','v0.7']
};
const backup=path.join(root,'niav_nav_voice_refs_v3_backups_20261003'); await fs.mkdir(backup,{recursive:true});
function baseline(h){
 const versions={REG:'v0.8',MPL:'v0.6',ZCP:'v0.9',SEC:'v0.7',FGA:'v0.5',FRD:'v0.5',FDD:'v0.4',DB:'v0.4',UIUX:'v0.4'};
 for(const [id,v] of Object.entries(versions)) h=h.replace(new RegExp(`(<td>NIAV-${id}(?:-INPUT)?<\\/td>[\\s\\S]*?<td>)v0\\.5(<\\/td>)`,'i'),`$1${v}$2`);
 h=h.replace(/(<td>NIAV-REG<\/td>[\s\S]*?<td>)v0\.4(<\/td>)/i,'$1v0.8$2').replace(/(<td>NIAV-MPL<\/td>[\s\S]*?<td>)v0\.4(<\/td>)/i,'$1v0.6$2').replace(/(<td>NIAV-SEC<\/td>[\s\S]*?<td>)v0\.4(<\/td>)/i,'$1v0.7$2').replace(/(<td>NIAV-FGA<\/td>[\s\S]*?<td>)v0\.4(<\/td>)/i,'$1v0.5$2');
 return h;
}
for(const [file,[from,to]] of Object.entries(targets)){
 const full=path.join(root,file); let h=await fs.readFile(full,'utf8'); await fs.copyFile(full,path.join(backup,file));
 if(file.includes('UI_UX_Specification')){
  h=h.replace(/<pre>Dashboard[\s\S]*?<\/pre>/i,'<pre>Home\n├─ Billing\n├─ Parties &amp; Items\n├─ Reports\n└─ More\n   ├─ GST/Statutory\n   ├─ Import/Migration\n   ├─ Users/Admin\n   ├─ Backup/Sync\n   ├─ Licence\n   └─ Settings/Help</pre>');
  h=h.replace('Define voice entry affordance only if feasibility is accepted.','Voice input is rejected; no voice-entry affordance in V1.');
 }
 if(file.includes('UX_Specification_v0.2')){
  h=h.replace(/<pre>Home[\s\S]*?<\/pre>/i,'<pre>Home\n ├─ Billing → New Bill / Vouchers → Payment → Preview/Print/Share → Posted\n ├─ Parties &amp; Items → Search → Master Form → Save\n ├─ Reports → Filter → Report → Export/Print\n └─ More → Import/Migration | GST/Statutory | Backup/Sync | Users | Licence | Help</pre>');
  h=h.replace('Conditional; do not present as guaranteed capability.','Rejected; do not present voice capability in V1.');
 }
 if(file.includes('Functional_Requirements')){h=h.replace(/shall optionally support voice-to-text only if the feasibility item is accepted/gi,'shall not support voice-to-text in V1; voice input is rejected');h=h.replace(/Voice input action where enabled/gi,'No voice input action in V1');h=h.replace(/Voice input \(M02\.5\):/gi,'Voice input (M02.5) rejected:');}
 if(file.includes('Universal Master Plan')){h=h.replace(/voice input/g,'voice input — rejected; excluded from V1');}
 if(file.includes('Modules & Sub-Modules')){h=h.replace('Vouchers from Tally/Busy exports mapped to the NiAv template','Excel exports from Tally/Busy mapped to the NiAv template');}
 if(file.includes('UI_UX')||file.includes('UX_Specification')){h=h.replace(/Define voice entry affordance only if feasibility is accepted\./gi,'Voice input is rejected; no voice-entry affordance in V1.').replace(/Conditional; do not present as guaranteed capability\./gi,'Rejected; do not present voice capability in V1.');}
 if(file.includes('Fit-Gap')||file.includes('Functional_Requirements')||file.includes('Release')||file.includes('Sync')) h=baseline(h);
 if(file.includes('Universal Master Plan')) h=h.replace('Initial master plan integrating REG v0.5, ZCP v0.5, SEC v0.5','Initial master plan integrating REG v0.4, ZCP v0.4, SEC v0.4');
 if(file.includes('Fit-Gap')) h=h.replace('Initial fit/gap register created from NIAV-REG v0.5, NIAV-MPL v0.5, NIAV-ZCP v0.5 and NIAV-SEC v0.5','Initial fit/gap register created from NIAV-REG v0.4, NIAV-MPL v0.3, NIAV-ZCP v0.5 and NIAV-SEC v0.4').replace('adapter-per-format native import is R3 feasibility only..','adapter-per-format native import is R3 feasibility only.');
 if(file.includes('Functional_Requirements')) h=h.replace('REG v0.5; MPL v0.5; ZCP v0.5; SEC v0.5; FGA v0.5','REG v0.4; MPL v0.3; ZCP v0.5; SEC v0.4; FGA v0.3');
 if(file.includes('Release')||file.includes('Sync')){h=h.replace(/<td>NIAV-REG<\/td><td>[\s\S]*?<td>v0\.5<\/td>/i,'<td>NIAV-REG</td><td>Modules &amp; Sub-Modules Register</td><td>v0.8</td>').replace(/<td>NIAV-MPL<\/td><td>[\s\S]*?<td>v0\.5<\/td>/i,'<td>NIAV-MPL</td><td>Universal Master Plan</td><td>v0.6</td>').replace(/<td>NIAV-SEC<\/td><td>[\s\S]*?<td>v0\.5<\/td>/i,'<td>NIAV-SEC</td><td>Security &amp; Anti-Exploitation Plan</td><td>v0.7</td>').replace(/<td>NIAV-FGA<\/td><td>[\s\S]*?<td>v0\.5<\/td>/i,'<td>NIAV-FGA</td><td>Fit-Gap Analysis &amp; Workaround Register</td><td>v0.5</td>').replace(/<td>NIAV-FRD(?:-INPUT)?<\/td><td>[\s\S]*?<td>v0\.5<\/td>/i,'<td>NIAV-FRD</td><td>Functional Requirements — Input Data &amp; Data Entry</td><td>v0.5</td>');}
 h=h.replace(/\s*<section id="niav-g0-nav-voice-v3"[\s\S]*?<\/section>\s*/gi,'');
 const log=`<section id="niav-g0-nav-voice-v3"><h2>G0 Navigation and Voice Correction — ${date}</h2><p>Navigation is Home, Billing, Parties &amp; Items, Reports, More. Voice input is rejected and is not a V1 capability or conditional UI affordance. Source-baseline references and historical rows were repaired without global version replacement.</p><table><tr><th>Version</th><th>Date</th><th>Change</th></tr><tr><td>${to}</td><td>${date}</td><td>Corrected navigation variants, rejected voice-input wording and affected cross-document version references.</td></tr></table></section>`;
 h=h.replace(/<body[^>]*>/i,m=>m+log); await fs.writeFile(full,h,'utf8');
}
console.log(JSON.stringify({updated:Object.keys(targets).length,backup},null,2));
