# Carbon Race — notes

Brief (BACKLOG.md#carbon-race): carbon-fibre plates, red anodised knob skirts, machined aluminium
collets, yellow warning lamps, racing stripe on the backplane. Light mode: white ceramic-composite
chassis. **Signature:** carbon weave + red anodised.

Built on the lookkit `lit` class (no kit changes). Every family wears the weave: plates, keys,
slider handle, and a carbon "puck" (the knob's Fill dish, via `shape.set`) behind every dial.
Red anodised: knob skirt (ColletKnob shape, knurled), Accent key, ON states, pill ON, Fader gutter,
backplane twin stripes (Triangle gradient with alpha stops on `Back`, so the stripe sits over either
chassis). Yellow: value arcs, Solo/Lamp ON, display text. One shadow contract (blur 1.3, cast 0.22).
Light mode: only plates/gap change (ceramic with a faint pale weave); controls and rig colour pinned.

## Round 1
- Identity: red knob + stripe read, but plates were flat grey: **weave invisible**. Cause: the
  kit's `grain` is px per cycle but CarbonFiber's sine period is `scale*weaveScale(5)`, so grain 4-5
  aliased to ~1 px. Worst problem.
- Back stripe repeated 6x (linear gradient wraps) and was blurry.
## Round 2
- Fixed: weave grain 15 (about 3 px sine period), intensity 0.6 on plates and keys, 0.14 pale on
  light plates. Stripe = Triangle type with A,B alpha 0 and C,D red = two crisp-ish twin bands.
- Knobs had no carbon: added the weave puck; ARC_OFF darkened to a groove on it.
- Critique: slider handle in red anodised rendered pink/translucent: replaced with carbon handle
  + aluminium chamfer, grain 6 (handle UV is anisotropic).
## Round 3
- knob.small set to px 30 / arc 2.4 / nub 0.09 (30 px check): 0/40/80/100 arcs distinguishable,
  red nub dot readable, puck keeps it off the plate. Softened plate vignette (ramp 0.12/0.3);
  whiter light chassis; light track text pinned dark (printcheck 0 pairs).
- Family tile: unmistakable by the red twin stripe and red/silver knobs; at 25% the weave itself is
  not visible, and the dark plates sit near Flat/Ice Cold in value.

## Known issues
- Weave is anisotropic on non-square widgets (slider handle, scroll thumb), so it is coarser there.
- Slider handle lets the yellow fill show faintly through its chamfer (shared handle behaviour).
- Pads keep the generic bound row colours.
- Stripe edges are soft (~1/12 of plate height); a hard edge needs a kit pattern.
- Not Unity-compile checked; renders are slrender only.
