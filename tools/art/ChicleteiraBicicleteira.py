# Chicleteira Bicicleteira (art v2, blocks): a gumball machine on a bicycle, after the
# original meme image (by @brainbenderchannel): an old red gumball machine riding a bicycle;
# its glass globe full of colorful gumballs has a grinning face with sleepy eyes, a red cap
# on top; the red base has a silver coin slot and a chute; thin rusty-red arms hold the
# handlebars and thin legs pedal. Ours: half the gumballs glow (a Godly).
import math

from voxel_art import block, both, plate, rod, solid

# Legs: the bicycle and the legs pedalling it
WR = 3.6  # wheel radius
FRONT, BACK = -6.6, 6.4
legs = []
for z in (FRONT, BACK):  # two wheels
    legs += [
        solid("Cylinder", 0, WR, z, 0.9, 2 * WR, 2 * WR, "Tire"),
        solid("Cylinder", 0, WR, z, 1.0, 2 * WR - 1.4, 2 * WR - 1.4, "Rim"),
        solid("Cylinder", 0, WR, z, 1.1, 2 * WR - 2.0, 2 * WR - 2.0, "Tire"),
        solid("Cylinder", 0, WR, z, 1.4, 1.0, 1.0, "Rim"),
    ]
    for k in range(4):  # spokes
        legs.append(block(0, WR, z, 0.2, 2 * WR - 2.2, 0.2, "Rim", rot=(k * 45, 0, 0)))
BB = (0, 3.4, 0.8)  # the frame
SEAT = (0, 9.6, 2.6)
HEAD = (0, 9.4, -4.8)
for a, b in ((BB, (0, WR, BACK)), (BB, SEAT), (SEAT, (0, WR, BACK)), (SEAT, HEAD), (BB, HEAD), (HEAD, (0, WR, FRONT))):
    legs.append(rod(a, b, 0.7, "Frame"))
legs += [
    block(0, 9.9, 2.8, 1.8, 0.6, 3.0, "Saddle"),  # a saddle
    solid("Cylinder", 0, *BB[1:], 1.6, 1.8, 1.8, "Rim"),  # the cranks and pedals
    rod((0.9, 3.4, 0.8), (0.9, 1.6, 2.0), 0.4, "Rim"),
    rod((-0.9, 3.4, 0.8), (-0.9, 5.2, -0.4), 0.4, "Rim"),
    block(1.6, 1.6, 2.0, 1.2, 0.3, 0.8, "Tire"),
    block(-1.6, 5.2, -0.4, 1.2, 0.3, 0.8, "Tire"),
]
for s, foot in ((1, (1.6, 1.9, 2.0)), (-1, (-1.6, 5.5, -0.4))):  # thin legs pedalling
    knee = (s * 1.8, 8.2, -1.4)
    legs += [
        rod((s * 1.4, 11.0, 2.0), knee, 0.9, "Rust"),
        rod(knee, foot, 0.8, "Rust"),
        block(foot[0], foot[1] + 0.3, foot[2] - 0.2, 1.0, 0.6, 1.8, "Shoe"),
    ]

MY = 13.4  # the machine's red base (its body)
body = [
    block(0, MY, 1.4, 6.0, 5.2, 5.2, "Red"),  # a red base...
    block(0, MY + 2.9, 1.4, 6.6, 0.6, 5.8, "RedDark"),
    block(0, MY - 2.9, 1.4, 6.6, 0.6, 5.8, "RedDark"),
    block(0, MY + 0.6, 1.4 - 2.7, 2.4, 2.4, 0.4, "Silver"),  # ...a silver coin slot...
    solid("Cylinder", 0, MY + 0.6, 1.4 - 3.1, 0.6, 1.4, 1.4, "Silver", rot=(0, 90, 0)),
    block(0, MY - 1.6, 1.4 - 3.0, 1.6, 1.2, 1.2, "Silver"),  # ...a chute
]

GY, GZ = MY + 7.4, 1.4  # the glass globe (its head)
G = 4.6
head = [
    solid("Ball", 0, GY, GZ, 2 * G - 1.2, 2 * G - 1.2, 2 * G - 1.2, "Glass"),
    solid("Cylinder", 0, GY - G + 0.6, GZ, 1.2, 6.8, 6.8, "Silver", rot=(0, 0, 90)),  # (the globe's collar)
]
COLORS = ["Ball1", "Ball2", "Ball3", "Ball4", "Ball5", "Ball6"]
k = 0
for i in range(-3, 4):  # colorful gumballs packed in the globe
    for j in range(-3, 4):
        for m in range(-3, 4):
            p = (i * 1.45, j * 1.45, m * 1.45)
            r = math.sqrt(sum(c * c for c in p))
            if r > G - 0.8 or r < G - 2.9:
                continue
            if p[2] < -1.6 and abs(p[0]) < 3.4 and -2.6 < p[1] < 2.2:  # (not behind the face)
                continue
            head.append(solid("Ball", p[0], GY + p[1], GZ + p[2], 1.9, 1.9, 1.9, COLORS[k % 6]))
            k += 1
FZ = GZ - G + 0.2  # the grinning face
head += [
    block(0, GY - 1.0, FZ - 0.2, 4.6, 1.8, 0.6, "Mouth"),  # a big grin...
    block(0, GY - 0.65, FZ - 0.55, 4.0, 0.7, 0.3, "White"),
    block(0, GY + 0.3, FZ - 0.4, 1.2, 1.2, 1.2, "Nose"),
]
head += both(
    solid("Ball", 1.6, GY + 1.6, FZ, 2.2, 2.2, 2.2, "White"),  # sleepy eyes...
    plate(1.6, GY + 1.5, FZ - 1.15, 0.8, 0.8, "Dark", depth=0.2),
    block(1.6, GY + 2.3, FZ - 0.3, 2.4, 0.8, 1.6, "Nose"),  # ...under heavy lids
    block(2.6, GY - 0.6, FZ - 0.1, 0.8, 0.6, 0.6, "Mouth", rot=(0, 0, 35)),
)
head += [
    solid("Ball", 0, GY + G - 0.4, GZ, 6.0, 6.0, 6.0, "Red"),  # a red cap on top...
    solid("Cylinder", 0, GY + G - 0.4, GZ, 1.0, 6.8, 6.8, "RedDark", rot=(0, 0, 90)),
    solid("Ball", 0, GY + G + 2.6, GZ, 1.4, 1.4, 1.4, "RedDark"),  # ...a knob
]

arms = [  # thin rusty-red arms holding the handlebars
    block(0, 11.6, -5.2, 6.4, 0.5, 0.5, "Frame"),
    rod((0, 9.4, -4.8), (0, 11.6, -5.2), 0.6, "Frame"),
]
for s in (-1, 1):
    arms += [
        block(s * 3.1, 11.6, -5.2, 1.0, 0.8, 0.8, "Tire"),  # grips
        rod((s * 3.2, MY + 1.6, 1.0), (s * 3.8, MY - 1.4, -2.2), 0.8, "Rust"),
        rod((s * 3.8, MY - 1.4, -2.2), (s * 3.1, 12.0, -5.0), 0.7, "Rust"),
        solid("Ball", s * 3.1, 12.0, -5.2, 1.2, 1.2, 1.2, "Rust"),
    ]

ART = {
    "Comment": "Chicleteira Bicicleteira: an old red gumball machine riding a bicycle, its globe full of glowing colorful gumballs with a sleepy grinning face and a red cap, thin rusty arms on the handlebars, thin legs pedalling.",
    "VoxelSize": 0.22,  # (a Godly: a little bigger)
    "Palette": {
        "Tire": (34, 34, 38),
        "Rim": (176, 180, 188),
        "Frame": (60, 64, 72),
        "Saddle": (70, 46, 34),
        "Rust": (170, 80, 50),
        "Shoe": (50, 40, 36),
        "Red": (204, 50, 44),
        "RedDark": (160, 36, 32),
        "Silver": (200, 204, 212),
        "Glass": (150, 206, 236),
        "Ball1": (250, 70, 90),
        "Ball2": (60, 200, 250),
        "Ball3": (250, 210, 50),
        "Ball4": (110, 220, 90),
        "Ball5": (250, 140, 40),
        "Ball6": (190, 110, 250),
        "Mouth": (90, 30, 30),
        "White": (250, 250, 248),
        "Nose": (240, 170, 120),
        "Dark": (24, 20, 20),
    },
    "Materials": {"Ball1": "Neon", "Ball3": "Neon", "Ball5": "Neon", "Rim": "Metal", "Silver": "Metal"},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
