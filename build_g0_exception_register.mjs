import fs from 'node:fs/promises';
import { Workbook, SpreadsheetFile } from 'file:///C:/Users/USER/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/@oai/artifact-tool/dist/artifact_tool.mjs';

const outputDir = 'E:/NiavERP v2 OpenAI/outputs/01a0f1dd-b8a2-7ba3-9346-01abef17f993';
await fs.mkdir(outputDir, { recursive: true });

const rows = [
  ['G0-OWN-001','Owner action required','D-12','Single APK vs flavours','D-12 remains Pending in the workbook; SEC still contains the decision boundary.','Confirm single APK with runtime edition gating, or override with the approved flavour model.','G5','','','','','', '', 'SEC §16; workbook Decisions row D-12','Owner decision recorded in workbook and reflected in SEC/REG/RTM.'],
  ['G0-OWN-002','Owner action required','OD-UI-003 / FR-M02-002','Voice input feasibility','Workbook marks this item Deferred, but no revisit gate/date is entered.','Name the revisit gate/date or reject the capability for the relevant release.','R3','','','','','', '', 'FRD; UIUX; UX','Gate/date must be explicit before G0 acceptance.'],
  ['G0-DEF-001','Deferred item','O-FG-006 / A-FG-006 / O-13','Tally/Busy native adapters','Excel import is V1/R2; native adapters are deferred to R3 feasibility.','Confirm the R3 feasibility gate and evidence required.','R3','','','','','', '', 'FGA; FDD; FRD; REG','Representative files and feasibility result.'],
  ['G0-DEF-002','Deferred item','O-FG-007 / O-FG-008','TDS/TCS and PF/ESI','TDS/TCS is deferred; PF/ESI and payroll are out of V1 scope.','Confirm the later-release gate for TDS/TCS and removal from V1 traceability.','Later release','','','','','', '', 'REG; MPL; ZCP; FRD; RTM','Updated scope and RTM rows.'],
  ['G0-DEF-003','Deferred item','O-M08','Automatic cross-script transliteration','Native-script, Latin search and aliases are V1; automatic transliteration is deferred to R2.','Confirm the R2 gate and keep automatic transliteration out of V1 acceptance criteria.','R2','','','','','', '', 'MPL; UX','R2 backlog item and V1 acceptance wording.'],
  ['G0-VER-001','Verification evidence missing','V-FG-001 / D-06','Encrypted SQLite library for Drift on Android 8+','Verification sheet says Ok with source “owner”; no official licence/library evidence is recorded.','Attach official library/version/licence and Android 8 compatibility evidence.','G0','','','','','', '', 'ZCP; SEC; FGA','Official source URL, version, licence, compatibility result.'],
  ['G0-VER-002','Verification evidence missing','GST rounding / D-M4','GST rounding rules','Verification sheet says Ok with source “owner”; no official rule or golden fixture is recorded.','Attach the rule source and a passing golden rounding fixture.','G0','','','','','', '', 'MPL; DSS; DB; TEST','Source citation plus fixture/result.'],
  ['G0-VER-003','Verification evidence missing','V-FG-001 / O-FG-002/O-FG-003','GST, e-invoice and e-way schemas','Verification sheet says Ok, but no official schemas/response contracts are recorded.','Attach official schema/version evidence and update verification logs.','G3','','','','','', '', 'FGA; REG; ZCP; TEST','Official schema files/URLs and adapter test result.'],
  ['G0-VER-004','Verification evidence missing','R-04','WhatsApp/email APK delivery limits','Verification sheet says Ok with source “owner”; no platform limit evidence or attachment test is recorded.','Attach channel limits and a successful APK/ZIP/checksum delivery test.','G5','','','','','', '', 'ZCP; RSP; FGA','Test capture and checksum evidence.'],
  ['G0-VER-005','Verification evidence missing','D-06 / SEC §5','Android Keystore behaviour on Android 8','Verification sheet says Ok with source “owner”; no device test evidence is recorded.','Attach Android 8 Keystore test result and key-wrap behaviour.','G0','','','','','', '', 'SEC; ZCP; TEST','Device/version test record.'],
  ['G0-VER-006','Verification evidence missing','O-M07 / OD-008','Printer compatibility','Verification sheet says Ok; no three-printer compatibility results are recorded.','Attach results for the supported ESC/POS/PDF printer matrix.','G5','','','','','', '', 'REG; FRD; TEST; UIUX','Three-printer test evidence.'],
  ['G0-VER-007','Verification evidence missing','O-14 / R-13','Indian data-protection obligations','Verification sheet says Ok; no official legal/source record is recorded.','Attach the reviewed source and the resulting local-only/minimal-collection control mapping.','G5','','','','','', '', 'ZCP; REG; SEC','Source and control decision record.'],
  ['G0-VER-008','Verification evidence missing','V-FG-003','Android file-provider/share/restore','Verification sheet says Ok; no target-version restore/share evidence is recorded.','Attach target Android test results for backup, restore, share and file-provider behaviour.','G5','','','','','', '', 'FGA; SEC; RSP; TEST','Target-version test record.'],
  ['G0-CON-001','Body contradiction','O-FG-007 / O-FG-008','Statutory scope wording','MPL/ZCP/FRD historical body text still mentions TDS/TCS/PF/ESI as V1-scope material alongside the workbook rule.','Make V1 text authoritative: TDS/TCS later release; PF/ESI/payroll out of scope.','G0','','','','','', '', 'MPL; ZCP; REG; FRD; RTM','Body text and RTM agree.'],
  ['G0-CON-002','Body contradiction','O-FG-006 / A-FG-006','Tally/Busy import wording','Historical body text still promises native-file import while the workbook sets Excel-only V1/R2 and native adapters to R3 feasibility.','Replace V1 native-import promise with the Excel-template boundary.','G0','','','','','', '', 'REG; FDD; FRD; FGA; RTM','No native-file import promise remains in V1 text.'],
  ['G0-CON-003','Body contradiction','RSP 5 / DSS-C-007','Rollback procedure','Rollback language appears in more than one form; the authoritative procedure is uninstall, install previous APK, then restore external backup.','Retain one authoritative rollback procedure and cross-link all references.','G5','','','','','', '', 'RSP; DSS; TEST','Consistent rollback text and recovery test.'],
  ['G0-CON-004','Body contradiction','SYNC 6 / OD-DB-006','Master-data conflict rule','Historical sync text contains both last-writer-wins and conflict-queue wording; the workbook rule is field merge, host arrival wins on same-field clash, loser logged.','Rewrite the body rule once and remove the contradictory alternative.','S1','','','','','', '', 'SYNC; DSS; DB; UX','One conflict rule across sync/schema/UX.'],
  ['G0-CON-005','Body contradiction','OD-UI-001','Navigation hierarchy','MPL, UIUX and UX contain different navigation variants; workbook selects Home, Billing, Parties & Items, Reports, More.','Retire the superseded navigation variants in body sections and keep one five-item model.','G0','','','','','', '', 'MPL; UIUX; UX; RTM; TEST','One navigation model in body and acceptance criteria.'],
  ['G0-SCH-001','Schema design gap','D-M5 / D-08 / OD-DB-002','FIFO cost layers and negative-stock costing','Workbook decides FIFO/weighted average and negative-stock handling, but schema baseline does not clearly model cost layers and stock movements.','Add cost-layer and stock-movement structures plus negative-stock costing/reconciliation rules.','G1','','','','','', '', 'DB; DSS; FRD; TEST','Schema delta and golden ledger fixtures.'],
  ['G0-SCH-002','Schema design gap','D-M5','Period locks','Workbook requires date-based period locks with authorised unlock, reason and audit; no complete period-lock entity/flow is visible in the baseline.','Add period-lock entity, rights, unlock reason and audit linkage.','G1','','','','','', '', 'DB; DSS; FDD; UIUX; TEST','Schema and permission/UX acceptance criteria.'],
  ['G0-SCH-003','Schema design gap','FR-M06','Bill-wise settlement','Functional requirements require bill allocation, but the schema baseline does not clearly expose bill_allocation.','Add bill_allocation and settlement lineage fields and tests.','G1','','','','','', '', 'DB; DSS; FRD; TEST','Schema and reconciliation fixture.'],
  ['G0-SCH-004','Schema design gap','MPL 7.4 / profiles','Tax, HSN and layout profiles','Tax-rate/HSN and layout-profile data are referenced by body requirements but are not clearly complete in the baseline schema.','Add effective-dated tax/HSN and synced/backed-up layout-profile structures.','G1','','','','','', '', 'DB; DSS; MPL; FRD; UIUX','Schema, migration and backup coverage.'],
  ['G0-SCH-005','Schema design gap','SYNC 3/6','Record and operation versioning','Sync requires base_version/dependencies and per-record versioning; the baseline does not consistently carry both across operation/entity structures.','Add record version, operation.base_version and operation.dependencies consistently.','S1','','','','','', '', 'DB; DSS; SYNC; TEST','Conflict/replay migration and tests.'],
  ['G0-SCH-006','Schema design gap','SEC licence controls','Trial anchor and denylist storage','Security requirements reference trial-anchor and denylist state, but the schema baseline does not clearly model both.','Add storage and lifecycle rules for trial anchor, denylist and audit evidence.','G0','','','','','', '', 'DB; DSS; SEC; TEST','Threat model, schema and negative tests.'],
  ['G0-SCH-007','Schema design gap','FRD voucher lines','Voucher-line discount','FRD/DB/UX reference voucher_line.discount, but the physical schema baseline does not clearly include it.','Add discount fields, calculation rules and golden voucher tests.','G1','','','','','', '', 'DB; DSS; FRD; UX; TEST','Schema and calculation fixture.'],
];

const wb = Workbook.create();
const instructions = wb.worksheets.add('Instructions');
instructions.getRange('A1:B10').values = [
  ['NiAv G0 Exception Register v0.1', null],
  ['Purpose', 'Short acceptance register for exceptions remaining after the 15-document workbook reconciliation.'],
  ['How to use', 'Edit only the yellow Owner action, Owner value, Gate/date if Deferred and Owner notes columns on Exceptions.'],
  ['Owner action', 'Choose Confirm, Override, Defer or Reject. Confirm accepts the Required resolution. Override requires Owner value. Defer requires a gate/date. Reject records rejection.'],
  ['Scope', 'This register contains only owner actions, deferred items, missing verification evidence, body contradictions and schema design gaps.'],
  ['Evidence rule', 'Do not mark verification complete without an official source, test record, fixture, or other named evidence.'],
  ['G0 acceptance', 'G0 is accepted only when owner-action rows are resolved, deferred rows have a gate/date, verification rows have evidence, contradictions are reconciled and schema gaps have approved changes.'],
  ['Source baseline', 'NiAv_Decisions_Workbook_v0.1.xlsx plus the 15 reconciled HTML documents, reviewed 2026-10-01.'],
  ['Workbook handoff', 'Return this workbook after entering proposed changes. The resulting values will be applied to the 15 documents in the next reconciliation pass.'],
  ['Important', 'Original decisions workbook is not modified by this register.'],
];

const summary = wb.worksheets.add('Summary');
summary.getRange('A1:B10').values = [
  ['G0 reconciliation summary', null],
  ['Total exceptions', null], ['Owner action required', null], ['Deferred items', null], ['Verification evidence missing', null], ['Body contradictions', null], ['Schema design gaps', null], ['Resolved in this register', null], ['Still pending', null], ['G0 recommendation', 'Do not accept G0 until owner actions, evidence and schema/body exceptions are dispositioned.'],
];

const ex = wb.worksheets.add('Exceptions');
ex.getRange('A1:O1').values = [['Exception ID','Category','Source ID(s)','Topic','Current exception / evidence','Required resolution','Gate','Owner action','Owner value (if Override)','Gate / date if Deferred','Owner notes','Effective value','Final status','Affected documents','Expected evidence / acceptance']];
ex.getRangeByIndexes(1,0,rows.length,15).values = rows;

const end = rows.length + 1;
for (let r=2; r<=end; r++) {
  ex.getRange(`L${r}`).formulas = [[`=IF(H${r}="Confirm",F${r},IF(H${r}="Override",I${r},IF(H${r}="Defer","Deferred: "&J${r},IF(H${r}="Reject","Rejected",""))))`]];
  ex.getRange(`M${r}`).formulas = [[`=IF(H${r}="","Pending owner action",IF(H${r}="Defer","Deferred",IF(H${r}="Reject","Rejected",IF(OR(H${r}="Confirm",H${r}="Override"),"Decided","Pending"))))`]];
}
summary.getRange('B2:B9').formulas = [
  [`=COUNTA(Exceptions!A2:A${end})`], [`=COUNTIF(Exceptions!B2:B${end},"Owner action required")`], [`=COUNTIF(Exceptions!B2:B${end},"Deferred item")`], [`=COUNTIF(Exceptions!B2:B${end},"Verification evidence missing")`], [`=COUNTIF(Exceptions!B2:B${end},"Body contradiction")`], [`=COUNTIF(Exceptions!B2:B${end},"Schema design gap")`], [`=COUNTIF(Exceptions!M2:M${end},"Decided")+COUNTIF(Exceptions!M2:M${end},"Rejected")`], [`=COUNTIF(Exceptions!M2:M${end},"Pending owner action")+COUNTIF(Exceptions!M2:M${end},"Deferred")`],
];

const navy = '#17365D', blue = '#D9EAF7', yellow = '#FFF2CC', red = '#F4CCCC', gray = '#F2F2F2';
for (const s of [instructions, summary, ex]) { s.showGridLines = false; s.getUsedRange().format.font = { name: 'Aptos', size: 10, color: '#1F1F1F' }; }
instructions.getRange('A1:B1').format = { fill: navy, font: { name: 'Aptos', size: 14, bold: true, color: '#FFFFFF' } };
summary.getRange('A1:B1').format = { fill: navy, font: { name: 'Aptos', size: 14, bold: true, color: '#FFFFFF' } };
summary.getRange('A2:A10').format.font = { bold: true, color: '#1F1F1F' };
summary.getRange('B2:B9').format = { fill: blue, font: { bold: true, color: '#17365D' }, horizontalAlignment: 'center' };
summary.getRange('B10').format = { fill: '#E2F0D9', wrapText: true };
instructions.getRange('A2:A10').format.font = { bold: true, color: navy };
instructions.getRange('B2:B10').format.wrapText = true;
ex.getRange('A1:O1').format = { fill: navy, font: { bold: true, color: '#FFFFFF' }, wrapText: true, horizontalAlignment: 'center', verticalAlignment: 'center' };
ex.getRange(`H2:K${end}`).format = { fill: yellow };
ex.getRange(`L2:M${end}`).format = { fill: gray };
ex.getRange(`A2:A${end}`).format.font = { bold: true, color: navy };
ex.getRange(`B2:B${end}`).format.font = { bold: true };
ex.getRange(`E2:O${end}`).format.wrapText = true;
ex.getRange(`A1:O${end}`).format.verticalAlignment = 'top';
ex.getRange(`A1:O${end}`).format.borders = { preset: 'all', style: 'thin', color: '#D9E1F2' };
ex.getRange(`H2:H${end}`).dataValidation = { rule: { type: 'list', values: ['Confirm','Override','Defer','Reject'] } };
ex.getRange(`B2:B${end}`).conditionalFormats.add('containsText', { text: 'Owner action required', format: { fill: red, font: { bold: true, color: '#9C0006' } } });
ex.getRange(`M2:M${end}`).conditionalFormats.add('containsText', { text: 'Pending', format: { fill: red, font: { bold: true, color: '#9C0006' } } });
ex.getRange(`M2:M${end}`).conditionalFormats.add('containsText', { text: 'Decided', format: { fill: '#E2F0D9', font: { bold: true, color: '#006100' } } });
ex.getRange(`M2:M${end}`).conditionalFormats.add('containsText', { text: 'Rejected', format: { fill: '#EDEDED', font: { bold: true, color: '#666666' } } });
ex.freezePanes.freezeRows(1);
ex.getRange('A:O').format.columnWidth = 16;
ex.getRange('A:A').format.columnWidth = 14; ex.getRange('B:B').format.columnWidth = 22; ex.getRange('C:C').format.columnWidth = 22; ex.getRange('D:D').format.columnWidth = 24; ex.getRange('E:F').format.columnWidth = 42; ex.getRange('G:G').format.columnWidth = 12; ex.getRange('H:H').format.columnWidth = 15; ex.getRange('I:K').format.columnWidth = 26; ex.getRange('L:M').format.columnWidth = 26; ex.getRange('N:N').format.columnWidth = 30; ex.getRange('O:O').format.columnWidth = 38;
ex.getRange(`1:1`).format.rowHeight = 34;
summary.getRange('A:A').format.columnWidth = 28; summary.getRange('B:B').format.columnWidth = 64;
instructions.getRange('A:A').format.columnWidth = 22; instructions.getRange('B:B').format.columnWidth = 110;

wb.recalculate();
const out = await SpreadsheetFile.exportXlsx(wb);
await out.save(`${outputDir}/NiAv_G0_Exception_Register_v0.1.xlsx`);
for (const sheetName of ['Summary','Exceptions']) {
  const preview = await wb.render({ sheetName, autoCrop: 'all', scale: 1, format: 'png' });
  await fs.writeFile(`${outputDir}/NiAv_G0_Exception_Register_${sheetName}.png`, new Uint8Array(await preview.arrayBuffer()));
}
console.log(JSON.stringify({ output: `${outputDir}/NiAv_G0_Exception_Register_v0.1.xlsx`, rows: rows.length, sheets: 3 }, null, 2));
