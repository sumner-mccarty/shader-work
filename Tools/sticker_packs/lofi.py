PACK = ("lofi", "Lo-Fi", False)
PRO_IDS = {"cat", "window", "city", "phones", "wavecloud"}


def _lowright(d, c=0.3):
    """The lower-right slice of shape d (the one shade layer)."""
    return inter(d, c - (X - Y) * 0.7)


@sticker("lofi", "phones", "Big headphones", ["#B8A6E8", "#F2A6C0", "#FFF1DC", "#7C69C4"], ink=1.0)
def _():
    band = U(arc(0.0, -0.1, 0.62, 0.15, math.pi - 0.15, 0.11), poly([(-0.52, 0.6), (-0.34, 0.9), (-0.2, 0.7)]), poly([(0.52, 0.6), (0.34, 0.9), (0.2, 0.7)]))
    cups = U(oval(-0.64, -0.12, 0.26, 0.4), oval(0.64, -0.12, 0.26, 0.4))
    cushions = U(oval(-0.5, -0.12, 0.12, 0.3), oval(0.5, -0.12, 0.12, 0.3))
    marks = U(heart(-0.68, -0.12, 0.13), heart(0.68, -0.12, 0.13))
    return [band, cups, cushions, marks]


@sticker("lofi", "window", "Rainy window", ["#5C5F9E", "#FFF1DC", "#9FD3F5", "#B8A6E8"], ink=1.0)
def _():
    glass = box(0, 0, 0.74, 0.74, 0.05)
    frame = U(sub(box(0, 0, 0.84, 0.84, 0.08), box(0, 0, 0.72, 0.72, 0.04)), box(0, 0, 0.05, 0.74), box(0, 0, 0.74, 0.05))
    drops = U(*[U(poly([(x, y + 0.28), (x - 0.15, y), (x + 0.15, y)]), circle(x, y - 0.01, 0.16)) for x, y in [(-0.4, -0.14), (0.38, -0.2), (-0.06, -0.52)]])
    cloud = U(circle(-0.3, 0.46, 0.18), circle(-0.04, 0.54, 0.24), circle(0.26, 0.46, 0.2), box(-0.02, 0.4, 0.4, 0.1, 0.05))
    return [glass, frame, drops, cloud]


@sticker("lofi", "cat", "Sleepy cat", ["#F6B98B", "#C98A5A", "#3B3A5A", "#D9B38C"], ink=1.0)
def _():
    cat = U(ellipse(0.12, -0.26, 0.62, 0.34), circle(-0.4, -0.08, 0.3), poly([(-0.66, 0.06), (-0.62, 0.46), (-0.38, 0.18)]), poly([(-0.42, 0.18), (-0.2, 0.44), (-0.14, 0.1)]),
            brush([(0.62, -0.34), (0.36, -0.58), (-0.1, -0.58), (-0.44, -0.46)], [0.09, 0.09, 0.09, 0.07]))
    shade = _lowright(cat, 0.5)
    face = U(arc(-0.5, -0.04, 0.1, math.pi + 0.3, 2 * math.pi - 0.3, 0.04), arc(-0.3, -0.04, 0.1, math.pi + 0.3, 2 * math.pi - 0.3, 0.04), text("z", 0.1, 0.3, 0.22, maxw=0.22), text("Z", 0.4, 0.56, 0.3, maxw=0.3))
    desk = box(0.0, -0.76, 0.9, 0.14, 0.04)
    return [desk, cat, shade, face]


@sticker("lofi", "deck", "Tape deck", ["#D8C8FF", "#3B3A5A", "#FFF1DC", "#F2A6C0"], ink=1.0)
def _():
    body = box(0, 0, 0.92, 0.62, 0.1)
    window = box(-0.08, 0.14, 0.58, 0.26, 0.05)
    reels = U(circle(-0.3, 0.14, 0.17), circle(0.14, 0.14, 0.17), circle(-0.3, 0.14, 0.0) + 0.0)
    keys = U(*[box(-0.6 + 0.2 * k, -0.34, 0.08, 0.1, 0.03) for k in range(5)], circle(0.72, 0.3, 0.1), circle(0.72, -0.02, 0.1))
    return [body, window, reels, keys]


@sticker("lofi", "lamp", "Desk lamp", ["#B8A6E8", "#FFC9B3", "#FFE9A8", "#7C69C4"], ink=1.0)
def _():
    arms = U(seg(-0.5, -0.66, -0.2, -0.04, 0.1), seg(-0.2, -0.04, -0.46, 0.4, 0.1), box(-0.4, -0.78, 0.4, 0.1, 0.05), circle(-0.2, -0.04, 0.13))
    hood = poly([(-0.78, 0.5), (-0.3, 0.88), (0.2, 0.58), (-0.28, 0.2)])
    beam = poly([(-0.02, 0.4), (0.8, -0.2), (0.54, -0.6), (-0.1, -0.2)])
    bulb = circle(-0.12, 0.42, 0.13)
    return [arms, hood, beam, bulb]


@sticker("lofi", "mug", "Steaming mug", ["#FFC9B3", "#E89A82", "#FFFFFF", "#7A4A32"], ink=1.0)
def _():
    mug = U(box(-0.1, -0.34, 0.46, 0.4, 0.14), arc(0.34, -0.32, 0.24, -1.45, 1.45, 0.095))
    shade = _lowright(mug, 0.45)
    steam = brush([(-0.12, 0.18), (-0.3, 0.42), (0.06, 0.6), (-0.12, 0.86)], [0.12, 0.12, 0.12, 0.1])
    tag = U(heart(-0.1, -0.34, 0.18), seg(0.1, 0.0, 0.34, 0.3, 0.03), box(0.4, 0.4, 0.13, 0.15, 0.03, 0.3))
    return [mug, shade, steam, tag]


@sticker("lofi", "plant", "Leafy plant", ["#E8A88A", "#7CCB9C", "#4FA372", "#FFF1DC"], ink=1.0)
def _():
    pot = U(poly([(-0.4, -0.2), (0.4, -0.2), (0.3, -0.86), (-0.3, -0.86)]), box(0.0, -0.18, 0.46, 0.08, 0.03))
    leaves = U(oval(-0.4, 0.18, 0.17, 0.4, 0.6), oval(0.4, 0.18, 0.17, 0.4, -0.6), oval(0.0, 0.42, 0.18, 0.42), oval(-0.18, 0.08, 0.14, 0.34, 0.2))
    shade = _lowright(leaves, 0.25)
    veins = U(seg(0.0, 0.1, 0.0, 0.7, 0.03), seg(-0.2, -0.0, -0.58, 0.36, 0.03), seg(0.2, 0.0, 0.58, 0.36, 0.03), arc(-0.12, -0.5, 0.07, math.pi + 0.3, 2 * math.pi - 0.3, 0.03), arc(0.12, -0.5, 0.07, math.pi + 0.3, 2 * math.pi - 0.3, 0.03))
    return [pot, leaves, shade, veins]


@sticker("lofi", "city", "Moon city", ["#3B3A7A", "#FFE9A8", "#1F1E3A", "#FFD27A"], ink=1.0)
def _():
    sky = circle(0, 0, 0.88)
    moonlight = U(crescent(-0.3, 0.38, 0.32, 0.12, 0.06, 0.27), seg(0.24, 0.7, 0.1, 0.4, 0.04), seg(0.5, 0.58, 0.36, 0.28, 0.04), seg(0.1, 0.24, -0.02, -0.04, 0.04))
    bld = inter(U(box(-0.6, -0.5, 0.2, 0.42), box(-0.2, -0.4, 0.2, 0.56), box(0.2, -0.54, 0.2, 0.34), box(0.6, -0.38, 0.2, 0.52), box(0.0, -0.9, 0.9, 0.2)), sky)
    wins = U(*[box(x, y, 0.05, 0.06) for x, y in [(-0.6, -0.4), (-0.2, -0.3), (-0.2, -0.54), (0.6, -0.3), (0.6, -0.56), (0.2, -0.52), (-0.6, -0.62)]])
    return [sky, moonlight, bld, wins]


@sticker("lofi", "notebook", "Doodle book", ["#F2A6C0", "#FFF1DC", "#7C69C4", "#B47A8C"], ink=1.0)
def _():
    with rotated(-0.1):
        cover = box(0, 0, 0.7, 0.88, 0.07)
        page = box(0.08, 0.0, 0.52, 0.76, 0.04)
        doodle = U(heart(0.0, 0.34, 0.16), star(0.28, 0.36, 5, 0.12, 0.05), polyline([(-0.2, -0.1), (-0.06, 0.0), (0.08, -0.1), (0.22, 0.0), (0.36, -0.1)], 0.04),
                   ring(0.1, -0.44, 0.14, 0.035), polyline([(-0.28, 0.1), (-0.28, 0.1)], 0.001) + 9)
        rings = U(*[circle(-0.6, y, 0.075) for y in np.linspace(-0.66, 0.66, 6)])
    return [cover, page, doodle, rings]


@sticker("lofi", "vinyl", "Pastel vinyl", ["#3B3A5A", "#CDB8FF", "#FFC9B3", "#FFF1DC"], ink=1.0)
def _():
    disc = circle(0.28, 0.1, 0.56)
    sleeve = box(-0.3, -0.06, 0.5, 0.72, 0.06)
    label = circle(0.3, 0.1, 0.13)
    art = U(circle(-0.3, 0.12, 0.26), box(-0.3, -0.42, 0.28, 0.08, 0.03))
    return [disc, sleeve, label, art]


@sticker("lofi", "loop", "Tape loop", ["#8A6A4A", "#F2A6C0", "#FFF1DC", "#3B3A5A"], ink=1.0)
def _():
    pts = [(0.84 * math.cos(t) / (1 + math.sin(t) ** 2), 0.84 * math.sin(t) * math.cos(t) / (1 + math.sin(t) ** 2) * 1.3) for t in np.linspace(0, 2 * math.pi, 17)[:-1]]
    tape = brush(pts, [0.1] * 16, closed=True, n=6)
    reels = U(circle(-0.5, 0.0, 0.22), circle(0.5, 0.0, 0.22))
    hubs = U(circle(-0.5, 0.0, 0.09), circle(0.5, 0.0, 0.09))
    spark = U(star(0.0, 0.52, 4, 0.18, 0.045), star(0.0, -0.52, 4, 0.14, 0.035))
    return [tape, reels, hubs, spark]


@sticker("lofi", "chill", "Chill sign", ["#B8A6E8", "#FFF1DC", "#3B3A5A", "#7C69C4"], ink=1.0)
def _():
    board = box(0, -0.1, 0.9, 0.46, 0.12)
    strings = U(seg(-0.55, 0.36, 0.0, 0.88, 0.05), seg(0.55, 0.36, 0.0, 0.88, 0.05))
    word = text("CHILL", 0, -0.1, 0.34, maxw=1.5)
    trim = U(sub(box(0, -0.1, 0.84, 0.4, 0.1), box(0, -0.1, 0.79, 0.35, 0.08)), circle(-0.55, 0.36, 0.08), circle(0.55, 0.36, 0.08))
    return [board, strings, word, trim]


@sticker("lofi", "timer", "Study timer", ["#FF8A7A", "#FFF1DC", "#D84A3A", "#3B3A5A"], ink=1.0)
def _():
    body = U(circle(0, 0.02, 0.76), box(0, -0.74, 0.4, 0.12, 0.05))
    face = circle(0, 0.02, 0.6)
    wedge = poly([(0, 0.02), (0, 0.6)] + [(0.6 * math.sin(t), 0.02 + 0.6 * math.cos(t)) for t in np.linspace(0.0, 1.9, 12)][1:] + [(0, 0.02)])
    features = U(arc(-0.24, -0.18, 0.1, math.pi + 0.3, 2 * math.pi - 0.3, 0.04), arc(0.14, -0.18, 0.1, math.pi + 0.3, 2 * math.pi - 0.3, 0.04), circle(-0.05, -0.36, 0.05),
                 seg(0, 0.02, 0, 0.5, 0.05), circle(0, 0.02, 0.09))
    return [body, face, wedge, features]


@sticker("lofi", "hoodie", "Cozy hoodie", ["#9FD3F5", "#6FB0E0", "#FFF1DC", "#3B3A5A"], ink=1.0)
def _():
    hood = circle(0.0, 0.5, 0.3)
    torso = U(box(0.0, -0.12, 0.42, 0.62, 0.1), taper(-0.34, 0.4, -0.84, -0.4, 0.17, 0.15), taper(0.34, 0.4, 0.84, -0.4, 0.17, 0.15))
    body = U(hood, torso)
    shade = _lowright(body, 0.25)
    pocket = U(box(0.0, -0.4, 0.28, 0.16, 0.05), ellipse(0.0, 0.52, 0.16, 0.18))
    strings = U(seg(-0.1, 0.4, -0.1, 0.02, 0.035), seg(0.1, 0.4, 0.1, 0.02, 0.035))
    return [body, shade, pocket, strings]


@sticker("lofi", "pixstar", "Pixel star", ["#FFD27A", "#E8A040", "#FFFFFF", "#B8A6E8"], ink=1.0)
def _():
    rows = ["....#....", "....#....", "...###...", "#########", ".#######.", "..#####..", "..#####..", ".###.###.", ".##...##."]
    star_ = pix(rows, 0.05, 0.0, 0.17)
    shade = pix(pixsub(rows, lambda i, j, w, h: i + j > 9), 0.05, 0.0, 0.17)
    shine = pix(pixsub(rows, lambda i, j, w, h: (i, j) in ((3, 3), (4, 3), (4, 4), (3, 4), (4, 2))), 0.05, 0.0, 0.17)
    sparkle = U(star(-0.62, 0.64, 4, 0.18, 0.045), star(0.66, 0.62, 4, 0.14, 0.035))
    return [star_, shade, shine, sparkle]


@sticker("lofi", "wavecloud", "Wave cloud", ["#E8DEFF", "#B8A6E8", "#7C69C4", "#FFFFFF"], ink=1.0)
def _():
    cloud = U(circle(-0.46, -0.1, 0.3), circle(-0.1, 0.12, 0.46), circle(0.44, -0.04, 0.34), box(0.0, -0.26, 0.76, 0.2, 0.18))
    shade = _lowright(cloud, 0.3)
    bars = U(*[box(-0.5 + 0.14 * k, -0.08, 0.05, h, 0.025) for k, h in enumerate([0.1, 0.2, 0.32, 0.16, 0.26, 0.38, 0.2, 0.12, 0.24])])
    notes = U(star(0.55, 0.62, 4, 0.14, 0.035), star(-0.62, 0.52, 4, 0.12, 0.03))
    waves = inter(bars, cloud)
    return [cloud, shade, waves, notes]
