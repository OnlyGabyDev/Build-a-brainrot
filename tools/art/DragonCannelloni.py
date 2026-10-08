# Dragon Cannelloni (art v2, blocks): a dragon made of pasta, after the original meme image
# (by @name2pictureai): a body of stacked cannelloni tubes (creamy filling at their ends)
# dripping with tomato sauce, a curling tail of tubes with a spiked tip; a horned head on a
# neck of tubes, glowing eyes, breathing glowing fire; its "arms" are wide wings of sauce
# stretched on pasta-tube frames; thick pasta legs on clawed feet.
from voxel_art import block, both, plate, rod, solid, wedge


def tube(cx, cy, cz, length, d, color="Pasta", ends=True):
    """A cannelloni lying along X, its filling showing at both ends."""
    shapes = [solid("Cylinder", cx, cy, cz, length, d, d, color)]
    if ends:
        for side in (-1, 1):
            shapes.append(solid("Cylinder", cx + side * (length / 2 + 0.05), cy, cz, 0.3, d * 0.62, d * 0.62, "Filling"))
    return shapes


body = []
for k, y in enumerate((11.2, 14.2, 17.2, 20.2)):  # the body: cannelloni stacked two deep
    body += tube(0, y, -0.9, 9.4 - abs(k - 1.5) * 0.8, 3.2)
    body += tube(0, y, 2.1, 8.6 - abs(k - 1.5) * 0.8, 3.2)
body += [  # tomato sauce dripping over it
    block(0, 21.9, 0.6, 7.0, 0.5, 6.4, "Sauce"),
    plate(-1.8, 19.4, -2.6, 1.4, 4.4, "Sauce", depth=0.4),
    plate(1.6, 20.2, -2.6, 1.2, 2.8, "Sauce", depth=0.4),
    plate(0.2, 13.6, -2.6, 1.0, 2.2, "Sauce", depth=0.4),
]
body += [  # a curling tail of tubes, a spiked tip
    rod((0, 11.0, 3.4), (0, 7.4, 8.0), 2.6, "Pasta", shape="Cylinder"),
    rod((0, 7.4, 8.0), (2.0, 5.2, 11.8), 2.2, "Pasta", shape="Cylinder"),
    rod((2.0, 5.2, 11.8), (4.6, 5.8, 14.0), 1.8, "PastaDark", shape="Cylinder"),
    wedge(5.6, 6.6, 14.8, 0.8, 2.6, 2.4, "Sauce", rot=(0, -50, 0)),
]

head = [
    rod((0, 21.4, -0.4), (0, 25.4, -2.6), 3.0, "Pasta", shape="Cylinder"),  # the neck...
    rod((0, 25.4, -2.6), (0, 27.6, -4.0), 2.8, "Pasta", shape="Cylinder"),
    block(0, 28.4, -5.4, 4.6, 3.6, 5.0, "Pasta"),  # ...the head
    block(0, 28.2, -9.0, 3.6, 1.8, 3.4, "Pasta"),  # its snout
    block(0, 26.9, -8.4, 3.4, 1.0, 3.6, "PastaDark", rot=(-14, 0, 0)),  # an open lower jaw
    block(0, 30.4, -5.2, 3.4, 0.5, 4.0, "Sauce"),  # a dash of sauce on top
]
head += both(
    plate(1.3, 29.65, -7.95, 1.2, 0.8, "Eye", depth=0.3),  # glowing eyes
    rod((1.4, 30.2, -4.0), (2.4, 32.8, -1.6), 0.9, "Horn"),  # swept-back horns
    wedge(2.45, 28.6, -5.2, 0.6, 1.6, 1.6, "PastaDark", rot=(0, -90, 0)),  # cheek frills
    plate(0.8, 28.6, -10.75, 0.5, 0.4, "Dark", depth=0.15),  # nostrils
)
# glowing fire breath, out of its open mouth
head += [
    block(0, 27.7, -11.2, 2.6, 1.6, 1.6, "Fire"),
    block(0, 27.4, -12.8, 3.4, 2.4, 1.8, "Fire"),
    block(0, 27.4, -12.6, 1.6, 1.2, 1.8, "FireCore"),
    block(0, 27.2, -14.6, 3.8, 3.0, 1.8, "Fire"),
    block(0, 27.2, -14.4, 2.0, 1.6, 2.0, "FireCore"),
    block(0.9, 28.9, -15.2, 1.4, 1.4, 1.4, "Fire", rot=(0, 0, 30)),  # flame tongues
    block(-1.2, 25.6, -15.6, 1.2, 1.2, 1.2, "Fire", rot=(0, 0, 20)),
    block(0.2, 27.0, -16.3, 1.6, 1.6, 1.0, "FireCore", rot=(0, 0, 45)),
]

arms = []
for side in (-1, 1):  # wings of sauce on pasta-tube frames
    shoulder = (side * 4.0, 20.4, 2.6)
    elbow = (side * 9.4, 26.6, 3.8)
    tip = (side * 15.0, 23.4, 4.6)
    arms += [
        rod(shoulder, elbow, 1.5, "Pasta", shape="Cylinder"),
        rod(elbow, tip, 1.2, "Pasta", shape="Cylinder"),
        rod(elbow, (side * 11.6, 18.0, 4.4), 0.9, "Pasta", shape="Cylinder"),
        block(side * 8.4, 21.8, 3.6, 8.6, 6.4, 0.5, "Sauce", rot=(0, 0, side * 22)),  # the sauce membranes
        block(side * 12.2, 21.6, 4.2, 5.6, 5.0, 0.5, "SauceDark", rot=(0, 0, side * -18)),
        wedge(side * 9.4, 27.8, 3.8, 0.8, 1.6, 1.2, "Horn"),  # a claw at the wing's bend
    ]

legs = []
for x in (-2.8, 2.8):
    legs += [
        rod((x, 10.4, 0.6), (x * 1.2, 5.4, -0.8), 3.0, "Pasta", shape="Cylinder"),  # thick pasta legs...
        rod((x * 1.2, 5.4, -0.8), (x * 1.15, 1.6, 0.2), 2.6, "Pasta", shape="Cylinder"),
        block(x * 1.15, 0.8, -1.0, 3.4, 1.6, 4.4, "PastaDark"),  # ...clawed feet
    ]
    for t in (-1.1, 0, 1.1):
        legs.append(wedge(x * 1.15 + t, 0.6, -3.7, 0.8, 1.2, 1.2, "Horn", rot=(0, 180, 0)))

ART = {
    "Comment": "Dragon Cannelloni: a dragon of stacked cannelloni dripping with tomato sauce, sauce wings on pasta frames, glowing eyes and glowing fire breath.",
    "VoxelSize": 0.2,
    "Palette": {
        "Pasta": (242, 200, 116),
        "PastaDark": (214, 162, 84),
        "Filling": (250, 244, 226),
        "Sauce": (204, 52, 38),
        "SauceDark": (160, 34, 26),
        "Horn": (110, 74, 46),
        "Eye": (255, 226, 70),
        "Dark": (60, 30, 24),
        "Fire": (255, 120, 30),
        "FireCore": (255, 236, 110),
    },
    "Materials": {"Eye": "Neon", "Fire": "Neon", "FireCore": "Neon"},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
