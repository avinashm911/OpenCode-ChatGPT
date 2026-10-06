# NiAv Document Link Studio

This is the alternative native Windows tool. It does not need Python, Node, a browser tab, or a localhost server.

Run it from PowerShell in the NiAv folder:

```powershell
powershell -ExecutionPolicy Bypass -File .\NiAv_Document_Link_Studio.ps1
```

Then:

1. Select the folder containing the 15 NiAv `.html` documents.
2. Select an unresolved ID from the left panel.
3. Enter the decision/evidence and choose the status.
4. Click **Apply closure to all linked documents**.

Each affected HTML file receives a generated closure ledger. Before writing, the tool creates timestamped copies in `.niav_linker_backups` beside the documents.
