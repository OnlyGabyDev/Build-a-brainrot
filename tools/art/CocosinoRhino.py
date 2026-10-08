# Cocosino Rhino (art v2, blocks): a coconut rhino, after the original meme image (by
# @alexey_pigeon, 2025-03-14): a rhino whose body is a big hairy brown coconut, its back end
# cut open (a dark shell rim round white flesh); a wrinkly brown rhino head with a big curved
# horn and a small one, little ears and eyes; four thick legs with pale toenails (the front
# pair are its "arms").
import math

from voxel_art import block, both, plate, rod, solid

CY, CZ = 10.0, 1.6  # the coconut's middle
R = 6.8

body = [solid("Ball", 0, CY, CZ, 2 * R, 2 * R, 2 * R, "Coco")]  # a big hairy coconut...
for k in range(24):  # ...fibres on it
    a = math.radians(k * 137.5)
    y = 0.9 - 1.7 * (k + 0.5) / 24
    r = math.sqrt(max(0.0, 1 - y * y))
    d = (math.cos(a) * r, y, math.sin(a) * r)
    if d[2] > 0.4 and d[1] > -0.2:  # (not over the cut)
        continue
    p = (d[0] * R, CY + d[1] * R, CZ + d[2] * R)
    t = (-d[2], 0.3, d[0])
    body.append(rod((p[0] - t[0] * 0.9, p[1] - t[1] * 0.9, p[2] - t[2] * 0.9), (p[0] + t[0] * 0.9, p[1] + t[1] * 0.9, p[2] + t[2] * 0.9), 0.35, "Fibre"))
N = (0.0, math.sin(math.radians(35)), math.cos(math.radians(35)))  # the cut faces back and up


def cut(n, length, d, color):
    return solid("Cylinder", 0, CY + N[1] * n, CZ + N[2] * n, length, d, d, color, rot=(145, 90, 0))


body += [
    cut(5.0, 3.6, 9.8, "Shell"),  # ...its back end cut open: a dark shell rim...
    cut(6.9, 0.4, 8.6, "Flesh"),  # ...round white flesh...
    cut(7.1, 0.4, 6.0, "Inside"),  # ...a creamy inside
]

HY, HZ = CY + 0.6, CZ - R - 2.6  # the head
head = [
    block(0, HY, HZ + 0.6, 5.6, 5.2, 5.6, "Hide"),  # a wrinkly rhino head...
    block(0, HY - 1.0, HZ - 2.6, 4.4, 3.6, 2.8, "Hide"),  # ...a long snout
    block(0, HY - 2.4, HZ - 2.4, 4.0, 1.0, 3.0, "HideDark"),
    plate(0, HY - 1.9, HZ - 4.05, 2.4, 0.3, "Dark", depth=0.15),
    rod((0, HY + 0.6, HZ - 3.2), (0, HY + 3.8, HZ - 4.4), 2.0, "Horn"),  # a big curved horn...
    rod((0, HY + 3.8, HZ - 4.4), (0, HY + 6.0, HZ - 3.6), 1.3, "Horn"),
    rod((0, HY + 6.0, HZ - 3.6), (0, HY + 7.0, HZ - 2.2), 0.8, "Horn"),
    rod((0, HY + 2.4, HZ - 0.6), (0, HY + 3.8, HZ - 1.2), 1.2, "Horn"),  # ...and a small one
]
for y in (HY + 1.6, HY + 0.6):  # (wrinkles)
    head += both(block(2.85, y, HZ + 0.6, 0.3, 0.3, 3.6, "HideDark"))
head += both(
    plate(1.6, HY + 0.6, HZ - 2.25, 0.8, 0.8, "Dark", depth=0.2),  # little eyes
    plate(1.45, HY + 0.8, HZ - 2.45, 0.3, 0.3, "Glint", depth=0.1),
    plate(0.8, HY - 1.4, HZ - 4.05, 0.5, 0.5, "Dark", depth=0.1),  # nostrils
    block(2.4, HY + 3.0, HZ + 2.4, 1.2, 2.0, 0.8, "Hide", rot=(0, 0, -20)),  # ears
)


def leg(x, z):
    return [
        block(x, 3.0, z, 3.6, 6.0, 3.6, "Hide"),  # a thick leg...
        block(x, 4.6, z, 3.8, 0.4, 3.8, "HideDark"),
        block(x, 0.8, z - 0.2, 4.0, 1.6, 4.0, "Hide"),  # ...a round foot...
    ] + [block(x + dx, 0.5, z - 2.25, 0.9, 0.9, 0.5, "Nail") for dx in (-1.2, 0.0, 1.2)]  # ...pale toenails


arms = leg(-3.4, CZ - 3.2) + leg(3.4, CZ - 3.2)
legs = leg(-3.4, CZ + 3.6) + leg(3.4, CZ + 3.6)

ART = {
    "Comment": "Cocosino Rhino: a rhino whose body is a big hairy coconut cut open at its back end, a wrinkly brown rhino head with a big curved horn, four thick legs with pale toenails.",
    "VoxelSize": 0.2,
    "Palette": {
        "Coco": (132, 84, 48),
        "Fibre": (96, 60, 34),
        "Shell": (82, 50, 30),
        "Flesh": (250, 248, 238),
        "Inside": (236, 226, 204),
        "Hide": (150, 108, 76),
        "HideDark": (118, 82, 56),
        "Horn": (214, 196, 160),
        "Dark": (36, 26, 22),
        "Glint": (240, 240, 240),
        "Nail": (230, 214, 184),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
