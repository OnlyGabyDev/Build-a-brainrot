# Makakini Bananini (art v2, blocks): a banana macaque, after the original meme image (by
# @alexey_pigeon, 2025-03-15): a fluffy cream macaque (a pink face, red ears, round amber
# eyes) sitting in a big peeled banana: the banana curves under it like a boat (a brown stem
# at its front tip), the peel's flaps hang open round the monkey's waist (yellow outside,
# cream inside); its furry arms rest on the flaps.
import math

from voxel_art import block, both, plate, rod, solid, turned

legs = []
P = [(0, 3.0, 8.0), (0, 2.8, 4.0), (0, 3.0, 0.0), (0, 3.8, -3.6), (0, 5.4, -6.6), (0, 7.8, -8.4)]
for k in range(len(P) - 1):  # a big banana curving under it like a boat...
    legs.append(rod(P[k], P[k + 1], 5.6 - k * 0.7, "Banana"))
    legs.append(solid("Ball", *P[k + 1], 5.6 - k * 0.7, 5.6 - k * 0.7, 5.6 - k * 0.7, "Banana"))
legs.append(solid("Ball", *P[0], 5.4, 5.4, 5.4, "Banana"))
legs += [
    rod((0, 7.8, -8.4), (0, 9.6, -9.4), 1.2, "Stem"),  # ...a brown stem at its tip
    block(0, 10.0, -9.6, 1.4, 1.0, 1.4, "Stem"),
    block(0, 2.6, 10.2, 2.0, 1.6, 1.4, "Stem"),  # (the other end)
]

BY = 8.6  # the monkey's middle
body = [
    block(0, BY, 0.6, 6.8, 7.0, 6.0, "Fur"),  # a fluffy monkey...
    block(0, BY + 1.0, -2.55, 4.6, 4.8, 0.3, "Chest"),
]
for k in range(4):  # ...the peel's flaps hanging open round its waist
    a = math.radians(45 + k * 90)
    out = (math.sin(a), 0.0, -math.cos(a))
    t = (math.cos(a), 0.0, math.sin(a))
    d = (out[0] * 0.6, -0.8, out[2] * 0.6)  # (hanging down and out)
    rim = (out[0] * 3.4, BY - 2.6, 0.6 + out[2] * 3.4)
    c = [rim[i] + d[i] * 2.6 for i in range(3)]
    body += [
        turned(*c, 4.0, 5.6, 0.8, "Banana", t, d),
        turned(*[c[i] - out[i] * 0.5 for i in range(3)], 3.4, 5.0, 0.4, "Peel", t, d),
    ]

HY = BY + 7.0  # the head
head = [
    block(0, HY, 0.4, 7.0, 6.4, 6.2, "Fur"),  # a fluffy cream head...
    block(0, HY + 3.4, 0.6, 5.4, 1.2, 5.0, "Fur"),
    block(0, HY - 0.8, -2.85, 4.4, 4.2, 0.6, "Face"),  # ...a pink face...
    block(0, HY - 1.8, -3.35, 2.8, 1.8, 0.6, "Face"),  # ...a short muzzle
    plate(0, HY - 1.4, -3.75, 1.0, 0.4, "Nose", depth=0.15),
    plate(0, HY - 2.3, -3.75, 1.4, 0.25, "Nose", depth=0.15),
]
head += both(
    plate(1.1, HY + 0.2, -3.25, 1.3, 1.3, "Amber", depth=0.2),  # round amber eyes
    plate(1.1, HY + 0.2, -3.45, 0.6, 0.6, "Pupil", depth=0.15),
    plate(0.9, HY + 0.45, -3.9, 0.25, 0.25, "Glint", depth=0.1),
    solid("Cylinder", 3.7, HY + 0.2, 0.4, 0.8, 2.6, 2.6, "Ear", rot=(0, 70, 0)),  # red ears
    block(3.0, HY - 2.2, -1.4, 1.4, 2.0, 2.6, "Fur"),  # (fluffy cheeks)
)

arms = []
for s in (-1, 1):  # furry arms resting on the flaps
    arms += [
        block(s * 4.2, BY + 2.0, 0.4, 2.2, 2.6, 2.6, "Fur"),
        rod((s * 4.6, BY + 1.0, 0.0), (s * 5.4, BY - 2.0, -2.4), 2.0, "Fur"),
        block(s * 5.4, BY - 2.4, -3.0, 1.8, 1.4, 1.8, "Face"),
    ]

ART = {
    "Comment": "Makakini Bananini: a fluffy cream macaque with a pink face and red ears sitting in a big peeled banana that curves under it like a boat, the peel's flaps open round its waist.",
    "VoxelSize": 0.2,
    "Palette": {
        "Banana": (250, 214, 60),
        "Peel": (250, 240, 196),
        "Stem": (110, 76, 40),
        "Fur": (226, 206, 168),
        "Chest": (240, 226, 196),
        "Face": (232, 156, 150),
        "Nose": (150, 80, 76),
        "Amber": (214, 150, 60),
        "Pupil": (24, 18, 16),
        "Glint": (250, 250, 250),
        "Ear": (220, 96, 90),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
