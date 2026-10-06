#!/usr/bin/env python3
"""
skinsheet — the authoring loop for .states.json skins.

Talks to Assets/Editor/SkinSheet.cs (an [InitializeOnLoad] editor poller) through a pair of
files in <project>/.skinsheet/. We write job.json, Unity renders every cell with the REAL
shader at the control's REAL pixel size and drops PNGs in .skinsheet/out/, we assemble an
annotated contact sheet. No Play Mode, no AssetDatabase import, no scene.

Usage as a library:
    from skinsheet import render, sheet
    render(cells)                       # cells -> PNGs
    sheet(rows, "out.png", title="...")  # PNGs -> annotated grid
"""
from __future__ import annotations

import json
import os
import subprocess
import time
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
BUS = ROOT / ".skinsheet"
OUT = BUS / "out"
SKINS = ROOT / "Assets" / "Resources" / "MaterialStates"

BUS.mkdir(exist_ok=True)
OUT.mkdir(exist_ok=True)


# ── talking to Unity ─────────────────────────────────────────────────────────

def _nudge_unity():
    """Unity's EditorApplication.update throttles hard when the window is not focused; on some
    machines it stops entirely. Poking the window costs ~100ms and makes the loop deterministic."""
    subprocess.run(
        ["powershell", "-NoProfile", "-Command", r"""
$sig = '[DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);'
$t = Add-Type -MemberDefinition $sig -Name W -Namespace N -PassThru -ErrorAction SilentlyContinue
$p = Get-Process Unity -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
if ($p) { [void]$t::SetForegroundWindow($p.MainWindowHandle) }
"""],
        capture_output=True, timeout=30,
    )


def refresh_assets(settle=14):
    """
    Force an asset-database refresh, then wait for the import to settle.

    The render loop deliberately does NOT refresh (that is the whole point — a states.json is
    read from disk, so iterating on skins never pays the import tax). But a SHADER edit is
    invisible to it: Unity keeps serving the previously compiled shader and the sheet quietly
    renders the old code, which reads as "my change did nothing". Auto-refresh only fires when
    the editor actually regains OS focus, and SetForegroundWindow from a background process is
    routinely ignored by Windows — so this activates the window properly and sends Ctrl+R,
    Unity's own Refresh shortcut.

    Call it once after touching a .shader/.cginc, not between skin iterations.
    (No-op under the slrender backend: it recompiles whenever a shader or include changes.)
    """
    if backend() == "slrender":
        return
    subprocess.run(
        ["powershell", "-NoProfile", "-Command", r"""
Add-Type -AssemblyName System.Windows.Forms
$p = Get-Process Unity -ErrorAction SilentlyContinue |
     Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
if ($p) {
  $ws = New-Object -ComObject WScript.Shell
  [void]$ws.AppActivate($p.Id)
  Start-Sleep -Milliseconds 800
  [System.Windows.Forms.SendKeys]::SendWait('^r')
}
"""],
        capture_output=True, timeout=60,
    )
    time.sleep(settle)


# ── backend: the Unity editor, or slrender (headless, no Unity) ─────────────
#
# SKINSHEET_BACKEND=unity|slrender|bus picks one; unset = Unity when an editor is running on Windows,
# slrender otherwise (Linux cloud workers, CI, a closed editor). `bus` = the .skinsheet/job.json
# protocol answered by a WARM `python -m slrender watch --bus .skinsheet` process — use it for
# iteration loops on a CPU rasteriser, where a fresh process pays ~20s per shader to compile. slrender (shader-work repo) renders
# the same cells with the same shaders — parity-tested against SkinSheet.cs — and by default in the
# app's SCREEN orientation, which fixes SkinSheet's inverted bevel-depth sign (SKILL.md). Set
# SKINSHEET_ORIENTATION=texture to reproduce SkinSheet.cs exactly.

_slr = None


def backend():
    b = os.environ.get("SKINSHEET_BACKEND", "").lower()
    if b in ("unity", "slrender", "bus"):
        return b
    if os.name == "nt":
        try:
            out = subprocess.run(["tasklist", "/FI", "IMAGENAME eq Unity.exe", "/NH"],
                                 capture_output=True, text=True, timeout=10).stdout
            if "Unity.exe" in out:
                return "unity"
        except (OSError, subprocess.SubprocessError):
            pass
    return "slrender"


def _slrender():
    """SkinRenderer from the shader-work checkout: $SLRENDER_HOME, this repo, or ../shader-work."""
    global _slr
    if _slr is None:
        import sys
        for home in (os.environ.get("SLRENDER_HOME"), ROOT, ROOT.parent / "shader-work"):
            if home and (Path(home) / "slrender" / "__init__.py").exists():
                sys.path.insert(0, str(Path(home)))
                break
        from slrender.skins import SkinRenderer
        _slr = SkinRenderer(ROOT, orientation=os.environ.get("SKINSHEET_ORIENTATION", "screen"))
    return _slr


def render(cells, rig=None, timeout=180, nudge=True):
    """Render a list of cell dicts into OUT/<id>.png. Returns the done.json-style payload."""
    if backend() == "slrender":
        job = {"out": str(OUT), "cells": cells}
        if rig:
            job["rig"] = rig
        payload = _slrender().run_job(job, OUT)
        if payload.get("fail"):
            print(f"  ! {payload['fail']} cell(s) failed: {payload.get('log', '')[:1500]}")
        return payload
    done = BUS / "done.json"
    done.unlink(missing_ok=True)

    job = {"out": str(OUT).replace("\\", "/"), "cells": cells}
    if rig:
        job["rig"] = rig
    # Write to a temp name then move, so the editor never reads a half-written file.
    tmp = BUS / "job.tmp"
    tmp.write_text(json.dumps(job, indent=1), encoding="utf-8")
    tmp.replace(BUS / "job.json")

    if nudge and backend() == "unity":
        _nudge_unity()

    deadline = time.time() + timeout
    while time.time() < deadline:
        if done.exists():
            time.sleep(0.15)
            payload = json.loads(done.read_text(encoding="utf-8"))
            if payload.get("fail"):
                print(f"  ! {payload['fail']} cell(s) failed: {payload.get('log','')[:1500]}")
            return payload
        time.sleep(0.25)
    raise TimeoutError("no answer on the job bus — is Unity open (SkinSheet.cs compiled), or "
                       "`python -m slrender watch --bus .skinsheet` running?")


# ── contact sheets ───────────────────────────────────────────────────────────

def _font(size, bold=False):
    cands = [Path(r"C:\Windows\Fonts") / n for n in (("seguisb.ttf", "segoeui.ttf") if bold else ("segoeui.ttf",))]
    cands += [Path("/usr/share/fonts/truetype/dejavu") / ("DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf"),
              Path("/System/Library/Fonts/Helvetica.ttc")]
    for p in cands:
        if p.exists():
            return ImageFont.truetype(str(p), size)
    try:
        return ImageFont.load_default(size=size)
    except TypeError:
        return ImageFont.load_default()


def sheet(rows, out_path, title=None, bg="#101317", fg="#E6EBF2", dim="#7C8794",
          pad=18, gap=14, label_h=16, cell_bg=None, max_width=2400):
    """
    rows: list of dicts { "label": str, "cells": [ {"id": str, "caption": str}, ... ] }
    Each cell's PNG is read from .skinsheet/out/<id>.png at its natural size.
    """
    f_title = _font(24, True)
    f_row = _font(15, True)
    f_cap = _font(12)

    # measure
    row_metrics = []
    for row in rows:
        imgs = []
        for c in row["cells"]:
            p = OUT / f"{c['id']}.png"
            imgs.append(Image.open(p).convert("RGBA") if p.exists() else None)
        w = sum((im.width if im else 40) + gap for im in imgs) - gap if imgs else 0
        h = max((im.height if im else 40) for im in imgs) if imgs else 40
        row_metrics.append((imgs, w, h))

    head = (44 if title else 0)
    content_w = max([w for _, w, _ in row_metrics] + [1])
    label_w = max(f_row.getbbox(r["label"])[2] for r in rows) + 22 if rows else 0
    W = min(max_width, pad * 2 + label_w + content_w)
    H = head + pad * 2 + sum(h + label_h + gap + 10 for _, _, h in row_metrics)

    sh = Image.new("RGBA", (W, H), bg)
    d = ImageDraw.Draw(sh)
    if title:
        d.text((pad, pad - 2), title, font=f_title, fill=fg)

    y = head + pad
    for (imgs, _, h), row in zip(row_metrics, rows):
        d.text((pad, y + h // 2 - 8), row["label"], font=f_row, fill=fg)
        x = pad + label_w
        for im, c in zip(imgs, row["cells"]):
            if im is None:
                d.rectangle([x, y, x + 40, y + 40], outline="#803030")
                d.text((x + 3, y + 14), "?", font=f_cap, fill="#C05050")
                x += 40 + gap
                continue
            if cell_bg:
                d.rectangle([x, y, x + im.width - 1, y + im.height - 1], fill=cell_bg)
            sh.alpha_composite(im, (x, y + (h - im.height) // 2))
            cap = c.get("caption")
            if cap:
                d.text((x, y + h + 4), cap, font=f_cap, fill=dim)
            x += im.width + gap
        y += h + label_h + gap + 10

    sh.convert("RGB").save(out_path)
    print(f"  -> {out_path}  ({W}x{H})")
    return out_path


def skin_path(name, folder=None):
    """Absolute forward-slash path to a .states.json, for a cell's "states" field."""
    base = Path(folder) if folder else SKINS
    return str((base / f"{name}.states.json").resolve()).replace("\\", "/")
