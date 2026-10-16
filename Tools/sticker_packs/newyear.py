PACK = ("newyear", "New Year", False)
PRO_IDS = {"clock", "midnight", "cannon", "balloons", "popper", "tophat"}


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


def _chip(x, y, a, w=0.13, h=0.075):
    """One chunky confetti chip."""
    return box(x, y, w, h, 0.03, a)


# ---- midnight clock (in a party hat) ----
@sticker("newyear", "clock", "Midnight clock", ["#FFF6DA", "#2E4BB5", "#1A1410", "#FF3D7F"], ink=1.0)
def _():
    face = circle(0, -0.12, 0.74)
    bezel = sub(circle(0, -0.12, 0.74), circle(0, -0.12, 0.58))
    hands = U(seg(0, -0.12, 0, 0.36, 0.08), circle(0, -0.12, 0.12), circle(0, -0.62, 0.07), circle(-0.4, -0.12, 0.07), circle(0.4, -0.12, 0.07))
    hat = U(poly(rotp([(-0.2, 0.5), (0.2, 0.5), (0.0, 0.84)], 0.5, -0.1, 0.5)), circle(-0.32, 0.84, 0.09))
    return [face, bezel, hands, hat]


# ---- midnight "12" ----
@sticker("newyear", "midnight", "Twelve", ["#FFC531", "#2E4BB5", "#1B2F85", "#FFF6DA"], ink=1.0)
def _():
    burst = star(0, 0, 12, 0.88, 0.7) - 0.05
    disc = circle(0, 0, 0.62)
    shade = _lowr(disc, 0.28)
    num = text("12", 0.0, 0.0, 0.5, maxw=0.9)
    return [burst, disc, shade, num]


# ---- party hat ----
def _hat_build():
    return poly([(-0.55, -0.62), (0.55, -0.62), (0.0, 0.62)])


@sticker("newyear", "partyhat", "Party hat", ["#FF3D7F", "#C2185B", "#FFE14A", "#FFFFFF"], ink=1.0)
def _():
    cone = _hat_build()
    shade = _lowr(cone, 0.08)
    trim = inter(cone, stripes(0.42, math.radians(-35), 0.32, 0.12))
    pom = U(circle(0, 0.66, 0.2), circle(-0.17, 0.58, 0.12), circle(0.17, 0.58, 0.12), box(0, -0.66, 0.6, 0.1, 0.08))
    return [cone, shade, trim, pom]


# ---- noisemaker (blowout horn, held flat) ----
@sticker("newyear", "horn", "Noisemaker", ["#2FA8F0", "#1B72B8", "#FFE14A", "#FF3D7F"], ink=1.0)
def _():
    body = taper(-0.84, -0.3, 0.1, 0.04, 0.1, 0.38)
    shade = _lowr(body, 0.1)
    bands = inter(body, stripes(0.36, math.radians(160), 0.3, 0.04))
    curl = U(arc(0.5, 0.36, 0.3, -1.4, 3.4, 0.095), seg(0.1, 0.04, 0.55, 0.07, 0.095))
    return [body, shade, bands, curl]


# ---- confetti cannon (on a wheel) ----
def _cannon_build():
    return U(box(-0.14, -0.06, 0.58, 0.28, 0.1, 0.35), box(0.46, 0.1, 0.1, 0.38, 0.05, 0.35))


@sticker("newyear", "cannon", "Confetti cannon", ["#9B3FE0", "#6A22A8", "#FFC531", "#FF3D7F"], ink=1.0)
def _():
    barrel = _cannon_build()
    shade = _lowr(barrel, 0.0)
    wheels = U(sub(circle(-0.3, -0.46, 0.34), circle(-0.3, -0.46, 0.12)), seg(-0.3, -0.46, 0.1, -0.1, 0.07))
    burst = U(brush([(0.58, 0.36), (0.7, 0.62), (0.86, 0.7)], [0.08, 0.08, 0.08]), _chip(0.3, 0.72, 0.5, 0.17, 0.1),
              _chip(0.74, 0.42, -0.5, 0.15, 0.09), _chip(0.1, 0.62, 1.1, 0.15, 0.09))
    return [barrel, shade, wheels, burst]


# ---- disco ball ----
@sticker("newyear", "discoball", "Disco ball", ["#E4ECF7", "#9AA9C4", "#4FB0FF", "#FFFFFF"], ink=1.0)
def _():
    cx, cy, R = 0.0, -0.1, 0.68
    ball = circle(cx, cy, R)
    shade = _lowr(ball, 0.2)
    tiles = []
    for i in range(-3, 4):
        for j in range(-3, 4):
            if (i + j) % 2:
                continue
            u, v = i * 0.4, j * 0.4
            x, y = 0.6 * math.sin(u), 0.6 * math.sin(v)
            tiles.append(box(cx + x, cy + y, 0.1 * math.cos(u) + 0.02, 0.1 * math.cos(v) + 0.02, 0.03))
    tiles = inter(circle(cx, cy, R - 0.06), U(*tiles))
    glint = U(_glint(0.5, 0.46, 0.28), box(0, 0.64, 0.05, 0.14, 0.02), circle(-0.3, 0.2, 0.06))
    return [ball, shade, tiles, glint]


# ---- balloon pair ----
@sticker("newyear", "balloons", "Balloons", ["#FF3D7F", "#2FA8F0", "#FFFFFF", "#8A8F98"], ink=1.0)
def _():
    left = U(oval(-0.3, 0.3, 0.38, 0.46, 0.15), poly([(-0.42, -0.14), (-0.22, -0.14), (-0.33, -0.04)]))
    right = U(oval(0.34, 0.38, 0.36, 0.44, -0.15), poly([(0.22, -0.02), (0.42, -0.04), (0.3, 0.07)]))
    shine = U(oval(-0.44, 0.46, 0.07, 0.14, 0.3), oval(0.22, 0.54, 0.07, 0.14, -0.3))
    strings = U(polyline([(-0.32, -0.14), (-0.1, -0.5), (0.1, -0.86)], 0.04), polyline([(0.3, 0.04), (0.14, -0.4), (0.1, -0.86)], 0.04),
                circle(0.1, -0.84, 0.08))
    return [left, right, shine, strings]


# ---- party popper (pull-string) ----
def _popper_build():
    return U(taper(0.52, -0.62, -0.14, 0.04, 0.14, 0.38), box(-0.14, 0.04, 0.42, 0.07, 0.03, -1.0))


@sticker("newyear", "popper", "Party popper", ["#FFB52E", "#D97A0B", "#FF3D7F", "#2FA8F0"], ink=1.0)
def _():
    cone = _popper_build()
    shade = _lowr(cone, -0.05)
    sprays = U(brush([(-0.14, 0.14), (-0.3, 0.46), (-0.1, 0.7), (-0.24, 0.9)], [0.08, 0.08, 0.08, 0.08]),
               brush([(-0.3, 0.04), (-0.62, 0.2), (-0.7, 0.5)], [0.08, 0.08, 0.08]),
               brush([(-0.04, 0.2), (0.16, 0.5), (0.5, 0.56)], [0.08, 0.08, 0.08]))
    pull = U(polyline([(0.5, -0.72), (0.66, -0.8), (0.76, -0.6)], 0.06), ring(0.74, -0.48, 0.12, 0.06))
    return [cone, shade, sprays, pull]


# ---- streamers ----
def _ribbon(x, sway):
    r = brush([(x, 0.62), (x + sway, 0.2), (x - sway, -0.22), (x + sway * 0.5, -0.64)], [0.15, 0.15, 0.15, 0.15])
    return sub(r, poly([(x + sway * 0.5 - 0.16, -0.9), (x + sway * 0.5 + 0.16, -0.9), (x + sway * 0.5, -0.56)]))


@sticker("newyear", "streamers", "Streamers", ["#FF3D7F", "#2FA8F0", "#FFE14A", "#9B3FE0"], ink=1.0)
def _():
    left, middle, right = _ribbon(-0.58, 0.1), _ribbon(0.0, -0.1), _ribbon(0.58, 0.1)
    rolls = U(*[sub(circle(x, 0.66, 0.24), ring(x, 0.66, 0.11, 0.04)) for x in (-0.58, 0.0, 0.58)])
    return [left, middle, right, rolls]


# ---- sparkling cider ----
def _cup_build():
    return poly([(-0.52, 0.56), (0.52, 0.56), (0.44, -0.78), (-0.44, -0.78)])


@sticker("newyear", "cider", "Sparkling cider", ["#D8EEFF", "#FFB52E", "#FFF4C7", "#E3172F"], ink=1.0)
def _():
    glass = _cup_build()
    juice = inter(_cup_build(), Y - 0.36)
    bubbles = U(circle(-0.16, 0.18, 0.1), circle(0.16, 0.06, 0.11), circle(0.0, 0.42, 0.07))
    apple = U(circle(-0.09, -0.36, 0.17), circle(0.09, -0.36, 0.17), seg(0.0, -0.2, 0.04, -0.06, 0.04), poly([(0.04, -0.12), (0.2, -0.02), (0.1, -0.2)]))
    return [glass, juice, bubbles, apple]


# ---- calendar page ----
@sticker("newyear", "calendar", "Calendar page", ["#FFFFFF", "#E3172F", "#B9C3D3", "#1A1410"], ink=1.0)
def _():
    base = box(0, -0.04, 0.7, 0.78, 0.08)
    fold = poly([(0.72, -0.5), (0.72, -0.9), (0.28, -0.9)])
    page = sub(base, fold)
    head = sub(inter(base, 0.4 - Y), text("JAN", 0.0, 0.58, 0.26, maxw=1.0))
    curl = poly([(0.7, -0.46), (0.7, -0.82), (0.34, -0.82)])
    num = text("1", 0.0, -0.14, 0.64)
    return [page, head, curl, num]


# ---- top hat spilling streamers ----
def _topper_build():
    return U(box(0, -0.18, 0.4, 0.36, 0.06), box(0, -0.52, 0.74, 0.1, 0.06))


@sticker("newyear", "tophat", "Top hat", ["#9B3FE0", "#6A22A8", "#FFC531", "#FF3D7F"], ink=1.0)
def _():
    hat = _topper_build()
    shade = _lowr(hat, 0.2)
    band = inter(hat, box(0, -0.38, 1.0, 0.1))
    spill = U(brush([(-0.2, 0.15), (-0.44, 0.5), (-0.7, 0.62)], [0.06, 0.1, 0.15]), brush([(0.0, 0.15), (0.04, 0.5), (0.26, 0.74)], [0.06, 0.1, 0.15]),
              brush([(0.2, 0.15), (0.46, 0.4), (0.8, 0.4)], [0.06, 0.1, 0.15]),
              _chip(-0.8, 0.3, 0.8, 0.15, 0.09), _chip(0.6, 0.68, -0.7, 0.15, 0.09), _chip(-0.3, 0.72, 0.3, 0.15, 0.09))
    return [hat, shade, band, spill]


# ---- resolution checklist ----
@sticker("newyear", "checklist", "Resolutions", ["#FFF6DA", "#E0A030", "#1FB86B", "#1A1410"], ink=1.0)
def _():
    board = box(0, -0.04, 0.62, 0.8, 0.1)
    clip = box(0, 0.78, 0.26, 0.12, 0.05)
    ticks = U(polyline([(-0.4, 0.4), (-0.3, 0.3), (-0.12, 0.52)], 0.07), polyline([(-0.4, -0.02), (-0.3, -0.12), (-0.12, 0.1)], 0.07))
    rows = U(seg(0.04, 0.4, 0.42, 0.4, 0.06), seg(0.04, 0.0, 0.42, 0.0, 0.06), seg(0.04, -0.4, 0.42, -0.4, 0.06),
             box(-0.26, -0.4, 0.11, 0.11, 0.03))
    return [board, clip, ticks, rows]


# ---- golden ticket (torn stub) ----
def _ticket_build():
    with rotated(0.22):
        body = box(0, 0, 0.8, 0.46, 0.06)
        notch = U(circle(-0.8, 0, 0.14), circle(0.8, 0, 0.14), circle(-0.4, 0.46, 0.1), circle(-0.4, -0.46, 0.1))
        return sub(body, notch)


@sticker("newyear", "ticket", "Golden ticket", ["#FFC531", "#E09A12", "#7A3B00", "#FFF4C7"], ink=1.0)
def _():
    ticket = _ticket_build()
    shade = _lowr(ticket, 0.3)
    with rotated(0.22):
        holes = U(*[circle(-0.4, y, 0.05) for y in (-0.28, -0.14, 0.0, 0.14, 0.28)])
        print_ = text("NYE", 0.18, 0.0, 0.5, maxw=0.86)
        stub = star(-0.6, 0.0, 5, 0.17, 0.08, math.pi / 2)
    mark = U(print_, stub)
    return [ticket, shade, mark, holes]


# ---- HNY ----
@sticker("newyear", "hny", "HNY", ["#2E4BB5", "#FFC531", "#FFFFFF", "#FF3D7F"], ink=1.0)
def _():
    pill = box(0, 0, 0.88, 0.5, 0.5)
    rim = sub(box(0, 0, 0.88, 0.5, 0.5), box(0, 0, 0.78, 0.4, 0.4))
    word = text("HNY", 0.0, 0.0, 0.46, maxw=1.3)
    sparkles = U(_glint(0.72, 0.5, 0.26), _glint(-0.66, -0.42, 0.24))
    return [pill, rim, word, sparkles]


# ---- 3 2 1 ----
@sticker("newyear", "countdown", "3 2 1", ["#FF3D7F", "#C2185B", "#FFFFFF", "#FFE14A"], ink=1.0)
def _():
    xs = (-0.6, 0.0, 0.6)
    tiles = U(*[box(x, 0, 0.27, 0.38, 0.08) for x in xs])
    shade = _lowr(tiles, 0.3)
    digits = U(text("3", -0.6, -0.02, 0.5), text("2", 0.0, -0.02, 0.5), text("1", 0.6, -0.02, 0.5))
    seam = U(*[box(x, 0.0, 0.27, 0.025) for x in xs])
    return [tiles, shade, digits, seam]
