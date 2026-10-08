# Ta Ta Ta Ta Sahur (art v2, blocks): a round terracotta teapot on long legs, after the
# original meme image (by @__chenesacc__): a squat pot stepped out of blocks with a lid and
# a knob, big round blue eyes and a small mouth; its "arms" are the spout curling up and
# puffing steam on one side and the handle looping down into a big hanging hand on the
# other; long terracotta legs on huge bare feet with toes.
from voxel_art import block, both, plate, rod

FRONT = -5.0  # the pot's front face (at its widest)

legs = []
for x in (-2.8, 2.8):
    legs += [
        rod((x, 12.6, 0), (x * 1.15, 1.6, -0.4), 2.2, "Skin"),  # long legs
        block(x * 1.15, 0.8, -1.8, 3.8, 1.6, 6, "Skin"),  # huge bare feet...
    ]
    for k, t in enumerate((-1.3, -0.45, 0.4, 1.25)):
        legs.append(block(x * 1.15 + t * (1 if x > 0 else -1), 0.75, -5.0 + abs(k - 1.5) * 0.25, 0.8, 1.1, 0.8, "Skin"))  # ...toes
        legs.append(plate(x * 1.15 + t * (1 if x > 0 else -1), 1.1, -5.45 + abs(k - 1.5) * 0.25, 0.5, 0.4, "Nail", depth=0.2))

# the pot: blocks stepped out to the widest in the middle, so it reads round
body = [
    block(0, 13.2, 0, 7, 1.2, 7, "PotDark"),  # its foot ring
    block(0, 14.6, 0, 9, 1.6, 9, "Pot"),
    block(0, 17.6, 0, 10, 4.4, 10, "Pot"),  # the belly
    block(0, 17.6, 0, 10.4, 0.8, 10.4, "PotDark"),  # a band round it
]
head = [
    block(0, 21.4, 0, 9.6, 3.2, 9.6, "Pot"),
    block(0, 24.0, 0, 8.6, 2, 8.6, "Pot"),
    block(0, 25.4, 0, 6.6, 0.8, 6.6, "PotDark"),  # the lid's rim...
    block(0, 26.3, 0, 5.4, 1, 5.4, "Pot"),  # ...the lid
    block(0, 27.2, 0, 1.2, 0.8, 1.2, "PotDark"),
    block(0, 28.4, 0, 2.2, 1.6, 2.2, "Pot"),  # its knob
]
head += both(
    plate(2.2, 21.6, -4.9, 3.0, 3.0, "White", depth=0.4),  # big round eyes...
    plate(2.2, 21.6, -5.05, 2.2, 3.4, "White", depth=0.2),
    plate(2.2, 21.6, -5.05, 3.4, 2.2, "White", depth=0.2),
    plate(2.0, 21.4, -5.3, 1.8, 1.8, "Blue", depth=0.2),  # ...blue irises
    plate(1.95, 21.35, -5.45, 0.8, 0.8, "Dark", depth=0.15),
    plate(1.6, 22.1, -5.55, 0.4, 0.4, "White", depth=0.1),  # glints
)
head.append(plate(0, 20.4, -4.9, 1.6, 0.45, "Mouth", depth=0.3))  # a small mouth

# the spout: out of the right side of the belly, curling up, a puff of steam at its tip
SPOUT = [(5.0, 17.6, 0), (7.6, 19.0, 0), (9.2, 22.0, 0), (10.0, 25.2, 0), (11.4, 27.0, 0)]
arms = []
for k in range(len(SPOUT) - 1):
    arms.append(rod(SPOUT[k], SPOUT[k + 1], 2.6 - k * 0.35, "Pot"))
arms += [
    block(12.0, 27.6, 0, 1.6, 1.2, 1.6, "PotDark", rot=(0, 0, 40)),  # its lip
    block(12.8, 29.2, 0, 1.4, 1.4, 1.4, "Steam"),  # steam
    block(13.4, 30.8, 0.4, 1.8, 1.8, 1.8, "Steam"),
    block(13.0, 32.8, 0.2, 1.2, 1.2, 1.2, "Steam"),
]
# the handle: a loop out of the left side, its end turning into an arm and a big hand
HANDLE = [(-5.0, 19.0, 0), (-8.2, 21.6, 0), (-9.6, 19.6, 0), (-9.2, 15.0, -0.2), (-8.6, 11.2, -0.6)]
for k in range(len(HANDLE) - 1):
    arms.append(rod(HANDLE[k], HANDLE[k + 1], 1.8, "Pot" if k < 2 else "Skin"))
arms += [
    block(-8.5, 9.8, -0.8, 2.6, 2.6, 1.6, "Skin"),  # the hand...
    block(-7.4, 7.8, -0.8, 0.6, 2, 0.8, "Skin"),  # ...long fingers
    block(-8.2, 7.6, -0.8, 0.6, 2.2, 0.8, "Skin"),
    block(-9.0, 7.8, -0.8, 0.6, 2, 0.8, "Skin"),
    block(-9.8, 8.4, -0.8, 0.6, 1.6, 0.8, "Skin"),
]

ART = {
    "Comment": "Ta Ta Ta Ta Sahur: a round terracotta teapot with big blue eyes, its spout steaming and its handle ending in a hand, on long legs and huge bare feet.",
    "VoxelSize": 0.2,
    "Palette": {
        "Pot": (176, 82, 56),
        "PotDark": (140, 60, 40),
        "Skin": (196, 102, 78),
        "Nail": (236, 200, 190),
        "White": (250, 250, 250),
        "Blue": (60, 150, 220),
        "Dark": (25, 22, 26),
        "Mouth": (95, 40, 30),
        "Steam": (240, 242, 248),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
