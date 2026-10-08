# Zibra Zubra Zibralini (art v2, blocks): a watermelon zebra, after the original meme image
# (by @alexey_pigeon, 2025-03-06): a zebra whose body is a long striped watermelon cut open
# at the chest (red flesh, black seeds, a white rind), a black-and-white striped neck with a
# black mane up to a striped zebra head with a dark muzzle; four muscular human legs in grey
# sneakers (the front pair are its "arms"); a zebra tail with a black tuft.
import math

from voxel_art import block, both, plate, rod

CY = 12.5  # the melon's middle
LAYERS = [(11, 9, 16), (9.4, 10.6, 14.4), (12, 6.4, 13), (8, 10, 17.4), (6.4, 11.4, 15), (12.4, 4.0, 11)]
FRONT = -8.7  # the cut chest

body = [block(0, CY, 0, w, h, l, "Melon") for w, h, l in LAYERS]
for x in (-3.6, -1.2, 1.2, 3.6):  # dark green stripes along it
    body.append(block(x, CY + 5.35, 0, 1.0, 0.3, 13.0, "Stripe"))
for y in (-2.4, 0.6, 3.2):
    body += both(block(6.05, CY + y, 0, 0.3, 1.0, 12.0, "Stripe"))
body += [  # the cut chest: white rind, red flesh, black seeds
    plate(0, CY, FRONT - 0.15, 7.0, 8.6, "Rind", depth=0.3),
    plate(0, CY, FRONT - 0.15, 9.0, 6.0, "Rind", depth=0.3),
    plate(0, CY, FRONT - 0.35, 6.0, 7.6, "Flesh", depth=0.3),
    plate(0, CY, FRONT - 0.35, 8.0, 5.0, "Flesh", depth=0.3),
    plate(0, CY, -8.15, 12.4, 4.8, "Melon", depth=0.3),  # (the rind's green edge)
    rod((0, CY + 1.0, 8.4), (0, CY - 4.0, 10.4), 0.8, "Black"),  # a zebra tail...
    block(0, CY - 5.0, 10.6, 1.4, 2.2, 1.4, "Black"),  # ...with a black tuft
]
for k in range(8):
    a = math.radians(k * 45 + 22)
    body.append(plate(math.sin(a) * 2.4, CY + math.cos(a) * 2.6, FRONT - 0.5, 0.5, 0.9, "Seed", depth=0.2, rot=(0, 0, -k * 45 - 22)))

# the neck: short slanted segments in black and white, up to the head
neck = [(0, CY + 2.0, -6.8), (0, CY + 11.0, -10.4)]
head = []
for k in range(7):
    t0, t1 = k / 7, (k + 1) / 7
    a = [neck[0][i] + (neck[1][i] - neck[0][i]) * t0 for i in range(3)]
    b = [neck[0][i] + (neck[1][i] - neck[0][i]) * t1 for i in range(3)]
    head.append(rod(a, b, 3.8, "White" if k % 2 == 0 else "Black"))
head.append(rod((0, CY + 3.4, -4.8), (0, CY + 12.6, -8.6), 1.0, "Black"))  # the mane
HZ = -12.4
head += [
    block(0, CY + 12.6, HZ, 4.6, 5.0, 6.0, "White"),  # the zebra's head...
    block(0, CY + 11.0, HZ - 3.8, 4.0, 2.8, 2.0, "Dark"),  # ...a dark muzzle
    plate(0, CY + 10.0, HZ - 4.85, 2.4, 0.3, "Black", depth=0.15),
    plate(0, CY + 13.5, HZ - 3.15, 3.6, 0.6, "Black", depth=0.3),  # stripes on its forehead
    plate(0, CY + 14.6, HZ - 3.15, 3.0, 0.6, "Black", depth=0.3),
]
for z in (-1.4, 0.4, 2.2):  # black stripes round the head
    head.append(block(0, CY + 12.6, HZ + z, 5.0, 5.4, 0.7, "Black"))
head += both(
    block(2.35, CY + 13.0, HZ - 2.0, 0.3, 1.1, 1.1, "Eye"),  # eyes on its sides
    block(2.5, CY + 13.2, HZ - 2.2, 0.1, 0.4, 0.4, "Glint"),
    block(1.4, CY + 15.8, HZ + 1.4, 1.0, 2.0, 1.0, "White"),  # ears
    block(1.4, CY + 16.5, HZ + 1.4, 1.1, 0.6, 1.1, "Black"),
    plate(1.0, CY + 11.4, HZ - 4.85, 0.6, 0.5, "Black", depth=0.1),  # nostrils
)


def leg(x, z):
    return [
        block(x, 6.4, z, 3.2, 3.6, 3.4, "Skin"),  # a muscular thigh...
        block(x, 3.8, z + 0.2, 2.4, 2.0, 2.6, "Skin"),  # ...a knee and calf
        block(x, 4.4, z + 1.0, 2.6, 2.6, 1.4, "Skin"),
        block(x, 1.4, z - 0.4, 3.0, 2.0, 4.4, "Sneaker"),  # a grey sneaker
        block(x, 0.3, z - 0.4, 3.2, 0.6, 4.8, "Sole"),
        block(x, 1.0, z - 2.5, 3.1, 1.0, 0.6, "Sole"),
        plate(x, 2.5, z - 1.4, 1.6, 0.3, "White", depth=0.5, rot=(90, 0, 0)),  # laces
    ]


legs = leg(-3.0, 5.0) + leg(3.0, 5.0)
arms = leg(-3.0, -4.6) + leg(3.0, -4.6)

ART = {
    "Comment": "Zibra Zubra Zibralini: a zebra whose body is a long striped watermelon cut open at the chest, a striped neck with a black mane, a zebra head, four muscular human legs in grey sneakers.",
    "VoxelSize": 0.2,
    "Palette": {
        "Melon": (70, 150, 70),
        "Stripe": (34, 92, 42),
        "Rind": (236, 246, 220),
        "Flesh": (234, 64, 70),
        "Seed": (30, 22, 22),
        "White": (246, 246, 246),
        "Black": (28, 28, 32),
        "Dark": (60, 58, 64),
        "Eye": (24, 22, 26),
        "Glint": (245, 245, 245),
        "Skin": (196, 140, 104),
        "Sneaker": (150, 156, 166),
        "Sole": (238, 238, 238),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
