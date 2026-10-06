#!/usr/bin/env python3
"""
Parse a Unity .shader's Properties block into the authoritative property table.

The point of reading the shader rather than trusting a doc: a skin that names a property the
shader does not declare is silently ignored (Material.HasProperty fails), and one that gets the
TYPE wrong writes a float into a colour. Both failures look like "the value did nothing", which
is the most expensive kind of bug to chase by eye. Everything the authoring layer emits is
validated against this table first.
"""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SHADERS = ROOT / "Assets" / "Shaders"

# _Name ("Display", Type) = default        — Type may be Range(a, b) or carry [Attributes]
_PROP = re.compile(
    r'^\s*(?:\[[^\]]*\]\s*)*'          # [Enum(...)] [Toggle] ...
    r'(_\w+)\s*\(\s*"([^"]*)"\s*,\s*'  # _Name ("Display",
    r'([A-Za-z0-9]+)\s*(\(([^)]*)\))?' # Type  or Range(0, 5)
    r'\s*\)\s*=\s*(.+?)\s*$',
    re.MULTILINE,
)


def properties(shader_name: str) -> dict:
    """{ '_Name': {'type','range','default','display'} } for a shader file stem."""
    path = SHADERS / f"{shader_name}.shader"
    text = path.read_text(encoding="utf-8", errors="replace")

    start = text.index("Properties")
    depth, i = 0, text.index("{", start)
    for j in range(i, len(text)):
        if text[j] == "{":
            depth += 1
        elif text[j] == "}":
            depth -= 1
            if depth == 0:
                block = text[i + 1:j]
                break

    out = {}
    for m in _PROP.finditer(block):
        name, display, typ, _, args, default = m.groups()
        rng = None
        if typ.lower() == "range" and args:
            rng = tuple(float(x) for x in args.split(","))
        out[name] = {
            "type": typ,
            "range": rng,
            "default": default.strip(),
            "display": display,
        }
    return out


# Which states.json "type" string a shader type maps to. Range and Float are both floats to the
# engine; the distinction is kept because the Designer draws a slider for Range.
def states_type(info) -> str:
    t = info["type"].lower()
    if t == "color":
        return "Color"
    if t == "vector":
        return "Vector4"
    if t == "range":
        return "Range"
    if t in ("2d", "cube", "3d", "2darray"):
        return "Texture"
    return "Float"


if __name__ == "__main__":
    import sys

    for s in sys.argv[1:] or ["SDFKnobRM", "SDFButtonRM", "SDFSliderRM", "SDFPanel", "SDFTogglePill"]:
        p = properties(s)
        print(f"\n===== {s}  ({len(p)} properties) =====")
        for k, v in p.items():
            r = f"{v['range']}" if v["range"] else ""
            print(f"  {k:44s} {v['type']:8s} {r:14s} = {v['default']}")
