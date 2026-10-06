# Street Wall (graffiti) - unlit

Intent: raw concrete + loud spray colour, all flat. Concrete plates (px-locked Concrete grain) in thick
marker-black frames; chalk-grey keys with a black marker outline; every ON state and value indicator is
spray paint (vertical gradient: magenta over cyan, lime over orange); dial tracks are black marker
strokes with paint laid over, chalk needle. Dark = night wall, light = whitewashed wall; controls identical.
The kit's unlit class has no gradient vocabulary, so the spec wraps its builders (SprayKit, assigned to
LOOK.kit) and adds paint + matching Hover/Pressed/Disabled/Active gradient states (a gradient beats a
plain colour write). lookkit.py untouched.

## Round 1 (rubric)
Identity: reads, but sits close to Flat at 25% (grey unlit). Cohesion good. Legibility: dark readouts
invisible (display text dark on dark well), slider fill a muddy vertical mustard on a thin track.
Fix: display text cyan/magenta in dark; slider paint runs ALONG the track (orange to lime).
## Round 2
Print: 13 pairs under 3:1 in dark (ink derived from dark MARK); set INK/INK_DIM chalk, key.label dark,
tracks.rowWithSample mid grey -> 0 pairs. knob.small at 30px: 0/40/80/100% distinct by paint extent and
needle. Remaining weakness: still near Flat in value structure.
## Round 3
Added overspray (paint fog) on the knob-bank Inset plate (magenta/cyan, bottom up), thicker frames, more
grain. Now unmistakable vs the family contact: only look with outlined concrete plus paint gradients.
Fidelity: good. States: Hover brightens paint, Pressed darkens/brightens, Disabled drops gradient to grey.

## Known issues
- Disabled fader (second slider) track is low contrast on the dark plate (disabled by design).
- Paint gradients are linear, not drippy; no per-key drip shapes.
- Not checked in Unity (slrender only).

## Revision round (critic: REVISE, identity 6)
Changes: (1) paint on everything pressed: Button dim paint (~35%) at rest, Hover half, Pressed full; Chip the
lime/orange pair; Lamp rests with a paint outline (ink when disabled); Pads wear the magenta/cyan pair as a
vertical gradient with both stops tinted 30% toward the row colour via padColor (so rows still differ);
ScrollHandle Pressed = darkened paint. (2) Concrete: contrast 1.7, finer/stronger px-locked grain (light mode
at half weight so the whitewash does not read as salt-and-pepper), dark base warmed (#55524D). The teal/magenta
haze on Inset is gone: the Panel gradient wraps (scale 4 gave three stripes), so the bank is now framed by a hard
paint stroke (border gradient) instead of a band - drip falloff NOT achieved. (3) Dark-mode states: Disabled
dial/fader lifted to #6A6A70 track + lighter fill/thumb; Close is an outlined slab at rest; small knob track
checked at 30x30 on the warm plate (black track keeps its silhouette, no ring needed).
Looked at: rack-dark, rack-light, a zoomed crop of the knob banks, and knob.small at 30x30 (values 0/40/80/100).
Known: pad rows 2-3 tinted pairs are a little muddy; no drip shapes; Unity not checked.

## Revision round 2 (critic: REVISE, identity 7)
1. Paint: both pairs now carry a saturated mid stop (cyan-violet-magenta, orange-yellow-lime) so a blend never
   greys. Accent/PLAY and Solo wear lime/orange, Mute and Lamp magenta/cyan, dial arcs and pads magenta/cyan, slider
   fill lime/orange. Hover/Pressed change value, not hue. Pads cannot alternate pairs (one skin per slot, rows tint
   all three stops 22% via padColor) - the row hue shows, the pair does not alternate.
2. Marker stroke: key outline 0.16 (about 3.8px at 48px, scales with the key). Dials are now black marker discs: a
   black stroke band wraps the paint, charcoal face, chalk needle - no bare floating arcs. Sliders sit in a black
   marker slot. Inset's paint border replaced by the plain black frame.
3. Neutrals/states: Button/Chip are chalk-white slabs (clear step to the paint Hover, full paint Pressed); Mute,
   Solo, Lamp, Close are black slabs with big paint-coloured marks (magenta/cyan/lime/chalk); Accent Disabled is
   concrete grey like the rest; a latched pad gets a thick white ring (Hover only lifts paint). Plates get a water
   stain: the foot of Face/Back/Inset/Socket runs darker (strong dark, light 0.3x) over the px-locked grain.
Looked at: rack-dark, rack-light, knob.small 30x30 at 0/40/80/100 (dark+light renders).
Known: pad rows differ only by tint, no per-bank pair alternation; stain is a bottom gradient, not vertical drips;
the bare slrender render of a knob shows its disc on the default background; not checked in Unity.

## Factory verdict — REJECTED after 2 revision rounds (2026-10-06)

Final critic (fresh, Opus): identity 7, one-material-story 6, legibility 8, craft 6, states 7, light-mode 7, theme-fidelity 6 → REVISE (needs identity >= 8, all >= 7).
Top fixes it asked for (not applied; revision budget spent):
1. Paint the knob bodies (dark spray gradient or coloured marker ring, thicker outline); put the lime->orange pair on knob arcs.
2. Make paint look sprayed: soft overspray halo outside outlines, grain on paint fills, denser bottom band; Button Normal cream sticker is out of place.
3. Round the slider wells to the key radius with the same outline; mid-grey well in light mode; lower/scale up light-mode concrete grain (reads as terrazzo); Lamp Pressed vs Active identical; Pad Hover barely differs.
Strengths: concrete + thick black marker outline is a clear form language; pad gradient grid reads as paint; distinct from every other look (unlit grey-mineral, multi-hue gradients).
