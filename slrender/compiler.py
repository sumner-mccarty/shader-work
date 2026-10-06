"""Unity ShaderLab pass -> GLSL 4.50, via DXC (HLSL -> SPIR-V) and SPIRV-Cross (SPIR-V -> GLSL).

Why this route: it is the one Unity itself takes when it compiles with DXC (the editor ships
dxcompiler.dll and spirv-cross), both tools run natively on Linux/Windows/macOS, and DXC compiles
these SDF shaders in about a second where fxc takes minutes.

Compatibility choices, each one load-bearing:
  * `-HV 2018` — HLSL 2021 (DXC's default) changed `?:`, `&&` and `||` on vectors; Unity-era code
    relies on the old per-component semantics.
  * Unity's implicit includes (HLSLSupport + UnityShaderVariables) are prepended to CGPROGRAM, as
    Unity does; `unity_shim/` provides them (and UnityCG/UnityUI) — written for this renderer.
  * `-fvk-use-gl-layout` — std140 uniform blocks, which plain GL can bind without extensions.
    Offsets are read back from SPIRV-Cross's reflection, so HLSL packing never has to be guessed.
  * The fragment `origin_upper_left` qualifier is dropped: in a Unity render-to-texture on D3D the
    projection is flipped, so SV_Position.y counts up from the uv.y = 0 row — which is exactly
    GL's default lower-left origin. ddx/ddy already agree (both increase with uv.y).

Everything is cached by the hash of the PREPROCESSED source (so an edit to any included .cginc
invalidates exactly the programs that include it) plus the tool versions and these options.
"""
from __future__ import annotations

import hashlib
import json
import os
import platform
import re
import shutil
import subprocess
import tempfile
from dataclasses import dataclass, field
from pathlib import Path

from . import shaderlab

PKG = Path(__file__).resolve().parent
SHIM = PKG / "unity_shim"
PIPELINE_VERSION = "3"          # bump when the GLSL post-processing below changes


class CompileError(Exception):
    def __init__(self, message, diagnostics=None):
        super().__init__(message)
        self.diagnostics = diagnostics or []


@dataclass
class Diagnostic:
    file: str
    line: int
    column: int
    severity: str
    message: str

    def __str__(self):
        return f"{self.file}:{self.line}:{self.column}: {self.severity}: {self.message}"


@dataclass
class StageOutput:
    glsl: str
    reflection: dict


@dataclass
class CompiledPass:
    shader: shaderlab.ShaderFile
    pass_: shaderlab.Pass
    keywords: tuple
    vertex: StageOutput
    fragment: StageOutput
    key: str
    warnings: list = field(default_factory=list)


# ── toolchain ───────────────────────────────────────────────────────────────

def _repo_toolchain_dirs():
    here = PKG.parent
    yield here / ".toolchain"
    if os.environ.get("SLRENDER_TOOLCHAIN"):
        yield Path(os.environ["SLRENDER_TOOLCHAIN"])


def _exe(name):
    return name + (".exe" if platform.system() == "Windows" else "")


def find_tool(tool: str) -> str:
    path = _find_tool(tool)
    if tool == "dxc" and platform.system() != "Windows":
        # Microsoft's Linux build keeps libdxcompiler.so in ../lib next to bin/dxc.
        lib = Path(path).resolve().parent.parent / "lib"
        cur = os.environ.get("LD_LIBRARY_PATH", "")
        if lib.exists() and str(lib) not in cur.split(":"):
            os.environ["LD_LIBRARY_PATH"] = str(lib) + (":" + cur if cur else "")
    return path


def _find_tool(tool: str) -> str:
    """Locate dxc / spirv-cross: env override, then the repo's .toolchain, then PATH."""
    env = {"dxc": "SLRENDER_DXC", "spirv-cross": "SLRENDER_SPIRV_CROSS"}[tool]
    if os.environ.get(env):
        return os.environ[env]
    arch = "arm64" if platform.machine().lower() in ("arm64", "aarch64") else "x64"
    for base in _repo_toolchain_dirs():
        cands = [base / "bin" / _exe(tool)]
        if tool == "dxc":
            cands += [base / "dxc" / "bin" / arch / _exe("dxc"), base / "dxc" / "bin" / _exe("dxc")]
        for c in cands:
            if c.exists():
                return str(c)
    found = shutil.which(tool)
    if found:
        return found
    raise FileNotFoundError(
        f"{tool} not found. Run Tools/setup_toolchain (see slrender/README.md) or set {env}.")


_version_cache = {}


def tool_versions() -> str:
    if "v" not in _version_cache:
        parts = []
        for t, args in (("dxc", ["--version"]), ("spirv-cross", ["--help"])):
            try:
                out = subprocess.run([find_tool(t)] + args, capture_output=True, text=True, timeout=60)
                txt = (out.stdout + out.stderr).strip().splitlines()
                parts.append(txt[0] if txt else t)
            except FileNotFoundError:
                parts.append(t + ":missing")
        _version_cache["v"] = " | ".join(parts)
    return _version_cache["v"]


# ── cache ───────────────────────────────────────────────────────────────────

def cache_dir() -> Path:
    if os.environ.get("SLRENDER_CACHE"):
        d = Path(os.environ["SLRENDER_CACHE"])
    elif (PKG.parent / ".git").exists():
        d = PKG.parent / ".slrender-cache"          # running from a shader-work checkout
    else:
        d = Path.home() / ".cache" / "slrender"     # pip-installed into some other environment
    d.mkdir(parents=True, exist_ok=True)
    return d


# ── source assembly ─────────────────────────────────────────────────────────

_STRIP_PRAGMAS = re.compile(
    r'^[ \t]*#[ \t]*pragma[ \t]+(vertex|fragment|geometry|hull|domain|target|multi_compile\w*|shader_feature\w*|'
    r'skip_variants|only_renderers|exclude_renderers|require|instancing_options|enable_d3d11_debug_symbols|'
    r'hardware_tier_variants|editor_sync_compilation|use_dxc|dynamic_branch\w*|surface|enable_cbuffer)\b.*$',
    re.M)


def assemble(shader: shaderlab.ShaderFile, p: shaderlab.Pass, keywords) -> str:
    """The exact text DXC sees: keyword defines, Unity's implicit includes, then the program."""
    lines = ["// generated by slrender — " + shader.path.name + " / " + p.name]
    for k in sorted(keywords):
        lines.append(f"#define {k} 1")
    lines.append("#define SHADER_API_GLCORE 1")
    if p.language == "CG":
        lines.append('#include "HLSLSupport.cginc"')
        lines.append('#include "UnityShaderVariables.cginc"')
    # Blank out (not delete) pragmas so the #line mapping stays exact.
    prog = _STRIP_PRAGMAS.sub(lambda m: "", p.program)
    return "\n".join(lines) + "\n" + prog + "\n"


def _include_dirs(shader: shaderlab.ShaderFile, roots) -> list:
    dirs = [str(SHIM), str(shader.path.parent)]
    for r in roots:
        if str(r) not in dirs:
            dirs.append(str(r))
    return dirs


_DIAG_RE = re.compile(r'^(?P<file>.*?):(?P<line>\d+):(?P<col>\d+): (?P<sev>error|warning|note): (?P<msg>.*)$')


def _parse_diags(text: str) -> list:
    out = []
    for ln in text.splitlines():
        m = _DIAG_RE.match(ln.strip())
        if m:
            out.append(Diagnostic(Path(m.group("file")).name if m.group("file") else "?",
                                  int(m.group("line")), int(m.group("col")), m.group("sev"), m.group("msg")))
    return out


def _run(cmd, cwd=None, timeout=1800):
    return subprocess.run(cmd, capture_output=True, text=True, cwd=cwd, timeout=timeout)


def _dxc_common(includes):
    args = ["-spirv", "-HV", "2018", "-fvk-use-gl-layout", "-fspv-target-env=vulkan1.0",
            "-Wno-ignored-attributes", "-Wno-conversion", "-Wno-parentheses-equality",
            "-Wno-unused-value", "-Wno-for-redefinition"]
    for d in includes:
        args += ["-I", d]
    return args


def _post_glsl(glsl: str, stage: str) -> str:
    if stage == "frag":
        glsl = re.sub(r'^\s*layout\(origin_upper_left\)\s+in\s+vec4\s+gl_FragCoord;\s*$', '', glsl, flags=re.M)
        glsl = glsl.replace("layout(origin_upper_left) ", "")
    return glsl


def compile_pass(shader: shaderlab.ShaderFile, pass_index: int = 0, keywords=(), roots=(),
                 optimize: str = "-O3", use_cache: bool = True, flip_y: bool = False) -> CompiledPass:
    """flip_y: negate gl_Position.y on every vertex-shader exit (SPIRV-Cross --flip-vert-y), which
    is how render.py reproduces a top-left-origin SCREEN (see Renderer.render orientation)."""
    p = shader.passes[pass_index]
    keywords = tuple(sorted(set(k for k in keywords if k and k.strip("_"))))
    includes = _include_dirs(shader, roots)
    src = assemble(shader, p, keywords)
    dxc = find_tool("dxc")
    sc = find_tool("spirv-cross")

    with tempfile.TemporaryDirectory(prefix="slr_") as td:
        td = Path(td)
        src_path = td / (shader.path.stem + ".hlsl")
        src_path.write_text(src, encoding="utf-8")

        # Preprocess once: its text is the cache key (covers every included file).
        pre = td / "pre.hlsl"
        r = _run([dxc, "-P", "-Fi", str(pre), "-HV", "2018"] + sum((["-I", d] for d in includes), [])
                 + [str(src_path)])
        if r.returncode != 0 or not pre.exists():
            diags = _parse_diags(r.stdout + r.stderr)
            raise CompileError(f"{shader.path.name}: preprocess failed\n{(r.stdout + r.stderr).strip()}", diags)
        pre_text = pre.read_text(encoding="utf-8", errors="replace")
        # #line markers carry absolute temp paths; drop them from the key.
        key_text = re.sub(r'^#line.*$', '', pre_text, flags=re.M)
        h = hashlib.sha256()
        for part in (PIPELINE_VERSION, tool_versions(), optimize, p.vertex, p.fragment,
                     "flipy" if flip_y else "", key_text):
            h.update(part.encode("utf-8")); h.update(b"\0")
        key = h.hexdigest()[:24]

        cdir = cache_dir() / key
        meta = cdir / "meta.json"
        if use_cache and meta.exists():
            m = json.loads(meta.read_text(encoding="utf-8"))
            return CompiledPass(shader, p, keywords,
                                StageOutput((cdir / "vert.glsl").read_text(encoding="utf-8"), m["vert_reflect"]),
                                StageOutput((cdir / "frag.glsl").read_text(encoding="utf-8"), m["frag_reflect"]),
                                key, m.get("warnings", []))

        warnings = []
        outs = {}
        for stage, profile, entry in (("vert", "vs_6_0", p.vertex), ("frag", "ps_6_0", p.fragment)):
            spv = td / f"{stage}.spv"
            cmd = [dxc, "-T", profile, "-E", entry, optimize, "-Fo", str(spv)] + _dxc_common(includes) + [str(src_path)]
            r = _run(cmd)
            diags = _parse_diags(r.stdout + r.stderr)
            if r.returncode != 0 or not spv.exists():
                errs = [d for d in diags if d.severity == "error"] or diags
                msg = "\n".join(str(d) for d in errs[:40]) or (r.stdout + r.stderr).strip()[-4000:]
                raise CompileError(f"{shader.path.name} [{p.name}] {stage} ({entry}) failed:\n{msg}", diags)
            warnings += [str(d) for d in diags if d.severity == "warning"]
            glsl_path = td / f"{stage}.glsl"
            r = _run([sc, str(spv), "--version", "450", "--no-es", "--combined-samplers-inherit-bindings"]
                     + (["--flip-vert-y"] if flip_y and stage == "vert" else [])
                     + ["--output", str(glsl_path)])
            if r.returncode != 0:
                raise CompileError(f"{shader.path.name} [{p.name}] {stage}: spirv-cross failed:\n{r.stderr.strip()}")
            refl_path = td / f"{stage}.json"
            r = _run([sc, str(spv), "--reflect", "--output", str(refl_path)])
            if r.returncode != 0:
                raise CompileError(f"{shader.path.name} [{p.name}] {stage}: reflection failed:\n{r.stderr.strip()}")
            outs[stage] = StageOutput(_post_glsl(glsl_path.read_text(encoding="utf-8"), stage),
                                      json.loads(refl_path.read_text(encoding="utf-8")))

        if use_cache:
            cdir.mkdir(parents=True, exist_ok=True)
            (cdir / "vert.glsl").write_text(outs["vert"].glsl, encoding="utf-8")
            (cdir / "frag.glsl").write_text(outs["frag"].glsl, encoding="utf-8")
            meta.write_text(json.dumps({"shader": str(shader.path), "pass": p.name, "keywords": keywords,
                                        "vert_reflect": outs["vert"].reflection,
                                        "frag_reflect": outs["frag"].reflection,
                                        "warnings": warnings[:200]}), encoding="utf-8")
        return CompiledPass(shader, p, keywords, outs["vert"], outs["frag"], key, warnings)
