# Gorillo Watermelondrillo (art v2, blocks): a watermelon gorilla, after the original meme
# image (by @alexey_pigeon): a big black gorilla whose belly is a whole round striped
# watermelon, cut open at the top (red flesh, a white rind) where its chest comes out; a
# gorilla's head (a dark grey face, a heavy brow, small eyes, wide nostrils); its "arms"
# are long black gorilla arms hanging down to big knuckles; short black legs.
from voxel_art import block, both, plate

CY = 12.5  # the melon's middle
LAYERS = [(15, 10, 13), (13, 13.4, 11.6), (10, 15, 10), (15.6, 6.4, 10), (10.6, 6.4, 14)]
TOP = CY + 6.7  # the cut

body = [block(0, CY, 0, w, h, l, "Melon") for w, h, l in LAYERS[:2] + LAYERS[3:]]
body.append(block(0, CY - 0.4, 0, 10, 14.2, 10, "Melon"))  # (its top is cut off)
for x in (-4.5, -1.5, 1.5, 4.5):  # dark green stripes, top to bottom
    body.append(plate(x, CY - 0.4, -7.15, 1.4, 11.0, "Stripe", depth=0.3))
    body.append(plate(x, CY - 0.4, 7.15, 1.4, 11.0, "Stripe", depth=0.3))
for z in (-3.0, 0.0, 3.0):
    body += both(block(7.95, CY, z, 0.3, 5.6, 1.4, "Stripe"))
body += [  # the cut: a white rind round red flesh...
    block(0, TOP + 0.2, 0, 12.4, 0.4, 10.6, "Rind"),
    block(0, TOP + 0.2, 0, 10.6, 0.4, 12.0, "Rind"),
    block(0, TOP + 0.5, 0, 11.2, 0.4, 9.4, "Flesh"),
    block(0, TOP + 0.5, 0, 9.4, 0.4, 10.8, "Flesh"),
    block(0, TOP + 2.6, 0.4, 9.6, 4.2, 7.0, "Fur"),  # ...and the gorilla's chest coming out
    block(0, TOP + 3.6, 0.4, 11.4, 2.6, 6.4, "Fur"),  # (its shoulders)
    block(0, TOP + 2.4, -3.15, 6.0, 3.0, 0.4, "Chest"),  # a dark grey chest
]

head = [
    block(0, TOP + 8.0, -0.8, 8.4, 7.4, 7.6, "Fur"),  # the gorilla's head...
    block(0, TOP + 10.8, 0.4, 6.4, 3.4, 6.0, "Fur"),  # ...its crest
    block(0, TOP + 7.4, -4.8, 6.8, 5.8, 0.6, "Face"),  # ...a grey face
    block(0, TOP + 9.4, -5.4, 7.2, 1.4, 1.6, "Face"),  # a heavy brow
    block(0, TOP + 6.2, -5.6, 5.0, 3.0, 1.8, "Face"),  # a wide muzzle
    plate(0, TOP + 5.0, -6.55, 3.2, 0.35, "Dark", depth=0.15),
]
head += both(
    plate(1.6, TOP + 8.3, -5.25, 1.2, 1.0, "Dark", depth=0.2),  # small eyes under the brow
    plate(1.4, TOP + 8.5, -5.4, 0.35, 0.35, "Glint", depth=0.1),
    plate(0.9, TOP + 6.9, -6.55, 0.9, 0.7, "Dark", depth=0.1),  # wide nostrils
    block(4.45, TOP + 8.0, -0.6, 0.6, 1.6, 1.4, "Fur"),  # little ears
)

arms = []
for s in (-1, 1):  # long gorilla arms hanging down to big knuckles
    arms += [
        block(s * 7.2, TOP + 2.8, 0.4, 3.6, 3.6, 4.0, "Fur"),  # a shoulder...
        block(s * 8.6, TOP - 2.6, 0.2, 3.6, 8.0, 3.8, "Fur", rot=(0, 0, s * 10)),  # ...upper arm...
        block(s * 9.4, TOP - 9.2, -0.2, 3.4, 6.8, 3.6, "Fur", rot=(0, 0, s * 4)),  # ...forearm...
        block(s * 9.6, 3.0, -0.4, 3.8, 2.8, 4.0, "Face"),  # ...big knuckles
        block(s * 9.6, 2.0, -2.5, 3.0, 1.0, 0.4, "Dark"),
    ]


def leg(x):
    return [
        block(x, 4.2, 0.4, 3.6, 4.8, 3.8, "Fur"),  # a short black leg...
        block(x, 0.8, -0.6, 4.0, 1.6, 5.2, "Face"),  # ...a dark grey foot
    ]


legs = leg(-3.0) + leg(3.0)

ART = {
    "Comment": "Gorillo Watermelondrillo: a big black gorilla whose belly is a round striped watermelon cut open at the top, a gorilla's head with a dark grey face, long arms down to big knuckles, short legs.",
    "VoxelSize": 0.2,
    "Palette": {
        "Melon": (66, 150, 64),
        "Stripe": (30, 90, 40),
        "Rind": (236, 246, 220),
        "Flesh": (234, 64, 70),
        "Fur": (40, 40, 46),
        "Chest": (90, 90, 100),
        "Face": (96, 96, 108),
        "Dark": (18, 18, 22),
        "Glint": (240, 240, 240),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
