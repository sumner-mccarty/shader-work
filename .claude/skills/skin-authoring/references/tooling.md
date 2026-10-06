# The skin toolchain — file map and schemas

## Files

| Path | What it is |
|---|---|
| `Assets/Editor/SkinSheet.cs` | Editor-side offscreen renderer. `[InitializeOnLoad]` poller on `.skinsheet/job.json`. Reads states files from disk, renders with `Graphics.Blit`, writes PNGs to `.skinsheet/out/`. Also runs the real SkinForge bake on `{"bake": true}`. |
| `Tools/skinsheet.py` | Python driver: writes the job, waits for `done.json`, assembles annotated contact sheets with PIL. |
| `Tools/shaderprops.py` | Parses a `.shader` Properties block into the authoritative `{name: {type, range, default}}` table. The source of truth for validation. |
| `Tools/skinlib.py` | Authoring library. `skin(name, family, base, states, bounds=...)` emits a validated `.states.json`. Rejects unknown properties and type mismatches; flags RM-only properties that break RM/non-RM file sharing. `BOUNDS` holds pre-measured hit-test dicts per role shape (`knob`, `button`, `button_round`, `button_accent`, `slider`, `pill`, `panel`) — **pass one to every `skin()` call**; omitting `bounds` does not mean "no hit test", it defaults to a full-rect hitbox that steals input from whatever sits behind the control (see pitfalls.md). |
| `Tools/design_realistic.py` | The Realistic look, as a Python spec. |
| `Tools/design_others.py` | The first-pass Neo/Tron/Flat sets (`Neo*`, `Tron*`, `Flat*`). Flat's are superseded. |
| `Tools/design_neomorphic.py` | Neomorphic Dark + Light (`NeoDark*`/`NeoLight*`), derived per component. |
| `Tools/design_flat.py` | Flat Dark + Light (`FlatDark*`/`FlatLight*`): unlit, non-RM, every guard set. `write` / `check` / `sheet <mode> <tag>` / `recipe` (writes `Flat.style.json` too). |
| `Tools/design_tron.py` | Tron Dark + Light (`TronDark*`/`TronLight*`): unlit, non-RM neon tubes (border core + additive edge bloom + unlit bevel sheen). Same commands as `design_flat.py`; `recipe` writes `Tron.style.json` and reuses Flat's role/swap roster. |
| `Tools/build_recipes.py` | Emits `Tron.style.json` only. Realistic and Neomorphic are hand-edited and Flat is written by `design_flat.py recipe`; `HAND_OWNED` skips them so a re-run cannot clobber that work. |
| `Tools/bake.py` | Python port of `SkinForge.Apply`/`Bake`. Verified byte-identical to the C# over all 80 baked files. |
| `Tools/sheet_style.py` | Renders one style's whole part set at real sizes. |
| `Tools/sheet_rack.py` | The cohesion test: composites parts onto a faceplate as a rack strip. Takes `<Style> <dark\|light> [neutral]`. |
| `Docs/Skinning/Params-*.md` | Exhaustive per-shader property references, code-derived. |

## Job schema (`.skinsheet/job.json`)

```json
{
  "out": "D:/repos/audiogame/.skinsheet/out",
  "bake": false,
  "rig": { "light1": {"pos":[0.15,0.85],"height":0.75,"color":"#FFFFFF",
                      "intensity":0.85,"specular":0.12},
           "light3": {"enabled": false} },
  "cells": [
    { "id": "knob-hero-0",
      "states": "D:/.../RealisticKnobHero.states.json",
      "shader": "UI/SDFKnobRM",
      "w": 132, "h": 132,
      "ss": 2,
      "shadow": 2,
      "state": "Normal",
      "set": { "_Value": 0.4 },
      "pos": [0.5, 0.5],
      "bg": "#15181C" }
  ]
}
```

- `ss` — supersample factor. Output PNG is `w*ss × h*ss`.
- `shadow` — when > 1, renders the widget's cast pass on an N× frame (as `WidgetShadowQuad` does)
  and composites the widget into the centre. Output is `w*ss*N × h*ss*N`. **Panels should not use
  it** — they are the surface, and their own shadow just draws a second silhouette behind them.
- `state` — a state name or a comma-separated stack (`"Normal,Hover"`), resolved through the base
  chain exactly as `MaterialStateEngine` does.
- `set` — per-cell property overrides applied last. This is how one skin file becomes a
  0%/40%/80% row.
- `pos` — the control's normalized screen position, which is what decides how the lamp falls on it.
  Fixed at centre by default so a sheet compares skins rather than positions.
- `rig` — optional light-rig override; omit to use the shipped rig from
  `Resources/Themes/Realistic.theme.json`.

Non-render jobs (one key each): `{"bake": true}`, `{"rebuildPacks": true}`, `{"dumpRects": true}`,
`{"countPanels": true}`, and for driving a Play-Mode capture without UI clicks (2026-09-14):
`{"play": true}` (enters Play with the Game view maximized), `{"stop": true}`,
`{"applyLook": "Tron Dark"}` (SkinMode.ApplyLook — ⚠ persists the user's default look, restore it),
`{"nav": "EnterEditor"}` (any AppNav static), `{"call": "SkinMode.OpenStudio"}` (any `Type.Method`
whose parameters default). All by reflection, so the editor assembly references no view code.

Reply lands in `.skinsheet/done.json` as `{"ok":N,"fail":N,"log":"..."}`.

## ⚠ The shared shadow buffer will corrupt panel renders if you touch this harness

Panels sample the global `_UIShadowBuffer` (gated by `_ReceiveSceneShadows`, **on by default**) so
any widget can cast onto any panel regardless of hierarchy. In the app a capture camera fills that
texture every frame. Offline there is no capture camera, so whatever was last bound stays bound —
in practice **the silhouettes of controls rendered in EARLIER cells of the same job**, which show
up as mysterious dark blobs and rounded-rect ghosts scattered across an otherwise bare plate.

`SkinSheet.cs` now binds a 1×1 white texture (`white` = "nothing above me") before each render.
If you ever see unexplained soft dark shapes on a panel that are not in its states.json, check that
binding first — it is not a skin bug and not a shader bug. Every panel render made before this fix
was contaminated.

**The same buffer bleeds between SCREENS in the app (2026-09-14).** It is one screen-space texture, so
controls hidden BEHIND a full-screen overlay still cast into it, and the overlay's own plates sample
it: Skin Studio's pale Neomorphic Light card showed a soft smear with a hard vertical edge — the
creator's knobs behind the sheet — and was spotless when opened over the main menu. Fix:
`WidgetShadowQuad.ExclusiveRoot` (only casters under it draw); SkinStudioPanel claims it while the
sheet is shown and releases it on peek/disable/destroy. Any future full-screen overlay with lit
previews should do the same. Diagnose by re-opening the overlay over a different screen.

## Composite placement gotcha

A cell rendered with `ss` and `shadow` comes back at `w*ss*N`. When compositing into a layout you
must undo BOTH: resize to `w*N`, then offset by `-w/2, -h/2` to back out the shadow padding.
Forgetting `ss` draws everything at 2× and looks like a layout bug rather than a scaling one.

## Roles → authored skin suffixes

Family-level `$base` covers the common case; these roles override it:

```
pad→Pad  button.accent/hero→Accent  toggle.button→ToggleBtn  button.close→Close  lamp→Lamp
knob.hero→KnobHero  knob.small→KnobSmall  (knob.large/medium fall through to the family base)
panel.faceplate→Face  panel.inset→Inset  display.well→Well  panel.backplane→Back
```

Style id and skin-name stem can differ (`Neomorphic` style → `Neo*` files); `build_recipes.py`
takes a `prefix=` argument for that, and `sheet_rack.py` keeps a `SKIN_PREFIX` map.
