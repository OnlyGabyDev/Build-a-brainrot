# Spioniro Golubiro (art v2, blocks): a spy pigeon, after the original meme image (by
# @dontmakemeobvious): a dark grey pigeon standing like a person in a tan trench coat (the
# collar turned up, a belt, buttons), big black sunglasses on its pale grey head, a dark
# beak with a white cere, a black camera with a silver top and a big lens hanging on a strap
# over its chest; its "arms" are the coat's sleeves, hands in its pockets; pink pigeon feet
# out under the coat.
from voxel_art import block, both, plate, rod, solid

body = [
    block(0, 11.6, 0, 9.0, 12.4, 7.0, "Coat"),  # the trench coat...
    block(0, 6.9, 0, 9.6, 3.4, 7.6, "Coat"),  # ...flaring at the hem
    block(0, 11.0, 0, 9.3, 1.0, 7.3, "CoatDark"),  # the belt...
    plate(0, 10.9, -3.75, 1.4, 1.0, "Buckle", depth=0.3),  # ...and its buckle
    plate(0, 16.3, -3.6, 2.6, 3.0, "Feather", depth=0.2),  # its dark chest in the coat's V
    block(0, 17.6, 0, 5.4, 1.4, 5.2, "Feather"),  # its neck
]
body += both(
    plate(1.7, 15.4, -3.65, 1.4, 5.0, "CoatDark", depth=0.3, rot=(0, 0, 15)),  # lapels
    block(2.7, 18.6, 0.2, 1.4, 3.6, 5.0, "Coat", rot=(0, 0, -18)),  # the collar turned up
    plate(2.2, 8.4, -3.9, 0.6, 0.6, "Button", depth=0.2),  # buttons
    plate(2.8, 9.6, -3.65, 2.4, 0.8, "CoatDark", depth=0.3),  # pocket flaps
)
body += [  # the camera on its strap
    block(0, 12.8, -4.3, 4.4, 2.6, 1.4, "Camera"),
    block(0, 14.25, -4.3, 4.0, 0.5, 1.2, "Silver"),
    block(1.3, 14.7, -4.3, 0.8, 0.6, 0.8, "Silver"),  # the shutter button
    solid("Cylinder", 0, 12.7, -5.4, 1.2, 2.2, 2.2, "Silver", rot=(0, 90, 0)),  # the lens...
    solid("Cylinder", 0, 12.7, -5.95, 0.2, 1.4, 1.4, "Lens", rot=(0, 90, 0)),
    plate(-1.4, 13.6, -5.05, 0.8, 0.5, "Lens", depth=0.1),  # ...the viewfinder
    rod((1.9, 13.6, -4.2), (2.4, 17.6, -2.6), 0.4, "Camera"),  # the strap
    rod((-1.9, 13.6, -4.2), (-2.4, 17.6, -2.6), 0.4, "Camera"),
]

HY = 21.4  # the head
head = [
    block(0, HY, -0.3, 6.4, 6.0, 6.0, "Pigeon"),  # a dark grey head...
    block(0, HY + 3.1, 0, 5.8, 1.4, 5.6, "PigeonTop"),  # ...paler on top
    block(0, HY + 2.3, -0.1, 6.6, 0.8, 6.0, "PigeonTop"),
    block(0, HY - 1.4, -3.7, 1.4, 1.2, 1.4, "Beak"),  # a dark beak...
    block(0, HY - 0.5, -3.65, 1.2, 0.6, 1.0, "Cere"),  # ...with a white cere
    plate(0, HY + 0.9, -3.65, 1.2, 0.5, "Shades", depth=0.4),  # sunglasses' bridge
]
head += both(
    plate(1.7, HY + 0.6, -3.65, 2.8, 2.0, "Shades", depth=0.4),  # big black sunglasses...
    plate(2.3, HY + 1.0, -3.9, 0.8, 0.3, "Shine", depth=0.1, rot=(0, 0, 30)),  # ...a shine
    block(3.35, HY + 1.0, -1.6, 0.3, 0.4, 3.8, "Shades"),  # ...their arms
)

arms = []
for s in (-1, 1):  # the coat's sleeves, hands in its pockets
    arms += [
        block(s * 4.8, 16.6, 0.2, 2.6, 2.6, 3.8, "Coat"),  # a shoulder
        rod((s * 5.0, 16.8, 0.4), (s * 5.6, 12.6, 0.9), 2.4, "Coat"),
        rod((s * 5.6, 12.6, 0.9), (s * 3.9, 9.6, -2.6), 2.2, "Coat"),
        rod((s * 4.5, 10.8, -1.4), (s * 4.0, 9.8, -2.4), 2.3, "CoatDark"),  # a cuff
    ]

legs = []
for x in (-1.7, 1.7):  # pink pigeon feet
    legs += [
        rod((x, 7.0, 0), (x, 1.0, 0), 1.0, "Foot"),
        rod((x, 0.5, 0), (x, 0.4, -2.4), 0.6, "Foot"),  # toes
        rod((x, 0.5, 0), (x - 1.2, 0.4, -2.0), 0.6, "Foot"),
        rod((x, 0.5, 0), (x + 1.2, 0.4, -2.0), 0.6, "Foot"),
        rod((x, 0.5, 0), (x, 0.4, 1.4), 0.6, "Foot"),
    ]

ART = {
    "Comment": "Spioniro Golubiro: a dark grey pigeon in a tan trench coat with the collar up, big black sunglasses, a camera on a strap over its chest, sleeves with hands in its pockets, pink pigeon feet.",
    "VoxelSize": 0.2,
    "Palette": {
        "Coat": (186, 112, 62),
        "CoatDark": (140, 80, 44),
        "Buckle": (210, 180, 110),
        "Button": (70, 46, 30),
        "Feather": (54, 56, 66),
        "Pigeon": (70, 72, 84),
        "PigeonTop": (150, 156, 168),
        "Beak": (52, 52, 58),
        "Cere": (232, 232, 236),
        "Shades": (18, 18, 22),
        "Shine": (200, 210, 230),
        "Camera": (26, 26, 30),
        "Silver": (196, 200, 208),
        "Lens": (60, 90, 130),
        "Foot": (214, 96, 104),
    },
    "Materials": {"Silver": "Metal"},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
