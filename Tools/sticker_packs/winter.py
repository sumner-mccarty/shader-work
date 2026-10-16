PACK = ("winter", "Winter", False)
PRO_IDS = {"snowglobe", "fireplace", "tree", "gingerbread", "cocoa"}


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


def _leaf(cx, cy, ang, ln, wd, n=3):
    """A spiky holly leaf: base at (cx, cy), tip `ln` away along `ang`."""
    top, bot = [], []
    for k in range(2 * n + 1):
        t = k / (2.0 * n)
        w = wd * math.sin(math.pi * t) ** 0.8 * (1.0 if k % 2 == 1 else 0.55)
        top.append((ln * t, w))
        bot.append((ln * t, -w))
    pts = top + bot[::-1][1:-1]
    c, s = math.cos(ang), math.sin(ang)
    return poly([(cx + c * x - s * y, cy + s * x + c * y) for x, y in pts])


# ---- snow globe ----
@sticker("winter", "snowglobe", "Snow globe", ["#9FDCF2", "#B03A2E", "#FFFFFF", "#2E9E4F"], ink=1.0)
def _():
    glass = circle(0, 0.14, 0.7)
    base = U(box(0, -0.66, 0.5, 0.2, 0.08), poly([(-0.4, -0.5), (0.4, -0.5), (0.3, -0.36), (-0.3, -0.36)]))
    mound = inter(glass, oval(0, -0.45, 0.62, 0.2) + 0.0)
    flakes = U(circle(-0.4, 0.42, 0.065), circle(0.4, 0.46, 0.065), circle(0.0, 0.64, 0.06), circle(0.46, 0.08, 0.055))
    shine = arc(0, 0.14, 0.58, math.radians(110), math.radians(150), 0.04)
    snow = U(mound, flakes, shine)
    tree = U(poly([(-0.2, -0.3), (0.2, -0.3), (0, 0.05)]), poly([(-0.15, -0.08), (0.15, -0.08), (0, 0.3)]))
    return [glass, base, snow, tree]


# ---- mitten ----
def _mitten_build():
    return U(box(0.0, 0.12, 0.42, 0.62, 0.3), taper(-0.3, -0.02, -0.64, 0.24, 0.17, 0.14), box(0, -0.38, 0.42, 0.2, 0.06))


@sticker("winter", "mitten", "Mitten", ["#E3172F", "#A80E22", "#F4F1EA", "#FFFFFF"], ink=1.0)
def _():
    wool = _mitten_build()
    shade = _rim(_mitten_build, -0.1, 0.1)
    cuff = box(0, -0.52, 0.46, 0.2, 0.06)
    pattern = U(heart(0.02, 0.22, 0.2), circle(-0.2, -0.1, 0.05), circle(0.24, -0.08, 0.05))
    return [wool, shade, cuff, pattern]


# ---- snowman ----
def _snowman_build():
    return U(circle(0, -0.38, 0.5), circle(0, 0.38, 0.34), seg(-0.4, -0.22, -0.78, 0.04, 0.085), seg(0.4, -0.22, 0.78, 0.04, 0.085))


@sticker("winter", "snowman", "Snowman", ["#FFFFFF", "#BFD4EA", "#FF6B1A", "#1A1410"], ink=1.0)
def _():
    snow = _snowman_build()
    shade = _rim(_snowman_build, -0.1, 0.1)
    scarf = U(box(0, 0.06, 0.36, 0.09, 0.04), box(0.24, -0.1, 0.08, 0.17, 0.03), poly([(0.0, 0.4), (0.62, 0.34), (0.0, 0.3)]) - 0.0)
    coal = U(circle(-0.13, 0.46, 0.07), circle(0.13, 0.46, 0.07), circle(0, -0.22, 0.08), circle(0, -0.44, 0.08), circle(0, -0.66, 0.08))
    return [snow, shade, scarf, coal]


# ---- beanie ----
def _beanie_build():
    return U(inter(circle(0, -0.05, 0.72), -(Y + 0.2)), box(0, -0.34, 0.76, 0.2, 0.1), circle(0, 0.74, 0.2))


@sticker("winter", "beanie", "Beanie", ["#2F7BE0", "#1B4FA8", "#FFFFFF", "#FFE14A"], ink=1.0)
def _():
    hat = _beanie_build()
    shade = _rim(_beanie_build, -0.1, 0.1)
    cuff = U(box(0, -0.4, 0.78, 0.2, 0.1))
    pompom = circle(0, 0.74, 0.2)
    return [hat, shade, cuff, pompom]


# ---- cocoa ----
def _cocoa_build():
    return U(box(-0.08, -0.2, 0.5, 0.5, 0.14), arc(0.46, -0.16, 0.24, -math.pi / 2, math.pi / 2, 0.075))


@sticker("winter", "cocoa", "Cocoa", ["#E3172F", "#6B3A1E", "#FFFFFF", "#C9D4E3"], ink=1.0)
def _():
    mug = _cocoa_build()
    cocoa = oval(-0.08, 0.3, 0.46, 0.12)
    cream = U(box(-0.28, 0.4, 0.15, 0.12, 0.06), box(0.08, 0.44, 0.14, 0.12, 0.06), heart(-0.08, -0.14, 0.2))
    steam = U(brush([(-0.25, 0.6), (-0.08, 0.74), (-0.25, 0.88)], [0.07, 0.07, 0.06]), brush([(0.12, 0.62), (0.29, 0.76), (0.12, 0.9)], [0.07, 0.07, 0.06]))
    return [mug, cocoa, cream, steam]


# ---- tree ----
@sticker("winter", "tree", "Tree", ["#2E9E4F", "#1F6B34", "#E3172F", "#FFD400"], ink=1.0)
def _():
    tiers = U(poly([(-0.72, -0.4), (0.72, -0.4), (0, 0.12)]) - 0.06, poly([(-0.56, -0.02), (0.56, -0.02), (0, 0.5)]) - 0.06,
              poly([(-0.4, 0.34), (0.4, 0.34), (0, 0.86)]) - 0.06)
    pine = tiers
    shade = U(_lowr(tiers, 0.12), box(0, -0.62, 0.1, 0.16, 0.02))
    balls = U(circle(-0.34, -0.38, 0.1), circle(0.4, -0.36, 0.1), circle(0.12, -0.02, 0.09), circle(-0.2, 0.2, 0.08), circle(0.16, 0.5, 0.075))
    tinsel = U(polyline([(-0.46, -0.1), (-0.1, -0.2), (0.3, -0.12), (0.5, -0.2)], 0.04), polyline([(-0.3, 0.2), (0.0, 0.3), (0.25, 0.2)], 0.035))
    return [pine, shade, balls, tinsel]


# ---- candle ----
def _candle_build():
    return U(box(0, -0.18, 0.34, 0.5, 0.08), circle(-0.14, 0.34, 0.07), taper(0.22, 0.3, 0.22, 0.12, 0.07, 0.04))


@sticker("winter", "candle", "Holly candle", ["#E3172F", "#A80E22", "#2E9E4F", "#FFE14A"], ink=1.0)
def _():
    wax = _candle_build()
    shade = _rim(_candle_build, -0.1, 0.1)
    holly = U(_leaf(-0.1, -0.5, math.radians(165), 0.82, 0.2), _leaf(0.1, -0.5, math.radians(15), 0.82, 0.2), circle(0, -0.48, 0.12))
    flame = U(circle(0, 0.58, 0.13), taper(0, 0.58, 0.02, 0.96, 0.12, 0.0))
    return [wax, shade, holly, flame]


# ---- gift ----
@sticker("winter", "gift", "Gift box", ["#2F7BE0", "#1B4FA8", "#FFD400", "#FFFFFF"], ink=1.0)
def _():
    box_ = U(box(0, -0.3, 0.72, 0.5, 0.06), box(0, 0.26, 0.76, 0.16, 0.05))
    shade = _lowr(box_, 0.3)
    ribbon = U(box(0, -0.18, 0.12, 0.62, 0.02), circle(0, 0.5, 0.1),
               oval(-0.22, 0.6, 0.2, 0.12, math.radians(30)), oval(0.22, 0.6, 0.2, 0.12, math.radians(-30)))
    dots = U(circle(-0.45, -0.3, 0.08), circle(-0.45, -0.58, 0.08), circle(0.45, -0.3, 0.08), circle(0.45, -0.58, 0.08))
    return [box_, shade, ribbon, dots]


# ---- ornament ----
def _ornament_build():
    return circle(0, -0.1, 0.62)


@sticker("winter", "ornament", "Ornament", ["#E3172F", "#A80E22", "#FFD400", "#FFFFFF"], ink=1.0)
def _():
    ball = _ornament_build()
    shade = _rim(_ornament_build, -0.12, 0.12)
    cap = U(box(0, 0.58, 0.14, 0.08, 0.02), ring(0, 0.76, 0.1, 0.04))
    zigzag = inter(ball, polyline([(-0.7, -0.16), (-0.5, 0.0), (-0.3, -0.16), (-0.1, 0.0), (0.1, -0.16), (0.3, 0.0), (0.5, -0.16), (0.7, 0.0)], 0.06))
    return [ball, shade, cap, zigzag]


# ---- sled ----
@sticker("winter", "sled", "Sled", ["#E3172F", "#8A93A3", "#E9C27A", "#FFD400"], ink=1.0)
def _():
    seat = box(-0.02, 0.0, 0.76, 0.18, 0.08)
    runners = U(brush([(-0.88, -0.46), (-0.4, -0.58), (0.4, -0.58), (0.78, -0.5), (0.9, -0.28)], [0.09, 0.09, 0.09, 0.09, 0.09]),
                box(-0.5, -0.3, 0.07, 0.2), box(0.4, -0.3, 0.07, 0.2))
    slats = U(box(-0.42, 0.0, 0.16, 0.07, 0.03), box(0.2, 0.0, 0.16, 0.07, 0.03))
    rope = bezier((0.9, -0.28), (0.95, 0.5), (0.3, 0.5), 0.065)
    return [seat, runners, slats, rope]


# ---- ice skate ----
def _skate_build():
    return poly(spline([(-0.56, 0.84), (0.1, 0.84), (0.14, 0.2), (0.5, 0.02), (0.82, -0.1), (0.84, -0.46), (-0.56, -0.46)], n=8))


@sticker("winter", "skate", "Ice skate", ["#E3172F", "#A80E22", "#8A8F98", "#FFFFFF"], ink=1.0)
def _():
    boot = _skate_build()
    shade = _rim(_skate_build, -0.1, 0.1)
    blade = U(box(0.1, -0.7, 0.78, 0.07, 0.05), seg(-0.4, -0.46, -0.4, -0.66, 0.06), seg(0.62, -0.46, 0.62, -0.66, 0.06), circle(0.86, -0.62, 0.06))
    trim = U(box(-0.23, 0.82, 0.4, 0.09, 0.06), seg(-0.34, 0.5, 0.04, 0.38, 0.045), seg(-0.34, 0.24, 0.12, 0.12, 0.045), seg(-0.34, -0.02, 0.3, -0.06, 0.045))
    return [boot, shade, blade, trim]


# ---- fireplace ----
@sticker("winter", "fireplace", "Fireplace", ["#B5523B", "#3A1D14", "#FF9F1C", "#8A5A33"], ink=1.0)
def _():
    bricks = box(0, -0.12, 0.8, 0.72, 0.05)
    opening = U(inter(box(0, -0.3, 0.42, 0.48, 0.14), -(Y + 0.76)), box(0, 0.2, 0.8, 0.03), box(0, 0.44, 0.8, 0.03))
    flames = U(poly([(-0.3, -0.76), (-0.2, -0.42), (-0.06, -0.76)]), poly([(-0.14, -0.76), (0.0, -0.2), (0.14, -0.76)]), poly([(0.06, -0.76), (0.2, -0.42), (0.3, -0.76)]))
    mantle = U(box(0, 0.72, 0.92, 0.1, 0.04), box(-0.55, 0.52, 0.06, 0.1))
    return [bricks, opening, flames, mantle]


# ---- gingerbread ----
def _ginger_build():
    return smin(U(circle(0, 0.56, 0.3), box(0, 0.0, 0.3, 0.34, 0.1), seg(-0.3, 0.14, -0.66, 0.3, 0.13), seg(0.3, 0.14, 0.66, 0.3, 0.13),
                  seg(-0.16, -0.24, -0.36, -0.74, 0.14), seg(0.16, -0.24, 0.36, -0.74, 0.14)), circle(0, 0.3, 0.2), 0.1)


@sticker("winter", "gingerbread", "Gingerbread", ["#C98B4B", "#9A5F2B", "#FFFFFF", "#E3172F"], ink=1.0)
def _():
    cookie = _ginger_build()
    shade = _rim(_ginger_build, -0.1, 0.1)
    icing = U(circle(-0.1, 0.6, 0.05), circle(0.1, 0.6, 0.05), arc(0, 0.54, 0.12, math.radians(215), math.radians(325), 0.035),
              seg(-0.6, 0.27, -0.7, 0.32, 0.05), seg(0.6, 0.27, 0.7, 0.32, 0.05), seg(-0.4, -0.64, -0.3, -0.7, 0.05), seg(0.4, -0.64, 0.3, -0.7, 0.05))
    buttons = U(circle(0, 0.18, 0.07), circle(0, -0.04, 0.07), circle(0, -0.26, 0.07))
    return [cookie, shade, icing, buttons]


# ---- holly ----
@sticker("winter", "holly", "Holly", ["#2E9E4F", "#1F6B34", "#E3172F", "#FFFFFF"], ink=1.0)
def _():
    leaves = U(_leaf(0.0, -0.1, math.radians(145), 0.9, 0.26), _leaf(0.0, -0.1, math.radians(35), 0.9, 0.26))
    shade = _lowr(leaves, 0.1)
    berries = U(circle(-0.1, -0.06, 0.15), circle(0.14, -0.1, 0.15), circle(0.0, -0.3, 0.15))
    shine = U(circle(-0.16, 0.0, 0.04), circle(0.08, -0.04, 0.04), circle(-0.06, -0.24, 0.04))
    return [leaves, shade, berries, shine]


# ---- star topper ----
def _topper_build():
    return U(star(0, 0.2, 8, 0.74, 0.4) - 0.04, poly([(-0.3, -0.58), (0.3, -0.58), (0.0, -0.18)]) - 0.03)


@sticker("winter", "startopper", "Star topper", ["#FFC531", "#E09A12", "#2E9E4F", "#E3172F"], ink=1.0)
def _():
    star_ = _topper_build()
    facets = U(*[poly([(0.0, 0.2), (0.74 * math.cos(math.pi / 2 + k * math.pi / 4), 0.2 + 0.74 * math.sin(math.pi / 2 + k * math.pi / 4)),
                       (0.4 * math.cos(math.pi / 2 + k * math.pi / 4 - math.pi / 8), 0.2 + 0.4 * math.sin(math.pi / 2 + k * math.pi / 4 - math.pi / 8))]) for k in range(8)])
    tip = poly([(-0.3, -0.6), (0.3, -0.6), (0.0, -0.3)]) - 0.03
    bow = U(oval(-0.22, -0.46, 0.22, 0.13, 0.4), oval(0.22, -0.46, 0.22, 0.13, -0.4), circle(0, -0.46, 0.1))
    return [star_, facets, tip, bow]


# ---- BRRR ----
def _brrr_build():
    return box(0, 0.08, 0.9, 0.5, 0.14)


@sticker("winter", "brrr", "Brrr", ["#CFF1FF", "#8FD3F0", "#0F3E7A", "#4FC3F7"], ink=1.0)
def _():
    block = _brrr_build()
    shade = _rim(_brrr_build, -0.1, 0.1)
    word = text("BRRR", 0.0, 0.1, 0.62, maxw=1.7)
    icicles = U(poly([(-0.66, -0.4), (-0.34, -0.4), (-0.5, -0.88)]), poly([(0.0, -0.4), (0.3, -0.4), (0.15, -0.74)]),
                poly([(0.4, -0.4), (0.74, -0.4), (0.57, -0.86)]))
    return [block, shade, word, icicles]
