# Marble & Rose Gold - notes

Brief (BACKLOG.md#marble-rose): white Carrara plates, rose-gold domed hardware, blush accents, soft
daylight rig; dark mode Nero Marquina with gold veins. **Signature:** stone + jewellery.

Built on the lookkit `lit` class. Plates use the `marble` preset (px-locked Marble, 90 px grain); dark mode
uses a spec-local preset `marble.nero` (registered from the spec, kit untouched). Keys/caps/handles/skirt
are `gold.rose`, accent keys are blush `enamel` with a rose-gold chamfer.

## Round 1
First guess used the stock marble tint (pattern colour mode 3 = Multiply). Findings:
- Craft/fidelity (worst): Multiply can only DARKEN, so Nero had no gold at all, and Carrara was a dim grey
  with wide wavy worms. Rose-gold keys read as brown leather (ambient too low).
- Fix order: pattern colour mode, then plate brightness, then key brightness.

## Round 2
Nero now uses colour type Feature + mode Lerp (stops black -> charcoal -> gold), so veins are metallic gold.
Carrara plate ambient raised and veins thinned (p1 0.1, p2 1.0, p3 0.3) - reads as white stone. Keys brightened
(amb 1.0-1.15) -> true rose gold, but the cap highlight blew to cream.
- Worst: Nero vein density swung from invisible (contrast 3) to camouflage (contrast 1.8); the pattern is
  very non-linear in contrast.

## Round 3
Nero settled at intensity 0.9 / contrast 1.2 / p3 0.9: sparse gold veining in black stone. Cap ambient
back to 1.0 so the dome keeps a darker foot. Dark chrome/track print lifted to pass printcheck.
Metrics: plate clip 0.0% both modes. dL dark: knob +124, knob.small +129, key +112. Light: knob -64,
knob.small -53, key -78 (dark rose-gold hardware on white stone, as intended).
- Legibility: knob.small at 30 px reads (cap + blush arc) in both modes.
- Identity: next to Gold Leaf / Ice Cold / Walnut & Brass the pink domes + veined stone are unmistakable.
- States: hover/pressed/disabled/active differ on every key and knob.

## Known issues
- The shader's Marble pattern is vertical sin-stripes warped by turbulence; veins run roughly top-to-bottom
  (the kit has no pattern-rotation key), so it reads as marble rather than a literal diagonal Carrara.
- Nero vein colour is a bronze-gold rather than a bright metallic gold (no specular on pattern colour).
- Rose-gold keys on white Carrara (light) are darker than the plate; fine for legibility but less airy.
- Dark mode hardware highlights are pale pink-cream at the dome peak.
