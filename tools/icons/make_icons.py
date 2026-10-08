"""
The UI icon set (UI v3: no emojis). Each icon is a glossy sticker: shapes filled with a
top-to-bottom gradient, a white gloss across their top, a darker rim at their bottom, a
thin dark line round each shape and a thick one round the whole icon (thicker at the
bottom, like a sticker standing up). Pure Python + PIL (numpy runs this machine out of
memory). Drawn at 1024 and shrunk to 256 for smooth edges.

    python tools/icons/make_icons.py            -> tools/icons/ui/<Name>.png + a contact sheet
    python tools/icons/make_icons.py Coin Gem   -> just those

Upload: serve tools/icons/ui with `python -m http.server 8765 --bind 127.0.0.1` and pass
http://localhost:8765/<Name>.png to the MCP's upload_image; the ids go in
sync/ReplicatedStorage/Shared/Config/Icons.luau.
"""

import math
import os
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageOps

S = 1024  # drawing size
OUT = 256  # file size
OUTLINE = (30, 25, 45)  # Kit.Outline
HERE = os.path.dirname(os.path.abspath(__file__))
OUT_DIR = os.path.join(HERE, "ui")


def u(v):
    """Design units (0-100) to pixels."""
    return v * S / 100


# Masks ----------------------------------------------------------------------


def blank():
    return Image.new("L", (S, S), 0)


def circle(cx, cy, r):
    m = blank()
    ImageDraw.Draw(m).ellipse([u(cx - r), u(cy - r), u(cx + r), u(cy + r)], fill=255)
    return m


def ellipse(x0, y0, x1, y1):
    m = blank()
    ImageDraw.Draw(m).ellipse([u(x0), u(y0), u(x1), u(y1)], fill=255)
    return m


def rect(x0, y0, x1, y1, r=0):
    m = blank()
    ImageDraw.Draw(m).rounded_rectangle([u(x0), u(y0), u(x1), u(y1)], radius=u(r), fill=255)
    return m


def poly(points):
    m = blank()
    ImageDraw.Draw(m).polygon([(u(x), u(y)) for x, y in points], fill=255)
    return m


def line(points, width):
    """A thick polyline with round joints and ends."""
    m = blank()
    d = ImageDraw.Draw(m)
    pts = [(u(x), u(y)) for x, y in points]
    d.line(pts, fill=255, width=int(u(width)), joint="curve")
    for x, y in pts[:1] + pts[-1:]:
        r = u(width) / 2
        d.ellipse([x - r, y - r, x + r, y + r], fill=255)
    return m


def pie(cx, cy, r, a0, a1):
    """A wedge; angles in degrees, clockwise from 3 o'clock."""
    m = blank()
    ImageDraw.Draw(m).pieslice([u(cx - r), u(cy - r), u(cx + r), u(cy + r)], a0, a1, fill=255)
    return m


def ring(cx, cy, r_out, r_in):
    return sub(circle(cx, cy, r_out), circle(cx, cy, r_in))


def arc(cx, cy, r_out, r_in, a0, a1):
    return sub(pie(cx, cy, r_out, a0, a1), circle(cx, cy, r_in))


def star(cx, cy, R, r, points=5, turn=-90):
    pts = []
    for i in range(points * 2):
        a = math.radians(turn + i * 180 / points)
        rad = R if i % 2 == 0 else r
        pts.append((cx + rad * math.cos(a), cy + rad * math.sin(a)))
    return poly(pts)


def sparkle(cx, cy, R, k=2.6):
    """A four-point twinkle with curved sides."""
    pts = []
    for i in range(96):
        t = 2 * math.pi * i / 96
        c, s = math.cos(t), math.sin(t)
        pts.append((cx + R * math.copysign(abs(c) ** k, c), cy + R * math.copysign(abs(s) ** k, s)))
    return poly(pts)


def union(*ms):
    out = ms[0]
    for m in ms[1:]:
        out = ImageChops.lighter(out, m)
    return out


def sub(a, b):
    return ImageChops.subtract(a, b)


def inter(a, b):
    return ImageChops.multiply(a, b)


def threshold(m, level):
    return m.point(lambda v: 255 if v > level else 0)


def grow(m, px):
    if px <= 0:
        return m
    return threshold(m.filter(ImageFilter.GaussianBlur(px / 1.9)), 8)


def shrink(m, px):
    return ImageOps.invert(grow(ImageOps.invert(m), px))


def rounded(m, r):
    """Rounds every corner by about r units."""
    return threshold(m.filter(ImageFilter.GaussianBlur(u(r))), 127)


def rotate(m, degrees, cx=50, cy=50):
    """Turns a mask clockwise round (cx, cy)."""
    return m.rotate(-degrees, resample=Image.BICUBIC, center=(u(cx), u(cy)))


def move(m, dx, dy):
    return ImageChops.offset(m, int(u(dx)), int(u(dy)))


# Painting -------------------------------------------------------------------


def vertical(top_value, bottom_value, y0, y1):
    """An L image that goes from top_value at y0 to bottom_value at y1."""
    col = Image.new("L", (1, S))
    span = max(1, y1 - y0)
    col.putdata([int(top_value + (bottom_value - top_value) * min(1, max(0, (y - y0) / span))) for y in range(S)])
    return col.resize((S, S), Image.NEAREST)


class Layer:
    def __init__(self, mask, top, bottom=None, line=True, gloss=0.55, shade=0.3, line_color=OUTLINE, line_width=2.2):
        self.mask = mask
        self.top = top
        self.bottom = bottom or top
        self.line = line
        self.gloss = gloss
        self.shade = shade
        self.line_color = line_color
        self.line_width = line_width


def fill(img, mask, color):
    img.paste(Image.new("RGBA", (S, S), color + (255,)), (0, 0), mask)


def paint(layers, outer=3.6, depth=1.8, gloss_height=0.5):
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    every = union(*[layer.mask for layer in layers])
    # the thick outline round the whole sticker, deeper at the bottom
    edge = grow(every, u(outer))
    fill(img, union(edge, move(edge, 0, depth)), OUTLINE)
    for layer in layers:
        m = layer.mask
        box = m.getbbox()
        if not box:
            continue
        if layer.line:
            fill(img, grow(m, u(layer.line_width)), layer.line_color)
        # gradient
        g = Image.linear_gradient("L").resize((box[2] - box[0], box[3] - box[1]))
        colored = ImageOps.colorize(g, layer.top, layer.bottom).convert("RGBA")
        sheet = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        sheet.paste(colored, box[:2])
        img.paste(sheet, (0, 0), m)
        h = box[3] - box[1]
        # a darker rim along the bottom
        if layer.shade > 0:
            rim = sub(m, move(m, 0, -max(2.5, h / S * 100 * 0.1)))
            rim = inter(rim.filter(ImageFilter.GaussianBlur(u(0.8))), m)
            rim = rim.point(lambda v: int(v * layer.shade))
            img.paste(Image.new("RGBA", (S, S), (0, 0, 0, 255)), (0, 0), rim)
        # the gloss: an inset ellipse over the top, fading down
        if layer.gloss > 0:
            w = box[2] - box[0]
            inset = shrink(m, u(2.2))
            cap = blank()
            ImageDraw.Draw(cap).ellipse([box[0] + w * 0.06, box[1] - h * 0.1, box[2] - w * 0.06, box[1] + h * gloss_height * 1.6], fill=255)
            shine = inter(inset, cap)
            fade = vertical(int(255 * layer.gloss), 0, box[1], box[1] + int(h * gloss_height))
            shine = inter(shine, fade)
            img.paste(Image.new("RGBA", (S, S), (255, 255, 255, 255)), (0, 0), shine)
    return img


def save(name, img):
    os.makedirs(OUT_DIR, exist_ok=True)
    img.resize((OUT, OUT), Image.LANCZOS).save(os.path.join(OUT_DIR, f"{name}.png"))


# Palette (top, bottom) --------------------------------------------------------

GOLD = ((255, 232, 100), (255, 150, 25))
GOLD_DARK = ((255, 200, 60), (225, 120, 15))
GOLD_LINE = (175, 95, 10)
STEEL = ((235, 240, 250), (150, 160, 185))
RED = ((255, 120, 120), (215, 40, 60))
GREEN = ((150, 250, 120), (35, 170, 65))
BLUE = ((120, 215, 255), (40, 120, 245))
PINK = ((255, 150, 225), (225, 60, 170))
PURPLE = ((200, 150, 255), (120, 65, 230))
WHITE = ((255, 255, 255), (222, 226, 238))
DARK = ((70, 62, 90), (40, 34, 55))
YELLOW = ((255, 248, 140), (255, 190, 30))
ORANGE = ((255, 200, 90), (255, 120, 30))
BROWN = ((215, 150, 90), (150, 90, 45))


def L(mask, colors, **kw):
    return Layer(mask, colors[0], colors[1], **kw)


# The icons --------------------------------------------------------------------

ICONS = {}


def icon(fn):
    ICONS[fn.__name__] = fn
    return fn


@icon
def Coin():
    return paint([
        L(circle(50, 52, 40), GOLD_DARK),
        L(circle(50, 52, 30), GOLD, line_color=GOLD_LINE, line_width=1.6, gloss=0.35),
        L(rounded(star(50, 54, 19, 8.5), 1), ((255, 200, 70), (235, 130, 20)), line_color=GOLD_LINE, line_width=1.4, gloss=0, shade=0),
    ])


@icon
def Gem():
    crown = [(18, 40), (32, 20), (68, 20), (82, 40)]
    tip = (50, 88)
    whole = rounded(poly(crown + [tip]), 1.2)
    facets = [
        (poly([(18, 40), (32, 20), (40, 40)]), (150, 235, 255)),
        (poly([(32, 20), (68, 20), (60, 40), (40, 40)]), (200, 248, 255)),
        (poly([(68, 20), (82, 40), (60, 40)]), (110, 205, 255)),
        (poly([(18, 40), (40, 40), tip]), (70, 170, 250)),
        (poly([(40, 40), (60, 40), tip]), (110, 200, 255)),
        (poly([(60, 40), (82, 40), tip]), (40, 120, 235)),
    ]
    layers = [L(whole, BLUE, gloss=0, shade=0)]
    for m, color in facets:
        layers.append(Layer(inter(m, whole), color, color, line=True, line_color=(30, 90, 190), line_width=0.7, gloss=0, shade=0))
    layers.append(Layer(inter(rect(18, 20, 82, 40), whole), (255, 255, 255), (255, 255, 255), line=False, gloss=0.0, shade=0))
    img = paint(layers[:-1])
    # a soft gloss over the crown and a twinkle
    shine = inter(shrink(inter(rect(18, 20, 82, 40), whole), u(2)), vertical(150, 20, int(u(20)), int(u(40))))
    img.paste(Image.new("RGBA", (S, S), (255, 255, 255, 255)), (0, 0), shine)
    twinkle = paint([Layer(sparkle(76, 22, 12), (255, 255, 255), (235, 250, 255), line_width=1.4, gloss=0, shade=0)], outer=1.6, depth=0)
    img.alpha_composite(twinkle)
    return img


def face_point(a, b, A, B, D):
    return (A[0] + a * (B[0] - A[0]) + b * (D[0] - A[0]), A[1] + a * (B[1] - A[1]) + b * (D[1] - A[1]))


def face_pip(a, b, r, A, B, D):
    return poly([face_point(a + r * math.cos(t), b + r * math.sin(t), A, B, D) for t in [2 * math.pi * i / 32 for i in range(32)]])


@icon
def Roll():
    T, Rt, C, Lt = (50, 12), (86, 31), (50, 50), (14, 31)
    Bl, Br, Bot = (14, 71), (86, 71), (50, 90)
    whole = rounded(poly([T, Rt, Br, Bot, Bl, Lt]), 3)
    top = inter(poly([T, Rt, C, Lt]), whole)
    left = inter(poly([Lt, C, Bot, Bl]), whole)
    right = inter(poly([C, Rt, Br, Bot]), whole)
    pip = (250, 250, 255)
    layers = [
        Layer(top, (255, 200, 245), (255, 150, 230), line_width=1.2, gloss=0.5, shade=0),
        Layer(left, (245, 110, 210), (215, 60, 185), line_width=1.2, gloss=0.25, shade=0.2),
        Layer(right, (190, 90, 245), (140, 55, 215), line_width=1.2, gloss=0.2, shade=0.2),
    ]
    pips = [face_pip(0.5, 0.5, 0.15, T, Rt, Lt)]
    pips += [face_pip(a, a, 0.13, Lt, C, Bl) for a in (0.28, 0.72)]
    pips += [face_pip(a, a, 0.12, C, Rt, Bot) for a in (0.24, 0.5, 0.76)]
    for m in pips:
        layers.append(Layer(m, pip, (225, 225, 240), line=True, line_width=0.8, gloss=0, shade=0))
    return paint(layers)


@icon
def Gift():
    ribbon = GOLD
    return paint([
        L(ellipse(24, 10, 50, 36), ribbon, gloss=0.4),
        L(ellipse(50, 10, 76, 36), ribbon, gloss=0.4),
        L(rect(20, 46, 80, 90, 3), PINK),
        L(rect(14, 32, 86, 50, 4), ((255, 175, 230), (240, 90, 185))),
        L(rect(43, 32, 57, 90), ribbon, line_width=1.6, gloss=0.3, shade=0),
        L(circle(50, 30, 8), ribbon, line_width=1.6, gloss=0.4, shade=0),
    ])


@icon
def Star():
    return paint([L(rounded(star(50, 54, 44, 20), 2.5), GOLD)])


def shackle(cy, left_bottom):
    band = union(arc(50, cy, 21, 10, 180, 360), rect(29, cy, 40, 50), rect(60, cy, 71, 50))
    if left_bottom < 50:
        band = sub(band, rect(28, left_bottom, 41, 50))
    return band


def lock_body(layers):
    layers.append(L(rect(16, 44, 84, 92, 10), GOLD))
    layers.append(Layer(union(circle(50, 62, 7.5), poly([(45.5, 64), (54.5, 64), (57, 80), (43, 80)])), (80, 50, 30), (50, 30, 20), line=False, gloss=0, shade=0))
    return layers


@icon
def Lock():
    return paint(lock_body([L(shackle(34, 50), STEEL)]))


@icon
def Unlock():
    return paint(lock_body([L(shackle(27, 34), STEEL)]))


@icon
def Sparkle():
    return paint([
        L(sparkle(44, 56, 40), ((255, 255, 215), (255, 195, 50)), gloss=0.4),
        L(sparkle(78, 22, 11), ((255, 255, 230), (255, 210, 80)), gloss=0, line_width=1.6),
    ])


@icon
def Check():
    return paint([L(rounded(poly([(12, 52), (27, 37), (42, 52), (74, 18), (89, 33), (42, 82)]), 2.5), GREEN)])


@icon
def Close():
    bar = rect(42, 8, 58, 92, 6)
    return paint([L(union(rotate(bar, 45), rotate(bar, -45)), WHITE, gloss=0.3)], outer=3.2)


@icon
def Wheel():
    colors = [(255, 90, 90), (255, 160, 60), (255, 225, 70), (110, 220, 90), (70, 210, 230), (80, 140, 255), (170, 100, 255), (255, 110, 200)]
    layers = [L(circle(50, 54, 42), GOLD_DARK, gloss=0)]
    for i, color in enumerate(colors):
        wedge = pie(50, 54, 35, -90 + i * 45, -90 + (i + 1) * 45)
        layers.append(Layer(wedge, color, tuple(int(c * 0.82) for c in color), line=True, line_color=(255, 255, 255), line_width=0.8, gloss=0, shade=0))
    for i in range(8):
        a = math.radians(-90 + 22.5 + i * 45)
        layers.append(Layer(circle(50 + 38.5 * math.cos(a), 54 + 38.5 * math.sin(a), 2.4), (255, 255, 230), (255, 230, 140), line=False, gloss=0, shade=0))
    layers.append(L(circle(50, 54, 9), GOLD, line_width=1.6))
    layers.append(L(rounded(poly([(40, 4), (60, 4), (50, 24)]), 1.2), RED, line_width=1.6, gloss=0.3))
    img = paint(layers)
    shine = inter(shrink(circle(50, 54, 35), u(2)), vertical(110, 0, int(u(19)), int(u(56))))
    img.paste(Image.new("RGBA", (S, S), (255, 255, 255, 255)), (0, 0), shine)
    return img


@icon
def Gear():
    teeth = union(*[rotate(rect(42, 8, 58, 30, 3), i * 45) for i in range(8)])
    body = sub(union(circle(50, 50, 32), teeth), circle(50, 50, 12))
    return paint([L(rounded(body, 1.5), ((200, 225, 255), (95, 125, 190)))])


@icon
def Factory():
    wall = rect(10, 48, 90, 90, 3)
    roof = union(*[poly([(10 + i * 26.7, 48), (10 + i * 26.7, 30), (10 + (i + 1) * 26.7, 48)]) for i in range(3)])
    return paint([
        L(rect(66, 18, 80, 40, 2), ((200, 200, 215), (130, 130, 155))),
        L(union(circle(73, 13, 7), circle(84, 8, 5)), WHITE, gloss=0.2, line_width=1.6),
        L(rounded(roof, 0.8), ((160, 110, 245), (100, 55, 200))),
        L(wall, PURPLE),
        Layer(union(rect(17, 58, 32, 71, 2), rect(42.5, 58, 57.5, 71, 2), rect(68, 58, 83, 71, 2)), (255, 245, 150), (255, 200, 60), line_width=1.4, gloss=0.3, shade=0),
        Layer(rect(42, 76, 58, 90, 2), (110, 70, 200), (80, 45, 160), line_width=1.4, gloss=0, shade=0),
    ])


@icon
def Album():
    return paint([
        L(rect(26, 14, 88, 92, 6), ((255, 255, 250), (225, 218, 205)), gloss=0),
        L(rect(14, 9, 80, 88, 8), BLUE),
        Layer(rect(14, 9, 27, 88, 6), (80, 160, 245), (30, 90, 210), line_width=1.2, gloss=0.3, shade=0),
        L(rounded(star(53, 46, 19, 8.5), 1.2), GOLD, line_width=1.8),
        Layer(rect(36, 70, 70, 76, 3), (255, 255, 255), (230, 240, 255), line=False, gloss=0, shade=0),
    ])


def arrow_arc(cx, cy, r_out, r_in, a0, a1, head=15):
    band = arc(cx, cy, r_out, r_in, a0, a1)
    a = math.radians(a1)
    rm = (r_out + r_in) / 2
    px, py = cx + rm * math.cos(a), cy + rm * math.sin(a)
    radial = (math.cos(a), math.sin(a))
    tangent = (-math.sin(a), math.cos(a))
    half = (r_out - r_in) / 2 + 8
    tip = (px + tangent[0] * head, py + tangent[1] * head)
    b1 = (px + radial[0] * half - tangent[0] * 2, py + radial[1] * half - tangent[1] * 2)
    b2 = (px - radial[0] * half - tangent[0] * 2, py - radial[1] * half - tangent[1] * 2)
    return union(band, poly([b1, tip, b2]))


@icon
def Rebirth():
    return paint([
        L(rounded(arrow_arc(50, 52, 37, 23, 190, 325), 1), GOLD),
        L(rounded(arrow_arc(50, 52, 37, 23, 10, 145), 1), GOLD),
    ])


@icon
def Cart():
    return paint([
        L(line([(8, 18), (20, 18), (30, 66), (80, 66)], 7), DARK, gloss=0.2),
        L(rounded(poly([(20, 26), (88, 26), (80, 58), (28, 58)]), 2), GREEN),
        Layer(union(rect(36, 32, 41, 52, 2), rect(51, 32, 56, 52, 2), rect(66, 32, 71, 52, 2)), (255, 255, 255), (220, 255, 220), line=False, gloss=0, shade=0),
        L(circle(36, 80, 8), DARK, gloss=0.3),
        L(circle(74, 80, 8), DARK, gloss=0.3),
    ])


@icon
def Clover():
    layers = [L(line([(52, 50), (60, 72), (72, 90)], 7), ((120, 210, 90), (50, 140, 50)), gloss=0)]
    for angle in (225, 315, 135, 45):
        a = math.radians(angle)
        cx, cy = 50 + 22 * math.cos(a), 46 + 22 * math.sin(a)
        px, py = -math.sin(a), math.cos(a)
        heart = union(
            circle(cx + px * 9 + math.cos(a) * 3, cy + py * 9 + math.sin(a) * 3, 11.5),
            circle(cx - px * 9 + math.cos(a) * 3, cy - py * 9 + math.sin(a) * 3, 11.5),
            poly([(cx + px * 19, cy + py * 19 + 0), (50 + math.cos(a) * 2, 46 + math.sin(a) * 2), (cx - px * 19, cy - py * 19)]),
        )
        layers.append(L(rounded(heart, 1), GREEN, line_width=1.8))
    return paint(layers)


@icon
def Clock():
    return paint([
        L(circle(24, 22, 11), GOLD),
        L(circle(76, 22, 11), GOLD),
        L(circle(50, 56, 37), RED),
        L(circle(50, 56, 28), WHITE, line_width=1.6, gloss=0.25),
        Layer(union(line([(50, 56), (50, 37)], 6), line([(50, 56), (64, 62)], 6)), (60, 50, 80), (40, 34, 55), line=False, gloss=0, shade=0),
        Layer(circle(50, 56, 4.5), (255, 120, 120), (215, 40, 60), line=False, gloss=0, shade=0),
    ])


@icon
def Lightning():
    return paint([L(rounded(poly([(60, 4), (20, 56), (46, 56), (36, 96), (82, 38), (55, 38), (70, 4)]), 1.2), YELLOW)])


def note_shape():
    head1 = rotate(ellipse(16, 66, 44, 86), -20, 30, 76)
    head2 = rotate(ellipse(56, 58, 84, 78), -20, 70, 68)
    stems = union(rect(36, 22, 44, 76), rect(76, 14, 84, 68))
    beam = poly([(36, 22), (84, 12), (84, 27), (36, 37)])
    return union(head1, head2, stems, beam)


@icon
def Music():
    return paint([L(note_shape(), PINK)])


@icon
def MusicOff():
    return paint([
        L(note_shape(), ((210, 200, 220), (150, 140, 170))),
        L(line([(14, 14), (86, 86)], 11), RED, gloss=0.3),
    ])


@icon
def Nuke():
    blades = union(pie(50, 52, 34, 240, 300), pie(50, 52, 34, 0, 60), pie(50, 52, 34, 120, 180))
    blades = sub(blades, circle(50, 52, 10))
    return paint([
        L(circle(50, 52, 42), YELLOW),
        Layer(union(blades, circle(50, 52, 6.5)), (60, 52, 75), (35, 30, 45), line=False, gloss=0, shade=0),
    ])


@icon
def Crown():
    body = rounded(poly([(12, 34), (32, 58), (50, 26), (68, 58), (88, 34), (82, 84), (18, 84)]), 1.5)
    return paint([
        L(circle(12, 31, 7), GOLD, line_width=1.8),
        L(circle(50, 22, 7.5), GOLD, line_width=1.8),
        L(circle(88, 31, 7), GOLD, line_width=1.8),
        L(body, GOLD),
        L(rect(18, 68, 82, 84, 2), GOLD_DARK, gloss=0.25, line_width=1.6),
        Layer(circle(34, 76, 4.6), (255, 120, 140), (210, 30, 60), line_width=1.2, gloss=0.3, shade=0),
        Layer(circle(50, 76, 4.6), (120, 215, 255), (40, 120, 245), line_width=1.2, gloss=0.3, shade=0),
        Layer(circle(66, 76, 4.6), (150, 250, 120), (35, 170, 65), line_width=1.2, gloss=0.3, shade=0),
    ])


@icon
def Magnet():
    u_shape = union(arc(50, 50, 36, 15, 0, 180), rect(14, 14, 35, 50), rect(65, 14, 86, 50))
    return paint([
        L(u_shape, RED),
        L(rect(14, 12, 35, 28), STEEL, line_width=1.8, shade=0.15),
        L(rect(65, 12, 86, 28), STEEL, line_width=1.8, shade=0.15),
    ])


@icon
def Radar():
    bright = (130, 255, 160)
    rings = union(ring(50, 50, 28.5, 26.5), ring(50, 50, 15, 13), rect(49, 10, 51, 90), rect(10, 49, 90, 51))
    rings = inter(rings, circle(50, 50, 40))
    img = paint([
        L(circle(50, 50, 42), ((50, 110, 75), (20, 60, 40)), gloss=0),
        Layer(rings, bright, (90, 220, 120), line=False, gloss=0, shade=0),
        Layer(pie(50, 50, 40, -70, -5), (120, 255, 150), (60, 200, 100), line=False, gloss=0, shade=0),
        L(circle(67, 34, 5.5), ((235, 255, 235), (150, 255, 170)), line_width=1.4, gloss=0, shade=0),
    ])
    shine = inter(shrink(circle(50, 50, 42), u(2.5)), vertical(90, 0, int(u(8)), int(u(46))))
    img.paste(Image.new("RGBA", (S, S), (255, 255, 255, 255)), (0, 0), shine)
    return img


@icon
def Shoe():
    upper = rounded(poly([(12, 66), (16, 30), (40, 30), (50, 46), (72, 52), (88, 64), (88, 74), (12, 74)]), 2)
    return paint([
        L(upper, RED),
        Layer(union(line([(30, 46), (40, 62)], 4.5), line([(40, 44), (52, 62)], 4.5)), (255, 255, 255), (230, 230, 240), line=False, gloss=0, shade=0),
        L(rect(8, 70, 92, 86, 7), WHITE, gloss=0.2),
    ])


@icon
def Mask():
    mask = rounded(union(ellipse(6, 26, 54, 78), ellipse(46, 26, 94, 78), rect(30, 28, 70, 56)), 1.5)
    mask = sub(mask, union(ellipse(17, 40, 43, 62), ellipse(57, 40, 83, 62)))
    return paint([L(mask, PURPLE)])


@icon
def Rocket():
    body = inter(ellipse(34, 4, 66, 84), rect(34, 4, 66, 70))
    fins = union(poly([(34, 48), (18, 74), (36, 70)]), poly([(66, 48), (82, 74), (64, 70)]))
    flame = union(circle(50, 78, 8), poly([(42, 78), (58, 78), (50, 96)]))
    def r(m):
        return rotate(m, 45, 50, 52)
    return paint([
        L(r(rounded(flame, 1)), ORANGE, gloss=0.2),
        L(r(rounded(fins, 1)), RED),
        L(r(body), WHITE),
        L(r(circle(50, 34, 8)), BLUE, line_width=1.8),
    ])


@icon
def Hammer():
    def r(m):
        return rotate(m, -35, 50, 50)
    return paint([
        L(r(rect(45, 38, 55, 90, 4)), BROWN),
        L(r(rect(20, 16, 80, 44, 8)), RED),
        L(r(rect(20, 16, 30, 44, 4)), STEEL, line_width=1.6, gloss=0.3),
        L(r(rect(70, 16, 80, 44, 4)), STEEL, line_width=1.6, gloss=0.3),
    ])


@icon
def Wrench():
    head = sub(circle(50, 24, 20), rect(42, 0, 58, 24))
    tool = union(head, rect(41, 30, 59, 92, 8))
    tool = sub(tool, circle(50, 82, 4.5))
    return paint([L(rotate(rounded(tool, 1), 40, 50, 50), STEEL)])


@icon
def ArrowUp():
    return paint([L(rounded(poly([(50, 6), (90, 48), (66, 48), (66, 92), (34, 92), (34, 48), (10, 48)]), 2), GREEN)])


@icon
def Arrow():
    return paint([L(rounded(poly([(8, 36), (50, 36), (50, 12), (92, 50), (50, 88), (50, 64), (8, 64)]), 2), WHITE)])


@icon
def Pin():
    return paint([
        L(rounded(union(circle(50, 38, 30), poly([(23, 50), (77, 50), (50, 94)])), 1.5), RED),
        Layer(circle(50, 37, 11), (255, 255, 255), (230, 232, 240), line=True, line_width=1.6, gloss=0, shade=0),
    ])


@icon
def Trophy():
    cup = inter(ellipse(22, -12, 78, 64), rect(22, 12, 78, 64))
    return paint([
        L(ring(23, 32, 14, 6.5), GOLD_DARK, gloss=0.2),
        L(ring(77, 32, 14, 6.5), GOLD_DARK, gloss=0.2),
        L(rect(44, 58, 56, 74), GOLD_DARK, gloss=0.2),
        L(cup, GOLD),
        L(rect(30, 72, 70, 82, 3), GOLD_DARK, line_width=1.8),
        L(rect(24, 80, 76, 92, 3), BROWN, line_width=1.8),
        Layer(rounded(star(50, 34, 11, 5), 0.6), (255, 255, 240), (255, 235, 160), line_color=GOLD_LINE, line_width=1.2, gloss=0, shade=0),
    ])


@icon
def Preview():
    """A magnifier over a green up arrow: see the next upgrade."""
    cx, cy, r, a = 42, 42, 28, 0.7071
    arrow = poly([(cx, cy - 18), (cx + 16, cy - 1), (cx + 6.5, cy - 1), (cx + 6.5, cy + 16), (cx - 6.5, cy + 16), (cx - 6.5, cy - 1), (cx - 16, cy - 1)])
    return paint([
        L(line([(cx + (r + 4) * a, cy + (r + 4) * a), (86, 86)], 14), RED),
        L(line([(cx + (r + 3) * a, cy + (r + 3) * a), (cx + (r + 11) * a, cy + (r + 11) * a)], 19), GOLD_DARK, line_width=1.6, gloss=0.2),
        L(ring(cx, cy, r + 7, r - 1), GOLD),
        Layer(circle(cx, cy, r - 1), (235, 252, 255), (130, 205, 250), line_width=1.4, gloss=0.45, shade=0.12),
        L(rounded(arrow, 1.2), GREEN, line_width=1.6, gloss=0.35, shade=0.15),
    ])


@icon
def Puzzle():
    piece = union(rect(20, 30, 72, 82, 5), circle(80, 56, 10), circle(46, 22, 10))
    piece = sub(piece, union(circle(20, 56, 8), circle(46, 82, 8)))
    return paint([L(rounded(piece, 1.2), ORANGE)])


@icon
def Storm():
    cloud = rounded(union(circle(30, 46, 16), circle(52, 36, 21), circle(72, 46, 15), rect(16, 44, 86, 62, 9)), 1)
    return paint([
        L(cloud, ((235, 240, 255), (150, 165, 210))),
        L(rounded(poly([(52, 50), (34, 76), (48, 76), (40, 96), (68, 66), (54, 66), (64, 50)]), 1), YELLOW, line_width=1.8),
    ])


def falling_gift(cx, cy, size, colors, tilt):
    """A small Gift (its bow, lid and ribbon) `size` tall centered on (cx, cy), turned `tilt` degrees."""
    k = size / 80

    def at(x, y):
        return cx + (x - 50) * k, cy + (y - 50) * k

    def box(x0, y0, x1, y1, r=0):
        (a0, b0), (a1, b1) = at(x0, y0), at(x1, y1)
        return rotate(rect(a0, b0, a1, b1, r * k), tilt, cx, cy)

    def oval(x0, y0, x1, y1):
        (a0, b0), (a1, b1) = at(x0, y0), at(x1, y1)
        return rotate(ellipse(a0, b0, a1, b1), tilt, cx, cy)

    knot_x, knot_y = at(50, 30)
    lid = (min(255, colors[0][0] + 20), min(255, colors[0][1] + 20), min(255, colors[0][2] + 20)), colors[1]
    return [
        L(oval(24, 10, 50, 36), WHITE, gloss=0.4, line_width=1.4),
        L(oval(50, 10, 76, 36), WHITE, gloss=0.4, line_width=1.4),
        L(box(20, 46, 80, 90, 3), colors, line_width=1.6),
        L(box(14, 32, 86, 50, 4), lid, line_width=1.6),
        L(box(43, 32, 57, 90), WHITE, line_width=1.2, gloss=0.3, shade=0),
        L(rotate(circle(knot_x, knot_y, 8 * k), tilt, cx, cy), WHITE, line_width=1.2, gloss=0.4, shade=0),
    ]


@icon
def LootRain():
    """The Loot Rain: a cloud letting gift boxes fall."""
    cloud = rounded(union(circle(30, 28, 15), circle(52, 19, 18), circle(72, 29, 13), rect(16, 27, 85, 42, 8)), 1)
    layers = [L(cloud, ((245, 248, 255), (165, 185, 235)))]
    layers += falling_gift(23, 66, 30, BLUE, -16)
    layers += falling_gift(79, 62, 28, PINK, 18)
    layers += falling_gift(51, 78, 32, GOLD, 6)
    return paint(layers)


@icon
def Party():
    cone = rounded(poly([(10, 92), (30, 40), (62, 72)]), 1)
    stripes = inter(cone, union(rotate(rect(0, 56, 100, 63), -45, 36, 66), rotate(rect(0, 70, 100, 77), -45, 36, 66)))
    layers = [
        L(cone, GOLD),
        Layer(stripes, (255, 110, 160), (225, 50, 120), line=False, gloss=0, shade=0),
    ]
    bits = [((58, 18, 6), PINK), ((80, 30, 5.5), BLUE), ((72, 50, 5), GREEN), ((44, 26, 4.5), YELLOW), ((86, 12, 4.5), PURPLE)]
    for (x, y, r), colors in bits:
        layers.append(L(circle(x, y, r), colors, line_width=1.6, gloss=0.3, shade=0))
    return paint(layers)


@icon
def Nut():
    hexagon = poly([(50 + 40 * math.cos(math.radians(30 + i * 60)), 52 + 40 * math.sin(math.radians(30 + i * 60))) for i in range(6)])
    return paint([
        L(sub(rounded(hexagon, 2), circle(50, 52, 15)), STEEL),
        Layer(ring(50, 52, 15, 11), (120, 130, 150), (90, 98, 120), line=False, gloss=0, shade=0),
    ])


@icon
def Warning():
    return paint([
        L(rounded(poly([(50, 8), (94, 88), (6, 88)]), 3), YELLOW),
        Layer(union(rect(45, 34, 55, 64, 4), circle(50, 75, 5.5)), (60, 52, 75), (35, 30, 45), line=False, gloss=0, shade=0),
    ])


@icon
def Plus():
    return paint([L(union(rect(38, 10, 62, 90, 6), rect(10, 38, 90, 62, 6)), WHITE, gloss=0.3)], outer=3.2)


@icon
def Brain():
    lobes = union(circle(32, 40, 18), circle(50, 30, 20), circle(68, 40, 18), circle(30, 58, 17), circle(70, 58, 17), circle(50, 62, 20))
    folds = union(line([(50, 16), (50, 74)], 3), line([(30, 38), (40, 46)], 3), line([(70, 38), (60, 46)], 3), line([(28, 62), (38, 58)], 3), line([(72, 62), (62, 58)], 3))
    return paint([
        L(rounded(lobes, 1), ((255, 190, 225), (240, 110, 175))),
        Layer(inter(folds, shrink(lobes, u(3))), (215, 80, 150), (190, 60, 130), line=False, gloss=0, shade=0),
    ])


@icon
def Calendar():
    body = rect(10, 16, 90, 92, 10)
    return paint([
        L(body, WHITE, gloss=0.25),
        L(inter(body, rect(10, 16, 90, 40)), RED, line_width=1.8),
        L(rounded(star(50, 67, 19, 8.5), 1.2), GOLD, line_width=1.8),
        L(rect(26, 6, 37, 28, 5), STEEL, line_width=1.6),
        L(rect(63, 6, 74, 28, 5), STEEL, line_width=1.6),
    ])


# Textures ---------------------------------------------------------------------


def stripes():
    """A tileable band of white 45-degree stripes (tinted and faded in the UI)."""
    size = 512
    img = Image.new("L", (size, size), 0)
    px = img.load()
    for y in range(size):
        for x in range(size):
            if (x + y) % 256 < 96:
                px[x, y] = 255
    small = img.resize((128, 128), Image.LANCZOS)
    out = Image.new("RGBA", (128, 128), (255, 255, 255, 0))
    out.putalpha(small)
    out.save(os.path.join(OUT_DIR, "Stripes.png"))


def glow():
    """A soft white disc that fades out to the edge."""
    size = 256
    img = Image.new("RGBA", (size, size), (255, 255, 255, 0))
    px = img.load()
    for y in range(size):
        for x in range(size):
            d = math.hypot(x - size / 2 + 0.5, y - size / 2 + 0.5) / (size / 2)
            a = max(0.0, 1 - d) ** 1.8
            px[x, y] = (255, 255, 255, int(255 * a))
    img.save(os.path.join(OUT_DIR, "Glow.png"))


def sheet(names):
    cols = 8
    cell = 136
    rows = math.ceil(len(names) / cols)
    out = Image.new("RGBA", (cols * cell, rows * cell), (120, 175, 240, 255))
    for i, name in enumerate(names):
        im = Image.open(os.path.join(OUT_DIR, f"{name}.png")).resize((120, 120), Image.LANCZOS)
        out.alpha_composite(im, ((i % cols) * cell + 8, (i // cols) * cell + 8))
    path = os.path.join(os.environ.get("ICON_SHEET_DIR", HERE), "ui_sheet.png")
    out.save(path)
    print("sheet:", path)


if __name__ == "__main__":
    os.makedirs(OUT_DIR, exist_ok=True)
    wanted = sys.argv[1:] or list(ICONS)
    for name in wanted:
        if name in ICONS:
            save(name, ICONS[name]())
            print("drew", name)
    if not sys.argv[1:]:
        stripes()
        glow()
    sheet([n for n in wanted if n in ICONS])
