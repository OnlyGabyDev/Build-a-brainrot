# Gorillini Bananini (art v2, blocks): a banana gorilla, after the original meme image (by
# @alexey_pigeon, 2025-03-18): a big silverback gorilla (silver-grey fur, a dark leathery
# face with a heavy brow) wrapped in a giant peeled banana: the banana rises behind its
# head like a hood and its peel's flaps hang round its chest; long strong arms down to its
# knuckles, short legs.
import math

from voxel_art import block, both, plate, rod, solid, turned

BY = 11.6  # the chest's middle
body = [
    block(0, BY, 0.8, 10.0, 8.4, 7.0, "Fur"),  # a big silverback...
    block(0, BY + 4.4, 0.8, 8.0, 1.6, 6.0, "Fur"),
    block(0, BY - 0.4, -2.75, 6.4, 6.4, 0.4, "Chest"),  # ...a dark chest
]
B = [(0, BY - 2.0, 4.6), (0, BY + 4.0, 5.4), (0, BY + 10.0, 4.6), (0, BY + 14.6, 2.6)]
for k in range(3):  # a giant banana rising behind it like a hood...
    d = 7.0 - k * 1.4
    body.append(rod(B[k], B[k + 1], d, "Banana"))
    body.append(solid("Ball", *B[k + 1], d - 0.2, d - 0.2, d - 0.2, "Banana"))
body += [rod(B[3], (0, BY + 16.0, 1.2), 1.4, "Stem"), block(0, BY + 16.4, 0.8, 1.6, 1.0, 1.6, "Stem")]
for k in range(5):  # ...its peel's flaps hanging round its chest
    a = math.radians(-80 + k * 40)
    out = (math.sin(a), 0.0, -math.cos(a))
    t = (math.cos(a), 0.0, math.sin(a))
    d = (out[0] * 0.45, -0.89, out[2] * 0.45)
    rim = (out[0] * 4.6, BY + 4.6, 0.8 + out[2] * 3.8)
    c = [rim[i] + d[i] * 3.0 for i in range(3)]
    body += [
        turned(*c, 3.6, 6.2, 0.8, "Banana", t, d),
        turned(*[c[i] - out[i] * 0.5 for i in range(3)], 3.0, 5.6, 0.4, "Peel", t, d),
    ]

HY, HZ = BY + 8.4, -0.4  # the head
head = [
    block(0, HY, HZ, 7.0, 6.6, 6.4, "Fur"),  # a silver-grey head...
    block(0, HY + 3.4, HZ + 0.6, 5.4, 1.6, 5.0, "Fur"),  # ...a crested top
    block(0, HY - 0.6, HZ - 3.25, 5.4, 5.0, 0.4, "Face"),  # ...a dark leathery face...
    block(0, HY + 1.4, HZ - 3.7, 5.8, 1.2, 1.2, "Face"),  # ...a heavy brow...
    block(0, HY - 1.6, HZ - 3.9, 3.8, 2.4, 1.2, "Face"),  # ...a wide muzzle
    plate(0, HY - 2.6, HZ - 4.55, 2.4, 0.3, "Dark", depth=0.15),
]
head += both(
    plate(1.4, HY + 0.4, HZ - 3.55, 1.1, 0.8, "Eye", depth=0.2),  # deep-set eyes
    plate(1.3, HY + 0.4, HZ - 3.7, 0.5, 0.5, "Dark", depth=0.15),
    plate(0.8, HY - 1.0, HZ - 4.55, 0.7, 0.5, "Dark", depth=0.1),  # nostrils
    block(3.7, HY + 0.4, HZ + 0.4, 0.6, 1.6, 1.6, "Face"),  # ears
)

arms = []
for s in (-1, 1):  # long strong arms down to its knuckles
    arms += [
        solid("Ball", s * 6.2, BY + 3.0, 0.8, 5.0, 5.0, 5.0, "Fur"),
        block(s * 7.0, BY - 1.6, 0.6, 3.8, 7.6, 4.0, "Fur", rot=(0, 0, s * 8)),
        block(s * 7.4, BY - 7.6, 0.2, 3.6, 6.0, 3.8, "Fur", rot=(0, 0, s * 3)),
        block(s * 7.5, 1.4, -0.2, 4.0, 2.8, 4.2, "Face"),  # knuckles
    ]

legs = []
for s in (-1, 1):  # short legs
    legs += [
        block(s * 2.8, 4.4, 0.8, 3.8, 5.0, 4.0, "Fur"),
        block(s * 2.8, 0.9, -0.2, 4.2, 1.8, 5.4, "Face"),
    ]

ART = {
    "Comment": "Gorillini Bananini: a big silverback gorilla with a dark leathery face wrapped in a giant peeled banana that rises behind its head like a hood, the peel's flaps round its chest, long arms down to its knuckles.",
    "VoxelSize": 0.2,
    "Palette": {
        "Fur": (170, 170, 176),
        "Chest": (90, 88, 96),
        "Face": (70, 64, 70),
        "Dark": (20, 18, 20),
        "Eye": (140, 90, 50),
        "Banana": (250, 214, 60),
        "Peel": (250, 240, 196),
        "Stem": (110, 76, 40),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
