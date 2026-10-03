# Tralalero Tralala (art v2, blocks): a blue shark on three legs in chunky light blue
# sneakers, built like Steal a Brainrot's model from clean blocks and ramps: a long boxy
# body with a white belly, black gills, a dorsal fin and a tail fin leaning back; its head
# is the snout (a white jaw, a pink smile round it, black eyes, a sloping brow); its
# "arms" are the pectoral fins; thick legs, sneakers with white soles, toe caps and
# swooshes, dark laces. Reference: Steal a Brainrot's render.
from voxel_art import block, both, plate, wedge

body = [
    block(0, 17.5, 4, 10, 9, 16, "Shark"),  # the long body
    block(0, 13.9, 4, 10.2, 1.8, 16.2, "Belly"),  # a white belly
    block(0, 17.6, 13.6, 7, 6.6, 3.2, "Shark"),  # the tail stalk
    wedge(0, 25, 4.4, 1.6, 6, 6, "Shark"),  # the dorsal fin, leaning back
    wedge(0, 24.4, 16.4, 1.6, 7, 3.2, "Shark"),  # the tail fin's upper lobe...
    wedge(0, 12.6, 16.2, 1.6, 4, 2.8, "Shark", rot=(180, 0, 0)),  # ...and its lower one
]
body += both(*[block(5.1, 17.8, z, 0.2, 4.4, 0.6, "Dark") for z in (-0.6, 0.8, 2.2)])  # gills

head = [
    block(0, 17.3, -7.4, 9.4, 8.6, 6.8, "Shark"),  # the snout
    wedge(0, 22.3, -7.4, 9.4, 1.4, 6.8, "Shark"),  # its brow sloping to the nose
    block(0, 13.9, -7.4, 9.6, 1.8, 7, "Belly"),  # the white jaw
    plate(0, 15.3, -10.9, 8.4, 0.7, "Mouth", depth=0.2),  # a pink smile round it
]
head += both(
    block(4.8, 15.3, -7.6, 0.2, 0.7, 6.4, "Mouth"),
    block(4.8, 19.4, -9, 0.3, 1.6, 1.6, "Dark"),  # black eyes
    block(4.95, 19.9, -9.4, 0.1, 0.5, 0.5, "White"),
)

arms = both(
    wedge(5.6, 14.6, 0.4, 1, 3.4, 4.2, "Shark", rot=(0, 0, -35)),  # pectoral fins, sweeping down
)


def leg(x, z):
    return [
        block(x, 8, z, 2.8, 10, 2.8, "Skin"),  # a thick leg
        block(x, 2.1, z - 0.6, 3.8, 2.6, 5.4, "Shoe"),  # a chunky sneaker
        block(x, 0.4, z - 0.6, 4, 0.8, 5.8, "Sole"),
        block(x, 1.2, z - 3.2, 3.9, 1.4, 0.8, "Sole"),  # the toe cap
        plate(x, 3.45, z - 1.4, 2, 0.4, "Dark", depth=0.6, rot=(90, 0, 0)),  # laces
        plate(x, 3.45, z, 2, 0.4, "Dark", depth=0.6, rot=(90, 0, 0)),
        block(x + 1.95, 2.2, z - 0.6, 0.2, 0.6, 3, "White", rot=(10, 0, 0)),  # swooshes
        block(x - 1.95, 2.2, z - 0.6, 0.2, 0.6, 3, "White", rot=(10, 0, 0)),
    ]


legs = leg(-2.6, -2) + leg(2.6, -2) + leg(0, 9)

ART = {
    "Comment": "Tralalero Tralala: a blue shark (blocks and ramps) on three legs in light blue sneakers; its head is the snout, its arms the pectoral fins.",
    "VoxelSize": 0.2,
    "Palette": {
        "Shark": (80, 145, 215),
        "Skin": (90, 155, 225),
        "Belly": (242, 244, 250),
        "Dark": (30, 35, 55),
        "White": (255, 255, 255),
        "Mouth": (230, 140, 220),
        "Shoe": (95, 200, 245),
        "Sole": (250, 250, 250),
    },
    # bodies sit where its body's bottom is
    "Joints": {"Legs": (0, 13, 3)},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
