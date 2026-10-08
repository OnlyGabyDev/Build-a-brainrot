# Raccooni Watermelunni (art v2, blocks): a watermelon raccoon, after the original meme image
# (by @alexey_pigeon, 2025-03-20): a big striped watermelon with its top cut off and lifted
# (red flesh with black seeds, a white rind), and a raccoon peeking out of it (a grey head,
# a black mask, a white muzzle, round ears), its little dark paws on the rim. The meme shows
# no legs: ours are stubby dark paws under the melon. The lifted lid rides on its head.
import math

from voxel_art import block, both, plate, rod, solid

C = (0.0, 8.6, 0.8)  # the melon's middle
R = 7.6
TOP = C[1] + 3.6  # the cut


def upright(y, h, d, color, x=0.0, z=C[2]):
    return solid("Cylinder", x, y, z, h, d, d, color, rot=(0, 0, 90))


body = [solid("Ball", *C, 2 * R, 2 * R, 2 * R, "Melon")]  # a big striped watermelon...
for k in range(6):
    body.append(solid("Cylinder", *C, 1.4, 2 * R + 0.3, 2 * R + 0.3, "Stripe", rot=(0, k * 30, 0)))
rr = math.sqrt(R * R - 3.6 * 3.6)  # (the melon's radius at the cut)
body += [
    upright(TOP + 2.0, 4.0, 2 * rr + 0.4, "Melon"),  # ...its top cut off:
    upright(TOP + 4.2, 0.4, 2 * rr + 0.4, "Rind"),  # a white rind...
    upright(TOP + 4.5, 0.4, 2 * rr - 1.0, "Flesh"),  # ...round red flesh...
]
for k in range(12):  # ...with black seeds
    a = math.radians(k * 30 + 10)
    body.append(block(math.sin(a) * (rr - 1.6), TOP + 4.75, C[2] - math.cos(a) * (rr - 1.6), 0.5, 0.3, 0.9, "Seed", rot=(0, -math.degrees(a), 0)))

HY, HZ = TOP + 8.6, C[2] - 1.0  # the raccoon's head
head = [
    block(0, HY, HZ, 6.4, 5.4, 5.0, "Grey"),  # a grey head...
    block(0, HY - 3.6, HZ + 0.4, 4.8, 2.6, 4.2, "Grey"),  # (its neck)
    block(0, HY + 0.4, HZ - 2.6, 6.6, 1.8, 0.4, "Mask"),  # ...a black mask...
    block(0, HY - 1.2, HZ - 2.9, 3.6, 2.0, 1.2, "White"),  # ...a white muzzle...
    block(0, HY - 0.7, HZ - 3.65, 1.2, 0.8, 0.4, "Mask"),  # ...a black nose
    plate(0, HY + 1.9, HZ - 2.55, 1.0, 1.2, "Mask", depth=0.15),  # (a stripe up its forehead)
]
head += both(
    plate(1.6, HY + 0.4, HZ - 2.95, 1.2, 1.2, "Eye", depth=0.2),  # shiny eyes in the mask
    plate(1.4, HY + 0.65, HZ - 3.1, 0.4, 0.4, "Glint", depth=0.1),
    block(2.0, HY + 1.65, HZ - 2.75, 2.0, 0.6, 0.4, "White"),  # (white brows)
    block(2.4, HY + 3.2, HZ + 0.4, 1.8, 1.8, 1.0, "Grey"),  # round ears
    plate(2.4, HY + 3.2, HZ - 0.15, 1.0, 1.0, "White", depth=0.2),
)
LID = (0.0, HY + 2.6, C[2] + 5.4)  # the lifted lid, tipped back behind its head
head += [
    solid("Cylinder", *LID, 1.0, 2 * rr - 1.0, 2 * rr - 1.0, "Flesh", rot=(-55, 90, 0)),
    solid("Cylinder", LID[0], LID[1] + 0.4, LID[2] + 0.5, 2.0, 2 * rr, 2 * rr, "Melon", rot=(-55, 90, 0)),
]

arms = []
for s in (-1, 1):  # little dark paws on the rim
    arms += [
        block(s * 2.4, TOP + 5.0, C[2] - 4.0, 2.0, 2.2, 1.6, "Grey"),
        block(s * 2.4, TOP + 4.6, C[2] - rr + 0.6, 2.0, 1.0, 2.4, "Mask"),
    ]

legs = []
for s in (-1, 1):  # (ours) stubby dark paws under the melon
    legs += [
        block(s * 3.4, 1.6, -1.8, 2.6, 2.4, 2.6, "Grey"),
        block(s * 3.4, 0.6, -3.4, 2.8, 1.2, 2.8, "Mask"),
    ]

ART = {
    "Comment": "Raccooni Watermelunni: a raccoon with a black mask and a white muzzle peeking out of a big striped watermelon cut open on top (red flesh, black seeds), the lifted lid tipped back behind its head, its dark paws on the rim.",
    "VoxelSize": 0.2,
    "Palette": {
        "Melon": (66, 150, 64),
        "Stripe": (30, 92, 40),
        "Rind": (236, 246, 220),
        "Flesh": (234, 64, 70),
        "Seed": (24, 20, 20),
        "Grey": (140, 140, 148),
        "Mask": (34, 34, 40),
        "White": (244, 244, 242),
        "Eye": (40, 36, 40),
        "Glint": (250, 250, 250),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
