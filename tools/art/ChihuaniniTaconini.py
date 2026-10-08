# Chihuanini Taconini (art v2, blocks): a taco chihuahua, after the original meme image (by
# @chancladlagfa): a tan chihuahua (huge ears, big glossy eyes, a dark nose) in a straw
# sombrero with a red and green zigzag band, its middle wrapped in a crunchy taco shell
# full of brown meat, green lettuce and red tomato; thin dog legs (the front pair are its
# "arms") and a little curled tail.
import math

from voxel_art import block, both, plate, rod, solid

CY, CZ = 9.4, 1.0  # the taco's middle

body = [
    block(0, CY - 0.4, CZ - 4.4, 4.6, 4.4, 3.0, "Tan"),  # the dog's chest...
    block(0, CY - 0.2, CZ + 4.2, 4.4, 4.2, 2.8, "Tan"),  # ...its rear
    solid("Cylinder", 0, CY, CZ, 7.4, 8.6, 8.6, "Shell", rot=(0, 90, 0)),  # a crunchy taco shell...
    block(0, CY + 2.2, CZ, 7.0, 4.4, 7.6, "Meat"),  # ...full of meat...
]
for x, z, c in ((-3.0, -3.0, "Lettuce"), (3.0, -2.4, "Lettuce"), (-2.8, 1.8, "Lettuce"), (2.8, 2.6, "Lettuce"), (-1.2, -3.4, "Tomato"), (1.6, 0.4, "Tomato"), (-0.6, 3.0, "Tomato"), (0.4, -1.4, "Lettuce")):
    body.append(block(x, CY + 4.6, CZ + z, 2.2 if c == "Lettuce" else 1.4, 1.0, 1.8 if c == "Lettuce" else 1.4, c, rot=(0, (x * 20) % 40 - 20, 0)))
body += [rod((0, CY + 1.0, CZ + 5.4), (0, CY + 3.6, CZ + 6.6), 0.8, "Tan"), rod((0, CY + 3.6, CZ + 6.6), (0, CY + 4.2, CZ + 5.4), 0.7, "Tan")]  # a curled tail

HY, HZ = CY + 5.6, CZ - 5.6  # the head
head = [
    block(0, HY - 2.6, HZ + 0.8, 3.0, 2.6, 2.6, "Tan"),  # (its neck)
    block(0, HY, HZ, 5.4, 4.6, 4.6, "Tan"),  # a round chihuahua head...
    block(0, HY - 1.0, HZ - 2.8, 2.6, 1.8, 1.6, "Tan"),  # ...a short muzzle...
    block(0, HY - 1.6, HZ - 2.6, 2.2, 0.8, 1.4, "Light"),
    block(0, HY - 0.4, HZ - 3.75, 1.2, 0.8, 0.4, "Dark"),  # ...a dark nose
]
head += both(
    solid("Cylinder", 1.4, HY + 0.4, HZ - 2.4, 0.4, 1.9, 1.9, "Eye", rot=(0, 90, 0)),  # big glossy eyes
    plate(1.15, HY + 0.75, HZ - 2.7, 0.5, 0.5, "Glint", depth=0.1),
    block(3.4, HY + 2.2, HZ + 0.4, 2.8, 3.8, 0.8, "Tan", rot=(0, 0, -40)),  # huge ears...
    block(3.3, HY + 2.1, HZ - 0.05, 1.8, 2.8, 0.2, "Pink", rot=(0, 0, -40)),  # ...pink inside
)
HAT = HY + 3.4
head += [
    solid("Cylinder", 0, HAT, HZ + 0.4, 0.6, 12.0, 12.0, "Straw", rot=(0, 0, 90)),  # a straw sombrero: the brim...
    solid("Cylinder", 0, HAT + 1.4, HZ + 0.4, 2.4, 5.4, 5.4, "Straw", rot=(0, 0, 90)),  # ...a tall crown...
    solid("Cylinder", 0, HAT + 2.9, HZ + 0.4, 0.8, 4.0, 4.0, "Straw", rot=(0, 0, 90)),
    solid("Cylinder", 0, HAT + 0.8, HZ + 0.4, 0.6, 5.6, 5.6, "Red", rot=(0, 0, 90)),  # ...a red band...
    solid("Cylinder", 0, HAT + 0.35, HZ + 0.4, 0.2, 11.0, 11.0, "Green", rot=(0, 0, 90)),  # ...a green zigzag ring on the brim
]
for k in range(12):
    a = math.radians(k * 30)
    head.append(block(math.sin(a) * 4.6, HAT + 0.4, HZ + 0.4 - math.cos(a) * 4.6, 1.2, 0.2, 0.5, "Red", rot=(0, -math.degrees(a) + 30, 0)))


def leg(x, z):
    return [
        block(x, 3.4, z, 1.2, 6.8, 1.2, "Tan"),
        block(x, 0.4, z - 0.4, 1.4, 0.8, 2.2, "Light"),
    ]


arms = leg(-1.6, CZ - 4.4) + leg(1.6, CZ - 4.4)
legs = leg(-1.6, CZ + 4.2) + leg(1.6, CZ + 4.2)

ART = {
    "Comment": "Chihuanini Taconini: a tan chihuahua with huge ears and big glossy eyes in a straw sombrero with a red and green band, its middle wrapped in a taco full of meat, lettuce and tomato, thin legs, a curled tail.",
    "VoxelSize": 0.2,
    "Palette": {
        "Tan": (210, 160, 100),
        "Light": (236, 206, 160),
        "Dark": (30, 22, 20),
        "Eye": (30, 24, 22),
        "Glint": (250, 250, 250),
        "Pink": (230, 160, 150),
        "Shell": (240, 196, 80),
        "ShellDark": (214, 160, 56),
        "Meat": (120, 70, 40),
        "Lettuce": (110, 190, 60),
        "Tomato": (220, 50, 40),
        "Straw": (232, 200, 130),
        "Red": (204, 40, 44),
        "Green": (40, 140, 70),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
