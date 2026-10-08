# Elefanto Frigo (art v2, blocks): a fridge elephant, after the original meme image (by
# @alexey_pigeon): a shiny silver fridge with an elephant's face on its freezer door (big
# round eyes, a long trunk hanging down the front, little tusks), big pink flapping ears on
# its sides, a door handle and a seam between the doors; four stubby silver feet with pale
# toenails (the front pair are its "arms"). No lettering (the meme has a name on it).
from voxel_art import block, both, plate, rod, solid, turned

FW, FD = 9.0, 7.4  # the fridge's width and depth
body = [
    block(0, 9.4, 0.6, FW, 10.0, FD, "Silver"),  # a shiny silver fridge...
    block(0, 14.5, 0.6 - FD / 2 - 0.05, FW - 0.2, 0.3, 0.3, "Seam"),  # ...a seam between the doors
    block(3.6, 10.6, 0.6 - FD / 2 - 0.35, 0.6, 4.0, 0.6, "Handle"),  # ...a door handle
]

HY = 18.6  # the freezer door (its head)
head = [
    block(0, HY, 0.6, FW, 7.6, FD, "Silver"),  # the freezer: an elephant's face...
    block(0, HY + 3.9, 0.6, FW - 0.6, 0.4, FD - 0.6, "Seam"),  # (its rounded top)
    block(0, HY + 4.2, 0.6, FW - 1.2, 0.4, FD - 1.2, "Silver"),
    block(0, HY - 0.6, 0.6 - FD / 2 - 0.8, 2.6, 2.6, 1.6, "Silver"),  # ...a trunk...
]
T = [(0, HY - 1.4, -3.6), (0, HY - 5.0, -4.2), (0, HY - 8.6, -4.0), (0, HY - 11.0, -4.6), (0, HY - 12.0, -5.8)]
for k in range(len(T) - 1):
    head.append(rod(T[k], T[k + 1], 2.4 - k * 0.3, "Silver" if k % 2 == 0 else "SilverDark"))
head.append(block(0, HY - 12.2, -6.6, 1.6, 1.0, 1.0, "Seam"))
head += both(
    solid("Cylinder", 2.2, HY + 1.0, 0.6 - FD / 2 - 0.2, 0.6, 2.8, 2.8, "White", rot=(0, 90, 0)),  # big round eyes
    solid("Cylinder", 2.2, HY + 0.8, 0.6 - FD / 2 - 0.5, 0.4, 1.6, 1.6, "Dark", rot=(0, 90, 0)),
    plate(1.85, HY + 1.2, 0.6 - FD / 2 - 0.75, 0.4, 0.4, "White", depth=0.1),
    block(2.2, HY + 2.6, 0.6 - FD / 2 - 0.1, 2.6, 0.5, 0.5, "SilverDark", rot=(0, 0, -10)),  # (lids)
    rod((1.4, HY - 1.6, -3.6), (2.0, HY - 3.2, -5.2), 0.7, "Tusk"),  # little tusks
    turned(5.0, HY - 0.4, 0.2, 5.6, 7.0, 0.6, "Silver", (0.9, 0, -0.44), (0, 1, 0)),  # big pink ears...
    turned(4.95, HY - 0.4, -0.1, 4.6, 5.8, 0.3, "Pink", (0.9, 0, -0.44), (0, 1, 0)),
)


def foot(x, z):
    return [
        block(x, 2.2, z, 2.8, 4.4, 2.8, "Silver"),  # a stubby silver foot...
        block(x, 4.0, z, 3.0, 0.4, 3.0, "SilverDark"),
    ] + [block(x + dx, 0.5, z - 1.5, 0.7, 0.8, 0.3, "Nail") for dx in (-0.8, 0.0, 0.8)]  # ...pale toenails


arms = foot(-3.0, -1.6) + foot(3.0, -1.6)
legs = foot(-3.0, 2.8) + foot(3.0, 2.8)

ART = {
    "Comment": "Elefanto Frigo: a shiny silver fridge with an elephant's face on its freezer door, a long trunk down the front, little tusks, big pink ears on its sides, four stubby silver feet.",
    "VoxelSize": 0.2,
    "Palette": {
        "Silver": (196, 202, 210),
        "SilverDark": (150, 156, 166),
        "Seam": (90, 94, 102),
        "Handle": (220, 224, 230),
        "White": (250, 250, 250),
        "Dark": (24, 24, 30),
        "Tusk": (250, 246, 230),
        "Pink": (236, 150, 160),
        "Nail": (236, 232, 222),
    },
    "Materials": {"Silver": "Metal", "SilverDark": "Metal", "Handle": "Metal"},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
