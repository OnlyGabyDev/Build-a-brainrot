# Dul Dul Dul (art v2, blocks): a schoolboy monkey, after the original meme image (by
# @sabrandeedat3): a grinning monkey (a tan face, a huge toothy smile, big round ears) in an
# Indonesian primary-school uniform: a white short-sleeved shirt with a collar, a red tie,
# a red-and-white flag patch over one pocket and a school badge on the other, a navy
# backpack on its back; red shorts, white socks and black shoes.
from voxel_art import block, both, plate, solid

SY = 15.6  # the shirt's middle
HY = 24.2  # the head's middle

body = [
    block(0, SY, 0.2, 8.6, 8.2, 5.0, "Shirt"),  # a white shirt...
    block(0, SY - 3.4, 0.2, 8.8, 1.4, 5.2, "Shirt"),  # ...tucked in
    block(0, SY + 3.6, 0.2, 5.6, 1.4, 4.0, "Fur"),  # (the neck)
    plate(0, SY + 0.2, -2.55, 1.2, 6.4, "Tie", depth=0.3),  # a red tie...
    block(0, SY + 3.4, -2.55, 1.6, 1.2, 0.5, "Tie"),  # ...its knot
    plate(2.0, SY + 1.6, -2.55, 2.2, 0.7, "Red", depth=0.2),  # a flag patch (red over white)
    plate(2.0, SY + 0.9, -2.55, 2.2, 0.7, "Patch", depth=0.2),
    plate(-2.0, SY + 0.4, -2.55, 2.2, 2.2, "Pocket", depth=0.15),  # a pocket...
    plate(-2.0, SY + 0.2, -2.6, 1.3, 1.5, "Badge", depth=0.2),  # ...a school badge
    plate(-2.0, SY + 0.3, -2.7, 0.6, 0.7, "Gold", depth=0.15),
    block(0, SY + 0.8, 4.4, 7.0, 7.0, 3.8, "Pack"),  # a navy backpack...
    block(0, SY - 1.6, 6.5, 5.0, 2.6, 0.8, "PackDark"),  # ...a front pocket
]
body += both(
    block(1.9, SY + 3.4, -2.3, 2.6, 1.2, 0.6, "Shirt", rot=(0, 0, 25)),  # the collar
    block(3.75, SY + 1.0, -2.55, 0.9, 6.6, 0.5, "Strap"),  # backpack straps over the shoulders
    block(3.75, SY + 4.4, 0.6, 0.9, 0.7, 6.8, "Strap"),
)

head = [
    block(0, HY, 0.2, 7.8, 7.6, 7.0, "Fur"),  # a round monkey head...
    block(0, HY + 4.0, 0.4, 6.2, 1.0, 5.6, "Fur"),
    block(0, HY - 0.8, -3.35, 6.4, 6.2, 0.4, "Face"),  # ...a tan face
    block(0, HY - 2.0, -3.9, 4.8, 2.8, 1.2, "Face"),  # ...a muzzle
    block(0, HY - 2.0, -4.6, 4.0, 1.6, 0.3, "Mouth"),  # a huge toothy smile
    plate(0, HY - 1.85, -4.85, 3.4, 0.9, "Teeth", depth=0.2),
    block(0, HY - 0.2, -4.2, 1.4, 0.9, 1.0, "Nose"),
    plate(0, HY + 2.2, -3.65, 4.6, 0.3, "Wrinkle", depth=0.15),  # (a wrinkled brow)
]
head += both(
    plate(1.6, HY + 1.0, -3.65, 1.6, 1.1, "White", depth=0.15),  # eyes...
    plate(1.6, HY + 1.0, -3.85, 0.9, 0.9, "Eye", depth=0.15),
    plate(1.4, HY + 1.2, -4.05, 0.3, 0.3, "White", depth=0.1),
    block(2.4, HY - 2.5, -4.15, 0.6, 0.5, 0.6, "Face", rot=(0, 0, 30)),  # ...smile corners
    solid("Cylinder", 4.7, HY + 0.6, 0.6, 1.0, 3.6, 3.6, "Fur", rot=(0, 70, 0)),  # big round ears
    solid("Cylinder", 4.85, HY + 0.6, 0.15, 0.4, 2.4, 2.4, "Face", rot=(0, 70, 0)),
)

arms = []
for s in (-1, 1):
    arms += [
        block(s * 5.2, SY + 2.4, 0.2, 2.2, 3.2, 3.0, "Shirt"),  # short white sleeves...
        block(s * 5.4, SY - 1.6, 0.0, 1.6, 5.2, 1.8, "Fur"),  # ...long monkey arms
        block(s * 5.45, SY - 4.8, -0.2, 2.0, 1.8, 2.4, "Face"),  # ...hands
    ]

legs = []
for s in (-1, 1):
    x = s * 2.0
    legs += [
        block(x, 10.0, 0.2, 3.8, 3.2, 4.6, "Red"),  # red shorts...
        block(x, 5.8, 0.2, 1.8, 5.0, 2.0, "Fur"),  # ...monkey legs...
        block(x, 2.4, 0.2, 2.0, 2.0, 2.2, "White"),  # ...white socks...
        block(x, 0.7, -0.5, 2.4, 1.4, 3.8, "Shoe"),  # ...black shoes
    ]

ART = {
    "Comment": "Dul Dul Dul: a grinning monkey with big round ears in an Indonesian school uniform, a white shirt with a red tie, a flag patch and a school badge, a navy backpack, red shorts, white socks, black shoes.",
    "VoxelSize": 0.2,
    "Palette": {
        "Fur": (132, 92, 60),
        "Face": (214, 168, 128),
        "Wrinkle": (176, 128, 92),
        "Mouth": (90, 40, 36),
        "Teeth": (250, 248, 236),
        "Nose": (150, 98, 76),
        "White": (250, 250, 248),
        "Eye": (70, 40, 24),
        "Shirt": (246, 246, 242),
        "Tie": (206, 40, 44),
        "Red": (214, 42, 46),
        "Patch": (250, 250, 250),
        "Pocket": (232, 232, 228),
        "Badge": (60, 40, 40),
        "Gold": (240, 196, 60),
        "Pack": (36, 50, 92),
        "PackDark": (26, 36, 70),
        "Strap": (30, 40, 76),
        "Shoe": (24, 24, 28),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
