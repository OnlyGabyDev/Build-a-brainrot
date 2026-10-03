# Brr Brr Patapim (art v2): a tall forest creature under a mossy green hood: a beige
# proboscis-monkey face with a long droopy nose and yellow eyes, a white beard down its
# chest, moss over its back and shoulders and round its thighs, long thin bare arms and
# legs, big bare feet. Reference: Steal a Brainrot's render.
from voxel_art import ball, box, both, chain, cylinder, paint

legs = []
for x in (-2.2, 2.2):
    legs += [
        cylinder(x, 0, 1.2, 1.2, 2, 14, "Skin"),  # long thin legs
        ball(x, 8, 0, 1.4, 1.4, 1.4, "Skin"),  # knees
        ball(x, 13.2, 0, 1.9, 2.3, 1.9, "Moss"),  # moss round the thighs
        ball(x, 1.1, -1.6, 1.8, 1.1, 2.8, "Skin"),  # big bare feet
        box(x - 1.7, 0, -3.8, x + 1.7, 0.8, 0.8, "Skin"),
        paint(box(x - 0.5, 0, -5, x + 0.5, 1.6, -3.4, "Toe")),
    ]
legs += [paint(ball(x, 13.5, -1.2, 1, 1, 1, "MossDark")) for x in (-2.6, 1.8)]

body = [
    ball(0, 20.5, 0, 4.2, 5, 3.4, "Skin"),
    paint(box(-6, 15, 0.5, 6, 26, 5, "Moss")),  # moss over the back...
    paint(box(3, 15, -5, 6, 26, 5, "Moss")),  # ...and the sides
    paint(box(-6, 15, -5, -3, 26, 5, "Moss")),
    paint(box(-2.5, 17, -5, 2.5, 26, -1, "Fur")),  # the beard down the chest
]
for x, y in ((-2, 18), (2, 22), (0, 24), (-3, 22), (3, 18)):
    body.append(paint(ball(x, y, 3.2, 1.2, 1.2, 1.2, "MossDark")))  # leafy clumps

head = [
    ball(0, 31.2, 0.5, 5.2, 6.2, 4.6, "Moss"),  # the mossy hood
    ball(0, 30, -2.6, 3.0, 4.0, 2.2, "Skin"),  # the face peeking out
    ball(0, 27.6, -2.8, 3, 1.5, 2, "Fur"),  # the beard's top
    paint(box(-3, 32, -6, -1, 34, -3, "Eye")),  # yellow eyes, dark pupils
    paint(box(1, 32, -6, 3, 34, -3, "Eye")),
    paint(box(-2, 32, -6, -1, 33, -3, "Pupil")),
    paint(box(1, 32, -6, 2, 33, -3, "Pupil")),
    paint(box(-3, 34, -6, 3, 35, -2.5, "Brow")),
]
head += chain((0, 30.6, -4.6), (0, 26.8, -5.4), 1.0, 1.45, "Nose")  # the long droopy nose
head.append(paint(box(-1, 26, -8, 1, 27, -6, "Nostril")))
for x, y, z in ((-3, 34, 1), (2, 35, 2), (3.5, 30, 2), (-3.5, 29, 2), (0, 36, 0)):
    head.append(paint(ball(x, y, z, 1.4, 1.4, 1.4, "MossDark")))

arms = both(
    ball(4.7, 24, 0.3, 1.5, 1.5, 1.5, "Moss"),  # leafy shoulders
    cylinder(5.1, 0, 0.85, 0.85, 10.5, 23, "Skin"),  # long thin arms
    ball(5.2, 9.8, -0.3, 1.2, 1.5, 1.1, "Skin"),  # big hands
)

ART = {
    "Comment": "Brr Brr Patapim: a tall forest creature under a mossy hood, a long droopy nose, a white beard, long bare limbs and big feet.",
    "VoxelSize": 0.2,
    "Palette": {
        "Moss": (70, 165, 75),
        "MossDark": (40, 120, 55),
        "Skin": (238, 196, 150),
        "Toe": (205, 160, 120),
        "Fur": (246, 242, 232),
        "Eye": (255, 214, 40),
        "Pupil": (25, 20, 15),
        "Brow": (120, 85, 60),
        "Nose": (226, 176, 132),
        "Nostril": (120, 70, 50),
    },
    "Joints": {"Head": (0, 31, 0)},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
