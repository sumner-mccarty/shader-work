# UI Shader Core — Patterns, Gradients, Lighting, Bevels, Compositing, SDF

This is a reference for the **shared core** every `.states.json` skin ultimately drives:
`CG/Core/UIPatterns.cginc`, `UIGradients.cginc`, `UILighting.cginc`, `UIEffects.cginc`,
`UIRenderer.cginc`, `UIDisplaySurface.cginc`, `UIComponents.cginc`, `UIGlobalUniforms.cginc`,
and `CG/SDF/SDFPrimitives.cginc` + `SDFOperations.cginc` — all read in full for this doc.
Per-widget property tables (Button/Panel/Slider/Knob/Toggle) live in sibling `Params-*.md` files;
this doc only covers the enums and conventions those widgets all share. Every claim below is
sourced directly from the code; anywhere the code was ambiguous or I could not verify a claim by
reading, it's flagged explicitly rather than guessed.

Cross-checked against real numeric usage in shipped `Assets/Resources/MaterialStates/*.json` skins
and against the `Range()` bounds authored in `SDFButton.shader`'s Properties block (the other
widgets — Panel/Slider/Knob/Toggle — declare the same property names with the same ranges; spot
checked and noted where one widget differs).

---

## 1. The Pattern Table

### How dispatch works

`ApplyMaterialPattern` (in `UIPatterns.cginc`) is the single entry point every widget section calls.
It early-outs if `component.patternEnabled < 0.5`, then samples exactly one pattern function through
this dispatcher:

```hlsl
float SamplePatternValue(int patternType, float2 pos, float2 center, float scale,
                         float p1, float p2, float p3)
{
    [branch]
    switch (patternType)
    {
        case PATTERN_PLASTIC:        return SamplePlastic(pos, center, scale, p1, p2, p3);
        case PATTERN_METAL:          return SampleMetal(pos, center, scale, p1, p2, p3);
        case PATTERN_RADIAL_BRUSHED: return SampleRadialBrushed(pos, center, scale, p1, p2, p3);
        case PATTERN_CARBON_FIBER:   return SampleCarbonFiber(pos, center, scale, p1, p2, p3);
        case PATTERN_LEATHER:        return SampleLeather(pos, center, scale, p1, p2, p3);
        case PATTERN_BRUSHED_CROSS:  return SampleBrushedCross(pos, center, scale, p1, p2, p3);
        case PATTERN_SATIN:          return SampleSatin(pos, center, scale, p1, p2, p3);
        case PATTERN_CONCRETE:       return SampleConcrete(pos, center, scale, p1, p2, p3);
        case PATTERN_FABRIC:         return SampleFabric(pos, center, scale, p1, p2, p3);
        case PATTERN_PAPER:          return SamplePaper(pos, center, scale, p1, p2, p3);
        case PATTERN_FROSTED:        return SampleFrosted(pos, center, scale, p1, p2, p3);
        case PATTERN_DIAMOND_PLATE:  return SampleDiamondPlate(pos, center, scale, p1, p2, p3);
        case PATTERN_KNURLED:        return SampleKnurled(pos, center, scale, p1, p2, p3);
        case PATTERN_HEX_GRID:       return SampleHexGrid(pos, center, scale, p1, p2, p3);
        case PATTERN_PERFORATED:     return SamplePerforated(pos, center, scale, p1, p2, p3);
        case PATTERN_WOOD_GRAIN:     return SampleWoodGrain(pos, center, scale, p1, p2, p3);
        case PATTERN_MARBLE:         return SampleMarble(pos, center, scale, p1, p2, p3);
        case PATTERN_CERAMIC:        return SampleCeramic(pos, center, scale, p1, p2, p3);
        case PATTERN_CIRCUIT:        return SampleCircuit(pos, center, scale, p1, p2, p3);
        case PATTERN_NOISE_ORGANIC:  return SampleNoiseOrganic(pos, center, scale, p1, p2, p3);
        default: return 0.0;
    }
}
```

Every pattern gets the **same** `pos`/`center`/`scale` — there is no per-pattern coordinate-space
override. What differs between patterns is only how each one turns `(pos+center)*scale` into a
value. That value (roughly centered on 0) is then multiplied by `patternIntensity`, reshaped by
`patternContrast`, and used two ways: `specularMod = 1 + pattern*patternSpecularEffect*10`, and
either `baseColor*(1+pattern)` (brightness modulation, the default) or a palette lookup if
`patternColorEnabled` — see §1.4 below.

### 1.1 Coordinate space — UV space, aspect-corrected per-widget (answered once, for all 20)

**Every pattern is in UV space, not fixed-pixel space** — because the space is decided entirely by
the *caller* (the widget shader), not by `SamplePatternValue`/`ApplyMaterialPattern` itself, and
every caller passes a UV that spans a fixed range across the widget's own quad regardless of how
large that quad is on screen. Concretely, in `SDFButton.shader`, `SDFPanel.shader`,
`SDFSlider.shader`, `SDFSlider RM`, and `SDFToggleRenderCore.cginc`:

```hlsl
float2 aspectScale = float2(max(rectAspect, 1.0), max(1.0 / rectAspect, 1.0));
float2 uvIso  = (uv - center) / aspectScale + center;   // Button/Panel form
// or, equivalently in Slider/Toggle:
float2 pos    = (uv - center) * 2.0 * aspectScale;
float2 uvIso  = pos * 0.5 + center;
```
`SDFSlider.shader` even spells out the intent in a comment (line ~674): *"Pattern UV: pos\*0.5+center
scales each axis by its pixel count so feature size is constant in screen pixels; wider quads show
more repetitions, not larger features."* Read that carefully: it means **isotropic within the
widget** (a non-square button/panel doesn't stretch its pattern into ellipses/ovals) — it does
**not** mean size-invariant across different control instances. `uv` (and therefore `uvIso`) always
spans `0..1` across the widget's own quad no matter how many actual screen pixels that quad
occupies. So for a *fixed* `patternScale`, the **cycle count is constant relative to the control**,
and a pattern feature's **physical/on-screen size scales up linearly as the control grows** — this
is exactly the "UV space" bucket the brief asked about, and it applies uniformly to all 20 patterns
because they all share this one dispatch call.

**One exception, verified by reading the file:** `SDFKnob.shader` (and by inspection, `SDFKnobRM.shader`
follows the same pattern) declares **no `aspectScale`/`uvIso` at all**. Its main-body (`fillComponent`)
and nub pattern calls pass the raw `uv = IN.texcoord` straight into `ApplyMaterialPattern`, and only
the knob **face** component computes a separate `faceUV = pos + float2(0.5,0.5)` from an already
`[-1,1]`-remapped `pos`. Knobs are assumed to sit in a square bounding box; if a knob's
RectTransform is stretched non-square, its body/nub pattern will stretch too where Button/Panel/
Slider/Toggle patterns would not. This is a real, code-verified asymmetry across the widget family,
not a guess.

### 1.2 Per-pattern parameter map, look, and visibility range

`noise()` (`UIMath.cginc`) is value noise with a **1-unit period** on its input (`floor(p)` cell
lookup) — confirmed by reading it — so wherever a pattern multiplies `uv` by some frequency `F`
before calling `noise`, `F` is literally "how many noise cells fit across the widget's UV span."
`VoronoiNoise`/`VoronoiEdge`/`FBMNoise` are assumed unit-period too (same hash lattice), consistent
with every pattern's own internal comments about "density"/"scale" ranges — flagged here as
assumed-from-context rather than independently re-derived, since `UIMath.cginc` internals were not
in the required reading set for this doc.

For each pattern, **total visible frequency ≈ `patternScale` × (pattern's own internal multiplier,
itself driven by `p1` in nearly every case)**. The Properties-block slider for `patternScale` is
**`Range(1, 100)`, default 20** on every section of every widget *except* `_NubPatternScale` on
`SDFKnob`/`SDFKnobRM`, which is `Range(0.1, 10)`, default 1 — the nub is small enough that even 1.0
is dense, so its floor was set an order of magnitude lower. This matters directly for "visible on a
40×40 control": because `patternScale` cannot go below 1 anywhere else, **the density/"detail" knob
(`p1`, generically labelled "Pattern Detail" in the Properties block) is the primary lever for
making a busy pattern read as a few large features on a small control — not `patternScale` alone.**
The table below gives, per pattern, the internal multiplier's `lerp(min,max,p1)` range so you can
compute this directly, plus the resulting cycle count at the floor (`scale=1, p1=0`) and at a
"large panel" setting. These are derived analytically from the formulas (unit-period noise), not
visually verified in-editor — treat them as a starting point and confirm in the Designer preview.
Real shipped skins (see the note at the end of this section) often run patternScale much higher than
"clearly legible individual features" would suggest, because many finishes are meant to read as a
*fine, subtle* material grain rather than a decorative tile — that's a valid choice too, just a
different goal from "clearly visible."

| # | Name | Look | p1 | p2 | p3 | Ignored | Frequency formula (approx.) | @40×40 (chunky) | @240×120, 120px short side (fine) |
|---|------|------|----|----|----|---------|------------------------------|------------------|-------------------------------------|
| 0 | Plastic | Smooth surface, subtle multi-octave noise blobs, optional metallic flake sparkle | octaves 1–4 (`clamp(int(p1*3)+1,1,4)`) | domain-warp distortion blend | flake sparkle amount (freq ×3) | — (all 3 used) | `scale` (octave-0 freq = scale) | scale 3–6, p1 low (1 octave) | scale 15–30 |
| 1 | Metal | Anisotropic linear brushed streaks | grain direction angle (0°–180°) | anisotropy ratio `lerp(0.05,0.3,p2)` — **low p2 = MORE stretched/longer streaks** | streak-variation blend | — | `scale` along grain direction | scale 2–6 | scale 10–30 |
| 2 | RadialBrushed | Angular grooves radiating from widget centre + optional concentric rings | groove-count multiplier `lerp(0.5,2,p1)` | groove-noise irregularity `lerp(0.1,0.5,p2)` | concentric ring frequency `lerp(5,30,p3)` + ring blend | — | spokes = `scale × lerp(0.5,2,p1)` around full circle | scale 6–12 | scale 18–36 |
| 3 | CarbonFiber | Woven checkerboard of two perpendicular fiber directions, optional clear-coat gloss | weave period `lerp(2,8,p1)` | weave-crossing contrast (not freq) | glossy-coat blend (not freq) | — | `scale × lerp(2,8,p1)` | scale 1 (floor), p1 low → 2 squares | scale 2.5–5, p1 mid |
| 4 | Leather | Organic Voronoi-cell grain with pores, optional warp + edge cracks | pore density `lerp(3,12,p1)` | organic warp blend | crack depth at cell edges | — | `scale × lerp(3,12,p1)` | scale 1, p1 low → 3 pores | scale 2–4 |
| 5 | BrushedCross | Two crossed brush-stroke directions | cross half-angle `lerp(0.3,1.57,p1)` (17°–90°) | stroke-noise irregularity | blend ratio between the two stroke layers | — | `scale × 3` (fixed internal ×3) | scale 1 → 3 bands | scale 5–10 |
| 6 | Satin | Smooth directional sheen band + soft low-freq noise | sheen band width `lerp(0.5,3,p1)` | flow-distortion blend | shimmer sparkle amount (freq ×4) | — | `scale × lerp(0.5,3,p1)` | scale 1–2, p1 low | scale 2–5 |
| 7 | Concrete | Rough FBM base + Voronoi aggregate pebbles + optional cracks | aggregate scale `lerp(2,8,p1)` (also visibility weight) | crack frequency `lerp(1,4,p2)` + weight | roughness-variation blend (not freq) | — | base `scale×2` (fixed) + aggregate `scale×lerp(2,8,p1)` | scale 1, p1 low → 2 pebbles | scale 3–6 |
| 8 | Fabric | Woven warp/weft threads | thread density `lerp(5,25,p1)` | thread-spacing jitter | warp/weft emphasis ratio (not freq) | — | `scale × lerp(5,25,p1)` | scale 1, p1 low → 5 threads (~8px each) | scale 2.5–5, p1 mid-high |
| 9 | Paper | Matte multi-octave fiber grain + optional stains | fiber density `lerp(1,4,p1)` (× fixed 3/6/12 sub-octaves) | blotch/stain amount | tooth depth (amplitude, not freq) | — | `scale × lerp(1,4,p1) × 3` (finest sub-octave) | scale 2–4 (paper is meant to stay fine/subtle even small) | scale 8–16 |
| 10 | Frosted | Sandblasted glass — Voronoi crystals blended toward soft blur | crystal size `lerp(5,20,p1)` | diffusion blend (crystal↔soft, up to 0.7) | opacity-variation blend | — | `scale × lerp(5,20,p1)` | scale 1, p1 low → 5 crystals | scale 1.5–3 |
| 11 | DiamondPlate | Industrial staggered raised-diamond grid | diamond spacing `lerp(2,8,p1)` | raised-height threshold (not freq) | edge sharpness (not freq) | — | `scale × lerp(2,8,p1)` | scale 1, p1 low → 2 diamonds (~20px) | scale 3–6 |
| 12 | Knurled | Diagonal-grid diamond grip texture | grid density `lerp(5,25,p1)` | groove depth `lerp(0.3,1,p2)` (not freq) | round-vs-sharp peak blend (not freq) | — | `scale × lerp(5,25,p1)` | scale 1, p1 low → 5 bumps (~8px) | scale 2–4 |
| 13 | HexGrid | Honeycomb cells with borders + optional indent | cell size `lerp(2,10,p1)` | border width `lerp(0.02,0.15,p2)` (not freq) | indent/concave depth (not freq) | — | `scale × lerp(2,10,p1)` | scale 1, p1 low → 2 hexes (~20px) | scale 2.5–5 |
| 14 | Perforated | Regular round-hole grille | hole density `lerp(3,15,p1)` | hole radius `lerp(0.15,0.45,p2)` (size, not freq) | edge softness (not freq) | — | `scale × lerp(3,15,p1)` | scale 1, p1 low → 3 holes | scale 1.8–3.6 |
| 15 | WoodGrain | Elliptical rings **from a UV corner, not widget centre** (see §7 Gotchas) + fine grain + knots | ring spacing `lerp(3,15,p1)` | ring "wander"/waviness (low-freq, not primary freq) | knot frequency `lerp(1,3,p3)` + ring warp | — | `scale × lerp(3,15,p1)` | scale 1, p1 low → 3 rings | scale 1–2 |
| 16 | Marble | Turbulent directional veining | vein scale `lerp(1,5,p1)` | turbulence octave falloff + displacement weight | vein sharpness (power curve 1–4) | — | `scale × lerp(1,5,p1)` | scale 1, p1 low → 1 broad vein | scale 2–4 |
| 17 | Ceramic | Near-flat glazed base, opt-in crackle, opt-in gloss variation | glaze smoothness `lerp(0.3,1,p1)` (inverse weight on base noise) | **crackle scale `lerp(3,10,p2)` — crackle is entirely OFF unless p2 > 0.01** | gloss-variation weight (not freq) | — | crackle `scale × lerp(3,10,p2)`; base `scale × 0.5` fixed | scale 1–2, p2 > 0 for any structure | scale 4–8 |
| 18 | Circuit | Manhattan-routed PCB traces + junction pads + optional 2nd layer | trace density `lerp(3,12,p1)` | junction-pad probability (density, not spatial freq) | 2nd offset layer blend (adds a second grid at 0.7× density) | — | `scale × lerp(3,12,p1)` | scale 1, p1 low → 3 cells | scale 2–4 |
| 19 | NoiseOrganic | Generic FBM turbulence, abstract/organic | octaves 1–6 (`clamp(int(p1*5)+1,1,6)`) | lacunarity `lerp(1.5,3,p2)` (freq growth per octave) | persistence `lerp(0.3,0.7,p3)` (amplitude falloff) | — | `scale` (octave-0 freq) | scale 2–5 | scale 10–25 |

Real shipped-skin data points (from `Assets/Resources/MaterialStates/*.json`, for calibration):
knob `_KnobPatternScale` values range **4 → 96.9** across different skins/pattern types; panel
`_PanelPatternScale` (pattern type 4 = Leather, used for a "brushed metal" faceplate look) sits at
**46–64** across the Rack faceplate family; `_ButtonBevelPatternScale` commonly sits **16–97**.
These run higher than the "clearly-legible-feature" numbers above because most of these skins want
a fine grain, not a decorative tile.

### 1.3 What `patternContrast` actually does (counter-intuitive — verify before assuming)

```hlsl
pattern = sign(pattern) * pow(abs(pattern), 1.0 / component.patternContrast);
```
This is applied **after** `patternIntensity` has already scaled the raw sample. Because the
exponent is `1/patternContrast`, **raising `patternContrast` above 1 makes the exponent < 1**, which
*lifts* small values disproportionately (e.g. `x^0.5` at `x=0.1` → `0.316`) — the pattern reads
**flatter / more washed-out**, with weak areas pulled up toward strong ones. **Lowering
`patternContrast` below 1** makes the exponent > 1 (e.g. `x^2`), which *crushes* small values toward
zero while barely touching values near 1 — the pattern reads **punchier, sparser, more isolated
peaks** — the classic "increased contrast" look. So the slider's real-world effect is **inverted**
from what "Contrast" normally implies in image-editing tools: **low `patternContrast` = sharp/punchy,
high `patternContrast` = flat/washed-out.** Properties range is `Range(0.1, 5)`, default 1.5 (i.e.
the shipped default already leans slightly toward "washed out").

### 1.4 Pattern colour palette (`patternColorEnabled`)

If `patternColorEnabled < 0.5` (the default), the pattern only modulates brightness:
`baseColor * (1.0 + pattern)`. If enabled, `component.patternColorType` picks how the (already
contrast-shaped) scalar `pattern` maps to a `[0,1]` palette position via `SamplePatternColorPosition`:

```hlsl
if (colorType == PATTERN_COLORTYPE_1)  // GRADIENT — signed [-1,1] → [0,1] linearly
    return saturate((patternValue + 1.0) * 0.5);
if (colorType == PATTERN_COLORTYPE_2)  // FEATURE — magnitude: flat=0, strong peak=1
    return saturate(abs(patternValue));
if (colorType == PATTERN_COLORTYPE_3)  // ZONES — frac(|v| * e): irregular repeating bands, distinct per feature
    return frac(abs(patternValue) * 2.718281828);
// PATTERN_COLORTYPE_4 — BANDS — abs(sin(v * π)): sine banding, good for rings/veins
return abs(sin(patternValue * 3.14159265));
```
That position feeds `InterpolatePatternColors` (2–4 stops `patternColorA..D`, `patternColorUsed`
selects how many; ping-pongs via a triangle wave so it tiles with no hard seam), then
`component.patternColorMode` picks the blend:

```hlsl
if (blendMode == 0) return patternColor * (1.0 + pattern);                      // Modulate
else if (blendMode == 1) return lerp(baseColor, patternColor, saturate(abs(pattern))); // Lerp
else if (blendMode == 2) return baseColor + patternColor * saturate(pattern);    // Additive
else return baseColor * lerp(float3(1,1,1), patternColor, saturate(abs(pattern))); // Multiply
```
**The alpha channel of `patternColorA..D` is never read** — `InterpolatePatternColors(...).rgb` is
the only part consulted. Setting a pattern-colour stop's alpha to 0 has zero effect.

### 1.5 Rotation / animation coupling

`patternOffset` (degrees, static) always applies. If `patternRotateWithValue > 0.5`, the sample
frame additionally rotates by `currentValue * angleRange` — i.e. the pattern **spins with the
control's live value** (only meaningful for Knob/Slider, which pass real `_Value`/`_AngleRange`;
Button/Panel pass `0.0, 0.0` so this branch is inert there). Otherwise, if `patternModWithValue >
0.5`, a sinusoidal "shimmer" rotation of `patternModAmount` degrees at `patternModFrequency` cycles
per full value sweep is added instead. The normal-offset used for lighting (`normalOffset`, driving
`specularMod`'s bump) is **counter-rotated** by the same angle so the lighting response stays
consistent regardless of pattern spin.

---

## 2. The Gradient Table

```hlsl
#define GRADIENT_LINEAR       0
#define GRADIENT_RADIAL       1
#define GRADIENT_ANGULAR      2
#define GRADIENT_DIAMOND      3
#define GRADIENT_TRIANGLE     4
#define GRADIENT_BEVEL_DEPTH  5  // RM-only, see §2.2
#define GRADIENT_BEVEL_WALLS  6  // RM-only, see §2.2
```

### 2.1 The five spatial gradients (dispatched through `GetGradientPosition`)

```hlsl
switch (gradientType)
{
    case GRADIENT_LINEAR:   return LinearGradient(uv, direction, time, speed, scale, offset);
    case GRADIENT_RADIAL:   return RadialGradient(uv, time, speed, scale, offset);
    case GRADIENT_ANGULAR:  return AngularGradient(uv, time, speed, scale, offset);
    case GRADIENT_DIAMOND:  return DiamondGradient(uv, time, speed, scale, offset);
    case GRADIENT_TRIANGLE: return TriangleGradient(uv, direction, time, speed, scale, offset);
    default: return 0.5;   // unknown type, or the RM-only 5/6 fall through here in this dispatcher
}
```

| Type | Name | What it does | `direction` | `centre` | `scale` | `offset` | `speed` |
|---|---|---|---|---|---|---|---|
| 0 | Linear | `dot(uv, normalize(direction))` — straight-line sweep along `direction` | **used** | n/a | multiplies the dot product (higher = more repeats across the quad) | added to position | animates (see §7 Gotchas) |
| 1 | Radial | `length((uv-0.5)*2)` — rings from UV centre `(0.5,0.5)` | ignored | fixed at UV centre — **not configurable** | ring spacing | phase shift | animates |
| 2 | Angular | `atan2(uv.y-0.5, uv.x-0.5)/(2π) + 0.5` — sweeps around UV centre | ignored | fixed at UV centre | sweep multiplier (>1 repeats the sweep multiple times per revolution) | phase shift | animates |
| 3 | Diamond | Taxicab distance `(|dx|+|dy|)*2` from UV centre | ignored | fixed at UV centre | ring spacing | phase shift | animates |
| 4 | Triangle | Same dot product as Linear, but passed through `TriangleWave` (ping-pong) for guaranteed seamless repetition | **used** | n/a | repeat frequency | phase shift | animates |

All five interpolate `colorA..D` through `InterpolateGradientColors`, which — like the pattern
palette — **ping-pongs** (`t = 1 - |frac(t*0.5)*2 - 1|`) so 2/3/4-stop gradients tile without a hard
seam, using `gradientNumColors` (2, 3, or 4; Properties `IntRange(2,4)`, default 4) to pick how many
stops are actually blended between.

**`manualPosition` only engages when `speed == 0 AND manualPosition > 0`** — a `manualPosition` of
exactly `0` will *not* trigger the override branch (it's indistinguishable from "not set"), even
though 0 is a perfectly legitimate sweep position. When it does engage, it **replaces** the entire
spatial term: `gradientPos = manualPosition * scale + offset` — `direction` and the UV-based shape
of the gradient are bypassed entirely; only `scale`/`offset` still apply.

### 2.2 The two RM-only bevel-topology gradients (5/6)

These are **not** computed through `GetGradientPosition`/`GetGradientColor` at all — the generic
dispatcher's `default:` case returns `0.5` for types 5/6, so if anything routed a bevel-topology
type through the ordinary gradient path it would silently produce a flat mid-grey. Instead they are
hand-implemented separately inside `SDFButtonRM.shader` and `SDFKnobRM.shader`, driven by the 2D SDF
surface normal at the raymarched hit point on a `SURFACE_WALL` (only meaningful there — e.g. a
knob's fluted/grooved side wall):

- `normalDot = dot(surfaceNormal2D, radialOutward)`: `+1` = outer wall, `0` = slit side, `-1` = slit back.
- `tangentialMag = |dot(surfaceNormal2D, tangentDir)|`: `1` = pure tangential (slit sides).

| Type | Name | What it does | `scale` | `offset` |
|---|---|---|---|---|
| 5 | BevelDepth | Linear `A(outer)→D(back)` ramp across `normalDot`: `t = saturate((1-normalDot)*scale + offset)`, then a direct piecewise lerp across up to 4 stops (bypasses the ping-pong triangle wave — always a straight A→D ramp) | range multiplier: `1` maps the full `[0,1]` of `normalDot` to the full A→D span; `2` means only the top half of `normalDot` fills all the stops (steeper ramp) | shifts the ramp — positive pushes toward D, negative toward A |
| 6 | BevelWalls | 4-zone partition using both `normalDot` and `tangentialMag`: A=outer wall, B=side outward-leaning, C=side inward-leaning, D=groove/slit back. Weights are constructed so `wA+wB+wC+wD == 1` by construction | transition sharpness: `1` = soft blended zone edges, `5` = sharp/crisp zone boundaries (`sharpK = 0.09/max(0.3,scale)`) | shifts the outer-vs-groove `normalDot` threshold, `outerTh = 0.65 + offset*0.15`, roughly `±2` range |

### 2.3 Dead/unused pieces (verified, not guessed)

- `GradientParams.globalBlend` / `.globalIntensity` are struct fields but **`GetGradientColor` never
  reads them** — the real "blend toward the scene-wide gradient" effect is a completely separate
  mechanism (`CalculateGlobalGradient` in `UIRenderer.cginc`, driven by the widget's own
  `_XxxGlobalBlend`/`_XxxGlobalIntensity` properties and the screen-space `_GlobalGradient*`
  uniforms in `UIGlobalUniforms.cginc`), applied by the widget shader as its own extra `lerp` step,
  not inside the gradient system at all.
- `BlendGradients` (LERP/MULTIPLY/ADD/OVERLAY/SCREEN blend modes) is only ever called from
  `UIEffects.cginc`'s `CombineEffectLayers`, and **`UIEffects.cginc` itself is not `#include`d by any
  current widget shader** (grep-verified across `Assets/Shaders`) — see §7 Gotchas.

---

## 3. The Lighting Model

### 3.1 What a light *is*

```hlsl
struct UILight
{
    bool   enabled;
    float3 direction;    // travel direction, see §3.2 sign convention
    float  intensity;
    float4 color;         // .rgb tint, .a always forced to 1.0 by UIGlobalLight
    float  specular;
    float  specularPower;
};
```
There are exactly **three lights, "the rig"**, shared by every widget on screen — published once per
frame by `UiSceneDirector` (runtime) or `GlobalLightingPlugin` (designer preview) as three plain
uniform triples per light:
```
_GlobalLightPosN   = (x, y, height)      // x is aspect-scaled, same space as the widget's _Position
_GlobalLightColorN = (r, g, b, intensity)
_GlobalLightFxN     = (enabled, specular, specularPower, unused)
```
`UIGlobalLight(gPos, gColor, gFx, objectPos)` builds a `UILight` from these three vectors plus the
consuming widget's own `_Position.xy`:
```hlsl
light.enabled       = gFx.x > 0.5;
light.direction     = UILightDirection(gPos, objectPos);
light.intensity     = gColor.w;
light.color         = float4(gColor.rgb, 1.0);
light.specular      = gFx.y;
light.specularPower = gFx.z;
```
So **specular intensity and specular power are entirely rig-level, not skin-level** — no
`.states.json` property changes a light's own specular tightness or strength; a skin can only change
how its *surface* responds (bevel shape, `patternSpecularEffect`, `patternRoughnessEffect` — see
§3.4). `UIDisplaySurface.cginc`'s comments give the rig's real defaults for context: `gFx.z` (spec
power) defaults to `32` and `gFx.y` (specular) defaults to `0.25`.

There is no 4th "ambient light" object — ambient is a separate scalar, see §3.3.

### 3.2 Sign convention (verbatim from `UILighting.cginc`, lines 53–72 — read before touching this)

> ```
> SIGN CONVENTION — read before touching this.
>
>   lightDir.xy = the direction the light TRAVELS, lamp → surface.
>   lightDir.z  = + toward the viewer, so a flat face (N = 0,0,1) stays lit.
>
> It is NOT a "to-light" vector, and the two halves genuinely disagree in sign. That
> looks wrong until you check the consumers, which were all written to it:
>   • CalculateShapeBevelNormal uses edgeDir = -sdfGradient, so a raised bevel's normal
>     points INWARD. Lit means dot(N, L) > 0, which needs L.xy pointing away from the lamp.
>   • The flat shadow offset samples at `p - ld2*dist`, drawing the shadow at +ld2 —
>     away from the lamp only if ld2 already points away from it.
> Returning `lightPos - objectPos` here instead (a to-light vector) lit the side AWAY
> from the lamp and threw the shadow onto the SAME side as the lamp — both halves of
> the long-standing bug, from this one sign.
>
> z is the lamp's HEIGHT above the UI plane and is what makes it grazing rather than
> head-on. Clamped, not defaulted: an unpublished rig gives a head-on light rather
> than a degenerate in-plane one.
> ```
```hlsl
float3 UILightDirection(float3 lightPos, float2 objectPos)
{
    return normalize(float3(objectPos - lightPos.xy, max(lightPos.z, 0.02)));
}
```
A companion function, `UIToLightVector(travelDir) = float3(-travelDir.xy, travelDir.z)`, flips only
the XY half back to a true to-light vector for the few consumers that need a surface-out-facing
normal instead of a bevel's inward-facing one (`UIDisplaySurface.cginc`'s glass/plastic cover, whose
normal points *out* at the viewer, uses this everywhere instead of the raw travel vector).

### 3.3 `_LightingAmbient` and the ambient/direct trade-off

`_LightingAmbient` is a real per-skin Properties-block float — `Range(0, 2)`, default `0.3` (checked
in `SDFButton.shader`). It is **not** blended against the direct terms — `ApplyUILighting` uses it as
a flat starting multiplier, then **adds** each enabled light's diffuse and specular on top:
```hlsl
finalColor = baseColor;
finalColor *= ambientIntensity;
// per light:
finalColor += baseColor * ndotl * light.intensity * light.color.rgb;      // diffuse, additive
finalColor += light.color.rgb * spec * light.specular * specularMod;      // specular, additive
return saturate(finalColor);                                              // clipped at the very end
```
So it's not "ambient trades off against direct" in the sense of an energy-conserving blend — it's a
floor, and the only thing that stops brightness running away is the final `saturate`. The practical
trade-off is about **headroom before clipping**: a high `_LightingAmbient` (near 2) leaves almost no
room before diffuse+specular clip to white, which **flattens the read of any bevel** (because the
whole point of a bevel is that `ndotl` varies across it — once everything clips to 1.0, that
variation is invisible). A low `_LightingAmbient` preserves that per-pixel `ndotl` variation as
visible brightness contrast, which is what actually sells the 3D bevel shape. **On a perfectly flat
section (no bevel, no pattern normal perturbation) the normal is a constant `(0,0,1)` everywhere —
`ndotl` is then constant across the whole surface and lighting cannot shape it at all; only a
bevel or a pattern's `normalOffset` gives lighting anything to vary over.**

### 3.4 Matte vs glossy vs metallic — what a skin can actually control

There's no explicit "roughness"/"metallic" material knob at the skin level (specular power/intensity
are rig-owned, §3.1). The available levers, all indirect:

- **Bevel shape is the primary lever for specular "pop."** Since a flat face has a constant normal,
  making a highlight band exist at all requires `bevelDepth` ≠ 0 (see §4). A tighter/sharper bevel
  (`bevelSmoothness` low, `bevelDistance` small) gives a thin, crisp highlight ring that reads more
  "glossy/metallic"; a broad, soft bevel (`bevelSmoothness`/`bevelDistance` larger) diffuses the
  highlight across more of the surface, reading more "matte/plastic."
- **`patternRoughnessEffect`** feeds `normalOffset = float2(-ddx(pattern), -ddy(pattern)) *
  patternRoughnessEffect` — this perturbs the lit normal per-pixel using the pattern's own screen
  derivative. High values break up the specular highlight into a broken/matte-looking scatter
  (rough plastic, concrete, fabric); near 0 keeps the underlying bevel highlight clean and glossy
  regardless of what pattern is painted on top.
- **`patternSpecularEffect`** feeds `specularMod = 1 + pattern*patternSpecularEffect*10` — this
  modulates how strongly the *existing* specular response is boosted/dimmed by the pattern's local
  value. High values with an anisotropic pattern (Metal, BrushedCross, RadialBrushed, CarbonFiber)
  give the streaky, direction-dependent glint associated with brushed metal; 0 leaves specular
  response uniform regardless of the pattern.
- **`_LightingAmbient` low + pattern/bevel contrast high** reads more "metallic" (metals have very
  little diffuse albedo — nearly all their visible brightness comes from specular, tinted by the
  light's own colour, not the base colour) — pairing this with a desaturated/grey `_XxxColor` and one
  of the anisotropic patterns above is the practical recipe used by the shipped Rack faceplate skins
  (Leather pattern type, oddly, is what they use for "brushed metal" — see §7 Gotchas about not
  trusting pattern names).

### 3.5 The removed `_LightingLightNGlobalEnabled` flag — correction to a common assumption

**This flag no longer exists in the codebase.** `UILighting.cginc`'s own header (lines 31–51)
documents that it — along with a full per-material copy of each light (direction/intensity/color/
specular/specularPower × 3 lights = 21 uniforms) — was **deliberately removed**:

> *"Skins used to carry a full copy of each light … plus a `_LightingLightNGlobalEnabled` flag to
> pick between that copy and the rig. That is 21 uniforms and three runtime branches per shader, in
> the fragment program, for a choice no skin actually wants to make differently — and it is what
> pushed SDFKnobRM's fragment program past the HLSL compiler's time limit. All of it is gone. A
> light is the rig's light."*

Grep-verified: `GlobalEnabled` does not appear anywhere in the shader source except inside that one
historical comment. **There is currently no per-control opt-out from the shared light rig** — every
widget always reads `_GlobalLightPos1/2/3`, `_GlobalLightColor1/2/3`, `_GlobalLightFx1/2/3` via the
`UI_LIGHT_1/2/3` macros. A skin cannot give one control its own "studio light" independent of the
scene; that capability existed once and was intentionally deleted for compile-time reasons.

---

## 4. Bevel Normals (`CalculateShapeBevelNormal`)

```hlsl
float3 CalculateShapeBevelNormal(float shapeSDF, float bevelDepth, float bevelDistance,
    float bevelSmoothness, float fillFaceSmoothness, int profileType, float profileSharpness,
    float2 aspectScale = float2(1,1))
```
Mechanically:
1. **Bevel band** — active where the fragment is inside the shape (`shapeSDF < 0`) and within
   `bevelDistance` of the edge. `profileType` picks the cross-section: `0` = **Dome**, a smooth
   `smoothstep` S-curve roll-off (default); `1` = **Linear**, a constant-slope angled shelf whose
   slope is scaled by `profileSharpness` (`0` = flat, `1` = full depth) — this only matters when
   `profileType == 1`.
2. **Fill-face profile** — if `fillFaceSmoothness != 0` and the fragment is inside the shape, a
   `sin(depth * π/2)` dome profile (physically-correct hemisphere shape) is layered on top of the
   flat interior face, scaled by `fillFaceSmoothness`. Per `UIComponents.cginc`'s own comment:
   `0 = flat, positive = outward (dome/pillow), negative = inward (divot/bowl)`.
3. **Edge direction** — taken from the **screen-space derivative of the SDF itself**
   (`ddx(shapeSDF), ddy(shapeSDF)`), not from any analytic shape formula — so it works for
   *any* shape, including composited/unioned ones. `edgeDir = -sdfGradient/|sdfGradient|` — this
   points **inward** for a normal SDF sign convention (negative inside), which the file's own
   comment says is deliberate: *"a raised bevel's normal points INWARD"* to match the light sign
   convention in §3.2.
4. **Raised vs recessed** — `if (bevelDepth < 0.0) edgeDir = -edgeDir;` — this is the entire
   raised/recessed switch. Positive `bevelDepth` keeps the inward-pointing normal (reads as a
   pillowed/raised bevel under the sign convention above); negative flips it outward (reads as a
   pushed-in groove/divot).
5. Final: `normal.xy = edgeDir * totalDepth; normal.z = 1 - abs(totalDepth)*0.5;` then normalized.
   `totalDepth = bevelFactor*abs(bevelDepth) + fillFactor`, so it can exceed the "sane" `[0,1]` range
   if `bevelDepth` and `fillFaceSmoothness` are both pushed to their extremes simultaneously —
   `normal.z` can go negative in that case (`totalDepth > 2`), which isn't clamped.

**Note on `aspectScale`:** the function signature accepts one, but a comment at the gradient
computation explicitly says it's **not used** — the SDF is already in "equi-pixel" (isotropic)
space, so `ddx`/`ddy` already give equal magnitudes on horizontal and vertical edges; dividing by
`aspectScale` was tried and found to be a bug (it produced a 4× Y-bias at 4:1 aspect). The parameter
exists for signature compatibility but its value is dead in the function body.

### Numeric ranges (from `SDFButton.shader`'s Properties block — same names/ranges repeat across widgets)

| Property | Range | Default | Subtle | Extreme |
|---|---|---|---|---|
| `_ButtonBevelDepth` | `-1.0 .. 1.0` | `0.2` | Near 0: almost no bevel — flat, lighting can't shape it at all (see §3.3). | Near ±1: `totalDepth` can exceed 1, `normal.z` can go negative — very steep, near-grazing shading, harsh light/dark transitions. |
| `_ButtonBevelSmoothness` | `0.001 .. 1.0` | `0.02` | Near 0.001: razor-sharp bevel edge, a crisp 1–2px highlight ring. | Near 1.0: extremely soft transition — if `bevelDistance` is also large the whole face gradates instead of showing a distinct rim. |
| `_ButtonBevelDistance` | `0.001 .. 1.0` | `0.1` | Small (~0.01–0.05): thin rim bevel, most of the face stays flat. | Large (approaching the shape's own half-extent): bevel consumes the entire face, no flat top remains — reads as a dome/pillow rather than a beveled plate. |
| `_ButtonFaceSmoothness` (`fillFaceSmoothness`) | `-1.0 .. 1.0` | `0.0` | Near 0: flat interior face. | Near ±1: strong dome (+) or bowl/divot (−) curvature across the whole interior, independent of the bevel ring. |
| `_ButtonBevelProfileType` | `Int` (enum `BevelProfileType`) | `0` (Dome) | — | `1` = Linear (angled shelf); combine with `_ButtonBevelProfileSharpness` `Range(0,1)` default `0.5`. |

---

## 5. Compositing

Every widget composites its layered sections by hand with a single premultiplied "over" operator,
`buttonCompositeOver` (`CG/SDF/SDFButtonLayers.cginc`):

```hlsl
void buttonCompositeOver(inout float4 dst, float3 srcColor, float blendAlpha)
{
    float oneMinusAlpha = 1.0 - blendAlpha;
    dst.rgb = dst.rgb * oneMinusAlpha + srcColor * blendAlpha;
    dst.a   = dst.a + blendAlpha * (1.0 - dst.a);
}
```
This is standard Porter-Duff "over" with alpha accumulation. `srcColor` is **always RGB only** — the
function has no way to consult a colour's own alpha channel. Callers construct `blendAlpha`
themselves, always as `<geometric SDF mask> * <a render-alpha property>`, e.g.
`buttonCompositeOver(finalColor, litColor, bodyMask * bodyComponent.alpha)`. The convention across
every widget/section, matching CLAUDE.md's numbered-section layout, is: check the section's
`_XxxEnabled` float guard, compute/sample the section's colour, compute its SDF-derived mask
(antialiased via `fwidth`), then composite once with `buttonCompositeOver`. Sections run in a fixed
literal order in the fragment function and simply overwrite what came before wherever their mask is
opaque — there's no separate blend-mode choice per section, only replace-under-alpha.

**What silently makes a layer invisible** (all verified in code, not assumed):
- The section's `_XxxEnabled` guard is off — the whole block is skipped (no color computed at all).
- The geometric mask is 0 — outside the SDF's antialiased edge, or explicitly zeroed by a guard
  (e.g. `SDFButton.shader` zeroes `bodyMask` entirely when the face is disabled and there's no rim
  to show, to avoid a "ghost ring" artefact from two coincident smoothsteps firing at once).
- The render-alpha property (`_XxxRenderAlpha`, or `component.alpha`) is 0.
- **A colour's own alpha channel is not consulted for body/base colours** —
  `RenderUIComponent`/`RenderCircularComponent`/`RenderRingComponent` in `UIRenderer.cginc` are the
  only functions in the whole codebase that read `component.color.a`, and **none of the current
  widget shaders call them** (grep-verified — every widget composites by hand with
  `buttonCompositeOver` instead). So setting e.g. `_ButtonColor`'s alpha to 0 in a colour picker,
  expecting the button body to become transparent, **does nothing** — you must use
  `_ButtonRenderAlpha` (or the enable flag, or the mask) instead.
- **Gradient stop alpha, by contrast, is meaningful** — `baseColor = lerp(baseColor,
  gradientColor.rgb, gradientColor.a)`, so a gradient stop's alpha is really a per-position "how much
  should this gradient show through over the base colour" blend weight, not a transparency value in
  the final composite. All four default gradient colour stops ship with alpha `1`. If you author a
  gradient with a stop at alpha `0`, that stretch of the gradient does nothing and the base colour
  shows through unmodified even though `gradientEnabled` is on.
- **Pattern palette colour alpha is never consulted at all** (§1.4) — always ignored regardless of value.

---

## 6. SDF Primitives + Operations

### 6.1 Primitives (`SDFPrimitives.cginc`)

| Function | Signature | Meaning |
|---|---|---|
| `OpRound` | `(sdf, radius)` | Expands the shape outward by `radius` (positive) or inward (negative) — dilates/eats the existing SDF, doesn't need shape-specific math. |
| `CircleSDF` | `(p, r)` | Distance to a circle of radius `r` centred at origin. |
| `RectangleSDF` | `(p, size)` | Distance to an axis-aligned box, half-extents `size`. |
| `RoundedRectSDF` | `(p, size, r)` | Box with uniform corner radius `r` (radius eats into `size`). |
| `EllipseSDF` | `(p, ab)` | Exact distance to an ellipse with semi-axes `ab` (closed-form cubic solve — the "hard" SDF in the library). |
| `TriangleSDF` | `(p, a, b, c)` | Distance to an arbitrary triangle defined by 3 points. |
| `PieSDF` | `(p, c, r)` | Circular sector/pie wedge; `c` = `(sin,cos)` of the half-aperture angle. |
| `RingSDF` | `(p, n, r, th, ru)` | Open ring arc of centre-radius `r`, thickness `th`, aperture defined by `n = (sin,cos)`, with `ru` corner rounding via `OpRound`. |
| `CutDiskSDF` | `(p, r, h)` | A disk of radius `r` with a flat chord cut off at height `h`. |
| `HexagonSDF` | `(p, r)` | Regular hexagon, flat-top, circumradius `r`. |
| `PentagonSDF` | `(p, r)` | Regular pentagon, circumradius `r`. |
| `StarSDF` | `(p, r, n, m)` | Generic `n`-pointed star, `r` = outer radius, `m` = inner-point sharpness divisor. |
| `RhombusSDF` | `(p, b)` | Rhombus/diamond with half-diagonals `b`. |
| `TrapezoidSDF` | `(p, a, b, ra, rb)` | Trapezoid between points `a`/`b` with radii `ra`/`rb` at each end. |
| `HeartSDF` | `(p)` | Fixed unit heart shape (not parameterized by size — scale `p` before calling). |
| `CrossSDF` | `(p, b, r)` | Plus/cross shape, arm half-extents `b`, corner rounding `r`. |
| `ArrowSDF` | `(p, a, b, w1, w2)` | Arrow shaft from `a`→`b` (widths `w1`→`w2`) with a triangular head at `b`. |
| `ArcSDF` | `(p, radius, thickness, startAngle, angleRange, roundedEnabled)` | Ring-band arc using the **UI angle convention: 0° = top, clockwise positive**; `roundedEnabled` adds round end caps via a k-based corner blend. This is the same convention every knob/slider arc-fill uses. |
| `getSDFAlpha` | `(sdfDistance, aaFactor=0.75)` | `fwidth`-based antialiased alpha mask from a raw SDF distance. |
| `SmoothRing` | `(dist, innerRadius, outerRadius, smoothness)` | Ring mask (not a true SDF — built from two `smoothstep`s) from a raw centre-distance value. |
| `SmoothCircle` | `(dist, radius, smoothness)` | Filled-circle mask, same raw-distance style as `SmoothRing`. |

### 6.2 Operations (`SDFOperations.cginc`)

| Function | Signature | Meaning |
|---|---|---|
| `OpUnion` | `(d1, d2)` | `min(d1,d2)` — combine two shapes (closest wins). |
| `OpSubtraction` | `(d1, d2)` | `max(-d1, d2)` — **cuts `d1` out of `d2`** (note the argument order: the *first* argument is the shape being removed, the *second* is the base you're cutting into — a common source of confusion). |
| `OpIntersection` | `(d1, d2)` | `max(d1,d2)` — overlap of both shapes. |
| `OpSmoothUnion` | `(d1, d2, k)` | Polynomial-smoothed union, blend radius `k`. |
| `OpSmoothSubtraction` | `(d1, d2, k)` | Smoothed version of `OpSubtraction` — same `d1`-cut-from-`d2` argument order. |
| `OpSmoothIntersection` | `(d1, d2, k)` | Smoothed intersection. |
| `OpTranslate` | `(p, offset)` | `p - offset` — shift the sampling point. |
| `OpRotate` | `(p, angle)` | Rotate the sampling point by `angle` radians. |
| `OpScale` | `(p, scale)` | `p / scale` — non-uniform scale of the domain (note: distances are no longer metric after non-uniform scale — a known SDF caveat, not specific to this file). |
| `OpRepeat` | `(p, c)` | Infinite tiling with period `c` (centred cell). |
| `OpRepeatLimit` | `(p, c, l)` | Tiling with period `c`, clamped to `±l` copies per axis (finite repeat). |
| `OpMirror` | `(p, n)` | Reflects `p` across the plane with normal `n` where it's on the wrong side. |
| `OpDisplace` | `(sdf, p, amplitude, frequency)` | Adds a `sin(x)*sin(y)` ripple of the given amplitude/frequency to the distance — cheap surface noise, not geometrically exact. |
| `OpTwist` | `(sdf, p, amount)` | **Dead code as written** — computes a twisted coordinate `q` but then returns the original `sdf` unchanged; the twist has no effect. |
| `OpBend` | `(sdf, p, amount)` | Same issue as `OpTwist` — computes a bent coordinate `q`, returns `sdf` unmodified. |
| `OpOnion` | `(sdf, thickness)` | `abs(sdf) - thickness` — turns a filled shape into a hollow shell/outline of the given thickness. |
| `SDFToAlpha` | `(sdf, edgeWidth)` | Alpha mask with a manually-specified antialiasing width. |
| `SDFToAlphaAA` | `(sdf)` | Same, using `fwidth` for automatic 1-pixel antialiasing. |
| `SDFToOutline` | `(sdf, outlineWidth, edgeWidth)` | Ring-shaped outline mask (outer minus inner alpha), manual edge width. |
| `SDFToOutlineAA` | `(sdf, outlineWidth)` | Same, `fwidth`-based automatic edge width. |
| `OpBlend` | `(d1, d2, t)` | Plain `lerp` between two distance fields (not shape-aware — a naive cross-fade, will pinch/distort mid-blend). |
| `OpSoftMin` | `(a, b, k)` | Quadratic soft minimum, blend radius `k`. |
| `OpSoftMax` | `(a, b, k)` | `-OpSoftMin(-a, -b, k)` — quadratic soft maximum. |
| `OpExtrusion` | `(sdf2D, z, h)` | 3D extrusion of a 2D SDF along `z`, half-height `h`. |
| `OpRevolution` | `(p, sdf1D)` | **Effectively a passthrough as written** — comment says "Apply 1D SDF to `length(p.xz) - offset`" but the function just returns `sdf1D` unchanged; the revolution isn't actually performed inside this function (the caller must do the `length(p.xz)` step itself before calling, if this is used at all). |
| `OpElongate` | `(sdf, p, h)` | Stretches a shape along axes by `h` by adding a box-margin term to the base SDF (approximate, standard IQ elongation trick). |
| `OpMorph` | `(sdf1, sdf2, t)` | `lerp` between two SDFs with a `smoothstep`-eased `t` (same cross-fade caveat as `OpBlend`). |
| `OpSmoothMorph` | `(sdf1, sdf2, t, smoothness)` | Morph with a smoothed, `smoothness`-widened transition band around `t=0.5`. |
| `SDFToGlow` | `(sdf, glowDistance, glowIntensity)` | Falloff glow mask outward from the shape edge. |
| `OpWeightedUnion` | `(sdf1..4, weights)` | Union of up to 4 shapes, each pre-scaled by a normalized weight (weights below `0.001` are skipped entirely). |
| `OpExpSmoothMin` | `(a, b, k)` | Exponential-falloff smooth minimum (alternate smoothing curve to `OpSmoothUnion`). |
| `OpPowSmoothMin` | `(a, b, k)` | Polynomial-power smooth minimum (another alternate curve). |
| `FrustumWallNz` | `(bevelDist, shiftAmt)` | Analytic Z component of a frustum/capped-cone wall normal (RM 3D bevel geometry). |
| `FrustumWallLateral` | `(bevelDist, shiftAmt)` | Analytic lateral (XY) component of the same wall normal. |

---

## 7. Gotchas

- **`patternContrast` is inverted from intuition** — low values = punchy/sharp, high values =
  washed-out/flat (see §1.3). The default (`1.5`) already leans toward "flat."
- **Pattern colour stop alpha (`patternColorA..D.a`) and body colour alpha (`_XxxColor.a`) are both
  silently ignored** in every current widget shader. Only gradient stop alpha
  (`_XxxGradientColorA..D.a`) does anything, and there it means "blend weight," not "transparency."
- **Gradients animate by default.** Every `_XxxGradientSpeed` ships at `1.0`, and `time*speed*0.1` is
  added into the gradient position unconditionally unless you explicitly zero it — enabling a
  gradient on a skin without also setting Speed to `0` gets you an unwanted slow scroll/rotate/pulse.
- **`manualPosition` needs `speed == 0 AND manualPosition > 0`** to engage — a manual override
  position of exactly `0` is indistinguishable from "not using manual override" and silently falls
  back to the normal UV-based spatial gradient.
- **Linear/Triangle gradient `direction` left at `(0,0)` will `normalize` to NaN**, corrupting that
  gradient entirely (Radial/Angular/Diamond don't use `direction` at all, so they're unaffected by
  this).
- **`WoodGrain`'s rings are centred at a UV corner `(0,0)`, not the widget's visual centre `(0.5,
  0.5)`.** Every other pattern that needs true centring (`RadialBrushed`) explicitly uses the
  already-centred `pos` (range `[-0.5,0.5]`); `WoodGrain` instead reuses the recombined `uv =
  (pos+center)*scale` (range `[0,scale]`) for its `distFromCenter` calculation. At low `scale` this
  reads as quarter-circle arcs emanating from one corner rather than concentric rings around the
  control — likely not the intended look; needs `patternOffset`/rotation or a scale high enough that
  the difference isn't visible to compensate.
- **`SDFKnob.shader` has no aspect correction at all** (no `aspectScale`/`uvIso`) — its body and nub
  pattern coordinates are raw `IN.texcoord`. Every other widget (Button/Panel/Slider/Toggle)
  aspect-corrects. A non-square knob RectTransform will visibly stretch its pattern where the other
  widgets wouldn't.
- **`patternScale` cannot go below `1` in the Properties UI** (Range floor) on every section except
  `_NubPatternScale` (`Range(0.1,10)`). For a legible "chunky" pattern on a small (~40px) control,
  the effective lever is **`patternParam1` toward `0`** (most patterns' dominant internal frequency
  multiplier), not `patternScale` alone — see §1.2.
- **`UIEffects.cginc` is dead code.** It defines a full `EffectParams`/`EffectLayer` system (Fill,
  Outline, Glow, Shadow, InnerShadow, Bevel, Emboss, Icon, IconBorder, IconGlow) that looks like an
  alternate compositing pipeline, but **no shader in the project `#include`s it** (grep-verified). It
  also would not compile as-is if included: every `Apply*Effect` function calls a 13-argument
  `GetGradientColor(...)` overload that doesn't match either overload actually declared in
  `UIGradients.cginc` (both real overloads take `scale`/`offset` and `gradientType`/`numColors`
  arguments this file omits). Do not treat this file as a working reference for how effects are
  layered — the real compositing convention is `buttonCompositeOver`, hand-called per section (§5).
- **`UIRenderer.cginc`'s `RenderUIComponent` / `RenderCircularComponent` / `RenderRingComponent` are
  also dead** — no widget shader calls them (grep-verified). Only `CalculateGradient`,
  `CalculateGlobalGradient`, and `sampleUIShadowBuffer` from that same file are actually used, called
  directly by the widget shaders. This is also the *only* place `component.color.a` is ever read —
  which is exactly why it's a trap (§5): the code path that would honour a body colour's alpha is
  unreachable.
- **`_LightingLightNGlobalEnabled` (a per-control opt-out from the shared light rig) was removed.**
  See §3.5. Every control always uses the 3-light rig; there is no per-skin "studio light" anymore.
- **`OpTwist` and `OpBend`** in `SDFOperations.cginc` compute a twisted/bent coordinate and then
  discard it, returning the input `sdf` unchanged. **`OpRevolution`** similarly returns its
  `sdf1D` argument unchanged rather than performing the `length(p.xz)` revolution itself. All three
  read as placeholders/incomplete — don't rely on them to do what their names imply.
- **`OpSubtraction(d1, d2)` cuts `d1` out of `d2`**, i.e. argument order is "thing removed, thing
  kept" — easy to reverse by mistake and get the inverse shape.
- **A perfectly flat, unbeveled surface cannot be shaded by the light rig at all** — its normal is a
  constant `(0,0,1)`, so `ndotl` and the specular half-vector term are both constant across every
  pixel. Any "3D-ness" comes entirely from bevel normal perturbation (§4) and/or a pattern's
  `normalOffset` (§1, `patternRoughnessEffect`); raising `_LightingAmbient`/light intensity on a flat
  surface just changes its flat brightness, never its shape.
- **High ambient + high direct light intensity clips to white and erases bevel definition** — because
  `ApplyUILighting` never renormalizes, only `saturate`s at the very end (§3.3).
