# Girafa Celestre (art v2, blocks): a space giraffe living in a watermelon, after the
# original meme image (by @ofuscabreno): a round striped watermelon cut open in front (white
# rind, red flesh, black seeds), a spotted giraffe neck rising out of a hole in it to a head
# in an astronaut's helmet (an open silver rim, pale blue shell, an antenna with a glowing
# star); spotted giraffe legs in big brown boots (the front pair are its "arms").
import math

from voxel_art import block, both, plate, rod

CY, CZ = 13.0, 0.6  # the melon's middle

body = [  # the melon, round from stepped blocks
    block(0, CY, CZ, 14, 9.6, 13, "Melon"),
    block(0, CY, CZ, 12, 12.6, 11.4, "Melon"),
    block(0, CY, CZ, 9.4, 14, 9.6, "Melon"),
    block(0, CY, CZ, 14.6, 6, 10, "Melon"),
    block(0, CY, CZ, 10, 6, 13.6, "Melon"),
]
FACE = CZ - 6.8  # the cut face, in front
body += [  # white rind, red flesh, a ring of black seeds, the hole the neck comes out of
    plate(0, CY, FACE - 0.15, 12.4, 8.0, "Rind", depth=0.3),
    plate(0, CY, FACE - 0.15, 10.4, 11.0, "Rind", depth=0.3),
    plate(0, CY, FACE - 0.15, 8.0, 12.2, "Rind", depth=0.3),
    plate(0, CY, FACE - 0.35, 10.8, 6.8, "Flesh", depth=0.3),
    plate(0, CY, FACE - 0.35, 9.0, 9.4, "Flesh", depth=0.3),
    plate(0, CY, FACE - 0.35, 6.6, 10.6, "Flesh", depth=0.3),
    plate(0, CY, FACE - 0.5, 3.2, 3.2, "Hole", depth=0.2),
]
for k in range(10):
    a = math.radians(k * 36 + 18)
    body.append(plate(math.sin(a) * 3.6, CY + math.cos(a) * 3.4, FACE - 0.5, 0.5, 0.9, "Seed", depth=0.2, rot=(0, 0, -k * 36 - 18)))
# dark green stripes round its back, sides and top
for x in (-4.5, -1.5, 1.5, 4.5):
    body.append(plate(x, CY, CZ + 6.95, 1.2, 6.0, "Stripe", depth=0.3))
    body.append(block(x, CY + 7.05, CZ, 1.2, 0.3, 9.0, "Stripe"))
for z in (-2.6, 0.6, 3.8):
    body += both(block(7.35, CY, CZ + z, 0.3, 6.0, 1.2, "Stripe"))

head = [
    rod((0, CY, FACE - 0.4), (0, 21.4, FACE - 3.2), 2.4, "Giraffe"),  # the neck, out of the hole
    block(0, 23.0, -10.6, 3.0, 3.0, 3.6, "Giraffe"),  # the head...
    block(0, 22.4, -13.0, 2.6, 2.2, 1.8, "Muzzle"),  # ...its muzzle
    plate(0, 21.7, -13.95, 1.4, 0.3, "Dark", depth=0.15),
]
for t, side in ((0.25, 1), (0.5, -1), (0.75, 1)):  # brown patches down the neck
    y, z = CY + (21.4 - CY) * t, FACE - 0.4 - 2.8 * t
    head.append(plate(side * 0.4, y, z - 1.3, 1.0, 1.0, "Patch", depth=0.2, rot=(18, 0, 0)))
    head.append(block(side * 1.25, y + 0.6, z, 0.2, 1.0, 1.0, "Patch"))
head += both(
    plate(1.0, 23.9, -12.5, 0.7, 0.7, "Dark", depth=0.2),  # eyes
    plate(0.85, 24.1, -12.65, 0.25, 0.25, "Glint", depth=0.1),
    rod((0.7, 24.5, -10.2), (0.9, 25.8, -10.2), 0.5, "Giraffe"),  # little horns
    block(0.9, 26.0, -10.2, 0.7, 0.6, 0.7, "Patch"),
    block(1.9, 24.4, -9.6, 1.0, 0.5, 0.8, "Giraffe"),  # ears
    plate(0.6, 22.6, -13.95, 0.4, 0.4, "Dark", depth=0.1),  # nostrils
)
# the astronaut's helmet: an open silver rim, a pale blue shell round the head
head += [
    block(0, 26.9, -11.0, 6.6, 0.8, 6.0, "Shell"),
    block(0, 20.0, -11.0, 6.6, 0.8, 6.0, "Shell"),  # (a collar round the neck)
    block(0, 23.45, -8.3, 6.6, 6.1, 0.6, "Shell"),
    block(0, 26.9, -14.15, 6.8, 1.0, 0.6, "Rim"),
    block(0, 20.0, -14.15, 6.8, 1.0, 0.6, "Rim"),
    rod((2.2, 27.3, -10.6), (2.8, 29.6, -10.4), 0.4, "Rim"),  # an antenna...
    block(2.8, 30.1, -10.4, 1.2, 1.2, 0.5, "Star", rot=(0, 0, 45)),  # ...with a glowing star
]
head += both(
    block(3.0, 23.45, -11.0, 0.6, 6.1, 6.0, "Shell"),
    block(3.1, 23.45, -14.15, 0.6, 7.0, 0.6, "Rim"),
)


def booted_leg(x, z):
    return [
        rod((x, CY - 5.0, z), (x, 3.4, z), 1.8, "Giraffe"),  # a spotted leg...
        plate(x, 5.4, z - 0.95, 0.8, 0.8, "Patch", depth=0.15),
        block(x, 1.9, z - 0.6, 3.4, 3.0, 4.6, "Boot"),  # ...in a big brown boot
        block(x, 1.2, z - 3.3, 3.2, 2.0, 1.2, "Boot"),
        block(x, 0.3, z - 1.0, 3.6, 0.6, 5.8, "Sole"),
        plate(x, 2.9, z - 2.95, 1.6, 0.3, "Lace", depth=0.2),  # laces
        plate(x, 2.3, z - 2.95, 1.6, 0.3, "Lace", depth=0.2),
    ]


legs = booted_leg(-3.2, 3.4) + booted_leg(3.2, 3.4)
arms = booted_leg(-3.2, -2.6) + booted_leg(3.2, -2.6)

ART = {
    "Comment": "Girafa Celestre: a striped watermelon cut open in front, a giraffe's neck rising out of it to a head in an astronaut helmet with a glowing star, four spotted legs in big brown boots.",
    "VoxelSize": 0.2,
    "Palette": {
        "Melon": (70, 150, 70),
        "Stripe": (36, 96, 44),
        "Rind": (236, 246, 220),
        "Flesh": (234, 64, 70),
        "Seed": (30, 22, 22),
        "Hole": (90, 30, 34),
        "Giraffe": (234, 190, 120),
        "Muzzle": (214, 166, 104),
        "Patch": (160, 92, 44),
        "Dark": (25, 22, 26),
        "Glint": (245, 245, 245),
        "Shell": (200, 226, 246),
        "Rim": (196, 200, 210),
        "Star": (255, 226, 80),
        "Boot": (176, 92, 40),
        "Sole": (245, 240, 230),
        "Lace": (60, 40, 30),
    },
    "Materials": {"Star": "Neon"},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
