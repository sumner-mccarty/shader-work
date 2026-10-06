# shader-work

The cloud workshop for DrumSumDrum's SDF UI shaders and skins.

* **[FACTORY.md](FACTORY.md)** — how to run the skin factory: phases, prompts to paste into cloud
  sessions, model choice, budget, review and import back into the Unity project.
* **[slrender/README.md](slrender/README.md)** — the headless Unity shader renderer (works on any
  Unity project; parity-tested against the editor).
* **[CLAUDE.md](CLAUDE.md)** — rules every cloud session follows.
* **[Looks/](Looks/README.md)** — one folder per look, the quality rubric, and [the backlog](Looks/BACKLOG.md).

The `Assets/`, `Tools/` (skin tooling), `.claude/skills/` and `Docs/Skinning/` trees mirror the
Unity project (audiogame, GitLab) at identical paths; refresh them with
`python Tools/sync_from_unity.py --project <audiogame>`.

```bash
bash Tools/setup_toolchain.sh          # Linux/macOS (Windows: Tools/setup_toolchain.ps1)
python -m slrender doctor
python tests/test_basics.py && python tests/parity.py check
```
