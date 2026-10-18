PACK = ("notation", "Drum Notation", False)
PRO_IDS = {"fermata", "sixteenths", "accent", "flam", "bassclef", "coda"}


def _disc(R):
    return lambda ox, oy: circle(ox, oy, R)


def _tile(hw, hh, r=0.3):
    return lambda ox, oy: box(ox, oy, hw, hh, r)


def _badge(f):
    """(body, shade): the badge and its lower-right rim."""
    d = f(0, 0)
    return d, sub(d, f(-0.12, 0.12))


def _glint_disc(R):
    return arc(0, 0, R - 0.12, 1.95, 2.75, 0.05)


def _glint_tile(hw, hh, r=0.3):
    return arc(-hw + r, hh - r, r - 0.12, 1.75, 3.0, 0.05)


def _zoom(k, fn):
    """Draw fn() blown up k times about the centre (primitives read the module's X/Y grids; text() does not, so scale it by hand)."""
    g = rotated.__init__.__globals__
    sx, sy = g["X"], g["Y"]
    g["X"], g["Y"] = sx / k, sy / k
    try:
        d = fn()
    finally:
        g["X"], g["Y"] = sx, sy
    return d * k


def _slid(fn, ox, oy):
    with rotated(0.0, 0.0, 0.0, ox, oy):
        return fn()


def _cutbadge(fn, grow):
    """A die-cut badge that follows the symbol: fn() grown by `grow`, plus its lower-right rim."""
    return _badge(lambda ox, oy: _slid(fn, ox, oy) - grow)


def _head(x, y, s=1.0, ang=0.4):
    return oval(x, y, 0.25 * s, 0.18 * s, ang)


@sticker("notation", "staff", "Drum staff", ["#2F3A8F", "#1B2260", "#FFF4D0", "#9FB0FF"], ink=1.0)
def _():
    fn = lambda: _zoom(0.88, lambda: U(*[seg(-0.74, y, 0.74, y, 0.05) for y in (-0.4, -0.2, 0.0, 0.2, 0.4)],
                                       _head(-0.05, -0.1, 1.4), seg(0.27, -0.05, 0.27, 0.8, 0.1)))
    badge, shade = _cutbadge(fn, 0.15)
    symbol = fn()
    shine = U(circle(-0.8, 0.24, 0.06), seg(-0.74, 0.4, -0.62, 0.5, 0.05))
    return [badge, shade, symbol, shine]


@sticker("notation", "xhead", "Cymbal X", ["#1FB5A8", "#12776F", "#FFF4D0", "#BFFFF4"], ink=1.0)
def _():
    fn = lambda: U(seg(-0.72, -0.1, 0.72, -0.1, 0.07), seg(-0.5, -0.38, 0.0, 0.12, 0.14), seg(-0.5, 0.12, 0.0, -0.38, 0.14), seg(0.04, -0.1, 0.04, 0.68, 0.1))
    badge, shade = _cutbadge(fn, 0.17)
    symbol = fn()
    shine = U(circle(-0.74, 0.2, 0.06), seg(-0.68, 0.34, -0.56, 0.44, 0.05))
    return [badge, shade, symbol, shine]


@sticker("notation", "rest", "Quarter rest", ["#7B4FD8", "#4A2A94", "#FFE27A", "#D9C4FF"], ink=1.0)
def _():
    fn = lambda: _zoom(0.95, lambda: U(polyline([(-0.12, 0.6), (0.18, 0.28), (-0.14, -0.04), (0.14, -0.34)], 0.12),
                       arc(-0.06, -0.52, 0.27, 0.84, 3.5, 0.12), circle(-0.3, -0.62, 0.14), circle(-0.12, 0.6, 0.12)))
    badge, shade = _cutbadge(fn, 0.17)
    symbol = fn()
    shine = U(circle(-0.5, 0.5, 0.06), seg(-0.42, 0.66, -0.3, 0.76, 0.05))
    return [badge, shade, symbol, shine]


@sticker("notation", "eighths", "Eighth triplet", ["#FF7A2E", "#B84A12", "#2B1A12", "#FFD2A8"], ink=1.0)
def _():
    def mk(ox, oy):
        return U(_slid(lambda: U(*[_head(x, -0.45, 0.85) for x in (-0.5, 0.0, 0.5)], *[seg(x + 0.2, -0.4, x + 0.2, 0.2, 0.085) for x in (-0.5, 0.0, 0.5)],
                                 seg(-0.3, 0.22, 0.7, 0.22, 0.12)), ox, oy), text("3", 0.2 + ox, 0.56 + oy, 0.36)) - 0.15
    badge, shade = _badge(mk)
    symbol = U(*[_head(x, -0.45, 0.85) for x in (-0.5, 0.0, 0.5)], *[seg(x + 0.2, -0.4, x + 0.2, 0.2, 0.085) for x in (-0.5, 0.0, 0.5)],
               seg(-0.3, 0.22, 0.7, 0.22, 0.12), text("3", 0.2, 0.56, 0.36))
    shine = U(circle(-0.86, -0.1, 0.06), seg(-0.8, 0.1, -0.74, 0.26, 0.05))
    return [badge, shade, symbol, shine]


@sticker("notation", "sixteenths", "Sixteenth notes", ["#E3172F", "#8A0F1F", "#FFF4D0", "#FFB3BC"], ink=1.0)
def _():
    fn = lambda: _zoom(0.92, lambda: U(_head(-0.4, -0.45, 1.3), _head(0.4, -0.45, 1.3), seg(-0.08, -0.4, -0.08, 0.5, 0.1), seg(0.72, -0.4, 0.72, 0.5, 0.1),
                                       seg(-0.08, 0.5, 0.72, 0.5, 0.13), seg(-0.08, 0.2, 0.72, 0.2, 0.12)))
    badge, shade = _cutbadge(fn, 0.15)
    symbol = fn()
    shine = U(circle(-0.8, -0.1, 0.06), seg(-0.76, 0.1, -0.68, 0.24, 0.05))
    return [badge, shade, symbol, shine]


@sticker("notation", "meter", "Time signature", ["#2F7BFF", "#1A4BB0", "#FFFFFF", "#B9D4FF"], ink=1.0)
def _():
    badge, shade = _badge(_disc(0.86))
    symbol = U(text("4", 0, 0.42, 0.66), text("4", 0, -0.42, 0.66))
    shine = _glint_disc(0.86)
    return [badge, shade, symbol, shine]


@sticker("notation", "repeat", "Repeat sign", ["#2B2E3A", "#12141C", "#FFC531", "#6B7390"], ink=1.0)
def _():
    badge, shade = _badge(_tile(0.88, 0.66))
    symbol = _slid(lambda: U(box(-0.46, 0, 0.13, 0.52, 0.04), box(-0.14, 0, 0.09, 0.52, 0.03), circle(0.3, 0.26, 0.17), circle(0.3, -0.26, 0.17)), 0.12, 0.0)
    shine = _glint_tile(0.88, 0.66)
    return [badge, shade, symbol, shine]


@sticker("notation", "accent", "Accent", ["#FF3B7F", "#A81552", "#FFFFFF", "#FFC2D9"], ink=1.0)
def _():
    badge, shade = _badge(lambda ox, oy: star(ox, oy, 9, 0.9, 0.7))
    symbol = _zoom(1.2, lambda: polyline([(-0.38, 0.38), (0.4, 0.0), (-0.38, -0.38)], 0.12))
    shine = arc(0, 0, 0.66, 1.95, 2.6, 0.05)
    return [badge, shade, symbol, shine]


@sticker("notation", "fermata", "Fermata", ["#8CD92B", "#4F8A0E", "#1E2F0A", "#E4FFB5"], ink=1.0)
def _():
    fn = lambda: U(arc(0, -0.3, 0.62, 0.2, math.pi - 0.2, 0.14), circle(0, -0.18, 0.14))
    badge, shade = _cutbadge(fn, 0.2)
    symbol = fn()
    shine = U(circle(-0.5, 0.12, 0.06), seg(-0.4, 0.3, -0.28, 0.4, 0.05))
    return [badge, shade, symbol, shine]


@sticker("notation", "hairpin", "Crescendo", ["#FF9F1C", "#B5640A", "#3A1E00", "#FFE0A0"], ink=1.0)
def _():
    fn = lambda: polyline([(-0.66, 0.0), (0.66, 0.36), (0.66, -0.36), (-0.66, 0.0)], 0.1)
    badge, shade = _cutbadge(fn, 0.16)
    symbol = fn()
    shine = U(circle(-0.5, 0.2, 0.06), seg(-0.36, 0.3, -0.2, 0.38, 0.05))
    return [badge, shade, symbol, shine]


@sticker("notation", "forte", "Fortissimo", ["#C21E56", "#7A0F36", "#FFF4D0", "#FFB0CC"], ink=1.0)
def _():
    mk = lambda ox, oy: text("ff", ox, oy, 0.95, maxw=1.5) - 0.17
    badge, shade = _badge(mk)
    symbol = text("ff", 0, 0, 0.95, maxw=1.5)
    shine = U(circle(-0.62, 0.34, 0.06), seg(-0.56, 0.5, -0.42, 0.6, 0.05))
    return [badge, shade, symbol, shine]


@sticker("notation", "tempo", "Tempo 120", ["#18B7C9", "#0B7380", "#FFFFFF", "#B5F4FB"], ink=1.0)
def _():
    badge, shade = _badge(_tile(0.9, 0.86))
    symbol = U(_head(-0.55, 0.3, 1.0), seg(-0.32, 0.34, -0.32, 0.8, 0.08), seg(-0.1, 0.3, 0.28, 0.3, 0.08), seg(-0.1, 0.12, 0.28, 0.12, 0.08),
               text("120", 0.0, -0.3, 0.66, maxw=1.5))
    shine = _glint_tile(0.9, 0.86)
    return [badge, shade, symbol, shine]


@sticker("notation", "flam", "Flam", ["#8A4FFF", "#4F2AA8", "#FFE27A", "#D8C2FF"], ink=1.0)
def _():
    fn = lambda: U(_head(-0.55, -0.3, 0.6), seg(-0.43, -0.27, -0.43, 0.3, 0.075), bezier((-0.43, 0.3), (-0.2, 0.22), (-0.18, 0.0), 0.075),
                   seg(-0.7, 0.02, -0.28, 0.34, 0.08), _head(0.3, -0.4, 1.45), seg(0.62, -0.32, 0.62, 0.66, 0.1))
    badge, shade = _cutbadge(fn, 0.15)
    symbol = fn()
    shine = U(circle(-0.74, -0.5, 0.06), seg(-0.68, -0.6, -0.56, -0.72, 0.05))
    return [badge, shade, symbol, shine]


@sticker("notation", "swing", "Swing", ["#F2B705", "#A87A00", "#2B1A12", "#FFF0A0"], ink=1.0)
def _():
    mk = lambda ox, oy: U(text("SWING", ox, oy + 0.08, 0.72, maxw=1.62), seg(-0.6 + ox, -0.5 + oy, 0.6 + ox, -0.5 + oy, 0.09)) - 0.17
    badge, shade = _badge(mk)
    symbol = U(text("SWING", 0, 0.08, 0.72, maxw=1.62), polyline([(-0.6, -0.5), (-0.3, -0.38), (0.0, -0.58), (0.3, -0.38), (0.6, -0.5)], 0.09))
    shine = U(circle(-0.8, 0.3, 0.06), seg(-0.74, 0.46, -0.62, 0.56, 0.05))
    return [badge, shade, symbol, shine]


@sticker("notation", "bassclef", "Bass clef", ["#E8590C", "#9E3500", "#FFF4D0", "#FFC9A0"], ink=1.0)
def _():
    fn = lambda: _zoom(1.0, lambda: U(circle(-0.3, 0.26, 0.17), bezier((-0.3, 0.3), (0.1, 0.8), (0.4, 0.3), 0.12), bezier((0.4, 0.3), (0.4, -0.3), (-0.3, -0.62), 0.12, r1=0.07),
                       circle(0.58, 0.4, 0.14), circle(0.58, 0.1, 0.14)))
    badge, shade = _cutbadge(fn, 0.14)
    symbol = fn()
    shine = U(circle(-0.62, 0.5, 0.06), seg(-0.5, 0.64, -0.36, 0.76, 0.05))
    return [badge, shade, symbol, shine]


@sticker("notation", "coda", "Coda", ["#FFC531", "#B8820A", "#6B1E2E", "#FFF2B0"], ink=1.0)
def _():
    fn = lambda: _zoom(0.92, lambda: U(ring(0, 0, 0.34, 0.13), seg(0, -0.72, 0, 0.72, 0.12), seg(-0.72, 0, 0.72, 0, 0.12)))
    badge, shade = _cutbadge(fn, 0.17)
    symbol = fn()
    shine = U(circle(-0.4, 0.4, 0.06), seg(-0.3, 0.52, -0.2, 0.62, 0.05))
    return [badge, shade, symbol, shine]


@sticker("notation", "ghost", "Ghost note", ["#7C93E0", "#4A5FA8", "#FFFFFF", "#D0DBFF"], ink=1.0)
def _():
    fn = lambda: _zoom(1.3, lambda: U(_head(-0.04, -0.26), seg(0.18, -0.2, 0.18, 0.5, 0.1),
                       arc(0.2, -0.05, 0.7, math.pi - 0.5, math.pi + 0.5, 0.13), arc(-0.2, -0.05, 0.7, -0.5, 0.5, 0.13)))
    badge, shade = _cutbadge(fn, 0.14)
    symbol = fn()
    shine = U(circle(-0.6, 0.5, 0.06), seg(-0.52, 0.64, -0.38, 0.74, 0.05))
    return [badge, shade, symbol, shine]


@sticker("notation", "roll", "Buzz roll", ["#D6336C", "#8C1A44", "#FFF4D0", "#FFB8D2"], ink=1.0)
def _():
    fn = lambda: U(_head(-0.15, -0.5, 1.5), seg(0.18, -0.44, 0.18, 0.62, 0.1),
                   *[seg(-0.2, y - 0.1, 0.5, y + 0.14, 0.1) for y in (-0.08, 0.16, 0.4)])
    badge, shade = _cutbadge(fn, 0.15)
    symbol = fn()
    shine = U(circle(-0.62, -0.2, 0.06), seg(-0.58, 0.0, -0.5, 0.14, 0.05))
    return [badge, shade, symbol, shine]