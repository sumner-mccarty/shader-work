# Candy Cane — notes (seasonal)

Brief (BACKLOG.md#candy-cane): red velvet plates with gold trim, candy-cane striped slider tracks and
knob skirts, pine-green keys, warm fairy-light lamps (amber glow, slightly uneven per lamp); light
mode snow-white frosted chassis with red and green. **Signature:** stripes + velvet + warm twinkle.

Built on the lookkit `lit` class: `fabric.velvet` plates with a gold welt (kit `plate.stitch`), green
`enamel` keys with a `gold.brushed` chamfer, gold slider handles, red/white stripes through the kit's
new `shape[...]["set"]` raw-property hook (default off; Flat/Tron/Gold Leaf proofs unchanged):
Angular gradient on the knob skirt (a peppermint swirl), Triangle gradient on the slider fill.

## Round 1
Metrics: clip 0.0% (both modes). ΔL dark: knob +85, knob.small +94, key +37.
- **Identity:** unmistakable — peppermint-swirl knobs, striped fills, red velvet, green keys, gold.
- **Legibility:** **worst problem** — the cap is a tiny green dot and the white nub vanishes on the
  white/red swirl: the pointer is unreadable at 30 px.
- **Craft:** pad rows tint to olive on the green pad body; velvet reads smooth (acceptable).
- **Light:** snow frosted chassis good; clip 0%.
Fix order: 1. bigger cap face + gold nub; 2. neutral pad body.

## Round 2
Changes: cap_r 0.6 / bevel 0.2 (bigger green face), gold nub, neutral pad body.
Metrics: clip 0.0%. ΔL dark: knob +80, knob.small +88, key +37.
- **Legibility:** the gold dot on the green cap reads at 30 px; the striped ring is a clean band. Fixed.
- **Identity:** swirl ring + green face reads as candy/wreath in one second.
- **Craft:** velvet still reads smooth — the fabric grain is invisible at 1:1 (**worst**). The yellow
  pad row still tints olive (row colour is bound; accepted).

## Round 3
Changes: fabric grain 2.5 px @ 0.4, stronger sheen ramp on the plate (0.25/0.3).
Metrics: dark clip 0.0%, ΔL knob +65 / knob.small +86 / key +36. **Light clip 8.4% (Face), 3.4% (Bezel)**
— the dark plate's new fabric pattern was inherited by the light plate (modes merge materials) and
blew the pale frosted plate out.
- **Craft:** the velvet now has a visible nap and sheen; still soft, which is right for velvet.
- **Fix:** light plate gets its own Frosted pattern, AMB_PLATE 0.95 → 0.85.
