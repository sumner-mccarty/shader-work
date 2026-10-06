# SDFSlider / SDFSliderRM — Parameter Reference

Source files read in full for this document:
- `Assets/Shaders/SDFSlider.shader` (base 2D shader — Properties block + fragment sections 1–11)
- `Assets/Shaders/SDFSliderRM.shader` (3D raymarched-handle variant — diffed against base for ADDED properties only)
- `Assets/Shaders/CG/SDF/SDFSliderUniforms.cginc`
- `Assets/Shaders/CG/SDF/SDFSliderLayers.cginc`
- `Assets/Shaders/CG/SDF/SDFSliderHandleShapes.cginc`
- Supporting enum sources cross-checked for accuracy: `Assets/Shaders/ShaderConstants.cs` (canonical C# mirror of every shader enum), `Assets/Shaders/CG/SDF/SDFPanelShapes.cginc`, `Assets/Shaders/CG/Core/UIPatterns.cginc`, `Assets/Shaders/CG/Core/UIGradients.cginc`, `Assets/Shaders/CG/Core/UILighting.cginc`, `Assets/Shaders/CG/Core/UIViewCamera.cginc`.

`controlType` for `.states.json` is whatever string the `MaterialStateController` is constructed with for this widget (see `SliderControl`/`MaterialStateUiValueControl` in `Assets/MaterialStateUiControls/`) — not read from the shader itself, so it isn't covered here.

---

## 0. How the fragment function is organized

The header comment in `SDFSlider.shader` describes the widget's conceptual layers (1=Background … 8=Shadows), but the fragment body's own numbered section comments — which is what a skin author actually walks through — are:

| # | Section (as commented in code) | Line (base shader) |
|---|---|---|
| 1 | Edge indent | `SDFSlider.shader:872` |
| 2 | External shadows — *rendered earlier, in the `_ShadowPassMode>0.5` block* | `SDFSlider.shader:901` (comment only) |
| 3 | Background body + bevel + rim + lighting | `SDFSlider.shader:906` |
| 4 | Track base (simple: no bevel profile, no pattern color) | `SDFSlider.shader:1005` |
| 5 | ValueUnfilled (track segment: handle → max end) | `SDFSlider.shader:1064` |
| 6 | ValueFilled (handle ≥ zero point) / ValueNegFilled (handle < zero point) | `SDFSlider.shader:1108` |
| 7 | ScaleMarks | `SDFSlider.shader:1196` |
| 8 | Handle body shadows — *rendered earlier, in the `_ShadowPassMode>0.5` block* | `SDFSlider.shader:1244` (comment only) |
| 9 | Handle body + bevel + rim + lighting (RM: raymarched 3D extrusion) | `SDFSlider.shader:1249` / `SDFSliderRM.shader:2588` |
| 10 | HandleFace (optional inner face shape on the handle) | `SDFSlider.shader:1354` |
| 11 | Border | `SDFSlider.shader:1429` |
| — | UI clip-rect + final composite (unnumbered tail) | `SDFSlider.shader:1480` |

Sections 2 and 8 (all shadows) do not run in the normal widget-quad pass at all. They run only when `_ShadowPassMode > 0.5`, on a separate, larger "shadow quad" rendered by `WidgetShadowQuad.cs` (see §5, "Shadows only render on the shadow quad").

The tables below are grouped by these same numbers (plus a "Global / System" group for properties outside any section, and a separate RM-only group for `SDFSliderRM.shader`).

**Legend used in every table:**
- **Range** column shows the Unity `Range(min,max)` slider bounds, or "unbounded" for a plain `Float`/`Int` property, or the fixed set of legal values for a `[IntRange]` selector.
- Any `*ColorUsed` property (`[IntRange] Range(2,4)`) picks how many of that layer's 4 gradient/pattern color stops (A/B/C/D) are actually blended between — at the default of `2`, C and D are ignored no matter what they're set to.
- `*RenderAlpha` = how much this layer's **lit** color is composited into the visible output (0 = layer invisible, but its SDF/bevel/lighting math still runs — see Gotchas). `*RenderEmissive` = how much of this layer's **unlit base color** is *added* on top afterward (a glow contribution independent of the lighting model) — the two are independent; a layer can be alpha-invisible and still glow, or fully opaque with zero glow.

---

## 1. Global / System properties (not tied to a numbered section)

| Name | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_MainTex` | 2D (`[PerRendererData]`) | n/a | `"white"` | Standard UGUI `Image` texture slot. Not sampled by any SDF math in this shader — present only because UGUI/CanvasRenderer expects it. |
| `_Color` | Color | n/a | `(1,1,1,1)` | UGUI `Graphic.color` tint. Multiplied into `finalColor`/`emissiveAccum` at the very end (`SDFSlider.shader:1487-1488`), i.e. it tints the *entire already-composited* widget, not any one layer. |
| `_Value` | Float (Range 0–1) | 0–1 | `0` | Normalized handle position / fill amount. Drives both the handle's travel position and the fill-region extent. See §4. |
| `_TrackValueZeroPoint` | Float (Range 0–1) | 0–1 | `0` | Where the fill "starts counting from" along the track: `0` = fill grows from the start end, `0.5` = fill grows outward from the center (bipolar), `1` = fill grows from the end backward. See §4. |
| `_Position` | Vector4 | n/a | `(0,0,0,0)` | Widget's screen-space anchor position, written by the scene director (`UiSceneDirector`) — used for the shared cross-widget light system (`UIGlobalUniforms.cginc`) and, in the RM shader, the scene-camera parallax term. Not hand-authored per skin. |
| `_AspectRatio` | Float | unbounded (0 = auto) | `0` | Overrides the auto-detected quad aspect ratio (`abs(ddy(uv.y))/abs(ddx(uv.x))`, `SDFSlider.shader:669-671`). `0` = auto-detect from the actual rendered rect. |
| `_ShadowPassMode` | Float | unbounded (treated as bool via `>0.5`) | `0` | `0` = normal widget quad (renders everything **except** shadows). `1` = shadow quad (renders **only** the 6 shadow layers, on an expanded backing quad). Driven by `WidgetShadowQuad.cs`, not hand-authored in `.states.json`. |
| `_ShadowUvExpand` | Float | unbounded | `1` | How much larger the shadow quad's UV space is than the widget's own, so shadows can extend past the widget's own edge without being clipped by it. Set by `WidgetShadowQuad`. |
| `_StencilComp`, `_Stencil`, `_StencilOp`, `_StencilWriteMask`, `_StencilReadMask`, `_ColorMask` | Float | unbounded | `8, 0, 0, 255, 255, 15` | Standard Unity UI masking plumbing (`Stencil{}` block, `ColorMask[_ColorMask]`). Managed by UGUI's `Mask`/`RectMask2D`, not authored per skin. |

---

## 2. Section 3 — Background (`_Bg*`)

Shape uses `getPanelBodySDF` (see enum table in §6). Full material pipeline: shape → bevel → bevel pattern → bevel gradient → rim → base pattern → base gradient → lighting.

| Name | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_BgEnabled` | Float (guard) | n/a (`>0.5`) | `1` | Master switch for the whole Background layer (section 3 body block, `SDFSlider.shader:909`). |
| `_BgColor` | Color | n/a | `(0.15,0.15,0.15,1)` | Base fill color before gradient/pattern/lighting. |
| `_BgRenderAlpha` | Range | 0–1 | `1` | See legend. |
| `_BgRenderEmissive` | Range | 0–1 | `0` | See legend. |
| `_BgShapeType` | Int `[Enum(PanelBodyShapeType)]` | 0, 1, 2, 3, 4, 100 | `0` | Background outline shape. See §6.1. |
| `_BgShapeParam1` | Range | 0–1 | `0.2` | Shape-specific (see §6.1 per-case meaning). |
| `_BgShapeParam2` | Range | 0–1 | `0.5` | Shape-specific (Polygircle rounding only; unused by most shapes). |
| `_BgShapeParam3` | Range | 0–1 | `0.5` | Declared but not read by `getPanelBodySDF`'s dispatcher for any current case — reserved. |
| `_BgShapeRotation` | Range | -180–180 (degrees) | `0` | Rotates the background shape's local space before SDF evaluation (`bgRotRad`, `SDFSlider.shader:690-691`). |
| `_BgPadding` | Range | 0.0–1.5 | `0.1` | Equi-pixel margin shrinking the background's half-extents in from the quad edge (`bgHalfW/H = aspectScale − _BgPadding`, `SDFSlider.shader:687-688`). |
| `_PanelBodyRoundness` | Range | 0–1 | `0` | Global corner-radius *reduction* applied after shape dispatch: `d -= _PanelBodyRoundness * minDim * 0.15` (`SDFPanelShapes.cginc:160`) — expands the shape outward, effectively rounding/inflating every corner regardless of shape type. |
| `_PanelBodyShapeTexLayer` | Float | unbounded (-1 = none) | `-1` | Texture2DArray layer index, used only when `_BgShapeType = 100` (Texture). |
| `_PanelBodyShapeTexScale` | Vector4 | n/a | `(1,1,0,0)` | UV scale for the Texture shape case. |
| `_BgBevelEnabled` | Float (guard) | n/a (`>0.5`) | `0` | Enables the background bevel (rim-to-face slope + its own normal). |
| `_BgBevelDepth` | Range | -1.0–1.0 | `0.2` | Signed bevel height. Positive = raised/domed, negative = recessed/carved. Sign flips the normal direction (`UILighting.cginc:655`). |
| `_BgBevelSmoothness` | Range | 0.001–1.0 | `0.02` | Dome-profile roll-off softness (only matters when `_BgBevelProfileType=0`). |
| `_BgBevelDistance` | Range | 0.001–1.0 | `0.1` | How far inward from the edge the bevel band extends before reaching the flat face. |
| `_BgFaceSmoothness` | Range | -1.0–1.0 | `0.0` | Dome/bowl curvature applied to the flat *face* interior (beyond the bevel band), not the bevel band itself. |
| `_BgBevelProfileType` | Int (**not** `[Enum]`-tagged in the Properties block, but is `BevelProfileType`) | 0 or 1 | `0` | `0` = Dome (smoothstep S-curve), `1` = Linear (constant-slope shelf, scaled by `_BgBevelProfileSharpness`). See §6.5. |
| `_BgBevelProfileSharpness` | Range | 0–1 | `0.5` | Linear-profile-only slope scale; ignored when profile type = Dome. |
| `_BgBevelPatternEnabled` | Float (guard) | n/a (`>0.5`) | `0` | Enables a procedural surface-material pattern texture painted onto the bevel band. |
| `_BgBevelPatternType` | Int `[Enum(PatternType)]` | 0–19 | `0` | Which procedural material (Plastic/Metal/Wood/etc). See §6.2. |
| `_BgBevelPatternScale` | Range | 1–100 | `20` | Pattern tiling frequency. |
| `_BgBevelPatternIntensity` | Range | 0–1 | `0.3` | Overall pattern strength. |
| `_BgBevelPatternContrast` | Range | 0.1–5 | `1.5` | Pattern contrast curve exponent. |
| `_BgBevelPatternSpecularEffect` | Range | 0–2 | `1.0` | How much the pattern modulates specular highlight strength. |
| `_BgBevelPatternRoughnessEffect` | Range | 0–2 | `0.3` | How much the pattern perturbs the lighting normal (roughness feel). |
| `_BgBevelPatternParam1` | Range | 0–1 | `0.5` | Pattern-specific "Detail" parameter. |
| `_BgBevelPatternParam2` | Range | 0–1 | `0.5` | Pattern-specific "Distortion" parameter. |
| `_BgBevelPatternParam3` | Range | 0–1 | `0.5` | Pattern-specific "Blend" parameter. |
| `_BgBevelPatternColorEnabled` | Float (guard) | n/a (`>0.5`) | `0` | Recolors the pattern using a 4-stop palette instead of plain brightness modulation. |
| `_BgBevelPatternColorType` | Int `[Enum(PatternColorType)]` | 0–3 | `2` (Zones) | How pattern signal maps to palette position. See §6.3. |
| `_BgBevelPatternColorMode` | Int `[Enum(PatternColorMode)]` | 0–3 | `1` (Lerp) | How the palette color blends with the base color. See §6.4. |
| `_BgBevelPatternColorUsed` | Int `[IntRange]` | 2, 3, or 4 | `2` | How many of ColorA–D are used. |
| `_BgBevelPatternColorA..D` | Color ×4 | n/a | white/0.5/0.3/0.1 gray ramp | Palette stops. |
| `_BgBevelGradientEnabled` | Float (guard) | n/a (`>0.5`) | `0` | Overlays a gradient on the bevel band/wall. |
| `_BgBevelGradientType` | Int `[Enum(GradientType)]` | 0–6 | `1` (Radial) | See §6.6 — note types 5/6 are RM-wall-only (see Gotchas). |
| `_BgBevelGradientColorA..D` | Color ×4 | n/a | white/0.5/0.3/0.1 gray ramp | Gradient stops. |
| `_BgBevelGradientDirection` | Vector4 | n/a | `(1,0,0,0)` | Direction for Linear/Triangle gradient types (xy used). |
| `_BgBevelGradientSpeed` | Float | unbounded | `1.0` | Animation speed (adds `_Time.y * speed * 0.1` to gradient position). |
| `_BgBevelGradientScale` | Range | 0.1–5 | `1.0` | Gradient frequency/tiling. |
| `_BgBevelGradientOffset` | Range | -2–2 | `0.0` | Static phase offset. |
| `_BgBevelGradientColorUsed` | Int `[IntRange]` | 2, 3, or 4 | `4` | Stops used. |
| `_BgRimEnabled` | Float (guard) | n/a (`>0.5`) | `0` | Enables a thin highlighted rim ring at the shape edge, independent of the bevel. |
| `_BgRimDepth` | Range | -0.5–0.5 | `0.1` | Rim's pseudo-height/direction (sign flips whether it reads as raised or recessed). |
| `_BgRimWidth` | Range | 0.001–1.0 | `0.02` | Rim band width. Also feeds `bgFaceInset = bgRimWidth + bgBevelDist` (§5, the rim eats into the same face inset budget as the bevel). |
| `_BgRimSmoothness` | Range | 0.001–0.1 | `0.01` | Rim edge AA/softness. |
| `_BgPatternEnabled` | Float (guard) | n/a (`>0.5`) | `0` | Enables the procedural pattern on the flat face (separate instance from the bevel pattern above). |
| `_BgPatternType` | Int `[Enum(PatternType)]` | 0–19 | `0` | See §6.2. |
| `_BgPatternScale` | Range | 1–100 | `20` | Tiling frequency. |
| `_BgPatternIntensity` | Range | 0–1 | `0.3` | Strength. |
| `_BgPatternContrast` | Range | 0.1–5 | `1.5` | Contrast curve. |
| `_BgPatternSpecularEffect` | Range | 0–2 | `1.0` | Specular modulation. |
| `_BgPatternRoughnessEffect` | Range | 0–2 | `0.3` | Normal perturbation. |
| `_BgPatternRotateEnabled` | Float (guard) | n/a (`>0.5`) | `0` | Rotates the pattern sample space. |
| `_BgPatternModEnabled` | Float (guard) | n/a (`>0.5`) | `0` | Enables a periodic angular modulation ("mod") warp on the pattern. |
| `_BgPatternModAmount` | Range | 0–90 (degrees) | `20` | Mod warp amount. |
| `_BgPatternModFrequency` | Range | 0.1–10 | `1` | Mod warp frequency. |
| `_BgPatternOffset` | Range | -180–180 (degrees) | `0` | Static pattern rotation offset. |
| `_BgPatternParam1..3` | Range ×3 | 0–1 | `0.5` each | Detail / Distortion / Blend, pattern-specific. |
| `_BgPatternColorEnabled` | Float (guard) | n/a (`>0.5`) | `0` | Recolors this pattern via palette. |
| `_BgPatternColorType` | Int `[Enum(PatternColorType)]` | 0–3 | `2` (Zones) | §6.3. |
| `_BgPatternColorMode` | Int `[Enum(PatternColorMode)]` | 0–3 | `1` (Lerp) | §6.4. |
| `_BgPatternColorUsed` | Int `[IntRange]` | 2–4 | `2` | Stops used. |
| `_BgPatternColorA..D` | Color ×4 | n/a | white/0.5/0.3/0.1 gray ramp | Palette stops. |
| `_BgGradientEnabled` | Float (guard) | n/a (`>0.5`) | `0` | Enables a gradient over the base fill color (before pattern/bevel/lighting composite). |
| `_BgGradientType` | Int `[Enum(GradientType)]` | 0–6 | `0` (Linear) | §6.6. |
| `_BgGradientColorA..D` | Color ×4 | n/a | dark gray ramp | Gradient stops. |
| `_BgGradientDirection` | Vector4 | n/a | `(1,0,0,0)` | Linear/Triangle direction. |
| `_BgGradientSpeed` | Float | unbounded | `1.0` | Animation speed. |
| `_BgGradientScale` | Range | 0.1–5 | `1.0` | Frequency. |
| `_BgGradientOffset` | Range | -2–2 | `0.0` | Phase offset. |
| `_BgGlobalBlend` | Range | 0–1 | `0.0` | Blend-in amount of the cross-widget "global" screen-space gradient (`CalculateGlobalGradient`, shared across all widgets via world position — a scene-wide backdrop tint, not this widget's own gradient). `0` = fully ignored. |
| `_BgGlobalIntensity` | Range | 0–2 | `1.0` | Multiplier applied on top of `_BgGlobalBlend`. |
| `_BgGradientColorUsed` | Int `[IntRange]` | 2–4 | `4` | Stops used for `_BgGradientType`. |

---

## 3. Section 4 — Track base (`_Track*`, not the fill segments)

The Track layer is deliberately simpler than Background/Handle: **no bevel-profile type, no rim, and no pattern-color palette** — only a flat bevel normal, a plain (uncolored) pattern, and a gradient. (`SDFSlider.shader:1005`: *"Track base (simple: no bevel profile, no pattern color)"*.)

| Name | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_TrackEnabled` | Float (guard) | n/a (`>0.5`) | `1` | Master switch for the Track groove layer. |
| `_TrackColor` | Color | n/a | `(0.08,0.08,0.08,1)` | Base track color. |
| `_TrackRenderAlpha` | Range | 0–1 | `1` | See legend. |
| `_TrackRenderEmissive` | Range | 0–1 | `0` | See legend. |
| `_TrackWidth` | Range | 0.001–1.0 | `0.05` | Track's half-width **perpendicular** to the slider axis, in equi-pixel space. This is the track's "thickness." |
| `_TrackCornerRadius` | Range | 0–1 | `1.0` | Corner rounding fraction of `min(trackHalfExt.x, trackHalfExt.y)` — since the perpendicular half-width (`_TrackWidth`) is normally the smaller axis, `1.0` (default) makes the track a full pill (rounded caps); `0` makes it a sharp rectangle. |
| `_TrackExtension` | Range | 0.0–0.5 | `0.0` | Extra track half-length added beyond the handle's travel endpoints (`trackAxisHalf = handleHalfTravel + _TrackExtension`, `SDFSlider.shader:721`). Also sets the span used by `ScaleMarks` (§8). |
| `_TrackValuePadding` | Range | 0–0.5 | `0` | Insets the **fill regions** (ValueFilled/Unfilled/Negative) inside the track groove — shrinks their perpendicular half-width by this amount so the fill draws as a thinner line inside a thicker groove. Does **not** affect the track's own visible length. |
| `_TrackBevelEnabled` | Float (guard) | n/a (`>0.5`) | `0` | Enables the track's bevel normal (groove-look lighting). |
| `_TrackBevelDepth` | Range | -1.0–1.0 | `-0.2` | Signed bevel height; negative default = recessed groove look. |
| `_TrackBevelSmoothness` | Range | 0.001–1.0 | `0.02` | Bevel roll-off softness (Dome profile only — Track always uses profile type `0`, hardcoded at `SDFSlider.shader:1055`). |
| `_TrackBevelDistance` | Range | 0.001–1.0 | `0.08` | Bevel band width. |
| `_TrackFaceSmoothness` | Range | -1.0–1.0 | `0.0` | Flat-face dome/bowl curvature beyond the bevel band. |
| `_TrackPatternEnabled` | Float (guard) | n/a (`>0.5`) | `0` | Enables the (uncolored) procedural pattern on the track face. |
| `_TrackPatternType` | Int `[Enum(PatternType)]` | 0–19 | `0` | §6.2. No specular/roughness/mod/rotate/color controls exposed for Track — the simplified `UIComponent` built at `SDFSlider.shader:1031-1044` zeroes those out. |
| `_TrackPatternScale` | Range | 1–100 | `20` | Tiling frequency. |
| `_TrackPatternIntensity` | Range | 0–1 | `0.3` | Strength. |
| `_TrackPatternContrast` | Range | 0.1–5 | `1.5` | Contrast curve. |
| `_TrackPatternParam1..3` | Range ×3 | 0–1 | `0.5` each | Detail / Distortion / Blend. |
| `_TrackGradientEnabled` | Float (guard) | n/a (`>0.5`) | `0` | Enables a gradient over the track base color. |
| `_TrackGradientType` | Int `[Enum(GradientType)]` | 0–6 | `0` (Linear) | §6.6. |
| `_TrackGradientColorA..D` | Color ×4 | n/a | dark gray ramp | Stops. |
| `_TrackGradientDirection` | Vector4 | n/a | `(0,1,0,0)` | Note the default direction is **vertical** (0,1) unlike most other layers' default (1,0) — a plain Linear gradient on the track defaults to running across its thin axis. |
| `_TrackGradientSpeed` | Float | unbounded | `1.0` | Animation speed. |
| `_TrackGradientScale` | Range | 0.1–5 | `1.0` | Frequency. |
| `_TrackGradientOffset` | Range | -2–2 | `0.0` | Phase offset. |
| `_TrackGlobalBlend` | Range | 0–1 | `0.0` | Cross-widget global gradient blend-in. |
| `_TrackGlobalIntensity` | Range | 0–2 | `1.0` | Multiplier on the above. |
| `_TrackGradientColorUsed` | Int `[IntRange]` | 2–4 | `2` | Stops used. |

---

## 4. Section 6 — ValueFilled / ValueNegative (`_TrackValueFilled*`, `_TrackValueNegative*`)

Both are simplified like Track (no rim/bevel-profile/pattern-color). ValueFilled is drawn when the handle sits at-or-past the fill origin; ValueNegative is drawn instead when the handle is on the *other* side of the fill origin — see §7 "Which color draws where."

| Name | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_TrackValueFilledEnabled` | Float (guard) | n/a (`>0.5`) | `1` | Master switch. **On by default** — this is what makes a fresh slider show progress at all. |
| `_TrackValueFilledColor` | Color | n/a | `(0.3,0.7,1.0,1)` | Base fill color (blue by default). |
| `_TrackValueFilledRenderAlpha` | Range | 0–1 | `1` | See legend. |
| `_TrackValueFilledRenderEmissive` | Range | 0–1 | `0` | See legend. |
| `_TrackValueFilledPatternEnabled` | Float (guard) | n/a (`>0.5`) | `0` | Enables pattern on the filled segment. |
| `_TrackValueFilledPatternType` | Int `[Enum(PatternType)]` | 0–19 | `0` | §6.2. |
| `_TrackValueFilledPatternScale` | Range | 1–100 | `20` | Tiling frequency. |
| `_TrackValueFilledPatternIntensity` | Range | 0–1 | `0.3` | Strength. |
| `_TrackValueFilledPatternContrast` | Range | 0.1–5 | `1.5` | Contrast curve. |
| `_TrackValueFilledPatternParam1..3` | Range ×3 | 0–1 | `0.5` each | Detail / Distortion / Blend. |
| `_TrackValueFilledGradientEnabled` | Float (guard) | n/a (`>0.5`) | `0` | Enables a gradient across the filled segment. |
| `_TrackValueFilledGradientType` | Int `[Enum(GradientType)]` | 0–6 | `0` (Linear) | §6.6. |
| `_TrackValueFilledGradientColorA..D` | Color ×4 | n/a | blue ramp | Stops. |
| `_TrackValueFilledGradientDirection` | Vector4 | n/a | `(1,0,0,0)` | Linear/Triangle direction. |
| `_TrackValueFilledGradientSpeed` | Float | unbounded | `1.0` | Animation speed. |
| `_TrackValueFilledGradientScale` | Range | 0.1–5 | `1.0` | Frequency. |
| `_TrackValueFilledGradientOffset` | Range | -2–2 | `0.0` | Phase offset. |
| `_TrackValueFilledGlobalBlend` | Range | 0–1 | `0.0` | Cross-widget global gradient blend-in. |
| `_TrackValueFilledGlobalIntensity` | Range | 0–2 | `1.0` | Multiplier. |
| `_TrackValueFilledGradientColorUsed` | Int `[IntRange]` | 2–4 | `2` | Stops used. |
| `_TrackValueNegativeEnabled` | Float (guard) | n/a (`>0.5`) | `0` | Master switch — **off by default**; a bipolar slider (`_TrackValueZeroPoint > 0`) needs this turned on to show anything on the "below zero" side. |
| `_TrackValueNegativeColor` | Color | n/a | `(1.0,0.3,0.3,1)` | Base color (red by default). |
| `_TrackValueNegativeRenderAlpha` | Range | 0–1 | `1` | See legend. |
| `_TrackValueNegativeRenderEmissive` | Range | 0–1 | `0` | See legend. |
| `_TrackValueNegativePatternEnabled` | Float (guard) | n/a (`>0.5`) | `0` | Enables pattern. |
| `_TrackValueNegativePatternType` | Int `[Enum(PatternType)]` | 0–19 | `0` | §6.2. |
| `_TrackValueNegativePatternScale` | Range | 1–100 | `20` | Tiling frequency. |
| `_TrackValueNegativePatternIntensity` | Range | 0–1 | `0.3` | Strength. |
| `_TrackValueNegativePatternContrast` | Range | 0.1–5 | `1.5` | Contrast curve. |
| `_TrackValueNegativePatternParam1..3` | Range ×3 | 0–1 | `0.5` each | Detail / Distortion / Blend. |
| `_TrackValueNegativeGradientEnabled` | Float (guard) | n/a (`>0.5`) | `0` | Enables gradient. |
| `_TrackValueNegativeGradientType` | Int `[Enum(GradientType)]` | 0–6 | `0` (Linear) | §6.6. |
| `_TrackValueNegativeGradientColorA..D` | Color ×4 | n/a | red ramp | Stops. |
| `_TrackValueNegativeGradientDirection` | Vector4 | n/a | `(1,0,0,0)` | Direction. |
| `_TrackValueNegativeGradientSpeed` | Float | unbounded | `1.0` | Animation speed. |
| `_TrackValueNegativeGradientScale` | Range | 0.1–5 | `1.0` | Frequency. |
| `_TrackValueNegativeGradientOffset` | Range | -2–2 | `0.0` | Phase offset. |
| `_TrackValueNegativeGlobalBlend` | Range | 0–1 | `0.0` | Global gradient blend-in. |
| `_TrackValueNegativeGlobalIntensity` | Range | 0–2 | `1.0` | Multiplier. |
| `_TrackValueNegativeGradientColorUsed` | Int `[IntRange]` | 2–4 | `2` | Stops used. |

---

## 5. Section 5 — ValueUnfilled (`_TrackValueUnfilled*`)

The segment from the handle to the far end of the track (opposite the fill origin). Same simplified shape as ValueFilled.

| Name | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_TrackValueUnfilledEnabled` | Float (guard) | n/a (`>0.5`) | `0` | Master switch — **off by default**; without it, the "remaining" portion of the track just shows the plain Track color from section 4, not a distinct color. |
| `_TrackValueUnfilledColor` | Color | n/a | `(0.05,0.05,0.05,1)` | Base color. |
| `_TrackValueUnfilledRenderAlpha` | Range | 0–1 | `1` | See legend. |
| `_TrackValueUnfilledRenderEmissive` | Range | 0–1 | `0` | See legend. |
| `_TrackValueUnfilledPatternEnabled` | Float (guard) | n/a (`>0.5`) | `0` | Enables pattern. |
| `_TrackValueUnfilledPatternType` | Int `[Enum(PatternType)]` | 0–19 | `0` | §6.2. |
| `_TrackValueUnfilledPatternScale` | Range | 1–100 | `20` | Tiling frequency. |
| `_TrackValueUnfilledPatternIntensity` | Range | 0–1 | `0.3` | Strength. |
| `_TrackValueUnfilledPatternContrast` | Range | 0.1–5 | `1.5` | Contrast curve. |
| `_TrackValueUnfilledPatternParam1..3` | Range ×3 | 0–1 | `0.5` each | Detail / Distortion / Blend. |
| `_TrackValueUnfilledGradientEnabled` | Float (guard) | n/a (`>0.5`) | `0` | Enables gradient. |
| `_TrackValueUnfilledGradientType` | Int `[Enum(GradientType)]` | 0–6 | `0` (Linear) | §6.6. |
| `_TrackValueUnfilledGradientColorA..D` | Color ×4 | n/a | dark gray ramp | Stops. |
| `_TrackValueUnfilledGradientDirection` | Vector4 | n/a | `(1,0,0,0)` | Direction. |
| `_TrackValueUnfilledGradientSpeed` | Float | unbounded | `1.0` | Animation speed. |
| `_TrackValueUnfilledGradientScale` | Range | 0.1–5 | `1.0` | Frequency. |
| `_TrackValueUnfilledGradientOffset` | Range | -2–2 | `0.0` | Phase offset. |
| `_TrackValueUnfilledGlobalBlend` | Range | 0–1 | `0.0` | Global gradient blend-in. |
| `_TrackValueUnfilledGlobalIntensity` | Range | 0–2 | `1.0` | Multiplier. |
| `_TrackValueUnfilledGradientColorUsed` | Int `[IntRange]` | 2–4 | `2` | Stops used. |

---

## 6. Section 9 — Handle (`_Handle*`, thumb body)

Full material pipeline like Background. Shape uses `getHandleSDF` (see §6.7 for the full shape enum). In `SDFSliderRM.shader` this whole section is replaced by a raymarched 3D extrusion — the property *names* below are identical between both shaders, but their meaning changes (bevel becomes real 3D height, not a fake normal) and several ranges differ (noted in the "RM diff" column). See §11 for full RM-only additions.

| Name | Type | Range (base / **RM if different**) | Default | What it does |
|---|---|---|---|---|
| `_HandleEnabled` | Float (guard) | n/a (`>0.5`) | `1` | Master switch for the whole Handle thumb. |
| `_HandleColor` | Color | n/a | `(0.6,0.6,0.6,1)` | Base fill color. |
| `_HandleRenderAlpha` | Range | 0–1 | `1` | See legend. |
| `_HandleRenderEmissive` | Range | 0–1 | `0` | See legend. |
| `_HandleShapeType` | Int `[Enum(SliderHandleShapeType)]` | 0–9, 100 | `0` | Thumb shape. See §6.7. |
| `_HandleWidth` | Range | 0.01–2.0 | `0.15` | Handle half-width in equi-pixel space (also the axis half-extent used for travel clamping — see §4). |
| `_HandleHeight` | Range | 0.01–2.0 | `0.15` | Handle half-height in equi-pixel space. |
| `_HandlePadding` | Range | 0–0.5 | `0` | Extra margin subtracted from travel so the handle edge never touches the quad boundary. See §4. |
| `_HandleShapeParam1..3` | Range ×3 | 0–1 | `0.5` each | Shape-specific tuning — meaning depends on `_HandleShapeType`, documented per-case in §6.7. |
| `_HandleShapeRotation` | Range | -180–180 (degrees) | `0` | Rotates the handle's local shape space. |
| `_HandleRoundness` | Range | 0–1 | `0` | Global corner-radius reduction applied after shape dispatch (`d -= _HandleRoundness * minDim * 0.15`, `SDFSliderHandleShapes.cginc:233`) — same mechanism as `_PanelBodyRoundness`. |
| `_HandleShapeTexLayer` | Float | unbounded (-1 = none) | `-1` | Texture2DArray layer, used only when `_HandleShapeType = 100`. |
| `_HandleShapeTexScale` | Vector4 | n/a | `(1,1,0,0)` | UV scale for the Texture shape case. |
| `_HandleBevelEnabled` | Float (guard) | n/a (`>0.5`) | `1` | **On by default** (unlike every other layer's bevel) — the handle ships with a visible 3D-looking bevel out of the box. |
| `_HandleBevelDepth` | Range | base: **-1.0–1.0**; RM: **-4.0–4.0** | `0.3` | Signed bevel height/intensity. RM widens the range because `abs()` is taken internally and the bevel height is `handleMinDim * lerp(0.05, 1.0, abs(depth))` uncapped by `lerp` — larger magnitudes let a real 3D handle read as noticeably taller. |
| `_HandleBevelSmoothness` | Range | 0.001–1.0 | `0.02` | Dome roll-off softness (base shader) / fillet radius factor on the raymarched edge (RM: `filletRadius = bevelHeight * _HandleBevelSmoothness * 0.4`). |
| `_HandleBevelDistance` | Range | 0.001–1.0 | `0.1` | Bevel band width / RM wall run (horizontal extent of the 3D bevel slope). |
| `_HandleFaceSmoothness` | Range | -1.0–1.0 | `0.0` | Face dome/bowl curvature (base: fake normal perturbation; RM: literally perturbs the raymarched face normal radially, `SDFSliderRM.shader:2792-2802`). |
| `_HandleBevelProfileType` | Int (not `[Enum]`-tagged) | 0 or 1 | `0` | Dome (0) / Linear (1) — base shader only; RM computes its bevel geometrically and ignores this. |
| `_HandleBevelProfileSharpness` | Range | 0–1 | `0.5` | Linear-profile slope scale — base shader only. |
| `_HandleBevelPatternEnabled` | Float (guard) | n/a (`>0.5`) | `0` | Enables pattern on the bevel band/wall. |
| `_HandleBevelPatternType` | Int `[Enum(PatternType)]` | 0–19 | `0` | §6.2. |
| `_HandleBevelPatternScale` | Range | 1–100 | `20` | Tiling frequency. |
| `_HandleBevelPatternIntensity` | Range | 0–1 | `0.3` | Strength. |
| `_HandleBevelPatternContrast` | Range | 0.1–5 | `1.5` | Contrast curve. |
| `_HandleBevelPatternSpecularEffect` | Range | 0–2 | `1.0` | Specular modulation. |
| `_HandleBevelPatternRoughnessEffect` | Range | 0–2 | `0.3` | Normal perturbation. |
| `_HandleBevelPatternParam1..3` | Range ×3 | 0–1 | `0.5` each | Detail / Distortion / Blend. |
| `_HandleBevelPatternColorEnabled` | Float (guard) | n/a (`>0.5`) | `0` | Recolor bevel pattern via palette. |
| `_HandleBevelPatternColorType` | Int `[Enum(PatternColorType)]` | 0–3 | `2` (Zones) | §6.3. |
| `_HandleBevelPatternColorMode` | Int `[Enum(PatternColorMode)]` | 0–3 | `1` (Lerp) | §6.4. |
| `_HandleBevelPatternColorUsed` | Int `[IntRange]` | 2–4 | `2` | Stops used. |
| `_HandleBevelPatternColorA..D` | Color ×4 | n/a | white/0.5/0.3/0.1 gray ramp | Palette stops. |
| `_HandleBevelGradientEnabled` | Float (guard) | n/a (`>0.5`) | `0` | Enables gradient on the bevel wall. |
| `_HandleBevelGradientType` | Int `[Enum(GradientType)]` | 0–6 | `1` (Radial) | §6.6. In the RM shader, types `5` (BevelDepth) and `6` (BevelWalls) become fully meaningful here — they read the raymarched wall's surface normal (`SDFSliderRM.shader:2884-2893`). In the base shader these two values silently fall back to a flat `0.5` gradient position (see Gotchas). |
| `_HandleBevelGradientColorA..D` | Color ×4 | n/a | white/0.5/0.3/0.1 gray ramp | Stops. |
| `_HandleBevelGradientDirection` | Vector4 | n/a | `(1,0,0,0)` | Direction. |
| `_HandleBevelGradientSpeed` | Float | unbounded | `1.0` | Animation speed. |
| `_HandleBevelGradientScale` | Range | 0.1–5 | `1.0` | Frequency. |
| `_HandleBevelGradientOffset` | Range | -2–2 | `0.0` | Phase offset. |
| `_HandleBevelGradientColorUsed` | Int `[IntRange]` | 2–4 | `4` | Stops used. |
| `_HandleRimEnabled` | Float (guard) | n/a (`>0.5`) | `0` | Enables the rim highlight ring. |
| `_HandleRimDepth` | Range | -0.5–0.5 | `0.1` | Rim pseudo-height/direction. |
| `_HandleRimWidth` | Range | 0.001–1.0 | `0.02` | Rim band width. Also feeds `handleFaceInset` (§5). |
| `_HandleRimSmoothness` | Range | 0.001–0.1 | `0.01` | Rim AA/softness. |
| `_HandlePatternEnabled` | Float (guard) | n/a (`>0.5`) | `0` | Enables pattern on the flat face. |
| `_HandlePatternType` | Int `[Enum(PatternType)]` | 0–19 | `0` | §6.2. |
| `_HandlePatternScale` | Range | 1–100 | `20` | Tiling frequency. |
| `_HandlePatternIntensity` | Range | 0–1 | `0.3` | Strength. |
| `_HandlePatternContrast` | Range | 0.1–5 | `1.5` | Contrast curve. |
| `_HandlePatternSpecularEffect` | Range | 0–2 | `1.0` | Specular modulation. |
| `_HandlePatternRoughnessEffect` | Range | 0–2 | `0.3` | Normal perturbation. |
| `_HandlePatternRotateEnabled` | Float (guard) | n/a (`>0.5`) | `0` | Rotates pattern sample space. |
| `_HandlePatternModEnabled` | Float (guard) | n/a (`>0.5`) | `0` | Enables angular mod warp. |
| `_HandlePatternModAmount` | Range | 0–90 (degrees) | `20` | Mod warp amount. |
| `_HandlePatternModFrequency` | Range | 0.1–10 | `1` | Mod warp frequency. |
| `_HandlePatternOffset` | Range | -180–180 (degrees) | `0` | Static rotation offset. |
| `_HandlePatternParam1..3` | Range ×3 | 0–1 | `0.5` each | Detail / Distortion / Blend. |
| `_HandlePatternColorEnabled` | Float (guard) | n/a (`>0.5`) | `0` | Recolor pattern via palette. |
| `_HandlePatternColorType` | Int `[Enum(PatternColorType)]` | 0–3 | `2` (Zones) | §6.3. |
| `_HandlePatternColorMode` | Int `[Enum(PatternColorMode)]` | 0–3 | `1` (Lerp) | §6.4. |
| `_HandlePatternColorUsed` | Int `[IntRange]` | 2–4 | `2` | Stops used. |
| `_HandlePatternColorA..D` | Color ×4 | n/a | white/0.5/0.3/0.1 gray ramp | Palette stops. |
| `_HandleGradientEnabled` | Float (guard) | n/a (`>0.5`) | `0` | Enables gradient on the base color. |
| `_HandleGradientType` | Int `[Enum(GradientType)]` | 0–6 | `0` (Linear) | §6.6. Sampled in handle-local UV space (`handleUV`), not screen UV, so it's oriented to the handle regardless of where it sits on the track. |
| `_HandleGradientColorA..D` | Color ×4 | n/a | light gray ramp | Stops. |
| `_HandleGradientDirection` | Vector4 | n/a | `(0,1,0,0)` | Direction (vertical default). |
| `_HandleGradientSpeed` | Float | unbounded | `1.0` | Animation speed. |
| `_HandleGradientScale` | Range | 0.1–5 | `1.0` | Frequency. |
| `_HandleGradientOffset` | Range | -2–2 | `0.0` | Phase offset. |
| `_HandleGlobalBlend` | Range | 0–1 | `0.0` | Cross-widget global gradient blend-in. |
| `_HandleGlobalIntensity` | Range | 0–2 | `1.0` | Multiplier. |
| `_HandleGradientColorUsed` | Int `[IntRange]` | 2–4 | `4` | Stops used. |

---

## 7. Section 10 — HandleFace (`_HandleFace*`)

An optional smaller inset shape drawn on top of the handle (e.g. a screw head, cap detail). Has pattern + gradient but **no bevel, no rim** — it's a flat painted decal, not a 3D layer.

| Name | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_HandleFaceEnabled` | Float (guard) | n/a (`>0.5`) | `0` | Master switch for the whole HandleFace layer. |
| `_HandleFaceShapeEnabled` | Float (guard) | n/a (`>0.5`) | `0` | If `0`, the face reuses the Handle's own shape type + params (just shrunk by `_HandleFaceSize`). If `1`, it uses its own independent shape type/params/rotation below. |
| `_HandleFaceShapeType` | Int `[Enum(SliderHandleShapeType)]` | 0–9, 100 | `0` | Only read when `_HandleFaceShapeEnabled=1`. Same enum as `_HandleShapeType`, §6.7. |
| `_HandleFaceShapeParam1..3` | Range ×3 | 0–1 | `0.5` each | Only read when `_HandleFaceShapeEnabled=1`. |
| `_HandleFaceShapeRotation` | Range | -180–180 (degrees) | `0` | Only read when `_HandleFaceShapeEnabled=1`. |
| `_HandleFaceSize` | Range | 0.01–1.0 | `0.6` | Fraction of the handle's min half-extent the face shape occupies (`faceMargin = (1 - size) * min(width,height)`). `1.0` ≈ same size as the handle; small values shrink it toward the center. |
| `_HandleFaceColor` | Color | n/a | `(0.3,0.3,0.3,1)` | Base color. |
| `_HandleFaceRenderAlpha` | Range | 0–1 | `1` | See legend. |
| `_HandleFaceRenderEmissive` | Range | 0–1 | `0` | See legend. |
| `_HandleFacePatternEnabled` | Float (guard) | n/a (`>0.5`) | `0` | Enables pattern. |
| `_HandleFacePatternType` | Int `[Enum(PatternType)]` | 0–19 | `0` | §6.2. |
| `_HandleFacePatternScale` | Range | 1–100 | `20` | Tiling frequency. |
| `_HandleFacePatternIntensity` | Range | 0–1 | `0.3` | Strength. |
| `_HandleFacePatternContrast` | Range | 0.1–5 | `1.5` | Contrast curve. |
| `_HandleFacePatternParam1..3` | Range ×3 | 0–1 | `0.5` each | Detail / Distortion / Blend. |
| `_HandleFaceGradientEnabled` | Float (guard) | n/a (`>0.5`) | `0` | Enables gradient. |
| `_HandleFaceGradientType` | Int `[Enum(GradientType)]` | 0–6 | `0` (Linear) | §6.6. |
| `_HandleFaceGradientColorA..D` | Color ×4 | n/a | dark gray ramp | Stops. |
| `_HandleFaceGradientDirection` | Vector4 | n/a | `(0,1,0,0)` | Direction (vertical default). |
| `_HandleFaceGradientScale` | Range | 0.1–5 | `1.0` | Frequency. |
| `_HandleFaceGradientOffset` | Range | -2–2 | `0.0` | Phase offset. |
| `_HandleFaceGlobalBlend` | Range | 0–1 | `0.0` | Global gradient blend-in. |
| `_HandleFaceGlobalIntensity` | Range | 0–2 | `1.0` | Multiplier. |
| `_HandleFaceGradientColorUsed` | Int `[IntRange]` | 2–4 | `2` | Stops used. |

Note: unlike every other Gradient block in this shader, `_HandleFaceGradient*` has **no `Speed` property** — animation speed isn't exposed for the face gradient (confirmed absent from both the Properties block and the `CalculateGradient` call, which passes a literal `1.0`).

---

## 8. Section 7 — ScaleMarks (`_ScaleMark*`)

Tick marks drawn along the slider axis. Simplest layer in the shader: flat color + optional 2-stop gradient only, **no pattern, no bevel**.

| Name | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_ScaleMarkEnabled` | Float (guard) | n/a (`>0.5`) | `0` | Master switch. |
| `_ScaleMarkColor` | Color | n/a | `(0.5,0.5,0.5,1)` | Base color. |
| `_ScaleMarkRenderAlpha` | Range | 0–1 | `1` | See legend. |
| `_ScaleMarkRenderEmissive` | Range | 0–1 | `0` | See legend. |
| `_ScaleMarkCount` | Range | 2–32 | `5` | Number of ticks, **including both end ticks** (evenly spaced from `-trackAxisHalf` to `+trackAxisHalf`; `t = mi/(count-1)`). |
| `_ScaleMarkWidth` | Range | 0.001–0.1 | `0.01` | Tick half-thickness along the slider axis. |
| `_ScaleMarkLength` | Range | 0.01–0.5 | `0.05` | Tick half-length perpendicular to the axis. |
| `_ScaleMarkOffset` | Range | 0–0.5 | `0.08` | Perpendicular distance of the tick row's centerline from the track centerline. |
| `_ScaleMarkSoftness` | Range | 0–0.05 | `0.005` | AA softness floor (`max(softness, fwidth(dist)*0.75)`). |
| `_ScaleMarkGradientEnabled` | Float (guard) | n/a (`>0.5`) | `0` | Enables a 2-stop gradient across all ticks (one shared gradient sample, not per-tick). |
| `_ScaleMarkGradientType` | Int `[Enum(GradientType)]` | 0–6 | `0` (Linear) | §6.6. |
| `_ScaleMarkGradientColorA`, `_ScaleMarkGradientColorB` | Color ×2 | n/a | `(0.7,0.7,0.7,1)`, `(0.3,0.3,0.3,1)` | Only 2 stops exist for ScaleMarks — no C/D, and `CalculateGradient` is called with the stop-count hardcoded to `2` (`SDFSlider.shader:1208`). |
| `_ScaleMarkGradientDirection` | Vector4 | n/a | `(1,0,0,0)` | Direction. |
| `_ScaleMarkGradientScale` | Range | 0.1–5 | `1.0` | Frequency. |
| `_ScaleMarkGradientOffset` | Range | -2–2 | `0.0` | Phase offset. |

`_ScaleMarkGradientSpeed` does not exist either — animation speed is hardcoded to `1.0` in the call site.

Ticks span `trackAxisHalf` — i.e. the track's own length (`handleHalfTravel + _TrackExtension`), **not** the quad's full half-length. They automatically move if `_HandleWidth`/`_HandlePadding`/`_TrackExtension` change.

---

## 9. Section 1 — Edge (`_Edge*`)

A soft recessed-indent glow hugging the *Background* shape's silhouette, drawn first (before the background itself is painted). No pattern, no bevel — just a distance-falloff intensity curve.

| Name | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_EdgeEnabled` | Float (guard) | n/a (`>0.5`) | `0` | Master switch. |
| `_EdgeColor` | Color | n/a | `(0,0,0,0.5)` | Base color (default: semi-transparent black, i.e. a soft inner shadow). |
| `_EdgeRenderAlpha` | Range | 0–1 | `1` | See legend. |
| `_EdgeRenderEmissive` | Range | 0–1 | `0` | See legend. |
| `_EdgeWidth` | Range | 0.001–1.0 | `0.1` | How far inward from the Background shape's edge the falloff extends. |
| `_EdgeSoftness` | Range | 0–1 | `0.3` | `0` = hard `smoothstep` cutoff at `_EdgeWidth`; `>0` = a `pow()`-curved gradient instead (`SDFSliderLayers.cginc:65-70`), and the falloff curve is always finished with `sin(gradient * PI/2)` easing regardless. |
| `_EdgeIntensity` | Range | 0–2 | `0.5` | Multiplies the resulting mask before compositing — values `>1` let the edge alpha exceed the natural [0,1] falloff, punching it more solid near the border. |
| `_EdgeInset` | Range | 0.0–0.5 | `0.0` | Extra inward offset added to the distance test (`distToGeometry = max(0, bodyDist + edgeInset)`) — shifts the whole indent band inward from the shape edge before the width falloff starts. |
| `_EdgeGradientEnabled` | Float (guard) | n/a (`>0.5`) | `0` | Enables gradient recoloring of the edge. |
| `_EdgeGradientType` | Int `[Enum(GradientType)]` | 0–6 | `0` (Linear) | §6.6. |
| `_EdgeGradientColorA..D` | Color ×4 | n/a | black/dark ramp | Stops. |
| `_EdgeGradientDirection` | Vector4 | n/a | `(0,1,0,0)` | Direction. |
| `_EdgeGradientSpeed` | Float | unbounded | `1.0` | Animation speed. |
| `_EdgeGradientScale` | Range | 0.1–5 | `1.0` | Frequency. |
| `_EdgeGradientOffset` | Range | -2–2 | `0.0` | Phase offset. |
| `_EdgeGlobalBlend` | Range | 0–1 | `0.0` | Global gradient blend-in. |
| `_EdgeGlobalIntensity` | Range | 0–2 | `1.0` | Multiplier. |
| `_EdgeGradientColorUsed` | Int `[IntRange]` | 2–4 | `2` | Stops used. |

Edge geometry always follows the **Background** shape (`_BgShapeType`/params), even if `_BgEnabled=0` — it is computed independently of whether the Background layer itself is drawn.

---

## 10. Section 11 — Border (`_Border*`)

A ring hugging the Background shape's silhouette from the *outside* of the fill inward, meant to read as a "cut-in" line at the canvas edge. No pattern, no bevel — gradient only.

| Name | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_BorderEnabled` | Float (guard) | n/a (`>0.5`) | `0` | Master switch. |
| `_BorderColor` | Color | n/a | `(1,1,1,1)` | Base color. |
| `_BorderRenderAlpha` | Range | 0–1 | `1` | See legend. |
| `_BorderRenderEmissive` | Range | 0–1 | `0` | See legend. |
| `_BorderWidth` | Range | 0.001–0.5 | `0.02` | Ring thickness, measured inward from the Background shape's edge. |
| `_BorderSoftness` | Range | 0–0.5 | `0.01` | AA softness added to the outer edge of the ring. |
| `_BorderIntensity` | Range | 0–2 | `1.0` | Multiplies the computed border mask before compositing. |
| `_BorderGradientEnabled` | Float (guard) | n/a (`>0.5`) | `0` | Enables gradient recoloring. |
| `_BorderGradientType` | Int `[Enum(GradientType)]` | 0–6 | `0` (Linear) | §6.6. |
| `_BorderGradientColorA..D` | Color ×4 | n/a | white-to-gray ramp | Stops. |
| `_BorderGradientDirection` | Vector4 | n/a | `(0,1,0,0)` | Direction. |
| `_BorderGradientSpeed` | Float | unbounded | `1.0` | Animation speed. |
| `_BorderGradientScale` | Range | 0.1–5 | `1.0` | Frequency. |
| `_BorderGradientOffset` | Range | -2–2 | `0.0` | Phase offset. |
| `_BorderGlobalBlend` | Range | 0–1 | `0.0` | Global gradient blend-in. |
| `_BorderGlobalIntensity` | Range | 0–2 | `1.0` | Multiplier. |
| `_BorderGradientColorUsed` | Int `[IntRange]` | 2–4 | `2` | Stops used. |

Border geometry also always follows the **Background** shape, and — see §12 — it explicitly avoids painting over wherever the Handle currently sits, even where the Handle overlaps the border ring.

---

## 11. Sections 2 & 8 — Shadows (`_LightingShadow1-3*`, `_HandleShadow1-3*`)

**These render only on the auxiliary shadow quad** (`_ShadowPassMode>0.5`), driven by `WidgetShadowQuad.cs` — not in the normal widget-quad pass. See §13 "Shadows only render on the shadow quad."

There are two independent trios:

**External shadows** (`_LightingShadow1/2/3`) — a drop-shadow cast by the **Background** shape's silhouette onto whatever is behind the widget, one per scene light.

| Name (×1/2/3) | Type | Range | Default (1 / 2 / 3) | What it does |
|---|---|---|---|---|
| `_LightingShadowNEnabled` | Float (guard) | n/a (`>0.5`) | `0 / 0 / 0` | Master switch for that light's shadow. All 3 off by default. |
| `_LightingShadowNColor` | Color | n/a | `(0,0,0,0.5) / (0,0,0,0.3) / (0,0,0,0.2)` | Shadow color/opacity — darker and more opaque for shadow 1, progressively lighter for 2/3 (a soft stacked-shadow look). |
| `_LightingShadowNBlur` | Range | 0–2 | `0.5 / 0.8 / 1.0` | Edge blur amount. |
| `_LightingShadowNDistance` | Range | 0–0.5 | `0.02 / 0.05 / 0.08` | Offset distance along the light direction. |
| `_LightingShadowNBlurFactor` | Range | 0–2 | `0.5` (all) | Directional blur bias (shadow edge facing away from the light blurs more). |
| `_LightingShadowNIntensity` | Range | 0–2 | `1.0` (all) | Opacity multiplier on top of `Color.a`. |

**Handle body shadows** (`_HandleShadow1/2/3`) — a shadow cast by the **Handle** thumb specifically, with an extra "Cast" control the external shadows don't have.

| Name (×1/2/3) | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_HandleShadowNEnabled` | Float (guard) | n/a (`>0.5`) | `0` (all) | Master switch. |
| `_HandleShadowNColor` | Color | n/a | `(0,0,0,0.6) / (0,0,0,0.4) / (0,0,0,0.3)` | Shadow color/opacity. |
| `_HandleShadowNBlur` | Range | 0–2 | `0.3 / 0.5 / 0.7` | Edge blur. |
| `_HandleShadowNDistance` | Range | 0–0.5 | `0.01 / 0.02 / 0.03` | Offset distance along light direction. |
| `_HandleShadowNBlurFactor` | Range | 0–2 | `0.3` (all) | Directional blur bias. |
| `_HandleShadowNIntensity` | Range | 0–2 | `1.0` (all) | Opacity multiplier. |
| `_HandleShadowNCast` | Range | 0–1 | `0.5` (all) | Extra parameter absent from external shadows: blends in a "hull sweep" — the shadow silhouette bulges to reflect the handle's own pseudo-3D bevel height, instead of just being a flat offset copy of the handle's 2D outline. `0` = flat silhouette shadow only. |

---

## 12. Lighting

| Name | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_LightingAmbient` | Range | 0–1 | `0.5` | Ambient light floor applied in `ApplyUILighting` to every lit layer (Background, Track, Handle). The 3 directional lights themselves (`_GlobalLightPos1-3`, `_GlobalLightColor1-3`, `_GlobalLightFx1-3`) are shared globals from `UIGlobalUniforms.cginc`, set once per scene, not per-widget skin properties. |

---

## 13. RM-only additions (`SDFSliderRM.shader`)

Everything in §1–12 above exists identically (same names, same defaults) in both shaders **except** the differences called out inline (`_HandleBevelDepth` range, `_HandleBevelProfileType`/`Sharpness` being ignored, `_BgRimWidth` default `0.022` vs `0.02` in the base — cosmetically negligible). The RM shader additionally defines:

### 13.1 New "Track Value" bevel block (not present in base `SDFSlider.shader` at all)

| Name | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_TrackValueBevelEnabled` | Float (guard) | n/a (`>0.5`) | `0` | Enables a real 3D bevel step on the ValueFilled/Unfilled/Negative fill surface (RM only) — the fill sits at its own elevation above the track face rather than being flush-painted onto it. |
| `_TrackValueBevelDepth` | Range | -1.0–1.0 | `0.1` | Signed fill-layer height above/below the track face. |
| `_TrackValueBevelSmoothness` | Range | 0.001–1.0 | `0.02` | Edge softness. |
| `_TrackValueBevelDistance` | Range | 0.001–1.0 | `0.08` | Bevel wall run. |
| `_TrackValueFaceSmoothness` | Range | -1.0–1.0 | `0.0` | Fill-face dome/bowl curvature. |

### 13.2 View / camera block

| Name | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_HandleLipHeight` | Range | 0–0.5 | `0.05` | Extra vertical "lip" step below the bevel wall, as a fraction of `handleMinDim` — gives the handle a small flat rim before the bevel slope starts (`handleTotalHeight = lipHeight + bevelHeight`). |
| `_ViewTilt` | Range | 0–10 | `2` | Authored (static) camera tilt magnitude for this widget. Combined with the scene camera term via `UI_VIEW_TILT = max(0, _ViewTilt + UI_VIEW_CAM_TILT)` (`UIViewCamera.cginc:56`) — **never referenced directly** in the fragment shader, always through this macro. |
| `_ViewAngle` | Range | -180–180 (degrees) | `0` | Compass direction of the tilt. Internally offset by +90° for vertical sliders so tilt/shift always map onto world Y/X consistently regardless of orientation (`SDFSliderRM.shader:1016`). |
| `_ViewFOV` | Range | 0–1 | `0` | `0` = orthographic raymarch camera; `>0` = perspective, with `focalDist = 1/tan(FOV * π/2)`. |
| `_ViewShift` | Range | -5–5 | `0` | Authored (static) horizontal parallax shift. Combined with the scene camera via `UI_VIEW_SHIFT = _ViewShift + UI_VIEW_CAM_SHIFT` (`UIViewCamera.cginc:55`). |
| `_ViewCamEnabled` | Float (guard) | n/a (`>0.5`) | `1` | Opts this material into the shared scene-camera parallax term (`_GlobalViewCam`, one eye point published per screen). `0` = ignore the camera entirely and use only the authored `_ViewShift`/`_ViewTilt`. |
| `_ViewCamShift` | Range | 0–5 | `0.6` | Bound: the *most* the scene camera may add to/subtract from `_ViewShift` for this material. |
| `_ViewCamTilt` | Range | 0–10 | `0.8` | Bound: the most the scene camera may add to/subtract from `_ViewTilt`. |
| `_BgViewTiltEnabled` | Float (guard) | n/a (`>0.5`) | `0` | Whether the Background layer participates in the view tilt at all (`bgCosT = lerp(1, cosT, applied)`). Off by default — background stays flat/untilted. |
| `_BgViewShiftEnabled` | Float (guard) | n/a (`>0.5`) | `0` | Whether the Background layer participates in the view shift/parallax. |
| `_TrackViewTiltEnabled` | Float (guard) | n/a (`>0.5`) | `1` | Whether the Track participates in view tilt. **On by default** (background is off by default, track is on — the track/handle read as 3D while the backing panel stays flat, by design). |
| `_TrackViewShiftEnabled` | Float (guard) | n/a (`>0.5`) | `0` | Whether the Track participates in view shift. |
| `_ViewValueShiftEnabled` | Float (guard) | n/a (`>0.5`) | `0` | Enables a `_Value`-driven lerp added on top of the static shift (`lerp(_ViewValueShiftMin, _ViewValueShiftMax, _Value)`) — e.g. the view subtly shifts as the slider moves. |
| `_ViewValueShiftMin` / `_ViewValueShiftMax` | Range ×2 | -5–5 | `0` / `0` | Endpoints of the value-driven shift lerp. |
| `_ViewValueTiltEnabled` | Float (guard) | n/a (`>0.5`) | `0` | Enables a `_Value`-driven lerp added on top of the static tilt. |
| `_ViewValueTiltMin` / `_ViewValueTiltMax` | Range ×2 | -10–10 | `0` / `0` | Endpoints of the value-driven tilt lerp. |
| `_ViewValueAspectEnabled` | Float (guard) | n/a (`>0.5`) | `0` | When both Value-Shift and Value-Tilt are enabled, gates which one actually applies based on orientation: wide (horizontal) sliders get only the value-shift, tall (vertical) sliders get only the value-tilt (`SDFSliderRM.shader:1027-1028`). When `0`, both apply regardless of orientation. |
| `_TrackViewElevation` | Float | unbounded | `0` | Manual additional elevation offset for the track face stack (added on top of the automatic bg/bevel-derived elevation). |
| `_HandleViewElevation` | Float | unbounded | `0` | Manual additional elevation offset for the handle, added on top of `handleFloor` (the automatically computed "stacked on bg → track → fill" resting height, see `SDFSliderRM.shader:2606-2621`). |

---

## 14. Enum reference — every integer value, read from the dispatch code

### 6.1 `_BgShapeType` — `PanelBodyShapeType` (dispatched in `getPanelBodySDF`, `SDFPanelShapes.cginc:93`)

| Value | Name | Code | What it draws |
|---|---|---|---|
| `0` | Squircle | `case 0:` (`SDFPanelShapes.cginc:95`) | `RoundedRectSDF` with radius `minDim*(1-saturate(param1))`; param1=0 → full pill, param1=1 → sharp rectangle. If `_PanelCornerRadiusPx>0.5` and the widget's real pixel size is known, the radius is instead a fixed on-screen pixel radius (`SDFPanelShapes.cginc:100-104`), clamped to the pill limit. |
| `1` | Polygircle | `case 1:` (`SDFPanelShapes.cginc:108`) | `param1<0.001` → perfect circle. Otherwise an n-gon, `sides = clamp(round(3 + param1*9), 3, 12)`; param2 = corner rounding. |
| `2` | Tab | `case 2:` (`SDFPanelShapes.cginc:128`) | `PanelTabShapeSDF`: rounded top half (radius = param1), flat rectangular bottom half. |
| `3` | Hexagon | `case 3:` (`SDFPanelShapes.cginc:133`) | Flat-top hexagon, stretches with the shape's half-extents; param1 = edge rounding. |
| `4` | Octagon | `case 4:` (`SDFPanelShapes.cginc:139`) | Rectangle with 45°-chamfered corners; param1 = corner-cut fraction. |
| `100` | Texture | `case 100:` (`SDFPanelShapes.cginc:144`) | SDF sampled from a `Texture2DArray` layer (`_PanelBodyShapeTexLayer`/`_PanelBodyShapeTexScale`). |
| other | default | `default:` (`SDFPanelShapes.cginc:152`) | Same as Squircle. |

Same enum and dispatcher power the Handle's own body shape's *background-equivalent* — no, Background only. (Handle uses a separate enum, §6.7.)

### 6.2 `_XxxPatternType` — `PatternType` (procedural surface materials, `UIPatterns.cginc:25-54`)

| Value | Name | Value | Name |
|---|---|---|---|
| `0` | Plastic | `10` | Frosted |
| `1` | Metal | `11` | DiamondPlate |
| `2` | RadialBrushed | `12` | Knurled |
| `3` | CarbonFiber | `13` | HexGrid |
| `4` | Leather | `14` | Perforated |
| `5` | BrushedCross | `15` | WoodGrain |
| `6` | Satin | `16` | Marble |
| `7` | Concrete | `17` | Ceramic |
| `8` | Fabric | `18` | Circuit |
| `9` | Paper | `19` | NoiseOrganic |

Applies identically to every `_XxxPatternType` property in the shader (Bg, BgBevel, Track, TrackValueFilled/Unfilled/Negative, Handle, HandleBevel, HandleFace).

### 6.3 `_XxxPatternColorType` — `PatternColorType` (`SamplePatternColorPosition`, `UIPatterns.cginc:774-793`)

| Value | Name | Code | What it does |
|---|---|---|---|
| `0` | Gradient | `if (colorType == PATTERN_COLORTYPE_1)` → `UIPatterns.cginc:776-780` | Treats the pattern's signed `[-1,+1]` value as a linear position: `saturate((v+1)*0.5)`. Negative pattern values read as palette stop A, zero as the midpoint, positive as D. |
| `1` | Feature | `if (colorType == PATTERN_COLORTYPE_2)` → `UIPatterns.cginc:781-785` | Uses `saturate(abs(v))` — flat/featureless surface areas sit at A, strong features (peaks/valleys either direction) push toward D. |
| `2` | Zones | `if (colorType == PATTERN_COLORTYPE_3)` → `UIPatterns.cginc:786-790` | `frac(abs(v) * 2.718281828)` — wraps repeatedly, producing visually distinct, irregular color zones per feature instance rather than a smooth ramp. |
| `3` | Bands | *(falls through to the final `return`)* → `UIPatterns.cginc:791-792` | `abs(sin(v * π))` — sine-wave banding; produces ring/vein/layered coloring. |

### 6.4 `_XxxPatternColorMode` — `PatternColorMode` (`ApplyMaterialPattern`, `UIPatterns.cginc:881-897`)

| Value | Name | Code | What it does |
|---|---|---|---|
| `0` | Modulate | `if (blendMode == 0)` → `UIPatterns.cginc:882-885` | `return patternColor * (1.0 + pattern)` — the palette color's own brightness is modulated by pattern strength; the original base color is discarded entirely wherever the pattern layer is active. |
| `1` | Lerp | `else if (blendMode == 1)` → `UIPatterns.cginc:886-889` | `lerp(baseColor, patternColor, saturate(abs(pattern)))` — base color blends toward the palette color at strong features. |
| `2` | Additive | `else if (blendMode == 2)` → `UIPatterns.cginc:890-893` | `baseColor + patternColor * saturate(pattern)` — palette color is added on top at strong *positive* features only (can push over 1.0/blow out highlights). |
| `3` | Multiply | `else` → `UIPatterns.cginc:894-897` | `baseColor * lerp(1, patternColor, saturate(abs(pattern)))` — palette color tints/darkens the base color multiplicatively; never brightens beyond the base. |

### 6.5 `_BgBevelProfileType` / `_HandleBevelProfileType` — `BevelProfileType` (`CalculateShapeBevelNormal`, `UILighting.cginc:616-633`)

Note: unlike every other enum property in this shader, these two are declared as plain `Int` in the Properties block — **no `[Enum(...)]` tag**, so the Unity Inspector shows a raw number field, not a dropdown. The legal values are still exactly these two:

| Value | Name | Code | What it does |
|---|---|---|---|
| `0` | Dome | `else { ... }` (the non-Linear branch) → `UILighting.cginc:630-633` | `bevelFactor = smoothstep(dist, dist - smoothness, abs(sdf))` — a smooth S-curve roll-off from edge to flat face. This is the default and matches every other widget's bevel look. |
| `1` | Linear | `if (profileType == 1)` → `UILighting.cginc:626-629` | `t = saturate((dist - abs(sdf)) / dist); bevelFactor = t * profileSharpness` — a constant-slope angled shelf instead of a curve; full intensity right at the edge, linearly down to 0 at `bevelDistance` inward, scaled by `profileSharpness`. |

### 6.6 `_XxxGradientType` — `GradientType` (`GetGradientPosition`, `UIGradients.cginc:94-112`)

| Value | Name | Code | What it does |
|---|---|---|---|
| `0` | Linear | `case GRADIENT_LINEAR:` → `UIGradients.cginc:99-100` | `dot(uv, normalize(direction)) * scale + time*speed*0.1 + offset` — straight-line gradient along `Direction`. |
| `1` | Radial | `case GRADIENT_RADIAL:` → `UIGradients.cginc:101-102` | `length(uv-0.5) * 2 * scale + ...` — radiates outward from the UV center. |
| `2` | Angular | `case GRADIENT_ANGULAR:` → `UIGradients.cginc:103-104` | `atan2(...)`-based — sweeps around the UV center like a clock hand. |
| `3` | Diamond | `case GRADIENT_DIAMOND:` → `UIGradients.cginc:105-106` | Taxicab (`|dx|+|dy|`) distance from center — diamond-shaped isolines. |
| `4` | Triangle | `case GRADIENT_TRIANGLE:` → `UIGradients.cginc:107-108` | Same as Linear but passed through a triangle wave (`TriangleWave`), producing a repeating back-and-forth ramp instead of a single pass. |
| `5` | BevelDepth (RM-wall-only) | *(falls to `default:` in `GetGradientPosition`)* → `UIGradients.cginc:109-110` | Only meaningful for a `*BevelGradient*` property evaluated on `SURFACE_WALL` of an RM shader's raymarched hit (linear outer→groove ramp driven by the surface normal). Everywhere else (any non-bevel Gradient slot, or any Gradient slot in the non-RM `SDFSlider.shader`), this value hits the `default:` case and returns a **fixed position of `0.5`** — i.e. it renders as a flat, static color pick from the middle of the palette, not a functioning gradient. |
| `6` | BevelWalls (RM-wall-only) | *(same `default:` fallback outside its intended RM context)* → `UIGradients.cginc:109-110` | Zone-based variant of the above (outer wall / side-out / side-in / groove-back), same RM-wall-only caveat. |

### 6.7 `_HandleShapeType` / `_HandleFaceShapeType` — `SliderHandleShapeType` (dispatched in `getHandleSDF`, `SDFSliderHandleShapes.cginc:162`)

| Value | Name | Code | What it draws |
|---|---|---|---|
| `0` | Capsule | `case 0:` (`SDFSliderHandleShapes.cginc:164-169`) | `RoundedRectSDF` with `r = minDim*(1-saturate(param1))` — param1=0 gives a full pill/capsule, param1=1 a sharp rectangle. (Identical formula to Squircle case 2 below — same math, different name for authoring clarity.) `param2`/`param3` unused. |
| `1` | Circle | `case 1:` (`SDFSliderHandleShapes.cginc:170-174`) | `CircleSDF(p, minDim)` — perfect circle/puck using the smaller of width/height as radius. All params unused. |
| `2` | FlatRect | `case 2:` (`SDFSliderHandleShapes.cginc:175-180`) | `RoundedRectSDF` with `r = minDim*saturate(param1)*0.5` — param1=0 sharp rectangle, param1=1 half-rounded. `param2`/`param3` unused. |
| `3` | OvalPointer | `case 3:` (`SDFSliderHandleShapes.cginc:181-185`, body in `HandleOvalPointerSDF` lines 40-55) | Rounded-rect body with a small downward triangular pointer nub. `param1` = pointer height (0–1, `lerp(0, 0.38*halfH)`), `param2` = pointer width (0–1, `lerp(0.2, 0.85)*halfW`). `param3` unused. |
| `4` | WingFader | `case 4:` (`SDFSliderHandleShapes.cginc:186-190`, body in `HandleWingFaderSDF` lines 58-75) | Wide rect with two symmetric recessed grip grooves on the long edges. `param1` = groove depth, `param2` = groove x-position/width, `param3` = corner roundness. |
| `5` | ArrowHandle | `case 5:` (`SDFSliderHandleShapes.cginc:191-195`, body in `HandleArrowSDF` lines 78-98) | Pill body with a triangular pointer at the top. `param1` = arrow height, `param2` = arrow width, `param3` = corner roundness. |
| `6` | FaderCap | `case 6:` (`SDFSliderHandleShapes.cginc:196-200`, body in `HandleFaderCapSDF` lines 102-116) | Rounded-rect with an optional central horizontal groove. `param1` = width squeeze (0=narrow, 1=full), `param2` = groove depth, `param3` = corner rounding. |
| `7` | FaderCapWide | `case 7:` (`SDFSliderHandleShapes.cginc:201-205`, body in `HandleFaderCapWideSDF` lines 120-135) | Wide rounded-rect with two screw/rivet holes. `param1` = height fraction, `param2` = screw hole radius, `param3` = corner rounding. |
| `8` | DShaft | `case 8:` (`SDFSliderHandleShapes.cginc:206-210`, body in `HandleDShaftSDF` lines 138-145) | Oval with a flat horizontal cut on the bottom edge. `param1` = cut depth, `param2` = oval rounding. `param3` unused. |
| `9` | Squircle | `case 9:` (`SDFSliderHandleShapes.cginc:211-216`) | Same formula as Capsule (case 0) — `r = minDim*(1-saturate(param1))`. Kept as a separate enum entry for authoring semantics even though the underlying math is identical to Capsule in the current implementation. |
| `100` | Texture | `case 100:` (`SDFSliderHandleShapes.cginc:217-224`) | SDF sampled from a `Texture2DArray` layer (`_HandleShapeTexLayer`/`_HandleShapeTexScale`, or the per-call override args used by `_HandleFaceShapeType`). |
| other | default | `default:` (`SDFSliderHandleShapes.cginc:225-230`) | Same as Capsule/Squircle. |

`_HandleFaceShapeType` shares this exact same enum and dispatcher (`getHandleSDF` is called directly with the Face's own params when `_HandleFaceShapeEnabled=1`).

---

## 15. The `_XxxEnabled` guard list — every section-enable float and what turns off at 0

| Guard | Section | At `0` (i.e. `<0.5`)... |
|---|---|---|
| `_BgEnabled` | 3 Background | The entire Background body block is skipped (`SDFSlider.shader:909`) — no shape, bevel, rim, pattern, gradient, or lighting for it. Edge indent (§9) still uses the Background's *shape* for its own geometry test regardless of this flag. |
| `_BgBevelEnabled` | 3 Background bevel | `bgEffBevelDepth` forced to `0` — flat, unbeveled face; `bgBevelDist`/`bgBevelDepthRaw` (feeding the pseudo-height used by external shadows) also collapse toward their minimums. |
| `_BgBevelPatternEnabled` | 3 Background bevel pattern | Bevel band renders as a plain lit surface, no procedural material. |
| `_BgBevelPatternColorEnabled` | 3 Background bevel pattern color | Pattern uses plain brightness modulation instead of the 4-stop palette. |
| `_BgBevelGradientEnabled` | 3 Background bevel gradient | No gradient overlay on the bevel wall. |
| `_BgRimEnabled` | 3 Background rim | No rim highlight ring; `bgRimWidth` forced to `0`, shrinking `bgFaceInset`. |
| `_BgPatternEnabled` | 3 Background face pattern | Face renders as flat base/gradient color, no procedural material. |
| `_BgPatternColorEnabled` | 3 Background face pattern color | Pattern uses plain brightness modulation. |
| `_BgPatternRotateEnabled` | 3 Background face pattern | Pattern sample space is not rotated. |
| `_BgPatternModEnabled` | 3 Background face pattern | No angular mod warp on the pattern. |
| `_BgGradientEnabled` | 3 Background face gradient | Base fill stays a flat `_BgColor`, no gradient. |
| `_TrackEnabled` | 4 Track | Entire groove layer skipped — but fill/unfilled/negative layers (5, 6) are *independent* and still render if their own `Enabled` flags are on, floating with no groove backing behind them. |
| `_TrackBevelEnabled` | 4 Track bevel | Flat unbeveled track surface. |
| `_TrackPatternEnabled` | 4 Track pattern | Flat/gradient color only, no procedural material. |
| `_TrackGradientEnabled` | 4 Track gradient | Flat `_TrackColor` only. |
| `_TrackValueUnfilledEnabled` | 5 ValueUnfilled | The "remaining" segment past the handle shows nothing extra — just whatever the Track layer painted underneath (§3). Default `0`. |
| `_TrackValueUnfilledPatternEnabled` / `GradientEnabled` | 5 | Same pattern/gradient toggles as other layers. |
| `_TrackValueFilledEnabled` | 6 ValueFilled | The "progress" segment shows nothing — a slider with this off and Unfilled/Negative also off will show only the bare Track color everywhere, with no visual indication of `_Value` at all except handle position. Default `1` (on). |
| `_TrackValueFilledPatternEnabled` / `GradientEnabled` | 6 | Same pattern/gradient toggles. |
| `_TrackValueNegativeEnabled` | 6 ValueNegative | When the handle is on the "negative" side of `_TrackValueZeroPoint`, nothing distinct is drawn there (falls back to bare Track color). Default `0` (off) — a bipolar zero-point slider needs this explicitly turned on. |
| `_TrackValueNegativePatternEnabled` / `GradientEnabled` | 6 | Same toggles. |
| `_HandleEnabled` | 9 Handle | No thumb drawn at all. Also disables the Border layer's handle-occlusion carve-out (§12: border draws straight through where the handle would have been) and (in the base shader) removes the handle from the pre-composite entirely; the RM shader's handle raymarch block is likewise skipped whole. |
| `_HandleBevelEnabled` | 9 Handle bevel | Base shader: flat unbeveled handle. RM shader: `handleBevelDist=0`/`handleBevelDepthRaw=0`, collapsing the extrusion height toward the lip-only minimum (see §16 gotcha on shadow pseudo-height floor). |
| `_HandleBevelPatternEnabled` / `PatternColorEnabled` / `GradientEnabled` | 9 | Same toggles as Background bevel. |
| `_HandleRimEnabled` | 9 Handle rim | No rim highlight; `handleRimWidth` forced to `0`. |
| `_HandlePatternEnabled` / `PatternColorEnabled` / `RotateEnabled` / `ModEnabled` | 9 | Same toggles as Background face pattern. |
| `_HandleGradientEnabled` | 9 Handle gradient | Flat `_HandleColor` only. |
| `_HandleFaceEnabled` | 10 HandleFace | Entire inner-face decal skipped. |
| `_HandleFaceShapeEnabled` | 10 HandleFace shape | Face reuses the Handle's own shape type/params (shrunk by `_HandleFaceSize`) instead of its own independent shape. |
| `_HandleFacePatternEnabled` / `GradientEnabled` | 10 | Same toggles. |
| `_ScaleMarkEnabled` | 7 ScaleMarks | No tick marks drawn. |
| `_ScaleMarkGradientEnabled` | 7 | Ticks use flat `_ScaleMarkColor`. |
| `_EdgeEnabled` | 1 Edge | No inner-edge indent glow. |
| `_EdgeGradientEnabled` | 1 | Flat `_EdgeColor`. |
| `_BorderEnabled` | 11 Border | No border ring; also skips the handle-occlusion clear pass entirely, so nothing about the border logic runs. |
| `_BorderGradientEnabled` | 11 | Flat `_BorderColor`. |
| `_LightingShadow1/2/3Enabled` | 2 External shadows | That light's background drop-shadow is skipped. All 3 default `0`. |
| `_HandleShadow1/2/3Enabled` | 8 Handle body shadows | That light's handle drop-shadow is skipped. All 3 default `0`. |

---

## 16. Value mechanics — how `_Value` maps to handle position and fill extent

**Orientation is inferred, not authored.** There is no explicit horizontal/vertical property. `sliderHoriz = (rectAspect >= 1.0) ? 1.0 : 0.0` (`SDFSlider.shader:681`), where `rectAspect` comes from `_AspectRatio` if `>0.001`, else the live rendered rect's `ddy(uv.y)/ddx(uv.x)`. **A perfectly square widget (`rectAspect == 1.0`) registers as horizontal**, since the test is `>=`, not `>`. To force a specific orientation regardless of the widget's actual on-screen rect, set `_AspectRatio` explicitly (`>1` = horizontal, `<1` = vertical).

**Equi-pixel space.** All positions live in a coordinate space where the widget's *shorter* dimension always spans exactly `±1.0`; the longer dimension is scaled up by `aspectScale = (max(rectAspect,1), max(1/rectAspect,1))`. `sliderLength` (the "full track direction" scalar used below) is whichever of `aspectScale.x`/`.y` corresponds to the slider axis.

**Handle travel.**
```
handleHalfTravel = max(0, sliderLength - _HandleWidth - _HandlePadding)
handleAxisPos     = lerp(-handleHalfTravel, +handleHalfTravel, _Value)
```
(`SDFSlider.shader:697-698`) — the handle's centre travels linearly with `_Value` between the two extremes. `_HandleWidth` eats directly into the available travel (a bigger handle has less room to move before its edge would exit the quad), and `_HandlePadding` adds further clearance on top. **If `_HandleWidth + _HandlePadding >= sliderLength`, `handleHalfTravel` clamps to `0` and the handle stops moving entirely — `_Value` still changes the fill extent, but the handle itself freezes at the center.**

**Track length** is derived from the same travel value, not authored independently: `trackAxisHalf = handleHalfTravel + _TrackExtension` (`SDFSlider.shader:721`) — so the track visually always matches wherever the handle can actually reach, plus the optional extension past the endpoints.

**Fill origin and which color draws where.**
```
fillOrigin = lerp(-sliderLength, +sliderLength, saturate(_TrackValueZeroPoint))
fillMin    = min(fillOrigin, handleAxisPos)
fillMax    = max(fillOrigin, handleAxisPos)
```
(`SDFSlider.shader:734-737`) — the filled region is always the span between the fill origin and the handle, regardless of which side is which. Which *color* is used depends on which side of the origin the handle sits:
```
if (handleAxisPos >= fillOrigin)  → ValueFilled color   (SDFSlider.shader:1113)
else                              → ValueNegative color  (SDFSlider.shader:1153)
```
- **`_TrackValueZeroPoint = 0` (default):** `fillOrigin = -sliderLength`, i.e. pinned at (or beyond) the track's own start. Since `handleAxisPos` can never be less than `-handleHalfTravel` (which is ≥ `-sliderLength`), the handle is always at-or-past the origin, so **only ValueFilled ever draws** — this is the classic "progress bar fills from the start" behavior. At `_Value=0` the filled span has zero width (invisible); at `_Value=1` it spans the full track.
- **`_TrackValueZeroPoint = 1`:** mirror image — fill grows backward from the end. Still only ValueFilled ever draws (handle is always ≤ the now-positive `fillOrigin`... actually re-check: at zp=1, `fillOrigin=+sliderLength`, and `handleAxisPos <= handleHalfTravel <= sliderLength`, so `handleAxisPos < fillOrigin` always → **ValueNegative color draws instead**, not ValueFilled, for the entire range. This is a real trap: setting the zero point to the far end silently switches which color property controls the visible fill.)
- **`_TrackValueZeroPoint = 0.5`:** `fillOrigin = 0`, the track's true center — this always lands inside the visible track regardless of `_TrackExtension`/`_HandlePadding` (center is center no matter the length). Fill grows outward bipolarly: ValueFilled color for `_Value > 0.5`, ValueNegative color for `_Value < 0.5`.
- **Any other `_TrackValueZeroPoint`** is expressed as a fraction of `sliderLength` (the full equi-pixel half-extent), **not** of `trackAxisHalf` (the track's own visible half-length). If `_TrackExtension` and `_HandlePadding` are both small, `trackAxisHalf ≈ handleHalfTravel ≈ sliderLength - _HandleWidth`, so the two are close and this rarely matters. But if the track is made much shorter than the full quad (e.g. deliberately, via a big fixed inset elsewhere), an intermediate zero point can compute a `fillOrigin` that falls *outside* the actually-visible track, at which point the origin behaves identically to whichever end it overshot (0 or 1) rather than the fraction you'd expect.

**Fill perpendicular width vs. length are controlled by different properties**: `_TrackWidth` (perpendicular thickness of the whole groove) and `_TrackValuePadding` (extra inset that thins the fill line specifically, inside the groove) control the cross-axis size; `_TrackCornerRadius` controls end-cap rounding; none of these affect how much of the track's *length* is filled — only `_Value`/`_TrackValueZeroPoint`/`_TrackExtension` do.

**Distinguishing 0%, 40%, 80% at a glance** (the brief's explicit ask): with the defaults (`_TrackValueZeroPoint=0`, `ValueFilled` on, `ValueUnfilled` off), 0% shows no filled segment (bare Track color throughout, handle at the far left/top), 40% shows a filled segment reaching 0.4 of the track length with the handle at its edge, and 80% likewise to 0.8 — the handle position and the fill's trailing edge are always the same point, so as long as `_TrackValueFilledColor` contrasts with `_TrackColor` (it does by default — blue vs near-black) the three states read unambiguously. Turning `_TrackValueUnfilledEnabled` on and giving it a third, distinct color makes the "remaining" segment explicit too, which helps at low values (near 0%) where the filled segment alone is a thin sliver against the handle.

---

## 17. Interaction / dependency notes

- **Shadows only render on the shadow quad, not the widget quad.** All 6 `_LightingShadowN*`/`_HandleShadowN*` blocks are gated behind `if (_ShadowPassMode > 0.5) { ... return finalColor; }` near the top of `frag()` (`SDFSlider.shader:801-869`), which is an *early return* — the widget's normal quad (`_ShadowPassMode=0`) never executes that block and never draws shadows itself. A second, larger quad rendered by `WidgetShadowQuad.cs` (auto-managed per the zero-prefab widget pipeline, `[DefaultExecutionOrder(600)]`, copies the control's live material every `LateUpdate`) runs the shader a second time with `_ShadowPassMode=1` to produce them, composited into a shared offscreen buffer other widgets can also sample. Turning on a `_XxxShadowNEnabled` flag in `.states.json` has zero visible effect unless that auxiliary quad exists and is active for this control.
- **Border occludes for the Handle, not vice versa, but does so via a live SDF check, not draw order.** Section 11 (Border) runs *after* section 9 (Handle) in the compositing order, so naively the border would paint over the handle. Instead, `calculateSliderBorder`'s output is masked by `borderHandleOcclusion` — a fresh `getHandleSDF` evaluation at that pixel (`SDFSlider.shader:1456-1461`) — so the border neither draws over nor gets "cleared under" wherever the handle currently sits. This means a sufficiently large/eccentrically-shaped handle can visually punch a gap in the border ring as it slides past.
- **Edge and Border always use the Background shape**, never the Track or Handle shape, even if `_BgEnabled=0`. Their geometry test (`getPanelBodySDF` with `_BgShapeType`/params) runs unconditionally.
- **Track's bevel is hardcoded to Dome profile** in the base shader (`0, 0.5` passed literally at `SDFSlider.shader:1055`) — `_TrackBevelProfileType` doesn't exist as a property at all for Track (only Background and Handle expose a profile-type selector).
- **`_BgBevelProfileType`/`_HandleBevelProfileType` are Int, not `[Enum]`-tagged** — every other enum-valued Int in this shader has an `[Enum(TypeName)]` attribute giving it a dropdown in the Unity Inspector; these two don't, so hand-editing `.states.json` is the only way most people will ever set them (Inspector shows a bare number field).
- **RM `_HandleBevelProfileType`/`_HandleBevelProfileSharpness` are ignored** — the RM handle computes its bevel as real 3D wall geometry (`sdfExtrusion3D`) instead of the 2D fake-normal dome/linear switch, so these two properties (inherited from the shared Properties block) have no effect there even though they're still exposed.
- **RM `_ViewTilt`/`_ViewShift` are never read directly** — only through the `UI_VIEW_TILT`/`UI_VIEW_SHIFT` macros (`UIViewCamera.cginc:55-56`), which additionally fold in the bounded scene-camera contribution (`_ViewCamEnabled`/`_ViewCamShift`/`_ViewCamTilt` against the shared `_GlobalViewCam`). Authoring `_ViewTilt` in a `.states.json` sets the *base* tilt; the actual on-screen tilt can still move at runtime if `_ViewCamEnabled=1` and the widget isn't screen-centered.
- **Per-layer `PatternColorType`/`PatternColorMode`/`ColorUsed` are only exposed on Background and Handle** (both the base-face and bevel instances) — Track, ValueFilled, ValueUnfilled, ValueNegative, and HandleFace all expose Pattern *type/scale/intensity/contrast/param1-3* but **not** the color-palette controls; their pattern always uses plain brightness modulation (the `else` branch at `UIPatterns.cginc:900-901`), never a 4-stop palette.
- **HandleFace's Gradient has no `Speed` property** — every other Gradient block in the shader exposes `Speed`; HandleFace's `CalculateGradient` call passes a hardcoded `1.0` instead (`SDFSlider.shader:1392-1393`).
- **ScaleMarks' Gradient is hardcoded to exactly 2 stops** — there's no `_ScaleMarkGradientColorC/D` or `_ScaleMarkGradientColorUsed`; the call site passes the literal `2` (`SDFSlider.shader:1208`).
- **`_TrackValuePadding` insets the *fill*, not the track.** A common mistake: to make the track groove itself narrower, use `_TrackWidth`; `_TrackValuePadding` only thins the colored fill line drawn *inside* that groove, leaving the groove's own visible width unchanged.
- **RM's `_TrackValueBevel*` block only exists in `SDFSliderRM.shader`** — authoring it in a `.states.json` shared with the base `SDFSlider.shader` is harmless (unknown properties are simply not applied) but has zero effect on the base shader's render.
- **Handle shadows always have some pseudo-height, even with `_HandleBevelEnabled=0`.** See Gotchas.

---

## 18. Gotchas

- **`_HandleBevelEnabled=0` does not fully flatten the handle's cast shadow.** `handleBevelDepthRaw = (_HandleBevelEnabled>0.5) ? abs(_HandleBevelDepth) : 0.0`, then `handlePseudoHeight = handleMaxDim * lerp(0.05, 0.5, handleBevelDepthRaw)` (`SDFSlider.shader:788-790`) — with bevel disabled, `depthRaw=0`, so `pseudoHeight` still evaluates to `handleMaxDim * 0.05`, a nonzero 5% floor. The same pattern applies to the Background's shadow pseudo-height (`bgPseudoHeight`, line 780). A shadow-hull-sweep effect (`*ShadowNCast > 0`) will therefore still show a slight bulge even on a fully flat-looking handle/background.
- **Gradient types `5` (BevelDepth) and `6` (BevelWalls) are silently non-functional outside an RM shader's bevel-wall context.** Any `_XxxGradientType` property set to `5` or `6` — including the base `SDFSlider.shader`'s `_BgBevelGradientType`/`_HandleBevelGradientType`, or *any* Gradient slot (not just Bevel ones) even in the RM shader — falls through `GetGradientPosition`'s `default:` case and returns a fixed `0.5`. The gradient will render as a flat, static blend point (effectively picking one fixed color from the middle of the ramp) instead of an actual gradient. Only `_HandleBevelGradientType` in `SDFSliderRM.shader`, evaluated specifically on the raymarched `SURFACE_WALL` hit, uses these values meaningfully.
- **`_TrackValueZeroPoint=1` flips which color property is "the fill."** As detailed in §16, at the maximum zero-point the handle is *always* on the negative side of the origin, so `_TrackValueFilledColor` never draws at all — `_TrackValueNegativeColor` (default red, and default **disabled**, `_TrackValueNegativeEnabled=0`) becomes the only fill indicator. A slider authored this way with the negative layer left off will render **no visible progress indication whatsoever**, just a bare track, regardless of `_Value`.
- **A handle that's too big freezes in place.** If `_HandleWidth + _HandlePadding >= sliderLength` (the widget's equi-pixel half-length along the slide axis), `handleHalfTravel` clamps to `0` (`max(0.0, ...)` at `SDFSlider.shader:697`) and the handle centre sits permanently at `0` (dead center) regardless of `_Value`. The fill region still updates correctly with `_Value` — only the handle stops moving — which can look like a broken/unresponsive slider if not caught.
- **A square widget defaults to horizontal.** `sliderHoriz = (rectAspect >= 1.0) ? 1 : 0` uses `>=`, so an exactly-1:1 aspect ratio (or `_AspectRatio` set to exactly `1`) is treated as horizontal, not vertical. If a design needs a vertical slider in a square container, `_AspectRatio` must be set below `1.0` (even `0.999` would flip it), not left at `0` (auto) or `1`.
- **`_BgShapeParam3` is a declared no-op for every current `_BgShapeType` case.** `getPanelBodySDF` accepts a `param3` argument, but no case in its switch (`SDFPanelShapes.cginc:93-158`) reads it. Authoring it does nothing visible today.
- **`_HandleShapeType` 0 (Capsule) and 9 (Squircle) are pixel-identical.** Both cases in `getHandleSDF`'s switch compute `r = minDim*(1-saturate(param1))` and call `RoundedRectSDF` with the exact same arguments (`SDFSliderHandleShapes.cginc:164-169` vs `211-216`) — they exist as separate enum entries for authoring/semantic clarity only, not distinct rendering.
- **Layer `RenderAlpha=0` does not mean "free."** Setting any `_XxxRenderAlpha` to `0` makes that layer visually disappear (its `buttonCompositeOver` call contributes zero alpha), but the SDF distance field, bevel normal, pattern sampling, and full lighting model for that layer still execute every frame — there's no early-out based on `RenderAlpha`. Only the corresponding `_XxxEnabled` guard skips the work entirely.
- **`_PanelBodyRoundness`/`_HandleRoundness` can push a shape's silhouette *outward* past its nominal half-extents.** Both are implemented as `d -= roundness * minDim * 0.15` after the shape switch — a pure SDF erosion that expands the filled region in every direction, including past corners that were already fully square. At `roundness=1` this adds up to `0.15 * minDim` of extra radius on top of whatever the shape's own params already produced, which can visibly overflow a tightly-padded layout.
- **Bipolar `_TrackValueZeroPoint` values away from `0`, `0.5`, or `1` may not land where expected** if the track's rendered length (`trackAxisHalf`) is meaningfully shorter than the full widget half-length (`sliderLength`) — see the last bullet of §16's fill-origin discussion.
- **The RM shader's `_HandleBevelDepth` range is 4× wider than the base shader's** (`-4..4` vs `-1..1`) for the *same property name* — a `.states.json` authored against default ranges assuming symmetry between the two shaders should double-check this value doesn't clip or look wildly different when swapped from `SDFSlider` to `SDFSliderRM` or vice versa.
- **Saturation / clamping ranges to be aware of when hand-authoring outside the Inspector sliders:** `_TrackValueZeroPoint` is `saturate()`-ed before use (`SDFSlider.shader:734`), so values outside `[0,1]` are silently clamped, not extrapolated. `_Value` itself is a `Range(0,1)` property but nothing in the fragment shader re-clamps it after the initial `lerp` calls — an out-of-range `_Value` written via `SetMaterialFloat` (bypassing the Inspector clamp) would extrapolate the handle position and fill mask past the track's visible ends rather than clamping.
