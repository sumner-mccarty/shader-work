"""Lunar Red — red lacquer, gold hardware, jade ON (lit, seasonal: lunar new year).
Brief: Looks/BACKLOG.md#lunar-red.

    python Tools/looks/lunar_red.py check | sheet | write | manifest | printcheck

Signature: deep vermilion LACQUER plates (a soft sheen rising to the top), gold hardware — a polished-gold "coin" cap with a lacquer-red square-ish mark, a finely
fluted gold rim, gold chamfers on every red key — and jade green for ON (accent key, value arc,
switch). Cloud-scroll contours animate the menu field. Reference, not costume: no lettering, no
characters. Light mode changes the chassis to warm rice-paper and rose; the red-and-gold hardware
and jade are identical.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from lookkit import Look, main, gcol, grad  # noqa: E402

JADE = "#2F8F6A"          # deep, slightly milky jade
JADE_LIT = "#3E9E78"          # value arc / lamp: true jade, not mint
JADE_HI = "#58B890"
RED_KEY = "#6E0A10"
CONTROLS = dict(                     # the hardware — identical in both modes
    BODY=RED_KEY, BODY_HI="#92131B", BODY_LO="#2E0408", DIS_BODY="#2C1214",
    MARK="#F3D98A", MARK_DIM="#C9A24C", DIS_MARK="#6B4A44", ON_MARK="#031F15",
    ACCENT=JADE, ACCENT_HI="#3AA67D", ACCENT_LO="#175A42", ACCENT_DIS="#2A3A32",
    SOLO="#CF9A26", LAMP=JADE_HI, LAMP_OFF="#8A6A34", HOT="#FF6A4A",
    CAP="#C99A2E", SKIRT="#C99A2E", NUB="#120405", HANDLE="#C99A2E",
    VALUE=JADE_LIT, VALUE_EM=0.15, TRACK="#0E0905", ARC_OFF="#2B1A0A",
    SCROLL="#7A1018", SCROLL_HI="#D9A93A", PAD_BODY="#4A0C10", PAD_TINT=0.72, PAD_HOVER_EM=0.4, PAD_PRESS_EM=0.3,
)
RED_KEY_MAT = {"preset": "lacquer.black", "edge": "gold.polished", "amb": 0.8}

# window-lattice FRIEZE: a px-locked DiamondPlate pattern (28 px pitch) painted in real gold (palette mode 0 =
# replace: dark ground / gold shadow / gold highlight). An InnerFrame layer of plain lacquer covers the interior
# of the Face, so the lattice shows only as a gold inlay band round the plate edge, inside the gold line.
LATTICE = ("DiamondPlate", 28.0, 1.0, 2.0, 0.0, 0.0, 0.0)
FRIEZE = 0.9             # InnerFrame size: fraction of the half short side left to the lattice band


def frieze_set(ground, gold_lo, gold_hi, face, band):
    d = {"_PanelPatternColorEnabled": 1, "_PanelPatternColorType": 1, "_PanelPatternColorMode": 0,
         "_PanelPatternColorUsed": 4, "_PanelPatternColorA": ground, "_PanelPatternColorB": ground,
         "_PanelPatternColorC": gold_lo, "_PanelPatternColorD": gold_hi,
         "_InnerFrameEnabled": 1, "_InnerFrameColor": face, "_InnerFrameSize": FRIEZE,
         "_InnerFrameShapeEnabled": 0, "_InnerFrameRenderAlpha": 1.0, "_InnerFrameRenderEmissive": 0.0}
    d.update(gcol("_Panel", band))
    d.update(grad("_InnerFrame", band, (0.0, 1.0)))
    return d


SOLO_ACTIVE = {"Active": {"_ButtonRenderEmissive": 0.06, "_IconRenderEmissive": 0.3, "_BorderEnabled": 1,
                         "_BorderColor": "#6E4A0C", "_BorderWidth": 0.04}}

LOOK = Look(
    title="Lunar Red", style="LunarRed", prefix="LunarRed", slug="lunar-red", cls="lit", order=40,
    status="rejected", brief="BACKLOG.md#lunar-red",
    blurb="Red lacquer, gold coin knobs and jade for ON. Lunar new year.",
    tagline="vermilion lacquer, gold hardware, jade for ON.",
    displays="neo",
    shape={
        "key": dict(corner=0.4, round=0.4),
        # a gold coin: fine milled rim (Fluted x36), a big domed face and a squircle mark
        "dial": dict(skirt="Fluted", skirt_count=36, skirt_depth=0.05, cap_r=0.68, bevel=0.17, depth=0.5,
                     smooth=0.6, dome=0.6, nub=0.085, nub_dist=0.4, arc_px=3.0,
                     set={"_KnobNubShapeType": 5}),   # Squircle mark: the coin's square hole
                "KnobHero": dict(ticks=11, arc_px=4.0, nub=0.12, stitch=(0.7, 0.055, "#7A0A12")),   # a ring of lacquer beads round the coin
        "plate": dict(stitch=("#C9993A", 1.3)),   # thin gold inlay line round the plate edge
        "Inset": dict(recess=-0.45),
        "shadow": dict(blur=1.5, cast=0.24),
    },
    material={
        "plate": {"preset": "lacquer.black", "lo": "#1A0003", "hi": "#FF5A3C", "plate_ramp": (0.38, 0.42), "linear": LATTICE,
                  "spec": 1.2, "rough": 0.02},
        "Inset": {"preset": "lacquer.black", "lo": "#120002", "hi": "#B03020", "plate_ramp": (0.3, 0.2)},
        "Socket": {"preset": "lacquer.black", "lo": "#0C0001", "hi": "#8A2418", "plate_ramp": (0.3, 0.15)},
        "Bezel": {"preset": "lacquer.black", "lo": "#120002", "hi": "#B03020", "plate_ramp": (0.3, 0.2)},
        "Back": {"preset": "lacquer.black", "lo": "#1A0003", "hi": "#FF5A3C", "plate_ramp": (0.38, 0.42)},
        "key": RED_KEY_MAT,
        "accent": {"preset": "ceramic", "tint": JADE, "edge": "gold.polished", "amb": 0.7, "spec": 0.7,
                   "rough": 0.25, "lo": "#06281C", "hi": "#BFEBD6", "matcap": ("pearl", 0.35)},
        "cap": {"preset": "gold.polished", "amb": 0.9, "ramp": (-0.45, 0.05, 0.45, 0.85)},
        "skirt": {"preset": "gold.brushed", "pattern": ("Knurled", 3.0, 0.2, 1.0, 0.5, 0.6, 0.5)},
        "handle": {"preset": "gold.polished", "amb": 0.95},
    },
    rig={
        "dark": {"light1": dict(pos=[-0.4, 1.5], height=1.3, color="#FFE2B4", intensity=0.15, specular=0.4,
                                specularPower=48),
                 "light2": dict(pos=[1.3, 0.6], height=0.9, color="#FFB0A0", intensity=0.03, specular=0.06),
                 "light3": dict(enabled=False)},
        "light": {"light1": dict(pos=[-1.5, 3.0], height=4.0, color="#FFF0D8", intensity=0.15, specular=0.15,
                                 specularPower=48),
                  "light2": dict(enabled=False), "light3": dict(enabled=False)},
    },
    track_themes={
        "LunarLacquer": {
            "_doc": "Lunar Red highway. See Starfield.track.json for the format.",
            "name": "LunarLacquer", "blurb": "Vermilion, jade and gold leaf on oxblood lacquer.",
            "palette": {
                "row1": "#FF4A30", "row2": "#2FB583", "row3": "#F2C24A", "row4": "#D9304A",
                "rail": "#D9A93A", "laneLine": "#6A1A1E", "laneFill": "#110304", "hitLine": "#FFF1D0",
                "receptor": "#E8C070", "gridBar": "#C9A227", "gridBeat": "#4A1216", "bgTop": "#140304",
                "bgBottom": "#2E0709", "fog": "#8A1A1E", "star": "#FFE0A0", "miss": "#FF3A2A",
                "perfect": "#FFE9A8"},
            "props": {"skyMode": 6, "skyColorA": "#5A0A10", "skyColorB": "#D9A93A", "skyAmount": 0.7,
                      "skyScale": 2.4, "starDensity": 0.0, "horizonGlow": 0.4, "railGlow": 1.0,
                      "noteGlow": 0.95, "additive": 0.22, "radiance": 0.95, "beatPulse": 0.6, "fog": 0.5,
                      "vignette": 0.5}},
    },
    modes={
        "dark": dict(
            track="LunarLacquer", blurb="Vermilion lacquer, gold coins, jade glow.",
            palette=dict(CONTROLS, GAP="#1A0305", BACK="#42060B", FACE="#A8141C", INSET="#380509", SOCKET="#240305",
                         WELL="#0A0203", SHADOW="#0A0000", SHADOW_A=0.6, WELL_EM=0.05),
            set={"Face": frieze_set("#6E0E0E", "#8A5A1C", "#D8A848", "#A8141C", ("#6E0E0E", "#A8141C", "#EE5238", "#B0161C")),
                 "Back": gcol("_Panel", ("#240306", "#42060B", "#7E2218", "#4C0A0E")),
                 "Inset": gcol("_Panel", ("#2A0405", "#380509", "#7A241C", "#4A0A0E")),
                 "Socket": gcol("_Panel", ("#0E0102", "#240305", "#521810", "#2C0508"))},
            states={"Solo": SOLO_ACTIVE, "Pad": {"Latched": {"_BorderEnabled": 1, "_BorderColor": "#D8A848", "_BorderWidth": 0.05,
                                        "_BorderRenderEmissive": 0.35, "_ButtonRenderEmissive": 0.3,
                                        **grad("_Border", ("#7A5410", "#F2CC66", "#A87A22"), (0.0, 1.0))},
                            "Disabled": {"_ButtonRenderAlpha": 0.7, "_ButtonBevelDepth": 0.0,
                                         "_ButtonFaceSmoothness": 0.0, "_ButtonRenderEmissive": 0.0}}},
            fields={
                "accent": {"shader": "Ribbons", "params": {"_Speed": 0.03, "_Base": "#3A070C", "_ColorA": "#B3141E",
                                                           "_ColorB": "#D9A93A", "_ColorC": "#7A0D14",
                                                           "_ColorD": "#1E9A6E", "_Opacity": 0.8, "_Contrast": 0.9}},
                "menu": {"shader": "Contours", "params": {"_Speed": 0.02, "_LineColor": "#E3B854",
                                                          "_LineStrength": 0.45, "_ColorA": "#2A0508",
                                                          "_ColorB": "#3E070C", "_ColorC": "#52090F",
                                                          "_ColorD": "#650C13"}},
            },
            app=dict(display=dict(text="#F5D77A", textDim="#9A7A3A", textAlt="#5BE8B0"),
                     ui=dict(accent="#46E0A4"))),
        "light": dict(
            track="LunarLacquer", blurb="Warm rice paper and rose, the same lacquer-red keys and gold.",
            palette=dict(CONTROLS, GAP="#B59A86", BACK="#D9C4B0", FACE="#EFE2CC", INSET="#EAD3BA", SOCKET="#E2C8AC",
                         WELL="#100606", SHADOW="#3A1A14", SHADOW_A=0.35, WELL_EM=0.05, AMB_PLATE=0.88),
            material={"plate": {"preset": "lacquer.black", "tint": "#EFE2CC", "lo": "#7A5A46", "hi": "#FFFFFF",
                                "plate_ramp": (0.1, 0.2), "linear": LATTICE},
                      "Inset": {"preset": "lacquer.black", "tint": "#EAD3BA", "lo": "#A87E5A", "hi": "#FFF4E0", "plate_ramp": (0.12, 0.15)},
                      "Socket": {"preset": "lacquer.black", "tint": "#E2C8AC", "lo": "#A07852", "hi": "#FFF0D8", "plate_ramp": (0.12, 0.15)},
                      "Back": {"preset": "lacquer.black", "tint": "#D9C4B0", "lo": "#7A5A46", "hi": "#FFFFFF", "plate_ramp": (0.1, 0.2)},
                      "Bezel": {"preset": "lacquer.black", "tint": "#E2C8AC", "lo": "#A07852", "hi": "#FFF0D8", "plate_ramp": (0.12, 0.15)}},
            set={"Face": frieze_set("#D4BE92", "#8A6420", "#B88C34", "#E6D5B4", ("#CDB892", "#E6D5B4", "#F2E6CC", "#E0D0B0")),
                 "Back": gcol("_Panel", ("#C8AE92", "#D9C4B0", "#EBDCC6", "#D2BCA0"))},
            states={"Solo": SOLO_ACTIVE, "Pad": {"Latched": {"_BorderEnabled": 1, "_BorderColor": "#C9922E", "_BorderWidth": 0.05,
                                        "_BorderRenderEmissive": 0.2, "_ButtonRenderEmissive": 0.2,
                                        **grad("_Border", ("#6A480C", "#E8BC50", "#9A6E1C"), (0.0, 1.0))},
                            "Disabled": {"_ButtonRenderAlpha": 0.8, "_ButtonBevelDepth": 0.0,
                                         "_ButtonFaceSmoothness": 0.0, "_ButtonRenderEmissive": 0.0}}},
            fields={
                "accent": {"shader": "Ribbons", "params": {"_Speed": 0.03, "_Base": "#E8D5BC", "_ColorA": "#C8363C",
                                                           "_ColorB": "#E3B854", "_ColorC": "#D88A7A",
                                                           "_ColorD": "#5BBF9A", "_Opacity": 0.7}},
                "menu": {"shader": "Contours", "params": {"_Speed": 0.02, "_LineColor": "#A5131B",
                                                          "_LineStrength": 0.4, "_ColorA": "#EBDAC2",
                                                          "_ColorB": "#E6D2B8", "_ColorC": "#E0CAAE",
                                                          "_ColorD": "#DAC1A4"}},
            },
            app=dict(display=dict(text="#F5D77A", textDim="#9A7A3A", textAlt="#5BE8B0"),
                     ui=dict(text="#3A1410", textDim="#7A5446", accent="#0F7A55"),
                     chrome=dict(label="#7A1A1E", labelActive="#3A1410", icon="#7A1A1E", iconActive="#3A1410"),
                     tracks=dict(text="#3A1410", rowWithSample="#D9B9A0"),
                     ink=dict(faceplate="#3A1410", faceplateDim="#7A5446", inset="#3A1410", insetDim="#7A5446",
                              backplane="#3A1410", backplaneDim="#7A5446", socket="#3A1410", socketDim="#7A5446",
                              reviewBar="#3A1410", reviewBarDim="#7A5446"))),
    },
)

if __name__ == "__main__":
    sys.exit(main(LOOK))
