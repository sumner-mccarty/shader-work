# Ice Cold — notes

Brief (BACKLOG.md#ice-cold): matte black chassis, heavy gold chain detail (thick knurled skirts, gold
bezel rings), "iced" keys and lamps (white diamond face: high-scale Ceramic + strong spec + glow);
light mode white leather with the same gold and ice. **Signature:** gold mass + diamond sparkle.

Built on the lookkit `lit` class: `rubber.matte` plates, `ceramic` keys with a `gold.polished` edge,
`gold.polished` caps, `gold.brushed` + Knurled skirts, a dashed gold ring (the kit's `dial.stitch`
option, used as a chain link) round every cap, ice-blue ON colour, white-leather chassis in light.

## Round 1
Metrics: clip 0.0% (both modes). ΔL dark: knob +68, knob.small +103, key +63.
- **Identity:** gold caps with a chain ring and gold-bezelled keys are unlike the other looks; but
  the keys read as flat grey, not diamond-white, so the "ice" half of the signature is missing.
  **Worst problem.**
- **Craft:** dark plate renders charcoal grey, not matte black (plate ambient + ramp too strong); hero
  skirt knurl is halftone dither; light-mode "white leather" renders mid grey.
- **Legibility:** ice-blue arcs on black separate 0/40/80/100 at 30 px. States distinct.
Fix order: 1. key ambient up so ceramic reads white; 2. plates: black darker, white brighter;
3. coarser, fainter knurl.

## Round 2
Changes: key ambient 0.55 → 0.95 (ceramic reads white), plates darker/brighter, knurl 5 px @ 0.3,
plate print ink set explicitly for the dark mode.
Metrics: dark clip 0.0%, ΔL knob +98, key +145. Light: **plate clip 99%** (AMB_PLATE 1.25 too hot).
- **Identity:** now unmistakable — white-ice keys with gold bezels, gold chain-ringed caps, matte
  black. The ice half of the signature lands.
- **Craft:** matte black is black. Light plate blown out — fix. The dark mode's plate print
  ("A01 KICK") vanished: derived ink came from the dark key mark. Set `ink`/`ui` text light.
- **Fix next:** light ambient 1.05; check clip < 1%.

## Round 3
Metrics: dark clip 0.0%, ΔL knob +98, key +145. Light: Face clip 10.8%, Well 3.0%, Bezel 1.2% — over
budget. White leather reads white; diamond keys, gold ring and "A01 KICK" print all good.
- **Craft:** light chassis still too hot at ambient 1.05 → 0.95. The Well's 3% is the display text
  (#8FE0FF has a 255 channel) → text #7FD2F2.
- **Identity (25% zoom):** gold domes + white-ice keys on black/white reads as flex in a second.
