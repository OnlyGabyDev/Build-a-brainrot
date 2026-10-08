# Antonio (art v2, blocks): a broccoli in a suit, after the original meme image (by
# @alvarito_318, 2025-04-18): a smiling green face with thick black glasses under a big
# bushy broccoli head (dark green florets), a green stalk neck; a smart dark green suit, a
# white shirt and a green tie, green hands; green trousers and dark shoes. No labels.
import math

from voxel_art import block, both, plate, rod, solid

SY = 13.4  # the suit's middle
body = [
    block(0, SY, 0.6, 8.2, 7.6, 5.0, "Suit"),  # a smart dark green suit...
    block(0, SY + 1.4, -1.95, 2.6, 4.6, 0.3, "Shirt"),  # ...a white shirt...
    block(0, SY + 1.25, -2.15, 0.9, 4.2, 0.3, "Tie"),  # ...a green tie
    block(0, SY + 3.5, -2.2, 1.2, 0.8, 0.4, "Tie"),
    block(0, SY + 4.2, 0.6, 3.0, 1.4, 2.6, "Stalk"),  # (the stalk neck)
]
body += both(
    block(1.7, SY + 2.2, -2.05, 1.4, 3.6, 0.3, "SuitDark", rot=(0, 0, -18)),  # lapels
    plate(3.0, SY - 1.2, -2.0, 1.6, 0.3, "SuitDark", depth=0.15),  # (a pocket)
)
body.append(plate(-0.8, SY - 2.6, -2.0, 0.5, 0.5, "Button", depth=0.15))

HY = SY + 7.6  # the head
head = [
    block(0, HY - 1.2, 0.4, 5.0, 5.0, 4.6, "Face"),  # a smiling green face...
    block(0, HY - 1.7, -2.35, 1.2, 1.4, 1.0, "FaceDark"),  # ...a nose...
    block(0, HY - 3.0, -1.95, 2.4, 0.4, 0.3, "Mouth"),  # ...a smile
    block(-1.4, HY - 2.75, -1.95, 0.6, 0.4, 0.3, "Mouth", rot=(0, 0, -30)),
    block(1.4, HY - 2.75, -1.95, 0.6, 0.4, 0.3, "Mouth", rot=(0, 0, 30)),
    block(0, HY - 0.6, -2.2, 1.0, 0.4, 0.4, "Glasses"),  # thick black glasses
]
head += both(
    block(1.4, HY - 0.6, -2.2, 2.0, 1.6, 0.4, "Glasses"),
    plate(1.4, HY - 0.6, -2.45, 1.4, 1.0, "Lens", depth=0.15),
    plate(1.3, HY - 0.6, -2.6, 0.5, 0.5, "Dark", depth=0.15),
    block(2.5, HY - 0.6, -0.4, 0.3, 0.4, 3.4, "Glasses"),
)
for x, y, z, d in ((0, 3.2, 0.4, 6.0), (-3.0, 2.2, 0.0, 4.6), (3.0, 2.2, 0.0, 4.6), (-1.6, 3.8, -1.8, 4.0), (1.6, 3.8, -1.8, 4.0), (-1.8, 3.6, 2.4, 4.4), (1.8, 3.6, 2.4, 4.4), (0, 5.4, 0.8, 4.4), (-3.4, 1.4, -1.6, 3.2), (3.4, 1.4, -1.6, 3.2), (0, 2.4, -2.6, 3.6)):
    head.append(solid("Ball", x, HY + y, z, d, d, d, "Floret" if (x + y) % 2 < 1 else "FloretDark"))  # a big bushy broccoli head

arms = []
for s in (-1, 1):  # suit arms, green hands
    arms += [
        block(s * 5.0, SY + 1.4, 0.6, 2.4, 4.4, 2.6, "Suit"),
        block(s * 5.2, SY - 2.6, 0.4, 2.2, 4.0, 2.4, "Suit"),
        block(s * 5.2, SY - 4.8, 0.4, 2.5, 0.6, 2.7, "Shirt"),
        block(s * 5.2, SY - 5.8, 0.2, 1.8, 1.8, 1.8, "Face"),
    ]

legs = []
for s in (-1, 1):  # green trousers, dark shoes
    x = s * 2.0
    legs += [
        block(x, 5.6, 0.6, 3.4, 8.0, 3.2, "Suit"),
        block(x, 0.8, -0.2, 3.0, 1.6, 4.6, "Shoe"),
    ]

ART = {
    "Comment": "Antonio: a smiling green face with thick black glasses under a big bushy broccoli head, a dark green suit with a white shirt and a green tie, green trousers and dark shoes.",
    "VoxelSize": 0.2,
    "Palette": {
        "Suit": (40, 96, 50),
        "SuitDark": (30, 74, 40),
        "Shirt": (244, 244, 238),
        "Tie": (30, 110, 60),
        "Button": (20, 40, 26),
        "Stalk": (150, 196, 90),
        "Face": (130, 190, 80),
        "FaceDark": (106, 164, 62),
        "Mouth": (50, 70, 30),
        "Glasses": (20, 20, 22),
        "Lens": (200, 220, 200),
        "Dark": (24, 30, 22),
        "Floret": (60, 140, 50),
        "FloretDark": (40, 110, 40),
        "Shoe": (30, 30, 30),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
