# Wildstyle — graffiti as the art itself: pieces, throw-ups, drips, caps and markers. Run by Tools/decor_stickers.py.
PACK = ("wildstyle", "Wildstyle", False)
PRO_IDS = {"dsdpiece", "boom", "creature", "burner", "burn", "king"}


def _moved(d, dx, dy):
    """Layer d slid by (dx, dy) slice units (y up); what slides in from the edge is far outside."""
    px, py = int(round(dx * N / 2)), int(round(dy * N / 2))
    out = np.full_like(d, BIG)
    h, w = d.shape
    rs, rd = (slice(py, h), slice(0, h - py)) if py >= 0 else (slice(0, h + py), slice(-py, h))
    cs, cd = (slice(0, w - px), slice(px, w)) if px >= 0 else (slice(-px, w), slice(0, w + px))
    out[rd, cd] = d[rs, cs]
    return out


def _rim(d, k=0.08):
    """The lower-right rim of d: d minus itself slid up-left — the house shade."""
    return sub(d, _moved(d, -k, k))


def _glint(d, k=0.07):
    """The upper-left rim of d: d minus itself slid down-right — the house highlight."""
    return sub(d, _moved(d, k, -k))


def _ext(d, dx, dy, n=7):
    """d dragged down-right by (dx, dy): the hard extruded drop shadow of 3D lettering."""
    return U(*[_moved(d, dx * k / n, -dy * k / n) for k in range(n + 1)])


def _lean(d, k):
    """d sheared so its tops lean right by k per unit of height (italic lettering)."""
    out = np.full_like(d, BIG)
    for r in range(N):
        y = _xs[::-1][r]
        s = int(round(k * y * N / 2))
        out[r] = np.roll(d[r], s)
        if s > 0:
            out[r, :s] = BIG
        elif s < 0:
            out[r, s:] = BIG
    return out


def _arrow(x0, y0, x1, y1, w=0.07, head=0.2):
    """A fat wildstyle arrow from (x0, y0) to its point at (x1, y1)."""
    ang = math.atan2(y1 - y0, x1 - x0)
    bx, by = x1 - head * math.cos(ang), y1 - head * math.sin(ang)
    nx, ny = -math.sin(ang), math.cos(ang)
    tip = poly([(x1, y1), (bx + nx * head * 0.62, by + ny * head * 0.62), (bx - nx * head * 0.62, by - ny * head * 0.62)])
    return U(taper(x0, y0, bx, by, w, w * 0.8), tip)


@sticker("wildstyle", "dsdpiece", "DSD piece", ["#2A1250", "#FFC531", "#B8730A", "#2FE0FF"], ink=1.0)
def _():
    word = text("DSD", 0, 0.0, 1.2, ang=0.08, stretch=0.5, maxw=1.4) - 0.015
    arrows = U(_arrow(0.5, 0.1, 0.84, 0.54, 0.08, 0.26), _arrow(-0.5, -0.1, -0.84, -0.54, 0.08, 0.26))
    outline = _ext(U(word, arrows) - 0.06, 0.08, 0.08, 6)
    letters = word
    shade = _rim(word, 0.05)
    return [outline, letters, shade, arrows]


@sticker("wildstyle", "throwup", "Throw-up", ["#1A1410", "#FFC531", "#B8730A", "#FFFFFF"], ink=1.0)
def _():
    word = text("PHAT", 0, 0.0, 1.2, ang=-0.06, stretch=0.4, maxw=1.6) - 0.02
    outline = word - 0.075
    fill = word
    shade = _rim(word, 0.05)
    shine = U(*[oval(x, 0.24, 0.08, 0.035, -0.5) for x in (-0.66, -0.26, 0.14, 0.56)])
    return [outline, fill, shade, shine]


@sticker("wildstyle", "king", "KING tag", ["#1A1410", "#7CFF3C", "#38B514", "#FFFFFF"], ink=1.0)
def _():
    word = inter(text("KING", 0, 0.28, 1.2, ang=0.05, stretch=0.45, maxw=1.4) - 0.03, box(-0.02, 0.28, 0.8, 0.6))
    drops = U(*[U(taper(x, 0.0, x, y, 0.07, 0.045), circle(x, y, 0.055)) for x, y in [(-0.62, -0.5), (-0.22, -0.78), (0.18, -0.36), (0.52, -0.66), (0.78, -0.3)]])
    outline = U(word, drops) - 0.07
    letters = word
    shade = U(_rim(word, 0.05), drops)
    shine = U(_glint(word, 0.035), circle(-0.62 - 0.02, -0.38, 0.02))
    return [outline, letters, shade, shine]


@sticker("wildstyle", "arrowburst", "Arrow burst", ["#FF8A00", "#C45A00", "#FFE14A", "#FFF4C7"], ink=1.0)
def _():
    arrows = U(*[_arrow(0.3 * math.cos(a), 0.3 * math.sin(a), 0.92 * math.cos(a), 0.92 * math.sin(a), 0.14, 0.4) for a in [k * math.pi / 2 + 0.78 for k in range(4)]])
    shade = _rim(arrows, 0.06)
    core = circle(0, 0, 0.36)
    hub = star(0, 0, 4, 0.24, 0.08, 0.4)
    return [arrows, shade, core, hub]


@sticker("wildstyle", "caps", "Fat & skinny cap", ["#E3172F", "#FF7A3D", "#A00F20", "#1A1410"], ink=1.0)
def _():
    fat = U(box(-0.46, -0.3, 0.4, 0.26, 0.1), box(-0.46, 0.04, 0.2, 0.1, 0.04))
    skinny = U(box(0.54, -0.04, 0.16, 0.52, 0.06), taper(0.54, 0.48, 0.54, 0.72, 0.07, 0.05))
    shade = _rim(U(fat, skinny), 0.07)
    nozzle = U(box(-0.46, 0.12, 0.09, 0.03, 0.01), circle(0.54, 0.74, 0.03), box(-0.46, -0.3, 0.26, 0.04, 0.02), box(0.54, -0.04, 0.06, 0.34, 0.02))
    return [fat, skinny, shade, nozzle]


@sticker("wildstyle", "mop", "Mop marker", ["#FF8A00", "#C45A00", "#1A1410", "#27B8FF"], ink=1.0)
def _():
    with rotated(0.45, 0.0, 0.1, 0.1, 0.1):
        bottle = U(box(0.0, -0.12, 0.38, 0.4, 0.14), box(0.0, 0.34, 0.2, 0.1, 0.04))
        dabber = U(box(0.0, 0.6, 0.3, 0.2, 0.1))
        shade = _rim(bottle, 0.08)
    paint = U(taper(-0.8, -0.7, 0.3, -0.76, 0.12, 0.14), taper(-0.5, -0.74, -0.5, -0.92, 0.07, 0.05), circle(-0.5, -0.92, 0.06))
    return [bottle, shade, dabber, paint]


@sticker("wildstyle", "blackbook", "Black book", ["#2B2B33", "#15151B", "#FF3B2F", "#FFC531"], ink=1.0)
def _():
    with rotated(-0.08):
        cover = box(0, 0, 0.62, 0.84, 0.07)
        spine = U(box(-0.54, 0, 0.1, 0.84, 0.04), _rim(cover, 0.08))
        strap = box(0.36, 0.0, 0.07, 0.84)
        label = U(box(-0.1, 0.28, 0.3, 0.22, 0.03))
    return [cover, spine, strap, label]


@sticker("wildstyle", "burner", "Brick burner", ["#B4533A", "#E3C9A3", "#FF8A00", "#FFE14A"], ink=1.0)
def _():
    wall = box(0, 0, 0.88, 0.88, 0.05)
    mortar = U(*[inter(wall, box(0, y, 1.0, 0.025)) for y in (-0.6, -0.2, 0.2, 0.6)],
               *[inter(wall, box(x + 0.0, y + 0.2, 0.025, 0.2)) for y in (-0.6, 0.2) for x in (-0.45, 0.45)],
               *[inter(wall, box(x, y + 0.2, 0.025, 0.2)) for y in (-0.2, 0.6) for x in (0.0, 0.9)])
    flame = poly(spline([(0.0, 0.8), (0.18, 0.4), (0.5, 0.2), (0.56, -0.2), (0.34, -0.58), (0.0, -0.66), (-0.34, -0.58), (-0.56, -0.2), (-0.4, 0.1), (-0.2, 0.3)], n=8))
    core = poly(spline([(0.04, 0.3), (0.26, -0.02), (0.3, -0.3), (0.0, -0.5), (-0.28, -0.3), (-0.2, 0.0)], n=8))
    return [wall, mortar, flame, core]


@sticker("wildstyle", "stencil", "Stencil star", ["#E3172F", "#D8B67A", "#B08A4A", "#FF8A8A"], ink=1.0)
def _():
    with rotated(-0.1):
        card = box(0, 0, 0.86, 0.86, 0.05)
        st = star(0, 0.02, 5, 0.62, 0.27)
        hole = st - 0.0
    paint = hole - 0.1
    sheet = sub(card, hole)
    bridges = U(inter(hole, box(0.0, 0.0, 0.7, 0.045, 0.0, 0.0)), inter(hole, box(0.0, 0.2, 0.045, 0.7)))
    spray = U(circle(-0.76, 0.5, 0.1), circle(0.78, -0.5, 0.09), circle(0.72, 0.62, 0.07))
    return [paint, sheet, bridges, spray]


@sticker("wildstyle", "boom", "BOOM block", ["#12306B", "#FFD23F", "#FF8A00", "#FFFFFF"], ink=1.0)
def _():
    word = text("BOOM", -0.08, 0.1, 1.2, stretch=0.4, maxw=1.4)
    block = _ext(word, 0.22, 0.22, 12)
    face = word
    shade = _rim(word, 0.05)
    shine = _glint(word, 0.04)
    return [block, face, shade, shine]


@sticker("wildstyle", "creature", "Boom-bap beast", ["#B35CFF", "#7A2CC8", "#FFF4C7", "#1A1410"], ink=1.0)
def _():
    horns = U(taper(-0.3, 0.4, -0.5, 0.84, 0.13, 0.03), taper(0.3, 0.4, 0.5, 0.84, 0.13, 0.03))
    tail = U(brush([(0.5, -0.5), (0.82, -0.44), (0.82, -0.14)], [0.12, 0.1, 0.07]), circle(0.82, -0.1, 0.1))
    body = U(circle(0, -0.1, 0.6), horns, tail, circle(-0.6, 0.0, 0.14), circle(0.6, 0.0, 0.14), circle(-0.3, -0.76, 0.14), circle(0.0, -0.8, 0.14), circle(0.3, -0.76, 0.14))
    shade = _rim(body, 0.07)
    belly = U(oval(0, -0.36, 0.34, 0.26), taper(-0.3, 0.4, -0.4, 0.62, 0.05, 0.02), taper(0.3, 0.4, 0.4, 0.62, 0.05, 0.02))
    shades = U(box(-0.25, 0.16, 0.2, 0.15, 0.06), box(0.25, 0.16, 0.2, 0.15, 0.06), box(0.0, 0.22, 0.1, 0.035), arc(0, -0.04, 0.3, math.radians(215), math.radians(325), 0.045))
    return [body, shade, belly, shades]


@sticker("wildstyle", "splatcrown", "Splat crown", ["#27B8FF", "#0B6DB8", "#FFD23F", "#FFFFFF"], ink=1.0)
def _():
    base = poly([(-0.62, -0.2), (-0.7, 0.4), (-0.38, 0.14), (-0.2, 0.62), (0.0, 0.18), (0.2, 0.62), (0.38, 0.14), (0.7, 0.4), (0.62, -0.2)])
    crown = smin(base, box(0, -0.25, 0.62, 0.16, 0.08), 0.06)
    drips = U(taper(-0.4, -0.3, -0.4, -0.66, 0.08, 0.05), circle(-0.4, -0.68, 0.06), taper(0.0, -0.3, 0.0, -0.84, 0.09, 0.05), circle(0, -0.86, 0.06),
              taper(0.42, -0.3, 0.42, -0.56, 0.07, 0.045), circle(0.42, -0.58, 0.05))
    body = U(crown, drips)
    shade = _rim(body, 0.07)
    dots = U(circle(-0.8, 0.6, 0.1), circle(0.82, 0.62, 0.09), circle(-0.36, 0.84, 0.07), circle(0.62, 0.84, 0.07))
    shine = U(seg(-0.5, -0.12, -0.2, -0.12, 0.03), circle(-0.58, 0.34, 0.03))
    return [body, shade, dots, shine]


@sticker("wildstyle", "train", "TRAIN panel", ["#9AA3AF", "#6B7380", "#1A1410", "#FFC531"], ink=1.0)
def _():
    panel = box(0, 0, 0.9, 0.5, 0.06)
    edge = _rim(panel, 0.09)
    word = _lean(text("TRAIN", 0, 0.0, 1.2, stretch=0.44, maxw=1.7), 0.2)
    outline = word - 0.05
    return [panel, edge, outline, word]


@sticker("wildstyle", "dripheart", "Drip heart", ["#FF2D6F", "#B01046", "#FFFFFF", "#FFD23F"], ink=1.0)
def _():
    drips = U(taper(-0.32, -0.2, -0.32, -0.74, 0.1, 0.06), circle(-0.32, -0.76, 0.07), taper(0.0, -0.4, 0.0, -0.9, 0.09, 0.05), circle(0.0, -0.92, 0.065),
              taper(0.36, -0.2, 0.36, -0.58, 0.09, 0.06), circle(0.36, -0.6, 0.065))
    body = U(heart(0, 0.06, 0.8), drips)
    shade = _rim(body, 0.08)
    shine = U(arc(-0.3, 0.34, 0.3, math.radians(100), math.radians(170), 0.055), circle(-0.58, 0.04, 0.055))
    spark = U(star(0.78, 0.76, 4, 0.2, 0.07), star(-0.8, -0.34, 4, 0.16, 0.06))
    return [body, shade, shine, spark]


@sticker("wildstyle", "marker", "Marker", ["#1A1410", "#FF2D6F", "#27B8FF", "#4A4F59"], ink=1.0)
def _():
    with rotated(0.8, 0.1, 0.0, 0.1, 0.1):
        body = U(box(0.1, 0.0, 0.2, 0.52, 0.08), poly([(-0.06, 0.48), (0.26, 0.48), (0.1, 0.78)]))
        cap = box(0.1, -0.52, 0.23, 0.24, 0.06)
        shade = _rim(U(body, cap), 0.06)
    scribble = brush([(-0.86, -0.6), (-0.6, -0.3), (-0.4, -0.7), (-0.2, -0.36)], [0.1] * 4)
    return [body, cap, scribble, shade]


@sticker("wildstyle", "burn", "BURN", ["#2A0A10", "#FF8A00", "#E3172F", "#FFE14A"], ink=1.0)
def _():
    word = text("BURN", 0, -0.34, 1.2, stretch=0.4, maxw=1.5) - 0.012
    tongues = U(*[brush([(x, 0.0), (x + 0.12 * s_, 0.24), (x - 0.04 * s_, 0.38 + h * 0.5), (x + 0.1 * s_, 0.38 + h)], [0.15, 0.13, 0.08, 0.01])
                  for x, s_, h in [(-0.62, 1, 0.26), (-0.3, -1, 0.4), (0.02, 1, 0.26), (0.32, -1, 0.42), (0.62, 1, 0.28)]])
    outline = U(word, tongues) - 0.07
    flames = tongues
    letters = word
    heat = inter(word, Y + 0.36)
    return [outline, flames, letters, heat]
