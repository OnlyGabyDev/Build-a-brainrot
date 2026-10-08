# Bulliccini Bananini (art v2, blocks): a banana bull, after the original meme image (by
# @alexey_pigeon, 2025-03-16): a shaggy cream bull's head (curved horns with dark tips, a
# pink nose, small red-rimmed eyes, a woolly curly top) coming out of a big peeled banana
# that stands on its own curved bottom (a brown tip); the peel's flaps hang open round it
# (yellow outside, cream inside) and are its "arms".
import math

from voxel_art import block, both, plate, rod, solid, turned

legs = []
P = [(0, 9.0, 0.6), (0, 6.0, 1.0), (0, 3.6, 0.6), (0, 2.0, 2.2), (0, 1.6, 4.6)]
for k in range(len(P) - 1):  # the banana's curved bottom, standing on the ground...
    d = 6.4 - k * 1.0
    legs.append(rod(P[k], P[k + 1], d, "Banana"))
    legs.append(solid("Ball", *P[k + 1], d - 0.4, d - 0.4, d - 0.4, "Banana"))
legs.append(block(0, 1.6, 6.2, 1.4, 1.4, 1.4, "Tip"))  # ...a brown tip

BY = 12.6  # the banana's middle
body = [
    solid("Cylinder", 0, BY, 0.6, 7.4, 6.8, 6.8, "Banana", rot=(0, 0, 90)),  # a big peeled banana...
    solid("Cylinder", 0, BY + 3.4, 0.4, 1.0, 6.0, 6.0, "Flesh", rot=(0, 0, 90)),  # ...pale flesh at the top
    solid("Cylinder", 0, BY + 4.6, 0.4, 2.0, 5.4, 5.4, "Wool", rot=(0, 0, 90)),  # (the bull's neck)
]

HY, HZ = BY + 8.2, -0.4  # the head
head = [
    block(0, HY, HZ, 6.6, 6.0, 6.0, "Wool"),  # a shaggy cream head...
    block(0, HY - 1.8, HZ - 3.2, 4.6, 3.0, 1.6, "Muzzle"),  # ...a broad pink-grey muzzle...
    block(0, HY - 1.6, HZ - 4.15, 3.6, 1.8, 0.4, "Nose"),  # ...a pink nose
]
for x, y in ((-2.0, 3.4), (0.0, 3.8), (2.0, 3.4), (-1.0, 4.4), (1.0, 4.4), (-2.8, 2.4), (2.8, 2.4)):  # a woolly curly top
    head.append(solid("Ball", x, HY + y - 0.6, HZ + 0.2, 2.6, 2.6, 2.6, "WoolLight"))
head += both(
    plate(1.2, HY - 1.5, HZ - 4.4, 0.6, 0.8, "Dark", depth=0.15),  # nostrils
    plate(2.0, HY + 0.6, HZ - 3.05, 1.2, 0.9, "RedRim", depth=0.2),  # small red-rimmed eyes
    plate(2.0, HY + 0.6, HZ - 3.25, 0.6, 0.6, "Dark", depth=0.15),
    block(3.6, HY + 0.4, HZ + 0.6, 1.6, 0.8, 2.0, "Wool", rot=(0, 0, -25)),  # ears
)
for s in (-1, 1):  # curved horns with dark tips
    pts = [(s * 3.2, HY + 2.2, HZ + 0.4), (s * 5.4, HY + 3.0, HZ + 0.4), (s * 6.6, HY + 4.8, HZ + 0.2), (s * 6.4, HY + 6.8, HZ - 0.2)]
    for k in range(3):
        head.append(rod(pts[k], pts[k + 1], 1.5 - k * 0.3, "Horn" if k < 2 else "HornTip"))

arms = []
for k in range(4):  # the peel's flaps hanging open round it
    a = math.radians(45 + k * 90)
    out = (math.sin(a), 0.0, -math.cos(a))
    t = (math.cos(a), 0.0, math.sin(a))
    d = (out[0] * 0.55, -0.83, out[2] * 0.55)
    rim = (out[0] * 3.1, BY + 3.4, 0.6 + out[2] * 3.1)
    c = [rim[i] + d[i] * 3.6 for i in range(3)]
    arms += [
        turned(*c, 3.8, 7.6, 0.8, "Banana", t, d),
        turned(*[c[i] - out[i] * 0.5 for i in range(3)], 3.2, 7.0, 0.4, "Peel", t, d),
        turned(*[rim[i] + d[i] * 7.4 for i in range(3)], 1.6, 0.8, 0.9, "Tip", t, d),
    ]

ART = {
    "Comment": "Bulliccini Bananini: a shaggy cream bull's head with curved horns and a pink nose coming out of a big peeled banana standing on its curved bottom, the peel's flaps hanging open.",
    "VoxelSize": 0.2,
    "Palette": {
        "Banana": (250, 214, 60),
        "Peel": (250, 240, 196),
        "Flesh": (250, 236, 180),
        "Tip": (110, 76, 40),
        "Wool": (226, 214, 188),
        "WoolLight": (240, 232, 212),
        "Muzzle": (206, 170, 160),
        "Nose": (226, 140, 150),
        "Dark": (40, 28, 28),
        "RedRim": (200, 70, 70),
        "Horn": (90, 74, 60),
        "HornTip": (40, 34, 30),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
