# Alessio (art v2, blocks): a soccer ball with a face, after the original meme image (by
# @pollonavale, 2025-04-08): a white soccer ball with black patches, a smug face (squinting
# eyes under heavy lids, a big round red nose, a smirk) and a red baseball cap, walking on
# thin legs in brown cowboy boots. The meme shows no arms: ours are thin legs-like arms with
# white gloves. The ball is its head; its body is the ball's dark underside.
import math

from voxel_art import block, both, plate, rod, solid, turned

BY, BZ = 14.0, 0.4  # the ball's middle
R = 6.2
PHI = (1 + 5 ** 0.5) / 2

body = [
    block(0, 7.6, BZ, 5.4, 1.6, 4.2, "Patch"),  # the ball's dark underside...
    block(0, 6.6, BZ, 4.0, 1.0, 3.2, "Trousers"),  # ...hips
]

head = [solid("Ball", 0, BY, BZ, 2 * R, 2 * R, 2 * R, "Ball")]  # a white soccer ball...
for v in [(0, a, b * PHI) for a in (-1, 1) for b in (-1, 1)] + [(a, b * PHI, 0) for a in (-1, 1) for b in (-1, 1)] + [(b * PHI, 0, a) for a in (-1, 1) for b in (-1, 1)]:
    n = math.sqrt(sum(c * c for c in v))
    v = tuple(c / n for c in v)
    if v[2] < -0.45 or v[1] > 0.7:  # (not under the face or the cap)
        continue
    up = (0.0, 1.0, 0.0) if abs(v[1]) < 0.9 else (1.0, 0.0, 0.0)
    dot = sum(up[i] * v[i] for i in range(3))
    y_axis = tuple(up[i] - dot * v[i] for i in range(3))
    m = math.sqrt(sum(c * c for c in y_axis))
    y_axis = tuple(c / m for c in y_axis)
    head.append(turned(v[0] * (R - 0.25), BY + v[1] * (R - 0.25), BZ + v[2] * (R - 0.25), 0.6, 3.2, 3.2, "Patch", v, y_axis, shape="Cylinder"))  # ...black patches



def surf(x, y):  # (the ball's front at x, y)
    return BZ - math.sqrt(R * R - x * x - (y - BY) ** 2)


head += [
    solid("Ball", 0, BY - 0.6, surf(0, BY - 0.6) + 0.2, 2.8, 2.8, 2.8, "Nose"),  # a big round red nose
    block(0.3, BY - 3.0, surf(0.3, BY - 3.0) - 0.1, 2.6, 0.45, 0.8, "Dark", rot=(0, 0, -10)),  # a smirk
    block(1.7, BY - 2.7, surf(1.7, BY - 2.7) - 0.1, 0.8, 0.45, 0.8, "Dark", rot=(0, 0, 30)),
]
head += both(
    block(1.9, BY + 1.5, surf(1.9, BY + 1.5) - 0.15, 1.8, 1.0, 0.8, "White"),  # squinting eyes...
    block(1.9, BY + 1.45, surf(1.9, BY + 1.45) - 0.35, 0.8, 0.8, 0.8, "Dark"),
    block(1.9, BY + 2.1, surf(1.9, BY + 2.1) - 0.2, 2.2, 0.7, 1.0, "Lid", rot=(0, 0, -10)),  # ...under heavy lids
    block(2.0, BY + 2.9, surf(2.0, BY + 2.9) - 0.1, 2.0, 0.4, 0.8, "Brow", rot=(0, 0, 12)),
)
head += [
    solid("Ball", 0, BY + 2.6, BZ + 0.4, 10.6, 10.6, 10.6, "Cap"),  # a red baseball cap...
    turned(0, BY + 4.6, BZ - 5.0, 7.6, 0.5, 4.6, "CapDark", (1, 0, 0), (0, 0.98, -0.2)),  # ...its brim...
    solid("Ball", 0, BY + 7.9, BZ + 0.4, 1.2, 1.2, 1.2, "CapDark"),  # ...a button
]

arms = []
for s in (-1, 1):  # (ours) thin arms with white gloves
    arms += [
        rod((s * 5.2, BY - 2.4, BZ), (s * 7.2, BY - 6.4, BZ - 1.0), 0.9, "Trousers"),
        solid("Ball", s * 7.3, BY - 6.9, BZ - 1.1, 1.8, 1.8, 1.8, "White"),
    ]

legs = []
for s in (-1, 1):  # thin legs in brown cowboy boots
    x = s * 1.6
    legs += [
        block(x, 5.2, BZ, 1.2, 4.4, 1.2, "Trousers"),
        block(x, 2.0, BZ, 2.0, 3.0, 2.2, "Boot"),  # a boot...
        block(x, 0.6, BZ - 0.9, 2.2, 1.2, 4.2, "Boot"),
        block(x, 0.2, BZ + 0.6, 2.4, 0.4, 1.0, "Heel"),  # ...its heel
        block(x, 3.4, BZ, 2.4, 0.4, 2.6, "Heel"),
    ]

ART = {
    "Comment": "Alessio: a white soccer ball with black patches, a smug squinting face with a big red nose and a red baseball cap, on thin legs in brown cowboy boots.",
    "VoxelSize": 0.2,
    "Palette": {
        "Ball": (246, 244, 238),
        "Patch": (34, 34, 38),
        "Nose": (226, 110, 104),
        "Dark": (40, 28, 26),
        "White": (250, 250, 250),
        "Lid": (226, 214, 196),
        "Brow": (90, 70, 50),
        "Cap": (204, 60, 52),
        "CapDark": (170, 44, 40),
        "Trousers": (70, 74, 60),
        "Boot": (134, 84, 48),
        "Heel": (90, 56, 32),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
