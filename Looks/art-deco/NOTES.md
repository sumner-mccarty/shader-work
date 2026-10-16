# Gatsby Deco — notes

Brief (BACKLOG.md#art-deco): lit · black enamel + gold geometric borders (rings, diamond shapes), cream lamps.
**Signature: nineteen-twenties geometry in real metal.** Everything stepped and chamfered, framed in gold inlay.

## Design intent
* **Form language (what separates it from Gold Leaf / Lunar Red, which are round):** every key, lamp, dot and pad is an
  OCTAGON (`_ButtonShapeType 4`, cut 0.85); every Face / Inset / Back plate is an octagon with a stepped corner pinned
  in canvas px (`_PanelShapeType 4` + `radius_px`), so a strip and a rack share the same corner. Knobs are an
  octagonal faceted gold bezel (Polygon x8) round a black-enamel face, with a concentric gold ring outside it, an ivory
  value arc, and a four-point ivory "diamond" mark on the face (a plain round dot on knob.small, where a star is a speck).
* **Gold = metal.** `gold.polished` on the chamfer of every key/pad, the knob bezel and slider handles (dark-ground /
  pale-sky ramp + polished matcap, warm key lamp in the rig). Plates carry a 1.4 px polished-gold border inlay
  (the plate `stitch` hook). The octagonal bezel gives eight facets that each catch the lamp differently.
* **Second note:** deep teal enamel keys, emerald for ON (accent key, switch). **Cream** lamp and ivory value arc / marks.
* **Sunburst:** the knob-bank Inset carries a fan of faint gold rays (RadialBrushed pattern, additive pattern colour).
* **Pads** are bevelled jewel cabochons in gold bezels; own track theme `GatsbyDeco` (ivory / jade / gold / deep teal rows).
* **Light mode:** the CHASSIS goes ivory enamel (+ jade value arc so it reads on cream); keys, caps, handles, lamps are
  byte-identical. Display wells stay black.
* Reference, not costume: no lettering, no characters, no brand.
* Fields: `accent` = Ribbons (teal / gold / ivory), `menu` = Contours in gold on black (dark) / antique gold on ivory.

## Round 1 — first full render (octagon keys + plates, gold knob bezel, Moss pads)
round 1 — REVISE
scores: identity 6, story 7, material 6, light 6, taste 6, knobs30 7, pads 4, states 7, print 8, craft 6, glass n/a
* Saw: octagon keys and the stepped gold-lined plates already read as deco and not as Gold Leaf; knob bezel is gold metal.
  Weak: pads are Moss red/green/brass (garish, not deco, and unframed); nothing says "sunburst / rings / diamond"; the
  plate bevel Back came out a stadium (corner 0.0 = pill); knob nub star was a speck; lamp ON blew to white; light-mode
  value arc (ivory on cream) vanished; light plate grain read as stucco; keys flat teal.
* Fix first: pads + track theme, motifs (ring / sunburst / diamond), light arcs.

## Round 2 — motifs and pads
round 2 — REVISE
scores: identity 8, story 8, material 7, light 7, taste 7, knobs30 8, pads 7, states 7, print 8, craft 7, glass n/a
since last round: concentric gold ring round the bezel (Knob, KnobHero), faint gold sunburst on the Inset, four-point
diamond nub, own track theme, pads are gold-chamfered cabochons (ivory / jade / gold / deep teal), Back is an octagon.
* Family sheet (contact, 16 looks): top-left is the only black-and-teal set with gold-outlined octagon panels; vs Gold
  Leaf (black + round gold knurled knobs) it differs in form (octagon everything, faceted bezel, ring), second colour
  (teal) and pad hues. Still the nearest neighbour in value / temperature.
* Weak: keys read as flat teal pills with a chamfer; small-knob star speck; enamel plate still greyish rather than black.
* Fix next: key gloss (enamel spec / gloss coat), darker enamel, knob.small dot, light value arc.

## Round 3 — enamel gloss, small knob, light mode
round 3 — REVISE (self-scored; awaiting critic)
scores: identity 8, story 8, material 7, light 8, taste 7, knobs30 8, pads 7, states 7, print 8, craft 7, glass n/a
since last round: keys and accent keys carry a gloss-coat matcap (spec 0.85, rough 0.1) so a lamp glint runs across the
face; plates darker (#090F11) with grain 0.03 (0.018 on ivory) so the enamel is smooth; knob.small uses a round ivory dot
(readable at 30 px: 0 % = dim track, 40/80/100 % = ivory arc, bezel separates from plate by >80 lum in both modes,
Looks/art-deco/sheets/knob-small-30.png); light mode value arc is jade on a dark track (ivory arc on cream vanished).
* printcheck: 0 pairs under 3:1. `check`: 0 errors, 0 warnings. Plate clip 0.00 % in both modes.
* Known weaknesses: the gold chamfer on keys is a darker bronze than the knob bezel (the key lamp only reaches the top
  edge); Hover vs Normal on keys is a modest lift (colour + 0.1 lighter), Pressed/Disabled are clear; the sunburst is
  deliberately faint (an additive pattern, only visible on the Inset); no diamond motif on plates (only the knob mark);
  the Face has no second concentric frame line (InnerFrame scales with the plate, so it would cut through content).

## Round 4 — critic round 1 (REVISE: material 5, light 5, taste 6, pads 6, states 6, craft 6)
round 4 — REVISE (self-scored; awaiting critic)
scores: identity 8, story 8, material 7, light 8, taste 7, knobs30 8, pads 7, states 8, print 9, craft 7, glass n/a
since last round:
* Bodies: button / chip / toggle / close / dot keys are now BLACK ENAMEL (lacquer.black, near-black, spec 0.95, gloss-coat
  matcap); teal survives only as the ON / latch colour (accent key, toggle Active, switch). Casino teal gone.
* Gold: a new chamfer ramp `gold.edge` (registered in the spec, bright at the TOP) replaces the string edge, which used the
  body ramp and lit every key/pad frame from below; the frames now catch light like the knob crowns. Solo Active and the
  ScrollHandle hover use the polished-gold body ramp (not flat colour); pad row 3 is a deeper gold.
* Hover/latch: key Hover lights the gold chamfer (hotter ramp) and lifts the face; pad Hover and Latched get a cream lamp
  edge-glow + emissive; knob Hover brightens the bezel ramp + emissive 0.12.
* Light = chassis only: removed the light-mode VALUE / ARC_OFF overrides; arcs, tracks, slider, pad Disabled (now opaque dark,
  alpha 1, mode-independent) equal dark. Only GAP/BACK/FACE/INSET/SOCKET, plate material, sunburst intensity (0.4), print differ.
* Craft: the bright horizontal streak across the sunburst was the pattern's angle seam (12 grooves x Param1 1.0 = whole
  cycles now; gone); Socket has a dim gold inlay + octagon; disabled ScrollHandle at alpha 0.8 so it is not a hole.
* Known weaknesses: no diamond motif beyond the knob mark; ivory arc on the ivory chassis is thin (kept identical to dark by
  rule); teal (accent only) is still shared with Rodeo.

---
## Independent critic verdicts (Opus, CHECKLIST.md scoring) — NOT ACCEPTED (batch stopped; status "draft")

| round | identity | story | material | light | taste | knobs30 | pads | states | print | craft |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 8 | 7 | 5 | 5 | 6 | 7 | 6 | 6 | 9 | 6 |
| 2 | 8 | 7 | 6 | 7 | 7 | 7 | 6 | 7 | 9 | 6 |

Batch stop rule fired (2 rejections in a row) before this look's 3rd revision, so it was not judged to the end.
Round-2 open items: pad row 3 still flat mustard / row 1 dull beige (needs lit gold/champagne metal); Pad Pressed vs Latched nearly
identical (both bright teal + cream rim); Socket plate is a plain dark box (needs an inner gold rule or a px-locked chevron/step
pattern); knob/knob.small Hover too weak at 1:1 and dark-mode 0% track nearly invisible at 30 px. Strongest part: faceted octagonal
gold knob skirts with a real moving highlight (clearly unlike Gold Leaf). Not shipped: Assets/Resources files not committed —
`python Tools/looks/art_deco.py write` regenerates them.
