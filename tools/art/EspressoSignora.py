# Espresso Signora (art v2, blocks): a coffee-cup lady, after the original meme image (by
# @ncracfbcr4x): her head is a cream coffee cup (a gold rim, dark coffee inside, steam
# curling up, a handle on her side) with a glamorous face (winged eyes with lashes, arched
# brows, red lips), a long black gown and long black opera gloves, a pearl necklace; one hand
# on her hip, the other holding up a tiny espresso cup on a saucer (ours: the original holds
# a cigarette holder, which we leave out).
from voxel_art import block, both, plate, rod, solid


def round_(cy, h, d, color, x=0.0, z=0.0):
    """An upright round slice, h tall, d across."""
    return solid("Cylinder", x, cy, z, h, d, d, color, rot=(0, 0, 90))


legs = [  # a long black gown...
    block(0, 2.2, 0, 8.0, 3.6, 7.0, "Dress"),
    block(0, 2.2, 0, 7.0, 3.6, 8.0, "Dress"),
    block(0, 7.0, 0, 6.6, 6.2, 5.6, "Dress"),
    block(0, 10.6, 0, 7.0, 3.0, 5.8, "Dress"),
    block(0, 0.35, 0, 8.4, 0.5, 7.4, "Gold"),  # a gold hem
]
legs += both(block(1.4, 0.6, -3.9, 1.4, 1.2, 1.8, "Heel"))  # ...red heels peeking out

body = [
    block(0, 14.6, 0, 6.6, 5.4, 5.2, "Dress"),  # the bodice...
    block(0, 12.4, 0, 7.2, 0.8, 6.0, "Gold"),  # ...a gold belt
    block(0, 18.2, 0, 7.8, 2.0, 4.4, "Skin"),  # her shoulders
    block(0, 17.4, 0, 7.0, 0.5, 5.4, "Dress"),  # the gown's straight neckline
    block(0, 20.2, 0, 2.4, 2.4, 2.4, "Skin"),  # her neck
]
for k in range(-4, 5):  # a pearl necklace
    body.append(block(k * 0.42, 18.85 - (k * k) * 0.03, -2.35 + abs(k) * 0.08, 0.45, 0.45, 0.45, "Pearl"))

HY = 23.6  # the middle of the cup
head = [
    round_(HY, 6.2, 8.8, "Cup"),  # the cream cup...
    round_(HY + 3.3, 0.5, 9.2, "Gold"),  # ...a gold rim...
    round_(HY + 3.55, 0.3, 7.8, "Coffee"),  # ...dark coffee inside
    rod((0.4, HY + 3.3, 0.6), (1.6, HY + 4.8, 0.6), 0.8, "Steam"),  # steam curling up
    rod((1.6, HY + 4.8, 0.6), (0.4, HY + 6.2, 0.4), 0.7, "Steam"),
    rod((0.4, HY + 6.2, 0.4), (1.2, HY + 7.4, 0.2), 0.6, "Steam"),
    block(-5.5, HY + 0.2, 0, 0.8, 3.2, 1.0, "Cup"),  # the handle on her side
    block(-4.9, HY + 1.6, 0, 1.6, 0.8, 1.0, "Cup"),
    block(-4.9, HY - 1.2, 0, 1.6, 0.8, 1.0, "Cup"),
    plate(0, HY - 1.8, -4.35, 1.8, 0.5, "Lips", depth=0.8),  # red lips
    plate(0, HY - 2.2, -4.35, 1.2, 0.4, "Lips", depth=0.8),
    plate(0, HY - 0.7, -4.25, 0.3, 0.8, "Shade", depth=0.8),  # a little nose
]
head += both(
    plate(1.6, HY + 0.3, -4.2, 1.8, 0.9, "White", depth=0.8),  # winged eyes...
    plate(1.45, HY + 0.25, -4.45, 0.7, 0.8, "Iris", depth=0.6),
    plate(1.9, HY + 0.85, -4.45, 2.4, 0.3, "Black", depth=0.6, rot=(0, 0, -8)),  # ...lashes and a wing
    plate(3.0, HY + 1.05, -4.0, 0.9, 0.3, "Black", depth=0.6, rot=(0, 0, -35)),
    plate(1.7, HY + 2.0, -4.25, 2.0, 0.3, "Black", depth=0.6, rot=(0, 0, -12)),  # arched brows
    plate(2.9, HY - 1.1, -3.4, 1.0, 0.5, "Blush", depth=0.8),
)

arms = [
    # her right hand on her hip...
    rod((3.9, 18.2, 0), (5.0, 16.6, 0.2), 1.4, "Skin"),
    rod((5.0, 16.6, 0.2), (6.2, 14.6, 0.4), 1.4, "Glove"),
    rod((6.2, 14.6, 0.4), (3.8, 12.9, -0.4), 1.3, "Glove"),
    block(3.6, 12.9, -0.6, 1.0, 1.2, 1.4, "Glove"),
    # ...her left holding up a tiny espresso cup
    rod((-3.9, 18.2, 0), (-5.0, 16.6, -0.4), 1.4, "Skin"),
    rod((-5.0, 16.6, -0.4), (-6.2, 15.0, -1.0), 1.4, "Glove"),
    rod((-6.2, 15.0, -1.0), (-6.4, 19.4, -3.0), 1.3, "Glove"),
    block(-6.4, 19.9, -3.2, 1.2, 1.0, 1.2, "Glove"),
    round_(20.5, 0.2, 2.2, "Gold", x=-6.4, z=-3.2),  # a gold saucer...
    round_(21.05, 0.9, 1.3, "Rim", x=-6.4, z=-3.2),  # ...a little white cup
    round_(21.45, 0.1, 1.1, "Coffee", x=-6.4, z=-3.2),
    block(-7.2, 21.1, -3.2, 0.4, 0.6, 0.3, "Rim"),
]

ART = {
    "Comment": "Espresso Signora: a cream coffee-cup head with a gold rim, steam and a glamorous face (winged eyes, red lips), a long black gown, black opera gloves, a pearl necklace, one hand on her hip, the other holding a tiny espresso cup.",
    "VoxelSize": 0.2,
    "Palette": {
        "Cup": (240, 226, 200),
        "Shade": (214, 192, 160),
        "Gold": (232, 182, 64),
        "Coffee": (70, 40, 24),
        "Steam": (252, 250, 246),
        "Lips": (200, 30, 50),
        "White": (252, 252, 252),
        "Iris": (60, 36, 24),
        "Black": (20, 18, 20),
        "Blush": (240, 170, 160),
        "Dress": (28, 24, 30),
        "Heel": (210, 30, 46),
        "Skin": (226, 176, 140),
        "Glove": (24, 22, 26),
        "Pearl": (250, 248, 240),
        "Rim": (250, 250, 250),
    },
    "Materials": {"Gold": "Metal"},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
