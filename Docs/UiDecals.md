# Stickers & paint — user decoration across the UI  *(PLAN 2026-10-08)*

> The player decorates their gear: a sticker slapped on the drum-pad plate, a paint splash thrown across the mixer,
> a spray-paint strike running over six faders and the plate between them. It must read as **physically on the
> hardware** — lit by the same lamps, clipped to the parts it lands on, surviving panel moves and look changes —
> and it must cost nothing per frame once placed.
>
> This is a different feature from background fields (`Docs/Skinning/Params-Backdrop.md`): fields are procedural,
> looping, BEHIND content and the same for every player of a look; decorations are user-authored, placed, ON surfaces
> and mostly static.

---

## 1. The decision: two layers, one data model

| | **Paint layer** (surface) | **Sticker layer** (overlay) |
|---|---|---|
| What | splats, spray strokes, brush strokes, drips, tape stripes, stencils | die-cut stickers, badges, decals with art |
| Drawn by | the widget shaders themselves (`UIDecals.cginc`), from a per-group **decal texture** | ordinary UGUI quads on top of the group, `UI/Sticker` shader |
| Conforms to parts | **yes** — clipped to each part's SDF shape, shaded by its bevel/dome, plate paint shows in the gaps | no — flat on top (that is what a real sticker does) |
| Over printed labels | no — print stays on top (legibility); optional later | **yes** — a sticker covers what's under it |
| Lit by the rig | yes, it is part of the surface | yes — the sticker shader reads the global light rig for its sheen |
| Per-frame cost | one texture read in each widget on a decorated panel; texture re-rendered only on edit | a few quads |
| Widget-shader compile cost | small (one `tex2Dlod`, no loops) — **must be measured** (§6) | none |

Why not one layer:
* **Overlay-only paint looks pasted on.** It can't be clipped to a knob's round cap or a pad's rounded body, it floats in
  the air over the gaps between controls, ignores bevels and hides hover/press/value arcs underneath it.
* **Surface-only stickers are wrong too.** A sticker is an object on top of the gear — it covers print, it has its own
  edge, shadow and sheen, and the user needs to grab it to move it. An overlay quad is exactly that.

---

## 2. Where a decoration lives: the GROUP

Layouts move: panels dock, resize, scroll, switch workspaces and breakpoints, and the screen size changes. A paint
strike across the mixer has to stay on the mixer.

* A **group** is a decorated surface region: by default a **panel** (its PanelFactory tab id, e.g. `Mixer`,
  `DrumPad`), optionally any layout container that names itself a group (`"decor": true` — a new layout key).
* Decoration coordinates are **normalized to the group's rect** (`pos` 0..1), and sizes are in **group-height units**
  so a round splat stays round when the panel is resized wider.
* Anchors:
  * `group` (default) — free placement on the panel; a strike crossing many controls is one decoration.
  * `element` — follows one control (`"anchor": {"class": "pad.12"}`), for a sticker on a specific pad. Uses the
    LayoutViewRoot ids / `class` bindings that Learn mode already relies on.
  * `workspace` (later) — spans panels; breaks when panels are re-docked, so offered with that warning or not at all.
* Persistence: per group, **global across looks** (it's the user's gear, not the look's). Look-specific sets are a
  later option.

---

## 3. Paint layer — how it renders

### 3.1 The decal texture (per decorated group)
* `DecalSurface` (component on the group root) owns an RGBA render texture sized to the group (canvas units × 1,
  × 0.5 on mobile): **premultiplied paint colour + coverage**.
* It is **re-rendered only when the decoration changes** (or while a reveal animation plays, ~0.3 s). Idle cost: zero.
* Each decoration is drawn into it by a small generator shader (procedural — no texture assets needed):
  * **`UI/Decal/Splat`** — seeded SDF: a main blob, satellites flung along a throw direction with decreasing size,
    thin streaks, droplets, an fbm-roughened edge; `drips` adds gravity runs (capsules with bulb ends, down = the
    group's down). `_Reveal` 0→1 animates the throw.
  * **`UI/Decal/Spray`** — soft stamps with speckle along a Catmull-Rom spline, overspray dots outside the core.
  * **`UI/Decal/Brush`** — a ribbon mesh along the spline with bristle streaks along the stroke and dry-brush
    break-up at the tail; pressure → width.
  * **Tape / stencil** — rectangles with torn ends; stencil letters via TMP rendered into the texture.
  * Blend per decoration: `normal`, `multiply` (stain/ink), `add` (glow paint), `erase`.
* Later (P2) a second texture carries the paint's **material**: R gloss, G metal (chrome/gold leaf paint),
  B emissive (glow-in-the-dark), A **height** (paint thickness). Height is the big realism win: the shader perturbs the
  normal by its gradient, so thick paint ridges and drips catch the rig's lamps.

### 3.2 How a widget finds its place in the group
Every widget shader already carries `IN.worldPosition` (canvas space — the same space `_ClipRect` uses). So one
per-material vector is enough:

```hlsl
// CG/Core/UIDecals.cginc (new) — opt-in per shader with #define UI_DECALS, like UI_PATTERN_TEXTURE
sampler2D _UIDecalTex;
float4    _UIDecalGroup;      // the group's rect in canvas space: xy origin, zw size
float     _UIDecalEnabled;    // 0 on every undecorated widget: the branch costs nothing

float4 UISampleDecal(float2 canvasPos)
{
    float2 uv = (canvasPos - _UIDecalGroup.xy) / _UIDecalGroup.zw;
    float inside = step(0.0, uv.x) * step(uv.x, 1.0) * step(0.0, uv.y) * step(uv.y, 1.0);
    return tex2Dlod(_UIDecalTex, float4(uv, 0, 0)) * inside;    // premultiplied
}
```

`DecalSurface` sets `_UIDecalTex`, `_UIDecalGroup`, `_UIDecalEnabled` on every `MaterialStateController` material
in its subtree through `SetMaterialVector/Float` (the live-driven contract: no skin ever authors these, so the state
engine never fights them), and again whenever the group's rect changes (resize, scroll). Undecorated panels never
touch their materials.

### 3.3 Where the paint enters the surface
**Phase 1 — at the existing Materials v2 hook** (`UI_MATERIAL_V2(col, base, n, P, NY)` in SDFKnobRM, SDFButtonRM,
SDFSliderRM, SDFPanel — proven placement, one line per shader). There the shader has the lit colour and the base
albedo, so the paint replaces the albedo while keeping the part's shading:

```hlsl
float4 d = UISampleDecal(IN.worldPosition.xy);
float shade = Luminance(lit) / max(Luminance(base), 1e-3);          // bevel/dome/lamp response of this pixel
lit = lit * (1.0 - d.a) + d.rgb * shade;                            // paint takes the light the surface takes
```

**Phase 2 — true albedo injection** (paint before lighting, own gloss/metal from the material texture) if Phase 1
looks flat on domed caps. Only after Phase 1 is judged in Play Mode.

Details that make it read as physical:
* Paint is clipped by each part's own SDF coverage for free (it is part of that part's colour).
* The **plate (SDFPanel) gets the same paint**, so a splat crossing a gap continues on the plate between controls —
  one continuous splash, not islands.
* Hover/pressed glows, value arcs and LEDs are composited after the body, so they still show over paint.
* Raymarched knobs: the canvas position of the pixel projects the paint straight onto the 3D cap (spray from the
  viewer). P2: inside the cap, rotate the decal UV by the knob's value angle so paint on the cap turns with it.

---

## 4. Sticker layer — how it renders

* A sticker is a UGUI quad under the group's root, after its content (top of the group's draw order), with shader
  **`UI/Sticker`**:
  * art: an SDF/MSDF sprite (die-cut edge = the SDF → crisp outline at any size + a white vinyl border),
  * finish: `matte` paper, `gloss` vinyl (sheen moves with the global light rig `UiLightRig` publishes),
    `holo` foil (view/light-angle rainbow), `chrome`, `glitter`;
  * a soft contact shadow, optional peeled corner and slight bubble (normal noise).
* Anchored to the group or to an element; transform = pos / scale / rotation in group units.
* Art sources: shipped packs (`Resources/Stickers/<Pack>/…`, procedural SDF art is ideal — the cloud factory can make
  packs cheaply), and later user images (import → SDF-ify on device).

---

## 5. Data model

`<persistentDataPath>/decor/<groupId>.decor.json` — engine-free JSON (§3.6 portability), small enough to sync to a
profile:

```jsonc
{ "version": 1, "group": "DrumPad",
  "items": [
    { "id": "a1", "kind": "splat",  "layer": "paint", "seed": 1234, "pos": [0.62, 0.40], "size": 0.35, "rot": 18,
      "color": "#FF2D6F", "finish": "gloss", "drips": 0.4, "blend": "normal" },
    { "id": "a2", "kind": "spray",  "layer": "paint", "points": [[0.10,0.80,1.0],[0.50,0.62,0.8],[0.92,0.30,0.5]],
      "width": 0.04, "color": "#FFD400", "finish": "matte" },
    { "id": "s1", "kind": "sticker", "layer": "sticker", "art": "Stickers/Street/Skull", "pos": [0.85, 0.12],
      "scale": 0.18, "rot": -8, "finish": "holo", "anchor": { "class": "pad.12" } } ] }
```
* Order in `items` = paint order (later items paint over earlier).
* Undo/redo: `JsonUndoStack` (MaterialStateStack/Core) over this document — the Designer's own undo.
* Export/import as a **deco pack** (zip of the JSON + any user art) through the existing UserContent path.

---

## 6. Compile-time budget — the hard constraint

SDFKnob already takes ~11 min in FXC under load and the RM shaders ~9–10 min, close to Unity's timeout. So:
* `UIDecals.cginc` is **opt-in per shader** (`#define UI_DECALS 1`), exactly like `UI_PATTERN_TEXTURE`.
* Gate before shipping any widget-shader change: time FXC for SDFKnob / SDFKnobRM / SDFButtonRM / SDFSliderRM /
  SDFPanel **before and after** (the 2026-10-07 harness measured SDFKnob at 678 s both ways for the texture-pattern
  change). Accept only if each grows < 5 %; otherwise drop that shader from Phase 1.
* Fallback for any shader left out: its parts get paint from an **overlay quad masked by the group's decal texture**
  — less physical, zero shader change.
* Raise `UNITY_SHADER_COMPILER_TASK_TIMEOUT_MINUTES` to 30 before this work regardless.

---

## 7. Authoring — a DECO tab in the Skin Studio

* Skin Mode already is "customize everything"; decoration is a new tab beside LOOK / SKY / PARTS / TWEAK / SAVE.
* Picking/drawing uses the **WorkshopOverlay** pattern (top-most canvas that raycasts the UI itself): the pointer
  picks the group under it and converts to group coordinates; while a paint tool is armed, presses go to the tool
  instead of the control.
* Tools: **Throw** (click = splat at the pointer, drag = throw direction & force), **Spray**, **Brush**, **Drip**,
  **Tape**, **Stencil**, **Sticker** (pick from packs, then place / move / rotate / scale with handles), **Eraser**,
  colour + finish pickers (palette roles `@accent` etc. so paint can follow the look, or fixed colours), Undo/Redo,
  Clear group.
* Live: the decal texture re-renders under the pointer as you draw (only the dirty rect).

---

## 8. Offline + cloud support (slrender)

* slrender's SkinRenderer gains a `decal` cell key (texture + group rect) so a rack composite can be rendered
  decorated — the same offline loop every look already uses.
* Splat / spray / brush generators are plain shaders → slrender renders them headless, so the cloud factory can design
  paint presets and sticker packs (SDF art) cheaply (Sonnet), judged on rack composites like looks are.

---

## 9. Phases

| Phase | Scope | Proof |
|---|---|---|
| **P0 spike** (½–1 day) | `UIDecals.cginc` in SDFPanel + SDFButtonRM only; `DecalSurface` on DrumPad with one hard-coded seeded splat rendered by `UI/Decal/Splat`; FXC timing before/after | Play-Mode screenshot of a splat crossing pads + plate; FXC table |
| **P1 core** | data model + persistence; group & element anchors; Splat / Spray / Brush generators; sticker overlay with matte / gloss / holo; DECO tab with place/move/rotate/scale/erase + undo; all four RM shaders + SDFPanel if the FXC gate passes | decorated Mixer + DrumPad survive dock/resize/look change/restart |
| **P2 realism** | paint material texture (gloss, metal, emissive, **height** → lit paint ridges), drips with gravity, throw reveal animation, knob caps rotate their paint, tape & stencil | before/after sheets under the rig |
| **P3 social** | deco packs export/import, sticker store packs (entitlements), decorations visible to others (profile / party), field-filled paint (animated paint sampling a background field) | |

## 10. Decisions to confirm
1. **Paint under printed labels** (legible, recommended) or over them (realistic)? Proposal: under, with a per-item
   "cover print" option later.
2. **Scope of a decoration**: per panel type, following the panel wherever it docks (recommended), or per workspace?
3. **Monetization**: free basic paint + a starter sticker pack; sticker packs / special finishes as store items or Pro?
4. **Visible to others** in party / profile (it's only a small JSON), or private?

---

## 11. Generators — built *(offline, slrender-verified; no Unity compile check yet)*

The §3.1 generator shaders. Each draws ONE decoration into a transparent quad: **premultiplied** rgba (`rgb * a`,
`a` = coverage), `Blend One OneMinusSrcAlpha`, uv 0..1 = the decoration's bounds (use a square quad: the picture is
centred and isotropic). Seeded and deterministic (`bdHash*` from `CG/Core/UIBackdropFlow.cginc`), no textures, no
widget shader touched. Contact sheets (4 seeds/variants, dark + light plate, 256 px and 64 px): `Looks/_decals/<name>.png`,
regenerated by `python Looks/_decals/make_sheets.py <splat|spray|brush>`.

### 11.1 `UI/Decal/Splat` — `DecalSplat.shader`  ·  `Looks/_decals/splat.png`
Thrown paint: lobed + tongued main blob squashed along the throw, 10 satellites flung along `_ThrowAngle` (falling in
size, smooth-unioned so near ones keep a wet neck), 8 tapered streaks ending in a bulb, 16 droplets, 6 gravity drips
(capsule + bulb, down = −v), fbm-roughened edge, wet sheen (lighter band inside the edge + a highlight on the lit side,
screen up-left). `_Reveal` plays the throw: blob punches out with overshoot, flung parts fly out in order of distance,
streaks lengthen, drips start after ~55 %. `_Reveal = 1` is the finished splat, `0` is empty.

| Property | Range | Default | What it does |
|---|---|---|---|
| `_Color` | colour | `(0.95,0.12,0.38,1)` | paint colour; alpha = overall opacity |
| `_Seed` | float | 1 | the whole splat is a function of this |
| `_Reveal` | 0–1 | 1 | throw animation |
| `_ThrowAngle` | 0–360 | 25 | throw direction in degrees (0 = right, 90 = up, v up) |
| `_Reach` | 0.2–0.95 | 0.8 | how far satellites/droplets are flung (blob is offset back by ¼ of it) |
| `_Directional` | 0–1 | 0.65 | 0 = burst in all directions, 1 = tight cone around the throw |
| `_Size` | 0.08–0.6 | 0.30 | blob radius (picture is −1..1) |
| `_Lobes` | 0–1 | 0.45 | broad outline irregularity |
| `_Tendrils` | 0–1 | 0.5 | pointed tongues, biased toward the throw |
| `_Stretch` | 0–1 | 0.3 | squash of blob/satellites along the throw |
| `_Rough` / `_RoughScale` | 0–1 / 2–40 | 0.2 / 14 | fbm edge roughness amount / frequency |
| `_Smooth` | 0–1 | 0.35 | wet-neck smoothing between shapes |
| `_Satellites` / `_SatSize` / `_Spread` | 0–1 / 0.05–0.8 / 0–1 | 0.8 / 0.5 / 0.45 | satellite amount (of 10) / size vs blob / sideways spread |
| `_Streaks` / `_StreakLen` | 0–1 / 0.2–2 | 0.6 / 1 | streak amount (of 8) / length |
| `_Droplets` | 0–1 | 0.8 | droplet amount (of 16) |
| `_Drips` / `_DripLen` | 0–1 / 0.05–1 | 0.5 / 0.45 | drip amount (of 6; fractional = shorter) / length |
| `_Gloss` / `_GlossWidth` | 0–1 / 0.005–0.1 | 0.45 / 0.018 | wet sheen strength / width of the rim band |
| `_Depth` | 0–0.6 | 0.12 | thickness shading (pool deeper than rim; less on light paint) |
| `_Variation` | 0–0.4 | 0.08 | low-frequency pigment variation |

Notes: the sheen highlight uses `ddx/ddy` of the shape field, so its light direction is screen-space (fixed up-left);
FXC cost is a handful of fixed `[unroll]` loops (10 + 8 + 16 + 6) with no branches on varying data.

### 11.2 `UI/Decal/Spray` — `DecalSpray.shader`  ·  `Looks/_decals/spray.png`
A spray-can stroke along up to six points. **Point scheme** (shared with Brush, `CG/Core/UIDecalStroke.cginc`, new,
included only by the two stroke generators): `_P0.._P5` are `float4(x, y, pressure, unused)` in the decoration's uv
(0..1, v up, square quad), `_PointCount` (1..6) says how many are live; the path is a Catmull-Rom spline *through*
the points (6 straight pieces per span, fixed `[unroll]`), pressure interpolates linearly; one point = one dab.
Look: Gaussian droplet density about the path → `alpha = 1 − exp(−flow · gauss)` (soft core), the falloff is stippled
against a fine noise (speckle), and two sizes of overspray dots outside the core thin out with distance.

| Property | Range | Default | What it does |
|---|---|---|---|
| `_Color` | colour | `(1,0.83,0,1)` | paint colour; alpha = overall opacity |
| `_Seed` | float | 1 | speckle + overspray pattern |
| `_PointCount` | 1–6 | 4 | live points |
| `_P0`…`_P5` | vector | see file | x, y, pressure, unused (uv 0..1) |
| `_Width` | 0.01–0.4 | 0.1 | core radius at pressure 1 (picture heights) |
| `_PressureWidth` / `_PressureFlow` | 0–1 | 0.8 / 0.5 | how much pressure thins the stroke / its paint amount |
| `_Flow` | 0.2–8 | 3.5 | paint amount: high = solid centre, low = see-through mist |
| `_Softness` | 0–1 | 0.5 | tight can-at-the-wall line → wide diffuse puff |
| `_Speckle` / `_GrainScale` | 0–1 / 40–400 | 0.7 / 170 | stippled edge amount / grain features per picture (lower it for small decals) |
| `_Overspray` / `_OversprayReach` | 0–1 / 1–5 | 0.6 / 2.4 | droplets outside the core / how far out (× core radius) |
| `_DotSize` | 0.2–2 | 1 | overspray dot size |

Cost: 30 path pieces + two 3×3 dot layers, all fixed `[unroll]`, branch-free.
