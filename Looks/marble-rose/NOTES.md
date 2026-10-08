# Marble & Rose Gold — notes

Brief (BACKLOG.md#marble-rose): white Carrara plates with grey veins, rose-gold domed hardware, blush-pink
accents, soft daylight rig; dark mode Nero Marquina (black stone, gold veins). **Signature: stone + jewellery.**

## Design intent

Two halves, each kept honest. **Stone**: the plates are the Materials v2 `marble` texture (real image, not the
procedural Marble pattern, which renders as camouflage blotches — the owner's rejected pattern). It is tiled
very large (900 px, round 4), blurred two mips so the thin contour lines melt into a soft cloudy base, turned ~35
degrees per slab (`_PanelPatternOffset`) and stretched 3.1x so the few bold veins run as long diagonal rivers; every slab (Face / Inset / Socket / Back / Bezel) is turned differently so no two plates
show the same crop. Dark = gold veins on black: pattern colour type Gradient + mode Lerp with intensity ~2.3
(negative = vein = gold, positive = the stone's own black): only the bold veins reach gold, 1-2 per plate. Light =
plain multiplicative grey veins on white. **Jewellery**: keys, caps, skirts and slider handles are `gold.rose`
with a rosier burgundy shadow end and a cream-pink highlight end, `satin` matcap on keys/handles and `polished`
on the domed caps (reflection, not tinted plastic), a reeded (fluted + knurled) knob skirt, blush-pink enamel
accent keys set in a rose-gold chamfer, a hairline rose-gold inlay framing the Face and Inset slabs, and pads
that are gemstone cabochons (rose quartz / jade / champagne / amethyst rows from the look's own track theme
`MarbleRoseGems`) set in a rose-gold bezel. Light mode changes only the chassis (stone + the value-arc ring
colours); the rose gold is the same metal, lifted by control ambient 1.15 so it reads as pale under the high
daylight lamp as it does under the dark mode's low key lamp.

## Round 1 — the existing draft, re-rendered against CHECKLIST.md
scores: identity 4, story 5, material 3, light 3, taste 4, knobs30 6, pads 5, states 6, print 7, craft 4, glass n/a
- Saw: dark plates are plain black — the gold veining never shows (the pattern colour ramp sat on a texture at
  intensity 0.9: invisible); light plates are a topographic map (tile 240 px, thick wavy contours) and clip
  62.8 % (plate ambient 1.0 + a whitening ramp). Rose-gold keys read as chocolate leather with one hard window
  highlight; pads are dark muted lozenges.
- Knob.small 30 px reads (cap + pink arc) but the dark light-mode ring is a heavy black outline on white.
- Fix first: make the stone read as stone (texture tile/intensity/blur/rotation, pattern colour for Nero), then
  the hardware colour (rosier, lighter), then pads.

## Round 2 — stone rebuilt, hardware re-coloured
scores: identity 8, story 7, material 7, light 6, taste 7, knobs30 7, pads 6, states 6, print 8, craft 7, glass n/a
- Saw: Nero Marquina and Carrara read as real stone in one second (A/B tested six variants: procedural marble =
  blotches, texture at tile 240 = contour map, tile 420-440 + blur + 30-35 degree turn + 2.4x stretch = Carrara).
  Rose-gold keys/caps now look like metal (satin/polished matcap, cream-pink highlight, burgundy shadow). The
  rose-gold inlay hairline frames the slabs and is visible at 25 % zoom.
- Weak: light plate was grey (ambient 0.66); light hardware looked darker/browner than in dark mode; key and knob
  Hover barely differed from Normal; pads were flat muted squares; slider unfilled track vanished on black.
- Fix first: pads, light-mode ambient/value colours, hover.

## Round 3 — gems, hover, light balance
scores: identity 9, story 8, material 8, light 8, taste 8, knobs30 8, pads 8, states 7, print 8, craft 7, glass n/a
- Saw: pads are cabochon gems in rose-gold bezels (Normal / Hover pale bezel / Pressed mint glow / Disabled dim /
  Latched pink all different, also in the parts sheets); keys/knobs/slider handles light up on Hover (emissive
  0.12-0.16 on top of the lighter colour); light plate is 0.00 % clipped and reads white stone; value arcs are
  ruby on a warm-grey ring in light, pale pink on a mauve ring in dark. knob.small at 30 px: arc distinct at
  0/40/80/100 % in both modes (0 % is cap + faint ring).
- Family sheets (dark and light): the only veined black-and-gold stone with pink metal in the set; vs Gold Leaf
  it differs in material (stone texture, not lacquer), hardware hue (rose, not yellow), form (reeded caps,
  bezelled pad gems) and the veins that cross the whole plate; in light it is the only white veined stone.
- Weak: Pressed on knobs is a subtle flattening of the dome (state 7); the same hard-edged matcap "window"
  highlight repeats on every key and cap; the finest Nero hairlines still bead slightly at 1:1 (mip blur 1.0
  smooths them, not to zero).
- Fix next (not done): a second matcap tone for caps vs keys; a rose-gold inlay on Back; per-pad row hue tuning.

## Round 4 — independent critic round 1 (REVISE: material 6, taste 6, pads 6, print 6)
scores: identity 9, story 8, material 7, light 8, taste 7, knobs30 8, pads 8, states 8, print 8, craft 7, glass n/a
- Fixed what the critic saw. (1) Marble: the contour-map look came from thin, even-width veins on a 440 px tile.
  Now tile 900 px + mip blur 2.0-2.2 + stretch 3.1x + contrast 1.0 (contrast 1.3 amplified a tile-seam bead line):
  few large veins of varying width, a dominant diagonal, soft cloudy base (A/B-rendered four variants per mode at
  rack scale before choosing). Nero keeps 1-2 bright gold rivers per plate (intensity 2.7); per-slab turns are
  now -20..-46 degrees so every slab keeps the diagonal but crops differently. (2) Pad Latched = brighter fill
  (emissive 0.42) + a blush-lit bezel (bevel stops pale pink to rose), Hover = only a brightness/rim lift
  (PAD_HOVER_EM 0.2): Normal / Hover / Pressed / Disabled / Latched are five different gems in both parts sheets.
  (3) Key glyphs (ToggleBtn, Solo, Lamp, Close) are near-black mauve `#2A1418` via per-slot `_IconColor`: the
  speaker, eye, power and x are readable on the rose-gold face in both modes.
- Cheap notes also taken: pad rows rose quartz / jade / champagne / amethyst (own `MarbleRoseGems`); keys use the
  `brushed` matcap, dome 0.25, roundness 0.8 (no window wedge / bowtie; the caps keep the `polished` metal the
  critic praised, at 0.7); knob pointer is a larger dark mauve dot (0.10, small 0.14), so the specular blob at 12
  o'clock no longer reads as a pointer at 30 px; light-mode arcs/slider fill softened from raspberry to dusty rose
  `#B85670`; display wells wear a rose-gold hairline (light well is smoky mauve); dark TRACK lifted so pill tracks
  and fader wells read on black stone; display `textDim` lifted (dB OUT readable); DIS_BODY per mode (dark lighter
  so the DIS caption reads, light paler so Disabled recedes); Accent Hover/Pressed stops more distinct.
- Checked, not changed: second-row small knobs only look flat because the 270 degree arc is open at the bottom
  (the cap is a full circle at 4x; knob.small at 32 px renders round); cap luminance dark vs light measured
  117 vs 124 (the light caps are not darker), they read browner only against white stone.
- Weak: marble still repeats one 900 px crop per slab (rotated), the Back gutter shows a hot gold flare in dark;
  keys are still a little candy-glossy at the top edge; pad row hues are muted by the 0.6 tint.
- Fix first (not done): a second Nero tone on the Back gutter (quieter), a hand-tuned champagne for row 3.

## Round 5 — independent critic round 2 (REVISE, close: only print 6 failed)
scores: identity 9, story 8, material 7, light 8, taste 7, knobs30 8, pads 8, states 8, print 8, craft 7, glass n/a
- Print: every state of the glyph keys now has its own ink instead of the kit's HOT red / ON_MARK-at-0.6-emissive:
  near-black mauve `#2A1418` in Normal, Hover and Active (Active emissive 0, so no pink-on-pink wash), cream
  `#FFE9E4` in Pressed on a deeper burgundy pressed face (`BODY_LO` `#733A3F`). Measured with a scratch script
  (glyph vs face, WCAG, deliberately pessimistic on 12 px glyphs): all 28 key x state x mode cells >= 3:1; the Close x is 0.5 of the key (was 0.42). Dark `MARK_DIM` lifted to `#9E868C` with a darker `DIS_BODY`
  `#54423F` so the "DIS" caption reads on the disabled key; the C# off-glyph colours (`key.markOff/glyphOff/
  velOff`) are pinned back to `#6E3F3C` so they stay dark on the rose keys.
- Pads: pad rows now rose quartz `#F08AA2` / celadon jade `#86C9A4` / champagne `#EDCB98` / amethyst, pad tint 0.75
  (no more teal or khaki); Hover lifted (`PAD_HOVER_EM` 0.2 to 0.3) and still different from Latched's blush bezel.
- Keys: the bowtie was the domed face on a rounded-rect medial axis. Keys, chips and the scroll handle are now flat
  satin faces (dome 0) with roundness 0.9, a wider bevel (0.2) and the `brushed` matcap: one soft top highlight from
  the vertical ramp and the bright rounded chamfer (4 dome/roundness variants A/B-rendered first).
- Calmer stone: dark Face turned to -45 degrees (the clustered gold wiggles at the left edge and pad block thin out),
  Back and the pad Socket use new `marble.nero.calm` (1100 px, intensity 1.6, blur 2.8) and the light Back
  `marble.carrara.calm` (no stretch, so no wood-grain parallels); the dark pad socket and gutter track get a dim
  rose hairline / lighter `SCROLLWELL`; the light LCD well is a smoky mauve (`#3B2A30`) with the rose hairline.
- Weak: gold veins still loop in a few places on the dark Face (a property of the source texture, only the crop can
  move); keys are flat satin now, less "domed jewel" than the caps; pad Pressed mint is very pale in light mode.
- Fix first (not done): a second Nero crop source for the Face (needs a new texture layer in the Unity repo's
  `gen_materials.py`); a faint dome back on the keys via a larger roundness when the kit allows it.

## Gate (final, re-run after round 5)
`check` 0 errors, 0 warnings, 0 waived · `lookcheck.py MarbleRose` 46 skins, 0 errors, 0 warnings ·
`printcheck` 0 print pairs under 3:1 · `tests/test_basics.py` all passed · `diff` 50 identical.
Plate clip (round 5): dark worst 0.00 %, light 0.14 %. Control luminance step off the plate (rack printout): dark +98
knob / +102 knob.small / +103 key; light -88 / -91 / -89 (dark rose gold on white stone, as intended).
No shader, shared JSON, mirrored tool or other look touched; `UI_PATTERN_TEXTURE` is only used by SDFPanel plates
(already opted in), so no shader grew. Not verified: Unity compile / Play Mode (no Unity here).

## Kit gaps (worked around in the spec, kit untouched)
- `resolve_material` turns an inline `tint` into the BASE colour, so pattern-colour stops (gold veins) cannot be
  passed inline: the stone presets `marble.nero`, `marble.nero.quiet`, `marble.carrara(.quiet)` are registered
  spec-locally by mutating `lookkit.MATERIALS` at import.
- No pattern rotation in a preset: used `modes[mode]["set"][slot]["_PanelPatternOffset"]` (works, validated).
- An `edge` given as a preset NAME reuses that preset's BODY ramp (dark to light, which draws a bezel dark at the
  top on RM keys/pads); an `edge` dict `{"preset": ..., "ramp": (bright..dark)}` is needed for a lit bezel.
- A palette token (`BODY`, `CAP`, ...) beats the preset's `base`, so recolouring a preset means changing the
  palette token plus the preset's `lo`/`hi`; `AMB_PLATE` explicit beats a preset's `plate_amb`.
- Hover emissive for knobs/faders/keys is a spec `shape["states"]` delta (the kit's own Hover is a 6 % recolour).

## Known issues
- Carrara is warm grey-white (~#D8D5D0 mean) rather than paper white: the < 1 % clip rule caps plate ambient.
- Light-mode value colours differ from dark (ruby `VALUE`, warm-grey `ARC_OFF`/`TRACK`); these are not in the
  kit's control-token waiver list and are chosen so the arc reads on white stone (reviewed, no waiver needed).
- Dot/ScrollHandle stay on the dark `SCROLL` token in light mode (chocolate bars on white), as in dark mode.
- Gold veins pass behind print in dark mode; `printcheck` measures plate colour, not the vein pixels.
- The second-row small knobs in the rack look flat at the bottom only because the 270 degree arc is open there; the
  cap is a full circle (checked at 4x, and in the knob.small 30 px strip) - not a quad clip.
- Both modes share one track theme (`MarbleRoseGems`, dark highway with rose-gold rails).

## Independent critic verdicts (Opus, fixed Looks/CHECKLIST.md)

### Critic round 1
```
round 1 — REVISE
scores: identity 8, story 7, material 6, light 7, taste 6, knobs30 7, pads 6, states 7, print 6, craft 7, glass n/a
evidence:
identity: At thumbnail next to the family sheet, the dark rack is black stone with gold veins, pink-copper hardware and blush LCD text and arcs. Gold Leaf and Ice Cold have yellow-gold knobs on plain charcoal, so this look differs in both material and palette. No other look has a white-marble light mode.
story: Rose gold is used on every knob, key, slider thumb and pad rim, every plate has a thin rose inlay, and all hardware shares one drop-shadow style. Two things sit outside the stone-and-jewellery world: the teal and ochre pad rows, and the LCD screens, which are bare black slabs.
material: The rose-gold knobs read as real metal (moving specular highlight, knurled skirt). The flat keys look like lacquer instead: Button Normal has a bowtie crease and Accent, Chip and ScrollHandle have a hard diagonal highlight wedge. The marble looks printed, not polished stone. In light mode it is a network of even-width grey contour lines forming closed cells, and in dark mode the gold veins are squiggles spread evenly over every plate.
light: The chassis switches to white marble with grey veins and the plates are not clipped (about #E0). Keys keep their rose gold. But the knob arcs and slider fill change from blush to hot raspberry, and the knob domes render darker than in dark mode, so some controls change between modes.
taste: The rose-gold hardware is close to the owner's bar. The busy contour-line marble in dark mode, the clashing teal and ochre pads and the glossy, candy-like keys keep it well below Realistic Dark. It avoids the rejected camouflage-blotch marble but does not read as Carrara either.
knobs30: In both modes the dome separates clearly from the plate, and the arc separates 0, 40, 80 and 100 % (blush on a dark-mauve track in dark mode, crimson on grey in light mode). The face pointer is not visible at 30 px, and a white specular blob at 12 o'clock looks like a pointer stuck at 50 %.
pads: Normal, Pressed (bright mint with a cream rim) and Disabled are clearly different, and pads stand off the plate in both modes. In both parts sheets Hover and Latched have nearly the same mid-teal fill and differ only in rim tone.
states: Button, ToggleBtn, Solo, Lamp, Close and Chip all show a lighter Hover, a darker red-mauve Pressed, a dark Disabled and a blush or peach Active. Accent Pressed looks almost the same as Normal in dark mode. In light mode the Disabled keys are darker than Normal, so they stand out instead of receding.
print: Captions are readable in both modes (0%/40%, MASTER, FADER 62 %, PADS…, A01 KICK), and the dark-mauve key words (PLAY, KEY, LEARN) read on rose gold. The Close × cannot be seen in Normal or Hover. The speaker, eye and power glyphs on ToggleBtn, Solo and Lamp are faint, and "DIS" and "dB OUT" are close to unreadable.
craft: Plates are clean: thin rose inlay, no wedges, lip seams or clipped glows, and the veins are smooth at 1:1. Smaller problems: in dark mode the pill tracks and fader wells nearly disappear on black marble, and the pad block's backing is a flat black slab.
glass: n/a
since last round: first round
fix first (max 3, concrete, with the spec field to change):
1. Marble plate pattern (Face/Inset/Back/Socket texture scale and intensity; dark-mode pattern colour). Make the veins fewer and larger, vary their width, give them a dominant diagonal drift and add a soft cloudy base tone, so it reads as Carrara and not a contour map. In dark mode cut vein density to about half and keep only 1–2 bright gold major veins per plate, so it looks like polished Nero Marquina and the rack is less busy.
2. Pad Latched vs Hover (Pad states.Latched fill and glow). Give Latched its own look, such as an inner blush ring or glow, or a clearly brighter fill. Keep Hover to a rim and brightness lift only.
3. Key glyph colour on ToggleBtn, Solo, Lamp and Close, in both modes. Darken the glyphs to a near-black mauve ink, or make them engraved, so the Close × and the speaker, eye and power glyphs reach 3:1 against the specular rose-gold face.
notes (not scored): The teal and ochre pad rows clash with the blush and rose palette; jade and champagne tints would sit better. The hot-raspberry arcs in light mode drift away from the brief's blush. The LCD wells are stark black boxes on white marble; a rose-gold bezel or smoky well would bring them into the story. The keys' matcap creates a bowtie crease and hard diagonal wedges, which makes them read as candy plastic; a softer, rounder highlight would read more like jewellery. At 1:1 the second-row small knobs in the rack look flattened at the bottom; verify this is not a quad clip. Light-mode knob domes are noticeably browner and darker than in dark mode, so check the rig and environment balance.
```

### Critic round 2
```
round 2 — REVISE
scores: identity 8, story 7, material 7, light 8, taste 7, knobs30 8, pads 7, states 8, print 6, craft 7, glass n/a
evidence:
identity: At thumbnail next to the base family and the two new looks (Synthwave, Carbon Race), the dark rack reads as black stone with gold veins plus rose-copper knobs and blush arcs. It differs from all of them in material (stone), palette (rose/blush) and lighting, and no other look has a white-marble light mode.
story: Rose gold is used on every knob, key, slider thumb, pad rim and plate inlay, all with one drop-shadow style, and the LCD wells now have a rose border and blush digits. The teal pad row, and to a lesser degree the khaki row, still sit outside the stone-and-jewellery world.
material: The marble is much better. Dark mode has a few large diagonal gold veins of varying width on black, which reads as polished black-and-gold stone. Light mode has diagonal grey veins over a soft cloudy base, and the parts-light plates look like real stone. The rose-gold knobs keep a moving highlight. The flat keys still show a bowtie crease (Button, Chip, ScrollHandle), so they read as glossy lacquer, not metal.
light: Only the chassis changes to white marble, and the plates are not clipped (about #E4). Knob domes now look the same as in dark mode (30 px strip, KnobHero row). Keys keep their rose gold. Knob arcs and slider fill change from pale blush to a deeper rose pink of the same hue, which is a reasonable contrast change, not a control swap.
taste: The dark rack now looks like a luxury object (black stone, gold veins, jewellery knobs) and avoids the rejected camouflage-blotch marble. The candy-gloss keys and the teal pad row still keep it below Realistic Dark.
knobs30: In both modes the dome separates clearly from the plate, the arc separates 0, 40, 80 and 100 % (blush on dark-mauve track / rose on grey track), and the dark pointer dot is now visible at 7, 11, 2 and 5 o'clock. The white specular wedge at 1 o'clock still competes a little.
pads: Latched now has its own white-blush inner ring and a brighter fill, so it is distinct from Hover. Pressed is bright mint with a cream rim and Disabled is dark (grey-beige in light mode), and pads stand off the plate in both modes. Hover is only a small fill and rim lift over Normal.
states: Every key shows a distinct Hover (lighter), Pressed (deeper red-mauve), Disabled and Active (blush, peach or pale pink). Accent Pressed is now a clearly deeper raspberry than Normal. Light-mode Disabled keys recede to grey-taupe or pale instead of darker.
print: Captions and key words read in both modes (0%/40%, MASTER, FADER 62 %, A01 KICK, PLAY, KEY, LEARN, "dB OUT"), and Normal-state glyphs are now dark and legible. Still under 3:1: the Close × in Hover (pink on pale rose) and Pressed (red on red-mauve), the pink glyphs on the pink Active ToggleBtn and Solo, and "DIS" in dark mode.
craft: Plates are clean: thin rose inlay, no wedges, chrome bars, lip seams or clipped glows, and the veins are smooth at sheet scale. Still present: the dark-mode pad block backing is a flat black slab, and the dark-mode ScrollTrack and fader wells nearly disappear on black.
glass: n/a
since last round: Improved: material 6→7 (the marble now reads as polished stone in both modes), light 7→8 (knob domes match between modes), taste 6→7, knobs30 7→8 (pointer dot now visible), pads 6→7 (Latched is distinct), states 7→8 (Accent Pressed and light-mode Disabled fixed). Print stays at 6: Normal glyphs are fixed but Close Hover/Pressed and the Active glyphs still fail. Identity, story and craft unchanged. No regressions.
fix first (max 3, concrete, with the spec field to change):
1. Close glyph colour in Hover and Pressed, and the ToggleBtn and Solo Active glyph colour, in both modes. Use the same near-black mauve ink as Normal, or cream with a dark edge on the red Pressed face, so each reaches 3:1. Also raise the dark-mode Button Disabled label colour (DIS) to about #9A8088 if printcheck counts disabled text.
2. Pad palette rows (pad track theme). Replace teal with jade-celadon and khaki with champagne, so all three rows belong to the rose-gold and stone world. Add about 8 % value to the Hover fill so Hover is clearer.
3. Key matcap and highlight shape on Button, Chip, ScrollHandle and Accent. Replace the bowtie crease with one soft rounded top highlight, so the keys read as polished jewellery and not candy lacquer.
notes (not scored): In dark mode a few gold veins form bright wiggly clusters (right edge of the pad block, bottom strip, left edge near y 300) that look like lightning or rivers; smoothing those would make the stone calmer. The light-mode bottom bar's veins wave in parallel like wood grain. In light mode the LCD wells are still near-black aubergine slabs on white marble; a smoky rose-tinted well would sit better. In the rack, the second-row small knobs still look flattened at the bottom. I cannot zoom to confirm, so please verify this is not a quad clip.
```

### Critic round 3
```
round 3 — PASS
scores: identity 8, story 8, material 8, light 8, taste 7, knobs30 8, pads 8, states 8, print 7, craft 7, glass n/a
since last round: Improved: story 7→8 (the teal row is now jade and the khaki row sand/champagne), material 7→8 (the bowtie crease on the keys is gone), pads 7→8 (Hover lift is clear), print 6→7 (Close Hover/Pressed and the Active glyphs fixed). Unchanged: identity 8, light 8, taste 7, knobs30 8, states 8, craft 7. No regressions in score.
fix first (not required for PASS): 1) Disabled-state glyph colour on Close, Lamp, ToggleBtn and Solo is invisible on the grey-taupe face in light mode (~#7A6A70 light, ~#8A7A80 dark). 2) Desaturate the Pressed pad mint toward celadon (~#B8DCC8) and keep Hover one clear step below Latched in fill. 3) Calm the bright wiggly gold vein clusters on the dark plates (left edge near y 150/300, right of the pad block, bottom strip).
notes (not scored): Hover pads moved close to Latched in fill (rim colour carries the difference); light-mode pad backing is a flat grey slab; light-mode LCD wells near-black aubergine on white marble (a smoky rose well would sit better); light-mode veins uniform-width wavy lines like contour lines; the second-row small knobs "look flat at the bottom" in the racks — foreman checked a 3x crop: they are complete circles, the value arc is simply open at the bottom (270° arc), not a quad clip.
```
