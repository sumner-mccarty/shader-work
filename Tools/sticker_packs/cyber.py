PACK = ("cyber", "Cyber Glitch", False)
PRO_IDS = {"glitchskull", "circuitheart", "glitcheye", "neoncat", "errorwin"}


def _lowright(d, c=0.3):
    """The lower-right slice of shape d (the one shade layer)."""
    return inter(d, c - (X - Y) * 0.7)


def _heart_pts(s, cy=0.0, n=64):
    pts = []
    for k in range(n):
        t = 2 * math.pi * k / n
        hx = 16 * math.sin(t) ** 3
        hy = 13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)
        pts.append((hx * s / 17.0, cy + hy * s / 17.0))
    return pts


def _glint(cx, cy, k=1.0):
    """The upper-left highlight: a short bar with a dot under it."""
    return U(seg(cx, cy, cx + 0.1 * k, cy + 0.14 * k, 0.04 * k), circle(cx - 0.02 * k, cy - 0.13 * k, 0.04 * k))


def _slide(rs):
    """Rows 2 and 7 pushed one cell left / right: the glitch slices."""
    out = []
    for j, r in enumerate(rs):
        out.append((r[1:] + ".") if j == 2 else (("." + r[:-1]) if j == 7 else r))
    return out


def _arrow(dx, dy=0.0):
    pts = [(-0.45, 0.8), (-0.45, -0.52), (-0.16, -0.26), (0.02, -0.74), (0.2, -0.66), (0.04, -0.2), (0.4, -0.2)]
    return poly([(x * 0.9 + dx, y * 0.9 + dy) for x, y in pts])


def _qr_rows():
    rng = np.random.RandomState(7)
    g = rng.rand(9, 9) > 0.5
    for r, c in ((0, 0), (0, 6), (6, 0)):
        g[r:r + 3, c:c + 3] = True
    g[6:8, 6:8] = False
    return ["".join("#" if v else "." for v in row) for row in g]


@sticker("cyber", "glitchskull", "Glitch skull", ["#FF2BD6", "#F4F1EA", "#12102A", "#19F2FF"], ink=1.0)
def _():
    rows = ["..#######..", ".#########.", "###########", "###########", "###########", "###########", ".#########.", "..#######..",
            "..#######..", "..#.#.#.#.."]
    holes = ["...........", "...........", "...........", "..###.###..", "..###.###..", "..###.###..", ".....#.....", "...........",
             "...........", "..........."]
    ghost = pix(rows, -0.15, 0.0, 0.135)
    skull = pix(_slide(rows), 0, 0.0, 0.135)
    eyes = pix(_slide(holes), 0, 0.0, 0.135)
    tear = pix(["..........." if j != 6 else "..#########.." for j in range(10)], 0, 0.0, 0.135)
    return [ghost, skull, eyes, tear]


@sticker("cyber", "circuitheart", "Circuit heart", ["#2A1B6B", "#C7BBFF", "#19F2FF", "#FF2BD6"], ink=1.0)
def _():
    body = poly(_heart_pts(0.92, 0.04))
    shine = _glint(-0.5, 0.5)
    traces = U(polyline([(0.0, 0.3), (0.0, -0.1), (0.3, -0.4)], 0.035), polyline([(-0.3, 0.1), (-0.22, 0.0), (-0.05, -0.17)], 0.035),
               polyline([(0.5, 0.3), (0.25, 0.3), (0.25, 0.08)], 0.035), polyline([(-0.3, -0.2), (-0.12, -0.38), (-0.12, -0.55)], 0.035))
    nodes = U(circle(0.3, -0.4, 0.07), circle(0.5, 0.3, 0.07), circle(0.25, 0.08, 0.06), circle(-0.3, -0.2, 0.06),
              circle(-0.12, -0.55, 0.07), circle(0.0, 0.3, 0.07), circle(-0.3, 0.1, 0.06))
    return [body, shine, traces, nodes]


@sticker("cyber", "glitcheye", "Glitch eye", ["#F4F1EA", "#7A2BFF", "#12102A", "#19F2FF"], ink=1.0)
def _():
    lens = inter(circle(0, -0.75, 1.1), circle(0, 0.75, 1.1))
    iris = inter(circle(0.0, 0.0, 0.34), lens)
    pupil = U(circle(0.0, 0.0, 0.135), circle(-0.1, 0.1, 0.0))
    bars = inter(U(box(0.38, 0.14, 0.42, 0.07), box(-0.34, -0.12, 0.44, 0.07), box(0.1, -0.28, 0.5, 0.05), _glint(-0.1, 0.02, 0.5)), lens)
    return [lens, iris, pupil, bars]


@sticker("cyber", "robotarm", "Robot arm", ["#C9CED6", "#8A8F98", "#12102A", "#19F2FF"], ink=1.0)
def _():
    arm = U(box(-0.6, -0.76, 0.34, 0.15, 0.05), seg(-0.6, -0.5, -0.26, 0.12, 0.24), seg(-0.26, 0.12, 0.2, 0.0, 0.2))
    shade = _lowright(arm, 0.2)
    joints = U(circle(-0.6, -0.5, 0.28), circle(-0.26, 0.12, 0.3), circle(0.2, 0.0, 0.2))
    claw = U(taper(0.2, 0.0, 0.72, 0.4, 0.13, 0.08), taper(0.2, 0.0, 0.72, -0.4, 0.13, 0.08))
    return [arm, shade, joints, claw]


@sticker("cyber", "chip", "Chip", ["#FFC531", "#12102A", "#19F2FF", "#FF2BD6"], ink=1.0)
def _():
    pins = U(*[box(x, y, 0.07, 0.17) for x in (-0.33, -0.11, 0.11, 0.33) for y in (-0.62, 0.62)],
             *[box(x, y, 0.17, 0.07) for y in (-0.33, -0.11, 0.11, 0.33) for x in (-0.62, 0.62)])
    body = box(0, 0, 0.52, 0.52, 0.08)
    die = shell(box(0, 0, 0.3, 0.3, 0.05), 0.045)
    dot = circle(-0.36, 0.36, 0.06)
    return [pins, body, die, dot]


@sticker("cyber", "cursor", "Glitch cursor", ["#19F2FF", "#F4F1EA", "#C9C3B6"], ink=1.0)
def _():
    ghost = _arrow(0.22, -0.06)
    arrow = U(inter(_arrow(0.0), 0.3 - Y), inter(_arrow(0.12), inter(Y - 0.3, -0.1 - Y)), inter(_arrow(-0.06), Y + 0.1))
    shade = _lowright(arrow, 0.0)
    return [ghost, arrow, shade]


@sticker("cyber", "loadbar", "Loading bar", ["#12102A", "#2A1B6B", "#19F2FF", "#FFFFFF"], ink=1.0)
def _():
    frame = box(0, -0.3, 0.88, 0.36, 0.14)
    track = box(0, -0.3, 0.74, 0.24, 0.08)
    fill = U(*[box(-0.6 + 0.24 * k, -0.3, 0.095, 0.17, 0.03) for k in range(5)])
    label = text("78%", 0.0, 0.4, 0.52, maxw=1.2)
    return [frame, track, fill, label]


@sticker("cyber", "errorwin", "Error window", ["#12102A", "#FF2BD6", "#FFFFFF", "#4A3FA0"], ink=1.0)
def _():
    window = box(0, -0.02, 0.88, 0.7, 0.1)
    bar = inter(window, 0.3 - Y)
    marks = U(*[circle(x, 0.5, 0.06) for x in (-0.68, -0.5)], seg(0.58, 0.4, 0.74, 0.6, 0.045), seg(0.58, 0.6, 0.74, 0.4, 0.045),
              box(0.0, -0.06, 0.08, 0.22, 0.03), circle(0.0, -0.42, 0.085))
    shine = _glint(-0.62, -0.3)
    return [window, bar, marks, shine]


@sticker("cyber", "qrsquare", "Code square", ["#F4F1EA", "#12102A", "#19F2FF", "#FF2BD6"], ink=1.0)
def _():
    rows = _qr_rows()
    plate = box(0, 0, 0.88, 0.88, 0.1)
    code = pix(rows, 0, 0, 0.18)
    accent = pix(["........." for _ in range(6)] + ["......##.", "......##.", "........."], 0, 0, 0.18)
    return [plate, code, accent, None]


@sticker("cyber", "neoncat", "Neon cat", ["#12102A", "#FF2BD6", "#19F2FF", "#4A3FA0"], ink=1.0)
def _():
    head = U(ellipse(0, -0.12, 0.7, 0.56), poly([(-0.64, 0.1), (-0.58, 0.82), (-0.14, 0.4)]), poly([(0.64, 0.1), (0.58, 0.82), (0.14, 0.4)]))
    outline = U(shell(head - 0.03, 0.045), *[seg(s * 0.3, y0, s * 0.66, y1, 0.035) for s in (-1, 1) for y0, y1 in ((-0.28, -0.22), (-0.38, -0.46))],
                poly([(-0.08, -0.2), (0.08, -0.2), (0.0, -0.3)]))
    eyes = U(ellipse(-0.27, -0.02, 0.13, 0.08, 0.3), ellipse(0.27, -0.02, 0.13, 0.08, -0.3))
    shine = _glint(-0.5, 0.18, 1.2)
    return [head, outline, eyes, shine]


@sticker("cyber", "visor", "VR visor", ["#F4F1EA", "#7A2BFF", "#12102A", "#19F2FF"], ink=1.0)
def _():
    headband = inter(shell(ellipse(0, 0.0, 0.8, 0.66), 0.08), 0.42 - np.abs(X))
    body = sub(box(0, 0.0, 0.74, 0.4, 0.28), circle(0, -0.5, 0.17))
    lens = sub(box(0, 0.02, 0.62, 0.3, 0.2), circle(0, -0.5, 0.2))
    glow = poly([(-0.42, 0.22), (-0.22, 0.22), (-0.38, -0.2), (-0.58, -0.2)])
    return [headband, body, lens, glow]


@sticker("cyber", "battery", "Battery", ["#F4F1EA", "#8A8F98", "#7CFF4F", "#FFE14A"], ink=1.0)
def _():
    body = box(-0.05, 0.0, 0.76, 0.42, 0.12)
    cap = box(0.8, 0.0, 0.1, 0.16, 0.04)
    charge = U(*[box(-0.54 + 0.28 * k, 0.0, 0.1, 0.26, 0.04) for k in range(3)])
    spark = poly([(0.42, 0.28), (0.18, -0.02), (0.34, -0.02), (0.26, -0.28), (0.52, 0.06), (0.36, 0.06), (0.46, 0.28)])
    return [body, cap, charge, spark]


@sticker("cyber", "wifi", "Wi-Fi", ["#19F2FF", "#0E8FA0", "#12102A", "#FFFFFF"], ink=1.0)
def _():
    tile = box(0, 0, 0.74, 0.74, 0.2)
    shade = _lowright(tile, 0.35)
    arcs = U(*[arc(0, -0.5, r, math.radians(48), math.radians(132), 0.075) for r in (0.38, 0.68, 0.98)])
    dot = circle(0, -0.5, 0.12)
    return [tile, shade, arcs, dot]


@sticker("cyber", "err404", "404", ["#12102A", "#FF2BD6", "#19F2FF", "#4A3FA0"], ink=1.0)
def _():
    tile = box(0, 0, 0.92, 0.58, 0.12)
    ghost = text("404", 0.06, -0.06, 0.58, maxw=1.5)
    word = text("404", 0.0, 0.0, 0.58, maxw=1.5)
    shine = _glint(-0.82, 0.3, 0.8)
    return [tile, ghost, word, shine]


@sticker("cyber", "lag", "LAG", ["#12102A", "#19F2FF", "#FF2BD6", "#FFFFFF"], ink=1.0)
def _():
    disc = circle(0, 0, 0.9)
    spinner = arc(0, 0, 0.74, math.radians(30), math.radians(300), 0.07)
    ghost = text("LAG", 0.05, -0.04, 0.38, maxw=1.0)
    word = text("LAG", 0.0, 0.0, 0.38, maxw=1.0)
    return [disc, spinner, ghost, word]


@sticker("cyber", "hood", "Hacker hood", ["#7A4BFF", "#C7BBFF", "#0B0A14", "#19F2FF"], ink=1.0)
def _():
    hood = U(ellipse(0, 0.16, 0.54, 0.62), ellipse(0, -0.6, 0.76, 0.36))
    shine = _glint(-0.5, 0.45, 1.2)
    face = ellipse(0.0, 0.06, 0.34, 0.39)
    eyes = U(ellipse(-0.15, 0.1, 0.11, 0.065, 0.2), ellipse(0.15, 0.1, 0.11, 0.065, -0.2))
    return [hood, shine, face, eyes]