# Tattoo Flash — old-school sailor flash, no people. Run by Tools/decor_stickers.py (every helper is in scope).
PACK = ("tattoo", "Tattoo Flash", False)
PRO_IDS = {"panther", "ship", "sacred", "skullroses", "eagle", "swallow"}


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


def _leaf(ax, ay, bx, by, w):
    """A pointed leaf from (ax, ay) to (bx, by), w = half-width at the middle (two circles' lens)."""
    mx, my = (ax + bx) / 2, (ay + by) / 2
    L = math.hypot(bx - ax, by - ay) / 2
    r = (L * L + w * w) / (2 * w)
    nx, ny = -(by - ay) / (2 * L), (bx - ax) / (2 * L)
    return inter(circle(mx + nx * (r - w), my + ny * (r - w), r), circle(mx - nx * (r - w), my - ny * (r - w), r))


def _rose(cx, cy, r):
    """A flash rose seen from above: (bloom, folds) — scalloped bloom and the dark spiral of its petals."""
    bloom = U(circle(cx, cy, r * 0.82), *[circle(cx + r * 0.42 * math.cos(a), cy + r * 0.42 * math.sin(a), r * 0.56)
                                          for a in [math.pi / 2 + k * 2 * math.pi / 5 for k in range(5)]])
    folds = U(arc(cx, cy, r * 0.22, 0.3, 4.2, r * 0.07), arc(cx + r * 0.04, cy - r * 0.02, r * 0.5, 3.4, 6.0, r * 0.075),
              arc(cx - r * 0.04, cy + r * 0.04, r * 0.5, 0.2, 2.6, r * 0.075))
    return bloom, folds


def _banner(cx, cy, hw, hh, tail=0.16):
    """A flash ribbon: a band with notched tails folding back at both ends."""
    band = box(cx, cy, hw, hh, 0.02)
    ends = U(poly([(cx - hw + 0.04, cy - hh * 0.4), (cx - hw - tail, cy - hh * 0.4), (cx - hw - tail + 0.08, cy - hh * 1.4),
                   (cx - hw - tail, cy - hh * 2.4), (cx - hw + 0.04, cy - hh * 2.4)]),
             poly([(cx + hw - 0.04, cy - hh * 0.4), (cx + hw + tail, cy - hh * 0.4), (cx + hw + tail - 0.08, cy - hh * 1.4),
                   (cx + hw + tail, cy - hh * 2.4), (cx + hw - 0.04, cy - hh * 2.4)]))
    return band, ends


@sticker("tattoo", "swallow", "Swallow", ["#1E3A6E", "#F4EEDC", "#D7262B", "#FFFFFF"], ink=1.0)
def _():
    with rotated(0.32):
        body = U(oval(0.02, 0.0, 0.42, 0.2), circle(0.42, 0.05, 0.19), poly([(0.56, 0.12), (0.8, 0.02), (0.56, -0.04)]))
        tail = U(taper(-0.3, 0.02, -0.88, 0.26, 0.11, 0.02), taper(-0.3, -0.02, -0.86, -0.22, 0.11, 0.02))
        wings = U(brush([(0.1, 0.12), (-0.05, 0.48), (-0.42, 0.82)], [0.18, 0.15, 0.03]),
                  brush([(0.12, -0.1), (0.26, -0.48), (0.1, -0.86)], [0.16, 0.13, 0.03]))
        bird = U(body, tail, wings)
        belly = inter(U(oval(0.02, -0.06, 0.38, 0.14), circle(0.42, -0.04, 0.12)), box(0.1, -0.5, 1.0, 0.5))
        throat = U(circle(0.5, 0.0, 0.09), oval(0.36, -0.06, 0.12, 0.08))
        shine = U(circle(0.44, 0.13, 0.045), brush([(0.04, 0.3), (-0.12, 0.56)], [0.035, 0.02]))
    return [bird, belly, throat, shine]


@sticker("tattoo", "anchor", "Anchor", ["#2F6FB0", "#1C4A80", "#E2B66B", "#FFFFFF"], ink=1.0)
def _():
    ring_ = ring(0, 0.72, 0.13, 0.055)
    stock = U(box(0, 0.47, 0.4, 0.065, 0.05), circle(-0.43, 0.47, 0.085), circle(0.43, 0.47, 0.085))
    shank = box(0, -0.05, 0.075, 0.56, 0.03)
    arms = arc(0, -0.12, 0.56, math.radians(198), math.radians(342), 0.075)
    flukes = U(poly([(-0.53, -0.3), (-0.72, -0.1), (-0.4, -0.06)]), poly([(0.53, -0.3), (0.72, -0.1), (0.4, -0.06)]),
               poly([(-0.14, -0.62), (0.14, -0.62), (0, -0.82)]))
    anchor = U(ring_, stock, shank, arms, flukes)
    shade = _rim(anchor, 0.07)
    rope = brush([(-0.36, 0.3), (0.24, 0.12), (-0.24, -0.12), (0.22, -0.36), (-0.04, -0.52)], [0.07] * 5)
    shine = U(seg(-0.03, 0.34, -0.03, -0.5, 0.022), arc(0, 0.72, 0.13, math.radians(110), math.radians(170), 0.025))
    return [anchor, shade, rope, shine]


@sticker("tattoo", "dagger", "Dagger", ["#D9DEE6", "#8A93A3", "#F2C417", "#D7262B"], ink=1.0)
def _():
    with rotated(-0.785, 0.0, 0.0, 0.02, 0.0):
        blade = poly([(0, -1.14), (0.21, -0.66), (0.21, 0.1), (-0.21, 0.1), (-0.21, -0.66)])
        edge = inter(blade, box(0.5, -0.3, 0.5, 1.0))
        hilt = U(box(0, 0.19, 0.5, 0.09, 0.07), circle(-0.52, 0.19, 0.12), circle(0.52, 0.19, 0.12), circle(0, 0.96, 0.15))
        grip = U(box(0, 0.54, 0.12, 0.27, 0.06))
        dagger = U(blade, hilt, grip)
    return [dagger, edge, hilt, grip]


@sticker("tattoo", "rose", "Rose", ["#2E9E4F", "#D7262B", "#7A0E14", "#FFB3B8"], ink=1.0)
def _():
    leaves = U(_leaf(-0.18, -0.28, -0.86, -0.62, 0.2), _leaf(0.18, -0.28, 0.82, -0.7, 0.2), _leaf(0.0, -0.3, 0.1, -0.9, 0.14))
    bloom, folds = _rose(0.0, 0.14, 0.64)
    shine = U(arc(0.0, 0.14, 0.5, math.radians(120), math.radians(160), 0.04), circle(-0.3, 0.5, 0.04))
    return [leaves, bloom, folds, shine]


@sticker("tattoo", "heart", "Winged heart", ["#E8D2A8", "#D7262B", "#8E1418", "#FFFFFF"], ink=1.0)
def _():
    feathers = [[brush([(sx * 0.26, 0.24 - k * 0.13), (sx * 0.62, 0.44 - k * 0.2), (sx * 0.92, 0.64 - k * 0.27)], [0.14, 0.11, 0.04])
                 for k in range(4)] for sx in (-1, 1)]
    wings = U(*[sub(f[k], f[k + 1] - 0.03) if k < 3 else f[k] for f in feathers for k in range(4)])
    heart_ = heart(0, 0.16, 1.1)
    shade = _rim(heart_, 0.1)
    shine = U(oval(-0.3, 0.38, 0.1, 0.05, 0.6), circle(-0.16, 0.48, 0.035))
    return [wings, heart_, shade, shine]


@sticker("tattoo", "panther", "Panther", ["#2B3146", "#101216", "#D7262B", "#FFE98A"], ink=1.0)
def _():
    head = U(oval(0, 0.1, 0.62, 0.52), oval(0, -0.36, 0.42, 0.4), circle(-0.48, 0.5, 0.18), circle(0.48, 0.5, 0.18))
    shade = _rim(head, 0.11)
    mouth = U(oval(0, -0.38, 0.28, 0.3), poly([(-0.1, 0.0), (0.1, 0.0), (0, -0.12)]), circle(-0.48, 0.5, 0.08), circle(0.48, 0.5, 0.08))
    eyes = U(sub(oval(-0.27, 0.2, 0.15, 0.075, -0.35), oval(-0.27, 0.2, 0.025, 0.07)),
             sub(oval(0.27, 0.2, 0.15, 0.075, 0.35), oval(0.27, 0.2, 0.025, 0.07)))
    fangs = U(eyes, poly([(-0.2, -0.12), (-0.08, -0.12), (-0.14, -0.34)]), poly([(0.2, -0.12), (0.08, -0.12), (0.14, -0.34)]),
              poly([(-0.17, -0.64), (-0.07, -0.64), (-0.12, -0.46)]), poly([(0.17, -0.64), (0.07, -0.64), (0.12, -0.46)]),
              arc(0, 0.1, 0.5, math.radians(112), math.radians(150), 0.055), arc(-0.48, 0.5, 0.12, math.radians(100), math.radians(170), 0.04))
    return [head, shade, mouth, fangs]


@sticker("tattoo", "ship", "Clipper ship", ["#F4EEDC", "#8A4B22", "#2F6FB0", "#1E2A44"], ink=1.0)
def _():
    canvas = U(poly(spline([(-0.62, 0.66), (-0.06, 0.66), (0.0, 0.2), (-0.06, -0.12), (-0.62, -0.12), (-0.54, 0.26)], n=8)),
               poly(spline([(0.1, 0.52), (0.6, 0.52), (0.66, 0.16), (0.6, -0.12), (0.1, -0.12), (0.18, 0.2)], n=8)))
    stripe = seg(-0.66, -0.21, 0.1, -0.21, 0.03)
    sails = U(canvas, stripe)
    hull = sub(U(poly([(-0.86, -0.12), (0.86, -0.12), (0.62, -0.5), (-0.66, -0.5)]), box(-0.34, 0.32, 0.045, 0.56),
                 box(0.36, 0.26, 0.045, 0.46), poly([(-0.3, 0.88), (-0.04, 0.82), (-0.3, 0.74)])), stripe)
    waves = U(box(0, -0.68, 0.88, 0.14, 0.08), *[circle(x, -0.52, 0.13) for x in np.linspace(-0.7, 0.7, 5)])
    shade = U(_rim(canvas, 0.1), inter(hull, box(0.1, -0.44, 1.0, 0.07)),
              *[arc(x, -0.52, 0.08, math.radians(20), math.radians(160), 0.025) for x in np.linspace(-0.7, 0.7, 5)])
    return [sails, hull, waves, shade]


@sticker("tattoo", "horseshoe", "Lucky horseshoe", ["#F2C417", "#C98A10", "#16161C", "#FFFFFF"], ink=1.0)
def _():
    shoe = U(arc(0, 0.0, 0.52, math.radians(-205), math.radians(25), 0.17),
             box(-0.48, 0.24, 0.15, 0.1, 0.04, -0.4), box(0.48, 0.24, 0.15, 0.1, 0.04, 0.4))
    shade = _rim(shoe, 0.08)
    holes = U(*[box(0.52 * math.cos(math.radians(a)), 0.52 * math.sin(math.radians(a)), 0.035, 0.065, 0.02, math.radians(a))
                for a in (-170, -135, -105, -75, -45, -10)])
    sparkle = star(-0.52, 0.3, 4, 0.38, 0.13)
    return [shoe, shade, holes, sparkle]


@sticker("tattoo", "snake", "Snake", ["#2E9E4F", "#1F6B34", "#F2C417", "#D7262B"], ink=1.0)
def _():
    path = [(-0.3, -0.84), (0.36, -0.7), (0.42, -0.32), (-0.26, -0.18), (-0.42, 0.18), (0.0, 0.36), (0.22, 0.44)]
    coil = brush(path, [0.04, 0.12, 0.16, 0.17, 0.16, 0.15, 0.14])
    body = U(coil, oval(0.38, 0.52, 0.28, 0.2, 0.4))
    shade = _rim(body, 0.08)
    bands = U(inter(coil, stripes(0.24, -0.5, 0.42)), circle(0.44, 0.62, 0.06))
    tongue = poly([(0.56, 0.7), (0.92, 0.88), (0.8, 0.7), (0.92, 0.56), (0.56, 0.6)]) - 0.01
    return [body, shade, bands, tongue]


@sticker("tattoo", "skullroses", "Skull and roses", ["#FFFFFF", "#EADCC0", "#D7262B", "#16161C"], ink=1.0)
def _():
    dome = circle(0, 0.26, 0.5)
    shine = U(dome, box(0, -0.12, 0.3, 0.26, 0.1))
    gleam = sub(dome, circle(0.06, 0.2, 0.48))
    skull = sub(shine, gleam)
    ra, fa = _rose(-0.48, -0.46, 0.4)
    rb, fb = _rose(0.48, -0.46, 0.4)
    roses = U(ra, rb)
    shadows = U(oval(-0.2, 0.2, 0.14, 0.16, 0.2), oval(0.2, 0.2, 0.14, 0.16, -0.2), poly([(0, 0.02), (-0.07, -0.1), (0.07, -0.1)]),
                *[box(x, -0.22, 0.02, 0.08) for x in (-0.1, 0.0, 0.1)], fa, fb, sub(_rim(dome, 0.1), U(ra, rb) - 0.02))
    return [shine, skull, roses, shadows]


@sticker("tattoo", "mom", "MOM heart", ["#D7262B", "#8E1418", "#F4EEDC", "#16161C"], ink=1.0)
def _():
    heart_ = heart(0, 0.18, 1.3)
    shade = _rim(heart_, 0.1)
    banner = U(box(0, -0.04, 0.86, 0.36, 0.06), poly([(-0.86, -0.4), (-0.7, -0.4), (-0.7, -0.52)]), poly([(0.86, -0.4), (0.7, -0.4), (0.7, -0.52)]))
    word = text("MOM", 0, -0.04, 0.6, stretch=0.74, maxw=1.5) - 0.012
    return [heart_, shade, banner, word]


@sticker("tattoo", "sacred", "Sacred heart", ["#FFE680", "#D7262B", "#FF8A00", "#7A0E14"], ink=1.0)
def _():
    rays = star(0, -0.04, 14, 0.9, 0.6, 0.0)
    whole = heart(0, -0.12, 1.0)
    heart_ = sub(whole, arc(-0.25, 0.01, 0.24, math.radians(105), math.radians(180), 0.05))
    flames = U(circle(0, 0.38, 0.14), taper(0, 0.4, 0.0, 0.84, 0.14, 0.0), taper(-0.08, 0.38, -0.22, 0.72, 0.09, 0.0),
               taper(0.08, 0.38, 0.22, 0.72, 0.09, 0.0))
    shade = sub(_rim(whole, 0.11), flames)
    return [rays, heart_, flames, shade]


@sticker("tattoo", "diamond", "Diamond", ["#E3263A", "#8E1418", "#16161C", "#FFFFFF"], ink=1.0)
def _():
    top, right, bottom, left = (0, 0.84), (0.64, 0.14), (0, -0.84), (-0.64, 0.14)
    gem = poly([top, right, bottom, left])
    shade = inter(gem, box(0.5, 0, 0.5, 1.0))
    facets = inter(U(polyline([left, right], 0.045), polyline([top, (-0.26, 0.14), bottom], 0.035), polyline([top, (0.26, 0.14), bottom], 0.035),
                     seg(0, 0.84, 0, -0.84, 0.06)), gem)
    sparkle = star(-0.34, 0.5, 4, 0.32, 0.11)
    return [gem, shade, facets, sparkle]


@sticker("tattoo", "star", "Nautical star", ["#D7262B", "#16161C", "#FFFFFF", "#FFFFFF"], ink=1.0)
def _():
    ro, ri = 0.9, 0.36
    starr = star(0, -0.04, 5, ro, ri)
    tips = [(ro * math.cos(math.pi / 2 + k * 2 * math.pi / 5), -0.04 + ro * math.sin(math.pi / 2 + k * 2 * math.pi / 5)) for k in range(5)]
    vals = [(ri * math.cos(math.pi / 2 + math.pi / 5 + k * 2 * math.pi / 5), -0.04 + ri * math.sin(math.pi / 2 + math.pi / 5 + k * 2 * math.pi / 5))
            for k in range(5)]
    points = inter(starr, U(*[poly([(0, -0.04), tips[k], vals[k]]) for k in range(5)]))
    shine = U(seg(-0.06, 0.62, -0.03, 0.32, 0.03), circle(-0.3, 0.12, 0.04))
    return [starr, points, shine]


@sticker("tattoo", "moth", "Moth", ["#C9A574", "#5A3420", "#FFE27A", "#16161C"], ink=1.0)
def _():
    fore = U(poly(spline([(-0.08, 0.3), (-0.5, 0.62), (-0.9, 0.6), (-0.8, 0.2), (-0.46, -0.06), (-0.08, -0.02)], n=8)),
             poly(spline([(0.08, 0.3), (0.5, 0.62), (0.9, 0.6), (0.8, 0.2), (0.46, -0.06), (0.08, -0.02)], n=8)))
    hind = U(oval(-0.34, -0.36, 0.3, 0.26, -0.6), oval(0.34, -0.36, 0.3, 0.26, 0.6))
    wings = U(fore, hind)
    pattern = U(inter(fore, U(circle(-0.86, 0.5, 0.3), circle(0.86, 0.5, 0.3))), _rim(wings, 0.13),
                ring(-0.5, 0.28, 0.13, 0.04), ring(0.5, 0.28, 0.13, 0.04))
    spots = U(circle(-0.5, 0.28, 0.08), circle(0.5, 0.28, 0.08), circle(-0.36, -0.38, 0.08), circle(0.36, -0.38, 0.08),
              brush([(-0.2, 0.36), (-0.42, 0.5), (-0.62, 0.55)], [0.03, 0.04, 0.025]), brush([(-0.3, -0.18), (-0.5, -0.24)], [0.03, 0.02]))
    body = U(oval(0, -0.04, 0.15, 0.5), circle(0, 0.46, 0.14), *[circle(sx * 0.1, y, 0.07) for sx in (-1, 1) for y in (0.2, -0.04, -0.28)],
             brush([(0.06, 0.56), (0.16, 0.7), (0.3, 0.76)], [0.06, 0.055, 0.07]), brush([(-0.06, 0.56), (-0.16, 0.7), (-0.3, 0.76)], [0.06, 0.055, 0.07]))
    return [wings, pattern, spots, body]


@sticker("tattoo", "eagle", "Eagle", ["#8A4B22", "#FFFFFF", "#F2C417", "#16161C"], ink=1.0)
def _():
    face = poly(spline([(-0.5, 0.14), (-0.38, 0.5), (-0.04, 0.66), (0.3, 0.58), (0.48, 0.38), (0.5, 0.14), (0.36, -0.04), (0.06, -0.14),
                        (-0.24, -0.16)], n=8))
    ruff = poly([(-0.46, 0.4), (-0.86, 0.02), (-0.62, 0.0), (-0.84, -0.38), (-0.54, -0.32), (-0.62, -0.74), (-0.26, -0.5),
                 (-0.12, -0.86), (0.06, -0.48), (0.3, -0.7), (0.28, -0.2), (0.1, -0.06)])
    feathers = U(face, ruff)
    gleam = seg(0.42, 0.33, 0.68, 0.34, 0.035)
    head = U(face, gleam)
    bill = U(poly(spline([(0.3, 0.42), (0.62, 0.44), (0.84, 0.28), (0.88, 0.04), (0.8, -0.14), (0.74, 0.04), (0.58, 0.12), (0.34, 0.1)], n=8)),
             poly([(0.34, 0.1), (0.62, 0.08), (0.54, -0.04), (0.34, -0.02)]))
    beak = sub(bill, gleam)
    marks = U(circle(0.14, 0.34, 0.065), brush([(-0.06, 0.44), (0.16, 0.47), (0.36, 0.4)], [0.035, 0.05, 0.03]),
              polyline([(0.36, 0.1), (0.6, 0.1), (0.7, 0.04)], 0.025), sub(_rim(face, 0.08), bill), sub(_rim(ruff, 0.09), face),
              *[polyline([(x - 0.09, y + 0.11), (x, y), (x + 0.09, y + 0.11)], 0.035) for x, y in [(-0.56, -0.18), (-0.3, -0.42), (0.04, -0.34)]])
    return [feathers, head, beak, marks]


@sticker("tattoo", "wheel", "Ship's wheel", ["#A0602E", "#6B3A16", "#F2C417", "#FFFFFF"], ink=1.0)
def _():
    angs = [k * math.pi / 4 + math.pi / 8 for k in range(8)]
    wheel = U(ring(0, 0, 0.5, 0.09), *[seg(0, 0, 0.84 * math.cos(a), 0.84 * math.sin(a), 0.05) for a in angs],
              *[circle(0.82 * math.cos(a), 0.82 * math.sin(a), 0.085) for a in angs])
    shade = _rim(wheel, 0.06)
    hub = U(circle(0, 0, 0.17), *[circle(0.5 * math.cos(a), 0.5 * math.sin(a), 0.055) for a in angs])
    shine = U(arc(0, 0, 0.5, math.radians(115), math.radians(150), 0.03), circle(-0.05, 0.05, 0.05))
    return [wheel, shade, hub, shine]


@sticker("tattoo", "lighthouse", "Lighthouse", ["#F4EEDC", "#D7262B", "#46546B", "#F2C417"], ink=1.0)
def _():
    tower = U(poly([(-0.24, 0.26), (0.24, 0.26), (0.34, -0.62), (-0.34, -0.62)]), box(0, 0.3, 0.3, 0.05, 0.02),
              box(0, 0.44, 0.16, 0.12, 0.02), poly([(-0.22, 0.56), (0.22, 0.56), (0, 0.78)]))
    bands = U(inter(tower, U(box(0, 0.06, 0.5, 0.1), box(0, -0.36, 0.5, 0.1))), poly([(-0.22, 0.56), (0.22, 0.56), (0, 0.78)]),
              box(0, 0.3, 0.3, 0.05, 0.02))
    shade = U(oval(-0.26, -0.72, 0.5, 0.18), oval(0.3, -0.74, 0.46, 0.16), oval(0.0, -0.62, 0.36, 0.16),
              inter(poly([(-0.24, 0.26), (0.24, 0.26), (0.34, -0.62), (-0.34, -0.62)]), poly([(0.12, 0.3), (0.4, 0.3), (0.4, -0.7), (0.18, -0.7)])))
    light = U(box(0, 0.44, 0.1, 0.08, 0.02), poly([(-0.1, 0.48), (-0.9, 0.7), (-0.9, 0.3), (-0.1, 0.4)]),
              poly([(0.1, 0.48), (0.9, 0.7), (0.9, 0.3), (0.1, 0.4)]))
    return [tower, bands, shade, light]