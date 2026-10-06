# Factory run 2026-10-06 — stopped early (3 rejections in a row)

Accepted: **0** of 8. No PR opened (nothing accepted). Work is preserved on this branch as drafts for review.

| look | status | last critic scores (identity/story/legib/craft/states/light/fidelity) |
|---|---|---|
| graffiti | rejected (2 revisions) | 7/6/8/6/7/7/6 |
| honky-tonk | rejected (2 revisions) | 6/7/6/6/6/7/6 |
| boom-box | rejected (2 revisions) | 8/7/7/6/6/5/7 |
| marble-rose | draft — revision 1 was cut short mid-round when the stop rule fired (files may be partly revised) | 7/6/6/5/7/6/5 |
| carbon-race | draft — judged once, REVISE, not revised | 7/6/7/5/7/6/6 |

## What is causing the rejections
1. **The accept bar is hard to reach in 2 rounds.** PASS needs every score >= 7 and identity >= 8. Nobody got craft >= 7 in any look; light-mode and craft are the recurring weak spots. The critic is a fresh instance each round and raises new items (goalposts move), so builders chase new problems instead of converging.
2. **Kit gaps force per-look workarounds** (all builders reported them, lookkit.py untouched):
   - `unlit` class has no state-aware gradient vocabulary (graffiti subclassed the part builders); `set` is per-slot not per-mode (honky-tonk subclassed Look); neon class hardcodes tube emissive.
   - `lit` kit paints every key from one BODY token, so per-role cap colours need a subclass (boom-box).
   - Pad/track colours come from the app's track-theme rows, not the skin, so builders cannot control pad hue (boom-box, honky-tonk, carbon-race); the light/dark track choice changes pad colours and was mistaken for a control recolour.
   - Pattern grain units differ per pattern (CarbonFiber period = scale*5, kit default aliases); marble tint can only multiply (needs a preset for gold veins); no `_PanelPatternOffset` writer; no taper control on ChickenHead; gradients repeat rather than clamp (no hard bands/drips).
3. **Prompt L asks for "at least 3 rounds" and a 25%-zoom identity read, but the builders were slow** (4 cores shared; first sheet ~10 min), and often did not open their own sheets/30 px knob until told to.
4. **Same defects recur across looks** — light mode that is not a chassis change (boom-box, honky-tonk), muddy/unlit-looking pad states (all), hover≈normal, dark tracks vanishing. These belong in the kit/prompt as defaults, not per-look fixes.

## Suggested changes before the next batch
- Put the recurring defects into Prompt L as a checklist (pad hover/pressed/latched distinct; track visible at 30 px; light mode = chassis only; no clipped glow at quad bounds; fill empty plates).
- Give the critic a fixed checklist (and its previous verdict) so revisions converge; consider allowing 3 revision rounds, or lowering "identity >= 8" to >= 7 with all others >= 6.
- Extend lookkit: per-role key colours, per-mode `set`, state-aware gradients for unlit, pad palette control, hard-edged gradient bands.
- Run builders with fewer than 3 in parallel on 4 cores, or accept ~10 min first renders.
