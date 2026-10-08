# Avocadini Antilopini (art v2, blocks): an avocado antelope, after the original meme image
# (by @patataposseduta): a slim antelope whose body is a dark green avocado, cut open on its
# side (pale green flesh round a big brown pit), a green head and neck with a pale muzzle,
# long ears and two big ridged horns curling back; four thin green legs with dark hooves (the
# front pair are its "arms").
import math

from voxel_art import block, both, plate, rod, solid

CY, CZ = 12.0, 1.4  # the avocado's middle

body = [
    solid("Ball", 0, CY, CZ + 1.2, 10.0, 10.0, 10.0, "Skin"),  # a dark green avocado...
    solid("Ball", 0, CY + 0.6, CZ - 2.4, 8.0, 8.0, 8.0, "Skin"),
]
for s in (-1, 1):  # ...cut open on its sides: pale flesh round a big brown pit
    body += [
        solid("Cylinder", s * 4.3, CY, CZ + 1.2, 1.8, 7.6, 7.6, "Flesh"),
        solid("Cylinder", s * 4.8, CY - 0.2, CZ + 1.2, 1.4, 4.0, 4.0, "Pit"),
        plate(s * 5.55, CY + 0.6, CZ + 0.6, 0.8, 1.0, "PitShine", depth=0.15, rot=(0, 90, 0)),
    ]
body += [rod((0, CY + 1.0, CZ + 6.0), (0, CY - 1.0, CZ + 7.2), 0.9, "Skin")]  # a little tail

HY, HZ = CY + 8.4, CZ - 6.0  # the head
head = [
    rod((0, CY + 2.6, CZ - 4.0), (0, HY - 1.2, HZ + 0.8), 2.6, "Green"),  # a green neck...
    block(0, HY, HZ, 3.4, 3.2, 3.6, "Green"),  # ...a head...
    block(0, HY - 0.7, HZ - 2.4, 2.6, 2.2, 2.0, "Muzzle"),  # ...a pale muzzle
    plate(0, HY - 0.6, HZ - 3.45, 1.2, 0.5, "Dark", depth=0.15),
]
head += both(
    plate(1.0, HY + 0.5, HZ - 1.85, 0.8, 0.8, "Dark", depth=0.2),  # eyes
    plate(0.85, HY + 0.7, HZ - 2.0, 0.3, 0.3, "Glint", depth=0.1),
    block(2.2, HY + 1.0, HZ + 0.6, 2.4, 0.8, 1.0, "Green", rot=(0, 0, -25)),  # long ears
    plate(2.2, HY + 1.0, HZ + 0.05, 1.8, 0.4, "Muzzle", depth=0.15, rot=(0, 0, -25)),
)
for s in (-1, 1):  # two big ridged horns curling back
    pts = []
    for k in range(9):
        a = math.radians(-20 + k * 30)
        pts.append((s * (1.0 + k * 0.28), HY + 1.6 + math.sin(math.radians(k * 24)) * 3.4 + k * 0.1, HZ + 0.4 + (1 - math.cos(math.radians(k * 24))) * 3.0))
    for k in range(len(pts) - 1):
        head.append(rod(pts[k], pts[k + 1], 1.1 - k * 0.07, "Horn" if k % 2 else "HornDark"))


def leg(x, z):
    return [
        block(x, 4.0, z, 1.2, 8.0, 1.2, "Green"),
        block(x, 0.5, z - 0.2, 1.4, 1.0, 1.8, "Dark"),
    ]


arms = leg(-2.0, CZ - 2.6) + leg(2.0, CZ - 2.6)
legs = leg(-2.0, CZ + 4.2) + leg(2.0, CZ + 4.2)

ART = {
    "Comment": "Avocadini Antilopini: a slim antelope whose body is a dark green avocado cut open on its sides (pale flesh, a big brown pit), a green head with long ears and big horns curling back, four thin green legs.",
    "VoxelSize": 0.2,
    "Palette": {
        "Skin": (52, 96, 42),
        "Flesh": (186, 220, 100),
        "Pit": (124, 66, 34),
        "PitShine": (196, 130, 90),
        "Green": (110, 160, 70),
        "Muzzle": (214, 226, 160),
        "Dark": (36, 30, 24),
        "Glint": (250, 250, 250),
        "Horn": (120, 92, 70),
        "HornDark": (92, 70, 52),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
