PACK = ("mom", "Mother's Day", False)
PRO_IDS = {"bouquet", "badge", "birds", "wreath", "cape", "locket"}


def _shift(make, dx, dy):
    """The shape `make()` draws, slid by (dx, dy)."""
    with rotated(0.0, 0.0, 0.0, dx, dy):
        return make()


def _rim(make, dx=-0.1, dy=0.1):
    """Lower-right shade: the shape minus a copy of itself nudged up-left."""
    return sub(make(), _shift(make, dx, dy))


def _lowr(d, c=0.12):
    """The lower-right part of d (beyond a diagonal)."""
    return inter(d, c - (X - Y) * 0.7071)


def _bloom(cx, cy, r, n=5):
    """A flower: (petals, centre) with the petals reaching about r out."""
    return petals(cx, cy, n, r * 0.62, r * 0.42, r * 0.36), circle(cx, cy, r * 0.3)


def _leaf(cx, cy, ang, ln, wd):
    """A leaf: base at (cx, cy), `ln` long along ang."""
    return oval(cx + math.cos(ang) * ln / 2, cy + math.sin(ang) * ln / 2, ln / 2, wd, ang)


# ---- bouquet ----
@sticker("mom", "bouquet", "Bouquet", ["#FF6FA8", "#D63A7E", "#FFF3D6", "#2E9E4F"], ink=1.0)
def _():
    p1, c1 = _bloom(-0.4, 0.34, 0.38)
    p2, c2 = _bloom(0.4, 0.34, 0.38)
    p3, c3 = _bloom(0.0, 0.58, 0.38)
    blooms = U(p1, c1, p2, c2, p3, c3)
    bow = U(oval(-0.2, -0.3, 0.2, 0.11, 0.5), oval(0.2, -0.3, 0.2, 0.11, -0.5), circle(0, -0.3, 0.09))
    shade = U(c1, c2, c3, inter(blooms, 0.1 - (X - Y) * 0.7071), bow)
    wrap = poly([(-0.74, 0.22), (0.74, 0.22), (0.13, -0.88), (-0.13, -0.88)])
    leaves = U(_leaf(-0.6, 0.2, 2.7, 0.34, 0.1), _leaf(0.6, 0.2, 0.45, 0.34, 0.1))
    return [blooms, shade, wrap, leaves]


# ---- #1 MOM ribbon badge ----
@sticker("mom", "badge", "Mom badge", ["#FF4F8B", "#BC2467", "#7B3FC4", "#FFFFFF"], ink=1.0)
def _():
    rosette = U(star(0, 0.4, 16, 0.58, 0.5), circle(0, 0.4, 0.51))
    shade = sub(inter(rosette, 0.4 - (X - Y) * 0.7071), circle(-0.05, 0.45, 0.45))
    band = poly([(-0.94, -0.06), (0.94, -0.06), (0.82, -0.48), (0.94, -0.9), (-0.94, -0.9), (-0.82, -0.48)])
    ribbon = sub(band, rosette)
    words = U(text("#1", 0, 0.4, 0.5, maxw=0.8), text("MOM", 0, -0.48, 0.5, maxw=1.45))
    return [rosette, shade, ribbon, words]


# ---- handmade card ----
def _card_build():
    return box(0, 0, 0.64, 0.8, 0.06)


@sticker("mom", "card", "Handmade card", ["#FFF6E2", "#E0CFA8", "#FF4F8B", "#FFC531"], ink=1.0)
def _():
    with rotated(-0.2, 0, 0):
        card = _card_build()
        shade = _rim(_card_build, -0.08, 0.08)
        drawing = U(petals(0.0, 0.0, 6, 0.26, 0.19, 0.15), seg(0, -0.25, 0, -0.74, 0.06), _leaf(0.0, -0.5, 0.5, 0.36, 0.08))
        stars = U(circle(0.0, 0.0, 0.14), star(-0.38, 0.58, 5, 0.15, 0.065), star(0.38, 0.58, 5, 0.15, 0.065))
    return [card, shade, drawing, stars]


# ---- teacup ----
@sticker("mom", "teacup", "Teacup", ["#FFF8F0", "#9DB6D8", "#FF6FA8", "#B8743C"], ink=1.0)
def _():
    cup = U(inter(box(-0.05, 0.0, 0.58, 0.46, 0.28), (Y - 0.3)), ring(0.62, 0.1, 0.2, 0.07))
    saucer = ellipse(-0.05, -0.5, 0.8, 0.13)
    shade = U(saucer, inter(cup, 0.1 - (X - Y) * 0.7071))
    love = heart(-0.05, 0.04, 0.44)
    tea = U(oval(-0.05, 0.3, 0.48, 0.07), seg(-0.3, 0.32, -0.64, 0.12, 0.04), box(-0.68, 0.02, 0.1, 0.13, 0.02, 0.4), brush([(-0.15, 0.48), (-0.28, 0.64), (-0.12, 0.78), (-0.22, 0.92)], [0.06, 0.06, 0.06, 0.05]),
            brush([(0.12, 0.48), (0.02, 0.64), (0.18, 0.76), (0.1, 0.9)], [0.06, 0.06, 0.06, 0.05]))
    return [cup, shade, love, tea]


# ---- heart locket ----
def _locket_build():
    return heart(0, -0.12, 1.05)


@sticker("mom", "locket", "Locket", ["#FFC531", "#D8960F", "#C9D2E0", "#FF4F8B"], ink=1.0)
def _():
    locket = _locket_build()
    shade = _rim(_locket_build, -0.1, 0.1)
    chain = U(ring(0, 0.74, 0.12, 0.07), polyline([(-0.6, 0.92), (-0.1, 0.8)], 0.07), polyline([(0.6, 0.92), (0.1, 0.8)], 0.07))
    gem = heart(0, -0.08, 0.55)
    return [locket, shade, chain, gem]


# ---- sun hat ----
def _hat_build():
    return U(oval(0, -0.3, 0.92, 0.3), inter(oval(0, -0.3, 0.52, 0.72), -(Y + 0.3)))


@sticker("mom", "sunhat", "Sun hat", ["#F3D58A", "#C89C3E", "#E85A8F", "#FFFFFF"], ink=1.0)
def _():
    hat = _hat_build()
    shade = _rim(_hat_build, -0.1, 0.1)
    band = inter(box(0, -0.27, 0.6, 0.1), oval(0, -0.3, 0.52, 0.72))
    pet, cen = _bloom(-0.3, 0.0, 0.36, 6)
    flower = sub(U(pet, cen), circle(-0.3, 0.0, 0.08))
    return [hat, shade, band, flower]


# ---- breakfast in bed ----
@sticker("mom", "tray", "Breakfast tray", ["#B8743C", "#7E4A1E", "#FFFFFF", "#FFB02E"], ink=1.0)
def _():
    tray = U(box(0, -0.5, 0.92, 0.2, 0.1), poly([(-0.6, -0.65), (-0.42, -0.65), (-0.2, -0.92), (-0.38, -0.92)]), poly([(0.6, -0.65), (0.42, -0.65), (0.2, -0.92), (0.38, -0.92)]))
    shade = inter(tray, -(Y + 0.5))
    china = U(box(-0.4, 0.02, 0.32, 0.32, 0.1), ring(-0.04, 0.02, 0.14, 0.07))
    treats = U(box(0.46, 0.0, 0.3, 0.3, 0.06), circle(0.34, 0.3, 0.17), circle(0.58, 0.3, 0.17),
               brush([(-0.5, 0.5), (-0.6, 0.64), (-0.46, 0.78), (-0.54, 0.9)], [0.07, 0.07, 0.07, 0.05]),
               brush([(-0.3, 0.5), (-0.38, 0.64), (-0.26, 0.76), (-0.32, 0.88)], [0.07, 0.07, 0.07, 0.05]))
    return [tray, shade, china, treats]


# ---- potted plant ----
def _pot_build():
    return U(poly([(-0.5, -0.22), (0.5, -0.22), (0.38, -0.9), (-0.38, -0.9)]), box(0, -0.2, 0.58, 0.1, 0.04))


@sticker("mom", "plant", "Potted plant", ["#D9703A", "#A34C1E", "#2E9E4F", "#F2A36B"], ink=1.0)
def _():
    pot = _pot_build()
    shade = _rim(_pot_build, -0.1, 0.1)
    leaves = U(_leaf(0, -0.15, 1.57, 0.95, 0.17), _leaf(0, -0.15, 0.95, 0.8, 0.16), _leaf(0, -0.15, 2.19, 0.8, 0.16),
               _leaf(0, -0.15, 0.3, 0.7, 0.14), _leaf(0, -0.15, 2.84, 0.7, 0.14))
    rim = box(0, -0.2, 0.58, 0.1, 0.04)
    return [pot, shade, leaves, rim]


# ---- heart balloon ----
def _hballoon_build():
    return heart(0, 0.22, 1.1)


@sticker("mom", "balloon", "Heart balloon", ["#FF6A3D", "#C2381A", "#FFFFFF", "#8A4A2B"], ink=1.0)
def _():
    balloon = _hballoon_build()
    shade = _rim(_hballoon_build, -0.12, 0.12)
    shine = seg(-0.5, 0.6, -0.36, 0.74, 0.06)
    string = U(poly([(0, -0.5), (-0.1, -0.62), (0.1, -0.62)]), brush([(0, -0.6), (-0.14, -0.68), (0.1, -0.78), (0, -0.86)], [0.08, 0.075, 0.075, 0.075]))
    return [balloon, shade, shine, string]


# ---- LOVE YOU note ----
def _note_build():
    return box(0, -0.05, 0.7, 0.7, 0.06)


@sticker("mom", "note", "Love note", ["#FFC2D9", "#E58BB0", "#E3172F", "#FFF6B0"], ink=1.0)
def _():
    with rotated(0.12, 0, 0):
        note = _note_build()
        shade = _rim(_note_build, -0.08, 0.08)
        tape = box(0, 0.7, 0.3, 0.1, 0.02, -0.08)
    words = U(text("LOVE", 0.045, 0.2, 0.3, ang=0.12, maxw=1.0), text("YOU", 0.0, -0.3, 0.3, ang=0.12, maxw=0.8))
    return [note, shade, words, tape]


# ---- gift box ----
@sticker("mom", "gift", "Gift", ["#FF8FC2", "#D4579A", "#7B3FC4", "#FFFFFF"], ink=1.0)
def _():
    with rotated(0.2, 0, -0.1):
        base = U(box(0, -0.3, 0.64, 0.44, 0.05), box(0, 0.16, 0.74, 0.15, 0.05))
        shade = U(inter(base, -(Y + 0.4)), inter(box(0, 0.16, 0.74, 0.15, 0.05), -(X - 0.4)))
        ribbon = U(box(0, -0.1, 0.12, 0.66), oval(-0.3, 0.46, 0.3, 0.15, 0.5), oval(0.3, 0.46, 0.3, 0.15, -0.5), circle(0, 0.38, 0.12))
        dots = U(*[circle(x, y, 0.08) for x in (-0.4, 0.4) for y in (-0.12, -0.5)])
    return [base, shade, ribbon, dots]


# ---- spa robe ----
def _robe_build():
    return U(poly([(-0.4, 0.74), (0.4, 0.74), (0.52, -0.82), (-0.52, -0.82)]),
             taper(-0.34, 0.58, -0.76, -0.28, 0.15, 0.19), taper(0.34, 0.58, 0.76, -0.28, 0.15, 0.19))


@sticker("mom", "robe", "Spa robe", ["#FFFFFF", "#C9D6E8", "#FF8FC2", "#6FC3E8"], ink=1.0)
def _():
    robe = _robe_build()
    shade = _lowr(robe, 0.2)
    trim = U(taper(-0.3, 0.7, 0.12, -0.2, 0.13, 0.09), taper(0.3, 0.7, -0.12, -0.2, 0.13, 0.09), box(0, -0.26, 0.54, 0.08),
             poly([(0.0, -0.26), (-0.1, -0.66), (0.02, -0.6), (0.1, -0.66)]))
    cuffs = U(circle(-0.76, -0.3, 0.19), circle(0.76, -0.3, 0.19))
    return [robe, shade, trim, cuffs]


# ---- heart made of flowers ----
def _hpt(t):
    x = 16 * math.sin(t) ** 3
    y = 13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)
    return (x * 0.048, (y + 2.4) * 0.048 + 0.02)


@sticker("mom", "wreath", "Flower heart", ["#2E9E4F", "#FF6FA8", "#FFE14A", "#FFFFFF"], ink=1.0)
def _():
    n = 9
    ts = [2 * math.pi * k / n + 0.0 for k in range(n)]
    ring_pts = [_hpt(2 * math.pi * k / 40) for k in range(41)]
    wreath = U(polyline(ring_pts, 0.15), *[_leaf(_hpt(t + math.pi / n)[0], _hpt(t + math.pi / n)[1], t + 1.2, 0.3, 0.07) for t in ts])
    blooms = U(*[petals(_hpt(t)[0], _hpt(t)[1], 5, 0.11, 0.09, 0.075, t) for t in ts])
    centers = U(*[circle(_hpt(t)[0], _hpt(t)[1], 0.05) for t in ts])
    buds = U(*[circle(_hpt(t + math.pi / n)[0], _hpt(t + math.pi / n)[1], 0.065) for t in ts])
    return [wreath, blooms, centers, buds]


# ---- mama and baby bird ----
@sticker("mom", "birds", "Mama bird", ["#B8743C", "#4FA8F0", "#FFD84A", "#3A2412"], ink=1.0)
def _():
    nest = U(inter(oval(0, -0.4, 0.92, 0.52), -(Y + 0.4) * -1.0 + 0.0), oval(0, -0.4, 0.92, 0.2))
    mama = U(oval(-0.22, 0.04, 0.5, 0.36, -0.2), circle(0.14, 0.38, 0.27), poly([(-0.6, 0.18), (-0.96, 0.42), (-0.84, 0.0), (-0.55, -0.05)]))
    baby = U(circle(0.5, -0.2, 0.3), poly([(0.38, 0.06), (0.46, 0.24), (0.56, 0.06)]))
    face = U(circle(0.2, 0.44, 0.06), poly([(0.36, 0.48), (0.7, 0.4), (0.38, 0.32)]), circle(0.52, -0.16, 0.06),
             poly([(0.66, -0.12), (0.92, -0.2), (0.66, -0.28)]))
    return [nest, mama, baby, face]


# ---- SUPER MOM cape ----
@sticker("mom", "cape", "Super Mom", ["#E3172F", "#A60F22", "#FFC531", "#E3172F"], ink=1.0)
def _():
    cape = poly([(-0.36, 0.84), (0.36, 0.84), (0.52, 0.3), (0.88, -0.78), (0.45, -0.62), (0.0, -0.86), (-0.45, -0.62), (-0.88, -0.78), (-0.52, 0.3)])
    shade = _lowr(cape, 0.3)
    emblem = U(poly([(-0.5, 0.52), (0.5, 0.52), (0.5, -0.05), (0.0, -0.58), (-0.5, -0.05)]), circle(-0.34, 0.8, 0.1), circle(0.34, 0.8, 0.1))
    words = text("MOM", 0, 0.14, 0.34, maxw=0.8)
    return [cape, shade, emblem, words]


# ---- pearls ----
@sticker("mom", "pearls", "Pearls", ["#FFF4EC", "#C9B9B0", "#FFC531", "#FF4F8B"], ink=1.0)
def _():
    angs = [-1.2 + 2.4 * k / 8 for k in range(9)]
    pts = [(0.76 * math.sin(a) / 0.932, 0.62 - 1.0 * math.cos(a)) for a in angs]
    beads = U(*[circle(x, y, 0.19) for x, y in pts])
    shade = U(*[inter(circle(x, y, 0.19), -0.02 - ((X - x) - (Y - y)) * 0.7071) for x, y in pts])
    clasp = U(box(pts[0][0], pts[0][1] + 0.12, 0.1, 0.06, 0.02), box(pts[-1][0], pts[-1][1] + 0.12, 0.1, 0.06, 0.02),
              circle(pts[0][0], pts[0][1] + 0.2, 0.1), circle(pts[-1][0], pts[-1][1] + 0.2, 0.1))
    drop = heart(0, pts[4][1] - 0.2, 0.42)
    return [beads, shade, clasp, drop]


# ---- perfume ----
@sticker("mom", "perfume", "Perfume", ["#C9A8FF", "#8A63D6", "#FFC531", "#FF4F8B"], ink=1.0)
def _():
    glass = U(box(0, -0.2, 0.52, 0.5, 0.16), box(0, 0.38, 0.14, 0.14, 0.03))
    shade = _lowr(glass, 0.1)
    cap = U(circle(0, 0.68, 0.2), box(0, 0.5, 0.2, 0.08, 0.03), seg(-0.3, 0.74, -0.72, 0.84, 0.09), circle(-0.76, 0.5, 0.08), circle(-0.84, 0.68, 0.07))
    label = U(petals(0, -0.18, 5, 0.17, 0.13, 0.1), circle(0, -0.18, 0.1))
    return [glass, shade, cap, label]
