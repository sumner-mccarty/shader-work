"""slrender command line.  `python -m slrender <command> --help` for details.

  doctor                      toolchain + GL check (run this first on a new machine/worker)
  compile [SHADER...] [--all] compile-check; errors as  File.shader:line:col: error: ...
  props SHADER                the shader's Properties (name, kind, default, range) as JSON
  render ...                  one image from a skin (--states) or raw material values (--props)
  job JOB.json [--out DIR]    run a SkinSheet job (same schema as Assets/Editor/SkinSheet.cs;
                              extra keys: "orientation" screen|texture, "time", "viewCam", "globals")
  watch [--bus DIR]           serve SkinSheet jobs from DIR/job.json -> DIR/done.json, warm
  contact PNG... -o OUT       tile images into one labelled contact sheet (one image to look at)
  glsl SHADER [--pass N]      print the generated GLSL (debugging the translation)

Common: --project DIR (Unity project or shader-work checkout; default: walk up from cwd),
        --software (Mesa llvmpipe, as on cloud workers; or SLRENDER_SOFTWARE=1).
"""
from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path


def _project(a):
    from .skins import find_project
    return Path(a.project) if a.project else find_project()


def _skin_renderer(a):
    from .render import Renderer
    from .skins import SkinRenderer
    proj = _project(a)
    roots = [p for p in (proj / "Assets" / "Shaders", proj / "Shaders") if p.exists()]
    return SkinRenderer(proj, renderer=Renderer(roots, software=a.software or None))


def _parse_value(s: str):
    s = s.strip()
    if s.startswith("#"):
        return s
    if "," in s:
        return [float(x) for x in s.split(",")]
    try:
        return float(s)
    except ValueError:
        return s


# ── commands ────────────────────────────────────────────────────────────────

def cmd_doctor(a):
    from . import compiler
    ok = True
    print(f"python       {sys.version.split()[0]}")
    for t in ("dxc", "spirv-cross"):
        try:
            print(f"{t:<12} {compiler.find_tool(t)}")
        except FileNotFoundError as e:
            print(f"{t:<12} MISSING - {e}")
            ok = False
    print(f"versions     {compiler.tool_versions()}")
    proj = _project(a)
    print(f"project      {proj}")
    try:
        sr = _skin_renderer(a)
        print(f"shaders      {', '.join(sr.r.shader_roots) or 'NONE FOUND'}")
        print(f"resources    {sr.resources}")
        info = sr.r.gl_info()
        print(f"gl           {info['GL_RENDERER']} | {info['GL_VERSION']}")
    except Exception as e:
        print(f"gl           FAILED - {type(e).__name__}: {e}")
        return 1
    # smallest real end-to-end check: a flat button through the whole pipeline
    try:
        t = time.time()
        img = sr.r.render("UI/SDFButton", {"_ButtonColor": (0.2, 0.6, 1.0, 1.0)}, (32, 32), bg=(0, 0, 0, 1))
        print(f"render       ok ({img.shape[1]}x{img.shape[0]}, {time.time() - t:.1f}s incl. compile)")
    except Exception as e:
        print(f"render       FAILED - {type(e).__name__}: {str(e)[:2000]}")
        ok = False
    return 0 if ok else 1


def cmd_compile(a):
    from . import compiler, shaderlab
    proj = _project(a)
    roots = [p for p in (proj / "Assets" / "Shaders", proj / "Shaders") if p.exists()]
    targets = []
    if a.all or not a.shaders:
        for r in roots:
            targets += [f for f in sorted(Path(r).glob("*.shader")) if not f.name.startswith("__")]
    for s in a.shaders:
        targets.append(shaderlab.find_shader(s, roots))
    failed = 0
    for path in targets:
        sh = shaderlab.parse(path)
        for i, p in enumerate(sh.passes):
            t = time.time()
            try:
                cp = compiler.compile_pass(sh, i, a.keywords or (), roots, use_cache=not a.no_cache)
                w = f"  {len(cp.warnings)} warning(s)" if cp.warnings else ""
                print(f"ok    {path.name} [{p.name}]  {time.time() - t:.1f}s{w}")
                if a.warnings:
                    for wline in cp.warnings:
                        print("      " + wline)
            except compiler.CompileError as e:
                failed += 1
                print(f"FAIL  {path.name} [{p.name}]")
                print("      " + str(e).replace("\n", "\n      "))
    return 1 if failed else 0


def cmd_props(a):
    from . import shaderlab
    proj = _project(a)
    roots = [p for p in (proj / "Assets" / "Shaders", proj / "Shaders") if p.exists()]
    sh = shaderlab.parse(shaderlab.find_shader(a.shader, roots))
    out = {name: {"kind": p.kind, "default": p.default, **({"range": p.range} if p.range else {}),
                  **({"display": p.display} if p.display else {}),
                  **({"attributes": p.attributes} if p.attributes else {})}
           for name, p in sh.properties.items()}
    print(json.dumps({"shader": sh.name, "file": str(sh.path), "properties": out}, indent=1))
    return 0


def cmd_render(a):
    from .render import TextureSpec, to_image
    sr = _skin_renderer(a)
    w, h = (int(x) for x in a.size.lower().split("x"))
    sets = {}
    for kv in a.set or []:
        k, v = kv.split("=", 1)
        sets[k] = _parse_value(v)
    t = time.time()
    if a.states:
        cell = {"states": a.states, "w": w, "h": h, "ss": a.ss, "state": a.state, "set": sets,
                "bg": a.bg, "shadow": a.shadow, "time": a.time, "orientation": a.orientation}
        if a.shader:
            cell["shader"] = a.shader
        if a.pos:
            cell["pos"] = [float(x) for x in a.pos.split(",")]
        img = sr.render_cell(cell)
    else:
        if not a.shader:
            sys.exit("render needs --states (a skin) or --shader (raw material values)")
        props = json.loads(Path(a.props).read_text(encoding="utf-8")) if a.props else {}
        props.update(sets)
        from .skins import parse_color
        props = {k: (parse_color(v) if isinstance(v, str) and v.startswith("#") else v) for k, v in props.items()}
        textures = {}
        for kv in a.texture or []:
            k, v = kv.split("=", 1)
            textures[k] = TextureSpec(data=v)
        globals_ = {}
        if not a.no_rig:
            # Same scene state a skin cell gets: the shipped light rig + pinned camera/shadow globals.
            from .skins import load_rig, rig_uniforms
            globals_ = rig_uniforms(load_rig(sr.resources), w / h)
            globals_.update({"_UIShadowBufferBound": 0.0, "_GlobalViewCam": (0.5 * w / h, 0.5, 2.2, 2.2)})
            props.setdefault("_Position", (0.5 * w / h, 0.5, 0.0, 0.0))
            props.setdefault("_WidgetPixelSize", (float(w), float(h), 0.0, 0.0))
        img = sr.r.render(a.shader, props, (w * a.ss, h * a.ss), globals_, keywords=a.keywords or (),
                          textures=textures, bg=parse_color(a.bg), time=a.time, orientation=a.orientation)
    to_image(img).save(a.out)
    print(f"{a.out}  {img.shape[1]}x{img.shape[0]}  {time.time() - t:.2f}s")
    return 0


def cmd_job(a):
    sr = _skin_renderer(a)
    job = json.loads(Path(a.job).read_text(encoding="utf-8"))
    t = time.time()
    payload = sr.run_job(job, a.out)
    print(json.dumps(payload))
    print(f"{payload['ok']} ok, {payload['fail']} failed in {time.time() - t:.1f}s")
    return 1 if payload["fail"] else 0


def cmd_watch(a):
    """The SkinSheet.cs bus, minus Unity: poll BUS/job.json, render, write BUS/done.json."""
    sr = _skin_renderer(a)
    bus = Path(a.bus)
    bus.mkdir(parents=True, exist_ok=True)
    print(f"watching {bus / 'job.json'}  ({sr.r.gl_info()['GL_RENDERER']}) - Ctrl+C to stop", flush=True)
    while True:
        job_path = bus / "job.json"
        if job_path.exists():
            try:
                text = job_path.read_text(encoding="utf-8")
            except OSError:
                time.sleep(0.1)
                continue
            if not text.strip():
                time.sleep(0.1)
                continue
            try:
                job = json.loads(text)
                if "cells" not in job:
                    unsupported = [k for k in job if k not in ("out", "rig", "theme")]
                    payload = {"ok": 0, "fail": 1, "log": f"slrender watch only renders cells (got {unsupported})"}
                else:
                    sr._docs.clear()   # states files may have been edited between jobs
                    t = time.time()
                    payload = sr.run_job(job, job.get("out") or (bus / "out"))
                    print(f"job: {payload['ok']} ok, {payload['fail']} failed, {time.time() - t:.1f}s", flush=True)
            except Exception as e:
                payload = {"ok": 0, "fail": 1, "log": f"FATAL {type(e).__name__}: {e}"}
            try:
                job_path.unlink()
            except OSError:
                pass
            (bus / "done.json").write_text(json.dumps(payload), encoding="utf-8")
        time.sleep(0.1)


def cmd_contact(a):
    from PIL import Image, ImageDraw
    files = []
    for pat in a.images:
        p = Path(pat)
        files += sorted(p.parent.glob(p.name)) if any(c in p.name for c in "*?[") else [p]
    if not files:
        sys.exit("no images")
    ims = [Image.open(f).convert("RGBA") for f in files]
    cols = a.cols or min(len(ims), 6)
    cw = max(i.width for i in ims)
    ch = max(i.height for i in ims)
    lab, pad = 14, 8
    rows = (len(ims) + cols - 1) // cols
    sheet = Image.new("RGB", (pad + cols * (cw + pad), pad + rows * (ch + lab + pad)), a.bg)
    d = ImageDraw.Draw(sheet)
    for i, (f, im) in enumerate(zip(files, ims)):
        x = pad + (i % cols) * (cw + pad)
        y = pad + (i // cols) * (ch + lab + pad)
        d.text((x, y), f.stem[:max(8, cw // 6)], fill=(200, 205, 215))
        sheet.paste(im, (x, y + lab), im)
    sheet.save(a.out)
    print(f"{a.out}  {sheet.width}x{sheet.height}  ({len(ims)} images)")
    return 0


def cmd_glsl(a):
    from . import compiler, shaderlab
    proj = _project(a)
    roots = [p for p in (proj / "Assets" / "Shaders", proj / "Shaders") if p.exists()]
    sh = shaderlab.parse(shaderlab.find_shader(a.shader, roots))
    cp = compiler.compile_pass(sh, a.pass_index, a.keywords or (), roots)
    print(cp.vertex.glsl if a.stage == "vert" else cp.fragment.glsl)
    return 0


def main(argv=None):
    ap = argparse.ArgumentParser(prog="slrender", description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--project", help="Unity project root or shader-work checkout")
    ap.add_argument("--software", action="store_true", help="Mesa llvmpipe (cloud configuration)")
    sub = ap.add_subparsers(dest="cmd", required=True)

    sub.add_parser("doctor")

    p = sub.add_parser("compile")
    p.add_argument("shaders", nargs="*", help="shader names (UI/SDFKnob) or .shader paths; default all")
    p.add_argument("--all", action="store_true")
    p.add_argument("--keywords", nargs="*")
    p.add_argument("--warnings", action="store_true")
    p.add_argument("--no-cache", action="store_true")

    p = sub.add_parser("props")
    p.add_argument("shader")

    p = sub.add_parser("render")
    p.add_argument("--states", help="skin: .states.json path or name under Resources/MaterialStates")
    p.add_argument("--shader", help="shader name/path (raw mode, or override the skin's)")
    p.add_argument("--props", help="raw mode: JSON file of material values")
    p.add_argument("--state", default="Normal")
    p.add_argument("--set", action="append", help="NAME=VALUE (float, r,g,b,a, or #hex); repeatable")
    p.add_argument("--texture", action="append", help="raw mode: NAME=image.png; repeatable")
    p.add_argument("--keywords", nargs="*")
    p.add_argument("--size", default="96x96")
    p.add_argument("--ss", type=int, default=1)
    p.add_argument("--pos", help="x,y normalized screen position (skin mode)")
    p.add_argument("--bg", default="#1A1D22")
    p.add_argument("--shadow", type=float, default=0)
    p.add_argument("--time", type=float, default=0)
    p.add_argument("--no-rig", action="store_true", help="raw mode: do not publish the scene light rig")
    p.add_argument("--orientation", choices=["screen", "texture"], default="screen",
                   help="screen = what the running app shows (default); texture = Unity Blit/SkinSheet")
    p.add_argument("-o", "--out", default="render.png")

    p = sub.add_parser("job")
    p.add_argument("job")
    p.add_argument("--out")

    p = sub.add_parser("watch")
    p.add_argument("--bus", default=".skinsheet")

    p = sub.add_parser("contact")
    p.add_argument("images", nargs="+")
    p.add_argument("-o", "--out", default="contact.png")
    p.add_argument("--cols", type=int)
    p.add_argument("--bg", default="#101317")

    p = sub.add_parser("glsl")
    p.add_argument("shader")
    p.add_argument("--pass", dest="pass_index", type=int, default=0)
    p.add_argument("--stage", choices=["vert", "frag"], default="frag")
    p.add_argument("--keywords", nargs="*")

    a = ap.parse_args(argv)
    fn = globals()["cmd_" + a.cmd]
    sys.exit(fn(a) or 0)


if __name__ == "__main__":
    main()
