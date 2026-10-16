PACK = ("harvest", "Harvest", False)
PRO_IDS = {"turkey", "thanks", "pie", "handturkey", "wreath"}


def _shade(d, dx=-0.1, dy=0.1):
    """Lower-right shade: the shape minus a copy of itself nudged up-left (screen space, even inside a rotated block)."""
    s = 96.0
    moved = np.roll(d, (int(round(-dy * s)), int(round(dx * s))), axis=(0, 1))
    return sub(d, moved)


def _zoom(k, make):
    """Run `make()` with the art drawn at scale k about the slice centre (k < 1 pulls it in from the edge)."""
    g = circle.__globals__
    saved = (g["X"], g["Y"])
    g["X"], g["Y"] = saved[0] / k, saved[1] / k
    try:
        return [None if d is None else d * k for d in make()]
    finally:
        g["X"], g["Y"] = saved


def _turn(ang, make, cx=0.0, cy=0.0):
    """Draw upright inside `make()`, get the list of layers turned by ang."""
    with rotated(ang, cx, cy):
        return make()


def _blade(cx, cy, ang, ln, wd):
    """A pointed leaf blade: base at (cx, cy), tip `ln` away along `ang`."""
    pts = [(ln * t, wd * math.sin(math.pi * t) ** 0.8) for t in np.linspace(0, 1, 9)]
    pts = pts + [(x, -y) for x, y in pts[::-1][1:-1]]
    c, s = math.cos(ang), math.sin(ang)
    return poly([(cx + c * x - s * y, cy + s * x + c * y) for x, y in pts])


# ---- roast turkey ----
@sticker("harvest", "turkey", "Roast turkey", ["#F4F1EA", "#B8661E", "#7A3A0E", "#FFFFFF"], ink=1.0)
def _():
    platter = oval(0.0, -0.5, 0.9, 0.3)
    legs = U(taper(-0.4, -0.22, -0.64, 0.1, 0.22, 0.14), taper(0.4, -0.22, 0.64, 0.1, 0.22, 0.14))
    bird = U(oval(0.0, -0.08, 0.52, 0.42), legs)
    shade = _shade(bird, -0.1, 0.1)
    bones = U(seg(-0.64, 0.1, -0.74, 0.34, 0.065), circle(-0.76, 0.38, 0.11), seg(0.64, 0.1, 0.74, 0.34, 0.065), circle(0.76, 0.38, 0.11))
    return [platter, bird, shade, bones]


# ---- pie ----
@sticker("harvest", "pie", "Pie", ["#E8B04A", "#B8801E", "#C2282B", "#F2CE7A"], ink=1.0)
def _():
    crust = U(circle(0, 0, 0.74), *[circle(0.8 * math.cos(a), 0.8 * math.sin(a), 0.11) for a in np.linspace(0, 2 * math.pi, 17)[:-1]])
    shade = _shade(crust, -0.1, 0.1)
    filling = circle(0, 0, 0.56)
    lattice = inter(U(stripes(0.3, 0.8, 0.34), stripes(0.3, -0.8, 0.34)), circle(0, 0, 0.6))
    return [crust, shade, filling, lattice]


# ---- cornucopia ----
@sticker("harvest", "cornucopia", "Cornucopia", ["#E8C080", "#B88A40", "#E3472F", "#7A3FA8"], ink=1.0)
def _():
    horn = brush([(-0.86, 0.7), (-0.7, 0.1), (-0.3, -0.3), (0.2, -0.42)], [0.07, 0.22, 0.36, 0.46])
    shade = _shade(horn, -0.1, 0.1)
    fruit = U(circle(0.64, -0.24, 0.3), circle(0.28, -0.04, 0.24), circle(0.66, -0.66, 0.18), circle(0.9 - 0.34, 0.1, 0.0) + 9.0)
    grapes = U(*[circle(x, y, 0.12) for x, y in [(-0.04, 0.0), (0.06, 0.22), (0.16, 0.0), (-0.16, 0.22), (0.04, -0.2)]])
    return [horn, shade, fruit, grapes]


# ---- corn ----
def _corn():
    cob = oval(0.0, 0.14, 0.34, 0.74)
    kernels = U(*[circle(-0.2 + 0.2 * i, 0.74 - 0.19 * j, 0.065) for j in range(7) for i in range(3)] + [circle(-0.1 + 0.2 * i, 0.645 - 0.19 * j, 0.065) for j in range(6) for i in range(2)])
    kernels = inter(kernels, cob + 0.1)
    husk = U(_blade(0.0, -0.5, 2.0, 0.62, 0.2), _blade(0.0, -0.5, 1.14, 0.62, 0.2), _blade(0.0, -0.5, 1.57, 0.6, 0.15))
    return cob, kernels, husk


@sticker("harvest", "corn", "Corn cob", ["#FFD23A", "#B8841A", "#E0A010", "#3FA03F"], ink=1.0)
def _():
    cob, kernels, husk = _turn(-0.45, _corn)
    shade = _shade(cob, -0.1, 0.1)
    return [cob, shade, kernels, husk]


# ---- gourds ----
@sticker("harvest", "gourds", "Gourds", ["#3FA03F", "#FFD23A", "#E8761F", "#5A3A18"], ink=1.0)
def _():
    rear = U(oval(-0.5, 0.18, 0.32, 0.4), taper(-0.5, 0.5, -0.5, 0.72, 0.08, 0.06))
    side = U(circle(0.5, -0.22, 0.34), taper(0.46, -0.02, 0.36, 0.46, 0.17, 0.11), circle(0.36, 0.52, 0.16))
    front = U(oval(-0.12, -0.34, 0.6, 0.46), taper(-0.12, -0.02, -0.1, 0.16, 0.1, 0.07))
    trim = U(arc(-0.12, -0.34, 0.34, 1.2, 2.0, 0.05), arc(-0.12, -0.34, 0.34, 3.2, 4.2, 0.0) + 9.0, arc(-0.12, -0.34, 0.2, 1.0, 2.3, 0.0) + 9.0,
             seg(-0.12, -0.04, -0.1, 0.16, 0.05), seg(-0.5, 0.58, -0.5, 0.72, 0.05), arc(-0.5, 0.18, 0.2, 1.0, 2.2, 0.045), arc(0.5, -0.22, 0.2, 1.0, 2.2, 0.045))
    return [rear, side, front, trim]


# ---- pumpkin pie slice ----
@sticker("harvest", "slice", "Pie slice", ["#E8892A", "#B8601A", "#E8B04A", "#FFFFFF"], ink=1.0)
def _():
    filling = poly([(-0.86, -0.06), (0.5, 0.34), (0.5, -0.46)])
    shade = inter(filling, -0.04 - Y - X * 0.1)
    crust = U(box(0.52, -0.05, 0.2, 0.46, 0.14), seg(-0.86, -0.06, 0.5, -0.44, 0.07))
    cream = U(circle(0.14, 0.48, 0.2), circle(0.38, 0.5, 0.18), circle(0.26, 0.68, 0.16))
    return [filling, shade, crust, cream]


# ---- buckle hat ----
@sticker("harvest", "buckle", "Buckle hat", ["#3A3F47", "#1E2126", "#8A5A2B", "#FFC531"], ink=1.0)
def _():
    hat = U(poly([(-0.42, -0.22), (0.42, -0.22), (0.26, 0.7), (-0.26, 0.7)]) - 0.06, oval(0.0, -0.3, 0.92, 0.22))
    shade = _shade(hat, -0.1, 0.1)
    band = box(0, -0.12, 0.43, 0.13, 0.02)
    buckle = shell(box(0, -0.12, 0.15, 0.15, 0.03), 0.045)
    return [hat, shade, band, buckle]


# ---- wheat bundle ----
def _wheat():
    stalks, heads = [], []
    for a in (-0.38, 0.0, 0.38):
        with rotated(a, 0.0, -0.84):
            stalks.append(seg(0.0, -0.84, 0.0, 0.2, 0.075))
            g = [oval(sx * 0.11, 0.3 + 0.2 * k, 0.09, 0.14, sx * 0.4) for k in range(3) for sx in (-1, 1)]
            g.append(oval(0.0, 0.88, 0.08, 0.14))
            heads.append(U(*g))
    return U(*stalks), U(*heads)


@sticker("harvest", "wheat", "Wheat", ["#D9B060", "#F0C040", "#B8661E", "#C2282B"], ink=1.0)
def _():
    stalks, heads = _zoom(0.88, _wheat)
    tie = U(box(0.0, -0.5, 0.26, 0.08, 0.02), poly([(0.0, -0.5), (0.26, -0.36), (0.2, -0.64)]), poly([(0.0, -0.5), (-0.26, -0.36), (-0.2, -0.64)]))
    shade = _shade(stalks, -0.1, 0.1)
    return [stalks, heads, shade, tie]


# ---- wishbone ----
@sticker("harvest", "wishbone", "Wishbone", ["#F4E3C8", "#C9A878", "#FFFFFF", "#FFC531"], ink=1.0)
def _():
    left = brush([(-0.58, 0.58), (-0.52, 0.12), (-0.2, -0.3), (0.0, -0.66)], [0.15, 0.13, 0.13, 0.15])
    right = brush([(0.58, 0.58), (0.52, 0.12), (0.2, -0.3), (0.0, -0.66)], [0.15, 0.13, 0.13, 0.15])
    bone = U(left, right, circle(-0.6, 0.68, 0.19), circle(0.6, 0.68, 0.19), circle(0.0, -0.7, 0.2))
    shade = _shade(bone, -0.08, 0.08)
    shine = U(seg(-0.68, 0.74, -0.6, 0.82, 0.05), seg(-0.58, 0.4, -0.52, 0.0, 0.04))
    wish = star(0.0, 0.3, 5, 0.26, 0.12)
    return [bone, shade, shine, wish]


# ---- THANKS banner ----
@sticker("harvest", "thanks", "Thanks banner", ["#9A3A18", "#E8761F", "#FFF0D0", "#FFC531"], ink=1.0)
def _():
    tails = U(poly([(-0.92, -0.18), (-0.5, -0.18), (-0.5, -0.5), (-0.74, -0.38), (-0.92, -0.5)]), poly([(0.92, -0.18), (0.5, -0.18), (0.5, -0.5), (0.74, -0.38), (0.92, -0.5)]))
    ribbon = box(0, 0.06, 0.78, 0.4, 0.05)
    word = text("THANKS", 0.0, 0.06, 0.34, maxw=1.36) - 0.012
    stitch = U(*[box(x, 0.4, 0.07, 0.022, 0.01) for x in np.linspace(-0.6, 0.6, 7)], *[box(x, -0.28, 0.07, 0.022, 0.01) for x in np.linspace(-0.6, 0.6, 7)])
    return [tails, ribbon, word, stitch]


# ---- cranberry bowl ----
@sticker("harvest", "cranberries", "Cranberry bowl", ["#FFFFFF", "#BFD4EA", "#C2182B", "#2E9E4F"], ink=1.0)
def _():
    bowl = U(inter(oval(0.0, 0.0, 0.8, 0.7), Y), box(0, 0.0, 0.86, 0.07, 0.03))
    shade = _shade(bowl, -0.1, 0.1)
    berries = U(*[circle(x, y, 0.19) for x, y in [(-0.52, 0.16), (-0.16, 0.22), (0.2, 0.22), (0.54, 0.14), (-0.34, 0.5), (0.04, 0.52), (0.38, 0.46), (-0.06, 0.78)]])
    sprig = U(_blade(0.3, 0.56, 0.5, 0.36, 0.13), _blade(0.3, 0.56, 1.5, 0.3, 0.11), seg(-0.5, -0.3, 0.5, -0.3, 0.0) + 9.0)
    return [bowl, shade, berries, sprig]


# ---- table setting ----
@sticker("harvest", "table", "Place setting", ["#E8761F", "#FFFFFF", "#C9CED6", "#B8661E"], ink=1.0)
def _():
    napkin = box(-0.78, -0.02, 0.2, 0.66, 0.04)
    plate = circle(0.0, 0.0, 0.54)
    fork = U(seg(-0.78, -0.76, -0.78, 0.2, 0.055), box(-0.78, 0.26, 0.2, 0.06, 0.02), *[box(x, 0.5, 0.05, 0.2, 0.01) for x in (-0.93, -0.78, -0.63)])
    knife = U(seg(0.76, -0.76, 0.76, -0.1, 0.06), poly([(0.66, -0.12), (0.66, 0.5), (0.74, 0.58), (0.86, 0.4), (0.86, -0.12)]))
    cutlery = U(fork, knife)
    ring_ = U(shell(circle(0, 0, 0.34), 0.04), star(0, 0, 5, 0.14, 0.06))
    return [napkin, plate, cutlery, ring_]


# ---- sweet potato ----
def _yam():
    tuber = brush([(-0.78, -0.4), (-0.4, -0.22), (0.1, 0.0), (0.56, 0.24)], [0.05, 0.34, 0.4, 0.34])
    flesh = oval(0.62, 0.28, 0.3, 0.36, 0.9)
    eyes = U(circle(-0.3, -0.12, 0.06), circle(-0.1, 0.12, 0.06), circle(0.1, -0.16, 0.06), seg(-0.9, -0.5, -0.76, -0.44, 0.045))
    return tuber, flesh, eyes


@sticker("harvest", "yam", "Sweet potato", ["#B8472E", "#8A2E1A", "#FF9F3A", "#5A1E10"], ink=1.0)
def _():
    tuber, flesh, eyes = _yam()
    shade = _shade(tuber, -0.1, 0.1)
    return [tuber, shade, flesh, eyes]


# ---- kid's hand turkey ----
def _finger(ang, ln=0.84, w=0.115):
    bx, by = 0.0, -0.3
    return taper(bx, by, bx + ln * math.cos(ang), by + ln * math.sin(ang), w, w + 0.02)


def _handturkey():
    palm = U(circle(0.0, -0.5, 0.4), taper(-0.2, -0.46, -0.62, -0.52, 0.17, 0.2), circle(-0.7, -0.52, 0.22))
    feathers = U(*[_finger(math.radians(a)) for a in (15, 75, 135)], poly([(-0.9, -0.6), (-0.8, -0.8), (-0.7, -0.62)]) - 0.03)
    plumes = U(*[_finger(math.radians(a)) for a in (45, 105)], poly([(-0.96, -0.46), (-1.0, -0.56), (-0.88, -0.52)]))
    eye = circle(-0.74, -0.46, 0.06)
    return [palm, feathers, plumes, eye]


@sticker("harvest", "handturkey", "Hand turkey", ["#9A5A2B", "#E3172F", "#FFC531", "#1A1410"], ink=1.0)
def _():
    palm, feathers, plumes, eye = _zoom(0.92, _handturkey)
    return [palm, feathers, plumes, eye]


# ---- leaf wreath ----
def _maple(cx, cy, k, ang):
    lobes = [(18, 0.95), (90, 1.0), (162, 0.95), (234, 0.72), (306, 0.72)]
    rel = [(-32, 0.4), (-22, 0.68), (-12, 0.54), (0, 0.9), (12, 0.54), (22, 0.68), (32, 0.4)]
    pts = []
    for a, sc in lobes:
        for da, r in rel:
            rr = r * (sc if r > 0.45 else 1.0) * 0.94
            t = math.radians(a + da) + ang
            pts.append((cx + k * rr * math.cos(t), cy + k * rr * math.sin(t)))
    return poly(pts)


def _wreath():
    groups = [[], [], []]
    for i in range(12):
        a_ = 2 * math.pi * i / 12 + 0.1
        ang = a_ + 0.55
        groups[i % 3].append(_blade(0.4 * math.cos(a_), 0.4 * math.sin(a_), ang, 0.56, 0.17))
    oaks, maples, aspens = (U(*g) for g in groups)
    bow = U(poly([(0.0, -0.7), (0.42, -0.52), (0.42, -0.9), (0.0, -0.7)]), poly([(0.0, -0.7), (-0.42, -0.52), (-0.42, -0.9), (0.0, -0.7)]), circle(0.0, -0.7, 0.13))
    return [oaks, maples, aspens, bow]


@sticker("harvest", "wreath", "Leaf wreath", ["#E8761F", "#C2282B", "#FFC531", "#8A5A2B"], ink=1.0)
def _():
    oaks, maples, aspens, bow = _zoom(0.94, _wreath)
    return [oaks, maples, aspens, bow]


# ---- gravy boat ----
def _gravy():
    hull = poly(spline([(-0.64, 0.3), (-0.58, -0.04), (-0.3, -0.3), (0.12, -0.34), (0.48, -0.14), (0.62, 0.08), (0.94, 0.4), (0.7, 0.4), (0.5, 0.34), (-0.1, 0.32)], n=8))
    boat = U(hull, arc(-0.7, 0.04, 0.24, math.pi / 2, 3 * math.pi / 2, 0.085), box(-0.04, -0.4, 0.3, 0.07, 0.03))
    shade = _shade(boat, -0.1, 0.1)
    gravy = U(oval(-0.06, 0.28, 0.58, 0.08), taper(0.56, 0.3, 0.9, 0.38, 0.07, 0.04), taper(0.9, 0.38, 0.92, 0.1, 0.045, 0.02))
    saucer = oval(-0.02, -0.58, 0.84, 0.13)
    return [boat, shade, gravy, saucer]


@sticker("harvest", "gravy", "Gravy boat", ["#FFFFFF", "#BFD4EA", "#8A4A1E", "#2F7BE0"], ink=1.0)
def _():
    boat, shade, gravy, saucer = _zoom(0.9, _gravy)
    return [boat, shade, gravy, saucer]
