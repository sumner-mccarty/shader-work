PACK = ("autumn", "Autumn", False)
PRO_IDS = {"maple", "fox", "squirrel", "scarecrow", "sweater"}


def _shade(d, dx=-0.1, dy=0.1):
    """Lower-right shade: the shape minus a copy of itself nudged up-left (screen space, even inside a rotated block)."""
    s = 96.0
    moved = np.roll(d, (int(round(-dy * s)), int(round(dx * s))), axis=(0, 1))
    return sub(d, moved)


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


def _zoom(k, make):
    """Run `make()` with the art drawn at scale k about the slice centre (k < 1 pulls it in from the edge)."""
    g = circle.__globals__
    saved = (g["X"], g["Y"])
    g["X"], g["Y"] = saved[0] / k, saved[1] / k
    try:
        return [None if d is None else d * k for d in make()]
    finally:
        g["X"], g["Y"] = saved


# ---- maple leaf ----
def _maple_pts(scale=1.0):
    lobes = [(18, 0.95), (90, 1.0), (162, 0.95), (234, 0.72), (306, 0.72)]
    rel = [(-32, 0.4), (-22, 0.68), (-12, 0.54), (0, 0.9), (12, 0.54), (22, 0.68), (32, 0.4)]
    pts = []
    for a, sc in lobes:
        for da, r in rel:
            rr = r * (sc if r > 0.45 else 1.0) * scale * 0.94
            t = math.radians(a + da)
            pts.append((rr * math.cos(t), 0.06 + rr * math.sin(t)))
    return pts


@sticker("autumn", "maple", "Maple leaf", ["#E8431F", "#B52A12", "#FFB07A", "#7A2E12"], ink=1.0)
def _():
    leaf = poly(_maple_pts()) - 0.03
    shade = _shade(leaf, -0.1, 0.1)
    shine = U(seg(-0.4, 0.62, -0.26, 0.76, 0.045), circle(-0.55, 0.5, 0.045))
    veins = U(seg(0, 0.08, 0, -0.82, 0.055), *[seg(0, 0.08, 0.6 * math.cos(math.radians(a)), 0.08 + 0.6 * math.sin(math.radians(a)), 0.04) for a in (18, 90, 162)])
    return [leaf, shade, shine, veins]


# ---- oak leaf ----
def _oak_pts():
    right = [(0.12, 0.9), (0.34, 0.74), (0.22, 0.56), (0.5, 0.42), (0.32, 0.24), (0.58, 0.08), (0.34, -0.1), (0.52, -0.3), (0.26, -0.42), (0.16, -0.6)]
    left = [(-x, y) for x, y in right[::-1]]
    return right + [(0.0, -0.68)] + left + [(0.0, 0.94)]


def _oak():
    leaf = poly(spline(_oak_pts(), n=6))
    shade = _shade(leaf, -0.1, 0.1)
    shine = U(seg(-0.14, 0.6, -0.1, 0.78, 0.045), seg(-0.34, 0.3, -0.26, 0.4, 0.045))
    vein = U(seg(0, 0.7, 0, -0.9, 0.05), seg(0, 0.3, 0.3, 0.4, 0.04), seg(0, 0.3, -0.3, 0.4, 0.04), seg(0, -0.05, 0.3, 0.06, 0.04), seg(0, -0.05, -0.3, 0.06, 0.04))
    return [leaf, shade, shine, vein]


@sticker("autumn", "oak", "Oak leaf", ["#D08A1E", "#9A5F0E", "#FFE08A", "#6B3A12"], ink=1.0)
def _():
    leaf, shade, shine, vein = _turn(-0.6, _oak)
    return [leaf, shade, shine, vein]


# ---- acorns ----
def _acorn(cx, cy, s, ang):
    def make():
        nut = U(oval(0, -0.12, 0.3, 0.34), poly([(-0.26, -0.28), (0.26, -0.28), (0.0, -0.66)]))
        cap = U(inter(oval(0, 0.12, 0.38, 0.32), 0.12 - Y), box(0, 0.12, 0.4, 0.06, 0.03), seg(0.0, 0.4, 0.04, 0.56, 0.05))
        return nut, cap
    with rotated(ang, 0.0, 0.0, cx, cy):
        nut, cap = make()
    return nut, cap


@sticker("autumn", "acorns", "Acorns", ["#C98B4B", "#8A5A2B", "#6B3A18", "#FFE9B8"], ink=1.0)
def _():
    n1, c1 = _acorn(-0.3, -0.02, 1.0, 0.18)
    n2, c2 = _acorn(0.42, -0.24, 1.0, -0.3)
    with rotated(0.0):
        pass
    nut = U(n1, n2)
    cap = U(c1, c2)
    shade = _shade(nut, -0.08, 0.08)
    shine = U(seg(-0.46, -0.02, -0.4, -0.2, 0.04), seg(0.26, -0.24, 0.3, -0.38, 0.04))
    return [nut, shade, cap, shine]


# ---- squirrel ----
@sticker("autumn", "squirrel", "Squirrel", ["#C8702A", "#8F4A14", "#FFE3B8", "#3A2418"], ink=1.0)
def _():
    tail = brush([(-0.28, -0.5), (-0.68, -0.2), (-0.6, 0.34), (-0.2, 0.64)], [0.15, 0.24, 0.27, 0.18])
    body = U(oval(-0.04, -0.34, 0.4, 0.4), circle(0.28, 0.1, 0.27), poly([(0.16, 0.3), (0.2, 0.56), (0.34, 0.36)]),
             poly([(0.3, 0.32), (0.46, 0.54), (0.5, 0.26)]), oval(0.1, -0.68, 0.34, 0.13))
    fur = U(tail, body)
    shade = _shade(fur, -0.1, 0.1)
    belly = U(oval(0.12, -0.3, 0.2, 0.3), oval(0.42, 0.04, 0.12, 0.1))
    details = U(circle(0.36, 0.16, 0.055), circle(0.52, 0.04, 0.06), circle(0.14, -0.2, 0.15), poly([(0.06, -0.3), (0.22, -0.3), (0.14, -0.4)]))
    return [fur, shade, belly, details]


# ---- mug ----
@sticker("autumn", "mug", "Cider mug", ["#E8761F", "#B04A0A", "#FFFFFF", "#FFE9C7"], ink=1.0)
def _():
    mug = U(box(-0.08, -0.22, 0.48, 0.42, 0.16), arc(0.42, -0.2, 0.22, -math.pi / 2, math.pi / 2, 0.08))
    shade = _shade(box(-0.08, -0.22, 0.48, 0.42, 0.16), -0.1, 0.1)
    steam = U(brush([(-0.3, 0.34), (-0.12, 0.5), (-0.3, 0.68), (-0.12, 0.88)], [0.07, 0.07, 0.07, 0.06]),
              brush([(0.14, 0.34), (0.32, 0.5), (0.14, 0.68), (0.32, 0.88)], [0.07, 0.07, 0.07, 0.06]))
    leaf = poly([(-0.08 + x * 0.36, -0.2 + y * 0.36) for x, y in _maple_pts()]) - 0.01
    trim = U(leaf, seg(-0.08, -0.34, -0.08, -0.5, 0.04))
    return [mug, shade, steam, trim]


# ---- scarf ----
def _scarf():
    drape = brush([(-0.86, 0.5), (-0.36, 0.28), (0.3, 0.56), (0.86, 0.4)], [0.22, 0.24, 0.24, 0.22])
    tail1 = _turn(0.08, lambda: box(-0.34, -0.18, 0.25, 0.54, 0.04), -0.34, 0.3)
    tail2 = _turn(-0.1, lambda: box(0.3, -0.26, 0.25, 0.46, 0.04), 0.3, 0.4)
    wrap = U(drape, tail1, tail2)
    shade = _shade(wrap, -0.08, 0.08)
    bands = inter(stripes(0.44, 0.0, 0.4, 0.05), wrap + 0.02)
    fringe = U(*[box(x, -0.82, 0.045, 0.09, 0.02) for x in (-0.56, -0.42, -0.28, -0.14, -0.0)], *[box(x, -0.8, 0.045, 0.09, 0.02) for x in (0.1, 0.24, 0.38, 0.52)])
    return [wrap, shade, bands, fringe]


@sticker("autumn", "scarf", "Scarf", ["#C2282B", "#8F1A1D", "#FFE3B8", "#FFC531"], ink=1.0)
def _():
    wrap, shade, bands, fringe = _zoom(0.84, _scarf)
    return [wrap, shade, bands, fringe]


# ---- rake and leaf pile ----
def _rake():
    handle = seg(-0.8, 0.96, -0.05, 0.3, 0.11)
    head = U(*[seg(-0.05, 0.3, tx, ty, 0.085) for tx, ty in [(-0.66, -0.2), (-0.36, -0.38), (-0.05, -0.42), (0.26, -0.38), (0.56, -0.2)]], arc(-0.05, 0.3, 0.66, math.radians(215), math.radians(325), 0.09))
    rake = U(handle, head)
    pile = U(oval(0.0, -0.66, 0.92, 0.26), circle(-0.46, -0.52, 0.26), circle(0.1, -0.44, 0.3), circle(0.56, -0.58, 0.22))
    shade = _shade(pile, -0.1, 0.1)
    leaves = U(_blade(-0.5, -0.6, 0.7, 0.34, 0.12), _blade(0.1, -0.36, 2.1, 0.34, 0.12), _blade(0.44, -0.6, 0.3, 0.3, 0.11), _blade(-0.1, -0.78, 2.6, 0.28, 0.1))
    return [rake, pile, shade, leaves]


@sticker("autumn", "rake", "Rake and leaves", ["#8A5A2B", "#F08A1F", "#C0381A", "#FFD23A"], ink=1.0)
def _():
    rake, pile, shade, leaves = _zoom(0.92, _rake)
    return [rake, pile, shade, leaves]


# ---- mushroom cluster ----
def _shroom(cx, cy, r):
    cap = inter(oval(cx, cy, r, r * 0.8), cy - Y)
    stem = U(taper(cx, cy, cx, cy - r * 1.1, r * 0.4, r * 0.34), box(cx, cy - 0.02, r * 0.94, 0.05, 0.02))
    return cap, stem


@sticker("autumn", "mushrooms", "Mushrooms", ["#F4E3C8", "#B8652A", "#8A4414", "#FFE9B8"], ink=1.0)
def _():
    c1, s1 = _shroom(-0.04, 0.2, 0.48)
    c2, s2 = _shroom(-0.56, -0.12, 0.3)
    c3, s3 = _shroom(0.5, -0.26, 0.34)
    stems = U(s1, s2, s3, box(0.0, -0.74, 0.7, 0.1, 0.05))
    caps = U(c1, c2, c3)
    shade = _shade(caps, -0.08, 0.08)
    spots = U(circle(-0.16, 0.4, 0.07), circle(0.16, 0.32, 0.06), circle(-0.6, 0.0, 0.05), circle(0.5, -0.14, 0.055))
    return [stems, caps, shade, spots]


# ---- sweater ----
@sticker("autumn", "sweater", "Sweater", ["#E0A030", "#B06E10", "#FFF0D0", "#8A4414"], ink=1.0)
def _():
    body = U(box(0, -0.1, 0.44, 0.58, 0.1), taper(-0.34, 0.34, -0.76, -0.12, 0.2, 0.18), taper(0.34, 0.34, 0.76, -0.12, 0.2, 0.18))
    shade = _shade(body, -0.1, 0.1)
    rib = U(box(0, -0.68, 0.44, 0.1, 0.04), circle(-0.76, -0.12, 0.19), circle(0.76, -0.12, 0.19), oval(0, 0.5, 0.24, 0.12))
    pattern = U(polyline([(-0.36, 0.0), (-0.18, 0.16), (0.0, 0.0), (0.18, 0.16), (0.36, 0.0)], 0.055),
                polyline([(-0.36, -0.28), (-0.18, -0.12), (0.0, -0.28), (0.18, -0.12), (0.36, -0.28)], 0.055))
    return [body, shade, pattern, rib]


# ---- apple basket ----
@sticker("autumn", "basket", "Apple basket", ["#B8803A", "#7A4C1A", "#E3172F", "#2E9E4F"], ink=1.0)
def _():
    tub = poly([(-0.78, -0.02), (0.78, -0.02), (0.68, -0.76), (-0.68, -0.76)]) - 0.05
    handle = arc(0, -0.02, 0.74, 0.0, math.pi, 0.075)
    basket = U(tub, handle, box(0, -0.02, 0.82, 0.07, 0.03))
    weave = inter(U(stripes(0.24, 0.0, 0.3, 0.06), stripes(0.3, 1.5708, 0.3, 0.0)), tub - 0.02)
    apples = U(circle(-0.4, 0.2, 0.27), circle(0.36, 0.22, 0.27), circle(-0.02, 0.38, 0.27))
    leaves = U(seg(-0.02, 0.62, 0.02, 0.76, 0.045), _blade(0.04, 0.72, 0.5, 0.26, 0.1), seg(-0.4, 0.44, -0.4, 0.54, 0.04), seg(0.36, 0.46, 0.38, 0.56, 0.04))
    return [basket, weave, apples, leaves]


# ---- scarecrow ----
@sticker("autumn", "scarecrow", "Scarecrow", ["#C23A2B", "#E8C26A", "#EBC98F", "#3A2418"], ink=1.0)
def _():
    shirt = U(poly([(-0.36, -0.34), (0.36, -0.34), (0.5, -0.9), (-0.5, -0.9)]), box(0, -0.66, 0.9, 0.2, 0.06))
    head = circle(0, -0.02, 0.46)
    hat = U(inter(oval(0, 0.46, 0.34, 0.3), 0.42 - Y), box(0, 0.4, 0.84, 0.08, 0.04), box(0, 0.44, 0.35, 0.05),
            poly([(-0.94, -0.58), (-0.76, -0.76), (-0.86, -0.5)]), poly([(0.94, -0.58), (0.76, -0.76), (0.86, -0.5)]),
            poly([(-0.52, 0.18), (-0.38, -0.04), (-0.58, -0.06)]), poly([(0.52, 0.18), (0.38, -0.04), (0.58, -0.06)]))
    face = U(circle(-0.17, 0.06, 0.08), circle(0.17, 0.06, 0.08), poly([(-0.07, -0.06), (0.07, -0.06), (0.0, -0.17)]),
             polyline([(-0.24, -0.24), (-0.12, -0.3), (0.0, -0.26), (0.12, -0.3), (0.24, -0.24)], 0.04))
    return [shirt, head, hat, face]


# ---- hay bale ----
def _hay():
    front = box(-0.1, -0.2, 0.64, 0.4, 0.05)
    top = poly([(-0.74, 0.2), (-0.3, 0.66), (0.86, 0.66), (0.54, 0.2)])
    side = poly([(0.54, 0.2), (0.86, 0.66), (0.86, -0.12), (0.54, -0.6)])
    tufts = U(seg(-0.74, 0.0, -0.94, 0.08, 0.05), seg(-0.74, -0.14, -0.92, -0.2, 0.05), seg(-0.46, 0.64, -0.54, 0.84, 0.05), seg(0.1, 0.66, 0.04, 0.86, 0.05),
              seg(0.8, 0.12, 0.96, 0.18, 0.05), seg(-0.2, -0.58, -0.26, -0.78, 0.05), seg(0.4, 0.66, 0.5, 0.84, 0.05))
    bale = U(front, top, side, tufts)
    shade = U(side, inter(front, -0.45 - Y))
    twine = U(box(-0.42, -0.2, 0.07, 0.4), box(0.2, -0.2, 0.07, 0.4), poly([(-0.49, 0.2), (-0.35, 0.2), (-0.01, 0.66), (-0.17, 0.66)]), poly([(0.13, 0.2), (0.27, 0.2), (0.57, 0.66), (0.43, 0.66)]))
    straw = U(seg(-0.2, -0.3, -0.02, -0.3, 0.04), seg(0.3, -0.04, 0.44, -0.04, 0.04), seg(-0.1, 0.0, 0.06, 0.0, 0.04), seg(-0.6, -0.1, -0.52, -0.1, 0.04),
              seg(0.1, 0.46, 0.4, 0.46, 0.04), seg(-0.2, 0.36, -0.08, 0.36, 0.04))
    return [bale, shade, twine, straw]


@sticker("autumn", "hay", "Hay bale", ["#E8B83A", "#B8841A", "#8A5A18", "#FFE08A"], ink=1.0)
def _():
    bale, shade, twine, straw = _zoom(0.9, _hay)
    return [bale, shade, twine, straw]


# ---- pinecone ----
@sticker("autumn", "pinecone", "Pinecone", ["#8A5230", "#5C3318", "#D9A25A", "#4A2E18"], ink=1.0)
def _():
    cone = brush([(0.0, -0.8), (0.0, -0.3), (0.0, 0.26), (0.0, 0.5)], [0.04, 0.46, 0.5, 0.3])
    shade = _shade(cone, -0.1, 0.1)
    scales = U(*[arc(x, y, 0.19, math.pi * 1.1, math.pi * 1.9, 0.055) for y in (0.36, 0.1, -0.16, -0.42) for x in (-0.34 + (0.17 if round((y + 0.36) / 0.26) % 2 else 0.0) + 0.34 * k for k in range(3))])
    scales = inter(scales, cone + 0.02)
    stem = U(seg(0.0, 0.52, 0.04, 0.8, 0.06), box(0.04, 0.84, 0.1, 0.05, 0.02))
    return [cone, shade, scales, stem]


# ---- sleeping fox ----
def _fox():
    tail = brush([(0.6, -0.06), (0.78, -0.42), (0.34, -0.66), (-0.3, -0.58)], [0.2, 0.28, 0.28, 0.17])
    head = circle(-0.5, 0.08, 0.4)
    body = U(oval(0.16, -0.1, 0.64, 0.46), head, poly([(-0.86, 0.26), (-0.82, 0.8), (-0.46, 0.4)]), poly([(-0.5, 0.36), (-0.14, 0.76), (-0.12, 0.2)]),
             poly([(-0.72, -0.06), (-0.98, -0.24), (-0.66, -0.3)]))
    fox = U(tail, body)
    dark = U(arc(-0.54, 0.12, 0.14, math.radians(200), math.radians(340), 0.045), circle(-0.97, -0.22, 0.065), poly([(-0.78, 0.36), (-0.76, 0.64), (-0.58, 0.4)]),
             poly([(-0.42, 0.36), (-0.2, 0.6), (-0.2, 0.32)]))
    white = U(inter(tail, -0.1 - X), inter(circle(-0.5, 0.08, 0.4), -0.1 - Y - 0.0) * 0 + inter(oval(-0.58, -0.14, 0.4, 0.2), circle(-0.5, 0.08, 0.4)))
    leaves = U(oval(0.0, -0.86, 0.9, 0.14), circle(-0.5, -0.76, 0.16), circle(0.2, -0.74, 0.2), circle(0.66, -0.78, 0.16), _blade(-0.3, -0.7, 2.2, 0.3, 0.1))
    return [fox, dark, white, leaves]


@sticker("autumn", "fox", "Curled fox", ["#F08A2A", "#3A2418", "#FFFFFF", "#B8321A"], ink=1.0)
def _():
    fox, dark, white, leaves = _zoom(0.9, _fox)
    return [fox, dark, white, leaves]


# ---- rain cloud with leaves ----
def _raincloud():
    cloud = U(box(0, 0.5, 0.74, 0.2, 0.2), circle(-0.36, 0.6, 0.3), circle(0.1, 0.72, 0.36), circle(0.48, 0.56, 0.26))
    shade = _shade(cloud, -0.1, 0.1)
    orange = U(poly([(-0.5 + x * 0.44, -0.02 + y * 0.44) for x, y in _maple_pts()]), poly([(0.3 + x * 0.4, -0.58 + y * 0.4) for x, y in _maple_pts()]))
    red = U(poly([(0.56 + x * 0.36, 0.0 + y * 0.36) for x, y in _maple_pts()]), poly([(-0.3 + x * 0.4, -0.64 + y * 0.4) for x, y in _maple_pts()]))
    return [cloud, shade, orange, red]


@sticker("autumn", "raincloud", "Leaf shower", ["#B6C3D6", "#7F90A8", "#E8761F", "#C0381A"], ink=1.0)
def _():
    cloud, shade, orange, red = _zoom(0.88, _raincloud)
    return [cloud, shade, orange, red]


# ---- COZY ----
@sticker("autumn", "cozy", "Cozy", ["#C8702A", "#8F4A14", "#FFF0D0", "#FFD23A"], ink=1.0)
def _():
    patch = box(0, 0, 0.9, 0.52, 0.16)
    shade = _shade(patch, -0.08, 0.08)
    word = text("COZY", 0.0, 0.0, 0.34, maxw=1.3)
    stitch = U(*[box(x, 0.4, 0.06, 0.025, 0.01) for x in np.linspace(-0.6, 0.6, 7)], *[box(x, -0.4, 0.06, 0.025, 0.01) for x in np.linspace(-0.6, 0.6, 7)])
    return [patch, shade, word, stitch]
