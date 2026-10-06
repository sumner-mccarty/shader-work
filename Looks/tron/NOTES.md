# Tron — lookkit proof

Tron shipped from `Tools/design_tron.py`. `Tools/looks/tron.py` re-expresses it with the kit's
`neon` class (core / bloom / sheen tubes); mode-dependent weights (tube width, bloom, plate px,
the HexGrid) are palette tokens.

## Proof (`python Tools/looks/tron.py diff`)

* 46/46 states files (TronDark* + TronLight*) — byte-identical, including TronDarkFace, whose
  shipped key order (`_PanelPatternPx` last) differs from what design_tron.py emits today — the kit
  matches the shipped file.
* `Themes/Tron.theme.json` — byte-identical.
* `UiStyles/Tron.style.json` — JSON-identical; differences: the generated banner comment, and the
  hand-joined `pad.ringWhite`/`pad.ringBack` line (see Flat's notes).

## Rules

`check` → 0 errors, 1 waiver: **footprint:Dot** — TronDark/LightDot ship at `_ButtonPadding 0.1`
where the app's RackDot is 0.252, so the Tron scroll dot draws and hit-tests larger than the slot it
swaps for. Reproduced as shipped; dropping the `Dot` override in the spec would fix it (a visual
change — review in the app).

Note for the owner: the shipped light-mode blurb ("The Legacy cockpit…") and the Style name echo a
film title. Kept verbatim because the proof reproduces shipped data; worth renaming when convenient.
