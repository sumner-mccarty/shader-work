PACK = ("grad", "Grad & Prom", False)
PRO_IDS = {"marquee", "limo", "tiara", "throw", "dancing", "gown"}


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


def _spark(cx, cy, r):
    """A four-point twinkle."""
    return star(cx, cy, 4, r, r * 0.34)


def _cap_parts(cx, cy, s, ang):
    """A mortarboard centred near (cx, cy), scale s, turned ang: (board, base)."""
    with rotated(ang, cx, cy):
        def P(pts):
            return poly([(cx + x * s, cy + y * s) for x, y in pts])
        board = P([(-0.9, 0.05), (0, 0.45), (0.9, 0.05), (0, -0.35)])
        base = P([(-0.5, -0.05), (-0.5, -0.5), (0, -0.72), (0.5, -0.5), (0.5, -0.05), (0, -0.3)])
    return board, base


# ---- grad cap ----
@sticker("grad", "cap", "Grad cap", ["#2A3358", "#151B38", "#FFC531", "#7C8CC9"], ink=1.0)
def _():
    board, base = _cap_parts(0, 0.08, 1.0, 0.0)
    cap = U(board, base)
    shade = sub(base, board)
    tassel = U(circle(0, 0.1, 0.08), polyline([(0, 0.1), (0.55, 0.02), (0.7, -0.25)], 0.045),
               circle(0.7, -0.25, 0.08), taper(0.7, -0.28, 0.7, -0.78, 0.06, 0.13))
    shine = U(seg(-0.62, 0.18, -0.12, 0.43, 0.035), seg(-0.3, 0.46, -0.02, 0.5, 0.0))
    return [cap, shade, tassel, shine]


# ---- diploma ----
@sticker("grad", "diploma", "Diploma", ["#FFF1C9", "#E0BE78", "#E3172F", "#FFFFFF"], ink=1.0)
def _():
    with rotated(0.5, 0, 0):
        paper = U(box(0, 0, 0.74, 0.3, 0.05), oval(-0.76, 0, 0.14, 0.34), oval(0.76, 0, 0.14, 0.34))
        rolls = U(oval(-0.76, 0, 0.14, 0.34), oval(0.76, 0, 0.14, 0.34))
        rolls = sub(rolls, U(oval(-0.8, 0, 0.07, 0.2), oval(0.72, 0, 0.07, 0.2)))
        band = box(0.02, 0, 0.11, 0.36, 0.03)
        bow = U(oval(-0.12, -0.3, 0.2, 0.12, 0.6), oval(0.16, -0.3, 0.2, 0.12, -0.6), circle(0.02, -0.28, 0.09))
        tails = U(poly([(0.0, -0.3), (-0.16, -0.76), (-0.02, -0.68), (0.08, -0.8)]), poly([(0.04, -0.3), (0.28, -0.7), (0.14, -0.72), (0.0, -0.3)]))
        ribbon = U(band, bow, tails)
        shine = seg(-0.5, 0.2, 0.25, 0.2, 0.03)
    return [paper, rolls, ribbon, shine]


# ---- gown ----
def _gown_build():
    torso = poly([(-0.3, 0.72), (0.3, 0.72), (0.6, -0.8), (-0.6, -0.8)])
    sleeves = U(taper(-0.28, 0.6, -0.78, -0.26, 0.16, 0.2), taper(0.28, 0.6, 0.78, -0.26, 0.16, 0.2))
    return U(torso, sleeves)


@sticker("grad", "gown", "Gown", ["#8E1B3A", "#5E1027", "#FFC531", "#FFFFFF"], ink=1.0)
def _():
    gown = _gown_build()
    shade = _lowr(gown, 0.18)
    stole = U(poly([(-0.3, 0.72), (-0.1, 0.72), (-0.08, -0.8), (-0.24, -0.8)]), poly([(0.3, 0.72), (0.1, 0.72), (0.08, -0.8), (0.24, -0.8)]))
    stole = sub(stole, U(poly([(-0.22, 0.74), (0.22, 0.74), (0, 0.36)])))
    collar = poly([(-0.2, 0.74), (0.2, 0.74), (0, 0.36)])
    return [gown, shade, stole, collar]


# ---- class-of banner ----
@sticker("grad", "classof", "Class of", ["#2F5BD0", "#1E3A8A", "#FFFFFF", "#FFC531"], ink=1.0)
def _():
    banner = poly([(-0.92, 0.62), (0.92, 0.62), (0.76, 0.0), (0.92, -0.62), (-0.92, -0.62), (-0.76, 0.0)])
    shade = inter(_lowr(banner, 0.0), -(Y + 0.1))
    words = U(text("CLASS", 0, 0.2, 0.4, maxw=1.3), text("OF", 0, -0.32, 0.28, maxw=0.6))
    trim = U(box(-0.62, -0.34, 0.12, 0.04, 0.01), box(0.62, -0.34, 0.12, 0.04, 0.01), box(0, 0.54, 0.7, 0.03, 0.01))
    return [banner, shade, words, trim]


# ---- yearbook ----
@sticker("grad", "yearbook", "Yearbook", ["#FFF1C9", "#8E1B3A", "#FFC531", "#5E1027"], ink=1.0)
def _():
    pages = box(0.06, -0.04, 0.6, 0.8, 0.07)
    cover = box(-0.04, 0.04, 0.6, 0.8, 0.07)
    cb, cp = _cap_parts(0.0, 0.2, 0.34, 0.0)
    emblem = U(cb, cp, box(0, -0.34, 0.28, 0.07, 0.02), box(0, -0.54, 0.2, 0.06, 0.02))
    spine = box(-0.5, 0.04, 0.1, 0.8, 0.05)
    return [pages, cover, emblem, spine]


# ---- thrown caps ----
@sticker("grad", "throw", "Caps up", ["#2A3358", "#151B38", "#FFC531", "#FF4F9A"], ink=1.0)
def _():
    b1, p1 = _cap_parts(-0.2, 0.4, 0.66, 0.45)
    b2, p2 = _cap_parts(0.2, -0.42, 0.66, -0.3)
    caps = U(b1, p1, b2, p2)
    shade = U(sub(p1, b1), sub(p2, b2))
    sparks = U(_spark(0.66, 0.62, 0.22), _spark(-0.7, -0.4, 0.2), _spark(-0.78, 0.8, 0.1))
    confetti = circle(-0.7, 0.72, 0.09)
    return [caps, shade, sparks, confetti]


# ---- honor medal ----
@sticker("grad", "medal", "Honor medal", ["#FFC531", "#E09A12", "#2F5BD0", "#FFF6B0"], ink=1.0)
def _():
    tails = U(poly([(-0.34, 0.0), (-0.56, -0.9), (-0.32, -0.74), (-0.12, -0.9), (-0.02, 0.0)]),
              poly([(0.34, 0.0), (0.56, -0.9), (0.32, -0.74), (0.12, -0.9), (0.02, 0.0)]))
    rosette = U(star(0, 0.24, 14, 0.66, 0.54), circle(0, 0.24, 0.55))
    ribbon = sub(tails, rosette)
    shade = U(inter(rosette, 0.5 - (X - Y) * 0.7071 * 1.0 - 0.3), circle(0, 0.24, 0.38))
    shade = sub(shade, circle(-0.05, 0.29, 0.3))
    star_ = star(0, 0.24, 5, 0.3, 0.13)
    return [rosette, shade, ribbon, star_]


# ---- prom tiara ----
@sticker("grad", "tiara", "Tiara", ["#9DB0EC", "#5566A8", "#FF4FA0", "#FFFFFF"], ink=1.0)
def _():
    xs = [-0.66, -0.33, 0.0, 0.33, 0.66]
    hs = [0.15, 0.45, 0.78, 0.45, 0.15]
    band = box(0, -0.5, 0.84, 0.2, 0.08)
    spikes = U(*[taper(x, -0.45, x, -0.5 + 0.2 + h, 0.19, 0.1) for x, h in zip(xs, hs)])
    tiara = smin(band, spikes, 0.1)
    shade = _lowr(band, 0.0)
    gems = U(*[circle(x, -0.3 + h + 0.12, 0.11) for x, h in zip(xs, hs)], regpoly(0, -0.5, 4, 0.19), circle(-0.46, -0.5, 0.08), circle(0.46, -0.5, 0.08))
    shine = seg(-0.72, -0.4, -0.2, -0.4, 0.04)
    return [tiara, shade, gems, shine]


# ---- corsage ----
@sticker("grad", "corsage", "Corsage", ["#FF7AB6", "#D93A86", "#F4F1EA", "#2E9E4F"], ink=1.0)
def _():
    bloom = U(petals(0, 0.2, 6, 0.27, 0.24, 0.19), circle(0, 0.2, 0.22))
    shade = U(inter(bloom, 0.1 - (X - Y) * 0.7071 * 0.9), circle(0, 0.2, 0.12))
    shade = sub(shade, circle(-0.04, 0.24, 0.05))
    band = U(arc(0, 0.5, 0.95, math.radians(222), math.radians(318), 0.11), poly([(0, -0.38), (-0.3, -0.72), (-0.12, -0.8), (0, -0.56)]),
             poly([(0, -0.38), (0.3, -0.72), (0.12, -0.8), (0, -0.56)]))
    leaves = U(oval(-0.52, -0.02, 0.26, 0.1, 0.6), oval(0.52, -0.02, 0.26, 0.1, -0.6))
    return [bloom, shade, band, leaves]


# ---- boutonniere ----
@sticker("grad", "boutonniere", "Boutonniere", ["#F2465A", "#B21C32", "#2E9E4F", "#FFC531"], ink=1.0)
def _():
    bloom = U(petals(-0.04, 0.34, 9, 0.24, 0.17, 0.15), circle(-0.04, 0.34, 0.26))
    shade = U(inter(bloom, 0.12 - (X - Y) * 0.7071), circle(-0.04, 0.34, 0.1))
    shade = sub(shade, circle(-0.08, 0.38, 0.04))
    greens = U(brush([(-0.04, 0.1), (0.0, -0.3), (0.05, -0.7)], [0.09, 0.09, 0.08]), oval(-0.38, -0.2, 0.32, 0.1, 0.7), oval(0.4, -0.12, 0.32, 0.1, -0.7))
    pin = U(seg(-0.35, -0.5, 0.45, -0.34, 0.09), circle(0.5, -0.33, 0.13), box(0.02, -0.42, 0.07, 0.1, 0.02, 0.2))
    return [bloom, shade, greens, pin]


# ---- limo ----
def _limo_build():
    return U(box(0, -0.1, 0.9, 0.22, 0.1), box(-0.08, 0.12, 0.66, 0.15, 0.08))


@sticker("grad", "limo", "Limo", ["#2E2E3A", "#16161F", "#9FE8FF", "#16161F"], ink=1.0)
def _():
    body = _limo_build()
    shade = inter(body, -(Y + 0.18))
    glass = U(*[box(x, 0.13, 0.12, 0.07, 0.03) for x in (-0.54, -0.28, -0.02, 0.24)], box(0.82, -0.08, 0.05, 0.04, 0.02))
    wheels = U(sub(circle(-0.56, -0.34, 0.2), circle(-0.56, -0.34, 0.08)), sub(circle(0.56, -0.34, 0.2), circle(0.56, -0.34, 0.08)))
    return [body, shade, glass, wheels]


# ---- dance shoe ----
@sticker("grad", "shoe", "Dance shoe", ["#FF4F9A", "#C42670", "#FFFFFF", "#FFD34D"], ink=1.0)
def _():
    pts = [(-0.9, -0.75), (-0.92, -0.62), (-0.7, -0.52), (-0.4, -0.42), (-0.15, -0.1), (0.1, 0.3), (0.42, 0.34), (0.5, 0.05), (0.44, -0.25), (0.15, -0.5), (-0.25, -0.68)]
    shoe = U(poly(spline(pts, n=8)), poly([(0.4, -0.2), (0.68, -0.18), (0.64, -0.8), (0.48, -0.8)]))
    shade = U(inter(shoe, -(Y + 0.5)), _lowr(poly([(0.4, -0.2), (0.68, -0.18), (0.64, -0.8), (0.48, -0.8)]), 5))
    strap = U(seg(0.05, 0.18, 0.45, 0.14, 0.08))
    glitter = U(_spark(-0.35, -0.22, 0.14), _spark(0.0, 0.5, 0.1), _spark(0.7, 0.55, 0.12))
    return [shoe, shade, strap, glitter]


# ---- photo strip ----
@sticker("grad", "photostrip", "Photo strip", ["#FFFFFF", "#C9CCE0", "#2B2D5B", "#FFD34D"], ink=1.0)
def _():
    with rotated(0.2, 0, 0):
        strip = box(0, 0, 0.36, 0.9, 0.05)
        shade = sub(strip, box(-0.04, 0.04, 0.36, 0.9, 0.05))
        frames = U(box(0, 0.56, 0.26, 0.24, 0.03), box(0, 0.0, 0.26, 0.24, 0.03), box(0, -0.56, 0.26, 0.24, 0.03))
        faces = U(heart(0, 0.56, 0.26), star(0, 0.0, 5, 0.22, 0.09), sub(circle(0, -0.56, 0.2), U(circle(-0.07, -0.52, 0.04), circle(0.07, -0.52, 0.04))))
    return [strip, shade, frames, faces]


# ---- PROM marquee ----
@sticker("grad", "marquee", "Prom sign", ["#C2185B", "#7B0F3C", "#FFE14A", "#FFFFFF"], ink=1.0)
def _():
    sign = box(0, 0, 0.92, 0.55, 0.1)
    shade = sub(sign, box(-0.06, 0.06, 0.92, 0.55, 0.1))
    bulbs = U(*[circle(x, y, 0.065) for x in (-0.78, 0.0, 0.78) for y in (-0.42, 0.42)], circle(-0.78, 0.0, 0.065), circle(0.78, 0.0, 0.065))
    words = text("PROM", 0, 0.0, 0.52, maxw=1.45)
    return [sign, shade, bulbs, words]


# ---- slow-dance hearts ----
def _hearts_build():
    return heart(-0.2, 0.08, 0.95)


@sticker("grad", "dancing", "Slow dance", ["#E3172F", "#9E0F22", "#FF8FB8", "#FFFFFF"], ink=1.0)
def _():
    love = _hearts_build()
    shade = _rim(_hearts_build, -0.12, 0.12)
    with rotated(-0.35, 0.3, -0.2):
        partner = heart(0.3, -0.2, 0.6)
    note = U(circle(-0.4, 0.05, 0.1), seg(-0.31, 0.07, -0.31, 0.42, 0.045), polyline([(-0.31, 0.42), (-0.14, 0.32)], 0.05))
    return [love, shade, partner, note]


# ---- GRAD balloon ----
def _balloon_build():
    return oval(0, 0.2, 0.7, 0.72)


@sticker("grad", "balloon", "Balloon", ["#FFC531", "#B07A0A", "#FFFFFF", "#23284D"], ink=1.0)
def _():
    balloon = _balloon_build()
    shade = U(_rim(_balloon_build, -0.12, 0.12), poly([(0, -0.46), (-0.1, -0.58), (0.1, -0.58)]), brush([(0, -0.56), (-0.16, -0.7), (0.12, -0.82), (0, -0.94)], [0.06, 0.055, 0.055, 0.055]))
    shine = U(seg(-0.36, 0.55, -0.2, 0.75, 0.05))
    words = text("GRAD", 0, 0.2, 0.44, maxw=1.2)
    return [balloon, shade, shine, words]


# ---- A+ ----
def _paper_build():
    return box(0, 0, 0.62, 0.82, 0.06)


@sticker("grad", "aplus", "A plus", ["#FFFFFF", "#C9CCE0", "#E3172F", "#4A7BE8"], ink=1.0)
def _():
    with rotated(-0.15, 0, 0):
        paper = _paper_build()
        shade = _rim(_paper_build, -0.08, 0.08)
        grade = text("A+", 0.042, 0.277, 0.5, ang=-0.15, maxw=0.9)
        lines = U(box(0, -0.2, 0.42, 0.04, 0.01), box(0, -0.4, 0.42, 0.04, 0.01), box(-0.1, -0.6, 0.32, 0.04, 0.01))
    return [paper, shade, grade, lines]
