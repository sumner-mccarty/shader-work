"""Midnight Pumpkin Dark + Light — October on the kit's `neon` class.

    python Tools/looks/midnight_pumpkin.py check | write | sheet | printcheck | manifest

Neon (unlit light tubes, no lamp rig). Where Tron is cyan on navy and Synthwave a magenta sunset sky, this is
a candle-lit night: near-black plates with a low pumpkin EMBER at the foot of the faceplate and a drifting
fat soft keys whose tubes burn pumpkin orange fading to witchy purple, a bone-white
candle-glow needle, and slime green for every ON (solo, lamp, pill, latched pads). The lamps are carved
jack-o'-lantern EYES: a triangle tube that floods slime green when it lights. Rounded, soft, slightly eerie
- no chamfers, no grid.
DARK  = midnight: black glass, ember at the foot, orange + purple tubes, green eyes.
LIGHT = dusk / hallow day: the chassis turns bone parchment, pumpkin flesh and dusk mauve; the black glass
keys and their tubes stay.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from lookkit import Look, gcol, main  # noqa: E402

ORANGE, ORANGE_HI, ORANGE_LO = "#FF7A1A", "#FFA040", "#C8500A"
PURPLE, PURPLE_HI = "#7438C4", "#C08CFF"
SLIME, SLIME_HI = "#86F020", "#B8FF58"

TRACK = {
    "_doc": "Midnight Pumpkin game-track theme: see Starfield.track.json for the format.",
    "name": "MidnightPumpkin", "blurb": "Candle-lit night: pumpkin, slime, witch-purple and bone.",
    "palette": {"row1": "#FF7A1A", "row2": "#8CFF2E", "row3": "#8A44E0", "row4": "#FF9A2E",
                "rail": "#FF8A2A", "laneLine": "#7A3EC0", "laneFill": "#0A0412", "hitLine": "#FFE9CF",
                "receptor": "#C9906A", "gridBar": "#FF9A3A", "gridBeat": "#5A2A8A", "bgTop": "#05020A",
                "bgBottom": "#1A0A14", "fog": "#6A2CB0", "star": "#FFD9A8", "miss": "#FF3A1A",
                "perfect": "#E8FF7A"},
    "props": {"skyMode": 0, "starDensity": 0.22, "horizonGlow": 0.7, "railGlow": 1.2, "noteGlow": 1.1,
              "additive": 0.32, "radiance": 1.0, "fog": 0.6, "vignette": 0.5},
}


# pads: no inner sheen band at rest (it read as a second frame); a thicker row-coloured rim instead
PAD = {"_ButtonBevelEnabled": 0, "_BorderWidth": 0.06, "_BorderRenderEmissive": 0.5, "_ButtonBevelGradientColorA": "#1C0B34",
       "_ButtonBevelGradientColorB": "#1C0B34"}


def purple_frame(w=None):
    """ONE rim per plate: a single witch-purple tube + its own bloom (no orange-to-pink second ring)."""
    d = {**gcol("_Border", (PURPLE, PURPLE)), **gcol("_Edge", (PURPLE, PURPLE))}
    return d


# lamp = a carved EMBER eye: dark glass with a barely-there ember rim when off, lit from inside amber -> yellow
LAMP_OFF = {**gcol("_Border", ("#8A4018", "#8A4018")), "_BorderWidth": 0.05, "_EdgeIntensity": 0.0,
            "_ButtonBevelEnabled": 0, "_ButtonRenderEmissive": 0.0}
LAMP_STATES = {
    "Hover": {**gcol("_Button", ("#3A1606", "#7A3008")), **gcol("_Border", ("#FF8A22", "#FFB040")),
              "_BorderWidth": 0.085, "_EdgeIntensity": 0.9},
    "Active": {**gcol("_Button", ("#FF5A08", "#FFB020")), **gcol("_Border", ("#FFB040", "#FFD878")),
               **gcol("_Edge", ("#FF8A10", "#FFA020")), "_BorderWidth": 0.06, "_EdgeIntensity": 1.0,
               "_ButtonRenderEmissive": 0.15},
}


def key_states(a, b, halo, line):
    """Hover on a glass key: the body lifts toward violet, the tube fattens, the bloom opens. Solo and Lamp light
    SLIME GREEN all the way out to the tube (the kit lights the tube with TUBE, i.e. orange/purple)."""
    out = {k: {"Hover": {**gcol("_Button", (a, b)), "_BorderWidth": w * line * 1.5, "_EdgeIntensity": halo}}
           for k, w in {"Button": 0.1, "ToggleBtn": 0.085, "Solo": 0.085, "Lamp": 0.1, "Chip": 0.09}.items()}
    out["Lamp"] = LAMP_STATES
    out["Accent"] = {"Hover": {"_EdgeIntensity": 0.7, "_BorderWidth": 0.13},
                     "Disabled": {**gcol("_Border", ("#7A4A2A", "#7A4A2A")), "_EdgeIntensity": 0.0}}
    out["Close"] = {"Hover": {**gcol("_Button", (a, b)), "_ButtonRenderAlpha": 1.0, "_EdgeIntensity": halo}}
    for k in ("Solo",):
        out[k]["Active"] = {**gcol("_Border", (SLIME_HI, SLIME)), **gcol("_Edge", (SLIME, SLIME)),
                            "_BorderWidth": 0.1 * line, "_EdgeIntensity": 1.3}
    return out


def pad_states(emissive):
    """Pads: Normal = black glass + row-coloured rim; Hover = fat rim + bloom + lifted glass; Pressed = flood in the
    row colour; Latched = slime green whatever the row (a gradient on a layer beats the row binding)."""
    return {"Hover": {"_ButtonRenderEmissive": 0.7, "_EdgeIntensity": 1.8, "_BorderWidth": 0.11,
                      "_ButtonBevelEnabled": 1, "_ButtonBevelDistance": 0.14, "_ButtonBevelSmoothness": 0.05},
            "Pressed": {"_ButtonBevelEnabled": 1, "_ButtonRenderEmissive": 0.6},
            "Disabled": {"_ButtonRenderAlpha": 1.0, "_EdgeIntensity": 0.0, "_BorderWidth": 0.04, "_BorderRenderEmissive": 0.15},
            "Latched": {"_BorderGradientEnabled": 1, **gcol("_Border", (SLIME_HI, SLIME)),
                        "_EdgeGradientEnabled": 1, **gcol("_Edge", (SLIME, SLIME)),
                        "_ButtonGradientEnabled": 1, **gcol("_Button", ("#1C4A06", "#3E9A0C")),
                        "_ButtonRenderEmissive": emissive, "_BorderWidth": 0.13, "_EdgeIntensity": 1.5}}



def knob_states(a, b):
    """Pumpkin caps: hover lifts the cap and flares the glow; disabled goes to cold dark clay."""
    out = {}
    for slot in ("Knob", "KnobHero", "KnobSmall"):
        out[slot] = {"Hover": {**gcol("_Knob", (a, b)), "_LineSublineGlowIntensity": 0.9},
                     "Disabled": {**gcol("_Knob", ("#1E1018", "#2C1A24")), "_KnobNubColor": "#0A0408"}}
    return out


D = dict(
    GAP="#030105", BACK="#0B2007", BACK_TOP="#0E0618",
    FACE="#3E1604", FACE_B="#1C0A10", FACE_C="#0C0614", FACE_TOP="#120A26",
    INSET="#07030C", INSET_TOP="#150B22", SOCKET="#040206", WELL="#050207", WELL_TOP="#0F0618",
    BODY="#09040E", BODY_TOP="#26103C", DIS_BODY="#06030A",
    # ONE hue per tube (core and bloom alike): orange for controls, purple for plates
    TUBE=("#FF7418", "#FF6E14", "#FF7A1A", "#FF7418"), TUBE_REST=("#E8620C",) * 4,
    TUBE_DIS=("#2A1630",) * 4, STRUCT="#4A2270", STRUCT_HI="#7C3CB8",
    HALO=("#E8520A",) * 4, HALO_REST=0.3, HALO_HOVER=0.55, HALO_ON=0.9, TUBE_EM=0.75, HALO_EM=1.6,
    SHEEN="#2C1240", SHEEN_ON="#F06A10", ARC_EMIT=0.3, FACE_LINE_PX=1.6, FACE_HALO_PX=4.0,
    FACE_SHEEN=0.03, PLATE_SHEEN="#5A2A00", GRID=0.0, LINE=1.0, BLOOM=2.2,
    MARK="#FFE8C9", MARK_DIM="#B58A78", ON_MARK="#0A1600", DIS_MARK="#4A3040",
    INK="#FFEBD2", INK_DIM="#E0B49A",
    ACCENT=("#B84400", "#E86A08"), ACCENT_HI=("#FF8A1E", "#FFC060"), ACCENT_DIS=("#4A2410", "#5E3014"),
    HOT=("#FF3D1A", "#FF6A2A"), SOLO=("#6ACB10", "#A8FF40"), LAMP=("#FF7A10", "#FFC030"),
    PRESS=("#E86A08", "#FF9A30"),
    ARC_OFF="#2E1448", ARC_OFF_HI="#42205E", ARC=("#FF5A00", "#FF8A1A", "#FFB02E", "#FFD866"),
    ARC_GLOW="#FF7A1A", ARC_GLOW_I=0.6,
    # pumpkin caps: orange clay, ribbed by the Fluted silhouette, a dark carved notch for the pointer
    CAP="#C84E00", CAP_TOP="#FF9A30", CAP_RING="#7A2A00", CAP_RING_HI="#FFD08A", NEEDLE="#1A0610",
    TRACK="#26123A", HANDLE="#FFE0B8", HANDLE_HI="#FFFFFF", FADER_A="#9B4DFF", FADER_B="#FF8A1A",
    PAD_BODY="#08040E", PAD_LINE="#FF9A3A", PAD_LINE_TINT=1.0, PAD_HALO_TINT=1.0, PAD_FACE_TINT=0.05,
    PAD_SHEEN_TINT=0.8, SCROLL="#3A1A5C", SCROLL_HI="#8A48D8")

# LIGHT changes the CHASSIS only: every control token is the dark one (rims, glass, caps, disabled looks)
CHASSIS_LIGHT = dict(
    GAP="#8A72AE", BACK="#A890C8", BACK_TOP="#C8B4E0",
    FACE="#E3D0AE", FACE_B="#EADCC0", FACE_C="#F1E6D0", FACE_TOP="#F7EFDF",
    INSET="#DCCBAC", INSET_TOP="#EADDC4", SOCKET="#9680BA",
    STRUCT="#8A6EB0", STRUCT_HI="#5A3A90", PLATE_SHEEN="#C8A878", FACE_LINE_PX=2.0, FACE_HALO_PX=3.0, FACE_SHEEN=0.0,
    INK="#2A0E3C", INK_DIM="#4A2A62", SCROLL="#8A6EB0", SCROLL_HI="#5A3A90")
L = {**D, **CHASSIS_LIGHT}

GLASS_TROUGH = {"_BgColor": "#12081E", "_BgGradientColorA": "#12081E", "_BgGradientColorB": "#2C1446"}
FRAME = {k: purple_frame() for k in ("Face", "Well", "Bezel")}

LOOK = Look(
    title="Midnight Pumpkin", style="MidnightPumpkin", prefix="MidnightPumpkin", slug="midnight-pumpkin", cls="neon",
    order=40, status="candidate", brief="BACKLOG.md#spooky",
    blurb="October on black glass: pumpkin knobs, carved ember eyes, slime-green solo and pill.",
    tagline="unlit, non-raymarched neon: pumpkin knobs, ember eyes, witch-purple frames, slime green.",
    note="The rig (Themes/MidnightPumpkin.theme) has every lamp off: all the light on screen is emissive - tube\n"
         "cores, additive blooms, arc glows - over black glass with an ember at its foot.",
    displays="tron",
    shape={
        "key": {"shape": 0, "cut": 0.3, "line": 0.1, "set": {"_EdgeSoftness": 1.0, "_EdgeFalloff": 2.0}},
        "Pad": {"cut": 0.5},
        "Close": {"alpha": 1.0},
        # the lamp is a carved EMBER eye: a triangle (3-gon polygircle), dark when off, lit from inside when on
        "Lamp": {"shape": 1, "cut": 0.02, "icon": None, "line": 0.05, "halo_w": 0.1, "set": LAMP_OFF},
        # knobs are PUMPKINS: a ribbed (10 flutes) orange cap with a carved dark triangle notch for the pointer
        "dial": {"silhouette": "capped", "nub": 0.17,
                 "set": {"_KnobShapeType": 6, "_KnobShapeScale": 10, "_KnobShapeParam1": 0.3,
                         "_KnobShapeParam2": 0.4, "_KnobShapeParam3": 0.0, "_KnobRoundness": 0.6,
                         "_KnobNubShapeType": 0}},
        "KnobHero": {"deco": False, "nub": 0.14},
        "Fader": {"fill": ("FADER_A", "FADER_B")},
        "plate": {"set": {"_PanelShapeType": 0, "_PanelShapeParam1": 0.8}},
        "Face": {"fill": ("FACE", "FACE_B", "FACE_C", "FACE_TOP"), "cut_px": 18.0,
                 "set": {"_PanelShapeType": 0, "_PanelShapeParam1": 0.8}},
    },
    track_themes={"MidnightPumpkin": TRACK},
    modes={
        "dark": dict(
            track="MidnightPumpkin",
            blurb="Midnight: black glass, an ember at the foot, pumpkin knobs and carved ember eyes.",
            palette=D,
            fields={"accent": {"shader": "Splotch", "params": {
                        "_Speed": 0.03, "_Base": "#07030C", "_ColorA": "#FF6A00", "_ColorB": "#9B3CFF",
                        "_ColorC": "#5A1CA0", "_ColorD": "#8CFF2E", "_Count": 5, "_Size": 0.3, "_Softness": 0.22,
                        "_Opacity": 0.85, "_Brightness": -0.12, "_Vignette": 0.45}},
                    "menu": {"shader": "Contours", "params": {
                        "_Speed": 0.015, "_LineColor": "#9B4DFF", "_LineStrength": 0.55, "_ColorA": "#06030A",
                        "_ColorB": "#120820", "_ColorC": "#2A1004", "_ColorD": "#4A1C06", "_Count": 12,
                        "_Brightness": -0.05}}},
            set={**FRAME, "Pad": PAD, "Pill": {"_LedColor": SLIME}, "Slider": GLASS_TROUGH, "Fader": GLASS_TROUGH},
            states={**key_states("#2A1048", "#5A2A98", 0.7, 1.0), **knob_states("#E8680E", "#FFC060"),
                    "Pad": pad_states(0.4)},
            app=dict(
                chrome=dict(headerBg="#06030A", headerBorder="#7C3CB8", tabFillBottom="#0A0510", tabFillTop="#0A0510",
                            tabFillActiveBottom="#1C0C2E", tabFillActiveTop="#2A1240", iconActive="#FF8A1E",
                            meatballLit="#8CFF2E"),
                ui=dict(textFaint="#8A6A80", accent="#FF8A1E", warn="#FFD25A", danger="#FF4A2A", ok="#8CFF2E"),
                surface=dict(card="#0A0510F5", cardEdge="#7C3CB8", divider="#241238", scrim="#030105C8"),
                display=dict(text="#F2B46C", textDim="#B07A5A", textAlt="#C8FF6A", warn="#FF5A2A"),
                key=dict(edgeOff="#E0680E", bankEdgeOff="#4A2270", velOn="#FF8A1E"),
                pad=dict(empty="#08040E80", ringWhite="#FFFFFF4D", ringBack="#030105E0"),
                review=dict(bar="#06030AF0", barRule="#FF8A1E22"),
                tracks=dict(backdrop="#05020A", strip="#07030C", rowWithSample="#1C0C2E", rowEmpty="#0E0618",
                            rowNotesNoSample="#2A1006", text="#F0D4BC", ruler="#FF8A1EB0", playhead="#8CFF2EE6",
                            recMarker="#FF4A2ADC", scrollbar="#FF8A1E26")),
        ),
        "light": dict(
            track="MidnightPumpkin",
            blurb="Dusk: bone parchment over dusk-violet; the same black glass, pumpkin knobs and ember eyes.",
            palette=L,
            fields={"accent": {"shader": "Splotch", "params": {
                        "_Speed": 0.03, "_Base": "#F2E6CE", "_ColorA": "#E8C89A", "_ColorB": "#B8A0D8",
                        "_ColorC": "#9A7ACA", "_ColorD": "#D8E8B0", "_Count": 5, "_Size": 0.3, "_Softness": 0.3,
                        "_Opacity": 0.8, "_Vignette": 0.2}},
                    "menu": {"shader": "Contours", "params": {
                        "_Speed": 0.015, "_LineColor": "#7A3CC0", "_LineStrength": 0.5, "_ColorA": "#EADCC0",
                        "_ColorB": "#F0E2C8", "_ColorC": "#F4E8D2", "_ColorD": "#F8EEDC", "_Count": 12}}},
            set={"plate": {"_BorderRenderEmissive": 0.12, "_EdgeRenderEmissive": 0.3}, **FRAME, "Well": {**FRAME["Well"], "_BorderRenderEmissive": 0.1, "_EdgeRenderEmissive": 0.1, "_EdgeIntensity": 0.3},
                 "Pad": PAD, "Pill": {"_LedColor": SLIME}, "Slider": GLASS_TROUGH, "Fader": GLASS_TROUGH},
            states={**key_states("#2A1048", "#5A2A98", 0.7, 1.0), **knob_states("#E8680E", "#FFC060"),
                    "Pad": pad_states(0.4)},
            app=dict(
                chrome=dict(headerBg="#B8A2D4", headerBorder="#5A3A90", tabFillBottom="#A890C8", tabFillTop="#A890C8",
                            tabFillActiveBottom="#F1E6D0", tabFillActiveTop="#F1E6D0", iconActive="#C8500A",
                            meatballLit="#C8500A", label="#2A0E3C", icon="#4A2A62"),
                ui=dict(textFaint="#8A6A9A", accent="#C8500A", warn="#B86A00", danger="#C8300A", ok="#3A8A10"),
                surface=dict(card="#F1E6D0F5", cardEdge="#5A3A90", divider="#A48CC4", scrim="#2A0E3CC0"),
                display=dict(text="#F2B46C", textDim="#B07A5A", textAlt="#C8FF6A", warn="#FF8A4A"),
                key=dict(label="#FFE8C9", edgeOff="#E0680E", bankFaceOff="#09040E", bankEdgeOff="#5A3A90",
                         velOn="#E86A08"),
                pad=dict(empty="#08040E80", ringWhite="#FFFFFF4D", ringBack="#09040EE0"),
                review=dict(bar="#B8A2D4F0", barRule="#2A0E3C22"),
                tracks=dict(backdrop="#8A72AE", strip="#A890C8", rowWithSample="#E3D0AE", rowEmpty="#D4C4A8",
                            rowNotesNoSample="#E8CBA0", text="#2A0E3C", ruler="#2A0E3CB0", playhead="#C8500AE6",
                            recMarker="#C8300ADC", scrollbar="#2A0E3C26")),
        ),
    },
)

if __name__ == "__main__":
    sys.exit(main(LOOK))
