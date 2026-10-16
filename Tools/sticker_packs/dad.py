PACK = ("dad", "Father's Day", False)
PRO_IDS = {"grill", "mug", "mower", "fishing", "ribbon", "superdad"}


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


def _flame(cx, cy, w, h, sk=0.0):
    """A teardrop flame: round base at (cx, cy), tip h above, leaning sk sideways."""
    return U(circle(cx, cy + w * 0.2, w), taper(cx, cy + w * 0.2, cx + sk, cy + h, w * 0.95, 0.0))


# ---- #1 DAD mug ----
def _mug_build():
    return U(box(-0.12, -0.12, 0.52, 0.52, 0.12), ring(0.5, -0.1, 0.26, 0.09))


@sticker("dad", "mug", "Dad mug", ["#2F7BE0", "#1B4FA8", "#FFFFFF", "#DDE6F2"], ink=1.0)
def _():
    mug = _mug_build()
    shade = _rim(_mug_build, -0.1, 0.0)
    words = U(text("#1", -0.12, 0.08, 0.34, maxw=0.7), text("DAD", -0.12, -0.34, 0.3, maxw=0.8))
    steam = U(brush([(-0.3, 0.5), (-0.4, 0.66), (-0.26, 0.8), (-0.34, 0.94)], [0.07, 0.07, 0.07, 0.05]),
              brush([(0.04, 0.5), (-0.06, 0.66), (0.08, 0.78), (0.0, 0.92)], [0.07, 0.07, 0.07, 0.05]))
    return [mug, shade, words, steam]


# ---- necktie ----
def _tie_build():
    return U(poly([(-0.2, 0.92), (0.2, 0.92), (0.28, 0.55), (-0.28, 0.55)]),
             poly([(-0.26, 0.5), (0.26, 0.5), (0.52, -0.68), (0.0, -0.92), (-0.52, -0.68)]))


@sticker("dad", "tie", "Necktie", ["#E3172F", "#A60F22", "#FFFFFF", "#FFC531"], ink=1.0)
def _():
    tie = _tie_build()
    shade = _lowr(tie, 0.2)
    bands = inter(stripes(0.34, 0.9, 0.35), tie)
    clip = box(0, -0.1, 0.34, 0.07, 0.02)
    return [tie, shade, bands, clip]


# ---- toolbox ----
def _toolbox_build():
    return U(box(0, -0.2, 0.84, 0.46, 0.08), box(0, 0.34, 0.9, 0.12, 0.05))


@sticker("dad", "toolbox", "Toolbox", ["#E3172F", "#A60F22", "#B8C2CF", "#FFD34D"], ink=1.0)
def _():
    toolbox = _toolbox_build()
    shade = _rim(_toolbox_build, -0.1, 0.1)
    handle = U(arc(0, 0.4, 0.34, math.radians(15), math.radians(165), 0.07), box(-0.3, 0.42, 0.08, 0.05), box(0.3, 0.42, 0.08, 0.05))
    latch = U(box(-0.5, 0.2, 0.1, 0.12, 0.03), box(0.5, 0.2, 0.1, 0.12, 0.03), box(0, -0.15, 0.2, 0.1, 0.04))
    return [toolbox, shade, handle, latch]


# ---- grill with flames ----
def _grill_build():
    return U(inter(circle(0, 0.0, 0.66), Y), ellipse(0, 0.0, 0.7, 0.1), seg(-0.3, -0.5, -0.48, -0.88, 0.08),
             seg(0.3, -0.5, 0.48, -0.88, 0.08), seg(0.66, 0.05, 0.9, 0.1, 0.07))


@sticker("dad", "grill", "Grill", ["#3A3F4B", "#1F232B", "#FF6A1C", "#FFE14A"], ink=1.0)
def _():
    grill = _grill_build()
    shade = _rim(_grill_build, -0.1, 0.1)
    fire = U(_flame(0.0, 0.1, 0.2, 0.78, 0.04), _flame(-0.38, 0.1, 0.15, 0.5, -0.04), _flame(0.38, 0.1, 0.15, 0.55, 0.05))
    glow = U(_flame(0.0, 0.1, 0.11, 0.46, 0.02), _flame(-0.38, 0.1, 0.08, 0.26), _flame(0.38, 0.1, 0.08, 0.3))
    return [grill, shade, fire, glow]


# ---- BBQ apron ----
def _apron_build():
    return U(poly([(-0.3, 0.6), (0.3, 0.6), (0.34, 0.2), (0.66, 0.12), (0.66, -0.88), (-0.66, -0.88), (-0.66, 0.12), (-0.34, 0.2)]))


@sticker("dad", "apron", "BBQ apron", ["#E3172F", "#A60F22", "#F4F1EA", "#FFFFFF"], ink=1.0)
def _():
    apron = _apron_build()
    shade = _rim(_apron_build, -0.1, 0.1)
    trim = U(arc(0, 0.62, 0.3, math.radians(10), math.radians(170), 0.07), box(0, -0.62, 0.42, 0.2, 0.04), seg(-0.66, 0.1, -0.9, -0.1, 0.06), seg(0.66, 0.1, 0.9, -0.1, 0.06))
    words = text("BBQ", 0, 0.0, 0.34, maxw=0.8)
    return [apron, shade, trim, words]


# ---- fishing rod and fish ----
def _fish_build():
    return U(oval(-0.4, -0.5, 0.44, 0.28, 0.2), poly([(0.0, -0.4), (0.3, -0.16), (0.3, -0.68)]))


@sticker("dad", "fishing", "Fishing", ["#3FB6F0", "#1B7DB8", "#9A6A3A", "#243044"], ink=1.0)
def _():
    fish = _fish_build()
    shade = _rim(_fish_build, -0.08, 0.1)
    rod = U(seg(0.8, -0.85, -0.55, 0.85, 0.11), circle(0.38, -0.34, 0.19), seg(0.28, -0.44, 0.7, -0.5, 0.09))
    line = U(polyline([(-0.55, 0.85), (-0.62, 0.2), (-0.5, -0.2)], 0.07), circle(-0.52, -0.45, 0.08))
    return [fish, shade, rod, line]


# ---- recliner ----
def _recliner_build():
    return U(box(0, 0.3, 0.48, 0.56, 0.22), box(-0.68, -0.08, 0.2, 0.4, 0.12), box(0.68, -0.08, 0.2, 0.4, 0.12), circle(-0.68, 0.14, 0.2), circle(0.68, 0.14, 0.2),
             box(0, -0.2, 0.5, 0.22, 0.08), poly([(-0.42, -0.36), (0.42, -0.36), (0.54, -0.74), (-0.54, -0.74)]))


@sticker("dad", "recliner", "Recliner", ["#8A4B2A", "#5E3018", "#E0A878", "#2A1A10"], ink=1.0)
def _():
    chair = _recliner_build()
    shade = _rim(_recliner_build, -0.1, 0.1)
    cushion = U(box(0, 0.34, 0.32, 0.36, 0.14), box(0, -0.15, 0.4, 0.1, 0.05), poly([(-0.3, -0.46), (0.3, -0.46), (0.4, -0.66), (-0.4, -0.66)]))
    feet = U(seg(0.9, -0.1, 0.9, -0.5, 0.06), circle(0.9, -0.5, 0.09), box(-0.66, -0.58, 0.1, 0.08, 0.02), box(0.66, -0.58, 0.1, 0.08, 0.02))
    return [chair, shade, cushion, feet]


# ---- hammer and wrench ----
@sticker("dad", "tools", "Hammer & wrench", ["#B8C2CF", "#7C8798", "#E85A1C", "#FFD34D"], ink=1.0)
def _():
    with rotated(0.7, 0, 0):
        head = U(box(0, 0.62, 0.36, 0.17, 0.04), box(-0.3, 0.6, 0.12, 0.1, 0.03))
        hhandle = box(0, -0.15, 0.09, 0.62, 0.04)
    with rotated(-0.7, 0, 0):
        wrench = U(ring(0, 0.64, 0.24, 0.1), box(0, -0.1, 0.1, 0.62, 0.04))
        wrench = sub(wrench, box(0, 0.88, 0.1, 0.18))
    metal = U(head, wrench)
    shade = _lowr(metal, 0.2)
    grip = hhandle
    with rotated(-0.7, 0, 0):
        cap = box(0, -0.62, 0.1, 0.1, 0.04)
    return [metal, shade, grip, cap]


# ---- golf ----
@sticker("dad", "golf", "Golf", ["#FFFFFF", "#C2CCDA", "#8A94A6", "#2E9E4F"], ink=1.0)
def _():
    ball = circle(0.42, -0.28, 0.32)
    shade = _lowr(ball, -0.38)
    club = U(seg(-0.75, 0.85, -0.1, -0.4, 0.1), poly([(-0.28, -0.34), (0.1, -0.52), (0.08, -0.72), (-0.38, -0.66)]))
    turf = U(box(0.0, -0.8, 0.9, 0.09, 0.04), poly([(-0.55, -0.7), (-0.5, -0.55), (-0.4, -0.7)]), poly([(0.55, -0.7), (0.6, -0.55), (0.7, -0.7)]),
            seg(-0.78, 0.78, -0.62, 0.5, 0.09))
    return [ball, shade, club, turf]


# ---- dad joke ----
def _joke_build():
    return U(box(0, 0.1, 0.84, 0.58, 0.28), poly([(-0.3, -0.35), (-0.1, -0.35), (-0.5, -0.82)]))


@sticker("dad", "joke", "Dad joke", ["#FFD34D", "#D9A21A", "#243044", "#E3172F"], ink=1.0)
def _():
    bubble = _joke_build()
    shade = _rim(_joke_build, -0.1, 0.1)
    words = text("HA!", 0.0, 0.1, 0.5, maxw=1.2)
    sparks = U(star(0.74, 0.62, 4, 0.2, 0.07), star(-0.74, -0.2, 4, 0.14, 0.05))
    return [bubble, shade, words, sparks]


# ---- BEST DAD ribbon ----
@sticker("dad", "ribbon", "Best Dad", ["#2F7BE0", "#1B4FA8", "#FFFFFF", "#FFC531"], ink=1.0)
def _():
    band = box(0, 0.18, 0.66, 0.56, 0.05)
    tails = U(poly([(-0.94, -0.06), (-0.5, -0.06), (-0.5, -0.62), (-0.94, -0.62), (-0.8, -0.34)]),
              poly([(0.94, -0.06), (0.5, -0.06), (0.5, -0.62), (0.94, -0.62), (0.8, -0.34)]))
    shade = sub(tails, band)
    words = U(text("BEST", 0, 0.38, 0.34, maxw=1.2), text("DAD", 0, -0.02, 0.34, maxw=1.0))
    trim = U(star(0, 0.82, 5, 0.14, 0.055), star(-0.75, -0.34, 5, 0.1, 0.04), star(0.75, -0.34, 5, 0.1, 0.04))
    return [band, shade, words, trim]


# ---- wristwatch ----
@sticker("dad", "watch", "Wristwatch", ["#8A5A2B", "#C9D2DE", "#FFFFFF", "#243044"], ink=1.0)
def _():
    strap = box(0, 0.0, 0.3, 0.92, 0.1)
    case = U(circle(0, 0.02, 0.56), box(0.58, 0.02, 0.07, 0.1, 0.02))
    face = circle(0, 0.02, 0.42)
    hands = U(seg(0, 0.02, 0, 0.32, 0.055), seg(0, 0.02, 0.2, -0.08, 0.055), circle(0, 0.02, 0.07), box(0, 0.36, 0.035, 0.05), box(0, -0.32, 0.035, 0.05),
              box(-0.34, 0.02, 0.05, 0.035), box(0.34, 0.02, 0.05, 0.035))
    return [strap, case, face, hands]


# ---- lawn mower ----
@sticker("dad", "mower", "Lawn mower", ["#E3172F", "#A60F22", "#3A3F4B", "#2E9E4F"], ink=1.0)
def _():
    deck = U(box(-0.15, -0.3, 0.62, 0.2, 0.1), circle(-0.3, -0.05, 0.28))
    shade = _lowr(deck, 0.0)
    gear = U(polyline([(0.4, -0.18), (0.58, 0.25), (0.74, 0.66)], 0.09), seg(0.5, 0.68, 0.84, 0.6, 0.1),
             sub(circle(-0.5, -0.56, 0.22), circle(-0.5, -0.56, 0.08)), sub(circle(0.22, -0.56, 0.22), circle(0.22, -0.56, 0.08)))
    grass = U(box(0, -0.88, 0.92, 0.06, 0.03), *[poly([(x - 0.07, -0.84), (x + 0.07, -0.84), (x + 0.02, -0.62)]) for x in (-0.8, -0.6, 0.55, 0.75)],
              circle(-0.82, -0.2, 0.06), circle(-0.72, 0.0, 0.05))
    return [deck, shade, gear, grass]


# ---- air guitar ----
def _guitar_build():
    return U(circle(-0.3, -0.35, 0.46), circle(-0.08, -0.04, 0.3), taper(0.0, 0.05, 0.78, 0.8, 0.08, 0.1))


def _hand(cx, cy, ang):
    """A fist with four finger knuckles: palm circle plus a row of bumps, turned ang."""
    with rotated(ang, cx, cy):
        return U(circle(cx, cy, 0.18), *[circle(cx - 0.18 + 0.12 * k, cy + 0.2, 0.075) for k in range(4)], circle(cx - 0.2, cy - 0.08, 0.07))


@sticker("dad", "airguitar", "Air guitar", ["#FF4F8B", "#FFC531", "#F2B88A", "#FFFFFF"], ink=1.0)
def _():
    outline = shell(_guitar_build(), 0.075)
    sparks = U(star(0.55, -0.1, 4, 0.22, 0.08), star(-0.72, 0.55, 4, 0.18, 0.07), star(0.2, -0.82, 4, 0.15, 0.055))
    hands = U(_hand(0.45, 0.45, -0.7), _hand(-0.28, -0.3, 0.3))
    return [outline, sparks, hands]


# ---- coffee thermos ----
def _thermos_build():
    return U(box(0, -0.15, 0.42, 0.66, 0.16), ring(0.5, 0.0, 0.26, 0.09))


@sticker("dad", "thermos", "Thermos", ["#A9BCD0", "#6E86A0", "#E3172F", "#3A4B5C"], ink=1.0)
def _():
    thermos = _thermos_build()
    shade = _rim(_thermos_build, -0.1, 0.0)
    cup = U(box(0, 0.66, 0.38, 0.2, 0.08), box(0, 0.5, 0.44, 0.05))
    band = U(box(0, -0.2, 0.42, 0.14), box(0, -0.58, 0.42, 0.05))
    return [thermos, shade, cup, band]


# ---- SUPER DAD badge ----
def _burst_build():
    return U(star(0, 0, 14, 0.94, 0.78), circle(0, 0, 0.8))


@sticker("dad", "superdad", "Super Dad", ["#2F7BE0", "#1B4FA8", "#FFC531", "#243044"], ink=1.0)
def _():
    burst = _burst_build()
    shade = _rim(_burst_build, -0.1, 0.1)
    seal = circle(0, 0, 0.62)
    words = text("DAD", 0, -0.02, 0.5, maxw=1.0)
    return [burst, shade, seal, words]
