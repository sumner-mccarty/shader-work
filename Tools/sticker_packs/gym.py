PACK = ("gym", "Gym", False)
PRO_IDS = {"glove", "barbell", "kettlebell", "beast", "pr"}

IRON, IRONS = "#3A3F47", "#1B1D22"
STEEL = "#C9CED6"
RED, REDS = "#E3172F", "#8E0F1E"
WHITE = "#FFFFFF"
BLUE, BLUES = "#2F9BE8", "#1B62A8"
TEAL, TEALS = "#2EC4B6", "#17897E"
PINK = "#FF5C8A"
SKIN, SKINS = "#F2A66B", "#C2723A"
YEL = "#FFC531"
ORANGE, ORANGES = "#FF8A1F", "#B84A0A"


def _lowright(d, c=0.3):
    """The lower-right slice of shape d (the one shade layer)."""
    return inter(d, c - (X - Y) * 0.7)


def _in(d, *strokes):
    """Highlight strokes kept inside shape d."""
    return inter(U(*strokes), d + 0.01)


@sticker("gym", "dumbbell", "Dumbbell", ["#2F6BFF", "#1A3C9E", STEEL, WHITE], ink=1.0)
def _():
    with rotated(0.5):
        body = U(box(-0.5, 0, 0.18, 0.36, 0.08), box(0.5, 0, 0.18, 0.36, 0.08), box(-0.72, 0, 0.07, 0.22, 0.04), box(0.72, 0, 0.07, 0.22, 0.04))
        handle = box(0, 0, 0.36, 0.09, 0.04)
        shine = _in(body, seg(-0.55, 0.26, -0.55, 0.08, 0.04), seg(0.45, 0.26, 0.45, 0.08, 0.04))
        shine = U(shine, seg(-0.3, 0.03, 0.2, 0.03, 0.025))
        shade = _lowright(body, 0.0) if False else None
    shade = _lowright(body, 0.25)
    return [body, shade, handle, shine]


@sticker("gym", "kettlebell", "Kettlebell", [IRON, IRONS, YEL, WHITE], ink=1.0)
def _():
    bell = U(circle(0, -0.22, 0.52), box(0, -0.66, 0.32, 0.1, 0.04))
    grip = sub(box(0, 0.36, 0.36, 0.3, 0.16), box(0, 0.3, 0.19, 0.17, 0.09))
    body = U(bell, grip)
    shade = _lowright(body, 0.3)
    label = oval(0, -0.24, 0.24, 0.16)
    shine = _in(body, arc(0, -0.22, 0.4, math.radians(115), math.radians(165), 0.04), seg(-0.3, 0.46, -0.1, 0.58, 0.035))
    return [body, shade, label, shine]


@sticker("gym", "barbell", "Barbell", [RED, REDS, STEEL, WHITE], ink=1.0)
def _():
    plates = U(box(-0.42, 0, 0.12, 0.6, 0.06), box(0.42, 0, 0.12, 0.6, 0.06),
               box(-0.62, 0, 0.09, 0.44, 0.05), box(0.62, 0, 0.09, 0.44, 0.05),
               box(-0.78, 0, 0.07, 0.28, 0.04), box(0.78, 0, 0.07, 0.28, 0.04))
    shade = _lowright(plates, 0.25)
    bar = U(box(0, 0, 0.3, 0.07, 0.03), box(-0.28, 0, 0.04, 0.12, 0.02), box(0.28, 0, 0.04, 0.12, 0.02))
    shine = _in(plates, seg(-0.46, 0.5, -0.46, 0.2, 0.035), seg(-0.64, 0.34, -0.64, 0.14, 0.03), seg(0.38, 0.5, 0.38, 0.2, 0.035))
    return [plates, shade, bar, shine]


@sticker("gym", "shaker", "Protein shaker", ["#3A3F47", "#1B1D22", RED, WHITE], ink=1.0)
def _():
    bottle = box(0, -0.12, 0.4, 0.52, 0.1)
    body = U(bottle, box(0, 0.46, 0.34, 0.08, 0.03))
    shade = _lowright(body, 0.25)
    cap = U(box(0, 0.62, 0.24, 0.1, 0.05), box(0.2, 0.74, 0.1, 0.06, 0.03))
    label = inter(box(0, -0.06, 0.4, 0.2), bottle)
    lid = U(cap, label)
    shine = _in(body, seg(-0.24, 0.3, -0.24, -0.5, 0.045), seg(-0.24, 0.5, -0.1, 0.5, 0.03))
    return [body, shade, lid, shine]


@sticker("gym", "rope", "Speed rope", ["#2B2E33", "#14161A", YEL, WHITE], ink=1.0)
def _():
    pts = [(0.6 * math.cos(math.radians(a)), 0.12 + 0.6 * math.sin(math.radians(a))) for a in range(-100, 281, 40)]
    rope = brush([(-0.2, -0.34)] + pts[1:-1] + [(0.2, -0.34)], [0.14] * (len(pts)))
    shade = _lowright(rope, 0.2)
    handles = U(box(-0.24, -0.58, 0.16, 0.36, 0.08, ang=0.1), box(0.24, -0.58, 0.16, 0.36, 0.08, ang=-0.1))
    shine = U(_in(handles, seg(-0.3, -0.36, -0.28, -0.78, 0.04), seg(0.18, -0.36, 0.2, -0.78, 0.04)),
              _in(rope, arc(0, 0.12, 0.6, math.radians(120), math.radians(160), 0.035)))
    return [rope, shade, handles, shine]


@sticker("gym", "glove", "Boxing glove", [RED, REDS, WHITE, WHITE], ink=1.0)
def _():
    with rotated(0.2):
        mitt = smin(smin(circle(0.0, 0.2, 0.52), box(0.0, -0.18, 0.44, 0.38, 0.2), 0.16), oval(-0.5, -0.02, 0.18, 0.3, 0.3), 0.1)
        cuff = U(box(0, -0.6, 0.36, 0.2, 0.05))
        body = U(mitt, cuff)
        trim = U(cuff, inter(box(0, -0.37, 0.4, 0.045), mitt))
        shine = _in(mitt, arc(0.0, 0.2, 0.4, math.radians(110), math.radians(165), 0.045), seg(-0.34, -0.02, -0.34, -0.2, 0.04))
    shade = _lowright(body, 0.3)
    return [body, shade, trim, shine]


@sticker("gym", "mat", "Yoga mat", [TEAL, TEALS, PINK, WHITE], ink=1.0)
def _():
    body = U(box(0.2, 0, 0.58, 0.46, 0.06), circle(-0.42, 0, 0.46))
    spiral = U(shell(circle(-0.42, 0, 0.3), 0.035), shell(circle(-0.42, 0, 0.14), 0.035), seg(-0.42, 0.3, -0.42, 0.46, 0.035))
    shade = U(inter(_lowright(body, 0.3), -circle(-0.42, 0, 0.44)), spiral)
    straps = inter(U(box(0.3, 0, 0.07, 0.5), box(0.62, 0, 0.07, 0.5)), body)
    shine = _in(body, seg(-0.2, 0.34, 0.8, 0.34, 0.04))
    return [body, shade, straps, shine]


@sticker("gym", "jug", "Water jug", ["#BFE6F5", "#8CC3DE", BLUE, WHITE], ink=1.0)
def _():
    with rotated(0.0, 0.0, 0.0, 0.1, 0.0):
        tank = box(0, -0.24, 0.5, 0.5, 0.2)
        handle = sub(box(0.56, -0.1, 0.2, 0.3, 0.12), box(0.58, -0.1, 0.09, 0.17, 0.06))
        body = U(tank, box(0, 0.4, 0.22, 0.2, 0.08), handle)
        shade = _lowright(body, 0.3)
        water = U(inter(tank + 0.06, Y - 0.0), box(0, 0.66, 0.26, 0.1, 0.04))
        shine = _in(body, seg(-0.32, 0.12, -0.32, -0.3, 0.045), seg(-0.12, 0.44, -0.12, 0.36, 0.03))
    return [body, shade, water, shine]


@sticker("gym", "towel", "Gym towel", [BLUE, BLUES, WHITE, WHITE], ink=1.0)
def _():
    front = box(-0.1, -0.12, 0.42, 0.62, 0.06)
    back = box(0.34, -0.22, 0.2, 0.5, 0.05)
    body = U(front, back)
    shade = U(sub(back, front - 0.0), _lowright(front, 0.22))
    trim = U(inter(U(box(-0.1, -0.42, 0.44, 0.07), box(-0.1, -0.24, 0.44, 0.07)), front),
             box(0, 0.56, 0.62, 0.07, 0.035), circle(-0.62, 0.56, 0.1), circle(0.62, 0.56, 0.1))
    shine = _in(front, seg(-0.4, 0.4, -0.4, 0.0, 0.04))
    return [body, shade, trim, shine]


@sticker("gym", "monitor", "Heart monitor", [PINK, "#C2305C", "#17171C", WHITE], ink=1.0)
def _():
    case = box(0, 0, 0.5, 0.46, 0.14)
    body = U(box(0, 0, 0.3, 0.86, 0.1), case)
    shade = _lowright(body, 0.3)
    pulse = polyline([(-0.36, -0.02), (-0.18, -0.02), (-0.08, 0.2), (0.04, -0.2), (0.14, 0.1), (0.2, -0.02), (0.36, -0.02)], 0.05)
    screen = sub(box(0, 0, 0.4, 0.32, 0.08), pulse)
    shine = _in(body, seg(-0.42, 0.38, -0.2, 0.38, 0.035), seg(-0.2, 0.84, -0.2, 0.62, 0.03))
    return [body, shade, screen, shine]


@sticker("gym", "pr", "PR badge", ["#FFB020", "#C27A0A", "#2B2E33", WHITE], ink=1.0)
def _():
    body = smin(poly([(-0.76, 0.76), (0.76, 0.76), (0.76, 0.0), (0.0, -0.9), (-0.76, 0.0)]), circle(0, 0.2, 0.3), 0.1) - 0.06
    ring = shell(body + 0.14, 0.03)
    trim = U(ring, text("PR", 0, 0.1, 0.8, stretch=0.8, maxw=0.95))
    shade = _lowright(body, 0.35)
    shine = _in(body, seg(-0.62, 0.62, -0.3, 0.62, 0.045), seg(-0.64, 0.5, -0.64, 0.3, 0.04))
    return [body, shade, trim, shine]


def _drop(cx, cy, r):
    return smin(circle(cx, cy, r), poly([(cx, cy + 2.1 * r), (cx - 0.9 * r, cy + 0.2 * r), (cx + 0.9 * r, cy + 0.2 * r)]) - 0.02, 0.18 * r + 0.04)


@sticker("gym", "sweat", "Sweat drop", [BLUE, BLUES, "#9FE8FF", WHITE], ink=1.0)
def _():
    big = _drop(-0.14, -0.22, 0.46)
    droplets = U(_drop(0.58, 0.22, 0.17), _drop(0.5, -0.5, 0.13))
    body = big
    shade = _lowright(big, 0.2)
    shine = _in(big, arc(-0.14, -0.22, 0.32, math.radians(120), math.radians(170), 0.05), circle(-0.3, 0.12, 0.05))
    return [body, shade, droplets, shine]


@sticker("gym", "treadmill", "Treadmill", [ORANGE, ORANGES, "#2B2E33", WHITE], ink=1.0)
def _():
    deck = poly([(-0.86, -0.6), (0.6, -0.06), (0.6, -0.74), (-0.86, -0.74)]) - 0.06
    column = taper(0.46, -0.3, 0.34, 0.3, 0.15, 0.13)
    console = box(0.24, 0.5, 0.5, 0.26, 0.1)
    rail = seg(0.3, 0.1, -0.3, 0.1, 0.1)
    body = U(deck, column, console, rail)
    shade = _lowright(body, 0.4)
    belt = U(poly([(-0.8, -0.6), (0.5, -0.12), (0.5, -0.32), (-0.8, -0.68)]) - 0.03, box(0.24, 0.5, 0.38, 0.15, 0.05))
    shine = _in(body, seg(-0.2, -0.64, -0.7, -0.64, 0.04), seg(-0.14, 0.64, 0.1, 0.68, 0.035))
    return [body, shade, belt, shine]


@sticker("gym", "beast", "BEAST", ["#FF5A1F", "#B8300A", "#1B1D22", WHITE], ink=1.0)
def _():
    body = star(0, 0, 7, 0.94, 0.62, ang=0.2) - 0.04
    word = text("BEAST", 0, 0.0, 1.0, stretch=0.6, maxw=1.3)
    shade = _lowright(body, 0.3)
    shine = _in(body, seg(-0.62, 0.42, -0.34, 0.66, 0.045), seg(-0.74, 0.2, -0.7, 0.3, 0.04))
    return [body, shade, word, shine]


