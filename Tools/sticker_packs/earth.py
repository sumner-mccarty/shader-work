PACK = ("earth", "Earth Day", False)
PRO_IDS = {"earth", "turbine", "bee", "whale", "tree", "solarsun"}

OCEAN, OCEAND = "#2FA8F0", "#0E4A86"
LEAF, LEAFD, LEAFL = "#4CC76A", "#237A3E", "#B8F0C4"
SUN, SUND = "#FFD23F", "#E0950A"
BARK, BARKD = "#9A6234", "#5C3518"
WHITE = "#FFFFFF"
INK = "#1A1410"


def _shift(make, dx, dy):
    """The shape `make()` draws, slid by (dx, dy)."""
    with rotated(0.0, 0.0, 0.0, dx, dy):
        return make()


def _rim(make, k=0.11):
    """Lower-right shade: the shape minus a copy of itself nudged up-left."""
    return sub(make(), _shift(make, -k, k))


def _leaf(cx, cy, hw, hh, ang=0.0):
    """A pointed leaf (a lens) hw long (half) and hh wide (half), turned by ang."""
    r = (hw * hw + hh * hh) / (2 * hh)
    with rotated(ang, cx, cy):
        return inter(circle(cx, cy - (r - hh), r), circle(cx, cy + (r - hh), r)) - 0.02


def _face(cx, cy, s=1.0):
    """Two oval eyes and a smile."""
    return U(oval(cx - 0.22 * s, cy + 0.08 * s, 0.075 * s, 0.12 * s), oval(cx + 0.22 * s, cy + 0.08 * s, 0.075 * s, 0.12 * s),
             arc(cx, cy + 0.02 * s, 0.3 * s, math.radians(210), math.radians(330), 0.05 * s))


# ---- smiling Earth ----
@sticker("earth", "earth", "Happy Earth", [OCEAN, LEAF, OCEAND, WHITE], ink=1.0)
def _():
    ocean = circle(0, 0, 0.86)
    land = inter(ocean, U(smin(oval(-0.5, 0.42, 0.3, 0.22, 0.5), oval(-0.18, 0.62, 0.26, 0.15), 0.12),
                          oval(-0.7, -0.08, 0.16, 0.26, -0.3),
                          smin(oval(0.56, -0.34, 0.28, 0.24, -0.5), oval(0.3, -0.62, 0.2, 0.14), 0.12),
                          oval(0.58, 0.42, 0.16, 0.2, 0.4), oval(-0.36, -0.62, 0.2, 0.12, 0.3)))
    shade = U(sub(ocean, circle(-0.11, 0.11, 0.85)), _face(0.0, -0.02, 1.05))
    shine = U(arc(0, 0, 0.7, math.radians(115), math.radians(150), 0.045), circle(-0.66, 0.2, 0.04),
              circle(-0.21, 0.15, 0.035), circle(0.25, 0.15, 0.035))
    return [ocean, land, shade, shine]


# ---- recycle loop ----
def _arrows():
    parts = []
    for k in range(3):
        a0 = math.radians(100 + 120 * k)
        a1 = a0 + math.radians(78)
        r = 0.5
        parts.append(arc(0, 0, r, a0, a1, 0.1, steps=24))
        tip = a1 + 0.42
        parts.append(poly([((r - 0.24) * math.cos(a1), (r - 0.24) * math.sin(a1)), ((r + 0.24) * math.cos(a1), (r + 0.24) * math.sin(a1)),
                           (r * math.cos(tip), r * math.sin(tip))]) - 0.02)
    return U(*parts)


@sticker("earth", "recycle", "Recycle", [LEAFL, "#7CCB8E", LEAFD, WHITE], ink=1.0)
def _():
    disc = circle(0, 0, 0.86)
    shade = sub(disc, circle(-0.1, 0.1, 0.85))
    arrows = _arrows()
    shine = U(arc(0, 0, 0.73, math.radians(118), math.radians(150), 0.04), circle(-0.66, 0.2, 0.04))
    return [disc, shade, arrows, shine]


# ---- seedling in hands ----
def _hands():
    return smin(smin(oval(-0.3, -0.46, 0.48, 0.26, 0.3), oval(0.3, -0.46, 0.48, 0.26, -0.3), 0.1),
                U(oval(-0.68, -0.18, 0.14, 0.24, -0.35), oval(0.68, -0.18, 0.14, 0.24, 0.35)), 0.12)


@sticker("earth", "seedling", "Seedling", [LEAF, "#F0A878", "#8A5A33", WHITE], ink=1.0)
def _():
    sprout = U(seg(0.0, -0.3, 0.0, 0.36, 0.055), _leaf(-0.28, 0.42, 0.3, 0.14, -0.55), _leaf(0.32, 0.56, 0.36, 0.17, 0.5))
    hands = _hands()
    soil = inter(oval(0.0, -0.28, 0.46, 0.22), -0.3 - Y)
    shade = U(_rim(_hands, 0.09), sub(soil, _hands()))
    shine = U(oval(-0.5, -0.36, 0.12, 0.04, 0.32), _leaf(0.24, 0.62, 0.12, 0.035, 0.5))
    return [sprout, hands, shade, shine]


# ---- tote bag ----
def _tote():
    return U(poly([(-0.64, 0.34), (0.64, 0.34), (0.72, -0.84), (-0.72, -0.84)]) - 0.04)


@sticker("earth", "tote", "Tote bag", ["#F2E2C0", "#C9A86E", LEAF, WHITE], ink=1.0)
def _():
    bag = U(_tote(), arc(-0.28, 0.36, 0.22, 0.0, math.pi, 0.065), arc(0.28, 0.36, 0.22, 0.0, math.pi, 0.065))
    shade = _rim(_tote, 0.1)
    print_ = U(_leaf(0.0, -0.26, 0.5, 0.26, 0.9), seg(-0.2, -0.66, -0.08, -0.5, 0.05))
    shine = U(seg(-0.5, 0.2, -0.54, -0.3, 0.04), seg(-0.06, -0.36, 0.14, 0.02, 0.04))
    return [bag, shade, print_, shine]


# ---- solar panel ----
_TL, _TR, _BR, _BL = (-0.6, 0.66), (0.82, 0.42), (0.62, -0.24), (-0.82, 0.02)


def _quad(u, v):
    """A point on the panel: u across (0..1), v down (0..1)."""
    tx, ty = _TL[0] + (_TR[0] - _TL[0]) * u, _TL[1] + (_TR[1] - _TL[1]) * u
    bx, by = _BL[0] + (_BR[0] - _BL[0]) * u, _BL[1] + (_BR[1] - _BL[1]) * u
    return (tx + (bx - tx) * v, ty + (by - ty) * v)


def _frame():
    return U(poly([_TL, _TR, _BR, _BL]) - 0.04, taper(0.0, 0.2, 0.0, -0.72, 0.13, 0.11), box(0.0, -0.78, 0.4, 0.09, 0.045))


@sticker("earth", "solar", "Solar panel", ["#C9CED6", "#7A808A", "#1F5FD0", WHITE], ink=1.0)
def _():
    frame = _frame()
    shade = _rim(_frame, 0.08)
    cells = []
    nu, nv, g = 4, 3, 0.035
    for i in range(nu):
        for j in range(nv):
            u0, u1, v0, v1 = i / nu + g, (i + 1) / nu - g, j / nv + g * 1.3, (j + 1) / nv - g * 1.3
            cells.append(poly([_quad(u0, v0), _quad(u1, v0), _quad(u1, v1), _quad(u0, v1)]))
    cells = U(*cells)
    shine = inter(cells, stripes(0.5, math.radians(-35), 0.14, 0.22))
    shine = inter(shine, -(X + 0.1 - (Y - 0.3)))
    return [frame, shade, cells, shine]


# ---- wind turbine ----
@sticker("earth", "turbine", "Wind turbine", ["#8FD0F2", "#4E9BD0", LEAF, WHITE], ink=1.0)
def _():
    sky = circle(0, 0, 0.86)
    shade = sub(sky, circle(-0.1, 0.1, 0.85))
    hill = inter(sky, circle(0.2, -1.42, 0.9))
    hub = (0.08, 0.26)
    blades = U(*[taper(hub[0], hub[1], hub[0] + 0.56 * math.cos(a), hub[1] + 0.56 * math.sin(a), 0.12, 0.05)
                 for a in (math.radians(100), math.radians(220), math.radians(340))])
    cloud = U(circle(-0.5, 0.36, 0.11), circle(-0.36, 0.42, 0.14), circle(-0.24, 0.34, 0.1), box(-0.37, 0.29, 0.14, 0.05, 0.05))
    turbine = U(taper(hub[0], -0.62, hub[0], hub[1], 0.11, 0.06), blades, circle(hub[0], hub[1], 0.12), cloud)
    return [sky, shade, hill, turbine]


# ---- bee on a daisy ----
_BEE = (0.18, 0.22, 0.3)          # body centre and tilt


def _beebody():
    with rotated(_BEE[2], _BEE[0], _BEE[1]):
        return U(oval(_BEE[0], _BEE[1], 0.44, 0.32), circle(_BEE[0] + 0.5, _BEE[1], 0.2))


_DAISY = (-0.3, -0.34, 0.22)


@sticker("earth", "bee", "Bee & daisy", [SUN, SUND, INK, WHITE], ink=1.0)
def _():
    cx, cy, r = _DAISY
    center = circle(cx, cy, r)
    body = U(_beebody(), center)
    shade = U(_rim(_beebody, 0.09), _rim(lambda: circle(cx, cy, r), 0.07))
    bx, by, ba = _BEE
    with rotated(ba, bx, by):
        stripes_ = inter(oval(bx, by, 0.44, 0.32), U(box(bx + 0.1, by, 0.075, 0.5), box(bx - 0.14, by, 0.075, 0.5)))
        head = circle(bx + 0.5, by, 0.2)
        tail = poly([(bx - 0.4, by + 0.07), (bx - 0.4, by - 0.07), (bx - 0.58, by)])
    stripes_ = U(stripes_, head, tail, seg(0.6, 0.5, 0.54, 0.72, 0.04), circle(0.54, 0.74, 0.07),
                 seg(0.72, 0.5, 0.8, 0.66, 0.04), circle(0.8, 0.68, 0.07))
    petals_ = sub(petals(cx, cy, 10, 0.38, 0.18, 0.11, 0.2), center)
    petals_ = sub(petals_, _beebody())
    wings = U(oval(-0.02, 0.58, 0.26, 0.15, 1.25), oval(0.28, 0.64, 0.24, 0.14, 1.7), petals_,
              circle(0.7, 0.42, 0.05), oval(0.04, 0.34, 0.12, 0.045, 0.3))
    return [body, shade, stripes_, wings]


# ---- leaf heart ----
def _lheart():
    return heart(0, 0.0, 0.92)


@sticker("earth", "leafheart", "Leaf heart", [LEAF, LEAFD, LEAFL, WHITE], ink=1.0)
def _():
    leaf = U(_lheart(), seg(0.0, -0.6, 0.12, -0.84, 0.05))
    shade = _rim(_lheart, 0.11)
    veins = U(bezier((0.0, 0.42), (0.04, -0.1), (0.0, -0.56), 0.045),
              *[seg(0.0, y, -0.34 + 0.08 * k, y + 0.22, 0.035) for k, y in enumerate((0.2, -0.06, -0.3))],
              *[seg(0.0, y, 0.34 - 0.08 * k, y + 0.22, 0.035) for k, y in enumerate((0.2, -0.06, -0.3))])
    veins = inter(veins, _lheart() + 0.08)
    shine = inter(U(arc(-0.3, 0.3, 0.3, math.radians(105), math.radians(165), 0.05), circle(-0.56, 0.12, 0.045)), _lheart() + 0.06)
    return [leaf, shade, veins, shine]


# ---- compost bin ----
def _bin():
    return poly([(-0.62, 0.26), (0.62, 0.26), (0.52, -0.84), (-0.52, -0.84)]) - 0.04


@sticker("earth", "compost", "Compost bin", [LEAF, LEAFD, "#FF9F1C", WHITE], ink=1.0)
def _():
    bin_ = U(_bin(), box(0.0, 0.34, 0.72, 0.1, 0.05, 0.12))
    shade = U(_rim(_bin, 0.1), box(0.0, 0.34, 0.72, 0.1, 0.05, 0.12))
    scraps = U(poly([(-0.42, 0.42), (-0.2, 0.42), (-0.36, 0.86)]) - 0.03,                 # a carrot
               oval(0.14, 0.56, 0.2, 0.17), seg(0.14, 0.7, 0.18, 0.84, 0.035),            # an apple core
               _leaf(0.48, 0.66, 0.22, 0.1, 0.6))
    shine = U(_leaf(0.0, -0.3, 0.3, 0.15, 0.8), seg(-0.46, 0.08, -0.4, -0.52, 0.04))
    return [bin_, shade, scraps, shine]


# ---- bicycle ----
def _frame_bike():
    return U(poly([(-0.46, -0.3), (-0.1, 0.18), (0.0, -0.3)]) - 0.07, poly([(-0.1, 0.18), (0.3, 0.18), (0.0, -0.3)]) - 0.07,
             seg(0.3, 0.18, 0.46, -0.3, 0.08), seg(0.3, 0.18, 0.36, 0.42, 0.075))


@sticker("earth", "bike", "Bicycle", ["#2B2E33", LEAF, LEAFD, WHITE], ink=1.0)
def _():
    tires = U(ring(-0.46, -0.3, 0.32, 0.12), ring(0.46, -0.3, 0.32, 0.12), box(-0.14, 0.34, 0.2, 0.08, 0.07),
              seg(0.24, 0.48, 0.52, 0.42, 0.07))
    frame = _frame_bike()
    shade = U(_rim(_frame_bike, 0.07), circle(-0.46, -0.3, 0.09), circle(0.46, -0.3, 0.09), circle(0.0, -0.3, 0.11))
    shine = U(arc(-0.46, -0.3, 0.32, math.radians(110), math.radians(160), 0.035), arc(0.46, -0.3, 0.32, math.radians(110), math.radians(160), 0.035),
              seg(-0.3, -0.12, -0.16, 0.06, 0.035))
    return [tires, frame, shade, shine]


# ---- raindrop with a leaf ----
def _drop():
    return smin(circle(0.0, -0.26, 0.58), poly([(-0.36, 0.1), (0.36, 0.1), (0.0, 0.78)]), 0.12)


@sticker("earth", "raindrop", "Raindrop", [OCEAN, LEAF, OCEAND, WHITE], ink=1.0)
def _():
    drop = _drop()
    leaf = U(_leaf(0.36, 0.7, 0.24, 0.11, 0.5), seg(0.04, 0.72, 0.18, 0.62, 0.035))
    shade = U(_rim(_drop, 0.11), _face(0.0, -0.32, 0.9))
    shine = U(arc(0.0, -0.26, 0.44, math.radians(125), math.radians(165), 0.05), circle(-0.3, 0.12, 0.045))
    return [drop, leaf, shade, shine]


# ---- tree with roots ----
def _canopy():
    return U(circle(0.0, 0.42, 0.42), circle(-0.42, 0.3, 0.32), circle(0.42, 0.3, 0.32), circle(-0.24, 0.0, 0.3), circle(0.26, 0.0, 0.3))


@sticker("earth", "tree", "Rooted tree", [LEAF, LEAFD, BARK, WHITE], ink=1.0)
def _():
    canopy = _canopy()
    shade = _rim(_canopy, 0.12)
    wood = U(taper(0.0, -0.5, 0.0, 0.1, 0.13, 0.09),
             brush([(0.0, -0.46), (-0.34, -0.62), (-0.74, -0.68)], [0.09, 0.06, 0.035]),
             brush([(0.0, -0.46), (0.34, -0.62), (0.74, -0.68)], [0.09, 0.06, 0.035]),
             brush([(-0.04, -0.5), (-0.14, -0.72), (-0.3, -0.86)], [0.07, 0.05, 0.03]),
             brush([(0.04, -0.5), (0.14, -0.72), (0.3, -0.86)], [0.07, 0.05, 0.03]))
    shine = U(arc(0.0, 0.42, 0.3, math.radians(110), math.radians(165), 0.045), circle(-0.56, 0.36, 0.045), circle(-0.32, 0.02, 0.04))
    return [canopy, shade, wood, shine]


# ---- whale heart ----
def _whale():
    body = smin(oval(-0.14, -0.28, 0.66, 0.38), brush([(0.34, -0.2), (0.54, 0.0), (0.6, 0.16)], [0.18, 0.09, 0.055]), 0.12)
    flukes = U(_leaf(0.48, 0.28, 0.18, 0.075, 2.2), _leaf(0.72, 0.22, 0.18, 0.075, 0.6))
    return U(body, flukes)


@sticker("earth", "whale", "Whale heart", ["#3B7BE0", "#1C3F86", "#FF5C8A", WHITE], ink=1.0)
def _():
    whale = _whale()
    shade = U(_rim(_whale, 0.1), circle(-0.5, -0.2, 0.065), arc(-0.6, -0.12, 0.36, math.radians(235), math.radians(300), 0.035))
    heart_ = U(heart(-0.26, 0.56, 0.48), seg(-0.26, 0.1, -0.26, 0.3, 0.05), circle(-0.56, 0.3, 0.05), circle(0.04, 0.3, 0.05))
    shine = U(oval(-0.4, 0.0, 0.14, 0.045, 0.2), circle(-0.48, -0.17, 0.025), oval(-0.38, 0.66, 0.06, 0.03, 0.6))
    return [whale, shade, heart_, shine]


# ---- light bulb with a leaf ----
def _glass():
    return smin(circle(0.0, 0.2, 0.48), box(0.0, -0.3, 0.24, 0.14, 0.04), 0.2)


@sticker("earth", "bulb", "Leaf bulb", [SUN, SUND, LEAF, WHITE], ink=1.0)
def _():
    glass = U(_glass(), *[taper(0.6 * math.cos(a), 0.2 + 0.6 * math.sin(a), 0.74 * math.cos(a), 0.2 + 0.74 * math.sin(a), 0.06, 0.045)
                          for a in (math.radians(15), math.radians(55), math.radians(125), math.radians(165))])
    shade = _rim(_glass, 0.1)
    leaf = U(_leaf(0.04, 0.24, 0.28, 0.14, 1.0), seg(0.0, -0.34, -0.02, 0.02, 0.04),
             box(0.0, -0.5, 0.25, 0.08, 0.04), box(0.0, -0.66, 0.21, 0.07, 0.035), box(0.0, -0.8, 0.1, 0.06, 0.04))
    shine = U(arc(0.0, 0.2, 0.36, math.radians(120), math.radians(170), 0.05), circle(-0.28, -0.02, 0.04))
    return [glass, shade, leaf, shine]


# ---- solar sun: a sun with a panel face ----
def _sunrays():
    return U(star(0, 0, 12, 0.86, 0.64, 0.0) - 0.02, circle(0, 0, 0.64))


@sticker("earth", "solarsun", "Solar sun", [SUN, SUND, "#1F5FD0", WHITE], ink=1.0)
def _():
    sun = _sunrays()
    shade = _rim(_sunrays, 0.11)
    disc = circle(0, 0, 0.5)
    panel = inter(disc, U(*[box(x, y, 0.095, 0.095, 0.02) for x in (-0.37, -0.12, 0.12, 0.37) for y in (-0.37, -0.12, 0.12, 0.37)]))
    shine = U(inter(panel, abs(X - Y + 0.36) * 0.7071 - 0.06), arc(0, 0, 0.58, math.radians(115), math.radians(155), 0.04))
    return [sun, shade, panel, shine]


# ---- GREEN ----
def _pill():
    return box(0.0, 0.0, 0.9, 0.5, 0.4)


@sticker("earth", "green", "GREEN", ["#1F6B34", WHITE, "#9BE8A8", "#B8F0C4"], ink=1.0)
def _():
    back = _pill()
    word = text("GREEN", 0.0, 0.0, 0.9, stretch=0.5, maxw=1.5) - 0.025
    shade = sub(word, text("GREEN", -0.035, 0.035, 0.9, stretch=0.5, maxw=1.5) - 0.025)
    shine = U(inter(word, box(0.0, 0.17, 1.0, 0.035)), seg(-0.62, 0.41, -0.3, 0.41, 0.035))
    return [back, word, shade, shine]
