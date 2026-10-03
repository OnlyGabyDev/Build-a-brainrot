# Tung Tung Tung Sahur (art v2, blocks): a tall wooden log with a face, built like Steal
# a Brainrot's model from clean blocks: a tall plank-log (darker grain strips down its
# sides and back, a bevelled top), a flat face on its top third (big white eyes with dark
# pupils and glints, arched brows, a block nose, a smirk); long thin wooden arms and legs,
# bare feet, a baseball bat in its right hand resting point-down on the ground.
# References: the original image (Wikipedia) and Steal a Brainrot's render.
from voxel_art import block, both, plate, rod

W, D = 8.4, 6.8  # the log's width and depth
FRONT = -D / 2

body = [block(0, 20, 0, W, 10, D, "Wood")]
head = [
    block(0, 30.25, 0, W, 10.5, D, "Wood"),
    block(0, 35.8, 0, W - 1, 0.6, D - 1, "Wood"),  # a bevelled top
]
# wood grain: darker strips down the sides and the back
for x, y0, y1 in ((-2.5, 15.5, 24.5), (1.0, 17, 25), (3.0, 15, 22)):
    body.append(plate(x, (y0 + y1) / 2, D / 2, 0.6, y1 - y0, "Grain", depth=0.8))
for x, y0, y1 in ((-3, 25.5, 34), (0.5, 27, 35), (2.5, 25, 31)):
    head.append(plate(x, (y0 + y1) / 2, D / 2, 0.6, y1 - y0, "Grain", depth=0.8))
body += both(block(W / 2, 20, -1, 0.8, 8, 0.6, "Grain"))
head += both(block(W / 2, 30, 1, 0.8, 7, 0.6, "Grain"))

head += both(
    plate(1.9, 30.8, FRONT - 0.1, 2.4, 2.8, "White", depth=0.8),  # big eyes
    plate(1.6, 30.6, FRONT - 0.4, 1.2, 1.5, "Pupil", depth=0.8),
    plate(1.35, 31.0, FRONT - 0.75, 0.45, 0.45, "White", depth=0.5),  # glints
    plate(1.9, 33.2, FRONT - 0.1, 2.8, 0.6, "Brow", depth=1.0, rot=(0, 0, -10)),  # arched brows
)
head += [
    block(0, 28.6, FRONT - 0.5, 1.4, 2.2, 1.0, "Wood"),  # the nose
    plate(0, 27.5, FRONT - 1.0, 1.4, 0.3, "Grain", depth=0.1),
    plate(-0.4, 26.4, FRONT - 0.1, 3.2, 0.5, "Mouth", depth=1.0),  # a smirk, up at its right end
    plate(1.6, 26.8, FRONT - 0.1, 1.2, 0.5, "Mouth", depth=1.0, rot=(0, 0, 30)),
]

arms = [
    rod((-4.9, 23.6, 0), (-5.3, 15.2, -0.2), 1.5, "Wood"),  # the left arm hangs relaxed
    block(-5.3, 14.4, -0.3, 1.8, 2, 1.8, "Wood"),
    rod((4.9, 23.6, 0), (5.2, 15.6, -0.6), 1.5, "Wood"),  # the right arm holds the bat
    block(5.3, 14.8, -0.8, 2, 2, 2, "Wood"),
    rod((5.4, 16.6, -0.4), (5.9, 9.4, -3.0), 1.0, "Bat", shape="Cylinder"),  # the bat's handle...
    rod((5.9, 9.4, -3.0), (6.5, 1.4, -6.3), 2.0, "Bat", shape="Cylinder"),  # ...and its barrel
    block(5.4, 16.9, -0.3, 1.4, 0.6, 1.4, "BatDark"),  # the knob
]

legs = []
for x in (-2.2, 2.2):
    legs += [
        rod((x, 15, 0), (x, 1.6, -0.4), 1.9, "Wood"),  # long thin legs
        block(x, 0.8, -1.4, 2.6, 1.6, 4.2, "Wood"),  # bare feet
        plate(x, 0.9, -3.55, 2.2, 1.0, "Grain", depth=0.1),
    ]

ART = {
    "Comment": "Tung Tung Tung Sahur: a tall wooden log with a face (blocks), thin arms and legs, bare feet, a baseball bat in its right hand.",
    "VoxelSize": 0.2,
    "Palette": {
        "Wood": (214, 140, 78),
        "Grain": (184, 112, 58),
        "White": (250, 250, 245),
        "Pupil": (30, 22, 18),
        "Brow": (85, 48, 28),
        "Mouth": (120, 52, 40),
        "Bat": (232, 182, 112),
        "BatDark": (150, 100, 55),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
