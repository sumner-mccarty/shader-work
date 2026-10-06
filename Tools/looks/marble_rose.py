"""Marble & Rose Gold — stone and jewellery (lit). Brief: Looks/BACKLOG.md#marble-rose.

    python Tools/looks/marble_rose.py check | sheet | write | manifest

Signature: stone + jewellery. Veined marble plates (px-locked Marble pattern) carry rose-gold domed
hardware: polished rose-gold caps over a fine-fluted skirt, rose-gold keys with a milled chamfer,
blush-pink enamel for accent/ON. Dark mode is Nero Marquina (black stone, gold veins); light mode
changes the chassis only, to white Carrara (soft grey veins) in soft daylight. The hardware is the same.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from lookkit import Look, MATERIALS, main  # noqa: E402

BLUSH = "#E79AA8"
ROSE = "#D8998C"
CONTROLS = dict(                     # the hardware — identical in both modes
    BODY=ROSE, BODY_HI="#EDB9AC", BODY_LO="#7E4A42", DIS_BODY="#6A5450",
    MARK="#3A1C1C", MARK_DIM="#6E3F3C", DIS_MARK="#9A7E78", ON_MARK="#3F0F1C",
    ACCENT=BLUSH, SOLO="#F0B7A4", LAMP="#FFD3DA", LAMP_OFF="#8A6A66", HOT="#D2455A",
    CAP="#E3A99C", SKIRT="#C98A7B", NUB="#FFE3E6", HANDLE="#E3A99C",
    VALUE="#F4A6B4", VALUE_EM=0.3, TRACK="#140D0E", ARC_OFF="#2E2022",
    SCROLL="#4A3A3C", SCROLL_HI="#D79A8A", PAD_BODY="#3A2A2C", PAD_TINT=0.6,
)
ROSE_KEY = {"preset": "gold.rose", "amb": 1.0}
# a spec-local preset (the kit's library is not edited): black stone whose pattern colours run
# black -> deep charcoal -> gold, so the veins are metallic gold
MATERIALS["marble.nero"] = dict(
    MATERIALS["marble"], base="#101013", lo="#000000", hi="#F0CC78", tint=(1, 1, (0.0, 0.1, 0.7, 1.0)),
    pattern=("Marble", 90.0, 0.9, 1.2, 0.1, 1.0, 0.9), spec=0.6, rough=0.1, plate_amb=1.1)
NERO = "marble.nero"
CARRARA = {"preset": "marble", "tint": "#F4F1EC", "lo": "#8C8884", "hi": "#FFFFFF",
           "pattern": ("Marble", 90.0, 0.8, 1.2, 0.1, 1.0, 0.3), "plate_amb": 1.3}

LOOK = Look(
    title="Marble & Rose Gold", style="MarbleRose", prefix="MarbleRose", slug="marble-rose", cls="lit", order=24,
    status="draft", brief="BACKLOG.md#marble-rose",
    blurb="Veined marble plates, rose-gold domed hardware, blush pink.",
    tagline="veined marble, rose-gold domed hardware, blush for ON.",
    displays="neo",
    shape={
        "key": dict(corner=0.5, round=0.5, bevel=0.16, depth=0.55, dome=0.4),
        "dial": dict(skirt="Fluted", skirt_count=40, skirt_depth=0.04, cap_r=0.64, bevel=0.2, depth=0.5,
                     smooth=0.6, dome=0.6, nub=0.07, nub_dist=0.4, arc_px=3.0),
        "KnobHero": dict(ticks=11, arc_px=4.0),
        "shadow": dict(blur=1.6, cast=0.24),
    },
    material={
        "plate": NERO,
        "key": ROSE_KEY,
        "accent": {"preset": "enamel", "tint": BLUSH, "edge": "gold.rose", "amb": 0.8},
        "cap": {"preset": "gold.rose", "amb": 1.0, "ramp": (-0.45, 0.05, 0.45, 0.8)},
        "skirt": {"preset": "gold.rose", "amb": 1.0, "pattern": ("Knurled", 2.0, 0.12, 1.0, 0.5, 0.6, 0.5)},
        "handle": "gold.rose",
    },
    rig={
        "dark": {"light1": dict(pos=[-0.4, 1.5], height=1.2, color="#FFE6DC", intensity=0.9, specular=0.4,
                                specularPower=48),
                 "light2": dict(pos=[1.3, 0.6], height=0.9, color="#FFC9D6", intensity=0.3, specular=0.08),
                 "light3": dict(enabled=False)},
        "light": {"light1": dict(pos=[-1.5, 3.0], height=4.0, color="#FFF6EE", intensity=0.8, specular=0.15,
                                 specularPower=48),
                  "light2": dict(enabled=False), "light3": dict(enabled=False)},
    },
    modes={
        "dark": dict(
            track="Velvet", blurb="Nero Marquina and rose gold.",
            palette=dict(CONTROLS, GAP="#060607", BACK="#0C0C0F", FACE="#131316", INSET="#0E0E11", SOCKET="#0D0D10",
                         WELL="#050405", SHADOW="#000000", SHADOW_A=0.6, WELL_EM=0.05, AMB_PLATE=0.7),
            app=dict(display=dict(text="#F4B4BF", textDim="#8E6670", textAlt="#E8C47A"),
                     ui=dict(text="#EADFD8", textDim="#8E8480", accent=BLUSH),
                     chrome=dict(label="#CDB6AE", labelActive="#EADFD8", icon="#CDB6AE", iconActive="#F4B4BF"),
                     tracks=dict(text="#EADFD8", ruler="#CDB6AEE6", playhead="#EADFD8E6", rowWithSample="#3A2A2C"),
                     ink=dict(faceplate="#EADFD8", faceplateDim="#9A8F8A", inset="#EADFD8", insetDim="#9A8F8A",
                              backplane="#EADFD8", backplaneDim="#9A8F8A", socket="#EADFD8", socketDim="#9A8F8A",
                              reviewBar="#EADFD8", reviewBarDim="#9A8F8A"))),
        "light": dict(
            track="Rosewater", blurb="White Carrara in soft daylight, the same rose gold.",
            palette=dict(CONTROLS, GAP="#B3AEA9", BACK="#D7D3CE", FACE="#EAE7E2", INSET="#DDD9D4", SOCKET="#D9D5D0",
                         WELL="#100C0D", SHADOW="#4A3E3C", SHADOW_A=0.35, WELL_EM=0.05, AMB_PLATE=1.0),
            material={"plate": CARRARA},
            app=dict(display=dict(text="#F4B4BF", textDim="#8E6670", textAlt="#E8C47A"),
                     ui=dict(text="#2A2224", textDim="#6E6264", accent="#B04C62"),
                     ink=dict(faceplate="#2A2224", faceplateDim="#6E6264", inset="#2A2224", insetDim="#6E6264",
                              backplane="#2A2224", backplaneDim="#6E6264", socket="#2A2224", socketDim="#6E6264",
                              reviewBar="#2A2224", reviewBarDim="#6E6264"))),
    },
)

if __name__ == "__main__":
    sys.exit(main(LOOK))
