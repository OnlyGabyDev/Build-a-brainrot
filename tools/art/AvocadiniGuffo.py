# Avocadini Guffo (art v2, blocks): an avocado owl, after the original meme image (by
# @alexey_pigeon): an owl whose body is half an avocado (a dark green skin round pale
# green flesh, a big glossy brown pit in its belly), a green feathered owl head with ear
# tufts, a tan face disc with rings round huge green eyes and a small hooked beak; its
# "arms" are wings of layered green leaf-feathers; short orange legs on clawed feet.
from voxel_art import block, both, plate, rod, solid, wedge

FZ = -7.0  # the cut face's front

body = [
    solid("Ball", 0, 9.0, 0, 13.0, 13.0, 13.0, "Skin"),  # the avocado: a round bottom...
    solid("Ball", 0, 14.5, 0.4, 10.0, 10.0, 10.0, "Skin"),  # ...narrowing to the top
    solid("Cylinder", 0, 9.0, FZ + 1.5, 3.0, 12.4, 12.4, "SkinDark", rot=(0, 90, 0)),  # a dark rim...
    solid("Cylinder", 0, 14.5, FZ + 1.5, 3.0, 9.4, 9.4, "SkinDark", rot=(0, 90, 0)),
    solid("Cylinder", 0, 9.0, FZ + 1.15, 3.0, 11.0, 11.0, "Flesh", rot=(0, 90, 0)),  # ...round pale flesh...
    solid("Cylinder", 0, 14.5, FZ + 1.15, 3.0, 8.0, 8.0, "Flesh", rot=(0, 90, 0)),
    solid("Cylinder", 0, 8.6, FZ + 0.8, 3.0, 8.4, 8.4, "FleshIn", rot=(0, 90, 0)),  # (yellower inside)
    solid("Ball", 0, 8.4, FZ + 0.4, 6.4, 6.4, 6.4, "Pit"),  # ...and a big glossy pit
    plate(-1.2, 9.8, FZ - 2.85, 1.0, 1.4, "PitShine", depth=0.3),
]

HY = 21.0  # the head
head = [
    block(0, HY, 0.4, 9.6, 7.6, 8.4, "Feather"),  # a green feathered head...
    block(0, HY + 3.6, 0.6, 7.6, 1.2, 7.2, "Feather"),
    wedge(0, HY + 1.6, -3.95, 3.0, 2.0, 0.6, "FeatherDark", rot=(0, 0, 180)),  # (a V of dark feathers)
    block(0, HY - 0.4, -3.95, 8.4, 6.0, 0.4, "Face"),  # ...a tan face disc
    wedge(0, HY - 1.3, -4.9, 1.2, 1.8, 1.4, "Beak", rot=(180, 0, 0)),  # a small hooked beak
]
for s in (-1, 1):
    x = s * 2.1
    head += [
        solid("Cylinder", x, HY - 0.1, -4.25, 0.4, 4.2, 4.2, "Ring", rot=(0, 90, 0)),  # rings round...
        solid("Cylinder", x, HY - 0.1, -4.55, 0.4, 3.4, 3.4, "RingDark", rot=(0, 90, 0)),
        solid("Cylinder", x, HY - 0.1, -4.85, 0.4, 2.8, 2.8, "Iris", rot=(0, 90, 0)),  # ...huge green eyes
        solid("Cylinder", x, HY - 0.1, -5.15, 0.4, 1.5, 1.5, "Pupil", rot=(0, 90, 0)),
        plate(x - s * 0.4, HY + 0.5, -5.45, 0.5, 0.5, "Glint", depth=0.2),
        block(s * 3.6, HY + 5.0, 0.0, 1.8, 3.4, 2.0, "Feather", rot=(0, 0, -s * 22)),  # ear tufts
        block(s * 4.4, HY + 6.0, 0.0, 1.0, 1.6, 1.4, "FeatherDark", rot=(0, 0, -s * 30)),
    ]

arms = []
for s in (-1, 1):  # wings of layered green leaf-feathers
    for k in range(4):
        arms += [
            block(s * (6.6 + k * 0.15), 12.6 - k * 1.7, -1.6 + k * 1.3, 1.4, 8.6 - k * 0.6, 3.2, "Leaf" if k % 2 == 0 else "LeafLight", rot=(0, 0, s * 14)),
            block(s * (7.35 + k * 0.15), 12.0 - k * 1.7, -1.6 + k * 1.3, 0.2, 6.4 - k * 0.6, 0.4, "Rib", rot=(0, 0, s * 14)),
        ]
    arms.append(block(s * 6.0, 15.4, 0.4, 2.4, 3.0, 6.0, "Leaf"))  # the shoulder

legs = []
for s in (-1, 1):  # short orange legs on clawed feet
    x = s * 2.4
    legs += [
        block(x, 2.4, 0.4, 1.4, 3.2, 1.4, "Foot"),
        block(x, 0.5, -0.8, 1.2, 1.0, 3.4, "Foot"),  # three toes
        block(x - 1.0, 0.5, -0.4, 1.0, 1.0, 2.6, "Foot", rot=(0, -25, 0)),
        block(x + 1.0, 0.5, -0.4, 1.0, 1.0, 2.6, "Foot", rot=(0, 25, 0)),
        block(x, 0.4, -2.7, 0.8, 0.8, 0.6, "Claw"),
    ]

ART = {
    "Comment": "Avocadini Guffo: an owl whose body is half an avocado with a big brown pit, a green feathered owl head with ear tufts, a tan face with huge green eyes, wings of green leaf-feathers, short orange legs.",
    "VoxelSize": 0.2,
    "Palette": {
        "Skin": (52, 92, 40),
        "SkinDark": (36, 66, 30),
        "Flesh": (176, 214, 92),
        "FleshIn": (214, 226, 112),
        "Pit": (122, 64, 34),
        "PitShine": (196, 130, 90),
        "Feather": (92, 150, 60),
        "FeatherDark": (54, 98, 40),
        "Face": (214, 186, 140),
        "Ring": (238, 220, 180),
        "RingDark": (150, 112, 70),
        "Iris": (60, 170, 70),
        "Pupil": (16, 20, 16),
        "Glint": (250, 250, 250),
        "Beak": (110, 84, 60),
        "Leaf": (96, 156, 56),
        "LeafLight": (140, 190, 80),
        "Rib": (60, 104, 40),
        "Foot": (232, 140, 60),
        "Claw": (60, 44, 34),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
