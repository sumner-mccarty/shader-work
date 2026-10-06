#!/usr/bin/env python3
"""
The Realistic mixer FACEPLATES, dark (authored RackFaceplate*) vs light (baked swaps), at module size.

sheet_rack.py draws the generic `RealisticFace` part, but the mixer's modules each wear their own
authored RackFaceplate<Colour> skin (and Realistic Light re-finishes them through its recipe's
`swaps` -> the authored RackFaceplate<Colour>Light files), so a material change to those — enamel paint in dark, brushed metal in light — never
showed up in the rack sheet. This renders exactly those files.

    python Tools/sheet_faceplates.py [tag]
"""
import sys
from skinlib import path
from skinsheet import OUT, render

W, H = 620, 170
COLOURS = ["Graphite", "Blue", "Cream", "Rust"]


def main(tag="faceplates"):
    cells = []
    for mode in ("dark", "light"):
        for c in COLOURS:
            name = "RackFaceplate" + c
            # Light re-finishes each plate by NAME (Realistic.style.json swaps -> <name>Light).
            src = path(name if mode == "dark" else name + "Light")
            cells.append({"id": f"fp-{mode}-{c}", "states": src, "w": W, "h": H, "ss": 1,
                          "bg": "#1B1E22" if mode == "dark" else "#C9CDD2"})
    render(cells)
    from PIL import Image, ImageDraw
    sheet = Image.new("RGB", (W * 2 + 30, (H + 10) * len(COLOURS) + 10), (40, 42, 46))
    for i, mode in enumerate(("dark", "light")):
        for j, c in enumerate(COLOURS):
            im = Image.open(OUT / f"fp-{mode}-{c}.png").convert("RGBA")
            sheet.paste(im, (10 + i * (W + 10), 10 + j * (H + 10)), im)
    dst = OUT.parent / f"{tag}.png"
    sheet.save(dst)
    print("  ->", dst)


if __name__ == "__main__":
    main(*sys.argv[1:])
