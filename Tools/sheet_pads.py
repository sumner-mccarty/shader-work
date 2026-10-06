#!/usr/bin/env python3
"""
The DRUM PAD cohesion test — the 4x4 grid as it is actually assembled, not a row of parts.

A pad is the one control in this app whose look cannot be judged alone: it is 1 of 16, it carries
a row colour it did not choose, it sits in a tray, and the RM parallax gives every one of them a
slightly different camera. All four of those only become visible in the grid.

The layout maths below is a faithful re-run of DrumPad.layout.json (root vertical, padding
[0,3,0,3], gap 6; TitleBar minSize [0,26]; PadWell flexGrow 1 with its own padding, gap 6; four
rows of four, gap 6) so the pad rects here are the rects the app builds. Verified against a live
Tools/UiRectDump: panel 433.5x448.6 -> pad 103.9x96.7, which is what the dump reported.

Usage:
    python Tools/sheet_pads.py                 # both sizes, current shipped skins
    python Tools/sheet_pads.py --skin Cand     # try Cand.states.json for the pads
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
from skinsheet import OUT, render, skin_path, _font, SKINS

ROOT = Path(__file__).resolve().parent.parent

# Realistic/dark rosters the Nebula track theme, and Util.RowColor reads @tracks.rowN from it —
# the pads and the highway must agree or the game lies about which row a note belongs to.
TRACK_THEME = "Nebula"
ROWS = 4
COLS = 4


def row_colors(theme=TRACK_THEME):
    src = json.loads((ROOT / "Assets/Resources/TrackThemes" / f"{theme}.track.json").read_text(encoding="utf-8"))
    return [src["palette"][f"row{i + 1}"] for i in range(ROWS)]


def hex_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))


def read_skin(name):
    p = SKINS / f"{name}.states.json" if not name.endswith(".json") else Path(name)
    return json.loads(p.read_text(encoding="utf-8"))


def normal_params(doc):
    for s in doc["states"]:
        if s["stateName"] == "Normal":
            return {p["name"]: p["value"] for p in s["parameters"]}
    return {}


def pad_color_sets(doc, rgb):
    """What DrumPadPanel.ApplyPerPadCustomization would write, resolved through the skin's own
    PadColorBinding: lerp each named property from its authored value toward the row colour."""
    binding = doc.get("padColor") or {}
    targets = binding.get("targets") or ([{"param": binding["param"], "amount": 1.0}]
                                         if binding.get("param") else [])
    base = normal_params(doc)
    out = {}
    for t in targets:
        name, amt = t.get("param"), float(t.get("amount", 1.0))
        if not name:
            continue
        cur = [float(v) for v in (base.get(name) or "0,0,0,1").split(",")]
        while len(cur) < 4:
            cur.append(1.0)
        out[name] = ",".join(f"{cur[i] + (rgb[i] - cur[i]) * amt:.5f}" for i in range(3)) + f",{cur[3]:.3f}"
    return out


# ── the layout, re-run ───────────────────────────────────────────────────────

def pad_rects(panel_w, panel_h, well_pad):
    """Returns (well_rect, [(col,row,x,y,w,h), ...]) in TOP-LEFT pixel space."""
    top, bottom, gap = 3, 3, 6
    title_h = 26
    wx, wy = 0, top + title_h + gap
    ww, wh = panel_w, panel_h - top - bottom - title_h - gap

    l, t, r, b = well_pad
    gx, gy = wx + l, wy + t
    gw, gh = ww - l - r, wh - t - b
    cw = (gw - (COLS - 1) * 6) / COLS
    ch = (gh - (ROWS - 1) * 6) / ROWS

    cells = []
    for r_i in range(ROWS):                      # 0 = TOP row on screen
        for c_i in range(COLS):
            cells.append((c_i, r_i,
                          gx + c_i * (cw + 6), gy + r_i * (ch + 6), cw, ch))
    return (wx, wy, ww, wh), cells


def build(out_path, panel_w, panel_h, pad_skin, well_skin, face_skin, well_pad,
          title, screen=(0.06, 0.02), tilt_amount=4.0, shift_amount=2.0, base_tilt=None,
          signed_tilt=False, ss=2, socket_skin=None):
    """`screen` is where the panel's top-left sits in normalized canvas space — the lamp
    direction is a function of position, so a sheet that pins every pad at 0.5,0.5 shows a grid
    lit from one place that the app will never light from one place."""
    doc = read_skin(pad_skin)
    base = normal_params(doc)
    authored_tilt = float(base.get("_ViewTilt", 0)) if base_tilt is None else base_tilt
    authored_shift = float(base.get("_ViewShift", 0))
    colors = [hex_rgb(c) for c in row_colors()]

    well, cells = pad_rects(panel_w, panel_h, well_pad)
    meta, job = {}, []

    def add(cid, states, w, h, x, y, shadow=False, **kw):
        c = {"id": cid, "states": states, "w": int(round(w)), "h": int(round(h)),
             "ss": ss, "bg": "#00000000"}
        if shadow:
            c["shadow"] = 2
        c.update(kw)
        job.append(c)
        meta[cid] = (int(round(w)), int(round(h)), int(round(x)), int(round(y)), shadow)

    # Canvas is 1080 tall; the sheet is drawn at panel scale, so normalized screen position is
    # (panel origin + pixel offset / 1920 or 1080).
    sx, sy = screen

    def npos(x, y, w, h):
        return [sx + (x + w * 0.5) / 1920.0, 1.0 - (sy + (y + h * 0.5) / 1080.0)]

    add("pd-face", skin_path(face_skin), panel_w, panel_h, 0, 0,
        pos=npos(0, 0, panel_w, panel_h))
    add("pd-well", skin_path(well_skin), well[2], well[3], well[0], well[1],
        pos=npos(well[0], well[1], well[2], well[3]))

    # One APERTURE per pad, drawn under it and filling its whole cell: the chassis is cut for
    # each pad, so what sits between two pads is a chassis edge, not empty tray.
    if socket_skin:
        for c_i, r_i, x, y, w, h in cells:
            add(f"sk-{r_i}{c_i}", skin_path(socket_skin), w, h, x, y,
                pos=npos(x, y, w, h))

    for c_i, r_i, x, y, w, h in cells:
        # Row 0 of the palette is the BOTTOM pad row (DrumPadPanel indexes padIndex/4 from the
        # bottom), and r_i counts from the top.
        rgb = colors[ROWS - 1 - r_i]
        nx = (x + w * 0.5) / panel_w
        ny = 1.0 - (y + h * 0.5) / panel_h        # RmViewParallax works in Unity's +Y-up space
        dx, dy = nx - 0.5, ny - 0.5
        raw = authored_tilt + dy * tilt_amount
        overrides = {"_ViewShift": f"{authored_shift + dx * shift_amount:.4f}"}
        if signed_tilt:
            overrides["_ViewTilt"] = f"{abs(raw):.4f}"
            if raw < 0:
                overrides["_ViewAngle"] = "180"
        else:
            overrides["_ViewTilt"] = f"{max(0.0, raw):.4f}"
        overrides.update(pad_color_sets(doc, rgb))
        add(f"pd-{r_i}{c_i}", skin_path(pad_skin) if "/" not in pad_skin else pad_skin,
            w, h, x, y, shadow=True, pos=npos(x, y, w, h), set=overrides)

    render(job)

    img = Image.new("RGBA", (int(panel_w), int(panel_h)), (0, 0, 0, 0))
    for cid, (w, h, x, y, shadow) in meta.items():
        p = OUT / f"{cid}.png"
        if not p.exists():
            continue
        im = Image.open(p).convert("RGBA")
        frame = 2 if shadow else 1
        im = im.resize((w * frame, h * frame), Image.LANCZOS)
        ox = -(w // 2) if shadow else 0
        oy = -(h // 2) if shadow else 0
        img.alpha_composite(im, (x + ox, y + oy))

    page = Image.new("RGBA", (int(panel_w), int(panel_h) + 40), "#0B0D10")
    ImageDraw.Draw(page).text((12, 11), title, font=_font(17, True), fill="#E6EBF2")
    page.alpha_composite(img, (0, 40))
    page.convert("RGB").save(out_path)
    print(f"  -> {out_path}  ({int(panel_w)}x{int(panel_h)})")
    return out_path


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--skin", default="RealisticPad")
    ap.add_argument("--well", default="PadWell")
    ap.add_argument("--socket", default=None)
    ap.add_argument("--face", default="RackFaceplateGraphite")
    ap.add_argument("--pad", default="0,0,0,0", help="PadWell container padding l,t,r,b")
    ap.add_argument("--tilt", type=float, default=4.0)
    ap.add_argument("--shift", type=float, default=2.0)
    ap.add_argument("--base-tilt", type=float, default=None)
    ap.add_argument("--signed", action="store_true")
    ap.add_argument("--ss", type=int, default=1)
    ap.add_argument("--tag", default="now")
    ap.add_argument("--size", default="both", choices=("big", "small", "both"))
    a = ap.parse_args()

    wp = [float(v) for v in a.pad.split(",")]
    sizes = {"big": (892, 907), "small": (433, 449)}
    for key in (["big", "small"] if a.size == "both" else [a.size]):
        w, h = sizes[key]
        build(ROOT / ".skinsheet" / f"pads-{a.tag}-{key}.png", w, h, a.skin, a.well, a.face, wp,
              f"{a.skin} on {a.well} — {key} ({w}x{h})  tilt={a.tilt} shift={a.shift}"
              + ("  signed" if a.signed else ""),
              tilt_amount=a.tilt, shift_amount=a.shift, base_tilt=a.base_tilt,
              signed_tilt=a.signed, ss=a.ss, socket_skin=a.socket)
