# Dino Beats — prehistoric pals, a volcano, fossils and a lot of RAWR. Run by Tools/decor_stickers.py (every helper is in scope).
PACK = ("dino", "Dino Beats", False)
PRO_IDS = {"trex", "volcano", "shades", "baby", "meteor"}


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


@sticker("dino", "trex", "T. rex drummer", ["#5CBF4A", "#E3172F", "#FFF4DC", "#1A1410"], ink=1.0)
def _():
    head = U(oval(-0.4, 0.5, 0.5, 0.27, 0.1), oval(-0.46, 0.3, 0.4, 0.11, 0.05))
    rex = smin(smin(U(oval(0.28, -0.05, 0.46, 0.38), taper(-0.1, 0.42, 0.2, 0.05, 0.2, 0.3)), head, 0.15), brush([(0.6, -0.1), (0.82, 0.0), (0.93, 0.26)], [0.2, 0.12, 0.05]), 0.1)
    rex = U(rex, seg(-0.02, 0.06, -0.3, -0.12, 0.085), seg(0.24, 0.02, 0.08, -0.14, 0.085))
    drum = box(-0.15, -0.72, 0.6, 0.2, 0.05)
    belly = U(oval(-0.15, -0.52, 0.6, 0.11), circle(-0.3, -0.12, 0.1), circle(0.08, -0.14, 0.1),
              *[poly([(x - 0.05, 0.33), (x + 0.05, 0.33), (x, 0.24)]) for x in (-0.72, -0.58, -0.44, -0.3)])
    sticks = U(seg(-0.3, -0.12, -0.62, -0.46, 0.07), seg(0.08, -0.14, 0.4, -0.48, 0.07), circle(-0.5, 0.6, 0.055),
               *[seg(x, -0.6, x, -0.88, 0.028) for x in (-0.55, -0.35, -0.15, 0.05, 0.25)])
    return [rex, drum, belly, sticks]


@sticker("dino", "trike", "Triceratops", ["#5BC0A5", "#FF8A5B", "#FFF4C7", "#1A1410"], ink=1.0)
def _():
    head = U(circle(-0.5, -0.02, 0.28), oval(-0.72, -0.1, 0.2, 0.14))
    body = smin(U(oval(0.25, -0.08, 0.55, 0.4), head), brush([(0.7, -0.1), (0.9, -0.3), (0.95, -0.5)], [0.14, 0.08, 0.02]), 0.1)
    legs = U(oval(-0.28, -0.56, 0.14, 0.2), oval(0.0, -0.58, 0.14, 0.18), oval(0.42, -0.58, 0.14, 0.18), oval(0.68, -0.56, 0.14, 0.2))
    frill = sub(oval(-0.26, 0.2, 0.34, 0.5, 0.35), head)
    frill = U(frill, *[circle(-0.26 + 0.4 * math.cos(a + 0.35 + math.pi / 2), 0.2 + 0.58 * math.sin(a + 0.35 + math.pi / 2), 0.07) for a in (-0.7, -0.35, 0.0, 0.35, 0.7)])
    horns = U(poly([(-0.52, 0.12), (-0.36, 0.14), (-0.62, 0.62)]), poly([(-0.76, -0.02), (-0.66, 0.06), (-0.92, 0.3)]), poly([(-0.42, 0.14), (-0.26, 0.1), (-0.4, 0.58)]))
    face = U(circle(-0.52, 0.06, 0.05), circle(-0.8, -0.1, 0.03))
    hide = U(body, legs)
    return [hide, frill, horns, face]


@sticker("dino", "longneck", "Long-neck", ["#5BA8E0", "#2F6FB0", "#FFF4C7", "#1A1410"], ink=1.0)
def _():
    body = smin(oval(0.1, -0.28, 0.55, 0.3), brush([(-0.3, -0.2), (-0.48, 0.2), (-0.34, 0.56), (-0.5, 0.76)], [0.22, 0.14, 0.1, 0.1]), 0.15)
    body = U(smin(body, oval(-0.62, 0.78, 0.2, 0.12, 0.25), 0.08), brush([(0.55, -0.25), (0.78, -0.4), (0.92, -0.62)], [0.15, 0.09, 0.03]),
             oval(-0.2, -0.68, 0.14, 0.2), oval(0.4, -0.68, 0.14, 0.2))
    shade = U(_rim(oval(0.1, -0.28, 0.55, 0.3), 0.08), oval(0.18, -0.68, 0.14, 0.2), oval(0.55, -0.68, 0.0001, 0.0001))
    shade = U(shade, sub(oval(0.18, -0.68, 0.14, 0.2), oval(-0.1, -0.5, 0.2, 0.3)))
    spots = U(circle(0.0, -0.22, 0.08), circle(0.25, -0.3, 0.07), circle(0.42, -0.2, 0.06), circle(-0.4, 0.3, 0.05))
    face = U(circle(-0.66, 0.8, 0.04), circle(-0.8, 0.77, 0.02))
    return [body, shade, spots, face]


@sticker("dino", "stego", "Stegosaurus", ["#F2A33A", "#C2391F", "#FFF4C7", "#1A1410"], ink=1.0)
def _():
    body = smin(smin(oval(0.05, -0.18, 0.6, 0.36), oval(-0.7, -0.22, 0.22, 0.13, -0.15), 0.1), brush([(0.55, -0.2), (0.8, -0.2), (0.93, -0.05)], [0.16, 0.1, 0.04]), 0.1)
    legs = U(oval(-0.3, -0.6, 0.14, 0.16), oval(0.0, -0.6, 0.14, 0.16), oval(0.35, -0.6, 0.14, 0.16), oval(0.58, -0.58, 0.12, 0.16))
    plates = U(*[poly([(x - 0.15, y0), (x - 0.03, y0 + h), (x + 0.15, y0 + 0.02)]) for x, y0, h in ((-0.38, 0.06, 0.42), (-0.1, 0.12, 0.56), (0.2, 0.12, 0.56), (0.48, 0.02, 0.42))])
    spikes = U(poly([(0.7, -0.1), (0.76, 0.02), (0.82, -0.12)]), poly([(0.86, -0.04), (0.94, 0.1), (0.96, -0.08)]))
    belly = U(_rim(oval(0.05, -0.18, 0.6, 0.36), 0.09), spikes)
    face = circle(-0.74, -0.2, 0.04)
    hide = U(body, legs)
    return [hide, plates, belly, face]


@sticker("dino", "ptero", "Pterodactyl", ["#FF7A59", "#2FA89A", "#FFD400", "#1A1410"], ink=1.0)
def _():
    wings = U(poly([(-0.1, 0.1), (-0.84, 0.5), (-0.78, 0.2), (-0.62, 0.3), (-0.58, 0.0), (-0.42, 0.1), (-0.3, -0.24), (-0.1, -0.24)]),
              poly([(0.1, 0.1), (0.84, 0.5), (0.78, 0.2), (0.62, 0.3), (0.58, 0.0), (0.42, 0.1), (0.3, -0.24), (0.1, -0.24)]))
    body = U(oval(0, -0.12, 0.26, 0.42), oval(0, 0.3, 0.2, 0.2), brush([(0, -0.4), (0, -0.64), (0.0, -0.82)], [0.12, 0.07, 0.03]))
    beak = U(poly([(-0.11, 0.36), (0.11, 0.36), (0.0, 0.9)]), poly([(-0.12, 0.3), (-0.3, 0.1), (-0.08, 0.14)]), poly([(0.12, 0.3), (0.3, 0.1), (0.08, 0.14)]))
    face = U(circle(-0.075, 0.34, 0.04), circle(0.075, 0.34, 0.04))
    return [wings, body, beak, face]


@sticker("dino", "egg", "Cracking egg", ["#F4E3C8", "#7BC96F", "#FFE14A", "#1A1410"], ink=1.0)
def _():
    egg = oval(0, -0.04, 0.62, 0.84)
    freckles = inter(egg, U(circle(-0.34, -0.4, 0.12), circle(0.32, -0.56, 0.1), circle(-0.14, -0.7, 0.08), circle(0.4, -0.2, 0.09), circle(-0.4, 0.4, 0.08), circle(0.3, 0.5, 0.07)))
    zig = [(-0.5, 0.1), (-0.28, -0.1), (-0.1, 0.12), (0.12, -0.12), (0.3, 0.08), (0.5, -0.1)]
    glow = inter(egg, polyline(zig, 0.12))
    crack = inter(egg, polyline(zig, 0.05))
    return [egg, freckles, glow, crack]


@sticker("dino", "footprint", "Footprint", ["#9A6B3F", "#6B4526", "#5A3A22", "#C79A66"], ink=1.0)
def _():
    slab = circle(0, 0, 0.88)
    shade = _rim(slab, 0.1)
    toes = U(taper(-0.36, 0.1, -0.54, 0.56, 0.16, 0.05), taper(0.0, 0.14, 0.0, 0.68, 0.17, 0.05), taper(0.36, 0.1, 0.54, 0.56, 0.16, 0.05))
    print_ = U(toes, oval(0, -0.2, 0.38, 0.32), poly([(-0.22, -0.44), (0.22, -0.44), (0.0, -0.68)]))
    shine = U(seg(-0.62, 0.36, -0.42, 0.58, 0.05))
    return [slab, shade, print_, shine]


@sticker("dino", "volcano", "Volcano", ["#9AA0AC", "#8A5A33", "#FF5A1F", "#FFE14A"], ink=1.0)
def _():
    smoke = U(circle(-0.24, 0.62, 0.22), circle(0.0, 0.76, 0.2), circle(0.24, 0.6, 0.22), circle(-0.04, 0.54, 0.24), circle(0.4, 0.78, 0.12))
    cone = poly([(-0.9, -0.75), (-0.28, 0.14), (0.28, 0.14), (0.9, -0.75)]) - 0.04
    lava = U(brush([(0.0, 0.14), (-0.06, -0.2), (0.12, -0.45), (0.04, -0.72)], [0.14, 0.09, 0.08, 0.06]), brush([(0.14, 0.12), (0.4, -0.2), (0.45, -0.7)], [0.07, 0.06, 0.05]),
             box(0, 0.16, 0.34, 0.06, 0.03), circle(-0.1, 0.34, 0.1), circle(0.14, 0.4, 0.08))
    sparks = U(circle(-0.18, 0.5, 0.05), circle(0.1, 0.48, 0.05), circle(0.0, 0.24, 0.08), seg(-0.04, -0.12, 0.0, -0.4, 0.035))
    return [smoke, cone, lava, sparks]


@sticker("dino", "fossil", "Fossil skull", ["#F4F1EA", "#C9C3B6", "#2B2E33", "#FFFFFF"], ink=1.0)
def _():
    skull = U(smin(oval(0.28, 0.16, 0.54, 0.44), oval(-0.34, 0.1, 0.48, 0.27), 0.18), oval(-0.26, -0.5, 0.6, 0.14, 0.06),
              *[poly([(x - 0.075, -0.14), (x + 0.075, -0.14), (x, -0.34)]) for x in (-0.68, -0.5, -0.32, -0.14)],
              *[poly([(x - 0.065, -0.38), (x + 0.065, -0.38), (x, -0.24)]) for x in (-0.6, -0.42, -0.24)],
              box(0.55, -0.26, 0.12, 0.16))
    shade = _rim(skull, 0.09)
    sockets = U(circle(0.3, 0.2, 0.16), oval(-0.74, 0.14, 0.07, 0.05), seg(0.0, 0.46, 0.55, 0.52, 0.04))
    return [skull, shade, sockets, None]


@sticker("dino", "baby", "Baby dino", ["#7BC96F", "#F4E3C8", "#C98B4B", "#1A1410"], ink=1.0)
def _():
    head = U(circle(0, 0.12, 0.42), *[poly([(x - 0.07, 0.5), (x + 0.07, 0.5), (x, 0.66)]) for x in (-0.16, 0.0, 0.16)], circle(-0.4, -0.16, 0.12), circle(0.4, -0.16, 0.12))
    cup = sub(oval(0, -0.4, 0.62, 0.5), U(*[poly([(x, -0.2), (x + 0.2, -0.2), (x + 0.1, -0.02)]) for x in (-0.6, -0.2, 0.2)], box(0, 0.1, 1.0, 0.28)))
    cap = sub(oval(0.28, 0.5, 0.36, 0.3, -0.5), circle(0.1, 0.12, 0.44))
    spots = U(circle(-0.3, -0.5, 0.07), circle(0.2, -0.6, 0.06), circle(0.4, -0.4, 0.05), circle(0.34, 0.66, 0.04))
    shell_ = U(cup, cap)
    face = U(circle(-0.16, 0.14, 0.08), circle(0.16, 0.14, 0.08), arc(0, 0.0, 0.1, -3.0, -0.14, 0.03))
    return [head, shell_, spots, face]


@sticker("dino", "shades", "Cool dino", ["#F0709A", "#FFD400", "#1A1410", "#FFFFFF"], ink=1.0)
def _():
    head = smin(circle(0, 0.1, 0.56), oval(0, -0.3, 0.6, 0.34), 0.16)
    crest = U(poly([(-0.14, 0.58), (0.0, 0.88), (0.14, 0.58)]), poly([(-0.4, 0.5), (-0.34, 0.76), (-0.18, 0.56)]), poly([(0.4, 0.5), (0.34, 0.76), (0.18, 0.56)]),
              _rim(head, 0.08), circle(-0.16, -0.12, 0.04), circle(0.16, -0.12, 0.04))
    glasses = U(box(-0.28, 0.16, 0.25, 0.15, 0.06), box(0.28, 0.16, 0.25, 0.15, 0.06), seg(-0.06, 0.2, 0.06, 0.2, 0.045), seg(-0.52, 0.2, -0.62, 0.26, 0.04),
                arc(0, -0.3, 0.3, -2.9, -0.24, 0.035))
    glints = U(seg(-0.42, 0.22, -0.3, 0.22, 0.035), seg(0.14, 0.22, 0.26, 0.22, 0.035), *[poly([(x - 0.045, -0.3), (x + 0.045, -0.3), (x, -0.4)]) for x in (-0.18, -0.06, 0.06, 0.18)])
    return [head, crest, glasses, glints]


@sticker("dino", "meteor", "Meteor", ["#FF5A1F", "#8A8F98", "#5A6070", "#FFE14A"], ink=1.0)
def _():
    flame = U(brush([(-0.2, -0.15), (0.2, 0.2), (0.38, 0.38), (0.66, 0.58)], [0.46, 0.34, 0.22, 0.03]), brush([(-0.1, -0.35), (0.3, -0.12), (0.6, -0.05), (0.78, 0.06)], [0.28, 0.2, 0.1, 0.02]),
              brush([(-0.35, 0.0), (-0.28, 0.35), (-0.1, 0.62), (0.0, 0.9)], [0.2, 0.15, 0.08, 0.02]))
    rock = smin(smin(circle(-0.3, -0.28, 0.48), circle(-0.58, -0.08, 0.28), 0.1), circle(-0.08, -0.56, 0.26), 0.1)
    craters = U(circle(-0.42, -0.2, 0.09), circle(-0.2, -0.4, 0.07), circle(-0.5, -0.42, 0.06))
    glow = sub(U(brush([(0.05, 0.0), (0.35, 0.3), (0.6, 0.5)], [0.2, 0.12, 0.03]), brush([(0.1, -0.3), (0.45, -0.12)], [0.12, 0.04])), rock)
    return [flame, rock, craters, glow]


def _fernpt(t):
    """A point on the fern's curved stem."""
    return ((1 - t) ** 2 * -0.35 + 2 * (1 - t) * t * -0.3 + t * t * 0.5, (1 - t) ** 2 * -0.88 + 2 * (1 - t) * t * 0.1 + t * t * 0.78)


@sticker("dino", "fern", "Fern", ["#3FA34D", "#2A7A3A", "#8A5A33", "#9AE05A"], ink=1.0)
def _():
    stem = polyline([_fernpt(k / 30) for k in range(31)], 0.045)
    leaves, rims, tips = [], [], []
    for i in range(1, 10):
        t = i / 10.2
        px, py = _fernpt(t)
        qx, qy = _fernpt(min(1.0, t + 0.02))
        tang = math.atan2(qy - py, qx - px)
        ln = 0.5 * (1 - t) + 0.14
        for side in (1, -1):
            ang = tang + side * (math.pi / 2 - 0.55)
            cx, cy = px + math.cos(ang) * ln * 0.5, py + math.sin(ang) * ln * 0.5
            leaves.append(oval(cx, cy, ln * 0.5 + 0.02, 0.085, ang))
            tips.append(seg(cx - math.cos(ang) * ln * 0.2, cy - math.sin(ang) * ln * 0.2 + 0.04, cx + math.cos(ang) * ln * 0.15, cy + math.sin(ang) * ln * 0.15 + 0.04, 0.02) if side == 1 else BIG + 0 * X)
    fronds = U(*leaves, brush([_fernpt(0.95), (0.52, 0.8)], [0.07, 0.03]) if False else seg(0.48, 0.74, 0.52, 0.8, 0.05))
    shade = U(*[_rim(l, 0.05) for l in leaves[:: 2]])
    veins = inter(shade, fronds)
    sprigs = U(*tips)
    return [fronds, veins, stem, sprigs]


@sticker("dino", "claw", "Raptor claw", ["#6BBF59", "#F1DFB8", "#2F7A32", "#FFFFFF"], ink=1.0)
def _():
    foot = U(oval(0.0, 0.0, 0.46, 0.36), taper(-0.28, -0.12, -0.56, -0.56, 0.17, 0.13), taper(0.0, -0.18, 0.0, -0.58, 0.17, 0.13), taper(0.28, -0.12, 0.56, -0.56, 0.17, 0.13))
    claws = U(brush([(0.2, 0.2), (0.34, 0.62), (0.72, 0.58), (0.86, 0.12)], [0.2, 0.16, 0.1, 0.025]),
              poly([(-0.46, -0.58), (-0.66, -0.52), (-0.7, -0.8)]), poly([(-0.1, -0.6), (0.1, -0.6), (0.0, -0.82)]), poly([(0.46, -0.58), (0.66, -0.52), (0.7, -0.8)]))
    scales = U(seg(-0.12, 0.2, 0.12, 0.2, 0.04), seg(-0.4, -0.36, -0.28, -0.3, 0.04), seg(-0.06, -0.38, 0.06, -0.38, 0.04), seg(0.4, -0.36, 0.28, -0.3, 0.04), _rim(foot, 0.07))
    shine = U(seg(0.3, 0.44, 0.48, 0.54, 0.045))
    return [foot, claws, scales, shine]


@sticker("dino", "amber", "Amber", ["#FFB000", "#D98A00", "#FFE9A8", "#4A2A14"], ink=1.0)
def _():
    stone = poly(spline([(-0.7, 0.2), (-0.36, 0.7), (0.24, 0.78), (0.7, 0.3), (0.74, -0.3), (0.3, -0.74), (-0.3, -0.7), (-0.76, -0.3)], True, 8))
    shade = _rim(stone, 0.12)
    core = U(seg(-0.5, 0.42, -0.3, 0.64, 0.06), circle(-0.64, 0.22, 0.05))
    bug = U(oval(0.04, -0.08, 0.34, 0.15, 0.2), circle(-0.34, 0.0, 0.12), oval(0.1, 0.22, 0.24, 0.1, 0.9), oval(-0.1, 0.22, 0.24, 0.1, 2.2),
            seg(-0.08, -0.2, -0.2, -0.42, 0.04), seg(0.1, -0.22, 0.08, -0.46, 0.04), seg(0.3, -0.14, 0.52, -0.26, 0.04))
    return [stone, shade, core, bug]


@sticker("dino", "rawr", "RAWR", ["#4FC36B", "#2E8F4A", "#FFFFFF", "#FFE14A"], ink=1.0)
def _():
    letters = text("RAWR", 0, -0.08, 0.9, stretch=0.62, maxw=1.65)
    spikes = U(*[poly([(x - 0.13, 0.28), (x + 0.13, 0.28), (x, 0.7)]) for x in (-0.66, -0.22, 0.22, 0.66)])
    plate = U(letters - 0.07, spikes)
    shade = _rim(plate, 0.09)
    shine = U(seg(-0.74, 0.14, -0.56, 0.3, 0.045))
    word = letters
    return [plate, shade, shine, word]
