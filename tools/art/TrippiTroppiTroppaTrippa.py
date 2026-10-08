# Trippi Troppi Troppa Trippa (art v2, blocks): a fish-headed bear, after the original meme
# image (by @1raidex_): a fat brown bear standing up (a big round pale belly, furry arms and
# legs) with a fish's head (olive green, a big round yellow eye, a gaping mouth with sharp
# little teeth), a spiky orange fin along its back and a fish's tail fin behind.
from voxel_art import block, both, plate, rod, solid, wedge

BY = 10.6  # the belly's middle
body = [
    block(0, BY, 0.8, 8.6, 9.6, 7.4, "Fur"),  # a fat brown bear...
    solid("Ball", 0, BY - 0.8, -1.6, 8.4, 8.4, 8.4, "Belly"),  # ...a big round pale belly
    block(0, BY + 5.4, 0.6, 7.0, 1.6, 6.6, "Fur"),  # (its shoulders)
]
for k in range(5):  # a spiky orange fin along its back
    body.append(wedge(0, BY + 4.6 - k * 1.8, 4.9 + k * 0.2, 0.6, 2.6 - k * 0.2, 2.2, "Fin", rot=(-20, 180, 0)))
body += [  # a fish's tail fin behind
    block(0, BY - 3.8, 5.2, 2.4, 2.4, 2.0, "Fish"),
    wedge(0, BY - 1.4, 7.4, 0.8, 4.2, 3.4, "Fin", rot=(0, 180, 0)),
    wedge(0, BY - 6.2, 7.4, 0.8, 4.2, 3.4, "Fin", rot=(180, 0, 0)),
]

HY, HZ = BY + 8.8, -0.8  # the fish head
head = [
    block(0, HY, HZ, 6.6, 7.0, 7.6, "Fish"),  # an olive green fish head...
    block(0, HY - 2.6, HZ - 0.6, 6.0, 2.0, 7.0, "FishPale"),  # ...a pale throat...
    block(0, HY - 1.0, HZ - 4.0, 5.2, 3.4, 0.6, "Mouth"),  # ...a gaping mouth...
    block(0, HY + 0.85, HZ - 4.2, 5.6, 0.6, 1.2, "Fish"),  # (its lips)
    block(0, HY - 2.95, HZ - 4.2, 5.6, 0.6, 1.2, "FishPale"),
    wedge(0, HY + 4.0, HZ + 1.4, 0.6, 2.0, 4.0, "Fin", rot=(0, 180, 0)),  # (a fin on top)
]
for k in range(6):  # ...sharp little teeth
    x = -2.0 + k * 0.8
    head += [
        block(x, HY + 0.3, HZ - 4.45, 0.4, 0.7, 0.3, "Tooth"),
        block(x + 0.4, HY - 2.35, HZ - 4.45, 0.4, 0.7, 0.3, "Tooth"),
    ]
head += both(
    solid("Cylinder", 3.35, HY + 1.6, HZ - 1.0, 0.5, 3.0, 3.0, "EyeYellow"),  # a big round yellow eye...
    solid("Cylinder", 3.65, HY + 1.6, HZ - 1.2, 0.4, 1.6, 1.6, "Dark"),
    plate(3.85, HY + 2.0, HZ - 1.6, 0.4, 0.4, "Glint", depth=0.1, rot=(0, 90, 0)),
    plate(3.35, HY - 0.6, HZ + 1.6, 0.4, 3.0, "FishDark", depth=0.2, rot=(0, 90, 0)),  # (a gill)
)

arms = []
for s in (-1, 1):  # furry bear arms
    arms += [
        solid("Ball", s * 4.8, BY + 4.2, 0.8, 3.6, 3.6, 3.6, "Fur"),
        rod((s * 5.0, BY + 3.6, 0.6), (s * 5.8, BY - 1.6, -0.6), 2.6, "Fur"),
        block(s * 5.8, BY - 2.6, -0.8, 2.6, 2.0, 2.6, "FurDark"),
    ]

legs = []
for s in (-1, 1):  # furry bear legs
    legs += [
        block(s * 2.6, 3.6, 0.8, 3.4, 5.6, 3.6, "Fur"),
        block(s * 2.6, 0.8, -0.2, 3.6, 1.6, 4.8, "FurDark"),
    ]

ART = {
    "Comment": "Trippi Troppi Troppa Trippa: a fat brown bear standing up with a big pale belly and a fish's head (olive green, a big yellow eye, a gaping mouth with sharp teeth), a spiky orange fin along its back and a tail fin.",
    "VoxelSize": 0.2,
    "Palette": {
        "Fur": (110, 76, 50),
        "FurDark": (84, 56, 38),
        "Belly": (226, 206, 160),
        "Fish": (120, 140, 60),
        "FishDark": (86, 104, 44),
        "FishPale": (206, 210, 150),
        "Mouth": (70, 30, 30),
        "Tooth": (250, 248, 236),
        "EyeYellow": (240, 220, 80),
        "Dark": (20, 18, 16),
        "Glint": (250, 250, 250),
        "Fin": (236, 150, 50),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
