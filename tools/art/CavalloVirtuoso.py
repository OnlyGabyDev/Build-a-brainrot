# Cavallo Virtuoso (art v2, blocks): a piano horse, after the original meme image (by
# @ofuscabreno, "Ecco Cavallo Virtuoso, uno show strepitoso"): a red upright piano (a lid,
# a front panel, white keys with black ones, a little music stand, gold pedals) standing on
# two giant black lace-up boots, a brown horse's head and neck rising out of its top (a black
# mane, a white blaze, a darker muzzle); its "arms" are two brown forelegs reaching over the
# piano to play the keys (ours: the meme only shows the head).
from voxel_art import block, both, plate, rod

body = [
    block(0, 15.0, 1.6, 14.0, 15.0, 5.6, "Red"),  # the piano's case...
    block(0, 22.9, 1.4, 14.6, 0.8, 6.2, "Red"),  # ...its lid
    plate(0, 18.6, -1.25, 11.4, 4.6, "RedDark", depth=0.3),  # the front panel
    plate(0, 18.6, -1.45, 10.2, 3.6, "Red", depth=0.3),
    block(0, 13.4, -2.2, 13.6, 1.0, 3.0, "Red"),  # the keyboard's shelf...
    block(0, 14.15, -2.2, 12.4, 0.5, 2.8, "Keys"),  # ...white keys...
    block(0, 15.6, -1.5, 12.6, 1.2, 0.6, "Red"),  # ...under the key cover
    plate(0, 10.6, -1.25, 11.0, 4.6, "RedDark", depth=0.3),  # the lower panel
    block(-1.0, 8.6, -1.6, 0.8, 0.4, 1.4, "Gold"),  # gold pedals
    block(1.0, 8.6, -1.6, 0.8, 0.4, 1.4, "Gold"),
    block(0, 20.4, -2.0, 4.6, 1.6, 0.3, "Stand", rot=(-15, 0, 0)),  # a little music stand
]
body += both(block(6.6, 14.4, -2.2, 0.8, 2.6, 3.4, "Red"))  # the keyboard's cheeks
for k in range(13):  # black keys in twos and threes
    if k % 7 in (2, 6):
        continue
    body.append(block(-5.4 + k * 0.9, 14.55, -1.6, 0.45, 0.3, 1.4, "Black"))

head = [
    rod((0, 19.6, 3.0), (0, 27.0, 1.6), 4.0, "Horse"),  # the neck out of the piano...
    rod((0, 21.0, 4.8), (0, 30.4, 2.6), 1.4, "Mane"),  # ...a black mane down it
    block(0, 28.4, 0.2, 3.6, 4.0, 3.8, "Horse"),  # the head...
    block(0, 26.8, -2.8, 3.0, 2.8, 3.6, "Horse"),  # ...a long snout...
    block(0, 26.6, -4.3, 2.9, 2.6, 1.0, "Muzzle"),  # ...darker at its end
    plate(0, 29.0, -1.85, 1.0, 2.0, "Blaze", depth=0.3),  # a white blaze
    block(0, 28.25, -2.6, 1.0, 0.3, 3.0, "Blaze"),
    block(0, 30.5, 0.4, 1.4, 1.0, 2.0, "Mane"),  # its forelock
]
head += both(
    block(1.85, 29.0, -0.6, 0.3, 1.0, 1.2, "Eye"),  # eyes on its sides
    block(1.95, 29.3, -0.9, 0.1, 0.3, 0.3, "Glint"),
    block(1.0, 31.0, 0.9, 0.8, 1.8, 0.8, "Horse", rot=(0, 0, -10)),  # ears
    plate(0.7, 26.9, -4.85, 0.5, 0.5, "Dark", depth=0.1),  # nostrils
)

arms = []
for s in (-1, 1):  # forelegs over the piano, playing the keys
    arms += [
        rod((s * 2.8, 22.4, 1.0), (s * 3.4, 19.0, -2.4), 1.6, "Horse"),
        rod((s * 3.4, 19.0, -2.4), (s * 3.6, 15.4, -2.6), 1.4, "Horse"),
        block(s * 3.6, 14.95, -2.7, 1.6, 0.9, 1.6, "Hoof"),
    ]


def boot(x):
    out = [
        block(x, 5.0, 1.0, 5.0, 6.0, 5.0, "Leather"),  # the shaft...
        block(x, 2.2, -2.4, 5.4, 3.6, 10.0, "Leather"),  # ...a big foot...
        block(x, 2.0, -7.0, 5.0, 3.2, 2.0, "Leather"),  # ...a round toe
        block(x, 0.35, -2.7, 5.7, 0.7, 11.0, "Sole"),
        block(x, 7.1, 1.0, 5.2, 0.6, 5.4, "Sole"),  # the shaft's rim
        block(x, 4.1, -3.8, 2.4, 0.4, 4.2, "Tongue"),  # the tongue
    ]
    for y in (4.6, 5.6, 6.6):  # laces up the front
        out.append(plate(x, y, -1.6, 2.0, 0.3, "Lace", depth=0.3))
        out += [block(x + d, y, -1.6, 0.4, 0.4, 0.4, "Eyelet") for d in (-1.4, 1.4)]
    return out


legs = boot(-3.7) + boot(3.7)

ART = {
    "Comment": "Cavallo Virtuoso: a red upright piano on two giant black lace-up boots, a brown horse's head and neck rising out of its top, its forelegs playing the keys.",
    "VoxelSize": 0.2,
    "Palette": {
        "Red": (204, 44, 40),
        "RedDark": (160, 28, 30),
        "Keys": (250, 248, 240),
        "Black": (24, 22, 24),
        "Gold": (230, 180, 60),
        "Stand": (180, 34, 34),
        "Horse": (124, 70, 40),
        "Mane": (30, 26, 26),
        "Muzzle": (84, 50, 36),
        "Blaze": (246, 242, 236),
        "Eye": (22, 18, 18),
        "Glint": (245, 245, 245),
        "Dark": (30, 22, 22),
        "Hoof": (50, 40, 36),
        "Leather": (34, 34, 38),
        "Sole": (66, 50, 40),
        "Tongue": (54, 54, 60),
        "Lace": (20, 20, 22),
        "Eyelet": (200, 200, 206),
    },
    "Materials": {"Gold": "Metal", "Eyelet": "Metal"},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
