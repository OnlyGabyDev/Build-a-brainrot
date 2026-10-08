# Pot Hotspot (art v2, blocks): a skeleton begging for Wi-Fi, after the original meme image
# (by @dytzz88, 2025-03-08): a thin crouching skeleton whose head is a tall smartphone, its
# teal screen showing a sad, worn-out face (droopy dark eyes, worried brows, a frown); one
# bony arm holds up a second phone with a glowing Wi-Fi sign, the other hangs to its knee.
from voxel_art import block, both, plate, rod, solid

SY = 15.0  # the rib cage's middle

body = [
    rod((0, 9.8, 1.2), (0, 20.6, 0.8), 1.4, "Bone"),  # a spine...
    block(0, 10.4, 0.6, 5.4, 1.8, 2.4, "Bone"),  # ...a pelvis
    block(0, 9.6, 0.6, 2.2, 1.0, 2.0, "Joint"),
    block(0, SY + 4.4, 0.2, 5.6, 0.8, 1.6, "Bone"),  # collarbones
    rod((0, SY + 3.8, -1.6), (0, SY - 1.6, -1.5), 1.0, "Bone"),  # a breastbone
]
body += both(block(2.2, 10.9, 0.6, 1.8, 1.8, 2.6, "Bone", rot=(0, 0, -20)))  # (hip bones)
for k in range(5):  # ribs
    y = SY + 3.2 - k * 1.25
    w = 2.8 - abs(k - 1.5) * 0.25
    body += both(
        rod((0.3, y, 1.0), (w, y - 0.3, 0.0), 0.7, "Bone"),
        rod((w, y - 0.3, 0.0), (0.4, y - 0.7, -1.5), 0.7, "Bone"),
    )
for y in (11.8, 13.0):  # vertebrae below the ribs
    body.append(block(0, y, 1.1, 1.6, 0.6, 1.4, "Joint"))

HY, HZ = 26.2, -0.2  # the phone head
head = [
    rod((0, 20.4, 0.8), (0, 21.8, 0.2), 0.9, "Bone"),  # a neck...
    block(0, HY, HZ, 6.0, 10.4, 0.9, "Phone"),  # ...a tall black phone...
    plate(0, HY - 0.1, HZ - 0.5, 5.4, 9.8, "Screen", depth=0.2),  # ...its teal screen
    plate(0, HY + 4.65, HZ - 0.65, 1.8, 0.5, "Phone", depth=0.15),  # (the notch)
    block(0, HY - 1.0, HZ - 0.75, 0.6, 1.4, 0.2, "Shade"),  # a thin nose...
    plate(0, HY - 2.9, HZ - 0.75, 1.8, 0.35, "Shade", depth=0.15),  # ...a frown
    plate(0, HY - 4.4, HZ - 0.65, 1.8, 0.2, "Bar", depth=0.15),  # (the home bar)
]
head += both(
    plate(1.15, HY + 0.6, HZ - 0.7, 1.6, 1.8, "Socket", depth=0.15),  # droopy dark eyes...
    plate(1.15, HY + 0.4, HZ - 0.8, 0.7, 0.7, "Glint", depth=0.1),
    plate(1.35, HY - 0.6, HZ - 0.7, 1.4, 0.3, "Shade", depth=0.1, rot=(0, 0, 15)),  # ...tired bags under them
    plate(1.4, HY + 2.1, HZ - 0.7, 1.8, 0.35, "Shade", depth=0.1, rot=(0, 0, -18)),  # worried brows
    plate(1.15, HY - 3.15, HZ - 0.75, 0.6, 0.35, "Shade", depth=0.1, rot=(0, 0, 35)),  # (the frown's ends)
)

PX, PY, PZ = 6.4, 25.4, -1.6  # the Wi-Fi phone, held up
arms = []
for s in (-1, 1):
    arms.append(solid("Ball", s * 3.1, SY + 4.0, 0.4, 1.6, 1.6, 1.6, "Joint"))  # shoulders
arms += [
    rod((3.1, SY + 4.0, 0.4), (5.6, SY - 0.6, -0.8), 1.2, "Bone"),  # one arm holds up a phone...
    solid("Ball", 5.6, SY - 0.6, -0.8, 1.2, 1.2, 1.2, "Joint"),
    rod((5.6, SY - 0.6, -0.8), (6.2, PY - 3.6, PZ + 0.6), 1.1, "Bone"),
    block(6.2, PY - 3.4, PZ + 0.6, 1.4, 1.6, 1.0, "Bone"),  # (the bony hand)
    block(PX, PY, PZ, 4.0, 6.8, 0.6, "Phone"),  # ...a second phone...
    plate(PX, PY, PZ - 0.35, 3.4, 6.2, "DarkScreen", depth=0.15),
    block(PX, PY - 1.6, PZ - 0.5, 0.6, 0.6, 0.2, "Wifi"),  # ...a glowing Wi-Fi sign
]
for k, w in enumerate((1.4, 2.5, 3.2)):
    y = PY - 1.0 + k * 0.8
    arms += [block(PX, y + 0.2, PZ - 0.5, w * 0.5, 0.35, 0.2, "Wifi")]
    arms += [block(PX + d * w * 0.38, y - 0.05, PZ - 0.5, w * 0.36, 0.35, 0.2, "Wifi", rot=(0, 0, -d * 32)) for d in (-1, 1)]
arms += [
    plate(PX - 0.9, PY - 2.6, PZ - 0.45, 1.8, 0.3, "Wifi", depth=0.1),  # ("WiFi")
    rod((-3.1, SY + 4.0, 0.4), (-4.0, SY - 1.6, 0.2), 1.2, "Bone"),  # ...the other hangs to its knee
    solid("Ball", -4.0, SY - 1.6, 0.2, 1.2, 1.2, 1.2, "Joint"),
    rod((-4.0, SY - 1.6, 0.2), (-4.4, 7.4, -0.8), 1.1, "Bone"),
    block(-4.5, 6.6, -0.9, 1.2, 1.8, 1.0, "Bone"),
]

legs = []
for s in (-1, 1):  # thin crouching legs
    hip, knee, ankle = (s * 2.0, 10.0, 0.6), (s * 2.6, 6.4, -3.6), (s * 2.6, 1.0, 0.6)
    legs += [
        rod(hip, knee, 1.4, "Bone"),
        solid("Ball", *knee, 1.5, 1.5, 1.5, "Joint"),
        rod(knee, ankle, 1.2, "Bone"),
        block(s * 2.6, 0.4, -0.8, 1.4, 0.8, 3.4, "Bone"),  # bony feet
    ]

ART = {
    "Comment": "Pot Hotspot: a thin crouching skeleton whose head is a tall phone with a sad face on its teal screen, one bony arm holding up a second phone with a glowing Wi-Fi sign.",
    "VoxelSize": 0.2,
    "Palette": {
        "Bone": (230, 224, 204),
        "Joint": (196, 188, 164),
        "Phone": (26, 28, 32),
        "Screen": (96, 176, 164),
        "DarkScreen": (20, 30, 36),
        "Socket": (24, 36, 36),
        "Glint": (200, 236, 230),
        "Shade": (46, 96, 90),
        "Bar": (230, 240, 240),
        "Wifi": (90, 255, 220),
    },
    "Materials": {"Wifi": "Neon"},
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
