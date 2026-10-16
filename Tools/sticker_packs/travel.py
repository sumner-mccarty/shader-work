# Travel — suitcases, planes, maps and the tour life. Run by Tools/decor_stickers.py (every helper is in scope).
PACK = ("travel", "Travel", False)
PRO_IDS = {"suitcase", "balloon", "bus", "compass", "ontour"}


def _moved(d, dx, dy):
    """Layer d slid by (dx, dy) slice units (y up); what slides in from the edge is far outside."""
    px, py = int(round(dx * N / 2)), int(round(dy * N / 2))
    out = np.full_like(d, BIG)
    h, w = d.shape
    rs, rd = (slice(py, h), slice(0, h - py)) if py >= 0 else (slice(0, h + py), slice(-py, h))
    cs, cd = (slice(0, w - px), slice(px, w)) if px >= 0 else (slice(-px, w), slice(0, w + px))
    out[rd, cd] = d[rs, cs]
    return out


def _rim(d, k=0.09):
    """The lower-right rim of d: d minus itself slid up-left — the house shade."""
    return sub(d, _moved(d, -k, k))


@sticker("travel", "suitcase", "Suitcase", ["#FF7A1A", "#5A3A22", "#FFF4C7", "#FFC531"], ink=1.0)
def _():
    case = box(0, -0.12, 0.8, 0.56, 0.1)
    trim = U(sub(box(0, 0.56, 0.24, 0.17, 0.07), box(0, 0.53, 0.14, 0.09, 0.03)), box(-0.52, -0.12, 0.065, 0.56), box(0.52, -0.12, 0.065, 0.56),
             _rim(case, 0.08))
    patches = U(box(-0.26, -0.02, 0.17, 0.13, 0.03, ang=0.3), circle(0.1, -0.3, 0.14), star(0.17, 0.1, 5, 0.17, 0.075))
    clasps = U(box(-0.2, 0.4, 0.07, 0.06, 0.02), box(0.2, 0.4, 0.07, 0.06, 0.02), circle(-0.55, -0.72, 0.075), circle(0.55, -0.72, 0.075))
    return [case, trim, patches, clasps]


@sticker("travel", "tourstamp", "Tour stamp", ["#FFF4DC", "#2B2E8F", "#E3172F", "#2B2E8F"], ink=1.0)
def _():
    paper = U(circle(0, 0, 0.8), *[circle(0.82 * math.cos(k * math.pi / 8), 0.82 * math.sin(k * math.pi / 8), 0.09) for k in range(16)])
    border = U(shell(circle(0, 0, 0.7), 0.04), shell(circle(0, 0, 0.56), 0.025))
    word = text("TOUR", 0, 0.0, 0.46, ang=0.14, stretch=0.9, maxw=1.0)
    marks = U(star(-0.04, 0.38, 5, 0.12, 0.052), star(0.04, -0.38, 5, 0.12, 0.052))
    return [paper, border, word, marks]


@sticker("travel", "plane", "Plane", ["#9FE8FF", "#F4F1EA", "#E3172F", "#1B3A8C"], ink=1.0)
def _():
    trail = U(brush([(-0.9, -0.55), (-0.62, -0.62), (-0.36, -0.42), (-0.1, -0.2)], [0.05, 0.09, 0.12, 0.14]),
              brush([(-0.7, -0.8), (-0.42, -0.84), (-0.2, -0.62), (0.0, -0.45)], [0.04, 0.07, 0.09, 0.1]))
    with rotated(-0.78, 0.1, 0.1):
        fus = oval(0.1, 0.1, 0.12, 0.82)
        wings = U(poly([(0.02, 0.28), (-0.78, -0.2), (-0.78, -0.42), (0.02, -0.12)]), poly([(0.18, 0.28), (0.98, -0.2), (0.98, -0.42), (0.18, -0.12)]),
                  poly([(0.04, -0.5), (-0.32, -0.76), (-0.32, -0.88), (0.04, -0.72)]), poly([(0.16, -0.5), (0.52, -0.76), (0.52, -0.88), (0.16, -0.72)]))
        plane_ = U(fus, wings)
        trim = U(circle(-0.5, -0.28, 0.08), circle(0.7, -0.28, 0.08), seg(0.1, -0.56, 0.1, -0.84, 0.045), inter(plane_, box(0.1, 0.5, 0.2, 0.04)))
        windows = U(*[circle(0.1, 0.1 + k * 0.17, 0.05) for k in range(-1, 3)], oval(0.1, 0.72, 0.06, 0.09))
    return [trail, plane_, trim, windows]


@sticker("travel", "globe", "Globe", ["#1FB6FF", "#0B6DB8", "#2EC46A", "#FFC531"], ink=1.0)
def _():
    globe = circle(0, 0.1, 0.58)
    shade = _rim(globe, 0.1)
    land = inter(globe, U(smin(oval(-0.22, 0.3, 0.2, 0.26, 0.4), oval(-0.1, -0.05, 0.12, 0.3, -0.25), 0.1), oval(0.3, 0.3, 0.2, 0.14), oval(0.28, -0.1, 0.14, 0.18, 0.5)))
    stand = U(arc(0, 0.1, 0.74, 3.6, 5.8, 0.045), box(0, -0.8, 0.34, 0.07, 0.03), seg(0, -0.7, 0, -0.78, 0.07), circle(0, 0.84, 0.05))
    return [globe, shade, land, stand]


@sticker("travel", "balloon", "Hot air balloon", ["#FF5A1F", "#FFD400", "#D93A0A", "#8A5A33"], ink=1.0)
def _():
    balloon = smin(circle(0, 0.3, 0.56), poly([(-0.3, -0.2), (0.3, -0.2), (0.14, -0.4), (-0.14, -0.4)]) - 0.03, 0.2)
    stripe = inter(balloon, U(oval(0, 0.3, 0.2, 0.7), box(0, -0.32, 0.12, 0.2)))
    shade = _rim(balloon, 0.1)
    face = U(circle(-0.18, 0.36, 0.08), circle(0.18, 0.36, 0.08), arc(0, 0.28, 0.2, -2.9, -0.24, 0.05), box(0, -0.76, 0.2, 0.13, 0.03), seg(-0.2, -0.4, -0.16, -0.64, 0.025), seg(0.2, -0.4, 0.16, -0.64, 0.025), seg(-0.1, -0.4, -0.1, -0.64, 0.02), seg(0.1, -0.4, 0.1, -0.64, 0.02))
    return [balloon, stripe, shade, face]


@sticker("travel", "bus", "Tour bus", ["#FF2D9B", "#9FE8FF", "#2B2E33", "#FFD400"], ink=1.0)
def _():
    body = U(box(0, -0.2, 0.88, 0.28, 0.08), box(-0.1, 0.22, 0.74, 0.2, 0.08))
    windows = U(*[box(-0.64 + k * 0.38, -0.06, 0.15, 0.1, 0.02) for k in range(4)], *[box(-0.62 + k * 0.32, 0.24, 0.12, 0.1, 0.02) for k in range(4)],
                box(0.7, -0.06, 0.1, 0.1, 0.02))
    wheels = U(circle(-0.5, -0.5, 0.16), circle(0.5, -0.5, 0.16))
    trim = U(box(0, -0.34, 0.88, 0.04), circle(-0.5, -0.5, 0.06), circle(0.5, -0.5, 0.06), circle(0.82, -0.28, 0.05))
    return [body, windows, wheels, trim]


@sticker("travel", "pin", "Map pin", ["#E3172F", "#A80F20", "#FFFFFF", "#1B6FE0"], ink=1.0)
def _():
    pin = smin(circle(0, 0.22, 0.5), poly([(-0.4, 0.0), (0.4, 0.0), (0, -0.62)]) - 0.02, 0.12)
    shade = _rim(pin, 0.09)
    dot = U(circle(0, 0.22, 0.2), seg(-0.34, 0.5, -0.24, 0.62, 0.035))
    ripple = sub(oval(0, -0.68, 0.66, 0.18), pin - 0.03)
    return [pin, shade, dot, ripple]


@sticker("travel", "compass", "Compass", ["#FFC531", "#FFF4DC", "#E3172F", "#2B2E33"], ink=1.0)
def _():
    case = U(circle(0, -0.04, 0.82), box(0, 0.82, 0.12, 0.09, 0.04))
    face = circle(0, -0.04, 0.64)
    north = poly(rotp([(0, 0.56), (-0.14, -0.04), (0.14, -0.04)], -0.6, 0, -0.04))
    south = U(poly(rotp([(0, -0.64), (-0.14, -0.04), (0.14, -0.04)], -0.6, 0, -0.04)), circle(0, -0.04, 0.06),
              box(0, 0.5, 0.025, 0.07), box(0, -0.58, 0.025, 0.07), box(-0.54, -0.04, 0.07, 0.025), box(0.54, -0.04, 0.07, 0.025))
    return [case, face, north, south]


@sticker("travel", "camera", "Camera", ["#C9CED6", "#2B2E33", "#5A6070", "#1FB6FF"], ink=1.0)
def _():
    body = U(box(0, -0.12, 0.86, 0.5, 0.1), box(-0.52, 0.48, 0.2, 0.1, 0.04), box(0.2, 0.46, 0.3, 0.1, 0.04))
    band = inter(body, -(Y - 0.12)) 
    lens = circle(0, -0.1, 0.4)
    glass = U(circle(0, -0.1, 0.24), box(0.58, 0.36, 0.12, 0.07, 0.02))
    return [body, band, lens, glass]


@sticker("travel", "duffel", "Duffel", ["#2B6BD6", "#1B3FA0", "#C98B4B", "#FFD400"], ink=1.0)
def _():
    bag = U(box(0, -0.2, 0.62, 0.4, 0.2), oval(-0.62, -0.2, 0.2, 0.4), oval(0.62, -0.2, 0.2, 0.4))
    caps = U(oval(-0.62, -0.2, 0.2, 0.4), _rim(bag, 0.09))
    handles = U(arc(0, 0.16, 0.36, 0.2, 2.94, 0.1), seg(-0.62, 0.2, 0.62, 0.2, 0.04))
    tag = U(box(0.4, -0.66, 0.14, 0.16, 0.03), seg(0.4, -0.52, 0.44, -0.4, 0.03))
    return [bag, caps, handles, tag]


@sticker("travel", "train", "Train", ["#E3172F", "#9FE8FF", "#FFD400", "#2B2E33"], ink=1.0)
def _():
    body = box(0, 0.04, 0.58, 0.78, 0.22)
    windows = U(box(0, 0.38, 0.42, 0.24, 0.1), box(-0.3, -0.06, 0.1, 0.0001))
    lights = U(circle(-0.3, -0.26, 0.1), circle(0.3, -0.26, 0.1), box(0, -0.58, 0.5, 0.07, 0.03), box(0, 0.7, 0.2, 0.05, 0.02))
    bumper = U(box(0, -0.06, 0.5, 0.04), box(-0.36, -0.82, 0.14, 0.06), box(0.36, -0.82, 0.14, 0.06), circle(0, -0.2, 0.07), seg(-0.2, 0.42, 0.2, 0.42, 0.03))
    return [body, windows, lights, bumper]


@sticker("travel", "gigpass", "Boarding pass", ["#F4F1EA", "#1B6FE0", "#141418", "#E3172F"], ink=1.0)
def _():
    card = sub(box(0, 0, 0.88, 0.5, 0.07), U(circle(0.5, 0.5, 0.1), circle(0.5, -0.5, 0.1)))
    header = inter(card, -(Y - 0.2))
    code = U(text("GIG", -0.3, -0.12, 0.56, stretch=0.9, maxw=0.95), *[box(x, -0.12, w, 0.24) for x, w in ((0.64, 0.03), (0.72, 0.05), (0.82, 0.03))])
    glyph = U(seg(-0.76, 0.34, -0.3, 0.34, 0.05), poly([(-0.6, 0.34), (-0.46, 0.5), (-0.38, 0.5), (-0.46, 0.34)]), poly([(-0.6, 0.34), (-0.46, 0.18), (-0.38, 0.18), (-0.46, 0.34)]),
              box(0.3, 0.34, 0.1, 0.045))
    return [card, header, code, glyph]


@sticker("travel", "postcard", "Postcard", ["#FFF4DC", "#4DB8FF", "#2EC46A", "#E3172F"], ink=1.0)
def _():
    with rotated(0.2):
        card = box(0, 0, 0.88, 0.58, 0.05)
        photo = box(-0.4, 0.0, 0.4, 0.44, 0.03)
        hills = inter(photo, poly([(-0.9, -0.5), (-0.7, -0.05), (-0.5, -0.2), (-0.26, 0.14), (0.0, -0.5)]))
        marks = U(box(0.5, 0.26, 0.22, 0.2, 0.03), seg(0.14, -0.08, 0.8, -0.08, 0.04), seg(0.14, -0.26, 0.8, -0.26, 0.04), seg(0.14, -0.44, 0.56, -0.44, 0.04),
                  circle(-0.28, 0.28, 0.09))
    return [card, photo, hills, marks]


@sticker("travel", "roadsign", "Mountain sign", ["#FFD400", "#141418", "#FFFFFF", "#FF8A00"], ink=1.0)
def _():
    sign = box(0, 0, 0.62, 0.62, 0.1, ang=math.pi / 4)
    mount = U(shell(box(0, 0, 0.52, 0.52, 0.06, ang=math.pi / 4), 0.03),
              poly([(-0.46, -0.3), (-0.14, 0.24), (0.04, -0.04), (0.2, 0.3), (0.5, -0.3)]) - 0.02)
    snow = U(poly([(-0.24, 0.07), (-0.14, 0.24), (-0.04, 0.07), (-0.14, 0.12)]), poly([(0.12, 0.14), (0.2, 0.3), (0.28, 0.14), (0.2, 0.18)]))
    road = brush([(0.0, -0.3), (0.12, -0.18), (-0.08, -0.04), (0.04, 0.1)], [0.07, 0.05, 0.035, 0.02])
    return [sign, mount, snow, road]


@sticker("travel", "sailboat", "Sailboat", ["#FFF4DC", "#E3172F", "#1FB6FF", "#8A5A33"], ink=1.0)
def _():
    sails = U(poly([(0.04, 0.72), (0.04, -0.2), (0.62, -0.2)]), poly([(-0.06, 0.6), (-0.06, -0.2), (-0.56, -0.2)]))
    hull = poly([(-0.66, -0.3), (0.7, -0.3), (0.46, -0.58), (-0.42, -0.58)]) - 0.03
    waves = sub(box(0, -0.74, 0.88, 0.12, 0.04), U(*[circle(x, -0.62, 0.11) for x in (-0.7, -0.35, 0.0, 0.35, 0.7)]))
    mast = U(seg(0, 0.78, 0, -0.3, 0.055), poly([(0.0, 0.82), (0.26, 0.76), (0.0, 0.68)]))
    return [sails, hull, waves, mast]


@sticker("travel", "ontour", "On tour", ["#1B3A8C", "#FFD400", "#E3172F", "#FFFFFF"], ink=1.0)
def _():
    disc = circle(0, 0, 0.9)
    route = U(*[circle(0.7 * math.cos(a), 0.7 * math.sin(a), 0.05) for a in [0.45 + k * 0.17 for k in range(12)]],
              *[circle(0.7 * math.cos(a), 0.7 * math.sin(a), 0.05) for a in [3.59 + k * 0.17 for k in range(12)]],
              star(-0.5, 0.56, 5, 0.15, 0.065), star(0.5, -0.56, 5, 0.15, 0.065))
    banner = box(0, 0, 0.88, 0.34, 0.03, ang=0.15)
    word = text("ON TOUR", 0, 0.0, 0.5, ang=0.15, stretch=0.6, maxw=1.45)
    return [disc, route, banner, word]
