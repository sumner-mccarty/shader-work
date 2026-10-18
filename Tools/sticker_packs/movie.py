PACK = ("movie", "Movie Night", False)
PRO_IDS = {"moviecam", "projector", "action", "marquee", "clapper", "curtain"}


def _lowright(d, cx=0.0, cy=0.0, k=0.2):
    """The lower-right slice of shape d (the one shade layer), cut along a diagonal through (cx, cy)."""
    return inter(d, k - ((X - cx) - (Y - cy)) * 0.7)


@sticker("movie", "clapper", "Clapperboard", ["#2B3050", "#151A33", "#FFFFFF", "#FFC531"], ink=1.0)
def _():
    board = box(0, -0.3, 0.8, 0.5, 0.06)
    with rotated(0.2, -0.7, 0.2):
        stick = box(0.05, 0.34, 0.86, 0.17, 0.04)
        bands = inter(stick, stripes(0.5, 1.0, 0.5, 0.1))
    body = U(board, stick)
    shade = _lowright(body, 0, -0.1, 0.25)
    stripes_ = U(bands, circle(-0.26, -0.2, 0.09), circle(0.26, -0.2, 0.09), arc(0, -0.16, 0.3, math.radians(220), math.radians(320), 0.05))
    hinge = U(circle(-0.7, 0.16, 0.08), box(0.5, -0.5, 0.2, 0.05))
    return [body, shade, stripes_, hinge]


@sticker("movie", "reel", "Film reel", ["#FF8A2A", "#C2561A", "#2B3050", "#FFFFFF"], ink=1.0)
def _():
    body = circle(0, 0.05, 0.84)
    shade = _lowright(body, 0, 0.05, 0.3)
    holes = U(*[circle(0.5 * math.cos(math.radians(90 + 72 * k)), 0.05 + 0.5 * math.sin(math.radians(90 + 72 * k)), 0.17)
                for k in range(5)], ring(0, 0.05, 0.12, 0.05), circle(0, 0.05, 0.05))
    shine = U(arc(0, 0.05, 0.74, math.radians(110), math.radians(165), 0.05), circle(-0.6, 0.55, 0.05))
    return [body, shade, holes, shine]


@sticker("movie", "glasses3d", "3D glasses", ["#F4EBD6", "#E3172F", "#25C7FF", "#FFFFFF"], ink=1.0)
def _():
    frame = U(box(-0.45, 0.0, 0.47, 0.46, 0.18), box(0.45, 0.0, 0.47, 0.46, 0.18))
    redlens = box(-0.45, 0.0, 0.33, 0.32, 0.12)
    cyanlens = box(0.45, 0.0, 0.33, 0.32, 0.12)
    shine = U(seg(-0.62, 0.16, -0.38, 0.16, 0.055), seg(0.28, 0.16, 0.52, 0.16, 0.055))
    return [frame, redlens, cyanlens, shine]


@sticker("movie", "dirchair", "Director's chair", ["#E3172F", "#A5102A", "#9A6B3A", "#FFFFFF"], ink=1.0)
def _():
    canvas = U(box(0, 0.48, 0.58, 0.26, 0.05), box(0, -0.08, 0.6, 0.1, 0.04))
    shade = _lowright(canvas, 0, 0.2, 0.25)
    wood = U(seg(-0.6, 0.78, -0.6, -0.1, 0.07), seg(0.6, 0.78, 0.6, -0.1, 0.07), seg(-0.62, 0.14, 0.62, 0.14, 0.05),
             seg(-0.55, -0.16, 0.55, -0.86, 0.08), seg(0.55, -0.16, -0.55, -0.86, 0.08))
    shine = U(seg(-0.4, 0.58, -0.4, 0.4, 0.05), seg(-0.36, -0.04, -0.1, -0.04, 0.035),
              seg(-0.12, 0.62, 0.3, 0.62, 0.04))
    return [canvas, shade, wood, shine]


@sticker("movie", "moviecam", "Movie camera", ["#3B7C86", "#265058", "#FFC531", "#FFFFFF"], ink=1.0)
def _():
    body = box(-0.1, -0.18, 0.56, 0.36, 0.08)
    shade = _lowright(body, -0.1, -0.18, 0.2)
    reels = U(circle(-0.4, 0.5, 0.32), circle(0.1, 0.56, 0.28), poly([(0.4, 0.0), (0.88, 0.26), (0.88, -0.62), (0.4, -0.34)]))
    glint = U(circle(-0.45, 0.56, 0.1), circle(0.06, 0.6, 0.09), circle(0.72, -0.18, 0.09),
              seg(-0.5, -0.0, -0.3, 0.0, 0.04))
    return [body, shade, reels, glint]


@sticker("movie", "soda", "Soda cup", ["#E3172F", "#A5102A", "#FFFFFF", "#FFD23A"], ink=1.0)
def _():
    cup = poly([(-0.52, 0.42), (0.52, 0.42), (0.36, -0.9), (-0.36, -0.9)])
    shade = _lowright(cup, 0, 0, 0.1)
    lid = U(oval(0, 0.5, 0.58, 0.14), inter(cup, box(0, -0.15, 0.6, 0.27)))
    face = U(circle(-0.16, -0.04, 0.09), circle(0.16, -0.04, 0.09), arc(0, -0.08, 0.22, math.radians(215), math.radians(325), 0.05),
             seg(0.08, 0.6, 0.3, 0.86, 0.09), seg(0.3, 0.86, 0.56, 0.86, 0.09))
    return [cup, shade, lid, face]


@sticker("movie", "candy", "Candy box", ["#3A7BFF", "#2250B8", "#FFFFFF", "#FF4F8B"], ink=1.0)
def _():
    carton = U(box(0, -0.36, 0.8, 0.4, 0.08), poly([(-0.8, 0.0), (0.8, 0.0), (0.58, 0.66), (-0.58, 0.66)]) - 0.03)
    shade = _lowright(carton, 0, -0.1, 0.3)
    band = polyline([(-0.76, -0.36), (-0.5, -0.14), (-0.25, -0.36), (0.0, -0.14), (0.25, -0.36), (0.5, -0.14), (0.76, -0.36)], 0.09)
    candies = U(circle(-0.3, 0.26, 0.2), poly([(-0.5, 0.26), (-0.72, 0.4), (-0.72, 0.12)]), poly([(-0.1, 0.26), (0.12, 0.4), (0.12, 0.12)]),
                box(0.4, 0.3, 0.24, 0.12, 0.06, 0.5))
    return [carton, shade, band, candies]


@sticker("movie", "seats", "Theater seats", ["#D8213C", "#92142A", "#2B2E3A", "#FFFFFF"], ink=1.0)
def _():
    seats = U(*[box(x, 0.28, 0.38, 0.46, 0.22) for x in (-0.44, 0.44)], *[box(x, -0.4, 0.4, 0.2, 0.1) for x in (-0.44, 0.44)])
    shade = _lowright(seats, 0, 0.0, 0.35)
    armrests = U(box(0, -0.1, 0.1, 0.34, 0.05), box(-0.9, -0.1, 0.07, 0.3, 0.04), box(0.9, -0.1, 0.07, 0.3, 0.04), box(0, -0.82, 0.92, 0.06, 0.03))
    shine = U(*[seg(x - 0.2, 0.56, x + 0.0, 0.62, 0.055) for x in (-0.44, 0.44)])
    return [seats, shade, armrests, shine]


@sticker("movie", "marquee", "Marquee NOW", ["#B3122E", "#7A0B20", "#FFE14A", "#FFFFFF"], ink=1.0)
def _():
    sign = U(box(0, -0.2, 0.9, 0.5, 0.1), poly([(-0.64, 0.28), (0.0, 0.9), (0.64, 0.28)]))
    shade = _lowright(sign, 0, -0.1, 0.3)
    bulbs = U(*[circle(x, y, 0.065) for x in (-0.72, -0.36, 0.0, 0.36, 0.72) for y in (-0.6,)],
              *[circle(x, -0.2, 0.065) for x in (-0.82, 0.82)], circle(0.0, 0.76, 0.07), circle(-0.4, 0.42, 0.065), circle(0.4, 0.42, 0.065))
    word = text("NOW", 0, -0.2, 0.46, maxw=1.2)
    return [sign, shade, bulbs, word]


@sticker("movie", "filmstrip", "Film strip", ["#2B2E3A", "#14161E", "#FFFFFF", "#9FD8FF"], ink=1.0)
def _():
    with rotated(0.45):
        strip = box(0, 0, 0.84, 0.37, 0.05)
        holes = U(*[box(x, y, 0.06, 0.06, 0.02) for x in (-0.7, -0.42, -0.14, 0.14, 0.42, 0.7) for y in (0.27, -0.27)])
        frames = U(*[box(x, 0, 0.2, 0.15, 0.03) for x in (-0.5, 0.0, 0.5)])
    shade = _lowright(strip, 0, 0, 0.25)
    return [strip, shade, holes, frames]


@sticker("movie", "walkstar", "Star tile", ["#D1AE82", "#A07B4E", "#F2B632", "#2E4BA8"], ink=1.0)
def _():
    tile = box(0, 0, 0.86, 0.86, 0.06)
    shade = _lowright(tile, 0, 0, 0.3)
    brass = star(0, 0, 5, 0.76, 0.36)
    inlay = star(0, 0, 5, 0.5, 0.24)
    return [tile, shade, brass, inlay]


@sticker("movie", "projector", "Projector", ["#3B4A8C", "#26306A", "#FFF2B0", "#E8EDF5"], ink=1.0)
def _():
    body = U(box(-0.44, -0.05, 0.46, 0.44, 0.12), box(0.12, -0.05, 0.12, 0.2, 0.04), seg(-0.7, -0.5, -0.7, -0.78, 0.07), seg(-0.2, -0.5, -0.2, -0.78, 0.07))
    shade = _lowright(body, -0.44, -0.05, 0.25)
    beam = poly([(0.24, 0.05), (0.92, 0.7), (0.92, -0.8), (0.24, -0.15)])
    lens = U(ring(-0.44, 0.0, 0.2, 0.07), circle(-0.44, 0.0, 0.07), circle(0.12, -0.05, 0.1), seg(-0.78, 0.3, -0.58, 0.3, 0.04))
    return [body, shade, beam, lens]


@sticker("movie", "ticket", "Cinema ticket", ["#25C7B0", "#17897A", "#FFFFFF", "#1E2438"], ink=1.0)
def _():
    with rotated(-0.2):
        base = sub(box(0, 0, 0.58, 0.88, 0.1), U(circle(-0.58, -0.1, 0.17), circle(0.58, -0.1, 0.17)))
        shade = _lowright(base, 0, 0, 0.3)
        perforation = U(star(0, 0.46, 5, 0.32, 0.15), *[box(x, -0.1, 0.07, 0.04) for x in (-0.34, -0.12, 0.12, 0.34)])
        lines = U(box(0, -0.46, 0.34, 0.07, 0.03), box(0, -0.7, 0.34, 0.07, 0.03))
    return [base, shade, perforation, lines]


@sticker("movie", "remote", "Remote", ["#3A3F4E", "#1F2330", "#FF3D4E", "#FFFFFF"], ink=1.0)
def _():
    with rotated(-0.4):
        body = box(0, 0, 0.3, 0.84, 0.14)
        shade = _lowright(body, 0, 0, 0.12)
        power = U(circle(0, 0.58, 0.14), poly([(-0.1, 0.1), (-0.1, 0.34), (0.12, 0.22)]))
        buttons = U(*[circle(x, y, 0.09) for x in (-0.14, 0.14) for y in (-0.1, -0.35, -0.6)], seg(-0.2, 0.74, -0.2, 0.5, 0.04))
    return [body, shade, power, buttons]


@sticker("movie", "couch", "Cozy couch", ["#7A5CC8", "#4F3A94", "#FF9A3D", "#FFFFFF"], ink=1.0)
def _():
    couch = U(box(0, 0.26, 0.7, 0.46, 0.2), box(-0.76, -0.12, 0.18, 0.4, 0.14), box(0.76, -0.12, 0.18, 0.4, 0.14),
              box(0, -0.28, 0.62, 0.2, 0.08), box(0, -0.54, 0.92, 0.14, 0.05),
              box(-0.7, -0.76, 0.1, 0.12, 0.03), box(0.7, -0.76, 0.1, 0.12, 0.03))
    shade = _lowright(couch, 0, 0, 0.35)
    blanket = poly([(0.18, 0.84), (0.82, 0.66), (0.9, 0.0), (0.6, -0.04), (0.56, 0.42), (0.18, 0.52)]) - 0.03
    stripes_ = inter(blanket, stripes(0.3, 0.5, 0.3, 0.05))
    return [couch, shade, blanket, stripes_]


@sticker("movie", "action", "ACTION", ["#E3172F", "#A5102A", "#FFE14A", "#FFFFFF"], ink=1.0)
def _():
    with rotated(0.12):
        banner = box(0, 0, 0.9, 0.42, 0.1)
        shade = _lowright(banner, 0, 0, 0.25)
        trim = U(box(0, 0.3, 0.78, 0.04), box(0, -0.3, 0.78, 0.04))
    word = text("ACTION", 0, 0.0, 0.38, ang=0.12, maxw=1.6)
    return [banner, shade, trim, word]


@sticker("movie", "curtain", "Stage curtain", ["#D8213C", "#92142A", "#FFC531", "#FFF6C2"], ink=1.0)
def _():
    left = poly([(-0.92, 0.55), (-0.34, 0.55), (-0.46, 0.1), (-0.5, -0.1), (-0.44, -0.5), (-0.34, -0.92), (-0.92, -0.92)])
    right = poly([(0.92, 0.55), (0.34, 0.55), (0.46, 0.1), (0.5, -0.1), (0.44, -0.5), (0.34, -0.92), (0.92, -0.92)])
    drapes = U(left, right)
    shade = _lowright(drapes, 0, 0, 0.45)
    trim = U(box(0, 0.78, 0.92, 0.1, 0.05), *[circle(x, 0.68, 0.14) for x in (-0.74, -0.37, 0.0, 0.37, 0.74)],
             box(-0.74, -0.1, 0.16, 0.08, 0.03), box(0.74, -0.1, 0.16, 0.08, 0.03), circle(-0.58, -0.1, 0.1), circle(0.58, -0.1, 0.1))
    screen = sub(box(0, -0.15, 0.5, 0.62, 0.05), drapes)
    return [drapes, shade, trim, screen]
