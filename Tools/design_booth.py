#!/usr/bin/env python3
"""
design_booth — the party BOOTH SIGN plates (Docs/Decor.md §10).

A sign is three plates stacked in one layout view (Views/BoothSign.cs):
  FRAME  — any shipped faceplate skin (walnut, brass, silver, carbon...), chosen per sign;
  BOARD  — the face when the sign is a plain board: BoothBoard, recoloured live per sign
           (SetMaterialColor _PanelColor), with an optional surface texture (paper, linen...);
  GLASS  — BoothGlass, OVER the picture: a plate that draws nothing of its own (_PanelRenderAlpha 0),
           so only the decor bound to it shows — paint and stickers on top of a video. SDFPanel already
           composites with lerp(panelAlpha, 1, decor.cov), so a clear plate is opaque exactly where
           paint covers it.

    python Tools/design_booth.py          # write both skins
    python Tools/design_booth.py sheet    # + render them (board over a few colours/surfaces)
"""
import sys

from skinlib import BOUNDS, skin

# Everything the shader would otherwise inherit from the source material, said out loud: an unset guard
# takes the MATERIAL's value, not the shader default (skill: "every effect guard is written").
QUIET = {
    "_PanelBevelEnabled": 0, "_PanelRimEnabled": 0, "_PanelGradientEnabled": 0,
    "_PanelScrewsEnabled": 0, "_EdgeEnabled": 0, "_BorderEnabled": 0,
    "_PanelShadow1Enabled": 0, "_PanelShadow2Enabled": 0, "_PanelShadow3Enabled": 0,
    "_LightingShadow1Enabled": 0, "_PanelRenderEmissive": 0, "_PanelFaceSmoothness": 0,
}


def glass():
    base = {
        "_PanelEnabled": 1,
        "_PanelColor": (0.0, 0.0, 0.0, 0.0),
        "_PanelRenderAlpha": 0.0,
        "_PanelShapeType": 0,
        "_PanelShapeParam1": 0.9,
        "_PanelBodyRoundness": 1.0,
        "_PanelCornerRadiusPx": 3,
        "_PanelPadding": 0.0,
        "_PanelPaddingPx": 0.01,
        "_PanelPatternEnabled": 0,
        "_LightingAmbient": 0.9,
        **QUIET,
    }
    return skin("BoothGlass", "Panel", base, bounds=BOUNDS["panel"])


def board():
    base = {
        "_PanelEnabled": 1,
        "_PanelColor": (0.93, 0.92, 0.89, 1.0),
        "_PanelRenderAlpha": 1.0,
        "_PanelShapeType": 0,
        "_PanelShapeParam1": 0.9,
        "_PanelBodyRoundness": 1.0,
        "_PanelCornerRadiusPx": 3,
        "_PanelPadding": 0.0,
        "_PanelPaddingPx": 0.01,
        # A surface you can feel: a texture layer (Materials v2), pixel-locked so a sign reads the same at
        # every size. BoothSign swaps the layer (paper / linen / velvet / plaster / frost / smooth) live.
        "_PanelPatternEnabled": 1,
        "_PanelPatternType": 20,
        "_PanelPatternParam1": 12,          # paper
        "_PanelPatternParam2": 0.0,
        "_PanelPatternParam3": 0.0,
        "_PanelPatternScale": 2,
        "_PanelPatternPx": 260,
        "_PanelPatternIntensity": 0.22,
        "_PanelPatternContrast": 1.0,
        "_PanelPatternSpecularEffect": 0.3,
        "_PanelPatternRoughnessEffect": 0.4,
        "_LightingAmbient": 0.62,
        **QUIET,
    }
    return skin("BoothBoard", "Panel", base, bounds=BOUNDS["panel"])


def sheet():
    from pathlib import Path
    from PIL import Image, ImageDraw
    from skinsheet import OUT, render
    from skinlib import path
    cells = []
    colours = [(0.93, 0.92, 0.89, 1), (0.08, 0.09, 0.10, 1), (0.10, 0.22, 0.16, 1), (0.95, 0.35, 0.55, 1)]
    layers = [(12, "paper"), (5, "linen"), (4, "velvet"), (11, "plaster")]
    for ci, c in enumerate(colours):
        for li, (layer, name) in enumerate(layers):
            cells.append({"id": f"board_{ci}_{name}", "states": path("BoothBoard"), "w": 320, "h": 180,
                          "set": {"_PanelColor": ",".join(str(v) for v in c), "_PanelPatternParam1": layer}})
    cells.append({"id": "glass", "states": path("BoothGlass"), "w": 320, "h": 180})
    r = render(cells)
    print("rendered", r.get("ok"), "fail", r.get("fail"), str(r.get("log", ""))[:300])
    ims = [(c["id"], Image.open(OUT / (c["id"] + ".png")).convert("RGBA")) for c in cells if (OUT / (c["id"] + ".png")).exists()]
    W, H, cols = 340, 210, 4
    S = Image.new("RGB", (cols * W, ((len(ims) + cols - 1) // cols) * H), (40, 70, 50))
    d = ImageDraw.Draw(S)
    for i, (n, im) in enumerate(ims):
        x, y = (i % cols) * W + 10, (i // cols) * H + 5
        S.paste(im, (x, y), im)
        d.text((x, y + 184), n, fill=(255, 255, 255))
    out = Path(sys.argv[2]) if len(sys.argv) > 2 else OUT / "booth_sheet.png"
    S.save(out)
    print("sheet", out)


if __name__ == "__main__":
    glass()
    board()
    print("wrote BoothGlass, BoothBoard")
    if len(sys.argv) > 1 and sys.argv[1] == "sheet":
        sheet()
