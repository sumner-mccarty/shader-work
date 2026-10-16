PACK = ("usa", "Fourth of July", False)
PRO_IDS = {"snare", "flag", "eagle", "burst", "guitar", "bell"}

RED = "#E3172F"
BLUE = "#1F47B5"
NAVY = "#102668"


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


def _bands(t, size):
    """Alternating bands for a coordinate t counted in band widths: negative inside every band whose index is even."""
    near = np.abs(np.mod(t - 0.5 + 1.0, 2.0) - 1.0)
    return (near - 0.5) * size


def _wave(cx, cy, hw, hh, amp, k, ph):
    """A waving rectangle: (sdf, v) where v is the flag's own vertical coordinate, so stripes follow the wave."""
    arg = k * (X - cx) + ph
    v = Y - cy - amp * np.sin(arg)
    qx = np.abs(X - cx) - hw
    qy = np.abs(v) - hh
    d = np.hypot(np.maximum(qx, 0), np.maximum(qy, 0)) + np.minimum(np.maximum(qx, qy), 0)
    return d / np.sqrt(1 + (amp * k * np.cos(arg)) ** 2), v


def _flag_parts(cx, cy, hw, hh, amp, k, ph, rows=7):
    """(cloth, red stripes, blue canton, white stars) of a waving stars-and-stripes flag."""
    cloth, v = _wave(cx, cy, hw, hh, amp, k, ph)
    g = np.sqrt(1 + (amp * k * np.cos(k * (X - cx) + ph)) ** 2)
    sh = 2 * hh / rows
    bars = inter(cloth, _bands((v + hh) / sh, sh) / g)
    cwh, chh = hw * 0.42, sh * 2
    uc, vc = -hw + cwh, hh - chh
    qx = np.abs(X - cx - uc) - cwh
    qy = np.abs(v - vc) - chh
    dc = np.hypot(np.maximum(qx, 0), np.maximum(qy, 0)) + np.minimum(np.maximum(qx, qy), 0)
    canton = inter(cloth, dc / g)
    stars = []
    for r in range(-1, 2):
        for c in (-1, 1):
            xs = uc + c * cwh * 0.5
            ys = vc + r * chh * 0.62
            stars.append(star(cx + xs, cy + ys + amp * math.sin(k * xs + ph), 5, hw * 0.12, hw * 0.05))
    return cloth, bars, canton, U(*stars)


# ---- the flag, waving ----
@sticker("usa", "flag", "US flag", ["#FFFFFF", RED, BLUE, "#FFFFFF"], ink=1.0)
def _():
    flag, stripes, canton, stars = _flag_parts(0.0, 0.0, 0.84, 0.52, 0.13, 4.2, 0.4)
    return [flag, stripes, canton, stars]


# ---- stars-and-stripes shield ----
def _shield_build():
    return poly(spline([(-0.74, 0.78), (0.0, 0.84), (0.74, 0.78), (0.74, 0.1), (0.5, -0.45), (0.0, -0.9), (-0.5, -0.45), (-0.74, 0.1)], n=8))


@sticker("usa", "shield", "Stars & stripes", ["#FFFFFF", RED, BLUE, "#FFFFFF"], ink=1.0)
def _():
    shield = _shield_build()
    bars = inter(shield, stripes(0.34, 0.0, 0.5))
    chief = inter(shield, 0.2 - Y)
    stars = U(star(-0.4, 0.52, 5, 0.17, 0.07), star(0.0, 0.56, 5, 0.17, 0.07), star(0.4, 0.52, 5, 0.17, 0.07))
    return [shield, bars, chief, stars]


# ---- spread eagle ----
_WING = [(-0.2, 0.28), (-0.5, 0.62), (-0.95, 0.74), (-0.8, 0.52), (-0.98, 0.42), (-0.78, 0.28), (-0.92, 0.14), (-0.7, 0.04), (-0.78, -0.1), (-0.48, -0.14), (-0.22, -0.1)]


@sticker("usa", "eagle", "Bald eagle", [NAVY, "#FFFFFF", RED, "#FFC531"], ink=1.0)
def _():
    wings = U(poly(_WING), poly([(-x, y) for x, y in _WING]))
    body = U(oval(0.0, -0.1, 0.3, 0.46), wings)
    bars = inter(inter(wings, stripes(0.3, 1.5708, 0.55)), Y - 0.4)
    head = U(circle(-0.06, 0.58, 0.25), poly([(-0.22, -0.4), (0.22, -0.4), (0.42, -0.92), (0.0, -0.78), (-0.42, -0.92)]))
    gold = U(poly([(-0.26, 0.64), (-0.6, 0.5), (-0.26, 0.42)]), seg(-0.14, -0.5, -0.2, -0.78, 0.05), seg(0.14, -0.5, 0.2, -0.78, 0.05))
    markings = U(bars, circle(-0.14, 0.62, 0.06))
    return [body, head, markings, gold]


# ---- firework rocket ----
@sticker("usa", "rocket", "Rocket", [RED, "#B01024", "#FFFFFF", BLUE], ink=1.0)
def _():
    with rotated(-0.7, 0, 0):
        body = box(0, 0.0, 0.27, 0.56, 0.1)
        nose = poly([(-0.27, 0.56), (0.27, 0.56), (0.0, 1.0)])
        fins = U(poly([(-0.27, -0.3), (-0.55, -0.7), (-0.27, -0.5)]), poly([(0.27, -0.3), (0.55, -0.7), (0.27, -0.5)]))
        stick = seg(0.0, -0.5, 0.0, -1.0, 0.09)
        flame = poly([(-0.17, -0.5), (0.17, -0.5), (0.0, -0.92)])
        band = box(0, 0.1, 0.27, 0.09)
    shade = _lowr(body, 0.0)
    trim = U(band, stick, flame)
    tip = U(nose, fins)
    return [body, shade, trim, tip]


# ---- firework burst ----
@sticker("usa", "burst", "Fireworks", [RED, BLUE, "#FFFFFF", "#FFC531"], ink=1.0)
def _():
    reds, blues, dots = [], [], []
    for k in range(12):
        a = k * math.pi / 6
        c, s_ = math.cos(a), math.sin(a)
        ray = taper(0.22 * c, 0.22 * s_, 0.66 * c, 0.66 * s_, 0.05, 0.1)
        (reds if k % 2 == 0 else blues).append(ray)
        dots.append(circle(0.8 * c, 0.8 * s_, 0.075))
    rays = U(*reds)
    beams = U(*blues)
    sparks = U(*dots)
    core = star(0, 0, 8, 0.3, 0.14)
    return [rays, beams, sparks, core]


# ---- sparkler ----
@sticker("usa", "sparkler", "Sparkler", ["#6B7686", RED, BLUE, "#FFFFFF"], ink=1.0)
def _():
    stick = seg(-0.7, -0.86, 0.04, -0.04, 0.085)
    reds, blues, dots = [], [], []
    for k in range(10):
        a = k * math.pi / 5
        c, s_ = math.cos(a), math.sin(a)
        ray = taper(0.24 + 0.14 * c, 0.24 + 0.14 * s_, 0.24 + 0.5 * c, 0.24 + 0.5 * s_, 0.06, 0.1)
        (reds if k % 2 == 0 else blues).append(ray)
        dots.append(circle(0.24 + 0.62 * c, 0.24 + 0.62 * s_, 0.075))
    rays = U(*reds)
    beams = U(*blues)
    sparks = U(*dots, star(0.24, 0.24, 8, 0.36, 0.14))
    return [stick, rays, beams, sparks]


# ---- liberty bell ----
def _bell_build():
    body = poly(spline([(-0.2, 0.6), (0.2, 0.6), (0.3, 0.2), (0.62, -0.5), (0.72, -0.64), (-0.72, -0.64), (-0.62, -0.5), (-0.3, 0.2)], n=8))
    return U(body, circle(0.0, -0.74, 0.14))


@sticker("usa", "bell", "Liberty bell", ["#FFC531", "#D8960F", RED, BLUE], ink=1.0)
def _():
    bell = _bell_build()
    shade = _rim(_bell_build, -0.12, 0.0)
    yoke = U(box(0, 0.74, 0.5, 0.1, 0.04), box(0, 0.66, 0.1, 0.14, 0.02))
    crack = polyline([(0.12, -0.64), (0.2, -0.38), (0.06, -0.2), (0.16, 0.05)], 0.05)
    band = box(0, -0.4, 0.58, 0.07)
    crack_band = U(crack, band)
    return [bell, shade, yoke, crack_band]


# ---- torch ----
def _torch_build():
    return U(taper(0.0, -0.8, 0.0, -0.04, 0.17, 0.26), poly([(-0.5, -0.04), (0.5, -0.04), (0.36, -0.22), (-0.36, -0.22)]), box(0, -0.04, 0.52, 0.07, 0.02))


@sticker("usa", "torch", "Torch", [BLUE, NAVY, RED, "#FFFFFF"], ink=1.0)
def _():
    torch = _torch_build()
    shade = _rim(_torch_build, -0.1, 0.0)
    flame = U(circle(0.0, 0.26, 0.36), taper(0.0, 0.26, 0.06, 0.8, 0.34, 0.0), circle(-0.4, 0.24, 0.13), taper(-0.4, 0.24, -0.45, 0.56, 0.13, 0.0))
    glow = U(circle(0.0, 0.24, 0.18), taper(0.0, 0.24, 0.03, 0.58, 0.18, 0.0))
    ring_band = U(glow, box(0, -0.5, 0.22, 0.07))
    return [torch, shade, flame, ring_band]


# ---- parade snare drum ----
def _snare_build():
    return U(box(0, -0.05, 0.8, 0.4), oval(0, -0.45, 0.8, 0.26), oval(0, 0.35, 0.8, 0.26))


@sticker("usa", "snare", "Parade drum", [BLUE, NAVY, "#FFFFFF", RED], ink=1.0)
def _():
    drum = _snare_build()
    shade = _lowr(drum, 0.15)
    head = oval(0, 0.35, 0.68, 0.2)
    stars = U(*[star(x, -0.22, 5, 0.15, 0.062) for x in (-0.44, 0.0, 0.44)])
    white = U(head, stars)
    hoops = U(shell(oval(0, 0.35, 0.8, 0.26), 0.05), inter(shell(oval(0, -0.45, 0.8, 0.26), 0.05), Y + 0.45),
              *[box(x, -0.2, 0.04, 0.3) for x in (-0.66, -0.22, 0.22, 0.66)])
    sticks = U(seg(-0.62, 0.7, 0.34, 0.2, 0.06), seg(0.62, 0.7, -0.34, 0.2, 0.06), circle(-0.62, 0.7, 0.09), circle(0.62, 0.7, 0.09))
    red = U(hoops, sticks)
    return [drum, shade, white, red]


# ---- bunting ----
def _swag(x):
    return 0.5 - 0.32 * (1 - (x / 0.85) ** 2)


@sticker("usa", "bunting", "Bunting", ["#FFFFFF", RED, BLUE, NAVY], ink=1.0)
def _():
    fans, reds, blues = [], [], []
    for xk in (-0.5, 0.0, 0.5):
        cy = _swag(xk) - 0.03
        fan = inter(circle(xk, cy, 0.42), Y - cy)
        t = (np.arctan2(Y - cy, X - xk) + math.pi) / (math.pi / 6)
        fans.append(fan)
        reds.append(inter(fan, _bands(t, 0.22)))
        blues.append(inter(circle(xk, cy, 0.15), Y - cy))
    rope = polyline([(x / 20.0 * 0.85, _swag(x / 20.0 * 0.85)) for x in range(-20, 21)], 0.09)
    cloth = U(*fans)
    stripe = U(*reds)
    centers = U(*blues)
    return [cloth, stripe, centers, rope]


# ---- top hat ----
def _hat_build():
    return U(box(0, 0.15, 0.4, 0.55, 0.06), box(0, -0.45, 0.82, 0.12, 0.06))


@sticker("usa", "tophat", "Star hat", [BLUE, NAVY, RED, "#FFFFFF"], ink=1.0)
def _():
    hat = _hat_build()
    shade = _rim(_hat_build, -0.1, 0.1)
    band = box(0, -0.2, 0.4, 0.14)
    stars = U(star(-0.14, 0.38, 5, 0.12, 0.05), star(0.16, 0.5, 5, 0.12, 0.05), star(-0.02, 0.18, 5, 0.12, 0.05), star(0.0, -0.2, 5, 0.1, 0.04))
    return [hat, shade, band, stars]


# ---- hot dog ----
@sticker("usa", "hotdog", "Hot dog", ["#F2C078", "#D9432E", "#FFD93A", RED], ink=1.0)
def _():
    with rotated(0.55, 0, 0):
        bun = box(0, -0.1, 0.62, 0.3, 0.28)
        dog = box(0, 0.02, 0.84, 0.16, 0.16)
        mustard = polyline([(-0.7 + 0.14 * k, 0.02 + (0.07 if k % 2 == 0 else -0.07)) for k in range(11)], 0.05)
        flag = U(seg(0.28, 0.1, 0.28, 0.78, 0.045), poly([(0.28, 0.78), (0.28, 0.46), (0.62, 0.62)]))
    return [bun, dog, mustard, flag]


# ---- apple pie ----
@sticker("usa", "pie", "Apple pie", [BLUE, RED, "#E8B26A", "#B87D3A"], ink=1.0)
def _():
    dish = poly([(-0.8, -0.28), (0.8, -0.28), (0.64, -0.68), (-0.64, -0.68)])
    dome = U(inter(ellipse(0, -0.2, 0.86, 0.66), -(Y + 0.3)), *[circle(-0.74 + 0.185 * k, -0.3, 0.1) for k in range(9)])
    inner = inter(ellipse(0, -0.2, 0.7, 0.52), -(Y + 0.3))
    filling = inner
    lattice = U(stripes(0.3, 0.785, 0.42), stripes(0.3, -0.785, 0.42))
    crust = U(sub(dome, inner), inter(inner, lattice))
    shade = _lowr(crust, 0.1)
    return [dish, filling, crust, shade]


# ---- USA map ----
_US = [(-124.7, 48.4), (-123.1, 49.0), (-95.2, 49.0), (-94.6, 48.7), (-89.6, 48.0), (-84.8, 46.5), (-83.5, 45.8), (-82.5, 43.0), (-83.1, 42.0), (-79.0, 42.8),
       (-76.5, 43.6), (-74.9, 45.0), (-71.5, 45.0), (-70.2, 46.8), (-69.2, 47.4), (-67.8, 47.1), (-67.0, 44.8), (-69.5, 43.9), (-70.7, 42.8), (-70.0, 41.8),
       (-71.5, 41.4), (-73.7, 40.9), (-74.0, 40.4), (-74.9, 38.9), (-75.9, 36.8), (-75.5, 35.3), (-77.0, 34.5), (-79.0, 33.3), (-81.0, 31.8), (-81.3, 30.2),
       (-80.0, 26.8), (-80.4, 25.2), (-81.2, 25.2), (-82.2, 26.5), (-82.8, 27.9), (-83.0, 29.2), (-84.0, 30.1), (-85.3, 29.7), (-86.5, 30.4), (-88.0, 30.3),
       (-89.4, 30.2), (-89.2, 29.0), (-90.2, 29.1), (-91.5, 29.5), (-93.8, 29.7), (-94.8, 29.3), (-97.1, 27.8), (-97.4, 26.0), (-99.2, 26.4), (-99.5, 27.5),
       (-100.8, 29.5), (-102.4, 29.8), (-103.2, 29.0), (-104.5, 29.6), (-106.5, 31.8), (-108.2, 31.8), (-108.2, 31.3), (-111.0, 31.3), (-114.8, 32.5),
       (-117.1, 32.5), (-118.5, 34.0), (-120.6, 34.6), (-121.9, 36.6), (-122.5, 37.8), (-123.8, 39.4), (-124.4, 40.4), (-124.5, 42.8), (-124.0, 46.2)]


def _map_build():
    return poly([((lon + 96) * 0.031, (lat - 37) * 0.052) for lon, lat in _US])


@sticker("usa", "map", "USA map", ["#FFFFFF", RED, BLUE, "#FFFFFF"], ink=1.0)
def _():
    usa = _map_build()
    sh = 0.095
    bars = inter(usa, _bands((Y + 0.65) / sh, sh))
    canton = inter(usa, box(-0.52, 0.18, 0.4, 0.5))
    stars = U(*[star(-0.8 + 0.18 * c, 0.4 - 0.2 * r, 5, 0.075, 0.03) for r in range(2) for c in range(4)])
    return [usa, bars, canton, stars]


# ---- USA lettering ----
@sticker("usa", "usa", "USA", [RED, BLUE, "#FFFFFF"], ink=1.0)
def _():
    shade = text("USA", 0.07, 0.05, 0.74, maxw=1.8)
    letters = text("USA", 0.0, 0.12, 0.74, maxw=1.8)
    stars = U(*[star(-0.54 + 0.36 * k, -0.57, 5, 0.17, 0.075) for k in range(4)])
    return [shade, letters, stars]


# ---- 1776 seal ----
def _seal_build():
    return circle(0, 0, 0.84)


@sticker("usa", "seal", "1776", [BLUE, NAVY, RED, "#FFFFFF"], ink=1.0)
def _():
    seal = _seal_build()
    shade = _rim(_seal_build, -0.1, 0.1)
    rim = ring(0, 0, 0.7, 0.05)
    angs = [math.pi * (0.2 + 0.2 * k) for k in range(4)] + [math.pi * (1.2 + 0.2 * k) for k in range(4)]
    words = U(text("1776", 0, 0.0, 0.34, maxw=1.0), *[star(0.52 * math.cos(a), 0.52 * math.sin(a), 5, 0.1, 0.04) for a in angs])
    return [seal, shade, rim, words]


# ---- star-spangled guitar ----
@sticker("usa", "guitar", "Stars guitar", ["#FFFFFF", RED, BLUE, "#FFFFFF"], ink=1.0)
def _():
    with rotated(-0.55, 0.0, 0.0):
        body = U(circle(0, -0.5, 0.42), circle(0, 0.0, 0.3), circle(-0.26, 0.12, 0.13), circle(0.28, 0.14, 0.12))
        neck = box(0, 0.5, 0.11, 0.46)
        head = box(0, 0.86, 0.19, 0.13, 0.03)
        guitar = U(body, neck, head)
        bars = inter(body, _bands((Y + 0.95) / 0.14, 0.14))
        field = U(inter(body, 0.02 - Y), neck, head)
        stars = U(star(-0.12, 0.1, 5, 0.09, 0.036), star(0.14, 0.12, 5, 0.09, 0.036), star(0.0, -0.1, 5, 0.07, 0.03))
    return [guitar, bars, field, stars]
