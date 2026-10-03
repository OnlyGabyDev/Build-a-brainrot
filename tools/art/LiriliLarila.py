# Lirilì Larilà (art v2): an elephant head (floppy ears, white tusks, a long trunk curling
# at its tip) on a big green cactus with ribs and white spines, standing in brown sandals
# with red straps; its arms are cactus branches, the right one holding up an alarm clock
# (Lirilì plays with time). Reference: Steal a Brainrot's render.
from voxel_art import ball, box, both, carve, chain, cylinder, paint

trunk = cylinder(0, 1, 4.6, 4.2, 4, 20, "Cactus")
crown = ball(0, 20, 1, 4.6, 2.6, 4.2, "Cactus")

legs = []
for x in (-2.4, 2.4):
    legs += [
        box(x - 2, 0, -3.6, x + 2, 1, 3, "Sole"),  # sandals
        cylinder(x, -0.2, 1.7, 2.2, 1, 4, "Cactus"),  # little cactus feet
        paint(box(x - 3, 1, -3, x + 3, 2, -2, "Strap")),
        paint(box(x - 3, 2, 0, x + 3, 3, 1, "Strap")),
    ]

body = [trunk, crown]
for x in (-4, -2, 0, 2, 3.5):
    body.append(paint(box(x, 4, -6, x + 1, 23, 6, "CactusDark")))  # ribs
for k, (x, y) in enumerate((x, y) for y in (6, 10, 14, 18) for x in (-3, -1, 1, 3)):
    if (k // 4) % 2 == 1:
        x += 1
    body.append(paint(box(x, y, -6, x + 1, y + 1, 6, "Spine")))  # spines

head = [
    ball(0, 17, -5.6, 4.2, 3.8, 3.6, "Elephant"),
    carve(trunk),
    carve(crown),
    paint(box(-3, 18, -10, -2, 20, -7, "Dark")),  # eyes
    paint(box(2, 18, -10, 3, 20, -7, "Dark")),
]
head += both(ball(4.4, 17.5, -4.6, 1, 3.4, 2.8, "Ear"))  # floppy ears
head += chain((0, 15, -8.8), (0, 9.6, -9.8), 1.35, 1.0, "Elephant")  # the trunk...
head += chain((0, 9.6, -9.8), (0, 9.4, -12), 1.0, 0.85, "Elephant")  # ...curling forward
head += both(*chain((1.7, 14.2, -8.2), (2.5, 11.2, -10.6), 0.65, 0.45, "Tusk"))

arms = [
    # the left branch, low, curving up
    *chain((-4.4, 9, 0), (-7, 9, 0), 1.3, 1.3, "Cactus"),
    cylinder(-7, 0, 1.3, 1.3, 9, 13.5, "Cactus"),
    ball(-7, 13.5, 0, 1.3, 1, 1.3, "Cactus"),
    # the right branch, higher, holding up an alarm clock
    *chain((4.4, 12, 0), (7, 12, 0), 1.3, 1.3, "Cactus"),
    cylinder(7, 0, 1.3, 1.3, 12, 17, "Cactus"),
    box(5, 17, -0.8, 9, 21, 0.8, "Clock"),
    paint(box(5.5, 17.5, -2, 8.5, 20.5, -0.5, "Face")),
    paint(box(6.5, 18.5, -2, 7, 20, -0.5, "Hand")),
    paint(box(7, 18.5, -2, 8, 19, -0.5, "Hand")),
    ball(5.4, 21.5, 0, 0.8, 0.8, 0.8, "Clock"),  # the bells
    ball(8.6, 21.5, 0, 0.8, 0.8, 0.8, "Clock"),
    carve(trunk),
]

ART = {
    "Comment": "Lirilì Larilà: an elephant head on a big cactus in sandals; its arms are cactus branches, one holding an alarm clock.",
    "VoxelSize": 0.2,
    "Palette": {
        "Cactus": (120, 200, 70),
        "CactusDark": (85, 160, 55),
        "Spine": (250, 250, 238),
        "Elephant": (168, 142, 112),
        "Ear": (145, 118, 92),
        "Tusk": (250, 248, 240),
        "Dark": (30, 25, 25),
        "Sole": (130, 82, 45),
        "Strap": (215, 70, 60),
        "Clock": (185, 190, 200),
        "Face": (255, 255, 255),
        "Hand": (30, 30, 35),
    },
    "Joints": {"Head": (0, 17, -5.6)},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
