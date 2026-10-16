# Fantasy — castles, creatures and charms. Every piece has the house shade (lower-right) and
# highlight (upper-left). Run by Tools/decor_stickers.py (every helper is in scope).
PACK = ("fantasy", "Fantasy", False)
PRO_IDS = {"castle", "unicorn", "sword", "griffin", "phoenix", "portal"}


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


@sticker("fantasy", "castle", "Castle", ["#9AA6C8", "#E8344E", "#4A5580", "#E6ECFF"], ink=1.0)
def _():
    keep = U(box(0, -0.3, 0.4, 0.52, 0.03), *[box(x, 0.28, 0.07, 0.07, 0.01) for x in (-0.28, -0.09, 0.09, 0.28)])
    towers = U(*[U(box(sx * 0.66, -0.35, 0.18, 0.45, 0.02), box(sx * 0.66, 0.15, 0.24, 0.06, 0.02)) for sx in (-1, 1)])
    body = U(keep, towers, seg(0.0, 0.3, 0.0, 0.84, 0.035))
    roofs = U(poly([(-0.9, 0.2), (-0.66, 0.68), (-0.42, 0.2)]), poly([(0.9, 0.2), (0.66, 0.68), (0.42, 0.2)]),
              box(0, -0.62, 0.16, 0.18, 0.04), circle(0, -0.45, 0.16), poly([(0.0, 0.84), (0.34, 0.74), (0.0, 0.64)]))
    slits = U(box(0, -0.05, 0.035, 0.12), box(-0.66, -0.3, 0.03, 0.1), box(0.66, -0.3, 0.03, 0.1))
    shade = U(_lr(body, 0.09), slits)
    shine = _hl(body, 0.08, 0.5)
    return [body, roofs, shade, shine]


@sticker("fantasy", "unicorn", "Unicorn", ["#FF6FD0", "#F6F0FF", "#2B1B5A", "#FFFFFF"], ink=1.0)
def _():
    skull = poly(spline([(-0.52, -0.86), (-0.34, -0.2), (-0.3, 0.3), (-0.12, 0.46), (0.1, 0.4), (0.42, 0.14), (0.62, -0.06), (0.58, -0.28),
                         (0.34, -0.3), (0.16, -0.16), (0.12, -0.4), (0.2, -0.86)], closed=True, n=6))
    ear = poly([(-0.16, 0.3), (-0.04, 0.72), (0.16, 0.34)])
    head = smin(skull, ear, 0.05)
    horn = bezier((0.12, 0.26), (0.24, 0.6), (0.4, 0.94), 0.11, r1=0.012)
    mane = brush([(-0.2, 0.42), (-0.56, 0.16), (-0.5, -0.28), (-0.64, -0.72)], [0.12, 0.17, 0.16, 0.12])
    horn_mane = U(horn, mane)
    eye = U(circle(0.26, 0.12, 0.05), circle(0.54, -0.12, 0.03))
    shade = U(_lr(head, 0.09), eye)
    shine = U(_hl(head, 0.08, 0.4), inter(horn, stripes(0.15, 1.2, 0.4, 0.03)))
    return [horn_mane, head, shade, shine]


@sticker("fantasy", "staff", "Wizard staff", ["#8A5A2B", "#7AE0FF", "#4E2F12", "#FFFFFF"], ink=1.0)
def _():
    with rotated(-0.5):
        wood = U(seg(0, -0.8, 0, 0.3, 0.12), arc(0, 0.52, 0.34, -2.8, -0.34, 0.1), arc(0, 0.52, 0.34, 0.34, 2.8, 0.1))
        orb = circle(0, 0.52, 0.24)
    glow = U(orb, star(0.62, 0.0, 4, 0.3, 0.09))
    shade = _lr(wood, 0.09)
    shine = _hl(wood, 0.08, 0.3)
    return [wood, glow, shade, shine]


@sticker("fantasy", "sword", "Sword in stone", ["#8F97A8", "#D8E2F4", "#4A2E12", "#FFF3B0"], ink=1.0)
def _():
    stone = poly(spline([(-0.8, -0.84), (-0.76, -0.42), (-0.5, -0.24), (-0.2, -0.34), (0.2, -0.32), (0.52, -0.2), (0.78, -0.44), (0.82, -0.84)], closed=True, n=6))
    blade = U(box(0, -0.05, 0.11, 0.3, 0.01), poly([(-0.11, 0.25), (0.11, 0.25), (0.0, 0.38)]), box(0, -0.4, 0.11, 0.14))
    hilt = U(box(0, 0.38, 0.38, 0.075, 0.03), box(0, 0.56, 0.07, 0.13, 0.02), circle(0, 0.71, 0.1))
    shade = U(_lr(stone, 0.1), hilt)
    shine = U(_hl(stone, 0.09, 0.6), star(0.55, 0.28, 4, 0.2, 0.06), star(-0.55, 0.45, 4, 0.16, 0.05))
    return [stone, blade, shade, shine]


@sticker("fantasy", "helmet", "Knight helmet", ["#AEB8D0", "#E8344E", "#2B3552", "#FFFFFF"], ink=1.0)
def _():
    helm = U(circle(0, 0.1, 0.5), box(0, -0.32, 0.5, 0.42, 0.08), box(0, -0.74, 0.4, 0.08, 0.03))
    plume = brush([(0.0, 0.54), (0.24, 0.8), (0.52, 0.74), (0.66, 0.46)], [0.1, 0.14, 0.12, 0.08])
    slit = U(box(0, 0.02, 0.36, 0.06, 0.02), box(0, -0.16, 0.04, 0.12), *[circle(x, -0.42, 0.04) for x in (-0.2, -0.1, 0.1, 0.2)])
    shade = U(_lr(helm, 0.1), slit)
    shine = _hl(helm, 0.09, 0.4)
    return [helm, plume, shade, shine]


@sticker("fantasy", "crest", "Crest shield", ["#D63A3A", "#FFD84A", "#7A1414", "#FFFFFF"], ink=1.0)
def _():
    shield = poly(spline([(-0.7, 0.8), (0.7, 0.8), (0.74, 0.1), (0.46, -0.5), (0.0, -0.88), (-0.46, -0.5), (-0.74, 0.1)], closed=True, n=6))
    border = sub(shield, shield + 0.08)
    rays = U(*[seg(0.26 * math.cos(a), 0.12 + 0.26 * math.sin(a), 0.44 * math.cos(a), 0.12 + 0.44 * math.sin(a), 0.055) for a in np.linspace(0, 2 * math.pi, 9)[:-1]])
    emblem = U(border, circle(0, 0.12, 0.2), rays)
    shade = _lr(shield, 0.1)
    shine = _hl(shield, 0.09, 0.5)
    return [shield, emblem, shade, shine]


@sticker("fantasy", "egg", "Dragon egg", ["#35C28A", "#FFC21A", "#0E6A4A", "#C8FFE6"], ink=1.0)
def _():
    egg = oval(0, -0.04, 0.62, 0.8, 0.0)
    pts = [(x, y) for y, off in ((0.5, 0.0), (0.22, 0.2), (-0.06, 0.0), (-0.34, 0.2), (-0.6, 0.0)) for x in (-0.42 + off, -0.02 + off, 0.38 + off - (0.2 if off else 0.0))]
    scales = U(*[inter(regpoly(x, y, 4, 0.13), egg + 0.1) for x, y in pts if abs(x) < 0.55])
    crack = polyline([(-0.2, 0.7), (-0.05, 0.5), (-0.18, 0.36), (0.0, 0.2)], 0.035)
    shade = U(_lr(egg, 0.11), crack)
    shine = _hl(egg, 0.1, 0.5)
    return [egg, scales, shade, shine]


@sticker("fantasy", "fairy", "Fairy", ["#8CE8FF", "#FFD9C2", "#D6508A", "#FFF6A0"], ink=1.0)
def _():
    wings = U(*[taper(sx * 0.04, 0.2, sx * 0.72, 0.64, 0.03, 0.19) for sx in (-1, 1)], *[taper(sx * 0.04, 0.16, sx * 0.6, -0.18, 0.03, 0.14) for sx in (-1, 1)])
    skin = U(circle(0, 0.44, 0.2), seg(-0.1, 0.16, -0.4, 0.0, 0.06), seg(0.1, 0.16, 0.42, 0.42, 0.06), seg(-0.1, -0.4, -0.13, -0.8, 0.055),
             seg(0.1, -0.4, 0.13, -0.8, 0.055), circle(-0.17, -0.82, 0.07), circle(0.17, -0.82, 0.07))
    dress = poly(spline([(-0.15, 0.22), (0.15, 0.22), (0.18, 0.04), (0.44, -0.42), (0.0, -0.52), (-0.44, -0.42), (-0.18, 0.04)], closed=True, n=6))
    hair = U(sub(circle(0, 0.5, 0.25), circle(0.0, 0.33, 0.24)), circle(-0.1, 0.72, 0.1), brush([(-0.2, 0.5), (-0.3, 0.3), (-0.26, 0.12)], [0.07, 0.07, 0.05]))
    wand = U(seg(0.42, 0.42, 0.62, 0.72, 0.03), star(0.66, 0.78, 4, 0.2, 0.06))
    shade = U(dress, hair, _lr(skin, 0.06))
    shine = U(_hl(skin, 0.05, 0.4), wand)
    return [wings, skin, shade, shine]


@sticker("fantasy", "shrooms", "Mushroom ring", ["#E8344E", "#FFF1D6", "#7A1428", "#FFFFFF"], ink=1.0)
def _():
    caps, stem_parts, spots = [], [], []
    for k in range(4):
        t = math.radians(-90 + 90 * k)
        x, y = 0.56 * math.cos(t), 0.04 + 0.3 * math.sin(t)
        r = 0.3 - 0.08 * math.sin(t)
        caps.append(sub(ellipse(x, y + 0.08, r, r * 0.85), box(x, y - 0.22, r * 1.2, r * 0.75)))
        stem_parts.append(box(x, y - 0.08, r * 0.42, r * 0.34, 0.03))
        spots.append(circle(x - r * 0.3, y + r * 0.4, r * 0.2))
    cap = U(*caps)
    stems = U(*stem_parts)
    shade = _lr(cap, 0.08)
    shine = U(*spots)
    return [cap, stems, shade, shine]


@sticker("fantasy", "goblet", "Golden goblet", ["#FFC21A", "#E8344E", "#A86A00", "#FFF3B0"], ink=1.0)
def _():
    cup = U(inter(circle(0, 0.25, 0.58), Y - 0.25), box(0, 0.3, 0.6, 0.06, 0.03))
    gold = U(cup, box(0, -0.3, 0.09, 0.3, 0.02), oval(0, -0.66, 0.4, 0.12, 0.0), circle(0, -0.34, 0.15))
    gems = U(circle(0, 0.0, 0.12), circle(-0.32, 0.14, 0.07), circle(0.32, 0.14, 0.07))
    shade = _lr(gold, 0.1)
    shine = _hl(gold, 0.09, 0.4)
    return [gold, gems, shade, shine]


@sticker("fantasy", "scroll", "Spell scroll", ["#F1DFAE", "#3A1C8A", "#B8995A", "#FFFFFF"], ink=1.0)
def _():
    paper = U(box(0, 0.0, 0.6, 0.54, 0.02), box(0, 0.58, 0.74, 0.12, 0.12), box(0, -0.58, 0.74, 0.12, 0.12))
    word = text("QUEST", 0.0, 0.0, 3.0, maxw=1.1)
    shade = _lr(paper, 0.09)
    shine = U(_hl(paper, 0.08, 0.5), star(0.62, 0.74, 4, 0.18, 0.06))
    return [paper, word, shade, shine]


@sticker("fantasy", "lute", "Magic lute", ["#B5651D", "#FFD84A", "#2A1206", "#FFFFFF"], ink=1.0)
def _():
    with rotated(0.8):
        wood = U(oval(0, -0.28, 0.4, 0.58, 0.0), box(0, 0.4, 0.1, 0.46, 0.02), poly([(-0.14, 0.86), (0.14, 0.86), (0.2, 0.64), (-0.2, 0.64)]))
        hole = circle(0, -0.22, 0.14)
        strings = U(*[seg(x, -0.62, x * 0.5, 0.74, 0.022) for x in (-0.07, 0.0, 0.07)])
        pegs = U(circle(-0.2, 0.82, 0.05), circle(0.2, 0.82, 0.05), box(0, -0.6, 0.18, 0.035, 0.01), ring(0, -0.22, 0.2, 0.04))
    gold = U(pegs, star(0.62, 0.6, 4, 0.26, 0.08))
    shade = U(_lr(wood, 0.1), hole, strings)
    shine = _hl(wood, 0.08, 0.4)
    return [wood, gold, shade, shine]


@sticker("fantasy", "phoenix", "Phoenix feather", ["#FF2E6A", "#FFC21A", "#7A0A28", "#FFFFFF"], ink=1.0)
def _():
    with rotated(0.45):
        vane = poly(spline([(0.0, 0.5), (0.22, 0.3), (0.3, 0.0), (0.28, -0.4), (0.12, -0.66), (0.0, -0.74), (-0.12, -0.66), (-0.28, -0.4), (-0.3, 0.0), (-0.22, 0.3)], closed=True, n=6))
        tongues = U(taper(-0.2, 0.4, -0.38, 0.84, 0.14, 0.01), taper(0.0, 0.5, 0.0, 0.92, 0.16, 0.01), taper(0.2, 0.4, 0.38, 0.84, 0.14, 0.01))
        flame = U(vane, tongues)
        core = U(oval(0.0, 0.0, 0.14, 0.4, 0.0), taper(0.0, 0.5, 0.0, 0.8, 0.07, 0.01))
        quill = seg(0.0, -0.86, 0.0, 0.84, 0.045)
    shade = U(_lr(flame, 0.09), quill)
    shine = _hl(flame, 0.08, 0.3)
    return [flame, core, shade, shine]


@sticker("fantasy", "griffin", "Griffin", ["#D9922E", "#F4F0E6", "#4A2A0C", "#FFF3C8"], ink=1.0)
def _():
    wing = poly([(-0.1, 0.05), (-0.18, 0.5), (-0.3, 0.88), (-0.55, 0.86), (-0.5, 0.74), (-0.76, 0.7), (-0.62, 0.58), (-0.86, 0.5),
                 (-0.68, 0.42), (-0.82, 0.32), (-0.52, 0.3), (-0.3, 0.1)])
    torso = U(oval(-0.05, -0.34, 0.5, 0.26, 0.0), circle(-0.4, -0.34, 0.26))
    legs = U(brush([(-0.42, -0.4), (-0.52, -0.64), (-0.46, -0.84)], [0.13, 0.1, 0.09]), oval(-0.4, -0.86, 0.14, 0.07, 0.0),
             seg(0.16, -0.42, 0.2, -0.82, 0.09), oval(0.26, -0.84, 0.13, 0.07, 0.0), brush([(0.3, -0.3), (0.58, -0.2), (0.7, -0.38)], [0.09, 0.08, 0.08]))
    tail = U(brush([(-0.62, -0.28), (-0.86, -0.18), (-0.8, 0.02)], [0.09, 0.08, 0.07]), circle(-0.8, 0.06, 0.13))
    beak = poly(spline([(0.46, 0.7), (0.84, 0.54), (0.92, 0.22), (0.72, 0.34), (0.6, 0.24), (0.46, 0.4)], closed=True, n=5))
    lion = U(wing, torso, legs, tail, beak)
    neck = brush([(0.1, -0.2), (0.18, 0.1), (0.26, 0.4)], [0.2, 0.18, 0.18])
    head = U(neck, oval(0.26, 0.52, 0.3, 0.26, 0.0), taper(0.2, 0.7, -0.1, 0.84, 0.1, 0.01), taper(0.28, 0.76, 0.0, 0.94, 0.09, 0.01), taper(0.14, 0.62, -0.18, 0.7, 0.09, 0.01))
    eye = U(circle(0.4, 0.54, 0.065), seg(0.26, 0.74, 0.5, 0.6, 0.045))
    both = U(lion, head)
    shade = U(_lr(both, 0.09), eye, circle(-0.8, 0.06, 0.13))
    shine = _hl(both, 0.08, 0.3)
    return [lion, head, shade, shine]


@sticker("fantasy", "rune", "Rune stone", ["#8A93A8", "#5CF0D0", "#3E465C", "#C8FFF0"], ink=1.0)
def _():
    slab = poly([(-0.66, -0.86), (-0.5, -0.1), (-0.58, 0.46), (-0.2, 0.7), (0.08, 0.86), (0.34, 0.6), (0.62, 0.52), (0.52, -0.2), (0.68, -0.86)])
    rune = U(seg(0.0, 0.44, 0.0, -0.46, 0.11), seg(0.0, 0.08, -0.3, 0.4, 0.1), seg(0.0, 0.08, 0.3, 0.4, 0.1), seg(0.0, -0.22, -0.26, -0.5, 0.09))
    cracks = U(polyline([(0.4, -0.6), (0.3, -0.4), (0.4, -0.2)], 0.03), polyline([(-0.42, 0.34), (-0.34, 0.14)], 0.03))
    shade = U(_lr(slab, 0.1), cracks)
    shine = _hl(slab, 0.09, 0.5)
    return [slab, rune, shade, shine]


@sticker("fantasy", "portal", "Portal", ["#C9B68A", "#7A3CE6", "#6E5F3A", "#E8D4FF"], ink=1.0)
def _():
    outer = poly(spline([(-0.72, -0.84), (-0.72, 0.06), (-0.46, 0.56), (0.0, 0.9), (0.46, 0.56), (0.72, 0.06), (0.72, -0.84)], closed=True, n=6))
    disc = poly(spline([(-0.44, -0.76), (-0.44, 0.02), (-0.28, 0.4), (0.0, 0.66), (0.28, 0.4), (0.44, 0.02), (0.44, -0.76)], closed=True, n=6))
    arch = sub(outer, disc)
    arms = []
    for a0 in (0.0, math.pi):
        arms.append(polyline([((0.04 + 0.9 * k / 60) * math.cos(a0 + k * 0.16), -0.06 + (0.04 + 0.9 * k / 60) * 1.15 * math.sin(a0 + k * 0.16)) for k in range(61)], 0.075))
    swirl = inter(U(*arms), disc + 0.02)
    shade = _lr(arch, 0.09)
    shine = U(_hl(arch, 0.08, 0.5), swirl)
    return [arch, disc, shade, shine]


