PACK = ("valentine", "Valentine's", False)
PRO_IDS = {"winged", "teddy", "chocolates", "drum", "potion", "birds"}


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


def _hrt(cx, cy, w):
    """A heart `w` wide on each side of (cx, cy), centred on that point."""
    s = w / 0.6
    return heart(cx, cy + 0.07 * s, s)


def _glint(cx, cy, r):
    """A bold four-point sparkle."""
    return star(cx, cy, 4, r, r * 0.38, math.pi / 2)


# ---- pierced heart ----
def _pierced_build():
    return _hrt(0.0, 0.0, 0.66)


@sticker("valentine", "pierced", "Pierced heart", ["#FF2D6F", "#C2185B", "#FFFFFF", "#8A5A2B"], ink=1.0)
def _():
    heart_ = _pierced_build()
    shade = _rim(_pierced_build, -0.08, 0.08)
    shine = U(oval(-0.36, 0.28, 0.06, 0.14, 0.7), circle(-0.24, 0.44, 0.05))
    tail = U(seg(-0.8, -0.56, 0.0, -0.05, 0.05), poly([(-0.92, -0.42), (-0.7, -0.5), (-0.84, -0.7)]), poly([(-0.7, -0.62), (-0.52, -0.46), (-0.58, -0.82)]))
    tip = U(shine, seg(0.0, 0.05, 0.7, 0.5, 0.05), poly([(0.62, 0.34), (0.92, 0.6), (0.56, 0.62)]))
    return [tail, heart_, shade, tip]


# ---- winged heart ----
def _winged_build():
    return _hrt(0.0, -0.04, 0.46)


@sticker("valentine", "winged", "Winged heart", ["#FFFFFF", "#FF2D6F", "#C2185B", "#FFB3C7"], ink=1.0)
def _():
    wl = U(oval(-0.6, 0.3, 0.3, 0.13, 0.5), oval(-0.64, 0.08, 0.28, 0.12, 0.2), oval(-0.56, -0.12, 0.24, 0.11, -0.15))
    wr = U(oval(0.6, 0.3, 0.3, 0.13, -0.5), oval(0.64, 0.08, 0.28, 0.12, -0.2), oval(0.56, -0.12, 0.24, 0.11, 0.15))
    wings = U(wl, wr)
    body = _winged_build()
    shade = _rim(_winged_build, -0.1, 0.1)
    shine = U(oval(-0.24, 0.2, 0.05, 0.12, 0.7), circle(-0.14, 0.34, 0.045))
    return [wings, body, shade, shine]


# ---- cracked heart ----
@sticker("valentine", "cracked", "Broken heart", ["#FF4F6B", "#C2185B", "#FFF1E0", "#FFB3C7"], ink=1.0)
def _():
    zig = [(0.02, 0.62), (0.16, 0.3), (-0.1, 0.04), (0.14, -0.22), (-0.04, -0.44), (0.02, -0.8)]
    left = inter(_hrt(0.0, 0.0, 0.7), poly(zig + [(-1.2, -0.9), (-1.2, 0.8)]))
    right = inter(_hrt(0.0, 0.0, 0.7), poly(zig + [(1.2, -0.9), (1.2, 0.8)]))
    with rotated(0.12, 0.0, -0.6, -0.08, 0.03):
        left = inter(_hrt(0.0, 0.0, 0.7), poly(zig + [(-1.2, -0.9), (-1.2, 0.8)]))
    with rotated(-0.1, 0.0, -0.6, 0.08, -0.04):
        right = inter(_hrt(0.0, 0.0, 0.7), poly(zig + [(1.2, -0.9), (1.2, 0.8)]))
    pieces = U(left, right)
    shade = _lowr(pieces, 0.1)
    plaster = box(0.0, 0.0, 0.42, 0.12, 0.04, 0.6)
    shine = U(oval(-0.4, 0.3, 0.06, 0.14, 0.7), circle(-0.3, 0.46, 0.05))
    return [pieces, shade, plaster, shine]


# ---- candy heart ----
@sticker("valentine", "candy", "Candy heart", ["#C9A6FF", "#9B72E8", "#FFFFFF", "#7A4FD0"], ink=1.0)
def _():
    candy = _hrt(0.0, 0.0, 0.8)
    shade = _lowr(candy, 0.12)
    shine = U(oval(-0.5, 0.36, 0.07, 0.16, 0.7), circle(-0.36, 0.54, 0.05))
    word = text("HUG", 0.0, 0.02, 0.4, maxw=0.96)
    return [candy, shade, shine, word]


# ---- love letter ----
@sticker("valentine", "letter", "Love letter", ["#FFFFFF", "#FFF1E0", "#FF8FB3", "#E3172F"], ink=1.0)
def _():
    card = box(0.0, 0.36, 0.56, 0.4, 0.06)
    paper = box(0.0, -0.18, 0.82, 0.52, 0.08)
    flap = inter(paper, poly([(-0.9, 0.4), (0.9, 0.4), (0.0, -0.26)]))
    seal = _hrt(0.0, -0.24, 0.26)
    return [card, paper, flap, seal]


# ---- roses ----
@sticker("valentine", "roses", "Roses", ["#2FB67A", "#E3172F", "#8E0F25", "#FF8FB3"], ink=1.0)
def _():
    leaves = U(oval(-0.64, -0.1, 0.28, 0.14, 0.6), oval(0.62, -0.3, 0.28, 0.14, -0.6), seg(-0.2, 0.2, -0.02, -0.5, 0.075), seg(0.28, 0.05, 0.02, -0.5, 0.075))
    roses = U(circle(-0.24, 0.36, 0.42), circle(0.34, 0.16, 0.36))
    swirls = U(arc(-0.24, 0.36, 0.22, math.radians(30), math.radians(300), 0.055), arc(-0.24, 0.36, 0.09, math.radians(0), math.radians(270), 0.05),
               arc(0.34, 0.16, 0.19, math.radians(80), math.radians(350), 0.055), arc(0.34, 0.16, 0.07, math.radians(0), math.radians(270), 0.05))
    bow = U(poly([(0.0, -0.5), (-0.36, -0.34), (-0.36, -0.68)]), poly([(0.0, -0.5), (0.36, -0.34), (0.36, -0.68)]), circle(0.0, -0.5, 0.11),
            poly([(-0.06, -0.58), (-0.3, -0.88), (-0.06, -0.84)]), poly([(0.06, -0.58), (0.3, -0.88), (0.06, -0.84)]))
    return [leaves, roses, swirls, bow]


# ---- teddy bear ----
def _teddy_build():
    return U(circle(0, 0.44, 0.34), circle(-0.3, 0.7, 0.14), circle(0.3, 0.7, 0.14), oval(0, -0.28, 0.4, 0.42),
             oval(-0.5, -0.12, 0.14, 0.24, 0.5), oval(0.5, -0.12, 0.14, 0.24, -0.5), oval(-0.28, -0.66, 0.2, 0.15), oval(0.28, -0.66, 0.2, 0.15))


@sticker("valentine", "teddy", "Teddy bear", ["#C98B4B", "#7A4A2B", "#FFE9C7", "#FF2D6F"], ink=1.0)
def _():
    bear = _teddy_build()
    dark = U(_lowr(bear, 0.16), circle(-0.12, 0.5, 0.045), circle(0.12, 0.5, 0.045), oval(0, 0.38, 0.08, 0.055))
    cream = U(oval(0, 0.4, 0.16, 0.12), circle(-0.3, 0.7, 0.07), circle(0.3, 0.7, 0.07), oval(-0.28, -0.66, 0.12, 0.08), oval(0.28, -0.66, 0.12, 0.08))
    love = _hrt(0.0, -0.2, 0.22)
    return [bear, dark, cream, love]


# ---- chocolates ----
@sticker("valentine", "chocolates", "Chocolates", ["#E3172F", "#FFE9B0", "#6B3A1E", "#FFD1E0"], ink=1.0)
def _():
    cases = U(box(0.0, 0.62, 0.66, 0.28, 0.07), box(0.0, -0.16, 0.76, 0.52, 0.1))
    tray = U(box(0.0, -0.16, 0.66, 0.42, 0.06), _hrt(0.0, 0.62, 0.17))
    chocolates = U(*[circle(x, y, 0.15) for x in (-0.4, 0.0, 0.4) for y in (-0.02, -0.34)])
    icing = U(*[circle(x - 0.04, y + 0.04, 0.06) for x in (-0.4, 0.0, 0.4) for y in (-0.02, -0.34)])
    return [cases, tray, chocolates, icing]


# ---- cupid bow ----
@sticker("valentine", "bow", "Cupid bow", ["#C98B4B", "#FFFFFF", "#7A4A2B", "#FF2D6F"], ink=1.0)
def _():
    ex, ey = -0.35 + 0.84 * math.cos(math.radians(50)), 0.84 * math.sin(math.radians(50))
    limb = arc(-0.35, 0.0, 0.84, math.radians(-50), math.radians(50), 0.09)
    string = seg(ex, ey, ex, -ey, 0.07)
    shaft = U(seg(-0.55, 0.0, 0.5, 0.0, 0.065), poly([(-0.92, 0.0), (-0.66, 0.2), (-0.52, 0.02), (-0.66, -0.2)]))
    with rotated(math.pi / 2, 0.0, 0.0):
        tip = _hrt(0.62, 0.0, 0.25)
    return [limb, string, shaft, tip]


# ---- heart padlock ----
def _lock_build():
    return _hrt(0.0, -0.2, 0.62)


@sticker("valentine", "padlock", "Love lock", ["#C9CFD8", "#FFC531", "#E3172F", "#5A0A18"], ink=1.0)
def _():
    shackle = sub(oval(0.0, 0.34, 0.36, 0.42), oval(0.0, 0.34, 0.22, 0.3))
    key = U(seg(-0.66, 0.66, 0.6, -0.6, 0.095), _hrt(-0.68, 0.68, 0.2), box(0.5, -0.4, 0.13, 0.06, 0.02, 0.785), box(0.64, -0.54, 0.13, 0.06, 0.02, 0.785))
    lock = _lock_build()
    shade = U(_rim(_lock_build, -0.08, 0.08), circle(0.0, -0.12, 0.12), taper(0.0, -0.12, 0.0, -0.38, 0.05, 0.1))
    return [shackle, key, lock, shade]


# ---- kiss print ----
@sticker("valentine", "kiss", "Kiss print", ["#FFF1E0", "#E3172F", "#8E0F25", "#FF2D6F"], ink=1.0)
def _():
    card = box(0.0, 0.0, 0.8, 0.62, 0.08, 0.12)
    with rotated(0.12, 0.0, 0.0, -0.12, 0.0):
        lips = smin(U(oval(-0.18, 0.1, 0.27, 0.16, -0.2), oval(0.18, 0.1, 0.27, 0.16, 0.2)), oval(0.0, -0.1, 0.4, 0.2), 0.05)
        crease = U(polyline([(-0.42, -0.0), (-0.2, -0.03), (0.0, 0.03), (0.2, -0.03), (0.42, 0.0)], 0.035), seg(-0.1, -0.22, -0.1, -0.12, 0.03), seg(0.1, -0.22, 0.1, -0.12, 0.03))
    love = _hrt(0.5, 0.2, 0.2)
    return [card, lips, crease, love]


# ---- XOXO ----
@sticker("valentine", "xoxo", "XOXO", ["#FF5C8A", "#D6336C", "#FFFFFF", "#FFE14A"], ink=1.0)
def _():
    tile = box(0, 0, 0.76, 0.76, 0.2, 0.1)
    shade = _lowr(tile, 0.3)
    word = U(text("XO", 0.0, 0.34, 0.44, ang=0.1, maxw=1.1), text("XO", 0.0, -0.28, 0.44, ang=0.1, maxw=1.1))
    dots = U(_hrt(0.64, 0.64, 0.14), _hrt(-0.64, -0.64, 0.14))
    return [tile, shade, word, dots]


# ---- LUV ----
@sticker("valentine", "luv", "LUV", ["#FF2D6F", "#C2185B", "#FFFFFF", "#FFE14A"], ink=1.0)
def _():
    bubble = U(box(0.0, 0.1, 0.84, 0.54, 0.34), poly([(-0.5, -0.3), (-0.16, -0.36), (-0.62, -0.84)]))
    shade = _lowr(bubble, 0.2)
    word = text("LUV", 0.0, 0.1, 0.5, maxw=1.3)
    glint = _glint(0.7, 0.58, 0.18)
    return [bubble, shade, word, glint]


# ---- heart cassette ----
@sticker("valentine", "cassette", "Love tape", ["#FF5C8A", "#FFF1E0", "#3A2433", "#E3172F"], ink=1.0)
def _():
    body = box(0, 0, 0.84, 0.6, 0.1)
    label = box(0, 0.24, 0.68, 0.26, 0.06)
    window = box(0, -0.26, 0.62, 0.26, 0.12)
    love = U(_hrt(-0.34, -0.26, 0.22), _hrt(0.34, -0.26, 0.22), _hrt(0.0, 0.24, 0.19), box(0.0, -0.26, 0.12, 0.05, 0.02))
    return [body, label, window, love]


# ---- heart drum ----
@sticker("valentine", "drum", "Heart drum", ["#FFC531", "#FF5C8A", "#FFF1E0", "#E3172F"], ink=1.0)
def _():
    shell = box(0.0, -0.22, 0.62, 0.4, 0.06)
    skin = oval(0.0, 0.18, 0.62, 0.2)
    trim = U(sub(oval(0.0, 0.18, 0.7, 0.26), oval(0.0, 0.18, 0.58, 0.17)), box(0.0, -0.62, 0.68, 0.06, 0.03), box(-0.52, -0.22, 0.05, 0.3), box(0.52, -0.22, 0.05, 0.3),
             box(-0.34, -0.22, 0.05, 0.3), box(0.34, -0.22, 0.05, 0.3), seg(-0.58, 0.88, 0.58, 0.58, 0.055), seg(0.58, 0.88, -0.58, 0.58, 0.055),
             circle(0.58, 0.58, 0.075), circle(-0.58, 0.58, 0.075))
    love = _hrt(0.0, -0.2, 0.18)
    return [shell, skin, trim, love]


# ---- lovebirds ----
@sticker("valentine", "birds", "Lovebirds", ["#FF8FB3", "#E0517F", "#FFC531", "#B8123E"], ink=1.0)
def _():
    birds = U(circle(-0.4, -0.18, 0.34), circle(-0.3, 0.2, 0.22), circle(0.4, -0.18, 0.34), circle(0.3, 0.2, 0.22),
              poly([(-0.66, -0.3), (-0.92, -0.62), (-0.52, -0.5)]), poly([(0.66, -0.3), (0.92, -0.62), (0.52, -0.5)]), box(0.0, -0.62, 0.72, 0.07, 0.03))
    wings = U(oval(-0.5, -0.14, 0.16, 0.24, 0.5), oval(0.5, -0.14, 0.16, 0.24, -0.5))
    beaks = U(poly([(-0.1, 0.24), (-0.1, 0.12), (-0.02, 0.18)]), poly([(0.1, 0.24), (0.1, 0.12), (0.02, 0.18)]))
    love = U(_hrt(0.0, 0.62, 0.2), circle(-0.24, 0.26, 0.045), circle(0.24, 0.26, 0.045))
    return [birds, wings, beaks, love]


# ---- love potion ----
@sticker("valentine", "potion", "Love potion", ["#D8EEFF", "#FF5C8A", "#C98B4B", "#FFFFFF"], ink=1.0)
def _():
    glass = U(_hrt(0.0, -0.2, 0.62), box(0.0, 0.42, 0.17, 0.2, 0.04), box(0.0, 0.6, 0.23, 0.06, 0.03))
    liquid = inter(_hrt(0.0, -0.2, 0.62) + 0.09, Y - 0.1)
    cork = box(0.0, 0.8, 0.16, 0.1, 0.04)
    bubbles = U(circle(-0.16, -0.14, 0.09), circle(0.16, -0.32, 0.08), circle(0.12, 0.0, 0.06), seg(-0.34, 0.3, -0.26, 0.4, 0.045))
    return [glass, liquid, cork, bubbles]


# ---- ring box ----
@sticker("valentine", "ringbox", "Ring box", ["#8B5CE0", "#B58CFF", "#FFC531", "#9FE8FF"], ink=1.0)
def _():
    box_ = U(box(0.0, 0.3, 0.6, 0.34, 0.08, 0.0), box(0.0, -0.36, 0.7, 0.34, 0.08))
    cushion = box(0.0, -0.1, 0.56, 0.1, 0.04)
    ring_ = ring(0.0, 0.1, 0.24, 0.08)
    gem = regpoly(0.0, 0.46, 4, 0.27)
    return [box_, cushion, ring_, gem]
