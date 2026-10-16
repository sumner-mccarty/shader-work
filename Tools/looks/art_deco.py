"""Gatsby Deco — black enamel, real gold lines, cream lamps (lit). Brief: Looks/BACKLOG.md#art-deco.

    python Tools/looks/art_deco.py check | sheet | write | manifest | printcheck

Signature: 1920s deco GEOMETRY. Every key, lamp and plate is an OCTAGON — stepped, chamfered corners
(Octagon shape type; plates pin the cut in canvas px) — framed by a hairline of polished gold inlay.
Knobs are faceted octagonal gold bezels around a black-enamel face with an ivory dot and an ivory value
arc. Gold is METAL: polished-gold ramp + polished matcap, and each facet of the octagonal bezel catches
the key lamp differently, so the highlight moves round the knob. Deep teal enamel is the second note
(keys, the ON accent), cream is the lamp. Reference, not costume: no lettering, no characters.
Light mode changes the CHASSIS to ivory enamel; the black-teal-gold controls are identical.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from lookkit import Look, main, MATERIALS, gcol, ramp_of, toward  # noqa: E402

# a gold CHAMFER ramp: bright at the top edge (a plain "gold.polished" string edge uses the body ramp, which is lit
# from below on a key), so the lamp catches the top rim exactly like the knob crowns
MATERIALS["gold.edge"] = dict(MATERIALS["gold.polished"], ramp=(0.85, 0.5, -0.35, -0.7))
_G = MATERIALS["gold.polished"]
GOLD_FILL = ramp_of(_G)                                                   # polished-gold body (Solo on, scroll hover)
EDGE_HOVER = tuple(toward(_G["base"], _G["lo"], _G["hi"], a) for a in (1.0, 0.8, 0.0, -0.45))
EDGE_CREAM = tuple(toward("#E8CF8C", _G["lo"], "#FFF6DA", a) for a in (1.0, 0.85, 0.2, -0.3))

GOLD = "#C99A3A"
TEAL = "#0F3B3B"
BLACK = "#0A1012"
EMERALD = "#12805C"
CREAM = "#F6EBC8"
CONTROLS = dict(                     # the hardware — identical in both modes
    BODY=BLACK, BODY_HI="#22302F", BODY_LO="#020404", DIS_BODY="#151B1B",
    MARK="#F3E6BE", MARK_DIM="#B79B58", DIS_MARK="#4A5048", ON_MARK="#F9F1D8",
    ACCENT=EMERALD, ACCENT_HI="#1A9C72", ACCENT_LO="#0A4A35", ACCENT_DIS="#25332E",
    SOLO="#C99A3A", LAMP="#F1DC9C", LAMP_OFF="#7C6B42", HOT="#D9573F",
    CAP="#0B1113", SKIRT=GOLD, NUB=CREAM, HANDLE=GOLD,
    VALUE="#EFE0B2", VALUE_EM=0.15, TRACK="#050808", ARC_OFF="#1E2A2A",
    SCROLL="#1C2B2B", SCROLL_HI=GOLD, PAD_BODY="#101A1A", PAD_TINT=0.7,
)
TEAL_KEY = {"preset": "lacquer.black", "tint": BLACK, "edge": "gold.edge", "amb": 0.85, "spec": 0.95, "rough": 0.05,
            "matcap": ("gloss_coat", 0.9), "dome": 0.32}
OCT = dict(shape=4, corner=0.85, round=0.25)

DIAL_SET = {"_KnobShapeParam2": 0.0, "_KnobNubShapeType": 4, "_KnobNubShapeScale": 4,
            "_KnobNubShapeParam1": 0.55, "_KnobNubShapeParam2": 0.0}


def ring(th):
    return {"_OuterRing1Enabled": 1, "_OuterRing1Radius": 0.7, "_OuterRing1Thickness": th,
            "_OuterRing1Color": GOLD, "_OuterRing1AngleStart": 0, "_OuterRing1AngleRange": 360,
            "_OuterRing1Style": 0, "_OuterRing1RenderAlpha": 1.0, "_OuterRing1RenderEmissive": 0.0}


SUNBURST = {"_PanelPatternEnabled": 1, "_PanelPatternType": 2, "_PanelPatternScale": 12.0,
            "_PanelPatternIntensity": 0.9, "_PanelPatternContrast": 1.0, "_PanelPatternParam1": 1.0,
            "_PanelPatternParam2": 0.0, "_PanelPatternParam3": 0.0, "_PanelPatternSpecularEffect": 0.0,
            "_PanelPatternRoughnessEffect": 0.0, "_PanelPatternColorEnabled": 1, "_PanelPatternColorType": 1,
            "_PanelPatternColorMode": 2, "_PanelPatternColorUsed": 2,
            "_PanelPatternColorA": "#000000", "_PanelPatternColorB": "#4D3A12"}

TRACK = {
    "name": "GatsbyDeco", "blurb": "Black enamel, jade, brass and ivory. Nineteen-twenties jewel tones.",
    "palette": {"row1": "#E6DAB6", "row2": "#2BA27E", "row3": "#C79A3C", "row4": "#2F7F8C",
                "rail": "#C99A3A", "laneLine": "#28403E", "laneFill": "#040808", "hitLine": "#FFF4D6",
                "receptor": "#B9A36A", "gridBar": "#9CB6AE", "gridBeat": "#1E3634", "bgTop": "#030707",
                "bgBottom": "#0A1514", "fog": "#1F5A52", "star": "#EADFB8", "miss": "#FF4436",
                "perfect": "#F6EBC8"},
    "props": {"skyMode": 6, "skyColorA": "#0F4A44", "skyColorB": "#C99A3A", "skyAmount": 0.7, "skyScale": 2.4,
              "starDensity": 0.0, "horizonGlow": 0.4, "railGlow": 1.0, "noteGlow": 0.95, "additive": 0.24,
              "radiance": 0.92, "beatPulse": 0.6, "fog": 0.55, "vignette": 0.48},
}

LOOK = Look(
    title="Gatsby Deco", style="GatsbyDeco", prefix="GatsbyDeco", slug="art-deco", cls="lit", order=45,
    status="draft", brief="BACKLOG.md#art-deco",
    blurb="Black enamel, polished-gold inlay, octagonal keys, cream lamps. Nineteen-twenties geometry.",
    tagline="black enamel, gold inlay, octagon keys, cream lamps.",
    displays="neo", track_themes={"GatsbyDeco": TRACK},
    shape={
        "key": dict(OCT, bevel=0.2, dome=0.25),
        "Lamp": dict(shape=4, corner=0.9, round=0.25),
        "Dot": dict(shape=4, corner=0.9, round=0.25),
        "Pad": dict(shape=4, corner=0.55, round=0.25),
        "dial": dict(skirt="Polygon", skirt_count=8, skirt_depth=0.04, cap_r=0.64, bevel=0.2, depth=0.55,
                     smooth=0.5, dome=0.35, nub=0.105, nub_dist=0.4, arc_px=3.0, set=DIAL_SET),
        # concentric gold ring between the bezel and the value arc (hairline on the hero, 1px on the 56 px dial)
        "Knob": dict(set=dict(DIAL_SET, **ring(0.03))),
        "KnobSmall": dict(nub=0.14, set=dict(DIAL_SET, _KnobNubShapeType=0)),
        "KnobHero": dict(ticks=11, arc_px=4.0, set=dict(DIAL_SET, **ring(0.022))),
        "plate": dict(radius_px=9.0, corner=0.3, stitch=(GOLD, 1.4), pad_px=3.0,
                      set={"_PanelShapeType": 4}),
        "Back": dict(radius_px=12.0, pad_px=1.5),
        # the sunburst: a fan of faint gold rays from the centre of the knob bank
        "Inset": dict(set=dict(SUNBURST, _PanelShapeType=4)),
        # the pad socket gets a dim gold inlay too, so it is not an empty hole in the chassis
        "Socket": dict(set={"_PanelShapeType": 4, "_BorderEnabled": 1, "_BorderColor": "#8C6C2C",
                            "_BorderWidthPx": 1.2, "_BorderRenderAlpha": 1.0, "_BorderRenderEmissive": 0.0}),
        "shadow": dict(blur=1.4, cast=0.22),
        "states": {
            # Hover must be visible at 1:1: the gold chamfer lights up (brighter, hotter ramp) as well as the face
            "key": {"Hover": dict(gcol("_ButtonBevel", EDGE_HOVER), _ButtonRenderEmissive=0.1)},
            "Pad": {"Hover": dict(gcol("_ButtonBevel", EDGE_CREAM), _ButtonRenderEmissive=0.3),
                    "Latched": dict(gcol("_ButtonBevel", EDGE_CREAM), _ButtonRenderEmissive=0.35),
                    # opaque, dark and mode-independent (alpha 0.45 showed the chassis through it)
                    "Disabled": dict(gcol("_Button", ("#0D1414", "#0D1414")), _ButtonGradientEnabled=1,
                                     _ButtonRenderAlpha=1.0, _ButtonRenderEmissive=0.0)},
            "Solo": {"Active": dict(gcol("_Button", GOLD_FILL), _ButtonRenderEmissive=0.04)},
            "ScrollHandle": {"Hover": gcol("_Button", GOLD_FILL), "Disabled": {"_ButtonRenderAlpha": 0.8}},
            "dial": {"Hover": dict(gcol("_KnobBevel", tuple(toward(_G["base"], _G["lo"], _G["hi"], a)
                                                           for a in (1.0, 0.8, 0.1, -0.4))),
                                   _KnobRenderEmissive=0.12)},
        },
    },
    material={
        "plate": {"preset": "enamel", "tint": "#0B1214", "lo": "#000000", "hi": "#8FA8A8",
                  "plate_ramp": (0.1, 0.16), "matcap": None,
                  "pattern": ("Plastic", 8.0, 0.03, 1.0, 0.7, 0.0, 0.15)},
        "key": TEAL_KEY,
        "pad": {"preset": "enamel", "edge": "gold.edge", "amb": 0.9},
        "accent": {"preset": "enamel", "tint": EMERALD, "edge": "gold.edge", "amb": 0.8, "spec": 0.85,
                   "rough": 0.1, "matcap": ("gloss_coat", 0.85), "dome": 0.32},
        "cap": {"preset": "lacquer.black", "tint": "#0B1113", "amb": 0.9},
        "skirt": {"preset": "gold.polished", "amb": 0.95, "ramp": (-0.55, 0.0, 0.5, 0.9)},
        "handle": {"preset": "gold.polished", "amb": 0.95},
    },
    rig={
        "dark": {"light1": dict(pos=[-0.4, 1.5], height=1.3, color="#FFE9C2", intensity=0.15, specular=0.4,
                                specularPower=48),
                 "light2": dict(pos=[1.3, 0.6], height=0.9, color="#C8E4E0", intensity=0.035, specular=0.06),
                 "light3": dict(enabled=False)},
        "light": {"light1": dict(pos=[-1.5, 3.0], height=4.0, color="#FFF2DA", intensity=0.158, specular=0.15,
                                 specularPower=48),
                  "light2": dict(enabled=False), "light3": dict(enabled=False)},
    },
    modes={
        "dark": dict(
            track="GatsbyDeco", blurb="Black enamel, gold inlay, one warm lamp.",
            palette=dict(CONTROLS, GAP="#030606", BACK="#070B0D", FACE="#090F11", INSET="#070C0E", SOCKET="#080D0F",
                         WELL="#040606", SHADOW="#000000", SHADOW_A=0.6, WELL_EM=0.05),
            fields={
                "accent": {"shader": "Ribbons", "params": {"_Speed": 0.03, "_Base": "#061214", "_ColorA": "#0F5A52",
                                                           "_ColorB": "#C99A3A", "_ColorC": "#0A2A2C",
                                                           "_ColorD": "#F3E6BE", "_Opacity": 0.8, "_Contrast": 0.9}},
                "menu": {"shader": "Contours", "params": {"_Speed": 0.02, "_LineColor": "#C99A3A",
                                                          "_LineStrength": 0.45, "_ColorA": "#060D0F",
                                                          "_ColorB": "#0A1517", "_ColorC": "#0E1C1E",
                                                          "_ColorD": "#122426"}},
            },
            app=dict(display=dict(text="#F3E6BE", textDim="#9A8650", textAlt="#F3E6BE"),
                     ui=dict(accent="#C99A3A"))),
        "light": dict(
            track="GatsbyDeco", blurb="Ivory enamel chassis, the same black and gold hardware.",
            palette=dict(CONTROLS, GAP="#A79E86", BACK="#D3C9B0", FACE="#E9E0C8", INSET="#DDD3BB", SOCKET="#D8CEB6",
                         WELL="#0E1112", SHADOW="#3A2E18", SHADOW_A=0.35, WELL_EM=0.05, AMB_PLATE=0.88),
            set={"Inset": {"_PanelPatternIntensity": 0.4}},
            material={"plate": {"preset": "enamel", "tint": "#E9E0C8", "lo": "#6A5E46", "hi": "#FFFFFF",
                                "plate_ramp": (0.1, 0.1),
                                "pattern": ("Plastic", 8.0, 0.018, 1.0, 0.7, 0.0, 0.15)}},
            fields={
                "accent": {"shader": "Ribbons", "params": {"_Speed": 0.03, "_Base": "#E9E0C8", "_ColorA": "#7FB8A8",
                                                           "_ColorB": "#D8B45A", "_ColorC": "#C9DDD0",
                                                           "_ColorD": "#B89440", "_Opacity": 0.7}},
                "menu": {"shader": "Contours", "params": {"_Speed": 0.02, "_LineColor": "#9A7A2A",
                                                          "_LineStrength": 0.4, "_ColorA": "#EBE2CA",
                                                          "_ColorB": "#E6DCC2", "_ColorC": "#E1D6BA",
                                                          "_ColorD": "#DCD0B2"}},
            },
            app=dict(display=dict(text="#F3E6BE", textDim="#9A8650", textAlt="#F3E6BE"),
                     ui=dict(text="#241E10", textDim="#6B5E45", accent="#8A6A22"),
                     chrome=dict(label="#5E4A1C", labelActive="#241E10", icon="#5E4A1C", iconActive="#241E10"),
                     tracks=dict(text="#241E10", rowWithSample="#D2C28F"),
                     ink=dict(faceplate="#241E10", faceplateDim="#6B5E45", inset="#241E10", insetDim="#6B5E45",
                              backplane="#241E10", backplaneDim="#6B5E45", socket="#241E10", socketDim="#6B5E45",
                              reviewBar="#241E10", reviewBarDim="#6B5E45"))),
    },
)

if __name__ == "__main__":
    sys.exit(main(LOOK))
