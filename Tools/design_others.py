#!/usr/bin/env python3
"""
NEOMORPHIC / TRON / FLAT — the other three shipped looks.

Each is a different answer to "where does form come from?", and that is what actually makes them
look different rather than recoloured:

  NEOMORPHIC — form comes ONLY from light. Every part is the same colour as the panel it sits on;
    nothing has a border, nothing has a pattern, and you can tell a knob from its background purely
    because it is domed and casts. This is the one style where a WIDE bevel is correct — clay is
    extruded, not machined — so it deliberately breaks Realistic's chamfer rule.

  TRON — form comes ONLY from edges. Unlit: bevels off, patterns off, bodies nearly black. What you
    see is borders, rings and arcs, all emissive. Value is the brightest thing on screen.

  FLAT — form comes ONLY from area and contrast. No bevel, no shadow, no gradient, no glow. Solid
    fills, one flat border, maximum legibility. It should look like a tool, not a photograph.

NOTE ON "UNLIT": the shaders have no lighting opt-out. With bevels and patterns off the surface
normal is constant, so the rig cannot SHAPE the surface, but it still adds a flat amount of light.
Tron and Flat therefore author their ambient low to compensate. A real `_LightingEnabled` guard
would be both more faithful and cheaper — it is on the shader-request list.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from skinlib import skin, shade, BOUNDS

# ═══════════════════════════════════════════════════════════════════════════════
# NEOMORPHIC
# ═══════════════════════════════════════════════════════════════════════════════

N = dict(
    face="#31353C", inset="#2C3037", back="#282C32", well="#2A2E35",
    body="#31353C",                 # THE point: identical to the face
    mark="#C7CFDA", dim="#767E8A",
    accent="#37D6C4", hot="#E8705F", lamp="#7EE8B0",
)
N_AMB = 0.78
DOME = 0.42          # wide bevel — moulded, not milled


def n_shadows(prefix, cast=0.55, blur=1.0):
    """Neomorphic lives or dies on the shadow: long, soft, low-contrast."""
    return {
        f"_{prefix}Shadow1Enabled": 1, f"_{prefix}Shadow1Color": "#12151999",
        f"_{prefix}Shadow1Blur": blur, f"_{prefix}Shadow1Distance": 0.0,
        f"_{prefix}Shadow1Cast": cast, f"_{prefix}Shadow1Intensity": 1.0,
        f"_{prefix}Shadow2Enabled": 1, f"_{prefix}Shadow2Color": "#0D0F1266",
        f"_{prefix}Shadow2Blur": min(blur * 2.0, 2.0), f"_{prefix}Shadow2Distance": 0.0,
        f"_{prefix}Shadow2Cast": cast * 0.9, f"_{prefix}Shadow2Intensity": 0.8,
        f"_{prefix}Shadow3Enabled": 0,
    }


def neo_knob(name, ticks=0, nub=0.085):
    base = {
        "_LightingAmbient": N_AMB, "_ViewTilt": 0.0,
        "_AngleStart": 315, "_AngleRange": 270, "_Value": 0.5,
        # A shallow dish pressed into the panel, same material throughout.
        "_FillEnabled": 1, "_FillColor": N["face"], "_FillPatternEnabled": 0,
        "_FillBevelEnabled": 1, "_FillBevelDepth": -0.55, "_FillBevelDistance": 0.22,
        "_FillBevelSmoothness": 0.7,
        # The dome.
        "_KnobEnabled": 1, "_KnobColor": N["body"], "_KnobShapeType": 0, "_KnobSize": 0.60,
        "_KnobBevelEnabled": 1, "_KnobBevelDistance": DOME, "_KnobBevelDepth": 0.95,
        "_KnobBevelSmoothness": 0.85, "_KnobFaceSmoothness": 0.30,
        "_KnobPatternEnabled": 0, "_KnobRimEnabled": 0, "_KnobEdgeEnabled": 0,
        # One glowing arc — the only colour in the whole style.
        "_LineEnabled": 1, "_LineRadius": 0.88, "_LineWidth": 0.055, "_LineRoundedEnabled": 1,
        "_LineColor": N["inset"],
        "_LineSublineUnfilledEnabled": 1, "_LineSublineUnfilledColor": "#272B31",
        "_LineSublineFilledEnabled": 1, "_LineSublineFilledColor": N["accent"],
        "_LineSublineFilledRenderEmissive": 0.55,
        "_LineSublineGlowEnabled": 1, "_LineSublineGlowColor": N["accent"] + "",
        "_LineSublineGlowWidth": 0.022, "_LineSublineGlowSoftness": 0.7,
        "_LineSublineGlowIntensity": 0.30, "_LineSublineGlowRenderEmissive": 1.0,
        # A soft dimple, not a painted mark.
        "_KnobNubEnabled": 1, "_KnobNubShapeType": 0, "_KnobNubColor": N["mark"],
        "_KnobNubSize": nub, "_KnobNubDistance": 0.58, "_NubEnabled": 0,
        "_OuterMarksEnabled": 0, "_OuterRing1Enabled": 0,
        "_OuterRing2Enabled": 0, "_OuterRing3Enabled": 0,
        "_EdgeEnabled": 0, "_BorderEnabled": 0,
    }
    base.update(n_shadows("Knob"))
    return skin(name, "Knob", base, {
        "Hover":   {"_KnobColor": shade(N["body"], 0.06)},
        "Pressed": {"_KnobColor": shade(N["body"], -0.08), "_KnobBevelDepth": 0.45},
        "Disabled": {"_KnobColor": shade(N["body"], -0.10), "_KnobNubColor": N["dim"],
                     "_LineSublineFilledColor": N["dim"],
                     "_LineSublineFilledRenderEmissive": 0.0,
                     "_LineSublineGlowEnabled": 0},
    }, bounds=BOUNDS["knob"])


def neo_button(name, fill=None, icon=None, icon_col=None, active=None, square=0.30,
               bounds_key="button", icon_size=0.30):
    fill = fill or N["body"]
    base = {
        "_LightingAmbient": N_AMB, "_ViewTilt": 0.0,
        "_ButtonEnabled": 1, "_ButtonColor": fill,
        "_ButtonShapeType": 0, "_ButtonShapeParam1": square, "_ButtonShapeParam2": 0.5,
        "_ButtonPadding": 0.20, "_ButtonRoundness": 0.32,
        "_ButtonBevelEnabled": 1, "_ButtonBevelDistance": 0.26, "_ButtonBevelDepth": 0.70,
        "_ButtonBevelSmoothness": 0.85, "_ButtonFaceSmoothness": 0.25,
        "_ButtonPatternEnabled": 0, "_ButtonRimEnabled": 0,
        "_EdgeEnabled": 0, "_BorderEnabled": 0,
    }
    if icon is not None:
        base.update({"_IconEnabled": 1, "_IconShapeType": icon,
                     "_IconColor": icon_col or N["dim"],
                     "_IconWidth": icon_size, "_IconHeight": icon_size})
    base.update(n_shadows("Button", cast=0.5, blur=0.9))
    states = {
        "Hover":   {"_ButtonColor": shade(fill, 0.05)},
        # Pressed INVERTS the extrusion — the key sinks into the panel. This is the whole
        # interaction language of the style; a colour change would say nothing here.
        "Pressed": {"_ButtonBevelDepth": -0.65, "_ButtonColor": shade(fill, -0.04)},
        "Disabled": {"_ButtonColor": shade(fill, -0.06), "_ButtonBevelDepth": 0.25},
    }
    if icon is not None:
        states["Disabled"]["_IconColor"] = shade(N["dim"], -0.25)
    if active:
        states["Active"] = {"_ButtonColor": active, "_ButtonBevelDepth": -0.45}
        if icon is not None:
            states["Active"]["_IconColor"] = "#FFFFFF"
    return skin(name, "Button", base, states, bounds=BOUNDS[bounds_key])


def neo_panel(name, fill, recess=False, glow=None):
    base = {
        "_LightingAmbient": 0.92,
        "_PanelEnabled": 1, "_PanelColor": fill,
        "_PanelShapeType": 0, "_PanelShapeParam1": 0.80, "_PanelPadding": 0.06,
        "_PanelFaceSize": 0.99,
        # ⚠ Bevel distance capped at 0.12. Neomorphic wants a soft pillow, but past ~0.15 the
        # bevel band crosses the rounded rect's MEDIAL AXIS (the 45-degree diagonals in from each
        # corner), where the SDF gradient the bevel normal is built from is discontinuous — and the
        # plate grows hard diagonal wedges in all four corners. Measured: 0.22 wedges badly, 0.14
        # is clean. Softness comes from the high smoothness, not from a wide band.
        # Only RECESSED plates bevel. A raised bevel on the outermost face is the same failure the
        # Realistic plates had — the lamp-facing edge blows out into a bright bar down one side —
        # and the outer face is the backdrop everything sits on, so it gains nothing from one.
        # Recessed insets keep theirs: a dish reads as a dish only if its wall catches light.
        "_PanelBevelEnabled": 1 if recess else 0, "_PanelBevelDistance": 0.12,
        "_PanelBevelDepth": -0.14, "_PanelBevelSmoothness": 0.8,
        "_PanelPatternEnabled": 0, "_PanelRimEnabled": 0,
        "_PanelGradientEnabled": 0, "_PanelScrewsEnabled": 0,
        "_EdgeEnabled": 0, "_BorderEnabled": 0,
    }
    if glow:
        base.update({"_PanelColor": glow, "_PanelRenderEmissive": 0.18})
    return skin(name, "Panel", base, bounds=BOUNDS["panel"])


def neo_slider(name):
    base = {
        "_LightingAmbient": N_AMB, "_ViewTilt": 0.0, "_Value": 0.5,
        "_BgEnabled": 1, "_BgColor": N["face"], "_BgShapeType": 0, "_BgShapeParam1": 0.55,
        "_BgPadding": 0.08, "_BgPatternEnabled": 0,
        "_BgBevelEnabled": 1, "_BgBevelDepth": -0.55, "_BgBevelDistance": 0.30,
        "_BgBevelSmoothness": 0.8,
        "_TrackEnabled": 1, "_TrackColor": "#272B31", "_TrackWidth": 0.14,
        "_TrackValueZeroPoint": 0.0,
        "_TrackValueFilledEnabled": 1, "_TrackValueFilledColor": N["accent"],
        "_TrackValueFilledRenderEmissive": 0.8,
        "_TrackValueUnfilledEnabled": 1, "_TrackValueUnfilledColor": "#272B31",
        "_HandleEnabled": 1, "_HandleColor": N["body"], "_HandleShapeType": 0,
        "_HandleWidth": 0.30, "_HandleHeight": 0.86, "_HandlePadding": 0.5,
        "_HandleBevelEnabled": 1, "_HandleBevelDistance": 0.30, "_HandleBevelDepth": 0.80,
        "_HandleBevelSmoothness": 0.85, "_HandleFaceSmoothness": 0.25,
        "_HandlePatternEnabled": 0, "_HandleRimEnabled": 0,
        "_EdgeEnabled": 0, "_BorderEnabled": 0,
    }
    base.update(n_shadows("Handle", cast=0.5, blur=0.9))
    return skin(name, "Slider", base, {
        "Hover":   {"_HandleColor": shade(N["body"], 0.06)},
        "Pressed": {"_HandleColor": shade(N["body"], -0.06)},
        "Disabled": {"_TrackValueFilledColor": N["dim"],
                     "_TrackValueFilledRenderEmissive": 0.0},
    }, bounds=BOUNDS["slider"])


def neo_pill(name):
    base = {
        "_LightingAmbient": N_AMB, "_Value": 0.0, "_StateCount": 2,
        "_BgEnabled": 1, "_BgColor": N["face"], "_BgPadding": 0.05,
        "_BgBevelEnabled": 1, "_BgBevelDepth": -0.55, "_BgBevelDistance": 0.30,
        "_TrackEnabled": 1, "_TrackColor": "#272B31",
        "_HandleEnabled": 1, "_HandleColor": N["body"], "_HandlePadding": 0.26,
        "_HandleFaceEnabled": 0,
        "_HandleBevelEnabled": 1, "_HandleBevelDistance": DOME, "_HandleBevelDepth": 0.85,
        "_HandleBevelSmoothness": 0.85, "_HandlePatternEnabled": 0, "_HandleRimEnabled": 0,
        "_LedEnabled": 0, "_LedColor": N["accent"], "_LedIntensity": 0.0,
        "_LedSurfaceBlend": 1.0, "_LedGlowRadius": 0.05,
        "_EdgeEnabled": 0, "_BorderEnabled": 0,
    }
    base.update(n_shadows("Toggle", cast=0.45, blur=0.8))
    return skin(name, "Toggle", base, {
        "Hover":   {"_HandleColor": shade(N["body"], 0.06)},
        "Pressed": {"_HandleColor": shade(N["body"], -0.06)},
        "Disabled": {"_LedSurfaceBlend": 0.0},
    }, bounds=BOUNDS["pill"])


# ═══════════════════════════════════════════════════════════════════════════════
# TRON
# ═══════════════════════════════════════════════════════════════════════════════

T = dict(
    face="#070C12", inset="#050A0F", back="#02050A", well="#03080E",
    body="#0A141C", mark="#E8FDFF", dim="#2E6472",
    accent="#31E4F5", hot="#FF3E7F", lamp="#5BFFB0", line="#128FA6",
)
T_AMB = 0.24          # unlit-ish: the rig still adds a flat lift, so start low
T_STRUCT = "#1B4550"  # dim structural line colour — panel/button outlines at rest
T_GLOW_BTN = dict(cast=0.10, blur=0.55)   # rectangular silhouette: tight halo
T_GLOW_KNOB = dict(cast=0.10, blur=0.45)  # circular silhouette: tighter still


def tron_knob(name, ticks=24, nub=0.075, rings=3):
    base = {
        "_LightingAmbient": T_AMB, "_ViewTilt": 0.0,
        "_AngleStart": 315, "_AngleRange": 270, "_Value": 0.5,
        "_FillEnabled": 1, "_FillColor": "#050B11", "_FillPatternEnabled": 0,
        "_FillBevelEnabled": 0,
        "_KnobEnabled": 1, "_KnobColor": "#040A10", "_KnobShapeType": 0, "_KnobSize": 0.56,
        "_KnobBevelEnabled": 0, "_KnobPatternEnabled": 0,
        # NOT _KnobEdge: that layer FILLS the cap instead of stroking its edge (verified by
        # isolation — at width 0.022 the whole disc goes solid accent). OuterRing2 parked at the
        # cap radius gives the crisp outline the style actually wants.
        #
        # HIERARCHY: the cap outline is STRUCTURE (dim, no glow) — "value is the brightest thing
        # on screen" only holds if structure stays out of its way. Only the value arc and the
        # pointer nub are full brightness at rest.
        "_KnobEdgeEnabled": 0, "_KnobRimEnabled": 0,
        "_OuterRing2Enabled": 1, "_OuterRing2Style": 0, "_OuterRing2Radius": 0.60,
        "_OuterRing2Thickness": 0.011, "_OuterRing2Color": T_STRUCT,
        "_OuterRing2AngleStart": 0, "_OuterRing2AngleRange": 360,
        "_OuterRing2RenderEmissive": 0.0,
        # The arc IS the control — the one thing on the knob that is always full brightness.
        "_LineEnabled": 1, "_LineRadius": 0.86, "_LineWidth": 0.055, "_LineRoundedEnabled": 0,
        "_LineColor": T["inset"],
        "_LineSublineUnfilledEnabled": 1, "_LineSublineUnfilledColor": "#0C2A33",
        "_LineSublineFilledEnabled": 1, "_LineSublineFilledColor": T["accent"],
        "_LineSublineFilledRenderEmissive": 1.0,
        "_LineSublineGlowEnabled": 1, "_LineSublineGlowColor": T["accent"],
        "_LineSublineGlowWidth": 0.020, "_LineSublineGlowSoftness": 0.6,
        "_LineSublineGlowIntensity": 0.40, "_LineSublineGlowRenderEmissive": 1.0,
        "_KnobNubEnabled": 1, "_KnobNubShapeType": 0, "_KnobNubColor": T["mark"],
        "_KnobNubSize": nub, "_KnobNubDistance": 0.66, "_NubEnabled": 0,
        # ⚠ SOLID, not dashed. `_OuterRingNStyle` 1/2 use HARDCODED counts baked into the shader
        # (24 dashes / 36 dots) that do not scale with radius — so on a 53px Pick-a-Look tile each
        # dash is well under a pixel and the ring shatters into an irregular pixel crust. That was
        # a large part of the "pixely" read on Tron. A solid ring is resolution-independent.
        # Dim (structure), not accent — the bezel is context, not a second value indicator.
        "_OuterRing1Enabled": 1, "_OuterRing1Style": 0, "_OuterRing1Radius": 1.06,
        "_OuterRing1Thickness": 0.015, "_OuterRing1Color": T_STRUCT,
        "_OuterRing1AngleStart": 0, "_OuterRing1AngleRange": 360,
        "_OuterRing1RenderEmissive": 0.0,
        # A second bezel ring further out — the reference HUD photos read as an instrument
        # cluster because of layered concentric rings, not one glowing circle. HERO-ONLY: five
        # concentric elements is a cluster at 132px and a smear at the 53px tile — this is exactly
        # what the size-keyed roles exist to vary.
        "_OuterRing3Enabled": 1 if rings >= 3 else 0, "_OuterRing3Style": 0, "_OuterRing3Radius": 1.16,
        "_OuterRing3Thickness": 0.008, "_OuterRing3Color": "#0F3A44",
        "_OuterRing3AngleStart": 0, "_OuterRing3AngleRange": 360,
        "_OuterRing3RenderEmissive": 0.0,
        "_OuterMarksEnabled": 1 if ticks else 0, "_OuterMarksType": 0,
        "_OuterMarksCount": ticks or 2, "_OuterMarksAngleStart": 315,
        "_OuterMarksAngleRange": 270, "_OuterMarksRadius": 0.72,
        "_OuterMarksLength": 0.06, "_OuterMarksThickness": 0.010,
        "_OuterMarksColorUnfilled": "#134B58", "_OuterMarksColorFilled": T["accent"],
        "_OuterMarksMajorEnabled": 1, "_OuterMarksMajorInterval": 4,
        "_OuterMarksMajorLengthMultiplier": 1.8, "_OuterMarksMajorThicknessMultiplier": 1.3,
        "_OuterMarksMajorColorUnfilled": T["dim"], "_OuterMarksMajorColorFilled": T["mark"],
        "_OuterMarksRenderEmissive": 1.0,
        # GLOW: the shadow layer repurposed. It is the only mechanism in this shader that draws
        # PAST the widget's own silhouette (the 2x-expanded backing quad built for cast shadows) —
        # so a bright colour there, instead of black, is a genuine soft bloom bleeding onto the
        # panel around the knob, not a flat-shaded ring. Kept tight (low cast) so it reads as a
        # halo, not a wash over the cap's own detail.
        "_KnobShadow1Enabled": 1, "_KnobShadow1Color": T["accent"] + "70",
        "_KnobShadow1Blur": T_GLOW_KNOB["blur"], "_KnobShadow1Distance": 0.0,
        "_KnobShadow1Cast": T_GLOW_KNOB["cast"], "_KnobShadow1Intensity": 1.0,
        "_KnobShadow2Enabled": 0, "_KnobShadow3Enabled": 0,
        "_EdgeEnabled": 0, "_BorderEnabled": 0,
    }
    return skin(name, "Knob", base, {
        "Hover":   {"_OuterRing2Color": T["accent"], "_LineSublineGlowIntensity": 0.65,
                    "_KnobShadow1Cast": T_GLOW_KNOB["cast"] * 1.8},
        "Pressed": {"_OuterRing2Color": T["hot"], "_LineSublineFilledColor": T["hot"],
                    "_LineSublineGlowColor": T["hot"], "_KnobShadow1Color": T["hot"] + "80",
                    "_KnobShadow1Cast": T_GLOW_KNOB["cast"] * 2.2},
        "Disabled": {"_LineSublineFilledColor": T["dim"], "_LineSublineGlowEnabled": 0,
                     "_OuterRing2Color": T["dim"], "_KnobNubColor": T["dim"],
                     "_KnobShadow1Enabled": 0},
    }, bounds=BOUNDS["knob"])


def tron_button(name, fill=None, icon=None, edge=None, icon_col=None, active=None, square=0.55,
                bounds_key="button", icon_size=0.30):
    fill = fill or "#0A1820"
    edge = edge or T["accent"]
    base = {
        "_LightingAmbient": T_AMB, "_ViewTilt": 0.0,
        "_ButtonEnabled": 1, "_ButtonColor": fill,
        # Octagon: the corner cut is what makes it read as a HUD plate rather than a rounded key.
        "_ButtonShapeType": 4, "_ButtonShapeParam1": 0.42, "_ButtonShapeParam2": 0.5,
        "_ButtonPadding": 0.20, "_ButtonRoundness": 0.0,
        "_ButtonBevelEnabled": 0, "_ButtonPatternEnabled": 0, "_ButtonRimEnabled": 0,
        # HIERARCHY: dim structural border at rest — a resting button is a labelled slot, not a
        # value. It only brightens (states, below) on hover/press/active, which is also what makes
        # those states legible as states rather than just another identical bright box.
        "_BorderEnabled": 1, "_BorderColor": T_STRUCT, "_BorderWidth": 0.035,
        "_BorderSoftness": 0.02, "_BorderRenderEmissive": 0.0,
        "_EdgeEnabled": 0,
        "_ButtonShadow1Enabled": 0, "_ButtonShadow2Enabled": 0, "_ButtonShadow3Enabled": 0,
    }
    if icon is not None:
        base.update({"_IconEnabled": 1, "_IconShapeType": icon,
                     "_IconColor": icon_col or T["dim"], "_IconRenderEmissive": 0.4,
                     "_IconWidth": icon_size, "_IconHeight": icon_size})

    def glow(color, cast_mult=1.0):
        return {"_ButtonShadow1Enabled": 1, "_ButtonShadow1Color": color + "70",
                "_ButtonShadow1Blur": T_GLOW_BTN["blur"],
                "_ButtonShadow1Distance": 0.0,
                "_ButtonShadow1Cast": T_GLOW_BTN["cast"] * cast_mult,
                "_ButtonShadow1Intensity": 1.0}

    states = {
        "Hover":   {"_ButtonColor": "#0F2530", "_BorderColor": edge,
                    "_BorderRenderEmissive": 1.0, **glow(edge, 1.0)},
        "Pressed": {"_ButtonColor": edge, "_BorderColor": T["mark"],
                    "_BorderRenderEmissive": 1.0, **glow(edge, 1.8)},
        "Disabled": {"_BorderColor": "#123038", "_ButtonColor": T["inset"],
                     "_BorderRenderEmissive": 0.0},
    }
    if icon is not None:
        states["Hover"]["_IconColor"] = edge
        states["Hover"]["_IconRenderEmissive"] = 1.0
        states["Pressed"]["_IconColor"] = T["face"]
        states["Disabled"]["_IconColor"] = T["dim"]
    if active:
        states["Active"] = {"_ButtonColor": active, "_BorderColor": active,
                            "_BorderRenderEmissive": 1.0, **glow(active, 1.6)}
        if icon is not None:
            states["Active"]["_IconColor"] = T["face"]
            states["Active"]["_IconRenderEmissive"] = 1.0
    return skin(name, "Button", base, states, bounds=BOUNDS[bounds_key])


def tron_panel(name, fill, grid=False, edge=None, px=260, glow=None):
    base = {
        "_LightingAmbient": 0.35,
        "_PanelEnabled": 1, "_PanelColor": fill,
        "_PanelShapeType": 4, "_PanelShapeParam1": 0.18, "_PanelPadding": 0.05,
        "_PanelFaceSize": 0.99,
        "_PanelBevelEnabled": 0, "_PanelRimEnabled": 0, "_PanelScrewsEnabled": 0,
        "_PanelGradientEnabled": 0,
        # The circuit-dot texture reads as a faint watermark by design — commit to SUBTLE, not
        # decorative-but-loud, so it does not compete with the controls sitting on top of it.
        "_PanelPatternEnabled": 1 if grid else 0, "_PanelPatternType": 13,
        # Pixel-locked (2026-10-04): 30-canvas-unit cells whatever size the panel is drawn at.
        "_PanelPatternScale": round(px / 30.0, 1), "_PanelPatternPx": px, "_PanelPatternIntensity": 0.14,
        "_PanelPatternParam1": 0.05, "_PanelPatternParam2": 0.7,
        "_BorderEnabled": 1, "_BorderColor": edge or T_STRUCT, "_BorderWidth": 0.016,
        "_BorderSoftness": 0.01, "_BorderRenderEmissive": 0.0,
        "_EdgeEnabled": 0,
    }
    if glow:
        base.update({"_PanelColor": glow, "_PanelRenderEmissive": 0.5})
    return skin(name, "Panel", base, bounds=BOUNDS["panel"])


def tron_slider(name):
    base = {
        "_LightingAmbient": T_AMB, "_ViewTilt": 0.0, "_Value": 0.5,
        "_BgEnabled": 1, "_BgColor": T["inset"], "_BgShapeType": 4, "_BgShapeParam1": 0.35,
        "_BgPadding": 0.06, "_BgPatternEnabled": 0, "_BgBevelEnabled": 0,
        "_TrackEnabled": 1, "_TrackColor": "#0A2630", "_TrackWidth": 0.14,
        "_TrackValueZeroPoint": 0.0,
        "_TrackValueFilledEnabled": 1, "_TrackValueFilledColor": T["accent"],
        "_TrackValueFilledRenderEmissive": 1.0,
        "_TrackValueUnfilledEnabled": 1, "_TrackValueUnfilledColor": "#0A2630",
        "_HandleEnabled": 1, "_HandleColor": T["mark"], "_HandleShapeType": 0,
        "_HandleWidth": 0.16, "_HandleHeight": 0.95, "_HandlePadding": 0.5,
        "_HandleBevelEnabled": 0, "_HandlePatternEnabled": 0, "_HandleRimEnabled": 0,
        "_HandleRenderEmissive": 1.0,
        "_BorderEnabled": 1, "_BorderColor": T["line"], "_BorderWidth": 0.02,
        "_BorderRenderEmissive": 1.0,
        "_EdgeEnabled": 0,
        "_HandleShadow1Enabled": 0, "_HandleShadow2Enabled": 0, "_HandleShadow3Enabled": 0,
    }
    return skin(name, "Slider", base, {
        "Hover":   {"_HandleColor": "#FFFFFF"},
        "Pressed": {"_TrackValueFilledColor": T["hot"], "_HandleColor": T["hot"]},
        "Disabled": {"_TrackValueFilledColor": T["dim"], "_HandleColor": T["dim"],
                     "_TrackValueFilledRenderEmissive": 0.0},
    }, bounds=BOUNDS["slider"])


def tron_pill(name):
    base = {
        "_LightingAmbient": T_AMB, "_Value": 0.0, "_StateCount": 2,
        "_BgEnabled": 1, "_BgColor": T["inset"], "_BgPadding": 0.05, "_BgBevelEnabled": 0,
        "_TrackEnabled": 1, "_TrackColor": "#0A2630",
        "_HandleEnabled": 1, "_HandleColor": T["line"], "_HandlePadding": 0.24,
        "_HandleFaceEnabled": 0, "_HandleBevelEnabled": 0, "_HandlePatternEnabled": 0,
        "_HandleRimEnabled": 0, "_HandleRenderEmissive": 1.0,
        "_LedEnabled": 0, "_LedColor": T["accent"], "_LedIntensity": 0.0,
        "_LedSurfaceBlend": 1.0, "_LedGlowRadius": 0.05,
        "_BorderEnabled": 1, "_BorderColor": T["line"], "_BorderWidth": 0.028,
        "_BorderRenderEmissive": 1.0, "_EdgeEnabled": 0,
        "_ToggleShadow1Enabled": 0, "_ToggleShadow2Enabled": 0, "_ToggleShadow3Enabled": 0,
    }
    return skin(name, "Toggle", base, {
        "Hover":   {"_BorderColor": T["mark"]},
        "Pressed": {"_BorderColor": T["hot"]},
        "Disabled": {"_BorderColor": T["dim"], "_LedSurfaceBlend": 0.0},
    }, bounds=BOUNDS["pill"])


# ═══════════════════════════════════════════════════════════════════════════════
# FLAT
# ═══════════════════════════════════════════════════════════════════════════════

F = dict(
    face="#20242A", inset="#191D22", back="#12151A", well="#151A20",
    body="#39404A", bodyAlt="#2C323A", mark="#F0F3F7", dim="#8A929C",
    accent="#4C9EF0", hot="#E8584C", lamp="#4FCB86", line="#454D57",
)
F_AMB = 0.55


def flat_knob(name, nub=0.09):
    base = {
        "_LightingAmbient": F_AMB, "_ViewTilt": 0.0,
        "_AngleStart": 315, "_AngleRange": 270, "_Value": 0.5,
        "_FillEnabled": 1, "_FillColor": F["inset"], "_FillPatternEnabled": 0,
        "_FillBevelEnabled": 0,
        "_KnobEnabled": 1, "_KnobColor": F["body"], "_KnobShapeType": 0, "_KnobSize": 0.58,
        "_KnobBevelEnabled": 0, "_KnobPatternEnabled": 0, "_KnobRimEnabled": 0,
        "_KnobEdgeEnabled": 0,
        # One thick, unambiguous arc. No glow, no gradient — just area.
        "_LineEnabled": 1, "_LineRadius": 0.84, "_LineWidth": 0.13, "_LineRoundedEnabled": 1,
        "_LineColor": F["inset"],
        "_LineSublineUnfilledEnabled": 1, "_LineSublineUnfilledColor": F["line"],
        "_LineSublineFilledEnabled": 1, "_LineSublineFilledColor": F["accent"],
        "_LineSublineFilledRenderEmissive": 0.0,
        "_KnobNubEnabled": 1, "_KnobNubShapeType": 0, "_KnobNubColor": F["mark"],
        "_KnobNubSize": nub, "_KnobNubDistance": 0.60, "_NubEnabled": 0,
        "_OuterMarksEnabled": 0, "_OuterRing1Enabled": 0,
        "_OuterRing2Enabled": 0, "_OuterRing3Enabled": 0,
        "_KnobShadow1Enabled": 0, "_KnobShadow2Enabled": 0, "_KnobShadow3Enabled": 0,
        "_EdgeEnabled": 0, "_BorderEnabled": 0,
    }
    return skin(name, "Knob", base, {
        "Hover":   {"_KnobColor": shade(F["body"], 0.12)},
        "Pressed": {"_KnobColor": shade(F["body"], -0.12)},
        "Disabled": {"_KnobColor": F["bodyAlt"], "_LineSublineFilledColor": F["dim"],
                     "_KnobNubColor": F["dim"]},
    }, bounds=BOUNDS["knob"])


def flat_button(name, fill=None, icon=None, icon_col=None, active=None, border=None,
                bounds_key="button", icon_size=0.32):
    fill = fill or F["body"]
    base = {
        "_LightingAmbient": F_AMB, "_ViewTilt": 0.0,
        "_ButtonEnabled": 1, "_ButtonColor": fill,
        "_ButtonShapeType": 0, "_ButtonShapeParam1": 0.80, "_ButtonShapeParam2": 0.5,
        "_ButtonPadding": 0.16, "_ButtonRoundness": 0.05,
        "_ButtonBevelEnabled": 0, "_ButtonPatternEnabled": 0, "_ButtonRimEnabled": 0,
        "_BorderEnabled": 1, "_BorderColor": border or F["line"], "_BorderWidth": 0.022,
        "_BorderSoftness": 0.01, "_EdgeEnabled": 0,
        "_ButtonShadow1Enabled": 0, "_ButtonShadow2Enabled": 0, "_ButtonShadow3Enabled": 0,
    }
    if icon is not None:
        base.update({"_IconEnabled": 1, "_IconShapeType": icon,
                     "_IconColor": icon_col or F["mark"],
                     "_IconWidth": icon_size, "_IconHeight": icon_size})
    states = {
        "Hover":   {"_ButtonColor": shade(fill, 0.13), "_BorderColor": F["dim"]},
        "Pressed": {"_ButtonColor": shade(fill, -0.15)},
        "Disabled": {"_ButtonColor": F["bodyAlt"], "_BorderColor": F["inset"]},
    }
    if icon is not None:
        states["Disabled"]["_IconColor"] = F["dim"]
    if active:
        states["Active"] = {"_ButtonColor": active, "_BorderColor": active}
        if icon is not None:
            states["Active"]["_IconColor"] = "#FFFFFF"
    return skin(name, "Button", base, states, bounds=BOUNDS[bounds_key])


def flat_panel(name, fill, border=None, glow=None):
    base = {
        "_LightingAmbient": 0.75,
        "_PanelEnabled": 1, "_PanelColor": fill,
        "_PanelShapeType": 0, "_PanelShapeParam1": 0.90, "_PanelPadding": 0.04,
        "_PanelFaceSize": 0.99,
        "_PanelBevelEnabled": 0, "_PanelRimEnabled": 0, "_PanelScrewsEnabled": 0,
        "_PanelPatternEnabled": 0, "_PanelGradientEnabled": 0,
        "_BorderEnabled": 1 if border else 0, "_BorderColor": border or F["line"],
        "_BorderWidth": 0.012, "_BorderSoftness": 0.005,
        "_EdgeEnabled": 0,
    }
    if glow:
        base.update({"_PanelColor": glow})
    return skin(name, "Panel", base, bounds=BOUNDS["panel"])


def flat_slider(name):
    base = {
        "_LightingAmbient": F_AMB, "_ViewTilt": 0.0, "_Value": 0.5,
        "_BgEnabled": 1, "_BgColor": F["inset"], "_BgShapeType": 0, "_BgShapeParam1": 0.85,
        "_BgPadding": 0.06, "_BgPatternEnabled": 0, "_BgBevelEnabled": 0,
        "_TrackEnabled": 1, "_TrackColor": F["line"], "_TrackWidth": 0.16,
        "_TrackValueZeroPoint": 0.0,
        "_TrackValueFilledEnabled": 1, "_TrackValueFilledColor": F["accent"],
        "_TrackValueUnfilledEnabled": 1, "_TrackValueUnfilledColor": F["line"],
        "_HandleEnabled": 1, "_HandleColor": F["mark"], "_HandleShapeType": 0,
        "_HandleWidth": 0.22, "_HandleHeight": 0.80, "_HandlePadding": 0.5,
        "_HandleBevelEnabled": 0, "_HandlePatternEnabled": 0, "_HandleRimEnabled": 0,
        "_EdgeEnabled": 0, "_BorderEnabled": 0,
        "_HandleShadow1Enabled": 0, "_HandleShadow2Enabled": 0, "_HandleShadow3Enabled": 0,
    }
    return skin(name, "Slider", base, {
        "Hover":   {"_HandleColor": "#FFFFFF"},
        "Pressed": {"_HandleColor": F["accent"]},
        "Disabled": {"_TrackValueFilledColor": F["dim"], "_HandleColor": F["dim"]},
    }, bounds=BOUNDS["slider"])


def flat_pill(name):
    base = {
        "_LightingAmbient": F_AMB, "_Value": 0.0, "_StateCount": 2,
        "_BgEnabled": 1, "_BgColor": F["inset"], "_BgPadding": 0.05, "_BgBevelEnabled": 0,
        "_TrackEnabled": 1, "_TrackColor": F["line"],
        "_HandleEnabled": 1, "_HandleColor": F["mark"], "_HandlePadding": 0.24,
        "_HandleFaceEnabled": 0, "_HandleBevelEnabled": 0, "_HandlePatternEnabled": 0,
        "_HandleRimEnabled": 0,
        "_LedEnabled": 0, "_LedColor": F["accent"], "_LedIntensity": 0.0,
        "_LedSurfaceBlend": 1.0, "_LedGlowRadius": 0.05,
        "_EdgeEnabled": 0, "_BorderEnabled": 0,
        "_ToggleShadow1Enabled": 0, "_ToggleShadow2Enabled": 0, "_ToggleShadow3Enabled": 0,
    }
    return skin(name, "Toggle", base, {
        "Hover":   {"_HandleColor": "#FFFFFF"},
        "Disabled": {"_HandleColor": F["dim"], "_LedSurfaceBlend": 0.0},
    }, bounds=BOUNDS["pill"])


# ═══════════════════════════════════════════════════════════════════════════════

def build():
    # NEOMORPHIC
    neo_knob("NeoKnobHero", nub=0.070)
    neo_knob("NeoKnob", nub=0.080)
    neo_knob("NeoKnobSmall", nub=0.100)
    neo_button("NeoButton")
    neo_button("NeoPad", square=0.60)
    neo_button("NeoAccent", fill=N["accent"], icon=6, icon_col="#0A2A26",
               bounds_key="button_accent")
    neo_button("NeoToggleBtn", icon=18, active=N["hot"], bounds_key="button_round")
    neo_button("NeoClose", icon=19, bounds_key="button_round")
    neo_button("NeoLamp", fill=N["inset"], icon=29, icon_col=N["dim"], icon_size=0.95,
               square=0.0, active=N["lamp"], bounds_key="button_round")
    neo_slider("NeoSlider")
    neo_pill("NeoPill")
    neo_panel("NeoFace", N["face"])
    neo_panel("NeoInset", N["inset"], recess=True)
    neo_panel("NeoBack", N["back"], recess=True)
    neo_panel("NeoWell", N["well"], recess=True, glow=N["well"])

    # TRON
    tron_knob("TronKnobHero", ticks=12, nub=0.065)
    tron_knob("TronKnob", ticks=0, nub=0.075, rings=2)
    tron_knob("TronKnobSmall", ticks=0, nub=0.095, rings=1)
    tron_button("TronButton")
    tron_button("TronPad", fill="#0D1B26", edge=T["line"], square=0.35)
    tron_button("TronAccent", fill="#0B2E38", icon=6, edge=T["accent"], icon_col=T["accent"],
                bounds_key="button_accent")
    tron_button("TronToggleBtn", icon=18, edge=T["line"], active=T["hot"],
                bounds_key="button_round")
    tron_button("TronClose", icon=19, edge=T["line"], bounds_key="button_round")
    tron_button("TronLamp", fill=T["back"], icon=29, edge=T["dim"], icon_col=T["dim"],
                icon_size=0.95, active=T["lamp"], bounds_key="button_round")
    tron_slider("TronSlider")
    tron_pill("TronPill")
    tron_panel("TronFace", T["face"], grid=True, px=260)
    tron_panel("TronInset", T["inset"], grid=True, px=200, edge="#0E5F70")
    tron_panel("TronBack", T["back"], edge="#08323C", px=240)
    tron_panel("TronWell", T["well"], edge=T["accent"], px=200, glow="#04121A")

    # FLAT
    flat_knob("FlatKnobHero", nub=0.070)
    flat_knob("FlatKnob", nub=0.085)
    flat_knob("FlatKnobSmall", nub=0.105)
    flat_button("FlatButton")
    flat_button("FlatPad", fill=F["bodyAlt"])
    flat_button("FlatAccent", fill=F["accent"], icon=6, icon_col="#0B2038", border=F["accent"],
                bounds_key="button_accent")
    flat_button("FlatToggleBtn", icon=18, active=F["hot"], bounds_key="button_round")
    flat_button("FlatClose", icon=19, bounds_key="button_round")
    flat_button("FlatLamp", fill=F["inset"], icon=29, icon_col=F["dim"], icon_size=1.00,
                active=F["lamp"], bounds_key="button_round")
    flat_slider("FlatSlider")
    flat_pill("FlatPill")
    flat_panel("FlatFace", F["face"], border=F["line"])
    flat_panel("FlatInset", F["inset"], border=F["line"])
    flat_panel("FlatBack", F["back"])
    flat_panel("FlatWell", F["well"], border=F["line"], glow=F["well"])


if __name__ == "__main__":
    build()
    print("built Neo / Tron / Flat sets")
