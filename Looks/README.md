# Looks — one folder per look

A **look** is a complete DrumSumDrum skin set: every rostered control and plate, in a dark and a
light mode, plus the recipe that tells the app which skin fills which slot. The app discovers a look
automatically from `Assets/Resources/UiStyles/<Style>.style.json`.

## What a finished look contains

| Path | What |
|---|---|
| `Tools/looks/<module>.py` | the generator — **the source of truth**; everything below is written by it |
| `Assets/Resources/MaterialStates/<Prefix>Dark*.states.json`, `<Prefix>Light*` | ~23 parts per mode |
| `Assets/Resources/UiStyles/<Style>.style.json` | recipe: roles, families, swaps, palettes, displays, rig |
| `Assets/Resources/Themes/<Style>[Light].theme.json` | the look's light rig (lit looks; unlit looks use all-off) |
| `Assets/Resources/TrackThemes/<Name>.track.json` | optional: the play-highway palette |
| `Looks/<slug>/look.json` | manifest (below) — what `Tools/import_to_unity.py` copies |
| `Looks/<slug>/NOTES.md` | design intent, each critique round, what was tried and rejected |
| `Looks/<slug>/sheets/` | `rack-dark.png`, `rack-light.png`, `parts-dark.png`, `parts-light.png` (+ device mocks) |

Name everything with the look's own **prefix** (`GoldLeafDark…`). A look never edits another look's
files, shipped skins, `Assets/Shaders`, or shared JSON (`UiThemes/ScopeFinishes.json`,
`UiThemes/Palette.json`) — that keeps parallel look PRs conflict-free. Screens map onto the existing
display finishes (`flat.*`, `neo.*`, `tron.*`, authored hardware) via the recipe's `displays`.

```json
{
  "slug": "gold-leaf",
  "style": "GoldLeaf",
  "title": "Gold Leaf",
  "prefix": "GoldLeaf",
  "brief": "BACKLOG.md#gold-leaf",
  "class": "lit",
  "status": "candidate",
  "files": ["Tools/looks/gold_leaf.py",
            "Assets/Resources/UiStyles/GoldLeaf.style.json",
            "Assets/Resources/Themes/GoldLeaf*.theme.json",
            "Assets/Resources/MaterialStates/GoldLeafDark*.states.json",
            "Assets/Resources/MaterialStates/GoldLeafLight*.states.json"]
}
```

`status`: `draft` (work in progress) → `candidate` (passes the gate, PR open) → `approved` (you merged
it after review) → `shipped` (imported into audiogame and checked in Play Mode).

## The gate (a PR is not ready until all pass)

```bash
python Tools/lookcheck.py <Style>        # 0 errors: full roster, bounds, valid params, every part renders
python tests/test_basics.py              # renderer contract still holds
```

## The quality rubric — critique every round against this, in NOTES.md

1. **Identity in one second.** At 25% zoom, the rack reads as THIS theme and no other. Put the
   rack next to the shipped looks and approved looks (`slrender contact Looks/*/sheets/rack-dark.png`)
   — it must differ in at least two of: material family, form language (corners/bevel/knob type),
   lighting class (lit / unlit / neon), palette structure (value + temperature).
2. **One material story.** Every part is made of the same world. One shadow contract (colour,
   blur, cast) across the set, or parts float at different heights.
3. **Legible before beautiful.** Values 0/40/80/100% distinguishable at the SMALLEST size the part is
   used (knob.small 48px); ON vs OFF obvious at a glance; plate print readable (palette `ink`).
4. **Craft.** No medial-axis wedges on plates, no chrome bars on plate bevels, no dotted lip seams
   (`_ButtonLipHeight 0`), no clipped highlights, no grain that aliases at 1:1 (judge `ss` 1).
5. **States.** Hover, Pressed, Disabled and (latching parts) Active all visibly differ.
6. **Light mode changes the chassis, not the controls** (unless the brief demands otherwise).
7. **Theme fidelity.** The brief's signature motifs are present and tasteful — reference, not
   costume. Never a real brand's name, logo or trade dress.

Judge only renders in the app's **screen** orientation (slrender's default) — never the Unity
SkinSheet's bevel direction, which is inverted.

## Colourways

A look may declare colourways (same structure, new palette — e.g. Gold Leaf on black / ivory /
emerald). Each colourway ships as its own Style so it appears in Skin Studio; it must still pass
the gate and rubric points 3–5.
