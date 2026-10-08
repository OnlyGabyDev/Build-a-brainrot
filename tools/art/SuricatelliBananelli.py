# Suricatelli Bananelli (art v2, blocks): a banana meerkat, after the original meme image
# (by @alexey_pigeon, 2025-03-20): a slim sandy meerkat (dark eye patches, small dark ears,
# a pale belly, a little dark nose) standing tall out of a peeled banana that stands on its
# own curved bottom (a brown tip); the peel's flaps hang open round it and are its "arms".
import math

from voxel_art import block, both, plate, rod, solid, turned

legs = []
P = [(0, 8.6, 0.6), (0, 5.8, 1.0), (0, 3.6, 0.6), (0, 2.0, 2.0), (0, 1.6, 4.2)]
for k in range(len(P) - 1):  # the banana's curved bottom, standing on the ground...
    d = 5.6 - k * 0.9
    legs.append(rod(P[k], P[k + 1], d, "Banana"))
    legs.append(solid("Ball", *P[k + 1], d - 0.4, d - 0.4, d - 0.4, "Banana"))
legs.append(block(0, 1.6, 5.6, 1.2, 1.2, 1.2, "Tip"))  # ...a brown tip

BY = 11.6  # the banana's middle
body = [
    solid("Cylinder", 0, BY, 0.6, 6.0, 5.8, 5.8, "Banana", rot=(0, 0, 90)),  # a peeled banana...
    solid("Cylinder", 0, BY + 2.8, 0.4, 1.0, 5.0, 5.0, "Flesh", rot=(0, 0, 90)),  # ...pale flesh at the top
    block(0, BY + 5.4, 0.4, 3.6, 5.0, 3.2, "Sand"),  # a slim meerkat rising out of it...
    block(0, BY + 5.0, -1.25, 2.4, 4.0, 0.3, "Belly"),  # ...a pale belly
]

HY = BY + 10.0  # the head
head = [
    block(0, HY - 1.4, 0.4, 3.0, 2.6, 3.0, "Sand"),  # (its neck)
    block(0, HY, 0.2, 3.6, 3.2, 3.6, "Sand"),  # a small sandy head...
    block(0, HY - 0.6, -2.2, 2.2, 1.8, 1.4, "Sand"),  # ...a short snout...
    block(0, HY - 0.3, -2.95, 0.8, 0.6, 0.3, "Dark"),  # ...a little dark nose
    block(0, HY - 1.3, -2.4, 1.8, 0.6, 1.0, "Belly"),
]
head += both(
    plate(1.0, HY + 0.4, -1.75, 1.3, 1.2, "Patch", depth=0.3),  # dark eye patches...
    plate(1.0, HY + 0.45, -2.0, 0.6, 0.6, "Eye", depth=0.2),
    plate(0.85, HY + 0.65, -2.6, 0.2, 0.2, "Glint", depth=0.1),
    block(1.9, HY + 0.8, 0.6, 0.6, 1.0, 1.0, "Patch"),  # ...small dark ears
)

arms = []
for k in range(4):  # the peel's flaps hanging open round it
    a = math.radians(45 + k * 90)
    out = (math.sin(a), 0.0, -math.cos(a))
    t = (math.cos(a), 0.0, math.sin(a))
    d = (out[0] * 0.55, -0.83, out[2] * 0.55)
    rim = (out[0] * 2.6, BY + 2.8, 0.6 + out[2] * 2.6)
    c = [rim[i] + d[i] * 3.2 for i in range(3)]
    arms += [
        turned(*c, 3.2, 6.8, 0.8, "Banana", t, d),
        turned(*[c[i] - out[i] * 0.5 for i in range(3)], 2.6, 6.2, 0.4, "Peel", t, d),
        turned(*[rim[i] + d[i] * 6.6 for i in range(3)], 1.4, 0.8, 0.9, "Tip", t, d),
    ]

ART = {
    "Comment": "Suricatelli Bananelli: a slim sandy meerkat with dark eye patches standing tall out of a peeled banana standing on its curved bottom, the peel's flaps hanging open.",
    "VoxelSize": 0.2,
    "Palette": {
        "Banana": (250, 214, 60),
        "Peel": (250, 240, 196),
        "Flesh": (250, 236, 180),
        "Tip": (110, 76, 40),
        "Sand": (206, 170, 120),
        "Belly": (236, 214, 176),
        "Patch": (70, 50, 36),
        "Eye": (20, 16, 14),
        "Glint": (250, 250, 250),
        "Dark": (36, 26, 22),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
