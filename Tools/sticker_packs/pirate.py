# Pirates — a ship, a map, gold and a flag with crossed drumsticks. Every piece has the house shade (lower-right) and
# highlight (upper-left). Run by Tools/decor_stickers.py (every helper is in scope).
PACK = ("pirate", "Pirates", False)
PRO_IDS = {"ship", "chest", "flag", "cannon", "lantern", "serpent"}


def _moved(d, dx, dy):
    """Layer d slid by (dx, dy) slice units (y up); what slides in from the edge is far outside."""
    px, py = int(round(dx * N / 2)), int(round(dy * N / 2))
    out = np.full_like(d, BIG)
    h, w = d.shape
    rs, rd = (slice(py, h), slice(0, h - py)) if py >= 0 else (slice(0, h + py), slice(-py, h))
    cs, cd = (slice(0, w - px), slice(px, w)) if px >= 0 else (slice(-px, w), slice(0, w + px))
    out[rd, cd] = d[rs, cs]
    return out


def _lr(d, k=0.09):
    """The house shade: the lower-right rim of d."""
    return sub(d, _moved(d, -k, k))


def _hl(d, k=0.075, cut=0.45):
    """The house highlight: the upper-left rim of d, kept only in the upper-left corner."""
    s = d + 0.05
    return inter(sub(s, _moved(s, k, -k)), X * 0.8 - Y * 0.8 + cut)


@sticker("pirate", "ship", "Pirate ship", ["#8A5A2B", "#F4EAD0", "#4E2F12", "#FFE7B8"], ink=1.0)
def _():
    hull = U(poly([(-0.9, -0.18), (0.9, -0.18), (0.64, -0.66), (-0.6, -0.66)]) - 0.03, seg(0.04, -0.2, 0.04, 0.9, 0.05), poly([(0.04, 0.9), (0.4, 0.8), (0.04, 0.68)]))
    sails = U(poly([(-0.52, 0.76), (0.0, 0.76), (0.0, -0.08), (-0.54, -0.08), (-0.6, 0.3)]),
              poly([(0.09, 0.76), (0.56, 0.5), (0.56, -0.08), (0.09, -0.08)]))
    shade = U(_lr(hull, 0.1), _lr(sails, 0.08))
    shine = U(_hl(hull, 0.08, 0.7), _hl(sails, 0.07, 0.55))
    return [hull, sails, shade, shine]


@sticker("pirate", "map", "Treasure map", ["#F1DFAE", "#C9AA66", "#FFF8E0", "#C21E1E"], ink=1.0)
def _():
    sheet = poly(spline([(-0.84, 0.74), (-0.3, 0.8), (0.3, 0.72), (0.84, 0.78), (0.78, 0.2), (0.86, -0.3), (0.8, -0.78), (0.3, -0.72),
                         (-0.3, -0.8), (-0.84, -0.72), (-0.76, -0.2), (-0.86, 0.2)], closed=True, n=6))
    shade = _lr(sheet, 0.1)
    shine = _hl(sheet, 0.08, 0.5)
    mark = U(seg(-0.26, 0.14, 0.26, -0.38, 0.08), seg(0.26, 0.14, -0.26, -0.38, 0.08),
             polyline([(-0.64, 0.52), (-0.42, 0.36), (-0.52, 0.04), (-0.62, -0.3)], 0.045),
             polyline([(0.3, 0.56), (0.6, 0.42), (0.54, 0.18)], 0.045))
    return [sheet, shade, shine, mark]


@sticker("pirate", "chest", "Treasure chest", ["#9A5B22", "#FFD84A", "#5E3410", "#FFF3B0"], ink=1.0)
def _():
    chest = U(box(0, -0.42, 0.78, 0.36, 0.08), box(0, 0.42, 0.7, 0.24, 0.1))
    heap = U(circle(-0.4, 0.02, 0.24), circle(0.4, 0.02, 0.24), circle(0.0, 0.14, 0.32), circle(-0.22, 0.34, 0.2), circle(0.22, 0.32, 0.2))
    gold = U(heap, box(-0.42, -0.42, 0.07, 0.36, 0.02), box(0.42, -0.42, 0.07, 0.36, 0.02), box(0, -0.3, 0.14, 0.16, 0.04))
    shade = U(_lr(chest, 0.1), _lr(heap, 0.08))
    shine = U(_hl(chest, 0.08, 0.6), _hl(heap, 0.07, 0.3))
    return [chest, gold, shade, shine]


@sticker("pirate", "flag", "Drum flag", ["#1E1E2E", "#0A0A14", "#6A6A90", "#F4F1EA"], ink=1.0)
def _():
    cloth = U(poly(spline([(-0.7, 0.8), (-0.2, 0.86), (0.4, 0.76), (0.88, 0.82), (0.8, 0.0), (0.88, -0.7), (0.4, -0.64), (-0.2, -0.74),
                           (-0.7, -0.66)], closed=True, n=6)), seg(-0.78, -0.88, -0.78, 0.88, 0.05))
    skull = U(circle(0.08, 0.3, 0.3), box(0.08, 0.06, 0.17, 0.12, 0.05))
    holes = U(circle(-0.04, 0.32, 0.085), circle(0.2, 0.32, 0.085), poly([(0.08, 0.2), (0.0, 0.08), (0.16, 0.08)]))
    sticks = U(seg(-0.44, -0.04, 0.44, -0.62, 0.05), seg(0.5, -0.04, -0.38, -0.62, 0.05), circle(0.46, -0.64, 0.1), circle(-0.4, -0.64, 0.1))
    emblem = sub(U(skull, sticks), holes)
    shade = _lr(cloth, 0.09)
    shine = _hl(cloth, 0.08, 0.4)
    return [cloth, shade, shine, emblem]


@sticker("pirate", "hat", "Pirate hat", ["#3A3A58", "#FFC21A", "#14141F", "#9A9AC8"], ink=1.0)
def _():
    brim = sub(ellipse(0, -0.02, 0.9, 0.52), ellipse(0, 0.64, 0.8, 0.52))
    tips = U(poly([(-0.92, 0.0), (-0.84, 0.46), (-0.5, 0.0)]), poly([(0.92, 0.0), (0.84, 0.46), (0.5, 0.0)]), poly([(-0.2, 0.3), (0.0, 0.62), (0.2, 0.3)]))
    hat = U(brim, tips, box(0, 0.26, 0.4, 0.3, 0.14))
    stripe = inter(shell(ellipse(0, 0.64, 0.8, 0.52), 0.04), box(0, -0.2, 1.0, 0.3))
    skull = sub(U(circle(0, 0.3, 0.2), box(0, 0.14, 0.11, 0.08, 0.03)), U(circle(-0.075, 0.32, 0.055), circle(0.075, 0.32, 0.055)))
    trim = U(stripe, skull)
    shade = _lr(hat, 0.1)
    shine = _hl(hat, 0.08, 0.4)
    return [hat, trim, shade, shine]





@sticker("pirate", "spyglass", "Spyglass", ["#D9A441", "#6B3A1E", "#8A5F12", "#FFF6C8"], ink=1.0)
def _():
    with rotated(0.55):
        tube = U(box(-0.7, 0, 0.16, 0.14, 0.05), box(-0.36, 0, 0.24, 0.2, 0.05), box(0.12, 0, 0.32, 0.27, 0.06),
                 poly([(0.42, 0.27), (0.84, 0.4), (0.84, -0.4), (0.42, -0.27)]))
        bands = U(box(-0.52, 0, 0.045, 0.22, 0.01), box(-0.12, 0, 0.045, 0.28, 0.01), box(0.44, 0, 0.055, 0.36, 0.01))
        glint = U(oval(0.72, 0.12, 0.07, 0.2, 0.0), box(-0.2, 0.14, 0.14, 0.045, 0.02))
    shade = _lr(tube, 0.1)
    shine = U(_hl(tube, 0.08, 0.45), glint)
    return [tube, bands, shade, shine]


@sticker("pirate", "cannon", "Cannon", ["#7A4A22", "#3E4A5E", "#1A1E2A", "#9FB0C8"], ink=1.0)
def _():
    wheel = circle(-0.08, -0.46, 0.34)
    cart = U(wheel, box(-0.1, -0.2, 0.46, 0.1, 0.04))
    with rotated(0.3, -0.1, 0.1):
        barrel = U(taper(-0.5, 0.1, 0.6, 0.1, 0.28, 0.21), box(0.62, 0.1, 0.07, 0.26, 0.03), circle(-0.58, 0.1, 0.13))
    balls = U(circle(0.7, -0.62, 0.14), circle(0.48, -0.66, 0.14))
    iron = U(barrel, balls)
    spokes = U(*[seg(-0.08 + 0.26 * math.cos(a), -0.46 + 0.26 * math.sin(a), -0.08, -0.46, 0.035) for a in np.linspace(0, math.pi, 4)[:-1]],
               *[seg(-0.08 - 0.26 * math.cos(a), -0.46 - 0.26 * math.sin(a), -0.08, -0.46, 0.035) for a in np.linspace(0, math.pi, 4)[:-1]])
    shade = U(_lr(cart, 0.09), _lr(iron, 0.09), inter(spokes, wheel + 0.06))
    shine = U(_hl(iron, 0.07, 0.3), _hl(cart, 0.07, 0.6))
    return [cart, iron, shade, shine]


@sticker("pirate", "anchor", "Anchor chain", ["#24406E", "#BFC9D9", "#0F1C38", "#8DA9D6"], ink=1.0)
def _():
    shank = seg(0.1, -0.55, 0.1, 0.5, 0.095)
    stock = box(0.1, 0.36, 0.32, 0.075, 0.03)
    eye = ring(0.1, 0.68, 0.13, 0.06)
    arms = arc(0.1, -0.06, 0.56, math.pi * 1.1, math.pi * 1.9, 0.1)
    flukes = U(poly([(-0.52, -0.4), (-0.3, -0.3), (-0.44, -0.1)]), poly([(0.72, -0.4), (0.5, -0.3), (0.64, -0.1)]))
    anchor = U(shank, stock, eye, arms, flukes)
    links = U(*[sub(oval(x, y, 0.17, 0.1, a), oval(x, y, 0.09, 0.035, a)) for x, y, a in
                ((-0.12, 0.72, 0.3), (-0.38, 0.54, 1.2), (-0.5, 0.28, 0.1), (-0.36, 0.04, 1.2), (-0.1, -0.08, 0.3), (0.2, 0.0, 1.2))])
    shade = _lr(anchor, 0.09)
    shine = _hl(anchor, 0.08, 0.4)
    return [anchor, links, shade, shine]


@sticker("pirate", "hook", "Pirate hook", ["#B9C3D3", "#7A4A22", "#4A5568", "#FFFFFF"], ink=1.0)
def _():
    hook = brush([(0.26, 0.4), (0.26, 0.05), (0.2, -0.3), (-0.14, -0.58), (-0.46, -0.34), (-0.4, -0.02)], [0.12, 0.12, 0.11, 0.1, 0.07, 0.03])
    cuff = U(box(0.26, 0.62, 0.3, 0.22, 0.09), box(0.26, 0.36, 0.2, 0.06, 0.02))
    shade = U(_lr(hook, 0.08), _lr(cuff, 0.08))
    shine = U(_hl(hook, 0.07, 0.3), _hl(cuff, 0.07, 0.5))
    return [hook, cuff, shade, shine]


@sticker("pirate", "patch", "Patch pirate", ["#E8B27A", "#1E1E2E", "#A8693A", "#FFFFFF"], ink=1.0)
def _():
    face = circle(0, -0.1, 0.7)
    band = box(0, 0.5, 0.74, 0.17, 0.06)
    eye_patch = U(circle(-0.27, 0.12, 0.2), seg(-0.27, 0.12, 0.7, 0.4, 0.05), seg(-0.27, 0.12, -0.66, 0.34, 0.05))
    mouth = U(arc(0.0, -0.3, 0.3, -2.5, -0.64, 0.06), box(0.18, -0.4, 0.05, 0.05))
    patch = U(eye_patch, mouth)
    head = U(face, band)
    shade = _lr(head, 0.1)
    shine = U(_hl(face, 0.09, 0.4), circle(0.25, 0.14, 0.07))
    return [head, patch, shade, shine]


@sticker("pirate", "coins", "Doubloons", ["#FFC21A", "#C98A00", "#B87500", "#FFF3B0"], ink=1.0)
def _():
    cs = [(-0.5, -0.5), (0.0, -0.54), (0.5, -0.5), (-0.25, -0.1), (0.25, -0.1), (0.0, 0.3)]
    r = 0.3
    coins = U(*[circle(x, y, r) for x, y in cs])
    marks = U(*[ring(x, y, 0.17, 0.04) for x, y in cs])
    shade = U(*[sub(circle(x, y, r), circle(x - 0.07, y + 0.07, r)) for x, y in cs])
    shine = U(*[circle(x - 0.14, y + 0.14, 0.05) for x, y in cs])
    return [coins, marks, shade, shine]


@sticker("pirate", "kraken", "Kraken arm", ["#8B4FD6", "#4AA8F0", "#4B2290", "#F4C6F0"], ink=1.0)
def _():
    pts = [(-0.2, -0.62), (0.2, -0.32), (-0.02, 0.06), (-0.3, 0.34), (-0.1, 0.62), (0.3, 0.56), (0.42, 0.32)]
    wid = [0.26, 0.23, 0.2, 0.17, 0.14, 0.1, 0.05]
    arm = brush(pts, wid)
    dense = spline(pts, closed=False, n=8)
    cups = []
    for f, r in ((0.12, 0.085), (0.26, 0.08), (0.4, 0.075), (0.54, 0.07), (0.68, 0.06), (0.8, 0.05)):
        i = int(len(dense) * f)
        (px, py), (qx, qy) = dense[i], dense[i + 1]
        n = math.hypot(qx - px, qy - py) or 1.0
        cups.append(circle(px - (qy - py) / n * 0.07, py + (qx - px) / n * 0.07, r))
    suckers = U(*cups)
    water = U(box(0, -0.78, 0.8, 0.12, 0.05), *[circle(x, -0.62, 0.17) for x in (-0.6, -0.3, 0.0, 0.3, 0.6)])
    shade = U(_lr(arm, 0.1), _lr(water, 0.08))
    shine = U(_hl(arm, 0.08, 0.3), suckers)
    return [arm, water, shade, shine]


@sticker("pirate", "boot", "Sea boot", ["#7A4A22", "#C9955A", "#3E2210", "#E0B07A"], ink=1.0)
def _():
    boot = U(box(-0.14, 0.14, 0.32, 0.6, 0.08), box(0.12, -0.52, 0.66, 0.24, 0.12), box(-0.5, -0.78, 0.18, 0.1, 0.03))
    cuff = U(box(-0.14, 0.58, 0.5, 0.2, 0.07), box(-0.14, 0.1, 0.1, 0.1, 0.02), box(0.0, -0.1, 0.34, 0.06, 0.02, ang=0.15))
    shade = _lr(boot, 0.1)
    shine = U(_hl(boot, 0.08, 0.5), _hl(cuff, 0.06, 0.6))
    return [boot, cuff, shade, shine]


@sticker("pirate", "arrr", "ARRR sign", ["#E8C890", "#8A5A2B", "#FFF1D0", "#3A2210"], ink=1.0)
def _():
    plank = box(0, 0, 0.92, 0.52, 0.08)
    nails = U(*[circle(x, y, 0.05) for x in (-0.8, 0.8) for y in (-0.36, 0.36)], box(0, 0.4, 0.5, 0.02), box(0, -0.4, 0.5, 0.02))
    shade = U(_lr(plank, 0.1), nails)
    shine = _hl(plank, 0.08, 0.6)
    word = text("ARRR", 0, 0.0, 2.6, maxw=1.62)
    return [plank, shade, shine, word]


@sticker("pirate", "lantern", "Lantern", ["#FFD84A", "#2B2B3A", "#FF8A1F", "#FFFFFF"], ink=1.0)
def _():
    glass = box(0, -0.02, 0.34, 0.38, 0.1)
    frame = U(poly([(-0.46, 0.34), (0.46, 0.34), (0.22, 0.6), (-0.22, 0.6)]), box(0, -0.46, 0.46, 0.1, 0.04),
              seg(-0.34, 0.34, -0.34, -0.4, 0.05), seg(0.34, 0.34, 0.34, -0.4, 0.05), ring(0, 0.7, 0.12, 0.04))
    flame = U(circle(0, -0.12, 0.13), bezier((-0.1, -0.12), (-0.04, 0.1), (0.0, 0.26), 0.1, r1=0.01), bezier((0.1, -0.12), (0.04, 0.1), (0.0, 0.26), 0.1, r1=0.01))
    shade = U(_lr(glass, 0.08), flame)
    shine = _hl(glass, 0.07, 0.4)
    return [glass, frame, shade, shine]


@sticker("pirate", "serpent", "Sea serpent", ["#2DBE8A", "#2E7BD6", "#146A6A", "#FFFFFF"], ink=1.0)
def _():
    humps = U(arc(-0.58, -0.5, 0.23, 0.0, math.pi, 0.15), arc(-0.1, -0.5, 0.23, 0.0, math.pi, 0.15))
    neck = brush([(0.28, -0.55), (0.26, -0.1), (0.32, 0.24)], [0.17, 0.16, 0.15])
    head = U(oval(0.38, 0.48, 0.32, 0.2, 0.35), poly([(0.1, 0.54), (0.24, 0.8), (0.32, 0.58)]))
    serpent = U(humps, neck, head)
    water = U(box(0, -0.72, 0.8, 0.14, 0.05), *[circle(x, -0.54, 0.2) for x in (-0.6, -0.3, 0.0, 0.3, 0.6)])
    shade = U(_lr(serpent, 0.1), _lr(water, 0.08))
    shine = U(_hl(serpent, 0.08, 0.3), _hl(water, 0.06, 0.9), circle(0.46, 0.54, 0.08))
    return [serpent, water, shade, shine]


