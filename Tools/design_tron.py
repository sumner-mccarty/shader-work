"""Tron Dark + Tron Light — unlit, non-RM, emissive vector HUD. One generator, one table per mode.

    python Tools/design_tron.py write [dark|light|both]   # Assets/Resources/MaterialStates/TronDark*/TronLight*
    python Tools/design_tron.py check                      # validate every part, write nothing
    python Tools/design_tron.py sheet <dark|light> <tag>   # render a device mock at app sizes (no Assets write)
    python Tools/design_tron.py recipe                     # Resources/UiStyles/Tron.style.json

THE PREMISE (2026-09-14). Tron is Flat's sibling — same unlit, non-raymarched, every-guard-set
rules (see design_flat.py) — but where Flat gets form from value steps, Tron gets it from LIGHT
TUBES on a black floor. Every tube is built from three layers the non-RM shaders already have:

  * CORE  — the Border band, emissive, coloured by a 4-stop gradient (blue with a hint of pink at
            its far end in Dark; blown out to a near-white core in Light).
  * BLOOM — the Edge ring with render-alpha 0 and emissive 1. Blend is `One OneMinusSrcAlpha`, so a
            zero-alpha emissive pixel is pure ADDITIVE light on whatever is behind the widget — a
            real halo spilling onto the plate, inside the widget's own padding, no shadow pass.
  * SHEEN — the body's bevel band. Unlit, the bevel has no normal to shade, so its gradient is just
            a colour band fading in from the outline: the tube's light caught on the black glass.

DARK  = the grid at night: thin tubes, deep navy-black glass, blue→violet with pink at the tip.
LIGHT = the Legacy cockpit: SAME black room, but the tubes are wide and white-hot, the bloom is
        big and pale cyan, and the glass catches enough of it that the black recedes.
"""
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from skinlib import skin, props, BOUNDS, FAMILY, mix  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
SC = ROOT / ".skinsheet" / "tron"

MODES = {
    "dark": dict(
        prefix="TronDark",
        # the floor: gaps are pure void, plates are navy-black glass lifted a hair at the top
        GAP="#000205", BACK="#01040A", BACK_TOP="#020812",
        FACE="#02060D", FACE_TOP="#07121F", INSET="#01040A", INSET_TOP="#030A14",
        SOCKET="#01040A", WELL="#000307", WELL_TOP="#01060D",
        BODY="#02070E", BODY_TOP="#081628", DIS_BODY="#02050A",
        # one tube, four stops left→right: cyan, azure, indigo, and pink only at the tip
        TUBE=("#2BE4FF", "#3D9BFF", "#6D6BFF", "#FF4FD8"),
        TUBE_REST=("#1597B8", "#2067B0", "#4644A8", "#A8338F"),
        TUBE_DIS=("#0A2533", "#0A2533", "#0A2533", "#0A2533"),
        STRUCT="#0C3448", STRUCT_HI="#17597A",
        HALO=("#1FC8FF", "#2F8BFF", "#5A5CFF", "#FF3FC8"),
        HALO_REST=0.50, HALO_HOVER=0.80, HALO_ON=1.2,
        SHEEN="#082038", SHEEN_ON="#9FF3FF", ARC_EMIT=0.3, FACE_LINE_PX=1.5, FACE_HALO_PX=3.0, FACE_SHEEN=0.035, PLATE_SHEEN="#0B2A4A",
        LINE=1.0, BLOOM=1.0,
        MARK="#BDF5FF", MARK_DIM="#4B86A6", ON_MARK="#01060C", DIS_MARK="#1F4254",
        ACCENT=("#33E6FF", "#3F8CFF"), ACCENT_HI=("#7DF1FF", "#77AEFF"), ACCENT_DIS=("#0B2C3A", "#0B2440"),
        HOT=("#FF4FB8", "#FF3F8F"), SOLO=("#33E6FF", "#3FA6FF"), LAMP=("#7FF6FF", "#33E6FF"),
        ARC_OFF="#0B2333", ARC_OFF_HI="#113348", ARC=("#2BE4FF", "#3D9BFF", "#6D6BFF", "#FF4FD8"),
        ARC_GLOW="#22C4FF", ARC_GLOW_I=0.55,
        CAP="#01050B", CAP_TOP="#0A1B2D", CAP_RING="#1A7FA5", CAP_RING_HI="#2BE4FF", NEEDLE="#E6FCFF",
        TRACK="#0A1F2E", HANDLE="#E6FCFF", HANDLE_HI="#FFFFFF",
        PAD_BODY="#02060C", PAD_LINE="#FFFFFF", PAD_LINE_TINT=0.85, PAD_HALO_TINT=1.0, PAD_FACE_TINT=0.04,
        PAD_SHEEN_TINT=0.18,
        SCROLL="#0E3A52", SCROLL_HI="#1D6F95",
    ),
    "light": dict(
        prefix="TronLight",
        # the same black room — glossy charcoal glass that catches the strips
        GAP="#030405", BACK="#08090B", BACK_TOP="#0F1215",
        FACE="#0C1013", FACE_TOP="#2C363C", INSET="#07090B", INSET_TOP="#161B1F",
        SOCKET="#060708", WELL="#030405", WELL_TOP="#07090B",
        BODY="#1A2025", BODY_TOP="#3A464D", DIS_BODY="#0E1114",
        # the tube is blown out: white core, a breath of cyan and pink at the ends
        TUBE=("#E9FCFF", "#FFFFFF", "#FFFFFF", "#FFEAF8"),
        TUBE_REST=("#CDEFF7", "#E6F4F8", "#E9E8F4", "#F1D9E9"),
        TUBE_DIS=("#2B3439", "#2B3439", "#2B3439", "#2B3439"),
        STRUCT="#3B4A52", STRUCT_HI="#7F9AA6",
        HALO=("#7FE6FF", "#A6EEFF", "#B9C8FF", "#FFB3E4"),
        HALO_REST=0.8, HALO_HOVER=1.1, HALO_ON=1.5,
        SHEEN="#56666E", SHEEN_ON="#FFFFFF", ARC_EMIT=0.8, FACE_LINE_PX=2.5, FACE_HALO_PX=4.0, FACE_SHEEN=0.0, PLATE_SHEEN="#4A5A62",
        LINE=1.8, BLOOM=1.5,
        MARK="#FFFFFF", MARK_DIM="#A7BAC2", ON_MARK="#06080A", DIS_MARK="#48545A",
        ACCENT=("#4CC6E6", "#2285B3"), ACCENT_HI=("#72D8F2", "#3499C6"), ACCENT_DIS=("#20272B", "#20272B"),
        HOT=("#F062B8", "#B8378A"), SOLO=("#3CC8EC", "#1E8FC0"), LAMP=("#5ED8F2", "#239FCC"),
        PRESS=("#4CC6E6", "#2285B3"),
        ARC_OFF="#252D32", ARC_OFF_HI="#333D43", ARC=("#DDF8FF", "#FFFFFF", "#FFFFFF", "#FFE1F4"),
        ARC_GLOW="#8FE8FF", ARC_GLOW_I=1.1,
        CAP="#101418", CAP_TOP="#2E383E", CAP_RING="#D5F4FB", CAP_RING_HI="#FFFFFF", NEEDLE="#FFFFFF",
        TRACK="#2A3338", HANDLE="#FFFFFF", HANDLE_HI="#FFFFFF",
        PAD_BODY="#15191D", PAD_LINE="#FFFFFF", PAD_LINE_TINT=0.5, PAD_HALO_TINT=1.0, PAD_FACE_TINT=0.2,
        PAD_SHEEN_TINT=0.45,
        SCROLL="#3A464C", SCROLL_HI="#6B7E86",
    ),
}

# ── shared plumbing ──────────────────────────────────────────────────────────

_FX = re.compile(r'^_\w*(Bevel|Pattern|Gradient|Rim|Shadow\d|Glow|Screws|InnerFrame|OuterMarks|OuterRing\d|'
                 r'FaceShape|ScaleMark|Edge)\w*Enabled$')


def tron_common(family):
    stem = FAMILY[family][2]
    p = props(stem)
    d = {k: 0 for k in p if _FX.match(k) and "Global" not in k}
    d["_LightingUnlit"] = 1
    d["_LightingAmbient"] = 1.0
    if "_ReceiveSceneShadows" in p:
        d["_ReceiveSceneShadows"] = 0
    return d


def _stops(stops):
    s = [stops] if isinstance(stops, str) else list(stops)
    if len(s) == 1:
        s = s * 2
    return s


def gcol(layer, stops):
    """Just the colour stops of a gradient — what a state delta changes."""
    s = _stops(stops)
    padded = s + [s[-1]] * (4 - len(s))
    d = {f"{layer}GradientColor{c}": padded[i] for i, c in enumerate("ABCD")}
    d[f"{layer}GradientColorUsed"] = len(s)
    return d


def grad(layer, stops, direction=(1.0, 0.0)):
    """A linear gradient normalised so the widget's own 0-1 UV square spans exactly stop A..last.

    LinearGradient is dot(uv, normalize(dir)) * scale + offset, so the scale and offset come from
    the four UV corners projected onto the direction."""
    dx, dy = direction
    ln = (dx * dx + dy * dy) ** 0.5
    nx, ny = dx / ln, dy / ln
    corners = (0.0, nx, ny, nx + ny)
    lo, hi = min(corners), max(corners)
    scale = 1.0 / (hi - lo)
    d = {f"{layer}GradientEnabled": 1, f"{layer}GradientType": 0,
         f"{layer}GradientDirection": (dx, dy, 0, 0), f"{layer}GradientScale": scale,
         f"{layer}GradientOffset": -lo * scale, f"{layer}GradientSpeed": 0.0}
    d.update(gcol(layer, stops))
    return d


def rgbf(hexcol):
    s = hexcol.lstrip("#")
    return [int(s[j:j + 2], 16) / 255 for j in (0, 2, 4)]


def _emit(name, family, base, states, bounds, extra=None, write=True):
    doc, problems = skin(name, family, base, states, bounds=bounds, flat_shader=True,
                         extra=extra, write=write, quiet=True)
    doc["author"] = "DrumSumDrum"
    return name, doc, problems


TUBE_DIR = (1.0, 0.35)      # left→right with a slight rise: pink lands top-right, like a sign lit from one end

# ── keys (UI/SDFButton) ──────────────────────────────────────────────────────


def tube(P, layer_border="_Border", stops=None, width=0.09, halo_w=0.16, halo=None, halo_stops=None):
    """CORE (border band, emissive) + BLOOM (edge ring, additive). Widths in button units (short side 2)."""
    return {
        "_BorderEnabled": 1, "_BorderColor": _stops(stops or P["TUBE_REST"])[0],
        "_BorderWidth": width * P["LINE"], "_BorderSoftness": 0.0, "_BorderInset": 0.0, "_BorderFalloff": 0.0,
        "_BorderIntensity": 1.0, "_BorderRenderAlpha": 1.0, "_BorderRenderEmissive": 1.0,
        **grad(layer_border, stops or P["TUBE_REST"], TUBE_DIR),
        "_EdgeEnabled": 1, "_EdgeColor": _stops(halo_stops or P["HALO"])[0],
        "_EdgeWidth": halo_w * P["BLOOM"], "_EdgeSoftness": 0.5, "_EdgeFalloff": 1.0, "_EdgeInset": 0.0,
        "_EdgeIntensity": P["HALO_REST"] if halo is None else halo,
        "_EdgeRenderAlpha": 0.0, "_EdgeRenderEmissive": 1.0,
        **grad("_Edge", halo_stops or P["HALO"], TUBE_DIR),
    }


def key(P, *, body=None, mark=None, icon=None, icon_size=0.42, pad=0.252, cut=0.55, shape=4, round_=0.0,
        line=0.09, halo_w=0.16, sheen=0.14, sheen_col=None, states=None, bounds="button", alpha=1.0, extra=None, tube_stops=None):
    base = tron_common("Button")
    b = body or (P["BODY"], P["BODY_TOP"])
    base.update({
        "_ButtonEnabled": 1, "_ButtonColor": _stops(b)[0], "_ButtonRenderAlpha": alpha, "_ButtonRenderEmissive": 0.0,
        "_ButtonShapeType": shape, "_ButtonShapeParam1": cut, "_ButtonPadding": pad, "_ButtonRoundness": round_,
        **grad("_Button", b, (0.0, 1.0)),
        # SHEEN: the tube's light caught on the glass, fading in from the outline
        "_ButtonBevelEnabled": 1 if sheen else 0, "_ButtonBevelDepth": 0.0,
        "_ButtonBevelDistance": sheen or 0.3, "_ButtonBevelSmoothness": sheen or 0.3,
        **grad("_ButtonBevel", (sheen_col or P["SHEEN"],) * 2, (0.0, 1.0)),
        **tube(P, stops=tube_stops, width=line, halo_w=min(halo_w, pad * 0.9)),
        "_IconEnabled": 1 if icon is not None else 0,
    })
    if icon is not None:
        base.update({"_IconShapeType": icon, "_IconColor": mark or P["MARK"], "_IconWidth": icon_size,
                     "_IconHeight": icon_size, "_IconRenderAlpha": 1.0, "_IconRenderEmissive": 0.35})
    return base, states or {}, BOUNDS[bounds], extra


def lit(P, fill, *, mark=None, halo=None, sheen=None, tube_stops=None):
    """A key lit from inside: body fills with the colour, mark goes dark, bloom opens right up."""
    d = {**gcol("_Button", fill), "_EdgeIntensity": P["HALO_ON"] if halo is None else halo,
         **gcol("_ButtonBevel", (sheen or P["SHEEN_ON"],) * 2),
         **gcol("_Border", tube_stops or P["TUBE"])}
    if mark is not False:
        d["_IconColor"] = mark or P["ON_MARK"]
    return d


def key_parts(P, n):
    hover = {**gcol("_Border", P["TUBE"]), "_EdgeIntensity": P["HALO_HOVER"], "_IconColor": P["MARK"]}
    dis = {**gcol("_Button", (P["DIS_BODY"],) * 2), **gcol("_Border", P["TUBE_DIS"]), "_EdgeIntensity": 0.0,
           "_ButtonBevelEnabled": 0, "_IconColor": P["DIS_MARK"]}
    std = {"Hover": hover, "Pressed": lit(P, P.get("PRESS", P["ACCENT"])), "Disabled": dis}

    yield n("Button"), key(P, states=std)
    yield n("Accent"), key(P, body=P["ACCENT"], bounds="button_accent", cut=0.5, tube_stops=P["TUBE"],
                           sheen_col=P["ACCENT_HI"][0],
                           states={"Hover": {**gcol("_Button", P["ACCENT_HI"]), "_EdgeIntensity": P["HALO_ON"]},
                                   "Pressed": {**gcol("_Button", P["ACCENT"]), "_EdgeIntensity": P["HALO_ON"] * 1.3},
                                   "Disabled": {**gcol("_Button", P["ACCENT_DIS"]), **gcol("_Border", P["TUBE_DIS"]),
                                                "_EdgeIntensity": 0.0}})
    # Accent keys are LIT at rest, so their sheen is the lit sheen.
    latch = dict(std, Hover=dict(hover))
    yield n("ToggleBtn"), key(P, mark=P["MARK_DIM"], icon=17, icon_size=0.55, pad=0.116, cut=0.5, line=0.075,
                              halo_w=0.1, sheen=0.12, bounds="button_round",
                              states=dict(latch, Active=lit(P, P["HOT"])))
    yield n("Solo"), key(P, mark=P["MARK_DIM"], icon=16, icon_size=0.55, pad=0.116, cut=0.5, line=0.075,
                         halo_w=0.1, sheen=0.12, bounds="button_round",
                         states=dict(latch, Active=lit(P, P["SOLO"])))
    yield n("Lamp"), key(P, mark=P["MARK_DIM"], icon=29, icon_size=0.62, pad=0.34, cut=0.5, line=0.08,
                         halo_w=0.3, sheen=0.12, bounds="button_round",
                         states=dict(latch, Active=lit(P, P["LAMP"])))
    yield n("Close"), key(P, mark=P["MARK_DIM"], icon=19, icon_size=0.4, pad=0.116, alpha=0.0, sheen=0,
                          bounds="button_round",
                          states={"Hover": {"_ButtonRenderAlpha": 1.0, "_IconColor": P["HOT"][0],
                                            **gcol("_Border", P["TUBE"]), "_EdgeIntensity": P["HALO_HOVER"]},
                                  "Pressed": lit(P, P["HOT"]),
                                  "Disabled": {"_IconColor": P["DIS_MARK"]}})
    yield n("Chip"), key(P, pad=0.13, cut=0.45, line=0.08, halo_w=0.12, states=std)
    yield n("Dot"), key(P, body=(P["SCROLL"], P["SCROLL_HI"]), shape=1, cut=0.0, pad=0.1, line=0.06, halo_w=0.1,
                        sheen=0, states={"Hover": {"_EdgeIntensity": P["HALO_HOVER"]},
                                         "Pressed": lit(P, P["ACCENT"], mark=False)})
    yield n("ScrollHandle"), key(P, body=(P["SCROLL"], P["SCROLL_HI"]), shape=0, cut=0.5, pad=0.1, line=0.05,
                                 halo_w=0.1, sheen=0,
                                 states={"Hover": {**gcol("_Border", P["TUBE"]), "_EdgeIntensity": P["HALO_HOVER"]},
                                         "Pressed": lit(P, P["ACCENT"], mark=False),
                                         "Disabled": {"_ButtonRenderAlpha": 0.4, "_EdgeIntensity": 0.0}})

    # PADS wear their row. The row colour drives the tube CORE (mostly), the BLOOM (fully), a breath
    # of the glass and the sheen — so a pad is a neon outline in its row's colour, and a hit fills
    # its glass with that colour. Bound colours are live-driven, so feedback is FLOATS only.
    pad = key(P, body=(P["PAD_BODY"],), pad=0.12, cut=0.32, line=0.085, halo_w=0.11, sheen=0.2,
              states={"Hover": {"_EdgeIntensity": P["HALO_HOVER"], "_ButtonBevelDistance": 0.26},
                      "Pressed": {"_EdgeIntensity": P["HALO_ON"] * 1.2, "_ButtonBevelDistance": 1.4,
                                  "_ButtonBevelSmoothness": 1.4, "_BorderWidth": 0.12 * P["LINE"]},
                      "Disabled": {"_ButtonRenderAlpha": 0.45, "_EdgeIntensity": 0.0},
                      "Latched": {"_BorderWidth": 0.13 * P["LINE"], "_EdgeIntensity": P["HALO_ON"],
                                  "_ButtonBevelDistance": 0.26, "_ButtonBevelSmoothness": 0.26}},
              extra={"padColor": {"targets": [
                  {"param": "_BorderColor", "amount": P["PAD_LINE_TINT"]},
                  {"param": "_EdgeColor", "amount": P["PAD_HALO_TINT"]},
                  {"param": "_ButtonColor", "amount": P["PAD_FACE_TINT"]},
                  {"param": "_ButtonBevelGradientColorA", "amount": P["PAD_SHEEN_TINT"]},
                  {"param": "_ButtonBevelGradientColorB", "amount": P["PAD_SHEEN_TINT"]},
              ]}})
    base, states, bounds, extra = pad
    # a bound colour must not be overridden by a gradient on the same layer
    for layer in ("_Border", "_Edge", "_Button"):
        base[f"{layer}GradientEnabled"] = 0
    base["_BorderColor"] = P["PAD_LINE"]
    base["_EdgeColor"] = P["HALO"][0]
    yield n("Pad"), (base, states, bounds, extra)


PAD_TARGETS = ("_BorderColor", "_EdgeColor", "_ButtonColor", "_ButtonBevelGradientColorA", "_ButtonBevelGradientColorB")


# ── dials (UI/SDFKnob) ───────────────────────────────────────────────────────

def dial(P, px, arc_px, *, cap=0.58, ticks=0, glow_px=5.0, nub=0.08, ring_px=1.0, deco=False):
    """A HUD dial: glowing value arc (cyan at the start of its travel, pink at the end), a dim
    groove for the remainder, a black glass cap with a thin tube round it and a light-dot pointer."""
    half = px / 2.0
    u = 1.0 / half
    w = arc_px * u
    r = 0.86 - w
    base = tron_common("Knob")
    base.update({
        "_AngleStart": 315, "_AngleRange": 270, "_Value": 0.5,
        "_FillEnabled": 0, "_BorderEnabled": 0, "_NubEnabled": 0,
        "_LineEnabled": 1, "_LineRadius": r, "_LineWidth": w, "_LineRenderAlpha": 0.0, "_LineRenderEmissive": 0.0,
        "_LineRoundedEnabled": 0, "_LineSublineThickness": 1.0,
        "_LineSublineUnfilledEnabled": 1, "_LineSublineUnfilledColor": P["ARC_OFF"],
        "_LineSublineUnfilledRenderAlpha": 1.0, "_LineSublineUnfilledRenderEmissive": 0.0,
        "_LineSublineFilledEnabled": 1, "_LineSublineFilledColor": P["ARC"][0],
        "_LineSublineFilledRenderAlpha": 1.0, "_LineSublineFilledRenderEmissive": P["ARC_EMIT"],
        **grad("_LineSublineFilled", P["ARC"], (1.0, 0.0)),
        "_LineSublineGlowEnabled": 1, "_LineSublineGlowColor": P["ARC_GLOW"], "_LineSublineGlowWidth": 0.001,
        "_LineSublineGlowSoftness": glow_px * u, "_LineSublineGlowIntensity": P["ARC_GLOW_I"],
        "_LineSublineGlowRenderAlpha": 0.0, "_LineSublineGlowRenderEmissive": 1.0,
        "_KnobEnabled": 1, "_KnobColor": P["CAP"], "_KnobShapeType": 0, "_KnobSize": cap,
        "_KnobRenderAlpha": 1.0, "_KnobRenderEmissive": 0.0,
        **grad("_Knob", (P["CAP"], P["CAP_TOP"]), (0.0, 1.0)),
        "_KnobNubEnabled": 1, "_KnobNubShapeType": 0, "_KnobNubColor": P["NEEDLE"], "_KnobNubSize": nub,
        "_KnobNubDistance": 0.68, "_KnobNubRenderAlpha": 1.0,
        # the cap's tube
        "_OuterRing2Enabled": 1, "_OuterRing2Style": 0, "_OuterRing2Radius": cap + ring_px * u * 0.5 / r,
        "_OuterRing2Thickness": ring_px * u * P["LINE"] / r, "_OuterRing2Color": P["CAP_RING"],
        "_OuterRing2AngleStart": 0, "_OuterRing2AngleRange": 360,
        "_OuterRing2RenderAlpha": 1.0, "_OuterRing2RenderEmissive": 0.8,
    })
    if ticks:
        base.update({
            "_OuterMarksEnabled": 1, "_OuterMarksType": 0, "_OuterMarksCount": ticks,
            "_OuterMarksAngleStart": 315, "_OuterMarksAngleRange": 270, "_OuterMarksRadius": 0.8,
            "_OuterMarksLength": 0.05, "_OuterMarksThickness": 0.012,
            "_OuterMarksColorUnfilled": P["ARC_OFF_HI"], "_OuterMarksColorFilled": P["ARC"][1],
            "_OuterMarksMajorEnabled": 1, "_OuterMarksMajorInterval": 4,
            "_OuterMarksMajorLengthMultiplier": 1.8, "_OuterMarksMajorThicknessMultiplier": 1.2,
            "_OuterMarksMajorColorUnfilled": P["STRUCT_HI"], "_OuterMarksMajorColorFilled": P["NEEDLE"],
            "_OuterMarksRenderEmissive": 0.6,
        })
    if deco:
        # two short bracket arcs outside the value arc — the instrument-cluster read
        base.update({
            "_OuterRing1Enabled": 1, "_OuterRing1Style": 0, "_OuterRing1Radius": 1.07,
            "_OuterRing1Thickness": 0.012, "_OuterRing1Color": P["STRUCT_HI"],
            "_OuterRing1AngleStart": 20, "_OuterRing1AngleRange": 50,
            "_OuterRing1RenderAlpha": 1.0, "_OuterRing1RenderEmissive": 0.5,
            "_OuterRing3Enabled": 1, "_OuterRing3Style": 0, "_OuterRing3Radius": 1.07,
            "_OuterRing3Thickness": 0.012, "_OuterRing3Color": P["STRUCT_HI"],
            "_OuterRing3AngleStart": 110, "_OuterRing3AngleRange": 50,
            "_OuterRing3RenderAlpha": 1.0, "_OuterRing3RenderEmissive": 0.5,
        })
    states = {"Hover": {"_OuterRing2Color": P["CAP_RING_HI"], "_LineSublineGlowIntensity": P["ARC_GLOW_I"] * 1.5,
                        "_LineSublineUnfilledColor": P["ARC_OFF_HI"]},
              "Pressed": {"_LineSublineGlowIntensity": P["ARC_GLOW_I"] * 2.0, "_LineSublineFilledRenderEmissive": 1.0,
                          "_OuterRing2Color": P["CAP_RING_HI"]},
              "Disabled": {**gcol("_LineSublineFilled", (P["DIS_MARK"],) * 2), "_LineSublineGlowIntensity": 0.0,
                           "_LineSublineFilledRenderEmissive": 0.0, "_OuterRing2Color": P["TUBE_DIS"][0],
                           "_KnobNubColor": P["DIS_MARK"], "_LineSublineUnfilledColor": P["TUBE_DIS"][0]}}
    return base, states, BOUNDS["knob"], None


def knob_parts(P, n):
    yield n("Knob"), dial(P, 44, 2.5, glow_px=3.5, nub=0.09)
    yield n("KnobHero"), dial(P, 96, 3.5, glow_px=5.0, nub=0.06, ticks=25, deco=True, cap=0.55)
    yield n("KnobSmall"), dial(P, 36, 2.2, glow_px=3.5, nub=0.1, cap=0.56)


# ── faders (UI/SDFSlider) and the switch (UI/SDFTogglePill) ─────────────────

def fader(P, *, bg=True, bg_pad=0.13, track_w=0.16, handle_w=0.1, handle_h=0.85, fill=None, gutter=False):
    base = tron_common("Slider")
    base.update({
        "_Value": 0.5, "_TrackValueZeroPoint": 0.0,
        "_BgEnabled": 1 if bg else 0, "_BgColor": P["INSET"], "_BgShapeType": 0 if gutter else 4,
        "_BgShapeParam1": 1.0 if gutter else 0.5, "_BgPadding": bg_pad,
        **grad("_Bg", (P["INSET"], P["INSET_TOP"]), (0.0, 1.0)),
        "_BorderEnabled": 0 if gutter else 1, "_BorderColor": P["STRUCT"], "_BorderWidth": 0.05 * P["LINE"],
        "_BorderRenderAlpha": 1.0, "_BorderRenderEmissive": 0.6,
        "_TrackEnabled": 1, "_TrackColor": P["TRACK"], "_TrackWidth": track_w,
        "_TrackValueFilledEnabled": 1, "_TrackValueFilledColor": (fill or P["ARC"])[0],
        "_TrackValueFilledRenderEmissive": P["ARC_EMIT"],
        **grad("_TrackValueFilled", fill or P["ARC"], (1.0, 0.0)),
        "_TrackValueUnfilledEnabled": 0,
        "_HandleEnabled": 1, "_HandleColor": P["HANDLE"], "_HandleShapeType": 2, "_HandleShapeParam1": 0.2,
        "_HandleWidth": handle_w, "_HandleHeight": handle_h, "_HandlePadding": 0.5, "_HandleRenderEmissive": 0.5,
    })
    states = {"Hover": {"_HandleColor": P["HANDLE_HI"], "_BorderColor": P["STRUCT_HI"]},
              "Pressed": {"_HandleColor": P["HANDLE_HI"], "_TrackValueFilledRenderEmissive": 1.0,
                          "_BorderColor": P["STRUCT_HI"]},
              "Disabled": {"_HandleColor": P["DIS_MARK"], **gcol("_TrackValueFilled", (P["DIS_MARK"],) * 2),
                           "_TrackValueFilledRenderEmissive": 0.0, "_TrackColor": P["DIS_BODY"],
                           "_BorderColor": P["TUBE_DIS"][0]}}
    return base, states, BOUNDS["slider"], None


def switch(P):
    base = tron_common("Toggle")
    base.update({
        "_Value": 0.0, "_StateCount": 2,
        "_BgEnabled": 0, "_BgColor": P["INSET"], "_BgPadding": 0.12,
        "_TrackEnabled": 1, "_TrackColor": P["BODY"], "_TrackHeight": 0.85, "_TrackCornerRadius": 1.0,
        "_HandleEnabled": 1, "_HandleColor": P["ARC_OFF_HI"], "_HandlePadding": 0.3, "_HandleFlatten": 0.0,
        "_HandleFaceEnabled": 0, "_HandleRenderEmissive": 0.2,
        "_LedEnabled": 1, "_LedColor": P["LAMP"][0], "_LedIntensity": 0.0, "_LedSurfaceBlend": 1.0,
        "_BorderEnabled": 1, "_BorderColor": P["TUBE_REST"][1], "_BorderWidth": 0.06 * P["LINE"],
        "_BorderRenderAlpha": 1.0, "_BorderRenderEmissive": 1.0,
        "_EdgeEnabled": 0, "_EdgeColor": P["HALO"][0], "_EdgeWidth": 0.12 * P["BLOOM"], "_EdgeSoftness": 0.5,
        "_EdgeIntensity": P["HALO_REST"], "_EdgeRenderAlpha": 0.0, "_EdgeRenderEmissive": 1.0,
    })
    states = {"Hover": {"_BorderColor": P["TUBE"][1], "_EdgeIntensity": P["HALO_HOVER"]},
              "Disabled": {"_HandleColor": P["DIS_MARK"], "_LedSurfaceBlend": 0.0, "_BorderColor": P["TUBE_DIS"][0],
                           "_EdgeIntensity": 0.0}}
    return base, states, BOUNDS["pill"], None


def control_parts(P, n):
    yield n("Slider"), fader(P)
    yield n("Fader"), fader(P, bg_pad=0.02, track_w=0.4, handle_w=0.3, handle_h=0.9, gutter=True,
                            fill=(P["SCROLL_HI"], P["SCROLL_HI"]))
    yield n("Pill"), switch(P)


# ── plates (UI/SDFPanel) ────────────────────────────────────────────────────

def plate(P, fill, *, cut_px=8.0, pad_px=None, line_px=1.5, tube_stops=None, struct=None, halo=0.0, halo_px=6.0,
          sheen=0.0, sheen_col=None, grid=0.0, grid_px=300):
    """A plate is black glass: a vertical lift, then either a TUBE (device plates: gradient core plus an
    additive bloom spilling OUT into the gap, `_EdgeCutInside`) or a HAIRLINE (recesses). Every weight
    is pinned in canvas units — `_BorderWidthPx`, `_EdgeWidthPx`, and `_PanelCornerRadiusPx`, which
    pins the octagon CUT — so a 60-unit strip and an 850-unit rack wear the same tube."""
    lw = line_px
    hw = halo_px if halo else 0.0
    if pad_px is None:
        # the bloom ends exactly at the quad edge (graded to zero), so it never shows a cut
        pad_px = lw + hw + 0.5
    base = tron_common("Panel")
    base.update({
        "_PanelEnabled": 1, "_PanelColor": fill[0], "_PanelRenderAlpha": 1.0, "_PanelRenderEmissive": 0.0,
        "_PanelShapeType": 4, "_PanelShapeParam1": 0.06 if cut_px else 0.0, "_PanelPadding": 0.02,
        "_PanelPaddingPx": pad_px, "_PanelCornerRadiusPx": cut_px,
        **grad("_Panel", fill, (0.0, 1.0)),
        "_BorderEnabled": 1 if (tube_stops or struct) else 0,
        "_BorderColor": struct or _stops(tube_stops or P["TUBE_REST"])[0],
        "_BorderWidth": 0.012, "_BorderWidthPx": lw, "_BorderSoftness": 0.0,
        "_BorderRenderAlpha": 1.0, "_BorderRenderEmissive": 1.0 if tube_stops else 0.5,
        "_EdgeCutInside": 1,
    })
    if tube_stops:
        base.update(grad("_Border", tube_stops, TUBE_DIR))
    if halo:
        base.update({"_EdgeEnabled": 1, "_EdgeColor": P["HALO"][0], "_EdgeWidth": 0.03, "_EdgeWidthPx": hw,
                     "_EdgeSoftness": 0.5, "_EdgeIntensity": halo, "_EdgeInset": 0.0,
                     "_EdgeRenderAlpha": 0.0, "_EdgeRenderEmissive": 1.0, **grad("_Edge", P["HALO"], TUBE_DIR)})
    if sheen:
        base.update({"_PanelBevelEnabled": 1, "_PanelBevelDepth": 0.0, "_PanelBevelDistance": sheen,
                     "_PanelBevelSmoothness": sheen, **grad("_PanelBevel", (sheen_col or P["SHEEN"],) * 2, (0, 1))})
    if grid:
        base.update({"_PanelPatternEnabled": 1, "_PanelPatternType": 13, "_PanelPatternScale": round(grid_px / 40.0, 1),
                     "_PanelPatternPx": grid_px,   # pixel-locked: 40-unit cells at any panel size
                     "_PanelPatternIntensity": grid, "_PanelPatternParam1": 0.05, "_PanelPatternParam2": 0.35})
    return base, {}, BOUNDS["panel"], None


def plate_parts(P, n):
    dark = P["prefix"].endswith("Dark")
    yield n("Face"), plate(P, (P["FACE"], P["FACE_TOP"]), tube_stops=P["TUBE_REST"], line_px=P["FACE_LINE_PX"],
                          halo=P["HALO_REST"], halo_px=P["FACE_HALO_PX"], cut_px=12.0, grid=0.06 if dark else 0.0,
                          sheen=P["FACE_SHEEN"], sheen_col=P["PLATE_SHEEN"])
    yield n("Inset"), plate(P, (P["INSET"], P["INSET_TOP"]), struct=P["STRUCT"], line_px=1.0, cut_px=6.0, pad_px=2.0)
    yield n("Socket"), plate(P, (P["SOCKET"], P["SOCKET"]), struct=P["STRUCT"], line_px=1.0, cut_px=5.0, pad_px=2.0)
    yield n("Well"), plate(P, (P["WELL"], P["WELL_TOP"]), tube_stops=P["TUBE_REST"], line_px=1.2,
                          halo=P["HALO_REST"] * 0.6, halo_px=2.0, cut_px=5.0, sheen=0.1)
    yield n("Back"), plate(P, (P["BACK"], P["BACK_TOP"]), cut_px=0.0, pad_px=0.0)
    yield n("Bezel"), plate(P, (P["WELL"], P["WELL_TOP"]), struct=P["STRUCT_HI"], line_px=1.2, cut_px=5.0, pad_px=2.0)
    yield n("ScrollTrack"), plate(P, (P["INSET"], P["INSET"]), struct=P["STRUCT"], line_px=1.0, cut_px=3.0, pad_px=1.0)


# ── assembly ─────────────────────────────────────────────────────────────────

def all_parts(mode, write=False, overrides=None):
    P = dict(MODES[mode], **(overrides or {}))
    n = lambda part: P["prefix"] + part          # noqa: E731
    family = {"key": "Button", "knob": "Knob", "control": None, "plate": "Panel"}
    out, problems = {}, {}
    for kind, gen in (("key", key_parts), ("knob", knob_parts), ("control", control_parts), ("plate", plate_parts)):
        for name, (base, states, bounds, extra) in gen(P, n):
            fam = family[kind] or ("Toggle" if name.endswith("Pill") else "Slider")
            nm, doc, probs = _emit(name, fam, base, states, bounds, extra, write=write)
            out[nm] = doc
            if probs:
                problems[nm] = sorted(set(probs))
    return P, out, problems


def write(modes):
    for mode in modes:
        _, parts, problems = all_parts(mode, write=True)
        for name in parts:
            (ROOT / "Assets/Resources/MaterialStates" / f"{name}.states.json").write_text(
                json.dumps(parts[name], indent=4), encoding="utf-8")
        print(f"  {mode}: wrote {len(parts)} parts")
        for name, probs in problems.items():
            print("   !!", name, probs)


def check():
    for mode in MODES:
        _, parts, problems = all_parts(mode)
        print(f"{mode}: {len(parts)} parts, {len(problems)} with problems")
        for name, probs in problems.items():
            print("   !!", name, probs)


# ── device mock sheet ────────────────────────────────────────────────────────

UNLIT_RIG = {"light1": {"enabled": False}, "light2": {"enabled": False}, "light3": {"enabled": False}}


def _authored(doc, param):
    for prm in doc["states"][0]["parameters"]:
        if prm["name"] == param:
            return [float(v) for v in prm["value"].split(",")][:3]
    return [0.0, 0.0, 0.0]


def sheet(mode, tag, overrides=None):
    from skinsheet import render, OUT, _font
    from PIL import Image, ImageDraw

    SC.mkdir(parents=True, exist_ok=True)
    P, parts, problems = all_parts(mode, overrides=overrides)
    for name, probs in problems.items():
        print("   !!", name, probs)
    pre = P["prefix"]
    paths = {}
    for name, doc in parts.items():
        p = SC / f"{tag}-{name}.states.json"
        p.write_text(json.dumps(doc), encoding="utf-8")
        paths[name[len(pre):]] = p.as_posix()

    W, H = 940, 540
    cells, meta, texts = [], [], []
    plate_col = {"Face": ("FACE", "FACE_TOP"), "Inset": ("INSET", "INSET_TOP"), "Socket": ("SOCKET", "SOCKET"),
                 "Well": ("WELL", "WELL_TOP"), "Back": ("BACK", "BACK_TOP"), "ScrollTrack": ("INSET", "INSET"),
                 "Bezel": ("WELL", "WELL_TOP")}
    plates = []

    def under(x, y, w, h):
        cx, cy = x + w / 2, y + h / 2
        for px_, py_, pw, ph, bot, top in reversed(plates):
            if px_ <= cx < px_ + pw and py_ <= cy < py_ + ph:
                return mix(bot, top, 1.0 - (cy - py_) / ph)
        return P["GAP"]

    def add(cid, part, w, h, x, y, **kw):
        c = {"id": f"tr-{tag}-{cid}", "states": paths[part], "w": w, "h": h, "ss": 1, "bg": under(x, y, w, h)}
        c.update(kw)
        cells.append(c)
        meta.append((c["id"], x, y))
        if part in plate_col:
            plates.append((x, y, w, h, P[plate_col[part][0]], P[plate_col[part][1]]))

    def txt(x, y, s, col, size=11, bold=False):
        texts.append((x, y, s, col, size, bold))

    ink, dim = P["MARK"], P["MARK_DIM"]

    add("face1", "Face", 600, 330, 10, 10)
    txt(26, 22, "EQ EIGHT", ink, 12, True)
    add("lamp-on", "Lamp", 30, 30, 536, 16, state="Active")
    add("lamp-off", "Lamp", 30, 30, 502, 16)
    add("close", "Close", 36, 30, 566, 16, state="Normal,Hover")
    for i, v in enumerate((0.0, 0.35, 0.72, 1.0)):
        x = 26 + i * 70
        add(f"k{i}", "Knob", 44, 44, x, 56, set={"_Value": v})
        txt(x + 4, 102, ("GAIN", "FREQ", "Q", "MIX")[i], dim, 10)
        txt(x + 6, 116, ("-inf", "1.2k", "0.71", "100%")[i], ink, 10)
    add("kdis", "Knob", 44, 44, 306, 56, state="Disabled", set={"_Value": 0.5})
    txt(304, 102, "OFF", dim, 10)
    add("khov", "Knob", 44, 44, 376, 56, state="Normal,Hover", set={"_Value": 0.5})
    txt(374, 102, "HOVER", dim, 10)
    for i, v in enumerate((0.2, 0.55, 0.9)):
        add(f"ks{i}", "KnobSmall", 36, 36, 446 + i * 52, 60, set={"_Value": v})
    add("well", "Well", 150, 32, 26, 142)
    txt(36, 148, "120.00", ink, 16, True)
    txt(108, 152, "BPM", dim, 10)
    add("sl", "Slider", 180, 30, 190, 143, set={"_Value": 0.62})
    add("sl-dis", "Slider", 120, 28, 380, 144, state="Disabled", set={"_Value": 0.3})
    add("pill0", "Pill", 46, 24, 512, 146, set={"_Value": 0.0})
    add("pill1", "Pill", 46, 24, 562, 146, set={"_Value": 1.0})

    row_y = 196
    for i, (part, st, lab) in enumerate([("Button", "Normal", "KEY"), ("Button", "Normal,Hover", "HOV"),
                                         ("Button", "Normal,Hover,Pressed", "PRS"), ("Button", "Disabled", "DIS"),
                                         ("ToggleBtn", "Normal", "M"), ("ToggleBtn", "Active", "M ON"),
                                         ("Solo", "Normal", "S"), ("Solo", "Active", "S ON"),
                                         ("Chip", "Normal", "LEARN")]):
        w, h = (28, 24) if part in ("ToggleBtn", "Solo") else (48, 26)
        x = 26 + i * 62
        add(f"b{i}", part, w, h, x, row_y, state=st)
        txt(x, row_y + 30, lab, dim, 9)
    add("acc", "Accent", 100, 34, 26, 250)
    txt(54, 259, "PLAY", P["ON_MARK"], 12, True)
    add("hero", "Button", 140, 38, 138, 248)
    txt(174, 259, "Sign out", ink, 12)
    add("wide", "Button", 100, 34, 290, 250, state="Normal,Hover")
    txt(312, 259, "Export", ink, 12)

    add("inset", "Inset", 300, 150, 630, 10)
    add("kh", "KnobHero", 96, 96, 650, 24, set={"_Value": 0.66})
    txt(752, 40, "MASTER", dim, 11, True)
    txt(752, 58, "-3.2 dB", ink, 18, True)
    add("kh2", "KnobHero", 96, 96, 826, 24, state="Normal,Hover,Pressed", set={"_Value": 0.25})

    add("socket", "Socket", 300, 170, 630, 170)
    rows = json.loads((ROOT / "Assets/Resources/TrackThemes/Grid.track.json").read_text(encoding="utf-8")
                      .split('"props"')[0].rstrip().rstrip(",") + "}")["palette"]
    pad_doc = parts[pre + "Pad"]
    authored = {t: _authored(pad_doc, t) for t in PAD_TARGETS}
    amount = {t["param"]: t["amount"] for t in pad_doc["padColor"]["targets"]}
    for r in range(3):
        rgb = rgbf(rows[f"row{r + 1}"])
        bind = {}
        for t in PAD_TARGETS:
            a = authored[t]
            bind[t] = ",".join(f"{a[j] + (rgb[j] - a[j]) * amount[t]:.5f}" for j in range(3)) + ",1"
        for c in range(5):
            st = "Normal"
            if (r, c) == (0, 1):
                st = "Normal,Latched"
            elif (r, c) == (1, 3):
                st = "Normal,Hover,Pressed"
            add(f"p{r}{c}", "Pad", 52, 48, 642 + c * 56, 182 + r * 52, state=st, set=dict(bind))

    add("back", "Back", 920, 60, 10, 352)
    add("strack", "ScrollTrack", 420, 12, 24, 372)
    add("shandle", "ScrollHandle", 110, 12, 90, 372)
    add("dot", "Dot", 16, 16, 460, 370)
    add("fader", "Fader", 120, 12, 490, 372, set={"_Value": 0.4})
    txt(630, 368, "A01  KICK", ink, 12, True)

    add("face2", "Face", 920, 110, 10, 420)
    txt(26, 432, f"TRON {mode.upper()} — {tag}  (unlit, non-RM, ss=1)", ink, 13, True)
    txt(26, 454, "core = border band · bloom = additive edge ring · sheen = unlit bevel band", dim, 11)

    render(cells, rig=UNLIT_RIG, timeout=480)

    img = Image.new("RGBA", (W, H), P["GAP"])
    for cid, x, y in meta:
        p = OUT / f"{cid}.png"
        if not p.exists():
            print("missing", cid)
            continue
        img.alpha_composite(Image.open(p).convert("RGBA"), (x, y))
    d = ImageDraw.Draw(img)
    for x, y, s, col, size, bold in texts:
        d.text((x, y), s, font=_font(size, bold), fill=col)
    out = SC / f"sheet-{mode}-{tag}.png"
    img.convert("RGB").save(out)
    img.resize((W * 2, H * 2), Image.NEAREST).convert("RGB").save(SC / f"sheet-{mode}-{tag}@2x.png")
    print(out)
    return out


# ── the recipe (Resources/UiStyles/Tron.style.json) ──────────────────────────
#
# Generated from the same tables as the parts. The ROSTER (roles, families, by-name swaps, screen
# finishes) is Flat's — one list of what a non-RM look must cover, kept in design_flat.py.

from design_flat import FAMILY_PART, ROLE_PART, SWAP_PART, AUTHORED_FINISHES  # noqa: E402


def display_map(mode):
    m = {k: f"tron.{mode}" for k in AUTHORED_FINISHES}
    m["led.matrix.green"] = m["led.matrix.amber"] = f"tron.{mode}.meter"
    m["waveform"] = f"tron.{mode}.waveform"
    return m


APP = {
    "dark": dict(
        trackTheme="Grid",
        blurb="The grid at night. Neon tubes on black glass - blue, with pink at the tip.",
        chrome=dict(headerBg="#01050B", headerBorder="#2067B0", tabFillBottom="#02070E", tabFillTop="#02070E",
                    tabFillActiveBottom="#061426", tabFillActiveTop="#0A1D33", label="#5E93AE",
                    labelActive="#D8F7FF", icon="#5E93AE", iconActive="#2BE4FF", gear="#5E93AECC",
                    meatballIdle="#5E93AE", meatballLit="#FF4FD8"),
        palettes={
            "ui": dict(text="#D8F7FF", textDim="#5E93AE", textFaint="#2E5468", accent="#2BE4FF",
                       warn="#FFC93E", danger="#FF3F8F", ok="#3DFFB0"),
            "surface": dict(card="#020810F5", cardEdge="#2067B0", divider="#0A2233", scrim="#000307C8",
                            backdrop="#000205", gap="#000205"),
            "ink": dict(faceplate="#D8F7FF", faceplateDim="#5E93AE", inset="#D8F7FF", insetDim="#5E93AE",
                        backplane="#D8F7FF", backplaneDim="#5E93AE", socket="#D8F7FF", socketDim="#5E93AE",
                        reviewBar="#D8F7FF", reviewBarDim="#5E93AE"),
            "display": dict(text="#7FF0FF", textDim="#2E7A94", textAlt="#FF7AD9", warn="#FF3F8F"),
            "key": dict(label="#D8F7FF", faceOff="#02070E", edgeOff="#1597B8", markOff="#4B86A6",
                        bankFaceOff="#02070E", bankEdgeOff="#0C3448",
                        glyphOff="#4B86A6", muteOn="#01060C", soloOn="#01060C", velOff="#4B86A6", velOn="#2BE4FF"),
            "pad": dict(empty="#02060C80"),
            "review": dict(bar="#01050BF0", barRule="#2BE4FF22"),
            "tracks": dict(backdrop="#000307", strip="#01050B", rowWithSample="#051226", rowEmpty="#020810",
                           rowNotesNoSample="#1C0A22", text="#9FDFF2", ruler="#2BE4FFB0", playhead="#FF4FD8E6",
                           recMarker="#FF3F8FDC", scrollbar="#2BE4FF26"),
        },
    ),
    "light": dict(
        trackTheme="Grid",
        blurb="The Legacy cockpit: the black room, tubes blown white-hot.",
        chrome=dict(headerBg="#07090B", headerBorder="#E6F4F8", tabFillBottom="#0A0C0F", tabFillTop="#0A0C0F",
                    tabFillActiveBottom="#161B1F", tabFillActiveTop="#232A30", label="#A7BAC2",
                    labelActive="#FFFFFF", icon="#A7BAC2", iconActive="#FFFFFF", gear="#A7BAC2CC",
                    meatballIdle="#A7BAC2", meatballLit="#FFFFFF"),
        palettes={
            "ui": dict(text="#FFFFFF", textDim="#A7BAC2", textFaint="#5B6A71", accent="#DDF7FF",
                       warn="#FFE08A", danger="#FF9BC8", ok="#B8FFE0"),
            "surface": dict(card="#0A0D10F5", cardEdge="#E6F4F8", divider="#1C2226", scrim="#000000C0",
                            backdrop="#030405", gap="#030405"),
            "ink": dict(faceplate="#FFFFFF", faceplateDim="#A7BAC2", inset="#FFFFFF", insetDim="#A7BAC2",
                        backplane="#FFFFFF", backplaneDim="#A7BAC2", socket="#FFFFFF", socketDim="#A7BAC2",
                        reviewBar="#FFFFFF", reviewBarDim="#A7BAC2"),
            "display": dict(text="#F4FEFF", textDim="#7FA3AE", textAlt="#FFD6EE", warn="#FF9BC8"),
            "key": dict(label="#FFFFFF", faceOff="#0C0F12", edgeOff="#CDEFF7", markOff="#A7BAC2",
                        bankFaceOff="#0C0F12", bankEdgeOff="#3B4A52",
                        glyphOff="#A7BAC2", muteOn="#06080A", soloOn="#06080A", velOff="#A7BAC2", velOn="#FFFFFF"),
            "pad": dict(empty="#0A0C0F80"),
            "review": dict(bar="#07090BF0", barRule="#FFFFFF22"),
            "tracks": dict(backdrop="#050607", strip="#0A0C0F", rowWithSample="#161B1F", rowEmpty="#0E1114",
                           rowNotesNoSample="#2A1A24", text="#E6F4F8", ruler="#FFFFFFB0", playhead="#FFFFFFE6",
                           recMarker="#FF9BC8DC", scrollbar="#FFFFFF26"),
        },
    ),
}

RECIPE_HEADER = """// ═══════════════════════════════════════════════════════════════════════════
// TRON — unlit, non-raymarched neon tubes on black glass.
//
// GENERATED by `python Tools/design_tron.py recipe` from the same tables as the TronDark*/TronLight*
// parts — edit design_tron.py, not this file. Every role, family and by-name skin rosters an authored
// file (UI/SDFKnob, UI/SDFButton, ... with _LightingUnlit 1), so nothing is baked and nothing can
// inherit an RM shader or a lit parameter. The rig (Themes/Tron.theme) has every lamp off: all the
// light on screen is emissive — border cores, additive edge blooms, arc glows.
// ═══════════════════════════════════════════════════════════════════════════
"""


def recipe():
    def roster(pre):
        return ({f: {"$base": pre + p} for f, p in FAMILY_PART.items()},
                {r: {"$base": pre + p} for r, p in ROLE_PART.items()})

    fam, roles = roster(MODES["dark"]["prefix"])
    doc = {
        "styleName": "Tron", "title": "Tron", "order": 3, "author": "DrumSumDrum",
        "blurb": "Unlit neon. Every edge is a light tube: a gradient core, an additive bloom, sheen on black glass.",
        "stateShifts": {"Hover": 0.08, "Pressed": -0.1, "Active": 0.16, "Disabled": -0.22},
        "families": fam, "roles": roles, "modes": {},
    }
    for mode in ("dark", "light"):
        P, A = MODES[mode], APP[mode]
        fam, roles = roster(P["prefix"])
        doc["modes"][mode] = {
            "trackTheme": A["trackTheme"], "blurb": A["blurb"], "lights": "Themes/Tron.theme",
            "colors": {"face": P["FACE"], "inset": P["INSET"], "backplane": P["BACK"], "well": P["WELL"],
                       "body": P["BODY"], "bodyAlt": P["BODY_TOP"], "accent": P["TUBE"][0], "line": P["TUBE_REST"][1],
                       "hot": P["HOT"][0], "lamp": P["LAMP"][0], "mark": P["MARK"]},
            "chrome": A["chrome"], "palettes": A["palettes"],
            "displays": display_map(mode),
            "families": fam, "roles": roles,
            "swaps": {k: P["prefix"] + v for k, v in SWAP_PART.items()},
        }
    out = ROOT / "Assets/Resources/UiStyles/Tron.style.json"
    out.write_text(RECIPE_HEADER + json.dumps(doc, indent=2) + "\n", encoding="utf-8")
    print("  wrote", out)


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "check"
    if cmd == "write":
        which = sys.argv[2] if len(sys.argv) > 2 else "both"
        write(["dark", "light"] if which == "both" else [which])
    elif cmd == "check":
        check()
    elif cmd == "recipe":
        recipe()
    else:
        sheet(sys.argv[2], sys.argv[3])
