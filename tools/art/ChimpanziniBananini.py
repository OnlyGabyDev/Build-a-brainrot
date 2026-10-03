# Chimpanzini Bananini (art v2): a grumpy chimp in a peeled banana: a green-topped head
# with a pink face, pink ears, small dark eyes under a heavy brow and a frown; the banana's
# yellow body curves down into a curl it stands on (its "legs"), a brown tip at the end;
# two peel flaps hang down its sides (its "arms"). Reference: Steal a Brainrot's render.
from voxel_art import ball, box, both, carve, chain, paint

# the banana, top to bottom: the body is the upper half, the curl it stands on the legs
upper = [
    ball(0, 16, 0, 3.8, 2.4, 3.4, "Banana"),
    ball(0.2, 13.6, 0, 3.7, 2.4, 3.3, "Banana"),
    ball(0.6, 11.2, 0, 3.5, 2.4, 3.1, "Banana"),
]
lower = [
    ball(1.3, 8.6, 0, 3.2, 2.3, 2.9, "Banana"),
    ball(2.4, 6.2, 0, 2.9, 2.2, 2.6, "Banana"),
    ball(3.8, 4.0, 0, 2.5, 2.1, 2.2, "Banana"),
    ball(5.3, 2.3, 0, 2.0, 1.9, 1.8, "Banana"),
    ball(6.6, 1.4, 0, 1.2, 1.2, 1.2, "Tip"),
]

body = list(upper)
body += [paint(box(-1, 9, -5, 1, 19, 5, "BananaLight"))]  # the ridge down its middle
legs = list(lower) + [carve(s) for s in upper]
legs += [paint(box(-1, 0, -5, 1, 9.8, 5, "BananaLight"))]

# the peel flaps, folded down its sides
arms = []
for side in (-1, 1):
    arms += chain((side * 3.4, 17.6, -0.6), (side * 5.4, 13.5, -1.4), 1.2, 1.05, "Banana")
    arms += chain((side * 5.4, 13.5, -1.4), (side * 5.8, 9.4, -1.6), 1.05, 0.85, "Banana")
    arms += [paint(ball(side * 5.4, 13.5, -2.6, 1.2, 4.5, 0.6, "BananaLight"))]  # the peel's pale inside
arms += [carve(s) for s in upper]

head = [
    ball(0, 21.6, -0.4, 3.8, 3.8, 3.4, "Green"),  # its head, green on top like the banana's stem end
    carve(upper[0]),
    ball(0, 20.8, -2.4, 2.9, 2.8, 1.6, "Face"),  # the pink face
    paint(box(-3, 22.6, -6, 3, 23.6, -1.5, "Brow")),  # a heavy brow
    paint(box(-2, 21.6, -6, -1, 22.6, -1.5, "Dark")),  # small dark eyes
    paint(box(1, 21.6, -6, 2, 22.6, -1.5, "Dark")),
    paint(box(-1, 19, -6, 1, 19.8, -3, "Dark")),  # a little frown
    paint(box(-2, 18.6, -6, -1, 19.4, -3, "Brow")),
    paint(box(1, 18.6, -6, 2, 19.4, -3, "Brow")),
]
head += both(ball(3.9, 21.2, -0.6, 1, 1.2, 0.8, "Face"))  # ears

ART = {
    "Comment": "Chimpanzini Bananini: a grumpy chimp in a peeled banana, standing on its curl, the peel flaps for arms.",
    "VoxelSize": 0.2,
    "Palette": {
        "Banana": (255, 222, 75),
        "BananaLight": (255, 240, 165),
        "Tip": (110, 75, 40),
        "Green": (95, 170, 65),
        "Face": (240, 140, 130),
        "Brow": (200, 105, 100),
        "Dark": (35, 25, 25),
    },
    "Joints": {"Legs": (1, 10, 0), "Head": (0, 21.6, -0.4)},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
