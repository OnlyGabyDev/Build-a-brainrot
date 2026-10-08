# Rhino Toasterino (art v2, blocks): a toaster rhino, after the original meme image (by
# @alexey_pigeon): a rhino whose body is a shiny chrome toaster (two slots on top with a
# slice of toast popping out of the back one, dials, a lever and vents on its sides), the
# rhino's grey head out of its front (a big curved pale horn and a little one, blue eyes, a
# wide open grin with white teeth); its "arms" are grey rhino arms held out; short thick
# grey legs with pale toenails.
from voxel_art import block, both, plate, rod

CY = 12.5  # the toaster's middle

body = [
    block(0, CY, 0, 11, 10, 12, "Chrome"),  # the toaster, its edges rounded off
    block(0, CY, 0, 10, 11, 11, "Chrome"),
    block(0, CY - 5.4, 0, 10.4, 0.8, 11.4, "ChromeDark"),  # a dark base
    block(0, CY + 5.55, -2.2, 6.4, 0.3, 1.6, "Slot"),  # two slots on top...
    block(0, CY + 5.55, 2.2, 6.4, 0.3, 1.6, "Slot"),
    block(0, CY + 8.2, 2.2, 7.6, 6.0, 1.4, "Crust"),  # ...a slice of toast popping out of one
    block(0, CY + 8.3, 2.2, 6.6, 5.4, 1.6, "Bread"),
    block(0, CY + 11.0, 2.2, 6.0, 1.0, 1.4, "Crust"),
    block(0, CY + 10.6, 2.2, 7.0, 1.0, 1.4, "Crust"),
    block(0, CY - 2.4, 6.2, 7.0, 3.0, 0.4, "ChromeDark"),  # vents at the back
]
body += both(
    block(5.65, CY + 2.8, -2.6, 0.3, 1.2, 3.4, "ChromeDark"),  # a lever slot on each side...
    block(6.1, CY + 2.8, -2.6, 0.9, 0.9, 1.4, "Knob"),  # ...its handle
    block(5.8, CY - 1.6, -3.0, 0.6, 1.6, 1.6, "Knob"),  # dials
    block(5.8, CY - 1.6, 0.2, 0.6, 1.6, 1.6, "Knob"),
    block(6.15, CY - 1.0, -3.0, 0.2, 0.6, 0.3, "Slot"),
    block(6.15, CY - 1.0, 0.2, 0.2, 0.6, 0.3, "Slot"),
    block(5.65, CY + 4.6, 3.6, 0.3, 0.6, 4.0, "Shine"),  # a shine on the chrome
)

head = [
    block(0, CY + 1.4, -8.4, 8.0, 7.0, 5.2, "Rhino"),  # the rhino's head, out of the front...
    block(0, CY - 0.6, -11.6, 7.0, 4.4, 2.4, "Rhino"),  # ...its long snout
    plate(0, CY - 0.8, -12.85, 5.4, 2.4, "Mouth", depth=0.2),  # a wide open grin...
    plate(0, CY + 0.1, -13.0, 5.0, 0.6, "Teeth", depth=0.2),  # ...white teeth...
    plate(0, CY - 1.7, -13.0, 4.0, 0.5, "Teeth", depth=0.2),
    plate(0, CY - 1.3, -12.95, 2.6, 0.6, "Tongue", depth=0.2),  # ...a pink tongue
    rod((0, CY + 1.0, -11.2), (0, CY + 5.6, -12.6), 2.6, "Horn"),  # a big curved horn...
    rod((0, CY + 5.6, -12.6), (0, CY + 9.2, -11.6), 1.8, "Horn"),
    rod((0, CY + 9.2, -11.6), (0, CY + 10.6, -10.2), 0.9, "Horn"),
    rod((0, CY + 4.4, -9.8), (0, CY + 6.2, -9.6), 1.4, "Horn"),  # ...and a little one
]
head += both(
    plate(2.6, CY + 3.2, -11.15, 1.8, 1.8, "White", depth=0.2),  # blue eyes
    plate(2.6, CY + 3.2, -11.35, 1.2, 1.2, "Blue", depth=0.2),
    plate(2.6, CY + 3.2, -11.5, 0.6, 0.6, "Dark", depth=0.1),
    plate(2.3, CY + 3.6, -11.6, 0.3, 0.3, "Glint", depth=0.1),
    block(3.4, CY + 5.6, -7.2, 1.4, 2.0, 1.2, "Rhino", rot=(0, 0, -20)),  # ears
    block(3.4, CY + 5.6, -7.85, 0.8, 1.2, 0.2, "Ear", rot=(0, 0, -20)),
    plate(1.4, CY + 0.5, -12.85, 0.6, 0.4, "Dark", depth=0.1),  # nostrils
)

arms = []
for s in (-1, 1):  # grey rhino arms held out
    arms += [
        block(s * 7.0, CY + 0.6, -1.2, 3.0, 2.8, 2.8, "Rhino"),
        block(s * 9.2, CY + 0.2, -2.4, 2.6, 2.6, 3.4, "Rhino", rot=(0, s * 30, 0)),
        block(s * 10.2, CY + 0.0, -4.0, 2.6, 2.6, 1.4, "Rhino", rot=(0, s * 30, 0)),
        block(s * 10.7, CY - 0.6, -4.8, 0.7, 0.8, 0.5, "Nail", rot=(0, s * 30, 0)),
        block(s * 9.8, CY - 0.6, -5.1, 0.7, 0.8, 0.5, "Nail", rot=(0, s * 30, 0)),
    ]


def leg(x, z):
    return [
        block(x, 3.6, z, 3.4, 5.6, 3.4, "Rhino"),  # a short thick leg...
        block(x, 1.0, z, 3.8, 2.0, 3.8, "Rhino"),
    ] + [block(x + dx, 0.6, z - 1.95, 0.8, 1.0, 0.4, "Nail") for dx in (-1.1, 0, 1.1)]  # ...pale toenails


legs = leg(-3.2, -2.0) + leg(3.2, -2.0) + leg(-3.2, 3.0) + leg(3.2, 3.0)

ART = {
    "Comment": "Rhino Toasterino: a rhino whose body is a shiny chrome toaster with toast popping out, a grey rhino head with a big curved horn, blue eyes and a wide grin, grey arms, short thick legs.",
    "VoxelSize": 0.2,
    "Palette": {
        "Chrome": (206, 212, 222),
        "ChromeDark": (110, 116, 128),
        "Shine": (248, 250, 255),
        "Knob": (40, 42, 50),
        "Slot": (30, 30, 36),
        "Crust": (176, 104, 44),
        "Bread": (236, 196, 130),
        "Rhino": (150, 156, 164),
        "Horn": (232, 222, 196),
        "Mouth": (110, 36, 44),
        "Teeth": (250, 250, 250),
        "Tongue": (232, 110, 130),
        "White": (250, 250, 250),
        "Blue": (60, 150, 230),
        "Dark": (24, 22, 26),
        "Glint": (245, 245, 245),
        "Ear": (220, 160, 170),
        "Nail": (236, 228, 210),
    },
    "Materials": {"Chrome": "Metal", "Shine": "Metal"},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
