# Malame Amarele (art v2, blocks): a sad yellow lump, after the original meme image (by
# @ofuscabreno): a big mustard-yellow lump shaped like a rounded cone, covered in dark
# cracks, two huge glossy eyes with dark rims and a worried little mouth; its bottom spreads
# into fat fingers with pale nails, splayed all round the front (the outer ones are its
# "arms", the front ones its "legs").
import math

from voxel_art import block, both, plate, rod, solid


BALLS = [((0, 7.4, 0.8), 7.4), ((0, 12.6, 0.4), 5.2), ((0, 16.6, 0.2), 3.0)]  # (a lump: one ball on another)


def cracks(balls, seed, count, skip=None):
    out = []
    for k in range(count):
        c, r = balls[k % len(balls)]
        a = math.radians(((k * 137.5 + seed) % 360))
        y = -0.2 + ((k * 0.618 + seed * 0.07) % 1.0) * 1.0
        if y < 0:
            y = 0.4 * y
        h = math.sqrt(max(0.0, 1 - y * y))
        n = (math.sin(a) * h, y, -math.cos(a) * h)
        if c[1] + n[1] * r < 1.4 or (skip and skip(n, c[1] + n[1] * r)):
            continue
        out.append(block(c[0] + n[0] * (r + 0.05), c[1] + n[1] * r, c[2] + n[2] * (r + 0.05), 0.3, 1.8, 0.25, "Crack", rot=(-math.degrees(math.asin(n[1])) * 0.0, -math.degrees(a), 40 if k % 2 else -40)))
    return out


body = [solid("Ball", *BALLS[0][0], 2 * BALLS[0][1], 2 * BALLS[0][1], 2 * BALLS[0][1], "Yellow")]
body += cracks(BALLS[:1], 7, 18, skip=lambda n, y: n[2] < -0.7 and 8.4 < y < 11.0)

head = [solid("Ball", *c, 2 * r, 2 * r, 2 * r, "Yellow") for c, r in BALLS[1:]]
head += cracks(BALLS[1:], 3, 14, skip=lambda n, y: n[2] < -0.4 and y < 16.0)
EY = 13.0  # the eyes, on the head's front
for s in (-1, 1):
    x = s * 2.5
    EZ = BALLS[1][0][2] - math.sqrt(BALLS[1][1] ** 2 - x * x - (EY - BALLS[1][0][1]) ** 2)
    head += [
        solid("Cylinder", x, EY, EZ - 0.1, 0.8, 3.8, 3.8, "Rim", rot=(0, 90, 0)),  # huge glossy eyes...
        solid("Cylinder", x, EY, EZ - 0.45, 0.6, 3.1, 3.1, "White", rot=(0, 90, 0)),
        solid("Cylinder", x, EY - 0.1, EZ - 0.75, 0.6, 2.1, 2.1, "Pupil", rot=(0, 90, 0)),
        plate(x - s * 0.4, EY + 0.5, EZ - 1.1, 0.6, 0.6, "White", depth=0.2),
        block(x + s * 0.2, EY + 2.3, EZ + 0.2, 2.4, 0.4, 0.6, "Crack", rot=(0, 0, s * 14)),  # (worried brows)
    ]
MY = 9.8  # a worried little mouth, on the lump below
MZ = BALLS[0][0][2] - math.sqrt(BALLS[0][1] ** 2 - (MY - BALLS[0][0][1]) ** 2)
body += [
    block(0, MY, MZ - 0.1, 2.6, 0.35, 0.6, "Crack"),
    block(-1.5, MY - 0.2, MZ, 0.7, 0.35, 0.6, "Crack", rot=(0, 0, 30)),
    block(1.5, MY - 0.2, MZ, 0.7, 0.35, 0.6, "Crack", rot=(0, 0, -30)),
]


def finger(base, angle, length, thick):
    a = math.radians(angle)
    d = (math.sin(a), 0.0, -math.cos(a))
    tip = (base[0] + d[0] * length, base[1], base[2] + d[2] * length)
    return [
        rod(base, tip, thick, "Yellow"),
        solid("Ball", *tip, thick + 0.3, thick + 0.3, thick + 0.3, "Yellow"),
        block(tip[0] - d[0] * 0.3, tip[1] + thick / 2 - 0.05, tip[2] - d[2] * 0.3, 1.2, 0.3, 1.0, "Nail", rot=(0, -angle, 0)),
        block(tip[0] - d[0] * 1.6, tip[1] + thick / 2 - 0.1, tip[2] - d[2] * 1.6, thick - 0.2, 0.25, 0.3, "Crack", rot=(0, -angle, 0)),  # (a knuckle line)
    ]


legs = []
for s in (-1, 1):  # fat fingers splayed in front
    for k, (x, ang) in enumerate(((1.4, 8), (3.6, 18), (5.6, 30))):
        legs += finger((s * x, 1.3, -4.2 + k * 0.9), s * ang, 4.6 - k * 0.3, 2.4)
arms = []
for s in (-1, 1):  # ...and the outer ones round its sides
    for k, (z, ang) in enumerate(((-1.4, 58), (1.6, 82))):
        arms += finger((s * 6.6, 1.4, z), s * ang, 4.0 - k * 0.6, 2.2)

ART = {
    "Comment": "Malame Amarele: a big mustard-yellow lump shaped like a rounded cone covered in dark cracks, two huge glossy eyes, a worried little mouth, its bottom spreading into fat fingers with pale nails.",
    "VoxelSize": 0.2,
    "Palette": {
        "Yellow": (226, 168, 48),
        "Crack": (150, 96, 30),
        "Rim": (120, 76, 30),
        "White": (250, 250, 250),
        "Pupil": (20, 18, 22),
        "Nail": (250, 240, 226),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
