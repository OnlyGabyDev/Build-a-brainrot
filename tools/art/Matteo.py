# Matteo (art v2, blocks): a furry gentleman, after the original meme image (by
# @pollonavale): a stout shaggy brown creature with a huge round pink nose, small round
# black sunglasses and a black top hat, a long dark blue tie down its furry chest, hairy
# arms hanging, and big bare feet.
import math

from voxel_art import block, both, plate, rod, solid

BY = 10.0  # the body's middle
body = [
    block(0, BY, 0.6, 10.0, 9.4, 7.6, "Fur"),  # a stout shaggy body...
    block(0, BY - 0.6, -3.15, 7.0, 7.4, 0.3, "FurLight"),
    plate(0, BY + 0.8, -3.45, 1.4, 6.0, "Tie", depth=0.3),  # ...a long dark blue tie
    block(0, BY + 4.0, -3.4, 1.8, 1.2, 0.6, "Tie"),
]
for k in range(10):  # (shaggy tufts)
    a = math.radians(k * 36 + 10)
    body.append(block(math.sin(a) * 4.9, BY - 4.4 + (k % 3) * 0.3, 0.6 - math.cos(a) * 3.7, 1.6, 1.8, 1.6, "FurDark", rot=(0, -math.degrees(a), 0)))

HY = BY + 8.0  # the head
head = [
    block(0, HY, 0.4, 8.6, 6.6, 7.0, "Fur"),  # a shaggy head...
    block(0, HY - 2.4, -2.4, 7.4, 2.4, 3.0, "FurLight"),  # ...a furry beard
    solid("Ball", 0, HY - 0.8, -4.0, 4.4, 4.4, 4.4, "Nose"),  # ...a huge round pink nose
    block(0, HY + 1.2, -3.2, 6.6, 0.4, 0.4, "Shades"),  # small round black sunglasses
    solid("Cylinder", 0, HY + 3.6, 0.4, 0.8, 11.0, 11.0, "Hat", rot=(0, 0, 90)),  # a black top hat: the brim...
    solid("Cylinder", 0, HY + 7.0, 0.4, 6.0, 7.0, 7.0, "Hat", rot=(0, 0, 90)),  # ...the crown...
    solid("Cylinder", 0, HY + 4.6, 0.4, 1.2, 7.1, 7.1, "HatBand", rot=(0, 0, 90)),  # ...a band
]
head += both(
    solid("Cylinder", 2.0, HY + 1.0, -3.3, 0.5, 2.4, 2.4, "Shades", rot=(0, 90, 0)),
    plate(1.6, HY + 1.4, -3.6, 0.5, 0.4, "Glint", depth=0.1),
    block(3.9, HY + 1.0, -1.0, 0.4, 0.4, 4.0, "Shades"),
)

arms = []
for s in (-1, 1):  # hairy arms hanging
    arms += [
        solid("Ball", s * 5.4, BY + 3.2, 0.6, 3.8, 3.8, 3.8, "Fur"),
        block(s * 5.8, BY - 1.0, 0.4, 2.8, 7.6, 3.0, "Fur", rot=(0, 0, s * 5)),
        block(s * 6.0, BY - 5.4, 0.2, 2.6, 2.0, 2.8, "Skin"),
    ]

legs = []
for s in (-1, 1):  # big bare feet
    x = s * 2.6
    legs += [
        block(x, 3.4, 0.6, 3.4, 4.0, 3.6, "Fur"),
        block(x, 0.9, -0.8, 3.8, 1.8, 6.0, "Skin"),
    ]
    for dx in (-1.2, -0.4, 0.4, 1.2):  # toes
        legs.append(block(x + dx, 0.6, -4.2, 0.7, 0.9, 1.0, "Skin"))

ART = {
    "Comment": "Matteo: a stout shaggy brown creature with a huge round pink nose, small round black sunglasses and a black top hat, a long dark blue tie, hairy arms, big bare feet.",
    "VoxelSize": 0.2,
    "Palette": {
        "Fur": (130, 96, 64),
        "FurDark": (104, 74, 48),
        "FurLight": (160, 124, 88),
        "Nose": (226, 140, 130),
        "Shades": (20, 20, 22),
        "Glint": (200, 210, 230),
        "Hat": (26, 26, 30),
        "HatBand": (60, 60, 70),
        "Tie": (34, 46, 80),
        "Skin": (200, 150, 120),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
