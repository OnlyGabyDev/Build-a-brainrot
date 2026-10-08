# Tigroligre Frutonni (art v2, blocks): a grapefruit tiger, after the original meme image
# (by @alexey_pigeon): an orange tiger with black stripes whose middle is a big grapefruit
# cut open on its sides (a yellow rind, pink flesh in segments), a roaring tiger head (white
# cheeks and muzzle, an open mouth with fangs, amber eyes under angry brows), a striped tail
# curling up with a grapefruit slice at its tip; four striped legs with white paws (the
# front pair are its "arms").
from voxel_art import block, both, plate, rod, solid

CY = 11.0  # the body's middle
FZ = 0.6  # the grapefruit's middle

body = [
    block(0, CY, -5.0, 8.0, 7.6, 5.0, "Orange"),  # the tiger's chest...
    block(0, CY + 0.3, 6.0, 7.6, 7.2, 4.6, "Orange"),  # ...and its back half
    block(0, CY - 3.45, -5.0, 6.0, 1.2, 4.6, "White"),  # a white belly
    solid("Cylinder", 0, CY, FZ, 9.6, 10.4, 10.4, "Rind"),  # the grapefruit, cut open on both sides...
]
for s in (-1, 1):
    body += [
        solid("Cylinder", s * 4.9, CY, FZ, 0.4, 9.0, 9.0, "Flesh"),  # ...pink flesh...
        solid("Cylinder", s * 5.05, CY, FZ, 0.2, 1.0, 1.0, "Pith"),
    ]
    for k in range(6):  # ...in segments
        body.append(block(s * 5.05, CY, FZ, 0.2, 8.4, 0.25, "Pith", rot=(k * 30, 0, 0)))
for z in (-6.6, -4.4, 4.6, 6.8):  # black stripes round its chest and back
    body.append(block(0, CY + 0.6, z, 8.3 if z < 0 else 7.9, 6.8, 0.6, "Black"))
# the tail curls up, a grapefruit slice at its tip
tail = [(0, CY + 2.0, 7.8), (0, CY + 5.0, 10.6), (0, CY + 8.6, 11.0), (0, CY + 10.6, 9.6)]
for k in range(len(tail) - 1):
    body.append(rod(tail[k], tail[k + 1], 1.4 - k * 0.15, "Orange" if k % 2 == 0 else "Black"))
body += [
    solid("Cylinder", 0, CY + 12.4, 9.0, 0.8, 4.0, 4.0, "Rind"),
    solid("Cylinder", 0.45, CY + 12.4, 9.0, 0.2, 3.4, 3.4, "Flesh"),
    solid("Cylinder", -0.45, CY + 12.4, 9.0, 0.2, 3.4, 3.4, "Flesh"),
]

HY, HZ = CY + 3.8, -10.0  # the head
head = [
    block(0, HY, HZ, 7.4, 6.6, 5.6, "Orange"),  # a roaring tiger head...
    block(0, HY - 0.3, HZ - 3.5, 4.4, 2.2, 2.6, "White"),  # ...a white muzzle...
    block(0, HY - 2.1, HZ - 3.4, 3.8, 1.8, 2.2, "Mouth"),  # ...its open mouth...
    block(0, HY - 3.6, HZ - 3.0, 4.0, 1.2, 2.8, "White", rot=(-18, 0, 0)),  # ...the lower jaw dropped
    plate(0, HY - 2.75, HZ - 4.4, 2.0, 0.5, "Tongue", depth=0.2),
    block(0, HY + 0.55, HZ - 4.95, 1.6, 0.9, 0.5, "Nose"),
    plate(0, HY + 2.4, HZ - 2.9, 0.6, 1.8, "Black", depth=0.2),  # forehead stripes
]
head += both(
    block(3.9, HY - 1.0, HZ - 1.2, 1.4, 3.6, 3.4, "White"),  # white cheeks
    block(1.4, HY - 1.75, HZ - 4.7, 0.5, 1.0, 0.5, "Tooth"),  # fangs
    block(1.3, HY - 3.0, HZ - 4.5, 0.5, 0.9, 0.5, "Tooth"),
    plate(1.8, HY + 1.4, HZ - 2.9, 1.5, 1.0, "Amber", depth=0.2),  # amber eyes...
    plate(1.7, HY + 1.4, HZ - 3.05, 0.5, 0.8, "Eye", depth=0.2),
    plate(1.9, HY + 2.3, HZ - 2.9, 2.0, 0.5, "Black", depth=0.3, rot=(0, 0, 20)),  # ...under angry brows
    plate(1.4, HY + 2.8, HZ - 2.9, 0.5, 1.2, "Black", depth=0.2, rot=(0, 0, 15)),
    block(2.8, HY + 3.6, HZ + 0.8, 1.8, 1.8, 1.0, "Orange"),  # ears
    plate(2.8, HY + 3.6, HZ + 0.2, 1.0, 1.0, "White", depth=0.2),
    block(3.75, HY + 1.0, HZ + 0.6, 0.3, 0.6, 3.0, "Black"),  # stripes on its sides
)


def leg(x, z):
    out = [
        block(x, 4.4, z, 2.8, 8.4, 2.8, "Orange"),  # a striped leg...
        block(x, 0.8, z - 0.5, 3.2, 1.6, 3.6, "White"),  # ...a white paw
    ]
    for y in (3.4, 6.2):
        out.append(block(x, y, z, 3.0, 0.6, 3.0, "Black"))
    return out


arms = leg(-2.5, -5.2) + leg(2.5, -5.2)
legs = leg(-2.5, 6.2) + leg(2.5, 6.2)

ART = {
    "Comment": "Tigroligre Frutonni: an orange striped tiger whose middle is a big grapefruit cut open on its sides, a roaring head with white cheeks and fangs, a striped tail curling up to a grapefruit slice, striped legs with white paws.",
    "VoxelSize": 0.2,
    "Palette": {
        "Orange": (240, 140, 40),
        "Black": (30, 26, 28),
        "White": (248, 244, 236),
        "Rind": (250, 206, 70),
        "Flesh": (240, 84, 104),
        "Pith": (252, 214, 210),
        "Mouth": (120, 30, 40),
        "Tongue": (236, 110, 130),
        "Tooth": (252, 252, 248),
        "Nose": (220, 120, 130),
        "Amber": (250, 196, 60),
        "Eye": (24, 20, 20),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
