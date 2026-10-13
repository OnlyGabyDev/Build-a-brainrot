# Bobrinni Kokokosinni (art v2, blocks): a coconut beaver, after the meme by
# @ai_video_maker_7 (2025-03-12; no original image could be reached: drawn from its
# description, redraw it from the original when we have it): a beaver whose round body is
# a hairy brown coconut cracked open on its belly (white flesh), a brown beaver head with
# buck teeth, round ears and whiskers, little paws, short legs with dark webbed feet and a
# flat criss-crossed tail.
import math

from voxel_art import block, both, plate, rod, solid, turned

C = (0.0, 9.0, 1.0)  # the coconut's middle
R = 6.4

body = [solid("Ball", *C, 2 * R, 2 * R, 2 * R, "Coco")]  # a hairy brown coconut...
for k in range(24):  # ...fibres
    a = math.radians(k * 137.5)
    y = 0.9 - 1.7 * (k + 0.5) / 24
    r = math.sqrt(max(0.0, 1 - y * y))
    d = (math.cos(a) * r, y, math.sin(a) * r)
    if d[2] < -0.5 and abs(d[1]) < 0.6:  # (not over the belly)
        continue
    p = (C[0] + d[0] * R, C[1] + d[1] * R, C[2] + d[2] * R)
    t = (-d[2], 0.3, d[0])
    body.append(rod(tuple(p[i] - t[i] * 0.9 for i in range(3)), tuple(p[i] + t[i] * 0.9 for i in range(3)), 0.35, "Fibre"))
body += [  # ...cracked open on its belly
    solid("Cylinder", 0, C[1] - 0.6, C[2] - R + 1.2, 2.6, 7.6, 7.6, "Shell", rot=(0, 90, 0)),
    solid("Cylinder", 0, C[1] - 0.6, C[2] - R + 0.1, 0.4, 6.6, 6.6, "Flesh", rot=(0, 90, 0)),
    solid("Cylinder", 0, C[1] - 0.6, C[2] - R - 0.15, 0.3, 4.4, 4.4, "Milk", rot=(0, 90, 0)),
]

HY, HZ = C[1] + R + 2.4, C[2] - 0.6  # the head
head = [
    block(0, HY, HZ, 6.4, 5.6, 5.6, "Fur"),  # a brown beaver head...
    block(0, HY - 1.2, HZ - 3.1, 3.6, 2.6, 1.6, "FurLight"),  # ...a pale muzzle...
    block(0, HY - 0.3, HZ - 4.05, 1.6, 1.0, 0.5, "Nose"),  # ...a dark nose...
    block(0, HY - 2.8, HZ - 3.6, 1.4, 1.2, 0.4, "Tooth"),  # ...buck teeth
    plate(0, HY - 2.8, HZ - 3.85, 0.15, 1.0, "Nose", depth=0.1),
]
head += both(
    plate(1.6, HY + 1.0, HZ - 2.95, 0.9, 0.9, "Eye", depth=0.2),  # eyes
    plate(1.45, HY + 1.2, HZ - 3.1, 0.3, 0.3, "Glint", depth=0.1),
    solid("Cylinder", 2.8, HY + 2.6, HZ + 0.2, 0.8, 1.9, 1.9, "FurDark", rot=(0, 70, 0)),  # round ears
    rod((1.6, HY - 1.0, HZ - 3.9), (4.0, HY - 0.6, HZ - 3.6), 0.2, "Whisker"),  # whiskers
    rod((1.6, HY - 1.4, HZ - 3.9), (4.0, HY - 1.8, HZ - 3.5), 0.2, "Whisker"),
)

arms = []
for s in (-1, 1):  # little paws
    arms += [
        rod((s * 4.8, C[1] + 2.4, C[2] - 2.6), (s * 3.6, C[1] - 0.2, C[2] - 6.2), 1.6, "Fur"),
        block(s * 3.4, C[1] - 0.6, C[2] - 6.6, 1.6, 1.2, 1.4, "FurDark"),
    ]

legs = []
for s in (-1, 1):  # short legs with dark webbed feet
    legs += [
        block(s * 2.8, 2.6, C[2], 2.6, 3.2, 2.8, "Fur"),
        block(s * 2.8, 0.6, C[2] - 1.0, 3.2, 1.2, 4.2, "Feet"),
    ]
legs += [  # a flat criss-crossed tail
    rod((0, 2.0, C[2] + 3.0), (0, 0.8, C[2] + 5.6), 2.0, "Fur"),
    turned(0, 0.5, C[2] + 9.0, 5.4, 7.0, 0.8, "Tail", (1, 0, 0), (0, 0, 1)),
]
for k in range(4):
    legs.append(turned(-1.8 + k * 1.2, 0.95, C[2] + 9.0, 0.2, 6.4, 0.2, "TailDark", (1, 0, 0), (0, 0, 1)))
    legs.append(turned(0, 0.95, C[2] + 6.8 + k * 1.5, 4.8, 0.2, 0.2, "TailDark", (1, 0, 0), (0, 0, 1)))

ART = {
    "Comment": "Bobrinni Kokokosinni: a beaver whose round body is a hairy coconut cracked open on its belly, a brown head with buck teeth and round ears, little paws, short legs with webbed feet, a flat criss-crossed tail.",
    "VoxelSize": 0.2,
    "Palette": {
        "Coco": (126, 82, 46),
        "Fibre": (92, 58, 32),
        "Shell": (84, 52, 30),
        "Flesh": (250, 248, 238),
        "Milk": (232, 236, 230),
        "Fur": (150, 100, 62),
        "FurLight": (206, 168, 124),
        "FurDark": (110, 72, 44),
        "Nose": (40, 30, 26),
        "Tooth": (250, 246, 230),
        "Eye": (24, 20, 20),
        "Glint": (250, 250, 250),
        "Whisker": (236, 230, 220),
        "Feet": (60, 46, 40),
        "Tail": (130, 86, 56),
        "TailDark": (96, 62, 40),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
