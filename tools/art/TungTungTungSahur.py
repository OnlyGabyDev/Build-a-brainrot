# Tung Tung Tung Sahur (art v2): a tall, narrow wooden log with a face on its top third
# (big round eyes under heavy brows, a nose, a smirk), long thin wooden arms, a baseball
# bat in its right hand resting point-down on the ground, long thin legs and bare feet.
# References: the original image (Wikipedia) and Steal a Brainrot's render.
from voxel_art import ball, box, both, chain, cylinder, paint

LOG_RX, LOG_RZ = 4.2, 3.4

legs = []
for x in (-2.3, 2.3):
    legs += [
        cylinder(x, 0, 1.05, 1.05, 1, 15, "Wood"),  # long thin legs (up to the log, not into it)
        ball(x, 8, 0, 1.25, 1.3, 1.25, "Wood"),  # knees
        ball(x, 1, -1.3, 1.5, 1.05, 2.4, "Wood"),  # bare feet
        box(x - 1.4, 0, -3.2, x + 1.4, 0.7, 0.9, "Wood"),
        paint(box(x - 0.5, 0, -4.5, x + 0.5, 1.6, -3, "Grain")),  # between the toes
    ]

body = [cylinder(0, 0, LOG_RX, LOG_RZ, 15, 25, "Wood")]
# wood grain down the log, broken up so it reads as grain, not stripes
for x, y0, y1 in ((-3, 15, 21), (-1, 17, 25), (1, 15, 19), (2, 20, 25), (3, 16, 23)):
    body.append(paint(box(x, y0, -5, x + 1, y1, 5, "Grain")))
body.append(paint(box(-5, 15, -5, 5, 16, 5, "Grain")))  # the log's lower rim

head = [
    cylinder(0, 0, LOG_RX, LOG_RZ, 25, 34, "Wood"),
    ball(0, 33.6, 0, LOG_RX, 2.6, LOG_RZ, "Wood"),  # the rounded top
]
for x, y0, y1 in ((-3, 25, 32), (-1, 26, 35), (2, 25, 33), (3, 27, 34)):
    head.append(paint(box(x, y0, 0, x + 1, y1, 5, "Grain")))  # grain on the back and sides only
head += both(
    ball(1.9, 30.5, -3.0, 1.6, 1.9, 0.75, "White"),  # big round eyes
    ball(1.7, 30.7, -3.7, 0.95, 1.1, 0.5, "Pupil"),
    paint(box(2, 31, -5, 3, 32, -3, "White")),  # a glint in each
    paint(box(0.9, 32.9, -5, 1.8, 33.7, -2, "Brow")),  # arched brows, on the log's face
    paint(box(1.8, 33.3, -5, 3.5, 34.1, -1.8, "Brow")),
)
head += [
    ball(0, 28.6, -3.4, 0.9, 1.4, 1.0, "Wood"),  # the nose
    paint(box(-1, 27.4, -5, 1, 28, -3.4, "Grain")),
    paint(box(-2.2, 26.4, -5, 1.6, 27.2, -2.5, "Mouth")),  # a smirk, up at its right end
    paint(box(1.6, 27, -5, 2.8, 28, -2.4, "Mouth")),
]

arms = [
    # the left arm hangs relaxed
    ball(-5, 23.2, 0, 1, 1, 1, "Wood"),
    cylinder(-5, 0.2, 0.75, 0.75, 14.8, 23.2, "Wood"),
    ball(-5, 14.2, -0.1, 0.95, 1.25, 1, "Wood"),
    # the right arm holds the bat
    ball(5, 23.2, 0, 1, 1, 1, "Wood"),
    cylinder(5, -0.3, 0.75, 0.75, 15.2, 23.2, "Wood"),
    ball(5.1, 14.6, -0.6, 1.1, 1.25, 1.1, "Wood"),
    ball(5.3, 16.2, -0.4, 0.7, 0.55, 0.7, "Bat"),  # the knob over the hand
]
arms += chain((5.35, 13.8, -0.9), (6.3, 1.4, -5.6), 0.6, 1.3, "Bat", steps=30)
arms.append(paint(box(4, 0, -7, 8, 2.4, -4, "BatDark")))  # the barrel's scuffed end

ART = {
    "Comment": "Tung Tung Tung Sahur: a tall wooden log with a face, thin arms and legs, bare feet, a baseball bat in its right hand.",
    "VoxelSize": 0.2,
    "Palette": {
        "Wood": (214, 140, 78),
        "Grain": (186, 112, 58),
        "White": (250, 250, 245),
        "Pupil": (30, 22, 18),
        "Brow": (85, 48, 28),
        "Mouth": (120, 52, 40),
        "Bat": (232, 182, 112),
        "BatDark": (196, 140, 80),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
