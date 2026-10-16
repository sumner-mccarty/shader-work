# Lunar Red — notes

Concept: vermilion lacquer plates (soft sheen to the top), gold coin knobs (fluted milled rim, domed polished-gold
face, squircle "square hole" mark in lacquer red), red keys with gold chamfers, jade for ON (accent key, value arc,
switch, lamp). Cloud-scroll = Contours menu field (gold lines on deep red); Ribbons accent field in red/gold/jade.
Pads take the Velvet track palette (rose / jade / amber rows). Light mode: rice-paper chassis, same red/gold/jade hardware.
Lattice cue: HexGrid and BrushedCross plate patterns were tried and rejected (see round 2); not present.

## Round 1
Findings: plates read dusty maroon (preset lo/hi pull toward grey); gold cap OK but plate has no lacquer feel.
Verdict: round 1 — REVISE
scores: identity 6, story 8, material 6, light 7, taste 6, knobs30 8, pads 7, states 8, print 8, craft 8, glass n/a
fix first: plate preset lo/hi to red-orange sheen, brighter FACE.

## Round 2
Changes: plate lo #260105 / hi #FF5440, FACE #8E0F17. Lattice attempts: BrushedCross read as diagonal scratches;
HexGrid at 22% left a hard vertical cell seam. Both dropped (clean lacquer chosen).
round 2 — REVISE
scores: identity 8, story 8, material 7, light 7, taste 7, knobs30 8, pads 7, states 8, print 8, craft 7, glass n/a
fix first: slider handle read blackish (raise handle amb), lattice cue absent (accept; coin + jade carry it).

## Round 3
Changes: pattern removed, handle amb 0.95, value arc #3EDC96 (more green, less cyan), light chassis checked
(clip 0.0%, controls unchanged), family contact checked: only Sweetheart/Candy Cane share a red plate, but they are
crimson-pink with silver/white hardware; Lunar Red is vermilion + gold + jade.
round 3 — PASS (self-scored)
scores: identity 8, story 8, material 8, light 7, taste 7, knobs30 8, pads 7, states 8, print 9, craft 8, glass n/a
Metrics: dark clip 0.0%; knob dL +51, small +75, hero +45, key +27, latch +85. Light clip 0.0%.
knob.small 30x30 at 0/40/80/100%: sheets/knob-small-30.png (value arc legible, gold separates from plate).
Waivers: none. Not verified: Unity / Play Mode.
Known weaknesses: red keys on red plate rely on the gold chamfer (dL 27); no literal lattice; light-mode identity
is quieter (cream chassis); gold cap leans slightly olive in shadow.

## Round 4 (answers critic round 1: identity 6, story 7, material 6, light 8, taste 5, knobs30 7, pads 6, states 7, print 9, craft 6)
Changes:
- Motif: plates carry a px-locked key-fret lattice (Fabric weave, 16 px cells, low intensity) coloured through a
  plate-red -> gold palette (Face/Back/Inset, per mode via `modes[mode]["set"]`), plus a thin gold inlay line round
  every plate (`plate.stitch`). Hero knob wears a ring of lacquer-red beads round the coin; pointer is now black
  (`NUB #120405`, hero size 0.1). Perforated/Weave/Dots/HexGrid/BrushedCross were compared; only the weave
  reads as lattice without scratching or seaming. Honest limit: at 1:1 the lattice is subtle texture, not a drawn fret.
- Lacquer: plate ramp deeper (oxblood #1A0003 -> vermilion #FF5A3C, ramp 0.38/0.42), spec 1.2 / rough 0.02.
  Inset #380509 and Socket #240305 now clearly darker and recessed (rim -0.45) than Face #8E0F17.
  Tracks: TRACK #0E0905 and ARC_OFF #2B1A0A (gold-black ink) so slider/arc tracks read on red.
- Jade: ACCENT #2F8F6A, VALUE/LAMP #3FB088 (no more mint/cyan); accent keys are ceramic + pearl matcap (milky stone)
  with a gold chamfer. Own track theme `LunarLacquer` (vermilion / jade / gold-leaf / crimson rows) in both modes;
  pad hover/press emissive 0.32/0.6 for wider Normal -> Hover -> Latched deltas.
- knob-small-30.png now renders 0/40/80/100% on the ACTUAL Face colour (top row) and the Inset it sits on (bottom row).
Self-score: identity 7, story 8, material 7, light 8, taste 7, knobs30 8, pads 8, states 8, print 9, craft 8, glass n/a
Metrics: clip 0.0% both modes; dark dL knob +72, small +84, hero +34, key +30. printcheck 0 pairs; lookcheck 0 errors.
Known: lattice is subtle at 1:1; light-mode inset reads slightly muddy rose-grey; gold cap leans olive in shadow.

## Round 5 (answers critic round 2: identity 6, story 7, material 7, light 7, taste 6, knobs30 7, pads 6, states 7, print 9, craft 7)
Changes:
- Identity: the weave is gone. Face/Back now carry a px-locked GOLD diamond window-lattice (DiamondPlate, 28 px
  pitch, intensity 0.8) — the pattern colour palette is a 4-stop plate-red,plate-red,gold,gold ramp so only the
  pattern highs turn gold (a 2-stop ramp never reached gold; this was the missing trick). Reads at 25% as a
  gold trellis on red. Gold inlay line kept. Bead ring now on every large knob (Knob + Hero, lacquer-red beads on the
  gold coin rim), hero square-hole pointer 0.12. Keys are now deep oxblood lacquer with gold chamfers so they
  separate from the brighter vermilion plate and read differently from Candy Cane's candy red/white.
  No lookkit change was needed (only `modes[...]["set"]`); lookkit.py, flat.py, tron.py are untouched, so their
  `diff` output is unchanged by this work (flat/tron `diff` print "15 differ" on this checkout regardless of my files).
- Material: per-plate 4-stop clear-coat gradient (deep foot, saturated body, soft bright band at the top third, back to
  body red) on Face/Back/Inset/Socket; Inset/Socket/Bezel are separate materials without the lattice (the
  lattice on the display bezel produced zig-zag edges and a 29% light-mode clip before this was fixed).
- Value/pads: VALUE #3E9E78 (jade), LAMP/highlight #58B890; pad Hover emissive 0.5 (clearly lighter), Latched adds a
  gold rim (Border, emissive) + glow, Disabled is flat and desaturated (alpha 0.7 dark / 0.8 light, bevel 0) so the
  light-mode gold row no longer smears to beige. Light-mode Inset/Socket/Bezel retinted warm rice-paper/cinnabar.
- knob-small-30.png re-rendered on the real Face and Inset colours.
Self-score: identity 7, story 8, material 7, light 8, taste 7, knobs30 8, pads 8, states 8, print 9, craft 8, glass n/a
Metrics: clip 0.0% every plate both modes. printcheck 0 pairs; lookcheck 0 errors; test_basics passes.
Known: hero knob mean dL vs the gold-lattice Face is small (4) — it separates by its shadow, dark bead ring and arc,
not by luminance; display bezel has no gold frame; pill Hover ~ On not addressed.

## Round 6 (answers critic round 3: identity 7, story 7, material 7, light 8, taste 7, knobs30 8, pads 7, states 7, print 9, craft 7)
Changes:
- Identity: the lattice is now real gold inlay, not tinted red. Pattern palette mode 0 (replace) with dark ground /
  shadow gold #8A5A1C / highlight gold #D8A848, DiamondPlate 28 px pitch, intensity 1 contrast 2. An InnerFrame layer
  of plain clear-coat lacquer (size 0.9) covers the Face interior, so the lattice shows only as a gold frieze band
  (~23 px on the sheet's 470 px plate) round the edge, inside the gold inlay line — visible at 25%. Back plates are
  plain lacquer again (their lattice vanished in light mode). Light mode: same frieze in darker antique gold on rice
  paper (gold lowered to stop the highlight clipping: 4.9% -> 0.0%). Caveat: InnerFrame size is proportional to the
  plate's short side, so the band is ~12 px on a 230 px module plate and wider on a big one; the sheet plate is the large case.
- Lacquer: Face stops #6E0E0E (foot) / #A8141C / #EE5238 (bright soft band at the top third) / #B0161C; Inset foot lifted
  slightly, band #7A241C.
- States: pad Pressed emissive 0.3 (jade ~#3FAF82 instead of mint), hover 0.4; pad Latched ring is a gold gradient
  Border (#7A5410 / #F2CC66 / #A87A22) with glow; Solo fill #CF9A26 with low emissive and a dark-gold rim on Active
  (no lemon yellow). Bead ring dropped from the 56 px knob (kept on KnobHero).
Self-score: identity 8, story 8, material 7, light 8, taste 7, knobs30 8, pads 8, states 8, print 9, craft 7, glass n/a
Metrics: clip 0.0% every plate, both modes. printcheck 0; lookcheck 0 errors; test_basics passes.
Known: frieze overlaps the sheet's controls by a few px (the sheet places content at fixed offsets; the app pads content
past the plate); the frieze is a diamond trellis, not a literal meander; display bezel has no gold frame.

---
## Independent critic verdicts (Opus, CHECKLIST.md scoring) — REJECTED after 3 revision rounds

| round | identity | story | material | light | taste | knobs30 | pads | states | print | craft |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 6 | 7 | 6 | 8 | 5 | 7 | 6 | 7 | 9 | 6 |
| 2 | 6 | 7 | 7 | 7 | 6 | 7 | 6 | 7 | 9 | 7 |
| 3 | 7 | 7 | 7 | 8 | 7 | 8 | 7 | 7 | 9 | 7 |
| 4 (final) | 7 | 8 | 7 | 8 | 7 | 8 | 7 | 7 | 9 | 6 |

Final blockers (round 4): **identity 7** (needs 8) — the Face frieze is a diamond/harlequin band that reads carnival/argyle,
not Lunar New Year; no single unmistakable holiday sign (key-fret / meander / lantern medallion / cloud scroll). Frieze gold sits
orange (~#D8902C) not gold leaf. **craft 6** — the frieze is wider than the layout's gutter, so the dB display, pad plate and close
button cover it in three places. Pad Hover vs Normal nearly identical in the rack's red pad row.
What worked: gold hero knobs with red bead ring (the strongest element, a real moving highlight), jade ON, gold inlay line,
lacquer-ish top band, light mode (rice-paper chassis, controls unchanged, 0% clip), distinct from Candy Cane.
Not shipped: Assets/Resources files were not committed. Regenerate with `python Tools/looks/lunar_red.py write`.
Next time: the pattern vocabulary has no squared meander; a real key-fret needs a lookkit/shader pattern (or a tiling texture in
Materials v2) rather than DiamondPlate; keep any plate frieze to ~10-12 px so it clears the rack layout.
