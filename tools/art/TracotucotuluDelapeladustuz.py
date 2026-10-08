# Tracotucotulu Delapeladustuz (art v2, blocks): a camel car, after the original meme image
# (by @turzin_sfd, 2025-02-09): a round blue beetle-like car (silver bumpers, round
# headlights, dark windows) with a camel's long neck and head rising from its front, and six
# knobbly camel legs in place of its wheels (the front pair are its "arms"). No badges or
# plates. Ours: the headlights glow (a Mythic).
import math

from voxel_art import block, both, plate, rod, solid

CY = 10.6  # the car's middle
body = [
    block(0, CY - 0.4, 0.6, 9.2, 3.6, 15.0, "Car"),  # a round blue car...
    solid("Ball", 0, CY + 1.6, 1.6, 10.0, 10.0, 10.0, "Car"),  # (its rounded cabin)
    block(0, CY - 2.2, -7.2, 9.8, 1.0, 1.0, "Silver"),  # ...silver bumpers...
    block(0, CY - 2.2, 8.4, 9.8, 1.0, 1.0, "Silver"),
    block(0, CY + 3.8, -2.4, 6.6, 2.4, 0.3, "Window"),  # ...dark windows
]
for s in (-1, 1):
    body += [
        solid("Ball", s * 3.6, CY - 0.6, -4.0, 5.2, 5.2, 5.2, "Car"),  # round fenders...
        solid("Ball", s * 3.6, CY - 0.6, 5.2, 5.2, 5.2, 5.2, "Car"),
        block(s * 4.95, CY + 2.6, 1.6, 0.3, 2.4, 6.0, "Window"),
        solid("Cylinder", s * 3.4, CY + 0.2, -6.2, 0.6, 2.2, 2.2, "Light", rot=(0, 90, 0)),  # ...round headlights
        solid("Cylinder", s * 3.4, CY + 0.2, -6.55, 0.3, 1.4, 1.4, "Silver", rot=(0, 90, 0)),
    ]

HZ = -8.6  # the camel's long neck and head, rising from its front
N = [(0, CY + 0.6, -5.6), (0, CY + 4.6, -7.4), (0, CY + 8.6, -8.0), (0, CY + 11.4, -9.0)]
head = []
for k in range(3):
    head.append(rod(N[k], N[k + 1], 3.0 - k * 0.3, "Camel"))
HY = N[-1][1]
head += [
    block(0, HY + 0.6, HZ - 1.0, 3.2, 3.0, 4.4, "Camel"),  # a camel head...
    block(0, HY - 0.2, HZ - 3.8, 2.6, 2.2, 2.4, "CamelLight"),  # ...a long soft muzzle
    plate(0, HY - 0.8, HZ - 5.05, 1.6, 0.3, "Dark", depth=0.15),
    block(0, HY + 1.0, HZ + 1.6, 3.6, 2.4, 1.0, "CamelDark"),  # (a shaggy mane)
]
head += both(
    plate(1.0, HY + 1.3, HZ - 3.25, 0.8, 0.8, "Dark", depth=0.2),  # sleepy eyes
    block(1.1, HY + 1.85, HZ - 3.3, 1.2, 0.4, 0.4, "CamelDark"),
    plate(0.7, HY - 0.1, HZ - 5.05, 0.4, 0.4, "Dark", depth=0.1),
    block(1.8, HY + 2.4, HZ + 0.2, 0.6, 1.0, 0.8, "Camel", rot=(0, 0, -20)),  # little ears
)


def leg(x, z):
    s = 1 if x > 0 else -1
    knee = (x + s * 0.4, 5.0, z - 0.6)
    return [
        rod((x, CY - 1.6, z), knee, 1.6, "Camel"),
        solid("Ball", *knee, 1.9, 1.9, 1.9, "CamelDark"),  # knobbly knees...
        rod(knee, (x + s * 0.4, 1.0, z + 0.2), 1.3, "Camel"),
        block(x + s * 0.4, 0.5, z - 0.4, 2.0, 1.0, 2.4, "CamelDark"),  # ...wide hooves
    ]


arms = leg(-3.4, -4.6) + leg(3.4, -4.6)
legs = leg(-3.4, 0.6) + leg(3.4, 0.6) + leg(-3.4, 5.8) + leg(3.4, 5.8)

ART = {
    "Comment": "Tracotucotulu Delapeladustuz: a round blue beetle-like car with glowing round headlights, a camel's long neck and head rising from its front, six knobbly camel legs in place of its wheels.",
    "VoxelSize": 0.2,
    "Palette": {
        "Car": (110, 150, 200),
        "Silver": (210, 214, 220),
        "Window": (40, 56, 76),
        "Light": (255, 236, 170),
        "Camel": (200, 150, 90),
        "CamelLight": (226, 190, 140),
        "CamelDark": (160, 112, 64),
        "Dark": (30, 22, 18),
    },
    "Materials": {"Light": "Neon", "Silver": "Metal"},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
