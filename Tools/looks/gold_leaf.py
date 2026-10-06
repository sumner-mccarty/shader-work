"""Gold Leaf — black lacquer and 24k gold hardware (lit). Brief: Looks/BACKLOG.md#gold-leaf.

    python Tools/looks/gold_leaf.py check | sheet | write | manifest

Signature: gold that reads as METAL — a domed, radially-brushed cap over a knurled skirt, gold
chamfers on black lacquer keys — never as yellow plastic. The gold's "reflection" is the preset's
dark-ground / pale-sky ramp; the warm, champagne specular is the RIG (warm key lamp). Deep emerald
is the only other colour, and it means ON. Light mode changes the chassis to ivory lacquer; the
hardware is the same black-and-gold.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from lookkit import Look, main  # noqa: E402

EMERALD = "#0E6A46"
CONTROLS = dict(                     # the hardware — identical in both modes
    BODY_LO="#3B3322",               # pressed: the key warms toward the gold, so a press reads
    DIS_BODY="#22201C",              # disabled sinks toward black lacquer in BOTH modes (not the plate)
    MARK="#E9CB7E", MARK_DIM="#9A8148", DIS_MARK="#4E4434", ON_MARK="#F6E6B4",
    ACCENT=EMERALD, SOLO="#B8903A", LAMP="#2FBF7C", LAMP_OFF="#7D6A3E", HOT="#C9473A",
    NUB=EMERALD, VALUE="#E3B854", VALUE_EM=0.15, TRACK="#0B0A08", ARC_OFF="#2B261C",
    SCROLL="#2A2721", SCROLL_HI="#B8903A", PAD_BODY="#1B1A18", PAD_TINT=0.72,
)
GOLD_KEY = {"preset": "lacquer.black", "edge": "gold.polished"}     # black lacquer, gold chamfer

LOOK = Look(
    title="Gold Leaf", style="GoldLeaf", prefix="GoldLeaf", slug="gold-leaf", cls="lit", order=10,
    status="candidate", brief="BACKLOG.md#gold-leaf",
    blurb="Black lacquer and 24k gold hardware. Emerald means on.",
    tagline="black lacquer, 24k gold hardware, emerald for ON.",
    displays="neo",
    shape={
        "key": dict(corner=0.42, round=0.42),
        # the knob: a domed gold cap riding a wide knurled skirt (the bevel band IS the skirt)
        # a fluted (knurled-edge) silhouette, a narrow skirt band and a big domed face
        "dial": dict(skirt="Fluted", skirt_count=30, skirt_depth=0.06, cap_r=0.66, bevel=0.18, depth=0.5,
                     smooth=0.6, dome=0.6, nub=0.07, nub_dist=0.42, arc_px=3.0),
        "KnobHero": dict(ticks=11, arc_px=4.0),
        "shadow": dict(blur=1.5, cast=0.22),
    },
    material={
        # lacquer, not paint: a soft sheen toward the top of every plate
        "plate": {"preset": "lacquer.black", "plate_ramp": (0.12, 0.2)},
        "key": GOLD_KEY,
        "accent": {"preset": "lacquer.black", "tint": EMERALD, "edge": "gold.polished"},
        # the cap must read as POLISHED gold: more ambient lifts the ramp's dark "ground" so the dome
        # reads as a bright mirror with a darker foot, not a bronze cup
        "cap": {"preset": "gold.polished", "amb": 0.9, "ramp": (-0.45, 0.05, 0.45, 0.85)},
        "skirt": {"preset": "gold.brushed", "pattern": ("Knurled", 1.4, 0.22, 1.0, 0.5, 0.6, 0.5)},
        "handle": "gold.polished",
    },
    rig={
        # a warm key high on the left (champagne spec), a faint cool fill so blacks keep a shape
        "dark": {"light1": dict(pos=[-0.4, 1.5], height=1.3, color="#FFE7BD", intensity=0.85, specular=0.35,
                                specularPower=48),
                 "light2": dict(pos=[1.3, 0.6], height=0.9, color="#CAD6FF", intensity=0.2, specular=0.06),
                 "light3": dict(enabled=False)},
        # pale chassis: one far, high, warm key — fill and bounce off
        "light": {"light1": dict(pos=[-1.5, 3.0], height=4.0, color="#FFF0D8", intensity=0.8, specular=0.15,
                                 specularPower=48),
                  "light2": dict(enabled=False), "light3": dict(enabled=False)},
    },
    modes={
        "dark": dict(
            track="Moss", blurb="Black lacquer, gold hardware, one warm lamp.",
            palette=dict(CONTROLS, GAP="#060607", BACK="#0C0C0E", FACE="#151417", INSET="#0F0F11", SOCKET="#0E0E10",
                         WELL="#060505", SHADOW="#000000", SHADOW_A=0.6, WELL_EM=0.05),
            app=dict(display=dict(text="#F2C96A", textDim="#8C7444", textAlt="#F2C96A"),
                     ui=dict(accent="#E3B854"))),
        "light": dict(
            track="Rosewater", blurb="Ivory lacquer, the same gold.",
            palette=dict(CONTROLS, GAP="#A99F88", BACK="#D2C8B2", FACE="#E6DDC9", INSET="#DAD0BB", SOCKET="#D6CCB6",
                         WELL="#100E0B", SHADOW="#3A2E18", SHADOW_A=0.35, WELL_EM=0.05, AMB_PLATE=0.88),
            material={"plate": {"preset": "lacquer.black", "tint": "#E6DDC9", "lo": "#6A5E46", "hi": "#FFFFFF"}},
            app=dict(display=dict(text="#F2C96A", textDim="#8C7444", textAlt="#F2C96A"),
                     ui=dict(text="#2A2418", textDim="#6B5E45", accent="#8A6A22"),
                     # tab labels/icons and multitrack text sit on the ivory chassis: gold-on-ivory
                     # measured 1.0-2.3:1 (printcheck), so they print in dark antique gold
                     chrome=dict(label="#6B5320", labelActive="#2A2418", icon="#6B5320", iconActive="#2A2418"),
                     tracks=dict(text="#2A2418", rowWithSample="#CDB98A"),
                     # pale plates, black keys: plate print goes dark, key print stays gold
                     ink=dict(faceplate="#2A2418", faceplateDim="#6B5E45", inset="#2A2418", insetDim="#6B5E45",
                              backplane="#2A2418", backplaneDim="#6B5E45", socket="#2A2418", socketDim="#6B5E45",
                              reviewBar="#2A2418", reviewBarDim="#6B5E45"))),
    },
)

if __name__ == "__main__":
    sys.exit(main(LOOK))
