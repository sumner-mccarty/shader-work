"""Ice Cold — hip-hop flex (lit). Brief: Looks/BACKLOG.md#ice-cold.

    python Tools/looks/ice_cold.py check | sheet | write | manifest

Signature: gold mass + diamond sparkle. Matte-black rubber chassis; heavy gold hardware (thick,
coarsely knurled skirts, a dashed gold chain ring round each cap, gold bezels on every key); the
keys and lamps are "iced" — white ceramic faces with a hard spec and a coarse facet grain. Ice blue
is the ON colour. Light mode swaps the chassis for white leather; gold and ice are unchanged.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from lookkit import Look, main  # noqa: E402

ICE = "#EAF4FC"
BLUE = "#6FD3FF"
CONTROLS = dict(                     # the hardware — identical in both modes
    BODY=ICE, BODY_HI="#FFFFFF", BODY_LO="#B9CEDD", DIS_BODY="#5C646C",
    MARK="#10151B", MARK_DIM="#52606E", DIS_MARK="#8C97A2", ON_MARK="#04202E",
    ACCENT=BLUE, SOLO="#F2C14E", LAMP="#BFEFFF", LAMP_OFF="#8CA0B0", HOT="#E04A4A",
    CAP="#C99A2E", SKIRT="#C99A2E", NUB="#10151B", HANDLE="#C99A2E",
    VALUE="#7FDBFF", VALUE_EM=0.35, TRACK="#08090B", ARC_OFF="#24262B",
    SCROLL="#2A2C31", SCROLL_HI="#E0B040", PAD_BODY="#2A2D33", PAD_TINT=0.7,
)
ICED = {"preset": "ceramic", "tint": ICE, "amb": 0.95, "spec": 1.0, "rough": 0.08,
        "pattern": ("Ceramic", 2.4, 0.3, 1.0, 0.5, 0.5, 0.0), "edge": "gold.polished"}

LOOK = Look(
    title="Ice Cold", style="IceCold", prefix="IceCold", slug="ice-cold", cls="lit", order=21,
    status="draft", brief="BACKLOG.md#ice-cold",
    blurb="Matte black, heavy gold and diamond-white keys.",
    tagline="matte black, heavy gold chain hardware, iced keys.",
    displays="neo",
    shape={
        "key": dict(corner=0.5, round=0.5, bevel=0.2, depth=0.6, dome=0.35),
        # heavy: a wide skirt band of coarse gold knurl and a dashed 'chain link' ring round the cap
        "dial": dict(skirt="Circle", cap_r=0.56, bevel=0.3, depth=0.6, smooth=0.6, dome=0.5, nub=0.07,
                     nub_dist=0.36, arc_px=3.0, stitch=(0.68, 0.045, "#E0B040")),
        "KnobHero": dict(ticks=11, arc_px=4.0),
        "shadow": dict(blur=1.5, cast=0.26),
    },
    material={
        "plate": {"preset": "rubber.matte", "tint": "#141518", "plate_ramp": (0.05, 0.18)},
        "key": ICED,
        "accent": {"preset": "ceramic", "tint": BLUE, "amb": 0.8, "spec": 1.0, "rough": 0.08,
                   "pattern": ("Ceramic", 2.4, 0.3, 1.0, 0.5, 0.5, 0.0), "edge": "gold.polished"},
        "cap": {"preset": "gold.polished", "amb": 0.9, "ramp": (-0.45, 0.05, 0.45, 0.85)},
        "skirt": {"preset": "gold.brushed", "pattern": ("Knurled", 5.0, 0.3, 1.0, 0.5, 0.6, 0.5)},
        "handle": "gold.polished",
    },
    rig={
        "dark": {"light1": dict(pos=[-0.5, 1.4], height=1.1, color="#FFF4DC", intensity=0.95, specular=0.55,
                                specularPower=56),
                 "light2": dict(pos=[1.3, 0.7], height=0.9, color="#BFDFFF", intensity=0.25, specular=0.2),
                 "light3": dict(enabled=False)},
        "light": {"light1": dict(pos=[-1.5, 3.0], height=4.0, color="#FFFFFF", intensity=0.8, specular=0.15,
                                 specularPower=48),
                  "light2": dict(enabled=False), "light3": dict(enabled=False)},
    },
    modes={
        "dark": dict(
            track="Starfield", blurb="Matte black, gold and ice.",
            palette=dict(CONTROLS, GAP="#050506", BACK="#0B0C0E", FACE="#0F1012", INSET="#0B0C0D", SOCKET="#09090A",
                         WELL="#030304", SHADOW="#000000", SHADOW_A=0.65, WELL_EM=0.05, AMB_PLATE=0.7),
            app=dict(display=dict(text="#7FD2F2", textDim="#4F7F94", textAlt="#F2C14E"),
                     ui=dict(text="#DDE3E8", textDim="#7D8892", accent="#6FD3FF"),
                     # black plates, white keys: plate print is light, key print stays dark
                     ink=dict(faceplate="#DDE3E8", faceplateDim="#7D8892", inset="#DDE3E8", insetDim="#7D8892",
                              backplane="#DDE3E8", backplaneDim="#7D8892", socket="#DDE3E8", socketDim="#7D8892",
                              reviewBar="#DDE3E8", reviewBarDim="#7D8892"))),
        "light": dict(
            track="Rosewater", blurb="White leather chassis, the same gold and ice.",
            palette=dict(CONTROLS, GAP="#A9AAAE", BACK="#D2D3D6", FACE="#ECECEA", INSET="#DCDDE0", SOCKET="#D6D7DA",
                         WELL="#0A0B0D", SHADOW="#2C2E33", SHADOW_A=0.35, WELL_EM=0.05, AMB_PLATE=0.95),
            material={"plate": {"preset": "leather.tooled", "tint": "#ECECEA", "lo": "#6C6C6E", "hi": "#FFFFFF",
                                "plate_ramp": (0.1, 0.15), "pattern": ("Leather", 5.0, 0.25, 1.0, 0.5, 0.5, 0.0)}},
            app=dict(display=dict(text="#7FD2F2", textDim="#4F7F94", textAlt="#F2C14E"),
                     ui=dict(text="#17181B", textDim="#5C5F66", accent="#1F8FC0"),
                     ink=dict(faceplate="#17181B", faceplateDim="#5C5F66", inset="#17181B", insetDim="#5C5F66",
                              backplane="#17181B", backplaneDim="#5C5F66", socket="#17181B", socketDim="#5C5F66",
                              reviewBar="#17181B", reviewBarDim="#5C5F66"))),
    },
)

if __name__ == "__main__":
    sys.exit(main(LOOK))
