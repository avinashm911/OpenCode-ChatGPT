#!/usr/bin/env python3
"""NiAv document linker and closure tool.

Standard-library-only local tool. It scans the HTML documents in its folder,
extracts likely unresolved items, accepts owner resolutions, and appends a
traceable closure ledger to every affected document.
"""
from __future__ import annotations

import argparse
import datetime as dt
import html
import http.server
import json
import os
import re
import shutil
import threading
import urllib.parse
from html.parser import HTMLParser
from pathlib import Path


ROOT = Path(__file__).resolve().parent
STATE = ROOT / ".niav_linker"
BACKUPS = STATE / "backups"
STATE_FILE = STATE / "state.json"
ID_RE = re.compile(r"\b(?:O-[A-Z0-9-]+|OD-[A-Z0-9-]+|RTM-O[A-Z0-9-]*|D-[A-Z0-9-]+|A-[A-Z0-9-]+|R-[A-Z0-9-]+|WP-[A-Z0-9-]+)\b", re.I)
UNRESOLVED_RE = re.compile(r"\b(?:TBC|TBD|open|unresolved|pending|verify|to be decided|to be confirmed|not yet frozen|conditional)\b|\[VERIFY\]", re.I)
DOC_RE = re.compile(r"\.html$", re.I)


def now():
    return dt.datetime.now().astimezone().isoformat(timespec="seconds")


def read_state():
    if not STATE_FILE.exists():
        return {"resolutions": [], "imports": []}
    try:
        return json.loads(STATE_FILE.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {"resolutions": [], "imports": []}


def write_state(state):
    STATE.mkdir(exist_ok=True)
    STATE_FILE.write_text(json.dumps(state, ensure_ascii=False, indent=2), encoding="utf-8")


class TextParser(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.stack = []
        self.title = ""
        self.heading = ""
        self.rows = []
        self.current_row = None
        self.current_cell = None
        self.links = []

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        self.stack.append(tag)
        if tag == "tr":
            self.current_row = []
        elif tag in ("td", "th") and self.current_row is not None:
            self.current_cell = []
        elif tag == "a" and attrs.get("href"):
            self.links.append(attrs["href"])

    def handle_endtag(self, tag):
        if tag in ("td", "th") and self.current_cell is not None and self.current_row is not None:
            self.current_row.append(" ".join("".join(self.current_cell).split()))
            self.current_cell = None
        elif tag == "tr" and self.current_row is not None:
            if self.current_row:
                self.rows.append(self.current_row)
            self.current_row = None
        if self.stack:
            self.stack.pop()

    def handle_data(self, data):
        if "title" in self.stack:
            self.title += data
        if self.stack and self.stack[-1] in ("h1", "h2", "h3"):
            self.heading += data
        if self.current_cell is not None:
            self.current_cell.append(data)


def analyse(path):
    raw = path.read_text(encoding="utf-8", errors="replace")
    parser = TextParser()
    parser.feed(raw)
    candidates = {}
    for row in parser.rows:
        text = " | ".join(row)
        if not UNRESOLVED_RE.search(text):
            continue
        ids = ID_RE.findall(text)
        if not ids:
            ids = [f"AUTO-{abs(hash(text)) % 100000:05d}"]
        for item_id in ids:
            candidates.setdefault(item_id.upper(), {"id": item_id.upper(), "text": text, "locations": []})
            candidates[item_id.upper()]["locations"].append("table")
    # Prose items often have no table row; keep a compact context around markers.
    for match in re.finditer(r"[^<]{0,220}(?:TBC|TBD|\[VERIFY\]|not yet frozen|to be decided)[^<]{0,220}", raw, re.I):
        context = " ".join(re.sub(r"<[^>]+>", " ", match.group(0)).split())
        ids = ID_RE.findall(context)
        for item_id in ids:
            key = item_id.upper()
            if key not in candidates:
                candidates[key] = {"id": key, "text": context, "locations": ["prose"]}
    title = parser.title.strip() or path.stem
    return {"file": path.name, "title": title, "items": list(candidates.values()), "links": parser.links}


def scan():
    docs = [analyse(p) for p in sorted(ROOT.iterdir()) if p.is_file() and DOC_RE.search(p.name)]
    states = {r["id"].upper(): r for r in read_state().get("resolutions", [])}
    for doc in docs:
        for item in doc["items"]:
            item["resolution"] = states.get(item["id"])
    return docs


def linked_docs(item_id, docs):
    return [d["file"] for d in docs if any(i["id"].upper() == item_id.upper() for i in d["items"])]


def closure_section(resolutions):
    rows = []
    for r in resolutions:
        affected = ", ".join(r.get("affected_docs", []))
        rows.append(
            "<tr><td><code>{}</code></td><td>{}</td><td>{}</td><td>{}</td><td>{}</td><td>{}</td></tr>".format(
                html.escape(r["id"]), html.escape(r.get("status", "Closed")),
                html.escape(r.get("decision", "")), html.escape(r.get("evidence", "")),
                html.escape(affected), html.escape(r.get("timestamp", ""))))
    return """\n<section id=\"niav-closure-ledger\" class=\"niav-linker-ledger\" data-generated-by=\"niav-document-linker\">\n<h2>NiAv Cross-Document Closure Ledger</h2>\n<p>This generated ledger is maintained by <code>niav_document_linker.py</code>. Original text and IDs are retained; resolutions are applied as traceable owner decisions or verification records.</p>\n<table><thead><tr><th>ID</th><th>Status</th><th>Resolution / decision</th><th>Evidence / input</th><th>Affected documents</th><th>Recorded</th></tr></thead><tbody>{}</tbody></table>\n</section>\n""".format("".join(rows))


def update_documents(resolutions):
    docs = scan()
    by_file = {d["file"]: d for d in docs}
    for r in resolutions:
        r["affected_docs"] = r.get("affected_docs") or linked_docs(r["id"], docs)
    for filename, doc in by_file.items():
        path = ROOT / filename
        source = path.read_text(encoding="utf-8", errors="replace")
        if "id=\"niav-closure-ledger\"" in source:
            source = re.sub(r"\n<section id=\"niav-closure-ledger\".*?</section>\n", "\n", source, flags=re.S)
        local = [r for r in resolutions if filename in r.get("affected_docs", [])]
        if not local:
            continue
        BACKUPS.mkdir(parents=True, exist_ok=True)
        backup = BACKUPS / f"{path.stem}.{dt.datetime.now().strftime('%Y%m%d%H%M%S')}.html"
        if not backup.exists():
            shutil.copy2(path, backup)
        addition = closure_section(local)
        if re.search(r"</body>", source, re.I):
            source = re.sub(r"</body>", addition + "</body>", source, count=1, flags=re.I)
        else:
            source += addition
        path.write_text(source, encoding="utf-8")


INDEX_HTML = r'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>NiAv Document Linker</title>
<style>body{font-family:system-ui,Segoe UI,sans-serif;margin:0;background:#f5f7fb;color:#172033}header{background:#172033;color:#fff;padding:22px 28px}main{max-width:1400px;margin:20px auto;padding:0 18px}.grid{display:grid;grid-template-columns:340px 1fr;gap:18px}.card{background:#fff;border:1px solid #dbe1ec;border-radius:10px;padding:16px;box-shadow:0 2px 8px #18243a12}button{background:#1769e0;color:#fff;border:0;border-radius:6px;padding:9px 13px;cursor:pointer}button.secondary{background:#e9eef8;color:#172033}input,textarea,select{width:100%;box-sizing:border-box;padding:9px;border:1px solid #bac5d8;border-radius:6px;margin:5px 0 11px}textarea{min-height:90px}table{width:100%;border-collapse:collapse;font-size:13px}th,td{text-align:left;border-bottom:1px solid #e5eaf2;padding:9px;vertical-align:top}.badge{display:inline-block;border-radius:12px;background:#fff1c7;color:#755500;padding:2px 8px;font-size:11px}.closed{background:#d9f6e6;color:#086b38}.muted{color:#667085;font-size:13px}.item{padding:9px;border-bottom:1px solid #e5eaf2;cursor:pointer}.item:hover{background:#f2f6ff}.item strong{display:block}.toolbar{display:flex;gap:8px;flex-wrap:wrap;align-items:center}.toolbar input{max-width:360px;margin:0}.notice{padding:10px;background:#edf5ff;border-left:4px solid #1769e0;margin-bottom:14px}.danger{background:#fff1f0;border-left-color:#d93025}.small{font-size:12px}</style></head><body><header><h1>NiAv Document Linker</h1><div>Cross-document closure workspace for the NiAv living-document set</div></header><main><div id="notice" class="notice">Loading document inventory…</div><div class="grid"><aside class="card"><h2>Open items</h2><div class="toolbar"><input id="filter" placeholder="Filter ID or text"><button class="secondary" onclick="load()">Refresh</button></div><div id="items"></div></aside><section><div class="card"><h2 id="selected">Select an unresolved item</h2><p class="muted">Choose an item to see every document containing the same ID. Enter owner data or verification evidence, then record one resolution across the linked set.</p><form id="form" style="display:none"><label>Status<select id="status"><option>Closed</option><option>Decided</option><option>Verified</option><option>Superseded</option><option>Deferred</option></select></label><label>Resolution / decision<textarea id="decision" required placeholder="Example: Quantity scale is 3 decimal places for V1 inventory quantities."></textarea></label><label>Evidence / input<textarea id="evidence" placeholder="Owner input, source file, test result, licence URL, or verification note"></textarea></label><label>Additional document links (optional)<input id="extra" placeholder="comma-separated filenames"></label><button>Apply closure to linked documents</button></form></div><div class="card" style="margin-top:18px"><h2>Document map</h2><div id="docs"></div></div><div class="card" style="margin-top:18px"><h2>Import / export</h2><p class="muted">Import JSON with an array of resolutions to batch-close decisions. Export the current traceability state for review or version control.</p><textarea id="importBox" placeholder='[{"id":"O-M03","status":"Closed","decision":"...","evidence":"..."}]'></textarea><div class="toolbar"><button onclick="importData()">Import resolutions</button><button class="secondary" onclick="exportData()">Download state JSON</button></div></div></section></div></main><script>
let docs=[],selected=null; const $=id=>document.getElementById(id);
async function load(){let r=await fetch('/api/scan');let x=await r.json();docs=x.docs;renderDocs();renderItems();$('notice').textContent=`${x.total_items} unresolved items found across ${docs.length} documents. Resolutions are written to the documents with backups in .niav_linker/backups.`}
function isOpen(i){return !i.resolution||!['Closed','Decided','Verified','Superseded'].includes(i.resolution.status)}
function renderDocs(){$('docs').innerHTML='<table><tr><th>File</th><th>Open IDs</th><th>Links</th></tr>'+docs.map(d=>`<tr><td>${esc(d.file)}</td><td>${d.items.filter(isOpen).length}</td><td>${d.links.length}</td></tr>`).join('')+'</table>'}
function renderItems(){let q=$('filter').value.toLowerCase();let all=[];docs.forEach(d=>d.items.filter(isOpen).forEach(i=>{if(!all.some(x=>x.id===i.id))all.push(i)}));all=all.filter(i=>(i.id+' '+i.text).toLowerCase().includes(q));$('items').innerHTML=all.map(i=>`<div class="item" onclick="select('${i.id}')"><strong>${esc(i.id)} <span class="badge">open</span></strong><span class="small">${esc(i.text.slice(0,180))}</span></div>`).join('')||'<p class="muted">No matching items.</p>'}
function select(id){selected=id;let matches=docs.filter(d=>d.items.some(i=>i.id===id));let item=matches.flatMap(d=>d.items).find(i=>i.id===id);$('selected').textContent=id;$('form').style.display='block';$('decision').value=item.resolution?.decision||'';$('evidence').value=item.resolution?.evidence||'';$('status').value=item.resolution?.status||'Closed';$('extra').value=matches.map(d=>d.file).join(', ');document.querySelector('#selected').insertAdjacentHTML('afterend',`<p class="muted">${matches.length} linked document(s): ${matches.map(d=>esc(d.file)).join(', ')}</p>`)}
$('form').onsubmit=async e=>{e.preventDefault();let affected=$('extra').value.split(',').map(x=>x.trim()).filter(Boolean);let r=await fetch('/api/resolve',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({id:selected,status:$('status').value,decision:$('decision').value,evidence:$('evidence').value,affected_docs:affected})});let x=await r.json();if(!r.ok){$('notice').className='notice danger';$('notice').textContent=x.error;return}$('notice').className='notice';$('notice').textContent=`Recorded ${selected} and updated ${x.updated.length} document(s).`;await load();selected=null;$('form').style.display='none';$('selected').textContent='Select an unresolved item'};
async function importData(){try{let data=JSON.parse($('importBox').value);let r=await fetch('/api/import',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(data)});let x=await r.json();$('notice').textContent=`Imported ${x.count} resolution(s).`;await load()}catch(e){$('notice').className='notice danger';$('notice').textContent='Import failed: '+e.message}}
async function exportData(){let r=await fetch('/api/state');let b=await r.blob();let a=document.createElement('a');a.href=URL.createObjectURL(b);a.download='niav-linker-state.json';a.click()}
function esc(s){return String(s||'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]))} $('filter').oninput=renderItems;load();</script></body></html>'''


class Handler(http.server.BaseHTTPRequestHandler):
    def send_json(self, payload, status=200):
        body = json.dumps(payload, ensure_ascii=False).encode()
        self.send_response(status); self.send_header("Content-Type", "application/json; charset=utf-8"); self.send_header("Content-Length", str(len(body))); self.end_headers(); self.wfile.write(body)

    def do_GET(self):
        route = urllib.parse.urlparse(self.path).path
        if route == "/":
            body = INDEX_HTML.encode(); self.send_response(200); self.send_header("Content-Type", "text/html; charset=utf-8"); self.send_header("Content-Length", str(len(body))); self.end_headers(); self.wfile.write(body)
        elif route == "/api/scan":
            docs = scan(); closed = {"Closed", "Decided", "Verified", "Superseded"}; self.send_json({"docs": docs, "total_items": len({i["id"] for d in docs for i in d["items"] if not i.get("resolution") or i["resolution"].get("status") not in closed})})
        elif route == "/api/state":
            body = json.dumps(read_state(), ensure_ascii=False, indent=2).encode(); self.send_response(200); self.send_header("Content-Type", "application/json"); self.send_header("Content-Disposition", "attachment; filename=niav-linker-state.json"); self.send_header("Content-Length", str(len(body))); self.end_headers(); self.wfile.write(body)
        else: self.send_error(404)

    def do_POST(self):
        length = int(self.headers.get("Content-Length", "0")); raw = self.rfile.read(length)
        try: payload = json.loads(raw.decode("utf-8"))
        except json.JSONDecodeError: return self.send_json({"error": "Request body must be JSON."}, 400)
        if self.path == "/api/resolve":
            payload = [payload]
        if self.path not in ("/api/resolve", "/api/import") or not isinstance(payload, list): return self.send_json({"error": "Expected a resolution object or array."}, 400)
        docs = scan(); known = {i["id"].upper() for d in docs for i in d["items"]}; state = read_state(); added=[]
        for r in payload:
            rid = str(r.get("id", "")).upper().strip()
            decision = str(r.get("decision", "")).strip()
            if not rid or not decision: return self.send_json({"error": "Every resolution needs id and decision."}, 400)
            if rid not in known and not r.get("affected_docs"): return self.send_json({"error": f"Unknown item {rid}; provide affected_docs or scan first."}, 400)
            entry = {"id": rid, "status": r.get("status", "Closed"), "decision": decision, "evidence": r.get("evidence", ""), "affected_docs": r.get("affected_docs") or linked_docs(rid, docs), "timestamp": r.get("timestamp", now())}
            state["resolutions"] = [x for x in state.get("resolutions", []) if x.get("id", "").upper() != rid]
            state["resolutions"].append(entry); added.append(entry)
        write_state(state); update_documents(state["resolutions"])
        self.send_json({"count": len(added), "updated": sorted({f for r in added for f in r["affected_docs"]})})

    def log_message(self, *_): pass


def main():
    ap = argparse.ArgumentParser(description="Run the NiAv cross-document closure tool")
    ap.add_argument("--port", type=int, default=8765)
    args = ap.parse_args()
    server = http.server.ThreadingHTTPServer(("127.0.0.1", args.port), Handler)
    print(f"NiAv Document Linker: http://127.0.0.1:{args.port}")
    try: server.serve_forever()
    except KeyboardInterrupt: pass


if __name__ == "__main__": main()
