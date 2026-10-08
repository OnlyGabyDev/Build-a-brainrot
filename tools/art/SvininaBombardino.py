# Svinina Bombardino (art v2, blocks): a pig bomb, after the original meme image (by
# @maksutka.only_yes): a pink pig whose round body is a grey steel bomb, ringed with
# riveted seams, with a cap and a lit fuse on top (a glowing spark); a pig's
# head in front (big ears, a round snout), four pink legs with dark hooves (the front pair
# are its "arms") and a curly tail.
from voxel_art import block, both, plate, rod

CY, CZ = 11.0, 1.0  # the bomb's middle
LAYERS = [(14, 9.6, 13), (12, 12.6, 11.4), (9.4, 14, 9.6), (14.6, 6, 10), (10, 6, 13.6)]  # a ball from stepped blocks


def ring(z, color):
    """A raised seam round the bomb at depth z (one slab per layer that reaches it)."""
    return [block(0, CY, CZ + z, w + 0.5, h + 0.5, 0.7, color) for w, h, l in LAYERS[:3] if abs(z) < l / 2 - 0.3]


body = [block(0, CY, CZ, w, h, l, "Steel") for w, h, l in LAYERS]
for z in (-3.4, 0, 3.4):
    body += ring(z, "SteelDark")
body += [
    rod((0, CY + 6.6, CZ), (0, CY + 8.0, CZ), 4.2, "SteelDark", shape="Cylinder"),  # the cap...
    rod((0, CY + 8.0, CZ), (0, CY + 8.6, CZ), 3.0, "Steel", shape="Cylinder"),
    rod((0, CY + 8.4, CZ), (0.4, CY + 10.0, CZ + 0.8), 0.6, "Fuse"),  # ...a curly fuse...
    rod((0.4, CY + 10.0, CZ + 0.8), (1.4, CY + 11.0, CZ + 0.4), 0.6, "Fuse"),
    rod((1.4, CY + 11.0, CZ + 0.4), (2.2, CY + 11.4, CZ - 0.6), 0.6, "Fuse"),
    block(2.5, CY + 11.6, CZ - 1.0, 1.4, 1.4, 1.4, "Spark", rot=(45, 45, 0)),  # ...and its spark
    block(2.5, CY + 11.6, CZ - 1.0, 2.8, 0.4, 0.4, "Spark", rot=(0, 0, 30)),
    block(2.5, CY + 11.6, CZ - 1.0, 0.4, 2.8, 0.4, "Spark", rot=(30, 0, 0)),
    block(2.5, CY + 11.6, CZ - 1.0, 0.4, 0.4, 2.8, "Spark", rot=(0, 30, 0)),
    rod((0, CY + 1.0, CZ + 6.9), (0.4, CY + 2.2, CZ + 8.0), 0.8, "Pig"),  # a curly tail
    rod((0.4, CY + 2.2, CZ + 8.0), (-0.4, CY + 3.0, CZ + 8.4), 0.8, "Pig"),
]
for z in (-3.4, 3.4):  # rivets along the seams
    body += both(block(7.3, CY + 2.4, CZ + z, 0.5, 0.6, 0.6, "Rivet"), block(7.3, CY - 2.8, CZ + z, 0.5, 0.6, 0.6, "Rivet"))
    body.append(block(0, CY + 7.3, CZ + z, 0.6, 0.5, 0.6, "Rivet"))

head = [
    block(0, CY + 0.6, -8.4, 8.4, 7.4, 5.4, "Pig"),  # the pig's head...
    block(0, CY + 0.6, -8.4, 7.0, 8.6, 4.6, "Pig"),
    block(0, CY - 0.6, -11.6, 4.6, 3.4, 1.6, "Snout"),  # ...a round snout
    block(0, CY - 0.6, -11.6, 3.6, 4.0, 1.6, "Snout"),
    plate(0, CY - 3.2, -11.05, 2.6, 0.35, "Dark", depth=0.2),  # a little smile
]
head += both(
    plate(0.9, CY - 0.6, -12.55, 0.8, 1.4, "Nostril", depth=0.2),
    plate(2.3, CY + 2.4, -11.15, 1.2, 1.2, "Dark", depth=0.2),  # eyes
    plate(2.0, CY + 2.7, -11.3, 0.4, 0.4, "Glint", depth=0.1),
    block(3.4, CY + 5.0, -8.6, 3.0, 3.2, 0.8, "Pig", rot=(25, 0, -25)),  # big ears flopping forward
    block(3.4, CY + 5.0, -9.05, 2.0, 2.2, 0.3, "Snout", rot=(25, 0, -25)),
)


def leg(x, z):
    return [
        block(x, 3.0, z, 3.0, 4.6, 3.0, "Pig"),  # a pink leg...
        block(x, 0.6, z, 3.2, 1.2, 3.2, "Hoof"),  # ...on a dark hoof
        block(x, 0.6, z - 1.65, 0.4, 1.2, 0.2, "Dark"),  # (split in two)
    ]


legs = leg(-3.6, CZ + 3.4) + leg(3.6, CZ + 3.4)
arms = leg(-3.6, CZ - 3.6) + leg(3.6, CZ - 3.6)

ART = {
    "Comment": "Svinina Bombardino: a pig whose round body is a grey steel bomb with riveted seams and a lit fuse on top; a pig's head in front, pink legs on dark hooves.",
    "VoxelSize": 0.2,
    "Palette": {
        "Steel": (150, 158, 170),
        "SteelDark": (96, 102, 114),
        "Rivet": (214, 218, 226),
        "Fuse": (226, 196, 140),
        "Spark": (255, 214, 80),
        "Pig": (240, 160, 160),
        "Snout": (226, 128, 138),
        "Nostril": (150, 70, 80),
        "Hoof": (90, 62, 60),
        "Dark": (30, 24, 26),
        "Glint": (245, 245, 245),
    },
    "Materials": {"Spark": "Neon"},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
