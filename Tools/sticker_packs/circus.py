# Circus — the big top: stripes, stars, a flaming hoop and a very good drum. Run by Tools/decor_stickers.py (every helper
# is in scope).
PACK = ("circus", "Circus", False)
PRO_IDS = {"drum", "tent", "hoop", "balloondog", "elephant", "tada"}

RED, DKRED, WHITE, GOLD, BLUE, NAVY = "#E8212E", "#A5121C", "#FFFFFF", "#FFC928", "#1E4FD8", "#14246B"
TEAL, PURP, SLATE, KRAFT, CARA = "#12B5A6", "#7A3FD0", "#7C8AA5", "#C8803C", "#9A5420"


def _moved(d, dx, dy):
    """Layer d slid by (dx, dy) slice units (y up); what slides in from the edge is far outside."""
    px, py = int(round(dx * N / 2)), int(round(dy * N / 2))
    out = np.full_like(d, BIG)
    h, w = d.shape
    rs, rd = (slice(py, h), slice(0, h - py)) if py >= 0 else (slice(0, h + py), slice(-py, h))
    cs, cd = (slice(0, w - px), slice(px, w)) if px >= 0 else (slice(-px, w), slice(0, w + px))
    out[rd, cd] = d[rs, cs]
    return out


def _rim(d, k=0.09):
    """The lower-right rim of d: d minus itself slid up-left — the house shade."""
    return sub(d, _moved(d, -k, k))


def _glint(d, cx, cy, rx=0.1, ry=0.05, ang=0.8):
    """A short upper-left highlight stroke, kept inside d."""
    return inter(oval(cx, cy, rx, ry, ang), d + 0.035)


def _star_dots(pts, r=0.07):
    return U(*[star(x, y, 4, r * 1.5, r * 0.45) for x, y in pts])


def _pin(cx, cy, ang, s=0.9):
    """A juggling club, fat end up: (body, band, glint)."""
    with rotated(ang, cx, cy):
        body = U(oval(cx, cy + 0.14 * s, 0.21 * s, 0.29 * s), seg(cx, cy - 0.2 * s, cx, cy + 0.0, 0.05 * s), circle(cx, cy - 0.3 * s, 0.085 * s))
        band = inter(body, box(cx, cy + 0.12 * s, 0.4 * s, 0.055 * s))
        glint = _glint(body, cx - 0.09 * s, cy + 0.26 * s, 0.1 * s, 0.025 * s, math.pi / 2 + 0.2)
    return body, band, glint


@sticker("circus", "tent", "Big top", [WHITE, RED, NAVY, GOLD], ink=1.0)
def _():
    apex = (0.0, 0.6)
    roof = poly([(-0.84, -0.02), apex, (0.84, -0.02)])
    wall = box(0, -0.4, 0.74, 0.34, 0.05)
    canvas = U(roof, wall)
    wedges = [poly([apex, (-0.84 + 0.28 * k, -0.02), (-0.84 + 0.28 * (k + 1), -0.02)]) for k in (1, 3, 5)]
    cols = [box(-0.74 + 0.247 * k + 0.123, -0.4, 0.123, 0.4) for k in (1, 3, 5)]
    stripes_ = inter(canvas, U(*wedges, *cols))
    door = poly([(-0.2, -0.74), (-0.2, -0.45), (0.0, -0.27), (0.2, -0.45), (0.2, -0.74)])
    shade = U(_rim(canvas, 0.1), door)
    flag = U(seg(0, 0.58, 0, 0.82, 0.035), poly([(0.0, 0.84), (0.24, 0.77), (0.0, 0.7)]), _glint(roof, -0.3, 0.2, 0.12, 0.04, 0.75))
    return [canvas, stripes_, shade, flag]


@sticker("circus", "pins", "Juggling pins", [RED, WHITE, DKRED, GOLD], ink=1.0)
def _():
    a, b, c = _pin(-0.5, -0.1, 0.6, 1.25), _pin(0.0, 0.4, math.pi - 0.4, 1.25), _pin(0.5, -0.2, -0.6, 1.25)
    body = U(a[0], b[0], c[0])
    band = U(a[1], b[1], c[1])
    shade = _rim(body, 0.09)
    sparks = U(a[2], b[2], c[2], _star_dots([(-0.74, 0.7), (0.76, 0.6), (0.0, -0.76)], 0.13))
    return [body, band, shade, sparks]


@sticker("circus", "unicycle", "Unicycle", [TEAL, RED, NAVY, GOLD], ink=1.0)
def _():
    cx, cy = 0.0, -0.4
    wheel = U(ring(cx, cy, 0.44, 0.09), seg(cx - 0.42, cy, cx + 0.42, cy, 0.05), seg(cx, cy - 0.42, cx, cy + 0.42, 0.05))
    frame = U(seg(cx, cy, 0, 0.56, 0.085), seg(cx, cy, 0.26, cy - 0.2, 0.06), box(0.34, cy - 0.22, 0.13, 0.06, 0.03), circle(cx, cy, 0.12))
    seat = oval(0.0, 0.64, 0.32, 0.12)
    shade = _rim(U(wheel, frame, seat), 0.1)
    sparks = U(seat, _glint(wheel, -0.32, -0.1, 0.09, 0.03, 1.0), _star_dots([(0.66, 0.3), (-0.66, 0.5)], 0.12))
    frame_seat = U(frame, seat)
    return [wheel, frame_seat, shade, sparks]


@sticker("circus", "trapeze", "Trapeze", [RED, GOLD, DKRED, WHITE], ink=1.0)
def _():
    with rotated(0.0, 0.0, 0.0):
        ropes = U(seg(-0.3, 0.88, -0.58, -0.3, 0.09), seg(0.3, 0.88, 0.58, -0.3, 0.09))
        bar = box(0, -0.42, 0.68, 0.13, 0.11)
        knobs = U(circle(-0.66, -0.42, 0.16), circle(0.66, -0.42, 0.16))
        shade = _rim(U(ropes, bar), 0.1)
        shine = U(_glint(ropes, -0.36, 0.3, 0.03, 0.2, -0.35), _glint(bar, -0.36, -0.38, 0.22, 0.035, 0.0))
    swing = U(bar, knobs)
    sparks = U(shine, _star_dots([(-0.7, 0.6), (0.72, 0.78)], 0.13))
    return [ropes, swing, shade, sparks]


@sticker("circus", "hoop", "Flaming hoop", ["#FF5A1F", BLUE, "#B3300F", GOLD], ink=1.0)
def _():
    cx, cy, r = 0.0, -0.06, 0.58
    flames, inner = [], []
    for k in range(7):
        a = math.pi * (0.04 + 0.92 * k / 6)
        big = 0.3 if k % 2 == 0 else 0.2
        with rotated(a - math.pi / 2, cx, cy):
            base = cy + r
            flames.append(poly(spline([(cx - 0.16, base - 0.05), (cx - 0.13, base + big * 0.5), (cx + 0.16, base + big + 0.08), (cx + 0.1, base + big * 0.4),
                                        (cx + 0.16, base - 0.05)], closed=True, n=6)))
            inner.append(poly(spline([(cx - 0.08, base + 0.02), (cx - 0.06, base + big * 0.35), (cx + 0.07, base + big * 0.68), (cx + 0.06, base + big * 0.3),
                                       (cx + 0.09, base + 0.02)], closed=True, n=6)))
    fire = U(*flames)
    hoop = U(ring(cx, cy, r, 0.085), box(0, -0.78, 0.05, 0.1), box(0, -0.86, 0.38, 0.05, 0.04))
    shade = _rim(U(fire, hoop), 0.1)
    shine = U(*inner)
    return [fire, hoop, shade, shine]


@sticker("circus", "tightrope", "Tightrope", [WHITE, RED, NAVY, GOLD], ink=1.0)
def _():
    rope = U(seg(-0.84, -0.6, 0.84, -0.3, 0.05), circle(-0.84, -0.6, 0.11), circle(0.84, -0.3, 0.11))
    walker = U(circle(0.0, 0.42, 0.2), taper(0.0, 0.3, 0.0, -0.1, 0.17, 0.12), seg(0.0, -0.1, -0.16, -0.43, 0.1), seg(0.0, -0.1, 0.16, -0.43, 0.1),
               seg(0.0, 0.22, -0.28, 0.1, 0.085), seg(0.0, 0.22, 0.28, 0.1, 0.085))
    pole = U(seg(-0.84, 0.1, 0.84, 0.1, 0.075), circle(-0.8, 0.1, 0.16), circle(0.8, 0.1, 0.16), _glint(walker, -0.07, 0.5, 0.04, 0.04, 0.0))
    shade = _rim(U(rope, walker), 0.1)
    return [rope, walker, shade, pole]


@sticker("circus", "elephant", "Elephant", ["#9AA7D6", PURP, NAVY, GOLD], ink=1.0)
def _():
    torso = oval(0.12, 0.0, 0.52, 0.38)
    head = circle(-0.5, 0.2, 0.3)
    ear = oval(-0.32, 0.14, 0.17, 0.26, 0.2)
    trunk = brush([(-0.7, 0.12), (-0.84, -0.15), (-0.8, -0.4), (-0.62, -0.46)], [0.13, 0.11, 0.1, 0.09])
    legs = U(box(-0.28, -0.48, 0.12, 0.26, 0.05), box(-0.02, -0.48, 0.12, 0.26, 0.05), box(0.38, -0.48, 0.12, 0.26, 0.05), box(0.62, -0.48, 0.12, 0.26, 0.05))
    tail = seg(0.62, 0.15, 0.76, -0.12, 0.05)
    body = U(torso, head, trunk, legs, tail)
    blanket = U(box(0.18, 0.32, 0.36, 0.14, 0.05), *[circle(-0.0 + 0.18 * k, 0.2, 0.09) for k in range(5)])
    eye = circle(-0.52, 0.28, 0.05)
    shade = U(_rim(body, 0.1), eye)
    trim = U(*[regpoly(0.0 + 0.18 * k, 0.3, 4, 0.075) for k in range(5)], seg(-0.14, 0.43, 0.5, 0.43, 0.03), _glint(head, -0.62, 0.38, 0.1, 0.05, 0.9), _glint(torso, -0.12, -0.12, 0.1, 0.04, 0.4))
    return [body, blanket, shade, trim]


@sticker("circus", "stilts", "Stilts", [PURP, BLUE, NAVY, GOLD], ink=1.0)
def _():
    pants = U(seg(-0.32, 0.0, -0.32, 0.58, 0.19), seg(0.32, 0.0, 0.32, 0.58, 0.19))
    stilts = U(seg(-0.32, -0.88, -0.32, 0.05, 0.055), seg(0.32, -0.88, 0.32, 0.05, 0.055), box(-0.32, -0.5, 0.17, 0.055, 0.03), box(0.32, -0.5, 0.17, 0.055, 0.03),
               oval(-0.36, -0.38, 0.22, 0.09), oval(0.36, -0.38, 0.22, 0.09), box(0, 0.8, 0.58, 0.11, 0.05))
    shade = _rim(U(pants, stilts), 0.1)
    shine = U(inter(pants, stripes(0.26, math.pi / 2, 0.45, 0.04)), _glint(pants, -0.42, 0.28, 0.2, 0.05, math.pi / 2), _glint(stilts, -0.52, 0.8, 0.1, 0.035, 0.0))
    return [pants, stilts, shade, shine]


@sticker("circus", "balloondog", "Balloon dog", [RED, BLUE, DKRED, WHITE], ink=1.0)
def _():
    parts = [oval(0.05, 0.02, 0.5, 0.26, 0.0), oval(-0.48, 0.34, 0.15, 0.3, 0.7), oval(-0.66, 0.52, 0.22, 0.16, 0.2), oval(-0.88, 0.4, 0.1, 0.1),
             oval(-0.5, 0.78, 0.08, 0.15, 0.4), oval(-0.78, 0.76, 0.08, 0.15, -0.3),
             oval(-0.3, -0.45, 0.13, 0.34), oval(-0.04, -0.45, 0.13, 0.34), oval(0.3, -0.45, 0.13, 0.34), oval(0.56, -0.45, 0.13, 0.34),
             oval(0.66, 0.4, 0.11, 0.34, -0.45)]
    balloon = U(*parts)
    tie = U(circle(0.74, 0.72, 0.08), seg(0.74, 0.72, 0.84, 0.84, 0.05), seg(0.74, 0.72, 0.84, 0.6, 0.05))
    shade = U(*[_rim(p, 0.1) for p in parts])
    shine = U(*[_glint(p, x, y, 0.08, 0.03, 0.4) for p, x, y in [(parts[0], -0.2, 0.15), (parts[2], -0.7, 0.58), (parts[6], -0.36, -0.3), (parts[8], 0.24, -0.3)]])
    return [balloon, tie, shade, shine]


@sticker("circus", "booth", "Ticket booth", ["#FFE9C7", RED, NAVY, GOLD], ink=1.0)
def _():
    house = box(0, -0.2, 0.62, 0.58, 0.04)
    awning = U(box(0, 0.4, 0.78, 0.16, 0.04), *[circle(-0.65 + 0.26 * k, 0.27, 0.13) for k in range(6)])
    roof = poly([(-0.7, 0.52), (0, 0.84), (0.7, 0.52)])
    window = box(0, -0.12, 0.38, 0.26, 0.04)
    shade = U(_rim(U(house, awning), 0.1), window, box(0, -0.45, 0.46, 0.04))
    shine = U(box(0, -0.12, 0.26, 0.015), _glint(roof, -0.3, 0.6, 0.14, 0.045, 0.35), star(0, -0.66, 5, 0.13, 0.06), *[box(-0.65 + 0.26 * k + 0.13, 0.42, 0.065, 0.14) for k in (1, 3, 5)])
    awning_roof = U(awning, roof)
    return [house, awning_roof, shade, shine]


@sticker("circus", "peanuts", "Peanut bag", [BLUE, "#E0A94A", GOLD, NAVY], ink=1.0)
def _():
    bag = poly([(-0.58, 0.02), (0.58, 0.02), (0.72, -0.88), (-0.72, -0.88)])
    nuts = U(*[U(circle(x - 0.13, y, 0.16), circle(x + 0.13, y + 0.02, 0.16)) for x, y in [(-0.4, 0.22), (0.05, 0.36), (0.45, 0.2)]])
    flap = box(0, -0.02, 0.62, 0.07, 0.03)
    label = U(box(0, -0.45, 0.5, 0.22, 0.05), _glint(bag, -0.6, -0.72, 0.2, 0.05, math.pi / 2 - 0.1))
    shade = U(_rim(U(bag, nuts), 0.1), flap, star(0, -0.45, 5, 0.15, 0.065))
    return [bag, nuts, label, shade]


@sticker("circus", "apple", "Caramel apple", [RED, CARA, DKRED, WHITE], ink=1.0)
def _():
    fruit = smin(circle(-0.22, -0.2, 0.48), circle(0.22, -0.2, 0.48), 0.2)
    stick = seg(0.0, 0.05, 0.1, 0.9, 0.055)
    coat = inter(U(inter(fruit, -(Y + 0.12)), seg(-0.52, 0.0, -0.52, -0.3, 0.1), seg(-0.1, 0.0, -0.1, -0.42, 0.09), seg(0.36, 0.0, 0.36, -0.34, 0.1)), fruit)
    shade = _rim(fruit, 0.09)
    shine = U(_star_dots([(-0.3, 0.2), (0.2, 0.18), (0.5, 0.1)], 0.07), _glint(fruit, -0.52, -0.4, 0.14, 0.04, 1.2))
    caramel = U(stick, coat)
    return [fruit, caramel, shade, shine]


@sticker("circus", "seal", "Seal", ["#8D8A96", RED, NAVY, WHITE], ink=1.0)
def _():
    stool = U(box(0.0, -0.8, 0.5, 0.09, 0.04), box(0.0, -0.66, 0.38, 0.07, 0.03))
    torso = oval(0.08, -0.38, 0.55, 0.22, 0.0)
    neck = brush([(-0.3, -0.34), (-0.42, -0.1), (-0.44, 0.12)], [0.2, 0.18, 0.17])
    head = U(circle(-0.44, 0.24, 0.22), oval(-0.56, 0.42, 0.2, 0.11, 0.9))
    tail = U(taper(0.45, -0.34, 0.74, -0.08, 0.14, 0.08), oval(0.7, 0.0, 0.18, 0.07, 0.9), oval(0.78, -0.14, 0.18, 0.07, 0.2))
    flipper = oval(-0.12, -0.5, 0.24, 0.08, -0.5)
    body = U(torso, neck, head, tail, flipper, stool)
    ball = circle(-0.62, 0.7, 0.22)
    face = U(circle(-0.5, 0.33, 0.055), circle(-0.62, 0.5, 0.08))
    shade = U(_rim(body, 0.1), face)
    shine = U(inter(ball, stripes(0.22, 0.6, 0.45)), _glint(head, -0.5, 0.38, 0.08, 0.04, 1.0), circle(-0.5, 0.45, 0.03), circle(-0.44, 0.5, 0.03), _glint(torso, -0.1, -0.28, 0.2, 0.04, 0.0))
    return [body, ball, shade, shine]


@sticker("circus", "drum", "Circus drum", [BLUE, RED, GOLD, NAVY], ink=1.0)
def _():
    top = oval(0.0, 0.36, 0.84, 0.3)
    bottom = oval(0.0, -0.56, 0.84, 0.3)
    shell = U(box(0.0, -0.1, 0.84, 0.46), bottom, top)
    head = oval(0.0, 0.36, 0.7, 0.17)
    hoops = U(sub(top, head), sub(bottom, _moved(bottom, 0.0, 0.14)))
    stars_ = U(head, *[star(x, -0.14, 5, r, r * 0.45) for x, r in [(-0.48, 0.16), (0.0, 0.27), (0.48, 0.16)]])
    sticks = U(seg(-0.55, 0.62, 0.15, 0.3, 0.04), seg(0.55, 0.62, -0.15, 0.3, 0.04))
    shade = U(sub(_rim(shell, 0.1), top), sticks)
    stars = U(stars_, _glint(shell, -0.74, -0.15, 0.22, 0.05, math.pi / 2))
    return [shell, hoops, stars, shade]


@sticker("circus", "marquee", "Marquee", [RED, WHITE, NAVY, GOLD], ink=1.0)
def _():
    board = U(box(0, 0.2, 0.9, 0.4, 0.06), seg(-0.6, -0.2, -0.6, -0.86, 0.09), seg(0.6, -0.2, 0.6, -0.86, 0.09))
    letters = text("CIRCUS", 0.0, 0.2, 0.66, maxw=1.3)
    bulbs = U(*[circle(-0.76 + 0.19 * k, 0.52, 0.07) for k in range(9)], _glint(board, -0.72, 0.42, 0.1, 0.04, 0.0))
    shade = _rim(board, 0.1)
    return [board, letters, shade, bulbs]


@sticker("circus", "tada", "Ta-da!", [GOLD, RED, "#D99A00", WHITE], ink=1.0)
def _():
    burst = star(0.0, 0.0, 12, 0.84, 0.66)
    words = U(text("TA", 0.0, 0.22, 0.4, maxw=1.0), text("DA!", 0.0, -0.26, 0.4, maxw=1.0))
    shade = _rim(burst, 0.1)
    shine = U(_star_dots([(-0.5, 0.5), (0.5, -0.5), (0.52, 0.5), (-0.5, -0.5)], 0.09), _glint(burst, -0.55, 0.15, 0.1, 0.03, 1.0))
    return [burst, words, shade, shine]