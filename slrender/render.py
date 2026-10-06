"""Draw a compiled ShaderLab pass the way Unity's Graphics.Blit does, headless, and read it back.

Blit model: one quad covering the target, object-space positions 0..1, uv 0..1, vertex colour
white, ortho projection, no depth. Output rows are returned top-first (row 0 = uv.y 1), matching
what Unity's ReadPixels + EncodeToPNG writes.

ORIENTATION — the one place two "correct" answers exist. Screen-space derivatives (ddx/ddy, fwidth)
and SV_Position depend on which way the target's rows run, and Unity on D3D11/Metal/Vulkan differs
between targets:
  "texture"  a render INTO a RenderTexture (Graphics.Blit, SkinSheet.cs): the projection is
             flipped, so ddy(uv.y) > 0 and SV_Position.y counts up from the uv.y = 0 row.
  "screen"   the backbuffer, i.e. a Screen Space - Overlay Canvas in the running app: no flip,
             ddy(uv.y) < 0, SV_Position.y counts down from the top.
Anything that builds a normal from screen derivatives (SDF bevels, pattern bump) lights the other
way up between the two — the "SkinSheet shows recessed, Play Mode shows raised" bug. Use "screen"
to judge what a player sees; "texture" to reproduce SkinSheet/Blit output.

GL context: moderngl standalone. On Linux it uses EGL (surfaceless), which with Mesa is the
llvmpipe software rasteriser — no GPU or display needed, which is the point (cloud workers).
Force a backend with SLRENDER_GL_BACKEND=egl|<default>.

Uniform values are LAYERED the way a Unity material resolves them:
    0  <  shader globals (Shader.SetGlobal*)  <  Properties defaults  <  values set on the material
so a property nobody set renders with its authored default, and a global only reaches uniforms
the material does not own.
"""
from __future__ import annotations

import math
import os
import platform
import struct
from dataclasses import dataclass

import numpy as np

from . import compiler, shaderlab

# Unity BlendMode enum (UnityEngine.Rendering.BlendMode), for `Blend [_SrcBlend] [_DstBlend]`.
_BLEND_ENUM = {0: "Zero", 1: "One", 2: "DstColor", 3: "SrcColor", 4: "OneMinusDstColor", 5: "SrcAlpha",
               6: "OneMinusSrcColor", 7: "DstAlpha", 8: "OneMinusDstAlpha", 9: "SrcAlphaSaturate",
               10: "OneMinusSrcAlpha"}


def _gl_consts():
    import moderngl as mgl
    return {
        "zero": mgl.ZERO, "one": mgl.ONE,
        "srccolor": mgl.SRC_COLOR, "oneminussrccolor": mgl.ONE_MINUS_SRC_COLOR,
        "srcalpha": mgl.SRC_ALPHA, "oneminussrcalpha": mgl.ONE_MINUS_SRC_ALPHA,
        "dstcolor": mgl.DST_COLOR, "oneminusdstcolor": mgl.ONE_MINUS_DST_COLOR,
        "dstalpha": mgl.DST_ALPHA, "oneminusdstalpha": mgl.ONE_MINUS_DST_ALPHA,
        "srcalphasaturate": 0x0308,
    }


_GL_BLEND_EQ = {"add": 0x8006, "sub": 0x800A, "revsub": 0x800B, "min": 0x8007, "max": 0x8008}


def builtin_globals(w: int, h: int, time: float = 0.0, orientation: str = "texture") -> dict:
    """What Unity provides to a draw into a w x h target."""
    vp = [[2.0, 0, 0, -1.0], [0, 2.0, 0, -1.0], [0, 0, -0.0198, -0.9802], [0, 0, 0, 1.0]]  # ortho(0,1,0,1,-1,100)
    ident = [[1.0, 0, 0, 0], [0, 1.0, 0, 0], [0, 0, 1.0, 0], [0, 0, 0, 1.0]]
    t = float(time)
    return {
        "_Time": (t / 20.0, t, t * 2.0, t * 3.0),
        "_SinTime": (math.sin(t / 8), math.sin(t / 4), math.sin(t / 2), math.sin(t)),
        "_CosTime": (math.cos(t / 8), math.cos(t / 4), math.cos(t / 2), math.cos(t)),
        "unity_DeltaTime": (1 / 60, 60.0, 1 / 60, 60.0),
        "_ScreenParams": (float(w), float(h), 1.0 + 1.0 / w, 1.0 + 1.0 / h),
        # x = -1 under the screen flip keeps ComputeScreenPos's y = 1 at the top, as on D3D.
        "_ProjectionParams": (-1.0 if orientation == "screen" else 1.0, -1.0, 100.0, 0.01),
        "_ZBufferParams": (1.0, 0.0, 0.01, 0.0),
        "unity_OrthoParams": (0.5, 0.5, 0.0, 1.0),
        "_WorldSpaceCameraPos": (0.0, 0.0, 0.0),
        "unity_ObjectToWorld": ident, "unity_WorldToObject": ident, "unity_MatrixV": ident,
        "unity_MatrixVP": vp, "glstate_matrix_projection": vp,
        "unity_GUIZTestMode": 4.0,
    }


def property_defaults(shader: shaderlab.ShaderFile) -> dict:
    """Material values a fresh `new Material(shader)` starts with (textures excluded)."""
    out = {}
    for p in shader.properties.values():
        if p.kind == "texture":
            out[p.name + "_ST"] = (1.0, 1.0, 0.0, 0.0)
            out[p.name + "_TexelSize"] = (1.0, 1.0, 1.0, 1.0)
        else:
            out[p.name] = p.default
    return out


# ── uniform block packing ───────────────────────────────────────────────────

_SCALAR = {"float": ("f", 1), "int": ("i", 1), "uint": ("I", 1), "bool": ("I", 1),
           "double": ("d", 1)}


def _base_and_n(t: str):
    if t in _SCALAR:
        return _SCALAR[t][0], 1, 1
    for prefix, code in (("vec", "f"), ("ivec", "i"), ("uvec", "I"), ("bvec", "I"), ("dvec", "d")):
        if t.startswith(prefix) and t[len(prefix):].isdigit():
            return code, int(t[len(prefix):]), 1
    if t.startswith("mat"):
        dims = t[3:]
        if "x" in dims:
            c, r = dims.split("x")
            return "f", int(r), int(c)
        return "f", int(dims), int(dims)
    return None, 0, 0


def _as_list(v):
    if isinstance(v, np.ndarray):
        return v.tolist()
    if isinstance(v, (tuple, list)):
        return list(v)
    return [v]


def _pack_value(buf: bytearray, offset: int, t: str, member: dict, v, types: dict):
    code, n, cols = _base_and_n(t)
    if code is None:
        # nested struct
        sub = types.get(t)
        if sub and isinstance(v, dict):
            for m in sub["members"]:
                if m["name"] in v:
                    _pack_member(buf, offset, m, v[m["name"]], types)
        return
    if cols > 1:
        # Matrices are given in HLSL math order (M[row][col], used as mul(M, v)). DXC turns HLSL's
        # default column_major into a SPIR-V RowMajor matrix of the transpose, so a member that
        # reflects as row_major wants HLSL's COLUMNS stored contiguously, otherwise its ROWS.
        M = np.asarray(v, dtype=np.float64).reshape(n, cols) if np.size(v) == n * cols else np.eye(n, cols)
        seq = M.T if member.get("row_major") else M
        stride = member.get("matrix_stride", 16)
        for i, vec in enumerate(seq):
            struct.pack_into("<" + "f" * len(vec), buf, offset + i * stride, *[float(x) for x in vec])
        return
    vals = _as_list(v)
    if len(vals) < n:
        vals = vals + [0.0] * (n - len(vals))
    vals = vals[:n]
    if code in ("i", "I"):
        vals = [int(round(float(x))) if not isinstance(x, bool) else int(x) for x in vals]
        if code == "I":
            vals = [max(0, x) for x in vals]
    else:
        vals = [float(x) for x in vals]
    struct.pack_into("<" + code * n, buf, offset, *vals)


def _pack_member(buf, base, m, v, types):
    off = base + m["offset"]
    arr = m.get("array")
    if arr:
        stride = m.get("array_stride", 16)
        _, n, cols = _base_and_n(m["type"])
        elem_ndim = 2 if cols > 1 else (1 if n > 1 else 0)
        items = [v] if isinstance(v, dict) or np.ndim(v) <= elem_ndim else list(v)
        for i, item in enumerate(items[:arr[0]]):
            _pack_value(buf, off + i * stride, m["type"], m, item, types)
    else:
        _pack_value(buf, off, m["type"], m, v, types)


def pack_block(block_type: dict, types: dict, size: int, values: dict) -> tuple:
    """Returns (bytes, used_names). `values` keys are uniform names (array items by list)."""
    buf = bytearray(size)
    used = set()
    for m in block_type["members"]:
        if m["name"] in values:
            _pack_member(buf, 0, m, values[m["name"]], types)
            used.add(m["name"])
    return bytes(buf), used


# ── textures ────────────────────────────────────────────────────────────────

_DEFAULT_TEX = {"white": (255, 255, 255, 255), "black": (0, 0, 0, 255), "gray": (128, 128, 128, 255),
                "grey": (128, 128, 128, 255), "bump": (128, 128, 255, 255), "red": (255, 0, 0, 255),
                "": (128, 128, 128, 255), "linearGray": (188, 188, 188, 255)}


@dataclass
class TextureSpec:
    """A texture bound by name. `data`: HxWx4 uint8 (row 0 = TOP, like a PNG), or a path to an image."""
    data: object = None
    color: tuple = None          # solid colour (0..255 RGBA) instead of data
    filter: str = "linear"       # linear | point
    wrap: str = "clamp"          # clamp | repeat
    layers: int = 1              # >1 for Texture2DArray (data then HxWx4 repeated, or a list)


class Renderer:
    """One GL context + program cache. Not thread-safe; use one per worker process."""

    def __init__(self, shader_roots=(), backend=None, software=None):
        """
        software — force Mesa's llvmpipe CPU rasteriser (the cloud configuration). Default: the
        SLRENDER_SOFTWARE env var. On Linux without a GPU you get llvmpipe anyway; on Windows this
        loads the Mesa build from .toolchain/mesa (Tools/setup_toolchain.ps1 -Mesa).
        """
        if software is None:
            software = os.environ.get("SLRENDER_SOFTWARE", "") not in ("", "0", "false")
        if software:
            os.environ["GALLIUM_DRIVER"] = "llvmpipe"
            os.environ.setdefault("MESA_GL_VERSION_OVERRIDE", "4.5")
            if platform.system() == "Windows":
                mesa = compiler.PKG.parent / ".toolchain" / "mesa" / "x64" / "opengl32.dll"
                if not mesa.exists():
                    raise FileNotFoundError(f"software rendering on Windows needs Mesa at {mesa} "
                                            "(Tools/setup_toolchain.ps1 -Mesa)")
                os.environ["GLCONTEXT_WIN_LIBGL"] = str(mesa)
            else:
                os.environ["LIBGL_ALWAYS_SOFTWARE"] = "1"
        import moderngl
        self._mgl = moderngl
        self.software = bool(software)
        self.shader_roots = [str(r) for r in shader_roots]
        backend = backend or os.environ.get("SLRENDER_GL_BACKEND")
        if backend is None and platform.system() == "Linux":
            backend = "egl"
        kw = {"require": 450}
        if backend:
            kw["backend"] = backend
        self.ctx = moderngl.create_standalone_context(**kw)
        self._programs = {}
        self._shaders = {}
        self._tex_cache = {}

    # ── info ──
    def gl_info(self) -> dict:
        return {k: self.ctx.info.get(k) for k in ("GL_RENDERER", "GL_VERSION", "GL_VENDOR")}

    def load_shader(self, name_or_path) -> shaderlab.ShaderFile:
        """Parsed .shader, re-parsed whenever the file changes on disk (a long-lived `watch`
        process sees shader edits; .cginc edits are caught by the compiler's preprocess hash)."""
        hit = self._shaders.get(name_or_path)
        if hit is not None:
            sh, mtime = hit
            try:
                if sh.path.stat().st_mtime == mtime:
                    return sh
            except OSError:
                pass
        path = shaderlab.find_shader(name_or_path, self.shader_roots)
        sh = shaderlab.parse(path)
        self._shaders[name_or_path] = (sh, path.stat().st_mtime)
        return sh

    def invalidate(self):
        """Forget parsed shaders (call after editing .shader files in a long-lived process)."""
        self._shaders.clear()

    # ── programs ──
    def program(self, shader: shaderlab.ShaderFile, pass_index=0, keywords=(), orientation="texture"):
        cp = compiler.compile_pass(shader, pass_index, keywords, self.shader_roots,
                                   flip_y=(orientation == "screen"))
        if cp.key not in self._programs:
            try:
                prog = self.ctx.program(vertex_shader=cp.vertex.glsl, fragment_shader=cp.fragment.glsl)
            except Exception as e:  # GL link/compile errors are rare after SPIRV-Cross, but say where
                raise compiler.CompileError(f"{shader.path.name}: GL rejected generated GLSL: {e}") from e
            self._programs[cp.key] = (prog, cp)
        return self._programs[cp.key]

    # ── textures ──
    def _texture(self, spec: TextureSpec, dim: str):
        key = (id(spec.data) if spec.data is not None and not isinstance(spec.data, str) else spec.data,
               spec.color, spec.filter, spec.wrap, spec.layers, dim)
        if key in self._tex_cache:
            return self._tex_cache[key]
        if spec.data is not None:
            if isinstance(spec.data, (str, os.PathLike)):
                from PIL import Image
                arr = np.asarray(Image.open(spec.data).convert("RGBA"))
            else:
                arr = np.asarray(spec.data, dtype=np.uint8)
                if arr.ndim == 3 and arr.shape[2] == 3:
                    arr = np.concatenate([arr, np.full(arr.shape[:2] + (1,), 255, np.uint8)], axis=2)
        else:
            arr = np.array([[spec.color or (255, 255, 255, 255)]], dtype=np.uint8)
        # GL row 0 is the BOTTOM (uv.y = 0); images arrive top-first.
        arr = np.ascontiguousarray(np.flipud(arr))
        h, w = arr.shape[:2]
        if "array" in dim:
            layers = max(1, spec.layers)
            data = np.concatenate([arr] * layers, axis=0) if arr.shape[0] == h else arr
            tex = self.ctx.texture_array((w, h, layers), 4, np.ascontiguousarray(data).tobytes())
        elif dim in ("3d",):
            tex = self.ctx.texture3d((w, h, 1), 4, arr.tobytes())
        elif dim in ("cube",):
            tex = self.ctx.texture_cube((w, h), 4, arr.tobytes() * 6)
        else:
            tex = self.ctx.texture((w, h), 4, arr.tobytes())
        f = self._mgl.NEAREST if spec.filter == "point" else self._mgl.LINEAR
        tex.filter = (f, f)
        if hasattr(tex, "repeat_x"):
            tex.repeat_x = spec.wrap == "repeat"
            tex.repeat_y = spec.wrap == "repeat"
        self._tex_cache[key] = tex
        return tex

    # ── draw ──
    def render(self, shader, props=None, size=(96, 96), globals_=None, keywords=(), pass_index=0,
               textures=None, bg=(0.0, 0.0, 0.0, 0.0), time=0.0, float_output=False, orientation="texture"):
        """
        Render one pass into a fresh w x h target cleared to `bg` (0..1 RGBA) and return an
        HxWx4 array, row 0 = top. uint8 unless float_output (then float32, unclamped HDR).

        props    — material values (name -> float | tuple | list | 4x4 nested list | dict for structs)
        globals_ — Shader.SetGlobal* values (only reach uniforms the material does not own)
        textures — name -> TextureSpec (material or global); unset textures use the Property default
        orientation — "texture" (Unity render-to-texture / SkinSheet) or "screen" (the app's
                   backbuffer); see the module docstring
        """
        if orientation not in ("texture", "screen"):
            raise ValueError("orientation must be 'texture' or 'screen'")
        sh = self.load_shader(shader) if isinstance(shader, (str, os.PathLike)) else shader
        prog, cp = self.program(sh, pass_index, keywords, orientation)
        w, h = int(size[0]), int(size[1])

        values = {}
        values.update(builtin_globals(w, h, time, orientation))
        values.update(globals_ or {})
        values.update(property_defaults(sh))
        values.update(props or {})

        # uniform blocks (DXC emits one: $Globals; any user cbuffers appear here too)
        ubos = {}
        for stage in (cp.vertex, cp.fragment):
            refl = stage.reflection
            for u in refl.get("ubos", []):
                ubos[u["name"]] = (u, refl["types"])
        buffers = []
        for name, (u, types) in ubos.items():
            data, _ = pack_block(types[u["type"]], types, u["block_size"], values)
            buf = self.ctx.buffer(data)
            buf.bind_to_uniform_block(u.get("binding", 0))
            buffers.append(buf)

        # textures: binding -> Unity name from reflection (combined samplers inherit image bindings)
        bound = []
        texmap = dict(textures or {})
        for stage in (cp.vertex, cp.fragment):
            for img in stage.reflection.get("separate_images", []) + stage.reflection.get("textures", []):
                uname = img["name"]
                if uname.endswith(".t"):
                    uname = uname[:-2]
                dim = img["type"].lower().replace("texture", "").replace("sampler", "") or "2d"
                spec = texmap.get(uname)
                if spec is None:
                    prop = sh.properties.get(uname)
                    spec = TextureSpec(color=_DEFAULT_TEX.get(prop.default if prop else "white",
                                                              (255, 255, 255, 255)))
                tex = self._texture(spec, dim)
                tex.use(location=img.get("binding", 0))
                bound.append(tex)

        # vertex data: everything the vertex shader asks for, Blit-style
        inputs = cp.vertex.reflection.get("inputs", [])
        quad = [(0, 0), (1, 0), (0, 1), (1, 1)]
        attr_vals = []
        fmt_parts, names = [], []
        for inp in sorted(inputs, key=lambda i: i["location"]):
            sem = inp["name"].split(".")[-1].upper()
            n = _base_and_n(inp["type"])[1] or 4
            names.append(inp["name"].replace(".", "_"))
            fmt_parts.append(f"{n}f")
            attr_vals.append((sem, n))
        rows = []
        for (x, y) in quad:
            row = []
            for sem, n in attr_vals:
                if sem.startswith("POSITION"):
                    v = [x, y, 0.0, 1.0]
                elif sem.startswith("TEXCOORD"):
                    v = [x, y, 0.0, 0.0]
                elif sem.startswith("COLOR"):
                    v = [1.0, 1.0, 1.0, 1.0]
                elif sem.startswith("NORMAL"):
                    v = [0.0, 0.0, -1.0, 0.0]
                elif sem.startswith("TANGENT"):
                    v = [1.0, 0.0, 0.0, 1.0]
                else:
                    v = [0.0, 0.0, 0.0, 0.0]
                row += v[:n]
            rows.append(row)
        vbo = self.ctx.buffer(np.array(rows, dtype="f4").tobytes())
        content = [(vbo, " ".join(fmt_parts), *names)] if names else []
        vao = self.ctx.vertex_array(prog, content, mode=self._mgl.TRIANGLE_STRIP) if content else \
            self.ctx.vertex_array(prog, [], mode=self._mgl.TRIANGLE_STRIP)

        dtype = "f4" if float_output else "f1"
        color = self.ctx.renderbuffer((w, h), 4, dtype=dtype)
        fbo = self.ctx.framebuffer(color_attachments=[color])
        fbo.use()
        fbo.viewport = (0, 0, w, h)
        fbo.clear(*[float(c) for c in bg])
        self._apply_state(cp.pass_, values)
        vao.render(vertices=4)
        raw = fbo.read(components=4, dtype=dtype)
        img = np.frombuffer(raw, dtype=np.float32 if float_output else np.uint8).reshape(h, w, 4)
        # GL row 0 is the bottom of the target. In "texture" mode that row is uv.y = 0, so flip to
        # put uv.y = 1 on top; in "screen" mode the flipped projection already put uv.y = 1 there.
        img = (np.flipud(img) if orientation == "texture" else img).copy()

        for o in (vao, vbo, fbo, color, *buffers):
            o.release()
        self.ctx.disable(self._mgl.BLEND)
        return img

    def _apply_state(self, p: shaderlab.Pass, values):
        mgl = self._mgl
        self.ctx.disable(mgl.DEPTH_TEST | mgl.CULL_FACE)
        if p.blend is None:
            self.ctx.disable(mgl.BLEND)
        else:
            gc = _gl_consts()

            def factor(tok):
                tok = tok.strip()
                if tok.startswith("[") and tok.endswith("]"):
                    v = values.get(tok[1:-1], 1)
                    v = int(round(float(_as_list(v)[0])))
                    tok = _BLEND_ENUM.get(v, "One")
                return gc.get(tok.lower(), mgl.ONE)

            self.ctx.enable(mgl.BLEND)
            self.ctx.blend_func = tuple(factor(t) for t in p.blend)
            op = (p.blend_op or "Add").split()[0].lower()
            eq = _GL_BLEND_EQ.get(op, _GL_BLEND_EQ["add"])
            self.ctx.blend_equation = (eq, eq)


def to_image(arr):
    """HxWx4 uint8 (or float, clamped) -> PIL.Image RGBA."""
    from PIL import Image
    if arr.dtype != np.uint8:
        arr = (np.clip(arr, 0.0, 1.0) * 255.0 + 0.5).astype(np.uint8)
    return Image.fromarray(arr, "RGBA")
