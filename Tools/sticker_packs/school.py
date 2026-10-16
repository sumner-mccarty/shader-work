PACK = ("school", "Back to School", False)
PRO_IDS = {"bus", "backpack", "chalkboard", "lunchbox", "crayons", "bell"}


def _shade(d, dx=-0.1, dy=0.1):
    """Lower-right shade: the shape minus a copy of itself nudged up-left (screen space, even inside a rotated block)."""
    s = 96.0
    moved = np.roll(d, (int(round(-dy * s)), int(round(dx * s))), axis=(0, 1))
    return sub(d, moved)


def _turn(ang, make, cx=0.0, cy=0.0):
    """Draw upright inside `make()`, get the list of layers turned by ang."""
    with rotated(ang, cx, cy):
        return make()


# ---- pencil ----
def _pencil():
    barrel = box(0, 0.04, 0.27, 0.5, 0.03)
    shade = inter(barrel, X - 0.08)
    tip = poly([(-0.27, -0.46), (0.27, -0.46), (0.0, -0.96)])
    eraser = U(box(0, 0.72, 0.27, 0.24, 0.08), box(0, 0.56, 0.27, 0.06))
    return [barrel, shade, tip, eraser]


@sticker("school", "pencil", "Pencil", ["#FFC531", "#E09A12", "#F2C894", "#F0708A"], ink=1.0)
def _():
    barrel, shade, tip, eraser = _turn(2.36, _pencil)
    return [barrel, shade, tip, eraser]


# ---- backpack ----
def _pack_body():
    return box(0, -0.1, 0.62, 0.72, 0.3)


@sticker("school", "backpack", "Backpack", ["#E3472F", "#A82A18", "#2F7BE0", "#FFD23A"], ink=1.0)
def _():
    body = U(_pack_body(), arc(0, 0.6, 0.2, 0.0, math.pi, 0.07))
    shade = _shade(_pack_body())
    pocket = box(0, -0.42, 0.44, 0.3, 0.12)
    trim = U(box(0, -0.12, 0.44, 0.05, 0.02), box(0, 0.12, 0.08, 0.08, 0.03), seg(-0.62, -0.2, -0.62, -0.62, 0.05), seg(0.62, -0.2, 0.62, -0.62, 0.05))
    return [body, shade, pocket, trim]


# ---- notebook ----
@sticker("school", "notebook", "Notebook", ["#2F7BE0", "#1B4FA8", "#FFFFFF", "#8A8F98"], ink=1.0)
def _():
    cover = box(0.06, 0, 0.62, 0.84, 0.08)
    shade = _shade(cover)
    label = U(box(0.1, 0.22, 0.36, 0.26, 0.05), box(0.1, -0.34, 0.36, 0.06, 0.02), box(0.1, -0.52, 0.28, 0.06, 0.02))
    rings = U(*[ring(-0.56, y, 0.12, 0.055) for y in (-0.64, -0.32, 0.0, 0.32, 0.64)])
    return [cover, shade, label, rings]


# ---- ruler ----
def _ruler():
    body = box(0, 0, 0.84, 0.31, 0.05)
    shade = inter(body, -0.04 - Y)
    marks = U(*[box(-0.7 + 0.2 * k, 0.15, 0.03, 0.14 if k % 2 == 0 else 0.09) for k in range(8)])
    hole = circle(0.66, -0.1, 0.08)
    return [body, shade, marks, hole]


@sticker("school", "ruler", "Ruler", ["#FFC531", "#E09A12", "#1A1410", "#FFF4C7"], ink=1.0)
def _():
    body, shade, marks, hole = _turn(0.6, _ruler)
    return [body, shade, marks, hole]


# ---- apple ----
def _apple_body():
    return U(smin(circle(-0.24, -0.1, 0.5), circle(0.24, -0.1, 0.5), 0.2), circle(0, -0.45, 0.4)) 


@sticker("school", "apple", "Apple", ["#E3172F", "#A80E22", "#FFFFFF", "#2E9E4F"], ink=1.0)
def _():
    body = _apple_body()
    shade = _shade(body, -0.12, 0.12)
    shine = U(brush([(-0.5, 0.04), (-0.46, 0.26), (-0.32, 0.38)], [0.05, 0.05, 0.045]), circle(-0.52, -0.2, 0.05))
    leaf = U(brush([(0.02, 0.4), (0.06, 0.62), (0.0, 0.8)], [0.05, 0.05, 0.04]), oval(0.3, 0.7, 0.26, 0.12, 0.45))
    return [body, shade, shine, leaf]


# ---- school bus ----
@sticker("school", "bus", "School bus", ["#FFC531", "#E09A12", "#9FE8FF", "#1A1410"], ink=1.0)
def _():
    body = U(box(-0.04, 0.08, 0.84, 0.52, 0.12), box(0.78, -0.16, 0.14, 0.26, 0.06))
    shade = inter(body, -0.1 - Y)
    glass = U(*[box(-0.62 + 0.28 * k, 0.28, 0.1, 0.15, 0.03) for k in range(4)], poly([(0.54, 0.43), (0.8, 0.43), (0.88, 0.0), (0.54, 0.0)]),
              circle(-0.52, -0.46, 0.08), circle(0.5, -0.46, 0.08))
    trim = U(box(-0.04, -0.12, 0.84, 0.045), circle(-0.52, -0.46, 0.22), circle(0.5, -0.46, 0.22), box(0.9, -0.34, 0.04, 0.06))
    return [body, shade, trim, glass]


# ---- calculator ----
@sticker("school", "calculator", "Calculator", ["#3FB6A8", "#1F8A7E", "#B7F26A", "#FF4F6E"], ink=1.0)
def _():
    body = box(0, 0, 0.58, 0.84, 0.12)
    shade = _shade(body)
    screen = box(0, 0.5, 0.44, 0.19, 0.05)
    keys = U(*[box(x, y, 0.12, 0.1, 0.03) for x in (-0.31, 0.0, 0.31) for y in (0.1, -0.14, -0.38)], box(0.0, -0.62, 0.43, 0.1, 0.03))
    return [body, shade, screen, keys]


# ---- lunch box ----
@sticker("school", "lunchbox", "Lunch box", ["#E3472F", "#A82A18", "#C9CED6", "#FFD23A"], ink=1.0)
def _():
    lid = inter(oval(0, 0.04, 0.86, 0.5), 0.04 - Y)
    base = box(0, -0.34, 0.84, 0.36, 0.12)
    body = U(lid, base)
    shade = _shade(body)
    metal = U(arc(0, 0.5, 0.3, 0.0, math.pi, 0.085), box(-0.36, 0.0, 0.11, 0.1, 0.03), box(0.36, 0.0, 0.11, 0.1, 0.03), box(0, 0.0, 0.84, 0.045))
    label = U(smin(circle(-0.1, -0.34, 0.2), circle(0.1, -0.34, 0.2), 0.1), oval(0.08, -0.12, 0.1, 0.05, 0.5), seg(0.0, -0.18, 0.0, -0.08, 0.04))
    return [body, shade, metal, label]


# ---- A+ star ----
@sticker("school", "aplus", "Gold star A+", ["#FFC531", "#E09A12", "#FFF4C7", "#C2182B"], ink=1.0)
def _():
    star_ = star(0, -0.02, 5, 0.94, 0.52) - 0.04
    shade = _shade(star_, -0.1, 0.1)
    shine = U(seg(-0.46, 0.46, -0.28, 0.62, 0.05), circle(-0.58, 0.34, 0.05))
    grade = text("A+", 0.0, -0.04, 0.44, maxw=0.7) - 0.015
    return [star_, shade, shine, grade]


# ---- chalkboard ----
@sticker("school", "chalkboard", "Chalkboard", ["#B9773A", "#2E5E48", "#FFFFFF", "#E3B98A"], ink=1.0)
def _():
    frame = box(0, 0.04, 0.9, 0.66, 0.06)
    board = box(0, 0.04, 0.78, 0.54, 0.03)
    chalk = U((text("ABC", 0.0, 0.18, 0.34, maxw=1.1) - 0.015), polyline([(-0.6, -0.26), (-0.3, -0.16), (0.0, -0.28), (0.3, -0.16), (0.6, -0.26)], 0.05))
    tray = box(0, -0.72, 0.7, 0.08, 0.03)
    return [frame, board, chalk, tray]


# ---- paper airplane ----
@sticker("school", "airplane", "Paper plane", ["#FFFFFF", "#BFD4EA", "#2F7BE0", "#8FB7EA"], ink=1.0)
def _():
    wing = poly([(-0.58, 0.2), (0.9, 0.68), (-0.02, -0.02)])
    fold = poly([(-0.02, -0.02), (0.9, 0.68), (0.1, -0.62), (0.04, -0.22)])
    trail = U(seg(-0.9, -0.2, -0.64, -0.34, 0.06), seg(-0.46, -0.44, -0.2, -0.56, 0.06), seg(-0.02, -0.66, 0.22, -0.74, 0.06))
    return [wing, fold, trail, None]


# ---- crayons ----
def _crayon(x, ytop, tilt, w=0.19):
    def make():
        body = box(x, (ytop - 0.3 - 0.9) / 2, w, (ytop - 0.3 + 0.9) / 2, 0.03)
        tip = poly([(x - w, ytop - 0.3), (x + w, ytop - 0.3), (x, ytop)])
        band = box(x, -0.34, w + 0.02, 0.24, 0.02)
        return U(body, tip), band
    return _turn(tilt, make, x, -0.9)


@sticker("school", "crayons", "Crayons", ["#E3172F", "#2F7BE0", "#FFC531", "#F2E3C2"], ink=1.0)
def _():
    red, red_band = _crayon(-0.55, 0.62, 0.1)
    yellow, yellow_band = _crayon(0.55, 0.5, -0.1)
    blue, blue_band = _crayon(0.0, 0.88, 0.0)
    paper = U(red_band, yellow_band, blue_band)
    return [red, blue, yellow, paper]


# ---- school bell ----
@sticker("school", "bell", "School bell", ["#FFC531", "#E09A12", "#FFF4C7", "#8A5A33"], ink=1.0)
def _():
    bell = poly(spline([(-0.16, 0.6), (0.16, 0.6), (0.4, 0.4), (0.48, 0.0), (0.58, -0.36), (0.84, -0.5), (0.84, -0.62), (-0.84, -0.62),
                        (-0.84, -0.5), (-0.58, -0.36), (-0.48, 0.0), (-0.4, 0.4)], n=8))
    shade = _shade(bell, -0.12, 0.1)
    shine = U(brush([(-0.3, 0.38), (-0.36, 0.1), (-0.42, -0.2)], [0.05, 0.05, 0.05]), circle(-0.5, -0.44, 0.04))
    handle = U(box(0, 0.78, 0.13, 0.2, 0.05), circle(0, -0.74, 0.14))
    return [bell, shade, shine, handle]


# ---- stack of books ----
@sticker("school", "books", "Books", ["#E3472F", "#2F7BE0", "#2E9E4F", "#FFF4E0"], ink=1.0)
def _():
    bottom = box(0.04, -0.58, 0.8, 0.22, 0.05)
    middle = box(-0.08, -0.12, 0.7, 0.22, 0.05)
    top = box(0.1, 0.34, 0.74, 0.22, 0.05)
    pages = U(box(0.7, -0.58, 0.14, 0.16, 0.02), box(0.52, -0.12, 0.14, 0.16, 0.02), box(0.72, 0.34, 0.14, 0.16, 0.02),
              box(-0.5, -0.58, 0.04, 0.22), box(-0.5, 0.34, 0.04, 0.22), box(-0.6, -0.12, 0.04, 0.22))
    return [bottom, middle, top, pages]


# ---- glue bottle ----
@sticker("school", "glue", "Glue", ["#FFFFFF", "#BFD4EA", "#FF8A1C", "#2F7BE0"], ink=1.0)
def _():
    bottle = U(box(0, -0.22, 0.54, 0.52, 0.16), taper(0, 0.3, 0, 0.5, 0.4, 0.2))
    shade = _shade(bottle)
    cap = U(poly([(-0.2, 0.46), (0.2, 0.46), (0.11, 0.74), (-0.11, 0.74)]) - 0.03, circle(0.0, 0.8, 0.08))
    face = U(circle(-0.15, -0.2, 0.07), circle(0.15, -0.2, 0.07), arc(0, -0.2, 0.2, math.radians(215), math.radians(325), 0.04))
    label = sub(box(0, -0.28, 0.54, 0.3, 0.05), face)
    return [bottle, shade, cap, label]


# ---- LATE! stamp ----
def _late():
    card = box(0, 0, 0.9, 0.54, 0.08)
    shade = _shade(card)
    border = shell(box(0, 0, 0.8, 0.44, 0.05), 0.04)
    word = text("LATE!", 0, 0.0, 0.42, maxw=1.4) - 0.015
    return [card, shade, U(border, word)]


@sticker("school", "late", "Late stamp", ["#F4F1EA", "#C9C3B6", "#E3172F", "#1A1410"], ink=1.0)
def _():
    card, shade, ink_ = _turn(0.1, _late)
    return [card, shade, ink_, None]


# ---- recorder ----
def _recorder():
    tube = U(taper(0, 0.5, 0, -0.5, 0.17, 0.21), taper(0, -0.5, 0, -0.76, 0.21, 0.31))
    shade = inter(tube, X - 0.07)
    holes = U(circle(0, 0.28, 0.095), circle(0, 0.0, 0.095), circle(0, -0.28, 0.095))
    beak = U(poly([(-0.19, 0.48), (0.19, 0.48), (0.12, 0.82), (-0.12, 0.82)]), box(0, 0.4, 0.22, 0.05, 0.02))
    return [tube, shade, holes, beak]


@sticker("school", "recorder", "Recorder", ["#E3472F", "#A82A18", "#1A1410", "#FFFFFF"], ink=1.0)
def _():
    tube, shade, holes, beak = _turn(-0.5, _recorder)
    return [tube, shade, holes, beak]
