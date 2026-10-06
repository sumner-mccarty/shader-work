#!/usr/bin/env python3
"""
The COHESION test: stop looking at parts in a list and build the thing they are actually for.

A part list flatters a skin — every control gets its own row, its own space, and nothing has to
agree with its neighbour. A rack strip does the opposite: the knob sits ON the faceplate it was
coloured against, next to the button it has to share a light source with, and any part that came
from a different design decision announces itself immediately.

Placement note: cells are supersampled (ss) and, when they cast, rendered on a 2x frame with the
widget centred. Both are undone here so a part lands at its true pixel size — getting this wrong
silently draws everything at 2x and looks like a layout bug rather than a scaling one.
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
from skinsheet import OUT, render, _font
from skinlib import path
from bake import BAKED

# A rack cell names a part by SUFFIX (the authored file's stem). In light mode the same part comes
# from the baked roster instead, so one map turns a suffix into the role the recipe keys on.
SUFFIX_ROLE = {
    "Face": "panel.faceplate", "Inset": "panel.inset", "Well": "display.well",
    "Back": "panel.backplane", "KnobHero": "knob.hero", "Knob": "knob.medium",
    "KnobSmall": "knob.small", "Slider": "slider.long", "Pill": "toggle.pill",
    "Accent": "button.accent", "Close": "button.close", "Button": "button.standard",
    "ToggleBtn": "toggle.button", "Lamp": "lamp", "Pad": "pad",
}
MODE = {"v": "dark", "rig": None}
# style id -> authored-skin filename stem (they differ where the user-facing word is long)
SKIN_PREFIX = {"Neomorphic": "Neo"}


def resolve(style, suffix):
    if MODE["v"] == "dark":
        return path(SKIN_PREFIX.get(style, style) + suffix)
    role = SUFFIX_ROLE[suffix].replace(".", "-")
    return str((BAKED / f"{style}Light.{role}.states.json").resolve()).replace("\\", "/")

W, H = 1180, 548
SS = 2

_cells = []
_meta = {}


def part(style, suffix, cid, w, h, x, y, shadow=True, **kw):
    """Queue one control and remember where it goes. x,y is its TOP-LEFT in rack space."""
    c = {"id": cid, "states": resolve(style, suffix), "w": w, "h": h, "ss": SS, "bg": "#00000000"}
    if shadow:
        c["shadow"] = 2
    c.update(kw)
    _cells.append(c)
    _meta[cid] = (w, h, x, y, shadow)


def build(style, out, title, ink="#DCE2EA", dim="#7B838E"):
    _cells.clear()
    _meta.clear()

    part(style, "Face", "rk-face", W, H, 0, 0, shadow=False)
    part(style, "Well", "rk-well", 300, 62, 30, 26, shadow=False)
    part(style, "Inset", "rk-ins1", 512, 160, 22, 118, shadow=False)
    part(style, "Inset", "rk-ins2", 356, 160, 556, 118, shadow=False)

    for i in range(3):
        part(style, "Lamp", f"rk-l{i}", 22, 22, 356 + i * 32, 46,
             state="Active" if i == 0 else "Normal")
    part(style, "Close", "rk-cls", 40, 34, W - 66, 22)

    for i, v in enumerate((0.25, 0.5, 0.85, 0.4)):
        part(style, "Knob", f"rk-k{i}", 84, 84, 46 + i * 120, 132, set={"_Value": v})
    for i in range(4):
        part(style, "KnobSmall", f"rk-ks{i}", 58, 58, 580 + i * 82, 146,
             set={"_Value": 0.15 + i * 0.27})
    part(style, "KnobHero", "rk-kh", 128, 128, 966, 118, set={"_Value": 0.72})

    part(style, "Slider", "rk-sld", 300, 46, 30, 322, set={"_Value": 0.62})
    part(style, "Pill", "rk-pill", 86, 38, 352, 326, set={"_Value": 1.0})
    part(style, "Accent", "rk-acc", 88, 54, 460, 318, icon=None)
    for i in range(3):
        part(style, "Button", f"rk-b{i}", 76, 54, 566 + i * 86, 318)
    part(style, "ToggleBtn", "rk-mute", 66, 54, 832, 318)
    part(style, "ToggleBtn", "rk-solo", 66, 54, 906, 318, state="Active")

    for i in range(4):
        part(style, "Pad", f"rk-p{i}", 86, 86, 30 + i * 98, 424)

    render(_cells, rig=MODE["rig"])

    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    for cid, (w, h, x, y, shadow) in _meta.items():
        p = OUT / f"{cid}.png"
        if not p.exists():
            continue
        im = Image.open(p).convert("RGBA")
        frame = 2 if shadow else 1
        im = im.resize((w * frame, h * frame), Image.LANCZOS)
        # A cast cell is drawn on a 2x frame with the widget dead centre; back the padding out.
        ox = -(w // 2) if shadow else 0
        oy = -(h // 2) if shadow else 0
        img.alpha_composite(im, (x + ox, y + oy))

    d = ImageDraw.Draw(img)
    f_lab, f_sm = _font(11, True), _font(10)
    for i, t in enumerate(["GAIN", "TONE", "MIX", "SEND"]):
        d.text((46 + i * 120 + 42 - len(t) * 3, 224), t, font=f_lab, fill=dim)
    for i, t in enumerate(["LOW", "MID", "HIGH", "AIR"]):
        d.text((580 + i * 82 + 29 - len(t) * 3, 212), t, font=f_sm, fill=dim)
    d.text((966 + 40, 254), "MASTER", font=f_lab, fill=dim)
    d.text((44, 40), "-12.4", font=_font(30, True), fill=ink)
    d.text((132, 54), "dB", font=f_lab, fill=dim)
    d.text((30, 392), "FADER", font=f_sm, fill=dim)
    d.text((352, 372), "BANK", font=f_sm, fill=dim)

    page, page_ink = ("#0B0D10", "#E6EBF2") if MODE["v"] == "dark" else ("#F2F3F5", "#12161B")
    sheet = Image.new("RGBA", (W, H + 44), page)
    dd = ImageDraw.Draw(sheet)
    dd.text((14, 12), title, font=_font(19, True), fill=page_ink)
    sheet.alpha_composite(img, (0, 44))
    sheet.convert("RGB").save(out)
    print(f"  -> {out}")
    return out


if __name__ == "__main__":
    style = sys.argv[1] if len(sys.argv) > 1 else "Realistic"
    MODE["v"] = sys.argv[2] if len(sys.argv) > 2 else "dark"
    if len(sys.argv) > 3 and sys.argv[3] == "neutral":
        # A daylight room: three neutral lamps, no warm/green fill. The shipped rig was tuned for
        # dark skins, where its green fill is invisible; on a pale palette it tints everything olive.
        MODE["rig"] = {
            "light1": {"pos": [0.15, 0.85], "height": 0.75, "color": "#FFFFFF",
                       "intensity": 0.85, "specular": 0.12},
            "light2": {"pos": [0.85, 0.75], "height": 0.70, "color": "#F2F6FF",
                       "intensity": 0.40, "specular": 0.08},
            "light3": {"enabled": False},
        }
    ink, dim = ("#DCE2EA", "#7B838E") if MODE["v"] == "dark" else ("#171B21", "#5A626C")
    build(style, str(Path(__file__).resolve().parent.parent / ".skinsheet" / f"rack-{style}-{MODE['v']}.png"),
          f"{style.upper()} {MODE['v'].upper()} — rack strip (cohesion test)",
          ink=ink, dim=dim)
