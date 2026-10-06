# Walnut & Brass — notes

Brief (BACKLOG.md#walnut-brass): 70s hi-fi receiver — oiled walnut side plates and inset panels
(WoodGrain, px-locked), brushed brass faceplate (Metal, warm), skirted aluminium knobs with fine knurl,
cream dial lamps behind amber glass; light mode teak + champagne aluminium.
**Signature:** real wood + warm metal.

Built on the lookkit `lit` class: `brass` Face/Bezel, `wood.oiled` Back/Inset/Socket/ScrollTrack,
`aluminium.brushed` keys, caps and handles, a fluted aluminium skirt, amber `enamel` accent keys.
Print is split per plate in dark mode (dark on brass, cream on walnut) via explicit `ink`.

## Round 1
Metrics: clip 0.0% both modes. ΔL dark: knob +93, knob.small +99, key +84.
Light ΔL: knob **+0.1**, knob.small +8, key −42.
- **Identity:** walnut + aluminium + amber reads hi-fi, unlike the other looks.
- **Craft / identity (worst):** the dark "brass" faceplate renders dark olive-brown — it reads as
  stained wood, not warm metal, so the "brass" half of the signature is missing; and every label
  printed on the Face ("MASTER", "A01 KICK") is dark ink on that dark plate, so it vanishes.
- **Legibility (light):** aluminium knobs ≈ teak in luminance (ΔL 0): the controls dissolve into
  the teak inset.
Fix order: 1. brighter brass; 2. darker teak; 3. calmer skirt knurl.

## Round 2
Changes: FACE brass #B0903C (plate ambient 0.62), teak darkened (#8C5A30 / #965F33), skirt knurl 3 px @ 0.12.
Metrics: clip 0.0% both modes. ΔL dark: knob +93, key +54. Light: knob +29, knob.small +38, key −36.
- **Identity:** the brass faceplate now reads as brushed warm metal flanked by wood — the signature
  lands in dark mode, and the light champagne/teak pair holds.
- **Legibility (worst):** captions printed on the walnut/teak panels are unreadable — dark ink on dark
  wood. Cause: the rack sheet printed every caption in the *faceplate* ink, whereas the app prints per
  surface. Kit fix: the rack sheet now uses the `inset` / `backplane` ink for captions that sit on
  those plates (a sheet change only: no part or recipe output moves; Flat proof still identical).
  Light-mode wood print set to cream, dark-mode faceplate dim ink darkened for contrast on brass.
