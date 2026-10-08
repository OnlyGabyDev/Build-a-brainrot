# Ganganzelli Trulala (art v2, blocks): a muscly orange giraffe, after the original meme
# image (by @alexey_pigeon, 2025-03-08): a giraffe's spotted neck and head (a curly black
# moustache, a brown fedora with a dark band) on a body that is half a big orange, its cut
# face forward (rind, white pith, juicy segments); huge muscly orange-peel arms with
# wristbands; muscly orange legs in brown sandals; a thin giraffe tail with a black tuft.
from voxel_art import block, both, plate, rod, solid

CY, CZ = 14.0, 1.0  # the orange's middle
R = 6.6
FZ = CZ - 5.6  # the cut face


def disc(z, d, color):
    return solid("Cylinder", 0, CY, z, 2.0, d, d, color, rot=(0, 90, 0))


body = [
    solid("Ball", 0, CY, CZ, 2 * R, 2 * R, 2 * R, "Peel"),  # half a big orange...
    disc(FZ, 13.8, "Peel"),  # ...its cut face forward: the rind...
    disc(FZ - 0.35, 12.8, "Pith"),  # ...white pith...
    disc(FZ - 0.7, 11.8, "Flesh"),  # ...juicy segments
    solid("Cylinder", 0, CY, FZ - 1.75, 0.4, 1.6, 1.6, "Pith", rot=(0, 90, 0)),
]
for k in range(6):
    body.append(block(0, CY, FZ - 1.75, 0.35, 11.4, 0.4, "Pith", rot=(0, 0, k * 30)))
tail = [(0, CY - 2.0, CZ + 6.2), (0, CY - 6.0, CZ + 8.6), (0, CY - 9.6, CZ + 9.4)]  # a thin tail...
body += [rod(tail[k], tail[k + 1], 0.8, "Giraffe") for k in range(2)]
body.append(block(0, CY - 10.6, CZ + 9.5, 1.4, 2.4, 1.4, "Dark"))  # ...a black tuft

HY, HZ = 26.8, -1.6  # the head
head = [
    rod((0, CY + 5.0, CZ + 0.6), (0, HY - 0.6, HZ + 1.8), 3.0, "Giraffe"),  # a spotted neck...
    block(0, HY, HZ, 3.8, 3.4, 4.0, "Giraffe"),  # ...a giraffe head...
    block(0, HY - 0.6, HZ - 3.0, 3.0, 2.4, 2.6, "Giraffe"),  # ...a long snout
    block(0, HY - 1.3, HZ - 3.2, 2.8, 1.0, 2.4, "Muzzle"),
    plate(0, HY - 0.8, HZ - 4.45, 2.8, 0.3, "Muzzle", depth=0.2),
]
for y, z, s in ((CY + 7.0, 1.6, 1.0), (CY + 9.4, 0.4, 0.8), (HY - 3.4, -0.2, 0.9), (HY + 0.6, HZ + 0.4, 0.7)):  # brown spots
    head += both(block(1.55 if y < HY - 2 else 1.95, y, z, 0.3, 1.2 * s + 0.4, 1.4 * s, "Spot"))
head += [block(0, CY + 8.2, 2.6, 1.4, 1.2, 0.3, "Spot"), block(0, CY + 10.6, 1.4, 1.2, 1.0, 0.3, "Spot")]
head += both(
    plate(1.2, HY + 1.1, HZ - 2.05, 0.9, 0.9, "Eye", depth=0.2),  # eyes
    plate(1.1, HY + 1.3, HZ - 2.2, 0.3, 0.3, "Glint", depth=0.1),
    plate(0.6, HY - 0.3, HZ - 4.45, 0.4, 0.4, "Dark", depth=0.1),  # nostrils
    block(2.4, HY + 1.0, HZ + 1.0, 1.6, 0.7, 1.0, "Giraffe", rot=(0, 0, -20)),  # ears
    block(0.9, HY - 2.1, HZ - 4.55, 1.6, 0.5, 0.5, "Dark"),  # a curly black moustache...
    block(2.0, HY - 1.6, HZ - 4.5, 0.6, 0.5, 0.5, "Dark", rot=(0, 0, 40)),
    block(2.3, HY - 1.05, HZ - 4.45, 0.5, 0.7, 0.5, "Dark"),
    block(2.0, HY - 0.7, HZ - 4.45, 0.5, 0.4, 0.5, "Dark"),
)
HAT = HY + 2.3
head += [
    solid("Cylinder", 0, HAT, HZ + 0.2, 0.5, 8.0, 8.0, "Hat", rot=(0, 0, 90)),  # a brown fedora: the brim...
    block(0, HAT + 1.3, HZ + 0.2, 4.6, 2.2, 5.0, "Hat"),  # ...the crown...
    block(0, HAT + 2.3, HZ + 0.2, 1.0, 0.4, 3.6, "HatDark"),  # ...pinched...
    block(0, HAT + 0.6, HZ + 0.2, 4.8, 0.7, 5.2, "HatDark"),  # ...a dark band
]

arms = []
for s in (-1, 1):  # huge muscly orange-peel arms
    x = s * 7.0
    arms += [
        solid("Ball", s * 6.2, CY + 4.4, CZ, 5.6, 5.6, 5.6, "Peel"),  # a round shoulder...
        solid("Ball", s * 7.8, CY + 0.4, CZ - 0.4, 5.0, 5.0, 5.0, "Peel"),  # ...a bulging bicep...
        rod((s * 7.8, CY - 1.6, CZ - 0.4), (s * 8.0, CY - 6.2, CZ - 0.8), 3.0, "Peel"),  # ...a forearm...
        block(s * 8.0, CY - 7.0, CZ - 0.8, 3.4, 0.8, 3.4, "Band"),  # ...a wristband...
        block(s * 8.0, CY - 8.6, CZ - 0.9, 3.0, 2.6, 3.0, "Peel"),  # ...a fist
    ]

legs = []
for s in (-1, 1):  # muscly orange legs in brown sandals
    x = s * 2.8
    legs += [
        solid("Ball", x, 8.2, CZ + 0.4, 4.6, 4.6, 4.6, "Peel"),  # a thigh...
        block(x, 4.2, CZ + 0.4, 2.6, 5.4, 2.6, "Peel"),  # ...a shin...
        block(x, 1.3, CZ - 0.6, 2.8, 1.2, 4.6, "Peel"),  # ...a foot...
        block(x, 0.35, CZ - 0.6, 3.2, 0.7, 5.2, "Sandal"),  # ...on a sandal
        block(x, 1.5, CZ - 1.6, 3.0, 0.5, 0.9, "Sandal"),
    ]

ART = {
    "Comment": "Ganganzelli Trulala: a giraffe's spotted neck and head with a curly moustache and a fedora on a body that is half a big orange (its cut face forward), huge muscly orange arms with wristbands, muscly legs in sandals, a thin tail with a tuft.",
    "VoxelSize": 0.2,
    "Palette": {
        "Peel": (244, 132, 28),
        "Pith": (252, 236, 200),
        "Flesh": (250, 160, 40),
        "Giraffe": (232, 186, 96),
        "Spot": (150, 86, 40),
        "Muzzle": (240, 212, 160),
        "Eye": (24, 18, 16),
        "Glint": (250, 250, 250),
        "Dark": (20, 18, 18),
        "Hat": (150, 92, 50),
        "HatDark": (70, 42, 26),
        "Band": (60, 50, 60),
        "Sandal": (110, 70, 40),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
