#!/usr/bin/env python3
"""
skinlib — author `.states.json` skins from Python, validated against the real shader.

Why a library rather than hand-edited JSON: a states.json is a flat bag of ~60-140 name/value
pairs with no schema, and the two ways to waste an hour on one are (a) naming a property the
shader does not declare — it is silently ignored, so the value "does nothing" and you go looking
for the wrong bug — and (b) writing a colour into a Float slot. Both are caught here at author
time by checking every key against the shader's own Properties block.

It also enforces the project's RM/non-RM parity rule: a skin file is shared by `SDFKnob` and
`SDFKnobRM`, so a property that exists on only one of them is a trap. Anything RM-only other than
the known view-projection set is reported.
"""
from __future__ import annotations

import json
import re
from pathlib import Path

from shaderprops import properties, states_type

ROOT = Path(__file__).resolve().parent.parent
SKINS = ROOT / "Assets" / "Resources" / "MaterialStates"

# family -> (states.json shaderName, RM shader stem, flat shader stem)
FAMILY = {
    "Button": ("UI/SDFButtonRM", "SDFButtonRM", "SDFButton"),
    "Knob":   ("UI/SDFKnobRM",   "SDFKnobRM",   "SDFKnob"),
    "Slider": ("UI/SDFSliderRM", "SDFSliderRM", "SDFSlider"),
    "Toggle": ("UI/SDFTogglePill", "SDFTogglePill", "SDFTogglePill"),
    "Panel":  ("UI/SDFPanel",    "SDFPanel",    "SDFPanel"),
}

# ── hit-test bounds ──────────────────────────────────────────────────────────
#
# LoadedBounds defaults to a FULL-RECT hitbox (type Rect, width=height=1) when a states.json
# carries no "bounds" key at all — confirmed in MaterialStateStack/Core/ShaderBounds.cs. That is
# not "no hit test", it is "the entire RectTransform is hit-testable", including the corner/edge
# margin outside the control's visible shape that a correctly-bounded control leaves as dead space
# for whatever sits behind it (e.g. a ScrollRect's drag-to-scroll gesture). A skin with no bounds
# therefore steals input its neighbours were passing through — this is exactly what broke Mixer
# scrolling after a theme swap re-skinned its knobs to bounds-less files.
#
# These mirror the STOCK skin each role ships with (WidgetRoles.StockSkin), read straight off their
# .states.json. `paddingParam` is preferred where the shader exposes one: MaterialStateUiControl
# derives the live hitbox from that shader property + the current aspect ratio, so the authored
# width/height here are only the fallback for a control with no live material yet.
BOUNDS = {
    "knob":       {"type": 0, "width": 0.890625, "height": 0.890625,
                   "radiusNorm": 0.9019293785095215, "paddingParam": ""},
    "button":     {"type": 0, "width": 0.890625, "height": 0.90625,
                   "radiusNorm": 1.0, "paddingParam": "_ButtonPadding"},
    "button_round": {"type": 0, "width": 0.9375, "height": 0.953125,
                     "radiusNorm": 0.9888291954994202, "paddingParam": "_ButtonPadding"},
    "slider":     {"type": 0, "width": 0.96875, "height": 0.875,
                   "radiusNorm": 1.0, "paddingParam": "_BgPadding"},
    "button_accent": {"type": 0, "width": 0.875, "height": 0.7752808928489685,
                      "radiusNorm": 1.0, "paddingParam": "_ButtonPadding"},
    "pill":       {"type": 0, "width": 0.953125, "height": 0.90625, "radiusNorm": 1.0},
    "panel":      {"type": 0, "width": 1.0, "height": 1.0, "radiusNorm": 1.0},
}

# RM-only properties that are legitimately RM-only: the view/perspective projection the flat
# shader is documented to ignore. Anything else RM-only is a shader parity bug, not a skin choice.
VIEW_ONLY = re.compile(r'^_View')

_cache: dict[str, dict] = {}


def props(stem):
    if stem not in _cache:
        _cache[stem] = properties(stem)
    return _cache[stem]


# ── colour helpers ───────────────────────────────────────────────────────────

def rgba(hex_or_tuple, alpha=None):
    """'#RRGGBB[AA]' or (r,g,b[,a]) floats -> the 'r,g,b,a' string a states.json carries."""
    if isinstance(hex_or_tuple, (tuple, list)):
        c = list(hex_or_tuple) + [1.0] * (4 - len(hex_or_tuple))
    else:
        s = hex_or_tuple.lstrip("#")
        if len(s) == 6:
            s += "ff"
        c = [int(s[i:i + 2], 16) / 255.0 for i in (0, 2, 4, 6)]
    if alpha is not None:
        c[3] = alpha
    return ",".join(f"{v:.6g}" for v in c)


def mix(a, b, t):
    """Blend two '#RRGGBB' colours in linear-ish sRGB. Handy for deriving state deltas."""
    def unpack(h):
        s = h.lstrip("#")
        if len(s) == 6:
            s += "ff"
        return [int(s[i:i + 2], 16) for i in (0, 2, 4, 6)]
    ca, cb = unpack(a), unpack(b)
    out = [round(x + (y - x) * t) for x, y in zip(ca, cb)]
    return "#" + "".join(f"{v:02X}" for v in out)


def shade(hexcol, amount):
    """Lighten (+) or darken (-) toward white/black. Keeps a neon hue neon better than a lerp."""
    return mix(hexcol, "#FFFFFF" if amount > 0 else "#000000", abs(amount))


# ── the writer ───────────────────────────────────────────────────────────────

_ORDER = ["Normal", "Hover", "Pressed", "Dragging", "Disabled", "Active"]
_BASE_OF = {"Hover": "Normal", "Pressed": "Hover", "Dragging": "Pressed",
            "Disabled": "Normal", "Active": "Normal"}


def _encode(family, name, value, problems, flat_only=False):
    """Resolve one authored value to (type, string), validating the property exists."""
    rm, flat = FAMILY[family][1], FAMILY[family][2]
    prm, pflat = props(rm), props(flat)

    if flat_only:
        # A skin that names the non-RM shader outright (Flat, Tron): validate against THAT shader.
        info = pflat.get(name)
        if info is None:
            problems.append(f"UNKNOWN {name} — not declared by {flat}")
            return None
    else:
        info = prm.get(name)
        if info is None:
            problems.append(f"UNKNOWN {name} — not declared by {rm}")
            return None
        if name not in pflat and not VIEW_ONLY.match(name):
            problems.append(f"RM-ONLY {name} — {flat} cannot render it (shader parity gap)")

    t = states_type(info)
    if isinstance(value, str) and value.startswith("#"):
        if t not in ("Color", "Vector4"):
            problems.append(f"TYPE {name} is {t} but was given a colour")
        return ("Color" if t == "Color" else "Vector4", rgba(value))
    if isinstance(value, (tuple, list)):
        return ("Vector4", ",".join(f"{float(v):.6g}" for v in value))
    if isinstance(value, bool):
        value = 1 if value else 0
    if t in ("Color", "Vector4"):
        problems.append(f"TYPE {name} is {t} but was given a number")
    return (t if t != "Texture" else "Float", f"{value:.6g}" if isinstance(value, float) else str(value))


def skin(name, family, base, states=None, bounds=None, control_type=None,
         write=True, quiet=False, flat_shader=False, extra=None):
    """
    Emit one `.states.json`.

    `base`   — the Normal state: every property this skin has an opinion about.
    `states` — {"Hover": {...}, "Pressed": {...}, ...} DELTAS only; each inherits per _BASE_OF
               (a state name outside _ORDER, e.g. "Latched", is emitted after them, based on Normal).
    `flat_shader` — name the non-RM shader (UI/SDFKnob, not UI/SDFKnobRM) and validate against it.
    `extra`  — additional top-level keys (e.g. "padColor").
    """
    problems = []
    shader_name = ("UI/" + FAMILY[family][2]) if flat_shader else FAMILY[family][0]

    def params(d):
        out = []
        for k, v in d.items():
            enc = _encode(family, k, v, problems, flat_only=flat_shader)
            if enc:
                out.append({"name": k, "type": enc[0], "value": enc[1]})
        return out

    doc = {
        "controlType": control_type or {"Button": "UIButton", "Knob": "UIKnob",
                                        "Slider": "UISlider", "Toggle": "UIToggle",
                                        "Panel": "UIPanel"}[family],
        "shaderName": shader_name,
        "states": [],
    }

    doc["states"].append({
        "stateId": f"{name}-normal", "stateName": "Normal",
        "description": "Default resting state", "baseStateName": "",
        "priority": 0, "tags": ["default"], "parameters": params(base),
    })
    order = _ORDER[1:] + [s for s in (states or {}) if s not in _ORDER]
    for i, sn in enumerate(order, start=1):
        delta = (states or {}).get(sn)
        if delta is None:
            continue
        doc["states"].append({
            "stateId": f"{name}-{sn.lower()}", "stateName": sn,
            "description": sn, "baseStateName": _BASE_OF.get(sn, "Normal"),
            "priority": i, "tags": [], "parameters": params(delta),
        })

    if bounds:
        doc["bounds"] = bounds
    if extra:
        doc.update(extra)

    if problems and not quiet:
        print(f"  !! {name}:")
        for p in sorted(set(problems)):
            print(f"       {p}")

    if write:
        SKINS.mkdir(parents=True, exist_ok=True)
        (SKINS / f"{name}.states.json").write_text(
            json.dumps(doc, indent=4), encoding="utf-8")
    return doc, problems


def path(name):
    return str((SKINS / f"{name}.states.json").resolve()).replace("\\", "/")
