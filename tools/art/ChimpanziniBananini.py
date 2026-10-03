# Chimpanzini Bananini (art v2, blocks): a grumpy chimp in a peeled banana, built like
# Steal a Brainrot's model from clean blocks and ramps: a green cube head with a flat pink
# face (a heavy brow, small dark eyes, a broad nose, a frown) and pink ears; the peeled
# banana's pale fruit standing in its yellow peel, the peel's flaps falling open round it
# (the two side flaps are its "arms"), its bottom curling into the hook it stands on, a
# brown tip at the end. Reference: Steal a Brainrot's render.
from voxel_art import block, both, plate, wedge

head = [
    block(0, 25, 0.2, 8, 8, 7.6, "Green"),  # the head, green all round
    block(0, 23.4, -3.75, 6.6, 5.6, 0.5, "Face"),  # the flat pink face
    block(0, 25.9, -4.15, 6.8, 1.3, 0.5, "Brow"),  # a heavy brow
    plate(-1.6, 24.5, -4.25, 1.1, 1.2, "Dark"),  # small dark eyes
    plate(1.6, 24.5, -4.25, 1.1, 1.2, "Dark"),
    block(0, 23.1, -4.3, 2, 1.2, 0.8, "Brow"),  # a broad nose
    plate(-0.5, 22.9, -4.75, 0.5, 0.5, "Dark", depth=0.2),
    plate(0.5, 22.9, -4.75, 0.5, 0.5, "Dark", depth=0.2),
    plate(0, 21.4, -4.05, 2.4, 0.5, "Dark"),  # a frown, its corners down
    plate(-1.5, 21.0, -4.05, 0.8, 0.5, "Dark", rot=(0, 0, 35)),
    plate(1.5, 21.0, -4.05, 0.8, 0.5, "Dark", rot=(0, 0, -35)),
    wedge(0, 29.4, -2, 8, 0.8, 1.6, "Green"),  # a tuft over the brow
]
head += both(
    block(4.4, 24.4, -0.2, 1, 2.4, 2.2, "Face"),  # pink ears
    block(4.75, 24.4, -0.2, 0.3, 1.4, 1.2, "Brow"),
)

body = [
    block(0, 15, 0, 5.4, 10, 5, "Fruit"),  # the peeled fruit
    block(0, 20.2, 0, 4.6, 0.6, 4.2, "Fruit"),
    # the front and back flaps of peel, falling open
    block(0, 13.4, -3.6, 5.4, 8.4, 0.8, "Banana", rot=(18, 0, 0)),
    block(0, 13.4, 3.6, 5.4, 8.4, 0.8, "Banana", rot=(-18, 0, 0)),
    plate(0, 13.4, -4.05, 3.4, 7, "Fruit", depth=0.2, rot=(18, 0, 0)),  # the peel's pale inside
]

arms = both(
    # the side flaps: out at the top, hanging down
    block(3.9, 15.8, 0, 0.9, 5, 5, "Banana", rot=(0, 0, 32)),
    block(5.3, 10.6, 0, 0.9, 6, 4.6, "Banana", rot=(0, 0, 8)),
    wedge(5.7, 7.0, 0, 0.9, 1.6, 4.2, "Banana", rot=(90, 0, 0)),
)

legs = [
    block(0.4, 8.2, 0, 5, 4.4, 4.6, "Banana"),  # the bottom, curling into a hook
    block(2.2, 5.0, 0, 4.4, 3.8, 4.2, "Banana", rot=(0, 0, 32)),
    block(4.4, 2.6, 0, 3.8, 3.2, 3.8, "Banana", rot=(0, 0, 58)),
    block(6.6, 1.5, 0, 2.6, 2.4, 3.2, "Banana", rot=(0, 0, 80)),
    block(7.9, 1.6, 0, 1.4, 1.8, 1.8, "Tip", rot=(0, 0, 80)),
]

ART = {
    "Comment": "Chimpanzini Bananini: a grumpy chimp in a peeled banana (blocks and ramps), standing on its curl, the side flaps for arms.",
    "VoxelSize": 0.2,
    "Palette": {
        "Banana": (255, 222, 70),
        "Fruit": (255, 244, 180),
        "Tip": (105, 70, 40),
        "Green": (90, 175, 70),
        "Face": (240, 150, 140),
        "Brow": (215, 115, 110),
        "Dark": (35, 25, 25),
    },
    "Joints": {"Legs": (0, 10, 0), "Head": (0, 25, 0)},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
