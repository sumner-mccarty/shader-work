# Global FX — review of `*GlobalBlend` / `*GlobalIntensity` and a plan for screen-space "DJ controller" effects

Scope: every `UI/SDF*` shader. Everything below was read from the shader sources in this repo; the C# side
(`UiSceneDirector`, `UIShadowBufferManager`, canvas setup) lives in the Unity repo and is **not** visible here,
so anything that depends on it is marked *(verify in Unity)*. Pictures were rendered with slrender
(`Docs/GlobalFx/demo_sweep.py`), not Unity.

---

## 1. TL;DR

* The hook is real and cheap: **32 blend slots + 32 intensity slots** across 5 widget families (60 declarations across the 9 shaders, since the RM
  twins repeat them). Each slot is `lerp(slotBaseColor, globalGradientColor, blend * intensity)`, branch-skipped when
  `blend == 0`. **No shipped skin/theme sets any of them** — all 0, so today nothing renders differently.
* It already works as "a colour field in screen space that every participating slot can borrow". The rendered
  proof is in §6: rim glows + value indicators picking up a left→right colour flow across a whole rack, with
  lit materials (carbon weave, bevels, speculars) preserved.
* But it is **not yet usable as the director-driven effect you describe**. Four things need fixing first (§3):
  1. the "screen position" it uses is probably not screen position in the real app;
  2. blend is a per-material property, so animating 0→1 across 30 controls means writing 30 materials;
  3. the gradient can only make smooth 4-stop ramps — no travelling band, ripple, pulse or beat envelope;
  4. `Intensity` multiplies the *blend*, so >1 over-shoots the lerp instead of meaning "brighter/glowier".
* Recommended design (§4): keep the per-slot `*GlobalBlend` as an **authored participation weight** (theme
  data, per state), and add **one global `_GlobalFxAmount` + a small global FX uniform block** that a director
  animates. Slots become `lerp(base, fx.rgb * intensity, saturate(slotBlend * fx.mask))`. One `Shader.SetGlobal*`
  burst per frame drives the whole screen; no per-widget writes. It also *shrinks* the shaders (10 inlined
  gradient evaluations in the knob → 1).
* Catalogue of effects, what's worth doing and why (§7–§8), and a phased plan (§10).

---

## 2. Inventory — what exists today

Every slot is a pair `_<Slot>GlobalBlend` (Range 0–1, default 0) and `_<Slot>GlobalIntensity` (Range 0–2,
default 1). "RM" shaders have the same slots as their base twin.

| Family (shaders) | Slots (blend/intensity pairs) | Count |
|---|---|---|
| **Knob** (`SDFKnob`, `SDFKnobRM`) | `Fill` (centre disc), `Line` (arc track), `LineSublineFilled` (progress arc), `LineSublineUnfilled`, `Knob` (rotating body), `KnobEdge` (indent ring), `Nub` (pointer), `NubEdge`, `Edge` (indent behind everything), `Border` | 10 |
| **Button** (`SDFButton`, `SDFButtonRM`) | `Button` (body/face), `Icon`, `Edge`, `Border` | 4 |
| **Slider** (`SDFSlider`, `SDFSliderRM`) | `Bg`, `Track`, `TrackValueFilled`, `TrackValueUnfilled`, `TrackValueNegative`, `Handle`, `HandleFace`, `Edge`, `Border` | 9 |
| **Panel** (`SDFPanel`) | `Panel`, `InnerFrame`, `Edge`, `Border` | 4 |
| **Toggle pill** (`SDFTogglePill`, `SDFTogglePillRM`) | `Bg`, `Track`, `Handle` (also aliased as `_Toggle*`), `Edge`, `Border` | 5 |
| `SDFIcon`, `SDFScope`, `SDFRhythmTrack`, Backdrop*/Decor*/Decal* | **none** | 0 |

**Slots that look like they should exist but don't:** toggle **LED**, knob **OuterRing1–3** and **OuterMarks**
(scale ticks), slider **ScaleMarks**, `SDFScope` trace, `SDFRhythmTrack` (the highway — probably *should*
stay out, see §7.4), `SDFIcon`. The LED and outer rings/ticks are the most "controller-like" light sources in
the kit; adding slots there is the highest-value shader work (§10, phase 3).

### How a slot is evaluated today

```
// UIRenderer.cginc / every SDF*.shader (inlined per slot, not shared)
float4 CalculateGlobalGradient(float2 screenPos, float time) {
    float2 uv = screenPos / _ScreenParams.xy;
    t = GetGradientPosition(_GlobalGradientType, uv, _GlobalGradientDirection,
                            _GlobalGradientTime, /*speed*/1.0, _GlobalGradientScale, _GlobalGradientOffset);
    return InterpolateGradientColors(_GlobalGradientColorA..D, t, 4);   // ping-pong over 4 stops
}
base = lerp(base, gc.rgb, blend * intensity);   // then pattern → lighting → (edge/border) emissive
```

Driven by the plain uniforms in `UIGlobalUniforms.cginc` (`_GlobalGradientType/ColorA-D/Direction/Scale/Offset/Time`).
Gradient types: 0 linear, 1 radial, 2 angular, 3 diamond, 4 triangle. `t = dot(uv,dir)*scale + Time*0.1 + Offset`
(so `Time` moves the field 0.1 screen-widths per second; the ping-pong makes it bounce A→D→A).

**Where it lands in the pipeline matters for looks:**
* Body slots (`Knob`, `Button`, `Panel`, `Bg`, `Handle`, `Fill`…) replace the *base colour before pattern and
  lighting* → the sweep is "paint under the lights": weave, brushed metal, bevels and speculars all survive.
* `Edge`/`Border`/`KnobEdge`/`NubEdge` colours also feed the `*RenderEmissive` accumulators → they act as real
  **glow**, which is why rim-only sweeps look the most "lit".

Related code that is **dead today**: `UIGlobalEffects.cginc::ApplyGlobalEffects` (pulse, wave, vignette, grain,
scanlines, colour grade) is included by `UIRenderer.cginc` but called by nothing; `_GlobalPulse*`,
`_GlobalWaveParams`, `_GlobalEffectMask`, `_GlobalGlitch*`, `_GlobalPixelSize` are declared and unused by the widgets.
This is the half-built version of what you want — see §4.3.

---

## 3. Problems to fix before building on it

### 3.1 The "screen position" is not screen position *(verify in Unity)*
Every call is `CalculateGlobalGradient(IN.worldPosition.xy, …)` and the vertex shader does
`OUT.worldPosition = v.vertex` — i.e. the **batched canvas-local vertex**, not a pixel. It is then divided by
`_ScreenParams.xy`. That is only a 0..1 screen UV if the canvas is Screen-Space-Overlay, scale factor 1, and the
mesh origin is the screen's bottom-left. In a normal UI the canvas origin is its pivot (centre) and a
`CanvasScaler` changes the units, so you would get: the sweep centred on the middle of the screen (negative UVs
left/below), compressed or stretched by the scaler, and a *different* effect on each aspect ratio. Camera-space
canvases would use world units and break it completely. In **slrender / SkinSheet it is 0..1 per cell**, so
every control sees only the first ~0.001 of the gradient — a sheet can never show a spatial sweep as-is.

*Recommendation:* give the shader an explicit mapping from `worldPosition.xy` to screen UV, set once per frame by
the director: `float4 _GlobalFxMap` (`uv = worldPosition.xy * map.xy + map.zw`). Overlay, scaled and camera
canvases then all work, and slrender can set the same global to emulate any screen (that is how the pictures in
§6 were made).

### 3.2 One slot in `SDFButtonRM` uses the wrong coordinate
`SDFButtonRM.shader:1174` (the raymarched body) calls `CalculateGlobalGradient(uv, time)` with the widget's own
0..1 UV, while its Edge/Border and every other shader use `IN.worldPosition.xy`. A button body would therefore
show a near-flat colour instead of its position in the sweep. Fixed for free by §4.2 (all slots read one shared
`screenUV`).

### 3.3 Blend is per-material; an effect needs a global switch
To fade 30 controls 0→1 you must touch 30 `Material` instances (or `MaterialPropertyBlock`s) every frame, *and*
those values collide with the state system (Hover/Pressed parameters are written into the same properties).
A global multiplier removes both problems (§4.1).

### 3.4 `Intensity` over-shoots
`lerp(base, g, blend*intensity)` with `intensity` up to 2 extrapolates: `blend=1, intensity=2` → `2g − base`, which can
go negative/clipped and shift hue. In `ApplyGlobalEffects` (unused) intensity is a brightness multiplier on the
gradient — a better meaning. Since every existing value is `blend=0, intensity=1`, redefining it changes no pixel
today (parity-safe).

### 3.5 The ramp can't make "one colour moving across"
Four smooth stops, ping-pong, speed 0.1/s: great for rainbow/flow, but a travelling *band* (the classic
chase/wipe), a ripple ring, or a beat-synced pulse needs an envelope (mask) as well as a colour. Today it can be
faked with stops `dim,dim,hot,dim` but the band width/speed are tied to `scale`/`Time` and can't be driven by a
curve. Crossing the screen in 1.5 s needs `Time` at ~6.7× — workable but awkward.

### 3.6 Smaller notes
* `SDFTogglePill`: the *Track* component's gradient call hard-codes `globalBlend=0` and applies the global
  separately to the base colour (Params-Toggle.md:249) — fine, just be aware pattern/bevel on the track is not tinted.
* `SDFSliderRM` evaluates the global in 9+ separate inlined blocks (`TrackValueFilled` alone is inlined at several sites). Knob RM: 10.
  Each is branch-gated, so off = free, but with many slots on it is 10 gradient evaluations per pixel and
  more unrolled code for FXC (CLAUDE.md: the RM shaders are already ~9–10 min of Unity's compile budget).
* The legibility rules (`lookcheck` print pairs ≥3:1, 30 px indicators) only audit *static* colours. An effect
  that recolours `Icon`/`Fill`/`TrackValueFilled` can drop below 3:1 against its background mid-sweep (§7.5).

---

## 4. Recommended design

### 4.1 Two layers: authored weight × runtime amount

| Layer | Who sets it | When | Meaning |
|---|---|---|---|
| `_XxxGlobalBlend` (existing, per slot) | **theme / skin** (`*.states.json`, per state) | author time | *"How much does this part take part in a screen-wide effect?"* — a weight, 0 = never |
| `_XxxGlobalIntensity` (existing, per slot) | theme / skin | author time | *"How hard does it light up?"* — gain on the FX colour (glow strength); 0–2 |
| `_GlobalFxAmount` (**new**, global float) | **director** | runtime | master fade 0→1→0 (attack/hold/release) |
| `_GlobalFx*` block (**new**, globals) | director | runtime | the effect itself (colours, phase, width, mode, origin) |

Shader side (one tiny function, shared by every slot):

```hlsl
// computed ONCE per fragment, only when _GlobalFxAmount > 0.001
float4 fx = GlobalFx(screenUV);                 // rgb = colour, a = spatial mask 0..1
// per slot (replaces the inlined CalculateGlobalGradient):
float w = saturate(slotBlend * _GlobalFxAmount * fx.a);
base = lerp(base, fx.rgb * slotIntensity, w);   // intensity = glow gain, not blend gain
```

* `_GlobalFxAmount == 0` (the default) ⇒ every slot is skipped ⇒ **frozen Unity goldens stay identical**.
* Old behaviour stays reachable: keep the legacy `_GlobalGradient*` as FX *mode 0* (full-mask rainbow), so any
  skin that sets blend today (none do) behaves as before.
* Hover/Pressed are just states that carry different weights — no extra machinery (§5).

### 4.2 Shared screen UV
`float2 screenUV = IN.worldPosition.xy * _GlobalFxMap.xy + _GlobalFxMap.zw;` computed once per fragment, passed to
`GlobalFx`. Fixes §3.1/§3.2 and costs nothing.

### 4.3 The FX uniform block (proposal)

| Uniform | Type | Meaning |
|---|---|---|
| `_GlobalFxAmount` | float | master 0..1 (director envelope) |
| `_GlobalFxMode` | int | 0 gradient field (legacy), 1 band, 2 ring/ripple, 3 wash, 4 beat-pulse, 5 target-converge |
| `_GlobalFxColorA..D` | float4×4 | palette (usually the theme's accent set) |
| `_GlobalFxPhase` | float | 0..1 position of the front, driven by a curve (or beat phase) — *not* wall-clock |
| `_GlobalFxWidth`, `_GlobalFxSoft` | float | band half-width / edge softness |
| `_GlobalFxDir` | float2 | sweep direction (modes 0/1) |
| `_GlobalFxOrigin` | float2 | centre for ring/ripple/converge, in screen UV |
| `_GlobalFxMap` | float4 | `worldPosition.xy → screen UV` (§3.1) |
| `_GlobalFxGroups` + per-widget `_GlobalFxGroup` *(optional)* | float bitmask | lets an effect include only some widget kinds (§4.4) |

Mask/colour per mode (all a few ALU):
`band: a = 1 − smoothstep(w, w+soft, |dot(uv,dir) − phase|)`, colour = ramp(position in band);
`ripple: a` same with `length(uv−origin)`; `wash: a = 1`, colour = single stop; `beat: a = pow(1−beatPhase, k)`;
`converge: ring radius = (1−phase)*R shrinking onto the target`.

### 4.4 "Do an effect in screenspace and include these UI elements"
Three levels, pick the cheapest that suffices:
1. **By authoring (default, zero code):** a control participates iff its slots have `GlobalBlend > 0` in the
   current theme/state. Choose the set when you author the theme.
2. **By group (optional):** one `_GlobalFxGroup` float on each material (bitmask: knobs=1, buttons=2, sliders=4,
   pads=8, panels=16, toggles=32…) and a global `_GlobalFxGroups` from the director. Shader gate:
   `(group & mask) != 0`. Lets the same theme run a "knobs only" sweep.
3. **By instance (exceptional):** the director writes `_GlobalFxGroup` on specific materials (e.g. "the one control
   the tutorial is pointing at"). Per-widget writes only on the rare targeted effect.

### 4.5 Compile-budget impact
Hoisting the effect to one `GlobalFx()` per fragment *removes* ~10 inlined gradient evaluations from
`SDFKnob(RM)` and ~9–15 from `SDFSlider(RM)`. Expect FXC time to stay flat or drop. It still needs the Unity
compile check CLAUDE.md requires, and a `tests/parity.py check` run (should be byte-identical: amount defaults to 0).

---

## 5. Theme authoring: which slots should take part

Principle: **light the lights, tint the paint, never touch the readouts.**

| Role | Slots | Weight (Normal) | Intensity | Why |
|---|---|---|---|---|
| **Rim lights** | `Edge`, `Border`, `KnobEdge`, `NubEdge`, (new) LED | 0.8–1.0 | 1.0–1.6 | feed the emissive accumulator → real glow; the DJ-controller look |
| **Indicators** | `Fill`, `Line`, `LineSublineFilled`, `TrackValueFilled`, `Icon`, `Nub` | 0.6–1.0 but **gate on luminance contrast** (§7.5) | 1.0 | these *are* the colour accent most themes already have; moving it feels alive |
| **Paint** | `Knob`, `Button`, `Handle`, `HandleFace`, `Panel`, `InnerFrame`, `Bg` | 0–0.35 | 1.0 | subtle wash; bodies keep material identity. ≥0.5 floods the panel (see §6, row 4) |
| **Readout backdrops** | `Track`, `TrackValueUnfilled`, `TrackValueNegative`, `LineSublineUnfilled` | 0 | — | must stay dark/neutral so a value is readable at 30 px |

**States** (existing `Normal` / `Hover` / `Pressed` / `Disabled` from the skin state system):
* `Normal`: weights above.
* `Hover`: rim lights ↑ (e.g. 0.8 → 1.0) and intensity ↑ — a hovered control "wakes up" a bit more than its
  neighbours, even mid-effect.
* `Pressed`: **blend → 0 on the pressed colour slots** (or a fixed theme flash). Direct feedback must beat ambient
  eye-candy; the player should never lose "I pressed this".
* `Disabled`: 0 — a disabled control that keeps glowing reads as enabled.

**Per-theme palette**: the director should read four colours from the theme (the look's own accent family — Tron
cyan/magenta/…, Carbon red/yellow/white/silver…), not use a rainbow by default. Suggest a `globalFx` block in the
theme JSON (`Themes/*.theme.json`, currently only `scene`):
`{"globalFx": {"palette": ["#..","#..","#..","#.."], "idle": "flow", "intensityScale": 1.0, "reduceMotionSafe": true}}`.

---

## 6. What it looks like (slrender, not Unity)

Setup: whole rack ≈ 1100×240; each cell rendered with `_ScreenParams = screen/cell` and `_GlobalGradientOffset += x0/W`
so the per-cell local coordinate becomes a true screen coordinate (this is the §3.1 emulation).
4 stops `#FF2D6A #FFB000 #22E0A0 #2E7BFF`, linear L→R. Rows: **off · rim+indicators @ 1.0 (phase 0) · same, phase +0.5
· every slot @ 1.0 · every slot @ 0.5**.

![Tron neon rack](GlobalFx/tron-sweep.png)

![Carbon Race lit rack — off · rim+indicators · all slots @ 0.5](GlobalFx/carbon-sweep.png)

What this tells us:
* **Row 2–3 (rim + indicators):** exactly the "DJ gear" read — the rings/rims/value arcs/borders pick up the sweep,
  bodies stay put. Best look and best legibility. This should be the default participation set.
* **Rows 4–5 (all slots):** the whole panel becomes a gradient poster. On the lit Carbon rack at 0.5 it is still
  gorgeous — weave pattern and speculars survive — but it hides the control hierarchy, so use it as a brief
  full-screen *event* (transition, drop, combo), not an idle state.
* The knob `Fill` ring and slider `TrackValueFilled` turn into live colour bars, which is where the sweep is most
  noticeable at small sizes.
* Not shown / unverified: motion (stills only), Unity FXC behaviour, and the real-canvas coordinate mapping
  (§3.1). An unexplained vertical discontinuity in the Tron face panel at x≈420 appears with the panel's own blend
  on; I did not chase it.

---

## 7. Effects worth building — and why

Ranked by (benefit ÷ cost). "Purpose" is the answer to *why would I ship this*.

| # | Effect | Look | Purpose / benefit | Trigger |
|---|---|---|---|---|
| 1 | **Beat pulse** — rim lights ease up/down with `beatPhase`, palette steps per bar | rack "breathes" with the track | peripheral **tempo reference**; makes the UI feel *wired to the audio* (the single most convincing DJ-hardware cue) | every beat, while a track plays; amplitude low (weights ≤0.5) |
| 2 | **Sweep L→R** — one bright band, 1–1.5 s, rim+indicator slots | classic controller boot/attract chase | **boot/ready cue**, screen/preset transitions (masks the swap), "loaded" confirmation | scene enter, preset load, theme switch |
| 3 | **Converge** — ring or band shrinks *onto a target control* | eye is pulled to one control | real **attention/onboarding** tool: first-run hints, "tap here", missed-step reminders; replaces ad-hoc arrows | tutorial step, idle-hint after N s |
| 4 | **Rainbow flow** (the §6 demo) — slow 4–6 s palette scroll | idle light show | **attract/idle mode**; moving colour also reduces static burn-in on OLED handhelds | no input for ~20–30 s; any touch fades out in 0.3 s |
| 5 | **Ripple from source** — ring emanates from a pressed pad/button | physical "touch splash" | feedback that is **spatially tied to what you did** (works as hit feedback in a rhythm game without touching the highway) | pad hit, perfect/good grade |
| 6 | **State wash** — whole rack tints to one colour (low weight) | mode colour | **mode/status signalling at a glance**: record-armed = red, sync-locked = green, deck A cyan / deck B magenta, low-battery amber | state change, persistent while true |
| 7 | **Milestone flash** — rainbow sweep, once | celebration | combo/streak/level-up reward without a popup; miss streak = brief red wash | combo thresholds, song end |
| 8 | **Level/meter chase** — front position = audio RMS or progress | rack acts as a VU / song-progress bar | ambient **progress/energy** display with zero extra widgets | continuous (optional) |

**Is random/untriggered worth it?** Only #4 is fine as purely idle "eye-candy" — rare, long, and it self-cancels on
input. Everything else earns its place by carrying information (beat, state, attention, reward). Random flashes during
play would compete with the highway and train players to ignore the glow, which would waste #3/#6.

### 7.4 Keep these out
* `SDFRhythmTrack` (the highway/notes): colours there encode gameplay (lanes, timing). Do not add global blend.
* Anything where colour = data: pitch/lane colours, value-negative indicators, error/disabled colours.

### 7.5 Guardrails (cheap, do them with the first implementation)
* **Photosensitivity:** cap flash/pulse rate (≤ 3 Hz, no full-screen red/white strobing); expose a "reduce motion"
  setting that disables #1/#4/#5 and shortens #2 to a single fade.
* **Legibility:** don't blend `Icon`/glyph slots at weight >0.5 unless the FX palette is luminance-matched to the
  background; extend `lookkit`'s printcheck with a "worst case against the FX palette" pass once palettes exist.
* **Interaction wins:** `Pressed` zeroes the weight on the pressed colour slots (§5).
* **Cap participation per frame:** effect amplitude ≤0.6 during gameplay, up to 1.0 only in menus/transitions.

---

## 8. Director sketch (Unity side — to be written in the audiogame repo)

```csharp
UiGlobalFx.Play(FxPreset preset, float duration, FxGroups groups = All, Vector2? origin = null);
// FxPreset = { mode, palette (from theme), width/soft, ease curves, attack/hold/release, loop }
```

* One component, one `Update()`: evaluates curves → `Shader.SetGlobalFloat("_GlobalFxAmount", …)`, `_GlobalFxPhase`,
  `_GlobalFxOrigin`, colours (only when changed), and `_GlobalFxMap` on resolution/scaler change. **No per-widget writes**
  in the common case.
* Envelope: `attack 0.25–0.5 s → hold → release 0.6–1 s`; `Cancel()` = release in 0.2–0.3 s (used by any user input
  while the effect is "idle").
* Presets are data (ScriptableObject/JSON next to themes), so a look can ship its own sweep timing and palette.
* Beat input: `_GlobalFxPhase` = `beatPhase` for mode 4, supplied by the audio clock, not `Time.time`.
* Priority: `Milestone > State wash > Beat pulse > Idle flow`; higher priority ducks lower ones.

---

## 9. Verifying it in this repo (no Unity)

* slrender already layers `globals` over a material and takes `cell["globals"]`; the §6 harness is
  `python Docs/GlobalFx/demo_sweep.py <SkinPrefix>` (writes to `Docs/GlobalFx/.out/`). With `_GlobalFxMap` in place it
  becomes trivial to add `Tools/looks/<look>.py fxsheet` that renders N phases per rack for review.
* Parity: all new uniforms default to "off" ⇒ `python tests/parity.py check` must pass unchanged. Anything that
  moves a pixel (e.g. fixing `SDFButtonRM` body to world-space) will only differ when blend>0, i.e. never in goldens.
* PR note required by CLAUDE.md: which shaders grew/shrank, and that a **Unity FXC compile check is needed**.

---

## 10. Phased plan

1. **Foundation (shader, small, parity-safe):** `GlobalFx()` + `_GlobalFxAmount/Map/Mode/Phase/Width/Origin/Colors`
   in `UIGlobalUniforms.cginc`/`UIRenderer.cginc`; replace the dozens of inlined `CalculateGlobalGradient` calls with a
   single per-fragment `fx`; fix §3.2; change Intensity to a gain on `fx.rgb`. Gate everything behind
   `_GlobalFxAmount > 0.001`.
2. **Proof in slrender:** `fxsheet` helper; render the 8 effects × (Tron, CarbonRace, one lit look, one flat look).
3. **More lights:** add blend/intensity slots to toggle **LED**, knob **OuterRing1–3** / **OuterMarks**, slider **ScaleMarks**
   (opt-in, defaults 0).
4. **Theme data:** `globalFx` palette/idle preset in each look's `Themes/*.theme.json`; set slot weights per the §5 table
   in each look's `Tools/looks/<look>.py` spec (the kit builds the states — do not hand-edit).
5. **Unity director + presets + reduce-motion setting** (audiogame repo).
6. **Then** decide which triggers to wire (suggested order: scene-enter sweep → beat pulse → idle flow → target converge →
   milestone).

### Open questions for you
* Canvas setup in the app (Overlay vs Camera, `CanvasScaler` mode) — decides how `_GlobalFxMap` is computed.
* Should effects ever run **during** a song, or only in menus/transitions? (This sets the amplitude caps in §7.5.)
* Do you want per-theme palettes only, or also a user-chosen "deck colour"?
