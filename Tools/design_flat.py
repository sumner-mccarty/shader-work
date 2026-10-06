"""Flat Dark + Flat Light — unlit, non-RM, Ableton-style. One generator, one table per mode.

    python Tools/design_flat.py write [dark|light|both]   # Assets/Resources/MaterialStates/FlatDark*/FlatLight*
    python Tools/design_flat.py check                      # validate every part, write nothing
    python Tools/design_flat.py sheet <dark|light> <tag>   # render a device mock at app sizes (no Assets write)

THE PREMISE (2026-09-13). Flat is the look a phone can afford. Every part names the NON-raymarched
shader (UI/SDFKnob, not UI/SDFKnobRM) and sets _LightingUnlit, so the rig, bevel normals and the
shadow capture pass cost nothing, and the authored hex is exactly what lands on screen under ANY rig
(Skin Studio previews included). Form comes only from value steps between neutral greys, one warm
accent for ON, and thin crisp strokes — the Ableton Live idiom: capless dials drawn as an arc plus a
needle, square keys with a small corner, device panels as flat blocks separated by darker gaps.

EVERY EFFECT GUARD IS SET. A skin that leaves a guard unset inherits the source MATERIAL's value,
not the shader default — so "no bevel / no pattern / no shadow" has to be said, not assumed.

FOOTPRINTS COME FROM THE APP'S AUTHORED SKINS (GreyButtonRM padding 0.252, MuteToggleRM 0.116,
EnableLampRM 0.34, RackSlider bg padding 0.13, ...) so a swap changes the finish, never the layout
or the hitbox.
"""
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from skinlib import skin, props, BOUNDS, FAMILY  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
SC = ROOT / ".skinsheet" / "flat"

MODES = {
    "dark": dict(
        prefix="FlatDark",
        # plates, darkest to lightest: the gaps between docked panels are the darkest thing on screen
        GAP="#141414", BACK="#1B1B1B", WELL="#171717", INSET="#222222", SOCKET="#202020", FACE="#2A2A2A",
        # keys
        BODY="#3E3E3E", BODY_HI="#494949", PRESS="#2E2E2E", BORDER=None,
        MARK="#D6D6D6", MARK_DIM="#9A9A9A", DIS_BODY="#343434", DIS_MARK="#5A5A5A",
        ACCENT="#FF9F1C", ACCENT_HI="#FFB24D", ACCENT_LO="#E88B0B", ACCENT_DIS="#5C4122", ON_MARK="#161616",
        SOLO="#45ADF5", LAMP="#F5C431",
        # dials / faders: grey track, light value, light needle
        ARC_OFF="#4D4D4D", ARC_OFF_HI="#5C5C5C", VALUE="#D9D9D9", VALUE_HI="#FFFFFF", DIS_ARC="#383838",
        TRACK="#474747", HANDLE="#D9D9D9", HANDLE_HI="#FFFFFF",
        PAD_BODY="#3A3A3A", PAD_TINT=0.8, PAD_LATCH="#FFFFFF",
        SCROLL="#4A4A4A", SCROLL_HI="#5A5A5A",
    ),
    "light": dict(
        prefix="FlatLight",
        GAP="#A8A8A8", BACK="#B9B9B9", WELL="#E9E9E9", INSET="#C4C4C4", SOCKET="#C8C8C8", FACE="#D0D0D0",
        # a pale key DARKENS under the pointer; disabled sinks toward the plate instead
        BODY="#BDBDBD", BODY_HI="#B2B2B2", PRESS="#A9A9A9", BORDER=None,
        MARK="#1C1C1C", MARK_DIM="#555555", DIS_BODY="#C9C9C9", DIS_MARK="#A5A5A5",
        ACCENT="#F28C00", ACCENT_HI="#FF9E1F", ACCENT_LO="#D67B00", ACCENT_DIS="#E2C9A6", ON_MARK="#141414",
        SOLO="#2A93E6", LAMP="#F2B800",
        ARC_OFF="#A6A6A6", ARC_OFF_HI="#959595", VALUE="#262626", VALUE_HI="#000000", DIS_ARC="#BBBBBB",
        TRACK="#A6A6A6", HANDLE="#262626", HANDLE_HI="#000000",
        PAD_BODY="#C2C2C2", PAD_TINT=0.75, PAD_LATCH="#1C1C1C",
        SCROLL="#A0A0A0", SCROLL_HI="#8C8C8C",
    ),
}

# ── shared plumbing ──────────────────────────────────────────────────────────

# Every guard for a surface EFFECT. Structural guards (_IconEnabled, _FillEnabled, _TrackEnabled, ...)
# are set per part instead, on or off, because each part means something different by them.
_FX = re.compile(r'^_\w*(Bevel|Pattern|Gradient|Rim|Shadow\d|Glow|Screws|InnerFrame|OuterMarks|OuterRing\d|'
                 r'FaceShape|ScaleMark|Edge)\w*Enabled$')


def flat_common(family):
    stem = FAMILY[family][2]
    p = props(stem)
    d = {k: 0 for k in p if _FX.match(k) and "Global" not in k}
    d["_LightingUnlit"] = 1
    d["_LightingAmbient"] = 1.0
    if "_ReceiveSceneShadows" in p:
        d["_ReceiveSceneShadows"] = 0
    return d


def _emit(name, family, base, states, bounds, extra=None, write=True):
    doc, problems = skin(name, family, base, states, bounds=bounds, flat_shader=True,
                         extra=extra, write=write, quiet=True)
    doc["author"] = "DrumSumDrum"
    return name, doc, problems


# ── keys (UI/SDFButton) ──────────────────────────────────────────────────────

def key(P, name, *, fill, mark=None, icon=None, icon_size=0.42, pad=0.252, corner=0.78, round_=0.0,
        states=None, bounds="button", alpha=1.0, extra=None):
    base = flat_common("Button")
    base.update({
        "_ButtonEnabled": 1, "_ButtonColor": fill, "_ButtonRenderAlpha": alpha, "_ButtonRenderEmissive": 0.0,
        "_ButtonShapeType": 0, "_ButtonShapeParam1": corner, "_ButtonPadding": pad, "_ButtonRoundness": round_,
        "_BorderEnabled": 1 if P["BORDER"] else 0, "_BorderColor": P["BORDER"] or fill,
        "_BorderWidth": 0.05, "_BorderSoftness": 0.0,
        "_IconEnabled": 1 if icon is not None else 0,
    })
    if icon is not None:
        base.update({"_IconShapeType": icon, "_IconColor": mark or P["MARK"], "_IconWidth": icon_size,
                     "_IconHeight": icon_size, "_IconRenderAlpha": 1.0, "_IconRenderEmissive": 0.0})
    return base, states or {}, BOUNDS[bounds], extra


def key_parts(P, n):
    # Held = lit in the accent, the way a momentary key in Live lights while you hold it. A merely
    # darker key vanished into the plate on dark and read as disabled on light.
    std = {"Hover": {"_ButtonColor": P["BODY_HI"]},
           "Pressed": {"_ButtonColor": P["ACCENT"], "_IconColor": P["ON_MARK"]},
           "Disabled": {"_ButtonColor": P["DIS_BODY"], "_IconColor": P["DIS_MARK"]}}

    yield n("Button"), key(P, n("Button"), fill=P["BODY"], states=std)
    yield n("Accent"), key(P, n("Accent"), fill=P["ACCENT"], bounds="button_accent", corner=0.744,
                           states={"Hover": {"_ButtonColor": P["ACCENT_HI"]},
                                   "Pressed": {"_ButtonColor": P["ACCENT_LO"]},
                                   "Disabled": {"_ButtonColor": P["ACCENT_DIS"]}})
    # Latches: OFF is a grey key with a dim mark; ON fills with the colour of what it means and the
    # mark goes dark on it. Colour AND contrast change, so it reads without relying on hue alone.
    latch = dict(std, Hover={"_ButtonColor": P["BODY_HI"], "_IconColor": P["MARK"]})
    # Marks at 0.55, not the RM keys' 0.42: a speaker/eye glyph at 0.42 on a 24px key is a smudge.
    yield n("ToggleBtn"), key(P, n("ToggleBtn"), fill=P["BODY"], mark=P["MARK_DIM"], icon=17, icon_size=0.55,
                              pad=0.116, bounds="button_round",
                              states=dict(latch, Active={"_ButtonColor": P["ACCENT"], "_IconColor": P["ON_MARK"]}))
    yield n("Solo"), key(P, n("Solo"), fill=P["BODY"], mark=P["MARK_DIM"], icon=16, icon_size=0.55, pad=0.116,
                         bounds="button_round",
                         states=dict(latch, Active={"_ButtonColor": P["SOLO"], "_IconColor": P["ON_MARK"]}))
    # The device activator: Ableton's yellow square when ON.
    yield n("Lamp"), key(P, n("Lamp"), fill=P["BODY"], mark=P["MARK_DIM"], icon=29, icon_size=0.62, pad=0.34,
                         corner=0.8, bounds="button_round",
                         states=dict(latch, Active={"_ButtonColor": P["LAMP"], "_IconColor": P["ON_MARK"]}))
    # A close X is just a mark until you point at it.
    yield n("Close"), key(P, n("Close"), fill=P["BODY_HI"], mark=P["MARK_DIM"], icon=19, icon_size=0.4,
                          pad=0.116, bounds="button_round", alpha=0.0,
                          states={"Hover": {"_ButtonRenderAlpha": 1.0, "_IconColor": P["MARK"]},
                                  "Pressed": {"_ButtonColor": P["PRESS"]},
                                  "Disabled": {"_IconColor": P["DIS_MARK"]}})
    yield n("Chip"), key(P, n("Chip"), fill=P["BODY"], pad=0.13, corner=0.7, states=std)
    yield n("Dot"), key(P, n("Dot"), fill=P["SCROLL"], corner=0.02, round_=0.9,
                        states={"Hover": {"_ButtonColor": P["SCROLL_HI"]},
                                "Pressed": {"_ButtonColor": P["MARK_DIM"]}})
    yield n("ScrollHandle"), key(P, n("ScrollHandle"), fill=P["SCROLL"], pad=0.1, corner=0.5,
                                 states={"Hover": {"_ButtonColor": P["SCROLL_HI"]},
                                         "Pressed": {"_ButtonColor": P["MARK_DIM"]},
                                         "Disabled": {"_ButtonRenderAlpha": 0.4}})
    # Pads wear their row's colour (padColor tints _ButtonColor), flat, like a clip slot.
    yield n("Pad"), key(P, n("Pad"), fill=P["PAD_BODY"], pad=0.12, corner=0.86,
                        states={"Hover": {"_ButtonRenderEmissive": 0.08},
                                "Pressed": {"_ButtonRenderEmissive": 0.22},
                                "Disabled": {"_ButtonRenderAlpha": 0.45},
                                "Latched": {"_BorderEnabled": 1, "_BorderColor": P["PAD_LATCH"],
                                            "_BorderWidth": 0.05, "_ButtonRenderEmissive": 0.1}},
                        extra={"padColor": {"targets": [{"param": "_ButtonColor", "amount": P["PAD_TINT"]}]}})


# ── dials (UI/SDFKnob) ───────────────────────────────────────────────────────

def dial(P, px, stroke_px, needle_px):
    """A capless dial: 270-degree arc (grey remainder, light value) + a needle from the centre.

    Widths are in widget units where the half-extent is 1.0, so they are derived from the part's
    real pixel size — which is why the three knob roles are separate files."""
    half = px / 2.0
    w = stroke_px / half
    r = 0.92 - w                              # arc outer edge sits at 0.92
    base = flat_common("Knob")
    base.update({
        "_AngleStart": 315, "_AngleRange": 270, "_Value": 0.5,
        "_FillEnabled": 0, "_KnobEnabled": 0, "_KnobNubEnabled": 0, "_BorderEnabled": 0,
        "_LineEnabled": 1, "_LineRadius": r, "_LineWidth": w, "_LineRenderAlpha": 0.0, "_LineRenderEmissive": 0.0,
        "_LineRoundedEnabled": 0, "_LineSublineThickness": 1.0,
        "_LineSublineUnfilledEnabled": 1, "_LineSublineUnfilledColor": P["ARC_OFF"],
        "_LineSublineUnfilledRenderAlpha": 1.0, "_LineSublineUnfilledRenderEmissive": 0.0,
        "_LineSublineFilledEnabled": 1, "_LineSublineFilledColor": P["VALUE"],
        "_LineSublineFilledRenderAlpha": 1.0, "_LineSublineFilledRenderEmissive": 0.0,
        "_NubEnabled": 1, "_NubShapeType": 1, "_NubColor": P["VALUE"], "_NubRenderAlpha": 1.0,
        "_NubRenderEmissive": 0.0, "_NubRotation": 0.0, "_NubShapeRotation": 0.0,
        # getNubSDF(Rectangle) takes FULL sizes, oriented so width runs along the radius. The arc
        # band is r … r+w, so a needle that JOINS it (2026-09-18: it used to stop at 0.94r, a
        # visible gap short of the arc) runs from the centre right through the band to its outer
        # edge (0.92) — the value hand-tuned in the Designer, now owned here.
        "_NubDistance": (r + w) * 0.5, "_NubSizeWidth": r + w, "_NubSizeHeight": needle_px / half,
    })
    states = {"Hover": {"_LineSublineUnfilledColor": P["ARC_OFF_HI"]},
              "Pressed": {"_LineSublineFilledColor": P["VALUE_HI"], "_NubColor": P["VALUE_HI"]},
              "Disabled": {"_LineSublineFilledColor": P["DIS_MARK"], "_LineSublineUnfilledColor": P["DIS_ARC"],
                           "_NubColor": P["DIS_MARK"]}}
    return base, states, BOUNDS["knob"], None


def knob_parts(P, n):
    yield n("Knob"), dial(P, 44, 3.0, 2.0)
    yield n("KnobHero"), dial(P, 96, 4.5, 3.0)
    yield n("KnobSmall"), dial(P, 36, 2.5, 2.0)


# ── faders (UI/SDFSlider) and the switch (UI/SDFTogglePill) ─────────────────

def fader(P, *, bg=None, bg_pad=0.13, bg_corner=0.9, track_w=0.2, fill=None, handle_w=0.12, handle_h=0.8):
    base = flat_common("Slider")
    base.update({
        "_Value": 0.5, "_TrackValueZeroPoint": 0.0,
        "_BgEnabled": 1 if bg else 0, "_BgColor": bg or P["FACE"], "_BgShapeType": 0,
        "_BgShapeParam1": bg_corner, "_BgPadding": bg_pad,
        "_TrackEnabled": 1, "_TrackColor": P["TRACK"], "_TrackWidth": track_w,
        "_TrackValueFilledEnabled": 1, "_TrackValueFilledColor": fill or P["VALUE"],
        "_TrackValueUnfilledEnabled": 0,
        "_HandleEnabled": 1, "_HandleColor": P["HANDLE"], "_HandleShapeType": 2, "_HandleShapeParam1": 0.2,
        "_HandleWidth": handle_w, "_HandleHeight": handle_h, "_HandlePadding": 0.5,
        "_BorderEnabled": 0,
    })
    states = {"Hover": {"_HandleColor": P["HANDLE_HI"]},
              "Pressed": {"_HandleColor": P["HANDLE_HI"], "_TrackValueFilledColor": P["VALUE_HI"]},
              "Disabled": {"_HandleColor": P["DIS_MARK"], "_TrackValueFilledColor": P["DIS_MARK"],
                           "_TrackColor": P["DIS_ARC"]}}
    return base, states, BOUNDS["slider"], None


def switch(P):
    base = flat_common("Toggle")
    base.update({
        "_Value": 0.0, "_StateCount": 2,
        "_BgEnabled": 0, "_BgColor": P["INSET"], "_BgPadding": 0.12,
        "_TrackEnabled": 1, "_TrackColor": P["TRACK"], "_TrackHeight": 0.85, "_TrackCornerRadius": 1.0,
        "_HandleEnabled": 1, "_HandleColor": P["HANDLE"], "_HandlePadding": 0.3, "_HandleFlatten": 0.0,
        "_HandleFaceEnabled": 0,
        # ON = the handle takes the accent. The surface blend is gated on _LedEnabled, the bloom ball
        # on _LedEnabled AND intensity — so enabled at intensity 0 recolours without a second ball.
        "_LedEnabled": 1, "_LedColor": P["ACCENT"], "_LedIntensity": 0.0, "_LedSurfaceBlend": 1.0,
        "_BorderEnabled": 0,
    })
    states = {"Hover": {"_TrackColor": P["ARC_OFF_HI"]},
              "Disabled": {"_HandleColor": P["DIS_MARK"], "_LedSurfaceBlend": 0.0, "_TrackColor": P["DIS_ARC"]}}
    return base, states, BOUNDS["pill"], None


def control_parts(P, n):
    yield n("Slider"), fader(P)
    # The multitrack's gutter zoom fader: square, unpadded, in the same channel as the scrollbars.
    yield n("Fader"), fader(P, bg=P["BACK"], bg_pad=0.02, bg_corner=1.0, track_w=0.4, fill=P["SCROLL_HI"],
                            handle_w=0.3, handle_h=0.9)
    yield n("Pill"), switch(P)


# ── plates (UI/SDFPanel) ────────────────────────────────────────────────────

def plate(P, color, *, pad=0.01, corner=0.98, pad_px=1.0, radius_px=0.0):
    """Proportional pad/corner stay as the fallback (and for the Designer's preview); the PX values
    win at runtime, so a plate's edge and corners are the same at every panel size — a big PD-48 no
    longer grows a margin and a corner that swallow its title bar."""
    base = flat_common("Panel")
    base.update({
        "_PanelEnabled": 1, "_PanelColor": color, "_PanelRenderAlpha": 1.0, "_PanelRenderEmissive": 0.0,
        "_PanelShapeType": 0, "_PanelShapeParam1": corner, "_PanelPadding": pad,
        "_PanelPaddingPx": pad_px, "_PanelCornerRadiusPx": radius_px,
        "_BorderEnabled": 0,
    })
    return base, {}, BOUNDS["panel"], None


def plate_parts(P, n):
    yield n("Face"), plate(P, P["FACE"], pad_px=2.0, radius_px=4.0)
    yield n("Inset"), plate(P, P["INSET"], corner=0.97, radius_px=3.0)
    yield n("Socket"), plate(P, P["SOCKET"], pad=0.03, corner=0.9, pad_px=2.0, radius_px=4.0)
    yield n("Well"), plate(P, P["WELL"], corner=0.9, radius_px=3.0)
    yield n("Back"), plate(P, P["BACK"], pad=0.004, corner=0.995, radius_px=1.0)
    yield n("Bezel"), plate(P, P["INSET"], corner=0.9, radius_px=3.0)
    yield n("ScrollTrack"), plate(P, P["INSET"], corner=1.0)   # a visible channel in the BACK gutter


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
            # skin() wrote the doc before "author" was added; rewrite with it.
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

    # Each cell renders over the plate it sits on, not transparent black: an AA edge blended into
    # black and then alpha-composited again reads as a dark outline the app never draws.
    plate_col = {"Face": "FACE", "Inset": "INSET", "Socket": "SOCKET", "Well": "WELL", "Back": "BACK",
                 "ScrollTrack": "INSET", "Bezel": "INSET"}
    plates = []

    def under(x, y):
        for px_, py_, pw, ph, col in reversed(plates):
            if px_ <= x < px_ + pw and py_ <= y < py_ + ph:
                return col
        return P["GAP"]

    def add(cid, part, w, h, x, y, **kw):
        c = {"id": f"fl-{tag}-{cid}", "states": paths[part], "w": w, "h": h, "ss": 1, "bg": under(x, y)}
        c.update(kw)
        cells.append(c)
        meta.append((c["id"], x, y))
        if part in plate_col:
            plates.append((x, y, w, h, P[plate_col[part]]))

    def txt(x, y, s, col, size=11, bold=False):
        texts.append((x, y, s, col, size, bold))

    ink, dim = P["MARK"], P["MARK_DIM"]

    # device 1: a mixer-ish module
    add("face1", "Face", 600, 330, 10, 10)
    txt(22, 18, "EQ EIGHT", ink, 12, True)
    add("lamp-on", "Lamp", 30, 30, 540, 14, state="Active")
    add("lamp-off", "Lamp", 30, 30, 505, 14)
    add("close", "Close", 36, 30, 570, 14, state="Normal,Hover")
    for i, v in enumerate((0.0, 0.35, 0.72, 1.0)):
        x = 24 + i * 70
        add(f"k{i}", "Knob", 44, 44, x, 56, set={"_Value": v})
        txt(x + 4, 102, ("GAIN", "FREQ", "Q", "MIX")[i], dim, 10)
        txt(x + 6, 116, ("-inf", "1.2k", "0.71", "100%")[i], ink, 10)
    add("kdis", "Knob", 44, 44, 304, 56, state="Disabled", set={"_Value": 0.5})
    txt(302, 102, "OFF", dim, 10)
    add("khov", "Knob", 44, 44, 374, 56, state="Normal,Hover", set={"_Value": 0.5})
    txt(372, 102, "HOVER", dim, 10)
    for i, v in enumerate((0.2, 0.55, 0.9)):
        add(f"ks{i}", "KnobSmall", 36, 36, 444 + i * 52, 60, set={"_Value": v})
    add("well", "Well", 150, 32, 24, 142)
    txt(34, 148, "120.00", ink, 16, True)
    txt(106, 152, "BPM", dim, 10)
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
        x = 24 + i * 62
        add(f"b{i}", part, w, h, x, row_y, state=st)
        txt(x, row_y + 30, lab, dim, 9)
    add("acc", "Accent", 100, 34, 24, 250)
    txt(52, 259, "PLAY", P["ON_MARK"], 12, True)
    add("hero", "Button", 140, 38, 136, 248)
    txt(172, 259, "Sign out", ink, 12)
    add("wide", "Button", 100, 34, 288, 250, state="Normal,Hover")
    txt(310, 259, "Export", ink, 12)

    # device 2: hero dial on an inset
    add("inset", "Inset", 300, 150, 630, 10)
    add("kh", "KnobHero", 96, 96, 650, 24, set={"_Value": 0.66})
    txt(752, 40, "MASTER", dim, 11, True)
    txt(752, 58, "-3.2 dB", ink, 18, True)
    add("kh2", "KnobHero", 96, 96, 826, 24, state="Normal,Hover,Pressed", set={"_Value": 0.25})

    # device 3: a drum-rack of pads in a socket
    add("socket", "Socket", 300, 170, 630, 170)
    rows = json.loads((ROOT / "Assets/Resources/TrackThemes/Nebula.track.json").read_text(encoding="utf-8"))["palette"]
    body = [int(P["PAD_BODY"].lstrip("#")[j:j + 2], 16) / 255 for j in (0, 2, 4)]
    for r in range(3):
        rgb = [int(rows[f"row{r + 1}"].lstrip("#")[j:j + 2], 16) / 255 for j in (0, 2, 4)]
        col = ",".join(f"{body[j] + (rgb[j] - body[j]) * P['PAD_TINT']:.5f}" for j in range(3)) + ",1"
        for c in range(5):
            st = "Normal"
            if (r, c) == (0, 1):
                st = "Normal,Latched"
            elif (r, c) == (1, 3):
                st = "Normal,Hover,Pressed"
            add(f"p{r}{c}", "Pad", 52, 48, 642 + c * 56, 182 + r * 52, state=st, set={"_ButtonColor": col})

    # device 4: multitrack gutter
    add("back", "Back", 920, 60, 10, 352)
    add("strack", "ScrollTrack", 420, 12, 24, 372)
    add("shandle", "ScrollHandle", 110, 12, 90, 372)
    add("dot", "Dot", 16, 16, 460, 370)
    add("fader", "Fader", 120, 12, 490, 372, set={"_Value": 0.4})
    txt(630, 368, "A01  KICK", ink, 12, True)

    # the rest of the room
    add("face2", "Face", 920, 110, 10, 420)
    txt(22, 430, f"FLAT {mode.upper()} — {tag}  (unlit, non-RM, ss=1)", ink, 13, True)
    txt(22, 452, "gaps are the darkest value; plates step up; keys step up again; ON is the only colour",
        dim, 11)

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
    big = img.resize((W * 2, H * 2), Image.NEAREST)
    big.convert("RGB").save(SC / f"sheet-{mode}-{tag}@2x.png")
    print(out)
    return out


# ── the recipe (Resources/UiStyles/Flat.style.json) ──────────────────────────
#
# Generated from the same tables as the parts so a hex lives in one place. Every role, family and
# by-name skin is rostered to an authored FlatDark*/FlatLight* file; nothing is baked, so nothing in
# either mode can inherit an RM shader or a lit parameter from the skin it would have recoloured.

FAMILY_PART = {"Button": "Button", "Knob": "Knob", "Slider": "Slider", "Toggle": "Pill", "Panel": "Face"}
ROLE_PART = {
    "pad": "Pad", "button.standard": "Button", "button.small": "Button", "button.wide": "Button",
    "button.hero": "Button", "button.accent": "Accent", "button.close": "Close", "toggle.button": "ToggleBtn",
    "toggle.pill": "Pill", "lamp": "Lamp", "knob.hero": "KnobHero", "knob.large": "Knob", "knob.medium": "Knob",
    "knob.small": "KnobSmall", "slider.long": "Slider", "slider.standard": "Slider",
    "panel.faceplate": "Face", "panel.inset": "Inset", "panel.socket": "Socket", "display.well": "Well",
    "panel.backplane": "Back",
}
# Skins layouts author outside a rostered role, and skins C# loads BY NAME (SkinResolver.ThemedStates).
# Faceplates are uniform on purpose: Flat is one tool, not a rack of assembled coloured modules.
SWAP_PART = {
    "GreyButtonRM": "Button", "AccentButtonRM": "Accent", "MuteToggleRM": "ToggleBtn", "SoloToggleRM": "Solo",
    "EnableLampRM": "Lamp", "CloseButtonRM": "Close", "LearnChipRM": "Chip", "RackDot": "Dot",
    "RackScrollHandle": "ScrollHandle", "RedKnobRM": "Knob", "RackSlider": "Slider", "RackGutterFader": "Fader",
    "UI_SDFTogglePill": "Pill", "MidiLearnPill": "Pill", "LedWellBlue": "Well", "RackPlateInset": "Inset",
    "PadSocket": "Socket", "PadWell": "Socket", "RackBackplane": "Back", "RackFaceplateGraphite": "Face",
    "RackFaceplateSilver": "Face", "RackFaceplateBlue": "Face", "RackFaceplateRust": "Face",
    "RackFaceplateGreen": "Face", "RackFaceplateCream": "Face", "DisplayBezel": "Bezel",
    "RackScrollTrack": "ScrollTrack",
}

# Every screen gets a flat finish (ScopeFinishes.json): no glass, no LED matrix, no phosphor tube,
# no glow — a plain well with a crisp curve. "*" catches finishes added to layouts later.
AUTHORED_FINISHES = ("glass.amber", "glass.cyan", "led.matrix.green", "led.matrix.amber", "lcd.grey",
                     "crt.phosphor", "plastic.blue", "flat", "*")


def display_map(mode):
    m = {k: f"flat.{mode}" for k in AUTHORED_FINISHES}
    m["led.matrix.green"] = m["led.matrix.amber"] = f"flat.{mode}.meter"
    m["waveform"] = f"flat.{mode}.waveform"
    return m


APP = {
    "dark": dict(
        trackTheme="Nebula",
        blurb="Charcoal and one orange. Unlit, sharp and cheap to draw - the phone look.",
        hot="#FF5A48",
        chrome=dict(headerBg="#1F1F1F", headerBorder="#00000000", tabFillBottom="#222222", tabFillTop="#222222",
                    tabFillActiveBottom="#2A2A2A", tabFillActiveTop="#2A2A2A", label="#9A9A9A",
                    labelActive="#D6D6D6", icon="#9A9A9A", iconActive="#FF9F1C", gear="#9A9A9ACC",
                    meatballIdle="#9A9A9A", meatballLit="#FF9F1C"),
        palettes={
            "ui": dict(text="#D6D6D6", textDim="#9A9A9A", textFaint="#666666", accent="#FF9F1C",
                       warn="#F5C431", danger="#FF5A48", ok="#5ED17A"),
            "surface": dict(card="#2A2A2AFA", cardEdge="#3A3A3A", divider="#1F1F1F", scrim="#0A0A0AB8",
                            backdrop="#141414", gap="#141414"),
            # Light ink for PLATES only. The cream/silver modules print dark silkscreen that vanishes on
            # a uniform dark faceplate; PrintInk flips dark neutral print when the surface's ink is
            # light. No "key" entry: C# prints dark marks on orange accent keys on purpose.
            "ink": dict(faceplate="#D6D6D6", faceplateDim="#8C8C8C", inset="#D6D6D6", insetDim="#8C8C8C",
                        backplane="#D6D6D6", backplaneDim="#8C8C8C", socket="#D6D6D6", socketDim="#8C8C8C",
                        reviewBar="#D6D6D6", reviewBarDim="#8C8C8C"),
            # textAlt == text: every readout prints in one ink (the channel name was the lone orange one)
            "display": dict(text="#E6E6E6", textDim="#8C8C8C", textAlt="#E6E6E6", warn="#FF5A48"),
            # multitrack latch marks: a lit mute/solo key FILLS (Active state), so its mark goes dark;
            # the velocity key has no fill, so its mark takes the accent
            "key": dict(label="#D6D6D6", faceOff="#3E3E3E", edgeOff="#2E2E2E", markOff="#9A9A9A",
                        bankFaceOff="#353535", bankEdgeOff="#2A2A2A",
                        glyphOff="#9A9A9A", muteOn="#161616", soloOn="#161616", velOff="#8C8C8C", velOn="#FF9F1C"),
            "pad": dict(empty="#262626FF"),
            "review": dict(bar="#1E1E1EF0", barRule="#FFFFFF14"),
            "tracks": dict(backdrop="#1B1B1B", strip="#222222", rowWithSample="#2E2E2E", rowEmpty="#262626",
                           rowNotesNoSample="#3A2B2B", text="#BDBDBD", ruler="#8C8C8CE6", playhead="#E6E6E6E6",
                           recMarker="#FF4A3DDC", scrollbar="#FFFFFF1E"),
        },
    ),
    "light": dict(
        trackTheme="Rosewater",
        blurb="Studio grey in daylight. Unlit, sharp and cheap to draw.",
        hot="#D0382B",
        chrome=dict(headerBg="#C2C2C2", headerBorder="#00000000", tabFillBottom="#C4C4C4", tabFillTop="#C4C4C4",
                    tabFillActiveBottom="#D0D0D0", tabFillActiveTop="#D0D0D0", label="#555555",
                    labelActive="#1C1C1C", icon="#555555", iconActive="#F28C00", gear="#555555CC",
                    meatballIdle="#555555", meatballLit="#F28C00"),
        palettes={
            "ui": dict(text="#1C1C1C", textDim="#555555", textFaint="#8A8A8A", accent="#F28C00",
                       warn="#B07A00", danger="#D0382B", ok="#2E9E55"),
            "surface": dict(card="#D6D6D6FA", cardEdge="#B0B0B0", divider="#C2C2C2", scrim="#1C1C1C99",
                            backdrop="#A8A8A8", gap="#A8A8A8"),
            # Print on surfaces this look re-finished (PrintInk): light literals become dark ink.
            "ink": dict(faceplate="#1C1C1C", faceplateDim="#5A5A5A", inset="#1C1C1C", insetDim="#5A5A5A",
                        backplane="#1C1C1C", backplaneDim="#5A5A5A", socket="#1C1C1C", socketDim="#5A5A5A",
                        key="#1C1C1C", keyDim="#555555", reviewBar="#1C1C1C", reviewBarDim="#5A5A5A"),
            "display": dict(text="#1C1C1C", textDim="#5A5A5A", textAlt="#1C1C1C", warn="#D0382B"),
            "key": dict(label="#1C1C1C", faceOff="#BDBDBD", edgeOff="#A9A9A9", markOff="#555555",
                        bankFaceOff="#C4C4C4", bankEdgeOff="#A9A9A9",
                        glyphOff="#3C3C3C", muteOn="#141414", soloOn="#141414", velOff="#555555", velOn="#D67B00"),
            "pad": dict(empty="#C8C8C8FF"),
            # challenge slots and note rings drawn for pale lanes (the defaults are dark-look greys)
            "review": dict(bar="#C4C4C4F0", barRule="#0000001A", slot="#8C8C8C", slotFill="#DADADA"),
            "tracks": dict(backdrop="#BEBEBE", strip="#C6C6C6", rowWithSample="#D8D8D8", rowEmpty="#CFCFCF",
                           rowNotesNoSample="#E0CDCD", text="#262626", ruler="#4A4A4AE6", playhead="#1C1C1CE6",
                           recMarker="#D0382BDC", scrollbar="#0000001E", noteSeparator="#F2F2F2"),
        },
    ),
}

RECIPE_HEADER = """// ═══════════════════════════════════════════════════════════════════════════
// FLAT — unlit, non-raymarched, Ableton-style. The look a phone can afford.
//
// GENERATED by `python Tools/design_flat.py recipe` from the same tables as the FlatDark*/FlatLight*
// parts — edit design_flat.py, not this file. Every role, family and by-name skin rosters an authored
// file (UI/SDFKnob, UI/SDFButton, ... with _LightingUnlit 1), so nothing is baked and nothing can
// inherit an RM shader or a lit parameter. The rig (Themes/Flat.theme) has every lamp off, and with
// no shadow authored anywhere the UI shadow capture pass idles.
// ═══════════════════════════════════════════════════════════════════════════
"""


def recipe():
    def roster(pre):
        return ({f: {"$base": pre + p} for f, p in FAMILY_PART.items()},
                {r: {"$base": pre + p} for r, p in ROLE_PART.items()})

    fam, roles = roster(MODES["dark"]["prefix"])
    doc = {
        "styleName": "Flat", "title": "Flat", "order": 4, "author": "DrumSumDrum",
        "blurb": "Unlit and sharp. Form from value steps and one warm accent - no bevel, no shadow, no glow.",
        "stateShifts": {"Hover": 0.08, "Pressed": -0.1, "Active": 0.16, "Disabled": -0.22},
        "families": fam, "roles": roles, "modes": {},
    }
    for mode in ("dark", "light"):
        P, A = MODES[mode], APP[mode]
        fam, roles = roster(P["prefix"])
        doc["modes"][mode] = {
            "trackTheme": A["trackTheme"], "blurb": A["blurb"], "lights": "Themes/Flat.theme",
            "colors": {"face": P["FACE"], "inset": P["INSET"], "backplane": P["BACK"], "well": P["WELL"],
                       "body": P["BODY"], "bodyAlt": P["PRESS"], "accent": P["ACCENT"], "line": P["ARC_OFF"],
                       "hot": A["hot"], "lamp": P["LAMP"], "mark": P["MARK"]},
            "chrome": A["chrome"], "palettes": A["palettes"],
            "displays": display_map(mode),
            "families": fam, "roles": roles,
            "swaps": {k: P["prefix"] + v for k, v in SWAP_PART.items()},
        }
    out = ROOT / "Assets/Resources/UiStyles/Flat.style.json"
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
