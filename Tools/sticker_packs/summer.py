PACK = ("summer", "Beach Summer", False)
PRO_IDS = {"tower", "flamingo", "castle", "van", "coconut", "umbrella"}


def _shift(make, dx, dy):
    """The shape `make()` draws, slid by (dx, dy)."""
    with rotated(0.0, 0.0, 0.0, dx, dy):
        return make()


def _rim(make, dx=-0.1, dy=0.1):
    """Lower-right shade: the shape minus a copy of itself nudged up-left."""
    return sub(make(), _shift(make, dx, dy))


def _lowr(d, c=0.12):
    """The lower-right part of d (beyond a diagonal)."""
    return inter(d, c - (X - Y) * 0.7071)


def _panels(cx, cy, r, centers, halfw):
    """Meridian panels of a ball seen from the side: each (centre angle, half width) in radians, cut to the ball."""
    sc = r * np.sqrt(np.maximum(1 - ((Y - cy) / r) ** 2, 0.03))
    th = np.arcsin(np.clip((X - cx) / sc, -1, 1))
    d = np.full(X.shape, BIG)
    for tc in centers:
        d = np.minimum(d, (np.abs(th - tc) - halfw) * sc * 0.8)
    return inter(d, circle(cx, cy, r))


# ---- sandcastle ----
def _castle_build():
    teeth = [box(cx + dx, ty, 0.05, 0.07, 0.01) for cx, ty in ((-0.55, 0.52), (0.55, 0.52), (0.0, 0.62)) for dx in (-0.14, 0.0, 0.14)]
    return U(box(0, -0.52, 0.84, 0.2, 0.04), box(-0.56, -0.0, 0.2, 0.45, 0.03), box(0.56, -0.0, 0.2, 0.45, 0.03), box(0, 0.08, 0.3, 0.54, 0.03), *teeth)


@sticker("summer", "castle", "Sandcastle", ["#F4D58D", "#D4A85A", "#8A5A2B", "#FF4F4F"], ink=1.0)
def _():
    castle = _castle_build()
    shade = _lowr(castle, 0.15)
    details = U(box(0, -0.5, 0.16, 0.18, 0.08), box(-0.56, 0.12, 0.08, 0.13, 0.03), box(0.56, 0.12, 0.08, 0.13, 0.03), box(0, 0.3, 0.08, 0.13, 0.03))
    flag = U(seg(0, 0.62, 0, 0.9, 0.05), poly([(0.0, 0.94), (0.4, 0.82), (0.0, 0.7)]))
    return [castle, shade, details, flag]


# ---- beach umbrella ----
@sticker("summer", "umbrella", "Beach umbrella", ["#FF5A5F", "#C23A40", "#FFFFFF", "#8A5A2B"], ink=1.0)
def _():
    with rotated(0.25, 0, 0):
        dome = U(inter(circle(0, 0.0, 0.8), -Y), *[circle(x, 0.0, 0.14) for x in (-0.66, -0.33, 0.0, 0.33, 0.66)])
        shade = _lowr(dome, 0.0)
        stripes = inter(U(poly([(0, 0.85), (-0.48, 0.0), (-0.2, 0.0)]), poly([(0, 0.85), (0.2, 0.0), (0.48, 0.0)]),
                          circle(-0.33, 0.0, 0.14), circle(0.33, 0.0, 0.14)), circle(0, 0.0, 0.95))
        pole = U(seg(0, 0.88, 0, -0.85, 0.09), circle(0, 0.88, 0.1))
    return [dome, shade, stripes, pole]


# ---- striped beach towel ----
def _towel_build():
    return box(0, 0, 0.82, 0.52, 0.06)


@sticker("summer", "towel", "Beach towel", ["#27C4C4", "#16999A", "#FFFFFF", "#FFD34D"], ink=1.0)
def _():
    with rotated(0.3, 0, 0):
        towel = _towel_build()
        shade = _rim(_towel_build, -0.08, 0.1)
        stripes = U(box(0, 0.12, 0.82, 0.07), box(0, -0.12, 0.82, 0.07))
        stripes = inter(stripes, towel)
        hem = U(box(-0.72, 0, 0.07, 0.52), box(0.72, 0, 0.07, 0.52))
        hem = inter(hem, towel)
    return [towel, shade, stripes, hem]


# ---- sunscreen ----
def _bottle_build():
    return U(box(0, -0.18, 0.4, 0.62, 0.14), box(0, 0.5, 0.17, 0.12, 0.04))


@sticker("summer", "sunscreen", "Sunscreen", ["#FF9F1C", "#CC7208", "#FFFFFF", "#1B5FD0"], ink=1.0)
def _():
    bottle = _bottle_build()
    shade = _rim(_bottle_build, -0.1, 0.0)
    label = U(box(0, -0.2, 0.32, 0.36, 0.05), box(0, 0.7, 0.2, 0.1, 0.04))
    words = text("SPF", 0, -0.1, 0.24, maxw=0.55)
    stripe = U(box(0, -0.45, 0.3, 0.06))
    print_ = U(words, stripe)
    return [bottle, shade, label, print_]


# ---- snorkel mask ----
@sticker("summer", "snorkel", "Snorkel", ["#1F6FE0", "#134A9C", "#BDF1FF", "#FFD34D"], ink=1.0)
def _():
    frame = U(box(-0.16, -0.1, 0.62, 0.42, 0.22), box(-0.16, -0.52, 0.16, 0.1, 0.04))
    shade = _lowr(frame, 0.0)
    glass = box(-0.16, -0.08, 0.48, 0.3, 0.16)
    tube = U(brush([(0.46, 0.15), (0.66, 0.45), (0.64, 0.78)], [0.12, 0.12, 0.12]), circle(0.64, 0.8, 0.14), circle(0.46, 0.14, 0.12))
    return [frame, shade, glass, tube]


# ---- swim fins ----
def _fin_build(ox, ang):
    with rotated(ang, ox, 0.0):
        return U(poly([(ox - 0.12, 0.85), (ox + 0.12, 0.85), (ox + 0.15, 0.3), (ox + 0.36, -0.72), (ox - 0.36, -0.72), (ox - 0.15, 0.3)]), circle(ox - 0.24, -0.62, 0.13), circle(ox + 0.24, -0.62, 0.13))


@sticker("summer", "fins", "Swim fins", ["#FFD34D", "#D49A10", "#1B5FD0", "#FFFFFF"], ink=1.0)
def _():
    fins = U(_fin_build(-0.4, -0.25), _fin_build(0.4, 0.25))
    shade = _lowr(fins, 0.25)
    with rotated(-0.25, -0.4, 0.0):
        r1 = U(box(-0.4, -0.55, 0.26, 0.06), box(-0.4, -0.3, 0.2, 0.06))
    with rotated(0.25, 0.4, 0.0):
        r2 = U(box(0.4, -0.55, 0.26, 0.06), box(0.4, -0.3, 0.2, 0.06))
    heel = U(box(-0.4, 0.65, 0.12, 0.06), box(0.4, 0.65, 0.12, 0.06))
    ribs = U(r1, r2)
    return [fins, shade, ribs, heel]


# ---- lifeguard tower ----
@sticker("summer", "tower", "Lifeguard tower", ["#FFF3D6", "#D9C59A", "#E3172F", "#9A6A3A"], ink=1.0)
def _():
    cabin = box(0, 0.12, 0.5, 0.3, 0.03)
    shade = _lowr(cabin, 0.1)
    roof = U(poly([(-0.66, 0.46), (0.66, 0.46), (0.5, 0.64), (-0.5, 0.64)]), seg(0.3, 0.64, 0.3, 0.92, 0.035), poly([(0.3, 0.92), (0.62, 0.82), (0.3, 0.72)]))
    legs = U(seg(-0.4, -0.18, -0.52, -0.9, 0.08), seg(0.4, -0.18, 0.52, -0.9, 0.08), seg(-0.46, -0.45, 0.46, -0.3, 0.055),
             seg(0.46, -0.45, -0.46, -0.3, 0.055), box(0, -0.2, 0.5, 0.05, 0.01))
    ladder = U(seg(-0.08, -0.2, 0.02, -0.9, 0.055), seg(0.2, -0.2, 0.3, -0.9, 0.055), *[box(0.12 + 0.036 * k, -0.35 - 0.17 * k, 0.1, 0.035) for k in range(4)])
    stilts = U(legs, ladder)
    return [cabin, shade, roof, stilts]


# ---- inflatable flamingo ----
@sticker("summer", "flamingo", "Flamingo float", ["#FF6FA8", "#D13C7C", "#2A1A26", "#FFFFFF"], ink=1.0)
def _():
    tube = sub(ellipse(0.0, -0.45, 0.86, 0.4), ellipse(0.0, -0.45, 0.46, 0.18))
    neck = brush([(0.4, -0.2), (0.62, 0.15), (0.42, 0.5), (0.1, 0.62)], [0.16, 0.14, 0.13, 0.13])
    head = circle(0.05, 0.64, 0.2)
    bird = U(tube, neck, head)
    shade = U(_lowr(tube, -0.2), sub(neck, brush([(0.36, -0.2), (0.55, 0.15), (0.35, 0.5), (0.05, 0.62)], [0.16, 0.14, 0.13, 0.13])))
    beak = U(poly([(-0.1, 0.72), (-0.36, 0.56), (-0.3, 0.42), (-0.08, 0.6)]), circle(0.08, 0.7, 0.045))
    shine = seg(-0.62, -0.28, -0.4, -0.12, 0.05)
    return [bird, shade, beak, shine]


# ---- beach ball ----
def _ballc_build():
    return circle(0, 0, 0.84)


@sticker("summer", "ball", "Beach ball", ["#FFFFFF", "#C9D4E8", "#FF4F4F", "#2F8BFF"], ink=1.0)
def _():
    ball = _ballc_build()
    shade = _rim(_ballc_build, -0.14, 0.14)
    red = _panels(0, 0, 0.84, [-0.628], 0.314)
    blue = _panels(0, 0, 0.84, [0.628], 0.314)
    return [ball, shade, red, blue]


# ---- bucket and spade ----
def _bucket_build():
    return U(poly([(-0.58, 0.2), (0.38, 0.2), (0.3, -0.7), (-0.5, -0.7)]), box(-0.1, 0.22, 0.5, 0.08, 0.04))


@sticker("summer", "bucket", "Bucket & spade", ["#2F9BFF", "#1B6BC0", "#FF4F4F", "#FFD34D"], ink=1.0)
def _():
    bucket = _bucket_build()
    shade = _rim(_bucket_build, -0.12, 0.0)
    spade = U(taper(0.46, -0.05, 0.74, 0.62, 0.07, 0.07), poly([(0.5, -0.1), (0.9, -0.1), (0.82, -0.72), (0.58, -0.72)]), box(0.74, 0.7, 0.1, 0.06, 0.02))
    handle = arc(-0.1, 0.25, 0.46, math.radians(20), math.radians(160), 0.06)
    return [bucket, shade, spade, handle]


# ---- surf van ----
def _van_build():
    return U(box(0, -0.05, 0.66, 0.66, 0.2), box(0, -0.62, 0.74, 0.1, 0.04))


@sticker("summer", "van", "Surf van", ["#FFD34D", "#FFFFFF", "#9FE8FF", "#243044"], ink=1.0)
def _():
    van = _van_build()
    roof = inter(box(0, -0.05, 0.66, 0.66, 0.2), 0.12 - Y)
    glass = U(box(-0.3, 0.34, 0.26, 0.2, 0.06), box(0.3, 0.34, 0.26, 0.2, 0.06))
    wheels = U(box(-0.62, -0.62, 0.14, 0.2, 0.05), box(0.62, -0.62, 0.14, 0.2, 0.05), circle(-0.4, -0.3, 0.11), circle(0.4, -0.3, 0.11),
               box(0, -0.62, 0.3, 0.04, 0.0), box(0, -0.1, 0.05, 0.14, 0.02), box(0, -0.4, 0.16, 0.05, 0.02), box(0, 0.76, 0.5, 0.05, 0.02), box(-0.4, 0.68, 0.05, 0.08), box(0.4, 0.68, 0.05, 0.08))
    return [van, roof, glass, wheels]


# ---- cooler ----
def _cooler_build():
    return U(box(0, -0.2, 0.74, 0.46, 0.08), box(0, 0.3, 0.8, 0.14, 0.05))


@sticker("summer", "cooler", "Cooler", ["#2F7BE0", "#1B4FA8", "#FFFFFF", "#FF4F4F"], ink=1.0)
def _():
    body = _cooler_build()
    shade = _rim(_cooler_build, -0.1, 0.1)
    lid = box(0, 0.3, 0.8, 0.14, 0.05)
    handle = U(arc(0, 0.34, 0.26, math.radians(20), math.radians(160), 0.06), box(-0.7, -0.2, 0.05, 0.14, 0.02), box(0.7, -0.2, 0.05, 0.14, 0.02), box(0, 0.12, 0.1, 0.06))
    return [body, shade, lid, handle]


# ---- hammock ----
@sticker("summer", "hammock", "Hammock", ["#FF7A59", "#C9482A", "#FFFFFF", "#8A5A2B"], ink=1.0)
def _():
    fabric = sub(ellipse(0, 0.0, 0.76, 0.5), ellipse(0, 0.36, 0.84, 0.42))
    shade = _lowr(fabric, 0.0)
    stripes = inter(U(box(-0.3, 0, 0.08, 0.6), box(0.1, 0, 0.08, 0.6), box(0.5, 0, 0.08, 0.6)), fabric)
    posts = U(box(-0.82, -0.1, 0.11, 0.8, 0.04), box(0.82, -0.1, 0.11, 0.8, 0.04), polyline([(-0.82, 0.5), (-0.6, 0.0)], 0.07), polyline([(0.82, 0.5), (0.6, 0.0)], 0.07),
              box(0, -0.86, 0.93, 0.07, 0.03))
    return [fabric, shade, stripes, posts]


# ---- coconut drink ----
def _coco_build():
    return circle(0, -0.2, 0.7)


@sticker("summer", "coconut", "Coconut drink", ["#8A5A2B", "#FFF3D6", "#FF4F4F", "#FF6FA8"], ink=1.0)
def _():
    coconut = _coco_build()
    milk = ellipse(0, 0.2, 0.5, 0.17)
    straw = U(seg(0.12, 0.2, 0.42, 0.88, 0.065), seg(0.42, 0.88, 0.62, 0.84, 0.065))
    pet = petals(-0.36, 0.52, 5, 0.12, 0.1, 0.085)
    flower = sub(U(pet, circle(-0.36, 0.52, 0.12)), circle(-0.36, 0.52, 0.05))
    return [coconut, milk, straw, flower]


# ---- beach radio ----
def _radio_build():
    return U(box(0, -0.2, 0.78, 0.5, 0.12), taper(0.5, 0.3, 0.72, 0.9, 0.05, 0.05), arc(-0.1, 0.25, 0.5, math.radians(15), math.radians(165), 0.07))


@sticker("summer", "radio", "Beach radio", ["#FFD34D", "#D49A10", "#2A3044", "#FF4F4F"], ink=1.0)
def _():
    body = _radio_build()
    shade = _rim(_radio_build, -0.1, 0.1)
    grille = U(*[circle(x, y, 0.07) for x in (-0.58, -0.42, -0.26, -0.1) for y in (-0.05, -0.2, -0.35)])
    dial = U(circle(0.42, -0.2, 0.16), seg(0.2, -0.45, 0.62, -0.45, 0.04))
    return [body, shade, grille, dial]


# ---- SURF'S UP sign ----
@sticker("summer", "surfsup", "Surf's up", ["#1FA2E8", "#0B6DB8", "#FFFFFF", "#FFD34D"], ink=1.0)
def _():
    sign = box(0, 0, 0.92, 0.66, 0.16)
    shade = sub(sign, box(-0.06, 0.07, 0.92, 0.66, 0.16))
    words = U(text("SURF'S", 0, 0.24, 0.42, maxw=1.7), text("UP", 0, -0.28, 0.42, maxw=0.9))
    trim = U(box(0, -0.58, 0.5, 0.035), box(0, 0.58, 0.5, 0.035))
    return [sign, shade, words, trim]


# ---- volleyball ----
@sticker("summer", "volleyball", "Volleyball", ["#FFF6D8", "#D9C58C", "#2F8BFF", "#FFD34D"], ink=1.0)
def _():
    ball = circle(0, 0, 0.82)
    shade = _rim(lambda: circle(0, 0, 0.82), -0.14, 0.14)
    blue = U(inter(ball, ring(-1.0, 0.45, 1.06, 0.15)), inter(ball, ring(0.0, -1.55, 1.2, 0.15)))
    yellow = inter(ball, ring(1.0, 0.45, 1.06, 0.15))
    return [ball, shade, blue, yellow]


# ---- seagull ----
def _gull_build():
    return U(oval(-0.12, -0.05, 0.56, 0.4, 0.15), circle(0.4, 0.3, 0.27), poly([(-0.55, 0.0), (-0.95, 0.12), (-0.8, -0.28), (-0.5, -0.2)]))


@sticker("summer", "seagull", "Seagull", ["#FFFFFF", "#C2CCDA", "#46566A", "#FF9F1C"], ink=1.0)
def _():
    body = _gull_build()
    shade = _rim(_gull_build, -0.12, 0.1)
    wing = U(oval(-0.2, 0.0, 0.42, 0.22, 0.25), circle(0.46, 0.34, 0.06))
    beak = U(poly([(0.58, 0.38), (0.5, 0.18), (0.96, 0.2)]), seg(-0.1, -0.42, -0.1, -0.82, 0.055), seg(0.12, -0.4, 0.14, -0.82, 0.055),
             box(-0.1, -0.84, 0.14, 0.04, 0.02), box(0.14, -0.84, 0.14, 0.04, 0.02))
    return [body, shade, wing, beak]
