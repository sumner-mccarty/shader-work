#!/usr/bin/env python3
"""
Refresh this repo's mirror of the Unity project (audiogame stays the source of truth).

    python Tools/sync_from_unity.py --project D:/repos/audiogame [--delete] [--dry-run]

This repo mirrors the Unity layout, so every path is the SAME relative path on both sides and the
project's own Tools/*.py run here unchanged (headless, via slrender):

    Assets/Shaders/**                      shader sources (scratch __probe_* skipped)
    Assets/Resources/{MaterialStates,UiStyles,Themes,TrackThemes,UiThemes}/*.json
    Tools/<skin tooling>                   skinsheet/skinlib/shaderprops/bake/design_*/sheet_*/...
    .claude/skills/skin-authoring/**       the skill workers follow
    Docs/Skinning/**                       per-shader property references

Only changed files are written. `--delete` also removes mirrored files that no longer exist in the
project (never anything outside the folders above, never Looks/ or the slrender files in Tools/). Run it before handing
work to cloud workers so they build against what the app actually ships.
"""
from __future__ import annotations

import argparse
import filecmp
import shutil
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent

TOOLS = ["skinsheet.py", "skinlib.py", "shaderprops.py", "bake.py", "build_recipes.py", "patch_skin.py",
         "sheet_style.py", "sheet_rack.py", "sheet_faceplates.py", "sheet_pads.py", "sheet_baseline.py",
         "design_realistic.py", "design_neomorphic.py", "design_others.py", "design_flat.py", "design_tron.py",
         "scopesheet.py", "s_mixer.py", "checklayout.py"]

MAPPINGS = [
    # (relative path, glob, include .meta)
    ("Assets/Shaders", "**/*", True),
    ("Assets/Resources/MaterialStates", "*.json", False),
    ("Assets/Resources/UiStyles", "*.json", False),
    ("Assets/Resources/Themes", "*.json", False),
    ("Assets/Resources/TrackThemes", "*.json", False),
    ("Assets/Resources/UiThemes", "*.json", False),
    (".claude/skills/skin-authoring", "**/*", False),
    ("Docs/Skinning", "**/*", False),
] + [("Tools", t, False) for t in TOOLS]


def skip(rel: Path) -> bool:
    return any(part.startswith("__probe") for part in rel.parts)


def _same(a: Path, b: Path) -> bool:
    if not b.exists():
        return False
    if filecmp.cmp(a, b, shallow=False):
        return True
    # Treat CRLF/LF-only differences as identical (git normalises them anyway).
    try:
        return a.read_bytes().replace(b"\r\n", b"\n") == b.read_bytes().replace(b"\r\n", b"\n")
    except OSError:
        return False


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--project", required=True, type=Path)
    ap.add_argument("--delete", action="store_true")
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()
    if not (a.project / "Assets").exists():
        sys.exit(f"{a.project} is not a Unity project (no Assets/)")

    written = removed = 0
    for rel_root, pattern, meta in MAPPINGS:
        src_rel = dst_rel = rel_root
        src, dst = a.project / src_rel, REPO / dst_rel
        if not src.exists():
            print(f"  (missing in project: {src_rel})")
            continue
        seen = set()
        for f in sorted(src.glob(pattern)):
            if not f.is_file():
                continue
            rel = f.relative_to(src)
            if skip(rel) or (f.suffix == ".meta" and not meta):
                continue
            seen.add(rel)
            target = dst / rel
            if _same(f, target):
                continue
            print(f"  {'new ' if not target.exists() else 'upd '} {dst_rel}/{rel.as_posix()}")
            written += 1
            if not a.dry_run:
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(f, target)
        if a.delete and dst.exists():
            for f in sorted(dst.glob(pattern)):
                rel = f.relative_to(dst)
                if f.is_file() and rel not in seen and (meta or f.suffix != ".meta"):
                    print(f"  del  {dst_rel}/{rel.as_posix()}")
                    removed += 1
                    if not a.dry_run:
                        f.unlink()
    print(f"{'would write' if a.dry_run else 'wrote'} {written}, {'would remove' if a.dry_run else 'removed'} {removed}")


if __name__ == "__main__":
    main()
