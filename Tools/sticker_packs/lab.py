# Science Lab — glassware, gadgets and a drum-tile of the elements. Every piece has the house shade (lower-right) and
# highlight (upper-left). Run by Tools/decor_stickers.py (every helper is in scope).
PACK = ("lab", "Science Lab", False)
PRO_IDS = {"flask", "atom", "scope", "planets", "dna", "board"}


def _moved(d, dx, dy):
    """Layer d slid by (dx, dy) slice units (y up); what slides in from the edge is far outside."""
    px, py = int(round(dx * N / 2)), int(round(dy * N / 2))
    out = np.full_like(d, BIG)
    h, w = d.shape
    rs, rd = (slice(py, h), slice(0, h - py)) if py >= 0 else (slice(0, h + py), slice(-py, h))
    cs, cd = (slice(0, w - px), slice(px, w)) if px >= 0 else (slice(-px, w), slice(0, w + px))
    out[rd, cd] = d[rs, cs]
    return out


def _lr(d, k=0.09):
    """The house shade: the lower-right rim of d."""
    return sub(d, _moved(d, -k, k))


def _hl(d, k=0.075, cut=0.45):
    """The house highlight: the upper-left rim of d, kept only in the upper-left corner."""
    s = d + 0.05
    return inter(sub(s, _moved(s, k, -k)), X * 0.8 - Y * 0.8 + cut)


@sticker("lab", "flask", "Bubbling flask", ["#CFEFFF", "#4CE05A", "#1F6B2A", "#FFFFFF"], ink=1.0)
def _():
    glass = poly([(-0.15, 0.8), (0.15, 0.8), (0.15, 0.3), (0.64, -0.62), (-0.64, -0.62), (-0.15, 0.3)]) - 0.05
    liquid = inter(glass, Y + 0.0)
    bubbles = U(circle(-0.06, 0.34, 0.09), circle(0.1, 0.55, 0.07), circle(-0.02, 0.72, 0.05))
    face = U(circle(-0.2, -0.22, 0.07), circle(0.2, -0.22, 0.07), arc(0.0, -0.3, 0.2, -2.5, -0.64, 0.05))
    shade = U(_lr(glass, 0.1), face)
    shine = U(_hl(glass, 0.08, 0.5), bubbles)
    return [glass, liquid, shade, shine]


@sticker("lab", "atom", "Atom", ["#3A7BFF", "#FF8A1F", "#1B3FA0", "#FFFFFF"], ink=1.0)
def _():
    orbits = U(*[shell(ellipse(0, 0, 0.86, 0.3, a), 0.045) for a in (0.0, 1.047, 2.094)])
    bits = U(circle(0, 0, 0.2), circle(0.78, 0.0, 0.1), circle(-0.39, 0.68, 0.1), circle(-0.39, -0.68, 0.1))
    shade = U(_lr(orbits, 0.06), sub(circle(0, 0, 0.2), circle(-0.06, 0.06, 0.2)))
    shine = _hl(orbits, 0.05, 0.3)
    return [orbits, bits, shade, shine]


@sticker("lab", "scope", "Microscope", ["#5B6B8C", "#D9A441", "#2B3552", "#E0E8FF"], ink=1.0)
def _():
    base = box(0.05, -0.74, 0.6, 0.12, 0.05)
    arm = arc(0.12, -0.12, 0.54, -1.4, 1.0, 0.17)
    tube = U(seg(-0.14, 0.5, -0.42, -0.1, 0.22), seg(-0.1, 0.72, -0.15, 0.55, 0.15), seg(-0.42, -0.1, -0.45, -0.3, 0.1))
    body = U(base, arm, tube)
    brass = U(box(-0.3, -0.44, 0.38, 0.06, 0.02), circle(0.5, -0.2, 0.14), seg(-0.38, 0.28, -0.04, 0.28, 0.06))
    shade = _lr(body, 0.1)
    shine = _hl(body, 0.08, 0.3)
    return [body, brass, shade, shine]


@sticker("lab", "dna", "DNA helix", ["#FF5FA8", "#3A7BFF", "#1B3FA0", "#BFD6FF"], ink=1.0)
def _():
    with rotated(0.4):
        ys = np.linspace(-0.74, 0.74, 60)
        a = polyline([(0.34 * math.sin(4.4 * y), y) for y in ys], 0.075)
        b = polyline([(-0.34 * math.sin(4.4 * y), y) for y in ys], 0.075)
        rungs = U(*[seg(0.34 * math.sin(4.4 * y), y, -0.34 * math.sin(4.4 * y), y, 0.04) for y in np.linspace(-0.68, 0.68, 11)])
        strands = U(a, b)
    shade = _lr(strands, 0.06)
    shine = _hl(strands, 0.05, 0.3)
    return [rungs, strands, shade, shine]


@sticker("lab", "rack", "Test tubes", ["#7DE87A", "#B07A3C", "#4A2E12", "#FFFFFF"], ink=1.0)
def _():
    tubes = U(*[seg(x, -0.5, x, 0.62, 0.14) for x in (-0.46, 0.0, 0.46)])
    rack = U(box(0, -0.02, 0.76, 0.07, 0.03), box(0, -0.72, 0.76, 0.1, 0.04), box(-0.72, -0.36, 0.06, 0.4, 0.02), box(0.72, -0.36, 0.06, 0.4, 0.02))
    shade = U(_lr(tubes, 0.08), _lr(rack, 0.07))
    shine = _hl(tubes, 0.06, 0.45)
    return [tubes, rack, shade, shine]


@sticker("lab", "beaker", "Beaker", ["#CFEFFF", "#FF7AD0", "#7A2E6A", "#FFFFFF"], ink=1.0)
def _():
    glass = U(box(0, -0.28, 0.52, 0.52, 0.06), box(0, 0.26, 0.58, 0.04, 0.02))
    liquid = inter(glass, Y + 0.28)
    fumes = U(smin(circle(-0.16, 0.5, 0.12), circle(0.1, 0.58, 0.15), 0.1), circle(0.0, 0.76, 0.1))
    ticks = U(*[box(-0.34, y, 0.1, 0.028) for y in (-0.7, -0.5, -0.3)])
    shade = U(_lr(glass, 0.1), ticks)
    shine = U(_hl(glass, 0.09, 0.5), fumes)
    return [glass, liquid, shade, shine]


@sticker("lab", "magnet", "Bar magnet", ["#E8344E", "#2E7BD6", "#7A1428", "#FFFFFF"], ink=1.0)
def _():
    with rotated(0.5):
        north = box(0, 0.0, 0.62, 0.28, 0.05)
        south = inter(north, X * -1)
        sparks = U(star(-0.62, 0.42, 4, 0.28, 0.08), star(0.62, -0.42, 4, 0.28, 0.08))
    shade = _lr(north, 0.1)
    shine = U(_hl(north, 0.08, 0.3), sparks)
    return [north, south, shade, shine]


@sticker("lab", "coil", "Lightning coil", ["#C77B3A", "#FFE840", "#7A3F14", "#FFF8C0"], ink=1.0)
def _():
    cyl = box(0, -0.3, 0.3, 0.38, 0.05)
    coil = U(box(0, -0.78, 0.46, 0.08, 0.03), cyl, circle(0, 0.3, 0.34))
    bolt = [(0.12, 0.34), (-0.16, -0.02), (0.0, -0.02), (-0.14, -0.4), (0.2, 0.06), (0.04, 0.06)]
    bolts = U(poly([(0.62 + 1.0 * (x - 0.0), 0.5 + 1.0 * (y)) for x, y in bolt]), poly([(-0.62 - 1.0 * (x - 0.0), 0.5 + 1.0 * (y)) for x, y in bolt]))
    rings = inter(cyl, stripes(0.24, math.pi / 2, 0.22, 0.05))
    shade = U(_lr(coil, 0.1), rings)
    shine = _hl(coil, 0.08, 0.3)
    return [coil, bolts, shade, shine]


@sticker("lab", "planets", "Planet model", ["#5E6BD6", "#FF9A2E", "#2A2F8A", "#FFF3B0"], ink=1.0)
def _():
    orbits = U(shell(circle(0, 0, 0.46), 0.03), shell(circle(0, 0, 0.8), 0.03))
    pl = [(0.0, 0.0, 0.2), (0.46 * math.cos(0.5), 0.46 * math.sin(0.5), 0.11), (0.8 * math.cos(3.5), 0.8 * math.sin(3.5), 0.16),
          (0.8 * math.cos(1.7), 0.8 * math.sin(1.7), 0.1)]
    planets = U(*[circle(x, y, r) for x, y, r in pl])
    shade = U(*[sub(circle(x, y, r), circle(x - 0.05, y + 0.05, r)) for x, y, r in pl])
    shine = U(*[circle(x - 0.05, y + 0.05, 0.035) for x, y, r in pl[:3]], _hl(orbits, 0.05, 0.5))
    return [orbits, planets, shade, shine]


@sticker("lab", "goggles", "Goggles", ["#2EB67D", "#BFF0FF", "#146A4A", "#FFFFFF"], ink=1.0)
def _():
    frame = U(circle(-0.42, 0.0, 0.4), circle(0.42, 0.0, 0.4), box(0, 0.0, 0.2, 0.1), seg(-0.78, 0.0, -0.9, 0.0, 0.08), seg(0.78, 0.0, 0.9, 0.0, 0.08))
    lens = U(circle(-0.42, 0.0, 0.27), circle(0.42, 0.0, 0.27))
    shade = _lr(frame, 0.09)
    shine = U(_hl(frame, 0.07, 0.3), arc(-0.42, 0.0, 0.17, 1.9, 2.8, 0.04), arc(0.42, 0.0, 0.17, 1.9, 2.8, 0.04))
    return [frame, lens, shade, shine]


@sticker("lab", "dish", "Petri dish", ["#E4F6FF", "#B9F0C8", "#2E7A4A", "#FFFFFF"], ink=1.0)
def _():
    dish = circle(0, 0, 0.84)
    agar = circle(0, 0, 0.62)
    cols = U(circle(-0.24, 0.2, 0.17), circle(0.26, 0.22, 0.12), circle(0.12, -0.28, 0.17))
    shade = U(_lr(dish, 0.08), cols, ring(0, 0, 0.68, 0.02))
    shine = U(_hl(dish, 0.09, 0.5), arc(0, 0, 0.76, 2.3, 2.9, 0.035))
    return [dish, agar, shade, shine]


@sticker("lab", "tile", "Element tile", ["#7A4AE0", "#3B1C9E", "#C9B2FF", "#FFE04A"], ink=1.0)
def _():
    tile = box(0, 0, 0.84, 0.84, 0.1)
    symbol = U(text("Dr", 0.0, -0.1, 3.0, maxw=1.35), text("66", -0.42, 0.56, 1.0, maxw=0.42))
    shade = _lr(tile, 0.1)
    shine = _hl(tile, 0.09, 0.6)
    return [tile, shade, shine, symbol]


@sticker("lab", "burner", "Bunsen burner", ["#8A93A8", "#3DB8FF", "#3E465C", "#FFFFFF"], ink=1.0)
def _():
    burner = U(oval(0, -0.68, 0.62, 0.17), box(0, -0.2, 0.13, 0.36, 0.04), box(0, -0.34, 0.22, 0.09, 0.03), seg(0.1, -0.58, 0.64, -0.46, 0.09))
    flame = U(circle(0, 0.34, 0.26), bezier((-0.17, 0.3), (-0.12, 0.62), (0.0, 0.9), 0.17, r1=0.01), bezier((0.17, 0.3), (0.12, 0.62), (0.0, 0.9), 0.17, r1=0.01))
    shade = _lr(burner, 0.09)
    shine = U(_hl(burner, 0.07, 0.5), _hl(flame, 0.07, 0.4))
    return [burner, flame, shade, shine]


@sticker("lab", "board", "Circuit board", ["#1FA05A", "#FFD84A", "#0F4F2C", "#B9FFD3"], ink=1.0)
def _():
    board = box(0, 0, 0.88, 0.68, 0.1)
    chip = U(box(0, 0, 0.26, 0.26, 0.04), *[box(x, y, 0.03, 0.07) for x in (-0.14, 0.0, 0.14) for y in (0.32, -0.32)],
             *[box(x, y, 0.07, 0.03) for x in (-0.32, 0.32) for y in (-0.14, 0.0, 0.14)])
    traces = U(polyline([(-0.34, 0.14), (-0.52, 0.14), (-0.62, 0.34), (-0.74, 0.34)], 0.04), polyline([(0.34, 0.0), (0.56, 0.0), (0.66, -0.22), (0.76, -0.22)], 0.04),
               polyline([(0.0, 0.34), (0.0, 0.5), (0.3, 0.5)], 0.04), polyline([(-0.14, -0.34), (-0.14, -0.5), (-0.4, -0.5)], 0.04),
               circle(-0.74, 0.34, 0.07), circle(0.76, -0.22, 0.07), circle(0.3, 0.5, 0.07), circle(-0.4, -0.5, 0.07))
    shade = U(_lr(board, 0.1), chip)
    shine = _hl(board, 0.08, 0.6)
    return [board, traces, shade, shine]


@sticker("lab", "wave", "Oscilloscope", ["#C9CFDD", "#37E88A", "#1E2438", "#FFFFFF"], ink=1.0)
def _():
    case = box(0, 0.0, 0.8, 0.84, 0.18)
    screen = circle(0, 0.2, 0.55)
    trace = polyline([(-0.5 + 0.045 * k, 0.2 + 0.24 * math.sin(0.55 * k)) for k in range(23)], 0.06)
    knobs = U(circle(-0.4, -0.58, 0.12), circle(0.0, -0.58, 0.12), circle(0.4, -0.58, 0.12))
    shade = U(_lr(case, 0.1), trace, knobs)
    shine = U(_hl(case, 0.08, 0.5), arc(0, 0.2, 0.44, 2.0, 2.7, 0.04))
    return [case, screen, shade, shine]


@sticker("lab", "labsign", "LAB badge", ["#FFFFFF", "#9AA3B8", "#DDE3F0", "#1B4FB0"], ink=1.0)
def _():
    card = box(0, 0.0, 0.86, 0.5, 0.1)
    shade = _lr(card, 0.1)
    shine = _hl(card, 0.08, 0.6)
    word = text("LAB", 0.0, 0.0, 3.2, maxw=1.5)
    return [card, shade, shine, word]


