# SDFKnob / SDFKnobRM — Parameter Reference

Source read in full: `Assets/Shaders/SDFKnob.shader` (Properties block + fragment function),
`Assets/Shaders/SDFKnobRM.shader` (Properties block, diffed against SDFKnob), `Assets/Shaders/CG/SDF/SDFKnobUniforms.cginc`,
`Assets/Shaders/CG/SDF/SDFKnobLayers.cginc`, `Assets/Shaders/CG/SDF/SDFKnobShapes.cginc`, and all 16 files in
`Assets/Shaders/CG/SDF/KnobShapes/*.cginc`. Supporting enum/behaviour claims verified against
`Assets/Shaders/ShaderConstants.cs`, `Assets/Shaders/CG/Core/UIMath.cginc`, `Assets/Shaders/CG/Core/UIGradients.cginc`,
`Assets/Shaders/CG/Core/UIPatterns.cginc`, `Assets/Shaders/CG/Core/UILighting.cginc`, and
`Assets/Shaders/CG/SDF/SDFPrimitives.cginc` (`ArcSDF`).

`SDFKnob.shader` has **~590 properties**. This doc groups them so a skin author can find what they need without
reading raw property soup. Section 2 defines the five *repeated sub-block shapes* (Bevel / Bevel-Pattern /
Bevel-Pattern-Color / Bevel-Gradient / Rim / Material-Pattern / Pattern-Color / Gradient) that appear, nearly
verbatim, on six different components (Fill, Line, Value Filled, Value Unfilled, Knob, Nub). Section 3 is the
complete per-property table, organized by component; rows that belong to one of the repeated sub-blocks link back
to §2 instead of repeating the same sentence six times — but every property name, type, range and default is
listed somewhere in §3. Nothing is summarized away.

---

## 1. What this shader draws (component map)

Rendered **in this literal order** (top of z-order = last in this list = drawn last = on top):

| # | Component | Enable flag | What it is |
|---|---|---|---|
| 1 | Edge indent | `_EdgeEnabled` | A dark "routed hole" gradient drawn *behind* everything, following the outer silhouette of Fill/Line/Value geometry. Skipped entirely when rendering the shadow-quad pass. |
| 2 | External + Knob shadows | `_LightingShadow1/2/3Enabled`, `_KnobShadow1/2/3Enabled` | Only rendered when `_ShadowPassMode > 0.5` (a separate expanded "shadow quad" draw call, see §5 in Interaction notes) — never on the normal widget quad. |
| 3 | Outer decorative rings | `_OuterRing1/2/3Enabled` | Up to 3 independent rings outside the dial, solid/dashed/dotted. |
| 4 | Scale marks | `_OuterMarksEnabled` | Tick marks / dots / arc segments / mixed, with major-tick sub-styling. |
| 5 | Fill | `_FillEnabled` | Static circular disc from center out to `_LineRadius`. Does **not** rotate with value. |
| 6 | Line (track) | `_LineEnabled` | The arc ring from `_LineRadius` to `_LineRadius + _LineWidth`, spanning `_AngleStart`→`_AngleStart+_AngleRange`. This is the "channel" the value fill sits inside. |
| 7 | Value Unfilled | `_LineSublineUnfilledEnabled` | The unfilled remainder of the value arc, drawn first (background) of the two value sub-arcs. |
| 8 | Value Filled | `_LineSublineFilledEnabled` | The filled portion of the value arc (0 → `_Value`), drawn on top of Unfilled. Has its own glow (`_LineSublineGlowEnabled`). |
| 9 | Knob body | `_KnobEnabled` | The rotating shape at the center — the primary value indicator. Has its own edge-indent (`_KnobEdgeEnabled`), independent face shape (`_KnobFaceShapeEnabled`), bevel, pattern, gradient, rim. **SDFKnobRM replaces its bevel with a true 3D sphere-marched extrusion**, everything else is shared/identical code. |
| 10 | Nub | `_NubEnabled` | An *independent* rotatable pointer/dot, positioned by its own `_NubDistance`/`_NubRotation`, oriented radially outward. Uses a **different, more limited** shape dispatcher than the Knob (see §4 gotcha). |
| 11 | KnobNub | `_KnobNubEnabled` (requires `_KnobEnabled`) | A small shape orbiting the knob's own face center (not the widget center), at `_KnobNubDistance × knobRadius`. Uses the **same full shape dispatcher as the Knob body** (unlike Nub). |
| 12 | Border | `_BorderEnabled` | A cut-in alpha border drawn outside the outermost visible geometry radius, for compositing over a background texture. Also clears (darkens) shadow/edge pixels under its own footprint. |
| — | Text layout | `_TextEnabled` | **Not rendered by the shader at all** — these floats drive a C# `ITextLayoutProvider`/`ShaderTextManager` that positions real TMP text objects. Skinning them has zero visual effect unless the C# side reads them. |

---

## 2. Shared sub-block legend (read this once)

Six components — **Fill**, **Line**, **Value Filled** (`_LineSublineFilled*`), **Value Unfilled**
(`_LineSublineUnfilled*`), **Knob**, **Nub** — each carry the same eight sub-blocks below, with the component's
name/prefix substituted for `{P}`. Numeric ranges/defaults differ *per component* (see §3 for the real numbers);
this section only explains what each suffix **does**, verified against the actual code paths.

### 2.1 Bevel block — `{P}BevelEnabled/Depth/Smoothness/Distance`, `{P}FaceSmoothness`
- **`{P}BevelEnabled`**: gate. When 0, `effectiveBevelDepth` is forced to `0.0` before the normal calc runs — the bevel *band* geometry is still evaluated but produces a flat (unlit-relative) normal, so there's no visible embossing.
- **`{P}BevelDepth`**: normal-perturbation strength. Confirmed sign convention from `CalculateArcBevelNormal`/`CalculateShapeBevelNormal`: **positive = raised/domed, negative = recessed/inset** — the code explicitly inverts the gradient direction when `bevelDepth < 0.0`.
- **`{P}BevelSmoothness`**: width of the smoothstep falloff at the edge of the bevel band (Dome profile) or (for Knob) has no effect on the Linear profile.
- **`{P}BevelDistance`**: how far inward from the shape edge (world-space units, same space as `_LineRadius`) the bevel band extends before going flat.
- **`{P}FaceSmoothness`**: a *second*, independent "dome/bowl" effect applied to the flat interior (beyond the bevel band), only when the sample is inside the shape (`shapeSDF < 0`) and the value is non-zero. Positive/negative selects dome vs. bowl curvature of the face itself, separate from the edge bevel.
- **Knob only** — `{P}BevelProfileType` (`[Enum(BevelProfileType)]`): `0 = Dome` (smooth `smoothstep` S-curve, the classic soft bevel), `1 = Linear` (constant-slope angled shelf — full depth at the edge, ramping to 0 at `BevelDistance`, scaled by `BevelProfileSharpness`). Verified at `UILighting.cginc:626-633`.
- **Knob only** — `{P}BevelProfileSharpness`: only affects the Linear profile (`bevelFactor = t * profileSharpness`); has **zero effect** when `BevelProfileType = Dome`.

### 2.2 Bevel Pattern block — `{P}BevelPatternEnabled/Type/Scale/Intensity/Contrast/SpecularEffect/RoughnessEffect/Param1-3`
A procedural material pattern that **replaces** the component's normal pattern *only inside the bevel band* (i.e. only where the Bevel block above is currently blending in). See §2.6 for what each `PatternType` value looks like — same enum, same sampling functions, just scoped to the bevel ring instead of the whole face.

### 2.3 Bevel Pattern Color block — `{P}BevelPatternColorEnabled/Type/Mode/Used`, `{P}BevelPatternColorA/B/C/D`
Recolors the bevel-pattern's procedural signal through a 4-stop palette. See §2.7 (`PatternColorType`) and §2.8 (`PatternColorMode`) — identical semantics, just applied to the bevel pattern instead of the main one.

### 2.4 Bevel Gradient block — `{P}BevelGradientEnabled/Type`, `{P}BevelGradientColorA-D`, `{P}BevelGradientDirection/Speed/Scale/Offset`, `{P}BevelGradientColorUsed`
A gradient that **replaces** the base color *only inside the bevel band* (independent of, and layered under, the Bevel Pattern above — pattern is applied after gradient inside the bevel-color calc). See §2.9 for `GradientType` values. **`{P}BevelGradientType` defaults to `1` (Radial) on every component that has this block** — different from the main Gradient block's default of `0` (Linear).

### 2.5 Rim block — `{P}RimEnabled/Depth/Width/Smoothness`
A *second*, independent bevel confined to a thin band right at the shape's outline (uses the live SDF distance, so it correctly follows non-circular Knob shapes, not just circles). Purely a normal/lighting effect — it does not change color, only how the outermost ring of pixels catches light. `RimDepth` sign: positive = raised rim, negative = recessed.

### 2.6 Material Pattern block — `{P}PatternEnabled/Type/Scale/Intensity/Contrast/SpecularEffect/RoughnessEffect/RotateEnabled/ModEnabled/ModAmount/ModFrequency/Offset/Param1-3`
The main procedural surface finish over the whole component face (not scoped to the bevel).
- **`{P}PatternType`** (`[Enum(PatternType)]`, values 0–19) — see the full table in §4.4. 20 pure-procedural materials (Plastic, Metal, brushed finishes, Concrete/Fabric/Paper/Frosted, geometric patterns, wood/marble/ceramic, Circuit/NoiseOrganic).
- **`{P}PatternScale`**: spatial frequency. Sampled in a **normalized `[-0.5, 0.5]` local-UV space** (`UIPatterns.cginc` line 74: "pos: rotated position relative to center ([-0.5, 0.5] range)") — **not pixels**. See the pixel-size gotcha in §6.
- **`{P}PatternIntensity`**: multiplies the raw pattern signal before it's used (`pattern = SamplePatternValue(...) * patternIntensity`).
- **`{P}PatternContrast`**: gamma-curve applied to the pattern value (pattern-specific; see individual `Sample*` functions in `UIPatterns.cginc`).
- **`{P}PatternSpecularEffect`**: how much the pattern's local value modulates the specular highlight strength.
- **`{P}PatternRoughnessEffect`**: scales a **screen-space-derivative** normal offset (`float2(-ddx(pattern), -ddy(pattern)) * roughnessEffect`) — this is what actually makes the pattern look "bumpy" under lighting, and it is a per-pixel derivative, so it can alias/vanish at small on-screen sizes (see §6).
- **`{P}PatternOffset`**: static rotation of the pattern sampling, in **degrees**.
- **`{P}PatternRotateEnabled`**: when `> 0.5`, adds `currentValue * angleRange` degrees to the pattern rotation every frame — i.e. **the pattern visually spins together with `_Value`** (for Knob/Nub components this is passed `_Value, _AngleRange`; for Fill it's passed `0.0, 0.0` so Fill's pattern never rotates with value regardless of this flag — see §3.1). Verified `UIPatterns.cginc:816-819`.
- **`{P}PatternModEnabled` / `ModAmount` / `ModFrequency`**: **mutually exclusive with `RotateEnabled`** — the code is `if (RotateWithValue) {...} else if (ModWithValue) {...}` (`UIPatterns.cginc:817-823`). When Rotate is on, Mod never fires even if its own flag is 1. When active (Rotate off, Mod on): adds `sin(_Value·2π·ModFrequency) · ModAmount` degrees — a value-driven oscillating "shimmer" rotation, amplitude `ModAmount` degrees, `ModFrequency` full cycles across the 0→1 value range.
- **`{P}PatternParam1/2/3`** (displayed as "Detail" / "Distortion" / "Blend"): generic 0–1 tuning knobs whose exact meaning is defined per `PatternType` inside the individual `Sample*` functions in `UIPatterns.cginc` (e.g. for Plastic: Param1=octave count, Param2=domain-warp amount, Param3=metallic-flake sparkle). Not re-derived per pattern type in this doc — read `UIPatterns.cginc` directly if a specific pattern's exact response matters.

### 2.7 Pattern Color Type — `PatternColorType` enum (0–3)
How the pattern's scalar signal indexes into the A/B/C/D palette (verified `UIPatterns.cginc:59-62`, mirrored `ShaderConstants.cs:224-230`):
| Value | Name | Meaning |
|---|---|---|
| 0 | `Gradient` | Signed range [-1,+1] → negative = color A, zero = mid, positive = color D |
| 1 | `Feature` | Feature strength → flat surface = A, peak feature = D |
| 2 | `Zones` | Repeating palette cycles — distinct coloring per feature instance (e.g. each grain/cell gets a different palette entry) |
| 3 | `Bands` | Sine-wave banding — rings/veins/layered look |

### 2.8 Pattern Color Mode — `PatternColorMode` enum (0–3)
How the palette-indexed color combines with the pattern's base color (`ShaderConstants.cs:215-221`):
| Value | Name | Meaning |
|---|---|---|
| 0 | `Modulate` | Palette color brightness-modulated by pattern strength |
| 1 | `Lerp` | Base color blends toward the palette color at strong pattern features |
| 2 | `Additive` | Palette color added at strong positive features |
| 3 | `Multiply` | Palette color tints/darkens the base color |

### 2.9 Gradient block — `{P}GradientEnabled/Type`, `{P}GradientColorA-D`, `{P}GradientDirection/Speed/Scale/Offset`, `{P}GlobalBlend/GlobalIntensity`, `{P}GradientColorUsed`
Replaces the component's flat base color with a 2–4 stop gradient before pattern/lighting are applied.
- **`{P}GradientType`** — see §4.5 for the full enum, including two RM-only bevel-topology types.
- **`{P}GradientDirection`**: only the `.xy` is used; only meaningful for `Linear`/`Triangle` types.
- **`{P}GradientSpeed`**: **the gradient position animates continuously** — `CalculateGradient` (the function actually called by SDFKnob, `UIRenderer.cginc:13-19`) computes `gradientPos` from `time * speed`, with no "manual/static position" fallback. **A nonzero default Speed (most default to `1.0`) means enabling any Gradient block makes it visibly scroll/animate**, not sit static — see §6 gotcha.
- **`{P}GradientScale`/`Offset`**: spatial frequency / phase shift of the gradient pattern.
- **`{P}GlobalBlend`/`GlobalIntensity`**: blends toward the shared cross-widget "global gradient" (`_GlobalGradientColorA-D` etc., set once for the whole screen via `UIGlobalUniforms.cginc`) instead of this component's own A-D stops — `0 = pure local gradient`, `>0 = blend toward the screen-wide look`.
- **`{P}GradientColorUsed`** (`[IntRange] Range(2,4)`): how many of A–D are actually interpolated between (2, 3, or 4-stop).

---

## 3. Complete property table (every property, by component, in render order)

Legend for the **What it does** column: `→ §2.x` means "identical semantics to the shared sub-block described in §2.x — only the Range/Default differ, shown in this row."

### 3.0 Core geometry / value (not owned by any single component)

| Name | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_MainTex` | 2D (`[PerRendererData]`) | — | white | Standard UGUI sprite slot. Never sampled for SDF math; exists only so Unity's UI raycast/atlas system is happy. |
| `_LineRadius` | Range | 0.1 – 1.0 | 0.3 | Normalized radius (fraction of the control's half-extent) where **Fill** ends and **Line** begins. Also the base multiplier for `knobRadius = _LineRadius * _KnobSize`. |
| `_LineWidth` | Range | 0.01 – 0.5 | 0.1 | Thickness of the **Line** track ring. Also feeds `extendedLineWidth`/`lineOuterRadius`, the outer culling radius for the whole widget. |
| `_AngleStart` | Float (unbounded) | — | 0 | Sweep start angle, **degrees, UI convention** — see §5 for the exact (non-obvious) zero reference and direction. |
| `_AngleRange` | Float (unbounded) | — | 270 | Total sweep in degrees from `_AngleStart`. Can exceed 360 or be negative; `ArcSDF`/mark code doesn't clamp it. |
| `_Value` | Range | 0 – 1 | 0.5 | The knob's value. Drives: value-arc fill fraction, knob body rotation, Nub/KnobNub angular position, scale-mark fill coloring, and (optionally) pattern rotation on any component with `PatternRotateEnabled`. |
| `_LineRoundedEnabled` | Float (0/1) | — | 1 | Rounded end-caps on **every** arc segment drawn with `ArcSDF` — Line, Value Filled, Value Unfilled, and (if used at those radii) Outer Rings. Set to 0 for hard-cut flat ends. |
| `_Position` | Vector | — | (0,0,0,0) | Set per-instance by the UI system for global-light-direction math; not something a `.states.json` skin should touch. |

### 3.1 Fill (`_Fill*`) — center disc, static, drawn 5th

| Name | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_FillEnabled` | Float | — | 1 | Master switch — see §4.1. |
| `_FillColor` | Color | — | (0.2,0.4,0.8,1) | Base color. |
| `_FillRenderAlpha` | Range | 0–1 | 1 | Alpha multiplier at composite time (`fillMask * fillComponent.alpha`). |
| `_FillRenderEmissive` | Range | 0–1 | 0 | Adds `baseColor * fillMask * emissive` on top, additively, bypassing lighting/alpha (see §4.1 emissive note). |
| `_FillBevelEnabled` | Float | — | 0 | → §2.1 |
| `_FillBevelDepth` | Range | -1.0–1.0 | 0.2 | → §2.1 |
| `_FillBevelSmoothness` | Range | 0.001–1.0 | 0.02 | → §2.1 |
| `_FillBevelDistance` | Range | 0.001–1.0 | 0.1 | → §2.1 |
| `_FillFaceSmoothness` | Range | -1.0–1.0 | 0.0 | → §2.1 |
| `_FillBevelPatternEnabled` | Float | — | 0 | → §2.2 |
| `_FillBevelPatternType` | Int `[Enum(PatternType)]` | 0–19 | 0 | → §2.2, §4.4 |
| `_FillBevelPatternScale` | Range | 1–100 | 20 | → §2.2 |
| `_FillBevelPatternIntensity` | Range | 0–1 | 0.3 | → §2.2 |
| `_FillBevelPatternContrast` | Range | 0.1–5 | 1.5 | → §2.2 |
| `_FillBevelPatternSpecularEffect` | Range | 0–2 | 1.0 | → §2.2 |
| `_FillBevelPatternRoughnessEffect` | Range | 0–2 | 0.3 | → §2.2 |
| `_FillBevelPatternParam1` (Detail) | Range | 0–1 | 0.5 | → §2.2 |
| `_FillBevelPatternParam2` (Distortion) | Range | 0–1 | 0.5 | → §2.2 |
| `_FillBevelPatternParam3` (Blend) | Range | 0–1 | 0.5 | → §2.2 |
| `_FillBevelPatternColorEnabled` | Float | — | 0 | → §2.3 |
| `_FillBevelPatternColorType` | Int `[Enum(PatternColorType)]` | 0–3 | 2 (Zones) | → §2.3, §2.7 |
| `_FillBevelPatternColorMode` | Int `[Enum(PatternColorMode)]` | 0–3 | 1 (Lerp) | → §2.3, §2.8 |
| `_FillBevelPatternColorUsed` | Int `[IntRange]` | 2–4 | 2 | → §2.3 |
| `_FillBevelPatternColorA` | Color | — | (1,1,1,1) | → §2.3 |
| `_FillBevelPatternColorB` | Color | — | (0.5,0.5,0.5,1) | → §2.3 |
| `_FillBevelPatternColorC` | Color | — | (0.3,0.3,0.3,1) | → §2.3 |
| `_FillBevelPatternColorD` | Color | — | (0.1,0.1,0.1,1) | → §2.3 |
| `_FillBevelGradientEnabled` | Float | — | 0 | → §2.4 |
| `_FillBevelGradientType` | Int `[Enum(GradientType)]` | 0–4 (+5,6 RM/Knob-only, not meaningful here) | 1 (Radial) | → §2.4, §4.5 |
| `_FillBevelGradientColorA` | Color | — | (1,1,1,1) | → §2.4 |
| `_FillBevelGradientColorB` | Color | — | (0.5,0.5,0.5,1) | → §2.4 |
| `_FillBevelGradientColorC` | Color | — | (0.3,0.3,0.3,1) | → §2.4 |
| `_FillBevelGradientColorD` | Color | — | (0.1,0.1,0.1,1) | → §2.4 |
| `_FillBevelGradientDirection` | Vector | — | (1,0,0,0) | → §2.4 |
| `_FillBevelGradientSpeed` | Float | — | 1.0 | → §2.4 (animates — see §6) |
| `_FillBevelGradientScale` | Range | 0.1–5 | 1.0 | → §2.4 |
| `_FillBevelGradientOffset` | Range | -2–2 | 0.0 | → §2.4 |
| `_FillBevelGradientColorUsed` | Int `[IntRange]` | 2–4 | 4 | → §2.4 |
| `_FillRimEnabled` | Float | — | 0 | → §2.5 |
| `_FillRimDepth` | Range | -0.5–0.5 | 0.1 | → §2.5 |
| `_FillRimWidth` | Range | 0.001–0.1 | 0.02 | → §2.5 |
| `_FillRimSmoothness` | Range | 0.001–0.1 | 0.01 | → §2.5 |
| `_FillPatternEnabled` | Float | — | 0 | → §2.6 |
| `_FillPatternType` | Int `[Enum(PatternType)]` | 0–19 | 0 (Plastic) | → §2.6, §4.4 |
| `_FillPatternScale` | Range | 1–100 | 20 | → §2.6 |
| `_FillPatternIntensity` | Range | 0–1 | 0.3 | → §2.6 |
| `_FillPatternContrast` | Range | 0.1–5 | 1.5 | → §2.6 |
| `_FillPatternSpecularEffect` | Range | 0–2 | 1.0 | → §2.6 |
| `_FillPatternRoughnessEffect` | Range | 0–2 | 0.3 | → §2.6 |
| `_FillPatternRotateEnabled` | Float | — | 0 | → §2.6, but **Fill is called with `(currentValue=0.0, angleRange=0.0)`** (`SDFKnob.shader:1362-1363`) — this flag is a **no-op on Fill**; it can never rotate with value regardless of setting. |
| `_FillPatternModEnabled` | Float | — | 0 | → §2.6 (only matters if RotateEnabled is 0; and since Fill's `currentValue` is always 0, `ModAmount·sin(0)=0` too — **Fill's pattern rotation is effectively always static**, only `_FillPatternOffset` has any effect) |
| `_FillPatternModAmount` | Range | 0–90 | 20 | → §2.6 (see note above — dead on Fill) |
| `_FillPatternModFrequency` | Range | 0.1–10 | 1 | → §2.6 (see note above — dead on Fill) |
| `_FillPatternOffset` | Range | -180–180 | 0 | → §2.6 |
| `_FillPatternParam1` (Detail) | Range | 0–1 | 0.5 | → §2.6 |
| `_FillPatternParam2` (Distortion) | Range | 0–1 | 0.5 | → §2.6 |
| `_FillPatternParam3` (Blend) | Range | 0–1 | 0.5 | → §2.6 |
| `_FillPatternColorEnabled` | Float | — | 0 | → §2.7/§2.8 |
| `_FillPatternColorType` | Int `[Enum(PatternColorType)]` | 0–3 | 2 (Zones) | → §2.7 |
| `_FillPatternColorMode` | Int `[Enum(PatternColorMode)]` | 0–3 | 1 (Lerp) | → §2.8 |
| `_FillPatternColorUsed` | Int `[IntRange]` | 2–4 | 2 | → §2.6 |
| `_FillPatternColorA` | Color | — | (1,1,1,1) | → §2.6 |
| `_FillPatternColorB` | Color | — | (0.5,0.5,0.5,1) | → §2.6 |
| `_FillPatternColorC` | Color | — | (0.3,0.3,0.3,1) | → §2.6 |
| `_FillPatternColorD` | Color | — | (0.1,0.1,0.1,1) | → §2.6 |
| `_FillGradientEnabled` | Float | — | 0 | → §2.9 |
| `_FillGradientType` | Int `[Enum(GradientType)]` | 0–4 | 0 (Linear) | → §2.9, §4.5 |
| `_FillGradientColorA` | Color | — | (1,0,0,1) red | → §2.9 |
| `_FillGradientColorB` | Color | — | (0,1,0,1) green | → §2.9 |
| `_FillGradientColorC` | Color | — | (0,0,1,1) blue | → §2.9 |
| `_FillGradientColorD` | Color | — | (1,1,0,1) yellow | → §2.9 (RGB+Y placeholder defaults — always looks like a rainbow test pattern until a skin author overrides them) |
| `_FillGradientDirection` | Vector | — | (1,0,0,0) | → §2.9 |
| `_FillGradientSpeed` | Float | — | 1.0 | → §2.9 (**animates by default** — see §6) |
| `_FillGradientScale` | Range | 0.1–5 | 1.0 | → §2.9 |
| `_FillGradientOffset` | Range | -2–2 | 0.0 | → §2.9 |
| `_FillGlobalBlend` | Range | 0–1 | 0.0 | → §2.9 |
| `_FillGlobalIntensity` | Range | 0–2 | 1.0 | → §2.9 |
| `_FillGradientColorUsed` | Int `[IntRange]` | 2–4 | 4 | → §2.9 |

### 3.2 Line / track (`_Line*` component props — not to be confused with `_LineRadius`/`_LineWidth` in §3.0 or `_LineSubline*` in §3.3/3.4) — the arc ring, drawn 6th

Same 8 sub-blocks as Fill, same names with `Line` prefix. Only rows whose **numeric range/default differs from Fill's equivalent** are called out; the rest follow the identical pattern (`_LineEnabled/_LineColor/_LineRenderAlpha/_LineRenderEmissive`, then Bevel/BevelPattern/BevelPatternColor/BevelGradient/Rim/Pattern/PatternColor/Gradient, all with a `Line` prefix in place of `Fill`).

| Name | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_LineEnabled` | Float | — | 1 | Master switch — see §4.1. |
| `_LineColor` | Color | — | (0.8,0.8,0.8,1) | Base color of the track. |
| `_LineRenderAlpha` | Range | 0–1 | 1 | → §3.1 pattern |
| `_LineRenderEmissive` | Range | 0–1 | 0 | → §3.1 pattern |
| `_LineBevelDepth` | Range | -1.0–1.0 | **0.05** (Fill: 0.2) | → §2.1 |
| `_LineBevelSmoothness` | Range | **0.001–3.0** (Fill: 0.001–1.0) | 0.02 | → §2.1 — note the much wider allowed range vs. Fill. |
| `_LineBevelDistance` | Range | 0.001–1.0 | 0.1 | → §2.1 |
| `_LineFaceSmoothness` | Range | -1.0–1.0 | 0.0 | → §2.1 |
| `_LineBevelPattern*` (9 props: Enabled/Type/Scale/Intensity/Contrast/SpecularEffect/RoughnessEffect/Param1/Param2/Param3) | — | identical ranges/defaults to `_FillBevelPattern*` | — | → §2.2 |
| `_LineBevelPatternColor*` (7 props) | — | identical to Fill's | — | → §2.3 |
| `_LineBevelGradient*` (11 props) | — | identical to Fill's | — | → §2.4 |
| `_LineRimEnabled/Depth/Width/Smoothness` | — | identical to Fill's | — | → §2.5 |
| `_LinePattern*` (14 props incl. RotateEnabled/ModEnabled/ModAmount/ModFrequency/Offset/Param1-3) | — | identical ranges to Fill's `_FillPattern*` | — | → §2.6. **Unlike Fill, Line's `ApplyMaterialPattern` call also passes `(_Value, _AngleRange)`** (`SDFKnob.shader:1459`) — so `_LinePatternRotateEnabled`/`_LinePatternModEnabled` **do work** on the Line track, rotating/shimmering its pattern as the knob turns even though the Line ring itself never rotates geometrically. |
| `_LinePatternColor*` (7 props) | — | identical to Fill's | — | → §2.7/§2.8 |
| `_LineGradient*` (13 props) | — | identical to Fill's | — | → §2.9 |

### 3.3 Value Filled (`_LineSublineFilled*`) — the "progress" arc, drawn 8th (on top of Unfilled)

Same 8 sub-blocks again, prefix `LineSublineFilled`. Geometry: an arc of radius `_LineRadius + _LineWidth*0.5`,
thickness `_LineWidth * _LineSublineThickness`, spanning `_AngleStart` → `_AngleStart + _AngleRange*_Value`.

| Name | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_LineSublineFilledEnabled` | Float | — | 1 | Master switch. |
| `_LineSublineFilledColor` | Color | — | (0.2,0.8,0.2,1) green | Base color of the filled arc. |
| `_LineSublineFilledRenderAlpha` | Range | 0–1 | 1.0 | → §3.1 pattern |
| `_LineSublineFilledRenderEmissive` | Range | 0–1 | 0 | → §3.1 pattern |
| `_LineSublineFilledBevelDepth` | Range | -1.0–1.0 | **0.03** | → §2.1 |
| `_LineSublineFilledBevelSmoothness` | Range | **0.001–0.2** | 0.02 | → §2.1 |
| `_LineSublineFilledBevelDistance` | Range | 0.001–1.0 | 0.1 | → §2.1 |
| `_LineSublineFilledFaceSmoothness` | Range | -1.0–1.0 | 0.0 | → §2.1 |
| `_LineSublineFilledBevelPattern*` (9 props) | — | same shape as §2.2 | — | → §2.2 |
| `_LineSublineFilledBevelPatternColor*` (7 props) | — | same shape as §2.3 | — | → §2.3 |
| `_LineSublineFilledBevelGradient*` (11 props) | — | same shape as §2.4 | — | → §2.4 |
| `_LineSublineFilledRim*` (4 props) | — | same shape as §2.5 | — | → §2.5 |
| `_LineSublineFilledPattern*` (14 props) | — | `PatternSpecularEffect` default is **0.5** here (others default 1.0) | — | → §2.6. Called with `(_Value, _AngleRange)` (`SDFKnob.shader:1607`) — Rotate/Mod work here too. |
| `_LineSublineFilledPatternColor*` (7 props) | — | same shape as §2.7/§2.8 | — | → §2.7/§2.8 |
| `_LineSublineFilledGradient*` (13 props) | — | same shape as §2.9 | — | → §2.9 |

**Glow (unique to Value Filled, not part of the shared sub-block set):**

| Name | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_LineSublineGlowEnabled` | Float | — | 0 | Outer glow extending *outward* from the Value Filled arc's own outline (uses `filledDist`, the same `ArcSDF` distance as the fill mask). Rendered **outside** the `filledMask` check so it can bleed past the arc's own edge (`SDFKnob.shader:1633-1637`). |
| `_LineSublineGlowColor` | Color | — | (0.3,0.6,1.0,0.5) | Glow color/alpha. |
| `_LineSublineGlowWidth` | Range | 0.001–0.5 | 0.02 | Distance from the edge (world units) where the glow is at full intensity before it starts fading. |
| `_LineSublineGlowSoftness` | Range | 0–1.0 | 0.05 | Additional fade-out distance beyond `GlowWidth`. |
| `_LineSublineGlowIntensity` | Range | 0–2 | 1.0 | Multiplies the glow mask before compositing. |
| `_LineSublineGlowRenderAlpha` | Range | 0–1 | 1 | Alpha multiplier at composite. |
| `_LineSublineGlowRenderEmissive` | Range | 0–1 | 0 | Additive emissive contribution. |
| `_LineSublineThickness` | Range | 0.1–1.0 | 0.5 | **Shared by both Filled and Unfilled** — fraction of `_LineWidth` used as the value-arc ring's thickness. Not per-Filled/Unfilled; one knob controls both. |

### 3.4 Value Unfilled (`_LineSublineUnfilled*`) — background half of the value arc, drawn 7th (before Filled)

Same structure as 3.3, prefix `LineSublineUnfilled`, geometry spans `_AngleStart+_AngleRange*_Value` → `_AngleStart+_AngleRange` (the remainder). No glow block (glow only exists for Filled).

| Name | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_LineSublineUnfilledEnabled` | Float | — | 1 | Master switch. |
| `_LineSublineUnfilledColor` | Color | — | (0.3,0.3,0.3,1) grey | Base color. |
| `_LineSublineUnfilledRenderAlpha` | Range | 0–1 | 1.0 | → §3.1 pattern |
| `_LineSublineUnfilledRenderEmissive` | Range | 0–1 | 0 | → §3.1 pattern |
| `_LineSublineUnfilledBevelDepth` | Range | -1.0–1.0 | **0.02** | → §2.1 |
| `_LineSublineUnfilledBevelSmoothness` | Range | 0.001–0.2 | 0.02 | → §2.1 |
| `_LineSublineUnfilledBevelDistance` | Range | 0.001–1.0 | 0.1 | → §2.1 |
| `_LineSublineUnfilledFaceSmoothness` | Range | -1.0–1.0 | 0.0 | → §2.1 |
| `_LineSublineUnfilledBevelPattern*` (9) / `BevelPatternColor*` (7) / `BevelGradient*` (11) / `Rim*` (4) | — | same shapes as §2.2–§2.5 | — | → §2.2–§2.5 |
| `_LineSublineUnfilledPattern*` (14) | — | `PatternSpecularEffect` default **0.5** (as Filled) | — | → §2.6, called with `(_Value, _AngleRange)`. |
| `_LineSublineUnfilledPatternColor*` (7) / `Gradient*` (13) | — | same shapes as §2.7–§2.9 | — | → §2.7–§2.9 |

### 3.5 Knob body (`_Knob*`) — the rotating shape, drawn 9th

This is the most complex component: base shape params, an optional independent **face shape**, then the full 8-block set, plus knob-only shadow/edge/nub groups. Rotation angle: `(_AngleStart + _AngleRange*_Value + _KnobRotation)` degrees — see §5 for the exact geometric meaning.

**Shape & geometry:**

| Name | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_KnobEnabled` | Float | — | 1 | Master switch — gates the whole component **and** `_KnobNubEnabled`, `_KnobEdgeEnabled`, and knob cast shadows. |
| `_KnobColor` | Color | — | (0.9,0.9,0.9,1) | Base face color. |
| `_KnobRenderAlpha` | Range | 0–1 | 1.0 | Alpha multiplier. |
| `_KnobRenderEmissive` | Range | 0–1 | 0 | Additive emissive. |
| `_KnobSize` | Range | 0.1–1.0 | 0.8 | `knobRadius = _LineRadius * _KnobSize` — knob radius as a fraction of the Fill radius. |
| `_KnobShapeType` | Int `[Enum(KnobShapeType)]` | 0–21, 100 | 0 (Circle) | Which of 22 body-shape SDFs (+texture) to draw. **Full enumeration in §4.1.** |
| `_KnobShapeScale` | Range | 1–20 | 6 | Multi-purpose "count" parameter — sides (Polygon), grip-nub count, tooth count (Gear), hub sides (ColletKnob), point count (Star/BlobStar), flute count (Fluted). Ignored by shapes that don't use a count. |
| `_KnobShapeRotation` | Range | -180–180 | 0 | Rotation (deg) of the shape's own local silhouette, applied *before* the value-driven knob rotation (independent axis from `_KnobRotation`). |
| `_KnobShapeParam1` | Range | 0–1 | 0.5 | Per-shape tuning slot 1 — meaning depends on `_KnobShapeType`, see §4.1's per-shape comments. |
| `_KnobShapeParam2` | Range | 0–1 | 0.5 | Per-shape tuning slot 2. |
| `_KnobShapeParam3` | Range | 0–1 | 0.5 | Per-shape tuning slot 3. |
| `_KnobShapeParam4` | Range | 0–1 | 0.5 | Declared and passed to `getKnobSDF` for every shape, but **no shape in `KnobShapes/*.cginc` currently reads `param4`** (all take only `param1-3`). Currently a no-op regardless of `_KnobShapeType`. |
| `_KnobShapeParam5` | Range | 0–1 | 0.5 | Same as Param4 — declared, passed through, unread by any implemented shape. No-op. |
| `_KnobShapeParam6` | Range | 0–1 | 0.5 | Same — no-op. |
| `_KnobRoundness` | Range | 0–1 | 0 | Universal post-SDF corner/edge softening applied to **every** shape type uniformly: `rawSDF - min(_KnobRoundness * radius * 0.15, radius * 0.4)` (`SDFKnobShapes.cginc:103-104`). Effectively inflates+rounds the silhouette; capped at 40% of the radius no matter how high the value goes. |
| `_KnobShapeTexLayer` | Float | — | -1 | Texture2DArray layer index used only when `_KnobShapeType = 100` (Texture). `-1` disables texture sampling. |
| `_KnobShapeTexScale` | Vector | — | (1,1,0,0) | UV scale for the texture-SDF sample; only `.xy` used. |
| `_KnobRotation` | Range | -180–180 | 0 | Manual rotation offset (deg), **added on top of the value-driven angle**, applied to both the knob body *and* the KnobNub orbit. This is the primary tool for aligning a shape's built-in "pointing" feature with the arc's zero reference — see §5/§6. |

**Face shape (independent inner boundary / 3D top face):**

| Name | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_KnobFaceShapeEnabled` | Float | — | 0 | When 0: the bevel's inner boundary is simply the outer shape inset by `_KnobBevelDistance` (classic behaviour). When 1: the inner/top face is an **independently shaped, independently sized and rotated** silhouette — can even protrude past the outer shape (code takes the `min()`/union of both). |
| `_KnobFaceShapeType` | Int `[Enum(KnobShapeType)]` | 0–21, 100 | 0 (Circle) | Same enum/dispatcher as `_KnobShapeType` — full range available for the face too. |
| `_KnobFaceShapeScale` | Range | 1–20 | 6 | Same meaning as `_KnobShapeScale`, for the face shape. |
| `_KnobFaceShapeSize` | Range | 0.01–1.0 | 0.7 | Face radius as a fraction of `knobRadius`. **Lower = more visible wall/bevel width** (the gap between the outer silhouette and the smaller inset face). |
| `_KnobFaceShapeRotation` | Range | -180–180 | 0 | Local rotation of the face shape's own silhouette. |
| `_KnobFaceShapeParam1-6` | Range | 0–1 | 0.5 each | Same per-shape semantics as `_KnobShapeParam1-6` (Param4-6 are also no-ops here for the same reason). |
| `_KnobFaceShapeTexLayer` | Float | — | -1 | Texture layer for the face shape when `_KnobFaceShapeType = 100`. |
| `_KnobFaceShapeTexScale` | Vector | — | (1,1,0,0) | UV scale for the face's texture SDF. |

**Bevel / Bevel Pattern / Bevel Pattern Color / Bevel Gradient / Rim / Pattern / Pattern Color / Gradient — same 8 shared sub-blocks as Fill (§2), prefix `Knob`:**

| Name | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_KnobBevelEnabled` | Float | — | 0 | → §2.1 |
| `_KnobBevelDepth` | Range | **-4.0–4.0** (Fill: -1..1) | 0.1 | → §2.1 — much larger allowed range, since it also has to reach RM's true 3D bevel heights (see §3.6). |
| `_KnobBevelSmoothness` | Range | 0.001–0.2 | 0.02 | → §2.1 |
| `_KnobBevelDistance` | Range | 0.001–1.0 | 0.1 | → §2.1 |
| `_KnobFaceSmoothness` | Range | -1.0–1.0 | 0.0 | → §2.1 |
| `_KnobBevelProfileType` | Int `[Enum(BevelProfileType)]` | 0–1 | 0 (Dome) | → §2.1 |
| `_KnobBevelProfileSharpness` | Range | 0–1 | 0.5 | → §2.1 |
| `_KnobBevelPattern*` (9 props), `BevelPatternColor*` (7), `BevelGradient*` (11) | — | same shapes as §2.2–§2.4 | — | → §2.2–§2.4 |
| `_KnobRimEnabled/Depth/Width/Smoothness` | — | same shape as §2.5 | — | → §2.5 |
| `_KnobPattern*` (14 props) | — | same shape as §2.6, but **`_KnobPatternRotateEnabled` defaults to `1`** (every other component defaults to 0) | — | → §2.6 — knob material patterns rotate with value out of the box. |
| `_KnobPatternColor*` (7) | — | same shape as §2.7/§2.8 | — | → §2.7/§2.8 |
| `_KnobGradient*` (13) | — | same shape as §2.9 | — | → §2.9 |

### 3.6 KnobEdge (`_KnobEdge*`) — indent ring around the knob's base, under the knob

Renders an inward-fading gradient at `max(0, knobShapeSDF + _KnobEdgeInset)`, i.e. it traces the **base shape's own outline** (not a circle), and is drawn *before* the knob body so it looks like a routed groove the knob sits in.

| Name | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_KnobEdgeEnabled` | Float | — | 0 | Master switch — see §4.1. |
| `_KnobEdgeColor` | Color | — | (0,0,0,0.8) | Base color/alpha of the indent. |
| `_KnobEdgeRenderAlpha` | Range | 0–1 | 1 | Alpha multiplier. |
| `_KnobEdgeWidth` | Range | 0.001–0.2 | 0.05 | How far out from the knob's edge the indent extends. |
| `_KnobEdgeInset` | Range | -0.1–0.1 | 0.0 | Shifts the indent's inner starting radius in/out relative to the knob's own silhouette. |
| `_KnobEdgeSoftness` | Range | 0–2 | 0.0 | 0 = sharp `smoothstep` cutoff at `_KnobEdgeWidth`; >0 = power-curve softened falloff (see `calculateEdgeIndent`/inline duplicate for the same math). |
| `_KnobEdgeIntensity` | Range | 0–2 | 1.0 | Multiplies the computed mask before compositing (can push past 1 for a harder edge). |
| `_KnobEdgeRenderEmissive` | Range | 0–1 | 0 | Additive emissive contribution. |
| `_KnobEdgeGradientEnabled` | Float | — | 0 | → §2.9 shape |
| `_KnobEdgeGradientType` | Int `[Enum(GradientType)]` | 0–6 | 0 (Linear) | → §2.9, §4.5 |
| `_KnobEdgeGradientColorA-D` | Color | — | R/G/B/Y | → §2.9 |
| `_KnobEdgeGradientDirection/Speed/Scale/Offset` | — | — | (1,0,0,0)/1/1/0 | → §2.9 |
| `_KnobEdgeGlobalBlend/GlobalIntensity` | Range | 0–1 / 0–2 | 0/1 | → §2.9 |
| `_KnobEdgeGradientColorUsed` | Int `[IntRange]` | 2–4 | 4 | → §2.9 |

### 3.7 KnobNub (`_KnobNub*`) — shape orbiting the knob's own face center, requires `_KnobEnabled`

Uses **`getKnobSDF`** (the full Knob shape dispatcher, §4.1) — not the more limited Nub dispatcher (§4.2). Orbit radius is `_KnobNubDistance × knobRadius`, angle uses the **same atan2 remap as the arc** (§5), offset by `_KnobRotation` so it tracks the knob body's rotation.

| Name | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_KnobNubEnabled` | Float | — | 0 | Master switch (also requires `_KnobEnabled`). |
| `_KnobNubColor` | Color | — | (1,1,1,1) | Base color. |
| `_KnobNubRenderAlpha` | Range | 0–1 | 1.0 | Alpha multiplier. |
| `_KnobNubSize` | Range | 0.005–0.5 | 0.08 | Radius passed to `getKnobSDF` — absolute world-space size, not relative to knob radius. |
| `_KnobNubDistance` | Range | 0–1 (base) / **0–2 (RM)** | 0.5 | Orbit distance as a multiple of `knobRadius`. Note the RM shader widens the allowed range to 2 (nub can sit twice as far out as the knob's own radius); base shader caps at 1. |
| `_KnobNubShapeType` | Int `[Enum(KnobShapeType)]` | 0–21, 100 | 0 (Circle) | Full Knob-shape enum — see §4.1. |
| `_KnobNubShapeScale` | Range | 1–20 | 6 | Same "count" semantics as `_KnobShapeScale`. |
| `_KnobNubShapeRotation` | Range | -180–180 | 0 | Local rotation of the nub's own shape, applied after it's oriented radially outward. |
| `_KnobNubShapeParam1-3` | Range | 0–1 | 0.5 each | Per-shape tuning (only 3 slots here, not 6 — params 4-6 are hardcoded to `0.5` in the `getKnobSDF` call at `SDFKnob.shader:2147-2149`, not exposed as properties). |
| `_KnobNubBevelEnabled` | Float | — | 0 | → §2.1 (KnobNub only has the Bevel block, no Pattern/Gradient/Rim/PatternColor sub-blocks). |
| `_KnobNubBevelDepth` | Range | -1.0–1.0 | 0.5 | → §2.1 |
| `_KnobNubBevelSmoothness` | Range | 0.001–0.2 | 0.02 | → §2.1 |
| `_KnobNubBevelDistance` | Range | 0.001–1.0 | 0.1 | → §2.1 |
| `_KnobNubFaceSmoothness` | Range | -1.0–1.0 | 0.0 | → §2.1 |

### 3.8 Nub (`_Nub*`) — independent rotatable pointer, drawn 10th

Uses **`getNubSDF`**, a **different and much more limited** dispatcher than Knob/KnobNub — see the critical gotcha in §4.2/§6. Position: `_NubDistance` along the arc angle (`_AngleStart + _AngleRange*_Value + _NubRotation`, same atan2 remap as §5), oriented radially outward, then further rotated by `_NubShapeRotation`.

| Name | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_NubEnabled` | Float | — | 0 | Master switch. |
| `_NubColor` | Color | — | (1,1,1,1) | Base color. |
| `_NubRenderAlpha` | Range | 0–1 | 1 | Alpha multiplier. |
| `_NubRenderEmissive` | Range | 0–1 | 0 | Additive emissive. |
| `_NubDistance` | Range | 0–1 | 0.4 | Orbit distance from widget center, in the same `[-1,1]` world space as `_LineRadius` (i.e. `0.4` sits inside the Fill circle unless `_LineRadius` is smaller). |
| `_NubRotation` | Range | -180–180 | 0 | Added to the value-driven angle before computing the Nub's *position* (not its own shape rotation — see `_NubShapeRotation`). |
| `_NubShapeType` | Int `[Enum(NubShapeType)]` | 0–19 (enum) but **only 0–4 actually implemented** | 0 (Circle) | See the critical gotcha in §4.2 — values 5-19 silently render as a circle. |
| `_NubSizeWidth` | Range | 0.01–2.5 | 0.1 | Width passed to `getNubSDF`. |
| `_NubSizeHeight` | Range | 0.01–2.5 | 0.05 | Height passed to `getNubSDF`. |
| `_NubRounding` | Range | 0–0.1 | 0.01 | Corner radius — **only used when `_NubShapeType = 2` (RoundedRect)**, passed as `param1`. No effect on any other shape (each shape reads its own `param1` meaning; Circle/Rectangle/Ellipse/Triangle ignore it entirely). |
| `_NubShapeParam1` | Range | 0–1 | 0.5 | Shape-specific; for RoundedRect this duplicates/overrides via the same `param1` slot as `_NubRounding` is *not* wired the same way — **`_NubRounding` is passed as the literal `param1` argument to `getNubSDF`** (`SDFKnob.shader:1985`, `_NubShapeParam1/2/3` are declared as separate properties but the actual call only forwards `_NubShapeParam1/2/3`, not `_NubRounding`, for the bevel-normal recompute at line 2083 — both call sites use `_NubShapeParam1/2/3`, not `_NubRounding`). Practically: **`_NubRounding` has no verified effect in this codebase** — grep shows it declared as a property but never referenced inside the fragment shader body. Treat as currently non-functional; use `_NubShapeParam1` for RoundedRect corner radius instead. |
| `_NubShapeParam2` | Range | 0–1 | 0.5 | Shape-specific, unused by shapes 0/1/3/4 (Circle/Rectangle/Ellipse/Triangle take no param2). |
| `_NubShapeParam3` | Range | 0–1 | 0.5 | Shape-specific, unused by shapes 0-4 entirely (none of the 5 implemented cases read param3). |
| `_NubShapeRotation` | Range | -180–180 | 0 | Rotates the nub's own shape silhouette, applied *after* the radial-outward orientation. |
| `_NubBevelEnabled` | Float | — | 0 | → §2.1 |
| `_NubBevelDepth` | Range | **0–1.0** (not -1..1 like other components) | 0.02 | → §2.1 — **cannot go negative**; the Nub can only look raised, never recessed, unlike every other component's bevel. |
| `_NubBevelSmoothness` | Range | 0–1 | 0.5 | → §2.1 |
| `_NubBevelDistance` | Range | 0–1.0 | 0.02 | → §2.1 |
| `_NubFaceSmoothness` | Range | -1–1 | 0 | → §2.1 |
| `_NubBevelPattern*` (9), `BevelPatternColor*` (7), `BevelGradient*` (11) | — | same shapes as §2.2-§2.4 | — | → §2.2–§2.4 |
| `_NubRimEnabled/Depth/Width/Smoothness` | — | same shape as §2.5 | — | → §2.5 |
| `_NubPatternEnabled` | Float | — | 0 | → §2.6 |
| `_NubPatternType` | Int `[Enum(PatternType)]` | 0–19 | 0 | → §2.6 |
| `_NubPatternScale` | Range | **0.1–10** (others: 1–100) | 1 | → §2.6 — a 10-100x narrower range than every other component's Pattern Scale. |
| `_NubPatternIntensity` | Range | **0–2** (others: 0–1) | 1 | → §2.6 |
| `_NubPatternContrast` | Range | **0–2** (others: 0.1–5) | 1 | → §2.6 |
| `_NubPatternSpecularEffect` | Range | **0–1** (others: 0–2) | 0.5 | → §2.6 |
| `_NubPatternRoughnessEffect` | Range | **0–1** (others: 0–2) | 0.5 | → §2.6 |
| `_NubPatternRotateEnabled` | Range(0,1) (not Float — declared as a `Range`) | 0–1 | 1 | → §2.6, called with `(_Value, _AngleRange)` — works. |
| `_NubPatternModEnabled/ModAmount/ModFrequency/Offset/Param1-3` | — | same shapes as §2.6 | — | → §2.6 |
| `_NubPatternColor*` (7) | — | same shape as §2.7/§2.8 | — | → §2.7/§2.8 |
| `_NubGradientEnabled` | Float | — | 0 | → §2.9 |
| `_NubGradientType` | Int `[Enum(GradientType)]` | 0–4 | 0 | → §2.9 |
| `_NubGradientColorA-D` | Color | — | R/G/B/Y | → §2.9 |
| `_NubGradientDirection` | Vector | — | (1,0,0,0) | → §2.9 |
| `_NubGradientSpeed` | Range | **0–5** (others: unbounded Float) | 1 | → §2.9 (still animates by default) |
| `_NubGradientScale` | Range | **0.1–10** (others: 0.1–5) | 1 | → §2.9 |
| `_NubGradientOffset` | Range | **0–1** (others: -2–2) | 0 | → §2.9 — cannot go negative, unlike every other component's GradientOffset. |
| `_NubGlobalBlend/GlobalIntensity` | Range | 0–1 / 0–2 | 0/1 | → §2.9 |
| `_NubGradientColorUsed` | Int `[IntRange]` | 2–4 | 4 | → §2.9 |

**Nub Edge (indent drawn just outside the Nub's own boundary, before the Nub itself):**

| Name | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_NubEdgeEnabled` | Float | — | 0 | Master switch. |
| `_NubEdgeColor` | Color | — | (0,0,0,0.8) | Indent color. |
| `_NubEdgeRenderAlpha` | Range | 0–1 | 1 | Alpha multiplier. |
| `_NubEdgeWidth` | Range | 0.001–0.2 | 0.05 | Indent extent from the nub's boundary. |
| `_NubEdgeSoftness` | Range | 0–2 | 0.0 | Same sharp/soft-curve toggle as KnobEdge. |
| `_NubEdgeIntensity` | Range | 0–2 | 1.0 | Mask multiplier. |
| `_NubEdgeRenderEmissive` | Range | 0–1 | 0 | Additive emissive. |
| `_NubEdgeGradient*` (13 props incl. Enabled/Type/ColorA-D/Direction/Speed/Scale/Offset/GlobalBlend/GlobalIntensity/ColorUsed) | — | same shape as §2.9 | — | → §2.9 |

### 3.9 External + Knob shadows (only rendered on the separate shadow-quad pass, `_ShadowPassMode > 0.5`)

| Name | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_LightingShadow1Enabled` | Float | — | 1 | External shadow cast by Fill/Line/Value geometry, from light 1. |
| `_LightingShadow1Color` | Color | — | (0,0,0,0.5) | Shadow color/alpha. |
| `_LightingShadow1Blur` | Range | 0–0.5 | 0.02 | Blur width of the shadow edge. |
| `_LightingShadow1Intensity` | Range | 0–2 | 1.0 | Alpha multiplier on the shadow. |
| `_LightingShadow1Distance` | Range | 0–0.5 | 0.1 | Offset distance of the shadow along the light direction. |
| `_LightingShadow2Enabled/Color/Blur/Intensity/Distance` | — | same shape | 0 / (0,0,0,0.3) / 0.03 / 0.8 / 0.12 | Second external shadow (light 2), **disabled by default**. |
| `_LightingShadow3Enabled/Color/Blur/Intensity/Distance` | — | same shape | 0 / (0,0,0,0.2) / 0.04 / 0.6 / 0.15 | Third external shadow (light 3), **disabled by default**. |
| `_LightingShadow1/2/3BlurFactor` | Range | 0–10 | 2.0 each | Power-curve sharpness on the light-facing side of the shadow blur (`shadowEdgeAlpha`'s `blurFactor` — higher = crisper light-side edge). |
| `_KnobShadow1Enabled` | Float | — | 1 | Cast shadow of the **knob's own silhouette** (hull-swept between base and face shape), from light 1. |
| `_KnobShadow1Color` | Color | — | (0,0,0,0.6) | Shadow color/alpha. |
| `_KnobShadow1Blur` | Range | **0–3.0** (external shadows: 0-0.5) | 0.01 | Blur width — much larger allowed range than the external shadows. |
| `_KnobShadow1Intensity` | Range | 0–2 | 1.2 | Alpha multiplier. |
| `_KnobShadow1Distance` | Range | 0–0.2 | 0.02 | Offset distance along the light direction. |
| `_KnobShadow2Enabled/Color/Blur/Intensity/Distance` | — | same shape | 0 / (0,0,0,0.4) / 0.02 / 0.8 / 0.03 | Second knob shadow, disabled by default. |
| `_KnobShadow3Enabled/Color/Blur/Intensity/Distance` | — | same shape | 0 / (0,0,0,0.3) / 0.03 / 0.6 / 0.04 | Third knob shadow, disabled by default. |
| `_KnobShadow1/2/3BlurFactor` | Range | 0–10 | 2.0 each | Same as external shadow blur factor, for knob shadows. |
| `_KnobShadow1/2/3Cast` | Range | 0–5 | 1.0 each | Multiplies the pseudo-3D "height" used to hull-sweep the shadow outward (bevel-depth-derived) — `0` collapses to a plain silhouette shadow with no directional throw; higher values throw the shadow further from the knob in the light's travel direction. |
| `_KnobShadow1/2/3MaxCast` | Range | 0.25–10 | 2.0 each | **RM-only** (see §3.6RM) — caps how far the cast throw can push the shadow, in units of the shadow-quad's own half-size, to prevent the sweep parameter collapsing back to the base footprint at grazing light angles. **Declared in the base SDFKnob.shader's uniform block is absent — grep confirms `_KnobShadow\dMaxCast` appears nowhere in `SDFKnob.shader`.** |

### 3.10 Outer decorative rings (`_OuterRing1/2/3*`) — up to 3, drawn 3rd

| Name | Type | Range | Default (Ring1 / Ring2 / Ring3) | What it does |
|---|---|---|---|---|
| `_OuterRing{N}Enabled` | Float | — | 0 / 0 / 0 | Master switch, all disabled by default. |
| `_OuterRing{N}Radius` | Range | 0.5–2.0 | 1.1 / 1.15 / 1.2 | Ring radius, world units (can sit well outside the `_LineRadius+_LineWidth` widget footprint). |
| `_OuterRing{N}Thickness` | Range | 0.001–0.2 | 0.02 each | Ring stroke width. |
| `_OuterRing{N}Color` | Color | — | grey, 0.5 alpha, darkening per ring | Ring color/alpha. |
| `_OuterRing{N}AngleStart` | Float | — | 0 each | Degrees, same convention as `_AngleStart` (§5) — **independent** of the knob's own `_AngleStart`, not additive. |
| `_OuterRing{N}AngleRange` | Float | — | 360 each | Degrees swept; full circle by default. |
| `_OuterRing{N}Style` | Int `[Enum(OuterRingStyle)]` | 0–2 | 0 (Solid) each | `0=Solid` continuous arc. `1=Dashed` — 24 fixed dashes across the angle range, each dash 60% of its slot (40% gap, hardcoded `dashCount=24`, `gapRatio=0.4` — not exposed as properties). `2=Dotted` — 36 fixed dots (`dotCount=36`, hardcoded), with the last dot dropped when `AngleRange >= 360` to avoid an overlapping seam. |
| `_OuterRing{N}RenderAlpha` | Range | 0–1 | 1 each | Alpha multiplier. |
| `_OuterRing{N}RenderEmissive` | Range | 0–1 | 0 each | Additive emissive. |

### 3.11 Scale marks (`_OuterMarks*`) — tick marks/dots/arc segments, drawn 4th

| Name | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_OuterMarksEnabled` | Float | — | 0 | Master switch (also requires `_OuterMarksCount >= 2`). |
| `_OuterMarksType` | Int `[Enum(OuterMarksType)]` | 0–3 | 0 (Lines) | `0=Lines` radial rectangular ticks. `1=Dots` circles. `2=Arcs` — a completely different code path (`renderScaleMarks`'s arc branch): renders `_OuterMarksCount - 1` **arc segments** (not per-mark ticks) using `_OuterMarksArcThickness`/`_OuterMarksArcGapSize` instead of `_OuterMarksLength`/`_OuterMarksThickness`/`_OuterMarksRounding`, and **ignores** `_OuterMarksMajor*` entirely (no major/minor distinction in Arc mode). `3=Mixed` — major ticks render as Lines, minor ticks render as Dots (`currentMarkType` forced per-mark). |
| `_OuterMarksCount` | Range | 2–120 | 11 | Number of mark positions evenly spaced across the angle range (`t = i/(count-1)`). |
| `_OuterMarksAngleStart` | Float | — | 0 | Degrees, same convention as `_AngleStart` — **independent** of the knob's `_AngleStart` (must be set manually to match if alignment is wanted — see §6). |
| `_OuterMarksAngleRange` | Float | — | 270 | Degrees swept by the marks — independent of `_AngleRange`. |
| `_OuterMarksColorFilled` | Color | — | (0.2,0.8,0.2,1) | Color for marks at/below the current value (with the value=0/mark=0 special case — see §6 gotcha). |
| `_OuterMarksColorUnfilled` | Color | — | (0.8,0.8,0.8,1) | Color for marks above the current value. |
| `_OuterMarksRadius` | Range | 0.1–1.5 | 0.9 | Distance from center, **as a multiple of `(_LineRadius + _LineWidth)`** — not an absolute world radius. |
| `_OuterMarksLength` | Range | 0.01–0.5 | 0.05 | Tick length (Lines/Mixed-major only). |
| `_OuterMarksThickness` | Range | 0.001–0.05 | 0.005 | Tick thickness (Lines/Mixed-major only). |
| `_OuterMarksRounding` | Range | 0–1 | 1 | Despite the label ("0=sharp, 1=rounded ends"), the code does **not** use a rounded-rect SDF — it's a flat inset (`d -= rounding * thickness * 0.5`) on a sharp `RectangleSDF`, which just inflates the tick slightly rather than rounding its corners. See §6 gotcha. |
| `_OuterMarksRenderAlpha` | Range | 0–1 | 1 | Alpha multiplier. |
| `_OuterMarksRenderEmissive` | Range | 0–1 | 0 | Additive emissive. |
| `_OuterMarksMajorEnabled` | Float | — | 1 | Enables the major/minor tick distinction (ignored entirely in Arc mode). |
| `_OuterMarksMajorInterval` | Range | 1–20 | 5 | Every Nth mark (`i % interval == 0`) is treated as major. |
| `_OuterMarksMajorLengthMultiplier` | Range | 1–3 | 1.5 | Multiplies `_OuterMarksLength` for major ticks. |
| `_OuterMarksMajorThicknessMultiplier` | Range | 1–3 | 1.5 | Multiplies `_OuterMarksThickness` for major ticks. |
| `_OuterMarksMajorColorFilled` | Color | — | (0.3,1,0.3,1) | Major-tick filled color (independent palette from minor ticks). |
| `_OuterMarksMajorColorUnfilled` | Color | — | (1,1,1,1) | Major-tick unfilled color. |
| `_OuterMarksArcGapSize` | Range | 0.001–0.2 | 0.02 | Arc mode only — gap between segments, in **radians**, then converted to degrees inline (`gapSize * 180/PI`). |
| `_OuterMarksArcThickness` | Range | 0.01–0.3 | 0.08 | Arc mode only — stroke thickness of each segment. |

### 3.12 Edge indent (`_Edge*`) — drawn 1st, behind everything

| Name | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_EdgeEnabled` | Float | — | 1 | **Enabled by default**, unlike most other optional layers. |
| `_EdgeColor` | Color | — | (0,0,0,0.8) | Indent color/alpha. |
| `_EdgeRenderAlpha` | Range | 0–1 | 1 | Alpha multiplier. |
| `_EdgeWidth` | Range | 0.001–0.2 | 0.05 | How far outward from the *combined* Fill/Line/Value outer boundary the indent extends. |
| `_EdgeSoftness` | Range | 0–2 | 0.0 | Sharp-cutoff vs. power-curve falloff (same math pattern as KnobEdge/NubEdge). |
| `_EdgeIntensity` | Range | 0–2 | 1.0 | Mask multiplier. |
| `_EdgeRenderEmissive` | Range | 0–1 | 0 | Additive emissive. |
| `_EdgeGradient*` (13 props: Enabled/Type/ColorA-D/Direction/Speed/Scale/Offset/GlobalBlend/GlobalIntensity/ColorUsed) | — | same shape as §2.9 | — | → §2.9 |

### 3.13 Border (`_Border*`) — cut-in alpha border, drawn last of the visible layers

| Name | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_BorderEnabled` | Float | — | 1 | **Enabled by default.** |
| `_BorderColor` | Color | — | (0,0,0,0.8) | Border color/alpha. |
| `_BorderRenderAlpha` | Range | 0–1 | 1 | Alpha multiplier. |
| `_BorderWidth` | Range | 0.001–0.1 | 0.02 | Solid-border width outside the outermost visible geometry radius. |
| `_BorderSoftness` | Range | 0–0.5 | 0.05 | Additional fade-out distance beyond `_BorderWidth`. |
| `_BorderIntensity` | Range | 0–2 | 1.0 | Mask multiplier applied to the border's alpha (not its territory-clearing effect — see §6). |
| `_BorderRenderEmissive` | Range | 0–1 | 0 | Additive emissive. |
| `_BorderGradient*` (13 props) | — | same shape as §2.9 | — | → §2.9 |

### 3.14 Lighting (shared, not component-specific)

| Name | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_LightingAmbient` | Range | 0–1 | 0.2 | Ambient light floor passed into every `ApplyUILighting` call across all components. |

*(Global per-scene light position/color/fx uniforms — `_GlobalLightPos1-3`, `_GlobalLightColor1-3`, `_GlobalLightFx1-3` — are declared in `SDFKnobUniforms.cginc` but are set by `GlobalLightManager`, not authored per-skin; omitted from this table as out of scope for `.states.json`.)*

### 3.15 Text layout (non-rendering — drives C# text placement only)

`_TextEnabled`, `_TextCount` (Range 0-16, def 12), `_TextRadius` (Float, def 180), `_TextAngleStart` (Float, def 0),
`_TextAngleRange` (Float, def 330), `_TextSize` (Float, def 16), `_TextColor` (Color), `_TextAlignment` (Range 0-2,
def 1: 0=Left/1=Center/2=Right), `_TextRotateWithKnob` (Float, def 0), `_TextFollowAngle` (Float, def 0),
`_TextForceUpright` (Float, def 1), `_TextId0`–`_TextId15` (Float, defaults 0-15, reference a C# text-table
dictionary). **None of these are read by the fragment shader.** They exist purely as a data channel a
`ITextLayoutProvider`/`ShaderTextManager` C# component reads via `material.GetFloat(...)` to position real TMP
text objects around the dial. Setting them in a `.states.json` only has an effect if that C# system is wired up
for the control instance; otherwise it's inert.

### 3.16 Unity UI plumbing (not skin-relevant, listed for completeness)

`_StencilComp` (Float, def 8), `_Stencil` (Float, def 0), `_StencilOp` (Float, def 0), `_StencilWriteMask` (Float,
def 255), `_StencilReadMask` (Float, def 255), `_ColorMask` (Float, def 15). Standard UGUI masking/stencil
plumbing, plus `_ClipRect` (Vector4, set by Unity's `RectMask2D`, not a Properties-block entry). Never authored
per-skin.

---

## 4. Enums — every integer value, read from the branch that handles it

### 4.1 `KnobShapeType` — `_KnobShapeType`, `_KnobFaceShapeType`, `_KnobNubShapeType` (dispatcher: `getKnobSDF`, `SDFKnobShapes.cginc:53-105`)

All 22 numeric cases + texture are **implemented** (none commented out), verified against the `[forcecase] switch` body:

| Value | Name | Code (`SDFKnobShapes.cginc` line) | Params used |
|---|---|---|---|
| 0 | Circle | `case 0: rawSDF = CircleSDF(p, radius);` (63) | none |
| 1 | GripNubs | `case 1: rawSDF = gripNubsSDF(p, radius, max(2,(int)shapeScale), param2, param1, param3);` (64) | Scale=count, param1=width, param2=depth, param3=roundness. **Note the argument order swap**: `gripNubsSDF(p, radius, numNubs, depth, width, roundness)` is called with `(shapeScale, param2, param1, param3)` — i.e. `param2` feeds the function's `depth` slot and `param1` feeds `width`, the reverse of the header-comment's advertised "param1=width, param2=depth" until you trace the call site. |
| 2 | Polygon | `case 2: rawSDF = PolygonSDF(p, radius, shapeScale, param1, param2, param3);` (65) | Scale=sides, param1=corner rounding, param2=edge-arc bump magnitude, param3=arc direction (>0.5 outward, else inward). |
| 3 | DShaft | `case 3: rawSDF = DShaftSDF(p, radius, param1, param2, param3);` (66) | param1=flat-cut depth, param2=rounding, param3=corner rounding. Flat cut is on `+y` local side. |
| 4 | Star | `case 4: {...} rawSDF = StarSDF(...) - param2*0.02;` (67-68) | Scale=points (min 3), param1=inner ratio, param2=tip rounding. |
| 5 | Squircle | `case 5: rawSDF = SquircleSDF(p, radius, param1, param2);` (69) | param1=squareness (0=circle→1=square), param2=x-axis squeeze. |
| 6 | Fluted | `case 6: rawSDF = FlutedSDF(p, radius, shapeScale, param1, param2, param3);` (70) | Scale=flute count, param1=depth, param2=sharpness, param3=phase offset (shifts flute pattern angularly). |
| 7 | Cross | `case 7: rawSDF = CrossSDF(p, float2(radius*lerp(.1,.9,param1), radius*lerp(.3,1,param2)), param3*0.02);` (71-72) | param1=arm width, param2=arm length, param3=corner rounding. |
| 8 | ChickenHead | `case 8: rawSDF = ChickenHeadSDF(p, radius, param1, param2, param3);` (74) | Round body (0.72×radius) + upward rectangular handle. param1=handle length, param2=handle width, param3=body-handle blend radius. |
| 9 | Arrow | `case 9: rawSDF = ArrowKnobSDF(p, radius, param1, param2, param3);` (75) | Arrowhead pointing toward local `-y` + rectangular tail toward `+y`, smooth-unioned. param1=head width, param2=tail width, param3=tail length. |
| 10 | Gear | `case 10: rawSDF = GearKnobSDF(p, radius, shapeScale, param1, param2, param3);` (76) | Scale=tooth count, param1=tooth height, param2=root rounding, param3=tooth width. |
| 11 | Skirted | `case 11: rawSDF = SkirtedKnobSDF(p, radius, param1, param2, param3);` (77) | Circular cap + separate skirt ring divided by a transparent groove. param1=cap radius ratio, param2=groove width, param3=groove depth multiplier. |
| 12 | OvalPointer | `case 12: rawSDF = OvalPointerSDF(p, radius, param1, param2, param3);` (78) | Upright ellipse with optional flat-bottom cut. param1=aspect ratio, param2=flat cut amount, param3=tip rounding. |
| 13 | MushroomCap | `case 13: rawSDF = MushroomCapSDF(p, radius, param1, param2, param3);` (79) | Wide dome + narrower stem; **local shape is rotated 90° so the dome faces `+x` / stem extends `-x`** (`float2 q = float2(p.y, -p.x)` inside the function). param1=cap overhang, param2=stem width, param3=stem length. |
| 14 | DaviesIndicator | `case 14: rawSDF = DaviesIndicatorSDF(p, radius, param1, param2, param3);` (80) | Disc with a machined slot cut from the `-y` side. param1=slot length, param2=slot width, param3=slot corner rounding. |
| 15 | ColletKnob | `case 15: rawSDF = ColletKnobSDF(p, radius, shapeScale, param1, param2, param3);` (81) | Disc + polygonal hub groove + optional knurled outer ring. Scale=hub sides, param1=hub radius ratio, param2=hub groove depth, param3=knurling amount (adds a `cos(angle*teeth)` ripple in the outer 25% of the radius when >0.01). |
| 16 | RingPointer | `case 16: rawSDF = RingPointerSDF(p, radius, param1, param2, param3);` (83) | Thin ring + solid tab, smooth-unioned. **Local shape rotated 90° so tab projects toward `+x`** (`float2 q = float2(p.y, -p.x)`). param1=ring thickness, param2=tab width, param3=tab length. |
| 17 | BlobStar | `case 17: rawSDF = BlobStarSDF(p, radius, shapeScale, param1, param2, param3);` (84) | Organic rounded star blended toward a circle. Scale=points, param1=inner ratio, param2=tip rounding, param3=circle-blend amount (0=pure star, 1=full smooth-union with an inscribed circle). |
| 18 | CapScrew | `case 18: rawSDF = CapScrewSDF(p, radius, param1, param2, param3);` (85) | Disc with a flat-head slot cut (horizontal rectangle); if `param3 > 0.5` (Phillips), also cuts a vertical slot forming a cross. param1=slot width, param2=slot depth, param3=Phillips toggle (step function, not a blend). |
| 19 | TaperDisc | `case 19: rawSDF = TaperDiscSDF(p, radius, param1, param2, param3);` (86) | Circular disc expanded asymmetrically on one side. param1=taper amount, param2=taper angle (0-1 maps to 0-360°), param3=edge rounding. |
| 20 | FaderCap | `case 20: rawSDF = FaderCapSDF(p, radius, param1, param2, param3);` (87) | Rounded rect with a milled central groove cut through it. param1=aspect ratio, param2=groove depth (as fraction of half-width), param3=corner rounding. **Not documented in the SDFKnob.shader header-comment's enum list (which stops at 19=TaperDisc) — only exists in `ShaderConstants.cs` and the dispatcher.** |
| 21 | FaderCapWide | `case 21: rawSDF = FaderCapWideSDF(p, radius, param1, param2, param3);` (88) | Wide rounded rect with two optional screw-hole cutouts. param1=aspect ratio, param2=screw-hole radius (0=no holes), param3=corner rounding. Same "missing from header comment" note as #20. |
| 100 | Texture | `case 100: {...}` (90-100) | Samples a signed-distance field from a `Texture2DArray` layer (`_KnobShapeTexLayer`/`_KnobFaceShapeTexLayer`), scaled by `_KnobShapeTexScale`/`_SDFShapeTexSpread`. Requires the texture asset + layer to actually be assigned at the material/controller level — a skin author cannot make this work from `.states.json` alone. |
| *other* | — | `default: rawSDF = CircleSDF(p, radius);` (101) | Any unlisted integer (e.g. 22-99) silently falls back to Circle. |

Every shape above also gets a **universal post-process**: `rawSDF - min(_KnobRoundness * radius * 0.15, radius * 0.4)` (roundness) is applied identically regardless of shape type.

### 4.2 `NubShapeType` — `_NubShapeType` (dispatcher: `getNubSDF`, `SDFKnobLayers.cginc:22-125`) — **only 5 of 20 enum values are implemented**

| Value | Name | Status |
|---|---|---|
| 0 | Circle | **Implemented**: `CircleSDF(p, min(width,height)*0.5)` |
| 1 | Rectangle | **Implemented**: `RectangleSDF(p, float2(width,height)*0.5)` |
| 2 | RoundedRect | **Implemented**: `RoundedRectSDF(p, float2(width,height)*0.5, param1)` — param1 = corner radius |
| 3 | Ellipse | **Implemented**: `EllipseSDF(p, float2(width,height)*0.5)` |
| 4 | Triangle | **Implemented**: upward-pointing triangle from three fixed corners |
| 5 | Diamond | **Commented out in the `switch`** (`SDFKnobLayers.cginc:43-52`, entire case block is `//`-prefixed) → falls to `default: return CircleSDF(...)` |
| 6 | Play | **Commented out** (lines 53-59) → renders as Circle |
| 7 | LineV | **Commented out** (lines 60-61) → renders as Circle |
| 8 | LineH | **Commented out** (lines 62-63) → renders as Circle |
| 9 | Dot | **Commented out** (lines 64-65) → renders as Circle |
| 10 | Arrow | **Commented out** (lines 66-73) → renders as Circle |
| 11 | Star | **Commented out** (lines 74-80) → renders as Circle |
| 12 | Cross | **Commented out** (lines 81-87) → renders as Circle |
| 13 | Heart | **Commented out** (lines 88-92) → renders as Circle |
| 14 | Hexagon | **Commented out** (lines 93-94) → renders as Circle |
| 15 | Pentagon | **Commented out** (lines 95-96) → renders as Circle |
| 16 | Rhombus | **Commented out** (lines 97-102) → renders as Circle |
| 17 | Ring | **Commented out** (lines 103-108) → renders as Circle |
| 18 | CutDisk | **Commented out** (lines 109-114) → renders as Circle |
| 19 | Pie | **Commented out** (lines 115-121) → renders as Circle |
| *any* | `default` | `default: return CircleSDF(p, min(width,height)*0.5);` (122-123) |

**This is the single biggest trap in the whole shader for a skin author.** The `NubShapeType` C# enum (`ShaderConstants.cs:96-120`) advertises the full 20-value set as if it were live — it is the same enum used elsewhere for real (e.g. `IconShapeType` shares the same numbering and *is* fully implemented for icons). Setting `_NubShapeType` to anything above `4` on the **Knob's** `_Nub` component silently produces a plain circle with no error, no console warning, nothing — verify visually before relying on it. Contrast with `_KnobNubShapeType` (§3.7), which uses the fully-implemented `KnobShapeType`/`getKnobSDF` dispatcher instead and has no such gap.

### 4.3 `OuterRingStyle` — `_OuterRing{1,2,3}Style` (`SDFKnobLayers.cginc:renderOuterRing`, 812-895)

| Value | Name | Code |
|---|---|---|
| 0 | Solid | `if (ringStyle < 0.5)` — continuous `ArcSDF` stroke. |
| 1 | Dashed | `else if (ringStyle < 1.5)` — 24 fixed dashes (`dashCount = 24`), each dash spans 60% of its angular slot (`gapRatio = 0.4`, hardcoded, not exposed). |
| 2 | Dotted | `else` — 36 fixed dots (`dotCount = 36`, hardcoded). Drops the final dot when `ringAngleRange >= 360` to avoid a doubled dot at the seam. |

### 4.4 `PatternType` — every `*PatternType` property (`UIPatterns.cginc:25-54`, mirrored `ShaderConstants.cs:37-65`)

| Value | Name | Category |
|---|---|---|
| 0 | Plastic | Surface material |
| 1 | Metal | Surface material |
| 2 | RadialBrushed | Surface material |
| 3 | CarbonFiber | Surface material |
| 4 | Leather | Surface material |
| 5 | BrushedCross | Brushed finish |
| 6 | Satin | Brushed finish |
| 7 | Concrete | Mineral/fabric |
| 8 | Fabric | Mineral/fabric |
| 9 | Paper | Mineral/fabric |
| 10 | Frosted | Mineral/fabric |
| 11 | DiamondPlate | Geometric |
| 12 | Knurled | Geometric |
| 13 | HexGrid | Geometric |
| 14 | Perforated | Geometric |
| 15 | WoodGrain | Organic |
| 16 | Marble | Organic |
| 17 | Ceramic | Organic |
| 18 | Circuit | Special |
| 19 | NoiseOrganic | Special |

All 20 are fully implemented `Sample*` functions in `UIPatterns.cginc` (not verified line-by-line in this doc — the dispatch switch itself was confirmed to route to a real function for every value 0-19; exact visual character of each was **not** individually re-derived here, only `SamplePlastic`'s param semantics were read in full as a representative example — see §2.6).

### 4.5 `GradientType` — every `*GradientType` property (`UIGradients.cginc:11-21`, mirrored `ShaderConstants.cs:20-34`)

| Value | Name | Code (`UIGradients.cginc:GetGradientPosition`) |
|---|---|---|
| 0 | Linear | `LinearGradient`: `dot(uv, normalize(direction)) * scale + time*speed*0.1 + offset` — a straight ramp along `Direction`. |
| 1 | Radial | `RadialGradient`: `length((uv-0.5)*2.0) * scale + ...` — rings out from the UV center. |
| 2 | Angular | `AngularGradient`: `atan2(uv.y-0.5, uv.x-0.5)/(2π) + 0.5` scaled — sweeps around the UV center. |
| 3 | Diamond | `DiamondGradient`: taxicab distance `(|dx|+|dy|)*2` from the UV center — diamond-shaped rings. |
| 4 | Triangle | `TriangleGradient`: same as Linear but passed through `TriangleWave()` for a repeating bounce pattern. |
| 5 | BevelDepth | **RM-only, meaningful only on Knob Bevel Gradient in `SDFKnobRM.shader`.** Linear A(outer)→D(groove back) ramp using the 3D bevel's surface normal, not UV position. `scale`=range multiplier, `offset`=shift. Using this on the base `SDFKnob.shader` (2D) or on any non-Knob-Bevel-Gradient slot has **undefined/untested behaviour** — the comment explicitly scopes it to one specific use site; not verified what `GetGradientPosition`'s `default:` fallback (`return 0.5`, static mid-palette color) produces for it elsewhere, since 5/6 aren't in the `switch`'s explicit cases (`GRADIENT_LINEAR`..`GRADIENT_TRIANGLE` are the only named cases; 5/6 have no case statement in `GetGradientPosition` itself and would fall to `default: return 0.5`, i.e. **a flat, non-animating mid-gradient position** wherever they're used through the ordinary `CalculateGradient` path that SDFKnob.shader actually calls). |
| 6 | BevelWalls | **RM-only** (Knob Bevel Gradient in `SDFKnobRM.shader` only). Zone-based: A=outer wall, B=side-outward-half, C=side-inward-half, D=groove/slit back. `scale`=transition sharpness, `offset`=outer/groove threshold shift. Same caveat as #5 — falls to the `default: return 0.5` static position if driven through the standard `CalculateGradient` used elsewhere. |

### 4.6 `PatternColorType` / `PatternColorMode` / `BevelProfileType` / `OuterMarksType`

Already fully tabulated in §2.7, §2.8, §2.1, and §3.11 respectively — not repeated here.

---

## 5. Value-indication mechanics — how `_Value` (0..1) becomes a visible position

Four independent things move as `_Value` changes, and **they do not all use the same angle convention**:

### 5.1 The angle convention itself (verified from `ArcSDF`, `SDFPrimitives.cginc:278-318`, and `getScaleMarkSDF`/Nub-position code in `SDFKnobLayers.cginc`/`SDFKnob.shader`)

`_AngleStart` and `_AngleRange` are **degrees**. Both the value-arc (`ArcSDF`) and every angular-position calculation (scale marks, `_Nub`, `_KnobNub`) convert a UI-space angle to a math direction the same way:

```
normalizedAngle = fmod(angle + 360, 360)
atan2Angle = (normalizedAngle <= 180) ? (180 - normalizedAngle) : (540 - normalizedAngle)
direction  = (cos(radians(atan2Angle)), sin(radians(atan2Angle)))   // world/local XY, +Y = up on screen
```

Working through this mapping for the four cardinal points gives:

| UI angle | Screen direction | Clock position |
|---|---|---|
| 0° | **West** (-1, 0) | 9 o'clock |
| 90° | North (0, 1) | 12 o'clock (top) |
| 180° | East (1, 0) | 3 o'clock |
| 270° | South (0, -1) | 6 o'clock |

and increasing angle sweeps **clockwise** (9:00 → 12:00 → 3:00 → 6:00 → back to 9:00).

**This contradicts the code comment sitting directly above the reusable helpers in `UIMath.cginc:379`** ("*These use UI angle convention: 0=top, clockwise positive*"), which describes `isInsideArc`/`isInAngularRange` (used elsewhere in the SDF library, not by the Knob's own arc-fill math) — but is **not what `ArcSDF` and the Knob's own position code actually do**. **0° is 9-o'clock/West, not top.** Both directions agree on "clockwise positive," but the zero reference is off from what the comment claims by 90°. Verify this empirically in the Designer before trusting either description if it matters for your skin.

With the shader's own defaults (`_AngleStart=0`, `_AngleRange=270`), the sweep runs West(9:00) → North(12:00) → East(3:00) → South(6:00), leaving a 90° dead zone in the **bottom-left quadrant** (6:00-to-9:00, roughly "7 o'clock") unfilled — the classic hardware-knob layout, confirming the derivation above is consistent with how the control is actually meant to look out of the box.

### 5.2 Value arc (Line/Value Filled/Value Unfilled)

- `currentAngleRange = _AngleRange * _Value`
- Value Filled arc: `_AngleStart` → `_AngleStart + currentAngleRange`
- Value Unfilled arc: `_AngleStart + currentAngleRange` → `_AngleStart + _AngleRange`
- Both are drawn with `ArcSDF`, so `_LineRoundedEnabled` controls whether their end-caps (including the seam between Filled and Unfilled) are rounded or flat-cut.
- **0%** = Filled arc has zero angular length (fully hidden, only Unfilled visible across the whole range). **100%** = Filled arc fully replaces Unfilled. **40% / 80%**: purely a function of `_AngleRange` — with the default 270°, 40% = 108° of sweep, 80% = 216°; both are trivially visually distinct as arc-length differences regardless of the angle-convention question above.

### 5.3 Knob body rotation — a *different*, unrelated-by-default transform

```
knobAngle = (_AngleStart + _AngleRange*_Value + _KnobRotation) * (PI/180)
shapeSDF(rotate2D(pos, knobAngle))
```

`rotate2D` is a plain CCW rotation matrix applied **directly to the raw degree sum in radians** — it does **not** go through the atan2 remap in §5.1. Derived from first principles (see worked example in the audit): sampling `shapeSDF(rotate2D(pos, θ))` makes the **rendered shape appear to rotate clockwise by θ** as θ increases — so the *direction* (clockwise-positive) happens to agree with §5.1's arc convention, but the **zero reference does not**: at `θ=0` the knob shows whatever direction its shape's local silhouette was authored to face (e.g. `DaviesIndicatorSDF`'s slot is cut toward local `-y`/south by construction; `ChickenHead`'s handle points local `-y`/toward the shape's "up" as defined inside that specific `.cginc` file — each shape file picks its own local convention independently).

**Practical consequence:** there is no guarantee a shape's built-in pointing feature (DaviesIndicator's slot, ChickenHead's handle, Arrow's tip, RingPointer's tab, MushroomCap's stem) visually lines up with where the value arc says "0%" out of the box. **`_KnobRotation` exists specifically to let a skin author dial that phase alignment in by hand** — set `_Value=0`, watch where the shape's indicator feature points, then adjust `_KnobRotation` until it matches the arc's start (9 o'clock by default, per §5.1) or whatever reference the skin wants. This must be tuned visually in the Designer per shape/skin; it cannot be computed from this doc alone without also reading each `*SDF.cginc` file's exact local-space placement, which is not something this doc derives to the degree of precision needed to hand you an exact number.

### 5.4 Nub and KnobNub position

Both **do** go through the §5.1 atan2 remap, so they correctly track the value-arc's angular convention:
- `_Nub`: angle = `_AngleStart + _AngleRange*_Value + _NubRotation`, position = `direction * _NubDistance` (world units, same `[-1,1]` space as `_LineRadius`), then the shape itself is additionally spun by `_NubShapeRotation` around its own center after being oriented radially outward.
- `_KnobNub`: angle = `_AngleStart + _AngleRange*_Value + _KnobRotation` (note: reuses **`_KnobRotation`**, not a `_KnobNub`-specific rotation property — it's locked to follow the knob body's manual offset), position = `direction * (_KnobNubDistance * knobRadius)`.

Both therefore land in the exact same place, angularly, as the tip of the Value Filled arc at any given `_Value` — these are the two indicators most likely to "feel" correctly synced to the arc at 0%/40%/80% without any extra tuning.

### 5.5 Scale marks

Independent again: `markAngleUI = _OuterMarksAngleStart + _OuterMarksAngleRange * (i/(count-1))`, same §5.1 remap. **Not tied to `_AngleStart`/`_AngleRange` at all** — a skin author who wants marks to line up with the arc's start/end must manually set `_OuterMarksAngleStart = _AngleStart` and `_OuterMarksAngleRange = _AngleRange`.

### 5.6 Making 0% / 40% / 80% clearly distinguishable

- The value arc's length is the most legible cue (proportional to `_Value` regardless of any angle-convention subtlety above) — keep `_LineSublineFilledColor` high-contrast against `_LineSublineUnfilledColor`.
- The Knob body's rotation is only useful as a value cue if the chosen `KnobShapeType` actually has an asymmetric silhouette (DaviesIndicator, ChickenHead, Arrow, RingPointer, Skirted-with-groove, etc.) — `Circle`/`Squircle`/`Star`-with-even-points/`Gear` look identical at every rotation and communicate nothing about value on their own.
- `_Nub`/`_KnobNub` at a fixed radius moving around the arc is the single clearest, shape-independent value cue — recommended as the primary indicator if the Knob body itself uses a rotationally-symmetric shape.
- Scale marks with `_OuterMarksColorFilled`/`Unfilled` recoloring per position (already wired to `_Value`) give discrete, countable confirmation at a glance — good for precise value reading, especially combined with `_OuterMarksMajorInterval` ticks at 0/40/80%-equivalent positions.

---

## 6. Interaction / dependency notes and pixel-size gotchas

- **Pattern `Scale`/`Detail`/`Roughness` on any component is sampled in normalized `[-0.5,0.5]` local space, not screen pixels** (`UIPatterns.cginc:74`). A `PatternScale` tuned to look good on a 200px knob will alias or effectively disappear (sub-pixel frequency, eaten by anti-aliasing) on a 24px knob rendered at the same `Scale` value. Test pattern-heavy skins at the *smallest* instance size they'll actually ship at, not just in the Designer's default preview size.
- **`{P}PatternRoughnessEffect` drives a screen-space-derivative (`ddx`/`ddy`) normal offset** — this is inherently a per-pixel effect; at small on-screen sizes the derivative magnitude shrinks and the "bumpiness" the pattern contributes to lighting fades out well before the base color pattern itself does.
- **Bevel width/distance ARE proportional (world-space, scale with the control)**, unlike pattern scale — `_KnobBevelDistance` etc. are fractions of `_LineRadius`/`knobRadius`, so bevels stay proportionally consistent across sizes. However, the **antialiasing band** around any SDF edge is pixel-derivative-based (`fwidth`), so a bevel whose `BevelDistance`/`BevelSmoothness` maps to less than ~1-2 screen pixels at a given size will be smeared away by AA regardless of what the property value says.
- **`_FillPatternRotateEnabled`/`_FillPatternModEnabled` are no-ops** — Fill's `ApplyMaterialPattern` call is hardcoded with `currentValue=0.0, angleRange=0.0` (`SDFKnob.shader:1362-1363`), so neither the value-linked rotation nor the shimmer can ever activate on Fill. Every other pattern-bearing component (Line, Value Filled, Value Unfilled, Knob, Nub) passes the real `(_Value, _AngleRange)` and both flags do work there.
- **`PatternRotateEnabled` silently overrides `PatternModEnabled`** on every component — the code is `if (RotateWithValue) {...} else if (ModWithValue) {...}` (`UIPatterns.cginc:817-823`). If a skin sets both to 1, only the continuous rotation happens; the sine-shimmer never triggers. Turn Rotate off to get Mod's behaviour.
- **Gradients animate by default.** `CalculateGradient` (the function SDFKnob.shader actually calls, `UIRenderer.cginc:13-19`) always derives gradient position from `time * speed` — there is no "static position" branch in this code path. Since most `*GradientSpeed` properties default to `1.0`, simply flipping `*GradientEnabled` on without also setting `*GradientSpeed = 0` makes that gradient visibly scroll/rotate/pulse continuously, which is easy to not notice in a still screenshot but very obvious in Play Mode.
- **`_KnobShapeParam4/5/6` and `_KnobFaceShapeParam4/5/6` are declared, always passed through, and currently unused** — no shape function in `KnobShapes/*.cginc` reads a `param4`, `param5`, or `param6` argument (they all take at most `param1-3`). Setting these has no visible effect for any `KnobShapeType` value that exists today. They exist as forward-compat slots.
- **`_NubRounding` appears to have no wired effect** — declared as a property, but the fragment code's two `getNubSDF` call sites (initial SDF evaluation and the bevel-normal finite-difference recompute) both pass `_NubShapeParam1/2/3`, never `_NubRounding`. Use `_NubShapeParam1` (which *is* forwarded as `RoundedRectSDF`'s corner-radius `param1`) for Nub corner rounding instead — see §3.8.
- **Scale marks are independent of the value arc's angle range** — `_OuterMarksAngleStart`/`_OuterMarksAngleRange` and `_OuterRing{N}AngleStart`/`AngleRange` are their own numbers, not derived from `_AngleStart`/`_AngleRange`. A skin that moves the knob's sweep range must also update these three families of properties manually or the marks/rings will visually detach from the arc.
- **`_KnobRotation` is shared** between the knob body's own rotation *and* the `_KnobNub` orbit offset — you cannot rotate one without the other. `_Nub` has its own independent `_NubRotation`.
- **RM-only widening**: `_KnobNubDistance`'s allowed `Range` is `0-1` on `SDFKnob.shader` but `0-2` on `SDFKnobRM.shader` — the same skin value can be valid on RM and clamp/invalid on base depending on authoring tool validation; keep it ≤ 1 for cross-shader-safe skins.
- **Border clears (darkens) what's under it.** `_BorderEnabled` doesn't just draw a ring on top — it computes a `territory` mask (everything the border's soft edge could possibly touch) and multiplies `finalColor`/`emissiveAccum` by `(1 - territory)` *before* compositing the border color, specifically so the border's soft edge fades to background rather than to a stale shadow/edge-indent color underneath it. A very wide `_BorderWidth + _BorderSoftness` can visibly eat into the Edge-indent or Line geometry's own edge softening.

---

## 7. Gotchas

1. **Angle-convention comment is misleading.** `UIMath.cginc:379` claims "0=top, clockwise positive" but the code the Knob shader actually uses (`ArcSDF`, mark/nub positioning) puts 0° at **West (9 o'clock)**, not top. See §5.1 for the full derivation. Trust the derivation over the comment.
2. **`_NubShapeType` values 5-19 are dead code.** The C# enum lists 20 shapes; only 0-4 (Circle/Rectangle/RoundedRect/Ellipse/Triangle) are implemented in `getNubSDF` — the rest are `//`-commented-out case blocks that fall through to a plain circle, silently, with no error. See §4.2. This is easy to miss because the sibling `_KnobNubShapeType` (a different property, on a different component) *does* have the full 22-shape range via `getKnobSDF`.
3. **`_KnobShapeType` 20 (FaderCap) and 21 (FaderCapWide) exist in code but are missing from the SDFKnob.shader header-comment's own enum documentation**, which stops at `19=TaperDisc`. They are real, implemented, and listed in `ShaderConstants.cs` — just under-documented at the point a skin author is most likely to look first (the shader file's own top-of-file comment block).
4. **`_NubBevelDepth` cannot go negative** (`Range(0, 1.0)`) — unlike every other component's bevel depth (`Range(-1,1)` or similar), the Nub can only look raised, never recessed.
5. **`_NubGradientOffset` cannot go negative** (`Range(0, 1)`) while every other component's `GradientOffset` is `Range(-2, 2)`.
6. **First scale mark has an explicit "don't count as filled at Value=0" special case**: `bool shouldBeFilled = (_Value >= markValue) && !(_Value == 0.0 && markValue == 0.0);` (`SDFKnobLayers.cginc:743`, repeated 777/781) — without this exclusion, `_Value >= markValue` would be `0 >= 0 = true` and the very first tick would render in the "filled" color even at the knob's minimum position. With it, mark 0 always starts in the Unfilled color and only the marks strictly less-than-or-equal to a *nonzero* value are ever colored Filled.
7. **`_OuterMarksRounding` doesn't round corners.** Despite the display name and the "0=sharp, 1=rounded ends" tooltip, the implementation (`SDFKnobLayers.cginc:684-686`) is `d -= rounding * thickness * 0.5` on a plain `RectangleSDF` — a uniform inset/inflate, not a rounded-rect distance function. It makes the tick slightly fatter/softer at high AA blur, not literally rounded.
8. **`_Color` is declared in `SDFKnobRM.shader`'s Properties block (`"Tint"`) but never referenced anywhere in the fragment shader** — grep for `_Color.`/`* _Color` in the file returns nothing. It's vestigial; changing it in a `.states.json` will have zero visual effect on SDFKnobRM.
9. **`_KnobShadow1/2/3MaxCast` exists only on SDFKnobRM**, not on the base SDFKnob.shader (confirmed absent via grep) — a skin file authored against RM's shadow-cast-distance cap won't have anything to apply that value to if reused against the base shader's material.
10. **GripNubs argument order is not what the property-label order implies.** The `[Enum(KnobShapeType)]` header comment (and this doc's §4.1 table) says "param1=width, param2=depth, param3=roundness," but the actual call is `gripNubsSDF(p, radius, count, /*depth*/param2, /*width*/param1, param3)` — i.e. the function's own `depth`/`width` argument positions receive `param2`/`param1` respectively, the reverse of what the comment implies at a skim. Verify visually which of `_KnobShapeParam1`/`Param2` is doing what before trusting the label.
11. **`_KnobBevelDepth`'s range is `-4..4`**, dramatically wider than every sibling component's bevel-depth range (`-1..1`) — this is intentional (it has to reach RM's true 3D bevel heights), but a skin author copying a "reasonable" 0.1-0.3 value from Fill/Line to Knob and expecting a similarly-scaled visual result should know the same numeric value reads very differently depending on which bevel it's on.
12. **Shadows only render on a second, separate draw call** (`_ShadowPassMode > 0.5`, an expanded backing quad managed by `WidgetShadowQuad.cs`) — none of `_LightingShadow1-3*`/`_KnobShadow1-3*` will show up at all if you only inspect the shader in a context that doesn't also render that second pass (e.g. a raw material preview thumbnail). This is expected, not a bug, but worth knowing when a shadow "isn't showing" in a quick preview.
13. **`GradientType` values 5 (BevelDepth) and 6 (BevelWalls) are RM-only and scoped to one specific slot** (Knob Bevel Gradient on SDFKnobRM). `GetGradientPosition`'s `switch` in `UIGradients.cginc` has no `case` for 5/6, so through the ordinary `CalculateGradient` path every other Gradient property on either shader would fall to the `default: return 0.5` branch if set to 5/6 — a static, flat mid-palette color, not a crash, but also not the "3D bevel topology" effect the enum name implies outside its one intended use site.
