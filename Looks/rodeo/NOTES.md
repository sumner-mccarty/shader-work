# Rodeo — notes

Brief (BACKLOG.md#rodeo): tooled saddle-leather faceplates (tan → oxblood), stitched edges, silver
concho knobs (fluted skirt, engraved RadialBrushed cap) with turquoise inlay caps, keys like branded
leather patches, amber oil-lamp glow. Light mode: bleached rawhide and pale denim.
**Signature:** leather + silver + turquoise.

Built on the lookkit `lit` class: `leather.tooled` plates and keys with a `chrome` chamfer, `chrome`
skirts and slider handles, turquoise `enamel` caps with a radial-brushed engraving, amber key lamp.

## Round 1
Rubric:
- **Identity:** turquoise cap + silver skirt is already unlike any other look. But the dark plates
  read as flat chocolate brown, not leather: the grain is invisible at 1:1 and there is no tan
  highlight at the top. **Worst problem — the "leather" half of the signature is missing.**
- **Cohesion:** keys, handles and scroll thumb share one leather/silver story. Pads are the
  generic row colours (bound, by design).
- **Legibility:** amber arcs on near-black track separate 0/40/80/100 well; turquoise caps hold at
  30 px. Latch ON states (turquoise / amber) are obvious.
- **Craft:** hero skirt knurl reads as a mesh/gear mess; light-mode plate is a good rawhide but
  its leather grain is a little coarse and the denim insets read grey-blue, not denim.
- **States / light mode:** hover/pressed/disabled distinct; light changes only the chassis.

Fix order: 1. leather grain bolder + tan top on dark plates; 2. smoother silver skirt;
3. stitched edge; 4. denim more saturated.

## Round 2
Changes: leather grain 5 px @ 0.5, tan highlight at the plate top, brighter dark plates (FACE #76412A),
smooth silver skirt (Metal, not Knurled), more saturated denim insets.
Metrics: clip 0.0% on every plate (both modes). ΔL dark: knob +56, knob.small +81, key +25.
- **Identity / cohesion:** knobs now read as concho; plates are better but still flat chocolate at
  1:1 — no sign of stitching, which the brief calls out. **Worst problem.**
- **Craft:** skirt no longer a mesh. Denim reads denim.

## Round 3
Kit extension (default OFF, other looks and the Flat/Tron proofs unchanged): `plate.stitch` — a thin
solid thread-colour Border band on Face/Inset/Back (a welt line; the panel shader has no dashed
border), and `dial.stitch` — a dashed OuterRing (the knob shader's fixed 24 dashes) round the cap.
- **Identity:** stitched welt on every plate + stitched dashed collar on every concho + turquoise inlay
  + silver: reads as tack-room hardware at 25% zoom, unlike Flat/Tron/Gold Leaf.
- **Legibility (30 px):** turquoise cap + dark nub hold; amber arc separates 0/40/80/100.
- **States:** hover/pressed/disabled/latched all differ (turquoise latch, amber solo/lamp).
- **Light:** bleached rawhide + denim; controls unchanged. Clip 0.0%.
Rejected: knurled skirt (mesh at 1:1); dashed plate border (not available in SDFPanel).
Known limit: the plate stitch is a solid line, not dashes.

## Diversity check
Tiled with Flat, Gold Leaf and Tron (`slrender contact Looks/*/sheets/rack-dark.png`): Rodeo is the
only warm-brown rack with cream stitch outlines, and the only one with turquoise knob caps. It differs
from Gold Leaf (the nearest warm look) in material family (leather vs lacquer), palette structure
(mid-value brown vs near-black) and form (stitched outline plates, concho collars).

## Gate
`check` 0 errors · `lookcheck.py Rodeo` 46 skins, 0 errors, 0 warnings · `tests/test_basics.py` all
passed. Not verified: Play Mode in the real app (no Unity here).
