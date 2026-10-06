#!/usr/bin/env python3
"""
Bring approved looks from this repo into the Unity project (the other half of sync_from_unity.py).

    python Tools/import_to_unity.py --project D:/repos/audiogame --look gold-leaf [--look ...]
                                    [--with-shaders] [--force] [--rebuild-packs] [--dry-run]

Each look is described by Looks/<slug>/look.json (see Looks/README.md):
    { "style": "GoldLeaf", "status": "approved",
      "files": ["Tools/looks/gold_leaf.py", "Assets/Resources/UiStyles/GoldLeaf.style.json",
                "Assets/Resources/Themes/GoldLeaf*.theme.json",
                "Assets/Resources/MaterialStates/GoldLeafDark*.states.json",
                "Assets/Resources/MaterialStates/GoldLeafLight*.states.json"] }

Paths are identical on both sides (this repo mirrors the Unity layout). Safety:
  * refuses an unapproved look unless --force;
  * never overwrites a DIFFERENT existing file in the project unless --force (a look must not
    clobber shipped skins — use its own name prefix);
  * shader changes (Assets/Shaders files that differ from the project) are only copied with
    --with-shaders, and are listed first: Unity compiles with FXC, not DXC, so they need a Unity
    compile + Play Mode check before shipping.
--rebuild-packs drops {"rebuildPacks": true} on the project's SkinSheet bus (Unity must be open),
so the frozen .themepack files pick up the new looks.
"""
from __future__ import annotations

import argparse
import filecmp
import json
import shutil
import sys
import time
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent


def same(a: Path, b: Path) -> bool:
    if not b.exists():
        return False
    if filecmp.cmp(a, b, shallow=False):
        return True
    return a.read_bytes().replace(b"\r\n", b"\n") == b.read_bytes().replace(b"\r\n", b"\n")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--project", required=True, type=Path)
    ap.add_argument("--look", action="append", default=[])
    ap.add_argument("--with-shaders", action="store_true")
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--rebuild-packs", action="store_true")
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()
    if not (a.project / "Assets").exists():
        sys.exit(f"{a.project} is not a Unity project")

    plan, problems = [], []
    for slug in a.look:
        mf = REPO / "Looks" / slug / "look.json"
        if not mf.exists():
            problems.append(f"{slug}: no {mf.relative_to(REPO)}")
            continue
        look = json.loads(mf.read_text(encoding="utf-8"))
        if look.get("status") != "approved" and not a.force:
            problems.append(f"{slug}: status is '{look.get('status')}', not 'approved' (use --force to import anyway)")
            continue
        for pattern in look.get("files", []):
            hits = sorted(REPO.glob(pattern))
            if not hits:
                problems.append(f"{slug}: '{pattern}' matches nothing")
            for src in hits:
                if src.is_file():
                    plan.append((slug, src.relative_to(REPO)))

    if a.with_shaders:
        for src in sorted((REPO / "Assets" / "Shaders").rglob("*")):
            if src.is_file() and src.suffix in (".shader", ".cginc", ".hlsl") and not src.name.startswith("__"):
                rel = src.relative_to(REPO)
                if not same(src, a.project / rel):
                    plan.append(("shaders", rel))

    for slug, rel in plan:
        dst = a.project / rel
        if same(REPO / rel, dst):
            continue
        state = "new " if not dst.exists() else "UPD "
        if dst.exists() and slug != "shaders" and not a.force:
            problems.append(f"{slug}: would overwrite existing {rel} (pick a unique prefix, or --force)")
            continue
        print(f"  {state} [{slug}] {rel.as_posix()}")
        if not a.dry_run:
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(REPO / rel, dst)

    for p in problems:
        print("  ! " + p)
    if problems and not a.dry_run:
        print("(the files above that had no problem were imported)")

    if a.rebuild_packs and not a.dry_run:
        bus = a.project / ".skinsheet"
        bus.mkdir(exist_ok=True)
        (bus / "done.json").unlink(missing_ok=True)
        (bus / "job.tmp").write_text(json.dumps({"rebuildPacks": True}), encoding="utf-8")
        (bus / "job.tmp").replace(bus / "job.json")
        print("  rebuildPacks job queued — waiting for Unity...")
        t = time.time()
        while time.time() - t < 300 and not (bus / "done.json").exists():
            time.sleep(0.5)
        print("  " + ((bus / "done.json").read_text(encoding="utf-8") if (bus / "done.json").exists()
                      else "no answer (is Unity open and finished compiling?)"))

    print("next: let Unity import, Rebuild Shipped Theme Packs (or --rebuild-packs), then check the look in "
          "Play Mode via Skin Studio — and capture it in the flipbook.")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
