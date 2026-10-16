PACK = ("jazz", "Jazz Club", False)
PRO_IDS = {"sax", "trumpet", "live", "skyline", "coolcat"}


def _lowright(d, c=0.3):
    """The lower-right slice of shape d (the one shade layer)."""
    return inter(d, c - (X - Y) * 0.7)


@sticker("jazz", "sax", "Saxophone", ["#FFC531", "#E09A12", "#8A5A1E", "#2B2E33"], ink=1.0)
def _():
    body = U(brush([(-0.46, 0.78), (-0.18, 0.7), (0.0, 0.36), (0.02, -0.3), (0.1, -0.66), (0.4, -0.7), (0.58, -0.38)],
                   [0.09, 0.11, 0.15, 0.17, 0.18, 0.18, 0.2]), ellipse(0.6, -0.3, 0.26, 0.12, 1.2))
    shade = _lowright(body, 0.2)
    keys = U(*[circle(0.02, y, 0.075) for y in (0.3, 0.06, -0.18)], circle(0.2, -0.4, 0.07))
    mouth = taper(-0.5, 0.78, -0.82, 0.68, 0.07, 0.11)
    return [body, shade, keys, mouth]


@sticker("jazz", "trumpet", "Trumpet", ["#FFC531", "#E09A12", "#F4F1EA", "#8A5A1E"], ink=1.0)
def _():
    with rotated(-0.25):
        tube = shell(box(-0.1, -0.12, 0.44, 0.22, 0.2), 0.075)
        bell = poly([(0.3, 0.08), (0.8, 0.46), (0.8, -0.7), (0.3, -0.32)])
        lead = seg(-0.85, 0.1, -0.5, 0.1, 0.06)
        body = U(tube, bell, lead)
        shade = _lowright(body, 0.2)
        valves = U(*[box(x, 0.2, 0.06, 0.2) for x in (-0.3, -0.1, 0.1)], *[circle(x, 0.42, 0.08) for x in (-0.3, -0.1, 0.1)])
        mouth = box(-0.88, 0.1, 0.08, 0.1, 0.04)
    return [body, shade, valves, mouth]


@sticker("jazz", "bass", "Upright bass", ["#E0955A", "#A8602E", "#3A2418", "#2B1A12"], ink=1.0)
def _():
    with rotated(0.2, 0.0, 0.0, 0.0, -0.06):
        body = smin(smin(circle(0, -0.44, 0.4), circle(0, -0.02, 0.26), 0.16), circle(0, 0.16, 0.2), 0.1)
        shade = _lowright(body, 0.2)
        neck = U(box(0, 0.58, 0.09, 0.28), circle(0, 0.9, 0.13), box(0, -0.88, 0.04, 0.06))
        holes = U(ellipse(-0.17, -0.4, 0.06, 0.17, 0.2), ellipse(0.17, -0.4, 0.06, 0.17, -0.2), box(0, -0.55, 0.12, 0.035))
    return [body, shade, neck, holes]


@sticker("jazz", "brush", "Drum brush", ["#2B2E33", "#C9CED6", "#8A8F98", "#FF4F4F"], ink=1.0)
def _():
    handle = taper(-0.8, -0.74, -0.18, -0.12, 0.09, 0.07)
    fan = U(*[taper(-0.14, -0.08, -0.14 + 0.82 * math.cos(math.radians(a)), -0.08 + 0.82 * math.sin(math.radians(a)), 0.05, 0.16)
              for a in (18, 45, 72)])
    shade = _lowright(fan, 0.1)
    band = box(-0.2, -0.14, 0.12, 0.09, 0.03, 0.78)
    return [handle, fan, shade, band]


@sticker("jazz", "cocktail", "Cocktail", ["#CFEFFF", "#FF6A3D", "#E3172F", "#2E9E4F"], ink=1.0)
def _():
    glass = U(inter(ellipse(0, 0.2, 0.64, 0.46), Y - 0.2), box(0, -0.28, 0.08, 0.3), ellipse(0, -0.64, 0.38, 0.1))
    drink = inter(ellipse(0, 0.2, 0.54, 0.36), Y - 0.1)
    cherry = circle(0.32, 0.3, 0.15)
    pick = seg(0.1, 0.72, 0.42, 0.22, 0.04)
    return [glass, drink, cherry, pick]


@sticker("jazz", "fedora", "Fedora", ["#D9B27A", "#A8814E", "#7A1A2A", "#E3172F"], ink=1.0)
def _():
    crown = poly(spline([(-0.5, -0.1), (-0.46, 0.5), (-0.24, 0.62), (-0.02, 0.44), (0.2, 0.62), (0.44, 0.5), (0.5, -0.1)], closed=False, n=6))
    brim = ellipse(0, -0.14, 0.92, 0.32, 0.06)
    hat = U(crown, brim)
    shade = _lowright(hat, 0.25)
    band = box(0, 0.0, 0.5, 0.12)
    feather = taper(0.3, 0.0, 0.62, 0.42, 0.04, 0.11)
    return [hat, shade, band, feather]


@sticker("jazz", "coolcat", "Cool cat", ["#8A8F98", "#E3172F", "#15131A", "#F4F1EA"], ink=1.0)
def _():
    head = U(ellipse(0, -0.12, 0.68, 0.56), poly([(-0.64, 0.05), (-0.58, 0.78), (-0.16, 0.38)]), poly([(0.64, 0.05), (0.58, 0.78), (0.16, 0.38)]))
    beret = U(ellipse(-0.04, 0.5, 0.42, 0.16, 0.12), circle(0.0, 0.68, 0.045))
    shades = U(ellipse(-0.26, -0.04, 0.22, 0.14, 0.12), ellipse(0.26, -0.04, 0.22, 0.14, -0.12), box(0, 0.0, 0.1, 0.035), seg(-0.46, 0.0, -0.66, 0.06, 0.035), seg(0.46, 0.0, 0.66, 0.06, 0.035))
    muzzle = U(ellipse(0, -0.36, 0.3, 0.19), poly([(-0.07, -0.18), (0.07, -0.18), (0.0, -0.26)]))
    return [head, beret, shades, muzzle]


@sticker("jazz", "spotlight", "Spotlight", ["#2B2E33", "#FFE9A8", "#8A8F98", "#FFFFFF"], ink=1.0)
def _():
    beam = poly([(-0.2, 0.34), (0.9, 0.9), (0.9, -0.5), (-0.2, 0.06)])
    with rotated(0.4, -0.5, 0.4):
        can = U(box(-0.5, 0.4, 0.3, 0.22, 0.06), box(-0.74, 0.4, 0.1, 0.16, 0.04))
        yoke = U(seg(-0.5, 0.4, -0.5, -0.3, 0.07), box(-0.5, -0.6, 0.3, 0.07, 0.03), seg(-0.5, -0.3, -0.5, -0.55, 0.07))
        lens = box(-0.2, 0.4, 0.05, 0.17, 0.02)
    return [can, beam, yoke, lens]


@sticker("jazz", "clarinet", "Clarinet", ["#3A4666", "#E8ECF2", "#C9CED6", "#F4F1EA"], ink=1.0)
def _():
    with rotated(0.55):
        tube = U(box(0, 0.0, 0.15, 0.68), box(0, 0.8, 0.1, 0.12, 0.03))
        keys = U(*[circle(0.0, y, 0.09) for y in (0.42, 0.1, -0.22)], seg(0.15, -0.3, 0.27, -0.45, 0.05))
        bell = poly([(-0.36, -0.92), (0.36, -0.92), (0.15, -0.58), (-0.15, -0.58)])
        mouth = box(0, 0.52, 0.17, 0.05, 0.02)
    return [tube, keys, bell, mouth]


@sticker("jazz", "sleeve", "Record sleeve", ["#15131A", "#F4E3B8", "#19B6FF", "#E3172F"], ink=1.0)
def _():
    disc = circle(0.32, 0.32, 0.58)
    sleeve = box(-0.3, -0.3, 0.5, 0.5, 0.05)
    label = sub(circle(0.32, 0.32, 0.24), sleeve)
    print_ = star(-0.3, -0.3, 5, 0.26, 0.11)
    return [disc, sleeve, label, print_]


@sticker("jazz", "live", "Neon LIVE", ["#15131A", "#FF2D6F", "#FFE9F1", "#19F2FF"], ink=1.0)
def _():
    plate = box(0, 0, 0.9, 0.52, 0.14)
    glow = text("LIVE", 0.0, 0.02, 0.44, maxw=1.45) - 0.025
    word = text("LIVE", 0.0, 0.02, 0.44, maxw=1.45)
    frame = shell(box(0, 0, 0.8, 0.43, 0.1), 0.02)
    return [plate, glow, word, frame]


@sticker("jazz", "skyline", "City nights", ["#1D2A6B", "#0E1440", "#FFE9A8", "#FFFFFF"], ink=1.0)
def _():
    tile = box(0, 0, 0.88, 0.88, 0.16)
    bl = [(-0.68, 0.15, 0.0), (-0.38, 0.14, 0.34), (-0.1, 0.14, -0.1), (0.18, 0.15, 0.2), (0.48, 0.14, 0.45), (0.74, 0.12, 0.05)]
    buildings = inter(U(*[box(x, (top - 0.9) / 2, hw, (top + 0.9) / 2) for x, hw, top in bl]), tile)
    windows = U(*[box(x + dx, y, 0.04, 0.045) for i, (x, hw, top) in enumerate(bl) for j, y in enumerate(np.arange(top - 0.14, -0.82, -0.2))
               for dx in (-0.06, 0.06) if (i + j + (dx > 0)) % 2 == 0])
    moon = crescent(-0.44, 0.62, 0.17, 0.07, 0.04, 0.14)
    return [tile, buildings, windows, moon]


@sticker("jazz", "swing", "SWING", ["#E3172F", "#FFC531", "#FFFFFF", "#FFE14A"], ink=1.0)
def _():
    banner = poly([(-0.92, 0.45), (0.92, 0.45), (0.78, 0.0), (0.92, -0.45), (-0.92, -0.45), (-0.78, 0.0)])
    trim = U(box(0, 0.36, 0.74, 0.04), box(0, -0.36, 0.74, 0.04))
    word = text("SWING", 0.0, 0.0, 0.34, maxw=1.4)
    stars = U(star(-0.62, 0.0, 5, 0.1, 0.045), star(0.62, 0.0, 5, 0.1, 0.045))
    return [banner, trim, word, stars]


@sticker("jazz", "ribbonmic", "Ribbon mic", ["#E8D5A8", "#15131A", "#8A8F98", "#E3172F"], ink=1.0)
def _():
    head = box(0, 0.22, 0.3, 0.55, 0.14)
    grille = U(*[box(x, 0.22, 0.045, 0.4, 0.02) for x in (-0.15, 0.0, 0.15)])
    yoke = U(arc(0, 0.12, 0.5, math.radians(200), math.radians(340), 0.07), box(0, -0.62, 0.07, 0.14), box(0, -0.8, 0.32, 0.07, 0.03))
    knob = circle(0, -0.42, 0.1)
    return [head, grille, yoke, knob]


@sticker("jazz", "ticket", "Ticket stub", ["#FFC531", "#E09A12", "#15131A", "#E3172F"], ink=1.0)
def _():
    with rotated(0.3):
        card = sub(box(0, 0, 0.84, 0.44, 0.06), U(circle(-0.84, 0.0, 0.14), circle(0.84, 0.0, 0.14)))
        shade = _lowright(card, 0.2)
        stub = U(*[box(0.5, y, 0.03, 0.04) for y in (-0.3, -0.15, 0.0, 0.15, 0.3)])
    word = text("ADMIT", -0.12, -0.04, 0.2, ang=0.3, maxw=0.9)
    return [card, shade, word, stub]


@sticker("jazz", "bowtie", "Bow tie", ["#E3172F", "#9D1220", "#FF8A9C", "#F4F1EA"], ink=1.0)
def _():
    wings = U(poly([(-0.08, 0.0), (-0.85, 0.46), (-0.85, -0.46)]), poly([(0.08, 0.0), (0.85, 0.46), (0.85, -0.46)]))
    shade = _lowright(wings, 0.2)
    knot = box(0, 0, 0.14, 0.22, 0.06)
    dots = U(*[circle(x, y, 0.06) for x, y in ((-0.55, 0.12), (-0.55, -0.14), (0.55, 0.12), (0.55, -0.14))])
    return [wings, shade, knot, dots]
