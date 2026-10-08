# Perochello Lemonchello (art v2, blocks): a lemon bird, after the original meme image (by
# @alexey_pigeon): a round yellow canary whose belly is a lemon cut open (a yellow rind, a
# white pith ring, pale segments), a curly yellow crest, a grey hooked beak, big round
# eyes; its "arms" are raised wings in red, orange and yellow; a long yellow tail; thin grey
# legs with three toes.
import math

from voxel_art import block, both, plate, rod

CY = 13.0  # the body's middle
F = -4.8  # the lemon's face

body = [
    block(0, CY, 0, 10, 10, 9, "Yellow"),  # a round yellow body
    block(0, CY, 0, 8.6, 12, 8, "Yellow"),
    block(0, CY, 0, 11, 8, 7.6, "Yellow"),
    plate(0, CY, F, 8.4, 6.4, "Rind", depth=0.6),  # the lemon cut open: its rind...
    plate(0, CY, F, 6.4, 8.4, "Rind", depth=0.6),
    plate(0, CY, F - 0.2, 7.4, 5.6, "Pith", depth=0.6),  # ...white pith...
    plate(0, CY, F - 0.2, 5.6, 7.4, "Pith", depth=0.6),
    plate(0, CY, F - 0.4, 6.6, 5.0, "Flesh", depth=0.6),  # ...pale segments
    plate(0, CY, F - 0.4, 5.0, 6.6, "Flesh", depth=0.6),
    plate(0, CY, F - 0.65, 0.9, 0.9, "Pith", depth=0.3),
]
for k in range(8):  # the segments' white lines
    a = k * 45
    body.append(plate(math.sin(math.radians(a)) * 1.6, CY + math.cos(math.radians(a)) * 1.6, F - 0.65, 0.3, 2.6, "Pith", depth=0.3, rot=(0, 0, -a)))
body += [  # a long tail of yellow and orange plumes
    rod((0, CY - 2.0, 4.0), (0, CY - 5.0, 9.6), 2.4, "Yellow"),
    rod((1.2, CY - 2.0, 4.0), (2.4, CY - 4.4, 9.0), 1.6, "Orange"),
    rod((-1.2, CY - 2.0, 4.0), (-2.4, CY - 4.4, 9.0), 1.6, "Orange"),
]

head = [
    block(0, CY + 8.2, -0.6, 7.0, 6.0, 6.4, "Yellow"),  # the head...
    block(0, CY + 8.2, -0.6, 6.0, 6.8, 5.6, "Yellow"),
    block(0, CY + 7.6, -4.8, 2.4, 2.4, 2.4, "Beak"),  # ...a grey hooked beak
    block(0, CY + 6.2, -5.6, 1.6, 1.6, 1.0, "Beak"),
    rod((0, CY + 11.4, -0.6), (0.4, CY + 13.4, 0.4), 0.8, "Yellow"),  # a curly crest
    rod((0.4, CY + 13.4, 0.4), (1.6, CY + 14.2, -0.6), 0.7, "Yellow"),
    rod((1.6, CY + 14.2, -0.6), (1.8, CY + 13.4, -1.4), 0.6, "Yellow"),
    rod((0, CY + 11.4, -0.2), (-1.0, CY + 12.8, 0.8), 0.6, "Yellow"),
]
head += both(
    plate(2.0, CY + 9.4, -3.95, 2.0, 2.0, "White", depth=0.2),  # big round eyes
    plate(2.0, CY + 9.4, -4.15, 1.3, 1.3, "Dark", depth=0.2),
    plate(1.8, CY + 9.8, -4.3, 0.45, 0.45, "Glint", depth=0.1),
    plate(2.6, CY + 7.0, -3.95, 1.2, 0.8, "Cheek", depth=0.15),
)

arms = []
for s in (-1, 1):  # raised wings, feathers fanning up and out
    arms += [
        block(s * 6.0, CY + 1.6, 0.4, 1.4, 5.0, 5.0, "Red"),
        block(s * 7.2, CY + 4.6, 0.4, 1.2, 6.4, 4.4, "Red", rot=(0, 0, -s * 20)),
        block(s * 8.6, CY + 7.2, 0.6, 1.0, 6.0, 3.4, "Orange", rot=(0, 0, -s * 32)),
        block(s * 9.8, CY + 9.2, 0.8, 0.9, 5.0, 2.6, "Yellow", rot=(0, 0, -s * 44)),
        block(s * 7.8, CY + 1.8, 0.6, 1.0, 5.4, 3.0, "Orange", rot=(0, 0, -s * 62)),
    ]


def leg(x):
    return [
        rod((x, CY - 4.4, 0.6), (x, 1.0, 0.0), 1.0, "Leg"),  # a thin grey leg...
        block(x, 1.0, 0.0, 1.4, 1.2, 1.4, "Leg"),
        rod((x, 0.6, 0.0), (x - 1.2, 0.5, -2.6), 0.7, "Leg"),  # ...three toes forward, one back
        rod((x, 0.6, 0.0), (x, 0.5, -3.0), 0.7, "Leg"),
        rod((x, 0.6, 0.0), (x + 1.2, 0.5, -2.6), 0.7, "Leg"),
        rod((x, 0.6, 0.0), (x, 0.5, 1.8), 0.7, "Leg"),
    ]


legs = leg(-2.2) + leg(2.2)

ART = {
    "Comment": "Perochello Lemonchello: a round yellow canary whose belly is a lemon cut open, raised red-orange-yellow wings, a curly crest, a grey hooked beak, thin grey legs.",
    "VoxelSize": 0.2,
    "Palette": {
        "Yellow": (252, 214, 48),
        "Rind": (240, 186, 20),
        "Pith": (252, 248, 226),
        "Flesh": (255, 236, 120),
        "Orange": (250, 150, 30),
        "Red": (232, 70, 40),
        "Beak": (130, 134, 146),
        "White": (250, 250, 250),
        "Dark": (24, 22, 26),
        "Glint": (245, 245, 245),
        "Cheek": (250, 170, 90),
        "Leg": (140, 144, 156),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
