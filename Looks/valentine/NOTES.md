# Sweetheart (valentine) — notes

Brief: lit, blush and crimson satin (Satin), rose-gold hardware, seasonal February. Spec: `Tools/looks/sweetheart.py`.

**Signature:** a gift box. Plates are crimson SATIN (the engine's Satin pattern, pixel-locked, soft drape bands, not velvet nap) in dark mode
and blush-pink satin in light mode. Keys are rose-pink satin enamel under a polished rose-gold chamfer, knob caps are polished
rose gold (matcap) over a fluted blush skirt (bonbon-paper liner), the ON lamp is a HEART (button icon 13, rotated 180 because
the SDF is y-up; lit state = crimson key, white heart), pads are confectionery (strawberry, pistachio, buttercream, lilac,
own track theme `SweetheartBox`), rose-gold piping line round the Face/Inset plates. Fields: `accent` = Ribbons (silk ribbon), `menu` = Bokeh, both in crimson/blush.
Light mode changes only the chassis; hardware tokens are identical.

Rejected: velvet plates (Candy Cane already owns red velvet); gold hearts everywhere (costume); a heart as knob nub (the knob nub
shader only implements circle/rect/rounded/ellipse/triangle, KnobNub has no heart shape).

## Round 1 — first render
Dark: clip 6% on Face (plates washed pink), pads near-white, satin read as vertical pinstripes. Light: plates 98-100% clipped.
Heart icon small and upside down.
```
round 1 — REVISE
scores: identity 6, story 7, material 6, light 2, taste 5, knobs30 7, pads 5, states 7, print n/a, craft 4, glass n/a
fix first: light plates clip (AMB_PLATE / PLATE_LO/HI override the preset), pad amb, satin pattern scale/p1/p2, heart icon
```
## Round 2 — plates deepened
AMB_PLATE 0.62 / 0.5 and explicit PLATE_LO/HI: dark clip 0%, light 0.95%. Satin retuned to a wide drape (scale 1, p1 0.2, p2 0.8).
Keys deepened to #DE5F80. Heart rotated 180 and sized 0.9; LAMP crimson so Active is a lit red key with a white heart.
```
round 2 — REVISE
scores: identity 7, story 8, material 7, light 6, taste 6, knobs30 8, pads 6, states 8, print 5, craft 7, glass n/a
since last round: clip fixed, heart reads, satin no longer pinstripes
fix first: light-mode key/plate separation (key dL ~0 on pink plate); print pairs under 3:1 in light; satin sheen too faint on dark
```
## Round 3 — satin lift, light separation, print
Dark satin intensity 0.5 (light 0.2 to hold the clip budget), light plates slightly deeper (#EFB0BF), light Back ink darkened
(backplaneDim, chrome label/icon) -> printcheck 0 pairs under 3:1. Family sheet: unmistakable (pink-crimson satin + pink hardware
+ hearts + pastel pads) next to Candy Cane / Lunar Red (red, gold, saturated pads) and Marble Rose (black stone).
```
round 3 — PASS (self)
scores: identity 8, story 8, material 7, light 7, taste 7, knobs30 8, pads 7, states 8, print 9, craft 7, glass n/a
```
Gate: `check` 0 errors; `lookcheck Sweetheart` 46 skins 0 errors; `printcheck` 0 under 3:1; `tests/test_basics.py` all passed.

## Round 4 — critic REVISE (identity 5, material 5, states 6 ...) addressed
Root cause of the "pinstripe corduroy": the pattern tuple's 2nd value is GRAIN IN PX (scale = tile px / grain), so ("Satin", 3.0 ...) meant a 73-cycle
stripe. Now grain 330 px, rotated per plate (`_PanelPatternOffset`) -> wide soft diagonal sheen bands (real satin drape).
Changes: (1) pad rows = blush -> rose -> crimson -> wine ladder (no green/cream) and a tone-on-tone HEART icon on every pad (Pad icon 13,
rotated 180, alpha 0.32) plus the 3 Lamp hearts; knob skirt is now a 9-petal rosette (BlobStar, p2/p3 = 1) in copper-rose, no longer
fluted, so it is not Marble & Rose Gold's knob. The knob shader has no heart shape (KnobShapeType and `_Nub` lack one; shape texture 100 has no
heart in this repo), so a heart-shaped indicator was NOT possible without a shader change. (2) metals warmed: ROSE_LO/HI copper-pink,
gold.rose base #B8705E, CAP/HANDLE #C98074 (read rose-gold, not silver). (3) Solo Active icon dark wine (was white on cream = blank),
Lamp Hover emissive 0.34 + white icon, Accent Disabled = grey-mauve (ACCENT_DIS). Notes: KnobSmall arc 3.4 px, VALUE #FF9FB8; light Inset deeper.
```
round 4 — self: REVISE-or-PASS pending critic
scores: identity 7, story 8, material 8, light 7, taste 7, knobs30 8, pads 8, states 8, print 9, craft 7, glass n/a
since last round: satin now reads as satin; hardware reads rose-gold; pads on-theme with hearts; knob silhouette distinct
```
Not done: KnobHero Disabled hotspot (not re-checked); light key/plate step still small (dL ~ -8).

## Round 5 — critic round 2 (identity 7, material 6, taste 5, knobs30 6, pads 6, craft 6) addressed
(1) Knob: the spiky rosette is gone; skirt = 6 broad rounded lobes (Fluted, count 6, depth 0.2, sharpness 0), cap dome 0.4 and matcap 0.55 so the hero
highlight is no longer a milky crescent; still unlike Marble & Rose Gold's 40-flute knob. (2) Metal: pink-champagne base #D4907F,
mauve (not brown) shadow #6B2C3A, near-white pink highlight #FFE2D8; CAP/HANDLE #D4968A. (3) Hearts at rack scale: pad heart icon 0.8 of the pad at
alpha 0.6 (reads at 25%); row1 deepened to #EE8CA8 so a white heart reads on every row; Lamp Hover keeps a dark heart (was a white blank).
Satin bands: pattern intensity 0.9 dark / 0.25 light (light would clip the plate budget above that: 0.45 gave 7% clip), still broad diagonal sheen.
Optional: KnobSmall pointer 0.2 and arc 3.8 px / #FFC2D2.
```
round 5 — self
scores: identity 7, story 8, material 7, light 7, taste 7, knobs30 7, pads 8, states 8, print 9, craft 7, glass n/a
```
Not done: quilted/damask Inset pattern, Pressed-vs-Latched pad hue split, Close Normal vs Pressed, slider thumb restyle (all still as round 4).

## Round 6 — critic round 3 (story 6, material 6, taste 5, pads 6, craft 5) addressed
(1) Knob: lobed skirt dropped, plain round silhouette (Circle), smooth domed rose-gold cap + one bevel ring; the value arc carries the read. (2) ONE alloy:
ALLOY #E3A898 / highlight #FFE6DE / shadow #8A5A60 for cap, skirt, handle, key and accent edges and the pad bezel (the brown #A86E5C base of the stock gold.rose
preset was leaking into pad/key rims); scroll handles are rose now. (3) Pads: Latched = saturated crimson gradient fill with a glowing white heart; Pressed emissive
0.6 -> 0.22 so it stays pale; ToggleBtn Active is crimson (emissive 0) vs the hotter Pressed ramp. Light chassis lifted toward blush-cream (GAP #C98A9C,
FACE #F6CAD2) at 0.76% worst clip.
```
round 6 — self
scores: identity 8, story 8, material 7, light 8, taste 7, knobs30 7, pads 8, states 8, print 9, craft 8, glass n/a
```
Not done: heart-shaped pointer (no heart in the knob nub shader), Disabled hero specular blob not investigated, damask Inset.

## Known weaknesses
* Dark plate hue is in the same red family as Candy Cane / Lunar Red; identity rests on the pink hardware, satin and heart.
* Satin is subtle: a drape of soft bands, not a mirror sheen (the Satin pattern is a single sinusoid + flow warp).
* Light mode key/plate luminance step is small (dL ~ -12); separation comes from the rose-gold chamfer, shadow and the dark glyphs.
* Pads are pale pastels; Normal vs Latched separation relies on the kit's emissive/bevel states, not on a hue change.
* The heart sits slightly high in its key (icon offset tuned by eye).

---
## Independent critic verdicts (Opus, CHECKLIST.md scoring) — REJECTED after 3 revision rounds

| round | identity | story | material | light | taste | knobs30 | pads | states | print | craft |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 5 | 7 | 5 | 7 | 5 | 6 | 7 | 6 | 9 | 7 |
| 2 | 7 | 7 | 6 | 8 | 5 | 6 | 6 | 7 | 9 | 6 |
| 3 | 8 | 6 | 6 | 8 | 5 | 7 | 6 | 7 | 9 | 5 |
| 4 (final) | 8 | 7 | 6 | 8 | 6 | 7 | 7 | 7 | 9 | 7 |

Final blockers (round 4): **material 6** — the Satin pattern never reads as satin (plates look like plain crimson
gradients, buttons/pads like glossy candy plastic); knob metal still reads pearl-silver next to peach-cream rims, i.e.
not one rose-gold alloy; **taste 6** ("cute, okay" — not a look kept all month). ToggleBtn Active vs Pressed still marginal.
What worked: heart pads / heart lamps give an immediate February read; clearly distinct from Candy Cane and Marble & Rose Gold.
Not shipped: Assets/Resources files were not committed. Regenerate with `python Tools/looks/sweetheart.py write`.
Next time: needs a satin treatment the lit shaders can actually show (anisotropic sheen / fabric texture at higher
contrast) and a knob shape/material other than rose-gold-on-dome; the knob nub shader has no heart.
