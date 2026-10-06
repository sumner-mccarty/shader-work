# Flat — lookkit proof

Flat shipped from `Tools/design_flat.py` before the kit existed. `Tools/looks/flat.py` re-expresses
it as a lookkit spec (the `unlit` class, whose shape defaults ARE Flat's tuned values) to prove the
kit is complete. The spec is palettes + app-print overrides; nothing about the parts is restated.

## Proof (`python Tools/looks/flat.py diff`, or `write --root <scratch>` + `cmp`)

* 46/46 states files (FlatDark* + FlatLight*) — byte-identical.
* `Themes/Flat.theme.json` — byte-identical.
* `UiStyles/Flat.style.json` — JSON-identical. Intentional text differences:
  1. the banner comment names the new generator (`Tools/looks/flat.py`, `Tools/lookkit.py`) instead
     of `design_flat.py`, and drops a real product name from its first line (CLAUDE.md: never name a
     brand) — "DAW-style" instead;
  2. `pad.ring`/`pad.ringBack` were hand-added to the shipped file on one line; the kit writes
     them with `json.dumps(indent=2)` (one key per line).
* The kit's derived app palettes reproduce most print colours from part tokens; the spec carries
  only the 40-odd values that differ.

## Rules

`check` → 0 errors, 1 waiver: **light-controls** — Flat Light deliberately recolours the keys pale
(value-inverted daylight UI; every mark flips dark through `key.*`). The kit's rule says a light
mode changes the chassis, not the controls; Flat is the documented exception.

The legacy un-moded `Flat*.states.json` files (FlatButton, FlatKnob, … — 15 files) are not emitted
by design_flat.py either and are not part of the proof; they appear to be pre-mode leftovers.
