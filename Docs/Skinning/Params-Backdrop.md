# Procedural backdrops and background fields — `UI/Backdrop/*`, `UI/BackdropWindow` (2026-10-08)

A wallpaper that is a **function of position and time** instead of a texture: no tiling, no seam, no resolution,
every look decision a `Properties` entry that a `.states.json` can tune. Each TYPE is its own small shader (nothing is
added to `SDFPanel` or to any widget shader), selected by `shaderName` in a states file:

| Shader (`shaderName`) | File | Character |
|---|---|---|
| `UI/Backdrop/Caustics` | `BackdropCaustics.shader` | flowing water: a caustic network over cold colour fields |
| `UI/Backdrop/Splotch` | `BackdropSplotch.shader` | drifting colour pools (metaball-ish); `_Softness` runs smooth mesh-gradient → crisp pools |
| `UI/Backdrop/Ribbons` | `BackdropRibbons.shader` | flowing silk / aurora ribbons whose colour slides along their length |
| `UI/Backdrop/Plasma` | `BackdropPlasma.shader` | interfering colour waves; `_Sharpness` runs smooth liquid gradient → hard-banded classic plasma |
| `UI/Backdrop/Bokeh` | `BackdropBokeh.shader` | drifting out-of-focus lights with a lens rim, screen-blended |
| `UI/Backdrop/Grid` | `BackdropGrid.shader` | a glowing perspective grid scrolling to a hazy horizon, optional striped sun (retro / synthwave) |
| `UI/Backdrop/Contours` | `BackdropContours.shader` | topographic iso-lines over a slowly reshaping terrain, every Nth line heavier |
| `UI/Backdrop/Starfield` | `BackdropStarfield.shader` | three parallax star layers drifting and twinkling over a faint nebula |

All of them include `CG/Core/UIBackdropFlow.cginc` (sine-free hashes, quintic value noise, fbm, orbit motion, 4-stop
ramp, finishing). **No widget shader includes it**, so SDFKnob / SDFButton / SDFSlider / SDFPanel compile exactly as
before (`python tests/parity.py check`: 30/30). Each backdrop compiles in FXC in ≤ 0.2 s with no loops beyond a fixed
`[unroll]` of ≤ 12 — nothing like the widget shaders' ~10-minute budget.

## Time: everything is exactly periodic

`cyc = _Time.y * _Speed + _Phase` — `_Speed` is **cycles per second**; every motion is a point walking once round a
circle per cycle, a phase advanced by a whole number of turns per cycle, or a scroll by a whole number of cells per
cycle. So the picture at `cyc` and `cyc + 1` is identical (measured 2026-10-08: mean difference 0.000 for all eight),
a host can run forever without a seam, a GIF of one period loops perfectly, and "slow" is just a long period
(`_Speed 0.05` = a 20 s loop). `_Phase` scrubs to a fixed frame for a still render. In slrender, `--time` pins `_Time.y`.

## Three ways the app uses them

### 1. The look's wallpaper (`backdropSkin`)
A recipe mode carries `"backdropSkin": "<Prefix><Mode>Backdrop"` (lookkit writes it from `modes[mode]["backdrop_fx"]`).
`UiBackdrop` renders it every frame into a half-resolution mipmapped RT, draws it behind the whole UI and binds it as
`_UIBackdropTex`, so glass parts refract the LIVE picture. `"backdrop"` (a texture path) stays as the static fallback.

### 2. Named background FIELDS + windows (`"fill"` in a layout)
Any layout node can show a field through a window:
```jsonc
"fill": "ribbons"                                          // shorthand
"fill": { "field": "accent", "opacity": 0.85, "blur": 2, "radius": 14, "inset": 4, "tint": "#FFFFFFE0",
          "brightness": -0.1, "saturation": 1.1, "refract": 8, "refractWidth": 20,
          "rim": 0.8, "rimWidth": 3, "rimColor": "#FFFFFFCC", "sheen": 0.4, "softness": 1 }
```
* **`UiBackdropFields`** renders each field ONCE per frame into a screen-sized mipmapped RT (½ res desktop, ¼ mobile)
  while any window on screen uses it, and frees it after 2 s unused — no subscribe/unsubscribe bookkeeping.
* **`BackdropFill`** (`UI/BackdropWindow`) samples the field at its own SCREEN position, so neighbouring windows on
  one field read as one continuous picture across cards, menus and panels — and each extra window costs one texture
  read. Rounded-rect clip, inset, mip blur, edge refraction, rim light, top sheen; RectMask2D and stencil masks work.
* Placement: on a **container** the window sits behind the children and above a `panelbg` plate (plate → field →
  content). On a **control / panelbg / text** it sits over the node's own graphic and under its children.
* **Name resolution:** `"wallpaper"` (the look's backdrop) → a ROLE the active look maps (recipe mode
  `"fields": {"accent": "<states>"}`; lookkit `modes[mode]["fields"] = {"accent": {"shader": ..., "params": ...}}`
  writes `<Prefix><Mode>Field<Role>`) → a states file by that name → the shipped generic `Field<Type>`
  (`Tools/gen_fields.py` writes `FieldCaustics … FieldStarfield`). Unresolved → the window hides and logs once.
* **Legibility is the layout's job.** A label's ink is chosen from the plate behind it, and a moving field changes
  that plate: over a fill, either dim the window (`"tint"` alpha / negative `"brightness"`), keep the field calm
  (low contrast, slow), or keep print on its own plate. Seen 2026-10-08: plasma behind the DrumPad title bar made the
  dark "PD-48" ink vanish in the field's dark phase.

### 3. Glass
`UI_MATERIAL_V2` glass (Knob/Button/Slider RM, SDFPanel) refracts `_UIBackdropTex` — the wallpaper only, not a
field under it. (A window under a glass control shows the field; the glass itself still bends the wallpaper.)

## Design rules these shaders follow
* **Legibility is the look's job, not the wallpaper's.** Print must hold at every moment of the loop:
  `Looks/<slug>/flow_demo.py` measures the worst-case contrast of every label against the brightest/darkest thing
  that ever passes behind it. Keep line/pool brightness modest and give glass a dimming tint under print.
* **A lens refracts structure, not a smooth gradient.** Give the wallpaper edges (Caustics lines, Splotch with a low
  `_Softness`, Ribbons with a low `_Softness`, Contours, Grid) or the glass has nothing to bend.
* **Derivatives stay out of branches** (FXC): compute everywhere, then select (see BackdropGrid's floor).
* **No reserved words as names** — `line`, `point`, `triangle`, `half` are HLSL keywords/types.
* Add a type = a new `Backdrop<Name>.shader` (+ its Properties block) and a `Field<Name>` preset in `gen_fields.py`;
  `backdrop_fx.shader` / field `shader` is just the file suffix.

## `UI/BackdropWindow` (set by BackdropFill from the layout's `fill`)
| Property | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_Color` | Color |  | `(1,1,1,1)` | Tint |
| `_FieldTex` | 2D |  | `"black" {}` | Field (bound by BackdropFill) |
| `_FieldUV` | Vector |  | `(1,1,0,0)` | Field UV: screen 0..1 -> field (scale xy, offset zw) |
| `_Opacity` | Range | 0 – 1 | `1` | Opacity |
| `_Blur` | Range | 0 – 8 | `0` | Blur (mip level) |
| `_Brightness` | Range | -0.5 – 0.5 | `0` | Brightness |
| `_Saturation` | Range | 0 – 2 | `1` | Saturation |
| `_RectSize` | Vector |  | `(100,100,0,0)` | Rect size (canvas units, set by BackdropFill) |
| `_Radius` | Float |  | `12` | Corner radius |
| `_Inset` | Float |  | `0` | Inset |
| `_Softness` | Range | 0.5 – 16 | `1` | Edge softness (screen px) |
| `_Refract` | Range | 0 – 40 | `0` | Edge refraction (canvas units) |
| `_RefractWidth` | Range | 1 – 80 | `18` | Refraction band (canvas units) |
| `_Rim` | Range | 0 – 2 | `0` | Rim light |
| `_RimWidth` | Range | 0.5 – 24 | `3` | Rim width (canvas units) |
| `_RimColor` | Color |  | `(1,1,1,0.8)` | Rim colour |
| `_Sheen` | Range | 0 – 1 | `0` | Top sheen |

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

### `UI/Backdrop/Plasma`
| Property | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_Color` | Color |  | `(1,1,1,1)` | Tint |
| `_Speed` | Range | 0 – 0.5 | `0.04` | Speed (cycles per second) |
| `_Phase` | Range | 0 – 1 | `0` | Phase (cycles, scrubs a still) |
| `_Aspect` | Float |  | `0` | Aspect override (0 = from the target) |
| `_Scale` | Range | 0.2 – 8 | `1.6` | Scale (features per picture height) |
| `_Warp` | Range | 0 – 2 | `0.6` | Domain warp |
| `_Bands` | Range | 0.25 – 4 | `1` | Colour bands |
| `_Sharpness` | Range | 0 – 1 | `0.15` | Band sharpness |
| `_ColorA` | Color |  | `(0.070, 0.050, 0.250, 1)` | Colour A |
| `_ColorB` | Color |  | `(0.300, 0.150, 0.700, 1)` | Colour B |
| `_ColorC` | Color |  | `(0.950, 0.300, 0.550, 1)` | Colour C |
| `_ColorD` | Color |  | `(1.000, 0.700, 0.350, 1)` | Colour D |
| `_Brightness` | Range | -0.5 – 0.5 | `0` | Brightness |
| `_Contrast` | Range | 0.5 – 2 | `1` | Contrast |
| `_Saturation` | Range | 0 – 2 | `1` | Saturation |
| `_Vignette` | Range | 0 – 1 | `0.2` | Vignette |
| `_Grain` | Range | 0 – 0.2 | `0` | Film grain |

### `UI/Backdrop/Bokeh`
| Property | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_Color` | Color |  | `(1,1,1,1)` | Tint |
| `_Speed` | Range | 0 – 0.5 | `0.03` | Speed (cycles per second) |
| `_Phase` | Range | 0 – 1 | `0` | Phase (cycles, scrubs a still) |
| `_Aspect` | Float |  | `0` | Aspect override (0 = from the target) |
| `_Seed` | Range | 0 – 64 | `7` | Layout seed |
| `_Count` | Range | 1 – 12 | `12` | Light count |
| `_Size` | Range | 0.02 – 0.5 | `0.17` | Radius (picture heights) |
| `_SizeVar` | Range | 0 – 1 | `0.5` | Radius variation |
| `_Spread` | Range | 0.2 – 1.5 | `1` | Spread |
| `_Drift` | Range | 0 – 0.5 | `0.12` | Drift radius |
| `_Softness` | Range | 0.01 – 1 | `0.25` | Edge softness |
| `_Rim` | Range | 0 – 1 | `0.35` | Lens rim |
| `_Intensity` | Range | 0 – 2 | `0.95` | Intensity |
| `_Pulse` | Range | 0 – 1 | `0.3` | Pulse |
| `_BaseTop` | Color |  | `(0.040, 0.040, 0.120, 1)` | Base top |
| `_BaseBottom` | Color |  | `(0.140, 0.050, 0.160, 1)` | Base bottom |
| `_ColorA` | Color |  | `(1.000, 0.700, 0.350, 1)` | Light A |
| `_ColorB` | Color |  | `(1.000, 0.350, 0.550, 1)` | Light B |
| `_ColorC` | Color |  | `(0.450, 0.550, 1.000, 1)` | Light C |
| `_ColorD` | Color |  | `(0.400, 1.000, 0.850, 1)` | Light D |
| `_Brightness` | Range | -0.5 – 0.5 | `0` | Brightness |
| `_Contrast` | Range | 0.5 – 2 | `1` | Contrast |
| `_Saturation` | Range | 0 – 2 | `1` | Saturation |
| `_Vignette` | Range | 0 – 1 | `0.3` | Vignette |
| `_Grain` | Range | 0 – 0.2 | `0` | Film grain |

### `UI/Backdrop/Grid`
| Property | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_Color` | Color |  | `(1,1,1,1)` | Tint |
| `_Speed` | Range | 0 – 0.5 | `0.05` | Speed (cycles per second) |
| `_Phase` | Range | 0 – 1 | `0` | Phase (cycles, scrubs a still) |
| `_Aspect` | Float |  | `0` | Aspect override (0 = from the target) |
| `_ScrollCells` | Range | 0 – 16 | `4` | Cells scrolled per cycle (whole) |
| `_Horizon` | Range | 0.1 – 0.9 | `0.45` | Horizon height (0 bottom, 1 top) |
| `_CameraHeight` | Range | 0.1 – 4 | `1` | Camera height |
| `_CellSize` | Range | 0.1 – 4 | `1` | Cell size |
| `_LineWidth` | Range | 0.5 – 6 | `1.4` | Line width (screen px) |
| `_LineColor` | Color |  | `(1.000, 0.250, 0.800, 1)` | Line colour |
| `_LineGlow` | Range | 0 – 2 | `0.8` | Line glow |
| `_Floor` | Color |  | `(0.030, 0.010, 0.060, 1)` | Floor |
| `_Haze` | Range | 0 – 1 | `0.6` | Horizon haze |
| `_HazeColor` | Color |  | `(0.900, 0.300, 0.700, 1)` | Haze colour |
| `_SkyTop` | Color |  | `(0.020, 0.010, 0.080, 1)` | Sky top |
| `_SkyBottom` | Color |  | `(0.350, 0.050, 0.350, 1)` | Sky at horizon |
| `_Sun` | Range | 0 – 1 | `1` | Sun |
| `_SunSize` | Range | 0.05 – 0.6 | `0.22` | Sun radius (picture heights) |
| `_SunTop` | Color |  | `(1.000, 0.850, 0.300, 1)` | Sun top |
| `_SunBottom` | Color |  | `(1.000, 0.200, 0.550, 1)` | Sun bottom |
| `_SunStripes` | Range | 0 – 12 | `5` | Sun stripes (per radius) |
| `_Brightness` | Range | -0.5 – 0.5 | `0` | Brightness |
| `_Contrast` | Range | 0.5 – 2 | `1` | Contrast |
| `_Saturation` | Range | 0 – 2 | `1` | Saturation |
| `_Vignette` | Range | 0 – 1 | `0.25` | Vignette |
| `_Grain` | Range | 0 – 0.2 | `0` | Film grain |

### `UI/Backdrop/Contours`
| Property | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_Color` | Color |  | `(1,1,1,1)` | Tint |
| `_Speed` | Range | 0 – 0.5 | `0.02` | Speed (cycles per second) |
| `_Phase` | Range | 0 – 1 | `0` | Phase (cycles, scrubs a still) |
| `_Aspect` | Float |  | `0` | Aspect override (0 = from the target) |
| `_Scale` | Range | 0.2 – 8 | `1.4` | Scale (features per picture height) |
| `_Detail` | Range | 1 – 4 | `3` | Detail (fbm octaves) |
| `_Drift` | Range | 0 – 1.5 | `0.5` | Reshape amount |
| `_Count` | Range | 2 – 40 | `14` | Lines per unit height |
| `_LineWidth` | Range | 0.5 – 4 | `1.1` | Line width (screen px) |
| `_MajorEvery` | Range | 0 – 10 | `5` | Heavier line every |
| `_LineColor` | Color |  | `(0.550, 0.950, 0.850, 1)` | Line colour |
| `_LineStrength` | Range | 0 – 1 | `0.8` | Line strength |
| `_ColorA` | Color |  | `(0.020, 0.060, 0.080, 1)` | Low |
| `_ColorB` | Color |  | `(0.030, 0.140, 0.160, 1)` | Mid low |
| `_ColorC` | Color |  | `(0.060, 0.220, 0.220, 1)` | Mid high |
| `_ColorD` | Color |  | `(0.120, 0.300, 0.260, 1)` | High |
| `_Brightness` | Range | -0.5 – 0.5 | `0` | Brightness |
| `_Contrast` | Range | 0.5 – 2 | `1` | Contrast |
| `_Saturation` | Range | 0 – 2 | `1` | Saturation |
| `_Vignette` | Range | 0 – 1 | `0.25` | Vignette |
| `_Grain` | Range | 0 – 0.2 | `0` | Film grain |

### `UI/Backdrop/Starfield`
| Property | Type | Range | Default | What it does |
|---|---|---|---|---|
| `_Color` | Color |  | `(1,1,1,1)` | Tint |
| `_Speed` | Range | 0 – 0.5 | `0.02` | Speed (cycles per second) |
| `_Phase` | Range | 0 – 1 | `0` | Phase (cycles, scrubs a still) |
| `_Aspect` | Float |  | `0` | Aspect override (0 = from the target) |
| `_DriftCells` | Range | 0 – 8 | `1` | Cells drifted per cycle (whole) |
| `_DriftAngle` | Range | -3.14 – 3.14 | `0.35` | Drift direction (radians) |
| `_Density` | Range | 4 – 60 | `18` | Density (cells per picture height) |
| `_Fill` | Range | 0 – 1 | `0.35` | Share of cells with a star |
| `_StarSize` | Range | 0.01 – 0.3 | `0.07` | Star size (cells) |
| `_Twinkle` | Range | 0 – 1 | `0.5` | Twinkle |
| `_Flare` | Range | 0 – 1 | `0.35` | Bright-star flare |
| `_StarA` | Color |  | `(0.750, 0.850, 1.000, 1)` | Star colour A |
| `_StarB` | Color |  | `(1.000, 0.850, 0.700, 1)` | Star colour B |
| `_Base` | Color |  | `(0.010, 0.010, 0.030, 1)` | Space |
| `_Nebula` | Range | 0 – 1 | `0.45` | Nebula amount |
| `_NebulaScale` | Range | 0.2 – 6 | `1.2` | Nebula scale |
| `_NebulaA` | Color |  | `(0.200, 0.080, 0.400, 1)` | Nebula A |
| `_NebulaB` | Color |  | `(0.050, 0.250, 0.450, 1)` | Nebula B |
| `_Brightness` | Range | -0.5 – 0.5 | `0` | Brightness |
| `_Contrast` | Range | 0.5 – 2 | `1` | Contrast |
| `_Saturation` | Range | 0 – 2 | `1` | Saturation |
| `_Vignette` | Range | 0 – 1 | `0.2` | Vignette |
| `_Grain` | Range | 0 – 0.2 | `0` | Film grain |
