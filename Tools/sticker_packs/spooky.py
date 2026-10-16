PACK = ("spooky", "Halloween", False)
PRO_IDS = {"hauntedhouse", "cauldron", "moonbat", "boo", "web"}


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


# ---- pumpkin ----
def _pumpkin_build():
    return U(oval(-0.4, -0.12, 0.44, 0.58), oval(0.4, -0.12, 0.44, 0.58), oval(0, -0.1, 0.5, 0.64))


@sticker("spooky", "pumpkin", "Pumpkin", ["#FF8A1F", "#D9560B", "#4FA83D", "#FFE14A"], ink=1.0)
def _():
    body = _pumpkin_build()
    shade = _rim(_pumpkin_build, -0.12, 0.1)
    stem = U(taper(0.0, 0.5, 0.06, 0.78, 0.11, 0.08), taper(0.06, 0.78, 0.2, 0.86, 0.08, 0.05))
    face = U(poly([(-0.42, 0.04), (-0.14, 0.04), (-0.28, 0.3)]), poly([(0.14, 0.04), (0.42, 0.04), (0.28, 0.3)]),
             poly([(-0.46, -0.28), (-0.28, -0.4), (-0.16, -0.28), (0.0, -0.42), (0.16, -0.28), (0.28, -0.4), (0.46, -0.28),
                   (0.34, -0.52), (0.0, -0.58), (-0.34, -0.52)]))
    return [body, shade, stem, face]


# ---- bat ----
def _bat_parts(cx, cy, s):
    def pts(sign):
        base = [(-0.1, 0.3), (-0.5, 0.66), (-0.96, 0.46), (-0.74, 0.22), (-0.7, 0.0), (-0.46, 0.12), (-0.34, -0.14), (-0.12, -0.1)]
        return [(cx + sign * -x * s if False else cx + (x if sign < 0 else -x) * s, cy + y * s) for x, y in base]
    wings = U(poly(pts(-1)), poly(pts(1)))
    body = U(oval(cx, cy + 0.0 * s, 0.2 * s, 0.34 * s), circle(cx, cy + 0.32 * s, 0.18 * s),
             poly([(cx - 0.17 * s, cy + 0.4 * s), (cx - 0.2 * s, cy + 0.66 * s), (cx - 0.04 * s, cy + 0.5 * s)]),
             poly([(cx + 0.17 * s, cy + 0.4 * s), (cx + 0.2 * s, cy + 0.66 * s), (cx + 0.04 * s, cy + 0.5 * s)]))
    return wings, body


@sticker("spooky", "bat", "Bat", ["#7B4FC0", "#2B1B3F", "#FFE14A", "#FFFFFF"], ink=1.0)
def _():
    wings, body = _bat_parts(0.0, -0.1, 1.0)
    eyes = U(circle(-0.07, 0.22, 0.05), circle(0.07, 0.22, 0.05))
    fangs = U(poly([(-0.07, 0.1), (-0.02, 0.1), (-0.045, 0.02)]), poly([(0.02, 0.1), (0.07, 0.1), (0.045, 0.02)]))
    return [wings, body, eyes, fangs]


# ---- witch hat ----
def _witchhat_build():
    cone = poly([(-0.5, -0.3), (0.5, -0.3), (0.2, 0.45), (-0.2, 0.45)])
    tip = brush([(0.0, 0.35), (0.04, 0.62), (0.3, 0.8), (0.5, 0.7)], [0.2, 0.15, 0.11, 0.07])
    return U(smin(cone, tip, 0.1), oval(0, -0.4, 0.92, 0.2))


@sticker("spooky", "witchhat", "Witch hat", ["#7B3FD0", "#4B1F96", "#FF8A1F", "#FFE14A"], ink=1.0)
def _():
    hat = _witchhat_build()
    shade = _rim(_witchhat_build, -0.1, 0.1)
    band = inter(hat, box(0, -0.2, 0.7, 0.1))
    buckle = sub(box(0.0, -0.2, 0.14, 0.14, 0.03), box(0.0, -0.2, 0.07, 0.07, 0.01))
    return [hat, shade, band, buckle]


# ---- cauldron ----
@sticker("spooky", "cauldron", "Cauldron", ["#3C3A46", "#7EE05A", "#C9F7A8", "#FF8A1F"], ink=1.0)
def _():
    pot = U(inter(circle(0, -0.05, 0.68), Y - 0.28), box(0, 0.28, 0.7, 0.1, 0.08), circle(-0.46, -0.66, 0.12), circle(0.46, -0.66, 0.12),
            ring(-0.74, 0.18, 0.1, 0.045), ring(0.74, 0.18, 0.1, 0.045))
    liquid = oval(0, 0.3, 0.56, 0.12)
    bubbles = U(circle(-0.22, 0.52, 0.14), circle(0.14, 0.62, 0.1), circle(0.32, 0.46, 0.07), circle(-0.04, 0.8, 0.06))
    fire = U(poly([(-0.3, -0.8), (-0.18, -0.58), (-0.06, -0.8)]), poly([(-0.12, -0.8), (0.0, -0.5), (0.12, -0.8)]),
             poly([(0.06, -0.8), (0.18, -0.58), (0.3, -0.8)]))
    return [pot, liquid, bubbles, fire]


# ---- candy corn ----
def _candycorn_build():
    return poly([(-0.2, 0.86), (0.2, 0.86), (0.7, -0.62), (-0.7, -0.62)]) - 0.1


@sticker("spooky", "candycorn", "Candy corn", ["#FFD23F", "#FF8A1F", "#FFFFFF", "#D99A00"], ink=1.0)
def _():
    base = _candycorn_build()
    middle = inter(base, np.maximum(-0.12 - Y, Y - 0.34))
    tip = inter(base, 0.34 - Y)
    shade = _lowr(base, 0.3)
    return [base, middle, tip, shade]


# ---- ghost ----
def _ghost_build():
    return U(circle(0, 0.3, 0.5), brush([(0, 0.2), (-0.06, -0.3), (0.2, -0.64), (0.58, -0.72)], [0.5, 0.42, 0.28, 0.05]),
             seg(-0.42, 0.04, -0.76, 0.36, 0.11), seg(0.42, 0.04, 0.76, 0.36, 0.11))


@sticker("spooky", "ghost", "Boo ghost", ["#F4F1FF", "#C6BDEB", "#2B1B3F", "#FF9AB8"], ink=1.0)
def _():
    body = _ghost_build()
    shade = _rim(_ghost_build, -0.1, 0.1)
    face = U(oval(-0.2, 0.34, 0.07, 0.12), oval(0.2, 0.34, 0.07, 0.12), oval(0.0, 0.06, 0.1, 0.13))
    cheeks = U(circle(-0.33, 0.14, 0.07), circle(0.33, 0.14, 0.07))
    return [body, shade, face, cheeks]


# ---- black cat ----
def _blackcat_build():
    return U(oval(0, -0.48, 0.48, 0.44), circle(0, 0.16, 0.4),
             poly([(-0.4, 0.3), (-0.42, 0.82), (-0.06, 0.5)]), poly([(0.4, 0.3), (0.42, 0.82), (0.06, 0.5)]),
             brush([(0.38, -0.7), (0.8, -0.62), (0.88, -0.2), (0.66, 0.1)], [0.11, 0.1, 0.09, 0.06]))


@sticker("spooky", "blackcat", "Black cat", ["#6A5494", "#3F3060", "#FFE14A", "#FF6B1A"], ink=1.0)
def _():
    fur = _blackcat_build()
    shade = _rim(_blackcat_build, -0.1, 0.1)
    eyes = sub(U(oval(-0.17, 0.2, 0.13, 0.16), oval(0.17, 0.2, 0.13, 0.16)), U(box(-0.17, 0.2, 0.03, 0.14), box(0.17, 0.2, 0.03, 0.14)))
    collar = U(box(0, -0.15, 0.34, 0.09, 0.04), circle(0, -0.3, 0.11))
    return [fur, shade, eyes, collar]


# ---- tombstone ----
def _tombstone_build():
    return U(box(0, -0.12, 0.54, 0.7, 0.06), circle(0, 0.38, 0.54))


@sticker("spooky", "tombstone", "Tombstone", ["#A9B0BC", "#7C8494", "#2B2F3A", "#7A4B26"], ink=1.0)
def _():
    stone = _tombstone_build()
    shade = _rim(_tombstone_build, -0.1, 0.1)
    rip = text("RIP", 0.0, 0.14, 0.4, maxw=0.9)
    dirt = U(ellipse(0, -0.82, 0.66, 0.15), circle(-0.4, -0.76, 0.12), circle(0.4, -0.76, 0.12))
    return [stone, shade, rip, dirt]


# ---- spider web ----
@sticker("spooky", "web", "Spider web", ["#3A2166", "#FFFFFF", "#9FE8FF", "#241344"], ink=1.0)
def _():
    back = circle(0, 0, 0.88)
    spokes = U(*[seg(0, 0, 0.84 * math.cos(k * math.pi / 4), 0.84 * math.sin(k * math.pi / 4), 0.045) for k in range(8)])
    rings = U(*[shell(regpoly(0, 0, 8, r, ang=0.0), 0.04) for r in (0.28, 0.52, 0.76)])
    strands = U(spokes, rings)
    dew = U(circle(0.3, 0.34, 0.09), circle(-0.46, -0.3, 0.08), circle(0.58, -0.4, 0.08))
    shade = _lowr(back, 0.3)
    return [back, strands, dew, shade]


# ---- spider ----
def _spider_legs():
    legs = []
    for sgn in (-1, 1):
        for (x0, y0, x1, y1) in [(0.2, 0.2, 0.84, 0.5), (0.28, 0.04, 0.9, 0.04), (0.28, -0.12, 0.86, -0.46), (0.2, -0.26, 0.6, -0.84)]:
            legs.append(seg(sgn * x0, y0, sgn * x1, y1, 0.065))
    return U(*legs)


@sticker("spooky", "spider", "Spider", ["#2B1B3F", "#6B4A9A", "#FFFFFF", "#E3172F"], ink=1.0)
def _():
    body = U(circle(0, -0.12, 0.36), circle(0, 0.26, 0.24))
    legs = _spider_legs()
    eyes = U(circle(-0.09, 0.3, 0.075), circle(0.09, 0.3, 0.075))
    mark = U(poly([(-0.12, -0.0), (0.12, -0.0), (0.0, -0.12)]), poly([(-0.12, -0.26), (0.12, -0.26), (0.0, -0.14)]))
    return [body, legs, eyes, mark]


# ---- full moon with bat ----
@sticker("spooky", "moonbat", "Moon and bat", ["#FFE9A0", "#E8C766", "#5B3B8C", "#2B1B3F"], ink=1.0)
def _():
    moon = circle(0, 0, 0.86)
    craters = U(circle(-0.42, 0.4, 0.15), circle(0.46, 0.46, 0.1), circle(0.52, -0.34, 0.17), circle(-0.6, -0.1, 0.1))
    cloud = U(circle(-0.5, -0.5, 0.2), circle(-0.2, -0.56, 0.25), circle(0.2, -0.52, 0.2), circle(0.5, -0.58, 0.16), box(0, -0.7, 0.62, 0.12, 0.08))
    wings, body = _bat_parts(0.05, 0.02, 0.62)
    bat = U(wings, body)
    return [moon, craters, cloud, bat]


# ---- haunted house ----
@sticker("spooky", "hauntedhouse", "Haunted house", ["#6B4A9A", "#2B1B3F", "#FFE14A", "#3E6B3A"], ink=1.0)
def _():
    walls = U(box(-0.12, -0.38, 0.64, 0.38, 0.03), box(0.52, -0.12, 0.2, 0.62, 0.03))
    roof = U(poly([(-0.84, 0.02), (-0.12, 0.54), (0.5, 0.02)]), poly([(0.26, 0.5), (0.52, 0.92), (0.78, 0.5)]),
             box(-0.12, 0.02, 0.62, 0.04))
    lights = U(box(-0.5, -0.3, 0.1, 0.13, 0.03), box(0.08, -0.3, 0.1, 0.13, 0.03), circle(0.52, 0.18, 0.09),
               box(0.52, -0.38, 0.1, 0.2, 0.05))
    ground = U(ellipse(0, -0.8, 0.95, 0.14), *[box(-0.9 + 0.2 * k, -0.7, 0.045, 0.1, 0.01) for k in (0, 1)])
    return [walls, roof, lights, ground]


# ---- bone ----
def _bone_build():
    with rotated(0.45):
        return U(box(0, 0, 0.5, 0.2, 0.06), circle(-0.62, 0.2, 0.24), circle(-0.62, -0.2, 0.24), circle(0.62, 0.2, 0.24), circle(0.62, -0.2, 0.24))


@sticker("spooky", "bone", "Bone", ["#F4F1EA", "#C9C3B6", "#FFFFFF", "#6B6558"], ink=1.0)
def _():
    bone = _bone_build()
    shade = _rim(_bone_build, -0.1, 0.1)
    with rotated(0.45):
        shine = U(seg(-0.34, 0.1, 0.1, 0.1, 0.05), circle(-0.66, 0.26, 0.07))
        crack = polyline([(0.2, 0.2), (0.3, 0.04), (0.18, -0.06), (0.28, -0.2)], 0.04)
    return [bone, shade, shine, crack]


# ---- poison bottle ----
@sticker("spooky", "poison", "Poison bottle", ["#CFE9FF", "#9B4DE8", "#C98B4B", "#F4F1EA"], ink=1.0)
def _():
    glass = U(box(0, -0.2, 0.44, 0.58, 0.14), box(0, 0.5, 0.17, 0.2, 0.03), box(0, 0.7, 0.21, 0.06, 0.02))
    liquid = inter(box(0, -0.2, 0.4, 0.54, 0.12), Y - 0.3)
    cork = box(0, 0.86, 0.14, 0.1, 0.04)
    skull = sub(U(circle(0, -0.1, 0.15), box(0, -0.27, 0.08, 0.07, 0.02)), U(circle(-0.06, -0.1, 0.04), circle(0.06, -0.1, 0.04)))
    label = sub(box(0, -0.2, 0.34, 0.32, 0.05), skull)
    return [glass, liquid, cork, label]


# ---- zombie hand ----
def _zombiehand_build():
    return U(taper(0.0, -0.72, 0.0, -0.1, 0.2, 0.18), box(0.0, 0.04, 0.29, 0.25, 0.1),
             taper(-0.2, 0.2, -0.27, 0.64, 0.085, 0.07), taper(-0.07, 0.24, -0.06, 0.72, 0.085, 0.07),
             taper(0.07, 0.24, 0.1, 0.74, 0.085, 0.07), taper(0.2, 0.2, 0.3, 0.58, 0.085, 0.07),
             taper(-0.26, -0.02, -0.52, 0.2, 0.09, 0.065))


@sticker("spooky", "zombiehand", "Zombie hand", ["#8BC34A", "#5F9A2B", "#6B5B4B", "#7A4B26"], ink=1.0)
def _():
    skin = _zombiehand_build()
    shade = _rim(_zombiehand_build, -0.1, 0.1)
    sleeve = poly([(-0.3, -0.34), (0.3, -0.34), (0.36, -0.66), (0.24, -0.56), (0.12, -0.68), (0.0, -0.56), (-0.12, -0.68), (-0.24, -0.54), (-0.36, -0.66)])
    dirt = U(ellipse(0, -0.8, 0.56, 0.14), circle(-0.3, -0.72, 0.12), circle(0.3, -0.72, 0.11))
    return [skin, shade, sleeve, dirt]


# ---- BOO ----
def _boo_build():
    return U(box(0, 0.04, 0.9, 0.5, 0.36), poly([(-0.5, -0.3), (-0.2, -0.3), (-0.58, -0.7)]))


@sticker("spooky", "boo", "Boo", ["#7B3FD0", "#4B1F96", "#FFE14A", "#7EE05A"], ink=1.0)
def _():
    bubble = _boo_build()
    shade = _rim(_boo_build, -0.1, 0.1)
    word = text("BOO", 0.0, -0.1, 0.5, maxw=1.5)
    slime = U(box(0, 0.5, 0.86, 0.1, 0.06), taper(-0.5, 0.5, -0.5, 0.26, 0.09, 0.07), circle(-0.5, 0.24, 0.07),
              taper(0.16, 0.5, 0.16, 0.3, 0.08, 0.06), circle(0.16, 0.28, 0.06), taper(0.62, 0.5, 0.62, 0.24, 0.09, 0.07), circle(0.62, 0.22, 0.07))
    return [bubble, shade, word, slime]
