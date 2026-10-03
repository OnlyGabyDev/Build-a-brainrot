# Glorbo Fruttodrillo (art v2): a crocodile in a striped watermelon, like Steal a
# Brainrot's model: the round melon (voxels, for its roundness) striped dark and light
# green; the croc's blocky head poking out of its front (a beige lower jaw, white teeth,
# red eyes on top, nostrils); little croc arms out of its sides; short croc legs with
# white claws. Reference: Steal a Brainrot's render.
from voxel_art import ball, block, both, box, paint, plate, rod

body = [ball(0, 14, 1, 7.6, 7.4, 7.2, "Melon")]
for x in (-6, -3, 0, 3, 6):  # its stripes, top to bottom
    body.append(paint(box(x - 0.6, 0, -10, x + 0.8, 30, 12, "MelonDark")))
for z in (-3, 2, 6):
    body.append(paint(box(-10, 0, z - 0.6, 10, 30, z + 0.8, "MelonDark")))
body.append(paint(box(-2, 20.5, -4, 2, 22, 6, "MelonLight")))  # a highlight on top

head = [
    block(0, 15.2, -8.6, 7, 4, 6.4, "Croc"),  # the snout
    block(0, 12.4, -8.8, 6.6, 1.8, 6, "Jaw"),  # the beige lower jaw
    block(0, 13.4, -11.95, 6.2, 0.6, 0.3, "Tooth"),  # white teeth
    block(0, 17.4, -6.4, 6, 1.2, 3, "Croc"),
    plate(-1, 16.6, -11.85, 0.6, 0.6, "Dark", depth=0.1),  # nostrils
    plate(1, 16.6, -11.85, 0.6, 0.6, "Dark", depth=0.1),
]
head += both(
    block(3.45, 13.4, -9, 0.3, 0.6, 5, "Tooth"),
    block(2.2, 18.5, -6.6, 2, 1.6, 2, "Croc"),  # eyes on top
    plate(2.2, 18.7, -7.65, 1.4, 0.8, "Eye", depth=0.1),
    plate(2.4, 18.7, -7.72, 0.5, 0.6, "Dark", depth=0.1),
)

arms = both(
    rod((6.6, 12, -2), (8.2, 9.6, -3.6), 1.6, "Croc"),  # little croc arms
    block(8.4, 9.2, -3.9, 1.8, 1.2, 1.8, "Croc"),
    plate(8.4, 8.9, -4.85, 1.4, 0.4, "Tooth", depth=0.1),
)

legs = both(
    block(3.4, 3.4, 0, 2.8, 6, 3, "Croc"),  # short croc legs
    block(3.4, 0.6, -1, 3.2, 1.2, 4.4, "Croc"),
    plate(3.4, 0.6, -3.25, 2.4, 0.6, "Tooth", depth=0.1),  # white claws
)

ART = {
    "Comment": "Glorbo Fruttodrillo: a croc (blocks) in a striped watermelon, red eyes, white teeth, little arms, short legs.",
    "VoxelSize": 0.2,
    "Palette": {
        "Melon": (120, 200, 80),
        "MelonDark": (40, 120, 55),
        "MelonLight": (170, 230, 120),
        "Croc": (70, 140, 60),
        "Jaw": (225, 215, 160),
        "Tooth": (255, 255, 250),
        "Eye": (235, 60, 50),
        "Dark": (25, 25, 25),
    },
    "Joints": {"Head": (0, 15, -8.6)},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
