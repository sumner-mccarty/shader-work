#!/usr/bin/env python3
"""
lookcheck — the gate every new look must pass before it is a PR.

    python Tools/lookcheck.py <Style> [--no-render] [--out Looks/<slug>/check]

Validates Assets/Resources/UiStyles/<Style>.style.json and every skin it rosters, then renders each
rostered part headless (slrender, the app's screen orientation) and writes a contact sheet.

ERRORS (exit 1): anything that breaks or silently degrades the app —
  * recipe missing/unparsable, no modes, missing styleName/title/blurb
  * a mode that does not roster EVERY role, family and by-name swap the app resolves (an
    unrostered slot falls back to a baked RM part — the look leaks another look's hardware)
  * a roster/swap target with no states file; a lights theme that does not exist
  * a skin without "bounds" (hit-test grows to the whole rect — breaks scrolling, see SKILL.md)
  * a parameter the shader does not declare (silently ignored) or a colour in a Float slot
  * a part that fails to compile/render, or renders empty / one flat colour
WARNINGS: no light mode, no Hover/Pressed/Disabled state where one is expected, an empty Disabled,
  an unset _ButtonLipHeight on SDFButtonRM, an unset _LightingShadow1Enabled on a knob.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO))
ASSETS = REPO / "Assets"
RES = ASSETS / "Resources"
SKINS = RES / "MaterialStates"

# The slots a look must fill — mirrors Tools/design_flat.py (ROLE_PART / FAMILY_PART / SWAP_PART),
# which is the complete list the app's SkinResolver consults.
ROLES = ["pad", "button.standard", "button.small", "button.wide", "button.hero", "button.accent", "button.close",
         "toggle.button", "toggle.pill", "lamp", "knob.hero", "knob.large", "knob.medium", "knob.small",
         "slider.long", "slider.standard", "panel.faceplate", "panel.inset", "panel.socket", "display.well",
         "panel.backplane"]
FAMILIES = ["Button", "Knob", "Slider", "Toggle", "Panel"]
SWAPS = ["GreyButtonRM", "AccentButtonRM", "MuteToggleRM", "SoloToggleRM", "EnableLampRM", "CloseButtonRM",
         "LearnChipRM", "RackDot", "RackScrollHandle", "RedKnobRM", "RackSlider", "RackGutterFader",
         "UI_SDFTogglePill", "MidiLearnPill", "LedWellBlue", "RackPlateInset", "PadSocket", "PadWell",
         "RackBackplane", "RackFaceplateGraphite", "RackFaceplateSilver", "RackFaceplateBlue",
         "RackFaceplateRust", "RackFaceplateGreen", "RackFaceplateCream", "DisplayBezel", "RackScrollTrack"]

# nominal render size per shader family (w, h) and the value sweep worth seeing
SIZES = {"SDFKnob": (72, 72), "SDFButton": (110, 56), "SDFSlider": (56, 200), "SDFTogglePill": (80, 40),
         "SDFPanel": (260, 140)}


def strip_jsonc(text: str) -> str:
    out, i, n, in_str = [], 0, len(text), False
    while i < n:
        c = text[i]
        if in_str:
            out.append(c)
            if c == "\\" and i + 1 < n:
                out.append(text[i + 1]); i += 2; continue
            if c == '"':
                in_str = False
            i += 1; continue
        if c == '"':
            in_str = True; out.append(c); i += 1; continue
        if text.startswith("//", i):
            j = text.find("\n", i); i = n if j < 0 else j; continue
        if text.startswith("/*", i):
            j = text.find("*/", i + 2); i = n if j < 0 else j + 2; continue
        out.append(c); i += 1
    return re.sub(r",\s*([}\]])", r"\1", "".join(out))


def load_recipe(style: str):
    f = RES / "UiStyles" / f"{style}.style.json"
    if not f.exists():
        return None, f"no recipe at {f.relative_to(REPO)}"
    try:
        return json.loads(strip_jsonc(f.read_text(encoding="utf-8-sig"))), None
    except ValueError as e:
        return None, f"recipe does not parse: {e}"


def target_of(v):
    if isinstance(v, str):
        return v
    if isinstance(v, dict):
        return v.get("$base")
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("style")
    ap.add_argument("--no-render", action="store_true")
    ap.add_argument("--out", type=Path)
    a = ap.parse_args()

    errors, warns = [], []
    recipe, err = load_recipe(a.style)
    if err:
        print("ERROR", err)
        return 1
    for k in ("styleName", "title", "blurb", "modes"):
        if k not in recipe:
            errors.append(f"recipe lacks '{k}'")
    modes = recipe.get("modes") or {}
    if not modes:
        errors.append("recipe has no modes")
    if "light" not in modes or "dark" not in modes:
        warns.append(f"modes are {sorted(modes)} — a complete look ships dark AND light")

    skins = set()
    for mname, m in modes.items():
        roles, fams, swaps = m.get("roles") or {}, m.get("families") or {}, m.get("swaps") or {}
        for r in ROLES:
            if not target_of(roles.get(r)):
                errors.append(f"[{mname}] role '{r}' not rostered to an authored skin")
        for f in FAMILIES:
            if not target_of(fams.get(f)):
                errors.append(f"[{mname}] family '{f}' not rostered")
        for s in SWAPS:
            if not target_of(swaps.get(s)):
                errors.append(f"[{mname}] swap '{s}' missing (that by-name skin would keep another look's finish)")
        for block in (roles, fams, swaps):
            for k, v in block.items():
                t = target_of(v)
                if t:
                    skins.add(t)
        lights = m.get("lights")
        if lights and not (RES / f"{lights}.json").exists():
            errors.append(f"[{mname}] lights '{lights}' has no Assets/Resources/{lights}.json")
        if not m.get("palettes"):
            warns.append(f"[{mname}] no palettes block (text/ink/display colours fall back to defaults)")
        if not (m.get("displays") or {}).get("*"):
            warns.append(f"[{mname}] displays has no '*' entry (screens keep their authored hardware finish)")

    from slrender import shaderlab
    roots = [ASSETS / "Shaders"]
    shader_cache = {}
    renderable = []
    for name in sorted(skins):
        f = SKINS / f"{name}.states.json"
        if not f.exists():
            errors.append(f"skin '{name}' has no file {f.relative_to(REPO)}")
            continue
        try:
            doc = json.loads(f.read_text(encoding="utf-8-sig"))
        except ValueError as e:
            errors.append(f"{name}: does not parse ({e})")
            continue
        if not doc.get("bounds"):
            errors.append(f"{name}: no 'bounds' (hit-test becomes the whole rect)")
        sname = doc.get("shaderName")
        try:
            sh = shader_cache.get(sname) or shaderlab.parse(shaderlab.find_shader(sname, roots))
            shader_cache[sname] = sh
        except Exception as e:
            errors.append(f"{name}: shader '{sname}' not found ({e})")
            continue
        states = {s.get("stateName"): s for s in doc.get("states") or []}
        for s in states.values():
            for p in s.get("parameters") or []:
                pn, pt, pv = p.get("name"), (p.get("type") or ""), str(p.get("value", ""))
                prop = sh.properties.get(pn)
                if prop is None:
                    errors.append(f"{name}/{s.get('stateName')}: '{pn}' is not a property of {sname}")
                elif prop.kind in ("float", "range", "int") and ("," in pv or pv.startswith("#")):
                    errors.append(f"{name}/{s.get('stateName')}: '{pn}' is a {prop.kind} but got '{pv}'")
        normal = next((s for s in states.values() if not s.get("baseStateName")), None)
        set_names = {p.get("name") for p in (normal or {}).get("parameters") or []}
        if "Button" in sname or "Knob" in sname or "Slider" in sname or "Pill" in sname:
            for want in ("Hover", "Pressed", "Disabled"):
                if want not in states:
                    warns.append(f"{name}: no '{want}' state")
            if "Disabled" in states and not states["Disabled"].get("parameters"):
                warns.append(f"{name}: 'Disabled' is empty (a disabled control will look enabled)")
        if sname == "UI/SDFButtonRM" and "_ButtonLipHeight" not in set_names:
            warns.append(f"{name}: _ButtonLipHeight unset (default 0.08 draws a dotted lip seam)")
        if "Knob" in sname and "_LightingShadow1Enabled" not in set_names:
            warns.append(f"{name}: _LightingShadow1Enabled unset (defaults ON on knobs: dark arc over the track)")
        renderable.append((name, sname))

    if not a.no_render and renderable:
        import numpy as np
        from slrender.skins import SkinRenderer
        from slrender import to_image
        slug_dir = next((mf.parent for mf in sorted((REPO / "Looks").glob("*/look.json"))
                         if json.loads(mf.read_text(encoding="utf-8")).get("style") == a.style),
                        REPO / "Looks" / a.style.lower())
        out = a.out or (slug_dir / "check")
        out.mkdir(parents=True, exist_ok=True)
        sr = SkinRenderer(REPO)
        for name, sname in renderable:
            fam = next((k for k in SIZES if k in sname), "SDFButton")
            w, h = SIZES[fam]
            cell = {"states": name, "w": w, "h": h, "bg": "#202226",
                    "set": {"_Value": 0.6} if fam in ("SDFKnob", "SDFSlider", "SDFTogglePill") else {}}
            try:
                img = sr.render_cell(cell)
            except Exception as e:
                errors.append(f"{name}: render failed — {type(e).__name__}: {str(e)[:400]}")
                continue
            rgb = img[..., :3].astype(np.int16)
            if img[..., 3].max() == 0 or (rgb.max(axis=(0, 1)) - rgb.min(axis=(0, 1))).max() < 3:
                errors.append(f"{name}: renders empty or one flat colour")
            to_image(img).save(out / f"{name}.png")
        import subprocess
        subprocess.run([sys.executable, "-m", "slrender", "contact", str(out / "*.png"),
                        "-o", str(out.parent / "check_parts.png")], cwd=REPO, capture_output=True)

    for w in warns:
        print("warn ", w)
    for e in errors:
        print("ERROR", e)
    print(f"{a.style}: {len(skins)} skins, {len(errors)} error(s), {len(warns)} warning(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
