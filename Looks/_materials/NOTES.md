# Material library — tuning notes

`Tools/lookkit.py` → `MATERIALS` (19 presets) for the **lit** class. Regenerate the sheet with

```bash
SKINSHEET_BACKEND=bus python Tools/lookkit.py materials            # → Looks/_materials/swatches.png
python Tools/lookkit.py materials gold.polished chrome --out /tmp/x.png   # a subset
```

`swatches.png` shows every preset as a knob cap (56 px), a key (76×40), a slider handle (170×40)
and a px-locked plate (200×90). Each is drawn at 1:1, under the **shipped rig**
(Themes/Realistic.theme) on the left and a **neutral rig** (two white lamps, sheet_rack's daylight
set) on the right. Every control sits on the same neutral dark plate (#2A2D32). The line under each
row is measured, not judged:

- `knob/key ΔL`: the control's mean luminance step off its plate (0–255). This is the dark-mode
  separation check FACTORY asks for.
- `plate L`: the plate's mean luminance.
- `clip`: the % of plate pixels with any channel ≥ 250. A light-mode plate must stay < 1%.
- `white`: the % of control pixels that are fully white, i.e. blown highlight.

`metrics.txt` holds the final numbers.

## What a preset is

`base/lo/hi` + a 4-stop `ramp` (amounts toward lo/hi, bottom → top) + `edge` (the chamfer's own
ramp) + `pattern` (name, **grain in px per cycle**, intensity, contrast, p1–p3) + `linear`
(the pattern for non-round surfaces) + `tint` (PatternColor through lo/hi) + `spec/rough` +
`dome` + `bevel` + `amb` / `plate_amb` + `plate_ramp` + `alpha` + `reflect` (hook, see below).

A spec names a preset per surface (`key`, `accent`, `cap`, `skirt`, `handle`, `plate` or a slot
name), optionally with a tint or overrides: `{"preset": "enamel", "tint": "#1F7A52"}`,
`{"preset": "lacquer.black", "edge": "gold.polished"}`.

- A surface that names a preset takes its colour from the preset, unless the palette sets that
  surface's token (`BODY`, `CAP`, `SKIRT`, `HANDLE`, `FACE`, …).
- State deltas move the whole ramp: a gradient beats a plain colour write.
- Pads never take a ramp, because their colour is bound.

## Rounds

**Round 1 — first guesses.**
- *Craft:* metal plates clipped badly: gold 93%, rose 63/95%, ceramic and marble 96%. The plates
  inherited the control ambient (0.7–0.75), and a flat plate catches the full diffuse of both lamps.
- *Craft:* RadialBrushed on a plate read as sunrays.
- *Fidelity:* gold read as yellow plastic. The base and highlight were too light and saturated, and
  spec 0.8 blew the cap white.
- *Legibility:* black lacquer and carbon keys vanished on the dark plate (key ΔL ≈ 0). This is the
  FACTORY "dark controls on dark plates" finding.
- *Measurement:* the white value arc polluted the knob metric. Swatches now render at value 0.

**Round 2 — plates.**
- *Fixes:* separate `plate_amb` per preset (0.28–0.8, by base lightness), and darker, richer metal
  ramps (gold base #A97B22, lo #1C0E00, hi #FFEDB0, stops −0.75/−0.25/+0.3/+0.75).
- *Result:* clip 0.0% on every plate under both rigs, and gold now reads as metal.
- *Still wrong:*
  - RadialBrushed sunrays on rectangular keys.
  - Metal plates look painted. The ramp (PLATE_LO/HI 0.06/0.08) is too weak to suggest a
    reflected sky.
  - Pale materials blow out on controls under the neutral rig.
  - Dark knobs still vanish: the knob chamfer wore the body ramp, not an edge.

**Round 3 — reading as metal, separating dark.**
- *Fixes:*
  - `linear` pattern for keys, handles and plates (radial brush stays on caps).
  - `plate_ramp` (0.25–0.35) on metals: a real "sky" at the top of the plate.
  - Knob skirts now wear the skirt preset's EDGE ramp.
- *Result:* the lacquer knob ΔL went 6 → 26 under the shipped rig, with a silver chamfer ring
  that lifts it off the plate.
- *Still wrong:*
  - Chrome, aluminium, ceramic and marble controls are 20–47% white under the neutral rig.
  - The lacquer and carbon key edges are faint (ΔL 13–15).

**Round 4 — pale and dark extremes.**
- *Fixes:*
  - Pale bases darkened (aluminium #8C9197, ceramic #CCC6B9, marble #C8C3BA), with control
    ambient down to 0.3–0.4.
  - Chrome ramp's top stops pulled in (+0.55/+0.15).
  - Wider (0.16) and brighter chamfers on lacquer and carbon. Lacquer key ΔL is now 13 → 19
    (shipped) and 27 → 34 (neutral); carbon 15 → 21.
- *Result:* pale controls no longer clip under the shipped rig (0%).
- *Still wrong:* ceramic and marble now read dull greige there.

**Round 5 — compromise for pale.**
- *Fixes:* ceramic base #D6D0C3, marble base #D2CDC4, ambient 0.28, smaller domes. Velvet's dome
  dropped to 0.05 (it had a plastic hot spot).
- *Final:*
  - Plates: 0.0% clip everywhere.
  - Dark presets under the shipped rig: knob ΔL 24–45, key ΔL 19–36.
  - Metals: 0–8% white under the shipped rig.

**Round 6 — the ramps were upside down on every control.** This came from building the Gold
Leaf pilot.
- *Measurement:* the pilot's gold caps looked lit from below, so I ran a red-A / blue-D ramp test
  on screen:
  - `SDFButtonRM`, `SDFKnobRM` and `SDFSliderRM` put stop **A at the TOP** of the control;
  - `SDFPanel` and the non-RM shaders put it at the bottom, as the skill says.
- *So:* rounds 1–5 judged the control swatches with the "sky" at the bottom.
- *Fix:* lookkit now writes `direction (0, −1)` (`RM_UP`) on every RM control ramp and edge
  band. Plates are unchanged.
- *Re-judged:*
  - Chrome keys show a proper bright-top horizon reflection.
  - Gold keys read as lit bars of metal.
  - Lacquer keys separate better: key ΔL +19 → +23 (shipped), +34 → +37 (neutral).
- *Unchanged:* no preset value needed retuning, and plates are still 0.0% clip.
- *Final numbers* (`metrics.txt`):
  - Dark presets under the shipped rig: knob ΔL 19–38, key ΔL 22–39.
  - Metals: 0–11% white (chrome 11%), shipped rig.

## Known limits — read before choosing a preset

- **The two rigs disagree by about 1.6× in brightness.** The neutral rig's near key lamp is far
  stronger than the shipped one. Pale presets (ceramic, marble, aluminium) are tuned between the
  two:
  - Under the shipped rig they read as grey stone / satin metal.
  - Under the neutral rig they read white, with a 14–18% white highlight on domed caps.
  - A look with a bright rig should lower `amb` on its pale surfaces (`{"preset": "ceramic",
    "amb": 0.2}`). Its rack sheet's `clip%` / control step print will say.
- **Chrome is 11% / 24% white** (shipped / neutral). The white is the fake horizon reflection,
  which is what chrome is. Lower the top ramp stop if a look finds it loud.
- **Marble veins are visible on plates only.** At key size, grain 60 px is under one cycle and
  reads as polished stone. That is deliberate: veins on a 40 px key read as dirt.
- **Specular colour comes from the lamps.** Spec is white unless the rig's lamps are tinted. Warm
  "champagne" spec on gold is a RIG choice (a warm light1 colour), not a material one. The
  material's ramp carries the hue.
- **Environment reflection (Phase 3) is not modelled yet.** Metals and glass fake it with the
  vertical ramp (dark ground, bright sky), dome and edge.
  - Each preset may carry `reflect=<0..1>`.
  - `Lit.finish()` writes it as `<layer>ReflectIntensity`, but only once the shader declares that
    property. Today nothing is emitted, so no skin changes until the shaders grow it.
- **Translucency** (`glass.frosted`, alpha 0.82) composites correctly in the rack sheet. A glass
  plate needs a deliberate backdrop colour behind it (the look's `GAP`/`BACK`).
