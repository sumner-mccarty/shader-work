# Procedural backdrops — `UI/Backdrop/*` (2026-10-08)

A wallpaper that is a **function of position and time** instead of a texture: no tiling, no seam, no resolution,
every look decision a `Properties` entry that a `.states.json` can tune. Each wallpaper TYPE is its own small
shader (nothing is added to `SDFPanel` or to any widget shader), selected by `shaderName` in the states file:

| Shader (`shaderName`) | File | Character |
|---|---|---|
| `UI/Backdrop/Caustics` | `BackdropCaustics.shader` | flowing water: a caustic network over cold colour fields |
| `UI/Backdrop/Splotch` | `BackdropSplotch.shader` | drifting colour pools (metaball-ish); `_Softness` runs smooth mesh-gradient → crisp pools |
| `UI/Backdrop/Ribbons` | `BackdropRibbons.shader` | flowing silk / aurora ribbons whose colour slides along their length |

All three include `CG/Core/UIBackdropFlow.cginc` (sine-free hashes, quintic value noise, fbm, orbit motion, 4-stop
ramp, finishing). **No widget shader includes it**, so SDFKnob / SDFButton / SDFSlider / SDFPanel compile exactly
as before and every shipped skin renders unchanged (`python tests/parity.py check`: 30/30).

## Time: everything is exactly periodic

`cyc = _Time.y * _Speed + _Phase` — `_Speed` is **cycles per second**; every motion is a point walking once round a
circle per cycle, or a phase advanced by a whole number of turns per cycle. So the picture at `cyc` and `cyc + 1`
is identical (measured: mean difference 0.000 over one period for all three), a host can run forever without a
seam, a GIF of one period loops perfectly, and "slow" is just a long period (`_Speed 0.015` = a 67 s loop).
`_Phase` scrubs to a fixed frame for a still render. In slrender a cell's `time` pins `_Time.y`.

## How the glass sees it (host contract — Unity side, not in this repo)

The widget shaders' glass term samples `_UIBackdropTex` at its (refracted) screen position. To make that picture
live, `UiBackdrop` renders the mode's backdrop skin into a mipmapped render texture every frame and binds it:

```csharp
// once: rt = new RenderTexture(w/2, h/2, 0) { useMipMap = true, autoGenerateMips = true, wrapMode = Clamp }
// per frame (style.json mode block carries "backdropSkin": "<Prefix><Mode>Backdrop"):
Graphics.Blit(null, rt, backdropMaterial);          // material = the states file's shaderName + parameters
Shader.SetGlobalTexture("_UIBackdropTex", rt);       // glass parts now refract the LIVE picture
// the visible wallpaper is the same rt drawn behind the UI (overlay canvas, sortingOrder -32000)
```

`"backdrop"` (a texture path) stays in the recipe as the **fallback** for a host that cannot render the skin.
Half-resolution is plenty: glass blurs it by mip level anyway. The look spec chooses and tunes the shader:
`modes[mode]["backdrop_fx"] = {"shader": "Caustics", "params": {...}, "time": 9.0}`
(Tools/lookkit.py writes `<Prefix><Mode>Backdrop.states.json`, validated against the shader's Properties).

## Design rules these shaders follow
* **Legibility is the look's job, not the wallpaper's.** Print must hold at every moment of the loop:
  `Looks/<slug>/flow_demo.py` measures the worst-case contrast of every label against the brightest/darkest
  thing that ever passes behind it. Keep line/pool brightness modest and give glass a dimming tint under print.
* **A lens refracts structure, not a smooth gradient.** Give the wallpaper edges (Caustics lines, Splotch with a low
  `_Softness`, Ribbons with a low `_Softness`) or the glass has nothing to bend.
* Add a type = a new `Backdrop<Name>.shader` + a Properties block; `backdrop_fx.shader` is just the file suffix.

## Properties

### `UI/Backdrop/Caustics`
| Property | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_Color` | Color |  | `(1,1,1,1)` | Tint |
| `_Speed` | Range | 0 – 0.5 | `0.04` | Speed (cycles per second) |
| `_Phase` | Range | 0 – 1 | `0` | Phase (cycles, scrubs a still) |
| `_Aspect` | Float |  | `0` | Aspect override (0 = from the target) |
| `_Scale` | Range | 0.2 – 8 | `1.8` | Scale (features per picture height) |
| `_Warp` | Range | 0 – 2 | `0.7` | Domain warp |
| `_Detail` | Range | 1 – 4 | `3` | Detail (fbm octaves) |
| `_FieldScale` | Range | 0.2 – 4 | `0.9` | Colour field scale |
| `_ColorA` | Color |  | `(0.000, 0.040, 0.090, 1)` | Deep |
| `_ColorB` | Color |  | `(0.050, 0.350, 0.560, 1)` | Mid |
| `_ColorC` | Color |  | `(0.150, 0.650, 0.800, 1)` | Light |
| `_ColorD` | Color |  | `(0.420, 0.160, 0.850, 1)` | Pool |
| `_PoolAmount` | Range | 0 – 1 | `0.7` | Pool amount |
| `_Depth` | Range | 0 – 1 | `0.5` | Depth fade (bright top, dark bottom) |
| `_LineColor` | Color |  | `(0.300, 0.850, 0.950, 1)` | Line colour |
| `_LineStrength` | Range | 0 – 2 | `0.9` | Line strength |
| `_LineWidth` | Range | 0.04 – 0.8 | `0.30` | Line width |
| `_LineLayers` | Range | 1 – 3 | `2` | Line layers |
| `_Brightness` | Range | -0.5 – 0.5 | `0` | Brightness |
| `_Contrast` | Range | 0.5 – 2 | `1` | Contrast |
| `_Saturation` | Range | 0 – 2 | `1` | Saturation |
| `_Vignette` | Range | 0 – 1 | `0.25` | Vignette |
| `_Grain` | Range | 0 – 0.2 | `0` | Film grain |

### `UI/Backdrop/Splotch`
| Property | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_Color` | Color |  | `(1,1,1,1)` | Tint |
| `_Speed` | Range | 0 – 0.5 | `0.03` | Speed (cycles per second) |
| `_Phase` | Range | 0 – 1 | `0` | Phase (cycles, scrubs a still) |
| `_Aspect` | Float |  | `0` | Aspect override (0 = from the target) |
| `_Seed` | Range | 0 – 64 | `3` | Layout seed |
| `_Count` | Range | 1 – 8 | `6` | Blob count |
| `_Size` | Range | 0.05 – 1.2 | `0.34` | Blob radius (picture heights) |
| `_SizeVar` | Range | 0 – 1 | `0.5` | Radius variation |
| `_Spread` | Range | 0.2 – 1.5 | `0.9` | Layout spread |
| `_Drift` | Range | 0 – 0.6 | `0.16` | Drift radius |
| `_Softness` | Range | 0.005 – 1 | `0.30` | Edge softness |
| `_Warp` | Range | 0 – 1 | `0.22` | Edge wobble (noise warp) |
| `_WarpScale` | Range | 0.5 – 8 | `2.4` | Wobble scale |
| `_Opacity` | Range | 0 – 1 | `0.92` | Blob opacity |
| `_Merge` | Range | 0 – 1 | `0.35` | Overlap blending (0 stack, 1 add) |
| `_Base` | Color |  | `(0.030, 0.040, 0.100, 1)` | Base |
| `_ColorA` | Color |  | `(0.070, 0.650, 0.800, 1)` | Blob A |
| `_ColorB` | Color |  | `(0.150, 0.300, 0.950, 1)` | Blob B |
| `_ColorC` | Color |  | `(0.550, 0.200, 0.900, 1)` | Blob C |
| `_ColorD` | Color |  | `(0.950, 0.350, 0.550, 1)` | Blob D |
| `_ColorFlow` | Range | 0 – 1 | `0.0` | Colour breathing (each blob drifts toward its neighbour colour) |
| `_EdgeShade` | Range | 0 – 1 | `0.0` | Edge shade (inner rim) |
| `_Brightness` | Range | -0.5 – 0.5 | `0` | Brightness |
| `_Contrast` | Range | 0.5 – 2 | `1` | Contrast |
| `_Saturation` | Range | 0 – 2 | `1` | Saturation |
| `_Vignette` | Range | 0 – 1 | `0.2` | Vignette |
| `_Grain` | Range | 0 – 0.2 | `0` | Film grain |

### `UI/Backdrop/Ribbons`
| Property | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_Color` | Color |  | `(1,1,1,1)` | Tint |
| `_Speed` | Range | 0 – 0.5 | `0.03` | Speed (cycles per second) |
| `_Phase` | Range | 0 – 1 | `0` | Phase (cycles, scrubs a still) |
| `_Aspect` | Float |  | `0` | Aspect override (0 = from the target) |
| `_Seed` | Range | 0 – 64 | `5` | Layout seed |
| `_Count` | Range | 1 – 6 | `4` | Ribbon count |
| `_Thickness` | Range | 0.02 – 0.6 | `0.14` | Thickness (picture heights) |
| `_Softness` | Range | 0.02 – 1 | `0.45` | Edge softness |
| `_Wave` | Range | 0 – 0.6 | `0.18` | Wave height |
| `_WaveFreq` | Range | 0.3 – 6 | `1.4` | Wave frequency |
| `_Tilt` | Range | -1.2 – 1.2 | `-0.25` | Tilt (radians) |
| `_Spread` | Range | 0.1 – 1.2 | `0.8` | Vertical spread |
| `_Glow` | Range | 0 – 2 | `0.6` | Glow (additive bleed) |
| `_Opacity` | Range | 0 – 1 | `0.9` | Ribbon opacity |
| `_Base` | Color |  | `(0.020, 0.030, 0.080, 1)` | Base |
| `_ColorA` | Color |  | `(0.100, 0.900, 0.650, 1)` | Ribbon A |
| `_ColorB` | Color |  | `(0.350, 0.400, 1.000, 1)` | Ribbon B |
| `_ColorC` | Color |  | `(0.900, 0.250, 0.750, 1)` | Ribbon C |
| `_ColorD` | Color |  | `(1.000, 0.650, 0.250, 1)` | Ribbon D |
| `_ColorSpan` | Range | 0.2 – 6 | `2.2` | Colour span along a ribbon (picture heights per palette) |
| `_Brightness` | Range | -0.5 – 0.5 | `0` | Brightness |
| `_Contrast` | Range | 0.5 – 2 | `1` | Contrast |
| `_Saturation` | Range | 0 – 2 | `1` | Saturation |
| `_Vignette` | Range | 0 – 1 | `0.2` | Vignette |
| `_Grain` | Range | 0 – 0.2 | `0` | Film grain |
