# Talpa Di Fero (art v2, blocks): an iron mole, after the original meme image (by
# BrainrotAISoKol): a plump dark grey furry mole with an iron shell of riveted bands over its
# back (like an armadillo's), a long pink snout with a steel drill sticking out of its nose,
# big round eyes in brass rims, little round ears, four short legs with long pale claws (the
# front pair are its "arms") and a thin pink tail.
from voxel_art import block, both, plate, rod

CY, CZ = 11.5, 2.0  # the body's middle

body = [  # a plump furry body, round from stepped blocks
    block(0, CY, CZ, 13, 9, 15, "Fur"),
    block(0, CY, CZ, 11, 11, 13, "Fur"),
    block(0, CY, CZ, 9, 12.4, 11, "Fur"),
    block(0, CY, CZ, 13.6, 6, 12, "Fur"),
    block(0, CY, CZ, 10, 7, 17, "Fur"),
    block(0, CY + 1.1, CZ + 0.5, 14.0, 4.6, 11.4, "IronDark"),  # the shell, a dome: dark seams under...
    block(0, CY + 2.35, CZ + 0.5, 12.0, 7.1, 11.4, "IronDark"),
    block(0, CY + 6.7, CZ + 0.5, 8.4, 1.6, 11.4, "IronDark"),
    rod((0, CY - 1.0, CZ + 8.2), (0, 4.6, CZ + 13.0), 0.8, "Pink"),  # a thin pink tail
]
for z in (-4.35, -1.45, 1.45, 4.35):  # ...four riveted iron bands
    zc = CZ + 0.5 + z
    body += [
        block(0, CY + 1.1, zc, 14.6, 4.8, 2.5, "Iron"),
        block(0, CY + 2.35, zc, 12.6, 7.3, 2.5, "Iron"),
        block(0, CY + 6.8, zc, 9.0, 1.6, 2.5, "Iron"),
    ]
    body += [block(x, CY + 7.75, zc, 0.6, 0.5, 0.6, "Rivet") for x in (-2.4, 0, 2.4)]
    body += both(
        block(7.45, CY + 1.1, zc, 0.5, 0.6, 0.6, "Rivet"),
        block(6.45, CY + 4.6, zc, 0.5, 0.6, 0.6, "Rivet"),
    )

head = [
    block(0, CY + 0.4, -9.0, 9.0, 8.0, 5.0, "Fur"),  # the head...
    block(0, CY + 0.4, -9.0, 7.6, 9.2, 4.4, "Fur"),
    block(0, CY + 0.4, -9.4, 9.6, 6.4, 3.6, "Fur"),
    block(0, CY - 1.0, -13.0, 4.4, 3.6, 3.2, "Pink"),  # ...a long pink snout...
    block(0, CY - 0.8, -15.0, 3.2, 2.8, 1.2, "PinkDark"),
    block(0, CY - 0.8, -16.0, 2.6, 2.6, 0.8, "Steel"),  # ...and a drill out of its nose
    block(0, CY - 0.8, -17.0, 2.0, 2.0, 1.2, "Steel"),
    block(0, CY - 0.8, -18.1, 1.4, 1.4, 1.0, "Steel"),
    block(0, CY - 0.8, -19.0, 0.7, 0.7, 0.8, "Steel"),
    plate(0, CY - 2.85, -12.6, 2.6, 0.3, "Dark", depth=0.2, rot=(90, 0, 0)),  # a little mouth
]
for k, z in enumerate((-16.4, -17.4, -18.4)):  # the drill's spiral grooves
    head.append(block(0, CY - 0.8, z, 2.4 - k * 0.6, 0.4, 0.3, "SteelDark", rot=(0, 0, 35)))
head += both(
    block(2.4, CY + 2.4, -11.65, 2.8, 2.8, 0.5, "Rim"),  # big round eyes in brass rims
    plate(2.4, CY + 2.4, -11.95, 2.0, 2.0, "Dark", depth=0.2),
    plate(2.0, CY + 2.9, -12.15, 0.7, 0.7, "Glint", depth=0.1),
    block(3.4, CY + 4.9, -8.6, 1.8, 1.6, 1.2, "FurDark"),  # little round ears
    plate(2.0, CY - 0.4, -14.7, 1.6, 0.2, "Whisker", depth=0.1, rot=(0, 0, 12)),  # whiskers
    plate(2.0, CY - 1.3, -14.7, 1.6, 0.2, "Whisker", depth=0.1, rot=(0, 0, -10)),
)


def leg(x, z, claw):
    return [
        block(x, 3.6, z, 3.2, 5.6, 3.4, "Fur"),  # a short furry leg...
        block(x, 0.8, z - 0.6, 3.6, 1.6, 4.0, "Pink"),  # ...a pink foot...
    ] + [block(x + dx, 0.5, z - 2.6 - claw / 2, 0.7, 1.0, claw, "Claw") for dx in (-1.1, 0, 1.1)]  # ...long claws


legs = leg(-4.2, CZ + 5.0, 1.2) + leg(4.2, CZ + 5.0, 1.2)
arms = leg(-4.2, CZ - 3.6, 2.0) + leg(4.2, CZ - 3.6, 2.0)

ART = {
    "Comment": "Talpa Di Fero: a plump grey mole with riveted iron bands over its back, a pink snout with a steel drill on its nose, big eyes in brass rims, short legs with long claws.",
    "VoxelSize": 0.2,
    "Palette": {
        "Fur": (92, 88, 92),
        "FurDark": (70, 66, 72),
        "Iron": (150, 154, 162),
        "IronDark": (84, 88, 98),
        "Rivet": (214, 216, 222),
        "Pink": (226, 150, 160),
        "PinkDark": (196, 110, 124),
        "Steel": (196, 200, 210),
        "SteelDark": (110, 114, 124),
        "Rim": (196, 160, 90),
        "Dark": (24, 22, 26),
        "Glint": (245, 245, 245),
        "Whisker": (224, 224, 224),
        "Claw": (240, 226, 214),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
