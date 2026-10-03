# Brr Brr Patapim (art v2, blocks): a tall forest creature, built like Steal a Brainrot's
# model from clean blocks: a mossy green hood (darker leaf patches) round a beige
# proboscis-monkey face (yellow eyes, a long droopy nose), a white beard down its chest,
# moss over its back, shoulders and thighs, long bare arms and legs, big hands and feet.
# Reference: Steal a Brainrot's render.
from voxel_art import block, both, plate, rod

head = [
    block(0, 31, 0.6, 10, 11, 9, "Moss"),  # the mossy hood
    block(0, 30.2, -4.0, 6.4, 7.2, 0.4, "Skin"),  # the face
    block(0, 33.6, -4.25, 6.6, 0.8, 0.4, "Brow"),
    rod((0, 30.8, -4.6), (0, 26.6, -5.6), 2.2, "Nose"),  # the long droopy nose
    block(0, 26.2, -5.7, 2.8, 1.6, 2, "Nose"),
    plate(-0.6, 25.6, -6.75, 0.5, 0.4, "Nostril", depth=0.1),
    plate(0.6, 25.6, -6.75, 0.5, 0.4, "Nostril", depth=0.1),
    block(0, 26.5, -3.4, 5.6, 2.6, 2.2, "Fur"),  # the beard's top
]
head += both(
    plate(1.9, 32.2, -4.3, 1.8, 1.4, "Eye", depth=0.2),  # yellow eyes
    plate(1.6, 32.1, -4.45, 0.7, 0.9, "Pupil", depth=0.1),
    plate(4.2, 33, -2, 1.6, 2.4, "MossDark", depth=0.2, rot=(0, 90, 0)),  # leaf patches
    plate(4.2, 28.4, 2, 2, 1.8, "MossDark", depth=0.2, rot=(0, 90, 0)),
)
head += [plate(x, y, 5.15, 2, 2, "MossDark", depth=0.2) for x, y in ((-2, 33), (2, 29), (-1, 27.5))]

body = [
    block(0, 20.5, 0, 8, 9.6, 6.2, "Skin"),
    block(0, 20.8, 1.3, 8.6, 9.8, 4, "Moss"),  # moss over its back and sides
    block(0, 21, -3.2, 4.8, 8.6, 0.4, "Fur"),  # the beard down its chest
]
body += [plate(x, y, 3.4, 2, 2, "MossDark", depth=0.2) for x, y in ((-2, 18), (2, 22.5), (0, 24.5))]

arms = both(
    block(5, 24, 0.4, 3, 3, 3.4, "Moss"),  # leafy shoulders
    rod((5.2, 22.6, 0.2), (5.6, 11.6, -0.4), 1.6, "Skin"),  # long thin arms
    block(5.7, 10.4, -0.5, 2.2, 2.6, 2, "Skin"),  # big hands
)

legs = both(
    block(2.2, 13.2, 0, 3.4, 3.4, 3.6, "Moss"),  # moss round the thighs
    rod((2.2, 12, 0), (2.2, 1.6, -0.3), 2.1, "Skin"),  # long legs
    block(2.2, 0.8, -1.4, 3, 1.6, 4.6, "Skin"),  # big bare feet
    plate(2.2, 0.9, -3.75, 2.6, 1.0, "Toe", depth=0.1),
)

ART = {
    "Comment": "Brr Brr Patapim: a tall forest creature (blocks) under a mossy hood, a long droopy nose, a white beard, long bare limbs and big feet.",
    "VoxelSize": 0.2,
    "Palette": {
        "Moss": (70, 165, 75),
        "MossDark": (40, 120, 55),
        "Skin": (238, 196, 150),
        "Toe": (205, 160, 120),
        "Fur": (246, 242, 232),
        "Eye": (255, 214, 40),
        "Pupil": (25, 20, 15),
        "Brow": (150, 110, 80),
        "Nose": (226, 176, 132),
        "Nostril": (120, 70, 50),
    },
    "Joints": {"Head": (0, 31, 0)},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
