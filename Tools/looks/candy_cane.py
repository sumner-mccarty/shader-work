"""Candy Cane — Christmas (lit, seasonal). Brief: Looks/BACKLOG.md#candy-cane.

    python Tools/looks/candy_cane.py check | sheet | write | manifest

Signature: stripes + velvet + warm twinkle. Red velvet plates piped in gold, pine-green keys with a
gold chamfer, knob skirts and slider fills wound in red-and-white candy stripes, warm fairy-light
lamps. Light mode changes the chassis to snow-white frosted glass; the hardware is the same.
The stripes use the kit's `shape[...]["set"]` hook (raw properties: gradient type Angular on the
skirt, Triangle on the slider fill).
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from lookkit import Look, main  # noqa: E402

RED, WHITE, GREEN, GOLD = "#D12A3A", "#FFFFFF", "#1E6B44", "#DDB650"
CONTROLS = dict(                     # the hardware — identical in both modes
    BODY=GREEN, BODY_HI="#2A8458", BODY_LO="#154D31", DIS_BODY="#3E4A42",
    MARK="#FFF3DC", MARK_DIM="#B9C8A8", DIS_MARK="#76806F", ON_MARK="#FFF8EC",
    ACCENT=RED, SOLO=GOLD, LAMP="#FFC15A", LAMP_OFF="#80683C", HOT="#FF5A4A",
    CAP=GREEN, SKIRT=RED, NUB=GOLD, HANDLE=GOLD,
    VALUE="#FFD27A", VALUE_EM=0.3, TRACK="#2A0A10", ARC_OFF="#3A1219",
    SCROLL="#8C6A28", SCROLL_HI=GOLD, PAD_BODY="#5A4A48", PAD_TINT=0.65,
)
STRIPE = lambda layer, typ, direction, scale: {            # noqa: E731  red/white, hard-ish bands
    f"{layer}GradientEnabled": 1, f"{layer}GradientType": typ, f"{layer}GradientDirection": direction,
    f"{layer}GradientScale": scale, f"{layer}GradientOffset": 0.0, f"{layer}GradientSpeed": 0.0,
    f"{layer}GradientColorA": RED, f"{layer}GradientColorB": RED,
    f"{layer}GradientColorC": WHITE, f"{layer}GradientColorD": WHITE, f"{layer}GradientColorUsed": 4}

LOOK = Look(
    title="Candy Cane", style="CandyCane", prefix="CandyCane", slug="candy-cane", cls="lit", order=22,
    status="candidate", brief="BACKLOG.md#candy-cane",
    blurb="Red velvet, pine green, candy stripes and fairy lights. Seasonal.",
    tagline="red velvet, candy stripes, warm twinkle (seasonal).",
    displays="neo",
    shape={
        "key": dict(corner=0.5, round=0.5),
        "dial": dict(skirt="Circle", cap_r=0.6, bevel=0.2, depth=0.55, smooth=0.7, dome=0.5, nub=0.085,
                     nub_dist=0.3, arc_px=3.0,
                     set=STRIPE("_KnobBevel", 2, (1.0, 0.0, 0.0, 0.0), 5.0)),
        "KnobHero": dict(ticks=11, arc_px=4.0),
        "Slider": dict(set=STRIPE("_TrackValueFilled", 4, (1.0, 0.6, 0.0, 0.0), 10.0)),
        "plate": dict(stitch=(GOLD, 1.4)),
        "shadow": dict(blur=1.5, cast=0.24),
    },
    material={
        "plate": {"preset": "fabric.velvet", "tint": "#7A1426", "plate_ramp": (0.32, 0.42),
                  "pattern": ("Fabric", 2.5, 0.4, 1.0, 0.5, 0.5, 0.0)},
        "key": {"preset": "enamel", "tint": GREEN, "edge": "gold.brushed"},
        "accent": {"preset": "enamel", "tint": RED, "edge": "gold.brushed"},
        "cap": {"preset": "enamel", "tint": GREEN, "edge": "gold.polished", "dome": 0.5, "amb": 0.8,
                "pattern": ("RadialBrushed", 3.0, 0.05, 1.0, 0.45, 0.2, 0.0)},
        "skirt": {"preset": "enamel", "tint": RED, "pattern": ("Plastic", 6.0, 0.02, 1.0, 0.7, 0.0, 0.1)},
        "handle": "gold.polished",
    },
    rig={
        # Lamp intensities are LOW on purpose (2026-10-07): until then a generator bug shipped every lamp
        # disabled, and the parts' ambient (~0.9) was tuned for that. Lamps at full strength stacked
        # 1.4-1.7x more light and blew the pale plates out; these add ~11-12% of light on top of the
        # approved look (sheen + cap highlights). See Tools/lookkit.py theme_files().
        "dark": {"light1": dict(pos=[-0.4, 1.5], height=1.2, color="#FFD79A", intensity=0.109, specular=0.3,
                                specularPower=40),
                 "light2": dict(pos=[1.3, 0.6], height=0.9, color="#FFA860", intensity=0.024, specular=0.05),
                 "light3": dict(enabled=False)},
        "light": {"light1": dict(pos=[-1.5, 3.0], height=4.0, color="#FFFFFF", intensity=0.089, specular=0.12,
                                 specularPower=40),
                  "light2": dict(enabled=False), "light3": dict(enabled=False)},
    },
    modes={
        "dark": dict(
            track="Velvet", blurb="Red velvet, gold piping, fairy lights.",
            palette=dict(CONTROLS, GAP="#16050A", BACK="#4A0C18", FACE="#7A1426", INSET="#5A0E1D", SOCKET="#52101B",
                         WELL="#0C0406", SHADOW="#000000", SHADOW_A=0.6, WELL_EM=0.05),
            app=dict(display=dict(text="#F6BE5E", textDim="#8C6E3A", textAlt="#F6BE5E"),
                     ui=dict(accent=GOLD))),
        "light": dict(
            track="Rosewater", blurb="Snow-white frosted chassis, the same stripes and green.",
            palette=dict(CONTROLS, GAP="#9FB0BC", BACK="#CAD6DE", FACE="#EEF3F6", INSET="#DCE8E4", SOCKET="#D5E2DE",
                         WELL="#0C0A0A", SHADOW="#2E3A44", SHADOW_A=0.35, WELL_EM=0.05, AMB_PLATE=0.9),
            material={"plate": {"preset": "glass.frosted", "tint": "#EEF3F6", "lo": "#7C8E9C", "hi": "#FFFFFF",
                                "alpha": 1.0, "plate_ramp": (0.1, 0.15),
                                "pattern": ("Frosted", 1.5, 0.12, 1.0, 0.5, 0.5, 0.0)}},
            app=dict(display=dict(text="#F6BE5E", textDim="#8C6E3A", textAlt="#F6BE5E"),
                     ui=dict(text="#2A1218", textDim="#6B4A52", accent="#B01E2E"),
                     chrome=dict(label="#5A3A42", labelActive="#2A1218", icon="#5A3A42", iconActive="#B01E2E",
                                 gear="#5A3A42CC", meatballIdle="#5A3A42", meatballLit="#B01E2E"),
                     tracks=dict(text="#2A1218", ruler="#4A2A32E6", playhead="#2A1218E6", rowWithSample="#C4D8CB"),
                     ink=dict(faceplate="#2A1218", faceplateDim="#6B4A52", inset="#17301F", insetDim="#46604E",
                              backplane="#2A1218", backplaneDim="#6B4A52", socket="#17301F", socketDim="#46604E",
                              reviewBar="#2A1218", reviewBarDim="#6B4A52"))),
    },
)

if __name__ == "__main__":
    sys.exit(main(LOOK))
