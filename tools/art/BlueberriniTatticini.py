# Blueberrini Tatticini (art v2, blocks): a blueberry bear, after the original meme image
# (by @alexey_pigeon): a chubby dusty-blue teddy bear made of blueberries (a round belly
# and head, the berry's little star-shaped crown on top of its head), round ears, small
# black eyes and a dark nose on a pale muzzle; stubby arms and legs.
import math

from voxel_art import block, both, plate, rod, solid

body = [
    solid("Ball", 0, 9.4, 0.8, 13.0, 13.0, 13.0, "Berry"),  # a chubby blueberry belly...
    solid("Ball", 0, 8.6, -3.2, 7.0, 7.0, 7.0, "BerryLight"),  # ...a paler front
]

HY = 19.6  # the head
head = [
    solid("Ball", 0, HY, 0.2, 10.6, 10.6, 10.6, "Berry"),  # a round blueberry head...
    solid("Ball", 0, HY - 1.6, -4.0, 4.4, 4.4, 4.4, "Muzzle"),  # ...a pale muzzle
    block(0, HY - 0.9, -6.2, 1.6, 1.0, 0.6, "Dark"),  # a dark nose
    plate(0, HY - 2.4, -6.05, 1.4, 0.3, "Dark", depth=0.15),
]
for k in range(5):  # the berry's star-shaped crown on top
    a = math.radians(k * 72)
    head.append(rod((0, HY + 5.0, 0.2), (math.sin(a) * 1.6, HY + 6.0, 0.2 - math.cos(a) * 1.6), 0.8, "Crown"))
head.append(solid("Cylinder", 0, HY + 5.2, 0.2, 0.8, 1.6, 1.6, "Dark", rot=(0, 0, 90)))
head += both(
    solid("Ball", 3.6, HY + 3.8, 0.4, 3.4, 3.4, 3.4, "Berry"),  # round ears
    solid("Ball", 3.7, HY + 3.9, -0.9, 1.8, 1.8, 1.8, "BerryLight"),
    plate(1.9, HY + 0.6, -4.75, 1.0, 1.2, "Dark", depth=0.3),  # small black eyes
    plate(1.75, HY + 0.95, -4.95, 0.35, 0.35, "Glint", depth=0.1),
)

arms = []
for s in (-1, 1):  # stubby arms
    arms += [
        solid("Ball", s * 6.2, 11.6, 0.2, 4.0, 4.0, 4.0, "Berry"),
        rod((s * 6.4, 11.0, 0.0), (s * 7.4, 7.8, -1.4), 3.0, "Berry"),
        solid("Ball", s * 7.5, 7.4, -1.6, 3.2, 3.2, 3.2, "BerryLight"),
    ]

legs = []
for s in (-1, 1):  # stubby legs
    legs += [
        block(s * 2.8, 2.4, 0.6, 3.6, 4.0, 3.6, "Berry"),
        block(s * 2.8, 0.8, -0.6, 4.0, 1.6, 4.8, "Berry"),
        plate(s * 2.8, 0.9, -3.05, 2.4, 1.0, "BerryLight", depth=0.2),
    ]

ART = {
    "Comment": "Blueberrini Tatticini: a chubby dusty-blue teddy bear made of blueberries, a round belly and head with the berry's star crown on top, round ears, small black eyes and a dark nose on a pale muzzle, stubby arms and legs.",
    "VoxelSize": 0.2,
    "Palette": {
        "Berry": (78, 96, 170),
        "BerryLight": (120, 140, 200),
        "Muzzle": (160, 176, 220),
        "Crown": (60, 70, 120),
        "Dark": (24, 24, 40),
        "Glint": (250, 250, 250),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
