# Piccione Macchina (art v2, blocks): a pigeon truck, after the original meme image (by
# @piccionemacchina, 2025-04-16): a grey pigeon (a shiny green-and-purple neck, an orange
# eye, a dark beak) fused with a sharp-edged silver pickup truck (a flat sloped roof, dark
# windows, black wheels); big grey wings spread up from its back, and it walks on pigeon
# legs in chunky white sneakers. No logos on the shoes or the truck. Ours: a light bar
# glows across the truck's nose and tail (a Godly).
import math

from voxel_art import block, both, plate, rod, solid, turned, wedge

TY, TZ = 10.4, 0.6  # the truck's middle
TW, TL = 8.4, 15.0

body = [
    block(0, TY - 0.6, TZ, TW, 3.2, TL, "Silver"),  # a sharp-edged silver truck...
    wedge(0, TY + 2.4, TZ - 3.2, TW - 0.2, 2.8, 5.6, "Silver"),  # ...its sloped windshield...
    wedge(0, TY + 2.4, TZ + 3.4, TW - 0.2, 2.8, 6.8, "Silver", rot=(0, 180, 0)),  # ...the long sloped roof behind
    turned(0, TY + 2.45, TZ - 3.3, TW - 1.0, 2.2, 0.2, "Window", (1, 0, 0), (0, 0.45, 0.89)),  # dark windows
    block(0, TY + 1.4, TZ - 7.55, TW - 0.6, 0.5, 0.3, "Glow"),  # a light bar across its nose...
    block(0, TY + 0.6, TZ + 7.55, TW - 0.6, 0.5, 0.3, "GlowRed"),  # ...and its tail
]
for s in (-1, 1):
    body += [
        block(s * (TW / 2 + 0.05), TY + 1.6, TZ, 0.3, 1.6, 6.0, "Window"),
        solid("Cylinder", s * (TW / 2 - 0.4), TY - 2.4, TZ - 4.6, 1.6, 4.0, 4.0, "Tire"),  # black wheels
        solid("Cylinder", s * (TW / 2 - 0.4), TY - 2.4, TZ + 4.6, 1.6, 4.0, 4.0, "Tire"),
        solid("Cylinder", s * (TW / 2 + 0.2), TY - 2.4, TZ - 4.6, 0.6, 2.2, 2.2, "Hub"),
        solid("Cylinder", s * (TW / 2 + 0.2), TY - 2.4, TZ + 4.6, 0.6, 2.2, 2.2, "Hub"),
    ]

HY, HZ = TY + 7.0, TZ - 4.0  # the pigeon's head and neck
head = [
    block(0, HY - 3.0, HZ + 0.6, 4.4, 4.2, 4.0, "Neck"),  # a shiny green-and-purple neck...
    block(0, HY - 1.7, HZ + 0.4, 4.2, 1.4, 3.8, "NeckPurple"),
    block(0, HY + 0.4, HZ, 4.0, 3.6, 4.4, "Grey"),  # ...a grey pigeon head...
    block(0, HY + 0.1, HZ - 2.8, 1.4, 1.0, 1.6, "Beak"),  # ...a dark beak...
    block(0, HY + 0.65, HZ - 2.4, 1.6, 0.6, 1.0, "Cere"),
]
head += both(
    solid("Cylinder", 1.9, HY + 0.8, HZ - 0.8, 0.5, 1.4, 1.4, "Eye"),  # ...an orange eye
    solid("Cylinder", 2.1, HY + 0.8, HZ - 0.8, 0.4, 0.6, 0.6, "Dark"),
)

arms = []
for s in (-1, 1):  # big grey wings spread up from its back
    for k in range(4):
        a = math.radians(30 + k * 14)
        d = (s * math.cos(a) * 0.5, math.sin(a), 0.3 + k * 0.05)
        n = math.sqrt(sum(c * c for c in d))
        d = tuple(c / n for c in d)
        base = (s * 2.6, TY + 2.8, TZ + 0.6 + k * 0.9)
        length = 9.0 - k * 1.2
        c = tuple(base[i] + d[i] * length / 2 for i in range(3))
        w = (-d[2] * d[0], -d[2] * d[1], 1.0 - d[2] * d[2])  # (front-to-back, square to d)
        m = math.sqrt(sum(v * v for v in w))
        arms.append(turned(*c, 3.4, length, 0.8, "Wing" if k % 2 == 0 else "WingDark", tuple(v / m for v in w), d))
    arms.append(block(s * 3.0, TY + 2.4, TZ + 1.6, 1.6, 2.2, 5.0, "Wing"))

legs = []
for s in (-1, 1):  # pigeon legs in chunky white sneakers
    x = s * 2.4
    legs += [
        rod((x, TY - 2.0, TZ - 0.4), (x, 3.0, TZ - 0.6), 1.2, "Leg"),
        block(x, 1.6, TZ - 1.2, 3.2, 2.4, 5.6, "Sneaker"),  # a chunky sneaker...
        block(x, 0.3, TZ - 1.2, 3.4, 0.6, 6.0, "SneakerSole"),
        block(x, 2.0, TZ - 3.95, 3.0, 1.2, 0.3, "SneakerDark"),
    ]
    for k in range(3):
        legs.append(block(x, 2.95, TZ - 2.2 + k * 1.0, 2.0, 0.3, 0.3, "SneakerDark"))

ART = {
    "Comment": "Piccione Macchina: a grey pigeon with a shiny green-and-purple neck fused with a sharp-edged silver pickup truck, big grey wings spread up, walking on pigeon legs in chunky white sneakers; a glowing light bar across the truck.",
    "VoxelSize": 0.24,  # (a Godly: bigger than the rest)
    "Palette": {
        "Silver": (190, 196, 204),
        "Window": (40, 46, 56),
        "Glow": (220, 240, 255),
        "GlowRed": (255, 60, 60),
        "Tire": (30, 30, 34),
        "Hub": (120, 126, 136),
        "Grey": (134, 138, 150),
        "Neck": (70, 140, 110),
        "NeckPurple": (130, 90, 150),
        "Beak": (50, 46, 46),
        "Cere": (230, 226, 220),
        "Eye": (240, 140, 40),
        "Dark": (20, 18, 18),
        "Wing": (150, 154, 166),
        "WingDark": (110, 114, 126),
        "Leg": (200, 110, 110),
        "Sneaker": (246, 246, 244),
        "SneakerSole": (226, 226, 222),
        "SneakerDark": (200, 200, 204),
    },
    "Materials": {"Glow": "Neon", "GlowRed": "Neon", "Silver": "Metal"},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
