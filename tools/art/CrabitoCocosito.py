# Crabito Cocosito (art v2, blocks): a coconut crab, after the original meme image (by
# @alexey_pigeon): a red-orange crab living in a big hairy brown coconut, the coconut split
# open in front like a mouth (white flesh inside), the crab's eyes on stalks peeking out of
# the gap; two big claws with dark tips in front, four jointed legs on each side.
import math

from voxel_art import both, block, plate, rod, solid

CY, CZ = 9.0, 1.2  # the coconut's middle
R = 6.6

body = [solid("Ball", 0, CY, CZ, 2 * R, 2 * R, 2 * R, "Coco")]  # a big hairy coconut...
for k in range(22):  # ...fibres on it
    a = math.radians(k * 137.5)
    y = 0.9 - 1.5 * (k + 0.5) / 22
    r = math.sqrt(max(0.0, 1 - y * y))
    d = (math.cos(a) * r, y, math.sin(a) * r)
    if d[2] < -0.45 and abs(d[1]) < 0.45:  # (not over the gap)
        continue
    p = (d[0] * R, CY + d[1] * R, CZ + d[2] * R)
    t = (-d[2], 0.3, d[0])
    body.append(rod((p[0] - t[0] * 0.8, p[1] - t[1] * 0.8, p[2] - t[2] * 0.8), (p[0] + t[0] * 0.8, p[1] + t[1] * 0.8, p[2] + t[2] * 0.8), 0.35, "Fibre"))
GY, GZ = CY + 0.4, CZ - R + 1.4  # the gap: the coconut split open in front
body += [
    block(0, GY, GZ - 0.2, 10.0, 3.0, 2.4, "Flesh"),  # white flesh round...
    block(0, GY, GZ - 0.5, 8.6, 2.0, 2.4, "Inside"),  # ...a dark inside
    block(0, GY + 1.75, GZ - 0.9, 10.4, 0.5, 2.2, "Shell"),  # (the shell's lips)
    block(0, GY - 1.75, GZ - 0.9, 10.4, 0.5, 2.2, "Shell"),
    block(0, GY - 0.3, GZ - 1.75, 3.4, 1.0, 0.4, "Crab"),  # the crab's face inside
    plate(0, GY - 0.35, GZ - 2.0, 1.6, 0.3, "Mouth", depth=0.15),
]

head = []
for s in (-1, 1):  # eyes on stalks peeking out
    base, top = (s * 1.4, GY + 0.4, GZ - 1.6), (s * 1.9, GY + 4.4, GZ - 2.0)
    head += [
        rod(base, top, 0.8, "Crab"),
        solid("Ball", top[0], top[1] + 0.6, top[2], 2.2, 2.2, 2.2, "EyeWhite"),
        plate(top[0], top[1] + 0.6, top[2] - 1.1, 1.0, 1.1, "Pupil", depth=0.3),
        plate(top[0] - s * 0.2, top[1] + 0.9, top[2] - 1.35, 0.35, 0.35, "EyeWhite", depth=0.1),
    ]

arms = []
for s in (-1, 1):  # two big claws in front
    shoulder, elbow, claw = (s * 3.6, CY - 1.4, CZ - 3.8), (s * 5.4, CY - 2.6, CZ - 6.6), (s * 4.6, CY - 2.4, CZ - 9.4)
    arms += [
        rod(shoulder, elbow, 1.4, "Crab"),
        rod(elbow, (claw[0], claw[1], claw[2] + 1.2), 1.6, "Crab"),
        block(claw[0], claw[1], claw[2], 3.0, 2.8, 3.4, "Crab"),  # a claw...
        block(claw[0] - s * 0.6, claw[1] + 0.6, claw[2] - 2.6, 1.4, 1.2, 2.2, "Crab"),  # ...its pincers
        block(claw[0] - s * 0.6, claw[1] - 0.9, claw[2] - 2.4, 1.2, 1.0, 1.8, "Crab"),
        block(claw[0] - s * 0.6, claw[1] + 0.6, claw[2] - 3.9, 1.2, 1.0, 0.6, "Tip"),  # ...dark tips
        block(claw[0] - s * 0.6, claw[1] - 0.9, claw[2] - 3.45, 1.0, 0.8, 0.5, "Tip"),
    ]

legs = []
for s in (-1, 1):  # four jointed legs on each side
    for k, z in enumerate((-1.6, 0.8, 3.2, 5.4)):
        hip, knee, foot = (s * 5.0, CY - 3.0, CZ + z), (s * 8.4, 4.6, CZ + z + 0.4), (s * 9.6, 0.15, CZ + z + 0.8)
        legs += [
            rod(hip, knee, 1.1, "Crab"),
            rod(knee, foot, 0.9, "Crab" if k % 2 else "CrabDark"),
        ]

ART = {
    "Comment": "Crabito Cocosito: a red-orange crab living in a big hairy coconut split open in front, eyes on stalks peeking out of the gap, two big claws with dark tips, four jointed legs on each side.",
    "VoxelSize": 0.2,
    "Palette": {
        "Coco": (128, 82, 46),
        "Fibre": (92, 58, 32),
        "Shell": (86, 52, 30),
        "Flesh": (250, 248, 238),
        "Inside": (60, 40, 26),
        "Crab": (232, 96, 46),
        "CrabDark": (204, 72, 36),
        "Tip": (40, 30, 28),
        "Mouth": (110, 30, 24),
        "EyeWhite": (250, 250, 248),
        "Pupil": (20, 18, 18),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
