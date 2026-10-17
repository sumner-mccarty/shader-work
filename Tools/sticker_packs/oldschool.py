# Old School — the 80s: b-boys, cardboard, hydrants, gold and block-party gear. Run by Tools/decor_stickers.py.
PACK = ("oldschool", "Old School", False)
PRO_IDS = {"bboy", "subway", "hydrant", "medallion", "phat", "nameplate"}


def _moved(d, dx, dy):
    """Layer d slid by (dx, dy) slice units (y up); what slides in from the edge is far outside."""
    px, py = int(round(dx * N / 2)), int(round(dy * N / 2))
    out = np.full_like(d, BIG)
    h, w = d.shape
    rs, rd = (slice(py, h), slice(0, h - py)) if py >= 0 else (slice(0, h + py), slice(-py, h))
    cs, cd = (slice(0, w - px), slice(px, w)) if px >= 0 else (slice(-px, w), slice(0, w + px))
    out[rd, cd] = d[rs, cs]
    return out


def _rim(d, k=0.08):
    """The lower-right rim of d: d minus itself slid up-left — the house shade."""
    return sub(d, _moved(d, -k, k))


def _glint(d, k=0.07):
    """The upper-left rim of d: d minus itself slid down-right — the house highlight."""
    return sub(d, _moved(d, k, -k))


def _ext(d, dx, dy, n=7):
    """d dragged down-right by (dx, dy): the hard extruded drop shadow of 3D lettering."""
    return U(*[_moved(d, dx * k / n, -dy * k / n) for k in range(n + 1)])


def _arrow(x0, y0, x1, y1, w=0.07, head=0.2):
    """A fat wildstyle arrow from (x0, y0) to its point at (x1, y1)."""
    ang = math.atan2(y1 - y0, x1 - x0)
    bx, by = x1 - head * math.cos(ang), y1 - head * math.sin(ang)
    nx, ny = -math.sin(ang), math.cos(ang)
    tip = poly([(x1, y1), (bx + nx * head * 0.62, by + ny * head * 0.62), (bx - nx * head * 0.62, by - ny * head * 0.62)])
    return U(taper(x0, y0, bx, by, w, w * 0.8), tip)


@sticker("oldschool", "bboy", "B-boy", ["#2B2E6B", "#FF3B7F", "#F2C38E", "#E3172F"], ink=1.0)
def _():
    k = 0.78

    C = lambda x, y, r: circle(x * k, y * k, r * k)
    T = lambda ax, ay, bx, by, ra, rb: taper(ax * k, ay * k, bx * k, by * k, ra * k, rb * k)
    O = lambda x, y, rx, ry, a=0.0: oval(x * k, y * k, rx * k, ry * k, a)

    with rotated(-0.3, 0, -0.05):
        pants = U(O(0.0, 0.08, 0.34, 0.24), T(0.12, 0.14, 0.6, 0.78, 0.19, 0.13), T(-0.12, 0.14, -0.52, 0.4, 0.19, 0.14), T(-0.52, 0.4, -0.26, 0.82, 0.14, 0.11))
        shirt = U(T(0.0, -0.46, 0.0, -0.2, 0.32, 0.28), T(0.0, -0.2, 0.0, 0.06, 0.28, 0.26), T(0.24, -0.4, 0.46, -0.54, 0.12, 0.11), T(-0.24, -0.34, -0.5, -0.2, 0.12, 0.11))
        skin = U(C(0.0, -0.66, 0.2), T(0.46, -0.54, 0.56, -0.8, 0.09, 0.085), C(0.56, -0.82, 0.1), T(-0.5, -0.2, -0.7, 0.04, 0.09, 0.085), C(-0.72, 0.08, 0.1))
        hat = U(sub(C(0.0, -0.66, 0.28), C(0.0, -0.42, 0.26)), O(-0.46, -0.72, 0.3, 0.1, 0.3))
        cap = U(hat, O(0.64, 0.86, 0.2, 0.12, 0.5), O(-0.24, 0.9, 0.2, 0.12, -0.9))
    return [pants, shirt, skin, cap]


@sticker("oldschool", "mat", "Battle mat", ["#C98B4B", "#FFE9A8", "#3A1F0A", "#FFFFFF"], ink=1.0)
def _():
    with rotated(0.12):
        mat = box(0, 0, 0.82, 0.74, 0.04)
        tape = U(box(-0.74, 0.58, 0.18, 0.08, 0.01, 0.78), box(0.74, -0.58, 0.18, 0.08, 0.01, 0.78))
    word = U(text("B-", -0.34, 0.3, 1.0, ang=0.12, stretch=0.6, maxw=0.6), text("BOY", 0.06, -0.26, 1.0, ang=0.12, stretch=0.6, maxw=1.4))
    shadow = _ext(word, 0.08, 0.08, 6)
    return [mat, tape, shadow, word]


@sticker("oldschool", "hightop", "Hoops high-top", ["#FFFFFF", "#2F6BFF", "#1A1410", "#FFC531"], ink=1.0)
def _():
    upper = poly(spline([(-0.76, -0.6), (-0.8, -0.1), (-0.72, 0.5), (-0.66, 0.8), (-0.2, 0.82), (-0.1, 0.62), (0.08, 0.3), (0.36, 0.14), (0.66, 0.08),
                         (0.86, -0.1), (0.9, -0.38), (0.84, -0.6)], n=6))
    upper = U(upper, box(-0.1, 0.86, 0.14, 0.09, 0.04, 0.25))
    sole = inter(upper, Y + 0.34)
    panels = U(inter(upper, circle(-0.86, 0.0, 0.5)), inter(upper, circle(0.96, -0.3, 0.38)), inter(upper, box(-0.5, 0.78, 0.4, 0.1)))
    panels = sub(panels, sole)
    laces = U(*[seg(-0.04 + 0.1 * i - 0.075, 0.6 - 0.13 * i - 0.05, -0.04 + 0.1 * i + 0.075, 0.6 - 0.13 * i + 0.05, 0.04) for i in range(4)],
              circle(-0.5, -0.5, 0.09), box(0.34, -0.2, 0.0, 0.0), *[circle(0.5 + 0.1 * i, -0.1 + 0.0 * i, 0.025) for i in range(3)])
    return [upper, panels, sole, laces]


@sticker("oldschool", "hoops", "Hoop earrings", ["#FFC531", "#C98A0C", "#E3172F", "#FFFFFF"], ink=1.0)
def _():
    hoops = U(shell(oval(-0.44, -0.08, 0.34, 0.56), 0.12), shell(oval(0.44, -0.08, 0.34, 0.56), 0.12))
    shade = _rim(hoops, 0.08)
    studs = U(circle(-0.44, 0.68, 0.12), circle(0.44, 0.68, 0.12))
    shine = U(arc(-0.44, -0.08, 0.5, math.radians(120), math.radians(165), 0.04), arc(0.44, -0.08, 0.5, math.radians(120), math.radians(165), 0.04))
    return [hoops, shade, studs, shine]


@sticker("oldschool", "nameplate", "Name plate", ["#FFC531", "#C98A0C", "#FFF4C7", "#1A1410"], ink=1.0)
def _():
    plate = box(0, -0.3, 0.86, 0.46, 0.12)
    chain = U(bezier((-0.56, -0.02), (0.0, 1.1), (0.56, -0.02), 0.09), *[circle(-0.5 + 0.25 * k, 0.0, 0.0) for k in range(1)])
    gold = U(plate, chain)
    shade = _rim(gold, 0.08)
    word = text("FLY", 0, -0.3, 1.0, stretch=0.62, maxw=1.35) - 0.015
    edge = word - 0.05
    return [gold, shade, edge, word]


@sticker("oldschool", "subway", "Subway car", ["#9AA3AF", "#1A1410", "#FFC531", "#FF2D6F"], ink=1.0)
def _():
    car = box(0, 0.0, 0.88, 0.4, 0.1)
    skirt = box(0, -0.42, 0.8, 0.06, 0.03)
    body = U(car, skirt, box(0.84, -0.04, 0.08, 0.2, 0.04))
    windows = U(*[box(-0.64 + 0.32 * k, 0.24, 0.12, 0.1, 0.03) for k in range(5)], skirt, circle(-0.64, -0.56, 0.14), circle(-0.3, -0.56, 0.14),
                circle(0.3, -0.56, 0.14), circle(0.64, -0.56, 0.14), circle(0.84, 0.02, 0.05))
    word = text("DSD", 0, -0.12, 1.0, ang=0.04, stretch=0.62, maxw=1.3) - 0.015
    arrows = U(_arrow(0.5, -0.02, 0.8, 0.2, 0.06, 0.2), _arrow(-0.5, -0.2, -0.78, -0.34, 0.06, 0.18))
    piece = U(word, arrows) - 0.065
    return [body, windows, piece, word]


@sticker("oldschool", "flyer", "Party flyer", ["#FFF1C9", "#FF2D6F", "#1A1410", "#FFD23F"], ink=1.0)
def _():
    with rotated(-0.1):
        paper = box(0, 0, 0.78, 0.86, 0.04)
        bands = U(inter(paper, box(0, 0.72, 1.0, 0.14)), inter(paper, box(0, -0.72, 1.0, 0.14)), circle(-0.44, -0.72, 0.0))
    word = text("JAM", 0, 0.0, 1.2, ang=-0.1, stretch=0.62, maxw=1.25) - 0.025
    outline = word - 0.07
    return [paper, bands, outline, word]


@sticker("oldschool", "hydrant", "Hydrant", ["#E3172F", "#A00F20", "#C9CED6", "#27B8FF"], ink=1.0)
def _():
    cx = 0.3
    barrel = box(cx, -0.26, 0.24, 0.46, 0.04)
    dome = oval(cx, 0.22, 0.3, 0.28)
    base = U(box(cx, -0.7, 0.36, 0.1, 0.04), box(cx, -0.6, 0.28, 0.05, 0.02))
    arms = U(box(cx - 0.36, -0.1, 0.16, 0.14, 0.04), box(cx + 0.36, -0.1, 0.16, 0.14, 0.04))
    body = U(barrel, dome, base, arms, box(cx, 0.28, 0.33, 0.05, 0.02), box(cx, 0.6, 0.09, 0.08, 0.03))
    shade = _rim(body, 0.07)
    caps = U(box(cx - 0.52, -0.1, 0.05, 0.19, 0.02), box(cx + 0.52, -0.1, 0.05, 0.19, 0.02), circle(cx, -0.26, 0.15), box(cx, 0.28, 0.33, 0.04, 0.02),
             box(cx, 0.66, 0.05, 0.04, 0.01))
    jet = poly(spline([(-0.26, -0.02), (-0.52, 0.12), (-0.8, 0.02), (-0.92, -0.28), (-0.9, -0.62), (-0.74, -0.38), (-0.52, -0.2), (-0.26, -0.18)], n=8))
    drops = U(circle(-0.64, 0.4, 0.13), circle(-0.8, -0.74, 0.12))
    water = U(jet, drops)
    return [body, shade, caps, water]


@sticker("oldschool", "scratch", "Scratch", ["#15151B", "#FFC531", "#F2C38E", "#FFFFFF"], ink=1.0)
def _():
    disc = circle(-0.12, -0.16, 0.68)
    label = U(circle(-0.12, -0.16, 0.28), arc(-0.12, -0.16, 0.46, math.radians(20), math.radians(120), 0.04), arc(-0.12, -0.16, 0.58, math.radians(200), math.radians(300), 0.04))
    with rotated(-0.5, 0.5, 0.45, -0.3, -0.3):
        hand = U(box(0.5, 0.45, 0.4, 0.34, 0.14), taper(0.24, 0.62, 0.0, 0.1, 0.13, 0.12), taper(0.5, 0.7, 0.34, 0.1, 0.13, 0.12), taper(0.78, 0.6, 0.66, 0.12, 0.12, 0.11))
    motion = U(arc(-0.12, -0.16, 0.8, math.radians(180), math.radians(240), 0.07))
    return [disc, label, hand, motion]


@sticker("oldschool", "crossfader", "Crossfader", ["#B9BEC8", "#1A1410", "#FFC531", "#FF2D6F"], ink=1.0)
def _():
    plate = box(0, 0, 0.9, 0.56, 0.1)
    slot = U(box(0, -0.12, 0.72, 0.11, 0.055))
    cap = box(0.24, -0.12, 0.22, 0.34, 0.08)
    marks = U(poly([(-0.78, 0.34), (-0.5, 0.5), (-0.5, 0.18)]), poly([(0.78, 0.34), (0.5, 0.5), (0.5, 0.18)]), box(0, 0.34, 0.1, 0.08, 0.03))
    return [plate, slot, cap, marks]


@sticker("oldschool", "mic", "Echo mic", ["#DDE3EC", "#E3172F", "#1A1410", "#27E0FF"], ink=1.0)
def _():
    head = circle(-0.18, 0.28, 0.44)
    handle = taper(-0.12, -0.04, 0.5, -0.74, 0.2, 0.12)
    mic = U(head, handle)
    band = U(box(0.02, -0.12, 0.22, 0.08, 0.02, -0.82), arc(-0.18, 0.28, 0.3, math.radians(100), math.radians(170), 0.06))
    cord = brush([(0.5, -0.78), (0.22, -0.88), (-0.1, -0.78)], [0.09] * 3)
    echo = U(arc(-0.18, 0.28, 0.66, math.radians(-25), math.radians(40), 0.08), arc(-0.18, 0.28, 0.86, math.radians(-25), math.radians(40), 0.08))
    return [mic, band, cord, echo]


@sticker("oldschool", "spotlight", "Spotlight", ["#FFE14A", "#2B2E33", "#111114", "#FFC531"], ink=1.0)
def _():
    beam = poly([(-0.2, 0.3), (0.9, 0.9), (0.9, -0.6), (-0.2, -0.2)])
    lamp = U(circle(-0.4, 0.04, 0.46), box(-0.4, -0.66, 0.1, 0.16, 0.03), box(-0.4, -0.78, 0.34, 0.07, 0.03))
    shade = _rim(lamp, 0.08)
    lens = U(circle(-0.4, 0.04, 0.3), ring(-0.4, 0.04, 0.42, 0.05))
    return [beam, lamp, shade, lens]


@sticker("oldschool", "jacket", "Track jacket", ["#27E0FF", "#1296B3", "#FFC531", "#1A1410"], ink=1.0)
def _():
    torso = box(0, -0.04, 0.42, 0.64, 0.08)
    sleeves = U(taper(-0.4, 0.5, -0.78, -0.4, 0.17, 0.15), taper(0.4, 0.5, 0.78, -0.4, 0.17, 0.15))
    body = U(torso, sleeves)
    shade = U(_rim(body, 0.08))
    cuffs = U(taper(-0.7, -0.22, -0.78, -0.4, 0.17, 0.16), taper(0.7, -0.22, 0.78, -0.4, 0.17, 0.16), box(0, 0.72, 0.28, 0.13, 0.05), box(0, -0.62, 0.43, 0.09, 0.03))
    zip_ = U(seg(0, 0.64, 0, -0.6, 0.04), circle(0, 0.3, 0.07))
    return [body, shade, cuffs, zip_]


@sticker("oldschool", "windmill", "Spin burst", ["#FFD23F", "#E0861A", "#FFFFFF", "#FF2D6F"], ink=1.0)
def _():
    blades = []
    for k in range(3):
        with rotated(k * 2.0944):
            blades.append(brush([(0.1, 0.0), (0.46, 0.04), (0.68, 0.34), (0.54, 0.66)], [0.12, 0.19, 0.16, 0.02]))
    swirl = U(*blades)
    shade = _rim(swirl, 0.07)
    core = circle(0, 0, 0.26)
    dots = ring(0, 0, 0.14, 0.06)
    return [swirl, shade, core, dots]


@sticker("oldschool", "medallion", "Dollar medallion", ["#FFC531", "#C98A0C", "#1A1410", "#FFF4C7"], ink=1.0)
def _():
    disc = U(circle(0, -0.1, 0.76), taper(0, 0.6, 0, 0.84, 0.11, 0.11))
    beads = U(*[circle(0.66 * math.cos(a), -0.1 + 0.66 * math.sin(a), 0.055) for a in np.linspace(0, 2 * math.pi, 15)[:-1]])
    shade = U(_rim(disc, 0.09), beads)
    sign = text("$", 0, -0.1, 0.9, maxw=0.8)
    shine = U(arc(0, -0.1, 0.5, math.radians(110), math.radians(170), 0.045), star(0.52, 0.5, 4, 0.2, 0.05))
    return [disc, shade, sign, shine]


@sticker("oldschool", "phat", "PHAT", ["#1A1410", "#FFD23F", "#FF3B2F", "#FFFFFF"], ink=1.0)
def _():
    word = text("PHAT", 0, 0.08, 1.2, ang=0.1, stretch=0.42, maxw=1.5) - 0.03
    letters = word
    outline = word - 0.07
    shadow = _ext(outline, 0.11, 0.11, 8)
    shine = U(_glint(letters, 0.035), star(0.76, 0.6, 4, 0.17, 0.045), star(-0.74, -0.5, 4, 0.12, 0.035))
    return [shadow, outline, letters, shine]
