"""Walnut & Brass — 70s hi-fi receiver (lit). Brief: Looks/BACKLOG.md#walnut-brass.

    python Tools/looks/walnut_brass.py check | sheet | write | manifest

Signature: real wood + warm metal. A brushed-brass faceplate flanked by oiled-walnut side plates and
inset panels (px-locked grain), skirted aluminium knobs with a fine flute, aluminium keys, cream dial
lamps and amber glass for ON. Light mode changes the chassis only: teak side panels and a champagne
aluminium faceplate; the hardware is the same.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from lookkit import Look, main  # noqa: E402

AMBER = "#E39A2E"
ALU = "#A9AEB4"
CONTROLS = dict(                     # the hardware — identical in both modes
    BODY=ALU, BODY_HI="#C4C8CD", BODY_LO="#7E838A", DIS_BODY="#5C5A55",
    MARK="#1B140E", MARK_DIM="#4F4538", DIS_MARK="#8A857B", ON_MARK="#2A1805",
    ACCENT=AMBER, SOLO="#E8B64A", LAMP="#F7E4B0", LAMP_OFF="#7A6A48", HOT="#D8452E",
    CAP="#B4B9BF", SKIRT="#8C9197", NUB=AMBER, HANDLE="#B4B9BF",
    VALUE="#F0AA3C", VALUE_EM=0.25, TRACK="#120B06", ARC_OFF="#2A1B10",
    SCROLL="#4A3A2A", SCROLL_HI="#C9A24A", PAD_BODY="#3A2C20", PAD_TINT=0.6,
)
# brushed brass: long anisotropic streaks (Metal, p1 0.5, p2 0 = longest) at a visible 2 px grain and a real
# bright-top / dark-foot gradient, so a large plate reads as lit metal at 1:1 rather than flat mustard
BRASS = {"preset": "brass", "plate_ramp": (0.45, 0.5), "plate_amb": 0.6, "spec": 0.9, "rough": 0.2,
         "pattern": ("Metal", 2.2, 0.24, 1.0, 0.5, 0.0, 0.0)}
WALNUT = {"preset": "wood.oiled", "pattern": ("WoodGrain", 40.0, 0.7, 1.15, 0.5, 0.5, 0.5)}

LOOK = Look(
    title="Walnut & Brass", style="WalnutBrass", prefix="WalnutBrass", slug="walnut-brass", cls="lit", order=23,
    status="candidate", brief="BACKLOG.md#walnut-brass",
    blurb="Oiled walnut, brushed brass, aluminium knobs and amber glass.",
    tagline="oiled walnut, brushed brass, skirted aluminium knobs.",
    displays="neo",
    shape={
        "key": dict(corner=0.22, round=0.25, bevel=0.14, depth=0.5, dome=0.2),
        "dial": dict(skirt="Fluted", skirt_count=36, skirt_depth=0.05, cap_r=0.62, bevel=0.2, depth=0.5,
                     smooth=0.6, dome=0.45, nub=0.07, nub_dist=0.4, arc_px=3.0),
        "KnobHero": dict(ticks=11, arc_px=4.0),
        "shadow": dict(blur=1.4, cast=0.24),
    },
    material={
        "plate": BRASS, "Back": WALNUT, "Inset": WALNUT, "Socket": WALNUT, "ScrollTrack": WALNUT,
        "key": {"preset": "aluminium.brushed", "amb": 0.8},
        "accent": {"preset": "enamel", "tint": AMBER, "edge": "brass"},
        "cap": {"preset": "aluminium.brushed", "amb": 0.85, "dome": 0.45,
                "pattern": ("RadialBrushed", 3.0, 0.1, 1.0, 0.45, 0.2, 0.0)},
        "skirt": {"preset": "aluminium.brushed", "pattern": ("Knurled", 3.0, 0.12, 1.0, 0.5, 0.6, 0.5)},
        "handle": "aluminium.brushed",
    },
    rig={
        "dark": {"light1": dict(pos=[-0.4, 1.5], height=1.2, color="#FFD9A0", intensity=0.9, specular=0.3,
                                specularPower=40),
                 "light2": dict(pos=[1.3, 0.6], height=0.9, color="#FFB070", intensity=0.18, specular=0.05),
                 "light3": dict(enabled=False)},
        "light": {"light1": dict(pos=[-1.5, 3.0], height=4.0, color="#FFF0D8", intensity=0.8, specular=0.12,
                                 specularPower=40),
                  "light2": dict(enabled=False), "light3": dict(enabled=False)},
    },
    modes={
        "dark": dict(
            track="Sunset", blurb="Walnut and brass in lamplight.",
            palette=dict(CONTROLS, GAP="#0E0805", BACK="#3A2314", FACE="#B0903C", INSET="#4A2D18", SOCKET="#2E1C10",
                         WELL="#080503", SHADOW="#000000", SHADOW_A=0.6, WELL_EM=0.05),
            app=dict(display=dict(text="#F2B25A", textDim="#8A6636", textAlt="#F2B25A"),
                     # print on the brass faceplate is a dark ENGRAVED brown (module names, captions, cards);
                     # the walnut plates, header and track lanes take cream
                     ui=dict(text="#2B1D0C", textDim="#5A4326", accent=AMBER),
                     chrome=dict(label="#CDB88C", labelActive="#2B1D0C", icon="#CDB88C", iconActive="#5A2E08",
                                 gear="#CDB88CCC", meatballIdle="#CDB88C", meatballLit=AMBER),
                     tracks=dict(text="#F0E2BC", ruler="#CDB88CE6", playhead="#F0E2BCE6",
                                 rowWithSample="#6B4A2A", rowEmpty="#2A180C"),
                     ink=dict(faceplate="#2B1D0C", faceplateDim="#5A4326", inset="#F0E2BC", insetDim="#A8946A",
                              backplane="#F0E2BC", backplaneDim="#A8946A", socket="#F0E2BC", socketDim="#A8946A",
                              reviewBar="#F0E2BC", reviewBarDim="#A8946A"))),
        "light": dict(
            track="Rosewater", blurb="Teak and champagne aluminium, same hardware.",
            palette=dict(CONTROLS, GAP="#8E7552", BACK="#8C5A30", FACE="#D9CCA6", INSET="#965F33", SOCKET="#7C4E28",
                         WELL="#100B07", SHADOW="#3A2A16", SHADOW_A=0.35, WELL_EM=0.05, AMB_PLATE=0.9),
            material={"plate": {"preset": "aluminium.brushed", "tint": "#D9CCA6", "lo": "#7C6E4C", "hi": "#FFFFFF",
                                "plate_ramp": (0.1, 0.15), "plate_amb": 0.9}},
            app=dict(display=dict(text="#F2B25A", textDim="#8A6636", textAlt="#F2B25A"),
                     ui=dict(text="#2A1A0E", textDim="#6B5238", accent="#B26A12"),
                     chrome=dict(label="#F3E6C8", labelActive="#2A1A0E", icon="#F3E6C8", iconActive="#7A3E08",
                                 gear="#F3E6C8CC", meatballIdle="#F3E6C8", meatballLit="#FFD27A"),
                     tracks=dict(text="#FBF0D8", ruler="#F3E6C8E6", playhead="#FBF0D8E6",
                                 rowWithSample="#7C4E28", rowEmpty="#A06C3C"),
                     ink=dict(faceplate="#2A1A0E", faceplateDim="#4A3820", inset="#FBF0D8", insetDim="#E3D2AE",
                              backplane="#FBF0D8", backplaneDim="#E3D2AE", socket="#FBF0D8", socketDim="#E3D2AE",
                              reviewBar="#FBF0D8", reviewBarDim="#E3D2AE"))),
    },
)

if __name__ == "__main__":
    sys.exit(main(LOOK))
