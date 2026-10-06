"""Graffiti — Street Wall (unlit). Brief: Looks/BACKLOG.md#graffiti.

    python Tools/looks/graffiti.py check | sheet | write | manifest | printcheck

Signature: raw concrete + loud spray colour, all flat. Plates are pixel-locked concrete in
marker-black frames (night wall dark / whitewashed wall light); keys are chalk-grey slabs with a thick
black marker outline; every ON state and every value indicator is SPRAY PAINT - a vertical gradient
(hot magenta over cyan, lime over orange) that reads as a drip. Dial tracks are black marker strokes
with the paint laid over them, a chalk needle on top.

The kit's `unlit` class has no gradient vocabulary for keys/dials/faders, so this spec wraps its part
builders (`SprayKit`): the base part is the class's, the paint and the marker outline are added on
top, and every gradient has a matching Hover/Pressed/Disabled/Active state (a gradient beats a plain
colour write, so a state that only changed `_ButtonColor` would show nothing).
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import lookkit  # noqa: E402
from lookkit import Look, main, grad, gcol, mix  # noqa: E402

INK = "#0B0B0D"                       # marker black: every outline
CHALK = "#F4F1E6"
MAG, CYAN, LIME, ORANGE = "#FF2A8C", "#10D6FF", "#B4FF2A", "#FF7A12"
VIOLET, YELLOW = "#8A2BFF", "#FFD21A"  # saturated mid stops: a paint blend never greys out
# bottom -> top (uv.y is 0 at the bottom on the non-RM shaders): a drip runs from the top colour down
PAINT_A = (CYAN, VIOLET, MAG)         # hot magenta over cyan
PAINT_B = (ORANGE, YELLOW, LIME)      # lime over orange
mix2 = lambda a, b, t: tuple(mix(x, y, t) for x, y in zip(a, b))       # noqa: E731
BRIGHT = lambda st, a=0.28: mix2(st, ("#FFFFFF",) * len(st), a)        # noqa: E731
DARK = lambda st, a=0.22: mix2(st, ("#000000",) * len(st), a)          # noqa: E731
CHALKS = lambda st, a: mix2(st, (CHALK,) * len(st), a)                 # noqa: E731
UP = (0.0, 1.0)
ACROSS = (1.0, 0.0)                   # faders run along the track
DIS_GREY = "#74757A"


class SprayKit(lookkit.Unlit):
    """Unlit vocabulary + marker outlines + spray gradients (see the module docstring)."""
    KEYPAINT = {"Accent": PAINT_B, "ToggleBtn": PAINT_A, "Solo": PAINT_B, "Lamp": PAINT_A}
    # OFF latches are black slabs with a paint-coloured mark (icon colour)
    BLACKKEY = {"ToggleBtn": MAG, "Solo": CYAN, "Lamp": LIME, "Close": CHALK}

    def parts(self, L, P):
        for slot, base, states, extra in super().parts(L, P):
            fn = getattr(self, "paint_" + L_group(slot), None)
            if fn:
                base, states = fn(L, P, slot, base, dict(states))
            if slot == "Pad":      # rows tint every paint stop toward their colour (amount of the way)
                extra = {"padColor": {"targets": [{"param": f"_ButtonGradientColor{c}", "amount": 0.22}
                                                  for c in "ABC"]}}
            yield slot, base, states, extra

    # ── keys: a marker outline that scales with the key; paint when pressed / on ──
    def paint_key(self, L, P, slot, base, states):
        paint = self.KEYPAINT.get(slot)
        base.update({"_BorderEnabled": 1, "_BorderColor": INK})
        if slot in self.BLACKKEY:               # black slab, paint-coloured mark
            base.update({"_ButtonColor": "#17171B", "_IconColor": self.BLACKKEY[slot], "_ButtonRenderAlpha": 1.0})
            states["Hover"] = {"_ButtonColor": "#34343B", "_IconColor": "#FFFFFF"}
            if slot == "Close":
                states["Pressed"] = dict(states["Pressed"], _ButtonColor=MAG)
                states["Disabled"] = {"_ButtonColor": DIS_GREY, "_IconColor": P["DIS_MARK"]}
                return base, states
        if slot == "Pad":                       # the brief's pair, tinted per row through padColor
            base.update(grad("_Button", PAINT_A, UP))
            states["Disabled"] = dict(states["Disabled"], _ButtonGradientEnabled=0)
            # latched = a thick white ring (hover only lifts the paint)
            states["Latched"] = dict(states.get("Latched", {}), _BorderEnabled=1, _BorderColor="#FFFFFF",
                                     _BorderWidth=0.2, _ButtonRenderEmissive=0.0)
            return base, states
        if slot == "ScrollHandle":
            states["Pressed"] = dict(states["Pressed"], **grad("_Button", DARK(PAINT_A, 0.35), UP))
            return base, states
        if slot in ("Button", "Chip"):          # chalk slab; paint on hover (pale) and press (full)
            full = PAINT_A if slot == "Button" else PAINT_B
            base["_ButtonColor"] = CHALK
            states["Hover"] = dict(states["Hover"], **grad("_Button", CHALKS(full, 0.5), UP))
            states["Pressed"] = dict(states["Pressed"], **grad("_Button", full, UP))
            states["Disabled"] = dict(states["Disabled"], _ButtonColor=DIS_GREY)
            return base, states
        if not paint:
            return base, states
        if slot == "Accent":                    # full paint at rest
            base.update(grad("_Button", paint, UP))
            states["Hover"] = dict(states["Hover"], **gcol("_Button", BRIGHT(paint, 0.35)))
            states["Pressed"] = dict(states["Pressed"], **gcol("_Button", DARK(paint, 0.3)))
            states["Disabled"] = dict(states["Disabled"], _ButtonGradientEnabled=0, _ButtonColor=DIS_GREY)
        else:                                   # latch: black OFF, paint ON
            states["Active"] = dict(states["Active"], **grad("_Button", paint, UP))
            states["Pressed"] = dict(states["Pressed"], **grad("_Button", paint, UP))
            states["Disabled"] = dict(states["Disabled"], _ButtonGradientEnabled=0, _ButtonColor=DIS_GREY)
            if slot == "Lamp":                  # the lamp's ring is paint at rest
                base.update(grad("_Border", PAINT_A, UP))
                states["Disabled"]["_BorderGradientEnabled"] = 0
        return base, states

    # ── dials: a black marker disc, paint laid over its track, chalk needle ──
    def paint_dial(self, L, P, slot, base, states):
        sub = L.S(slot).get("subline", 0.62)
        base.update(grad("_LineSublineFilled", PAINT_A, UP))
        base.update({"_LineColor": INK, "_LineRenderAlpha": 1.0, "_LineSublineThickness": sub,
                     "_FillEnabled": 1, "_FillColor": "#26262B", "_FillRenderAlpha": 1.0, "_FillRenderEmissive": 0.0})
        states["Hover"] = dict(states["Hover"], **gcol("_LineSublineFilled", BRIGHT(PAINT_A, 0.18)))
        states["Pressed"] = dict(states["Pressed"], **gcol("_LineSublineFilled", BRIGHT(PAINT_A, 0.4)))
        states["Disabled"] = dict(states["Disabled"], _LineSublineFilledGradientEnabled=0,
                                  _LineSublineFilledColor="#8C8C92", _LineSublineUnfilledColor="#5A5A60",
                                  _NubColor="#A0A0A6", _FillColor="#4A4A50")
        return base, states

    def paint_fader(self, L, P, slot, base, states):
        if slot == "Fader":                     # the zoom fader stays quiet chalk on the gutter
            return base, states
        # a black marker slot behind the painted track
        base.update({"_BgEnabled": 1, "_BgColor": INK, "_BorderEnabled": 0})
        base.update(grad("_TrackValueFilled", PAINT_B, ACROSS))
        states["Hover"] = dict(states["Hover"], **gcol("_TrackValueFilled", BRIGHT(PAINT_B, 0.18)))
        states["Pressed"] = dict(states["Pressed"], **gcol("_TrackValueFilled", BRIGHT(PAINT_B, 0.4)))
        states["Disabled"] = dict(states["Disabled"], _TrackValueFilledGradientEnabled=0,
                                  _TrackValueFilledColor="#8C8C92", _TrackColor="#5A5A60",
                                  _HandleColor="#A8A8AE")
        return base, states

    def paint_switch(self, L, P, slot, base, states):
        return base, states

    # ── plates: stained, px-locked concrete in a marker frame ──
    def paint_plate(self, L, P, slot, base, states):
        S = L.S(slot)
        base.update({"_BorderEnabled": 1, "_BorderColor": INK, "_BorderWidthPx": S["frame_px"],
                     "_BorderWidth": 0.02, "_BorderSoftness": 0.0})
        if S["stain"] and slot in ("Face", "Back", "Inset", "Socket"):
            fill = P[S["fill"]]                  # water stain: the foot of the wall runs darker
            k = S["stain"] * P.get("STAIN_K", 1.0)
            base.update(grad("_Panel", (mix(fill, "#000000", k), mix(fill, "#000000", k * 0.35), fill), UP))
        if S["grain"]:
            base.update({"_PanelPatternEnabled": 1, "_PanelPatternType": 7,
                         "_PanelPatternScale": round(S["grain_px"] / S["grain_cell"], 2),
                         "_PanelPatternPx": S["grain_px"], "_PanelPatternIntensity": S["grain"] * P.get("GRAIN_K", 1.0),
                         "_PanelPatternContrast": S["contrast"], "_PanelPatternParam1": 0.5,
                         "_PanelPatternParam2": 0.5, "_PanelPatternParam3": 0.0})
        return base, states


def L_group(slot):
    return lookkit.SLOTS[slot][2]


CONTROLS = dict(                      # the hardware - identical in both modes
    BODY="#EDEAE0", BODY_HI="#FFFFFF", PRESS="#7C7D82", BORDER=INK,
    MARK="#121214", MARK_DIM="#34353A", DIS_BODY="#74757A", DIS_MARK="#4E4F54", ON_MARK="#0B0B0D",
    ACCENT=MAG, ACCENT_HI="#FF63AE", ACCENT_LO="#C8156F", ACCENT_DIS="#74757A",
    SOLO=CYAN, LAMP=LIME, HOT=ORANGE,
    ARC_OFF="#26262B", ARC_OFF_HI="#34343A", VALUE=CHALK, VALUE_HI="#FFFFFF", DIS_ARC="#2A2A2E",
    TRACK="#2C2C32", HANDLE=CHALK, HANDLE_HI="#FFFFFF",
    PAD_BODY="#8E8F94", PAD_TINT=0.8, PAD_LATCH="#0B0B0D", SCROLL="#8A8B90", SCROLL_HI=CYAN,
)

LOOK = Look(
    title="Street Wall", style="Graffiti", prefix="Graffiti", slug="graffiti", cls="unlit", order=24,
    status="draft", brief="BACKLOG.md#graffiti",
    blurb="Raw concrete in marker-black frames and loud spray paint. All flat.",
    tagline="unlit concrete, marker outlines, spray-paint gradients.",
    note="The rig (Themes/Graffiti.theme) has every lamp off; all the colour is flat paint.",
    displays="flat",
    shape={
        "key": dict(corner=0.6, stroke=0.16), "ToggleBtn": dict(icon_size=0.72), "Solo": dict(icon_size=0.72), "Lamp": dict(icon_size=0.78), "Close": dict(icon_size=0.55),
        "dial": dict(silhouette="needle", arc_outer=0.9),
        "Knob": dict(px=44, stroke_px=8.0, needle_px=2.5),
        "KnobHero": dict(px=96, stroke_px=12.0, needle_px=4.0),
        "KnobSmall": dict(px=36, stroke_px=7.5, needle_px=2.5),
        "fader": dict(track_w=0.3, handle_w=0.14),
        "plate": dict(frame_px=3.0, grain=0.16, contrast=1.7, stain=0.4, grain_px=200, grain_cell=2.5, pad_px=3.0),
        "Face": dict(radius_px=3.0), "Back": dict(frame_px=0.0, grain=0.10),
        "Well": dict(grain=0.0), "Bezel": dict(grain=0.0), "ScrollTrack": dict(frame_px=1.5, grain=0.0),
    },
    modes={
        "dark": dict(
            track="Nebula", blurb="Night wall. Dark concrete, black marker, paint that glows against it.",
            palette=dict(CONTROLS, GAP="#141311", BACK="#2E2C29", WELL="#17171A", INSET="#47443F",
                         SOCKET="#3B3935", FACE="#55524D", PRINT_DIM="#B8B8BC",
                         INK="#F2EFE4", INK_DIM="#C2C0B6"),
            app=dict(display=dict(text=CYAN, textDim="#2A8FA8", textAlt=MAG),
                     ui=dict(accent=MAG), key=dict(label="#121214"),
                     tracks=dict(rowWithSample="#5A5B60"))),
        "light": dict(
            track="Rosewater", blurb="Whitewashed wall. Pale concrete, the same marker and paint.",
            palette=dict(CONTROLS, GAP="#9C9A92", BACK="#BDBAB0", WELL="#E6E3D8", INSET="#CFCCC1",
                         SOCKET="#C8C5BA", FACE="#DEDBD0", PRINT_DIM="#4A4A4E", GRAIN_K=0.5, STAIN_K=0.3),
            app=dict()),
    },
)
LOOK.kit = SprayKit()

if __name__ == "__main__":
    sys.exit(main(LOOK))
