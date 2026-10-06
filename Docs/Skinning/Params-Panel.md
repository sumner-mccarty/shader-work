# SDFPanel — Parameter Reference

Source read in full: `Assets/Shaders/SDFPanel.shader`, `Assets/Shaders/CG/SDF/SDFPanelUniforms.cginc`,
`Assets/Shaders/CG/SDF/SDFPanelLayers.cginc`, `Assets/Shaders/CG/SDF/SDFPanelShapes.cginc`.
Enum values cross-checked against `Assets/Shaders/ShaderConstants.cs` and the switch/if chains in
`Assets/Shaders/CG/Core/UIPatterns.cginc`, `UIGradients.cginc`, `UILighting.cginc`,
`Assets/Shaders/CG/SDF/SDFButtonLayers.cginc`. `SDFPanelRM.shader` was **not** in the read set and is
not covered here (per CLAUDE.md, the RM variant only replaces section 9 with a raymarched extrusion —
the 2D properties below should carry over unchanged, but that has not been verified against this task).

Panel is drawn by `Assets/Shaders/SDFPanel.shader`'s single `frag()` (lines ~482‑980), in this literal
order — this doc groups every property under the section that consumes it:

1. Edge indent
2. External shadows (×3)
3. Panel body shadows (×3)
4. **Panel** body + face + bevel + rim + pattern + gradient (the main faceplate material)
5. **InnerFrame** — a second, fully independent material pipeline nested on top of the Panel face
6. Border
6.5. Corner screws
(Lighting/ambient and ReceiveSceneShadows are cross-cutting, listed after Border)

Panel and InnerFrame are structurally identical (same sub-block set: Shape → Bevel → Bevel Pattern →
Bevel Pattern Color → Bevel Gradient → Rim → Pattern → Pattern Color → Gradient → own nested Face/size).
The enum meanings are documented once in §3 and referenced from both tables.

---

## 1. Global / non-sectioned properties

| Property | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_MainTex` | 2D (PerRendererData) | — | white | Unity UI sprite texture; unused by the SDF material itself but required by the UI batching pipeline. |
| `_Color` | Color | — | (1,1,1,1) | Standard UGUI `Image.color` tint. Multiplies the final composited output (`finalColor *= IN.color`) and the emissive accumulator. |
| `_Value` | Float (Range 0‑1) | 0–1 | 0 | Declared but **not read anywhere in SDFPanel's frag()** — Panel has no value-driven visual (no fill, no rotation). Present only because it's part of the shared uniform block layout; harmless to leave at default. |
| `_Position` | Vector4 | — | (0,0,0,0) | World-ish XY position of the widget, pushed at runtime. Feeds `UI_LIGHT_1/2/3` macros (`UILightDirection(gPos, _Position.xy)`) so the 3 scene lights compute a per-widget light direction. Not meaningful to hand-author in `.states.json`. |
| `_AspectRatio` | Float | 0+ | 0 | 0 = auto-detect aspect from `ddx/ddy` of the UV (works for any RectTransform size). Nonzero overrides the detected aspect — rarely needed. |
| `_PanelScrewsEnabled` | Float (bool-guard) | — | 0 | Enables the 4 corner screws overlay (drawn last, on top of everything but before clip/shadow-receive). See §5. |
| `_PanelScrewShapeType` | Int (`ScrewShapeType`) | 0–7 | 0 | Drive type: 0 Slotted · 1 Phillips · 2 HexSocket · 3 Torx · 4 Dome (plain rivet) · 5 HexHead (hex bolt outline) · 6 Pozidriv · 7 Robertson. |
| `_PanelScrewInset` | Range | 0–1.5 | 0.12 | Screw centre inset **in the same units as `_PanelPadding`**, measured in from the *panel body's* corner by tracing the body SDF — so it follows a rounded, chamfered or hexagonal corner and keeps a true constant clearance at any panel size. |
| `_PanelScrewRadius` | Range | 0.002–0.5 | 0.055 | Screw head radius, padding units. Scales with the plate. |
| `_PanelScrewColor` | Color | — | (0.62,0.63,0.655,1) | The metal. Lit by the scene's key lamp (dome diffuse + Blinn glint), so it relights with every other widget. |
| `_PanelScrewSlotColor` | Color | — | (0.07,0.07,0.08,1) | The drive recess. |
| `_PanelScrewRotation` | Range | -180–180 | 32 | Angle of the drive recess (the slot/cross). |
| `_PanelScrewDepth` | Range | 0–1 | 0.85 | How deep the recess reads — 0 removes it entirely, leaving a bare head. |
| `_PanelScrewMetallic` | Range | 0–1 | 0.8 | Strength of the glint and the rim crescent. 0 = matte plastic rivet. |
| `_ReceiveSceneShadows` | Float (bool-guard) | — | 1 | When 1, the panel multiplies its final color by the shared `_UIShadowBuffer` (shadows cast by knobs/buttons/sliders sitting on top of it). Set to 0 for panels mounted in an overlay/modal layer so they don't visibly darken from shadows cast by widgets on layers behind them (see code comment — the buffer has no per-layer stacking concept). |
| `_WidgetPixelSize` | Vector2 | — | (0,0) | Runtime-pushed real pixel size of the RectTransform (by `MaterialStateController`/`SyncPixelSize`). Only consumed by `_PanelCornerRadiusPx` (below). **Not meaningfully settable from a static `.states.json` preview** — it's 0 unless something pushes it live. |
| `_StencilComp`, `_Stencil`, `_StencilOp`, `_StencilWriteMask`, `_StencilReadMask`, `_ColorMask` | Float | — | 8, 0, 0, 255, 255, 15 | Standard Unity UI masking/stencil plumbing. Not skin-authored in practice. |

---

## 2. Section 1 — Edge indent

A soft dark (or gradient) band that straddles the panel's outer boundary, computed and composited
**before** the panel body — visible only where the opaque panel body doesn't cover it (i.e. mainly in
the `_PanelPadding` gap between the panel edge and the widget's full quad, and through any panel alpha
< 1). This is what fakes a "panel recessed into a socket" look independent of the bevel.

| Property | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_EdgeEnabled` | Float | — | 0 | Master guard for this whole section. |
| `_EdgeColor` | Color | — | (0,0,0,0.5) | Base edge-band color (used when gradient is off, or as the pre-gradient fallback). |
| `_EdgeRenderAlpha` | Float | 0‑1 | 1 | Multiplies the alpha of the composited edge color. |
| `_EdgeRenderEmissive` | Float | 0‑1 | 0 | Adds `edgeColor * mask * this` into the additive emissive accumulator (bypasses normal alpha blending / lighting). |
| `_EdgeWidth` | Float | 0.001‑1.0 | 0.1 | Width (in equi-pixel units) of the fade band, measured outward from the inset boundary. |
| `_EdgeSoftness` | Float | 0‑1 | 0.3 | 0 = hard `smoothstep` edge at `_EdgeWidth`. >0 switches to a `pow()` falloff curve (`edgePower = lerp(0.8,4.0, (softness/2)^1.5)`) for a softer/rounder gradient shape. |
| `_EdgeIntensity` | Float | 0‑2 | 0.5 | Multiplies the computed mask before compositing — a straight brightness/opacity dial on top of the shape falloff. |
| `_EdgeInset` | Float | 0.0‑0.5 | 0.0 | Shifts the reference boundary inward by this many equi-pixel units before measuring distance. Distance is `max(0, bodyDist + EdgeInset)` — so **within** the inset boundary the band is clamped to full intensity (1.0), and it only fades going outward from there. |
| `_EdgeGradientEnabled` | Float | — | 0 | Enables a `CalculateGradient` sweep over the edge color instead of flat `_EdgeColor`. |
| `_EdgeGradientType` | Int (`Enum(GradientType)`) | 0‑6 | 0 (Linear) | See §3.5. |
| `_EdgeGradientColorA/B/C/D` | Color | — | black‑ish ramp | Gradient stops. |
| `_EdgeGradientDirection` | Vector2 | — | (0,1,0,0) | Direction for Linear/Triangle gradient types. |
| `_EdgeGradientSpeed` | Float | — | 1.0 | Animation speed (multiplies `_Time.y`). |
| `_EdgeGradientScale` | Float | 0.1‑5 | 1.0 | Spatial frequency of the gradient sweep. |
| `_EdgeGradientOffset` | Float | -2‑2 | 0.0 | Phase offset added to the gradient position. |
| `_EdgeGradientColorUsed` | Int (IntRange) | 2‑4 | 2 | How many of the 4 color stops are active (2, 3, or 4). |
| `_EdgeGlobalBlend` | Float | 0‑1 | 0.0 | Blends toward the scene-wide "global gradient" effect (`CalculateGlobalGradient`, screen-space, shared across all widgets) — a cross-widget ambient tint sweep, not the per-widget gradient above. |
| `_EdgeGlobalIntensity` | Float | 0‑2 | 1.0 | Multiplies `_EdgeGlobalBlend`'s blend factor. |

---

## 3. Section 2/3 — Shadows

Two independent triads, each identical in shape (3 slots numbered 1‑3, same property set per slot):

- **External shadows** (`_LightingShadowN*`) — a flat 2D silhouette shadow cast on the background
  behind the panel's outer boundary, one per scene light (`UI_LIGHT_1/2/3`).
- **Panel body shadows** (`_PanelShadowN*`) — a hull-swept "3D depth" cast shadow that also accounts
  for the bevel's pseudo-height (`pseudoHeight`), so a deeply beveled panel throws a longer/wider
  shadow than a flat one. When `_PanelFaceEnabled` is 0 (ring/outline mode), the shadow is punched
  into a ring shape to match the hollow face.

| Property (×3, N=1,2,3) | Type | Range | Default (Shadow1 shown) | What it does |
|---|---|---|---|---|
| `_LightingShadowNEnabled` | Float | — | 0 | Guard for external shadow N. |
| `_LightingShadowNColor` | Color | — | (0,0,0,0.5 / 0.3 / 0.2) | Shadow tint + max alpha. |
| `_LightingShadowNBlur` | Float | 0‑2 | 0.5 / 0.8 / 1.0 | Base blur radius multiplier (`baseBlur = blur*0.05`). |
| `_LightingShadowNDistance` | Float | 0‑0.5 | 0.02 / 0.05 / 0.08 | Offset distance along the light direction, in equi-pixel units ×2. |
| `_LightingShadowNBlurFactor` | Float | 0‑2 | 0.5 | Balances near-edge vs far-edge blur (contact-hardening approximation) — see `buttonShadowEdgeAlpha` in `SDFButtonLayers.cginc`. |
| `_LightingShadowNIntensity` | Float | 0‑2 | 1.0 | Multiplies the shadow's composited alpha. |
| `_PanelShadowNEnabled` | Float | — | 0 | Guard for panel body shadow N. |
| `_PanelShadowNColor` | Color | — | (0,0,0,0.6/0.4/0.3) | Shadow tint + max alpha. |
| `_PanelShadowNBlur` | Float | 0‑2 | 0.3/0.5/0.7 | Same blur model as external shadows. |
| `_PanelShadowNDistance` | Float | 0‑0.5 | 0.01/0.02/0.03 | Offset distance along light direction. |
| `_PanelShadowNBlurFactor` | Float | 0‑2 | 0.3 | Near/far blur balance. |
| `_PanelShadowNIntensity` | Float | 0‑2 | 1.0 | Multiplies composited alpha. |
| `_PanelShadowNCast` | Float | 0‑1 | 0.5 | Scales `pseudoHeight` for the hull sweep — 0 collapses the shadow to the flat silhouette (same as an external shadow); higher values extrude it further, simulating a taller 3D bevel. |

---

## 4. Section 4 — Panel (the faceplate itself)

This is the main material pipeline: body shape → bevel → bevel pattern → bevel pattern color →
bevel gradient → rim → surface pattern → pattern color → surface gradient, then lit by the 3 scene
lights. `_PanelFaceEnabled`/`_PanelFaceShapeEnabled`/`_PanelFaceSize` control a second nested
"face" SDF used only to define the *inner* boundary the bevel slopes down to (not a separately
colored layer — that's what InnerFrame is for).

### 4.1 Panel core

| Property | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_PanelEnabled` | Float | — | 1 | Master guard for the entire Panel body (shape+bevel+rim+pattern+gradient+lighting). At 0, none of section 4 or 5's rendering happens (InnerFrame is nested inside Panel's `if` block via `_PanelEnabled`? — **No**: InnerFrame is its own top-level `if (_InnerFrameEnabled > 0.5)` block, independent of `_PanelEnabled`. See gotchas.) |
| `_PanelColor` | Color | — | (0.25,0.25,0.25,1) | Base face color before gradient/pattern. |
| `_PanelRenderAlpha` | Float | 0‑1 | 1 | Alpha multiplier for the normal (non-emissive) composite. |
| `_PanelRenderEmissive` | Float | 0‑1 | 0 | Adds `baseColor * bodyMask * this` to the additive emissive accumulator. |

### 4.2 Panel shape

| Property | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_PanelShapeType` | Int (`Enum(PanelBodyShapeType)`) | 0,1,2,3,4,100 | 0 (Squircle) | Selects the SDF dispatched in `getPanelBodySDF`. See §3.1 for full integer table. |
| `_PanelShapeParam1` | Float | 0‑1 | 0.2 | Shape-specific (squareness / n-gon selector / top-radius / hex-rounding / octagon-cut — see §3.1). |
| `_PanelShapeParam2` | Float | 0‑1 | 0.5 | Shape-specific (only used by Polygircle, as corner rounding). |
| `_PanelShapeParam3` | Float | 0‑1 | 0.5 | **Declared, passed through everywhere, but not read by any case in `getPanelBodySDF`'s switch.** Currently inert for every shape type. |
| `_PanelShapeRotation` | Float | -180‑180 | 0 | Rotates the body-space position (`bodyPos = rotate2D(pos, rotation)`) before evaluating the shape SDF — also rotates all body/rim/external-shadow/body-shadow computations that share `bodyPos`/`bodyRotRad`. |
| `_PanelPadding` | Float | 0.0‑1.5 | 0.15 | Equi-pixel-unit margin subtracted from the widget's aspect-scaled half-extent to get the panel's actual half-size (`bodyHalfW = aspectScale.x - Padding`). This is proportional to the widget's shorter side (not locked to real pixels) — see §5 for the pixel-vs-proportional distinction. |
| `_PanelBodyRoundness` | Float | 0‑1 | 0 | Applied **after** the shape switch, to every shape type uniformly: `d -= _PanelBodyRoundness * minDim * 0.15` — a global corner/edge softening independent of the per-shape rounding params, up to 15% of the shape's shorter half-extent. |
| `_PanelCornerRadiusPx` | Float | — | 0 | Squircle-only (case 0). When > 0.5 **and** `_WidgetPixelSize` is populated (min dimension > 1px, i.e. pushed at runtime), overrides the proportional `param1` squareness with a fixed absolute-pixel corner radius: `r = clamp(CornerRadiusPx * 2 / minPixelDim, 0, minDim)`. This is the one shape property that stays a constant real-pixel size regardless of panel size — everything else in this shader scales with the widget. |
| `_PanelBodyShapeTexLayer` | Float | — | -1 | Squircle/Texture-type (case 100) only: which layer of the shared `Texture2DArray` (`SDFTextures.cginc`, not read for this task) to sample as a custom SDF. -1/unset falls back to whatever the array default is. |
| `_PanelBodyShapeTexScale` | Vector2 | — | (1,1,0,0) | Texture-type only: UV tiling scale for the sampled SDF texture. |

### 4.3 Panel bevel

| Property | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_PanelBevelEnabled` | Float | — | 0 | Guard. At 0: no bevel shading (flat lit face), and bevel pattern/gradient (§4.4/4.6) are force-disabled regardless of their own enable flags (`hasBevelEffects` requires `bevelActive`). |
| `_PanelBevelDepth` | Float | -1.0‑1.0 | 0.2 | Bevel height/slope. **Sign matters**: positive = raised/embossed edge (normal tilts outward, catches highlight), negative = recessed/engraved edge (normal inverted — see `CalculateShapeBevelNormal`'s `if (bevelDepth < 0.0) edgeDir = -edgeDir`). Magnitude is remapped through a `tan()` curve before use, so response is nonlinear near ±1. |
| `_PanelBevelSmoothness` | Float | 0.001‑1.0 | 0.02 | Controls the sharpness of the bevel's inner falloff (Dome profile only — see `profileType`). Small = crisp edge, large = soft gradual roll-off. |
| `_PanelBevelDistance` | Float | 0.001‑1.0 | 0.1 | How far inward (equi-units) the bevel band extends from the shape edge. Also feeds `pseudoHeight` for shadow-cast hull sweeps and defines `faceInset` (together with rim width). |
| `_PanelFaceSmoothness` | Float | -1.0‑1.0 | 0.0 | Dome/bowl profile applied to the *flat interior* of the face (not the bevel band itself): positive bulges the face normal outward (subtle dome), negative dishes it inward (subtle bowl). 0 = perfectly flat interior. |
| `_PanelBevelProfileType` | Int | 0,1 | 0 | 0 = Dome (smooth sine/smoothstep roll-off). 1 = Linear (constant-slope angled shelf, uses `_PanelBevelProfileSharpness` as the slope scale). See §3.2. |
| `_PanelBevelProfileSharpness` | Float | 0‑1 | 0.5 | Linear profile only: 0 = no slope (flat), 1 = full bevel depth reached immediately at the edge. Unused when profile type is Dome. |

### 4.4 Panel bevel pattern

Overlays a procedural material texture (wood grain, brushed metal, knurling, etc.) **only within the
bevel band**, blended in proportional to the bevel falloff factor computed above.

| Property | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_PanelBevelPatternEnabled` | Float | — | 0 | Guard (also requires `_PanelBevelEnabled`). |
| `_PanelBevelPatternType` | Int (`Enum(PatternType)`) | 0‑19 | 0 (Plastic) | See §3.3 for all 20. |
| `_PanelBevelPatternScale` | Float | 1‑100 | 20 | **Pattern frequency — see §5, the critical size/scale section.** |
| `_PanelBevelPatternIntensity` | Float | 0‑1 | 0.3 | How strongly the pattern perturbs the base color (brightness modulation magnitude). |
| `_PanelBevelPatternContrast` | Float | 0.1‑5 | 1.5 | Gamma-like curve on the raw pattern value (`sign(v)*pow(abs(v), 1/contrast)`). |
| `_PanelBevelPatternSpecularEffect` | Float | 0‑2 | 1.0 | How much the pattern modulates the specular highlight strength. |
| `_PanelBevelPatternRoughnessEffect` | Float | 0‑2 | 0.3 | How much the pattern perturbs the bevel's lighting normal (`ddx/ddy` of pattern value → normal offset) — simulates surface micro-roughness. |
| `_PanelBevelPatternParam1` | Float | 0‑1 | 0.5 | Pattern-specific "Detail" knob (meaning varies per pattern type — e.g. octave count for Plastic, grain direction for Metal). |
| `_PanelBevelPatternParam2` | Float | 0‑1 | 0.5 | Pattern-specific "Distortion" knob. |
| `_PanelBevelPatternParam3` | Float | 0‑1 | 0.5 | Pattern-specific "Blend" knob. |

### 4.5 Panel bevel pattern color

Recolors the bevel pattern using a 2‑4 stop palette instead of pure brightness modulation.

| Property | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_PanelBevelPatternColorEnabled` | Float | — | 0 | Guard. At 0, the pattern only modulates brightness of the existing bevel color (`baseColor * (1+pattern)`) — no palette lookup. |
| `_PanelBevelPatternColorType` | Int (`Enum(PatternColorType)`) | 0‑3 | 2 (Zones) | How the pattern's scalar value maps to a [0,1] palette position. See §3.4. |
| `_PanelBevelPatternColorMode` | Int (`Enum(PatternColorMode)`) | 0‑3 | 1 (Lerp) | How the palette color combines with the base bevel color. See §3.4. |
| `_PanelBevelPatternColorUsed` | Int (IntRange) | 2‑4 | 2 | How many of A/B/C/D are active stops. |
| `_PanelBevelPatternColorA/B/C/D` | Color | — | white → dark gray ramp | Palette stops, interpolated with a ping-pong triangle wave (`InterpolatePatternColors`) so the palette never hard-seams. |

### 4.6 Panel bevel gradient

An independent gradient sweep applied to the bevel color (before pattern-color blending), separate
from the bevel pattern.

| Property | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_PanelBevelGradientEnabled` | Float | — | 0 | Guard. |
| `_PanelBevelGradientType` | Int (`Enum(GradientType)`) | 0‑4 (5/6 are RM-only) | 1 (Radial) | See §3.5. |
| `_PanelBevelGradientColorA/B/C/D` | Color | — | white → dark gray | Gradient stops. |
| `_PanelBevelGradientDirection` | Vector2 | — | (1,0,0,0) | Linear/Triangle direction. |
| `_PanelBevelGradientSpeed` | Float | — | 1.0 | Animation speed. |
| `_PanelBevelGradientScale` | Float | 0.1‑5 | 1.0 | Spatial frequency. |
| `_PanelBevelGradientOffset` | Float | -2‑2 | 0.0 | Phase offset. |
| `_PanelBevelGradientColorUsed` | Int (IntRange) | 2‑4 | 4 | Active stop count. |

### 4.7 Panel rim bevel

A second, independent bevel ring right at the shape's outer silhouette (distinct from the main bevel,
which sits at the face/body boundary). Reads `panelDist` (the outer body SDF, or -1 to disable when a
custom face shape is active and the face itself is what's showing — see code at line 752‑754).

| Property | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_PanelRimEnabled` | Float | — | 0 | Guard. |
| `_PanelRimDepth` | Float | -0.5‑0.5 | 0.1 | Signed tilt strength of the rim's lighting normal — positive/negative reads as a raised lip vs a sunken groove around the very edge. |
| `_PanelRimWidth` | Float | 0.001‑1.0 | 0.02 | How far inward from the edge the rim band extends. Also contributes to `faceInset` (`rimWidth + bevelDist`) — i.e. it eats into the same interior-face budget the main bevel uses. |
| `_PanelRimSmoothness` | Float | 0.001‑0.1 | 0.01 | Falloff softness of the rim band. |

### 4.8 Panel surface pattern

Same 20-pattern library as the bevel pattern, applied to the **entire face** (not just the bevel
band) before the bevel/rim shading is layered on top.

| Property | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_PanelPatternEnabled` | Float | — | 0 | Guard. |
| `_PanelPatternType` | Int (`Enum(PatternType)`) | 0‑19 | 0 (Plastic) | See §3.3. |
| `_PanelPatternScale` | Float | 1‑100 | 20 | **See §5 — pattern frequency, UV-space not pixel-space.** |
| `_PanelPatternPx` | Float | ≥0 | 0 | Canvas units per pattern tile. >0 pixel-locks EVERY pattern in the shader (face, bevel, inner frame) so grain no longer scales with the widget; 0 = widget-relative (§5). |
| `_PanelPatternIntensity` | Float | 0‑1 | 0.3 | Brightness modulation strength. |
| `_PanelPatternContrast` | Float | 0.1‑5 | 1.5 | Gamma curve on pattern value. |
| `_PanelPatternSpecularEffect` | Float | 0‑2 | 1.0 | Specular modulation strength. |
| `_PanelPatternRoughnessEffect` | Float | 0‑2 | 0.3 | Normal-perturbation strength. |
| `_PanelPatternRotateEnabled` | Float | — | 0 | If set, rotates the pattern sample continuously based on `currentValue` (Panel always passes `currentValue=0`, so **this has no visible effect on Panel** — it's meaningful on value-driven widgets like Knob/Slider). |
| `_PanelPatternModEnabled` | Float | — | 0 | Same caveat: drives a sine "shimmer" rotation off `currentValue`; inert on Panel since Panel passes 0. |
| `_PanelPatternModAmount` | Float | 0‑90 | 20 | Shimmer amplitude in degrees (inert on Panel, see above). |
| `_PanelPatternModFrequency` | Float | 0.1‑10 | 1 | Shimmer frequency (inert on Panel). |
| `_PanelPatternOffset` | Float | -180‑180 | 0 | Static rotation offset applied to the pattern sample space — **this one does work** on Panel (it's not gated by `currentValue`). |
| `_PanelPatternParam1/2/3` | Float | 0‑1 | 0.5 each | Pattern-specific Detail/Distortion/Blend knobs (see pattern function bodies in `UIPatterns.cginc` for exact per-type meaning). |

### 4.9 Panel surface pattern color

| Property | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_PanelPatternColorEnabled` | Float | — | 0 | Guard. |
| `_PanelPatternColorType` | Int (`Enum(PatternColorType)`) | 0‑3 | 2 (Zones) | See §3.4. |
| `_PanelPatternColorMode` | Int (`Enum(PatternColorMode)`) | 0‑3 | 1 (Lerp) | See §3.4. |
| `_PanelPatternColorUsed` | Int (IntRange) | 2‑4 | 2 | Active stop count. |
| `_PanelPatternColorA/B/C/D` | Color | — | white → dark gray | Palette stops. |

### 4.10 Panel gradient

| Property | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_PanelGradientEnabled` | Float | — | 0 | Guard. |
| `_PanelGradientType` | Int (`Enum(GradientType)`) | 0‑4 | 0 (Linear) | See §3.5. |
| `_PanelGradientColorA/B/C/D` | Color | — | R/G/B/Y (demo defaults, meant to be overridden) | Gradient stops. |
| `_PanelGradientDirection` | Vector2 | — | (1,0,0,0) | Linear/Triangle direction. |
| `_PanelGradientSpeed` | Float | — | 1.0 | Animation speed. |
| `_PanelGradientScale` | Float | 0.1‑5 | 1.0 | Spatial frequency. |
| `_PanelGradientOffset` | Float | -2‑2 | 0.0 | Phase offset. |
| `_PanelGlobalBlend` | Float | 0‑1 | 0.0 | Blend toward the scene-wide global gradient effect. |
| `_PanelGlobalIntensity` | Float | 0‑2 | 1.0 | Multiplies the global blend factor. |
| `_PanelGradientColorUsed` | Int (IntRange) | 2‑4 | 4 | Active stop count. |

### 4.11 Panel face (defines the bevel's *inner* boundary — not a separate colored layer)

| Property | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_PanelFaceEnabled` | Float | — | 1 | At 0, switches Panel into **ring/outline mode**: the interior of the face is punched out (`bodyMask *= faceMask` using `topFaceDist`), so only a ring the width of `faceInset` (rim width + bevel distance) is drawn. Also flips `shadowFaceHole` on for the body-shadow hull sweep, so the cast shadow becomes a matching ring. |
| `_PanelFaceShapeEnabled` | Float | — | 0 | At 1, the bevel's inner boundary is computed from an *independent* SDF (its own shape type/params/rotation/size) rather than a uniform inward offset of the body shape — lets you e.g. bevel down from a rounded-rect body to a circular inset face. |
| `_PanelFaceShapeType` | Int (`Enum(PanelBodyShapeType)`) | 0,1,2,3,4,100 | 0 (Squircle) | Same enum as `_PanelShapeType`, §3.1. |
| `_PanelFaceShapeParam1/2/3` | Float | 0‑1 | 0.2/0.5/0.5 | Same per-shape meaning as the body shape params. |
| `_PanelFaceShapeRotation` | Float | -180‑180 | 0 | Rotates the face-shape sample position. |
| `_PanelFaceSize` | Float | 0.01‑1.0 | 0.85 | Fraction of the body's half-extent the face shape is sized to (margin = `(1-Size) * min(bodyHalfW,bodyHalfH)`). Only meaningful when `_PanelFaceShapeEnabled` is 1. |
| `_PanelFaceShapeTexLayer` | Float | — | -1 | Texture-type (100) face shape only. |
| `_PanelFaceShapeTexScale` | Vector2 | — | (1,1,0,0) | Texture-type face shape UV scale. |

---

## 5. Section 5 — InnerFrame

A **second, fully independent** SDF + material pipeline (own shape, own bevel, own bevel
pattern/pattern-color/gradient, own rim, own surface pattern/pattern-color/gradient), composited on
top of everything Panel drew. This is the shape the CLAUDE.md architecture note describes as replacing
Icon: a nested badge/inset shape sitting on the panel face, with the full bevel/rim/lighting treatment
Icon never had. It is gated only by its own `_InnerFrameEnabled` — **not** by `_PanelEnabled** — so it
is possible to show InnerFrame with Panel's body switched off.

Every property mirrors §4.2‑§4.10 exactly, with the `Panel` prefix replaced by `InnerFrame`:

| Sub-block | Properties |
|---|---|
| Core | `_InnerFrameEnabled`, `_InnerFrameColor` (default 0.15,0.15,0.15,1 — darker than Panel's 0.25 default, reads as a recessed badge), `_InnerFrameRenderAlpha`, `_InnerFrameRenderEmissive` |
| Shape | `_InnerFrameShapeEnabled` (note: unlike Panel, InnerFrame's shape is driven purely by `_InnerFrameSize` inset from the *unrotated* `bodyPos`/`pos` unless this flag is 1 — when 0 it borrows the Panel's own `_PanelShapeType`/Param1‑3 rather than defining its own), `_InnerFrameShapeType` (`Enum(PanelBodyShapeType)`), `_InnerFrameShapeParam1/2/3`, `_InnerFrameShapeRotation`, `_InnerFrameSize` (Range 0.01‑1.0, default 0.75 — fraction of `min(bodyHalfW,bodyHalfH)`, the **same** margin formula as `_PanelFaceSize` against the same body-half-extent base; see §7 gotchas for when that concentricity guarantee breaks), `_InnerFrameShapeTexLayer`, `_InnerFrameShapeTexScale` |
| Bevel | `_InnerFrameBevelEnabled`, `_InnerFrameBevelDepth`, `_InnerFrameBevelSmoothness`, `_InnerFrameBevelDistance`, `_InnerFrameFaceSmoothness`, `_InnerFrameBevelProfileType`, `_InnerFrameBevelProfileSharpness` |
| Bevel pattern | `_InnerFrameBevelPatternEnabled`, `_InnerFrameBevelPatternType` (`Enum(PatternType)`), `_InnerFrameBevelPatternScale`, `..Intensity`, `..Contrast`, `..SpecularEffect`, `..RoughnessEffect`, `..Param1/2/3` |
| Bevel pattern color | `_InnerFrameBevelPatternColorEnabled`, `..ColorType` (`Enum(PatternColorType)`), `..ColorMode` (`Enum(PatternColorMode)`), `..ColorUsed`, `..ColorA/B/C/D` |
| Bevel gradient | `_InnerFrameBevelGradientEnabled`, `..GradientType` (`Enum(GradientType)`), `..ColorA/B/C/D`, `..Direction`, `..Speed`, `..Scale`, `..Offset`, `..ColorUsed` |
| Rim | `_InnerFrameRimEnabled`, `_InnerFrameRimDepth`, `_InnerFrameRimWidth`, `_InnerFrameRimSmoothness` |
| Surface pattern | `_InnerFramePatternEnabled`, `_InnerFramePatternType`, `..Scale`, `..Intensity`, `..Contrast`, `..SpecularEffect`, `..RoughnessEffect`, `..RotateEnabled`, `..ModEnabled`, `..ModAmount`, `..ModFrequency`, `..Offset`, `..Param1/2/3` (same "inert unless value-driven" caveat as Panel — InnerFrame also always passes `currentValue=0`) |
| Surface pattern color | `_InnerFramePatternColorEnabled`, `..ColorType`, `..ColorMode`, `..ColorUsed`, `..ColorA/B/C/D` |
| Gradient | `_InnerFrameGradientEnabled`, `_InnerFrameGradientType`, `..ColorA/B/C/D` (defaults are a dark gray ramp, unlike Panel's RGB/Y demo defaults), `..Direction`, `..Speed`, `..Scale`, `..Offset`, `_InnerFrameGlobalBlend`, `_InnerFrameGlobalIntensity`, `..ColorUsed` |

InnerFrame has **no** `_InnerFrameFaceEnabled`/ring-mode equivalent to Panel's `_PanelFaceEnabled` —
it is always a filled shape, never a ring, and it has no nested third-level shape of its own.

---

## 6. Section 6 — Border

A thin frame cut in at the outer canvas/quad edge (independent of the panel shape's own edge —
it's evaluated against the *same* body SDF, but its width/softness are usually small enough to sit
right at the visual boundary). Drawn **after** InnerFrame; where its territory mask is significant it
first clears (`*= 1-territory`) whatever was already composited, then draws the border color on top —
so it can visibly cut into Panel/InnerFrame pixels near the edge, not just add on top of empty space.

| Property | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_BorderEnabled` | Float | — | 0 | Guard. |
| `_BorderColor` | Color | — | (1,1,1,1) | Base border color. |
| `_BorderRenderAlpha` | Float | 0‑1 | 1 | Alpha multiplier. |
| `_BorderRenderEmissive` | Float | 0‑1 | 0 | Additive emissive contribution. |
| `_BorderWidth` | Float | 0.001‑0.5 | 0.02 | Border band width outward from the body SDF's zero boundary. |
| `_BorderSoftness` | Float | 0‑0.5 | 0.01 | Outer-edge falloff softness. |
| `_BorderIntensity` | Float | 0‑2 | 1.0 | Multiplies the composited mask. |
| `_BorderGradientEnabled` | Float | — | 0 | Guard for a gradient sweep over the border color. |
| `_BorderGradientType` | Int (`Enum(GradientType)`) | 0‑4 | 0 (Linear) | See §3.5. |
| `_BorderGradientColorA/B/C/D` | Color | — | white → dark gray ramp | Gradient stops. |
| `_BorderGradientDirection` | Vector2 | — | (0,1,0,0) | Linear/Triangle direction. |
| `_BorderGradientSpeed` | Float | — | 1.0 | Animation speed. |
| `_BorderGradientScale` | Float | 0.1‑5 | 1.0 | Spatial frequency. |
| `_BorderGradientOffset` | Float | -2‑2 | 0.0 | Phase offset. |
| `_BorderGlobalBlend` | Float | 0‑1 | 0.0 | Blend toward scene-wide global gradient. |
| `_BorderGlobalIntensity` | Float | 0‑2 | 1.0 | Multiplies global blend factor. |
| `_BorderGradientColorUsed` | Int (IntRange) | 2‑4 | 2 | Active stop count. |

---

## 7. Section 6.5 — Corner screws & Lighting

| Property | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_PanelScrewsEnabled` | Float | — | 0 | See §1. Draws 4 shaded bolt heads in the corners, on top of everything (Panel, InnerFrame, Border). Implemented in `CG/SDF/SDFPanelScrews.cginc`; head shape, colours, drive type, angle, recess depth and metallic are all skinnable. |
| `_PanelScrewShapeType` / `_PanelScrewInset` / `_PanelScrewRadius` / `_PanelScrewColor` / `_PanelScrewSlotColor` / `_PanelScrewRotation` / `_PanelScrewDepth` / `_PanelScrewMetallic` | — | — | — | See the §1 table. |
| `_LightingAmbient` | Float | 0‑1 | 0.5 | Ambient light floor applied in `ApplyUILighting` before the 3 directional lights are added — affects Panel's and InnerFrame's lit color (not Edge/Border/Shadows/Screws, which are unlit flat composites). |

The 3 scene lights themselves (`_GlobalLightPos1‑3`, `_GlobalLightColor1‑3`, `_GlobalLightFx1‑3`) are
**not** per-material properties exposed in this shader's Properties block — they're pushed globally by
`UiSceneDirector`/the designer's `GlobalLightingPlugin`, shared by every widget in the scene. A skin
cannot author light position/color/specular per-instance; only shadow *lengths* (`_LightingShadowN*`,
`_PanelShadowN*`) are per-skin.

---

## 3. Enum reference (shared by every `Enum(...)` property above)

### 3.1 `PanelBodyShapeType` — `_PanelShapeType`, `_PanelFaceShapeType`, `_InnerFrameShapeType`

Read from `getPanelBodySDF`'s `switch (shapeType)` in `SDFPanelShapes.cginc`:

- `case 0: // Squircle` — `RoundedRectSDF`. `param1` = squareness, `r = minDim * (1.0 - saturate(param1))` (0 = pill/full round, 1 = sharp rectangle). If `_PanelCornerRadiusPx > 0.5` and pixel size is known, overrides `r` with a fixed absolute-pixel radius instead.
- `case 1: // Polygircle` — if `param1 < 0.001`, plain `CircleSDF`. Else an n-gon: `sides = clamp((int)(3.0 + param1*9.0 + 0.5), 3, 12)` (param1 sweeps 3→12 sides across its range), `rounding = param2 * minDim * 0.15` (corner rounding on the polygon).
- `case 2: // Tab` — `PanelTabShapeSDF`: `param1` = top corner radius fraction (`r = min(halfSize)*saturate(param1)`). Rounded on the upper half (`p.y >= 0`), hard rectangular corners on the lower half (`p.y < 0`).
- `case 3: // Hexagon` — `PanelHexagonStretchSDF`, flat-top, stretches with the shape's own aspect (does not stay regular). `param1` = rounding, `rounding = param1 * minDim * 0.1`.
- `case 4: // Octagon` — `PanelOctagonSDF`, rectangle with 45° chamfered corners. `param1` = corner-cut fraction 0‑1, `cut = lerp(0, s*0.5, saturate(param1))` where `s = min(halfSize)`.
- `case 100: // Texture` — SDF sampled from a `Texture2DArray` layer via `sampleTextureSDF`, using `_PanelBodyShapeTexLayer`/`_PanelBodyShapeTexScale` (or the per-call override args for InnerFrame/Face). `SDFTextures.cginc` was not part of this task's read set — texture-array asset wiring is not documented here.
- `default:` — falls back to the Squircle formula.

After the switch, **every** case (including Texture) gets `d -= _PanelBodyRoundness * minDim * 0.15` applied uniformly.

### 3.2 `BevelProfileType` — `_PanelBevelProfileType`, `_InnerFrameBevelProfileType`

From `ShaderConstants.cs` / `CalculateShapeBevelNormal` in `UILighting.cginc`:
- `0 = Dome` — smooth sine/smoothstep roll-off (default).
- `1 = Linear` — constant-slope angled shelf; `_..ProfileSharpness` sets the slope, full depth reached right at the edge when sharpness=1.

### 3.3 `PatternType` — `_PanelPatternType`, `_PanelBevelPatternType`, `_InnerFramePatternType`, `_InnerFrameBevelPatternType`

All 20, from `ShaderConstants.cs` (`#define PATTERN_*` in `UIPatterns.cginc` matches):

| Value | Name | Notes |
|---|---|---|
| 0 | Plastic | Multi-octave noise (`param1`=octave count 1‑4), optional domain warp (`param2`), metallic flake sparkle (`param3`). |
| 1 | Metal | Anisotropic linear brushed noise. `param1` = grain direction angle (0=horizontal…1=vertical), `param2` = anisotropy stretch, `param3` = streak variation. |
| 2 | RadialBrushed | Angular stripes from center. `param1` = groove-count multiplier, `param2` = groove noise irregularity, `param3` = concentric ring emphasis. |
| 3 | CarbonFiber | Woven checkerboard fiber pattern. `param1` = weave tightness, `param2` = crossing depth/contrast, `param3` = clear-coat smoothing. |
| 4 | Leather | Voronoi-cell grain with pores. `param1` = pore density, `param2` = organic warp, `param3` = crack depth along cell edges. |
| 5 | BrushedCross | Two opposing-angle brush strokes. `param1` = cross angle, `param2` = stroke noise, `param3` = balance between the two stroke layers. |
| 6 | Satin | Smooth directional sheen band. `param1` = sheen band width, `param2` = flow distortion, `param3` = shimmer sparkle. |
| 7 | Concrete | Multi-octave rough noise + Voronoi aggregate. `param1` = aggregate/pebble visibility, `param2` = surface cracks, `param3` = rough-vs-smooth variation. |
| 8 | Fabric | Woven warp/weft threads. `param1` = thread density, `param2` = spacing irregularity, `param3` = warp/weft emphasis ratio. |
| 9 | Paper | Granular fiber noise + directional bias. `param1` = fiber density, `param2` = blotchy stain marks, `param3` = surface tooth depth. |
| 10 | Frosted | Voronoi crystal + soft diffusion blend. `param1` = crystal/grain size, `param2` = diffusion amount, `param3` = opacity variation. |
| 11 | DiamondPlate | Staggered raised-diamond industrial grid. `param1` = diamond spacing, `param2` = raised height, `param3` = edge sharpness. |
| 12 | Knurled | Diagonal-grid diamond grip pattern. `param1` = grid density, `param2` = groove depth, `param3` = round-vs-sharp peak shape. |
| 13 | HexGrid | Honeycomb cell pattern. `param1` = cell size, `param2` = border width, `param3` = concave-cell indent depth. |
| 14 | Perforated | Regular round hole grid. `param1` = hole density, `param2` = hole size, `param3` = edge softness. |
| 15 | WoodGrain | Elliptical rings + fine grain lines + knots. `param1` = ring spacing, `param2` = ring wander/waviness, `param3` = knot frequency. **This is the pattern named in the task's grain-scale requirement — see §5.** |
| 16 | Marble | Turbulent sine veining. `param1` = vein scale, `param2` = turbulence amount, `param3` = vein sharpness (thin crisp vs soft streaks). |
| 17 | Ceramic | Smooth glaze + optional crackle/crazing. `param1` = glaze smoothness, `param2` = crackle amount, `param3` = gloss variation. |
| 18 | Circuit | Manhattan-routed PCB traces + pads, hashed per-cell. `param1` = trace density, `param2` = junction pad frequency, `param3` = second offset layer opacity. |
| 19 | NoiseOrganic | Generic FBM turbulence. `param1` = octave count 1‑6, `param2` = lacunarity, `param3` = persistence. |

### 3.4 `PatternColorType` / `PatternColorMode` — `_Panel(Bevel)PatternColorType/Mode`

From `SamplePatternColorPosition` / `ApplyMaterialPattern` in `UIPatterns.cginc` (matches `ShaderConstants.cs`):

`PatternColorType` (maps the pattern's raw scalar to a [0,1] palette lookup position):
- `0 = Gradient` — `saturate((patternValue+1)*0.5)`: signed range [-1,+1] maps linearly, negative→A, midpoint→mid stop, positive→D.
- `1 = Feature` — `saturate(abs(patternValue))`: flat/quiet areas of the pattern → A, strong peaks/features → D.
- `2 = Zones` — `frac(abs(patternValue) * 2.718281828)`: wraps irregularly, giving visually distinct color "zones" per feature instance rather than a smooth ramp.
- `3 = Bands` — `abs(sin(patternValue * PI))`: sine-wave banding, good for rings/veins/layered looks.

`PatternColorMode` (how the looked-up palette color combines with the surface's existing color):
- `0 = Modulate` — `return patternColor * (1.0 + pattern)`: palette color's own brightness is modulated by pattern strength; ignores `baseColor` entirely.
- `1 = Lerp` — `return lerp(baseColor, patternColor, saturate(abs(pattern)))`: base color blends toward the palette color where the pattern is strong.
- `2 = Additive` — `return baseColor + patternColor * saturate(pattern)`: palette color adds on top at strong positive features only.
- `3 = Multiply` (`else` branch, effectively "any other value") — `return baseColor * lerp(1, patternColor, saturate(abs(pattern)))`: palette tints/darkens the base color.

### 3.5 `GradientType` — `_Panel(Bevel)GradientType`, `_Edge/Border/InnerFrame(Bevel)GradientType`

From `UIGradients.cginc` / `ShaderConstants.cs`:
- `0 = Linear` — `dot(uv, normalize(direction)) * scale + time*speed*0.1 + offset`.
- `1 = Radial` — distance from UV center (0.5,0.5), scaled.
- `2 = Angular` — `atan2` sweep around UV center, normalized to [0,1] turns.
- `3 = Diamond` — taxicab (`|dx|+|dy|`) distance from UV center.
- `4 = Triangle` — animated triangle wave along `direction`, self-repeating via `frac()`.
- `5 = BevelDepth`, `6 = BevelWalls` — **RM-only** (raymarched knob bevel topology, uses the 3D hit-point surface normal). Not meaningful for `SDFPanel.shader`'s 2D bevel path — selecting them here falls through `GetGradientPosition`'s `default:` case, which returns a flat `0.5` (i.e. always the exact midpoint color, no visible gradient).

---

## 4. `_XxxEnabled` guard list

| Guard | Turns off at 0 |
|---|---|
| `_PanelEnabled` | The entire Panel body: shape, bevel, bevel pattern/gradient, rim, surface pattern/gradient, lighting. InnerFrame keeps rendering independently. |
| `_PanelBevelEnabled` | Panel's main bevel shading (falls back to flat lit face) **and** force-disables `_PanelBevelPatternEnabled`/`_PanelBevelGradientEnabled` regardless of their own flags. |
| `_PanelBevelPatternEnabled` | Panel bevel's procedural material texture overlay. |
| `_PanelBevelPatternColorEnabled` | Palette recoloring of the bevel pattern (falls back to plain brightness modulation). |
| `_PanelBevelGradientEnabled` | Panel bevel's own gradient sweep. |
| `_PanelRimEnabled` | Panel's outer rim bevel ring entirely (function returns the input unchanged). |
| `_PanelPatternEnabled` | Panel's whole-face procedural pattern. |
| `_PanelPatternColorEnabled` | Palette recoloring of the surface pattern. |
| `_PanelGradientEnabled` | Panel's whole-face gradient sweep. |
| `_PanelFaceEnabled` | Switches Panel to ring/outline mode (interior punched out) instead of disabling anything outright. |
| `_PanelFaceShapeEnabled` | Falls back to a uniform inward offset of the body shape for the bevel's inner boundary, instead of an independently-shaped face SDF. |
| `_InnerFrameEnabled` | The entire InnerFrame layer (shape/bevel/rim/pattern/gradient/lighting) — independent of `_PanelEnabled`. |
| `_InnerFrameShapeEnabled` | InnerFrame borrows the Panel's own body shape type/params instead of using its own. |
| `_InnerFrameBevelEnabled`, `..BevelPatternEnabled`, `..BevelPatternColorEnabled`, `..BevelGradientEnabled`, `..RimEnabled`, `..PatternEnabled`, `..PatternColorEnabled`, `..GradientEnabled` | Same semantics as the Panel equivalents, InnerFrame-scoped. |
| `_EdgeEnabled` | The whole recessed-indent band around the panel quad. |
| `_EdgeGradientEnabled` | Edge band falls back to flat `_EdgeColor`. |
| `_BorderEnabled` | The whole cut-in border at the canvas edge. |
| `_BorderGradientEnabled` | Border falls back to flat `_BorderColor`. |
| `_LightingShadowNEnabled` (×3) | That external shadow slot. |
| `_PanelShadowNEnabled` (×3) | That panel-body shadow slot. |
| `_PanelScrewsEnabled` | The 4 corner screw discs. |
| `_ReceiveSceneShadows` | Panel stops darkening from other widgets' cast shadows (buffer sample skipped). |

---

## 5. Reading the panel as a physical plate

**Rim vs bevel vs edge — three separate, layerable effects, outer to inner:**
1. **Edge indent** (§2) — a soft dark halo drawn in the gap *around* the panel (in the `_PanelPadding`
   margin), faking a recessed socket the plate sits in. Purely a flat color composite, not lit.
2. **Rim bevel** (`_PanelRim*`, §4.7) — a thin lit bevel right at the outer silhouette. Sign of
   `_PanelRimDepth` reads as a raised lip (positive) or a sunken groove (negative) running around
   the very edge of the plate.
3. **Main bevel** (`_PanelBevel*`, §4.3) — the primary chamfer from the outer body down to the
   interior face, width set by `_PanelBevelDistance`. Sign of `_PanelBevelDepth` is raised-emboss
   (positive) vs recessed-engrave (negative); the face itself can additionally dome/bowl via
   `_PanelFaceSmoothness`.

All three can be stacked (e.g. edge halo + raised rim lip + recessed main bevel) since they're
independent `_XxxEnabled` guards operating on different bands of the same shape.

**Screws / rivets** (`_PanelScrewsEnabled`, §7): exactly 4, one per corner, no count control.
`_PanelScrewInset` and `_PanelScrewRadius` are in the **same units as `_PanelPadding`** and are
measured from the *panel body's* corner, not the quad's: the placement sphere-traces the body's own
SDF until it reads `-inset`, so a bolt keeps a true constant clearance from the plate edge and tucks
correctly inside a rounded, chamfered (Octagon) or sloped (Hexagon) corner. Everything scales with
the plate, exactly like the rest of the panel.

They used to be `_PanelScrewInsetPx` / `_PanelScrewRadiusPx` — a fixed count of real screen pixels in
from the raw *quad* corner. That was the one part of the panel that did not scale with the widget,
and because it ignored both the padding and the corner shape the bolts drifted off the corner they
were supposed to be holding down. The `Px` suffix went with the measurement.

Appearance is fully skinnable: `_PanelScrewShapeType` picks one of eight drive types (slotted,
Phillips, hex socket, Torx, plain dome rivet, hex bolt head, Pozidriv, Robertson), `_PanelScrewColor`
/ `_PanelScrewSlotColor` the metal and the recess, `_PanelScrewRotation` the drive angle,
`_PanelScrewDepth` how deep the recess reads, `_PanelScrewMetallic` the glint. The head is lit by the
scene's key lamp (dome diffuse + Blinn glint + a rolled rim crescent) rather than the hard-coded
"light from the top-left" shade it used to carry, so the hardware relights with every other widget.

**Pattern SCALE — UV-space, not pixel-space (the grain-too-fine bug).**

Every pattern sampler (`SamplePlastic`, `SampleWoodGrain`, `SampleMetal`, …) builds its sample
coordinate as `uv = (pos + center) * scale`, where `pos`/`center` come from `uvIso` — the fragment's
UV **normalized to the widget's own 0‑1 rect**, aspect-corrected but with no notion of the widget's
actual on-screen pixel size:

```
float2 uvIso = (uv - center) / float2(aspectScale.x, aspectScale.y) + center;
...
float3 mainPatternedColor = ApplyMaterialPattern(baseColor, uvIso, panelComp, 0.0, 0.0, specularMod, normalOffset);
```

`_PanelPatternScale` / `_PanelBevelPatternScale` (and the InnerFrame/Bg/Track/Handle equivalents in
the other shader) therefore express **"how many pattern cycles fit across the widget's own 0‑1 UV
span"** — a widget-relative frequency — not a physical grain size and not derived from
`_WidgetPixelSize` at all (unlike `_PanelCornerRadiusPx`, which explicitly is pixel-locked).

Consequence: **the same numeric scale value produces the same cycle *count* regardless of the panel's
actual pixel footprint**, so the apparent on-screen grain size is directly proportional to how big the
panel is rendered:
- A large panel (e.g. 600px wide) spreads that fixed cycle count over 600 pixels → each grain cycle
  covers many pixels → grain reads clearly, looks like real wood/brushed-metal texture.
- A small panel (e.g. 60px wide) squeezes the *same* cycle count into 60 pixels → each cycle is only
  a few pixels wide, well under what antialiasing/derivative-based normal perturbation can resolve →
  the grain aliases into flat noise or disappears into visual mush. **This is exactly the "grain too
  fine to see at small sizes" failure mode.**

**Fix / practical guidance:** `_PanelPatternScale` and `_PanelBevelPatternScale` (Range 1‑100) must be
tuned **relative to the control's actual pixel size**, not left at one fixed number across every skin
usage:
- Lower the scale value to make the grain **coarser** (fewer cycles across the panel — each cycle
  covers more pixels). For small panels (roughly under ~120px on the short side), keep scale in the
  low end of the range, ballpark **1–8**, so a handful of visible cycles span the panel instead of
  dozens of sub-pixel ones.
- Raise the scale value to make the grain **finer** — safe on large panels (300px+) up to the 20‑60
  range the shipped defaults use.
- **Since 2026-10-04 there is: set `_PanelPatternPx`** (canvas units per tile) and the pattern samples
  `(uv-0.5)·_WidgetPixelSize/_PanelPatternPx` instead of `uvIso`. The rest of this section is the
  legacy (`_PanelPatternPx` 0) behaviour.
- There is no automatic DPI/size compensation anywhere in this pipeline. A `.states.json` authored and
  eyeballed on a large preview panel in the Designer window **will look aliased on small instances of
  the same control** unless the pattern scale (and, to a lesser degree, `_PanelBevelPatternScale`
  separately, since the bevel band is narrower than the full face) is deliberately lowered for small
  variants, or overridden per-instance at runtime via `SetMaterialFloat("_PanelPatternScale", ...)`.
- The bevel pattern (§4.4) samples the *same* `uvIso` (whole-widget-normalized) space as the main
  surface pattern, not a space normalized to the (much narrower) bevel band itself — so a bevel
  pattern using the same scale value as the main surface pattern will look visually finer/denser
  than the main surface pattern, because the bevel band physically occupies far fewer of those UV
  units. Expect to use a *lower* `_PanelBevelPatternScale` than `_PanelPatternScale` to get a
  comparable apparent grain size in the bevel.

---

## 6. Interaction / dependency notes

- `_PanelEnabled` and `_InnerFrameEnabled` are fully independent — InnerFrame is not "inside" Panel's
  guard despite being visually nested on top of it.
- `_PanelFaceEnabled = 0` (ring mode) only produces a visible ring if `faceInset` (`rimWidth +
  bevelDist`) is nonzero — i.e. you need `_PanelRimEnabled` and/or `_PanelBevelEnabled` with a nonzero
  distance, otherwise `faceInset` is 0 and the code path sets `bodyMask = 0` outright (nothing draws).
- `_PanelFaceShapeEnabled` changes what `panelDist` (used for the rim, §4.7) even means: when a custom
  face shape pokes outside the body's own bevel band (`topFaceDist > 0 && bodyDist < 0`), the code
  tilts the bevel normal to fake a wall between the two shapes (lines 714‑730) — a deliberate but
  approximate hack, not a true 3D wall.
- Panel body shadows (`_PanelShadowN*`) use `pseudoHeight`, which is derived from
  `_PanelBevelDistance`/`_PanelBevelDepth` **only if `_PanelBevelEnabled` is on** — a panel with the
  bevel disabled but body shadows enabled will cast a flat silhouette shadow with no 3D hull-sweep
  extrusion, even if `_PanelShadowNCast` is nonzero.
- `_PanelShapeParam3` is threaded through every shape-type call site but not read by any case in
  `getPanelBodySDF` — currently a no-op regardless of shape type.
- `_PanelPatternRotateEnabled`/`_PanelPatternModEnabled`/`ModAmount`/`ModFrequency` are wired to
  `currentValue`, which Panel always calls with `0.0` — these four properties are dead weight for
  Panel specifically (they matter on value-driven widgets like Slider/Knob that share the same
  `ApplyMaterialPattern` function). `_PanelPatternOffset` is *not* value-gated and does work.
- Gradient types 5 (`BevelDepth`) and 6 (`BevelWalls`) are RM/3D-hit-point-only; selecting them on any
  `Panel(Bevel)GradientType`/`InnerFrame(Bevel)GradientType` property in this (non-RM) shader silently
  produces a flat mid-palette color (see §3.5).

---

## 7. Gotchas

- **`_PanelCornerRadiusPx` needs `_WidgetPixelSize` to be pushed at runtime.** In a static Designer
  preview or a hand-edited `.states.json` with no live `MaterialStateController`, this property has no
  effect even if nonzero — the code explicitly checks `min(_WidgetPixelSize.x, _WidgetPixelSize.y) >
  1.0` before using it.
- **Corner screws are the only geometry in this shader locked to real screen pixels.** Every other
  distance/width/padding property (`_PanelPadding`, `_PanelBevelDistance`, `_PanelRimWidth`,
  `_EdgeWidth`, `_BorderWidth`, …) is expressed in "equi-pixel" units that scale proportionally with
  the widget's own size (shorter side = 2.0 equi-units), so bevels/rims/edges stay visually
  proportional as a control is resized — screws do not, by design (rack-hardware realism).
- **Pattern/bevel-pattern scale is UV-normalized to the widget, not to real pixels — see §5.** This is
  almost certainly the mechanism behind "grain too fine to see at small sizes."
- **`_PanelShapeParam3` and (on Panel specifically) the four value-gated pattern-rotation properties
  are inert** — don't spend time tuning them expecting a visible change on Panel.
- **`_PanelBodyRoundness` stacks with shape-specific rounding.** A Squircle at `param1=1` (sharp
  rect) plus `_PanelBodyRoundness=1` will still show some corner rounding (up to 15% of the shorter
  half-extent), since the roundness subtraction happens unconditionally after the shape switch.
- **Screw appearance (metal shade, slot color/angle) is not skinnable** — only enable/inset/radius are
  exposed; the visual treatment is hard-coded.
- **`_InnerFrameSize` and `_PanelFaceSize` use the identical margin formula against the identical
  base** (`(1 - saturate(size)) * min(bodyHalfW, bodyHalfH)`, i.e. the Panel *body's* half-extents in
  both cases) — so with `_PanelFaceShapeEnabled = 0` and `_InnerFrameShapeEnabled = 0` (both borrowing
  the Panel body's plain shape), setting `_InnerFrameSize` smaller than `_PanelFaceSize` nests
  InnerFrame concentrically inside the visible face as expected. That guarantee **breaks** as soon as
  `_PanelFaceShapeEnabled = 1` — the face then follows its own shape type/rotation/param1‑3 (and the
  bevel target moves accordingly), while `_InnerFrameSize`'s margin is still measured against the
  *body's* half-extents, not the custom face's actual footprint — so the two will drift apart unless
  InnerFrame is also given a matching custom shape (`_InnerFrameShapeEnabled = 1` with the same
  params).
- **`SDFPanelRM.shader` was not read for this task.** If a raymarched panel variant exists/is used,
  verify its section-9 properties separately before assuming full parity with this document.
- **`SDFTextures.cginc`** (backing the `Texture` shape type, value 100, on any shape-type property in
  this doc) was not part of the read set — texture-array asset assignment/binding is not documented
  here; treat Texture-type shapes as unverified until checked separately.
