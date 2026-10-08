# Tric Trac Baraboom (art v2, blocks): a cucumber-headed creature on giant bare feet, after
# the original meme image (by @__chenesacc__ and @reisonbs): a speckled green cucumber head
# drooping forward into a long snout with a dried tip, red-rimmed eyes on its sides, two
# big leaves on a curly stem on top; a bare beige body with green vines down it; its
# "arms" are bunches of vines hanging from its shoulders; short legs on huge feet with
# five toes each.
import random

from voxel_art import block, both, plate, rod

rng = random.Random(7)  # the speckles' spots, the same every run

legs = []
for x in (-2.8, 2.8):
    legs += [
        block(x, 3.6, 0.4, 3.8, 4.8, 4.2, "Skin"),  # short legs
        block(x * 1.1, 0.9, -1.4, 5.6, 1.8, 7.6, "Skin"),  # huge feet...
    ]
    for k in range(5):  # ...five fat toes each, nails on top
        tx = x * 1.1 + (k - 2) * 1.12 * (1 if x > 0 else -1)
        legs.append(block(tx, 0.85, -5.8 + abs(k - 1.6) * 0.3, 1.0, 1.7, 1.6, "Skin"))
        legs.append(block(tx, 1.75, -6.0 + abs(k - 1.6) * 0.3, 0.7, 0.15, 0.8, "Nail"))

body = [
    block(0, 8.5, 0.4, 8.6, 5, 7.2, "Skin"),
    block(0, 13.5, 0.4, 7.6, 5, 6.6, "Skin"),
]
for x, y0 in ((-2.6, 7.6), (0.4, 9.4), (2.8, 6.6)):  # vines down its front
    body.append(plate(x, (y0 + 16) / 2, -3.35, 0.7, 16 - y0, "Vine", depth=0.4))

arms = []
for side in (-1, 1):  # bunches of vines hanging from its shoulders
    for k, (dx, dz, end) in enumerate(((0, -1.2, 4.6), (0.8, 0, 3.0), (0.2, 1.2, 5.6))):
        top = (side * (3.8 + dx * 0.3), 15.6, 0.4 + dz)
        mid = (side * (5.0 + dx), 10.4, 0.2 + dz)
        arms.append(rod(top, mid, 1.1, "Vine"))
        arms.append(rod(mid, (side * (5.2 + dx * 0.6), end, dz - 0.2), 1.0, "VineDark" if k == 1 else "Vine"))

head = [
    block(0, 20.6, 0.6, 7.4, 9.2, 7.4, "Green"),  # the cucumber head...
    block(0, 25.6, 0.8, 6.0, 1.2, 6.0, "Green"),
    rod((0, 21.8, -2.2), (0, 13.4, -8.4), 5.2, "Green"),  # ...drooping into a long snout
    rod((0, 13.4, -8.4), (0, 11.6, -9.2), 3.0, "Tip"),  # its dried tip
    rod((0, 26.2, 0.8), (0.6, 28.4, 0.6), 0.8, "Stem"),  # a curly stem...
    rod((0.6, 28.4, 0.6), (-0.4, 29.6, 0.2), 0.7, "Stem"),
]
head += [  # ...and two big leaves
    block(-3.4, 29.8, 0.2, 6.6, 0.8, 5.2, "Leaf", rot=(0, 20, 24)),
    block(3.6, 30.4, 0.6, 7.0, 0.8, 5.6, "Leaf", rot=(0, -15, -20)),
    block(-3.4, 30.3, 0.2, 6.0, 0.3, 0.5, "LeafVein", rot=(0, 20, 24)),
    block(3.6, 30.9, 0.6, 6.4, 0.3, 0.5, "LeafVein", rot=(0, -15, -20)),
]
head += both(
    plate(3.85, 22.6, -1.4, 2.4, 2.4, "EyeRim", depth=0.4, rot=(0, 90, 0)),  # red-rimmed eyes on its sides
    plate(4.0, 22.6, -1.4, 1.5, 1.5, "Dark", depth=0.3, rot=(0, 90, 0)),
    plate(4.1, 23.0, -1.8, 0.4, 0.4, "White", depth=0.2, rot=(0, 90, 0)),
)
# pale speckles over its head
for _ in range(60):
    face = rng.choice(("front", "left", "right", "back"))
    y = rng.uniform(16.6, 24.8)
    if face == "front":
        x = rng.uniform(-3.3, 3.3)
        if abs(x) < 2.9 and y < 23.4:
            continue  # (the snout covers this)
        head.append(block(x, y, -3.15, 0.5, 0.5, 0.4, "Speckle"))
    elif face == "back":
        head.append(block(rng.uniform(-3.3, 3.3), y, 4.35, 0.5, 0.5, 0.4, "Speckle"))
    else:
        sx = 3.75 if face == "right" else -3.75
        z = rng.uniform(-2.8, 3.8)
        if 21 < y < 24.4 and -3 < z < 0.2:
            continue  # (the eye's here)
        head.append(block(sx, y, z, 0.4, 0.5, 0.5, "Speckle"))
for t in (0.15, 0.35, 0.55, 0.75):  # and down its snout
    for dx in (-1.6, 0.4, 1.8):
        y = 21.8 + (13.4 - 21.8) * t
        z = -2.2 + (-8.4 + 2.2) * t
        head.append(block(dx + rng.uniform(-0.4, 0.4), y + 1.6, z - 1.85, 0.5, 0.5, 0.5, "Speckle", rot=(-36, 0, 0)))

ART = {
    "Comment": "Tric Trac Baraboom: a speckled cucumber head drooping into a snout, two big leaves on top, a bare body hung with vines, huge bare feet.",
    "VoxelSize": 0.2,
    "Palette": {
        "Green": (104, 150, 84),
        "Speckle": (200, 225, 170),
        "Tip": (170, 140, 80),
        "Stem": (80, 110, 50),
        "Leaf": (98, 168, 64),
        "LeafVein": (150, 205, 110),
        "Vine": (88, 140, 70),
        "VineDark": (66, 110, 52),
        "Skin": (232, 196, 160),
        "Nail": (250, 235, 220),
        "EyeRim": (200, 70, 60),
        "Dark": (25, 22, 26),
        "White": (250, 250, 245),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
