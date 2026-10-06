import sys; sys.path.insert(0, r"D:\repos\audiogame\Tools")
from skinsheet import render, sheet, skin_path

# The app as it ships = Realistic Dark. Baseline to beat.
PARTS = [
    ("pad",            "GreyButtonRM",          96, 96),
    ("button.standard","GreyButtonRM",          88, 76),
    ("button.small",   "GreyButtonRM",          72, 52),
    ("button.wide",    "GreyButtonRM",         132, 56),
    ("button.accent",  "AccentButtonRM",        88, 62),
    ("button.hero",    "AccentButtonRM",       150, 96),
    ("toggle.button",  "MuteToggleRM",          88, 76),
    ("button.close",   "CloseButtonRM",         76, 62),
    ("lamp",           "EnableLampRM",          48, 48),
    ("knob.hero",      "RedKnobRM",            148,148),
    ("knob.medium",    "RedKnobRM",             88, 88),
    ("knob.small",     "RedKnobRM",             72, 72),
    ("slider.long",    "TesterSDFSlider",      240, 56),
    ("toggle.pill",    "UI_SDFTogglePill",      96, 48),
    ("panel.faceplate","RackFaceplateGraphite",240,128),
    ("panel.inset",    "RackPlateInset",       200, 96),
    ("display.well",   "LedWellBlue",          200, 60),
    ("panel.backplane","RackBackplane",        240,110),
]

cells, rows = [], []
BG = "#0E1013"
for role, skin, w, h in PARTS:
    vals = [0.0, 0.4, 0.8] if ("knob" in role or "slider" in role) else [0.65]
    rc = []
    for v in vals:
        cid = f"base-{role}-{v}"
        cells.append({"id": cid, "states": skin_path(skin), "w": w, "h": h,
                      "state": "Normal", "set": {"_Value": v}, "bg": BG, "ss": 2})
        rc.append({"id": cid, "caption": (f"{v:.0%}" if len(vals) > 1 else skin)})
    rows.append({"label": role, "cells": rc})

render(cells)
sheet(rows, r"D:\repos\audiogame\.skinsheet\baseline-realistic-dark.png",
      title="BASELINE — Realistic Dark (the app as it ships)", bg=BG)
