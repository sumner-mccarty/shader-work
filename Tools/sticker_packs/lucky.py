PACK = ("lucky", "Lucky", False)
PRO_IDS = {"rainbow", "harp", "tallhat", "rosette", "banner", "shootingstar"}


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


def _glint(cx, cy, r):
    """A bold four-point sparkle."""
    return star(cx, cy, 4, r, r * 0.38, math.pi / 2)


def _leaf3(cx, cy, s, ang=0.0):
    """Three heart leaves meeting at (cx, cy), one pointing up before `ang` turns them."""
    with rotated(ang, cx, cy):
        return U(*[_turned(cx, cy, s, k * 2.0943951) for k in range(3)])


def _turned(cx, cy, s, a):
    with rotated(a, cx, cy):
        return heart(cx, cy + 0.61 * s, s)


# ---- shamrock ----
def _shamrock_build():
    return _leaf3(0.0, 0.0, 0.62)


@sticker("lucky", "shamrock", "Shamrock", ["#2FB67A", "#1B8A58", "#BFF2D4", "#137A3C"], ink=1.0)
def _():
    leaves = _shamrock_build()
    shade = _rim(_shamrock_build, -0.1, 0.1)
    veins = U(*[seg(0.0, 0.0, 0.5 * math.cos(math.radians(a)), 0.5 * math.sin(math.radians(a)), 0.045) for a in (90, 210, 330)])
    stem = brush([(0.0, -0.1), (0.1, -0.5), (0.3, -0.76), (0.52, -0.62)], [0.09, 0.08, 0.07, 0.06])
    return [leaves, shade, veins, stem]


# ---- rainbow and pot of gold ----
@sticker("lucky", "rainbow", "Pot of gold", ["#FF4F4F", "#FFC531", "#2FB67A", "#2B2E3A"], ink=1.0)
def _():
    cx, cy = -0.1, -0.4
    red = arc(cx, cy, 0.74, 0.0, math.pi, 0.1)
    yellow = U(arc(cx, cy, 0.58, 0.0, math.pi, 0.1), circle(0.52, -0.3, 0.12), circle(0.72, -0.34, 0.11), circle(0.62, -0.18, 0.12))
    green = arc(cx, cy, 0.42, 0.0, math.pi, 0.1)
    pot = U(circle(0.62, -0.58, 0.3), box(0.62, -0.32, 0.26, 0.05, 0.02))
    outer, middle, inner = red, yellow, green
    return [outer, middle, inner, pot]


# ---- lucky coin ----
@sticker("lucky", "coin", "Lucky penny", ["#FFC531", "#E09A12", "#2FB67A", "#FFF4C7"], ink=1.0)
def _():
    coin = circle(0.0, 0.0, 0.8)
    rim = sub(circle(0.0, 0.0, 0.8), circle(0.0, 0.0, 0.62))
    clover = U(_leaf3(0.0, 0.1, 0.42), seg(0.0, 0.1, 0.1, -0.5, 0.07))
    shine = arc(0.0, 0.0, 0.52, math.radians(115), math.radians(160), 0.045)
    return [coin, rim, clover, shine]


# ---- green bowler ----
def _bowler_build():
    return U(inter(oval(0.0, -0.1, 0.52, 0.62), -0.1 - Y), oval(0.0, -0.3, 0.88, 0.2))


@sticker("lucky", "bowler", "Green bowler", ["#2FB67A", "#1B8A58", "#FFC531", "#BFF2D4"], ink=1.0)
def _():
    hat = _bowler_build()
    shade = _rim(_bowler_build, -0.1, 0.1)
    band = inter(hat, box(0.0, -0.18, 1.0, 0.1))
    clover = _clover_tip(0.0, 0.2, 0.1)
    return [hat, shade, band, clover]


# ---- ladybug ----
@sticker("lucky", "ladybug", "Ladybug", ["#E3172F", "#A80E22", "#1A1410", "#2FB67A"], ink=1.0)
def _():
    body = oval(0.0, -0.1, 0.6, 0.62)
    shade = _lowr(body, 0.1)
    spots = U(circle(0.0, 0.58, 0.28), seg(0.0, 0.5, 0.0, -0.72, 0.05), circle(-0.3, -0.34, 0.1), circle(0.3, -0.34, 0.1),
              seg(-0.14, 0.78, -0.26, 0.88, 0.05), seg(0.14, 0.78, 0.26, 0.88, 0.05))
    clover = U(_clover_tip(-0.2, 0.1, 0.1), _clover_tip(0.2, 0.1, 0.1))
    return [body, shade, spots, clover]


# ---- coin trail ----
@sticker("lucky", "trail", "Coin trail", ["#FFC531", "#E09A12", "#FFF4C7", "#FFFFFF"], ink=1.0)
def _():
    spots = [(-0.5, -0.5, 0.31), (-0.04, -0.06, 0.35), (0.46, 0.4, 0.38)]
    coins = U(*[oval(x, y, r * 0.8, r, 0.5) for (x, y, r) in spots])
    shade = _lowr(coins, 0.0)
    rims = U(*[ring(x, y, r * 0.5, 0.05) for (x, y, r) in spots])
    return [coins, shade, rims]


# ---- tall green hat with buckle ----
def _tallhat_build():
    return U(poly([(-0.42, 0.7), (0.42, 0.7), (0.5, -0.4), (-0.5, -0.4)]), oval(0.0, -0.44, 0.84, 0.18), oval(0.0, 0.7, 0.42, 0.08))


@sticker("lucky", "tallhat", "Buckle hat", ["#2FB67A", "#1B8A58", "#1A1410", "#FFC531"], ink=1.0)
def _():
    hat = _tallhat_build()
    shade = _lowr(hat, 0.2)
    band = inter(hat, box(0.0, -0.22, 1.0, 0.14))
    buckle = sub(box(0.0, -0.22, 0.2, 0.2, 0.04), box(0.0, -0.22, 0.1, 0.1, 0.02))
    return [hat, shade, band, buckle]


# ---- harp ----
_NECK = [(-0.6, 0.76), (0.0, 0.92), (0.6, 0.1)]


def _neck_y(x):
    best = None
    for k in range(61):
        t = k / 60.0
        px = (1 - t) ** 2 * _NECK[0][0] + 2 * (1 - t) * t * _NECK[1][0] + t * t * _NECK[2][0]
        py = (1 - t) ** 2 * _NECK[0][1] + 2 * (1 - t) * t * _NECK[1][1] + t * t * _NECK[2][1]
        if best is None or abs(px - x) < best[0]:
            best = (abs(px - x), py)
    return best[1]


def _harp_frame():
    return U(bezier(_NECK[0], _NECK[1], _NECK[2], 0.1), seg(-0.6, 0.76, -0.6, -0.78, 0.1), seg(-0.6, -0.78, 0.6, 0.1, 0.1))


@sticker("lucky", "harp", "Harp", ["#E0A030", "#B07412", "#5A3A1A", "#2FB67A"], ink=1.0)
def _():
    frame = _harp_frame()
    shade = _lowr(frame, 0.2)
    strings = U(*[seg(x, -0.78 + 0.733 * (x + 0.6) + 0.06, x, _neck_y(x) - 0.05, 0.05) for x in (-0.32, -0.06, 0.2, 0.44)])
    gems = U(circle(-0.6, 0.76, 0.17), circle(0.6, 0.1, 0.17), circle(-0.6, -0.78, 0.17))
    return [frame, shade, strings, gems]


# ---- LUCKY banner ----
@sticker("lucky", "banner", "LUCKY", ["#2FB67A", "#1B8A58", "#FFFFFF", "#FFC531"], ink=1.0)
def _():
    tails = U(poly([(-0.9, -0.16), (-0.6, -0.16), (-0.6, -0.56), (-0.9, -0.56), (-0.8, -0.36)]), poly([(0.9, -0.16), (0.6, -0.16), (0.6, -0.56), (0.9, -0.56), (0.8, -0.36)]))
    band = box(0.0, 0.0, 0.8, 0.38, 0.06)
    word = text("LUCKY", 0.0, 0.0, 0.42, maxw=1.4)
    trim = sub(box(0.0, 0.0, 0.8, 0.38, 0.06), box(0.0, 0.0, 0.73, 0.31, 0.04))
    return [tails, band, trim, word]


# ---- wishbone ----
def _wish_build():
    left = brush([(-0.62, 0.76), (-0.46, 0.16), (0.0, -0.52)], [0.13, 0.11, 0.15])
    right = brush([(0.62, 0.76), (0.46, 0.16), (0.0, -0.52)], [0.13, 0.11, 0.15])
    return U(left, right, circle(-0.62, 0.74, 0.17), circle(0.62, 0.74, 0.17), circle(0.0, -0.62, 0.17))


@sticker("lucky", "wishbone", "Wishbone", ["#FFF1D6", "#E6C99A", "#FFFFFF", "#2FB67A"], ink=1.0)
def _():
    bone = _wish_build()
    shade = _rim(_wish_build, -0.08, 0.08)
    shine = U(oval(-0.5, 0.5, 0.05, 0.14, 0.2), circle(-0.64, 0.84, 0.05))
    clover = _clover_tip(0.0, 0.44, 0.12)
    return [bone, shade, shine, clover]


# ---- lucky star ----
def _lstar_build():
    return star(0.34, 0.34, 5, 0.52, 0.26) - 0.05


@sticker("lucky", "shootingstar", "Lucky star", ["#FF4F4F", "#FFC531", "#E09A12", "#2FB67A"], ink=1.0)
def _():
    tail = brush([(0.1, 0.1), (-0.3, -0.3), (-0.78, -0.6)], [0.18, 0.13, 0.03])
    body = _lstar_build()
    shade = _rim(_lstar_build, -0.08, 0.08)
    streak = brush([(0.0, 0.3), (-0.4, 0.0), (-0.84, -0.14)], [0.1, 0.08, 0.02])
    return [tail, body, shade, streak]


# ---- clover drumsticks ----
def _clover_tip(cx, cy, r):
    return U(circle(cx - r * 0.9, cy, r), circle(cx + r * 0.9, cy, r), circle(cx, cy + r * 1.0, r), circle(cx, cy - r * 0.2, r))


@sticker("lucky", "sticks", "Clover sticks", ["#C98B4B", "#7A4A2B", "#2FB67A", "#BFF2D4"], ink=1.0)
def _():
    sticks = U(taper(-0.7, -0.7, 0.28, 0.28, 0.06, 0.1), taper(0.7, -0.7, -0.28, 0.28, 0.06, 0.1))
    shade = _lowr(sticks, 0.0)
    tips = U(_leaf3(0.4, 0.3, 0.3), _leaf3(-0.4, 0.3, 0.3))
    shine = U(circle(0.4, 0.6, 0.06), circle(-0.48, 0.6, 0.06))
    return [sticks, shade, tips, shine]


# ---- green bow tie ----
@sticker("lucky", "bowtie", "Bow tie", ["#2FB67A", "#1B8A58", "#FFC531", "#BFF2D4"], ink=1.0)
def _():
    wings = U(poly([(-0.1, 0.0), (-0.84, 0.46), (-0.84, -0.46)]), poly([(0.1, 0.0), (0.84, 0.46), (0.84, -0.46)]))
    shade = _lowr(wings, 0.1)
    clovers = U(_clover_tip(-0.52, 0.0, 0.08), _clover_tip(0.52, 0.0, 0.08))
    knot = box(0.0, 0.0, 0.17, 0.28, 0.08)
    return [wings, shade, clovers, knot]


# ---- happy clover ----
def _pal_build():
    lobes = U(circle(0.0, 0.5, 0.34), circle(-0.4, 0.08, 0.34), circle(0.4, 0.08, 0.34), circle(0.0, 0.12, 0.36))
    return U(lobes, taper(-0.2, -0.2, -0.22, -0.72, 0.13, 0.15), taper(0.2, -0.2, 0.22, -0.72, 0.13, 0.15),
             taper(-0.5, -0.02, -0.86, -0.2, 0.13, 0.1), taper(0.5, -0.02, 0.86, -0.2, 0.13, 0.1))


@sticker("lucky", "pal", "Happy clover", ["#2FB67A", "#1B8A58", "#1A1410", "#FF8FB3"], ink=1.0)
def _():
    leaves = _pal_build()
    shade = _lowr(leaves, 0.1)
    face = U(circle(-0.17, 0.22, 0.11), circle(0.17, 0.22, 0.11), arc(0.0, 0.16, 0.25, math.radians(215), math.radians(325), 0.06))
    cheeks = U(circle(-0.34, 0.04, 0.07), circle(0.34, 0.04, 0.07))
    return [leaves, shade, face, cheeks]


# ---- money bag ----
def _bag_build():
    return U(circle(0.0, -0.3, 0.56), poly([(-0.2, 0.14), (0.2, 0.14), (0.4, -0.14), (-0.4, -0.14)]), oval(0.0, 0.14, 0.3, 0.1))


@sticker("lucky", "bag", "Gold sack", ["#C9A36B", "#9A7440", "#FFC531", "#2FB67A"], ink=1.0)
def _():
    sack = _bag_build()
    shade = _rim(_bag_build, -0.1, 0.1)
    coins = U(circle(-0.16, 0.36, 0.16), circle(0.14, 0.4, 0.17), circle(0.0, 0.54, 0.15))
    trim = U(box(0.0, 0.08, 0.3, 0.08, 0.03), _clover_tip(0.0, -0.3, 0.12))
    return [sack, shade, coins, trim]


# ---- prize rosette ----
@sticker("lucky", "rosette", "Rosette", ["#2FB67A", "#1B8A58", "#FFC531", "#FFFFFF"], ink=1.0)
def _():
    tails = U(poly([(-0.4, -0.2), (-0.1, -0.2), (-0.3, -0.9), (-0.4, -0.7), (-0.6, -0.76)]), poly([(0.4, -0.2), (0.1, -0.2), (0.3, -0.9), (0.4, -0.7), (0.6, -0.76)]))
    fluted = U(*[circle(0.58 * math.cos(math.radians(t)), 0.2 + 0.58 * math.sin(math.radians(t)), 0.17) for t in range(0, 360, 30)], circle(0.0, 0.2, 0.58))
    center = circle(0.0, 0.2, 0.4)
    clover = _clover_tip(0.0, 0.18, 0.1)
    return [tails, fluted, center, clover]
