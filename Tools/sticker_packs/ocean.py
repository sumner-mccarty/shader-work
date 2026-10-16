PACK = ("ocean", "Ocean", False)
PRO_IDS = {"swell", "lighthouse", "sub", "dolphin", "chest", "jellyfish"}


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


@sticker("ocean", "swell", "Wave", ["#1FA2E8", "#0B6DB8", "#FFFFFF", "#0B3E8C"], ink=1.0)
def _():
    pts = [(-1.1, -0.9), (-1.1, -0.3), (-0.8, -0.05), (-0.45, 0.35), (-0.05, 0.72), (0.4, 0.76), (0.72, 0.5),
           (0.74, 0.12), (0.5, -0.02), (0.36, 0.2), (0.18, 0.3), (0.2, 0.0), (0.45, -0.3), (1.1, -0.45), (1.1, -0.9)]
    water = inter(poly(spline(pts, n=8)), box(0, 0, 0.9, 0.82, 0.14))
    deep = sub(water, _shift(lambda: inter(poly(spline(pts, n=8)), box(0, 0, 0.9, 0.82, 0.14)), -0.12, 0.14))
    foam = U(inter(water, sub(circle(0.34, 0.5, 0.5), circle(0.28, 0.3, 0.36))), circle(-0.62, -0.5, 0.06),
             circle(0.0, -0.58, 0.07), circle(0.55, -0.7, 0.05))
    foam = U(inter(foam, water), inter(arc(0.05, 0.1, 0.62, math.radians(25), math.radians(110), 0.05), water))
    return [water, deep, foam]


@sticker("ocean", "sharkfin", "Shark fin", ["#7C8FA6", "#56677D", "#3FB6F0", "#FFFFFF"], ink=1.0)
def _():
    fin_pts = [(-0.52, -0.55), (-0.34, -0.05), (-0.06, 0.42), (0.2, 0.92), (0.22, 0.45), (0.34, 0.02), (0.62, -0.55)]
    fin = poly(spline(fin_pts, n=8))
    shade = _lowr(fin, 0.06)
    water = U(box(0, -0.66, 0.95, 0.26, 0.1), *[circle(x, -0.42, 0.17) for x in (-0.7, -0.3, 0.1, 0.5, 0.82)])
    foam = U(*[circle(x, -0.4, 0.09) for x in (-0.55, -0.1, 0.4)], box(0.0, -0.78, 0.5, 0.05, 0.03))
    return [fin, shade, water, foam]


@sticker("ocean", "whaletail", "Whale tail", ["#5B6FD6", "#3A47A6", "#FFFFFF", "#9FE8FF"], ink=1.0)
def _():
    stalk = taper(0, -0.75, 0, -0.1, 0.15, 0.11)
    lobe_l = brush([(0, -0.05), (-0.35, 0.05), (-0.62, 0.3), (-0.82, 0.75)], [0.12, 0.14, 0.12, 0.02])
    lobe_r = brush([(0, -0.05), (0.35, 0.05), (0.62, 0.3), (0.82, 0.75)], [0.12, 0.14, 0.12, 0.02])
    tail = smin(smin(stalk, lobe_l, 0.12), lobe_r, 0.12)
    shade = _lowr(tail, 0.1)
    splash = U(circle(-0.5, -0.66, 0.22), circle(-0.18, -0.72, 0.22), circle(0.18, -0.7, 0.23), circle(0.5, -0.66, 0.22),
               box(0, -0.8, 0.72, 0.12, 0.06), seg(-0.66, -0.5, -0.8, -0.3, 0.1), seg(0.66, -0.5, 0.82, -0.28, 0.1))
    drops = U(circle(-0.82, -0.2, 0.1), circle(0.84, -0.18, 0.1))
    return [tail, shade, splash, drops]


def _squid_build():
    mantle = oval(0, 0.38, 0.3, 0.6)
    tip = poly([(0, 0.98), (-0.2, 0.7), (0.2, 0.7)])
    fins = U(poly([(-0.12, 0.92), (-0.56, 0.62), (-0.18, 0.42)]), poly([(0.12, 0.92), (0.56, 0.62), (0.18, 0.42)]))
    head = circle(0, -0.1, 0.3)
    tents = U(brush([(-0.2, -0.3), (-0.3, -0.58), (-0.22, -0.86)], [0.09, 0.07, 0.04]),
              brush([(-0.07, -0.34), (-0.08, -0.62), (-0.02, -0.92)], [0.09, 0.07, 0.04]),
              brush([(0.07, -0.34), (0.08, -0.62), (0.02, -0.92)], [0.09, 0.07, 0.04]),
              brush([(0.2, -0.3), (0.3, -0.58), (0.22, -0.86)], [0.09, 0.07, 0.04]))
    return smin(smin(U(mantle, tip), fins, 0.06), U(head, tents), 0.08)


@sticker("ocean", "squid", "Squid", ["#FF5E7A", "#D63A5C", "#FFC2CF", "#1A1410"], ink=1.0)
def _():
    body = _squid_build()
    shade = _rim(_squid_build, -0.12, 0.08)
    spots = U(circle(-0.08, 0.58, 0.07), circle(0.1, 0.4, 0.06), circle(-0.06, 0.2, 0.05), circle(0.12, 0.72, 0.045))
    eyes = U(circle(-0.15, -0.1, 0.085), circle(0.15, -0.1, 0.085))
    return [body, shade, spots, eyes]


def _jellyfish_build():
    bell = U(inter(circle(0, 0.05, 0.66), -(Y - 0.05)), oval(0, 0.05, 0.66, 0.1))
    arms = U(brush([(-0.45, 0.0), (-0.55, -0.3), (-0.4, -0.55), (-0.5, -0.85)], [0.07, 0.06, 0.05, 0.03]),
             brush([(-0.15, -0.02), (-0.25, -0.35), (-0.1, -0.6), (-0.18, -0.9)], [0.08, 0.06, 0.05, 0.03]),
             brush([(0.15, -0.02), (0.25, -0.35), (0.1, -0.6), (0.18, -0.9)], [0.08, 0.06, 0.05, 0.03]),
             brush([(0.45, 0.0), (0.55, -0.3), (0.4, -0.55), (0.5, -0.85)], [0.07, 0.06, 0.05, 0.03]))
    return U(bell, arms)


@sticker("ocean", "jellyfish", "Jellyfish", ["#D58BFF", "#A64BE0", "#FFB8F4", "#1A1410"], ink=1.0)
def _():
    body = _jellyfish_build()
    shade = _rim(_jellyfish_build, -0.12, 0.1)
    spots = U(circle(-0.28, 0.4, 0.08), circle(0.0, 0.5, 0.08), circle(0.28, 0.4, 0.08))
    face = U(circle(-0.18, 0.15, 0.05), circle(0.18, 0.15, 0.05))
    return [body, shade, spots, face]


def _nautilus_build():
    return U(circle(-0.1, 0.1, 0.68), taper(0.0, -0.05, 0.7, -0.55, 0.5, 0.26))


@sticker("ocean", "nautilus", "Spiral shell", ["#FFE2C2", "#F2B98A", "#E8803A", "#8A3F12"], ink=1.0)
def _():
    shell_ = _nautilus_build()
    shade = _rim(_nautilus_build, -0.12, 0.12)
    ang = np.arctan2(Y - 0.1, X + 0.1)
    bands = inter(shell_, np.cos(ang * 4.0 + 0.4) * 0.3 - 0.0 + 0.04)
    bands = inter(bands, -(np.hypot(X + 0.1, Y - 0.1) - 0.3))
    pts = []
    for k in range(60):
        t = k / 59.0
        a = t * 4.4 + 0.5
        r = 0.05 + 0.5 * t
        pts.append((-0.1 + r * math.cos(a), 0.1 + r * math.sin(a)))
    spiral = inter(polyline(pts, 0.05), shell_)
    return [shell_, shade, bands, spiral]


def _starfish_build():
    arms = []
    for k in range(5):
        a = math.pi / 2 + k * 2 * math.pi / 5
        c, s_ = math.cos(a), math.sin(a)
        mid = (0.45 * c - 0.09 * s_, 0.45 * s_ + 0.09 * c)
        tip = (0.86 * c - 0.0 * s_, 0.86 * s_ + 0.0 * c)
        arms.append(brush([(0, 0), mid, tip], [0.28, 0.17, 0.05]))
    return smin(U(*arms), circle(0, 0, 0.3), 0.1)


@sticker("ocean", "starfish", "Starfish", ["#FF7A59", "#D9482E", "#FFE0A8", "#FFFFFF"], ink=1.0)
def _():
    body = _starfish_build()
    shade = _rim(_starfish_build, -0.1, 0.1)
    dots = []
    for k in range(5):
        a = math.pi / 2 + k * 2 * math.pi / 5
        for r in (0.3, 0.52, 0.7):
            dots.append(circle(r * math.cos(a), r * math.sin(a), 0.045 if r > 0.6 else 0.055))
    spots = U(*dots)
    shine = U(seg(-0.4, 0.5, -0.28, 0.66, 0.04), circle(-0.5, 0.36, 0.035))
    return [body, shade, spots, shine]


@sticker("ocean", "lighthouse", "Lighthouse", ["#FFFFFF", "#E3172F", "#FFE14A", "#34506E"], ink=1.0)
def _():
    tower = poly([(-0.34, -0.55), (0.34, -0.55), (0.2, 0.3), (-0.2, 0.3)])
    stripes_ = inter(tower, U(box(0, -0.38, 0.5, 0.11), box(0, -0.06, 0.5, 0.11)))
    glow = U(box(0, 0.5, 0.16, 0.14, 0.03), poly([(0.16, 0.56), (0.9, 0.78), (0.9, 0.3), (0.16, 0.44)]),
             poly([(-0.16, 0.56), (-0.9, 0.78), (-0.9, 0.3), (-0.16, 0.44)]))
    base = U(box(0, 0.34, 0.3, 0.05, 0.02), poly([(-0.2, 0.64), (0.2, 0.64), (0, 0.9)]),
             ellipse(0, -0.72, 0.6, 0.15), ellipse(-0.42, -0.58, 0.2, 0.17), ellipse(0.44, -0.6, 0.18, 0.15))
    return [tower, stripes_, glow, base]


@sticker("ocean", "lifering", "Life ring", ["#FFFFFF", "#FF4F2E", "#C9D4E3", "#E0B070"], ink=1.0)
def _():
    band = ring(0, 0, 0.6, 0.27)
    stripes_ = inter(band, U(box(0, 0, 0.17, 1.0), box(0, 0, 1.0, 0.17)))
    shade = _lowr(band, 0.36)
    rope = U(*[arc(0, 0, 0.6, math.radians(a0), math.radians(a0 + 50), 0.05) for a0 in (20, 110, 200, 290)])
    return [band, stripes_, shade, rope]


def _sub_build():
    return U(smin(oval(-0.05, -0.1, 0.78, 0.42), box(-0.12, 0.3, 0.22, 0.18, 0.06), 0.1), taper(-0.1, 0.4, -0.1, 0.74, 0.09, 0.09),
             box(0.12, 0.74, 0.22, 0.09, 0.04), box(0.78, -0.1, 0.07, 0.1))


@sticker("ocean", "sub", "Submarine", ["#2EC4B6", "#1B8F85", "#FFE14A", "#2B2E33"], ink=1.0)
def _():
    hull = _sub_build()
    shade = _rim(_sub_build, -0.1, 0.1)
    ports = U(circle(-0.45, -0.1, 0.12), circle(-0.05, -0.1, 0.12), circle(0.35, -0.1, 0.12))
    prop = poly([(0.76, -0.1), (0.9, 0.18), (0.9, -0.38)])
    return [hull, shade, ports, prop]


def _crab_claw(sgn):
    arm = seg(sgn * 0.42, -0.02, sgn * 0.6, 0.34, 0.07)
    hand = sub(circle(sgn * 0.62, 0.54, 0.22), poly([(sgn * 0.62, 0.46), (sgn * 0.42, 0.9), (sgn * 0.84, 0.9)]))
    return U(arm, hand)


def _crab_legs():
    out = []
    for sgn in (-1, 1):
        for (x1, y1, x2, y2) in [(0.4, -0.2, 0.74, -0.18), (0.34, -0.32, 0.68, -0.46), (0.24, -0.42, 0.46, -0.7)]:
            out.append(polyline([(sgn * x1, y1), (sgn * x2, y2), (sgn * (x2 + 0.05), y2 - 0.13)], 0.05))
    return U(*out)


def _crab_build():
    return U(oval(0, -0.12, 0.56, 0.38), _crab_claw(-1), _crab_claw(1), _crab_legs())


@sticker("ocean", "crab", "Crab", ["#F0412E", "#B8271A", "#FFFFFF", "#1A1410"], ink=1.0)
def _():
    body = _crab_build()
    shade = _rim(_crab_build, -0.1, 0.1)
    eyes = U(circle(-0.17, 0.3, 0.1), circle(0.17, 0.3, 0.1), seg(-0.17, 0.2, -0.17, 0.3, 0.05), seg(0.17, 0.2, 0.17, 0.3, 0.05))
    details = U(circle(-0.17, 0.3, 0.045), circle(0.17, 0.3, 0.045), arc(0, -0.1, 0.16, math.radians(215), math.radians(325), 0.03))
    return [body, shade, eyes, details]


def _puffer_build():
    return U(circle(-0.1, 0.0, 0.52), star(-0.1, 0.0, 9, 0.74, 0.46) - 0.03,
             poly([(0.34, 0.0), (0.92, 0.46), (0.8, 0.0), (0.92, -0.46)]) - 0.03,
             poly([(-0.2, -0.36), (0.1, -0.66), (0.1, -0.3)]) - 0.03)


@sticker("ocean", "puffer", "Pufferfish", ["#6FD6B8", "#35A68A", "#FFFFFF", "#FFF4C7"], ink=1.0)
def _():
    body = _puffer_build()
    shade = _rim(_puffer_build, -0.1, 0.1)
    belly = inter(circle(-0.1, 0.0, 0.5), Y + 0.14)
    eye = sub(circle(-0.36, 0.14, 0.17), circle(-0.4, 0.14, 0.085))
    return [body, shade, eye, belly]


def _coral_build():
    return U(brush([(0, -0.5), (0.02, -0.1), (-0.04, 0.3), (0.0, 0.78)], [0.2, 0.17, 0.15, 0.13]),
             brush([(-0.05, -0.35), (-0.3, -0.1), (-0.52, 0.0), (-0.62, 0.38)], [0.16, 0.15, 0.13, 0.12]),
             brush([(0.05, -0.3), (0.3, -0.05), (0.5, 0.15), (0.64, 0.5)], [0.16, 0.15, 0.13, 0.12]),
             brush([(-0.02, 0.1), (-0.26, 0.3), (-0.3, 0.55)], [0.12, 0.11, 0.11]))


@sticker("ocean", "coral", "Coral", ["#FF6F91", "#D23F6B", "#FFD1DC", "#8A5A33"], ink=1.0)
def _():
    coral = _coral_build()
    shade = _rim(_coral_build, -0.1, 0.08)
    tips = U(circle(0.0, 0.78, 0.09), circle(-0.62, 0.38, 0.085), circle(0.64, 0.5, 0.085), circle(-0.3, 0.55, 0.075))
    rock = U(ellipse(0, -0.74, 0.7, 0.22), circle(-0.44, -0.62, 0.2), circle(0.42, -0.64, 0.21))
    return [coral, shade, tips, rock]


@sticker("ocean", "bottle", "Message bottle", ["#7FD8E8", "#FFE08A", "#C98B4B", "#FFFFFF"], ink=1.0)
def _():
    with rotated(-0.7, 0, 0):
        glass = U(box(0, -0.2, 0.38, 0.62, 0.2), box(0, 0.58, 0.15, 0.28, 0.03))
        paper = box(0.0, -0.12, 0.2, 0.46, 0.08)
        cork = box(0, 0.9, 0.16, 0.12, 0.04)
        shine = U(seg(-0.28, -0.46, -0.28, 0.1, 0.045), circle(-0.28, 0.28, 0.045))
    return [glass, paper, cork, shine]


def _dolphin_build():
    trunk = brush([(-0.66, -0.52), (-0.38, -0.1), (0.0, 0.26), (0.38, 0.34), (0.6, 0.2)], [0.05, 0.17, 0.27, 0.25, 0.17])
    beak = taper(0.6, 0.22, 0.9, 0.08, 0.13, 0.05)
    dorsal = poly([(-0.12, 0.42), (0.06, 0.72), (0.2, 0.46)])
    flukes = U(poly([(-0.66, -0.52), (-0.98, -0.5), (-0.86, -0.7)]), poly([(-0.66, -0.52), (-0.92, -0.2), (-0.86, -0.4)]))
    flipper = poly([(0.12, 0.05), (0.2, -0.3), (0.34, -0.02)])
    return smin(U(trunk, beak, dorsal, flukes, flipper), trunk, 0.05)


@sticker("ocean", "dolphin", "Dolphin", ["#4A90D9", "#CFE9FF", "#1A1410", "#4FC3F7"], ink=1.0)
def _():
    body = _dolphin_build()
    belly = _rim(_dolphin_build, -0.13, 0.15)
    eye = U(circle(0.55, 0.3, 0.055), arc(0.74, 0.1, 0.1, math.radians(250), math.radians(320), 0.03))
    water = U(box(0.0, -0.84, 0.95, 0.12, 0.08), circle(-0.4, -0.74, 0.17), circle(0.5, -0.74, 0.17), circle(0.92, -0.55, 0.07))
    return [body, belly, eye, water]


def _chest_build():
    return U(box(0, -0.33, 0.8, 0.38, 0.08), inter(box(0, 0.3, 0.8, 0.34, 0.3), -Y))


@sticker("ocean", "chest", "Treasure chest", ["#B8672A", "#7A3E14", "#FFC531", "#FFFFFF"], ink=1.0)
def _():
    wood = _chest_build()
    shade = _rim(_chest_build, -0.1, 0.1)
    plate = sub(box(0, -0.1, 0.13, 0.18, 0.04), U(circle(0, -0.06, 0.04), box(0, -0.14, 0.02, 0.06)))
    gold = U(inter(U(box(-0.52, 0, 0.09, 0.78), box(0.52, 0, 0.09, 0.78)), wood), plate, box(0, 0.0, 0.8, 0.03))
    shine = U(seg(-0.6, 0.5, -0.4, 0.62, 0.045), circle(-0.7, 0.36, 0.04))
    return [wood, shade, gold, shine]


@sticker("ocean", "ahoy", "Ahoy", ["#1FA2E8", "#0B6DB8", "#FFFFFF", "#FFC531"], ink=1.0)
def _():
    ribbon = U(box(0, 0.0, 0.72, 0.42, 0.07), poly([(-0.66, -0.26), (-0.98, -0.26), (-0.84, 0.0), (-0.98, 0.26), (-0.66, 0.26)]),
               poly([(0.66, -0.26), (0.98, -0.26), (0.84, 0.0), (0.98, 0.26), (0.66, 0.26)]))
    shade = _lowr(ribbon, 0.2)
    word = text("AHOY", 0.0, 0.0, 0.5, maxw=1.3)
    stars = U(star(-0.6, 0.6, 5, 0.17, 0.07), star(0.6, 0.6, 5, 0.17, 0.07), star(0.0, 0.7, 5, 0.2, 0.08))
    return [ribbon, shade, word, stars]
