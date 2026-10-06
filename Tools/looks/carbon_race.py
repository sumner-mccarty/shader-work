"""Carbon Race — motorsport cockpit (lit). Brief: Looks/BACKLOG.md#carbon-race.

    python Tools/looks/carbon_race.py check | sheet | write | manifest | printcheck

Signature: carbon weave + red anodised. Every family wears the weave (plates, keys, slider handles,
switch handle, the knob skirt's inlay) and every family carries red anodised or a yellow warning mark:
red anodised collet skirts under machined-aluminium caps, a red/carbon racing stripe down the
backplane, yellow warning lamps. Light mode changes the CHASSIS only: white ceramic-composite
plates with a faint pale weave; the hardware (carbon keys, red knobs) is identical.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from lookkit import Look, main  # noqa: E402

RED = "#D5202B"
YELLOW = "#FFC51A"
CONTROLS = dict(                     # the hardware — identical in both modes
    BODY="#23262B", BODY_HI="#34383F", BODY_LO="#15171A", DIS_BODY="#3A3D42",
    MARK="#E4E7EB", MARK_DIM="#8A929B", DIS_MARK="#5C6169", ON_MARK="#14110A",
    ACCENT=RED, SOLO=YELLOW, LAMP=YELLOW, LAMP_OFF="#6F6230", HOT="#FF4A3A",
    CAP="#B9BEC4", SKIRT=RED, NUB=RED, HANDLE="#B9BEC4",
    VALUE=YELLOW, VALUE_EM=0.3, TRACK="#0B0C0E", ARC_OFF="#08090B",
    SCROLL="#2A2D32", SCROLL_HI="#D5202B", PAD_BODY="#2B2E33", PAD_TINT=0.6,
)
# racing stripes: two red bands along the backplane (Triangle gradient, 2 periods), the carbon between
# is transparent so the plate's own colour + weave shows in either mode
STRIPE = {
    "_PanelGradientEnabled": 1, "_PanelGradientType": 4, "_PanelGradientDirection": (0.0, 1.0, 0.0, 0.0),
    "_PanelGradientScale": 2.0, "_PanelGradientOffset": 0.0, "_PanelGradientSpeed": 0.0,
    "_PanelGradientColorA": RED + "00", "_PanelGradientColorB": RED + "00",
    "_PanelGradientColorC": RED + "FF", "_PanelGradientColorD": RED + "FF", "_PanelGradientColorUsed": 4,
}
def puck(px):
    """A carbon-weave dish behind the dial (the Fill layer): the weave is a cycle count across the
    widget, so its scale follows the dial's real pixel size (3 px per sine period)."""
    return {"_FillEnabled": 1, "_FillColor": "#1B1D21", "_FillRenderAlpha": 1.0, "_FillRenderEmissive": 0.0,
            "_FillBevelEnabled": 0, "_FillRimEnabled": 0, "_FillFaceSmoothness": 0.0,
            "_FillPatternEnabled": 1, "_FillPatternType": 3, "_FillPatternScale": round(px / 15.0, 2),
            "_FillPatternIntensity": 0.7, "_FillPatternContrast": 1.0, "_FillPatternSpecularEffect": 0.9,
            "_FillPatternRoughnessEffect": 0.3, "_FillPatternParam1": 0.5, "_FillPatternParam2": 1.0,
            "_FillPatternParam3": 0.0}


CARBON_PLATE = {"preset": "carbon", "plate_ramp": (0.12, 0.3), "plate_amb": 0.8,
                "pattern": ("CarbonFiber", 15.0, 0.6, 1.0, 0.5, 1.0, 0.0), "spec": 0.9, "rough": 0.3}
ANODISED = {"preset": "aluminium.brushed", "tint": RED, "lo": "#2A0508", "hi": "#FF9A92",
            "ramp": (-0.55, -0.1, 0.2, 0.5), "edge": (0.6, 0.3, -0.25, -0.55), "amb": 0.6,
            "pattern": ("Knurled", 3.0, 0.14, 1.0, 0.5, 0.6, 0.5), "spec": 0.7, "rough": 0.2}

LOOK = Look(
    title="Carbon Race", style="CarbonRace", prefix="CarbonRace", slug="carbon-race", cls="lit", order=24,
    status="draft", brief="BACKLOG.md#carbon-race",
    blurb="Carbon-fibre weave, red anodised collets, racing stripes and yellow warning lamps.",
    tagline="carbon weave, red anodised collets, racing stripes.",
    displays="tron",
    shape={
        "key": dict(corner=0.3, round=0.3, bevel=0.14, depth=0.5, dome=0.2),
        "dial": dict(skirt="ColletKnob", skirt_count=12, skirt_depth=0.12, cap_r=0.58, bevel=0.2, depth=0.5,
                     smooth=0.6, dome=0.5, nub=0.075, nub_dist=0.38, arc_px=3.0),
        "Knob": dict(set=puck(56)), "KnobHero": dict(ticks=11, arc_px=4.0, set=puck(112)),
        "KnobSmall": dict(px=30, arc_px=2.4, nub=0.09, set=puck(30)),
        "Back": dict(set=STRIPE),
        "shadow": dict(blur=1.3, cast=0.22),
    },
    material={
        "plate": CARBON_PLATE,
        "key": {"preset": "carbon", "edge": "aluminium.brushed", "amb": 1.0,
                "pattern": ("CarbonFiber", 15.0, 0.6, 1.0, 0.5, 1.0, 0.0)},
        "accent": {"preset": "enamel", "tint": RED, "edge": "aluminium.brushed"},
        "cap": {"preset": "aluminium.brushed", "amb": 1.0, "dome": 0.5,
                "pattern": ("RadialBrushed", 3.0, 0.12, 1.0, 0.45, 0.2, 0.0)},
        "skirt": ANODISED,
        "handle": {"preset": "aluminium.brushed", "amb": 1.0},
        "Slider": {"preset": "carbon", "edge": "aluminium.brushed", "amb": 1.0,
                   "pattern": ("CarbonFiber", 6.0, 0.6, 1.0, 0.5, 1.0, 0.0)},
    },
    rig={
        "dark": {"light1": dict(pos=[-0.4, 1.5], height=1.2, color="#FFF4E6", intensity=0.95, specular=0.35,
                                specularPower=40),
                 "light2": dict(pos=[1.3, 0.6], height=0.9, color="#BFD4FF", intensity=0.25, specular=0.08),
                 "light3": dict(enabled=False)},
        "light": {"light1": dict(pos=[-1.5, 3.0], height=4.0, color="#FFFFFF", intensity=0.8, specular=0.12,
                                 specularPower=40),
                  "light2": dict(enabled=False), "light3": dict(enabled=False)},
    },
    modes={
        "dark": dict(
            track="Nebula", blurb="Carbon tub, red anodised hardware, one hard lamp.",
            palette=dict(CONTROLS, GAP="#07080A", BACK="#16181C", FACE="#24272D", INSET="#1B1D21", SOCKET="#1B1D21",
                         WELL="#07090B", SHADOW="#000000", SHADOW_A=0.6, WELL_EM=0.05),
            app=dict(display=dict(text=YELLOW, textDim="#8C7220", textAlt=YELLOW),
                     ui=dict(accent=RED))),
        "light": dict(
            track="Rosewater", blurb="White ceramic-composite chassis, same carbon and red hardware.",
            palette=dict(CONTROLS, GAP="#A9AEB4", BACK="#DDE0E3", FACE="#F3F3F0", INSET="#E2E4E1", SOCKET="#DADCDA",
                         WELL="#0A0C0E", SHADOW="#2C3036", SHADOW_A=0.35, WELL_EM=0.05, AMB_PLATE=0.9),
            material={"plate": {"preset": "ceramic", "plate_ramp": (0.1, 0.12), "plate_amb": 0.9,
                                "pattern": ("CarbonFiber", 15.0, 0.14, 1.0, 0.5, 1.0, 0.0), "spec": 0.5, "rough": 0.3}},
            app=dict(display=dict(text=YELLOW, textDim="#8C7220", textAlt=YELLOW),
                     ui=dict(text="#15171A", textDim="#555B63", accent="#C41B26"),
                     chrome=dict(label="#444A52", labelActive="#15171A", icon="#444A52", iconActive="#C41B26",
                                 gear="#444A52CC", meatballIdle="#444A52", meatballLit="#C41B26"),
                     tracks=dict(text="#15171A", ruler="#444A52E6", playhead="#15171AE6", rowWithSample="#B9BEC4"),
                     ink=dict(faceplate="#15171A", faceplateDim="#555B63", inset="#15171A", insetDim="#555B63",
                              backplane="#15171A", backplaneDim="#555B63", socket="#15171A", socketDim="#555B63",
                              reviewBar="#15171A", reviewBarDim="#555B63"))),
    },
)

if __name__ == "__main__":
    sys.exit(main(LOOK))
