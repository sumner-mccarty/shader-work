# Carbon Race — notes

Brief (BACKLOG.md#carbon-race): carbon-fibre plates, red anodised knob skirts, machined aluminium
collets, yellow warning lamps, a racing stripe on the backplane. Light mode: white ceramic-composite
chassis. **Signature:** carbon weave + red anodised.

## Design intent

A motorsport cockpit in black carbon, red anodised hardware and yellow warning marks, built on the
`lit` kit class (no kit changes) under one hard warm lamp. Every family wears the weave: plates, keys,
the carbon "puck" dish behind each dial; every family also carries red anodised metal or a yellow
signal. The knob is a machined collet: knurled red anodised skirt under a brushed-aluminium cap that
carries a satin matcap (the moving highlight). The display bezel is red anodised aluminium with the
real `brushed_fine` texture, the backplane carries ONE smooth crimson racing band, the Face plate has a
soft diagonal clear-coat sheen and four Torx cap screws, the value arcs/fills/lamps are signal yellow
and the screens are amber-on-black (`glass.amber` / `led.matrix.amber`, no shared JSON touched). Pads
come from the look's own track theme `CarbonRace` (pit-lane flag rows: red, yellow, blue, green). Light
mode changes ONLY the chassis (smooth glazed white ceramic composite with a pale sheen, no weave); controls,
rig colour and the red/yellow hardware are identical. One shadow contract (blur 1.3, cast 0.22).

Verified against the old draft's claims: the weave WAS invisible at 25% (3 px cells), and the dark
plates DID sit near Flat / Ice Cold in value. Materials v2 helped in three places: `matcap=satin` on the
cap and the accent key, `texture=brushed_fine` on the bezel and scroll handle, and the existing `carbon`
preset's gloss coat on keys. There is no carbon or anodise texture in the catalog (see Kit gaps).

## Round 1 — the inherited draft, re-rendered with the current kit
scores: identity 5, story 6, material 5, light 6, taste 4, knobs30 7, pads 4, states 7, print 8, craft 6, glass n/a
Saw: dark plates are flat charcoal with a 3 px weave that reads as faint noise (Flat / Ice Cold value at
25%); the red skirt is dull red plastic with no highlight; the accent key is smooth enamel; pads are the
generic maroon/green/amber rows; screens use the cyan/pink Tron finish; only the bottom stripe says
"racing". Controls separate (knob step +16, key +35) and 30 px knobs read.
Fix first: make the weave resolvable (grain 15 -> 30+), re-material the red as metal, give the look its
own pad/track palette, and a red presence in the main rack, not just the bottom strip.

## Round 2 — weave 7 px, anodised skirt, red bezel, track theme, amber screens
scores: identity 7, story 7, material 6, light 5, taste 6, knobs30 7, pads 7, states 7, print 9, craft 6, glass n/a
Saw: the weave now reads as carbon at 1:1 and at half size; the bezel is a bright red anodised frame
(vertical ramp = metal); pads are red/yellow/blue; the Inset is a darker glossy fine weave so the knob
bank separates. BUT the first light render was broken: the dark carbon preset I gave Inset/Socket/Back
leaked into light mode (harsh grey zig-zag, Back clipped 7.4%), fixed within the round with ceramic
overrides (clip 0.0% on every plate). The PLAY accent key measured 2.4:1 against its dark label.
Fix first: light-mode plate materials; accent key too dark; lit keys (Solo/Mute Active) show the weave
through their glyph.

## Round 3 — sheen, screws, brighter accent key, pad ladder, Active keys flat
scores: identity 8, story 8, material 7, light 7, taste 7, knobs30 8, pads 7, states 8, print 9, craft 7, glass n/a
Saw: a soft corner-to-corner clear-coat sheen (4-stop diagonal gradient via `set`) makes the plate read
glossy at 25%; Torx corner screws add hardware; the accent key is brighter red metal (satin matcap 0.6,
mean L 0.17: dark label 3.9:1, white label 4.9:1); Active ToggleBtn/Solo/Lamp drop the weave to 0.12 and
glow (emissive 0.28) so the glyph reads. Pad Hover vs Latched were nearly the same value (153 vs 145);
now Normal 102 / Hover ~136 / Latched ~170 / Pressed ~212, Disabled dim. Skirt: deeper anodising base
(#C8141F), knurl 0.3, satin matcap on the cap = bright streaks upper-left, dark lower-right.
Fix first: scroll handle shows horizontal rungs (widget-relative weave on a long thin part).

## Round 4 — final: scroll handle, brushed texture, weave 6 px
scores: identity 8, story 8, material 7, light 8, taste 7, knobs30 8, pads 8, states 8, print 9, craft 7, glass n/a
Saw: scroll handle is now a clean brushed streak (dark -> red on hover/press); bezel uses the real
`brushed_fine` texture (reads as brushed anodised aluminium, better than the procedural Metal); weave
cell 6 px (WEAVE 30) is the sweet spot between "visible" and "basket". I tried the same texture on the
accent key: it turned to orange-peel mottling at key size, so the key keeps the procedural Metal streak.
knob.small @30 px (Looks/carbon-race/check/knob30-carbon-race.png): 0/40/80/100% all readable in both
modes (yellow arc length, red skirt, silver cap, red nub), separated from the plate by the puck + dark
groove. Family check (/tmp/family-carbon-race.png, 10 looks): the only black-carbon + red + yellow rack;
differs from Flat/Ice Cold/Gold Leaf (flat or lacquer dark plates, gold/cyan/orange accents) in material,
palette structure and form (collet knobs), and from Candy Cane (the other red look) in value structure.
Weakest item: material/taste at 7 — the procedural CarbonFiber is a plain-weave of ripples (zig-zag),
not a true twill, so it reads "stylised carbon", and the plate average value is still close to the other
dark looks at 25%.

## Kit gaps (worked around, nothing in lookkit.py touched)
* No carbon-fibre or anodised-metal texture in `MaterialTex`; CarbonFiber is procedural, plain weave,
  cell = grain/5 px, widget-relative on controls (anisotropic on non-square parts). A `carbon_twill`
  texture would be the real fix (Tools/gen_materials.py in the Unity repo).
* A knob has ONE matcap (the cap preset's): cap and skirt share it; a skirt preset's `matcap` is ignored.
* Gradient stripes cannot have hard edges (the 4-stop ramp is smoothstep over 1/3 of a ping-pong half period),
  so the racing band is soft by construction (a Linear gradient, scale 2.4, gives ONE band); it is also
  proportional to the plate, so there is no stripe on the Face plate (it would cross controls at other sizes).
* No per-slot ON_MARK: the accent key and the lit keys share one glyph colour. ON_MARK is now the light
  glyph (white on the crimson keys); the yellow Solo/Lamp keys get a dark glyph through a state delta and
  `app.key.soloOn` (the app drives glyph colour live, so the app palette is what counts).
* Pad hover/latched/pressed ladder: only HOVER/PRESS emissive are palette tokens; Latched had to be set
  through `shape["states"]`. Plate gradient sheen/screws via `shape["Face"]["set"]` and
  `modes["light"]["set"]`; screens via a full `displays` map (amber finishes) because the shared
  ScopeFinishes.json cannot be edited.

## Known issues
* Not compile-checked in Unity (slrender only). The `brushed_fine` texture is used only on the Bezel
  (SDFPanel) and ScrollHandle (SDFButtonRM), both of which define UI_PATTERN_TEXTURE; no shader edited.
* Wide domed/bevelled metal keys (Accent) show the medial-axis bow-tie crease in their highlight.
* The crimson band is soft-edged and proportional to the Back plate's height; where it falls behind the
  real multitrack rows is unverified (the sheet's "A01 KICK" label sits above it).
* The light chassis is deliberately smooth (no texture): paper/plaster/frost textures read as concrete and
  the preset's own Ceramic pattern is a zig-zag tile, so it relies on the Face sheen + screws for life.
* Knob Hover is only a cap lighten; the Torx screws are 8 px in from the corner and small at 1:1.
* Screens: only the well is drawn on the sheets; scope/waveform/VU in amber are unverified here.
* The `CarbonRace` track theme reuses skyMode 7 (the Grid corridor) with a red palette; not seen in game.

## Round 5 — independent critic round 1 (REVISE): stripe, ceramic chassis, hover states, collet cap
scores: identity 8, story 8, material 7, light 8, taste 7, knobs30 8, pads 8, states 8, print 8, craft 7, glass n/a
Saw: the Back plate is now ONE smooth crimson band (Linear gradient, skirt crimson, weave 0.55 -> 0.2) in
both modes with nothing aliased or sawtoothed; the light chassis is smooth glazed ceramic (weave off, Inset
and Socket now differ in value); Dot / ScrollHandle Hover is silver vs Pressed crimson, Pill Hover lifts to a
lighter crimson over On, Accent Normal / Hover / Pressed are three clear steps, Pad ladder 102 / 153 / 191 / 225
(Normal / Hover / Latched / Pressed). The knob cap is now a nearly flat turned-aluminium disc with radial
machining and one soft highlight (no chrome horizon); bezel, skirt, accent key, band and Mute ON are one
crimson; slider fill is amber (arc/fill emissive 0.3 -> 0.1) beside the lamp yellow; "PLAY" is a light glyph
on crimson, "dB OUT" dim amber lifted, Mute ON no longer hot pink.
Fix first (remaining): the cap is a little matte next to the old chrome ball (a stronger moving highlight
would need a per-part matcap the kit lacks); the Accent key still shows a faint crease at top centre (wide
domed key, medial axis) — matcap cut to 0.3 but not gone; pad Hover is +50% but still the quietest step.

## Independent critic verdicts (Opus, fixed Looks/CHECKLIST.md)

### Critic round 1
```
round 1 — REVISE
scores: identity 8, story 7, material 6, light 7, taste 6, knobs30 8, pads 7, states 6, print 7, craft 6, glass n/a
evidence:
identity: At thumbnail size, the charcoal carbon chassis, crimson knob skirts, yellow arcs and red backplane stripes set it apart from every look on the family sheet. Candy Cane is maroon-chassis red, Gold Leaf and Ice Cold are dark with gold knobs, and none has a woven chassis.
story: Carbon plates, carbon chips with chrome rims, red skirts and yellow lamps share one world, but there are four different reds (coral brushed display bezel, crimson knurled skirts, pure-red noisy stripes, hot-pink ToggleBtn Active), and the steel-blue pad row picks up nothing else.
material: Dark carbon reads as real twill and the knob caps have a strong moving chrome highlight. The light chassis is a high-contrast white zig-zag weave that reads as woven fabric, not the smooth Ceramic the brief names. The "Collet" caps render as chrome balls with a hard horizon line, not machined collets.
light: The chassis changes (white weave, black knob rings) while buttons, knobs and the display stay the same, with no 0% plate clip. Only the Disabled pad (beige) and Disabled Accent (pink wash) change control colour.
taste: It has more conviction than the ~50% looks thanks to the chrome caps and real carbon, but the loud, crude red stripe bands and the five-element knob (carbon ring, red knurl, chrome dome, dot, arc) keep it short of sitting next to Realistic Dark.
knobs30: In the 30 px strip, the red skirts lift off both plates (helped by the black ring in light mode), the yellow arcs at 40/80/100 are clearly different lengths, and the red pointer dot on the chrome reads at all four values.
pads: In parts-dark, Normal and Hover (a little lighter ochre) differ only modestly. Pressed (flat bright yellow) and Latched (gold with glow) are distinct, Disabled is dark, and all rack pads are clearly visible on the plate.
states: Dot Hover and Pressed look identical (red), ScrollHandle Hover and Pressed are identical, Pill on and Hover are nearly identical, and Accent Normal and Hover are barely different. Button, Toggle, Solo, Lamp, Close and Chip all separate fine.
print: Knob captions, MASTER/PRESSED and the KEY/HOVER/PRESS labels read in both modes. The weak spots are the dim amber "dB OUT" on black, black "PLAY" on mid red, and black "A01 KICK" over the red/white weave stripe in light mode.
craft: The Back plate's red stripe bands are noisy and aliased at 1:1, and their edges become a jagged sawtooth over the light weave (rack-light bottom). The light chassis twill shimmers as a zig-zag, and every Accent/PLAY button has a pale V-notch wedge at top centre.
glass: n/a
since last round: first round
fix first (max 3, concrete, with the spec field to change): 1) Back plate racing stripe: replace the two noisy hard red bands with one smooth gradient band in the knob-skirt crimson. Turn the Back plate texture/noise intensity down to stop the 1:1 aliasing, and do not lay the weave under the stripe in light mode (Back plate band colour/softness + texture intensity, both modes). 2) Light-mode chassis: use the Ceramic material for light-mode FACE/INSET/SOCKET/BACK, with the weave texture off or near zero, so it reads as glazed white composite instead of woven cloth. 3) Hover states: give Dot and ScrollHandle a Hover distinct from Pressed (lighter or ringed, not the same red), Pill Hover a visible lift over on, and Accent Hover a clear brightness step (Hover tint/lift for Dot, ScrollHandle, Pill, Accent).
notes (not scored): The knob cap should look like a machined collet (flat top, stepped cylinder, turned rings) rather than a chrome ball, which would carry the Realistic Dark machined feel. Pull the display bezel's coral brushed red toward the skirt crimson so "red anodised" is one finish. The Accent V-notch highlight looks like a bevel/specular artifact in the accent button part. The Inset and Socket plates in parts-dark are almost identical and flat. The lemon slider fill is close to neon next to the deeper warning-lamp yellow. The steel-blue pad row could become a carbon-friendly neutral or a second livery colour.
```

### Critic round 2 — PASS
```
round 2 — PASS
scores: identity 8, story 7, material 7, light 8, taste 7, knobs30 8, pads 8, states 8, print 8, craft 7, glass n/a
since last round: Improved, and every item on my round-1 fix list landed. Material +1: ceramic light chassis, spun caps. Light +1: the controls now sit on a true ceramic chassis. Taste +1: single stripe, clean light mode. Pads +1: clearer Hover. States +2: distinct Hover on Dot, ScrollHandle, Pill and Accent. Print +1: white PLAY, A01 KICK moved off the stripe. Craft +1: stripe aliasing and weave shimmer fixed. Unchanged: identity 8, story 7 (bezel red and blue pad row remain), knobs30 8. Regressed: nothing.
fix first (not required for PASS): 1) Remove the Accent V-notch wedge (specular band / bevel profile, all states, both modes). 2) Re-colour pad row 3 from steel blue to a carbon-friendly neutral or a second livery tone (pad track theme). 3) Make the knob cap a real collet (flat top, stepped cylinder, turned rings) instead of a spun dome.
notes (not scored): bezel's brushed red brighter than the skirt crimson; dark-mode stripe is a brighter pure red than the light-mode crimson; a crisper band edge would read more like a painted stripe; at 30 px the 80% pointer dot sits at 3 o'clock on the red skirt and nearly vanishes (the arc carries the value); light-mode Disabled Button/Chip could fade further to separate from Hover; Knob Hover is hard to tell from an ordinary value state; Inset and Socket plates near-identical in both modes; lemon slider fill brighter than the lamp yellow.
```
