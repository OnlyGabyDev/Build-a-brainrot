# Bandito Bobritto (art v2, blocks): a beaver in a gangster film's coat and hat, after the
# original meme image (by @ai_video_maker_7), made kid-friendly (no gun, no cigar): a brown
# beaver head with a pale muzzle, big buck teeth, a black nose and little ears under a brown
# fedora with a dark band; a long brown trench coat with a belt, open over a dark suit,
# white shirt and black tie; its flat scaly tail behind; coat sleeves and dark paws; short
# legs in dark trousers on big flat beaver feet.
from voxel_art import block, both, plate, rod, wedge

FRONT = -3.2  # the coat's front face

legs = []
for x in (-1.9, 1.9):
    legs += [
        block(x, 4.1, 0, 2.8, 6, 2.8, "Suit"),  # trousers
        block(x * 1.1, 0.6, -1.0, 3.6, 1.2, 5.2, "Paw"),  # big flat feet...
    ]
    for t in (-1.1, 0, 1.1):
        legs.append(block(x * 1.1 + t, 0.5, -3.75, 0.8, 0.8, 0.5, "Claw"))  # ...little claws

body = [
    block(0, 9.0, 0, 9.6, 4, 6.8, "Coat"),  # the coat flares out at the bottom...
    block(0, 15.2, 0, 8.6, 8.4, 6.2, "Coat"),
    block(0, 11.6, 0, 9.0, 1.0, 6.6, "CoatDark"),  # ...a belt...
    block(0, 11.6, FRONT - 0.15, 1.4, 1.2, 0.4, "Buckle"),
    plate(0, 16.6, -3.15, 3.6, 6.4, "Suit", depth=0.4),  # ...open over the suit
    plate(0, 17.6, -3.4, 1.8, 4.4, "Shirt", depth=0.3),
    plate(0, 17.2, -3.6, 0.7, 4.0, "Tie", depth=0.2),
    plate(0, 10.0, FRONT - 0.15, 0.4, 3.2, "CoatDark", depth=0.3),  # where the coat closes below the belt
]
body += both(
    plate(2.3, 16.4, -3.35, 1.4, 6.2, "CoatDark", depth=0.4, rot=(0, 0, -14)),  # wide lapels
    block(4.4, 19.0, 0, 0.6, 0.6, 6.4, "CoatDark"),  # shoulder seams
)
body += [  # the flat scaly tail out the back
    block(0, 4.4, 6.3, 4.4, 1.0, 8.6, "Tail", rot=(40, 0, 0)),
    block(0, 4.78, 6.62, 3.6, 0.2, 7.4, "TailDark", rot=(40, 0, 0)),
]

arms = both(
    rod((4.8, 18.4, 0), (5.6, 11.6, -0.6), 2.6, "Coat"),  # coat sleeves...
    block(5.7, 11.0, -0.7, 2.8, 1.2, 2.8, "CoatDark"),  # ...cuffs
    block(5.7, 9.6, -0.8, 2.0, 1.8, 2.0, "Paw"),  # dark paws
)

head = [
    block(0, 22.6, 0.2, 7.2, 6.4, 6.6, "Fur"),  # the head
    block(0, 21.2, -3.8, 4.4, 3.2, 2.2, "Muzzle"),  # a pale muzzle...
    block(0, 22.6, -5.0, 1.8, 1.2, 0.8, "Nose"),  # ...a black nose
    plate(-0.5, 19.4, -4.95, 0.9, 1.6, "Teeth", depth=0.4),  # big buck teeth
    plate(0.5, 19.4, -4.95, 0.9, 1.6, "Teeth", depth=0.4),
]
head += both(
    plate(1.8, 23.8, -3.0, 1.2, 1.4, "Dark", depth=0.4),  # small dark eyes
    plate(1.55, 24.1, -3.25, 0.4, 0.4, "Glint", depth=0.15),
    block(3.4, 25.4, 0.6, 1.6, 1.6, 1.4, "Fur"),  # little ears
    block(4.0, 21.0, -4.4, 2.4, 0.25, 0.25, "Whisker", rot=(0, 0, 10)),
)
head += [  # the fedora
    block(0, 26.2, 0.2, 10.4, 0.6, 9.6, "Hat"),  # its brim...
    block(0, 26.9, 0.2, 7.0, 1.0, 6.4, "Band"),  # ...a dark band...
    block(0, 28.6, 0.2, 6.8, 2.6, 6.2, "Hat"),  # ...its crown, pinched on top
    block(0, 30.0, 0.2, 2.0, 0.4, 5.0, "HatDark"),
]

ART = {
    "Comment": "Bandito Bobritto: a beaver with buck teeth in a brown fedora and a long trench coat over a dark suit and tie, a flat tail, big flat feet (no gun, no cigar).",
    "VoxelSize": 0.2,
    "Palette": {
        "Fur": (126, 80, 48),
        "Muzzle": (196, 150, 108),
        "Nose": (30, 24, 24),
        "Teeth": (250, 236, 200),
        "Dark": (25, 22, 26),
        "Glint": (240, 240, 240),
        "Whisker": (60, 45, 35),
        "Coat": (150, 100, 58),
        "CoatDark": (112, 72, 40),
        "Buckle": (230, 190, 80),
        "Suit": (45, 44, 52),
        "Shirt": (245, 245, 245),
        "Tie": (25, 25, 30),
        "Paw": (78, 52, 36),
        "Claw": (230, 220, 200),
        "Tail": (96, 66, 46),
        "TailDark": (70, 48, 34),
        "Hat": (120, 84, 54),
        "HatDark": (96, 66, 42),
        "Band": (50, 38, 32),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
