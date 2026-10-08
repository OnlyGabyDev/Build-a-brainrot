# Orangutini Ananassini (art v2, blocks): an orangutan that's a pineapple, after the
# original meme image (by @alexey_pigeon): a shaggy orange head with a bare grey-brown face
# (deep-set eyes, a wide mouth) under a pineapple's crown of spiky leaves; a golden
# pineapple body with a criss-cross of darker scales; long shaggy orange arms reaching
# the ground; short shaggy legs on dark feet.
from voxel_art import block, both, plate, wedge

body = [
    block(0, 13.4, 0, 10, 10.8, 8.4, "Pineapple"),  # the pineapple, round from stepped blocks
    block(0, 13.4, 0, 8.8, 12.8, 7.2, "Pineapple"),
    block(0, 13.4, 0, 10.8, 8, 7.2, "Pineapple"),
]
# its scales: a criss-cross of darker lines with a spike in each diamond
for y in (9.6, 12.4, 15.2, 18.0):
    for z, flip in ((-4.25, 1), (4.25, -1)):
        body.append(plate(0, y, z, 10.0, 0.45, "Scale", depth=0.3, rot=(0, 0, 32 * flip)))
        body.append(plate(0, y, z, 10.0, 0.45, "Scale", depth=0.3, rot=(0, 0, -32 * flip)))
for y in (11.0, 13.8, 16.6):
    for x in (-3.0, 0, 3.0):
        body.append(block(x, y, -4.45, 0.6, 0.6, 0.4, "Spike"))
body += both(block(5.45, 13.4, 0, 0.3, 7.6, 6.6, "PineappleDark"))

head = [
    block(0, 23.1, 0.2, 8.4, 6.6, 7.4, "Hair"),  # the shaggy head...
    block(0, 22.5, -3.6, 5.6, 5.4, 0.6, "Face"),  # ...its bare face
    block(0, 21.1, -4.2, 4.2, 2.0, 1.0, "Face"),  # a pushed-out mouth
    plate(0, 20.8, -4.75, 2.8, 0.35, "Dark", depth=0.2),
    block(0, 24.9, -3.9, 4.6, 0.8, 0.6, "FaceDark"),  # a heavy brow
]
head += both(
    plate(1.3, 23.7, -3.95, 1.1, 0.9, "Dark", depth=0.2),  # deep-set eyes
    plate(1.1, 23.9, -4.1, 0.3, 0.3, "Glint", depth=0.1),
    plate(0.4, 22.4, -3.95, 0.4, 0.5, "FaceDark", depth=0.2),  # nostrils
    block(4.4, 21.9, 0.2, 0.8, 4.2, 6.0, "HairDark"),  # shaggy cheeks
)
# the pineapple's crown of spiky leaves
for x, z, tilt, h in ((0, 0.2, 0, 7), (-1.6, 0.4, -18, 6), (1.6, 0.0, 18, 6), (0, -1.4, 0, 5.4),
                      (0, 1.8, 0, 5.6), (-3.0, 0.2, -34, 4.6), (3.0, 0.2, 34, 4.6), (-1.4, -1.6, -20, 4.6), (1.4, 1.8, 20, 4.6)):
    head.append(wedge(x, 26.4 + h / 2, z, 1.4, h, 1.2, "Leaf", rot=(0, 0, tilt)))
    head.append(block(x * 0.9, 26.9, z, 1.2, 1.2, 1.2, "LeafDark", rot=(0, 0, tilt)))

arms = []
for side in (-1, 1):  # long shaggy arms down to the ground
    arms += [
        block(side * 6.4, 17.4, -0.4, 2.6, 4.4, 3.0, "Hair", rot=(0, 0, side * 10)),
        block(side * 7.0, 11.0, -0.8, 2.4, 9.2, 2.6, "Hair"),
        block(side * 7.6, 12.0, -0.4, 0.8, 7.6, 2.8, "HairDark"),  # long shaggy hair
        block(side * 7.0, 4.6, -1.0, 2.6, 3.6, 2.8, "Hair"),
        block(side * 7.0, 1.4, -1.4, 2.8, 2.8, 3.4, "Hand"),  # dark knuckles on the ground
    ]

legs = []
for x in (-2.6, 2.6):
    legs += [
        block(x, 5.0, 0.2, 3.2, 4.8, 3.4, "Hair"),  # short shaggy legs
        block(x, 1.4, -0.6, 3.6, 2.8, 4.8, "Hand"),  # dark feet
    ]

ART = {
    "Comment": "Orangutini Ananassini: an orangutan with a pineapple body and a crown of pineapple leaves on its shaggy head, long arms to the ground.",
    "VoxelSize": 0.2,
    "Palette": {
        "Pineapple": (236, 186, 56),
        "PineappleDark": (204, 150, 40),
        "Scale": (150, 116, 40),
        "Spike": (110, 120, 40),
        "Hair": (214, 104, 36),
        "HairDark": (176, 78, 28),
        "Face": (140, 112, 96),
        "FaceDark": (100, 78, 66),
        "Hand": (84, 62, 52),
        "Dark": (30, 22, 22),
        "Glint": (240, 240, 240),
        "Leaf": (110, 168, 64),
        "LeafDark": (78, 128, 46),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
