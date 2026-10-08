# Tim Cheese (art v2, blocks): a cool grey rat in a black suit, after the original meme
# image (by @choppow): a grey head with big round ears (pink inside), black sunglasses, a
# snout with a pink nose and white whiskers; a black suit jacket over a white shirt and a
# dark red tie, a pink tail; black trousers and shoes; our own touch: a wedge of holey
# cheese in its right paw.
from voxel_art import block, both, plate, rod, solid, wedge

FRONT = -2.6  # the jacket's front face

legs = []
for x in (-1.7, 1.7):
    legs += [
        block(x, 7, 0, 2.8, 10, 2.8, "Suit"),  # trousers
        block(x, 1.4, -0.6, 3, 1.8, 4.2, "Suit"),  # shoes...
        block(x, 0.3, -0.6, 3.2, 0.6, 4.4, "Sole"),  # ...on dark soles
    ]

body = [
    block(0, 17, 0, 8, 10, 5.2, "Suit"),  # the jacket
    plate(0, 19.6, FRONT - 0.1, 2.6, 4.8, "Shirt", depth=0.4),  # the white shirt...
    plate(0, 19.2, FRONT - 0.3, 0.8, 4.4, "Tie", depth=0.3),  # ...and a thin tie
    block(0, 21.8, 0, 3.6, 0.6, 3.6, "Shirt"),  # the collar
]
body += both(
    plate(1.9, 19.4, FRONT - 0.1, 1.2, 4.6, "Lapel", depth=0.5, rot=(0, 0, -12)),  # lapels
)
for y in (15.6, 13.6):
    body.append(plate(0, y, FRONT - 0.1, 0.7, 0.7, "Button", depth=0.4))
body += [  # a pink tail curling up behind
    rod((0, 13.4, 2.4), (0, 10.4, 5.6), 0.8, "Pink"),
    rod((0, 10.4, 5.6), (0, 12.6, 8.4), 0.7, "Pink"),
    rod((0, 12.6, 8.4), (0, 15.4, 8.8), 0.6, "Pink"),
]

arms = both(
    rod((4.6, 21, 0), (5.4, 14.2, -0.4), 2.4, "Suit"),  # sleeves
    block(5.5, 13.4, -0.5, 1.8, 1.8, 1.8, "Fur"),  # grey paws
)
arms += [  # the cheese, held out in the right paw
    wedge(5.6, 13.9, -3.6, 3.2, 3.4, 4.4, "Cheese"),
    block(7.25, 13.0, -2.6, 0.2, 1, 1, "CheeseHole"),  # holes in its side
    block(7.25, 14.2, -1.9, 0.2, 0.7, 0.7, "CheeseHole"),
    block(7.25, 12.6, -4.3, 0.2, 0.7, 0.7, "CheeseHole"),
]

head = [
    block(0, 25, 0, 7, 6, 6, "Fur"),
    block(0, 24.2, -4, 3.6, 3, 2.4, "Fur"),  # the snout...
    block(0, 24.8, -5.4, 1.4, 1.2, 1, "Pink"),  # ...a pink nose
    plate(0, 23.2, -5.25, 1.6, 0.3, "Dark", depth=0.2),  # a little mouth
    block(0, 28.3, 0.4, 2, 0.8, 2, "Fur"),  # a tuft
]
head += both(
    plate(1.75, 26.2, -3.15, 2.8, 1.8, "Glasses", depth=0.5),  # sunglasses...
    plate(1.4, 26.6, -3.45, 0.8, 0.4, "Glint", depth=0.2),
    solid("Cylinder", 3.6, 29.4, 0.6, 0.8, 5, 5, "Fur", rot=(0, 90, 0)),  # big round ears...
    solid("Cylinder", 3.6, 29.4, 0.1, 0.4, 3.4, 3.4, "Pink", rot=(0, 90, 0)),  # ...pink inside
    block(3.2, 24.4, -4.6, 2.8, 0.3, 0.3, "White", rot=(0, 0, 8)),  # whiskers
    block(3.2, 23.6, -4.6, 2.8, 0.3, 0.3, "White", rot=(0, 0, -8)),
)
head.append(plate(0, 26.4, -3.2, 0.8, 0.5, "Glasses", depth=0.4))  # the bridge

ART = {
    "Comment": "Tim Cheese: a grey mouse in sunglasses and a black suit, a pink tail, holding a wedge of cheese.",
    "VoxelSize": 0.2,
    "Palette": {
        "Fur": (150, 150, 160),
        "Pink": (240, 150, 170),
        "Suit": (34, 34, 42),
        "Lapel": (55, 55, 66),
        "Shirt": (245, 245, 245),
        "Tie": (150, 30, 45),
        "Button": (90, 90, 100),
        "Sole": (60, 50, 50),
        "Glasses": (18, 18, 22),
        "Glint": (130, 170, 230),
        "Dark": (30, 25, 30),
        "White": (250, 250, 250),
        "Cheese": (255, 205, 60),
        "CheeseHole": (215, 160, 30),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
