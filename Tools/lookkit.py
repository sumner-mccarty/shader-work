#!/usr/bin/env python3
"""lookkit — the shared look kit: a compact LOOK SPEC in, a complete DrumSumDrum look out.

    python Tools/looks/<module>.py check                    # build in memory + audit every rule
    python Tools/looks/<module>.py write [dark|light|both]  # states files, recipe, rig (+ track theme)
    python Tools/looks/<module>.py sheet [dark|light|both]  # Looks/<slug>/sheets/{rack,parts}-<mode>.png
    python Tools/looks/<module>.py recipe                   # just Resources/UiStyles/<Style>.style.json
    python Tools/looks/<module>.py diff                     # what `write` would change, byte for byte
    python Tools/looks/<module>.py manifest                 # Looks/<slug>/look.json
    python Tools/looks/<module>.py selftest                 # break each rule on a copy: audit must catch it
      --root DIR      write/diff against DIR/Assets/Resources/... instead of the repo (scratch builds)
      --colourway X   act on one declared colourway (its own Style) instead of the base look
    (or: python Tools/lookkit.py <module|path.py> <command> ...)

A look used to be a 700-line generator (Tools/design_flat.py, design_tron.py) that hand-wrote every
part, every state, the roster, the recipe and a sheet harness. Everything that is the SAME for every
look lives here instead, so a look is the part that is actually its own — ~150 lines of spec:

    LOOK = Look(
        title="Gold Leaf", style="GoldLeaf", prefix="GoldLeaf", slug="gold-leaf", cls="lit",
        order=7, blurb="...", note="what the recipe banner says",
        modes={"dark":  dict(palette={...tokens...}, app={...overrides...}, track="Nebula", blurb="..."),
               "light": dict(palette={...}, app={...}, track="Rosewater", blurb="...")},
        shape={"key": {...}, "dial": {...}, "plate": {...}, "<Slot>": {...}},   # form language
        material={"plate": {...}, "key": {...}, "knob": {...}},                   # lit only: patterns
        rig={"dark": {...lamps...}, "light": {...}},                              # lit only
        displays="neo",                       # finish family for screens, or a full {authored: finish}
        colourways={"Emerald": dict(title=..., palette={"dark": {...}, "light": {...}})},
        waive={"rule:Slot": "why this look may break it"},
    )
    if __name__ == "__main__":
        main(LOOK)

THE THREE CLASSES (`cls`) — each is a complete part vocabulary with its own state grammar:
  * "unlit" — Flat's rules. Non-RM shaders, _LightingUnlit 1, form from value steps and one accent.
  * "neon"  — Tron's rules. Unlit too, but every edge is a light tube: CORE (border, emissive,
              gradient) + BLOOM (edge ring, alpha 0, emissive — additive) + SHEEN (unlit bevel band).
  * "lit"   — the raymarched UI/*RM shaders under a lamp rig, the vocabulary of the shipped
              Realistic*, NeoDark*/NeoLight* and RackFaceplate* skins: domed keys with a milled
              bevel, capped knobs with a skirt silhouette, px-locked patterned plates, ONE shadow
              contract for every control.
  `shape` and `material` override the class defaults (CLASS_SHAPE / LIT_MATERIAL below) per group
  ("key", "dial", "fader", "switch", "plate") or per slot ("Accent", "KnobHero", "Face", ...);
  slot beats group beats class default. The palette is per mode: the token names each class reads
  are listed in PALETTE_DEFAULTS / *_TOKENS; a token a class needs and the spec omits is an error.

THE SKILL'S RULES ARE ENFORCED, NOT DOCUMENTED (see audit()) — `check` fails on any of them:
  bounds on every part · every effect guard written, on or off · footprints (padding param) equal
  to the app skin each part swaps for · _ButtonLipHeight/_KnobLipHeight/_HandleLipHeight 0 on RM
  parts · _LightingShadow1Enabled explicit on knobs · plates: no face dome, bevel distance <= 0.14,
  no bevel on the outermost plates (Face/Back) of a lit look · every patterned plate pixel-locked
  (_PanelPatternPx) · value arc _LineRadius + _LineWidth <= 0.88 (0.92 with square ends) · a light
  mode changes the chassis, not the controls · full roster (every role, family and by-name swap).
  A look that must break one says so in `waive={"<rule>:<Slot or mode>": "reason"}`; the reason is
  printed by `check` so the exception is reviewed, not silent.

OUTPUT: Assets/Resources/MaterialStates/<Prefix>{Dark,Light}<Slot>.states.json (23 parts per mode),
UiStyles/<Style>.style.json, Themes/<Style>.theme.json (unlit/neon: every lamp off) or
Themes/<Style>{Dark,Light}.theme.json (lit), TrackThemes/<Name>.track.json when the spec defines
one, and Looks/<slug>/sheets/{rack,parts}-{dark,light}.png — the RACK COMPOSITE (every part placed
on the plate it sits on) is what reviewers judge.

SHEETS composite premultiplied: slrender draws every cell on transparent black exactly as the app's
blend (`One OneMinusSrcAlpha`) would, so `canvas = cell.rgb + (1 - cell.a) * canvas` is exact — an
anti-aliased edge never darkens and a neon bloom (alpha 0, emissive) stays ADDITIVE light on the plate.
"""
from __future__ import annotations

import copy
import difflib
import importlib.util
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from skinlib import skin, props, BOUNDS, FAMILY, mix  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
RES_REL = Path("Assets/Resources")
MODES = ("dark", "light")

# ═══ 1. the roster — every slot the app's SkinResolver consults ═══════════════════════════════════
#
# (Was design_flat.py's; lookcheck.py mirrors it.) Every role, family and by-name skin is rostered to
# an authored file, nothing is baked, so nothing can inherit an RM shader or a lit parameter.

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
# Screen finishes a layout can author (UiThemes/ScopeFinishes.json); "*" catches ones added later.
AUTHORED_FINISHES = ("glass.amber", "glass.cyan", "led.matrix.green", "led.matrix.amber", "lcd.grey",
                     "crt.phosphor", "plastic.blue", "flat", "*")

# ═══ 2. slots — the 23 parts every look emits per mode ════════════════════════════════════════════
#
# suffix: (shader family, BOUNDS key, shape group, the app skin it swaps for, that skin's footprint).
# The FOOTPRINT is the padding param the runtime derives the hitbox from (_ButtonPadding / _BgPadding):
# a swap must change the finish, never the layout or the hitbox — audit() holds every part to it.
SLOTS = {
    "Button":       ("Button", "button",        "key",    "GreyButtonRM",          0.252),
    "Accent":       ("Button", "button_accent", "key",    "AccentButtonRM",        0.252),
    "ToggleBtn":    ("Button", "button_round",  "key",    "MuteToggleRM",          0.116),
    "Solo":         ("Button", "button_round",  "key",    "SoloToggleRM",          0.116),
    "Lamp":         ("Button", "button_round",  "key",    "EnableLampRM",          0.34),
    "Close":        ("Button", "button_round",  "key",    "CloseButtonRM",         0.116),
    "Chip":         ("Button", "button",        "key",    "LearnChipRM",           0.13),
    "Dot":          ("Button", "button",        "key",    "RackDot",               0.252),
    "ScrollHandle": ("Button", "button",        "key",    "RackScrollHandle",      0.1),
    "Pad":          ("Button", "button",        "key",    None,                    0.12),
    "Knob":         ("Knob",   "knob",          "dial",   "RedKnobRM",             None),
    "KnobHero":     ("Knob",   "knob",          "dial",   None,                    None),
    "KnobSmall":    ("Knob",   "knob",          "dial",   None,                    None),
    "Slider":       ("Slider", "slider",        "fader",  "RackSlider",            0.13),
    "Fader":        ("Slider", "slider",        "fader",  "RackGutterFader",       0.02),
    "Pill":         ("Toggle", "pill",          "switch", "UI_SDFTogglePill",      0.12),
    "Face":         ("Panel",  "panel",         "plate",  "RackFaceplateGraphite", None),
    "Inset":        ("Panel",  "panel",         "plate",  "RackPlateInset",        None),
    "Socket":       ("Panel",  "panel",         "plate",  "PadSocket",             None),
    "Well":         ("Panel",  "panel",         "plate",  "LedWellBlue",           None),
    "Back":         ("Panel",  "panel",         "plate",  "RackBackplane",         None),
    "Bezel":        ("Panel",  "panel",         "plate",  "DisplayBezel",          None),
    "ScrollTrack":  ("Panel",  "panel",         "plate",  "RackScrollTrack",       None),
}
PAD_PARAM = {"Button": "_ButtonPadding", "Slider": "_BgPadding", "Toggle": "_BgPadding"}
LATCHES = ("ToggleBtn", "Solo", "Lamp")


def footprint_report():
    """Re-read each app skin's padding param: the SLOTS table must still match what ships."""
    out = []
    for suf, (fam, _, _, app, fp) in SLOTS.items():
        if not app or fp is None:
            continue
        f = ROOT / RES_REL / "MaterialStates" / f"{app}.states.json"
        if not f.exists():
            out.append(f"footprint source {app} missing")
            continue
        doc = json.loads(f.read_text(encoding="utf-8-sig"))
        norm = next(s for s in doc["states"] if not s.get("baseStateName"))
        v = next((float(p["value"]) for p in norm["parameters"] if p["name"] == PAD_PARAM[fam]), None)
        if v is None or abs(v - fp) > 5e-4:
            out.append(f"SLOTS[{suf}] footprint {fp} != {app} {PAD_PARAM[fam]} {v}")
    return out


# ═══ 3. colour + gradient helpers ═════════════════════════════════════════════════════════════════

def first(c):
    return c if isinstance(c, str) else c[0]


def stops(s):
    s = [s] if isinstance(s, str) else list(s)
    return s * 2 if len(s) == 1 else s


def gcol(layer, st):
    """Just the colour stops of a gradient — what a state delta changes."""
    s = stops(st)
    padded = s + [s[-1]] * (4 - len(s))
    d = {f"{layer}GradientColor{c}": padded[i] for i, c in enumerate("ABCD")}
    d[f"{layer}GradientColorUsed"] = len(s)
    return d


def grad(layer, st, direction=(1.0, 0.0)):
    """A linear gradient normalised so the widget's own 0-1 UV square spans exactly stop A..last.
    (LinearGradient is dot(uv, normalize(dir)) * scale + offset; uv.y is 0 at the BOTTOM.)"""
    dx, dy = direction
    ln = (dx * dx + dy * dy) ** 0.5
    nx, ny = dx / ln, dy / ln
    corners = (0.0, nx, ny, nx + ny)
    lo, hi = min(corners), max(corners)
    scale = 1.0 / (hi - lo)
    d = {f"{layer}GradientEnabled": 1, f"{layer}GradientType": 0,
         f"{layer}GradientDirection": (dx, dy, 0, 0), f"{layer}GradientScale": scale,
         f"{layer}GradientOffset": -lo * scale, f"{layer}GradientSpeed": 0.0}
    d.update(gcol(layer, st))
    return d


def rgbf(hexcol):
    s = hexcol.lstrip("#")
    return [int(s[j:j + 2], 16) / 255 for j in (0, 2, 4)]


def lum(hexcol):
    r, g, b = rgbf(first(hexcol))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def alpha(hexcol, a):
    """'#RRGGBB' + an alpha byte ('CC' or 0.8)."""
    if not isinstance(a, str):
        a = f"{round(a * 255):02X}"
    return first(hexcol)[:7] + a


# Every guard for a surface EFFECT. Structural guards (_IconEnabled, _FillEnabled, _TrackEnabled, ...)
# are set per part instead, on or off, because each part means something different by them.
# An UNSET guard inherits the source MATERIAL's value, not the shader default — so "no bevel / no
# pattern / no shadow" has to be said, not assumed.
FX = re.compile(r'^_\w*(Bevel|Pattern|Gradient|Rim|Shadow\d|Glow|Screws|InnerFrame|OuterMarks|OuterRing\d|'
                r'FaceShape|ScaleMark|Edge)\w*Enabled$')
RM_ONLY_OK = re.compile(r"^_(\w+LipHeight|\w+MaxCast|\w+BevelEnabled)$")   # RM-only names a lit skin may set
PATTERNS = {n: i for i, n in enumerate(
    "Plastic Metal RadialBrushed CarbonFiber Leather BrushedCross Satin Concrete Fabric Paper Frosted "
    "DiamondPlate Knurled HexGrid Perforated WoodGrain Marble Ceramic Circuit NoiseOrganic".split())}
KNOB_SHAPES = {n: i for i, n in enumerate(
    "Circle GripNubs Polygon DShaft Star Squircle Fluted Cross ChickenHead Arrow Gear Skirted OvalPointer "
    "MushroomCap DaviesIndicator ColletKnob RingPointer BlobStar CapScrew TaperDisc FaderCap FaderCapWide".split())}


def stem(family, rm):
    return FAMILY[family][1] if rm else FAMILY[family][2]


def guards(family, rm):
    return [k for k in props(stem(family, rm)) if FX.match(k) and "Global" not in k]


# ═══ 4. the classes ═══════════════════════════════════════════════════════════════════════════════
#
# Each class is a full part vocabulary: parts(L, P) yields (slot, base, states, extra) for all 23
# SLOTS. P is the mode's palette, L the look (L.S(slot) = its resolved shape language).

class Unlit:
    """FLAT (2026-09-13) — the look a phone can afford. Non-RM shaders + _LightingUnlit, so the rig,
    bevel normals and the shadow capture pass cost nothing and the authored hex is exactly what lands
    on screen under ANY rig. Form comes only from value steps between neutrals, one accent for ON, and
    thin crisp strokes: capless dials (arc + needle), square keys with a small corner, flat plates
    separated by darker gaps."""
    rm = False
    TOKENS = ("GAP BACK WELL INSET SOCKET FACE BODY BODY_HI PRESS MARK MARK_DIM DIS_BODY DIS_MARK ACCENT "
              "ACCENT_HI ACCENT_LO ACCENT_DIS ON_MARK SOLO LAMP HOT ARC_OFF ARC_OFF_HI VALUE VALUE_HI DIS_ARC "
              "TRACK HANDLE HANDLE_HI PAD_BODY PAD_TINT PAD_LATCH SCROLL SCROLL_HI").split()
    SHAPE = {
        "key": dict(shape=0, corner=0.78, round=0.0, icon=None, icon_size=0.42, alpha=1.0, stroke=0.05),
        "Accent": dict(corner=0.744),
        # Marks at 0.55, not the RM keys' 0.42: a speaker/eye glyph at 0.42 on a 24px key is a smudge.
        "ToggleBtn": dict(icon=17, icon_size=0.55), "Solo": dict(icon=16, icon_size=0.55),
        "Lamp": dict(icon=29, icon_size=0.62, corner=0.8), "Close": dict(icon=19, icon_size=0.4, alpha=0.0),
        "Chip": dict(corner=0.7), "Dot": dict(corner=0.02, round=0.9), "ScrollHandle": dict(corner=0.5),
        "Pad": dict(corner=0.86),
        # capless dials; widths derive from the part's real pixel size (why the three roles are files)
        "dial": dict(silhouette="needle", arc_outer=0.92),
        "Knob": dict(px=44, stroke_px=3.0, needle_px=2.0), "KnobHero": dict(px=96, stroke_px=4.5, needle_px=3.0),
        "KnobSmall": dict(px=36, stroke_px=2.5, needle_px=2.0),
        "fader": dict(bg=None, corner=0.9, track_w=0.2, fill="VALUE", handle_w=0.12, handle_h=0.8),
        # the multitrack's gutter zoom fader: square, unpadded, in the same channel as the scrollbars
        "Fader": dict(bg="BACK", corner=1.0, track_w=0.4, fill="SCROLL_HI", handle_w=0.3, handle_h=0.9),
        "switch": dict(track_h=0.85),
        "plate": dict(pad=0.01, corner=0.98, pad_px=1.0, radius_px=0.0),
        "Face": dict(fill="FACE", pad_px=2.0, radius_px=4.0), "Inset": dict(fill="INSET", corner=0.97, radius_px=3.0),
        "Socket": dict(fill="SOCKET", pad=0.03, corner=0.9, pad_px=2.0, radius_px=4.0),
        "Well": dict(fill="WELL", corner=0.9, radius_px=3.0),
        "Back": dict(fill="BACK", pad=0.004, corner=0.995, radius_px=1.0),
        "Bezel": dict(fill="INSET", corner=0.9, radius_px=3.0),
        "ScrollTrack": dict(fill="INSET", corner=1.0),        # a visible channel in the BACK gutter
    }
    RECIPE_COLORS = dict(face="FACE", inset="INSET", backplane="BACK", well="WELL", body="BODY", bodyAlt="PRESS",
                         accent="ACCENT", line="ARC_OFF", hot="HOT", lamp="LAMP", mark="MARK")

    @staticmethod
    def common(family, P=None):
        p = props(stem(family, False))
        d = {k: 0 for k in guards(family, False)}
        d["_LightingUnlit"] = 1
        d["_LightingAmbient"] = 1.0
        if "_ReceiveSceneShadows" in p:
            d["_ReceiveSceneShadows"] = 0
        return d

    # ── keys (UI/SDFButton) ──
    def key(self, L, P, slot, *, fill, mark=None, states=None, extra=None):
        S = L.S(slot)
        base = self.common("Button")
        border = P.get("BORDER")
        base.update({
            "_ButtonEnabled": 1, "_ButtonColor": fill, "_ButtonRenderAlpha": S["alpha"], "_ButtonRenderEmissive": 0.0,
            "_ButtonShapeType": S["shape"], "_ButtonShapeParam1": S["corner"], "_ButtonPadding": S["pad"],
            "_ButtonRoundness": S["round"],
            "_BorderEnabled": 1 if border else 0, "_BorderColor": border or fill,
            "_BorderWidth": S["stroke"], "_BorderSoftness": 0.0,
            "_IconEnabled": 1 if S["icon"] is not None else 0,
        })
        if S["icon"] is not None:
            base.update({"_IconShapeType": S["icon"], "_IconColor": mark or P["MARK"], "_IconWidth": S["icon_size"],
                         "_IconHeight": S["icon_size"], "_IconRenderAlpha": 1.0, "_IconRenderEmissive": 0.0})
        return slot, base, states or {}, extra

    def keys(self, L, P):
        # Held = lit in the accent, the way a momentary key lights while you hold it. A merely darker
        # key vanished into the plate on dark and read as disabled on light.
        std = {"Hover": {"_ButtonColor": P["BODY_HI"]},
               "Pressed": {"_ButtonColor": P["ACCENT"], "_IconColor": P["ON_MARK"]},
               "Disabled": {"_ButtonColor": P["DIS_BODY"], "_IconColor": P["DIS_MARK"]}}
        yield self.key(L, P, "Button", fill=P["BODY"], states=std)
        yield self.key(L, P, "Accent", fill=P["ACCENT"],
                       states={"Hover": {"_ButtonColor": P["ACCENT_HI"]}, "Pressed": {"_ButtonColor": P["ACCENT_LO"]},
                               "Disabled": {"_ButtonColor": P["ACCENT_DIS"]}})
        # Latches: OFF is a grey key with a dim mark; ON fills with the colour of what it means and the
        # mark goes dark on it. Colour AND contrast change, so it reads without relying on hue alone.
        latch = dict(std, Hover={"_ButtonColor": P["BODY_HI"], "_IconColor": P["MARK"]})
        for slot, on in (("ToggleBtn", "ACCENT"), ("Solo", "SOLO"), ("Lamp", "LAMP")):
            yield self.key(L, P, slot, fill=P["BODY"], mark=P["MARK_DIM"],
                           states=dict(latch, Active={"_ButtonColor": P[on], "_IconColor": P["ON_MARK"]}))
        # A close X is just a mark until you point at it.
        yield self.key(L, P, "Close", fill=P["BODY_HI"], mark=P["MARK_DIM"],
                       states={"Hover": {"_ButtonRenderAlpha": 1.0, "_IconColor": P["MARK"]},
                               "Pressed": {"_ButtonColor": P["PRESS"]}, "Disabled": {"_IconColor": P["DIS_MARK"]}})
        yield self.key(L, P, "Chip", fill=P["BODY"], states=std)
        yield self.key(L, P, "Dot", fill=P["SCROLL"],
                       states={"Hover": {"_ButtonColor": P["SCROLL_HI"]}, "Pressed": {"_ButtonColor": P["MARK_DIM"]}})
        yield self.key(L, P, "ScrollHandle", fill=P["SCROLL"],
                       states={"Hover": {"_ButtonColor": P["SCROLL_HI"]}, "Pressed": {"_ButtonColor": P["MARK_DIM"]},
                               "Disabled": {"_ButtonRenderAlpha": 0.4}})
        # Pads wear their row's colour (padColor tints _ButtonColor), flat, like a clip slot.
        yield self.key(L, P, "Pad", fill=P["PAD_BODY"],
                       states={"Hover": {"_ButtonRenderEmissive": 0.08}, "Pressed": {"_ButtonRenderEmissive": 0.22},
                               "Disabled": {"_ButtonRenderAlpha": 0.45},
                               "Latched": {"_BorderEnabled": 1, "_BorderColor": P["PAD_LATCH"],
                                           "_BorderWidth": 0.05, "_ButtonRenderEmissive": 0.1}},
                       extra={"padColor": {"targets": [{"param": "_ButtonColor", "amount": P["PAD_TINT"]}]}})

    # ── dials (UI/SDFKnob) ──
    def dial(self, L, P, slot):
        """A capless dial: 270-degree arc (grey remainder, light value) + a needle from the centre.
        Widths are widget units (half-extent 1.0), derived from the part's real pixel size."""
        S = L.S(slot)
        half = S["px"] / 2.0
        w = S["stroke_px"] / half
        r = S["arc_outer"] - w
        base = self.common("Knob")
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
            # getNubSDF(Rectangle) takes FULL sizes, oriented so width runs along the radius: a needle
            # that JOINS the arc runs from the centre through the band to its outer edge.
            "_NubDistance": (r + w) * 0.5, "_NubSizeWidth": r + w, "_NubSizeHeight": S["needle_px"] / half,
        })
        states = {"Hover": {"_LineSublineUnfilledColor": P["ARC_OFF_HI"]},
                  "Pressed": {"_LineSublineFilledColor": P["VALUE_HI"], "_NubColor": P["VALUE_HI"]},
                  "Disabled": {"_LineSublineFilledColor": P["DIS_MARK"], "_LineSublineUnfilledColor": P["DIS_ARC"],
                               "_NubColor": P["DIS_MARK"]}}
        return slot, base, states, None

    # ── faders (UI/SDFSlider) + the switch (UI/SDFTogglePill) ──
    def fader(self, L, P, slot):
        S = L.S(slot)
        bg = P[S["bg"]] if S["bg"] else None
        base = self.common("Slider")
        base.update({
            "_Value": 0.5, "_TrackValueZeroPoint": 0.0,
            "_BgEnabled": 1 if bg else 0, "_BgColor": bg or P["FACE"], "_BgShapeType": 0,
            "_BgShapeParam1": S["corner"], "_BgPadding": S["pad"],
            "_TrackEnabled": 1, "_TrackColor": P["TRACK"], "_TrackWidth": S["track_w"],
            "_TrackValueFilledEnabled": 1, "_TrackValueFilledColor": P[S["fill"]],
            "_TrackValueUnfilledEnabled": 0,
            "_HandleEnabled": 1, "_HandleColor": P["HANDLE"], "_HandleShapeType": 2, "_HandleShapeParam1": 0.2,
            "_HandleWidth": S["handle_w"], "_HandleHeight": S["handle_h"], "_HandlePadding": 0.5,
            "_BorderEnabled": 0,
        })
        states = {"Hover": {"_HandleColor": P["HANDLE_HI"]},
                  "Pressed": {"_HandleColor": P["HANDLE_HI"], "_TrackValueFilledColor": P["VALUE_HI"]},
                  "Disabled": {"_HandleColor": P["DIS_MARK"], "_TrackValueFilledColor": P["DIS_MARK"],
                               "_TrackColor": P["DIS_ARC"]}}
        return slot, base, states, None

    def switch(self, L, P, slot):
        S = L.S(slot)
        base = self.common("Toggle")
        base.update({
            "_Value": 0.0, "_StateCount": 2,
            "_BgEnabled": 0, "_BgColor": P["INSET"], "_BgPadding": S["pad"],
            "_TrackEnabled": 1, "_TrackColor": P["TRACK"], "_TrackHeight": S["track_h"], "_TrackCornerRadius": 1.0,
            "_HandleEnabled": 1, "_HandleColor": P["HANDLE"], "_HandlePadding": 0.3, "_HandleFlatten": 0.0,
            "_HandleFaceEnabled": 0,
            # ON = the handle takes the accent. The surface blend is gated on _LedEnabled, the bloom ball
            # on _LedEnabled AND intensity — so enabled at intensity 0 recolours without a second ball.
            "_LedEnabled": 1, "_LedColor": P["ACCENT"], "_LedIntensity": 0.0, "_LedSurfaceBlend": 1.0,
            "_BorderEnabled": 0,
        })
        states = {"Hover": {"_TrackColor": P["ARC_OFF_HI"]},
                  "Disabled": {"_HandleColor": P["DIS_MARK"], "_LedSurfaceBlend": 0.0, "_TrackColor": P["DIS_ARC"]}}
        return slot, base, states, None

    # ── plates (UI/SDFPanel) ──
    def plate(self, L, P, slot):
        """Proportional pad/corner stay as the fallback (and the Designer's preview); the PX values win
        at runtime, so a plate's edge and corners are the same at every panel size."""
        S = L.S(slot)
        base = self.common("Panel")
        base.update({
            "_PanelEnabled": 1, "_PanelColor": P[S["fill"]], "_PanelRenderAlpha": 1.0, "_PanelRenderEmissive": 0.0,
            "_PanelShapeType": 0, "_PanelShapeParam1": S["corner"], "_PanelPadding": S["pad"],
            "_PanelPaddingPx": S["pad_px"], "_PanelCornerRadiusPx": S["radius_px"],
            "_BorderEnabled": 0,
        })
        return slot, base, {}, None

    def parts(self, L, P):
        yield from self.keys(L, P)
        for s in ("Knob", "KnobHero", "KnobSmall"):
            yield self.dial(L, P, s)
        yield self.fader(L, P, "Slider")
        yield self.fader(L, P, "Fader")
        yield self.switch(L, P, "Pill")
        for s in ("Face", "Inset", "Socket", "Well", "Back", "Bezel", "ScrollTrack"):
            yield self.plate(L, P, s)

    def plate_colors(self, L, P, slot):
        """(bottom, top) of a plate — what the sheet harness and the rack composite need to know."""
        c = P[L.S(slot)["fill"]]
        return c, c


TUBE_DIR = (1.0, 0.35)      # left→right with a slight rise: the tip colour lands top-right


class Neon(Unlit):
    """TRON (2026-09-14) — Flat's rules plus LIGHT TUBES on a black floor. Every tube is three layers
    the non-RM shaders already have: CORE = the Border band, emissive, a 4-stop gradient; BLOOM = the
    Edge ring with render-alpha 0 and emissive 1 (blend `One OneMinusSrcAlpha`, so a zero-alpha
    emissive pixel is pure ADDITIVE light spilling onto whatever is behind — no shadow pass); SHEEN =
    the body's bevel band, which unlit has no normal and is just a colour fading in from the outline.
    Traps: panel/toggle Edges fill INSIDE (panels need _EdgeCutInside 1, the pill has no Edge); a
    gradient on a layer beats any C# colour write to it (pads turn gradients off on bound layers);
    glyph colour is live-driven, so a lit key must be a fill a white glyph reads on; sheen bands
    crease into an X at a rectangle's medial axis — keep them short of the centre."""
    TOKENS = ("GAP BACK BACK_TOP FACE FACE_TOP INSET INSET_TOP SOCKET WELL WELL_TOP BODY BODY_TOP DIS_BODY "
              "TUBE TUBE_REST TUBE_DIS STRUCT STRUCT_HI HALO HALO_REST HALO_HOVER HALO_ON SHEEN SHEEN_ON ARC_EMIT "
              "FACE_LINE_PX FACE_HALO_PX FACE_SHEEN PLATE_SHEEN GRID LINE BLOOM MARK MARK_DIM ON_MARK DIS_MARK "
              "ACCENT ACCENT_HI ACCENT_DIS HOT SOLO LAMP PRESS ARC_OFF ARC_OFF_HI ARC ARC_GLOW ARC_GLOW_I CAP "
              "CAP_TOP CAP_RING CAP_RING_HI NEEDLE TRACK HANDLE HANDLE_HI PAD_BODY PAD_LINE PAD_LINE_TINT "
              "PAD_HALO_TINT PAD_FACE_TINT PAD_SHEEN_TINT SCROLL SCROLL_HI").split()
    SHAPE = {
        "key": dict(shape=4, cut=0.55, round=0.0, line=0.09, halo_w=0.16, sheen=0.14, icon=None, icon_size=0.42,
                    alpha=1.0),
        "Accent": dict(cut=0.5),
        "ToggleBtn": dict(icon=17, icon_size=0.55, cut=0.5, line=0.075, halo_w=0.1, sheen=0.12),
        "Solo": dict(icon=16, icon_size=0.55, cut=0.5, line=0.075, halo_w=0.1, sheen=0.12),
        "Lamp": dict(icon=29, icon_size=0.62, cut=0.5, line=0.08, halo_w=0.3, sheen=0.12),
        "Close": dict(icon=19, icon_size=0.4, alpha=0.0, sheen=0),
        "Chip": dict(cut=0.45, line=0.08, halo_w=0.12),
        "Dot": dict(shape=1, cut=0.0, line=0.06, halo_w=0.1, sheen=0),
        "ScrollHandle": dict(shape=0, cut=0.5, line=0.05, halo_w=0.1, sheen=0),
        "Pad": dict(cut=0.32, line=0.085, halo_w=0.11, sheen=0.2),
        # a HUD dial: glowing arc, dim groove, black glass cap with a thin tube round it, light-dot pointer
        "dial": dict(silhouette="capped", arc_outer=0.86, cap=0.58, ticks=0, glow_px=5.0, nub=0.08, ring_px=1.0,
                     deco=False),
        "Knob": dict(px=44, arc_px=2.5, glow_px=3.5, nub=0.09),
        "KnobHero": dict(px=96, arc_px=3.5, glow_px=5.0, nub=0.06, ticks=25, deco=True, cap=0.55),
        "KnobSmall": dict(px=36, arc_px=2.2, glow_px=3.5, nub=0.1, cap=0.56),
        "fader": dict(bg=True, track_w=0.16, handle_w=0.1, handle_h=0.85, fill="ARC", gutter=False),
        "Fader": dict(track_w=0.4, handle_w=0.3, handle_h=0.9, gutter=True, fill=("SCROLL_HI", "SCROLL_HI")),
        "switch": dict(track_h=0.85),
        # A plate is black glass: a vertical lift, then a TUBE (device plates: gradient core + bloom
        # spilling OUT into the gap, _EdgeCutInside) or a HAIRLINE (recesses). Every weight is pinned
        # in canvas units (_BorderWidthPx, _EdgeWidthPx, _PanelCornerRadiusPx pins the octagon CUT).
        "plate": dict(cut_px=8.0, pad_px=None, line_px=1.5, tube=None, struct=None, halo=0.0, halo_px=6.0,
                      sheen=0.0, sheen_col=None, grid=0.0, grid_px=300),
        "Face": dict(fill=("FACE", "FACE_TOP"), tube="TUBE_REST", line_px="FACE_LINE_PX", halo="HALO_REST",
                     halo_px="FACE_HALO_PX", cut_px=12.0, grid="GRID", sheen="FACE_SHEEN", sheen_col="PLATE_SHEEN"),
        "Inset": dict(fill=("INSET", "INSET_TOP"), struct="STRUCT", line_px=1.0, cut_px=6.0, pad_px=2.0),
        "Socket": dict(fill=("SOCKET", "SOCKET"), struct="STRUCT", line_px=1.0, cut_px=5.0, pad_px=2.0),
        "Well": dict(fill=("WELL", "WELL_TOP"), tube="TUBE_REST", line_px=1.2, halo=("HALO_REST", 0.6), halo_px=2.0,
                     cut_px=5.0, sheen=0.1),
        "Back": dict(fill=("BACK", "BACK_TOP"), cut_px=0.0, pad_px=0.0),
        "Bezel": dict(fill=("WELL", "WELL_TOP"), struct="STRUCT_HI", line_px=1.2, cut_px=5.0, pad_px=2.0),
        "ScrollTrack": dict(fill=("INSET", "INSET"), struct="STRUCT", line_px=1.0, cut_px=3.0, pad_px=1.0),
    }
    RECIPE_COLORS = dict(face="FACE", inset="INSET", backplane="BACK", well="WELL", body="BODY", bodyAlt="BODY_TOP",
                         accent="TUBE", line=("TUBE_REST", 1), hot="HOT", lamp="LAMP", mark="MARK")
    PAD_TARGETS = ("_BorderColor", "_EdgeColor", "_ButtonColor", "_ButtonBevelGradientColorA",
                   "_ButtonBevelGradientColorB")

    @staticmethod
    def val(P, v):
        """A shape value may name a palette token (mode-dependent weights) or (token, factor)."""
        if isinstance(v, str) and v in P:
            return P[v]
        if isinstance(v, tuple) and len(v) == 2 and isinstance(v[0], str) and v[0] in P \
                and isinstance(v[1], (int, float)):
            return P[v[0]] * v[1]
        return v

    def tube(self, P, st=None, width=0.09, halo_w=0.16, halo=None, halo_stops=None):
        """CORE (border band, emissive) + BLOOM (edge ring, additive). Widths in button units (short side 2)."""
        return {
            "_BorderEnabled": 1, "_BorderColor": stops(st or P["TUBE_REST"])[0],
            "_BorderWidth": width * P["LINE"], "_BorderSoftness": 0.0, "_BorderInset": 0.0, "_BorderFalloff": 0.0,
            "_BorderIntensity": 1.0, "_BorderRenderAlpha": 1.0, "_BorderRenderEmissive": 1.0,
            **grad("_Border", st or P["TUBE_REST"], TUBE_DIR),
            "_EdgeEnabled": 1, "_EdgeColor": stops(halo_stops or P["HALO"])[0],
            "_EdgeWidth": halo_w * P["BLOOM"], "_EdgeSoftness": 0.5, "_EdgeFalloff": 1.0, "_EdgeInset": 0.0,
            "_EdgeIntensity": P["HALO_REST"] if halo is None else halo,
            "_EdgeRenderAlpha": 0.0, "_EdgeRenderEmissive": 1.0,
            **grad("_Edge", halo_stops or P["HALO"], TUBE_DIR),
        }

    def key(self, L, P, slot, *, body=None, mark=None, sheen_col=None, states=None, extra=None, tube_stops=None):
        S = L.S(slot)
        base = self.common("Button")
        b = body or (P["BODY"], P["BODY_TOP"])
        sheen = S["sheen"]
        base.update({
            "_ButtonEnabled": 1, "_ButtonColor": stops(b)[0], "_ButtonRenderAlpha": S["alpha"],
            "_ButtonRenderEmissive": 0.0, "_ButtonShapeType": S["shape"], "_ButtonShapeParam1": S["cut"],
            "_ButtonPadding": S["pad"], "_ButtonRoundness": S["round"],
            **grad("_Button", b, (0.0, 1.0)),
            # SHEEN: the tube's light caught on the glass, fading in from the outline
            "_ButtonBevelEnabled": 1 if sheen else 0, "_ButtonBevelDepth": 0.0,
            "_ButtonBevelDistance": sheen or 0.3, "_ButtonBevelSmoothness": sheen or 0.3,
            **grad("_ButtonBevel", (sheen_col or P["SHEEN"],) * 2, (0.0, 1.0)),
            **self.tube(P, st=tube_stops, width=S["line"], halo_w=min(S["halo_w"], S["pad"] * 0.9)),
            "_IconEnabled": 1 if S["icon"] is not None else 0,
        })
        if S["icon"] is not None:
            base.update({"_IconShapeType": S["icon"], "_IconColor": mark or P["MARK"], "_IconWidth": S["icon_size"],
                         "_IconHeight": S["icon_size"], "_IconRenderAlpha": 1.0, "_IconRenderEmissive": 0.35})
        return slot, base, states or {}, extra

    @staticmethod
    def lit(P, fill, *, mark=None, halo=None, sheen=None, tube_stops=None):
        """A key lit from inside: body fills with the colour, mark goes dark, bloom opens right up."""
        d = {**gcol("_Button", fill), "_EdgeIntensity": P["HALO_ON"] if halo is None else halo,
             **gcol("_ButtonBevel", (sheen or P["SHEEN_ON"],) * 2), **gcol("_Border", tube_stops or P["TUBE"])}
        if mark is not False:
            d["_IconColor"] = mark or P["ON_MARK"]
        return d

    def keys(self, L, P):
        lit = self.lit
        hover = {**gcol("_Border", P["TUBE"]), "_EdgeIntensity": P["HALO_HOVER"], "_IconColor": P["MARK"]}
        dis = {**gcol("_Button", (P["DIS_BODY"],) * 2), **gcol("_Border", P["TUBE_DIS"]), "_EdgeIntensity": 0.0,
               "_ButtonBevelEnabled": 0, "_IconColor": P["DIS_MARK"]}
        std = {"Hover": hover, "Pressed": lit(P, P["PRESS"]), "Disabled": dis}
        yield self.key(L, P, "Button", states=std)
        # Accent keys are LIT at rest, so their sheen is the lit sheen.
        yield self.key(L, P, "Accent", body=P["ACCENT"], tube_stops=P["TUBE"], sheen_col=P["ACCENT_HI"][0],
                       states={"Hover": {**gcol("_Button", P["ACCENT_HI"]), "_EdgeIntensity": P["HALO_ON"]},
                               "Pressed": {**gcol("_Button", P["ACCENT"]), "_EdgeIntensity": P["HALO_ON"] * 1.3},
                               "Disabled": {**gcol("_Button", P["ACCENT_DIS"]), **gcol("_Border", P["TUBE_DIS"]),
                                            "_EdgeIntensity": 0.0}})
        latch = dict(std, Hover=dict(hover))
        for slot, on in (("ToggleBtn", "HOT"), ("Solo", "SOLO"), ("Lamp", "LAMP")):
            yield self.key(L, P, slot, mark=P["MARK_DIM"], states=dict(latch, Active=lit(P, P[on])))
        yield self.key(L, P, "Close", mark=P["MARK_DIM"],
                       states={"Hover": {"_ButtonRenderAlpha": 1.0, "_IconColor": P["HOT"][0],
                                         **gcol("_Border", P["TUBE"]), "_EdgeIntensity": P["HALO_HOVER"]},
                               "Pressed": lit(P, P["HOT"]), "Disabled": {"_IconColor": P["DIS_MARK"]}})
        yield self.key(L, P, "Chip", states=std)
        yield self.key(L, P, "Dot", body=(P["SCROLL"], P["SCROLL_HI"]),
                       states={"Hover": {"_EdgeIntensity": P["HALO_HOVER"]},
                               "Pressed": lit(P, P["ACCENT"], mark=False)})
        yield self.key(L, P, "ScrollHandle", body=(P["SCROLL"], P["SCROLL_HI"]),
                       states={"Hover": {**gcol("_Border", P["TUBE"]), "_EdgeIntensity": P["HALO_HOVER"]},
                               "Pressed": lit(P, P["ACCENT"], mark=False),
                               "Disabled": {"_ButtonRenderAlpha": 0.4, "_EdgeIntensity": 0.0}})
        # PADS wear their row. The row colour drives the tube CORE (mostly), the BLOOM (fully), a breath
        # of the glass and the sheen — a neon outline in its row's colour; a hit fills the glass with it.
        # Bound colours are live-driven, so feedback is FLOATS only.
        slot, base, states, extra = self.key(
            L, P, "Pad", body=(P["PAD_BODY"],),
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
        # a bound colour must not be overridden by a gradient on the same layer
        for layer in ("_Border", "_Edge", "_Button"):
            base[f"{layer}GradientEnabled"] = 0
        base["_BorderColor"] = P["PAD_LINE"]
        base["_EdgeColor"] = P["HALO"][0]
        yield slot, base, states, extra

    def dial(self, L, P, slot):
        S = L.S(slot)
        half = S["px"] / 2.0
        u = 1.0 / half
        w = S["arc_px"] * u
        r = S["arc_outer"] - w
        cap = S["cap"]
        base = self.common("Knob")
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
            "_LineSublineGlowSoftness": S["glow_px"] * u, "_LineSublineGlowIntensity": P["ARC_GLOW_I"],
            "_LineSublineGlowRenderAlpha": 0.0, "_LineSublineGlowRenderEmissive": 1.0,
            "_KnobEnabled": 1, "_KnobColor": P["CAP"], "_KnobShapeType": 0, "_KnobSize": cap,
            "_KnobRenderAlpha": 1.0, "_KnobRenderEmissive": 0.0,
            **grad("_Knob", (P["CAP"], P["CAP_TOP"]), (0.0, 1.0)),
            "_KnobNubEnabled": 1, "_KnobNubShapeType": 0, "_KnobNubColor": P["NEEDLE"], "_KnobNubSize": S["nub"],
            "_KnobNubDistance": 0.68, "_KnobNubRenderAlpha": 1.0,
            # the cap's tube
            "_OuterRing2Enabled": 1, "_OuterRing2Style": 0, "_OuterRing2Radius": cap + S["ring_px"] * u * 0.5 / r,
            "_OuterRing2Thickness": S["ring_px"] * u * P["LINE"] / r, "_OuterRing2Color": P["CAP_RING"],
            "_OuterRing2AngleStart": 0, "_OuterRing2AngleRange": 360,
            "_OuterRing2RenderAlpha": 1.0, "_OuterRing2RenderEmissive": 0.8,
        })
        if S["ticks"]:
            base.update({
                "_OuterMarksEnabled": 1, "_OuterMarksType": 0, "_OuterMarksCount": S["ticks"],
                "_OuterMarksAngleStart": 315, "_OuterMarksAngleRange": 270, "_OuterMarksRadius": 0.8,
                "_OuterMarksLength": 0.05, "_OuterMarksThickness": 0.012,
                "_OuterMarksColorUnfilled": P["ARC_OFF_HI"], "_OuterMarksColorFilled": P["ARC"][1],
                "_OuterMarksMajorEnabled": 1, "_OuterMarksMajorInterval": 4,
                "_OuterMarksMajorLengthMultiplier": 1.8, "_OuterMarksMajorThicknessMultiplier": 1.2,
                "_OuterMarksMajorColorUnfilled": P["STRUCT_HI"], "_OuterMarksMajorColorFilled": P["NEEDLE"],
                "_OuterMarksRenderEmissive": 0.6,
            })
        if S["deco"]:
            # two short bracket arcs outside the value arc — the instrument-cluster read
            for n, start in ((1, 20), (3, 110)):
                base.update({
                    f"_OuterRing{n}Enabled": 1, f"_OuterRing{n}Style": 0, f"_OuterRing{n}Radius": 1.07,
                    f"_OuterRing{n}Thickness": 0.012, f"_OuterRing{n}Color": P["STRUCT_HI"],
                    f"_OuterRing{n}AngleStart": start, f"_OuterRing{n}AngleRange": 50,
                    f"_OuterRing{n}RenderAlpha": 1.0, f"_OuterRing{n}RenderEmissive": 0.5,
                })
        states = {"Hover": {"_OuterRing2Color": P["CAP_RING_HI"], "_LineSublineGlowIntensity": P["ARC_GLOW_I"] * 1.5,
                            "_LineSublineUnfilledColor": P["ARC_OFF_HI"]},
                  "Pressed": {"_LineSublineGlowIntensity": P["ARC_GLOW_I"] * 2.0,
                              "_LineSublineFilledRenderEmissive": 1.0, "_OuterRing2Color": P["CAP_RING_HI"]},
                  "Disabled": {**gcol("_LineSublineFilled", (P["DIS_MARK"],) * 2), "_LineSublineGlowIntensity": 0.0,
                               "_LineSublineFilledRenderEmissive": 0.0, "_OuterRing2Color": P["TUBE_DIS"][0],
                               "_KnobNubColor": P["DIS_MARK"], "_LineSublineUnfilledColor": P["TUBE_DIS"][0]}}
        return slot, base, states, None

    def fader(self, L, P, slot):
        S = L.S(slot)
        gutter = S["gutter"]
        fill = stops([P[t] for t in S["fill"]] if isinstance(S["fill"], tuple) else P[S["fill"]])
        base = self.common("Slider")
        base.update({
            "_Value": 0.5, "_TrackValueZeroPoint": 0.0,
            "_BgEnabled": 1 if S["bg"] else 0, "_BgColor": P["INSET"], "_BgShapeType": 0 if gutter else 4,
            "_BgShapeParam1": 1.0 if gutter else 0.5, "_BgPadding": S["pad"],
            **grad("_Bg", (P["INSET"], P["INSET_TOP"]), (0.0, 1.0)),
            "_BorderEnabled": 0 if gutter else 1, "_BorderColor": P["STRUCT"], "_BorderWidth": 0.05 * P["LINE"],
            "_BorderRenderAlpha": 1.0, "_BorderRenderEmissive": 0.6,
            "_TrackEnabled": 1, "_TrackColor": P["TRACK"], "_TrackWidth": S["track_w"],
            "_TrackValueFilledEnabled": 1, "_TrackValueFilledColor": fill[0],
            "_TrackValueFilledRenderEmissive": P["ARC_EMIT"],
            **grad("_TrackValueFilled", fill, (1.0, 0.0)),
            "_TrackValueUnfilledEnabled": 0,
            "_HandleEnabled": 1, "_HandleColor": P["HANDLE"], "_HandleShapeType": 2, "_HandleShapeParam1": 0.2,
            "_HandleWidth": S["handle_w"], "_HandleHeight": S["handle_h"], "_HandlePadding": 0.5,
            "_HandleRenderEmissive": 0.5,
        })
        states = {"Hover": {"_HandleColor": P["HANDLE_HI"], "_BorderColor": P["STRUCT_HI"]},
                  "Pressed": {"_HandleColor": P["HANDLE_HI"], "_TrackValueFilledRenderEmissive": 1.0,
                              "_BorderColor": P["STRUCT_HI"]},
                  "Disabled": {"_HandleColor": P["DIS_MARK"], **gcol("_TrackValueFilled", (P["DIS_MARK"],) * 2),
                               "_TrackValueFilledRenderEmissive": 0.0, "_TrackColor": P["DIS_BODY"],
                               "_BorderColor": P["TUBE_DIS"][0]}}
        return slot, base, states, None

    def switch(self, L, P, slot):
        S = L.S(slot)
        base = self.common("Toggle")
        base.update({
            "_Value": 0.0, "_StateCount": 2,
            "_BgEnabled": 0, "_BgColor": P["INSET"], "_BgPadding": S["pad"],
            "_TrackEnabled": 1, "_TrackColor": P["BODY"], "_TrackHeight": S["track_h"], "_TrackCornerRadius": 1.0,
            "_HandleEnabled": 1, "_HandleColor": P["ARC_OFF_HI"], "_HandlePadding": 0.3, "_HandleFlatten": 0.0,
            "_HandleFaceEnabled": 0, "_HandleRenderEmissive": 0.2,
            "_LedEnabled": 1, "_LedColor": P["LAMP"][0], "_LedIntensity": 0.0, "_LedSurfaceBlend": 1.0,
            "_BorderEnabled": 1, "_BorderColor": P["TUBE_REST"][1], "_BorderWidth": 0.06 * P["LINE"],
            "_BorderRenderAlpha": 1.0, "_BorderRenderEmissive": 1.0,
            # the pill's Edge fills INSIDE (no cut) — so no bloom here, by design
            "_EdgeEnabled": 0, "_EdgeColor": P["HALO"][0], "_EdgeWidth": 0.12 * P["BLOOM"], "_EdgeSoftness": 0.5,
            "_EdgeIntensity": P["HALO_REST"], "_EdgeRenderAlpha": 0.0, "_EdgeRenderEmissive": 1.0,
        })
        states = {"Hover": {"_BorderColor": P["TUBE"][1], "_EdgeIntensity": P["HALO_HOVER"]},
                  "Disabled": {"_HandleColor": P["DIS_MARK"], "_LedSurfaceBlend": 0.0,
                               "_BorderColor": P["TUBE_DIS"][0], "_EdgeIntensity": 0.0}}
        return slot, base, states, None

    def plate(self, L, P, slot):
        S = L.S(slot)
        v = lambda k: self.val(P, S[k])          # noqa: E731
        fill = tuple(P[t] for t in S["fill"])
        tube_stops = P[S["tube"]] if S["tube"] else None
        struct = P[S["struct"]] if S["struct"] else None
        lw, halo, sheen, grid = v("line_px"), v("halo"), v("sheen"), v("grid")
        hw = v("halo_px") if halo else 0.0
        pad_px = S["pad_px"]
        if pad_px is None:
            # the bloom ends exactly at the quad edge (graded to zero), so it never shows a cut
            pad_px = lw + hw + 0.5
        cut_px = S["cut_px"]
        base = self.common("Panel")
        base.update({
            "_PanelEnabled": 1, "_PanelColor": fill[0], "_PanelRenderAlpha": 1.0, "_PanelRenderEmissive": 0.0,
            "_PanelShapeType": 4, "_PanelShapeParam1": 0.06 if cut_px else 0.0, "_PanelPadding": 0.02,
            "_PanelPaddingPx": pad_px, "_PanelCornerRadiusPx": cut_px,
            **grad("_Panel", fill, (0.0, 1.0)),
            "_BorderEnabled": 1 if (tube_stops or struct) else 0,
            "_BorderColor": struct or stops(tube_stops or P["TUBE_REST"])[0],
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
            col = P[S["sheen_col"]] if S["sheen_col"] else P["SHEEN"]
            base.update({"_PanelBevelEnabled": 1, "_PanelBevelDepth": 0.0, "_PanelBevelDistance": sheen,
                         "_PanelBevelSmoothness": sheen, **grad("_PanelBevel", (col,) * 2, (0, 1))})
        if grid:
            # HexGrid, pixel-locked: 40-unit cells at any panel size
            base.update({"_PanelPatternEnabled": 1, "_PanelPatternType": 13,
                         "_PanelPatternScale": round(S["grid_px"] / 40.0, 1),
                         "_PanelPatternIntensity": grid, "_PanelPatternParam1": 0.05, "_PanelPatternParam2": 0.35,
                         "_PanelPatternPx": S["grid_px"]})
        return slot, base, {}, None

    def plate_colors(self, L, P, slot):
        f = L.S(slot)["fill"]
        return P[f[0]], P[f[1]]


class Lit(Unlit):
    """LIT — the raymarched UI/*RM shaders under the look's lamp rig. The vocabulary is the shipped
    Realistic*, NeoDark*/NeoLight* and RackFaceplate* skins, with every fix the skill records baked in:
      * keys: a flat face with a milled chamfer (bevel ~0.1–0.2 = machined; 0.3+ = a sphere) and a
        subtle DOME (_ButtonFaceSmoothness 0.12–0.45), which is what turns a constant Blinn-Phong term
        into a moving highlight; high _ButtonRoundness keeps the bevel band off the medial axis;
        _ButtonLipHeight 0 (an unset lip is 0.08 and draws the dotted seam).
      * knobs: a capped dial — skirt silhouette (KnobShapeType: Circle, Fluted, Knurled-by-pattern,
        Gear, Skirted…), a domed cap (circles have no medial axis: dome freely), bevel well inside the
        cap radius, lip 0, a DOT indicator (KnobNub shapes can't draw a thin line), the value arc with
        a visible base line and NO line emissive, _LightingShadow1-3 off and the cap seated by ONE
        faint _KnobShadow1 with cast 0.
      * plates: no dome, no bevel on Face/Back (the silhouette + drop shadow read as a panel; a plate
        bevel is a chrome bar waiting to happen), insets recessed with a rim at low depth, material
        from a top-lit GRADIENT (A = bottom, B = top) plus a faint, PIXEL-LOCKED pattern.
      * ONE shadow contract (colour, blur, cast) on every control's Shadow1, so parts sit at one height.
      * light mode changes the chassis (plates), not the controls."""
    rm = True
    TOKENS = ("GAP BACK FACE INSET SOCKET WELL BODY BODY_HI BODY_LO DIS_BODY MARK MARK_DIM DIS_MARK ON_MARK "
              "ACCENT ACCENT_HI ACCENT_LO ACCENT_DIS HOT SOLO LAMP LAMP_OFF CAP SKIRT NUB ARC_OFF VALUE VALUE_EM "
              "TRACK HANDLE PAD_BODY PAD_TINT SCROLL SCROLL_HI SHADOW SHADOW_A AMB AMB_PLATE AMB_ACCENT "
              "PLATE_LO PLATE_HI WELL_EM").split()
    SHAPE = {
        "key": dict(shape=0, corner=0.5, round=0.35, bevel=0.16, depth=0.5, smooth=0.5, dome=0.3, rim=0.0,
                    icon=None, icon_size=0.5, alpha=1.0, sunk=0.15),
        "ToggleBtn": dict(icon=17, icon_size=0.55), "Solo": dict(icon=16, icon_size=0.55),
        "Lamp": dict(icon=29, icon_size=0.62, corner=0.9, round=0.9), "Close": dict(icon=19, icon_size=0.42),
        "Dot": dict(corner=0.02, round=0.9), "ScrollHandle": dict(corner=0.5, round=0.45, bevel=0.3, dome=0.2),
        "Pad": dict(corner=0.5, round=0.45, bevel=0.22, depth=0.08, smooth=1.0, dome=0.15, sunk=0.1),
        "dial": dict(silhouette="cap", arc_outer=0.86, arc_px=3.0, rounded=True, skirt="Circle", skirt_count=6,
                     skirt_depth=0.15, cap_r=0.62, bevel=0.2, depth=0.35, smooth=1.0, dome=0.35,
                     nub=0.075, nub_dist=0.62, ticks=0),
        "Knob": dict(px=56), "KnobHero": dict(px=112, ticks=11, arc_px=4.0), "KnobSmall": dict(px=48, arc_px=2.6),
        "fader": dict(track_w=0.16, handle="cap", handle_w=0.28, handle_h=0.9, bevel=0.12, depth=0.5, dome=0.3,
                      corner=0.6),
        "Fader": dict(track_w=0.4, handle_w=0.3, handle_h=0.9, bevel=0.0, dome=0.0),
        "switch": dict(track_h=0.7),
        "plate": dict(radius_px=4.0, pad_px=2.0, corner=0.9, pad=0.01, recess=None, rim_w=0.03, screws=False),
        "Face": dict(fill="FACE", screws=False), "Back": dict(fill="BACK", radius_px=1.0, pad_px=0.0),
        "Inset": dict(fill="INSET", recess=-0.3), "Socket": dict(fill="SOCKET", recess=-0.3),
        "Well": dict(fill="WELL", recess=-0.3, radius_px=3.0, pad_px=3.0),
        "Bezel": dict(fill="INSET", recess=-0.2, radius_px=3.0, pad_px=3.0),
        "ScrollTrack": dict(fill="INSET", recess=-0.2, corner=1.0, radius_px=0.0, pad_px=1.0),
    }
    # Pattern = (type, scale, Px, intensity, contrast, spec, rough, p1, p2, p3). The plate default is
    # the 2026-10-04 realism pass's enamel; "Metal" plates want p1 0.5 (else mottled noise).
    MATERIAL = {
        "plate": dict(pattern="Plastic", scale=60, px=100, intensity=0.06, contrast=1.0, spec=0.3, rough=0.5,
                      p1=0.7, p2=0.0, p3=0.15),
        "key": dict(pattern="Plastic", scale=14, intensity=0.05, contrast=1.0, spec=0.3, rough=0.6),
        "cap": dict(pattern="RadialBrushed", scale=11, intensity=0.15, p1=0.45, p2=0.2),
        "skirt": dict(pattern=None),
        "handle": dict(pattern=None),
    }
    RECIPE_COLORS = dict(face="FACE", inset="INSET", backplane="BACK", well="WELL", body="BODY", bodyAlt="BODY_LO",
                         accent="ACCENT", line="ARC_OFF", hot="HOT", lamp="LAMP", mark="MARK")

    def common(self, family, P=None, amb=None):
        p = props(stem(family, True))
        d = {k: 0 for k in guards(family, True)}
        d["_LightingUnlit"] = 0
        d["_LightingAmbient"] = amb if amb is not None else P["AMB"]
        d["_ReceiveSceneShadows"] = 0 if "_ReceiveSceneShadows" in p else None
        if d["_ReceiveSceneShadows"] is None:
            del d["_ReceiveSceneShadows"]
        if "_ViewTilt" in p:
            # no view tilt / scene-camera lean: it projected pads out of their cells
            d.update({"_ViewTilt": 0.0, "_ViewCamEnabled": 0})
        return d

    def shadow(self, L, P, layer, *, cast=None, blur=None, a=None):
        """THE shadow contract: one colour/blur/cast for the whole set (`shape.shadow` overrides)."""
        sh = dict(dict(blur=1.6, cast=0.25, intensity=1.0), **L.shape.get("shadow", {}))
        return {f"{layer}Shadow1Enabled": 1,
                f"{layer}Shadow1Color": alpha(P["SHADOW"], P["SHADOW_A"] if a is None else a),
                f"{layer}Shadow1Blur": sh["blur"] if blur is None else blur,
                f"{layer}Shadow1Cast": sh["cast"] if cast is None else cast,
                f"{layer}Shadow1Intensity": sh["intensity"], f"{layer}Shadow1Distance": 0.0}

    def pattern(self, L, P, layer, which, slot=None):
        mat = P["MATERIAL"]
        m = dict(self.MATERIAL[which], **mat.get(which, {}), **(mat.get(slot, {}) if slot else {}))
        if not m.get("pattern"):
            return {f"{layer}PatternEnabled": 0}
        d = {f"{layer}PatternEnabled": 1, f"{layer}PatternType": PATTERNS[m["pattern"]],
             f"{layer}PatternScale": m.get("scale", 20), f"{layer}PatternIntensity": m.get("intensity", 0.05)}
        for k, prop in (("contrast", "Contrast"), ("spec", "SpecularEffect"), ("rough", "RoughnessEffect"),
                        ("p1", "Param1"), ("p2", "Param2"), ("p3", "Param3"), ("px", "Px")):
            if k in m:
                d[f"{layer}Pattern{prop}"] = m[k]
        return d

    # ── keys (UI/SDFButtonRM) ──
    def key(self, L, P, slot, *, fill, mark=None, states=None, extra=None, amb=None):
        S = L.S(slot)
        base = self.common("Button", P, amb)
        base.update({
            "_ButtonEnabled": 1, "_ButtonColor": fill, "_ButtonRenderAlpha": S["alpha"], "_ButtonRenderEmissive": 0.0,
            "_ButtonShapeType": S["shape"], "_ButtonShapeParam1": S["corner"], "_ButtonPadding": S["pad"],
            "_ButtonRoundness": S["round"], "_ButtonLipHeight": 0.0,
            "_ButtonBevelEnabled": 1 if S["bevel"] else 0, "_ButtonBevelDistance": S["bevel"] or 0.1,
            "_ButtonBevelDepth": S["depth"], "_ButtonBevelSmoothness": S["smooth"], "_ButtonFaceSmoothness": S["dome"],
            **self.pattern(L, P, "_Button", "key", slot),
            **self.shadow(L, P, "_Button"),
            "_BorderEnabled": 0, "_EdgeEnabled": 0,
            "_IconEnabled": 1 if S["icon"] is not None else 0,
        })
        if S["rim"]:
            base.update({"_ButtonRimEnabled": 1, "_ButtonRimDepth": S["rim"], "_ButtonRimWidth": 0.02})
        if S["icon"] is not None:
            base.update({"_IconShapeType": S["icon"], "_IconColor": mark or P["MARK"], "_IconWidth": S["icon_size"],
                         "_IconHeight": S["icon_size"], "_IconRenderAlpha": 1.0, "_IconRenderEmissive": 0.0})
        return slot, base, states or {}, extra

    def keys(self, L, P):
        def sunk(slot, **kw):
            S = L.S(slot)
            return dict({"_ButtonBevelDepth": -S["sunk"], "_ButtonFaceSmoothness": 0.0,
                         "_ButtonShadow1Intensity": 0.3}, **kw)
        dis = {"_ButtonColor": P["DIS_BODY"], "_ButtonBevelDepth": L.S("Button")["depth"] * 0.4,
               "_IconColor": P["DIS_MARK"], "_ButtonShadow1Intensity": 0.5}

        def std(slot):
            return {"Hover": {"_ButtonColor": P["BODY_HI"]},
                    "Pressed": sunk(slot, _ButtonColor=P["BODY_LO"]), "Disabled": dict(dis)}
        yield self.key(L, P, "Button", fill=P["BODY"], states=std("Button"))
        yield self.key(L, P, "Accent", fill=P["ACCENT"], mark=P["ON_MARK"], amb=P["AMB_ACCENT"],
                       states={"Hover": {"_ButtonColor": P["ACCENT_HI"]},
                               "Pressed": sunk("Accent", _ButtonColor=P["ACCENT_LO"]),
                               "Disabled": {"_ButtonColor": P["ACCENT_DIS"], "_ButtonShadow1Intensity": 0.5}})
        # A latch: ON is pressed IN, filled with its meaning, and the mark glows — shape AND colour.
        for slot, on in (("ToggleBtn", "ACCENT"), ("Solo", "SOLO"), ("Lamp", "LAMP")):
            mark = P["LAMP_OFF"] if slot == "Lamp" else P["MARK_DIM"]
            yield self.key(L, P, slot, fill=P["BODY"], mark=mark,
                           states=dict(std(slot), Hover={"_ButtonColor": P["BODY_HI"], "_IconColor": P["MARK"]},
                                       Active=sunk(slot, _ButtonColor=P[on], _IconColor=P["ON_MARK"],
                                                   _ButtonRenderEmissive=0.25, _IconRenderEmissive=0.6)))
        yield self.key(L, P, "Close", fill=P["BODY"], mark=P["MARK_DIM"],
                       states={"Hover": {"_ButtonColor": P["BODY_HI"], "_IconColor": P["HOT"]},
                               "Pressed": sunk("Close", _ButtonColor=P["BODY_LO"], _IconColor=P["HOT"]),
                               "Disabled": dict(dis)})
        yield self.key(L, P, "Chip", fill=P["BODY"], states=std("Chip"))
        yield self.key(L, P, "Dot", fill=P["SCROLL"],
                       states={"Hover": {"_ButtonColor": P["SCROLL_HI"]},
                               "Pressed": sunk("Dot", _ButtonColor=P["ACCENT"]), "Disabled": dict(dis)})
        yield self.key(L, P, "ScrollHandle", fill=P["SCROLL"],
                       states={"Hover": {"_ButtonColor": P["SCROLL_HI"]},
                               "Pressed": {"_ButtonColor": P["ACCENT"]},
                               "Disabled": {"_ButtonRenderAlpha": 0.4}})
        # PD-48 pads: untilted, soft squircle, wide shallow smooth bevel, row colour tinted onto the body.
        slot, base, states, extra = self.key(
            L, P, "Pad", fill=P["PAD_BODY"],
            states={"Hover": {"_ButtonRenderEmissive": 0.06},
                    "Pressed": sunk("Pad", _ButtonRenderEmissive=0.35),
                    "Disabled": {"_ButtonRenderAlpha": 0.45, "_ButtonShadow1Intensity": 0.4},
                    "Latched": {"_ButtonRenderEmissive": 0.25, "_ButtonBevelDepth": -0.05}},
            extra={"padColor": {"targets": [{"param": "_ButtonColor", "amount": P["PAD_TINT"]}]}})
        base.update(self.shadow(L, P, "_Button", cast=0.0, blur=1.2))
        yield slot, base, states, extra

    # ── dials (UI/SDFKnobRM) ──
    def dial(self, L, P, slot):
        S = L.S(slot)
        half = S["px"] / 2.0
        w = S["arc_px"] / half
        r = S["arc_outer"] - w
        knob_size = S["cap_r"] / r           # the cap's radius is _LineRadius × _KnobSize
        skirt = KNOB_SHAPES[S["skirt"]] if isinstance(S["skirt"], str) else S["skirt"]
        base = self.common("Knob", P)
        base.update({
            "_AngleStart": 315, "_AngleRange": 270, "_Value": 0.5,
            # _LightingShadow1 defaults ON in SDFKnob/SDFKnobRM: off (all three, via the guards) —
            # the cap is seated by one faint soft shadow with no cast instead.
            "_LightingShadow1Enabled": 0, "_LightingShadow2Enabled": 0, "_LightingShadow3Enabled": 0,
            **self.shadow(L, P, "_Knob", cast=0.0),
            "_FillEnabled": 0, "_BorderEnabled": 0, "_EdgeEnabled": 0, "_NubEnabled": 0,
            # the value arc: a VISIBLE base line under it (alpha 0 let the plate show through as a dark
            # edge) with NO emissive (added after the arcs composite; washes the arc out)
            "_LineEnabled": 1, "_LineRadius": r, "_LineWidth": w, "_LineColor": P["ARC_OFF"],
            "_LineRenderAlpha": 1.0, "_LineRenderEmissive": 0.0, "_LineRoundedEnabled": 1 if S["rounded"] else 0,
            "_LineSublineUnfilledEnabled": 1, "_LineSublineUnfilledColor": P["ARC_OFF"],
            "_LineSublineUnfilledRenderEmissive": 0.0,
            "_LineSublineFilledEnabled": 1, "_LineSublineFilledColor": P["VALUE"],
            "_LineSublineFilledRenderEmissive": P["VALUE_EM"],
            "_KnobEnabled": 1, "_KnobColor": P["CAP"], "_KnobShapeType": skirt, "_KnobSize": knob_size,
            "_KnobShapeScale": S["skirt_count"], "_KnobShapeParam1": S["skirt_depth"],
            # lip 0 (+ the SDFKnobRM no-lip fix) removes the dotted ring; bevel well inside the cap
            "_KnobLipHeight": 0.0,
            "_KnobBevelEnabled": 1, "_KnobBevelDistance": S["bevel"], "_KnobBevelDepth": S["depth"],
            "_KnobBevelSmoothness": S["smooth"], "_KnobFaceSmoothness": S["dome"],
            **self.pattern(L, P, "_Knob", "cap", slot),
            **self.pattern(L, P, "_KnobBevel", "skirt", slot),
            "_KnobNubEnabled": 1, "_KnobNubShapeType": 0, "_KnobNubColor": P["NUB"], "_KnobNubSize": S["nub"],
            "_KnobNubDistance": S["nub_dist"],
        })
        if S["ticks"]:
            base.update({
                "_OuterMarksEnabled": 1, "_OuterMarksType": 0, "_OuterMarksCount": S["ticks"],
                "_OuterMarksAngleStart": 315, "_OuterMarksAngleRange": 270, "_OuterMarksRadius": r + w + 0.02,
                "_OuterMarksLength": 0.05, "_OuterMarksThickness": 0.014,
                # layers have their own colour pairs: unset, these default to green/white confetti
                "_OuterMarksColorUnfilled": P["MARK_DIM"], "_OuterMarksColorFilled": P["VALUE"],
                "_OuterMarksMajorEnabled": 0, "_OuterMarksMajorColorUnfilled": P["MARK_DIM"],
                "_OuterMarksMajorColorFilled": P["VALUE"], "_OuterMarksRenderEmissive": 0.0,
            })
        states = {"Hover": {"_KnobColor": P["BODY_HI"] if P["CAP"] == P["BODY"] else mix(P["CAP"], "#FFFFFF", 0.06)},
                  "Pressed": {"_KnobBevelDepth": S["depth"] * 0.6},
                  "Disabled": {"_KnobNubColor": P["DIS_MARK"], "_LineSublineFilledColor": P["DIS_MARK"],
                               "_LineSublineFilledRenderEmissive": 0.0, "_KnobShadow1Intensity": 0.5}}
        return slot, base, states, None

    # ── faders (UI/SDFSliderRM) + the switch (UI/SDFTogglePill) ──
    def fader(self, L, P, slot):
        S = L.S(slot)
        gutter = slot == "Fader"
        base = self.common("Slider", P)
        base.update({
            "_Value": 0.5, "_TrackValueZeroPoint": 0.0, "_HandleLipHeight": 0.0,
            "_BgEnabled": 1 if gutter else 0, "_BgColor": P["BACK"], "_BgShapeType": 0,
            "_BgShapeParam1": 1.0, "_BgPadding": S["pad"],
            "_TrackEnabled": 1, "_TrackColor": P["TRACK"], "_TrackWidth": S["track_w"],
            "_TrackValueFilledEnabled": 1, "_TrackValueFilledColor": P["SCROLL_HI"] if gutter else P["VALUE"],
            "_TrackValueFilledRenderEmissive": 0.0 if gutter else P["VALUE_EM"],
            "_TrackValueUnfilledEnabled": 0,
            "_HandleEnabled": 1, "_HandleColor": P["HANDLE"], "_HandleShapeType": 0,
            "_HandleShapeParam1": S["corner"], "_HandleWidth": S["handle_w"], "_HandleHeight": S["handle_h"],
            "_HandlePadding": 0.5,
            "_HandleBevelEnabled": 1 if S["bevel"] else 0, "_HandleBevelDistance": S["bevel"] or 0.1,
            "_HandleBevelDepth": S["depth"], "_HandleBevelSmoothness": 0.5, "_HandleFaceSmoothness": S["dome"],
            **self.pattern(L, P, "_Handle", "handle", slot),
            **({} if gutter else self.shadow(L, P, "_Handle")),
            "_BorderEnabled": 0, "_EdgeEnabled": 0,
        })
        states = {"Hover": {"_HandleColor": P["BODY_HI"]},
                  "Pressed": {"_HandleColor": P["BODY_LO"]},
                  "Disabled": {"_HandleColor": P["DIS_BODY"], "_TrackValueFilledColor": P["DIS_MARK"],
                               "_TrackValueFilledRenderEmissive": 0.0}}
        return slot, base, states, None

    def switch(self, L, P, slot):
        S = L.S(slot)
        base = self.common("Toggle", P)
        base.update({
            "_Value": 0.0, "_StateCount": 2,
            "_BgEnabled": 0, "_BgColor": P["INSET"], "_BgPadding": S["pad"],
            "_TrackEnabled": 1, "_TrackColor": P["TRACK"], "_TrackHeight": S["track_h"], "_TrackCornerRadius": 1.0,
            "_HandleEnabled": 1, "_HandleColor": P["HANDLE"], "_HandlePadding": 0.26, "_HandleFaceEnabled": 0,
            "_HandleBevelEnabled": 1, "_HandleBevelDistance": 0.3, "_HandleBevelDepth": 0.4,
            "_HandleBevelSmoothness": 0.8, "_HandleFaceSmoothness": 0.3,
            # ON = the handle takes the accent (LED on at intensity 0: a recolour, no bloom ball)
            "_LedEnabled": 1, "_LedColor": P["ACCENT"], "_LedIntensity": 0.0, "_LedSurfaceBlend": 1.0,
            # no cast shadow: SDFTogglePill's shadow pass (_ShadowPassMode 1) redraws the whole pill at
            # the 2x quad size (RealisticPill does it too, in slrender) — the guards keep it off
            "_BorderEnabled": 0, "_EdgeEnabled": 0,
        })
        states = {"Hover": {"_HandleColor": P["BODY_HI"]}, "Pressed": {"_HandleColor": P["BODY_LO"]},
                  "Disabled": {"_HandleColor": P["DIS_BODY"], "_LedSurfaceBlend": 0.0}}
        return slot, base, states, None

    # ── plates (UI/SDFPanel) ──
    def plate(self, L, P, slot):
        S = L.S(slot)
        c = P[S["fill"]]
        lo, hi = self.plate_colors(L, P, slot)
        base = self.common("Panel", P, P["AMB_PLATE"])
        base.update({
            "_PanelEnabled": 1, "_PanelColor": c, "_PanelRenderAlpha": 1.0,
            "_PanelRenderEmissive": P["WELL_EM"] if slot == "Well" else 0.0,
            "_PanelShapeType": 0, "_PanelShapeParam1": S["corner"], "_PanelPadding": S["pad"],
            "_PanelPaddingPx": S["pad_px"], "_PanelCornerRadiusPx": S["radius_px"],
            # medial-axis rule: never dome a rectangle; material is read from the GRADIENT instead
            "_PanelFaceSmoothness": 0.0,
            **grad("_Panel", (lo, hi), (0.0, 1.0)),
            **(self.pattern(L, P, "_Panel", "plate", slot) if slot not in ("Well", "ScrollTrack") else {}),
            "_BorderEnabled": 0, "_EdgeEnabled": 0,
        })
        if S["recess"]:
            # a recessed dish reads as a dish only if its wall catches light — a RIM, low depth
            base.update({"_PanelRimEnabled": 1, "_PanelRimDepth": S["recess"], "_PanelRimWidth": S["rim_w"],
                         "_PanelRimSmoothness": S["rim_w"]})
        if S["screws"]:
            base.update({"_PanelScrewsEnabled": 1, "_PanelScrewShapeType": 1, "_PanelScrewInsetPx": 7.5,
                         "_PanelScrewRadiusPx": 3.8, "_PanelScrewColor": mix(c, "#FFFFFF", 0.35),
                         "_PanelScrewSlotColor": mix(c, "#000000", 0.7), "_PanelScrewRotation": -24,
                         "_PanelScrewDepth": 0.73, "_PanelScrewMetallic": 0.9, "_PanelScrewBore": 0.62})
        return slot, base, {}, None

    def plate_colors(self, L, P, slot):
        c = P[L.S(slot)["fill"]]
        # top-lit: A (uv.y 0) is the BOTTOM — keep the light in B
        return mix(c, "#000000", P["PLATE_LO"]), mix(c, "#FFFFFF", P["PLATE_HI"])


CLASSES = {"unlit": Unlit, "neon": Neon, "lit": Lit}

# Palette tokens a spec may leave out (derived). Everything else in TOKENS is required.
PALETTE_DEFAULTS = {
    "unlit": lambda P: {"HOT": P["ACCENT"]},
    "neon": lambda P: {"PRESS": P["ACCENT"]},
    "lit": lambda P: {"BODY_HI": mix(P["BODY"], "#FFFFFF", 0.07), "BODY_LO": mix(P["BODY"], "#000000", 0.12),
                      "DIS_BODY": mix(P["BODY"], P["FACE"], 0.6), "MARK_DIM": mix(P["MARK"], P["BODY"], 0.4),
                      "DIS_MARK": mix(P["MARK"], P["BODY"], 0.7),
                      "ACCENT_HI": mix(P["ACCENT"], "#FFFFFF", 0.12), "ACCENT_LO": mix(P["ACCENT"], "#000000", 0.12),
                      "ACCENT_DIS": mix(P["ACCENT"], P["FACE"], 0.65), "HOT": P["ACCENT"], "SOLO": P["ACCENT"],
                      "LAMP": P["ACCENT"], "LAMP_OFF": P.get("MARK_DIM") or mix(P["MARK"], P["BODY"], 0.4),
                      "CAP": P["BODY"], "SKIRT": P["BODY"], "NUB": P["ACCENT"], "VALUE_EM": 0.0,
                      "HANDLE": P["BODY"], "PAD_BODY": P["BODY"], "PAD_TINT": 0.5, "SCROLL": P["BODY"],
                      "SCROLL_HI": P["ACCENT"], "SHADOW": "#000000", "SHADOW_A": 0.45, "AMB": 0.6,
                      "AMB_PLATE": 0.5, "AMB_ACCENT": P.get("AMB", 0.6), "PLATE_LO": 0.06, "PLATE_HI": 0.08,
                      "WELL_EM": 0.0, "SOCKET": P["INSET"], "GAP": mix(P["BACK"], "#000000", 0.3)},
}


# ═══ 5. app palettes — what C# and layouts print with (derived, the spec overrides) ═══════════════
#
# The skill's list of app pieces a look must set: palette ink.* (PrintInk flips dark neutral print on a
# surface whose ink is light), display.*, tracks.* (incl. noteSeparator on pale lanes), review.*
# (slot/slotFill on pale lanes), key.* (the multitrack latch marks C# drives), surface.backdrop/gap.
# `ink.key` only where keys are pale (C# prints dark marks on accent keys on purpose).

def derive_app(P, pale_keys, pale):
    t = lambda k: first(P[k])                    # noqa: E731
    # three print tiers: INK (text), INK_DIM (secondary UI text), PRINT_DIM (dim silkscreen/readouts);
    # they default to the parts' MARK / MARK_DIM
    ui_ink = first(P.get("INK", P["MARK"]))
    dim = first(P.get("INK_DIM", P["MARK_DIM"]))
    pdim = first(P.get("PRINT_DIM", dim))
    groups = {
        "ui": dict(text=ui_ink, textDim=dim, textFaint=mix(dim, t("BACK"), 0.4), accent=t("ACCENT"),
                   warn=t("LAMP"), danger=t("HOT"), ok="#2E9E55" if pale else "#5ED17A"),
        "surface": dict(card=alpha(t("FACE"), "FA"), cardEdge=t("BODY"), divider=t("BACK"),
                        scrim=alpha(ui_ink, "99") if pale else alpha(t("GAP"), "B8"),
                        backdrop=t("GAP"), gap=t("GAP")),
        "ink": dict(faceplate=ui_ink, faceplateDim=pdim, inset=ui_ink, insetDim=pdim, backplane=ui_ink,
                    backplaneDim=pdim, socket=ui_ink, socketDim=pdim,
                    **(dict(key=ui_ink, keyDim=dim) if pale_keys else {}),
                    reviewBar=ui_ink, reviewBarDim=pdim),
        "display": dict(text=ui_ink, textDim=pdim, textAlt=ui_ink, warn=t("HOT")),
        "key": dict(label=ui_ink, faceOff=t("BODY"), edgeOff=t("PRESS") if "PRESS" in P else t("BODY"),
                    markOff=t("MARK_DIM"), bankFaceOff=t("BODY"), bankEdgeOff=t("BACK"), glyphOff=t("MARK_DIM"),
                    muteOn=t("ON_MARK"), soloOn=t("ON_MARK"), velOff=t("MARK_DIM"), velOn=t("ACCENT")),
        "pad": dict(empty=alpha(t("PAD_BODY"), "FF")),
        "review": dict(bar=alpha(t("BACK"), "F0"), barRule="#0000001A" if pale else "#FFFFFF14",
                       **(dict(slot=dim, slotFill=t("FACE")) if pale else {})),
        "tracks": dict(backdrop=t("BACK"), strip=t("INSET"), rowWithSample=t("BODY"), rowEmpty=t("FACE"),
                       rowNotesNoSample=mix(t("FACE"), t("HOT"), 0.15), text=ui_ink, ruler=alpha(pdim, "E6"),
                       playhead=alpha(ui_ink, "E6"), recMarker=alpha(t("HOT"), "DC"),
                       scrollbar="#0000001E" if pale else "#FFFFFF1E",
                       **(dict(noteSeparator=mix(t("FACE"), "#FFFFFF", 0.7)) if pale else {})),
    }
    chrome = dict(headerBg=t("BACK"), headerBorder="#00000000", tabFillBottom=t("INSET"), tabFillTop=t("INSET"),
                  tabFillActiveBottom=t("FACE"), tabFillActiveTop=t("FACE"), label=dim, labelActive=ui_ink,
                  icon=dim, iconActive=t("ACCENT"), gear=alpha(dim, "CC"), meatballIdle=dim, meatballLit=t("ACCENT"))
    return chrome, groups


def merge(base, over):
    """Deep-merge spec overrides into derived defaults: keeps key order, appends new keys, None deletes."""
    out = copy.deepcopy(base)
    for k, v in (over or {}).items():
        if v is None:
            out.pop(k, None)
        elif isinstance(v, dict) and isinstance(out.get(k), dict):
            out[k] = merge(out[k], v)
        else:
            out[k] = copy.deepcopy(v)
    return out


def display_map(family, mode):
    m = {k: f"{family}.{mode}" for k in AUTHORED_FINISHES}
    m["led.matrix.green"] = m["led.matrix.amber"] = f"{family}.{mode}.meter"
    m["waveform"] = f"{family}.{mode}.waveform"
    return m


UNLIT_LAMP = {"pos": [0.5, 2.0], "height": 2.0, "color": "#FFFFFF", "intensity": 0.0, "specular": 0.0,
              "specularPower": 16, "enabled": False}
ANIMATE = {"enabled": False, "mode": "random", "speed": 0.45, "reach": 2.5}


def _inline(d):
    return "{ " + ", ".join(f"{json.dumps(k)}: {json.dumps(v)}" for k, v in d.items()) + " }"


def theme_text(name, scene):
    """The Themes/*.theme.json layout every shipped rig uses: one line per lamp."""
    lines = ["{", f'  "themeName": {json.dumps(name)},', '  "scene": {']
    items = []
    for k, v in scene.items():
        if k == "portrait":
            inner = ",\n".join(f'      {json.dumps(pk)}: {_inline(pv)}' for pk, pv in v.items())
            items.append(f'    "portrait": {{\n{inner}\n    }}')
        else:
            items.append(f"    {json.dumps(k)}: {_inline(v)}")
    lines.append(",\n".join(items))
    lines += ["  }", "}", ""]
    return "\n".join(lines)


# ═══ 6. the look ══════════════════════════════════════════════════════════════════════════════════

class Look:
    def __init__(self, *, title, style, prefix, slug, cls, modes, order=50, blurb="", note="",
                 author="DrumSumDrum", brief=None, status="draft", shape=None, material=None, rig=None,
                 displays=None, colourways=None, waive=None, state_shifts=None, generator=None, track_themes=None,
                 tagline=None):
        assert cls in CLASSES, f"cls must be one of {sorted(CLASSES)}"
        self.title, self.style, self.prefix, self.slug, self.cls = title, style, prefix, slug, cls
        self.order, self.blurb, self.note, self.author = order, blurb, note, author
        self.brief, self.status = brief, status
        self.kit = CLASSES[cls]()
        self.modes = modes
        self.shape = shape or {}
        self.material = material or {}
        self.rig = rig
        self.displays = displays
        self.colourways = colourways or {}
        self.waive = waive or {}
        self.state_shifts = state_shifts or {"Hover": 0.08, "Pressed": -0.1, "Active": 0.16, "Disabled": -0.22}
        self.generator = generator
        self.track_themes = track_themes or {}
        self.tagline = tagline

    # ── resolution ──
    def S(self, slot):
        fam, _, group, _, fp = SLOTS[slot]
        cs, sp = self.kit.SHAPE, self.shape
        d = {"pad": fp}
        # class group < spec group < class slot < spec slot: a slot's own class default (a Dot is a
        # circle, a Close key is invisible until hovered) survives a group-wide restyle unless the spec
        # names that slot
        for layer in (cs.get(group), sp.get(group), cs.get(slot), sp.get(slot)):
            d.update(layer or {})
        return d

    def palette(self, mode):
        given = dict(self.modes[mode]["palette"])
        P = dict(PALETTE_DEFAULTS[self.cls](given), **given)
        missing = [t for t in self.kit.TOKENS if t not in P]
        if missing:
            raise KeyError(f"{self.style} {mode}: palette lacks {missing}")
        P["prefix"] = self.mode_prefix(mode)
        # materials may be re-tuned per mode (a pale brushed plate wants less grain than a dark one)
        P["MATERIAL"] = merge(self.material, self.modes[mode].get("material", {}))
        return P

    def mode_prefix(self, mode):
        return self.prefix + mode.capitalize()

    def colourway(self, name):
        cw = self.colourways[name]
        lk = copy.copy(self)
        lk.title = cw.get("title", f"{self.title} {name}")
        lk.style = cw.get("style", self.style + name)
        lk.prefix = cw.get("prefix", self.prefix + name)
        lk.slug = cw.get("slug", f"{self.slug}-{name.lower()}")
        lk.order = cw.get("order", self.order)
        lk.blurb = cw.get("blurb", self.blurb)
        lk.colourways = {}
        lk.modes = {}
        for mode, m in self.modes.items():
            mm = copy.deepcopy(m)
            mm["palette"] = dict(m["palette"], **cw.get("palette", {}).get(mode, {}))
            mm["app"] = merge(m.get("app", {}), cw.get("app", {}).get(mode, {}))
            for k in ("blurb", "track"):
                if k in cw.get("modes", {}).get(mode, {}):
                    mm[k] = cw["modes"][mode][k]
            lk.modes[mode] = mm
        return lk

    # ── parts ──
    def build(self, mode):
        """-> (P, {name: doc}, {name: [problems]}) — validated against the shader, nothing written."""
        P = self.palette(mode)
        out, problems = {}, {}
        for slot, base, states, extra in self.kit.parts(self, P):
            fam, bkey = SLOTS[slot][:2]
            name = P["prefix"] + slot
            doc, probs = skin(name, fam, base, states, bounds=BOUNDS[bkey], flat_shader=not self.kit.rm,
                              extra=extra, write=False, quiet=True)
            doc["author"] = self.author
            probs = [p for p in probs if not (p.startswith("RM-ONLY") and RM_ONLY_OK.match(p.split()[1]))]
            out[name] = doc
            if probs:
                problems[name] = sorted(set(probs))
        return P, out, problems

    # ── app side ──
    def app(self, mode, P):
        pale = lum(P["FACE"]) > 0.5
        pale_keys = lum(P["BODY"]) > 0.5
        chrome, groups = derive_app(P, pale_keys, pale)
        over = self.modes[mode].get("app", {})
        chrome = merge(chrome, over.get("chrome"))
        groups = merge(groups, {k: v for k, v in over.items() if k not in ("chrome", "hot")})
        return chrome, groups

    def lights_ref(self, mode):
        if self.cls != "lit":
            return f"Themes/{self.style}.theme"
        return f"Themes/{self.style}{mode.capitalize()}.theme"

    def theme_files(self):
        if self.cls != "lit":
            kind = "unlit"
            scene = {f"light{i}": dict(UNLIT_LAMP) for i in (1, 2, 3)}
            scene["animate"] = dict(ANIMATE)
            return {f"Themes/{self.style}.theme.json": theme_text(f"{self.title} rig ({kind})", scene)}
        out = {}
        for mode in MODES:
            rig = copy.deepcopy((self.rig or {}).get(mode) or {})
            scene = {}
            for i in (1, 2, 3):
                lamp = dict(UNLIT_LAMP, specularPower=32)
                lamp.update(rig.get(f"light{i}", {}))
                lamp.setdefault("enabled", True)
                scene[f"light{i}"] = {k: lamp[k] for k in ("pos", "height", "color", "intensity", "specular",
                                                            "specularPower", "enabled")}
            if rig.get("portrait"):
                scene["portrait"] = rig["portrait"]
            scene["animate"] = dict(ANIMATE)
            out[f"Themes/{self.style}{mode.capitalize()}.theme.json"] = theme_text(
                f"{self.title} {mode.capitalize()} rig", scene)
        return out

    def display_block(self, mode):
        d = self.modes[mode].get("displays", self.displays)
        if d is None:
            return {"*": "flat." + mode}
        return display_map(d, mode) if isinstance(d, str) else dict(d)

    def rig_scene(self, mode):
        """The rig as slrender's job override (sheets light every cell exactly as the app will)."""
        if self.cls != "lit":
            return {f"light{i}": {"enabled": False} for i in (1, 2, 3)}
        return json.loads(re.sub(r"^\s*//.*$", "", self.theme_files()[f"Themes/{self.style}{mode.capitalize()}"
                                                                       f".theme.json"], flags=re.M))["scene"]

    def recipe_text(self):
        def roster(pre):
            return ({f: {"$base": pre + p} for f, p in FAMILY_PART.items()},
                    {r: {"$base": pre + p} for r, p in ROLE_PART.items()})

        fam, roles = roster(self.mode_prefix("dark"))
        doc = {"styleName": self.style, "title": self.title, "order": self.order, "author": self.author,
               "blurb": self.blurb, "stateShifts": self.state_shifts, "families": fam, "roles": roles, "modes": {}}
        for mode in MODES:
            P = self.palette(mode)
            m = self.modes[mode]
            colors = {}
            for k, tok in self.kit.RECIPE_COLORS.items():
                if isinstance(tok, tuple):
                    colors[k] = P[tok[0]][tok[1]]
                else:
                    colors[k] = first(P[tok])
            colors.update(m.get("colors", {}))
            chrome, groups = self.app(mode, P)
            fam, roles = roster(P["prefix"])
            doc["modes"][mode] = {
                "trackTheme": m["track"], "blurb": m["blurb"], "lights": self.lights_ref(mode),
                "colors": colors, "chrome": chrome, "palettes": groups, "displays": self.display_block(mode),
                "families": fam, "roles": roles,
                "swaps": {k: P["prefix"] + v for k, v in SWAP_PART.items()},
            }
        bar = "// " + "═" * 75
        gen = self.generator or f"Tools/looks/{self.slug.replace('-', '_')}.py"
        head = [bar, f"// {self.title.upper()} — {self.tagline or self.blurb_line()}", "//",
                f"// GENERATED by `python {gen} recipe` (Tools/lookkit.py) from the same spec as the",
                f"// {self.mode_prefix('dark')}*/{self.mode_prefix('light')}* parts — edit the spec, not this file. "
                "Every role, family and",
                "// by-name skin rosters an authored file, so nothing is baked and nothing can inherit another",
                "// look's finish."]
        for ln in (self.note.strip().splitlines() if self.note else []):
            head.append(("// " + ln).rstrip())
        head.append(bar)
        return "\n".join(head) + "\n" + json.dumps(doc, indent=2) + "\n"

    def blurb_line(self):
        return {"unlit": "unlit, non-raymarched", "neon": "unlit, non-raymarched neon tubes",
                "lit": "raymarched, lit by its own rig"}[self.cls] + "."

    def files(self, modes=MODES):
        """Every file `write` produces: {repo-relative path: text}."""
        out = {}
        for mode in modes:
            _, parts, _ = self.build(mode)
            for name, doc in parts.items():
                out[f"Assets/Resources/MaterialStates/{name}.states.json"] = json.dumps(doc, indent=4)
        out[f"Assets/Resources/UiStyles/{self.style}.style.json"] = self.recipe_text()
        for rel, text in self.theme_files().items():
            out[f"Assets/Resources/{rel}"] = text
        for name, tt in self.track_themes.items():
            out[f"Assets/Resources/TrackThemes/{name}.track.json"] = json.dumps(tt, indent=2) + "\n"
        return out

    def manifest(self):
        return {"slug": self.slug, "style": self.style, "title": self.title, "prefix": self.prefix,
                "brief": self.brief or f"BACKLOG.md#{self.slug}", "class": self.cls, "status": self.status,
                "files": [self.generator or f"Tools/looks/{self.slug.replace('-', '_')}.py",
                          f"Assets/Resources/UiStyles/{self.style}.style.json",
                          f"Assets/Resources/Themes/{self.style}*.theme.json",
                          f"Assets/Resources/MaterialStates/{self.mode_prefix('dark')}*.states.json",
                          f"Assets/Resources/MaterialStates/{self.mode_prefix('light')}*.states.json",
                          *[f"Assets/Resources/TrackThemes/{n}.track.json" for n in self.track_themes]]}

    # ── the rules ──
    def waived(self, rule, where):
        return self.waive.get(f"{rule}:{where}") or self.waive.get(rule)

    def audit(self):
        """-> (errors, warnings, waivers) — every rule the skill learned the hard way."""
        errors, warns, waivers = [], [], []

        def rule(ok, r, where, msg):
            if ok:
                return
            why = self.waived(r, where)
            if why:
                waivers.append(f"{r}:{where} — {msg}  [waived: {why}]")
            else:
                errors.append(f"{r}:{where} — {msg}")

        errors += footprint_report()
        built = {}
        for mode in MODES:
            P, parts, problems = self.build(mode)
            built[mode] = P
            for name, probs in problems.items():
                errors += [f"shader:{name} — {p}" for p in probs]
            for name, doc in parts.items():
                slot = name[len(P["prefix"]):]
                fam, _, group, app, fp = SLOTS[slot]
                norm = next(s for s in doc["states"] if not s["baseStateName"])
                v = {p["name"]: p["value"] for p in norm["parameters"]}
                f = lambda k, d=0.0: float(v.get(k, d))          # noqa: E731
                st = {s["stateName"]: s for s in doc["states"]}
                rule("bounds" in doc, "bounds", name, "no bounds (the hit test becomes the whole rect)")
                miss = [g for g in guards(fam, self.kit.rm) if g not in v]
                rule(not miss, "guards", name, f"effect guards left to the material: {miss[:6]}")
                if fp is not None:
                    pv = f(PAD_PARAM[fam], -1)
                    rule(abs(pv - fp) < 5e-4, "footprint", slot,
                         f"{PAD_PARAM[fam]} {pv:g} but {app or 'the app slot'} is {fp:g} (moves the layout/hitbox)")
                if doc["shaderName"].endswith("RM"):
                    for lip in ("_ButtonLipHeight", "_KnobLipHeight", "_HandleLipHeight"):
                        if lip in props(stem(fam, True)):
                            rule(lip in v and f(lip) == 0.0, "lip", name, f"{lip} must be authored 0 (dotted seam)")
                if fam == "Knob":
                    rule("_LightingShadow1Enabled" in v, "knob-shadow", name,
                         "_LightingShadow1Enabled unset (defaults ON: a dark arc over the track)")
                    if f("_LineEnabled"):
                        lim = 0.88 if f("_LineRoundedEnabled") else 0.92
                        rule(f("_LineRadius") + f("_LineWidth") <= lim + 1e-6, "arc", name,
                             f"_LineRadius+_LineWidth {f('_LineRadius') + f('_LineWidth'):.3f} > {lim} (quad clips it)")
                    if f("_KnobEnabled") and f("_KnobBevelEnabled"):
                        rule(f("_KnobBevelDistance") < 0.8 * f("_LineRadius") * f("_KnobSize"), "knob-bevel", name,
                             "bevel distance reaches the cap radius (the whole cap faces away: grey)")
                if fam == "Panel":
                    rule(f("_PanelFaceSmoothness") == 0.0, "plate-dome", name,
                         "_PanelFaceSmoothness on a rectangle stamps medial-axis wedges (keep 0)")
                    if f("_PanelBevelEnabled"):
                        rule(f("_PanelBevelDistance") <= 0.14, "plate-bevel", name,
                             f"_PanelBevelDistance {f('_PanelBevelDistance'):g} > 0.14 (medial-axis wedges)")
                        if self.kit.rm and slot in ("Face", "Back"):
                            rule(f("_PanelBevelDepth") == 0.0, "outer-bevel", name,
                                 "the outermost plate keeps no bevel (a chrome bar down the lamp side)")
                    if f("_PanelPatternEnabled"):
                        rule(f("_PanelPatternPx") > 0, "pattern-px", name,
                             "patterned plate not pixel-locked (_PanelPatternPx): grain scales with the panel")
                if fam == "Button" and self.kit.rm and f("_ButtonFaceSmoothness") > 0 and f("_ButtonRoundness") < 0.25 \
                        and f("_ButtonShapeParam1") > 0.1:
                    warns.append(f"{name}: domed face with roundness {f('_ButtonRoundness'):g} < 0.25 "
                                 "(the bevel band may reach the medial axis)")
                if group in ("key", "dial", "fader", "switch") and slot not in ("Dot", "Pad", "ScrollHandle"):
                    for want in ("Hover", "Disabled"):
                        if want not in st:
                            warns.append(f"{name}: no {want} state")
                    if "Disabled" in st and not st["Disabled"]["parameters"]:
                        warns.append(f"{name}: empty Disabled (a disabled control looks enabled)")
                if slot in LATCHES:
                    rule("Active" in st, "latch", name, "a latching key needs an Active state")
        # light modes change the chassis, not the controls
        if "light" in built and "dark" in built:
            for tok in ("BODY", "ACCENT", "CAP", "HANDLE"):
                if tok in built["dark"] and tok in built["light"]:
                    d = abs(lum(built["dark"][tok]) - lum(built["light"][tok]))
                    rule(d < 0.3, "light-controls", tok,
                         f"light mode moves control token {tok} by {d:.2f} luminance (change the chassis, "
                         "not the controls)")
        for mode in MODES:
            if not self.modes[mode].get("track"):
                errors.append(f"track:{mode} — no trackTheme")
            tf = ROOT / RES_REL / "TrackThemes" / f"{self.modes[mode].get('track')}.track.json"
            if self.modes[mode].get("track") not in self.track_themes and not tf.exists():
                errors.append(f"track:{mode} — TrackThemes/{self.modes[mode].get('track')}.track.json does not exist")
        return errors, warns, waivers

    # ── sheets ──
    def sheet_parts_dir(self, mode):
        d = ROOT / ".skinsheet" / "lookkit" / self.mode_prefix(mode)
        d.mkdir(parents=True, exist_ok=True)
        P, parts, _ = self.build(mode)
        paths = {}
        for name, doc in parts.items():
            p = d / f"{name}.states.json"
            p.write_text(json.dumps(doc, indent=4), encoding="utf-8")
            paths[name[len(P["prefix"]):]] = p.as_posix()
        return P, parts, paths


# ═══ 7. sheets — the rack composite (what reviewers judge) and the parts sheet ═══════════════════

def _track_rows(name, looks_tracks):
    if name in looks_tracks:
        return looks_tracks[name]["palette"]
    from lookcheck import strip_jsonc
    f = ROOT / RES_REL / "TrackThemes" / f"{name}.track.json"
    return json.loads(strip_jsonc(f.read_text(encoding="utf-8-sig")))["palette"]


def _authored(doc, param):
    for prm in doc["states"][0]["parameters"]:
        if prm["name"] == param:
            return [float(x) for x in prm["value"].split(",")][:3]
    return None


def pad_binding(doc, row_hex):
    """What C#'s padColor binding writes for one row colour: authored + (row - authored) * amount."""
    rgb = rgbf(row_hex)
    out = {}
    for t in doc.get("padColor", {}).get("targets", []):
        a = _authored(doc, t["param"])
        if a is None:
            continue
        out[t["param"]] = ",".join(f"{a[j] + (rgb[j] - a[j]) * t['amount']:.5f}" for j in range(3)) + ",1"
    return out


class Canvas:
    """Premultiplied compositor: every slrender cell is premultiplied RGBA (drawn on transparent black
    with the widget's own blend), so `dst = src + (1 - a) * dst` is exactly what the app's blend does —
    AA edges never darken and additive blooms (alpha 0, emissive) stay additive."""

    def __init__(self, w, h, bg):
        import numpy as np
        self.np = np
        self.w, self.h = w, h
        self.px = np.zeros((h, w, 3), np.float32)
        self.px[:] = np.array(rgbf(bg), np.float32)
        self.texts = []

    def put(self, png, x, y, w, h, ss=1, frame=1.0):
        from PIL import Image
        np = self.np
        im = Image.open(png).convert("RGBA")
        fw, fh = int(round(w * frame)), int(round(h * frame))
        a = np.asarray(im, np.float32) / 255.0
        if ss > 1:
            a = a.reshape(fh, ss, fw, ss, 4).mean(axis=(1, 3))
        x0, y0 = int(round(x - (fw - w) / 2)), int(round(y - (fh - h) / 2))
        xs, ys = max(0, x0), max(0, y0)
        xe, ye = min(self.w, x0 + fw), min(self.h, y0 + fh)
        if xe <= xs or ye <= ys:
            return
        src = a[ys - y0:ye - y0, xs - x0:xe - x0]
        dst = self.px[ys:ye, xs:xe]
        dst[:] = src[..., :3] + (1.0 - src[..., 3:4]) * dst

    def text(self, x, y, s, col, size=11, bold=False, anchor="la"):
        self.texts.append((x, y, s, col, size, bold, anchor))

    def image(self):
        from PIL import Image, ImageDraw
        from skinsheet import _font
        img = Image.fromarray((self.np.clip(self.px, 0, 1) * 255 + 0.5).astype("uint8"), "RGB")
        d = ImageDraw.Draw(img)
        for x, y, s, col, size, bold, anchor in self.texts:
            d.text((x, y), s, font=_font(size, bold), fill=first(col)[:7], anchor=anchor)
        return img


class Scene:
    """Queue cells (part, rect, state, value...), render them in one job, composite onto a Canvas."""

    def __init__(self, look, mode, w, h, tag):
        self.look, self.mode, self.tag = look, mode, tag
        self.P, self.parts, self.paths = look.sheet_parts_dir(mode)
        self.w, self.h = w, h
        self.cells, self.meta = [], []
        self.canvas = Canvas(w, h, self.P["GAP"])
        self.lit = look.cls == "lit"

    def add(self, part, x, y, w, h, state=None, value=None, sets=None):
        cid = f"lk-{self.P['prefix']}-{self.tag}-{len(self.cells)}"
        plate = SLOTS[part][2] == "plate"
        ss = 2 if self.lit else 1
        c = {"id": cid, "states": self.paths[part], "w": w, "h": h, "ss": ss, "bg": "#00000000",
             "pos": [(x + w / 2) / self.w, 1.0 - (y + h / 2) / self.h]}
        if self.lit and not plate and SLOTS[part][0] != "Toggle":
            c["shadow"] = 2
        if state:
            c["state"] = state
        s = dict(sets or {})
        if value is not None:
            s["_Value"] = value
        if s:
            c["set"] = s
        self.cells.append(c)
        self.meta.append((cid, x, y, w, h, ss, 2.0 if c.get("shadow") else 1.0))

    def pad(self, x, y, w, h, row_hex, state=None):
        self.add("Pad", x, y, w, h, state=state, sets=pad_binding(self.parts[self.P["prefix"] + "Pad"], row_hex))

    def render(self):
        from skinsheet import render, OUT
        render(self.cells, rig=self.look.rig_scene(self.mode), timeout=900)
        for cid, x, y, w, h, ss, frame in self.meta:
            p = OUT / f"{cid}.png"
            if p.exists():
                self.canvas.put(p, x, y, w, h, ss, frame)
            else:
                print("   missing", cid)
        return self.canvas


def ink(look, mode, P):
    _, groups = look.app(mode, P)
    i = groups.get("ink", {})
    return i.get("faceplate", first(P["MARK"])), i.get("faceplateDim", first(P["MARK_DIM"]))


def rack_sheet(look, mode, out):
    """The cohesion test: one device built from every part, each ON the plate it sits on."""
    W, H = 1180, 600
    sc = Scene(look, mode, W, H, "rack")
    P = sc.P
    S = look.S
    kpx = {k: S(k).get("px", d) for k, d in (("Knob", 56), ("KnobHero", 112), ("KnobSmall", 48))}
    a = sc.add
    a("Face", 0, 0, W, 470)
    # top strip: readout well, lamps, learn chip, switches, close
    a("Well", 24, 18, 250, 58)
    for i in range(3):
        a("Lamp", 300 + i * 34, 30, 28, 28, state="Active" if i == 0 else "Normal")
    a("Chip", 414, 32, 64, 26)
    a("Pill", 498, 32, 52, 26, value=0.0)
    a("Pill", 558, 32, 52, 26, value=1.0)
    a("Close", W - 60, 22, 36, 30, state="Normal,Hover")
    # dials on an inset
    vals = (0.0, 0.4, 0.8, 1.0)
    kw = kpx["Knob"]
    a("Inset", 18, 96, 620, min(210, kw + kpx["KnobSmall"] + 96))
    for i, v in enumerate(vals):
        a("Knob", 40 + i * 110, 112, kw, kw, value=v)
    a("Knob", 480, 112, kw, kw, state="Disabled", value=0.5)
    a("Knob", 560, 112, kw, kw, state="Normal,Hover", value=0.5)
    ks = kpx["KnobSmall"]
    for i, v in enumerate(vals):
        a("KnobSmall", 44 + i * 110, 112 + kw + 46, ks, ks, value=v)
    a("KnobSmall", 484, 112 + kw + 46, ks, ks, state="Normal,Hover,Pressed", value=0.6)
    # hero on the plate itself + a bezelled screen
    kh = kpx["KnobHero"]
    a("KnobHero", 660, 104, kh, kh, value=0.66)
    a("KnobHero", 660 + kh + 30, 104, kh, kh, state="Normal,Hover,Pressed", value=0.25)
    a("Bezel", 940, 96, 220, 120)
    a("Well", 952, 108, 196, 96)
    # faders + keys
    a("Slider", 24, 324, 300, 40, value=0.62)
    a("Slider", 24, 372, 300, 40, state="Disabled", value=0.3)
    a("Accent", 344, 324, 96, 40)
    a("Accent", 344, 372, 96, 40, state="Normal,Hover,Pressed")
    keys = [("Button", "Normal"), ("Button", "Normal,Hover"), ("Button", "Normal,Hover,Pressed"),
            ("Button", "Disabled")]
    for i, (part, st) in enumerate(keys):
        a(part, 458 + i * 84, 324, 76, 40, state=st)
    lat = [("ToggleBtn", "Normal"), ("ToggleBtn", "Active"), ("Solo", "Normal"), ("Solo", "Active"),
           ("Lamp", "Disabled")]
    for i, (part, st) in enumerate(lat):
        a(part, 458 + i * 64, 374, 40, 34, state=st)
    # pads in a socket
    a("Socket", 800, 236, 360, 222)
    rows = _track_rows(look.modes[mode]["track"], look.track_themes)
    for r in range(3):
        for c in range(4):
            st = "Normal,Latched" if (r, c) == (0, 1) else ("Normal,Hover,Pressed" if (r, c) == (1, 2) else None)
            if (r, c) == (2, 3):
                st = "Disabled"
            sc.pad(814 + c * 86, 248 + r * 68, 78, 62, rows[f"row{r + 1}"], state=st)
    # the multitrack gutter
    a("Back", 0, 476, W, 124)
    a("ScrollTrack", 24, 500, 460, 14)
    a("ScrollHandle", 120, 500, 120, 14)
    a("ScrollHandle", 300, 500, 80, 14, state="Normal,Hover")
    a("Dot", 500, 498, 18, 18)
    a("Fader", 530, 500, 140, 14, value=0.4)
    a("Inset", 24, 530, 460, 52)
    a("Button", 36, 538, 70, 36)
    a("ToggleBtn", 116, 540, 32, 32, state="Active")
    a("Solo", 154, 540, 32, 32)
    cv = sc.render()
    ink_c, dim_c = ink(look, mode, P)
    key_ink = first(P["MARK"])
    screen = look.app(mode, P)[1].get("display", {})
    scr_ink, scr_dim = screen.get("text", ink_c), screen.get("textDim", dim_c)      # print IN a well
    t = cv.text
    t(36, 30, "-12.4", scr_ink, 26, True)
    t(130, 44, "dB  OUT", scr_dim, 11)
    t(446, 45, "LEARN", key_ink, 10, True, "mm")
    for i, lab in enumerate(("0%", "40%", "80%", "100%", "DIS", "HOVER")):
        t(40 + i * 110 + kw / 2 if i < 4 else (480 if i == 4 else 560) + kw / 2, 112 + kw + 8, lab, dim_c, 10,
          False, "ma")
    t(660 + kh / 2, 104 + kh + 10, "MASTER", dim_c, 11, True, "ma")
    t(660 + kh * 1.5 + 30, 104 + kh + 10, "PRESSED", dim_c, 11, True, "ma")
    t(1050, 156, "120.00", scr_ink, 22, True, "mm")
    t(392, 344, "PLAY", first(P["ON_MARK"]), 12, True, "mm")
    t(392, 392, "PLAY", first(P["ON_MARK"]), 12, True, "mm")
    key_ink, key_dim = first(P["MARK"]), first(P["MARK_DIM"])     # print ON a key is key ink, not plate ink
    for i, lab in enumerate(("KEY", "HOVER", "PRESS", "DIS")):
        t(458 + i * 84 + 38, 344, lab, key_ink if i < 3 else key_dim, 11, True, "mm")
    t(24, 418, "FADER  62%  ·  DISABLED 30%", dim_c, 10)
    t(1160, 222, "PADS · latched · pressed · disabled", dim_c, 10, False, "ra")
    t(700, 504, "A01  KICK", ink_c, 12, True)
    t(200, 548, f"{look.title.upper()} {mode.upper()} · {look.cls}", dim_c, 11, True)
    img = cv.image()
    return _titled(img, f"{look.title} {mode} — rack composite (cohesion test)", P, out)


def _titled(img, title, P, out):
    from PIL import Image, ImageDraw
    from skinsheet import _font
    dark = lum(P["GAP"]) < 0.5
    page, ink_ = ("#0B0D10", "#E6EBF2") if dark else ("#F2F3F5", "#12161B")
    sheet = Image.new("RGB", (img.width, img.height + 40), page)
    ImageDraw.Draw(sheet).text((12, 10), title, font=_font(18, True), fill=ink_)
    sheet.paste(img, (0, 40))
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out, optimize=True)
    print("  ->", out.relative_to(ROOT) if out.is_relative_to(ROOT) else out)
    return out


def parts_sheet(look, mode, out):
    """Every part, every state, the value sweep, at its real size — each cell over its own plate."""
    W = 1180
    rows = []
    vals = (0.0, 0.4, 0.8, 1.0)
    keyst = ("Normal", "Normal,Hover", "Normal,Hover,Pressed", "Disabled")
    S = look.S

    def k(part, w, h, extra=()):
        return (part, [(part, w, h, st, None, st.split(",")[-1]) for st in keyst + tuple(extra)])
    rows.append(k("Button", 76, 40))
    rows.append(k("Accent", 96, 40))
    rows.append(k("ToggleBtn", 40, 34, ("Active",)))
    rows.append(k("Solo", 40, 34, ("Active",)))
    rows.append(k("Lamp", 30, 30, ("Active",)))
    rows.append(k("Close", 36, 30))
    rows.append(k("Chip", 64, 26))
    rows.append(("Dot · ScrollHandle", [("Dot", 18, 18, st, None, st.split(",")[-1]) for st in keyst[:3]] +
                 [("ScrollHandle", 110, 14, st, None, st.split(",")[-1]) for st in keyst]))
    rows.append(("Pad", [("Pad", 78, 62, st, None, st.split(",")[-1])
                         for st in keyst + ("Normal,Latched",)]))
    for part, dflt in (("KnobSmall", 48), ("Knob", 56), ("KnobHero", 112)):
        px = S(part).get("px", dflt)
        cells = [(part, px, px, None, v, f"{v:.0%}") for v in vals]
        cells += [(part, px, px, "Normal,Hover", 0.5, "Hover"), (part, px, px, "Disabled", 0.5, "Disabled")]
        if px != 48:
            cells += [(part, 48, 48, None, v, f"{v:.0%}@48") for v in (0.0, 0.4, 0.8)]
        rows.append((part, cells))
    rows.append(("Slider", [("Slider", 170, 40, None, v, f"{v:.0%}") for v in vals] +
                 [("Slider", 170, 40, "Disabled", 0.5, "Disabled")]))
    rows.append(("Fader · Pill", [("Fader", 140, 14, None, v, f"{v:.0%}") for v in (0.2, 0.7)] +
                 [("Pill", 52, 26, None, 0.0, "off"), ("Pill", 52, 26, None, 1.0, "on"),
                  ("Pill", 52, 26, "Normal,Hover", 1.0, "Hover"), ("Pill", 52, 26, "Disabled", 1.0, "Disabled")]))
    # plates sit in the GAP (the darkest thing on screen), like docked panels
    rows.append(("Plates", [(p, w, h, None, None, p) for p, w, h in
                            (("Face", 220, 110), ("Inset", 200, 110), ("Socket", 200, 110), ("Back", 220, 110))]))
    rows.append(("Screens · gutter", [(p, w, h, None, None, p) for p, w, h in
                                       (("Well", 200, 60), ("Bezel", 200, 60), ("ScrollTrack", 200, 14))]))
    # lay out
    gap, lab_h, row_gap, x0 = 16, 14, 14, 150
    y = 12
    placed, bands = [], []
    for label, cells in rows:
        h = max(c[2] for c in cells) + (32 if look.cls == "lit" else 8)
        x = x0
        for c in cells:
            if x + c[1] > W - 10:
                break
            placed.append((label, c, x, y + (h - c[2]) // 2))
            x += max(c[1], 40) + gap
        placed.append((label, None, 16, y + h // 2 - 7))
        if label.startswith(("Plates", "Screens")):
            bands.append((y - row_gap // 2, h + lab_h + row_gap))
        y += h + lab_h + row_gap
    H = y
    sc = Scene(look, mode, W, H, "parts")
    sc.canvas.px[:] = sc.canvas.np.array(rgbf(look.kit.plate_colors(look, sc.P, "Face")[0]), "float32")
    for by, bh in bands:
        sc.canvas.px[max(0, by):by + bh] = sc.canvas.np.array(rgbf(sc.P["GAP"]), "float32")
    rowsc = _track_rows(look.modes[mode]["track"], look.track_themes)
    ink_c, dim_c = ink(look, mode, sc.P)
    for label, c, x, yy in placed:
        if c is None:
            sc.canvas.text(x, yy, label, ink_c, 12, True)
            continue
        part, w, h, st, v, cap = c
        if part == "Pad":
            sc.pad(x, yy, w, h, rowsc["row2"], state=st)
        else:
            sc.add(part, x, yy, w, h, state=st, value=v)
        sc.canvas.text(x + max(w, 40) / 2, yy + h + 4 + (10 if look.cls == "lit" else 0), cap, dim_c, 9,
                       False, "ma")
    cv = sc.render()
    return _titled(cv.image(), f"{look.title} {mode} — every part, every state, real sizes", sc.P, out)


# ═══ 8. CLI ═══════════════════════════════════════════════════════════════════════════════════════

def write_files(files, root):
    for rel, text in files.items():
        p = Path(root) / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(text, encoding="utf-8", newline="\n")
    print(f"  wrote {len(files)} files under {Path(root).resolve()}")


def diff_files(files, root, show=12):
    """Compare built files with what is on disk under root. -> number of files that differ."""
    from lookcheck import strip_jsonc
    same, differ = 0, []
    for rel, text in files.items():
        p = Path(root) / rel
        cur = p.read_text(encoding="utf-8") if p.exists() else None
        if cur == text:
            same += 1
            continue
        differ.append(rel)
        if cur is None:
            print(f"  NEW   {rel}")
            continue
        try:
            jeq = json.loads(strip_jsonc(cur)) == json.loads(strip_jsonc(text))
        except ValueError:
            jeq = False
        lines = list(difflib.unified_diff(cur.splitlines(), text.splitlines(), "on disk", "built", n=0, lineterm=""))
        print(f"  DIFF  {rel}  ({'JSON-equal: whitespace/comments/key order only' if jeq else 'content differs'}"
              f", {sum(1 for ln in lines if ln[:1] in '+-') - 2} changed lines)")
        for ln in lines[2:2 + show]:
            print("        " + ln[:150])
    print(f"  {same} identical, {len(differ)} differ")
    return len(differ)


def selftest(look):
    """Break each rule on a copy of `look` and confirm audit() catches it (a spec cannot break them)."""
    cases = []
    lit = look.cls == "lit"
    plate = "Inset"
    cases.append(("footprint", {"shape": {"Button": {"pad": 0.2}}}))
    cases.append(("arc", {"shape": {"Knob": {"arc_outer": 0.97}}}))
    if lit:
        cases.append(("plate-bevel", "bevel"))
        cases.append(("outer-bevel", "outer"))
        cases.append(("pattern-px", {"material": {"plate": {"px": 0}}}))
        cases.append(("lip", "lip"))
    cases.append(("knob-shadow", "knob-shadow"))
    cases.append(("light-controls", "light"))
    cases.append(("guards", "guards"))
    cases.append(("bounds", "bounds"))
    fails = 0
    for want, how in cases:
        lk = copy.deepcopy(look)
        lk.waive = {}
        if isinstance(how, dict):
            for k, v in how.items():
                setattr(lk, k, merge(getattr(lk, k), v))
        elif how == "light":
            lk.modes["light"]["palette"] = dict(lk.modes["light"]["palette"], BODY=mix(first(
                lk.modes["dark"]["palette"]["BODY"]), "#FFFFFF" if lum(lk.modes["dark"]["palette"]["BODY"]) < 0.5
                else "#000000", 0.9))
        else:
            kit = lk.kit
            orig = kit.parts

            def broken(L, P, how=how, orig=orig):
                for slot, base, states, extra in orig(L, P):
                    if how == "lip" and slot == "Button":
                        base = {k: v for k, v in base.items() if k != "_ButtonLipHeight"}
                    if how == "knob-shadow" and slot == "Knob":
                        base = {k: v for k, v in base.items() if k != "_LightingShadow1Enabled"}
                    if how == "guards" and slot == "Button":
                        base = {k: v for k, v in base.items() if not k.endswith("PatternEnabled")}
                    if how in ("bevel", "outer") and slot == ("Face" if how == "outer" else plate):
                        base = dict(base, _PanelBevelEnabled=1, _PanelBevelDistance=0.1 if how == "outer" else 0.3,
                                    _PanelBevelDepth=0.3)
                    yield slot, base, states, extra
            kit.parts = broken
            if how == "bounds":
                bk = BOUNDS["knob"]
                BOUNDS["knob"] = None
        try:
            errors, _, _ = lk.audit()
        finally:
            if how == "bounds":
                BOUNDS["knob"] = bk
        hit = [e for e in errors if e.startswith(want + ":")]
        print(f"  {'ok  ' if hit else 'MISS'} {want:15s} {hit[0][:110] if hit else errors[:1]}")
        fails += 0 if hit else 1
    return fails


def load_spec(arg):
    p = Path(arg)
    if not p.suffix:
        p = ROOT / "Tools" / "looks" / f"{arg}.py"
    spec = importlib.util.spec_from_file_location(p.stem, p)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod.LOOK


def main(look, argv=None):
    argv = list(sys.argv[1:] if argv is None else argv)

    def opt(name, default=None):
        if name in argv:
            i = argv.index(name)
            v = argv[i + 1]
            del argv[i:i + 2]
            return v
        return default
    out_opt = opt("--out")
    root_opt = opt("--root")
    root = Path(root_opt or ROOT)
    cw = opt("--colourway")
    looks = [look]
    if cw == "all":
        looks = [look] + [look.colourway(n) for n in look.colourways]
    elif cw:
        looks = [look.colourway(cw)]
    cmd = argv[0] if argv else "check"
    which = argv[1] if len(argv) > 1 else "both"
    modes = MODES if which == "both" else (which,)
    rc = 0
    for lk in looks:
        print(f"{lk.title} ({lk.style}, {lk.cls})")
        if cmd == "check":
            errors, warns, waivers = lk.audit()
            for w in warns:
                print("  warn  ", w)
            for w in waivers:
                print("  waived", w)
            for e in errors:
                print("  ERROR ", e)
            print(f"  {len(errors)} error(s), {len(warns)} warning(s), {len(waivers)} waived")
            rc |= 1 if errors else 0
        elif cmd == "write":
            if lk.status == "example" and not root_opt:
                print("  an example spec only writes to a scratch --root")
                return 1
            errors, _, _ = lk.audit()
            if errors:
                print("  refusing to write: `check` has errors")
                return 1
            write_files(lk.files(modes), root)
        elif cmd == "recipe":
            write_files({f"Assets/Resources/UiStyles/{lk.style}.style.json": lk.recipe_text()}, root)
        elif cmd == "diff":
            rc |= 1 if diff_files(lk.files(), root) else 0
        elif cmd == "selftest":
            rc |= 1 if selftest(lk) else 0
        elif cmd == "manifest":
            p = ROOT / "Looks" / lk.slug / "look.json"
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(json.dumps(lk.manifest(), indent=2) + "\n", encoding="utf-8")
            print("  ->", p.relative_to(ROOT))
        elif cmd == "sheet":
            out = Path(out_opt or ROOT / "Looks" / lk.slug / "sheets")
            for mode in modes:
                rack_sheet(lk, mode, out / f"rack-{mode}.png")
                parts_sheet(lk, mode, out / f"parts-{mode}.png")
        else:
            print(__doc__)
            return 2
    return rc


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(2)
    sys.exit(main(load_spec(sys.argv[1]), sys.argv[2:]))
