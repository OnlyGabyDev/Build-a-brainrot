# Il Bisonte Giuppitere (art v2, blocks): a bison planet, after the original meme image
# (by @duchampino.creatu, 2025-05-17): a big shaggy bison's head (dark brown fur, curved
# horns, a broad muzzle, a beard) in front of planet Jupiter (a big ball in cream, tan and
# orange bands, its great red spot), standing on a pair of giant black high-top sneakers
# (white soles and laces; no logos). The meme shows no arms: ours are two little moons
# circling the planet. Ours: the great red spot glows (a Mythic).
import math

from voxel_art import block, both, plate, rod, solid

PY, PZ = 17.0, 2.0  # Jupiter's middle
R = 8.0

body = [solid("Ball", 0, PY, PZ, 2 * R, 2 * R, 2 * R, "Cream")]  # planet Jupiter...
for k, (dy, color) in enumerate(((-5.6, "Band2"), (-3.6, "Band1"), (-1.4, "Band2"), (1.2, "Band1"), (3.4, "Band3"), (5.6, "Band2"))):  # ...its bands
    r = math.sqrt(R * R - dy * dy) + 0.15
    body.append(solid("Cylinder", 0, PY + dy, PZ, 1.2, 2 * r, 2 * r, color, rot=(0, 0, 90)))
body += [
    solid("Ball", 5.2, PY - 2.8, PZ - 4.6, 3.0, 3.0, 3.0, "Spot"),  # ...its great red spot
    block(0, PY - R + 0.8, PZ + 0.4, 4.0, 1.6, 3.6, "Cream"),  # (where the shoes meet it)
]

HY, HZ = PY + 1.0, PZ - R - 1.4  # the bison's head, before the planet
head = [
    block(0, HY, HZ, 7.6, 7.4, 5.2, "Fur"),  # a big shaggy head...
    block(0, HY + 3.4, HZ + 0.4, 8.6, 2.6, 5.0, "FurDark"),  # ...a woolly crown
    block(0, HY - 2.4, HZ - 2.6, 5.0, 3.4, 2.0, "Muzzle"),  # ...a broad muzzle...
    block(0, HY - 2.0, HZ - 3.65, 3.6, 1.6, 0.3, "Nose"),
    block(0, HY - 5.4, HZ - 0.6, 4.2, 3.4, 3.4, "FurDark"),  # ...a beard
]
head += both(
    plate(1.0, HY - 2.0, HZ - 3.85, 0.7, 0.8, "Dark", depth=0.15),  # nostrils
    plate(2.2, HY + 0.8, HZ - 2.75, 1.0, 0.8, "Dark", depth=0.2),  # small dark eyes
    plate(2.0, HY + 1.0, HZ - 2.9, 0.3, 0.3, "Glint", depth=0.1),
    block(4.2, HY + 1.2, HZ + 0.4, 1.6, 1.0, 2.0, "FurDark", rot=(0, 0, -20)),  # ears
)
for s in (-1, 1):  # curved horns
    pts = [(s * 3.6, HY + 3.0, HZ + 0.4), (s * 6.0, HY + 3.4, HZ + 0.2), (s * 7.2, HY + 5.4, HZ - 0.2), (s * 6.6, HY + 7.6, HZ - 0.6)]
    for k in range(3):
        head.append(rod(pts[k], pts[k + 1], 1.8 - k * 0.45, "Horn"))

arms = []
for s in (-1, 1):  # (ours) two little moons circling the planet
    c = (s * (R + 3.0), PY + 1.0 * s, PZ)
    arms += [
        solid("Cylinder", s * (R - 0.2), PY + 0.5 * s, PZ, 6.6, 0.4, 0.4, "Orbit", rot=(0, 0, s * 8)),
        solid("Ball", *c, 2.8, 2.8, 2.8, "Moon"),
        solid("Ball", c[0] + 0.4, c[1] + 0.5, c[2] - 1.0, 0.9, 0.9, 0.9, "MoonDark"),
    ]

legs = []
for s in (-1, 1):  # giant black high-top sneakers
    x = s * 3.0
    legs += [
        block(x, 4.8, PZ, 4.4, 6.4, 5.2, "Shoe"),  # a tall black top...
        block(x, 1.4, PZ - 1.4, 5.0, 2.0, 9.6, "Shoe"),  # ...the foot...
        block(x, 0.4, PZ - 1.4, 5.4, 0.8, 10.2, "Sole"),  # ...a white sole...
        block(x, 1.6, PZ - 6.15, 5.2, 1.2, 0.6, "Sole"),  # (a white toe cap)
        block(x, 8.2, PZ, 4.6, 0.6, 5.4, "Sole"),  # (a white collar)
    ]
    for k in range(4):  # ...white laces
        legs.append(block(x, 3.0 + k * 1.3, PZ - 2.75, 2.6, 0.35, 0.4, "Sole"))

ART = {
    "Comment": "Il Bisonte Giuppitere: a big shaggy bison's head with curved horns and a beard in front of planet Jupiter (its bands, a glowing great red spot), standing on giant black high-top sneakers, two little moons circling it.",
    "VoxelSize": 0.2,
    "Palette": {
        "Cream": (238, 220, 186),
        "Band1": (214, 160, 110),
        "Band2": (196, 120, 70),
        "Band3": (226, 190, 150),
        "Spot": (196, 70, 50),
        "Fur": (96, 64, 40),
        "FurDark": (70, 46, 30),
        "Muzzle": (60, 44, 36),
        "Nose": (36, 28, 26),
        "Dark": (18, 14, 12),
        "Glint": (240, 240, 240),
        "Horn": (220, 206, 176),
        "Orbit": (220, 220, 230),
        "Moon": (206, 206, 214),
        "MoonDark": (160, 160, 170),
        "Shoe": (30, 30, 34),
        "Sole": (244, 244, 240),
    },
    "Materials": {"Spot": "Neon"},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
