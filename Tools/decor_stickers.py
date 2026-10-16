#!/usr/bin/env python3
"""
Generate the faceplate-decor STICKER LIBRARY (Docs/Decor.md §2.2): every sticker is drawn here as up to four
signed-distance-field LAYERS (one per RGBA channel). EACH PACK is its own flipbook PNG that Unity imports as a
Texture2DArray — Assets/Resources/Decor/Packs/<pack>.png — plus one manifest, stickers.json (2026-10-11: one shared
atlas was at 58 of 64 slots and every new pack meant a client release).

    python Tools/decor_stickers.py            # write the per-pack atlases + manifest + the publishable CDN set
    python Tools/decor_stickers.py --sheet out.png   # also a quick numpy preview sheet (flat colours)
    python Tools/decor_stickers.py --only animals,food   # just those packs (iterate on art; pair with DSD_STICKER_OUT)
    python Tools/decor_stickers.py --names         # only refresh each sticker's layerNames in the manifest (no pixels)

DSD_STICKER_OUT=<dir> redirects EVERY output (manifest, pack PNGs + .meta, CDN set) into <dir>, so art can be tried out
without touching what ships; Tools/decorsheet.py reads the same variable to render the result through the real shader.

THE CDN SET (Builds/StickerPacks/): index.json + <pack>.<rev>.png. Upload the folder to
cdn.drumsumdrum.com/stickers/ and every client picks up new packs, new stickers in a pack, and Pro/free
re-balancing on its next launch, with no build (see StickerPackStore). <rev> is a hash of the pack's pixels, so a
changed pack is a new file and an old client's cache can never serve stale art.

Why SDF layers: a sticker stays crisp from a 30-unit chip to a 400-unit slab, the die-cut vinyl border and the ink
outline come from the distance itself (UI/Decor/Sticker), and each layer is a COLOUR SLOT — so every sticker is
recolourable by the user and the shader paints the layers in order: R first, A last.

Coordinates: each slice is [-1, 1]^2, y UP, distances in those units, negative inside. Keep art inside ~0.92.
"""
import hashlib
import json
import math
import os
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
if os.environ.get("DSD_STICKER_OUT"):
    OUT_DIR = Path(os.environ["DSD_STICKER_OUT"])
    PUBLISH_DIR = OUT_DIR / "Publish"
else:
    OUT_DIR = ROOT / "Assets" / "Resources" / "Decor"
    PUBLISH_DIR = ROOT / "Builds" / "StickerPacks"
PACKS_DIR = OUT_DIR / "Packs"
TEXT_CACHE = ROOT / "Builds" / ".sticker_cache"       # exact text distance fields are slow (pure-python EDT): keep them
N = 192                 # slice size in px
COLS = 8                # flipbook columns
SPREAD_UV = 0.125       # art-uv distance the 0..1 ramp spans (UI/Decor/Sticker _ArtSpread)
EDGE_CLEARANCE = 0.075  # the die-cut margin in slice units (_Border 0.06 / _ArtSize 0.84): art must keep at least this from the edge
FONT = ROOT / "Assets" / "Fonts" / "pbio-bold.ttf"

_xs = (np.arange(N) + 0.5) / N * 2.0 - 1.0
X, Y = np.meshgrid(_xs, _xs[::-1])          # row 0 = top (PNG), y up
BIG = 9.0


# ── SDF primitives (negative inside) ─────────────────────────────────────────────────────────────────────

def circle(cx, cy, r):
    return np.hypot(X - cx, Y - cy) - r


def ellipse(cx, cy, rx, ry, ang=0.0):
    px, py = _rot(X - cx, Y - cy, -ang)
    k = np.hypot(px / rx, py / ry)
    return (k - 1.0) * min(rx, ry)


def oval(cx, cy, rx, ry, ang=0.0):
    """An ellipse with a first-order DISTANCE field (iq): unlike ellipse() it stays honest far from a long thin shape, so the
    die-cut border and ink outline don't smear along its axis. All art added after 2026-10-11 uses this; the older
    stickers keep ellipse() so they regenerate byte-identical."""
    px, py = _rot(X - cx, Y - cy, -ang)
    k0 = np.hypot(px / rx, py / ry)
    k1 = np.hypot(px / (rx * rx), py / (ry * ry))
    return np.where(k1 < 1e-7, -min(rx, ry), k0 * (k0 - 1.0) / np.maximum(k1, 1e-7))


def _rot(x, y, a):
    c, s = math.cos(a), math.sin(a)
    return c * x - s * y, s * x + c * y


def box(cx, cy, hw, hh, r=0.0, ang=0.0):
    px, py = _rot(X - cx, Y - cy, -ang)
    qx = np.abs(px) - (hw - r)
    qy = np.abs(py) - (hh - r)
    return np.hypot(np.maximum(qx, 0), np.maximum(qy, 0)) + np.minimum(np.maximum(qx, qy), 0) - r


def seg(ax, ay, bx, by, r):
    pax, pay = X - ax, Y - ay
    bax, bay = bx - ax, by - ay
    h = np.clip((pax * bax + pay * bay) / max(bax * bax + bay * bay, 1e-9), 0, 1)
    return np.hypot(pax - bax * h, pay - bay * h) - r


def taper(ax, ay, bx, by, ra, rb):
    pax, pay = X - ax, Y - ay
    bax, bay = bx - ax, by - ay
    h = np.clip((pax * bax + pay * bay) / max(bax * bax + bay * bay, 1e-9), 0, 1)
    return np.hypot(pax - bax * h, pay - bay * h) - (ra + (rb - ra) * h)


def polyline(pts, r):
    d = np.full(X.shape, BIG)
    for (ax, ay), (bx, by) in zip(pts[:-1], pts[1:]):
        d = np.minimum(d, seg(ax, ay, bx, by, r))
    return d


def poly(pts):
    """Exact SDF of a simple polygon (iq), vectorised over the grid."""
    pts = np.asarray(pts, dtype=float)
    n = len(pts)
    d = (X - pts[0, 0]) ** 2 + (Y - pts[0, 1]) ** 2
    s = np.ones(X.shape)
    j = n - 1
    for i in range(n):
        ex, ey = pts[j, 0] - pts[i, 0], pts[j, 1] - pts[i, 1]
        wx, wy = X - pts[i, 0], Y - pts[i, 1]
        t = np.clip((wx * ex + wy * ey) / max(ex * ex + ey * ey, 1e-12), 0, 1)
        bx, by = wx - ex * t, wy - ey * t
        d = np.minimum(d, bx * bx + by * by)
        c1 = Y >= pts[i, 1]
        c2 = Y < pts[j, 1]
        c3 = ex * wy > ey * wx
        flip = (c1 & c2 & c3) | (~c1 & ~c2 & ~c3)
        s = np.where(flip, -s, s)
        j = i
    return s * np.sqrt(d)


def star(cx, cy, n, ro, ri, ang=math.pi / 2):
    pts = []
    for k in range(2 * n):
        r = ro if k % 2 == 0 else ri
        a = ang + k * math.pi / n
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return poly(pts)


def ring(cx, cy, r, t):
    return np.abs(circle(cx, cy, r)) - t


def arc(cx, cy, r, a0, a1, t, steps=40):
    pts = [(cx + r * math.cos(a0 + (a1 - a0) * k / steps), cy + r * math.sin(a0 + (a1 - a0) * k / steps))
           for k in range(steps + 1)]
    return polyline(pts, t)


def bezier(p0, p1, p2, r, steps=40, r1=None):
    pts = []
    for k in range(steps + 1):
        t = k / steps
        x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0]
        y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1]
        pts.append((x, y))
    if r1 is None:
        return polyline(pts, r)
    d = np.full(X.shape, BIG)
    for k, ((ax, ay), (bx, by)) in enumerate(zip(pts[:-1], pts[1:])):
        ra = r + (r1 - r) * k / steps
        rb = r + (r1 - r) * (k + 1) / steps
        d = np.minimum(d, taper(ax, ay, bx, by, ra, rb))
    return d


def heart(cx, cy, s):
    px = np.abs(X - cx) / s
    py = (Y - cy) / s + 0.62
    a = np.hypot(px - 0.25, py - 0.75) - 0.35355339
    bx = px - 0.5 * np.maximum(px + py, 0)
    by = py - 0.5 * np.maximum(px + py, 0)
    c = np.hypot(px, py - 1.0)
    d2 = np.sqrt(np.minimum(c * c, bx * bx + by * by)) * np.sign(px - py)
    return np.where(py + px > 1.0, a, d2) * s


def U(*ds):
    return np.minimum.reduce(ds)


def smin(a, b, k):
    h = np.clip(0.5 + 0.5 * (b - a) / k, 0, 1)
    return b * (1 - h) + a * h - k * h * (1 - h)


def sub(a, b):
    return np.maximum(a, -b)


def inter(a, b):
    return np.maximum(a, b)


def shell(d, t):
    """An outline of thickness t around shape d (centred on its edge)."""
    return np.abs(d) - t


def regpoly(cx, cy, n, r, ang=math.pi / 2):
    """A regular n-gon, first corner at angle ang."""
    return poly([(cx + r * math.cos(ang + 2 * math.pi * k / n), cy + r * math.sin(ang + 2 * math.pi * k / n)) for k in range(n)])


def crescent(cx, cy, r, dx, dy, r2):
    """A moon: circle r at (cx, cy) with circle r2 bitten out of it at (cx + dx, cy + dy)."""
    return sub(circle(cx, cy, r), circle(cx + dx, cy + dy, r2))


def petals(cx, cy, n, dist, rx, ry, ang0=0.0):
    """n elliptical petals round a centre: long axis radial, centre of each `dist` out."""
    ds = []
    for k in range(n):
        a = ang0 + 2 * math.pi * k / n
        ds.append(oval(cx + dist * math.cos(a), cy + dist * math.sin(a), rx, ry, a))
    return np.minimum.reduce(ds)


class rotated:
    """`with rotated(ang, cx, cy):` — draw upright, get it turned (counter-clockwise, radians) about (cx, cy). Every primitive
    reads this module's X/Y sample grids, so swapping those for a rotated copy turns whatever is drawn inside the block.
    (text() rasterises on its own grid: give it its own ang.)"""

    def __init__(self, ang, cx=0.0, cy=0.0, mx=0.0, my=0.0):
        self.ang, self.cx, self.cy, self.mx, self.my = ang, cx, cy, mx, my     # (mx, my): then slide the result by this much

    def __enter__(self):
        global X, Y
        self._saved = (X, Y)
        c, s = math.cos(self.ang), math.sin(self.ang)
        dx, dy = X - self.mx - self.cx, Y - self.my - self.cy
        X, Y = self.cx + c * dx + s * dy, self.cy - s * dx + c * dy       # sample the upright drawing at the inverse transform
        return self

    def __exit__(self, *exc):
        global X, Y
        X, Y = self._saved
        return False


def spline(pts, closed=True, n=10):
    """Catmull-Rom through the points → a dense point list for poly() / polyline() (organic outlines: lips, leaves, ears)."""
    pts = [tuple(p) for p in pts]
    m = len(pts)
    out = []
    segs = m if closed else m - 1
    for i in range(segs):
        p0 = pts[(i - 1) % m] if (closed or i > 0) else pts[0]
        p1 = pts[i]
        p2 = pts[(i + 1) % m]
        p3 = pts[(i + 2) % m] if (closed or i + 2 < m) else pts[-1]
        for k in range(n):
            t = k / n
            t2, t3 = t * t, t * t * t
            out.append(tuple(0.5 * ((2 * p1[j]) + (-p0[j] + p2[j]) * t + (2 * p0[j] - 5 * p1[j] + 4 * p2[j] - p3[j]) * t2
                                    + (-p0[j] + 3 * p1[j] - 3 * p2[j] + p3[j]) * t3) for j in (0, 1)))
    if not closed:
        out.append(pts[-1])
    return out


def brush(pts, widths, closed=False, n=8):
    """A stroke along a smooth path whose half-width varies: pts = [(x, y)…] through which a spline runs, widths = a half-width
    per point (interpolated along it). Tentacles, tails, cables, vines."""
    p3 = [(p[0], p[1]) for p in pts]
    dense = spline(p3, closed=closed, n=n)
    segs = len(p3) if closed else len(p3) - 1
    ws = []
    for i in range(segs):
        w0, w1 = widths[i], widths[(i + 1) % len(widths)]
        for k in range(n):
            ws.append(w0 + (w1 - w0) * k / n)
    if not closed:
        ws.append(widths[-1])
    d = np.full(X.shape, BIG)
    for i in range(len(dense) - 1):
        d = np.minimum(d, taper(dense[i][0], dense[i][1], dense[i + 1][0], dense[i + 1][1], ws[i], ws[i + 1]))
    return d


def rotp(pts, ang, ox=0.0, oy=0.0):
    """Rotate a list of points about (ox, oy) by ang radians (counter-clockwise, y up)."""
    c, s = math.cos(ang), math.sin(ang)
    return [(ox + c * (x - ox) - s * (y - oy), oy + s * (x - ox) + c * (y - oy)) for x, y in pts]


def pix(rows, cx, cy, cell):
    """Pixel art: rows of '#' (filled) and '.', centred on (cx, cy), each cell `cell` units across. Rasterised and run through
    the same exact distance transform as text() (a union of boxes has a shallow field along every seam, and the ink outline
    then draws a hairline there)."""
    key = repr(("pix", tuple(rows), cx, cy, cell, N))
    disk = TEXT_CACHE / (hashlib.sha1(key.encode()).hexdigest()[:20] + ".npy")
    if disk.exists():
        return np.load(disk)
    R = 3
    W = N * R
    h, w = len(rows), max(len(r) for r in rows)
    m = np.zeros((W, W), dtype=bool)
    for j, row in enumerate(rows):
        for i, ch in enumerate(row):
            if ch != '#':
                continue
            x0 = cx + (i - w / 2) * cell
            y1 = cy + (h / 2 - j) * cell
            c0, c1 = int(round((x0 + 1) / 2 * W)), int(round((x0 + cell + 1) / 2 * W))
            r0, r1 = int(round((1 - (y1 + 1) / 2) * W)), int(round((1 - (y1 - cell + 1) / 2) * W))
            m[max(r0, 0):max(r1, 0), max(c0, 0):max(c1, 0)] = True
    sd = (_edt(m) - _edt(~m)) / (W / 2)
    sd = sd[R // 2::R, R // 2::R]
    TEXT_CACHE.mkdir(parents=True, exist_ok=True)
    np.save(disk, sd)
    return sd


def pixsub(rows, keep):
    """The cells of `rows` for which keep(i, j, w, h) holds — a shading or highlight layer cut from the same bitmap."""
    h, w = len(rows), max(len(r) for r in rows)
    return ["".join('#' if ch == '#' and keep(i, j, w, h) else '.' for i, ch in enumerate(r)) for j, r in enumerate(rows)]


def stripes(period, ang, width, off=0.0):
    """Diagonal bands: negative inside a band `width` wide (fraction of period), repeating every `period` units."""
    c, s = math.cos(ang), math.sin(ang)
    f = (((X * c + Y * s + off) / period) % 1.0) - 0.5
    return np.abs(f) * period - width * period / 2


# ── text: rasterise with the app's display face, then an exact Euclidean distance transform ──────────────

def _edt_1d(f):
    n = f.shape[-1]
    out = np.empty_like(f)
    for row in range(f.shape[0]):
        fr = f[row]
        v = np.zeros(n, dtype=int)
        z = np.zeros(n + 1)
        k = 0
        v[0] = 0
        z[0], z[1] = -np.inf, np.inf
        for q in range(1, n):
            s = ((fr[q] + q * q) - (fr[v[k]] + v[k] * v[k])) / (2 * q - 2 * v[k])
            while s <= z[k]:
                k -= 1
                s = ((fr[q] + q * q) - (fr[v[k]] + v[k] * v[k])) / (2 * q - 2 * v[k])
            k += 1
            v[k] = q
            z[k] = s
            z[k + 1] = np.inf
        k = 0
        for q in range(n):
            while z[k + 1] < q:
                k += 1
            out[row, q] = (q - v[k]) ** 2 + fr[v[k]]
    return out


def _edt(mask):
    inf = 1e10
    f = np.where(mask, 0.0, inf)
    d = _edt_1d(f)
    d = _edt_1d(d.T.copy()).T
    return np.sqrt(d)


_text_cache = {}


def text(s, cx, cy, h, ang=0.0, font=FONT, stretch=1.0, maxw=1.5):
    """SDF of a word set in the app's display face, centred at (cx, cy), cap height ~h, rotated ang,
    shrunk if needed so it is no wider than maxw (units of the [-1, 1] slice)."""
    key = (s, cx, cy, h, ang, stretch, maxw, str(font))
    if key in _text_cache:
        return _text_cache[key]
    stamp = f"{Path(font).stat().st_mtime_ns}"
    disk = TEXT_CACHE / (hashlib.sha1((repr(key) + stamp + str(N)).encode()).hexdigest()[:20] + ".npy")
    if disk.exists():
        _text_cache[key] = np.load(disk)
        return _text_cache[key]
    R = 4                       # raster at 4x the slice
    W = N * R
    img = Image.new("L", (W, W), 0)
    dr = ImageDraw.Draw(img)
    size = int(h * W / 2 * 1.38)
    f = ImageFont.truetype(str(font), size)
    bb = dr.textbbox((0, 0), s, font=f)
    tw, th = bb[2] - bb[0], bb[3] - bb[1]
    limit = maxw * W / 2 / max(stretch, 1e-3)
    if tw > limit:
        size = max(8, int(size * limit / tw))
        f = ImageFont.truetype(str(font), size)
        bb = dr.textbbox((0, 0), s, font=f)
        tw, th = bb[2] - bb[0], bb[3] - bb[1]
    tmp = Image.new("L", (tw + 8, th + 8), 0)
    ImageDraw.Draw(tmp).text((4 - bb[0], 4 - bb[1]), s, font=f, fill=255)
    if stretch != 1.0:
        tmp = tmp.resize((max(1, int(tmp.width * stretch)), tmp.height), Image.LANCZOS)
    if ang:
        tmp = tmp.rotate(math.degrees(ang), resample=Image.BICUBIC, expand=True)
    px = int((cx + 1) / 2 * W - tmp.width / 2)
    py = int((1 - (cy + 1) / 2) * W - tmp.height / 2)
    img.paste(tmp, (px, py), tmp)
    m = np.asarray(img) > 127
    # downsample the signed distance to the slice grid (centres of each R x R block)
    inside = _edt(~m)
    outside = _edt(m)
    sd = (outside - inside) / (W / 2)           # units of [-1, 1]
    sd = sd[R // 2::R, R // 2::R]
    _text_cache[key] = sd
    TEXT_CACHE.mkdir(parents=True, exist_ok=True)
    np.save(disk, sd)
    return sd


# ── the library ──────────────────────────────────────────────────────────────────────────────────────────

STICKERS = []          # (pack, id, title, layers[], colors[], ink)


def sticker(pack, sid, title, colors, ink=0.0):
    def deco(fn):
        STICKERS.append((pack, sid, title, fn, colors, ink))
        return fn
    return deco


# Each layer's name for the paint dock's COLORS slot tooltips ("Color 2 — shade"): the variable the art returns it as,
# tidied for players (US spelling). A layer returned as an expression stays "" and shows as plain "Color N".
LAYER_NAME_FIX = {"f": "face", "feat": "features", "cran": "skull", "btn": "button", "btns": "buttons", "cab": "cabinet",
                  "centre": "center", "num": "number", "plat": "platter", "refl": "reflection", "yel": "yellow",
                  "ringshade": "ring shade", "starr": "star", "st": "star", "pep": "pepperoni", "pet": "petals", "zz": "zzz",
                  "ms": "mountains", "pl": "planet", "sq": "square", "tri": "triangle", "allv": "leaves", "mid": "middle"}
LAYER_NAME_DROP = {"r1", "r2", "r3"}


def layer_names(fn):
    """The names of the layers ``fn`` returns, aligned with its return list (None where a layer has no name)."""
    import ast
    import inspect
    import textwrap
    try:
        tree = ast.parse(textwrap.dedent(inspect.getsource(fn)))
    except (OSError, SyntaxError):
        return []
    rets = [n for n in ast.walk(tree) if isinstance(n, ast.Return)]
    if not rets or not isinstance(rets[-1].value, ast.List):
        return []
    out = []
    for e in rets[-1].value.elts:
        name = e.id.strip("_").replace("_", " ") if isinstance(e, ast.Name) else None
        name = LAYER_NAME_FIX.get(name, name)
        out.append(None if name in LAYER_NAME_DROP else name)
    return out


def named_layers(fn):
    """``fn``'s layers (Nones dropped, at most the shader's four) and their names, kept in step."""
    raw = fn()
    names = layer_names(fn)
    kept = [(l, names[i] if i < len(names) else None) for i, l in enumerate(raw) if l is not None][:4]
    return [l for l, _ in kept], [n or "" for _, n in kept]


def patch_layer_names(path):
    """Write ``layerNames`` into an existing manifest WITHOUT re-rendering a pixel (the packs and their revs stay put)."""
    manifest = json.loads(Path(path).read_text(encoding="utf-8"))
    by_id = {(p, s): fn for p, s, _t, fn, _c, _i in STICKERS}
    named = 0
    for pack in manifest["packs"]:
        for st in pack["stickers"]:
            fn = by_id.get((pack["id"], st["id"]))
            if fn is None:
                continue
            layers, names = named_layers(fn)
            if len(layers) != st.get("layers"):
                sys.exit(f"{pack['id']}/{st['id']}: art has {len(layers)} layers, the manifest {st.get('layers')} — run a full build")
            st["layerNames"] = names
            named += sum(1 for n in names if n)
    Path(path).write_text(json.dumps(manifest, indent=1), encoding="utf-8")
    print(f"layer names written to {path} ({named} named layers)")


# ---- STREET (free pack; Pro picks in PRO) ------------------------------------------------------------------

@sticker("street", "star", "Star", ["#FFC531", "#FF8A00", "#FFF4C7", "#1A1410"], ink=1.0)
def _():
    body = star(0, -0.02, 5, 0.9, 0.4) - 0.04
    shade = inter(body, X * 0.6 + Y * -0.8 - 0.05 - 0.0)
    shine = U(seg(-0.22, 0.32, -0.08, 0.5, 0.05), circle(-0.3, 0.2, 0.05))
    return [body, shade, shine]


@sticker("street", "bolt", "Lightning", ["#FFE14A", "#FF9F1C", "#FFFFFF"], ink=1.0)
def _():
    pts = [(-0.18, 0.92), (0.55, 0.92), (0.14, 0.2), (0.52, 0.2), (-0.36, -0.92), (-0.04, -0.06), (-0.5, -0.06)]
    body = poly(pts) - 0.04
    shade = inter(body, X + 0.15)
    shine = seg(0.0, 0.78, 0.3, 0.78, 0.04)
    return [body, shade, shine]


@sticker("street", "skull", "Skull", ["#F4F1EA", "#C9C3B6", "#15131A"], ink=1.0)
def _():
    cran = U(circle(0, 0.18, 0.66), box(0, -0.42, 0.38, 0.3, 0.12))
    shade = inter(cran, circle(0.25, 0.0, 0.85) * -1)
    eyes = U(ellipse(-0.27, 0.12, 0.2, 0.22, 0.2), ellipse(0.27, 0.12, 0.2, 0.22, -0.2))
    nose = poly([(0, -0.1), (-0.09, -0.28), (0.09, -0.28)])
    teeth = U(*[box(x, -0.56, 0.012, 0.13) for x in (-0.18, 0.0, 0.18)], box(0, -0.43, 0.32, 0.012))
    holes = U(eyes, nose - 0.01, teeth)
    return [cran, sub(cran, circle(-0.2, 0.42, 0.62)), holes]


@sticker("street", "flame", "Flame", ["#FF3D2E", "#FF9F1C", "#FFE14A"], ink=1.0)
def _():
    outer = smin(U(circle(0, -0.42, 0.44),
                   bezier((-0.42, -0.4), (-0.55, 0.3), (-0.05, 0.92), 0.2, r1=0.02),
                   bezier((0.4, -0.35), (0.62, 0.15), (0.32, 0.55), 0.18, r1=0.02)), circle(0, -0.1, 0.3), 0.2)
    mid = smin(circle(0, -0.48, 0.3), bezier((-0.18, -0.4), (-0.2, 0.15), (0.05, 0.5), 0.14, r1=0.02), 0.15)
    core = smin(circle(0, -0.55, 0.17), bezier((0, -0.5), (-0.06, -0.2), (0.06, 0.05), 0.08, r1=0.01), 0.1)
    return [outer, mid, core]


@sticker("street", "crown", "Crown", ["#FFC531", "#E09A12", "#FF3D7F", "#1FB6FF"], ink=1.0)
def _():
    body = poly([(-0.78, -0.45), (-0.82, 0.42), (-0.42, 0.05), (0, 0.6), (0.42, 0.05), (0.82, 0.42), (0.78, -0.45)]) - 0.04
    band = inter(body, box(0, -0.38, 0.9, 0.12))
    tips = U(circle(-0.82, 0.46, 0.09), circle(0, 0.66, 0.1), circle(0.82, 0.46, 0.09))
    gems = U(circle(0, -0.38, 0.08), circle(-0.45, -0.38, 0.06), circle(0.45, -0.38, 0.06))
    return [U(body, tips), band, gems, U(circle(0, 0.66, 0.05))]


@sticker("street", "smiley", "Smiley", ["#FFD233", "#F2A900", "#1A1410"], ink=1.0)
def _():
    face = circle(0, 0, 0.86)
    shade = inter(face, -circle(-0.15, 0.15, 0.82))
    feat = U(ellipse(-0.28, 0.2, 0.09, 0.17), ellipse(0.28, 0.2, 0.09, 0.17),
             arc(0, 0.02, 0.5, math.radians(200), math.radians(340), 0.06))
    return [face, shade, feat]


@sticker("street", "peace", "Peace", ["#1FB6FF", "#FFFFFF"], ink=0.0)
def _():
    disc = circle(0, 0, 0.88)
    sign = U(ring(0, 0, 0.62, 0.09), seg(0, 0.62, 0, -0.62, 0.09),
             seg(0, -0.05, -0.44, -0.44, 0.09), seg(0, -0.05, 0.44, -0.44, 0.09))
    return [disc, sign]


@sticker("street", "eightball", "8-Ball", ["#141418", "#FFFFFF", "#141418", "#3A3A44"], ink=0.0)
def _():
    ball = circle(0, 0, 0.88)
    spot = circle(-0.1, 0.18, 0.4)
    eight = text("8", -0.1, 0.17, 0.42)
    rim = inter(ball, -circle(-0.2, 0.25, 0.95))      # a cool rim of reflected light, lower right
    return [ball, spot, eight, rim]


@sticker("street", "eye", "Eye", ["#FFFFFF", "#2EC4B6", "#141418", "#FFFFFF"], ink=1.0)
def _():
    almond = inter(circle(0, -0.55, 1.0), circle(0, 0.55, 1.0))
    iris = inter(circle(0, 0, 0.36), almond)
    pupil = circle(0, 0, 0.16)
    glint = circle(0.1, 0.1, 0.06)
    return [almond, iris, pupil, glint]


@sticker("street", "pow", "POW!", ["#FFE14A", "#FF3D2E", "#FFFFFF", "#141418"], ink=1.0)
def _():
    burst = star(0, 0, 12, 0.92, 0.66, 0.2) - 0.02
    inner = star(0, 0, 12, 0.72, 0.52, 0.45) - 0.02
    word = text("POW!", 0, 0.0, 0.34, ang=0.15, maxw=1.12)
    return [burst, inner, word - 0.035, word]


@sticker("street", "wow", "WOW", ["#FFFFFF", "#141418", "#FF2D6F"], ink=1.0)
def _():
    bubble = U(ellipse(0, 0.12, 0.88, 0.62), poly([(-0.45, -0.3), (-0.05, -0.32), (-0.62, -0.88)]))
    word = text("WOW", 0, 0.14, 0.36, maxw=1.2)
    return [bubble, word]


@sticker("street", "sparkle", "Sparkle", ["#FFFFFF", "#9FE8FF"], ink=0.0)
def _():
    big = star(0.1, 0.1, 4, 0.8, 0.16, math.pi / 2)
    small = star(-0.55, -0.5, 4, 0.32, 0.07, math.pi / 2)
    tiny = star(0.6, -0.55, 4, 0.2, 0.05, math.pi / 2)
    return [U(big, small, tiny), U(star(0.1, 0.1, 4, 0.42, 0.1, math.pi / 2))]


@sticker("street", "ghost", "Ghost", ["#F4F7FB", "#C9D4E3", "#141418"], ink=1.0)
def _():
    body = U(circle(0, 0.25, 0.6), box(0, -0.2, 0.6, 0.45))
    for i, x in enumerate((-0.45, -0.15, 0.15, 0.45)):
        body = sub(body, circle(x, -0.68, 0.15)) if i % 2 else U(body, circle(x, -0.62, 0.15))
    shade = inter(body, X - 0.25)
    feat = U(ellipse(-0.2, 0.32, 0.09, 0.15), ellipse(0.2, 0.32, 0.09, 0.15), ellipse(0, 0.0, 0.12, 0.1))
    return [body, shade, feat]


@sticker("street", "dice", "Dice", ["#FF2D6F", "#C2185B", "#FFFFFF"], ink=1.0)
def _():
    face = box(-0.06, -0.06, 0.66, 0.66, 0.16, 0.18)
    side = sub(box(0.12, 0.12, 0.66, 0.66, 0.16, 0.18), face)
    pips = U(*[circle(-0.06 + dx, -0.06 + dy, 0.1) for dx, dy in [(-0.32, 0.32), (0.32, -0.32), (0, 0), (-0.32, -0.32), (0.32, 0.32)]])
    return [U(face, box(0.12, 0.12, 0.66, 0.66, 0.16, 0.18)), side, pips]


@sticker("street", "flag", "Checkered flag", ["#F4F4F4", "#141418", "#8A8F98"], ink=1.0)
def _():
    pole = seg(-0.72, -0.9, -0.72, 0.85, 0.05)
    cloth = poly([(-0.68, 0.82), (0.25, 0.92), (0.8, 0.75), (0.85, 0.0), (0.2, 0.12), (-0.68, 0.0)])
    gx = np.floor((X + 1) / 0.25)
    gy = np.floor((Y - 0.06 * np.sin(X * 4)) / 0.22 + 10)
    checks = np.where(((gx + gy) % 2) == 0, cloth, BIG)
    return [U(pole, cloth), checks, pole]


@sticker("street", "spraycan", "Spray can", ["#2EC4B6", "#E3172F", "#F4F1EA", "#2B2E33"], ink=1.0)
def _():
    body = U(box(-0.1, -0.22, 0.4, 0.56, 0.07), poly([(-0.5, 0.3), (0.3, 0.3), (0.16, 0.56), (-0.36, 0.56)]))
    cap = U(box(-0.1, 0.72, 0.3, 0.2, 0.07), box(0.34, 0.8, 0.13, 0.06, 0.03))      # the cap, and the nozzle poking out of it
    label = inter(box(-0.1, -0.26, 0.48, 0.24), body)
    mist = U(*[circle(x, y, r) for x, y, r in [(0.62, 0.86, 0.045), (0.74, 0.74, 0.04), (0.78, 0.9, 0.032), (0.58, 0.68, 0.03), (0.68, 0.56, 0.026)]])
    wave = U(bezier((-0.34, -0.26), (-0.22, -0.1), (-0.1, -0.26), 0.03), bezier((-0.1, -0.26), (0.02, -0.42), (0.14, -0.26), 0.03),
             box(-0.1, 0.72, 0.12, 0.06, 0.03), mist)
    return [body, cap, label, wave]


@sticker("street", "bomb", "Bomb", ["#2B2E33", "#8A8F98", "#C98B4B", "#FFE14A"], ink=1.0)
def _():
    body = circle(-0.15, -0.25, 0.6)
    cap = box(0.27, 0.17, 0.16, 0.1, 0.03, -0.78)
    shine = U(oval(-0.42, -0.02, 0.1, 0.2, 0.6), cap)
    fuse = bezier((0.36, 0.26), (0.6, 0.42), (0.42, 0.62), 0.035)
    spark = star(0.5, 0.72, 8, 0.2, 0.08, 0.2)
    return [body, shine, fuse, spark]


@sticker("street", "gem", "Gem", ["#1FB6FF", "#9FE8FF", "#0B6DB8", "#FFFFFF"], ink=1.0)
def _():
    outline = poly([(-0.52, 0.64), (0.52, 0.64), (0.84, 0.24), (0, -0.86), (-0.84, 0.24)])
    light = U(poly([(-0.52, 0.64), (-0.16, 0.64), (-0.34, 0.24), (-0.84, 0.24)]), poly([(-0.84, 0.24), (-0.34, 0.24), (0, -0.86)]))
    dark = U(poly([(0.16, 0.64), (0.52, 0.64), (0.84, 0.24), (0.34, 0.24)]), poly([(0.34, 0.24), (0.84, 0.24), (0, -0.86)]))
    glint = U(star(-0.34, 0.46, 4, 0.16, 0.035, math.pi / 2), circle(-0.55, 0.3, 0.035))
    return [outline, light, dark, glint]


@sticker("street", "skateboard", "Skateboard", ["#E3172F", "#141418", "#F4F1EA", "#FFD400"], ink=1.0)
def _():
    deck = box(0, 0, 0.3, 0.9, 0.3)
    grip = box(0, 0, 0.22, 0.8, 0.22)
    wheels = U(*[box(sx * 0.4, sy * 0.52, 0.08, 0.14, 0.04) for sx in (-1, 1) for sy in (-1, 1)])
    mark = star(0, 0.1, 5, 0.17, 0.07)
    return [deck, grip, wheels, mark]


@sticker("street", "megaphone", "Megaphone", ["#E3172F", "#F4F1EA", "#2B2E33", "#FFD400"], ink=1.0)
def _():
    horn = poly([(-0.6, 0.16), (0.22, 0.52), (0.22, -0.52), (-0.6, -0.16)])
    rim = box(0.22, 0, 0.06, 0.54, 0.05)
    grip = U(box(-0.68, 0, 0.1, 0.22, 0.05), box(-0.2, -0.44, 0.08, 0.2, 0.03, 0.3))
    waves = U(arc(0.22, 0, 0.5, -0.55, 0.55, 0.04), arc(0.22, 0, 0.7, -0.5, 0.5, 0.04))
    return [horn, rim, grip, waves]


@sticker("street", "crossbones", "Crossbones", ["#F4F1EA", "#C9C3B6", "#141418"], ink=1.0)
def _():
    def bone(ax, ay, bx, by):
        dx, dy = bx - ax, by - ay
        n = math.hypot(dx, dy)
        px, py = -dy / n * 0.12, dx / n * 0.12
        return U(seg(ax, ay, bx, by, 0.1), circle(ax + px, ay + py, 0.14), circle(ax - px, ay - py, 0.14),
                 circle(bx + px, by + py, 0.14), circle(bx - px, by - py, 0.14))
    a = bone(-0.62, -0.62, 0.62, 0.62)
    b = bone(0.62, -0.62, -0.62, 0.62)
    both = U(a, b)
    return [both, inter(both, X * 0.55 - Y * 0.85 - 0.02)]


@sticker("street", "padlock", "Padlock", ["#8A8F98", "#FFC531", "#E09A12", "#141418"], ink=1.0)
def _():
    shackle = U(arc(0, 0.22, 0.36, 0.0, math.pi, 0.1), seg(-0.36, 0.22, -0.36, -0.1, 0.1), seg(0.36, 0.22, 0.36, -0.1, 0.1))
    body = box(0, -0.3, 0.62, 0.5, 0.14)
    shade = inter(body, X * 0.5 - Y * 0.25 - 0.2)
    hole = U(circle(0, -0.2, 0.1), poly([(-0.06, -0.2), (0.06, -0.2), (0.1, -0.46), (-0.1, -0.46)]))
    return [shackle, body, shade, hole]


@sticker("street", "lips", "Lips", ["#E3172F", "#9D1220", "#FF8A9C", "#141418"], ink=1.0)
def _():
    upper = poly(spline([(-0.9, -0.03), (-0.62, 0.22), (-0.34, 0.42), (-0.1, 0.34), (0, 0.24), (0.1, 0.34), (0.34, 0.42), (0.62, 0.22),
                         (0.9, -0.03), (0.5, 0.05), (0, -0.01), (-0.5, 0.05)]))
    lower = poly(spline([(-0.9, -0.03), (-0.5, 0.05), (0, -0.01), (0.5, 0.05), (0.9, -0.03), (0.66, -0.4), (0.3, -0.64), (0, -0.68),
                         (-0.3, -0.64), (-0.66, -0.4)]))
    line = polyline(spline([(-0.9, -0.03), (-0.5, 0.05), (0, -0.01), (0.5, 0.05), (0.9, -0.03)], closed=False), 0.03)
    shade = inter(lower, -Y - 0.34)
    shine = U(oval(-0.14, -0.26, 0.26, 0.05, 0.08), oval(-0.38, 0.28, 0.1, 0.035, 0.5))
    return [U(upper, lower), shade, shine, line]


# ---- SWEETS (free pack; Pro picks in PRO) — after the ice-cream MPC ----------------------------------------

@sticker("sweets", "cone", "Ice cream cone", ["#E9A75B", "#FF8FB8", "#FFF4E8", "#C8102E"], ink=1.0)
def _():
    cone = poly([(-0.42, 0.05), (0.42, 0.05), (0, -0.92)]) - 0.03
    scoop = smin(circle(0, 0.32, 0.46), U(circle(-0.36, 0.1, 0.16), circle(0.0, 0.04, 0.16), circle(0.36, 0.1, 0.16)), 0.08)
    drip = U(taper(-0.22, 0.05, -0.22, -0.2, 0.08, 0.06), circle(-0.22, -0.22, 0.08),
             taper(0.18, 0.02, 0.18, -0.08, 0.07, 0.06), circle(0.18, -0.09, 0.07))
    waffle = inter(U(*[seg(x - 0.4, 0.05, x + 0.3, -0.8, 0.018) for x in (-0.2, 0.05, 0.3)],
                     *[seg(x + 0.4, 0.05, x - 0.3, -0.8, 0.018) for x in (-0.3, -0.05, 0.2)]), cone)
    sprinkles = U(*[box(x, y, 0.06, 0.018, 0.018, a) for x, y, a in
                    [(-0.15, 0.5, 0.6), (0.18, 0.45, -0.4), (0.0, 0.3, 1.2), (-0.28, 0.28, -0.9), (0.3, 0.25, 0.3), (0.1, 0.62, 0.1)]])
    cherry = U(circle(0.08, 0.83, 0.12), bezier((0.1, 0.9), (0.15, 1.0), (0.28, 1.02), 0.018))
    # cone, scoop + drips, the cone's waffle lines and the sprinkles (one colour slot), the cherry
    return [cone, U(scoop, drip), U(waffle, sprinkles), cherry]


@sticker("sweets", "popsicle", "Ice lolly", ["#FF5FA2", "#FFD1E3", "#D8A86A", "#7BD3F7"], ink=1.0)
def _():
    stick = box(0, -0.66, 0.1, 0.28, 0.08)
    body = sub(box(0, 0.22, 0.42, 0.66, 0.38), circle(0.42, 0.72, 0.16))
    shine = box(-0.2, 0.25, 0.05, 0.36, 0.05)
    drip = box(0.2, -0.4, 0.06, 0.08, 0.06)
    return [body, U(shine), stick, drip]


@sticker("sweets", "swirl", "Soft serve", ["#FFF4E8", "#E9C9A3", "#E9A75B", "#FF3D7F"], ink=1.0)
def _():
    cone = poly([(-0.36, -0.2), (0.36, -0.2), (0, -0.95)]) - 0.03
    tiers = U(box(0, -0.12, 0.5, 0.14, 0.14), box(0, 0.12, 0.4, 0.13, 0.13), box(0, 0.33, 0.28, 0.12, 0.12),
              taper(0, 0.42, 0.12, 0.72, 0.16, 0.03))
    grooves = U(arc(0, -0.3, 0.55, math.radians(55), math.radians(125), 0.02), arc(0, -0.04, 0.42, math.radians(55), math.radians(125), 0.02),
                arc(0, 0.18, 0.3, math.radians(55), math.radians(125), 0.018))
    waffle = inter(U(*[seg(x - 0.3, -0.2, x + 0.3, -0.9, 0.018) for x in (-0.15, 0.1)],
                     *[seg(x + 0.3, -0.2, x - 0.3, -0.9, 0.018) for x in (-0.1, 0.15)]), cone)
    return [tiers, grooves, cone, waffle]


@sticker("sweets", "lollipop", "Lollipop", ["#FF3D7F", "#FFFFFF", "#F4F1EA"], ink=1.0)
def _():
    candy = circle(0, 0.26, 0.6)
    t = np.arctan2(Y - 0.26, X)
    r = np.hypot(X, Y - 0.26)
    spiral = np.abs(((r * 8.0 - t / math.pi) % 2.0) - 1.0) * 0.12 - 0.04
    spiral = inter(spiral, candy)
    stick = box(0, -0.6, 0.06, 0.36, 0.05)
    return [candy, spiral, stick]


@sticker("sweets", "donut", "Donut", ["#E9A75B", "#FF8FB8", "#FFFFFF", "#7BD3F7"], ink=1.0)
def _():
    dough = sub(circle(0, 0, 0.86), circle(0, 0, 0.26))
    icing = sub(inter(circle(0, 0.03, 0.74) + 0.04 * np.sin(np.arctan2(Y, X) * 9), circle(0, 0, 0.8)), circle(0, 0, 0.32))
    rng = np.random.default_rng(4)
    sp = []
    for _ in range(18):
        a = rng.uniform(0, 2 * math.pi)
        rr = rng.uniform(0.42, 0.66)
        sp.append(box(rr * math.cos(a), rr * math.sin(a), 0.07, 0.022, 0.022, rng.uniform(0, 3)))
    sprinkles = U(*sp)
    return [dough, icing, inter(sprinkles, icing) - 0.0, inter(U(*sp[::3]), icing)]


@sticker("sweets", "cupcake", "Cupcake", ["#7BD3F7", "#FFF4E8", "#FF3D7F", "#C8102E"], ink=1.0)
def _():
    cup = poly([(-0.55, -0.1), (0.55, -0.1), (0.4, -0.88), (-0.4, -0.88)]) - 0.03
    ribs = inter(U(*[seg(x, -0.1, x * 0.75, -0.88, 0.02) for x in (-0.3, -0.1, 0.1, 0.3)]), cup)
    frosting = smin(U(circle(-0.35, 0.05, 0.25), circle(0.35, 0.05, 0.25), circle(0, 0.2, 0.36), circle(0, 0.5, 0.22)), box(0, -0.05, 0.6, 0.08, 0.08), 0.1)
    cherry = U(circle(0.05, 0.78, 0.13), bezier((0.08, 0.86), (0.12, 0.98), (0.26, 1.0), 0.018))
    return [U(cup), frosting, ribs, cherry]


@sticker("sweets", "cherries", "Cherries", ["#E3172F", "#2E9E4F", "#FFFFFF"], ink=1.0)
def _():
    fruit = U(circle(-0.36, -0.42, 0.34), circle(0.36, -0.36, 0.34))
    stems = U(bezier((-0.36, -0.12), (-0.25, 0.4), (0.1, 0.72), 0.03), bezier((0.36, -0.06), (0.3, 0.4), (0.1, 0.72), 0.03),
              ellipse(0.32, 0.72, 0.26, 0.11, 0.35))
    shine = U(ellipse(-0.48, -0.3, 0.07, 0.05, 0.6), ellipse(0.24, -0.24, 0.07, 0.05, 0.6))
    return [fruit, stems, shine]


@sticker("sweets", "watermelon", "Watermelon", ["#2E9E4F", "#FFFFFF", "#FF4F6A", "#141418"], ink=1.0)
def _():
    # a half slice, flat side up: green rind round the arc, a white band, red flesh, black seeds
    cy = 0.32
    rind = inter(circle(0, cy, 0.9), Y - cy)
    white = inter(circle(0, cy, 0.8), Y - cy)
    flesh = inter(circle(0, cy, 0.72), Y - cy - 0.0)
    seeds = U(*[ellipse(x, y, 0.035, 0.06, 0.25 * x) for x, y in [(-0.32, 0.12), (0, 0.0), (0.32, 0.12), (-0.18, -0.15), (0.18, -0.15), (0, -0.32)]])
    return [rind, white, flesh, inter(seeds, flesh)]


@sticker("sweets", "candy", "Wrapped sweet", ["#FFE14A", "#FF9F1C", "#FFFFFF"], ink=1.0)
def _():
    body = ellipse(0, 0, 0.42, 0.34)
    ends = U(poly([(-0.36, 0), (-0.86, 0.36), (-0.78, -0.36)]), poly([(0.36, 0), (0.86, -0.36), (0.78, 0.36)])) - 0.02
    stripes = inter(np.abs(((X + Y * 0.6) * 4) % 1.0 - 0.5) * 0.25 - 0.06, body)
    return [U(body, ends), stripes, ellipse(-0.12, 0.14, 0.12, 0.05, 0.3)]


@sticker("sweets", "cookie", "Cookie", ["#C98B4B", "#5A3420", "#E2AE70"], ink=1.0)
def _():
    cookie = circle(0, 0, 0.84) + 0.03 * np.sin(np.arctan2(Y, X) * 11)
    chips = U(*[circle(x, y, r) for x, y, r in [(-0.35, 0.3, 0.1), (0.25, 0.4, 0.09), (0.05, 0.0, 0.1), (-0.4, -0.25, 0.09),
                                                 (0.42, -0.1, 0.1), (0.1, -0.45, 0.08), (-0.1, 0.55, 0.07)]])
    return [cookie, chips, inter(cookie, -circle(0.2, -0.2, 0.86))]


@sticker("sweets", "strawberry", "Strawberry", ["#E3172F", "#2E9E4F", "#FFE14A"], ink=1.0)
def _():
    berry = smin(circle(0, 0.05, 0.6), poly([(-0.55, 0.15), (0.55, 0.15), (0, -0.85)]), 0.2)
    leaves = U(*[ellipse(0.3 * math.cos(a), 0.62 + 0.1 * math.sin(a), 0.22, 0.08, a) for a in (0.3, 1.2, 1.9, 2.8)], seg(0, 0.62, 0, 0.88, 0.04))
    seeds = U(*[ellipse(x, y, 0.025, 0.045) for x, y in [(-0.3, 0.2), (0, 0.25), (0.3, 0.2), (-0.15, -0.05), (0.15, -0.05), (-0.3, -0.2), (0.3, -0.2), (0, -0.35), (-0.12, -0.55), (0.12, -0.55)]])
    return [berry, leaves, inter(seeds, berry)]


@sticker("sweets", "cake", "Layer cake", ["#8A5A33", "#FFF4E8", "#FF8FB8", "#E3172F"], ink=1.0)
def _():
    front = box(0, -0.3, 0.74, 0.5, 0.08)
    top = poly([(-0.74, -0.04), (0.74, -0.04), (0.5, 0.34), (-0.5, 0.34)]) - 0.03
    cream = U(box(0, -0.42, 0.74, 0.07), box(0, -0.14, 0.74, 0.06))
    frosting = U(top, box(0, -0.03, 0.76, 0.06, 0.06), circle(-0.5, -0.12, 0.07), circle(-0.12, -0.14, 0.08), circle(0.3, -0.13, 0.07),
                 taper(0.62, -0.04, 0.62, -0.2, 0.07, 0.05), circle(0.62, -0.2, 0.05))
    cherry = U(circle(0.0, 0.38, 0.14), bezier((0.02, 0.5), (0.08, 0.7), (0.28, 0.72), 0.02))
    return [U(front, top), cream, frosting, cherry]


@sticker("sweets", "chocolate", "Chocolate", ["#5A3420", "#8A5A33", "#E3172F", "#FFF4E8"], ink=1.0)
def _():
    bar = box(0, 0.0, 0.58, 0.86, 0.06)
    squares = U(*[box(x, y, 0.15, 0.13, 0.03) for x in (-0.34, 0.0, 0.34) for y in (0.64, 0.38, 0.12)])
    wrap = poly([(-0.58, -0.08), (-0.38, -0.0), (-0.19, -0.08), (0, 0.0), (0.19, -0.08), (0.38, 0.0), (0.58, -0.08),
                 (0.58, -0.8), (-0.58, -0.8)])
    word = text("CHOC", 0, -0.46, 0.2, maxw=0.95)
    return [bar, squares, inter(wrap, bar + 0.04), word]


@sticker("sweets", "gummy", "Gummy bear", ["#FF3D6B", "#FFC2D1", "#C2185B", "#141418"], ink=1.0)
def _():
    head = circle(0, 0.4, 0.4)
    ears = U(circle(-0.3, 0.72, 0.15), circle(0.3, 0.72, 0.15))
    body = oval(0, -0.24, 0.44, 0.5)
    arms = U(oval(-0.5, -0.06, 0.15, 0.27, 0.55), oval(0.5, -0.06, 0.15, 0.27, -0.55))
    legs = U(oval(-0.27, -0.7, 0.2, 0.2), oval(0.27, -0.7, 0.2, 0.2))
    bear = smin(smin(head, ears, 0.06), smin(smin(body, arms, 0.08), legs, 0.08), 0.1)
    shine = U(oval(-0.22, 0.56, 0.07, 0.15, 0.4), oval(-0.2, -0.12, 0.06, 0.2, 0.15))
    snout = U(oval(0, 0.3, 0.17, 0.13), circle(-0.3, 0.72, 0.07), circle(0.3, 0.72, 0.07))
    face = U(circle(-0.16, 0.45, 0.04), circle(0.16, 0.45, 0.04), oval(0, 0.35, 0.05, 0.03), arc(0, 0.27, 0.07, math.radians(220), math.radians(320), 0.015))
    return [bear, shine, snout, face]


@sticker("sweets", "macaron", "Macaron", ["#FF8FB8", "#FFF4E8", "#E8639A", "#FFFFFF"], ink=1.0)
def _():
    top = inter(oval(0, 0.02, 0.76, 0.56), 0.1 - Y)           # a dome, flat underneath
    bottom = inter(oval(0, -0.02, 0.76, 0.56), Y + 0.1)        # the same, upside down
    feet = U(box(0, 0.1, 0.76, 0.05, 0.05), box(0, -0.1, 0.76, 0.05, 0.05))   # the ruffled "foot" each shell sits on
    filling = box(0, 0.0, 0.68, 0.09, 0.07)
    shade = U(inter(top, Y - 0.24), inter(bottom, Y + 0.42))      # the rim of each dome, away from the light
    shine = U(oval(-0.3, 0.38, 0.22, 0.06, 0.18), oval(-0.3, -0.22, 0.2, 0.05, -0.18))
    return [U(top, bottom, feet), filling, shade, shine]


@sticker("sweets", "candycane", "Candy cane", ["#F4F1EA", "#E3172F", "#2E9E4F", "#FFFFFF"], ink=1.0)
def _():
    cane = U(seg(0.12, -0.82, 0.12, 0.3, 0.15), arc(-0.2, 0.3, 0.32, 0.0, math.pi, 0.15), seg(-0.52, 0.3, -0.52, 0.12, 0.15))
    bands = inter(stripes(0.36, 2.2, 0.5), cane)
    bow = U(oval(-0.14, -0.36, 0.26, 0.12, 0.4), oval(0.38, -0.36, 0.26, 0.12, -0.4), circle(0.12, -0.34, 0.08))
    glint = seg(0.06, -0.7, 0.06, 0.16, 0.022)
    return [cane, bands, bow, glint]


@sticker("sweets", "cottoncandy", "Cotton candy", ["#E9C9A3", "#FF8FD0", "#FFC2E8", "#FFFFFF"], ink=1.0)
def _():
    stick = box(0, -0.66, 0.05, 0.3, 0.03)
    fluff = U(circle(0, 0.2, 0.46), circle(-0.4, 0.06, 0.3), circle(0.4, 0.06, 0.3), circle(-0.22, 0.52, 0.28), circle(0.26, 0.5, 0.3),
              circle(-0.52, 0.34, 0.2), circle(0.55, 0.32, 0.2))
    puffs = U(circle(-0.18, 0.4, 0.22), circle(0.22, 0.12, 0.2), circle(-0.4, 0.0, 0.14), circle(0.2, 0.55, 0.14))
    swirls = U(arc(0.0, 0.2, 0.3, 0.3, 2.4, 0.018), arc(-0.1, 0.25, 0.18, 3.4, 5.4, 0.016))
    return [stick, fluff, puffs, swirls]


@sticker("sweets", "milkshake", "Milkshake", ["#DCE6F2", "#FF8FB8", "#FFFFFF", "#E3172F"], ink=1.0)
def _():
    glass = poly([(-0.46, 0.3), (0.46, 0.3), (0.32, -0.84), (-0.32, -0.84)]) - 0.04
    shake = inter(glass, Y - 0.18)
    cream = U(circle(-0.26, 0.34, 0.22), circle(0.06, 0.4, 0.26), circle(0.32, 0.32, 0.18), circle(-0.04, 0.58, 0.2))
    cherry = U(circle(0.0, 0.8, 0.11), seg(0.22, 0.5, 0.5, 0.9, 0.045))
    return [glass, shake, cream, cherry]


@sticker("sweets", "pancakes", "Pancakes", ["#E9A75B", "#C98B4B", "#8A4B1E", "#FFE9A8"], ink=1.0)
def _():
    stack = U(box(0, -0.5, 0.74, 0.14, 0.14), box(0, -0.2, 0.7, 0.14, 0.14), box(0, 0.1, 0.72, 0.14, 0.14))
    under = U(*[inter(box(0, y, 0.74, 0.14, 0.14), -Y + y - 0.03) for y in (-0.5, -0.2, 0.1)])
    syrup = U(box(0, 0.22, 0.66, 0.07, 0.07), taper(-0.4, 0.22, -0.4, -0.12, 0.08, 0.06), circle(-0.4, -0.12, 0.06),
              taper(0.05, 0.22, 0.05, -0.34, 0.08, 0.06), circle(0.05, -0.34, 0.06), taper(0.5, 0.22, 0.5, -0.04, 0.08, 0.06), circle(0.5, -0.04, 0.06))
    butter = box(0.0, 0.36, 0.2, 0.1, 0.03, 0.08)
    return [stack, under, syrup, butter]


# ---- MUSIC (free pack; Pro picks in PRO) -------------------------------------------------------------------

@sticker("music", "note", "Eighth note", ["#141418", "#FF2D6F"], ink=0.0)
def _():
    head = ellipse(-0.25, -0.55, 0.3, 0.22, 0.45)
    stem = box(0.02, 0.05, 0.06, 0.62)
    flag = bezier((0.04, 0.66), (0.5, 0.45), (0.42, -0.05), 0.07, r1=0.03)
    return [U(head, stem, flag), ellipse(-0.33, -0.48, 0.08, 0.05, 0.45)]


@sticker("music", "beamed", "Beamed notes", ["#FF2D6F", "#141418"], ink=1.0)
def _():
    heads = U(ellipse(-0.48, -0.55, 0.26, 0.19, 0.45), ellipse(0.32, -0.42, 0.26, 0.19, 0.45))
    stems = U(box(-0.25, 0.0, 0.055, 0.56), box(0.55, 0.12, 0.055, 0.56))
    beam = poly([(-0.3, 0.55), (0.6, 0.72), (0.6, 0.55), (-0.3, 0.38)])
    return [U(heads, stems, beam)]


@sticker("music", "headphones", "Headphones", ["#2B2E33", "#FF2D6F", "#8A8F98"], ink=1.0)
def _():
    band = arc(0, -0.05, 0.68, math.radians(15), math.radians(165), 0.1)
    cups = U(box(-0.68, -0.32, 0.17, 0.3, 0.12), box(0.68, -0.32, 0.17, 0.3, 0.12))
    pads = U(box(-0.52, -0.32, 0.08, 0.24, 0.07), box(0.52, -0.32, 0.08, 0.24, 0.07))
    return [U(band, cups), cups, pads]


@sticker("music", "vinyl", "Vinyl", ["#141418", "#FF2D6F", "#F4F1EA", "#3A3A44"], ink=0.0)
def _():
    disc = circle(0, 0, 0.9)
    label = circle(0, 0, 0.32)
    hole = circle(0, 0, 0.05)
    grooves = inter(np.abs(((np.hypot(X, Y) * 18) % 1.0) - 0.5) * 0.05 - 0.008, sub(disc, circle(0, 0, 0.38)))
    return [disc, grooves, label, U(hole, text("DSD", 0, 0.14, 0.09))]


@sticker("music", "cassette", "Cassette", ["#F4F1EA", "#141418", "#FF2D6F", "#8A8F98"], ink=1.0)
def _():
    shell_ = box(0, 0, 0.9, 0.58, 0.08)
    window = box(0, 0.08, 0.5, 0.18, 0.06)
    reels = U(ring(-0.32, 0.08, 0.13, 0.04), ring(0.32, 0.08, 0.13, 0.04))
    band = box(0, 0.38, 0.8, 0.07, 0.03)
    base = poly([(-0.6, -0.58), (0.6, -0.58), (0.48, -0.3), (-0.48, -0.3)])
    return [shell_, U(window, base), band, reels]


@sticker("music", "speaker", "Speaker", ["#2B2E33", "#8A8F98", "#141418", "#FF2D6F"], ink=1.0)
def _():
    cab = box(0, 0, 0.62, 0.88, 0.1)
    woofer = circle(0, -0.25, 0.42)
    tweeter = circle(0, 0.52, 0.18)
    caps = U(circle(0, -0.25, 0.13), circle(0, 0.52, 0.06))
    return [cab, U(woofer, tweeter), U(ring(0, -0.25, 0.3, 0.02), ring(0, 0.52, 0.12, 0.015)), caps]


@sticker("music", "mic", "Microphone", ["#8A8F98", "#141418", "#FF2D6F"], ink=1.0)
def _():
    head = U(circle(0, 0.42, 0.36), box(0, 0.2, 0.36, 0.22, 0.0))
    grille = inter(U(*[seg(-0.4, y, 0.4, y, 0.018) for y in (0.25, 0.4, 0.55, 0.7)], *[seg(x, 0.0, x, 0.8, 0.018) for x in (-0.16, 0, 0.16)]), head)
    body = U(box(0, -0.42, 0.14, 0.42, 0.1))
    band = box(0, -0.02, 0.22, 0.06, 0.03)
    return [U(head, body, band), grille, band]


@sticker("music", "sticks", "Drumsticks", ["#E9C9A3", "#C98B4B"], ink=1.0)
def _():
    a = U(taper(-0.72, -0.78, 0.66, 0.7, 0.07, 0.035), circle(0.68, 0.72, 0.07))
    b = U(taper(0.72, -0.78, -0.66, 0.7, 0.07, 0.035), circle(-0.68, 0.72, 0.07))
    return [U(a, b), U(circle(0.68, 0.72, 0.055), circle(-0.68, 0.72, 0.055))]


@sticker("music", "snare", "Snare", ["#E3172F", "#F4F1EA", "#8A8F98", "#141418"], ink=1.0)
def _():
    shell_ = box(0, -0.18, 0.78, 0.42, 0.06)
    top = ellipse(0, 0.24, 0.78, 0.2)
    lugs = U(*[box(x, -0.18, 0.03, 0.3) for x in (-0.55, -0.18, 0.18, 0.55)])
    hoops = U(box(0, 0.2, 0.8, 0.05, 0.03), box(0, -0.58, 0.8, 0.05, 0.03))
    return [U(shell_, top), top, hoops, lugs]


@sticker("music", "pick", "Guitar pick", ["#FF9F1C", "#FFE14A", "#FFFFFF"], ink=1.0)
def _():
    pick = smin(circle(0, 0.18, 0.66), poly([(-0.55, 0.25), (0.55, 0.25), (0, -0.9)]), 0.25)
    inner = smin(circle(0, 0.2, 0.42), poly([(-0.34, 0.25), (0.34, 0.25), (0, -0.55)]), 0.2)
    return [pick, inner, text("DSD", 0, 0.18, 0.2)]


@sticker("music", "eq", "Equalizer", ["#141418", "#2EE6A0", "#FFD400", "#FF2D6F"], ink=0.0)
def _():
    panel = box(0, 0, 0.9, 0.7, 0.14)
    hs = [0.3, 0.55, 0.8, 0.62, 0.42, 0.7, 0.35]
    bars_lo, bars_mid, bars_hi = [], [], []
    for i, h in enumerate(hs):
        x = -0.66 + i * 0.22
        for k in range(int(h * 10)):
            y = -0.52 + k * 0.105
            cell = box(x, y, 0.08, 0.04, 0.015)
            (bars_lo if k < 4 else bars_mid if k < 7 else bars_hi).append(cell)
    return [panel, U(*bars_lo), U(*bars_mid), U(*bars_hi) if bars_hi else panel * 0 + BIG]


@sticker("music", "rec", "REC", ["#141418", "#FF2D2D", "#FFFFFF"], ink=0.0)
def _():
    pill = box(0, 0, 0.9, 0.4, 0.4)
    dot = circle(-0.56, 0, 0.16)
    word = text("REC", 0.16, 0.0, 0.32, maxw=0.98)
    return [pill, dot, word]


@sticker("music", "onair", "On Air", ["#C8102E", "#FF9AA8", "#FFFFFF"], ink=1.0)
def _():
    sign = box(0, 0, 0.9, 0.42, 0.12)
    inner = box(0, 0, 0.82, 0.34, 0.08)
    word = text("ON AIR", 0, 0.0, 0.26, maxw=1.36)
    return [sign, shell(inner, 0.015), word]


@sticker("music", "metronome", "Metronome", ["#5A3420", "#C98B4B", "#F4F1EA", "#141418"], ink=1.0)
def _():
    body = poly([(-0.5, -0.82), (0.5, -0.82), (0.2, 0.82), (-0.2, 0.82)]) - 0.03
    face = poly([(-0.32, -0.45), (0.32, -0.45), (0.13, 0.62), (-0.13, 0.62)])
    arm = U(seg(0, -0.45, 0.3, 0.55, 0.03), box(0.2, 0.22, 0.08, 0.06, 0.02, -0.3))
    return [body, face, U(*[seg(-0.12, y, 0.12, y, 0.012) for y in (-0.2, 0.0, 0.2, 0.4)]), arm]


@sticker("music", "keys", "Keys", ["#F4F1EA", "#8A8F98", "#141418", "#E3172F"], ink=1.0)
def _():
    body = box(0, -0.02, 0.9, 0.68, 0.1)
    seams = U(*[box(x, -0.2, 0.012, 0.46) for x in (-0.6, -0.3, 0.0, 0.3, 0.6)])
    blacks = U(*[box(x, 0.19, 0.085, 0.31, 0.03) for x in (-0.6, -0.3, 0.3, 0.6)])
    felt = box(0, 0.58, 0.9, 0.08, 0.04)
    return [body, seams, blacks, felt]


@sticker("music", "kick", "Kick drum", ["#E3172F", "#F4F1EA", "#8A8F98", "#141418"], ink=1.0)
def _():
    shell_ = circle(0, 0, 0.88)
    head = circle(0, 0, 0.7)
    lugs = U(*[box(0.8 * math.cos(a), 0.8 * math.sin(a), 0.075, 0.035, 0.015, a) for a in [k * math.pi / 4 + math.pi / 8 for k in range(8)]])
    logo = U(ring(0, 0, 0.5, 0.022), text("DSD", 0, 0.0, 0.22, maxw=0.8))
    return [shell_, head, lugs, logo]


@sticker("music", "hihat", "Hi-hat", ["#8A8F98", "#F5C242", "#B8860B", "#FFFFFF"], ink=1.0)
def _():
    stand = U(seg(0, 0.4, 0, -0.62, 0.035), seg(0, -0.6, -0.5, -0.9, 0.03), seg(0, -0.6, 0.5, -0.9, 0.03), seg(0, -0.6, 0.02, -0.92, 0.03))
    top = oval(0, 0.5, 0.84, 0.17, 0.05)
    bot = oval(0, 0.16, 0.84, 0.17, -0.03)
    under = U(inter(top, Y - 0.5), oval(0, 0.6, 0.18, 0.08, 0.05))
    shine = U(seg(-0.6, 0.55, -0.24, 0.6, 0.02), seg(-0.6, 0.2, -0.26, 0.17, 0.02))
    return [stand, U(top, bot), under, shine]


@sticker("music", "turntable", "Turntable", ["#2B2E33", "#C9CED6", "#141418", "#FF2D6F"], ink=1.0)
def _():
    base = box(0, 0, 0.92, 0.74, 0.1)
    plat = circle(-0.2, -0.02, 0.6)
    rec = sub(circle(-0.2, -0.02, 0.52), circle(-0.2, -0.02, 0.17))
    arm = U(taper(0.72, 0.5, 0.2, -0.14, 0.035, 0.03), box(0.14, -0.2, 0.11, 0.05, 0.02, 0.95), circle(0.72, 0.5, 0.1), circle(-0.2, -0.02, 0.03))
    return [base, plat, rec, arm]


@sticker("music", "tambourine", "Tambourine", ["#C98B4B", "#F4F1EA", "#2B2E33", "#C9CED6"], ink=1.0)
def _():
    angs = [math.pi / 4 + k * math.pi / 2 for k in range(4)]
    rim = circle(0, 0, 0.88)
    head = circle(0, 0, 0.62)
    slots = U(*[box(0.75 * math.cos(a), 0.75 * math.sin(a), 0.16, 0.05, 0.02, a + math.pi / 2) for a in angs])
    discs = U(*[circle(0.75 * math.cos(a) - d * math.sin(a), 0.75 * math.sin(a) + d * math.cos(a), 0.07) for a in angs for d in (-0.08, 0.08)])
    return [rim, head, slots, discs]


@sticker("music", "waveform", "Waveform", ["#8A8F98", "#FF5A1F", "#FFFFFF", "#141418"], ink=1.0)
def _():
    hs = [0.18, 0.32, 0.55, 0.38, 0.7, 0.5, 0.82, 0.6, 0.4, 0.62, 0.3, 0.45, 0.2]
    xs = np.linspace(-0.84, 0.84, len(hs))
    bars = U(*[box(x, 0, 0.052, h, 0.052) for x, h in zip(xs, hs)])
    played = inter(bars, X + 0.08)
    head = U(box(-0.08, 0, 0.02, 0.86, 0.02), circle(-0.08, 0.84, 0.055))
    return [bars, played, head]


@sticker("music", "guitar", "Guitar", ["#E9A75B", "#5A3420", "#141418", "#F4F1EA"], ink=1.0)
def _():
    with rotated(-0.6):
        body = smin(circle(0, -0.5, 0.38), circle(0, -0.1, 0.27), 0.2)
        neck = U(box(0, 0.42, 0.075, 0.46), box(0, 0.88, 0.11, 0.12, 0.03))
        dark = U(circle(0, -0.4, 0.11), box(0, -0.68, 0.15, 0.035, 0.015), *[box(0, y, 0.075, 0.01) for y in np.linspace(0.1, 0.6, 6)])
        light = U(ring(0, -0.4, 0.15, 0.014), seg(0, -0.66, 0, 0.82, 0.008))
    return [body, neck, dark, light]


@sticker("music", "maracas", "Maracas", ["#E3172F", "#FFD400", "#C98B4B", "#FFFFFF"], ink=1.0)
def _():
    def maraca(sign):
        with rotated(sign * 0.42, 0.0, -0.3, sign * 0.4, 0.0):
            head = oval(0, 0.32, 0.3, 0.42)
            bands = inter(stripes(0.28, 0.9, 0.4), head)
            handle = U(taper(0, -0.1, 0, -0.6, 0.075, 0.1), circle(0, -0.66, 0.11))
            shine = oval(-0.1, 0.5, 0.06, 0.14, 0.2)
        return head, bands, handle, shine
    a, b = maraca(1), maraca(-1)
    return [U(a[0], b[0]), U(a[1], b[1]), U(a[2], b[2]), U(a[3], b[3])]


# ---- SPACE (free pack; Pro picks in PRO) -------------------------------------------------------------------

@sticker("space", "rocket", "Rocket", ["#F4F1EA", "#E3172F", "#1FB6FF", "#FF9F1C"], ink=1.0)
def _():
    hull = smin(ellipse(0, 0.08, 0.3, 0.72), poly([(-0.3, -0.2), (0.3, -0.2), (0, 0.95)]) - 0.02, 0.12)
    fins = U(poly([(-0.28, -0.25), (-0.62, -0.72), (-0.22, -0.6)]), poly([(0.28, -0.25), (0.62, -0.72), (0.22, -0.6)])) - 0.03
    nose = inter(hull, 0.55 - Y)
    window = circle(0, 0.22, 0.14)
    flame = smin(circle(0, -0.72, 0.13), taper(0, -0.72, 0, -0.98, 0.12, 0.01), 0.05)
    return [hull, U(fins, nose), window, flame]


@sticker("space", "planet", "Ringed planet", ["#8B3DFF", "#FF5FD2", "#FFD400"], ink=1.0)
def _():
    planet = circle(0, 0, 0.55)
    bands = inter(np.abs((Y * 6 + 0.3 * np.sin(X * 5)) % 2 - 1) * 0.1 - 0.035, planet)
    ringd = ellipse(0, 0, 0.92, 0.22, 0.32)
    ring_ = sub(shell(ringd, 0.05), inter(planet, Y * math.cos(0.32) - X * math.sin(0.32) - 0.0))
    return [U(planet), bands, ring_]


@sticker("space", "moon", "Moon", ["#FFE9A8", "#E8C870", "#141418"], ink=1.0)
def _():
    moon = sub(circle(0, 0, 0.8), circle(0.4, 0.22, 0.66))
    craters = U(circle(-0.45, 0.2, 0.09), circle(-0.3, -0.35, 0.12), circle(-0.1, -0.62, 0.07))
    face = U(circle(-0.28, 0.12, 0.045), arc(-0.3, -0.05, 0.12, math.radians(200), math.radians(320), 0.02))
    return [moon, inter(craters, moon), face]


@sticker("space", "ufo", "UFO", ["#8A8F98", "#7BF7C4", "#FFD400", "#3A3F47"], ink=1.0)
def _():
    saucer = ellipse(0, -0.12, 0.8, 0.22)
    dome = inter(circle(0, 0.05, 0.4), -Y)
    lights = U(*[circle(x, -0.14, 0.055) for x in (-0.5, -0.18, 0.18, 0.5)])
    beam = poly([(-0.26, -0.3), (0.26, -0.3), (0.46, -0.95), (-0.46, -0.95)])
    return [U(saucer, dome), dome, lights, inter(beam, -saucer)]


@sticker("space", "alien", "Alien", ["#7BF7C4", "#2EC4B6", "#141418"], ink=1.0)
def _():
    head = smin(ellipse(0, 0.12, 0.62, 0.7), poly([(-0.32, -0.3), (0.32, -0.3), (0, -0.9)]), 0.25)
    eyes = U(ellipse(-0.28, 0.0, 0.24, 0.13, -0.5), ellipse(0.28, 0.0, 0.24, 0.13, 0.5))
    return [head, inter(head, X * 0.8 + 0.3), U(eyes, seg(-0.08, -0.45, 0.08, -0.45, 0.02))]


@sticker("space", "comet", "Comet", ["#1FB6FF", "#9FE8FF", "#FFFFFF"], ink=0.0)
def _():
    tail = U(taper(0.85, 0.85, 0.15, 0.15, 0.02, 0.32), taper(0.6, 0.92, 0.1, 0.25, 0.01, 0.15), taper(0.92, 0.55, 0.3, 0.08, 0.01, 0.15))
    head = circle(-0.2, -0.2, 0.38)
    core = circle(-0.25, -0.25, 0.2)
    return [U(tail, head), U(head, taper(0.6, 0.6, 0.15, 0.15, 0.01, 0.18)), core]


@sticker("space", "sun", "Sun", ["#FF9F1C", "#FFD400", "#FFF4C7", "#141418"], ink=1.0)
def _():
    rays = star(0, 0, 12, 0.92, 0.62, 0.0) - 0.03
    disc = circle(0, 0, 0.56)
    glow = circle(-0.12, 0.12, 0.3)
    face = U(ellipse(-0.18, 0.1, 0.05, 0.08), ellipse(0.18, 0.1, 0.05, 0.08), arc(0, 0.02, 0.25, math.radians(210), math.radians(330), 0.03))
    return [rays, disc, inter(glow, disc), face]


@sticker("space", "astro", "Helmet", ["#F4F7FB", "#141418", "#1FB6FF", "#FF9F1C"], ink=1.0)
def _():
    helmet = U(circle(0, 0.08, 0.72), box(0, -0.6, 0.6, 0.22, 0.12))
    visor = ellipse(0, 0.1, 0.48, 0.36)
    refl = U(ellipse(-0.16, 0.24, 0.16, 0.07, 0.4), ellipse(0.22, -0.02, 0.06, 0.03, 0.4))
    light = circle(0.52, 0.52, 0.08)
    return [helmet, visor, refl, light]


@sticker("space", "satellite", "Satellite", ["#F4D35E", "#1B6FE0", "#9FE8FF", "#C9CED6"], ink=1.0)
def _():
    with rotated(0.55):
        body = U(box(0, 0, 0.2, 0.24, 0.04), seg(-0.3, 0, -0.2, 0, 0.03), seg(0.2, 0, 0.3, 0, 0.03))
        panels = U(box(-0.62, 0, 0.3, 0.2, 0.02), box(0.62, 0, 0.3, 0.2, 0.02))
        grid = inter(U(*[seg(x, -0.2, x, 0.2, 0.014) for x in (-0.82, -0.62, -0.42, 0.42, 0.62, 0.82)],
                       seg(-0.92, 0, -0.32, 0, 0.014), seg(0.32, 0, 0.92, 0, 0.014)), panels)
        dish = U(sub(circle(0, 0.52, 0.25), circle(0, 0.66, 0.25)), seg(0, 0.24, 0, 0.5, 0.025), circle(0, 0.74, 0.04))
    return [body, panels, grid, dish]


@sticker("space", "earth", "Earth", ["#1B6FE0", "#2E9E4F", "#FFFFFF", "#CFE9FF"], ink=1.0)
def _():
    ocean = circle(0, 0, 0.86)
    land = inter(U(smin(circle(-0.34, 0.3, 0.24), oval(-0.22, -0.02, 0.15, 0.3, -0.3), 0.15),
                   smin(circle(0.36, 0.22, 0.22), oval(0.4, -0.2, 0.17, 0.3, 0.2), 0.12),
                   circle(0.05, -0.66, 0.13)), ocean)
    clouds = inter(U(oval(0.0, 0.52, 0.3, 0.06, 0.15), oval(-0.5, -0.32, 0.26, 0.05, -0.1), oval(0.3, -0.48, 0.24, 0.05, 0.2)), ocean)
    glint = inter(oval(-0.46, 0.46, 0.14, 0.07, 0.9), ocean)
    return [ocean, land, clouds, glint]


@sticker("space", "mars", "Red planet", ["#D9573B", "#A53A28", "#F4E3C8", "#7A2A1C"], ink=1.0)
def _():
    pl = circle(-0.05, -0.05, 0.8)
    terrain = inter(U(oval(-0.32, 0.08, 0.3, 0.14, 0.3), oval(0.2, -0.32, 0.36, 0.12, -0.2), oval(0.28, 0.3, 0.2, 0.09, 0.5)), pl)
    cap = U(inter(pl, 0.55 - Y), circle(0.68, 0.66, 0.13))
    craters = U(ring(-0.36, -0.42, 0.12, 0.02), ring(0.32, 0.04, 0.09, 0.018), ring(-0.1, -0.2, 0.06, 0.015))
    return [pl, terrain, cap, craters]


@sticker("space", "constellation", "Constellation", ["#14163A", "#6B7CFF", "#FFFFFF", "#FFD400"], ink=1.0)
def _():
    pts = [(-0.66, 0.5), (-0.4, 0.34), (-0.14, 0.26), (0.12, 0.08), (0.6, 0.12), (0.52, -0.3), (0.08, -0.26)]
    disc = circle(0, 0, 0.9)
    lines = polyline(pts + [pts[3]], 0.014)
    stars = U(*[star(x, y, 4, 0.14, 0.04, math.pi / 2) for x, y in pts])
    tiny = U(*[star(x, y, 4, 0.08, 0.025, math.pi / 2) for x, y in [(-0.4, -0.4), (-0.1, -0.62), (0.4, 0.58), (-0.62, -0.05), (0.7, -0.5)]])
    return [disc, lines, stars, tiny]


@sticker("space", "galaxy", "Galaxy", ["#1E1348", "#7A3CFF", "#FF5FD2", "#FFF4C7"], ink=1.0)
def _():
    disc = circle(0, 0, 0.9)
    r = np.hypot(X, Y) + 1e-6
    t = np.arctan2(Y, X)
    s = (t / math.pi + 1.5 * np.log(r + 0.15)) % 1.0
    grad = np.hypot(1.0 / (math.pi * r), 1.5 / (r + 0.15))
    arms = np.maximum((np.abs(s - 0.5) - 0.3) / grad, circle(0, 0, 0.84))
    inner = np.maximum((np.abs(s - 0.5) - 0.12) / grad, circle(0, 0, 0.78))
    core = U(circle(0, 0, 0.17), *[circle(x, y, 0.03) for x, y in [(0.55, 0.55), (-0.6, 0.4), (0.3, -0.7), (-0.4, -0.55), (0.7, -0.2)]])
    return [disc, arms, inner, core]


@sticker("space", "blackhole", "Black hole", ["#FF7A00", "#FFD400", "#0B0B12", "#FFF4C7"], ink=1.0)
def _():
    outer = oval(0, 0, 0.92, 0.3, 0.28)
    inner = oval(0, 0, 0.7, 0.2, 0.28)
    hole = circle(0, 0, 0.36)
    lens = ring(0, 0, 0.43, 0.04)
    return [outer, inner, hole, lens]


@sticker("space", "shootingstar", "Shooting star", ["#1FB6FF", "#FFD400", "#FFF4C7", "#FFFFFF"], ink=1.0)
def _():
    trails = U(taper(0.3, 0.3, -0.8, -0.8, 0.12, 0.01), taper(0.3, 0.3, -0.86, -0.3, 0.09, 0.01), taper(0.3, 0.3, -0.3, -0.86, 0.09, 0.01))
    st = star(0.3, 0.3, 5, 0.46, 0.2, math.pi / 2 + 0.3) - 0.03
    core = star(0.3, 0.3, 5, 0.28, 0.12, math.pi / 2 + 0.3)
    spark = U(star(-0.3, 0.55, 4, 0.14, 0.035, math.pi / 2), star(0.62, -0.42, 4, 0.1, 0.03, math.pi / 2), star(-0.62, 0.1, 4, 0.08, 0.025, math.pi / 2))
    return [trails, st, core, spark]


@sticker("space", "telescope", "Telescope", ["#2B59C3", "#F4D35E", "#5A3420", "#FFFFFF"], ink=1.0)
def _():
    legs = U(seg(0, -0.1, -0.55, -0.9, 0.04), seg(0, -0.1, 0.5, -0.9, 0.04), seg(0, -0.1, 0.02, -0.92, 0.04))
    with rotated(-0.75, 0.0, -0.1):
        tube = U(poly([(-0.1, -0.5), (0.1, -0.5), (0.2, 0.2), (-0.2, 0.2)]), poly([(-0.2, 0.15), (0.2, 0.15), (0.26, 0.74), (-0.26, 0.74)]))
        brass = U(box(0, 0.7, 0.28, 0.04), box(0, 0.16, 0.22, 0.03), box(0, -0.52, 0.12, 0.04))
        glint = seg(-0.1, 0.3, -0.1, 0.6, 0.02)
    return [tube, brass, legs, glint]


# ---- RETRO (free pack; Pro picks in PRO) -------------------------------------------------------------------

@sticker("retro", "roundel", "Racing 07", ["#FFFFFF", "#141418", "#E3172F"], ink=0.0)
def _():
    disc = circle(0, 0, 0.88)
    rim = shell(circle(0, 0, 0.8), 0.03)
    num = text("07", 0, 0.0, 0.56, maxw=1.1)
    return [disc, num, rim]


@sticker("retro", "hazard", "Hazard", ["#FFD400", "#141418"], ink=1.0)
def _():
    tri = poly([(0, 0.88), (-0.92, -0.74), (0.92, -0.74)]) - 0.06
    inner = shell(poly([(0, 0.62), (-0.66, -0.56), (0.66, -0.56)]) - 0.03, 0.035)
    mark = U(taper(0, 0.3, 0, -0.18, 0.08, 0.05), circle(0, -0.36, 0.07))
    return [tri, U(inner, mark)]


@sticker("retro", "radioactive", "Radioactive", ["#FFD400", "#141418"], ink=0.0)
def _():
    disc = circle(0, 0, 0.88)
    a = np.arctan2(Y, X)
    blades = inter(inter(circle(0, 0, 0.72), -circle(0, 0, 0.2)), np.cos(3 * (a - math.pi / 2)) * -0.3 + 0.15)
    return [disc, U(blades, circle(0, 0, 0.13))]


@sticker("retro", "sunset", "Synth sunset", ["#FF2D6F", "#FFD400", "#2B0A3D", "#FF9F1C"], ink=0.0)
def _():
    sun = circle(0, 0.06, 0.84)
    lower = inter(sun, Y - 0.06)                        # the lower half goes gold
    # the synthwave slits: bands across the lower half, thickening toward the horizon
    band = np.abs(((Y + 0.9) * 7.0) % 1.0 - 0.5)
    slits = inter(inter(band - (0.06 + (0.0 - Y) * 0.32), sun), Y + 0.02)
    return [sun, lower, slits]


@sticker("retro", "palm", "Palm", ["#2E9E4F", "#8A5A33", "#FF9F1C"], ink=1.0)
def _():
    trunk = bezier((0.1, -0.92), (0.0, -0.2), (0.2, 0.42), 0.1, r1=0.06)
    fronds = U(*[bezier((0.2, 0.45), (0.2 + 0.4 * math.cos(a), 0.45 + 0.35 * math.sin(a) + 0.15), (0.2 + 0.75 * math.cos(a), 0.45 + 0.5 * math.sin(a) - 0.2), 0.1, r1=0.02)
                 for a in (0.3, 1.2, 1.9, 2.8, 3.4)])
    nuts = U(circle(0.12, 0.36, 0.08), circle(0.28, 0.34, 0.08))
    return [fronds, trunk, nuts]


@sticker("retro", "wave", "Big wave", ["#0F3B63", "#1FB6FF", "#F4F7FB"], ink=1.0)
def _():
    sea = U(box(0, -0.62, 0.9, 0.28, 0.12),
            smin(circle(0.05, 0.02, 0.62), box(0, -0.4, 0.9, 0.2), 0.3))
    curl = sub(circle(0.05, 0.02, 0.62), circle(-0.1, 0.0, 0.38))
    foam = U(*[circle(-0.1 + 0.48 * math.cos(a), 0.0 + 0.48 * math.sin(a), 0.07) for a in np.linspace(0.6, 2.6, 7)], circle(-0.4, 0.15, 0.08))
    return [sea, curl, foam]


@sticker("retro", "cactus", "Cactus", ["#2E9E4F", "#C8102E", "#E9A75B"], ink=1.0)
def _():
    body = U(box(0, 0.05, 0.18, 0.7, 0.18), box(-0.36, 0.2, 0.12, 0.28, 0.12), box(-0.22, -0.05, 0.16, 0.06, 0.06),
             box(0.36, 0.32, 0.12, 0.3, 0.12), box(0.22, 0.06, 0.16, 0.06, 0.06))
    flower = circle(0, 0.78, 0.1)
    pot = poly([(-0.42, -0.62), (0.42, -0.62), (0.32, -0.95), (-0.32, -0.95)])
    return [U(body, pot), flower, pot]


@sticker("retro", "hifi", "Hi-Fi", ["#141418", "#FFD400", "#FF2D6F"], ink=0.0)
def _():
    badge = box(0, 0, 0.92, 0.38, 0.1)
    word = text("HI-FI", 0, 0.0, 0.32, stretch=1.15, maxw=1.5)
    lines = U(seg(-0.85, -0.3, 0.85, -0.3, 0.02), seg(-0.85, 0.3, 0.85, 0.3, 0.02))
    return [badge, word, lines]


@sticker("retro", "arrow", "Arrow sign", ["#FFD400", "#141418"], ink=1.0)
def _():
    sign = poly([(-0.9, 0.3), (0.25, 0.3), (0.25, 0.62), (0.92, 0), (0.25, -0.62), (0.25, -0.3), (-0.9, -0.3)]) - 0.03
    word = text("DRUM", -0.28, 0.0, 0.22, maxw=0.95)
    return [sign, word]


@sticker("retro", "boombox", "Boombox", ["#E3172F", "#141418", "#8A8F98", "#F4F1EA"], ink=1.0)
def _():
    body = box(0, -0.1, 0.92, 0.5, 0.1)
    handle = shell(box(0, 0.48, 0.52, 0.16, 0.1), 0.045)
    speakers = U(circle(-0.52, -0.16, 0.3), circle(0.52, -0.16, 0.3))
    cones = U(circle(-0.52, -0.16, 0.1), circle(0.52, -0.16, 0.1))
    deck = box(0, -0.05, 0.16, 0.18, 0.03)
    rings = U(ring(-0.52, -0.16, 0.2, 0.02), ring(0.52, -0.16, 0.2, 0.02))
    return [U(body, handle), U(speakers, deck), rings, cones]


@sticker("retro", "tv", "Television", ["#C98B4B", "#2B2E33", "#7BF7C4", "#FFFFFF"], ink=1.0)
def _():
    body = box(0, -0.14, 0.88, 0.58, 0.14)
    dark = U(box(-0.12, -0.12, 0.62, 0.46, 0.14), circle(0.7, 0.1, 0.075), circle(0.7, -0.12, 0.075),
             *[seg(0.6, y, 0.8, y, 0.016) for y in (-0.34, -0.42, -0.5)],
             seg(0, 0.46, -0.42, 0.88, 0.025), seg(0, 0.46, 0.4, 0.88, 0.025), circle(0, 0.46, 0.06))
    screen = box(-0.12, -0.12, 0.54, 0.38, 0.1)
    glint = poly([(-0.52, 0.2), (-0.34, 0.2), (-0.56, -0.12), (-0.62, -0.12)])
    return [body, dark, screen, glint]


@sticker("retro", "vhs", "VHS tape", ["#1B1B1F", "#F4F1EA", "#E3172F", "#8A8F98"], ink=1.0)
def _():
    body = box(0, 0, 0.92, 0.56, 0.06)
    label = box(0, 0.12, 0.78, 0.3, 0.03)
    mark = U(box(0, 0.32, 0.78, 0.05), text("VHS", 0, 0.1, 0.18, maxw=0.9))
    window = box(0, -0.36, 0.42, 0.08, 0.03)
    return [body, label, mark, window]


@sticker("retro", "polaroid", "Instant photo", ["#F4F1EA", "#7BD3F7", "#2E9E4F", "#FFD400"], ink=1.0)
def _():
    with rotated(0.1):
        frame = box(0, 0, 0.66, 0.86, 0.05)
        photo = box(0, 0.14, 0.54, 0.54)
        hills = inter(U(circle(-0.3, -0.5, 0.55), circle(0.4, -0.55, 0.5)), photo)
        sun = circle(0.24, 0.42, 0.13)
    return [frame, photo, hills, sun]


@sticker("retro", "shades", "Sunglasses", ["#141418", "#0B6DB8", "#FFFFFF", "#FF2D6F"], ink=1.0)
def _():
    L = spline([(-0.84, 0.18), (-0.1, 0.18), (-0.14, -0.2), (-0.4, -0.36), (-0.7, -0.3), (-0.84, -0.04)])
    lensL = poly(L)
    lensR = poly([(-x, y) for x, y in L])
    lenses = U(lensL, lensR)
    frame = U(lenses - 0.07, seg(-0.2, 0.12, 0.2, 0.12, 0.05), seg(-0.9, 0.2, 0.9, 0.2, 0.05))
    glints = U(seg(-0.68, 0.06, -0.5, 0.06, 0.02), seg(-0.4, 0.06, -0.3, 0.06, 0.02), seg(0.3, 0.06, 0.4, 0.06, 0.02), seg(0.5, 0.06, 0.68, 0.06, 0.02))
    return [frame, lenses, glints, None]


@sticker("retro", "rotary", "Rotary phone", ["#E3172F", "#2B2E33", "#F4F1EA", "#8A8F98"], ink=1.0)
def _():
    body = poly(spline([(-0.84, -0.74), (0.84, -0.74), (0.58, 0.04), (-0.58, 0.04)], n=6)) - 0.04
    handset = U(box(0, 0.42, 0.78, 0.1, 0.1), box(-0.66, 0.28, 0.14, 0.18, 0.07), box(0.66, 0.28, 0.14, 0.18, 0.07))
    dial = circle(0, -0.34, 0.4)
    holes = U(*[circle(0.29 * math.cos(a), -0.34 + 0.29 * math.sin(a), 0.055) for a in np.linspace(math.radians(40), math.radians(320), 10)],
              circle(0, -0.34, 0.1))
    return [body, handset, dial, holes]


@sticker("retro", "jukebox", "Jukebox", ["#E3172F", "#FFC531", "#2B2E33", "#F4F1EA"], ink=1.0)
def _():
    arch = U(box(0, -0.3, 0.66, 0.62, 0.05), inter(circle(0, 0.3, 0.66), 0.3 - Y))
    window = U(box(0, -0.12, 0.48, 0.44, 0.04), inter(circle(0, 0.26, 0.48), 0.26 - Y))
    rec = circle(0, 0.08, 0.3)
    bits = U(circle(0, 0.08, 0.08), *[circle(x, -0.7, 0.05) for x in (-0.36, -0.18, 0.0, 0.18, 0.36)])
    return [arch, window, rec, bits]


@sticker("retro", "lavalamp", "Lava lamp", ["#B58CFF", "#FF2D6F", "#C98B4B", "#FFFFFF"], ink=1.0)
def _():
    glass = poly([(-0.2, 0.58), (0.2, 0.58), (0.38, -0.5), (-0.38, -0.5)]) - 0.03
    lava = inter(U(circle(-0.04, -0.34, 0.3), circle(0.02, -0.02, 0.15), circle(-0.1, 0.24, 0.11), circle(0.08, 0.38, 0.06)), glass)
    ends = U(poly([(-0.22, 0.9), (0.22, 0.9), (0.2, 0.56), (-0.2, 0.56)]) - 0.03, poly([(-0.52, -0.9), (0.52, -0.9), (0.36, -0.5), (-0.36, -0.5)]) - 0.03)
    shine = seg(-0.16, 0.3, -0.26, -0.3, 0.025)
    return [glass, lava, ends, shine]


@sticker("retro", "open", "Open sign", ["#14163A", "#2EE6FF", "#FF2D9B", "#FFD400"], ink=1.0)
def _():
    sign = box(0, 0, 0.92, 0.46, 0.14)
    border = shell(box(0, 0, 0.84, 0.38, 0.1), 0.022)
    word = text("OPEN", 0, 0.0, 0.34, maxw=1.2)
    dots = U(*[circle(x, 0.31, 0.022) for x in np.linspace(-0.5, 0.5, 6)])
    return [sign, border, word, dots]


# ---- ANIMALS (free pack; Pro picks in PRO) — round-faced and friendly -------------------------------------

@sticker("animals", "cat", "Cat", ["#F2A144", "#FFF4E8", "#3A2418", "#FF7A93"], ink=1.0)
def _():
    ears = U(poly([(-0.74, 0.16), (-0.62, 0.92), (-0.12, 0.5)]), poly([(0.74, 0.16), (0.62, 0.92), (0.12, 0.5)])) - 0.03
    head = smin(oval(0, -0.1, 0.76, 0.6), ears, 0.06)
    inner = U(poly([(-0.58, 0.34), (-0.54, 0.74), (-0.28, 0.5)]), poly([(0.58, 0.34), (0.54, 0.74), (0.28, 0.5)]),
              oval(-0.15, -0.32, 0.17, 0.13), oval(0.15, -0.32, 0.17, 0.13))
    feat = U(oval(-0.3, -0.04, 0.085, 0.13), oval(0.3, -0.04, 0.085, 0.13),
             bezier((0, -0.36), (-0.06, -0.46), (-0.18, -0.42), 0.015), bezier((0, -0.36), (0.06, -0.46), (0.18, -0.42), 0.015),
             *[seg(s * 0.5, y0, s * 0.92, y1, 0.012) for s in (-1, 1) for y0, y1 in ((-0.26, -0.2), (-0.34, -0.38), (-0.4, -0.54))],
             *[box(x, 0.42, 0.022, 0.1, 0.02) for x in (-0.14, 0.0, 0.14)])
    nose = poly([(-0.08, -0.24), (0.08, -0.24), (0, -0.34)]) - 0.025
    return [head, inner, feat, nose]


@sticker("animals", "dog", "Dog", ["#D9A066", "#8A5A33", "#FFF4E8", "#1A1410"], ink=1.0)
def _():
    head = oval(0, 0.02, 0.6, 0.62)
    ears = U(*[oval(s * 0.7, 0.06, 0.2, 0.46, s * 0.28) for s in (-1, 1)])
    brown = U(ears, oval(-0.27, 0.12, 0.2, 0.22))
    muzzle = oval(0, -0.3, 0.36, 0.3)
    feat = U(circle(-0.27, 0.12, 0.065), circle(0.27, 0.12, 0.065), oval(0, -0.15, 0.14, 0.095),
             seg(0, -0.24, 0, -0.34, 0.02), bezier((0, -0.34), (-0.08, -0.46), (-0.2, -0.38), 0.02), bezier((0, -0.34), (0.08, -0.46), (0.2, -0.38), 0.02))
    return [U(head, ears), brown, muzzle, feat]


@sticker("animals", "bunny", "Bunny", ["#EFEAE0", "#FFB3C4", "#3A2418", "#FF8FA8"], ink=1.0)
def _():
    ears = U(*[oval(s * 0.3, 0.5, 0.15, 0.38, -s * 0.1) for s in (-1, 1)])
    head = oval(0, -0.24, 0.64, 0.54)
    inner = U(*[oval(s * 0.3, 0.5, 0.075, 0.27, -s * 0.1) for s in (-1, 1)])
    feat = U(oval(-0.26, -0.14, 0.07, 0.1), oval(0.26, -0.14, 0.07, 0.1), seg(0, -0.4, 0, -0.5, 0.018),
             bezier((0, -0.5), (-0.07, -0.58), (-0.17, -0.52), 0.018), bezier((0, -0.5), (0.07, -0.58), (0.17, -0.52), 0.018))
    pink = U(oval(0, -0.37, 0.075, 0.055), circle(-0.44, -0.34, 0.085), circle(0.44, -0.34, 0.085))
    return [U(ears, head), inner, feat, pink]


@sticker("animals", "bear", "Bear", ["#A9713E", "#E9C9A3", "#2A1A10", "#FF8FA8"], ink=1.0)
def _():
    head = U(circle(0, -0.06, 0.66), circle(-0.5, 0.52, 0.23), circle(0.5, 0.52, 0.23))
    cream = U(circle(-0.5, 0.52, 0.12), circle(0.5, 0.52, 0.12), oval(0, -0.26, 0.32, 0.26))
    feat = U(circle(-0.26, 0.02, 0.07), circle(0.26, 0.02, 0.07), oval(0, -0.16, 0.12, 0.085), seg(0, -0.24, 0, -0.32, 0.018),
             bezier((0, -0.32), (-0.08, -0.42), (-0.18, -0.35), 0.018), bezier((0, -0.32), (0.08, -0.42), (0.18, -0.35), 0.018))
    cheeks = U(circle(-0.46, -0.16, 0.085), circle(0.46, -0.16, 0.085))
    return [head, cream, feat, cheeks]


@sticker("animals", "panda", "Panda", ["#FFFFFF", "#141418", "#FFFFFF", "#FF8FA8"], ink=1.0)
def _():
    head = oval(0, -0.06, 0.7, 0.64)
    black = U(circle(-0.52, 0.52, 0.25), circle(0.52, 0.52, 0.25), oval(-0.29, 0.0, 0.15, 0.21, -0.52), oval(0.29, 0.0, 0.15, 0.21, 0.52),
              oval(0, -0.2, 0.1, 0.07), seg(0, -0.26, 0, -0.34, 0.018),
              bezier((0, -0.34), (-0.08, -0.44), (-0.18, -0.38), 0.018), bezier((0, -0.34), (0.08, -0.44), (0.18, -0.38), 0.018))
    glint = U(circle(-0.28, 0.04, 0.045), circle(0.28, 0.04, 0.045))
    cheeks = U(circle(-0.5, -0.24, 0.085), circle(0.5, -0.24, 0.085))
    return [U(head), black, glint, cheeks]


@sticker("animals", "fox", "Fox", ["#F26B21", "#FFF4E8", "#2A1A10", "#FF8FA8"], ink=1.0)
def _():
    face = poly([(-0.84, 0.3), (-0.74, 0.94), (-0.3, 0.52), (0.3, 0.52), (0.74, 0.94), (0.84, 0.3), (0.52, -0.4), (0, -0.84), (-0.52, -0.4)]) - 0.03
    cream = poly([(-0.82, 0.14), (-0.5, -0.38), (0, -0.82), (0.5, -0.38), (0.82, 0.14), (0.36, -0.12), (0, 0.0), (-0.36, -0.12)]) - 0.02
    dark = U(poly([(-0.66, 0.4), (-0.64, 0.8), (-0.4, 0.56)]), poly([(0.66, 0.4), (0.64, 0.8), (0.4, 0.56)]),
             oval(-0.3, 0.16, 0.1, 0.06, -0.4), oval(0.3, 0.16, 0.1, 0.06, 0.4), circle(0, -0.76, 0.075),
             seg(-0.2, -0.5, 0, -0.62, 0.014), seg(0.2, -0.5, 0, -0.62, 0.014))
    cheeks = U(circle(-0.48, -0.06, 0.07), circle(0.48, -0.06, 0.07))
    return [face, cream, dark, cheeks]


@sticker("animals", "owl", "Owl", ["#8A5A33", "#F4E3C8", "#1A1410", "#FFB300"], ink=1.0)
def _():
    body = U(oval(0, -0.06, 0.66, 0.82), poly([(-0.6, 0.5), (-0.72, 0.92), (-0.22, 0.72)]), poly([(0.6, 0.5), (0.72, 0.92), (0.22, 0.72)]))
    light = U(oval(0, -0.4, 0.4, 0.42), circle(-0.3, 0.2, 0.28), circle(0.3, 0.2, 0.28))
    dark = U(circle(-0.3, 0.2, 0.13), circle(0.3, 0.2, 0.13),
             *[bezier((x - 0.1, -0.36 + dy), (x, -0.28 + dy), (x + 0.1, -0.36 + dy), 0.014) for x in (-0.18, 0.18) for dy in (0.0, -0.2)],
             box(-0.3, -0.84, 0.08, 0.04, 0.02), box(0.3, -0.84, 0.08, 0.04, 0.02))
    beak = poly([(-0.1, 0.1), (0.1, 0.1), (0, -0.14)]) - 0.02
    return [body, light, dark, U(beak, ring(-0.3, 0.2, 0.28, 0.025), ring(0.3, 0.2, 0.28, 0.025))]


@sticker("animals", "penguin", "Penguin", ["#1E2740", "#FFFFFF", "#FF9F1C", "#141418"], ink=1.0)
def _():
    body = U(oval(0, -0.05, 0.56, 0.86), *[oval(s * 0.66, -0.12, 0.13, 0.36, s * 0.35) for s in (-1, 1)])
    belly = U(oval(0, -0.14, 0.4, 0.68), circle(-0.2, 0.36, 0.14), circle(0.2, 0.36, 0.14))
    orange = U(poly([(-0.14, 0.2), (0.14, 0.2), (0, -0.02)]) - 0.03, oval(-0.24, -0.88, 0.2, 0.06), oval(0.24, -0.88, 0.2, 0.06))
    eyes = U(circle(-0.2, 0.36, 0.06), circle(0.2, 0.36, 0.06))
    return [body, belly, orange, eyes]


@sticker("animals", "frog", "Frog", ["#5FBF4A", "#FFFFFF", "#1A2A12", "#FF8FA8"], ink=1.0)
def _():
    head = U(oval(0, -0.2, 0.84, 0.56), circle(-0.4, 0.4, 0.28), circle(0.4, 0.4, 0.28))
    whites = U(circle(-0.4, 0.42, 0.2), circle(0.4, 0.42, 0.2))
    dark = U(circle(-0.4, 0.42, 0.1), circle(0.4, 0.42, 0.1), arc(0, -0.12, 0.52, math.radians(215), math.radians(325), 0.03),
             circle(-0.1, 0.0, 0.025), circle(0.1, 0.0, 0.025))
    cheeks = U(circle(-0.62, -0.18, 0.1), circle(0.62, -0.18, 0.1))
    return [head, whites, dark, cheeks]


@sticker("animals", "fish", "Fish", ["#FF8A1F", "#FFFFFF", "#1A1410", "#FFD400"], ink=1.0)
def _():
    body = oval(-0.12, 0.0, 0.62, 0.42)
    tail = poly([(0.42, 0.0), (0.92, 0.4), (0.84, 0.0), (0.92, -0.4)]) - 0.03
    fish = smin(body, tail, 0.1)
    bands = inter(fish, stripes(0.34, 0.0, 0.34, -0.1))
    dark = U(circle(-0.5, 0.08, 0.06), bezier((-0.72, -0.1), (-0.66, -0.16), (-0.6, -0.12), 0.015), arc(-0.2, 0.0, 0.42, math.radians(140), math.radians(220), 0.015))
    fins = U(poly([(-0.2, 0.36), (0.1, 0.36), (0.0, 0.66)]), poly([(-0.16, -0.36), (0.06, -0.36), (-0.02, -0.6)]))
    return [fish, bands, dark, fins]


@sticker("animals", "octopus", "Octopus", ["#B058E6", "#E3B8F5", "#FFFFFF", "#1A1410"], ink=1.0)
def _():
    head = circle(0, 0.2, 0.56)
    tents = U(brush([(-0.34, -0.1), (-0.7, -0.3), (-0.82, -0.62), (-0.55, -0.82), (-0.38, -0.66)], [0.17, 0.14, 0.11, 0.08, 0.04]),
              brush([(-0.12, -0.14), (-0.2, -0.5), (-0.34, -0.78), (-0.1, -0.9)], [0.15, 0.12, 0.09, 0.04]),
              brush([(0.12, -0.14), (0.2, -0.5), (0.34, -0.78), (0.1, -0.9)], [0.15, 0.12, 0.09, 0.04]),
              brush([(0.34, -0.1), (0.7, -0.3), (0.82, -0.62), (0.55, -0.82), (0.38, -0.66)], [0.17, 0.14, 0.11, 0.08, 0.04]))
    octo = smin(head, tents, 0.1)
    spots = U(circle(-0.3, 0.55, 0.05), circle(0.1, 0.62, 0.06), circle(0.34, 0.48, 0.04), circle(-0.05, 0.46, 0.035))
    eyes = U(circle(-0.22, 0.14, 0.15), circle(0.22, 0.14, 0.15))
    pupils = U(circle(-0.2, 0.12, 0.07), circle(0.24, 0.12, 0.07), arc(0, -0.04, 0.12, math.radians(215), math.radians(325), 0.02))
    return [octo, spots, eyes, pupils]


@sticker("animals", "bee", "Bee", ["#FFD233", "#2B2E33", "#CFE9FF", "#FFFFFF"], ink=1.0)
def _():
    body = oval(0.08, -0.12, 0.58, 0.42)
    head = circle(-0.56, -0.08, 0.28)
    dark = U(inter(body, stripes(0.34, 0.0, 0.45, 0.1)), head, poly([(0.6, -0.12), (0.88, -0.12), (0.6, -0.02)]) - 0.0,
             bezier((-0.6, 0.14), (-0.66, 0.4), (-0.84, 0.46), 0.014), bezier((-0.5, 0.18), (-0.5, 0.44), (-0.34, 0.52), 0.014))
    wings = U(oval(-0.02, 0.5, 0.24, 0.36, 0.5), oval(0.3, 0.48, 0.24, 0.34, -0.3))
    eye = U(circle(-0.62, -0.02, 0.07), arc(-0.56, -0.12, 0.14, math.radians(230), math.radians(300), 0.015))
    return [U(body, head), dark, wings, eye]


# ---- FOOD (free pack; Pro picks in PRO) — the savoury side of SWEETS --------------------------------------

@sticker("food", "pizza", "Pizza", ["#E9A75B", "#FFC531", "#E3172F", "#2E9E4F"], ink=1.0)
def _():
    wedge = U(poly([(-0.7, 0.5), (0.7, 0.5), (0, -0.92)]) - 0.04, box(0, 0.6, 0.76, 0.16, 0.15))
    cheese = poly([(-0.56, 0.44), (0.56, 0.44), (0, -0.74)]) - 0.03
    pep = U(circle(-0.26, 0.22, 0.12), circle(0.22, 0.18, 0.11), circle(-0.04, -0.15, 0.11), circle(0.03, -0.5, 0.075))
    leaf = U(oval(0.32, -0.1, 0.1, 0.05, 0.6), oval(-0.3, -0.12, 0.09, 0.045, -0.5), oval(0.05, 0.4, 0.1, 0.05, 0.2))
    return [wedge, cheese, pep, leaf]


@sticker("food", "burger", "Burger", ["#E9A75B", "#5A3420", "#4FBF4A", "#E3172F"], ink=1.0)
def _():
    buns = U(inter(oval(0, 0.08, 0.84, 0.62), 0.08 - Y), box(0, -0.52, 0.78, 0.13, 0.12))
    patty = box(0, -0.22, 0.86, 0.14, 0.12)
    lettuce = U(*[circle(x, 0.0, 0.1) for x in np.linspace(-0.74, 0.74, 8)], box(0, 0.0, 0.8, 0.05))
    tomato = box(0, -0.1, 0.74, 0.05, 0.03)
    return [buns, patty, lettuce, tomato]


@sticker("food", "fries", "Fries", ["#FFD233", "#E3172F", "#FFF4E8", "#9D1220"], ink=1.0)
def _():
    angs = [0.22, 0.12, 0.05, 0.0, -0.06, -0.14, -0.24]
    sticks = U(*[box(x, 0.32 + 0.05 * math.sin(i * 2.3), 0.065, 0.46, 0.03, a) for i, (x, a) in enumerate(zip(np.linspace(-0.42, 0.42, 7), angs))])
    carton = poly([(-0.56, -0.06), (0.56, -0.06), (0.42, -0.88), (-0.42, -0.88)]) - 0.03
    word = text("FRIES", 0, -0.44, 0.15, maxw=0.8)
    rim = box(0, -0.08, 0.56, 0.04, 0.02)
    return [sticks, carton, word, rim]


@sticker("food", "taco", "Taco", ["#D99A2B", "#4FBF4A", "#F2C14E", "#E3172F"], ink=1.0)
def _():
    back = inter(oval(0, 0.2, 0.86, 0.66), 0.2 - Y)                      # the far wall of the shell, rising behind the filling
    lettuce = U(*[circle(x, 0.3 + 0.03 * math.sin(i * 1.7), 0.115) for i, x in enumerate(np.linspace(-0.66, 0.66, 8))])
    front = inter(circle(0, 0.2, 0.88), Y - 0.2)                          # the near wall, in front of everything
    tomato = U(circle(-0.3, 0.44, 0.08), circle(0.16, 0.48, 0.08), circle(0.44, 0.38, 0.07), circle(-0.02, 0.36, 0.06))
    return [back, lettuce, front, tomato]


@sticker("food", "hotdog", "Hot dog", ["#E9A75B", "#C2452D", "#D9954A", "#FFD400"], ink=1.0)
def _():
    with rotated(0.45):
        bun = box(0, -0.12, 0.8, 0.26, 0.26)
        dog = box(0, 0.08, 0.88, 0.15, 0.15)
        front = inter(box(0, -0.14, 0.8, 0.22, 0.22), Y + 0.04)
        xs = np.linspace(-0.7, 0.7, 9)
        mustard = polyline([(x, 0.13 + (0.07 if i % 2 else -0.0)) for i, x in enumerate(xs)], 0.03)
    return [bun, dog, front, mustard]


@sticker("food", "sushi", "Sushi", ["#FFFFFF", "#FF7F50", "#FFE9E0", "#1E3A2E"], ink=1.0)
def _():
    rice = box(0, -0.22, 0.74, 0.3, 0.28)
    fish = box(0, 0.12, 0.84, 0.24, 0.2)
    fat = inter(fish, stripes(0.32, 0.7, 0.16, 0.0))
    nori = box(0, -0.04, 0.095, 0.5)
    return [rice, fish, fat, nori]


@sticker("food", "egg", "Fried egg", ["#FFFFFF", "#FFB300", "#FF8A00", "#FFF4C7"], ink=1.0)
def _():
    white = smin(smin(circle(-0.3, 0.2, 0.46), circle(0.34, 0.14, 0.5), 0.2), smin(circle(0.0, -0.4, 0.44), circle(-0.5, -0.3, 0.3), 0.2), 0.2)
    yolk = circle(0.02, -0.02, 0.3)
    shade = inter(yolk, X * 0.6 - Y * 0.8 - 0.05)
    shine = oval(-0.1, 0.1, 0.1, 0.06, 0.6)
    return [white, yolk, shade, shine]


@sticker("food", "coffee", "Coffee", ["#F4F1EA", "#2B2E33", "#C98B4B", "#FF8A9C"], ink=1.0)
def _():
    cup = poly([(-0.46, 0.34), (0.46, 0.34), (0.36, -0.88), (-0.36, -0.88)]) - 0.03
    lid = U(box(0, 0.46, 0.54, 0.1, 0.05), box(0, 0.62, 0.4, 0.07, 0.04))
    sleeve = inter(poly([(-0.46, 0.1), (0.46, 0.1), (0.41, -0.44), (-0.41, -0.44)]), cup + 0.02)
    love = heart(0, -0.13, 0.25)
    return [cup, lid, sleeve, love]


@sticker("food", "popcorn", "Popcorn", ["#F4F1EA", "#E3172F", "#FFF2C2", "#FFC531"], ink=1.0)
def _():
    bucket = poly([(-0.56, 0.12), (0.56, 0.12), (0.42, -0.88), (-0.42, -0.88)]) - 0.03
    bands = inter(bucket, stripes(0.36, 0.0, 0.5, 0.05))
    corn = U(*[circle(x, y, r) for x, y, r in [(-0.4, 0.3, 0.2), (0.0, 0.4, 0.24), (0.4, 0.3, 0.2), (-0.2, 0.62, 0.18),
                                                (0.24, 0.64, 0.18), (-0.64, 0.18, 0.13), (0.64, 0.16, 0.13)]])
    butter = U(circle(-0.2, 0.35, 0.06), circle(0.26, 0.52, 0.06), circle(0.05, 0.2, 0.05), circle(-0.4, 0.45, 0.05), circle(0.5, 0.32, 0.05))
    return [bucket, bands, corn, butter]


@sticker("food", "avocado", "Avocado", ["#3E7B2E", "#B7D96B", "#8A5A33", "#C98B4B"], ink=1.0)
def _():
    outer = smin(circle(0, -0.28, 0.56), circle(0, 0.4, 0.34), 0.5)
    flesh = outer + 0.1
    pit = circle(0, -0.2, 0.26)
    shine = oval(-0.1, -0.12, 0.05, 0.11, 0.4)
    return [outer, flesh, pit, shine]


@sticker("food", "ramen", "Ramen", ["#F4F1EA", "#E3172F", "#FFD233", "#FFFFFF"], ink=1.0)
def _():
    bowl = U(inter(circle(0, 0.12, 0.88), Y - 0.12), box(0, 0.12, 0.92, 0.05, 0.05))
    band = inter(bowl, box(0, -0.4, 0.9, 0.07))
    dome = inter(circle(0, 0.12, 0.7), 0.12 - Y)
    waves = U(*[bezier((-0.62, 0.2 + k * 0.14), (-0.2, 0.3 + k * 0.14), (0.0, 0.2 + k * 0.14), 0.016) for k in range(3)],
              *[bezier((0.0, 0.2 + k * 0.14), (0.3, 0.12 + k * 0.14), (0.62, 0.24 + k * 0.14), 0.016) for k in range(3)])
    noodles = sub(dome, waves)
    egg = U(circle(-0.3, 0.34, 0.16), circle(0.26, 0.4, 0.13))
    return [bowl, band, noodles, egg]


@sticker("food", "chili", "Chili", ["#E3172F", "#9D1220", "#2E9E4F", "#FF8A9C"], ink=1.0)
def _():
    pepper = brush([(-0.45, 0.4), (0.0, 0.36), (0.45, -0.1), (0.72, -0.72)], [0.3, 0.3, 0.22, 0.04])
    shade = inter(pepper, X * 0.6 - Y * 0.9 - 0.42)
    green = U(oval(-0.5, 0.5, 0.22, 0.12, -0.3), seg(-0.58, 0.56, -0.74, 0.84, 0.055))
    shine = seg(-0.32, 0.52, 0.05, 0.5, 0.03)
    return [pepper, shade, green, shine]


# ---- FACES (free pack; Pro picks in PRO) — expressions, not emoji ----------------------------------------

def _face():
    f = circle(0, 0, 0.86)
    return f, inter(f, -circle(-0.15, 0.15, 0.82))


@sticker("faces", "cool", "Cool", ["#FFD233", "#F2A900", "#1A1410", "#FFFFFF"], ink=1.0)
def _():
    f, shade = _face()
    dark = U(box(-0.34, 0.12, 0.3, 0.2, 0.12), box(0.34, 0.12, 0.3, 0.2, 0.12), seg(-0.06, 0.2, 0.06, 0.2, 0.04),
             seg(-0.64, 0.22, -0.84, 0.3, 0.04), seg(0.64, 0.22, 0.84, 0.3, 0.04), arc(0, -0.1, 0.46, math.radians(215), math.radians(325), 0.045))
    glints = U(seg(-0.5, 0.2, -0.36, 0.2, 0.025), seg(-0.46, 0.1, -0.4, 0.1, 0.02), seg(0.2, 0.2, 0.34, 0.2, 0.025))
    return [f, shade, dark, glints]


@sticker("faces", "wink", "Wink", ["#FFD233", "#F2A900", "#1A1410", "#FF8A9C"], ink=1.0)
def _():
    f, shade = _face()
    dark = U(oval(-0.3, 0.2, 0.09, 0.15), arc(0.3, 0.18, 0.16, math.radians(30), math.radians(150), 0.04),
             arc(0, 0.0, 0.5, math.radians(210), math.radians(330), 0.045))
    return [f, shade, dark, U(circle(-0.56, -0.1, 0.1), circle(0.56, -0.1, 0.1))]


@sticker("faces", "love", "Heart eyes", ["#FFD233", "#F2A900", "#1A1410", "#E3172F"], ink=1.0)
def _():
    f, shade = _face()
    dark = U(arc(0, -0.04, 0.5, math.radians(210), math.radians(330), 0.045))
    hearts = U(heart(-0.33, 0.2, 0.3), heart(0.33, 0.2, 0.3))
    return [f, shade, dark, hearts]


@sticker("faces", "lol", "Laughing", ["#FFD233", "#F2A900", "#1A1410", "#5BC8FF"], ink=1.0)
def _():
    f, shade = _face()
    eyes = U(polyline([(-0.5, 0.36), (-0.26, 0.24), (-0.5, 0.12)], 0.045), polyline([(0.5, 0.36), (0.26, 0.24), (0.5, 0.12)], 0.045))
    mouth = inter(circle(0, 0.06, 0.52), Y - 0.06)
    tears = U(taper(-0.62, 0.14, -0.7, -0.2, 0.08, 0.03), circle(-0.7, -0.22, 0.045), taper(0.62, 0.14, 0.7, -0.2, 0.08, 0.03), circle(0.7, -0.22, 0.045))
    return [f, shade, U(eyes, mouth), tears]


@sticker("faces", "angry", "Angry", ["#FF5A36", "#C2321A", "#FFFFFF", "#1A1410"], ink=1.0)
def _():
    f, shade = _face()
    teeth = U(*[box(x, -0.34, 0.075, 0.1, 0.02) for x in (-0.2, -0.0, 0.2)])
    dark = U(seg(-0.58, 0.46, -0.14, 0.22, 0.07), seg(0.58, 0.46, 0.14, 0.22, 0.07), circle(-0.3, 0.06, 0.08), circle(0.3, 0.06, 0.08),
             sub(box(0, -0.34, 0.34, 0.16, 0.06), teeth))
    return [f, shade, teeth, dark]


@sticker("faces", "shock", "Shocked", ["#FFD233", "#F2A900", "#FFFFFF", "#1A1410"], ink=1.0)
def _():
    f, shade = _face()
    whites = U(circle(-0.3, 0.14, 0.22), circle(0.3, 0.14, 0.22))
    dark = U(circle(-0.3, 0.14, 0.09), circle(0.3, 0.14, 0.09), oval(0, -0.38, 0.16, 0.22),
             arc(-0.3, 0.46, 0.22, math.radians(60), math.radians(120), 0.04), arc(0.3, 0.46, 0.22, math.radians(60), math.radians(120), 0.04))
    return [f, shade, whites, dark]


@sticker("faces", "sleepy", "Sleepy", ["#FFD233", "#F2A900", "#1A1410", "#3A86FF"], ink=1.0)
def _():
    f, shade = _face()
    dark = U(arc(-0.3, 0.16, 0.17, math.radians(200), math.radians(340), 0.04), arc(0.3, 0.16, 0.17, math.radians(200), math.radians(340), 0.04),
             oval(0, -0.3, 0.1, 0.07))
    zz = U(text("Z", 0.42, 0.5, 0.26, ang=-0.15), text("z", 0.7, 0.8, 0.14, ang=-0.15))
    return [f, shade, dark, zz]


@sticker("faces", "robot", "Robot", ["#C9CED6", "#8A8F98", "#2B2E33", "#2EE6FF"], ink=1.0)
def _():
    head = box(0, -0.12, 0.8, 0.62, 0.16)
    shade = inter(head, X * 0.6 - Y * 0.5 - 0.35)
    dark = U(box(0, 0.0, 0.6, 0.26, 0.1), *[seg(x, -0.44, x, -0.3, 0.02) for x in np.linspace(-0.3, 0.3, 7)],
             seg(0, 0.5, 0, 0.72, 0.04), circle(0, 0.78, 0.09), circle(-0.8, -0.12, 0.1), circle(0.8, -0.12, 0.1))
    eyes = U(circle(-0.28, 0.0, 0.11), circle(0.28, 0.0, 0.11))
    return [head, shade, dark, eyes]


@sticker("faces", "cry", "Crying", ["#FFD233", "#F2A900", "#1A1410", "#5BC8FF"], ink=1.0)
def _():
    f, shade = _face()
    dark = U(seg(-0.56, 0.4, -0.16, 0.5, 0.05), seg(0.56, 0.4, 0.16, 0.5, 0.05),
             arc(-0.3, 0.18, 0.15, math.radians(200), math.radians(340), 0.04), arc(0.3, 0.18, 0.15, math.radians(200), math.radians(340), 0.04),
             arc(0, -0.62, 0.36, math.radians(50), math.radians(130), 0.05))
    tears = U(taper(-0.3, 0.1, -0.36, -0.6, 0.07, 0.04), circle(-0.36, -0.62, 0.05), taper(0.3, 0.1, 0.36, -0.6, 0.07, 0.04), circle(0.36, -0.62, 0.05))
    return [f, shade, dark, tears]


@sticker("faces", "party", "Party", ["#FFD233", "#F2A900", "#1A1410", "#FF2D9B"], ink=1.0)
def _():
    face = circle(0, -0.26, 0.66)
    shade = inter(face, -circle(-0.12, -0.14, 0.62))
    dark = U(oval(-0.24, -0.16, 0.07, 0.11), oval(0.24, -0.16, 0.07, 0.11), arc(0, -0.34, 0.4, math.radians(215), math.radians(325), 0.045))
    with rotated(-0.22, 0.0, 0.3):
        hat = U(poly([(-0.34, 0.3), (0.34, 0.3), (0, 0.8)]) - 0.02, circle(0, 0.8, 0.085))
    return [face, shade, dark, hat]


@sticker("faces", "nerd", "Nerd", ["#FFD233", "#F2A900", "#1A1410", "#FFFFFF"], ink=1.0)
def _():
    f, shade = _face()
    dark = U(ring(-0.3, 0.12, 0.24, 0.04), ring(0.3, 0.12, 0.24, 0.04), seg(-0.06, 0.14, 0.06, 0.14, 0.04), seg(-0.54, 0.16, -0.84, 0.24, 0.035),
             seg(0.54, 0.16, 0.84, 0.24, 0.035), circle(-0.3, 0.12, 0.06), circle(0.3, 0.12, 0.06), arc(0, -0.04, 0.46, math.radians(215), math.radians(325), 0.045))
    teeth = box(0, -0.36, 0.13, 0.1, 0.02)
    return [f, shade, dark, sub(teeth, seg(0, -0.46, 0, -0.26, 0.012))]


@sticker("faces", "tongue", "Silly", ["#FFD233", "#F2A900", "#1A1410", "#FF5F8A"], ink=1.0)
def _():
    f, shade = _face()
    dark = U(circle(-0.3, 0.2, 0.09), polyline([(0.18, 0.34), (0.42, 0.22), (0.18, 0.1)], 0.045), arc(0, 0.0, 0.5, math.radians(210), math.radians(330), 0.045))
    tongue = sub(U(box(0.06, -0.52, 0.17, 0.2, 0.12), circle(0.06, -0.62, 0.17)), seg(0.06, -0.7, 0.06, -0.42, 0.012))
    return [f, shade, dark, tongue]


# ---- NATURE (free pack; Pro picks in PRO) ----------------------------------------------------------------

@sticker("nature", "daisy", "Daisy", ["#FFFFFF", "#FFD400", "#E6E2DA", "#8A5A33"], ink=1.0)
def _():
    pet = petals(0, 0, 12, 0.52, 0.36, 0.135)
    centre = circle(0, 0, 0.27)
    ringshade = inter(pet, circle(0, 0, 0.5))
    seeds = U(*[circle(0.2 * math.sqrt(k / 22.0) * math.cos(k * 2.4), 0.2 * math.sqrt(k / 22.0) * math.sin(k * 2.4), 0.028) for k in range(22)])
    return [pet, centre, ringshade, seeds]


@sticker("nature", "sunflower", "Sunflower", ["#FFC531", "#FF9F1C", "#5A3420", "#2A1A10"], ink=1.0)
def _():
    outer = petals(0, 0, 16, 0.62, 0.3, 0.1)
    inner = petals(0, 0, 16, 0.56, 0.24, 0.065, math.pi / 16)
    disc = circle(0, 0, 0.4)
    seeds = U(*[circle(0.35 * math.sqrt(k / 70.0) * math.cos(k * 2.39996), 0.35 * math.sqrt(k / 70.0) * math.sin(k * 2.39996), 0.022) for k in range(70)])
    return [outer, inner, disc, seeds]


@sticker("nature", "tulip", "Tulip", ["#2E9E4F", "#FF4F6A", "#C2185B", "#FFC2D1"], ink=1.0)
def _():
    green = U(seg(0, -0.3, 0, -0.9, 0.055), oval(-0.28, -0.6, 0.32, 0.1, 0.7), oval(0.28, -0.52, 0.32, 0.1, -0.6))
    cup = sub(oval(0, 0.2, 0.52, 0.58), U(poly([(-0.28, 0.95), (-0.1, 0.52), (-0.02, 0.95)]), poly([(0.28, 0.95), (0.1, 0.52), (0.02, 0.95)])))
    shade = inter(cup, X * 0.7 - 0.12)
    shine = seg(-0.3, 0.1, -0.24, 0.5, 0.03)
    return [green, cup, shade, shine]


@sticker("nature", "mushroom", "Mushroom", ["#F4E3C8", "#E3172F", "#FFFFFF", "#9D1220"], ink=1.0)
def _():
    stem = box(0, -0.46, 0.27, 0.4, 0.14)
    cap = inter(oval(0, -0.08, 0.88, 0.72), -0.08 - Y)
    spots = U(circle(-0.4, 0.28, 0.14), circle(0.12, 0.42, 0.17), circle(0.52, 0.16, 0.12), circle(-0.1, 0.08, 0.08), circle(-0.62, 0.0, 0.07))
    rim = inter(cap, Y - 0.0)
    return [stem, cap, inter(spots, cap), rim]


@sticker("nature", "leaf", "Leaf", ["#4FBF4A", "#2E9E4F", "#B7D96B", "#8A5A33"], ink=1.0)
def _():
    with rotated(-0.7):
        blade = inter(circle(-0.6, 0.0, 1.05), circle(0.6, 0.0, 1.05))
        right = inter(blade, X)
        veins = U(seg(0, -0.74, 0, 0.7, 0.026), *[seg(0, y, s * 0.32, y + 0.22, 0.018) for y in (-0.42, -0.14, 0.14, 0.4) for s in (-1, 1)])
        stem = seg(0, -0.74, 0.0, -0.98, 0.04)
    return [blade, right, inter(veins, blade), stem]


@sticker("nature", "clover", "Clover", ["#2E9E4F", "#4FBF4A", "#B7D96B", "#1F6B34"], ink=1.0)
def _():
    leaves, lines = [], []
    for k in range(4):
        with rotated(k * math.pi / 2 + math.pi / 4):
            leaves.append(heart(0, 0.4, 0.4))
            lines.append(seg(0, 0.05, 0, 0.55, 0.02))
    allv = U(*leaves)
    stem = bezier((0.0, -0.1), (0.1, -0.5), (0.34, -0.8), 0.04)
    return [allv, inter(U(*lines), allv), U(circle(0, 0, 0.07)), stem]


@sticker("nature", "pine", "Pine", ["#2E7D4F", "#1F5A38", "#8A5A33", "#FFFFFF"], ink=1.0)
def _():
    t1 = poly([(-0.64, -0.2), (0.64, -0.2), (0, 0.3)])
    t2 = poly([(-0.52, 0.12), (0.52, 0.12), (0, 0.62)])
    t3 = poly([(-0.4, 0.44), (0.4, 0.44), (0, 0.92)])
    tiers = U(t1, t2, t3)
    snow = U(inter(t3, Y - 0.66), inter(t2, Y - 0.38), inter(t1, Y - 0.06))
    return [tiers, inter(tiers, X), box(0, -0.58, 0.1, 0.3), snow]


@sticker("nature", "mountain", "Mountains", ["#5B6B8C", "#3F4C68", "#FFFFFF", "#FFD400"], ink=1.0)
def _():
    big = poly([(-0.92, -0.62), (-0.14, 0.72), (0.5, -0.62)])
    small = poly([(0.0, -0.62), (0.5, 0.18), (0.94, -0.62)])
    ms = U(big, small)
    dark = U(inter(big, X + 0.14), inter(small, X - 0.5))
    snow = U(inter(big, 0.3 - Y), inter(small, 0.0 - Y))
    snow = sub(snow, U(*[circle(x, 0.22, 0.09) for x in (-0.3, -0.1, 0.1)]))
    return [ms, dark, snow, circle(-0.7, 0.55, 0.18)]


@sticker("nature", "rainbow", "Rainbow", ["#E3172F", "#FFD400", "#1FB6FF", "#FFFFFF"], ink=1.0)
def _():
    r1 = arc(0, -0.3, 0.74, 0.0, math.pi, 0.085, steps=60)
    r2 = arc(0, -0.3, 0.57, 0.0, math.pi, 0.085, steps=60)
    r3 = arc(0, -0.3, 0.4, 0.0, math.pi, 0.085, steps=60)
    clouds = U(circle(-0.62, -0.4, 0.2), circle(-0.4, -0.46, 0.17), circle(-0.82, -0.5, 0.14), circle(0.62, -0.4, 0.2), circle(0.4, -0.46, 0.17), circle(0.82, -0.5, 0.14),
               box(-0.6, -0.56, 0.3, 0.1, 0.1), box(0.6, -0.56, 0.3, 0.1, 0.1))
    return [r1, r2, r3, clouds]


@sticker("nature", "raincloud", "Storm cloud", ["#C9D4E3", "#8FA3BF", "#3A86FF", "#FFD400"], ink=1.0)
def _():
    cloud = U(circle(-0.4, 0.34, 0.3), circle(0.0, 0.46, 0.38), circle(0.4, 0.32, 0.3), box(0, 0.2, 0.7, 0.2, 0.2))
    shade = inter(cloud, Y - 0.26)
    rain = U(*[seg(x, -0.0, x - 0.08, -0.26, 0.035) for x in (-0.62, -0.4)], *[seg(x, -0.0, x - 0.08, -0.26, 0.035) for x in (0.4, 0.62)],
             *[seg(x, -0.42, x - 0.08, -0.62, 0.03) for x in (-0.52, 0.5)])
    bolt = poly([(0.02, 0.02), (0.24, 0.02), (0.1, -0.3), (0.28, -0.3), (-0.1, -0.84), (-0.02, -0.46), (-0.18, -0.46)])
    return [cloud, shade, rain, bolt]


@sticker("nature", "snowflake", "Snowflake", ["#1FB6FF", "#FFFFFF", "#CFE9FF", "#9FE8FF"], ink=1.0)
def _():
    disc = circle(0, 0, 0.9)
    arms = []
    for k in range(6):
        a = k * math.pi / 3 + math.pi / 2
        c, s = math.cos(a), math.sin(a)
        arms.append(seg(0, 0, 0.74 * c, 0.74 * s, 0.045))
        for t in (0.34, 0.54):
            bx, by = t * c, t * s
            for da in (-0.8, 0.8):
                arms.append(seg(bx, by, bx + 0.2 * math.cos(a + da), by + 0.2 * math.sin(a + da), 0.036))
    flake = U(*arms)
    return [disc, flake, regpoly(0, 0, 6, 0.15), U(*[circle(x, y, 0.025) for x, y in [(0.7, 0.5), (-0.65, 0.55), (0.55, -0.7), (-0.5, -0.66)]])]


@sticker("nature", "shell", "Shell", ["#FFB3C4", "#FF8FA8", "#E8639A", "#FFFFFF"], ink=1.0)
def _():
    hx, hy = 0.0, -0.58
    ang = np.arctan2(Y - hy, X - hx)
    rr = np.hypot(X - hx, Y - hy)
    scallop = rr - (1.0 + 0.045 * np.cos(ang * 10.0))
    wedge = poly([(hx, hy), (hx + 3 * math.cos(math.pi / 2 - 1.12), hy + 3 * math.sin(math.pi / 2 - 1.12)),
                  (hx + 3 * math.cos(math.pi / 2 + 1.12), hy + 3 * math.sin(math.pi / 2 + 1.12))])
    fan = inter(scallop, wedge)
    ridges = inter(U(*[seg(hx, hy, hx + 1.3 * math.cos(a), hy + 1.3 * math.sin(a), 0.022) for a in np.linspace(math.pi / 2 - 1.0, math.pi / 2 + 1.0, 9)]), fan)
    base = U(box(0, -0.62, 0.22, 0.1, 0.05), seg(-0.18, -0.58, -0.3, -0.66, 0.05), seg(0.18, -0.58, 0.3, -0.66, 0.05))
    shine = arc(hx, hy, 0.62, math.radians(105), math.radians(135), 0.02)
    return [fan, ridges, base, shine]


# ---- ARCADE (free pack; Pro picks in PRO) — pixels, cartridges and a game-over screen --------------------

@sticker("arcade", "heart8", "Pixel heart", ["#E3172F", "#FFFFFF", "#9D1220", "#141418"], ink=1.0)
def _():
    rows = [".###.###.", "#########", "#########", "#########", ".#######.", "..#####..", "...###...", "....#...."]
    hl = pixsub(rows, lambda i, j, w, h: (i, j) in ((1, 1), (2, 1), (1, 2)))
    sh = pixsub(rows, lambda i, j, w, h: (i - w / 2) * 0.7 - (j - h / 2) > 1.6)
    return [pix(rows, 0, 0, 0.19), pix(hl, 0, 0, 0.19), pix(sh, 0, 0, 0.19), None]


@sticker("arcade", "star8", "Pixel star", ["#FFD400", "#FF9F1C", "#FFFFFF", "#141418"], ink=1.0)
def _():
    rows = [".....#.....", "....###....", "....###....", "...#####...", "###########", ".#########.", "..#######..", "..#######..", ".####.####.", ".###...###."]
    sh = pixsub(rows, lambda i, j, w, h: (i - w / 2 + 0.5) * 0.8 + (j - h / 2) * 0.35 > 0.9)
    hl = pixsub(rows, lambda i, j, w, h: (i, j) in ((4, 3), (3, 4), (4, 4), (4, 2)))
    return [pix(rows, 0, 0.0, 0.16), pix(sh, 0, 0.0, 0.16), pix(hl, 0, 0.0, 0.16), None]


@sticker("arcade", "skull8", "Pixel skull", ["#F4F1EA", "#C9C3B6", "#141418", "#E3172F"], ink=1.0)
def _():
    rows = ["..#####..", ".#######.", "#########", "#########", "#########", ".#######.", "..#####..", "..#####..", "..#.#.#.."]
    holes = ["........." , ".........", ".##...##.", ".##...##.", "....#....", ".........", "....#....", ".........", "........."]
    sh = pixsub(rows, lambda i, j, w, h: (i - w / 2) * 0.8 - (j - h / 2) * 0.3 > 1.3)
    return [pix(rows, 0, 0, 0.19), pix(sh, 0, 0, 0.19), pix(holes, 0, 0, 0.19), None]


@sticker("arcade", "coin", "Coin", ["#FFC531", "#E09A12", "#FFE9A8", "#FFFFFF"], ink=1.0)
def _():
    disc = circle(0, 0, 0.88)
    rim = ring(0, 0, 0.68, 0.04)
    mark = star(0, 0, 5, 0.38, 0.17)
    glint = U(arc(0, 0, 0.78, math.radians(110), math.radians(150), 0.03), circle(-0.48, 0.5, 0.03))
    return [disc, rim, mark, glint]


@sticker("arcade", "gamepad", "Gamepad", ["#C9CED6", "#2B2E33", "#E3172F", "#FFFFFF"], ink=1.0)
def _():
    body = smin(box(0, 0.08, 0.84, 0.38, 0.3), U(circle(-0.58, -0.3, 0.3), circle(0.58, -0.3, 0.3)), 0.14)
    dark = U(box(-0.5, 0.1, 0.2, 0.07, 0.02), box(-0.5, 0.1, 0.07, 0.2, 0.02), box(-0.1, 0.0, 0.09, 0.03, 0.015), box(0.1, 0.0, 0.09, 0.03, 0.015))
    btn = U(circle(0.46, 0.0, 0.12), circle(0.68, 0.18, 0.12))
    shine = seg(-0.6, 0.34, 0.6, 0.34, 0.025)
    return [body, dark, btn, shine]


@sticker("arcade", "joystick", "Joystick", ["#2B2E33", "#C9CED6", "#E3172F", "#FFD400"], ink=1.0)
def _():
    base = box(0, -0.52, 0.82, 0.28, 0.14)
    shaft = seg(0, -0.3, 0, 0.2, 0.07)
    ball = U(circle(0, 0.48, 0.3))
    btns = U(circle(-0.52, -0.5, 0.11), circle(-0.24, -0.5, 0.11), circle(0.28, -0.5, 0.11), circle(0.56, -0.5, 0.11))
    return [base, shaft, ball, btns]


@sticker("arcade", "floppy", "Floppy disk", ["#1B6FE0", "#F4F1EA", "#C9CED6", "#141418"], ink=1.0)
def _():
    body = sub(box(0, 0, 0.8, 0.8, 0.08), poly([(0.58, 0.95), (0.95, 0.95), (0.95, 0.58)]))
    label = box(0, -0.34, 0.54, 0.36, 0.03)
    shutter = box(0.08, 0.5, 0.36, 0.3, 0.03)
    dark = U(box(0.2, 0.5, 0.1, 0.2, 0.02), *[seg(-0.4, y, 0.4, y, 0.014) for y in (-0.22, -0.34, -0.46)])
    return [body, label, shutter, dark]


@sticker("arcade", "cursor", "Cursor", ["#141418", "#FFFFFF", "#2EE6FF", "#FFD400"], ink=0.0)
def _():
    P = [(0, 0), (0, 17), (4, 13), (7, 20), (9, 19), (6, 12), (12, 12)]
    pts = [((x - 5.0) * 0.07 + 0.1, (9.6 - y) * 0.07) for x, y in P]
    arrow = poly(pts)
    inner = arrow + 0.045
    burst = U(*[seg(pts[0][0] + 0.09 * math.cos(a), pts[0][1] + 0.09 * math.sin(a), pts[0][0] + 0.19 * math.cos(a), pts[0][1] + 0.19 * math.sin(a), 0.026)
                for a in (math.radians(100), math.radians(135), math.radians(170))])
    return [arrow, inner, burst, None]


@sticker("arcade", "gameover", "Game over", ["#141418", "#E3172F", "#E3172F", "#2B2E33"], ink=1.0)
def _():
    sign = box(0, 0, 0.92, 0.55, 0.1)
    border = shell(box(0, 0, 0.84, 0.47, 0.06), 0.022)
    words = U(text("GAME", 0, 0.2, 0.25, maxw=1.2), text("OVER", 0, -0.2, 0.25, maxw=1.2))
    scan = inter(sign, stripes(0.07, math.pi / 2, 0.3))
    return [sign, border, words, scan]


@sticker("arcade", "insertcoin", "Insert coin", ["#FFD400", "#141418", "#141418", "#E3172F"], ink=1.0)
def _():
    sign = box(0, 0, 0.92, 0.5, 0.1)
    border = shell(box(0, 0, 0.84, 0.42, 0.06), 0.02)
    words = U(text("INSERT", 0, 0.16, 0.17, maxw=1.1), text("COIN", 0, -0.18, 0.28, maxw=1.1))
    dots = U(*[circle(x, y, 0.04) for x in (-0.8, 0.8) for y in (-0.3, 0.3)])
    return [sign, border, words, dots]


@sticker("arcade", "trophy", "Trophy", ["#FFC531", "#E09A12", "#5A3420", "#FFFFFF"], ink=1.0)
def _():
    bowl = poly(spline([(-0.52, 0.76), (0.52, 0.76), (0.46, 0.32), (0.22, 0.02), (-0.22, 0.02), (-0.46, 0.32)], n=6))
    handles = U(arc(-0.54, 0.4, 0.22, math.radians(100), math.radians(260), 0.05), arc(0.54, 0.4, 0.22, math.radians(-80), math.radians(80), 0.05))
    stem = box(0, -0.16, 0.1, 0.18)
    cup = U(bowl, handles, stem, box(0, -0.4, 0.28, 0.07, 0.03))
    shade = inter(U(bowl, stem), X - 0.26)
    base = U(box(0, -0.6, 0.42, 0.12, 0.05), box(0, -0.46, 0.3, 0.05))
    star_ = star(0, 0.42, 5, 0.19, 0.08)
    return [cup, shade, base, star_]


@sticker("arcade", "cartridge", "Cartridge", ["#8A8F98", "#FF2D6F", "#2B2E33", "#FFFFFF"], ink=1.0)
def _():
    body = U(box(0, 0.1, 0.7, 0.8, 0.08), box(0, -0.66, 0.5, 0.14, 0.04))
    label = box(0, 0.2, 0.54, 0.46, 0.05)
    dark = U(box(0, -0.66, 0.38, 0.07, 0.02), *[seg(x, 0.7, x, 0.8, 0.018) for x in np.linspace(-0.5, 0.5, 8)],
             *[seg(x, -0.58, x, -0.72, 0.013) for x in np.linspace(-0.3, 0.3, 9)])
    mark = U(star(0, 0.26, 5, 0.22, 0.1), seg(-0.34, -0.06, 0.34, -0.06, 0.02))
    return [body, label, dark, mark]


# ---- GEAR (free pack; Pro picks in PRO) — the hardware this app is about --------------------------------

@sticker("gear", "jack", "Jack plug", ["#2B2E33", "#C9CED6", "#8A8F98", "#FFD400"], ink=1.0)
def _():
    with rotated(0.62):
        handle = U(box(-0.64, 0, 0.28, 0.2, 0.09), box(0.38, 0, 0.04, 0.13), seg(-0.92, 0, -1.0, 0, 0.07))
        sleeve = box(-0.02, 0, 0.34, 0.13, 0.03)
        tip = U(box(0.62, 0, 0.2, 0.075, 0.02), poly([(0.8, 0.075), (0.8, -0.075), (0.9, 0)]))
        metal = U(sleeve, tip)
        shade = inter(metal, Y + 0.0)
        band = box(0.2, 0, 0.03, 0.135)
    return [handle, metal, shade, band]


@sticker("gear", "xlr", "XLR", ["#C9CED6", "#2B2E33", "#E0B84A", "#8A8F98"], ink=1.0)
def _():
    shell_ = circle(0, 0, 0.88)
    inner = circle(0, 0, 0.68)
    pins = U(circle(-0.24, 0.2, 0.11), circle(0.24, 0.2, 0.11), circle(0, -0.3, 0.11))
    key = U(box(0, 0.62, 0.09, 0.07, 0.02), ring(-0.24, 0.2, 0.17, 0.018), ring(0.24, 0.2, 0.17, 0.018), ring(0, -0.3, 0.17, 0.018))
    return [shell_, inner, pins, key]


@sticker("gear", "din", "MIDI DIN", ["#C9CED6", "#2B2E33", "#E0B84A", "#8A8F98"], ink=1.0)
def _():
    shell_ = circle(0, 0, 0.88)
    inner = circle(0, 0, 0.7)
    pins = U(*[circle(0.42 * math.cos(a), -0.05 + 0.42 * math.sin(a), 0.085) for a in np.linspace(0, math.pi, 5)])
    key = box(0, -0.6, 0.1, 0.1, 0.02)
    return [shell_, inner, pins, key]


@sticker("gear", "knob", "Knob", ["#2B2E33", "#8A8F98", "#E3172F", "#F4F1EA"], ink=1.0)
def _():
    body = circle(0, 0, 0.6)
    face = circle(0, 0, 0.48)
    with rotated(-0.55):
        pointer = seg(0, 0.1, 0, 0.42, 0.045)
    ticks = U(*[circle(0.8 * math.cos(a), 0.8 * math.sin(a), 0.032) for a in [math.pi / 2 + math.radians(135) - k * math.radians(27) for k in range(11)]])
    return [body, face, pointer, ticks]


@sticker("gear", "fader", "Fader", ["#2B2E33", "#141418", "#C9CED6", "#FF5A1F"], ink=1.0)
def _():
    plate = box(0, 0, 0.52, 0.88, 0.08)
    slot = box(0, 0, 0.065, 0.72, 0.03)
    cap = box(0, -0.2, 0.34, 0.17, 0.04)
    marks = U(*[box(s * 0.4, y, 0.07, 0.012) for s in (-1, 1) for y in np.linspace(-0.7, 0.7, 8)], box(0, -0.2, 0.3, 0.014))
    return [plate, slot, cap, marks]


@sticker("gear", "toggle", "Toggle switch", ["#2B2E33", "#C9CED6", "#8A8F98", "#E3172F"], ink=1.0)
def _():
    plate = box(0, 0, 0.62, 0.84, 0.1)
    nut = regpoly(0, -0.1, 6, 0.34, 0.0)
    lever = taper(0, -0.1, 0.2, 0.6, 0.12, 0.075)
    tip = circle(0.2, 0.62, 0.115)
    return [plate, nut, lever, tip]


@sticker("gear", "vu", "VU meter", ["#2B2E33", "#F4E3C8", "#2B2E33", "#E3172F"], ink=1.0)
def _():
    body = box(0, 0, 0.92, 0.72, 0.1)
    face = box(0, 0, 0.8, 0.6, 0.06)
    cx, cy = 0.0, -0.5
    ticks = U(*[seg(cx + 0.58 * math.cos(math.radians(a)), cy + 0.58 * math.sin(math.radians(a)), cx + 0.7 * math.cos(math.radians(a)), cy + 0.7 * math.sin(math.radians(a)), 0.014)
                for a in np.linspace(48, 132, 9)])
    dark = U(ticks, arc(cx, cy, 0.62, math.radians(48), math.radians(132), 0.012), circle(cx, cy, 0.07), text("VU", 0, -0.12, 0.13, maxw=0.4))
    needle = U(seg(cx, cy, cx + 0.64 * math.cos(math.radians(72)), cy + 0.64 * math.sin(math.radians(72)), 0.022),
               arc(cx, cy, 0.62, math.radians(112), math.radians(132), 0.04))
    return [body, face, dark, needle]


@sticker("gear", "scope", "Oscilloscope", ["#3A3F47", "#0B1A12", "#2EE6A0", "#C9CED6"], ink=1.0)
def _():
    body = box(0, 0, 0.92, 0.78, 0.1)
    screen = box(-0.18, 0.06, 0.62, 0.54, 0.08)
    trace = polyline([(x, 0.06 + 0.24 * math.sin(x * 5.2)) for x in np.linspace(-0.74, 0.36, 36)], 0.03)
    grid = inter(U(*[seg(x, -0.5, x, 0.62, 0.007) for x in np.linspace(-0.62, 0.26, 5)], *[seg(-0.8, y, 0.44, y, 0.007) for y in np.linspace(-0.3, 0.42, 5)]), screen)
    knobs = U(circle(0.68, 0.42, 0.1), circle(0.68, 0.12, 0.1), circle(0.68, -0.18, 0.1), box(0.68, -0.54, 0.17, 0.06, 0.03))
    return [body, screen, U(trace, grid), knobs]


@sticker("gear", "tube", "Valve", ["#CFE9FF", "#8A8F98", "#2B2E33", "#FF9F1C"], ink=1.0)
def _():
    glass = U(circle(0, 0.34, 0.46), box(0, -0.12, 0.46, 0.46))
    plates = U(box(-0.15, 0.12, 0.05, 0.34, 0.02), box(0.15, 0.12, 0.05, 0.34, 0.02), seg(-0.15, 0.46, 0.15, 0.46, 0.03))
    base = U(box(0, -0.6, 0.48, 0.17, 0.05), *[box(x, -0.84, 0.03, 0.07) for x in (-0.3, -0.1, 0.1, 0.3)])
    glow = U(circle(0, -0.2, 0.1), seg(-0.1, 0.2, 0.1, 0.2, 0.02), seg(0, -0.12, 0, 0.2, 0.012))
    return [glass, plates, base, glow]


@sticker("gear", "patch", "Patch cable", ["#FF2D6F", "#C9CED6", "#2B2E33", "#FFFFFF"], ink=1.0)
def _():
    cable = brush([(-0.52, 0.32), (-0.64, -0.1), (-0.36, -0.58), (0.0, -0.66), (0.4, -0.56), (0.66, -0.1), (0.54, 0.32)], [0.06] * 7)
    metal = U(*[U(box(s * 0.56, 0.54, 0.075, 0.17), box(s * 0.56, 0.74, 0.04, 0.07)) for s in (-1, 1)])
    handles = U(*[box(s * 0.56, 0.3, 0.12, 0.11, 0.04) for s in (-1, 1)])
    shine = U(bezier((-0.54, 0.0), (-0.5, -0.4), (-0.28, -0.52), 0.014), bezier((0.5, 0.0), (0.46, -0.4), (0.26, -0.52), 0.0))
    return [cable, metal, handles, shine]


@sticker("gear", "sine", "Sine wave", ["#1B6FE0", "#9FE8FF", "#FFFFFF", "#FFD400"], ink=1.0)
def _():
    disc = circle(0, 0, 0.9)
    axis = seg(-0.78, 0, 0.78, 0, 0.016)
    wave = polyline([(x, 0.36 * math.sin(x * math.pi * 1.6)) for x in np.linspace(-0.72, 0.72, 60)], 0.065)
    return [disc, axis, wave, circle(0.31, 0.36, 0.09)]


@sticker("gear", "adsr", "Envelope", ["#141418", "#FF2D6F", "#FFFFFF", "#FFD400"], ink=1.0)
def _():
    panel = box(0, 0, 0.92, 0.72, 0.12)
    pts = [(-0.74, -0.42), (-0.38, 0.44), (-0.12, 0.08), (0.34, 0.08), (0.72, -0.42)]
    fill = poly([(-0.74, -0.52)] + pts + [(0.72, -0.52)])
    line = polyline(pts, 0.032)
    nodes = U(*[circle(x, y, 0.06) for x, y in pts])
    return [panel, fill, line, nodes]


# ---- ROADIE (free pack; Pro picks in PRO) — flight-case labels and backstage passes --------------------

@sticker("roadie", "fragile", "Fragile", ["#E3172F", "#FFFFFF", "#FFFFFF", "#141418"], ink=1.0)
def _():
    sign = box(0, 0, 0.92, 0.52, 0.08)
    border = shell(box(0, 0, 0.84, 0.44, 0.05), 0.02)
    word = text("FRAGILE", 0, 0.1, 0.25, maxw=1.5)
    small = text("HANDLE WITH CARE", 0, -0.27, 0.08, maxw=1.5)
    return [sign, border, word, small]


@sticker("roadie", "thisway", "This way up", ["#FF9F1C", "#F4F1EA", "#141418", "#FF9F1C"], ink=1.0)
def _():
    sign = box(0, 0, 0.8, 0.86, 0.1)
    inner = box(0, 0, 0.7, 0.76, 0.06)
    arrows = U(*[poly([(x, 0.58), (x + 0.27, 0.14), (x + 0.1, 0.14), (x + 0.1, -0.5), (x - 0.1, -0.5), (x - 0.1, 0.14), (x - 0.27, 0.14)]) for x in (-0.3, 0.3)])
    return [sign, inner, arrows, None]


@sticker("roadie", "glass", "Glass", ["#E3172F", "#FFFFFF", "#E3172F", "#141418"], ink=1.0)
def _():
    sq = box(0, 0, 0.8, 0.8, 0.1)
    bowl = U(inter(circle(0, 0.12, 0.34), Y - 0.12), box(0, 0.4, 0.34, 0.28))
    glass_ = U(bowl, box(0, -0.2, 0.04, 0.2), box(0, -0.46, 0.25, 0.04, 0.02))
    crack = polyline([(-0.12, 0.66), (0.05, 0.42), (-0.07, 0.24), (0.1, 0.04)], 0.022)
    return [sq, glass_, crack, None]


@sticker("roadie", "umbrella", "Keep dry", ["#1B6FE0", "#F4F1EA", "#9FE8FF", "#0B3E8C"], ink=1.0)
def _():
    sq = box(0, 0, 0.8, 0.8, 0.1)
    dome = U(inter(circle(0, 0.08, 0.52), 0.08 - Y), inter(U(circle(-0.34, 0.08, 0.17), circle(0, 0.08, 0.17), circle(0.34, 0.08, 0.17)), Y - 0.08))
    handle = U(seg(0, 0.08, 0, -0.42, 0.038), arc(-0.1, -0.42, 0.1, -math.pi, 0.0, 0.038))
    rain = U(*[taper(x, y, x - 0.05, y - 0.16, 0.04, 0.012) for x, y in [(-0.58, 0.5), (0.5, 0.56), (-0.5, -0.1), (0.56, -0.02), (0.38, -0.46), (-0.4, -0.5)]])
    ribs = U(seg(0, 0.56, -0.34, 0.08, 0.014), seg(0, 0.56, 0.34, 0.08, 0.014), seg(0, 0.56, 0, 0.08, 0.014))
    return [sq, dome, rain, ribs]


@sticker("roadie", "heavy", "Heavy", ["#FFD400", "#141418", "#FFD400", "#141418"], ink=1.0)
def _():
    sq = box(0, 0, 0.82, 0.82, 0.1)
    weight = U(poly([(-0.48, -0.56), (0.48, -0.56), (0.34, 0.0), (-0.34, 0.0)]) - 0.04, ring(0, 0.16, 0.17, 0.045))
    word = text("KG", 0, -0.3, 0.22, maxw=0.7)
    border = shell(box(0, 0, 0.73, 0.73, 0.07), 0.03)
    return [sq, weight, word, border]


@sticker("roadie", "qc", "QC passed", ["#2E9E4F", "#FFFFFF", "#FFFFFF", "#1F6B34"], ink=1.0)
def _():
    disc = circle(0, 0, 0.9)
    ring_ = shell(circle(0, 0, 0.76), 0.028)
    check = U(polyline([(-0.34, 0.02), (-0.1, -0.22), (0.36, 0.24)], 0.09), text("QC", 0, 0.54, 0.17, maxw=0.5), text("PASSED", 0, -0.52, 0.12, maxw=0.9))
    return [disc, ring_, check, None]


@sticker("roadie", "barcode", "Barcode", ["#F4F1EA", "#141418", "#E3172F", "#141418"], ink=1.0)
def _():
    label = box(0, 0, 0.92, 0.6, 0.06)
    widths = [0.02, 0.045, 0.02, 0.07, 0.03, 0.02, 0.05, 0.035, 0.02, 0.06, 0.03, 0.02, 0.045, 0.025, 0.07, 0.02, 0.04, 0.03, 0.02, 0.055, 0.025]
    x = -0.74
    bars = []
    for i, w in enumerate(widths):
        bars.append(box(x + w, 0.02, w / 2 + 0.002, 0.26 if i % 7 else 0.3))
        x += w * 2 + 0.03
    digits = text("4 901234 567890", 0, -0.36, 0.1, maxw=1.4)
    head = box(0, 0.5, 0.92, 0.1, 0.0)
    return [label, U(*bars, digits), inter(head, label + 0.0), None]


@sticker("roadie", "allaccess", "All access", ["#141418", "#FF2D9B", "#FFFFFF", "#C9CED6"], ink=1.0)
def _():
    card = box(0, -0.04, 0.56, 0.84, 0.1)
    stripe = box(0, 0.12, 0.56, 0.15)
    words = U(text("ALL", 0, -0.2, 0.24, maxw=0.9), text("ACCESS", 0, -0.52, 0.14, maxw=0.95))
    slot = U(box(0, 0.64, 0.14, 0.04, 0.02), star(0, 0.12, 5, 0.1, 0.045))
    return [card, stripe, words, slot]


@sticker("roadie", "vip", "VIP", ["#FFC531", "#E09A12", "#3A2418", "#FFFFFF"], ink=1.0)
def _():
    burst = star(0, 0, 16, 0.9, 0.8, 0.1)
    ring_ = shell(circle(0, 0, 0.66), 0.03)
    word = text("VIP", 0, 0.0, 0.42, maxw=1.0)
    return [burst, ring_, word, None]


@sticker("roadie", "backstage", "Backstage", ["#F4F1EA", "#FF9F1C", "#141418", "#E3172F"], ink=1.0)
def _():
    card = box(0, 0, 0.92, 0.52, 0.08)
    band = inter(card, X + 0.5)
    word = text("BACKSTAGE", 0.14, 0.0, 0.2, maxw=1.1)
    dot = U(circle(-0.7, 0.0, 0.05), circle(-0.7, 0.2, 0.05), circle(-0.7, -0.2, 0.05))
    return [card, band, word, dot]


@sticker("roadie", "loud", "Play loud", ["#141418", "#FFFFFF", "#FFD400", "#E3172F"], ink=1.0)
def _():
    disc = circle(0, 0, 0.9)
    speaker = U(box(-0.4, 0.12, 0.12, 0.2), poly([(-0.3, 0.32), (0.02, 0.62), (0.02, -0.38), (-0.3, -0.08)]))
    waves = U(arc(0.02, 0.12, 0.3, -0.7, 0.7, 0.045), arc(0.02, 0.12, 0.5, -0.65, 0.65, 0.045), arc(0.02, 0.12, 0.7, -0.55, 0.55, 0.045))
    word = text("LOUD", 0, -0.6, 0.17, maxw=0.8)
    return [disc, speaker, waves, word]


@sticker("roadie", "stop", "Stop", ["#FFFFFF", "#E3172F", "#FFFFFF", "#141418"], ink=1.0)
def _():
    outer = regpoly(0, 0, 8, 0.92, math.pi / 8)
    inner = regpoly(0, 0, 8, 0.82, math.pi / 8)
    word = text("STOP", 0, 0.0, 0.34, maxw=1.1)
    return [outer, inner, word, None]


# ---- MYSTIC (free pack; Pro picks in PRO) -----------------------------------------------------------------

@sticker("mystic", "pyramid", "Pyramid eye", ["#F4D35E", "#C9A227", "#FFFFFF", "#141418"], ink=1.0)
def _():
    tri = poly([(0, 0.8), (-0.88, -0.7), (0.88, -0.7)]) - 0.02
    shade = inter(tri, -X)
    almond = inter(circle(0, -0.55, 0.7), circle(0, 0.35, 0.7))
    dark = U(circle(0, -0.1, 0.13), arc(0, -0.32, 0.46, math.radians(52), math.radians(128), 0.02))
    return [tri, shade, almond, dark]


@sticker("mystic", "moonstars", "Moon and stars", ["#2B2D6B", "#FFE9A8", "#FFD400", "#FFFFFF"], ink=1.0)
def _():
    disc = circle(0, 0, 0.9)
    moon = crescent(-0.1, 0.0, 0.58, 0.28, 0.1, 0.5)
    stars = U(star(0.42, 0.4, 5, 0.16, 0.07), star(0.6, -0.1, 5, 0.11, 0.05), star(0.2, -0.5, 5, 0.09, 0.04))
    tiny = U(*[circle(x, y, 0.025) for x, y in [(-0.6, 0.6), (0.05, 0.72), (0.65, 0.55), (-0.7, -0.5), (0.5, -0.65), (-0.2, -0.78)]])
    return [disc, moon, stars, tiny]


@sticker("mystic", "tarot", "Tarot card", ["#F4E3C8", "#5B2A86", "#E0B84A", "#FFFFFF"], ink=1.0)
def _():
    card = box(0, 0, 0.56, 0.88, 0.07)
    frame = shell(box(0, 0, 0.46, 0.78, 0.04), 0.035)
    emblem = U(star(0, 0.14, 8, 0.32, 0.15), ring(0, 0.14, 0.4, 0.022), crescent(0, -0.52, 0.16, 0.08, 0.04, 0.14))
    glints = U(star(-0.3, 0.55, 4, 0.08, 0.02), star(0.3, -0.1, 4, 0.06, 0.018))
    return [card, frame, emblem, glints]


@sticker("mystic", "crystalball", "Crystal ball", ["#C98B4B", "#8B3DFF", "#FF5FD2", "#FFFFFF"], ink=1.0)
def _():
    base = U(poly([(-0.5, -0.82), (0.5, -0.82), (0.38, -0.56), (-0.38, -0.56)]) - 0.03, box(0, -0.6, 0.3, 0.07, 0.03))
    ball = circle(0, 0.12, 0.62)
    swirl = U(arc(0.05, 0.1, 0.3, 0.4, 3.8, 0.05), arc(-0.05, 0.12, 0.16, 3.6, 7.0, 0.04), circle(0.3, 0.38, 0.05))
    shine = U(arc(0, 0.12, 0.5, math.radians(110), math.radians(150), 0.035), circle(-0.36, 0.5, 0.035), star(0.28, -0.1, 4, 0.1, 0.025))
    return [base, ball, swirl, shine]


@sticker("mystic", "potion", "Potion", ["#CFE9FF", "#2EE6A0", "#8A5A33", "#FFFFFF"], ink=1.0)
def _():
    flask = U(circle(0, -0.28, 0.54), box(0, 0.32, 0.17, 0.32, 0.04))
    liquid = inter(flask, Y + 0.02)
    cork = box(0, 0.74, 0.17, 0.12, 0.04)
    bubbles = U(circle(-0.2, -0.4, 0.07), circle(0.16, -0.22, 0.05), circle(0.0, -0.6, 0.045), circle(0.3, -0.48, 0.04), circle(-0.06, 0.1, 0.035))
    shine = arc(0, -0.28, 0.42, math.radians(150), math.radians(190), 0.03)
    return [flask, liquid, cork, U(bubbles, shine)]


@sticker("mystic", "candle", "Candle", ["#F4F1EA", "#C9A44C", "#FF9F1C", "#FFE14A"], ink=1.0)
def _():
    wax = U(box(0, -0.22, 0.21, 0.46, 0.06), taper(-0.12, 0.22, -0.12, 0.0, 0.07, 0.04), circle(-0.12, -0.02, 0.04))
    holder = U(oval(0, -0.8, 0.52, 0.1), box(0, -0.7, 0.3, 0.06, 0.03), arc(0.45, -0.78, 0.16, -math.pi / 2, math.pi / 2, 0.03))
    flame = U(circle(0, 0.46, 0.13), taper(0, 0.46, 0.02, 0.86, 0.11, 0.0))
    inner = U(circle(0, 0.44, 0.065), taper(0, 0.44, 0.01, 0.66, 0.05, 0.0))
    return [wax, holder, flame, inner]


@sticker("mystic", "key", "Old key", ["#F4D35E", "#C9A227", "#FFFFFF", "#FFFFFF"], ink=1.0)
def _():
    with rotated(-0.75):
        bow = sub(U(circle(0, 0.56, 0.3), circle(-0.24, 0.42, 0.14), circle(0.24, 0.42, 0.14)), circle(0, 0.58, 0.12))
        shaft = box(0, -0.12, 0.07, 0.62)
        bits = U(box(0.16, -0.58, 0.17, 0.07, 0.02), box(0.12, -0.4, 0.13, 0.06, 0.02))
        key = U(bow, shaft, bits)
        shade = inter(key, X - 0.04)
        glint = U(arc(0, 0.56, 0.22, math.radians(110), math.radians(150), 0.02), seg(-0.03, 0.2, -0.03, -0.4, 0.014))
    return [key, shade, glint, None]


@sticker("mystic", "nazar", "Evil eye", ["#1B3A8C", "#FFFFFF", "#3A9BFF", "#141418"], ink=1.0)
def _():
    return [circle(0, 0, 0.88), circle(0, 0, 0.62), circle(0, 0, 0.4), circle(0, 0, 0.19)]


@sticker("mystic", "phases", "Moon phases", ["#2B2D6B", "#FFE9A8", "#FFE9A8", "#FFFFFF"], ink=1.0)
def _():
    pill = box(0, 0, 0.92, 0.3, 0.3)
    xs = np.linspace(-0.62, 0.62, 5)
    r = 0.15
    lit = U(sub(circle(xs[1], 0, r), circle(xs[1] + 0.09, 0, r * 0.95)), inter(circle(xs[2], 0, r), X - xs[2]),
            inter(circle(xs[3], 0, r), circle(xs[3] + 0.1, 0, r * 1.0) + 0.0), circle(xs[4], 0, r))
    rings = U(*[ring(x, 0, r, 0.012) for x in xs])
    spark = U(*[circle(x, y, 0.014) for x, y in [(-0.8, 0.18), (0.8, -0.18), (-0.3, 0.2), (0.3, -0.2)]])
    return [pill, lit, rings, spark]


@sticker("mystic", "hourglass", "Hourglass", ["#8A5A33", "#CFE9FF", "#FFD233", "#FFFFFF"], ink=1.0)
def _():
    frame = U(box(0, 0.76, 0.52, 0.07, 0.03), box(0, -0.76, 0.52, 0.07, 0.03), seg(-0.46, 0.76, -0.46, -0.76, 0.04), seg(0.46, 0.76, 0.46, -0.76, 0.04))
    top = poly([(-0.38, 0.7), (0.38, 0.7), (0.05, 0.02), (-0.05, 0.02)])
    bottom = poly([(-0.05, -0.02), (0.05, -0.02), (0.38, -0.7), (-0.38, -0.7)])
    glass_ = U(top, bottom)
    sand = U(inter(top, Y - 0.3), inter(bottom, Y + 0.34), seg(0, 0.02, 0, -0.38, 0.012))
    shine = U(seg(-0.26, 0.58, -0.12, 0.3, 0.018), seg(-0.26, -0.5, -0.2, -0.62, 0.018))
    return [frame, glass_, sand, shine]


@sticker("mystic", "spellbook", "Spell book", ["#5B2A86", "#F4E3C8", "#E0B84A", "#E3172F"], ink=1.0)
def _():
    cover = box(0, 0, 0.66, 0.86, 0.07)
    pages = U(box(0.6, -0.02, 0.07, 0.78, 0.02), box(0.0, -0.8, 0.6, 0.05, 0.02))
    emblem = U(star(-0.03, 0.14, 5, 0.3, 0.14), ring(-0.03, 0.14, 0.4, 0.02), *[box(sx * 0.5, sy * 0.72, 0.09, 0.09, 0.03) for sx in (-1, 1) for sy in (-1, 1)])
    clasp = U(circle(-0.03, -0.5, 0.09))
    return [cover, pages, emblem, clasp]


@sticker("mystic", "wand", "Wand", ["#2B2E33", "#FFD400", "#F4F1EA", "#9FE8FF"], ink=1.0)
def _():
    with rotated(-0.72):
        stick = box(0, -0.12, 0.055, 0.66, 0.02)
        starr = star(0, 0.74, 5, 0.27, 0.12) - 0.01
        tip = box(0, 0.5, 0.075, 0.05, 0.02)
        spark = U(star(-0.36, 0.78, 4, 0.12, 0.03), star(0.36, 0.5, 4, 0.1, 0.026), star(-0.26, 0.4, 4, 0.07, 0.02))
    return [stick, starr, tip, spark]


# ---- HIP HOP (free pack; Pro picks in PRO) — the culture, in sticker form --------------------------------

@sticker("hiphop", "snapback", "Snapback", ["#E3172F", "#141418", "#8A8F98", "#FFC531"], ink=1.0)
def _():
    crown = inter(oval(-0.12, -0.16, 0.66, 0.74), -0.16 - Y)
    brim = brush([(0.28, -0.18), (0.62, -0.17), (0.92, -0.3)], [0.085, 0.08, 0.05])
    band = box(-0.12, -0.22, 0.68, 0.07, 0.03)
    seams = U(seg(-0.12, 0.54, -0.5, -0.16, 0.012), seg(-0.12, 0.54, 0.32, -0.16, 0.012), seg(-0.12, 0.54, -0.12, -0.16, 0.012), circle(-0.12, 0.56, 0.065))
    logo = star(0.1, 0.14, 5, 0.17, 0.075)
    return [crown, U(brim, band), seams, logo]


@sticker("hiphop", "chain", "Gold chain", ["#FFC531", "#E09A12", "#2B2E33", "#FFE9A8"], ink=1.0)
def _():
    xs = np.linspace(-0.84, 0.84, 600)
    ys = 0.72 - 1.0 * (1.0 - (xs / 0.84) ** 2)
    seglen = np.hypot(np.diff(xs), np.diff(ys))
    arc_ = np.concatenate([[0], np.cumsum(seglen)])
    pts = [np.searchsorted(arc_, s) for s in np.arange(0.05, arc_[-1] - 0.05, 0.135)]
    faces, edges = [], []
    for n, i in enumerate(pts):
        i = min(i, len(xs) - 2)
        ang = math.atan2(ys[i + 1] - ys[i], xs[i + 1] - xs[i])
        if n % 2 == 0:
            faces.append(shell(oval(xs[i], ys[i], 0.105, 0.068, ang), 0.026))
        else:
            edges.append(box(xs[i], ys[i], 0.09, 0.03, 0.015, ang))
    links = U(*faces, *edges)
    medal = circle(0, -0.62, 0.3)
    return [U(links, medal, seg(0, -0.34, 0, -0.3, 0.05)), shell(circle(0, -0.62, 0.23), 0.026), circle(0, -0.62, 0.17), text("DSD", 0, -0.62, 0.1, maxw=0.3)]


@sticker("hiphop", "sneaker", "Sneaker", ["#E3172F", "#F4F1EA", "#FFFFFF", "#141418"], ink=1.0)
def _():
    upper = poly(spline([(-0.84, -0.58), (-0.88, -0.1), (-0.74, 0.46), (-0.5, 0.64), (-0.24, 0.5), (-0.1, 0.22), (0.2, 0.1),
                         (0.58, 0.0), (0.88, -0.2), (0.92, -0.52), (0.0, -0.6)], n=8))
    sole = U(box(0.02, -0.68, 0.92, 0.1, 0.07), box(0.02, -0.6, 0.9, 0.03))
    toecap = inter(oval(0.7, -0.3, 0.3, 0.26), upper)
    laces = U(*[seg(-0.13 + 0.14 * k - 0.07, 0.24 - 0.045 * k + 0.12, -0.13 + 0.14 * k + 0.1, 0.24 - 0.045 * k - 0.1, 0.022) for k in range(4)])
    star_ = star(-0.46, 0.04, 5, 0.15, 0.065)
    dark = U(polyline([(-0.74, 0.44), (-0.5, 0.6), (-0.26, 0.48)], 0.035), seg(-0.9, -0.58, 0.94, -0.58, 0.02))
    return [upper, sole, U(toecap, laces, star_), dark]


@sticker("hiphop", "mpc", "Pad controller", ["#3A3F47", "#141418", "#E3172F", "#FFD400"], ink=1.0)
def _():
    body = box(0, 0, 0.92, 0.88, 0.1)
    cells = [(i, j) for i in range(4) for j in range(4)]
    def pad(i, j):
        return box(-0.55 + 0.37 * i, -0.52 + 0.37 * j, 0.15, 0.15, 0.04)
    pads = U(*[pad(i, j) for i, j in cells])
    red = U(*[pad(i, j) for i, j in [(0, 0), (2, 1), (1, 3), (3, 3)]])
    yel = U(*[pad(i, j) for i, j in [(3, 1), (0, 2), (2, 2)]])
    return [body, pads, red, yel]


@sticker("hiphop", "drummachine", "Drum machine", ["#C9CED6", "#2B2E33", "#E3172F", "#FFD400"], ink=1.0)
def _():
    body = box(0, 0, 0.92, 0.56, 0.08)
    knobs = U(*[circle(x, 0.26, 0.075) for x in np.linspace(-0.62, 0.62, 6)], text("BEAT", 0, -0.4, 0.1, maxw=0.6))
    xs = np.linspace(-0.7, 0.7, 8)
    red = U(*[box(x, -0.08, 0.075, 0.1, 0.03) for x in xs[[0, 1, 4, 5]]])
    yel = U(*[box(x, -0.08, 0.075, 0.1, 0.03) for x in xs[[2, 3, 6, 7]]])
    return [body, knobs, red, yel]


@sticker("hiphop", "cash", "Cash", ["#6BBF6F", "#2E7D4F", "#CFE8C9", "#1F5A38"], ink=1.0)
def _():
    with rotated(0.18):
        bill = box(0, 0, 0.9, 0.5, 0.04)
        border = shell(box(0, 0, 0.8, 0.4, 0.03), 0.022)
        face = oval(0, 0, 0.25, 0.3)
        mark = U(text("$", 0, 0.0, 0.3, maxw=0.3), *[circle(sx * 0.62, sy * 0.24, 0.07) for sx in (-1, 1) for sy in (-1, 1)])
    return [bill, border, face, mark]


@sticker("hiphop", "platinum", "Platinum plaque", ["#3A2418", "#F4E3C8", "#C9CED6", "#FFC531"], ink=1.0)
def _():
    frame = box(0, 0, 0.9, 0.9, 0.06)
    mat = box(0, 0, 0.78, 0.78, 0.04)
    disc = circle(0, 0.12, 0.5)
    gold = U(circle(0, 0.12, 0.17), box(0, -0.6, 0.46, 0.11, 0.03), ring(0, 0.12, 0.38, 0.012), ring(0, 0.12, 0.28, 0.012))
    return [frame, mat, disc, gold]


@sticker("hiphop", "bandana", "Bandana", ["#E3172F", "#FFFFFF", "#FFFFFF", "#9D1220"], ink=1.0)
def _():
    with rotated(math.pi / 4):
        sq = box(0, 0, 0.64, 0.64, 0.04)
        border = shell(box(0, 0, 0.54, 0.54, 0.02), 0.02)
        drops = U(*[U(circle(x, y, 0.075), taper(x, y, x + 0.2 * math.cos(a), y + 0.2 * math.sin(a), 0.075, 0.008)) for x, y, a in
                    [(-0.24, -0.2, 0.8), (0.2, -0.24, 2.3), (-0.2, 0.14, -0.7), (0.22, 0.12, 3.8), (0.0, -0.02, 1.57)]])
        dots = U(*[circle(x, y, 0.025) for x in (-0.36, 0.36) for y in (-0.36, 0.36)], circle(0, 0.36, 0.025), circle(0, -0.36, 0.025))
        fold = inter(sq, 0.34 - Y)
    return [sq, border, U(drops, dots), fold]


@sticker("hiphop", "bucket", "Bucket hat", ["#FF9F1C", "#E07B00", "#141418", "#FFFFFF"], ink=1.0)
def _():
    crown = poly(spline([(-0.52, -0.1), (-0.42, 0.46), (0.0, 0.62), (0.42, 0.46), (0.52, -0.1)], n=8))
    brim = oval(0, -0.2, 0.92, 0.22)
    band = box(0, 0.06, 0.5, 0.07, 0.02)
    stitches = U(*[inter(shell(oval(0, -0.2, rx, ry), 0.014), -(Y + 0.2) + 0.12 - 0.12) for rx, ry in ((0.7, 0.15), (0.8, 0.185))])
    return [crown, brim, band, stitches]


@sticker("hiphop", "tag", "Graffiti tag", ["#141418", "#FF2D6F", "#FFFFFF", "#FFD400"], ink=0.0)
def _():
    word = text("BOOM", 0, 0.16, 0.5, maxw=1.6)
    drips = U(taper(-0.52, -0.1, -0.52, -0.5, 0.06, 0.045), circle(-0.52, -0.52, 0.045), taper(0.1, -0.1, 0.1, -0.7, 0.055, 0.04), circle(0.1, -0.72, 0.042),
              taper(0.62, -0.1, 0.62, -0.38, 0.05, 0.038), circle(0.62, -0.4, 0.038))
    fill = U(word, drips)
    shine = U(*[oval(x, 0.38, 0.07, 0.03, 0.4) for x in (-0.62, -0.2, 0.2, 0.62)])
    return [fill - 0.065, fill, shine, U(star(-0.8, 0.7, 4, 0.1, 0.025), star(0.8, -0.3, 4, 0.09, 0.022))]


@sticker("hiphop", "ring", "Diamond ring", ["#FFC531", "#CFF3FF", "#5BC8FF", "#FFFFFF"], ink=1.0)
def _():
    band = ring(0, -0.26, 0.44, 0.1)
    prongs = U(seg(-0.2, 0.1, -0.14, 0.26, 0.035), seg(0.2, 0.1, 0.14, 0.26, 0.035), seg(0, 0.08, 0, 0.2, 0.035))
    gem = poly([(-0.34, 0.5), (0.34, 0.5), (0.5, 0.3), (0.0, -0.02), (-0.5, 0.3)])
    facets = U(poly([(-0.34, 0.5), (0.0, 0.5), (-0.08, 0.3), (-0.5, 0.3)]), poly([(0.0, -0.02), (0.5, 0.3), (0.08, 0.3)]))
    spark = U(star(-0.72, 0.62, 4, 0.16, 0.035), star(0.66, 0.74, 4, 0.12, 0.028), star(0.76, 0.18, 4, 0.08, 0.02))
    return [U(band, prongs), gem, facets, spark]


@sticker("hiphop", "crate", "Record crate", ["#E3172F", "#1B6FE0", "#C98B4B", "#8A5A33"], ink=1.0)
def _():
    red = U(*[box(x, 0.22, 0.2, 0.42, 0.02, a) for x, a in ((-0.58, 0.16), (-0.08, -0.04), (0.44, 0.1))])
    blue = U(*[box(x, 0.2, 0.2, 0.4, 0.02, a) for x, a in ((-0.33, -0.1), (0.18, 0.06), (0.66, -0.12))])
    crate = box(0, -0.46, 0.84, 0.4, 0.05)
    slats = U(inter(crate, stripes(0.28, math.pi / 2, 0.2, 0.0)), box(-0.5, -0.3, 0.14, 0.035, 0.02), box(0.5, -0.3, 0.14, 0.035, 0.02))
    return [red, blue, crate, slats]


# ── build ────────────────────────────────────────────────────────────────────────────────────────────────

# The 58 stickers that shipped before 2026-10-11's expansion. Their pixels never change (decor files and party rigs name them
# forever), so the edge fitter below leaves them alone; everything newer is fitted.
LEGACY = {
    "street/star", "street/bolt", "street/skull", "street/flame", "street/crown", "street/smiley", "street/peace",
    "street/eightball", "street/eye", "street/pow", "street/wow", "street/sparkle", "street/ghost", "street/dice",
    "street/flag", "sweets/cone", "sweets/popsicle", "sweets/swirl", "sweets/lollipop", "sweets/donut",
    "sweets/cupcake", "sweets/cherries", "sweets/watermelon", "sweets/candy", "sweets/cookie", "sweets/strawberry",
    "music/note", "music/beamed", "music/headphones", "music/vinyl", "music/cassette", "music/speaker", "music/mic",
    "music/sticks", "music/snare", "music/pick", "music/eq", "music/rec", "music/onair", "music/metronome",
    "space/rocket", "space/planet", "space/moon", "space/ufo", "space/alien", "space/comet", "space/sun",
    "space/astro", "retro/roundel", "retro/hazard", "retro/radioactive", "retro/sunset", "retro/palm", "retro/wave",
    "retro/cactus", "retro/hifi", "retro/arrow", "retro/boombox",
}


def _shrink(d, k):
    """Scale a signed-distance layer about the slice centre by k < 1 (distances scale with it)."""
    m = max(2, int(round(N * k)))
    im = Image.fromarray(np.ascontiguousarray(d, dtype=np.float32)).resize((m, m), Image.BILINEAR)
    out = np.full((N, N), BIG, dtype=np.float32)
    o = (N - m) // 2
    out[o:o + m, o:o + m] = np.asarray(im) * (m / N)
    return out


def encode(d):
    if d is None:
        return np.zeros((N, N), dtype=np.uint8)
    t = 0.5 - d / (4.0 * SPREAD_UV)
    return (np.clip(t, 0, 1) * 255 + 0.5).astype(np.uint8)


# Every pack is FREE; Pro is per STICKER (2026-10-10 pricing decision: "all the sticker packs … free, but some
# pro only in every sticker pack, and we grow stickers over time"). Each pack keeps a complete free set and holds
# back roughly a third — its showiest pieces — for Pro. Pro stickers can still be tried on the plate; only keeping
# them asks (DecorPaintMode.SaveRespectingPro). The pack flag stays in the manifest as False so an older build that
# only reads it shows the whole pack as free rather than locked.
#
# When adding a pack: give it a complete free set first, then pick its Pro third here. Never REMOVE or RENAME an id —
# decor files and party rigs name stickers by "pack/id" forever (an unknown id renders as a star).
PACKS = [
    ("street", "Street", False),
    ("sweets", "Sweets", False),
    ("music", "Music", False),
    ("space", "Space", False),
    ("retro", "Retro", False),
    ("animals", "Animals", False),
    ("food", "Food", False),
    ("faces", "Faces", False),
    ("nature", "Nature", False),
    ("arcade", "Arcade", False),
    ("gear", "Gear", False),
    ("roadie", "Roadie", False),
    ("mystic", "Mystic", False),
    ("hiphop", "Hip Hop", False),
]

PRO = {
    "street": {"crown", "eye", "pow", "ghost", "flag",
               # 2026-10-11 expansion: every new sticker in an existing pack is Pro
               "spraycan", "bomb", "gem", "skateboard", "megaphone", "crossbones", "padlock", "lips"},
    "sweets": {"popsicle", "cupcake", "donut", "watermelon",
               "cake", "chocolate", "gummy", "macaron", "candycane", "cottoncandy", "milkshake", "pancakes"},
    "music": {"vinyl", "cassette", "mic", "rec", "onair",
              "keys", "kick", "hihat", "turntable", "tambourine", "waveform", "guitar", "maracas"},
    "space": {"ufo", "alien", "astro",
              "satellite", "earth", "mars", "constellation", "galaxy", "blackhole", "shootingstar", "telescope"},
    "retro": {"radioactive", "sunset", "hifi", "boombox",
              "tv", "vhs", "polaroid", "shades", "rotary", "jukebox", "lavalamp", "open"},
    # the packs added with the expansion: a complete free set (8 of 12) and the showiest third (4) held back for Pro
    "animals": {"fox", "panda", "octopus", "owl"},
    "food": {"sushi", "ramen", "avocado", "popcorn"},
    "faces": {"cool", "love", "robot", "party"},
    "nature": {"sunflower", "rainbow", "mountain", "snowflake"},
    "arcade": {"gamepad", "trophy", "cartridge", "gameover"},
    "gear": {"scope", "vu", "tube", "patch"},
    "roadie": {"allaccess", "vip", "backstage", "loud"},
    "mystic": {"pyramid", "crystalball", "hourglass", "spellbook"},
    "hiphop": {"chain", "sneaker", "platinum", "ring"},
}


# ---- PACK FILES: one new pack per file, Tools/sticker_packs/<pack>.py (2026-10-16) ---------------------------------
# So parallel authors never edit this file (or PACKS/PRO above) at the same time. A pack file is run INSIDE this
# module's namespace — every helper above (circle, box, star, text, U, sub, inter, X, Y, @sticker …) is in scope with
# no imports — and declares
#     PACK = ("skate", "Skate & Surf", False)          # (id, title, pack-level pro — always False)
#     PRO_IDS = {"board", "wave", ...}                  # the showiest ~third of its stickers
# plus its @sticker("skate", ...) functions. See Tools/sticker_packs/README.md.
_PACK_DIR = Path(__file__).resolve().parent / "sticker_packs"
for _pf in sorted(_PACK_DIR.glob("[!_]*.py")) if _PACK_DIR.exists() else []:
    _ns = dict(globals())
    exec(compile(_pf.read_text(encoding="utf-8"), str(_pf), "exec"), _ns)   # str path: inspect/linecache find the source
    _pack = _ns.get("PACK")
    if not _pack or _pack[0] in {p[0] for p in PACKS}:
        sys.exit(f"{_pf.name}: needs a PACK = (id, title, False) whose id no other pack uses")
    PACKS.append(tuple(_pack))
    PRO[_pack[0]] = set(_ns.get("PRO_IDS", ()))


def build(sheet_path=None, only=None):
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    PACKS_DIR.mkdir(parents=True, exist_ok=True)
    PUBLISH_DIR.mkdir(parents=True, exist_ok=True)
    slices = []                               # every sticker, in library order (the preview sheet)
    tight = []                                # stickers whose art + die-cut margin reaches the slice edge
    fitted = []                               # newer stickers the generator scaled down to keep that margin
    pack_slices = {p[0]: [] for p in PACKS}   # per pack, in the pack's own slice order
    manifest = {"version": 2, "spread": SPREAD_UV, "size": N, "columns": COLS, "packs": []}
    by_pack = {p[0]: {"id": p[0], "title": p[1], "pro": p[2], "stickers": []} for p in PACKS}
    for pack, sid, title, fn, colors, ink in STICKERS:
        if only and pack not in only:
            continue
        layers, names = named_layers(fn)
        layers = [np.where(np.isfinite(l), l, BIG) for l in layers]
        # the shader's die-cut margin (_Border 0.06 of the half quad, over _ArtSize 0.84) must fit INSIDE the slice, or the cut is
        # clamped flat at the slice edge (and the flipbook emulator bleeds a neighbour in)
        union = np.minimum.reduce(layers)
        rim = np.concatenate([union[0, :], union[-1, :], union[:, 0], union[:, -1]]).min()
        if rim < EDGE_CLEARANCE:
            if f"{pack}/{sid}" in LEGACY:
                tight.append((f"{pack}/{sid}", float(rim)))          # shipped art: reported, never altered
            elif rim >= 0.0:
                # newer art is fitted: scaled down just enough that the die-cut margin sits inside the slice
                k = (1.0 - EDGE_CLEARANCE) / (1.0 - rim)
                layers = [_shrink(l, k) for l in layers]
                fitted.append((f"{pack}/{sid}", k))
            else:
                tight.append((f"{pack}/{sid}", float(rim)))          # clipped by the slice already: redraw it smaller
        rgba = np.stack([encode(layers[i]) if i < len(layers) else encode(np.full((N, N), BIG)) for i in range(4)], axis=-1)
        slices.append(rgba)
        local = len(pack_slices[pack])        # the slice INSIDE this pack's array
        pack_slices[pack].append(rgba)
        by_pack[pack]["stickers"].append({"id": sid, "title": title, "slice": local, "layers": len(layers),
                                          "colors": colors[:4], "ink": ink, "pro": sid in PRO.get(pack, ()),
                                          "layerNames": names})

    for old in PUBLISH_DIR.glob("*.png"):     # the publish folder only ever holds the CURRENT revs
        old.unlink()
    index = {"version": 2, "spread": SPREAD_UV, "size": N, "columns": COLS, "packs": []}
    total_px = 0
    for pid, title, _pro in PACKS:
        sl = pack_slices[pid]
        if not sl:
            continue
        rows = (len(sl) + COLS - 1) // COLS
        atlas = np.zeros((rows * N, COLS * N, 4), dtype=np.uint8)
        for i, one in enumerate(sl):
            r, c = divmod(i, COLS)
            atlas[r * N:(r + 1) * N, c * N:(c + 1) * N] = one
        png = PACKS_DIR / f"{pid}.png"
        Image.fromarray(atlas, "RGBA").save(png)
        data = png.read_bytes()
        rev = hashlib.sha1(data).hexdigest()[:8]     # of the PIXELS: a changed pack is a new file name
        entry = by_pack[pid]
        entry.update({"atlas": f"Decor/Packs/{pid}", "rows": rows, "depth": rows * COLS, "rev": rev})
        manifest["packs"].append(entry)
        (PUBLISH_DIR / f"{pid}.{rev}.png").write_bytes(data)
        index["packs"].append(dict(entry, png=f"{pid}.{rev}.png"))
        write_meta(PACKS_DIR / f"{pid}.png.meta", pid, rows)
        total_px += atlas.shape[0] * atlas.shape[1]

    manifest["slices"] = len(slices)
    (OUT_DIR / "stickers.json").write_text(json.dumps(manifest, indent=1), encoding="utf-8")
    (PUBLISH_DIR / "index.json").write_text(json.dumps(index, indent=1), encoding="utf-8")

    # The old single atlas is gone: leaving it would ship ~9 MB of art nothing reads.
    for legacy in (OUT_DIR / "StickerArt.png", OUT_DIR / "StickerArt.png.meta"):
        if legacy.exists():
            legacy.unlink()
            print("removed legacy", legacy.name)

    print(f"{len(slices)} stickers in {len(manifest['packs'])} packs ({total_px * 4 / 1e6:.1f} MB as RGBA32); "
          f"CDN set in {PUBLISH_DIR}")
    for sid, rim in tight:
        if sid in LEGACY:
            continue            # the first 58 shipped like that; their pixels must not move
        print(f"  WARNING {sid}: art is clipped by the slice edge (clearance {rim:.3f}) — redraw it smaller")
    if fitted:
        print("  fitted to the slice (scaled): " + ", ".join(f"{s} x{k:.2f}" for s, k in fitted))
    if sheet_path:
        preview([s for s in STICKERS if not only or s[0] in only], slices, sheet_path)


def write_meta(meta, pack_id, rows):
    """The importer settings for one pack: a flipbook Texture2DArray (COLS x rows tiles). The GUID is derived from
    the pack id (and kept if the file already has one) so a regenerate never breaks a reference."""
    guid = hashlib.md5(("dsd.sticker.pack." + pack_id).encode()).hexdigest()
    if meta.exists():
        import re
        m = re.search(r"guid: ([0-9a-f]{32})", meta.read_text(encoding="utf-8"))
        if m:
            guid = m.group(1)
    size = max(COLS * N, rows * N)
    mts = 2048 if size <= 2048 else 4096
    meta.write_text(f"""fileFormatVersion: 2
guid: {guid}
TextureImporter:
  internalIDToNameTable: []
  externalObjects: {{}}
  serializedVersion: 13
  mipmaps:
    mipMapMode: 0
    enableMipMap: 0
    sRGBTexture: 0
    linearTexture: 0
    fadeOut: 0
    borderMipMap: 0
    mipMapsPreserveCoverage: 0
    alphaTestReferenceValue: 0.5
    mipMapFadeDistanceStart: 1
    mipMapFadeDistanceEnd: 3
  bumpmap:
    convertToNormalMap: 0
    externalNormalMap: 0
    heightScale: 0.25
    normalMapFilter: 0
    flipGreenChannel: 0
  isReadable: 0
  streamingMipmaps: 0
  streamingMipmapsPriority: 0
  vTOnly: 0
  ignoreMipmapLimit: 0
  grayScaleToAlpha: 0
  generateCubemap: 6
  cubemapConvolution: 0
  seamlessCubemap: 0
  textureFormat: 1
  maxTextureSize: {mts}
  textureSettings:
    serializedVersion: 2
    filterMode: 1
    aniso: 1
    mipBias: 0
    wrapU: 1
    wrapV: 1
    wrapW: 1
  nPOTScale: 0
  lightmap: 0
  compressionQuality: 50
  spriteMode: 0
  alphaUsage: 1
  alphaIsTransparency: 0
  textureType: 0
  textureShape: 4
  singleChannelComponent: 0
  flipbookRows: {rows}
  flipbookColumns: {COLS}
  maxTextureSizeSet: 0
  compressionQualitySet: 0
  textureFormatSet: 0
  ignorePngGamma: 0
  applyGammaDecoding: 0
  swizzle: 50462976
  cookieLightType: 0
  platformSettings:
  - serializedVersion: 3
    buildTarget: DefaultTexturePlatform
    maxTextureSize: {mts}
    resizeAlgorithm: 0
    textureFormat: 4
    textureCompression: 0
    compressionQuality: 50
    crunchedCompression: 0
    allowsAlphaSplitting: 0
    overridden: 0
    ignorePlatformSupport: 0
    androidETC2FallbackOverride: 0
    forceMaximumCompressionQuality_BC6H_BC7: 0
  userData:
  assetBundleName:
  assetBundleVariant:
""", encoding="utf-8")


def preview(stickers, slices, path):
    """Flat-colour numpy preview (no lighting): quick check of every sticker's layers."""
    cell = 128
    cols = 8
    rows = (len(slices) + cols - 1) // cols
    img = Image.new("RGB", (cols * cell, rows * cell), (40, 44, 50))
    k = 0
    for pack, sid, title, fn, colors, ink in stickers:
        sl = slices[k].astype(float) / 255.0
        out = np.ones((N, N, 3)) * np.array([40, 44, 50]) / 255.0
        union = sl.max(axis=-1)
        border = np.clip((union - 0.5 + 0.06 / (4 * SPREAD_UV) * 2) * 40, 0, 1)
        out = out * (1 - border[..., None]) + np.array([0.97, 0.97, 0.95]) * border[..., None]
        for i in range(4):
            if i >= len(colors):
                break
            a = np.clip((sl[..., i] - 0.5) * 40 + 0.5, 0, 1)
            c = np.array([int(colors[i][j:j + 2], 16) for j in (1, 3, 5)]) / 255.0
            out = out * (1 - a[..., None]) + c * a[..., None]
        im = Image.fromarray((out * 255).astype(np.uint8)).resize((cell, cell), Image.LANCZOS)
        r, c = divmod(k, cols)
        img.paste(im, (c * cell, r * cell))
        k += 1
    img.save(path)
    print("preview", path)


if __name__ == "__main__":
    if "--names" in sys.argv:
        patch_layer_names(OUT_DIR / "stickers.json")
        sys.exit(0)
    sheet = None
    if "--sheet" in sys.argv:
        sheet = sys.argv[sys.argv.index("--sheet") + 1]
    only = None
    if "--only" in sys.argv:
        only = set(sys.argv[sys.argv.index("--only") + 1].split(","))
        if not os.environ.get("DSD_STICKER_OUT"):
            sys.exit("--only writes a PARTIAL manifest: set DSD_STICKER_OUT to a scratch folder first (it would overwrite what ships).")
    build(sheet, only)
