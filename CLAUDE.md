# CLAUDE.md — shader-work

This repo is the **cloud workshop** for DrumSumDrum's UI shaders and skins. The game itself lives in
a separate Unity repo (audiogame, on GitLab, not reachable from here); this repo mirrors the parts
of it that shader/skin work needs, at the **same relative paths**, and adds `slrender` — a headless
renderer that draws Unity shaders without Unity, parity-tested against the real editor.

You work here without Unity, ever. Everything you make is judged from slrender renders.

## Layout

| Path | What | May you edit it? |
|---|---|---|
| `Assets/Shaders/` | shader sources (mirrored from audiogame) | only in a shader task (FACTORY.md Phase 3) |
| `Assets/Resources/MaterialStates/` | skins (`*.states.json`) | only files with YOUR look's prefix |
| `Assets/Resources/UiStyles/` `Themes/` `TrackThemes/` | recipes, light rigs, highway palettes | only YOUR look's files |
| `Assets/Resources/UiThemes/` | shared display finishes + palette | no (shared — causes PR conflicts) |
| `Tools/*.py` (mirrored) | the project's skin tooling: `skinlib`, `skinsheet`, `bake`, `design_*`, `sheet_*` | no — import them |
| `Tools/lookkit.py` | the shared look kit (spec → parts, recipe, rig, sheets, rule audit) | only to extend a class; keep the Flat/Tron proofs byte-identical |
| `Tools/looks/` | one lookkit spec per look (yours); `flat.py`/`tron.py` are proofs, `example_lit.py` a template | yours only |
| `Tools/lookcheck.py` `sync_from_unity.py` `import_to_unity.py` `setup_toolchain.*` | workshop tools | only if the task says so |
| `Looks/` | one folder per look + `BACKLOG.md` briefs + `README.md` (format + rubric) | your look's folder |
| `.claude/skills/skin-authoring/` | **the skin skill — read SKILL.md before any skin work** | no |
| `Docs/Skinning/Params-*.md` | exhaustive per-shader property references | no |
| `slrender/` | the renderer ([slrender/README.md](slrender/README.md)) | only in a renderer task |
| `tests/` | `test_basics.py` (renderer contract), `parity.py` + `golden/` (Unity parity) | never edit goldens |

## Setup (automatic)

A SessionStart hook runs `Tools/setup_toolchain.sh` (installs DXC, SPIRV-Cross, Mesa llvmpipe, Python
deps, then `python -m slrender --software doctor`). If the hook didn't run or failed, run it yourself:
`bash Tools/setup_toolchain.sh`. `doctor` must end with `render ok` before you do anything else.
If a download is blocked, say so in your final message — the environment's network access needs
github.com, objects.githubusercontent.com, pypi.org and the Ubuntu archive.

## Rendering — how you see

* There is no GPU: GL is Mesa llvmpipe. The FIRST draw of each big shader in a process costs
  ~20 s (driver compile); after that, 10–60 ms. So keep one warm renderer alive:
  ```bash
  python -m slrender watch --bus .skinsheet > /tmp/slr-watch.log 2>&1 &
  export SKINSHEET_BACKEND=bus      # Tools/skinsheet.py now talks to the warm process
  ```
* **Parallel workers in one checkout** (e.g. builder subagents): each must use its OWN bus —
  `export SKINSHEET_BUS=.skinsheet-<slug>` and `python -m slrender watch --bus .skinsheet-<slug> &` —
  or they overwrite each other's job.json and PNGs.
* Everything renders in the app's **screen** orientation by default. Do not "fix" bevel direction
  to match the skill's warnings about the Unity SkinSheet — slrender already shows what players see.
* LOOK at results: build ONE contact sheet per round (`python -m slrender contact "<pngs>" -o sheet.png`
  or the `sheet()` helpers in `Tools/skinsheet.py`), keep it ≤ 2400 px wide, and open it with the
  Read tool. Judge at 1:1 (`ss` 1); zoom crops 3–4× nearest-neighbour for craft checks.
* Quick one-offs: `python -m slrender render --states <Skin> --size 72x72 --set _Value=0.4 -o x.png`;
  raw shader props: `python -m slrender render --shader UI/SDFButton --set _ButtonColor=#E0A030 ...`;
  what a shader accepts: `python -m slrender props UI/SDFKnobRM`.

## Look workflow (a new skin set)

1. Read `.claude/skills/skin-authoring/SKILL.md` (all of it — the traps are real), `Looks/README.md`
   (package format + rubric), and your brief in `Looks/BACKLOG.md`.
2. Write `Tools/looks/<module>.py` as a **lookkit spec** (`Tools/lookkit.py` — read its docstring and
   the spec section of `Looks/README.md`). Copy the closest template: `Tools/looks/flat.py` (unlit),
   `Tools/looks/tron.py` (neon) or `Tools/looks/example_lit.py` (lit). A spec is palettes per mode,
   shape language, materials, rig, displays and app-print overrides — the kit builds all 23 parts per
   mode, the roster, recipe and rig, and enforces the skill's rules (bounds, every guard, footprints,
   lip 0, knob shadow, plate bevel/dome, px-locked patterns, arc ≤ 0.88, light mode = chassis).
   Never hand-write states files for a look; if the kit lacks a vocabulary, extend the class in
   lookkit.py and keep the proofs green (`python Tools/looks/flat.py diff`, `tron.py diff`: every part
   and rig identical, recipes differing only in the banner).
3. `python Tools/looks/<module>.py check` → 0 errors. A rule may only be broken through
   `waive={"rule:Slot": "reason"}`, and the reason belongs in NOTES.md too.
4. Iterate on **rack composites**, not part lists: ≥ 3 rounds of
   `python Tools/looks/<module>.py sheet` (writes `Looks/<slug>/sheets/{rack,parts}-{dark,light}.png`;
   keep `SKINSHEET_BACKEND=bus`). Each round write a short critique in `Looks/<slug>/NOTES.md` against
   the rubric (identity, cohesion, legibility at 48 px, craft, states, fidelity), then fix the worst
   problem first.
5. Diversity check: tile your `rack-dark.png` with every other look's
   (`python -m slrender contact Looks/*/sheets/rack-dark.png -o /tmp/family.png`) and confirm yours
   is unmistakable.
6. `python Tools/looks/<module>.py write` + `manifest`, then the gate: `python Tools/lookcheck.py <Style>`
   → 0 errors (and read the warnings). `python tests/test_basics.py`.
7. Final sheets in `Looks/<slug>/sheets/`, set the spec's `status="candidate"` (re-run `manifest`),
   commit, push, open a PR titled `look: <Title>` whose description embeds the four sheets and
   summarises NOTES.md.

## Shader workflow (only when the task is a shader feature)

Edit `Assets/Shaders/**` → `python -m slrender compile <shader>` (errors point at the .shader line) →
render → look. **Every existing skin must render unchanged**: new properties default to OFF, and
`python tests/parity.py check` must still pass (it compares against frozen Unity renders). If an
intentional change moves pixels, say exactly which and why in the PR. Note in the PR that the
change needs a Unity compile check (Unity uses FXC; very large unrolled loops can fail there).

## Rules

* Never name or imitate a real brand, artist, product, logo or trade dress.
* Never edit another look's files, mirrored `Tools/*.py`, shared `UiThemes/*.json`, or test goldens.
* Don't regenerate shipped looks with their old generators (`design_realistic/others.py` have
  drifted from the committed skins — the skill says so).
* Keep committed images small (PNG, ≤ ~1.5 MB each). Never commit `.toolchain/`, `.slrender-cache/`.
* Report outcomes honestly in the PR: what passes, what you could not verify, what you'd do next.
