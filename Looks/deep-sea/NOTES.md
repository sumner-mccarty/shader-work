# Bioluminescent (deep-sea) — notes

Neon class (unlit tubes). Identity: abyss-BLUE lit water plates (not black glass), round bell/orb forms (capsule keys,
circular lamp/dot/knobs), cyan->violet tubes with a wide soft glow, plankton-cell Voronoi lattice on plates, Caustics
wallpaper in the gaps, ONE warm note (coral: knob nucleus, arc tip, HOT, close). Light = sunlit lagoon chassis
(seafoam/white sand, white caustics); controls unchanged dark-water organisms. Fields: accent = Splotch (jellyfish
glows), menu = Bokeh (plankton motes), both calm and dim for print.

## Round 1
Sheet: plates read as saturated mid-blue, flat; closest family neighbour is Clearwater (blue) though that one is glass.
round 1 — REVISE
scores: identity 7, story 8, material 6, light 8, taste 6, knobs30 7, pads 7, states 7, print 8, craft 7, glass n/a
fix first: darken plates so organisms glow (FACE ramp), light Inset clip 11%, light Face clip.

## Round 2
Darkened FACE/BACK ramps (abyss navy bottom -> deep teal top); light INSET/FACE_TOP lowered (Inset clip 11% -> 0%).
Tried FACE_SHEEN 0.12: washed the plate flat blue with wedge look -> rejected, back to 0.03.
round 2 — REVISE
scores: identity 8, story 8, material 7, light 8, taste 7, knobs30 7, pads 7, states 7, print 8, craft 7, glass n/a
since last: plates deeper, organisms pop; Inset clip fixed.
fix first: light caustic lines clipping near plate edges (Face 1.7%), knob 30 px check.

## Round 3
Light caustics toned (LineStrength 0.85->0.38, pale-sand pool dimmer): Face clip 1.69 -> 1.17. knob-small at 30 px:
value arc, coral nucleus and cap ring separate from plate in both modes (sheets/knob-small-30.png: 0/40/80/100%).
round 3 — PASS (self-score)
scores: identity 8, story 8, material 7, light 8, taste 7, knobs30 8, pads 7, states 7, print 8 (printcheck 0 pairs <3:1), craft 7, glass n/a

## Round 4 (after critic round 1: identity 6, material 5, craft 5 - "Tron in a navy jacket")
Changes: every key/pad/knob body is now a RADIAL gradient (cyan core -> abyss navy rim), so controls read lit from
inside; the tube is a thin skin (0.06 vs 0.1), keys are pure capsules/circles, pads near-circular cells; Latched pad and
Lamp ON flood a bright mint core (halo itself cannot exceed the footprint quad, so the glow lives in the fill);
plate lattice stronger (Face 0.55 / contrast 2.2 / scale 4) and readable at 25%; sheen band removed from keys (it was
the inner bar/slot ghost); knob cap ring dimmed to a track colour (0% shows no bright ring), pointer now near-white;
Close/Dot hover lift the fill and take a full-cyan rim; pad Hover/Pressed swell the core; Face halo removed and the
caustic pool/lines dimmed (the "glow band" under the plate was the wallpaper pool in the gap, not a plate bloom);
controls now identical in both modes (shared CTRL tokens, dark disabled parts); light Face clip 0.52%.
Arc glow width widened (0.001 -> 0.03) to calm the speckled glow edge.
round 4 — self-score: identity 7, story 8, material 7, light 8, taste 7, knobs30 8, pads 8, states 8, print 9, craft 7
fix next: more blobby silhouettes need a shader feature (keys are still pills); dark Face clip 1.16%.

## Round 5 (after critic round 2: identity 7, material 6, light 6, craft 6)
Changes: Face/Back lattice softened to real caustics (scale 2.2, contrast 1.1, intensity 0.3 - quiet behind controls,
still visible at 25%); knob caps now a lit cyan core with radial glow (same family as pads); pad/key rims are
row/glow coloured (PAD_LINE cyan, tint 1.0, no white), thinner and slightly soft (width 0.045, softness 0.12 -
softness 0.45 was tried and turned rims into fat slabs); Close now has a body in both modes (dark-body fill in light);
Disabled pad = dimmed navy body (no grey-teal wash); arc end is a solid violet (no 4th-stop shimmer) and the arc glow
is lower (0.8 -> 0.6) so knob Hover is lighter; dark Inset and Socket get a radial ambient glow + faint lattice;
light key/pad rim emissive cut; handle/pointer/hover-ring whites softened.
Light Face clip stays 0.51%: the clipped pixels are the sheet's white key labels and hover ring edges on the plate
region (located by pixel scan), not the plate or the wallpaper (wallpaper lines off = 0.49%).
round 5 — self-score: identity 7, story 8, material 7, light 7, taste 7, knobs30 8, pads 8, states 8, print 9, craft 7
fix next: identity needs a silhouette idea beyond pills; light Face clip 0.5% from labels.

## Known weaknesses
* Light Face clip now 0.52%; dark Face 1.16% (rule applies to light); Well 2.0% is the bright display text, expected.
* Silhouettes are still pills/circles - truly blobby shapes are not available to neon keys.
* Bottom transport segment tiles and parts-light background not reworked (optional notes).
* No true material conviction beyond emissive tubes (neon class has no lit materials).
* Dark plate blue is still the nearest relative of Clearwater; tubes + capsule keys + lamp orbs are what separate them.
* Light-mode cap ring and arc fill are both cyan at 30 px (merge slightly at 100%).
* lookcheck warns: Dot has no Disabled state, Pill no Pressed (kit class defaults).

---
## Independent critic verdicts (Opus, CHECKLIST.md scoring) — NOT ACCEPTED (batch stopped; status "draft")

| round | identity | story | material | light | taste | knobs30 | pads | states | print | craft |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 6 | 7 | 5 | 7 | 5 | 6 | 7 | 6 | 9 | 5 |
| 2 | 7 | 7 | 6 | 6 | 6 | 7 | 8 | 7 | 9 | 6 |
| 3 | 7 | 8 | 7 | 6 | 6 | 7 | 8 | 8 | 9 | 6 |

Batch stop rule fired (2 rejections in a row) before this look's 3rd revision was judged/continued, so it was not run to the end.
Round-3 open items: soft caustics are invisible now (identity gap vs Tron: needs larger, ~1.5x-contrast cyan caustic cells on
Face/Inset/Socket, and organic/lobed pad cores); light-mode Face clips 0.51% (needs 0) and light knob tracks are near-black wire
rings; value-arc outer edge stair-steps and the 40% arc end is cut square. Strongest parts: radial-core pads and knobs, state
separation. Not shipped: Assets/Resources files not committed — `python Tools/looks/deep_sea.py write` regenerates them.
