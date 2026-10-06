"""Neomorphic Light + Dark — dedicated per-component skins, one generator, one table per mode.

    python design_neomorphic.py write [light|dark|both]    # write Assets/Resources/MaterialStates/NeoLight*/NeoDark*
    python design_neomorphic.py sheet <mode> <tag> [amb]    # render every part at app sizes (no Assets write)

Every part is DERIVED from its Neo (dark) authored file for structure (shape, bounds, state list),
then every state that matters is set explicitly. A recipe recolour could not do this: it pushes one
value into every state that already declares a property, so e.g. the lamp's Active icon colour came
out as its Normal colour shifted a little lighter — on and off looked the same.

The STRUCTURE is shared by both modes (it was tuned on Light, 2026-09-13, and every fix in it is a
geometry/shader fix, not a colour choice): no unauthored _LightingShadow1 on knobs, lip height 0,
knob bevel well inside the cap, visible base line with no emissive, pads untilted, inset padding
0.01, pad halo inside its shadow quad. Only the MODE table differs.
"""
import copy, json, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SK = ROOT / "Assets/Resources/MaterialStates"
SC = ROOT / ".skinsheet" / "neomorphic"
SC.mkdir(parents=True, exist_ok=True)

MODES = {
    "light": dict(
        prefix="NeoLight",
        FACE="#E6E9EE", BODY="#E8EBF0", BODY_HI="#EAEDF1", BODY_LO="#D9DDE3", PRESS="#DCE0E6",
        INSET="#D9DDE4", BACK="#D3D7DE", WELL="#C2C9D3", LINE="#D2D7DF",
        ACCENT="#3F7FD6", MARK="#5A6272", SHADOW="#8F98A6", DIS_MARK="#B6BCC6",
        ACCENT_HI="#4F8FE6", ACCENT_LO="#3772C4", ACCENT_DIS="#AFC4E2", ACCENT_MARK="#FFFFFF",
        LATCH_ON="#C4D9F6", LATCH_MARK="#2F7BEA", LAMP_OFF_MARK="#AAB1BC", LAMP_ON="#D6E3F6", LAMP_MARK="#2F7BEA",
        PAD_BODY="#EEF1F5", PAD_TINT=0.5,
        KNOB_TRACK="#C6CCD5", KNOB_ARC="#2F6FD0", KNOB_ARC_EM=0.0,
        SLIDER_TRACK="#D6DBE2", PILL_BG="#CDD2DA",
        AMB_PANEL=0.5, AMB_BTN=0.5, AMB_ACCENT=0.78, AMB_PAD=0.55, AMB_KNOB=0.7, AMB_HANDLE=0.8,
        AMB_PILL=0.55, AMB_WELL=0.6,
        SH_BTN_A=0.3, SH_KNOB_A=0.25, SH_PAD_A=0.22,
    ),
    "dark": dict(
        prefix="NeoDark",
        FACE="#2C3036", BODY="#31353C", BODY_HI="#373C44", BODY_LO="#272A30", PRESS="#282B31",
        INSET="#262A30", BACK="#23262B", WELL="#161A20", LINE="#3A3F47",
        ACCENT="#4A9BF5", MARK="#AEB6C2", SHADOW="#050608", DIS_MARK="#5A616B",
        ACCENT_HI="#5AA8FA", ACCENT_LO="#3A86E0", ACCENT_DIS="#34465C", ACCENT_MARK="#FFFFFF",
        LATCH_ON="#233349", LATCH_MARK="#5AB0FF", LAMP_OFF_MARK="#5C636D", LAMP_ON="#20314A", LAMP_MARK="#5AB0FF",
        PAD_BODY="#3A3F47", PAD_TINT=0.55,
        KNOB_TRACK="#3A3F47", KNOB_ARC="#4A9BF5", KNOB_ARC_EM=0.2,
        SLIDER_TRACK="#3A3F47", PILL_BG="#22262B",
        AMB_PANEL=0.9, AMB_BTN=0.85, AMB_ACCENT=0.85, AMB_PAD=0.8, AMB_KNOB=0.85, AMB_HANDLE=0.9,
        AMB_PILL=0.85, AMB_WELL=0.9,
        SH_BTN_A=0.55, SH_KNOB_A=0.5, SH_PAD_A=0.45,
    ),
}


def hexrgba(h, a=None):
    s = h.lstrip("#")
    if len(s) == 6:
        s += "ff"
    r, g, b, al = (int(s[i:i + 2], 16) / 255.0 for i in (0, 2, 4, 6))
    if a is not None:
        al = a
    return f"{r:.6g},{g:.6g},{b:.6g},{al:.6g}"


def val(v):
    if isinstance(v, str) and v.startswith("#"):
        return "Color", hexrgba(v)
    if isinstance(v, tuple):          # ("#hex", alpha)
        return "Color", hexrgba(v[0], v[1])
    return "Float", f"{v:.6g}" if isinstance(v, float) else str(v)


def setp(state, params):
    lst = state.setdefault("parameters", [])
    idx = {p["name"]: i for i, p in enumerate(lst)}
    for k, v in params.items():
        t, s = val(v)
        if k in idx:
            lst[idx[k]]["value"] = s
            if t == "Color":
                lst[idx[k]]["type"] = "Color"
        else:
            lst.append({"name": k, "type": t, "value": s})


def derive(base, name, normal, states=None, description=None):
    doc = json.loads((SK / f"{base}.states.json").read_text(encoding="utf-8"))
    doc = copy.deepcopy(doc)
    doc["author"] = "DrumSumDrum"
    by = {s["stateName"]: s for s in doc["states"]}
    norm = next(s for s in doc["states"] if not s.get("baseStateName"))
    # An UNSET _ButtonLipHeight is 0.08, not 0, and draws the dotted lip seam round raymarched keys
    # (see the skin-authoring skill). It was patched to 0 by hand on five Neo Light parts, so every
    # regenerate silently brought the seam back. Light only: Neo Dark's keys are its authored look.
    if (doc.get("shaderName") == "UI/SDFButtonRM" and "_ButtonLipHeight" not in normal
            and name.startswith("NeoLight")):
        normal = dict(normal, _ButtonLipHeight=0.0)
    setp(norm, normal)
    if description:
        norm["description"] = description
    for sname, params in (states or {}).items():
        st = by.get(sname)
        if st is None:
            st = {"stateId": f"neolight-{name}-{sname}", "stateName": sname, "description": "",
                  "baseStateName": norm["stateName"], "priority": 0, "tags": [], "parameters": []}
            doc["states"].append(st)
        # A derived state lists ONLY what it changes: clear the dark look's deltas first.
        st["parameters"] = []
        setp(st, params)
    return name, doc


def button_parts(P, n):
    SH_BTN = {"_ButtonShadow1Enabled": 1, "_ButtonShadow1Color": (P["SHADOW"], P["SH_BTN_A"]), "_ButtonShadow1Blur": 2.5,
              "_ButtonShadow1Cast": 0.3, "_ButtonShadow1Intensity": 1.0, "_ButtonShadow1Distance": 0.0,
              "_ButtonShadow2Enabled": 0, "_ButtonShadow3Enabled": 0}
    DOME_BTN = {"_ButtonBevelEnabled": 1, "_ButtonBevelDistance": 0.34, "_ButtonBevelDepth": 0.15,
                "_ButtonBevelSmoothness": 1.0, "_ButtonFaceSmoothness": 0.12}
    SUNK_BTN = {"_ButtonBevelDepth": -0.2, "_ButtonShadow1Intensity": 0.25}
    base_btn = dict(DOME_BTN, **SH_BTN, _ButtonColor=P["BODY"], _LightingAmbient=P["AMB_BTN"],
                    _ButtonPatternEnabled=1, _ButtonPatternType=0, _ButtonPatternScale=14,
                    _ButtonPatternIntensity=0.05, _ButtonPatternContrast=1.0,
                    _ButtonPatternSpecularEffect=0.3, _ButtonPatternRoughnessEffect=0.6,
                    _IconColor=P["MARK"], _EdgeEnabled=0, _BorderEnabled=0, _ButtonRenderEmissive=0.0)
    std_states = {
        "Hover": {"_ButtonColor": P["BODY_HI"]},
        "Pressed": dict(SUNK_BTN, _ButtonColor=P["PRESS"]),
        "Disabled": {"_ButtonColor": P["FACE"], "_ButtonBevelDepth": 0.1, "_IconColor": P["DIS_MARK"]},
    }
    yield derive("NeoButton", n("Button"), base_btn, std_states)
    yield derive("NeoClose", n("Close"), base_btn, std_states)
    yield derive("NeoAccent", n("Accent"),
                 dict(base_btn, _ButtonColor=P["ACCENT"], _IconColor=P["ACCENT_MARK"], _LightingAmbient=P["AMB_ACCENT"]),
                 {"Hover": {"_ButtonColor": P["ACCENT_HI"]},
                  "Pressed": dict(SUNK_BTN, _ButtonColor=P["ACCENT_LO"]),
                  "Disabled": {"_ButtonColor": P["ACCENT_DIS"], "_ButtonBevelDepth": 0.1}})
    # A latch: Active is PRESSED IN and its mark takes the accent — on/off is a shape AND a colour.
    yield derive("NeoToggleBtn", n("ToggleBtn"), base_btn,
                 dict(std_states, Active={"_ButtonColor": P["LATCH_ON"], "_ButtonBevelDepth": -0.25,
                                          "_IconColor": P["LATCH_MARK"], "_IconRenderEmissive": 0.8}))
    # The bypass lamp: OFF is a quiet grey power mark on a raised key; ON is sunk, tinted, and the
    # mark glows accent blue. Two independent cues so it reads at a glance.
    yield derive("NeoLamp", n("Lamp"),
                 dict(base_btn, _IconColor=P["LAMP_OFF_MARK"], _IconRenderEmissive=0.0),
                 {"Hover": {"_ButtonColor": P["BODY_HI"]},
                  "Pressed": dict(SUNK_BTN, _ButtonColor=P["BODY_LO"]),
                  "Disabled": {"_ButtonColor": P["FACE"], "_ButtonBevelDepth": 0.1, "_IconColor": P["DIS_MARK"]},
                  "Active": {"_ButtonColor": P["LAMP_ON"], "_ButtonBevelDepth": -0.3,
                             "_IconColor": P["LAMP_MARK"], "_IconRenderEmissive": 0.9}})
    # PD-48 pads: NO view tilt and no scene-camera tilt (_ViewTilt 3 projected every pad out of its
    # cell and over the tray). Soft squircle, wide shallow smooth bevel, no lip/rim/edge ring, a halo
    # small enough to stay inside the 2x shadow quad (blur 3.0 was cut at the quad edge and printed
    # a line on the tray), and the row colour tinted onto the body.
    name_, pad = derive("NeoPad", n("Pad"),
                 dict(_ButtonColor=P["PAD_BODY"], _LightingAmbient=P["AMB_PAD"],
                      _ViewTilt=0.0, _ViewCamEnabled=0, _ViewShift=0.0,
                      _ButtonPadding=0.12, _ButtonShapeParam1=0.5, _ButtonRoundness=0.45,
                      _ButtonBevelEnabled=1, _ButtonBevelDistance=0.22, _ButtonBevelDepth=0.08,
                      _ButtonBevelSmoothness=1.0, _ButtonFaceSmoothness=0.15, _ButtonLipHeight=0.0,
                      _ButtonRimEnabled=0, _EdgeEnabled=0, _BorderEnabled=0,
                      _ButtonShadow1Enabled=1, _ButtonShadow1Color=(P["SHADOW"], P["SH_PAD_A"]), _ButtonShadow1Blur=1.2,
                      _ButtonShadow1Cast=0.0, _ButtonShadow1Intensity=1.0,
                      _ButtonShadow2Enabled=0, _ButtonShadow3Enabled=0,
                      _LightingShadow1Enabled=0, _LightingShadow2Enabled=0, _LightingShadow3Enabled=0),
                 {"Hover": {"_ButtonRenderEmissive": 0.05},
                  "Pressed": {"_ButtonBevelDepth": -0.1, "_ButtonShadow1Intensity": 0.25},
                  "Disabled": {"_ButtonBevelDepth": 0.03, "_ButtonShadow1Intensity": 0.4},
                  "Latched": {"_ButtonRenderEmissive": 0.25, "_ButtonBevelDepth": -0.05}})
    pad["padColor"] = {"targets": [{"param": "_ButtonColor", "amount": P["PAD_TINT"]}]}
    yield name_, pad


def knob_parts(P, n):
    def knob(base, name, line_w, nub):
        # The arc spans _LineRadius … _LineRadius + _LineWidth (SDFKnob: "from _LineRadius to
        # _LineRadius + _LineWidth"). At 0.9 + 0.12…0.18 it ended at 1.02–1.08 of the half-extent —
        # past the quad, so the round top of every arc was sliced flat, worst on small knobs where
        # a pixel of AA is 0.04 of the extent (2026-09-18).
        # 2026-09-20: 0.91 left under 2px of air on a 38px knob — enough for the band but not for
        # its ROUNDED cap, which reaches sqrt(R² + t²) (t = half the band), plus a pixel of AA, so
        # the top of the arc still read as flattened in the app. Outer edge now 0.88; the cap is
        # rescaled so its radius (_LineRadius × _KnobSize) stays the 0.54 it always was.
        r = 0.88 - line_w
        knob_size = 0.54 / r
        normal = dict(_KnobShadow1Enabled=1, _KnobShadow1Intensity=1.0, _KnobShadow1Distance=0.0,
                      _KnobShadow2Enabled=0, _KnobShadow3Enabled=0,
                      _LightingAmbient=P["AMB_KNOB"],
                      # _LightingShadow1 defaults ON in SDFKnob/SDFKnobRM (black, a .5, distance .1)
                      # and threw a hard drop shadow across every knob's own track. Off, all three.
                      # The cap is seated by one faint soft shadow with no cast.
                      _LightingShadow1Enabled=0, _LightingShadow2Enabled=0, _LightingShadow3Enabled=0,
                      _KnobShadow1Color=(P["SHADOW"], P["SH_KNOB_A"]), _KnobShadow1Blur=1.8, _KnobShadow1Cast=0.0,
                      _KnobColor=P["BODY"], _FillEnabled=0,
                      # Lip 0 (+ the SDFKnobRM no-lip seam fix) removes the dotted ring round the cap;
                      # bevel distance well inside the cap radius, or the whole cap faces away (grey).
                      _KnobLipHeight=0.0,
                      _KnobBevelEnabled=1, _KnobBevelDistance=0.22, _KnobBevelDepth=0.3,
                      _KnobBevelSmoothness=1.0,
                      _KnobFaceSmoothness=-0.35,
                      _LineSublineFilledGradientEnabled=0, _LineRadius=r, _KnobSize=knob_size,
                      # A VISIBLE base line under the arc (alpha 0 let the plate show through as a dark
                      # edge) with NO emissive (added after the arcs composite; washes the arc out).
                      _LineEnabled=1, _LineWidth=line_w, _LineColor=P["KNOB_TRACK"],
                      _LineRenderAlpha=1.0, _LineRenderEmissive=0.0,
                      _LineSublineUnfilledRenderEmissive=0.0,
                      _LineSublineUnfilledEnabled=1, _LineSublineUnfilledColor=P["KNOB_TRACK"],
                      _LineSublineFilledEnabled=1, _LineSublineFilledColor=P["KNOB_ARC"],
                      _LineSublineFilledRenderEmissive=P["KNOB_ARC_EM"],
                      _LineSublineGlowEnabled=0,
                      _KnobNubEnabled=1, _KnobNubColor=P["ACCENT"], _KnobNubSize=nub, _KnobNubDistance=0.55)
        states = {
            "Hover": {"_KnobColor": P["BODY_HI"]},
            "Pressed": {"_KnobColor": P["BODY_LO"], "_KnobBevelDepth": 0.2},
            "Disabled": {"_KnobColor": P["FACE"], "_KnobNubColor": P["DIS_MARK"],
                         "_LineSublineFilledColor": P["DIS_MARK"], "_LineSublineFilledRenderEmissive": 0.0},
        }
        # Stays on UI/SDFKnobRM: the flat UI/SDFKnob's in-app variant never finished async-compiling.
        return derive(base, name, normal, states)
    yield knob("NeoKnob", n("Knob"), 0.16, 0.11)
    yield knob("NeoKnobHero", n("KnobHero"), 0.12, 0.08)
    yield knob("NeoKnobSmall", n("KnobSmall"), 0.18, 0.13)


def slider_parts(P, n):
    yield derive("NeoSlider", n("Slider"),
                 dict(_LightingAmbient=P["AMB_HANDLE"], _HandleShadow1Enabled=0, _HandleShadow2Enabled=0,
                      _HandleShadow3Enabled=0,
                      _BgEnabled=0,
                      _TrackEnabled=1, _TrackWidth=0.16, _TrackColor=P["SLIDER_TRACK"],
                      _TrackValueFilledEnabled=1, _TrackValueFilledColor=P["ACCENT"],
                      _TrackValueFilledRenderEmissive=0.15,
                      _TrackValueUnfilledEnabled=1, _TrackValueUnfilledColor=P["SLIDER_TRACK"],
                      _HandleEnabled=1, _HandleColor=P["BODY"], _HandleShapeType=1,
                      _HandleWidth=0.78, _HandleHeight=0.78,
                      _HandleBevelEnabled=1, _HandleBevelDistance=0.6, _HandleBevelDepth=0.15,
                      _HandleBevelSmoothness=1.0, _HandleFaceSmoothness=0.15),
                 {"Hover": {"_HandleColor": P["BODY_HI"]},
                  "Pressed": {"_HandleColor": P["BODY_LO"]},
                  "Disabled": {"_TrackValueFilledColor": P["DIS_MARK"], "_TrackValueFilledRenderEmissive": 0.0}})
    yield derive("NeoPill", n("Pill"),
                 {"_LightingAmbient": P["AMB_PILL"],
                  "_BgEnabled": 1, "_BgColor": P["PILL_BG"],
                  "_BgBevelEnabled": 0,
                  "_TrackColor": P["LINE"], "_HandleColor": P["BODY"],
                  "_HandleBevelEnabled": 0,
                  "_ToggleShadow1Enabled": 0, "_ToggleShadow2Enabled": 0, "_LedEnabled": 0},
                 {"Hover": {"_HandleColor": P["BODY_HI"]},
                  "Pressed": {"_HandleColor": P["BODY_LO"]},
                  "Disabled": {"_LedSurfaceBlend": 0}})


def panel_parts(P, n):
    # PIXEL padding + corners (2026-09-13): the proportional 0.06 padding and 0.2 corner put a big
    # PD-48 plate's edge 25px inside its rect with an 80px corner, straight through the title bar.
    # (Applied to the shipped files with Tools/patch_skin.py; kept here so a re-run agrees.)
    px = {"Face": (2.0, 14.0), "Inset": (1.0, 12.0), "Back": (2.0, 6.0), "Well": (1.0, 8.0)}
    fixed = lambda part: {"_PanelPaddingPx": px[part][0], "_PanelCornerRadiusPx": px[part][1]}
    yield derive("NeoFace", n("Face"), dict(fixed("Face"), _PanelColor=P["FACE"], _LightingAmbient=P["AMB_PANEL"]))
    sunk = {"_PanelBevelEnabled": 0, "_PanelRimEnabled": 1, "_PanelRimDepth": -0.3,
            "_PanelRimWidth": 0.03, "_PanelRimSmoothness": 0.03, "_LightingAmbient": P["AMB_PANEL"]}
    # Padding 0.01 (Neo base 0.06 drew the tray edge ~12px inside its rect; pads ran over it).
    yield derive("NeoInset", n("Inset"), dict(sunk, **fixed("Inset"), _PanelColor=P["INSET"], _PanelPadding=0.01))
    # No bevel: on the tall mixer backplane it shaded every strip between modules dark-to-bright.
    yield derive("NeoBack", n("Back"), dict(fixed("Back"), _PanelColor=P["BACK"], _LightingAmbient=P["AMB_PANEL"],
                                            _PanelBevelEnabled=0))
    yield derive("NeoWell", n("Well"),
                 dict(sunk, **fixed("Well"), _PanelColor=P["WELL"], _PanelRenderEmissive=0.0,
                      _LightingAmbient=P["AMB_WELL"]))


def all_parts(mode, overrides=None):
    P = dict(MODES[mode], **(overrides or {}))
    n = lambda part: P["prefix"] + part
    for gen in (button_parts, knob_parts, slider_parts, panel_parts):
        yield from gen(P, n)


def write(modes):
    for mode in modes:
        for name, doc in all_parts(mode):
            (SK / f"{name}.states.json").write_text(json.dumps(doc, indent=4), encoding="utf-8")
            print("  wrote", name)


# ── component sheet ──────────────────────────────────────────────────────────

RIGS = {
    "mid": {"light1": {"pos": [-1.8, 3.0], "height": 2.6, "color": "#FFFFFF", "intensity": 0.72, "specular": 0.06},
            "light2": {"enabled": False}, "light3": {"enabled": False}},
}


def sheet(mode, tag, overrides=None, rig="mid"):
    sys.path.insert(0, str(ROOT / "Tools"))
    from skinsheet import render, OUT, _font
    from PIL import Image, ImageDraw

    P = dict(MODES[mode], **(overrides or {}))
    parts = dict(all_parts(mode, overrides))
    pre = P["prefix"]
    paths = {}
    for name, doc in parts.items():
        p = SC / f"{tag}-{name}.states.json"
        p.write_text(json.dumps(doc), encoding="utf-8")
        paths[name[len(pre):]] = p.as_posix()

    W, H = 1180, 560
    cells, meta = [], []

    def add(cid, part, w, h, x, y, shadow=True, **kw):
        c = {"id": f"ns-{tag}-{cid}", "states": paths[part], "w": w, "h": h, "ss": 1, "bg": "#00000000",
             "pos": [0.15 + 0.7 * x / W, 0.85 - 0.7 * y / H]}
        if shadow:
            c["shadow"] = 2
        c.update(kw)
        cells.append(c)
        meta.append((c["id"], w, h, x, y, shadow))

    add("face", "Face", W, H, 0, 0, shadow=False)
    add("inset", "Inset", 520, 150, 20, 20, shadow=False)
    for i, v in enumerate((0.0, 0.35, 0.7, 1.0)):
        add(f"k{i}", "Knob", 48, 48, 50 + i * 110, 55, set={"_Value": v})
    add("kdis", "Knob", 48, 48, 490, 55, state="Disabled", set={"_Value": 0.5})
    add("kin", "Inset", 150, 150, 585, 5, shadow=False)
    add("kh", "KnobHero", 120, 120, 600, 20, set={"_Value": 0.65})
    for i, v in enumerate((0.2, 0.8)):
        add(f"ks{i}", "KnobSmall", 34, 34, 760 + i * 60, 60, set={"_Value": v})
    for i, (w, hh, y) in enumerate(((150, 32, 30), (110, 32, 80), (190, 26, 130))):
        add(f"well{i}", "Well", w, hh, 900, y, shadow=False)

    labels = []
    for i, (part, st, lab) in enumerate([("Button", "Normal", "BTN"), ("Button", "Normal,Hover", "HOV"),
                                         ("Button", "Normal,Hover,Pressed", "PRS"), ("Button", "Disabled", "DIS"),
                                         ("ToggleBtn", "Normal", "OFF"), ("ToggleBtn", "Active", "ON"),
                                         ("Accent", "Normal", "ACC"),
                                         ("Lamp", "Normal", "LAMP"), ("Lamp", "Active", "LIT")]):
        w, h = (34, 34) if part == "Lamp" else (40, 34)
        add(f"b{i}", part, w, h, 30 + i * 70, 220, state=st)
        labels.append((32 + i * 70, 262, lab))

    for i, v in enumerate((0.3, 0.8)):
        add(f"sl{i}", "Slider", 260, 30, 30 + i * 300, 310, set={"_Value": v})
    for i, v in enumerate((0.0, 1.0)):
        add(f"pl{i}", "Pill", 52, 26, 660 + i * 80, 312, set={"_Value": v})

    rows = json.loads((ROOT / "Assets/Resources/TrackThemes/Nebula.track.json").read_text(encoding="utf-8"))["palette"]
    pad_doc = parts[pre + "Pad"]
    base = {x["name"]: x["value"] for x in next(s for s in pad_doc["states"] if not s.get("baseStateName"))["parameters"]}
    body = [float(v) for v in base["_ButtonColor"].split(",")]
    add("tray", "Inset", 640, 80, 20, 380, shadow=False)
    for i in range(4):
        rgb = [int(rows[f"row{4 - i}"].lstrip("#")[j:j + 2], 16) / 255 for j in (0, 2, 4)]
        a = P["PAD_TINT"]
        col = ",".join(f"{body[j] + (rgb[j] - body[j]) * a:.5f}" for j in range(3)) + ",1"
        st = "Normal,Hover,Pressed" if i == 3 else "Normal"
        add(f"p{i}", "Pad", 142, 48, 30 + i * 154, 396, state=st, set={"_ButtonColor": col})

    render(cells, rig=RIGS[rig], timeout=480)

    img = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    for cid, w, h, x, y, sh in meta:
        p = OUT / f"{cid}.png"
        if not p.exists():
            print("missing", cid)
            continue
        img.alpha_composite(Image.open(p).convert("RGBA"), (x - (w // 2 if sh else 0), y - (h // 2 if sh else 0)))
    d = ImageDraw.Draw(img)
    dim = "#7A8290" if mode == "light" else "#8A93A0"
    for x, y, lab in labels:
        d.text((x, y), lab, font=_font(10, True), fill=dim)
    d.text((50, 110), "0%       35%       70%      100%     disabled", font=_font(10), fill=dim)
    digit = "#2B5C9E" if mode == "light" else "#62D6FF"
    d.text((912, 36), "1:1.00", font=_font(18, True), fill=digit)
    d.text((912, 86), "+0.00", font=_font(18, True), fill=digit)
    d.text((912, 134), "01 CH CH CH", font=_font(14, True), fill=digit)
    d.text((30, 340), "slider 30%", font=_font(10), fill=dim)
    d.text((330, 340), "slider 80%", font=_font(10), fill=dim)
    d.text((660, 345), "pill off / on", font=_font(10), fill=dim)
    d.text((500, 470), "pad pressed ->", font=_font(10), fill=dim)

    sheet_img = Image.new("RGB", (W + 20, H + 40), "#E9EBEE")
    ImageDraw.Draw(sheet_img).text((10, 10), f"NEOMORPHIC {mode.upper()} parts — {tag}", font=_font(16, True), fill="#15181C")
    sheet_img.paste(img.convert("RGB"), (10, 34))
    out = SC / f"sheet-{mode}-{tag}.png"
    sheet_img.save(out)
    print(out)
    return out


if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "write":
        which = sys.argv[2] if len(sys.argv) > 2 else "both"
        write(["light", "dark"] if which == "both" else [which])
    elif cmd == "verify-light":
        bad = []
        for name, doc in all_parts("light"):
            on_disk = json.loads((SK / f"{name}.states.json").read_text(encoding="utf-8"))
            if on_disk != doc:
                bad.append(name)
        print("light parts identical to committed:", not bad, bad)
    else:
        mode, tag = sys.argv[2], sys.argv[3]
        amb = float(sys.argv[4]) if len(sys.argv) > 4 else None
        ov = None
        if amb is not None:
            ov = {k: v * amb for k, v in MODES[mode].items() if k.startswith("AMB_")}
        sheet(mode, tag, ov)
