"""Boom Box '86 — chrome-and-black portable stereo (lit). Brief: Looks/BACKLOG.md#boom-box.

    python Tools/looks/boom_box.py check | sheet | write | manifest

Signature: speaker grille + chunky keys. Brushed-chrome faceplate on a black moulded body, round
perforated speaker-grille wells (insets/sockets), square piano-style keys in a chrome bezel that light
red / yellow / VU green, black ridged fader caps, ribbed black knobs with a chrome cap. Light mode
swaps the chassis for silver-grey plastic; the hardware is the same.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from lookkit import Look, Lit, main, grad  # noqa: E402
from skinlib import mix  # noqa: E402

RED, YELLOW, GREEN, BLUE = "#D82A2A", "#F2C21A", "#2FD060", "#2D6AEA"
# per-slot glossy cap colours: (lit colour, resting colour). Latches rest as the dark tint of their own cap.
CAPS = {"Button": (BLUE, BLUE, "#6FA0FF"), "Chip": ("#1FA652", "#1FA652", "#5BE88A"),
        "ToggleBtn": (RED, "#B82424", "#FF4A3A"), "Solo": (YELLOW, "#D6AC10", "#FFE640"),
        "Lamp": (GREEN, "#1FA84C", "#58FF8C"), "Close": ("#3A3D43", "#3A3D43", "#6A6E75")}   # (lit, rest, active)
RIDGE = {"_HandleGradientEnabled": 1, "_HandleGradientType": 4, "_HandleGradientDirection": (1.0, 0.0, 0.0, 0.0),
         "_HandleGradientScale": 3.0, "_HandleGradientOffset": 0.0, "_HandleGradientSpeed": 0.0,
         "_HandleGradientColorA": "#2A2D32", "_HandleGradientColorB": "#2A2D32",
         "_HandleGradientColorC": "#D4D8DE", "_HandleGradientColorD": "#D4D8DE", "_HandleGradientColorUsed": 4}


class BoomLit(Lit):
    """Lit class + per-slot cap colours, one shadow height for keys and pads, ridged fader cap."""

    def keys(self, L, P):
        for slot, base, states, extra in super().keys(L, P):
            m = self.preset(P, "pad" if slot == "Pad" else "key", slot)
            if slot in CAPS and m:
                c, rest, act = CAPS[slot]
                rest_c = rest
                base.update(self.paint("_Button", m, rest_c))
                states = dict(states)
                states["Hover"] = {**states.get("Hover", {}), **self.recolour("_Button", m, mix(rest_c, "#FFFFFF", 0.22)),
                                   "_ButtonRenderEmissive": 0.12}
                states["Pressed"] = {**states.get("Pressed", {}), **self.recolour("_Button", m, mix(rest_c, "#000000", 0.3))}
                states["Disabled"] = {**states.get("Disabled", {}), **self.recolour("_Button", m, mix(rest_c, "#55575B", 0.75))}
                if "Active" in states:
                    states["Active"] = {**states["Active"], **self.recolour("_Button", m, act)}
            elif slot == "Accent":
                states = dict(states, Hover={**states["Hover"], "_ButtonRenderEmissive": 0.12})
            if slot == "Pad":
                base.update(self.shadow(L, P, "_Button"))        # same height as the keys
                states = dict(states)
                # Pressed = pushed in and dim; Latched = lit with a bright ring (they must differ)
                states["Pressed"] = {**states.get("Pressed", {}), "_ButtonRenderEmissive": 0.0, "_ButtonBevelDepth": -0.3}
                states["Latched"] = {"_ButtonRenderEmissive": 0.45, "_EdgeEnabled": 1, "_EdgeColor": "#FFFFFF",
                                     "_EdgeWidth": 0.07, "_EdgeRenderAlpha": 1.0, "_EdgeSoftness": 0.2}
            yield slot, base, states, extra

    def fader(self, L, P, slot):
        slot, base, states, extra = super().fader(L, P, slot)
        if slot == "Slider":
            base.update(RIDGE)
            states = {"Hover": {"_HandleGradientColorC": "#FFFFFF", "_HandleGradientColorD": "#FFFFFF"},
                      "Pressed": {"_HandleGradientColorC": "#9AA0A8", "_HandleGradientColorD": "#9AA0A8"},
                      "Disabled": {"_HandleGradientColorA": "#2A2B2E", "_HandleGradientColorB": "#2A2B2E",
                                   "_HandleGradientColorC": "#3A3C40", "_HandleGradientColorD": "#3A3C40",
                                   "_TrackValueFilledColor": P["DIS_MARK"], "_TrackValueFilledRenderEmissive": 0.0}}
        return slot, base, states, extra

    def dial(self, L, P, slot):
        slot, base, states, extra = super().dial(L, P, slot)
        r = base["_LineRadius"]
        cap = r * base["_KnobSize"]
        w = r - cap - 0.03
        base.update({"_KnobNubEnabled": 0, "_NubEnabled": 1, "_NubShapeType": 1, "_NubColor": "#F2F4F7",
                     "_NubRenderAlpha": 1.0, "_NubRenderEmissive": 0.0, "_NubRotation": 0.0, "_NubShapeRotation": 0.0,
                     "_NubDistance": cap + 0.02 + w / 2, "_NubSizeWidth": w, "_NubSizeHeight": 0.1,
                     "_FillEnabled": 1, "_FillColor": "#0B0C0E", "_FillRenderAlpha": 1.0})
        states = dict(states)
        states["Disabled"] = {**states["Disabled"], "_NubColor": P["DIS_MARK"], "_LineColor": "#17181B", "_LineSublineUnfilledColor": "#17181B",
                              "_KnobNubColor": P["DIS_MARK"]}
        return slot, base, states, extra


CONTROLS = dict(                     # the hardware — identical in both modes
    BODY=BLUE, BODY_HI="#5C8FF5", BODY_LO="#1C48B0", DIS_BODY="#4A5160",
    MARK="#FFFFFF", MARK_DIM="#C9D2E6", DIS_MARK="#7A8190", ON_MARK="#14100A",
    ACCENT=RED, SOLO=YELLOW, LAMP=GREEN, LAMP_OFF="#8FD9A6", HOT="#FF4A3A",
    CAP="#A8AEB6", SKIRT="#1C1D20", NUB="#E23A2E", HANDLE="#1C1D20",
    VALUE=GREEN, VALUE_EM=0.45, TRACK="#0A0B0C", ARC_OFF="#6A6F78",
    SCROLL="#9AA0A8", SCROLL_HI="#E4E7EB", PAD_BODY=BLUE, PAD_TINT=1.0,
)
# chunky square piano key: black plastic body in a chrome bezel; the lit state fills it with the cap colour
KEY = {"preset": "plastic.gloss", "tint": BLUE, "edge": "chrome", "amb": 0.95, "spec": 0.9, "rough": 0.08,
       "bevel": (0.13, 1.0, 0.4), "linear": ("Plastic", 6.0, 0.02, 1.0, 0.6, 0.0, 0.0)}
# real chrome: cool silver, fine high-contrast brushing, a tall sky-to-ground ramp
CHROME = {"preset": "chrome", "tint": "#454A52", "plate_ramp": (0.2, 0.5), "plate_amb": 0.8,
          "pattern": ("Metal", 2.4, 0.16, 1.4, 0.5, 0.0, 0.0), "spec": 0.7, "rough": 0.15}
BLACK = {"preset": "carbon", "tint": "#0E0F11", "plate_ramp": (0.02, 0.1), "plate_amb": 0.9,
         "pattern": ("CarbonFiber", 4.0, 0.3, 1.0, 0.5, 0.5, 0.0)}
# speaker grille: round perforations (Perforated p1 = density, p2 = hole size, p3 = softness)
GRILLE = {"preset": "carbon", "tint": "#1C1D20", "plate_ramp": (0.05, 0.25), "plate_amb": 1.0, "lock": 200,
          "pattern": ("Perforated", 100.0, 0.7, 1.0, 0.55, 0.5, 0.15), "spec": 0.4, "rough": 0.3}

LOOK = Look(
    title="Boom Box '86", style="BoomBox", prefix="BoomBox", slug="boom-box", cls="lit", order=24,
    status="draft", brief="BACKLOG.md#boom-box",
    blurb="Brushed chrome, black plastic, speaker grille and chunky coloured keys.",
    tagline="chrome faceplate, speaker grille, chunky piano keys.",
    displays="neo",
    shape={
        "key": dict(corner=0.95, round=0.3, bevel=0.13, depth=1.0, smooth=0.4, dome=0.3),
        "Pad": dict(corner=0.95, round=0.3, bevel=0.09, depth=1.0, smooth=0.4, dome=0.3, sunk=0.15),
        "plate": dict(stitch=("#C9CED6", 2.2), set=dict(_BorderGradientEnabled=1, **{k: v for k, v in grad("_Border", ("#454A52", "#E8ECF0", "#FFFFFF", "#7C828B"), (0.0, 1.0)).items() if k.startswith("_BorderGradient") and k != "_BorderGradientEnabled"})),
        "dial": dict(skirt="Fluted", skirt_count=24, skirt_depth=0.08, cap_r=0.5, bevel=0.22, depth=0.6,
                     smooth=0.6, dome=0.5, nub=0.075, nub_dist=0.34, arc_px=3.0),
        "KnobHero": dict(ticks=11, arc_px=4.0),
        "fader": dict(handle_w=0.44, handle_h=0.95, corner=0.2, bevel=0.14, depth=0.7, dome=0.1),
        "shadow": dict(blur=1.2, cast=0.34),
    },
    material={
        "plate": CHROME, "Back": BLACK, "Inset": GRILLE, "Socket": GRILLE, "ScrollTrack": BLACK,
        "key": KEY, "pad": dict(KEY),
        "accent": dict(KEY, tint=RED),
        "cap": {"preset": "aluminium.brushed", "amb": 0.95, "dome": 0.5, "ramp": (-0.35, 0.0, 0.5, 0.35), "spec": 0.7, "rough": 0.2,
                "pattern": ("RadialBrushed", 3.0, 0.08, 1.0, 0.45, 0.2, 0.0)},
        "skirt": {"preset": "rubber.matte", "tint": "#1C1D20", "amb": 0.9,
                  "edge": (0.5, 0.3, 0.05, -0.1),
                  "pattern": ("Knurled", 3.0, 0.2, 1.0, 0.5, 0.6, 0.5)},
        "handle": {"preset": "rubber.matte", "tint": "#1C1D20", "amb": 0.9, "edge": "chrome",
                   "linear": ("Knurled", 3.0, 0.2, 1.0, 0.5, 0.6, 0.5),
                   "pattern": ("Knurled", 3.0, 0.2, 1.0, 0.5, 0.6, 0.5)},
    },
    rig={
        "dark": {"light1": dict(pos=[-0.4, 1.5], height=1.2, color="#FFFFFF", intensity=0.95, specular=0.5,
                                specularPower=56),
                 "light2": dict(pos=[1.3, 0.6], height=0.9, color="#BFD4FF", intensity=0.3, specular=0.1),
                 "light3": dict(enabled=False)},
        "light": {"light1": dict(pos=[-0.4, 1.5], height=1.2, color="#FFFFFF", intensity=0.95, specular=0.5,
                                 specularPower=56),
                  "light2": dict(pos=[1.3, 0.6], height=0.9, color="#BFD4FF", intensity=0.3, specular=0.1),
                  "light3": dict(enabled=False)},
    },
    modes={
        "dark": dict(
            track="Starfield", blurb="Gunmetal and black, silver trim, VU green.",
            palette=dict(CONTROLS, GAP="#050506", BACK="#0E0F11", FACE="#3B3F46", INSET="#1C1D20", SOCKET="#17181A",
                         WELL="#040405", SHADOW="#000000", SHADOW_A=0.65, WELL_EM=0.05),
            app=dict(display=dict(text="#46E06A", textDim="#2F8A48", textAlt="#F2C228"),
                     ui=dict(text="#EEF0F3", textDim="#B4BAC3", accent=RED),
                     key=dict(label="#FFFFFF"),
                     chrome=dict(label="#C4C9D1", labelActive="#FFFFFF", icon="#C4C9D1", iconActive="#FFFFFF",
                                 gear="#C4C9D1CC", meatballIdle="#C4C9D1", meatballLit=RED),
                     tracks=dict(text="#EEF0F3", ruler="#C4C9D1E6", playhead="#EEF0F3E6",
                                 rowWithSample="#3B3F46", rowEmpty="#17181A"),
                     ink=dict(faceplate="#EEF0F3", faceplateDim="#B4BAC3", inset="#EEF0F3", insetDim="#B4BAC3",
                              backplane="#EEF0F3", backplaneDim="#B4BAC3", socket="#EEF0F3", socketDim="#B4BAC3",
                              reviewBar="#EEF0F3", reviewBarDim="#B4BAC3"))),
        "light": dict(
            track="Starfield", blurb="Silver-grey plastic chassis, same hardware.",
            palette=dict(CONTROLS, GAP="#7C8087", BACK="#9AA0A8", FACE="#8C929A", INSET="#AEB3BA", SOCKET="#B2B7BE",
                         WELL="#0A0B0D", SHADOW="#1A1C20", SHADOW_A=0.55, WELL_EM=0.05),
            material={
                      "plate": {"preset": "aluminium.brushed", "tint": "#8C929A", "lo": "#4A4F57", "hi": "#FFFFFF",
                                "plate_ramp": (0.15, 0.4), "plate_amb": 0.8,
                                "pattern": ("Metal", 2.4, 0.16, 1.4, 0.5, 0.0, 0.0), "spec": 0.7, "rough": 0.15},
                      "Back": {"preset": "rubber.matte", "tint": "#9AA0A8", "lo": "#4A4F57", "hi": "#FFFFFF",
                               "plate_ramp": (0.06, 0.1), "plate_amb": 0.9,
                               "pattern": ("Plastic", 1.6, 0.07, 1.0, 0.6, 0.0, 0.1)},
                      "Inset": dict(GRILLE, tint="#AEB3BA", lo="#4A4E55", hi="#F4F5F7", plate_ramp=(0.04, 0.14),
                                    plate_amb=0.6, pattern=("Perforated", 100.0, 0.22, 1.0, 0.55, 0.5, 0.15)),
                      "Socket": dict(GRILLE, tint="#B2B7BE", lo="#4A4E55", hi="#F4F5F7", plate_ramp=(0.04, 0.14),
                                     plate_amb=0.6, pattern=("Perforated", 100.0, 0.22, 1.0, 0.55, 0.5, 0.15))},
            app=dict(display=dict(text="#46E06A", textDim="#2F8A48", textAlt="#F2C228"),
                     ui=dict(text="#0B0D10", textDim="#2A2E34", accent="#C42A20"),
                     key=dict(label="#FFFFFF"),
                     chrome=dict(label="#2A2E34", labelActive="#0B0D10", icon="#2A2E34", iconActive="#C42A20",
                                 gear="#2A2E34CC", meatballIdle="#2A2E34", meatballLit="#C42A20"),
                     tracks=dict(text="#0B0D10", ruler="#2A2E34E6", playhead="#0B0D10E6", rowWithSample="#9CA0A7",
                                 rowEmpty="#D2D5D9", strip="#B4B8BE"),
                     ink=dict(faceplate="#0B0D10", faceplateDim="#2A2E34", inset="#0B0D10", insetDim="#22262B",
                              backplane="#0B0D10", backplaneDim="#2A2E34", socket="#0B0D10", socketDim="#22262B",
                              reviewBar="#0B0D10", reviewBarDim="#2A2E34"))),
    },
)

LOOK.kit = BoomLit()

if __name__ == "__main__":
    sys.exit(main(LOOK))
