# Faceplate Decor — paint, stickers, wraps, live backdrops  *(rev 3, 2026-10-09 — BUILT)*

Also the home of the two Skin Studio tools built in the same run: **color sets** (§8) and **arrange** (§9).

> Supersedes the two-layer plan in `Docs/UiDecals.md` §1–§9 (its §11 generator reference still stands).
> User direction 2026-10-09: *"nothing covers buttons, displays, etc, but it's like you took the faceplate
> off — it is above label text and blended with edges so the edge of the shader still looks like it's the
> shadow of a painted/stickered [plate]."* Reference photos: an MPC Studio in an ice-cream sticker wrap, a
> mixer faceplate printed with a tiger.

## 1. The one decision: decor lives IN the faceplate

Everything the user adds — paint, stickers, wraps, splats, tape — is composited into the **plate
surface itself**, inside `UI/SDFPanel`, before the plate is lit. Consequences, all of them wanted:

| Requirement | How it falls out |
|---|---|
| Never covers buttons, knobs, pads, displays | Controls and displays are separate graphics drawn **after** their plate. Decor cannot reach them. |
| Above the label text | Plate print (TMP labels whose nearest plate is decorated) switches to `TextMeshPro/Mobile/Distance Field Decor`, which multiplies its ink by `1 − decor coverage`. Translucent spray lets print ghost through. Per panel **"Reprint labels"** puts the print back on top, the way real vinyl skins reprint the legends. |
| Blended with the edges | Decor replaces the plate's ALBEDO — on the face AND the bevel band (applied after the bevel's own gradient/pattern colouring, before lighting). The plate's bevel normals, rim, recess walls, border, screws and the controls' cast shadows (`_UIShadowBuffer`) all shade it afterwards: a sticker that reaches a plate edge rolls over the bevel and darkens with it. |
| Cut by the holes | The faceplate-off model, literally (§2.5): every mounted part — key, knob, pad, lamp, slider, LED well — is an APERTURE, and decor is trimmed at it with a knife margin; screw heads (which go back in after decorating) sit in trimmed rings of bare plate. The cut vinyl has thickness, so its edge catches the lamp and drops a shadow. |
| Survives docking / resizing / variants | Decor is anchored per item (9-point panel anchor or a control) in canvas units, re-rendered when the panel's rect changes. Because controls always draw on top, a re-flow can never put paint ON a control — at worst a sticker ends up partly under one. |
| Survives look changes | Decor belongs to the PANEL (your gear), not the look, and is rebound after every `PanelFactory` rebuild. Optional per-look scope. |
| Costs nothing idle | One set of render textures per decorated panel, re-rendered only on edit/resize/light change. Undecorated plates take a uniform branch. |

## 2. Rendering

### 2.1 Decor space
A **decor group** = one panel view root (or its scroll content, so paint scrolls with the modules).
Decor space = the group rect in canvas units, origin bottom-left. Items carry an anchor
(`[ax, ay]` in 0..1 of the group rect, snapped to 0/0.5/1 at placement, or a control path) plus an offset,
rotation and scale in canvas units — so a sticker near the top-right corner stays near it when the
panel grows.

### 2.2 Generation (per group, 4 MRTs, one-command CommandBuffers)
Every draw is a tiny `CommandBuffer` that names its own targets and view/projection — NOT
`Graphics.DrawMeshNow`, which inherits whatever `Camera.current` a manual `Camera.Render()` elsewhere left
behind (the Studio's capture cameras) and then lands every mesh off the target. That was the "Studio's
preview plates are bare" bug: the rack happened to render on frames with a harmless leftover camera.

| RT | Content | Blend |
|---|---|---|
| `albedo` ARGB32 | premultiplied paint colour, a = coverage | over (One, OneMinusSrcAlpha) |
| `mat` ARGB32 | premult (gloss, metal, holo), a = coverage | over |
| `fx` ARGB32 | premult (glitter, emissive, ‑), a = coverage | over |
| `height` R8 | paint / vinyl thickness | additive (erase multiplies down) |

Item shaders (`UI/Decor/*`, all write the 4 targets): **Stroke** (ribbon mesh, 10 brush kinds),
**Splat** (port of `UI/Decal/Splat`), **Sticker** (layered-SDF art atlas + procedural shapes + text),
**Wrap** (procedural full-plate fills), **Erase**.

### 2.3 Resolve (one pass, 2 MRTs) → what the plate samples
* `_DecorTex` = `albedo` as-is.
* `_DecorSurfTex` = (normal.xy from the height field's Sobel, gloss, metal) — demultiplied.
* `_DecorFxTex` = (holo, glitter, emissive, **cast shadow**). The shadow is height-field ray-marched toward
  the rig's key light, so every sticker edge and thick paint ridge drops a soft shadow in the lamp's
  direction — the "shadow of a painted/stickered plate".

Re-resolved when the rig changes (lamp moved, look switched).

### 2.4 In `UI/SDFPanel` (section 4, `CG/Core/UIDecor.cginc`)
`decorUV = affine(IN.worldPosition.xy)` (canvas space → group uv, two float4s, rotation-safe). Where
coverage > 0: albedo ← paint; normal ← normal + paint relief; specular ← gloss; plate glass/matcap faded out
under paint; then metal (matcap or studio env), holo rainbow, glitter glints and emissive glow on top;
cast shadow multiplies plate and paint alike. Panel alpha → opaque under paint (glass looks).

### 2.5 Apertures & hardware — "like you took the faceplate off" (user direction, 2026-10-09)
*"Make sure we don't ignore the original bevels, edges, etc … it really looks like I stuck the sticker on, some
of it got cut off by the hole for the button/knob, but I can see the sticker get dark by the edge component."*
* **Holes** (`DecorRenderer.Hole`, `UI/Decor/Hole`): on rebind `DecorSurface` collects every
  `MaterialStateController` in the group that is not a paintable plate (and doesn't hold one) — keys, knobs,
  pads, lamps, sliders, LED wells. Each one's aperture is its OWN body outline, from the skin's hit bounds
  (`LoadedBounds`: a circle, the width/height fractions, or the `paddingParam` inset), plus `HoleMargin`
  (2 canvas units of bare plate — the knife margin). Holes are erased from all four targets AFTER every item
  (and the ghost being placed), so the height field steps at the cut: the resolve gives the vinyl edge a lit
  lip and a cast shadow. Recomputed every 4 frames and hashed; a part that is moved, resized, hidden or
  reflowed re-cuts the decor. A whole pad matrix in a well is one aperture — exactly an MPC's faceplate cutout.
* **Screws** (SDFPanel §4, `UIDecorTrim`): the screws go back in after decorating, so decor is trimmed in a
  ring of `1 + counterbore + 0.45` head radii around each head (the same centres §6.5 draws — computed once,
  `panelScrewCentres`), with a thin shadow lip just outside the cut.
* **Bevels & seams**: decor is applied after the bevel band's colouring, so it wraps the plate's edge; where a
  sticker crosses the seam between two plates the gap and both bevels show through it as a crease.

## 3. Data — `ui/decor/<panelType>[@<look>].decor.json`
```jsonc
{ "version": 2, "panel": "DrumPad", "reprint": false,
  "items": [
    { "id": "w1", "kind": "wrap",   "wrap": "tiger", "colors": ["#F28C1A","#120C08","#F6E7C8"], "scale": 1, "rot": 0, "seed": 3 },
    { "id": "a1", "kind": "stroke", "brush": "spray", "color": "#FF2D6F", "finish": "gloss", "width": 18,
      "anchor": [0.5,0.5], "pos": [0,0], "rot": 0, "scale": 1, "pts": [x,y,p, x,y,p, …] },
    { "id": "s1", "kind": "sticker","art": "sweets/cone", "colors": [...], "finish": "holo", "size": 90,
      "anchor": [1,1], "pos": [-60,-50], "rot": -8, "peel": 0.3, "border": 1 },
    { "id": "p1", "kind": "splat",  "seed": 12, "color": "#FFD400", "size": 120, "throw": 25, … } ] }
```
Order = paint order. Engine-free model in `DrumSumDrum.Core.Decor`; realizer in `UiPipeline/Decor*`.

## 4. Editing — PAINT mode (inside Skin Mode)
* Entered from the Skin Mode bar (**PAINT**) or the Studio's **PAINT** step. The Studio sheet hides; the
  whole app is the canvas. A floating **dock** carries tools, size/opacity, colour, finish, undo/redo,
  labels covered/reprinted, scope, revert, save, done.
* Tools: **Select** (move / rotate / scale / duplicate / delete / order), **Brush**, **Marker**, **Spray**,
  **Chalk**, **Pen**, **Neon**, **Tape**, **Pinstripe**, **Drip**, **Splat** (click = throw, drag = aim),
  **Sticker** (library drawer, drop + handles), **Wrap** (click a panel to wrap it), **Eraser**.
* Pointer over a panel highlights the decor group; presses go to the tool, never to the app.
* Undo/redo across panels (global history of `(panel, before, after)`), **Save** writes files,
  **Revert** returns to the last save, unsaved changes prompt on exit.
* A drag is ONE undo step *(2026-10-16)*: a MIX colour drag and the decor sliders (sticker PEELED CORNER / GRIME / AIR
  BUBBLES, wrap PATTERN SIZE / ANGLE — `DecorDock.HeldSlider`) hold the store (`DecorStore.BeginHold`) from the drag's first
  change until the finger comes off (or a hex is typed), so every `Mutate` in between still lands live but folds into one step
  per panel. Undo/redo end a hold first; revert, leaving paint mode, closing the picker, dock rebuilds and a slider disabled
  mid-drag (`DecorSlider` reports the release) never leave one open. Wrap slots use the same `ColorSlotStrip` as stickers now
  (a pick recolours the chip in place; the drawer is no longer rebuilt per MIX frame).
* Keys: B/M/S/K/P/N/T/D/X/V/E tools, `[` `]` size, Ctrl+Z / Ctrl+Shift+Z, Del, Esc.
* Studio ▸ PAINT also carries a **STICKERS · PEEL ONE OFF** sheet under the wraps (2026-10-10: the STICK tool was
  only on the dock's second row, and a page of wraps with no stickers beside it read as "sticker bomb or nothing").
  A tile starts paint mode with the STICK tool armed and that sticker in hand.
* **Sticker COLORS** *(2026-10-16)*: the sticker drawer (placing, and a selected sticker) has one colour slot per art layer
  (`Sticker.Slots`: `layers`, up to 4; procedural shapes 3 = print top, print bottom, keyline). Click a slot, then a swatch
  or MIX fills it — the wrap drawer's pattern, built on the reusable `ColorSlotStrip` (DecorUi.cs: N slots + a getter + a
  setter, meant for avatar parts next). Slot 0 → `color`, 1..3 → `colors` (`DecorItem.SetColor`; "" = the art's own), so the
  file format is unchanged. A selected sticker's edits go through `EditSelected` (undoable); placing colours live in
  `DecorPaintMode.StickerColors`, tied to the art in hand. **SHUFFLE** keeps slot 0 and derives the rest
  (`DecorCatalog.Harmony`); **MATCH RACK** writes palette roles (`RackRoles`: `@ui.accent`, `@ui.textDim`, `@ui.text`,
  `@surface.card` — roles every palette has), which follow the look: `DecorSurface` redraws role-coloured decor when
  `Palette.OnChanged` fires (`DecorCatalog.PaletteGeneration`). Tooltips name the layer from the manifest's `layerNames`
  (`Tools/decor_stickers.py` takes them from the art's own variable names; `--names` refreshes them without touching pixels).
  Bus: `DecorDev.Colors` (`select DrumPad 0; arm 2; pick #FF2D6F; mix 12; shuffle; match; original; undo; report` —
  `report` prints the undo depth).

## 5. Free vs Pro (`ProGate.Feature.SkinPainter`)
Free gets a full kit: Brush, Marker, Spray, Pen, Splat, Eraser, Select; matte / satin / gloss; the **Street**
and **Sweets** sticker packs and the procedural shapes; solid / gradient / radial / camo / checker / racing /
polka / hazard wraps; swatches + the look's own colours + a custom mixer.
Pro adds Chalk, Neon, Tape, Pinstripe, Drip, Glitter gel; metal, chrome, holo, glitter and glow finishes; the
Music, Space and Retro packs; every other wrap (tiger, flames, sticker bomb, carbon, holo, marble …); decor
per look. Everything can be TRIED; only keeping Pro items asks (`DecorPaintMode.SaveRespectingPro`).

## 6. Live backdrops — the BACKDROP step
`BackdropEditMode` (Skin Mode bar ▸ BACKDROP, Studio ▸ BACKDROP): 13 kinds (water/caustics, aurora,
synthwave, lava lamp, nebula, rain + the original fields), each an animated gallery tile; every colour and
range property of the shader becomes a chip or slider automatically. APPLY TO MY LOOK forks the look
(`SkinDraft.Editable`), writes `<Look>Backdrop` as a user skin and points the look at it; SHOW BETWEEN PANELS
clears `surface.gap` so docked panels float over it. All five new fields keep the exactly-periodic time
contract (`UIBackdropFlow.cginc`) and read `_UIBeat` (not yet fed by pad hits).

## 7. Status (2026-10-09)
Built and verified in Play Mode through the SkinSheet bus (`DecorDev.Stage/Paint/Holes/Report`,
`ArrangeDev.Run`, `ColorEditMode.Dev`): decor core, apertures + screw trim + bevel wrap, PAINT mode + dock +
drawers, 58 stickers in 5 per-pack arrays (§7b), 28 wraps, BACKDROP editor, Studio PAINT/BACKDROP/COLORS steps, colour sets,
arrange. Open: text stickers, image import (Pro), control-pinned anchors, `_UIBeat` feed, flipbook captures.

## 7b. Sticker packs — one array per pack, and packs as content *(2026-10-11)*
The shared atlas (58 of 64 slots, one client release per new pack) is replaced by **one `Texture2DArray` per pack**
(`Resources/Decor/Packs/<id>.png`, flipbook-imported, 8 columns × n rows of 192² tiles; `Sticker.Slice` is pack-local) and
`stickers.json` v2 (per pack: `atlas`, `rows`, `rev`; per sticker: `pro`). `DecorRenderer.DrawSticker` binds the sticker's own
pack's array. `Tools/decor_stickers.py` also writes the CDN set to `Builds/StickerPacks/` (`index.json` + `<pack>.<rev>.png`,
`rev` = hash of the pixels). **`StickerPackStore`** fetches that index in the background at boot, caches new/changed packs under
`persistentDataPath/StickerPacks`, builds their arrays and swaps them into `DecorCatalog` (`Generation` bumps; decor surfaces redraw).
Offline-first: bundled packs, then cached, then the network only ever adds. A rig naming a pack the receiver lacks shows a star until
it lands (`StickerPackStore.Want`). Pro/free per sticker lives in the manifest, so re-balancing needs no build.
Cost/policy: `Docs/Release/05-Pricing-And-Storage.md` §3.

## 8. Color sets — `SkinTint`, `ColorEditMode` (Skin Mode ▸ COLORS, Studio ▸ ② COLORS)
The shipped looks are AUTHORED skins (`$base`) whose recipe `colors` are informational only, so recolouring
cannot be a recipe re-bake. A set is a group of parts (primary action, buttons, toggles & lamps, knobs,
faders, plates, screens — by role AND by authored skin, via the roster and swaps) and a channel: BODY (the
part) or LIGHT (a button's lit `Active` state, a knob's value arc, a fader's fill, a pill's LED). Editing is a
hue-preserving re-tint of every colour in that channel of every state relative to the set's key colour
(hue rotates, saturation and value scale), so bevels, gradients and Hover/Pressed shifts keep their
relationships; a neutral key (grey metal) takes the new hue on its neutrals and leaves accents alone.
* **Live**: dragging pushes the re-tinted skin into every control on screen with
  `MaterialStateController.ApplySkinJsonKeepingState` — the active states (a lit lamp) and live-driven
  params (a knob's value, a pad's row colour) survive the re-skin.
* **Keep**: on release, real skins are written to the user layer, the draft look (`SkinDraft.EditableQuiet`,
  a fork that renders identically, so no rebuild) points its roster/swaps at them, and the theme's `tint`
  record keeps each slot's ORIGINAL skin so a re-tint never compounds and RESET puts it back.
* **ACCENT**: one tap re-dyes every LIGHT and the primary keys (keeping their depth) and the UI accent.
Pads stay with the SKY (their row colours are live-driven per pad).

## 9. Arrange — `ArrangeFrame`, `LayoutNudge`, `LayoutTweaks` (roam mode)
Pick any control while roaming: 8 handles size it (corners keep the shape; Shift frees it, Alt sizes from
the centre), a MOVE grip shifts it off its layout slot, and smart guides snap edges, centres and sizes to the
neighbours and back home (Ctrl disables). Arrows nudge 1/10, +/− size, Home returns it, Delete hides,
Ctrl+Z/Ctrl+Y undo/redo every tweak. Everything is live on the real control (`LayoutElement` / `LayoutNudge`
re-flow this frame) and the release writes ONE patch op with no rebuild (`fixedWidth`/`fixedHeight` per axis,
`nudge`). `LayoutNudge` is an `ILayoutSelfController`, so the offset survives every reflow. The selection is
sticky across rebuilds (it follows the control's panel+path), and Studio ▸ TWEAK lists every changed panel
with a reset.


## 10. The booth — rigs in party mode *(2026-10-10, BUILT)*
User direction 2026-10-09: *"make decorating and styling the PD-48 a key social thing … party mode swap the skin
out for the other guy's skin when we are listening to them play … the non-active drumpads in the left and right
stage area floating like characters"*; then *"each user take over the screen like you were watching them from
their perspective (so it would also include the sky change)"*, *"hide it behind a UI effect 'Next Drummer!'"*,
and *"I designed my setup / PD-48 / stages with videos looping — a DJ booth they get to show off"*.

**A rig** (`Core/Decor/PadRig.cs`) is a player's PD-48 plus the perspective it is played in: every PD-48 part as it
RESOLVED on the owner's machine (`roster` by role, `classes` where a node disagreed), the text of any skin only
they have (`bodies` — COLORS re-tints, forks, imported packs), the PD-48 decor, plate print colours, row colours,
sky (resolved, never "Shuffle"), wallpaper + live backdrop skin, light rig, and two BOOTH SCREENS
(`UserContent.BoothScreens`, Studio ▸ BACKDROP ▸ YOUR PARTY BOOTH). Bots dress themselves from their id
(`PartyRigs.ForBot`: a shipped look, a sky, usually a wrap, 3–6 stickers on the visible metal).

**Wire.** `PartyMessageKind.Rig` (appended; protocol NOT bumped — an older build drops it and sees stock rigs).
gzip + base64, cut at 24 000 chars (`PadRigWire`) because API Gateway frames cap at 32 KB and the client sends one
frame per message; `PackFitted` halves stroke points (then drops the biggest strokes) until a rig fits 8 pieces.
The host keeps everyone's and hands the set to each newcomer. Sent once on joining; re-sent if it changes while the
lobby is open.

**`by` — who really sent it.** The relay stamps the sender of a frame from its connection, and presence messages
reach clients RELAYED BY THE HOST — so before this, every emote in an online room landed on the host's plate and
the creator's live tally credited the whole room's attempts to the host. The host now stamps the original sender
into a copy (`PartyMachine.Relayed`), and `PartyMessages.Origin` believes `by` only when the frame came from the host.

**On screen** (`Views/PartyStage.cs`, its own layers: crowd + screens at sortingOrder 500, curtain at 1500):
* **Whose booth** — RoundIntro and Create: the creator; VoteSnippets: the spotlight challenge's author; Awards /
  MatchOver: the MVP (`PartyScoring.Standings`, never a rule of its own); otherwise yours. Handed back a beat before
  Recreate, but only once the live monitor has drained (`PartyService.MonitorPending`).
* **The takeover** (`PartyCurtain`) — "NEXT DRUMMER · ROUND n — NAME — LOOK · WRAP · STICKERS": two slabs in the
  rig's row colours slam shut on the round sting, and the swap happens on the frame AFTER a fully covered frame was
  presented (any hitch lands on a frame nobody sees). Sky: `TrackThemes.Borrow`; wallpaper: `UiBackdrop.Borrow`
  (prewarmed when the rig arrived — the first draw of a shader is where a swap hitches); lamps:
  `UiSceneDirector.UseRigResource`; PD-48: the owner's puppet parked exactly over your PD-48's slot while your own
  content is hidden (no rebuild, no stale state, and your per-control skin picks can't leak onto their hardware).
  Your own round gets "YOU'RE UP"; a win you already own the room for
  gets "CHAMPION". Nothing borrowed is ever persisted; leaving the party or its screen puts everything back at once.
* **The crowd** (`RigPuppet`) — everyone but the booth's owner, as real live PD-48s built from the SHIPPED layout in
  their skins (`SkinResolver.RegisterTransient` + `UserContent.RegisterTransientSkin`, under a `rig.` prefix),
  wearing their decor (`DecorSurface.SetOverride`; `LocalUnits` so a scaled-down plate keeps its sticker sizes),
  floating either side of the track with a nameplate. They nod to whatever is sounding, flash a pad in their row
  colour under their own drummer's hits (live as hits arrive in the recreate race; as they sound for the listener),
  hop, glow, and pop emote bubbles. Two on a side stand staggered so nameplates never collide. Floating, their
  RectMask2Ds are switched off: the sway tilts them, and a tilted RectMask2D clips to the wrong box (it sliced the
  top bar and corner stickers off every rig); parked on the stage, untilted, they're back on.
* **Booth signs** (`BoothSign`, superseding the 2026-10-10 morning's `BoothScreen`) — see §10.2.
* **The bots are an audience** (`PartyServiceBotCrowd`) — they cheer the next drummer on, hype a performance that is
  actually happening, own up to their own scores, salute the champion and sometimes answer your reactions.

**Not yet:** importing a remote rig's custom light rig (shipped rigs only). Atlas-slot skins from user-imported packs
render with the receiver's bound atlas. Booth videos are fetched when the owner takes the stage, not prewarmed in the
lobby. A REPORT can't take a booth video down for everyone (it lives on its owner's host) — reports.mjs acts on the
account.

**Dev:** `{"call":"PartyDeck.DevQuickMatch","arg":"autoplay"}` over the SkinSheet bus starts a quick match vs 3 bots
with your turns autoplayed — the hands-free review loop. `{"call":"BoothMode.Dev","arg":"menu|sheet0|sheet1|paint|done|
demo|chips|unhide|diag"}` drives booth mode; `chips` gives bots' signs HIDE/REPORT so the chips can be seen solo;
`diag` dumps the backline racks (state + their photograph as PNG in `.skinsheet/out`).

### 10.2 Booth signs — a sign creator for each side *(2026-10-10, BUILT)*
User direction 2026-10-10: *"the two displays for each side support video but also be sticker/paintable boards with
separate border options (wooden, none, metal, etc) as well as glowing effects/backlighting… a sign creator of sorts"*;
*"up to 2 video links or choose from some video screen visualizers, or none"*; videos *"everyone by default with
friends only being an option… report/hide buttons yes"*.

**A sign** (`Core/Decor/BoothSignSpec.cs`; yours in settings.json `boothSigns`, via `UiPipeline/Decor/BoothSigns`)
is built back to front by `Views/BoothSign.cs`:
* **Light** — a backlight halo (`UiPrimitives.SoftBox`, 9-sliced so the fade keeps its width) and an optional NEON
  tube round the frame, in the sign's light colour, swelling with `UiBeat` and with the owner's hits.
* **Frame** — none, YOUR LOOK (the PD-48 faceplate skin), or a real lit plate from a shipped look (`BoothFrames`:
  walnut, oak, brass, silver, graphite, carbon, copper, marble, synth, rust), thickness 4–48.
* **Face** — `none` (no sign at all), `wallpaper`, `shader:UI/Backdrop/*` (13 visuals), `video:<https link>`, or
  `board` — `BoothBoard` recoloured live with a texture-layer surface (paper, canvas, velvet, plaster, frosted,
  leather, denim, glitter, terrazzo, smooth).
* **Glass** — `BoothGlass` over the picture: `_PanelRenderAlpha 0`, so it draws nothing but the decor bound to it —
  SDFPanel composites `lerp(panelAlpha, 1, decor.cov)`, i.e. PAINT AND STICKERS LAND OVER THE VIDEO.
* **Lettering** — up to 24 characters, mounted IN FRONT (outside the decor surface, so it is never re-shaded as plate
  print): neon (TMP underlay in the text colour, breathing) or print (a short drop shadow); Display / LED / Plain faces.
* **Decor** — each sign is a decor surface (`BoothSignL` / `BoothSignR`), built at 640×360 and scaled, with decor in
  LOCAL units so a sticker sits in the same place on every machine at every size.

Nodes are built in code with `userStates = true`, so a theme can never swap the chosen frame or the board.
Skins: `Tools/design_booth.py` (`sheet` renders boards over colours/surfaces).

**Video** (`Views/BoothVideo.cs`): a link only (`MediaLinks.TryNormalize` — Dropbox/OneDrive/direct; YouTube etc.
refused), STREAMED by every viewer straight from the owner's host (AVPro opens the URL; nothing goes through the
relay but the address) and played muted, looping, cropped to fill the face. Only if the stream errors or shows nothing
for 15 s does that viewer download it instead (`BoothVideoCache`: ≤60 MB, a web page refused by Content-Type) into
`temporaryCachePath/BoothVideo/` — deleted when the last sign using it lets go, when the party ends
(`PartyService.Leave` → `BoothVideoCache.PartyEnded`) and on app start. A booth video never lands in the media cache.
A local file never travels (`BoothSignSpec` drops non-web videos).

**Whose videos you see** (`BoothSigns.Videos`): EVERYONE (default) / FRIENDS ONLY (platform friends, matched on the
player's `steam:` avatar id or user id) / NOBODY; a blocked video shows the owner's fallback visual. Under every
other human's sign: **HIDE** (theirs → a neutral visual, captioned HIDDEN; persisted in `boothHidden`; SKINS ▸ SIGNS
lists "SHOW n HIDDEN PLAYERS AGAIN") and **REPORT** (hides first, then `ReportFlow` with `contentType: "booth"`,
contentId = the video link or `sign-left|right`). The server accepts `booth`; `reports.mjs takedown` on one prints
what to do with the account (nothing of ours to remove).

**Rig:** `PadRig.signs` (two specs), `PadRig.panels` (non-empty decor by panel: the signs, the mixer), and
`PadRig.screens` still written (each sign's picture as a plain visual) so an older build shows something. Bots dress
two signs from their id: a visual in a frame and their NAME or a slogan lit on a board with stickers.

### 10.3 Your booth — skin mode from anywhere *(2026-10-10, BUILT)*
User direction: from the main menu skin mode was a sheet over a scrim you couldn't click through, and once in Play or
Party there was no way back in. `Views/BoothMode.cs` is the one entry: main menu **SKINS** closes the menu and opens
skin mode ON the play screen dressed as YOUR BOOTH (badge "YOUR BOOTH"): your signs hung and clickable ("LEFT SIGN ·
CLICK TO EDIT" → the sign creator), your real PD-48 to paint, a floating TWIN of it ("AS THE CROWD SEES YOU", decor
read live — paint the pads and the twin has it the same frame), and your backline. DONE reopens the menu. The play
screen's nav row has a skin button and the party MENU has DECORATE MY BOOTH (both stay where they are; mid-match
your signs become editable when the screen is yours). Changes reach the room when skin mode closes
(`PartyRigs.MarkLocalDirty` → `DriveRigs` recaptures at any phase, not only the lobby). From CREATE, skin mode is
unchanged. The rail grew **SIGNS** (`SkinMode.SignsToggle`) — the sign creator (`Views/BoothSignSheet.cs`): the sign
live at the top, stood on the side away from the sign it edits.

⚠ `PartyStage` used to hide itself by deactivating its own GameObject — whose `Update` is what shows it again — so after
the first party the booth never came back until a restart. Content now lives on a child layer.

### 10.4 The backline — your mixer at the wings *(2026-10-10, BUILT)*
User direction: *"showing their mixer as an option could be cool too… as kinda 3d elements in the distance… if I
decorate my mixer… in party mode, can they see an example of that"*. `Views/BoothBackline.cs` builds the stage owner's
MIXER from the shipped layout — in their look (a shipped look by name; a custom one through the rig's part list),
wearing their CREATE decor (`PadRig.panels["Mixer"]`) — on an off-screen world-space canvas (render layer 29, its own
orthographic camera, photographed ~15×/s into a 512×1079 texture), and stands it at the stage wings as two
`PerspectiveImage` slabs (a 20×20 grid mesh, yawed ±32° toward the track, fogged at the far edge): the top of the rack
on the left, the bottom on the right, behind the signs and the crowd. Scopes and meters keep moving. Built with
`WidgetBuildContext.CastShadows = false` (a shadow quad positions itself by SCREEN rect and would land on the live
UI) and `_ReceiveSceneShadows 0`. Two racks are kept — yours and the stage owner's — so the screen coming back to
you never rebuilds. Off: SKINS ▸ SIGNS ▸ BACKLINE ▸ NO BACKLINE (`boothBackline`). ⚠ A `Graphic` subclass added at
runtime is NOT given a CanvasRenderer (the wings were laid out and never drew) — create the GameObject with it.

### 10.5 The takeover curtain — design the screen you slam shut *(2026-10-11, BUILT)*
User direction: *"in party mode … design the colors/stickers/etc for that quick popup screen too vs just being red and
blue always … add that under skin mode somehow."* The takeover curtain (`PartyCurtain`: "NEXT DRUMMER — JUNO", and the
quick "YOUR GO" before a count-in) took its two slabs from the player's lane colours — rows 0 and 3, red and blue unless a
sky changed them — so every curtain looked alike. It is now a design (`CurtainSpec`, engine-free in Core):
* **Colours** — slab A (left) and slab B (right), each "#RRGGBB" or null = the lane colour as before; **body brightness**
  (0.2–1: how bright a slab is against its stripe); the name's **colour** (null = white, small print tinted from slab A).
* **Pattern** — `lines` (speed lines, the old look), `bands` (the same lines 3.4× thicker), `dots` (halftone), `checker`,
  `none`. Dots and checker are 48 px tiling sprites made once (`PartyCurtain.PatternSprite`).
* **Lettering** — the name's typeface (`BoothFonts` id: display / led / sans) and a **tagline** (≤ 24) that replaces the
  look line under the name ("TRON DARK · 4 STICKERS") — only where that line was the look line (the "YOUR GO" and
  "THE SHOWCASE" lines stay informative).
* **Stickers** — six places round the name card (`CurtainSpec.Slots`: top/bottom left/right, far left/right), each a sticker
  from the whole library. They are a decor document on the panel **`BoothCurtain`** (items get `id = "curtain.<slot>"`),
  drawn on a clear glass plate (`BoothGlass`, the signs' trick — a decor surface only draws on a skinned plate) between
  the slabs and the lettering, so they pop in with the name card. Undo, saving and the Pro rule come with the decor store:
  a Pro sticker can be TRIED without Pro but is neither saved nor sent (`BoothCurtain.RemoveProStickers`, and the rig
  capture drops it).
* **Flash** — the white flash as the slabs meet, on or off.

**It travels in the rig.** `PadRig.curtain` (key `"curtain"`, only the non-default fields) + the stickers in
`PadRig.panels["BoothCurtain"]`. A player who never opened the tool sends nothing and the room sees the lane-colour
curtain; a build that predates it ignores the key. `PartyStage.CurtainOf(rig)` resolves a rig to (design, colours,
stickers) at every takeover (`Takeover`, your own "YOU'RE UP", your champion win). **Bots** get one made up from their id
(`PartyRigs.BotCurtain`: a colour pair, a pattern, a typeface, sometimes a tagline and 0–3 stickers), drawn after
everything else in `ForBot` so no bot's existing dressing changed.

**The editor — Skin Mode ▸ CURTAIN** (`Views/BoothCurtainSheet.cs`, a rail button next to SIGNS, wired in `BoothMode.Wire`).
The same curtain at the top of the sheet in its covered pose (`PartyCurtain.CreatePreview` — no canvas of its own,
clipped, everything scaled by height/1080), with PLAY IT (the whole slam, in place), FULL SCREEN (the real curtain over
everything, exactly what the room sees) and RESET; below, LOOKS (six one-click starting points), COLORS, PATTERN,
LETTERING, STICKERS (six places, then the pack tabs and a real gallery of plates), EXTRAS. Every change is live and kept
at once (`BoothCurtain`, setting `boothCurtain`); it stands on the right clear of the rail and closes the sign sheet (and
vice versa). Dev: `{"call":"BoothMode.Dev","arg":"curtain"}` opens it, `"curtaindemo"` dresses a sample.

Play-verified 2026-10-11 (Unity 6000.0.83f1, signed-out/expired editor session): the sheet's every section, PLAY IT (name
card fades in, white flash at +0.27 s), FULL SCREEN (slabs → card + stickers → wipe), stickers in two places live; a quick
match vs 3 bots — your "YOU'RE UP" in your design, JUNO (yellow/purple checker) and MAKO (yellow/crimson bands + a rainbow
orb, ghost, cloud) each in their own. Not yet: two humans over the relay (a design and its sticker doc end to end); the
portrait layout of the sheet; painting directly ON the curtain (PAINT works on panels you can see, and the curtain is
only on screen during a takeover — the six places are the editor for now).
