# Pets — faces, bowls, balls and cozy beds for the best friends on the drum riser. Run by Tools/decor_stickers.py (every helper is in scope).
PACK = ("pets", "Pets", False)
PRO_IDS = {"catdrum", "dogphones", "hamster", "fishbowl", "parrot"}


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


def _paw(cx, cy, s):
    """A paw print: one big pad and four toes."""
    pad = oval(cx, cy - 0.2 * s, 0.36 * s, 0.3 * s)
    toes = U(oval(cx - 0.5 * s, cy + 0.08 * s, 0.14 * s, 0.2 * s, 0.5), oval(cx - 0.18 * s, cy + 0.36 * s, 0.15 * s, 0.21 * s, 0.15),
             oval(cx + 0.18 * s, cy + 0.36 * s, 0.15 * s, 0.21 * s, -0.15), oval(cx + 0.5 * s, cy + 0.08 * s, 0.14 * s, 0.2 * s, -0.5))
    return U(pad, toes)


@sticker("pets", "puppy", "Puppy", ["#E8A850", "#8A5A33", "#FFFFFF", "#1A1410"], ink=1.0)
def _():
    skull = circle(0, 0.2, 0.52)
    paws = U(oval(-0.3, -0.38, 0.15, 0.11), oval(0.3, -0.38, 0.15, 0.11))
    head = U(skull, oval(-0.5, 0.18, 0.19, 0.4, -0.28), oval(0.5, 0.18, 0.19, 0.4, 0.28), paws)
    ears = U(oval(-0.5, 0.18, 0.19, 0.4, -0.28), oval(0.5, 0.18, 0.19, 0.4, 0.28), _rim(skull, 0.08))
    pickets = U(*[U(box(x, -0.62, 0.12, 0.22), poly([(x - 0.12, -0.42), (x + 0.12, -0.42), (x, -0.28)])) for x in (-0.74, -0.44, -0.14, 0.16, 0.46, 0.76)])
    fence = U(sub(pickets, paws), oval(0, -0.02, 0.28, 0.2), seg(-0.3, 0.5, -0.18, 0.6, 0.04))
    face = U(circle(-0.22, 0.26, 0.085), circle(0.22, 0.26, 0.085), oval(0, 0.06, 0.12, 0.085), seg(0, 0.0, 0, -0.06, 0.03))
    return [head, ears, fence, face]


@sticker("pets", "kitten", "Kitten", ["#B8C0CC", "#6B7385", "#C98B4B", "#1A1410"], ink=1.0)
def _():
    paws = U(oval(-0.26, -0.12, 0.14, 0.11), oval(0.26, -0.12, 0.14, 0.11))
    head = U(oval(0, 0.2, 0.56, 0.48), poly([(-0.52, 0.34), (-0.46, 0.84), (-0.08, 0.6)]), poly([(0.52, 0.34), (0.46, 0.84), (0.08, 0.6)]), paws)
    stripes = U(taper(0, 0.62, 0, 0.44, 0.045, 0.03), taper(-0.17, 0.6, -0.12, 0.44, 0.04, 0.025), taper(0.17, 0.6, 0.12, 0.44, 0.04, 0.025),
                poly([(-0.44, 0.44), (-0.4, 0.72), (-0.2, 0.58)]), poly([(0.44, 0.44), (0.4, 0.72), (0.2, 0.58)]), _rim(oval(0, 0.2, 0.56, 0.48), 0.08))
    carton = U(box(0, -0.5, 0.78, 0.4, 0.05), poly([(-0.78, -0.12), (-0.96, 0.08), (-0.66, 0.14)]), poly([(0.78, -0.12), (0.96, 0.08), (0.66, 0.14)]))
    box_ = sub(U(carton, box(0, -0.4, 0.78, 0.04)), paws)
    face = U(oval(-0.22, 0.2, 0.09, 0.12), oval(0.22, 0.2, 0.09, 0.12), poly([(-0.06, 0.06), (0.06, 0.06), (0, -0.01)]),
             arc(-0.07, -0.04, 0.07, -3.0, -0.2, 0.025), arc(0.07, -0.04, 0.07, -3.0, -0.2, 0.025),
             seg(-0.38, 0.1, -0.74, 0.14, 0.032), seg(-0.38, 0.0, -0.74, -0.04, 0.032), seg(0.38, 0.1, 0.74, 0.14, 0.032), seg(0.38, 0.0, 0.74, -0.04, 0.032))
    return [head, stripes, box_, face]


@sticker("pets", "fishbowl", "Goldfish bowl", ["#D6F4FF", "#4DB8FF", "#FF7A1A", "#1A1410"], ink=1.0)
def _():
    glass = U(circle(0, -0.1, 0.7), box(0, 0.62, 0.3, 0.1, 0.04))
    water = sub(inter(circle(0, -0.1, 0.7), Y - 0.28), arc(-0.4, -0.1, 0.46, 1.9, 2.8, 0.035))
    fish_body = smin(oval(-0.02, -0.08, 0.3, 0.2), poly([(0.2, -0.08), (0.5, 0.06), (0.5, -0.24)]), 0.05)
    fish = U(fish_body, poly([(-0.1, 0.06), (0.06, 0.28), (0.12, 0.04)]), poly([(-0.02, -0.2), (0.12, -0.36), (0.14, -0.18)]))
    bubbles = U(shell(circle(-0.36, 0.1, 0.06), 0.022), shell(circle(-0.26, 0.26, 0.045), 0.02), circle(-0.17, -0.08, 0.05))
    return [glass, water, fish, bubbles]


@sticker("pets", "hamster", "Hamster wheel", ["#2EC4B6", "#F2B26B", "#FFF0D2", "#1A1410"], ink=1.0)
def _():
    wheel = U(shell(circle(0, 0.1, 0.78), 0.065), *[seg(0, 0.1, 0.78 * math.cos(a), 0.1 + 0.78 * math.sin(a), 0.065) for a in (0.5, 2.6, 4.7)],
              box(0, -0.84, 0.5, 0.07, 0.04), seg(0, 0.1, -0.34, -0.84, 0.085), seg(0, 0.1, 0.34, -0.84, 0.085))
    hamster = U(smin(oval(-0.12, -0.3, 0.5, 0.36), circle(0.36, -0.2, 0.3), 0.12), circle(0.28, 0.02, 0.11), oval(-0.38, -0.62, 0.14, 0.08), oval(0.1, -0.62, 0.14, 0.08))
    belly = U(oval(0.0, -0.46, 0.3, 0.14), oval(0.5, -0.28, 0.17, 0.12))
    face = U(circle(0.44, -0.14, 0.065), circle(0.66, -0.26, 0.055))
    return [wheel, hamster, belly, face]


@sticker("pets", "paw", "Paw print", ["#FF6B6B", "#D93F4A", "#FFF4E8", "#FFFFFF"], ink=1.0)
def _():
    disc = circle(0, 0, 0.88)
    shade = _rim(disc, 0.1)
    paw = _paw(0, -0.02, 1.12)
    shine = seg(-0.62, 0.38, -0.42, 0.6, 0.045)
    return [disc, shade, paw, shine]


@sticker("pets", "tag", "Collar tag", ["#FFC531", "#E3172F", "#E09A12", "#1A1410"], ink=1.0)
def _():
    plate = box(0, -0.22, 0.84, 0.56, 0.28)
    tag = U(plate, shell(circle(0, 0.5, 0.17), 0.05))
    strap = box(0, 0.78, 0.88, 0.12, 0.04)
    shade = _rim(plate, 0.09)
    words = U(text("GOOD", 0, -0.06, 0.38, stretch=0.8, maxw=1.35), text("BOY", 0, -0.46, 0.34, maxw=0.9))
    return [tag, strap, shade, words]


@sticker("pets", "parrot", "Parrot", ["#E3402F", "#2B7BE0", "#FFB300", "#1A1410"], ink=1.0)
def _():
    body = smin(smin(circle(-0.08, 0.3, 0.36), oval(0.12, -0.2, 0.36, 0.52, -0.3), 0.2),
                brush([(0.28, -0.5), (0.4, -0.72), (0.56, -0.9)], [0.13, 0.1, 0.06]), 0.04)
    wing = U(oval(0.16, -0.12, 0.2, 0.4, -0.3), brush([(0.3, -0.5), (0.42, -0.72), (0.56, -0.9)], [0.07, 0.06, 0.03]))
    beak = U(circle(-0.5, 0.22, 0.15), taper(-0.56, 0.2, -0.52, -0.02, 0.09, 0.025), seg(-0.5, -0.62, 0.5, -0.78, 0.09),
             seg(-0.1, -0.66, -0.12, -0.74, 0.04), seg(0.1, -0.68, 0.1, -0.74, 0.04))
    eye = U(circle(-0.28, 0.36, 0.07))
    return [body, wing, beak, eye]


@sticker("pets", "guinea", "Guinea pig", ["#E0782A", "#4A2A18", "#FFF0D2", "#1A1410"], ink=1.0)
def _():
    body = smin(oval(0.26, -0.14, 0.6, 0.4), circle(-0.4, 0.0, 0.42), 0.15)
    dark = U(inter(body, oval(0.52, -0.02, 0.3, 0.36)), circle(-0.16, 0.38, 0.16), oval(-0.22, -0.62, 0.17, 0.08), oval(0.5, -0.62, 0.17, 0.08), _rim(body, 0.07))
    blaze = inter(body, oval(-0.56, 0.12, 0.15, 0.3, -0.1))
    face = U(circle(-0.4, 0.12, 0.085), circle(-0.82, -0.04, 0.075), arc(-0.62, -0.2, 0.08, -3.0, -0.3, 0.03))
    return [body, dark, blaze, face]


@sticker("pets", "turtle", "Turtle", ["#9ADB5A", "#2E9E4F", "#1F6B34", "#1A1410"], ink=1.0)
def _():
    skin = U(taper(0.4, -0.12, 0.62, 0.04, 0.12, 0.1), circle(0.66, 0.06, 0.2), oval(-0.34, -0.5, 0.15, 0.14), oval(0.3, -0.5, 0.15, 0.14),
             poly([(-0.55, -0.18), (-0.84, -0.3), (-0.55, -0.34)]), box(0, -0.32, 0.6, 0.08, 0.04))
    dome = inter(circle(0, -0.22, 0.64), -(Y + 0.3))
    scutes = U(_rim(dome, 0.1), seg(-0.18, 0.4, -0.3, -0.26, 0.035), seg(0.18, 0.4, 0.3, -0.26, 0.035),
               seg(-0.52, 0.06, 0.52, 0.06, 0.035))
    scutes = inter(U(scutes, shell(dome, 0.02)), dome - 0.0)
    face = U(circle(0.7, 0.1, 0.045), arc(0.74, 0.0, 0.08, -2.6, -0.8, 0.02))
    return [skin, dome, scutes, face]


@sticker("pets", "dogbowl", "Dog bowl", ["#C98B4B", "#2EC4B6", "#1B8F86", "#FFFFFF"], ink=1.0)
def _():
    kibble = U(circle(-0.4, 0.14, 0.15), circle(-0.14, 0.24, 0.16), circle(0.14, 0.24, 0.16), circle(0.4, 0.14, 0.15), circle(0, 0.44, 0.16),
               circle(-0.3, 0.38, 0.12), circle(0.28, 0.4, 0.12))
    bowl = U(poly([(-0.78, 0.0), (0.78, 0.0), (0.58, -0.6), (-0.58, -0.6)]) - 0.04, box(0, 0.0, 0.84, 0.07, 0.05), box(0, -0.7, 0.46, 0.07, 0.04))
    shade = U(_rim(bowl, 0.08))
    paw = _paw(0, -0.3, 0.42)
    return [kibble, bowl, shade, paw]


@sticker("pets", "tennisball", "Tennis ball", ["#D8F03A", "#A8C21C", "#FFFFFF", "#FFFFFF"], ink=1.0)
def _():
    ball = circle(0, 0, 0.84)
    shade = _rim(ball, 0.1)
    seams = inter(U(shell(circle(-1.14, 0, 0.9), 0.04), shell(circle(1.14, 0, 0.9), 0.04)), ball + 0.06)
    shine = seg(-0.68, 0.1, -0.58, 0.34, 0.045)
    return [ball, shade, seams, shine]


@sticker("pets", "catdrum", "Cat drummer", ["#FF9F1C", "#E3172F", "#FFF4DC", "#1A1410"], ink=1.0)
def _():
    cat = U(oval(0, 0.0, 0.34, 0.4), circle(0, 0.36, 0.3), poly([(-0.3, 0.46), (-0.26, 0.82), (-0.06, 0.62)]), poly([(0.3, 0.46), (0.26, 0.82), (0.06, 0.62)]),
            brush([(0.3, -0.1), (0.62, -0.1), (0.7, 0.2)], [0.07, 0.07, 0.05]), circle(-0.26, 0.02, 0.09), circle(0.26, 0.02, 0.09))
    drum = U(box(0, -0.52, 0.64, 0.32, 0.06), oval(0, -0.2, 0.64, 0.17))
    trim = U(oval(0, -0.2, 0.52, 0.12), inter(drum, box(0, -0.4, 0.7, 0.03)), inter(drum, box(0, -0.72, 0.7, 0.03)),
             seg(-0.26, 0.04, -0.56, 0.42, 0.08), seg(0.26, 0.04, 0.56, 0.42, 0.08), circle(-0.6, 0.46, 0.12), circle(0.6, 0.46, 0.12))
    face = U(circle(-0.12, 0.38, 0.045), circle(0.12, 0.38, 0.045), poly([(-0.04, 0.3), (0.04, 0.3), (0, 0.25)]),
             *[seg(x, -0.4, x, -0.72, 0.022) for x in (-0.44, -0.22, 0.0, 0.22, 0.44)])
    return [cat, drum, trim, face]


@sticker("pets", "dogphones", "DJ dog", ["#F4F1EA", "#3A2A22", "#E3172F", "#1A1410"], ink=1.0)
def _():
    head = U(circle(0, -0.1, 0.55), oval(-0.6, -0.32, 0.14, 0.3, -0.15), oval(0.6, -0.32, 0.14, 0.3, 0.15))
    spots = U(oval(-0.6, -0.32, 0.14, 0.3, -0.15), oval(0.6, -0.32, 0.14, 0.3, 0.15), circle(0.22, 0.2, 0.13), circle(-0.18, -0.4, 0.07),
             circle(0.3, -0.5, 0.06), circle(-0.04, 0.34, 0.06), _rim(circle(0, -0.1, 0.55), 0.07))
    phones = U(arc(0, -0.1, 0.7, 0.15, 2.99, 0.07), box(-0.7, -0.1, 0.15, 0.26, 0.07), box(0.7, -0.1, 0.15, 0.26, 0.07))
    face = U(circle(-0.22, -0.02, 0.07), circle(0.22, -0.02, 0.07), oval(0, -0.3, 0.12, 0.09),
             arc(-0.09, -0.42, 0.09, -3.0, -0.14, 0.028), arc(0.09, -0.42, 0.09, -3.0, -0.14, 0.028))
    return [head, spots, phones, face]


@sticker("pets", "yarn", "Yarn ball", ["#FF6FA0", "#D93A72", "#C9CED6", "#FFE0EC"], ink=1.0)
def _():
    ball = circle(-0.1, 0.1, 0.62)
    thread = brush([(0.3, -0.4), (0.62, -0.66), (0.35, -0.82), (0.7, -0.84)], [0.12, 0.12, 0.11, 0.1])
    body = U(ball, thread)
    strands = inter(U(shell(circle(-1.3, 1.1, 1.4), 0.035), shell(circle(-1.5, 1.3, 1.7), 0.035), shell(circle(1.1, 0.9, 1.2), 0.035),
                      shell(circle(1.3, 0.5, 1.5), 0.035), _rim(ball, 0.1)), ball + 0.0)
    needle = U(seg(0.16, 0.16, 0.62, 0.6, 0.085), circle(0.66, 0.64, 0.13))
    shine = seg(-0.42, 0.42, -0.26, 0.56, 0.04)
    return [body, strands, needle, shine]


@sticker("pets", "bed", "Pet bed", ["#8B5CF6", "#E9D9FF", "#D9A05B", "#1A1410"], ink=1.0)
def _():
    outer = oval(0, -0.52, 0.9, 0.34)
    inner = oval(0, -0.46, 0.7, 0.2)
    dog = U(oval(0.12, -0.14, 0.5, 0.34), circle(-0.42, -0.04, 0.34), oval(-0.72, -0.1, 0.16, 0.12), oval(0.62, -0.32, 0.14, 0.1, 0.7))
    lines = U(oval(-0.3, 0.06, 0.12, 0.26, 0.45), arc(-0.5, 0.02, 0.07, -3.0, -0.15, 0.035), circle(-0.8, -0.06, 0.05),
              text("Z", 0.46, 0.5, 0.3, maxw=0.4), text("Z", 0.74, 0.76, 0.2, maxw=0.28))
    return [outer, inner, dog, lines]


@sticker("pets", "woof", "Woof", ["#FFD400", "#E09A12", "#1A1410", "#E3172F"], ink=1.0)
def _():
    bubble = U(oval(0, 0.1, 0.9, 0.58), poly([(-0.5, -0.3), (-0.1, -0.44), (-0.64, -0.82)]))
    shade = _rim(bubble, 0.09)
    word = text("WOOF", 0.0, 0.1, 0.36, ang=0.08, maxw=1.3)
    bark = U(seg(0.56, 0.7, 0.7, 0.8, 0.08), seg(0.68, 0.54, 0.8, 0.54, 0.08), seg(-0.56, 0.7, -0.7, 0.8, 0.08))
    return [bubble, shade, word, bark]
