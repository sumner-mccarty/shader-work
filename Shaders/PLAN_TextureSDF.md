# Texture SDF Shape Integration Plan

## Overview

Add texture-based SDF shapes as an extension to the existing procedural shape dispatchers (`getKnobSDF`, `getButtonSDF`, `getIconSDF`), using a `Texture2DArray` with a dummy fallback.

### What we keep from the original proposal
- `Texture2DArray` for all texture-based shapes
- 1×1×1 dummy texture fallback (pixel = 0.5, surface boundary)
- R-channel SDF format (0..1 stored, remapped to signed distance)
- Uniform-controlled gating (near-zero cost when unused)

### What we drop
- **Shape struct + eval loop** — each component uses ONE shape, not a scene. The `evaluateScene()` loop solves a problem that doesn't exist here.
- **GLSL syntax** — this is Unity HLSL (`float2`/`float4`, `Texture2DArray`, `SampleLevel`)
- **MSDF** — R-channel SDF is sufficient for shape boundaries. Defer MSDF to later.

### Key constraint: Raymarching LOD
RM shaders call the shape SDF ~96+ times per pixel inside a loop. Screen-space derivatives (`ddx`/`ddy`) are invalid there, so `tex2D()`/`Sample()` won't work. All texture sampling must use **`SampleLevel(sampler, uv, 0)`**. This is correct for SDF data — it's a lookup table, not a visual texture.

---

## Phase 1: Texture Infrastructure

- [x] **1.1** Create `Shaders/CG/SDF/SDFTextures.cginc` (NEW file)
  - Declare `Texture2DArray _SDFShapeTexArray` + `SamplerState sampler_SDFShapeTexArray`
  - Implement `sampleTextureSDF(float2 uv, int layer)`:
    - Uses `_SDFShapeTexArray.SampleLevel(sampler, float3(uv, layer), 0).r`
    - Remaps R from 0..1 → signed distance: `v * 2.0 - 1.0`
    - Returns `1e5` when `layer < 0` (disabled sentinel)
  - Include coord-mapping helper: local SDF coords (centered origin, radius-normalized) → UV [0,1]

- [x] **1.2** Add texture uniforms to `Shaders/CG/SDF/SDFKnobUniforms.cginc`
  - `float _KnobShapeTexLayer;` (int, -1 = disabled)
  - `float2 _KnobShapeTexScale;` (UV scale)
  - `float _KnobFaceShapeTexLayer;` (for independent face shape)
  - `float2 _KnobFaceShapeTexScale;`
  - `float _NubShapeTexLayer;` / `float _KnobNubShapeTexLayer;` (if nub supports shapes)

- [x] **1.3** Add texture uniforms to `Shaders/CG/SDF/SDFButtonUniforms.cginc`
  - `float _ButtonShapeTexLayer;`
  - `float2 _ButtonShapeTexScale;`
  - `float _FaceShapeTexLayer;` (for button face shape)
  - `float2 _FaceShapeTexScale;`
  - `float _IconShapeTexLayer;`
  - `float2 _IconShapeTexScale;`

- [x] **1.4** Add `Texture = 100` enum values in `Shaders/ShaderConstants.cs`
  - `KnobShapeType.Texture = 100`
  - `ButtonShapeType.Texture = 100`
  - `IconShapeType.Texture = 100`
  - Value 100 avoids collision with future procedural shapes (leaves ~78 slots)

- [x] **1.5** Create `Scripts/SDFShapeTextureManager.cs` (NEW file)
  - `[RuntimeInitializeOnLoadMethod]` or `Awake()` on a singleton
  - Create 1×1×1 `Texture2DArray` with `TextureFormat.R8`, pixel value = 128 (0.5 normalized)
  - Bind globally: `Shader.SetGlobalTexture("_SDFShapeTexArray", dummyTex)`
  - Public API: `SetTextureArray(Texture2DArray realArray)` to replace with real data
  - Public API: `int AddShape(Texture2D sdfTexture)` — blit into array, return layer index

---

## Phase 2: Shape Dispatcher Integration

- [x] **2.1** Add `case 100` to `getKnobSDF` in `Shaders/CG/SDF/SDFKnobShapes.cginc` (line ~419, before `default:`)
  - UV mapping: `(p / radius) * _KnobShapeTexScale * 0.5 + 0.5`
  - Call `sampleTextureSDF(uv, (int)_KnobShapeTexLayer)`
  - Scale result by `radius` to match procedural distance scale
  - ```hlsl
    case 100: // Texture SDF
    {
        float2 texUV = (p / radius) * _KnobShapeTexScale * 0.5 + 0.5;
        rawSDF = sampleTextureSDF(texUV, (int)_KnobShapeTexLayer) * radius;
        break;
    }
    ```

- [x] **2.2** Add `case 100` to `getButtonSDF` in `Shaders/CG/SDF/SDFButtonShapes.cginc` (line ~159, before `default:`)
  - UV mapping: `(p / halfSize) * _ButtonShapeTexScale * 0.5 + 0.5`
  - Scale result by `minDim`
  - ```hlsl
    case 100: // Texture SDF
    {
        float2 texUV = (p / halfSize) * _ButtonShapeTexScale * 0.5 + 0.5;
        d = sampleTextureSDF(texUV, (int)_ButtonShapeTexLayer) * minDim;
        break;
    }
    ```

- [x] **2.3** Add `case 100` to `getIconSDF` in `Shaders/CG/SDF/SDFButtonLayers.cginc` (line ~99, before `default:`)
  - Same pattern with icon-specific coord mapping
  - ```hlsl
    case 100: // Texture SDF
    {
        float iconDim = min(width, height);
        float2 texUV = (p / (float2(width, height) * 0.5)) * _IconShapeTexScale * 0.5 + 0.5;
        return sampleTextureSDF(texUV, (int)_IconShapeTexLayer) * iconDim * 0.5;
    }
    ```

---

## Phase 3: Shader Properties & Includes

- [x] **3.1** `Shaders/SDFKnob.shader` — Add Properties + include
  - Add to Properties block:
    ```
    _KnobShapeTexLayer ("Knob Shape Tex Layer", Float) = -1
    _KnobShapeTexScale ("Knob Shape Tex Scale", Vector) = (1, 1, 0, 0)
    _KnobFaceShapeTexLayer ("Knob Face Shape Tex Layer", Float) = -1
    _KnobFaceShapeTexScale ("Knob Face Shape Tex Scale", Vector) = (1, 1, 0, 0)
    ```
  - Add `#include "CG/SDF/SDFTextures.cginc"` to CGPROGRAM includes

- [x] **3.2** `Shaders/SDFKnobRM.shader` — Same as 3.1

- [x] **3.3** `Shaders/SDFButton.shader` — Add Properties + include
  - Add to Properties block:
    ```
    _ButtonShapeTexLayer ("Button Shape Tex Layer", Float) = -1
    _ButtonShapeTexScale ("Button Shape Tex Scale", Vector) = (1, 1, 0, 0)
    _FaceShapeTexLayer ("Face Shape Tex Layer", Float) = -1
    _FaceShapeTexScale ("Face Shape Tex Scale", Vector) = (1, 1, 0, 0)
    _IconShapeTexLayer ("Icon Shape Tex Layer", Float) = -1
    _IconShapeTexScale ("Icon Shape Tex Scale", Vector) = (1, 1, 0, 0)
    ```
  - Add `#include "CG/SDF/SDFTextures.cginc"` to CGPROGRAM includes

- [x] **3.4** `Shaders/SDFButtonRM.shader` — Same as 3.3

---

## Phase 4: Verification

- [ ] **4.1** All 4 shaders compile with no errors (check Unity console)
- [ ] **4.2** Regression: existing procedural shapes render identically with dummy texture bound
- [ ] **4.3** Texture shape test: set `_KnobShapeType = 100`, bind a circle SDF texture → renders circle matching procedural circle
- [ ] **4.4** RM test: raymarched knob/button with texture shape renders correctly (no black/broken artifacts from LOD issues)
- [ ] **4.5** Performance: profile RM shader — expect <5% overhead when texture path unused (branch skipped), <15% when active

---

## Phase 5: Optional — Editor / Material Integration

- [ ] **5.1** Update MaterialStateStack or custom inspectors to expose texture layer selection (defer if not straightforward)
- [ ] **5.2** Add SDF texture generation tooling (SVG → SDF bake, Unity Editor tool — out of scope for initial implementation)

---

## Files Summary

| File | Action | Phase |
|------|--------|-------|
| `Shaders/CG/SDF/SDFTextures.cginc` | **CREATE** | 1 |
| `Scripts/SDFShapeTextureManager.cs` | **CREATE** | 1 |
| `Shaders/CG/SDF/SDFKnobUniforms.cginc` | EDIT — add tex uniforms | 1 |
| `Shaders/CG/SDF/SDFButtonUniforms.cginc` | EDIT — add tex uniforms | 1 |
| `Shaders/ShaderConstants.cs` | EDIT — add enum values | 1 |
| `Shaders/CG/SDF/SDFKnobShapes.cginc` | EDIT — add `case 100` | 2 |
| `Shaders/CG/SDF/SDFButtonShapes.cginc` | EDIT — add `case 100` | 2 |
| `Shaders/CG/SDF/SDFButtonLayers.cginc` | EDIT — add `case 100` | 2 |
| `Shaders/SDFKnob.shader` | EDIT — Properties + include | 3 |
| `Shaders/SDFKnobRM.shader` | EDIT — Properties + include | 3 |
| `Shaders/SDFButton.shader` | EDIT — Properties + include | 3 |
| `Shaders/SDFButtonRM.shader` | EDIT — Properties + include | 3 |

---

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| `shapeType = 100` for texture | Leaves ~78 slots for future procedural shapes |
| Always `SampleLevel(LOD 0)` | Correct for SDF data; avoids RM derivative issues |
| Single global `_SDFShapeTexArray` | All components share one array, layer index differentiates |
| Dummy 1×1×1 with R=0.5 | Surface boundary → no visual artifact when unbound |
| Drop Shape struct + eval loop | Single-shape-per-component architecture doesn't need it |
| Drop MSDF | R-channel sufficient for shape boundaries |
| Rotation via existing `_ShapeRotation` | No extra UV rotation params needed |

---

## Texture Format Notes

- **Recommended starting format**: 128×128 R8 per shape
- **Higher detail**: 256×256 or R16 for sub-pixel precision
- **SDF convention**: 0.5 = surface boundary, <0.5 = inside, >0.5 = outside
- **Unity max layers**: 2048 per Texture2DArray (atlas/paging if more needed — defer)
