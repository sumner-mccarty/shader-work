"""Rodeo — Country & Western (lit). Brief: Looks/BACKLOG.md#rodeo.

    python Tools/looks/rodeo.py check | sheet | write | manifest

Signature: leather + silver + turquoise. Tooled saddle-leather plates (tan on top, oxblood at the
foot), keys like branded leather patches with a silver chamfer, silver concho knobs (a fluted skirt,
a radially-engraved turquoise inlay cap) and amber oil-lamp glow. Light mode changes the chassis to
bleached rawhide and pale denim; the hardware is the same.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from lookkit import Look, main  # noqa: E402

TURQ = "#2BB5AA"
LEATHER = "#8E5632"
CONTROLS = dict(                     # the hardware — identical in both modes
    BODY=LEATHER, MARK="#F4E4C4", MARK_DIM="#C9A878", DIS_MARK="#6A4E36", ON_MARK="#06201D",
    ACCENT=TURQ, SOLO="#E3A33A", LAMP="#F4A83A", LAMP_OFF="#7A5530", HOT="#D8452E",
    CAP=TURQ, SKIRT="#A5ADB5", NUB="#22110A", HANDLE="#B7BEC5",
    VALUE="#F0B04A", VALUE_EM=0.15, TRACK="#1A0D08", ARC_OFF="#2A150C",
    SCROLL="#6E4428", SCROLL_HI="#C9D0D6", PAD_BODY="#6A4630", PAD_TINT=0.6,
)
RAWHIDE_SKIRT = {"preset": "chrome", "pattern": ("Fluted", 1.0, 0.0, 1.0, 0.5, 0.0, 0.0)}

LOOK = Look(
    title="Rodeo", style="Rodeo", prefix="Rodeo", slug="rodeo", cls="lit", order=20,
    status="draft", brief="BACKLOG.md#rodeo",
    blurb="Tooled leather, silver conchos, turquoise inlay and amber oil glow.",
    tagline="saddle leather, silver concho knobs, turquoise inlay.",
    displays="neo",
    shape={
        "key": dict(corner=0.3, round=0.3),
        "dial": dict(skirt="Fluted", skirt_count=20, skirt_depth=0.1, cap_r=0.6, bevel=0.17, depth=0.45,
                     smooth=0.6, dome=0.55, nub=0.07, nub_dist=0.4, arc_px=3.0),
        "KnobHero": dict(ticks=11, arc_px=4.0),
        "shadow": dict(blur=1.4, cast=0.24),
    },
    material={
        "plate": {"preset": "leather.tooled", "lo": "#2A0A0A", "hi": "#EBB880", "plate_ramp": (0.3, 0.38),
                  "pattern": ("Leather", 5.0, 0.5, 1.0, 0.5, 0.5, 0.0)},
        "key": {"preset": "leather.tooled", "edge": "chrome"},
        "accent": {"preset": "enamel", "tint": TURQ, "edge": "chrome"},
        "cap": {"preset": "enamel", "tint": TURQ, "edge": "chrome", "dome": 0.5, "amb": 0.8,
                "pattern": ("RadialBrushed", 3.0, 0.08, 1.0, 0.45, 0.2, 0.0)},
        "skirt": {"preset": "chrome", "pattern": ("Metal", 1.0, 0.05, 1.0, 0.5, 0.0, 0.0)},
        "handle": "chrome",
    },
    rig={
        # amber oil lamp, high on the left; a faint warm-cool fill so the shadows keep a shape
        "dark": {"light1": dict(pos=[-0.4, 1.5], height=1.2, color="#FFC57A", intensity=0.9, specular=0.3,
                                specularPower=40),
                 "light2": dict(pos=[1.3, 0.6], height=0.9, color="#9FB6D0", intensity=0.18, specular=0.05),
                 "light3": dict(enabled=False)},
        "light": {"light1": dict(pos=[-1.5, 3.0], height=4.0, color="#FFF2DC", intensity=0.8, specular=0.12,
                                 specularPower=40),
                  "light2": dict(enabled=False), "light3": dict(enabled=False)},
    },
    modes={
        "dark": dict(
            track="Sunset", blurb="Oxblood leather, silver and turquoise by lamplight.",
            palette=dict(CONTROLS, GAP="#120805", BACK="#341C11", FACE="#76412A", INSET="#4A2818", SOCKET="#34190F",
                         WELL="#0B0605", SHADOW="#000000", SHADOW_A=0.6, WELL_EM=0.05),
            app=dict(display=dict(text="#F6B25A", textDim="#8A6636", textAlt="#F6B25A"),
                     ui=dict(accent="#2BB5AA"))),
        "light": dict(
            track="Rosewater", blurb="Bleached rawhide and pale denim, the same silver and turquoise.",
            palette=dict(CONTROLS, GAP="#9A8868", BACK="#C2AD86", FACE="#DDCBA6", INSET="#7F9CBC", SOCKET="#7391B2",
                         WELL="#14100C", SHADOW="#3A2A18", SHADOW_A=0.35, WELL_EM=0.05, AMB_PLATE=0.9),
            material={"plate": {"preset": "leather.tooled", "tint": "#DDCBA6", "lo": "#7A6648", "hi": "#FFFFFF",
                                "plate_ramp": (0.1, 0.18), "pattern": ("Leather", 5.0, 0.35, 1.0, 0.5, 0.5, 0.0)}},
            app=dict(display=dict(text="#F6B25A", textDim="#8A6636", textAlt="#F6B25A"),
                     ui=dict(text="#2A1A0E", textDim="#6B5238", accent="#16857C"),
                     ink=dict(faceplate="#2A1A0E", faceplateDim="#6B5238", inset="#1B2A38", insetDim="#46586A",
                              backplane="#2A1A0E", backplaneDim="#6B5238", socket="#1B2A38", socketDim="#46586A",
                              reviewBar="#2A1A0E", reviewBarDim="#6B5238"))),
    },
)

if __name__ == "__main__":
    sys.exit(main(LOOK))
