# Centrucci Nuclucci (art v2, blocks): a smug cooling tower, after the original meme image
# (by @tralalelotralalaaaa): a beige concrete cooling tower (wide at the bottom, pinched in
# the middle, flared at the top) with a smug face (half-closed eyes under raised brows, a big
# nose, a smirk) and a radiation sign on its belly, a cloud of steam rising from its top; it
# stands on two big bare feet in brown sandals. The meme shows no arms: ours are short and
# concrete. Ours: the radiation sign glows (a Mythic).
import math

from voxel_art import block, both, plate, rod, solid


def ring(y, h, d, color):
    return solid("Cylinder", 0, y, 0.6, h, d, d, color, rot=(0, 0, 90))


BODY = [(5.6, 1.6, 14.0), (7.2, 1.6, 13.2), (8.8, 1.6, 12.4), (10.4, 1.6, 11.6), (12.0, 1.6, 10.9)]
HEAD = [(13.6, 1.6, 10.4), (15.2, 1.6, 10.0), (16.8, 1.6, 9.9), (18.4, 1.6, 10.1), (20.0, 1.6, 10.6), (21.6, 1.4, 11.2)]

body = [ring(y, h, d, "Concrete" if k % 2 else "ConcreteDark") for k, (y, h, d) in enumerate(BODY)]
SY, SZ = 9.0, 0.6 - 6.0  # a radiation sign on its belly
body += [
    solid("Cylinder", 0, SY, SZ - 0.1, 0.6, 4.6, 4.6, "Sign", rot=(0, 90, 0)),
    solid("Cylinder", 0, SY, SZ - 0.45, 0.3, 1.0, 1.0, "Dark", rot=(0, 90, 0)),
]
for k in range(3):  # (its three blades)
    a = math.radians(90 + k * 120)
    body.append(block(math.cos(a) * 1.3, SY + math.sin(a) * 1.3, SZ - 0.45, 1.5, 1.3, 0.3, "Dark", rot=(0, 0, math.degrees(a) - 90)))

head = [ring(y, h, d, "Concrete" if k % 2 else "ConcreteDark") for k, (y, h, d) in enumerate(HEAD)]
head.append(ring(22.2, 0.3, 10.4, "Dark"))  # (its open top)
for k, (x, y, z, d) in enumerate(((0, 24.2, 0.6, 5.0), (-2.2, 25.6, 1.0, 4.0), (2.0, 26.0, 0.0, 4.4), (0.2, 27.6, 0.8, 4.6), (-1.4, 29.4, 0.2, 3.4), (1.2, 30.4, 0.6, 3.0))):  # a cloud of steam
    head.append(solid("Ball", x, y, z, d, d, d, "Steam" if k % 2 else "SteamGrey"))
FZ = 0.6 - 5.0  # its face
head += [
    block(0, 16.6, FZ - 0.9, 1.8, 2.8, 1.6, "ConcreteDark"),  # a big nose
    block(0.4, 14.8, FZ - 0.15, 3.6, 0.4, 0.4, "Dark", rot=(0, 0, 8)),  # a smirk
    block(2.3, 15.1, FZ - 0.15, 0.9, 0.4, 0.4, "Dark", rot=(0, 0, 30)),
]
head += both(
    plate(2.0, 18.2, FZ - 0.1, 2.0, 1.2, "White", depth=0.3),  # half-closed eyes...
    plate(2.1, 18.0, FZ - 0.3, 0.9, 0.8, "Dark", depth=0.2),
    block(2.0, 18.7, FZ - 0.2, 2.2, 0.5, 0.6, "ConcreteDark"),  # ...heavy lids...
    block(2.1, 19.8, FZ - 0.2, 2.2, 0.4, 0.6, "Dark", rot=(0, 0, 12)),  # ...raised brows
)

arms = []
for s in (-1, 1):  # (ours) short concrete arms
    arms += [
        rod((s * 5.6, 12.0, 0.6), (s * 7.4, 9.0, 0.0), 1.6, "Concrete"),
        rod((s * 7.4, 9.0, 0.0), (s * 7.6, 6.8, -1.0), 1.4, "Concrete"),
        solid("Ball", s * 7.6, 6.4, -1.1, 1.8, 1.8, 1.8, "Concrete"),
    ]

legs = []
for s in (-1, 1):  # big bare feet in brown sandals
    x = s * 2.8
    legs += [
        block(x, 3.4, 0.8, 2.8, 4.6, 2.8, "Skin"),  # an ankle...
        block(x, 1.2, -1.0, 4.4, 2.0, 7.4, "Skin"),  # ...a big bare foot...
        block(x, 0.25, -1.0, 4.8, 0.5, 7.8, "Sandal"),  # ...on a sandal
        block(x, 1.9, -1.4, 4.6, 0.6, 1.2, "Sandal"),
        block(x, 3.0, 0.8, 3.0, 0.6, 3.0, "Sandal"),
    ]
    for dx in (-1.6, -0.8, 0.0, 0.8, 1.6):  # toes, the big one inside
        big = dx == -1.6 * s
        legs.append(block(x + dx, 1.1, -5.2, 1.1 if big else 0.8, 1.5 if big else 1.2, 1.4, "Skin"))

ART = {
    "Comment": "Centrucci Nuclucci: a beige concrete cooling tower with a smug face, a glowing radiation sign on its belly and steam rising from its top, standing on two big bare feet in sandals.",
    "VoxelSize": 0.2,
    "Palette": {
        "Concrete": (214, 200, 170),
        "ConcreteDark": (190, 176, 146),
        "Sign": (250, 210, 40),
        "Dark": (40, 34, 30),
        "White": (246, 244, 236),
        "Steam": (240, 240, 244),
        "SteamGrey": (206, 208, 214),
        "Skin": (226, 172, 132),
        "Sandal": (120, 76, 44),
    },
    "Materials": {"Sign": "Neon"},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
