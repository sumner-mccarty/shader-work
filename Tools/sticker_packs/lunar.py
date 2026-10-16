PACK = ("lunar", "Lunar New Year", False)
PRO_IDS = {"dragon", "lion", "lanterns", "firecrackers", "ingot", "drum"}


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


# ---- red lanterns ----
def _lanterns_build():
    return U(oval(-0.4, 0.02, 0.36, 0.34), oval(0.42, -0.06, 0.32, 0.3))


@sticker("lunar", "lanterns", "Red lanterns", ["#E3172F", "#A80E22", "#FFC531", "#FF7A66"], ink=1.0)
def _():
    body = _lanterns_build()
    shade = _rim(_lanterns_build, -0.1, 0.1)
    trim = U(box(-0.4, 0.4, 0.15, 0.06, 0.02), box(-0.4, -0.36, 0.15, 0.06, 0.02), box(0.42, 0.29, 0.13, 0.06, 0.02),
             box(0.42, -0.41, 0.13, 0.06, 0.02), seg(-0.4, 0.46, -0.4, 0.8, 0.06), seg(0.42, 0.35, 0.42, 0.8, 0.06),
             seg(-0.4, 0.8, 0.42, 0.8, 0.06), seg(-0.4, -0.4, -0.4, -0.64, 0.06), seg(0.42, -0.46, 0.42, -0.7, 0.06),
             circle(-0.4, -0.7, 0.09), circle(0.42, -0.76, 0.09))
    ribs = U(oval(-0.4, 0.02, 0.1, 0.3), oval(0.42, -0.06, 0.09, 0.27))
    return [body, shade, trim, ribs]


# ---- red envelope ----
@sticker("lunar", "envelope", "Red envelope", ["#E3172F", "#A80E22", "#FFC531", "#FFF4C7"], ink=1.0)
def _():
    paper = box(0, 0, 0.62, 0.84, 0.1)
    flap = inter(paper, poly([(-0.7, 0.9), (0.7, 0.9), (0.0, 0.1)]))
    seal = U(circle(0, 0.12, 0.24), box(0, -0.52, 0.4, 0.09, 0.04))
    shine = U(box(-0.46, -0.1, 0.05, 0.3, 0.02), circle(0.42, -0.2, 0.05))
    return [paper, flap, seal, shine]


# ---- dragon head ----
def _dragon_build():
    return U(oval(-0.1, 0.0, 0.5, 0.42), oval(0.42, 0.06, 0.42, 0.22, -0.1), oval(0.38, -0.3, 0.38, 0.14, 0.1), circle(0.74, 0.14, 0.14))


@sticker("lunar", "dragon", "Dragon head", ["#E3172F", "#FFC531", "#FFFFFF", "#8A0F22"], ink=1.0)
def _():
    head = _dragon_build()
    gold = U(brush([(-0.2, 0.36), (-0.5, 0.62), (-0.78, 0.5)], [0.13, 0.1, 0.05]),
             poly([(-0.5, 0.22), (-0.84, 0.4), (-0.52, 0.0)]), poly([(-0.56, -0.04), (-0.86, -0.1), (-0.5, -0.28)]),
             poly([(-0.44, -0.3), (-0.76, -0.5), (-0.3, -0.44)]),
             brush([(0.74, -0.2), (0.86, -0.42), (0.7, -0.68)], [0.1, 0.1, 0.08]))
    whites = U(circle(-0.02, 0.16, 0.2), poly([(0.3, -0.14), (0.42, -0.14), (0.36, -0.28)]), poly([(0.5, -0.14), (0.62, -0.14), (0.56, -0.28)]))
    dark = U(_rim(_dragon_build, -0.1, 0.1), circle(0.02, 0.14, 0.1), circle(0.78, 0.2, 0.06), seg(0.08, -0.1, 0.74, -0.06, 0.04))
    return [head, gold, whites, dark]


# ---- firecracker string ----
_FC = ((-0.26, 0.66, 0.3), (0.26, 0.36, -0.3), (-0.26, 0.06, 0.3), (0.26, -0.24, -0.3), (-0.26, -0.54, 0.3))


def _crackers_build():
    return U(*[box(x, y, 0.25, 0.18, 0.05, a) for (x, y, a) in _FC])


@sticker("lunar", "firecrackers", "Firecrackers", ["#E3172F", "#A80E22", "#FFC531", "#7A3B00"], ink=1.0)
def _():
    crackers = _crackers_build()
    shade = _rim(_crackers_build, -0.07, 0.07)
    bands = U(*[box(x * 0.55, y, 0.05, 0.16, 0.02, a) for (x, y, a) in _FC], star(0.5, -0.66, 4, 0.22, 0.08))
    cord = U(seg(0.0, 0.9, 0.0, -0.4, 0.055), seg(0.0, 0.9, -0.26, 0.66, 0.05))
    return [cord, crackers, shade, bands]


# ---- dumpling ----
def _dumpling_build():
    top = inter(oval(0.0, -0.14, 0.78, 0.7), -0.14 - Y)
    bumps = U(*[circle(0.74 * math.cos(math.radians(t)), -0.14 + 0.66 * math.sin(math.radians(t)), 0.1) for t in (28, 55, 82, 109, 136, 160)])
    return U(top, bumps, box(0.0, -0.2, 0.78, 0.08, 0.05))


@sticker("lunar", "dumpling", "Dumpling", ["#D9A55B", "#FFF4DC", "#E6C99A", "#B97F34"], ink=1.0)
def _():
    steamer = box(0, -0.58, 0.9, 0.28, 0.12)
    dump = _dumpling_build()
    shade = _rim(_dumpling_build, -0.1, 0.1)
    pleats = U(*[seg(0.5 * math.cos(math.radians(t)), -0.14 + 0.46 * math.sin(math.radians(t)), 0.64 * math.cos(math.radians(t)), -0.14 + 0.6 * math.sin(math.radians(t)), 0.05)
                 for t in (35, 62, 90, 118, 145)])
    slats = U(*[seg(-0.7, y, 0.7, y, 0.035) for y in (-0.52, -0.66)])
    return [steamer, dump, shade, U(pleats, slats)]


# ---- mandarin orange ----
def _orange_build():
    return circle(0.0, -0.1, 0.7)


@sticker("lunar", "mandarin", "Mandarin", ["#FF8A1F", "#D9600B", "#2FB67A", "#FFD08A"], ink=1.0)
def _():
    fruit = _orange_build()
    shade = _rim(_orange_build, -0.12, 0.12)
    leaf = U(poly(spline([(0.04, 0.58), (0.3, 0.86), (0.66, 0.78), (0.5, 0.52)], n=8)), poly(spline([(-0.04, 0.58), (-0.3, 0.84), (-0.62, 0.7), (-0.46, 0.5)], n=8)), seg(0.0, 0.56, 0.0, 0.68, 0.06))
    shine = U(oval(-0.32, 0.18, 0.1, 0.2, 0.5), circle(-0.1, 0.42, 0.06))
    return [fruit, shade, leaf, shine]


# ---- lucky knot ----
@sticker("lunar", "knot", "Lucky knot", ["#E3172F", "#8A0A1A", "#FFC531", "#C2182F"], ink=1.0)
def _():
    cx, cy = 0.0, 0.06
    loops = U(ring(cx, cy + 0.34, 0.24, 0.09), ring(cx, cy - 0.34, 0.24, 0.09), ring(cx - 0.34, cy, 0.24, 0.09), ring(cx + 0.34, cy, 0.24, 0.09))
    cord = U(loops, box(cx, cy, 0.3, 0.3, 0.06, 0.785))
    shade = _lowr(cord, 0.1)
    gold = U(circle(cx, cy, 0.13), box(0, -0.56, 0.13, 0.08, 0.03))
    tassel = U(taper(0.0, -0.54, 0.0, -0.74, 0.1, 0.14), taper(-0.16, -0.54, -0.26, -0.76, 0.08, 0.09), taper(0.16, -0.54, 0.26, -0.76, 0.08, 0.09))
    return [cord, shade, gold, tassel]


# ---- plum blossoms ----
def _flower(cx, cy, s, a):
    return petals(cx, cy, 5, 0.17 * s, 0.17 * s, 0.17 * s, a)


def _blooms_build():
    return U(_flower(-0.36, 0.52, 0.9, 0.3), _flower(0.34, 0.5, 1.05, 0.0), _flower(-0.12, -0.42, 1.0, 0.6))


@sticker("lunar", "plum", "Plum blossom", ["#7A4A2B", "#FF8FB3", "#E0517F", "#FFC531"], ink=1.0)
def _():
    branch = U(brush([(-0.8, -0.54), (-0.4, -0.3), (0.1, -0.1), (0.7, 0.42)], [0.09, 0.08, 0.07, 0.06]),
               brush([(-0.1, -0.12), (-0.2, 0.3), (-0.4, 0.5)], [0.07, 0.07, 0.06]))

    blooms = _blooms_build()
    shade = _rim(_blooms_build, -0.07, 0.07)
    centers = U(circle(-0.36, 0.52, 0.09), circle(0.34, 0.5, 0.1), circle(-0.12, -0.42, 0.1))
    return [branch, blooms, shade, centers]


# ---- gold coin, square hole ----
@sticker("lunar", "coin", "Lucky coin", ["#FFC531", "#E09A12", "#FFF4C7", "#7A3B00"], ink=1.0)
def _():
    coin = sub(circle(0, 0, 0.8), box(0, 0, 0.2, 0.2, 0.02))
    rim = U(sub(circle(0, 0, 0.8), circle(0, 0, 0.66)), sub(box(0, 0, 0.3, 0.3, 0.03), box(0, 0, 0.2, 0.2, 0.02)))
    marks = U(box(0, 0.48, 0.1, 0.07, 0.02), box(0, -0.48, 0.1, 0.07, 0.02), box(-0.48, 0, 0.07, 0.1, 0.02), box(0.48, 0, 0.07, 0.1, 0.02))
    shine = arc(0, 0, 0.55, math.radians(110), math.radians(165), 0.06)
    return [coin, rim, marks, shine]


# ---- lion dance head ----
@sticker("lunar", "lion", "Lion dance", ["#E3172F", "#FFFFFF", "#FFC531", "#1A1410"], ink=1.0)
def _():
    mane = U(*[circle(0.66 * math.cos(a), -0.04 + 0.62 * math.sin(a), 0.2) for a in [math.radians(t) for t in range(0, 360, 30)]], circle(0, -0.04, 0.6))
    face = oval(0, -0.06, 0.58, 0.54)
    gold = U(circle(-0.27, 0.16, 0.18), circle(0.27, 0.16, 0.18), seg(-0.46, 0.44, -0.14, 0.38, 0.07), seg(0.46, 0.44, 0.14, 0.38, 0.07),
             circle(0, -0.04, 0.12), taper(0.0, 0.48, 0.0, 0.76, 0.15, 0.08), circle(-0.62, 0.0, 0.1), circle(0.62, 0.0, 0.1))
    dark = U(circle(-0.25, 0.14, 0.09), circle(0.25, 0.14, 0.09), inter(oval(0, -0.3, 0.34, 0.22), Y + 0.3))
    return [mane, face, gold, dark]


# ---- paper fan ----
def _fan_build():
    return inter(circle(0.0, -0.8, 1.5), poly([(0.0, -0.8), (-1.24, 0.9), (1.24, 0.9)]))


@sticker("lunar", "fan", "Paper fan", ["#E3172F", "#A80E22", "#FFC531", "#FFE9B0"], ink=1.0)
def _():
    paper = _fan_build()
    shade = _lowr(paper, 0.0)
    trim = U(sub(paper, circle(0.0, -0.8, 1.22)), circle(0.0, -0.8, 0.16), box(0.0, -0.84, 0.07, 0.1, 0.02))
    ribs = U(*[seg(0.0, -0.8, 1.2 * math.sin(a), -0.8 + 1.2 * math.cos(a), 0.035) for a in [math.radians(t) for t in (-22, 0, 22)]])
    return [paper, shade, trim, ribs]


# ---- teapot ----
def _teapot_build():
    return U(circle(0.0, -0.2, 0.5), brush([(-0.4, -0.18), (-0.74, -0.24), (-0.9, 0.08)], [0.15, 0.11, 0.07]), box(0, -0.7, 0.3, 0.08, 0.04))


@sticker("lunar", "teapot", "Teapot", ["#C4623A", "#8E3F20", "#FFC531", "#FFE9B0"], ink=1.0)
def _():
    pot = _teapot_build()
    shade = _rim(_teapot_build, -0.1, 0.1)
    lid = U(inter(oval(0.0, 0.26, 0.36, 0.2), Y - 0.26), box(0, 0.26, 0.4, 0.05, 0.02), circle(0, 0.5, 0.09))
    handle = brush([(-0.4, 0.04), (-0.4, 0.5), (0.0, 0.8), (0.4, 0.5), (0.4, 0.04)], [0.07, 0.07, 0.07, 0.07, 0.07])
    return [pot, shade, lid, handle]


# ---- auspicious cloud ----
def _cloud_build():
    return U(circle(-0.34, 0.08, 0.36), circle(0.18, 0.26, 0.32), circle(0.52, -0.06, 0.26), box(0.1, -0.18, 0.62, 0.2, 0.2),
             brush([(-0.46, -0.3), (-0.7, -0.44), (-0.64, -0.7), (-0.4, -0.68)], [0.15, 0.13, 0.11, 0.1]))


@sticker("lunar", "cloud", "Lucky cloud", ["#E3172F", "#A80E22", "#FFE9B0", "#FFC531"], ink=1.0)
def _():
    cloud = _cloud_build()
    shade = _lowr(cloud, 0.0)
    curls = U(arc(-0.34, 0.08, 0.2, math.radians(30), math.radians(340), 0.05), arc(0.18, 0.26, 0.17, math.radians(30), math.radians(340), 0.05),
              arc(0.52, -0.06, 0.12, math.radians(30), math.radians(340), 0.045))
    gold = U(circle(-0.34, 0.08, 0.07), circle(0.18, 0.26, 0.06), circle(0.52, -0.06, 0.05))
    return [cloud, shade, curls, gold]


# ---- lion-dance drum ----
def _drum_build():
    return U(box(0.0, -0.06, 0.74, 0.46, 0.2), oval(0.0, 0.34, 0.74, 0.22))


@sticker("lunar", "drum", "Festival drum", ["#E3172F", "#8A1A1A", "#FFE9B0", "#FFC531"], ink=1.0)
def _():
    barrel = _drum_build()
    legs = U(poly([(-0.58, -0.4), (-0.34, -0.4), (-0.66, -0.76), (-0.86, -0.76)]), poly([(0.58, -0.4), (0.34, -0.4), (0.66, -0.76), (0.86, -0.76)]))
    dark = U(_lowr(barrel, 0.2), legs)
    skin = oval(0.0, 0.34, 0.6, 0.15)
    gold = U(*[circle(x, 0.12, 0.08) for x in (-0.56, -0.28, 0.0, 0.28, 0.56)], *[circle(x, -0.3, 0.08) for x in (-0.56, -0.28, 0.0, 0.28, 0.56)])
    return [barrel, dark, skin, gold]


# ---- gold ingot ----
def _ingot_build():
    base = poly(spline([(-0.62, -0.62), (0.62, -0.62), (0.76, -0.1), (-0.76, -0.1)], n=8))
    ends = U(oval(-0.68, 0.06, 0.18, 0.32, 0.5), oval(0.68, 0.06, 0.18, 0.32, -0.5))
    return smin(smin(base, ends, 0.1), oval(0.0, 0.12, 0.5, 0.36), 0.1)


@sticker("lunar", "ingot", "Gold ingot", ["#FFC531", "#D88A0C", "#FFF4C7", "#FFFFFF"], ink=1.0)
def _():
    gold = _ingot_build()
    shade = _rim(_ingot_build, -0.1, 0.1)
    face = oval(0.0, 0.2, 0.28, 0.22)
    shine = oval(-0.14, 0.26, 0.06, 0.1, 0.5)
    return [gold, shade, face, shine]


# ---- good-luck diamond ----
@sticker("lunar", "luck", "Good luck", ["#E3172F", "#7A0A18", "#FFC531", "#FFF4C7"], ink=1.0)
def _():
    diamond = box(0, 0, 0.64, 0.64, 0.06, math.pi / 4)
    shade = _lowr(diamond, 0.2)
    border = U(sub(box(0, 0, 0.64, 0.64, 0.06, math.pi / 4), box(0, 0, 0.52, 0.52, 0.04, math.pi / 4)), petals(0, 0, 4, 0.26, 0.21, 0.21, math.pi / 4))
    core = circle(0, 0, 0.11)
    return [diamond, shade, border, core]
