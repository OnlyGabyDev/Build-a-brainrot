# 67 (art v2, blocks): the "six-seven" meme (Maverick Trevillian shouting "six seven!" at a
# basketball game, palms up, 2025). The look follows Steal a Brainrot's "67" (a 6 and a 7
# side by side, an eye on each digit, white gloves, sneakers), which the user allowed since
# 67 is just a number, with our own changes: basketball-orange digits with black seams (the
# meme comes from a basketball game), the palms-up 6-7 shrug (the 6's hand low, the 7's
# high), gold cuffs, red sneakers over striped socks.
# The digits are drawn in the viewer's coordinates: u runs to the viewer's right, x = -u.
from voxel_art import block, plate, rod

D = 3.0  # the digits' depth (the head's top parts are 3.2 deep: no shared faces)
HD = 3.2


def seg(u0, u1, y0, y1, color="Ball", depth=D):
    return block(-(u0 + u1) / 2, (y0 + y1) / 2, 0, abs(u1 - u0), abs(y1 - y0), depth, color)


def seam(u0, u1, y0, y1, z):
    return plate(-(u0 + u1) / 2, (y0 + y1) / 2, z, abs(u1 - u0), abs(y1 - y0), "Seam", depth=0.2)


L6, R6 = -10.3, -1.3  # the 6
L7, R7 = 1.3, 10.3  # the 7
BZ, HZ = -D / 2 - 0.1, -HD / 2 - 0.1  # seams on the body's and the head's fronts

body = [  # the 6's round bottom...
    seg(L6 + 1.2, R6 - 1.2, 8.0, 10.6),
    seg(L6, L6 + 2.6, 9.2, 17.8),
    seg(R6 - 2.6, R6, 9.2, 16.6),
    seg(L6 + 1.2, R6 - 1.2, 15.4, 18.0),
    seam(L6 + 1.3, R6 - 1.3, 9.15, 9.45, BZ),  # ...with basketball seams
    seam(L6 + 1.15, L6 + 1.45, 9.45, 17.0, BZ),
    seam(R6 - 1.45, R6 - 1.15, 9.45, 16.5, BZ),
    seam(L6 + 1.45, R6 - 1.45, 16.55, 16.85, BZ),
    # the 7's slanted stem
    rod((-8.6, 22.0, 0), (-5.0, 8.4, 0), 2.8, "Ball"),
    seg(3.6, 6.4, 8.0, 9.6, depth=2.8),
    rod((-8.4, 21.0, -1.5), (-5.1, 8.6, -1.5), 0.3, "Seam"),
]

head = [  # the 6's curl...
    seg(L6, L6 + 2.6, 17.6, 24.6, depth=HD),
    seg(L6 + 1.2, R6 - 1.4, 22.4, 26.0, depth=HD),
    seg(R6 - 2.8, R6, 21.2, 24.8, depth=HD),
    seam(L6 + 1.15, L6 + 1.45, 17.8, 24.2, HZ),
    seam(R6 - 1.55, R6 - 1.25, 21.6, 24.2, HZ),
    # ...and the 7's top bar
    seg(L7, R7 - 0.4, 22.6, 26.0, depth=HD),
    seg(R7 - 3.0, R7, 20.6, 24.8, depth=HD),
    seam(6.7, R7 - 1.6, 24.15, 24.45, HZ),
]
for u, y, pu in ((-5.7, 23.4, -5.1), (4.6, 22.8, 4.0)):  # a big eye on each digit
    head += [
        plate(-u, y, -HD / 2 - 0.15, 4.2, 4.6, "White", depth=0.3),
        plate(-pu, y - 0.4, -HD / 2 - 0.35, 2.4, 2.8, "Pupil", depth=0.2),
        plate(-pu + 0.6, y + 0.3, -HD / 2 - 0.5, 0.7, 0.7, "White", depth=0.1),
    ]


def hand(x, y, z, s):
    """A white glove held palm up (s: the side it's on), a gold cuff."""
    return [
        block(x, y, z + 1.5, 2.2, 2.2, 0.9, "Cuff"),
        block(x, y, z, 3.4, 1.1, 3.4, "Glove"),  # the palm...
        block(x + s * 0.2, y + 0.2, z - 2.2, 3.2, 0.9, 1.4, "Glove"),  # ...fingers...
        block(x - s * 1.85, y + 0.7, z, 0.8, 1.3, 1.4, "Glove"),  # ...a thumb
    ]


arms = [  # the 6-7 shrug: the 6's hand low, the 7's high
    rod((9.4, 14.0, 0), (12.4, 12.4, -0.6), 1.5, "Ball"),
    rod((12.4, 12.4, -0.6), (13.6, 12.6, -2.2), 1.4, "Ball"),
    rod((-7.4, 16.0, 0), (-11.0, 17.4, -0.6), 1.5, "Ball"),
    rod((-11.0, 17.4, -0.6), (-12.2, 19.4, -2.2), 1.4, "Ball"),
]
arms += hand(14.0, 12.6, -3.4, 1) + hand(-12.6, 19.8, -3.4, -1)


def leg(x):
    return [
        rod((x, 9.4, 0), (x, 2.6, 0), 1.6, "Ball"),
        block(x, 3.4, 0, 2.0, 2.0, 2.0, "Sock"),  # a striped sock...
        block(x, 3.9, 0, 2.3, 0.4, 2.3, "Red"),
        block(x, 1.3, -0.7, 3.0, 2.2, 4.6, "Red"),  # ...a red sneaker
        block(x, 0.3, -0.7, 3.2, 0.6, 5.0, "Sole"),
        block(x, 1.0, -2.9, 2.8, 1.4, 0.6, "Sole"),
        block(x + 1.55, 1.5, -0.4, 0.2, 0.5, 2.6, "Sole"),
        block(x - 1.55, 1.5, -0.4, 0.2, 0.5, 2.6, "Sole"),
    ]


legs = leg(5.8) + leg(-5.0)

ART = {
    "Comment": "67: the digits 6 and 7 side by side in basketball orange with black seams, a big eye on each, arms out in the palms-up 6-7 shrug with white gloves and gold cuffs, red sneakers over striped socks.",
    "VoxelSize": 0.2,
    "Palette": {
        "Ball": (238, 122, 38),
        "Seam": (40, 26, 22),
        "White": (250, 250, 250),
        "Pupil": (22, 22, 30),
        "Glove": (250, 250, 250),
        "Cuff": (250, 196, 50),
        "Sock": (246, 246, 246),
        "Red": (222, 40, 52),
        "Sole": (250, 250, 250),
    },
    "Materials": {"Cuff": "Metal"},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
