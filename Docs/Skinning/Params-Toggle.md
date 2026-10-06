# SDFTogglePill / SDFTogglePillRM — Parameter Reference

Source read in full: `Assets/Shaders/SDFTogglePill.shader`, `Assets/Shaders/SDFTogglePillRM.shader`,
`Assets/Shaders/CG/SDF/SDFTogglePillDefs.cginc`, `Assets/Shaders/CG/SDF/SDFToggleSharedUniforms.cginc`,
`Assets/Shaders/CG/SDF/SDFToggleLayers.cginc`, `Assets/Shaders/CG/SDF/SDFToggleRenderCore.cginc`, plus
`Assets/Shaders/CG/SDF/SDFPillShapes.cginc` (the actual shape SDFs — included by both `.shader` files
but not in the original read list; read anyway since it's where `_Value` actually drives the handle,
which the task specifically asked about). Enums cross-checked against `ShaderConstants.cs`.

**Both `.shader` files share one fragment implementation.** `SDFToggleRenderCore.cginc`'s `frag()` is
the single body for both the flat pass (`SDFTogglePill.shader`) and the "Raymarch" pass
(`SDFTogglePillRM.shader`) — the RM shader's Properties block adds `_ViewTilt`/`_ViewAngle`/`_ViewFOV`/
`_ViewShift` and includes `SDF3DExtrusion.cginc`, but **`SDFToggleRenderCore.cginc` never references
any of those four uniforms or any raymarch/extrusion function**. Despite the "Raymarch" pass name and
the CLAUDE.md description of RM variants replacing section 9 with a sphere-marched extrusion, this
particular RM shader currently renders **identically** to the flat variant — see Gotchas.

Render order in `SDFToggleRenderCore.cginc`'s `frag()` (this doc groups properties by these sections):

1. Edge indent
2. External shadows (×3)
3. Background (`Bg`)
4. Track (the pill groove)
5. Toggle body shadows (×3)
6. LED bloom (halo, drawn before the body so the body occludes its center)
7. Toggle body (the sliding **Handle**/ball — uniform-bridged from generic `_Toggle*` to `_Handle*`)
8. Toggle face (**Handle Face** — a flat highlight disc on the ball)
9. Type-specific extras (`TOGGLE_TYPE_EXTRAS` — **not defined for Pill**, no-op)
10. Border

Plus: Core state (`_Value`, `_StateCount`), 3 scene lights (shared, not per-material), and the
inert RM-only view properties.

---

## 0. Naming: `_Toggle*` vs `_Handle*` vs `_Bg*` vs `_Track*`

`SDFToggleRenderCore.cginc` is written once, generically, against `_Toggle*`/`_ToggleFace*` names so it
can be shared by every future toggle archetype (rocker, bat, rotary, …). `SDFTogglePillDefs.cginc`
`#define`s every `_Toggle*`/`_ToggleFace*` symbol the render core reads to the semantically-named
`_Handle*`/`_HandleFace*` uniforms that are actually exposed in the Pill shader's Properties block:

```
#define _ToggleEnabled       _HandleEnabled
#define _ToggleColor         _HandleColor
... (full body/bevel/pattern/gradient/rim set)
#define _ToggleFaceEnabled   _HandleFaceEnabled
...
```

So **every property this doc calls "Handle" is what the render core internally calls "Toggle body,"**
and every "Handle Face" property is internally "Toggle face." The generic `_Toggle*` names are not
separately bindable material properties on the Pill shaders — only `_Handle*`/`_HandleFace*` exist in
the Properties block. `_TogglePadding` has no exposed property at all; it's hard-`#define`d to `0.0`
for Pill (the handle/track region fills the entire Bg interior with no extra inset).

---

## 1. Core state

| Property | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_Value` | Float | 0‑1 | 0 | **The on/off (or multi-state) state.** Continuous float, not a bool and not a separate `_On` property. Drives the handle's X position directly in `getPillBodySDF` (`ballX = lerp(-travelHW, travelHW, t)`) and blends `_LedColor`/`_HandleFaceColor`/`_HandleColor` toward the LED color via `_LedSurfaceBlend * _Value` wherever that's enabled. There is no discrete "state" uniform separate from this float — a binary toggle just animates `_Value` between 0 and 1 (typically via DOTween per `MaterialStateEngine`'s transition model, per CLAUDE.md). |
| `_StateCount` | Int (`IntRange`) | 2‑8 | 2 | When ≥2, `_Value` is **quantized** before positioning the ball: `t = floor(t*(StateCount-1)+0.5) / (StateCount-1)`. At the default 2, this snaps to exactly 0 or 1 (standard binary switch — no continuous drag-glide visual, the ball jumps between the two end positions once `_Value` crosses the halfway point in this formula's rounding). Values >2 make the ball snap to 3‑8 evenly spaced positions along the track, for a multi-position slide switch. Nothing else in the shader (track/Bg/LED color, etc.) changes per discrete position — only the ball's X coordinate. |
| `_AnimT` | Float | — | (none) | Declared in `SDFToggleSharedUniforms.cginc` but **has no Properties-block entry on either Pill shader and is not read anywhere in the Pill render path.** Dead for this control — likely a hook reserved for a future toggle archetype's animation blending. |
| `_ToggleType` | Int | — | (none, `[HideInInspector]` pattern elsewhere) | Declared, meant to be set per-material by the per-type shader, but **not read anywhere in `SDFPillShapes.cginc` or `SDFToggleRenderCore.cginc`** — Pill's shape functions (`getToggleBodySDF`/`getToggleTrackSDF`) are hard-wired to the pill shape directly, no type dispatch. Dead for this control. |

---

## 2. Section 1 — Edge indent

Identical mechanism to Panel's Edge (see `Params-Panel.md` §2) but measured against the **Bg**
shape's rounded-rect SDF, not a Toggle-body SDF.

| Property | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_EdgeEnabled` | Float | — | 0 | Guard. |
| `_EdgeColor` | Color | — | (0,0,0,0.5) | Base edge-band color. |
| `_EdgeRenderAlpha` | Float | 0‑1 | 1 | Alpha multiplier. |
| `_EdgeRenderEmissive` | Float | 0‑1 | 0 | Additive emissive contribution. |
| `_EdgeWidth` | Float | 0.001‑0.2 | 0.03 | Band width outward from the inset boundary (note: tighter range than Panel's 0.001‑1.0). |
| `_EdgeSoftness` | Float | 0‑1 | 0.5 | 0 = hard falloff; >0 = `pow()`-curve soft falloff. |
| `_EdgeIntensity` | Float | 0‑2 | 1.0 | Multiplies the computed mask. |
| `_EdgeInset` | Float | -0.1‑0.1 | 0.0 | Shifts the reference boundary (can go negative here, unlike Panel's 0‑0.5-only range). |
| `_EdgeGradientEnabled` | Float | — | 0 | Guard for gradient sweep. |
| `_EdgeGradientType` | Int (`Enum(GradientType)`) | 0‑4 | 0 (Linear) | See §7.4. |
| `_EdgeGradientColorA/B/C/D` | Color | — | white → dark gray ramp | Gradient stops. |
| `_EdgeGradientDirection` | Vector2 | — | (1,0,0,0) | Linear/Triangle direction. |
| `_EdgeGradientSpeed` | Float | — | 1.0 | Animation speed. |
| `_EdgeGradientScale` | Float | 0.1‑5 | 1.0 | Spatial frequency. |
| `_EdgeGradientOffset` | Float | -2‑2 | 0.0 | Phase offset. |
| `_EdgeGlobalBlend` | Float | 0‑1 | 0.0 | Blend toward scene-wide global gradient. |
| `_EdgeGlobalIntensity` | Float | 0‑2 | 1.0 | Multiplies global blend factor. |
| `_EdgeGradientColorUsed` | Int (IntRange) | 2‑4 | 4 | Active stop count. |

---

## 3. Section 2 — External shadows (×3)

Cast by the **Bg** shape (approximated as a rounded rect using `_BgRounding`, regardless of any
toggle-type-specific body shape) onto the background behind the whole widget. Same mechanics as
Panel's external shadows (`Params-Panel.md` §3).

| Property (×3, N=1,2,3) | Type | Range | Default (Shadow1 shown) | What it does |
|---|---|---|---|---|
| `_LightingShadowNEnabled` | Float | — | 0 | Guard. |
| `_LightingShadowNColor` | Color | — | (0,0,0,0.5/0.3/0.3) | Tint + max alpha. |
| `_LightingShadowNBlur` | Float | 0‑1 | 0.3 | Base blur multiplier (note: 0‑1 range here vs Panel's 0‑2). |
| `_LightingShadowNDistance` | Float | 0‑0.2 | 0.02 | Offset distance. |
| `_LightingShadowNBlurFactor` | Float | 0‑1 | 0.5 | Near/far blur balance. |
| `_LightingShadowNIntensity` | Float | 0‑2 | 1.0 | Multiplies composited alpha. |

---

## 4. Section 3 — Background (`Bg`)

The outer housing/plate the whole switch sits on — always a rounded rect (`RoundedRectSDF`), sized by
padding in from the widget's aspect-scaled half-extent. Full bevel/pattern/gradient/rim material
pipeline, same structure as Panel's main body.

### 4.1 Bg core & geometry

| Property | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_BgEnabled` | Float | — | 1 | Guard for the entire Bg layer. |
| `_BgColor` | Color | — | (0.18,0.18,0.18,1) | Base color. |
| `_BgRenderAlpha` | Float | 0‑1 | 1 | Alpha multiplier. |
| `_BgRenderEmissive` | Float | 0‑1 | 0 | Additive emissive contribution. |
| `_BgPadding` | Float | 0.0‑1.5 | 0.05 | Equi-unit margin subtracted from the widget's aspect-scaled half-extent (`bgHalfW = aspectScale.x - BgPadding`). Since `_TogglePadding` is hard-wired to 0 for Pill, this single value also determines the Track/Handle's available half-extent (`bodyHalfW = bgHalfW - 0`). |
| `_BgRounding` | Float | 0‑1 | 0.3 | 0 = sharp rect, 1 = full pill/capsule (`r = minDim*(1-saturate(rounding))`, same formula family as Panel's Squircle). Also reused as the Edge/External-shadow/Border reference shape. |

### 4.2 Bg bevel

| Property | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_BgBevelEnabled` | Float | — | 0 | Guard; also gates bevel pattern/gradient regardless of their own flags. |
| `_BgBevelDepth` | Float | -1.0‑1.0 | 0.2 | Signed raised(+)/recessed(-) bevel depth, same tan-remap as Panel. |
| `_BgBevelSmoothness` | Float | 0.001‑1.0 | 0.02 | Dome-profile falloff sharpness. |
| `_BgBevelDistance` | Float | 0.001‑1.0 | 0.1 | Bevel band width inward from the Bg edge. |
| `_BgFaceSmoothness` | Float | -1.0‑1.0 | 0.0 | Dome(+)/bowl(-) profile on the flat interior. |
| `_BgBevelProfileType` | Int | 0,1 | 0 | 0=Dome, 1=Linear — see §7.2. |
| `_BgBevelProfileSharpness` | Float | 0‑1 | 0.5 | Linear-profile slope (unused for Dome). |

### 4.3 Bg bevel pattern / bevel pattern color / bevel gradient

| Property | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_BgBevelPatternEnabled` | Float | — | 0 | Guard. |
| `_BgBevelPatternType` | Int (`Enum(PatternType)`) | 0‑19 | 0 (Plastic) | See §7.3. |
| `_BgBevelPatternScale` | Float | 1‑100 | 20 | **UV-space cycle count — see the Panel doc's §5 grain-scale explanation; identical mechanism here.** |
| `_BgBevelPatternIntensity` | Float | 0‑1 | 0.3 | Brightness modulation strength. |
| `_BgBevelPatternContrast` | Float | 0.1‑5 | 1.5 | Gamma curve on pattern value. |
| `_BgBevelPatternSpecularEffect` | Float | 0‑2 | 1.0 | Specular modulation strength. |
| `_BgBevelPatternRoughnessEffect` | Float | 0‑2 | 0.3 | Normal-perturbation strength. |
| `_BgBevelPatternParam1/2/3` | Float | 0‑1 | 0.5 each | Pattern-specific Detail/Distortion/Blend. |
| `_BgBevelPatternColorEnabled` | Float | — | 0 | Guard for palette recoloring. |
| `_BgBevelPatternColorType` | Int (`Enum(PatternColorType)`) | 0‑3 | 2 (Zones) | See §7.4. |
| `_BgBevelPatternColorMode` | Int (`Enum(PatternColorMode)`) | 0‑3 | 1 (Lerp) | See §7.4. |
| `_BgBevelPatternColorUsed` | Int (IntRange) | 2‑4 | 2 | Active stop count. |
| `_BgBevelPatternColorA/B/C/D` | Color | — | white → dark gray | Palette stops. |
| `_BgBevelGradientEnabled` | Float | — | 0 | Guard. |
| `_BgBevelGradientType` | Int (`Enum(GradientType)`) | 0‑4 | 1 (Radial) | See §7.5. |
| `_BgBevelGradientColorA/B/C/D` | Color | — | white → dark gray | Gradient stops. |
| `_BgBevelGradientDirection` | Vector2 | — | (1,0,0,0) | Linear/Triangle direction. |
| `_BgBevelGradientSpeed` | Float | — | 1.0 | Animation speed. |
| `_BgBevelGradientScale` | Float | 0.1‑5 | 1.0 | Spatial frequency. |
| `_BgBevelGradientOffset` | Float | -2‑2 | 0.0 | Phase offset. |
| `_BgBevelGradientColorUsed` | Int (IntRange) | 2‑4 | 4 | Active stop count. |

### 4.4 Bg rim

| Property | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_BgRimEnabled` | Float | — | 0 | Guard. |
| `_BgRimDepth` | Float | -0.5‑0.5 | 0.1 | Signed raised-lip(+)/sunken-groove(-) tilt at the Bg's outer edge. |
| `_BgRimWidth` | Float | 0.001‑1.0 | 0.02 | Rim band width. Also feeds `bgFaceInset` (`rimWidth + effBevelDist`), which sets where the bevel's "top face" boundary sits. |
| `_BgRimSmoothness` | Float | 0.001‑0.1 | 0.01 | Rim falloff softness. |

### 4.5 Bg surface pattern / pattern color / gradient

| Property | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_BgPatternEnabled` | Float | — | 0 | Guard. |
| `_BgPatternType` | Int (`Enum(PatternType)`) | 0‑19 | 0 (Plastic) | See §7.3. |
| `_BgPatternScale` | Float | 1‑100 | 20 | UV-space cycle count (see Panel doc §5). |
| `_BgPatternIntensity` | Float | 0‑1 | 0.3 | Brightness modulation. |
| `_BgPatternContrast` | Float | 0.1‑5 | 1.5 | Gamma curve. |
| `_BgPatternSpecularEffect` | Float | 0‑2 | 1.0 | Specular modulation. |
| `_BgPatternRoughnessEffect` | Float | 0‑2 | 0.3 | Normal perturbation. |
| `_BgPatternRotateEnabled` | Float | — | 0 | Value-gated rotation — Bg always passes `currentValue=0` in its `ApplyMaterialPattern` call, so **inert**. |
| `_BgPatternModEnabled` | Float | — | 0 | Same — inert for Bg. |
| `_BgPatternModAmount` | Float | 0‑90 | 20 | Inert for Bg (see above). |
| `_BgPatternModFrequency` | Float | 0.1‑10 | 1 | Inert for Bg. |
| `_BgPatternOffset` | Float | -180‑180 | 0 | **Not** value-gated — does work (static rotation). |
| `_BgPatternParam1/2/3` | Float | 0‑1 | 0.5 each | Pattern-specific knobs. |
| `_BgPatternColorEnabled` | Float | — | 0 | Guard for palette recoloring. |
| `_BgPatternColorType` | Int (`Enum(PatternColorType)`) | 0‑3 | 2 (Zones) | See §7.4. |
| `_BgPatternColorMode` | Int (`Enum(PatternColorMode)`) | 0‑3 | 1 (Lerp) | See §7.4. |
| `_BgPatternColorUsed` | Int (IntRange) | 2‑4 | 2 | Active stop count. |
| `_BgPatternColorA/B/C/D` | Color | — | white → dark gray | Palette stops. |
| `_BgGradientEnabled` | Float | — | 0 | Guard. |
| `_BgGradientType` | Int (`Enum(GradientType)`) | 0‑4 | 0 (Linear) | See §7.5. |
| `_BgGradientColorA/B/C/D` | Color | — | dark gray ramp | Gradient stops. |
| `_BgGradientDirection` | Vector2 | — | (0,1,0,0) | Linear/Triangle direction. |
| `_BgGradientSpeed` | Float | — | 1.0 | Animation speed. |
| `_BgGradientScale` | Float | 0.1‑5 | 1.0 | Spatial frequency. |
| `_BgGradientOffset` | Float | -2‑2 | 0.0 | Phase offset. |
| `_BgGlobalBlend` | Float | 0‑1 | 0.0 | Blend toward scene-wide global gradient. |
| `_BgGlobalIntensity` | Float | 0‑2 | 1.0 | Multiplies global blend factor. |
| `_BgGradientColorUsed` | Int (IntRange) | 2‑4 | 4 | Active stop count. |

---

## 5. Section 4 — Track (the pill groove)

The visible channel the handle slides inside. Geometry is derived from the *same* `_TrackHeight`/
`_HandlePadding` values the handle's own radius/travel use (see §6.1) — track and handle sizing are
coupled, not independent.

| Property | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_TrackHeight` | Float | 0‑1 | 0.5 | Track's half-height as a fraction of the toggle body's half-height: `trackHH = bodyHalfH * lerp(0.25, 0.90, TrackHeight)`. **Also feeds the handle's ball radius** (`ballR = trackHH - padding`) — raising this makes both the track *and* the ball bigger. |
| `_TrackCornerRadius` | Float | 0‑1 | 0.25 | 0 = rectangular track ends, 1 = fully rounded/capsule ends (`cornerR = trackHH * saturate(TrackCornerRadius)`, maxes out at a perfect semicircle when it equals `trackHH`). |
| `_TrackInsetDepth` | Float | 0‑1 | 0.5 | **Declared, exposed in the inspector, mapped to `_ToggleParam5`, but never read anywhere in `SDFToggleRenderCore.cginc`'s Track-rendering block.** The Track's actual bevel comes entirely from the separate `_TrackBevelDepth`/`_TrackBevelDistance` properties below. This property currently has **zero visual effect** — see Gotchas. |
| `_TrackEnabled` | Float | — | 1 | Guard for the whole Track layer. |
| `_TrackColor` | Color | — | (0.1,0.1,0.1,1) | Base color. |
| `_TrackRenderAlpha` | Float | 0‑1 | 1 | Alpha multiplier. |
| `_TrackRenderEmissive` | Float | 0‑1 | 0 | Additive emissive contribution. |
| `_TrackBevelEnabled` | Float | — | 0 | Guard for the track's own bevel. |
| `_TrackBevelDepth` | Float | -1.0‑1.0 | **-0.15** (negative default — recessed groove) | Signed bevel depth; negative default deliberately reads as an inset channel, unlike every other bevel-depth default in this codebase which defaults positive. |
| `_TrackBevelSmoothness` | Float | 0.001‑1.0 | 0.02 | Dome falloff sharpness. |
| `_TrackBevelDistance` | Float | 0.001‑1.0 | 0.15 | Bevel band width. |
| `_TrackFaceSmoothness` | Float | -1.0‑1.0 | 0.0 | Dome/bowl profile on the track's flat interior. |
| `_TrackBevelProfileType` | Int | 0,1 | 0 | 0=Dome, 1=Linear — see §7.2. |
| `_TrackBevelProfileSharpness` | Float | 0‑1 | 0.5 | Linear-profile slope. |
| `_TrackPatternEnabled` | Float | — | 0 | Guard. |
| `_TrackPatternType` | Int (`Enum(PatternType)`) | 0‑19 | 0 (Plastic) | See §7.3. |
| `_TrackPatternScale` | Float | 1‑100 | 20 | UV-space cycle count (Panel doc §5). |
| `_TrackPatternIntensity` | Float | 0‑1 | 0.3 | Brightness modulation. |
| `_TrackPatternContrast` | Float | 0.1‑5 | 1.5 | Gamma curve. |
| `_TrackPatternSpecularEffect` | Float | 0‑2 | 1.0 | Specular modulation. |
| `_TrackPatternRoughnessEffect` | Float | 0‑2 | 0.3 | Normal perturbation. |
| `_TrackPatternParam1/2/3` | Float | 0‑1 | 0.5 each | Pattern-specific knobs. Note: Track's `CreateUIComponent` call hard-codes `patternRotateWithValue`/`patternModWithValue`/etc. to 0 — there is **no** `_TrackPatternRotateEnabled`/`ModEnabled`/`ModAmount`/`ModFrequency`/`Offset` property exposed at all for Track (unlike Bg/Handle), so Track's pattern can never rotate. |
| `_TrackPatternColorEnabled` | Float | — | 0 | Guard for palette recoloring. |
| `_TrackPatternColorType` | Int (`Enum(PatternColorType)`) | 0‑3 | 2 (Zones) | See §7.4. |
| `_TrackPatternColorMode` | Int (`Enum(PatternColorMode)`) | 0‑3 | 1 (Lerp) | See §7.4. |
| `_TrackPatternColorUsed` | Int (IntRange) | 2‑4 | 2 | Active stop count. |
| `_TrackPatternColorA/B/C/D` | Color | — | white → dark gray | Palette stops. |
| `_TrackGradientEnabled` | Float | — | 0 | Guard. Note: Track's gradient call passes `globalBlend=0.0, globalIntensity=1.0` hard-coded into `CreateUIComponent` — **there is no `_TrackGlobalBlend`/`_TrackGlobalIntensity` wiring into the actual per-pixel gradient compositing inside the bevel/pattern pipeline**, even though both properties exist and are read separately at lines 220‑222 for the *base* track color's own global-gradient blend before pattern/bevel are applied. |
| `_TrackGradientType` | Int (`Enum(GradientType)`) | 0‑4 | 0 (Linear) | See §7.5. |
| `_TrackGradientColorA/B/C/D` | Color | — | dark ramp | Gradient stops. |
| `_TrackGradientDirection` | Vector2 | — | (0,1,0,0) | Linear/Triangle direction. |
| `_TrackGradientSpeed` | Float | — | 1.0 | Animation speed. |
| `_TrackGradientScale` | Float | 0.1‑5 | 1.0 | Spatial frequency. |
| `_TrackGradientOffset` | Float | -2‑2 | 0.0 | Phase offset. |
| `_TrackGlobalBlend` | Float | 0‑1 | 0.0 | Blends the track's *base* color toward the scene-wide global gradient (applied once, before pattern/bevel — see note above). |
| `_TrackGlobalIntensity` | Float | 0‑2 | 1.0 | Multiplies that blend factor. |
| `_TrackGradientColorUsed` | Int (IntRange) | 2‑4 | 4 | Active stop count. |

---

## 6. Sections 5/6/7/8 — Toggle body shadows, LED, Handle, Handle Face

### 6.1 Handle geometry (drives both the Handle's shape and the Track's coupling — see §5)

| Property | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_HandlePadding` | Float | 0‑1 | 0.3 | Gap between the ball's edge and the track's inner wall: `padding = trackHH * lerp(0.04, 0.30, HandlePadding)`; `ballR = trackHH - padding`. Higher = smaller ball relative to the track (more visible gap); lower = ball nearly fills the track height. |
| `_HandleFlatten` | Float | 0‑1 | 0.3 | 0 = perfect circle. 1 = squished oval, 75% as wide along the travel axis (`flatten = lerp(1.0, 0.75, HandleFlatten)`, `ballPos.x /= flatten` then `ballDist *= flatten` as an **approximate** SDF rescale — not an exact ellipse SDF, may show minor distortion at high values, especially combined with a large bevel). |

### 6.2 Toggle body shadows (×3) — hull-swept cast shadow of the Handle

| Property (×3, N=1,2,3) | Type | Range | Default (Shadow1 shown) | What it does |
|---|---|---|---|---|
| `_ToggleShadowNEnabled` | Float | — | 0 | Guard. Note the shared/generic `_Toggle*` name here — these are **not** bridged to `_Handle*` by the Defs file (only body/face material properties are bridged); `_ToggleShadow1/2/3*` are the actual, directly-bound property names in the Pill Properties block. |
| `_ToggleShadowNColor` | Color | — | (0,0,0,0.5/0.3/0.3) | Tint + max alpha. |
| `_ToggleShadowNBlur` | Float | 0‑1 | 0.2 | Base blur multiplier. |
| `_ToggleShadowNDistance` | Float | 0‑0.2 | 0.01 | Offset distance along light direction. |
| `_ToggleShadowNBlurFactor` | Float | 0‑1 | 0.3 | Near/far blur balance. |
| `_ToggleShadowNIntensity` | Float | 0‑2 | 1.0 | Multiplies composited alpha. |
| `_ToggleShadowNCast` | Float | 0‑2 | 1.0 | Scales `pseudoHeight` for the hull sweep (0 = flat silhouette shadow only). Range extends to 2 here (vs Panel's 0‑1), allowing an exaggerated 3D throw. |

### 6.3 LED

An analytic glow halo (`calculateLedBloom`, exponential falloff) drawn just **outside** the Handle's
silhouette, before the Handle itself is drawn on top (so only the outer glow ring survives visually).

| Property | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_LedEnabled` | Float | — | 0 | Guard. |
| `_LedColor` | Color | — | (0.2,1.0,0.3,1) | Glow tint + alpha multiplier on the composited bloom. |
| `_LedIntensity` | Float | 0‑4 | 1.5 | Overall bloom brightness. **Not** scaled by `_Value` — the bloom is either on (per `_LedEnabled`/`_LedIntensity`) or off, regardless of toggle state; only the *surface* tint (below) is `_Value`-scaled. |
| `_LedGlowRadius` | Float | 0.01‑1.0 | 0.15 | Equi-unit falloff radius the exponential glow normalizes against. |
| `_LedGlowSharpness` | Float | 0.5‑20 | 6.0 | Exponential falloff rate; higher = tighter/closer glow. |
| `_LedSurfaceBlend` | Float | 0‑1 | 0.0 | Blends the Handle body's **and** Handle Face's own base color toward `_LedColor`, scaled by `_Value` (`lerp(baseColor, LedColor, LedSurfaceBlend * _Value)`) — this is the only LED property that visually tracks on/off state. |
| `_LedRenderEmissive` | Float | 0‑4 | 1.5 | Additive emissive contribution from the bloom (separate multiplier from `_LedIntensity`, applied on top of it: `_LedColor.rgb * bloom * _LedRenderEmissive`). |

The glow tracks `getToggleBodySDF` (the moving ball) — since the ball slides with `_Value`, the glow
halo slides with it too. There is no way, in this shader, to have a static LED indicator dot
independent of the handle's position.

### 6.4 Handle (the sliding ball — bridged from generic `_Toggle*`, see §0)

| Property | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_HandleEnabled` | Float | — | 1 | Guard for the entire Handle body + everything gated on it (shadows' `pseudoHeight`, LED bloom's SDF, Handle Face, type extras). |
| `_HandleColor` | Color | — | (0.7,0.7,0.7,1) | Base color. |
| `_HandleRenderAlpha` | Float | 0‑1 | 1 | Alpha multiplier. |
| `_HandleRenderEmissive` | Float | 0‑1 | 0 | Additive emissive contribution. |
| `_HandleBevelEnabled` | Float | — | **1** (on by default, unlike every other bevel in this shader) | Guard; also gates bevel pattern/gradient. |
| `_HandleBevelDepth` | Float | -1.0‑1.0 | 0.25 | Signed raised/recessed bevel depth. |
| `_HandleBevelSmoothness` | Float | 0.001‑1.0 | 0.02 | Dome falloff sharpness. |
| `_HandleBevelDistance` | Float | 0.001‑1.0 | 0.12 | Bevel band width. Also, combined with `_HandleRimWidth`, defines `faceInset` — which gates whether Handle Face (§6.5) is visible at all. |
| `_HandleFaceSmoothness` | Float | -1.0‑1.0 | 0.0 | Dome/bowl profile on the ball's flat interior. |
| `_HandleBevelProfileType` | Int | 0,1 | 0 | 0=Dome, 1=Linear — see §7.2. |
| `_HandleBevelProfileSharpness` | Float | 0‑1 | 0.5 | Linear-profile slope. |
| `_HandleBevelPatternEnabled` | Float | — | 0 | Guard. |
| `_HandleBevelPatternType` | Int (`Enum(PatternType)`) | 0‑19 | 0 (Plastic) | See §7.3. |
| `_HandleBevelPatternScale` | Float | 1‑100 | 20 | UV-space cycle count. |
| `_HandleBevelPatternIntensity` | Float | 0‑1 | 0.3 | Brightness modulation. |
| `_HandleBevelPatternContrast` | Float | 0.1‑5 | 1.5 | Gamma curve. |
| `_HandleBevelPatternSpecularEffect` | Float | 0‑2 | 1.0 | Specular modulation. |
| `_HandleBevelPatternRoughnessEffect` | Float | 0‑2 | 0.3 | Normal perturbation. |
| `_HandleBevelPatternParam1/2/3` | Float | 0‑1 | 0.5 each | Pattern-specific knobs. |
| `_HandleBevelPatternColorEnabled` | Float | — | 0 | Guard for palette recoloring. |
| `_HandleBevelPatternColorType` | Int (`Enum(PatternColorType)`) | 0‑3 | 2 (Zones) | See §7.4. |
| `_HandleBevelPatternColorMode` | Int (`Enum(PatternColorMode)`) | 0‑3 | 1 (Lerp) | See §7.4. |
| `_HandleBevelPatternColorUsed` | Int (IntRange) | 2‑4 | 2 | Active stop count. |
| `_HandleBevelPatternColorA/B/C/D` | Color | — | white → dark gray | Palette stops. |
| `_HandleBevelGradientEnabled` | Float | — | 0 | Guard. |
| `_HandleBevelGradientType` | Int (`Enum(GradientType)`) | 0‑4 | 1 (Radial) | See §7.5. |
| `_HandleBevelGradientColorA/B/C/D` | Color | — | white → dark gray | Gradient stops. |
| `_HandleBevelGradientDirection` | Vector2 | — | (1,0,0,0) | Linear/Triangle direction. |
| `_HandleBevelGradientSpeed` | Float | — | 1.0 | Animation speed. |
| `_HandleBevelGradientScale` | Float | 0.1‑5 | 1.0 | Spatial frequency. |
| `_HandleBevelGradientOffset` | Float | -2‑2 | 0.0 | Phase offset. |
| `_HandleBevelGradientColorUsed` | Int (IntRange) | 2‑4 | 4 | Active stop count. |
| `_HandleRimEnabled` | Float | — | 0 | Guard. |
| `_HandleRimDepth` | Float | -0.5‑0.5 | 0.1 | Signed raised-lip/sunken-groove tilt at the ball's outer edge. |
| `_HandleRimWidth` | Float | 0.001‑1.0 | 0.02 | Rim band width; contributes to `faceInset` alongside bevel distance. |
| `_HandleRimSmoothness` | Float | 0.001‑0.1 | 0.01 | Rim falloff softness. |
| `_HandlePatternEnabled` | Float | — | 0 | Guard. |
| `_HandlePatternType` | Int (`Enum(PatternType)`) | 0‑19 | **1 (Metal)** | See §7.3. (Note the default differs from every other `PatternType` property in both shaders, which default to 0/Plastic — the ball's own surface pattern defaults to a brushed-metal look.) |
| `_HandlePatternScale` | Float | 1‑100 | 20 | UV-space cycle count. |
| `_HandlePatternIntensity` | Float | 0‑1 | 0.3 | Brightness modulation. |
| `_HandlePatternContrast` | Float | 0.1‑5 | 1.5 | Gamma curve. |
| `_HandlePatternSpecularEffect` | Float | 0‑2 | 1.0 | Specular modulation. |
| `_HandlePatternRoughnessEffect` | Float | 0‑2 | 0.3 | Normal perturbation. |
| `_HandlePatternRotateEnabled` | Float | — | 0 | Value-gated (`currentValue` passed as `0.0` by the Handle's own render call too, same as Bg/Panel) — **inert**. |
| `_HandlePatternModEnabled` | Float | — | 0 | Inert, same reason. |
| `_HandlePatternModAmount` | Float | 0‑90 | 20 | Inert. |
| `_HandlePatternModFrequency` | Float | 0.1‑10 | 1 | Inert. |
| `_HandlePatternOffset` | Float | -180‑180 | 0 | Not value-gated — does work. |
| `_HandlePatternParam1/2/3` | Float | 0‑1 | 0.5 each | Pattern-specific knobs. |
| `_HandlePatternColorEnabled` | Float | — | 0 | Guard. |
| `_HandlePatternColorType` | Int (`Enum(PatternColorType)`) | 0‑3 | 2 (Zones) | See §7.4. |
| `_HandlePatternColorMode` | Int (`Enum(PatternColorMode)`) | 0‑3 | 1 (Lerp) | See §7.4. |
| `_HandlePatternColorUsed` | Int (IntRange) | 2‑4 | 2 | Active stop count. |
| `_HandlePatternColorA/B/C/D` | Color | — | white → dark gray | Palette stops. |
| `_HandleGradientEnabled` | Float | — | 0 | Guard. |
| `_HandleGradientType` | Int (`Enum(GradientType)`) | 0‑4 | 1 (Radial) | See §7.5. |
| `_HandleGradientColorA/B/C/D` | Color | — | light → mid gray ramp | Gradient stops. |
| `_HandleGradientDirection` | Vector2 | — | (0,1,0,0) | Linear/Triangle direction. |
| `_HandleGradientSpeed` | Float | — | 1.0 | Animation speed. |
| `_HandleGradientScale` | Float | 0.1‑5 | 1.0 | Spatial frequency. |
| `_HandleGradientOffset` | Float | -2‑2 | 0.0 | Phase offset. |
| `_HandleGlobalBlend` | Float | 0‑1 | 0.0 | Blend toward scene-wide global gradient. |
| `_HandleGlobalIntensity` | Float | 0‑2 | 1.0 | Multiplies global blend factor. |
| `_HandleGradientColorUsed` | Int (IntRange) | 2‑4 | 4 | Active stop count. |

### 6.5 Handle Face (highlight disc — bridged from generic `_ToggleFace*`)

A **flat, unlit** disc composited on top of the Handle to fake a specular highlight/reflection. It has
no bevel, no pattern, and is **not** run through `ApplyUILighting` — only gradient + LED-surface-blend.

| Property | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_HandleFaceEnabled` | Float | — | 1 | Guard. **Only actually renders if `faceInset > 0.001`** — i.e. requires `_HandleBevelEnabled` or `_HandleRimEnabled` to be on with a nonzero distance/width; with both disabled, the highlight silently disappears even though this flag is 1. Also requires the sample point to be inside the Handle body (`toggleBodyDist < 0.001`). |
| `_HandleFaceColor` | Color | — | (0.6,0.6,0.6,1) | Base color (also LED-surface-blended toward `_LedColor * _Value` when `_LedSurfaceBlend>0`). |
| `_HandleFaceRenderAlpha` | Float | 0‑1 | 1 | Alpha multiplier. |
| `_HandleFaceRenderEmissive` | Float | 0‑1 | 0 | Additive emissive contribution. |
| `_HandleFaceSize` | Float | 0.01‑1.0 | 0.75 | Fraction of the Handle's own extent the disc is sized to (`faceMargin = (1-Size)*maxDim`). |
| `_HandleFaceGradientEnabled` | Float | — | 0 | Guard for a gradient sweep over the disc's color. |
| `_HandleFaceGradientType` | Int (`Enum(GradientType)`) | 0‑4 | 1 (Radial) | See §7.5. |
| `_HandleFaceGradientColorA/B/C/D` | Color | — | light → mid gray ramp | Gradient stops. |
| `_HandleFaceGradientDirection` | Vector2 | — | (0,1,0,0) | Linear/Triangle direction. |
| `_HandleFaceGradientSpeed` | Float | — | 1.0 | Animation speed. |
| `_HandleFaceGradientScale` | Float | 0.1‑5 | 1.0 | Spatial frequency. |
| `_HandleFaceGradientOffset` | Float | -2‑2 | 0.0 | Phase offset. |
| `_HandleFaceGradientColorUsed` | Int (IntRange) | 2‑4 | 4 | Active stop count. |

---

## 7. Section 10 — Border, Lighting, RM-only properties

### 7.1 Border

Same mechanism as Panel's Border (`Params-Panel.md` §6), measured against the Bg shape's SDF.

| Property | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_BorderEnabled` | Float | — | 0 | Guard. |
| `_BorderColor` | Color | — | (0,0,0,0.3) | Base border color. |
| `_BorderRenderAlpha` | Float | 0‑1 | 1 | Alpha multiplier. |
| `_BorderRenderEmissive` | Float | 0‑1 | 0 | Additive emissive contribution. |
| `_BorderWidth` | Float | 0.001‑0.2 | 0.05 | Border band width. |
| `_BorderSoftness` | Float | 0‑0.2 | 0.02 | Outer-edge falloff softness. |
| `_BorderIntensity` | Float | 0‑2 | 1.0 | Multiplies composited mask. |
| `_BorderGradientEnabled` | Float | — | 0 | Guard. |
| `_BorderGradientType` | Int (`Enum(GradientType)`) | 0‑4 | 0 (Linear) | See §7.5. |
| `_BorderGradientColorA/B/C/D` | Color | — | white → dark gray ramp | Gradient stops. |
| `_BorderGradientDirection` | Vector2 | — | (1,0,0,0) | Linear/Triangle direction. |
| `_BorderGradientSpeed` | Float | — | 1.0 | Animation speed. |
| `_BorderGradientScale` | Float | 0.1‑5 | 1.0 | Spatial frequency. |
| `_BorderGradientOffset` | Float | -2‑2 | 0.0 | Phase offset. |
| `_BorderGlobalBlend` | Float | 0‑1 | 0.0 | Blend toward scene-wide global gradient. |
| `_BorderGlobalIntensity` | Float | 0‑2 | 1.0 | Multiplies global blend factor. |
| `_BorderGradientColorUsed` | Int (IntRange) | 2‑4 | 4 | Active stop count. |

### 7.2 Lighting

| Property | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_LightingAmbient` | Float | 0‑1 | 0.3 | Ambient floor applied before the 3 directional lights, in `ApplyUILighting` — affects Bg's and Handle's lit color only (Edge/Border/Shadows/LED/HandleFace/Track are unlit flat composites, same pattern as Panel). |

As with Panel, the 3 scene lights (`_GlobalLightPos/Color/Fx1‑3`) are global/shared, not per-material
skin properties.

### 7.3 RM-only properties (`SDFTogglePillRM.shader` Properties block only)

| Property | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_ViewTilt` | Float | 0‑10 | 0 | **Declared, included in the Properties block, but never read by `SDFToggleRenderCore.cginc`.** No visual effect on the Pill toggle in its current form — see Gotchas. |
| `_ViewAngle` | Float | -180‑180 | 0 | Same — declared, unused. |
| `_ViewFOV` | Float | 0‑1 | 0 | Same — declared, unused. |
| `_ViewShift` | Float | -5‑5 | 0 | Same — declared, unused. |

### 7.4 Standard Unity UI / hidden properties (both shaders)

`[HideInInspector] _StencilComp/_Stencil/_StencilOp/_StencilWriteMask/_StencilReadMask/_ColorMask` and
`_AspectRatio` — same role as documented in `Params-Panel.md` §1; not meant for skin authoring.
`_MainTex`/`_Color` — standard UGUI sprite texture + tint, same as Panel.

---

## 3. Enum reference

Identical definitions to `Params-Panel.md` §3 (same `.cginc` source files, shared across every SDF UI
shader in this codebase) — repeated here for a self-contained document.

### 7.a `BevelProfileType` — every `*BevelProfileType` property above

- `0 = Dome` — smooth sine/smoothstep roll-off (default everywhere in this shader).
- `1 = Linear` — constant-slope angled shelf; the paired `*BevelProfileSharpness` sets the slope.

### 7.b `PatternType` — every `*PatternType` property above (0‑19)

| Value | Name | Notes |
|---|---|---|
| 0 | Plastic | Multi-octave noise, optional domain warp + metallic flake sparkle. |
| 1 | Metal | Anisotropic brushed noise; `param1`=grain direction, `param2`=anisotropy stretch, `param3`=streak variation. **Default for `_HandlePatternType`.** |
| 2 | RadialBrushed | Angular stripes from center; groove count/noise/ring-emphasis params. |
| 3 | CarbonFiber | Woven checkerboard fiber weave. |
| 4 | Leather | Voronoi-cell grain with pores and crack edges. |
| 5 | BrushedCross | Two opposing-angle brush strokes. |
| 6 | Satin | Smooth directional sheen band + shimmer. |
| 7 | Concrete | Rough multi-octave noise + Voronoi aggregate + cracks. |
| 8 | Fabric | Woven warp/weft thread pattern. |
| 9 | Paper | Granular fiber noise, blotch stains, surface tooth. |
| 10 | Frosted | Voronoi crystal + soft diffusion blend. |
| 11 | DiamondPlate | Staggered raised-diamond industrial grid. |
| 12 | Knurled | Diagonal-grid diamond grip pattern. |
| 13 | HexGrid | Honeycomb cells with border/indent controls. |
| 14 | Perforated | Regular round hole grid. |
| 15 | WoodGrain | Elliptical rings + grain lines + knots. |
| 16 | Marble | Turbulent sine veining. |
| 17 | Ceramic | Smooth glaze + optional crackle. |
| 18 | Circuit | Manhattan PCB traces + pads. |
| 19 | NoiseOrganic | Generic FBM turbulence. |

Full per-`param1/2/3` semantics for each type are documented once in `Params-Panel.md` §3.3 (same
sampling functions in `UIPatterns.cginc`, not re-derived here to avoid drift between the two docs).

### 7.c `PatternColorType` / `PatternColorMode` — every `*PatternColorType`/`*PatternColorMode` property above

`PatternColorType` (maps the pattern's scalar to a [0,1] palette position):
- `0 = Gradient` — signed [-1,+1] → linear palette position.
- `1 = Feature` — `abs(patternValue)`: flat→A, strong peaks→D.
- `2 = Zones` — irregular wrap (`frac(abs(v)*e)`), gives distinct per-feature coloring.
- `3 = Bands` — `abs(sin(v*PI))` sine banding.

`PatternColorMode` (how the palette color combines with the surface color):
- `0 = Modulate` — `patternColor * (1+pattern)` (ignores base color).
- `1 = Lerp` — `lerp(baseColor, patternColor, saturate(abs(pattern)))`.
- `2 = Additive` — `baseColor + patternColor * saturate(pattern)`.
- `3 = Multiply` — `baseColor * lerp(1, patternColor, saturate(abs(pattern)))`.

### 7.d `GradientType` — every `*GradientType` property above

- `0 = Linear`, `1 = Radial`, `2 = Angular`, `3 = Diamond`, `4 = Triangle` — all fully functional in
  this 2D shader.
- `5 = BevelDepth`, `6 = BevelWalls` — RM/raymarched-hit-point-only (meaningful on `SDFKnobRM`'s knob
  bevel). Selecting either here falls through `GetGradientPosition`'s `default:` and returns a flat
  `0.5` gradient position — i.e. always the exact midpoint palette color, no visible sweep. This
  applies on **both** `SDFTogglePill.shader` and `SDFTogglePillRM.shader`, since neither actually
  raymarches (see Gotchas).

---

## 4. `_XxxEnabled` guard list

| Guard | Turns off at 0 |
|---|---|
| `_BgEnabled` | The entire Bg housing layer (shape/bevel/pattern/gradient/rim/lighting). |
| `_BgBevelEnabled` | Bg's bevel shading; also force-disables Bg bevel pattern/gradient regardless of their own flags. |
| `_BgBevelPatternEnabled` | Bg bevel's procedural texture overlay. |
| `_BgBevelPatternColorEnabled` | Palette recoloring of the Bg bevel pattern. |
| `_BgBevelGradientEnabled` | Bg bevel's own gradient sweep. |
| `_BgRimEnabled` | Bg's outer rim bevel ring. |
| `_BgPatternEnabled` | Bg's whole-face procedural pattern. |
| `_BgPatternColorEnabled` | Palette recoloring of Bg's surface pattern. |
| `_BgGradientEnabled` | Bg's whole-face gradient sweep. |
| `_TrackEnabled` | The entire Track (pill groove) layer. |
| `_TrackBevelEnabled` | Track's bevel shading. |
| `_TrackPatternEnabled` | Track's procedural pattern. |
| `_TrackPatternColorEnabled` | Palette recoloring of Track's pattern. |
| `_TrackGradientEnabled` | Track's gradient sweep. |
| `_HandleEnabled` | The entire Handle (ball) layer **and everything gated on it**: Handle's own shadows' hull-sweep height, LED bloom's SDF source, Handle Face, and `TOGGLE_TYPE_EXTRAS` (unused for Pill anyway). |
| `_HandleBevelEnabled` | Handle's bevel; force-disables Handle bevel pattern/gradient. |
| `_HandleBevelPatternEnabled` | Handle bevel's procedural texture overlay. |
| `_HandleBevelPatternColorEnabled` | Palette recoloring of Handle bevel pattern. |
| `_HandleBevelGradientEnabled` | Handle bevel's own gradient sweep. |
| `_HandleRimEnabled` | Handle's outer rim bevel. **Also affects whether Handle Face renders at all** (via `faceInset`). |
| `_HandlePatternEnabled` | Handle's whole-ball procedural pattern. |
| `_HandlePatternColorEnabled` | Palette recoloring of Handle's pattern. |
| `_HandleGradientEnabled` | Handle's whole-ball gradient sweep. |
| `_HandleFaceEnabled` | Handle Face highlight disc — but only actually visible if `faceInset>0` (bevel or rim active) regardless of this flag. |
| `_HandleFaceGradientEnabled` | Handle Face's gradient sweep (falls back to flat `_HandleFaceColor`). |
| `_LedEnabled` | Both the LED bloom halo and (combined with `_LedSurfaceBlend`) the on-surface LED tint blend on Handle/HandleFace. |
| `_EdgeEnabled` | The recessed-indent band around the Bg quad. |
| `_EdgeGradientEnabled` | Edge band falls back to flat `_EdgeColor`. |
| `_BorderEnabled` | The cut-in border at the canvas edge. |
| `_BorderGradientEnabled` | Border falls back to flat `_BorderColor`. |
| `_LightingShadowNEnabled` (×3) | That external (Bg) shadow slot. |
| `_ToggleShadowNEnabled` (×3) | That Handle body shadow slot. |

---

## 5. How on/off state is expressed, and what drives the track/knob/label

**State**: purely `_Value` (Float 0‑1), continuous — there is no boolean `_On` uniform. `_StateCount`
(2‑8) quantizes `_Value` into evenly-spaced snap positions for multi-way switches; at the default 2 it
behaves as a standard binary toggle. Whatever drives `_Value` at runtime (DOTween transition per
`MaterialStateEngine`, or a live-driven `SetMaterialFloat("_Value", v)` per CLAUDE.md's live-param
contract) is what animates the slide.

**Handle travel** (`getPillBodySDF` in `SDFPillShapes.cginc`): the ball's X position is a straight
`lerp(-travelHW, travelHW, t)` where `t` is `_Value` (post-`_StateCount` quantization) and `travelHW =
halfW - ballR - padding`. There is no easing/overshoot baked into the shape function itself — any
spring/bounce feel comes entirely from whatever animates `_Value` over time (DOTween easing curve),
not from the shader.

**Track**: a single static rounded-rect groove (§5) — it does not change color, size, or shape based
on `_Value`/on-off state by itself. Any "track lights up when on" effect has to be authored externally
(e.g. driving `_TrackColor` via a live param, or relying on the LED glow/Handle-face tint which *do*
track `_Value`).

**Knob** (the "Handle" in this shader's naming, §6.4): full lit 3D-bevel material, always circular
(optionally flattened to an oval via `_HandleFlatten`) — it is not itself a shape enum, there's no
"knob shape type" selector for Pill (unlike Panel/Button/Knob's shape-type enums). Ball radius is
derived jointly from `_TrackHeight` and `_HandlePadding` (§6.1), not an independent absolute size.

**Label / glyph**: **there is no text, icon, or glyph rendering anywhere in this shader.** No font
atlas, no icon SDF dispatcher (unlike `SDFButtonLayers.cginc`, which defines `getIconSDF` for buttons —
that function is not called anywhere in the toggle pipeline). Any "ON"/"OFF" text or check/cross glyph
on a toggle has to be a separate UI element (e.g. a UGUI `Text`/`TMP` object or a second SDF widget)
layered on top by the scene/prefab — it is not a property of `SDFTogglePill`/`SDFTogglePillRM`.

---

## 6. Interaction / dependency notes

- `_TogglePadding` is hard-`#define`d to `0.0` for Pill — Bg padding (`_BgPadding`) is the only control
  over how much smaller the Track/Handle region is than the outer housing.
- Track sizing (`trackHH`) and Handle ball radius (`ballR`) are **both** derived from `_TrackHeight`;
  they cannot be tuned fully independently — raising `_TrackHeight` grows both the groove and the ball.
- `_HandleFaceEnabled` visually depends on `_HandleBevelEnabled`/`_HandleRimEnabled` having a nonzero
  distance/width (`faceInset > 0.001`), not just on its own flag.
- LED bloom intensity (`_LedIntensity`) is state-independent; only `_LedSurfaceBlend` (surface tint on
  Handle/HandleFace) actually scales with `_Value`. A skin wanting the glow itself to switch on/off
  with toggle state needs to drive `_LedEnabled`/`_LedIntensity` externally (e.g. per-state in
  `.states.json`, since `.states.json` state deltas can differ between an "On" and "Off" state stack).
- `_TrackPatternRotateEnabled`/`ModEnabled`/`ModAmount`/`ModFrequency`/`Offset` do not exist as
  properties for Track at all (Track's `CreateUIComponent` hard-codes all of these to 0/1 constants) —
  don't look for them; they're absent by design, not merely inert.
- `_BgPatternRotateEnabled`/`ModEnabled`/`ModAmount`/`ModFrequency` and the equivalent `_Handle*`
  properties exist but are inert for this control, since Bg/Handle both call `ApplyMaterialPattern`
  with `currentValue` hard-coded to `0.0` — `*PatternOffset` (static rotation, not value-gated) is the
  only rotation control that actually does anything.
- `_TrackInsetDepth` is dead (declared, exposed, mapped to an unused `_ToggleParam5` slot) — do not
  expect any visual change from adjusting it; use `_TrackBevelDepth`/`_TrackBevelDistance` instead.
- `_AnimT` and `_ToggleType` are declared in the shared uniforms file but have no Properties-block
  entry and are not read by the Pill render path — fully dead for this control.
- Gradient types 5/6 (`BevelDepth`/`BevelWalls`) silently degrade to a flat midpoint color on every
  gradient property in both Pill shaders (flat and "RM").

---

## 7. Gotchas

- **`SDFTogglePillRM.shader`'s raymarch pass does not raymarch.** It declares `_ViewTilt`/
  `_ViewAngle`/`_ViewFOV`/`_ViewShift` and includes `SDF3DExtrusion.cginc`, but its fragment body is
  the exact same `#include "CG/SDF/SDFToggleLayers.cginc"` + `#include
  "CG/SDF/SDFToggleRenderCore.cginc"` pair as the flat shader, and `SDFToggleRenderCore.cginc` never
  references any of those 4 uniforms or the extrusion header. Authoring `_ViewTilt` etc. on an
  `SDFTogglePillRM` material will have **no visible effect** — this differs from `SDFButtonRM.shader`/
  `SDFKnobRM.shader`/`SDFSliderRM.shader`, which do implement a real section-9 sphere-marched
  extrusion per CLAUDE.md's architecture description. Treat the two Pill shaders as visually
  interchangeable until/unless this is wired up.
- **`_TrackInsetDepth` is a decoy** — it's in the Properties block with a plausible name and default,
  but has zero effect. Use `_TrackBevelDepth`/`_TrackBevelDistance` to shape the groove's inset look.
- **`_HandleFaceEnabled=1` alone does not guarantee the highlight shows.** It also needs
  `_HandleBevelEnabled` or `_HandleRimEnabled` on with nonzero distance/width.
- **Handle Face is unlit.** Don't expect it to respond to `_LightingAmbient` or the 3 scene lights —
  it's a flat/gradient disc composited directly, meant as a fake specular highlight, not a real
  lit surface.
- **No text/icon rendering at all in this shader family.** "ON"/"OFF" labels or check/X glyphs must be
  separate UI elements composited by the scene, not a shader property.
- **Track pattern has fewer exposed properties than Bg/Handle's pattern block** (no rotate/mod/offset
  properties) — don't assume parity across the three pattern blocks in this shader.
- **Pattern/bevel-pattern scale is UV-space, not pixel-space — same mechanism and same "too fine at
  small sizes" risk as documented in `Params-Panel.md` §5.** Applies to every `*PatternScale`/
  `*BevelPatternScale` property in this document (`_BgPatternScale`, `_TrackPatternScale`,
  `_HandlePatternScale`, and their Bevel counterparts).
- **`_HandleFlatten`'s oval squash is an approximate SDF rescale**, not an exact ellipse distance
  field — expect minor bevel/AA distortion at high flatten values, especially combined with a large
  bevel distance.
- **`_ToggleShadow*`/`_LightingShadow*` are NOT bridged through the `_Handle*` naming convention** —
  unlike body/bevel/pattern/gradient/rim properties, shadow properties keep their generic `_Toggle*`/
  `_Lighting*` names directly in the Properties block; there is no `_HandleShadow*` property to look
  for.
