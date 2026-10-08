#!/usr/bin/env python3
"""Clearwater flow demo: the procedural wallpaper flows while the glass refracts it.

    SKINSHEET_BACKEND=bus python Looks/clearwater/flow_demo.py [dark|light|both] [--frames 8] [--measure]
    (--measure: only the text-free legibility pass, no GIF/strip — use it with many frames, e.g. --frames 24)

Writes  Looks/clearwater/sheets/flow-<mode>.gif  (one seamless loop = one wallpaper width)
        Looks/clearwater/sheets/flow-<mode>-strip.png  (4 frames side by side, for the PR)
and prints a LEGIBILITY report: for every printed label on the rack, the worst-case contrast of its ink
against the brightest (dark ink: darkest) background that ever passes behind it during the loop. The
backgrounds are measured on a text-free render of the same frame, so glyphs never pollute the number.

What the app has to do to match this (Unity side, not in this repo): render the mode's `backdropSkin`
(<Prefix><Mode>Backdrop.states.json — a Backdrop* shader + its params) into a mipmapped render texture every
frame (Graphics.Blit(null, rt, material)), bind it as `_UIBackdropTex`, and draw it behind the UI. No widget
shader changes: the glass already samples `_UIBackdropTex` at its (refracted) screen position.
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "Tools"))
sys.path.insert(0, str(ROOT / "Tools" / "looks"))
import lookkit  # noqa: E402
from clearwater import LOOK  # noqa: E402

def period(mode):
    """Seconds in one loop of this mode's wallpaper: 1 / _Speed (the Backdrop* shaders are exactly periodic)."""
    fx = LOOK.modes[mode]["backdrop_fx"]
    stem = "Backdrop" + fx["shader"]
    from shaderprops import properties
    speed = float(fx["params"].get("_Speed", properties(stem)["_Speed"]["default"]))
    return 1.0 / speed


_orig_text = lookkit.Canvas.text


def lin(c):
    c = np.asarray(c, dtype=np.float64)
    c = np.where(c <= 0.03928, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    return c[..., 0] * 0.2126 + c[..., 1] * 0.7152 + c[..., 2] * 0.0722


def hex_rgb(h):
    h = h.lstrip("#")
    return [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]


def labels(mode):
    """(name, rect in canvas px, ink hex) for every label the rack prints over GLASS — rects from rack_sheet."""
    P = LOOK.palette(mode)
    face, face_dim = lookkit.ink(LOOK, mode, P)
    ins, ins_dim = lookkit.ink(LOOK, mode, P, "inset")
    bp, bp_dim = lookkit.ink(LOOK, mode, P, "backplane")
    key, key_dim = lookkit.first(P["MARK"]), lookkit.first(P["MARK_DIM"])
    on = lookkit.first(P["ON_MARK"])
    out = []
    for i, cx in enumerate((68, 178, 288, 398, 508, 588)):
        out.append((f"knob caption {i}", (cx - 22, 176, cx + 22, 190), ins_dim))
    out += [("MASTER", (684, 226, 748, 240), face_dim), ("PRESSED", (826, 226, 890, 240), face_dim),
            ("FADER caption", (24, 418, 180, 432), face_dim), ("PADS caption", (980, 222, 1160, 236), face_dim),
            ("A01 KICK", (700, 504, 772, 520), bp), ("look title", (200, 548, 350, 562), bp_dim)]
    for i, cx in enumerate((496, 580, 664, 748)):
        out.append((f"key label {i}", (cx - 14, 337, cx + 14, 351), key if i < 3 else key_dim))
    out += [("PLAY (accent)", (376, 337, 408, 351), on), ("PLAY (accent, states)", (376, 385, 408, 399), on),
            ("LEARN chip", (432, 38, 460, 52), key)]
    return out


def measure(img, mode):
    """Worst-case WCAG contrast per label from a TEXT-FREE rack render (img already includes the 40px title)."""
    a = np.asarray(img.convert("RGB"), dtype=np.float32) / 255.0
    rows = []
    for name, (x0, y0, x1, y1), ink_hex in labels(mode):
        bg = lin(a[y0 + 40:y1 + 40, x0:x1])
        il = float(lin(np.array(hex_rgb(ink_hex))))
        worst = float(np.percentile(bg, 99)) if il > float(np.median(bg)) else float(np.percentile(bg, 1))
        hi, lo = max(il, worst), min(il, worst)
        rows.append((name, (hi + 0.05) / (lo + 0.05)))
    return rows


def run(mode, frames):
    tmp = ROOT / ".skinsheet" / f"flow-{mode}"
    tmp.mkdir(parents=True, exist_ok=True)
    shots, worst = [], {}
    for f in range(frames):
        lookkit.BACKDROP_TIME = f / frames * period(mode)           # frame f of one seamless loop
        lookkit.Canvas.text = lambda self, *a, **k: None            # text-free pass: backgrounds only
        bare = lookkit.rack_sheet(LOOK, mode, tmp / f"bare-{f}.png")
        lookkit.Canvas.text = _orig_text
        for name, c in measure(Image.open(bare), mode):
            worst[name] = min(worst.get(name, 99.0), c)
        if not MEASURE_ONLY:
            shots.append(Image.open(lookkit.rack_sheet(LOOK, mode, tmp / f"frame-{f}.png")).convert("RGB"))
        print(f"  {mode} frame {f + 1}/{frames}", flush=True)
    sheets = ROOT / "Looks" / LOOK.slug / "sheets"
    if not MEASURE_ONLY:
        write_outputs(mode, frames, shots, sheets)
    report(mode, frames, worst)
    return worst


def write_outputs(mode, frames, shots, sheets):
    small = [im.resize((im.width // 2, im.height // 2), Image.LANCZOS) for im in shots]
    pal = [im.quantize(colors=96, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE) for im in small]
    pal[0].save(sheets / f"flow-{mode}.gif", save_all=True, append_images=pal[1:], duration=140, loop=0, optimize=True)
    pick = [shots[round(i * (frames - 1) / 3)] for i in range(4)]            # four frames, full size, 2x2
    w, h = pick[0].size
    strip = Image.new("RGB", (w * 2, h * 2))
    for i, im in enumerate(pick):
        strip.paste(im, ((i % 2) * w, (i // 2) * h))
    strip.resize((strip.width * 3 // 4, strip.height * 3 // 4), Image.LANCZOS).save(sheets / f"flow-{mode}-strip.png", optimize=True)


def report(mode, frames, worst):
    print(f"\nLEGIBILITY over the {frames}-frame loop ({mode}) — worst-case contrast of each label's ink vs the wallpaper behind it:")
    low = 0
    for name, c in sorted(worst.items(), key=lambda kv: kv[1]):
        flag = "  !! under 3:1" if c < 3.0 else ""
        low += c < 3.0
        print(f"  {c:5.2f}  {name}{flag}")
    print(f"  -> {low} label(s) under 3:1")


MEASURE_ONLY = "--measure" in sys.argv

if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    n = int(sys.argv[sys.argv.index("--frames") + 1]) if "--frames" in sys.argv else 8
    args = [a for a in args if not a.isdigit()]
    for m in (("dark", "light") if (not args or args[0] == "both") else (args[0],)):
        run(m, n)
