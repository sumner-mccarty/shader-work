#!/usr/bin/env python3
"""
scopesheet — the offline authoring loop for the MIXER DISPLAYS (`UI/SDFScope`).

`skinsheet` renders a control from a `.states.json`; a ScopeDisplay has no states file — its
material is configured from layout-node props merged over a named finish in
`Resources/UiThemes/ScopeFinishes.json` (see ScopeDisplay.ApplyProps / DisplaySurfaceProps).
This module does that merge in Python, emits a throwaway states-shaped doc per display into
`.skinsheet/scopes/`, and hands it to the same Unity poller. So a contact sheet here shows the
REAL shader with the REAL per-module configuration the mixer ships, not an approximation.

    from scopesheet import display_states, MIXER_DISPLAYS
    from skinsheet import render, sheet

Every cell may `set` any shader property on top (`_Activity`, `_Engaged`, `_P0`, `_Phase`, ...),
which is how one display becomes a bypassed / mix-0 / mix-1 row.
"""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BUS = ROOT / ".skinsheet"
SCOPES = BUS / "scopes"
FINISHES = ROOT / "Assets" / "Resources" / "UiThemes" / "ScopeFinishes.json"


# ── json-with-// comments (the layout/theme files carry doc comments) ────────

def loose_json(text: str):
    out = []
    for s in text.splitlines():
        inq = esc = False
        res = ""
        i = 0
        while i < len(s):
            c = s[i]
            if esc:
                res += c; esc = False; i += 1; continue
            if c == "\\":
                res += c; esc = True; i += 1; continue
            if c == '"':
                inq = not inq; res += c; i += 1; continue
            if (not inq) and c == "/" and i + 1 < len(s) and s[i + 1] == "/":
                break
            res += c; i += 1
        out.append(res)
    return json.loads("\n".join(out))


def finishes() -> dict:
    return loose_json(FINISHES.read_text(encoding="utf-8"))["finishes"]


# ── prop key -> (shader property, states type) ──────────────────────────────
#
# Mirrors ScopeDisplay.ApplyProps + DisplaySurfaceProps.Push. A key missing here is a key the
# sheet would silently drop, so keep the two in step.

_C, _F = "Color", "Range"

KEYMAP = {
    "mode": ("_Mode", _F),
    "bgColor": ("_BgColor", _C), "gridColor": ("_GridColor", _C),
    "curveColor": ("_CurveColor", _C), "fillColor": ("_FillColor", _C),
    "h0Color": ("_H0Color", _C), "h1Color": ("_H1Color", _C), "h2Color": ("_H2Color", _C),
    "playheadColor": ("_PlayheadColor", _C),
    "grid": ("_GridEnabled", _F), "fill": ("_FillEnabled", _F),
    "curveThickness": ("_CurveThickness", _F), "glow": ("_Glow", _F),
    "waveColorMode": ("_WaveColorMode", _F),
    "lowColor": ("_LowColor", _C), "midColor": ("_MidColor", _C), "highColor": ("_HighColor", _C),

    "surfaceMode": ("_SurfaceMode", _F),
    "surfaceReflect": ("_SurfaceReflect", _F), "surfaceGloss": ("_SurfaceGloss", _F),
    "surfaceRough": ("_SurfaceRough", _F), "surfaceFresnel": ("_SurfaceFresnel", _F),
    "surfaceCurveOptical": ("_SurfaceCurveOptical", _F), "surfaceEnv": ("_SurfaceEnv", _F),
    "surfaceInnerShadow": ("_SurfaceInnerShadow", _F),
    "surfaceSignalMask": ("_SurfaceSignalMask", _F), "surfaceEnvColor": ("_SurfaceEnvColor", _C),
    "bezelPx": ("_BezelPx", _F), "bezelRoundPx": ("_BezelRoundPx", _F),
    "bezelColor": ("_BezelColor", _C),
    # cut-in (2026-09-18) — the hole the display sits in; see UIDisplaySurface.cginc
    "cutEdgePx": ("_CutEdgePx", _F), "cutEdgeColor": ("_CutEdgeColor", _C),
    "cutEdgeStrength": ("_CutEdgeStrength", _F), "cutRoundPx": ("_CutRoundPx", _F),
    "cutBevelPx": ("_CutBevelPx", _F), "cutBevelDepth": ("_CutBevelDepth", _F),
    "cutBevelMinPx": ("_CutBevelMinPx", _F), "cutWallColor": ("_CutWallColor", _C),
    # VU ladder zones (MeterStyle, LOOK choice) — alpha-0 colours = classic green/amber/red
    "vuLowColor": ("_VuLowColor", _C), "vuMidColor": ("_VuMidColor", _C),
    "vuHighColor": ("_VuHighColor", _C), "vuSegments": ("_VuSegments", _F),

    "pixelCellsX": ("_PixelCellsX", _F), "pixelCellsY": ("_PixelCellsY", _F),
    "pixelGap": ("_PixelGap", _F), "pixelRound": ("_PixelRound", _F),
    "pixelFloor": ("_PixelFloor", _F),
    "scanlineAmount": ("_ScanlineAmount", _F), "scanlinePitchPx": ("_ScanlinePitchPx", _F),
    "plasticHaze": ("_PlasticHaze", _F),
    "curveAmount": ("_CurveAmount", _F), "vignetteAmount": ("_VignetteAmount", _F),
    "surfaceTint": ("_SurfaceTint", _C),
}


# DisplaySurfaceProps field defaults the shader would otherwise see as its Properties defaults.
CSHARP_DEFAULTS = {
    "cutEdgePx": 5, "cutEdgeColor": "0,0,0,0.85", "cutEdgeStrength": 0.8, "cutRoundPx": 6,
    "cutBevelPx": 5, "cutBevelDepth": 1, "cutBevelMinPx": 80, "cutWallColor": "0.22,0.23,0.25,0.9",
}


def _value(v):
    if isinstance(v, bool):
        return "1" if v else "0"
    if isinstance(v, (int, float)):
        return f"{float(v):.6g}"
    return str(v)


def display_states(name: str, props: dict, quad=None) -> str:
    """Merge finish + node props into a states-shaped doc on disk; return its absolute path."""
    # C#-side defaults that are ON unless a finish says otherwise (DisplaySurfaceProps).
    merged = dict(CSHARP_DEFAULTS)
    fin = props.get("finish")
    if fin:
        base = finishes().get(fin)
        if base is None:
            raise KeyError(f"unknown finish '{fin}'")
        merged.update({k: v for k, v in base.items() if not k.startswith("_")})
    merged.update({k: v for k, v in props.items() if k != "finish"})

    params = []
    for k, v in merged.items():
        hit = KEYMAP.get(k)
        if hit is None:
            continue                      # animated/playheadSpeed etc. are C#-side, not uniforms
        params.append({"name": hit[0], "type": hit[1], "value": _value(v)})
    # _QuadSize must be declared as a Vector4 here so per-cell `set` overrides inherit that type
    # (SkinSheet's GuessType would otherwise read "150,58" as a Color).
    q = quad or (150, 58)
    params.append({"name": "_QuadSize", "type": "Vector4", "value": f"{q[0]},{q[1]},0,0"})
    # Same reason: declare every param/handle bank so a cell's `set` writes them as vectors.
    for bank in ("_P0", "_P1", "_P2", "_H0", "_H1", "_H2"):
        params.append({"name": bank, "type": "Vector4", "value": "0,0,0,0"})

    doc = {
        "controlType": "ScopeDisplay",
        "shaderName": "UI/SDFScope",
        "states": [{
            "stateId": f"{name}-normal", "stateName": "Normal",
            "description": "scope", "baseStateName": "", "priority": 0,
            "tags": ["default"], "parameters": params,
        }],
    }
    SCOPES.mkdir(parents=True, exist_ok=True)
    p = SCOPES / f"{name}.states.json"
    p.write_text(json.dumps(doc, indent=1), encoding="utf-8")
    return str(p.resolve()).replace("\\", "/")


# The eleven ScopeDisplay nodes the mixer actually builds (Mixer.layout.json), with the pixel
# size each is laid out at. Kept here so a sheet is a statement about the SHIPPING mixer.
MIXER_DISPLAYS = [
    ("envy",   [240, 96],  {"finish": "glass.amber", "mode": 0, "fill": True, "grid": False,
                            "curveThickness": 1.1}),
    ("filter", [150, 100], {"finish": "glass.cyan", "mode": 1, "grid": True, "fill": False,
                            "h0Color": "#4DA6FF", "h1Color": "#FF9E2E", "h2Color": "#8CF04A"}),
    ("comp",   [110, 82],  {"finish": "lcd.grey", "mode": 2, "fill": False}),
    ("chorus", [110, 82],  {"finish": "plastic.blue", "mode": 4, "grid": False,
                            "curveColor": "#2DE2E6", "h1Color": "#8AB8FF", "h2Color": "#40E8A8"}),
    ("flange", [120, 80],  {"finish": "crt.phosphor", "mode": 5, "grid": False, "fill": False}),
    ("echo",   [110, 82],  {"finish": "led.matrix.amber", "mode": 6, "grid": False,
                            "pixelCellsX": 30, "pixelCellsY": 10}),
    ("drive",  [180, 100], {"finish": "glass.amber", "mode": 3, "curveThickness": 2.0,
                            "curveColor": "#FF5030", "fillColor": "#FF503022",
                            "surfaceTint": "#FFCFC033"}),
    ("reverb", [120, 82],  {"finish": "glass.cyan", "mode": 7, "grid": False, "fill": True,
                            "fillColor": "#40A8FF22"}),
    ("meterL", [160, 22],  {"finish": "led.matrix.green", "mode": 9, "grid": False}),
    ("duck",   [20, 30],   {"finish": "led.matrix.amber", "mode": 9, "grid": False}),
]

# Representative knob positions per module, so a cell shows a real picture rather than the
# shader's property defaults. (bank0, bank1) — the same meaning MixerPanel's WireDsp pushes.
DEMO_PARAMS = {
    "envy":   ((0.18, 0.22, 0.55, 0.30), (0.95, 0, 0, 0)),
    "filter": ((0.18, 0.45, 0.86, 0.68), (0.35, 0.30, 0.45, 0)),
    "comp":   ((0.45, 0.30, 0.35, 0.40), (0, 0, 0, 0)),
    "chorus": ((0.45, 0.60, 0.40, 0.35), (0, 0, 0, 0)),
    "flange": ((0.40, 0.70, 0.55, 0), (0, 0, 0, 0)),
    "echo":   ((0.35, 0.62, 0.50, 0.40), (0, 0, 0, 0)),
    "drive":  ((0.55, 0, 0, 0), (0, 0, 0, 0)),
    "reverb": ((0.55, 0.60, 0.50, 0.40), (0, 0, 0, 0)),
    "meterL": ((0.62, 0, 0, 0), (0, 0, 0, 0)),
    "duck":   ((0.45, 0, 0, 0), (0, 0, 0, 0)),
}


def cell(name, size, props, cid, extra=None, ss=2, bg="#14171B"):
    """One render cell for a mixer display, with its demo params pre-set."""
    p0, p1 = DEMO_PARAMS.get(name, ((0.3, 0.4, 0.6, 0.5), (0.4, 0.6, 0.4, 0)))
    s = {
        "_P0": ",".join(f"{v:g}" for v in p0),
        "_P1": ",".join(f"{v:g}" for v in p1),
        "_QuadSize": f"{size[0]},{size[1]},0,0",
    }
    s.update(extra or {})
    return {"id": cid, "states": display_states(name, props, size),
            "shader": "UI/SDFScope", "w": size[0], "h": size[1], "ss": ss, "bg": bg, "set": s}
