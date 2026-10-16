PACK = ("sports", "Sports", False)
PRO_IDS = {"trophy", "medal", "scoreboard", "podium", "mvp"}


def _lowright(d, c=0.3):
    """The lower-right slice of shape d (the one shade layer)."""
    return inter(d, c - (X - Y) * 0.7)


def _blk(x0, x1, y0, y1):
    return box((x0 + x1) / 2, (y0 + y1) / 2, (x1 - x0) / 2, (y1 - y0) / 2, 0.03)


@sticker("sports", "trophy", "Cup", ["#FFC531", "#E09A12", "#5A3420", "#FFFFFF"], ink=1.0)
def _():
    bowl = poly(spline([(-0.36, 0.84), (0.36, 0.84), (0.32, 0.32), (0.13, 0.04), (-0.13, 0.04), (-0.32, 0.32)], n=6))
    handles = U(inter(shell(circle(-0.46, 0.5, 0.17), 0.07), X + 0.34), inter(shell(circle(0.46, 0.5, 0.17), 0.07), 0.34 - X))
    cup = U(bowl, handles, box(0, -0.12, 0.09, 0.17))
    shade = _lowright(cup, 0.25)
    base = U(box(0, -0.38, 0.34, 0.1, 0.03), box(0, -0.62, 0.52, 0.15, 0.04))
    plaque = U(box(0, -0.62, 0.24, 0.07, 0.02), star(0, 0.46, 5, 0.19, 0.08))
    return [cup, shade, base, plaque]


@sticker("sports", "medal", "Gold medal", ["#E3172F", "#FFC531", "#E09A12", "#FFFFFF"], ink=1.0)
def _():
    ribbon = U(poly([(-0.62, 0.9), (-0.2, 0.9), (0.2, 0.06), (-0.22, 0.06)]), poly([(0.62, 0.9), (0.2, 0.9), (-0.2, 0.06), (0.22, 0.06)]))
    disc = circle(0, -0.3, 0.52)
    rim = shell(circle(0, -0.3, 0.4), 0.035)
    mark = text("1", 0.0, -0.3, 0.36)
    return [ribbon, disc, rim, mark]


@sticker("sports", "whistle", "Whistle", ["#E3172F", "#9D1220", "#15131A", "#C9CED6"], ink=1.0)
def _():
    with rotated(0.2):
        body = U(circle(0.22, -0.05, 0.44), box(-0.44, 0.1, 0.4, 0.18, 0.06))
        shade = _lowright(body, 0.2)
        holes = U(circle(0.22, -0.05, 0.2), box(-0.3, 0.22, 0.2, 0.05))
        loop = shell(circle(0.42, 0.46, 0.17), 0.08)
    return [body, shade, holes, loop]


@sticker("sports", "stopwatch", "Stopwatch", ["#E3172F", "#9D1220", "#FFFFFF", "#15131A"], ink=1.0)
def _():
    case = U(circle(0, -0.1, 0.66), box(0, 0.64, 0.1, 0.12, 0.03), box(0, 0.74, 0.17, 0.06, 0.03), seg(0.46, 0.46, 0.62, 0.62, 0.07))
    shade = _lowright(case, 0.25)
    face = circle(0, -0.1, 0.5)
    marks = U(box(0, 0.28, 0.04, 0.08), box(0, -0.48, 0.04, 0.08), box(0.38, -0.1, 0.08, 0.04), box(-0.38, -0.1, 0.08, 0.04),
              seg(0, -0.1, 0.22, 0.14, 0.04), circle(0, -0.1, 0.07))
    return [case, shade, face, marks]


@sticker("sports", "sole", "Sole print", ["#FF7A1A", "#C2540A", "#15131A", "#FFE0B8"], ink=1.0)
def _():
    with rotated(0.25):
        sole = smin(ellipse(0.0, 0.3, 0.4, 0.55), ellipse(0.0, -0.52, 0.27, 0.34), 0.25)
        shade = _lowright(sole, 0.2)
        tread = U(*[polyline([(-0.22, y), (0.0, y + 0.09), (0.22, y)], 0.04) for y in (0.1, 0.3, 0.5, 0.7)])
        heel = shell(circle(0, -0.5, 0.17), 0.045)
    return [sole, shade, tread, heel]


@sticker("sports", "basketball", "Basketball", ["#FF8A1F", "#C2540A", "#15131A", "#FFD9A8"], ink=1.0)
def _():
    ball = circle(0, 0, 0.86)
    shade = sub(ball, circle(-0.1, 0.1, 0.84))
    lines = inter(U(seg(0, -0.86, 0, 0.86, 0.05), seg(-0.86, 0, 0.86, 0, 0.05), shell(circle(-1.02, 0, 0.74), 0.05), shell(circle(1.02, 0, 0.74), 0.05)), ball)
    shine = U(seg(-0.5, 0.45, -0.34, 0.6, 0.05), circle(-0.58, 0.36, 0.05))
    return [ball, shade, lines, shine]


@sticker("sports", "soccer", "Soccer ball", ["#FFFFFF", "#C9CED6", "#15131A", "#FFFFFF"], ink=1.0)
def _():
    ball = circle(0, 0, 0.86)
    shade = sub(ball, circle(-0.1, 0.1, 0.84))
    outer = [poly([(0.83 * math.cos(a) + 0.24 * math.cos(a + k * 1.2566 + 3.1416), 0.83 * math.sin(a) + 0.24 * math.sin(a + k * 1.2566 + 3.1416))
                   for k in range(5)]) for a in [math.radians(18 + 72 * i) for i in range(5)]]
    patches = inter(U(regpoly(0, 0, 5, 0.27), *outer, *[seg(0.27 * math.cos(math.radians(90 + 72 * i)), 0.27 * math.sin(math.radians(90 + 72 * i)),
                      0.6 * math.cos(math.radians(90 + 72 * i)), 0.6 * math.sin(math.radians(90 + 72 * i)), 0.035) for i in range(5)]), ball)
    shine = U(seg(-0.52, 0.42, -0.36, 0.58, 0.05), circle(-0.6, 0.34, 0.05))
    return [ball, shade, patches, shine]


@sticker("sports", "baseball", "Baseball", ["#F4F1EA", "#C9C3B6", "#E3172F", "#FFFFFF"], ink=1.0)
def _():
    ball = circle(0, 0, 0.86)
    shade = sub(ball, circle(-0.1, 0.1, 0.84))
    seams = []
    for s in (-1, 1):
        cx = s * 1.18
        seams.append(arc(cx, 0, 0.78, math.pi * (0 if s < 0 else 1) - 0.62, math.pi * (0 if s < 0 else 1) + 0.62, 0.035))
        for k in range(-4, 5):
            a = math.pi * (0 if s < 0 else 1) + k * 0.15
            seams.append(seg(cx + 0.7 * math.cos(a), 0.7 * math.sin(a), cx + 0.86 * math.cos(a), 0.86 * math.sin(a), 0.03))
    stitches = inter(U(*seams), ball)
    shine = U(seg(-0.5, 0.45, -0.34, 0.6, 0.05), circle(-0.58, 0.36, 0.05))
    return [ball, shade, stitches, shine]


@sticker("sports", "racket", "Racket", ["#E3172F", "#F4F1EA", "#2B2E33", "#FFE14A"], ink=1.0)
def _():
    with rotated(-0.7, 0.0, 0.0, 0.0, 0.0):
        head = ellipse(0, 0.4, 0.46, 0.54)
        frame = shell(head, 0.11)
        strings = inter(U(*[seg(x, -0.2, x, 1.0, 0.045) for x in (-0.13, 0.13)], *[seg(-0.5, y, 0.5, y, 0.045) for y in (0.14, 0.4, 0.66)]), head)
        handle = U(poly([(-0.14, -0.08), (0.14, -0.08), (0.08, -0.3), (-0.08, -0.3)]), box(0, -0.6, 0.09, 0.34, 0.03))
        grip = box(0, -0.66, 0.13, 0.18, 0.03)
    return [frame, strings, handle, grip]


@sticker("sports", "finish", "Finish line", ["#C9CED6", "#15131A", "#FFFFFF", "#FFFFFF"], ink=1.0)
def _():
    posts = U(box(-0.84, -0.1, 0.09, 0.84), box(0.84, -0.1, 0.09, 0.84), box(-0.84, -0.88, 0.14, 0.04), box(0.84, -0.88, 0.14, 0.04))
    banner = box(0, 0.4, 0.8, 0.36, 0.04)
    checker = U(pix(["#.#.#.#.#.#.#.#"], 0, 0.66, 0.1), pix([".#.#.#.#.#.#.#."], 0, 0.18, 0.1))
    word = text("FINISH", 0.0, 0.42, 0.2, maxw=1.2)
    return [posts, banner, checker, word]


@sticker("sports", "podium", "Podium", ["#6A7BD6", "#4A5AAE", "#FFFFFF", "#FFC531"], ink=1.0)
def _():
    steps = U(_blk(-0.28, 0.28, -0.8, 0.12), _blk(-0.88, -0.3, -0.8, -0.14), _blk(0.3, 0.88, -0.8, -0.34))
    shade = _lowright(steps, 0.1)
    numbers = U(text("1", 0.0, -0.22, 0.3), text("2", -0.59, -0.42, 0.22), text("3", 0.59, -0.55, 0.2))
    winner = U(star(0.0, 0.42, 5, 0.22, 0.095), circle(-0.59, 0.1, 0.1), circle(0.59, -0.1, 0.1))
    return [steps, shade, numbers, winner]


@sticker("sports", "foamfinger", "Foam finger", ["#E3172F", "#9D1220", "#FFFFFF", "#FFFFFF"], ink=1.0)
def _():
    hand = U(box(0.0, -0.2, 0.4, 0.42, 0.12), box(-0.02, 0.5, 0.15, 0.42, 0.12), box(-0.5, 0.0, 0.14, 0.2, 0.08, 0.5),
             *[circle(x, 0.2, 0.14) for x in (0.12, 0.28)])
    shade = _lowright(hand, 0.25)
    cuff = box(0.0, -0.66, 0.4, 0.12, 0.03)
    word = text("#1", 0.0, -0.2, 0.32, maxw=0.6)
    return [hand, shade, cuff, word]


@sticker("sports", "pennant", "Pennant", ["#2E5BFF", "#1E3DB0", "#F4F1EA", "#FFFFFF"], ink=1.0)
def _():
    with rotated(0.15):
        flag = poly([(-0.62, 0.5), (0.74, 0.0), (-0.62, -0.5)])
        shade = _lowright(flag, 0.2)
        pole = box(-0.7, -0.05, 0.06, 0.7, 0.02)
    word = text("#1", -0.2, -0.02, 0.38, ang=0.0, maxw=0.7)
    return [flag, shade, pole, word]


@sticker("sports", "coach", "Coach", ["#F2B58C", "#2E5BFF", "#15131A", "#E3172F"], ink=1.0)
def _():
    face = circle(0, -0.05, 0.64)
    cap = U(inter(circle(0, -0.05, 0.68), 0.26 - Y), box(0.3, 0.27, 0.55, 0.075, 0.03))
    features = U(circle(-0.22, 0.04, 0.07), circle(0.22, 0.04, 0.07), box(-0.22, 0.16, 0.14, 0.03, 0.01, 0.2), box(0.22, 0.16, 0.14, 0.03, 0.01, -0.2))
    whistle = U(box(0.06, -0.32, 0.2, 0.1, 0.04), circle(0.3, -0.32, 0.13))
    return [face, cap, features, whistle]


@sticker("sports", "scoreboard", "Scoreboard", ["#8A8F98", "#15131A", "#FFB020", "#E3172F"], ink=1.0)
def _():
    board = U(box(0, 0.12, 0.9, 0.56, 0.08), box(-0.5, -0.7, 0.1, 0.22), box(0.5, -0.7, 0.1, 0.22))
    screen = box(0, 0.12, 0.8, 0.45, 0.05)
    digits = text("00:00", 0.0, 0.12, 0.38, maxw=1.4)
    lamps = U(circle(-0.62, 0.52, 0.045), circle(-0.42, 0.52, 0.045), circle(0.42, 0.52, 0.045), circle(0.62, 0.52, 0.045))
    return [board, screen, digits, lamps]


@sticker("sports", "mvp", "MVP badge", ["#2E5BFF", "#FFFFFF", "#FFE14A", "#FFFFFF"], ink=1.0)
def _():
    shield = poly([(-0.74, 0.66), (0.74, 0.66), (0.74, 0.05), (0.5, -0.4), (0.0, -0.82), (-0.5, -0.4), (-0.74, 0.05)])
    trim = shell(shield - 0.1, 0.03)
    bolt = poly([(0.14, 0.62), (-0.2, 0.16), (0.0, 0.16), (-0.12, -0.1), (0.24, 0.28), (0.04, 0.28), (0.22, 0.62)])
    word = text("MVP", 0.0, -0.32, 0.3, maxw=1.0)
    return [shield, trim, bolt, word]
