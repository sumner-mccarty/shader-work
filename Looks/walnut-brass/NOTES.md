# Walnut & Brass — notes

Brief (BACKLOG.md#walnut-brass): 70s hi-fi receiver — oiled walnut side plates and inset panels
(WoodGrain, px-locked), brushed brass faceplate (Metal, warm), skirted aluminium knobs with fine knurl,
cream dial lamps behind amber glass; light mode teak + champagne aluminium.
**Signature:** real wood + warm metal.

Built on the lookkit `lit` class: `brass` Face/Bezel, `wood.oiled` Back/Inset/Socket/ScrollTrack,
`aluminium.brushed` keys, caps and handles, a fluted aluminium skirt, amber `enamel` accent keys.
Print is split per plate in dark mode (dark on brass, cream on walnut) via explicit `ink`.

## Round 1
Metrics: clip 0.0% both modes. ΔL dark: knob +93, knob.small +99, key +84.
Light ΔL: knob **+0.1**, knob.small +8, key −42.
- **Identity:** walnut + aluminium + amber reads hi-fi, unlike the other looks.
- **Craft / identity (worst):** the dark "brass" faceplate renders dark olive-brown — it reads as
  stained wood, not warm metal, so the "brass" half of the signature is missing; and every label
  printed on the Face ("MASTER", "A01 KICK") is dark ink on that dark plate, so it vanishes.
- **Legibility (light):** aluminium knobs ≈ teak in luminance (ΔL 0): the controls dissolve into
  the teak inset.
Fix order: 1. brighter brass; 2. darker teak; 3. calmer skirt knurl.

## Round 2
Changes: FACE brass #B0903C (plate ambient 0.62), teak darkened (#8C5A30 / #965F33), skirt knurl 3 px @ 0.12.
Metrics: clip 0.0% both modes. ΔL dark: knob +93, key +54. Light: knob +29, knob.small +38, key −36.
- **Identity:** the brass faceplate now reads as brushed warm metal flanked by wood — the signature
  lands in dark mode, and the light champagne/teak pair holds.
- **Legibility (worst):** captions printed on the walnut/teak panels are unreadable — dark ink on dark
  wood. Cause: the rack sheet printed every caption in the *faceplate* ink, whereas the app prints per
  surface. Kit fix: the rack sheet now uses the `inset` / `backplane` ink for captions that sit on
  those plates (a sheet change only: no part or recipe output moves; Flat proof still identical).
  Light-mode wood print set to cream, dark-mode faceplate dim ink darkened for contrast on brass.

## Round 3
Metrics unchanged (clip 0.0% both modes; ΔL dark knob +93 / key +54; light knob +29, key −36).
- **Legibility:** every caption now reads on its plate (dark print on brass, cream on walnut/teak);
  knob.small holds at 30 px (aluminium cap + amber nub + amber arc on near-black track).
- **Identity (25% zoom):** brass-and-wood slab with aluminium dials — reads hi-fi in one second.
- **Known limit:** the walnut grain is calm at 1:1 (px-locked, 0.5 intensity); the hero cap's skirt
  knurl reads as a fine mesh at 3× zoom. Dim captions in light mode are cream on teak (contrast ~3:1).

## Diversity check
Tiled with the other looks: Walnut & Brass is the only rack with a bright brushed-brass faceplate
flanked by wood and with aluminium (not gold) hardware. vs Rodeo (brown, nearest) it differs in
material (metal faceplate + grain wood vs leather), value structure (bright centre, dark flanks) and
hardware (plain aluminium, amber, no stitching).

## Gate
`check` 0 errors · `lookcheck.py WalnutBrass` 46 skins, 0 errors, 0 warnings · `tests/test_basics.py` passed. Not verified: Play Mode in the real app (no Unity here).

## Round 4 — Play Mode feedback (real app) and quality pass
Findings from Unity Play Mode: (1) module names / captions printed on the brass faceplate were nearly
invisible; (2) the big brass plates read as flat mustard, not brushed brass.

**(1) Print.** Cause: the app's text roles (`ui.text`/`ui.textDim`, and the chrome/track roles derived from the
key MARK) were cream or key-dark, not the plate print. The rack sheet could not show it (it printed captions in
`ink.faceplate`), so I added `python Tools/looks/walnut_brass.py printcheck` (WCAG contrast of every app print
role on the plate it lands on) and measured the *rendered* plate pixels under each rack-sheet caption.
Dark mode print on brass is now an engraved brown: `ink.faceplate` / `ui.text` #2B1D0C, `ink.faceplateDim` /
`ui.textDim` #46311A (slightly darker than the suggested #5A4326, because the brass foot under "FADER" measured
2.2:1 with #5A4326). Walnut plates, header and track lanes take cream via explicit `ink.inset/backplane/socket/
reviewBar`, `chrome.*` and `tracks.*`. Measured on the final sheet (plate pixel vs ink):
MASTER 5.1, PRESSED 4.8, FADER 3.5, PADS 5.1 (dim ink); every `printcheck` pair >= 3:1 in both modes.
**(2) Brass.** Metal grain 2.2 px @ 0.24 (p1 0.5, p2 0 = longest streaks), spec 0.9 / rough 0.2, a
bright-top / dark-foot ramp (0.2, 0.45) and plate ambient 1.1 (0.62 rendered the plate (108,92,48), which is dark
olive, not brass; it now renders ~(190,160,85) with a visible horizontal brush at 1:1 and 3x). Walnut grain
0.55 @ contrast 1.05. The champagne plate in light mode had inherited the brass grain by a deep merge — it now
has its own fine Metal grain.
**Control separation.** A bright plate pulled the aluminium controls toward it (Button ΔL 2, hero −52). Control
ambient 0.8 → 1.2 on keys and caps restores it: Knob +143, KnobSmall +150, Button +64, ToggleBtn +110 (dark);
Knob +78, Button +26 (light). KnobHero's *mean* step stays ~0 because the hero sits on brass and carries a dark
value track; it separates by its dark arc and bright cap, not by mean luminance (accepted). Slider fill
VALUE_EM 0.25 → 0.55 so the amber fill reads on the bright brass.
Clip 0.0% on every plate in both modes (the Face clipped 0.65-28% at plate ambient 1.15-1.3, so 1.1 is the ceiling).
Sheet fix (kit): the parts sheet's Plates/Screens bands now print their captions in the backplane ink (they
were dark-on-dark).
