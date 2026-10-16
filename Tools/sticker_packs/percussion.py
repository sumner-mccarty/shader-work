PACK = ("percussion", "World Perc", False)
PRO_IDS = {"conga", "taiko", "steelpan", "djembe", "happy"}


def _lowright(d, c=0.3):
    """The lower-right slice of shape d (the one shade layer)."""
    return inter(d, c - (X - Y) * 0.7)


@sticker("percussion", "conga", "Conga", ["#C9742E", "#8F4A1A", "#F4E4C1", "#2B2E33"], ink=1.0)
def _():
    with rotated(0.12):
        body = poly(spline([(-0.46, 0.5), (-0.54, 0.0), (-0.36, -0.82), (0.36, -0.82), (0.54, 0.0), (0.46, 0.5)], n=8))
        shade = _lowright(body, 0.42)
        head = U(ellipse(0, 0.52, 0.5, 0.17))
        trim = U(box(0, 0.4, 0.5, 0.06), box(0, -0.62, 0.38, 0.07, 0.03), ellipse(0, 0.5, 0.06, 0.04))
    return [body, shade, head, trim]


@sticker("percussion", "bongos", "Bongos", ["#E3A23B", "#B56A1A", "#F4E4C1", "#2B2E33"], ink=1.0)
def _():
    left = poly(spline([(-0.86, 0.1), (-0.8, -0.4), (-0.66, -0.74), (-0.1, -0.74), (-0.02, -0.4), (0.0, 0.1)], n=6))
    right = poly(spline([(0.0, 0.1), (0.02, -0.4), (0.1, -0.74), (0.66, -0.74), (0.8, -0.4), (0.86, 0.1)], n=6))
    body = U(left, right)
    shade = _lowright(body, 0.0)
    head = U(ellipse(-0.43, 0.12, 0.43, 0.15), ellipse(0.43, 0.12, 0.43, 0.15))
    trim = U(box(0, -0.2, 0.1, 0.06), box(-0.4, -0.56, 0.3, 0.05), box(0.4, -0.56, 0.3, 0.05))
    return [body, shade, head, trim]


@sticker("percussion", "djembe", "Djembe", ["#B8702F", "#7C4416", "#F4E4C1", "#2B2E33"], ink=1.0)
def _():
    body = poly(spline([(-0.56, 0.5), (-0.34, 0.14), (-0.3, -0.3), (-0.56, -0.84), (0.56, -0.84), (0.3, -0.3), (0.34, 0.14), (0.56, 0.5)], n=8))
    shade = _lowright(body, 0.1)
    head = ellipse(0, 0.52, 0.58, 0.2)
    pattern = U(*[poly([(-0.22 + 0.22 * k, -0.7), (-0.11 + 0.22 * k, -0.5), (0.0 + 0.22 * k, -0.7)]) for k in range(3)],
            polyline([(-0.4, -0.3), (-0.22, -0.18), (0, -0.3), (0.22, -0.18), (0.4, -0.3)], 0.04), box(0, 0.36, 0.5, 0.05))
    return [body, shade, head, pattern]


@sticker("percussion", "tabla", "Tabla", ["#C9742E", "#F4E4C1", "#141418", "#8F4A1A"], ink=1.0)
def _():
    bayan = U(inter(circle(-0.46, -0.16, 0.52), Y + 0.16), ellipse(-0.46, -0.16, 0.52, 0.2))
    dayan = U(poly(spline([(0.2, 0.2), (0.16, -0.5), (0.3, -0.84), (0.66, -0.84), (0.8, -0.5), (0.76, 0.2)], n=6)))
    body = U(bayan, dayan)
    heads = U(ellipse(-0.46, -0.16, 0.52, 0.2), ellipse(0.48, 0.2, 0.3, 0.12))
    spots = U(ellipse(-0.4, -0.16, 0.22, 0.09), ellipse(0.48, 0.2, 0.16, 0.06))
    trim = U(box(0.48, -0.36, 0.34, 0.07), box(0.48, -0.62, 0.3, 0.06))
    return [body, heads, spots, trim]


@sticker("percussion", "cajon", "Cajon", ["#E0A15A", "#F4C98A", "#2B2E33", "#8F5A1E"], ink=1.0)
def _():
    box_ = box(0, -0.1, 0.62, 0.7, 0.05)
    top = poly([(-0.62, 0.62), (0.62, 0.62), (0.8, 0.84), (-0.44, 0.84)])
    hole = circle(0, -0.08, 0.26)
    trim = U(box(0, 0.4, 0.62, 0.05), box(-0.44, -0.66, 0.06, 0.1), box(0.44, -0.66, 0.06, 0.1), seg(-0.5, 0.2, 0.5, 0.2, 0.0))
    return [box_, top, hole, trim]


@sticker("percussion", "taiko", "Taiko", ["#B83A2A", "#F4E4C1", "#FFC531", "#7C4416"], ink=1.0)
def _():
    body = U(ellipse(0, -0.26, 0.8, 0.62), box(0, -0.28, 0.8, 0.46))
    head = circle(-0.02, -0.12, 0.48)
    tacks = U(*[circle(-0.02 + 0.6 * math.cos(a), -0.12 + 0.6 * math.sin(a), 0.05) for a in np.linspace(0, 2 * math.pi, 13)[:-1]])
    sticks = U(taper(-0.7, 0.88, -0.1, 0.1, 0.06, 0.08), taper(0.7, 0.88, 0.1, 0.1, 0.06, 0.08), circle(-0.7, 0.88, 0.07), circle(0.7, 0.88, 0.07))
    return [body, head, tacks, sticks]


@sticker("percussion", "steelpan", "Steel pan", ["#7F8FA3", "#2F3A4C", "#FFC531", "#E3172F"], ink=1.0)
def _():
    bowl = U(ellipse(0, -0.12, 0.86, 0.52), box(0, -0.46, 0.86, 0.32))
    shade = ellipse(0, 0.0, 0.76, 0.4)
    notes = U(ellipse(-0.42, 0.04, 0.22, 0.13, 0.4), ellipse(0.42, 0.04, 0.22, 0.13, -0.4), ellipse(0.0, 0.2, 0.2, 0.11), ellipse(0.0, -0.12, 0.22, 0.12))
    mallets = U(taper(-0.72, -0.78, -0.2, -0.3, 0.07, 0.07), circle(-0.16, -0.26, 0.12), taper(0.72, -0.78, 0.2, -0.3, 0.07, 0.07), circle(0.16, -0.26, 0.12))
    return [bowl, shade, notes, mallets]


@sticker("percussion", "happy", "Happy conga", ["#2EC4B6", "#F4E4C1", "#141418", "#FF6A8A"], ink=1.0)
def _():
    body = poly(spline([(-0.58, 0.44), (-0.66, -0.1), (-0.48, -0.78), (0.48, -0.78), (0.66, -0.1), (0.58, 0.44)], n=8))
    head = ellipse(0, 0.46, 0.6, 0.2)
    face = U(circle(-0.22, -0.02, 0.1), circle(0.22, -0.02, 0.1), sub(circle(0, -0.2, 0.22), circle(0, -0.12, 0.22)))
    hands = U(circle(-0.82, -0.2, 0.13), circle(0.82, -0.2, 0.13), seg(-0.66, -0.2, -0.82, -0.2, 0.07), seg(0.66, -0.2, 0.82, -0.2, 0.07))
    return [body, head, face, hands]


@sticker("percussion", "guiro", "Guiro", ["#C8B23A", "#8A7A1E", "#3A2418", "#F4E4C1"], ink=1.0)
def _():
    with rotated(0.4):
        body = smin(ellipse(-0.3, 0.0, 0.58, 0.42), ellipse(0.5, 0.0, 0.38, 0.24), 0.25)
        shade = _lowright(body, 0.2)
        ridges = inter(U(*[box(-0.5 + 0.22 * k, 0.0, 0.07, 0.4) for k in range(5)]), body)
        hole = ellipse(0.78, 0.0, 0.08, 0.1)
    stick = U(taper(-0.86, 0.86, 0.1, 0.1, 0.07, 0.07))
    grooves = U(ridges, hole)
    return [body, shade, grooves, stick]


@sticker("percussion", "claves", "Claves", ["#C9742E", "#E0A15A", "#FFE14A", "#7C4416"], ink=1.0)
def _():
    left = taper(-0.84, 0.7, -0.08, -0.1, 0.15, 0.15)
    right = taper(0.84, 0.7, 0.08, -0.1, 0.15, 0.15)
    tops = U(circle(-0.84, 0.7, 0.15), circle(0.84, 0.7, 0.15))
    spark = star(0.0, -0.26, 8, 0.4, 0.17, 0.4)
    return [left, right, spark, tops]


@sticker("percussion", "talking", "Talking drum", ["#D9A05A", "#8A5A24", "#2B2E33", "#F4E4C1"], ink=1.0)
def _():
    with rotated(0.5, -0.1, 0.1):
        body = poly(spline([(-0.52, 0.5), (-0.14, 0.16), (-0.14, -0.16), (-0.52, -0.5), (0.52, -0.5), (0.14, -0.16), (0.14, 0.16), (0.52, 0.5)], n=4))
        shade = _lowright(body, 0.3)
        cords = U(*[seg(x, 0.46, x * 0.3, 0.0, 0.05) for x in (-0.34, 0.0, 0.34)], *[seg(x, -0.46, x * 0.3, 0.0, 0.05) for x in (-0.34, 0.0, 0.34)])
        heads = U(ellipse(0, 0.5, 0.56, 0.16), ellipse(0, -0.5, 0.56, 0.16))
    beater = U(brush([(0.1, -0.8), (0.44, -0.8), (0.64, -0.5)], [0.07, 0.09, 0.09]), circle(0.64, -0.44, 0.15))
    cords = U(cords, beater)
    return [body, shade, cords, heads]


@sticker("percussion", "frame", "Frame drum", ["#7C4416", "#F0C890", "#E3172F", "#2B2E33"], ink=1.0)
def _():
    rim = circle(-0.14, 0.16, 0.74)
    head = circle(-0.14, 0.16, 0.58)
    art = U(circle(-0.14, 0.0, 0.2), *[ellipse(-0.14 + dx, 0.34 + dy, 0.065, 0.14, a) for dx, dy, a in [(-0.24, -0.02, 0.4), (-0.08, 0.1, 0.1), (0.08, 0.1, -0.1), (0.24, -0.02, -0.4)]])
    beater = U(taper(0.5, -0.5, 0.78, -0.78, 0.07, 0.07), circle(0.8, -0.8, 0.12))
    return [rim, head, art, beater]


@sticker("percussion", "timbales", "Timbales", ["#C9CED6", "#8A8F98", "#F4F1EA", "#2B2E33"], ink=1.0)
def _():
    l = box(-0.46, 0.04, 0.42, 0.28, 0.05)
    r = box(0.46, 0.0, 0.38, 0.26, 0.05)
    body = U(l, r)
    shade = _lowright(body, 0.0)
    heads = U(ellipse(-0.46, 0.3, 0.42, 0.15), ellipse(0.46, 0.24, 0.38, 0.14))
    stand = U(box(0, -0.34, 0.8, 0.07, 0.03), seg(0, -0.34, 0, -0.5, 0.06), seg(-0.4, -0.5, 0.4, -0.84, 0.07), seg(0.4, -0.5, -0.4, -0.84, 0.07))
    return [body, shade, heads, stand]


@sticker("percussion", "agogo", "Agogo", ["#FFC531", "#E09A12", "#2B2E33", "#7C4416"], ink=1.0)
def _():
    big = poly([(-0.66, 0.36), (-0.3, 0.36), (-0.08, -0.5), (-0.9, -0.5)])
    small = poly([(0.3, 0.2), (0.6, 0.2), (0.76, -0.4), (0.2, -0.4)])
    bells = U(big, small, ellipse(-0.49, -0.5, 0.42, 0.14), ellipse(0.48, -0.4, 0.28, 0.1))
    shade = _lowright(bells, 0.0)
    mouths = U(ellipse(-0.49, -0.5, 0.34, 0.09), ellipse(0.48, -0.4, 0.2, 0.065))
    handle = U(bezier((-0.48, 0.36), (-0.02, 0.9), (0.45, 0.2), 0.09), taper(0.7, 0.86, 0.2, 0.18, 0.06, 0.06), circle(0.72, 0.88, 0.1))
    return [bells, shade, mouths, handle]


@sticker("percussion", "rainstick", "Rainstick", ["#B8702F", "#2EC4B6", "#F4E4C1", "#1FB6FF"], ink=1.0)
def _():
    with rotated(0.45):
        tube = box(0, 0, 0.24, 0.8, 0.24)
        bands = inter(stripes(0.3, 0.7, 0.4, 0.1), tube)
        caps = U(box(0, 0.78, 0.3, 0.1, 0.05), box(0, -0.78, 0.3, 0.1, 0.05))
    drops = U(poly([(-0.66, 0.58), (-0.55, 0.36), (-0.77, 0.36)]), circle(-0.66, 0.33, 0.11), poly([(0.66, -0.2), (0.77, -0.42), (0.55, -0.42)]), circle(0.66, -0.45, 0.11))
    return [tube, bands, caps, drops]


@sticker("percussion", "groove", "Groove", ["#FFE14A", "#E0A800", "#B8321A"], ink=1.0)
def _():
    with rotated(-0.1):
        banner = U(box(0, 0, 0.92, 0.46, 0.12), poly([(-0.88, 0.3), (-0.99, 0.0), (-0.88, -0.3)]), poly([(0.88, 0.3), (0.99, 0.0), (0.88, -0.3)]))
        shade = _lowright(banner, 0.15)
        word = text("GROOVE", 0, 0.0, 0.42, maxw=1.72)
    return [banner, shade, word]


