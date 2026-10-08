#!/usr/bin/env python3
"""
Write the shipped GENERIC background fields: Assets/Resources/MaterialStates/Field<Type>.states.json.

A layout window (`"fill": {"field": "plasma"}`, see Assets/UiPipeline/BackdropFill.cs) resolves a field name in
order: "wallpaper" → a role the active look maps (recipe mode "fields") → a states file by that name → the generic
`Field<Type>` written here. So every Backdrop* shader is usable from any layout with no look support, and a look
that wants its own version of a role maps it in its spec (`modes[mode]["fields"]`, Tools/lookkit.py).

Each preset is just a Backdrop* shader plus the parameters that differ from its own Properties defaults, validated
against the shader (name, type, range) by lookkit.fx_skin.

    python Tools/gen_fields.py            # write all
    python Tools/gen_fields.py --check    # validate only
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from lookkit import ROOT, fx_skin  # noqa: E402

# Generic fields sit BEHIND content, so they are a touch calmer than a hero wallpaper: a 20–30 s loop and the
# shaders' own (deliberately moody) default palettes.
PRESETS = {
    "Caustics":  {"_Speed": 0.05},
    "Splotch":   {"_Speed": 0.04, "_Softness": 0.5},
    "Ribbons":   {"_Speed": 0.04},
    "Plasma":    {"_Speed": 0.04},
    "Bokeh":     {"_Speed": 0.035},
    "Grid":      {"_Speed": 0.05},
    "Contours":  {"_Speed": 0.03},
    "Starfield": {"_Speed": 0.03},
}


def main(check_only: bool) -> int:
    errors = 0
    for shader, params in PRESETS.items():
        name = f"Field{shader}"
        doc, problems = fx_skin(name, {"shader": shader, "params": params}, "gen_fields.py")
        for p in problems:
            print(f"  ✗ {name}: {p}")
        errors += len(problems)
        if not check_only and not problems:
            out = ROOT / "Assets" / "Resources" / "MaterialStates" / f"{name}.states.json"
            out.write_text(json.dumps(doc, indent=4) + "\n", encoding="utf-8")
            print(f"  wrote {out.relative_to(ROOT).as_posix()}")
    print(f"{len(PRESETS)} fields, {errors} problem(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main("--check" in sys.argv))
