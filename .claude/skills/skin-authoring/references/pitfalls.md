# Shader bugs, gaps and traps found while authoring the eight shipped looks

Everything here was verified by isolation renders against the real shaders, not inferred.

## Authoring mistakes that broke the running app (not shader bugs — our bugs)

**Missing `bounds` broke Mixer scrolling.** All 60 first-pass skins were emitted without a
`"bounds"` field, because `Tools/skinlib.skin()` supported the parameter but nothing passed it.
`ShaderBounds` defaults to a FULL-RECT hitbox (`type: Rect, width: 1, height: 1` —
`Assets/MaterialStateStack/Core/ShaderBounds.cs`), not "no hit test" — so every reskinned knob's
hitbox grew to cover its whole RectTransform, including the corner margin a correctly-bounded
control leaves as dead space. That margin is exactly where a ScrollRect drag gesture was passing
through. Fixed by adding `Tools/skinlib.BOUNDS` (measured from each role's stock skin) and wiring
`bounds=BOUNDS[...]` into every `skin()` call in both design modules; re-verified against the real
C# bake (80/80 files byte-identical, bounds included). **Any new design module must do the same —
see SKILL.md's "Hit-test bounds" section, and check for this before calling any skin done.**

## Confirmed bugs

**`_KnobEdge` fills the cap instead of stroking its edge.**
At `_KnobEdgeWidth: 0.022` the entire knob face goes solid `_KnobEdgeColor`. Isolation: turning
`_KnobEdgeEnabled` off is what removes the solid disc. Workaround: park an `_OuterRingN` at the cap
radius (`_OuterRing2Radius ≈ _KnobSize`) for an outline.

**Related:** `_NubShapeType` values 5–19 are commented out in `getNubSDF` and silently fall back to
a circle (this one IS dead — `_KnobNubShapeType` uses the separate, fully-implemented `getKnobSDF`
dispatcher and has no such gap).

**`_NubRounding` is never referenced.** Use `_NubShapeParam1`.

**`SDFTogglePillRM` does not raymarch.** It declares `_ViewTilt/_ViewAngle/_ViewFOV/_ViewShift`,
includes `SDF3DExtrusion.cginc`, and never reads any of them; the fragment body is identical to the
flat shader's.

**Dead properties carried by 53 shipped skins.** `_LightingLight1Direction` and
`_LightingLight1Specular` appear in `Resources/MaterialStates/*.states.json` and in `SDFKnob.mat`
but exist nowhere in the shader source — lighting is entirely rig-driven via `_GlobalLightPos/
Color/FxN` plus the control's `_Position`. Any note claiming these were "tuned by eye" is stale.

**Other inert properties:** `_PanelShapeParam3`; `_TrackInsetDepth` on the toggle; `_Value`,
`_Color` and `_MainTex` on the button; `_Color` on `SDFKnobRM`; `_KnobShapeParam4-6`; and every
pattern rotate/mod property on layers whose call site hardcodes `currentValue = 0`.

## Traps that look like bugs but are not

**CORRECTION (this doc previously called this a bug — it is not):** `_Nub` renders BEFORE the
Knob body in the composite order (Fill/Line/Value → Nub → Border → Knob → KnobEdge → KnobNub), so
the opaque Knob body draws over anything `_Nub` places inside the cap's footprint. That is by
design: `_Nub` is for a marker OUTSIDE the cap (e.g. `_NubDistance` at/beyond `_LineRadius`, riding
the arc), used alongside `_KnobNub` (which sits on the cap, drawn last) when a skin wants two
independent value cues rather than one. An isolation test that only swept `_NubDistance` up to 0.9
on a knob whose cap covers roughly that same radius will make `_Nub` look broken when it is simply
being drawn under — confirmed by re-testing at `_NubDistance` 0.62–1.02, where it appears cleanly
past the cap edge.

**Major ticks are a separate colour pair.** `_OuterMarksMajorColorFilled/Unfilled` default to
`(0.3,1,0.3)` and white. Unset, every knob shows stray green and white ticks at the major interval.
This is almost certainly why the shipped knobs look confetti-coloured.

**`_AngleStart = 0` is 9 o'clock, not 12.** UI angle: 0=W, 90=N, 180=E, 270=S, clockwise positive.
The classic hardware layout with the dead zone centred at the bottom is `_AngleStart: 315`,
`_AngleRange: 270`. The stock default (0/270) puts the gap in the bottom-LEFT.

**Scale marks do not inherit the value sweep.** Set `_OuterMarksAngleStart/Range` equal to
`_AngleStart/_AngleRange` by hand or the ticks will not line up with the arc.

**`_TrackValueZeroPoint: 1` silently switches which colour draws the fill** — it uses
`_TrackValueNegativeColor` (disabled by default), so the slider shows no progress at all.

**Slider orientation is inferred from aspect, not authored.** A perfectly square slider registers
as horizontal (`>=`). Force it with `_AspectRatio`.

**Gradient types 5/6 (BevelDepth/BevelWalls) are RM-wall-only.** Anywhere else they fall through to
a flat 0.5 — a solid mid-palette colour, no gradient.

## RM / non-RM parity gaps

A skin file is shared between e.g. `SDFKnob` and `SDFKnobRM`, so anything RM-only other than the
`_View*` set is a trap. Current gaps (`Tools/skinlib.py` reports these at author time):

- `SDFButton` has `_AspectRatio`; `SDFButtonRM` does not.
- `SDFButtonRM` adds `_AAWidth`, `_ButtonLipHeight`, `_ButtonShadowNMaxCast`.
- `SDFKnobRM` adds `_KnobLipHeight`, `_KnobShadowNMaxCast`.
- `SDFSliderRM` adds `_TrackValueBevel*`, `_TrackValueFaceSmoothness`, `_TrackViewElevation`,
  `_HandleViewElevation` — the non-RM slider cannot bevel its value track at all.

## Feature requests worth raising

1. **`_LightingEnabled` (or `_Unlit`) float guard** per shader. Tron and Flat are conceptually
   unlit but the rig still adds a flat lift they have to author around, and skipping the lighting
   maths outright is the performance win those styles exist for.
2. **Per-theme light rig in the SkinForge manifest.** The biggest remaining quality gap in the light
   modes: the shipped rig (warm key + blue + **green** fill) is tuned for dark skins, and on a pale
   palette the green fill tints everything olive. `Themes/*.theme.json` already carries a `scene`
   block and `UiLightRig.Load` already reads it — SkinForge just cannot emit one per mode. A
   verified neutral rig (two white lamps, fill disabled) removes the cast entirely.
3. **Toggle pill: let the track colour follow `_Value`**, and let the LED bloom be hidden without
   losing `_LedSurfaceBlend`. Today the LED draws a second ball beside the handle.
4. **A stroke-mode for `_KnobEdge`** (or fix the fill behaviour).
5. **Pixel-aware pattern scale.** An optional "cycles per 100px" mode would remove the need to
   author a separate skin file per size purely for grain.
