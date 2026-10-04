# Android shader startup / crash analysis

Scope: static analysis of this repo only. It contains `Shaders/` but no Unity project, scenes,
materials-in-use, C# managers or build settings, so nothing here was compiled, run on a device or
profiled. "Measured" below means counted from the source; "Hypothesis" means inferred and must be
confirmed with the steps in section 4 before anything is changed.

## 1. Measured (from source)

Baseline produced by a script that expands `#include`s and counts calls and loops (the script was
a scratch file and is not part of the repo; rerun it after any change to compare).

| Shader | Lines after includes | `getKnobSDF` inlined | Loops | Largest loop bound |
|---|---|---|---|---|
| SDFKnobRM | 27,965 | 10 | 89 | 64 (raymarch) |
| SDFKnob | 26,964 | 8 | 87 | 4 |
| SDFSliderRM | 27,729 | 0 | 89 | 128 |
| SDFButtonRM | 25,531 | 0 | 86 | 64 |
| SDFSlider / Button / Panel / TogglePill(RM) | 25,000-25,900 | 0 | 83-85 | 4-5 |
| SDFRhythmTrack, SDFScope, SDFWaveform | 2,900-4,100 | 0 | 3-7 | 1-20 |
| Glow, LoadingPads, MaskedSprite, SDFIcon, UIGameFx | under 200 | 0 | 0 | 0 |

- Eleven shaders each pull in the whole core library (UIPatterns, UILighting, UIDisplaySurface,
  UIEffects, ...) and expand to roughly 25-28k lines, whether or not they use it.
- The shape switch in `getKnobSDF` has 23 cases and is marked `[forcecase]`. `SDFKnobRM` inlines it
  10 times (about 230 shape evaluations in one fragment function). Inside the 64-step march loop
  each step calls `evalKnobSDF` and `computeFaceSDF`, so both switches sit inside the loop body.
- Every property is a runtime `float` (676 properties in `SDFKnobRM`, 658 in `SDFKnob`), so nothing
  is dead-code-eliminated per material. Every material compiles and runs the full feature set.
- Keyword variants are tiny: one `multi_compile __ UNITY_UI_CLIP_RECT` (2 variants) per shader.
  Variant count is not the problem here.
- Precision: `float` outnumbers `half`/`fixed` by 10-30x in the heavy shaders, and `v2f` uses
  `fixed4`, with no `SHADER_API_MOBILE` handling anywhere in the repo.
- The repo contains six `__probe_*` copies of `SDFKnobRM` and `SDFSliderRM` (3,200 lines each),
  which test `use_dxc` and `skip_optimizations`. They add 6 more heavy shaders to import and,
  if referenced or in Always Included Shaders, to the build.

## 2. Hypotheses about the 2-minute start and the crash

1. **Driver-side compile of huge programs (most likely cause of the 2 minutes).** On Android the
   GLES3/Vulkan driver compiles each program the first time it is used. ~28k-line sources with
   inlined 23-way switches inside a 64-128 step loop are the kind of input that makes Mali/Adreno
   compilers take seconds each, and ~11 such shaders back to back adds up. Falls out of section 1
   but is not yet timed.
2. **Crash from compiler or shader memory (likely).** Driver compile of these programs can exhaust
   memory on low-RAM devices, and the crash follows the heavy-shader work. Needs a logcat to
   confirm (OOM kill vs. GPU driver abort vs. managed exception).
3. **Runtime cost after start (separate issue).** 64-128 march steps, each evaluating the shape
   switch for base and face SDFs, per pixel and per widget is expensive on mobile GPUs even once
   compiled. This hurts frame time and thermal behaviour, not startup.
4. **Texture memory (unverified).** `_SDFShapeTexArray` is a Texture2DArray. Its size and format
   are decided in C# (`SDFShapeTextureManager`, `SdfAtlas`), which is not in this repo. An
   uncompressed RGBA array could matter. Single R-channel use suggests a one-channel format would do.
5. **Runtime shader creation / warmup (unverifiable here).** No C# in this repo calls
   `Shader.Find`, `new Material` or `WarmUp`; the manager code that might is outside it.

## 3. Recommended changes (not yet applied, in order of safety)

PC rendering must stay unchanged, so every shader edit below is gated by `SHADER_API_MOBILE` (or
a mobile-only keyword) so desktop compiles identical code.

1. Remove the six `__probe_*` shaders from the project (or move outside `Assets/`) and confirm
   no Always Included / Resources / scene reference. Zero visual risk.
2. Mobile-only reduction of march steps (64 to about 32, 128 to about 64 for the slider), with an
   early-out on a looser epsilon. Check visually on device: this is the one change that can alter
   output on Android, so compare screenshots.
3. Replace `fixed4` in `v2f` and non-accumulating colour maths with `half` on mobile only.
4. Reduce compile size: have each shader include only the cginc modules it uses, or split the
   shape switch behind `shader_feature_local` keywords (needs the C# material code to set them,
   so deferred until that code is available).
5. Build tooling (editor script): strip `UNITY_UI_CLIP_RECT` variants not used on Android, log
   per-shader compile time via the build report, and add a `ShaderVariantCollection` warmup
   spread across frames behind the loading screen instead of in one hitch.
6. Texture: confirm the array format is a compressed single-channel format (ASTC/R8) on Android.

## 4. How to establish the evidence before changing anything

1. Make a Development Build with Autoconnect Profiler and "Deep Profiling" off. Capture the first
   2 minutes; look at `Shader.CreateGPUProgram`, `Shader.Parse`, and `ShaderLab.WarmupAll`.
2. `adb logcat -b all` through startup and the crash. Filter for `Unity`, `libc`, `lowmemorykiller`,
   `Mali`/`Adreno`, and `AndroidRuntime`. This distinguishes OOM kill from driver abort.
3. Editor: Window > Analysis > Shader compile report, or `Editor.log` "Compiled shader" lines,
   for per-shader compile time and variant count (confirm the 2-variant count above).
4. Memory Profiler snapshot at startup on the device; check Texture2DArray size and shader memory.
5. Test one change at a time (step 1, then 2, ...) and record startup seconds and peak memory.

## 5. What I need to continue

- The Unity project (or at least `Assets/` scripts that touch shaders: `SDFShapeTextureManager`,
  `SdfAtlas`, any material setup code), and the Android player settings (graphics API, ASTC, etc.).
- One logcat from a failing run and one profiler capture. With those I can turn hypotheses
  1-5 into confirmed causes and apply section 3 safely.
- A target device model (GPU vendor changes which fixes matter) and iOS follow-up: the mobile guards
  here are written for reuse on iOS/Metal.
