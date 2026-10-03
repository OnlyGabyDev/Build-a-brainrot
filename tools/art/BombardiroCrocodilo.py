# Bombardiro Crocodilo (art v2, blocks): a crocodile that's a bomber, built like Steal a
# Brainrot's model from clean blocks and ramps: a dark green fuselage with a glass cockpit
# on top, a tail fin and tailplane; its head is the croc's snout as the plane's nose (a
# beige lower jaw, white teeth, yellow eyes on top); its "arms" are the wings with two
# yellow-tipped propellers each and a bomb under each; its "legs" the landing gear.
# Reference: Steal a Brainrot's render.
from voxel_art import block, both, plate, rod, solid, wedge

body = [
    block(0, 13, 6, 8.4, 7, 22, "Hull"),  # the fuselage
    block(0, 17.4, 2.4, 5.4, 1.8, 7, "Hull"),
    block(0, 18.6, 2.4, 4.6, 1.4, 6, "Glass"),  # the cockpit
    block(0, 18.6, 2.4, 0.4, 1.5, 6.1, "Hull"),
    wedge(0, 20, 15.6, 1.6, 7, 5, "Hull"),  # the tail fin
    block(0, 14.8, 16, 12, 0.8, 3.4, "Hull"),  # the tailplane
    plate(0.85, 19.2, 16.4, 2, 1.4, "Yellow", depth=0.1, rot=(0, 90, 0)),
    plate(-0.85, 19.2, 16.4, 2, 1.4, "Yellow", depth=0.1, rot=(0, 90, 0)),
]

head = [
    block(0, 13.6, -8.6, 7.4, 4.2, 7.4, "Croc"),  # the snout, as the nose
    block(0, 10.6, -8.8, 7, 1.8, 7, "Jaw"),
    block(0, 11.7, -12.4, 6.6, 0.6, 0.3, "Tooth"),
    block(0, 16, -6.4, 6.4, 1.2, 3.2, "Croc"),
    plate(-1.1, 15, -12.35, 0.6, 0.6, "Dark", depth=0.1),
    plate(1.1, 15, -12.35, 0.6, 0.6, "Dark", depth=0.1),
]
head += both(
    block(3.65, 11.7, -9, 0.3, 0.6, 5.6, "Tooth"),
    block(2.2, 17.1, -6.6, 1.8, 1.4, 1.8, "Croc"),  # eyes on top
    plate(2.2, 17.2, -7.55, 1.2, 0.8, "Yellow", depth=0.1),
    plate(2.4, 17.2, -7.62, 0.5, 0.6, "Dark", depth=0.1),
)

arms = []
for side in (-1, 1):
    arms.append(block(side * 10.6, 13.4, 5, 13, 1, 7, "Hull"))  # the wings
    arms.append(solid("Cylinder", side * 9.4, 11.2, 5.2, 5, 1.8, 1.8, "Bomb", rot=(0, 90, 0)))  # a bomb under each
    arms.append(block(side * 9.4, 11.2, 2.4, 1, 1, 0.6, "Yellow"))
    for x in (7.4, 12.6):  # two propellers each
        hub = (side * x, 13.4, 1.2)
        arms += [
            solid("Ball", *hub, 1.4, 1.4, 1.4, "Dark"),
            block(hub[0], hub[1], 0.8, 0.7, 6, 0.3, "Hull"),
            block(hub[0], hub[1], 0.8, 6, 0.7, 0.3, "Hull"),
            block(hub[0], hub[1] + 2.8, 0.75, 0.8, 0.6, 0.35, "Yellow"),
            block(hub[0], hub[1] - 2.8, 0.75, 0.8, 0.6, 0.35, "Yellow"),
            block(hub[0] + 2.8, hub[1], 0.75, 0.6, 0.8, 0.35, "Yellow"),
            block(hub[0] - 2.8, hub[1], 0.75, 0.6, 0.8, 0.35, "Yellow"),
        ]

legs = []
for x, z in ((-2.6, 8), (2.6, 8), (0, -2)):  # the landing gear
    legs += [
        rod((x, 9.4, z), (x, 2, z), 0.8, "Gear"),
        solid("Cylinder", x, 1.6, z, 1.2, 3.2, 3.2, "Tire"),
        solid("Cylinder", x, 1.6, z, 1.3, 1.4, 1.4, "Gear"),
    ]

ART = {
    "Comment": "Bombardiro Crocodilo: a crocodile bomber (blocks): a croc snout as the nose, a glass cockpit, wings with propellers and bombs, landing gear.",
    "VoxelSize": 0.2,
    "Palette": {
        "Hull": (45, 60, 45),
        "Glass": (170, 220, 245),
        "Yellow": (250, 215, 50),
        "Croc": (140, 190, 95),
        "Jaw": (230, 220, 170),
        "Tooth": (255, 255, 250),
        "Dark": (20, 22, 20),
        "Bomb": (70, 75, 70),
        "Gear": (150, 155, 160),
        "Tire": (30, 30, 32),
    },
    "Joints": {"Legs": (0, 9.4, 4), "Head": (0, 13.6, -8.6)},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
