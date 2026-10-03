# Ballerina Cappuccina (art v2): a big white cappuccino cup for a head (coffee and foam
# inside, a handle on its right), a sweet face on the cup (arched brows, lashes, brown
# eyes, a pink nose and blush, a smile); a pink leotard and a wide frilly tutu; thin arms
# held out to the sides; pink tights, one leg lifted to the side, white pointe shoes.
# Reference: Steal a Brainrot's render.
import math

from voxel_art import ball, box, both, carve, chain, cylinder, paint

legs = [
    cylinder(-1.3, 0, 0.8, 0.8, 1.5, 13, "Tights"),  # the standing leg
    ball(-1.3, 1.2, -0.6, 0.95, 1.2, 1.5, "Shoe"),  # a pointe shoe
    paint(box(-3, 2.4, -3, 0, 3.4, 2, "Ribbon")),
]
legs += chain((1.3, 12.6, 0), (5.6, 5.4, -0.4), 0.8, 0.75, "Tights")  # the lifted leg
legs += [ball(6.2, 4.6, -0.5, 1, 1.1, 1.2, "Shoe")]

leotard = ball(0, 16.5, 0, 2.3, 3.3, 1.9, "Leotard")
body = [
    leotard,
    cylinder(0, 0, 5.6, 5, 13, 14.2, "Tutu"),  # the tutu, in two frilly layers
    cylinder(0, 0, 4.6, 4.1, 14.2, 15.2, "TutuLight"),
    paint(box(-6, 13, -6, 6, 13.6, 6, "TutuLight")),
]
for k in range(10):
    a = k / 10 * math.pi * 2
    body.append(ball(math.sin(a) * 5.3, 13.4, math.cos(a) * 4.7, 0.9, 0.7, 0.9, "TutuLight"))  # ruffles

arms = both(
    *chain((2.1, 18.4, 0), (8.6, 19.2, -0.2), 0.85, 0.8, "Skin", steps=20),  # held out to the sides
    ball(9.2, 19.3, -0.2, 0.95, 0.95, 0.95, "Skin"),
)
arms.append(carve(leotard))

cup = cylinder(0, 0, 5, 4.6, 20, 30, "Cup")
head = [
    cup,
    cylinder(0, 0, 5.3, 4.9, 29.2, 30.4, "Cup"),  # the rim
    carve(cylinder(0, 0, 4.4, 4.0, 28.6, 31, "")),
    cylinder(0, 0, 4.4, 4.0, 28.4, 29.2, "Coffee"),  # coffee, a heart of foam on it
    paint(box(-2, 28, -2, 2, 30, 1, "Foam")),
    ball(0, 20.6, 0, 4.6, 1, 4.2, "Cup"),  # its rounded foot
    # the handle, on its right
    box(5, 22, -0.8, 7.8, 23, 0.8, "Cup"),
    box(6.8, 23, -0.8, 7.8, 27.5, 0.8, "Cup"),
    box(5, 27.5, -0.8, 7.8, 28.5, 0.8, "Cup"),
]
head += both(
    paint(box(1, 24, -6, 3, 26, -3, "White")),  # eyes
    paint(box(1, 24, -6, 2, 25, -3, "Iris")),
    paint(box(1, 26, -6, 3.4, 27, -3, "Lash")),  # lashes
    paint(box(0.6, 27.6, -6, 3.2, 28.4, -3, "Brow")),  # arched brows
    paint(box(2.6, 21.6, -6, 4, 22.6, -2.4, "Blush")),
)
head += [
    paint(box(-0.5, 22.6, -6, 0.5, 23.6, -3, "Nose")),
    paint(box(-1.6, 21, -6, 1.6, 21.8, -3, "Smile")),  # a smile, its corners up
    paint(box(-2.4, 21.6, -6, -1.4, 22.4, -3, "Smile")),
    paint(box(1.4, 21.6, -6, 2.4, 22.4, -3, "Smile")),
]

ART = {
    "Comment": "Ballerina Cappuccina: a cappuccino-cup head with a sweet face, a pink tutu, arms out, one leg lifted, pointe shoes.",
    "VoxelSize": 0.2,
    "Palette": {
        "Cup": (252, 250, 246),
        "Coffee": (120, 72, 45),
        "Foam": (232, 205, 170),
        "White": (255, 255, 255),
        "Iris": (110, 65, 40),
        "Lash": (35, 28, 30),
        "Brow": (150, 95, 60),
        "Nose": (255, 160, 170),
        "Blush": (255, 180, 190),
        "Smile": (220, 90, 110),
        "Leotard": (255, 175, 200),
        "Tutu": (255, 190, 215),
        "TutuLight": (255, 220, 235),
        "Skin": (252, 210, 185),
        "Tights": (255, 200, 210),
        "Shoe": (255, 240, 245),
        "Ribbon": (255, 150, 185),
    },
    "Joints": {"Legs": (0, 13, 0), "Head": (0, 25, 0)},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
