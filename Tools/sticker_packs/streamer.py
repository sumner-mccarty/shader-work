PACK = ("streamer", "Streamer", False)
PRO_IDS = {"drumcam", "hypetrain", "stream", "emote", "hype", "raid"}


def _lowright(d, cx=0.0, cy=0.0, k=0.2):
    """The lower-right slice of shape d (the one shade layer), cut along a diagonal through (cx, cy)."""
    return inter(d, k - ((X - cx) - (Y - cy)) * 0.7)


@sticker("streamer", "webcam", "Webcam", ["#4C8DFF", "#2B5FC4", "#1E2438", "#FFFFFF"], ink=1.0)
def _():
    body = U(circle(0, 0.22, 0.64), box(0, -0.42, 0.15, 0.22), box(0, -0.72, 0.52, 0.16, 0.1))
    shade = _lowright(body, 0, 0.0, 0.28)
    lens = circle(0, 0.22, 0.42)
    shine = U(arc(0, 0.22, 0.54, math.radians(115), math.radians(165), 0.045), circle(-0.14, 0.36, 0.09),
              circle(0.1, 0.1, 0.045))
    return [body, shade, lens, shine]


@sticker("streamer", "ringlight", "Ring light", ["#FFF1B8", "#F0C766", "#2B2E3A", "#FFFFFF"], ink=1.0)
def _():
    glow = ring(0, 0.16, 0.56, 0.24)
    shade = _lowright(glow, 0, 0.16, 0.12)
    stand = U(seg(0, -0.4, 0, -0.7, 0.12), seg(0, -0.66, -0.4, -0.8, 0.12), seg(0, -0.66, 0.4, -0.8, 0.12), box(0, -0.4, 0.14, 0.1, 0.04))
    shine = U(arc(0, 0.16, 0.68, math.radians(110), math.radians(165), 0.06), circle(-0.5, 0.52, 0.06))
    return [glow, shade, stand, shine]


@sticker("streamer", "gamingchair", "Gaming chair", ["#FF3D6E", "#B71C47", "#2B2E3A", "#FFFFFF"], ink=1.0)
def _():
    back = U(box(0, 0.26, 0.5, 0.6, 0.22), box(-0.58, 0.0, 0.16, 0.42, 0.08), box(0.58, 0.0, 0.16, 0.42, 0.08), box(0, -0.4, 0.62, 0.15, 0.1))
    shade = _lowright(back, 0, 0.0, 0.3)
    base = U(box(0, 0.8, 0.28, 0.1, 0.05), seg(0, -0.52, 0, -0.72, 0.13), seg(-0.56, -0.84, 0.56, -0.84, 0.13),
             circle(-0.56, -0.84, 0.12), circle(0.56, -0.84, 0.12))
    shine = U(seg(-0.26, 0.1, -0.26, 0.62, 0.07), seg(-0.6, 0.18, -0.6, 0.4, 0.045), seg(-0.44, -0.4, 0.0, -0.4, 0.045))
    return [back, shade, base, shine]


@sticker("streamer", "headset", "Headset", ["#25D0FF", "#0E8FB8", "#2B2E3A", "#FFFFFF"], ink=1.0)
def _():
    band = arc(0, -0.05, 0.56, math.radians(0), math.radians(180), 0.1)
    cups = U(box(-0.62, -0.1, 0.2, 0.32, 0.1), box(0.62, -0.1, 0.2, 0.32, 0.1))
    body = U(band, cups)
    shade = _lowright(body, 0, 0.0, 0.2)
    mic = U(bezier((-0.6, -0.42), (-0.62, -0.9), (-0.1, -0.78), 0.05), circle(-0.1, -0.76, 0.12),
            box(-0.5, -0.1, 0.06, 0.2, 0.03), box(0.5, -0.1, 0.06, 0.2, 0.03))
    shine = U(arc(0, -0.05, 0.56, math.radians(110), math.radians(150), 0.04), seg(-0.68, 0.1, -0.68, -0.04, 0.045))
    return [body, shade, mic, shine]


@sticker("streamer", "chat", "Chat hearts", ["#FFFFFF", "#C9D2E3", "#FF3D7F", "#7FE3FF"], ink=1.0)
def _():
    bubble = U(oval(0, 0.16, 0.86, 0.62), poly([(-0.5, -0.3), (-0.1, -0.4), (-0.62, -0.88)]))
    shade = _lowright(bubble, 0, 0.2, 0.3)
    hearts = U(heart(-0.4, 0.14, 0.3), heart(0.0, 0.3, 0.3), heart(0.4, 0.1, 0.3))
    shine = U(seg(-0.62, 0.5, -0.4, 0.62, 0.05), circle(-0.72, 0.38, 0.05))
    return [bubble, shade, hearts, shine]


@sticker("streamer", "gg", "GG badge", ["#8B5CFF", "#5028C4", "#FFFFFF", "#FFE14A"], ink=1.0)
def _():
    body = circle(0, 0, 0.88)
    shade = _lowright(body, 0, 0, 0.35)
    word = text("GG", 0, -0.02, 0.62, maxw=1.2)
    shine = U(arc(0, 0, 0.74, math.radians(110), math.radians(170), 0.055))
    return [body, shade, word, shine]


@sticker("streamer", "stream", "Stream sign", ["#1B1F33", "#0A0C18", "#FF4A6E", "#FFFFFF"], ink=1.0)
def _():
    plaque = box(0, 0, 0.9, 0.72, 0.14)
    shade = _lowright(plaque, 0, 0, 0.35)
    neon = U(text("STREAM", 0, -0.42, 0.3, maxw=1.7), circle(0, 0.2, 0.34))
    rim = U(ring(0, 0.2, 0.45, 0.035), seg(-0.78, 0.5, -0.56, 0.5, 0.04))
    return [plaque, shade, neon, rim]


@sticker("streamer", "followers", "Follower heart", ["#FF3D7F", "#B71C55", "#FFFFFF", "#FFC2DA"], ink=1.0)
def _():
    body = heart(0, 0.02, 0.98)
    shade = _lowright(body, 0, 0, 0.3)
    word = text("1K", 0, 0.04, 0.5, maxw=0.85)
    shine = seg(-0.55, 0.12, -0.45, 0.32, 0.06)
    return [body, shade, word, shine]


@sticker("streamer", "clip", "Clip", ["#2E3A6E", "#1B2347", "#FFE14A", "#FFFFFF"], ink=1.0)
def _():
    frame = box(0, 0.14, 0.84, 0.6, 0.14)
    shade = _lowright(frame, 0, 0.14, 0.3)
    play = U(poly([(-0.18, 0.5), (-0.18, -0.2), (0.44, 0.15)]) - 0.06,
             box(0, -0.5, 0.64, 0.09, 0.04))
    shine = U(seg(-0.68, 0.58, -0.4, 0.58, 0.05), circle(-0.72, 0.38, 0.05))
    return [frame, shade, play, shine]


@sticker("streamer", "hypetrain", "Hype train", ["#FF3D4E", "#B31B2F", "#FFD23A", "#2B2E3A"], ink=1.0)
def _():
    body = U(box(-0.3, 0.0, 0.26, 0.38, 0.06), box(0.26, -0.12, 0.52, 0.26, 0.12), box(0.58, 0.32, 0.13, 0.16, 0.04),
             box(-0.3, 0.4, 0.34, 0.07, 0.03), box(0.08, -0.42, 0.86, 0.08, 0.03))
    shade = _lowright(body, 0.1, -0.1, 0.2)
    flames = U(smin(circle(0.58, 0.64, 0.17), bezier((0.46, 0.56), (0.4, 0.92), (0.62, 0.9), 0.12, r1=0.02), 0.1),
               taper(-0.56, 0.05, -0.92, 0.2, 0.14, 0.02), taper(-0.56, -0.15, -0.96, -0.14, 0.14, 0.02),
               taper(-0.56, -0.34, -0.9, -0.5, 0.12, 0.02), circle(0.86, -0.14, 0.08), seg(-0.5, 0.2, -0.2, 0.2, 0.04))
    wheels = U(circle(-0.4, -0.58, 0.19), circle(0.1, -0.58, 0.19), circle(0.6, -0.58, 0.19), box(-0.3, 0.14, 0.12, 0.12, 0.03))
    return [body, shade, flames, wheels]


@sticker("streamer", "emote", "Headset face", ["#FFB3D1", "#E5779F", "#25D0FF", "#2B2E3A"], ink=1.0)
def _():
    face = circle(0, 0, 0.7)
    shade = _lowright(face, 0, 0, 0.3)
    headset = U(arc(0, 0, 0.78, math.radians(15), math.radians(165), 0.08), box(-0.8, 0.0, 0.12, 0.28, 0.06),
                box(0.8, 0.0, 0.12, 0.28, 0.06), bezier((0.82, -0.2), (0.78, -0.62), (0.3, -0.62), 0.04), circle(0.28, -0.62, 0.1))
    features = U(sub(oval(-0.26, 0.14, 0.13, 0.2), circle(-0.22, 0.22, 0.05)), sub(oval(0.26, 0.14, 0.13, 0.2), circle(0.3, 0.22, 0.05)),
                 inter(oval(0, -0.28, 0.26, 0.26), Y + 0.15))
    return [face, shade, headset, features]


@sticker("streamer", "raid", "Raid badge", ["#FF5A36", "#B5301A", "#FFE14A", "#FFFFFF"], ink=1.0)
def _():
    body = box(0.1, 0.0, 0.84, 0.52, 0.18)
    shade = _lowright(body, 0.1, 0, 0.3)
    bolt = poly([(-0.52, 0.9), (-0.14, 0.9), (-0.38, 0.12), (-0.08, 0.12), (-0.62, -0.9), (-0.46, -0.1), (-0.78, -0.1)]) - 0.04
    word = text("RAID", 0.3, -0.02, 0.46, maxw=1.05)
    return [body, shade, bolt, word]


@sticker("streamer", "viewers", "Viewer count", ["#FFFFFF", "#BFC9DD", "#1E2438", "#25D0FF"], ink=1.0)
def _():
    almond = inter(circle(0, -0.5, 1.0), circle(0, 0.7, 1.0))
    body = U(almond, box(0, -0.6, 0.62, 0.3, 0.14))
    shade = _lowright(body, 0, -0.1, 0.3)
    iris = U(sub(circle(0, 0.2, 0.34), circle(-0.08, 0.3, 0.06)), text("12K", 0, -0.6, 0.36, maxw=1.0))
    rim = arc(0, 0.2, 0.34, math.radians(20), math.radians(70), 0.035)
    return [body, shade, iris, rim]


_HEART = ["##.##", "#####", "#####", ".###.", "..#.."]


@sticker("streamer", "pixelrain", "Pixel rain", ["#FF3D7F", "#B71C55", "#FFFFFF"], ink=1.0)
def _():
    body = U(pix(_HEART, -0.26, 0.36, 0.2), pix(_HEART, 0.36, -0.08, 0.15), pix(_HEART, -0.06, -0.6, 0.12))
    shade = _lowright(body, 0, 0, 0.1)
    shine = U(pix(["##", "#."], -0.5, 0.52, 0.1), pix(["##", "#."], 0.2, 0.06, 0.08), pix(["#"], -0.18, -0.48, 0.08))
    return [body, shade, shine]


@sticker("streamer", "greenscreen", "Green screen", ["#2FD266", "#1C9A48", "#0F4D26", "#FFFFFF"], ink=1.0)
def _():
    body = box(0, 0, 0.8, 0.8, 0.1)
    shade = _lowright(body, 0, 0, 0.3)
    person = inter(U(circle(0, 0.18, 0.3), ellipse(0, -0.62, 0.62, 0.52)), body)
    marks = U(polyline([(-0.62, 0.3), (-0.62, 0.62), (-0.3, 0.62)], 0.06), polyline([(0.62, -0.3), (0.62, -0.62), (0.3, -0.62)], 0.06))
    return [body, shade, person, marks]


@sticker("streamer", "drumcam", "Drum cam", ["#FF3D6E", "#B71C47", "#F4F1EA", "#2B2E3A"], ink=1.0)
def _():
    with rotated(-0.5, -0.45, 0.55):
        cam = box(-0.45, 0.55, 0.36, 0.24, 0.1)
        lens = box(-0.1, 0.55, 0.14, 0.16, 0.05)
    shell = box(0.14, -0.5, 0.64, 0.32, 0.06)
    body = U(cam, shell)
    shade = _lowright(body, 0.0, 0.0, 0.1)
    snare = U(oval(0.14, -0.2, 0.7, 0.2), seg(-0.7, 0.62, -0.5, 0.7, 0.045))
    stand = U(seg(-0.62, 0.34, -0.62, -0.42, 0.1), lens, *[box(x, -0.52, 0.07, 0.2, 0.03) for x in (-0.3, 0.14, 0.58)])
    return [body, shade, snare, stand]


@sticker("streamer", "bell", "Alert bell", ["#FFC531", "#E09A12", "#FF3D7F", "#FFFFFF"], ink=1.0)
def _():
    bell = U(circle(-0.1, 0.2, 0.5), poly([(-0.6, 0.2), (0.4, 0.2), (0.64, -0.42), (-0.84, -0.42)]), box(-0.1, -0.44, 0.78, 0.1, 0.08),
             circle(-0.1, 0.76, 0.1))
    shade = _lowright(bell, -0.1, 0.1, 0.3)
    badge = U(circle(-0.1, -0.68, 0.15), heart(0.52, 0.5, 0.62))
    shine = U(seg(-0.5, 0.36, -0.38, 0.6, 0.05), seg(-0.7, -0.1, -0.6, -0.3, 0.04))
    return [bell, shade, badge, shine]


@sticker("streamer", "hype", "HYPE", ["#FF3D7F", "#B71C55", "#FFFFFF", "#1E2438"], ink=1.0)
def _():
    burst = star(0, 0, 10, 0.92, 0.66, 0.2) - 0.02
    shade = _lowright(burst, 0, 0, 0.4)
    word = text("HYPE", 0, 0.0, 0.36, ang=0.12, maxw=1.2)
    glow = word - 0.035
    return [burst, shade, glow, word]