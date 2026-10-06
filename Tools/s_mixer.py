#!/usr/bin/env python3
"""
s_mixer — contact sheet of every mixer display in its ENGAGED / IDLE / BYPASSED reading.

Three columns per module answer the question the displays exist to answer at a glance:
  bypassed  — module switched out: the picture must read as OFF (subdued, no hue, no motion)
  idle      — in circuit but mix at zero and no audio: present, still, but not lit
  live      — engaged and audio flowing: hue and light come up, ripples travel the lines
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from scopesheet import MIXER_DISPLAYS, cell           # noqa: E402
from skinsheet import render, sheet                    # noqa: E402

BG = "#14171B"
OUT = Path(__file__).resolve().parent.parent / ".skinsheet"

COLS = [
    # Audio IS playing, but the module is switched out: subdued AND still.
    ("bypassed+audio", {"_Engaged": 0.0, "_Activity": 0.85, "_Phase": 0.0, "_Playhead": -1}),
    # In circuit and turned up, nothing sounding: full hue, no motion.
    ("engaged, silent", {"_Engaged": 1.0, "_Activity": 0.0, "_Phase": 0.0, "_Playhead": -1}),
    # In circuit with signal passing: the ripple runs the lines.
    ("engaged+audio", {"_Engaged": 1.0, "_Activity": 0.85, "_Phase": 0.30, "_Playhead": 0.45}),
    # Half wet — the in-between reading has to be legible too, not a binary.
    ("mix 40%", {"_Engaged": 0.4, "_Activity": 0.85, "_Phase": 0.55, "_Playhead": 0.62}),
]


def main(tag="mixer-displays"):
    cells, rows = [], []
    for name, size, props in MIXER_DISPLAYS:
        rc = []
        for cap, extra in COLS:
            cid = f"sc-{name}-{cap}"
            cells.append(cell(name, size, props, cid, extra=extra, bg=BG))
            rc.append({"id": cid, "caption": cap})
        rows.append({"label": name, "cells": rc})
    render(cells)
    sheet(rows, str(OUT / f"{tag}.png"), title="MIXER DISPLAYS — bypassed / engaged / live / half-wet", bg=BG)


if __name__ == "__main__":
    main(*sys.argv[1:])
