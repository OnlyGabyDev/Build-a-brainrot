# Fluriflura (art v2, blocks): a goggled bird, after the original meme image (by
# @capybarawt): a round black bird with a white belly, a spiky black crest, a big curved
# orange beak and huge round goggles with tan frames; its "arms" are wide black wings,
# white at the tips, spread out; orange legs on webbed feet.
from voxel_art import block, both, plate, rod, solid, wedge

legs = []
for x in (-2.0, 2.0):
    legs += [
        rod((x, 9.4, 0.6), (x * 1.1, 1.4, -0.4), 1.2, "Orange"),  # thin orange legs...
        block(x * 1.1, 0.5, -1.6, 3.2, 1.0, 3.4, "Orange"),  # ...webbed feet
        wedge(x * 1.1, 0.5, -3.9, 3.2, 1.0, 1.2, "Orange", rot=(0, 180, 0)),
    ]

# the round body, stepped out of blocks: black all round, a white belly in front
body = [
    block(0, 10.4, 0.6, 7, 2, 7, "Black"),
    block(0, 14.4, 0.6, 9, 6, 8.4, "Black"),
    block(0, 18.4, 0.6, 7.4, 2, 7, "Black"),
    block(0, 14.0, -3.0, 6.4, 7.4, 1.6, "White"),  # the white belly...
    block(0, 10.6, -2.4, 4.6, 1.6, 1.4, "White"),
    block(0, 10.6, 5.6, 4, 0.8, 3.6, "Black", rot=(-30, 0, 0)),  # a tail
]

arms = both(  # wide wings spread out, white tips
    block(7.4, 16.8, 0.8, 6.4, 1.8, 5.4, "Black", rot=(0, 0, 22)),
    block(12.6, 19.4, 1.0, 4.8, 1.5, 4.8, "Black", rot=(0, 0, 32)),
    block(15.6, 21.6, 1.2, 2.8, 1.3, 4.2, "White", rot=(0, 0, 38)),
)

head = [
    block(0, 22.6, 0.4, 7, 6.4, 6.6, "Black"),  # the head
]
for k, (x, tilt) in enumerate(((-1.6, -25), (-0.4, -8), (0.8, 10), (1.8, 28), (0.2, 0))):  # a spiky crest
    head.append(wedge(x, 27.4, 1.4 + (k % 2) * 0.8, 1.2, 3.2, 2.2, "Black", rot=(0, 0, tilt)))
head += [  # the big curved orange beak, darker at the tip
    block(0, 21.2, -4.6, 3.6, 3.8, 3.4, "Orange"),
    block(0, 20.2, -7.4, 3.0, 3.0, 2.8, "Orange", rot=(-14, 0, 0)),
    block(0, 18.8, -9.4, 2.2, 2.2, 2.0, "OrangeDark", rot=(-28, 0, 0)),
    plate(0, 20.8, -6.35, 3.8, 0.3, "OrangeDark", depth=2.6),  # the beak's line
]
head += both(  # huge round goggles
    solid("Cylinder", 2.1, 23.8, -3.4, 1.2, 4.8, 4.8, "Frame", rot=(0, 90, 0)),
    solid("Cylinder", 2.1, 23.8, -4.1, 0.4, 3.5, 3.5, "Lens", rot=(0, 90, 0)),
    plate(1.4, 24.6, -4.35, 0.7, 0.7, "Glint", depth=0.1),
)

ART = {
    "Comment": "Fluriflura: a round black and white bird with a spiky crest, a big orange beak and huge round goggles, wings spread, orange webbed feet.",
    "VoxelSize": 0.2,
    "Palette": {
        "Black": (38, 38, 46),
        "White": (245, 242, 235),
        "Orange": (250, 140, 40),
        "OrangeDark": (200, 90, 30),
        "Frame": (214, 168, 100),
        "Lens": (30, 30, 36),
        "Glint": (180, 200, 230),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
