# Bananita Dolphinita (art v2, blocks): a dolphin in a peeled banana, after the original
# meme image (by @alexey_pigeon): a blue-grey dolphin's head (a long beak, a smile, a pale
# throat, a swept-back fin on top) rising out of a standing banana, its cream flesh showing
# round the opening; its "arms" are two peel flaps hanging down at its sides (a third
# hangs behind); the banana's curled bottom with a brown tip is what it stands on.
from voxel_art import block, both, plate, wedge

legs = [
    block(0, 5.0, -0.4, 6.0, 6.4, 6.0, "Banana", rot=(-8, 0, 0)),  # the banana's bottom...
    block(0, 1.4, -1.4, 4.2, 2.4, 4.2, "BananaDark", rot=(-16, 0, 0)),
    block(0, 0.6, -2.8, 2.0, 1.2, 2.2, "Tip"),  # ...its brown tip
]

body = [
    block(0, 10.6, 0, 7, 5.2, 7, "Banana"),  # the banana, still in its peel below...
    block(0, 15.6, 0, 5.8, 4.8, 5.8, "Flesh"),  # ...its cream flesh standing out of it
    block(0, 13.0, 0, 6.2, 0.4, 6.2, "FleshDark"),
]
body += both(block(3.55, 10.6, -3.55, 0.3, 5.2, 0.3, "BananaDark"))  # its ridges
body += both(block(3.55, 10.6, 3.55, 0.3, 5.2, 0.3, "BananaDark"))
for z, tilt in ((-4.7, -28), (4.7, 28)):  # peel flaps curling up and out, front and back
    body += [
        block(0, 16.4, z, 4.4, 7.6, 0.9, "Banana", rot=(tilt, 0, 0)),
        block(0, 16.5, z * 0.9, 3.8, 7.0, 0.4, "Flesh", rot=(tilt, 0, 0)),
        block(0, 20.0, z * 1.38, 3.2, 1.0, 1.4, "Tip", rot=(tilt * 1.6, 0, 0)),
    ]

arms = both(  # the side flaps: yellow out, cream in, brown at the ends
    block(4.7, 16.4, 0, 0.9, 7.6, 4.4, "Banana", rot=(0, 0, -28)),
    block(4.25, 16.5, 0, 0.4, 7.0, 3.8, "Flesh", rot=(0, 0, -28)),
    block(6.5, 20.0, 0, 1.4, 1.0, 3.2, "Tip", rot=(0, 0, -45)),
)

head = [
    block(0, 21.2, 0.2, 5.8, 6.4, 6.0, "Dolphin"),  # the dolphin's head...
    block(0, 24.8, 0.6, 4.6, 1.2, 4.6, "Dolphin"),
    block(0, 22.6, -3.4, 4.4, 3.4, 1.4, "Dolphin"),  # ...its round forehead...
    block(0, 21.0, -6.0, 2.6, 1.8, 4.4, "Dolphin"),  # ...a long beak
    block(0, 20.3, -5.8, 2.8, 0.5, 4.6, "Belly"),
    plate(0, 19.6, -2.75, 4.0, 2.4, "Belly", depth=0.4),  # a pale throat
    wedge(0, 26.9, 1.8, 0.9, 3.0, 3.6, "Dolphin"),  # the swept-back fin
]
head += both(
    plate(2.95, 22.4, -2.0, 1.0, 1.0, "Dark", depth=0.3, rot=(0, 90, 0)),  # eyes on its sides
    plate(3.05, 22.6, -2.2, 0.35, 0.35, "White", depth=0.1, rot=(0, 90, 0)),
    block(1.42, 20.7, -6.0, 0.2, 0.25, 3.8, "Dark"),  # its smile
)

ART = {
    "Comment": "Bananita Dolphinita: a blue-grey dolphin rising out of a peeled banana, two peel flaps hanging at its sides, a brown tip at the bottom.",
    "VoxelSize": 0.2,
    "Palette": {
        "Banana": (250, 214, 60),
        "BananaDark": (226, 178, 38),
        "Flesh": (250, 240, 196),
        "FleshDark": (232, 214, 160),
        "Tip": (106, 72, 40),
        "Dolphin": (118, 136, 156),
        "Belly": (210, 216, 224),
        "Dark": (25, 22, 26),
        "White": (250, 250, 250),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
