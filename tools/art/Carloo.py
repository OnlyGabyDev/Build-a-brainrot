# Carloo (art v2, blocks): a fancy fish on a foot, after the original meme image (by
# @pollonavale, 2025-04-14): a big olive bass (a pale belly, dark scales, a spiny back fin)
# in a black top hat and black sunglasses, sipping a pink milkshake (whipped cream, a red
# and white straw) through big pale lips; it stands on one big bare human foot. Its "arms"
# are its side fins, the right one holding up the milkshake.
from voxel_art import block, both, plate, rod, solid, wedge

FY = 15.0  # the fish's middle
HZ = -5.6  # the head's middle


def upright(x, y, z, height, d, color):
    return solid("Cylinder", x, y, z, height, d, d, color, rot=(0, 0, 90))


body = [
    block(0, FY, 1.6, 7.8, 8.6, 8.0, "Fish"),  # an olive bass...
    block(0, FY - 2.6, 1.4, 7.4, 3.6, 8.2, "Belly"),  # ...a pale belly
    block(0, FY + 0.4, 7.0, 5.4, 6.0, 3.6, "Fish"),  # ...narrowing to the tail
    block(0, FY + 0.6, 10.2, 0.8, 7.0, 3.4, "Fin", rot=(0, 0, 0)),  # a tail fin
    wedge(0, FY + 5.4, 2.6, 0.8, 2.6, 6.0, "Fin", rot=(0, 180, 0)),  # a spiny back fin
]
body += [
    block(0, FY + 3.4, 2.0, 7.0, 2.0, 8.6, "Back"),  # a darker back
    block(0, FY + 2.6, 7.0, 4.6, 2.0, 3.8, "Back"),
]
for z, y, w in ((-0.8, FY + 0.6, 1.8), (1.6, FY + 0.2, 1.4), (3.8, FY + 0.8, 1.8), (6.4, FY + 0.4, 1.4)):
    body += both(plate(3.95 if z < 5 else 2.75, y, z, w, 1.2, "Scale", depth=0.2, rot=(0, 90, 0)))  # dark blotches
body += both(plate(3.9, FY + 0.4, -2.2, 0.5, 7.0, "Gill", depth=0.2, rot=(0, 90, 0)))

head = [
    block(0, FY + 0.4, HZ + 0.3, 7.6, 8.0, 5.6, "Fish"),  # the head...
    block(0, FY - 2.4, HZ - 0.05, 7.2, 3.4, 5.7, "Belly"),  # ...pale under the jaw
    block(0, FY - 0.6, HZ - 3.2, 4.4, 2.6, 1.8, "Lip"),  # big pale lips...
    plate(0, FY - 0.6, HZ - 4.15, 3.0, 0.5, "Mouth", depth=0.2),
    block(0, FY + 2.8, HZ - 2.65, 8.2, 2.2, 0.5, "Shades"),  # black sunglasses...
    plate(0, FY + 3.7, HZ - 3.05, 8.4, 0.4, "Shades", depth=0.2),
    upright(0, FY + 4.7, HZ + 0.6, 0.6, 8.4, "Hat"),  # a black top hat: the brim...
    upright(0, FY + 7.6, HZ + 0.6, 5.4, 5.8, "Hat"),  # ...the crown...
    upright(0, FY + 5.6, HZ + 0.6, 1.0, 5.9, "Band"),  # ...a band
]
head += both(
    plate(2.0, FY + 2.7, HZ - 2.95, 3.4, 1.6, "Lens", depth=0.2),  # (glossy lenses)
    plate(1.4, FY + 3.2, HZ - 3.1, 0.6, 0.4, "Glint", depth=0.1),
    block(4.0, FY + 2.8, HZ + 0.6, 0.4, 0.5, 5.6, "Shades"),  # the arms of the shades
)

arms = both(block(4.6, FY - 1.6, -1.0, 0.6, 3.0, 3.6, "Fin", rot=(0, 0, -30)))  # side fins
GX, GY, GZ = 5.2, FY - 1.6, -10.4  # the milkshake, held up by the right fin
arms += [
    block(4.6, FY - 2.4, -5.6, 1.0, 2.0, 8.0, "Fin"),  # (the right fin reaching forward)
    upright(GX, GY, GZ, 6.0, 3.8, "Shake"),  # a glass of pink milkshake...
    upright(GX, GY + 2.75, GZ, 0.5, 4.1, "Glass"),  # ...its rim and foot
    upright(GX, GY - 2.75, GZ, 0.5, 4.1, "Glass"),
    solid("Ball", GX, GY + 3.2, GZ, 3.2, 3.2, 3.2, "Cream"),  # ...whipped cream on top
    solid("Ball", GX, GY + 4.6, GZ, 1.8, 1.8, 1.8, "Cream"),
]
straw = [(GX - 0.4, GY + 3.6, GZ), (GX - 0.6, GY + 6.0, GZ + 0.4), (0.8, FY - 0.6, HZ - 4.0)]
arms += [rod(straw[k], straw[k + 1], 0.4, "Straw" if k == 0 else "StrawRed") for k in range(2)]

legs = [
    block(0, 6.0, 1.6, 4.4, 11.0, 4.2, "Skin"),  # one big bare foot: the ankle...
    block(0, 1.6, -1.6, 5.6, 3.2, 8.4, "Skin"),  # ...the foot...
    block(0, 1.4, 3.0, 4.4, 2.8, 2.0, "Skin"),  # ...the heel
]
for k, x in enumerate((-2.2, -1.1, 0.0, 1.1, 2.2)):  # ...five toes
    big = 1.3 if k == 0 else 0.9
    legs += [
        block(x, 0.6 + big / 2, -6.4, big, big, 1.8, "Skin"),
        plate(x, 0.6 + big * 0.7, -7.35, big * 0.6, big * 0.4, "Nail", depth=0.15),
    ]

ART = {
    "Comment": "Carloo: a big olive bass in a black top hat and sunglasses sipping a pink milkshake through big pale lips, standing on one big bare foot.",
    "VoxelSize": 0.2,
    "Palette": {
        "Fish": (104, 124, 74),
        "Belly": (222, 214, 170),
        "Scale": (70, 84, 50),
        "Back": (80, 98, 58),
        "Gill": (64, 74, 46),
        "Fin": (128, 120, 80),
        "Lip": (228, 200, 168),
        "Mouth": (90, 40, 40),
        "Shades": (20, 20, 22),
        "Lens": (40, 44, 56),
        "Glint": (200, 210, 230),
        "Hat": (24, 24, 28),
        "Band": (60, 60, 70),
        "Glass": (230, 236, 240),
        "Shake": (244, 170, 186),
        "Cream": (252, 246, 236),
        "Straw": (250, 250, 250),
        "StrawRed": (224, 52, 60),
        "Skin": (226, 170, 132),
        "Nail": (244, 214, 200),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
