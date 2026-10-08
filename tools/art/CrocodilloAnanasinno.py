# Crocodillo Ananasinno (art v2, blocks): a pineapple crocodile, after the original meme
# image (by @alexey_pigeon, 2025-03-12): a crocodile whose body is a long golden pineapple
# (rows of brown eyes, a crown of green leaves on its back), a long croc head with a toothy
# grin and eyes on top, a spiky tail, four short bent legs with claws (the front pair are
# its "arms").
import math

from voxel_art import block, both, plate, rod, solid, turned

CY, CZ = 6.6, 1.0  # the body's middle
R, L = 4.4, 10.0  # its radius and length

body = [
    solid("Cylinder", 0, CY, CZ, L, 2 * R, 2 * R, "Pine", rot=(0, 90, 0)),  # a long golden pineapple...
    solid("Ball", 0, CY, CZ - L / 2 + 0.6, 2 * R - 0.4, 2 * R - 0.4, 2 * R - 0.4, "Pine"),
    solid("Ball", 0, CY, CZ + L / 2 - 0.6, 2 * R - 0.4, 2 * R - 0.4, 2 * R - 0.4, "Pine"),
]
for row in range(6):  # ...rows of brown eyes round it
    z = CZ - 4.2 + row * 1.7
    for k in range(9):
        a = math.radians(k * 40 + (20 if row % 2 else 0))
        if math.cos(a) < -0.6:  # (none underneath)
            continue
        body.append(turned(math.sin(a) * (R + 0.05), CY + math.cos(a) * (R + 0.05), z, 1.0, 1.0, 0.3, "Eye", (0, 0, 1), (math.cos(a), -math.sin(a), 0)))
for k in range(7):  # a crown of green leaves on its back
    a = math.radians(-70 + k * 23)
    body.append(rod((0, CY + R - 0.6, CZ - 0.6), (math.sin(a) * 3.4, CY + R + 4.6 - abs(k - 3) * 0.5, CZ - 0.6 + math.cos(a) * 1.4), 1.2, "Leaf" if k % 2 else "LeafDark"))
T = [(0, CY, CZ + L / 2), (0, CY - 1.0, CZ + 9.0), (0, CY - 2.6, CZ + 12.4), (0, CY - 4.0, CZ + 15.0)]
for k in range(3):  # a spiky tail
    body.append(rod(T[k], T[k + 1], 3.2 - k * 0.8, "Croc"))
    body.append(block(0, (T[k][1] + T[k + 1][1]) / 2 + 1.6 - k * 0.4, (T[k][2] + T[k + 1][2]) / 2, 0.6, 1.4, 1.0, "Spike", rot=(-20, 0, 0)))

HY, HZ = CY + 0.8, CZ - L / 2 - 2.4  # the head
head = [
    block(0, HY, HZ, 5.0, 3.6, 4.0, "Croc"),  # a croc head...
    block(0, HY - 0.6, HZ - 4.6, 3.8, 1.6, 5.6, "Croc"),  # ...a long snout...
    block(0, HY - 1.6, HZ - 4.0, 3.6, 0.8, 6.0, "CrocPale"),  # ...a pale jaw
    block(0, HY + 0.4, HZ - 7.0, 2.4, 0.6, 1.0, "CrocDark"),
]
for k in range(6):  # a toothy grin
    head += both(block(1.75, HY - 1.3, HZ - 1.8 - k * 0.9, 0.3, 0.5, 0.3, "Tooth"))
head += both(
    block(1.4, HY + 2.0, HZ + 0.2, 1.4, 1.0, 1.4, "Croc"),  # eyes on top
    plate(1.4, HY + 2.1, HZ - 0.55, 1.0, 0.7, "Gold", depth=0.2),
    plate(1.4, HY + 2.1, HZ - 0.7, 0.3, 0.6, "Dark", depth=0.15),
)


def leg(x, z):
    s = 1 if x > 0 else -1
    return [
        rod((x, CY - 1.0, z), (x + s * 1.6, 2.4, z), 2.0, "Croc"),
        rod((x + s * 1.6, 2.4, z), (x + s * 1.8, 0.6, z - 0.6), 1.8, "Croc"),
        block(x + s * 1.8, 0.5, z - 1.4, 2.4, 1.0, 2.6, "Croc"),
    ] + [block(x + s * 1.8 + dx, 0.4, z - 2.85, 0.4, 0.6, 0.5, "Claw") for dx in (-0.8, 0.0, 0.8)]


arms = leg(-3.2, CZ - 3.2) + leg(3.2, CZ - 3.2)
legs = leg(-3.2, CZ + 3.4) + leg(3.2, CZ + 3.4)

ART = {
    "Comment": "Crocodillo Ananasinno: a crocodile whose body is a long golden pineapple with a crown of green leaves on its back, a long toothy croc head, a spiky tail, four short bent legs.",
    "VoxelSize": 0.2,
    "Palette": {
        "Pine": (226, 160, 48),
        "Eye": (150, 92, 30),
        "Leaf": (100, 174, 64),
        "LeafDark": (58, 126, 50),
        "Croc": (128, 140, 70),
        "CrocDark": (96, 106, 52),
        "CrocPale": (210, 200, 150),
        "Spike": (200, 150, 50),
        "Tooth": (250, 248, 240),
        "Gold": (240, 200, 60),
        "Dark": (24, 20, 20),
        "Claw": (70, 56, 40),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
