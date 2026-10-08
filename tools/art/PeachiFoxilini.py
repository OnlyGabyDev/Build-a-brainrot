# Peachi Foxilini (art v2, blocks): a peach fox, after the original meme image (by
# @alexey_pigeon, 2025-03-11): a little fox whose body is a big round fuzzy peach (a seam
# round it), a white fluffy ruff on its chest, a pale peach fox head with huge pointed ears
# (pink inside), big glossy dark eyes, a tiny black nose and whiskers; a huge swirling tail,
# peach at the root and white at the tip; four thin legs (the front pair are its "arms").
import math

from voxel_art import block, both, plate, rod, solid

CY, CZ = 10.5, 1.5  # the peach's middle

body = [
    solid("Ball", 0, CY, CZ, 14.0, 14.0, 14.0, "Peach"),  # a big round fuzzy peach...
    solid("Cylinder", 0, CY, CZ, 0.5, 14.4, 14.4, "Seam"),  # ...a seam round it
    block(0, CY + 1.4, -5.2, 6.0, 7.0, 3.6, "Fluff"),  # a white fluffy ruff...
    block(0, CY - 2.0, -5.4, 4.0, 3.0, 3.0, "Fluff", rot=(20, 0, 0)),  # ...hanging to a point
    block(0, CY - 3.4, -5.2, 2.0, 1.6, 2.0, "Fluff", rot=(20, 0, 0)),
]
P = [(0, CY + 1.5, CZ + 6.8), (0, CY + 4.0, CZ + 13.0), (0, CY + 15.0, CZ + 11.5), (0, CY + 16.0, CZ + 5.0)]
for k in range(15):  # a huge swirling tail of fluff, peach at the root, white at the tip
    t = k / 14
    p = [(1 - t) ** 3 * P[0][i] + 3 * (1 - t) ** 2 * t * P[1][i] + 3 * (1 - t) * t * t * P[2][i] + t ** 3 * P[3][i] for i in range(3)]
    d = 3.4 + 3.4 * math.sin(math.pi * min(1.0, t * 1.15))
    color = "Peach" if t < 0.3 else "TailPink" if t < 0.55 else "TailPale" if t < 0.78 else "Fluff"
    body.append(solid("Ball", p[0], p[1], p[2], max(d, 2.4), max(d, 2.4), max(d, 2.4), color))

HY, HZ = CY + 7.0, -6.2  # the head
head = [
    block(0, HY, HZ, 7.2, 6.0, 6.0, "Head"),  # a pale peach fox head...
    block(0, HY - 1.6, HZ - 3.6, 3.4, 2.4, 2.6, "Head"),  # ...a short muzzle...
    block(0, HY - 2.4, HZ - 3.2, 3.0, 1.0, 2.6, "Fluff"),  # ...white under it
    block(0, HY - 0.9, HZ - 4.95, 1.0, 0.8, 0.4, "Nose"),  # a tiny black nose
]
head += both(
    block(3.2, HY - 1.8, HZ - 1.0, 1.6, 2.6, 3.6, "Fluff"),  # white cheek tufts
    solid("Cylinder", 1.75, HY + 0.6, HZ - 3.05, 0.4, 3.0, 3.0, "Eye", rot=(0, 90, 0)),  # big glossy eyes
    plate(1.3, HY + 1.2, HZ - 3.3, 0.6, 0.6, "Glint", depth=0.2),
    block(2.3, HY + 3.6, HZ + 0.6, 3.2, 2.6, 1.4, "Head", rot=(0, 0, -16)),  # huge pointed ears...
    block(2.8, HY + 5.6, HZ + 0.6, 2.2, 2.2, 1.4, "Head", rot=(0, 0, -16)),
    block(3.25, HY + 7.3, HZ + 0.6, 1.0, 1.8, 1.4, "Head", rot=(0, 0, -16)),
    block(2.4, HY + 4.0, HZ - 0.25, 1.8, 2.0, 0.3, "EarIn", rot=(0, 0, -16)),  # ...pink inside
    block(2.85, HY + 5.6, HZ - 0.25, 1.0, 1.8, 0.3, "EarIn", rot=(0, 0, -16)),
    rod((1.6, HY - 1.2, HZ - 4.5), (4.2, HY - 0.8, HZ - 4.4), 0.2, "Whisker"),  # whiskers
    rod((1.6, HY - 1.6, HZ - 4.5), (4.2, HY - 2.0, HZ - 4.3), 0.2, "Whisker"),
)


def leg(x, z, top):
    return [
        block(x, top / 2, z, 1.6, top, 1.6, "Peach"),  # a thin leg...
        block(x, 0.5, z - 0.5, 1.8, 1.0, 2.4, "Paw"),  # ...a small paw
    ]


arms = leg(-2.6, -3.2, 6.0) + leg(2.6, -3.2, 6.0)
legs = leg(-3.4, 5.4, 5.4) + leg(3.4, 5.4, 5.4)

ART = {
    "Comment": "Peachi Foxilini: a little fox whose body is a big round peach with a seam, a white fluffy ruff, a pale peach fox head with huge ears and big glossy eyes, a huge swirling tail peach to white, four thin legs.",
    "VoxelSize": 0.2,
    "Palette": {
        "Peach": (244, 150, 120),
        "Seam": (214, 108, 92),
        "Fluff": (250, 244, 236),
        "TailPink": (246, 176, 160),
        "TailPale": (250, 214, 204),
        "Head": (246, 186, 160),
        "Nose": (30, 22, 22),
        "Eye": (24, 20, 26),
        "Glint": (250, 250, 250),
        "EarIn": (236, 120, 130),
        "Whisker": (250, 250, 250),
        "Paw": (226, 132, 108),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
