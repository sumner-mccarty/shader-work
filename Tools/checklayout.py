#!/usr/bin/env python3
"""Parse a .layout.json the way PanelLayoutParser does — JSON with // comments, including
trailing ones after a value. A five-second guard against a hand-edit that would only fail at
runtime, inside Play Mode, as a silent empty panel."""
import json, sys
from pathlib import Path

def strip(text: str) -> str:
    out, i, n, in_str, esc = [], 0, len(text), False, False
    while i < n:
        c = text[i]
        if in_str:
            out.append(c)
            if esc: esc = False
            elif c == "\\": esc = True
            elif c == '"': in_str = False
            i += 1
            continue
        if c == '"':
            in_str = True; out.append(c); i += 1; continue
        if c == "/" and i + 1 < n and text[i+1] == "/":
            while i < n and text[i] != "\n": i += 1
            continue
        if c == "/" and i + 1 < n and text[i+1] == "*":
            i += 2
            while i + 1 < n and not (text[i] == "*" and text[i+1] == "/"): i += 1
            i += 2
            continue
        out.append(c); i += 1
    return "".join(out)

def load(path): return json.loads(strip(Path(path).read_text(encoding="utf-8")))

# Every key PanelLayoutParser.ParseNode actually reads. A doc key it does NOT read is silently
# ignored at runtime — that is how "wrap": true did nothing in every doc until 2026-10-04.
ROOT = Path(__file__).resolve().parent.parent
def parser_keys():
    import re
    src = (ROOT / "Assets/DrumSumDrum.Core/Layout/PanelLayoutParser.cs").read_text(encoding="utf-8")
    body = src[src.index("static LayoutNode ParseNode"):]
    body = body[:body.index("static string InferType") if "static string InferType" in body else len(body)]
    return set(re.findall(r'\(d, "([A-Za-z]+)"', body)) | set(re.findall(r'd\.(?:ContainsKey|TryGetValue)\("([A-Za-z]+)"', body)) | {"children"}

def unread_keys(node, known, path="root"):
    out = []
    if isinstance(node, dict):
        for k in node:
            if k not in known: out.append(f"{path}: \"{k}\"")
        for i, c in enumerate(node.get("children") or []):
            out += unread_keys(c, known, f"{path}/{c.get('name') or c.get('class') or c.get('type') or i}" if isinstance(c, dict) else path)
    return out

if __name__ == "__main__":
    args = sys.argv[1:] or [str(p) for p in sorted(
        (Path(__file__).resolve().parent.parent / "Assets/Resources/PanelLayouts").glob("*.layout.json"))]
    bad = 0
    known = parser_keys()
    for a in args:
        try:
            doc = load(a)
            unread = unread_keys(doc.get("root"), known) if isinstance(doc, dict) else []
            if unread:
                bad += 1
                print(f"  FAIL  {Path(a).name}: keys the parser never reads (ignored at runtime):")
                for u in unread[:12]: print(f"          {u}")
                if len(unread) > 12: print(f"          … and {len(unread) - 12} more")
            else:
                print(f"  ok    {Path(a).name}")
        except Exception as e:
            bad += 1; print(f"  FAIL  {Path(a).name}: {e}")
    sys.exit(1 if bad else 0)
