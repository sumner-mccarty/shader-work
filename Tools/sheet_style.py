#!/usr/bin/env python3
"""Render one style's whole part set at the sizes the parts are really used at."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from skinsheet import render, sheet
from skinlib import path

# role, skin suffix, w, h, extra per-cell overrides
PARTS = [
    ("knob.hero",       "KnobHero",  132, 132, "val"),
    ("knob.medium",     "Knob",       88,  88, "val"),
    ("knob.small",      "KnobSmall",  60,  60, "val"),
    ("slider.long",     "Slider",    240,  56, "val"),
    ("pad",             "Pad",        96,  96, None),
    ("button.standard", "Button",     88,  76, "states"),
    ("button.small",    "Button",     72,  40, None),
    ("button.accent",   "Accent",     88,  62, None),
    ("toggle.button",   "ToggleBtn",  88,  76, "active"),
    ("button.close",    "Close",      56,  48, None),
    ("lamp",            "Lamp",       36,  36, "active"),
    ("toggle.pill",     "Pill",       96,  44, "onoff"),
    ("panel.faceplate", "Face",      260, 120, None),
    ("panel.inset",     "Inset",     200,  90, None),
    ("display.well",    "Well",      200,  56, None),
    ("panel.backplane", "Back",      240, 100, None),
]


def build(style, bg, out, title):
    cells, rows = [], []
    for role, suffix, w, h, mode in PARTS:
        skinname = style + suffix
        rc = []

        def add(cid, caption, **kw):
            # Panels are the surface everything else sits ON — they do not cast into the scene,
            # and rendering their own shadow pass just draws a second silhouette behind them.
            cell = {"id": cid, "states": path(skinname), "w": w, "h": h,
                    "bg": bg, "ss": 2}
            if not role.startswith(("panel.", "display.")):
                cell["shadow"] = 2
            cell.update(kw)
            cells.append(cell)
            rc.append({"id": cid, "caption": caption})

        key = f"{style}-{role}".replace(".", "_")
        if mode == "val":
            for v in (0.0, 0.4, 0.8, 1.0):
                add(f"{key}-{v}", f"{v:.0%}", set={"_Value": v})
        elif mode == "onoff":
            add(f"{key}-off", "off", set={"_Value": 0.0})
            add(f"{key}-on", "on", set={"_Value": 1.0})
        elif mode == "active":
            add(f"{key}-n", "normal")
            add(f"{key}-a", "ACTIVE", state="Active")
        elif mode == "states":
            for st in ("Normal", "Hover", "Pressed", "Disabled"):
                add(f"{key}-{st}", st, state=st)
        else:
            add(key, skinname)
        rows.append({"label": role, "cells": rc})

    render(cells)
    return sheet(rows, out, title=title, bg=bg)


if __name__ == "__main__":
    style = sys.argv[1] if len(sys.argv) > 1 else "Realistic"
    bg = sys.argv[2] if len(sys.argv) > 2 else "#1A1D22"
    build(style, bg,
          rf"D:\repos\audiogame\.skinsheet\set-{style}.png",
          f"{style.upper()} — full part set, real sizes, real shadow pass")
