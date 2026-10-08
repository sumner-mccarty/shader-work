"""Synthwave Dark + Synthwave Light — the 1980s sunset-and-grid look on the kit's `neon` class.

    python Tools/looks/synthwave.py check | write | sheet | printcheck | manifest

Neon (unlit light tubes, no lamp rig) — but where Tron is cyan tubes on navy-black glass, Synthwave is
the SUNSET: every plate is a vertical sky gradient (indigo -> violet -> magenta -> horizon orange), the
tubes burn hot magenta -> orange -> yellow, the hardware (cap rings, pointers, slider handles) is
chrome-cyan tubes (cyan body, white highlight arc), and ONE grid (Circuit) runs under everything: dark ink lines on
the Face that show toward the bright horizon, glowing lines on the floor plates. Keys and plates are soft squircles,
not Tron's chamfered octagons.
DARK  = midnight drive: deep indigo-to-orange sky behind black-violet glass keys with burning tubes.
LIGHT = pastel vaporwave: the chassis turns lilac / peach / mint, the glass keys and their tubes stay.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from lookkit import Look, gcol, main  # noqa: E402


# dial geometry the kit derives its cap ring from (Neon.dial): kept in one table so the chrome tube, its
# highlight and the hover ring are computed from the same numbers as the kit's own ring
DIALS = {"Knob": dict(px=44, arc_px=2.5, cap=0.58), "KnobHero": dict(px=96, arc_px=3.5, cap=0.55),
         "KnobSmall": dict(px=36, arc_px=2.8, cap=0.56)}
ARC_OUTER = 0.86


def ring(slot, line, mult):
    """(radius, thickness) of the cap ring at `mult` x the kit's 1 px tube; the inner edge stays on the cap."""
    d = DIALS[slot]
    u = 2.0 / d["px"]
    r = ARC_OUTER - d["arc_px"] * u
    t = u * line / r * mult
    return d["cap"] + t * 0.5, t


def chrome(slot, line):
    """The cap ring as a chrome-cyan TUBE: a fatter, less blown-out cyan ring with a white highlight arc on the
    upper-left (OuterRing3), instead of the kit's flat cyan line."""
    rad, t = ring(slot, line, 1.5)
    return {"_OuterRing2Radius": rad, "_OuterRing2Thickness": t, "_OuterRing2RenderEmissive": 0.25,
            "_OuterRing3Enabled": 1, "_OuterRing3Style": 0, "_OuterRing3Radius": rad, "_OuterRing3Thickness": t * 0.38,
            "_OuterRing3Color": "#FFFFFF", "_OuterRing3AngleStart": 205, "_OuterRing3AngleRange": 95,
            "_OuterRing3RenderAlpha": 1.0, "_OuterRing3RenderEmissive": 1.0}


def knob_states(line, glow, cap_a, cap_b):
    """Hover must read at 30 px: the ring goes white and fat, the cap lifts, the arc glow doubles."""
    out = {}
    for slot in DIALS:
        rad, t = ring(slot, line, 2.1)
        out[slot] = {"Hover": {"_OuterRing2Radius": rad, "_OuterRing2Thickness": t, "_OuterRing2Color": "#FFFFFF",
                               "_OuterRing2RenderEmissive": 0.6, "_LineSublineGlowIntensity": glow * 2.6,
                               **gcol("_Knob", (cap_a, cap_b))},
                     "Disabled": {"_OuterRing3Enabled": 0}}
    return out


KEY_LINE = {"Button": 0.09, "ToggleBtn": 0.075, "Solo": 0.075, "Lamp": 0.08, "Chip": 0.08}


def key_states(line, halo, a, b):
    """Hover on a glass key: the body lifts toward violet, the tube fattens and the bloom opens (a gradient
    beats any colour write, so the body is a gradient delta)."""
    out = {k: {"Hover": {**gcol("_Button", (a, b)), "_BorderWidth": w * line * 1.5, "_EdgeIntensity": halo}}
           for k, w in KEY_LINE.items()}
    out["Dot"] = {"Hover": {**gcol("_Button", ("#8444CC", "#C070F4")), **gcol("_Border", ("#FF2EC4", "#FF9A2E")),
                            "_BorderWidth": 0.1 * line, "_EdgeIntensity": halo}}
    return out


def pad_states(emissive):
    """Pads: Normal = dark glass + thin row-coloured rim (no inner sheen); Hover = fatter rim, strong bloom and
    a lifted body (no inner frame); Pressed = flood in the row colour; Latched = glowing MAGENTA whatever the row (a gradient
    on a layer beats the row-colour binding, so the ON colour is the look's, not the row's)."""
    return {"Hover": {"_ButtonRenderEmissive": 0.7, "_EdgeIntensity": 1.6, "_BorderWidth": 0.12},
            "Pressed": {"_ButtonBevelEnabled": 1, "_ButtonRenderEmissive": 0.6},
            "Latched": {"_BorderGradientEnabled": 1, **gcol("_Border", ("#FF7AE0", "#FF2EC4")),
                        "_EdgeGradientEnabled": 1, **gcol("_Edge", ("#FF2EC4", "#FF2EC4")),
                        "_ButtonGradientEnabled": 1, **gcol("_Button", ("#78095A", "#D81C9A")),
                        "_ButtonRenderEmissive": emissive, "_BorderWidth": 0.13, "_EdgeIntensity": 1.5}}


def grid(col, inten=0.15, contrast=2.0, ink=False):
    """The ONE grid: Circuit's orthogonal traces, pixel-locked (120 px tile, 3 cycles), in a pattern colour. On
    dark plates it is ADDED (lines glow); on a bright plate it is MULTIPLIED (lines print dark / lilac), which also
    makes it show most where a plate is brightest - toward the sunset horizon."""
    return {"_PanelPatternEnabled": 1, "_PanelPatternType": 18, "_PanelPatternScale": 3.0, "_PanelPatternPx": 120,
            "_PanelPatternIntensity": inten, "_PanelPatternContrast": contrast,
            "_PanelPatternParam1": 0.5, "_PanelPatternParam2": 0.0, "_PanelPatternParam3": 0.0,
            "_PanelPatternColorEnabled": 1, "_PanelPatternColorType": 1, "_PanelPatternColorMode": 3 if ink else 2,
            "_PanelPatternColorUsed": 2, "_PanelPatternColorA": "#FFFFFF" if ink else "#000000",
            "_PanelPatternColorB": col}


LOOK = Look(
    title="Synthwave", style="Synthwave", prefix="Synthwave", slug="synthwave", cls="neon", order=31, status="candidate",
    brief="BACKLOG.md#synthwave",
    blurb="Sunset gradient plates, hot magenta-to-orange tubes, chrome-cyan hardware, a neon grid floor.",
    tagline="unlit, non-raymarched neon on a sunset sky.",
    note="The rig (Themes/Synthwave.theme) has every lamp off: all the light on screen is emissive - tube\n"
         "cores, additive blooms, arc glows - over plates that are authored sky gradients.",
    displays="tron",
    shape={
        # soft squircles instead of Tron's chamfered octagons
        "key": {"shape": 0, "cut": 0.62},
        "Pad": {"cut": 0.7},
        "dial": {"silhouette": "capped"},
        "Knob": DIALS["Knob"], "KnobSmall": DIALS["KnobSmall"],
        "KnobHero": {**DIALS["KnobHero"], "deco": False},          # no detached outer "ears": ticks only
        "Fader": {"fill": ("FADER_A", "FADER_B")},
        "plate": {"set": {"_PanelShapeType": 0, "_PanelShapeParam1": 0.9}},
        "Face": {"fill": ("FACE", "FACE_B", "FACE_C", "FACE_TOP"), "cut_px": 16.0,
                 "set": {"_PanelShapeType": 0, "_PanelShapeParam1": 0.9}},
    },
    modes={
        "dark": dict(
            track="Sunset", blurb="Midnight drive: a sunset sky behind black-violet glass and burning tubes.",
            palette=dict(
                # the sky: horizon orange at the bottom, up through magenta and violet to night indigo
                GAP="#07021A", BACK="#0A0320", BACK_TOP="#2E0C4E",
                FACE="#C04516", FACE_B="#9A1478", FACE_C="#451478", FACE_TOP="#140A44",
                INSET="#0A0322", INSET_TOP="#1C0A3C", SOCKET="#07021A", WELL="#4A1240", WELL_TOP="#060220",
                BODY="#14062E", BODY_TOP="#46176E", DIS_BODY="#0B0418",
                TUBE=("#FF2EC4", "#FF4F9A", "#FF7A3C", "#FFB02E"), TUBE_REST=("#E0209E", "#E8468C", "#F0703A", "#F2A02A"),
                TUBE_DIS=("#2D1648",) * 4, STRUCT="#5A1C7E", STRUCT_HI="#B03CC8",
                HALO=("#FF2EC4", "#FF4F7A", "#FF7A2F", "#FFB02E"), HALO_REST=0.5, HALO_HOVER=0.85, HALO_ON=1.2,
                SHEEN="#4A1668", SHEEN_ON="#FFD0F0", ARC_EMIT=0.3, FACE_LINE_PX=1.6, FACE_HALO_PX=4.0,
                FACE_SHEEN=0.025, PLATE_SHEEN="#8A1AA0", GRID=0.0, LINE=1.0, BLOOM=1.0,
                MARK="#FFE9FB", MARK_DIM="#B07AC8", ON_MARK="#14062A", DIS_MARK="#4A2A66",
                INK="#FFF1FC", INK_DIM="#FFE0F6",
                ACCENT=("#E01FA8", "#FF4FC8"), ACCENT_HI=("#FF4FC8", "#FF8AE0"), ACCENT_DIS=("#3A1048", "#2A0C3A"),
                HOT=("#FF2EC4", "#FF1F8E"), SOLO=("#4DE8FF", "#2CB8F0"), LAMP=("#FFD84D", "#FF9A2E"),
                PRESS=("#D6199E", "#F03CB8"),
                ARC_OFF="#5A2E90", ARC_OFF_HI="#7A40AC", ARC=("#FF2EC4", "#FF5C8A", "#FF9A2E", "#FFE066"),
                ARC_GLOW="#FF3FA8", ARC_GLOW_I=0.55,
                CAP="#0A0320", CAP_TOP="#3A1668", CAP_RING="#6FE8FF", CAP_RING_HI="#E8FFFF", NEEDLE="#E8FFFF",
                TRACK="#2A1046", HANDLE="#D6FAFF", HANDLE_HI="#FFFFFF", FADER_A="#FF2EC4", FADER_B="#FF9A2E",
                PAD_BODY="#0A0320", PAD_LINE="#FFFFFF", PAD_LINE_TINT=0.85, PAD_HALO_TINT=1.0, PAD_FACE_TINT=0.18,
                PAD_SHEEN_TINT=0.5, SCROLL="#4A1A6E", SCROLL_HI="#9A3CC0"),
            # ONE grid (Circuit) on every plate: dark ink lines on the Face (they show toward the bright horizon),
            # glowing lines on the floor plates; chrome-tube cap rings; magenta pill ON
            set={"Face": grid("#05011A", 0.15, 3.0, ink=True), "Inset": grid("#2A8CA8"), "Back": grid("#7A2A8A"),
                 "Socket": grid("#30206A"),
                 "Pad": {"_ButtonBevelEnabled": 0, "_BorderWidth": 0.065, "_ButtonBevelGradientColorA": "#1C0B34",
                         "_ButtonBevelGradientColorB": "#1C0B34"},
                 "Pill": {"_LedColor": "#FF2EC4"}, **{k: chrome(k, 1.0) for k in DIALS}},
            states={**key_states(1.0, 1.4, "#3A1670", "#7A36C0"), **knob_states(1.0, 0.55, "#3A1668", "#6A2AA8"),
                    # a pressed accent key sinks to a deeper magenta (it is lit at rest, so it cannot get brighter)
                    "Accent": {"Pressed": gcol("_Button", ("#98106E", "#C42A98"))},
                    "Pad": pad_states(0.4)},
            app=dict(
                chrome=dict(headerBg="#0A0320", headerBorder="#B03CC8", tabFillBottom="#0E0630", tabFillTop="#0E0630",
                            tabFillActiveBottom="#2A0C48", tabFillActiveTop="#3A1260", iconActive="#FF5CD0",
                            meatballLit="#FF9A2E"),
                ui=dict(textFaint="#7A4A96", accent="#FF5CD0", warn="#FFD84D", danger="#FF3F8F", ok="#4DF0C8"),
                surface=dict(card="#0E0630F5", cardEdge="#B03CC8", divider="#2A0C48", scrim="#07021AC8"),
                display=dict(text="#FFD0F4", textDim="#A06AB8", textAlt="#7FF0FF", warn="#FF9A2E"),
                key=dict(edgeOff="#E0209E", bankEdgeOff="#5A1C7E", velOn="#FF5CD0"),
                pad=dict(empty="#0A032080", ringWhite="#FFFFFF4D", ringBack="#07021AE0"),
                review=dict(bar="#0A0320F0", barRule="#FF5CD022"),
                tracks=dict(backdrop="#07021A", strip="#0A0320", rowWithSample="#1C0A3C", rowEmpty="#100636",
                            rowNotesNoSample="#3A0C3A", text="#EBC8F2", ruler="#FF5CD0B0", playhead="#FFD84DE6",
                            recMarker="#FF3F8FDC", scrollbar="#FF5CD026")),
        ),
        "light": dict(
            track="Sunset", blurb="Pastel vaporwave: lilac, peach and mint chassis, the same glass keys and tubes.",
            palette=dict(
                GAP="#C9BBEA", BACK="#A8E2D0", BACK_TOP="#D2C6F6",
                FACE="#F2B896", FACE_B="#F29CC2", FACE_C="#C4A2F0", FACE_TOP="#A4B4F0",
                INSET="#C0ECDD", INSET_TOP="#DAF6EC", SOCKET="#B9A5E8", WELL="#1A0B3A", WELL_TOP="#2A1058",
                BODY="#1D0B3E", BODY_TOP="#4A1D7A", DIS_BODY="#7A6A9A",
                TUBE=("#D6169C", "#E0347C", "#E4601F", "#E08A24"), TUBE_REST=("#C8168F", "#D63078", "#DC5A1F", "#D88422"),
                TUBE_DIS=("#9A8AB8",) * 4, STRUCT="#8A6AC0", STRUCT_HI="#6A3CA8",
                HALO=("#FF4FC8", "#FF6A9A", "#FF9A4A", "#FFC060"), HALO_REST=0.25, HALO_HOVER=0.4, HALO_ON=0.6,
                SHEEN="#5A2A8A", SHEEN_ON="#FFD0F0", ARC_EMIT=0.15, FACE_LINE_PX=2.2, FACE_HALO_PX=3.0,
                FACE_SHEEN=0.0, PLATE_SHEEN="#B08AE0", GRID=0.0, LINE=1.3, BLOOM=0.6, TUBE_EM=0.04, HALO_EM=0.25,
                MARK="#FFF1FC", MARK_DIM="#C8A0E0", ON_MARK="#14062A", DIS_MARK="#5A4A7A",
                INK="#2A0F55", INK_DIM="#5B2F86",
                ACCENT=("#E01FA8", "#FF4FC8"), ACCENT_HI=("#FF4FC8", "#FF8AE0"), ACCENT_DIS=("#8A7AA8", "#7A6A98"),
                HOT=("#E01FA8", "#C8168F"), SOLO=("#1CC8E8", "#14A0D0"), LAMP=("#F2A02A", "#E8681F"),
                PRESS=("#D6199E", "#F03CB8"),
                ARC_OFF="#3A1C60", ARC_OFF_HI="#4A2878", ARC=("#FF2EC4", "#FF5C8A", "#FF9A2E", "#FFC84A"),
                ARC_GLOW="#FF3FA8", ARC_GLOW_I=0.3,
                CAP="#12062A", CAP_TOP="#34104E", CAP_RING="#4FD8F0", CAP_RING_HI="#B8F4FF", NEEDLE="#E8FFFF",
                TRACK="#6A4A96", HANDLE="#D6FAFF", HANDLE_HI="#FFFFFF", FADER_A="#FF2EC4", FADER_B="#FF9A2E",
                PAD_BODY="#12062A", PAD_LINE="#FFFFFF", PAD_LINE_TINT=0.85, PAD_HALO_TINT=1.0, PAD_FACE_TINT=0.18,
                PAD_SHEEN_TINT=0.5, SCROLL="#8A6AC0", SCROLL_HI="#6A3CA8"),
            # plate tubes burn at emissive 1.0 in the kit (clips on pastel): turn the burn down on daylight plates;
            # the same ONE grid, INKED (multiply) in lilac - an additive line would vanish on pastel
            set={"plate": {"_BorderRenderEmissive": 0.12, "_EdgeRenderEmissive": 0.3},
                 "Face": grid("#9C84D0", 0.11, 2.0, ink=True), "Inset": grid("#A4C8D4", 0.10, 1.8, ink=True),
                 "Back": grid("#9C84D0", 0.11, 2.0, ink=True), "Socket": grid("#8A78C8", 0.10, 1.8, ink=True),
                 "Pad": {"_ButtonBevelEnabled": 0, "_BorderWidth": 0.07, "_ButtonBevelGradientColorA": "#2A1450",
                         "_ButtonBevelGradientColorB": "#2A1450"},
                 "Pill": {"_LedColor": "#E01FA8"},
                 # dark glass troughs: a chrome handle needs a dark bed on pastel plates
                 "Slider": {"_BgColor": "#1D0B3E", "_BgGradientColorA": "#1D0B3E", "_BgGradientColorB": "#3A1668"},
                 "Fader": {"_BgColor": "#1D0B3E", "_BgGradientColorA": "#1D0B3E", "_BgGradientColorB": "#3A1668"},
                 **{k: chrome(k, 1.3) for k in DIALS}},
            states={**key_states(1.3, 0.9, "#4A2088", "#8444CC"), **knob_states(1.3, 0.3, "#4A1C80", "#7A3AB8"),
                    "Accent": {"Pressed": gcol("_Button", ("#98106E", "#C42A98"))},
                    "Pad": pad_states(0.3)},
            app=dict(
                chrome=dict(headerBg="#E0D4F8", headerBorder="#8A6AC0", tabFillBottom="#D4C6F2", tabFillTop="#D4C6F2",
                            tabFillActiveBottom="#F0E6FF", tabFillActiveTop="#F0E6FF", iconActive="#C8168F",
                            meatballLit="#E8681F"),
                ui=dict(textFaint="#8A6AB0", accent="#C8168F", warn="#C86A10", danger="#C8168F", ok="#1A9A7A"),
                surface=dict(card="#F0E6FFF5", cardEdge="#8A6AC0", divider="#B8A4E0", scrim="#2A0F55C0"),
                display=dict(text="#FFD0F4", textDim="#B08ADA", textAlt="#7FF0FF", warn="#FFB04A"),
                key=dict(label="#FFF1FC", edgeOff="#C8168F", bankFaceOff="#1D0B3E", bankEdgeOff="#8A6AC0",
                         velOn="#E01FA8"),
                pad=dict(empty="#12062A80", ringWhite="#FFFFFF4D", ringBack="#12062AE0"),
                review=dict(bar="#E0D4F8F0", barRule="#2A0F5522"),
                tracks=dict(backdrop="#C9BBEA", strip="#D4C6F2", rowWithSample="#E4D8FA", rowEmpty="#D8CCF4",
                            rowNotesNoSample="#F2C8E4", text="#2A0F55", ruler="#5B2F86B0", playhead="#C8168FE6",
                            recMarker="#C8168FDC", scrollbar="#2A0F5526")),
        ),
    },
)

if __name__ == "__main__":
    sys.exit(main(LOOK))
