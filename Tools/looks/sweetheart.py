"""Sweetheart — Valentine's (lit, seasonal: february). Brief: Looks/BACKLOG.md#valentine.

    python Tools/looks/sweetheart.py check | sheet | write | manifest | printcheck

Signature: satin + a gift box. Plates are crimson SATIN (the engine's Satin pattern: a long soft sheen band, not
velvet nap) with a rose-gold piping line; light mode is blush-pink satin. The keys are rose-pink satin enamel
under a rose-gold chamfer, the knobs are polished rose-gold caps in a fluted blush skirt (a bonbon-paper
liner), the ON lamp is a HEART, pads are confectionery (strawberry, pistachio, cream, lilac). Hardware is
identical in both modes; only the chassis changes.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from lookkit import Look, MATERIALS, gcol, grad, main, RM_UP  # noqa: E402

CRIMSON, BLUSH, PINK = "#D21F4B", "#F6C9D0", "#DE5F80"
ALLOY, ROSE_LO, ROSE_HI = "#E3A898", "#8A5A60", "#FFE6DE"     # ONE rose-gold alloy for every metal part
PIPING = "#E0A596"                        # rose-gold piping on the plates
WINE = "#3A0B18"                          # ink on pink keys

CONTROLS = dict(
    BODY=PINK, BODY_HI="#EE86A2", BODY_LO="#A63456", DIS_BODY="#8A5A66",
    MARK=WINE, MARK_DIM="#7A3A4C", DIS_MARK="#B58A94", ON_MARK="#FFF1F3",
    ACCENT=CRIMSON, ACCENT_HI="#EE4A70", ACCENT_LO="#8E1233", ACCENT_DIS="#6A5258", SOLO="#F2B3A4", LAMP="#E3234F", LAMP_OFF="#6A2038",
    HOT="#FF2D5A",
    CAP=ALLOY, SKIRT=ALLOY, NUB="#2A0610", HANDLE=ALLOY,
    VALUE="#FFC2D2", VALUE_EM=0.35, TRACK="#1A060B", ARC_OFF="#4C1424",
    SCROLL="#C98B98", SCROLL_HI="#F4C0C8", PAD_BODY="#4A1A28", PAD_TINT=0.8,
    PAD_HOVER_EM=0.3, PAD_PRESS_EM=0.22,
)


def rose(matcap, ramp, **kw):
    return dict({"preset": "gold.rose", "base": ALLOY, "amb": 1.0, "matcap": matcap, "lo": ROSE_LO, "hi": ROSE_HI, "ramp": ramp}, **kw)


def hardware(amb):
    return {
        "key": {"preset": "enamel", "tint": PINK, "edge": rose(("polished", 0.7), (-0.4, 0.05, 0.4, 0.75)),
                "amb": amb * 0.62, "pattern": ("Satin", 40.0, 0.07, 1.0, 0.3, 0.4, 0.0)},
        "accent": {"preset": "enamel", "tint": CRIMSON, "edge": rose(("polished", 0.7), (-0.4, 0.05, 0.4, 0.75)),
                   "amb": amb * 0.7},
        "cap": rose(("polished", 0.55), (-0.4, 0.05, 0.4, 0.75), amb=amb),
        "skirt": rose(("satin", 0.7), (-0.5, -0.1, 0.35, 0.7), amb=amb),
        "handle": rose(("brushed", 0.7), (-0.5, -0.1, 0.3, 0.68), amb=amb),
        "pad": rose(("gloss_coat", 0.6), (-0.5, -0.1, 0.3, 0.68), amb=amb * 0.6,
                    edge={"preset": "gold.rose", "base": ALLOY, "lo": ROSE_LO, "hi": ROSE_HI, "ramp": (0.75, 0.4, -0.2, -0.55)}),
    }


def satin(tint, amb, ramp, p=0.9, **kw):
    """Crimson/blush satin: the Satin pattern (long soft sheen band) under a lifted top, pixel-locked."""
    return dict({"preset": "enamel", "tint": tint, "plate_amb": amb, "plate_ramp": ramp, "spec": 0.5, "rough": 0.3,
                 "pattern": ("Satin", 330.0, p, 1.0, 0.12, 0.7, 0.0), "px": 220}, **kw)


TURN = {"Face": -32, "Inset": -25, "Socket": -40, "Back": -20, "Bezel": -36}
SATIN_SET = {k: {"_PanelPatternOffset": v} for k, v in TURN.items()}
GLYPH = WINE
KEY_STATES = {k: {"Hover": {"_ButtonRenderEmissive": 0.12}}
              for k in ("Button", "Accent", "ToggleBtn", "Solo", "Lamp", "Close", "Chip")}
for _k in ("ToggleBtn", "Solo", "Lamp"):
    KEY_STATES[_k]["Active"] = {"_IconColor": "#FFF1F3" if _k == "Lamp" else WINE, "_IconRenderEmissive": 0.5 if _k == "Lamp" else 0.0}
KEY_STATES["ToggleBtn"]["Active"]["_ButtonRenderEmissive"] = 0.0
KEY_STATES["Lamp"]["Hover"] = {"_ButtonRenderEmissive": 0.16, "_IconColor": "#2A0610", "_IconRenderEmissive": 0.0}
for _k in ("Close", "ToggleBtn", "Solo"):
    KEY_STATES[_k]["Hover"]["_IconColor"] = GLYPH
for _k in ("Close", "ToggleBtn", "Solo", "Lamp"):
    KEY_STATES[_k]["Pressed"] = {"_IconColor": "#FFE9E4"}

LOOK = Look(
    title="Sweetheart", style="Sweetheart", prefix="Sweetheart", slug="valentine", cls="lit", order=30,
    status="rejected", brief="BACKLOG.md#valentine",
    blurb="Crimson and blush satin, rose-gold hardware, a heart for ON. Seasonal: February.",
    tagline="crimson satin, rose-gold hardware, a heart for ON (seasonal: february).",
    displays="neo",
    shape={
        "key": dict(corner=0.5, round=0.7, bevel=0.18, depth=0.55, smooth=0.8, dome=0.0),
        "ScrollHandle": dict(round=0.9, dome=0.0),
        "Lamp": dict(icon=13, icon_size=0.9, set={"_IconShapeRotation": 180.0, "_IconOffset": (0.0, -0.1, 0.0, 0.0)}),
        "dial": dict(skirt="Circle", cap_r=0.62, bevel=0.2, depth=0.5,
                     smooth=0.6, dome=0.4, nub=0.1, nub_dist=0.38, arc_px=3.0),
        "KnobSmall": dict(nub=0.2, arc_px=3.8),
        "KnobHero": dict(ticks=11, arc_px=4.0),
        "shadow": dict(blur=1.6, cast=0.24),
        "Face": dict(stitch=(PIPING, 1.2)), "Inset": dict(stitch=(PIPING, 1.0)),
        "Pad": dict(bevel=0.15, depth=0.3, smooth=0.9, dome=0.3, icon=13, icon_size=0.8,
                set={"_IconColor": "#FFFFFF", "_IconRenderAlpha": 0.6, "_IconShapeRotation": 180.0}),
        "Close": dict(icon_size=0.5),
        "states": dict(
            KEY_STATES,
            dial={"Hover": {"_KnobRenderEmissive": 0.16}, "Pressed": {"_KnobFaceSmoothness": 0.25}},
            fader={"Hover": {"_HandleRenderEmissive": 0.16}},
            Pad={"Latched": dict(grad("_Button", ("#FF7A9C", "#E5224F", "#C01846"), RM_UP),
                                 **{"_ButtonRenderEmissive": 0.22, "_ButtonBevelDepth": -0.05, "_IconRenderAlpha": 1.0,
                                    "_IconRenderEmissive": 0.9, "_IconColor": "#FFFFFF"})}),
    },
    material=dict(hardware(1.0)),
    rig={
        "dark": {"light1": dict(pos=[-0.4, 1.5], height=1.2, color="#FFE6DC", intensity=0.9, specular=0.4,
                                specularPower=48),
                 "light2": dict(pos=[1.3, 0.6], height=0.9, color="#FF9CB4", intensity=0.3, specular=0.08),
                 "light3": dict(enabled=False)},
        "light": {"light1": dict(pos=[-1.5, 3.0], height=4.0, color="#FFF6F0", intensity=0.8, specular=0.15,
                                 specularPower=48),
                  "light2": dict(enabled=False), "light3": dict(enabled=False)},
    },
    track_themes={
        "SweetheartBox": {
            "_doc": "Sweetheart highway. See Starfield.track.json for the format.",
            "name": "SweetheartBox",
            "blurb": "Blush, rose, crimson, wine ladder. Rose-gold rails.",
            "palette": {
                "row1": "#EE8CA8", "row2": "#EA6F90", "row3": "#D21F4B", "row4": "#8E1840",
                "rail": "#E6A99B", "laneLine": "#6A2A3C", "laneFill": "#14050A", "hitLine": "#FFF1E8",
                "receptor": "#F0B0BC", "gridBar": "#D9708A", "gridBeat": "#4A1A28", "bgTop": "#12040A",
                "bgBottom": "#2A0A16", "fog": "#7A2A44", "star": "#FFD2DC", "miss": "#FF4A66",
                "perfect": "#FFEBC0"},
            "props": {"skyMode": 6, "skyColorA": "#3A0E1C", "skyColorB": "#D9708A", "skyAmount": 0.5, "skyScale": 2.4,
                      "starDensity": 0.0, "horizonGlow": 0.45, "railGlow": 0.95, "noteGlow": 0.95, "additive": 0.22,
                      "radiance": 0.92, "beatPulse": 0.55, "fog": 0.55, "vignette": 0.5}},
    },
    modes={
        "dark": dict(
            track="SweetheartBox", blurb="Crimson satin plates piped in rose gold, a heart for ON.",
            material={"plate": satin("#8A1633", 0.6, (0.0, 0.2)), "Inset": satin("#5E0F25", 0.6, (0.0, 0.12)),
                      "Socket": satin("#4A0B1E", 0.6, (0.0, 0.1)), "Bezel": satin("#4A0B1E", 0.6, (0.0, 0.1)),
                      "Back": satin("#3A0A18", 0.6, (0.0, 0.1), p=0.15)},
            set=SATIN_SET,
            palette=dict(CONTROLS, GAP="#1A060C", BACK="#3A0A18", FACE="#8A1633", INSET="#5E0F25", SOCKET="#4A0B1E",
                         WELL="#12040A", SCROLLWELL="#4A0B1E", SHADOW="#000000", SHADOW_A=0.6, WELL_EM=0.05,
                         AMB_PLATE=0.62, PLATE_LO=0.12, PLATE_HI=0.1),
            fields={"accent": {"shader": "Ribbons", "params": {
                        "_Speed": 0.03, "_Base": "#2A0612", "_ColorA": "#C21E48", "_ColorB": "#F27A96",
                        "_ColorC": "#8E1233", "_ColorD": "#E0A596", "_Opacity": 0.8, "_Brightness": -0.1}},
                    "menu": {"shader": "Bokeh", "params": {
                        "_Speed": 0.03, "_BaseTop": "#2A0612", "_BaseBottom": "#4A0B1E", "_ColorA": "#F27A96",
                        "_ColorB": "#E0A596", "_ColorC": "#C21E48", "_ColorD": "#F6C9D0", "_Intensity": 0.6}}},
            app=dict(display=dict(text="#FFC6D2", textDim="#C98A9A", textAlt="#F0C19A"),
                     key=dict(markOff=WINE, glyphOff=WINE, velOff=WINE),
                     ui=dict(text="#F8E4E8", textDim="#B48A96", accent="#F06C8C"),
                     chrome=dict(label="#E6BCC6", labelActive="#FFF1F3", icon="#E6BCC6", iconActive="#FF8AA4"),
                     tracks=dict(text="#F8E4E8", ruler="#E6BCC6E6", playhead="#F8E4E8E6", rowWithSample="#4A1A28"),
                     ink=dict(faceplate="#FFE9ED", faceplateDim="#D8A4B2", inset="#FFE9ED", insetDim="#D8A4B2",
                              backplane="#FFE9ED", backplaneDim="#D8A4B2", socket="#FFE9ED", socketDim="#D8A4B2",
                              reviewBar="#FFE9ED", reviewBarDim="#D8A4B2"))),
        "light": dict(
            track="SweetheartBox", blurb="Blush-pink satin chassis, the same rose-gold hardware.",
            material=dict({"plate": satin("#F6CAD2", 0.45, (0.0, 0.08), p=0.25), "Inset": satin("#E8A2B2", 0.45, (0.0, 0.05), p=0.25),
                           "Socket": satin("#DA85A0", 0.42, (0.0, 0.05), p=0.25), "Bezel": satin("#DA85A0", 0.42, (0.0, 0.05), p=0.25),
                           "Back": satin("#E3A3B3", 0.45, (0.0, 0.05), p=0.15)}, **hardware(1.1)),
            set=SATIN_SET,
            palette=dict(CONTROLS, GAP="#C98A9C", BACK="#E3A3B3", FACE="#F6CAD2", INSET="#E8A2B2", SOCKET="#DA85A0",
                         WELL="#4A0F22", SCROLLWELL="#E6A8B6", VALUE="#C2183F", ARC_OFF="#8C5A66", TRACK="#6A3444",
                         VALUE_EM=0.1, SHADOW="#4A2030", SHADOW_A=0.38, WELL_EM=0.05, AMB_PLATE=0.5,
                         PLATE_LO=0.08, PLATE_HI=0.0),
            fields={"accent": {"shader": "Ribbons", "params": {
                        "_Speed": 0.03, "_Base": "#F6C9D0", "_ColorA": "#E98FA4", "_ColorB": "#FFE3E8",
                        "_ColorC": "#D2506F", "_ColorD": "#F2B3A4", "_Opacity": 0.8}},
                    "menu": {"shader": "Bokeh", "params": {
                        "_Speed": 0.03, "_BaseTop": "#F6C9D0", "_BaseBottom": "#E6A8B6", "_ColorA": "#FFFFFF",
                        "_ColorB": "#F2B3A4", "_ColorC": "#E98FA4", "_ColorD": "#FFE3E8", "_Intensity": 0.6}}},
            app=dict(display=dict(text="#FFD6DE", textDim="#E0A8B6", textAlt="#F6D2A8"),
                     ui=dict(text="#3A0B18", textDim="#7A4656", accent="#B8143C"),
                     chrome=dict(label="#4A1828", icon="#4A1828"),
                     ink=dict(faceplate="#3A0B18", faceplateDim="#7A4656", inset="#3A0B18", insetDim="#6E3A4C",
                              backplane="#3A0B18", backplaneDim="#4E1E30", socket="#3A0B18", socketDim="#6E3A4C",
                              reviewBar="#3A0B18", reviewBarDim="#6E3A4C"))),
    },
)

if __name__ == "__main__":
    sys.exit(main(LOOK))
