"""Bioluminescent Dark + Light — the deep sea on the kit's `neon` class.

    python Tools/looks/deep_sea.py check | write | sheet | printcheck | manifest

Neon (unlit light tubes, no lamp rig). Where Tron is a hard cyan grid on black, Synthwave a magenta sunset and
Midnight Pumpkin a warm candle-lit night, this is the ABYSS: plates are lit abyss-BLUE water (not black glass)
with a faint cell lattice (Voronoi, like plankton membranes), keys are round bell-shaped organisms - capsules and
circles whose tube burns cyan fading to violet, with a wide soft radial glow inside the rim (the jellyfish bell)
and a big soft bloom outside it. A Caustics wallpaper drifts through the gaps between modules. Coral is the one
warm note: the knob's pointer (a glowing nucleus), the value arc's tip, MUTE/HOT and the close key.
DARK  = the abyss: deep blue water, cyan + violet organisms, drifting caustics.
LIGHT = a sunlit lagoon: the chassis turns shallow seafoam / white sand with white caustic light; the controls stay
the same dark-water organisms with their tubes (a little deeper so they read on pale water).
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from lookkit import Look, gcol, main  # noqa: E402

CYAN, VIOLET, CORAL, MINT = "#35F0E2", "#9B7BFF", "#FF7AAE", "#7CFFE8"

TRACK = {
    "_doc": "Bioluminescent game-track theme: see Starfield.track.json for the format.",
    "name": "Bioluminescent", "blurb": "The abyss: cyan and violet organisms, a coral flash, caustic light from above.",
    "palette": {"row1": "#35F0E2", "row2": "#9B7BFF", "row3": "#FF7AAE", "row4": "#7CE0FF",
                "rail": "#2FD0E8", "laneLine": "#1A5E86", "laneFill": "#02101E", "hitLine": "#E6FFFB",
                "receptor": "#4FB6D8", "gridBar": "#35F0E2", "gridBeat": "#1C4A7A", "bgTop": "#010812",
                "bgBottom": "#04304E", "fog": "#1C5AA0", "star": "#9CEBFF", "miss": "#FF4A7A",
                "perfect": "#B8FFF2"},
    "props": {"skyMode": 0, "starDensity": 0.3, "horizonGlow": 0.5, "railGlow": 1.2, "noteGlow": 1.2,
              "additive": 0.4, "radiance": 1.0, "fog": 0.7, "vignette": 0.5},
}


def cells(col, inten=0.3, scale=3.0, px=180, add=True, contrast=1.4):
    """The plankton lattice: Voronoi cell walls (Leather), pixel-locked. ADDED as glowing membranes on dark water,
    INKED as faint sand ripples on the light lagoon."""
    return {"_PanelPatternEnabled": 1, "_PanelPatternType": 4, "_PanelPatternScale": scale,
            "_PanelPatternPx": px, "_PanelPatternIntensity": inten, "_PanelPatternContrast": contrast,
            "_PanelPatternParam1": 0.3, "_PanelPatternParam2": 0.7, "_PanelPatternParam3": 0.8,
            "_PanelPatternColorEnabled": 1, "_PanelPatternColorType": 1, "_PanelPatternColorMode": 2 if add else 3,
            "_PanelPatternColorUsed": 2, "_PanelPatternColorA": "#000000" if add else "#FFFFFF",
            "_PanelPatternColorB": col}


def radial(layer, st, scale=1.6):
    """A RADIAL gradient (type 1: distance from the centre of the part, stop A at the middle) - the organism lit from
    inside: a soft glowing core fading to abyss navy at the rim. `st` = 2-4 stops, core first."""
    return {f"{layer}GradientEnabled": 1, f"{layer}GradientType": 1, f"{layer}GradientScale": scale,
            f"{layer}GradientOffset": 0.0, **gcol(layer, st)}


# the bell: a soft cyan core fading through blue to near-black at the rim (never white text on a bright core)
BELL = ("#127C9C", "#0A4676", "#031C38", "#020D1C")
BELL_HI = ("#25B4D6", "#0C5890", "#042A4C", "#020F20")
PAD_BELL = ("#0B4468", "#06305A", "#021A34", "#010E1C")
PAD_HOVER = ("#2AB8D8", "#0C6498", "#043258", "#021428")
PAD_PRESS = ("#6CE8E8", "#1CA4C8", "#0A4C78", "#032A4A")
PAD_LIT = ("#A8FFF0", "#2FD8C8", "#0B7C88", "#033A48")

# pads: no inner sheen band at rest; a thin row-coloured rim round a glowing cell
PAD = {"_ButtonBevelEnabled": 0, "_BorderWidth": 0.045, "_BorderSoftness": 0.12, "_BorderRenderEmissive": 0.55, **radial("_Button", PAD_BELL, 1.7),
       "_ButtonBevelGradientColorA": "#05203A", "_ButtonBevelGradientColorB": "#05203A"}
KEYS = {**radial("_Button", BELL, 1.6), "_BorderSoftness": 0.12, "_BorderRenderEmissive": 0.6}
DIAL = {**radial("_Knob", ("#2CC0DC", "#127C9C", "#053058", "#020C1A"), 1.55), "_LineSublineGlowWidth": 0.03}


def key_states():
    """Hover on a bell: the glow swells (core brightens) and the rim fattens. Solo lights the tube violet, the lamp
    floods mint; Dot and Close get a real fill lift + full-cyan rim."""
    out = {k: {"Hover": {**gcol("_Button", BELL_HI), "_BorderWidth": w * 1.5, "_EdgeIntensity": 1.5}}
           for k, w in {"Button": 0.06, "ToggleBtn": 0.055, "Solo": 0.055, "Lamp": 0.06, "Chip": 0.06}.items()}
    out["Solo"]["Active"] = {**gcol("_Border", ("#D8CCFF", VIOLET)), **gcol("_Edge", (VIOLET, VIOLET)),
                             "_BorderWidth": 0.07, "_EdgeIntensity": 1.3}
    out["Lamp"]["Active"] = {**gcol("_Border", ("#E6FFFB", MINT)), **gcol("_Edge", (MINT, CYAN)),
                             "_BorderWidth": 0.07, "_EdgeIntensity": 1.4}
    out["Dot"] = {"Hover": {**gcol("_Button", ("#7CF8F0", "#1E8CB8", "#0A4C78", "#031C38")), **gcol("_Border", (CYAN, CYAN)),
                            "_BorderWidth": 0.16, "_EdgeIntensity": 1.5}}
    out["Close"] = {"Hover": {"_ButtonRenderAlpha": 1.0, "_IconColor": "#FFFFFF", **gcol("_Button", BELL_HI),
                              **gcol("_Border", (CYAN, CYAN)), "_BorderWidth": 0.1, "_EdgeIntensity": 1.5},
                    "Pressed": {"_ButtonRenderAlpha": 1.0, "_IconColor": "#FFFFFF", **gcol("_Button", PAD_PRESS)},
                    "Disabled": {"_IconColor": "#244A60"}}
    return out


def pad_states(emissive):
    """Pads: Normal = dim glowing cell + thin row rim; Hover = the cell's core swells + fat rim + bloom; Pressed = the
    core floods bright; Latched = a mint orb whatever the row (a gradient beats the row binding)."""
    return {"Hover": {**gcol("_Button", PAD_HOVER), "_ButtonRenderEmissive": 0.5, "_EdgeIntensity": 1.7,
                      "_BorderWidth": 0.12},
            "Pressed": {**gcol("_Button", PAD_PRESS), "_ButtonRenderEmissive": 0.6, "_BorderWidth": 0.12,
                        "_EdgeIntensity": 1.8},
            "Disabled": {"_ButtonRenderAlpha": 1.0, **gcol("_Button", ("#0A2238", "#061A2E", "#04101E", "#020C18")),
                         "_EdgeIntensity": 0.0, "_BorderRenderEmissive": 0.05},
            "Latched": {"_BorderGradientEnabled": 1, **gcol("_Border", ("#9CFFF0", MINT)),
                        "_EdgeGradientEnabled": 1, **gcol("_Edge", (CYAN, CYAN)),
                        **gcol("_Button", PAD_LIT), "_ButtonRenderEmissive": emissive, "_BorderWidth": 0.12,
                        "_EdgeIntensity": 1.5}}


# the organisms are the SAME in both modes (the chassis changes, not the controls)
CTRL = dict(
    BODY="#020D1C", BODY_TOP="#0B2E54", DIS_BODY="#041222",
    TUBE=("#5CFFE8", "#2FCBFF", "#8A7CFF", "#B88BFF"), TUBE_REST=("#25C7C8", "#2494D6", "#6C5CE0", "#8E62D8"),
    TUBE_DIS=("#16384E",) * 4, STRUCT="#103E62", STRUCT_HI="#1E6C96",
    HALO=("#2FF0E0", "#2FA6FF", "#7C6CFF", "#A06CFF"), HALO_ON=1.3,
    SHEEN="#0A4C78", SHEEN_ON="#B8FFF4", ARC_EMIT=0.35,
    ON_MARK="#021424", DIS_MARK="#3A6680",
    ACCENT=("#34E4E0", "#0A8CAA"), ACCENT_HI=("#8CFAF2", "#14B4CC"), ACCENT_DIS=("#0A2C3C", "#0A2640"),
    HOT=("#FF9CC2", "#FF3D80"), SOLO=("#D2C6FF", "#7A5CFF"), LAMP=("#A8FFF0", "#2FD8C8"),
    PRESS=("#34E4E0", "#0A8CAA"),
    ARC_OFF="#0A2A44", ARC_OFF_HI="#12405E", ARC=("#35F0E2", "#38A8FF", "#9B7BFF", "#9B7BFF"),
    ARC_GLOW="#22D8FF",
    CAP="#2CC0DC", CAP_TOP="#020C1A", CAP_RING="#17607F", CAP_RING_HI="#5CD8D0", NEEDLE="#DDFFF8",
    TRACK="#0A2438", HANDLE="#8CE8DC", HANDLE_HI="#B8FFF4", FADER_A="#9B7BFF", FADER_B="#35F0E2",
    PAD_BODY="#02101E", PAD_LINE="#35F0E2", PAD_LINE_TINT=1.0, PAD_HALO_TINT=1.0, PAD_FACE_TINT=0.07,
    PAD_SHEEN_TINT=0.3,
)

LOOK = Look(
    title="Bioluminescent", style="Bioluminescent", prefix="Biolum", slug="deep-sea", cls="neon",
    order=41, status="draft", brief="BACKLOG.md#deep-sea",
    blurb="Abyss-blue water, round glowing organisms lit from inside in cyan and violet, a coral flash, drifting caustics.",
    tagline="unlit, non-raymarched neon: organisms lit from inside in abyssal water.",
    note="The rig (Themes/Bioluminescent.theme) has every lamp off: all the light on screen is emissive - radial\n"
         "glows, thin tubes, additive blooms, arc glows - over lit abyss-blue plates with a Caustics wallpaper behind.",
    displays="tron",
    shape={
        # round, buoyant cells: pills and circles whose body is a RADIAL glow; the rim is a thin skin, not the idea
        "key": {"shape": 0, "cut": 0.0, "line": 0.06, "halo_w": 0.3, "sheen": 0.0},
        "Pad": {"cut": 0.06, "halo_w": 0.18, "line": 0.05},
        # the lamp is a plankton ORB: a plain circle that floods with light, no glyph
        "Lamp": {"shape": 1, "cut": 0.0, "icon": None, "line": 0.06, "halo_w": 0.42, "sheen": 0.0},
        "Dot": {"halo_w": 0.2, "line": 0.05},
        "Close": {"alpha": 1.0},
        "dial": {"silhouette": "capped", "nub": 0.11, "glow_px": 6.0, "ring_px": 1.0},
        "KnobHero": {"deco": False, "ticks": 0, "glow_px": 8.0},
        "Fader": {"fill": ("FADER_A", "FADER_B")},
        "plate": {"set": {"_PanelShapeType": 0, "_PanelShapeParam1": 0.8}},
        "Face": {"fill": ("FACE", "FACE_B", "FACE_C", "FACE_TOP"), "cut_px": 22.0, "halo": 0.0,
                 "set": {"_PanelShapeType": 0, "_PanelShapeParam1": 0.8}},
        "Inset": {"cut_px": 12.0}, "Socket": {"cut_px": 10.0}, "Well": {"cut_px": 10.0}, "Bezel": {"cut_px": 10.0},
    },
    track_themes={"Bioluminescent": TRACK},
    modes={
        "dark": dict(
            track="Bioluminescent", backdrop="Backdrops/DeepWater",
            blurb="The abyss: deep blue water, organisms lit from inside, caustic light drifting through the gaps.",
            backdrop_fx={"shader": "Caustics", "time": 9.0, "params": {
                "_Speed": 0.04, "_Scale": 1.25, "_Warp": 0.9, "_Detail": 3, "_FieldScale": 0.7,
                "_ColorA": "#000610", "_ColorB": "#03264A", "_ColorC": "#074A6C", "_ColorD": "#3A1C9C",
                "_PoolAmount": 0.8, "_LineColor": "#3EF0DC", "_LineStrength": 0.3, "_LineWidth": 0.22,
                "_LineLayers": 2, "_Depth": 0.85, "_Brightness": -0.1, "_Contrast": 1.1, "_Saturation": 1.1,
                "_Vignette": 0.35}},
            fields={"accent": {"shader": "Splotch", "params": {
                        "_Speed": 0.03, "_Base": "#020A18", "_ColorA": "#14D6E0", "_ColorB": "#7A4CFF",
                        "_ColorC": "#1E7BFF", "_ColorD": "#FF5C9A", "_Count": 5, "_Size": 0.3, "_Softness": 0.4,
                        "_Opacity": 0.85, "_Merge": 0.5, "_Brightness": -0.12, "_Vignette": 0.45}},
                    "menu": {"shader": "Bokeh", "params": {
                        "_Speed": 0.02, "_BaseTop": "#02101E", "_BaseBottom": "#04243E", "_ColorA": "#38F0E0",
                        "_ColorB": "#8A6BFF", "_ColorC": "#2D9BFF", "_ColorD": "#FF7AB4", "_Count": 10,
                        "_Size": 0.08, "_Softness": 0.6, "_Rim": 0.1, "_Intensity": 0.55, "_Pulse": 0.5,
                        "_Brightness": -0.06}}},
            palette=dict(
                CTRL,
                # the water: lit from above - the plate runs from abyss navy (bottom) to a deep teal-blue sky
                GAP="#010A14", BACK="#020E1E", BACK_TOP="#04203A",
                FACE="#020F20", FACE_B="#03203A", FACE_C="#053358", FACE_TOP="#07426C",
                INSET="#02101F", INSET_TOP="#04223E", SOCKET="#020E1B", WELL="#010811", WELL_TOP="#03182C",
                HALO_REST=0.55, HALO_HOVER=0.95,
                FACE_LINE_PX=1.2, FACE_HALO_PX=3.0, FACE_SHEEN=0.03, PLATE_SHEEN="#0A4068", GRID=0.0, LINE=1.0,
                BLOOM=1.4, MARK="#C4F7FF", MARK_DIM="#5E9CC0", INK="#D4F8FF", INK_DIM="#82BCD6", ARC_GLOW_I=0.6,
                SCROLL="#0F3E5E", SCROLL_HI="#2A86B0"),
            set={"key": KEYS, "Accent": radial("_Button", CTRL["ACCENT"] + ("#08607A", "#05384C"), 1.6),
                 "dial": DIAL, "Pad": PAD, "Pill": {"_LedColor": MINT},
                 "Dot": radial("_Button", ("#2A86B0", "#0F3E5E"), 1.6),
                 "Face": cells("#34C8E8", 0.3, 2.2, 260, contrast=1.1),
                 "Back": cells("#2A8CC8", 0.28, 1.8, 300, contrast=1.1),
                 "Inset": {**cells("#2A78B0", 0.18, 2.0, 200, contrast=1.1), **radial("_Panel", ("#08406A", "#042A4A", "#021428"), 1.3)},
                 "Socket": {**cells("#2A78B0", 0.14, 2.0, 200, contrast=1.1), **radial("_Panel", ("#063A60", "#032240", "#020F1E"), 1.3)}},
            states={**key_states(), "Pad": pad_states(0.4)},
            app=dict(
                chrome=dict(headerBg="#020C18", headerBorder="#1E6C96", tabFillBottom="#03121F", tabFillTop="#03121F",
                            tabFillActiveBottom="#062A48", tabFillActiveTop="#0A3A60", iconActive="#35F0E2",
                            meatballLit="#FF7AAE"),
                ui=dict(textFaint="#3C6C88", accent="#35F0E2", warn="#FFC66B", danger="#FF5C94", ok="#4DF5B0"),
                surface=dict(card="#031426F5", cardEdge="#1E6C96", divider="#0A2A44", scrim="#010811C8"),
                display=dict(text="#8CFFF0", textDim="#2E8C9E", textAlt="#C8B4FF", warn="#FF5C94"),
                key=dict(edgeOff="#25C7C8", bankEdgeOff="#103E62", velOn="#35F0E2"),
                pad=dict(empty="#02101E80", ringWhite="#FFFFFF4D", ringBack="#010811E0"),
                review=dict(bar="#020C18F0", barRule="#35F0E222"),
                tracks=dict(backdrop="#010A14", strip="#020E1B", rowWithSample="#062442", rowEmpty="#03162A",
                            rowNotesNoSample="#16103A", text="#A8E6F6", ruler="#35F0E2B0", playhead="#FF7AAEE6",
                            recMarker="#FF5C94DC", scrollbar="#35F0E226")),
        ),
        "light": dict(
            track="Bioluminescent", backdrop="Backdrops/Lagoon",
            blurb="A sunlit lagoon: seafoam and white-sand chassis, white caustic light; the same organisms.",
            backdrop_fx={"shader": "Caustics", "time": 9.0, "params": {
                "_Speed": 0.04, "_Scale": 1.25, "_Warp": 0.8, "_Detail": 3, "_FieldScale": 0.7,
                "_ColorA": "#2FA9B8", "_ColorB": "#5FD0CC", "_ColorC": "#8FE0D0", "_ColorD": "#D8E8B0",
                "_PoolAmount": 0.5, "_LineColor": "#FFFFFF", "_LineStrength": 0.2, "_LineWidth": 0.24,
                "_LineLayers": 2, "_Depth": 0.3, "_Brightness": 0.0, "_Contrast": 1.0, "_Saturation": 1.0,
                "_Vignette": 0.1}},
            fields={"accent": {"shader": "Splotch", "params": {
                        "_Speed": 0.03, "_Base": "#BDEFE6", "_ColorA": "#5FD8D0", "_ColorB": "#9AB4FF",
                        "_ColorC": "#C8A8FF", "_ColorD": "#FFB4C8", "_Count": 5, "_Size": 0.3, "_Softness": 0.4,
                        "_Opacity": 0.85, "_Merge": 0.3, "_Vignette": 0.15}},
                    "menu": {"shader": "Bokeh", "params": {
                        "_Speed": 0.02, "_BaseTop": "#D6F6EE", "_BaseBottom": "#A2E0DC", "_ColorA": "#FFFFFF",
                        "_ColorB": "#C8D8FF", "_ColorC": "#8AE8E0", "_ColorD": "#FFD0E0", "_Count": 10,
                        "_Size": 0.08, "_Softness": 0.6, "_Rim": 0.1, "_Intensity": 0.45, "_Pulse": 0.4}}},
            palette=dict(
                CTRL,
                GAP="#7FD3D4", BACK="#9ADEDB", BACK_TOP="#BDEFE6",
                FACE="#62C6CA", FACE_B="#8BDCD6", FACE_C="#A2E0D4", FACE_TOP="#BCE8DC",
                INSET="#C2EBE4", INSET_TOP="#D6F2EA", SOCKET="#7ACDCD", WELL="#06243C", WELL_TOP="#0A3558",
                HALO_REST=0.3, HALO_HOVER=0.5, HALO_ON=0.8,
                FACE_LINE_PX=1.6, FACE_HALO_PX=2.5, FACE_SHEEN=0.0, PLATE_SHEEN="#9ADCD8", GRID=0.0, LINE=1.15,
                BLOOM=0.8, TUBE_EM=0.1, HALO_EM=0.3,
                MARK="#C4F7FF", MARK_DIM="#6FA6C4", INK="#06304A", INK_DIM="#1B5674", ARC_GLOW_I=0.45,
                SCROLL="#5AAAB8", SCROLL_HI="#1E7C9C"),
            set={"plate": {"_BorderRenderEmissive": 0.15, "_EdgeRenderEmissive": 0.3},
                 "key": {**KEYS, "_BorderRenderEmissive": 0.1}, "Accent": radial("_Button", CTRL["ACCENT"] + ("#08607A", "#05384C"), 1.6),
                 "dial": DIAL, "Pad": {**PAD, "_BorderRenderEmissive": 0.15}, "Pill": {"_LedColor": MINT},
                 "Dot": radial("_Button", ("#2A86B0", "#0F3E5E"), 1.6),
                 "Face": cells("#1E8C9C", 0.2, 2.2, 260, add=False, contrast=1.1),
                 "Back": cells("#1E8C9C", 0.16, 1.8, 300, add=False, contrast=1.1),
                 "Slider": {"_BgColor": "#06243C", "_BgGradientColorA": "#06243C", "_BgGradientColorB": "#0D3358"},
                 "Fader": {"_BgColor": "#06243C", "_BgGradientColorA": "#06243C", "_BgGradientColorB": "#0D3358"}},
            states={**key_states(), "Pad": pad_states(0.15)},
            app=dict(
                chrome=dict(headerBg="#A8E4E0", headerBorder="#2E7C98", tabFillBottom="#8FD6D6", tabFillTop="#8FD6D6",
                            tabFillActiveBottom="#D2F0E4", tabFillActiveTop="#D2F0E4", iconActive="#0A7C9A",
                            meatballLit="#E0407A"),
                ui=dict(textFaint="#4F8498", accent="#0A7C9A", warn="#B86A00", danger="#D0305E", ok="#16886A"),
                surface=dict(card="#D2F0E4F5", cardEdge="#2E7C98", divider="#9ADEDB", scrim="#06304AC0"),
                display=dict(text="#8CFFF0", textDim="#2E8C9E", textAlt="#C8B4FF", warn="#FF5C94"),
                key=dict(label="#C4F7FF", edgeOff="#25C7C8", bankFaceOff="#031226", bankEdgeOff="#2E7C98",
                         velOn="#0A9CB8"),
                pad=dict(empty="#06182C80", ringWhite="#FFFFFF4D", ringBack="#031226E0"),
                review=dict(bar="#A8E4E0F0", barRule="#06304A22"),
                tracks=dict(backdrop="#7FD3D4", strip="#8FD6D6", rowWithSample="#C2EBE4", rowEmpty="#A8E4E0",
                            rowNotesNoSample="#C8E4F4", text="#06304A", ruler="#1B5674B0", playhead="#D0305EE6",
                            recMarker="#D0305EDC", scrollbar="#06304A26")),
        ),
    },
)

if __name__ == "__main__":
    sys.exit(main(LOOK))
