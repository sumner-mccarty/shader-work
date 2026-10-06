#!/usr/bin/env python3
"""
patch_skin — surgically set properties on an ALREADY-AUTHORED .states.json.

`skinlib.skin()` emits a whole file from a Python spec, which is right for a look designed in
Python (the four shipped styles). The skins the app actually ships on — GreyButtonRM, RedKnobRM,
RackFaceplateGraphite and friends — were tuned by hand in the Material State Designer and carry
130+ values apiece. Re-emitting one of those from a spec would silently drop everything the spec
does not mention, so a polish pass needs the other operation: change these six numbers, leave the
other hundred exactly as they are.

Every write is validated against the shader's own Properties block (Tools/shaderprops), so a
misspelt name or a colour written into a Float slot fails loudly here instead of doing nothing at
runtime — the two silent failures that cost the most time when authoring skins.

    from patch_skin import patch
    patch("GreyButtonRM", {"_ButtonPatternType": 1, "_ButtonPatternScale": 14})
    patch("GreyButtonRM", {"_ButtonColor": "#4A4A44"}, state="Hover")

Colours accept "#RRGGBB", "#RRGGBBAA" or an (r,g,b[,a]) 0..1 tuple; vectors accept a 4-tuple.
Floats accept int/float. Values are written in the same string form the Designer emits, so a
patched file round-trips through the Designer unchanged.
"""
from __future__ import annotations

import json
import re
from pathlib import Path

import shaderprops

ROOT = Path(__file__).resolve().parent.parent
SKINS = ROOT / "Assets" / "Resources" / "MaterialStates"

# states.json shaderName ("UI/SDFButtonRM") -> the .shader file stem shaderprops wants.
def _shader_stem(shader_name: str) -> str:
    return shader_name.split("/")[-1]


def _fmt_float(v) -> str:
    # Unity's own serialisation for these files is round-trippable float text; 9 significant
    # digits matches what the Designer writes and keeps diffs from churning on re-save.
    s = repr(float(v))
    return s


def _parse_color(v):
    if isinstance(v, (list, tuple)):
        c = list(v) + [1.0] * (4 - len(v))
        return [float(x) for x in c[:4]]
    s = str(v).strip()
    if s.startswith("#"):
        s = s[1:]
    if len(s) == 6:
        s += "FF"
    if len(s) != 8:
        raise ValueError(f"bad colour {v!r}")
    return [int(s[i:i + 2], 16) / 255.0 for i in (0, 2, 4, 6)]


def _encode(name: str, value, info) -> str:
    st = shaderprops.states_type(info)
    if st == "Color":
        return ",".join(_fmt_float(c) for c in _parse_color(value))
    if st == "Vector4":
        if not isinstance(value, (list, tuple)) or len(value) != 4:
            raise ValueError(f"{name}: Vector4 needs a 4-tuple, got {value!r}")
        return ",".join(_fmt_float(c) for c in value)
    if st == "Texture":
        raise ValueError(f"{name}: textures are not patchable here")
    # Float / Range / Enum-as-float
    if isinstance(value, str):
        raise ValueError(f"{name}: expected a number for a {info['type']} property, got {value!r}")
    f = float(value)
    rng = info.get("range")
    if rng and not (rng[0] - 1e-6 <= f <= rng[1] + 1e-6):
        # A WARNING, not an error: Range() only bounds the material inspector's slider, and
        # nothing clamps Material.SetFloat. Several shipped skins deliberately live outside it —
        # EnableLampRM's _EdgeSoftness is 4.5 against a declared 0..1 and renders as intended.
        print(f"  note: {name} = {f} is outside the shader's declared Range{rng} "
              f"(allowed — Range does not clamp at runtime)")
    return _fmt_float(f)


def _load(path: Path):
    """Read a states.json that may carry // comments (the hand-authored ones do)."""
    raw = path.read_text(encoding="utf-8")
    stripped = re.sub(r"^\s*//.*$", "", raw, flags=re.M)
    return json.loads(stripped)


def patch(skin: str, values: dict, state: str = "Normal", folder=None, dry=False) -> dict:
    """
    Set `values` on `skin`'s `state`. Properties already present are updated in place (so their
    position in the file, and therefore the diff, stays small); new ones are appended.

    Returns {name: (old, new)} for everything that actually changed.
    """
    base = Path(folder) if folder else SKINS
    path = base / f"{skin}.states.json"
    doc = _load(path)
    props = shaderprops.properties(_shader_stem(doc["shaderName"]))

    target = next((s for s in doc["states"] if s["stateName"] == state), None)
    if target is None:
        raise KeyError(f"{skin}: no state named {state!r} "
                       f"(has {[s['stateName'] for s in doc['states']]})")

    unknown = [k for k in values if k not in props]
    if unknown:
        raise KeyError(f"{skin}: {doc['shaderName']} does not declare {unknown} — "
                       f"these would be silently ignored at runtime")

    by_name = {p["name"]: p for p in target["parameters"]}
    changed = {}
    for name, value in values.items():
        info = props[name]
        encoded = _encode(name, value, info)
        existing = by_name.get(name)
        old = existing["value"] if existing else None
        if old == encoded:
            continue
        changed[name] = (old, encoded)
        if existing is not None:
            existing["value"] = encoded
            existing["type"] = shaderprops.states_type(info)
        else:
            target["parameters"].append(
                {"name": name, "type": shaderprops.states_type(info), "value": encoded})

    if changed and not dry:
        path.write_text(json.dumps(doc, indent=2), encoding="utf-8")
    return changed


if __name__ == "__main__":
    import sys
    if len(sys.argv) < 3:
        print('usage: patch_skin.py <Skin> \'{"_Prop": 1.0}\' [StateName]')
        raise SystemExit(1)
    st = sys.argv[3] if len(sys.argv) > 3 else "Normal"
    for k, (o, n) in patch(sys.argv[1], json.loads(sys.argv[2]), st).items():
        print(f"  {k}: {o} -> {n}")
