# The Skin Factory — how to drive shader-work from the cloud

Goal: an open-ended catalogue of high-quality, distinct DrumSumDrum looks (gold, water/glass,
country & western, hip-hop, Christmas, and every theme after them), made by cloud Claude sessions
on this GitHub repo, reviewed by you as PRs with pictures, and imported into the Unity project
(audiogame, GitLab) only when approved.

```
 audiogame (GitLab, Unity — source of truth)            shader-work (GitHub — cloud workshop)
 ┌──────────────────────────────────┐  sync_from_unity  ┌────────────────────────────────────────┐
 │ Assets/Shaders, Resources/…      │ ────────────────▶ │ same paths + slrender + Looks/ + gates │
 │ Tools/ (skin tooling)            │                   │ cloud sessions: one look per session   │
 │ .claude/skills/skin-authoring    │ ◀──────────────── │ PR per look: sheets, lookcheck, notes  │
 │ Unity: packs, Play Mode check    │  import_to_unity  │ you merge = approved                   │
 └──────────────────────────────────┘                   └────────────────────────────────────────┘
```

## 0. Once, locally (done in this session except the push)

* `slrender` (headless renderer), parity-tested: 30/30 cells against the Unity editor, GPU and
  llvmpipe; `tests/test_basics.py` 12/12.
* shader-work restructured to the Unity layout; mirror filled by `Tools/sync_from_unity.py`
  (shaders, all skins/recipes/rigs/track themes, the skin tooling, the skin skill, the param docs).
* `Tools/skinsheet.py` (in both repos) renders headless when Unity isn't running, or through a warm
  `slrender watch` process (`SKINSHEET_BACKEND=bus`) — so every existing `design_*`/`sheet_*` tool runs
  in the cloud unchanged.
* `Tools/lookcheck.py` (the PR gate), `Tools/import_to_unity.py` (the way back), `Looks/` (format,
  rubric, 40+ briefs), `CLAUDE.md` (worker rules), a SessionStart hook that installs the toolchain,
  and a GitHub Actions workflow that re-proves the Linux path on every push.
* audiogame: `SkinSheet.cs` now pins `_Time` and `_GlobalViewCam` (its renders were not repeatable).

**You:** commit + push shader-work (and commit the two audiogame files on GitLab). Then check the
Actions tab: the `slrender` workflow is the first real Linux run — it must go green before you
spend credits.

## Before each batch (2 minutes, local)

```bash
cd D:/repos/shader-work
python Tools/sync_from_unity.py --project D:/repos/audiogame     # pick up anything you changed in Unity
git add -A && git commit -m "sync from audiogame" && git push
```

## How to launch a cloud session

claude.ai/code (or the desktop app's cloud option) → repository **sumner-mccarty/shader-work** →
choose the **model** → paste the prompt → start. The session gets a fresh Linux container, the hook
installs the toolchain (~2–3 min the first time), and the session works on its own branch and opens
a PR. Run several sessions in parallel — each look touches only its own files, so PRs don't conflict.
If setup reports a blocked download, set the environment's network access to allow GitHub release
downloads, PyPI and the Ubuntu archive (or full access).

To give feedback, comment on the PR and start a session on that branch with the follow-up prompt
(§ Review).

## Model choice

| Work | Model | Why |
|---|---|---|
| Phase 1 foundation (look kit, material library), Phase 3 shader features | **Opus 5.5** | architecture + subtle shader maths; a mistake here poisons every look after it |
| Phase 2 looks, follow-up fixes | **Sonnet 5.5** | pattern-following with visual judgement, at half Opus's price |
| Phase 4 colourways | Sonnet 5.5 (or Haiku 4.5 once a look's spec is fully parameterised) | mechanical palette swaps under a gate |

Prices per million tokens (input/output): Opus 5.5 $4/$20, Sonnet 5.5 $2/$10, Haiku 4.5 $1/$5.
Haiku is not recommended for whole looks: the skill is ~600 lines of non-obvious traps and the job
is judging renders — cost per *approved* look is what matters.

## Budget for $100 (rough estimates — watch the first sessions and adjust)

| Phase | Sessions | Est. |
|---|---|---|
| 1 Foundation (Opus) | 2 | $25–35 |
| 2 Looks Wave 1 (Sonnet) | 10–12 | $40–55 |
| 3 Reflection/glass shader feature (Opus) | 1 | $10–15 |
| 4 Colourways (Sonnet) | 2–4 | $5–10 |

---------------------------------------------------------------------------------------------------
## Phase 1 — Foundation (Opus 5.5, run F1 first; F2 after F1 merges)

### Prompt F1 — the look kit
```
Read CLAUDE.md, .claude/skills/skin-authoring/SKILL.md (all), Looks/README.md, and study
Tools/design_flat.py and Tools/design_tron.py closely.

Build Tools/lookkit.py: a library that turns a compact LOOK SPEC into a complete DrumSumDrum look,
so future looks are ~150-line specs instead of 700-line generators.

Requirements:
- Generalise design_flat.py/design_tron.py: part builders for every slot they emit (keys/pad/lamp/
  toggle/close/accent/chip/dot/solo, dials hero/standard/small, faders + sliders + scroll handle/
  track, pill switch, plates face/inset/back/socket/well/bezel), the roster tables (roles, families,
  swaps), app palette roles, display map, rig, recipe writer, write/check/sheet/recipe CLI.
- Support three classes: unlit (Flat), neon (Tron), and LIT raymarched (UI/*RM shaders) — derive the
  lit vocabulary from the shipped Realistic*, NeoDark*, NeoLight* and RackFaceplate* skins.
- Encode the skill's rules so a spec cannot break them: bounds on every part, every effect guard
  explicit, footprints copied from the app skins each part swaps for, _ButtonLipHeight 0,
  _LightingShadow1Enabled explicit on knobs, plate bevel/dome limits (medial-axis rule), px-locked
  plate patterns, arc radius+width <= 0.88, light modes change the chassis.
- A spec names: title/style/prefix, class, per-mode palette, per-family material + shape language
  (corner radius, bevel, dome, knob silhouette, pattern), rig, track theme, display map, colourways.
- Output per look: states files, UiStyles recipe, Themes rig, and Looks/<slug>/sheets/{rack,parts}-
  {dark,light}.png. A rack composite renderer is required (parts placed on their faceplate, as
  Tools/sheet_rack.py does) — that is what reviewers judge.
- Proof: re-express Flat and Tron as specs (Tools/looks/flat.py, tron.py) that reproduce the shipped
  FlatDark*/FlatLight*/TronDark*/TronLight* files and recipes byte-for-byte, or list every
  intentional difference with a reason. Write them to a scratch dir for the comparison, do NOT
  overwrite the shipped files.
- Document the spec format in Looks/README.md and update CLAUDE.md's Look workflow to use the kit.
Gates: python tests/test_basics.py; python Tools/lookcheck.py on both proofs (0 errors).
Open a PR "lookkit: shared look kit + Flat/Tron proofs" with sheets of both proofs.
```

### Prompt F2 — lit material library + pilot looks
```
Read CLAUDE.md and the lookkit docstring. Add a material library to Tools/lookkit.py for LIT looks:
named presets for polished gold, brushed gold, rose gold, chrome, brushed aluminium, brass, copper,
black lacquer, enamel, gloss plastic, matte rubber, oiled wood, tooled leather, marble, ceramic,
frosted glass (translucent), velvet/fabric, carbon fibre, concrete. Each preset = the pattern
(type, px-derived scale, intensity, contrast, params), dome, bevel, spec/roughness effect, ambient
and the colour ramp it needs to read correctly under the shipped and a neutral rig. Tune each on a
swatch sheet (knob cap, key, plate, slider handle at real sizes), 3+ rounds, judged at 1:1; keep the
final swatch sheet in Looks/_materials/.
Then build two pilot looks from Looks/BACKLOG.md with the kit: gold-leaf and liquid-glass, following
the Look workflow in CLAUDE.md completely (rubric critique rounds in NOTES.md, lookcheck 0 errors).
One PR per pilot, plus one for the material library.

Verified in Unity on 2026-10-06 (lit example applied in Play Mode): the lit class renders in the
editor exactly as slrender shows it, and the light mode's pale plates (one far high key, plate
ambient 1.0) do NOT clip in the app. Two findings to act on:
- Dark mode: dark knobs/keys nearly vanish on dark plates in the real mixer. Every dark-mode preset
  must separate controls from the plate (rim/edge highlight, value step or shadow) — check it on
  the rack at knob.small size.
- Pills draw their own shadows inline (no shadow pass, WidgetShadowQuad needs _ShadowPassMode);
  slrender now matches that — never add a cast shadow for pills.
Light modes: report the % of clipped (>=250) pixels on each light-mode plate; keep it under 1%.
Leave a hook in the material presets for an environment-reflection term (Phase 3 adds it to the
shaders); fake gold/chrome/glass for now with dome + warm spec + gradients.
```

---------------------------------------------------------------------------------------------------
## Phase 2 — Look production (Sonnet 5.5, 4–6 sessions in parallel per batch)

Pick briefs from `Looks/BACKLOG.md` (Wave 1 first). One look per session. Paste, replacing the slug:

### Prompt L — one look
```
Make the look "<slug>" from Looks/BACKLOG.md.
Follow CLAUDE.md's Look workflow exactly: read the skin skill, Looks/README.md (incl. "Materials v2"),
Looks/CHECKLIST.md, Looks/TASTE.md and the lookkit docstring first; build Tools/looks/<module>.py on the
look kit; dark AND light; every role/family/swap rostered; your own prefix; your own rig if lit.
Use the Materials v2 presets (real textures, matcaps, glass + backdrop) wherever the brief names a
material — procedural-only surfaces are what made the last looks "okay, not stellar".
Iterate on rack composites for at least 3 rounds; each round score Looks/CHECKLIST.md in
Looks/<slug>/NOTES.md (render knob.small at 30x30 as well) and fix the lowest items first. Push the theme's
signature until it reads in one second at 25% zoom, then check it against every other look's rack
for distinctness.
Gate: python Tools/lookcheck.py <Style> with 0 errors, python Tools/looks/<module>.py printcheck with 0 pairs under 3:1, python tests/test_basics.py.
Deliver Looks/<slug>/ (look.json status "candidate", NOTES.md, sheets/) and open a PR
"look: <Title>" embedding rack-dark, rack-light, parts-dark, parts-light.
Do not edit shaders, shared JSON, mirrored Tools, or any other look.
```

Batch size: start with 4 (e.g. rodeo, ice-cold, candy-cane, walnut-brass), review, adjust the
prompt or kit from what you see, then go wider.

### Prompt B — hands-off batch (one prompt → many looks, one PR to review)

One cloud session acts as a **factory foreman**: it picks briefs itself, runs builder subagents in
parallel, has an independent critic judge every look and send it back for fixes, and opens ONE PR
for the whole batch. You only review that PR. Run the foreman on **Sonnet 5.5**; it puts builders
on Sonnet and the critic on Opus (the critic reads only four pictures, so Opus there is cheap and
it's where taste matters most). Change `6` to set the batch size.

```
You are the Look Factory foreman. Deliver up to 6 new, accepted looks this session with no help
from me. I will only review the final PR.

1. Setup: read CLAUDE.md, FACTORY.md, Looks/README.md (rubric) and the lookkit docstring. Run
   `python -m slrender --software doctor`; stop and report if it fails.
2. Pick: `git fetch --all`. Take briefs from Looks/BACKLOG.md in order (Wave 1, then Wave 2) that
   have NO Looks/<slug>/ folder on origin/main or on any origin branch. Keep the batch varied: no two
   looks with the same lighting class AND primary material. If the backlog runs dry, write new briefs
   with the theme formula at the end of BACKLOG.md and use those.
3. Build: one builder subagent per look (model: sonnet), at most 3 running at once — they share
   this container's CPU for rendering. Give each: the brief's slug, Prompt L from FACTORY.md, and
   these rules: export SKINSHEET_BUS=.skinsheet-<slug> and SKINSHEET_BACKEND=bus, run its own
   `python -m slrender watch --bus .skinsheet-<slug> &`, touch only files with its own prefix and its
   own Looks/<slug>/ folder, do NOT commit or push, and reply with: file list, lookcheck output,
   the four sheet paths, and its own rubric critique.
4. Judge: for each finished look, start a critic subagent (model: opus) that sees ONLY the brief,
   Looks/CHECKLIST.md, Looks/TASTE.md, the look's four sheets, a 30x30 knob.small render, and a contact
   sheet of every other look's rack-dark.png (`python -m slrender contact "Looks/*/sheets/rack-dark.png"`)
   — and, from round 2, ITS OWN PREVIOUS VERDICT. It scores exactly the CHECKLIST items in the
   CHECKLIST's verdict format (new observations go under "notes", never into the score — the goalposts
   do not move). PASS = every item >= 7 and identity >= 8. On REVISE, give the "fix first" list to the
   builder (continue the same subagent if you can, otherwise a new builder working on the existing
   files) — at most 3 revision rounds. Still failing after 3: set look.json status "rejected", keep
   the verdicts in NOTES.md, and do not count it.
5. Ship: for each accepted look set status "candidate" and commit it alone ("look: <Title>").
   Re-run `python Tools/lookcheck.py <Style>` and `python Tools/looks/<module>.py printcheck` (0 under 3:1) for every accepted look and `python tests/test_basics.py`.
   Push and open ONE PR "looks: batch <date> — <n> looks". For each look the description has: title,
   one-line concept, critic score, rack-dark and rack-light embedded, known issues. Rejected looks
   go in a short list at the end with the reason.
6. Stop when 6 looks are accepted, or early if 3 looks in a row are rejected — then report what in
   the kit or the prompt is causing it instead of burning more budget.
```

**Reviewing a batch:** open the PR, scroll the racks. Merge it as is, or comment e.g.
"drop candy-cane; ice-cold: gold too orange" and run the follow-up prompt on that branch. Mark the
ones you keep `approved` (the follow-up session can do that for you) and import them.

**Fully unattended (optional):** a scheduled cloud routine (Claude Code's `/schedule`, e.g. "every
night at 2am") can run Prompt B with a batch of 3 — a new batch PR waits for you each morning.
Check that routines draw from the same credits, and keep the batch small so one bad night is cheap.

**Cost:** measured: batch 1 (4 looks) ≈ $7; batch 2 (5 attempted, 0 accepted) burned its budget on a
critic that moved the goalposts — fixed by the checklist above. Expect ~$2–4 per accepted look.

### Prompt P — polish an existing look with Materials v2 (Sonnet 5.5, one look per session)
```
Polish the look "<slug>" (Tools/looks/<module>.py) with Materials v2 — read Looks/README.md
"Materials v2", Looks/CHECKLIST.md and Looks/TASTE.md first, then render the CURRENT racks as round 0.
Goal: material conviction. Use the presets' real textures and matcaps (wood that is wood, metal with a
moving reflection, fabric with weave), keep the look's identity and palette, keep light mode a chassis
change. Score CHECKLIST.md each round in NOTES.md (3+ rounds), knob.small at 30x30 included.
Gate: lookcheck 0 errors, printcheck 0 under 3:1, test_basics. Write the files, regenerate the sheets,
keep look.json status "candidate" (it needs re-approval), open a PR "polish: <Title> (Materials v2)"
embedding before/after racks for both modes.
```

### Prompt G — the glass look (Sonnet 5.5; the Liquid Glass brief, done properly)
```
Build a new glass look on Materials v2 glass, branching from main. The old attempt lives on branch
origin/main-5vekxz-liquid-glass (Tools/looks/liquid_glass.py) — copy its spec as a starting point only;
it predates the glass shader term. The look is
the modern translucent-glass UI style: mostly see-through parts that show the wallpaper behind them,
blurred and bent at curved edges, bright fresnel rims, clear-coat highlights. Read Looks/README.md
"Materials v2", Looks/CHECKLIST.md (item 11) and Looks/TASTE.md first.
- modes[*]["backdrop"]: a colourful wallpaper (Backdrops/Aurora or DeepWater for dark, Sunset or a new
  pale one for light — new wallpapers go in Tools/gen_materials.py, say so in the PR if you need one).
- plates: preset glass.frosted (bodies opaque; the glass term is the transparency), soft rounded edge;
  keys/knobs/handles: glass.clear with a glass_rim matcap; one strong accent for ON.
- Judge it over the wallpaper on the rack sheet (the sheet draws it); 3+ rounds against CHECKLIST.md.
Rename the look away from the trademark-like "Liquid Glass" (e.g. "Clearwater"). Gate as Prompt P.
Open a PR "look: <Title> (glass)" embedding both racks; mark old PR #4 as superseded in its description.
```

---------------------------------------------------------------------------------------------------
## Phase 3 — Shader features for true gold / chrome / glass (Opus 5.5)

Today's widget lighting is Blinn-Phong under the lamp rig — gold and glass are faked with domes,
specular and gradients. Real reflection needs a new lighting term. The screens' `UIDisplaySurface.cginc`
already has a fresnel + reflected-environment model to borrow.

### Prompt S1 — environment reflection
```
Read CLAUDE.md (Shader workflow), SKILL.md, CG/Core/UILighting.cginc and CG/Core/UIDisplaySurface.cginc.
Add an environment-reflection term to the widget lighting so metals and glass can read as truly
reflective: a procedural studio environment (horizon gradient + soft-box highlights, no textures),
fresnel-weighted, sampled with the surface normal the bevel/dome already computes, tinted by the
material colour for metals and untinted for dielectrics, plus an optional thin-film (iridescence)
tint. Expose it as float-guarded properties (_XxxReflectEnabled, strength, tint mode, roughness/blur)
on the body/cap/handle sections of SDFKnobRM, SDFButtonRM, SDFSliderRM, SDFTogglePillRM and the panel
face of SDFPanel, all defaulting OFF.
Hard requirement: python tests/parity.py check must still pass unchanged (existing skins untouched),
and compile time of SDFKnobRM must not blow up (report before/after slrender compile times).
Show it with swatch sheets (chrome, gold, glass, holographic) and upgrade the lookkit material
presets to use it. PR "shader: environment reflection" — state clearly that it needs a Unity
compile + Play Mode check before shipping.
```
**After merging:** import with shaders and check in Unity yourself (Phase 3 is the one step that
must touch the editor):
```bash
python Tools/import_to_unity.py --project D:/repos/audiogame --with-shaders --dry-run   # review the list
python Tools/import_to_unity.py --project D:/repos/audiogame --with-shaders
```
Then let Unity compile (watch the console), open a lit look in Play Mode, and only then run Wave 3.

---------------------------------------------------------------------------------------------------
## Phase 4 — Colourways (multiply approved looks)

### Prompt C — colourways
```
Add 3 colourways to the approved look <slug> (see its spec in Tools/looks/): <e.g. "on black",
"on ivory", "emerald"> — same structure, new palettes, each its own Style (<Style><Variant>),
dark and light. Re-run every rubric legibility/state check (palette changes break contrast),
lookcheck 0 errors each, sheets in Looks/<slug>-<variant>/. One PR for all three.
```

---------------------------------------------------------------------------------------------------
## Review — your part (this is where quality comes from)

On each PR: look at the four sheets on GitHub, then ask:
1. Do I know the theme in one second? 2. Would I ship it next to Realistic Dark?
3. Small knobs readable at 0/40/80%? 4. Anything crude — hard lines, blown highlights, mush?
5. Is it different enough from what we already have?

Feedback prompt (new session on the PR branch, Sonnet):
```
Continue the look on this branch. Review feedback: <your notes>. Address every point, re-run the
rubric round in NOTES.md, regenerate the sheets, keep lookcheck at 0 errors, push to the same PR.
```
Approve = set `status: "approved"` in its look.json and merge.

## Import approved looks into audiogame (local)

```bash
cd D:/repos/shader-work && git pull
python Tools/import_to_unity.py --project D:/repos/audiogame --look rodeo --look ice-cold --dry-run
python Tools/import_to_unity.py --project D:/repos/audiogame --look rodeo --look ice-cold --rebuild-packs
```
Then in Unity: let it import, Play Mode → Skin Studio → each new look over the creator/mixer, and
capture it in the flipbook. Mark the look `shipped`. Commit audiogame on GitLab.

## Using slrender elsewhere (the side project)

`slrender` is project-agnostic — any Unity project with `Assets/Shaders`:
`python -m slrender --project <path> compile --all`, `render --shader ... --set ...`, `contact`.
For a cloud worker in another repo, vendor or pip-install it (slrender/README.md). The workflow
"write .shader → compile → render a property sweep → look → iterate → drop into Unity" works for any
built-in-pipeline shader today; URP/HDRP need a ShaderLibrary shim (next step if you want it).
