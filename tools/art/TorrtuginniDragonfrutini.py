# Torrtuginni Dragonfrutini (art v2, blocks): a dragon-fruit tortoise, after the original
# meme image (by @alexey_pigeon, 2025-03-17): a pink scaly tortoise whose shell is a big
# dragon fruit (a hot pink dome covered in pink scales tipped with lime green), a lime
# green rim round it; a smiling pink head on a long neck (a pale throat, a red eye), four
# thick pink scaly legs with lime claws. Ours: the scale tips glow (a Godly).
import math

from voxel_art import block, both, plate, rod, solid

CZ = 0.6  # the shell's middle
Y0 = 6.6  # its rim
RS, HS = 8.6, 9.6  # its radius and height


def upright(x, y, z, height, d, color):
    return solid("Cylinder", x, y, z, height, d, d, color, rot=(0, 0, 90))


def leaf(p0, d, t, width, length, thick, color):
    """A flat block from p0 along d, `width` across along t (a scale lying on the shell)."""
    n = (t[1] * d[2] - t[2] * d[1], t[2] * d[0] - t[0] * d[2], t[0] * d[1] - t[1] * d[0])
    m = [[t[i], d[i], n[i]] for i in range(3)]  # (columns: the block's X, Y and Z)
    rx = math.degrees(math.atan2(-m[1][2], m[2][2]))
    ry = math.degrees(math.asin(max(-1.0, min(1.0, m[0][2]))))
    rz = math.degrees(math.atan2(-m[0][1], m[0][0]))
    c = [p0[i] + d[i] * length / 2 for i in range(3)]
    return block(*c, width, length, thick, color, rot=(rx, ry, rz))


def radius_at(y):
    return RS * math.sqrt(max(0.0, 1 - ((y - Y0) / HS) ** 2))


body = [
    upright(0, Y0 - 0.2, CZ, 1.4, 2 * RS + 0.8, "Rim"),  # a lime green rim...
    block(0, Y0 - 1.5, CZ, 11.0, 1.6, 12.6, "Belly"),  # ...a pale belly plate
]
y = Y0 + 0.5
for d, h in ((2 * RS, 2.2), (2 * RS - 1.4, 2.0), (2 * RS - 3.6, 2.0), (2 * RS - 6.8, 1.8), (2 * RS - 10.6, 1.4)):
    body.append(upright(0, y + h / 2, CZ, h, d, "Shell"))  # a hot pink dragon-fruit dome...
    y += h
RINGS = ((Y0 + 1.6, 11, 0.0, 0.75), (Y0 + 4.4, 10, 18.0, 0.62), (Y0 + 6.8, 8, 0.0, 0.45), (Y0 + 8.4, 5, 36.0, 0.2))
for ring, (ry, count, phase, out) in enumerate(RINGS):  # ...covered in pink scales tipped with green
    r = radius_at(ry) - 0.6
    for k in range(count):
        a = math.radians(phase + k * 360 / count)
        if ring < 2 and math.cos(a) > 0.8:  # (none over the neck)
            continue
        h = (math.sin(a), 0.0, -math.cos(a))
        up = math.sqrt(1 - out * out)
        d = (h[0] * out, up, h[2] * out)
        p0 = (h[0] * r, ry, CZ + h[2] * r)
        t = (math.cos(a), 0.0, math.sin(a))
        pm = tuple(p0[i] + d[i] * 2.6 for i in range(3))
        body += [leaf(p0, d, t, 3.4, 2.9, 0.8, "Scale"), leaf(pm, d, t, 1.6, 1.6, 0.7, "Tip"), leaf(tuple(pm[i] + d[i] * 1.4 for i in range(3)), d, t, 0.7, 1.2, 0.6, "Tip")]
for k in range(3):  # (a crown of scales on top)
    a = math.radians(k * 120 + 60)
    body += [
        rod((0, Y0 + HS - 0.6, CZ), (math.sin(a) * 1.2, Y0 + HS + 1.6, CZ - math.cos(a) * 1.2), 2.2, "Scale"),
        rod((math.sin(a) * 1.2, Y0 + HS + 1.6, CZ - math.cos(a) * 1.2), (math.sin(a) * 1.8, Y0 + HS + 3.2, CZ - math.cos(a) * 1.8), 1.1, "Tip"),
    ]
body.append(rod((0, Y0 - 0.6, CZ + RS - 0.4), (0, Y0 - 1.6, CZ + RS + 2.0), 1.6, "Skin"))  # a stubby tail

HY, HZ = Y0 + 5.4, CZ - RS - 4.8  # the head
head = [
    rod((0, Y0 - 0.2, CZ - RS + 1.8), (0, HY - 1.2, HZ + 1.6), 3.4, "Skin"),  # a long neck...
    rod((0, Y0 - 0.9, CZ - RS + 1.0), (0, HY - 2.2, HZ + 1.0), 2.4, "Throat"),  # ...a pale throat
    block(0, HY, HZ, 5.6, 4.8, 6.0, "Skin"),  # a smiling pink head...
    block(0, HY - 1.8, HZ - 0.6, 5.2, 1.8, 5.2, "Throat"),  # ...a pale jaw
    plate(0, HY - 0.95, HZ - 3.05, 3.8, 0.35, "Mouth", depth=0.15),  # (the smile)
    block(0, HY + 2.5, HZ + 0.2, 4.4, 0.6, 4.4, "SkinLight"),  # (scales on its head)
]
head += both(
    block(2.0, HY - 0.75, HZ - 2.95, 0.6, 0.45, 0.3, "Mouth", rot=(0, 0, -30)),  # (the smile's corners)
    plate(2.85, HY + 0.8, HZ - 1.2, 1.8, 1.8, "Eye", depth=0.2, rot=(0, 90, 0)),  # a red eye...
    plate(3.0, HY + 0.8, HZ - 1.4, 0.9, 0.9, "Pupil", depth=0.2, rot=(0, 90, 0)),
    plate(3.1, HY + 1.1, HZ - 1.7, 0.35, 0.35, "Glint", depth=0.1, rot=(0, 90, 0)),
    plate(2.85, HY + 1.95, HZ - 1.1, 2.2, 0.45, "SkinDark", depth=0.2, rot=(0, 90, 0)),  # ...a heavy lid
    plate(0.8, HY + 0.6, HZ - 3.05, 0.45, 0.45, "SkinDark", depth=0.1),  # nostrils
    plate(2.85, HY - 0.5, HZ + 1.2, 1.6, 1.1, "SkinLight", depth=0.2, rot=(0, 90, 0)),  # cheek scales
)
for y in (Y0 + 0.8, Y0 + 2.2):  # neck wrinkles
    head.append(block(0, y + 0.2, CZ - RS - 0.4 - (y - Y0) * 0.9, 3.6, 0.4, 0.8, "SkinDark"))


def leg(x, z):
    out = [
        block(x, 3.6, z, 3.8, 7.2, 3.8, "Skin"),  # a thick pink scaly leg...
        block(x, 0.9, z - 0.4, 4.2, 1.8, 4.6, "Skin"),  # ...a round foot...
    ]
    for y in (2.6, 5.0):
        out += [
            plate(x - 0.9, y, z - 1.95, 1.4, 1.2, "SkinLight", depth=0.2),
            plate(x + 0.9, y + 1.0, z - 1.95, 1.4, 1.2, "SkinLight", depth=0.2),
        ]
    for dx in (-1.3, 0.0, 1.3):  # ...lime claws
        out.append(block(x + dx, 0.5, z - 2.9, 0.9, 0.9, 0.9, "Claw"))
    return out


arms = leg(-5.4, CZ - 4.6) + leg(5.4, CZ - 4.6)
legs = leg(-5.4, CZ + 4.8) + leg(5.4, CZ + 4.8)

ART = {
    "Comment": "Torrtuginni Dragonfrutini: a pink scaly tortoise whose shell is a big hot pink dragon fruit covered in pink scales with glowing lime tips, a lime rim, a smiling pink head on a long neck, thick scaly legs with lime claws.",
    "VoxelSize": 0.2,
    "Palette": {
        "Shell": (228, 50, 132),
        "Scale": (240, 92, 162),
        "Tip": (170, 236, 60),
        "Rim": (186, 214, 80),
        "Belly": (226, 210, 130),
        "Skin": (232, 124, 154),
        "SkinLight": (246, 168, 188),
        "SkinDark": (196, 84, 116),
        "Throat": (244, 206, 186),
        "Mouth": (150, 50, 70),
        "Eye": (214, 40, 60),
        "Pupil": (30, 16, 20),
        "Glint": (250, 250, 250),
        "Claw": (180, 226, 70),
    },
    "Materials": {"Tip": "Neon"},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
