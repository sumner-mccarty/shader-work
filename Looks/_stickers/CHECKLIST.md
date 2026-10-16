# Sticker pack critic — the SAME checklist every round

Score each item 1–10 with one sentence of evidence (which sticker, what you see). PASS = **every item ≥ 7**. Anything not
on this list goes under "notes", never into a score. From round 2 you also get your previous verdict: say what improved.
Judge the **32 px sheet first** (that is a sticker on a real plate), then the 96 px sheet for craft.

1. **Reads at 32** — every sticker is recognisable at 32 px; name the ones that aren't.
2. **Theme** — the pack as a whole is unmistakably its theme, and fun; a player would want to stick these on their gear.
3. **Silhouette** — bold, distinct outlines; no spindly parts, hairlines or specks that vanish at 32.
4. **House style** — matches the shipped packs (family sheet): flat bold shapes, dark keyline, one shade (lower-right),
   one highlight (upper-left), clean die-cut border.
5. **Color slots** — each layer is a meaningful part with a plain-word name (`layerNames` in the scratch manifest); the
   art would still read if any one slot were recolored.
6. **Variety** — a mix of objects, symbols, characters and words; no near-duplicates inside the pack; nothing that
   duplicates a sticker in a shipped pack.
7. **Craft** — the generator's tight list is empty; no clipped edges, slivers, misregistered layers or lumpy curves.
8. **Pro split** — the Pro third (`PRO_IDS`) is the showiest; the free set is still a complete, good pack.
9. **Safe** — no real brand, logo, product, band, artist, mascot or character; text ≤ 6 characters and only where it
   adds; nothing beyond PG-13.

## Verdict format
```
round N — PASS | REVISE
scores: reads32 8, theme 7, silhouette 7, style 8, slots 7, variety 6, craft 7, pro 8, safe 10
since last round: <what improved, what regressed>
fix first (max 3, concrete — sticker id and what to change): ...
drop (stickers that cannot be saved): ...
notes (not scored): ...
```
