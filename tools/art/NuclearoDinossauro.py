# Nuclearo Dinossauro (art v2, blocks): a T-rex bomber, after the original meme image (by
# @nuclearodinossauro): a big bomber plane with rough dark grey-brown dino hide (darker
# scales, a ridge of spikes along its back, a glass cockpit, a tall tail fin), its nose a
# roaring T-rex head (jaws wide open, rows of white teeth); its "arms" are the wings with two
# propeller engines each, its "legs" the landing gear. Ours, for a Godly: the eyes and the
# throat glow nuclear green.
from voxel_art import block, both, plate, rod, solid, wedge

body = [
    block(0, 13.0, 6.0, 8.8, 7.6, 24.0, "Hide"),  # the fuselage...
    block(0, 13.4, 6.0, 7.6, 8.6, 22.0, "Hide"),
    block(0, 17.9, 0.6, 4.6, 1.6, 5.0, "Glass"),  # ...a glass cockpit...
    block(0, 17.9, 0.6, 0.4, 1.7, 5.3, "HideDark"),
    wedge(0, 21.0, 16.6, 1.6, 8.0, 5.4, "Hide"),  # ...a tall tail fin...
    block(0, 15.4, 16.8, 13.0, 0.8, 3.6, "Hide"),  # ...and tailplane
    block(0, 9.0, 4.0, 3.4, 0.6, 8.0, "HideDark"),  # bomb bay doors...
    solid("Cylinder", 0, 7.4, 4.4, 6.0, 2.8, 2.8, "Bomb", rot=(0, 90, 0)),  # ...a glowing bomb under it
    solid("Cylinder", 0, 7.4, 3.6, 0.8, 3.0, 3.0, "Glow", rot=(0, 90, 0)),
    solid("Cylinder", 0, 7.4, 5.4, 0.8, 3.0, 3.0, "Glow", rot=(0, 90, 0)),
    solid("Ball", 0, 7.4, 1.4, 2.8, 2.8, 2.8, "Bomb"),
    block(0, 7.4, 7.8, 0.3, 3.4, 1.6, "HideDark"),
    block(0, 7.4, 7.8, 3.4, 0.3, 1.6, "HideDark"),
    rod((0, 8.8, 4.4), (0, 9.4, 4.4), 0.6, "Gear"),
]
for z in (3.6, 6.8, 10.0, 13.2):  # a ridge of spikes along its back
    body.append(block(0, 17.9, z, 0.8, 2.0, 2.0, "Spike", rot=(45, 0, 0)))
for z, y in ((-1.0, 11.6), (2.8, 14.2), (6.6, 11.2), (10.4, 13.8), (14.2, 11.8)):  # darker scales
    body += both(block(4.45, y, z, 0.3, 1.6, 2.4, "HideDark"))

HZ = -9.6  # the T-rex head
head = [
    block(0, 15.0, HZ, 8.0, 5.0, 8.4, "Hide"),  # the skull...
    block(0, 14.6, HZ - 5.0, 6.4, 3.6, 3.0, "Hide"),  # ...a long snout...
    block(0, 9.4, HZ - 1.4, 7.2, 1.8, 9.0, "Hide", rot=(-20, 0, 0)),  # ...the lower jaw, wide open
    block(0, 11.6, HZ - 0.4, 6.0, 3.6, 7.0, "Mouth"),
    block(0, 11.6, HZ + 2.9, 4.0, 2.8, 0.6, "Glow"),  # a glowing throat
    block(0, 17.8, HZ + 1.0, 0.8, 1.8, 1.8, "Spike", rot=(45, 0, 0)),
]
for z in (-15.2, -14.0, -12.6, -11.2, -9.8, -8.4):  # rows of white teeth
    jaw = 10.36 + (z + 11.0) * 0.364  # (the open jaw's top)
    head += both(
        block(2.7, 12.0, z, 0.6, 1.2, 0.6, "Tooth"),
        block(2.5, jaw + 0.5, z + 0.2, 0.6, 1.0, 0.6, "Tooth"),
    )
head += [block(x, 12.4, HZ - 6.0, 0.6, 1.2, 0.6, "Tooth") for x in (-1.6, -0.5, 0.6, 1.7)]
head += both(
    block(3.9, 16.4, HZ - 2.6, 1.4, 1.2, 1.6, "Glow"),  # glowing eyes...
    block(3.4, 17.5, HZ - 2.6, 2.2, 0.8, 2.8, "HideDark"),  # ...under heavy brows
    plate(1.4, 15.2, HZ - 6.55, 0.6, 0.4, "Dark", depth=0.1),  # nostrils
)

arms = []
for s in (-1, 1):
    arms.append(block(s * 10.2, 13.6, 4.0, 12.0, 1.0, 7.0, "Hide"))  # the wings...
    arms.append(block(s * 12.4, 14.15, 4.8, 6.0, 0.2, 4.0, "HideDark"))
    for x in (7.8, 13.2):  # ...two propeller engines each
        arms += [
            solid("Cylinder", s * x, 13.0, 2.2, 7.0, 3.4, 3.4, "Engine", rot=(0, 90, 0)),
            solid("Ball", s * x, 13.0, -1.5, 1.6, 1.6, 1.6, "HideDark"),
            block(s * x, 13.0, -1.9, 0.7, 6.4, 0.3, "Blade"),
            block(s * x, 13.0, -1.9, 6.4, 0.7, 0.3, "Blade"),
            block(s * x, 16.0, -1.95, 0.8, 0.6, 0.35, "Tip"),
            block(s * x, 10.0, -1.95, 0.8, 0.6, 0.35, "Tip"),
            block(s * x + 3.0, 13.0, -1.95, 0.6, 0.8, 0.35, "Tip"),
            block(s * x - 3.0, 13.0, -1.95, 0.6, 0.8, 0.35, "Tip"),
        ]

legs = []
for x, z in ((-2.8, 9.0), (2.8, 9.0), (0, -3.0)):  # the landing gear
    legs += [
        rod((x, 9.6, z), (x, 2.0, z), 0.8, "Gear"),
        solid("Cylinder", x, 1.6, z, 1.2, 3.2, 3.2, "Tire"),
        solid("Cylinder", x, 1.6, z, 1.3, 1.4, 1.4, "Gear"),
    ]

ART = {
    "Comment": "Nuclearo Dinossauro: a big bomber with dark dino hide, a spiked ridge, a glass cockpit and a tall tail fin, its nose a roaring T-rex head with glowing green eyes and throat, wings with propeller engines, landing gear.",
    "VoxelSize": 0.2,
    "Palette": {
        "Hide": (98, 94, 84),
        "HideDark": (66, 62, 56),
        "Spike": (140, 132, 116),
        "Glass": (170, 220, 245),
        "Mouth": (110, 30, 36),
        "Glow": (120, 255, 90),
        "Tooth": (250, 248, 236),
        "Dark": (24, 22, 20),
        "Engine": (76, 74, 70),
        "Blade": (60, 58, 56),
        "Tip": (250, 210, 50),
        "Gear": (150, 155, 160),
        "Tire": (30, 30, 32),
        "Bomb": (70, 76, 70),
    },
    "Materials": {"Glow": "Neon"},
    "Joints": {"Legs": (0, 9.4, 6.0), "Head": (0, 13.6, -8.0)},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
