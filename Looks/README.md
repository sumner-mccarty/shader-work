# Looks — one folder per look

A **look** is a complete DrumSumDrum skin set: every rostered control and plate, in a dark and a
light mode, plus the recipe that tells the app which skin fills which slot. The app discovers a look
automatically from `Assets/Resources/UiStyles/<Style>.style.json`.

## What a finished look contains

| Path | What |
|---|---|
| `Tools/looks/<module>.py` | the look SPEC (see below) — **the source of truth**; `Tools/lookkit.py` writes everything below from it |
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

## The look spec (`Tools/lookkit.py`)

A look is a ~150-line **spec**, not a generator. `Tools/lookkit.py` owns everything that is the same
for every look — the 23 part builders per mode, the roster (roles, families, by-name swaps), app
palette derivation, display map, rig and recipe writers, the rule audit, the rack/parts sheets and
the CLI. Start from the closest spec: `Tools/looks/flat.py` (unlit), `Tools/looks/tron.py` (neon) or
`Tools/looks/example_lit.py` (lit — a template, never shipped).

```python
import sys; from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from lookkit import Look, main

LOOK = Look(
    title="Gold Leaf", style="GoldLeaf", prefix="GoldLeaf", slug="gold-leaf", cls="lit", order=7,
    blurb="One line for Skin Studio.", tagline="first line of the recipe banner", note="more banner text",
    modes={
        "dark":  dict(track="Nebula", blurb="...", palette={...tokens...}, app={...overrides...}),
        "light": dict(track="Rosewater", blurb="...", palette={...}, app={...}),
    },
    shape={"key": {...}, "dial": {...}, "fader": {...}, "switch": {...}, "plate": {...},
           "<Slot>": {...}, "shadow": {"blur": 1.4, "cast": 0.22}},       # form language
    material={"plate": {...}, "key": {...}, "cap": {...}, "skirt": {...}, "handle": {...}},   # lit
    rig={"dark": {"light1": {...}, "light2": {...}, "light3": {...}}, "light": {...}},     # lit
    displays="neo",                  # a finish family (flat/neo/tron), or a full {authored: finish} map
    colourways={"Emerald": dict(palette={"dark": {...}, "light": {...}}, app={"dark": {...}})},
    waive={"<rule>:<Slot|token>": "why this look must break the rule"},
    track_themes={"MyTrack": {...a TrackThemes json...}},                # optional
)
if __name__ == "__main__":
    sys.exit(main(LOOK))
```

| Field | Meaning |
|---|---|
| `cls` | `unlit` (Flat's rules: non-RM, `_LightingUnlit 1`, value steps), `neon` (Tron's: unlit light tubes — core/bloom/sheen), `lit` (UI/*RM under the look's rig; the Realistic/Neo/RackFaceplate vocabulary). Each class documents its palette tokens (`TOKENS`) and shape defaults (`SHAPE`) in lookkit.py. |
| `palette` | Per-mode tokens the class reads (`FACE`, `BODY`, `ACCENT`, `VALUE`, …). A missing required token is an error; optional ones are derived (`PALETTE_DEFAULTS`). App-print tiers `INK` / `INK_DIM` / `PRINT_DIM` default to `MARK` / `MARK_DIM`. Neon keeps mode-dependent weights (`LINE`, `BLOOM`, `GRID`, plate px) in the palette. |
| `shape` | Form language, resolved **class group < spec group < class slot < spec slot**. Groups: `key` (corner, round, bevel, depth, dome, icon…), `dial` (`silhouette` needle/capped/cap, px, arc_px, skirt = a KnobShapeType name, cap_r, dome, nub…), `fader`, `switch`, `plate` (radius_px, pad_px, recess…). Slots: `Button Accent ToggleBtn Solo Lamp Close Chip Dot ScrollHandle Pad Knob KnobHero KnobSmall Slider Fader Pill Face Inset Socket Well Back Bezel ScrollTrack`. `pad` is the footprint — leave it. |
| `material` | Lit only. Per surface (`key`, `accent`, `cap`, `skirt`, `handle`, `plate`, `pad`, or a slot name) name a **preset** from the material library — `"gold.polished"`, `{"preset": "enamel", "tint": "#1F7A52"}`, `{"preset": "lacquer.black", "edge": "gold.polished", "amb": 0.8}` — which brings the colour ramp (fake reflection), edge band, px-derived pattern, spec/roughness, dome, bevel and ambient. Presets: gold.polished, gold.brushed, gold.rose, chrome, aluminium.brushed, brass, copper, lacquer.black, enamel, plastic.gloss, rubber.matte, wood.oiled, leather.tooled, marble, ceramic, glass.frosted, fabric.velvet, carbon, concrete — see `Looks/_materials/` (swatches + tuning notes + known limits). A plain dict without `preset` is the legacy pattern-only form (`pattern`, `scale`, `px`, `intensity`, …). A mode may re-tune its materials with `modes[mode]["material"]`. |
| `app` | Overrides on the DERIVED app palettes (`chrome`, `ui`, `surface`, `ink`, `display`, `key`, `pad`, `review`, `tracks`). Derivation already covers the pale-look pieces (`ink.key` only on pale keys; `review.slot/slotFill`, `tracks.noteSeparator` on pale lanes). `None` deletes a key. |
| `rig` | Lit only: lamps per mode → `Themes/<Style>{Dark,Light}.theme.json`. Unlit/neon always get `Themes/<Style>.theme.json` with every lamp off. |
| `waive` | The only way past a rule. The reason prints on every `check`, so the exception gets reviewed. |

```bash
python Tools/looks/<module>.py check       # build in memory + audit every rule (0 errors before anything else)
python Tools/looks/<module>.py sheet       # Looks/<slug>/sheets/{rack,parts}-{dark,light}.png
python Tools/looks/<module>.py write       # MaterialStates, UiStyles recipe, Themes rig (refuses with errors)
python Tools/looks/<module>.py diff        # byte-for-byte against what is on disk (--root DIR for a scratch tree)
python Tools/looks/<module>.py manifest    # Looks/<slug>/look.json
python Tools/looks/<module>.py selftest    # break each rule on a copy and confirm `check` catches it
python Tools/lookkit.py materials          # the material swatch sheet (Looks/_materials/swatches.png)
#   --colourway <Name|all> acts on a declared colourway (its own Style, prefix <Prefix><Name>)
```

**Rules the kit enforces** (`check` errors): bounds on every part; every effect guard written; the
footprint (`_ButtonPadding`/`_BgPadding`) equals the app skin each part swaps for; `_ButtonLipHeight`,
`_KnobLipHeight`, `_HandleLipHeight` authored 0 on RM parts; `_LightingShadow1Enabled` explicit on
knobs; knob bevel inside the cap; plates never domed, bevel distance ≤ 0.14, no bevel on a lit look's
Face/Back; every patterned plate pixel-locked; value arc `_LineRadius + _LineWidth` ≤ 0.88 (0.92
with square ends); a light mode moves no control token (`BODY`, `ACCENT`, `CAP`, `HANDLE`) by ≥ 0.3
luminance; every mode names an existing track theme; every shader key validated. The sheets
composite slrender's premultiplied cells exactly (`src + (1 - a) · dst`), so an AA edge never grows
a dark outline and a neon bloom stays additive — no per-cell `bg` hacks. The rack sheet also MEASURES
what FACTORY asks for: each plate's clipped-pixel % (a light-mode plate must stay < 1%) and each
control's luminance step off its plate (dark controls must separate from dark plates).

The proof that the kit is complete: `python Tools/looks/flat.py diff` and `tron.py diff` reproduce
every shipped FlatDark*/FlatLight*/TronDark*/TronLight* part and both rigs byte-for-byte; the two
recipes are JSON-identical (only the generated banner comment and one hand-formatted line differ).

## The gate (a PR is not ready until all pass)

```bash
python Tools/looks/<module>.py check     # 0 errors: the kit's rule audit
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
the gate and rubric points 3–5. In a spec: `colourways={"Emerald": dict(palette={"dark": {...},
"light": {...}}, app={"light": {...}})}` → Style `<Style>Emerald`, prefix `<Prefix>Emerald`, built with
`--colourway Emerald` (or `all`).
