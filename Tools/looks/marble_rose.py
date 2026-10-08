"""Marble & Rose Gold — stone and jewellery (lit). Brief: Looks/BACKLOG.md#marble-rose.

    python Tools/looks/marble_rose.py check | sheet | write | manifest | printcheck

Signature: stone + jewellery. The plates are real veined stone (the Materials v2 `marble` texture, tiled
large, turned ~35 degrees and stretched so the veins run as long diagonal rivers): Nero Marquina in dark
mode (black, veined in gold) and white Carrara in light mode (soft grey veins). The hardware is jewellery:
satin/polished rose-gold keys and domed caps over a reeded skirt (matcap metal, not tinted plastic),
blush-pink enamel for ON and accents, a hairline rose-gold inlay framing the stone slabs, gemstone pad
colours (own track theme). Light mode changes the chassis only — the same rose gold sits on white stone.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from lookkit import Look, MATERIALS, gcol, main  # noqa: E402

BLUSH = "#E79AA8"
ROSE_LO, ROSE_HI = "#4E1F26", "#FFE6DE"        # rose gold: burgundy-rose shadows, cream-pink highlights
GOLD = "#E4BE6C"                                # the Nero veins
INLAY = "#C98F82"                               # the hairline rose-gold frame round the slabs

CONTROLS = dict(                     # the hardware — identical in both modes
    BODY="#DA9C94", BODY_HI="#F3C8BB", BODY_LO="#733A3F", DIS_BODY="#6A5450",
    MARK="#3A1C1C", MARK_DIM="#6E3F3C", DIS_MARK="#9A7E78", ON_MARK="#3F0F1C",
    ACCENT=BLUSH, SOLO="#F0B7A4", LAMP="#FFD3DA", LAMP_OFF="#8A6A66", HOT="#D2455A",
    CAP="#E6B0A6", SKIRT="#C98A82", NUB="#2A1018", HANDLE="#DA9C94", ACCENT_HI="#F6BCC8", ACCENT_LO="#A8566A",
    VALUE="#F4A6B4", VALUE_EM=0.3, TRACK="#140D0E", ARC_OFF="#46343A",
    SCROLL="#4A3A3C", SCROLL_HI="#D79A8A", PAD_BODY="#3A2A2C", PAD_TINT=0.75,
    PAD_HOVER_EM=0.3, PAD_PRESS_EM=0.6,
)


GLYPH = "#2A1418"                    # near-black mauve ink for key glyphs (speaker, eye, power, x): >= 3:1 on rose gold
WELL_FRAME = {"_BorderEnabled": 1, "_BorderColor": INLAY, "_BorderWidthPx": 1.0, "_BorderRenderAlpha": 1.0,
              "_BorderRenderEmissive": 0.0}     # a rose-gold hairline round every display well


def rose(matcap, ramp, **kw):
    """Rose gold = the kit's gold.rose with a rosier shadow end and a pale-pink highlight end."""
    return dict({"preset": "gold.rose", "amb": 1.0, "matcap": matcap, "lo": ROSE_LO, "hi": ROSE_HI, "ramp": ramp}, **kw)


# Every state of every glyph key keeps the near-black ink: the kit's own Hover (HOT red on Close), Pressed (HOT) and
# Active (ON_MARK wine at 0.6 emissive, which washes pink on a pink face) all fell under 3:1 on the rose-gold face.
KEY_STATES = {k: {"Hover": {"_ButtonRenderEmissive": 0.12}}
              for k in ("Button", "Accent", "ToggleBtn", "Solo", "Lamp", "Close", "Chip")}
for _k in ("ToggleBtn", "Solo", "Lamp"):
    KEY_STATES[_k]["Active"] = {"_IconColor": GLYPH, "_IconRenderEmissive": 0.0}
for _k in ("Close", "ToggleBtn", "Solo", "Lamp"):
    KEY_STATES[_k]["Hover"]["_IconColor"] = GLYPH
# a pressed key sinks to the deep red-mauve ramp: the glyph flips to cream there (near-black measured 1.3-2.3:1)
for _k in ("Close", "ToggleBtn", "Solo", "Lamp"):
    KEY_STATES[_k]["Pressed"] = {"_IconColor": "#FFE9E4"}


def hardware(amb, accent_amb, pad_amb):
    """The jewellery: brushed-satin keys and handles, polished domed caps, reeded satin skirt, blush enamel
    accents, gem pads in a bright-top rose-gold bezel. `amb` is the control ambient (the light mode lifts it)."""
    return {
        "key": rose(("brushed", 0.7), (-0.5, -0.1, 0.3, 0.68), amb=amb),
        "accent": {"preset": "enamel", "tint": BLUSH, "edge": "gold.rose", "amb": accent_amb},
        "cap": rose(("polished", 0.7), (-0.4, 0.05, 0.4, 0.75), amb=amb),
        "skirt": rose(("satin", 0.8), (-0.7, -0.2, 0.3, 0.72), amb=amb,
                      pattern=("Knurled", 2.0, 0.12, 1.0, 0.5, 0.6, 0.5)),
        "handle": rose(("brushed", 0.7), (-0.5, -0.1, 0.3, 0.68), amb=amb),
        "pad": rose(("gloss_coat", 0.6), (-0.5, -0.1, 0.3, 0.68), amb=pad_amb,
                    edge={"preset": "gold.rose", "lo": ROSE_LO, "hi": ROSE_HI, "ramp": (0.75, 0.4, -0.2, -0.55)}),
    }


# Spec-local stone presets (the kit's library is not edited). Both use the real `marble` texture.
# Nero: the pattern colour runs gold (strongest, negative = vein) -> dim gold -> the plate's own black, so the
# veins are metallic gold; intensity ~3 lifts even the thin hairlines out of the black.
MATERIALS["marble.nero"] = dict(
    MATERIALS["marble"], texture=("marble", 900, 2.7, 1.0, 2.0, 0.3), base="#101013", lo="#000000", hi=GOLD,
    tint=(0, 1, (1.0, 0.5, 0.0, 0.0)), spec=0.05, rough=0.05, plate_amb=1.1)
MATERIALS["marble.nero.quiet"] = dict(MATERIALS["marble.nero"], texture=("marble", 760, 2.2, 1.0, 1.8, 0.3))
# the gutter and the pad socket are thin/small crops: a larger, blurrier, barely stretched tile keeps them calm
MATERIALS["marble.nero.calm"] = dict(MATERIALS["marble.nero"], texture=("marble", 1100, 1.6, 1.0, 2.8, 0.12))
# Carrara: plain multiplicative veins (white stone, grey rivers).
MATERIALS["marble.carrara"] = dict(
    MATERIALS["marble"], texture=("marble", 900, 0.9, 1.0, 2.2, 0.3), base="#E6E2DD", lo="#8C8884", hi="#FFFFFF",
    spec=0.1, rough=0.05, plate_amb=0.66)
MATERIALS["marble.carrara.quiet"] = dict(MATERIALS["marble.carrara"], texture=("marble", 760, 0.7, 1.0, 2.0, 0.3))
MATERIALS["marble.carrara.calm"] = dict(MATERIALS["marble.carrara"], texture=("marble", 1100, 0.8, 1.0, 2.6, 0.0))

# veins run as diagonal rivers; each slab is turned differently so no two plates show the same crop
TURN = {"Face": -45, "Inset": -28, "Socket": -46, "Back": -20, "Bezel": -40}

STONE_SET = {s: {"_PanelPatternOffset": a} for s, a in TURN.items()}

LOOK = Look(
    title="Marble & Rose Gold", style="MarbleRose", prefix="MarbleRose", slug="marble-rose", cls="lit", order=24,
    status="candidate", brief="BACKLOG.md#marble-rose",
    blurb="Veined stone plates, rose-gold domed hardware, blush pink.",
    tagline="veined marble, rose-gold domed hardware, blush for ON.",
    displays="neo",
    shape={
        # no dome: a domed key face stamps the medial-axis bowtie crease; a flat satin face under the vertical ramp plus a
        # bright rounded chamfer reads as one soft top highlight
        "key": dict(corner=0.5, round=0.9, bevel=0.2, depth=0.55, smooth=0.8, dome=0.0),
        "ScrollHandle": dict(round=0.9, dome=0.0),
        "dial": dict(skirt="Fluted", skirt_count=40, skirt_depth=0.04, cap_r=0.64, bevel=0.2, depth=0.5,
                     smooth=0.6, dome=0.6, nub=0.1, nub_dist=0.4, arc_px=3.0),
        "KnobSmall": dict(nub=0.14),
        "KnobHero": dict(ticks=11, arc_px=4.0),
        "shadow": dict(blur=1.6, cast=0.24),
        # the rose-gold inlay: a hairline frame round the two big slabs (a metal line set into the stone)
        "Face": dict(stitch=(INLAY, 1.2)), "Inset": dict(stitch=(INLAY, 1.0)),
        "ScrollTrack": dict(fill="SCROLLWELL"),
        # a gem set in a rose-gold bezel: wide shallow cabochon, gloss coat
        "Pad": dict(bevel=0.15, depth=0.3, smooth=0.9, dome=0.3),
        # near-black mauve glyphs: the speaker / eye / power / close marks must read on the specular rose-gold face
        "ToggleBtn": dict(set={"_IconColor": GLYPH}), "Solo": dict(set={"_IconColor": GLYPH}),
        "Lamp": dict(set={"_IconColor": GLYPH}), "Close": dict(set={"_IconColor": GLYPH}, icon_size=0.5),
        # hover must be SEEN: a lit lift on top of the lighter colour
        "states": dict(
            KEY_STATES,
            dial={"Hover": {"_KnobRenderEmissive": 0.16}, "Pressed": {"_KnobFaceSmoothness": 0.25}},
            fader={"Hover": {"_HandleRenderEmissive": 0.16}},
            # Hover = a rim/brightness lift (kit: emissive PAD_HOVER_EM + a domed face); Latched = a lit gem with
            # its own blush-lit bezel, so the two never share a look
            Pad={"Latched": dict({"_ButtonRenderEmissive": 0.42, "_ButtonBevelDepth": -0.05},
                                 **gcol("_ButtonBevel", ("#FFF0F3", "#FFC2D0", "#F29AB0", "#D9728C")))}),
    },
    material=hardware(1.0, 0.8, 0.9),
    rig={
        "dark": {"light1": dict(pos=[-0.4, 1.5], height=1.2, color="#FFE6DC", intensity=0.9, specular=0.4,
                                specularPower=48),
                 "light2": dict(pos=[1.3, 0.6], height=0.9, color="#FFC9D6", intensity=0.3, specular=0.08),
                 "light3": dict(enabled=False)},
        "light": {"light1": dict(pos=[-1.5, 3.0], height=4.0, color="#FFF6EE", intensity=0.8, specular=0.15,
                                 specularPower=48),
                  "light2": dict(enabled=False), "light3": dict(enabled=False)},
    },
    # gemstone pad colours + a rose-gold highway: pads wear their row colour from the mode's track theme
    track_themes={
        "MarbleRoseGems": {
            "_doc": "Marble & Rose Gold highway. See Starfield.track.json for the format.",
            "name": "MarbleRoseGems",
            "blurb": "Rose quartz, celadon jade, champagne, amethyst on black stone. Rose-gold rails.",
            "palette": {
                "row1": "#F08AA2", "row2": "#86C9A4", "row3": "#EDCB98", "row4": "#B79BE0",
                "rail": "#E6A99B", "laneLine": "#6A4A44", "laneFill": "#0B0809", "hitLine": "#FFF1E8",
                "receptor": "#E8B8A8", "gridBar": "#D9A08F", "gridBeat": "#4A3430", "bgTop": "#0A0708",
                "bgBottom": "#1C1214", "fog": "#7A4A46", "star": "#FFE6D8", "miss": "#FF4A66",
                "perfect": "#FFEBC0"},
            "props": {"skyMode": 6, "skyColorA": "#3A2224", "skyColorB": "#D9A08F", "skyAmount": 0.5, "skyScale": 2.4,
                      "starDensity": 0.0, "horizonGlow": 0.45, "railGlow": 0.95, "noteGlow": 0.95, "additive": 0.22,
                      "radiance": 0.92, "beatPulse": 0.55, "fog": 0.55, "vignette": 0.5}},
    },
    modes={
        "dark": dict(
            track="MarbleRoseGems", blurb="Nero Marquina: black stone veined in gold, rose-gold hardware.",
            material={"plate": "marble.nero", "Inset": "marble.nero.quiet", "Socket": "marble.nero.calm",
                      "Bezel": "marble.nero.quiet", "Back": "marble.nero.calm"},
            set=dict(STONE_SET, Well=WELL_FRAME, Socket=dict(WELL_FRAME, _BorderColor="#6A4A44")),
            palette=dict(CONTROLS, GAP="#050506", BACK="#0A0A0C", FACE="#111113", INSET="#0B0B0D", SOCKET="#09090B",
                         WELL="#050405", SHADOW="#000000", SHADOW_A=0.6, WELL_EM=0.05, AMB_PLATE=1.1, TRACK="#40302F", DIS_BODY="#54423F",
                         MARK_DIM="#9E868C", SCROLLWELL="#271D20",
                         PLATE_LO=0.0, PLATE_HI=0.02),
            app=dict(display=dict(text="#F4B4BF", textDim="#D0A0AA", textAlt="#E8C47A"),
                     # the kit derives these from MARK_DIM; they print on the (pale) rose keys, so they keep the dark ink
                     key=dict(markOff="#6E3F3C", glyphOff="#6E3F3C", velOff="#6E3F3C"),
                     ui=dict(text="#EADFD8", textDim="#8E8480", accent=BLUSH),
                     chrome=dict(label="#CDB6AE", labelActive="#EADFD8", icon="#CDB6AE", iconActive="#F4B4BF"),
                     tracks=dict(text="#EADFD8", ruler="#CDB6AEE6", playhead="#EADFD8E6", rowWithSample="#3A2A2C"),
                     ink=dict(faceplate="#EADFD8", faceplateDim="#9A8F8A", inset="#EADFD8", insetDim="#9A8F8A",
                              backplane="#EADFD8", backplaneDim="#9A8F8A", socket="#EADFD8", socketDim="#9A8F8A",
                              reviewBar="#EADFD8", reviewBarDim="#9A8F8A"))),
        "light": dict(
            track="MarbleRoseGems", blurb="White Carrara in soft daylight, the same rose gold.",
            # the daylight lamp sits high and soft: lift the hardware's ambient so the SAME rose gold reads
            # as pale as it does under the dark mode's low key lamp (controls stay, only the chassis changes)
            # the daylight lamp sits high and soft: lift the hardware's ambient so the SAME rose gold reads
            # as pale as it does under the dark mode's low key lamp (controls stay, only the chassis changes)
            material=dict({"plate": "marble.carrara", "Inset": "marble.carrara.quiet", "Socket": "marble.carrara.quiet",
                           "Bezel": "marble.carrara.quiet", "Back": "marble.carrara.calm"}, **hardware(1.15, 1.0, 1.1)),
            set=dict(STONE_SET, Well=WELL_FRAME),
            palette=dict(CONTROLS, GAP="#B3AEA9", BACK="#C9C3BC", FACE="#E6E2DD", INSET="#DEDAD5", SOCKET="#D5CFC9",
                         VALUE="#B85670", ARC_OFF="#8C807E", TRACK="#6A5A5C", VALUE_EM=0.1, DIS_BODY="#C9B3AE",
                         WELL="#3B2A30", SCROLLWELL="#DEDAD5", SHADOW="#4A3E3C", SHADOW_A=0.35, WELL_EM=0.05, AMB_PLATE=0.9,
                         PLATE_LO=0.05, PLATE_HI=0.0),
            app=dict(display=dict(text="#F4B4BF", textDim="#D0A0AA", textAlt="#E8C47A"),
                     ui=dict(text="#2A2224", textDim="#6E6264", accent="#B04C62"),
                     ink=dict(faceplate="#2A2224", faceplateDim="#6E6264", inset="#2A2224", insetDim="#6E6264",
                              backplane="#2A2224", backplaneDim="#6E6264", socket="#2A2224", socketDim="#6E6264",
                              reviewBar="#2A2224", reviewBarDim="#6E6264"))),
    },
)

if __name__ == "__main__":
    sys.exit(main(LOOK))
