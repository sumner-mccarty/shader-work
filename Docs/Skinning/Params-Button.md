# SDFButton / SDFButtonRM — Complete Parameter Reference

Source of truth for hand-authoring `.states.json` skins for `UI/SDFButton` (2D, file
`Assets/Shaders/SDFButton.shader`) and `UI/SDFButtonRM` (raymarched 3D variant, file
`Assets/Shaders/SDFButtonRM.shader`). Both shaders share one uniform block
(`Assets/Shaders/CG/SDF/SDFButtonUniforms.cginc`), one shape dispatcher
(`Assets/Shaders/CG/SDF/SDFButtonShapes.cginc`), and one layer-helper file
(`Assets/Shaders/CG/SDF/SDFButtonLayers.cginc` — this is also where the Icon SDF lives).

Everything below was read directly out of the current source, not inferred from names.
Where a value's meaning depends on an integer switch, the switch is quoted. Where I could
not verify a claim from code, that is stated explicitly rather than guessed.

**Fragment-section numbering used below** is the shader's own, taken from its in-code
`// ===...` banner comments (`SDFButton.shader` lines 535, 565, 633, 814, 886, 926) — it is
**not** the generic 1–11 template from other widgets' docs. SDFButton's actual layer order is:

| # | Layer | Shader-file section comment |
|---|---|---|
| 1 | Edge indent | `// 1. Edge indent (behind everything)` |
| 2/3 | External shadows + Button (body/cast) shadows | `// 2/3. External + body shadows — SHADOW QUAD ONLY` |
| 4 | Button body (shape, bevel, bevel pattern, bevel gradient, rim bevel, pattern, pattern color, gradient, face) | `// 4. Button rendering (main button shape)` |
| 5 | Icon | `// 5. Icon rendering (on top of button)` |
| 6 | Border | `// 6. Border (on top of everything)` |

Composite order (back to front) is: Edge → [shadows, on a separate expanded backing quad] →
Button body+bevel+face → Icon → Border. In `SDFButtonRM.shader` the order is the same except
Border is drawn **before** the raymarched body (so the body composites on top of it — see
§5), and a self-shadow pass runs between Border and the body.

---

## 1. Complete property table

Type column: **F**=Float, **R(a,b)**=Range(a,b), **C**=Color, **V4**=Vector, **I**=Int
(shader-side `Int`/`[IntRange]`, still a `float` uniform — see §6 guard note).
"RM" column: ✅ = present in `SDFButtonRM.shader` too (with the same name/range unless noted),
`—` = RM does not declare a matching property, `≠` = present but with a different range/default (noted in Notes).

### 0. Core / always-relevant (no `_XxxEnabled` gate)

| Name | Type | Range | Default | RM | What it does |
|---|---|---|---|---|---|
| `_MainTex` | 2D (PerRendererData) | — | white | ✅ | Declared for UGUI/CanvasRenderer compatibility (`sampler2D` uniform exists). **Never sampled** anywhere in either shader's fragment function — see §7 gotchas. |
| `_Color` | C | — | (1,1,1,1) | ✅ | Declared in the Properties block only. **No matching HLSL uniform exists anywhere in the file** — it has zero effect. Actual per-instance tint comes from the mesh vertex color (`IN.color`, i.e. `Image.color`), multiplied in at the very end of `frag()`. |
| `_Value` | R(0,1) | 0–1 | 0 | ✅ | Declared and uniform-declared (`float _Value;`) but **never read** anywhere in either shader's fragment body. "Value (Pressed)" is vestigial for this shader — pressed-state visuals must come from state-stack transitions (e.g. a "Pressed" state overriding `_ButtonBevelDepth`/color), not from this float. |
| `_AspectRatio` | F | 0=auto | 0 | — (2D only) | 0 = auto-detect aspect from `ddx/ddy` of the UV (correct for normal UGUI layout). >0 = force a W/H ratio; used by preview panes that render to a square RT. **Not in `SDFButtonRM.shader`'s Properties block** — the RM uniform still exists in code (shared `SDFButtonUniforms.cginc`) but has no Properties-block entry, so it cannot be set from the Designer/states.json on the RM material; it silently falls back to whatever the last global/material float happened to be (effectively 0/auto unless C# sets it directly). |
| `_ShadowPassMode` | F | 0 or 1 | 0 | ✅ | 0 = normal "widget quad" pass (renders everything except the shadow layers, which would clip at this quad's edge). 1 = "shadow quad" pass — a separate, larger backing quad (see `WidgetShadowQuad.cs`) that renders **only** the external/body shadow layers so they can extend past the widget's own rect. Driven by C#, not something a skin author sets by hand. |
| `_ShadowUvExpand` | F | — | 1 | ✅ | How many multiples of the widget's own size the shadow-quad backing mesh is. Used to remap `uv` back into widget-local space on the shadow pass. Set by `WidgetShadowQuad`, not a skin concern. |
| `_Position` | V4 | — | (0,0,0,0) | ✅ | This widget's UI-space position, used as the `objectPos` for computing per-widget light direction (`UILightDirection`) against the shared global lights. Set by the UI system, not authored per-skin. |
| `_StencilComp`, `_Stencil`, `_StencilOp`, `_StencilWriteMask`, `_StencilReadMask`, `_ColorMask` | F | — | 8, 0, 0, 255, 255, 15 | ✅ | Standard Unity UI stencil/mask plumbing (for `Mask`/`RectMask2D`). Not a skin concern. |

### 1. Button body — shape (section 4)

| Name | Type | Range | Default | RM | What it does |
|---|---|---|---|---|---|
| `_ButtonEnabled` | F (guard) | — | 1 | ✅ | Master switch for the entire button body (section 4 / `renderRaymarchButton`). See §3. |
| `_ButtonColor` | C | — | (0.3,0.3,0.3,1) | ✅ | Base body tint (`.rgb` only — alpha ignored, see §7). |
| `_ButtonRenderAlpha` | R(0,1) | 0–1 | 1 | ✅ | Actual opacity multiplier for the body composite (`bodyMask * bodyComponent.alpha`, where `alpha` = this property, **not** `_ButtonColor.a`). |
| `_ButtonRenderEmissive` | R(0,1) | 0–1 | 0 | ✅ | Fraction of the body's base color added to the additive emissive accumulator (bypasses premultiplied-alpha darkening at low opacity). |
| `_ButtonShapeType` | I `[Enum(ButtonShapeType)]` | — | 0 | ✅ | Body silhouette. **Full enum in §2.1.** |
| `_ButtonShapeParam1/2/3` | R(0,1) each | 0–1 | 0.2 / 0.5 / 0.5 | ✅ | Shape-specific tuning; meaning depends on `_ButtonShapeType` — see §2.1. |
| `_ButtonShapeRotation` | R(-180,180) | deg | 0 | ✅ | Rotates the body-shape sample position before evaluating the SDF. |
| `_ButtonPadding` | R(0,1.5) | equi-px | 0.3 | ✅ | Constant nine-slice margin subtracted from the aspect-scaled half-extents on **every** side (`bodyHalfW = aspectScale.x - _ButtonPadding`, clamped to a 0.001 floor). 0 = edge-to-edge; large values shrink the visible body toward nothing (see §7). |
| `_ButtonRoundness` | R(0,1) | 0–1 | 0 | ✅ | Universal **post-SDF** rounding, applied after the shape dispatcher regardless of shape type: `d -= _ButtonRoundness * minDim * 0.15` (`SDFButtonShapes.cginc:150`). Softens every shape's corners uniformly, including Polygircle/Hexagon/Octagon vertices. |
| `_ButtonShapeTexLayer` | F | -1=off | -1 | ✅ | Texture-array layer index, only read when `_ButtonShapeType == 100` (Texture). Requires the global `_SDFShapeTexArray` (declared in `SDFTextures.cginc`) to already contain that layer — this is a shared resource, not something a states.json skin populates. |
| `_ButtonShapeTexScale` | V4 (xy used) | — | (1,1,0,0) | ✅ | UV tiling scale for the texture-SDF shape (shape type 100 only). |

### 2. Button body — bevel geometry (section 4)

| Name | Type | Range | Default | RM | What it does |
|---|---|---|---|---|---|
| `_ButtonBevelEnabled` | F (guard) | — | 0 | ✅ | Master switch for the beveled edge band. See §3, §4. |
| `_ButtonBevelDepth` | R(-1,1) | signed | 0.2 | ✅ | **2D shader:** sign matters — positive = raised edge, negative = recessed (code comment: "Flip gradient direction for recessed bevels", `UILighting.cginc:654-655`). Magnitude sets how far the surface normal tilts. **RM shader: sign is discarded** — geometry height uses `abs(_ButtonBevelDepth)` only (`SDFButtonRM.shader:811`), and the body's `bevelDepth` field on its `UIComponent` is created but never read again in the RM file (only the Icon's is). So in RM, `-0.5` and `0.5` produce an identical 3D body; only the Icon's own bevel (evaluated with `CalculateShapeBevelNormal`, a 2D overlay) still respects sign. |
| `_ButtonBevelSmoothness` | R(0.001,1) | — | 0.02 | ✅ | Dome-profile roll-off width (only meaningful when `_ButtonBevelProfileType==0`, see §2.1a). In RM also scales the fillet radius on the top edge of the 3D extrusion (`filletR = bevelHeight * _ButtonBevelSmoothness * 0.4`). |
| `_ButtonBevelDistance` | R(0.001,1) | equi-px | 0.1 | ✅ | Width of the bevel band, measured inward from the body edge. Also feeds `faceInset` (see §5) which determines where the flat face begins. |
| `_ButtonFaceSmoothness` | R(-1,1) | signed | 0 | ✅ | Dome/bowl curvature of the **flat face itself** (not the edge bevel). Positive = face bulges outward (dome); negative = face caves inward (bowl). In 2D this is `fillFaceSmoothness` inside `CalculateShapeBevelNormal`; in RM it directly perturbs the face-surface normal radially (`renderRaymarchButton`, "Face dome/bowl perturbation"). |
| `_ButtonBevelProfileType` | I (no `[Enum]` tag) | — | 0 | — (declared but unused) | 0 = Dome (smoothstep S-curve), 1 = Linear (constant-slope shelf). **Full detail in §2.1a.** Only consumed by the 2D shader's body-bevel `CalculateShapeBevelNormal` call; **RM ignores it entirely** for the body (its 3D bevel is real extruded geometry, not a normal-map trick) — confirmed: this property is declared in RM's Properties block (inherited from the shared uniforms include) but never referenced in `SDFButtonRM.shader`'s code. Has **no `[Enum(BevelProfileType)]` attribute** despite `ShaderConstants.cs` defining `BevelProfileType` — the Inspector/Designer shows a raw int field, not a dropdown, unless the Designer tool special-cases the name. |
| `_ButtonBevelProfileSharpness` | R(0,1) | — | 0.5 | — (declared but unused) | Linear-profile-only slope multiplier (`bevelFactor = t * profileSharpness`). Same 2D-only, RM-ignores-it caveat as above. |

### 2.1a. `_ButtonBevelProfileType` — full enum (quoted from `CalculateShapeBevelNormal`, `UILighting.cginc:613-633`)

```
// profileType     : 0=Dome (smoothstep), 1=Linear (constant-slope angled shelf)
...
if (profileType == 1) {
    // Linear profile: constant-slope angled shelf, full depth at edge, 0 at bevelDistance inward.
    float t = saturate((scaledBevelDistance - abs(shapeSDF)) / max(0.0001, scaledBevelDistance));
    bevelFactor = t * profileSharpness;
} else {
    // Dome profile (default): smooth S-curve roll-off via smoothstep.
    bevelFactor = smoothstep(scaledBevelDistance, max(0.0001, scaledBevelDistance - scaledSmoothness), abs(shapeSDF));
}
```
- `0 = Dome` — smooth rounded roll-off, width controlled by `_ButtonBevelSmoothness`.
- `1 = Linear` — a flat-angled shelf from the edge inward across `_ButtonBevelDistance`, with `_ButtonBevelProfileSharpness` scaling how much of the full depth it reaches (0 = flush, 1 = full bevel depth at the very edge, dropping linearly to 0 at `bevelDistance`). `_ButtonBevelSmoothness` has no effect on this profile.

### 3. Button body — bevel pattern (section 4)

| Name | Type | Range | Default | RM | What it does |
|---|---|---|---|---|---|
| `_ButtonBevelPatternEnabled` | F (guard) | — | 0 | ✅ | Enables a procedural material pattern overlay confined to the bevel band. |
| `_ButtonBevelPatternType` | I `[Enum(PatternType)]` | — | 0 | ✅ | Which of the 20 pattern algorithms. **Full enum in §2.2.** |
| `_ButtonBevelPatternScale` | R(1,100) | — | 20 | ✅ | Pattern tiling frequency. |
| `_ButtonBevelPatternIntensity` | R(0,1) | — | 0.3 | ✅ | Overall pattern strength multiplier before contrast shaping. |
| `_ButtonBevelPatternContrast` | R(0.1,5) | — | 1.5 | ✅ | See §7 — counter-intuitive direction (low values sharpen/increase contrast, high values wash it out). |
| `_ButtonBevelPatternSpecularEffect` | R(0,2) | — | 1.0 | ✅ | How strongly the pattern modulates specular highlight strength. |
| `_ButtonBevelPatternRoughnessEffect` | R(0,2) | — | 0.3 | ✅ | How strongly the pattern perturbs the lighting normal (bump-like micro-roughness), via `normalOffset = -ddx/ddy(pattern) * roughnessEffect`. |
| `_ButtonBevelPatternParam1` ("Detail") | R(0,1) | — | 0.5 | ✅ | Generic per-pattern-type parameter; exact meaning depends on the chosen `PatternType` algorithm inside `UIPatterns.cginc` (not documented per-algorithm here — out of scope; treat as "detail knob," verify visually per pattern). |
| `_ButtonBevelPatternParam2` ("Distortion") | R(0,1) | — | 0.5 | ✅ | Same caveat — per-pattern-type. |
| `_ButtonBevelPatternParam3` ("Blend") | R(0,1) | — | 0.5 | ✅ | Same caveat — per-pattern-type. |

**Important dependency:** on the 2D shader (`SDFButton.shader`), bevel pattern only renders where `hasBevelEffects = (bevelActive>0.5) && (patternEnabled||gradientEnabled)` **and** `bevelFactor > 0.001` — i.e. `_ButtonBevelEnabled` must ALSO be on, or the pattern is computed but discarded (`RenderButtonBevelWithPatternAndGradient`). On RM, the wall-surface pattern block is gated the same way (`hitSurface==SURFACE_WALL && _ButtonBevelEnabled>0.5 && _ButtonBevelPatternEnabled>0.5`), but additionally **the bevel pattern's UV is the raw screen-space quad UV (`uv`), not the 3D surface UV** — the code comment explains this is deliberate: "acts as a fixed 'window into a global texture' — does not follow the 3D surface under ViewTilt rotations" (`SDFButtonRM.shader:1130-1133`). So on a tilted RM button, the bevel pattern will NOT rotate/tilt with the button the way the face pattern does.

### 4. Button body — bevel pattern color (section 4)

| Name | Type | Range | Default | RM | What it does |
|---|---|---|---|---|---|
| `_ButtonBevelPatternColorEnabled` | F (guard) | — | 0 | ✅ | Recolors the bevel pattern from a 2/3/4-stop palette instead of pure brightness modulation. |
| `_ButtonBevelPatternColorType` | I `[Enum(PatternColorType)]` | — | 2 (Zones) | ✅ | How the pattern's scalar value maps to a palette position. **Full enum in §2.3.** |
| `_ButtonBevelPatternColorMode` | I `[Enum(PatternColorMode)]` | — | 1 (Lerp) | ✅ | How the palette color composites with the base color. **Full enum in §2.4.** |
| `_ButtonBevelPatternColorUsed` | I `[IntRange(2,4)]` | 2–4 | 2 | ✅ | How many of the 4 palette colors (A/B/C/D) are actually blended between — 2 = A↔B only, 3 = A→B→C, 4 = A→B→C→D (triangle-wave ping-pong across stops, `InterpolatePatternColors`, `UIPatterns.cginc:746-761`). |
| `_ButtonBevelPatternColorA/B/C/D` | C | — | white / .5gray / .3gray / .1gray | ✅ | Palette stops. **Alpha channel is discarded** — only `.rgb` is read (`InterpolatePatternColors(...).rgb`, `UIPatterns.cginc:876-879`). |

### 5. Button body — bevel gradient (section 4)

| Name | Type | Range | Default | RM | What it does |
|---|---|---|---|---|---|
| `_ButtonBevelGradientEnabled` | F (guard) | — | 0 | ✅ | Recolors the bevel band from a gradient instead of the flat/pattern color. |
| `_ButtonBevelGradientType` | I `[Enum(GradientType)]` | — | 1 (Radial) | ✅ | 0–4 = standard gradients (see §2.5). **5 and 6 (BevelDepth / BevelWalls) are RM-only-meaningful** — see next row and §7. |
| `_ButtonBevelGradientColorA/B/C/D` | C | — | white → .1gray | ✅ | Gradient stops. **Alpha matters here** (unlike pattern colors) — see §7. |
| `_ButtonBevelGradientDirection` | V4 (xy used) | — | (1,0,0,0) | ✅ | Direction for Linear/Triangle gradient types only; ignored by Radial/Angular/Diamond and by the RM-only types 5/6. |
| `_ButtonBevelGradientSpeed` | F | — | 1.0 | ✅ | Animates the gradient position over `_Time`; nonzero = continuous drift even on a "resting" state. |
| `_ButtonBevelGradientScale` | R(0.1,5) | — | 1.0 | ✅ | Spatial frequency of the gradient sweep. |
| `_ButtonBevelGradientOffset` | R(-2,2) | — | 0.0 | ✅ | Phase offset added to the gradient position. |
| `_ButtonBevelGradientColorUsed` | I `[IntRange(2,4)]` | 2–4 | 4 | ✅ | Same "how many stops" semantics as the pattern-color version, but for gradients (`InterpolateGradientColors`, `UIGradients.cginc:117-138`). |

### 2.5a. Gradient Type 5/6 — RM-only body (quoted, `SDFButtonRM.shader:1084-1126`)

```
UNITY_BRANCH if (hitSurface == SURFACE_WALL && _ButtonBevelEnabled > 0.5 && _ButtonBevelGradientEnabled > 0.5) {
    int bevelGradType = (int)_ButtonBevelGradientType;
    if (bevelGradType == 5) {
        // BevelDepth: ramp A→D based on normalDot (wall angle vs outward radial)
        ...
    } else if (bevelGradType == 6) {
        // BevelWalls: 4-zone partition using normalDot + tangentialMag
        ...
    } else {
        // Standard gradient types on bevel
        float4 gradientColor = CalculateGradient(uv, ...);
        ...
    }
}
```
- Type `5 = BevelDepth`: ramps A→B→C→D linearly by `normalDot = dot(wallGradN, outwardRadialDir)` (how face-on vs edge-on the bevel wall is at that pixel) — only computed on `SURFACE_WALL` hits in the raymarched body.
- Type `6 = BevelWalls`: 4-zone partition — A = outer wall face-on (`normalDot>0.5`), B/C = the two sides of a groove/slit (`tangentialMag>0.7`, split by sign), D = the groove/slit back.
- **On the 2D `SDFButton.shader`, there is no such special-casing.** `CalculateGradient`'s underlying `GetGradientPosition` switch (`UIGradients.cginc:94-112`) only has cases 0–4; type 5 or 6 falls into `default: return 0.5;` — i.e. a **frozen, flat gradient position** (always the exact midpoint of the A→B→C→D ramp), not an error, just a static color that doesn't respond to the shape at all. Setting Bevel Gradient Type to 5/6 on the non-RM button is effectively a no-op pattern-wise (constant color), and is a trap if a skin is shared between the 2D and RM buttons expecting the same look.

### 6. Button body — rim bevel (section 4)

| Name | Type | Range | Default | RM | What it does |
|---|---|---|---|---|---|
| `_ButtonRimEnabled` | F (guard) | — | 0 | ✅ | Enables a second, tighter bevel band right at the silhouette edge, independent of the main bevel. |
| `_ButtonRimDepth` | R(-0.5,0.5) | signed | 0.1 | ✅ | Tilt strength/direction of the rim's normal (same raised/recessed sign convention as the main bevel, via `rimBevelDepth` fed into a normal built from the SDF gradient — `CalculateButtonRimFromSDF`, `SDFButtonLayers.cginc:466-502`). |
| `_ButtonRimWidth` | R(0.001,1) | equi-px | 0.02 | ✅ | Width of the rim band from the edge inward. Also adds into `faceInset` (see §5) — widening the rim shrinks the flat face. |
| `_ButtonRimSmoothness` | R(0.001,0.1) | — | 0.01 | ✅ | Roll-off softness of the rim band. |

**Dependency:** the rim is suppressed entirely on the interior face surface when a custom Face Shape is active and the pixel is inside it (`rimSDF = -1.0` forced, "suppress rim on face surface", `SDFButton.shader:793-798`), and suppressed everywhere when `_ButtonFaceEnabled<0.5` produces zero `faceInset` (see §7 — total invisibility trap).

### 7. Button body — pattern (section 4)

Identical structure/behavior to the bevel pattern block (§3), applied to the whole body instead of just the bevel band:

| Name | Type | Range | Default |
|---|---|---|---|
| `_ButtonPatternEnabled` | F (guard) | — | 0 |
| `_ButtonPatternType` `[Enum(PatternType)]` | I | — | 0 |
| `_ButtonPatternScale` | R(1,100) | — | 20 |
| `_ButtonPatternIntensity` | R(0,1) | — | 0.3 |
| `_ButtonPatternContrast` | R(0.1,5) | — | 1.5 |
| `_ButtonPatternSpecularEffect` | R(0,2) | — | 1.0 |
| `_ButtonPatternRoughnessEffect` | R(0,2) | — | 0.3 |
| `_ButtonPatternRotateEnabled` | F | — | 0 |
| `_ButtonPatternModEnabled` | F | — | 0 |
| `_ButtonPatternModAmount` | R(0,90) | deg | 20 |
| `_ButtonPatternModFrequency` | R(0.1,10) | — | 1 |
| `_ButtonPatternOffset` | R(-180,180) | deg | 0 |
| `_ButtonPatternParam1/2/3` | R(0,1) | — | 0.5/0.5/0.5 |

**`_ButtonPatternRotateEnabled` / `_ButtonPatternModEnabled` / `_ButtonPatternModAmount` / `_ButtonPatternModFrequency` are dead in this shader.** They map to `UIComponent.patternRotateWithValue` / `patternModWithValue`, which `ApplyMaterialPattern` only uses multiplied against a `currentValue` argument (`radians(currentValue * angleRange)` / `sin(currentValue * ...)`). Every single call site of `ApplyMaterialPattern` in both `SDFButton.shader` and `SDFButtonRM.shader` (body and icon, 4 call sites total) passes `currentValue = 0.0, angleRange = 0.0` literally. So these four properties compute `0` regardless of their values and have **zero visible effect** — this shader never wires them to `_Value` or anything else. (`_ButtonPatternOffset`, by contrast, is NOT dead — it's applied unconditionally as a static rotation.)

### 8. Button body — pattern color (section 4)

Same structure as §4, for the whole-body pattern:

| Name | Type | Range | Default |
|---|---|---|---|
| `_ButtonPatternColorEnabled` | F (guard) | — | 0 |
| `_ButtonPatternColorType` `[Enum(PatternColorType)]` | I | — | 2 (Zones) |
| `_ButtonPatternColorMode` `[Enum(PatternColorMode)]` | I | — | 1 (Lerp) |
| `_ButtonPatternColorUsed` `[IntRange(2,4)]` | I | 2–4 | 2 |
| `_ButtonPatternColorA/B/C/D` | C | — | white/.5/.3/.1 gray |

Same alpha-discarded caveat as §4.

### 9. Button body — gradient (section 4)

| Name | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_ButtonGradientEnabled` | F (guard) | — | 0 | Blends the flat body color toward a gradient. |
| `_ButtonGradientType` `[Enum(GradientType)]` | I | — | 0 (Linear) | Body gradients are computed in screen UV space via `CalculateGradient(uv,...)` — types 5/6 are meaningless here even on RM (the RM special-case for 5/6 only applies to the **bevel** gradient on `SURFACE_WALL`, not the body-fill gradient) and fall to the same `default: 0.5` flat position as §2.5a. |
| `_ButtonGradientColorA/B/C/D` | C | — | red/green/blue/yellow | Alpha matters (blend-with-base weight, see §7). |
| `_ButtonGradientDirection` | V4(xy) | — | (1,0,0,0) | Linear/Triangle only. |
| `_ButtonGradientSpeed` | F | — | 1.0 | Animates over time if nonzero. |
| `_ButtonGradientScale` | R(0.1,5) | — | 1.0 | Spatial frequency. |
| `_ButtonGradientOffset` | R(-2,2) | — | 0.0 | Phase offset. |
| `_ButtonGlobalBlend` | R(0,1) | — | 0.0 | Blends toward the **scene-wide global gradient** (`CalculateGlobalGradient`, driven by `_GlobalGradientColorA-D`/`_GlobalGradientType`/etc — uniforms not in this Properties block, set by a scene-level director, e.g. for a synced rainbow sweep across many widgets at once). Not a per-skin gradient. |
| `_ButtonGlobalIntensity` | R(0,2) | — | 1.0 | Multiplies `_ButtonGlobalBlend`'s blend weight. |
| `_ButtonGradientColorUsed` `[IntRange(2,4)]` | I | 2–4 | 4 | Stop count, as above. |

### 10. Button face (section 4 — shares the body's shape/inset math)

| Name | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_ButtonFaceEnabled` | F (guard) | — | 1 | 0 = the interior fill is punched out entirely, leaving only the bevel/rim ring visible ("ring/outline mode"). See §7 for the total-invisibility trap this can cause. |
| `_ButtonFaceShapeEnabled` | F | — | 0 | 0 (default) = face boundary is simply the body shape inset by `faceInset = rimWidth + bevelDist`. 1 = face gets its own independent SDF shape (own type/params/rotation/size), unioned into the silhouette with the body (so the face can poke outside the body outline). |
| `_ButtonFaceShapeType` `[Enum(ButtonShapeType)]` | I | — | 0 (Squircle) | Only read when `_ButtonFaceShapeEnabled>0.5`. Same 5-shape (+Texture) enum as the body — §2.1. |
| `_ButtonFaceShapeParam1/2/3` | R(0,1) | — | 0.2/0.5/0.5 | Same per-shape meanings as the body's params (§2.1), applied to the face shape. |
| `_ButtonFaceShapeRotation` | R(-180,180) | deg | 0 | Rotates the face-shape sample position. |
| `_ButtonFaceSize` | R(0.01,1) | fraction | 0.8 | Only used when `_ButtonFaceShapeEnabled>0.5`: nine-slice margin subtracted from the body half-extents to size the face shape's own half-extents — **lower = wider bevel wall** (more margin removed), 1.0 = margin removed, face shape sized to the full body half-extent. |
| `_ButtonFaceShapeTexLayer` | F | -1=off | -1 | Texture-array layer for face shape type 100. |
| `_ButtonFaceShapeTexScale` | V4(xy) | — | (1,1,0,0) | UV scale for face shape type 100. |

---

### 11. Icon (section 5)

The icon draws on top of the button body using the button's own local SDF dispatcher —
**not** the files under `Assets/Shaders/CG/SDF/Icons/`. See §2.6 for why.

| Name | Type | Range | Default | RM | What it does |
|---|---|---|---|---|---|
| `_IconEnabled` | F (guard) | — | 0 | ✅ | Master switch for the icon layer. |
| `_IconColor` | C | — | (1,1,1,1) | ✅ | `.rgb` tint; alpha ignored (opacity via `_IconRenderAlpha`, same pattern as body). |
| `_IconRenderAlpha` | R(0,1) | 0–1 | 1 | ✅ | Icon opacity. |
| `_IconRenderEmissive` | R(0,1) | 0–1 | 0 | ✅ | Additive emissive contribution. |
| `_IconShapeType` | **F (no `[Enum]` tag, not Int)** | — | 0 | ✅ | Icon glyph id. **`ShaderConstants.cs`'s `IconShapeType` enum exists and matches this dispatcher exactly** (comment: "Icon indicator shape (getIconSDF in SDFButtonLayers.cginc)"), but the Properties-block declaration is a plain `Float`, not `[Enum(IconShapeType)] Int` like the body/face shape — so unlike `_ButtonShapeType`, the Unity Inspector (outside the custom Designer tool) will show a raw number field, not a dropdown. **Full 0–28 + 100 glyph list in §2.6.** |
| `_IconWidth` | R(0.01,1.0) 2D / R(0.01,0.5) RM ≠ | fraction | 0.1 | ≠ | Icon half-extent basis (exact meaning is per-glyph — see the `getIconSDF` cases). **RM caps the range at 0.5 instead of 1.0** — same uniform, tighter Inspector slider only. |
| `_IconHeight` | same as Width | fraction | 0.1 | ≠ | Same, vertical. |
| `_IconShapeParam1/2/3` | R(0,1) | — | 0.5 each | ✅ | Per-glyph meaning — e.g. for Arrow (10): param1=headWidth, param2=tailWidth; for Star (11): param1=innerRatio, param2=pointCount; for Cross (12): param1=armWidthRatio, param2=rounding; for Chevron (20): param1 flips direction (0=right,1=down). See the quoted switch in §2.6 for the rest. |
| `_IconShapeRotation` | R(-180,180) | deg | 0 | ✅ | Rotates the icon sample position. |
| `_IconOffset` | V4(xy) | — | (0,0,0,0) | ✅ | Screen-space offset from center. On RM this is decomposed into the tilted face-plane basis so the icon still tracks the 3D face under `_ViewTilt`/`_ViewAngle`. |
| `_IconShapeTexLayer` | F | -1=off | -1 | ✅ | Texture layer for icon shape type 100. |
| `_IconShapeTexScale` | V4(xy) | — | (1,1,0,0) | ✅ | UV scale for icon shape type 100. |
| `_IconBevelEnabled` | F (guard) | — | 0 | ✅ | Enables a 2D bevel-normal effect on the icon (always the 2D `CalculateShapeBevelNormal` approach, even on RM — icons are flat overlays in both shaders). |
| `_IconBevelDepth` | R(-1,1) | signed | 0.2 | ✅ | Sign convention identical to `_ButtonBevelDepth`'s 2D behavior (raised/recessed) — **and unlike the button body, this sign is respected in RM too**, since the icon always goes through `CalculateShapeBevelNormal`. |
| `_IconBevelSmoothness` | R(0.001,1) | — | 0.02 | ✅ | Dome roll-off width. |
| `_IconBevelDistance` | R(0.001,1) | — | 0.1 | ✅ | Bevel band width. |
| `_IconFaceSmoothness` | R(-1,1) | signed | 0.0 | ✅ | Icon face dome/bowl curvature. |
| **`_IconBevelProfileType`/`_IconBevelProfileSharpness`** | — | — | — | — | **Do not exist.** Both `SDFButton.shader`'s and `SDFButtonRM.shader`'s icon-bevel calls hardcode `profileType=0, profileSharpness=0.5` (`CalculateShapeBevelNormal(iconDist, ..., 0, 0.5)`) — the icon bevel is always Dome profile; there is no property to change it. |
| `_IconPatternEnabled` … `_IconPatternParam3` | (same set as Button Pattern §7) | — | (same defaults) | ✅ | Identical mechanics to the body pattern block, applied to the icon. `_IconPatternRotateEnabled`/`_IconPatternModEnabled`/`_IconPatternModAmount`/`_IconPatternModFrequency` are **dead for the same reason** as the button's (§7) — icon's `ApplyMaterialPattern` call also hardcodes `currentValue=0.0, angleRange=0.0`. |
| `_IconPatternColorEnabled` … `_IconPatternColorD` | (same set as §4) | — | (same defaults) | ✅ | Identical mechanics. |
| `_IconGradientEnabled` … `_IconGradientColorUsed` | (same set as §9) | — | (same defaults) | ✅ | Identical mechanics — icon gradient position is computed from `iconPos*0.5+0.5` (icon-local UV), not the widget UV. |
| `_IconRimEnabled` | F (guard) | — | 0 | ✅ | Rim bevel ring right at the icon's own silhouette. |
| `_IconRimDepth` | R(-0.5,0.5) | signed | 0.1 | ✅ | Same convention as button rim. |
| `_IconRimWidth` | R(0.001,0.1) | — | 0.02 | ✅ | Note the range cap is **0.1 here, not 1.0** like the button's `_ButtonRimWidth` — the icon is much smaller so a proportionally tighter max makes sense, but a skin author copying a button-rim value verbatim onto an icon can silently clamp. |
| `_IconRimSmoothness` | R(0.001,0.1) | — | 0.01 | ✅ | Roll-off softness. |

---

### 12. Edge indent (section 1)

| Name | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_EdgeEnabled` | F (guard) | — | 0 | Draws a soft indented ring just **outside** the button body, in the space between the body edge and the widget's quad boundary. Skipped entirely on the shadow-quad pass (`_ShadowPassMode<0.5` required). |
| `_EdgeColor` | C | — | (0,0,0,0.5) | `.rgb` tint; alpha ignored — opacity via `_EdgeRenderAlpha`, same universal pattern as body/icon. |
| `_EdgeRenderAlpha` | R(0,1) | 0–1 | 1 | Opacity. |
| `_EdgeRenderEmissive` | R(0,1) | 0–1 | 0 | Additive emissive. |
| `_EdgeWidth` | R(0.001,0.2) | equi-px | 0.03 | How far outward from the body edge the indent extends. |
| `_EdgeSoftness` | R(0,1) | — | 0.5 | 0 = hard smoothstep edge; >0 switches to a `pow`-shaped falloff curve (`edgePower = lerp(0.8,4.0,softnessCurve)`), softer/broader as it increases. |
| `_EdgeIntensity` | R(0,2) | — | 1.0 | Multiplies the computed indent alpha before render-alpha. Can push past 1 for a harder cutoff. |
| `_EdgeInset` | R(-0.1,0.1) | equi-px | 0.0 | Shifts where the indent starts relative to the body edge — positive pulls it inward (overlapping the body), negative pushes it further outward. |
| `_EdgeGradientEnabled` … `_EdgeGradientColorUsed` | (same set/ranges as §9, "Edge" prefix) | — | see note | Identical gradient mechanics, tinting the edge color. **Default color stops differ from Button's**: Edge uses a grayscale ramp (`ColorA`=white, `B`=.5 gray, `C`=.3 gray, `D`=.1 gray — matching the Bevel Gradient defaults), not Button Gradient's red/green/blue/yellow. All other fields (Type=0 Linear, Direction=(1,0,0,0), Speed=1.0, Scale=1.0, Offset=0.0, GlobalBlend=0.0, GlobalIntensity=1.0, ColorUsed=4) are identical to §9. |

---

### 13. Border (section 6, but drawn **before** the body on RM — see note)

| Name | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_BorderEnabled` | F (guard) | — | 0 | Draws a ring at a fixed distance from the body edge, used for canvas-edge cut-in styling. |
| `_BorderColor` | C | — | (0,0,0,0.3) | `.rgb` used as the border fill; **alpha is never read anywhere in `calculateButtonBorder`** — opacity is `_BorderRenderAlpha` only (see §7, this is the same universal rule but worth restating since Border has no separate "intensity" gate on top). |
| `_BorderRenderAlpha` | R(0,1) | 0–1 | 1 | Opacity. |
| `_BorderRenderEmissive` | R(0,1) | 0–1 | 0 | Additive emissive. |
| `_BorderWidth` | R(0.001,0.2) | equi-px | 0.05 | Width of the border ring, measured outward from the body edge. |
| `_BorderSoftness` | R(0,0.2) | — | 0.02 | Outer-edge falloff softness. |
| `_BorderIntensity` | R(0,2) | — | 1.0 | Multiplies the border alpha before render-alpha. |
| `_BorderGradientEnabled` … `_BorderGradientColorUsed` | (same set/ranges as §9, "Border" prefix) | — | see note | Identical gradient mechanics. **Default color stops differ from Button's** the same way Edge's do: grayscale ramp (white → .5 → .3 → .1 gray), not red/green/blue/yellow. All other fields identical to §9's defaults. |

**Important gotcha (both shaders):** whenever `_BorderEnabled` is on, the code **always clears** ("punches a hole in") whatever was already composited underneath, across the border's full territory band, scaled by `max(_BorderRenderAlpha, _BorderRenderEmissive)` — **regardless of `_BorderColor`'s own value**:
```
float borderPresence = max(_BorderRenderAlpha, _BorderRenderEmissive);
float effectiveTerritory = borderTerritory * borderPresence;
if (effectiveTerritory > 0.001) {
    float clearFactor = 1.0 - effectiveTerritory;
    finalColor.rgb *= clearFactor; finalColor.a *= clearFactor; emissiveAccum *= clearFactor;
}
```
(`SDFButton.shader:911-918`, identical logic in RM at `:1444-1451`). On `SDFButtonRM.shader` this clear runs **before the raymarched body renders** (Border is composited first, body composites on top of it, §5 architecture note) — so on RM, Border cannot cut a hole through the body itself, only through the Edge/backdrop layers beneath it. On the 2D shader, Border runs **last** (after body+icon), so there it CAN cut a visible notch out of an already-drawn button body if the border ring overlaps the body silhouette.

---

### 14. Shadows (section 2/3 — shadow-quad pass only)

Three independent external-shadow slots (behind the button, on the background) and three
independent button/cast-shadow slots (simulating the 3D body's own drop shadow), each with
identical parameter sets:

| Name pattern | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_LightingShadowNEnabled` (N=1,2,3) | F (guard) | — | 0 | External shadow slot N, driven by global light N's direction. |
| `_LightingShadowNColor` | C | — | (0,0,0,0.5)/(0,0,0,0.3)×2 | **Alpha DOES matter here** — `_LightingShadow1Color.a * shadowAlpha * _LightingShadow1Intensity` is the actual composite alpha (`SDFButton.shader:577`). This is the one Color property family in the whole shader where the alpha channel is load-bearing. |
| `_LightingShadowNBlur` | R(0,1) | — | 0.3 | Softness of the shadow edge. |
| `_LightingShadowNDistance` | R(0,0.2) | equi-px | 0.02 | How far the shadow silhouette is offset from the body, along the light direction. |
| `_LightingShadowNBlurFactor` | R(0,1) | — | 0.5 | Shapes the near/far blur asymmetry (contact-hardening: near edge sharper, far edge softer) — see `buttonShadowEdgeAlpha`. |
| `_LightingShadowNIntensity` | R(0,2) | — | 1.0 | Extra multiplier on top of `.a`. |
| `_ButtonShadowNEnabled` | F (guard) | — | 0 | Cast/body shadow slot N — simulates the 3D bevel/extrusion throwing a shadow (hull-sweep from base to face). |
| `_ButtonShadowNColor` | C | — | (0,0,0,0.5)/(0,0,0,0.3)×2 | Same alpha-matters rule as external shadows. |
| `_ButtonShadowNBlur/Distance/BlurFactor/Intensity` | — | — | 0.2/0.01/0.3/1.0 | Same roles as the external shadow equivalents. |
| `_ButtonShadowNCast` | R(0,2) 2D / R(0,5) RM ≠ | — | 1.0 | Strength of the hull-sweep throw (0 = no cast component, only the flat base footprint casts). **RM widens the range to 0–5** (vs 2D's 0–2) — same uniform, just a larger usable range because RM's throw is capped separately by `MaxCast` (next row) instead of visually saturating the way the 2D flat shadow does. |
| `_ButtonShadowNMaxCast` | R(0.25,10) | — | 2.0 | **RM only.** Hard cap on how far the hull-sweep throw can extend, in units of the widget's own half-size (`2.0` = reaches exactly the default `_ShadowUvExpand=2` backing quad edge). Exists because a grazing light angle sends the raw throw toward infinity, which — without a cap — makes the shadow **vanish** rather than grow (documented failure mode in the code comment at `SDFButtonRM.shader:338-345`). Not present on the 2D shader, which has no equivalent failure mode ("RM-only: the 2D SDFButton's flat cast shadow doesn't have this failure mode"). |

**Shadows only render on the `_ShadowPassMode=1` pass** (a separate backing quad — see §0), driven externally by `WidgetShadowQuad`. On RM there is an *additional* always-on self-shadow pass (§0/§5) using the same `_ButtonShadowN*` values, gated by `finalColor.a>0.001`, that darkens siblings drawn earlier on the widget's own quad (e.g. the Border) — this is separate machinery from the shadow-quad pass and runs on every normal draw, not just the shadow pass.

---

### 15. Lighting (global, section-less — applies throughout 4/5/6)

| Name | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_LightingAmbient` | R(0,2) | — | 0.3 | Flat ambient multiplier applied to base color before the 3 directional lights are summed (`ApplyUILighting`, `UILighting.cginc:502-557`). At 0, unlit faces (normal pointing away from every light) go fully black. |

The three actual lights (`_GlobalLightPos1-3`, `_GlobalLightColor1-3`, `_GlobalLightFx1-3`)
are **not** button properties — they are scene-global uniforms published once per frame by
`UiSceneDirector` (runtime) / `GlobalLightingPlugin` (designer preview) via `UiLightRig`, shared
by every SDF widget in the scene. A `.states.json` skin cannot change light position/color/
specular per-widget; only per-widget shadow length/softness (`_LightingShadowN*`/`_ButtonShadowN*`)
is a skin's own to set.

---

### 16. RM-only additions (present in `SDFButtonRM.shader`, absent from `SDFButton.shader`)

Diffed directly from both Properties blocks (12 names):

| Name | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_ViewTilt` | R(0,10) | — | 0 | 3D camera tilt amount; 10 = a full 90° (code note: the projection degenerates near there and is clamped, see `computeRMButtonShadowAlpha`'s `cosTsafe = max(0.15, cosTpre)`). Combines with the scene camera add-on (`_ViewCamTilt`) via `UI_VIEW_TILT`. |
| `_ViewAngle` | R(-180,180) | deg | 0 | Which screen-space direction the tilt leans toward. |
| `_ViewFOV` | R(0,1) | — | 0 | 0 = orthographic projection. >0 = perspective; `focalDist = maxDim / tan(_ViewFOV * PI/2)` (0.5→45°, 0.667→60°, 0.889→80°, 1→90°). |
| `_ViewShift` | R(-5,5) | — | 0 | Lateral camera shift (parallax), combines with `_ViewCamShift` via `UI_VIEW_SHIFT`. |
| `_ViewCamEnabled` | F (guard) | — | 1 | Whether the shared scene-camera add-on (see comment: "a BOUNDED add-on to the authored view above") applies to this material at all. |
| `_ViewCamShift` | R(0,5) | — | 0.6 | Caps how far the scene camera may additionally shift this material beyond its authored `_ViewShift`. |
| `_ViewCamTilt` | R(0,10) | — | 0.8 | Caps how far the scene camera may additionally tilt this material beyond its authored `_ViewTilt`. |
| `_ButtonLipHeight` | R(0,1) | fraction of minDim | 0.08 | Height of a small vertical lip at the outer edge of the 3D extrusion, between the base and the start of the bevel — purely an RM geometry feature, no 2D equivalent. |
| `_AAWidth` | R(0.5,4.0) | — | 1.0 | Multiplier on the raymarched silhouette/face antialiasing width (`aaScale = max(0.5, _AAWidth)`). Raise it if edges look too soft/thin at small sizes; the 2D shader doesn't need this because its edges are always analytic `fwidth()`-based, not raymarch-hit-based. |
| `_ButtonShadow1MaxCast` / `2` / `3` | R(0.25,10) | — | 2.0 | See §Shadows above — hard cap on hull-sweep throw distance, RM-only. |

**Also removed:** `_AspectRatio` has no Properties-block entry in RM (see §0) even though the underlying uniform/behavior is still present in code.

---

## 2. Enum reference — every integer value, quoted from the switch that consumes it

### 2.1 `_ButtonShapeType` / `_ButtonFaceShapeType` (`ButtonShapeType`, `getButtonSDF` in `SDFButtonShapes.cginc:82-153`)

The shader file's own header comment claims "11 shape types" — **this is stale**; the actual
dispatcher only implements 5 procedural shapes + a texture-SDF fallback. Verified against both
the `switch` statement and `ShaderConstants.cs`'s `ButtonShapeType` enum, which agree exactly:

```
case 0: // Squircle -- param1=squareness (0=circle/pill, 1=sharp rect); stretches with aspect ratio
case 1: // Polygircle -- param1=0->circle, param1>0->3-12 sided polygon; uses minDim (never stretches)
case 2: // Tab -- param1=top corner radius (0=sharp, 1=half-circle top); rounded top, flat bottom
case 3: // Hexagon -- flat-top, stretches with halfSize; param1=corner rounding
case 4: // Octagon -- stretches with halfSize; param1=corner cut amount
case 100: // Texture SDF -- shape sampled from Texture2DArray layer
default: // same as case 0 (Squircle)
```

- **0 = Squircle** — `RoundedRectSDF` with corner radius `minDim*(1-param1)`. `param1=0` → radius = `minDim` (pill/circle at 1:1); `param1=1` → radius 0 (sharp rectangle). Stretches with the rect's own aspect (width/height independent).
- **1 = Polygircle** — `param1<0.001` → perfect circle (`CircleSDF`, radius=`minDim`). Else an N-gon, `sides = clamp(round(3 + param1*9), 3, 12)`, `param2` = corner rounding (`param2 * minDim * 0.15`). **Always inscribed in a circle of radius `minDim`** — the only body shape that never stretches with aspect ratio, even on a very wide/tall button.
- **2 = Tab** — rounded top half (radius `minDim*saturate(param1)`), sharp rectangular bottom half. `param1=0` sharp top, `param1=1` half-circle top.
- **3 = Hexagon** — flat-top hexagon, vertices at `(±halfSize.x, 0)`, flat edges at `y=±halfSize.y`. `param1` = corner rounding (`param1*minDim*0.1`).
- **4 = Octagon** — rectangle with 45° chamfered corners; `param1` = corner-cut amount, `cut = lerp(0, minDim*0.5, saturate(param1))`.
- **100 = Texture** — SDF sampled from a `Texture2DArray` layer (`_ButtonShapeTexLayer`/`_ButtonShapeTexScale`, or `_ButtonFaceShapeTexLayer`/`Scale` for the face). Requires the shared `_SDFShapeTexArray` (declared in `SDFTextures.cginc`) to already have that layer populated by external tooling — not something a `.states.json` skin can populate on its own.
- Any other integer (e.g. 5–99, 101+) falls to `default:`, which is identical to case 0 (Squircle). Not a crash, just silently becomes a squircle.

`param3` is **not consumed by any button shape case** (no `case` reads `param3`) — it exists in the property block/function signature for symmetry with the Knob/Panel shape systems but is currently unused for buttons.

`_ButtonRoundness` applies **after** this switch, universally, to every case including 100 and `default` (see §1.1).

### 2.2 `_ButtonPatternType` / `_ButtonBevelPatternType` / `_IconPatternType` (`PatternType`, `UIPatterns.cginc:25-54`)

Verified against `#define PATTERN_*` and `ShaderConstants.cs`:

| Value | Name |
|---|---|
| 0 | Plastic |
| 1 | Metal |
| 2 | RadialBrushed |
| 3 | CarbonFiber |
| 4 | Leather |
| 5 | BrushedCross |
| 6 | Satin |
| 7 | Concrete |
| 8 | Fabric |
| 9 | Paper |
| 10 | Frosted |
| 11 | DiamondPlate |
| 12 | Knurled |
| 13 | HexGrid |
| 14 | Perforated |
| 15 | WoodGrain |
| 16 | Marble |
| 17 | Ceramic |
| 18 | Circuit |
| 19 | NoiseOrganic |

`Param1/2/3` ("Detail"/"Distortion"/"Blend") meanings are algorithm-specific inside `SamplePatternValue` (`UIPatterns.cginc`) — out of scope to fully re-derive here per algorithm; verify visually per chosen type.

### 2.3 `_XxxPatternColorType` (`PatternColorType`, `UIPatterns.cginc:59-67`)

```
#define PATTERN_COLORTYPE_GRADIENT  0   // signed range [-1,+1] → palette: negative=A, zero=mid, positive=D
#define PATTERN_COLORTYPE_FEATURE   1   // feature strength → palette: flat surface=A, peak feature=D
#define PATTERN_COLORTYPE_ZONES     2   // repeating palette cycles — irregular coloring per feature instance
#define PATTERN_COLORTYPE_BANDS     3   // sine-wave banding — rings, veins, layered patterns
```
- **0 = Gradient** — `saturate((patternValue+1)*0.5)` — a signed pattern value maps linearly across the whole palette.
- **1 = Feature** — `saturate(abs(patternValue))` — magnitude only; flat areas sit at A, strong positive OR negative features both push toward D.
- **2 = Zones** — `frac(abs(patternValue) * 2.718281828)` — deliberately irrational multiplier so repeating pattern features land on visually distinct, non-aligned palette positions.
- **3 = Bands** — `abs(sin(patternValue * π))` — sine-wave banding, good for rings/veins.

### 2.4 `_XxxPatternColorMode` (`PatternColorMode`, `UIPatterns.cginc`, consumed at `UIPatterns.cginc:881-897`)

```
if (blendMode == 0) return patternColor * (1.0 + pattern);                          // Modulate
else if (blendMode == 1) return lerp(baseColor, patternColor, saturate(abs(pattern))); // Lerp
else if (blendMode == 2) return baseColor + patternColor * saturate(pattern);          // Additive
else return baseColor * lerp(float3(1,1,1), patternColor, saturate(abs(pattern)));     // Multiply (default/3)
```
- **0 = Modulate** — palette color's own brightness scaled by `(1+pattern)`; base color is fully replaced by the palette (not blended with it).
- **1 = Lerp** — base color blends toward the palette color as pattern strength increases; at `pattern=0` you see pure base color.
- **2 = Additive** — palette color is added on top of base (only for positive `pattern`, since it's `saturate(pattern)` not `abs`) — brightens, never darkens toward the palette.
- **3 = Multiply** — palette color tints/darkens the base color multiplicatively.

### 2.5 `_XxxGradientType` (`GradientType`, `UIGradients.cginc:11-21`)

```
#define GRADIENT_LINEAR       0
#define GRADIENT_RADIAL       1
#define GRADIENT_ANGULAR      2
#define GRADIENT_DIAMOND      3
#define GRADIENT_TRIANGLE     4
#define GRADIENT_BEVEL_DEPTH  5  // RM-only-meaningful, bevel wall gradient — see §2.5a
#define GRADIENT_BEVEL_WALLS  6  // RM-only-meaningful, bevel wall gradient — see §2.5a
```
- **0 = Linear** — `dot(uv, normalize(direction)) * scale + time*speed*0.1 + offset`.
- **1 = Radial** — distance from UV center `(0.5,0.5)`.
- **2 = Angular** — `atan2` sweep around center, normalized to `[0,1)`.
- **3 = Diamond** — taxicab (L1) distance from center.
- **4 = Triangle** — a Linear ramp passed through a repeating triangle wave (`TriangleWave`), for a seamlessly tiling animated stripe.
- **5/6** — see §2.5a. Only produce their described special behavior on `SURFACE_WALL` hits of the RM **bevel** gradient; everywhere else (body gradient, edge/border gradient, and the entire 2D shader) they fall through `GetGradientPosition`'s `default:` case and return a frozen `0.5`.

### 2.6 `_IconShapeType` (`IconShapeType`, `getIconSDF` in `SDFButtonLayers.cginc:29-185`; matches `ShaderConstants.cs`'s `IconShapeType` enum exactly)

**Important:** `Assets/Shaders/CG/SDF/Icons/SDFIconsUI.cginc`, `SDFIcons.cginc`, and
`SDFIconsBasic.cginc` define a *different*, larger icon set (`GetIconSDF`/`GetUIIconSDF`/
`GetBasicIconSDF`, IDs 1–39) — but **neither `SDFButton.shader` nor `SDFButtonRM.shader`
includes any file under `CG/SDF/Icons/`** (confirmed by `grep`: the only shader that
references those files is the deprecated `Assets/Shaders/Reference/SDFButton.shader.backup`).
The button's actual icon dispatcher is the local `getIconSDF` function in
`SDFButtonLayers.cginc`, with its own independent 0–28 (+100) numbering below. Do not use the
`ICON_*` defines from the `Icons/` folder when authoring a button skin — they do not correspond
to this shader's `_IconShapeType` values at all past a coincidental overlap in small numbers.

| Value | Name | Notes (param1/param2 where used) |
|---|---|---|
| 0 | Circle | |
| 1 | Rectangle | |
| 2 | RoundedRect | param1 = corner radius |
| 3 | Ellipse | |
| 4 | Triangle | points up |
| 5 | Diamond | |
| 6 | Play | triangle pointing right |
| 7 | LineV | vertical bar, param1 = corner radius |
| 8 | LineH | horizontal bar, param1 = corner radius |
| 9 | Dot | small filled circle |
| 10 | Arrow | points up; param1 = head width, param2 = tail width |
| 11 | Star | param1 = inner ratio, param2 = point count (3–9) |
| 12 | Cross | "plus" too; param1 = arm width ratio, param2 = rounding |
| 13 | Heart | |
| 14 | Hexagon | |
| 15 | Pentagon | |
| 16 | Eye | almond outline + pupil dot (MultiTrack row solo) |
| 17 | SpeakerOff | speaker + X (MultiTrack row mute) |
| 18 | Speaker | speaker + sound-wave arcs (unmuted) |
| 19 | Close | × of two bars (overlay/sheet close) |
| 20 | Chevron | param1: 0 = points right, 1 = points down |
| 21 | Grabber | **reserved, not implemented** — falls to `default:` (renders as a plain Circle) |
| 22 | Search | **reserved, not implemented** — renders as Circle |
| 23 | Gear | **reserved, not implemented** — renders as Circle |
| 24 | Check | **reserved, not implemented** — renders as Circle |
| 25 | Loop | **reserved, not implemented** — renders as Circle |
| 26 | Metronome | **reserved, not implemented** — renders as Circle |
| 27 | Folder | **reserved, not implemented** — renders as Circle |
| 28 | Film | **reserved, not implemented** — renders as Circle |
| 100 | Texture | SDF sampled from `_SDFShapeTexArray` layer `_IconShapeTexLayer` |
| anything else | — | falls to `default: return CircleSDF(...)` — silently becomes a circle, not an error |

---

## 3. `_XxxEnabled` guard list — every section-enable float

All of these are compared with `> 0.5` (never `== 1`), so any value ≥ 0.5001 counts as "on."

| Guard | What turns OFF when 0 |
|---|---|
| `_ButtonEnabled` | The entire section-4 body block: shape, bevel, bevel pattern, bevel gradient, rim, pattern, pattern color, gradient, face. Nothing in section 4 evaluates at all — cheapest way to fully hide the button while keeping Icon/Edge/Border/Shadows independently visible. |
| `_ButtonBevelEnabled` | `bevelDist`/`bevelDepthRaw` are both forced to 0 upstream (`SDFButton.shader:525-526`, `SDFButtonRM.shader:810-811`) before any bevel math runs — so the body renders perfectly flat (normal stays `(0,0,1)`), and `hasBevelEffects` in `RenderButtonBevelWithPatternAndGradient` is forced false regardless of the bevel-pattern/gradient enables (§3 dependency note). On RM, bevel HEIGHT of the extrusion itself also goes to 0 — the 3D lip becomes the only visible edge feature. |
| `_ButtonBevelPatternEnabled` | Just the procedural material overlay on the bevel band; the bevel's base color/lighting still render. |
| `_ButtonBevelPatternColorEnabled` | Bevel pattern reverts to plain brightness modulation (`baseColor*(1+pattern)`) instead of the A/B/C/D palette. |
| `_ButtonBevelGradientEnabled` | Bevel band keeps its flat/patterned color instead of a gradient sweep. |
| `_ButtonRimEnabled` | No secondary tight edge-highlight band; `CalculateButtonRimFromSDF` returns the input color/normal untouched. |
| `_ButtonPatternEnabled` | Whole-body procedural material overlay off; body stays flat/gradient color. |
| `_ButtonPatternColorEnabled` | Body pattern reverts to brightness modulation instead of palette recolor. |
| `_ButtonGradientEnabled` | Body stays the flat `_ButtonColor` (still receives global-gradient blend if `_ButtonGlobalBlend>0`, and pattern if enabled). |
| `_ButtonFaceEnabled` | Interior fill is fully punched transparent, leaving only the bevel/rim ring — **can make the ENTIRE button invisible if bevel and rim are both off too**, see §7. |
| `_ButtonFaceShapeEnabled` | Face boundary reverts to a simple inset of the body shape (`bodyDist + faceInset`) instead of an independently-shaped SDF. |
| `_IconEnabled` | No icon layer at all (section 5 skipped). |
| `_IconBevelEnabled` | Icon renders flat (no bevel normal contribution). |
| `_IconPatternEnabled`, `_IconPatternColorEnabled`, `_IconGradientEnabled`, `_IconRimEnabled` | Icon equivalents of the button-body guards above. |
| `_EdgeEnabled` | Section 1 skipped entirely — no indent ring outside the body. |
| `_EdgeGradientEnabled` | Edge stays flat `_EdgeColor` (still receives global-gradient blend if `_EdgeGlobalBlend>0`). |
| `_BorderEnabled` | Section 6 skipped — also means the "clear territory under the border" effect (§Border) does not happen at all. |
| `_BorderGradientEnabled` | Border stays flat `_BorderColor`. |
| `_LightingShadow{1,2,3}Enabled` | That external-shadow slot skipped (only evaluated on the shadow-quad pass). |
| `_ButtonShadow{1,2,3}Enabled` | That cast-shadow slot skipped, both on the shadow-quad pass AND (RM only) the self-shadow-onto-siblings pass. |

Note: `light.enabled` (the 3 scene lights, `_GlobalLightFxN.x > 0.5`) is a **separate** guard
from anything above — it is scene-global, not a button property, and gates the diffuse+specular
contribution of that light inside `ApplyUILighting`.

---

## 4. Bevel / lighting model — what makes a button read as raised vs recessed vs flat

**Flat:** `_ButtonBevelEnabled=0`, or `_ButtonBevelDepth=0`, or `_ButtonBevelDistance` so small
the band never activates. Surface normal stays `(0,0,1)` everywhere → `ApplyUILighting` gives a
uniform "looking straight at the light" shading with no highlight sweep.

**Raised (2D shader) / always for RM body:** `_ButtonBevelDepth > 0`. In the 2D shader, the
bevel-normal helper's edge direction (`edgeDir = -normalize(sdfGradient)`) is used unflipped —
the code comment states this "points INWARD," i.e. the simulated slope tilts down from a raised
outer rim toward the (relatively lower) center, the classic embossed-button look. In the RM
shader the body ALWAYS gets the same raised, upward-sloping extrusion regardless of
`_ButtonBevelDepth`'s sign, because RM geometry uses `abs(_ButtonBevelDepth)` for height (§1,
`_ButtonBevelDepth` row) — sign-based recessing is a 2D-shader-only effect for the body (the
Icon still respects sign in both shaders, since it always uses the 2D bevel-normal path).

**Recessed (2D shader body, or Icon in either shader):** `_ButtonBevelDepth < 0` — code
explicitly flips the edge direction ("Flip gradient direction for recessed bevels",
`UILighting.cginc:654-655`), simulating a carved-in / inset groove instead of a raised rim.

**Depth magnitude and reach:** `abs(_ButtonBevelDepth)` scales `totalDepth` (how far the normal
tilts, 0 = flat, saturating visually well before 1.0 since `normal.z = 1 - abs(totalDepth)*0.5`
never goes negative). `_ButtonBevelDistance` sets how wide (in equi-pixels) the sloped band is;
`_ButtonBevelSmoothness` (Dome profile) or `_ButtonBevelProfileSharpness` (Linear profile, 2D
body only) shapes the roll-off curve within that band. On RM, bevel HEIGHT of the actual 3D mesh
is `minDim * lerp(0.05, 1.0, abs(_ButtonBevelDepth))` — i.e. even at `_ButtonBevelDepth=0` the RM
extrusion still has a small 5%-of-minDim step (never perfectly flat once `_ButtonBevelEnabled=1`
on RM, unlike the 2D shader which can reach a truly flat normal at depth=0).

**Interaction with the 3-light rig:** none of the bevel properties change light position/color —
they only change the **surface normal** fed into `ApplyUILighting(normal, baseColor, ambient,
specularMod, normalOffset, light1, light2, light3)`. A steeper bevel normal facing toward a
light's direction reads brighter (Lambert `max(0,dot(N,L))`) and picks up more Blinn-Phong
specular (`pow(max(0,dot(N,H)), specularPower)`); facing away from all three lights, a surface
only shows `baseColor * _LightingAmbient`. Because the 3 lights are scene-global (§Lighting), the
*direction* a given bevel looks "lit from" is not something a skin controls — only how strongly
the geometry itself reacts (via bevel depth/distance/smoothness/profile) is.

---

## 5. Interaction / dependency notes

- **`faceInset = rimWidth + bevelDist`** (`_ButtonRimEnabled ? _ButtonRimWidth : 0` +
  `_ButtonBevelEnabled ? _ButtonBevelDistance : 0`) is the quantity that positions where the flat
  face begins when `_ButtonFaceShapeEnabled=0` (the default "face = body inset" mode). **Both**
  Rim Width and Bevel Distance shrink the visible flat face area jointly — increasing either one
  narrows the face, even though they're in separate Properties-block groups.
- When `_ButtonFaceShapeEnabled=1` instead, the custom face shape's size comes from
  `_ButtonFaceSize` (a fraction of the body half-extent) plus `_ButtonBevelDistance` as an
  additional offset — `_ButtonRimWidth` is **not** part of that calculation; the rim becomes a
  separate decorative ring around the outer body edge, independent of the custom face's size.
- **RM-only sign gotcha:** `_ButtonBevelDepth`'s sign only matters for the 2D shader's body and
  for the Icon in both shaders. RM's 3D body always uses `abs(_ButtonBevelDepth)` for height (§4).
- **RM-only profile gotcha:** `_ButtonBevelProfileType`/`_ButtonBevelProfileSharpness` only
  affect the 2D shader's body bevel; RM's body bevel is real extruded geometry and never reads
  either property (both are declared in RM's Properties block via the shared uniforms include,
  but never referenced in `SDFButtonRM.shader`'s code).
- **Bevel Gradient types 5/6 (BevelDepth/BevelWalls)** only do anything special on RM's body's
  `SURFACE_WALL` hits; everywhere else — the 2D shader entirely, and the body/edge/border
  gradients on RM — they silently collapse to a static flat `0.5` gradient position (§2.5a).
- **Pattern "rotate/mod with value" properties are dead code for this shader**
  (`_ButtonPatternRotateEnabled`, `_ButtonPatternModEnabled`, `_ButtonPatternModAmount`,
  `_ButtonPatternModFrequency`, and their `_Icon*` equivalents) — every `ApplyMaterialPattern`
  call site hardcodes `currentValue=0`, so these four properties per pattern block compute to
  zero regardless of what they're set to (§7, §Icon). `_ButtonPatternOffset`/`_IconPatternOffset`
  are NOT dead — they apply a static rotation unconditionally.
- **`_Value` (Value/Pressed) has no reader anywhere** in either shader's fragment function —
  it exists as a Properties-block entry only. A "pressed" visual must come entirely from the
  state-stack (a "Pressed" state that overrides e.g. `_ButtonBevelDepth` sign or `_ButtonColor`),
  never from reading `_Value` directly in this shader.
- **`_MainTex` and `_Color` are both fully inert** — `_MainTex` is declared (`sampler2D`) but
  never sampled; `_Color` has no matching HLSL uniform anywhere in the file. Tinting is entirely
  through the many `_XxxColor` properties plus the mesh vertex color (`Image.color` on the UGUI
  component, multiplied in once at the very end of `frag()`).
- **Pixel-size scaling — patterns can vanish at small control sizes.** All pattern math samples
  in either `uvIso` (isotropic UV, 2D body/icon patterns) or the raw `uv`/3D `faceUV` (RM), with
  `_XxxPatternScale` (1–100) controlling spatial frequency directly in UV space — it has **no
  relationship to the control's actual pixel size** on screen. A `PatternScale` tuned to look good
  on a 200px button will alias/moiré or wash out to a flat average color on an 8px button (the
  same UV-space frequency now spans far fewer screen pixels than a period). Likewise
  `_ButtonRimWidth`/`_EdgeWidth`/`_BorderWidth`/`_ButtonBevelDistance` are all in **equi-pixel
  space** (roughly "fraction of the shorter side of the widget," not literal screen pixels) —
  they scale with the widget's own size in the layout, not with actual on-screen pixel density,
  so the same numeric value reads as a much larger fraction of a tiny button than a large one.
  A rim/bevel/edge width tuned for a big button can swallow a small button's entire face.
- **Texture-SDF shape/icon types (100) depend on external state.** `_ButtonShapeTexLayer`,
  `_ButtonFaceShapeTexLayer`, `_IconShapeTexLayer` only do something useful if the shared
  `_SDFShapeTexArray` (global `Texture2DArray`, declared in `SDFTextures.cginc`) already contains
  that layer index — populating the array itself is outside what a `.states.json` skin can do; a
  skin can only choose which layer to sample.

---

## 6. Gotchas

- **Alpha-channel rule (verified across every color property in both shaders):**
  - `_LightingShadowNColor.a` / `_ButtonShadowNColor.a` — **used**, multiplies shadow opacity.
  - Every `_XxxGradientColorA/B/C/D` (Button/Bevel/Edge/Border/Icon gradients) — **used**, the
    interpolated stop's `.a` is the lerp weight blending flat base color → gradient color
    (`baseColor = lerp(baseColor, gradientColor.rgb, gradientColor.a)`). A gradient stop with
    `a=0` is invisible at that point in the ramp even if its RGB is set.
  - `_ButtonColor.a`, `_IconColor.a`, `_EdgeColor.a`, `_BorderColor.a` — **ignored**. Only `.rgb`
    is read; actual opacity is the separate `_XxxRenderAlpha` float. Setting `_ButtonColor`'s
    alpha to 0 in a skin does **not** hide the button.
  - Every `_XxxPatternColorA/B/C/D` (pattern palettes) — **ignored**, only `.rgb` is read
    (`InterpolatePatternColors(...).rgb`).
- **`_ButtonBevelPatternContrast`/`_ButtonPatternContrast`/`_IconPatternContrast` behave inverted
  from what "contrast" suggests at the range extremes.** The code does
  `pattern = sign(pattern) * pow(abs(pattern), 1.0/contrast)`. At the low end of the range
  (`0.1`), the exponent is `10`, which crushes weak signal toward 0 and keeps only the strongest
  features visible — i.e. **low Contrast values read as MORE contrasty** (sharp, mostly flat with
  sparse peaks). At the high end (`5`), the exponent is `0.2`, which pulls weak signal up toward
  full strength — **high Contrast values read as flatter/washed out**, with the pattern visible
  almost everywhere at similar strength. The default `1.5` is already on the "flatten slightly"
  side of neutral (`1.0`).
- **Disabling Face without any Rim/Bevel margin makes the whole button invisible, not just the
  face.** If `_ButtonFaceEnabled=0` and `faceInset` (`_ButtonRimWidth` when rim is on, plus
  `_ButtonBevelDistance` when bevel is on) is `0` — e.g. Rim and Bevel are both off, or their
  distances are effectively 0 — the code explicitly zeroes `bodyMask` entirely rather than
  leaving a degenerate ring (`SDFButton.shader:682-690`, code comment: "Guard: if faceInset is
  zero... just hide everything"). A skin author trying to make a plain thin outline (face off, no
  bevel/rim) must give the rim or bevel a nonzero width/distance or the button vanishes.
- **`_ButtonPadding` above the widget's own aspect-scaled half-extent collapses the body to a
  0.001-unit dot**, not a graceful shrink to zero — `bodyHalfW = max(0.001, aspectScale.x -
  _ButtonPadding)`. At the property's own max (`1.5`) this is easy to hit on a small/near-square
  widget.
- **`_ButtonRoundness` and shape-specific `param1` both round corners but are not equivalent** —
  `_ButtonRoundness` is a flat, shape-agnostic post-SDF offset (`-_ButtonRoundness*minDim*0.15`,
  max ~15% of the short side) applied identically to every shape type including Polygircle,
  Hexagon, and Octagon, which already have their own independent rounding params. Cranking both
  to max on, say, Hexagon compounds — verify visually rather than assuming additivity is linear.
- **Any nonzero `_XxxGradientSpeed` animates continuously**, including on a resting/idle state —
  most gradient blocks default `Speed=1.0`. A skin author who enables a gradient purely for its
  static color ramp (not wanting motion) must explicitly set `Speed=0`.
- **Icon shape ids 21–28 (Grabber, Search, Gear, Check, Loop, Metronome, Folder, Film) are
  reserved placeholders** — they are named/numbered in `ShaderConstants.cs` but not implemented
  in `getIconSDF`'s switch, so selecting them silently renders a plain circle (the `default:`
  case), not an error and not a missing-icon indicator.
- **The generic `Assets/Shaders/CG/SDF/Icons/*.cginc` icon library is not used by this shader at
  all** — do not cross-reference its `ICON_*` IDs against `_IconShapeType`; they are a completely
  separate, unrelated numbering used only by the deprecated `Reference/SDFButton.shader.backup`.
- **`_IconShapeType` has no `[Enum]` attribute** even though `ShaderConstants.cs` defines a
  matching `IconShapeType` enum — every other shape-type property in this file
  (`_ButtonShapeType`, `_ButtonFaceShapeType`) does have `[Enum(ButtonShapeType)]`. Whatever tool
  reads this Properties block for dropdown generation may not offer a dropdown for icons the way
  it does for body/face shapes; a hand-authored `.states.json` needs the literal integer from
  §2.6.
- **`_ButtonBevelProfileType` also has no `[Enum]` attribute** despite `ShaderConstants.cs`
  defining `BevelProfileType` — same caveat, and doubly moot on RM since the property does
  nothing there at all (§Interaction notes).
- **RM `_IconWidth`/`_IconHeight` cap at 0.5, not 1.0** like the 2D shader's same-named
  properties — a skin shared between `SDFButton` and `SDFButtonRM` materials that pushes these
  near the 2D shader's max will silently clamp on RM.
- **RM `_ButtonShadowNCast` range is 0–5 vs the 2D shader's 0–2** for the identically-named
  property — a value like `3.0` is valid on RM but out-of-range (and will clamp in a slider UI,
  though the raw float would still be accepted by the material) on the 2D shader.
