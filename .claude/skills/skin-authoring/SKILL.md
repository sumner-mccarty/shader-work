---
name: skin-authoring
description: Author or fix DrumSumDrum `.states.json` UI skins for the SDF shaders (knob, button, slider, toggle pill, panel) and the SkinForge style recipes that ship them. Use when creating a new look, restyling parts, debugging "this shader property did nothing", tuning a value indicator so 0%/40%/80% read clearly, or when a pattern/grain looks wrong at a given control size.
---

# Authoring `.states.json` skins

A skin is a flat bag of 60–140 shader property values. The two failure modes that waste the most
time are both silent: **naming a property the shader does not declare** (ignored — the value simply
"does nothing"), and **writing a colour into a Float slot**. Never hand-edit raw JSON blind; go
through the tooling below, which validates every key against the shader's own Properties block.

## The loop

Never iterate through Play Mode, and never judge a skin from the Designer's single-control preview.

```bash
python Tools/design_realistic.py     # emit states.json from a Python spec (validated)
python Tools/sheet_style.py Realistic "#15181C"   # every part, real sizes, real shadow pass
python Tools/sheet_rack.py Realistic dark          # the cohesion test — parts ON a faceplate
```

`Assets/Editor/SkinSheet.cs` is an `[InitializeOnLoad]` poller: it watches `.skinsheet/job.json`,
renders each cell with the REAL shader via `Graphics.Blit`, and writes PNGs. It reads states files
from **disk**, so a candidate skin needs no import and no domain reload. A whole theme renders in
about a second. Unity must be open; edits to `SkinSheet.cs` itself need a Ctrl+R in the editor.

**Without Unity (2026-10-06): slrender.** The same jobs render headless — Linux/cloud or a closed
editor — through `slrender` (the shader-work repo, parity-tested 30/30 against SkinSheet.cs).
`Tools/skinsheet.py` picks it automatically when no editor is running (`SKINSHEET_BACKEND=
unity|slrender|bus`; `bus` = a warm `python -m slrender watch --bus .skinsheet`). It renders in the
app's **screen** orientation by default, which FIXES the inverted bevel-depth sign described below
(SkinSheet renders into a texture, where Unity flips the projection and every screen-derivative
normal); `SKINSHEET_ORIENTATION=texture` reproduces SkinSheet exactly. SkinSheet.cs now pins
`_Time` (job/cell `time`, default 0 — gradients with the default speed 1 scroll) and `_GlobalViewCam`
(cell `viewCam`; was whatever the last Play session left).

Always look at a **rack composite**, not a part list. A list flatters a skin — every control gets
its own row and never has to agree with a neighbour. See `references/tooling.md`.

## Hit-test bounds — set this or you will break input, not just visuals

**Every skin needs a `"bounds"` field, and `skinlib.skin()` will not add one for you unless you
pass `bounds=`.** A states.json with no `bounds` key does not mean "no hit test" — it means the
FULL RectTransform becomes hit-testable (`ShaderBounds` defaults to `type: Rect, width: 1,
height: 1`, per `Assets/MaterialStateStack/Core/ShaderBounds.cs`). A correctly-bounded control
(e.g. the stock knob's `width/height ≈ 0.89`) leaves the corners of its RectTransform as dead
space for whatever sits behind it. A bounds-less control claims that entire margin instead —
which is exactly what broke Mixer scrolling after a theme swap: the knobs' hitboxes grew to cover
the gaps a ScrollRect drag was passing through.

Use `Tools/skinlib.BOUNDS` — pre-measured from each role's stock skin (`knob`, `button`,
`button_round`, `button_accent`, `slider`, `pill`, `panel`) — and pass the right one to every
`skin()` call: `bounds=BOUNDS["knob"]`. Where a shape has a `paddingParam` (buttons: `_ButtonPadding`,
sliders: `_BgPadding`), the runtime derives the live hitbox from that shader property at the
control's current aspect, so the authored width/height are only the fallback before a material
exists — set the padding param name correctly and don't worry about pixel-perfecting the numbers.

**Verify, don't assume:** `python -c "import json,glob; ..."` scanning every generated
`.states.json` for a missing `"bounds"` key is a 5-second check that would have caught this before
it shipped. Run it after any new `design_*.py` module.

## Non-obvious mechanics that decide how a skin looks

Full property tables live in `Docs/Skinning/Params-*.md` (Knob/Button/Slider/Toggle/Panel/Core).
These are the facts that are not discoverable from the property names:

- **Bevel distance is the single most important number.** ~0.10 = a flat face with a milled
  chamfer (machined hardware). 0.30+ turns any control into a sphere. Neomorphic is the one style
  that legitimately wants a wide bevel (0.26–0.42) — clay is moulded, not milled.

- **A perfectly FLAT face never reads as metal, no matter how good the pattern is — this is the
  single highest-leverage fix in the whole file.** `ApplyUILighting`'s Blinn-Phong specular term
  (`UILighting.cginc:519-523`) is `pow(dot(normal, halfDir), power)`. A flat face has a constant
  normal, so that term is a CONSTANT across the whole surface — no gradient, no sparkle, no sense
  of a directional lamp, regardless of how much pattern/roughness/specular-effect you dial in. Set
  `_XxxFaceSmoothness` to a subtle dome (~0.15 on a large flat panel, ~0.3–0.45 on a knob cap or
  button face) and the SAME lighting math produces a moving highlight sweep instead. Verified
  side-by-side on knob cap, collar, button face, slider/pill handle: flat-vs-domed at identical
  pattern settings is the entire difference between "sticker" and "machined part". **But see the
  medial-axis rule below — this applies to ROUND parts and well-rounded buttons only, never to a
  rectangular plate.**

- **⚠ THE MEDIAL-AXIS RULE — the #1 source of "hard lines" on any rectangular part.**
  Both the face dome (`_XxxFaceSmoothness`) and the bevel (`CalculateShapeBevelNormal`) build their
  normal from the SDF GRADIENT. A rounded rectangle's gradient is **discontinuous along its medial
  axis** — the 45° diagonals running in from each corner — so any wide-enough normal-shaping band
  stamps hard diagonal wedges across the part. It is a geometry artifact, not a lighting effect;
  no colour, pattern or smoothness value hides it. Measured thresholds:
  - `_PanelFaceSmoothness` on a rect plate: wedges visible from **0.05**. Keep it at **0**.
  - `_PanelBevelDistance`: clean to ~0.14, wedges badly by **0.22**.
  - A circle (knob cap, collar) has no medial axis and is immune — dome those freely.
  - A button survives a dome because high `_ButtonRoundness` keeps its bevel band clear of the axis.
  A plate gets its material read from the **gradient** instead, which is evaluated in UV space and
  has no discontinuity.

- **A plate bevel is a hard bright BAR waiting to happen.** The chamfer is only a few pixels wide,
  so any real depth tilts its normal near-vertical and the lamp-facing edge blows out into a chrome
  strip down one side. Widening the bevel to soften it just walks into the medial-axis rule above.
  On the shipped looks the outermost plate has **no bevel at all** — the rounded silhouette plus the
  drop shadow already read as a physical panel. Only RECESSED insets keep a bevel (a dish reads as a
  dish only if its wall catches light), and even then at low depth (~0.14).

- **Plate padding and corners SCALE with the plate unless you pin them in pixels.** `_PanelPadding`
  and `_PanelShapeParam1` are fractions of the half short side, so a faceplate docked large grows a
  wide margin and a huge corner — the PD-48's title and bank keys ended up outside Neomorphic's
  plate border (0.06 padding = 25px inset and an 80px corner on an 850px panel). Pin any plate a
  layout prints near its edge with `_PanelPaddingPx` (2026-09-13) and `_PanelCornerRadiusPx`
  (canvas units, 0 = proportional): Flat and Neomorphic faceplates use 2px / 4–14px.

- **A panel wants LESS pattern than feels right.** A strong brush pattern at plate scale reads as
  scratches, and at high intensity it beads along any lit edge. ~0.03 intensity at a high scale
  (~70) plus a top-to-bottom gradient is what reads as brushed aluminium.

- **Gradient orientation: `uv.y` is 0 at the BOTTOM.** With `_PanelGradientDirection (0,1,0,0)` the
  position is `dot(uv, dir)` = `uv.y`, so **ColorA is the bottom colour and ColorB the top** — put
  the light in B for a top-lit plate. Do NOT try to flip it with a negative direction `(0,-1,0,0)`:
  that drives the position negative, which clamps and renders the whole plate black.

- **Neomorphic-style buttons want LOW `_ButtonShapeParam1` (~0.2–0.35) and HIGH `_ButtonRoundness`
  (~0.3+)** for the classic soft-app-icon squircle. Watch `_ButtonBevelDistance` when pushing
  bevel depth for "puffiness" — past a certain point the flat, unbevel portion of the face shrinks
  into a small visible rectangle that reads as a separate inset screen rather than one smooth
  puffy surface. ~0.26 distance was the ceiling before that artifact appeared at this shape.

- **Pattern scale is a CYCLE COUNT across the widget's own 0–1 UV, never pixels.** The same number
  gives the same number of cycles at every size, so grain gets physically finer as the control
  shrinks. Derive it from the part's real pixel size: roughly `scale = px / 8` for a visible
  surface grain, `px / 3` for a coarse grip, `px / 1.5` for a fine matte noise. This is why the
  size-keyed roles (`knob.hero` vs `knob.small`) need **separate skin files**, not one file reused.

- **Widths and distances are equi-pixel units where the widget's SHORT side = 2.0.** A slider's
  `_HandleWidth: 0.16` on a 56px-tall widget is ~4px. Use `_HandleHeight` for the cross-axis — it
  is what turns a sliver into a fader cap.

- **Lighting is rig-driven — except `_LightingUnlit`.** `ApplyUILighting` does
  `base * _LightingAmbient + Σ lights`; there is no per-skin light. Raising `_LightingAmbient` on a
  pale palette clips everything to white and flattens every bevel. **`_LightingUnlit 1` (2026-09-13,
  all nine widget shaders) returns the base colour exactly** — no ambient scale, no lamps, no
  specular, under ANY rig (verified: a Flat part renders pixel-identical under a strong lit rig and
  with every lamp off; a Realistic control differs by 210). It is a macro the shader defines before
  its first include (`UI_LIGHTING_UNLIT`), so `UILighting.cginc` stays a pure-function library.
  Unlit looks (Flat, Tron) use it instead of the old "author ambient low" workaround.
  `_LightingLight1Direction` / `_LightingLight1Specular` appear in 53 shipped skins and **exist
  nowhere in the shader** — they are dead.

- **Layers have their own colour pairs you must set or inherit garbage.**
  `_OuterMarksMajorColorFilled/Unfilled` default to bright green and white — leave them unset and
  every knob grows stray green confetti ticks.

- **⚠ `_LightingShadow1Enabled` defaults to ON in `SDFKnob`/`SDFKnobRM` (and ONLY there) — set it
  explicitly.** Default is black, alpha 0.5, distance 0.1: a hard drop shadow the knob throws across
  its own value track. A skin that never names it inherits it, which reads as a dark arc on the far
  side of every knob, makes the line unreadable, and makes the cap look floaty. Found 2026-09-13 on
  Neomorphic Light after the rim, bevels, outer rings and `_KnobShadow1` were all ruled out. Seat a
  cap with ONE faint `_KnobShadow1` (cast 0) instead. The other SDF shaders default it to 0.

- **Dotted ring round a raymarched knob cap (`SDFKnobRM`) = the lip seam.** With a lip, the
  step between the bevel wall and the lip leaves a one-pixel hit/miss gap; with `_KnobLipHeight` 0
  (older shader) grazing hits on the base plane lit near-white. Fix: author `_KnobLipHeight 0`
  (the shader now gives lipless LIP/RIM hits zero coverage, 2026-09-13). Rings, shadow, view cam
  and bevel smoothness do NOT hide it. Don't switch a LIT skin to the flat `UI/SDFKnob` to dodge it.
  (The flat knob itself works — Flat ships on it — but its in-app `UNITY_UI_CLIP_RECT` variant takes
  ~4 minutes to async-compile the first time an editor session draws it, cyan squares until then.
  Wait it out; a player build compiles it offline.)
  **`SDFButtonRM` has the identical seam** (pads/keys): with `_ButtonLipHeight 0` it drew detached
  one-pixel lines along the edges plus corner specks; same guarded fix (zero coverage for lipless
  LIP/RIM hits, fd941d9f). The property default is 0.08, so an UNSET lip is not lip 0 — only skins
  that author 0 take the new path.

- **A knob's base `_Line` emissive is added AFTER the value arcs composite** — any
  `_LineRenderEmissive` washes the filled arc out; brighten the track by colour, never emissive. And
  `_KnobBevelDistance` ≥ the cap radius turns the whole cap into a slope facing away from the lamp
  (grey cap); keep it well inside (~0.22 on `_KnobSize` 0.6).

- **`_KnobNub` sits ON the cap; `_Nub` sits OUTSIDE it.** Composite order (verified against the
  fragment source) is Fill/Line/Value → **Nub** → Border → **Knob body** (drawn on top) →
  KnobEdge → **KnobNub** (drawn last, on top of everything). So `_Nub` is invisible at any
  `_NubDistance` inside the cap's footprint — the opaque Knob body composites over it — and is for
  a SEPARATE marker beyond the cap, typically riding the arc (`_NubDistance` at/above the arc
  radius, e.g. ≥ `_LineRadius`). Use it alongside `_KnobNub` when you want two independent value
  cues (a mark on the cap AND a mark on the arc), not as a substitute for it.

- **The value arc needs ~0.12 of the half-extent of air outside it.** The band spans `_LineRadius`
  … `_LineRadius + _LineWidth` in a quad that ends at 1.0, and the quad clips SQUARE: any part of
  the band past 1.0 is sliced flat, which reads as "the roundness is cut off" at the top and sides.
  Rounded ends reach `sqrt(R² + t²)` (t = half the band), and AA costs another pixel — on a 38px
  knob a pixel is 0.05 of the extent. **Keep `_LineRadius + _LineWidth` ≤ 0.88** (Neomorphic,
  2026-09-20; Tron 0.86, Flat 0.92 with square ends) and rescale `_KnobSize` (the cap radius is
  `_LineRadius × _KnobSize`) so moving the arc in does not shrink the cap.

- **`_KnobEdge` FILLS the cap** rather than stroking its edge. For an outline, park an `_OuterRingN`
  at the cap radius instead.

- **Brushed metal needs `_PanelPatternParam1 = 0.5`.** At 0.0 or 1.0 the Metal pattern is mottled
  noise; only at ~0.5 does it resolve into anisotropic streaks.

- **External shadows are drawn on a separate 2×-expanded quad** (`_ShadowPassMode=1`, driven by
  `WidgetShadowQuad.cs`). The widget quad never draws them. A preview that skips this pass judges
  shadow-driven styles (Realistic, Neomorphic) on a render with no shadow in it.

- **The toggle pill cannot recolour its track from `_Value`.** The only value-driven surface is
  `_LedSurfaceBlend` (handle and handle face). It is gated on `_LedEnabled`, but the bloom "second
  ball" is gated on `_LedEnabled` AND `_LedIntensity > 0` — so **`_LedEnabled 1`, `_LedIntensity 0`,
  `_LedSurfaceBlend 1`** turns the handle `_LedColor` when on, with no ball (Flat's switch).

- **A needle = `_Nub` Rectangle with the cap OFF.** `getNubSDF` takes FULL sizes (it halves them)
  and orients the shape so `_NubSizeWidth` runs along the radius. With `_KnobEnabled 0` nothing
  composites over it: a centre-to-arc needle is width `0.94·r` at distance `0.47·r` (r = `_LineRadius`).

## Structure vs colour — where a change belongs

`Resources/UiStyles/<Style>.style.json` recipes carry **colour**; authored `.states.json` files carry
**structure**. A recipe cannot turn a machined knob into a Tron ring — that is thirty geometry
properties, and burying them in a recipe leaves the user nothing to open in the Designer.

`"$base": "<SkinName>"` in a recipe's family or role block names the authored file that part derives
from (role beats family). A mode whose only override is `$base` **rosters the authored file
directly and bakes nothing** — which is how a style's dark mode stays byte-for-byte the authored
look, while its light mode is a pure recolour of the same geometry.

**`"swaps"` (mode block) re-finishes one AUTHORED skin by name** —
`"swaps": {"RackFaceplateGraphite": { "_PanelColor": "$face", … }}` bakes `<Look>.swap-<Name>` and
the resolver substitutes it wherever a layout falls through to that authored skin. Use it for
hardware the roster deliberately leaves alone (`$inherit` faceplates): a roster entry flattens every
module to one finish, a swap touches only the one you name. Text printed on such a plate must use
`@plate.*` palette roles, not literal hex, or it cannot flip with the metal.

**Pale looks (Neomorphic Light, 2026-09-13) — the calibration that works.** A look's own rig
(`"lights"` in the mode block) of ONE far, high key (`pos [-1.5,3.0]`, `height 4`, fill/bounce off)
adds ~0.5 of diffuse over ambient, so pale surfaces want `_LightingAmbient` ≈ 0.45–0.5; at 0.86+
everything clips to white and every shadow vanishes. On pale plates: turn OFF inset/slider/pill
bevels and the knob `_Fill` dish (they read as dark frames/wells), shrink pad lip + rim, and make
shadows grey not black. App-level pieces a pale look must also set: palette `ink.*`, `display.*`,
`tracks.*` (incl. `noteSeparator`, the multitrack note hairline), `review.slot/slotFill`, `key.*`
(unlit latch colours C# drives), `surface.backdrop` + `surface.gap` (the gaps
between docked panels), and `swaps` for every skin loaded BY NAME (MultiTrackView scrollbars, zoom
faders, track-label wells, GreyButtonRM/MuteToggleRM/SoloToggleRM headers, DisplayBezel).

**Unlit looks (Flat, 2026-09-13) — `Tools/design_flat.py` is the template for Tron.** One generator
emits every part for both modes (`write`), validates (`check`), renders a device mock at real app
sizes (`sheet <mode> <tag>`), and writes the recipe itself (`recipe`) so a hex lives in one place —
do not hand-edit `Flat.style.json`, and `build_recipes.py` no longer emits it. The rules it encodes:
every part names the NON-RM shader (`skin(..., flat_shader=True)`) and sets `_LightingUnlit 1`,
`_ReceiveSceneShadows 0`; **every effect guard is written, on or off** (an unset guard inherits the
source MATERIAL's value, not the shader default); footprints (padding, bounds) are copied from the
app skins each part swaps for (GreyButtonRM 0.252, MuteToggleRM 0.116, EnableLampRM 0.34, RackSlider
bg 0.13) so a look never moves a layout; the rig is `Themes/Flat.theme` with every lamp off; and with
no shadow authored anywhere `UIShadowBufferManager` idles its capture camera. Roster EVERY role,
family and by-name skin (`SWAP_PART`) to an authored file, including the six RackFaceplate* colours —
nothing baked means nothing inherits an RM shader. App pieces a look with pale keys or dark plates
needs: `key.glyphOff/muteOn/soloOn/velOff/velOn` (multitrack latch marks; a lit mute/solo key FILLS
via its Active state, so its mark goes dark), and an `ink` group in the DARK mode too — `PrintInk`
flips dark neutral print (the cream/silver modules' `#22262E` silkscreen) when the surface's ink is
light. Leave `key` out of a dark mode's ink: C# prints dark marks on orange accent keys on purpose.
Sheet harness trap: render each cell over the plate it sits on (`bg`), never transparent black — an
AA edge blended into black then alpha-composited again reads as a dark outline the app never draws.

**Neon looks (Tron, 2026-09-14) — `Tools/design_tron.py`, same rules as Flat plus light tubes.** Every
edge is three layers the non-RM shaders already have: CORE = Border band, emissive, 4-stop gradient;
BLOOM = Edge ring with render-alpha 0 and emissive 1 (blend is `One OneMinusSrcAlpha`, so a zero-alpha
emissive pixel is pure ADDITIVE light spilling onto whatever is behind — bloom with no shadow pass);
SHEEN = the bevel band, which unlit has no normal and is just a colour fading in from the outline.
Dark = thin blue→violet tubes with pink at the tip on navy glass; Light = the same black room with
white-hot wide tubes and a big pale bloom. Traps found getting there:
- **Panel and toggle Edges fill INSIDE.** Only the button's Edge uses `UIRingMask` (cut inside); the
  panel/toggle indent is full strength under the body, harmless when alpha-composited under an opaque
  body but its EMISSIVE survives and lights the whole plate. Panels now have `_EdgeCutInside 1`; the
  pill has no cut, so Tron's pill has no Edge.
- **A bloom needs padding, and padding pushes a plate's content in.** Keep plate bloom ≈ 3–4px and pad =
  line + bloom + 0.5 (the graded ring reaches zero at the quad edge, so no cut shows); put brightness
  INWARD (sheen/gradient) instead of widening the bloom. SDFPanel gained `_BorderWidthPx`, `_EdgeWidthPx`,
  and `_PanelCornerRadiusPx` now pins the OCTAGON cut too — proportional tubes are hairlines on a strip
  and bars on a rack.
- **A gradient on a layer beats any C# colour write to it.** `lerp(colour, gradient, a=1)` — so
  `LightDuckKey`'s `_ButtonColor/_EdgeColor/_BorderColor` and a pad's `padColor` binding are ignored
  wherever that layer has a gradient. Pads turn gradients off on bound layers.
- **Glyph colour is live-driven** (`GlyphMark` → `SetMaterialColor("_IconColor")`), so no skin state can
  darken a mark: a lit key must be a fill a WHITE glyph reads on (Tron Light's first white fills ate them).
- **`pad.empty` alpha is how far an unloaded pad's row colour moves toward it** — opaque black killed
  every empty pad's tube; Tron uses 50%.
- **Unlit sheen bands crease into an X** when they reach a rectangle's medial axis (no normals needed —
  the band follows the SDF distance). Keep a pad's latched/hover sheen well short of the centre.
- **Unset `_ButtonLipHeight` is 0.08, not 0**, and draws the dotted lip seam round raymarched keys —
  Neomorphic Light's Button/Accent/Close/Lamp/ToggleBtn were all unset (fixed to 0). The RM slider
  handle's speckled rim was NOT a lip: its wall hits had no silhouette AA (fixed the SDFButtonRM way,
  untilted only).
Offline harness: `design_tron.py sheet <mode> <tag>` renders each cell over its plate's GRADIENT colour
(not the bottom colour — dark squares otherwise).

**Displays are a look axis too (2026-09-13).** Screens — ScopeDisplay modes, WaveformView, the
GN-UV meters — wear named finishes from `Resources/UiThemes/ScopeFinishes.json`; a layout node names
the AUTHORED one (`glass.amber`, `led.matrix.green`, `lcd.grey`, …). A look re-finishes them with a
mode-block `"displays": { "<authored>": "<finish>", "waveform": "<finish>", "*": "<finish>" }` →
`UiThemeManifest.displays`, resolved in `ScopeFinishes.Resolve` as authored finish → node props →
LOOK finish (the look wins), so a look finish must carry APPEARANCE keys only — never
mode/grid/fill/curveThickness. Realistic names none (its boutique hardware is the authored set);
Flat maps to `flat.<mode>[.meter|.waveform]`, Neomorphic to `neo.<mode>…`. Traps found getting there:
a PALE screen needs `surfaceMode` 0 or 4 (LCD) — glass/plastic covers (1–2) assume an emissive
picture on a dark field and render a pale background dark; VU meters on a pale screen need
`housingColor` or their unlit segments print as dark stripes; and **packs carry the map, so rebuild
packs only AFTER Unity has finished compiling** — a rebuild during the domain reload silently writes
manifests with no `displays` (check: unzip a `.themepack.bytes`, read `themes/<Look>.theme.json`).
Skin Studio previews resolve screens against their own look via a `displayTheme` prop and are lit by
their own look's rig via `SkinSwatch.LightAs`.

**Display finish keys added 2026-09-18** (all appearance keys, so a look finish may carry them):
- `vuLowColor/vuMidColor/vuHighColor` (alpha 0 = classic green/amber/red), `vuMidAt/vuHighAt`,
  `vuSegments` (0 = solid bar) — the VU ladder is a LOOK choice now; `MeterStyle` layers a per-look
  Skin Studio override (TWEAK ▸ METERS) on top.
- **Cut-in** — the hole in the faceplate a display sits in (`UIApplyDisplayCutIn`, UIDisplaySurface
  .cginc): `cutWallColor` + `cutBevelPx/cutBevelDepth/cutBevelMinPx` (the lit wall, only on displays
  ≥ 80px short side) then `cutEdgePx/cutEdgeColor/cutEdgeStrength` (the lip's rolling shadow, starting
  at the foot of the wall). ON by default in `DisplaySurfaceProps`; Flat turns it off (`cutEdgePx 0,
  cutBevelPx 0`). Widths scale with display size. `scopesheet.py` mirrors the C# defaults.
- Waveform band colours: every look finish now uses `colorMode`/`waveColorMode` 2 with its own
  `low/mid/highColor` — mode 0 threw the frequency information away.
- ⚠ **A shader/.cginc edit renders STALE until Unity refreshes** — call
  `skinsheet.refresh_assets()` once after touching one (sends Ctrl+R); the sheet otherwise quietly
  shows the previous compile. Verify with a garish diagnostic colour, not by eye.

**Realistic faceplates (2026-09-18):** the mixer modules wear the AUTHORED `RackFaceplate<Colour>`
skins, not `RealisticFace` — `sheet_rack.py` never shows them; use `sheet_faceplates.py`. Dark =
enamel (Plastic pattern 0, scale 100, ~0.06, pattern specular 1.6 / roughness 0.1); Light = brushed
aluminium via the recipe's `swaps` (Metal 1, scale 100, 0.045, Param1 0.5, Param2 0.99) — at scale 80
/ 0.075 on a module-sized plate the Metal pattern reads as liquid swirls, not brushing.

**Realistic mixer realism pass (2026-10-04) — supersedes the faceplate numbers above.** What read
as "pixely": (1) widget-relative grain (blotches ~10 units); (2) `_PanelPatternSpecularEffect` 1.8 —
spec is `1 + pattern·effect·10`, so faint noise became lit camo. Now: enamel plates = Plastic 0,
scale 60, Px 100, 0.10, contrast 1, spec 0.3, rough 0.5, P1 0.7 / P2 0 (warp = swirls) / P3 0.15;
brushed (Graphite, Backplane, every *Light) = Metal 1, scale 160, Px 160, 0.12 (Light 0.07),
contrast 1, spec 0.5. `RedKnobRM`: the grey "spike" was `_KnobFaceShapeType 8` (ChickenHead) — the
FACE shape is the lit top, everything outside it renders as dark skirt, so a pointer face = a
pointer silhouette. Now face off, Fluted 6 ×20 shallow (0.15) skirt, dome 0.3, no `_Fill` dish,
cream `_KnobNub` circle 0.065 @ 0.7. ⚠ KnobNub shapes can't draw a thin line (Oval/FaderCap stay
blobs); a dot is the clean indicator. `GreyButtonRM`: roundness 0.4, dome 0.3, bevel 0.18/0.5,
grain 0.04 @ 40. Sweep harness = SkinSheet cells at real mixer sizes, viewed at 3-4× nearest.

**⚠ SkinSheet draws panel bevel DEPTH SIGN inverted vs the app (found 2026-10-04).** LedWell* had
depth/rim −0.55/−0.45 ("recessed"): recessed on the sheet, RAISED in Play Mode under both Realistic
rigs (bright top lip, dark bottom = a button). Flipped to +0.55/+0.45 and they read as LCDs set
into the plate in both modes. Likely the D3D RT y-flip under `Graphics.Blit` inverting the
screen-derivative normal. Other "recessed" skins (RackPlateInset, PadSocket, RackScrollTrack,
Neo*Inset/Well) carry negative depth and may be inverted in-app too — judge bevel direction in
Play Mode or with slrender's default `screen` orientation, never on the Unity sheet. (Confirmed
2026-10-06: it IS the render-to-texture flip — slrender renders LedWellAmber raised in `texture`
mode and recessed in `screen` mode, matching sheet vs Play Mode.) Realistic Light coloured plates are anodised tints at the silver
plate's lightness (Blue .58/.66/.76, Green .62/.69/.58, Rust .76/.61/.51, Black .50, Cream .84/.80/.70),
gradient A = ×0.92 (bottom), B = ×1.07 (top), same as silver.

**Pixel-locked grain: `_PanelPatternPx`** (SDFPanel, 2026-10-04) = canvas units one pattern tile
spans; the scale then counts cycles per that many units, so the grain is identical on a 60-unit
strip and a 1200-unit rack. Use it for any plate that resizes (backplanes, stretch panels).
`RackBackplane` = brushed Metal 1, scale 100, Px 200, 0.15, Param2 0 / Param3 0 (Param3's streak
term runs at 4× frequency and aliases once pixel-locked). 0 = the legacy behaviour below.
EVERY shipped patterned SDFPanel skin is pixel-locked (2026-10-04), with Px = the size it was tuned
at (RackFaceplate* 230, Realistic Face/Inset/Back 260/200/240, Tron 260/200/300, PadWell 406), so
its look at that size is unchanged. A new patterned panel skin should set Px too. Generators
(`design_realistic/others/tron.py`) emit it from their `px`. ⚠ Those generators have DRIFTED from the
committed skins — running one rewrites ~24 unrelated files; diff before keeping a regen.

**Otherwise pattern scale is per PANEL, not per pixel** (uv 0..1 × `_PanelPatternScale`). At 100 a
230px-tall faceplate gets a ~2px grain period — invisible at 1:1, visible only zoomed. Keep
faceplate scales ~25–35 (2026-09-19: enamel Plastic 26 / 0.075; brushed Metal 34 / 0.12,
Param2 0 = longest streaks — Param2 is anisotropy, HIGHER = shorter streaks).

**Where each look's faceplates are tuned (Designer-editable files):**
- Realistic Dark: `MaterialStates/RackFaceplate<Colour>.states.json` (authored, enamel).
- Realistic Light: `MaterialStates/RackFaceplate<Colour>Light.states.json` — the light `swaps`
  in Realistic.style.json now name these directly (`"RackFaceplateBlue": "RackFaceplateBlueLight"`)
  instead of carrying a recipe, so the Designer owns them.
- Flat / Neomorphic / Tron: generated by `Tools/design_<look>.py` (panel.faceplate role in
  `Resources/UiStyles/<Look>.style.json`); hand-edits to their files are overwritten on regen —
  put the value in the generator.
- Then Tools ▸ DrumSumDrum ▸ Rebuild Shipped Theme Packs, or the app shows the frozen pack.

**Built-in wells need a px margin.** A recessed well (negative rim/bevel) with `_PanelPadding`
≈0.01 puts its rim AA on the quad edge and the quad clips it square. Pin `_PanelPaddingPx` 2–4.
Display cut-ins cut their corners to transparent (UIApplyDisplayCutIn coverage), never paint them.

**Light modes: change the chassis, not the controls.** Recolouring knobs/keys/lamps pale breaks
every literal light glyph and blows Active emissive to white; dark controls on light metal is how
daylight hardware is built (Realistic Light, 2026-09-13).

`Tools/bake.py` is a faithful Python port of `SkinForge.Apply`, verified to produce byte-identical
output to the C# across all 80 baked files. Use it to preview a recipe edit without Unity; re-verify
with `{"bake": true}` in a SkinSheet job if you change either implementation.

## Checklist before calling a skin done

1. **`bounds` present on every generated file** — grep for it; see above. This is a functional
   bug, not a cosmetic one, and it will not show up in any render.
2. Value legibility: render 0% / 40% / 80% / 100% and confirm they are distinguishable at the
   **smallest** size the part is used at.
3. States: Hover, Pressed, Disabled and (for latching parts) Active all visibly differ. Shipped
   skins commonly have an empty `Disabled` — a disabled control that looks enabled is a bug.
4. Pattern scale checked at the real pixel size, not the preview size.
5. One shadow contract across the whole set — same colour, blur and cast — or parts float at
   different heights from each other.
6. Rack composite, not a part list.

See `references/tooling.md` for the file map and job schema, and `references/pitfalls.md` for the
running list of shader bugs and gaps found while authoring.
