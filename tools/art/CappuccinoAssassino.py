# Cappuccino Assassino (art v2, blocks): a square white cup, a ninja, built like Steal a
# Brainrot's model from clean blocks: a black hood over its top with a steel headband
# plate and two tails fluttering behind, fierce eyes under angry brows, a black sash round
# its middle; thin black arms and legs, a katana in each hand (wrapped hilts, gold guards,
# steel blades). Reference: Steal a Brainrot's render.
from voxel_art import block, both, plate, rod

body = [
    block(0, 14.5, 0, 9, 9.5, 8.4, "Cup"),
    block(0, 13.8, 0, 9.2, 2.6, 8.6, "Black"),  # the sash
    block(3.2, 12.0, -4.5, 1.2, 2.6, 0.4, "Black"),  # its knot's tail
]

head = [
    block(0, 22.5, 0, 9, 6.5, 8.4, "Cup"),
    block(0, 26.9, 0, 9.4, 2.6, 8.8, "Black"),  # the hood
    block(0, 25.0, 0, 9.4, 1.4, 8.8, "Black"),
    block(0, 25.2, -4.55, 3.4, 1.8, 0.4, "Steel"),  # the headband's plate
    plate(0, 25.2, -4.8, 0.8, 0.8, "Dark", depth=0.1),
    rod((3.4, 26.2, 4.4), (6.6, 24.6, 7.8), 0.8, "Black"),  # the headband's tails
    rod((2.2, 25.8, 4.4), (4.6, 23.6, 7.6), 0.7, "Black"),
]
head += both(
    plate(1.9, 21.6, -4.3, 2, 1.7, "Black", depth=0.2),  # fierce eyes...
    plate(2.3, 22.0, -4.45, 0.6, 0.6, "White", depth=0.1),  # ...with a glint
    plate(1.9, 23.6, -4.3, 2.8, 0.7, "Black", depth=0.2, rot=(0, 0, 20)),  # angry brows
)

arms = []
for side in (-1, 1):
    arms += [
        rod((side * 4.8, 17.5, 0), (side * 6.3, 10.6, -1), 1.2, "Black"),  # thin arms
        block(side * 6.4, 10, -1.2, 1.6, 1.6, 1.6, "Glove"),
        rod((side * 6.3, 10.9, -0.7), (side * 6.8, 8.4, -2.6), 0.8, "Wrap"),  # the hilt
        block(side * 6.85, 8.2, -2.8, 2, 0.4, 1.2, "Gold", rot=(-40, 0, 0)),  # the guard
        rod((side * 6.9, 8.0, -3.0), (side * 9.4, 1.2, -7.6), 0.6, "Steel"),  # the blade
    ]

legs = []
for x in (-1.6, 1.6):
    legs += [
        rod((x, 9.8, 0), (x, 1.6, -0.2), 1.5, "Black"),
        block(x, 0.8, -0.8, 2.2, 1.6, 3.4, "Black"),  # ninja shoes
    ]

ART = {
    "Comment": "Cappuccino Assassino: a square cup (blocks) in a ninja hood and sash, fierce eyes, thin black limbs, a katana in each hand.",
    "VoxelSize": 0.2,
    "Palette": {
        "Cup": (250, 248, 244),
        "Black": (32, 30, 36),
        "Steel": (190, 196, 206),
        "Dark": (60, 62, 70),
        "White": (255, 255, 255),
        "Glove": (190, 150, 105),
        "Wrap": (130, 95, 60),
        "Gold": (230, 180, 60),
    },
    "Joints": {"Head": (0, 23, 0)},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
