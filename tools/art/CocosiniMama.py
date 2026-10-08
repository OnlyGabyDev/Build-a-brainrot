# Cocosini Mama (art v2, blocks): a coconut kangaroo, after the original meme image (by
# @alexey_pigeon): a kangaroo whose body is a big hairy brown coconut with a round pouch
# cut into its front (a brown shell rim, white coconut flesh, a baby kangaroo peeking out of
# the dark inside), a tan kangaroo head with tall ears (pink inside) and big glossy eyes;
# short arms resting on the pouch; big hind legs with long feet; a long thick tail.
import math

from voxel_art import block, both, plate, rod, solid

CY = 12.0  # the coconut's middle
CZ = 0.8
R = 6.0  # the coconut's radius

body = [solid("Ball", 0, CY, CZ, 2 * R, 2 * R, 2 * R, "Coco")]  # the coconut...
for k in range(18):  # ...hairy fibres on it
    a = math.radians(k * 137.5)
    y = 0.85 - 1.6 * (k + 0.5) / 18
    r = math.sqrt(max(0.0, 1 - y * y))
    d = (math.cos(a) * r, y, math.sin(a) * r)
    if d[2] < -0.55 and d[1] < 0.35:  # (not over the pouch)
        continue
    p = (d[0] * R, CY + d[1] * R, CZ + d[2] * R)
    t = (-d[2], 0.3, d[0])  # along the surface
    body.append(rod((p[0] - t[0] * 0.9, p[1] - t[1] * 0.9, p[2] - t[2] * 0.9), (p[0] + t[0] * 0.9, p[1] + t[1] * 0.9, p[2] + t[2] * 0.9), 0.35, "Fibre"))
PY, PZ = CY - 1.2, CZ - 5.2  # the pouch
body += [
    solid("Cylinder", 0, PY, PZ, 1.6, 7.0, 7.0, "Shell", rot=(0, 90, 0)),  # a brown shell rim...
    solid("Cylinder", 0, PY, PZ - 0.4, 1.6, 6.0, 6.0, "Flesh", rot=(0, 90, 0)),  # ...white coconut flesh...
    solid("Cylinder", 0, PY, PZ - 0.6, 1.6, 4.4, 4.4, "Inside", rot=(0, 90, 0)),  # ...a dark inside...
    block(0, PY - 0.4, PZ - 1.5, 2.0, 2.0, 1.2, "Roo"),  # ...and a baby kangaroo peeking out
    block(0, PY - 0.9, PZ - 2.2, 1.2, 0.9, 0.6, "Roo"),
    plate(0, PY - 0.75, PZ - 2.55, 0.4, 0.3, "Dark", depth=0.1),
]
body += both(
    plate(0.5, PY - 0.1, PZ - 2.15, 0.4, 0.5, "Dark", depth=0.1),
    block(0.6, PY + 1.1, PZ - 1.4, 0.5, 1.2, 0.3, "Roo"),
)
body += [  # a long thick tail
    rod((0, CY - 3.6, CZ + 4.6), (0, 3.0, CZ + 10.4), 2.6, "Roo"),
    rod((0, 3.0, CZ + 10.4), (0, 0.8, CZ + 13.4), 1.8, "Roo"),
]

HY, HZ = CY + 9.6, -3.8  # the head
head = [
    rod((0, CY + 3.8, -1.8), (0, HY - 1.2, HZ + 0.2), 3.0, "Roo"),  # the neck
    block(0, HY, HZ, 4.0, 3.8, 4.2, "Roo"),  # the head...
    block(0, HY - 1.0, HZ - 2.8, 2.6, 2.0, 2.6, "Roo"),  # ...a snout...
    block(0, HY - 1.6, HZ - 2.6, 2.2, 1.0, 2.6, "Muzzle"),  # ...pale under it
    block(0, HY - 0.3, HZ - 4.15, 1.2, 0.7, 0.3, "Dark"),  # a nose
]
head += both(
    plate(1.3, HY + 0.6, HZ - 2.15, 1.2, 1.6, "Eye", depth=0.3),  # big glossy eyes
    plate(1.1, HY + 1.0, HZ - 2.35, 0.45, 0.45, "Glint", depth=0.1),
    block(1.5, HY + 3.6, HZ + 0.4, 1.4, 4.4, 0.8, "Roo", rot=(0, 0, -12)),  # tall ears...
    block(1.5, HY + 3.6, HZ - 0.05, 0.9, 3.4, 0.2, "EarIn", rot=(0, 0, -12)),  # ...pink inside
)

arms = []
for s in (-1, 1):  # short arms resting on the pouch
    arms += [
        rod((s * 3.2, CY + 3.4, -2.8), (s * 2.6, PY + 3.6, PZ - 1.0), 1.4, "Roo"),
        block(s * 2.3, PY + 3.4, PZ - 1.3, 1.4, 1.0, 1.6, "Roo"),
        block(s * 2.3, PY + 3.0, PZ - 1.9, 1.2, 0.6, 0.6, "Dark"),
    ]

legs = []
for s in (-1, 1):  # big hind legs with long feet
    legs += [
        block(s * 4.8, 7.4, 2.0, 2.6, 5.0, 5.4, "Roo", rot=(-20, 0, 0)),
        rod((s * 4.8, 5.4, 3.8), (s * 4.6, 1.4, 2.4), 1.8, "Roo"),
        block(s * 4.5, 0.7, -1.2, 2.2, 1.4, 8.0, "Roo"),
        block(s * 4.5, 0.7, -5.3, 1.6, 0.8, 0.6, "Dark"),  # claws
    ]

ART = {
    "Comment": "Cocosini Mama: a kangaroo whose body is a big hairy coconut with a round pouch cut into it and a baby kangaroo peeking out, a tan head with tall ears and big glossy eyes, short arms on the pouch, big hind legs, a long tail.",
    "VoxelSize": 0.2,
    "Palette": {
        "Coco": (132, 86, 50),
        "Fibre": (96, 60, 34),
        "Shell": (90, 56, 32),
        "Flesh": (250, 248, 240),
        "Inside": (60, 40, 26),
        "Roo": (204, 150, 96),
        "Muzzle": (236, 210, 172),
        "EarIn": (234, 150, 150),
        "Eye": (20, 18, 22),
        "Glint": (250, 250, 250),
        "Dark": (40, 30, 28),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
