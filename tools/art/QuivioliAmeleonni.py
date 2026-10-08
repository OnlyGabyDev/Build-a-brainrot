# Quivioli Ameleonni (art v2, blocks): a kiwi chameleon, after the original meme image (by
# @alexey_pigeon): a brown-orange chameleon whose body is a thick slice of kiwi (a fuzzy
# brown rim, bright green flesh with a ring of black seeds round a white core on both
# sides), a crested chameleon head with big round green turret eyes, a tail curled into a
# spiral; four bent legs with gripping two-toed feet (the front pair are its "arms").
import math

from voxel_art import block, both, plate, rod, solid

CY, CZ = 11.0, 1.0  # the kiwi's middle
W, D = 6.4, 12.0  # its thickness and size

body = [solid("Cylinder", 0, CY, CZ, W, D, D, "Rim")]  # a thick kiwi slice: a fuzzy rim...
for s in (-1, 1):
    x = s * (W / 2 + 0.2)
    body += [
        solid("Cylinder", x, CY, CZ, 0.4, D - 1.0, D - 1.0, "Kiwi"),  # ...bright green flesh...
        solid("Cylinder", x + s * 0.3, CY, CZ, 0.4, 6.4, 6.4, "KiwiLight"),
        solid("Cylinder", x + s * 0.6, CY, CZ, 0.4, 2.8, 2.8, "Core"),  # ...a white core...
    ]
    for k in range(14):  # ...a ring of black seeds
        a = math.radians(k * 360 / 14)
        body.append(block(x + s * 0.55, CY + math.cos(a) * 2.5, CZ + math.sin(a) * 2.5, 0.3, 0.9, 0.45, "Seed", rot=(-math.degrees(a), 0, 0)))
spiral = []
for k in range(16):  # a tail curled into a spiral
    t = k / 15
    a = math.radians(-60 + t * 520)
    r = 4.2 * (1 - t) + 0.6
    spiral.append((0, CY - 1.4 + math.cos(a) * r * 0.9 - 1.6 * (1 - t), CZ + D / 2 + 3.4 + math.sin(a) * r))
for k, p in enumerate(spiral):
    d = 2.6 * (1 - k / 16) + 0.8
    body.append(solid("Ball", *p, d, d, d, "Skin" if k % 3 else "SkinDark"))

HY, HZ = CY + 3.6, CZ - D / 2 - 2.4  # the head
head = [
    rod((0, CY + 2.0, CZ - D / 2 + 1.8), (0, HY - 0.4, HZ + 1.6), 3.2, "Skin"),  # a neck...
    block(0, HY, HZ, 4.2, 4.0, 5.0, "Skin"),  # ...a crested chameleon head...
    block(0, HY - 0.8, HZ - 3.0, 3.2, 2.6, 2.0, "Skin"),  # ...a blunt snout...
    plate(0, HY - 1.6, HZ - 4.05, 2.6, 0.3, "Dark", depth=0.15),  # ...a long mouth line
    block(0, HY + 2.6, HZ + 1.4, 1.4, 2.4, 4.4, "SkinDark", rot=(25, 0, 0)),  # the crest
]
head += both(
    block(2.15, HY - 1.6, HZ - 1.6, 0.3, 0.3, 4.4, "Dark"),  # (the mouth's line down its sides)
    solid("Cylinder", 2.4, HY + 0.6, HZ - 0.8, 1.6, 3.4, 3.4, "Skin"),  # round turret eyes...
    solid("Cylinder", 3.25, HY + 0.6, HZ - 0.8, 0.4, 2.6, 2.6, "Eye"),  # ...bright green...
    solid("Cylinder", 3.55, HY + 0.6, HZ - 1.0, 0.4, 1.2, 1.2, "Dark"),  # ...a black pupil
    plate(3.75, HY + 1.0, HZ - 1.3, 0.4, 0.4, "Glint", depth=0.1, rot=(0, 90, 0)),
    plate(1.0, HY - 0.6, HZ - 4.05, 0.4, 0.4, "Dark", depth=0.1),  # nostrils
)


def leg(x, z, forward):
    s = 1 if x > 0 else -1
    hip, knee, foot = (x, CY - 3.8, z), (x + s * 2.2, 4.4, z - forward), (x + s * 2.4, 0.6, z - forward * 0.4)
    return [
        rod(hip, knee, 1.6, "Skin"),
        solid("Ball", *knee, 1.8, 1.8, 1.8, "SkinDark"),
        rod(knee, foot, 1.4, "Skin"),
        block(foot[0], 0.5, foot[2] - 1.0, 1.6, 1.0, 1.6, "Skin"),  # two-toed gripping feet
        block(foot[0], 0.5, foot[2] + 0.9, 1.4, 1.0, 1.4, "Skin"),
    ]


arms = leg(-2.2, CZ - 3.0, 1.6) + leg(2.2, CZ - 3.0, 1.6)
legs = leg(-2.2, CZ + 3.4, -1.2) + leg(2.2, CZ + 3.4, -1.2)

ART = {
    "Comment": "Quivioli Ameleonni: a brown-orange chameleon whose body is a thick kiwi slice (green flesh, black seeds, white core on both sides), a crested head with big round green turret eyes, a spiral tail, four bent legs.",
    "VoxelSize": 0.2,
    "Palette": {
        "Rim": (120, 84, 50),
        "Kiwi": (120, 200, 40),
        "KiwiLight": (176, 224, 80),
        "Core": (244, 246, 220),
        "Seed": (24, 22, 18),
        "Skin": (204, 126, 72),
        "SkinDark": (164, 96, 56),
        "Eye": (110, 210, 60),
        "Dark": (36, 26, 22),
        "Glint": (250, 250, 250),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
