# Strawberrelli Flamingelli (art v2, blocks): a strawberry flamingo, after the original meme
# image (by @alexey_pigeon): a flamingo whose body is a big red strawberry dotted with yellow
# seeds and crowned with green leaves, a long pink S-neck, a pink head with a pale beak bent
# down to a black tip, yellow eyes; its "arms" are pink wings folded along the berry; long
# thin pink legs with backward knees and webbed feet.
import math

from voxel_art import block, both, plate, rod

CY, CZ = 17.0, 1.0  # the berry's middle

body = [  # the strawberry, wide at the top and coming to a point below
    block(0, CY + 0.6, CZ, 12, 7, 12, "Berry"),
    block(0, CY, CZ, 10, 10, 10, "Berry"),
    block(0, CY - 0.6, CZ, 8.6, 12, 8.6, "Berry"),
    block(0, CY - 7.6, CZ, 6.4, 3, 6.4, "Berry"),
    block(0, CY - 9.6, CZ, 3.6, 2.4, 3.6, "Berry"),
]
for k in range(6):  # green leaves round the top, drooping over its edge, and a stem
    a = k * 60 + 30
    leaf = block(0, 0, 4.0, 2.8, 0.8, 6.0, "Leaf", rot=(-28, a, 0))
    turn = math.radians(a)
    leaf["Min"] = leaf["Max"] = leaf["Center"] = (math.sin(turn) * 4.2, CY + 3.9, CZ + math.cos(turn) * 4.2)
    body.append(leaf)
body.append(block(0, CY + 4.3, CZ, 6.0, 0.8, 6.0, "Leaf"))
body.append(rod((0, CY + 4.4, CZ + 1.0), (0.4, CY + 6.4, CZ + 2.2), 1.0, "Stem"))
# yellow seeds on every side, in staggered rows
for row, (y, half) in enumerate(((CY - 5.6, 4.3), (CY - 3.6, 4.3), (CY - 1.6, 5.0), (CY + 0.6, 6.0), (CY + 2.6, 6.0))):
    for t in ((-3.0, -1.0, 1.0, 3.0) if row % 2 == 0 else (-2.0, 0.0, 2.0)):
        if abs(t) > half - 0.8:
            continue
        body.append(plate(t, y, CZ - half - 0.15, 0.8, 1.1, "Seed", depth=0.3))
        body.append(plate(t, y, CZ + half + 0.15, 0.8, 1.1, "Seed", depth=0.3))
        body += both(block(half + 0.15, y, CZ + t, 0.3, 1.1, 0.8, "Seed"))

head = [  # a long pink S-neck...
    rod((0, CY + 1.0, CZ - 4.6), (0, CY + 5.0, CZ - 7.8), 2.4, "Pink"),
    rod((0, CY + 5.0, CZ - 7.8), (0, CY + 9.0, CZ - 7.8), 2.2, "Pink"),
    rod((0, CY + 9.0, CZ - 7.8), (0, CY + 12.6, CZ - 5.8), 2.2, "Pink"),
    block(0, CY + 13.8, CZ - 6.6, 3.8, 3.6, 4.4, "Pink"),  # ...a pink head...
    block(0, CY + 13.8, CZ - 9.6, 2.6, 2.2, 2.2, "Beak"),  # ...a pale beak bent down to a black tip
    block(0, CY + 12.4, CZ - 10.4, 2.0, 2.2, 1.6, "Beak"),
    block(0, CY + 11.0, CZ - 10.5, 1.6, 1.2, 1.4, "Dark"),
]
head += both(
    plate(1.95, CY + 14.6, CZ - 7.4, 0.2, 1.2, "Eye", depth=1.2, rot=(0, 90, 0)),  # yellow eyes on its sides
    plate(2.05, CY + 14.6, CZ - 7.5, 0.2, 0.5, "Dark", depth=0.5, rot=(0, 90, 0)),
)

arms = []
for s in (-1, 1):  # pink wings folded along the berry, dark tips at the back
    arms += [
        block(s * 6.6, CY + 1.0, CZ + 0.6, 1.4, 6.0, 8.6, "Wing", rot=(-14, 0, 0)),
        block(s * 7.2, CY + 1.8, CZ - 0.6, 0.8, 3.4, 6.0, "WingLight", rot=(-14, 0, 0)),
        block(s * 6.9, CY - 0.4, CZ + 4.8, 1.2, 4.0, 4.4, "WingLight", rot=(-24, 0, 0)),
        block(s * 7.0, CY - 1.6, CZ + 7.0, 1.0, 2.0, 2.6, "Dark", rot=(-30, 0, 0)),
    ]


def leg(x):
    knee = (x, 6.4, CZ + 1.6)
    return [
        rod((x, CY - 6.0, CZ), knee, 1.0, "Pink"),  # a long thin leg...
        block(*knee, 1.5, 1.5, 1.5, "Pink"),  # ...a knee bending back...
        rod(knee, (x, 1.0, CZ - 0.2), 1.0, "Pink"),
        block(x, 0.5, CZ - 1.4, 3.0, 1.0, 3.4, "Pink"),  # ...a webbed foot
    ]


legs = leg(-1.8) + leg(1.8)

ART = {
    "Comment": "Strawberrelli Flamingelli: a flamingo whose body is a big red strawberry with yellow seeds and green leaves, a long pink S-neck, a pale beak bent down to a black tip, pink wings, long thin pink legs.",
    "VoxelSize": 0.2,
    "Palette": {
        "Berry": (222, 40, 56),
        "Seed": (252, 216, 90),
        "Leaf": (74, 160, 60),
        "Stem": (90, 130, 50),
        "Pink": (246, 130, 160),
        "Wing": (240, 104, 140),
        "WingLight": (252, 160, 186),
        "Beak": (246, 220, 210),
        "Eye": (252, 210, 60),
        "Dark": (28, 24, 28),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
