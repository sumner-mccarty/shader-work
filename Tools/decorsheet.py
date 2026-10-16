#!/usr/bin/env python3
"""
Offline contact sheets for the faceplate-decor item shaders (Docs/Decor.md), through slrender — no Unity.

    python Tools/decorsheet.py wraps  out.png [W H]          every UI/Decor/Wrap pattern on a W x H plate
    python Tools/decorsheet.py wrapsb out.png [W H]          just the second sheet (UI/Decor/WrapB)
    python Tools/decorsheet.py wrap   out.png MODE [k=v ...]  one pattern, raw property overrides
    python Tools/decorsheet.py stickers out.png [pack=a,b ids=a/x,b/y size=96 cols=8 grime=0.6]
                                                             every procedural shape + every atlas sticker (or just those)

What it shows is the ALBEDO target (SV_Target0) composited over a plate colour — shape, colour and pattern.
Relief, gloss and the cast shadow only exist once the plate shader lights them: judge those in Play Mode
({"call": "DecorDev.Stage", "arg": ...} over the SkinSheet bus).

The wrap shader works in canvas units (unity_ObjectToWorld scales the 0..1 quad to W x H and the VP matrix
is an ortho over the same box), exactly as DecorRenderer draws it into a panel's decor texture.
"""
import json
import os
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

WRAPS = [
    # id, mode, colors (C0..C3), scale, title  — keep in step with DecorCatalog.Wraps
    ("solid", 0, ["#1B6FE0"], 60, "Solid"),
    ("gradient", 1, ["#FF2D6F", "#7A2CFF", "#00000000"], 60, "Fade"),
    ("radial", 2, ["#FFB300", "#B3123A", "#00000000"], 60, "Glow fade"),
    ("camo", 3, ["#4B5320", "#6B6B3A", "#2E2A1E", "#8C7853"], 90, "Camo"),
    ("checker", 10, ["#00000000", "#F2F2F2", "#141414"], 22, "Checkers"),
    ("racing", 11, ["#00000000", "#F5F5F5", "#E2231A"], 46, "Racing"),
    ("polka", 12, ["#00000000", "#FFFFFF"], 34, "Polka"),
    ("hazard", 23, ["#000000", "#FFC400", "#121212"], 28, "Hazard"),
    ("digicamo", 4, ["#5A6B7A", "#8A9AA8", "#2F3A44", "#C2CDD6"], 80, "Digital camo"),
    ("tiger", 5, ["#E9861C", "#E9861C", "#120C08", "#F6E7C8"], 70, "Tiger"),
    ("leopard", 6, ["#D9A055", "#D9A055", "#20150C", "#B9743A"], 50, "Leopard"),
    ("zebra", 7, ["#F4F1EA", "#F4F1EA", "#101010"], 40, "Zebra"),
    ("carbon", 8, ["#0E0F11", "#3A3F47"], 60, "Carbon"),
    ("flames", 9, ["#00000000", "#FFE14A", "#FF7A00", "#D3121E"], 90, "Flames"),
    ("marble", 13, ["#F2F0EC", "#D8D4CC", "#5F5A55"], 120, "Marble"),
    ("terrazzo", 14, ["#ECE6DA", "#E36B4D", "#2B6E8F", "#F2C14E"], 40, "Terrazzo"),
    ("honeycomb", 15, ["#1C1F24", "#E8B500"], 30, "Honeycomb"),
    ("plaid", 16, ["#7A1418", "#0E2A1A", "#141414", "#E8C547"], 40, "Plaid"),
    ("waves", 17, ["#0F3B63", "#E9F1F7"], 38, "Waves"),
    ("halftone", 18, ["#FFE600", "#E4002B"], 40, "Halftone"),
    ("sprinkles", 19, ["#00000000", "#FF4F9A", "#4FC3FF", "#FFE14A"], 26, "Sprinkles"),
    ("stars", 20, ["#070B1E", "#2A1B4D", "#FFFFFF", "#9CD3FF"], 40, "Night sky"),
    ("wood", 21, ["#8A5A33", "#5C3A1E"], 80, "Wood"),
    ("brushed", 22, ["#B9BEC4"], 60, "Brushed"),
    ("splatter", 24, ["#F4F1EA", "#E4002B", "#1B6FE0", "#111111"], 60, "Splatter"),
    ("confetti", 25, ["#00000000", "#FF4F9A", "#FFE14A", "#4FD1C5"], 34, "Confetti"),
    ("aurora", 26, ["#081226", "#14B8A6", "#7C3AED", "#F472B6"], 120, "Aurora"),
    ("holo", 27, ["#C9CED6", "#FFFFFF"], 60, "Holo base"),
    # the second sheet, UI/Decor/WrapB (mode = 100 + its _Mode) - keep in step with DecorCatalog.Wraps
    ("brick", 100, ["#9A958C", "#B4573C", "#8E3F2E", "#2E2A27"], 90, "Brick wall"),
    ("subway", 101, ["#C9C6BE", "#F2F1EC"], 70, "Subway tile"),
    ("chainlink", 102, ["#00000000", "#B9C0C8"], 46, "Chain-link"),
    ("scrawl", 103, ["#16171B", "#FF2D6F", "#2EE6FF", "#FFD400"], 80, "Scrawl"),
    ("tiedye", 104, ["#FF2D6F", "#FFB300", "#3A6BFF", "#8B3DFF"], 120, "Tie-dye"),
    ("paisley", 105, ["#B3123A", "#F4F1EA", "#6B0A22", "#FFD1A0"], 70, "Paisley"),
    ("argyle", 106, ["#E9E2D0", "#1F3A5F", "#7A1F3D", "#E9C46A"], 70, "Argyle"),
    ("scales", 107, ["#0A3D2E", "#2EC4B6", "#1B8A6B", "#9FF3D8"], 40, "Scales"),
    ("tufted", 108, ["#6B0F1A", "#E0B84A"], 70, "Tufted leather"),
    ("circuit", 109, ["#0E4D3A", "#C9A44C", "#0A2A20", "#E9F2EC"], 70, "Circuit board"),
    ("grooves", 110, ["#26272C", "#FF2D6F", "#FFD400", "#2EE6FF"], 100, "Crate digger"),
    ("spectrum", 111, ["#0B0B10", "#2EE6A0", "#FFD400", "#FF2D2D"], 90, "Equalizer"),
    ("memphis", 112, ["#F4E9D8", "#FF5A8A", "#2EC4B6", "#2B2D6B"], 70, "Memphis"),
    ("concrete", 113, ["#8A8D90", "#6F6A60"], 100, "Concrete"),
    ("corrugated", 114, ["#B8BDC2", "#9A4B22"], 60, "Corrugated tin"),
    ("sunburst", 115, ["#FFB300", "#FF7A00", "#C21E56", "#FFE9A8"], 90, "Sunburst"),
    ("denim", 116, ["#1F3F6B", "#6F93C2", "#E0B84A"], 80, "Denim"),
    ("scanlines", 117, ["#0E2A22", "#3FBF93", "#00F0FF"], 80, "CRT"),
    ("blueprint", 118, ["#12408A", "#BFE0FF", "#FFFFFF"], 80, "Blueprint"),
]

SHAPES = ["circle", "square", "star", "shield", "bolt", "heart", "burst", "bubble", "badge", "hex", "diamond",
          "pill", "arrow", "cloud"]
SHAPE_COLORS = {
    0: ["#2EC4B6", "#1B8A80", "#E9FFFC"], 1: ["#3A86FF", "#1B4FBF", "#DDE9FF"], 2: ["#FFC531", "#FF8A00", "#FFF4C7"],
    3: ["#2B59C3", "#14306B", "#FFFFFF"], 4: ["#FFE14A", "#FF9F1C", "#FFFFFF"], 5: ["#FF3D7F", "#C2185B", "#FFD1E0"],
    6: ["#FF4F2E", "#C2185B", "#FFE14A"], 7: ["#FFFFFF", "#E8ECF2", "#1B1B1B"], 8: ["#E63946", "#9D1C26", "#FFF1E6"],
    9: ["#8338EC", "#4C1D95", "#EDE3FF"], 10: ["#06D6A0", "#05866A", "#E7FFF8"], 11: ["#111111", "#2A2A2A", "#FFC531"],
    12: ["#FF006E", "#8A0039", "#FFFFFF"], 13: ["#FFFFFF", "#DCE6F2", "#9BB5D6"],
}


def _renderer():
    from slrender.skins import SkinRenderer
    return SkinRenderer(ROOT)


def _color(hexs):
    from slrender.skins import parse_color
    return parse_color(hexs)


def _globals(w, h):
    vp = [[2.0 / w, 0, 0, -1.0], [0, 2.0 / h, 0, -1.0], [0, 0, -0.0198, -0.9802], [0, 0, 0, 1.0]]
    o2w = [[float(w), 0, 0, 0], [0, float(h), 0, 0], [0, 0, 1.0, 0], [0, 0, 0, 1.0]]
    return {"unity_ObjectToWorld": o2w, "unity_MatrixVP": vp, "glstate_matrix_projection": vp}


def _over(img, plate):
    """Premultiplied rgba (HxWx4, uint8 or float 0..1) over a flat plate colour → uint8 RGB."""
    if img.dtype == np.uint8:
        img = img.astype(np.float32) / 255.0
    a = img[..., 3:4]
    rgb = img[..., :3] + plate[None, None, :] * (1.0 - a)
    return (np.clip(rgb, 0, 1) * 255 + 0.5).astype(np.uint8)


def render_wrap(sr, mode, colors, scale, w, h, extra=None, seed=3.0):
    props = {"_Mode": float(mode), "_Scale": float(scale), "_Angle": 0.0, "_Seed": seed,
             "_Size": (float(w), float(h), 0.0, 0.0), "_Color": (1, 1, 1, 1)}
    for i in range(4):
        c = colors[i] if i < len(colors) else ("#00000000" if i == 2 else "#FFFFFF")
        props["_C%d" % i] = _color(c)
    props.update(extra or {})
    shader = "UI/Decor/Wrap"
    if mode >= 100:                                  # the second sheet is its own shader, _Mode = mode - 100
        shader, props["_Mode"] = "UI/Decor/WrapB", float(mode - 100)
    img = sr.r.render(shader, props, (w, h), _globals(w, h), bg=(0, 0, 0, 0))
    return img


def render_sticker(sr, props, size):
    base = {"_Color": (1, 1, 1, 1), "_ArtSize": 0.82, "_Border": 0.06, "_ArtSlice": -1.0}
    base.update(props)
    return sr.r.render("UI/Decor/Sticker", base, (size, size), {}, bg=(0, 0, 0, 0))


def sheet(cells, cols, cw, ch, out, title):
    pad, lab = 10, 22
    rows = (len(cells) + cols - 1) // cols
    W = cols * (cw + pad) + pad
    H = rows * (ch + pad + lab) + pad + 34
    S = Image.new("RGB", (W, H), (16, 19, 23))
    d = ImageDraw.Draw(S)
    try:
        font = ImageFont.truetype("arial.ttf", 13)
        tfont = ImageFont.truetype("arialbd.ttf", 16)
    except OSError:
        font = tfont = ImageFont.load_default()
    d.text((pad, 8), title, fill=(230, 235, 242), font=tfont)
    for i, (im, label) in enumerate(cells):
        r, c = divmod(i, cols)
        x = pad + c * (cw + pad)
        y = 34 + pad + r * (ch + pad + lab)
        S.paste(Image.fromarray(im), (x, y))
        d.text((x, y + ch + 4), label, fill=(150, 160, 172), font=font)
    S.save(out)
    print(out, S.size)


def main():
    cmd, out = sys.argv[1], sys.argv[2]
    sr = _renderer()
    plate = np.array([0.55, 0.57, 0.6])
    if cmd in ("wraps", "wrapsb"):                   # wrapsb = only the second sheet
        w = int(sys.argv[3]) if len(sys.argv) > 3 else 360
        h = int(sys.argv[4]) if len(sys.argv) > 4 else 220
        cells = []
        for wid, mode, cols, scale, title in WRAPS:
            if cmd == "wrapsb" and mode < 100:
                continue
            img = render_wrap(sr, mode, cols, scale, w, h)
            cells.append((_over(img, plate), f"{title}  ({wid}, mode {mode})"))
        sheet(cells, 4, w, h, out, "UI/Decor/Wrap — albedo over a grey plate")
    elif cmd == "wrap":
        mode = int(sys.argv[3])
        kv = dict(a.split("=", 1) for a in sys.argv[4:])
        w, h = int(kv.pop("w", 700)), int(kv.pop("h", 360))
        entry = next((e for e in WRAPS if e[1] == mode), None)
        cols = kv.pop("colors", None)
        cols = cols.split(",") if cols else (entry[2] if entry else ["#888888"])
        scale = float(kv.pop("scale", entry[3] if entry else 60))
        extra = {k: float(v) for k, v in kv.items()}
        cells = []
        for seed in (1.0, 3.0, 7.0, 11.0):
            img = render_wrap(sr, mode, cols, scale, w, h, extra, seed)
            cells.append((_over(img, plate), f"mode {mode}  seed {seed:g}"))
        sheet(cells, 2, w, h, out, f"UI/Decor/Wrap mode {mode}")
    elif cmd == "stickers":
        # optional: pack=a,b (only those packs), size=96 (cell px), grime=0.6 (wear on every sticker), cols=8
        kv = dict(a.split("=", 1) for a in sys.argv[3:])
        ids = set(kv["ids"].split(",")) if kv.get("ids") else None
        want = set(kv["pack"].split(",")) if kv.get("pack") else ({i.split("/")[0] for i in ids} if ids else None)
        size = int(kv.get("size", 160))
        cols = int(kv.get("cols", 8))
        grime = float(kv.get("grime", 0.0))
        cells = []
        for i, name in enumerate(SHAPES):
            if want is not None:
                break
            cs = SHAPE_COLORS[i]
            props = {"_Shape": float(i), "_C0": _color(cs[0]), "_C1": _color(cs[1]), "_C2": _color(cs[2]),
                     "_Peel": 0.3 if name in ("circle", "bolt") else 0.0, "_Grime": grime}
            img = render_sticker(sr, props, size)
            cells.append((_over(img, np.array([0.18, 0.2, 0.22])), name))
        # DSD_STICKER_OUT = the scratch folder Tools/decor_stickers.py was pointed at (art not shipped yet)
        decor = Path(os.environ["DSD_STICKER_OUT"]) if os.environ.get("DSD_STICKER_OUT") else ROOT / "Assets" / "Resources" / "Decor"
        man = decor / "stickers.json"
        if man.exists():
            from slrender.render import TextureSpec
            doc = json.loads(man.read_text(encoding="utf-8"))
            for pack in doc.get("packs", []):
                if want is not None and pack["id"] not in want:
                    continue
                # one flipbook PNG per pack since 2026-10-11 (Tools/decor_stickers.py); slice indexes are pack-local
                arr = decor / "Packs" / (pack["id"] + ".png")
                if not arr.exists():
                    continue
                for s in pack.get("stickers", []):
                    if ids is not None and (pack["id"] + "/" + s["id"]) not in ids:
                        continue
                    props = {"_ArtSlice": float(s["slice"]), "_ArtLayers": float(s.get("layers", 4)),
                             "_ArtSpread": float(doc.get("spread", 0.0625)), "_ArtSize": 0.84,
                             "_Ink": float(s.get("ink", 0)), "_Grime": grime, "_Seed": 1.0 + len(cells) * 0.37}
                    for k, c in enumerate(s.get("colors", [])[:4]):
                        props["_C%d" % k] = _color(c)
                    img = sr.r.render("UI/Decor/Sticker", dict({"_Color": (1, 1, 1, 1), "_Border": 0.06}, **props),
                                      (size, size), {}, bg=(0, 0, 0, 0),
                                      textures={"_StickerArt": TextureSpec(data=str(arr), grid=(doc.get("columns", 8), pack.get("rows", 8)))})
                    cells.append((_over(img, np.array([0.18, 0.2, 0.22])), pack["id"] + "/" + s["id"] + (" PRO" if s.get("pro") else "")))
        sheet(cells, cols, size, size, out, "UI/Decor/Sticker — albedo")
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
