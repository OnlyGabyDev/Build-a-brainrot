# Trulimero Trulicina (art v2, blocks): a fish with a cat's face on four human legs, after
# the original meme image (by @_goon_master_): a long silvery-gold scaly fish body with a
# red dorsal fin and a red fanned tail; a tabby cat's face on its front (pointed ears,
# yellow-green eyes with slit pupils, a pink nose, a white muzzle, whiskers); its "arms"
# are red side fins; four bare human legs walking.
from voxel_art import block, both, plate, rod, wedge

TOP, BOTTOM = 17.0, 9.0

body = [
    block(0, 13, 5, 6.6, 8, 13, "Scale"),  # the fish...
    block(0, 13.2, 13.0, 5.0, 6, 3, "Scale"),  # ...narrowing to the tail
    block(0, 13.4, 15.2, 3.2, 3.6, 1.6, "ScaleDark"),
    block(0, 9.9, 4.8, 6.8, 2, 12.4, "Belly"),  # a pale belly
]
for row, y in enumerate((15.6, 13.8, 12.0)):  # rows of scales down its sides
    for k in range(5):
        z = 0.6 + k * 2.4 + (row % 2) * 1.2
        body += both(plate(3.35, y, z, 1.6, 1.0, "ScaleRow", depth=0.2, rot=(0, 90, 0)))
body += [  # the red fanned tail...
    block(0, 15.4, 17.6, 0.8, 2.6, 5.0, "Fin", rot=(-35, 0, 0)),
    block(0, 11.4, 17.6, 0.8, 2.6, 5.0, "Fin", rot=(35, 0, 0)),
    block(0, 13.4, 16.4, 0.8, 3.0, 1.2, "Fin"),
    # ...and the red dorsal fin
    wedge(0, 18.4, 6.6, 0.8, 2.8, 8, "Fin", rot=(0, 180, 0)),
    block(0, 17.3, 6.6, 0.8, 0.6, 8, "Fin"),
]

arms = both(  # red side fins
    wedge(3.6, 11.8, 2.4, 0.8, 3.0, 4.4, "Fin", rot=(-20, 0, 20)),
)

head = [
    block(0, 13.8, -3.6, 7.6, 8.0, 4.4, "Fur"),  # the cat's face
    plate(0, 11.4, -5.9, 4.4, 2.6, "White", depth=0.4),  # a white muzzle...
    block(0, 12.8, -6.1, 1.4, 1.0, 0.6, "Nose"),  # ...a pink nose
    plate(0, 11.0, -6.15, 1.6, 0.35, "Dark", depth=0.2),
]
head += both(
    wedge(2.6, 19.2, -3.4, 2.0, 2.8, 2.8, "Fur", rot=(0, -90, 0)),  # pointed ears...
    plate(2.6, 18.6, -4.5, 1.0, 1.0, "Pink", depth=0.2),
    plate(2.0, 14.6, -5.85, 2.6, 2.4, "Eye", depth=0.4),  # yellow-green eyes...
    plate(2.0, 14.6, -6.1, 0.6, 2.0, "Dark", depth=0.2),  # ...slit pupils
    plate(1.6, 15.3, -6.15, 0.4, 0.4, "White", depth=0.1),
    plate(1.4, 17.2, -5.85, 0.6, 1.6, "Stripe", depth=0.3),  # tabby stripes
    plate(3.3, 16.4, -5.85, 0.6, 1.4, "Stripe", depth=0.3, rot=(0, 0, 25)),
    block(4.6, 12.0, -5.4, 3.0, 0.25, 0.25, "White", rot=(0, 0, 10)),  # whiskers
    block(4.6, 11.2, -5.4, 3.0, 0.25, 0.25, "White", rot=(0, 0, -10)),
)
head.append(plate(0, 17.4, -5.85, 0.6, 1.8, "Stripe", depth=0.3))

legs = []
for z in (0.6, 9.4):  # four bare human legs, mid-stride
    for x in (-1.9, 1.9):
        swing = 1.2 if (x > 0) == (z < 5) else -1.2
        knee = (x * 1.05, 5.0, z + swing * 0.4)
        foot = (x * 1.1, 1.0, z - swing * 0.6)
        legs += [
            rod((x, BOTTOM + 0.4, z), knee, 1.8, "Skin"),
            rod(knee, foot, 1.6, "Skin"),
            block(foot[0], 0.5, foot[2] - 1.0, 2.0, 1.0, 3.4, "Skin"),  # bare feet
            plate(foot[0], 0.5, foot[2] - 2.75, 1.6, 0.5, "Toe", depth=0.15),
        ]

ART = {
    "Comment": "Trulimero Trulicina: a silvery-gold fish with a tabby cat's face, red fins and tail, walking on four bare human legs.",
    "VoxelSize": 0.2,
    "Palette": {
        "Scale": (200, 186, 140),
        "ScaleDark": (160, 140, 100),
        "ScaleRow": (182, 166, 120),
        "Belly": (232, 226, 205),
        "Fin": (225, 80, 60),
        "Fur": (205, 160, 110),
        "Stripe": (120, 86, 56),
        "White": (250, 248, 240),
        "Nose": (230, 130, 140),
        "Pink": (240, 170, 175),
        "Eye": (200, 220, 70),
        "Dark": (25, 22, 26),
        "Skin": (232, 180, 150),
        "Toe": (210, 150, 125),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
