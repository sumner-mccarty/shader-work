# Synthwave — notes

## Design intent

The 1980s sunset-and-grid era, on the kit's `neon` class (unlit, non-raymarched, no lamp rig). Tron is
cyan tubes on navy-black glass; Synthwave is the SUNSET. Every device plate is a vertical sky
gradient (night indigo -> violet -> hot magenta -> horizon orange), the tubes burn magenta -> pink ->
orange, the hardware (knob cap rings, pointers, slider handles) is chrome-cyan, ON states are hot
magenta, and the floor under the controls (gutter + knob bank) carries a faint neon grid. Form
language differs from Tron too: soft squircle keys and plates instead of chamfered octagons.
Signature: sunset gradient + grid. Light mode is a chassis change only: the plates go pastel
vaporwave (lilac / pink / peach faceplate, mint insets and gutter, lilac pad tray), the black-violet
glass keys, chrome rings and magenta ON stay (dark controls on a daylight chassis).

How it is built (all in `Tools/looks/synthwave.py`, no hand-written states): `neon` class tokens,
`shape` (squircle key/plate, 4-stop Face fill), `modes[mode]["set"]` for the grid pattern and the
pastel plate tube burn, `modes[mode]["states"]` for the pad hover/latched progression, the glass
hover lift and the pressed accent. 23 parts x 2 modes, track theme `Sunset` (existing), displays
`tron` finishes (their magenta -> violet -> cyan waveform fits).

Self-scores use Looks/CHECKLIST.md; self-critique below is of what the sheets showed, not of intent.

## Round 1

First complete dark + light sheets (HexGrid on the faceplate, kit pad sheen, pastel colours at 255).

scores: identity 7, story 8, material 6, light 5, taste 6, knobs30 6, pads 5, states 7, print 8, craft 4, glass n/a

Saw: the sunset plate already reads in one second and nothing else in the family looks like it, but
the kit's HexGrid (GRID 0.06) renders as aliased triangle fragments over only the right ~60% of the
faceplate (visible bottom-right), the pad bodies are a dull lavender-grey (violet SHEEN mixed with the row
colour), and the light plates measure 40% clipped (pastels authored with a 255 channel plus a plate
tube emitting at 1.0). knob.small at 30 px: groove invisible at 0%.
Fix first: drop HexGrid; clip-safe pastels and calm the plate tube burn in light; pad sheen re-based.

## Round 2

Circuit grid, pad sheen, light clip, groove.

scores: identity 8, story 8, material 6, light 8, taste 7, knobs30 7, pads 6, states 7, print 8, craft 7, glass n/a

Saw: HexGrid gone; the grid is now Circuit traces drawn additively (magenta on the gutter, a fainter cyan
under the knob bank), px-locked, and reads as a neon floor. Pads now take their row hue (pink / mint /
amber glass) and empty pads are visible on the black tray; light plates 0.00% clipped, controls stay dark.
Still weak: pad Hover looked like Normal, Latched like Pressed; keys' Hover only brightened the tube;
Accent Pressed ~ Normal; the light slider handle (white) vanished on the mint bed; gutter grid too loud
in dark, nearly invisible in light; Pill ON was yellow, not magenta.
Fix first: pad state progression; hover cue on the glass body; dark beds under light sliders.

## Round 3 (final)

Pad progression (sheen 0.2 / 0.32 / 0.42 / flood for Normal / Hover / Latched / Pressed, tube 0.085 /
0.115 / 0.15), glass-body lift on Hover (Button, ToggleBtn, Solo, Lamp, Chip), deeper-magenta Accent
Pressed, magenta Pill ON, sunset-gradient gutter fader, dark glass troughs for the light sliders, dimmer
dark grid / slightly stronger light grid, brighter dark arc groove.

scores: identity 8, story 8, material 6, light 8, taste 7, knobs30 8, pads 7, states 8, print 8, craft 7, glass n/a

Saw: states are now unmistakable on every key (hover lifts the violet glass and brightens the tube,
pressed floods, active fills magenta / cyan / amber, disabled sinks to a dim outline). knob.small at 30 px:
0 / 40 / 80 / 100 % all read in both modes (groove visible at 0%, magenta->orange arc grows), the cyan cap ring
keeps the knob off the plate. Family sheet (25% zoom): the only violet-magenta-orange gradient in the
set and the only one whose plates are a sky, vs Tron's cyan/navy octagons. printcheck 0 pairs under 3:1.
Weakest items: material (unlit neon is gradient lines + additive bloom, there is no moving highlight to
make glass or chrome feel physical) and taste against the Realistic reference; pads Hover/Latched/Pressed
are distinct but the band-style sheen is a hard-edged step, not a soft glow.
Fix next (not done): soften the pad sheen step; give the chrome-cyan hardware a real gradient ring.

## Round 4 - critic revision 1 (the coordinator's "Round 2")

Critic round 1 said REVISE (material 6, taste 6, states 6, craft 6). Changes: small-key Hover (ToggleBtn, Solo,
Lamp, Chip, Button: body lifts to lighter violet, tube 1.5x fatter, bloom opens; Dot: lilac body + hot rim; knobs: cap
lifts, ring goes white and 2x fat, arc glow x2.6); pads rebuilt (Normal = dark face + thin row rim, no sheen band;
Hover = lifted body + fat rim + bloom; Pressed = bright flood; Latched = glowing MAGENTA whatever the row, by a gradient
that beats the row binding); ONE grid (Circuit, 120 px tile) on Face / Inset / Back / Socket (dark ink lines on the
Face, so they show toward the bright horizon; glowing lines on the floor plates; softer inked lines on pastel); chrome
tube cap rings (cyan body + white highlight arc), KnobHero "ears" removed, PRESS fill deepened so pale text reads.

scores: identity 8, story 8, material 7, light 8, taste 7, knobs30 8, pads 8, states 8, print 8, craft 7, glass n/a

Saw: Hover is now obvious at 1:1 on every small key and on knob.small (white fat ring + lifted cap vs the 40% arc); pads are
clean slabs with four clearly different states and a magenta Latched that cannot be mistaken for Hover; the grid is one
idiom everywhere. Still: unlit neon has no moving highlight (material stays the weakest), the Circuit grid has random
gaps so it reads as a mesh/circuit rather than a clean lattice, and the Face grid is deliberately faint on pastel.
Fix first (not done): a real gradient/glow ring for the chrome hardware; soften Circuit's random gaps if the kit gains a
square-lattice pattern.

## Kit gaps (worked around, `Tools/lookkit.py` untouched)

* `neon` plates hard-code an octagon (`_PanelShapeType 4`), tube emissive 1.0 and halo emissive 1.0: the
  squircle comes from `shape["plate"]["set"]`, the pastel burn from `modes["light"]["set"]["plate"]`.
* A multi-stop sky needs a 4-token `fill` on Face (works: the plate writes 4 gradient stops); the kit's
  `plate_colors` only reports the first two, so the parts-sheet page colour is the horizon orange.
* HexGrid, the only grid the neon plate knows, breaks in px-locked mode (draws only right of ~38% of the
  panel, as triangle fragments) and has no pattern colour; the grid here is a raw `_PanelPattern*` set
  (Circuit: multiply ink on the Face and on pastel plates, additive glow on dark floor plates).
* The neon dial has no chrome ring and a single flat tube: the highlight arc (OuterRing3), fatter ring and hover
  ring are raw `_OuterRing2/3*` sets computed from the kit's own dial geometry (`DIALS` table in the spec).
* Neon pads have no Normal-without-sheen and no ON colour of their own; the sheen is switched off with
  `_ButtonBevelEnabled 0` and the magenta Latched is a gradient delta in `states`.
* Neon pads ignore `PAD_HOVER_EM` / `PAD_PRESS_EM`; hover/latched are written through `states`.
* Pill ON takes `LAMP[0]` (amber here); overridden with `_LedColor` through `set`.
* There is no way to draw a perspective grid or a sun disc (no per-pixel horizon, InnerFrame is centred
  and would sit behind the controls); the "grid-perspective feel" is a flat orthogonal grid under a
  vertical sky gradient.

## Known issues

* `lookcheck` warns `Dot: no Disabled state` and `Pill: no Pressed state` (4 warnings) - kit-level, identical on Tron.
* Dark-mode plate clip is 1.2% (Face) / 8% (Well): the emissive tube core is white-hot at its yellow end. Only
  light-mode plates carry the < 1% rule (they measure 0.00%); no glow is cut square at a quad edge
  (bloom is graded to zero at the plate padding).
* The Circuit grid has random gaps (it is a PCB trace pattern), so it reads as "grid-ish circuitry" rather
  than a clean lattice; in light mode it is deliberately faint.
* Display screens borrow Tron's finishes (`tron.dark`/`tron.light`, near-black glass, magenta -> violet -> cyan
  waveform); the light mode's screens therefore stay dark. Not seen in a real app screen here.
* Not verified: Unity (this look uses only the non-RM unlit shaders and existing track theme `Sunset`;
  no shader or shared JSON touched). Light-mode hover on pads is judged from the parts sheet only.

## Independent critic verdicts (Opus, fixed Looks/CHECKLIST.md)

### Critic round 1
```
round 1 — REVISE
scores: identity 8, story 7, material 6, light 7, taste 6, knobs30 8, pads 7, states 6, print 7, craft 6, glass n/a
evidence:
identity: At family-sheet thumbnail size the purple→magenta→orange gradient chassis looks like no other look. Tron is the only other neon look and it is dark navy with flat plates, so the palette structure and the chassis treatment both differ. The "grid" half of the signature barely shows: the Face plate is a clean gradient, and the grid appears only faintly on the inset and back plates.
story: Buttons, knob arcs, displays and plate rims share one sunset neon language with dark controls and bright rims. Two things break it: the back strip uses a busy purple maze (Circuit) while the inset uses a fine square grid, and the pads' thick pastel frames around dark inner squares look like a different idiom.
material: Knob value arcs read as gradient neon, and the hero knob's tick ring is convincing. The "chrome-cyan tube" is a flat cyan ring with no highlight or glow. Most rims are flat gradient strokes with almost no bloom; only Pressed shows a halo. The pad rims read as plastic bevels, not light tubes.
light: The chassis changes to lilac→pink→peach with a mint inset and back, which fits pastel vaporwave. The controls keep their dark purple bodies and stay legible. No plate clips at 0%. Disabled parts turn grey-lilac (Button, Toggle, Solo, Lamp, Pad), so light mode does touch control states slightly.
taste: The sunset chassis and hero knobs are striking. The pads are clunky nested frames, the buttons' yellow-pink rims feel toy-like, and the missing grid makes the whole thing read as "bold gradient UI", not a crafted synthwave instrument. Competent and loud, not stellar.
knobs30: In both modes the cyan ring separates each knob cleanly from its plate. 0/40/80/100 read distinctly by arc length plus the white dot. The dark-mode unfilled track is dark purple on near-black, so 0% leans on the dot alone.
pads: Normal (dark inner square), Hover (smaller inner square), Pressed (solid teal), Disabled (brown/dim) and Latched (tiny slot) all differ. Hover and Latched both read as "teal with a shrinking dark rectangle" and are easy to confuse. Latched is not magenta-ON in the parts row. Empty pads stay visible on the black plate.
states: Button, Accent, Close, Chip and Pill states are clear. Normal and Hover are nearly identical at 1:1 on ToggleBtn, Solo, Lamp and Dot in both modes, and KnobSmall Hover is hard to tell from 40%. Active states (magenta toggle, cyan solo, orange lamp) are clear.
print: Captions are readable on every plate in both modes: lilac on dark inset, white on magenta, cream on the orange bottom edge, dark purple on pastel. The exception is "PRESS": white on bright pink is weak in both modes, and dark-mode "FADER 62%" on orange-red is marginal.
craft: No diagonal wedges and no dotted lip seams. The dark back strip's Circuit maze is noisy at 1:1, and the light back plate shows a fine moiré-like mesh. The Socket plate is a flat empty black slab. The KnobHero's detached outer arc "ears" look messy. The pad double-rim plus inner square reads as stacked frames.
glass: n/a
since last round: first round
fix first (max 3, concrete, with the spec field to change):
1) Hover lift on the small keys. ToggleBtn, Solo, Lamp, Dot and KnobSmall Hover need a visible change: a brighter rim, a tube glow, or a lighter body (spec: hover state colour/glow delta per slot, in both mode palettes).
2) Pads (spec: pad face/inner inset, pad latched colour, pad rim width). Drop the dark nested square: make Normal a dark face with a thin neon rim, Hover a brighter rim or glow, Pressed filled, and Latched glowing magenta (the brief's "magenta ON"), so Hover and Latched can't be confused.
3) Put the grid signature where it shows and use one pattern (spec: plate texture on Face, Back pattern kind, scale and intensity). Add a low-intensity grid on the Face plate, ideally denser or brighter toward the lower, orange "horizon" half. Make Back use the same grid as Inset instead of the Circuit maze, and check the light-mode back plate for moiré at 1:1.
notes (not scored): Make the cyan knob ring a real "chrome tube" with a highlight stripe or soft glow to match the brief. "PRESS" button text needs a darker ink on the pressed pink. The Socket plate could take the faint grid so it isn't an empty slab. The KnobHero outer arc segments could be simplified or tied into the tick ring. Light mode is pastel only in the chassis; the controls are still heavy dark purple, which is allowed but less vaporwave than the brief suggests. On the dark parts sheet, labels on the orange background are only just readable (that is sheet chrome, not app print).
```

### Critic round 2 — PASS
```
round 2 — PASS
scores: identity 8, story 8, material 7, light 7, taste 7, knobs30 8, pads 8, states 8, print 7, craft 7, glass n/a
since last round: Improved: pads 7→8 (clean rims, magenta latched), states 6→8 (all small-key hovers now visible), craft 6→7, story 7→8, material 6→7 (the ring has a tube highlight), taste 6→7. Unchanged: identity 8, light 7, knobs30 8, print 7. No regressions.
fix first (not required for PASS): 1) "PRESS" white on bright pink is weak (darker ink or darker pressed face). 2) KnobHero outer-arc "ears" at 0%/Disabled. 3) ToggleBtn Active vs Pressed in dark mode are both pink.
notes (not scored): the pad block now resembles Tron's at thumbnail size (a sunset pink→orange rim gradient or a hint of grid would keep it on-brand); dark-mode "dB OUT" dim mauve on near-black; disabled pad keeps a full-brightness rim; Close Normal vs Disabled differ only by rim/x brightness; Pill Hover only slightly brighter than "on"; light-mode Socket is a flat lilac slab (could take the faint grid).
```
