# Pandaccini Bananini (art v2, blocks): a banana panda, after the original meme image (by
# @alexey_pigeon): a panda's front half coming out of a big peeled banana (the yellow
# banana is its back half, curving up to a brown stem; the peel's flaps, yellow outside and
# cream inside, hang down over its shoulders), a round white panda head with black ears and
# drooping black eye patches, a black nose and a little smile; black panda legs (the front
# pair are its "arms").
from voxel_art import block, both, plate

CY = 11.0  # the banana's middle

body = [
    block(0, CY, 3.0, 9.0, 8.0, 9.0, "Banana"),  # the banana, the panda's back half...
    block(0, CY, 3.2, 8.0, 9.0, 8.6, "Banana"),
    block(0, CY + 1.8, 8.4, 7.0, 6.6, 3.8, "Banana", rot=(-25, 0, 0)),  # ...curving up...
    block(0, CY + 4.6, 10.8, 5.4, 5.0, 3.4, "Banana", rot=(-45, 0, 0)),
    block(0, CY + 7.6, 12.2, 3.6, 3.6, 3.0, "Banana", rot=(-65, 0, 0)),
    block(0, CY + 10.0, 12.9, 1.8, 2.6, 1.8, "Stem", rot=(-20, 0, 0)),  # ...to a brown stem
    block(0, CY + 4.55, 3.0, 2.0, 0.3, 7.0, "Ridge"),  # the banana's ridges
    block(0, CY - 0.4, -2.6, 8.4, 7.6, 4.0, "White"),  # the panda's chest out of its front...
    block(0, CY + 1.5, -1.6, 8.8, 5.2, 2.2, "Black"),  # ...a black band over its shoulders
]
body += both(
    block(4.6, CY + 1.0, 1.6, 0.3, 1.0, 1.4, "Spot"),  # brown spots on the banana
    block(4.6, CY - 1.6, 5.0, 0.3, 0.8, 1.0, "Spot"),
    block(4.1, CY + 3.2, 6.6, 0.3, 0.6, 0.8, "Spot"),
)
for side in (-1, 1):  # the peel's flaps hang down over its shoulders, cream inside
    body += [
        block(side * 5.1, CY - 0.6, -1.8, 0.8, 7.4, 3.6, "Peel", rot=(12, 0, side * 10)),
        block(side * 5.4, CY - 0.2, -1.7, 0.5, 6.6, 3.2, "Banana", rot=(12, 0, side * 10)),
        block(side * 3.0, CY + 4.2, -1.6, 3.4, 0.8, 3.2, "Peel", rot=(12, 0, side * 24)),
        block(side * 3.1, CY + 4.5, -1.5, 3.0, 0.5, 2.8, "Banana", rot=(12, 0, side * 24)),
    ]

HY, HZ = CY + 6.4, -6.0  # the head
head = [
    block(0, HY, HZ, 9.0, 7.6, 7.4, "White"),  # a round white head
    block(0, HY, HZ, 8.0, 8.6, 6.6, "White"),
    block(0, HY - 2.0, HZ - 3.95, 3.6, 2.6, 1.0, "White"),  # its muzzle...
    block(0, HY - 1.1, HZ - 4.5, 1.8, 1.0, 0.6, "Black"),  # ...a black nose...
    plate(0, HY - 2.6, HZ - 4.5, 1.4, 0.3, "Black", depth=0.15),  # ...a little smile
]
head += both(
    block(3.6, HY + 4.4, HZ + 1.0, 2.6, 2.6, 1.6, "Black"),  # black ears
    plate(2.0, HY + 0.3, HZ - 3.75, 2.4, 3.2, "Black", depth=0.3, rot=(0, 0, -25)),  # drooping eye patches...
    plate(1.9, HY + 0.5, HZ - 3.95, 1.0, 1.0, "Eye", depth=0.2),  # ...with dark eyes
    plate(1.7, HY + 0.75, HZ - 4.1, 0.35, 0.35, "Glint", depth=0.1),
    plate(3.0, HY - 1.4, HZ - 3.75, 1.0, 0.6, "Blush", depth=0.2),
)

arms = []
for x in (-2.6, 2.6):  # black front legs
    arms += [
        block(x, 4.6, -3.6, 3.0, 7.6, 3.0, "Black"),
        block(x, 0.8, -4.0, 3.2, 1.6, 3.6, "Black"),
        plate(x, 0.6, -5.85, 2.2, 0.5, "Pad", depth=0.1),
    ]

legs = []
for x in (-2.8, 2.8):  # black back legs
    legs += [
        block(x, 4.0, 5.4, 2.8, 6.4, 3.2, "Black"),
        block(x, 0.8, 4.8, 3.4, 1.6, 4.4, "Black"),
    ]

ART = {
    "Comment": "Pandaccini Bananini: a panda coming out of a big peeled banana that curves up to a brown stem behind it, peel flaps over its shoulders, a round white head with black ears and eye patches, black legs.",
    "VoxelSize": 0.2,
    "Palette": {
        "Banana": (250, 214, 52),
        "Peel": (250, 238, 190),
        "Ridge": (226, 186, 40),
        "Spot": (120, 80, 40),
        "Stem": (96, 66, 36),
        "White": (246, 246, 242),
        "Black": (34, 34, 38),
        "Eye": (20, 20, 24),
        "Glint": (250, 250, 250),
        "Blush": (246, 190, 196),
        "Pad": (70, 66, 70),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
