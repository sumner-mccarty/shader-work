PACK = ("garage", "Hot Rods", False)
PRO_IDS = {"hotrod", "engine", "moto", "pump", "grille", "tree"}

RED, REDD = "#E3172F", "#8E0F1E"
CHROME, CHROMED = "#D3D8DF", "#7A808A"
TIRE, TIRED = "#3A3F47", "#16181C"
FLAME, FLAMEY = "#FF7A1A", "#FFD23F"
WHITE = "#FFFFFF"
INK = "#1A1410"


def _shift(make, dx, dy):
    """The shape `make()` draws, slid by (dx, dy)."""
    with rotated(0.0, 0.0, 0.0, dx, dy):
        return make()


def _rim(make, k=0.11):
    """Lower-right shade: the shape minus a copy of itself nudged up-left."""
    return sub(make(), _shift(make, -k, k))


def _flames(x0, x1, y, h, n=3):
    """Licks of flame pointing right: n tongues from a rounded root at x0 reaching toward x1."""
    parts = [circle(x0 + h * 0.5, y, h * 0.55)]
    for k in range(n):
        dy = (k - (n - 1) / 2) * h * 0.62
        reach = x1 - abs(k - (n - 1) / 2) * (x1 - x0) * 0.28
        parts.append(brush([(x0 + h * 0.4, y + dy * 0.5), ((x0 + reach) / 2, y + dy + h * 0.12), (reach, y + dy - h * 0.1)],
                           [h * 0.32, h * 0.2, 0.012]))
    return U(*parts)


# ---- flaming hot rod (side view, facing right, nose down) ----
def _rod():
    return U(poly([(-0.88, -0.24), (0.88, -0.3), (0.88, -0.06), (0.0, 0.06), (-0.88, 0.06)]) - 0.05,
             poly([(-0.8, 0.02), (-0.74, 0.4), (-0.4, 0.4), (-0.18, 0.04)]) - 0.04,
             inter(circle(-0.5, -0.3, 0.36), -0.2 - Y + 0.4))


@sticker("garage", "hotrod", "Hot rod", [RED, REDD, TIRE, FLAMEY], ink=1.0)
def _():
    body = _rod()
    shade = U(_rim(_rod, 0.08), poly([(-0.68, 0.16), (-0.65, 0.31), (-0.44, 0.31), (-0.33, 0.16)]) - 0.02)   # and the dark window
    wheels = U(circle(-0.5, -0.42, 0.3), circle(0.6, -0.46, 0.24))
    flames = U(inter(_flames(-0.3, 0.94, -0.1, 0.24), _rod()), circle(-0.5, -0.42, 0.13), circle(0.6, -0.46, 0.1),
               seg(-0.7, 0.36, -0.46, 0.36, 0.03))
    return [body, shade, wheels, flames]


# ---- crossed pistons ----
def _piston(ang):
    with rotated(ang):
        return U(box(0.0, 0.42, 0.26, 0.24, 0.06), taper(0.0, 0.2, 0.0, -0.56, 0.14, 0.11), ring(0.0, -0.66, 0.15, 0.08))


def _pistons():
    return U(_piston(0.72), _piston(-0.72))


@sticker("garage", "pistons", "Crossed pistons", [CHROME, CHROMED, INK, WHITE], ink=1.0)
def _():
    pistons = _pistons()
    shade = _rim(_pistons, 0.08)
    rings = []
    for a in (0.72, -0.72):
        with rotated(a):
            rings.append(U(box(0.0, 0.5, 0.27, 0.03), box(0.0, 0.38, 0.27, 0.03), circle(0.0, 0.18, 0.06)))
    rings = inter(U(*rings), pistons)
    shine = U(seg(-0.6, 0.38, -0.5, 0.48, 0.035), seg(0.42, 0.62, 0.56, 0.5, 0.035), circle(0.0, 0.0, 0.07))
    return [pistons, shade, rings, shine]


# ---- chrome engine (V8, front view) ----
def _block():
    return U(box(0.0, -0.38, 0.46, 0.34, 0.08),
             poly([(-0.46, -0.12), (-0.84, 0.26), (-0.6, 0.44), (-0.2, 0.06)]) - 0.04,
             poly([(0.46, -0.12), (0.84, 0.26), (0.6, 0.44), (0.2, 0.06)]) - 0.04,
             box(0.0, 0.22, 0.2, 0.16, 0.04), oval(0.0, 0.5, 0.62, 0.22))


@sticker("garage", "engine", "Chrome V8", [CHROME, CHROMED, RED, WHITE], ink=1.0)
def _():
    engine = U(_block(), *[seg(sx * 0.5, -0.3 - 0.14 * k, sx * 0.86, -0.36 - 0.14 * k, 0.05) for sx in (-1, 1) for k in range(3)])
    shade = U(_rim(_block, 0.09), oval(0.0, 0.5, 0.3, 0.09), circle(0.0, -0.42, 0.17),
              *[seg(sx * 0.5, -0.3 - 0.14 * k, sx * 0.86, -0.36 - 0.14 * k, 0.05) for sx in (-1, 1) for k in range(3)])
    covers = U(poly([(-0.48, -0.06), (-0.76, 0.26), (-0.6, 0.36), (-0.28, 0.04)]) - 0.03,
               poly([(0.48, -0.06), (0.76, 0.26), (0.6, 0.36), (0.28, 0.04)]) - 0.03, circle(0.0, -0.42, 0.09))
    shine = U(oval(-0.3, 0.6, 0.18, 0.04, 0.1), seg(-0.36, -0.16, -0.36, -0.54, 0.035), circle(0.4, 0.6, 0.035))
    return [engine, shade, covers, shine]


# ---- racing tire ----
def _tire():
    d = circle(0.0, 0.0, 0.86)
    for k in range(18):
        a = 2 * math.pi * k / 18
        d = sub(d, box(0.86 * math.cos(a), 0.86 * math.sin(a), 0.07, 0.035, 0.0, a))
    return d


@sticker("garage", "tire", "Racing tire", [TIRE, TIRED, RED, WHITE], ink=1.0)
def _():
    tire = _tire()
    shade = sub(_tire(), circle(-0.1, 0.1, 0.84))
    rim = U(sub(circle(0.0, 0.0, 0.46), U(*[circle(0.27 * math.cos(a), 0.27 * math.sin(a), 0.08)
                                             for a in [math.radians(90 + 72 * k) for k in range(5)]])))
    shine = U(arc(0.0, 0.0, 0.66, math.radians(110), math.radians(160), 0.05), circle(0.0, 0.0, 0.08),
              arc(0.0, 0.0, 0.38, math.radians(115), math.radians(155), 0.035))
    return [tire, shade, rim, shine]


# ---- spark plug ----
_PA = -0.5


def _ceramic():
    with rotated(_PA, 0.0, 0.0, 0.08, 0.06):
        return U(box(0.0, 0.34, 0.24, 0.3, 0.08), box(0.0, 0.7, 0.12, 0.1, 0.04))


@sticker("garage", "plug", "Spark plug", ["#F4F1EA", "#B9B3A6", CHROMED, FLAMEY], ink=1.0)
def _():
    ceramic = _ceramic()
    shade = _rim(_ceramic, 0.08)
    with rotated(_PA, 0.0, 0.0, 0.08, 0.06):
        metal = U(box(0.0, 0.86, 0.15, 0.08, 0.04), box(0.0, 0.0, 0.36, 0.13, 0.04),
                  box(0.0, -0.3, 0.22, 0.2, 0.03), polyline([(0.0, -0.52), (0.0, -0.62), (0.13, -0.62)], 0.05))
        threads = U(*[box(0.0, y, 0.25, 0.03, 0.015) for y in (-0.18, -0.32, -0.46)])
        tip = (0.0, -0.78)
    metal = U(metal, threads)
    c, s_ = math.cos(_PA), math.sin(_PA)
    sx, sy = 0.08 + c * tip[0] - s_ * tip[1], 0.06 + s_ * tip[0] + c * tip[1]
    spark = U(star(sx - 0.06, sy - 0.04, 4, 0.3, 0.08, 0.3), seg(-0.24, 0.3, -0.14, 0.5, 0.04))
    return [ceramic, shade, metal, spark]


# ---- NITRO burst ----
def _nburst():
    pts = []
    for k in range(24):
        a = 2 * math.pi * k / 24
        r = 0.92 if k % 2 == 0 else 0.66
        pts.append((r * math.cos(a), r * math.sin(a) * 0.72))
    return poly(pts) - 0.02


@sticker("garage", "nitro", "NITRO", ["#2EC8FF", "#1478C8", "#0A1F44", WHITE], ink=1.0)
def _():
    burst = _nburst()
    shade = _rim(_nburst, 0.1)
    word = text("NITRO", 0.0, 0.0, 0.34, ang=0.08, maxw=1.32)
    shine = U(arc(0.0, 0.0, 0.62, math.radians(125), math.radians(160), 0.04), circle(-0.62, 0.08, 0.04))
    return [burst, shade, word, shine]


# ---- speedometer pegged in the red ----
_SC = (0.0, -0.22)


def _dial():
    return U(inter(circle(_SC[0], _SC[1], 0.88), _SC[1] - 0.16 - Y), box(0.0, _SC[1] - 0.12, 0.88, 0.1, 0.08))


@sticker("garage", "speedo", "Speedometer", [CHROME, CHROMED, INK, RED], ink=1.0)
def _():
    bezel = _dial()
    shade = _rim(_dial, 0.08)
    cx, cy = _SC
    ticks = U(*[seg(cx + 0.56 * math.cos(a), cy + 0.56 * math.sin(a), cx + 0.7 * math.cos(a), cy + 0.7 * math.sin(a), 0.04)
                for a in [math.radians(180 - 22.5 * k) for k in range(7)]])
    face = sub(U(inter(circle(cx, cy, 0.76), cy - 0.06 - Y), box(0.0, cy - 0.04, 0.76, 0.03)), ticks)
    a = math.radians(8)
    redline = inter(ring(cx, cy, 0.63, 0.1), inter(cy - Y, cx + 0.3 - X))
    needle = U(redline, taper(cx, cy, cx + 0.72 * math.cos(a), cy + 0.72 * math.sin(a), 0.075, 0.025), circle(cx, cy, 0.13))
    return [bezel, shade, face, needle]


# ---- wrench and socket ----
def _wrench():
    with rotated(0.78, 0.0, 0.0, -0.08, 0.06):
        handle = box(0.0, 0.0, 0.66, 0.15, 0.13)
        head = sub(circle(-0.66, 0.0, 0.3), U(box(-0.84, 0.0, 0.22, 0.12), circle(-0.62, 0.0, 0.12)))
        ring_end = circle(0.66, 0.0, 0.28)
        return U(sub(U(handle, ring_end), regpoly(0.66, 0.0, 6, 0.14, 0.0)), head)


def _socket():
    return U(box(0.48, -0.44, 0.26, 0.34, 0.07), oval(0.48, -0.1, 0.26, 0.1))


@sticker("garage", "wrench", "Wrench & socket", [CHROME, CHROMED, INK, WHITE], ink=1.0)
def _():
    tools = U(_wrench(), _socket())
    shade = U(_rim(_wrench, 0.08), _rim(_socket, 0.09))
    detail = U(regpoly(0.48, -0.1, 6, 0.14, 0.0), box(0.48, -0.5, 0.27, 0.045))
    with rotated(0.78, 0.0, 0.0, -0.08, 0.06):
        shine = seg(-0.3, 0.06, 0.3, 0.06, 0.04)
    shine = U(shine, seg(0.3, -0.26, 0.3, -0.66, 0.04))
    return [tools, shade, detail, shine]


# ---- motorcycle ----
def _mbody():
    return U(poly([(-0.42, 0.06), (-0.12, 0.34), (0.3, 0.34), (0.44, 0.12), (0.12, -0.18), (-0.24, -0.18)]) - 0.05)


@sticker("garage", "moto", "Motorcycle", [TIRE, RED, REDD, CHROME], ink=1.0)
def _():
    tires = U(ring(-0.52, -0.34, 0.24, 0.12), ring(0.56, -0.34, 0.24, 0.12), box(-0.36, 0.2, 0.22, 0.08, 0.07, -0.1))
    body = U(_mbody(), arc(0.56, -0.34, 0.33, math.radians(40), math.radians(130), 0.07))
    shade = U(_rim(_mbody, 0.08), circle(0.04, -0.2, 0.15))
    chrome = U(seg(0.56, -0.34, 0.38, 0.46, 0.065), seg(0.28, 0.54, 0.54, 0.46, 0.06),
               box(0.02, -0.24, 0.16, 0.14, 0.05), polyline([(-0.12, -0.36), (-0.36, -0.54), (-0.74, -0.54)], 0.06),
               circle(-0.52, -0.34, 0.08), circle(0.56, -0.34, 0.08), oval(-0.1, 0.24, 0.14, 0.04, 0.0))
    return [tires, body, shade, chrome]


# ---- flames decal ----
@sticker("garage", "flames", "Flames decal", [RED, FLAME, FLAMEY, WHITE], ink=1.0)
def _():
    outer = _flames(-0.84, 0.9, 0.0, 0.5)
    middle = inter(_flames(-0.74, 0.62, -0.03, 0.34), outer + 0.06)
    core = inter(_flames(-0.66, 0.3, -0.05, 0.2), middle + 0.06)
    shine = U(seg(-0.6, 0.26, -0.36, 0.34, 0.035), circle(-0.72, 0.16, 0.035))
    return [outer, middle, core, shine]


# ---- retro gas pump ----
def _pump():
    return U(box(-0.12, -0.12, 0.46, 0.66, 0.16), box(-0.12, -0.82, 0.56, 0.08, 0.04))


@sticker("garage", "pump", "Gas pump", [RED, REDD, "#F4F1EA", TIRE], ink=1.0)
def _():
    pump = U(_pump(), circle(-0.12, 0.7, 0.24))
    shade = _rim(_pump, 0.1)
    panel = U(circle(-0.12, 0.7, 0.17), box(-0.12, 0.18, 0.3, 0.2, 0.06), box(-0.12, -0.3, 0.3, 0.07, 0.03),
              seg(-0.44, 0.38, -0.44, -0.4, 0.035))
    hose = U(brush([(0.34, 0.0), (0.6, -0.1), (0.66, -0.5), (0.7, -0.66)], [0.05, 0.05, 0.05, 0.05]),
             box(0.6, 0.12, 0.12, 0.1, 0.04), box(0.72, 0.28, 0.04, 0.12, 0.02), seg(-0.12, 0.18, 0.04, 0.3, 0.035))
    return [pump, shade, panel, hose]


# ---- gear shift knob ----
def _knob():
    return circle(0.0, 0.32, 0.5)


@sticker("garage", "shifter", "Shift knob", [INK, "#000000", WHITE, CHROME], ink=1.0)
def _():
    knob = U(_knob(), poly([(-0.42, -0.86), (0.42, -0.86), (0.2, -0.5), (-0.2, -0.5)]) - 0.03)
    shade = U(_rim(_knob, 0.1))
    pattern = U(seg(-0.24, 0.34, 0.24, 0.34, 0.04), *[seg(x, 0.1, x, 0.58, 0.04) for x in (-0.24, 0.0, 0.24)],
                arc(0.0, 0.32, 0.4, math.radians(115), math.radians(155), 0.04))
    lever = U(box(0.0, -0.3, 0.1, 0.22, 0.03), box(0.0, -0.14, 0.18, 0.06, 0.03))
    return [knob, shade, pattern, lever]


# ---- tachometer (a pillar tach: a can seen from the front, clamp foot) ----
_TF = (0.14, 0.2, 0.5)          # face centre and radius


def _can():
    return U(seg(-0.16, -0.12, _TF[0], _TF[1], 0.6), box(-0.3, -0.72, 0.1, 0.16, 0.03), box(-0.3, -0.84, 0.3, 0.06, 0.03))


@sticker("garage", "tach", "Tachometer", [TIRE, TIRED, WHITE, RED], ink=1.0)
def _():
    can = _can()
    shade = _rim(_can, 0.1)
    cx, cy, r = _TF
    ticks = U(*[seg(cx + (r - 0.16) * math.cos(a), cy + (r - 0.16) * math.sin(a), cx + (r - 0.04) * math.cos(a), cy + (r - 0.04) * math.sin(a), 0.035)
                for a in [math.radians(225 - 33.75 * k) for k in range(9)]])
    face = sub(circle(cx, cy, r), ticks)
    a = math.radians(40)
    red = U(inter(ring(cx, cy, r - 0.1, 0.1), inter(cy - Y, cx + 0.12 - X)),
            taper(cx, cy, cx + (r - 0.06) * math.cos(a), cy + (r - 0.06) * math.sin(a), 0.07, 0.025), circle(cx, cy, 0.1),
            circle(cx + 0.46, cy + 0.5, 0.11))
    return [can, shade, face, red]


# ---- drag-strip light tree ----
def _post():
    return U(box(0.0, 0.08, 0.42, 0.78, 0.1), box(0.0, -0.82, 0.08, 0.1))


@sticker("garage", "tree", "Light tree", ["#4A505A", "#22252B", FLAMEY, "#4CE06A"], ink=1.0)
def _():
    post = _post()
    shade = _rim(_post, 0.08)
    amber = U(*[circle(x, y, 0.13) for x in (-0.2, 0.2) for y in (0.62, 0.32, 0.02)])
    go = U(circle(-0.2, -0.32, 0.15), circle(0.2, -0.32, 0.15))
    return [post, shade, amber, go]


# ---- muscle car grille ----
def _front():
    return U(box(0.0, -0.06, 0.9, 0.4, 0.14), poly([(-0.66, 0.3), (0.66, 0.3), (0.52, 0.62), (-0.52, 0.62)]) - 0.04,
             box(-0.68, -0.52, 0.14, 0.14, 0.04), box(0.68, -0.52, 0.14, 0.14, 0.04))


@sticker("garage", "grille", "Muscle grille", [RED, "#2A0A0E", CHROME, "#FFF4C7"], ink=1.0)
def _():
    car = _front()
    shade = U(_rim(_front, 0.08), box(0.0, -0.02, 0.4, 0.17, 0.04), poly([(-0.46, 0.34), (0.46, 0.34), (0.36, 0.56), (-0.36, 0.56)]))
    chrome = U(*[box(0.0, y, 0.4, 0.025) for y in (-0.08, 0.04)], shell(box(0.0, -0.02, 0.4, 0.17, 0.04), 0.03),
               box(0.0, -0.34, 0.86, 0.07, 0.05), ring(-0.66, -0.02, 0.15, 0.04), ring(0.66, -0.02, 0.15, 0.04))
    lights = U(circle(-0.66, -0.02, 0.11), circle(0.66, -0.02, 0.11), seg(-0.58, 0.18, -0.3, 0.18, 0.035))
    return [car, shade, chrome, lights]


# ---- VROOM ----
def _banner():
    slits = U(*[box(-0.74, y, 0.2, 0.03) for y in (0.16, 0.0, -0.16)])
    return sub(poly([(-0.88, -0.44), (0.7, -0.44), (0.88, 0.44), (-0.7, 0.44)]) - 0.03, slits)


@sticker("garage", "vroom", "VROOM", [INK, FLAMEY, FLAME, WHITE], ink=1.0)
def _():
    back = _banner()
    word = text("VROOM", 0.08, 0.0, 0.9, stretch=0.5, maxw=1.42) - 0.025
    shade = sub(word, text("VROOM", 0.05, 0.03, 0.9, stretch=0.5, maxw=1.42) - 0.025)
    shine = U(inter(word, box(0, 0.16, 1.0, 0.035)), seg(-0.44, 0.36, 0.2, 0.36, 0.035))
    return [back, word, shade, shine]
