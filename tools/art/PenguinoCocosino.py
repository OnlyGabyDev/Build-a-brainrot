# Penguino Cocosino (art v2, blocks): a coconut penguin, after the original meme image (by
# @alexey_pigeon): a tall egg-shaped hairy brown coconut with a big opening of white coconut
# flesh for a belly, the top of the coconut is the head (a white penguin face round black
# eyes, a black beak, a few loose hairs); its "arms" are black flippers; flat black feet.
import random

from voxel_art import block, both, plate, rod

rng = random.Random(7)  # the fibres' spots, the same every run
CY = 10.5  # the body's middle
NECK = 17.0  # where the head (the coconut's top) starts

body = [  # the coconut's lower part, round from stepped blocks
    block(0, CY, 0, 12, 13, 11, "Coconut"),
    block(0, CY, 0, 10.4, 15, 9.6, "Coconut"),
    block(0, CY + 0.4, 0, 12.8, 9, 9.2, "Coconut"),
    block(0, CY + 0.4, 0, 9.2, 9, 12.4, "Coconut"),
    plate(0, CY - 0.4, -6.2, 8.6, 7.4, "Flesh", depth=0.6),  # the opening: an oval of white flesh round...
    plate(0, CY - 0.4, -6.2, 7.4, 9.6, "Flesh", depth=0.6),
    plate(0, CY - 0.4, -6.2, 5.2, 11.0, "Flesh", depth=0.6),
    plate(0, CY - 0.4, -6.4, 6.8, 6.0, "Meat", depth=0.6),  # ...a creamy hollow
    plate(0, CY - 0.4, -6.4, 5.6, 8.0, "Meat", depth=0.6),
    plate(0, CY - 0.4, -6.4, 3.6, 9.2, "Meat", depth=0.6),
]

head = [  # the coconut's top, tapering up
    block(0, NECK + 2.0, 0.2, 11.0, 4.0, 10.4, "Coconut"),
    block(0, NECK + 3.4, 0.2, 9.4, 5.0, 8.8, "Coconut"),
    block(0, NECK + 5.6, 0.4, 7.0, 2.4, 6.6, "Coconut"),
    block(0, NECK + 6.9, 0.6, 4.0, 1.0, 3.6, "Coconut"),
    plate(0, NECK + 3.2, -5.4, 8.4, 3.6, "White", depth=0.4),  # a big white penguin face
    plate(0, NECK + 2.4, -5.4, 6.4, 5.6, "White", depth=0.4),
    plate(0, NECK + 1.4, -5.4, 3.6, 5.0, "White", depth=0.4),
    block(0, NECK + 2.0, -6.8, 2.6, 1.6, 2.4, "Black"),  # a black beak
    block(0, NECK + 1.6, -8.2, 1.6, 1.0, 1.2, "Black"),
    rod((0.4, NECK + 7.3, 0.6), (1.2, NECK + 9.0, 1.0), 0.3, "Fibre"),  # a few loose hairs
    rod((-0.4, NECK + 7.3, 0.2), (-1.4, NECK + 8.6, -0.2), 0.3, "Fibre"),
]
head += both(
    plate(2.2, NECK + 3.6, -5.75, 1.6, 1.9, "Black", depth=0.2),  # black eyes
    plate(1.9, NECK + 4.1, -5.9, 0.55, 0.55, "Glint", depth=0.1),
)
# hairy fibres: darker and paler strokes over the coconut (body and head)
for _ in range(60):
    y = rng.uniform(4.5, NECK + 4.5)
    part = head if y > NECK + 0.4 else body
    half = 5.3 if y < NECK + 3.2 else 4.6
    shade = rng.choice(("Fibre", "Fibre", "FibreLight"))
    face = rng.choice(("left", "right", "back", "back"))
    if face == "back":
        part.append(block(rng.uniform(-3.6, 3.6), y, half + 0.25, 0.4, rng.uniform(1.2, 2.0), 0.4, shade, rot=(0, 0, rng.uniform(-30, 30))))
    else:
        x = half + 0.25 if face == "right" else -half - 0.25
        part.append(block(x, y, rng.uniform(-3.4, 3.4), 0.4, rng.uniform(1.2, 2.0), 0.4, shade, rot=(rng.uniform(-30, 30), 0, 0)))

arms = both(  # black flippers, down and out
    block(7.0, CY + 1.6, 0.4, 1.2, 7.6, 3.6, "Black", rot=(0, 0, 22)),
    block(7.9, CY - 1.6, 0.4, 1.0, 3.0, 2.6, "Black", rot=(0, 0, 30)),
)


def foot(x):
    return [
        block(x, 2.2, 0.2, 2.6, 2.6, 2.6, "Black"),  # a short leg...
        block(x, 0.5, -1.4, 3.6, 1.0, 5.4, "Black"),  # ...a flat black foot
    ] + [block(x + dx, 0.5, -4.4, 0.9, 1.0, 1.0, "Black") for dx in (-1.2, 0, 1.2)]


legs = foot(-2.6) + foot(2.6)

ART = {
    "Comment": "Penguino Cocosino: a tall hairy coconut with a white flesh belly; its top is a penguin's head (white face, black eyes and beak), black flippers, flat black feet.",
    "VoxelSize": 0.2,
    "Palette": {
        "Coconut": (126, 80, 46),
        "Fibre": (94, 58, 32),
        "FibreLight": (170, 120, 74),
        "Flesh": (250, 248, 240),
        "Meat": (246, 238, 214),
        "White": (250, 250, 250),
        "Black": (30, 32, 38),
        "Glint": (245, 245, 245),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
