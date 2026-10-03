# Ballerina Cappuccina (art v2, blocks): a big squared cappuccino cup for a head (coffee
# with a foam heart on top, a handle on its right), a sweet face on its front (big eyes
# with lashes, arched brows, a pink nose and blush, a wide smile); a pink leotard and a
# wide two-layer tutu; smooth thin arms held out to the sides; pink tights, one leg lifted
# to the side, pink pointe shoes. Reference: Steal a Brainrot's render.
from voxel_art import block, both, plate, rod, solid

head = [
    block(0, 25, 0, 9.6, 10, 9.2, "Cup"),  # the cup
    block(0, 30.3, 0, 10.2, 0.6, 9.8, "Cup"),  # its rim
    block(0, 30.4, 0, 8.6, 0.6, 8.2, "Coffee"),  # the coffee...
    block(0, 30.75, -0.4, 2.4, 0.2, 2, "Foam"),  # ...a foam heart on it
    block(-0.9, 30.75, 0.6, 1.6, 0.2, 1.6, "Foam", rot=(0, 45, 0)),
    block(0.9, 30.75, 0.6, 1.6, 0.2, 1.6, "Foam", rot=(0, 45, 0)),
    block(0, 20.3, 0, 8.6, 0.6, 8.2, "Cup"),  # its foot
    # the handle, on its right
    block(5.6, 28, 0, 2.4, 1.2, 1.4, "Cup"),
    block(5.6, 22.6, 0, 2.4, 1.2, 1.4, "Cup"),
    block(7.2, 25.3, 0, 1.2, 6.6, 1.4, "Cup"),
    plate(0, 23.6, -4.75, 0.9, 0.7, "Nose", depth=0.3),
    plate(0, 21.9, -4.7, 3.4, 0.6, "Smile", depth=0.2),  # a wide smile...
]
head += both(
    plate(2.1, 25.4, -4.7, 2, 2.4, "White", depth=0.2),  # big eyes
    plate(1.9, 25.2, -4.85, 1.2, 1.6, "Iris", depth=0.2),
    plate(1.75, 25.6, -4.95, 0.5, 0.5, "White", depth=0.1),  # a glint
    plate(2.1, 26.8, -4.85, 2.6, 0.5, "Lash", depth=0.2),  # lashes
    plate(3.4, 27.0, -4.85, 0.9, 0.4, "Lash", depth=0.2, rot=(0, 0, -35)),
    plate(2.1, 28.4, -4.7, 2.6, 0.5, "Brow", depth=0.2, rot=(0, 0, -12)),  # arched brows
    plate(3.4, 22.8, -4.7, 1.6, 0.8, "Blush", depth=0.15),
    plate(2.1, 22.3, -4.7, 0.8, 0.6, "Smile", depth=0.2, rot=(0, 0, 30)),  # ...its corners up
)

body = [
    block(0, 17.4, 0, 4.2, 5.6, 3.4, "Leotard"),
    solid("Cylinder", 0, 14.4, 0, 1.4, 12.4, 12.4, "Tutu", rot=(0, 0, 90)),  # the tutu
    solid("Cylinder", 0, 15.4, 0, 1.0, 9.6, 9.6, "TutuLight", rot=(0, 0, 90)),
    block(0, 15.2, 0, 4.4, 0.6, 3.6, "Ribbon"),  # its waistband
]

arms = both(
    solid("Cylinder", 5.6, 19, 0, 7.8, 1.3, 1.3, "Skin"),  # held out to the sides
    solid("Ball", 9.7, 19, 0, 1.8, 1.8, 1.8, "Skin"),
)

legs = [
    rod((-1.3, 14, 0), (-1.3, 1.8, -0.3), 1.5, "Tights", shape="Cylinder"),  # the standing leg
    block(-1.3, 0.9, -0.6, 1.7, 1.8, 2.6, "Shoe"),  # a pointe shoe
    plate(-1.3, 2.4, -0.6, 1.9, 0.5, "Ribbon", depth=2.8),
    rod((1.3, 13.6, 0), (6.0, 5.8, -0.5), 1.5, "Tights", shape="Cylinder"),  # the lifted leg
    block(6.5, 4.9, -0.6, 1.7, 2.6, 1.7, "Shoe", rot=(0, 0, -30)),
]

ART = {
    "Comment": "Ballerina Cappuccina: a squared cappuccino-cup head with a sweet face, a pink tutu, arms out, one leg lifted, pointe shoes.",
    "VoxelSize": 0.2,
    "Palette": {
        "Cup": (252, 250, 246),
        "Coffee": (120, 72, 45),
        "Foam": (240, 222, 195),
        "White": (255, 255, 255),
        "Iris": (110, 65, 40),
        "Lash": (35, 28, 30),
        "Brow": (150, 95, 60),
        "Nose": (255, 160, 170),
        "Blush": (255, 185, 195),
        "Smile": (225, 95, 115),
        "Leotard": (255, 175, 200),
        "Tutu": (255, 190, 215),
        "TutuLight": (255, 222, 236),
        "Skin": (252, 212, 188),
        "Tights": (255, 205, 215),
        "Shoe": (255, 150, 185),
        "Ribbon": (255, 120, 165),
    },
    "Joints": {"Legs": (0, 13.6, 0), "Head": (0, 25, 0)},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
