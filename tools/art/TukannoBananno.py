# Tukanno Bananno (art v2, blocks): a banana toucan, after the original meme image (by
# @alexey_pigeon): a black toucan with a bright yellow chest, a big green-ringed eye, and a
# huge beak that is a curved banana (green at its root, brown at the tip); black wings, a
# long black tail, grey-blue feet. Ours: the eye ring glows and the banana shines (a Godly).
from voxel_art import block, both, plate, rod, solid

BY, BZ = 11.0, 1.0  # the body's middle

body = [
    block(0, BY, BZ, 7.6, 9.0, 7.0, "Black"),  # a black toucan...
    block(0, BY + 0.4, BZ - 3.4, 6.4, 7.0, 0.6, "Chest"),  # ...a bright yellow chest
    block(0, BY - 2.8, BZ - 3.2, 5.6, 2.2, 0.6, "ChestDeep"),
    block(0, BY - 4.6, BZ + 0.6, 6.0, 1.2, 5.6, "Black"),
    block(0, BY - 3.0, BZ + 6.2, 3.8, 1.6, 7.0, "Black", rot=(-28, 0, 0)),  # a long black tail
    block(0, BY - 5.2, BZ + 9.0, 3.4, 1.0, 3.0, "Black", rot=(-40, 0, 0)),
]

HY, HZ = BY + 7.0, BZ - 0.8  # the head
head = [
    block(0, HY, HZ, 6.6, 6.0, 6.2, "Black"),  # a black head...
    block(0, HY - 2.0, HZ - 2.6, 5.4, 2.6, 1.4, "Chest"),  # ...a yellow throat
]
head += both(
    solid("Cylinder", 3.25, HY + 0.6, HZ - 0.6, 0.5, 3.6, 3.6, "Ring"),  # a big green-ringed eye...
    solid("Cylinder", 3.5, HY + 0.6, HZ - 0.6, 0.4, 2.4, 2.4, "EyeWhite"),
    solid("Cylinder", 3.7, HY + 0.6, HZ - 0.8, 0.4, 1.4, 1.4, "Pupil"),
    plate(4.0, HY + 1.0, HZ - 1.1, 0.4, 0.4, "EyeWhite", depth=0.1, rot=(0, 90, 0)),
)
B = [(0, HY + 0.2, HZ - 3.0), (0, HY + 0.6, HZ - 6.4), (0, HY + 0.2, HZ - 9.8), (0, HY - 1.0, HZ - 12.6), (0, HY - 2.8, HZ - 14.4)]
widths = [(4.6, 4.2), (4.4, 4.0), (3.8, 3.4), (3.0, 2.6)]
colors = ["Green", "Banana", "Banana", "Banana"]
for k in range(4):  # a huge beak: a curved banana...
    w, h = widths[k]
    a, b = B[k], B[k + 1]
    head.append(rod(a, b, w, colors[k]))
    head.append(solid("Ball", *b, h, h, h, colors[k + 1] if k < 3 else "Banana"))
head += [
    block(0, HY - 3.1, HZ - 14.9, 1.4, 1.4, 1.4, "Tip"),  # ...brown at the tip
    rod((0, HY - 0.9, HZ - 3.6), (0, HY - 1.4, HZ - 11.6), 0.35, "Line"),  # (the beak's gape)
]

arms = []
for s in (-1, 1):  # black wings
    arms += [
        block(s * 4.2, BY + 1.0, BZ + 0.8, 1.2, 7.0, 6.0, "Black", rot=(0, 0, s * 6)),
        block(s * 4.4, BY - 2.6, BZ + 3.0, 1.0, 3.6, 4.0, "Wing", rot=(0, 0, s * 6)),
        block(s * 4.75, BY + 1.6, BZ + 0.8, 0.3, 3.6, 4.0, "Wing", rot=(0, 0, s * 6)),
    ]

legs = []
for s in (-1, 1):  # grey-blue feet
    x = s * 1.8
    legs += [
        block(x, 3.2, BZ + 0.4, 1.2, 4.0, 1.2, "Foot"),
        block(x, 0.6, BZ - 0.8, 1.0, 1.2, 3.2, "Foot"),  # two toes forward...
        block(x + s * 0.9, 0.6, BZ - 0.6, 0.8, 1.2, 2.6, "Foot", rot=(0, -s * 20, 0)),
        block(x, 0.6, BZ + 1.8, 0.9, 1.0, 1.8, "Foot"),  # ...one back
    ]

ART = {
    "Comment": "Tukanno Bananno: a black toucan with a bright yellow chest, a big green-ringed eye and a huge beak that is a curved banana, black wings, a long tail, grey-blue feet.",
    "VoxelSize": 0.24,  # (a Godly: bigger than the rest)
    "Palette": {
        "Black": (30, 30, 34),
        "Wing": (52, 52, 60),
        "Chest": (252, 196, 40),
        "ChestDeep": (246, 150, 40),
        "Ring": (150, 240, 70),
        "EyeWhite": (240, 250, 250),
        "Pupil": (20, 20, 24),
        "Green": (150, 196, 60),
        "Banana": (252, 222, 60),
        "Tip": (100, 66, 34),
        "Line": (180, 140, 40),
        "Foot": (110, 130, 160),
    },
    "Materials": {"Ring": "Neon"},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
