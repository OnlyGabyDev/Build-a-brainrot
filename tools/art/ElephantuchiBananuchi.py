# Elephantuchi Bananuchi (art v2, blocks): a banana elephant, after the original meme image
# (by @alexey_pigeon, 2025-03-15): a grey elephant's head (big pink-lined ears, small eyes,
# white tusks, its trunk curled up) coming out of a tall peeled banana that stands on its
# own curved bottom (a brown tip); the peel's flaps hang open round it (yellow outside,
# cream inside) and are its "arms".
import math

from voxel_art import block, both, plate, rod, solid, turned

legs = []
P = [(0, 9.0, 0.6), (0, 6.0, 0.8), (0, 3.4, 0.2), (0, 1.6, -1.6), (0, 0.9, -4.0)]
for k in range(len(P) - 1):  # the banana's curved bottom, standing on the ground...
    d = 6.0 - k * 1.0
    legs.append(rod(P[k], P[k + 1], d, "Banana"))
    legs.append(solid("Ball", *P[k + 1], d - 0.4, d - 0.4, d - 0.4, "Banana"))
legs.append(block(0, 1.0, -5.6, 1.4, 1.4, 1.4, "Tip"))  # ...a brown tip

BY = 12.6  # the banana's middle
body = [
    solid("Cylinder", 0, BY, 0.6, 7.4, 6.4, 6.4, "Banana", rot=(0, 0, 90)),  # a tall peeled banana...
    solid("Cylinder", 0, BY + 3.4, 0.4, 1.0, 5.6, 5.6, "Flesh", rot=(0, 0, 90)),  # ...its pale flesh at the top
    solid("Cylinder", 0, BY + 4.6, 0.4, 2.0, 5.0, 5.0, "Grey", rot=(0, 0, 90)),  # (the elephant's neck)
]

HY, HZ = BY + 8.4, -0.2  # the head
head = [
    block(0, HY, HZ, 6.2, 6.0, 5.6, "Grey"),  # a grey elephant head...
    block(0, HY + 2.6, HZ + 0.4, 5.0, 1.4, 4.6, "Grey"),
    block(0, HY - 1.2, HZ - 3.0, 2.8, 2.6, 1.0, "Grey"),  # ...its trunk curled up
]
T = [(0, HY - 1.6, HZ - 3.4), (0, HY - 3.6, HZ - 5.0), (0, HY - 3.0, HZ - 7.2), (0, HY - 0.6, HZ - 8.2), (0, HY + 1.6, HZ - 7.6)]
for k in range(len(T) - 1):
    head.append(rod(T[k], T[k + 1], 2.4 - k * 0.35, "Grey" if k % 2 == 0 else "GreyDark"))
head.append(block(0, HY + 2.0, HZ - 7.5, 1.2, 0.8, 1.2, "Pink"))
head += both(
    plate(1.7, HY + 0.8, HZ - 2.95, 0.8, 0.8, "Dark", depth=0.2),  # small eyes
    plate(1.55, HY + 1.0, HZ - 3.1, 0.3, 0.3, "Glint", depth=0.1),
    rod((1.3, HY - 2.0, HZ - 2.8), (1.8, HY - 3.0, HZ - 5.4), 0.8, "Tusk"),  # white tusks
    turned(4.4, HY + 0.4, HZ + 0.8, 4.6, 6.0, 0.6, "Grey", (0.94, 0, -0.34), (0, 1, 0)),  # big ears...
    turned(4.3, HY + 0.4, HZ + 0.5, 3.6, 4.8, 0.3, "Pink", (0.94, 0, -0.34), (0, 1, 0)),  # ...pink inside
)

arms = []
for k in range(4):  # the peel's flaps hanging open round it
    a = math.radians(45 + k * 90)
    out = (math.sin(a), 0.0, -math.cos(a))
    t = (math.cos(a), 0.0, math.sin(a))
    d = (out[0] * 0.55, -0.83, out[2] * 0.55)
    rim = (out[0] * 2.9, BY + 3.4, 0.6 + out[2] * 2.9)
    c = [rim[i] + d[i] * 3.6 for i in range(3)]
    arms += [
        turned(*c, 3.6, 7.6, 0.8, "Banana", t, d),
        turned(*[c[i] - out[i] * 0.5 for i in range(3)], 3.0, 7.0, 0.4, "Peel", t, d),
        turned(*[rim[i] + d[i] * 7.4 for i in range(3)], 1.6, 0.8, 0.9, "Tip", t, d),
    ]

ART = {
    "Comment": "Elephantuchi Bananuchi: a grey elephant head with big pink-lined ears, white tusks and a curled trunk coming out of a tall peeled banana standing on its curved bottom, the peel's flaps hanging open.",
    "VoxelSize": 0.2,
    "Palette": {
        "Banana": (250, 214, 60),
        "Peel": (250, 240, 196),
        "Flesh": (250, 236, 180),
        "Tip": (110, 76, 40),
        "Grey": (150, 146, 150),
        "GreyDark": (124, 120, 126),
        "Pink": (230, 150, 160),
        "Tusk": (250, 248, 236),
        "Dark": (24, 22, 24),
        "Glint": (250, 250, 250),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
