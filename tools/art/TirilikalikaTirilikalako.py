# Tirilikalika Tirilikalako (art v2, blocks): an air-conditioner chicken, after the original
# meme image (by @marcks.amp, 2025-03-02): a golden-brown hen (a red comb and wattle, a
# yellow beak, a fan of dark tail feathers) whose body is an air conditioner's outdoor unit
# (a white box, a round fan grille in front, vent slats, a power cable trailing behind); it
# walks on two robot legs of bendy ribbed hoses ending in metal feet; small folded wings.
import math

from voxel_art import block, both, plate, rod, solid

BY = 12.8  # the box's middle
BW, BH, BD = 10.4, 7.2, 7.0


def hose(a, b, out):
    out.append(rod(a, b, 1.4, "Hose"))
    n = max(2, int(math.dist(a, b) / 0.8))
    d = [(b[i] - a[i]) / math.dist(a, b) for i in range(3)]
    for k in range(1, n):
        p = [a[i] + (b[i] - a[i]) * k / n for i in range(3)]
        out.append(rod(tuple(p[i] - d[i] * 0.15 for i in range(3)), tuple(p[i] + d[i] * 0.15 for i in range(3)), 1.8, "Ring"))


FZ = -BD / 2  # the box's front
body = [
    block(0, BY, 0, BW, BH, BD, "Box"),  # an air conditioner's outdoor unit...
    block(0, BY - BH / 2 - 0.2, 0, BW - 0.6, 0.4, BD - 0.6, "Trim"),  # ...on a grey base
    block(0, BY + BH / 2 + 0.2, 0.0, BW - 0.4, 0.4, BD - 0.4, "Trim"),  # (a lid)
    solid("Cylinder", 1.6, BY, FZ - 0.1, 0.4, 6.0, 6.0, "Grille", rot=(0, 90, 0)),  # a round fan grille...
    solid("Cylinder", 1.6, BY, FZ - 0.35, 0.3, 5.0, 5.0, "Fan", rot=(0, 90, 0)),
    solid("Cylinder", 1.6, BY, FZ - 0.6, 0.3, 1.2, 1.2, "Trim", rot=(0, 90, 0)),
]
for k in range(3):  # ...its blades
    body.append(block(1.6, BY, FZ - 0.5, 4.6, 1.0, 0.2, "Blade", rot=(0, 0, k * 60 + 15)))
for k in range(4):  # ...grille bars
    body.append(block(1.6, BY - 2.25 + k * 1.5, FZ - 0.75, 5.6, 0.2, 0.2, "Grille"))
for k in range(5):  # vent slats
    body.append(plate(-3.4, BY - 2.4 + k * 1.2, FZ - 0.1, 2.4, 0.4, "Slat", depth=0.2))
for z in (-1.6, 0.0, 1.6):  # vents on its sides
    body += both(plate(BW / 2 + 0.1, BY + 0.6, z, 1.0, 4.4, "Slat", depth=0.2, rot=(0, 90, 0)))
cable = [(BW / 2 - 1.0, BY - 2.0, BD / 2 + 0.2), (BW / 2 - 0.6, BY - 4.6, BD / 2 + 2.2), (BW / 2 + 0.4, 0.4, BD / 2 + 3.2)]
body += [rod(cable[k], cable[k + 1], 0.5, "Cable") for k in range(2)]  # a power cable trailing
body += [
    block(0, BY + BH / 2 + 2.0, 1.4, 7.6, 3.6, 6.0, "Feather"),  # the hen's feathers on top...
    block(0, BY + BH / 2 + 1.6, -2.0, 5.6, 3.6, 2.4, "Neck"),  # ...a golden breast
]
for k in range(5):  # a fan of dark tail feathers
    a = math.radians(-50 + k * 25)
    body.append(block(math.sin(a) * 1.6, BY + BH / 2 + 5.4, 5.0, 1.4, 6.4, 1.2, "Tail" if k % 2 else "TailGreen", rot=(-25, 0, -math.degrees(a))))

HY, HZ = BY + BH / 2 + 6.2, -2.6  # the head
head = [
    block(0, HY - 2.6, HZ + 0.6, 4.0, 4.0, 3.6, "Neck"),  # a golden neck...
    block(0, HY, HZ, 3.6, 3.6, 3.6, "Neck"),  # ...the head...
    block(0, HY - 0.2, HZ - 2.4, 1.6, 1.0, 1.6, "Beak"),  # ...a yellow beak
    block(0, HY - 1.8, HZ - 2.0, 1.2, 2.0, 0.8, "Comb"),  # a red wattle...
    block(0, HY + 2.2, HZ + 0.2, 1.0, 1.4, 3.6, "Comb"),  # ...and comb
    block(0, HY + 2.9, HZ - 0.8, 1.0, 1.2, 1.0, "Comb"),
    block(0, HY + 3.0, HZ + 1.0, 1.0, 1.4, 1.0, "Comb"),
]
head += both(
    plate(1.85, HY + 0.4, HZ - 0.6, 0.9, 0.9, "Eye", depth=0.2, rot=(0, 90, 0)),  # eyes
    plate(2.1, HY + 0.4, HZ - 0.6, 0.4, 0.4, "Pupil", depth=0.2, rot=(0, 90, 0)),
    plate(1.85, HY - 0.95, HZ - 0.4, 1.0, 1.0, "Comb", depth=0.15, rot=(0, 90, 0)),  # red cheeks
)

arms = both(  # small folded wings
    block(4.2, BY + BH / 2 + 1.8, 1.6, 1.2, 3.0, 5.0, "FeatherDark", rot=(0, 0, -10)),
    block(4.4, BY + BH / 2 + 1.0, 3.0, 1.0, 2.0, 3.4, "Feather", rot=(0, 0, -10)),
)

legs = []
for s in (-1, 1):  # robot legs of bendy ribbed hoses
    hip, knee, ankle = (s * 2.8, BY - BH / 2 + 0.2, 0.4), (s * 3.0, 5.4, -2.4), (s * 3.0, 1.6, 0.4)
    legs += [
        block(hip[0], hip[1] - 0.3, hip[2], 2.4, 0.8, 2.4, "Metal"),
        solid("Ball", *knee, 2.2, 2.2, 2.2, "Metal"),
    ]
    hose(hip, knee, legs)
    hose(knee, ankle, legs)
    legs += [
        block(s * 3.0, 0.5, -0.6, 2.4, 1.0, 3.6, "Metal"),  # metal feet
        block(s * 3.0, 0.4, -2.8, 0.8, 0.8, 1.2, "Metal"),
        block(s * 3.0 - 0.9, 0.4, -2.4, 0.6, 0.8, 1.2, "Metal", rot=(0, 20, 0)),
        block(s * 3.0 + 0.9, 0.4, -2.4, 0.6, 0.8, 1.2, "Metal", rot=(0, -20, 0)),
    ]

ART = {
    "Comment": "Tirilikalika Tirilikalako: a golden-brown hen with a red comb whose body is an air conditioner's white outdoor unit with a round fan grille, on two robot legs of bendy ribbed hoses with metal feet.",
    "VoxelSize": 0.2,
    "Palette": {
        "Box": (236, 238, 236),
        "Trim": (176, 180, 184),
        "Grille": (90, 94, 100),
        "Fan": (44, 48, 54),
        "Blade": (150, 156, 164),
        "Slat": (196, 200, 204),
        "Cable": (40, 40, 44),
        "Feather": (200, 112, 40),
        "FeatherDark": (150, 78, 30),
        "Neck": (232, 160, 60),
        "Tail": (70, 50, 40),
        "TailGreen": (40, 70, 56),
        "Beak": (246, 196, 60),
        "Comb": (222, 36, 40),
        "Eye": (250, 220, 120),
        "Pupil": (20, 16, 16),
        "Hose": (60, 62, 68),
        "Ring": (88, 90, 98),
        "Metal": (170, 176, 186),
    },
    "Materials": {"Metal": "Metal"},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
