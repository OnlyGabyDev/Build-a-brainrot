# Ketupat Kepat (art v2, blocks): a ketupat creature, after the original meme image (by
# @bullhitam4): its head is a big green ketupat (a woven palm-leaf rice cake standing on a
# corner, a checker of light and dark green weave, two leaf tails on top) with big pink eyes
# and a wide red grin full of white teeth; a body of woven leaf strands (pale yellow-green
# down the middle); long leaf-strand arms hanging from its sides to woven hands; pale green
# legs in brown boots. Ours, for a Godly: the pink of its eyes glows.
import math

from voxel_art import block, both, plate, rod

HY = 21.0  # the ketupat's middle
C, S_ = math.cos(math.radians(45)), math.sin(math.radians(45))
FZ = -3.5  # its front face


def woven(u, v):
    """A point on the ketupat's front, in its own turned grid (u, v)."""
    return (u * C - v * S_, HY + u * S_ + v * C)


head = [block(0, HY, 0, 10.0, 10.0, 7.0, "Leaf", rot=(0, 0, 45))]  # the ketupat on its corner...
for i in range(4):  # ...a checker of light and dark weave
    for j in range(4):
        if (i + j) % 2 == 0:
            x, y = woven(-3.75 + 2.5 * i, -3.75 + 2.5 * j)
            head.append(plate(x, y, FZ - 0.1, 2.3, 2.3, "LeafLight", depth=0.2, rot=(0, 0, 45)))
head += [
    rod((0, HY + 6.6, 0), (1.4, HY + 9.4, 0.6), 0.8, "LeafLight"),  # two leaf tails on top
    rod((0, HY + 6.6, 0), (-1.0, HY + 8.8, -0.4), 0.7, "Leaf"),
    plate(0, HY - 2.6, FZ - 0.4, 7.2, 2.4, "Red", depth=0.3),  # a wide red grin...
    plate(0, HY - 2.5, FZ - 0.6, 6.4, 1.4, "Tooth", depth=0.2),  # ...full of white teeth
]
for k in range(7):
    head.append(plate(-2.7 + k * 0.9, HY - 2.5, FZ - 0.75, 0.15, 1.2, "Red", depth=0.1))
head += both(
    plate(3.9, HY - 1.6, FZ - 0.4, 1.4, 0.8, "Red", depth=0.3, rot=(0, 0, 35)),  # the grin's corners turned up
    plate(2.4, HY + 1.2, FZ - 0.4, 3.0, 3.0, "Dark", depth=0.3),  # big pink eyes...
    plate(2.4, HY + 1.2, FZ - 0.6, 2.4, 2.4, "Pink", depth=0.2),
    plate(2.3, HY + 1.1, FZ - 0.8, 1.2, 1.2, "Dark", depth=0.2),
    plate(2.7, HY + 1.6, FZ - 0.95, 0.5, 0.5, "Tooth", depth=0.1),
)

body = [
    block(0, 11.4, 0, 2.4, 7.0, 3.6, "Pale"),  # woven strands: pale down the middle...
    block(1.9, 11.0, 0, 1.6, 6.6, 3.2, "Leaf"),  # ...green on its sides
    block(-1.9, 11.0, 0, 1.6, 6.6, 3.2, "Leaf"),
    block(0, 13.9, 0, 5.6, 2.4, 3.8, "Leaf"),
]
for y in (9.4, 12.0):  # bands across the weave
    body.append(block(0, y, 0, 5.6, 0.6, 3.8, "LeafLight"))

arms = []
for s in (-1, 1):  # long leaf strands from its sides down to woven hands
    arms += [
        rod((s * 2.6, 14.0, 0), (s * 5.8, 13.0, 0), 1.2, "Leaf"),  # a shoulder strand
        rod((s * 5.4, HY - 3.0, 0), (s * 6.0, 11.8, 0), 1.2, "Leaf"),  # strands hanging...
        rod((s * 6.2, HY - 2.6, 0.6), (s * 6.6, 12.0, 0.6), 0.9, "LeafLight"),
        rod((s * 6.0, 11.8, 0), (s * 8.4, 9.8, -0.6), 1.2, "Leaf"),  # ...bending out
        block(s * 9.0, 9.4, -0.8, 2.4, 2.2, 2.0, "LeafLight"),  # a woven hand...
        rod((s * 9.6, 8.6, -1.2), (s * 10.6, 7.4, -1.8), 0.6, "Leaf"),  # ...its leaf fingers
        rod((s * 9.0, 8.4, -1.4), (s * 9.4, 7.0, -2.2), 0.6, "Leaf"),
        rod((s * 10.0, 9.8, -0.6), (s * 11.2, 9.6, -1.2), 0.6, "Leaf"),
    ]

legs = []
for x in (-1.7, 1.7):  # pale green legs in brown boots
    legs += [
        block(x, 5.6, 0, 1.8, 5.6, 1.8, "Pale"),
        block(x, 1.6, -0.4, 2.6, 2.6, 3.4, "Boot"),
        block(x, 3.1, -0.3, 2.9, 0.6, 2.9, "BootLight"),
        block(x, 0.3, -0.7, 2.8, 0.6, 3.8, "Sole"),
    ]

ART = {
    "Comment": "Ketupat Kepat: a big green woven ketupat head on its corner with glowing pink eyes and a wide red grin full of teeth, a body and long arms of woven leaf strands, pale green legs in brown boots.",
    "VoxelSize": 0.2,
    "Palette": {
        "Leaf": (110, 172, 60),
        "LeafLight": (170, 214, 92),
        "Pale": (214, 228, 130),
        "Red": (222, 50, 50),
        "Tooth": (252, 252, 248),
        "Dark": (40, 30, 34),
        "Pink": (255, 150, 190),
        "Boot": (140, 80, 40),
        "BootLight": (176, 108, 60),
        "Sole": (86, 50, 28),
    },
    "Materials": {"Pink": "Neon"},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
