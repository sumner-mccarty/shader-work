"""ShaderLab (.shader) parsing — just enough of Unity's format to compile and draw a pass.

What comes out of a .shader file:
  * the Properties block (name, kind, default) — Unity seeds every material from these, so a
    property nobody sets still renders with its authored default, not zero;
  * each Pass: its render state (Blend / BlendOp / ColorMask / Cull / ZWrite), the program text
    (CGPROGRAM or HLSLPROGRAM, with any CGINCLUDE/HLSLINCLUDE blocks prepended the way Unity does),
    the entry points and keyword pragmas, and the line the program starts on, so compiler errors
    can be reported against the .shader file itself.

The parser is a tolerant scanner, not a grammar: it strips comments, walks braces, and reads the
few statements that matter. Anything it does not understand is ignored rather than fatal.
"""
from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path


@dataclass
class Property:
    name: str
    display: str
    kind: str            # float | range | int | color | vector | texture
    default: object      # float, 4-tuple, or texture default name ("white", "black", ...)
    tex_dim: str = ""    # 2D | 3D | Cube | 2DArray | CubeArray | Any (textures only)
    range: tuple | None = None
    attributes: list = field(default_factory=list)


@dataclass
class Pass:
    name: str
    program: str             # program text (includes already prepended)
    program_line: int        # 1-based line in the .shader where `program` text begins
    language: str            # "CG" | "HLSL"
    vertex: str
    fragment: str
    keywords: list           # list of keyword sets, one per multi_compile/shader_feature line
    target: str
    blend: tuple | None      # (srcRGB, dstRGB, srcA, dstA) factor names, or None for "Off"
    blend_op: str = "Add"
    color_mask: str = "RGBA"
    cull: str = "Back"
    zwrite: str = "On"
    tags: dict = field(default_factory=dict)


@dataclass
class ShaderFile:
    path: Path
    name: str
    properties: dict         # name -> Property (ordered as declared)
    passes: list
    tags: dict


# ── comment stripping that keeps line numbers ───────────────────────────────

def _strip_comments(text: str) -> str:
    """Replace // and /* */ comments with spaces (newlines kept) so offsets/lines survive."""
    out = []
    i, n = 0, len(text)
    in_str = False
    while i < n:
        c = text[i]
        if in_str:
            out.append(c)
            if c == '\\' and i + 1 < n:
                out.append(text[i + 1]); i += 2; continue
            if c == '"':
                in_str = False
            i += 1
            continue
        if c == '"':
            in_str = True; out.append(c); i += 1; continue
        if text.startswith('//', i):
            j = text.find('\n', i)
            j = n if j < 0 else j
            out.append(' ' * (j - i)); i = j; continue
        if text.startswith('/*', i):
            j = text.find('*/', i + 2)
            j = n if j < 0 else j + 2
            out.append(''.join('\n' if ch == '\n' else ' ' for ch in text[i:j])); i = j; continue
        out.append(c); i += 1
    return ''.join(out)


def _match_brace(text: str, open_idx: int) -> int:
    """Index of the '}' matching the '{' at open_idx (program blocks are skipped as opaque)."""
    depth = 0
    i = open_idx
    n = len(text)
    while i < n:
        m = re.compile(r'\b(CGPROGRAM|HLSLPROGRAM|CGINCLUDE|HLSLINCLUDE)\b').match(text, i)
        if m:
            end_kw = 'ENDCG' if m.group(1).startswith('CG') else 'ENDHLSL'
            j = text.find(end_kw, m.end())
            i = (n if j < 0 else j + len(end_kw))
            continue
        c = text[i]
        if c == '"':
            j = text.find('"', i + 1)
            i = n if j < 0 else j + 1
            continue
        if c == '{':
            depth += 1
        elif c == '}':
            depth -= 1
            if depth == 0:
                return i
        i += 1
    raise ValueError("unbalanced braces in ShaderLab")


def _line_of(text: str, idx: int) -> int:
    return text.count('\n', 0, idx) + 1


# ── Properties ──────────────────────────────────────────────────────────────

_NUM = r'[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?'
_PROP_RE = re.compile(
    r'(?P<attrs>(?:\[[^\]]*\]\s*)*)'
    r'(?P<name>[A-Za-z_]\w*)\s*\(\s*"(?P<display>[^"]*)"\s*,\s*'
    r'(?P<type>Range\s*\(\s*(?P<lo>' + _NUM + r')\s*,\s*(?P<hi>' + _NUM + r')\s*\)|[A-Za-z0-9]+)\s*\)\s*'
    r'=\s*(?P<default>"[^"]*"\s*\{[^}]*\}|"[^"]*"|\([^)]*\)|' + _NUM + r')',
    re.S)


def _parse_properties(body: str) -> dict:
    props = {}
    for m in _PROP_RE.finditer(body):
        name = m.group('name')
        t = m.group('type').strip()
        tl = t.lower()
        attrs = re.findall(r'\[([^\]]*)\]', m.group('attrs') or '')
        d = m.group('default').strip()
        if tl.startswith('range'):
            p = Property(name, m.group('display'), 'range', float(d), range=(float(m.group('lo')), float(m.group('hi'))))
        elif tl in ('float',):
            p = Property(name, m.group('display'), 'float', float(d))
        elif tl in ('int', 'integer'):
            p = Property(name, m.group('display'), 'int', float(d))
        elif tl in ('color', 'vector'):
            vals = [float(x) for x in re.findall(_NUM, d)]
            vals = (vals + [0.0, 0.0, 0.0, 0.0])[:4]
            if tl == 'color' and len(re.findall(_NUM, d)) == 3:
                vals[3] = 1.0
            p = Property(name, m.group('display'), tl, tuple(vals))
        elif tl in ('2d', '3d', 'cube', '2darray', 'cubearray', 'any', 'rect'):
            dm = re.match(r'"([^"]*)"', d)
            p = Property(name, m.group('display'), 'texture', (dm.group(1) if dm else '') or 'gray', tex_dim=t)
        else:
            continue
        p.attributes = attrs
        props[name] = p
    return props


# ── render state ────────────────────────────────────────────────────────────

def _state(text: str, key: str):
    m = re.search(r'^\s*' + key + r'\s+([^\n{}]+)', text, re.M | re.I)
    return m.group(1).strip() if m else None


def _parse_blend(spec: str | None, inherited):
    if spec is None:
        return inherited
    s = spec.replace(',', ' ').split()
    if not s or s[0].lower() == 'off':
        return None
    if len(s) >= 4:
        return (s[0], s[1], s[2], s[3])
    if len(s) >= 2:
        return (s[0], s[1], s[0], s[1])
    return inherited


def _render_state(block: str, inherited: dict) -> dict:
    """Read state statements at THIS level only (program blocks and nested braces masked)."""
    flat = re.sub(r'\b(CG|HLSL)(PROGRAM|INCLUDE)\b.*?\bEND(CG|HLSL)\b', ' ', block, flags=re.S)
    # mask nested { } (Stencil, Tags, Pass) so their contents are not read as our statements
    out, depth = [], 0
    for c in flat:
        if c == '{':
            depth += 1; out.append(' '); continue
        if c == '}':
            depth -= 1; out.append(' '); continue
        out.append(c if depth == 0 else ('\n' if c == '\n' else ' '))
    flat = ''.join(out)
    st = dict(inherited)
    b = _state(flat, 'Blend')
    if b is not None:
        st['blend'] = _parse_blend(b, st.get('blend'))
    for key, k in (('BlendOp', 'blend_op'), ('ColorMask', 'color_mask'), ('Cull', 'cull'), ('ZWrite', 'zwrite')):
        v = _state(flat, key)
        if v is not None:
            st[k] = v.split()[0]
    return st


def _parse_tags(block: str) -> dict:
    m = re.search(r'\bTags\s*\{([^}]*)\}', block)
    return dict(re.findall(r'"([^"]+)"\s*=\s*"([^"]*)"', m.group(1))) if m else {}


# ── programs ────────────────────────────────────────────────────────────────

_PROG_RE = re.compile(r'\b(CGPROGRAM|HLSLPROGRAM)\b(.*?)\bEND(CG|HLSL)\b', re.S)
_INCL_RE = re.compile(r'\b(CGINCLUDE|HLSLINCLUDE)\b(.*?)\bEND(CG|HLSL)\b', re.S)


def _pragmas(prog: str):
    vertex = fragment = None
    target = '2.5'
    keywords = []
    for m in re.finditer(r'^\s*#\s*pragma\s+(\w+)\s*(.*)$', prog, re.M):
        kind, rest = m.group(1), m.group(2).strip()
        if kind == 'vertex':
            vertex = rest.split()[0]
        elif kind == 'fragment':
            fragment = rest.split()[0]
        elif kind == 'target':
            target = rest.split()[0]
        elif kind.startswith('multi_compile') or kind.startswith('shader_feature'):
            if kind in ('multi_compile_fog', 'multi_compile_instancing', 'multi_compile_fwdbase',
                        'multi_compile_shadowcaster', 'multi_compile_particles'):
                continue
            keywords.append(rest.split())
    return vertex, fragment, target, keywords


def parse(path) -> ShaderFile:
    path = Path(path)
    raw = path.read_text(encoding='utf-8', errors='replace')
    text = _strip_comments(raw)

    m = re.search(r'\bShader\s*"([^"]+)"\s*\{', text)
    if not m:
        raise ValueError(f"{path}: no Shader \"...\" block")
    name = m.group(1)
    shader_open = m.end() - 1
    shader_close = _match_brace(text, shader_open)
    shader_body_start = shader_open + 1

    props = {}
    pm = re.search(r'\bProperties\s*\{', text[shader_body_start:shader_close])
    if pm:
        p_open = shader_body_start + pm.end() - 1
        p_close = _match_brace(text, p_open)
        props = _parse_properties(text[p_open + 1:p_close])

    # Shader-level CGINCLUDE (outside SubShaders) applies to every program.
    shader_level_includes = []

    sub_m = re.search(r'\bSubShader\s*\{', text[shader_body_start:shader_close])
    if not sub_m:
        raise ValueError(f"{path}: no SubShader")
    head = text[shader_body_start:shader_body_start + sub_m.start()]
    for im in _INCL_RE.finditer(head):
        shader_level_includes.append((im.group(1), raw[shader_body_start + im.start(2):shader_body_start + im.end(2)],
                                      _line_of(text, shader_body_start + im.start(2))))

    sub_open = shader_body_start + sub_m.end() - 1
    sub_close = _match_brace(text, sub_open)
    sub_body = text[sub_open + 1:sub_close]
    sub_tags = _parse_tags(sub_body)

    # SubShader-level includes and state (state outside any Pass is inherited by every Pass).
    sub_includes = list(shader_level_includes)
    passes_spans = []
    i = 0
    while True:
        pm2 = re.compile(r'\bPass\s*\{').search(sub_body, i)
        if not pm2:
            break
        p_open = sub_open + 1 + pm2.end() - 1
        p_close = _match_brace(text, p_open)
        passes_spans.append((p_open, p_close))
        i = p_close - (sub_open + 1) + 1

    outside = sub_body
    for (a, b) in reversed(passes_spans):
        a_rel, b_rel = a - (sub_open + 1), b - (sub_open + 1)
        outside = outside[:a_rel] + ' ' * (b_rel - a_rel + 1) + outside[b_rel + 1:]
    for im in _INCL_RE.finditer(outside):
        sub_includes.append((im.group(1), raw[sub_open + 1 + im.start(2):sub_open + 1 + im.end(2)],
                             _line_of(text, sub_open + 1 + im.start(2))))

    base_state = {'blend': None, 'blend_op': 'Add', 'color_mask': 'RGBA', 'cull': 'Back', 'zwrite': 'On'}
    sub_state = _render_state(outside, base_state)

    passes = []
    for (p_open, p_close) in passes_spans:
        block = text[p_open + 1:p_close]
        st = _render_state(block, sub_state)
        nm = re.search(r'\bName\s+"([^"]*)"', block)
        prog_m = _PROG_RE.search(block)
        if not prog_m:
            continue
        lang = 'CG' if prog_m.group(1) == 'CGPROGRAM' else 'HLSL'
        prog_start = p_open + 1 + prog_m.start(2)
        prog_text = raw[prog_start:p_open + 1 + prog_m.end(2)]
        prefix = ''.join(f'#line {ln} "{path.name}"\n{body}\n'
                         for kw, body, ln in sub_includes
                         if (kw == 'CGINCLUDE') == (lang == 'CG'))
        program = prefix + f'#line {_line_of(text, prog_start)} "{path.name}"\n' + prog_text
        vertex, fragment, target, keywords = _pragmas(prog_text)
        passes.append(Pass(
            name=nm.group(1) if nm else f'Pass{len(passes)}',
            program=program, program_line=_line_of(text, prog_start), language=lang,
            vertex=vertex or 'vert', fragment=fragment or 'frag', keywords=keywords, target=target,
            blend=st['blend'], blend_op=st['blend_op'], color_mask=st['color_mask'],
            cull=st['cull'], zwrite=st['zwrite'], tags={**sub_tags, **_parse_tags(block)}))

    return ShaderFile(path=path, name=name, properties=props, passes=passes, tags=sub_tags)


def find_shader(name_or_path, roots) -> Path:
    """Resolve a Unity shader NAME ("UI/SDFButton") or a path to its .shader file."""
    p = Path(name_or_path)
    if p.suffix == '.shader':
        if p.exists():
            return p
        for root in roots:
            hits = sorted(Path(root).rglob(p.name))
            if hits:
                return hits[0]
    for root in roots:
        for f in Path(root).rglob('*.shader'):
            try:
                head = f.read_text(encoding='utf-8', errors='replace')[:4096]
            except OSError:
                continue
            m = re.search(r'\bShader\s*"([^"]+)"', _strip_comments(head))
            if m and m.group(1) == name_or_path:
                return f
    raise FileNotFoundError(f"no shader named {name_or_path!r} under {', '.join(map(str, roots))}")
