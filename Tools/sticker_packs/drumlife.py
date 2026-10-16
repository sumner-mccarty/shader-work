# Drum Life — the drummer's side of the stage: sticks, pads, keys, plugs and blisters. Run by Tools/decor_stickers.py
# (every helper is in scope). Not the Music pack's instruments: no kick, hi-hat, vinyl, cassette, mic, turntable, keys …
PACK = ("drumlife", "Drum Life", False)
PRO_IDS = {"rimshot", "crash", "clicktrack", "bpm", "fourcount", "blister"}


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


def _stick(ax, ay, bx, by, rb=0.075):
    """A drumstick from butt (ax, ay) to tip (bx, by): (shaft, tip)."""
    L = math.hypot(bx - ax, by - ay)
    ux, uy = (bx - ax) / L, (by - ay) / L
    sx, sy = bx - ux * 0.12, by - uy * 0.12
    shaft = U(taper(ax, ay, sx, sy, rb, rb * 0.5), circle(ax, ay, rb))
    tip = oval(bx - ux * 0.06, by - uy * 0.06, 0.085, rb * 0.78, math.atan2(uy, ux))
    return shaft, tip


@sticker("drumlife", "crest", "Stick crest", ["#E9C9A3", "#F5C242", "#B8860B", "#FFFFFF"], ink=1.0)
def _():
    a, at = _stick(-0.62, -0.78, 0.62, 0.74, 0.1)
    b, bt = _stick(0.62, -0.78, -0.62, 0.74, 0.1)
    sticks = U(a, b, at, bt)
    shield = U(poly([(-0.52, 0.56), (-0.18, 0.56), (0.0, 0.66), (0.18, 0.56), (0.52, 0.56), (0.52, 0.02), (0.0, -0.66), (-0.52, 0.02)]) - 0.03)
    shade = _rim(shield, 0.1)
    emblem = U(star(0, 0.06, 5, 0.3, 0.13), polyline([(-0.4, 0.04), (-0.4, 0.44), (-0.12, 0.44)], 0.055))
    return [sticks, shield, shade, emblem]


@sticker("drumlife", "rimshot", "Rimshot", ["#1B6FE0", "#0B3E8C", "#FFFFFF", "#E9C9A3"], ink=1.0)
def _():
    shell_ = U(oval(0, 0.1, 0.86, 0.46), oval(0, -0.26, 0.86, 0.46), box(0, -0.08, 0.86, 0.18))
    shade = U(sub(shell_, U(oval(0, 0.1, 0.86, 0.46), box(-0.3, -0.2, 0.6, 0.4))), inter(_rim(shell_, 0.08), shell_))
    head = U(oval(0, 0.12, 0.76, 0.38), star(0.62, 0.4, 8, 0.3, 0.12, 0.3), arc(0, -0.08, 0.76, math.radians(188), math.radians(222), 0.06))
    shaft, tip = _stick(0.8, 0.8, 0.36, 0.22, 0.11)
    stick = U(shaft, tip)
    return [shell_, shade, head, stick]


@sticker("drumlife", "crash", "Crash", ["#F5C242", "#B8860B", "#FFFFFF", "#E9C9A3"], ink=1.0)
def _():
    cymbal = oval(-0.08, 0.14, 0.78, 0.38, 0.35)
    shade = U(inter(cymbal, box(0.02, -0.34, 1.2, 0.46, 0.0, 0.35)), shell(oval(-0.08, 0.14, 0.5, 0.25, 0.35), 0.024),
              oval(-0.08, 0.18, 0.2, 0.12, 0.35))
    shine = U(seg(-0.6, 0.12, -0.28, 0.38, 0.045), star(0.42, -0.2, 8, 0.3, 0.12, 0.2))
    shaft, tip = _stick(0.84, -0.8, 0.38, -0.16, 0.1)
    stick = U(shaft, tip)
    return [cymbal, shade, shine, stick]


@sticker("drumlife", "pad", "Practice pad", ["#2EC4B6", "#3A3F47", "#6B717C", "#F3D9A4"], ink=1.0)
def _():
    base = U(oval(0, 0.04, 0.88, 0.56), oval(0, -0.06, 0.88, 0.56))
    rubber = oval(0, 0.08, 0.76, 0.46)
    shine = U(arc(0, 0.08, 0.62, math.radians(130), math.radians(175), 0.045), oval(0.06, 0.04, 0.16, 0.08))
    a, at = _stick(-0.84, -0.3, 0.7, 0.42, 0.1)
    b, bt = _stick(-0.78, -0.56, 0.78, 0.18, 0.1)
    sticks = U(a, b, at, bt)
    return [base, rubber, shine, sticks]


@sticker("drumlife", "clickbox", "Click box", ["#3A3F47", "#1F2226", "#9BE38A", "#1A1C22"], ink=1.0)
def _():
    body = U(box(0, -0.06, 0.82, 0.62, 0.14), box(0.56, 0.6, 0.06, 0.08, 0.02))
    shade = _rim(body, 0.09)
    screen = U(box(0, 0.14, 0.62, 0.28, 0.06), circle(0.56, 0.7, 0.12), polyline([(-0.7, -0.2), (-0.7, 0.42), (-0.5, 0.48)], 0.045))
    digits = U(text("120", 0.0, 0.14, 0.34, maxw=1.0), *[circle(x, -0.42, 0.1) for x in (-0.4, 0.0, 0.4)])
    return [body, shade, screen, digits]


@sticker("drumlife", "earplugs", "Earplugs", ["#FF9F1C", "#E07B00", "#FFFFFF", "#1A1C22"], ink=1.0)
def _():
    a, b = box(-0.36, 0.14, 0.24, 0.44, 0.22, 0.3), box(0.36, 0.1, 0.24, 0.44, 0.22, -0.25)
    plugs = U(a, b)
    shade = _rim(plugs, 0.09)
    shine = U(seg(-0.54, 0.32, -0.42, 0.52, 0.045), seg(0.18, 0.3, 0.26, 0.5, 0.045))
    faces = U(bezier((-0.3, -0.3), (0.0, -0.96), (0.3, -0.36), 0.085),
              circle(-0.42, 0.18, 0.045), circle(-0.26, 0.24, 0.045), arc(-0.33, 0.06, 0.09, math.radians(200), math.radians(340), 0.035),
              circle(0.3, 0.16, 0.045), circle(0.46, 0.1, 0.045), arc(0.36, 0.02, 0.09, math.radians(200), math.radians(340), 0.035))
    return [plugs, shade, shine, faces]


@sticker("drumlife", "blister", "Blister", ["#E9B98A", "#C98B4B", "#FFF1DC", "#3A2418"], ink=1.0)
def _():
    with rotated(0.55):
        bandage = box(0, 0, 0.92, 0.36, 0.34)
        pad = U(box(0, 0, 0.36, 0.26, 0.08), seg(-0.78, 0.2, -0.52, 0.24, 0.05))
        holes = U(*[circle(x, y, 0.035) for x in (-0.72, -0.56, 0.56, 0.72) for y in (-0.12, 0.12)])
    shade = _rim(bandage, 0.09)
    face = U(holes, polyline([(-0.2, 0.18), (-0.1, 0.12), (-0.2, 0.06)], 0.035), polyline([(0.06, 0.32), (0.14, 0.24), (0.04, 0.2)], 0.035),
             arc(0.0, -0.06, 0.1, math.radians(20), math.radians(160), 0.035))
    return [bandage, shade, pad, face]


@sticker("drumlife", "stickbag", "Stick bag", ["#E9C9A3", "#2E9E4F", "#1F6B34", "#1A1C22"], ink=1.0)
def _():
    parts = [_stick(x, -0.3, x + dx, 0.84, 0.115) for x, dx in [(-0.2, -0.12), (0.02, 0.0), (0.24, 0.12)]]
    gleam = U(seg(-0.34, -0.06, -0.34, -0.6, 0.05), seg(-0.34, -0.06, -0.12, -0.06, 0.04))
    sticks = U(*[p[0] for p in parts], *[p[1] for p in parts], gleam)
    pouch = box(0.02, -0.42, 0.44, 0.48, 0.12)
    bag = sub(pouch, gleam)
    shade = U(_rim(pouch, 0.1), inter(pouch, box(0.02, -0.04, 0.5, 0.08)))
    strap = U(brush([(0.44, -0.1), (0.72, 0.3), (0.62, 0.62)], [0.07, 0.07, 0.07]), seg(-0.22, -0.56, 0.26, -0.56, 0.045))
    return [sticks, bag, shade, strap]


@sticker("drumlife", "key", "Drum key", ["#B9C0CA", "#6B727D", "#1A1C22", "#FFFFFF"], ink=1.0)
def _():
    wings = box(0, 0.5, 0.74, 0.2, 0.18)
    barrel = box(0, -0.12, 0.24, 0.5, 0.06)
    end = oval(0, -0.62, 0.24, 0.16)
    key = U(wings, barrel, end)
    shade = U(_rim(key, 0.1), inter(barrel, box(0.18, -0.12, 0.06, 0.5)))
    socket = U(box(0, -0.62, 0.09, 0.08, 0.0), circle(-0.5, 0.5, 0.075), circle(0.5, 0.5, 0.075))
    shine = U(seg(-0.3, 0.6, 0.3, 0.6, 0.04), seg(-0.12, 0.2, -0.12, -0.38, 0.04))
    return [key, shade, socket, shine]


@sticker("drumlife", "setlist", "Setlist", ["#F4F1EA", "#A4AAB4", "#1A1C22", "#E3172F"], ink=1.0)
def _():
    with rotated(-0.1):
        paper = box(0, -0.04, 0.62, 0.84, 0.04)
        curl = poly([(0.62, -0.58), (0.62, -0.88), (0.32, -0.88)])
        writing = U(text("SET", -0.18, 0.52, 0.24, maxw=0.7), *[box(-0.08 + 0.06 * (k % 2), 0.16 - k * 0.2, 0.38 - 0.08 * (k % 3), 0.04, 0.03)
                                                                for k in range(5)],
                    *[circle(-0.48, 0.16 - k * 0.2, 0.045) for k in range(5)])
        mark = U(seg(-0.52, -0.24, 0.44, -0.24, 0.04), star(0.42, 0.52, 5, 0.16, 0.07))
    glint = seg(-0.18, 0.77, 0.0, 0.83, 0.03)
    mark = U(mark, sub(box(0, 0.8, 0.32, 0.11, 0.0, 0.2), glint))
    shade = U(inter(paper, curl), inter(_rim(paper, 0.09), paper))
    return [paper, shade, writing, mark]


@sticker("drumlife", "throne", "Throne", ["#C9CED6", "#3A3F47", "#1A1C22", "#FFFFFF"], ink=1.0)
def _():
    stand = U(box(0, -0.22, 0.1, 0.4), box(0, -0.06, 0.15, 0.07, 0.02), seg(0, -0.54, -0.6, -0.76, 0.1),
              seg(0, -0.54, 0.6, -0.76, 0.1))
    seat = U(oval(0, 0.42, 0.66, 0.22), box(0, 0.28, 0.66, 0.14), oval(0, 0.14, 0.66, 0.22))
    shade = U(sub(seat, oval(0, 0.42, 0.66, 0.22)), _rim(seat, 0.06))
    shine = U(arc(0, 0.42, 0.5, math.radians(150), math.radians(200), 0.035), circle(0, 0.44, 0.04))
    return [stand, seat, shade, shine]


@sticker("drumlife", "fourcount", "4 count", ["#8B3DFF", "#5B21B6", "#FFFFFF", "#FFD400"], ink=1.0)
def _():
    badge = regpoly(0, 0, 6, 0.8, math.pi / 2) - 0.06
    shade = _rim(badge, 0.1)
    ring_ = U(shell(regpoly(0, 0, 6, 0.66, math.pi / 2) + 0.04, 0.035), polyline([(-0.66, 0.04), (-0.66, 0.3), (-0.38, 0.46)], 0.05))
    number = U(text("4", 0, 0.12, 0.6, maxw=0.8), text("COUNT", 0, -0.4, 0.17, maxw=0.82))
    return [badge, shade, ring_, number]


@sticker("drumlife", "onetwo", "1 2 3 4", ["#1E2A44", "#0E1526", "#FFD400", "#FF3D7F"], ink=1.0)
def _():
    with rotated(0.08):
        tile = box(0, 0, 0.84, 0.84, 0.22)
        gleam = arc(-0.6, 0.6, 0.14, math.radians(105), math.radians(165), 0.045)
    shade = _rim(tile, 0.1)
    downbeats = U(text("1", -0.36, 0.38, 0.6, ang=0.08, maxw=0.62) - 0.02, text("3", -0.38, -0.4, 0.6, ang=0.08, maxw=0.62) - 0.02, gleam)
    backbeats = U(text("2", 0.38, 0.4, 0.6, ang=0.08, maxw=0.62) - 0.02, text("4", 0.36, -0.38, 0.6, ang=0.08, maxw=0.62) - 0.02)
    return [tile, shade, downbeats, backbeats]


@sticker("drumlife", "bpm", "BPM", ["#E3172F", "#9D1220", "#FFFFFF", "#FFFFFF"], ink=1.0)
def _():
    heart_ = heart(0, 0.1, 1.34)
    shade = _rim(heart_, 0.1)
    pulse = U(polyline([(-0.66, -0.12), (-0.3, -0.12), (-0.18, 0.06), (-0.06, -0.36), (0.08, -0.12), (0.62, -0.12)], 0.045),
              arc(-0.335, 0.274, 0.32, math.radians(115), math.radians(165), 0.055))
    word = text("BPM", 0, 0.3, 0.28, maxw=0.98)
    return [heart_, shade, pulse, word]


@sticker("drumlife", "broken", "Broken stick", ["#FFD400", "#E9C9A3", "#A86C38", "#FFFFFF"], ink=1.0)
def _():
    burst = star(0.0, -0.42, 8, 0.4, 0.2, 0.2)
    left = U(taper(-0.84, 0.36, -0.2, -0.3, 0.13, 0.12), circle(-0.84, 0.36, 0.13),
             poly([(-0.28, -0.2), (-0.08, -0.26), (-0.18, -0.34), (-0.06, -0.42), (-0.2, -0.46), (-0.3, -0.4)]),
             poly([(-0.16, -0.26), (0.02, -0.12), (-0.08, -0.3)]))
    right = U(taper(0.2, -0.3, 0.72, 0.42, 0.12, 0.09), poly([(0.28, -0.2), (0.08, -0.26), (0.18, -0.34), (0.06, -0.42), (0.2, -0.46), (0.3, -0.4)]),
              poly([(0.14, -0.4), (0.0, -0.62), (0.2, -0.46)]))
    stick = U(left, right)
    shade = _rim(stick, 0.07)
    tip = U(oval(0.78, 0.5, 0.12, 0.09, 0.95), seg(-0.76, 0.32, -0.46, 0.0, 0.05))
    return [burst, stick, shade, tip]


@sticker("drumlife", "clicktrack", "Click track", ["#2EC4B6", "#E3172F", "#9D1220", "#FFFFFF"], ink=1.0)
def _():
    band = U(arc(-0.1, 0.06, 0.6, math.radians(15), math.radians(172), 0.13), box(-0.7, -0.12, 0.16, 0.3, 0.12),
             polyline([(0.3, -0.62), (0.16, -0.72), (0.28, -0.8), (0.12, -0.88), (-0.4, -0.88)], 0.06))
    cup = circle(0.36, -0.12, 0.5)
    shade = _rim(cup, 0.11)
    emblem = U(sub(poly([(0.2, -0.42), (0.54, -0.42), (0.45, 0.14), (0.29, 0.14)]), seg(0.37, -0.32, 0.5, 0.04, 0.04)),
               arc(0.36, -0.12, 0.38, math.radians(105), math.radians(165), 0.06))
    return [band, cup, shade, emblem]


@sticker("drumlife", "pedal", "Kick pedal", ["#7A808A", "#E3172F", "#2B2E33", "#FFFFFF"], ink=1.0)
def _():
    frame = U(box(-0.02, -0.76, 0.84, 0.12, 0.05), box(0.54, -0.22, 0.16, 0.56, 0.06), circle(0.54, 0.34, 0.2),
              seg(0.54, 0.34, 0.34, 0.56, 0.08))
    board = U(poly([(-0.84, -0.64), (0.36, -0.28), (0.38, -0.06), (-0.84, -0.42)]), box(-0.72, -0.62, 0.13, 0.13, 0.04))
    shade = U(_rim(frame, 0.08), _rim(board, 0.07), seg(0.36, -0.14, 0.4, 0.2, 0.06))
    ball = U(circle(0.26, 0.62, 0.26), seg(0.42, -0.06, 0.42, -0.6, 0.04), circle(0.48, 0.42, 0.05),
             seg(-0.72, -0.48, -0.16, -0.31, 0.04))
    return [frame, board, shade, ball]


@sticker("drumlife", "cowbell", "Cowbell", ["#E3172F", "#9D1220", "#2B2E33", "#FFFFFF"], ink=1.0)
def _():
    bell = U(poly([(-0.34, 0.46), (0.34, 0.46), (0.56, -0.6), (-0.56, -0.6)]) - 0.05, oval(0, -0.64, 0.6, 0.14))
    shade = U(inter(bell, poly([(0.12, 0.6), (0.7, 0.6), (0.9, -0.9), (0.24, -0.9)])))
    mouth = U(oval(0, -0.64, 0.5, 0.09), box(0, 0.6, 0.2, 0.12, 0.04), box(0.42, 0.62, 0.3, 0.05, 0.02), circle(0, 0.6, 0.05))
    shine = U(seg(-0.26, 0.3, -0.42, -0.4, 0.04), circle(-0.2, 0.36, 0.035))
    return [bell, shade, mouth, shine]
