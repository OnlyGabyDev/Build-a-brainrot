# Carrotini Brainini (art v2, blocks): a brainy little car, after the original meme image
# (by @brazilianaimemes): a round orange car (dark windows, round headlights, a silver
# bumper, black wheels) with a big pink-orange brain bulging out of its roof and a happy
# face on its front (big eyes, a wide grin), walking on two bare legs. The meme shows no
# arms: ours are its side mirrors on little stalks. No badges or plates.
import math

from voxel_art import block, both, plate, rod, solid

CY = 9.0  # the car's middle
body = [
    block(0, CY - 0.6, 0.6, 8.6, 3.8, 11.0, "Car"),  # a round orange car...
    solid("Ball", 0, CY + 1.6, 0.6, 9.6, 9.6, 9.6, "Car"),  # (its rounded cabin)
    block(0, CY - 2.6, -5.6, 9.8, 1.0, 1.0, "Silver"),  # ...a silver bumper...
    block(0, CY - 2.6, 6.8, 9.8, 1.0, 1.0, "Silver"),
]
for s in (-1, 1):
    body += [
        solid("Ball", s * 3.4, CY - 0.6, -3.0, 5.0, 5.0, 5.0, "Car"),  # ...round fenders...
        solid("Ball", s * 3.4, CY - 0.6, 4.2, 5.0, 5.0, 5.0, "Car"),
        solid("Cylinder", s * 4.5, CY - 2.6, -3.0, 1.6, 4.0, 4.0, "Tire"),  # ...black wheels...
        solid("Cylinder", s * 4.5, CY - 2.6, 4.2, 1.6, 4.0, 4.0, "Tire"),
        solid("Cylinder", s * 5.0, CY - 2.6, -3.0, 0.8, 2.0, 2.0, "Silver"),
        solid("Cylinder", s * 5.0, CY - 2.6, 4.2, 0.8, 2.0, 2.0, "Silver"),
        block(s * 4.75, CY + 2.6, 0.8, 0.3, 2.4, 5.6, "Window"),  # ...dark side windows
        solid("Cylinder", s * 3.2, CY + 0.2, -5.4, 0.6, 2.0, 2.0, "Light", rot=(0, 90, 0)),  # ...round headlights
    ]
body.append(block(0, CY + 3.4, -2.9, 6.4, 2.2, 0.3, "Window"))  # a windshield

HY = CY + 6.6  # the brain on its roof, and its face
head = []
for x, y, z, d in ((0, 0.0, 0.8, 7.2), (-2.2, 0.6, -1.4, 4.6), (2.2, 0.6, -1.4, 4.6), (-2.4, 0.4, 2.6, 4.6), (2.4, 0.4, 2.6, 4.6), (0, 1.8, -0.4, 4.8), (0, 1.6, 2.6, 4.4)):
    head.append(solid("Ball", x, HY + y, z, d, d, d, "Brain"))  # a big brain bulging out...
for k in range(7):  # ...its folds
    head.append(block(0, HY + 2.4 - k * 0.1, -2.4 + k * 1.0, 0.3, 0.4, 0.8, "BrainDark"))
    head += both(block(1.8, HY + 2.0, -2.0 + k * 0.9, 1.6, 0.3, 0.3, "BrainDark", rot=(0, 0, 20 * (1 if k % 2 else -1))))
FZ = 0.6 - 6.2  # its face, on the front of the hood
head += [
    block(0, CY - 0.8, FZ + 0.2, 5.0, 1.6, 0.6, "Mouth"),  # a wide grin...
    block(0, CY - 0.45, FZ - 0.15, 4.4, 0.6, 0.3, "White"),
    block(0, CY + 1.0, FZ + 0.1, 1.2, 1.2, 0.8, "CarDark"),  # ...a little nose
]
head += both(
    solid("Ball", 1.7, CY + 2.4, FZ + 0.4, 2.4, 2.4, 2.4, "White"),  # big eyes...
    plate(1.6, CY + 2.3, FZ - 0.85, 1.2, 1.2, "Iris", depth=0.2),
    plate(1.6, CY + 2.3, FZ - 1.0, 0.6, 0.6, "Dark", depth=0.15),
    block(1.8, CY + 3.8, FZ + 0.4, 2.2, 0.5, 0.6, "CarDark", rot=(0, 0, -12)),  # ...happy brows
    block(2.8, CY - 0.4, FZ + 0.2, 0.8, 0.6, 0.6, "Mouth", rot=(0, 0, 35)),
)

arms = []
for s in (-1, 1):  # (ours) side mirrors on little stalks
    arms += [
        rod((s * 4.6, CY + 1.6, -2.4), (s * 6.0, CY + 2.4, -2.6), 0.5, "CarDark"),
        block(s * 6.4, CY + 2.6, -2.6, 1.0, 1.2, 1.6, "Car"),
        plate(s * 6.4, CY + 2.6, -3.45, 0.7, 0.9, "Silver", depth=0.15),
    ]

legs = []
for s in (-1, 1):  # two bare legs
    x = s * 2.2
    legs += [
        rod((x, CY - 1.6, 0.8), (x, 3.0, 0.8), 2.0, "Skin"),
        rod((x, 3.0, 0.8), (x, 1.2, 0.4), 1.8, "Skin"),
        block(x, 0.6, -0.6, 2.2, 1.2, 3.8, "Skin"),
    ]

ART = {
    "Comment": "Carrotini Brainini: a round orange car with a big brain bulging out of its roof and a happy face on its front, round headlights, black wheels, walking on two bare legs.",
    "VoxelSize": 0.2,
    "Palette": {
        "Car": (240, 130, 50),
        "CarDark": (196, 96, 34),
        "Window": (50, 70, 90),
        "Silver": (210, 214, 220),
        "Tire": (30, 30, 34),
        "Light": (250, 240, 170),
        "Brain": (240, 160, 150),
        "BrainDark": (206, 116, 110),
        "Mouth": (90, 30, 30),
        "White": (250, 250, 248),
        "Iris": (70, 120, 60),
        "Dark": (20, 18, 16),
        "Skin": (226, 170, 132),
    },
    "Materials": {"Silver": "Metal"},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
