PACK = ("country", "Country", False)
PRO_IDS = {"boots", "truck", "campfire", "skull", "badge"}


def _lowright(d, c=0.3):
    """The lower-right slice of shape d (the one shade layer)."""
    return inter(d, c - (X - Y) * 0.7)


@sticker("country", "hat", "Cowboy hat", ["#D2A05A", "#9A6A2A", "#7A1A2A", "#FFD400"], ink=1.0)
def _():
    crown = poly(spline([(-0.5, -0.2), (-0.54, 0.3), (-0.3, 0.62), (0.0, 0.44), (0.3, 0.62), (0.54, 0.3), (0.5, -0.2)], n=8))
    brim = poly(spline([(-0.94, 0.12), (-0.72, -0.3), (0.0, -0.44), (0.72, -0.3), (0.94, 0.12), (0.62, -0.14), (0.0, -0.2), (-0.62, -0.14)], n=8))
    hat = U(crown, brim)
    shade = _lowright(hat, 0.22)
    band = inter(box(0, -0.1, 0.56, 0.12), U(crown, brim))
    star_ = star(0.0, -0.1, 5, 0.16, 0.07)
    return [hat, shade, band, star_]


@sticker("country", "boots", "Boots", ["#A8602E", "#6E3A16", "#F4E4C1", "#FFD400"], ink=1.0)
def _():
    parts = []
    for dx, dy in [(-0.18, 0.2), (0.2, 0.0)]:
        parts.append(poly([(-0.2 + dx, 0.62 + dy), (0.16 + dx, 0.62 + dy), (0.17 + dx, 0.06 + dy), (0.4 + dx, -0.04 + dy), (0.62 + dx, -0.16 + dy),
                           (0.66 + dx, -0.36 + dy), (-0.26 + dx, -0.36 + dy), (-0.26 + dx, 0.06 + dy)]))
        parts.append(box(-0.12 + dx, -0.46 + dy, 0.15, 0.1, 0.02))
    boot = U(*parts)
    shade = _lowright(boot, 0.4)
    trim = U(box(-0.18, 0.78, 0.18, 0.06), box(0.2, 0.58, 0.18, 0.06), heart(-0.18, 0.58, 0.1), heart(0.2, 0.38, 0.1))
    spur = U(seg(-0.46, -0.1, -0.7, -0.14, 0.05), star(-0.74, -0.14, 6, 0.2, 0.09), seg(-0.08, -0.34, -0.3, -0.4, 0.05), star(-0.34, -0.4, 6, 0.18, 0.08))
    return [boot, shade, trim, spur]


@sticker("country", "banjo", "Banjo", ["#B8702F", "#F4F1EA", "#3A2418", "#C9CED6"], ink=1.0)
def _():
    with rotated(0.75, 0.0, 0.0, 0.0, 0.0):
        rim = circle(-0.1, -0.5, 0.44)
        head = circle(-0.1, -0.5, 0.31)
        neck = U(box(-0.1, 0.36, 0.12, 0.6), box(-0.1, 0.88, 0.19, 0.13, 0.04))
        brackets = U(*[circle(-0.1 + sx * 0.2, 0.88, 0.06) for sx in (-1, 1)], box(-0.1, -0.5, 0.2, 0.06))
    return [rim, head, neck, brackets]


@sticker("country", "fiddle", "Fiddle", ["#D9894A", "#8A4A1A", "#2B2E33", "#F4E4C1"], ink=1.0)
def _():
    with rotated(-0.55, 0.0, 0.0, -0.1, 0.0):
        body = U(smin(circle(0, -0.4, 0.4), circle(0, 0.12, 0.3), 0.1))
        body = sub(body, U(circle(-0.46, -0.08, 0.17), circle(0.46, -0.08, 0.17)))
        shade = _lowright(body, 0.18)
        neck = U(box(0, 0.56, 0.09, 0.3), circle(0, 0.88, 0.14), box(0, -0.74, 0.14, 0.07))
        fholes = U(box(-0.17, -0.22, 0.045, 0.14, 0.02, 0.15), box(0.17, -0.22, 0.045, 0.14, 0.02, -0.15))
        strings = U(neck, fholes)
    bow = U(taper(0.88, -0.6, -0.5, 0.5, 0.07, 0.07), circle(0.88, -0.6, 0.1))
    return [body, shade, strings, bow]


@sticker("country", "lasso", "Lasso", ["#E0B070", "#8A5A24", "#F4E4C1", "#7C4416"], ink=1.0)
def _():
    coil = U(ring(-0.1, -0.15, 0.58, 0.14), ring(-0.1, -0.15, 0.26, 0.11))
    twist = inter(stripes(0.2, 0.9, 0.35, 0.0), U(coil, ring(0.5, 0.5, 0.3, 0.1)))
    loop = ring(0.5, 0.5, 0.3, 0.1)
    knot = U(box(0.42, 0.22, 0.14, 0.12, 0.05, 0.8), seg(0.4, 0.2, 0.3, -0.3, 0.1))
    return [coil, twist, loop, knot]


@sticker("country", "cactus", "Prickly pear", ["#3FA66A", "#277A4A", "#FF4F7A", "#C9742E"], ink=1.0)
def _():
    pads = U(oval(0.0, 0.0, 0.34, 0.42), oval(-0.38, 0.5, 0.26, 0.34, 0.5), oval(0.4, 0.46, 0.26, 0.34, -0.45))
    shade = _lowright(pads, 0.1)
    flowers = U(star(-0.5, 0.8, 5, 0.16, 0.075), star(0.52, 0.76, 5, 0.16, 0.075), star(0.0, 0.5, 5, 0.15, 0.07))
    pot = U(poly([(-0.46, -0.52), (0.46, -0.52), (0.36, -0.9), (-0.36, -0.9)]), box(0, -0.5, 0.54, 0.08, 0.03))
    return [pads, shade, flowers, pot]


@sticker("country", "truck", "Pickup truck", ["#D9622B", "#9FE8FF", "#2B2E33", "#E8ECF2"], ink=1.0)
def _():
    body = U(box(0.0, -0.16, 0.9, 0.22, 0.05), poly([(-0.06, 0.04), (0.04, 0.4), (0.5, 0.4), (0.7, 0.04)]), box(-0.56, 0.06, 0.32, 0.22, 0.02))
    glass = U(poly([(0.07, 0.04), (0.11, 0.3), (0.29, 0.3), (0.29, 0.04)]), poly([(0.35, 0.04), (0.35, 0.3), (0.45, 0.3), (0.58, 0.04)]))
    wheels = U(circle(-0.5, -0.4, 0.21), circle(0.54, -0.4, 0.21))
    chrome = U(box(0.92, -0.3, 0.06, 0.12, 0.02), box(-0.92, -0.3, 0.06, 0.12, 0.02), circle(-0.5, -0.4, 0.09), circle(0.54, -0.4, 0.09),
               circle(-0.52, 0.34, 0.24), box(0.8, -0.1, 0.05, 0.1, 0.01))
    return [body, glass, wheels, chrome]


@sticker("country", "barn", "Barn", ["#C8372A", "#8F1F18", "#5A4A3A", "#F4F1EA"], ink=1.0)
def _():
    wall = U(box(0.0, -0.3, 0.7, 0.5), poly([(-0.7, 0.2), (-0.5, 0.6), (0.5, 0.6), (0.7, 0.2)]))
    shade = _lowright(wall, 0.28)
    roof = U(polyline([(-0.86, 0.14), (-0.5, 0.7), (0.5, 0.7), (0.86, 0.14)], 0.09))
    trim = U(box(0, -0.42, 0.3, 0.38) - 0.0, 9) if False else sub(box(0, -0.4, 0.34, 0.36), box(0, -0.4, 0.25, 0.27))
    trim = U(trim, seg(-0.25, -0.67, 0.25, -0.13, 0.05), seg(0.25, -0.67, -0.25, -0.13, 0.05), box(0, 0.3, 0.14, 0.1, 0.02), seg(-0.7, -0.8, 0.7, -0.8, 0.04))
    return [wall, shade, roof, trim]


@sticker("country", "badge", "Howdy badge", ["#FFC531", "#E09A12", "#B8321A", "#FFF4C7"], ink=1.0)
def _():
    pts = [(0.92 * math.cos(math.pi / 2 + k * 2 * math.pi / 5), 0.92 * math.sin(math.pi / 2 + k * 2 * math.pi / 5)) for k in range(5)]
    star_ = U(star(0, 0, 5, 0.9, 0.46), *[circle(x * 0.92, y * 0.92, 0.1) for x, y in pts])
    shade = _lowright(star_, 0.3)
    plate = circle(0, -0.02, 0.5)
    word = text("HOWDY", 0, -0.02, 0.2, maxw=0.8)
    return [star_, shade, plate, word]


@sticker("country", "bandana", "Neckerchief", ["#E3172F", "#A8121F", "#F4F1EA", "#5A0A12"], ink=1.0)
def _():
    cloth = poly(spline([(-0.8, 0.46), (-0.5, 0.32), (0.5, 0.32), (0.8, 0.46), (0.12, -0.8), (-0.12, -0.8)], n=6))
    shade = _lowright(cloth, 0.3)
    dots = inter(U(*[circle(x, y, 0.08) for x, y in [(-0.42, 0.14), (0.0, 0.14), (0.42, 0.14), (-0.2, -0.12), (0.2, -0.12), (0.0, -0.38)]], box(0, 0.32, 0.82, 0.07)), cloth)
    knot = U(circle(0.0, 0.46, 0.22), taper(-0.08, 0.48, -0.56, 0.78, 0.16, 0.12), taper(0.08, 0.48, 0.56, 0.78, 0.16, 0.12))
    return [cloth, shade, dots, knot]


@sticker("country", "harmonica", "Harmonica", ["#C9CED6", "#8A8F98", "#2B2E33", "#E3172F"], ink=1.0)
def _():
    with rotated(0.12):
        cover = box(0, 0, 0.8, 0.46, 0.07)
        shade = _lowright(cover, 0.22)
        holes = U(*[box(-0.5 + 0.2 * k, 0.04, 0.085, 0.14, 0.015) for k in range(6)])
        caps = U(box(-0.76, 0.0, 0.05, 0.46), box(0.76, 0.0, 0.05, 0.46))
    return [cover, shade, holes, caps]


@sticker("country", "campfire", "Campfire", ["#7C4416", "#FF6A1F", "#FFE14A", "#8A8F98"], ink=1.0)
def _():
    logs = U(taper(-0.7, -0.74, 0.46, -0.4, 0.13, 0.13), taper(0.7, -0.74, -0.46, -0.4, 0.13, 0.13))
    flame = poly(spline([(-0.5, -0.4), (-0.6, 0.0), (-0.3, 0.22), (-0.36, 0.66), (-0.06, 0.4), (0.08, 0.84), (0.3, 0.4), (0.56, 0.1), (0.5, -0.4)], n=6))
    core = poly(spline([(-0.24, -0.4), (-0.28, -0.1), (-0.04, 0.12), (0.06, 0.5), (0.22, 0.0), (0.28, -0.4)], n=6))
    stones = U(*[circle(x, -0.78, 0.16) for x in (-0.76, -0.44, 0.44, 0.76)])
    return [logs, flame, core, stones]


@sticker("country", "wheel", "Wagon wheel", ["#B8702F", "#7C4416", "#2B2E33", "#FFE9C7"], ink=1.0)
def _():
    rim = ring(0, 0, 0.74, 0.14)
    spokes = U(*[seg(0, 0, 0.78 * math.cos(k * math.pi / 4), 0.78 * math.sin(k * math.pi / 4), 0.05) for k in range(8)])
    hub = U(circle(0, 0, 0.2), ring(0, 0, 0.9, 0.0) + 9)
    iron = U(ring(0, 0, 0.9, 0.05), circle(0, 0, 0.09))
    return [rim, spokes, hub, iron]


@sticker("country", "skull", "Longhorn", ["#F4E4C1", "#C9A878", "#2B2E33", "#2EC4B6"], ink=1.0)
def _():
    skull = U(poly(spline([(-0.32, 0.5), (-0.38, 0.0), (-0.16, -0.5), (0.16, -0.5), (0.38, 0.0), (0.32, 0.5)], closed=False, n=6)), ellipse(0, 0.32, 0.34, 0.26))
    horns = U(brush([(-0.3, 0.3), (-0.7, 0.34), (-0.9, 0.5), (-0.9, 0.7)], [0.1, 0.1, 0.08, 0.05]), brush([(0.3, 0.3), (0.7, 0.34), (0.9, 0.5), (0.9, 0.7)], [0.1, 0.1, 0.08, 0.05]))
    sockets = U(ellipse(-0.16, 0.1, 0.1, 0.12), ellipse(0.16, 0.1, 0.1, 0.12), ellipse(-0.07, -0.34, 0.04, 0.08), ellipse(0.07, -0.34, 0.04, 0.08))
    gem = poly([(0.0, 0.62), (-0.1, 0.5), (0.0, 0.36), (0.1, 0.5)])
    return [skull, horns, sockets, gem]


@sticker("country", "sign", "Honky tonk", ["#B8321A", "#FFD400", "#FFD400", "#F4F1EA"], ink=1.0)
def _():
    board = box(0, 0, 0.92, 0.7, 0.1)
    trim = U(sub(box(0, 0, 0.86, 0.64, 0.08), box(0, 0, 0.8, 0.58, 0.06)), *[circle(sx * 0.84, sy * 0.58, 0.07) for sx in (-1, 1) for sy in (-1, 1)])
    honky = text("HONKY", 0, 0.22, 0.36, maxw=1.55)
    tonk = text("TONK", 0, -0.24, 0.36, maxw=1.2)
    return [board, trim, honky, tonk]


@sticker("country", "rocker", "Rocking chair", ["#B8702F", "#7C4416", "#E3172F", "#E0B070"], ink=1.0)
def _():
    frame = U(seg(-0.4, 0.8, -0.28, -0.1, 0.12), seg(-0.34, 0.5, 0.0, 0.5, 0.08), seg(-0.38, 0.72, -0.02, 0.72, 0.08),
              seg(-0.3, -0.1, 0.56, -0.1, 0.12), seg(0.56, -0.1, 0.58, -0.56, 0.1), seg(-0.1, -0.1, -0.06, -0.56, 0.1), seg(0.04, 0.2, 0.54, 0.2, 0.08), seg(0.54, 0.2, 0.56, -0.1, 0.08))
    rockers = arc(0.1, 0.4, 1.18, -2.1, -1.0, 0.12)
    shade = _lowright(frame, 0.3)
    cushion = box(0.14, 0.0, 0.4, 0.12, 0.05)
    return [frame, shade, cushion, rockers]


