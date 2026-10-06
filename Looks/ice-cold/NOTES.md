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
