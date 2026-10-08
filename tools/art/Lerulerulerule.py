# Lerulerulerule (art v2, blocks): a cowboy cactus penguin, after the original meme image (by
# @alexey_pigeon): a huge muscly green cactus body (pale ridges, little spines, bulging pecs
# and abs) with a penguin's head (dark blue, a white face, an orange beak, a frown) under a
# brown cowboy hat; a brown belt with a gold buckle, blue jeans and brown cowboy boots.
import math

from voxel_art import block, both, plate, rod, solid

SY = 16.0  # the chest's middle


def spines(c, size, n, seed):
    out = []
    for k in range(n):
        a = math.radians((k * 137.5 + seed) % 360)
        y = c[1] - size[1] / 2 + 0.6 + ((k * 0.618 + seed * 0.1) % 1.0) * (size[1] - 1.2)
        x, z = math.sin(a) * size[0] / 2, -math.cos(a) * size[2] / 2
        out.append(rod((c[0] + x, y, c[2] + z), (c[0] + x * 1.22, y + 0.3, c[2] + z * 1.22), 0.25, "Spine"))
    return out


body = [
    block(0, SY, 0.4, 10.4, 8.6, 6.4, "Cactus"),  # a huge muscly cactus chest...
    block(0, SY - 5.2, 0.4, 7.6, 3.4, 5.4, "Cactus"),  # ...a narrower waist
    block(0, SY - 7.3, 0.4, 7.8, 1.2, 5.6, "Belt"),  # a brown belt...
    block(0, SY - 7.3, -2.45, 2.0, 1.4, 0.4, "Gold"),  # ...a gold buckle
]
body += both(
    block(2.5, SY + 1.4, -3.0, 4.6, 3.8, 0.8, "Cactus"),  # bulging pecs
    plate(2.5, SY - 0.6, -3.45, 4.0, 0.3, "Ridge", depth=0.15),
)
for y in (SY - 2.6, SY - 4.4):  # abs
    body += both(block(1.1, y, -2.75, 1.8, 1.4, 0.8, "Cactus"))
for x in (-3.6, 3.6):  # pale ridges down its sides
    body.append(block(x, SY - 0.4, 3.65, 0.6, 7.6, 0.3, "Ridge"))
body += spines((0, SY, 0.4), (10.4, 8.6, 6.4), 18, 5)

HY = SY + 7.4  # the head
head = [
    block(0, HY, 0.4, 6.4, 6.0, 6.0, "Navy"),  # a dark blue penguin head...
    block(0, HY - 0.4, -2.45, 4.6, 4.0, 0.3, "Face"),  # ...a white face...
    block(0, HY - 1.2, -3.6, 2.0, 1.2, 2.4, "Beak"),  # ...an orange beak...
    block(0, HY - 2.0, -3.4, 1.6, 0.6, 1.8, "BeakDark"),
    block(0, HY - 3.6, 0.4, 4.6, 1.4, 4.4, "Navy"),  # (its neck)
]
head += both(
    plate(1.2, HY + 0.4, -2.75, 1.0, 1.0, "Eye", depth=0.2),  # small fierce eyes...
    block(1.3, HY + 1.2, -2.75, 1.8, 0.5, 0.5, "Navy", rot=(0, 0, -20)),  # ...under a frown
)
HAT = HY + 3.2
head += [
    solid("Cylinder", 0, HAT, 0.4, 0.6, 11.0, 11.0, "Hat", rot=(0, 0, 90)),  # a brown cowboy hat: the brim...
    block(0, HAT + 0.6, 0.4, 10.2, 0.6, 3.0, "Hat"),  # (curled up at the sides)
    block(0, HAT + 2.0, 0.4, 5.6, 3.2, 5.6, "Hat"),  # ...the crown...
    block(0, HAT + 3.5, 0.4, 1.4, 0.4, 4.0, "HatDark"),  # ...pinched...
    block(0, HAT + 0.75, 0.4, 5.8, 0.6, 5.8, "HatDark"),  # ...a dark band
]
head += both(block(4.8, HAT + 1.0, 0.4, 1.4, 0.6, 7.6, "Hat", rot=(0, 0, 25)))

arms = []
for s in (-1, 1):  # huge muscly cactus arms
    arms += [
        solid("Ball", s * 6.4, SY + 3.0, 0.4, 5.2, 5.2, 5.2, "Cactus"),  # a shoulder...
        block(s * 7.4, SY - 1.0, 0.0, 3.6, 5.6, 3.6, "Cactus", rot=(0, 0, s * 8)),  # ...a big arm...
        block(s * 7.9, SY - 5.8, -0.4, 3.0, 4.6, 3.0, "Cactus", rot=(0, 0, s * 4)),
        block(s * 8.0, SY - 8.8, -0.6, 3.2, 2.4, 3.2, "Cactus"),  # ...a fist
        block(s * 7.4, SY - 1.0, 1.85, 0.5, 4.6, 0.3, "Ridge", rot=(0, 0, s * 8)),
    ]
    arms += spines((s * 7.6, SY - 2.6, 0.0), (3.6, 9.0, 3.6), 7, 11 + s)

legs = []
for s in (-1, 1):
    x = s * 2.2
    legs += [
        block(x, 7.8, 0.4, 3.6, 4.4, 4.6, "Jeans"),  # blue jeans...
        block(x, 7.8, -1.95, 2.6, 0.3, 0.2, "JeansDark"),
        block(x, 3.6, 0.4, 3.0, 4.6, 3.4, "Boot"),  # ...brown cowboy boots
        block(x, 0.7, -0.5, 3.2, 1.4, 5.4, "Boot"),
        block(x, 0.3, 1.7, 3.4, 0.6, 1.2, "HatDark"),
        block(x, 5.8, 0.4, 3.4, 0.6, 3.8, "HatDark"),
    ]

ART = {
    "Comment": "Lerulerulerule: a huge muscly green cactus body with spines and a dark blue penguin head with a white face and an orange beak under a brown cowboy hat, a belt with a gold buckle, blue jeans, brown cowboy boots.",
    "VoxelSize": 0.2,
    "Palette": {
        "Cactus": (86, 160, 70),
        "Ridge": (150, 206, 120),
        "Spine": (236, 226, 190),
        "Belt": (110, 66, 36),
        "Gold": (230, 186, 60),
        "Navy": (32, 40, 70),
        "Face": (236, 238, 240),
        "Beak": (246, 150, 40),
        "BeakDark": (210, 110, 30),
        "Eye": (24, 22, 26),
        "Hat": (150, 92, 50),
        "HatDark": (96, 56, 30),
        "Jeans": (64, 98, 160),
        "JeansDark": (44, 70, 120),
        "Boot": (130, 78, 42),
    },
    "Materials": {"Gold": "Metal"},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
