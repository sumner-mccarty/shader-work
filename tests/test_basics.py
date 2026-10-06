#!/usr/bin/env python3
"""
slrender basics — the generic (non-skin) contract, on tiny fixture shaders:

    python tests/test_basics.py            # GPU/default GL
    SLRENDER_SOFTWARE=1 python tests/test_basics.py

Checks: texture + uv orientation (row 0 of a PNG = top = uv.y 1, as in Unity), derivative signs,
Properties defaults, Int uniforms, multi_compile keywords, HLSLPROGRAM with modern texture syntax,
user cbuffers, float4x4 packing (HLSL mul order), float4 arrays, premultiplied blending, and that
editing a .shader in a live process is picked up.
"""
from __future__ import annotations

import shutil
import sys
import tempfile
from pathlib import Path

import numpy as np

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO))

from slrender import Renderer, TextureSpec  # noqa: E402

FIX = REPO / "tests" / "fixtures" / "Shaders"
failures = []


def check(name, cond, detail=""):
    print(f"  {'ok ' if cond else 'BAD'} {name}{('  ' + detail) if detail and not cond else ''}")
    if not cond:
        failures.append(name)


def main():
    tmp = Path(tempfile.mkdtemp(prefix="slr_test_"))
    shutil.copytree(FIX, tmp / "Shaders")
    r = Renderer([tmp / "Shaders"])
    print("gl:", r.gl_info()["GL_RENDERER"])

    # 1. texture identity + orientation: top half red, bottom half blue, left column green
    src = np.zeros((8, 8, 4), np.uint8)
    src[:4] = (255, 0, 0, 255)
    src[4:] = (0, 0, 255, 255)
    src[:, 0] = (0, 255, 0, 255)
    img = r.render("Slr/TexIdentity", size=(8, 8),
                   textures={"_MainTex": TextureSpec(data=src, filter="point")})
    check("texture identity (top=red, bottom=blue, left=green)", np.array_equal(img, src),
          f"got top-left {img[0, 0]} top {img[0, 4]} bottom {img[7, 4]}")

    # 2. uv probe: top-left pixel has uv ~ (0, 1)
    img = r.render("Slr/TexIdentity", {"_Mode": 1}, size=(16, 16))
    check("uv origin bottom-left, PNG row 0 = top", img[0, 0, 0] < 16 and img[0, 0, 1] > 240
          and img[15, 15, 0] > 240 and img[15, 15, 1] < 16, f"tl {img[0, 0]} br {img[15, 15]}")

    # 3. derivative signs: ddx(uv.x) > 0 and ddy(uv.y) > 0 (Unity D3D render-to-texture)
    img = r.render("Slr/TexIdentity", {"_Mode": 2}, size=(64, 64))
    check("ddx/ddy positive", img[32, 32, 0] > 200 and img[32, 32, 1] > 200, f"{img[32, 32]}")

    # 3b. "screen" orientation (the app's backbuffer): same upright image, ddy(uv.y) < 0
    img = r.render("Slr/TexIdentity", size=(8, 8), orientation="screen",
                   textures={"_MainTex": TextureSpec(data=src, filter="point")})
    check("screen: texture still upright", np.array_equal(img, src), f"top {img[0, 4]} bottom {img[7, 4]}")
    img = r.render("Slr/TexIdentity", {"_Mode": 2}, size=(64, 64), orientation="screen")
    check("screen: ddx > 0, ddy < 0", img[32, 32, 0] > 200 and img[32, 32, 1] < 8, f"{img[32, 32]}")

    # 4. Properties default (Tint white) vs set; keyword
    img = r.render("Slr/TexIdentity", {"_Tint": (0.5, 0.5, 0.5, 1)}, size=(4, 4))
    check("material colour applied", abs(int(img[1, 1, 0]) - 128) <= 1, f"{img[1, 1]}")
    img = r.render("Slr/TexIdentity", size=(4, 4), keywords=["SLR_RED_ON"])
    check("multi_compile keyword", tuple(img[1, 1, :3]) == (255, 0, 0), f"{img[1, 1]}")

    # 5. HLSLPROGRAM: quadrant colours via float4 array, matrix swaps x/y, cbuffer gain/alpha
    quad = [(1, 0, 0, 1), (0, 1, 0, 1), (0, 0, 1, 1), (1, 1, 0, 1)]   # BL BR TL TR
    ident = np.eye(4).tolist()
    img = r.render("Slr/HlslUniforms", {"_Quad": quad, "_UvXform": ident, "_Gain": 1.0, "_Alpha": 1.0},
                   size=(8, 8), bg=(0, 0, 0, 0))
    check("float4 array + orientation (TL blue, BR green)",
          tuple(img[0, 0, :3]) == (0, 0, 255) and tuple(img[7, 7, :3]) == (0, 255, 0), f"tl {img[0, 0]} br {img[7, 7]}")
    swap = [[0, 1, 0, 0], [1, 0, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]]   # uv' = (uv.y, uv.x)
    img = r.render("Slr/HlslUniforms", {"_Quad": quad, "_UvXform": swap, "_Gain": 1.0, "_Alpha": 1.0}, size=(8, 8))
    # top-left pixel: uv=(0,1) -> uv'=(1,0) -> BR quadrant -> green
    check("float4x4 in HLSL mul order", tuple(img[0, 0, :3]) == (0, 255, 0), f"tl {img[0, 0]}")
    shift = [[1, 0, 0, 0.5], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]]   # translation column
    img = r.render("Slr/HlslUniforms", {"_Quad": quad, "_UvXform": shift, "_Gain": 1.0, "_Alpha": 1.0}, size=(8, 8))
    check("float4x4 translation column", tuple(img[7, 0, :3]) == (0, 255, 0), f"bl {img[7, 0]}")

    # 6. premultiplied blend over a background
    img = r.render("Slr/HlslUniforms", {"_Quad": [(1, 1, 1, 1)] * 4, "_UvXform": ident, "_Gain": 1.0, "_Alpha": 0.5},
                   size=(4, 4), bg=(0, 0, 1, 1))
    check("Blend One OneMinusSrcAlpha", abs(int(img[1, 1, 0]) - 128) <= 1 and abs(int(img[1, 1, 2]) - 255) <= 1,
          f"{img[1, 1]}")

    # 7. edit the .shader while the process is alive
    f = tmp / "Shaders" / "SlrTexIdentity.shader"
    f.write_text(f.read_text().replace("c.rgb = float3(1, 0, 0);", "c.rgb = float3(0, 1, 0);"))
    import os, time
    os.utime(f, (time.time() + 2, time.time() + 2))
    img = r.render("Slr/TexIdentity", size=(4, 4), keywords=["SLR_RED_ON"])
    check("live .shader edit picked up", tuple(img[1, 1, :3]) == (0, 255, 0), f"{img[1, 1]}")

    shutil.rmtree(tmp, ignore_errors=True)
    print(f"{'FAILED: ' + ', '.join(failures) if failures else 'all passed'}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
