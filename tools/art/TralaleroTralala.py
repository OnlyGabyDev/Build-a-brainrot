# Tralalero Tralala (art v2): a blue shark on three legs in light blue sneakers (white
# soles and swooshes, dark laces). A long body with a white belly, gills behind the head,
# a tall dorsal fin leaning back, a crescent tail; its head is the snout in front of the
# body (white jaw, a pink smile, black eyes); its "arms" are the pectoral fins.
# Reference: Steal a Brainrot's render (and the original image: the three sneakers).
from voxel_art import ball, box, both, carve, cylinder, paint

torso = ball(0, 19, 3, 5.5, 5.2, 10.5, "Shark")

body = [
    torso,
    paint(box(-7, 10, -10, 7, 17.5, 15, "Belly")),  # the white underside
    ball(0, 19.5, 14, 2.6, 2.6, 3.2, "Shark"),  # the tail stalk
]
# the dorsal fin: a tall triangle, its front edge leaning back
for k in range(6):
    body.append(box(-1, 23.5 + k, -1 + k * 0.9, 1, 24.5 + k, 6 - k * 0.3, "Shark"))
# the tail: a crescent, its upper lobe longer
for k in range(7):
    body.append(ball(0, 21 + k, 16.5 + k * 0.55, 0.8, 0.8, 1.5 - k * 0.1, "Shark"))
for k in range(5):
    body.append(ball(0, 18 - k, 16.5 + k * 0.55, 0.8, 0.8, 1.3 - k * 0.1, "Shark"))
body += both(*[paint(box(4, 16, z, 7, 22, z + 1, "Dark")) for z in (-5, -3, -1)])  # gills

head = [
    ball(0, 18.6, -8.5, 5, 4.7, 5.6, "Shark"),  # the snout
    carve(torso),  # (only the part in front of the body)
    paint(box(-7, 10, -16, 7, 17.5, -3, "Belly")),  # the white jaw
    paint(box(-7, 16, -16, 7, 17, -6, "Mouth")),  # a pink smile round the snout
]
head += both(
    paint(box(2.5, 20, -13, 6, 22, -10, "Dark")),  # black eyes
    paint(box(2.5, 21, -13, 6, 22, -12, "White")),  # a glint
)

arms = both(
    ball(4.6, 17.5, 0, 1.6, 0.9, 2.6, "Shark"),  # pectoral fins, sweeping out and down
    ball(6.2, 16.6, 0.5, 1.3, 0.7, 2, "Shark"),
)
arms += [carve(torso)]


def leg(x, z):
    """A blue leg in a sneaker; it reaches up into the torso, carved off at its curve."""
    return [
        cylinder(x, z, 1.6, 1.6, 3, 17, "Skin"),
        box(x - 2.3, 1, z - 2.8, x + 2.3, 3.6, z + 2.6, "Shoe"),
        ball(x, 2.2, z - 2.8, 2.3, 1.4, 1.6, "Shoe"),  # the rounded toe
        box(x - 2.4, 0, z - 4.4, x + 2.4, 1.2, z + 2.8, "Sole"),
        paint(box(x - 1, 3, z - 2, x + 1, 4, z - 1, "Dark")),  # laces
        paint(box(x - 1, 3, z, x + 1, 4, z + 1, "Dark")),
        paint(box(x + 1.6, 2, z - 2, x + 3, 3, z + 1, "White")),  # swooshes
        paint(box(x - 3, 2, z - 2, x - 1.6, 3, z + 1, "White")),
    ]


legs = leg(-2.7, -2) + leg(2.7, -2) + leg(0, 8.5) + [carve(torso)]

ART = {
    "Comment": "Tralalero Tralala: a blue shark on three legs in light blue sneakers; its head is the snout, its arms the pectoral fins.",
    "VoxelSize": 0.2,
    "Palette": {
        "Shark": (75, 140, 215),
        "Skin": (90, 155, 225),
        "Belly": (240, 243, 250),
        "Dark": (30, 35, 55),
        "White": (255, 255, 255),
        "Mouth": (230, 140, 220),
        "Shoe": (95, 200, 245),
        "Sole": (250, 250, 250),
    },
    # the legs reach up into the torso; bodies sit where the torso's bottom is
    "Joints": {"Legs": (0, 14, 3)},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
