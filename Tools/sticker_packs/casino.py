PACK = ("casino", "Casino Night", False)
PRO_IDS = {"roulette", "slots", "winsign", "jackpot", "lucky7"}


def _shift(make, dx, dy):
    """The shape `make()` draws, slid by (dx, dy)."""
    with rotated(0.0, 0.0, 0.0, dx, dy):
        return make()


def _rim(make, dx=-0.1, dy=0.1):
    """Lower-right shade: the shape minus a copy of itself nudged up-left."""
    return sub(make(), _shift(make, dx, dy))


def _lowr(d, c=0.12):
    """The lower-right part of d (beyond a diagonal)."""
    return inter(d, c - (X - Y) * 0.7071)


def _spade(cx, cy, s):
    with rotated(math.pi, cx, cy + 0.0):
        top = heart(cx, cy + 0.06 * s, 0.8 * s)
    return U(top, poly([(cx - 0.12 * s, cy - 0.36 * s), (cx + 0.12 * s, cy - 0.36 * s), (cx, cy - 0.02 * s)]))


def _club(cx, cy, s):
    return U(circle(cx, cy + 0.2 * s, 0.2 * s), circle(cx - 0.2 * s, cy - 0.08 * s, 0.2 * s), circle(cx + 0.2 * s, cy - 0.08 * s, 0.2 * s),
             poly([(cx - 0.12 * s, cy - 0.4 * s), (cx + 0.12 * s, cy - 0.4 * s), (cx, cy)]))


def _diamond(cx, cy, s):
    return poly([(cx, cy + 0.42 * s), (cx + 0.3 * s, cy), (cx, cy - 0.42 * s), (cx - 0.3 * s, cy)])


def _die(cx, cy, size, ang):
    with rotated(ang, cx, cy):
        return box(cx, cy, size, size, size * 0.26)


def _die_pips(cx, cy, size, ang, pts):
    out = []
    with rotated(ang, cx, cy):
        for px, py in pts:
            out.append(circle(cx + px * size, cy + py * size, size * 0.14))
    return U(*out)


FIVE = [(-0.5, 0.5), (0.5, 0.5), (0, 0), (-0.5, -0.5), (0.5, -0.5)]
THREE = [(-0.5, 0.5), (0, 0), (0.5, -0.5)]


# ---- dice ----
def _dice_build():
    return U(_die(-0.3, -0.2, 0.44, -0.25), _die(0.34, 0.32, 0.38, 0.4))


@sticker("casino", "dice", "Lucky dice", ["#FFFFFF", "#B8C4D6", "#E3172F", "#FFD400"], ink=1.0)
def _():
    dice = _dice_build()
    shade = _rim(_dice_build, -0.1, 0.1)
    pips = U(_die_pips(-0.3, -0.2, 0.44, -0.25, FIVE), _die_pips(0.34, 0.32, 0.38, 0.4, THREE))
    sparkle = U(star(0.72, -0.62, 4, 0.2, 0.05), star(-0.78, 0.6, 4, 0.14, 0.04))
    return [dice, shade, pips, sparkle]


# ---- chip ----
def _chip_build():
    return circle(0, 0, 0.86)


@sticker("casino", "chip", "Poker chip", ["#E3172F", "#A80E22", "#FFFFFF", "#FFD400"], ink=1.0)
def _():
    chip = _chip_build()
    shade = _rim(_chip_build, -0.12, 0.12)
    marks = []
    for k in range(8):
        with rotated(k * math.pi / 4):
            marks.append(box(0, 0.72, 0.13, 0.1, 0.02))
    edge = inter(U(*marks), chip)
    inner = U(shell(circle(0, 0, 0.5), 0.04), star(0, 0, 5, 0.3, 0.13))
    return [chip, shade, edge, inner]


# ---- suits ----
@sticker("casino", "suits", "Card suits", ["#FFFFFF", "#B8C4D6", "#E3172F", "#2B2E33"], ink=1.0)
def _():
    card = box(0, 0, 0.84, 0.88, 0.12)
    shade = _lowr(card, 0.5)
    red = U(heart(-0.38, 0.36, 0.4), _diamond(0.4, -0.4, 1.0))
    black = U(_spade(0.4, 0.36, 1.0), _club(-0.4, -0.4, 1.0))
    return [card, shade, red, black]


# ---- ace ----
def _ace_build():
    with rotated(0.2):
        return box(0, 0, 0.64, 0.86, 0.1)


@sticker("casino", "ace", "Ace", ["#FFFFFF", "#B8C4D6", "#E3172F", "#FFD400"], ink=1.0)
def _():
    card = _ace_build()
    shade = _rim(_ace_build, -0.1, 0.1)
    with rotated(0.2):
        red = U(heart(0.0, 0.0, 0.8), heart(-0.36, 0.62, 0.14), heart(0.36, -0.56, 0.14))
        border = shell(box(0, 0, 0.5, 0.72, 0.06), 0.03)
    return [card, shade, red, border]


# ---- slots ----
@sticker("casino", "slots", "Slots", ["#FFC531", "#FFFFFF", "#E3172F", "#3A2C5A"], ink=1.0)
def _():
    frame = box(-0.04, 0.0, 0.8, 0.72, 0.14)
    window = U(box(-0.44, 0.08, 0.22, 0.38, 0.05), box(-0.04, 0.08, 0.22, 0.38, 0.05), box(0.36, 0.08, 0.22, 0.38, 0.05))
    sevens = U(text("7", -0.44, 0.08, 0.5), text("7", -0.04, 0.08, 0.5), text("7", 0.36, 0.08, 0.5))
    lever = U(seg(0.86, -0.1, 0.86, 0.4, 0.07), circle(0.86, 0.5, 0.12), box(-0.04, -0.52, 0.34, 0.06, 0.03))
    return [frame, window, sevens, lever]


# ---- roulette ----
@sticker("casino", "roulette", "Roulette", ["#3A2A1E", "#D6212E", "#FFC531", "#FFFFFF"], ink=1.0)
def _():
    r = np.hypot(X, Y)
    ang = np.arctan2(Y, X)
    base = circle(0, 0, 0.88)
    wedges = -np.sin(6.0 * ang) * (r / 6.0)
    red = inter(inter(wedges, np.maximum(r - 0.7, 0.4 - r)), base)
    hub = U(circle(0, 0, 0.26), seg(-0.5, 0.0, 0.5, 0.0, 0.05), seg(0.0, -0.5, 0.0, 0.5, 0.05), ring(0, 0, 0.74, 0.03))
    ball = circle(0.48, 0.32, 0.08)
    return [base, red, hub, ball]


# ---- jackpot ----
@sticker("casino", "jackpot", "Jackpot", ["#FFC531", "#D99A00", "#8A5A00", "#FFFFFF"], ink=1.0)
def _():
    stack = U(*[U(ellipse(0, -0.62 + 0.17 * k, 0.6, 0.2), box(0, -0.7 + 0.17 * k, 0.6, 0.09)) for k in range(3)])
    coin = circle(0, 0.22, 0.52)
    coins = U(stack, coin)
    coinrim = U(ring(0, 0.22, 0.4, 0.035), *[sub(ellipse(0, -0.62 + 0.17 * k, 0.6, 0.2), ellipse(0, -0.52 + 0.17 * k, 0.6, 0.2)) for k in range(3)])
    dollar = text("$", 0.0, 0.22, 0.5)
    sparkle = U(star(0.7, 0.7, 4, 0.2, 0.05), star(-0.72, 0.58, 4, 0.13, 0.04))
    return [coins, coinrim, dollar, sparkle]


# ---- horseshoe ----
def _shoe_build():
    return U(arc(0, 0.06, 0.52, math.radians(150), math.radians(390), 0.22), box(-0.58, -0.46, 0.2, 0.16, 0.04), box(0.58, -0.46, 0.2, 0.16, 0.04))


@sticker("casino", "horseshoe", "Horseshoe", ["#F2B632", "#B7791F", "#5A3A0A", "#FFFFFF"], ink=1.0)
def _():
    shoe = _shoe_build()
    shade = _rim(_shoe_build, -0.1, 0.1)
    nails = U(*[circle(0.52 * math.cos(math.radians(a)), 0.06 + 0.52 * math.sin(math.radians(a)), 0.07) for a in (200, 235, 270, 305, 340)])
    shine = arc(0, 0.06, 0.52, math.radians(200), math.radians(235), 0.05)
    return [shoe, shade, nails, shine]


# ---- lucky clover ----
@sticker("casino", "clover", "Lucky clover", ["#FFC531", "#2EB04F", "#1B7A36", "#FFFFFF"], ink=1.0)
def _():
    token = box(0, 0, 0.86, 0.86, 0.3)
    leaves = []
    veins = []
    for k in range(4):
        with rotated(k * math.pi / 2):
            leaves.append(heart(0.0, 0.4, 0.4))
            veins.append(seg(0.0, 0.08, 0.0, 0.5, 0.035))
    clover = U(*leaves)
    leafshade = U(*veins, circle(0, 0, 0.07))
    shine = U(seg(-0.4, 0.5, -0.26, 0.62, 0.045), circle(-0.52, 0.4, 0.04))
    return [token, clover, leafshade, shine]


# ---- dealer visor ----
def _chipstack_stack(cx, n, y0):
    return U(*[U(ellipse(cx, y0 + 0.2 * k, 0.42, 0.17), box(cx, y0 + 0.2 * k - 0.09, 0.42, 0.09)) for k in range(n)])


@sticker("casino", "chipstack", "Chip stacks", ["#E3172F", "#2F7BE0", "#FFFFFF", "#2B2E33"], ink=1.0)
def _():
    redstack = _chipstack_stack(-0.45, 2, -0.2)
    bluestack = _chipstack_stack(0.45, 4, -0.5)
    stripes_ = U(*[box(cx + dx, y0 + 0.2 * k - 0.09, 0.07, 0.06) for cx, n, y0 in ((-0.45, 2, -0.2), (0.45, 4, -0.5)) for k in range(n) for dx in (-0.22, 0.22)])
    front = U(ellipse(0.0, -0.68, 0.4, 0.16), box(0.0, -0.77, 0.4, 0.09))
    return [redstack, bluestack, stripes_, front]


# ---- WIN sign ----
def _win_build():
    return box(0, 0, 0.86, 0.5, 0.14)


@sticker("casino", "winsign", "Win sign", ["#5A1A3C", "#3A0E26", "#FFD400", "#FFF4C7"], ink=1.0)
def _():
    sign = _win_build()
    shade = _rim(_win_build, -0.1, 0.1)
    pts = [(x, y) for x in (-0.66, -0.33, 0.0, 0.33, 0.66) for y in (0.36, -0.36)] + [(-0.76, 0.0), (0.76, 0.0)]
    bulbs = U(*[circle(x, y, 0.075) for x, y in pts])
    word = text("WIN", 0.0, 0.0, 0.42, maxw=1.2)
    return [sign, shade, bulbs, word]


# ---- lucky coin ----
def _koban_build():
    return oval(0, 0, 0.56, 0.84)


def _coin_build():
    return sub(circle(0, 0.2, 0.58), box(0, 0.2, 0.16, 0.16, 0.02))


@sticker("casino", "luckycoin", "Lucky coin", ["#FFC531", "#D99A00", "#8A5A00", "#E3172F"], ink=1.0)
def _():
    coin = _coin_build()
    shade = _rim(_coin_build, -0.1, 0.1)
    rim = U(ring(0, 0.2, 0.46, 0.04), shell(box(0, 0.2, 0.2, 0.2, 0.03), 0.03))
    tassel = U(circle(0, -0.46, 0.1), seg(0, -0.46, 0, -0.58, 0.08), poly([(-0.2, -0.58), (0.2, -0.58), (0.28, -0.94), (0.1, -0.84), (0.0, -0.94), (-0.1, -0.84), (-0.28, -0.94)]))
    return [coin, shade, rim, tassel]


# ---- cherry pair ----
@sticker("casino", "cherries", "Cherry symbol", ["#FFF4D6", "#E3172F", "#2E9E4F", "#FFFFFF"], ink=1.0)
def _():
    tile = box(0, 0, 0.86, 0.86, 0.22)
    cherries = U(circle(-0.3, -0.3, 0.3), circle(0.32, -0.22, 0.28))
    stems = U(bezier((-0.3, -0.0), (-0.1, 0.5), (0.12, 0.56), 0.05), bezier((0.32, 0.06), (0.3, 0.4), (0.12, 0.56), 0.05), oval(0.32, 0.56, 0.26, 0.1, 0.35))
    shine = U(seg(-0.46, -0.16, -0.38, -0.06, 0.04), seg(0.2, -0.08, 0.28, 0.02, 0.04))
    return [tile, cherries, stems, shine]


# ---- lucky 7 ----
def _lucky7_build():
    return star(0, 0, 14, 0.9, 0.76) - 0.03


@sticker("casino", "lucky7", "Lucky 7", ["#E3172F", "#A80E22", "#FFFFFF", "#FFD400"], ink=1.0)
def _():
    badge = _lucky7_build()
    shade = _rim(_lucky7_build, -0.1, 0.1)
    ring_ = shell(circle(0, 0, 0.64), 0.04)
    seven = text("7", 0.0, 0.0, 0.9)
    return [badge, shade, ring_, seven]


# ---- top hat ----
def _tophat_build():
    return U(box(0, 0.16, 0.42, 0.5, 0.08), oval(0, -0.4, 0.9, 0.22))


@sticker("casino", "tophat", "Top hat", ["#3B3552", "#241F38", "#E3172F", "#FFFFFF"], ink=1.0)
def _():
    hat = _tophat_build()
    shade = _rim(_tophat_build, -0.1, 0.1)
    band = box(0, -0.2, 0.43, 0.11)
    with rotated(0.3, 0.3, -0.14):
        card = box(0.3, -0.1, 0.19, 0.28, 0.04)
    return [hat, shade, band, card]


# ---- ALL IN ----
def _allin_build():
    return box(0, 0, 0.72, 0.82, 0.26)


@sticker("casino", "allin", "All in", ["#1F8F55", "#146B3E", "#FFD400", "#E3172F"], ink=1.0)
def _():
    felt = _allin_build()
    shade = _rim(_allin_build, -0.1, 0.1)
    word = U(text("ALL", 0.0, 0.3, 0.46, maxw=1.2), text("IN", 0.0, -0.28, 0.46, maxw=1.2))
    border = shell(box(0, 0, 0.6, 0.7, 0.2), 0.03)
    return [felt, shade, word, border]


