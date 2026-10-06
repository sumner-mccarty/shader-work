"""Honky-Tonk Neon — a roadhouse at midnight (neon). Brief: Looks/BACKLOG.md#honky-tonk.

    python Tools/looks/honky_tonk.py check | sheet | write | manifest | printcheck

Signature: WARM bar neon on wood, not cyber-blue. Tubes in hot pink, mint and amber bent round dark
weathered boards (WoodGrain, very low intensity, behind the tubes); the dial caps are chickenhead
pointers wrapped in a bent tube. Unlit, like Tron — every glow is emissive.
DARK  = midnight: thin tubes, deep brown-black planks, pink with amber at the tip, mint for "on".
LIGHT = the same sign by day: sun-bleached paint over the same boards, the tubes unlit glass (dull,
        no bloom), so it reads as a roadside sign switched off at noon.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from lookkit import Look, Neon, main, grad, gcol, stops, first, lum, mix, SLOTS  # noqa: E402

# WoodGrain on every board, pixel-locked (rings from a corner - a shader quirk - read as grain at this scale).
# Intensity is per mode: bleached paint shows grain far more readily than black stain.
def wood(intensity, contrast=1.0):
    # long soft grain only: no knot term (p3 0) and no wander (p2 0), so no bullseye rings; px-locked
    return {"_PanelPatternEnabled": 1, "_PanelPatternType": 15, "_PanelPatternScale": 3.0,
            "_PanelPatternIntensity": intensity, "_PanelPatternContrast": contrast, "_PanelPatternParam1": 0.2,
            "_PanelPatternParam2": 0.0, "_PanelPatternParam3": 0.0, "_PanelPatternPx": 600}


WOOD = {"dark": (wood(0.18), wood(0.08)), "light": (wood(0.016, 1.5), wood(0.008, 1.5))}

# LIGHT = unlit glass: a tube that is only pigment under daylight, so no emissive lift and no bloom ring
GLASS = {"_BorderRenderEmissive": 0.0, "_EdgeEnabled": 0}

# A chickenhead cap: round body + a pointer lug, outlined by an unlit bevel band so the lug is a bent tube.
RIM = {"dark": "#3DFFC0", "light": "#4FA68A"}


def chicken(mode):
    return {"_KnobShapeType": 8, "_KnobShapeParam1": 1.0, "_KnobShapeParam2": 0.5, "_KnobShapeParam3": 0.45,
            "_KnobShapeRotation": ROT, "_KnobBevelEnabled": 1, "_KnobBevelDepth": 0.0, "_KnobBevelDistance": 0.09,
            "_KnobBevelSmoothness": 0.14, **grad("_KnobBevel", (RIM[mode],) * 2, (0.0, 1.0)),
            "_KnobEdgeEnabled": 0, "_KnobEdgeColor": RIM[mode], "_KnobEdgeRenderAlpha": 0.0,
            "_KnobEdgeRenderEmissive": 1.0 if mode == "dark" else 0.0, "_KnobEdgeWidth": 0.35,
            "_KnobEdgeInset": 0.0, "_KnobEdgeSoftness": 0.8, "_KnobEdgeIntensity": 0.5 if mode == "dark" else 0.0}


ROT = 270.0

TRACK = {
    "name": "HonkyTonk", "blurb": "Midnight roadhouse: pink, mint and amber on dark boards.",
    "palette": {"row1": "#FF4F9A", "row2": "#3DFFC0", "row3": "#FFB02E", "row4": "#FF7A4A",
                "rail": "#FF5FA8", "laneLine": "#8A4A36", "laneFill": "#120804", "hitLine": "#FFE9D0",
                "receptor": "#E8A27A", "gridBar": "#FFB02E", "gridBeat": "#5A3220",
                "bgTop": "#0A0503", "bgBottom": "#2A140C", "fog": "#7A2E48", "star": "#FFD8B0",
                "miss": "#FF2A4E", "perfect": "#FFF0B8"},
    "props": {"skyMode": 0, "starDensity": 0.12, "horizonGlow": 0.5, "railGlow": 1.25, "noteGlow": 1.1,
              "additive": 0.3, "radiance": 1.0, "gridBrightness": 0.6, "fog": 0.4, "vignette": 0.5},
}

def tint(c, P, k=0.65):
    """The body of a lit tube: a dark (or, in daylight, pale) wash of the tube colour."""
    return mix(c, "#F2E8D0", 0.7) if lum(P["BODY"]) > 0.5 else mix(c, "#0C0605", k)


class HTNeon(Neon):
    """Pressed / on = a LIT TUBE: bright border + glow, the fill only a tint of the tube colour (the kit's
    default floods the key solid). Hover moves the fill and the glow; pads stay warm."""

    @staticmethod
    def lit(P, fill, *, mark=None, halo=None, sheen=None, tube_stops=None):
        pale = lum(P["BODY"]) > 0.5
        st = stops(fill)
        c = st[0]
        body = tint(c, P)
        d = {**gcol("_Button", (body, body)), "_EdgeIntensity": P["HALO_ON"] if halo is None else halo,
             **gcol("_ButtonBevel", (sheen or mix(c, body, 0.45),) * 2), **gcol("_Border", tube_stops or st),
             **gcol("_Edge", st)}
        if mark is not False:
            d["_IconColor"] = mark or (P["ON_MARK"] if pale else P["MARK"])
        return d

    def fader(self, L, P, slot):
        slot, base, states, extra = super().fader(L, P, slot)
        if lum(P["BODY"]) > 0.5:      # daylight: a disabled fader mutes, it never brightens
            states["Disabled"]["_TrackColor"] = "#9A8A6C"
        return slot, base, states, extra

    def keys(self, L, P):
        pale = lum(P["BODY"]) > 0.5
        hov = "#F8F1DF" if pale else "#35190F"
        for slot, base, states, extra in super().keys(L, P):
            if slot == "Accent":
                a, ah = P["ACCENT"], P["ACCENT_HI"]
                body = tint(a[0], P, 0.86)
                slot, base, states, extra = self.key(
                    L, P, "Accent", body=(body, body), tube_stops=(a[0], a[0], a[1], a[1]),
                    sheen_col=mix(a[0], body, 0.5),
                    states={"Hover": {**gcol("_Button", (mix(body, a[0], 0.18),) * 2), **gcol("_Border", ah),
                                      "_EdgeIntensity": P["HALO_ON"] * 1.2},
                            "Pressed": self.lit(P, ah, halo=P["HALO_ON"] * 1.5),
                            "Disabled": {**gcol("_Button", P["ACCENT_DIS"]), **gcol("_Border", P["TUBE_DIS"]),
                                         "_EdgeIntensity": 0.0}})
                base.update(gcol("_Edge", a))
            elif slot in ("Button", "Chip", "ToggleBtn", "Solo", "Lamp") and "Hover" in states:
                states["Hover"].update({**gcol("_Button", (hov, hov)),
                                        "_EdgeIntensity": P["HALO_ON"] * (0.0 if pale else 0.9)})
            elif slot == "Pad":
                states["Hover"].update({"_ButtonRenderEmissive": 0.18 if not pale else 0.0, "_BorderWidth": 0.105 * P["LINE"],
                                        "_EdgeIntensity": P["HALO_ON"] * (0.0 if pale else 1.0)})
                states["Pressed"].update({"_ButtonRenderEmissive": 0.4 if not pale else 0.0, "_BorderWidth": 0.15 * P["LINE"], "_ButtonBevelDistance": 0.3,
                                          "_ButtonBevelSmoothness": 0.3})
                states["Latched"].update({"_ButtonRenderEmissive": 0.0 if pale else 0.3})
                states["Disabled"].update({"_ButtonRenderAlpha": 0.2, "_BorderWidth": 0.035,
                                           "_BorderRenderEmissive": 0.0, "_BorderRenderAlpha": 0.35})
            yield slot, base, states, extra


class HonkyTonk(Look):
    """The kit's `set` hook is per slot, not per mode: route the mode-dependent wood and the chickenhead
    caps through S() while a mode is being built."""
    _mode = "dark"

    def build(self, mode):
        self._mode = mode
        return super().build(mode)

    def S(self, slot):
        d = super().S(slot)
        group = SLOTS[slot][2]
        extra = {}
        if group == "plate":
            extra.update({"_PanelShapeType": 0, "_PanelShapeParam1": 0.98})
        if slot in ("Face", "Back", "Inset"):
            extra.update(WOOD[self._mode][slot == "Inset"])
        if slot in ("Knob", "KnobHero", "KnobSmall"):
            extra.update(chicken(self._mode))
        if self._mode == "light":
            if group == "key":
                extra.update(GLASS)
            elif slot in ("Face", "Well", "Bezel", "Pill"):
                extra.update({"_BorderRenderEmissive": 0.0})
            elif group == "fader":
                extra.update({"_BorderRenderEmissive": 0.0})
            elif group == "dial":
                extra.update({"_OuterRing2RenderEmissive": 0.0})
        return dict(d, set=dict(d.get("set", {}), **extra)) if extra else d


LOOK = HonkyTonk(
    title="Honky-Tonk Neon", style="HonkyTonk", prefix="HonkyTonk", slug="honky-tonk", cls="neon", order=24,
    status="draft", brief="BACKLOG.md#honky-tonk",
    blurb="Warm bar neon - pink, mint and amber tubes over dark weathered boards.",
    tagline="warm bar neon tubes on weathered wood, chickenhead pointers.",
    note="Unlit: the rig has every lamp off. Boards are a low-intensity WoodGrain behind the tubes.",
    displays="tron",
    track_themes={"HonkyTonk": TRACK},
    shape={
        "dial": {"silhouette": "capped", "cap": 0.66, "ring_px": 0.6},
        "key": {"shape": 0, "cut": 0.32, "round": 0.6},
        **{k: {"shape": 0, "cut": 0.32, "round": 0.6} for k in ("Accent", "ToggleBtn", "Solo", "Lamp", "Chip")},
        "Pad": {"shape": 0, "cut": 0.32, "round": 0.6, "sheen": 0.0},
        "Dot": {"line": 0.09, "halo_w": 0.14}, "ScrollHandle": {"line": 0.08, "halo_w": 0.12, "shape": 0, "cut": 0.32, "round": 0.6},
        "KnobHero": {"deco": False},
        "Fader": {"fill": "ARC"},
        "Face": {"cut_px": 14.0}, "Well": {"cut_px": 8.0},
    },
    waive={"light-controls:BODY": "brief: light mode is the same sign switched off - key faces become pale painted glass",
           "light-controls:CAP": "same: pale painted caps carrying the unlit chickenhead tube",
           "light-controls:ACCENT": "same: the mint accent is a pale unlit tube, not a lit one"},
    modes={
        "dark": dict(
            track="HonkyTonk", blurb="Midnight at the roadhouse. Pink, mint and amber neon on dark boards.",
            palette=dict(
                GAP="#050302", BACK="#0E0805", BACK_TOP="#170D07", FACE="#22140C", FACE_TOP="#372113",
                INSET="#0B0604", INSET_TOP="#160C07", SOCKET="#080403", WELL="#050302", WELL_TOP="#0B0604",
                BODY="#150B08", BODY_TOP="#2C1610", DIS_BODY="#0D0706",
                TUBE=("#FF4F9A", "#FF5FA8", "#FF7A4A", "#FFB02E"), TUBE_REST=("#B8386F", "#B03F78", "#B85A38", "#B8801F"),
                TUBE_DIS=("#2E1A14",) * 4, STRUCT="#4A2A1C", STRUCT_HI="#8A5434",
                HALO=("#FF3F8F", "#FF4F8A", "#FF6A3A", "#FFA21F"), HALO_REST=0.5, HALO_HOVER=0.8, HALO_ON=1.2,
                SHEEN="#3A1220", SHEEN_ON="#FFD0A8", ARC_EMIT=0.3, FACE_LINE_PX=1.5, FACE_HALO_PX=3.0,
                FACE_SHEEN=0.03, PLATE_SHEEN="#3A1A10", GRID=0.0, LINE=1.0, BLOOM=1.0,
                MARK="#FFD9B8", MARK_DIM="#A8735C", ON_MARK="#140806", DIS_MARK="#4E3228",
                INK="#FFE3C8", INK_DIM="#B08068",
                ACCENT=("#3DFFC0", "#1FD9A0"), ACCENT_HI=("#8CFFDC", "#5CF0C0"), ACCENT_DIS=("#12342A", "#0E2A22"),
                HOT=("#FF4F8F", "#FF2F6F"), SOLO=("#FFB02E", "#FF8A1F"), LAMP=("#FFD06A", "#FFA82E"),
                ARC_OFF="#5A3524", ARC_OFF_HI="#7A4A30", ARC=("#FFB02E", "#FF7A4A", "#FF4F9A", "#FF4F9A"),
                ARC_GLOW="#FF5F8A", ARC_GLOW_I=0.55,
                CAP="#0C0605", CAP_TOP="#26150E", CAP_RING="#8E2A5C", CAP_RING_HI="#FF5FA8", NEEDLE="#FFE2A0",
                TRACK="#2A1710", HANDLE="#F0A848", HANDLE_HI="#FFD08A",
                PAD_BODY="#1A0C08", PAD_LINE="#FFFFFF", PAD_LINE_TINT=0.85, PAD_HALO_TINT=1.0, PAD_FACE_TINT=0.22,
                PAD_SHEEN_TINT=0.08, SCROLL="#1C0F0A", SCROLL_HI="#2E1810"),
            app=dict(
                chrome=dict(headerBg="#0A0503", headerBorder="#B03F78", tabFillBottom="#120A06", tabFillTop="#120A06",
                            tabFillActiveBottom="#241309", tabFillActiveTop="#32190C", iconActive="#FFB02E",
                            meatballLit="#FF4F9A"),
                ui=dict(textFaint="#6E4A3A", accent="#FF5FA8", warn="#FFC93E", danger="#FF3F5F", ok="#3DFFC0"),
                surface=dict(card="#120A06F5", cardEdge="#B03F78", divider="#2A170E", scrim="#050302C8"),
                display=dict(text="#FFC15A", textDim="#8A5A30", textAlt="#3DFFC0", warn="#FF4F8F"),
                key=dict(edgeOff="#B03F78", bankEdgeOff="#4A2A1C", velOn="#FFB02E"),
                pad=dict(empty="#14090580", ringWhite="#FFFFFF4D", ringBack="#0A0503E0"),
                review=dict(bar="#0A0503F0", barRule="#FF5FA822"),
                tracks=dict(backdrop="#050302", strip="#0A0503", rowWithSample="#241008", rowEmpty="#120804",
                            rowNotesNoSample="#2A0C1C", text="#FFD9B8", ruler="#FFB02EB0", playhead="#FF4F9AE6",
                            recMarker="#FF3F5FDC", scrollbar="#FFB02E26")),
        ),
        "light": dict(
            track="HonkyTonk", blurb="Daytime sign: sun-bleached paint on the same boards, the glass tubes unlit.",
            palette=dict(
                GAP="#7A6648", BACK="#B49C74", BACK_TOP="#C2AB84", FACE="#D9C7A2", FACE_TOP="#E8D9B8",
                INSET="#A58E68", INSET_TOP="#B49C76", SOCKET="#9A8460", WELL="#3A2A20", WELL_TOP="#4A372A",
                BODY="#EADFC4", BODY_TOP="#F6EEDA", DIS_BODY="#D6CAAE",
                TUBE=("#C4698A", "#C86F90", "#C98A68", "#C6A04E"), TUBE_REST=("#B07A92", "#B58298", "#B59078", "#B59E62"),
                TUBE_DIS=("#7F7260",) * 4, STRUCT="#8A7250", STRUCT_HI="#5E4A32",
                HALO=("#E8709E", "#EC7FA6", "#EC9066", "#ECB866"), HALO_REST=0.0, HALO_HOVER=0.25, HALO_ON=0.6,
                SHEEN="#B89C78", SHEEN_ON="#FFE8CC", ARC_EMIT=0.0, FACE_LINE_PX=2.5, FACE_HALO_PX=2.0,
                FACE_SHEEN=0.0, PLATE_SHEEN="#C0A880", GRID=0.0, LINE=1.3, BLOOM=0.3,
                MARK="#3A2418", MARK_DIM="#6E4E3A", ON_MARK="#2C1208", DIS_MARK="#8A7A66",
                INK="#2A160C", INK_DIM="#48301F",
                ACCENT=("#5FB398", "#4A9C82"), ACCENT_HI=("#7FC8AE", "#62B096"), ACCENT_DIS=("#BDC2B0", "#BDC2B0"),
                HOT=("#C8507C", "#B03F68"), SOLO=("#CC8A38", "#B87428"), LAMP=("#D4A848", "#C28F30"),
                PRESS=("#5FB398", "#4A9C82"),
                ARC_OFF="#C4B08A", ARC_OFF_HI="#B09A74", ARC=("#C6A04E", "#C98A68", "#C4698A", "#C4698A"),
                ARC_GLOW="#E8709E", ARC_GLOW_I=0.0,
                CAP="#EFE3C8", CAP_TOP="#F8F0DC", CAP_RING="#C49AAA", CAP_RING_HI="#C4698A", NEEDLE="#8A4A2A",
                TRACK="#8A7452", HANDLE="#E09838", HANDLE_HI="#FFC070",
                PAD_BODY="#E4D6B6", PAD_LINE="#A89674", PAD_LINE_TINT=0.8, PAD_HALO_TINT=0.0, PAD_FACE_TINT=0.14,
                PAD_SHEEN_TINT=0.15, SCROLL="#EADFC4", SCROLL_HI="#F4EAD2"),
            app=dict(
                chrome=dict(headerBg="#9C8660", headerBorder="#5E4A32", tabFillBottom="#B49C74", tabFillTop="#B49C74",
                            tabFillActiveBottom="#D9C7A2", tabFillActiveTop="#E8D9B8", iconActive="#B02A5E",
                            meatballLit="#B02A5E"),
                ui=dict(textFaint="#8A7452", accent="#C93C7E", warn="#B8741A", danger="#C02A4E", ok="#14956E"),
                surface=dict(card="#E8D9B8F5", cardEdge="#5E4A32", divider="#B49C74", scrim="#2A160CC0"),
                display=dict(text="#FFC15A", textDim="#D9A060", textAlt="#3DFFC0", warn="#FF4F8F"),
                key=dict(edgeOff="#B58298", bankEdgeOff="#8A7250", velOn="#E0902A"),
                pad=dict(empty="#4A362A80", ringWhite="#FFFFFF4D", ringBack="#2C1A14E0"),
                review=dict(bar="#9C8660F0", barRule="#2A160C22"),
                tracks=dict(backdrop="#7A6648", strip="#9C8660", rowWithSample="#C2AB84", rowEmpty="#B49C74",
                            rowNotesNoSample="#C8A8A0", text="#2A160C", ruler="#2A160CB0", recMarker="#C02A4EDC",
                            scrollbar="#2A160C26")),
        ),
    },
)

LOOK.kit = HTNeon()

if __name__ == "__main__":
    sys.exit(main(LOOK))
