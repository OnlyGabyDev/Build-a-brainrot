# Cacto Hipopotamo (art v2, blocks): a cactus hippo, after the original meme image (by
# @ofuscabreno): a tall green ribbed cactus with pale spines, a grey-pink hippo's head
# poking out of its front near the top (a wide muzzle, nostrils on top, little ears), two
# short green feet in big brown sandals with buckles; its "arms" are two little cactus
# branches (the original is a plain column: these are ours).
from voxel_art import block, both, plate

TOP = 24.0  # the cactus's top

body = [
    block(0, 15, 0, 9, 18, 9, "Cactus"),  # the column, round from stepped blocks
    block(0, 15, 0, 10.6, 17, 7, "Cactus"),
    block(0, 15, 0, 7, 17, 10.6, "Cactus"),
    block(0, TOP - 0.2, 0, 7, 1.2, 7, "Cactus"),  # its rounded top
    block(0, TOP + 0.4, 0, 5, 1.0, 5, "Cactus"),
]
for x in (-2.0, 0.0, 2.0):  # darker ribs down every side, dotted with spines
    body.append(block(x, 15, -5.4, 0.8, 16, 0.4, "Rib"))
    body.append(block(x, 15, 5.4, 0.8, 16, 0.4, "Rib"))
    body += both(block(5.4, 15, x, 0.4, 16, 0.8, "Rib"))
    for y in (8.4, 11.8, 15.2, 18.6, 22.0):
        if not (abs(x) < 3 and 13.0 < y < 22.5):  # (none on the hippo's face)
            body.append(block(x, y, -5.8, 0.3, 0.3, 0.6, "Spine"))
        body.append(block(x + 0.6, y + 1.7, 5.8, 0.3, 0.3, 0.6, "Spine"))
        body += both(block(5.8, y + (1.7 if x else 0), x, 0.6, 0.3, 0.3, "Spine"))

head = [
    block(0, 18.4, -6.4, 7.6, 6.0, 3.0, "Hippo"),  # the hippo's head, out of the cactus...
    block(0, 15.6, -8.0, 8.2, 3.8, 3.4, "HippoLight"),  # ...its wide muzzle
    block(0, 17.3, -8.0, 7.0, 0.8, 3.0, "HippoLight"),
    plate(0, 14.1, -9.75, 5.6, 0.35, "Dark", depth=0.2),  # a long mouth
]
head += both(
    block(2.0, 17.75, -8.6, 1.2, 0.5, 1.0, "Nostril"),  # nostrils on top
    plate(2.4, 19.6, -7.95, 1.2, 1.2, "Dark", depth=0.2),  # eyes
    plate(2.1, 19.9, -8.1, 0.4, 0.4, "Glint", depth=0.1),
    block(3.0, 21.7, -6.0, 1.4, 1.2, 1.0, "Hippo"),  # little ears
    block(3.0, 21.7, -6.55, 0.8, 0.6, 0.2, "Ear"),
)

arms = []
for s in (-1, 1):  # little cactus branches, out then up
    arms += [
        block(s * 6.6, 12.0, 0, 3.0, 2.6, 2.6, "Cactus"),
        block(s * 7.6, 14.6, 0, 2.6, 5.6, 2.6, "Cactus"),
        block(s * 7.6, 17.5, 0, 2.0, 0.6, 2.0, "Cactus"),
        block(s * 7.6, 14.6, -1.4, 0.6, 4.8, 0.3, "Rib"),
        block(s * 8.95, 13.4, 0, 0.3, 0.3, 0.6, "Spine"),
        block(s * 8.95, 16.0, 0, 0.3, 0.3, 0.6, "Spine"),
        block(s * 7.6, 12.0, -1.45, 0.3, 0.3, 0.6, "Spine"),
    ]


def foot(x):
    return [
        block(x, 4.6, 0.4, 3.4, 2.8, 3.4, "Cactus"),  # a short green leg...
        block(x, 2.2, -0.6, 3.8, 2.2, 5.4, "Cactus"),  # ...a green foot...
        block(x, 0.6, -0.6, 4.8, 1.2, 7.2, "Sole"),  # ...in a big brown sandal
        block(x, 2.0, -1.9, 4.4, 1.4, 1.6, "Strap"),
        block(x, 2.6, 0.9, 4.4, 1.4, 1.6, "Strap"),
        block(x + 1.9, 2.0, -1.9, 0.6, 0.8, 0.8, "Buckle"),
        block(x + 1.9, 2.6, 0.9, 0.6, 0.8, 0.8, "Buckle"),
    ] + [block(x + dx, 1.8, -3.6, 0.9, 1.0, 0.8, "Cactus") for dx in (-1.3, 0, 1.3)] + [
        plate(x + dx, 2.1, -4.05, 0.6, 0.5, "Nail", depth=0.15) for dx in (-1.3, 0, 1.3)
    ]


legs = foot(-2.6) + foot(2.6)

ART = {
    "Comment": "Cacto Hipopotamo: a tall ribbed green cactus with spines, a hippo's head poking out of its front, little cactus branches, green feet in big brown sandals.",
    "VoxelSize": 0.2,
    "Palette": {
        "Cactus": (86, 156, 74),
        "Rib": (56, 116, 52),
        "Spine": (244, 236, 196),
        "Hippo": (150, 132, 150),
        "HippoLight": (186, 160, 172),
        "Nostril": (90, 70, 84),
        "Ear": (214, 150, 160),
        "Dark": (28, 24, 28),
        "Glint": (245, 245, 245),
        "Sole": (196, 130, 70),
        "Strap": (150, 86, 44),
        "Buckle": (220, 200, 150),
        "Nail": (230, 220, 200),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
