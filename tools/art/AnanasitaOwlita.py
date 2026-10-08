# Ananasita Owlita (art v2, blocks): a pineapple owl, after the original meme image (by
# @alexey_pigeon): an owl whose body is a golden pineapple (rows of brown eyes), a crown of
# long green pineapple leaves on its head, big round orange feather discs round huge dark
# eyes, a small dark hooked beak; wings of green leaves; short dark legs with claws.
import math

from voxel_art import block, both, plate, rod, solid, wedge

CY = 9.6  # the pineapple's middle
R, H = 5.6, 9.0

body = [
    solid("Cylinder", 0, CY, 0.6, H, 2 * R, 2 * R, "Pine", rot=(0, 0, 90)),  # a golden pineapple...
    solid("Ball", 0, CY - H / 2 + 0.8, 0.6, 2 * R - 0.6, 2 * R - 0.6, 2 * R - 0.6, "Pine"),
]
for row in range(5):  # ...rows of brown eyes
    y = CY - 3.6 + row * 1.7
    for k in range(10):
        a = math.radians(k * 36 + (18 if row % 2 else 0))
        body.append(block(math.sin(a) * (R + 0.05), y, 0.6 - math.cos(a) * (R + 0.05), 1.0, 1.0, 0.3, "Eye", rot=(0, -math.degrees(a), 0)))

HY = CY + H / 2 + 3.0  # the head
head = [
    block(0, HY, 0.6, 9.0, 6.0, 8.0, "Pine"),  # a pineapple head...
    block(0, HY - 3.4, 0.6, 8.0, 1.0, 7.0, "PineDark"),
]
for s in (-1, 1):
    x = s * 2.2
    head += [
        solid("Cylinder", x, HY - 0.2, 0.6 - 4.1, 0.6, 4.6, 4.6, "Feather", rot=(0, 90, 0)),  # big orange feather discs...
        solid("Cylinder", x, HY - 0.2, 0.6 - 4.4, 0.4, 3.4, 3.4, "FeatherLight", rot=(0, 90, 0)),
        solid("Cylinder", x, HY - 0.2, 0.6 - 4.7, 0.4, 2.4, 2.4, "EyeDark", rot=(0, 90, 0)),  # ...round huge dark eyes
        plate(x - s * 0.4, HY + 0.4, 0.6 - 5.0, 0.6, 0.6, "Glint", depth=0.2),
    ]
head.append(wedge(0, HY - 1.8, 0.6 - 4.7, 1.2, 2.0, 1.4, "Beak", rot=(180, 0, 0)))  # a small dark beak
for k in range(9):  # a crown of long green leaves
    a = math.radians(k * 40)
    tip = (math.sin(a) * 3.8, HY + 9.0 - (k % 2) * 1.6, 0.6 + math.cos(a) * 3.0)
    head.append(rod((0, HY + 2.8, 0.6), tip, 1.2, "Leaf" if k % 2 else "LeafDark"))
head.append(rod((0, HY + 2.8, 0.6), (0, HY + 9.6, 0.4), 1.2, "Leaf"))

arms = []
for s in (-1, 1):  # wings of green leaves
    for k in range(4):
        arms.append(block(s * (6.0 + k * 0.2), CY + 1.6 - k * 1.6, -1.2 + k * 1.2, 1.2, 7.4 - k * 0.8, 2.6, "Leaf" if k % 2 == 0 else "LeafDark", rot=(0, 0, s * 18)))
    arms.append(block(s * 5.4, CY + 3.6, 0.6, 2.2, 3.0, 5.0, "LeafDark"))

legs = []
for s in (-1, 1):  # short dark legs with claws
    x = s * 2.4
    legs += [
        block(x, 2.0, 0.6, 1.2, 3.0, 1.2, "Leg"),
        block(x, 0.5, -0.6, 1.0, 1.0, 3.0, "Leg"),
        block(x - 1.0, 0.5, -0.2, 0.9, 1.0, 2.2, "Leg", rot=(0, -25, 0)),
        block(x + 1.0, 0.5, -0.2, 0.9, 1.0, 2.2, "Leg", rot=(0, 25, 0)),
    ]

ART = {
    "Comment": "Ananasita Owlita: an owl whose body is a golden pineapple, a crown of long green leaves on its head, big orange feather discs round huge dark eyes, a small dark beak, wings of green leaves.",
    "VoxelSize": 0.2,
    "Palette": {
        "Pine": (228, 162, 48),
        "PineDark": (190, 126, 36),
        "Eye": (150, 92, 30),
        "Feather": (240, 140, 30),
        "FeatherLight": (250, 190, 60),
        "EyeDark": (30, 22, 18),
        "Glint": (250, 250, 250),
        "Beak": (50, 44, 44),
        "Leaf": (100, 174, 64),
        "LeafDark": (58, 126, 50),
        "Leg": (70, 56, 46),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
