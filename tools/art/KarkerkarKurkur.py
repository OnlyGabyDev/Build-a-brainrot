# Karkerkar Kurkur (art v2, blocks): a living chair, after the meme by @sabrandeedat3 (no
# original image could be reached: drawn from playbrainrot.org's pixel version and the wiki's
# description; redraw it from the original when we have it): an aqua green chair whose
# tall backrest is its face (big round eyes, a nose, a slightly open mouth), green hands at
# the ends of its armrests (its "arms"), and four legs ending in big feet.
from voxel_art import block, both, plate, solid

SEAT = 10.0  # the seat's height
W, D = 10.4, 9.0  # the seat's width and depth

body = [
    block(0, SEAT, 0.4, W, 2.0, D, "Chair"),  # a seat...
    block(0, SEAT - 1.2, 0.4, W - 0.6, 0.4, D - 0.6, "ChairDark"),
]

BZ = 0.4 + D / 2 - 1.0  # the backrest (its head)
head = [
    block(0, SEAT + 7.6, BZ, W, 13.2, 2.0, "Chair"),  # a tall backrest...
    block(0, SEAT + 14.4, BZ, W - 1.2, 0.6, 2.2, "ChairDark"),
    block(0, SEAT + 5.4, BZ - 1.4, 2.0, 2.4, 1.0, "ChairDark"),  # ...a nose...
    block(0, SEAT + 3.0, BZ - 1.15, 3.6, 1.0, 0.4, "Mouth"),  # ...a slightly open mouth
    block(0, SEAT + 3.65, BZ - 1.2, 4.4, 0.4, 0.4, "ChairDark"),
]
head += both(
    solid("Cylinder", 2.4, SEAT + 8.6, BZ - 1.15, 0.4, 3.0, 3.0, "White", rot=(0, 90, 0)),  # big round eyes
    solid("Cylinder", 2.2, SEAT + 8.4, BZ - 1.45, 0.4, 1.5, 1.5, "Pupil", rot=(0, 90, 0)),
    plate(1.9, SEAT + 8.9, BZ - 1.75, 0.4, 0.4, "White", depth=0.1),
    block(2.5, SEAT + 10.8, BZ - 1.2, 2.6, 0.5, 0.4, "ChairDark", rot=(0, 0, -8)),  # (brows)
)

arms = []
for s in (-1, 1):  # armrests ending in green hands
    x = s * (W / 2 - 0.6)
    arms += [
        block(x, SEAT + 2.4, 1.0, 1.2, 3.0, 1.2, "Chair"),
        block(x, SEAT + 3.9, 0.0, 1.6, 1.0, D - 1.0, "Chair"),
        block(x + s * 0.2, SEAT + 4.0, -D / 2 + 0.4, 2.2, 1.8, 2.0, "Hand"),
        block(x + s * 0.2, SEAT + 3.4, -D / 2 - 0.4, 1.8, 0.8, 0.8, "Hand"),
    ]

legs = []
for x in (-W / 2 + 1.0, W / 2 - 1.0):  # four legs with big feet
    for z in (-D / 2 + 1.4, D / 2 - 0.6):
        legs += [
            block(x, SEAT / 2, z, 1.6, SEAT - 1.0, 1.6, "Chair"),
            block(x, 0.7, z - 0.8, 2.6, 1.4, 3.6, "Foot"),
        ]

ART = {
    "Comment": "Karkerkar Kurkur: an aqua green chair whose tall backrest is its face with big round eyes, a nose and a slightly open mouth, green hands on its armrests, four legs with big feet.",
    "VoxelSize": 0.2,
    "Palette": {
        "Chair": (70, 210, 160),
        "ChairDark": (44, 168, 126),
        "Hand": (90, 222, 172),
        "Foot": (56, 186, 140),
        "Mouth": (40, 50, 46),
        "White": (250, 250, 250),
        "Pupil": (20, 20, 22),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
