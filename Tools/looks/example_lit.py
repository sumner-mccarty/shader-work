"""Lit Example — a TEMPLATE for the kit's `lit` class, not a look. Copy it to start a lit look.

    python Tools/looks/example_lit.py check
    python Tools/looks/example_lit.py sheet [dark|light] --out <dir>     # renders; never writes Assets
    python Tools/looks/example_lit.py write --root <scratch dir>          # `write` needs --root (status "example")

Anodised graphite hardware under one warm key lamp: brushed, pixel-locked plates; domed keys with a
milled chamfer; fluted knob skirts with a radial-brushed cap and an amber dot; amber for ON.
Light mode changes the CHASSIS (pale brushed aluminium, low ambient so it doesn't clip), never the
controls — dark keys on light metal is how daylight hardware is built.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from lookkit import Look, main  # noqa: E402

CONTROLS = dict(           # identical in both modes: the hardware doesn't change, the room does
    BODY="#3D434B", MARK="#D9DEE4", MARK_DIM="#8E979F", ON_MARK="#1A1206",
    ACCENT="#E8873A", SOLO="#4AA3D8", LAMP="#F2B14A", HOT="#E2553F",
    CAP="#454B53", NUB="#F09A4A", VALUE="#F09A4A", VALUE_EM=0.25, HANDLE="#454B53",
    PAD_BODY="#2E3338", PAD_TINT=0.55, SCROLL="#3A4047", SCROLL_HI="#5A636C",
)

LOOK = Look(
    title="Lit Example", style="LitExample", prefix="LitExample", slug="lit-example", cls="lit", order=90,
    status="example",
    blurb="Anodised graphite hardware under one warm lamp - the lookkit lit-class template.",
    displays="neo",
    shape={
        "key": dict(corner=0.45, round=0.4, bevel=0.14, depth=0.5, smooth=0.5, dome=0.3),
        "dial": dict(skirt="Fluted", skirt_count=18, skirt_depth=0.12, cap_r=0.6, bevel=0.16, depth=0.45, dome=0.4),
        "shadow": dict(blur=1.4, cast=0.22),
    },
    material={
        # brushed metal wants Param1 0.5 (else mottled noise) and is pixel-locked (Px) so a strip and a
        # rack wear the same grain
        "plate": dict(pattern="Metal", scale=160, px=160, intensity=0.1, contrast=1.0, spec=0.5, rough=0.35,
                      p1=0.5, p2=0.0, p3=0.0),
        "cap": dict(pattern="RadialBrushed", scale=24, intensity=0.12, p1=0.45, p2=0.2),
    },
    rig={
        "dark": {"light1": dict(pos=[-0.4, 1.5], height=1.3, color="#FFF1DE", intensity=0.85, specular=0.3,
                                specularPower=36),
                 "light2": dict(pos=[1.3, 0.6], height=0.9, color="#DDE8FF", intensity=0.25, specular=0.08),
                 "light3": dict(enabled=False)},
        # pale chassis: ONE far, high key (fill/bounce off) — the calibration that keeps pale plates
        # from clipping
        "light": {"light1": dict(pos=[-1.5, 3.0], height=4.0, color="#FFFFFF", intensity=0.8, specular=0.12,
                                 specularPower=40),
                  "light2": dict(enabled=False), "light3": dict(enabled=False)},
    },
    modes={
        "dark": dict(
            track="Nebula", blurb="Graphite hardware, one warm lamp.",
            palette=dict(CONTROLS, GAP="#0B0D10", BACK="#15181C", FACE="#22262B", INSET="#1A1D21", WELL="#0A1316",
                         ARC_OFF="#1C2025", TRACK="#121518", SHADOW="#000000", SHADOW_A=0.55,
                         AMB=0.62, AMB_PLATE=0.55, PLATE_LO=0.1, PLATE_HI=0.1, WELL_EM=0.1),
            app=dict(display=dict(text="#F7B26B", textDim="#8A6A48"))),
        "light": dict(
            track="Rosewater", blurb="The same hardware on brushed aluminium.",
            palette=dict(CONTROLS, GAP="#8F959B", BACK="#AEB3B9", FACE="#C8CCD1", INSET="#BABFC5", WELL="#0E171A",
                         ARC_OFF="#2A2F35", TRACK="#2A2F35", MARK_DIM="#8E979F", SHADOW="#3A4048", SHADOW_A=0.35,
                         # calibrated on slrender: the far key adds little, so the pale plate's
                         # level is set by its ambient; the controls keep the dark mode's
                         AMB=0.62, AMB_PLATE=1.0, PLATE_LO=0.06, PLATE_HI=0.05, WELL_EM=0.1),
            material=dict(plate=dict(intensity=0.06)),       # pale brushed metal: half the grain
            app=dict(display=dict(text="#F7B26B", textDim="#8A6A48"),
                     # plates are pale but keys stay dark: plate print goes dark, key print stays light
                     ink=dict(faceplate="#1E2226", faceplateDim="#4E565E", inset="#1E2226", insetDim="#4E565E",
                              backplane="#1E2226", backplaneDim="#4E565E", socket="#1E2226", socketDim="#4E565E",
                              reviewBar="#1E2226", reviewBarDim="#4E565E"),
                     ui=dict(text="#1E2226", textDim="#4E565E"))),
    },
)

if __name__ == "__main__":
    sys.exit(main(LOOK))
