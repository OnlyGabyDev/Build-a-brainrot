# Orcalita Orcala (art v2, blocks): a pink orca in sneakers, after the original meme image
# (by @lowbrainrot; Orcalero Orcala's wife): a glossy pink orca standing up on its tail (a
# white belly and white eye patches, a tall pink back fin), a big pink bow on its head,
# its side fins as "arms"; it stands in chunky white sneakers (no logos).
import math

from voxel_art import block, both, plate, rod, solid, wedge

BY = 13.0  # the body's middle
body = [
    solid("Ball", 0, BY, 0.6, 11.0, 11.0, 11.0, "Pink"),  # a glossy pink orca...
    solid("Ball", 0, BY - 4.6, 0.8, 8.6, 8.6, 8.6, "Pink"),
    solid("Ball", 0, BY - 1.6, -1.6, 8.6, 8.6, 8.6, "White"),  # ...a white belly
    wedge(0, BY + 5.6, 5.0, 1.2, 9.0, 5.0, "Pink", rot=(-15, 180, 0)),  # ...a tall back fin
    block(0, BY - 8.6, 3.4, 7.4, 1.0, 2.6, "Pink", rot=(20, 0, 0)),  # (its tail flukes)
]

HY = BY + 6.6  # the head
head = [
    solid("Ball", 0, HY, -0.6, 9.6, 9.6, 9.6, "Pink"),  # a round pink head...
    solid("Ball", 0, HY - 1.8, -2.8, 6.0, 6.0, 6.0, "White"),  # ...a white chin
    block(0, HY - 1.4, -5.6, 3.4, 0.4, 0.4, "Dark"),  # ...a smile
]
head += both(
    solid("Ball", 2.6, HY + 1.0, -3.0, 3.4, 3.4, 3.4, "White"),  # white eye patches...
    plate(2.5, HY + 0.6, -4.75, 0.8, 0.8, "Dark", depth=0.2),  # ...little eyes
    plate(2.4, HY + 0.85, -4.9, 0.3, 0.3, "Glint", depth=0.1),
    block(2.2, HY + 5.6, -0.4, 3.0, 2.4, 1.2, "Bow", rot=(0, 0, -15)),  # a big pink bow
)
head.append(block(0, HY + 5.4, -0.4, 1.4, 1.4, 1.4, "BowDark"))

arms = both(  # side fins
    block(5.4, BY - 0.4, 0.0, 1.0, 5.0, 2.4, "Pink", rot=(0, 0, -35)),
)

legs = [  # standing on its tail...
    rod((0, BY - 7.0, 1.0), (0, 4.6, 1.6), 3.4, "Pink"),
    block(0, 4.2, 1.6, 6.4, 1.4, 2.4, "Pink"),
]
for s in (-1, 1):  # ...in chunky white sneakers
    x = s * 2.4
    legs += [
        block(x, 1.6, 0.6, 3.2, 2.4, 5.6, "Sneaker"),
        block(x, 0.3, 0.6, 3.4, 0.6, 6.0, "Sole"),
        block(x + s * 1.65, 1.6, 0.4, 0.2, 1.0, 3.0, "SneakerDark"),
    ]
    for k in range(3):
        legs.append(block(x, 2.95, -0.6 + k * 1.0, 2.0, 0.3, 0.3, "SneakerDark"))

ART = {
    "Comment": "Orcalita Orcala: a glossy pink orca standing on its tail with a white belly and eye patches, a tall back fin, a big pink bow on its head, side fins, in chunky white sneakers.",
    "VoxelSize": 0.2,
    "Palette": {
        "Pink": (240, 110, 170),
        "White": (250, 244, 248),
        "Dark": (30, 24, 30),
        "Glint": (250, 250, 250),
        "Bow": (250, 130, 190),
        "BowDark": (220, 90, 160),
        "Sneaker": (246, 246, 244),
        "Sole": (226, 226, 222),
        "SneakerDark": (200, 200, 206),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
