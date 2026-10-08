# Snooffi Zeffirulli (art v2, blocks): a pineapple hedgehog, after the original meme image
# (by @alexey_pigeon, 2025-03-12): a little hedgehog whose body is a round golden pineapple
# (rows of brown eyes, a spiky crown of green leaves along its back), a white pointed face
# with a pink nose, small black eyes and round pink ears; four short pink legs.
import math

from voxel_art import block, both, plate, rod, solid

CY, CZ = 8.6, 1.4  # the pineapple's middle
R = 6.0

body = [solid("Ball", 0, CY, CZ, 2 * R, 2 * R, 2 * R, "Pine")]  # a round golden pineapple...
for row, (dy, n) in enumerate(((-3.0, 10), (-1.0, 12), (1.0, 12), (3.0, 10))):  # ...rows of brown eyes
    y = CY + dy
    r = math.sqrt(R * R - dy * dy) + 0.05
    for k in range(n):
        a = math.radians(k * 360 / n + (15 if row % 2 else 0))
        if math.cos(a) > 0.8 and dy > -2:  # (not behind the face)
            continue
        body.append(block(math.sin(a) * r, y, CZ - math.cos(a) * r, 1.0, 1.0, 0.3, "Eye", rot=(0, -math.degrees(a), 0)))
for k in range(9):  # ...a spiky crown of green leaves along its back
    z = CZ - 3.0 + k * 0.9
    tilt = (k - 4) * 9
    for s in (-1, 0, 1):
        if s and k % 2:
            continue
        body.append(rod((s * 0.8, CY + R - 1.0, z), (s * 2.4, CY + R + 3.6 - abs(k - 4) * 0.35, z + math.sin(math.radians(tilt)) * 2.4), 1.0, "Leaf" if (k + s) % 2 else "LeafDark"))

HY, HZ = CY + 0.4, CZ - R - 1.4  # the head
head = [
    block(0, HY, HZ + 0.6, 5.4, 4.6, 4.0, "White"),  # a white pointed face...
    block(0, HY - 0.6, HZ - 2.0, 3.0, 2.6, 2.4, "White"),
    block(0, HY - 0.9, HZ - 3.6, 1.6, 1.4, 1.2, "White"),
    block(0, HY - 0.7, HZ - 4.35, 1.0, 0.8, 0.4, "Nose"),  # ...a pink nose
]
head += both(
    plate(1.4, HY + 0.6, HZ - 1.45, 0.8, 0.9, "Dark", depth=0.2),  # small black eyes
    plate(1.25, HY + 0.85, HZ - 1.6, 0.3, 0.3, "Glint", depth=0.1),
    solid("Cylinder", 2.6, HY + 2.4, HZ + 1.0, 0.6, 1.8, 1.8, "Ear", rot=(0, 70, 0)),  # round pink ears
)

arms = []
legs = []
for s in (-1, 1):  # four short pink legs
    arms += [block(s * 2.6, 1.6, CZ - 2.6, 1.4, 3.2, 1.6, "Pink"), block(s * 2.6, 0.4, CZ - 3.2, 1.6, 0.8, 2.4, "Pink")]
    legs += [block(s * 2.8, 1.6, CZ + 3.2, 1.4, 3.2, 1.6, "Pink"), block(s * 2.8, 0.4, CZ + 2.6, 1.6, 0.8, 2.4, "Pink")]

ART = {
    "Comment": "Snooffi Zeffirulli: a little hedgehog whose body is a round golden pineapple with a spiky crown of green leaves along its back, a white pointed face with a pink nose and round pink ears, short pink legs.",
    "VoxelSize": 0.2,
    "Palette": {
        "Pine": (230, 168, 50),
        "Eye": (150, 92, 30),
        "Leaf": (100, 174, 64),
        "LeafDark": (60, 126, 50),
        "White": (246, 242, 236),
        "Nose": (236, 130, 150),
        "Dark": (24, 20, 20),
        "Glint": (250, 250, 250),
        "Ear": (238, 160, 170),
        "Pink": (232, 170, 176),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
