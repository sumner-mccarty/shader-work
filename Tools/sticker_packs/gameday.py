PACK = ("gameday", "Game Day", False)
PRO_IDS = {"helmet", "stadium", "ring", "snare", "td", "scoreboard"}

# invented team colors (no real team): violet + lime, navy trim
VIOLET, VIOLETD = "#7B3FE4", "#45208F"
LIME = "#A6E22E"
ORANGE, ORANGED = "#FF7A1A", "#B84A0A"
NAVY, NAVYD = "#24345C", "#121A30"
GOLD, GOLDD = "#FFC531", "#C98A0C"
LEATHER, LEATHERD = "#A4502A", "#5E2A12"
WHITE = "#FFFFFF"


def _shift(make, dx, dy):
    """The shape `make()` draws, slid by (dx, dy)."""
    with rotated(0.0, 0.0, 0.0, dx, dy):
        return make()


def _rim(make, k=0.11):
    """Lower-right shade: the shape minus a copy of itself nudged up-left."""
    return sub(make(), _shift(make, -k, k))


def _lens(cx, cy, hw, hh, ang=0.0):
    """A football: a pointed lens hw long (half) and hh tall (half), turned by ang."""
    r = (hw * hw + hh * hh) / (2 * hh)
    with rotated(ang, cx, cy):
        return inter(circle(cx, cy - (r - hh), r), circle(cx, cy + (r - hh), r)) - 0.03


# ---- football ----
def _football():
    return _lens(0, 0, 0.84, 0.47, 0.55)


@sticker("gameday", "football", "Football", [LEATHER, LEATHERD, WHITE, "#FFD9B8"], ink=1.0)
def _():
    ball = _football()
    shade = _rim(_football, 0.12)
    with rotated(0.55):
        laces = U(seg(-0.3, 0.0, 0.3, 0.0, 0.05), *[seg(x, -0.13, x, 0.13, 0.045) for x in (-0.2, -0.067, 0.067, 0.2)],
                  inter(ball, U(box(-0.56, 0, 0.045, 0.6), box(0.56, 0, 0.045, 0.6))))
        shine = U(seg(-0.42, 0.27, -0.2, 0.33, 0.045), circle(-0.56, 0.2, 0.04))
    return [ball, shade, laces, shine]


# ---- helmet (side view, facing right) ----
def _helmet():
    dome = sub(circle(-0.1, 0.12, 0.72), box(0.5, -0.42, 0.44, 0.42))
    return U(dome, oval(0.04, -0.34, 0.24, 0.26))


@sticker("gameday", "helmet", "Helmet", [VIOLET, VIOLETD, LIME, WHITE], ink=1.0)
def _():
    helmet = _helmet()
    shade = _rim(_helmet, 0.12)
    trim = U(inter(ring(-0.1, 0.12, 0.5, 0.08), 0.1 - Y),
             circle(-0.1, -0.12, 0.09),
             polyline([(0.5, 0.06), (0.86, 0.06), (0.86, -0.44), (0.24, -0.44)], 0.055), seg(0.56, 0.06, 0.56, -0.44, 0.05))
    shine = U(oval(-0.44, 0.38, 0.13, 0.055, 0.75), circle(-0.58, 0.18, 0.04))
    return [helmet, shade, trim, shine]


# ---- goal posts with a ball sailing through ----
def _posts():
    return U(seg(0, -0.84, 0, -0.22, 0.14), box(0, -0.22, 0.72, 0.13, 0.06),
             seg(-0.62, -0.22, -0.62, 0.84, 0.13), seg(0.62, -0.22, 0.62, 0.84, 0.13))


@sticker("gameday", "goalposts", "Goal posts", [GOLD, GOLDD, LEATHER, WHITE], ink=1.0)
def _():
    posts = _posts()
    shade = _rim(_posts, 0.09)
    ball = _lens(0.0, 0.38, 0.46, 0.27, 0.5)
    with rotated(0.5, 0.0, 0.38):
        shine = U(seg(-0.16, 0.38, 0.16, 0.38, 0.045), *[seg(x, 0.29, x, 0.47, 0.04) for x in (-0.07, 0.07)])
    shine = U(shine, seg(-0.67, 0.2, -0.67, 0.7, 0.04), seg(0.57, 0.2, 0.57, 0.7, 0.04))
    return [posts, shade, ball, shine]


# ---- TD burst ----
def _burst():
    return star(0, 0, 14, 0.92, 0.7, 0.1) - 0.02


@sticker("gameday", "td", "TD!", [ORANGE, ORANGED, NAVY, WHITE], ink=1.0)
def _():
    burst = _burst()
    shade = _rim(_burst, 0.12)
    word = text("TD!", 0.02, 0.0, 0.52, ang=0.12, maxw=1.2)
    shine = U(arc(0, 0, 0.6, math.radians(110), math.radians(160), 0.045), circle(-0.62, 0.08, 0.04))
    return [burst, shade, word, shine]


# ---- jersey 00 ----
def _jersey():
    return poly([(-0.32, 0.78), (-0.14, 0.66), (0.14, 0.66), (0.32, 0.78), (0.86, 0.5), (0.9, 0.02), (0.62, -0.02),
                 (0.6, -0.84), (-0.6, -0.84), (-0.62, -0.02), (-0.9, 0.02), (-0.86, 0.5)]) - 0.03


@sticker("gameday", "jersey", "Jersey 00", [VIOLET, VIOLETD, LIME, WHITE], ink=1.0)
def _():
    shirt = _jersey()
    shade = _rim(_jersey, 0.1)
    trim = U(inter(shirt, U(box(-0.73, 0.26, 0.055, 0.5), box(0.73, 0.26, 0.055, 0.5))),
             inter(shirt, shell(poly([(-0.2, 0.72), (0.2, 0.72), (0.0, 0.42)]), 0.05)),
             text("00", 0.0, -0.22, 0.46, maxw=0.95))
    shine = U(seg(-0.48, 0.58, -0.3, 0.68, 0.045), circle(-0.42, 0.2, 0.04))
    return [shirt, shade, trim, shine]


# ---- stadium with lights ----
def _stadium():
    stand = poly([(-0.88, -0.78), (0.88, -0.78), (0.76, -0.04), (-0.76, -0.04)]) - 0.02
    towers = U(seg(-0.58, -0.04, -0.58, 0.5, 0.075), seg(0.58, -0.04, 0.58, 0.5, 0.075))
    heads = U(box(-0.58, 0.64, 0.3, 0.22, 0.05), box(0.58, 0.64, 0.3, 0.22, 0.05))
    return U(stand, towers, heads, box(0, -0.04, 0.8, 0.07, 0.03))


@sticker("gameday", "stadium", "Stadium", [NAVY, NAVYD, GOLD, WHITE], ink=1.0)
def _():
    stadium = _stadium()
    shade = _rim(_stadium, 0.08)
    arches = U(*[U(box(x, -0.48, 0.08, 0.14, 0.0), circle(x, -0.34, 0.08)) for x in (-0.54, -0.18, 0.18, 0.54)])
    lights = U(box(-0.58, 0.64, 0.23, 0.15, 0.04), box(0.58, 0.64, 0.23, 0.15, 0.04), arches,
               star(0.0, 0.36, 5, 0.22, 0.09))
    shine = U(*[circle(sx * 0.58 + dx, 0.64 + dy, 0.05) for sx in (-1, 1) for dx in (-0.12, 0.0, 0.12) for dy in (0.065, -0.065)],
              seg(-0.66, -0.16, -0.3, -0.16, 0.035))
    return [stadium, shade, lights, shine]


# ---- nacho tray ----
_CHIPS = [(-0.5, 0.02, 0.36, 1.3), (0.34, 0.12, 0.38, 1.45), (-0.08, 0.3, 0.42, 1.75), (0.62, -0.06, 0.3, 1.9), (0.04, -0.04, 0.34, 1.15)]


def _chip(cx, cy, r, a):
    return regpoly(cx, cy, 3, r, a) - 0.05


@sticker("gameday", "nachos", "Nachos", [GOLD, "#E0861A", VIOLET, WHITE], ink=1.0)
def _():
    chips = U(*[_chip(*c) for c in _CHIPS])
    shade = U(*[_rim(lambda c=c: _chip(*c), 0.09) for c in _CHIPS])
    tray = poly([(-0.86, -0.18), (0.86, -0.18), (0.7, -0.8), (-0.7, -0.8)]) - 0.04
    shine = U(seg(-0.74, -0.32, -0.3, -0.32, 0.04), circle(-0.62, 0.14, 0.045), circle(-0.16, 0.44, 0.045),
              circle(0.28, 0.25, 0.04))
    return [chips, shade, tray, shine]


# ---- wing basket ----
_WINGS = [0.62, -0.62, 0.0]


def _wing(a):
    with rotated(a, 0.0, -0.24):
        return U(oval(0.0, 0.1, 0.25, 0.34), taper(0.0, 0.3, 0.0, 0.58, 0.1, 0.07))


def _bone(a):
    with rotated(a, 0.0, -0.24):
        return U(seg(0.0, 0.44, 0.0, 0.62, 0.08), circle(-0.08, 0.7, 0.11), circle(0.08, 0.7, 0.11))


@sticker("gameday", "wings", "Wing basket", ["#E8571E", "#9A2E0E", "#E3172F", WHITE], ink=1.0)
def _():
    wings = U(*[U(_wing(a), _bone(a)) for a in _WINGS])
    shade = U(*[_rim(lambda a=a: _wing(a), 0.09) for a in _WINGS])
    basket = U(inter(oval(0, -0.22, 0.84, 0.62), Y + 0.22), box(0, -0.22, 0.86, 0.09, 0.05))
    checks = inter(inter(oval(0, -0.22, 0.84, 0.62), Y + 0.36), inter(stripes(0.28, 0.0, 0.5), stripes(0.28, math.pi / 2, 0.5, 0.14)))
    shine = U(checks, *[_bone(a) for a in _WINGS], oval(-0.26, 0.14, 0.1, 0.045, 1.0))
    return [wings, shade, basket, shine]


# ---- scoreboard HOME 7 AWAY 3 ----
def _board():
    return U(box(0, 0.16, 0.9, 0.62, 0.08), box(-0.42, -0.66, 0.09, 0.22), box(0.42, -0.66, 0.09, 0.22))


@sticker("gameday", "scoreboard", "Scoreboard", [NAVY, NAVYD, GOLD, WHITE], ink=1.0)
def _():
    board = _board()
    shade = _rim(_board, 0.08)
    digits = U(text("7", -0.42, 0.0, 0.5, maxw=0.6), text("3", 0.42, 0.0, 0.5, maxw=0.6))
    shine = U(text("HOME", -0.47, 0.54, 0.13, maxw=0.48), text("AWAY", 0.47, 0.54, 0.13, maxw=0.48),
              box(0, 0.0, 0.035, 0.3))
    digits = U(digits, _lens(0.0, 0.54, 0.11, 0.065, 0.0))
    return [board, shade, digits, shine]


# ---- pennant GO! ----
def _flag():
    top = [(-0.58 + 1.5 * t, 0.44 - 0.44 * t + 0.07 * math.sin(t * 6.0)) for t in np.linspace(0, 1, 14)]
    bot = [(-0.58 + 1.5 * t, -0.44 + 0.44 * t + 0.07 * math.sin(t * 6.0)) for t in np.linspace(1, 0, 14)[1:]]
    with rotated(0.3, 0.0, 0.0, 0.06, 0.0):
        return poly(top + bot) - 0.03


@sticker("gameday", "pennant", "GO! pennant", [ORANGE, ORANGED, NAVY, WHITE], ink=1.0)
def _():
    flag = _flag()
    shade = _rim(_flag, 0.1)
    with rotated(0.3, 0.0, 0.0, 0.06, 0.0):
        trim = U(inter(flag, box(-0.58, 0.0, 0.12, 0.6)), seg(-0.72, 0.62, -0.72, -0.62, 0.07), circle(-0.72, 0.66, 0.1))
    word = U(text("GO!", 0.1, 0.06, 0.42, ang=0.3, maxw=0.9),
             seg(-0.3, 0.38, -0.06, 0.42, 0.04))
    return [flag, shade, trim, word]


# ---- cheer megaphone ----
def _cone():
    with rotated(0.42, 0.0, 0.0, 0.08, 0.08):
        return U(poly([(-0.66, 0.14), (0.56, 0.48), (0.56, -0.48), (-0.66, -0.14)]) - 0.02, oval(0.56, 0.0, 0.13, 0.5))


@sticker("gameday", "megaphone", "Cheer cone", [ORANGE, ORANGED, VIOLET, WHITE], ink=1.0)
def _():
    cone = _cone()
    shade = _rim(_cone, 0.1)
    with rotated(0.42, 0.0, 0.0, 0.08, 0.08):
        trim = U(oval(0.56, 0.0, 0.13, 0.5), inter(cone, box(-0.22, 0, 0.07, 0.5)), box(-0.7, 0.0, 0.07, 0.17, 0.03))
        shine = U(star(0.14, 0.0, 5, 0.3, 0.12, math.pi / 2 - 0.42), seg(-0.42, 0.16, -0.3, 0.2, 0.035))
    pompom = U(star(-0.52, -0.56, 11, 0.34, 0.22, 0.2), circle(-0.52, -0.56, 0.26))
    trim = U(trim, pompom)
    return [cone, shade, trim, shine]


# ---- championship ring ----
def _ring():
    band = U(oval(0, -0.3, 0.5, 0.56) - 0.0, poly([(-0.46, 0.12), (-0.62, 0.36), (0.62, 0.36), (0.46, 0.12)]))
    return U(sub(band, oval(0, -0.36, 0.3, 0.36)), regpoly(0, 0.38, 8, 0.5, math.pi / 8) - 0.04)


@sticker("gameday", "ring", "Champ ring", [GOLD, GOLDD, VIOLET, WHITE], ink=1.0)
def _():
    band = _ring()
    shade = _rim(_ring, 0.1)
    stone = regpoly(0, 0.38, 8, 0.32, math.pi / 8) - 0.03
    shine = U(star(0, 0.38, 5, 0.19, 0.08), arc(0, -0.33, 0.42, math.radians(150), math.radians(205), 0.04),
              star(-0.72, 0.72, 4, 0.24, 0.065), star(0.76, 0.0, 4, 0.18, 0.05))
    return [band, shade, stone, shine]


# ---- cooler with a football on it ----
def _cooler():
    return U(box(0, -0.24, 0.84, 0.54, 0.1), box(0, 0.36, 0.9, 0.14, 0.07))


@sticker("gameday", "cooler", "Cooler", ["#E3172F", "#8E0F1E", LEATHER, WHITE], ink=1.0)
def _():
    cooler = _cooler()
    shade = _rim(_cooler, 0.1)
    ball = _lens(0.0, -0.26, 0.64, 0.34, 0.14)
    with rotated(0.14, 0.0, -0.26):
        laces = U(seg(-0.24, -0.26, 0.24, -0.26, 0.05), *[seg(x, -0.37, x, -0.15, 0.045) for x in (-0.15, 0.0, 0.15)],
                  inter(ball, U(box(-0.44, -0.26, 0.04, 0.5), box(0.44, -0.26, 0.04, 0.5))))
    lid = U(box(0, 0.36, 0.9, 0.14, 0.07), inter(shell(box(0, 0.6, 0.36, 0.2, 0.12), 0.06), Y - 0.5),
            laces, star(0.68, 0.66, 4, 0.18, 0.05), star(-0.7, 0.62, 4, 0.13, 0.04))
    return [cooler, shade, ball, lid]


# ---- play diagram clipboard ----
def _board_clip():
    return box(0, -0.06, 0.68, 0.86, 0.08)


@sticker("gameday", "playbook", "Play diagram", ["#B8864B", "#7A4A2B", WHITE, NAVY], ink=1.0)
def _():
    board = _board_clip()
    shade = _rim(_board_clip, 0.1)
    paper = U(box(0, -0.14, 0.54, 0.66, 0.03), seg(-0.6, 0.66, -0.6, 0.2, 0.035))
    xs = U(*[U(seg(x - 0.12, 0.36 - 0.12, x + 0.12, 0.36 + 0.12, 0.055), seg(x - 0.12, 0.36 + 0.12, x + 0.12, 0.36 - 0.12, 0.055)) for x in (-0.26, 0.26)])
    os_ = U(ring(-0.26, -0.5, 0.11, 0.05), ring(0.26, -0.5, 0.11, 0.05))
    arrow = U(bezier((-0.26, -0.34), (-0.3, -0.02), (0.06, -0.06), 0.045), poly([(0.2, -0.06), (0.02, 0.06), (0.02, -0.18)]))
    clip = U(box(0, 0.76, 0.28, 0.11, 0.05), box(0, 0.86, 0.12, 0.07, 0.04))
    marks = U(xs, os_, arrow, clip)
    return [board, shade, paper, marks]


# ---- drum-line snare with team stripes ----
def _snare():
    return U(box(0, -0.22, 0.74, 0.36, 0.04), oval(0, 0.14, 0.74, 0.2), oval(0, -0.58, 0.74, 0.2))


@sticker("gameday", "snare", "Drum line", [NAVY, NAVYD, LIME, WHITE], ink=1.0)
def _():
    sticks = U(seg(-0.7, 0.8, -0.1, 0.4, 0.075), circle(-0.72, 0.8, 0.11), seg(0.7, 0.8, 0.1, 0.4, 0.075), circle(0.72, 0.8, 0.11))
    drum = U(_snare(), sticks)
    shade = _rim(_snare, 0.1)
    shell_ = sub(U(box(0, -0.22, 0.74, 0.36, 0.04), oval(0, -0.58, 0.74, 0.2)), oval(0, 0.14, 0.74, 0.2))
    stripes_ = U(inter(shell_, polyline([(-0.8, 0.02), (0.0, -0.4), (0.8, 0.02)], 0.12)), sticks)
    head = U(oval(0, 0.14, 0.64, 0.14), seg(-0.62, -0.2, -0.62, -0.5, 0.04))
    return [drum, shade, stripes_, head]


# ---- face-paint fan ----
def _fanface():
    return circle(0.0, -0.04, 0.72)


@sticker("gameday", "fan", "Face-paint fan", ["#F2B58C", "#C98A62", VIOLET, "#2A1410"], ink=1.0)
def _():
    face = U(_fanface(), circle(-0.72, -0.02, 0.13), circle(0.72, -0.02, 0.13),
             *[circle(x, 0.68, 0.14) for x in (-0.3, 0.0, 0.3)])
    shade = _rim(_fanface, 0.11)
    paint = U(*[box(sx * 0.4, -0.06, 0.16, 0.05, 0.02, sx * 0.35) for sx in (-1, 1)],
              *[box(sx * 0.4, -0.2, 0.16, 0.05, 0.02, sx * 0.35) for sx in (-1, 1)],
              star(0.0, 0.42, 5, 0.17, 0.075), *[circle(x, 0.68, 0.14) for x in (-0.3, 0.0, 0.3)])
    features = U(arc(-0.26, 0.12, 0.11, math.radians(20), math.radians(160), 0.045), arc(0.26, 0.12, 0.11, math.radians(20), math.radians(160), 0.045),
                 inter(oval(0.0, -0.36, 0.26, 0.24), Y + 0.32))
    return [face, shade, paint, features]


# ---- HIKE ----
@sticker("gameday", "hike", "HIKE", [NAVY, ORANGE, ORANGED, WHITE], ink=1.0)
def _():
    word = text("HIKE", 0.0, 0.02, 0.52, ang=0.14, maxw=1.46)
    back = U(word, text("HIKE", 0.05, -0.04, 0.52, ang=0.14, maxw=1.46)) - 0.07
    shade = sub(word, text("HIKE", -0.035, 0.05, 0.52, ang=0.14, maxw=1.46))
    with rotated(0.14):
        shine = inter(word + 0.0, box(0, 0.2, 1.0, 0.035))
    return [back, word, shade, shine]
