# Bambini Crostini (art v2, blocks): a croissant fawn, after the original meme image (by
# @top.brainrot): a fawn whose body is a big golden croissant (puffy ridges with darker
# crust on top, pale dough in the grooves, both ends curling down), the fawn's tan neck and
# head out of its front (a white muzzle and throat, a black nose, big dark eyes, tall ears
# with pale insides); four thin tan legs with black hooves (the front pair are its "arms").
import math

from voxel_art import block, both, plate, rod

CY = 14.0  # the croissant's middle (its top ridge)
R = 13.0  # the croissant bends round a circle this big, so both ends curl down

# (angle along the bend, width, height): the ridges from the middle out to each end
RIDGES = [(0, 11.0, 8.0), (13, 10.0, 7.4), (26, 8.6, 6.4), (39, 6.8, 5.2), (52, 4.8, 3.8)]

body = [block(0, CY - 1.0, 0, 6.0, 5.0, 16.0, "Dough")]  # pale dough deep in the grooves
for angle, w, h in RIDGES:
    for s in ((1,) if angle == 0 else (-1, 1)):
        a = math.radians(angle)
        y, z = CY - R * (1 - math.cos(a)), s * R * math.sin(a)
        tilt = (s * angle, 0, 0)
        up = (math.cos(a), s * math.sin(a))  # the ridge's own up, for the crust on top
        body += [
            block(0, y, z, w, h - 1.4, 3.0, "Golden", rot=tilt),  # a puffy ridge, rounded...
            block(0, y, z, w - 1.4, h, 2.8, "Golden", rot=tilt),
            block(0, y + up[0] * (h / 2 - 0.2), z + up[1] * (h / 2 - 0.2), w - 2.6, 0.8, 2.4, "Crust", rot=tilt),  # ...darker on top
        ]

HY, HZ = CY + 11.6, -11.6  # the head
head = [
    rod((0, CY + 0.4, -5.8), (0, CY + 10.0, -10.6), 3.2, "Fur"),  # the neck...
    rod((0, CY + 0.6, -6.8), (0, CY + 9.4, -11.2), 2.0, "Throat"),  # ...a pale throat
    block(0, HY, HZ, 5.0, 4.4, 5.0, "Fur"),  # the head...
    block(0, HY - 0.9, HZ - 3.3, 2.8, 2.6, 3.4, "Fur"),  # ...its snout...
    block(0, HY - 1.7, HZ - 3.2, 2.6, 1.2, 3.8, "Cream"),  # ...a white muzzle
    plate(0, HY - 0.3, HZ - 5.1, 1.4, 1.0, "Nose", depth=0.3),
    plate(0, HY - 1.95, HZ - 5.15, 1.2, 0.3, "Nose", depth=0.15),  # a little mouth
    plate(0, HY + 1.2, HZ - 2.6, 1.4, 1.6, "Spot", depth=0.2),  # a pale spot on its brow
]
head += both(
    plate(1.85, HY + 0.7, HZ - 2.6, 1.3, 1.6, "Cream", depth=0.2),  # big dark eyes...
    plate(1.85, HY + 0.7, HZ - 2.75, 1.0, 1.3, "Eye", depth=0.2),
    plate(1.65, HY + 1.05, HZ - 2.9, 0.35, 0.35, "Glint", depth=0.1),
    block(3.6, HY + 2.8, HZ + 0.8, 3.8, 1.8, 0.8, "Fur", rot=(0, 0, 35)),  # tall ears...
    block(3.6, HY + 2.8, HZ + 0.25, 3.0, 1.1, 0.3, "EarIn", rot=(0, 0, 35)),  # ...pale insides
)


def leg(x, z):
    return [
        rod((x, CY - 2.0, z), (x, 5.0, z + 0.5), 1.7, "Fur"),  # a thin leg...
        rod((x, 5.0, z + 0.5), (x, 1.2, z - 0.1), 1.2, "Fur"),
        block(x, 0.7, z - 0.2, 1.5, 1.4, 1.8, "Hoof"),  # ...a black hoof
    ]


legs = leg(-2.4, 5.6) + leg(2.4, 5.6)
arms = leg(-2.4, -5.4) + leg(2.4, -5.4)

ART = {
    "Comment": "Bambini Crostini: a fawn whose body is a big golden croissant curling down at both ends, a tan neck and head with a white muzzle, big dark eyes and tall ears, four thin legs with black hooves.",
    "VoxelSize": 0.2,
    "Palette": {
        "Golden": (230, 156, 62),
        "Crust": (190, 102, 38),
        "Dough": (246, 214, 150),
        "Fur": (196, 132, 82),
        "Cream": (246, 236, 220),
        "Throat": (236, 212, 184),
        "Spot": (226, 180, 130),
        "Nose": (30, 26, 28),
        "Eye": (34, 26, 24),
        "Glint": (250, 250, 250),
        "EarIn": (240, 200, 180),
        "Hoof": (40, 34, 34),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
