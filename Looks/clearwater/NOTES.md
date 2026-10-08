# Clearwater — notes

**Concept.** The modern translucent-glass UI style, done as two glasses over one live wallpaper. **Plates are frosted**
(`glass.frosted`: blurred, a dim smoke so print holds, a soft rounded edge). **Controls are liquid lenses**
(`glass.clear`: almost no blur, a deep rounded edge, strong refraction, a bright fresnel rim, a clear-coat glint):
the wallpaper is clear in the middle of a key and bends hard at its rim. Keys are pills and capsules, pads are soft
squircles, knobs are domed glass pucks, handles are capsule lenses. **One warm accent** (amber) is ON, value and
focus — warm light in cold glass, so ON is the only warm thing on screen.

**The wallpaper is procedural and animated** (`Assets/Shaders/Backdrop*.shader`, `Docs/Skinning/Params-Backdrop.md`):
dark = `Caustics` (flowing water), light = `Splotch` (pastel colour pools with crisp-ish edges). Both are exactly
periodic (loop = 1 / `_Speed` s = 67 s here), tunable from a states file, and need no texture. The tileable PNGs
(`Backdrops/Lagoon`, `Backdrops/Daybreak`) stay as the fallback for a host that cannot render the skin.

How the glass term composes (read before tuning): `pixel = lerp(lit body, wallpaper × tint, strength) + fresnel rim`,
then the matcap on top. At strength ~0.9 the body colour and the lamp rig are ~10% of the pixel, so **hover / pressed /
ON / disabled move RIM, TINT, STRENGTH and REFRACT** (the `key_states()` block in the spec), not the colour the kit's
default state deltas write — those are invisible on glass.

## Design principles taken from the reference style (generic; no brand, no trade dress)
Glass belongs to the control/navigation layer, not to content · refraction concentrates at the edge, the middle stays
clear · highlights follow the geometry · the pane carries a **dimming layer** under print (the style's best-known
criticism is print dissolving into the picture, 1.5:1 in places) · a tinted/solid variant for the primary action ·
interaction deepens the lens. The legibility loop below exists because of the third point.

## Rounds (CHECKLIST.md items; self-scored — no independent critic has seen this look)
`identity / story / material / light / taste / knobs30 / pads / states / print / craft / glass`

**Round 0 — the old Liquid-Glass spec ported onto the glass presets, untuned.** 5/6/5/3/4/6/5/4/3/4/6
Wallpaper visible through every part, but: a hard white window-reflection wedge in the corner of every key, pad and
cap (the `glass_rim` matcap at 0.9); light mode a dark-pink chassis, plate clip 8%; 17 print pairs under 3:1.
*Fix first:* matcap strength, a pale wallpaper for light, BODY tokens.

**Round 1 — smoked/milk glass, rim-tint-strength states, BODY at one mid-tone.** 6/7/6/4/5/6/6/6/7/5/7
BODY/CAP/HANDLE sit at L≈0.21 in BOTH modes so white print (dark) and navy print (light) each clear 3:1 on the proxy
token (3.85 / 3.46). Hover/Pressed/Active/Disabled now differ. *Still wrong:* light mode served a stale wallpaper
(the warm renderer caches crops by path — see "Pipeline findings"); keys read as boxes; thick white outline frames.

**Round 2 — wallpaper fixed, dimming tint on dark plates, accent glass.** 6/7/7/5/5/6/6/7/7/6/7
Accent keys needed their own glass (strength 0.3) or the amber mixed with the wallpaper into mud.
*Still wrong:* "simple glass": boxy keys, the same window glint on everything, rim glow bars on plates, light plates 15% clip.

**Round 3–4 — liquid lenses.** 8/8/7/6/6/7/7/7/8/6/8
`corner` 0 is a pill (1 = a sharp rectangle — I had it backwards for one round). Refract 0.28, blur 0.4, a tight steep
fillet (bevel 0.14/0.6/0.6) = a thin bright rim and a narrow refractive band. DeepWater's caustics gave the lens
something to bend (Aurora is too smooth: a lens refracts structure, not a gradient). Warm amber accent.
*Still wrong:* light controls pale-on-pale, pad rims thick.

**Round 5 — the static racks.** 8/8/8/7/7/7/7/7/8/7/8
Rims thinned (key 0.8 / light 0.5), pads lensed, 30 px knobs read 0/40/80/100 in both modes (`sheets/knob30.png`: 30 px, 4x),
printcheck 0 pairs under 3:1, plate clip 0.00% in both modes.

**Round 6–8 — the wallpaper flows (user direction), legibility must survive it.**
1. Tileable textures (Lagoon, Daybreak) scrolled — rejected as the end state: finite, a seam risk, flat scroll only.
2. **Procedural shaders** (`UI/Backdrop/Caustics|Splotch|Ribbons`): exactly periodic, tunable, no texture, no cost to any
   widget shader. `Looks/clearwater/flow_demo.py` renders the rack across one full loop and measures, per printed label,
   the worst-case contrast against the brightest (dark ink: darkest) background that ever passes behind it.
3. The loop found what the stills hid: dark HOVER/KEY labels at 1.98–2.46:1 where a caustic crosses a clear key, light
   dim print at 2.9:1 under a dark pool, the light disabled key at 2.76:1. Fixed with a dimmer wallpaper peak, more smoke
   on clear keys, a hover tint that stays close to normal (the rim carries hover), a lighter disabled key, darker light-mode
   dim ink. **Result over a 24-phase sweep: 0 labels under 3:1 in both modes (dark worst 3.06, light worst 3.23);
   plate clip 0.00% at every frame.** Values: light-mode fill was 1.08:1 on the plate; now a deep-orange fill on a dark
   track (3.65:1 on the track).

### Final scores (self): identity 8 · story 8 · material 8 · light 7 · taste 7 · knobs30 7 · pads 7 · states 7 · print 8 · craft 7 · glass 8
Identity: the only look with a see-through wallpaper; differs from every other rack in material (glass), form language
(pills, lens pads, puck knobs), lighting class (lit glass over a live picture) and palette structure (cold glass, one warm
accent) — see the family grid in the PR. Taste is a guess: the owner has not rated it, and "physical conviction wins"
(TASTE.md) is exactly what a Unity Play Mode look will decide.

## Waivers (all four are the same reason)
`outer-bevel:Clearwater{Dark,Light}{Face,Back}` — the kit writes a soft rounded bevel (distance 0.12 ≤ the 0.14 medial-axis
limit, depth 0.35, smoothness 0.9) on every glass plate because refraction and the fresnel rim need a curved edge to
catch; here that band is the signature, not a chrome bar. The kit's glass-plate branch and its own `outer-bevel` rule
disagree — worth reconciling in the kit.

## Pipeline findings (for the next glass look)
* **Warm renderer cache:** `slrender watch` caches wallpaper crops by `(path, rect)`. Reusing one path per look served the
  previous wallpaper for two rounds. Kit now names the path after the wallpaper / the frame time; restart the watcher if you
  edit a wallpaper file in place.
* **Lit colour leaks into glass:** `lerp(color, glass, strength)` takes `color` before any clamp, so a bright light-mode plate
  at ambient 0.86 leaked ~10% of an over-1.0 value into every pixel (6–15% clip). Light plates: ambient 0.5.
* **Accent glass needs low strength (0.3)** so the accent body carries the pixel; at 0.5 amber over a blue wallpaper is mud.
* **`_ButtonShapeParam1` (the kit's `corner`): 0 = pill, 1 = sharp rectangle.**
* `Tools/looks/flat.py diff` and `tron.py diff` report 33 identical / 15 differ **on main already** (their plates predate the
  Materials v2 glass guards); unchanged by this work.

## Not verified / next
* **Unity:** not compiled with FXC (the three backdrop shaders are small, include nothing from the widget stack, and no
  widget shader changed, but it is unverified); the C# host is not written — `UiBackdrop` must Blit the `backdropSkin` into a
  mipmapped RT and bind `_UIBackdropTex` (snippet in `Docs/Skinning/Params-Backdrop.md`). `"backdropSkin"` is a NEW key in the
  recipe's mode block; it assumes the manifest parser ignores unknown keys (unverified). Until the host reads it the look shows
  the `backdrop` texture fallback (static).
* Glass refracts the WALLPAPER only: a slider track under a handle is not magnified; `UI_SDFTogglePill` and the display wells
  have no glass term and stay opaque.
* Legibility is measured on the rack sheet's own labels and plate print tokens (printcheck); it is not a scan of every app screen.
* The dark HOVER key label has the thinnest margin (3.06:1). A "simple glass" colourway (frosted controls, no lens) and more
  wallpaper types (Bokeh-like, aurora) are cheap follow-ups: a spec field and a shader file each.
