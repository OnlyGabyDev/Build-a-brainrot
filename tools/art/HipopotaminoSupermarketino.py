# Hipopotamino Supermarketino (art v2, blocks): a supermarket hippo, the 101st, after the
# Greek meme by @froutatoudasous69 (2025-03-17; no original image could be reached: drawn
# from its description, redraw it from the original when we have it): a big grey-pink hippo
# whose body is a supermarket's shelving unit full of colorful goods (boxes, bottles, cans,
# fruit, price strips); a wide hippo head (a huge muzzle, nostril bumps, little ears, small
# eyes on top) above it, stubby legs, and a red shopping basket in one hand. Ours: a light
# strip on top and the price strips glow (a Godly).
import math

from voxel_art import block, both, plate, rod, solid

SY, SZ = 11.6, 0.6  # the shelving unit's middle
SW, SH, SD = 11.4, 12.0, 7.0

body = [
    block(0, SY, SZ + SD / 2 - 0.3, SW, SH, 0.6, "Frame"),  # a shelving unit: its back...
    block(0, SY + SH / 2 - 0.3, SZ, SW, 0.6, SD, "Frame"),  # ...top...
    block(0, SY - SH / 2 + 0.3, SZ, SW, 0.6, SD, "Frame"),  # ...bottom...
    block(0, SY + SH / 2 + 0.4, SZ - 1.0, SW - 1.0, 0.4, 1.0, "Light"),  # (a light strip on top)
]
for s in (-1, 1):
    body.append(block(s * (SW / 2 - 0.2), SY, SZ, 0.8, SH + 0.4, SD + 0.4, "Hide"))  # ...its sides are the hippo's flanks
ROWS = [SY - 3.0, SY + 1.0, SY + 5.0]  # (shelf tops)
GOODS = [
    ("box", "Red", "Yellow"), ("bottle", "Green", None), ("can", "Blue", "White"), ("fruit", "Orange", None),
    ("box", "Purple", "White"), ("bottle", "Pink", None), ("fruit", "Apple", None), ("can", "Yellow", "Red"),
    ("box", "Blue", "Yellow"), ("can", "Green", "White"), ("bottle", "Orange", None), ("box", "Pink", "White"),
]
for r, top in enumerate(ROWS):
    body.append(block(0, top - 0.3, SZ, SW - 1.2, 0.6, SD - 0.8, "Shelf"))  # a shelf...
    body.append(block(0, top - 0.3, SZ - SD / 2 + 0.05, SW - 1.2, 0.7, 0.3, "Price"))  # ...its glowing price strip
    for k in range(4):  # ...full of colorful goods
        kind, a, b = GOODS[(r * 4 + k) % len(GOODS)]
        x = -3.6 + k * 2.4
        z = SZ - 1.2
        if kind == "box":
            body += [block(x, top + 1.4, z, 1.8, 2.8, 1.8, a), plate(x, top + 1.6, z - 0.95, 1.2, 0.8, b, depth=0.15)]
        elif kind == "bottle":
            body += [solid("Cylinder", x, top + 1.2, z, 2.4, 1.3, 1.3, a, rot=(0, 0, 90)), solid("Cylinder", x, top + 2.8, z, 0.9, 0.6, 0.6, a, rot=(0, 0, 90)), solid("Cylinder", x, top + 3.3, z, 0.3, 0.7, 0.7, "White", rot=(0, 0, 90))]
        elif kind == "can":
            body += [solid("Cylinder", x, top + 1.0, z, 2.0, 1.5, 1.5, a, rot=(0, 0, 90)), solid("Cylinder", x, top + 1.0, z, 0.6, 1.6, 1.6, b, rot=(0, 0, 90))]
        else:
            body += [solid("Ball", x - 0.4, top + 0.8, z, 1.4, 1.4, 1.4, a), solid("Ball", x + 0.5, top + 0.8, z - 0.2, 1.4, 1.4, 1.4, a), solid("Ball", x, top + 1.9, z, 1.4, 1.4, 1.4, a)]

HY, HZ = SY + SH / 2 + 3.6, SZ - 0.8  # the hippo's head
head = [
    block(0, HY, HZ + 1.0, 8.6, 5.4, 6.6, "Hide"),  # a wide hippo head...
    block(0, HY - 0.8, HZ - 3.4, 10.0, 4.6, 4.4, "Hide"),  # ...a huge muzzle...
    block(0, HY - 2.6, HZ - 3.2, 9.6, 1.2, 4.2, "HidePink"),
    block(0, HY - 1.9, HZ - 5.65, 6.0, 0.5, 0.3, "Dark"),  # (its smile)
]
head += both(
    solid("Ball", 2.4, HY + 1.2, HZ - 4.6, 2.4, 2.4, 2.4, "Hide"),  # nostril bumps...
    plate(2.4, HY + 1.4, HZ - 5.75, 0.8, 0.5, "Dark", depth=0.15),
    block(2.4, HY + 3.1, HZ - 0.8, 1.8, 1.4, 1.8, "Hide"),  # small eyes on top...
    plate(2.4, HY + 3.2, HZ - 1.75, 1.0, 0.9, "Eye", depth=0.2),
    plate(2.2, HY + 3.4, HZ - 1.9, 0.3, 0.3, "Glint", depth=0.1),
    block(3.6, HY + 3.0, HZ + 2.6, 1.2, 1.2, 0.8, "HidePink"),  # ...little ears
    block(4.0, HY - 2.2, HZ - 5.3, 0.8, 1.6, 0.8, "Tooth"),  # (little tusks)
)

arms = []
for s in (-1, 1):  # stubby hippo arms...
    arms += [
        solid("Ball", s * (SW / 2 + 0.6), SY + 4.2, SZ, 3.6, 3.6, 3.6, "Hide"),
        rod((s * (SW / 2 + 1.0), SY + 3.6, SZ), (s * (SW / 2 + 1.6), SY - 0.6, SZ - 1.6), 2.6, "Hide"),
        block(s * (SW / 2 + 1.6), SY - 1.4, SZ - 1.8, 2.6, 1.6, 2.6, "HidePink"),
    ]
BX, BYY, BZ = SW / 2 + 1.6, SY - 4.2, SZ - 2.4  # ...one holding a red shopping basket
arms += [
    block(BX, BYY, BZ, 3.4, 2.6, 4.4, "Basket"),
    block(BX, BYY + 1.2, BZ, 2.8, 0.4, 3.8, "BasketDark"),
    rod((BX, BYY + 1.3, BZ - 1.6), (BX, SY - 1.6, BZ), 0.4, "BasketDark"),
    rod((BX, BYY + 1.3, BZ + 1.6), (BX, SY - 1.6, BZ), 0.4, "BasketDark"),
    solid("Ball", BX - 0.6, BYY + 1.8, BZ - 0.8, 1.4, 1.4, 1.4, "Apple"),
    block(BX + 0.6, BYY + 2.0, BZ + 0.8, 1.2, 1.8, 1.0, "Yellow"),
]

legs = []
for s in (-1, 1):  # stubby legs
    legs += [
        block(s * 3.2, 3.2, SZ, 3.8, 5.2, 4.2, "Hide"),
        block(s * 3.2, 0.5, SZ - 0.4, 4.2, 1.0, 4.8, "HidePink"),
    ]

ART = {
    "Comment": "Hipopotamino Supermarketino: a big grey-pink hippo whose body is a supermarket shelving unit full of colorful boxes, bottles, cans and fruit with glowing price strips, a wide hippo head on top, stubby legs, a red shopping basket.",
    "VoxelSize": 0.24,  # (a Godly: bigger than the rest)
    "Palette": {
        "Hide": (150, 136, 150),
        "HidePink": (214, 160, 170),
        "Dark": (36, 28, 32),
        "Eye": (40, 30, 36),
        "Glint": (250, 250, 250),
        "Tooth": (250, 246, 236),
        "Frame": (236, 238, 240),
        "Shelf": (190, 196, 204),
        "Price": (255, 230, 70),
        "Light": (220, 250, 255),
        "Red": (220, 50, 50),
        "Yellow": (250, 210, 50),
        "Green": (60, 180, 80),
        "Blue": (60, 120, 220),
        "White": (250, 250, 250),
        "Orange": (250, 140, 40),
        "Purple": (150, 80, 200),
        "Pink": (240, 120, 180),
        "Apple": (210, 40, 50),
        "Basket": (210, 40, 50),
        "BasketDark": (160, 24, 32),
    },
    "Materials": {"Price": "Neon", "Light": "Neon"},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
