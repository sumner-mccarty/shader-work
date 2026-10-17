PACK = ("toybox", "Toy Box", False)
PRO_IDS = {"robot", "jackbox", "horse", "cube", "rocket", "dog"}

RED, REDD = "#E3172F", "#8E0F1E"
BLUE, BLUED = "#2F6BFF", "#1A3C9E"
YEL, YELD = "#FFC531", "#D08A0C"
TIN, TIND = "#C9CED6", "#7A808A"
WOOD, WOODD = "#E0A15A", "#9A6234"
WHITE = "#FFFFFF"
INK = "#1A1410"


def _shift(make, dx, dy):
    """The shape `make()` draws, slid by (dx, dy)."""
    with rotated(0.0, 0.0, 0.0, dx, dy):
        return make()


def _rim(make, k=0.11):
    """Lower-right shade: the shape minus a copy of itself nudged up-left."""
    return sub(make(), _shift(make, -k, k))


# ---- wind-up robot ----
def _robot():
    return U(box(0.0, 0.42, 0.34, 0.26, 0.08), box(0.0, -0.18, 0.42, 0.34, 0.08),
             box(-0.56, -0.12, 0.1, 0.26, 0.06), box(0.56, -0.12, 0.1, 0.26, 0.06),
             box(-0.22, -0.68, 0.13, 0.18, 0.04), box(0.22, -0.68, 0.13, 0.18, 0.04))


@sticker("toybox", "robot", "Wind-up robot", [TIN, TIND, RED, WHITE], ink=1.0)
def _():
    robot = U(_robot(), seg(0.0, 0.66, 0.0, 0.76, 0.04))
    shade = _rim(_robot, 0.1)
    trim = U(circle(0.0, 0.78, 0.08), box(-0.15, 0.44, 0.09, 0.09, 0.03), box(0.15, 0.44, 0.09, 0.09, 0.03), box(0.0, 0.26, 0.16, 0.035),
             circle(0.0, -0.12, 0.17), *[circle(x, -0.4, 0.05) for x in (-0.16, 0.0, 0.16)],
             seg(0.52, -0.2, 0.78, -0.2, 0.04), box(0.84, -0.2, 0.05, 0.13, 0.04))
    shine = U(seg(-0.24, 0.6, -0.04, 0.6, 0.035), seg(-0.32, 0.04, -0.32, -0.24, 0.035), circle(-0.04, -0.06, 0.05))
    return [robot, shade, trim, shine]


# ---- yo-yo (turned, so the gap between the halves shows) ----
def _front():
    return circle(-0.08, -0.2, 0.58)


@sticker("toybox", "yoyo", "Yo-yo", [RED, REDD, YEL, WHITE], ink=1.0)
def _():
    back = circle(0.12, -0.08, 0.58)
    yoyo = U(_front(), back)
    shade = U(sub(back, _front() - 0.06), inter(_front(), sub(_front(), circle(-0.18, -0.1, 0.58))))
    hub = circle(-0.08, -0.2, 0.2)
    shine = U(brush([(-0.08, -0.2), (0.06, 0.2), (0.0, 0.5), (0.12, 0.66)], [0.045, 0.045, 0.045, 0.045]), ring(0.18, 0.76, 0.12, 0.05),
              arc(-0.08, -0.2, 0.46, math.radians(115), math.radians(160), 0.05))
    return [yoyo, shade, hub, shine]


# ---- spinning top ----
def _top():
    return U(oval(0.0, 0.06, 0.74, 0.3), poly([(-0.52, -0.04), (0.52, -0.04), (0.0, -0.74)]) - 0.05,
             box(0.0, 0.44, 0.08, 0.16, 0.04), circle(0.0, 0.6, 0.1))


@sticker("toybox", "top", "Spinning top", ["#FF7A1A", "#B84A0A", YEL, WHITE], ink=1.0)
def _():
    top = _top()
    shade = _rim(_top, 0.1)
    bands = inter(oval(0.0, 0.06, 0.74, 0.3), U(box(0.0, 0.06, 0.8, 0.08), box(0.0, 0.26, 0.8, 0.045), box(0.0, -0.14, 0.8, 0.045)))
    shine = U(oval(-0.36, 0.2, 0.16, 0.045, 0.15), arc(0.0, -0.58, 0.3, math.radians(200), math.radians(240), 0.04),
              arc(0.0, -0.58, 0.3, math.radians(300), math.radians(340), 0.04))
    return [top, shade, bands, shine]


# ---- jack-in-the-box ----
def _jbox():
    return box(0.0, -0.54, 0.46, 0.3, 0.06)


@sticker("toybox", "jackbox", "Jack-in-the-box", [BLUE, BLUED, YEL, WHITE], ink=1.0)
def _():
    lid = box(-0.6, -0.08, 0.06, 0.3, 0.03, -0.25)
    crank = U(seg(0.46, -0.5, 0.68, -0.5, 0.05), box(0.72, -0.38, 0.07, 0.16, 0.05))
    box_ = U(_jbox(), lid, crank)
    hat = U(poly([(-0.2, 0.6), (-0.54, 0.8), (0.0, 0.7)]) - 0.04, poly([(0.2, 0.6), (0.54, 0.8), (0.0, 0.7)]) - 0.04)
    shade = U(_rim(_jbox, 0.1), hat, circle(-0.12, 0.36, 0.055), circle(0.12, 0.36, 0.055),
              arc(0.0, 0.3, 0.17, math.radians(200), math.radians(340), 0.05))
    jack = U(polyline([(0.0, -0.26), (-0.22, -0.18), (0.22, -0.08), (-0.22, 0.02), (0.0, 0.08)], 0.07),
             circle(0.0, 0.32, 0.3), circle(-0.58, 0.8, 0.08), circle(0.58, 0.8, 0.08))
    shine = U(star(0.0, -0.54, 5, 0.2, 0.085), seg(-0.34, -0.32, -0.34, -0.66, 0.035), circle(-0.14, 0.48, 0.045))
    return [box_, jack, shade, shine]


# ---- rocking horse ----
def _horse():
    return U(oval(-0.02, 0.0, 0.46, 0.22),                                               # the barrel
             poly([(0.22, 0.06), (0.42, 0.56), (0.56, 0.6), (0.4, 0.0)]) - 0.06,             # the neck
             oval(0.6, 0.5, 0.24, 0.13, -0.5),                                            # the head
             poly([(0.4, 0.62), (0.44, 0.78), (0.52, 0.64)]) - 0.02,                        # the ear
             *[taper(x, -0.08, x + dx, -0.48, 0.07, 0.06) for x, dx in ((-0.32, -0.12), (-0.2, -0.04), (0.18, 0.04), (0.3, 0.12))])


@sticker("toybox", "horse", "Rocking horse", [RED, REDD, YEL, WHITE], ink=1.0)
def _():
    horse = _horse()
    shade = U(_rim(_horse, 0.08), circle(0.58, 0.54, 0.04))
    rocker = U(arc(0.0, 0.5, 1.02, math.radians(232), math.radians(308), 0.07),
               brush([(0.26, 0.6), (0.2, 0.36), (0.16, 0.12)], [0.09, 0.08, 0.06]),          # the mane
               brush([(-0.46, 0.08), (-0.66, 0.0), (-0.76, -0.22)], [0.09, 0.08, 0.05]),     # the tail
               box(-0.04, 0.2, 0.14, 0.05, 0.03))                                          # the saddle
    shine = U(oval(-0.18, 0.1, 0.16, 0.04, 0.0), circle(0.5, 0.58, 0.03))
    return [horse, shade, rocker, shine]


# ---- alphabet blocks D S D ----
_BLOCKS = [(-0.4, -0.44), (0.4, -0.44), (0.0, 0.32)]


def _cube(cx, cy, s=0.36, d=0.12):
    return U(box(cx, cy, s, s, 0.05), poly([(cx - s, cy + s), (cx - s + d, cy + s + d), (cx + s + d, cy + s + d), (cx + s + d, cy - s + d), (cx + s, cy - s)]))


@sticker("toybox", "blocks", "D S D blocks", [YEL, YELD, BLUE, WHITE], ink=1.0)
def _():
    blocks = U(*[_cube(cx, cy) for cx, cy in _BLOCKS])
    shade = U(*[sub(_cube(cx, cy), box(cx, cy, 0.36, 0.36, 0.05)) for cx, cy in _BLOCKS])
    panels = U(*[box(cx, cy, 0.27, 0.27, 0.05) for cx, cy in _BLOCKS])
    letters = U(text("D", -0.4, -0.44, 0.32), text("S", 0.4, -0.44, 0.32), text("D", 0.0, 0.32, 0.32),
                seg(-0.74, -0.14, -0.6, -0.14, 0.03))
    return [blocks, shade, panels, letters]


# ---- puzzle cube (generic, isometric) ----
def _iso(u, v, face):
    """A point on one face of an isometric cube of half-size 0.82: face 0 top, 1 left, 2 right; u, v in 0..1."""
    c, s = math.cos(math.radians(30)), math.sin(math.radians(30))
    R = 0.78
    top, lft, rgt, ctr = (0.0, R), (-R * c, R * s), (R * c, R * s), (0.0, 0.0)
    bot, bl, br = (0.0, -R), (-R * c, -R * s), (R * c, -R * s)
    quad = {0: (lft, top, rgt, ctr), 1: (lft, ctr, bot, bl), 2: (ctr, rgt, br, bot)}[face]
    a, b, cc, d = quad
    x = (1 - u) * (1 - v) * a[0] + u * (1 - v) * b[0] + u * v * cc[0] + (1 - u) * v * d[0]
    y = (1 - u) * (1 - v) * a[1] + u * (1 - v) * b[1] + u * v * cc[1] + (1 - u) * v * d[1]
    return (x, y)


def _tiles(face, g=0.07):
    out = []
    for i in range(3):
        for j in range(3):
            u0, u1, v0, v1 = i / 3 + g, (i + 1) / 3 - g, j / 3 + g, (j + 1) / 3 - g
            out.append(poly([_iso(u0, v0, face), _iso(u1, v0, face), _iso(u1, v1, face), _iso(u0, v1, face)]) - 0.012)
    return U(*out)


@sticker("toybox", "cube", "Puzzle cube", ["#3A3F5A", "#8FB8FF", "#FF9EC4", "#FFE38A"], ink=1.0)
def _():
    body = regpoly(0.0, 0.0, 6, 0.86, math.pi / 2) - 0.03
    shade = _tiles(2)
    left = _tiles(1)
    top = _tiles(0)
    return [body, shade, left, top]


# ---- toy spring on the stairs ----
def _stairs():
    return U(box(-0.46, -0.62, 0.42, 0.24, 0.03), box(0.46, -0.36, 0.42, 0.5, 0.03))


_COILS = [math.radians(18 + 144 * k / 6) for k in range(7)]


def _coil(a):
    return oval(0.5 * math.cos(a), -0.1 + 0.5 * math.sin(a), 0.085, 0.22, a)


@sticker("toybox", "spring", "Stair spring", [WOOD, "#C792FF", "#5E3A72", WHITE], ink=1.0)
def _():
    stairs = _stairs()
    spring = U(*[_coil(a) for a in _COILS], box(-0.5, -0.32, 0.17, 0.08, 0.03), box(0.5, 0.06, 0.17, 0.08, 0.03))
    shade = U(_rim(_stairs, 0.08), *[sub(_coil(a), _shift(lambda a=a: _coil(a), -0.05, 0.05)) for a in _COILS])
    shine = U(*[circle(0.5 * math.cos(a) - 0.03, -0.1 + 0.5 * math.sin(a) + 0.1, 0.035) for a in _COILS],
              seg(-0.8, -0.44, -0.5, -0.44, 0.03), seg(0.12, 0.08, 0.3, 0.08, 0.03))
    return [stairs, spring, shade, shine]


# ---- paper boat ----
def _paper():
    return U(poly([(-0.86, 0.0), (0.86, 0.0), (0.56, -0.44), (-0.56, -0.44)]) - 0.03, poly([(-0.42, 0.0), (0.0, 0.74), (0.42, 0.0)]) - 0.03)


@sticker("toybox", "boat", "Paper boat", ["#2FA8F0", "#F4F1EA", "#AEB9C9", "#5A6B86"], ink=1.0)
def _():
    water = U(oval(0.0, -0.56, 0.8, 0.2), oval(-0.6, -0.48, 0.24, 0.12), oval(0.6, -0.48, 0.24, 0.12))
    boat = _paper()
    shade = U(inter(_paper(), poly([(0.0, 0.74), (0.42, 0.0), (0.0, 0.0)])), inter(_paper(), -0.26 - Y))
    folds = U(seg(0.0, 0.7, 0.0, 0.02, 0.03), seg(-0.56, 0.0, -0.44, -0.4, 0.03), seg(0.56, 0.0, 0.44, -0.4, 0.03))
    return [water, boat, shade, folds]


# ---- toy drum with sticks ----
def _drum():
    return U(box(0.0, -0.3, 0.62, 0.36, 0.04), oval(0.0, 0.06, 0.62, 0.16), oval(0.0, -0.66, 0.62, 0.16))


@sticker("toybox", "drum", "Toy drum", [BLUE, BLUED, RED, WHITE], ink=1.0)
def _():
    drum = _drum()
    shade = _rim(_drum, 0.1)
    hoops = U(inter(_drum(), U(box(0.0, -0.02, 0.7, 0.08), box(0.0, -0.6, 0.7, 0.08))),
              seg(-0.66, 0.78, -0.14, 0.2, 0.07), circle(-0.68, 0.8, 0.12), seg(0.66, 0.78, 0.14, 0.2, 0.07), circle(0.68, 0.8, 0.12))
    cords = U(polyline([(-0.56, -0.12), (-0.37, -0.5), (-0.18, -0.12), (0.0, -0.5), (0.18, -0.12), (0.37, -0.5), (0.56, -0.12)], 0.045),
              oval(0.0, 0.06, 0.52, 0.1))
    return [drum, shade, hoops, cords]


# ---- bag of marbles ----
def _bag():
    return U(smin(oval(-0.1, -0.3, 0.5, 0.5), poly([(-0.32, 0.1), (0.12, 0.1), (0.04, 0.46), (-0.24, 0.46)]), 0.1),
             poly([(-0.32, 0.46), (0.12, 0.46), (0.28, 0.7), (-0.48, 0.7)]) - 0.04)


@sticker("toybox", "marbles", "Marble bag", ["#8B5CE0", "#5A2FA8", "#2EC4B6", WHITE], ink=1.0)
def _():
    bag = _bag()
    shade = U(_rim(_bag, 0.1), box(-0.1, 0.42, 0.22, 0.05, 0.03))
    marbles = U(circle(0.56, -0.62, 0.2), circle(0.7, -0.2, 0.15))
    swirl = U(inter(marbles, U(arc(0.56, -0.62, 0.1, 0.4, 2.6, 0.04), arc(0.7, -0.2, 0.08, 0.4, 2.6, 0.035))),
              circle(0.5, -0.54, 0.035), circle(0.66, -0.14, 0.03), oval(-0.36, -0.12, 0.06, 0.16, 0.2),
              polyline([(-0.4, 0.46), (-0.6, 0.34), (-0.66, 0.16)], 0.035), circle(-0.66, 0.12, 0.06))
    return [bag, shade, marbles, swirl]


# ---- pull-along dog ----
def _dog():
    return U(box(-0.06, -0.1, 0.5, 0.24, 0.14),                                   # the body
             circle(0.5, 0.3, 0.32), oval(0.8, 0.2, 0.14, 0.12),                   # head and snout
             taper(-0.52, 0.04, -0.7, 0.32, 0.07, 0.05),                           # the tail
             box(-0.38, -0.42, 0.1, 0.16, 0.03), box(0.28, -0.42, 0.1, 0.16, 0.03))


@sticker("toybox", "dog", "Pull-along dog", [WOOD, WOODD, RED, WHITE], ink=1.0)
def _():
    dog = _dog()
    ears = oval(0.3, 0.2, 0.12, 0.3, -0.25)
    shade = U(_rim(_dog, 0.08), ears, circle(0.56, 0.38, 0.075), circle(0.9, 0.24, 0.07))
    trim = U(circle(-0.38, -0.62, 0.2), circle(0.28, -0.62, 0.2), oval(0.76, 0.0, 0.07, 0.11, 0.2), box(0.18, -0.06, 0.06, 0.2, 0.02),
             bezier((-0.56, -0.24), (-0.76, -0.44), (-0.84, -0.12), 0.04), circle(-0.84, -0.08, 0.07))
    shine = U(seg(-0.42, 0.04, 0.0, 0.04, 0.04), circle(0.54, 0.41, 0.03), circle(0.42, 0.52, 0.04), circle(-0.38, -0.62, 0.07), circle(0.28, -0.62, 0.07))
    return [dog, shade, trim, shine]


# ---- tin toy rocket ----
def _rocket():
    with rotated(-0.6):
        return U(oval(0.0, 0.0, 0.26, 0.64), poly([(-0.24, -0.28), (-0.5, -0.66), (-0.16, -0.5)]) - 0.03,
                 poly([(0.24, -0.28), (0.5, -0.66), (0.16, -0.5)]) - 0.03)


@sticker("toybox", "rocket", "Tin rocket", [RED, REDD, YEL, WHITE], ink=1.0)
def _():
    rocket = _rocket()
    shade = _rim(_rocket, 0.09)
    with rotated(-0.6):
        trim = U(inter(oval(0.0, 0.0, 0.26, 0.64), 0.4 - Y),
                 poly([(-0.24, -0.28), (-0.5, -0.66), (-0.16, -0.5)]) - 0.03, poly([(0.24, -0.28), (0.5, -0.66), (0.16, -0.5)]) - 0.03,
                 inter(oval(0.0, 0.0, 0.26, 0.64), box(0.0, -0.24, 0.3, 0.04)))
        flame = U(oval(0.0, -0.78, 0.1, 0.16), circle(0.0, -0.66, 0.08),
                  seg(0.26, -0.02, 0.4, -0.02, 0.04), box(0.46, 0.06, 0.05, 0.12, 0.04), box(0.46, -0.1, 0.05, 0.12, 0.04))
        shine = U(circle(0.0, 0.12, 0.1),
                  *[circle(x, -0.14, 0.03) for x in (-0.12, 0.0, 0.12)], seg(-0.17, 0.38, -0.17, 0.2, 0.03))
    trim = U(trim, flame)
    return [rocket, shade, trim, shine]


# ---- jump rope ----
def _handles():
    return U(seg(-0.16, -0.44, 0.3, -0.82, 0.1), seg(0.18, -0.44, -0.28, -0.82, 0.1))


@sticker("toybox", "rope", "Jump rope", ["#C98B4B", "#8A5A33", "#FF5C8A", WHITE], ink=1.0)
def _():
    handles = _handles()
    shade = _rim(_handles, 0.06)
    rope = brush([(-0.16, -0.44), (-0.56, -0.18), (-0.66, 0.3), (-0.3, 0.72), (0.26, 0.7), (0.6, 0.32), (0.5, -0.12), (0.18, -0.44)],
                 [0.08, 0.1, 0.11, 0.11, 0.11, 0.1, 0.09, 0.08])
    shine = U(arc(0.0, 0.18, 0.8, math.radians(0), math.radians(30), 0.045), arc(-0.12, 0.26, 0.4, math.radians(110), math.radians(150), 0.035),
              seg(-0.12, -0.52, 0.04, -0.64, 0.03))
    return [handles, shade, rope, shine]


# ---- bouncy ball ----
def _ball():
    return circle(0.08, 0.1, 0.62)


@sticker("toybox", "ball", "Bouncy ball", ["#FF5C8A", "#B8285A", YEL, WHITE], ink=1.0)
def _():
    ball = U(_ball(), oval(0.08, -0.78, 0.4, 0.07))
    shade = U(_rim(_ball, 0.11), oval(0.08, -0.78, 0.4, 0.07))
    band = U(inter(_ball(), box(0.08, 0.1, 0.8, 0.12, 0.0, 0.35)), star(0.08, 0.1, 5, 0.2, 0.085))
    shine = U(arc(0.08, 0.1, 0.48, math.radians(115), math.radians(160), 0.05), circle(-0.3, 0.3, 0.045),
              seg(-0.86, -0.06, -0.66, -0.06, 0.04), seg(-0.82, 0.22, -0.66, 0.18, 0.04), seg(-0.82, -0.34, -0.66, -0.3, 0.04))
    return [ball, shade, band, shine]


# ---- PLAY ----
@sticker("toybox", "play", "PLAY", [INK, YEL, "#FF7A1A", WHITE], ink=1.0)
def _():
    word = text("PLAY", 0.0, 0.02, 0.5, ang=-0.1, maxw=1.42)
    back = U(word, text("PLAY", 0.05, -0.03, 0.5, ang=-0.1, maxw=1.42), star(0.66, 0.56, 5, 0.2, 0.09), star(-0.68, -0.52, 5, 0.15, 0.07)) - 0.06
    shade = sub(word, text("PLAY", -0.035, 0.05, 0.5, ang=-0.1, maxw=1.42))
    with rotated(-0.1):
        shine = inter(word, box(0, 0.2, 1.0, 0.035))
    shine = U(shine, star(0.66, 0.56, 5, 0.2, 0.09), star(-0.68, -0.52, 5, 0.15, 0.07))
    return [back, word, shade, shine]
