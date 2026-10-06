"""DrumSumDrum skin rendering — a line-for-line port of Assets/Editor/SkinSheet.cs on top of slrender.

A SkinSheet job (`{"cells": [...], "rig": {...}}`, schema in
.claude/skills/skin-authoring/references/tooling.md) renders here exactly as it does in the Unity
editor, without Unity: resolve the state stack through the base chain, apply only parameters the
shader declares (Material.HasProperty), push the light rig, neutralise the shared shadow buffer,
and optionally run the external shadow pass on an expanded frame.

Mirrored C#: SkinSheet.Resolve/Apply/SetParam/ParseVec/ParseColor/RenderWithShadow,
UiLightRig.CreateDefault/Load/Merge/PosVector/ColorVector/FxVector.
"""
from __future__ import annotations

import json
import os
import re
from pathlib import Path

import numpy as np

from .render import Renderer, TextureSpec, to_image

DEFAULT_THEME = "Themes/Realistic.theme"


# ── value plumbing (SkinSheet.ParseVec / ParseColor) ────────────────────────

def _float(s, default=None):
    try:
        return float(s)
    except (TypeError, ValueError):
        return default


def parse_vec(s):
    if s and s[0] == "#":
        return parse_color(s)
    v = [0.0, 0.0, 0.0, 1.0]
    for i, part in enumerate((s or "").split(",")[:4]):
        f = _float(part)
        if f is not None:
            v[i] = f
    return tuple(v)


def parse_color(hexs):
    if not hexs:
        return (0.0, 0.0, 0.0, 0.0)
    if hexs[0] != "#":
        return parse_vec(hexs)
    s = hexs[1:]
    if len(s) == 6:
        s += "FF"
    if len(s) != 8:
        return (0.0, 0.0, 0.0, 0.0)
    return tuple(int(s[i:i + 2], 16) / 255.0 for i in (0, 2, 4, 6))


_HTML_NAMES = {"red": "#FF0000", "cyan": "#00FFFF", "blue": "#0000FF", "darkblue": "#0000A0",
               "lightblue": "#ADD8E6", "purple": "#800080", "yellow": "#FFFF00", "lime": "#00FF00",
               "fuchsia": "#FF00FF", "white": "#FFFFFF", "silver": "#C0C0C0", "grey": "#808080",
               "gray": "#808080", "black": "#000000", "orange": "#FFA500", "brown": "#A52A2A",
               "maroon": "#800000", "green": "#008000", "olive": "#808000", "navy": "#000080",
               "teal": "#008080", "aqua": "#00FFFF", "magenta": "#FF00FF"}


def parse_html_color(s):
    """UnityEngine.ColorUtility.TryParseHtmlString (white on failure, as UiRigLight does)."""
    if not s:
        return (1.0, 1.0, 1.0, 1.0)
    s = _HTML_NAMES.get(s.lower(), s)
    if s[0] != "#":
        return (1.0, 1.0, 1.0, 1.0)
    h = s[1:]
    if len(h) in (3, 4):
        h = "".join(c * 2 for c in h)
    if len(h) == 6:
        h += "FF"
    if len(h) != 8 or not re.fullmatch(r"[0-9A-Fa-f]{8}", h):
        return (1.0, 1.0, 1.0, 1.0)
    return tuple(int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4, 6))


def value_string(v):
    if isinstance(v, str):
        return v
    if isinstance(v, bool):
        return "1" if v else "0"
    if isinstance(v, (int, float)):
        return ("%.6f" % float(v)).rstrip("0").rstrip(".") or "0"
    return str(v) if v is not None else "0"


def guess_type(v):
    return "Color" if isinstance(v, str) and ("," in v[1:] or v.startswith("#")) else "Float"


def param_value(ptype, value):
    """SkinSheet.SetParam's conversion; None = not applied."""
    if value is None or value == "":
        return None
    t = (ptype or "Float").lower()
    if t == "color":
        return parse_vec(value)
    if t in ("vector", "vector4", "vector2", "vector3"):
        return parse_vec(value)
    if t in ("texture", "texture2d"):
        return None
    return _float(value)


# ── state resolution (SkinSheet.Resolve, = MaterialStateEngine's base-chain merge) ─

def resolve(doc: dict, state_name: str = "Normal") -> dict:
    """Flatten a states.json to {name: (type, value-string)} for a state or 'A,B' stack."""
    by_name, root = {}, None
    for s in doc.get("states") or []:
        if not isinstance(s, dict):
            continue
        n = s.get("stateName")
        if n:
            by_name[n.lower()] = s
        if root is None and not s.get("baseStateName"):
            root = s
    out = {}

    def apply(state):
        for p in state.get("parameters") or []:
            if isinstance(p, dict) and p.get("name"):
                out[p["name"]] = (p.get("type") or "Float", p.get("value") if p.get("value") is not None else "0")

    if root is not None:
        apply(root)
    for piece in (state_name or "").split(","):
        name = piece.strip().lower()
        if not name or name not in by_name or by_name[name] is root:
            continue
        chain, cur, guard = [], by_name[name], 0
        while cur is not None and guard < 16:
            guard += 1
            chain.append(cur)
            b = (cur.get("baseStateName") or "").lower()
            cur = by_name.get(b) if b else None
        for st in reversed(chain):
            apply(st)
    return out


# ── light rig (UiLightRig) ──────────────────────────────────────────────────

def default_rig() -> dict:
    return {
        "light1": {"pos": [0.09, 0.18], "height": 0.42, "color": "#FFDB8C", "intensity": 1.0, "specular": 0.25, "specularPower": 32.0, "enabled": True},
        "light2": {"pos": [0.01, 0.20], "height": 0.30, "color": "#99C7FF", "intensity": 0.6, "specular": 0.15, "specularPower": 24.0, "enabled": True},
        "light3": {"pos": [0.01, 0.05], "height": 0.22, "color": "#B8FFC7", "intensity": 0.35, "specular": 0.10, "specularPower": 16.0, "enabled": True},
    }


def _merge_light(target: dict, src: dict | None):
    """UiLightRig.Merge — sentinels: height/specularPower >0, intensity/specular >=0; enabled always copied."""
    if not src:
        return
    if isinstance(src.get("pos"), list) and len(src["pos"]) >= 2:
        target["pos"] = list(src["pos"])
    if (src.get("height") or 0) > 0.0001:
        target["height"] = src["height"]
    if src.get("color"):
        target["color"] = src["color"]
    if src.get("intensity", -1) >= 0:
        target["intensity"] = src["intensity"]
    if src.get("specular", -1) >= 0:
        target["specular"] = src["specular"]
    if (src.get("specularPower") or 0) > 0.0001:
        target["specularPower"] = src["specularPower"]
    target["enabled"] = bool(src.get("enabled", True))


def load_rig(resources_dir, resource_path: str = DEFAULT_THEME, portrait: bool = False) -> dict:
    rig = default_rig()
    if resources_dir is None:
        return rig
    f = Path(resources_dir) / (resource_path + ".json")
    if not f.exists():
        return rig
    try:
        scene = json.loads(f.read_text(encoding="utf-8-sig")).get("scene")
    except (ValueError, OSError):
        return rig
    if not scene:
        return rig
    for i in (1, 2, 3):
        _merge_light(rig[f"light{i}"], scene.get(f"light{i}"))
    if portrait and scene.get("portrait"):
        for i in (1, 2, 3):
            _merge_light(rig[f"light{i}"], scene["portrait"].get(f"light{i}"))
    return rig


def apply_rig_override(rig: dict, o: dict):
    """SkinSheet.ApplyRigOverride — raw field overwrite, no sentinels."""
    for i in (1, 2, 3):
        block = o.get(f"light{i}")
        if not block:
            continue
        l = rig[f"light{i}"]
        for k in ("pos", "height", "intensity", "specular", "color", "enabled", "specularPower"):
            if k in block:
                l[k] = block[k]


def rig_uniforms(rig: dict, aspect: float) -> dict:
    out = {}
    for i in (1, 2, 3):
        l = rig[f"light{i}"]
        pos = l.get("pos") or [0, 0]
        c = parse_html_color(l.get("color"))
        out[f"_GlobalLightPos{i}"] = (pos[0] * aspect, pos[1], max(float(l.get("height", 0)), 0.02), 0.0)
        out[f"_GlobalLightColor{i}"] = (c[0], c[1], c[2], max(float(l.get("intensity", 0)), 0.0))
        out[f"_GlobalLightFx{i}"] = (1.0 if l.get("enabled", True) else 0.0, float(l.get("specular", 0)),
                                     max(float(l.get("specularPower", 0)), 1.0), 0.0)
    return out


# ── one cell (SkinSheet.RenderCell) ─────────────────────────────────────────

class SkinRenderer:
    """Renders SkinSheet cells. `project` is a Unity project root or a shader-work checkout:
    shaders are looked up under Assets/Shaders or Shaders, resources under Assets/Resources or
    Resources."""

    def __init__(self, project=None, renderer: Renderer | None = None, shader_roots=None, resources=None,
                 orientation: str = "screen"):
        """orientation: "screen" (default) = what the running app shows; "texture" = what Unity's
        SkinSheet.cs writes (they differ in the sign of every screen-derivative normal — see
        render.py). A cell or job may override it with an "orientation" key."""
        self.orientation = orientation
        project = Path(project) if project else find_project()
        self.project = project
        if shader_roots is None:
            shader_roots = [p for p in (project / "Assets" / "Shaders", project / "Shaders") if p.exists()]
        if resources is None:
            resources = next((p for p in (project / "Assets" / "Resources", project / "Resources") if p.exists()), None)
        self.resources = resources
        self.r = renderer or Renderer(shader_roots)
        self._docs = {}
        self._backdrops = {}
        # Materials v2: the app binds these globals at startup (UiMaterialLibrary.cs) — so do we.
        self.material_textures = {}
        self.material_globals = {}
        lib = Path(resources) / "UiMaterials" if resources else None
        if lib and (lib / "MaterialTex.png").exists() and (lib / "Matcaps.png").exists():
            self.material_textures = {
                "_UIMaterialTexArray": TextureSpec(data=str(lib / "MaterialTex.png"), grid=(4, 4), wrap="repeat", mipmaps=True),
                "_UIMatcapArray": TextureSpec(data=str(lib / "Matcaps.png"), grid=(4, 4), wrap="clamp", mipmaps=True),
            }
            self.material_globals = {"_UIMaterialLibBound": 1.0}

    def states_path(self, name: str) -> Path:
        p = Path(name)
        if p.suffix == ".json" and p.exists():
            return p
        base = (self.resources / "MaterialStates") if self.resources else Path(".")
        return base / (name if name.endswith(".states.json") else name + ".states.json")

    def _doc(self, states):
        if isinstance(states, dict):
            return states
        key = str(states)
        if key not in self._docs:
            self._docs[key] = json.loads(Path(states).read_text(encoding="utf-8-sig"))
        return self._docs[key]

    def material(self, cell: dict, rig: dict):
        """(shader, props, globals) for a cell — exactly what SkinSheet pushes onto the Material."""
        w = max(2, int(float(cell.get("w", 96))))
        h = max(2, int(float(cell.get("h", 96))))
        states = cell.get("states")
        if isinstance(states, str) and not Path(states).exists():
            states = str(self.states_path(states))
        doc = self._doc(states)
        shader_name = cell.get("shader") or doc.get("shaderName")
        sh = self.r.load_shader(shader_name)
        has = sh.properties

        props = {}
        resolved = resolve(doc, cell.get("state") or "Normal")
        for name, (ptype, value) in resolved.items():
            if name in has:
                v = param_value(ptype, value)
                if v is not None:
                    props[name] = v
        for name, raw in (cell.get("set") or {}).items():
            ptype = resolved[name][0] if name in resolved else guess_type(raw)
            if name in has:
                v = param_value(ptype, value_string(raw))
                if v is not None:
                    props[name] = v

        pos = cell.get("pos") or [0.5, 0.5]
        aspect = w / h
        props["_Position"] = (pos[0] * aspect, pos[1], 0.0, 0.0)
        if "_AspectRatio" in has:
            props["_AspectRatio"] = aspect
        props["_WidgetPixelSize"] = (float(w), float(h), 0.0, 0.0)
        props["_ShadowPassMode"] = 0.0
        lights = rig_uniforms(rig, aspect)
        props.update(lights)                       # rig.PublishTo(mat)
        globals_ = dict(lights)                    # rig.Publish (globals)
        # Pinned scene state (SkinSheet.cs does the same): no shadow buffer, and the app's scene
        # camera at rest with the eye on the cell's centre.
        globals_["_UIShadowBufferBound"] = 0.0
        vc = cell.get("viewCam")
        globals_["_GlobalViewCam"] = ((float(vc[0]) * aspect, float(vc[1]), float(vc[2]), float(vc[3]))
                                      if vc and len(vc) >= 4 else (0.5 * aspect, 0.5, 2.2, 2.2))
        globals_.update(cell.get("globals") or {})
        return sh, props, globals_

    def render_cell(self, cell: dict, rig: dict | None = None):
        """-> HxWx4 uint8 (row 0 = top), the same pixels SkinSheet writes for this cell."""
        rig = rig or load_rig(self.resources)
        sh, props, globals_ = self.material(cell, rig)
        w = max(2, int(float(cell.get("w", 96))))
        h = max(2, int(float(cell.get("h", 96))))
        ss = min(4, max(1, int(float(cell.get("ss", 1)))))
        bg = parse_color(cell.get("bg") or "#00000000")
        textures = {"_UIShadowBuffer": TextureSpec(color=(255, 255, 255, 255))}
        textures.update(self.material_textures)
        globals_.update(self.material_globals)
        # Backdrop (glass): the look's wallpaper. `backdropRect` [x0, y0, x1, y1] (0..1, y DOWN, of
        # the wallpaper) is the part of the screen this cell occupies — a rack sheet passes each
        # cell's rect so every glass part sees the slice of wallpaper actually behind it.
        bg_full = None
        if cell.get("backdrop"):
            crop = self._backdrop(cell["backdrop"], cell.get("backdropRect") or [0, 0, 1, 1])
            textures["_UIBackdropTex"] = TextureSpec(data=crop, wrap="clamp", mipmaps=True)
            globals_["_UIBackdropBound"] = 1.0
            globals_.setdefault("_UIBackdropUV", (1.0, 1.0, 0.0, 0.0))
            bg_full = crop if cell.get("backdropUnder", True) else None
        keywords = cell.get("keywords") or ()
        time = float(cell.get("time", 0.0))
        orient = cell.get("orientation") or self.orientation

        def bgimg(W, H):
            if bg_full is None:
                return None
            from PIL import Image as _I
            return np.asarray(_I.fromarray(bg_full).resize((W, H), _I.BILINEAR))

        expand = float(cell.get("shadow", 0) or 0)
        if expand > 1.001 and "_ShadowPassMode" not in sh.properties:
            # The app only gives a control a shadow quad when its material HAS _ShadowPassMode
            # (WidgetShadowQuad.cs) — toggles draw their shadow inline. Running the pass anyway
            # would draw the whole control again at 2x behind itself. Keep the expanded frame so
            # sheet layouts don't change, with no cast pass in it.
            bw, bh = int(round(w * ss * expand)), int(round(h * ss * expand))
            front = self.r.render(sh, props, (w * ss, h * ss), globals_, keywords, textures=textures,
                                  bg=(0, 0, 0, 0), time=time, orientation=orient)
            out = np.empty((bh, bw, 4), np.float32)
            out[:] = bg
            f = front.astype(np.float32) / 255.0
            ox, oy = (bw - front.shape[1]) // 2, (bh - front.shape[0]) // 2
            region = out[oy:oy + front.shape[0], ox:ox + front.shape[1]]
            region[:] = f + region * (1.0 - f[..., 3:4])
            return (np.clip(out, 0, 1) * 255.0 + 0.5).astype(np.uint8)
        if expand > 1.001:
            bw, bh = int(round(w * ss * expand)), int(round(h * ss * expand))
            back = self.r.render(sh, {**props, "_ShadowPassMode": 1.0, "_ShadowUvExpand": expand}, (bw, bh),
                                 globals_, keywords, textures=textures, bg=bg, time=time, orientation=orient,
                                 bg_image=bgimg(bw, bh))
            front = self.r.render(sh, {**props, "_ShadowPassMode": 0.0, "_ShadowUvExpand": 1.0}, (w * ss, h * ss),
                                  globals_, keywords, textures=textures, bg=(0, 0, 0, 0), time=time,
                                  orientation=orient)
            out = back.astype(np.float32) / 255.0
            f = front.astype(np.float32) / 255.0
            ox, oy = (bw - front.shape[1]) // 2, (bh - front.shape[0]) // 2
            # SkinSheet composites in Unity's bottom-up row order (rows here are top-first, so its
            # offset counts from the bottom); the app's shadow quad is simply centred.
            y0 = (bh - oy - front.shape[0]) if orient == "texture" else oy
            region = out[y0:y0 + front.shape[0], ox:ox + front.shape[1]]
            region[:] = f + region * (1.0 - f[..., 3:4])
            return (np.clip(out, 0, 1) * 255.0 + 0.5).astype(np.uint8)
        return self.r.render(sh, props, (w * ss, h * ss), globals_, keywords, textures=textures, bg=bg, time=time,
                             orientation=orient, bg_image=bgimg(w * ss, h * ss))

    def _backdrop(self, path, rect):
        """Wallpaper crop (HxWx4 uint8, row 0 = top) for a cell's screen rect."""
        from PIL import Image as _I
        p = Path(path)
        if not p.exists() and self.resources:
            p = Path(self.resources) / path
            if not p.exists():
                p = Path(self.resources) / (str(path) + ".png")
        key = (str(p), tuple(rect))
        if key not in self._backdrops:
            im = _I.open(p).convert("RGBA")
            W, H = im.size
            x0, y0, x1, y1 = rect
            im = im.crop((int(x0 * W), int(y0 * H), max(int(x1 * W), int(x0 * W) + 1), max(int(y1 * H), int(y0 * H) + 1)))
            self._backdrops[key] = np.asarray(im)
        return self._backdrops[key]

    def run_job(self, job: dict, out_dir=None) -> dict:
        """Run a SkinSheet job dict; write <id>.png files; return a done.json-style payload."""
        out_dir = Path(out_dir or job.get("out") or "out")
        out_dir.mkdir(parents=True, exist_ok=True)
        rig = load_rig(self.resources, job.get("theme") or DEFAULT_THEME)
        if job.get("rig"):
            apply_rig_override(rig, job["rig"])
        ok = fail = 0
        log = []
        saved = self.orientation
        if job.get("orientation"):
            self.orientation = job["orientation"]
        for i, cell in enumerate(job.get("cells") or []):
            cid = cell.get("id") or f"cell{ok}"
            try:
                to_image(self.render_cell(cell, rig)).save(out_dir / f"{cid}.png")
                ok += 1
            except Exception as e:  # keep going; report like SkinSheet does
                log.append(f"{cid}: {type(e).__name__} {e}")
                fail += 1
        self.orientation = saved
        return {"ok": ok, "fail": fail, "log": " | ".join(log)}


def find_project(start=None) -> Path:
    """Walk up from `start` (or cwd) to a folder holding Assets/Shaders or Shaders/."""
    env = os.environ.get("SLRENDER_PROJECT")
    if env:
        return Path(env)
    p = Path(start or os.getcwd()).resolve()
    for d in [p, *p.parents]:
        if (d / "Assets" / "Shaders").exists() or (d / "Shaders").is_dir():
            return d
    return p
