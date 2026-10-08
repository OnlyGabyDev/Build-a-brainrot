# Quesadilla Crocodila (art v2, blocks): a quesadilla crocodile, after the original meme
# image (by @lifewatching1, 2025-03-25): a crocodile standing up, wrapped in a huge folded
# quesadilla like a poncho (a toasted tortilla with brown spots, melted cheese and green
# bits dripping from its edges), its long scaly green-grey head poking out under the top;
# pale scaly arms and legs with claws, a tail behind.
from voxel_art import block, both, plate, rod, solid

BY = 14.0  # the quesadilla's middle
STEPS = [(10.4, 0.0), (9.0, 1.7), (7.6, 3.4), (6.2, 5.1), (4.8, 6.8), (3.2, 8.5), (1.8, 10.0)]  # (width, height up)

body = [block(0, BY - 0.6, 0.6, 6.4, 9.0, 4.6, "Pale")]  # a pale scaly body...
for z in (-2.2, 3.4):  # ...wrapped in a folded quesadilla, front and back
    for w, up in STEPS:
        body.append(block(0, BY - 5.4 + up, z, w, 1.8, 1.4, "Tortilla"))
body.append(block(0, BY + 4.8, 0.6, 1.8, 1.6, 7.0, "Tortilla"))  # (the fold at the top)
for x, y, z in ((-3.4, BY - 4.6, -2.95), (2.6, BY - 3.0, -2.95), (-1.0, BY - 1.6, -2.95), (1.8, BY + 0.6, -2.95), (-0.6, BY + 2.6, -2.95), (3.6, BY - 5.0, -2.95), (-2.6, BY - 1.0, 4.15), (1.4, BY + 1.8, 4.15), (0.0, BY - 4.0, 4.15)):  # toasted spots
    body.append(plate(x, y, z, 1.0, 0.8, "Toast", depth=0.15))
for x, h, c in ((-4.4, 2.6, "Cheese"), (-3.0, 1.6, "Lettuce"), (-1.6, 3.2, "Cheese"), (0.0, 2.0, "Cheese"), (1.4, 1.4, "Lettuce"), (2.8, 2.8, "Cheese"), (4.2, 1.8, "Cheese")):  # cheese and green bits dripping
    body.append(block(x, BY - 6.3 - h / 2, -2.0, 1.0, h, 0.9, c))
    body.append(block(x * 0.9, BY - 6.3 - h / 2 + 0.4, 3.4, 1.0, h, 0.9, c))
body += [rod((0, BY - 4.6, 3.6), (0, 4.0, 9.0), 2.6, "Croc"), rod((0, 4.0, 9.0), (0, 1.0, 12.4), 1.6, "Croc")]  # a tail

HY, HZ = BY + 2.4, -4.2  # the crocodile's head, poking out under the top
head = [
    block(0, HY, HZ + 0.4, 4.4, 3.6, 4.4, "Croc"),  # a scaly head...
    block(0, HY - 0.6, HZ - 4.0, 3.6, 1.8, 5.4, "Croc"),  # ...a long snout...
    block(0, HY - 1.8, HZ - 3.4, 3.4, 0.8, 5.8, "CrocPale"),  # ...a pale jaw
    block(0, HY + 0.4, HZ - 6.4, 2.2, 0.6, 1.0, "CrocDark"),  # (nostril bumps)
]
for k in range(6):  # teeth
    head += both(block(1.6, HY - 1.25, HZ - 1.4 - k * 0.9, 0.3, 0.5, 0.3, "Tooth"))
head += both(
    block(1.3, HY + 2.0, HZ + 0.2, 1.4, 1.0, 1.4, "Croc"),  # eyes on top...
    plate(1.3, HY + 2.1, HZ - 0.55, 1.0, 0.7, "Eye", depth=0.2),
    plate(1.3, HY + 2.1, HZ - 0.7, 0.3, 0.6, "Dark", depth=0.15),
    block(2.25, HY + 0.6, HZ + 0.4, 0.3, 0.4, 3.6, "CrocDark"),  # (scales down its sides)
)

arms = []
for s in (-1, 1):  # pale scaly arms with claws
    arms += [
        rod((s * 4.6, BY + 1.6, 0.6), (s * 6.4, BY - 2.6, -0.2), 1.8, "Pale"),
        rod((s * 6.4, BY - 2.6, -0.2), (s * 6.6, BY - 6.4, -1.2), 1.6, "Pale"),
        block(s * 6.6, BY - 7.0, -1.4, 1.8, 1.2, 1.8, "Pale"),
    ] + [block(s * 6.6 + dx, BY - 7.8, -1.8, 0.4, 0.8, 0.4, "Claw") for dx in (-0.6, 0.0, 0.6)]

legs = []
for s in (-1, 1):  # pale scaly legs, big clawed feet
    legs += [
        rod((s * 2.2, 8.4, 0.6), (s * 2.6, 4.0, 0.0), 2.4, "Pale"),
        rod((s * 2.6, 4.0, 0.0), (s * 2.8, 1.2, 0.4), 2.0, "Pale"),
        block(s * 2.8, 0.6, -1.2, 3.0, 1.2, 4.6, "Pale"),
    ] + [block(s * 2.8 + dx, 0.5, -3.75, 0.5, 0.6, 0.5, "Claw") for dx in (-1.0, 0.0, 1.0)]

ART = {
    "Comment": "Quesadilla Crocodila: a crocodile standing up wrapped in a huge folded quesadilla with cheese and green bits dripping, its long scaly head poking out, pale scaly arms and legs with claws, a tail.",
    "VoxelSize": 0.2,
    "Palette": {
        "Tortilla": (244, 214, 140),
        "Toast": (190, 130, 60),
        "Cheese": (246, 170, 40),
        "Lettuce": (100, 170, 60),
        "Croc": (110, 140, 120),
        "CrocDark": (80, 104, 90),
        "CrocPale": (200, 210, 186),
        "Pale": (226, 214, 186),
        "Tooth": (250, 248, 240),
        "Eye": (230, 200, 90),
        "Dark": (24, 20, 20),
        "Claw": (90, 76, 60),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
