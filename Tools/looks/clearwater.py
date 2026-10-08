"""Clearwater — modern translucent glass (lit, Materials v2 glass). Brief: Looks/BACKLOG.md#clearwater.

    python Tools/looks/clearwater.py check | sheet | write | manifest | printcheck

Signature: you can SEE THROUGH it. The look names a wallpaper per mode (`backdrop`); every plate, key,
knob cap and handle is an opaque body wearing the glass term, which replaces the body colour with the
wallpaper behind the part — blurred by the frosted plates, bent at every curved edge, ringed by a
bright fresnel rim and finished with a clear-coat highlight. One strong accent lights the ON state.
Dark = aurora wallpaper under smoked glass; light = a pale pastel wallpaper (Daybreak) under milk glass.

How the glass term composes (CG/Core/UIMaterials.cginc): pixel = lerp(lit body, wallpaper * tint, strength)
+ fresnel rim, then the matcap on top. So at strength ~0.9 the body colour and the lamp rig are 10% of the
pixel: hover / pressed / ON / disabled therefore move RIM, TINT and STRENGTH (the `states` blocks below),
not the body colour the kit's default state deltas write.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from lookkit import Look, main  # noqa: E402

ACCENT = "#FFA24A"           # the one strong colour: ON, value arcs, focus — warm amber against cold glass


def glass(strength, blur, refract, tint, rim):
    return dict(strength=strength, blur=blur, refract=refract, tint=tint, rim=rim)


# ── dark: smoked glass over the aurora ───────────────────────────────────────────────────────────────
# Two glasses, like a modern translucent UI: PLATES are frosted (blurred, a dim smoke so print holds) and
# CONTROLS are liquid lenses — almost no blur, a deep rounded edge, strong refraction, so the wallpaper
# is clear in the middle of a key and bends hard at its rim (a droplet), ringed by a bright fresnel line.
DARK_PLATE = {"preset": "glass.frosted", "glass": glass(0.92, 3.5, 0.12, "#8CA8B4FF", 0.3), "matcap": ("glass_rim", 0.2)}
DARK_KEY = {"preset": "glass.clear", "glass": glass(0.94, 0.4, 0.28, "#728997FF", 0.8), "matcap": ("glass_rim", 0.35),
            "bevel": (0.14, 0.6, 0.6), "dome": 0.6}
# ── light: milk glass over Daybreak ──────────────────────────────────────────────────────────────────
LIGHT_PLATE = {"preset": "glass.frosted", "glass": glass(0.9, 3.5, 0.12, "#E2EBF2FF", 0.12), "matcap": ("glass_rim", 0.15)}
LIGHT_KEY = {"preset": "glass.clear", "glass": glass(0.94, 0.4, 0.28, "#DCE6EEFF", 0.55), "matcap": ("glass_rim", 0.3),
             "bevel": (0.14, 0.6, 0.6), "dome": 0.6}

# ON: tinted glass. Strength ~0.45 lets the accent body colour carry half the pixel, the wallpaper the rest.
ACCENT_GLASS = glass(0.3, 0.4, 0.28, "#FFE2BCFF", 0.8)

# BODY/CAP/HANDLE are the colour of the ~10% of a glass pixel that is not wallpaper, AND the proxy every
# print pair is checked against. They sit at one mid-tone (L ~0.21) in BOTH modes so white print (dark)
# and navy print (light) each clear 3:1 on it (3.85 / 3.46); the real glass pixel is smoked or milk.
CONTROLS = dict(
    BODY="#5C849A", ACCENT=ACCENT, SOLO="#FFD27A", LAMP="#FFD9A0", HOT="#FF6A7A",
    CAP="#5C849A", SKIRT="#4C7388", NUB="#F4FBFF", VALUE="#FFC878", VALUE_EM=0.35, AMB_ACCENT=0.95,
    HANDLE="#5C849A", SCROLL="#4C7388", SCROLL_HI=ACCENT, PAD_BODY="#4A7F96", PAD_TINT=0.7,
)

# ── the wallpapers: PROCEDURAL, animated, tunable (Assets/Shaders/Backdrop*.shader, see UIBackdropFlow.cginc) ──
# A host renders this skin into the texture the glass samples, every frame; `backdrop` (a tileable PNG) stays as
# the fallback for a host that cannot. Both shaders are exactly periodic: the loop lasts 1 / _Speed seconds.
# Tuned for LEGIBILITY first: the brightest thing that can ever pass behind print stays dim (dark) or pale
# (light), so the print contrast the flow demo measures holds at every moment of the loop.
DARK_FX = dict(shader="Caustics", time=9.0, params={
    "_Speed": 0.05, "_Scale": 1.7, "_Warp": 0.7, "_Detail": 3, "_FieldScale": 0.9,
    "_ColorA": "#000A17", "_ColorB": "#0A4778", "_ColorC": "#15658A", "_ColorD": "#512AB0", "_PoolAmount": 0.65,
    "_LineColor": "#45B6CC", "_LineStrength": 0.30, "_LineWidth": 0.26, "_LineLayers": 2, "_Depth": 0.5,
    "_Brightness": -0.02, "_Contrast": 1.0, "_Saturation": 1.05, "_Vignette": 0.3})
LIGHT_FX = dict(shader="Splotch", time=9.0, params={
    "_Speed": 0.05, "_Seed": 3, "_Count": 7, "_Size": 0.24, "_SizeVar": 0.55, "_Spread": 1.0, "_Drift": 0.14,
    "_Softness": 0.14, "_Warp": 0.22, "_WarpScale": 2.4, "_Opacity": 0.9, "_Merge": 0.0,
    "_Base": "#B6CDE6", "_ColorA": "#80CEB4", "_ColorB": "#88A8EA", "_ColorC": "#B496E6", "_ColorD": "#EC98AC",
    "_ColorFlow": 0.5, "_EdgeShade": 0.0, "_Brightness": -0.03, "_Contrast": 1.0, "_Saturation": 1.0, "_Vignette": 0.0})

# Glass state grammar: the body colour is only ~10% of a glass pixel, so a state has to move the RIM, the
# TINT or the STRENGTH. (Group "key" covers every button-shaped part; "dial" the knobs; "fader" the handles.)
def key_states(hover_tint, press_tint, on_tint):
    return {
        "key": {
            "Hover": {"_ButtonGlassRim": 1.7, "_ButtonGlassTint": hover_tint, "_ButtonGlassStrength": 0.82, "_ButtonGlassRefract": 0.34},
            "Pressed": {"_ButtonGlassRim": 0.6, "_ButtonGlassTint": press_tint, "_ButtonGlassStrength": 0.96, "_ButtonGlassRefract": 0.4},
            "Disabled": {"_ButtonGlassRim": 0.3, "_ButtonGlassStrength": 0.85, "_ButtonGlassRefract": 0.1, "_ButtonRenderAlpha": 0.6},
        },
        "ToggleBtn": {"Active": {"_ButtonGlassTint": on_tint, "_ButtonGlassStrength": 0.3, "_ButtonGlassRim": 1.1}},
        "Solo": {"Active": {"_ButtonGlassTint": on_tint, "_ButtonGlassStrength": 0.3, "_ButtonGlassRim": 1.1}},
        "Lamp": {"Active": {"_ButtonGlassTint": on_tint, "_ButtonGlassStrength": 0.3, "_ButtonGlassRim": 1.1}},
        "Accent": {"Hover": {"_ButtonGlassRim": 1.6, "_ButtonGlassStrength": 0.3},
                   "Pressed": {"_ButtonGlassRim": 0.5, "_ButtonGlassStrength": 0.3}},
        "dial": {"Hover": {"_KnobGlassRim": 1.7, "_KnobGlassStrength": 0.82, "_KnobGlassRefract": 0.34},
                 "Pressed": {"_KnobGlassRim": 0.6, "_KnobGlassStrength": 0.96, "_KnobGlassRefract": 0.42},
                 "Disabled": {"_KnobGlassStrength": 0.5, "_KnobGlassRim": 0.25}},
        "fader": {"Hover": {"_HandleGlassRim": 1.7, "_HandleGlassStrength": 0.82, "_HandleGlassRefract": 0.34},
                  "Pressed": {"_HandleGlassRim": 0.6, "_HandleGlassRefract": 0.42},
                  "Disabled": {"_HandleGlassStrength": 0.5, "_HandleGlassRim": 0.25}},
        "Pad": {"Hover": {"_ButtonGlassRim": 1.6},
                "Pressed": {"_ButtonGlassRim": 0.4, "_ButtonGlassStrength": 0.5},
                "Latched": {"_ButtonGlassRim": 1.4, "_ButtonGlassStrength": 0.45},
                "Disabled": {"_ButtonGlassStrength": 0.4}},
    }


# Glass plates need a curved edge for the refraction and fresnel rim to catch. The kit writes a soft
# rounded bevel (distance 0.12 <= the 0.14 medial-axis limit, depth 0.35, smoothness 0.9) on any glass
# plate; the rim band IS the look's signature, not a chrome bar, so the outermost plates are waived.
GLASS_EDGE = "glass plates need a soft rounded edge for refraction + the fresnel rim (bevel 0.12, depth 0.35, smooth 0.9)"

LOOK = Look(
    title="Clearwater", style="Clearwater", prefix="Clearwater", slug="clearwater", cls="lit", order=24,
    status="candidate", brief="clearwater/NOTES.md",
    blurb="Translucent glass over a wallpaper: blurred, bent, rimmed in light.",
    tagline="see-through glass over a wallpaper — frosted plates, clear keys, bright rims.",
    displays="neo",
    shape={
        "key": dict(corner=0.0, round=0.4),                # corner 0 = a pill/capsule (1 = a sharp rectangle)
        "Pad": dict(corner=0.3, round=0.5), "Lamp": dict(corner=0.0, round=0.4),
        "dial": dict(skirt="Circle", cap_r=0.7, bevel=0.2, depth=0.5, smooth=1.0, dome=0.8,
                     nub=0.06, nub_dist=0.5, arc_px=3.0),
        "fader": dict(corner=0.0, bevel=0.2, depth=0.8, smooth=1.0, dome=0.55),
        "plate": dict(radius_px=10.0),
        "Face": dict(radius_px=12.0), "Back": dict(radius_px=1.0),
        "KnobHero": dict(ticks=0, arc_px=4.0),
        "shadow": dict(blur=2.2, cast=0.18),
    },
    material={
        "plate": DARK_PLATE,
        "key": DARK_KEY,
        # the LEARN chip sits under the brightest part of the wallpaper: a hair more smoke keeps its label >= 3:1 all loop
        "Chip": dict(DARK_KEY, glass=glass(0.94, 0.4, 0.28, "#667F8EFF", 0.8)),
        "accent": dict(DARK_KEY, tint=ACCENT, glass=ACCENT_GLASS),
        "cap": DARK_KEY,
        "skirt": dict(DARK_PLATE, matcap=None),
        "handle": DARK_KEY,
        "pad": dict(DARK_KEY, glass=glass(0.66, 0.4, 0.28, "#C8DCE8FF", 0.7)),
    },
    rig={
        # glass takes its light from the wallpaper and the matcap; the lamps only fill the ~10% of the
        # body colour that survives, so the rig stays soft and cool
        "dark": {"light1": dict(pos=[-0.3, 1.6], height=1.2, color="#EAFBFF", intensity=0.8, specular=0.45,
                                specularPower=64),
                 "light2": dict(pos=[0.9, -0.4], height=0.8, color="#6FE0D8", intensity=0.18, specular=0.1,
                                specularPower=32),
                 "light3": dict(enabled=False)},
        "light": {"light1": dict(pos=[-1.5, 3.0], height=4.0, color="#F4FFFF", intensity=0.7, specular=0.3,
                                 specularPower=64),
                  "light2": dict(enabled=False), "light3": dict(enabled=False)},
    },
    waive={f"outer-bevel:Clearwater{m}{s}": GLASS_EDGE for m in ("Dark", "Light") for s in ("Face", "Back")},
    modes={
        "dark": dict(
            track="Aurora", backdrop="Backdrops/Lagoon", backdrop_fx=DARK_FX, blurb="Smoked glass over a drifting lagoon.",
            states=key_states(hover_tint="#8AA2AFFF", press_tint="#8CA6B2FF", on_tint="#FFB866FF"),
            palette=dict(CONTROLS, GAP="#04252A", BACK="#1D3F4A", FACE="#2B5662", INSET="#244A55", SOCKET="#21444F",
                         WELL="#03191C", SHADOW="#00161A", SHADOW_A=0.55, AMB_PLATE=0.55, WELL_EM=0.1,
                         MARK="#F4FBFF", MARK_DIM="#DCEBF2", DIS_MARK="#8FA9B6", ON_MARK="#2B1400",
                         LAMP_OFF="#A6C4D2", ARC_OFF="#0D2A3A", TRACK="#082030"),
            app=dict(display=dict(text="#9FFFF4", textDim="#4FA7A8", textAlt="#E8FFFD"),
                     ink=dict(faceplate="#EFFFFE", faceplateDim="#D6F0F0", inset="#EFFFFE", insetDim="#D6F0F0",
                              backplane="#EFFFFE", backplaneDim="#D6F0F0", socket="#EFFFFE", socketDim="#D6F0F0",
                              reviewBar="#EFFFFE", reviewBarDim="#D6F0F0"))),
        "light": dict(
            track="Rosewater", backdrop="Backdrops/Daybreak", backdrop_fx=LIGHT_FX, blurb="Milk glass over a pastel daybreak.",
            states=key_states(hover_tint="#FFFFFFFF", press_tint="#C4D4E0FF", on_tint="#FFB866FF"),
            material={"plate": LIGHT_PLATE, "key": LIGHT_KEY, "Chip": LIGHT_KEY, "accent": dict(LIGHT_KEY, tint=ACCENT, glass=ACCENT_GLASS),
                      "cap": LIGHT_KEY, "skirt": dict(LIGHT_PLATE, matcap=None), "handle": LIGHT_KEY,
                      "pad": dict(LIGHT_KEY, glass=glass(0.72, 0.4, 0.28, "#F4F8FCFF", 0.35))},
            palette=dict(CONTROLS, GAP="#C4E0DC", BACK="#D8ECE8", FACE="#E8F4F1", INSET="#DDEEEA", SOCKET="#DAEBE7",
                         WELL="#062A2E", SHADOW="#2E5C6E", SHADOW_A=0.5, AMB_PLATE=0.5, WELL_EM=0.1,
                         MARK="#10303C", MARK_DIM="#244A59", DIS_MARK="#8DA6B2", ON_MARK="#2B1400", DIS_BODY="#A9BFCD",
                         LAMP_OFF="#6F95A3", ARC_OFF="#1F3743", TRACK="#243E4C",
                         # values stay readable on a pale plate: a deep orange fill (3.65:1 on its dark track,
                         # 2.1:1 on the plate; the old pale amber was 1.08:1 on the plate)
                         VALUE="#E67D00", VALUE_EM=0.0),
            app=dict(display=dict(text="#9FFFF4", textDim="#4FA7A8", textAlt="#E8FFFD"),
                     ui=dict(text="#10303C", textDim="#2A5361", accent="#11857A"),
                     ink=dict(faceplate="#10303C", faceplateDim="#27505E", inset="#10303C", insetDim="#27505E",
                              backplane="#10303C", backplaneDim="#27505E", socket="#10303C", socketDim="#27505E",
                              reviewBar="#10303C", reviewBarDim="#27505E"))),
    },
)

if __name__ == "__main__":
    sys.exit(main(LOOK))
