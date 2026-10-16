# Sticker packs — one file per pack

New sticker packs live here, one file per pack: `Tools/sticker_packs/<pack>.py`. `Tools/decor_stickers.py` runs every
file in this folder inside its own namespace (files starting with `_` are skipped), so **all its drawing helpers are in
scope with no imports**. Authors never edit `decor_stickers.py`, `PACKS` or `PRO`, so parallel sessions never collide.

Spec for what a sticker IS in the app: `Docs/Decor.md` §2.2, §4 (Sticker COLORS), §7b (packs as content).

## A pack file

```python
PACK = ("skate", "Skate & Surf", False)        # (id, title shown to players, always False)
PRO_IDS = {"board", "wave", "ramp", "helmet", "wax"}   # the showiest ~THIRD of the pack (see Pro below)


@sticker("skate", "board", "Skateboard", ["#FF4F2E", "#B8321A", "#FFE9C7", "#1A1410"], ink=1.0)
def _():
    deck = box(0, 0, 0.82, 0.24, r=0.24, ang=0.5)
    shade = inter(deck, -(X * 0.5 + Y * 0.86) - 0.05)      # lower-right half of the deck
    grip = box(0, 0, 0.7, 0.13, r=0.12, ang=0.5)
    wheels = U(circle(-0.5, -0.12, 0.11), circle(0.5, 0.42, 0.11))
    return [deck, shade, grip, wheels]
```

* **ids**: pack id lowercase letters only, unique (taken: street sweets music space retro animals food faces nature arcade
  gear roadie mystic hiphop). Sticker ids lowercase, unique in the pack. **Never rename or delete an id once shipped.**
* **title**: Title Case, US spelling (Color, not Colour), ≤ 14 characters.
* **colors**: one hex per layer, in the same order as the returned layers.
* **ink**: `1.0` = the house dark keyline round the art (almost every shipped sticker); `0.0` = none.
* **16–20 stickers per pack.** Shipped packs have 12–24.

## The art

* A sticker function returns **up to 4 signed-distance layers** (numpy arrays, negative inside), painted in order: the
  first is the bottom (the body), the last is on top. Coordinates: the slice is `[-1, 1]²`, **y up**, `X`/`Y` are the
  pixel-coordinate grids. Keep the art inside ~0.92 — the white die-cut border needs the margin.
* **Each layer is a COLOR SLOT the player can recolor** (Skin Mode ▸ stickers ▸ COLORS). So a layer must be a meaningful,
  separately colorable PART (body, shade, shine, eyes, trim, label…), and the sticker must still read when any slot gets
  another color.
* **Name the variables you return** — the app shows them as the slot tooltips ("Color 2 — shade"). Use plain words
  (`body`, `shade`, `shine`, `trim`, `eyes`, `wheels`); an expression in the return list shows only as "Color N".
* House style (look at the shipped packs): bold flat shapes, a dark keyline, ONE shade layer (lower-right) and ONE
  highlight (upper-left — the light comes from top-left), chunky details. No hairlines: anything thinner than ~0.04 is
  lost at 32 units.
* Helpers: `circle ellipse oval box seg taper polyline poly star ring arc bezier heart regpoly crescent petals spline brush
  rotp pix stripes text` to make shapes; `U` (union), `sub(a, b)` (a minus b), `inter(a, b)`, `smin` (soft union), `shell(d, t)`
  (outline), `d - 0.04` grows a shape, `d + 0.04` shrinks it. `text(s, cx, cy, h)` sets short words in the house
  font — keep words ≤ 6 characters.
* **Never** name or imitate a real brand, logo, product, band, artist, mascot or character. Generic is the point.

## Pro
About a third of each pack is Pro (`PRO_IDS`) — the showiest, most detailed pieces. The free two-thirds must still be a
complete, good pack on its own. Watching someone else's Pro sticker is free; only keeping one needs Pro.

## Render and look

```bash
export SLRENDER_SOFTWARE=1 PYTHONIOENCODING=utf-8
DSD_STICKER_OUT=.out/<pack> python Tools/decor_stickers.py --only <pack>          # scratch build, never the shipped files
DSD_STICKER_OUT=.out/<pack> python Tools/decorsheet.py stickers Looks/_stickers/<pack>-96.png pack=<pack> size=96 cols=8
DSD_STICKER_OUT=.out/<pack> python Tools/decorsheet.py stickers Looks/_stickers/<pack>-32.png pack=<pack> size=32 cols=10
python Tools/decorsheet.py stickers .out/family.png size=40 cols=24              # every SHIPPED pack, for comparison
```

* The generator prints `fitted to the slice (scaled)` for art it shrank to keep the die-cut margin (fine) and a
  **tight** list for art already clipped by the slice edge — redraw those smaller.
* Judge at **32** — that is a sticker on a real plate. The 96 sheet is for craft.
* Commit only your pack file and its `Looks/_stickers/<pack>-*.png` sheets. **Never commit** `.out/`,
  `Assets/Resources/Decor/` or `Builds/` — the real atlases and the CDN set are built in the Unity project on import.

## On import (not your job)
`decor_stickers.py` in the Unity project gets the same loader; then the packs are built, checked in Play Mode and
published to the CDN (`Tools/publish_stickers.ps1`) — players get them with no client release.
