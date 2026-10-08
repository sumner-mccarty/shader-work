#!/usr/bin/env python3
"""
gen_materials.py — the Materials v2 library: tileable surface textures + studio matcaps.

    python Tools/gen_materials.py            # write the atlases + catalog, and a preview sheet
    python Tools/gen_materials.py preview    # preview sheet only (.skinsheet/materials_preview.png)

Writes (all generated here — no downloaded or licensed imagery):
  Assets/Resources/UiMaterials/MaterialTex.png   4x4 grid of 512px GREYSCALE tiles → Texture2DArray
  Assets/Resources/UiMaterials/Matcaps.png       4x4 grid of 256px RGB matcaps   → Texture2DArray
  Assets/Resources/UiMaterials/catalog.json      layer index of every entry (what skins and lookkit use)
  Assets/Resources/Backdrops/*.png               1920x1080 wallpapers for glass looks (recipe "backdrop")

TEXTURES are height/albedo-detail maps centred on 0.5: the shaders use them as pattern type 20
(`PATTERN_TEXTURE`, layer = _XxxPatternParam1), so every existing pattern control applies —
intensity, contrast, specular/roughness effect (bump), colour ramp (patternColor A–D), px-lock.
Colour comes from the ramp, not the texture: a wood tile is greyscale grain the skin maps to its
own browns. Every tile is periodic by construction (spectral noise, wrapped Worley cells, integer
frequencies), so it repeats with no seam.

MATCAPS are a sphere seen head-on in one studio (top-left soft box, high key, horizon, dark floor,
right rim): sampled with the surface normal they give metal, gloss, pearl and glass reflections
that read correctly at UI sizes. `mode` in the catalog says how the shader uses each: `metal`
(replaces the lit colour, tinted by the part's colour), `coat` (added on top: specular-only clear
coat / glass rim, black = nothing), `tint` (multiplies — soft diffuse sheens).
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "Assets" / "Resources" / "UiMaterials"
RNG = np.random.default_rng(20261006)
N = 512


# ── periodic building blocks ───────────────────────────────────────────────

def spectral(n=N, beta=2.0, fmin=1.0, fmax=None, ax=1.0, ay=1.0, angle=0.0, seed=None):
    """Periodic noise from filtered white noise: power ~ 1/f^beta between fmin and fmax cycles/tile.
    ax/ay stretch the spectrum (ax<ay → streaks along x). Result: zero mean, unit std."""
    rng = np.random.default_rng(seed) if seed is not None else RNG
    w = rng.standard_normal((n, n))
    fy = np.fft.fftfreq(n)[:, None] * n
    fx = np.fft.fftfreq(n)[None, :] * n
    if angle:
        c, s = np.cos(angle), np.sin(angle)
        fx, fy = fx * c - fy * s, fx * s + fy * c
    f = np.sqrt((fx * ax) ** 2 + (fy * ay) ** 2)
    f[0, 0] = 1.0
    filt = f ** (-beta / 2.0)
    filt[f < fmin] = 0.0
    if fmax:
        filt *= np.exp(-(f / fmax) ** 2)
    filt[0, 0] = 0.0
    out = np.real(np.fft.ifft2(np.fft.fft2(w) * filt))
    return (out - out.mean()) / (out.std() + 1e-9)


def worley(n=N, cells=16, jitter=0.9, seed=None):
    """Periodic Worley: returns (F1, F2, cell_id) distances in cell units on an n×n tile."""
    rng = np.random.default_rng(seed) if seed is not None else RNG
    pts = (np.arange(cells)[:, None, None] + 0.5 + (rng.random((cells, cells, 2)) - 0.5) * jitter)
    gy, gx = np.meshgrid(np.arange(cells), np.arange(cells), indexing="ij")
    px = (gx + 0.5 + (rng.random((cells, cells)) - 0.5) * jitter).ravel()
    py = (gy + 0.5 + (rng.random((cells, cells)) - 0.5) * jitter).ravel()
    ids = np.arange(cells * cells)
    y, x = np.meshgrid((np.arange(n) + 0.5) * cells / n, (np.arange(n) + 0.5) * cells / n, indexing="ij")
    f1 = np.full((n, n), 1e9)
    f2 = np.full((n, n), 1e9)
    cid = np.zeros((n, n), np.int64)
    for k in range(px.size):
        dx = np.abs(x - px[k]); dx = np.minimum(dx, cells - dx)
        dy = np.abs(y - py[k]); dy = np.minimum(dy, cells - dy)
        d = np.sqrt(dx * dx + dy * dy)
        closer = d < f1
        f2 = np.where(closer, f1, np.minimum(f2, d))
        cid = np.where(closer, ids[k], cid)
        f1 = np.where(closer, d, f1)
    return f1, f2, cid


def norm01(a, lo=0.02, hi=0.98):
    a0, a1 = np.quantile(a, lo), np.quantile(a, hi)
    return np.clip((a - a0) / (a1 - a0 + 1e-9), 0, 1)


def centre(a, std=0.16):
    """Map to mean 0.5, given std, clipped — the shaders treat 0.5 as 'no feature'."""
    a = (a - a.mean()) / (a.std() + 1e-9)
    return np.clip(0.5 + a * std, 0.0, 1.0)


Y, X = np.meshgrid(np.arange(N) / N, np.arange(N) / N, indexing="ij")


# ── textures ────────────────────────────────────────────────────────────────

def wood_grain():
    warp = spectral(beta=3.2, fmin=1, fmax=6, seed=1) * 0.035 + spectral(beta=2.5, fmin=2, fmax=20, seed=2) * 0.006
    yy = Y + warp + 0.02 * np.sin(2 * np.pi * (X * 2 + spectral(beta=3, fmin=1, fmax=4, seed=3) * 0.1))
    k = 11
    ph = (yy * k) % 1.0
    late = np.exp(-((ph - 0.55) / 0.11) ** 2) * 0.9 + np.exp(-((ph - 0.6) / 0.04) ** 2) * 0.5
    pores = spectral(beta=1.2, fmin=30, fmax=220, ax=0.06, ay=1.0, seed=4)
    fig = spectral(beta=2.0, fmin=2, fmax=12, ax=0.25, ay=1.0, seed=5)
    v = -late * 1.0 + pores * 0.18 + fig * 0.22
    return centre(v, 0.17)


def wood_burl():
    w1 = spectral(beta=3.0, fmin=2, fmax=10, seed=11)
    w2 = spectral(beta=3.0, fmin=2, fmax=10, seed=12)
    d = np.sin(2 * np.pi * (spectral(beta=2.6, fmin=3, fmax=24, seed=13) * 1.6 + w1 * 0.4))
    eyes = worley(cells=7, seed=14)[0]
    v = d * 0.6 - np.exp(-(eyes / 0.12) ** 2) * 1.6 + spectral(beta=1.2, fmin=40, fmax=200, seed=15) * 0.15 + w2 * 0.2
    return centre(v, 0.17)


def leather_pebble():
    f1, f2, _ = worley(cells=26, jitter=0.95, seed=21)
    crease = np.clip((f2 - f1) / 0.22, 0, 1) ** 0.6
    dome = 1 - (f1 / 0.75) ** 2
    v = crease * 0.9 + dome * 0.25 + spectral(beta=1.0, fmin=60, fmax=250, seed=22) * 0.08 \
        + spectral(beta=3, fmin=1, fmax=5, seed=23) * 0.12
    return centre(v, 0.15)


def leather_smooth():
    cre = spectral(beta=2.2, fmin=8, fmax=80, ax=1.0, ay=0.45, angle=0.6, seed=31)
    lines = 1 - np.exp(-(cre / 0.18) ** 2)   # thin dark creases where noise crosses zero
    v = lines * 0.6 + spectral(beta=1.4, fmin=40, fmax=240, seed=32) * 0.12 + spectral(beta=3, fmin=1, fmax=4, seed=33) * 0.2
    return centre(v, 0.13)


def velvet():
    crush = spectral(beta=3.3, fmin=1, fmax=7, seed=41)
    nap = spectral(beta=1.0, fmin=40, fmax=250, ax=1.0, ay=0.15, seed=42)
    v = np.tanh(crush * 1.4) * 0.8 + nap * 0.1
    return centre(v, 0.19)


def linen():
    t = 48
    ph_x, ph_y = (X * t) % 1.0, (Y * t) % 1.0
    jit = spectral(beta=1.6, fmin=4, fmax=60, seed=51) * 0.08
    warp = np.cos(np.pi * (ph_x - 0.5 + jit)) ** 2
    weft = np.cos(np.pi * (ph_y - 0.5 + jit)) ** 2
    over = ((np.floor(X * t) + np.floor(Y * t)) % 2) > 0
    v = np.where(over, warp * 1.0 + weft * 0.55, weft * 1.0 + warp * 0.55)
    v += spectral(beta=1.3, fmin=20, fmax=200, ax=1, ay=0.3, seed=52) * 0.12 + spectral(beta=3, fmin=1, fmax=5, seed=53) * 0.1
    return centre(v, 0.16)


def denim():
    t = 64
    diag = ((X + Y) * t) % 1.0
    ridge = np.cos(np.pi * (diag - 0.5)) ** 4
    slub = spectral(beta=1.6, fmin=8, fmax=120, ax=1.0, ay=0.08, seed=61)
    v = ridge * 0.8 + slub * 0.25 + spectral(beta=1.0, fmin=80, fmax=250, seed=62) * 0.1
    return centre(v, 0.15)


def marble():
    # Veins = where a turbulence-warped sine crosses zero. Keep the warp SMALL (a few tenths of a
    # cycle) or the sine wraps many times per pixel and the veins dissolve into speckle.
    t1 = spectral(beta=3.4, fmin=1, fmax=8, seed=71) * 0.38 + spectral(beta=2.4, fmin=4, fmax=30, seed=72) * 0.035
    s = np.sin(2 * np.pi * (X * 2 + Y * 1 + t1))
    wid = 0.05 + 0.04 * np.tanh(spectral(beta=3, fmin=1, fmax=6, seed=77))
    vein = np.exp(-(s / wid) ** 2) * 0.9 + np.exp(-(s / 0.28) ** 2) * 0.22
    t2 = spectral(beta=3.4, fmin=1, fmax=8, seed=74) * 0.45 + spectral(beta=2.4, fmin=4, fmax=30, seed=75) * 0.03
    s2 = np.sin(2 * np.pi * (X * 1 - Y * 3 + t2 + 0.3))
    vein2 = np.exp(-(s2 / 0.025) ** 2) * 0.5 + np.exp(-(s2 / 0.12) ** 2) * 0.1
    cloud = spectral(beta=3.0, fmin=1, fmax=10, seed=73) * 0.10 + spectral(beta=1.6, fmin=20, fmax=200, seed=76) * 0.03
    v = -(vein + vein2) + cloud
    return np.clip(0.62 + v * 0.42, 0, 1)


def terrazzo():
    v = spectral(beta=2.0, fmin=2, fmax=40, seed=81) * 0.15
    for cells, amp, size, seed in ((10, 0.9, 0.55, 82), (22, 0.6, 0.4, 83), (48, 0.4, 0.3, 84)):
        f1, f2, cid = worley(cells=cells, jitter=0.95, seed=seed)
        chip = (f1 < size * (0.6 + 0.4 * ((cid * 2654435761) % 997) / 997.0))
        shade = (((cid * 40503) % 1009) / 1009.0 - 0.5) * 2
        v = np.where(chip, shade * amp, v)
    return centre(v, 0.2)


def brushed_fine():
    v = spectral(beta=1.6, fmin=2, fmax=250, ax=0.02, ay=1.0, seed=91) + spectral(beta=3, fmin=1, fmax=6, seed=92) * 0.15
    return centre(v, 0.16)


def hammered():
    f1, f2, _ = worley(cells=14, jitter=0.85, seed=101)
    dent = (f1 / 0.85) ** 2
    v = -dent + np.clip((f2 - f1) / 0.1, 0, 1) * 0.15 + spectral(beta=1.5, fmin=30, fmax=200, seed=102) * 0.05
    return centre(v, 0.18)


def plaster():
    v = spectral(beta=2.4, fmin=1, fmax=60, seed=111) * 0.7 + spectral(beta=1.2, fmin=40, fmax=250, seed=112) * 0.25
    pits = worley(cells=40, seed=113)[0]
    v -= np.exp(-(pits / 0.07) ** 2) * 1.5
    return centre(v, 0.14)


def paper():
    v = spectral(beta=2.6, fmin=1, fmax=30, seed=121) * 0.35
    for a, s in ((0.3, 122), (1.2, 123), (2.1, 124), (2.7, 125)):
        v += spectral(beta=1.4, fmin=20, fmax=220, ax=0.15, ay=1.0, angle=a, seed=s) * 0.18
    return centre(v, 0.12)


def frost():
    f1, f2, _ = worley(cells=18, jitter=1.0, seed=131)
    edge = np.exp(-((f2 - f1) / 0.045) ** 2)
    f1b, f2b, _ = worley(cells=44, jitter=1.0, seed=132)
    edge2 = np.exp(-((f2b - f1b) / 0.05) ** 2)
    v = edge * 1.0 + edge2 * 0.5 + spectral(beta=2.5, fmin=1, fmax=20, seed=133) * 0.25
    return centre(v, 0.2)


def glitter():
    v = spectral(beta=2.0, fmin=2, fmax=60, seed=141) * 0.08
    rng = np.random.default_rng(142)
    n_sp = 5200
    xs, ys = rng.integers(0, N, n_sp), rng.integers(0, N, n_sp)
    amp = rng.random(n_sp) ** 2.2
    img = np.zeros((N, N))
    img[ys, xs] += amp
    k = np.exp(-(np.arange(-3, 4) ** 2) / 1.2)
    k2 = k[:, None] * k[None, :]
    F = np.fft.fft2(img) * np.fft.fft2(np.pad(k2, ((0, N - 7), (0, N - 7))))
    sp = np.real(np.fft.ifft2(F))
    sp = np.roll(sp, (-3, -3), axis=(0, 1))
    v = v + sp * 2.2
    return np.clip(0.42 + v * 0.35, 0, 1)


def soft_cloud():
    return centre(spectral(beta=3.0, fmin=1, fmax=24, seed=151), 0.18)


def crackle():
    f1, f2, _ = worley(cells=12, jitter=1.0, seed=161)
    f1b, f2b, _ = worley(cells=30, jitter=1.0, seed=162)
    crack = np.exp(-((f2 - f1) / 0.035) ** 2) + np.exp(-((f2b - f1b) / 0.03) ** 2) * 0.6
    v = -crack + spectral(beta=2.0, fmin=2, fmax=60, seed=163) * 0.2
    return centre(v, 0.17)


TEXTURES = [
    ("wood_grain", wood_grain, "plain-sawn wood, grain along x"),
    ("wood_burl", wood_burl, "burl / figured wood"),
    ("leather_pebble", leather_pebble, "pebble-grain leather"),
    ("leather_smooth", leather_smooth, "smooth leather with creases"),
    ("velvet", velvet, "crushed velvet sheen + nap"),
    ("linen", linen, "plain-weave linen / canvas"),
    ("denim", denim, "twill denim"),
    ("marble", marble, "veined marble (veins dark)"),
    ("terrazzo", terrazzo, "terrazzo / granite chips"),
    ("brushed_fine", brushed_fine, "fine brushed metal, streaks along x"),
    ("hammered", hammered, "hammered metal dimples"),
    ("plaster", plaster, "plaster / concrete with pits"),
    ("paper", paper, "fibrous paper / card"),
    ("frost", frost, "frost / ice crystals"),
    ("glitter", glitter, "glitter / sparkle specks"),
    ("crackle", crackle, "aged-paint craquelure"),
]


# ── matcaps ─────────────────────────────────────────────────────────────────

M = 256


def _sphere():
    y, x = np.meshgrid(np.linspace(1, -1, M), np.linspace(-1, 1, M), indexing="ij")   # row 0 = top (y up)
    r2 = x * x + y * y
    inside = r2 <= 1.0
    z = np.sqrt(np.clip(1 - r2, 0, 1))
    return x, y, z, inside


def _env(rx, ry, rz, blur=0.0):
    """Studio radiance for reflection direction r (y up, z toward viewer)."""
    sky = np.clip(ry, 0, 1)
    e = 0.10 + 0.25 * sky ** 0.6                                   # dim cool studio, brighter up
    e = e - 0.08 * np.clip(-ry, 0, 1) ** 0.5                       # dark floor
    horizon = np.exp(-((ry - 0.02) / (0.05 + blur * 0.4)) ** 2) * 0.35
    floor_bounce = np.exp(-((ry + 0.35) / (0.12 + blur * 0.4)) ** 2) * 0.10
    sw = 0.22 + blur * 0.6                                         # soft box: big, top-left, toward camera
    box = np.exp(-(((rx + 0.38) / (sw * 1.4)) ** 6 + ((ry - 0.62) / sw) ** 6)) * 1.6
    sw2 = 0.10 + blur * 0.5                                        # strip light right
    strip = np.exp(-(((rx - 0.80) / sw2) ** 4 + ((ry - 0.10) / (0.45 + blur)) ** 4)) * 0.9 * (rz > 0.15)
    key = np.exp(-(((rx - 0.05) ** 2 + (ry - 0.92) ** 2) / (0.004 + blur * 0.08))) * 2.0   # hot top key
    return e + horizon + floor_bounce + box + strip + key * (rz > -0.2)


def _reflect(x, y, z):
    # view v = (0,0,1) toward the camera; r = 2(n·v)n - v
    return 2 * z * x, 2 * z * y, 2 * z * z - 1


def metal(blur=0.0, aniso=0.0):
    x, y, z, inside = _sphere()
    rx, ry, rz = _reflect(x, y, z)
    if aniso:
        ry = ry * (1 - aniso) + np.sign(ry) * np.abs(ry) ** 0.5 * aniso * 0.2
    e = _env(rx, ry, rz, blur)
    fres = 0.75 + 0.25 * (1 - z) ** 3
    # a lifted floor: a UI metal sits in a lit room, not a black studio — without it aluminium and
    # satin brass read as dark steel (Walnut & Brass, 2026-10-06)
    v = np.clip(0.2 + e * fres * 0.9, 0, 1.4)
    return np.dstack([v, v, v]), inside


def coat(blur=0.0, strength=1.0):
    """Specular-only clear coat: black where nothing reflects (shader ADDS it)."""
    x, y, z, inside = _sphere()
    rx, ry, rz = _reflect(x, y, z)
    e = _env(rx, ry, rz, blur)
    fres = 0.04 + 0.96 * (1 - z) ** 5
    v = np.clip((np.clip(e - 0.30, 0, None) * 0.9 + 0.0) * (0.35 + 0.65 * fres / 0.3).clip(0, 2.2) * 0.45 * strength, 0, 1)
    return np.dstack([v, v, v]), inside


def pearl():
    x, y, z, inside = _sphere()
    rx, ry, rz = _reflect(x, y, z)
    e = _env(rx, ry, rz, 0.25)
    t = (1 - z) * 2.6 + ry * 0.6
    irid = np.dstack([0.5 + 0.5 * np.cos(6.283 * (t + 0.00)),
                      0.5 + 0.5 * np.cos(6.283 * (t + 0.33)),
                      0.5 + 0.5 * np.cos(6.283 * (t + 0.67))])
    base = 0.66 + 0.2 * z
    col = base[..., None] * (0.80 + 0.24 * irid) * np.array([1.0, 0.97, 0.95]) + (np.clip(e - 0.45, 0, None) * 0.3)[..., None]
    return np.clip(col, 0, 1), inside


def glass_rim():
    x, y, z, inside = _sphere()
    rx, ry, rz = _reflect(x, y, z)
    e = _env(rx, ry, rz, 0.02)
    fres = 0.04 + 0.96 * (1 - z) ** 4
    rim = fres * 0.9 + np.clip(e - 0.4, 0, None) * (0.25 + fres)
    caustic = np.exp(-(((x - 0.25) ** 2 + (y + 0.45) ** 2) / 0.05)) * 0.35   # light focused through the drop
    v = np.clip(rim + caustic, 0, 1)
    return np.dstack([v, v, v]), inside


def ceramic():
    x, y, z, inside = _sphere()
    rx, ry, rz = _reflect(x, y, z)
    diff = 0.55 + 0.35 * np.clip(x * -0.4 + y * 0.7 + z * 0.6, 0, 1)
    spec = np.clip(_env(rx, ry, rz, 0.08) - 0.4, 0, None) * 0.35
    v = np.clip(diff + spec, 0, 1)
    return np.dstack([v, v, v]), inside


def rubber():
    x, y, z, inside = _sphere()
    diff = 0.35 + 0.45 * np.clip(x * -0.35 + y * 0.6 + z * 0.7, 0, 1) ** 1.3
    v = np.clip(diff, 0, 1)
    return np.dstack([v, v, v]), inside


MATCAPS = [
    ("chrome", lambda: metal(0.0), "metal", "mirror chrome — tint for gold/copper/brass"),
    ("polished", lambda: metal(0.08), "metal", "polished metal, slightly soft"),
    ("satin", lambda: metal(0.25), "metal", "satin / bead-blasted metal"),
    ("brushed", lambda: metal(0.18, aniso=0.6), "metal", "brushed metal, highlights stretched"),
    ("gloss_coat", lambda: coat(0.0), "coat", "sharp clear coat: lacquer, gloss plastic, enamel"),
    ("satin_coat", lambda: coat(0.2, 0.8), "coat", "soft clear coat: satin plastic, waxed wood"),
    ("pearl", pearl, "tint", "pearl / mother-of-pearl sheen"),
    ("glass_rim", glass_rim, "coat", "glass / water droplet: fresnel rim + caustic"),
    ("ceramic", ceramic, "tint", "glazed ceramic"),
    ("rubber", rubber, "tint", "matte rubber / soft touch"),
]


# ── wallpapers (backdrops for glass looks) ──────────────────────────────────

BW, BH = 1920, 1080


def _blobs(specs, base, seed):
    rng = np.random.default_rng(seed)
    y, x = np.mgrid[0:BH, 0:BW].astype(np.float32)
    x /= BH; y /= BH
    img = np.ones((BH, BW, 3), np.float32) * np.array(base, np.float32)
    for cx, cy, r, col, a in specs:
        d = ((x - cx) ** 2 + (y - cy) ** 2) / (r * r)
        img += np.exp(-d * 1.6)[..., None] * np.array(col, np.float32) * a
    return img, x, y, rng


def wall_aurora():
    img, x, y, rng = _blobs([(0.4, 0.3, 0.6, (0.1, 0.9, 0.6), 0.55), (1.2, 0.25, 0.55, (0.4, 0.3, 1.0), 0.5),
                             (1.6, 0.7, 0.5, (0.0, 0.6, 0.9), 0.4), (0.8, 0.85, 0.5, (0.8, 0.2, 0.7), 0.25)],
                            (0.02, 0.03, 0.08), 201)
    for k in range(3):
        ph = rng.random() * 6.28
        band = np.exp(-((y - (0.35 + 0.12 * k) - 0.08 * np.sin(x * (2.2 + k) + ph)) / 0.05) ** 2)
        img += band[..., None] * np.array([(0.2, 1.0, 0.7), (0.5, 0.4, 1.0), (0.2, 0.8, 1.0)][k]) * 0.35
    return img


def wall_deepwater():
    img, x, y, rng = _blobs([(0.9, -0.1, 0.9, (0.1, 0.6, 0.7), 0.6), (0.3, 0.9, 0.6, (0.0, 0.2, 0.4), 0.4),
                             (1.5, 0.6, 0.5, (0.0, 0.5, 0.6), 0.35)], (0.0, 0.05, 0.09), 202)
    caus = np.zeros((BH, BW), np.float32)
    for f, a in ((7.0, 1.0), (13.0, 0.6)):
        u = np.sin(x * f + np.sin(y * f * 0.8) * 1.6) + np.sin(y * f * 1.1 + np.sin(x * f * 0.7) * 1.4)
        caus += np.exp(-(u / 0.35) ** 2) * a
    img += (caus * np.clip(1.2 - y, 0, 1))[..., None] * np.array([0.25, 0.75, 0.8]) * 0.35
    return img


def wall_bokeh():
    img, x, y, rng = _blobs([(0.9, 0.5, 1.2, (0.25, 0.08, 0.15), 0.6)], (0.03, 0.02, 0.04), 203)
    cols = [(1.0, 0.65, 0.25), (1.0, 0.35, 0.4), (0.4, 0.6, 1.0), (1.0, 0.85, 0.5), (0.8, 0.4, 1.0)]
    for _ in range(70):
        cx, cy, r = rng.random() * 1.78, rng.random(), 0.02 + rng.random() ** 2 * 0.09
        d = np.sqrt((x - cx) ** 2 + (y - cy) ** 2) / r
        disk = np.clip((1.0 - d) * 6, 0, 1) * (0.6 + 0.4 * d)
        img += disk[..., None] * np.array(cols[rng.integers(len(cols))]) * (0.15 + rng.random() * 0.35)
    return img


def wall_sunset():
    y = np.linspace(0, 1, BH, dtype=np.float32)[:, None]
    x = np.linspace(0, BW / BH, BW, dtype=np.float32)[None, :]
    top, mid, low = np.array([0.12, 0.05, 0.3]), np.array([0.95, 0.3, 0.45]), np.array([1.0, 0.7, 0.3])
    t = y[..., None]
    img = np.where(t < 0.6, top + (mid - top) * (t / 0.6), mid + (low - mid) * ((t - 0.6) / 0.4))
    img = img + np.zeros((1, BW, 1))
    sun = np.exp(-(((x - 0.89) ** 2 + (y - 0.72) ** 2) / 0.02))
    img += sun[..., None] * np.array([1.0, 0.8, 0.5]) * 0.6
    return img


BP = BW / BH          # the wallpaper's width in height units: the x period of a TILEABLE wallpaper


def _pdx(x, cx):
    """Horizontal distance on a wallpaper that wraps sideways (so a glow near the right edge continues on the left)."""
    d = np.abs(x - cx)
    return np.minimum(d, BP - d)


def wall_lagoon():
    """A DARK flowing-water wallpaper for glass looks, SEAMLESSLY TILEABLE in x: every wave number is an integer
    count of cycles across the width and every glow wraps, so a host can drift it sideways forever and the
    refraction in a glass part keeps moving without a seam. A caustic network (crisp enough for a lens to bend)
    over cold teal / blue / violet fields with one warm coral note."""
    y, x = np.mgrid[0:BH, 0:BW].astype(np.float32)
    x /= BH; y /= BH
    u = 2.0 * np.pi * x / BP
    img = np.ones((BH, BW, 3), np.float32) * np.array((0.0, 0.04, 0.09), np.float32)
    for cx, cy, r, col, a in ((0.30, 0.15, 0.55, (0.05, 0.65, 0.75), 0.60), (1.30, 0.55, 0.55, (0.08, 0.28, 0.85), 0.55),
                              (0.00, 0.85, 0.50, (0.45, 0.16, 0.85), 0.50), (0.85, 0.95, 0.40, (0.00, 0.50, 0.60), 0.40),
                              (1.55, 0.12, 0.35, (0.90, 0.25, 0.55), 0.30)):
        d2 = (_pdx(x, cx) ** 2 + (y - cy) ** 2) / (r * r)
        img += np.exp(-d2 * 1.6)[..., None] * np.array(col, np.float32) * a
    caus = np.zeros((BH, BW), np.float32)
    for (k1, k2), (f1, f2), a in (((2, 1), (5.6, 7.7), 1.0), ((4, 3), (10.4, 14.3), 0.6)):
        w = np.sin(k1 * u + np.sin(y * f1) * 1.6) + np.sin(y * f2 + np.sin(k2 * u) * 1.4)
        caus += np.exp(-(w / 0.35) ** 2) * a
    img += (caus * np.clip(1.2 - y, 0, 1))[..., None] * np.array([0.25, 0.75, 0.8], np.float32) * 0.32
    return img


def wall_daybreak():
    """A PALE wallpaper for light glass looks, SEAMLESSLY TILEABLE in x (see wall_lagoon): a milk-blue sky with soft
    peach / mint / lilac / rose glows (blended, not added, so the hues survive), two slow light bands and crisp
    pastel orbs for a lens to bend. Luminance stays ~0.65-0.82 and NO channel passes ~0.92, so milk glass over it
    never clips to white and dark print still reads."""
    y, x = np.mgrid[0:BH, 0:BW].astype(np.float32)
    x /= BH; y /= BH
    u = 2.0 * np.pi * x / BP
    rng = np.random.default_rng(204)
    img = np.ones((BH, BW, 3), np.float32) * np.array((0.74, 0.80, 0.90), np.float32)
    for cx, cy, r, col, a in ((0.20, 0.25, 0.60, (0.90, 0.68, 0.56), 0.85),      # peach
                              (0.95, 0.10, 0.60, (0.50, 0.72, 0.90), 0.85),      # sky
                              (1.55, 0.50, 0.55, (0.72, 0.62, 0.90), 0.85),      # lilac
                              (0.55, 0.95, 0.60, (0.54, 0.86, 0.74), 0.85),      # mint
                              (1.30, 1.00, 0.45, (0.90, 0.62, 0.74), 0.80)):     # rose
        w = (np.exp(-((_pdx(x, cx) ** 2 + (y - cy) ** 2) / (r * r)) * 1.6) * a)[..., None]
        img = img * (1 - w) + np.array(col, np.float32) * w
    for k in range(2):
        ph = rng.random() * 6.28
        band = np.exp(-((y - (0.40 + 0.22 * k) - 0.07 * np.sin((1 + k) * u + ph)) / 0.07) ** 2)[..., None]
        img = img * (1 - band * 0.35) + np.array([(0.90, 0.88, 0.86), (0.86, 0.90, 0.92)][k], np.float32) * band * 0.35
    # crisp pastel orbs: a lens bends nothing in a smooth gradient, so give refraction edges to catch
    for cx, cy, r, col in ((0.30, 0.62, 0.075, (0.90, 0.60, 0.74)), (0.74, 0.30, 0.060, (0.52, 0.84, 0.72)),
                           (1.20, 0.70, 0.085, (0.66, 0.60, 0.92)), (0.12, 0.84, 0.055, (0.92, 0.72, 0.52)),
                           (0.62, 0.84, 0.050, (0.56, 0.74, 0.92)), (1.50, 0.26, 0.070, (0.90, 0.60, 0.74)),
                           (0.95, 0.54, 0.045, (0.92, 0.72, 0.52)), (1.62, 0.84, 0.060, (0.52, 0.84, 0.72)),
                           (0.40, 0.20, 0.050, (0.66, 0.60, 0.92)), (1.05, 0.92, 0.040, (0.90, 0.60, 0.74))):
        m = np.clip((r - np.sqrt(_pdx(x, cx) ** 2 + (y - cy) ** 2)) / 0.008, 0, 1)[..., None] * 0.8
        img = img * (1 - m) + np.array(col, np.float32) * m
    return img


WALLPAPERS = [("Aurora", wall_aurora), ("DeepWater", wall_deepwater), ("Bokeh", wall_bokeh), ("Sunset", wall_sunset),
              ("Lagoon", wall_lagoon), ("Daybreak", wall_daybreak)]
# wallpapers a host may DRIFT sideways (UiBackdrop scrolling _UIBackdropUV.zw): imported with Repeat wrap in x
TILEABLE = ("Lagoon", "Daybreak")


def write_wallpapers():
    import uuid
    d = ROOT / "Assets" / "Resources" / "Backdrops"
    d.mkdir(parents=True, exist_ok=True)
    for name, fn in WALLPAPERS:
        img = np.clip(fn(), 0, 1)
        # a whisper of grain so the 8-bit gradients don't band
        img += (np.random.default_rng(7).random(img.shape[:2])[..., None] - 0.5) / 255.0
        Image.fromarray((np.clip(img, 0, 1) * 255 + 0.5).astype(np.uint8), "RGB").save(d / f"{name}.png", optimize=True)
        meta = d / f"{name}.png.meta"
        if not meta.exists():
            meta.write_text(f"""fileFormatVersion: 2
guid: {uuid.uuid4().hex}
TextureImporter:
  serializedVersion: 13
  mipmaps:
    mipMapMode: 0
    enableMipMap: 1
    sRGBTexture: 1
  isReadable: 0
  maxTextureSize: 2048
  textureSettings:
    serializedVersion: 2
    filterMode: 1
    aniso: 1
    mipBias: 0
    wrapU: {0 if name in TILEABLE else 1}
    wrapV: 1
    wrapW: 1
  nPOTScale: 0
  textureType: 0
  textureShape: 1
  alphaUsage: 0
  platformSettings:
  - serializedVersion: 3
    buildTarget: DefaultTexturePlatform
    maxTextureSize: 2048
    textureFormat: -1
    textureCompression: 1
    compressionQuality: 50
  userData:
  assetBundleName:
  assetBundleVariant:
""", encoding="utf-8", newline=chr(10))
        print("  wallpaper", name)


# ── output ──────────────────────────────────────────────────────────────────

def build():
    tex_atlas = np.full((4 * N, 4 * N), 128, np.uint8)
    tex_cat = []
    for i, (name, fn, desc) in enumerate(TEXTURES):
        t = fn()
        r, c = divmod(i, 4)
        tex_atlas[r * N:(r + 1) * N, c * N:(c + 1) * N] = (np.clip(t, 0, 1) * 255 + 0.5).astype(np.uint8)
        tex_cat.append({"layer": i, "name": name, "desc": desc})
        print(f"  tex {i:2d} {name}")

    cap_atlas = np.zeros((4 * M, 4 * M, 3), np.uint8)
    cap_cat = []
    for i, (name, fn, mode, desc) in enumerate(MATCAPS):
        col, inside = fn()
        # extend the rim colour outward a little so bilinear sampling at the silhouette is clean
        col = np.where(inside[..., None], col, col * 0)
        r, c = divmod(i, 4)
        cap_atlas[r * M:(r + 1) * M, c * M:(c + 1) * M] = (np.clip(col, 0, 1) * 255 + 0.5).astype(np.uint8)
        cap_cat.append({"layer": i, "name": name, "mode": mode, "desc": desc})
        print(f"  cap {i:2d} {name} ({mode})")
    return tex_atlas, tex_cat, cap_atlas, cap_cat


def preview(tex_atlas, cap_atlas, path):
    from PIL import ImageDraw
    t = Image.fromarray(tex_atlas, "L").resize((1024, 1024)).convert("RGB")
    c = Image.fromarray(cap_atlas, "RGB").resize((1024, 1024))
    sheet = Image.new("RGB", (2068, 1024), (16, 18, 22))
    sheet.paste(t, (0, 0)); sheet.paste(c, (1044, 0))
    d = ImageDraw.Draw(sheet)
    for i, (n, *_r) in enumerate(TEXTURES):
        r, cc = divmod(i, 4); d.text((cc * 256 + 6, r * 256 + 6), n, fill=(255, 60, 60))
    for i, (n, *_r) in enumerate(MATCAPS):
        r, cc = divmod(i, 4); d.text((1044 + cc * 256 + 6, r * 256 + 6), n, fill=(255, 60, 60))
    sheet.save(path)
    print("  preview ->", path)


def main():
    tex_atlas, tex_cat, cap_atlas, cap_cat = build()
    prev = ROOT / ".skinsheet" / "materials_preview.png"
    prev.parent.mkdir(exist_ok=True)
    preview(tex_atlas, cap_atlas, prev)
    if len(sys.argv) > 1 and sys.argv[1] == "preview":
        return
    write_wallpapers()
    OUT.mkdir(parents=True, exist_ok=True)
    Image.fromarray(tex_atlas, "L").save(OUT / "MaterialTex.png", optimize=True)
    Image.fromarray(cap_atlas, "RGB").save(OUT / "Matcaps.png", optimize=True)
    (OUT / "catalog.json").write_text(json.dumps({
        "_comment": "Generated by Tools/gen_materials.py. Layer indices are what skins write: textures → "
                    "_XxxPatternType 20 + _XxxPatternParam1 = layer; matcaps → _XxxMatcapLayer.",
        "textures": tex_cat, "texture_tile_px": N, "matcaps": cap_cat, "matcap_px": M,
    }, indent=1), encoding="utf-8")
    print("  wrote", OUT)


if __name__ == "__main__":
    main()
