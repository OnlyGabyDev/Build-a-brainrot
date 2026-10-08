# Burballoni Watermeloni (art v2, blocks): a watermelon capybara, after the original meme
# image (by @alexey_pigeon): a capybara whose body is a big round striped watermelon, cut
# open at the front (a white rind and red flesh with black seeds round its neck), its brown
# capybara head poking out (a blunt square snout, small ears, buck teeth, sleepy eyes); four
# short brown legs (the front pair are its "arms").
import math

from voxel_art import block, both, plate, rod, solid

C = (0.0, 9.0, 1.8)  # the melon's middle
R = 7.0

body = [solid("Ball", *C, 2 * R, 2 * R, 2 * R, "Melon")]  # a big striped watermelon...
for k in range(6):
    body.append(solid("Cylinder", *C, 1.4, 2 * R + 0.3, 2 * R + 0.3, "Stripe", rot=(0, k * 30, 0)))
FZ = C[2] - R  # ...cut open at the front:
body += [
    solid("Cylinder", 0, C[1], FZ + 1.6, 3.4, 10.6, 10.6, "Melon", rot=(0, 90, 0)),
    solid("Cylinder", 0, C[1], FZ - 0.25, 0.4, 10.6, 10.6, "Rind", rot=(0, 90, 0)),  # a white rind...
    solid("Cylinder", 0, C[1], FZ - 0.55, 0.4, 9.4, 9.4, "Flesh", rot=(0, 90, 0)),  # ...red flesh...
]
for k in range(12):  # ...with black seeds
    a = math.radians(k * 30 + 15)
    body.append(block(math.sin(a) * 3.9, C[1] + math.cos(a) * 3.9, FZ - 0.8, 0.5, 0.9, 0.3, "Seed", rot=(0, 0, -math.degrees(a))))

HY, HZ = C[1] + 1.2, FZ - 2.6  # the capybara's head poking out
head = [
    block(0, HY - 0.4, HZ + 1.4, 4.6, 4.4, 2.8, "Fur"),  # (its neck)
    block(0, HY, HZ - 1.0, 5.0, 4.6, 4.0, "Fur"),  # a brown head...
    block(0, HY - 0.6, HZ - 3.6, 4.2, 3.2, 2.4, "Fur"),  # ...a blunt square snout...
    block(0, HY - 0.2, HZ - 4.95, 2.4, 1.0, 0.3, "Dark"),
    block(0, HY - 2.4, HZ - 4.4, 1.4, 1.0, 0.4, "Tooth"),  # ...buck teeth
]
head += both(
    plate(1.6, HY + 1.0, HZ - 3.05, 1.0, 0.5, "Dark", depth=0.2),  # sleepy eyes
    block(2.2, HY + 2.6, HZ + 0.2, 1.0, 1.0, 0.8, "FurDark"),  # small ears
    rod((1.8, HY - 1.0, HZ - 4.8), (3.6, HY - 0.6, HZ - 4.6), 0.15, "Whisker"),
)


def leg(x, z):
    return [
        block(x, 1.8, z, 2.4, 3.6, 2.4, "Fur"),
        block(x, 0.5, z - 0.4, 2.6, 1.0, 3.0, "FurDark"),
    ]


arms = leg(-3.0, C[2] - 3.0) + leg(3.0, C[2] - 3.0)
legs = leg(-3.0, C[2] + 3.4) + leg(3.0, C[2] + 3.4)

ART = {
    "Comment": "Burballoni Watermeloni: a capybara whose body is a big round striped watermelon cut open at the front, its brown head with a blunt snout and buck teeth poking out, four short legs.",
    "VoxelSize": 0.2,
    "Palette": {
        "Melon": (66, 150, 64),
        "Stripe": (30, 92, 40),
        "Rind": (236, 246, 220),
        "Flesh": (234, 64, 70),
        "Seed": (24, 20, 20),
        "Fur": (160, 110, 70),
        "FurDark": (120, 80, 50),
        "Dark": (40, 28, 24),
        "Tooth": (250, 246, 230),
        "Whisker": (60, 44, 34),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
