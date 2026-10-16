# Festival — three days in a field: tents, wristbands, mud and a sunrise. Run by Tools/decor_stickers.py (every helper is
# in scope).
PACK = ("festival", "Festival", False)
PRO_IDS = {"stage", "ferris", "van", "crown", "confetti", "lantern"}


def _moved(d, dx, dy):
    """Layer d slid by (dx, dy) slice units (y up); what slides in from the edge is far outside."""
    px, py = int(round(dx * N / 2)), int(round(dy * N / 2))
    out = np.full_like(d, BIG)
    h, w = d.shape
    rs, rd = (slice(py, h), slice(0, h - py)) if py >= 0 else (slice(0, h + py), slice(-py, h))
    cs, cd = (slice(0, w - px), slice(px, w)) if px >= 0 else (slice(-px, w), slice(0, w + px))
    out[rd, cd] = d[rs, cs]
    return out


def _rim(d, k=0.09):
    """The lower-right rim of d: d minus itself slid up-left — the house shade."""
    return sub(d, _moved(d, -k, k))


def _leaf_(cx, cy):
    """A small leaf poking out of the crown's vine."""
    return oval(cx, cy, 0.12, 0.06, math.atan2(cy, cx))


def _qcurve(p0, p1, p2, n=24):
    """Points along a quadratic curve p0 -> p2 pulled toward p1 (a crisp-cornered outline when joined with poly())."""
    return [((1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0], (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1])
            for t in np.linspace(0, 1, n)]


def _daisy(cx, cy, r):
    """A little five-petal flower: (petals, center)."""
    return petals(cx, cy, 5, r * 0.55, r * 0.5, r * 0.32, math.pi / 2), circle(cx, cy, r * 0.32)


@sticker("festival", "wristband", "Wristband", ["#FFC9A0", "#E09A6A", "#FF2D9B", "#FFE14A"], ink=1.0)
def _():
    with rotated(-0.7, 0.0, 0.0, 0.02, -0.02):
        knuckles = [box(x, 0.56, 0.1, 0.13, 0.095) for x in (-0.255, -0.085, 0.085, 0.255)]
        fist = U(box(0, 0.32, 0.36, 0.24, 0.14), *[sub(knuckles[k], knuckles[k + 1] - 0.03) if k < 3 else knuckles[k] for k in range(4)],
                 sub(box(-0.05, 0.24, 0.27, 0.08, 0.08), box(-0.05, 0.37, 0.36, 0.035)))
        arm = box(0, -0.42, 0.27, 0.46, 0.08)
        hand = U(fist, arm)
        cuff = box(0, -0.22, 0.34, 0.2, 0.06)
        band = U(cuff, taper(0.26, -0.3, 0.56, -0.5, 0.09, 0.08), taper(0.26, -0.36, 0.46, -0.66, 0.09, 0.08))
        pattern = U(inter(cuff, stripes(0.28, 1.1, 0.36)), box(0.24, -0.22, 0.11, 0.14, 0.04))
    shade = sub(_rim(hand, 0.09), band)
    return [hand, shade, band, pattern]


@sticker("festival", "tent", "Tent", ["#FF8A1F", "#D9620A", "#2B2E33", "#FFFFFF"], ink=1.0)
def _():
    tent = poly(spline([(-0.88, -0.56), (-0.5, 0.06), (-0.06, 0.66), (0.06, 0.66), (0.5, 0.06), (0.88, -0.56)], closed=True, n=6))
    shade = inter(tent, box(0.55, 0, 0.5, 1.0))
    door = poly([(-0.3, -0.56), (0.0, 0.3), (0.3, -0.56)])
    trim = U(polyline([(-0.3, -0.56), (0.0, 0.3), (0.3, -0.56)], 0.035), seg(0, 0.62, 0, 0.82, 0.04), star(0.0, 0.84, 4, 0.1, 0.03),
             box(0, -0.62, 0.9, 0.05, 0.03), seg(-0.4, 0.2, -0.26, 0.4, 0.035))
    return [tent, shade, door, trim]


@sticker("festival", "stage", "Main stage", ["#C9A8FF", "#8B3DFF", "#FFE680", "#2B2E33"], ink=1.0)
def _():
    backdrop = box(0, 0.12, 0.7, 0.5, 0.02)
    deck = box(0, -0.62, 0.9, 0.24, 0.04)
    beams = U(*[poly([(x - 0.04, 0.5), (x + 0.04, 0.5), (x + 0.14, -0.38), (x - 0.14, -0.38)]) for x in (-0.28, 0.0, 0.28)],
              *[circle(x, 0.5, 0.07) for x in (-0.28, 0.0, 0.28)], *[oval(x, -0.44, 0.17, 0.07) for x in (-0.28, 0.0, 0.28)])
    cabs = U(*[box(sx * 0.62, y, 0.17, 0.14, 0.03) for sx in (-1, 1) for y in (-0.24, 0.06)])
    cones = U(*[circle(sx * 0.62, y, 0.08) for sx in (-1, 1) for y in (-0.24, 0.06)])
    truss = U(box(0, 0.64, 0.84, 0.08, 0.02), box(-0.8, 0.14, 0.07, 0.52, 0.02), box(0.8, 0.14, 0.07, 0.52, 0.02),
              sub(cabs, cones), inter(deck, box(0, -0.74, 1.0, 0.12)))
    return [backdrop, deck, beams, truss]


@sticker("festival", "ferris", "Ferris wheel", ["#3A3F47", "#2EC4B6", "#FF3D9A", "#FFD400"], ink=1.0)
def _():
    cx, cy, r = 0.0, 0.18, 0.54
    legs = U(seg(cx, cy, -0.5, -0.78, 0.1), seg(cx, cy, 0.5, -0.78, 0.1), box(0, -0.8, 0.66, 0.08, 0.04))
    angs = [math.pi / 2 + k * math.pi / 3 for k in range(6)]
    wheel = U(ring(cx, cy, r, 0.075), *[seg(cx, cy, cx + r * math.cos(a), cy + r * math.sin(a), 0.06) for a in angs])
    cars = U(*[box(cx + r * math.cos(a), cy + r * math.sin(a) - 0.1, 0.13, 0.11, 0.05) for a in angs])
    hub = U(circle(cx, cy, 0.13), arc(cx, cy, r, math.radians(115), math.radians(150), 0.03))
    return [legs, wheel, cars, hub]


@sticker("festival", "flag", "Festival flag", ["#8A8F98", "#2EC4B6", "#1B7F78", "#FFD400"], ink=1.0)
def _():
    pole = U(seg(-0.5, -0.86, -0.5, 0.86, 0.05), seg(-0.5, -0.86, -0.72, -0.86, 0.045), seg(-0.5, -0.86, -0.28, -0.86, 0.045))
    flag = poly(_qcurve((-0.46, 0.82), (0.2, 0.86), (0.86, 0.32)) + _qcurve((0.86, 0.32), (0.2, 0.02), (-0.46, -0.18))[1:])
    shade = _rim(flag, 0.1)
    stripe = U(inter(flag, stripes(0.42, -1.2, 0.3, 0.06)), star(-0.06, 0.34, 5, 0.17, 0.075))
    return [pole, flag, shade, stripe]


@sticker("festival", "glowstick", "Glow stick", ["#C8FFB0", "#39E75F", "#FFFFFF", "#2B2E33"], ink=1.0)
def _():
    with rotated(0.75):
        stick = box(0, 0, 0.13, 0.66, 0.13)
        core = seg(-0.04, 0.48, -0.04, -0.4, 0.035)
        caps = U(box(0, 0.7, 0.1, 0.06, 0.03), box(0, -0.7, 0.1, 0.06, 0.03))
    glow = U(stick - 0.17, star(-0.5, 0.5, 4, 0.26, 0.07), star(0.56, -0.46, 4, 0.22, 0.06))
    return [glow, stick, core, caps]


@sticker("festival", "chair", "Camping chair", ["#2B2E33", "#2E9E4F", "#1F6B34", "#E3172F"], ink=1.0)
def _():
    frame = U(seg(-0.6, -0.24, 0.6, -0.84, 0.05), seg(0.6, -0.24, -0.6, -0.84, 0.05), seg(-0.68, 0.02, -0.68, -0.84, 0.05),
              seg(0.68, 0.02, 0.68, -0.84, 0.05), box(-0.66, 0.02, 0.16, 0.05, 0.03), box(0.66, 0.02, 0.16, 0.05, 0.03),
              seg(-0.5, -0.04, -0.5, 0.8, 0.045), seg(0.5, -0.04, 0.5, 0.8, 0.045))
    fabric = U(box(0, 0.4, 0.5, 0.36, 0.05), poly([(-0.54, -0.02), (0.54, -0.02), (0.62, -0.26), (-0.62, -0.26)]))
    shade = U(inter(fabric, box(0, -0.2, 0.7, 0.08)), inter(_rim(box(0, 0.4, 0.5, 0.36, 0.05), 0.08), box(0, 0.4, 0.5, 0.36, 0.05)),
              seg(-0.3, 0.7, -0.3, 0.1, 0.03), seg(0.3, 0.7, 0.3, 0.1, 0.03))
    cup = U(poly([(0.6, 0.06), (0.8, 0.06), (0.77, 0.32), (0.63, 0.32)]), box(0.7, 0.33, 0.1, 0.03, 0.01))
    return [frame, fabric, shade, cup]


@sticker("festival", "van", "Camper van", ["#2EC4B6", "#F4F1EA", "#7FD6FF", "#2B2E33"], ink=1.0)
def _():
    body = U(box(0, -0.04, 0.86, 0.38, 0.16), box(-0.1, 0.4, 0.6, 0.1, 0.06))
    roof = U(inter(body, box(0, 0.4, 1.0, 0.4)), poly([(-0.68, 0.48), (0.48, 0.48), (0.4, 0.62), (-0.6, 0.62)]),
             seg(-0.7, -0.08, -0.3, -0.08, 0.03))
    glass = U(box(0.62, 0.14, 0.16, 0.13, 0.05), *[box(x, 0.14, 0.14, 0.12, 0.04) for x in (-0.6, -0.26, 0.08)])
    wheels = U(circle(-0.5, -0.44, 0.19), circle(0.5, -0.44, 0.19), box(0.22, -0.12, 0.024, 0.18), box(0.84, -0.18, 0.04, 0.05, 0.02),
               inter(_rim(body, 0.07), box(0, -0.3, 1.0, 0.3)))
    return [body, roof, glass, wheels]


@sticker("festival", "lanyard", "VIP lanyard", ["#8B3DFF", "#F4F1EA", "#FF3D9A", "#1A1C22"], ink=1.0)
def _():
    card = box(0, -0.42, 0.46, 0.46, 0.08)
    strap = U(brush([(-0.62, 0.9), (-0.36, 0.5), (-0.06, 0.18)], [0.09, 0.09, 0.08]), brush([(0.62, 0.9), (0.36, 0.5), (0.06, 0.18)], [0.09, 0.09, 0.08]),
              box(0, 0.12, 0.08, 0.1, 0.03), inter(_rim(card, 0.07), card))
    glint = seg(-0.34, -0.04, -0.12, -0.04, 0.03)
    band = sub(inter(card, box(0, -0.06, 0.5, 0.12)), glint)
    word = U(text("VIP", 0, -0.48, 0.3, maxw=0.8), box(0, 0.0, 0.1, 0.03, 0.015))
    return [strap, card, band, word]


@sticker("festival", "sunrise", "Sunrise", ["#FFE680", "#FF9F1C", "#3CBF5A", "#5A2A10"], ink=1.0)
def _():
    rays = U(*[poly([(0, -0.16), (0.8 * math.cos(a - 0.17), -0.16 + 0.8 * math.sin(a - 0.17)), (0.8 * math.cos(a + 0.17), -0.16 + 0.8 * math.sin(a + 0.17))])
               for a in [math.pi * (0.16 + 0.17 * k) for k in range(5)]])
    sun = circle(0, -0.16, 0.44)
    hills = U(box(0, -0.68, 0.94, 0.2, 0.0), oval(-0.5, -0.46, 0.46, 0.16), oval(0.44, -0.5, 0.5, 0.14))
    face = U(arc(-0.16, 0.0, 0.08, math.radians(20), math.radians(160), 0.035), arc(0.16, 0.0, 0.08, math.radians(20), math.radians(160), 0.035),
             arc(0.0, -0.14, 0.16, math.radians(200), math.radians(340), 0.04), inter(_rim(hills, 0.08), box(0.4, -0.8, 0.5, 0.1)))
    return [rays, sun, hills, face]


@sticker("festival", "boot", "Rubber boot", ["#FFD400", "#D9A800", "#2B2E33", "#7A4A24"], ink=1.0)
def _():
    boot = U(box(-0.16, 0.18, 0.32, 0.6, 0.08), poly(spline([(-0.48, -0.1), (-0.48, -0.56), (0.62, -0.56), (0.66, -0.34), (0.4, -0.2),
                                                               (0.12, -0.14), (0.16, -0.1)], closed=True, n=6)))
    shade = U(inter(boot, box(0.1, 0.18, 0.06, 0.62)), _rim(boot, 0.08))
    sole = U(box(0.07, -0.62, 0.6, 0.08, 0.05), box(-0.16, 0.74, 0.34, 0.07, 0.04))
    mud = U(oval(0.0, -0.74, 0.8, 0.12), circle(-0.6, -0.58, 0.1), circle(0.68, -0.6, 0.09), circle(0.5, -0.4, 0.07),
            circle(-0.3, -0.36, 0.08))
    return [boot, shade, sole, mud]


@sticker("festival", "crown", "Flower crown", ["#3CBF5A", "#FF6FB5", "#FFD400", "#FFFFFF"], ink=1.0)
def _():
    spots = [(-0.5, -0.1, 0.28), (0.0, -0.18, 0.36), (0.5, -0.1, 0.28)]
    vine = U(shell(oval(0, 0.08, 0.62, 0.3), 0.1), oval(-0.27, -0.24, 0.14, 0.07, -0.5), oval(0.27, -0.24, 0.14, 0.07, 0.5),
             oval(-0.3, 0.44, 0.13, 0.06, 0.3), oval(0.3, 0.44, 0.13, 0.06, -0.3))
    blossoms = U(*[U(petals(x, y, 5, r * 0.4, r * 0.56, r * 0.42, math.pi / 2), circle(x, y, r * 0.55)) for x, y, r in spots])
    centers = U(*[circle(x, y, r * 0.36) for x, y, r in spots])
    shine = U(*[circle(x - r * 0.42, y + r * 0.5, 0.045) for x, y, r in spots])
    return [vine, blossoms, centers, shine]


@sticker("festival", "lantern", "Paper lantern", ["#FF5A3D", "#C2311B", "#2B2E33", "#FFE680"], ink=1.0)
def _():
    lantern = oval(0, -0.04, 0.64, 0.56)
    ribs = U(_rim(lantern, 0.1), *[inter(lantern, shell(oval(0, -0.04, rx, 0.56), 0.022)) for rx in (0.22, 0.44)])
    caps = U(box(0, 0.54, 0.24, 0.07, 0.03), box(0, -0.62, 0.24, 0.07, 0.03), seg(0, 0.6, 0, 0.88, 0.035),
             taper(0, -0.66, 0, -0.9, 0.05, 0.08))
    glow = U(oval(-0.06, 0.02, 0.18, 0.24), arc(0, -0.04, 0.5, math.radians(130), math.radians(170), 0.045))
    return [lantern, ribs, caps, glow]


@sticker("festival", "confetti", "Confetti popper", ["#FFE680", "#8B3DFF", "#FF3D9A", "#2EC4B6"], ink=1.0)
def _():
    burst = star(0.28, 0.3, 11, 0.6, 0.36, 0.3)
    cone = poly([(-0.84, -0.84), (-0.24, 0.0), (0.0, -0.26)]) - 0.03
    confetti = U(box(0.1, 0.5, 0.11, 0.055, 0.02, 0.6), box(0.5, 0.18, 0.11, 0.055, 0.02, -0.4), circle(0.34, 0.6, 0.075),
             brush([(0.42, 0.42), (0.56, 0.5), (0.62, 0.66)], [0.045, 0.045, 0.04]), circle(0.66, 0.06, 0.065))
    streamers = U(inter(cone, stripes(0.26, 0.8, 0.4)), box(0.28, 0.32, 0.11, 0.055, 0.02, -0.9), circle(0.06, 0.24, 0.07),
             brush([(-0.04, 0.5), (-0.1, 0.62), (0.02, 0.72)], [0.045, 0.045, 0.04]), circle(0.62, -0.18, 0.06))
    return [burst, cone, confetti, streamers]


@sticker("festival", "bottle", "Water bottle", ["#4FC3FF", "#2A8AC0", "#2B2E33", "#FFFFFF"], ink=1.0)
def _():
    bottle = box(0, -0.18, 0.38, 0.64, 0.16)
    shade = _rim(bottle, 0.1)
    cap = U(box(0, 0.54, 0.26, 0.1, 0.05), ring(0.0, 0.76, 0.13, 0.05), box(0, 0.44, 0.3, 0.04, 0.02))
    shine = U(seg(-0.22, 0.24, -0.22, -0.56, 0.045), heart(0.08, -0.16, 0.36))
    return [bottle, shade, cap, shine]


@sticker("festival", "live", "LIVE", ["#FF3D9A", "#1A1C22", "#FFD400", "#FFFFFF"], ink=1.0)
def _():
    slab = poly([(-0.68, 0.42), (0.86, 0.42), (0.68, -0.42), (-0.86, -0.42)])
    word = text("LIVE", 0, 0.0, 0.52, maxw=1.36) - 0.012
    shadow = _moved(word, 0.05, -0.05) - 0.02
    stripes_ = U(inter(slab, box(0, 0.36, 1.0, 0.04)), inter(slab, box(0, -0.36, 1.0, 0.04)))
    return [slab, shadow, word, stripes_]


@sticker("festival", "ticket", "Ticket", ["#FF6FB5", "#D93A86", "#FFD400", "#FFFFFF"], ink=1.0)
def _():
    with rotated(-0.24):
        body = sub(box(0, 0, 0.88, 0.46, 0.06), U(circle(-0.88, 0, 0.12), circle(0.88, 0, 0.12)))
        stub = inter(body, box(0.66, 0, 0.3, 0.6))
        dashes = U(*[box(0.36, y, 0.02, 0.04, 0.015) for y in (-0.32, -0.16, 0.0, 0.16, 0.32)], seg(-0.7, 0.3, -0.3, 0.3, 0.035))
    starr = star(-0.2, 0.0, 5, 0.3, 0.13, math.pi / 2 - 0.24)
    return [body, stub, starr, dashes]


@sticker("festival", "outhouse", "Outhouse", ["#2F6FE0", "#8DB8FF", "#F4F1EA", "#FFD400"], ink=1.0)
def _():
    booth = U(box(0, -0.18, 0.5, 0.66, 0.03), box(0, 0.54, 0.6, 0.08, 0.02), box(0.32, 0.7, 0.09, 0.08, 0.01))
    door = box(-0.04, -0.22, 0.32, 0.56, 0.03)
    roof = U(box(0, 0.54, 0.6, 0.08, 0.02), box(0.32, 0.7, 0.09, 0.08, 0.01), box(0.18, -0.22, 0.04, 0.1, 0.02))
    moon = crescent(-0.06, 0.14, 0.15, 0.07, 0.04, 0.13)
    return [booth, door, roof, moon]