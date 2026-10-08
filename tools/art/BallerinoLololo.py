# Ballerino Lololo (art v2, blocks): a ballet milkshake, after the original meme image (by
# @fskacca): a latte-colored takeaway cup with fluted sides, a white domed lid and a bent
# straw, a happy face (big dark eyes, an open smile), a white tutu round its bottom, huge
# muscular arms flexing (double biceps) and muscular legs, one on pointe in a pale pink
# ballet shoe, the other bent up to its knee.
import math

from voxel_art import block, both, plate, rod, solid


def cup(y0, y1, d, color):
    """An upright round slice of the cup, from y0 to y1, d across."""
    return solid("Cylinder", 0, (y0 + y1) / 2, 0, y1 - y0, d, d, color, rot=(0, 0, 90))


body = [
    cup(11.6, 13.8, 7.4, "Cup"),  # the cup's fluted bottom...
    cup(13.8, 16.0, 8.0, "Cup"),
    cup(16.0, 18.2, 8.6, "Cup"),
    solid("Cylinder", 0, 12.4, 0, 1.0, 14.0, 14.0, "Tutu", rot=(0, 0, 90)),  # ...in a white tutu
    solid("Cylinder", 0, 11.7, 0, 0.8, 15.2, 15.2, "TutuShade", rot=(0, 0, 90)),
]
for k in range(12):  # flutes round the cup
    a = math.radians(k * 30 + 15)
    body.append(block(math.sin(a) * 4.0, 15.6, -math.cos(a) * 4.0, 0.6, 4.4, 0.5, "Flute", rot=(0, -k * 30 - 15, 0)))

head = [
    cup(18.2, 20.6, 9.2, "Cup"),  # the cup's top...
    cup(20.6, 23.2, 9.8, "Cup"),
    cup(23.2, 23.9, 10.4, "Rim"),  # ...its rim...
    solid("Ball", 0, 23.6, 0, 9.0, 9.0, 9.0, "Lid"),  # ...a domed lid...
    cup(27.6, 28.3, 2.4, "Rim"),
    rod((1.0, 26.0, 0.4), (2.2, 31.0, 1.0), 0.9, "Straw"),  # ...a bent straw
    rod((2.2, 31.0, 1.0), (4.6, 32.0, 1.4), 0.9, "Straw"),
    rod((1.6, 28.6, 0.7), (1.8, 29.4, 0.75), 0.95, "Stripe"),
    plate(0, 19.4, -4.75, 3.0, 1.3, "Mouth", depth=0.6),  # an open smile...
    plate(0, 19.05, -4.95, 1.6, 0.5, "Tongue", depth=0.3),  # ...a pink tongue
    plate(0, 19.85, -4.95, 2.4, 0.35, "White", depth=0.3),  # ...white teeth
]
head += both(
    plate(1.7, 21.8, -4.95, 1.4, 1.9, "Eye", depth=0.6),  # big dark eyes...
    plate(1.45, 22.25, -5.3, 0.45, 0.45, "White", depth=0.1),
    plate(1.9, 23.15, -4.95, 1.4, 0.35, "Eye", depth=0.4, rot=(0, 0, -12)),  # ...happy brows
    plate(2.9, 20.0, -4.4, 1.0, 0.6, "Blush", depth=0.6),
    plate(2.2, 19.6, -4.75, 0.4, 0.8, "Mouth", depth=0.6, rot=(0, 0, 40)),  # the smile's corners
)

arms = []
for s in (-1, 1):  # huge muscular arms flexing
    arms += [
        solid("Ball", s * 4.4, 16.8, 0, 3.0, 3.0, 3.0, "Skin"),  # a shoulder
        rod((s * 4.4, 16.6, 0), (s * 8.2, 17.8, 0), 2.6, "Skin"),
        block(s * 6.4, 18.6, -0.2, 3.0, 2.4, 2.8, "Skin"),  # a big biceps
        rod((s * 8.2, 17.8, 0), (s * 8.6, 22.6, -0.4), 2.5, "Skin"),
        block(s * 8.7, 23.5, -0.5, 2.3, 2.0, 2.1, "Skin"),  # a fist
    ]

legs = [
    rod((1.4, 12.6, 0), (1.6, 6.6, 0), 2.8, "Skin"),  # one leg on pointe...
    block(1.7, 8.0, 0.4, 2.2, 2.6, 2.4, "Skin"),
    rod((1.6, 6.6, 0), (1.5, 2.6, 0.1), 2.2, "Skin"),
    block(1.5, 4.4, 0.6, 1.8, 2.2, 1.8, "Skin"),  # (its calf)
    block(1.5, 1.3, 0.0, 1.4, 2.6, 1.4, "Shoe"),
    plate(1.5, 2.2, -0.75, 1.6, 0.25, "Ribbon", depth=0.1, rot=(0, 0, 30)),
    plate(1.5, 2.2, -0.75, 1.6, 0.25, "Ribbon", depth=0.1, rot=(0, 0, -30)),
    rod((-1.4, 12.4, 0), (-5.0, 8.8, -1.4), 2.6, "Skin"),  # ...the other bent up to its knee
    rod((-5.0, 8.8, -1.4), (0.2, 7.0, -0.8), 2.0, "Skin"),
    block(0.6, 6.7, -0.8, 1.2, 1.4, 1.2, "Shoe", rot=(0, 0, -20)),
]

ART = {
    "Comment": "Ballerino Lololo: a latte takeaway cup with a domed lid, a bent straw and a happy face, a white tutu, huge muscular arms flexing, muscular legs, one on pointe.",
    "VoxelSize": 0.2,
    "Palette": {
        "Cup": (236, 208, 180),
        "Flute": (220, 188, 156),
        "Rim": (250, 248, 244),
        "Lid": (246, 244, 240),
        "Straw": (240, 222, 200),
        "Stripe": (232, 120, 150),
        "Tutu": (252, 252, 252),
        "TutuShade": (238, 236, 244),
        "Eye": (40, 26, 22),
        "White": (252, 252, 252),
        "Mouth": (120, 40, 44),
        "Tongue": (236, 120, 130),
        "Blush": (244, 170, 170),
        "Skin": (238, 182, 150),
        "Shoe": (248, 214, 218),
        "Ribbon": (236, 180, 190),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
