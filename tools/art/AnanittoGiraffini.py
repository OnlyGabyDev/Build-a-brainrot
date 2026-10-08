# Ananitto Giraffini (art v2, blocks): a pineapple giraffe, after the original meme image
# (by @alexey_pigeon, 2025-03-11): a giraffe whose body is a big golden pineapple (rows of
# brown eyes on it, a crown of long green leaves on its back), a spotted giraffe neck and
# head (little horns, ears), four long spotted legs with dark hooves (the front pair are its
# "arms"), a thin tail with a black tuft.
import math

from voxel_art import block, both, plate, rod, solid

CY, CZ = 12.0, 1.4  # the pineapple's middle
R, H = 4.6, 8.4  # its radius and height

body = [
    solid("Cylinder", 0, CY, CZ, H, 2 * R, 2 * R, "Pine", rot=(0, 0, 90)),  # a golden pineapple...
    solid("Ball", 0, CY + H / 2 - 0.6, CZ, 2 * R - 1.0, 2 * R - 1.0, 2 * R - 1.0, "Pine"),
    solid("Ball", 0, CY - H / 2 + 0.6, CZ, 2 * R - 1.0, 2 * R - 1.0, 2 * R - 1.0, "Pine"),
]
for row in range(5):  # ...rows of brown eyes
    y = CY - 3.2 + row * 1.6
    for k in range(9):
        a = math.radians(k * 40 + (20 if row % 2 else 0))
        body.append(block(math.sin(a) * (R + 0.05), y, CZ - math.cos(a) * (R + 0.05), 1.0, 1.0, 0.3, "Eye", rot=(0, -math.degrees(a), 0)))
for k in range(7):  # a crown of long green leaves on its back
    a = math.radians(k * 360 / 7)
    tip = (math.sin(a) * 3.0, CY + H / 2 + 6.2, CZ + 1.0 + math.cos(a) * 3.0)
    body.append(rod((0, CY + H / 2 + 0.6, CZ + 1.0), tip, 1.2, "Leaf" if k % 2 else "LeafDark"))
for k in range(4):
    a = math.radians(k * 90 + 45)
    body.append(rod((0, CY + H / 2 + 0.6, CZ + 1.0), (math.sin(a) * 1.2, CY + H / 2 + 7.6, CZ + 1.0 + math.cos(a) * 1.2), 1.0, "Leaf"))
body += [  # a thin tail with a black tuft
    rod((0, CY - 1.0, CZ + R - 0.2), (0, CY - 6.0, CZ + R + 1.6), 0.7, "Giraffe"),
    block(0, CY - 7.0, CZ + R + 1.8, 1.2, 2.2, 1.2, "Dark"),
]

HY, HZ = CY + 14.0, CZ - 6.0  # the head
head = [
    rod((0, CY + 2.0, CZ - R + 1.4), (0, HY - 1.2, HZ + 1.2), 2.8, "Giraffe"),  # a spotted neck...
    block(0, HY, HZ, 3.6, 3.4, 4.0, "Giraffe"),  # ...a giraffe head...
    block(0, HY - 0.6, HZ - 2.8, 3.0, 2.4, 2.4, "Giraffe"),  # ...a long snout
    block(0, HY - 1.3, HZ - 2.9, 2.8, 1.0, 2.4, "Muzzle"),
    plate(0, HY - 0.9, HZ - 4.05, 1.8, 0.3, "Dark", depth=0.15),
]
for t in (0.25, 0.5, 0.75):  # brown spots down its neck
    p = [(CY + 2.0) + (HY - 1.2 - CY - 2.0) * t, (CZ - R + 1.4) + (HZ + 1.2 - CZ + R - 1.4) * t]
    head += both(block(1.45, p[0], p[1], 0.3, 1.2, 1.2, "Spot"))
    head.append(block(0, p[0] - 0.6, p[1] + 1.45, 1.2, 1.0, 0.3, "Spot"))
head += both(
    plate(1.2, HY + 0.6, HZ - 2.05, 0.9, 0.9, "Pupil", depth=0.2),  # eyes
    plate(1.05, HY + 0.8, HZ - 2.25, 0.3, 0.3, "Glint", depth=0.1),
    rod((0.8, HY + 1.6, HZ + 0.4), (1.0, HY + 3.2, HZ + 0.6), 0.6, "Giraffe"),  # little horns
    block(1.0, HY + 3.4, HZ + 0.6, 0.9, 0.9, 0.9, "Dark"),
    block(2.3, HY + 1.0, HZ + 0.8, 1.6, 0.6, 0.9, "Giraffe", rot=(0, 0, -20)),  # ears
    block(1.85, HY - 0.2, HZ + 0.6, 0.3, 1.0, 1.2, "Spot"),
)


def leg(x, z):
    return [
        block(x, 4.6, z, 1.6, 9.2, 1.6, "Giraffe"),  # a long spotted leg...
        block(x, 6.2, z - 0.85, 1.0, 1.0, 0.3, "Spot"),
        block(x + (0.85 if x > 0 else -0.85), 3.6, z, 0.3, 1.0, 1.0, "Spot"),
        block(x, 0.6, z, 1.9, 1.2, 1.9, "Dark"),  # ...a dark hoof
    ]


arms = leg(-2.4, CZ - 2.8) + leg(2.4, CZ - 2.8)
legs = leg(-2.4, CZ + 3.0) + leg(2.4, CZ + 3.0)

ART = {
    "Comment": "Ananitto Giraffini: a giraffe whose body is a big golden pineapple with a crown of long green leaves on its back, a spotted neck and head with little horns, long spotted legs with dark hooves, a thin tail.",
    "VoxelSize": 0.2,
    "Palette": {
        "Pine": (226, 164, 48),
        "Eye": (150, 92, 30),
        "Leaf": (96, 170, 64),
        "LeafDark": (58, 124, 50),
        "Giraffe": (232, 184, 96),
        "Spot": (150, 90, 44),
        "Muzzle": (240, 214, 170),
        "Dark": (50, 36, 30),
        "Pupil": (20, 16, 14),
        "Glint": (250, 250, 250),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
