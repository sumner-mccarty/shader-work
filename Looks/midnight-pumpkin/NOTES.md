# Midnight Pumpkin — notes

Brief (BACKLOG#spooky): neon, purple/orange glow on black, lamp "eyes", slime-green ON, seasonal October.
Class `neon` (unlit tubes). Signature: fat soft keys with pumpkin->witch-purple tubes, a pumpkin EMBER at the
foot of the faceplate, carved triangle jack-o'-lantern eyes as the lamps, slime green for every ON, bone-white
candle needles. Light = dusk parchment / pumpkin-flesh / mauve chassis, same black glass controls.

## round 1 — REVISE
scores: identity 6, story 7, material 6 (neon: tube/bloom conviction), light 7, taste 6, knobs30 ?, pads 5, states 7, print ?, craft 6, glass n/a
since last round: first render. Orange/purple tubes and the green solo/lamp read; the ember glows nicely at the foot of the Face.
fix first: (1) pads: the inner sheen band reads as a second dark frame and the orange row goes muddy brown (spec `set.Pad` bevel off, PAD_FACE_TINT down);
(2) identity: nothing says "October" beyond the colours — the plates are plain black; add a slime-green fog under the rack (BACK green foot + green NoiseOrganic mist) and make the purple mist visible;
(3) knob.small at 30 px not yet measured.
notes: lamp triangles read as eyes, but at rest they are only a tube - fine.

## round 2 — REVISE
scores: identity 7, story 8, material 7, light 7, taste 7, knobs30 8, pads 8, states 7, print 9, craft 7, glass n/a
since last round: pads fixed (no inner frame, rim is now the true row colour at emissive 0.7 so orange/green/purple rows read);
purple mist now visible on Face/Inset, swamp-green fog under the rack (Back, bottom); printcheck 0 pairs under 3:1;
knob.small at 30x30 (sheets/knob-small-30.png): 0/40/80/100% distinguishable, ring + glass separate from the plate.
tried and rejected: a triangle knob nub (tiny and scruffy at 44 px - the round candle-dot reads better).
fix first: (1) Solo/Lamp ON lit the tube with the orange/purple TUBE, so the "eye" was pale-yellow, not slime — now Active
overrides border+bloom to slime (key_states); (2) Mute ON was too close to Pressed — HOT is now pumpkin-red;
(3) light mode read as generic peach: add a dusk mauve at the top of the Face (FACE_TOP) so it is dusk, not pastel.
notes: knobs in dark show the same orange arc for every size - consistent with the one material story.

## round 3 — PASS (self-scored; critic pending)
scores: identity 8, story 8, material 7 (neon: tube + bloom + mist are one world), light 8, taste 7, knobs30 8, pads 8, states 8, print 9, craft 8, glass n/a
since last round: slime-green eyes now green out to the tube (Lamp/Solo Active); mute ON is pumpkin-red, distinct from Pressed;
light mode is a dusk sky (mauve top to pumpkin foot) with parchment insets, controls unchanged; plate clip 0% in light.
family sheet: the only black + orange + purple look with outlined (not filled) pads, triangle lamps and a green foot;
Tron is cyan, Synthwave a magenta sky - differs in palette structure, form language (soft fat keys, triangle eyes, pad rims) and plate (ember + mist).
known weaknesses: dark Well plate clips 8% (small display bezel tube; same as the kit's neon wells), "eyes" are single triangles
not pairs (one lamp per control), the October cue is carried by colour + eyes + green fog rather than literal motifs (by design: reference, not costume).
Light-mode waivers: none.

## round 4 — critic REVISE round 1 addressed (self-score, critic pending)
Changes, one per critic item:
1a. Knobs are PUMPKINS: Fluted silhouette (10 flutes, `_KnobShapeType 6`) in an orange clay ramp (CAP #C84E00 -> #FF9A30) with a dark carved
    socket for the pointer (NEEDLE #1A0610) instead of black dome + white dot; cap ring is dark orange, hover lifts the cap.
    (Tried a triangle notch first: read as a black asterisk at 96 px - dropped for the round socket.)
1b. Lamps are carved EMBER eyes: near-black triangle with a barely-there ember rim when off, a warm fill + brighter rim on Hover,
    lit from inside amber -> yellow (and a bloom) when ON. Solo / pill / latched pads keep slime green.
1c. One hue per rim: TUBE/TUBE_REST/HALO are single-hue orange on controls; plate frames (Face, Well, Bezel) are a single witch-purple
    tube. The orange->purple->pink gradient (and its doubled yellow + pink ring) is gone. The blotchy NoiseOrganic mist is removed
    (the rejected camouflage pattern); plates keep a clean ember gradient and the green fog is a pure gradient on the Back.
2.  Light = chassis only: bone/parchment faceplate over dusk-violet back plates; every control token is the dark mode's (rims, glass, caps,
    disabled looks - no grey slab). Close is dark glass in both modes (it vanished on parchment). Plate clip 0%.
3.  Pad Hover now opens an inner row-coloured glow band + fatter rim (was a near-identical fill); rims tint only 30-50% toward the row, so the
    three rows read as one skin. Pad Disabled fades to 30% alpha. Lamp Hover is a visible fill/glow step over Normal.
scores: identity 8, story 8, material 7, light 8, taste 7, knobs30 8, pads 8, states 8, print 9, craft 8, glass n/a
known weakness: pad Hover's inner band can read as a thin second frame on a green row; neon glow is a measured ~1.1x bloom, not a heavy halo.

## round 5 — critic round 2 addressed (self-score, critic pending)
1. States: Accent Hover now steps to a bright ember (ACCENT_HI #FF8A1E->#FFC060, was ~Normal); Close Hover lifts to the same purple glass as
   Button/ToggleBtn; Accent Disabled is a dimmed ember (#4A2410->#5E3014 body, brown-orange rim), not a dark slab.
2. Light = chassis only: Slider/Fader trough glass is now set identically in both modes (Disabled bevel matches); Pad Disabled is the same
   opaque dark glass with a dim rim in both modes (no alpha, so no taupe slab on parchment); Lamp Normal is the same dark glass triangle
   with an ember rim in both modes (on dark plates it merely looks hollow because the plate is dark too).
3. One tube per part: control tubes are one orange (TUBE #FF7418, TUBE_EM 0.75) with a wide, soft red-orange bloom (BLOOM 2.2, HALO_EM 1.6, rest
   0.3 / hover 0.55 / on 0.9) instead of a bright second ring; Pressed's inner cream sheen band is now ember orange (SHEEN_ON), so no third ring.
   Plates stay a single purple tube. Pad rims take the full row colour and the track theme is palette-only (orange, slime, witch-purple, amber:
   no pink row). Pad Hover = crisp thin inner line + fatter rim (was a blurred dark rectangle). Lamp bloom narrowed (it clipped square on pale
   plates) and the Active eye is amber->orange with low emissive instead of a flat yellow.
scores: identity 8, story 8, material 7, light 8, taste 7, knobs30 8, pads 8, states 8, print 9, craft 7, glass n/a
not done (optional): stem notch on KnobSmall, rounder 30 px arc edges, cap depth beyond the radial ramp (the neon class is unlit: no lighting pass).
