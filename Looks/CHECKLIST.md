# The critic's checklist — the SAME list every round

Batch 2026-10-06 stalled because a fresh critic raised new items each round and builders chased moving
goalposts. The critic scores exactly these items, every round, and receives its own previous verdict so
it can say what got better. A builder fixes the lowest-scoring items first.

Score each 1–10 with one sentence of evidence (what you see, where). PASS = every item ≥ 7 and
**Identity ≥ 8**. Anything you notice that is not on this list goes under "notes", never into the score.

## Look-level
1. **Identity** — at 25% zoom the rack reads as THIS theme and no other look (compare the family sheet:
   different in ≥ 2 of material, form language, lighting class, palette structure).
2. **One material story** — every part belongs to the same world; one shadow contract.
3. **Material conviction** — metals read as metal (moving highlight, not tinted plastic), wood as wood,
   fabric as fabric. Uses the Materials v2 presets/textures/matcaps where the brief names a material.
4. **Light mode** — changes the chassis, not the controls (or carries a reviewed waiver); 0% plate clip.
5. **Taste** — measured against Looks/TASTE.md: would the owner put this next to the looks they rated
   highest?

## Recurring defects (each one fails the item it belongs to)
6. **Small knobs at 30 px** — a knob.small rendered at 30×30 separates from its plate and its value reads.
7. **Pads** — Normal / Hover / Pressed / Latched all visibly different; empty pads still visible on the plate.
8. **States** — Hover, Pressed, Disabled (and Active on latching keys) visibly differ on every key.
9. **Print** — `python Tools/looks/<module>.py printcheck` reports 0 pairs under 3:1.
10. **Craft** — no hard diagonal wedges on plates, no chrome bar on a plate bevel, no dotted lip seam,
    no glow clipped square at a quad edge, no texture aliasing at 1:1, no empty-looking plates.
11. **Glass looks only** — a `backdrop` is set, gaps show it, glass parts are opaque bodies (the glass
    is the transparency), and the rim/refraction is visible on curved edges.

## Verdict format
```
round N — PASS | REVISE
scores: identity 8, story 7, material 6, light 7, taste 6, knobs30 7, pads 5, states 7, print 8, craft 6, glass n/a
since last round: <what improved, what regressed>
fix first (max 3, concrete, with the spec field to change): ...
notes (not scored): ...
```
