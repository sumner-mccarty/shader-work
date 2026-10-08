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
from lookkit import Look, main, grad, gcol, mix  # noqa: E402

RED = "#D5202B"
ANOD = "#C8141F"        # the anodising: a deeper red than the lamps/ON states, so its highlights have room
YELLOW = "#FFC51A"
CONTROLS = dict(                     # the hardware — identical in both modes
    BODY="#23262B", BODY_HI="#34383F", BODY_LO="#15171A", DIS_BODY="#3A3D42",
    MARK="#E4E7EB", MARK_DIM="#8A929B", DIS_MARK="#5C6169", ON_MARK="#FFF4E6",
    ACCENT=RED, SOLO=YELLOW, LAMP=YELLOW, LAMP_OFF="#6F6230", HOT="#FF4A3A",
    CAP="#B9BEC4", SKIRT=ANOD, NUB=RED, HANDLE="#B9BEC4",
    VALUE=YELLOW, VALUE_EM=0.1, TRACK="#0B0C0E", ARC_OFF="#08090B",
    SCROLL="#2A2D32", SCROLL_HI="#8B929B", ACCENT_HI="#F0505B", ACCENT_LO="#8A0E17", PAD_BODY="#2B2E33", PAD_TINT=0.6, PAD_HOVER_EM=0.3, PAD_PRESS_EM=0.72,
)
# the racing stripe: ONE smooth crimson band behind the tracks (a Linear gradient ping-pongs, so scale 2.4 /
# offset -0.05 gives a single solid band ~28% of the plate high with soft smoothstep edges, centred a
# little below the middle so the track labels stay on the plate); stops A/B are transparent, C/D crimson,
# so the plate's own colour shows either side in either mode and the band wears the same crimson as the skirts
STRIPE = {
    "_PanelGradientEnabled": 1, "_PanelGradientType": 0, "_PanelGradientDirection": (0.0, 1.0, 0.0, 0.0),
    "_PanelGradientScale": 2.4, "_PanelGradientOffset": -0.05, "_PanelGradientSpeed": 0.0,
    "_PanelGradientColorA": ANOD + "00", "_PanelGradientColorB": ANOD + "00",
    "_PanelGradientColorC": ANOD + "FF", "_PanelGradientColorD": ANOD + "FF", "_PanelGradientColorUsed": 4,
}
# a lit crimson key (Mute ON): the carbon ramp would pull its top stop to hot pink, so it gets its own
_c = "#D01A26"
CRIMSON_ON = dict({"_ButtonColor": _c}, **gcol("_Button", (mix(_c, "#000000", 0.3), _c, mix(_c, "#FF9A92", 0.12),
                                                           mix(_c, "#FF9A92", 0.25))))
# the Face plate: a soft clear-coat sheen sweeping corner to corner (what makes black weave read as
# GLOSSY carbon at a glance), and four Torx cap screws in the corners — motorsport fasteners
def faceplate(sheen):
    return dict(grad("_Panel", sheen, (0.5, 0.5)),
                _PanelScrewsEnabled=1, _PanelScrewShapeType=3, _PanelScrewInsetPx=8.0, _PanelScrewRadiusPx=4.2,
                _PanelScrewColor="#B9BEC4", _PanelScrewSlotColor="#1A1C1F", _PanelScrewRotation=-24,
                _PanelScrewDepth=0.7, _PanelScrewMetallic=0.95, _PanelScrewBore=0.5)


def puck(px, cell=7.0):
    """A carbon-weave dish behind the dial (the Fill layer): the weave is a cycle count across the
    widget, so its scale follows the dial's real pixel size (`cell` px per weave cell)."""
    return {"_FillEnabled": 1, "_FillColor": "#1B1D21", "_FillRenderAlpha": 1.0, "_FillRenderEmissive": 0.0,
            "_FillBevelEnabled": 0, "_FillRimEnabled": 0, "_FillFaceSmoothness": 0.0,
            "_FillPatternEnabled": 1, "_FillPatternType": 3, "_FillPatternScale": round(px / (cell * 5.0), 2),
            "_FillPatternIntensity": 0.7, "_FillPatternContrast": 1.0, "_FillPatternSpecularEffect": 0.9,
            "_FillPatternRoughnessEffect": 0.3, "_FillPatternParam1": 0.5, "_FillPatternParam2": 1.0,
            "_FillPatternParam3": 0.0}


WEAVE = 30.0          # CarbonFiber: grain / 5 = px per weave cell (6 px) — reads at 1:1 and at half size
CARBON_PLATE = {"preset": "carbon", "plate_ramp": (0.12, 0.3), "plate_amb": 0.8,
                "pattern": ("CarbonFiber", WEAVE, 0.55, 1.0, 0.5, 1.0, 0.0), "spec": 0.9, "rough": 0.3}
ANODISED = {"preset": "aluminium.brushed", "tint": ANOD, "lo": "#2A0508", "hi": "#EC4650",
            "ramp": (-0.5, -0.1, 0.3, 0.65), "edge": (0.6, 0.3, -0.25, -0.55), "amb": 0.6,
            "pattern": ("Knurled", 3.0, 0.3, 1.0, 0.5, 0.6, 0.5), "spec": 0.7, "rough": 0.2}
# the light chassis: smooth glazed white ceramic composite — NO weave (the preset's own Ceramic pattern is a
# zig-zag tile and a paper/plaster/frost texture reads as concrete; both were tried and rejected)
CERAMIC = {"preset": "ceramic", "plate_ramp": (0.1, 0.12), "plate_amb": 0.9, "pattern": None, "spec": 0.5, "rough": 0.3}
GLOSS = dict(CARBON_PLATE, pattern=("CarbonFiber", 20.0, 0.4, 1.0, 0.5, 1.0, 0.0))     # the deep, fine, clear-coated weave

TRACK = {
    "_doc": "See Starfield.track.json for the format. Pit-lane signal flags on a black grid.",
    "name": "CarbonRace", "blurb": "A floodlit pit straight: signal-flag rows on a black grid.",
    "palette": {
        "row1": "#FF3340", "row2": "#FFC51A", "row3": "#4DB6FF", "row4": "#36E08A",
        "rail": "#FF3340", "laneLine": "#7A2028", "laneFill": "#050405", "hitLine": "#FFF2D6",
        "receptor": "#C9A24A", "gridBar": "#FF5A4A", "gridBeat": "#4A1A1E", "bgTop": "#030203",
        "bgBottom": "#0B0708", "fog": "#6A1A20", "star": "#FFD9A0", "miss": "#FF2A2A", "perfect": "#FFF2C2"},
    "props": {"skyMode": 7, "skyColorA": "#FF3340", "skyColorB": "#5A1018", "skyAmount": 0.8, "skyHorizon": 0.56,
              "starDensity": 0.0, "horizonGlow": 0.35, "gridBrightness": 1.1, "railGlow": 1.4, "noteGlow": 1.2,
              "noteCoreBrightness": 1.1, "additive": 0.4, "radiance": 1.05, "bedOpacity": 0.85, "fog": 0.5,
              "vignette": 0.5},
}

LOOK = Look(
    title="Carbon Race", style="CarbonRace", prefix="CarbonRace", slug="carbon-race", cls="lit", order=24,
    status="candidate", brief="BACKLOG.md#carbon-race",
    blurb="Carbon-fibre weave, red anodised collets, racing stripes and yellow warning lamps.",
    tagline="carbon weave, red anodised collets, racing stripes.",
    displays={**{k: "glass.amber" for k in ("glass.amber", "glass.cyan", "lcd.grey", "crt.phosphor", "plastic.blue",
                                          "flat", "waveform", "*")},
              "led.matrix.green": "led.matrix.amber", "led.matrix.amber": "led.matrix.amber"},
    shape={
        "key": dict(corner=0.3, round=0.3, bevel=0.14, depth=0.5, dome=0.2),
        "dial": dict(skirt="ColletKnob", skirt_count=12, skirt_depth=0.12, cap_r=0.58, bevel=0.2, depth=0.75,
                     smooth=0.3, dome=0.3, nub=0.075, nub_dist=0.38, arc_px=3.0),
        "Knob": dict(set=puck(56, 5.0)), "KnobHero": dict(ticks=11, arc_px=4.0, set=puck(112, 7.0)),
        "Bezel": dict(fill="SKIRT", recess=-0.25, radius_px=5.0, pad_px=0.0),
        "Face": dict(set=faceplate(("#121316", "#202328", "#383C44", "#16181C"))),
        "KnobSmall": dict(px=30, arc_px=2.4, nub=0.09, set=puck(30, 3.5)),
        "Fader": dict(set={"_TrackValueFilledColor": ANOD}),         # the gutter fader fill stays crimson
        "Back": dict(set=STRIPE),
        "shadow": dict(blur=1.3, cast=0.22),
        # a lit key is a lamp, not a woven tile: the weave steps back behind the glyph. Mute ON is crimson (not the
        # carbon-ramped hot pink); Solo/Lamp ON are yellow with a dark glyph (ON_MARK is the light glyph on red)
        "states": {
            "ToggleBtn": {"Active": dict(CRIMSON_ON, _ButtonPatternIntensity=0.12, _ButtonRenderEmissive=0.12)},
            "Solo": {"Active": {"_ButtonPatternIntensity": 0.12, "_ButtonRenderEmissive": 0.25, "_IconColor": "#14110A"}},
            "Lamp": {"Active": {"_ButtonPatternIntensity": 0.12, "_ButtonRenderEmissive": 0.25, "_IconColor": "#14110A"}},
            "Pad": {"Latched": {"_ButtonRenderEmissive": 0.52}},
            # Hover over ON lifts the lit handle (a lighter crimson) instead of repeating ON
            "Pill": {"Hover": {"_LedColor": "#FF6A74"}},
        },
    },
    material={
        "plate": CARBON_PLATE,
        "key": {"preset": "carbon", "edge": "aluminium.brushed", "amb": 1.0,
                "pattern": ("CarbonFiber", 24.0, 0.65, 1.0, 0.5, 1.0, 0.0)},
        "accent": dict(ANODISED, edge="aluminium.brushed", matcap=("satin", 0.3), dome=0.1, amb=1.1,
                       ramp=(-0.15, 0.1, 0.35, 0.55), pattern=("Metal", 1.0, 0.1, 1.0, 0.5, 0.0, 0.0)),
        # a turned collet top: a nearly flat disc with radial machining and one soft highlight (dome 0.3 + a weak
        # satin matcap) instead of the chrome-ball horizon a strong matcap on a 0.5 dome drew
        "cap": {"preset": "aluminium.brushed", "amb": 1.0, "dome": 0.3, "matcap": ("satin", 0.4),
                "pattern": ("RadialBrushed", 3.0, 0.28, 1.0, 0.45, 0.2, 0.85)},
        "skirt": ANODISED,
        "Bezel": dict(ANODISED, plate_ramp=(0.3, 0.42), plate_amb=0.9, texture=("brushed_fine", 90, 0.7, 1.0, 0.0, 0.0)),
        "Inset": GLOSS, "Socket": dict(CARBON_PLATE, pattern=("CarbonFiber", 26.0, 0.5, 1.0, 0.5, 1.0, 0.0)),
        # a long thin grip: a widget-relative weave would smear into rungs, so it wears a brushed streak
        "ScrollHandle": {"preset": "carbon", "edge": "aluminium.brushed", "amb": 1.0,
                         "texture": ("brushed_fine", 60, 0.45, 1.0, 0.0, 0.0)},
        # the backplane weave steps right back: it lies under the crimson band and aliased at 1:1 at 0.55
        "Back": dict(CARBON_PLATE, pattern=("CarbonFiber", WEAVE, 0.2, 1.0, 0.5, 1.0, 0.0)),
        "handle": {"preset": "aluminium.brushed", "amb": 1.0},
        "Slider": {"preset": "carbon", "edge": "aluminium.brushed", "amb": 1.0,
                   "pattern": ("CarbonFiber", 6.0, 0.6, 1.0, 0.5, 1.0, 0.0)},
    },
    track_themes={"CarbonRace": TRACK},
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
            track="CarbonRace", blurb="Carbon tub, red anodised hardware, one hard lamp.",
            palette=dict(CONTROLS, GAP="#07080A", BACK="#16181C", FACE="#1D1F24", INSET="#131417", SOCKET="#0F1012",
                         WELL="#07090B", SHADOW="#000000", SHADOW_A=0.6, WELL_EM=0.05),
            app=dict(display=dict(text=YELLOW, textDim="#B8941F", textAlt=YELLOW),
                     key=dict(soloOn="#14110A"), ui=dict(accent=RED))),
        "light": dict(
            track="CarbonRace", blurb="White ceramic-composite chassis, same carbon and red hardware.",
            palette=dict(CONTROLS, GAP="#A9AEB4", BACK="#DDE0E3", FACE="#F3F3F0", INSET="#E6E8E5", SOCKET="#D2D5D6",
                         WELL="#0A0C0E", SHADOW="#2C3036", SHADOW_A=0.35, WELL_EM=0.05, AMB_PLATE=0.9),
            set={"Face": grad("_Panel", ("#E4E5E1", "#F0F0EC", "#F9F9F6", "#E9EAE6"), (0.5, 0.5))},
            material={"plate": CERAMIC, "Inset": CERAMIC, "Socket": CERAMIC, "Back": CERAMIC},
            app=dict(display=dict(text=YELLOW, textDim="#B8941F", textAlt=YELLOW), key=dict(soloOn="#14110A"),
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
