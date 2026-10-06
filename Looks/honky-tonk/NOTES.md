# Honky-Tonk Neon (neon, unlit)

Brief: a roadhouse at midnight - neon tubes in pink, mint and amber over dark weathered wood
(WoodGrain, very low intensity, behind the tubes), chickenhead dial pointers as bent neon. Light mode:
daytime sign in sun-bleached paint with unlit glass tubes. Signature: warm bar neon on wood, not
cyber-blue.

Spec: `Tools/looks/honky_tonk.py` (kit class `neon`, prefix `HonkyTonk`, track theme `HonkyTonk` defined in the spec).

## Design
* Tubes run pink -> coral -> amber left to right (Tron runs cyan -> pink). Mint is the "on" colour
  (accent keys, pad row 2), amber the lamp/solo colour, pink the hot/mute colour. No blue anywhere.
* Boards: FACE/BACK/INSET carry a pixel-locked WoodGrain (`set` hook, mode-dependent via a small
  `Look.S` override in the spec): 0.36 intensity on near-black brown in dark, 0.022 on bleached paint in light.
* Chickenhead: knob cap shape 8, rotated 270 deg so the lug points at the value, outlined by the
  unlit bevel band in the tube colour (KnobBevel, distance 0.05) - a bent tube following the lug. The
  cream bulb (KnobNub) rides the lug, the pink cap ring is kept as the bezel tube.
* Light: same black-glass controls (chassis changes, not hardware); plates become cream/tan paint; tubes
  are pigment only - `_BorderRenderEmissive 0`, edge bloom off on keys/plates/pill/cap ring, halo 0,
  ARC_EMIT 0 - so the sign reads as switched off in daylight. Controls still show their ON colours.

## Round 1 (first sheets) - critique
* Identity: warm outlines on brown read at once and differ from Tron (blue/cyan) - good. Wood was
  invisible in dark (0.16) and swirled like marbling in light (0.16 at scale 6) - worst problem.
* Craft: chickenhead cap was a dark blob; pointer rotation 180 deg off the value (lug and nub disagreed);
  first outline attempt (bevel 0.16) filled the whole cap pink.
* Light: tubes still looked like pastel bloom (additive emissive on pale paint).
* Fix first: chickenhead + light glass.

## Round 2
* Chickenhead: bevel 0.05 -> a clean bent outline; `_KnobShapeRotation` 270 aligns lug, nub and arc at
  0/10/50/90/100%. Cap radius 0.66 (cap_r) so the head is big enough at 36 px.
* Light tubes -> unlit glass via `GLASS` overrides (emissive 0, no Edge); LINE 1.3. Reads as painted
  glass on bleached boards. Wood in light 0.022 / scale 4 - still faintly contoured, intentional.
* Remaining: dark wood barely visible at 25% zoom; face colour a touch dull.

## Round 3
* Dark wood 0.36 on FACE #22140C -> #372113: grain reads on the rack at 25% zoom (family contact sheet).
* Family check against boom-box, candy-cane, flat, gold-leaf, graffiti, ice-cold, marble-rose, rodeo,
  tron, walnut-brass: only Rodeo shares the brown value range; it is lit leather with turquoise
  conchos, this is unlit outline-glow with pink/amber/mint. Unmistakable.
* printcheck: light-mode INK_DIM darkened (#48301F), `key.label` and `display.textDim` set for the dark
  keys / dark wells -> 0 pairs under 3:1.

## Rubric (final)
1. Identity: strong - glowing pink/amber outlines, mint on, wood. Differs from every shipped/other look in lighting class + palette + form.
2. One material story: tubes on boards everywhere; one tube weight per class of part.
3. Legibility: knob.small at 30 px - 0/40/80/100% distinct (arc fill + bulb), though the cap ring and the
   lug merge into a busy double ring at 30 px (known). ON/OFF obvious: mint/pink/amber fills.
4. Craft: no plate bevel/dome, lip 0 n/a (unlit), px-locked patterns, arcs <= 0.88. Pads: outline colour
   comes from the row (padColor), fine.
5. States: Hover/Pressed/Disabled/Active differ on keys, knobs, faders, pill. Dot has no Disabled and
   Pill no Pressed (kit parity with Tron).
6. Light = chassis: BODY/CAP/ACCENT unchanged; tubes dull instead of bright.
7. Fidelity: pink/mint/amber tubes, wood, chickenhead as bent neon, unlit daytime sign - all present.

## Known issues
* Rings from WoodGrain are quarter-circle arcs from a UV corner (shader quirk); in light mode they read
  slightly like contour lines on the large Face. A straight-plank vocabulary would need a shader change.
* Light-mode wood and pad row colours are not independent of palette tokens (set hook is per slot).
* Slider fill in light has gradient pink -> amber that is dim on tan; legible but low drama (as intended).
* Could not verify in Unity (FXC) or the real app; judged from slrender renders only.

## Revision round (critic: REVISE) - critique
* Wood: dark intensity 0.36 -> 0.10, light 0.022 -> 0.008; scale 3, px 600, ring spacing 0.2, wander and knot terms 0
  (no bullseye / moire rings). A whisper in dark.
* Lit tubes: kit `lit()` overridden (subclass `HTNeon` in the spec): pressed/active = bright tube border + glow in the
  state colour, fill only a 65% dark tint of it (pale tint in light). Accent keys rest as mint tubes with a dark mint tint
  (no solid slabs). Button/Chip/latch Hover also lifts the fill and glow; pad Pressed uses a short sheen (no grey block),
  pad Disabled is thinner, dimmer, emissive 0. Scroll handles/dots are dark bodies with real tubes; zoom fader fill is the ARC gradient.
* Chickenhead: length 1.0, width 0.28 - a long pointer reaching past the cap, bevel-band outlined with a soft inner glow;
  cap ring thinner (0.6 px) and dimmer so the pointer is the hero. Verified at 30 px (0/40/80/100% distinct).
* Light = the same sign switched off: dark-mode geometry kept; pale painted key/cap faces, desaturated pink/mint/amber
  tubes, no emissive, no bloom (pads included), darker MARK_DIM and raised disabled contrast. Control-luminance rule
  waived for BODY and CAP (reasons in the spec); screens (Well/Bezel) stay dark glass.
* Distinct from Tron: chickenhead pointer, mixed tube colours per part, warm wood, glow halo; lit-tube states.
* Known: pad cores still pick up the track row tint (cool-ish on the mint row); light Face shows faint diagonal streaks; display wells in light remain dark.

## Revision round 2 (final) - critique
* Not-Tron: no chamfers anywhere - keys, pads and plates are soft rounded tube bends (shape 0, low corner param, plate
  radius pinned in px). Pads are lit warm glass faces (row colour tinted into the face, no sheen, no inner frame) with a thin
  row-coloured tube; Hover = thicker tube + glow + lifted face, Pressed = brighter filled face, Latched = fill + glow,
  Disabled = dim, thin, emissive 0, alpha 0.2.
* Chickenhead: wide, filleted pointer (width 0.5, blend 0.45) in MINT over a pink cap ring and an amber/pink arc; KnobHero
  loses its bracket arcs (one tick ring left). Arc track lifted (#5A3524) so it shows on wood at 30 px.
* Accent keys: dark mint tint (86%) with a plain mint tube - no teal slab.
* Wood: Face/Back 0.18, Inset 0.08 (dark); 0.016 / 0.008 (light). Visible between tubes at 1:1, still a whisper.
* Light: slider Disabled track no longer brightens (explicit muted track + border emissive 0); pads Pressed/Hover/Latched
  differ by tube weight (no emissive in daylight), Disabled is a flat tan; no white pad blocks.
* Known: dark pad rows still read fairly saturated at 25% zoom; light-mode screens stay dark glass; mint row tint cool-ish.

## Factory verdict — REJECTED after 2 revision rounds (2026-10-06)

Final critic (fresh, Opus): identity 6, one-material-story 7, legibility 6, craft 6, states 6, light-mode 7, theme-fidelity 6 -> REVISE.
Unapplied fixes (revision budget spent):
1. Wood still reads as plain brown-black at 1:1 in dark (raise WoodGrain ~2x, warmer red mid-tone); knob pointer reads as a magnifying glass — needs a tapered chickenhead, two neon colours per knob not three.
2. Pad glow clips at quad bounds (chamfer-looking corners, square glow edges in light); dark Accent PLAY ink is near-black on dark teal (unreadable).
3. Pad Normal/Hover/Pressed/Latched nearly identical in dark; Button Normal vs Hover differ only in rim hue; Toggle Normal and Active both pink.
Also: light-mode wood renders as diagonal satin bands (fabric sheen); 0% track on small knob faint.
Strengths: pink/mint/amber on warm brown is clearly bar neon, not cyber-blue; amber->pink arcs and amber 7-seg displays good. Weakness: shares neon class and thin-rim language with Tron, so only palette separates it.
