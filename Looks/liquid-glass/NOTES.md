# Liquid Glass — notes

Brief (BACKLOG.md#liquid-glass): frosted pale-aqua plates, translucent (alpha ~0.85) over a
deep-teal backdrop; clear domed "droplet" buttons with a bright spec rim and a darker refractive
core (radial gradient); knobs as glass pucks with a caustic shimmer (NoiseOrganic); sea-glass
white light mode.
**Signature:** everything looks WET.

Built with the lookkit `lit` class and the `glass.frosted` preset:

| Surface | Material |
|---|---|
| plates | glass.frosted at alpha 0.85 |
| droplets (keys, handles) | radial ramp (core → rim), deep dome, wide soft bevel, alpha 0.88 |
| pucks (knob caps) | NoiseOrganic tinted toward light |

The wetness is mostly the rig: a cool key with tight, strong specular (power 64) and a faint aqua
bounce from below. Every round prints plate clip % (FACTORY: < 1% on light plates) and the control
ΔL off its plate.

## Round 1
Metrics:
- Dark: clip 0.0%. ΔL: knob +33, knob.small +55, latch +26.
- Light: clip 0.0%. ΔL: knob −38, knob.small −16.
- Keys are missing from the ΔL print: at alpha 0.88 they never reach the metric's 0.95 coverage
  threshold. Fixed in the kit (threshold 0.8).

Rubric:
- **Identity:** watery teal plus aqua light: unlike anything in the family. The droplet keys read
  as glass lozenges (dark core, bright rim). The aqua mute/solo fills glow.
- **Fidelity (worst):** the knob CAPS read as grey frosted pebbles. The NoiseOrganic caustic is a
  fine grey sparkle; nothing about it is wet or aqua.
- **Light mode:** "sea-glass white" renders a murky grey-teal. There are two causes: the
  translucent plates pick up a dark GAP behind them, and the plate ambient (0.62) is too low for a
  pale plate under one far key.
- **Cohesion:** the plates are matte frosted glass with no sheen, so nothing on the chassis looks
  wet.
- **Legibility:** aqua arcs on dark-teal tracks read clearly at 48 px. The knob.small step off the
  plate is weak in light mode (−16).

Fix order:
1. Pucks: saturated aqua glass, larger and brighter caustic cells added as light, a bright edge
   band.
2. Light mode: a paler backdrop and plate ambient up.
3. A plate sheen (`plate_ramp`).

## Round 2
Changes: saturated aqua puck with radial core and additive NoiseOrganic caustics; plate sheen
(`plate_ramp` 0.12 / 0.3); light backdrop paler, plate ambient 0.86.

Metrics:
- Dark: clip 0.0%. ΔL: knob +59, knob.small +77, key +42, latch +87.
- Light: clip 0.0%. ΔL: knob −53, knob.small −36, key −67.

Rubric:
- **Light mode:** it now reads as sea-glass, pale aqua-white glass, with no clipping.
- **Cohesion:** the plates carry a sheen.
- **Fidelity / craft (worst):** at 3× zoom every knob is an **eyeball**: a pale grey ring around
  a mottled aqua iris. The skirt takes the frosted preset's pale base and edge ramp. The caustic
  cells are dark-and-light mottling (moss/sponge), not light.

Fix:
- the skirt is aqua glass (`SKIRT #3F9AA3`), with a bright rim only at the outer edge;
- a narrower skirt band (bevel 0.14), so the puck face fills the cap;
- caustics: much larger cells (grain 22 px), fainter (0.22), pure additive light (tint stops all
  toward hi).

## Round 3
Changes: aqua glass skirt with a rim-only highlight; skirt band 0.22 → 0.14; caustics at grain
22 px, 0.22, additive.

Metrics:
- Dark: clip 0.0%. ΔL: knob +32, knob.small +51, hero +38, key +42, latch +87.
- Light: clip 0.0%. ΔL: knob −80, knob.small −61, key −67.

Rubric:
- **Fidelity:** the pucks are WET now. At 3× each reads as a glass marble with water inside: an
  aqua core, a bright refracted foot at the bottom, a crisp specular dot, soft caustic light. The
  white nub reads as the pointer at 40/80%. **Signature met on the knobs.**
- **Legibility:** the dark-mode knob step fell to +32 (the cap is darker aqua now). It is still a
  clear separation, helped by the dark ring and the bright rim. Arcs read at 48 px.
- **States:** Disabled, Pressed and Active are distinct. **Hover is nearly invisible** on the
  droplets: `BODY_HI` derives as BODY + 7% white, which is lost in the radial ramp.
- **Cohesion (worst):** the pads are opaque, matte, muddy tiles. They are the only non-glass parts
  on the rack.

Fix:
- pads become glass: the frosted preset at alpha 0.85, domed. The bound row colour is unchanged
  (no ramp), and the tint goes 0.6 → 0.75 so the rows stay saturated;
- an explicit, clearly lighter Hover (`BODY_HI #8ACBD1`).

## Round 4 (final)
Changes: glass pads (frosted preset, alpha 0.85, dome 0.45, tint 0.75); explicit
`BODY_HI #8ACBD1`.

Metrics:
- Dark: clip 0.0% on every plate. ΔL: knob +32, knob.small +51, hero +38, key +43, latch +87.
- Light: clip **0.0%** on every plate (FACTORY budget < 1%). ΔL: knob −80, knob.small −61,
  key −66.

Rubric:
1. **Identity:** in one second it reads as glass and water. Tiled with Flat, Tron and Gold Leaf it
   differs on all four axes:
   - material: translucent glass, vs flat greys / neon tubes / lacquer + metal;
   - form: droplet lozenges and marble pucks;
   - lighting: lit, with tight wet highlights;
   - palette: a mid-value aqua chassis; every other look is near-black.
2. **One material story:** plates, keys, knobs, handles, pads and scroll parts are all frosted
   glass, with one cool rig and one soft shadow (blur 2.2, cast 0.18).
3. **Legible:**
   - aqua arcs on dark-teal tracks separate 0/40/80/100 at 48 px, and the white nub points;
   - ON is a lit aqua / ice-blue / mint fill;
   - plate print is near-white on teal / deep teal on sea-glass.
4. **Craft:**
   - no plate bevel or dome, lips 0;
   - caustic cells are large and soft (no aliasing at 1:1);
   - no blown whites on plates.
5. **States:** Hover (lighter), Pressed (darker, sunk), Disabled (dim, edge dimmed) and Active
   (lit fill) all differ.
6. **Light mode:** the chassis goes sea-glass white; the glassware is identical.
7. **Fidelity:** all the brief's motifs are present:
   - frosted aqua translucent plates over deep teal;
   - droplets with a dark refractive core and bright rim;
   - glass pucks with caustics;
   - sea-glass light mode;
   - everything wet.

Not done / not verified:
- **No animated shimmer.** The brief's "slow pattern speed" doesn't exist: the shaders have
  `*GradientSpeed` but no pattern speed, so the caustics are static. An animated shimmer would
  need a shader feature (Wave 3 / Phase 3).
- **Translucency over real content.** The plates are alpha 0.85. In the app, whatever the layout
  draws behind a docked panel shows through it; the rack composites them over the look's own
  GAP/BACK. Check in Play Mode that busy views (multitrack lanes behind a panel) don't muddy it.
- **Unity / Play Mode** in general: all judgement is from slrender.
