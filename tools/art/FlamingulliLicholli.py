# Flamingulli Licholli (art v2, blocks): a lychee flamingo, after the original meme image
# (by @alexey_pigeon, 2025-03-19; also called Flamingulli Gulli Gulli): a flamingo whose
# body is a big red bumpy lychee, a long pink S-shaped neck, a pink head with a bent
# black-tipped beak, white wings edged in black (its "arms"), long pink legs, one bent.
import math

from voxel_art import block, both, plate, rod, solid

C = (0.0, 14.0, 1.6)  # the lychee's middle
R = 5.8

body = [solid("Ball", *C, 2 * R, 2 * R, 2 * R, "Lychee")]  # a big red bumpy lychee...
for k in range(40):  # ...its bumps
    y = 1 - 2 * (k + 0.5) / 40
    r = math.sqrt(max(0.0, 1 - y * y))
    a = math.radians(k * 137.5)
    n = (math.cos(a) * r, y, math.sin(a) * r)
    if n[1] < -0.75:
        continue
    body.append(solid("Ball", C[0] + n[0] * (R - 0.2), C[1] + n[1] * (R - 0.2), C[2] + n[2] * (R - 0.2), 1.6, 1.6, 1.6, "LycheeDark" if k % 3 == 0 else "Bump"))
body.append(rod((0, C[1] + 1.0, C[2] + R - 0.6), (0, C[1] + 2.4, C[2] + R + 1.8), 1.6, "Pink"))  # (a little tail)

N = [(0, C[1] + 3.6, C[2] - 3.8), (0, C[1] + 6.4, C[2] - 5.4), (0, C[1] + 9.0, C[2] - 4.4), (0, C[1] + 11.4, C[2] - 5.6), (0, C[1] + 12.6, C[2] - 7.6)]
head = []
for k in range(len(N) - 1):  # a long pink S-shaped neck...
    head.append(rod(N[k], N[k + 1], 1.8, "Pink"))
    head.append(solid("Ball", *N[k + 1], 1.9, 1.9, 1.9, "Pink"))
HP = N[-1]
head += [
    solid("Ball", HP[0], HP[1] + 0.4, HP[2], 3.4, 3.4, 3.4, "Pink"),  # ...a pink head...
    rod((0, HP[1] + 0.2, HP[2] - 1.4), (0, HP[1] - 0.6, HP[2] - 3.4), 1.3, "Beak"),  # ...a bent beak...
    rod((0, HP[1] - 0.6, HP[2] - 3.4), (0, HP[1] - 2.0, HP[2] - 3.8), 1.0, "BeakTip"),  # ...black-tipped
]
head += both(
    plate(1.5, HP[1] + 0.8, HP[2] - 0.5, 0.8, 0.8, "Eye", depth=0.2, rot=(0, 90, 0)),
)

arms = []
for s in (-1, 1):  # white wings edged in black
    arms += [
        block(s * 6.6, C[1] + 1.2, C[2] + 0.4, 0.8, 4.4, 6.4, "White", rot=(-20, 0, s * 6)),
        block(s * 6.75, C[1] + 0.2, C[2] + 2.6, 0.8, 2.6, 4.4, "White", rot=(-35, 0, s * 6)),
        block(s * 6.9, C[1] - 1.2, C[2] + 4.0, 0.6, 1.4, 3.4, "Black", rot=(-35, 0, s * 6)),
        block(s * 5.8, C[1] + 2.6, C[2] - 0.6, 1.8, 1.6, 3.0, "Pink"),
    ]

legs = [  # long pink legs, one bent
    rod((-1.6, C[1] - R + 0.8, C[2]), (-1.6, 5.0, C[2] - 0.4), 0.9, "Pink"),
    solid("Ball", -1.6, 5.0, C[2] - 0.4, 1.4, 1.4, 1.4, "PinkDark"),
    rod((-1.6, 5.0, C[2] - 0.4), (-1.6, 0.6, C[2]), 0.8, "Pink"),
    block(-1.6, 0.3, C[2] - 0.8, 1.6, 0.6, 2.4, "PinkDark"),
    rod((1.6, C[1] - R + 0.8, C[2]), (1.8, 5.8, C[2] - 2.0), 0.9, "Pink"),
    solid("Ball", 1.8, 5.8, C[2] - 2.0, 1.4, 1.4, 1.4, "PinkDark"),
    rod((1.8, 5.8, C[2] - 2.0), (1.8, 6.4, C[2] + 2.2), 0.8, "Pink"),
    block(1.8, 6.4, C[2] + 2.8, 1.4, 0.6, 1.8, "PinkDark"),
]

ART = {
    "Comment": "Flamingulli Licholli: a flamingo whose body is a big red bumpy lychee, a long pink S-shaped neck, a bent black-tipped beak, white wings edged in black, long pink legs, one bent.",
    "VoxelSize": 0.2,
    "Palette": {
        "Lychee": (206, 50, 70),
        "Bump": (226, 70, 90),
        "LycheeDark": (170, 36, 56),
        "Pink": (246, 130, 160),
        "PinkDark": (226, 100, 136),
        "Beak": (250, 220, 220),
        "BeakTip": (30, 26, 28),
        "Eye": (250, 220, 80),
        "White": (250, 246, 244),
        "Black": (30, 28, 30),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
