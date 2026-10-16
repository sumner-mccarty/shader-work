# Golden Era — the 90s: pagers, jerseys, lowriders, gold and gear. Run by Tools/decor_stickers.py.
PACK = ("goldenera", "Golden Era", False)
PRO_IDS = {"lowrider", "fresh", "jersey", "puffer", "pixelpet", "loud"}


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


@sticker("goldenera", "pager", "Pager", ["#7A2CFF", "#3F0FA8", "#B9F27A", "#1A1410"], ink=1.0)
def _():
    with rotated(-0.12):
        body = box(0, -0.05, 0.8, 0.54, 0.1)
        clip = box(0, 0.62, 0.3, 0.1, 0.04)
        shell_ = U(body, clip)
        shade = _rim(body, 0.08)
        screen = box(0, 0.06, 0.64, 0.3, 0.05)
        btns = U(circle(-0.46, -0.38, 0.1), circle(-0.16, -0.38, 0.1), circle(0.14, -0.38, 0.1), circle(0.44, -0.38, 0.1))
    word = text("BEEP", 0, 0.04, 1.0, ang=-0.12, maxw=1.2, stretch=0.55)
    lettering = U(word, btns)
    return [shell_, shade, screen, lettering]


@sticker("goldenera", "brickphone", "Brick phone", ["#2B2E33", "#1A1410", "#FFD23F", "#FF3B2F"], ink=1.0)
def _():
    with rotated(0.18):
        body = U(box(0, -0.08, 0.4, 0.78, 0.1), taper(-0.22, 0.7, -0.24, 0.9, 0.1, 0.1))
        shade = _rim(body, 0.08)
        keys = U(*[box(-0.2 + 0.2 * i, -0.52 + 0.19 * j, 0.075, 0.07, 0.02) for i in range(3) for j in range(3)])
        screen = box(0.0, 0.52, 0.26, 0.14, 0.03)
    return [body, shade, keys, screen]


@sticker("goldenera", "jersey", "Jersey", ["#E3172F", "#9D1220", "#FFFFFF", "#FFD23F"], ink=1.0)
def _():
    torso = box(0, -0.2, 0.6, 0.7, 0.1)
    straps = U(box(-0.36, 0.62, 0.17, 0.26, 0.05), box(0.36, 0.62, 0.17, 0.26, 0.05))
    cut = U(circle(-0.8, 0.42, 0.4), circle(0.8, 0.42, 0.4), circle(0, 0.92, 0.3))
    body = sub(U(torso, straps), cut)
    shade = _rim(body, 0.08)
    trim = inter(body, U(shell(circle(-0.8, 0.42, 0.4), 0.045), shell(circle(0.8, 0.42, 0.4), 0.045), shell(circle(0, 0.92, 0.3), 0.045),
                          box(0, -0.84, 0.7, 0.045)))
    number = U(shell(oval(-0.22, -0.2, 0.15, 0.3), 0.075), shell(oval(0.22, -0.2, 0.15, 0.3), 0.075))
    return [body, shade, trim, number]


@sticker("goldenera", "boots", "Work boots", ["#E3B25E", "#B07A2C", "#7A4A1E", "#FFF1C9"], ink=1.0)
def _():
    upper = poly(spline([(-0.62, -0.46), (-0.66, 0.2), (-0.6, 0.78), (-0.12, 0.8), (-0.04, 0.2), (0.3, -0.02), (0.74, -0.08), (0.86, -0.3),
                         (0.8, -0.46)], n=7))
    shade = U(_rim(upper, 0.08), inter(upper, box(0, -0.45, 1, 0.05)))
    sole = U(box(0.1, -0.64, 0.82, 0.14, 0.04), *[box(-0.62 + 0.22 * k, -0.78, 0.07, 0.04, 0.01) for k in range(7)])
    laces = U(*[box(-0.36, 0.64 - 0.15 * k, 0.17, 0.04, 0.02, 0.15) for k in range(5)], circle(-0.36, 0.82, 0.045), taper(-0.5, 0.78, -0.64, 0.66, 0.05, 0.05))
    return [upper, shade, sole, laces]


@sticker("goldenera", "camera", "Snap camera", ["#FFC531", "#E3172F", "#2B2E33", "#FFFFFF"], ink=1.0)
def _():
    body = box(0, -0.06, 0.52, 0.82, 0.1)
    top = U(box(-0.3, 0.84, 0.18, 0.06, 0.03), circle(0.34, 0.8, 0.14))
    wrap = U(body, top)
    band = inter(body, box(0, -0.46, 1.0, 0.16))
    lens = U(circle(0.0, 0.16, 0.26), box(-0.3, 0.6, 0.14, 0.08, 0.03), box(0.28, 0.6, 0.1, 0.08, 0.03))
    glass = U(circle(0.0, 0.16, 0.12), circle(-0.08, 0.22, 0.04))
    return [wrap, band, lens, glass]


@sticker("goldenera", "cd", "CD", ["#E6EEF7", "#3A3F47", "#FF2D6F", "#9AE0FF"], ink=1.0)
def _():
    disc = sub(circle(0.3, -0.06, 0.64), circle(0.3, -0.06, 0.13))
    case = box(-0.3, 0.0, 0.58, 0.74, 0.05)
    spine = box(-0.76, 0.0, 0.1, 0.72, 0.03)
    shine = U(seg(-0.5, 0.45, -0.1, 0.62, 0.055), seg(-0.58, 0.18, -0.38, 0.28, 0.045), arc(0.3, -0.06, 0.42, math.radians(30), math.radians(70), 0.04))
    return [disc, case, spine, shine]


@sticker("goldenera", "cdplayer", "CD player", ["#FF2D6F", "#C9CED6", "#27B8FF", "#1A1410"], ink=1.0)
def _():
    phones = U(arc(0, -0.1, 0.76, math.radians(15), math.radians(165), 0.09), box(-0.8, -0.14, 0.14, 0.28, 0.07), box(0.8, -0.14, 0.14, 0.28, 0.07))
    body = circle(0, -0.2, 0.6)
    window = U(sub(circle(0, -0.2, 0.46), circle(0, -0.2, 0.12)))
    buttons = U(circle(0, -0.2, 0.1), circle(-0.28, -0.78, 0.07), circle(0.28, -0.78, 0.07), seg(-0.5, 0.2, -0.22, 0.4, 0.035), ring(0, -0.2, 0.46, 0.03))
    return [phones, body, window, buttons]


@sticker("goldenera", "mixtape", "Mixtape", ["#FFF1C9", "#D8B67A", "#2F6BFF", "#E3172F"], ink=1.0)
def _():
    with rotated(0.1):
        card = box(0, 0, 0.88, 0.62, 0.04)
        shade = U(_rim(card, 0.08), box(0.5, 0.0, 0.025, 0.62))
        marks = U(box(-0.1, -0.5, 0.62, 0.065, 0.03), box(0.5, 0.5, 0.2, 0.065, 0.03), circle(-0.72, -0.5, 0.07), circle(0.72, -0.5, 0.07))
    title = text("MIX", -0.02, 0.06, 1.2, ang=0.1, stretch=0.5, maxw=1.4) - 0.03
    return [card, shade, marks, title]


@sticker("goldenera", "lowrider", "Lowrider", ["#A62CFF", "#4A0F86", "#1A1410", "#E6EEF7"], ink=1.0)
def _():
    with rotated(-0.15, 0, 0.0, 0.0, 0.02):
        hull = U(box(0.0, -0.08, 0.9, 0.2, 0.08), poly(spline([(-0.34, 0.06), (-0.22, 0.4), (0.26, 0.4), (0.42, 0.06)], closed=True, n=6)))
        wells = U(circle(-0.5, -0.16, 0.26), circle(0.5, -0.16, 0.26))
        shade = U(_rim(hull, 0.07), wells)
        wheels = U(circle(-0.5, -0.44, 0.22), circle(0.5, -0.16, 0.22))
        chrome = U(poly([(-0.28, 0.09), (-0.18, 0.35), (0.04, 0.35), (0.04, 0.09)]), poly([(0.12, 0.09), (0.12, 0.35), (0.24, 0.35), (0.36, 0.09)]),
                   box(0.0, -0.08, 0.7, 0.03), circle(-0.5, -0.44, 0.09), circle(0.5, -0.16, 0.08), box(0.9, -0.06, 0.05, 0.06, 0.02), box(-0.9, -0.06, 0.05, 0.06, 0.02))
    return [hull, shade, wheels, chrome]


@sticker("goldenera", "payphone", "Pay phone", ["#2F6BFF", "#1F46B0", "#C9CED6", "#1A1410"], ink=1.0)
def _():
    body = U(box(0.12, -0.04, 0.5, 0.78, 0.07), box(0.12, 0.74, 0.58, 0.1, 0.04))
    shade = _rim(body, 0.08)
    keys = U(*[box(0.0 + 0.22 * i, -0.12 - 0.19 * j, 0.075, 0.07, 0.02) for i in range(3) for j in range(3)], box(0.12, 0.46, 0.28, 0.1, 0.03), box(0.56, 0.2, 0.05, 0.12, 0.02))
    handset = U(taper(-0.52, 0.52, -0.52, -0.06, 0.12, 0.12), circle(-0.52, 0.56, 0.17), circle(-0.52, -0.06, 0.17),
                brush([(-0.44, -0.2), (-0.2, -0.4), (-0.4, -0.62), (-0.1, -0.84)], [0.045, 0.045, 0.045, 0.045]))
    return [body, shade, keys, handset]


@sticker("goldenera", "hoopfence", "Hoop & fence", ["#7F8896", "#FFFFFF", "#FF8A00", "#E3172F"], ink=1.0)
def _():
    mesh = U(seg(-0.9, 0.1, 0.1, -0.9, 0.09), seg(-0.1, 0.9, 0.9, -0.1, 0.09), seg(-0.9, -0.1, 0.1, 0.9, 0.09), seg(-0.1, -0.9, 0.9, 0.1, 0.09))
    backboard = box(0, 0.26, 0.6, 0.42, 0.06)
    hoop = U(oval(0, -0.18, 0.44, 0.1), taper(-0.42, -0.18, -0.26, -0.78, 0.07, 0.055), taper(0.42, -0.18, 0.26, -0.78, 0.07, 0.055),
             taper(0.0, -0.18, 0.0, -0.8, 0.06, 0.05))
    target = shell(box(0, 0.2, 0.24, 0.18, 0.03), 0.05)
    return [mesh, backboard, hoop, target]


@sticker("goldenera", "loud", "Loud label", ["#FF2D6F", "#1A1410", "#FFE14A", "#FFFFFF"], ink=1.0)
def _():
    label = box(0, 0, 0.9, 0.6, 0.05)
    label = sub(label, U(circle(-0.9, 0, 0.14), circle(0.9, 0, 0.14)))
    word = text("LOUD", 0.0, -0.1, 1.0, stretch=0.55, maxw=1.4)
    shadow = _ext(word, 0.08, 0.08, 6)
    speaker = U(box(-0.66, 0.42, 0.07, 0.08, 0.02), poly([(-0.62, 0.48), (-0.48, 0.56), (-0.48, 0.28), (-0.62, 0.36)]),
                arc(-0.44, 0.42, 0.14, math.radians(-40), math.radians(40), 0.04), box(0.1, 0.46, 0.5, 0.05, 0.02))
    return [label, shadow, word, speaker]


@sticker("goldenera", "puffer", "Puffy jacket", ["#FF8A00", "#C45A00", "#FFF1C9", "#1A1410"], ink=1.0)
def _():
    puffs = U(*[box(0, 0.62 - 0.3 * k, 0.4, 0.17, 0.15) for k in range(5)])
    sleeves = U(*[circle(-0.54 - 0.06 * k, 0.5 - 0.3 * k, 0.17) for k in range(4)], *[circle(0.54 + 0.06 * k, 0.5 - 0.3 * k, 0.17) for k in range(4)],
                taper(-0.4, 0.62, -0.6, 0.0, 0.17, 0.17), taper(0.4, 0.62, 0.6, 0.0, 0.17, 0.17))
    body = U(puffs, sleeves)
    shade = _rim(body, 0.07)
    collar = box(0, 0.82, 0.3, 0.1, 0.05)
    cuffs = U(box(-0.8, -0.58, 0.14, 0.06, 0.02, 0.2), box(0.8, -0.58, 0.14, 0.06, 0.02, -0.2))
    trim = U(collar, cuffs)
    zip_ = U(seg(0, 0.76, 0, -0.64, 0.035))
    return [body, shade, trim, zip_]


@sticker("goldenera", "overalls", "Overalls", ["#3F6FD8", "#2447A0", "#6E9BFF", "#FFC531"], ink=1.0)
def _():
    bib = box(0, 0.3, 0.36, 0.38, 0.05)
    legs = U(poly([(-0.46, -0.06), (-0.04, -0.06), (-0.08, -0.84), (-0.46, -0.84)]), poly([(0.04, -0.06), (0.46, -0.06), (0.46, -0.84), (0.08, -0.84)]))
    strap_up = taper(0.24, 0.62, 0.42, 0.86, 0.1, 0.09)
    strap_down = U(taper(-0.26, 0.62, -0.58, 0.3, 0.13, 0.13), taper(-0.58, 0.3, -0.6, -0.14, 0.13, 0.13))
    body = U(bib, legs, strap_up, strap_down, box(0, -0.06, 0.46, 0.1, 0.04))
    shade = _rim(body, 0.07)
    pocket = box(0, 0.22, 0.22, 0.16, 0.03)
    buttons = U(circle(-0.26, 0.58, 0.08), circle(0.26, 0.58, 0.08), circle(-0.6, -0.16, 0.1))
    return [body, shade, pocket, buttons]


@sticker("goldenera", "pixelpet", "Pixel pet", ["#FF2D6F", "#B01046", "#B9F27A", "#1A1410"], ink=1.0)
def _():
    egg = U(oval(0, -0.12, 0.64, 0.74), taper(0, 0.62, 0, 0.84, 0.09, 0.09))
    shade = _rim(egg, 0.09)
    screen = box(0, 0.1, 0.4, 0.34, 0.08)
    pet = pix([".#...#.", "#######", "##.#.##", "#######", ".#####.", "..#.#.."], 0, 0.1, 0.085)
    btns = U(circle(-0.3, -0.5, 0.09), circle(0, -0.54, 0.09), circle(0.3, -0.5, 0.09), pet)
    return [egg, shade, screen, btns]


@sticker("goldenera", "fresh", "FRESH", ["#FF2D6F", "#2A1250", "#FFC531", "#E0861A"], ink=1.0)
def _():
    word = text("FRESH", 0, 0.0, 1.2, stretch=0.4, maxw=1.5) - 0.02
    burst = star(0, 0, 12, 0.92, 0.66, 0.2)
    outline = word - 0.075
    letters = word
    chrome = inter(word, Y + 0.02)
    return [burst, outline, letters, chrome]
