# Salamino Penguino (art v2, blocks): a salami penguin, after the original meme image (by
# @italianbrainrotanimals01, 2025-04-27): a penguin whose head and chest are one big red
# salami (white fat spots, a flat cut top), small grumpy eyes and a black beak on the
# salami; a black back and a white belly under it; black flippers; dark webbed feet.
import math

from voxel_art import block, both, plate, solid, wedge

R = 5.2  # the salami's radius
SZ = -0.6  # its middle
NECK = 19.0  # where the head (the salami's top) meets the chest
TOP = 27.6


def upright(x, y, z, height, d, color):
    return solid("Cylinder", x, y, z, height, d, d, color, rot=(0, 0, 90))


def spots(y0, y1, seed):
    out = []
    for k in range(int((y1 - y0) * 1.6)):
        a = math.radians(((k * 137.5 + seed) % 220) - 110)  # (round its front and sides)
        y = y0 + 0.8 + ((k * 0.618 + seed * 0.1) % 1.0) * (y1 - y0 - 1.6)
        if abs(a) < 0.7 and NECK + 1.4 < y < NECK + 6.6:  # (not over the face)
            continue
        out.append(block(math.sin(a) * (R + 0.05), y, SZ - math.cos(a) * (R + 0.05), 0.9, 0.9, 0.3, "Fat", rot=(0, -math.degrees(a), 0)))
    return out


body = [
    solid("Ball", 0, 8.0, 0.6, 12.0, 12.0, 12.0, "Black"),  # a round black penguin body...
    upright(0, 12.0, 0.8, 8.0, 10.6, "Black"),  # ...with a black back
    solid("Ball", 0, 7.4, -0.8, 10.6, 10.6, 10.6, "White"),  # ...a white belly
    upright(0, (10.0 + NECK) / 2, SZ, NECK - 10.0, 2 * R, "Salami"),  # the salami's lower half
]
body += spots(10.0, NECK, 11)

head = [
    upright(0, (NECK + TOP) / 2, SZ, TOP - NECK, 2 * R, "Salami"),  # the salami's top...
    upright(0, TOP + 0.2, SZ, 0.4, 2 * R - 0.8, "Cut"),  # ...cut flat
    block(0, NECK + 3.6, SZ - R - 1.2, 1.8, 1.4, 2.6, "Beak"),  # a black beak...
    wedge(0, NECK + 2.5, SZ - R - 1.4, 1.4, 0.9, 2.2, "Beak", rot=(180, 0, 0)),  # ...hooked down
]
head += spots(NECK, TOP, 3)
head += both(
    block(1.6, NECK + 5.0, SZ - R + 0.05, 1.4, 0.9, 0.4, "Eye"),  # small grumpy eyes...
    block(1.7, NECK + 5.65, SZ - R - 0.05, 2.0, 0.5, 0.5, "Lid", rot=(0, 0, -12)),  # ...heavy lids
)
for x, z in ((-1.8, -1.6), (2.0, 0.8), (-0.4, 2.2), (1.2, -2.8)):  # fat spots on the cut
    head.append(block(x, TOP + 0.5, SZ + z, 1.0, 0.3, 1.0, "Fat"))

arms = []
for s in (-1, 1):  # black flippers
    arms += [
        block(s * 5.8, 13.6, 0.6, 1.6, 9.4, 3.6, "Black", rot=(0, 0, s * 14)),
        block(s * 6.8, 9.0, 0.6, 1.2, 3.6, 2.6, "Black", rot=(0, 0, s * 20)),
    ]

legs = []
for s in (-1, 1):  # dark webbed feet
    legs += [
        block(s * 2.4, 2.0, 0.0, 2.0, 2.6, 2.0, "Black"),
        block(s * 2.6, 0.5, -1.4, 2.8, 1.0, 4.4, "Feet"),
        block(s * 2.6, 0.5, -3.7, 0.6, 0.8, 0.6, "Black"),
    ]

ART = {
    "Comment": "Salamino Penguino: a penguin whose head and chest are one big red salami with white fat spots and a flat cut top, grumpy eyes and a black beak, a black back, a white belly, black flippers, dark feet.",
    "VoxelSize": 0.2,
    "Palette": {
        "Black": (30, 32, 38),
        "White": (244, 244, 240),
        "Salami": (186, 44, 48),
        "Fat": (250, 226, 222),
        "Cut": (214, 76, 80),
        "Beak": (24, 24, 26),
        "Eye": (20, 16, 16),
        "Lid": (140, 30, 34),
        "Feet": (60, 60, 66),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
