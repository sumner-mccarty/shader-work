# Skate & Surf — boards, wheels, ramps and the sea. Run by Tools/decor_stickers.py (every helper is in scope).
PACK = ("skate", "Skate & Surf", False)
PRO_IDS = {"barrel", "halfpipe", "shaka", "island", "shades", "crab"}


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


def _side_board(cx, cy, length, ang, thick=0.085, wheel=0.13):
    """A skateboard in profile: kicked deck, trucks, wheels (three distance fields)."""
    with rotated(ang, cx, cy):
        h = length / 2
        deck = brush([(cx - h, cy + 0.16), (cx - h * 0.72, cy), (cx + h * 0.72, cy), (cx + h, cy + 0.16)],
                     [thick * 0.8, thick, thick, thick * 0.8])
        trucks = U(*[poly([(cx + s * h * 0.5 - 0.11, cy - thick), (cx + s * h * 0.5 + 0.11, cy - thick),
                           (cx + s * h * 0.5 + 0.05, cy - thick - 0.12), (cx + s * h * 0.5 - 0.05, cy - thick - 0.12)])
                     for s in (-1, 1)])
        wheels = U(*[circle(cx + s * h * 0.5, cy - thick - 0.12 - wheel * 0.55, wheel) for s in (-1, 1)])
    return deck, trucks, wheels


@sticker("skate", "ollie", "Ollie", ["#FF5A1F", "#C9CED6", "#FFD23F", "#FFFFFF"], ink=1.0)
def _():
    board, trucks, wheels = _side_board(0.2, 0.2, 1.4, 0.36, thick=0.13, wheel=0.17)
    swoosh = U(brush([(-0.22, -0.2), (-0.56, -0.36), (-0.9, -0.3)], [0.09, 0.06, 0.02]),
               brush([(-0.42, 0.02), (-0.7, -0.06), (-0.92, 0.0)], [0.07, 0.05, 0.02]))
    deck = U(board, swoosh)
    shine = seg(-0.26, 0.04, 0.34, 0.26, 0.03)
    return [deck, trucks, wheels, shine]


@sticker("skate", "wheel", "Wheel", ["#FFD23F", "#E09A12", "#EEF0F3", "#2B2E33"], ink=1.0)
def _():
    face = oval(-0.24, 0.0, 0.44, 0.8)
    wheel = U(face, oval(0.24, 0.0, 0.44, 0.8), box(0, 0, 0.24, 0.8))
    tread = sub(wheel, face)
    bearing = oval(-0.24, 0.0, 0.25, 0.44)
    hole = U(oval(-0.24, 0.0, 0.11, 0.2), *[circle(-0.24 + 0.18 * math.cos(a), 0.32 * math.sin(a), 0.03) for a in (0.8, 2.35, 3.9, 5.5)])
    return [wheel, tread, bearing, hole]


@sticker("skate", "halfpipe", "Half-pipe", ["#E9B872", "#9A5F2C", "#C9CED6", "#FF3D7F"], ink=1.0)
def _():
    cut = U(circle(-0.26, 0.2, 0.5), circle(0.26, 0.2, 0.5), box(0, 0.6, 0.26, 0.4))
    ramp = sub(box(0, -0.36, 0.88, 0.52, 0.06), cut)
    shade = U(_rim(ramp, 0.08), inter(ramp, cut - 0.1), *[inter(ramp, box(x, -0.36, 0.028, 0.6)) for x in (-0.6, 0.6)])
    coping = U(circle(-0.76, 0.16, 0.075), circle(0.76, 0.16, 0.075), box(-0.82, 0.13, 0.06, 0.04), box(0.82, 0.13, 0.06, 0.04))
    deck, trucks, wheels = _side_board(-0.36, 0.14, 0.96, -0.72, thick=0.085, wheel=0.11)
    board = U(deck, trucks, wheels)
    return [ramp, shade, coping, board]


@sticker("skate", "barrel", "Barrel wave", ["#1FB6C9", "#138A9E", "#0B3E66", "#FFFFFF"], ink=1.0)
def _():
    cx, cy = -0.42, 0.06
    water = poly(spline([(-0.82, -0.44), (0.84, -0.44), (0.84, -0.18), (0.54, 0.08), (0.16, 0.34), (-0.3, 0.5), (-0.64, 0.44),
                         (-0.82, 0.24), (-0.86, -0.04), (-0.78, -0.22), (-0.84, -0.34)], n=8))
    shade = U(_rim(water, 0.1), inter(water, box(0, -0.42, 1.0, 0.06)))
    hollow = sub(circle(cx, cy, 0.32), circle(cx + 0.1, cy - 0.08, 0.2))
    foam = U(arc(cx, cy, 0.4, math.radians(-10), math.radians(235), 0.085),
             brush([(cx + 0.36, cy + 0.2), (0.2, 0.3), (0.62, 0.04)], [0.08, 0.06, 0.025]),
             circle(cx + 0.4 * math.cos(math.radians(235)), cy + 0.4 * math.sin(math.radians(235)), 0.1))
    return [water, shade, hollow, foam]


@sticker("skate", "surfboard", "Surfboard", ["#2EC4B6", "#1B8A80", "#FF5A1F", "#FFFFFF"], ink=1.0)
def _():
    with rotated(-0.62):
        board = poly(spline([(0, 0.92), (0.22, 0.58), (0.27, 0.0), (0.22, -0.6), (0.1, -0.86), (-0.1, -0.86), (-0.22, -0.6),
                             (-0.27, 0.0), (-0.22, 0.58)], n=10))
        stripes_ = inter(board, U(box(0, 0.36, 0.4, 0.06), box(0, 0.18, 0.4, 0.035), box(0, -0.62, 0.4, 0.06)))
        shine = U(seg(-0.13, 0.5, -0.17, -0.1, 0.03), circle(-0.1, 0.66, 0.03))
    shade = _rim(board, 0.08)
    return [board, shade, stripes_, shine]


@sticker("skate", "shades", "Wraparounds", ["#FF3D7F", "#FFD23F", "#1A1C22", "#FFFFFF"], ink=1.0)
def _():
    visor = poly(spline([(-0.88, 0.16), (-0.5, 0.3), (0, 0.32), (0.5, 0.3), (0.88, 0.16), (0.82, -0.1), (0.52, -0.32), (0.18, -0.28),
                         (0, -0.12), (-0.18, -0.28), (-0.52, -0.32), (-0.82, -0.1)], n=8))
    mirror = inter(visor, stripes(0.32, -0.45, 0.34, 0.08))
    frame = U(brush([(-0.9, 0.14), (-0.5, 0.32), (0, 0.35), (0.5, 0.32), (0.9, 0.14)], [0.05, 0.075, 0.075, 0.075, 0.05]),
              box(0, -0.05, 0.05, 0.08, 0.03))
    shine = U(seg(-0.62, 0.08, -0.4, 0.13, 0.035), seg(0.28, 0.1, 0.44, 0.13, 0.03))
    return [visor, mirror, frame, shine]


@sticker("skate", "island", "Palm island", ["#2E9BE0", "#F2D49B", "#8A5A33", "#2E9E4F"], ink=1.0)
def _():
    sea = oval(0, -0.6, 0.9, 0.24)
    sand = U(inter(oval(-0.06, -0.52, 0.6, 0.3), Y + 0.6), oval(-0.06, -0.58, 0.6, 0.1))
    trunk = brush([(-0.1, -0.42), (0.0, -0.05), (0.18, 0.3), (0.3, 0.5)], [0.085, 0.075, 0.065, 0.06])
    fronds = U(*[brush(pts, [0.04, 0.12, 0.04]) for pts in [
        [(0.3, 0.52), (-0.1, 0.72), (-0.5, 0.56)], [(0.3, 0.52), (0.6, 0.8), (0.88, 0.62)], [(0.3, 0.52), (-0.1, 0.42), (-0.38, 0.2)],
        [(0.3, 0.52), (0.7, 0.42), (0.86, 0.14)], [(0.3, 0.52), (0.22, 0.82), (0.0, 0.92)]]], circle(0.26, 0.46, 0.08))
    return [sea, sand, trunk, fronds]


@sticker("skate", "shaka", "Shaka", ["#FFC24A", "#E0901A", "#7A3E12", "#2EC4B6"], ink=1.0)
def _():
    with rotated(-0.25):
        palm = box(0.02, -0.12, 0.36, 0.36, 0.18)
        knuckles = U(*[box(x, 0.22, 0.1, 0.15, 0.09) for x in (-0.19, 0.02, 0.23)])
        thumb = U(taper(-0.22, -0.1, -0.66, 0.42, 0.16, 0.13), circle(-0.66, 0.42, 0.13))
        pinky = U(taper(0.28, 0.12, 0.72, 0.44, 0.11, 0.095), circle(0.72, 0.44, 0.095))
        wrist = box(0.04, -0.62, 0.24, 0.2, 0.06)
        hand = U(palm, knuckles, thumb, pinky, box(0.04, -0.42, 0.22, 0.12))
        creases = U(seg(-0.085, 0.3, -0.085, 0.1, 0.022), seg(0.125, 0.3, 0.125, 0.1, 0.022), arc(-0.3, -0.05, 0.16, 0.2, 1.4, 0.022))
        cuff = U(wrist, box(0.04, -0.5, 0.25, 0.04))
    shade = _rim(hand, 0.08)
    return [hand, shade, creases, cuff]


@sticker("skate", "helmet", "Helmet", ["#FF3D7F", "#C2185B", "#1A1C22", "#FFFFFF"], ink=1.0)
def _():
    shell_ = U(inter(oval(0.0, -0.02, 0.84, 0.8), box(0, 0.38, 1.0, 0.62)), box(0.0, -0.22, 0.84, 0.08, 0.06))
    shade = _rim(shell_, 0.1)
    vents = U(*[box(x, y, 0.065, 0.16, 0.06, a) for x, y, a in [(-0.36, 0.44, 0.5), (-0.06, 0.56, 0.1), (0.26, 0.5, -0.4)]],
              brush([(-0.3, -0.26), (-0.22, -0.5), (-0.06, -0.66)], [0.08, 0.08, 0.08]), box(0.02, -0.68, 0.11, 0.08, 0.03))
    stripe = U(inter(shell_, box(0, 0.12, 1.0, 0.06)), arc(0, -0.02, 0.66, math.radians(115), math.radians(150), 0.04))
    return [shell_, shade, vents, stripe]


@sticker("skate", "griptape", "Grip tape", ["#26282E", "#C98B4B", "#A4AAB4", "#FFFFFF"], ink=1.0)
def _():
    roll = U(circle(-0.18, 0.18, 0.64), poly([(-0.18, -0.46), (0.88, -0.46), (0.8, -0.56), (0.9, -0.66), (0.8, -0.74), (0.9, -0.84),
                                              (-0.1, -0.84)]))
    core = sub(circle(-0.18, 0.18, 0.28), circle(-0.18, 0.18, 0.16))
    grit = U(ring(-0.18, 0.18, 0.56, 0.05), *[circle(x, y, 0.05) for x, y in [(-0.58, 0.36), (-0.44, -0.2), (0.16, 0.48), (0.24, 0.02),
                                                                               (-0.62, -0.04), (0.04, -0.24)]])
    shine = arc(-0.18, 0.18, 0.44, math.radians(110), math.radians(165), 0.045)
    return [roll, core, grit, shine]


@sticker("skate", "fin", "Fin", ["#6B7C93", "#46546B", "#2E9BE0", "#FFFFFF"], ink=1.0)
def _():
    fin = poly(spline([(-0.52, -0.3), (-0.3, 0.16), (-0.02, 0.58), (0.2, 0.84), (0.22, 0.56), (0.3, 0.16), (0.46, -0.3)], n=10))
    shade = inter(fin, poly([(0.08, 0.9), (0.7, 0.9), (0.7, -0.4), (0.18, -0.4)]))
    water = U(box(0, -0.58, 0.88, 0.26, 0.1), *[circle(x, -0.36, 0.13) for x in np.linspace(-0.74, 0.74, 5)])
    foam = U(arc(-0.62, -0.5, 0.2, math.radians(30), math.radians(150), 0.045), arc(0.62, -0.5, 0.2, math.radians(30), math.radians(150), 0.045),
             seg(-0.54, -0.28, 0.48, -0.28, 0.06), seg(-0.2, -0.66, 0.24, -0.66, 0.04))
    return [fin, shade, water, foam]


@sticker("skate", "sun", "Hot sun", ["#FFD23F", "#FF8A00", "#FF5A1F", "#FFFFFF"], ink=1.0)
def _():
    rays = U(*[brush(rotp([(0.48, 0.0), (0.7, 0.14), (0.9, 0.06)], k * math.pi / 5), [0.13, 0.09, 0.04]) for k in range(10)])
    disc = circle(0, 0, 0.5)
    sun = U(disc, rays)
    flares = U(inter(rays, -disc), _rim(disc, 0.1))
    glow = inter(disc, circle(0.1, -0.1, 0.36))
    shine = U(arc(0, 0, 0.36, math.radians(110), math.radians(165), 0.06), circle(-0.12, 0.38, 0.04))
    return [sun, flares, glow, shine]


@sticker("skate", "wax", "Surf wax", ["#F4E3C8", "#FFF8EC", "#D9B98A", "#1A1C22"], ink=1.0)
def _():
    bar = U(box(0, -0.18, 0.86, 0.5, 0.16), *[circle(x, 0.26, 0.12) for x in np.linspace(-0.66, 0.66, 6)])
    top = inter(bar, box(0, 0.36, 1.0, 0.16))
    shade = _rim(bar, 0.1)
    word = text("WAX", 0, -0.22, 0.48, maxw=1.5) - 0.012
    return [bar, top, shade, word]


@sticker("skate", "cone", "Cone", ["#FF6B1A", "#FFFFFF", "#2B2E33", "#E0520F"], ink=1.0)
def _():
    cone = U(poly([(-0.14, 0.84), (0.14, 0.84), (0.48, -0.56), (-0.48, -0.56)]), circle(0, 0.82, 0.14))
    bands = inter(cone, U(box(0, 0.34, 0.6, 0.11), box(0, -0.14, 0.6, 0.12)))
    base = box(0, -0.68, 0.84, 0.14, 0.06)
    shade = inter(cone, X - 0.12)
    return [cone, bands, base, shade]


@sticker("skate", "rad", "RAD", ["#FF3D7F", "#1A1C22", "#FFD23F", "#FFFFFF"], ink=1.0)
def _():
    slab = U(box(0, 0.12, 0.9, 0.5, 0.12), taper(-0.56, -0.3, -0.56, -0.62, 0.1, 0.075), circle(-0.56, -0.64, 0.085),
             taper(0.12, -0.3, 0.12, -0.8, 0.1, 0.075), circle(0.12, -0.82, 0.085), taper(0.62, -0.3, 0.62, -0.52, 0.09, 0.07),
             circle(0.62, -0.54, 0.075))
    word = text("RAD", 0, 0.12, 0.62, maxw=1.5) - 0.015
    shadow = _moved(word, 0.05, -0.05) - 0.02
    shine = U(seg(-0.74, 0.5, -0.5, 0.5, 0.035), circle(-0.56, -0.56, 0.03))
    return [slab, shadow, word, shine]


@sticker("skate", "shred", "SHRED", ["#2EC4B6", "#1A1C22", "#FFFFFF", "#FF5A1F"], ink=1.0)
def _():
    with rotated(0.1):
        tape = poly([(-0.9, 0.44), (-0.74, 0.52), (-0.5, 0.44), (-0.22, 0.52), (0.06, 0.44), (0.34, 0.52), (0.62, 0.45), (0.9, 0.5),
                     (0.86, -0.44), (0.62, -0.52), (0.34, -0.44), (0.06, -0.52), (-0.22, -0.44), (-0.5, -0.52), (-0.86, -0.46)])
        edge = inter(tape, U(box(0, 0.52, 1.0, 0.08), box(0, -0.52, 1.0, 0.08)))
    word = text("SHRED", 0, 0.0, 0.56, ang=0.1, stretch=0.8, maxw=1.66)
    shadow = _moved(word, 0.045, -0.045) - 0.03
    return [tape, shadow, word, edge]


@sticker("skate", "flipflops", "Flip-flops", ["#FF3D7F", "#C2185B", "#FFD23F", "#FFFFFF"], ink=1.0)
def _():
    soles = U(*[poly(spline([(cx, 0.82), (cx + 0.24, 0.62), (cx + 0.2, 0.0), (cx + 0.22, -0.5), (cx, -0.84), (cx - 0.22, -0.5),
                             (cx - 0.18, 0.0), (cx - 0.24, 0.62)], n=8)) for cx in (-0.38, 0.38)])
    shade = _rim(soles, 0.08)
    straps = U(*[U(bezier((cx, 0.42), (cx - 0.24, 0.3), (cx - 0.2, 0.02), 0.045), bezier((cx, 0.42), (cx + 0.24, 0.3), (cx + 0.2, 0.02), 0.045))
                 for cx in (-0.38, 0.38)])
    flowers = U(*[U(petals(cx, 0.42, 5, 0.07, 0.065, 0.045), circle(cx, 0.42, 0.04)) for cx in (-0.38, 0.38)])
    return [soles, shade, straps, flowers]


@sticker("skate", "crab", "Beach crab", ["#FF5A3D", "#C2311B", "#FFFFFF", "#1A1C22"], ink=1.0)
def _():
    shell_ = oval(0, -0.18, 0.52, 0.34)
    claws = U(*[U(sub(circle(sx * 0.64, 0.38, 0.22), poly([(sx * 0.64, 0.36), (sx * 0.98, 0.72), (sx * 0.98, 0.3)])),
                  brush([(sx * 0.36, -0.08), (sx * 0.58, 0.04), (sx * 0.62, 0.22)], [0.08, 0.075, 0.08])) for sx in (-1, 1)])
    legs = U(*[brush([(sx * 0.4, -0.3 - k * 0.1), (sx * 0.7, -0.4 - k * 0.12), (sx * 0.8, -0.6 - k * 0.1)], [0.06, 0.05, 0.025])
               for sx in (-1, 1) for k in range(2)])
    stalks = U(seg(-0.16, -0.0, -0.18, 0.26, 0.05), seg(0.16, -0.0, 0.18, 0.26, 0.05))
    crab = U(shell_, claws, legs, stalks)
    shade = _rim(crab, 0.08)
    eyes = U(circle(-0.19, 0.3, 0.12), circle(0.19, 0.3, 0.12))
    face = U(circle(-0.16, 0.3, 0.055), circle(0.22, 0.3, 0.055), arc(0, -0.12, 0.18, math.radians(200), math.radians(340), 0.04))
    return [crab, shade, eyes, face]