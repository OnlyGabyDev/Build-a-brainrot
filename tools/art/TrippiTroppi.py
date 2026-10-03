# Trippi Troppi (art v2): a cat's face on a shrimp: a round beige cat head with an orange
# top and ears, big orange eyes in thick black frames, a red nose, a white muzzle and
# whiskers, two long shrimp antennae; a curled orange shrimp body with segments and a
# tail fan; little claws for arms; thin shrimp legs. Reference: Steal a Brainrot's render.
from voxel_art import ball, box, both, carve, chain, paint

segments = [
    ball(0, 12, 1.5, 3.6, 3.2, 2.6, "Shrimp"),
    ball(0, 11.2, 4.5, 3.3, 3, 2.4, "Shrimp"),
    ball(0, 9.8, 7.2, 2.9, 2.7, 2.2, "Shrimp"),
    ball(0, 8, 9.4, 2.5, 2.3, 2, "Shrimp"),
    ball(0, 6.2, 11.2, 2, 1.9, 1.7, "Shrimp"),
]

body = list(segments)
for z in (3, 6, 8, 10):
    body.append(paint(box(-5, 0, z, 5, 16, z + 1, "ShrimpDark")))  # the segments' seams
body += [
    ball(0, 4.8, 13, 3.4, 0.9, 1.6, "Shrimp"),  # the tail fan
    ball(0, 4.4, 14.4, 2.4, 0.8, 1.2, "ShrimpDark"),
]

head = [
    ball(0, 15.5, -3.8, 5.6, 5.2, 4.6, "Fur"),  # the cat's big head
    carve(segments[0]),
    carve(segments[1]),
    paint(box(-7, 18, -10, 7, 22, 2, "Orange")),  # its orange top
]
head += both(
    box(2, 19.5, -5, 4.6, 21.5, -2.6, "Orange"),  # ears
    box(2.6, 21.5, -4.4, 4, 22.6, -3.2, "Orange"),
    paint(box(1, 15, -10, 5, 19, -6, "Dark")),  # big framed eyes
    paint(box(2, 16, -10, 4, 18, -6, "EyeOrange")),
    paint(box(3, 16, -10, 4, 17, -6, "Dark")),  # pupils
    box(4.6, 12.5, -6.6, 6.6, 13, -6.1, "Dark"),  # whiskers
    box(4.6, 13.5, -6.2, 6.6, 14, -5.7, "Dark"),
)
head += [
    ball(0, 12.2, -7.4, 3.2, 1.9, 1.6, "White"),  # the muzzle
    ball(0, 14, -8.4, 1.1, 0.9, 0.6, "Nose"),  # a red nose
    paint(box(-1, 11, -10, 1, 12, -7.5, "Dark")),  # the mouth
]
head += both(*chain((1.5, 21, -2), (3.8, 29, 1.4), 0.8, 0.7, "Orange", steps=30))  # antennae

arms = both(*chain((3.2, 10, -2.2), (4.6, 7.4, -5), 0.75, 0.75, "Shrimp"), ball(4.8, 7, -5.6, 1.1, 1, 1.2, "ShrimpDark"))
arms += [carve(segments[0])]

legs = []
for z in (1.5, 4.5, 7.5):
    legs += both(*chain((2, 9.4, z), (3.8, 0.6, z + 0.6), 0.6, 0.55, "Shrimp"))
legs += [carve(s) for s in segments]

ART = {
    "Comment": "Trippi Troppi: a cat's face on a shrimp, big framed eyes, a red nose, long antennae, little claws and thin shrimp legs.",
    "VoxelSize": 0.2,
    "Palette": {
        "Fur": (242, 205, 155),
        "Orange": (250, 130, 50),
        "Shrimp": (255, 125, 65),
        "ShrimpDark": (220, 90, 45),
        "Dark": (30, 25, 30),
        "EyeOrange": (255, 170, 40),
        "White": (252, 250, 245),
        "Nose": (230, 60, 70),
    },
    "Joints": {"Head": (0, 15.5, -3.8)},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
