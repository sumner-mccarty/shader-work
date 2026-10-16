PACK = ("punk", "Metal & Punk", False)
PRO_IDS = {"boltskull", "guitars", "batwing", "flamedie", "amp"}


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


def _zig(dx):
    return [(dx + 0.0, 1.1), (dx + 0.14, 0.55), (dx - 0.12, 0.15), (dx + 0.12, -0.2), (dx - 0.1, -0.55), (dx + 0.02, -1.1)]


def _wing(s):
    pts = [(0.1, 0.15), (0.5, 0.6), (0.92, 0.66), (0.72, 0.2), (0.9, -0.08), (0.64, -0.2), (0.64, -0.6), (0.38, -0.36), (0.1, -0.3)]
    return poly([(s * x, y) for x, y in pts])


def _horn(s):
    return brush([(s * 0.42, -0.35), (s * 0.7, -0.2), (s * 0.7, 0.28), (s * 0.5, 0.74)], [0.18, 0.15, 0.1, 0.02])


def _tri(cx, cy, ang, base, length):
    """A spike: base centre (cx, cy), pointing along ang."""
    dx, dy = math.cos(ang), math.sin(ang)
    px, py = -dy, dx
    return poly([(cx + px * base, cy + py * base), (cx + dx * length, cy + dy * length), (cx - px * base, cy - py * base)])


@sticker("punk", "pin", "Safety pin", ["#C9CED6", "#8A8F98", "#FF2D6F"], ink=1.0)
def _():
    with rotated(0.6):
        wire = U(seg(-0.55, 0.26, 0.45, 0.26, 0.09), seg(-0.55, -0.26, 0.45, -0.26, 0.09), ring(-0.62, 0.0, 0.26, 0.09),
                 box(0.56, 0.0, 0.26, 0.42, 0.1))
        shade = _lowright(wire, 0.1)
        hood = sub(box(0.56, 0.0, 0.26, 0.42, 0.1), box(0.62, 0.0, 0.1, 0.2, 0.05))
    return [wire, shade, hood]


@sticker("punk", "jacket", "Studded jacket", ["#3A3D44", "#1E1B24", "#6A6678", "#C9CED6"], ink=1.0)
def _():
    half = [(0.2, 0.72), (0.56, 0.62), (0.92, -0.1), (0.78, -0.82), (0.55, -0.78), (0.52, -0.3), (0.46, -0.84), (0.0, -0.84)]
    jacket = poly(half + [(-x, y) for x, y in reversed(half)])
    shade = _lowright(jacket, 0.3)
    lapels = U(poly([(0.2, 0.72), (0.58, 0.64), (0.34, 0.2), (0.0, 0.4)]), poly([(-0.2, 0.72), (-0.58, 0.64), (-0.34, 0.2), (0.0, 0.4)]))
    zip_ = U(seg(0.0, 0.4, 0.14, -0.8, 0.04), *[circle(x, y, 0.06) for x, y in ((0.4, 0.5), (-0.4, 0.5), (0.3, 0.32), (-0.3, 0.32))])
    return [jacket, shade, lapels, zip_]


@sticker("punk", "studheart", "Studded heart", ["#23212B", "#0B0A14", "#C9CED6", "#FFFFFF"], ink=1.0)
def _():
    body = poly(_heart_pts(0.92, 0.04))
    shade = _lowright(body, 0.25)
    studs = U(*[circle(x, y, 0.06) for x, y in _heart_pts(0.66, 0.0, 14)])
    shine = U(circle(-0.4, 0.46, 0.08), circle(-0.24, 0.55, 0.05))
    return [body, shade, studs, shine]


@sticker("punk", "boltskull", "Bolt skull", ["#F4F1EA", "#C9C3B6", "#15131A", "#FFE14A"], ink=1.0)
def _():
    bone = U(circle(0, 0.2, 0.68), box(0, -0.45, 0.36, 0.3, 0.1))
    shade = sub(bone, circle(-0.18, 0.4, 0.66))
    holes = U(poly([(-0.52, 0.2), (-0.1, 0.22), (-0.14, -0.1), (-0.5, -0.04)]),
              ellipse(0.28, 0.1, 0.19, 0.21, -0.2), poly([(0.03, -0.12), (-0.06, -0.3), (0.12, -0.3)]),
              *[box(x, -0.56, 0.035, 0.13) for x in (-0.2, 0.0, 0.2)])
    bolt = poly([(0.18, 0.95), (-0.34, 0.2), (-0.06, 0.2), (-0.26, -0.3), (0.34, 0.36), (0.08, 0.36), (0.32, 0.95)])
    return [bone, shade, holes, bolt]


@sticker("punk", "guitars", "Crossed guitars", ["#7A4A2A", "#E3172F", "#F4F1EA", "#15131A"], ink=1.0)
def _():
    necks, red, cream, trim = [], [], [], []
    for sgn in (1, -1):
        with rotated(sgn * 0.74, 0.0, 0.0, 0.0, -0.05):
            necks.append(U(box(0, 0.42, 0.1, 0.52), box(0, 0.94, 0.16, 0.12, 0.05)))
            body = smin(circle(0, -0.5, 0.4), circle(0.04, -0.08, 0.27), 0.07)
            (red if sgn > 0 else cream).append(body)
            trim.append(U(box(0, -0.3, 0.2, 0.06), circle(0, -0.58, 0.1)))
    necks = U(*necks)
    body_red = U(*red)
    body_cream = U(*cream)
    pickups = U(*trim)
    return [necks, body_red, body_cream, pickups]


@sticker("punk", "mohawk", "Mohawk", ["#F2B58C", "#C98B64", "#FF2D6F", "#15131A"], ink=1.0)
def _():
    raw = [(-0.4, -0.85), (-0.5, -0.2), (-0.5, 0.25), (-0.3, 0.6), (0.05, 0.68), (0.4, 0.5), (0.5, 0.2), (0.74, -0.05),
           (0.52, -0.12), (0.55, -0.3), (0.45, -0.5), (0.2, -0.6), (0.14, -0.85)]
    head = poly(spline([(x * 0.9, y * 0.9 - 0.12) for x, y in raw], n=6))
    shade = _lowright(head, 0.3)
    hair = U(*[_tri(-0.05 + 0.5 * math.cos(a), 0.0 + 0.5 * math.sin(a), a, 0.12, 0.42)
               for a in [math.radians(v) for v in (165, 140, 115, 90, 65)]])
    eye = U(circle(0.3, 0.1, 0.06), circle(-0.05, -0.2, 0.07))
    return [head, shade, hair, eye]


@sticker("punk", "brokenheart", "Broken heart", ["#E3172F", "#9D1220", "#F4F1EA", "#FF8A9C"], ink=1.0)
def _():
    left = inter(heart(-0.09, 0.02, 0.9), poly(_zig(-0.09) + [(-1.3, -1.1), (-1.3, 1.1)]))
    right = inter(heart(0.09, -0.02, 0.9), poly(_zig(0.09) + [(1.3, -1.1), (1.3, 1.1)]))
    body = U(left, right)
    shade = _lowright(body, 0.25)
    stitches = U(seg(-0.2, 0.42, 0.22, 0.34, 0.055), seg(-0.2, -0.02, 0.22, -0.1, 0.055), seg(-0.2, -0.46, 0.2, -0.4, 0.055))
    shine = circle(-0.5, 0.45, 0.07)
    return [body, shade, stitches, shine]


@sticker("punk", "fist", "Raised fist", ["#F2B58C", "#C98B64", "#15131A", "#1E1B24"], ink=1.0)
def _():
    fingers = U(*[box(x, 0.38, 0.115, 0.3, 0.07) for x in (-0.36, -0.12, 0.12, 0.36)])
    palm = box(0.0, -0.02, 0.5, 0.36, 0.1)
    thumb = box(-0.1, 0.06, 0.34, 0.12, 0.06, 0.2)
    wrist = box(0.0, -0.5, 0.36, 0.2, 0.04)
    fist = U(fingers, palm, wrist - 0.0)
    shade = _lowright(fist, 0.3)
    creases = U(*[seg(x, 0.3, x, 0.62, 0.025) for x in (-0.24, 0.0, 0.24)], shell(thumb, 0.022))
    cuff = box(0.0, -0.6, 0.38, 0.2, 0.05)
    return [fist, shade, creases, cuff]


@sticker("punk", "chainlink", "Chain link", ["#C9CED6", "#8A8F98", "#FFFFFF", "#FFFFFF"], ink=1.0)
def _():
    with rotated(0.6):
        left_link = shell(box(-0.3, 0.0, 0.5, 0.27, 0.27), 0.1)
        right_link = shell(box(0.3, 0.0, 0.5, 0.27, 0.27), 0.1)
        overlap = inter(left_link, circle(-0.3, 0.27, 0.2))
    return [left_link, right_link, overlap, None]


@sticker("punk", "nosign", "NO sign", ["#FFFFFF", "#E3172F", "#15131A"], ink=1.0)
def _():
    disc = circle(0, 0, 0.9)
    sign = U(shell(circle(0, 0, 0.74), 0.1), seg(-0.52, 0.52, 0.52, -0.52, 0.1))
    word = text("NO", 0.0, 0.0, 0.46, maxw=1.0)
    return [disc, sign, word]


@sticker("punk", "flamedie", "Flaming die", ["#FF7A1A", "#F4F1EA", "#15131A", "#C9C3B6"], ink=1.0)
def _():
    flames = U(poly(spline([(-0.78, -0.3), (-0.84, 0.35), (-0.55, 0.1), (-0.5, 0.78), (-0.2, 0.3), (-0.1, 0.92), (0.1, 0.35),
                            (0.3, 0.84), (0.42, 0.26), (0.7, 0.62), (0.7, 0.0), (0.82, -0.3), (0.0, -0.8)], n=5)))
    with rotated(0.15):
        die = box(0, -0.12, 0.6, 0.6, 0.15)
        pips = U(*[circle(cx * 1.15, cy * 1.15 - 0.12, 0.095) for cx, cy in [(-0.28, 0.28), (0.28, 0.28), (0, 0), (-0.28, -0.28), (0.28, -0.28)]])
    shade = _lowright(die, 0.2)
    return [flames, die, pips, shade]


@sticker("punk", "batwing", "Bat wings", ["#7A3FCF", "#4F2394", "#2B2E33", "#1E1B24"], ink=1.0)
def _():
    wings = U(_wing(1), _wing(-1))
    shade = _lowright(wings, 0.3)
    body = U(ellipse(0, -0.05, 0.17, 0.32), circle(0, 0.32, 0.2), _tri(-0.12, 0.44, 1.95, 0.09, 0.32), _tri(0.12, 0.44, 1.19, 0.09, 0.32))
    bones = U(*[seg(s * 0.5, 0.6, s * tx, ty, 0.06) for s in (1, -1) for tx, ty in [(0.9, 0.64), (0.88, -0.06), (0.62, -0.58)]],
              *[seg(s * 0.1, 0.15, s * 0.5, 0.6, 0.07) for s in (1, -1)])
    return [wings, shade, body, bones]


@sticker("punk", "horns", "Devil", ["#15131A", "#E3172F", "#9D1220", "#FFFFFF"], ink=1.0)
def _():
    horns = U(_tri(-0.34, 0.4, 2.0, 0.17, 0.6), _tri(0.34, 0.4, 1.14, 0.17, 0.6))
    face = circle(0, -0.1, 0.62)
    shade = sub(face, circle(-0.2, 0.08, 0.62))
    features = U(poly([(-0.5, 0.26), (-0.1, 0.0), (-0.12, 0.18), (-0.44, 0.34)]),
                 poly([(0.5, 0.26), (0.1, 0.0), (0.12, 0.18), (0.44, 0.34)]),
                 sub(box(0, -0.38, 0.34, 0.14, 0.07), box(0, -0.32, 0.3, 0.05)))
    return [horns, face, shade, features]


@sticker("punk", "loudtag", "Torn tag", ["#F4F1EA", "#C9C3B6", "#15131A", "#E3172F"], ink=1.0)
def _():
    with rotated(0.15):
        tag = poly([(-0.88, 0.34), (-0.66, 0.5), (0.62, 0.5), (0.7, 0.34), (0.6, 0.22), (0.74, 0.1), (0.6, -0.02), (0.76, -0.14),
                    (0.62, -0.26), (0.72, -0.38), (-0.66, -0.5), (-0.88, -0.34)])
        tear = inter(tag, 0.46 - X)
        hole = circle(-0.68, 0.0, 0.07)
        string = ring(-0.68, 0.0, 0.17, 0.045)
    word = text("LOUD", 0.04, 0.03, 0.4, ang=0.15, maxw=0.95)
    strap = U(hole, string)
    return [tag, tear, word, strap]


@sticker("punk", "wristband", "Spiked band", ["#7A2B2B", "#4A1818", "#C9CED6", "#F4F1EA"], ink=1.0)
def _():
    with rotated(0.25):
        band = box(0, -0.1, 0.8, 0.36, 0.12)
        shade = _lowright(box(0, -0.1, 0.8, 0.36, 0.12), 0.15)
        spikes = U(*[_tri(x, 0.12, math.pi / 2, 0.17, 0.55) for x in (-0.46, 0.0, 0.46)])
        stitch = U(box(0.0, -0.32, 0.72, 0.04), box(0.0, 0.0, 0.1, 0.1, 0.03))
    return [band, shade, spikes, stitch]


@sticker("punk", "amp", "Amp stack", ["#3A3D47", "#15131A", "#C9CED6", "#E3172F"], ink=1.0)
def _():
    cab = U(box(0, 0.62, 0.8, 0.22, 0.05), box(0, -0.28, 0.8, 0.58, 0.05))
    grill = U(*[ring(x, y, 0.2, 0.065) for x in (-0.36, 0.36) for y in (-0.02, -0.56)], *[circle(x, y, 0.07) for x in (-0.36, 0.36) for y in (-0.02, -0.56)])
    knobs = U(*[circle(x, 0.62, 0.085) for x in (-0.58, -0.36, -0.14, 0.08)])
    lamp = circle(0.52, 0.62, 0.1)
    return [cab, grill, knobs, lamp]