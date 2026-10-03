# Trippi Troppi (art v2, blocks): a cat's face on a shrimp, built like Steal a Brainrot's
# model from clean blocks and ramps: a beige cube head with an orange crown of spiky
# tufts, pointed ears, big orange eyes in thick black frames, a red nose, a white muzzle
# and whiskers, two long antennae; a shrimp body of orange shell plates arching back and
# down to a fanned tail; little claws for arms; thin jointed legs.
# Reference: Steal a Brainrot's render.
from voxel_art import block, both, plate, rod, wedge

head = [
    block(0, 16, -2.4, 9.4, 8.6, 8.4, "Fur"),  # the cat's head
    block(0, 19.4, -2.4, 9.6, 2, 8.6, "Orange"),  # its orange crown...
    block(0, 21.2, -1, 4.4, 1.6, 4.4, "Orange"),
    plate(0, 13.2, -6.75, 4.6, 2.6, "White", depth=0.6),  # the white muzzle
    block(0, 14.6, -7.0, 1.6, 1.2, 0.8, "Nose"),  # a red nose
    plate(0, 12.4, -7.15, 2.2, 0.4, "Dark", depth=0.2),  # the mouth
]
for x in (-3, -1, 1, 3):  # ...with spiky tufts
    head.append(wedge(x, 21.0, -6.2, 1.8, 2.2, 1.6, "Orange", rot=(0, 180, 0)))
head += both(
    wedge(3.4, 21.6, -1.6, 2.2, 3.2, 2.6, "Orange", rot=(0, -90, 0)),  # pointed ears
    plate(2.3, 16.6, -6.8, 3.2, 3.4, "Dark", depth=0.6),  # thick black frames...
    plate(2.3, 16.6, -7.15, 2, 2.2, "EyeOrange", depth=0.2),  # ...round big orange eyes
    plate(2.6, 16.4, -7.3, 0.7, 1.3, "Dark", depth=0.1),  # slit pupils
    block(5.6, 13.6, -6.2, 2.6, 0.3, 0.3, "Dark", rot=(0, 0, 10)),  # whiskers
    block(5.6, 12.8, -6.2, 2.6, 0.3, 0.3, "Dark", rot=(0, 0, -10)),
    rod((1.4, 21.6, -1.2), (3.4, 28.4, 1.6), 0.7, "Orange"),  # long antennae, bending back
    rod((3.4, 28.4, 1.6), (5.2, 30.6, 5.4), 0.6, "Orange"),
)

# the shrimp: shell plates arching back from behind the head and down to the tail
SHELL = [  # (y, z, width, height, depth, tilt)
    (14.6, 3.6, 7.6, 6.6, 3.4, 10),
    (13.6, 6.6, 6.8, 6, 3.2, 25),
    (11.8, 9.2, 6, 5.4, 3, 40),
    (9.4, 11.2, 5.2, 4.6, 2.8, 58),
    (6.8, 12.4, 4.4, 3.8, 2.6, 75),
]
body = []
for y, z, w, h, d, tilt in SHELL:
    body.append(block(0, y, z, w, h, d, "Shrimp", rot=(tilt, 0, 0)))
    body.append(block(0, y + h / 2 - 0.3, z, w + 0.2, 0.5, d + 0.2, "ShrimpDark", rot=(tilt, 0, 0)))  # each plate's rim
body += both(
    wedge(1.6, 4.6, 13.6, 2.2, 1, 3.4, "Shrimp", rot=(0, 160, 0)),  # the fanned tail
)
body.append(wedge(0, 4.6, 14, 2, 1, 3.4, "ShrimpDark", rot=(0, 180, 0)))

arms = both(
    block(4.4, 10.4, -3.4, 1, 3.4, 1, "Shrimp", rot=(30, 0, 20)),  # little claws
    block(5.0, 8.6, -5.0, 1.6, 1.4, 2, "ShrimpDark"),
    wedge(5.0, 8.6, -6.6, 1.4, 1.2, 1.4, "ShrimpDark", rot=(0, 180, 0)),
)

legs = []
for z, out in ((1.5, 4.2), (4.6, 4.8), (7.6, 5.4)):
    knee = (out, 7.6, z - 0.4)
    legs += both(
        rod((2.2, 10.6, z), knee, 0.75, "Shrimp"),  # thin jointed legs: out to the knee...
        rod(knee, (out - 0.6, 0.2, z - 1), 0.7, "Shrimp"),  # ...and down to the ground
    )

ART = {
    "Comment": "Trippi Troppi: a cat's face on a shrimp (blocks and ramps), big framed eyes, a red nose, long antennae, little claws, thin legs.",
    "VoxelSize": 0.2,
    "Palette": {
        "Fur": (242, 208, 160),
        "Orange": (250, 130, 50),
        "Shrimp": (255, 125, 65),
        "ShrimpDark": (220, 90, 45),
        "Dark": (30, 25, 30),
        "EyeOrange": (255, 175, 40),
        "White": (252, 250, 245),
        "Nose": (230, 60, 70),
    },
    "Joints": {"Head": (0, 16, -2.4)},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
