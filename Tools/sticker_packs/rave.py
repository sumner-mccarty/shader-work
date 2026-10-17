# Rave — neon lasers, bass and a dark floor. Every piece carries the house shade (lower-right) and highlight (upper-left)
# layers. Run by Tools/decor_stickers.py (every helper is in scope).
PACK = ("rave", "Rave", False)
PRO_IDS = {"deck", "speaker", "drop", "hands", "strobe", "lheart"}


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
    """The house shade: the lower-right rim of d (d minus itself slid up-left)."""
    return sub(d, _moved(d, -k, k))


def _hl(d, k=0.075, cut=0.45):
    """The house highlight: the upper-left rim of d shrunk a little, kept only in the upper-left corner."""
    s = d + 0.05
    return inter(sub(s, _moved(s, k, -k)), X * 0.8 - Y * 0.8 + cut)


@sticker("rave", "laser", "Laser fan", ["#FF2E4A", "#FF9A1F", "#8A0F2E", "#FFF0C8"], ink=1.0)
def _():
    ox, oy = -0.55, -0.5
    tips = [(ox + 1.3 * math.cos(math.radians(a)), oy + 1.3 * math.sin(math.radians(a))) for a in (4, 24, 44, 64, 84)]
    rays = [taper(ox, oy, x, y, 0.07, 0.15) for x, y in tips]
    reds = U(rays[0], rays[2], rays[4])
    oranges = U(rays[1], rays[3])
    housing = U(box(ox, oy, 0.28, 0.24, 0.08, ang=0.6), circle(ox, oy, 0.2))
    shade = U(_lr(U(reds, oranges), 0.09), housing)
    shine = U(_hl(U(reds, oranges), 0.07, 0.3), seg(ox + 0.2, oy + 0.45, ox + 0.5, oy + 1.0, 0.04))
    return [reds, oranges, shade, shine]


@sticker("rave", "face", "Party face", ["#D9F23A", "#9DB300", "#FFFFE0", "#1B1030"], ink=1.0)
def _():
    body = circle(0, 0, 0.7)
    shade = _lr(body, 0.1)
    shine = _hl(body, 0.09, 0.4)
    shades = U(*[box(0, y, 0.5, 0.045, 0.02) for y in (0.3, 0.2, 0.1)], box(0, 0.2, 0.52, 0.13, 0.05))
    shades = sub(box(0, 0.2, 0.52, 0.15, 0.06), U(*[box(0, y, 0.6, 0.018) for y in (0.26, 0.14)]))
    phones = U(arc(0, 0, 0.74, 0.25, math.pi - 0.25, 0.06), box(-0.76, 0.02, 0.12, 0.27, 0.06), box(0.76, 0.02, 0.12, 0.27, 0.06))
    mouth = arc(0, -0.08, 0.34, -2.5, -0.64, 0.07)
    features = U(shades, phones, mouth)
    return [body, shade, shine, features]


@sticker("rave", "deck", "DJ deck", ["#5A42B0", "#2B1A66", "#B9A8FF", "#19E3FF"], ink=1.0)
def _():
    body = box(0, -0.1, 0.88, 0.7, 0.12)
    shade = _lr(body, 0.1)
    shine = _hl(body, 0.08, 0.55)
    hts = [0.08, 0.15, 0.1, 0.18, 0.12, 0.07, 0.17, 0.12, 0.08]
    bars = U(*[box(-0.64 + 0.16 * i, 0.38, 0.06, h, 0.025) for i, h in enumerate(hts)])
    platter = U(ring(-0.3, -0.3, 0.3, 0.055), circle(-0.3, -0.3, 0.08))
    slider = U(box(0.5, -0.3, 0.07, 0.3, 0.03), box(0.5, -0.12, 0.17, 0.06, 0.03))
    wave = U(bars, platter, slider)
    return [body, shade, shine, wave]


@sticker("rave", "visor", "LED visor", ["#FF2E93", "#B4106A", "#FFC4E4", "#1A1030"], ink=1.0)
def _():
    frame = poly(spline([(-0.88, 0.34), (0.0, 0.42), (0.88, 0.34), (0.8, -0.1), (0.5, -0.36), (0.18, -0.2), (-0.18, -0.2), (-0.5, -0.36),
                         (-0.8, -0.1)], closed=True, n=6))
    shade = _lr(frame, 0.1)
    shine = _hl(frame, 0.08, 0.45)
    eq = U(*[seg(-0.54 + 0.18 * i, 0.1 - h, -0.54 + 0.18 * i, 0.1 + h, 0.055)
             for i, h in enumerate([0.03, 0.1, 0.06, 0.13, 0.06, 0.1, 0.03])])
    screen = sub(box(0, 0.1, 0.7, 0.2, 0.1), eq)  # the visor glass; the EQ bars are cut out of it
    return [frame, shade, shine, screen]


@sticker("rave", "strobe", "Strobe light", ["#FFF45A", "#5A60A0", "#2C3070", "#C9CDF5"], ink=1.0)
def _():
    rays = U(*[taper(0.26 + 0.04 * math.cos(math.radians(a)), 0.04 * math.sin(math.radians(a)), 0.26 + 0.46 * math.cos(math.radians(a)),
                     0.46 * math.sin(math.radians(a)), 0.07, 0.12) for a in (-50, -25, 0, 25, 50)])
    flash = U(rays, box(0.2, 0.0, 0.11, 0.3, 0.04))
    head = box(-0.38, 0.02, 0.46, 0.42, 0.1)
    housing = U(head, seg(-0.38, -0.4, -0.38, -0.64, 0.09), box(-0.38, -0.74, 0.32, 0.07, 0.03))
    shade = _lr(housing, 0.09)
    shine = _hl(head, 0.08, 0.5)
    return [flash, housing, shade, shine]


@sticker("rave", "speaker", "Speaker stack", ["#4A44A0", "#1F1A55", "#A9A2F0", "#19E3FF"], ink=1.0)
def _():
    top = box(-0.15, 0.42, 0.5, 0.38, 0.07)
    low = box(-0.15, -0.42, 0.5, 0.38, 0.07)
    body = U(top, low)
    shade = U(_lr(top, 0.09), _lr(low, 0.09))
    shine = U(_hl(top, 0.07, 0.4), _hl(low, 0.07, 0.4))
    woofs = U(ring(-0.15, -0.42, 0.26, 0.07), circle(-0.15, -0.42, 0.09), ring(-0.15, 0.42, 0.19, 0.06), circle(-0.15, 0.42, 0.06))
    rings = U(arc(-0.15, -0.42, 0.66, -0.55, 0.55, 0.05), arc(-0.15, -0.42, 0.84, -0.45, 0.45, 0.05))
    bass = U(woofs, rings)
    return [body, shade, shine, bass]


@sticker("rave", "bass", "BASS sign", ["#6A4AD0", "#25126B", "#C2B0FF", "#FF3DB4"], ink=1.0)
def _():
    plate = box(0, 0, 0.9, 0.44, 0.15)
    shade = _lr(plate, 0.1)
    shine = _hl(plate, 0.08, 0.55)
    neon = text("BASS", 0, 0.0, 0.42, maxw=1.45)
    return [plate, shade, shine, neon]


@sticker("rave", "drop", "Drop burst", ["#FFE41F", "#F08A00", "#FFFBD0", "#D4106E"], ink=1.0)
def _():
    burst = star(0, 0, 14, 0.92, 0.64, ang=0.1)
    shade = _lr(burst, 0.1)
    shine = _hl(burst, 0.08, 0.5)
    word = text("DROP", 0, 0.0, 0.34, ang=0.1, maxw=1.1)
    return [burst, shade, shine, word]


def _wavy(r, amp, k, t):
    """A ring of mean radius r whose edge ripples k times round (a sound wave bent into a circle)."""
    pts = [((r + amp * math.sin(k * a)) * math.cos(a), (r + amp * math.sin(k * a)) * math.sin(a)) for a in np.linspace(0, 2 * math.pi, 97)]
    return polyline(pts, t)


@sticker("rave", "pulse", "Sound ring", ["#B07CFF", "#6A34D6", "#EAD8FF", "#19E3FF"], ink=1.0)
def _():
    arcs = U(*[arc(0, 0, r, a0, a1, 0.085) for r in (0.5, 0.76) for a0, a1 in ((math.radians(75), math.radians(200)), (math.radians(255), math.radians(380)))])
    shade = _lr(arcs, 0.07)
    shine = _hl(arcs, 0.06, 0.2)
    dot = circle(0, 0, 0.22)
    return [arcs, shade, shine, dot]


@sticker("rave", "fog", "Fog cloud", ["#C9B8FF", "#8466E8", "#F4EEFF", "#FF5FCB"], ink=1.0)
def _():
    body = U(circle(-0.48, -0.1, 0.36), circle(-0.1, 0.3, 0.5), circle(0.42, 0.0, 0.4), box(0, -0.38, 0.84, 0.28, 0.24))
    shade = _lr(body, 0.1)
    shine = _hl(body, 0.08, 0.4)
    swirl = U(arc(-0.45, -0.12, 0.16, 0.4, 4.4, 0.05), arc(0.38, -0.02, 0.2, -0.4, 3.4, 0.05), arc(-0.1, 0.32, 0.14, 0.6, 5.0, 0.05))
    return [body, shade, shine, swirl]


@sticker("rave", "beads", "Bead bracelet", ["#FF4FA8", "#FFE41F", "#B01868", "#FFFFFF"], ink=1.0)
def _():
    n, R, r = 10, 0.62, 0.215
    cs = [(R * math.cos(math.pi / 2 + 2 * math.pi * i / n), R * math.sin(math.pi / 2 + 2 * math.pi * i / n)) for i in range(n)]
    body = U(*[circle(x, y, r) for x, y in cs])
    alt = U(*[circle(x, y, r) for i, (x, y) in enumerate(cs) if i % 2 == 1])
    shade = U(*[sub(circle(x, y, r), circle(x - 0.06, y + 0.06, r)) for x, y in cs])
    shine = U(*[circle(x - 0.08, y + 0.08, 0.05) for x, y in cs])
    return [body, alt, shade, shine]


@sticker("rave", "fader", "Crossfader", ["#6870B0", "#262A52", "#C9CEF5", "#FF3D5A"], ink=1.0)
def _():
    plate = box(0, 0, 0.88, 0.64, 0.12)
    slot = box(0, -0.3, 0.66, 0.06, 0.03)
    shade = U(_lr(plate, 0.1), slot)
    shine = _hl(plate, 0.08, 0.55)
    cap = U(box(0.22, -0.3, 0.17, 0.2, 0.05), *[box(-0.6 + 0.2 * i, 0.22, 0.075, 0.14, 0.03) for i in range(7)])
    return [plate, shade, shine, cap]


@sticker("rave", "cube", "Mirror cube", ["#9FB4DE", "#5A6FA3", "#EAF4FF", "#FFFFFF"], ink=1.0)
def _():
    cube = poly([(0, 0.86), (0.74, 0.43), (0.74, -0.43), (0, -0.86), (-0.74, -0.43), (-0.74, 0.43)])
    right = poly([(0, 0), (0.74, 0.43), (0.74, -0.43), (0, -0.86)])
    top = poly([(0, 0.86), (0.74, 0.43), (0, 0), (-0.74, 0.43)])
    streaks = U(inter(cube, stripes(0.6, 2.2, 0.2, 0.1)), star(-0.5, 0.2, 4, 0.2, 0.05))
    return [cube, right, top, streaks]


@sticker("rave", "lheart", "Lightning heart", ["#FF2E93", "#B4106A", "#FFC4E4", "#FFF23A"], ink=1.0)
def _():
    body = heart(0, 0.0, 0.88)
    shade = _lr(body, 0.1)
    shine = _hl(body, 0.08, 0.5)
    bolt = poly([(0.12, 0.55), (-0.3, -0.02), (-0.02, -0.02), (-0.14, -0.6), (0.3, 0.08), (0.03, 0.08)]) - 0.02
    return [body, shade, shine, bolt]


@sticker("rave", "hands", "Heart hand", ["#FF4FB0", "#FFD3B0", "#D9926A", "#FFFFFF"], ink=1.0)
def _():
    love = heart(0, 0.22, 0.62)
    fingers = U(*[box(x, -0.2 + dy, 0.1, 0.3, 0.1) for x, dy in ((-0.36, -0.02), (-0.12, 0.04), (0.12, 0.04), (0.36, -0.02))])
    hand = U(fingers, box(0, -0.6, 0.48, 0.26, 0.12), oval(-0.54, -0.45, 0.12, 0.22, -0.6))
    shade = _lr(hand, 0.1)
    shine = U(_hl(hand, 0.07, 0.3), _hl(love, 0.08, 0.4), star(0.64, 0.6, 4, 0.2, 0.07))
    return [love, hand, shade, shine]


@sticker("rave", "vibe", "VIBE ribbon", ["#19E3FF", "#0D8FB3", "#E0FBFF", "#5B21D6"], ink=1.0)
def _():
    main = box(0, 0.1, 0.66, 0.36, 0.04)
    tails = U(poly([(-0.9, 0.0), (-0.45, 0.0), (-0.45, -0.5), (-0.9, -0.5), (-0.76, -0.25)]),
              poly([(0.9, 0.0), (0.45, 0.0), (0.45, -0.5), (0.9, -0.5), (0.76, -0.25)]))
    body = U(main, tails)
    shade = U(sub(tails, main), _lr(main, 0.09))
    shine = _hl(main, 0.07, 0.4)
    word = text("VIBE", 0, 0.1, 0.34, maxw=1.1)
    return [body, shade, shine, word]
