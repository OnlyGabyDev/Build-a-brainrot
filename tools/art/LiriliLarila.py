# Lirilì Larilà (art v2, blocks): an elephant head on a big green cactus, built like
# Steal a Brainrot's model from clean blocks: the cactus with darker ribs and white
# spines; the elephant's boxy head (big flat ears, a long trunk curling forward, white
# tusks, dark eyes); sandals with red straps; cactus-branch arms, the right one holding
# up an alarm clock (Lirilì plays with time). Reference: Steal a Brainrot's render.
from voxel_art import block, both, plate, rod, solid

body = [
    block(0, 12.5, 1, 9, 17, 8.4, "Cactus"),  # the cactus
    block(0, 21.3, 1, 7.8, 0.6, 7.2, "Cactus"),  # its bevelled top
]
for x in (-3, 0, 3):  # ribs down its front and back
    body.append(plate(x, 12.5, -3.3, 0.8, 16, "CactusDark", depth=0.2))
    body.append(plate(x, 12.5, 5.3, 0.8, 16, "CactusDark", depth=0.2))
body += both(block(4.6, 12.5, 1, 0.2, 16, 0.8, "CactusDark"))
for x, y in ((-1.5, 6), (1.5, 9), (-1.5, 12), (1.5, 15), (-1.5, 18), (1.5, 4.5)):  # spines
    body.append(plate(x, y, -3.4, 0.6, 0.6, "Spine", depth=0.2))
    body.append(plate(-x, y + 1, 5.4, 0.6, 0.6, "Spine", depth=0.2))

head = [
    block(0, 17.4, -6.6, 8, 7, 6, "Elephant"),  # the head
    block(0, 21.1, -6.6, 7, 0.4, 5, "Elephant"),
    rod((0, 15.2, -9.4), (0, 9.4, -10.4), 2.4, "Elephant"),  # the trunk...
    rod((0, 9.4, -10.4), (0, 8.8, -12.6), 1.8, "Elephant"),  # ...curling forward
    block(0, 9.4, -13.4, 1.8, 1.4, 1, "ElephantDark"),
]
head += both(
    block(4.6, 17.4, -5.4, 0.8, 6.2, 5.2, "Ear", rot=(0, -20, 0)),  # big flat ears
    rod((1.9, 14.4, -9.4), (2.7, 11.2, -11.8), 1.0, "Tusk"),  # white tusks
    plate(2.4, 19, -9.65, 1, 1.2, "Dark", depth=0.2),  # dark eyes
)

arms = [
    # the left branch, low, curving up
    block(-6, 9, 1, 3, 2.4, 2.4, "Cactus"),
    block(-7, 12, 1, 2.4, 6, 2.4, "Cactus"),
    # the right branch, higher, holding up an alarm clock
    block(6, 12, 1, 3, 2.4, 2.4, "Cactus"),
    block(7, 15.4, 1, 2.4, 6.8, 2.4, "Cactus"),
    block(7, 21.6, 1, 4.6, 4.6, 2, "Clock"),
    plate(7, 21.6, -0.1, 3.6, 3.6, "Face", depth=0.2),
    plate(7, 22.4, -0.25, 0.4, 1.6, "Hand", depth=0.1),
    plate(7.6, 21.6, -0.25, 1.2, 0.4, "Hand", depth=0.1),
    solid("Ball", 5.3, 24.4, 1, 1.4, 1.4, 1.4, "Clock"),  # its bells
    solid("Ball", 8.7, 24.4, 1, 1.4, 1.4, 1.4, "Clock"),
]

legs = []
for x in (-2.4, 2.4):
    legs += [
        block(x, 0.5, -0.4, 4, 1, 6.6, "Sole"),  # sandals
        block(x, 2.3, 0.3, 3.4, 2.6, 4.4, "Cactus"),  # little cactus feet
        block(x, 1.9, -1.8, 3.8, 0.8, 1, "Strap"),
        block(x, 2.9, 1.2, 3.8, 0.8, 1, "Strap"),
    ]

ART = {
    "Comment": "Lirilì Larilà: an elephant head on a big cactus (blocks) in sandals; its arms are cactus branches, one holding an alarm clock.",
    "VoxelSize": 0.2,
    "Palette": {
        "Cactus": (125, 200, 70),
        "CactusDark": (85, 160, 55),
        "Spine": (250, 250, 238),
        "Elephant": (168, 142, 112),
        "ElephantDark": (130, 108, 85),
        "Ear": (150, 124, 98),
        "Tusk": (250, 248, 240),
        "Dark": (30, 25, 25),
        "Sole": (130, 82, 45),
        "Strap": (215, 70, 60),
        "Clock": (185, 190, 200),
        "Face": (255, 255, 255),
        "Hand": (30, 30, 35),
    },
    "Joints": {"Head": (0, 17.4, -6.6)},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
