# Blueberrinni Octopusini (art v2, blocks): a fuzzy blueberry octopus, after the original
# meme image (by @alexey_pigeon): a big round blue head with huge glossy dark eyes and a
# blueberry's star-shaped crown on top; a skirt where its tentacles meet; its "arms" are
# two tentacles curling up at its sides; six more tentacles spread on the ground, pink
# suckers underneath and curled tips.
import math

from voxel_art import block, both, plate

head = [  # the round head, stepped out of blocks
    block(0, 17.6, 0.6, 11, 8.4, 10, "Blue"),
    block(0, 17.6, 0.6, 9, 11.2, 8.4, "Blue"),
    block(0, 17.6, 0.6, 11.8, 5.6, 8, "Blue"),
    block(0, 17.6, 0.6, 7.4, 12.4, 6.4, "Blue"),
]
head += [  # the blueberry's crown: a dark ring with five points
    block(0, 24.1, 0.6, 4.4, 0.8, 4.4, "Crown"),
    block(0, 24.5, 0.6, 2.6, 0.4, 2.6, "CrownDark"),
]
for k in range(5):
    a = math.radians(k * 72)
    head.append(block(math.sin(a) * 2.4, 24.4, 0.6 - math.cos(a) * 2.4, 1.2, 0.8, 1.2, "Crown", rot=(0, k * 72, 0)))
head += both(
    plate(2.5, 17.4, -4.55, 3.4, 4.0, "Eye", depth=0.6),  # huge glossy dark eyes...
    plate(2.5, 17.4, -4.75, 2.6, 4.6, "Eye", depth=0.3),
    plate(1.6, 18.6, -4.95, 1.0, 1.2, "White", depth=0.15),  # ...with glints
    plate(3.2, 16.2, -4.95, 0.5, 0.5, "White", depth=0.15),
)
head.append(plate(0, 14.6, -4.4, 1.4, 0.4, "Mouth", depth=0.3))  # a tiny mouth

body = [
    block(0, 10.15, 0.6, 9.6, 2.5, 9.0, "Blue"),  # the skirt where its tentacles meet
    block(0, 8.6, 0.6, 7.6, 0.6, 7.0, "BlueDark"),
]

arms = []
for side in (-1, 1):  # two tentacles curling up at its sides
    arms += [
        block(side * 5.9, 10.6, -0.6, 2.2, 2.4, 2.4, "Blue"),
        block(side * 7.4, 12.4, -0.8, 2.0, 3.0, 2.2, "Blue", rot=(0, 0, side * -20)),
        block(side * 8.2, 15.0, -1.0, 1.8, 2.6, 2.0, "Blue", rot=(0, 0, side * -5)),
        block(side * 7.6, 16.8, -1.0, 1.6, 1.6, 1.8, "Blue", rot=(0, 0, side * 30)),
        plate(side * 6.75, 12.4, -0.8, 0.6, 0.6, "Sucker", depth=0.15, rot=(0, 90, 0)),
        plate(side * 7.25, 14.8, -1.0, 0.6, 0.6, "Sucker", depth=0.15, rot=(0, 90, 0)),
    ]

legs = []
for k in range(6):  # six tentacles spread on the ground, tips curling up
    a = math.radians(-150 + k * 60)  # (none straight out the front, where the arms are)
    dx, dz = math.sin(a), -math.cos(a)
    legs += [
        block(dx * 3.0, 5.9, 0.6 + dz * 3.0, 2.6, 4.8, 2.6, "Blue"),
        block(dx * 5.0, 1.6, 0.6 + dz * 5.0, 2.4, 2.4, 2.4, "Blue"),
        block(dx * 7.2, 1.0, 0.6 + dz * 7.2, 2.2, 2.0, 2.2, "Blue", rot=(0, math.degrees(a), 0)),
        block(dx * 8.6, 2.0, 0.6 + dz * 8.6, 1.6, 2.0, 1.6, "Blue", rot=(0, math.degrees(a), 0)),
        block(dx * 5.6, 2.85, 0.6 + dz * 5.6, 0.8, 0.1, 0.8, "Sucker"),  # pink suckers
        block(dx * 7.2, 2.05, 0.6 + dz * 7.2, 0.7, 0.1, 0.7, "Sucker"),
    ]

ART = {
    "Comment": "Blueberrinni Octopusini: a fuzzy blue octopus with huge glossy eyes and a blueberry crown, two tentacles curled up, six on the ground with pink suckers.",
    "VoxelSize": 0.2,
    "Palette": {
        "Blue": (96, 116, 210),
        "BlueDark": (70, 86, 170),
        "Crown": (52, 62, 140),
        "CrownDark": (36, 42, 100),
        "Eye": (24, 22, 44),
        "White": (250, 250, 255),
        "Mouth": (50, 40, 90),
        "Sucker": (244, 156, 178),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
