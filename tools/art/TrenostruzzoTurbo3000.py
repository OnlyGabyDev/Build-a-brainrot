# Trenostruzzo Turbo 3000 (art v2, blocks): an ostrich steam train, after the original meme
# image (by @ofuscabreno): a black steam locomotive with a green cab, gold trim, a tall
# smokestack puffing smoke and a glowing headlamp, with a fluffy dark ostrich body at its
# front, red driving wheels a little off the ground (the ostrich carries it); a long pink
# neck up to a fuzzy ostrich head (big orange eyes, a long pink beak); its "arms" are the
# ostrich's short fluffy wings; long pink ostrich legs with two big toes. (The original has
# a toilet on the cab: left out.)
from voxel_art import block, both, plate, rod, solid

BY = 11.0  # the boiler's middle

body = [
    solid("Cylinder", 0, BY, 1.0, 15.0, 8.0, 8.0, "Iron", rot=(0, 90, 0)),  # the boiler, lying along Z
    block(0, 6.9, 3.0, 9.0, 1.6, 17.0, "Frame"),  # the frame under it
    block(0, 4.9, 3.6, 9.4, 2.4, 11.0, "Frame"),
    block(0, 12.4, 12.2, 9.4, 12.6, 5.6, "Cab"),  # the green cab at the back...
    block(0, 19.2, 12.2, 10.6, 1.0, 7.0, "Frame"),  # ...its roof
    block(0, 6.2, 12.2, 9.6, 0.8, 5.8, "Gold"),
    plate(0, 15.0, 9.3, 6.0, 3.4, "Window", depth=0.2),  # windows
    block(0, 15.0, 15.1, 6.0, 3.4, 0.2, "Window"),
    rod((0, BY + 3.6, -4.4), (0, BY + 8.4, -4.4), 2.6, "Iron", shape="Cylinder"),  # the smokestack...
    rod((0, BY + 8.4, -4.4), (0, BY + 9.6, -4.4), 3.6, "Frame", shape="Cylinder"),
    rod((0, BY + 3.6, 2.6), (0, BY + 5.6, 2.6), 2.8, "Gold", shape="Cylinder"),  # a gold steam dome
    block(0, BY + 11.4, -4.0, 3.0, 2.4, 3.0, "Smoke"),  # ...puffing smoke
    block(0.8, BY + 13.6, -2.8, 3.8, 2.8, 3.8, "Smoke"),
    block(2.0, BY + 16.2, -0.8, 4.6, 3.2, 4.6, "SmokeLight"),
    block(3.4, BY + 19.0, 2.2, 3.6, 2.6, 3.6, "SmokeLight"),
    block(0, BY + 5.6, -6.4, 2.6, 2.0, 1.8, "Gold"),  # the headlamp's housing...
    plate(0, BY + 5.6, -7.4, 1.8, 1.4, "Lamp", depth=0.3),  # ...glowing
]
for z in (-3.0, 1.0, 5.0):  # gold bands round the boiler
    body.append(solid("Cylinder", 0, BY, z, 0.6, 8.4, 8.4, "Gold", rot=(0, 90, 0)))
body += both(
    block(4.6, 15.0, 12.2, 0.2, 3.4, 3.2, "Window"),
    block(4.8, 9.4, 12.2, 0.2, 3.0, 4.6, "Fire"),  # the firebox glowing through the cab's sides
    block(4.75, 6.9, 3.0, 0.2, 0.6, 16.0, "Gold"),  # a gold stripe along the frame
)
body += [  # the ostrich's fluffy body at the front
    block(0, BY - 0.4, -7.4, 9.4, 8.6, 5.4, "Feather"),
    block(0, BY - 0.4, -7.6, 8.0, 10.0, 4.6, "Feather"),
    block(0, BY - 4.0, -7.6, 6.4, 2.0, 4.0, "Feather"),
]
for x, y in ((-3.6, BY + 3.2), (3.4, BY + 2.4), (-2.4, BY - 3.4), (3.8, BY - 3.0), (0.6, BY + 4.4)):
    body.append(block(x, y, -10.0, 2.0, 1.6, 0.6, "FeatherLight", rot=(0, 0, 20 if x > 0 else -20)))  # fluffy tufts

NZ = -9.4
head = [
    rod((0, BY + 3.6, NZ - 0.6), (0, BY + 10.0, NZ - 1.6), 2.4, "Neck"),  # a long pink neck...
    rod((0, BY + 10.0, NZ - 1.6), (0, BY + 15.4, NZ - 0.6), 2.2, "Neck"),
    block(0, BY + 17.0, NZ - 1.4, 4.6, 4.2, 5.2, "Fuzz"),  # ...a fuzzy head...
    block(0, BY + 19.0, NZ - 1.0, 3.6, 1.2, 4.0, "Fuzz"),
    block(0, BY + 15.9, NZ - 5.4, 3.0, 1.2, 4.0, "Beak"),  # ...a long flat pink beak
    block(0, BY + 15.3, NZ - 5.2, 2.6, 0.6, 3.4, "BeakDark"),
]
for y in (BY + 6.0, BY + 9.0, BY + 12.0):  # fuzz down the neck
    head.append(block(0, y, NZ - 1.4, 2.8, 1.0, 2.8, "Fuzz", rot=(10, 0, 0)))
head += both(
    block(2.35, BY + 17.4, NZ - 2.4, 0.3, 2.0, 2.0, "Eye"),  # big orange eyes
    block(2.5, BY + 17.4, NZ - 2.4, 0.2, 1.0, 1.0, "Dark"),
    block(2.6, BY + 17.8, NZ - 2.8, 0.1, 0.4, 0.4, "Glint"),
    block(1.0, BY + 16.2, NZ - 6.8, 0.4, 0.3, 0.6, "Dark"),  # nostrils
)

for s in (-1, 1):  # the red driving wheels with their rods, a little off the ground
    for z in (-0.6, 3.6, 7.8):
        body += [
            solid("Cylinder", s * 5.0, 4.6, z, 0.6, 4.8, 4.8, "Wheel"),
            solid("Cylinder", s * 5.25, 4.6, z, 0.4, 3.4, 3.4, "WheelDark"),
            solid("Cylinder", s * 5.45, 4.6, z, 0.4, 1.4, 1.4, "Gold"),
        ]
    body.append(block(s * 5.85, 4.6, 3.6, 0.4, 0.7, 8.8, "Rod"))  # the coupling rod

arms = []
for s in (-1, 1):  # short fluffy ostrich wings
    arms += [
        block(s * 5.3, BY + 0.6, -7.2, 1.2, 4.4, 4.6, "Feather", rot=(-12, 0, s * 12)),
        block(s * 5.9, BY - 1.0, -5.4, 1.0, 3.0, 3.0, "FeatherLight", rot=(-24, 0, s * 18)),
        block(s * 5.8, BY + 2.4, -8.8, 0.9, 1.6, 2.2, "FeatherLight", rot=(-12, 0, s * 12)),
    ]


def leg(x):
    return [
        rod((x, BY - 3.6, -7.4), (x, 4.2, -6.2), 1.6, "Leg"),  # a long pink leg...
        block(x, 4.2, -6.2, 2.0, 2.0, 2.0, "Leg"),  # ...a knobbly ankle...
        rod((x, 4.2, -6.2), (x, 1.0, -7.0), 1.4, "Leg"),
        block(x - 0.6, 0.6, -8.4, 1.2, 1.2, 3.6, "Leg"),  # ...two big toes
        block(x + 0.7, 0.6, -8.0, 1.0, 1.0, 2.8, "Leg"),
        block(x - 0.6, 0.6, -10.4, 1.0, 1.0, 0.6, "Dark"),
    ]


legs = leg(-2.4) + leg(2.4)

ART = {
    "Comment": "Trenostruzzo Turbo 3000: a black steam locomotive with a green cab, gold trim, smoke and a glowing headlamp, a fluffy ostrich body in front with short wings, a long pink neck and ostrich head, red wheels, long pink legs.",
    "VoxelSize": 0.2,
    "Palette": {
        "Iron": (44, 46, 54),
        "Frame": (24, 24, 30),
        "Cab": (60, 140, 76),
        "Gold": (240, 186, 60),
        "Window": (250, 220, 120),
        "Fire": (255, 120, 40),
        "Lamp": (255, 240, 150),
        "Smoke": (150, 150, 158),
        "SmokeLight": (196, 196, 204),
        "Feather": (56, 50, 50),
        "FeatherLight": (110, 100, 96),
        "Neck": (236, 170, 160),
        "Fuzz": (176, 150, 126),
        "Beak": (236, 150, 140),
        "BeakDark": (196, 110, 106),
        "Eye": (246, 150, 30),
        "Dark": (24, 22, 26),
        "Glint": (245, 245, 245),
        "Wheel": (214, 50, 44),
        "WheelDark": (150, 30, 30),
        "Rod": (200, 204, 214),
        "Leg": (236, 160, 150),
    },
    "Materials": {"Gold": "Metal", "Window": "Neon", "Fire": "Neon", "Lamp": "Neon"},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
