# La Vaca Saturno Saturnita (art v2): a cow that's Saturn, like Steal a Brainrot's model:
# a round planet body (voxels, for its roundness) in beige and pale blue stripes; its
# "arms" are the planet's flat white ring; a blocky cow head on top (black patches,
# sunglasses, a pink snout, horns, ears); short legs on big bare feet.
# Reference: Steal a Brainrot's render.
import math

from voxel_art import ball, block, both, box, paint, plate, rod

body = [ball(0, 13.6, 0, 6.8, 6.6, 6.4, "Planet")]
for y in (8, 11, 15, 18):  # its stripes
    body.append(paint(box(-8, y, -8, 8, y + 1.2, 8, "Stripe")))

arms = []  # the ring: flat segments round the planet
for k in range(24):
    a = k / 24 * math.pi * 2
    arms.append(block(math.sin(a) * 9.4, 13.6, math.cos(a) * 9.4, 2.7, 0.7, 3.6, "Ring", rot=(0, math.degrees(a), 0)))

head = [
    block(0, 22.6, -1.6, 6.4, 5, 5.6, "Cow"),  # the cow's head
    block(0, 21.0, -4.95, 4.4, 2.4, 1.4, "Snout"),  # a pink snout
    plate(-0.9, 21.0, -5.7, 0.6, 0.8, "Nostril", depth=0.1),
    plate(0.9, 21.0, -5.7, 0.6, 0.8, "Nostril", depth=0.1),
    plate(0, 23.6, -4.55, 6.2, 1.6, "Shades", depth=0.2),  # sunglasses
    plate(-1.6, 24.8, 1.25, 2.4, 2, "Patch", depth=0.1),  # black patches
    plate(1.8, 21.4, 1.25, 2, 2.4, "Patch", depth=0.1),
]
head += both(
    plate(1.6, 23.6, -4.7, 2.2, 1.4, "Lens", depth=0.1),
    rod((2.4, 25, -2), (3.6, 27.4, -2.4), 0.9, "Horn"),  # horns
    block(3.6, 23.4, -1.2, 1.4, 0.8, 1.6, "Cow", rot=(0, 0, -20)),  # ears
    plate(3.25, 22.4, -2.6, 0.2, 2, "Patch", depth=2, rot=(0, 90, 0)),
)

legs = both(
    block(3, 4.4, 0, 2.6, 4, 2.6, "Feet"),  # short legs...
    block(3.2, 1.4, -1.4, 3.6, 2.8, 6, "Feet"),  # ...on big bare feet
    plate(3.2, 1.0, -4.45, 3.2, 1.2, "Toe", depth=0.1),
)

ART = {
    "Comment": "La Vaca Saturno Saturnita: a cow that's Saturn: a striped planet body, a flat ring for arms, a cow head in shades, big bare feet.",
    "VoxelSize": 0.2,
    "Palette": {
        "Planet": (230, 205, 160),
        "Stripe": (150, 205, 230),
        "Ring": (240, 242, 248),
        "Cow": (250, 250, 250),
        "Patch": (25, 25, 28),
        "Snout": (245, 165, 175),
        "Nostril": (150, 70, 80),
        "Shades": (20, 20, 24),
        "Lens": (40, 45, 60),
        "Horn": (240, 225, 180),
        "Feet": (232, 200, 160),
        "Toe": (205, 170, 130),
    },
    "Joints": {"Head": (0, 22.6, -1.6)},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
