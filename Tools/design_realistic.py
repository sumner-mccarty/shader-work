#!/usr/bin/env python3
"""
REALISTIC — boutique rack hardware, lit by one warm lamp.

A machined aluminium cap on a fluted anodised collar, a painted pointer dot, a thin bright value
arc, brushed-steel faceplates with real screws. Every part shares ONE lighting story — same
ambient, same shadow contract, same chamfer — because that is what "cohesive" means here.

WHAT THE RENDER LOOP TAUGHT THIS FILE (each measured, not guessed):

  * BEVEL DISTANCE IS THE WHOLE GAME. ~0.10 = a flat face with a milled chamfer at the edge.
    0.30+ turns any control into a sphere. The shipped skins used ~0.30, and that single number
    is most of why they read as plastic balls rather than machined parts.

  * FLAT DOES NOT READ AS METAL — CURVATURE DOES. A perfectly flat cap (`_KnobFaceSmoothness: 0`)
    gives a normal that never varies, so the Blinn-Phong specular term (`ApplyUILighting`,
    `UILighting.cginc:519-523`) is constant across the whole face: no gradient, no "sparkle", no
    sense of a directional lamp — the exact "flat plastic" complaint. A SUBTLE dome
    (`_KnobFaceSmoothness` ~0.3-0.45) curves the normal continuously across the face, which turns
    the same Blinn-Phong term into a moving highlight sweep. This is the single highest-leverage
    fix in the whole file, and it applies to every domed part: knob cap, collar, button face,
    slider/pill handle, faceplate. Verified side-by-side — flat vs domed at identical pattern/
    light settings is the difference between "sticker" and "machined part".

  * PATTERN SCALE IS A CYCLE COUNT ACROSS THE WIDGET, NOT A GRAIN SIZE — it is normalised to the
    widget's own 0-1 UV and never sees pixels. So it MUST be derived from the size the part is
    actually used at: GRAIN_PX fixes how many screen pixels one cycle should cover and every
    pattern scale here is computed from it. This is why the size-keyed roles (knob.hero vs
    knob.small) genuinely need separate skin files rather than one file used at four sizes.

  * A LARGE FLAT SURFACE WANTS LESS PATTERN, NOT MORE. The Metal pattern at panel scale reads as
    busy scratches, not brushed aluminium — real brushed metal is SUBTLE at a glance and only
    shows grain up close. Panels use a low-intensity (~0.05), coarse-scale pass, leaning on the
    face dome for the actual "this is a plate under a lamp" read.

  * MAJOR TICKS HAVE THEIR OWN COLOUR PAIR. `_OuterMarksMajorColorFilled/Unfilled` default to
    bright green and white; leave them unset and every knob grows stray green confetti ticks.

  * `_KnobNub` sits ON the cap; `_Nub` sits OUTSIDE it (composite order: Nub before Knob body,
    KnobNub after). A plain circle KnobNub reads perfectly well as a pointer once the cap actually
    looks like metal — elongated shapes (OvalPointer, DShaft) didn't visibly elongate at pointer
    scale and weren't worth the complexity.

  * BRUSHED METAL NEEDS `_XxxPatternParam1 = 0.5`. At 0.0 or 1.0 the Metal pattern (type 1) is
    mottled noise; at 0.5 it resolves into real anisotropic streaks. RadialBrushed (type 2) does
    NOT need this — it reads as lathe-turned metal on its own and is what the knob cap/collar use.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from skinlib import skin, shade, BOUNDS

P = dict(
    face="#272B31", inset="#212429", back="#141619", well="#0A1822",
    cap="#4C5259", collar="#2C3138", body="#40464E", bodyAlt="#2F353C",
    mark="#E4E9EF", dim="#7B838E", groove="#14171B",
    accent="#4FD1E0", hot="#D2544A", lamp="#6EE7A8",
)

AMBIENT = 0.60      # controls: the room's light level
AMB_PANEL = 0.48    # surfaces: deep graphite under one lamp, not flat office grey
CHAMFER = 0.10      # bevel distance — flat face, narrow milled edge
DOME = 0.34         # face curvature that makes the specular term actually move
GRAIN_PX = 8.0      # screen pixels per pattern cycle: under ~6 it aliases, over ~14 it blobs


def grain(px, per=None):
    """Pattern scale that puts one cycle every `per` screen pixels on a `px`-wide control."""
    return round(px / (per or GRAIN_PX), 1)


def shadows(prefix, cast=0.25, blur=0.6):
    """THE shadow contract: one soft contact shadow plus a wider ambient-occlusion lift, identical
    on every part, so nothing floats at a different height from its neighbour."""
    return {
        f"_{prefix}Shadow1Enabled": 1, f"_{prefix}Shadow1Color": "#000000A6",
        f"_{prefix}Shadow1Blur": blur, f"_{prefix}Shadow1Distance": 0.0,
        f"_{prefix}Shadow1Cast": cast, f"_{prefix}Shadow1Intensity": 1.0,
        f"_{prefix}Shadow2Enabled": 1, f"_{prefix}Shadow2Color": "#00000059",
        f"_{prefix}Shadow2Blur": min(blur * 2.4, 2.0), f"_{prefix}Shadow2Distance": 0.0,
        f"_{prefix}Shadow2Cast": cast * 0.8, f"_{prefix}Shadow2Intensity": 0.7,
        f"_{prefix}Shadow3Enabled": 0,
    }


# ── KNOB ─────────────────────────────────────────────────────────────────────

def knob(name, px, ticks=11, nub=0.075):
    base = {
        "_LightingAmbient": AMBIENT, "_ViewTilt": 0.0,
        "_AngleStart": 315, "_AngleRange": 270, "_Value": 0.5,

        # The fluted collar the cap sits in. A soft dished dome (not a flat disc) so its own
        # Blinn-Phong term varies too — a lathe-turned ring, not a painted circle.
        "_FillEnabled": 1, "_FillColor": P["collar"],
        # FIXED flute count, deliberately NOT derived from size. Flutes are a physical feature of
        # the part ("this knob has fourteen grips"), not a texture density — a real knob does not
        # grow more flutes when drawn larger. 14 survives every size this file is used at, from the
        # 53px Pick-a-Look tile to the 132px hero. Measured: 27 aliases into noise at tile size,
        # 7 reads as blobby scallops; 11-16 is the usable band.
        "_FillPatternEnabled": 1, "_FillPatternType": 2,
        "_FillPatternScale": 14, "_FillPatternIntensity": 0.42,
        "_FillPatternParam1": 0.55, "_FillPatternParam2": 0.15,
        "_FillBevelEnabled": 1, "_FillBevelDepth": -0.35, "_FillBevelDistance": 0.20,
        "_FillBevelSmoothness": 0.38,

        # The cap: flat FACE (chamfer stays narrow — still a milled edge, not a ball) but the
        # face itself is subtly domed, which is what makes it read as metal instead of a sticker.
        "_KnobEnabled": 1, "_KnobColor": P["cap"], "_KnobShapeType": 0, "_KnobSize": 0.62,
        "_KnobBevelEnabled": 1, "_KnobBevelDistance": CHAMFER, "_KnobBevelDepth": 0.60,
        "_KnobBevelSmoothness": 0.22, "_KnobFaceSmoothness": DOME,
        # RESTORED (2026-08-19, 4th pass): this was removed for one bad reason — a radial brush
        # converges to a point at dead centre, so at the 53px Pick-a-Look TILE the cap's middle
        # pixel cluster aliases into noise. But the tile is a secondary, momentary view; the knob
        # is drawn at 88-132px everywhere it actually lives (Mixer, every rack), and at THAT size
        # this pattern is what turns the dome from "grey plastic dome" into "lathe-turned metal" —
        # removing it made the real, everyday view worse to fix a glance-length thumbnail. Restored
        # to the values verified in the metal-read study (t-metal.png): RadialBrushed, intensity
        # 0.50. If the tile aliasing needs a separate answer later, give `knob.medium` (the specific
        # role the tile previews) a lower intensity — do not strip the whole family again.
        "_KnobPatternEnabled": 1, "_KnobPatternType": 2, "_KnobPatternScale": grain(px),
        "_KnobPatternIntensity": 0.50, "_KnobPatternParam1": 0.45, "_KnobPatternParam2": 0.2,
        "_KnobRimEnabled": 1, "_KnobRimDepth": 0.16, "_KnobRimWidth": 0.014,
        "_KnobEdgeEnabled": 1, "_KnobEdgeColor": "#0A0C0FB0", "_KnobEdgeWidth": 0.016,

        # The value arc, sunk into the collar.
        "_LineEnabled": 1, "_LineRadius": 0.86, "_LineWidth": 0.075, "_LineRoundedEnabled": 1,
        "_LineColor": P["groove"],
        "_LineSublineUnfilledEnabled": 1, "_LineSublineUnfilledColor": "#242930",
        "_LineSublineFilledEnabled": 1, "_LineSublineFilledColor": P["accent"],
        "_LineSublineFilledRenderEmissive": 0.55,

        # The painted pointer.
        "_KnobNubEnabled": 1, "_KnobNubShapeType": 0, "_KnobNubColor": P["mark"],
        "_KnobNubSize": nub, "_KnobNubDistance": 0.62, "_NubEnabled": 0,

        "_OuterMarksEnabled": 1 if ticks else 0, "_OuterMarksType": 0,
        "_OuterMarksCount": ticks or 2, "_OuterMarksAngleStart": 315,
        "_OuterMarksAngleRange": 270, "_OuterMarksRadius": 1.02,
        "_OuterMarksLength": 0.085, "_OuterMarksThickness": 0.012,
        "_OuterMarksColorUnfilled": P["dim"], "_OuterMarksColorFilled": P["accent"],
        "_OuterMarksMajorEnabled": 1, "_OuterMarksMajorInterval": 5,
        "_OuterMarksMajorLengthMultiplier": 1.6, "_OuterMarksMajorThicknessMultiplier": 1.4,
        "_OuterMarksMajorColorUnfilled": P["mark"], "_OuterMarksMajorColorFilled": P["accent"],

        "_OuterRing1Enabled": 0, "_OuterRing2Enabled": 0, "_OuterRing3Enabled": 0,
        "_EdgeEnabled": 0, "_BorderEnabled": 0,
    }
    base.update(shadows("Knob"))
    return skin(name, "Knob", base, {
        "Hover":    {"_KnobColor": shade(P["cap"], 0.10), "_KnobNubColor": "#FFFFFF"},
        "Pressed":  {"_KnobColor": shade(P["cap"], -0.10)},
        "Disabled": {"_KnobColor": shade(P["cap"], -0.30), "_KnobNubColor": P["dim"],
                     "_LineSublineFilledColor": P["dim"],
                     "_LineSublineFilledRenderEmissive": 0.0},
    }, bounds=BOUNDS["knob"])


# ── BUTTON ───────────────────────────────────────────────────────────────────

def button(name, fill, px=88, icon=None, square=0.70, icon_col=None, active=None,
           bounds_key="button", icon_size=0.30):
    base = {
        "_LightingAmbient": AMBIENT, "_ViewTilt": 0.0,
        "_ButtonEnabled": 1, "_ButtonColor": fill,
        "_ButtonShapeType": 0, "_ButtonShapeParam1": square, "_ButtonShapeParam2": 0.5,
        "_ButtonPadding": 0.18, "_ButtonRoundness": 0.0,
        "_ButtonBevelEnabled": 1, "_ButtonBevelDistance": CHAMFER, "_ButtonBevelDepth": 0.52,
        "_ButtonBevelSmoothness": 0.30, "_ButtonFaceSmoothness": 0.30,
        # ⚠ NO GRAIN. "Fine matte texture" at UI scale is a trap: the previous 1.5px-per-cycle
        # setting is BELOW the resolvable limit, so it rasterises as random per-pixel noise rather
        # than material — the "pixely" look. Swept 59 / 20 / 8 / off cycles at true tile size: off
        # is unambiguously the cleanest, and the dome + chamfer + colour already say "moulded key".
        "_ButtonPatternEnabled": 0,
        "_ButtonRimEnabled": 1, "_ButtonRimDepth": 0.22, "_ButtonRimWidth": 0.020,
        "_EdgeEnabled": 0, "_BorderEnabled": 0,
    }
    if icon is not None:
        base.update({"_IconEnabled": 1, "_IconShapeType": icon,
                     "_IconColor": icon_col or P["mark"],
                     "_IconWidth": icon_size, "_IconHeight": icon_size})
    base.update(shadows("Button"))
    states = {
        "Hover":   {"_ButtonColor": shade(fill, 0.10)},
        "Pressed": {"_ButtonColor": shade(fill, -0.12), "_ButtonBevelDepth": 0.18,
                    "_ButtonFaceSmoothness": 0.10,
                    "_ButtonShadow1Cast": 0.10, "_ButtonShadow2Cast": 0.08},
        "Disabled": {"_ButtonColor": shade(fill, -0.26), "_ButtonRimDepth": 0.06},
    }
    if icon is not None:
        states["Disabled"]["_IconColor"] = P["dim"]
    if active:
        states["Active"] = {"_ButtonColor": active, "_ButtonRimDepth": 0.28}
        if icon is not None:
            states["Active"]["_IconColor"] = "#FFFFFF"
    return skin(name, "Button", base, states, bounds=BOUNDS[bounds_key])


# ── PANEL ────────────────────────────────────────────────────────────────────

def panel(name, fill, px=260, screws=False, recess=False, glow=None, rim=0.12):
    base = {
        "_LightingAmbient": AMB_PANEL,
        "_PanelEnabled": 1, "_PanelColor": fill,
        "_PanelShapeType": 0, "_PanelShapeParam1": 0.88, "_PanelPadding": 0.06,
        "_PanelFaceSize": 0.99,
        # Bevel depth is deliberately TINY. The chamfer is only ~4px wide, so a large depth tilts
        # its normal almost vertically and the lamp-facing edge blows out into a hard chrome bar
        # down one side — the "hard line" complaint, confirmed by additive isolation (bar appears
        # exactly when the bevel is switched on, at every distance). At ~0.07 it reads as a subtle
        # machined edge instead. Do NOT widen `_PanelBevelDistance` to soften it: past ~0.15 the
        # bevel band starts crossing the rounded rect's medial axis and the diagonal corner wedges
        # come back.
        # BEVEL OFF on plates. The chamfer is only a few pixels wide, so ANY depth blows its
        # lamp-facing edge into a hard bright bar (confirmed by additive isolation: the bar appears
        # exactly when the bevel is enabled, at every depth and distance tried), and widening it to
        # soften the normal instead drags the band across the rounded rect's medial axis and brings
        # back the diagonal corner wedges. A plate does not need it: the rounded silhouette plus
        # the drop shadow already read as a physical panel sitting on the backplane.
        "_PanelBevelEnabled": 0,
        # ⚠ _PanelFaceSmoothness MUST STAY 0 ON A RECTANGULAR PANEL.
        # The face dome takes its normal from the SDF gradient, and a rounded rect's gradient is
        # DISCONTINUOUS along its medial axis — the 45-degree diagonals running in from each
        # corner. Any nonzero value stamps hard diagonal wedges across the plate (visible at 0.05,
        # ugly by 0.15). It is a geometry artifact, not a lighting effect, and no amount of colour
        # or pattern tuning hides it. Curvature is the right tool for a KNOB CAP — a circle has no
        # medial axis — and the wrong tool for a plate. A plate gets its material read from the
        # GRADIENT below, which is evaluated in UV space and has no such discontinuity.
        "_PanelFaceSmoothness": 0.0,
        "_PanelPatternEnabled": 1, "_PanelPatternType": 1,
        # Grain pixel-locked (2026-10-04): tuned at `px`, so one tile = px canvas units and the
        # brushing stays the same density on a 60-unit strip and a 1200-unit rack.
        "_PanelPatternScale": 70, "_PanelPatternPx": px, "_PanelPatternIntensity": 0.028,
        "_PanelPatternParam1": 0.5, "_PanelPatternParam2": 0.95, "_PanelPatternParam3": 0.08,
        # ⚠ RIM OFF. `_PanelRim` is a lit bevel ring at the very silhouette, and against this
        # light rig it resolves into a hard, near-white CHROME BAR down one edge — the "hard line"
        # complaint. Isolation confirmed it: turning the rim off is what removes the bar. The main
        # bevel already gives the plate its edge, so the rim buys nothing but the artifact.
        "_PanelRimEnabled": 0,
        # The plate's entire "lit from above" read. Gradient position is dot(uv, dir), and uv.y is
        # 0 at the BOTTOM, so with dir (0,1) position 0 is the bottom edge: ColorA is the BOTTOM
        # colour and ColorB the top. Light therefore belongs in B. (Flipping the direction to
        # (0,-1) instead drives the position negative, which clamps and renders the plate black.)
        "_PanelGradientEnabled": 1, "_PanelGradientType": 0, "_PanelGradientColorUsed": 2,
        "_PanelGradientColorA": shade(fill, -0.13), "_PanelGradientColorB": shade(fill, 0.15),
        "_PanelGradientDirection": (0, 1, 0, 0),
        # Corner hardware. Inset/radius are in PADDING UNITS measured from the plate's own
        # corner (not screen pixels from the quad's), so the bolts hold the corner down at any
        # plate size — see CG/SDF/SDFPanelScrews.cginc.
        "_PanelScrewsEnabled": 1 if screws else 0,
        "_PanelScrewShapeType": 0, "_PanelScrewInset": 0.13, "_PanelScrewRadius": 0.058,
        "_PanelScrewColor": "#9BA1AB", "_PanelScrewSlotColor": "#15171C",
        "_PanelScrewRotation": 32, "_PanelScrewDepth": 0.85, "_PanelScrewMetallic": 0.85,
        "_EdgeEnabled": 0, "_BorderEnabled": 0,
    }
    if glow:
        base.update({"_PanelColor": glow, "_PanelRenderEmissive": 0.30,
                     "_PanelPatternEnabled": 0,
                     "_PanelGradientColorA": shade(glow, 0.16),
                     "_PanelGradientColorB": shade(glow, -0.30)})
    return skin(name, "Panel", base, bounds=BOUNDS["panel"])


# ── SLIDER ───────────────────────────────────────────────────────────────────

def slider(name, px=240):
    base = {
        "_LightingAmbient": AMBIENT, "_ViewTilt": 0.0, "_Value": 0.5,
        # The recessed well the slot is cut into.
        "_BgEnabled": 1, "_BgColor": "#141719", "_BgShapeType": 0, "_BgShapeParam1": 0.75,
        "_BgPadding": 0.10,
        "_BgBevelEnabled": 1, "_BgBevelDepth": -0.70, "_BgBevelDistance": 0.09,
        "_BgBevelSmoothness": 0.25, "_BgFaceSmoothness": 0.10,
        "_BgPatternEnabled": 1, "_BgPatternType": 1, "_BgPatternScale": 24,
        "_BgPatternIntensity": 0.05, "_BgPatternParam1": 0.5, "_BgPatternParam2": 0.9,

        # The slot.
        "_TrackEnabled": 1, "_TrackColor": P["groove"], "_TrackWidth": 0.16,
        "_TrackExtension": 0.0, "_TrackValueZeroPoint": 0.0,
        "_TrackValueFilledEnabled": 1, "_TrackValueFilledColor": P["accent"],
        "_TrackValueFilledRenderEmissive": 0.5,
        "_TrackValueUnfilledEnabled": 1, "_TrackValueUnfilledColor": "#20252B",

        # The cap — the knob's chamfer + dome, so they read as one family.
        "_HandleEnabled": 1, "_HandleColor": P["cap"], "_HandleShapeType": 0,
        # _HandleHeight is the cross-axis size and is the property that makes a fader cap a CAP.
        # Without it the handle is a thin sliver lying along the track: _HandleWidth only extends
        # it along the travel axis, in equi-pixel units where the SHORT side of the widget = 2.0.
        "_HandleWidth": 0.26, "_HandleHeight": 0.92, "_HandlePadding": 0.5,
        "_HandleBevelEnabled": 1, "_HandleBevelDistance": CHAMFER, "_HandleBevelDepth": 0.55,
        "_HandleBevelSmoothness": 0.22, "_HandleFaceSmoothness": DOME,
        # RESTORED with the knob cap — same reasoning: the fader cap is used at 240px-wide-widget
        # scale (never the 53px tile), so the same metal read applies.
        "_HandlePatternEnabled": 1, "_HandlePatternType": 2, "_HandlePatternScale": 9,
        "_HandlePatternIntensity": 0.45, "_HandlePatternParam1": 0.5,
        "_HandleRimEnabled": 1, "_HandleRimDepth": 0.16, "_HandleRimWidth": 0.014,
        "_EdgeEnabled": 0, "_BorderEnabled": 0,
    }
    base.update(shadows("Handle"))
    return skin(name, "Slider", base, {
        "Hover":   {"_HandleColor": shade(P["cap"], 0.10)},
        "Pressed": {"_HandleColor": shade(P["cap"], -0.10)},
        "Disabled": {"_HandleColor": shade(P["cap"], -0.30),
                     "_TrackValueFilledColor": P["dim"],
                     "_TrackValueFilledRenderEmissive": 0.0},
    }, bounds=BOUNDS["slider"])


# ── TOGGLE PILL ──────────────────────────────────────────────────────────────

def pill(name):
    base = {
        "_LightingAmbient": AMBIENT, "_Value": 0.0, "_StateCount": 2,
        "_BgEnabled": 1, "_BgColor": P["inset"], "_BgPadding": 0.05,
        "_BgBevelEnabled": 1, "_BgBevelDepth": -0.40, "_BgBevelDistance": 0.16,
        "_TrackEnabled": 1, "_TrackColor": P["groove"],
        "_HandleEnabled": 1, "_HandleColor": P["cap"], "_HandlePadding": 0.26, "_HandleFaceEnabled": 0,
        "_HandleBevelEnabled": 1, "_HandleBevelDistance": 0.14, "_HandleBevelDepth": 0.55,
        "_HandleBevelSmoothness": 0.22, "_HandleFaceSmoothness": 0.30,
        "_HandlePatternEnabled": 0,
        "_HandleRimEnabled": 1, "_HandleRimDepth": 0.16, "_HandleRimWidth": 0.016,
        # The track cannot recolour with _Value, so ON is said by the handle tinting to the LED
        # colour. The bloom is deliberately tiny — at the shader's default radius it swallows the
        # whole control and you can no longer see which end the handle is at.
        "_LedEnabled": 0, "_LedColor": P["accent"], "_LedIntensity": 0.0,
        "_LedSurfaceBlend": 1.0, "_LedGlowRadius": 0.06, "_LedGlowSharpness": 0.8,
        "_EdgeEnabled": 0, "_BorderEnabled": 0,
    }
    base.update(shadows("Toggle"))
    return skin(name, "Toggle", base, {
        "Hover":   {"_HandleColor": shade(P["cap"], 0.10)},
        "Pressed": {"_HandleColor": shade(P["cap"], -0.10)},
        "Disabled": {"_HandleColor": shade(P["cap"], -0.30), "_LedIntensity": 0.0,
                     "_LedSurfaceBlend": 0.0},
    }, bounds=BOUNDS["pill"])


def build():
    knob("RealisticKnobHero",  132, ticks=11, nub=0.070)
    knob("RealisticKnob",       88, ticks=11, nub=0.080)
    knob("RealisticKnobSmall",  60, ticks=0,  nub=0.100)
    button("RealisticButton",    P["body"],    px=88)
    button("RealisticPad",       P["bodyAlt"], px=96, square=0.60)
    button("RealisticAccent",    P["accent"],  px=88, icon=6, icon_col="#06232A",
           bounds_key="button_accent")
    button("RealisticToggleBtn", P["bodyAlt"], px=88, icon=18, active=P["hot"],
           bounds_key="button_round")
    button("RealisticClose",     P["bodyAlt"], px=56, icon=19, bounds_key="button_round")
    button("RealisticLamp",      "#17241F",    px=36, icon=29, icon_col=P["lamp"],
           icon_size=0.90, square=0.0, active=P["lamp"], bounds_key="button_round")
    slider("RealisticSlider")
    pill("RealisticPill")
    panel("RealisticFace",  P["face"],  260, screws=True)
    panel("RealisticInset", P["inset"], 200, recess=True)
    panel("RealisticBack",  P["back"],  240, recess=True, rim=0.06)
    panel("RealisticWell",  P["well"],  200, recess=True, glow=P["well"])


if __name__ == "__main__":
    build()
    print("built Realistic set")
