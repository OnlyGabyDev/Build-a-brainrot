# Armodillo Cocodillo (art v2, blocks): a coconut armadillo, after the original meme image
# (by @alexey_pigeon): an armadillo curled up inside a big hairy brown coconut, peeking out
# of a round hole in its front (a white flesh rim round the hole); its banded grey-brown
# shell shows inside, its long-eared head and little clawed hands rest on the rim, its
# banded tail sticks out of the back; little feet under it.
import math

from voxel_art import block, both, plate, rod, solid

C = (0.0, 8.0, 1.0)  # the coconut's middle
R = 7.0
N = (0.0, 0.26, -0.966)  # the hole faces forward, a little up

body = [solid("Ball", *C, 2 * R, 2 * R, 2 * R, "Coco")]  # a big hairy coconut...
for k in range(26):  # ...fibres
    a = math.radians(k * 137.5)
    y = 0.9 - 1.7 * (k + 0.5) / 26
    r = math.sqrt(max(0.0, 1 - y * y))
    d = (math.cos(a) * r, y, math.sin(a) * r)
    if d[0] * N[0] + d[1] * N[1] + d[2] * N[2] > 0.55:  # (not over the hole)
        continue
    p = (C[0] + d[0] * R, C[1] + d[1] * R, C[2] + d[2] * R)
    t = (-d[2], 0.3, d[0])
    body.append(rod(tuple(p[i] - t[i] * 0.9 for i in range(3)), tuple(p[i] + t[i] * 0.9 for i in range(3)), 0.35, "Fibre"))


def hole(n, length, d, color):
    return solid("Cylinder", C[0] + N[0] * n, C[1] + N[1] * n, C[2] + N[2] * n, length, d, d, color, rot=(15, 90, 0))


body += [
    hole(5.6, 3.0, 9.0, "Coco"),  # ...a round hole in its front: a white flesh rim...
    hole(7.2, 0.4, 8.4, "Flesh"),
    hole(7.45, 0.4, 6.6, "Shell"),  # ...the armadillo's banded shell inside
]
for k in range(3):
    body.append(hole(7.7, 0.3, 6.0 - k * 1.8, "ShellDark" if k % 2 == 0 else "Shell"))
tail = [(0, 4.2, C[2] + 6.4), (0, 2.2, C[2] + 9.0), (0, 1.4, C[2] + 11.6)]  # a banded tail out the back
for k in range(2):
    body.append(rod(tail[k], tail[k + 1], 1.6 - k * 0.4, "Shell"))
    body.append(solid("Ball", *tail[k + 1], 1.7 - k * 0.4, 1.7 - k * 0.4, 1.7 - k * 0.4, "ShellDark"))

HP = (0.0, C[1] + 2.4, C[2] - R - 1.6)  # the head, peeking out
head = [
    block(HP[0], HP[1], HP[2], 3.4, 3.0, 3.6, "Skin"),  # a long head...
    block(HP[0], HP[1] - 0.5, HP[2] - 2.6, 1.8, 1.6, 2.2, "Skin"),  # ...a pointy snout...
    block(HP[0], HP[1] - 0.3, HP[2] - 3.8, 1.0, 0.8, 0.4, "Nose"),
    block(HP[0], HP[1] + 1.65, HP[2] + 0.4, 2.8, 0.4, 2.8, "ShellDark"),  # (a little head shield)
]
head += both(
    plate(1.0, HP[1] + 0.5, HP[2] - 1.85, 0.8, 0.8, "Eye", depth=0.2),  # eyes
    plate(0.85, HP[1] + 0.7, HP[2] - 2.0, 0.3, 0.3, "Glint", depth=0.1),
    block(1.4, HP[1] + 2.6, HP[2] + 0.8, 1.0, 2.6, 0.5, "Skin", rot=(0, 0, -15)),  # long ears
    block(1.4, HP[1] + 2.6, HP[2] + 0.5, 0.6, 2.0, 0.2, "EarIn", rot=(0, 0, -15)),
)

arms = []
for s in (-1, 1):  # little clawed hands on the rim
    arms += [
        block(s * 2.6, C[1] - 0.4, C[2] - R - 1.2, 1.6, 1.4, 2.4, "Skin"),
    ] + [block(s * 2.6 + dx, C[1] - 0.9, C[2] - R - 2.5, 0.35, 0.6, 0.5, "Claw") for dx in (-0.5, 0.0, 0.5)]

legs = []
for s in (-1, 1):  # little feet under it
    legs += [
        block(s * 3.0, 1.0, -2.4, 2.2, 2.0, 2.8, "Skin"),
    ] + [block(s * 3.0 + dx, 0.4, -4.0, 0.4, 0.6, 0.6, "Claw") for dx in (-0.6, 0.0, 0.6)]

ART = {
    "Comment": "Armodillo Cocodillo: an armadillo curled up inside a big hairy coconut, peeking out of a round hole in its front, its banded shell inside, long ears, little clawed hands on the rim, a banded tail out the back.",
    "VoxelSize": 0.2,
    "Palette": {
        "Coco": (132, 84, 48),
        "Fibre": (96, 60, 34),
        "Flesh": (250, 248, 238),
        "Shell": (176, 150, 130),
        "ShellDark": (140, 116, 98),
        "Skin": (206, 170, 150),
        "Nose": (90, 60, 56),
        "Eye": (24, 20, 20),
        "Glint": (250, 250, 250),
        "EarIn": (230, 160, 160),
        "Claw": (70, 56, 46),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
