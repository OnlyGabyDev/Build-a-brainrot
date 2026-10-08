# Mangolini Parrocini (art v2, blocks): a mango parrot, after the original meme image (by
# @alexey_pigeon): a parrot whose body is half a mango cut into cubes (orange cubes standing
# out of the front, a green and red skin round them, a long mango-skin tail), a red head
# fading to orange, a big grey hooked beak, white eye rings; its "arms" are green wings
# tipped yellow and red; short grey feet.
from voxel_art import block, both, plate, rod

CY = 12.0  # the body's middle
F = -4.0  # the cut face

body = [
    block(0, CY, 0, 10, 12, 8, "Skin"),  # the mango half, round from stepped blocks
    block(0, CY, 0, 8.4, 14, 7, "Skin"),
    block(0, CY, 0, 11, 9, 6.6, "Skin"),
    block(0, CY + 1.0, 2.3, 10.8, 9.0, 5.0, "Blush"),  # a red blush over its back
    plate(0, CY, F - 0.1, 9.0, 11.0, "Flesh", depth=0.4),  # the cut face...
]
for row in range(5):  # ...cut into cubes standing out
    for col in range(4):
        x, y = -3.15 + col * 2.1, CY - 4.2 + row * 2.1
        if (row in (0, 4)) and col in (0, 3):
            continue  # (round off the corners)
        body.append(block(x, y, F - 1.0, 1.8, 1.8, 1.6, "Cube" if (row + col) % 2 == 0 else "CubeLight"))
body += [  # a long tail of mango skin
    rod((0, CY - 3.0, 3.4), (0, CY - 6.0, 10.6), 2.6, "Skin"),
    rod((0, CY - 2.2, 3.6), (0, CY - 5.0, 10.0), 1.4, "Blush"),
]

head = [
    block(0, CY + 9.0, -0.4, 7.4, 6.4, 6.6, "Orange"),  # the head, orange at the nape...
    block(0, CY + 9.4, -1.0, 7.0, 6.0, 6.2, "Red"),  # ...red over the face
    block(0, CY + 9.6, -1.0, 6.4, 6.6, 5.6, "Red"),
    block(0, CY + 9.0, -4.8, 3.0, 3.4, 2.4, "Beak"),  # a big grey hooked beak
    block(0, CY + 7.2, -5.6, 2.2, 2.0, 1.6, "Beak"),
    block(0, CY + 6.4, -6.0, 1.4, 1.0, 0.8, "BeakDark"),
    block(0, CY + 7.6, -4.4, 2.4, 1.0, 1.2, "BeakDark"),  # (its lower half)
]
head += both(
    plate(2.4, CY + 10.2, -4.25, 2.2, 2.2, "White", depth=0.2),  # white eye rings
    plate(2.4, CY + 10.2, -4.45, 1.3, 1.3, "Dark", depth=0.2),
    plate(2.2, CY + 10.6, -4.6, 0.45, 0.45, "Glint", depth=0.1),
    block(3.75, CY + 8.0, -1.4, 0.3, 2.4, 3.6, "Yellow"),  # yellow cheeks
)

arms = []
for s in (-1, 1):  # green wings, held out, tipped yellow and red
    arms += [
        block(s * 5.9, CY + 1.0, 0.4, 1.6, 7.4, 5.4, "Green", rot=(0, 0, s * 12)),
        block(s * 7.2, CY - 1.2, 0.8, 1.2, 6.6, 4.4, "GreenLight", rot=(0, 0, s * 24)),
        block(s * 8.6, CY - 3.4, 1.2, 1.0, 4.0, 3.4, "Yellow", rot=(0, 0, s * 32)),
        block(s * 9.4, CY - 5.0, 1.4, 0.9, 2.4, 2.4, "Red", rot=(0, 0, s * 38)),
    ]


def foot(x):
    return [
        block(x, 4.0, 0.2, 2.0, 5.0, 2.0, "Leg"),  # a short grey leg...
        rod((x, 1.0, 0.2), (x - 0.8, 0.5, -2.4), 0.8, "Leg"),  # ...two toes forward, two back
        rod((x, 1.0, 0.2), (x + 0.8, 0.5, -2.4), 0.8, "Leg"),
        rod((x, 1.0, 0.2), (x - 0.6, 0.5, 2.4), 0.8, "Leg"),
        rod((x, 1.0, 0.2), (x + 0.6, 0.5, 2.4), 0.8, "Leg"),
    ]


legs = foot(-2.4) + foot(2.4)

ART = {
    "Comment": "Mangolini Parrocini: a parrot whose body is half a mango cut into orange cubes, a red head with a big grey hooked beak, green wings tipped yellow and red, a mango-skin tail.",
    "VoxelSize": 0.2,
    "Palette": {
        "Skin": (110, 176, 70),
        "Blush": (226, 76, 56),
        "Flesh": (232, 150, 30),
        "Cube": (252, 178, 36),
        "CubeLight": (255, 206, 70),
        "Orange": (250, 150, 40),
        "Red": (226, 54, 48),
        "Yellow": (252, 214, 56),
        "Beak": (110, 112, 124),
        "BeakDark": (70, 72, 84),
        "Green": (70, 170, 70),
        "GreenLight": (130, 200, 80),
        "White": (250, 250, 250),
        "Dark": (24, 22, 26),
        "Glint": (245, 245, 245),
        "Leg": (130, 134, 146),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
