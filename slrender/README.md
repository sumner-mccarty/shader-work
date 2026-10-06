# slrender — Unity shaders, rendered without Unity

`slrender` compiles a Unity ShaderLab `.shader` file and renders it to a PNG — on Linux, Windows or
macOS, with or without a GPU, in about a second once warm. No editor, no Play Mode, no import.
It exists so people and AI workers can write, tune and judge shaders in a loop measured in seconds
instead of minutes: **edit → compile → render → look → repeat**.

```
.shader ──ShaderLab parse──▶ program + Properties + render state
        ──DXC (HLSL → SPIR-V, -HV 2018)──▶ ──SPIRV-Cross──▶ GLSL 4.50 + reflection
        ──OpenGL (GPU or Mesa llvmpipe)──▶ the pass drawn the way Graphics.Blit draws it ──▶ PNG
```

DXC + SPIRV-Cross is the same route Unity takes when it compiles with DXC (the editor ships both).
Unity's own include files are replaced by a small shim written for this tool (`unity_shim/`).

## How close to Unity is it?

Measured, not assumed — `tests/parity.py` renders 30 cells in the real editor (`SkinSheet.cs`) and
compares them pixel for pixel with slrender (all nine widget shaders, raymarched and flat, every
shipped look, shadows, states, supersampling, off-centre positions):

* non-raymarched shaders: **exact** (max error 1/255 — rounding);
* raymarched shaders: no systematic difference (bias ≤ 0.9/255); per-pixel noise only where two
  compilers can never agree bit-for-bit — the 1-px hit/miss ring of a raymarched silhouette and
  patterns finer than a pixel. After a 1-px blur, mean error ≤ 1.0/255 on every cell;
* identical on an Intel GPU and on Mesa llvmpipe (the cloud configuration).

Getting there found two editor bugs, now fixed in `SkinSheet.cs`: unpinned `_Time` (every
gradient whose skin leaves its speed at the default 1 scrolls) and an unpinned `_GlobalViewCam`
(raymarched controls leaned by whatever the last Play session left in that global).

### Orientation: "screen" vs "texture"

Unity on D3D11/Metal/Vulkan flips the projection when it renders **into a texture**, so screen
derivatives (`ddx`/`ddy`/`fwidth`) point opposite ways in a Blit and on the backbuffer. Any normal
built from them — SDF bevels, pattern bump — lights the other way up. That is the "recessed on the
SkinSheet, raised in Play Mode" bug in the skin-authoring skill. slrender renders either:

* `screen` (default for skins and the CLI) — what the running app shows;
* `texture` — what `Graphics.Blit` / `SkinSheet.cs` writes (used by the parity test).

## Install

From a checkout of this repo:

```bash
bash Tools/setup_toolchain.sh                                   # Linux / macOS
powershell -ExecutionPolicy Bypass -File Tools/setup_toolchain.ps1 [-Mesa]   # Windows
python -m slrender doctor
```

The scripts put pinned, checksummed builds of DXC and SPIRV-Cross in `.toolchain/` and install
`moderngl numpy pillow`. On Linux they also install Mesa's EGL + llvmpipe (no GPU or display needed).

As a package in any environment: `pip install "git+https://github.com/sumner-mccarty/shader-work"`
(gives a `slrender` command), then point it at the tools with `SLRENDER_TOOLCHAIN=<checkout>/.toolchain`
or put `dxc` and `spirv-cross` on PATH (`SLRENDER_DXC` / `SLRENDER_SPIRV_CROSS` also work).

## Use it on any Unity project

```bash
slrender --project /path/to/UnityProject compile --all          # every .shader under Assets/Shaders
slrender --project ... props "Custom/MyShader"                  # Properties as JSON
slrender --project ... render --shader "Custom/MyShader" --set _Color=#FF8800 --set _Glow=0.6 \
         --size 256x256 -o out.png                              # raw material values
slrender --project ... render --shader Custom/MyShader --props material.json --texture _MainTex=albedo.png
slrender contact "renders/*.png" -o sheet.png                   # one image to look at
```

`--project` is any folder with `Assets/Shaders/` (or `Shaders/`). Shaders are found by Unity name
(`"UI/SDFKnob"`), file name (`SDFKnob.shader`) or path. Errors come back as
`File.shader:line:col: error: ...` against the original file.

### The AI shader loop (any project)

1. Write or edit `Assets/Shaders/Foo.shader` (CGPROGRAM or HLSLPROGRAM).
2. `slrender compile Foo.shader` until clean — DXC is strict and fast; fix what it says.
3. Render a sweep of the properties that matter (`--set` per image, or a Python loop over
   `Renderer.render`), tile them with `slrender contact`, and LOOK at the sheet.
4. Iterate. When it is right, drop the file into the Unity project — it compiles there unchanged
   (Unity uses FXC on D3D11, which is occasionally stricter about loop unrolling and register
   counts on very large shaders; check the console once).

### Python API

```python
from slrender import Renderer, TextureSpec, to_image
r = Renderer(["path/to/Assets/Shaders"], software=False)          # software=True → llvmpipe
img = r.render("UI/SDFButton",                                     # name, filename or path
               props={"_ButtonColor": (0.9, 0.6, 0.2, 1.0), "_ButtonBevelEnabled": 1},
               size=(120, 56), globals_={"_GlobalLightPos1": (0.5, 1.2, 0.4)},
               keywords=["UNITY_UI_CLIP_RECT"], textures={"_MainTex": TextureSpec(data="a.png")},
               bg=(0.1, 0.1, 0.12, 1.0), time=0.0, orientation="screen")   # HxWx4 uint8, row 0 = top
to_image(img).save("out.png")
```

Values layer like a Unity material: zero < globals < Properties defaults < `props`. Matrices are
given in HLSL math order (`mul(M, v)`); arrays as lists; ints/bools are converted for you.

Skin layer (DrumSumDrum `.states.json`): `slrender.skins.SkinRenderer(project).render_cell(cell)` —
the SkinSheet job schema (`.claude/skills/skin-authoring/references/tooling.md`) plus
`orientation`, `time`, `viewCam`, `globals`. `python -m slrender job job.json` runs a whole job;
`python -m slrender watch --bus .skinsheet` answers `Tools/skinsheet.py` like the Unity editor does,
from a warm process (set `SKINSHEET_BACKEND=bus`).

## Speed

DXC compiles even the 2,600-line raymarched knob in ~1–6 s (fxc: >10 min). Results are cached by the
hash of the *preprocessed* source, so editing any `.cginc` recompiles exactly what includes it.
The GL driver compiles each program once per process: instant on a GPU, ~20 s for the largest
shaders on llvmpipe — keep one process alive (`watch`, or one Python session) while iterating.
Warm renders take 10–60 ms.

## Supported / not (yet)

Supported: CGPROGRAM and HLSLPROGRAM passes, CGINCLUDE/HLSLINCLUDE, `multi_compile`/`shader_feature`
keywords, Properties defaults (incl. `[PerRendererData]` textures), DX9 `sampler2D/tex2D*` and modern
`Texture2D/SamplerState`, `Texture2DArray`, user cbuffers, arrays, matrices, `Blend`/`BlendOp`
(including `[_SrcBlend]` property-driven factors), `_Time`, `_ScreenParams`, `ComputeScreenPos`.

Not supported: surface shaders (`#pragma surface`), GrabPass, stencil/depth/MSAA, geometry and
tessellation stages, multi-pass compositing (render passes individually with `pass_index`), URP/HDRP
ShaderGraph or `Packages/com.unity.render-pipelines.*` includes (a shim for the URP ShaderLibrary
is the natural next step), and most of UnityCG beyond what UI/full-quad shaders use — the shim grows
as needed: an "undeclared identifier" from `slrender compile` names exactly what to add.

## Files

| | |
|---|---|
| `shaderlab.py` | ShaderLab parser (Properties, passes, render state, pragmas, includes) |
| `compiler.py`  | DXC → SPIR-V → GLSL, reflection, preprocess-hash cache, toolchain lookup |
| `render.py`    | GL renderer: uniform packing from reflection, textures, blend, orientation, readback |
| `skins.py`     | DrumSumDrum skin semantics: state chains, light rig, pinned globals, shadow pass, jobs |
| `unity_shim/`  | HLSLSupport / UnityShaderVariables / UnityCG / UnityUI stand-ins |
| `__main__.py`  | CLI (`doctor compile props render job watch contact glsl`) |
