PACK = ("orchestra", "Orchestra", False)
PRO_IDS = {"timpani", "horn", "gong", "clef", "conductor"}


def _lowright(d, c=0.3):
    """The lower-right slice of shape d (the one shade layer)."""
    return inter(d, c - (X - Y) * 0.7)


@sticker("orchestra", "timpani", "Timpani", ["#D9803A", "#F4EBD8", "#8A5A24", "#C9742E"], ink=1.0)
def _():
    bowl = inter(circle(-0.1, 0.1, 0.66), Y - 0.1)
    head = ellipse(-0.1, 0.1, 0.66, 0.2)
    hardware = U(shell(ellipse(-0.1, 0.1, 0.66, 0.2), 0.04), seg(-0.4, -0.42, -0.6, -0.84, 0.06), seg(0.2, -0.42, 0.4, -0.84, 0.06), seg(-0.1, -0.56, -0.1, -0.84, 0.06),
                 box(-0.78, 0.1, 0.1, 0.06, 0.02), box(0.58, 0.1, 0.1, 0.06, 0.02))
    mallets = U(taper(0.3, 0.7, 0.06, 0.28, 0.065, 0.065), circle(0.32, 0.74, 0.13), taper(0.7, 0.58, 0.34, 0.28, 0.065, 0.065), circle(0.72, 0.62, 0.13))
    return [bowl, head, hardware, mallets]


@sticker("orchestra", "baton", "Baton", ["#FFFFFF", "#C9A878", "#FFC531", "#FF6A8A"], ink=1.0)
def _():
    stick = taper(-0.62, -0.62, 0.36, 0.36, 0.09, 0.035)
    handle = circle(-0.7, -0.7, 0.15)
    arcs = U(arc(0.36, 0.36, 0.3, -1.3, 0.1, 0.075), arc(0.36, 0.36, 0.48, -1.2, 0.0, 0.075))
    tip = circle(0.38, 0.38, 0.08)
    return [stick, handle, arcs, tip]


@sticker("orchestra", "violin", "Violin", ["#B8431E", "#2B1A12", "#5A1E0A", "#FFC9A0"], ink=1.0)
def _():
    with rotated(0.35, 0.0, 0.0):
        body = sub(smin(circle(0, -0.46, 0.44), circle(0, 0.1, 0.33), 0.14), U(circle(-0.54, -0.1, 0.2), circle(0.54, -0.1, 0.2)))
        neck = U(box(0, 0.6, 0.09, 0.3), circle(0, 0.92, 0.12))
        details = U(box(-0.2, -0.24, 0.055, 0.16, 0.02, 0.15), box(0.2, -0.24, 0.055, 0.16, 0.02, -0.15), box(0.0, -0.34, 0.16, 0.04))
        chinrest = ellipse(0.14, -0.78, 0.19, 0.08, 0.3)
    return [body, neck, details, chinrest]


@sticker("orchestra", "cello", "Cello", ["#8A3A22", "#5A2214", "#2B1A12", "#D9B38C"], ink=1.0)
def _():
    body = sub(smin(circle(-0.1, -0.4, 0.44), circle(-0.1, 0.14, 0.3), 0.12), U(circle(-0.6, -0.08, 0.2), circle(0.4, -0.08, 0.2)))
    shade = _lowright(body, 0.2)
    parts = U(box(-0.1, 0.54, 0.07, 0.3), circle(-0.1, 0.84, 0.1), seg(-0.1, -0.8, -0.1, -0.9, 0.05), box(-0.1, -0.3, 0.17, 0.035), box(-0.3, -0.2, 0.05, 0.14, 0.02, 0.15), box(0.1, -0.2, 0.05, 0.14, 0.02, -0.15))
    bow = U(taper(0.86, -0.74, -0.6, 0.46, 0.08, 0.08), circle(0.86, -0.74, 0.1))
    return [body, shade, parts, bow]


@sticker("orchestra", "horn", "French horn", ["#FFC531", "#FFE9A8", "#8A5A1E", "#E09A12"], ink=1.0)
def _():
    tubing = U(ring(-0.14, 0.1, 0.5, 0.13), ring(-0.14, 0.1, 0.24, 0.11), taper(0.2, -0.2, 0.54, -0.54, 0.12, 0.36), seg(-0.5, 0.4, -0.78, 0.66, 0.08))
    rim = ellipse(0.62, -0.62, 0.32, 0.42, 0.8)
    keys = U(*[box(-0.14 + dx, 0.1, 0.06, 0.2, 0.02) for dx in (-0.2, 0.0, 0.2)])
    mouth = circle(-0.82, 0.72, 0.11)
    return [tubing, rim, keys, mouth]


@sticker("orchestra", "piano", "Grand piano", ["#2B2E3A", "#8A93B0", "#FFFFFF", "#8A5A24"], ink=1.0)
def _():
    case = U(box(0.0, -0.06, 0.86, 0.17, 0.05), *[seg(x, -0.2, x, -0.84, 0.06) for x in (-0.7, 0.7)])
    lid = poly([(-0.8, 0.12), (0.76, 0.12), (0.5, 0.74), (-0.5, 0.42)])
    keys = box(-0.66, -0.06, 0.24, 0.07, 0.02)
    bench = U(box(-0.68, -0.56, 0.2, 0.08, 0.03), seg(-0.78, -0.62, -0.78, -0.84, 0.05), seg(-0.58, -0.62, -0.58, -0.84, 0.05))
    return [case, lid, keys, bench]


@sticker("orchestra", "sheet", "Sheet music", ["#F4EBD8", "#2B2E33", "#E3172F", "#C9B896"], ink=1.0)
def _():
    page = sub(box(0, 0, 0.66, 0.86, 0.05), poly([(0.4, 0.9), (0.7, 0.9), (0.7, 0.58)]))
    staff = U(*[box(0, y, 0.5, 0.04) for y in (0.5, 0.26, 0.02, -0.22, -0.46, -0.7)])
    notes = U(circle(-0.28, 0.2, 0.1), seg(-0.18, 0.2, -0.18, 0.62, 0.035), circle(0.14, 0.0, 0.1), seg(0.24, 0.0, 0.24, 0.42, 0.035), seg(-0.18, 0.62, 0.24, 0.42, 0.05),
              circle(-0.14, -0.5, 0.1), seg(-0.04, -0.5, -0.04, -0.08, 0.035))
    fold = poly([(0.4, 0.9), (0.7, 0.58), (0.4, 0.58)])
    return [page, staff, notes, fold]


@sticker("orchestra", "stand", "Music stand", ["#3A3F4E", "#F4EBD8", "#E3172F", "#8A8F98"], ink=1.0)
def _():
    frame = U(box(0.0, 0.3, 0.62, 0.54, 0.05), seg(0.0, -0.2, 0.0, -0.6, 0.09), poly([(0.0, -0.5), (-0.62, -0.9), (0.62, -0.9)]))
    sheet = box(0.0, 0.32, 0.5, 0.44, 0.03)
    notes = U(circle(-0.22, 0.14, 0.1), circle(0.18, 0.26, 0.1), seg(-0.12, 0.14, -0.12, 0.56, 0.04), seg(0.28, 0.26, 0.28, 0.66, 0.04), seg(-0.12, 0.56, 0.28, 0.66, 0.07))
    ledge = box(0.0, -0.18, 0.62, 0.07, 0.02)
    return [frame, sheet, notes, ledge]


@sticker("orchestra", "bowtie", "Concert bow tie", ["#F0E6CC", "#15131A", "#3A3F4E", "#FFC531"], ink=1.0)
def _():
    collar = U(poly([(-0.2, 0.0), (-0.92, -0.14), (-0.62, -0.84), (-0.0, -0.4)]), poly([(0.2, 0.0), (0.92, -0.14), (0.62, -0.84), (0.0, -0.4)]))
    tie = U(poly([(-0.1, 0.0), (-0.84, 0.4), (-0.84, -0.4)]), poly([(0.1, 0.0), (0.84, 0.4), (0.84, -0.4)]), box(0, 0, 0.16, 0.22, 0.06))
    shade = _lowright(tie, 0.15)
    stud = U(circle(0, -0.5, 0.1), circle(0, -0.72, 0.1))
    return [collar, tie, shade, stud]


@sticker("orchestra", "conductor", "Maestro", ["#2B2E3A", "#FFD2A8", "#F0F0F5", "#2B2E33"], ink=1.0)
def _():
    suit = U(poly([(-0.7, -0.9), (-0.5, -0.34), (0.5, -0.34), (0.7, -0.9)]), taper(0.34, -0.5, 0.64, 0.1, 0.12, 0.1))
    face = circle(-0.06, 0.12, 0.34)
    hair = U(poly([(-0.46, 0.2), (-0.7, 0.5), (-0.34, 0.46), (-0.4, 0.82), (-0.08, 0.5), (0.04, 0.88), (0.12, 0.48), (0.4, 0.74), (0.32, 0.36), (0.3, 0.2)]),
             taper(0.64, 0.1, 0.86, 0.56, 0.05, 0.04), poly([(-0.24, -0.34), (-0.06, -0.62), (0.12, -0.34)]))
    details = U(arc(-0.2, 0.14, 0.07, math.pi + 0.3, 2 * math.pi - 0.3, 0.035), arc(0.1, 0.14, 0.07, math.pi + 0.3, 2 * math.pi - 0.3, 0.035), ellipse(-0.05, -0.04, 0.09, 0.05),
                poly([(-0.22, -0.46), (-0.06, -0.38), (0.1, -0.46), (0.1, -0.58), (-0.06, -0.5), (-0.22, -0.58)]))
    return [suit, face, hair, details]


@sticker("orchestra", "triangle", "Triangle", ["#E8B04A", "#A8721E", "#FFFFFF", "#6B4A24"], ink=1.0)
def _():
    tri = sub(shell(regpoly(0.0, -0.1, 3, 0.74), 0.1), box(0.5, 0.3, 0.14, 0.2, 0.0, 0.5))
    shade = _lowright(tri, 0.25)
    loop = U(ring(0.0, 0.74, 0.1, 0.045), seg(0.0, 0.6, 0.0, 0.66, 0.05))
    beater = U(taper(0.78, -0.62, 0.26, 0.18, 0.07, 0.08), circle(0.78, -0.62, 0.1))
    return [tri, shade, loop, beater]


@sticker("orchestra", "gong", "Gong", ["#8A5A24", "#E0A030", "#FFD86B", "#2B2E33"], ink=1.0)
def _():
    frame = U(seg(-0.8, -0.84, -0.8, 0.76, 0.08), seg(0.8, -0.84, 0.8, 0.76, 0.08), seg(-0.82, 0.78, 0.82, 0.78, 0.08), box(-0.8, -0.84, 0.16, 0.06, 0.02), box(0.8, -0.84, 0.16, 0.06, 0.02),
              seg(-0.2, 0.74, -0.2, 0.5, 0.035), seg(0.2, 0.74, 0.2, 0.5, 0.035))
    disc = circle(0.0, -0.06, 0.6)
    boss = U(circle(0.0, -0.06, 0.22), ring(0.0, -0.06, 0.42, 0.05))
    mallet = U(taper(0.88, -0.84, 0.46, -0.44, 0.07, 0.07), circle(0.4, -0.38, 0.15))
    return [frame, disc, boss, mallet]


@sticker("orchestra", "clock", "Pendulum clock", ["#9A5A2E", "#F4EBD8", "#2B2E33", "#FFC531"], ink=1.0)
def _():
    case = U(box(0.0, -0.16, 0.42, 0.7, 0.08), poly([(-0.42, 0.5), (0.0, 0.92), (0.42, 0.5)]))
    face = circle(0.0, 0.42, 0.3)
    glass = U(box(0.0, -0.32, 0.26, 0.34, 0.05), seg(0.0, 0.42, 0.0, 0.62, 0.04), seg(0.0, 0.42, 0.14, 0.36, 0.04))
    pendulum = U(seg(0.0, -0.1, 0.1, -0.4, 0.03), circle(0.1, -0.46, 0.13))
    return [case, face, glass, pendulum]


@sticker("orchestra", "cymbals", "Crash cymbals", ["#FFC531", "#E09A12", "#5A3A1A", "#FFFFFF"], ink=1.0)
def _():
    discs = U(oval(-0.4, 0.2, 0.56, 0.22, 0.45), oval(0.4, 0.2, 0.56, 0.22, -0.45))
    bells = U(circle(-0.4, 0.2, 0.17), circle(0.4, 0.2, 0.17))
    straps = U(seg(-0.4, 0.2, -0.5, -0.56, 0.07), seg(0.4, 0.2, 0.5, -0.56, 0.07), box(-0.5, -0.66, 0.11, 0.15, 0.04), box(0.5, -0.66, 0.11, 0.15, 0.04))
    sparkle = U(star(0.0, 0.7, 4, 0.24, 0.08), star(-0.7, 0.62, 4, 0.16, 0.055))
    return [discs, bells, straps, sparkle]


@sticker("orchestra", "clef", "Treble clef", ["#7A1A2A", "#FFC531", "#E09A12", "#FFE9A8"], ink=1.0)
def _():
    badge = circle(0, 0, 0.86)
    clef = U(seg(0.06, -0.62, 0.06, 0.62, 0.08), ring(-0.02, -0.12, 0.3, 0.08), ring(0.05, -0.12, 0.12, 0.07), arc(0.25, 0.5, 0.2, 0.0, math.pi, 0.075),
             seg(0.45, 0.5, 0.4, 0.2, 0.075), arc(-0.1, -0.62, 0.17, math.pi, 2 * math.pi, 0.075), circle(-0.28, -0.62, 0.09))
    shade = _lowright(clef, 0.25)
    sparks = U(star(0.55, 0.62, 4, 0.14, 0.035), star(-0.58, 0.52, 4, 0.1, 0.03))
    return [badge, clef, shade, sparks]


@sticker("orchestra", "bravo", "BRAVO", ["#8A1030", "#E3172F", "#FFE9A8", "#FFC531"], ink=1.0)
def _():
    tails = U(poly([(-0.52, 0.2), (-0.94, 0.2), (-0.8, -0.06), (-0.94, -0.32), (-0.52, -0.32)]), poly([(0.52, 0.2), (0.94, 0.2), (0.8, -0.06), (0.94, -0.32), (0.52, -0.32)]))
    ribbon = box(0, -0.06, 0.66, 0.4, 0.05)
    word = text("BRAVO", 0, -0.06, 0.4, maxw=1.2)
    stars = U(star(-0.5, 0.36, 5, 0.2, 0.09), star(0.0, 0.5, 5, 0.26, 0.12), star(0.5, 0.36, 5, 0.2, 0.09), box(0, 0.2, 0.62, 0.1))
    return [tails, ribbon, word, stars]


