# Boneca Ambalabu (art v2): a frog head (dark green, bulging eyes on top, a beige jaw
# with brown stripes) on a big upright black tire (its hole goes through side to side),
# on skinny bare human legs with long toes; skinny arms poke out of the tire's sides.
# Reference: Steal a Brainrot's render.
import math

from voxel_art import ball, block, box, both, carve, paint, plate, rod

TIRE_Y, TIRE_R, TREAD = 17, 6, 2.5

body = []
for k in range(28):  # the tire: a ring of balls round its axle (along X)
    a = k / 28 * math.pi * 2
    body.append(ball(0, TIRE_Y + math.sin(a) * TIRE_R, math.cos(a) * TIRE_R, 2.8, TREAD, TREAD, "Tire"))
for k in range(14):  # the tread, across it
    a = (k + 0.5) / 14 * math.pi * 2
    y, z = TIRE_Y + math.sin(a) * (TIRE_R + 1.6), math.cos(a) * (TIRE_R + 1.6)
    body.append(paint(box(-4, y - 0.5, z - 0.5, 4, y + 0.5, z + 0.5, "Tread")))

tire_bottom = ball(0, TIRE_Y - TIRE_R, 0, 2.8, TREAD, TREAD, "Tire")

legs = []
for x in (-1.6, 1.6):
    legs += [
        rod((x, 10.8, 0), (x, 1.2, -0.3), 1.5, "Skin"),  # skinny legs
        block(x, 5.6, -0.1, 1.9, 1.6, 1.9, "Skin"),  # knobby knees
        block(x, 0.6, -1.2, 2.4, 1.2, 3.2, "Skin"),  # feet...
    ]
    for dx in (-0.7, 0.7):
        legs.append(rod((x + dx, 0.5, -2.6), (x + dx * 1.5, 0.4, -4.8), 0.7, "Skin"))  # ...with long toes
legs += [carve(tire_bottom)]

arms = []
for side in (-1, 1):
    arms.append(rod((side * 2.9, 15, -1), (side * 5.6, 11, -1.5), 1.1, "Skin"))  # skinny arms
    arms.append(block(side * 5.8, 10.4, -1.6, 1.6, 1.8, 1.6, "Skin"))

head = [
    block(0, 28.8, -0.4, 8.6, 5.2, 8.2, "Frog"),  # the frog's head (blocks)
    block(0, 26.6, -0.6, 8.8, 2.4, 8.4, "Jaw"),  # its beige jaw...
]
for x in (-3, -1, 1, 3):
    head.append(plate(x, 26.6, -4.85, 0.6, 2.2, "Stripe", depth=0.1))  # ...with brown stripes
head += both(
    block(2.4, 32.1, -2.2, 2.6, 1.6, 2.6, "Frog"),  # bulging eyes on top
    plate(2.4, 32.1, -3.55, 1.8, 1.0, "Eye", depth=0.1),
    plate(2.6, 32.1, -3.62, 0.7, 0.8, "Pupil", depth=0.1),
)

ART = {
    "Comment": "Boneca Ambalabu: a striped frog head on an upright black tire, on skinny bare legs with long toes.",
    "VoxelSize": 0.2,
    "Palette": {
        "Tire": (38, 38, 44),
        "Tread": (62, 62, 70),
        "Skin": (238, 196, 160),
        "Frog": (60, 95, 45),
        "Jaw": (225, 205, 165),
        "Stripe": (120, 85, 60),
        "Eye": (250, 230, 120),
        "Pupil": (25, 25, 25),
    },
    "Joints": {"Legs": (0, 10.5, 0), "Head": (0, 28, -0.4)},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
