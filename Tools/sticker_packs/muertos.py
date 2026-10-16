# Día de Muertos — marigolds, sugar-skull calaveras, papel picado, the ofrenda. Run by Tools/decor_stickers.py (every helper is in scope).
PACK = ("muertos", "Día de Muertos", False)
PRO_IDS = {"calavera", "crowned", "drummer", "alebrije", "snare", "banner", "monarch"}


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


def _leaf(ax, ay, bx, by, w):
    """A pointed leaf from (ax, ay) to (bx, by), w = half-width at the middle."""
    mx, my = (ax + bx) / 2, (ay + by) / 2
    L = math.hypot(bx - ax, by - ay) / 2
    r = (L * L + w * w) / (2 * w)
    nx, ny = -(by - ay) / (2 * L), (bx - ax) / (2 * L)
    return inter(circle(mx + nx * (r - w), my + ny * (r - w), r), circle(mx - nx * (r - w), my - ny * (r - w), r))


def _bloom(cx, cy, r, n=9, a0=0.3):
    """A ruffled marigold head: a core ringed by n round petals, extent r."""
    return U(circle(cx, cy, r * 0.62), *[circle(cx + r * 0.62 * math.cos(a0 + 2 * math.pi * k / n),
                                                cy + r * 0.62 * math.sin(a0 + 2 * math.pi * k / n), r * 0.38) for k in range(n)])


def _skull(cx, cy, s):
    """A rounded calavera head: wide cranium melting into a short jaw."""
    return smin(circle(cx, cy + 0.2 * s, 0.62 * s), box(cx, cy - 0.45 * s, 0.42 * s, 0.32 * s, 0.12 * s), 0.12 * s)


# ---- the showpiece: a sugar skull ----
@sticker("muertos", "calavera", "Sugar skull", ["#FFF4DC", "#E8318A", "#FFB41F", "#2A1240"], ink=1.0)
def _():
    skull = _skull(0, 0, 1.0)
    eyeflowers = U(petals(-0.3, 0.14, 8, 0.25, 0.1, 0.1), petals(0.3, 0.14, 8, 0.25, 0.1, 0.1))
    swirls = U(arc(-0.44, -0.3, 0.1, 0.4, 5.2, 0.04), arc(0.44, -0.3, 0.1, 3.5, 8.3, 0.04),
               petals(0, 0.6, 8, 0.11, 0.09, 0.09), seg(-0.12, 0.34, 0.12, 0.34, 0.035))
    pattern = U(eyeflowers, swirls)
    accent = U(regpoly(0, 0.6, 4, 0.12), circle(-0.55, -0.12, 0.05), circle(0.55, -0.12, 0.05), circle(-0.46, -0.52, 0.05),
               circle(0.46, -0.52, 0.05), circle(-0.3, 0.14, 0.06), circle(0.3, 0.14, 0.06))
    sockets = U(circle(-0.3, 0.14, 0.14), circle(0.3, 0.14, 0.14))
    mouth = U(seg(-0.36, -0.42, 0.36, -0.42, 0.03), *[seg(x, -0.42, x, -0.66, 0.026) for x in (-0.24, -0.12, 0.0, 0.12, 0.24)])
    detail = U(sockets, heart(0, -0.14, 0.1), mouth)
    return [skull, pattern, accent, detail]


# ---- skull with a marigold crown ----
@sticker("muertos", "crowned", "Flower-crown skull", ["#FFF4DC", "#17B8B0", "#FF9A1F", "#2A1240"], ink=1.0)
def _():
    skull = smin(circle(0, -0.1, 0.52), box(0, -0.54, 0.36, 0.28, 0.1), 0.1)
    pattern = U(*[petals(sx * 0.21, -0.12, 8, 0.15, 0.07, 0.07) for sx in (-1, 1)], arc(-0.42, -0.36, 0.08, 0.4, 5.2, 0.04),
                arc(0.42, -0.36, 0.08, 3.5, 8.3, 0.04), *[circle(sx * 0.3, 0.32, 0.05) for sx in (-1, 1)],
                *[_bloom(x, y, 0.13, n=7) for x, y in ((-0.72, 0.16), (0.72, 0.16), (-0.12, 0.62), (0.12, 0.62))])
    blooms = U(_bloom(-0.5, 0.14, 0.21), _bloom(0.5, 0.14, 0.21), _bloom(-0.27, 0.42, 0.23, a0=0.1), _bloom(0.27, 0.42, 0.23, a0=0.1),
               _bloom(0, 0.52, 0.27, n=10))
    detail = U(circle(-0.21, -0.12, 0.1), circle(0.21, -0.12, 0.1), heart(0, -0.3, 0.07),
               seg(-0.3, -0.5, 0.3, -0.5, 0.03), *[seg(x, -0.5, x, -0.7, 0.026) for x in (-0.15, 0.0, 0.15)])
    return [skull, pattern, blooms, detail]


# ---- a skeleton at a drum kit ----
@sticker("muertos", "drummer", "Skeleton drummer", ["#FFF4DC", "#17B8B0", "#FFB41F", "#2A1240"], ink=1.0)
def _():
    head = U(circle(0, 0.56, 0.31), box(0, 0.34, 0.16, 0.08, 0.05))
    ribs = oval(0, 0.1, 0.3, 0.28)
    arms = U(polyline([(-0.22, 0.14), (-0.54, 0.2), (-0.62, 0.46)], 0.13), polyline([(0.22, 0.14), (0.54, 0.2), (0.62, 0.46)], 0.13),
             circle(-0.62, 0.48, 0.16), circle(0.62, 0.48, 0.16))
    bones = U(head, ribs, arms, box(0, 0.3, 0.07, 0.1))
    drums = U(circle(0, -0.5, 0.42), *[circle(0.45 * math.cos(math.radians(15 + 30 * k)) * 0.97, -0.5 + 0.45 * math.sin(math.radians(15 + 30 * k)) * 0.97, 0.07) for k in range(12)])
    cymbals = U(seg(-0.62, 0.48, -0.78, 0.7, 0.09), circle(-0.8, 0.73, 0.11), seg(0.62, 0.48, 0.78, 0.7, 0.09), circle(0.8, 0.73, 0.11), oval(0.7, -0.04, 0.22, 0.08, -0.12), seg(0.7, -0.04, 0.7, -0.3, 0.05),
                _bloom(0, -0.5, 0.22, n=8))
    detail = U(circle(-0.11, 0.58, 0.085), circle(0.11, 0.58, 0.085), seg(-0.2, 0.08, 0.2, 0.08, 0.035), seg(-0.2, -0.04, 0.2, -0.04, 0.035),
               circle(0, -0.5, 0.08))
    return [bones, drums, cymbals, detail]


# ---- skeleton hands, sticks crossed ----
@sticker("muertos", "hands", "Bone hand", ["#D9A25B", "#FFF4DC", "#E8318A", "#2A1240"], ink=1.0)
def _():
    sticks = U(seg(-0.74, -0.74, 0.66, 0.66, 0.065), circle(0.7, 0.7, 0.1))
    hand = U(box(0, -0.28, 0.36, 0.32, 0.12), *[seg(x, -0.1, x * 1.3, y, 0.085) for x, y in ((-0.27, 0.46), (-0.09, 0.64), (0.09, 0.62), (0.27, 0.42))],
             seg(-0.3, -0.32, -0.7, 0.04, 0.095), box(0, -0.72, 0.2, 0.18, 0.06))
    pattern = U(_bloom(0, -0.26, 0.2, n=8), *[circle(x * 1.3 * 1.0, y - 0.08, 0.05) for x, y in ((-0.27, 0.46), (-0.09, 0.64), (0.09, 0.62), (0.27, 0.42))],
                box(0, -0.72, 0.2, 0.05, 0.02))
    lines = U(*[seg(x * 1.3 - 0.07, 0.12, x * 1.3 + 0.07, 0.12, 0.022) for x in (-0.27, -0.09, 0.09, 0.27)],
              circle(0, -0.26, 0.05))
    return [sticks, hand, pattern, lines]


# ---- cempasúchil ----
@sticker("muertos", "marigold", "Marigold", ["#FF9A1F", "#E5700B", "#FFD23F", "#2E9E4F"], ink=1.0)
def _():
    petals_ = _bloom(0, 0.06, 0.82, n=11)
    ruffle = U(_bloom(0, 0.06, 0.52, n=9, a0=0.0), circle(0, 0.06, 0.2))
    core = circle(0, 0.06, 0.18)
    leaves = sub(U(_leaf(0.2, -0.3, 0.72, -0.86, 0.12), _leaf(-0.2, -0.3, -0.7, -0.84, 0.12)), petals_ - 0.0)
    return [petals_, ruffle, core, leaves]


# ---- a garland of marigolds ----
@sticker("muertos", "garland", "Marigold garland", ["#2E9E4F", "#FF9A1F", "#FFD23F", "#E8318A"], ink=1.0)
def _():
    xs = [-0.66, -0.33, 0.0, 0.33, 0.66]
    ys = [0.5 - 1.0 * (1 - (x / 0.8) ** 2) for x in xs]
    pts = list(zip(xs, ys))
    string = U(polyline([(-0.86, 0.6)] + pts + [(0.86, 0.6)], 0.08), *[_leaf(x, y, x + 0.12 * (-1) ** i, y - 0.32, 0.09) for i, (x, y) in enumerate(pts[1:-1])])
    blooms = U(*[_bloom(x, y, 0.3 if 0 < i < 4 else 0.26, a0=0.2 * i) for i, (x, y) in enumerate(pts)])
    centers = U(*[circle(x, y, 0.1) for x, y in pts])
    tassels = U(*[U(circle(sx * 0.84, 0.6, 0.12), seg(sx * 0.84, 0.6, sx * 0.84, 0.3, 0.07), circle(sx * 0.84, 0.28, 0.12)) for sx in (-1, 1)])
    return [string, blooms, centers, tassels]


# ---- papel picado ----
def _flag(cx, top, w=0.125, h=0.62):
    bot = top - h
    return poly([(cx - w, top), (cx + w, top), (cx + w, bot + 0.09), (cx + w / 2, bot), (cx, bot + 0.09), (cx - w / 2, bot), (cx - w, bot + 0.09)])


def _cut(cx, top):
    mid = top - 0.28
    return U(regpoly(cx, mid, 4, 0.085), circle(cx, top - 0.1, 0.04), circle(cx - 0.065, mid - 0.17, 0.04), circle(cx + 0.065, mid - 0.17, 0.04),
             circle(cx - 0.085, mid, 0.03), circle(cx + 0.085, mid, 0.03))


@sticker("muertos", "banner", "Papel picado", ["#6B2FA0", "#E8318A", "#17B8B0", "#FFB41F"], ink=1.0)
def _():
    xs = [-0.63, -0.21, 0.21, 0.63]
    top = lambda x: 0.55 - 0.3 * (1 - (x / 0.9) ** 2)
    string = polyline([(x / 10, top(x / 10)) for x in range(-9, 10)], 0.055)
    def flag(x):
        t = top(x) + 0.02
        b = t - 1.05
        w = 0.2
        return poly([(x - w, t), (x + w, t), (x + w, b + 0.14), (x + w / 2, b), (x, b + 0.14), (x - w / 2, b), (x - w, b + 0.14)])
    def cuts(x):
        mid = top(x) - 0.4
        return U(circle(x, top(x) - 0.12, 0.05), circle(x - 0.1, mid - 0.34, 0.045), circle(x + 0.1, mid - 0.34, 0.045), circle(x, mid - 0.5, 0.05))
    def gem(x):
        return regpoly(x, top(x) - 0.4, 4, 0.13)
    fl = [sub(flag(x), cuts(x)) for x in xs]
    flags_a = U(fl[0], fl[2])
    flags_b = U(fl[1], fl[3])
    flags_c = U(*[gem(x) for x in xs])
    return [string, flags_a, flags_b, flags_c]


# ---- pan de muerto ----
@sticker("muertos", "bread", "Pan de muerto", ["#D9923B", "#FFE6B0", "#A9651E", "#FFFFFF"], ink=1.0)
def _():
    loaf = inter(oval(0, -0.12, 0.84, 0.66), -0.62 - Y)
    strips = U(*[bezier((0, 0.4), (x * 0.9, 0.34), (x * 1.08, -0.3), 0.09) for x in (-0.7, -0.3, 0.3, 0.7)],
               *[U(circle(x * 1.08 - 0.07, -0.36, 0.115), circle(x * 1.08 + 0.07, -0.36, 0.115)) for x in (-0.7, -0.3, 0.3, 0.7)],
               circle(0, 0.44, 0.19))
    bones = strips
    shade = _rim(loaf, 0.12)
    sugar = U(star(-0.58, 0.46, 4, 0.14, 0.04), star(0.62, 0.5, 4, 0.1, 0.03), circle(-0.5, -0.02, 0.045), circle(0.5, -0.04, 0.045),
              circle(0.0, 0.0, 0.045))
    return [loaf, bones, shade, sugar]


# ---- candle and marigolds ----
@sticker("muertos", "candle", "Ofrenda candle", ["#FFF4DC", "#FF8A1F", "#FFB41F", "#2E9E4F"], ink=1.0)
def _():
    wax = U(box(0, -0.12, 0.3, 0.4, 0.07), circle(0.18, 0.28, 0.07), seg(0.18, 0.26, 0.18, 0.04, 0.06), seg(-0.12, 0.3, -0.12, 0.1, 0.06))
    flame = U(circle(0, 0.5, 0.18), poly([(-0.17, 0.55), (0, 0.92), (0.17, 0.55)]))
    blooms = U(_bloom(-0.46, -0.58, 0.3), _bloom(0.46, -0.58, 0.3, a0=0.1), _bloom(0, -0.66, 0.28, a0=0.5), _bloom(-0.78, -0.42, 0.14),
               _bloom(0.78, -0.42, 0.14, a0=0.4))
    leaves = U(_leaf(0.4, -0.4, 0.88, -0.14, 0.1), _leaf(-0.4, -0.4, -0.88, -0.14, 0.1))
    return [wax, flame, blooms, leaves]


# ---- monarch butterfly ----
def _wing(sx):
    up = poly(spline([(sx * 0.05, 0.06), (sx * 0.2, 0.55), (sx * 0.6, 0.86), (sx * 0.88, 0.66), (sx * 0.8, 0.26), (sx * 0.4, 0.0)], closed=True))
    low = poly(spline([(sx * 0.05, 0.0), (sx * 0.45, -0.05), (sx * 0.66, -0.34), (sx * 0.52, -0.74), (sx * 0.22, -0.7), (sx * 0.05, -0.36)], closed=True))
    return U(up, low)


@sticker("muertos", "monarch", "Monarch butterfly", ["#2A1240", "#FF8A1F", "#2A1240", "#FFFFFF"], ink=1.0)
def _():
    full = U(_wing(-1), _wing(1))
    edge = full
    wings = full + 0.1
    veins = U(oval(0, -0.02, 0.07, 0.4), circle(0, 0.44, 0.075), seg(0, 0.46, -0.16, 0.78, 0.024), seg(0, 0.46, 0.16, 0.78, 0.024),
              *[seg(sx * 0.06, 0.08, sx * ex, ey, 0.026) for sx in (-1, 1) for ex, ey in ((0.66, 0.66), (0.78, 0.4), (0.52, -0.02), (0.5, -0.5))])
    spots = inter(U(*[circle(sx * x, y, 0.05) for sx in (-1, 1) for x, y in ((0.6, 0.86), (0.86, 0.68), (0.88, 0.4), (0.56, -0.7), (0.34, -0.72), (0.8, 0.24))]), full + 0.01)
    return [edge, wings, veins, spots]


# ---- an invented spirit creature, alebrije style ----
@sticker("muertos", "alebrije", "Spirit creature", ["#17B8B0", "#E8318A", "#FFB41F", "#2A1240"], ink=1.0)
def _():
    torso = oval(-0.08, -0.12, 0.44, 0.27)
    head = U(circle(0.42, 0.18, 0.29), taper(0.5, 0.12, 0.88, 0.02, 0.2, 0.1))
    neck = taper(0.18, -0.02, 0.4, 0.14, 0.2, 0.2)
    legs = U(seg(-0.36, -0.3, -0.42, -0.72, 0.12), seg(-0.12, -0.34, -0.08, -0.74, 0.12), seg(0.2, -0.32, 0.26, -0.72, 0.12),
             seg(0.38, -0.2, 0.52, -0.66, 0.12))
    tail = brush([(-0.46, -0.14), (-0.82, -0.04), (-0.86, 0.32), (-0.6, 0.46), (-0.5, 0.28)], [0.12, 0.1, 0.08, 0.06, 0.04])
    body = U(torso, head, neck, legs, tail)
    pattern = U(*[circle(x, y, 0.065) for x, y in ((-0.3, -0.04), (-0.08, 0.04), (0.14, -0.04), (-0.2, -0.24), (0.04, -0.26))],
                circle(0.4, 0.34, 0.06),
                *[seg(x - 0.06, y, x + 0.06, y, 0.028) for x, y in ((-0.42, -0.5), (-0.08, -0.55), (0.26, -0.5), (0.52, -0.46))])
    trim = U(_leaf(-0.3, 0.1, -0.1, 0.78, 0.15), _leaf(-0.14, 0.12, 0.2, 0.7, 0.14), _leaf(-0.45, 0.06, -0.62, 0.6, 0.12),
             bezier((0.38, 0.38), (0.3, 0.74), (0.58, 0.84), 0.085), bezier((0.5, 0.4), (0.62, 0.68), (0.82, 0.66), 0.08),
             circle(-0.5, 0.28, 0.07))
    detail = U(circle(0.5, 0.24, 0.065), circle(0.9, 0.03, 0.045), seg(0.5, 0.0, 0.64, -0.03, 0.02))
    return [body, pattern, trim, detail]


# ---- sugar-skull snare ----
@sticker("muertos", "snare", "Sugar-skull snare", ["#17B8B0", "#FFF4DC", "#E8318A", "#2A1240"], ink=1.0)
def _():
    shell_ = U(box(0, -0.2, 0.68, 0.3), oval(0, -0.5, 0.68, 0.22), oval(0, 0.1, 0.68, 0.22))
    sticks = sub(U(seg(-0.5, 0.05, 0.62, 0.8, 0.065), seg(0.5, 0.05, -0.62, 0.8, 0.065), circle(0.66, 0.84, 0.1), circle(-0.66, 0.84, 0.1)), shell_)
    head = U(oval(0, 0.1, 0.57, 0.17), circle(0, -0.22, 0.21), box(0, -0.38, 0.12, 0.08, 0.04), sticks)
    hoop = U(sub(oval(0, 0.1, 0.68, 0.22), oval(0, 0.1, 0.57, 0.17)), *[box(x, -0.18, 0.045, 0.26, 0.02) for x in (-0.52, -0.34, 0.34, 0.52)],
             inter(sub(oval(0, -0.5, 0.68, 0.22), oval(0, -0.56, 0.62, 0.2)), -0.3 - Y))
    detail = U(circle(-0.08, -0.2, 0.06), circle(0.08, -0.2, 0.06), seg(-0.1, -0.4, 0.1, -0.4, 0.02), seg(0, -0.34, 0, -0.44, 0.02))
    return [shell_, head, hoop, detail]


# ---- an empty frame for someone remembered ----
@sticker("muertos", "frame", "Photo frame", ["#FFB41F", "#FFF4DC", "#FF8A1F", "#2E9E4F"], ink=1.0)
def _():
    outer = box(0, 0, 0.62, 0.74, 0.08)
    frame = sub(outer, box(0, 0, 0.46, 0.58, 0.04))
    pane = box(0, 0, 0.46, 0.58, 0.04)
    blooms = U(_bloom(-0.5, 0.64, 0.26), _bloom(-0.72, 0.38, 0.18, a0=0.5), _bloom(0.52, -0.66, 0.28, a0=0.2), _bloom(0.74, -0.4, 0.18),
               _bloom(0.28, -0.78, 0.17, a0=0.6))
    leaves = sub(U(_leaf(-0.34, 0.74, -0.04, 0.9, 0.08), _leaf(0.1, -0.6, 0.38, -0.86, 0.08), _leaf(-0.7, 0.62, -0.88, 0.3, 0.07)), blooms)
    return [frame, pane, blooms, leaves]


# ---- hummingbird and flower ----
@sticker("muertos", "hummingbird", "Hummingbird", ["#17B8B0", "#E8318A", "#FFB41F", "#2A1240"], ink=1.0)
def _():
    body = U(circle(0.1, 0.1, 0.23), oval(-0.24, -0.16, 0.42, 0.22, 0.5),
             taper(-0.5, -0.34, -0.84, -0.72, 0.1, 0.03), taper(-0.5, -0.34, -0.62, -0.84, 0.1, 0.03))
    wing = _leaf(-0.2, -0.04, -0.7, 0.62, 0.23)
    flower = U(petals(0.64, 0.34, 5, 0.17, 0.13, 0.13), circle(0.64, 0.34, 0.15))
    detail = U(taper(0.28, 0.16, 0.6, 0.3, 0.085, 0.04), circle(0.14, 0.17, 0.055), circle(0.64, 0.34, 0.07))
    return [body, wing, flower, detail]


# ---- a skeleton guitar ----
@sticker("muertos", "guitar", "Bone guitar", ["#C2185B", "#FFF4DC", "#FFB41F", "#2A1240"], ink=1.0)
def _():
    with rotated(-0.7):
        body = U(smin(circle(0, -0.5, 0.42), circle(0, -0.08, 0.3), 0.18), circle(-0.2, 0.06, 0.12), circle(0.2, 0.06, 0.12))
        bones = U(box(0, 0.42, 0.08, 0.4, 0.03), circle(-0.08, 0.86, 0.085), circle(0.08, 0.86, 0.085), box(0, 0.76, 0.12, 0.1, 0.02),
                  smin(circle(0, -0.46, 0.27), box(0, -0.64, 0.16, 0.12, 0.05), 0.08))
        trim = U(box(0, -0.18, 0.2, 0.06, 0.02), box(0, 0.0, 0.2, 0.06, 0.02), shell(circle(0, -0.5, 0.38), 0.03))
        detail = U(circle(-0.1, -0.48, 0.07), circle(0.1, -0.48, 0.07), heart(0, -0.62, 0.05), box(0, -0.9, 0.2, 0.035, 0.01))
    return [body, bones, trim, detail]


# ---- VIVA ----
@sticker("muertos", "viva", "VIVA", ["#E8318A", "#17B8B0", "#FFF4DC", "#FFB41F"], ink=1.0)
def _():
    plaque = box(0, 0, 0.86, 0.46, 0.12)
    border = shell(box(0, 0, 0.76, 0.36, 0.08), 0.035)
    word = text("VIVA", 0, 0.0, 0.5, maxw=1.35, stretch=1.0)
    blooms = U(_bloom(-0.8, 0.46, 0.18), _bloom(0.8, -0.46, 0.18, a0=0.5))
    return [plaque, border, word, blooms]


# ---- maracas ----
@sticker("muertos", "maracas", "Maracas", ["#17B8B0", "#D9A25B", "#FFB41F", "#E8318A"], ink=1.0)
def _():
    heads = U(circle(-0.4, 0.38, 0.34), circle(0.4, 0.38, 0.34))
    handles = U(seg(-0.4, 0.38, 0.32, -0.78, 0.07), seg(0.4, 0.38, -0.32, -0.78, 0.07), circle(0.34, -0.8, 0.1), circle(-0.34, -0.8, 0.1))
    pattern = U(petals(-0.4, 0.38, 6, 0.14, 0.09, 0.09), petals(0.4, 0.38, 6, 0.14, 0.09, 0.09))
    dots = U(circle(-0.4, 0.38, 0.07), circle(0.4, 0.38, 0.07), circle(-0.4, 0.14, 0.04), circle(0.4, 0.14, 0.04))
    return [heads, handles, pattern, dots]
