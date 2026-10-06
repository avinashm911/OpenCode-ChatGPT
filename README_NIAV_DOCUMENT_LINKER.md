# NiAv Document Linker

This local, standard-library-only tool links the NiAv HTML living documents through their shared IDs and closes unresolved points with one traceable owner decision or verification record.

## Run

From this folder:

```powershell
.\run_niav_document_linker.ps1
```

The launcher accepts an optional port, for example `.\run_niav_document_linker.ps1 -Port 9000`.

Open `http://127.0.0.1:8765` in a browser.

## Workflow

1. The scanner inventories all `.html` documents in the same folder.
2. It finds unresolved table/prose items marked with IDs such as `O-M03`, `OD-UI-001`, `RTM-O01`, `TBC`, `TBD`, or `[VERIFY]`.
3. Selecting an item shows every document containing that ID.
4. Enter the decision, status, and evidence. The tool updates every affected document by adding a generated **NiAv Cross-Document Closure Ledger** section.
5. The original files are backed up under `.niav_linker/backups/`, and resolutions are stored in `.niav_linker/state.json`.
6. Batch input is supported through JSON, for example:

```json
[
  {
    "id": "O-M03",
    "status": "Closed",
    "decision": "Quick Bill save-to-fresh-bill target is 10 seconds on the V1 baseline device.",
    "evidence": "Owner decision; to be verified in G2 performance test.",
    "affected_docs": ["NiAv_ Universal Master Plan v0.2.html"]
  }
]
```

The tool intentionally does not erase or rewrite the original unresolved wording. This maintains document history and makes each closure auditable.
