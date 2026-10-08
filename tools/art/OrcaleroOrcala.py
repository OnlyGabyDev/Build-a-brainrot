# Orcalero Orcala (art v2, blocks): an orca in sneakers, after the original meme image (by
# @brainrottini.ai): a big black orca standing up and leaning forward, a white belly, a
# tall dorsal fin, its tail curling down behind to the ground; its head is the front end
# (white eye patches, small eyes, a white chin, a grin); its "arms" are black pectoral
# fins; "1, 2, 3 scarpe": three white sneakers with a black stripe, two in front and one
# under the tail's flukes.
import math

from voxel_art import block, both, rod, wedge

TILT = -22  # degrees: the whole orca leans forward
ORIGIN = (0, 15.0, 1.0)  # the body's middle


def at(x, y, z):
    """A point given in the leaning body's own frame, in the world."""
    a = math.radians(TILT)
    return (ORIGIN[0] + x, ORIGIN[1] + y * math.cos(a) - z * math.sin(a), ORIGIN[2] + y * math.sin(a) + z * math.cos(a))


def lean(x, y, z, sx, sy, sz, color, shape=block, rot=(0, 0, 0)):
    """A block (or wedge) placed and turned in the leaning body's frame."""
    return shape(*at(x, y, z), sx, sy, sz, color, rot=(TILT + rot[0], rot[1], rot[2]))


body = [
    lean(0, 0, 0, 11, 15, 10, "Orca"),  # the body, an egg from stepped blocks
    lean(0, 0, 0, 9.6, 16.4, 8.6, "Orca"),
    lean(0, -0.6, 0, 12, 11, 8.6, "Orca"),
    lean(0, -1.6, -5.25, 7.6, 10.0, 0.7, "Belly"),  # a white belly, standing out of its front
    lean(0, -2.0, -5.25, 5.6, 11.6, 0.7, "Belly"),
    lean(0, -7.8, -1.6, 7.0, 1.0, 5.0, "Belly"),  # (and under it)
    lean(0, 5.4, 4.6, 2.0, 2.4, 3.4, "Saddle"),  # a grey saddle patch behind the fin
    lean(0, 10.0, 4.4, 1.8, 9.0, 5.0, "Orca", shape=wedge, rot=(16, 0, 0)),  # a tall dorsal fin, leaning back
    rod(at(0, -5.0, 3.6), (0, 6.4, 9.4), 4.0, "Orca"),  # the tail, curling down behind...
    rod((0, 6.4, 9.4), (0, 4.6, 11.6), 3.0, "Orca"),
    block(0, 4.4, 12.6, 9.0, 1.0, 3.4, "Orca", rot=(8, 0, 0)),  # ...to its flukes
]
body += both(lean(5.95, -4.0, -2.2, 0.6, 4.0, 5.0, "Belly"))  # the white reaching up its flanks

head = [
    lean(0, 10.2, -0.6, 9.6, 5.4, 8.6, "Orca"),  # the head, the orca's front end...
    lean(0, 10.2, -0.6, 8.2, 6.6, 7.4, "Orca"),
    lean(0, 9.0, -4.8, 7.6, 3.8, 1.6, "Orca"),  # ...its rounded snout
    lean(0, 7.8, -5.3, 7.0, 1.6, 1.8, "Belly"),  # a white chin
    lean(0, 8.8, -5.75, 5.6, 0.4, 0.3, "Dark"),  # a long grin
]
head += both(
    lean(4.95, 11.2, 0.4, 0.4, 2.0, 3.6, "Belly"),  # white eye patches behind its eyes
    lean(4.95, 10.0, -2.4, 0.4, 1.1, 1.1, "Dark"),  # small eyes
    lean(5.1, 10.2, -2.6, 0.1, 0.4, 0.4, "Glint"),
)

arms = []
for s in (-1, 1):  # black pectoral fins, sweeping down and out
    arms += [
        block(s * 6.6, 12.6, -2.8, 1.4, 6.6, 3.8, "Orca", rot=(TILT, 0, s * 32)),
        block(s * 8.2, 9.6, -2.0, 1.2, 3.0, 2.8, "Orca", rot=(TILT, 0, s * 44)),
    ]


def sneaker(x, z, stump=True):
    return ([block(x, 6.4, z + 0.4, 3.4, 5.6, 3.4, "Orca")] if stump else []) + [  # a black stump...
        block(x, 2.2, z - 0.6, 4.2, 2.8, 5.8, "Shoe"),  # ...in a white sneaker
        block(x, 0.4, z - 0.6, 4.4, 0.8, 6.2, "Sole"),
        block(x, 1.2, z - 3.4, 4.3, 1.4, 0.8, "Sole"),  # the toe cap
        block(x, 3.75, z - 1.2, 2.4, 0.3, 2.8, "Lace"),  # laces
        block(x + 2.15, 2.0, z - 0.6, 0.2, 0.7, 3.6, "Dark", rot=(12, 0, 0)),  # a black stripe on each side
        block(x - 2.15, 2.0, z - 0.6, 0.2, 0.7, 3.6, "Dark", rot=(12, 0, 0)),
    ]


legs = sneaker(-3.0, -1.6) + sneaker(3.0, -1.6) + sneaker(0, 13.0, stump=False)

ART = {
    "Comment": "Orcalero Orcala: a big black orca standing up and leaning forward, a white belly, a tall dorsal fin, its tail curling down behind, white eye patches, black pectoral fins, three white sneakers.",
    "VoxelSize": 0.2,
    "Palette": {
        "Orca": (32, 34, 42),
        "Belly": (246, 246, 248),
        "Saddle": (120, 124, 134),
        "Dark": (16, 16, 20),
        "Glint": (240, 240, 240),
        "Shoe": (250, 250, 252),
        "Sole": (226, 228, 232),
        "Lace": (236, 236, 240),
    },
    # bodies sit where its body's bottom is (the third sneaker is under the tail)
    "Joints": {"Legs": (0, 8.4, -1.2)},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
