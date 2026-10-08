# Tigrilini Watermelini (art v2, blocks): a watermelon tiger, after the original meme image
# (by @alexey_pigeon, 2025-03-17): a big round striped watermelon cut open on its top-front
# (a white rind round red flesh with black seeds), and out of the cut a big tiger head in
# watermelon green with dark green stripes, a pale grey ruff, a pink nose, white whiskers
# and glowing green eyes. The meme shows no limbs: ours are green striped paws over the
# rim, stubby hind paws under the melon and a striped tail.
import math

from voxel_art import block, both, plate, rod, solid

C = (0.0, 9.5, 0.6)  # the melon's middle
R = 8.0
RX = 50  # the cut faces up and forward
N = (0.0, math.sin(math.radians(RX)), -math.cos(math.radians(RX)))  # (the cut's normal)
V = (0.0, math.cos(math.radians(RX)), math.sin(math.radians(RX)))  # (up along the cut)


def at(n, v=0.0, u=0.0):
    return (C[0] + u, C[1] + N[1] * n + V[1] * v, C[2] + N[2] * n + V[2] * v)


def cut_disc(n, length, d, color):
    return solid("Cylinder", *at(n), length, d, d, color, rot=(RX, 90, 0))


body = [solid("Ball", *C, 2 * R, 2 * R, 2 * R, "Melon")]  # a big round watermelon...
for k in range(6):  # ...dark green stripes round it
    body.append(solid("Cylinder", *C, 1.4, 2 * R + 0.3, 2 * R + 0.3, "Stripe", rot=(0, k * 30, 0)))
body += [
    cut_disc(6.4, 3.8, 13.0, "Melon"),  # ...cut open on its top-front:
    cut_disc(8.5, 0.4, 13.0, "Rind"),  # a white rind...
    cut_disc(8.8, 0.4, 11.6, "Flesh"),  # ...round red flesh...
]
for k in range(14):  # ...with black seeds
    a = math.radians(k * 360 / 14 + 8)
    body.append(block(*at(9.05, math.sin(a) * 4.9, math.cos(a) * 4.9), 0.5, 0.8, 0.3, "Seed", rot=(RX, 0, -math.degrees(a))))
tail = [(0, 5.0, C[2] + 7.4), (0, 7.0, C[2] + 11.0), (0, 11.4, C[2] + 12.6), (0, 14.6, C[2] + 11.4)]
for k in range(3):  # a striped tail
    body.append(rod(tail[k], tail[k + 1], 1.8 - k * 0.2, "Green" if k % 2 == 0 else "Stripe"))
    body.append(solid("Ball", *tail[k + 1], 2.0 - k * 0.2, 2.0 - k * 0.2, 2.0 - k * 0.2, "Stripe" if k % 2 == 0 else "Green"))

HY, HZ = 20.0, -4.2  # the tiger's head
FZ = HZ - 3.6  # its face
head = [
    block(0, HY, HZ, 9.2, 8.4, 7.2, "Green"),  # a big green tiger head...
    block(0, HY - 3.4, HZ, 10.4, 3.6, 7.0, "Ruff"),  # ...a pale ruff round its jaw...
    block(0, HY - 2.0, FZ - 0.6, 4.6, 2.8, 1.6, "Ruff"),  # ...a pale muzzle...
    block(0, HY - 0.5, FZ - 1.25, 1.8, 1.2, 0.8, "Nose"),  # ...a pink nose
    plate(0, HY - 2.6, FZ - 1.45, 0.3, 1.2, "Dark", depth=0.15),  # (the mouth)
    plate(0, HY - 3.2, FZ - 1.45, 2.4, 0.3, "Dark", depth=0.15),
    plate(0, HY + 3.0, FZ - 0.05, 0.8, 2.0, "Stripe", depth=0.2),  # stripes on its forehead...
]
head += both(
    plate(2.1, HY + 1.0, FZ - 0.05, 2.0, 1.3, "Eye", depth=0.2),  # glowing green eyes...
    plate(2.0, HY + 1.0, FZ - 0.25, 0.4, 1.1, "Dark", depth=0.15),
    plate(2.3, HY + 2.0, FZ - 0.05, 2.4, 0.4, "Stripe", depth=0.25, rot=(0, 0, 18)),  # ...frowning brows
    plate(1.4, HY + 3.4, FZ - 0.05, 0.6, 1.8, "Stripe", depth=0.2, rot=(0, 0, 20)),  # ...forehead stripes
    plate(3.8, HY - 0.4, FZ - 0.05, 1.4, 0.5, "Stripe", depth=0.2, rot=(0, 0, -20)),  # ...cheek stripes
    plate(3.8, HY + 0.8, FZ - 0.05, 1.4, 0.5, "Stripe", depth=0.2, rot=(0, 0, -20)),
    block(4.65, HY + 1.0, HZ + 0.4, 0.3, 0.6, 4.0, "Stripe"),  # stripes on its sides
    block(4.65, HY + 2.6, HZ + 0.4, 0.3, 0.6, 3.6, "Stripe"),
    block(3.4, HY + 4.8, HZ + 0.6, 2.6, 2.4, 1.6, "Green"),  # round ears...
    plate(3.4, HY + 4.7, HZ - 0.25, 1.6, 1.4, "EarIn", depth=0.2),
    block(3.4, HY + 6.05, HZ + 0.6, 2.0, 0.3, 1.9, "Stripe"),  # (dark tips)
    rod((1.6, HY - 1.6, FZ - 1.5), (5.4, HY - 1.0, FZ - 1.2), 0.2, "White"),  # white whiskers
    rod((1.6, HY - 2.1, FZ - 1.5), (5.4, HY - 2.5, FZ - 1.1), 0.2, "White"),
)
for x in (-1.6, 0.0, 1.6):  # stripes over its crown
    head.append(block(x, HY + 4.25, HZ + 0.4, 0.7, 0.3, 5.0, "Stripe"))

arms = []
for s in (-1, 1):  # green striped paws over the rim
    p = at(8.6, -6.0, s * 3.2)
    arms += [
        rod(at(5.0, -3.0, s * 3.6), p, 2.6, "Green"),
        block(p[0], p[1] + 0.2, p[2] - 0.6, 3.0, 2.0, 3.0, "Green"),
        block(p[0], p[1] + 0.25, p[2] - 0.6, 3.4, 0.5, 3.4, "Stripe"),
        block(p[0], p[1] - 0.2, p[2] - 2.15, 2.6, 1.0, 0.3, "Ruff"),  # (pale toes)
    ]

legs = []
for s in (-1, 1):  # stubby hind paws under the melon
    legs += [
        block(s * 3.8, 2.8, -1.6, 2.8, 3.0, 3.0, "Green"),
        block(s * 3.8, 1.0, -3.6, 3.2, 2.0, 4.0, "Green"),
        block(s * 3.8, 1.1, -3.6, 3.6, 0.5, 4.4, "Stripe"),
        plate(s * 3.8, 0.9, -5.65, 2.6, 1.0, "Ruff", depth=0.3),
    ]

ART = {
    "Comment": "Tigrilini Watermelini: a big striped watermelon cut open on its top-front (white rind, red flesh, black seeds) with a big green-striped tiger head coming out of it, glowing green eyes, a pale ruff, paws over the rim, stubby hind paws and a striped tail.",
    "VoxelSize": 0.2,
    "Palette": {
        "Melon": (118, 178, 70),
        "Stripe": (34, 92, 40),
        "Rind": (238, 246, 220),
        "Flesh": (232, 58, 66),
        "Seed": (24, 20, 20),
        "Green": (128, 196, 64),
        "Ruff": (216, 216, 208),
        "Nose": (236, 110, 130),
        "Dark": (28, 30, 26),
        "Eye": (170, 255, 80),
        "EarIn": (210, 150, 140),
        "White": (250, 250, 250),
    },
    "Materials": {"Eye": "Neon"},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
