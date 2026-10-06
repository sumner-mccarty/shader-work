#!/usr/bin/env python3
"""
Parity test: slrender vs the real Unity editor (Assets/Editor/SkinSheet.cs).

    python tests/parity.py golden --project D:/repos/audiogame   # needs Unity open (Windows)
    python tests/parity.py check                                  # anywhere, no Unity

`golden` renders CELLS in Unity through the project's SkinSheet job bus and freezes everything
the check needs into tests/golden/: the Unity PNGs, the exact states.json files used, the theme
rig, and cells.json. `check` re-renders those cells headless and compares, writing per-cell diff
heatmaps and a contact sheet to tests/out/. The check is self-contained — it never reads the
Unity project — so a cloud worker can prove its renderer still matches Unity.

Exit code is non-zero when any cell exceeds the tolerance.
"""
from __future__ import annotations

import argparse
import json
import shutil
import sys
import time
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
REPO = HERE.parent
GOLDEN = HERE / "golden"
OUT = HERE / "out"
sys.path.insert(0, str(REPO))

# id, states, w, h, extra
CELLS = [
    ("knobrm_real_hero",   "RealisticKnobHero",  132, 132, {"set": {"_Value": 0.4}}),
    ("knobrm_real_hero_sh", "RealisticKnobHero", 132, 132, {"set": {"_Value": 0.4}, "shadow": 2}),
    ("knobrm_real_0",      "RealisticKnob",       72,  72, {"set": {"_Value": 0.0}}),
    ("knobrm_real_80",     "RealisticKnob",       72,  72, {"set": {"_Value": 0.8}}),
    ("knobrm_real_corner", "RealisticKnob",       72,  72, {"set": {"_Value": 0.5}, "pos": [0.1, 0.9]}),
    ("knobrm_neol",        "NeoLightKnob",        72,  72, {"set": {"_Value": 0.6}, "bg": "#C9CED6"}),
    ("knobrm_neod_small",  "NeoDarkKnobSmall",    48,  48, {"set": {"_Value": 0.3}}),
    ("knob_tron_hero",     "TronDarkKnobHero",   132, 132, {"set": {"_Value": 0.6}, "bg": "#05070A"}),
    ("knob_flatl",         "FlatLightKnob",       72,  72, {"set": {"_Value": 0.25}, "bg": "#E8EBEF"}),
    ("btnrm_real",         "RealisticButton",    120,  56, {}),
    ("btnrm_real_hover",   "RealisticButton",    120,  56, {"state": "Hover"}),
    ("btnrm_real_press",   "RealisticButton",    120,  56, {"state": "Pressed"}),
    ("btnrm_real_sh",      "RealisticButton",    120,  56, {"shadow": 2}),
    ("btnrm_neol",         "NeoLightButton",     120,  56, {"bg": "#C9CED6"}),
    ("btnrm_neod_lamp",    "NeoDarkLamp",         56,  56, {"state": "Active"}),
    ("btn_flatd",          "FlatDarkButton",     120,  56, {}),
    ("btn_flatd_pad",      "FlatDarkPad",         96,  96, {}),
    ("btn_tron",           "TronDarkButton",     120,  56, {"bg": "#05070A"}),
    ("btn_tron_ss2",       "TronDarkButton",     120,  56, {"bg": "#05070A", "ss": 2}),
    ("sldrm_real",         "RealisticSlider",     64, 220, {"set": {"_Value": 0.3}}),
    ("sldrm_neod",         "NeoDarkSlider",       64, 220, {"set": {"_Value": 0.7}}),
    ("sld_flatl_fader",    "FlatLightFader",      48, 200, {"set": {"_Value": 0.5}, "bg": "#E8EBEF"}),
    ("sld_tron_h",         "TronDarkSlider",     220,  48, {"set": {"_Value": 0.65}, "bg": "#05070A"}),
    ("pill_real_off",      "RealisticPill",       80,  40, {"set": {"_Value": 0.0}}),
    ("pill_real_on",       "RealisticPill",       80,  40, {"set": {"_Value": 1.0}}),
    ("pill_tron",          "TronDarkPill",        80,  40, {"set": {"_Value": 1.0}, "bg": "#05070A"}),
    ("panel_rack_graphite", "RackFaceplateGraphite", 300, 160, {}),
    ("panel_neol_face",    "NeoLightFace",       300, 160, {}),
    ("panel_flatd_face",   "FlatDarkFace",       300, 160, {}),
    ("panel_tron_face",    "TronDarkFace",       300, 160, {"bg": "#05070A"}),
]

THEME = "Themes/Realistic.theme"


def cells_for(states_dir: Path):
    out = []
    for cid, states, w, h, extra in CELLS:
        c = {"id": cid, "states": str((states_dir / f"{states}.states.json").resolve()).replace("\\", "/"),
             "w": w, "h": h, "bg": "#1A1D22"}
        c.update(extra)
        out.append(c)
    return out


# ── golden (Unity) ──────────────────────────────────────────────────────────

def make_golden(project: Path):
    sys.path.insert(0, str(project / "Tools"))
    import skinsheet  # the project's own Unity job driver

    src_states = project / "Assets" / "Resources" / "MaterialStates"
    if GOLDEN.exists():
        shutil.rmtree(GOLDEN)
    (GOLDEN / "states").mkdir(parents=True)
    (GOLDEN / "png").mkdir()
    for _, states, *_ in CELLS:
        shutil.copy2(src_states / f"{states}.states.json", GOLDEN / "states" / f"{states}.states.json")
    theme_src = project / "Assets" / "Resources" / (THEME + ".json")
    (GOLDEN / "Themes").mkdir()
    shutil.copy2(theme_src, GOLDEN / "Themes" / theme_src.name)

    cells = cells_for(src_states)
    t = time.time()
    payload = skinsheet.render(cells)
    print(f"unity: {payload} in {time.time() - t:.1f}s")
    for c in cells:
        shutil.copy2(skinsheet.OUT / f"{c['id']}.png", GOLDEN / "png" / f"{c['id']}.png")
    rel = []
    for cid, states, w, h, extra in CELLS:
        c = {"id": cid, "states": f"states/{states}.states.json", "w": w, "h": h, "bg": "#1A1D22"}
        c.update(extra)
        rel.append(c)
    (GOLDEN / "cells.json").write_text(json.dumps({"theme": THEME, "cells": rel,
                                                   "unity": payload, "made": time.strftime("%Y-%m-%d %H:%M")},
                                                  indent=1), encoding="utf-8")
    print(f"golden -> {GOLDEN}")


# ── check (headless) ────────────────────────────────────────────────────────

def _blur(a: np.ndarray) -> np.ndarray:
    from PIL import ImageFilter
    return np.asarray(Image.fromarray(a, "RGBA").filter(ImageFilter.GaussianBlur(1.0))).astype(np.float32)


def compare(a: np.ndarray, b: np.ndarray):
    """
    Raw stats are reported, but PASS/FAIL is judged perceptually, because two compilers never agree
    bit-for-bit on a raymarched silhouette (hit/miss flips on a 1px ring) or on a pattern finer
    than a pixel (aliasing noise). Those average out under a 1px blur; a real logic difference —
    a wrong uniform, a flipped axis, a missing term — does not, and it also shows up as BIAS.
      bias       signed mean error (0..255 levels) — catches "everything a bit brighter"
      blur_mean  mean |error| after a 1px Gaussian
      blur_p8    % of pixels still more than 8 levels off after the blur
    """
    if a.shape != b.shape:
        return {"shape": f"{a.shape} vs {b.shape}"}
    d = np.abs(a.astype(np.int16) - b.astype(np.int16))
    dm = d.max(axis=2)
    db = np.abs(_blur(a) - _blur(b))
    return {"max": int(d.max()), "mean": float(d.mean()),
            "bias": float((a.astype(np.float32) - b.astype(np.float32))[..., :3].mean()),
            "blur_mean": float(db.mean()), "blur_p8": float((db.max(axis=2) > 8).mean() * 100.0),
            "diff": dm}


TOL = {"bias": 1.0, "blur_mean": 1.5, "blur_p8": 5.0}


def passes(m) -> bool:
    return ("shape" not in m and abs(m["bias"]) <= TOL["bias"] and m["blur_mean"] <= TOL["blur_mean"]
            and m["blur_p8"] <= TOL["blur_p8"])


def heat(dm: np.ndarray) -> Image.Image:
    v = np.clip(dm.astype(np.float32) * 8.0, 0, 255).astype(np.uint8)
    rgb = np.stack([v, (v * 0.35).astype(np.uint8), 255 - v], axis=2)
    rgb[dm == 0] = (12, 12, 16)
    return Image.fromarray(rgb, "RGB")


def check(project=None):
    from slrender.skins import SkinRenderer, load_rig

    meta = json.loads((GOLDEN / "cells.json").read_text(encoding="utf-8"))
    sr = SkinRenderer(project or REPO, resources=GOLDEN, orientation="texture")  # goldens come from SkinSheet
    rig = load_rig(GOLDEN, meta.get("theme", THEME))
    OUT.mkdir(exist_ok=True)
    rows, failed = [], 0
    t_all = time.time()
    for c in meta["cells"]:
        c = dict(c)
        c["states"] = str(GOLDEN / c["states"])
        t = time.time()
        try:
            img = sr.render_cell(c, rig)
        except Exception as e:
            print(f"  {c['id']:<22} ERROR {type(e).__name__}: {str(e)[:300]}")
            failed += 1
            continue
        dt = time.time() - t
        ref = np.asarray(Image.open(GOLDEN / "png" / f"{c['id']}.png").convert("RGBA"))
        m = compare(img, ref)
        ok = passes(m)
        failed += 0 if ok else 1
        extra = m.get("shape") or (f"bias {m['bias']:+5.2f}  blur mean {m['blur_mean']:4.2f}  blur>8 {m['blur_p8']:4.1f}%"
                                   f"   (raw max {m['max']:3d} mean {m['mean']:4.2f})")
        print(f"  {'ok ' if ok else 'BAD'} {c['id']:<22} {extra}   ({dt:.2f}s)")
        Image.fromarray(img, "RGBA").save(OUT / f"{c['id']}.png")
        rows.append((c["id"], img, ref, m))
    print(f"{len(rows)} cells in {time.time() - t_all:.1f}s, {failed} over tolerance")
    _sheet(rows, OUT / "parity_sheet.png")
    return failed


def _sheet(rows, path):
    if not rows:
        return
    pad, lab = 8, 14
    W = pad + sum(0 for _ in rows)
    colw = max(r[2].shape[1] for r in rows)
    H = sum(max(r[2].shape[0], 20) + lab + pad for r in rows) + pad
    sheet = Image.new("RGB", (pad * 4 + colw * 3, H), (16, 18, 22))
    d = ImageDraw.Draw(sheet)
    y = pad
    for cid, img, ref, m in rows:
        d.text((pad, y), f"{cid}   unity | slrender | diff x8   mean {m.get('mean', 0):.2f}", fill=(200, 205, 215))
        y += lab
        for i, im in enumerate((ref, img)):
            tile = Image.fromarray(im, "RGBA")
            sheet.paste(tile.convert("RGB"), (pad + i * (colw + pad), y), tile)
        if "diff" in m:
            sheet.paste(heat(m["diff"]), (pad + 2 * (colw + pad), y))
        y += max(ref.shape[0], 20) + pad
    sheet.save(path)
    print(f"  sheet -> {path}")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", choices=["golden", "check"])
    ap.add_argument("--project", type=Path,
                    help="golden: the Unity project. check: where to find Shaders/ (default: this repo)")
    a = ap.parse_args()
    if a.cmd == "golden":
        if not a.project:
            sys.exit("golden needs --project <Unity project root>")
        make_golden(a.project)
    else:
        sys.exit(1 if check(a.project) else 0)
