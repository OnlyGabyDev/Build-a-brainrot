# Boneca Ambalabu (art v2): a frog head (dark green, bulging eyes on top, a beige jaw
# with brown stripes) on a big upright black tire (its hole goes through side to side),
# on skinny bare human legs with long toes; skinny arms poke out of the tire's sides.
# Reference: Steal a Brainrot's render.
import math

from voxel_art import ball, box, both, carve, chain, cylinder, paint

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
for x in (-1.5, 1.5):
    legs += [
        cylinder(x, 0, 0.8, 0.8, 1.2, 10.5, "Skin"),  # skinny legs
        ball(x, 6, 0, 1, 1, 1, "Skin"),  # knobby knees
        ball(x, 0.9, -1.2, 1.3, 0.9, 2.2, "Skin"),  # feet
    ]
    for dx in (-0.8, 0.8):
        legs += chain((x + dx, 0.6, -2.6), (x + dx * 1.4, 0.5, -4.6), 0.5, 0.45, "Skin")  # long toes
legs += [carve(tire_bottom)]

arms = []
for side in (-1, 1):
    arms += chain((side * 2.6, 15, -1), (side * 5.5, 11, -1.5), 0.85, 0.8, "Skin", steps=16)  # skinny arms
    arms += [ball(side * 5.8, 10.5, -1.6, 1, 1.1, 1, "Skin")]

head = [
    ball(0, 27.8, -0.5, 4.4, 3.6, 4.2, "Frog"),  # the frog's head
    ball(0, 26, -1.8, 3.8, 1.8, 3.2, "Jaw"),  # its beige jaw...
    paint(box(-4, 23, -7, 4, 27, 3, "Jaw")),
]
for x in (-3.5, -1.5, 1.5, 3.5):
    head.append(paint(box(x - 0.4, 24, -7, x + 0.4, 26.6, 3, "Stripe")))  # ...with brown stripes
head += both(
    ball(2.2, 30.6, -1.6, 1.6, 1.5, 1.6, "Frog"),  # bulging eyes on top
    paint(box(2, 30.5, -4, 3.5, 32, -2.6, "Eye")),
    paint(box(2.5, 30.5, -4, 3.5, 31.5, -2.6, "Pupil")),
)
head += [carve(s) for s in body if s.get("Kind") == "Ball"]  # (off the tire)

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
    "Joints": {"Legs": (0, 10.5, 0), "Head": (0, 27.5, -0.5)},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
