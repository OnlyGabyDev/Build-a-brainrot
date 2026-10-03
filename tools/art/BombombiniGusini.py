# Bombombini Gusini (art v2, blocks): a goose that's a bomber, built like Steal a
# Brainrot's model from clean blocks: a grey fuselage with a tail fin and two bombs under
# it; a thick white goose neck reaching forward and up to its head (an orange beak, black
# eyes); its "arms" are the wings, two red-tipped propellers on each; orange goose legs
# and webbed feet. Reference: Steal a Brainrot's render.
from voxel_art import block, both, plate, rod, shift, solid, wedge

LOW = -4  # it sits low, the plane just over its webbed feet

body = [
    block(0, 12.5, 5, 8, 7, 17, "Grey"),  # the fuselage
    block(0, 9.3, 5, 8.2, 0.6, 17.2, "GreyDark"),  # its belly
    wedge(0, 19, 11.4, 1.4, 6, 5, "Grey"),  # the tail fin
    plate(0.75, 18.4, 12.4, 2.4, 2.4, "Red", depth=0.1, rot=(0, 90, 0)),
    plate(-0.75, 18.4, 12.4, 2.4, 2.4, "Red", depth=0.1, rot=(0, 90, 0)),
    block(0, 13.5, 12.6, 10, 0.8, 3, "Grey"),  # the tailplane
]
for z in (2, 8):  # two bombs hanging under it
    body += [
        solid("Cylinder", 0, 7.6, z, 4.4, 2.2, 2.2, "Bomb", rot=(0, 90, 0)),
        block(0, 7.6, z - 2.4, 1.4, 1.4, 0.6, "Red"),
    ]

head = [
    rod((0, 14.2, -3.4), (0, 20.2, -8.8), 4.0, "White"),  # the long thick neck
    block(0, 20.4, -9.6, 4.6, 4.2, 5.4, "White"),  # the head
    block(0, 19.4, -13.4, 2.8, 1.6, 3, "Beak"),  # the beak
    wedge(0, 19.0, -15.6, 2.4, 0.8, 1.6, "Beak", rot=(0, 180, 0)),
    plate(0, 19.5, -14.95, 0.8, 0.4, "BeakDark", depth=0.1),
]
head += both(
    block(2.35, 21, -10.8, 0.2, 1.2, 1.2, "Dark"),  # eyes
    block(2.45, 21.3, -11.0, 0.1, 0.4, 0.4, "White"),
)

arms = []
for side in (-1, 1):
    arms.append(block(side * 8.6, 12.6, 4.4, 9.4, 0.8, 5.4, "Grey"))  # the wings
    for x in (6.6, 11.0):  # two propellers each, spinning in front of the wing
        hub = (side * x, 12.6, 1.4)
        arms += [
            solid("Ball", *hub, 1.4, 1.4, 1.4, "GreyDark"),
            block(hub[0], hub[1], 1.0, 0.7, 6, 0.3, "Blade"),
            block(hub[0], hub[1], 1.0, 6, 0.7, 0.3, "Blade"),
            block(hub[0], hub[1] + 2.8, 0.95, 0.8, 0.6, 0.35, "Red"),
            block(hub[0], hub[1] - 2.8, 0.95, 0.8, 0.6, 0.35, "Red"),
            block(hub[0] + 2.8, hub[1], 0.95, 0.6, 0.8, 0.35, "Red"),
            block(hub[0] - 2.8, hub[1], 0.95, 0.6, 0.8, 0.35, "Red"),
        ]

body, head, arms = shift(body, dy=LOW), shift(head, dy=LOW), shift(arms, dy=LOW)

legs = []
for x in (-1.8, 1.8):
    legs += [
        rod((x, 5, 1), (x, 1.0, 0), 1.3, "Beak"),  # short goose legs
        block(x, 0.4, -1, 3, 0.8, 3.6, "Beak"),  # webbed feet
        wedge(x, 0.4, -3.4, 3, 0.8, 1.2, "Beak", rot=(0, 180, 0)),
    ]

ART = {
    "Comment": "Bombombini Gusini: a goose bomber (blocks), a white neck and head with an orange beak, wings with propellers, goose feet.",
    "VoxelSize": 0.2,
    "Palette": {
        "Grey": (140, 155, 170),
        "GreyDark": (105, 118, 132),
        "Red": (235, 80, 85),
        "Bomb": (60, 65, 70),
        "White": (250, 250, 248),
        "Beak": (255, 160, 40),
        "BeakDark": (215, 115, 25),
        "Dark": (25, 25, 30),
        "Blade": (95, 100, 110),
    },
    "Joints": {"Legs": (0, 5, 2), "Head": (0, 16.4, -9.6)},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
