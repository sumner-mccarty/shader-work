PACK = ("spring", "Spring", False)
PRO_IDS = {"lamb", "umbrella", "butterfly", "nest", "snail", "cherry"}


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


def _egg(cx, cy, w, ang=0.0):
    """An egg `w` wide, a little pointier at the top, turned by `ang`."""
    with rotated(ang, cx, cy):
        return smin(circle(cx, cy - 0.12 * w, w), circle(cx, cy + 0.42 * w, 0.62 * w), 0.5 * w)


def _drop(cx, cy, r, ang=0.0):
    """A rain drop: round at the bottom, pointed on top, turned by `ang`."""
    with rotated(ang, cx, cy):
        return U(circle(cx, cy, r), poly([(cx - r * 0.92, cy + r * 0.3), (cx + r * 0.92, cy + r * 0.3), (cx, cy + r * 2.1)]))


# ---- painted eggs ----
@sticker("spring", "eggs", "Painted eggs", ["#FF8FB3", "#2FA8F0", "#FFD84A", "#FFFFFF"], ink=1.0)
def _():
    left = _egg(-0.5, -0.14, 0.38, 0.2)
    middle = _egg(0.0, 0.1, 0.46)
    right = _egg(0.52, -0.14, 0.38, -0.2)
    bands = inter(left, box(-0.5, -0.14, 0.6, 0.12, 0.0, 0.2))
    dots = inter(middle, U(circle(-0.16, 0.24, 0.1), circle(0.16, 0.24, 0.1), circle(0.0, 0.04, 0.1), circle(-0.18, -0.16, 0.1), circle(0.18, -0.16, 0.1)))
    zig = inter(right, stripes(0.26, math.radians(60), 0.5, 0.0))
    marks = U(bands, dots, zig)
    return [left, middle, right, marks]


# ---- bunny ----
def _bunny_build():
    return U(oval(0.0, -0.4, 0.42, 0.4), circle(0.0, 0.1, 0.32), oval(-0.16, 0.66, 0.11, 0.3, 0.1), oval(0.16, 0.66, 0.11, 0.3, -0.1),
             oval(-0.26, -0.74, 0.2, 0.11), oval(0.26, -0.74, 0.2, 0.11), circle(0.44, -0.58, 0.13))


@sticker("spring", "bunny", "Bunny", ["#FFFFFF", "#9AA8BD", "#FF8FB3", "#1A1410"], ink=1.0)
def _():
    bunny = _bunny_build()
    shade = _lowr(bunny, 0.1)
    blush = U(oval(-0.16, 0.68, 0.06, 0.22, 0.1), oval(0.16, 0.68, 0.06, 0.22, -0.1), oval(0.0, 0.04, 0.08, 0.06), _egg(0.0, -0.46, 0.2))
    eyes = U(circle(-0.12, 0.16, 0.06), circle(0.12, 0.16, 0.06))
    return [bunny, shade, blush, eyes]


# ---- hatching chick ----
def _chick_build():
    return U(circle(0.0, 0.1, 0.5), poly([(-0.1, 0.56), (0.0, 0.76), (0.1, 0.56)]), poly([(-0.18, 0.56), (-0.3, 0.7), (-0.06, 0.58)]))


@sticker("spring", "chick", "Chick", ["#FFD84A", "#F2A02A", "#FFFFFF", "#1A1410"], ink=1.0)
def _():
    chick = _chick_build()
    beak = U(_lowr(chick, 0.2), poly([(-0.12, 0.14), (0.12, 0.14), (0.0, 0.0)]), seg(-0.18, -0.34, -0.22, -0.5, 0.05), seg(0.18, -0.34, 0.22, -0.5, 0.05))
    zig = [(-0.74, -0.2), (-0.5, -0.02), (-0.3, -0.22), (-0.1, -0.02), (0.1, -0.22), (0.3, -0.02), (0.5, -0.22), (0.74, -0.04)]
    shell = poly(zig + [(0.7, -0.78), (-0.7, -0.78)])
    eyes = U(circle(-0.17, 0.24, 0.08), circle(0.17, 0.24, 0.08))
    return [chick, beak, shell, eyes]


# ---- tulips ----
def _tulip(cx, cy):
    cup = U(inter(oval(cx, cy, 0.25, 0.36), Y - cy), poly([(cx - 0.25, cy), (cx - 0.25, cy + 0.44), (cx - 0.09, cy + 0.24), (cx, cy + 0.48), (cx + 0.09, cy + 0.24),
                                                         (cx + 0.25, cy + 0.44), (cx + 0.25, cy)]))
    return cup


@sticker("spring", "tulips", "Tulips", ["#2FB67A", "#FF3D5A", "#FFD84A", "#FF8FB3"], ink=1.0)
def _():
    leaves = U(seg(-0.46, 0.0, -0.3, -0.8, 0.09), seg(0.0, 0.2, 0.0, -0.8, 0.09), seg(0.46, 0.0, 0.3, -0.8, 0.09),
               oval(-0.62, -0.5, 0.14, 0.42, -0.4), oval(0.62, -0.5, 0.14, 0.42, 0.4), box(0.0, -0.84, 0.2, 0.06, 0.03))
    left = _tulip(-0.46, 0.0)
    middle = _tulip(0.0, 0.22)
    right = _tulip(0.46, 0.0)
    return [leaves, left, middle, right]


# ---- watering can ----
def _can_build():
    return U(box(-0.12, -0.2, 0.42, 0.42, 0.08), brush([(0.24, -0.1), (0.56, 0.1), (0.8, 0.4)], [0.14, 0.11, 0.1]), box(-0.12, 0.2, 0.42, 0.05, 0.02))


@sticker("spring", "can", "Watering can", ["#2FA8F0", "#1B72B8", "#FFD84A", "#9FE8FF"], ink=1.0)
def _():
    can = _can_build()
    shade = _lowr(can, 0.2)
    trim = U(brush([(-0.46, 0.2), (-0.7, 0.5), (-0.4, 0.72), (-0.04, 0.56)], [0.09, 0.09, 0.09, 0.09]), oval(0.84, 0.46, 0.1, 0.2, 0.5))
    drops = U(seg(0.84, 0.3, 0.86, -0.12, 0.1), _drop(0.84, -0.4, 0.11))
    return [can, shade, trim, drops]


# ---- rain boots ----
def _boots_build():
    return U(box(-0.4, 0.1, 0.22, 0.5, 0.06), oval(-0.34, -0.5, 0.34, 0.2), box(0.4, 0.1, 0.22, 0.5, 0.06), oval(0.46, -0.5, 0.34, 0.2))


@sticker("spring", "boots", "Rain boots", ["#8FD0F2", "#2FB67A", "#1B8A58", "#FFFFFF"], ink=1.0)
def _():
    puddle = oval(0.0, -0.7, 0.92, 0.2)
    boots = _boots_build()
    shade = _rim(_boots_build, -0.08, 0.08)
    trim = U(box(-0.4, 0.56, 0.22, 0.07, 0.02), box(0.4, 0.56, 0.22, 0.07, 0.02), circle(-0.4, 0.3, 0.07), circle(0.4, 0.3, 0.07), circle(-0.4, 0.06, 0.07),
             circle(0.4, 0.06, 0.07), circle(-0.4, -0.18, 0.07), circle(0.4, -0.18, 0.07))
    return [puddle, boots, shade, trim]


# ---- umbrella with rain ----
@sticker("spring", "umbrella", "Umbrella", ["#FF5C8A", "#FFD1E0", "#2B2E3A", "#2FA8F0"], ink=1.0)
def _():
    dome = inter(circle(0.0, 0.0, 0.84), -Y)
    scallops = U(*[circle(x, 0.0, 0.14) for x in (-0.56, -0.28, 0.0, 0.28, 0.56)])
    canopy = U(dome, scallops)
    panels = inter(canopy, U(poly([(0.0, 0.84), (-0.2, 0.0), (0.2, 0.0)]), poly([(-0.5, 0.64), (-0.72, 0.0), (-0.44, 0.0)]), poly([(0.5, 0.64), (0.72, 0.0), (0.44, 0.0)])))
    handle = U(seg(0.0, 0.0, 0.0, -0.5, 0.05), arc(-0.14, -0.5, 0.14, math.radians(180), math.radians(360), 0.05))
    rain = U(_drop(-0.56, -0.28, 0.09), _drop(0.28, -0.28, 0.09), _drop(0.56, -0.28, 0.09), _drop(-0.28, -0.52, 0.09))
    return [canopy, panels, handle, rain]


# ---- butterfly ----
def _wings_build():
    return U(oval(-0.4, 0.26, 0.38, 0.3, 0.5), oval(0.4, 0.26, 0.38, 0.3, -0.5), oval(-0.32, -0.34, 0.26, 0.22, -0.5), oval(0.32, -0.34, 0.26, 0.22, 0.5))


@sticker("spring", "butterfly", "Butterfly", ["#2FA8F0", "#1B72B8", "#FFF4C7", "#1A1410"], ink=1.0)
def _():
    wings = _wings_build()
    shade = _lowr(wings, 0.2)
    spots = U(circle(-0.46, 0.3, 0.11), circle(0.46, 0.3, 0.11), circle(-0.32, -0.34, 0.08), circle(0.32, -0.34, 0.08))
    body = U(oval(0.0, -0.04, 0.09, 0.5), brush([(-0.04, 0.4), (-0.16, 0.62), (-0.3, 0.7)], [0.06, 0.06, 0.06]), brush([(0.04, 0.4), (0.16, 0.62), (0.3, 0.7)], [0.06, 0.06, 0.06]))
    return [wings, shade, spots, body]


# ---- bird nest ----
@sticker("spring", "nest", "Bird nest", ["#B8864B", "#7A4A2B", "#8FD0F2", "#FFFFFF"], ink=1.0)
def _():
    nest = oval(0.0, -0.34, 0.74, 0.34)
    weave = U(*[arc(0.0, -0.18, 0.5 - 0.1 * k, math.radians(200), math.radians(340), 0.04) for k in range(3)], seg(-0.64, -0.2, -0.8, -0.1, 0.05), seg(0.64, -0.2, 0.8, -0.12, 0.05))
    eggs = U(oval(-0.3, 0.0, 0.2, 0.26, 0.2), oval(0.0, 0.08, 0.2, 0.26), oval(0.3, 0.0, 0.2, 0.26, -0.2))
    highlight = U(oval(-0.36, 0.08, 0.05, 0.1, 0.2), oval(-0.06, 0.16, 0.05, 0.1), oval(0.24, 0.08, 0.05, 0.1, -0.2))
    return [nest, weave, eggs, highlight]


# ---- kite ----
@sticker("spring", "kite", "Kite", ["#FF5C8A", "#FFD84A", "#FFFFFF", "#2FA8F0"], ink=1.0)
def _():
    outline = poly([(0.0, 0.84), (0.46, 0.24), (0.0, -0.4), (-0.46, 0.24)])
    panel = inter(outline, -X)
    struts = U(seg(0.0, 0.84, 0.0, -0.4, 0.05), seg(-0.46, 0.24, 0.46, 0.24, 0.05))
    tail = U(brush([(0.0, -0.3), (0.22, -0.6), (-0.12, -0.76), (0.2, -0.88)], [0.06, 0.06, 0.06, 0.06]), box(0.12, -0.6, 0.12, 0.07, 0.02, 0.6), box(-0.1, -0.76, 0.12, 0.07, 0.02, -0.6))
    return [outline, panel, struts, tail]


# ---- sprout ----
@sticker("spring", "sprout", "Sprout", ["#4CC76A", "#2E9E4F", "#8A5A2B", "#BFF2D4"], ink=1.0)
def _():
    left = poly(spline([(0.0, 0.0), (-0.3, 0.46), (-0.76, 0.5), (-0.7, 0.1), (-0.34, -0.06)], n=8))
    right = poly(spline([(0.0, 0.12), (0.3, 0.64), (0.78, 0.66), (0.72, 0.24), (0.34, 0.06)], n=8))
    leaves = U(left, right, seg(0.0, -0.3, 0.0, 0.1, 0.07))
    shade = _lowr(leaves, 0.3)
    soil = oval(0.0, -0.52, 0.76, 0.3)
    vein = U(seg(-0.2, 0.12, -0.56, 0.3, 0.035), seg(0.2, 0.28, 0.6, 0.46, 0.035))
    return [leaves, shade, soil, vein]


# ---- cherry blossom branch ----
def _blossom(cx, cy, s, a=0.0):
    petals5 = petals(cx, cy, 5, 0.2 * s, 0.15 * s, 0.15 * s, a)
    notches = U(*[circle(cx + 0.36 * s * math.cos(a + 2 * math.pi * k / 5), cy + 0.36 * s * math.sin(a + 2 * math.pi * k / 5), 0.05 * s) for k in range(5)])
    return sub(petals5, notches)


def _blossoms_build():
    return U(_blossom(-0.38, 0.44, 1.3, 0.3), _blossom(0.36, 0.28, 1.4, 0.0), _blossom(-0.12, -0.4, 1.25, 0.6))


@sticker("spring", "cherry", "Cherry blossom", ["#6B4A3A", "#FFD1E0", "#FF9FBF", "#FFE14A"], ink=1.0)
def _():
    branch = U(brush([(0.9, 0.7), (0.4, 0.2), (0.0, -0.1), (-0.5, -0.5), (-0.84, -0.72)], [0.08, 0.1, 0.1, 0.09, 0.08]),
               brush([(0.1, -0.06), (-0.2, 0.24), (-0.5, 0.5)], [0.08, 0.08, 0.07]))
    blooms = _blossoms_build()
    shade = _lowr(blooms, 0.0)
    centers = U(circle(-0.38, 0.44, 0.12), circle(0.36, 0.28, 0.13), circle(-0.12, -0.4, 0.12))
    return [branch, blooms, shade, centers]


# ---- snail ----
@sticker("spring", "snail", "Snail", ["#FF9F43", "#E8C9A0", "#8A4B1F", "#4CC76A"], ink=1.0)
def _():
    shell = circle(0.14, 0.2, 0.46)
    body = U(oval(-0.06, -0.38, 0.78, 0.16), taper(-0.6, -0.34, -0.7, 0.2, 0.13, 0.11), circle(-0.7, 0.24, 0.13), seg(-0.74, 0.3, -0.84, 0.56, 0.05), seg(-0.64, 0.32, -0.62, 0.6, 0.05))
    swirl = U(arc(0.14, 0.2, 0.3, math.radians(30), math.radians(330), 0.06), arc(0.14, 0.2, 0.13, math.radians(120), math.radians(420), 0.06))
    leaf = U(oval(0.0, -0.66, 0.88, 0.14), circle(-0.84, 0.58, 0.07), circle(-0.62, 0.62, 0.07))
    return [shell, body, swirl, leaf]


# ---- lamb ----
@sticker("spring", "lamb", "Lamb", ["#FFFFFF", "#C9D4E3", "#6B4A3A", "#FF8FB3"], ink=1.0)
def _():
    wool = U(circle(-0.34, 0.04, 0.3), circle(-0.02, 0.24, 0.32), circle(-0.04, -0.14, 0.38), circle(-0.46, -0.28, 0.24), circle(-0.04, 0.05, 0.4))
    shade = _lowr(wool, 0.12)
    face = U(oval(0.52, 0.1, 0.26, 0.3, -0.2), oval(0.36, 0.38, 0.1, 0.18, 0.5), box(-0.3, -0.7, 0.09, 0.18, 0.03), box(0.0, -0.7, 0.09, 0.18, 0.03), box(0.24, -0.7, 0.09, 0.18, 0.03))
    blush = U(oval(0.36, 0.38, 0.05, 0.1, 0.5), circle(0.64, 0.0, 0.06), circle(0.5, 0.18, 0.045))
    return [wool, shade, face, blush]


# ---- seed packet ----
@sticker("spring", "seeds", "Seed packet", ["#FFF4C7", "#4CC76A", "#FF8A2B", "#3A2433"], ink=1.0)
def _():
    packet = box(0.0, -0.04, 0.6, 0.84, 0.06)
    zig = poly([(-0.6, 0.8), (0.6, 0.8), (0.6, 0.6), (0.4, 0.5), (0.2, 0.6), (0.0, 0.5), (-0.2, 0.6), (-0.4, 0.5), (-0.6, 0.6)])
    stem = U(inter(packet, zig), seg(-0.08, 0.5, -0.16, 0.66, 0.05), seg(0.0, 0.52, 0.0, 0.7, 0.05), seg(0.08, 0.5, 0.16, 0.66, 0.05))
    carrot = poly([(-0.2, 0.5), (0.2, 0.5), (0.0, -0.02)])
    word = text("SEEDS", 0.0, -0.46, 0.2, maxw=0.95)
    return [packet, stem, carrot, word]


# ---- BLOOM ----
@sticker("spring", "bloom", "BLOOM", ["#4CC76A", "#2E9E4F", "#FFFFFF", "#FF8FB3"], ink=1.0)
def _():
    pill = box(0.0, 0.0, 0.84, 0.36, 0.36)
    shade = _lowr(pill, 0.2)
    word = text("BLOOM", 0.0, 0.0, 0.46, maxw=1.4)
    flowers = U(petals(-0.68, 0.3, 5, 0.15, 0.12, 0.12, 0.3), petals(0.68, -0.3, 5, 0.15, 0.12, 0.12, 0.1), circle(-0.68, 0.3, 0.08), circle(0.68, -0.3, 0.08))
    return [pill, shade, word, flowers]
