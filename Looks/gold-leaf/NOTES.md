# Gold Leaf — notes

Brief (BACKLOG.md#gold-leaf): black lacquer plates, 24k gold hardware (knurled skirts, domed
radially-brushed caps, gold-edged keys), warm key light with champagne specular, ivory lacquer in
light mode, emerald for ON.
**Signature:** gold that reads as METAL, never as yellow plastic.

Built with the lookkit `lit` class and the material library:

| Surface | Material |
|---|---|
| plates | `lacquer.black`, re-tinted ivory in light mode |
| keys | `lacquer.black` with a `gold.polished` edge |
| accent | lacquer tinted emerald |
| knob cap | `gold.polished` |
| knob skirt | `gold.brushed` + Knurled |
| slider handle | `gold.polished` |

The warm specular comes from the rig: a champagne key lamp, plus a faint cool fill in dark mode.

Every rack round prints measured numbers:
- plate clip %: a light-mode plate must stay < 1%;
- control ΔL: the control's luminance step off its plate, i.e. dark-mode separation.

## Round 1
Metrics:
- Dark: clip 0.0% on every plate. ΔL: knob +54, knob.small +62, key +34, latch +75.
- Light: clip 0.0%. ΔL: knob −57, key −67.

Rubric:
- **Identity:** strong. Black, gold and emerald; nothing else in the family looks like it.
- **Cohesion:** keys, knobs, handles and the scroll thumb all share one gold. The pads don't
  belong: the Moss rows tinted 55% onto the dark body read as muddy brown and olive.
- **Legibility (48 px):** good. Gold arcs on the black track separate 0/40/80/100 clearly, and
  the emerald nub reads.
- **Craft:**
  - The knob CAP reads as dull bronze. The cap's ramp bottom plus a weak lamp leave a dark "cup",
    so it is not polished gold. **Worst problem — fails the signature.**
  - The hero's knurl reads as mesh noise.
- **States:** hover, pressed and disabled are distinct, and the latches fill emerald or gold.
- **Light mode:** the "ivory" chassis renders khaki/greige (plate ambient 0.62 is too low for a
  pale plate under one far key).

Fix order:
1. Gold caps: ambient up, knurl finer and fainter.
2. Ivory chassis brighter (clip budget allows it).
3. Pad tint up.

## Round 2
Changes: cap ambient 0.9; knurl grain 1.4 px at 0.22; PAD_TINT 0.72; light plate ambient 0.62 → 0.88.

Metrics:
- Dark: clip 0.0%. ΔL: knob +89, knob.small +99, key +34.
- Light: clip 0.0% (worst plate 0.00%). ΔL: knob −76, key −122.

Rubric:
- **Identity / cohesion:** the gold now reads as gold. The ivory chassis reads as cream lacquer
  with black-and-gold hardware: the daylight-hardware idiom. Pads sit in the palette.
- **Craft:** at 3× zoom every cap is a **cup**. The 0.3 bevel band (the skirt) catches the key
  lamp and out-shines the small domed face, so the centre reads recessed and darker. The emerald
  dot sits on the skirt, not the cap. **Worst problem.**
- Everything else holds.

Fix:
- bevel 0.3 → 0.18, so the domed face dominates;
- skirt silhouette Fluted (30 flutes, shallow), so the knurl reads at the edge as well as in the
  pattern;
- lighter cap ramp;
- dot moved onto the face (distance 0.42).

## Round 3
Changes: the fluted skirt + narrow bevel + domed face from round 2's fix, and the kit fix that
emerged here (RM control ramps run bottom-to-top on screen; see Looks/_materials/NOTES.md, round 6).

Metrics:
- Dark: clip 0.0%. ΔL: knob +98, knob.small +107, key +34, latch +75.
- Light: clip 0.0%. ΔL: knob −68, key −122.

Rubric:
- **Craft:** the caps are domes now: bright crown, darker foot, radial brushing visible at 3×,
  emerald dot on the face. The knurled hero skirt reads as knurling. Gold reads as METAL on every
  part. **Signature met.**
- **Legibility:** at 48 px the 0/40/80/100 positions read from the arc and the dot.
- **States (worst problem now):** on black lacquer, Pressed (body darker) and Disabled (body
  toward the plate) barely differ from Normal. The gold chamfer is what you see, and nothing
  changed it.
- **Cohesion:** the black lacquer plates read as matte paint, not lacquer. They have no sheen.

Fixes:
- kit: Disabled now dims a preset key's edge band (`Lit.dim_edge`, on the materials branch);
- spec: Pressed fills to a warm gold-brown (`BODY_LO #3B3322`);
- plates get a lacquer sheen (`plate_ramp` 0.12 / 0.2 toward the preset's grey highlight).

## Round 4
Changes:
- kit: `dim_edge` on Disabled;
- spec: Pressed `BODY_LO #3B3322`, lacquer plate sheen.

Metrics:
- Dark: clip 0.0%. ΔL: knob +86, knob.small +105, key +32.
- Light: clip 0.0%. ΔL: knob −71, key −112.

Rubric:
- **States:** dark mode is now unambiguous. Pressed fills warm gold-brown, Disabled dims the gold
  chamfer to bronze, the latches fill emerald (mute), gold (solo) or green-lit (lamp).
- **Cohesion:** the plates read as lacquer, with a soft sheen rising to the top.
- **Light mode (worst):** Disabled derives from the PLATE (`DIS_BODY = mix(BODY, FACE)`), so on
  ivory a disabled key turns pale grey and its label vanishes. The control changes with the
  chassis, which breaks the light-mode rule in spirit.

Fix: `DIS_BODY #22201C` in the shared hardware palette. Disabled looks the same in both modes.

## Round 5 (final)
Change: `DIS_BODY #22201C` shared by both modes.

Metrics:
- Dark: clip 0.0% on every plate. ΔL: knob +86, knob.small +105, hero +88, key +34, latch +73.
- Light: clip **0.0%** on every plate (FACTORY budget < 1%). ΔL: knob −71, knob.small −55, key −126.

Rubric:
1. **Identity:** in one second it reads as black lacquer and gold. Tiled with Flat and Tron
   (`slrender contact Looks/*/sheets/rack-dark.png`) it differs on all four axes:
   - material: lacquer + metal, vs flat greys / neon glass;
   - form: domed fluted knobs and chamfered keys, vs capless arcs / tubes;
   - lighting: lit, vs unlit;
   - palette: warm black-gold-emerald, vs neutral + orange / cyan-pink.
   Realistic and Neomorphic have no `Looks/` sheets yet; against their skins it shares the lit
   class but not the material (no brushed aluminium, no clay) or the palette.
2. **One material story:** one gold on every hardware part (cap, skirt, key chamfer, handle,
   scroll thumb, solo fill). One shadow contract (blur 1.5, cast 0.22).
3. **Legible:**
   - 0/40/80/100 are distinct at 48 px (gold arc on a black track, plus the emerald dot);
   - ON vs OFF is a fill change (emerald / gold / lit green), not just a hue;
   - plate print is gold on black / dark brown on ivory.
4. **Craft:**
   - no plate bevel, no dome on plates, lips 0;
   - the knurl and radial brushing hold at 1:1 with no aliasing;
   - no blown highlights (white 0% on controls).
5. **States:** Hover / Pressed / Disabled / Active all differ in both modes.
6. **Light mode:** the chassis goes to ivory lacquer; the hardware is identical.
7. **Fidelity:** every brief motif is there: knurled gold skirts, domed radially-brushed gold caps,
   gold-edged keys, warm key light (champagne spec from the rig), ivory light mode, emerald ON.
   The gold reads as metal, not yellow plastic. No brand references.

Not verified: Unity / Play Mode. The rig's champagne spec and the light chassis's ambient are
calibrated in slrender, which FACTORY's 2026-10-06 Unity check found matches the editor for the lit
class.
