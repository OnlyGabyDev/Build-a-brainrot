# Il Mastodontico Telepiedone (art v2, blocks): a TV on giant feet, after the original meme
# image (by @malacoabalabu, 2025-03-02): an old wooden television (a fuzzy grey static
# screen, round knobs, a speaker grille, a rabbit-ears antenna) standing on two long bare
# human legs, one huge foot resting on planet Earth. The meme shows no arms: ours are thin
# bare arms. Ours: the static glows (a Mythic).
import math

from voxel_art import block, both, plate, rod, solid

TY, TZ = 20.0, 0.4  # the TV's middle
TW, TH, TD = 11.0, 8.6, 7.0

head = [
    block(0, TY, TZ, TW, TH, TD, "Wood"),  # an old wooden television...
    block(0, TY, TZ - TD / 2 - 0.15, TW - 0.8, TH - 0.8, 0.3, "WoodDark"),
    block(1.2, TY + 0.2, TZ - TD / 2 - 0.35, 7.0, 6.2, 0.4, "Frame"),  # ...a screen...
]
for i in range(7):  # ...of fuzzy grey static
    for j in range(6):
        if (i * 7 + j * 3) % 4 == 0:
            continue
        g = "Static" if (i + j * 2) % 3 else "StaticDark"
        head.append(plate(1.2 - 2.7 + i * 0.9, TY + 0.2 - 2.25 + j * 0.9, TZ - TD / 2 - 0.65, 0.9, 0.9, g, depth=0.2))
head += [
    solid("Cylinder", -3.9, TY + 2.0, TZ - TD / 2 - 0.4, 0.8, 1.6, 1.6, "Knob", rot=(0, 90, 0)),  # round knobs...
    solid("Cylinder", -3.9, TY + 0.0, TZ - TD / 2 - 0.4, 0.8, 1.6, 1.6, "Knob", rot=(0, 90, 0)),
]
for k in range(4):  # ...a speaker grille
    head.append(plate(-3.9, TY - 1.6 - k * 0.6, TZ - TD / 2 - 0.4, 1.8, 0.3, "WoodDark", depth=0.2))
head += [
    block(0, TY + TH / 2 + 0.4, TZ + 0.6, 2.4, 0.8, 1.6, "Frame"),  # a rabbit-ears antenna
    rod((-0.4, TY + TH / 2 + 0.6, TZ + 0.6), (-2.6, TY + TH / 2 + 6.0, TZ + 0.2), 0.4, "Antenna"),
    rod((0.4, TY + TH / 2 + 0.6, TZ + 0.6), (2.8, TY + TH / 2 + 5.6, TZ + 0.2), 0.4, "Antenna"),
    solid("Ball", -2.6, TY + TH / 2 + 6.0, TZ + 0.2, 0.8, 0.8, 0.8, "Antenna"),
    solid("Ball", 2.8, TY + TH / 2 + 5.6, TZ + 0.2, 0.8, 0.8, 0.8, "Antenna"),
]
for s in (-1, 1):  # little feet under the cabinet
    head.append(block(s * (TW / 2 - 1.0), TY - TH / 2 - 0.3, TZ, 1.2, 0.6, TD - 1.0, "WoodDark"))

body = [block(0, TY - TH / 2 - 1.0, TZ + 0.4, 5.6, 1.6, 3.6, "Skin")]  # (the legs' tops)

arms = []
for s in (-1, 1):  # (ours) thin bare arms
    arms += [
        rod((s * (TW / 2 - 0.2), TY - 0.6, TZ + 0.4), (s * (TW / 2 + 1.6), TY - 4.4, TZ - 0.6), 1.0, "Skin"),
        rod((s * (TW / 2 + 1.6), TY - 4.4, TZ - 0.6), (s * (TW / 2 + 1.8), TY - 8.0, TZ - 1.4), 0.9, "Skin"),
        block(s * (TW / 2 + 1.8), TY - 8.6, TZ - 1.5, 1.2, 1.2, 1.0, "Skin"),
    ]

GX, GY, GZ = -2.6, 3.0, -5.6  # planet Earth
R = 3.0
legs = [solid("Ball", GX, GY, GZ, 2 * R, 2 * R, 2 * R, "Ocean")]  # planet Earth...
for k, (a, b, w) in enumerate(((20, 10, 2.2), (120, -20, 1.8), (230, 30, 2.4), (300, -35, 1.4), (70, 50, 1.4))):
    ax, by = math.radians(a), math.radians(b)
    n = (math.cos(by) * math.sin(ax), math.sin(by), -math.cos(by) * math.cos(ax))
    legs.append(solid("Ball", GX + n[0] * (R - 0.6), GY + n[1] * (R - 0.6), GZ + n[2] * (R - 0.6), w, w, w, "Land"))  # ...green land
legs += [
    rod((-2.0, TY - TH / 2 - 1.0, TZ + 0.6), (-2.6, GY + R + 2.0, GZ + 3.6), 2.2, "Skin"),  # a leg reaching forward...
    block(-2.6, GY + R + 1.1, GZ + 1.4, 3.4, 2.0, 6.6, "Skin"),  # ...its huge foot on the Earth
    rod((2.0, TY - TH / 2 - 1.0, TZ + 0.6), (2.4, 1.6, TZ + 0.8), 2.2, "Skin"),  # the other leg...
    block(2.4, 0.8, TZ - 1.0, 3.0, 1.6, 5.4, "Skin"),  # ...a big bare foot
]
for k, x in enumerate((-3.8, -3.2, -2.6, -2.0, -1.4)):  # toes
    legs.append(block(x, GY + R + 0.9 + (0.25 if k == 0 else 0), GZ - 2.2, 0.6 if k else 0.9, 0.9 if k else 1.2, 1.2, "Skin"))
for k, x in enumerate((1.2, 1.8, 2.4, 3.0, 3.6)):
    legs.append(block(x, 0.5, TZ - 4.1, 0.6, 0.9, 1.0, "Skin"))

ART = {
    "Comment": "Il Mastodontico Telepiedone: an old wooden TV with a glowing static screen, knobs and a rabbit-ears antenna on two long bare legs, one huge foot resting on planet Earth.",
    "VoxelSize": 0.2,
    "Palette": {
        "Wood": (150, 84, 44),
        "WoodDark": (104, 56, 30),
        "Frame": (60, 56, 54),
        "Static": (210, 216, 222),
        "StaticDark": (120, 126, 136),
        "Knob": (230, 210, 170),
        "Antenna": (190, 194, 200),
        "Skin": (222, 166, 128),
        "Ocean": (52, 120, 210),
        "Land": (90, 176, 80),
    },
    "Materials": {"Static": "Neon", "Antenna": "Metal"},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
