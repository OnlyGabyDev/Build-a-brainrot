# Frigo Camelo (art v2, blocks): a white fridge with a camel's hump, built like Steal a
# Brainrot's model from clean blocks: two doors with grey handles; a camel's thick brown
# neck rising out of the fridge's front to a camel head (a pale snout, dark eyes, little
# ears); camel legs in big brown boots with white laces; its "arms" are short camel
# forelegs at its sides. Reference: Steal a Brainrot's render.
from voxel_art import block, both, plate, rod

body = [
    block(0, 19, 0, 9.4, 16, 7.4, "Fridge"),  # the fridge
    block(0, 21.6, -3.75, 9.4, 0.3, 0.2, "Seam"),  # its doors' seam
    block(3.6, 24, -4.0, 0.7, 3.6, 0.6, "Handle"),  # handles
    block(3.6, 16.2, -4.0, 0.7, 6, 0.6, "Handle"),
    block(0, 28.1, 1, 6.2, 2.2, 4.8, "Camel"),  # the hump on top
    block(0, 29.6, 1, 4.2, 0.8, 3.2, "Camel"),
]

head = [
    rod((0, 24.4, -3.9), (0, 29.4, -6.6), 3.2, "Camel"),  # the thick neck
    block(0, 30.8, -8.2, 4.2, 3.6, 5.4, "Camel"),  # the head
    block(0, 30.2, -11.6, 3.2, 2.6, 2.2, "Snout"),  # the snout
    plate(-0.7, 30.5, -12.75, 0.6, 0.6, "Dark", depth=0.1),  # nostrils
    plate(0.7, 30.5, -12.75, 0.6, 0.6, "Dark", depth=0.1),
    plate(0, 29.4, -12.75, 1.8, 0.3, "Dark", depth=0.1),
]
head += both(
    block(2.15, 31.6, -9.2, 0.2, 1.2, 1.2, "Dark"),  # eyes
    block(1.4, 33.1, -6.4, 0.9, 1.2, 0.8, "Camel"),  # little ears
)

arms = both(
    rod((5.1, 23, 0), (5.6, 15.2, -0.6), 1.8, "Camel"),  # short forelegs
    block(5.6, 14.4, -0.7, 2, 1.4, 2, "Hoof"),
)

legs = []
for x in (-2.2, 2.2):
    legs += [
        rod((x, 11, 0), (x, 3.2, -0.2), 2.2, "Camel"),
        block(x, 1.9, -0.6, 3.4, 3, 4.6, "Boot"),  # big boots...
        block(x, 0.3, -0.6, 3.6, 0.6, 4.8, "Sole"),
        plate(x, 2.2, -2.95, 2, 0.4, "Lace", depth=0.1),  # ...with white laces
        plate(x, 3.0, -2.95, 2, 0.4, "Lace", depth=0.1),
    ]

ART = {
    "Comment": "Frigo Camelo: a fridge (blocks) with a camel's hump, neck and head, camel legs in laced boots.",
    "VoxelSize": 0.2,
    "Palette": {
        "Fridge": (246, 248, 250),
        "Seam": (175, 182, 192),
        "Handle": (150, 158, 170),
        "Camel": (190, 120, 70),
        "Snout": (215, 160, 115),
        "Dark": (30, 25, 22),
        "Boot": (110, 65, 40),
        "Sole": (60, 40, 30),
        "Lace": (250, 250, 245),
        "Hoof": (80, 55, 40),
    },
    "Joints": {"Head": (0, 30.8, -8.2)},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
