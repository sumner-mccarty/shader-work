#!/usr/bin/env python3
"""
A faithful Python port of SkinForge.Apply / Bake (Assets/UiPipeline/SkinForge.cs).

Two jobs. First, it lets the render loop SEE a light mode without going through Unity — a recipe
edit becomes a picture in about a second instead of a domain reload. Second, it is an independent
implementation of the same rules, so if the C# and this ever disagree about what a recipe means,
one of them has a bug and the disagreement is visible rather than silent.

Rules mirrored exactly:
  * overrides land on the BASE state;
  * a derived state follows the recipe ONLY for properties it already had an opinion about
    (otherwise Hover stops being a delta), and its value is re-derived through `stateShifts`
    as an HSV VALUE shift, not a lerp — that keeps a neon hue neon;
  * "$slot" / "$slot@alpha" resolve from the mode's colours, "#RRGGBB[AA]" is a literal;
  * a property's TYPE comes from whatever the base file already declared.
"""
from __future__ import annotations

import colorsys
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKINS = ROOT / "Assets" / "Resources" / "MaterialStates"
STYLES = ROOT / "Assets" / "Resources" / "UiStyles"
BAKED = ROOT / ".skinsheet" / "baked"

ROLES = [
    ("pad", "Button"), ("button.standard", "Button"), ("button.small", "Button"),
    ("button.wide", "Button"), ("button.accent", "Button"), ("button.hero", "Button"),
    ("toggle.button", "Button"), ("button.close", "Button"), ("lamp", "Button"),
    ("knob.hero", "Knob"), ("knob.large", "Knob"), ("knob.medium", "Knob"),
    ("knob.small", "Knob"), ("slider.long", "Slider"), ("slider.standard", "Slider"),
    ("toggle.pill", "Toggle"), ("panel.faceplate", "Panel"), ("panel.inset", "Panel"),
    ("display.well", "Panel"), ("panel.backplane", "Panel"),
]

_COMMENT = re.compile(r'^\s*//.*$', re.MULTILINE)


def load_style(style):
    text = (STYLES / f"{style}.style.json").read_text(encoding="utf-8")
    return json.loads(_COMMENT.sub("", text))


# ── value grammar ────────────────────────────────────────────────────────────

def _unhex(h):
    s = h.lstrip("#")
    if len(s) == 6:
        s += "ff"
    return [int(s[i:i + 2], 16) / 255.0 for i in (0, 2, 4, 6)]


def _shift(rgba, amount):
    """Move toward white/black in HSV VALUE — SkinForge.Shift, not a lerp."""
    r, g, b, a = rgba
    h, s, v = colorsys.rgb_to_hsv(r, g, b)
    r2, g2, b2 = colorsys.hsv_to_rgb(h, s, max(0.0, min(1.0, v + amount)))
    return [r2, g2, b2, a]


def encode(value, colors, declared_type, lighten):
    if isinstance(value, bool):
        return declared_type or "Float", "1" if value else "0"
    if isinstance(value, (int, float)):
        return declared_type or "Float", f"{value:.6g}"
    if isinstance(value, list):
        return declared_type or "Vector4", ",".join(f"{float(v):.6g}" for v in value)
    if not isinstance(value, str) or not value:
        return None

    if value[0] == "$":
        slot, alpha = value[1:], None
        if "@" in slot:
            slot, a = slot.split("@", 1)
            alpha = float(a)
        if slot not in colors:
            return None
        c = _unhex(colors[slot])
        if alpha is not None:
            c[3] = alpha
        if abs(lighten) > 1e-4:
            c = _shift(c, lighten)
        t = "Vector4" if declared_type == "Vector4" else "Color"
        return t, ",".join(f"{v:.6g}" for v in c)

    if value[0] == "#":
        c = _unhex(value)
        if abs(lighten) > 1e-4:
            c = _shift(c, lighten)
        t = "Vector4" if declared_type == "Vector4" else "Color"
        return t, ",".join(f"{v:.6g}" for v in c)

    if "," in value:
        return declared_type or "Vector4", value
    return declared_type or "Float", value


# ── the bake ─────────────────────────────────────────────────────────────────

def apply(base_doc, overrides, colors, shifts):
    doc = json.loads(json.dumps(base_doc))
    states = doc.get("states") or []
    if not states:
        return None

    declared = {}
    for st in states:
        for p in st.get("parameters", []):
            declared.setdefault(p["name"], p.get("type"))

    for st in states:
        params = st.setdefault("parameters", [])
        is_base = not st.get("baseStateName")
        lighten = float(shifts.get(st.get("stateName", ""), 0.0) or 0.0)
        index = {p["name"]: i for i, p in enumerate(params)}

        for k, v in overrides.items():
            at = index.get(k, -1)
            if not is_base and at < 0:
                continue                      # a delta stays a delta
            enc = encode(v, colors, declared.get(k), 0.0 if is_base else lighten)
            if enc is None:
                continue
            t, s = enc
            if at >= 0:
                params[at]["value"] = s
                if t:
                    params[at]["type"] = t
            else:
                params.append({"name": k, "type": t or "Float", "value": s})
    doc["author"] = "SkinForge"
    return doc


def bake(style, mode, out_dir=None):
    """Bake one look. Returns {role: skin-name}; writes any baked file to `out_dir`."""
    doc = load_style(style)
    m = doc["modes"][mode]
    colors = m.get("colors", {})
    shifts = doc.get("stateShifts", {})
    fam, rol = doc.get("families", {}), doc.get("roles", {})
    mfam, mrol = m.get("families", {}), m.get("roles", {})

    out_dir = Path(out_dir or BAKED)
    out_dir.mkdir(parents=True, exist_ok=True)
    prefix = (style + ("Light" if mode == "light" else "Dark"))

    roster = {}
    for role, family in ROLES:
        ov = {}
        for src, key in ((fam, family), (mfam, family), (rol, role), (mrol, role)):
            ov.update((src or {}).get(key, {}))
        base_skin = ov.pop("$base", None)
        if base_skin == "$inherit":
            continue    # leave this role out of the roster — see SkinForge.IsInherit
        if not base_skin:
            continue
        if not ov:
            roster[role] = base_skin           # nothing to say: roster the authored file
            continue
        src = SKINS / f"{base_skin}.states.json"
        if not src.exists():
            print(f"  ! {style}/{mode}: missing base {base_skin}")
            continue
        baked = apply(json.loads(src.read_text(encoding="utf-8")), ov, colors, shifts)
        name = f"{prefix}.{role.replace('.', '-')}"
        (out_dir / f"{name}.states.json").write_text(json.dumps(baked, indent=4), encoding="utf-8")
        roster[role] = name

    # "swaps": authored skin -> replacement (SkinForge swaps / UiThemeManifest.swaps).
    for key, val in (m.get("swaps") or {}).items():
        if isinstance(val, str):
            if val:
                roster["swap:" + key] = val
            continue
        ov = dict(val)
        base_skin = ov.pop("$base", None) or key
        src = SKINS / f"{base_skin}.states.json"
        if not src.exists():
            print(f"  ! {style}/{mode}: missing swap base {base_skin}")
            continue
        baked = apply(json.loads(src.read_text(encoding="utf-8")), ov, colors, shifts)
        name = f"{prefix}.swap-{key}"
        (out_dir / f"{name}.states.json").write_text(json.dumps(baked, indent=4), encoding="utf-8")
        roster["swap:" + key] = name

    # "displays": authored display finish -> this look's finish (UiThemeManifest.displays).
    for key, val in (m.get("displays") or {}).items():
        if isinstance(val, str) and val:
            roster["display:" + key] = val
    return roster


if __name__ == "__main__":
    import sys
    for style in sys.argv[1:] or ["Realistic", "Neomorphic", "Tron", "Flat"]:
        for mode in ("dark", "light"):
            r = bake(style, mode)
            baked = sum(1 for k, v in r.items() if "." in v and not k.startswith("display:"))
            print(f"  {style:11s} {mode:5s}  {len(r)} roles, {baked} baked, "
                  f"{len(r)-baked} rostered as authored")
