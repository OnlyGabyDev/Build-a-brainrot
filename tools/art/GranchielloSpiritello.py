# Granchiello Spiritello (art v2, blocks): a streetwear crab, after the original meme image
# (by @novix.01, 2025-03-31): a big orange-red crab in a grey beanie and black sunglasses,
# a silver chain on its shell, its huge claws held up by its face; it squats in baggy blue
# jeans and chunky sneakers (no logos), little crab legs poking out at its sides.
import math

from voxel_art import block, both, plate, rod, solid

CY, CZ = 13.0, 0.6  # the shell's middle
body = [
    block(0, CY, CZ, 11.0, 6.0, 7.4, "Shell"),  # a big orange-red crab shell...
    block(0, CY + 2.6, CZ, 9.6, 1.4, 6.6, "Shell"),
    block(0, CY - 2.6, CZ - 0.2, 9.8, 1.4, 6.8, "ShellPale"),
    block(0, CY - 0.4, CZ - 3.75, 6.0, 3.2, 0.3, "ShellPale"),  # (its face plate)
    block(0, CY - 1.0, CZ - 3.95, 3.0, 0.5, 0.3, "Mouth"),
]
for k in range(9):  # ...a silver chain on it
    a = math.radians(-60 + k * 15)
    body.append(block(math.sin(a) * 3.2, CY - 2.0 - math.cos(a) * 1.6 + 1.6, CZ - 3.95, 0.7, 0.7, 0.4, "Chain", rot=(0, 0, 45)))
body.append(block(0, CY - 3.4, CZ - 4.1, 1.2, 1.4, 0.4, "Chain"))
for s in (-1, 1):  # little crab legs poking out at its sides
    for k in range(3):
        body += [
            rod((s * 5.2, CY - 1.0, CZ - 1.6 + k * 1.8), (s * 7.6, CY - 3.0, CZ - 1.4 + k * 2.0), 0.8, "Shell"),
            rod((s * 7.6, CY - 3.0, CZ - 1.4 + k * 2.0), (s * 8.4, CY - 6.4, CZ - 1.2 + k * 2.0), 0.7, "ShellDark"),
        ]

HY = CY + 3.0  # the head: the beanie and the shades
head = [
    block(0, CY + 1.6, CZ - 4.0, 7.6, 1.6, 0.6, "Shades"),  # black sunglasses...
    block(0, CY + 2.3, CZ - 4.3, 7.8, 0.4, 0.4, "Shades"),
    solid("Cylinder", 0, HY + 0.9, CZ, 2.0, 9.4, 9.4, "Beanie", rot=(0, 0, 90)),  # a grey beanie...
    solid("Ball", 0, HY + 1.6, CZ, 8.6, 8.6, 8.6, "Beanie"),
    solid("Cylinder", 0, HY + 0.2, CZ, 1.2, 9.6, 9.6, "BeanieDark", rot=(0, 0, 90)),  # ...a turned-up cuff
]
head += both(
    plate(1.9, CY + 1.6, CZ - 4.35, 2.8, 1.2, "Lens", depth=0.15),
    plate(1.2, CY + 1.9, CZ - 4.45, 0.6, 0.3, "Glint", depth=0.1),
)
for k in range(5):  # (ribs on the beanie)
    head.append(block(-2.4 + k * 1.2, HY + 0.2, CZ - 4.85, 0.3, 1.2, 0.5, "Beanie"))

arms = []
for s in (-1, 1):  # huge claws held up by its face
    arms += [
        rod((s * 5.2, CY - 0.4, CZ - 1.0), (s * 6.8, CY - 2.6, CZ - 4.2), 1.8, "Shell"),
        rod((s * 6.8, CY - 2.6, CZ - 4.2), (s * 3.8, CY - 1.6, CZ - 6.0), 1.8, "Shell"),
        block(s * 2.6, CY - 1.6, CZ - 6.4, 3.2, 3.0, 2.6, "Shell"),  # a claw held up by its mouth...
        block(s * 1.2, CY - 0.7, CZ - 6.6, 1.6, 1.2, 2.0, "Shell"),  # ...its pincers...
        block(s * 1.2, CY - 2.7, CZ - 6.6, 1.6, 1.0, 1.8, "Shell"),
        block(s * 0.45, CY - 0.7, CZ - 6.6, 0.3, 1.0, 1.6, "ShellDark"),  # ...dark tips
    ]

legs = []
for s in (-1, 1):  # baggy blue jeans and chunky sneakers
    x = s * 2.8
    legs += [
        block(x, 7.4, CZ, 4.8, 5.0, 5.0, "Jeans"),
        block(x, 3.6, CZ - 0.4, 4.4, 3.2, 4.6, "Jeans"),
        block(x, 6.0, CZ - 2.55, 0.3, 3.2, 0.2, "JeansDark"),
        block(x, 1.2, CZ - 1.0, 4.2, 2.0, 6.0, "Sneaker"),  # a chunky sneaker...
        block(x, 0.3, CZ - 1.0, 4.4, 0.6, 6.4, "Sole"),
        block(x + s * 2.15, 1.3, CZ - 1.4, 0.2, 1.0, 3.2, "SneakerDark"),
    ]
legs.append(block(0, 9.6, CZ, 9.4, 1.0, 5.2, "Belt"))  # (a belt)

ART = {
    "Comment": "Granchiello Spiritello: a big orange-red crab in a grey beanie and black sunglasses with a silver chain, huge claws held up by its face, squatting in baggy blue jeans and chunky sneakers.",
    "VoxelSize": 0.2,
    "Palette": {
        "Shell": (226, 96, 50),
        "ShellDark": (180, 66, 36),
        "ShellPale": (240, 170, 120),
        "Mouth": (110, 40, 30),
        "Chain": (210, 214, 222),
        "Beanie": (150, 160, 172),
        "BeanieDark": (120, 128, 140),
        "Shades": (20, 20, 24),
        "Lens": (40, 46, 60),
        "Glint": (210, 220, 240),
        "Jeans": (60, 90, 150),
        "JeansDark": (40, 64, 112),
        "Belt": (40, 34, 30),
        "Sneaker": (246, 246, 244),
        "Sole": (226, 226, 222),
        "SneakerDark": (40, 50, 80),
    },
    "Materials": {"Chain": "Metal"},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
