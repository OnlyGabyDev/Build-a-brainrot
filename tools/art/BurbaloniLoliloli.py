# Burbaloni Loliloli (art v2, blocks): a capybara living in a coconut, after the original
# meme image (by @alexey_pigeon): a big round hairy brown coconut, stepped out of blocks,
# with an opening of white coconut flesh in front; a capybara's head poking out of it (a
# big square muzzle, a dark nose, small eyes and ears); its "arms" are two little paws
# holding the opening's rim; four short capybara legs with dark feet.
import random

from voxel_art import block, both, plate

rng = random.Random(11)  # the fibres' spots, the same every run
CY = 13.0  # the coconut's middle

body = [
    block(0, CY, 0, 13, 9, 12, "Coconut"),  # the coconut, round from stepped blocks
    block(0, CY, 0, 11, 13, 10, "Coconut"),
    block(0, CY, 0, 9, 14.6, 8, "Coconut"),
    block(0, CY, 0, 13.6, 5, 9, "Coconut"),
    block(0, CY, 0, 9, 5, 12.6, "Coconut"),
]
# hairy fibres: darker and paler strokes all over
for _ in range(70):
    face = rng.choice(("left", "right", "back", "top", "front"))
    shade = rng.choice(("Fibre", "Fibre", "FibreLight"))
    if face in ("left", "right"):
        x = 6.6 if face == "right" else -6.6
        body.append(block(x + (0.25 if x > 0 else -0.25), rng.uniform(CY - 3.6, CY + 3.6), rng.uniform(-4.2, 4.2), 0.4, rng.uniform(1.2, 2.2), 0.4, shade, rot=(rng.uniform(-30, 30), 0, 0)))
    elif face == "back":
        body.append(block(rng.uniform(-5.2, 5.2), rng.uniform(CY - 3.6, CY + 3.6), 6.25, 0.4, rng.uniform(1.2, 2.2), 0.4, shade, rot=(0, 0, rng.uniform(-30, 30))))
    elif face == "top":
        body.append(block(rng.uniform(-3.6, 3.6), CY + 7.45, rng.uniform(-3.2, 3.2), 0.4, 0.4, rng.uniform(1.2, 2.2), shade, rot=(0, rng.uniform(-40, 40), 0)))
    else:
        x = rng.uniform(-5.6, 5.6)
        if abs(x) < 4.6:
            continue  # (the opening's here)
        body.append(block(x, rng.uniform(CY - 3.6, CY + 3.6), -6.25, 0.4, rng.uniform(1.2, 2.2), 0.4, shade, rot=(0, 0, rng.uniform(-30, 30))))
body += [  # the opening: a ring of white flesh round a dark hollow
    plate(0, CY + 0.4, -6.1, 9.6, 9.4, "Flesh", depth=0.6),
    plate(0, CY + 0.4, -6.25, 7.8, 7.6, "Hollow", depth=0.5),
]

arms = both(  # little paws holding the rim
    block(2.6, CY - 3.0, -6.8, 1.8, 1.2, 1.6, "Fur"),
    block(2.6, CY - 3.0, -7.65, 1.4, 0.8, 0.3, "Dark"),
)

head = [
    block(0, CY + 1.0, -8.2, 7.0, 6.0, 4.8, "Fur"),  # the capybara's head...
    block(0, CY - 0.2, -12.0, 6.0, 4.2, 3.0, "Fur"),  # ...its big square muzzle
    block(0, CY + 0.9, -13.65, 4.0, 1.4, 0.4, "Nose"),
    plate(0, CY - 1.3, -13.55, 2.6, 0.4, "Dark", depth=0.2),  # a little mouth
    block(0, CY + 4.1, -8.4, 6.0, 0.6, 4.0, "FurDark"),  # darker on top
]
head += both(
    plate(2.3, CY + 2.8, -10.65, 1.0, 1.0, "Dark", depth=0.3),  # small eyes
    plate(2.1, CY + 3.0, -10.85, 0.3, 0.3, "Glint", depth=0.1),
    block(3.1, CY + 4.4, -6.9, 1.6, 1.4, 1.0, "FurDark"),  # small round ears
    plate(1.1, CY + 1.0, -13.9, 0.6, 0.5, "Dark", depth=0.15),  # nostrils
)

legs = []
for x in (-3.8, 3.8):
    for z in (-3.0, 3.6):
        legs += [
            block(x, 4.0, z, 2.6, 4.8, 2.8, "Fur"),  # short legs
            block(x, 0.8, z - 0.4, 3.0, 1.6, 3.6, "Dark"),  # dark feet
        ]

ART = {
    "Comment": "Burbaloni Loliloli: a capybara poking its head out of a big round hairy coconut, little paws on the rim, four short legs.",
    "VoxelSize": 0.2,
    "Palette": {
        "Coconut": (128, 84, 50),
        "Fibre": (96, 60, 34),
        "FibreLight": (168, 120, 76),
        "Flesh": (250, 248, 240),
        "Hollow": (60, 40, 28),
        "Fur": (176, 124, 78),
        "FurDark": (140, 96, 58),
        "Nose": (60, 42, 34),
        "Dark": (36, 28, 26),
        "Glint": (240, 240, 240),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
