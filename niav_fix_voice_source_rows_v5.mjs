import fs from 'node:fs/promises';
const files=['NiAv_ Modules & Sub-Modules Register v0.4.html','NiAv_ Zero-Cost Strategy Plan (V1) v0.5.html','NiAv_Release_and_Support_Playbook_v0.1.html','NiAv_Sync_Protocol_Specification_v0.1.html'];
for(const f of files){let h=await fs.readFile(f,'utf8');
 h=h.replaceAll('Voice-to-text for search and item entry (feasibility TBC)','Voice input rejected; no voice-to-text capability in V1');
 h=h.replaceAll('Voice input (M02.5): ⏭️','Voice input (M02.5): rejected; excluded from V1');
 h=h.replaceAll('<td>NIAV-FDD</td><td>Functional Design Document</td><td>v0.8</td>','<td>NIAV-FDD</td><td>Functional Design Document</td><td>v0.4</td>');
 h=h.replaceAll('<td>NIAV-DB</td><td>Database Schema Document</td><td>v0.6</td>','<td>NIAV-DB</td><td>Database Schema Document</td><td>v0.4</td>');
 h=h.replaceAll('<td>NIAV-UIUX</td><td>UI/UX Specification</td><td>v0.7</td>','<td>NIAV-UIUX</td><td>UI/UX Specification</td><td>v0.4</td>');
 await fs.writeFile(f,h,'utf8');}
console.log('voice and source rows repaired');
