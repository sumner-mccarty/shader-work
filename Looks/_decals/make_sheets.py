"""Render a contact sheet for a decal generator: python Looks/_decals/make_sheets.py splat|spray|brush
Rows: 256 px on a dark plate, 256 px on a light plate, 64 px dark, 64 px light. Variants are below."""
import sys
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from slrender.skins import SkinRenderer, parse_color  # noqa: E402

DARK, LIGHT = "#1A1D22", "#D9DCE0"

def P(*pts):  # (x, y, pressure) -> float4 props
    return {f"_P{i}": (x, y, p, 0.0) for i, (x, y, p) in enumerate(pts)} | {"_PointCount": float(len(pts))}

def inside(props, width=0.09):
    """Brush strokes: fit the points into [m, 1-m] with m = 1.3 x the half-width so no stroke touches its quad edge."""
    m = 1.3 * props.get("_Width", width)
    keys = [k for k in props if k.startswith("_P") and k[2:].isdigit()]
    xs = [props[k][0] for k in keys]; ys = [props[k][1] for k in keys]
    x0, x1, y0, y1 = min(xs), max(xs), min(ys), max(ys)
    sc = (1 - 2 * m) / max(x1 - x0, y1 - y0, 1e-6)
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    out = dict(props)
    for k in keys:
        x, y, pr, z = props[k]
        out[k] = (0.5 + (x - cx) * sc, 0.5 + (y - cy) * sc, pr, z)
    return out

VARIANTS = {
    "splat": ("UI/Decal/Splat", [
        ("seed 1 pink",      {"_Seed": 1, "_Color": "#F21F61"}),
        ("seed 7 cyan up",   {"_Seed": 7, "_Color": "#14B8E6", "_ThrowAngle": 70, "_Drips": 0.7}),
        ("seed 12 yellow",   {"_Seed": 12, "_Color": "#FFC800", "_ThrowAngle": 200, "_Directional": 0.9, "_Reach": 0.9}),
        ("burst green",      {"_Seed": 3, "_Color": "#3DDC6A", "_Directional": 0.0, "_Streaks": 0.9, "_Drips": 0.3, "_Reach": 0.6}),
        ("big white drippy", {"_Seed": 21, "_Color": "#F2F2F2", "_Size": 0.38, "_Drips": 1.0, "_DripLen": 0.8, "_Satellites": 0.4}),
        ("reveal 0.4",       {"_Seed": 1, "_Color": "#F21F61", "_Reveal": 0.4}),
    ]),
    "spray": ("UI/Decal/Spray", [
        ("s-curve",  {"_Seed": 1, "_Color": "#FFD400", **P((0.08, 0.8, 1.0), (0.3, 0.3, 0.9), (0.55, 0.7, 0.7), (0.9, 0.2, 0.4))}),
        ("loose",    {"_Seed": 5, "_Color": "#F21F61", "_Overspray": 1.0, "_Width": 0.2, **P((0.1, 0.5, 0.8), (0.5, 0.55, 1.0), (0.9, 0.45, 0.6))}),
        ("tight",    {"_Seed": 9, "_Color": "#14B8E6", "_Overspray": 0.25, "_Width": 0.07, "_Softness": 0.25, **P((0.1, 0.2, 1.0), (0.4, 0.5, 1.0), (0.7, 0.55, 1.0), (0.92, 0.85, 1.0))}),
        ("6 pts",    {"_Seed": 2, "_Color": "#3DDC6A", **P((0.1, 0.15, 0.4), (0.25, 0.7, 0.8), (0.4, 0.2, 1.0), (0.6, 0.8, 1.0), (0.75, 0.25, 0.7), (0.92, 0.7, 0.3))}),
        ("white",    {"_Seed": 4, "_Color": "#F2F2F2", **P((0.1, 0.9, 0.3), (0.5, 0.5, 1.0), (0.9, 0.1, 0.3))}),
        ("2 pts",    {"_Seed": 6, "_Color": "#FF7A00", "_Width": 0.16, **P((0.15, 0.5, 1.0), (0.85, 0.5, 0.6))}),
    ]),
    "brush": ("UI/Decal/Brush", [
        ("sweep",    {"_Seed": 1, "_Color": "#F21F61", **P((0.08, 0.7, 1.0), (0.35, 0.35, 1.0), (0.65, 0.6, 0.9), (0.92, 0.3, 0.6))}),
        ("dry",      {"_Seed": 5, "_Color": "#14B8E6", "_DryBrush": 0.9, **P((0.08, 0.5, 1.0), (0.5, 0.45, 0.9), (0.92, 0.55, 0.5))}),
        ("wet",      {"_Seed": 9, "_Color": "#FFC800", "_DryBrush": 0.1, "_Width": 0.2, **P((0.1, 0.2, 0.8), (0.5, 0.5, 1.0), (0.9, 0.8, 0.8))}),
        ("6 pts",    {"_Seed": 2, "_Color": "#3DDC6A", **P((0.1, 0.15, 0.6), (0.25, 0.7, 1.0), (0.4, 0.2, 1.0), (0.6, 0.8, 1.0), (0.75, 0.25, 0.8), (0.92, 0.7, 0.4))}),
        ("white",    {"_Seed": 4, "_Color": "#F2F2F2", "_Bristles": 44, "_Streakiness": 0.8, **P((0.1, 0.9, 0.9), (0.5, 0.5, 1.0), (0.9, 0.1, 0.5))}),
        ("2 pts",    {"_Seed": 6, "_Color": "#FF7A00", "_Width": 0.24, **P((0.15, 0.5, 1.0), (0.85, 0.5, 0.5))}),
    ]),
}

def main():
    name = sys.argv[1]
    shader, variants = VARIANTS[name]
    if name == "brush":
        variants = [(l, inside(p)) for l, p in variants]
    sr = SkinRenderer(ROOT, orientation="screen")
    rows = [(256, DARK), (256, LIGHT), (64, DARK), (64, LIGHT)]
    n = len(variants)
    pad, lab = 6, 14
    W = pad + n * (256 + pad)
    H = pad + sum(s + pad for s, _ in rows) + lab
    sheet = Image.new("RGB", (W, H), "#0B0D10")
    dr = ImageDraw.Draw(sheet)
    y = pad
    for size, bg in rows:
        for i, (lbl, props) in enumerate(variants):
            pr = {k: (parse_color(v) if isinstance(v, str) else v) for k, v in props.items()}
            img = sr.r.render(shader, pr, (size, size), bg=parse_color(bg), orientation="screen")
            x = pad + i * (256 + pad)
            sheet.paste(Image.fromarray(np.asarray(img)[..., :3]), (x, y))
            if size == 256 and bg == DARK:
                pass
        y += size + pad
    for i, (lbl, _) in enumerate(variants):
        dr.text((pad + i * (256 + pad) + 2, y), lbl, fill="#9AA5B1")
    out = ROOT / "Looks" / "_decals" / f"{name}.png"
    sheet.save(out, optimize=True)
    print(out, sheet.size, out.stat().st_size // 1024, "KB")

main()
