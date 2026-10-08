# Bobrelli Bananelli (art v2, blocks): a banana beaver, after the original meme image (by
# @alexey_pigeon, 2025-03-15): a fluffy brown beaver (round ears, a dark nose, buck teeth,
# whiskers) standing up in a peeled banana: the banana rises behind its back (a brown stem
# on top) and its peel's flaps hang round its chest like a big collar; small paws, short
# legs, and a flat criss-crossed tail on the ground behind.
import math

from voxel_art import block, both, plate, rod, solid, turned

BY = 9.6  # the torso's middle
body = [
    block(0, BY, 0.6, 7.0, 8.0, 6.0, "Fur"),  # a fluffy brown torso...
    block(0, BY - 0.4, -2.55, 4.6, 6.0, 0.3, "FurLight"),
]
B = [(0, BY - 3.0, 3.4), (0, BY + 2.0, 4.4), (0, BY + 7.6, 3.6), (0, BY + 11.2, 1.6)]
for k in range(3):  # ...a banana rising behind its back...
    d = 5.0 - k * 1.0
    body.append(rod(B[k], B[k + 1], d, "Banana"))
    body.append(solid("Ball", *B[k + 1], d - 0.2, d - 0.2, d - 0.2, "Banana"))
body += [rod(B[3], (0, BY + 12.8, 0.6), 1.2, "Stem"), block(0, BY + 13.2, 0.4, 1.4, 1.0, 1.4, "Stem")]  # ...a brown stem on top
for k in range(4):  # ...its peel's flaps hanging round its chest like a collar
    a = math.radians(-60 + k * 40)
    out = (math.sin(a), 0.0, -math.cos(a))
    t = (math.cos(a), 0.0, math.sin(a))
    d = (out[0] * 0.5, -0.87, out[2] * 0.5)
    rim = (out[0] * 3.2, BY + 3.8, 0.6 + out[2] * 3.2)
    c = [rim[i] + d[i] * 2.6 for i in range(3)]
    body += [
        turned(*c, 3.0, 5.4, 0.8, "Banana", t, d),
        turned(*[c[i] - out[i] * 0.5 for i in range(3)], 2.4, 4.8, 0.4, "Peel", t, d),
    ]

HY = BY + 7.6  # the head
head = [
    block(0, HY, 0.4, 6.6, 6.0, 6.0, "Fur"),  # a round furry head...
    block(0, HY - 1.4, -2.9, 3.6, 2.6, 1.6, "FurLight"),  # ...a pale muzzle...
    block(0, HY - 0.5, -3.85, 1.6, 1.0, 0.5, "Nose"),  # ...a dark nose...
    block(0, HY - 2.95, -3.4, 1.4, 1.2, 0.4, "Tooth"),  # ...buck teeth
    plate(0, HY - 2.95, -3.65, 0.15, 1.0, "Nose", depth=0.1),
]
head += both(
    plate(1.6, HY + 0.9, -2.75, 0.9, 0.9, "Eye", depth=0.2),  # eyes
    plate(1.45, HY + 1.1, -2.9, 0.3, 0.3, "Glint", depth=0.1),
    solid("Cylinder", 2.8, HY + 2.8, 0.4, 0.8, 2.0, 2.0, "FurDark", rot=(0, 70, 0)),  # round ears
    rod((1.6, HY - 1.2, -3.7), (4.0, HY - 0.8, -3.4), 0.2, "Whisker"),  # whiskers
    rod((1.6, HY - 1.6, -3.7), (4.0, HY - 2.0, -3.3), 0.2, "Whisker"),
)

arms = []
for s in (-1, 1):  # small paws
    arms += [
        rod((s * 3.6, BY + 2.0, 0.0), (s * 3.4, BY - 1.6, -2.6), 1.8, "Fur"),
        block(s * 3.2, BY - 2.0, -3.2, 1.6, 1.2, 1.4, "FurDark"),
    ]

legs = []
for s in (-1, 1):  # short legs
    legs += [
        block(s * 2.2, 3.4, 0.6, 2.6, 3.6, 3.0, "Fur"),
        block(s * 2.2, 0.7, -0.6, 2.8, 1.4, 4.2, "FurDark"),
    ]
legs += [  # a flat criss-crossed tail on the ground behind
    rod((0, 2.2, 3.0), (0, 0.8, 5.4), 2.0, "Fur"),
    turned(0, 0.5, 9.0, 5.4, 7.2, 0.8, "Tail", (1, 0, 0), (0, 0, 1)),
]
for k in range(4):
    legs.append(turned(-1.8 + k * 1.2, 0.95, 9.0, 0.2, 6.6, 0.2, "TailDark", (1, 0, 0), (0, 0, 1)))
    legs.append(turned(0, 0.95, 6.6 + k * 1.6, 4.8, 0.2, 0.2, "TailDark", (1, 0, 0), (0, 0, 1)))

ART = {
    "Comment": "Bobrelli Bananelli: a fluffy brown beaver with buck teeth standing in a peeled banana that rises behind its back, the peel's flaps round its chest like a collar, small paws, short legs, a flat criss-crossed tail.",
    "VoxelSize": 0.2,
    "Palette": {
        "Fur": (170, 118, 70),
        "FurLight": (214, 176, 130),
        "FurDark": (120, 80, 50),
        "Nose": (40, 30, 28),
        "Tooth": (250, 246, 230),
        "Eye": (24, 20, 20),
        "Glint": (250, 250, 250),
        "Whisker": (240, 236, 226),
        "Banana": (250, 214, 60),
        "Peel": (250, 240, 196),
        "Stem": (110, 76, 40),
        "Tail": (150, 100, 70),
        "TailDark": (110, 70, 48),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
