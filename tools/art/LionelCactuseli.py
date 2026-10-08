# Lionel Cactuseli (art v2, blocks): a cactus lion, after the original meme image (by
# @alexey_pigeon): a lion whose body is a green cactus (darker ribs round it, yellow
# spines), a proud lion head with a big orange-brown mane (darker tufts), a tan face, a pale
# muzzle and amber eyes; a green cactus tail ending in a red flower bud; four ribbed cactus
# legs with pale green paws (the front pair are its "arms").
from voxel_art import block, both, plate, rod

CY = 12.0  # the body's middle

body = [
    block(0, CY, 0.6, 8.4, 7.6, 13.0, "Cactus"),  # the cactus body...
    block(0, CY, 0.6, 7.6, 8.4, 12.4, "Cactus"),
]
for z in (-3.4, -1.0, 1.4, 3.8, 6.2):  # ...darker ribs round it...
    body.append(block(0, CY, z, 8.7, 8.7, 0.5, "Rib"))
for z in (-2.2, 0.2, 2.6, 5.0):  # ...yellow spines on its back and sides
    body.append(block(0, CY + 4.5, z, 0.3, 0.9, 0.3, "Spine"))
    body += both(block(4.5, CY + 1.6, z, 0.9, 0.3, 0.3, "Spine"), block(4.5, CY - 1.6, z + 0.6, 0.9, 0.3, 0.3, "Spine"))
tail = [(0, CY + 2.0, 7.0), (0, CY + 5.4, 10.0), (0, CY + 9.0, 9.6)]  # a cactus tail...
body += [rod(tail[k], tail[k + 1], 1.3, "Cactus") for k in range(2)]
body += [
    block(0, CY + 10.2, 9.4, 1.8, 2.4, 1.8, "Flower", rot=(-10, 0, 0)),  # ...ending in a red flower bud
    block(0, CY + 11.3, 9.2, 1.2, 1.0, 1.2, "FlowerDark", rot=(-10, 0, 0)),
]

HY, HZ = CY + 5.0, -7.4  # the head
head = [
    block(0, HY, HZ + 0.8, 9.6, 9.6, 5.0, "Mane"),  # a big mane...
    block(0, HY, HZ + 0.8, 10.6, 8.2, 4.4, "Mane"),
    block(0, HY + 0.2, HZ + 0.8, 8.0, 10.8, 4.2, "Mane"),
    block(0, HY - 0.4, HZ - 2.6, 5.4, 5.8, 2.6, "Face"),  # ...a tan face...
    block(0, HY - 2.0, HZ - 4.2, 3.4, 2.4, 1.4, "Muzzle"),  # ...a pale muzzle
    block(0, HY - 0.75, HZ - 4.85, 1.6, 1.0, 0.6, "Nose"),
    plate(0, HY - 2.75, HZ - 4.95, 1.4, 0.3, "Nose", depth=0.15),  # its mouth
    plate(0, HY + 1.6, HZ - 3.95, 0.5, 1.2, "FaceDark", depth=0.2),  # a frown line
]
head += both(
    block(4.7, HY + 2.6, HZ + 0.8, 1.6, 2.6, 3.6, "ManeDark"),  # darker tufts in the mane
    block(4.4, HY - 2.9, HZ + 0.8, 2.0, 2.6, 3.8, "ManeDark"),
    block(2.2, HY + 4.9, HZ + 0.8, 2.6, 1.6, 3.6, "ManeDark"),
    plate(1.45, HY + 0.6, HZ - 3.95, 1.4, 1.0, "Amber", depth=0.2),  # amber eyes...
    plate(1.35, HY + 0.6, HZ - 4.1, 0.6, 0.8, "Eye", depth=0.2),
    plate(1.6, HY + 1.4, HZ - 3.95, 1.8, 0.4, "FaceDark", depth=0.3, rot=(0, 0, 12)),  # ...proud brows
    block(2.4, HY + 3.5, HZ - 1.4, 1.4, 1.4, 0.8, "Face"),  # little ears
)


def leg(x, z):
    return [
        block(x, 4.6, z, 2.8, 8.6, 2.8, "Cactus"),  # a ribbed cactus leg...
        plate(x, 4.4, z - 1.45, 0.5, 6.0, "Rib", depth=0.2),
        block(x, 6.4, z - 1.6, 0.3, 0.3, 0.9, "Spine"),
        block(x, 3.4, z - 1.6, 0.3, 0.3, 0.9, "Spine"),
        block(x, 0.8, z - 0.5, 3.2, 1.6, 3.6, "Paw"),  # ...a pale green paw
    ]


arms = leg(-2.5, -4.2) + leg(2.5, -4.2)
legs = leg(-2.5, 5.2) + leg(2.5, 5.2)

ART = {
    "Comment": "Lionel Cactuseli: a lion whose body is a green cactus with darker ribs and yellow spines, a big orange-brown mane round a tan face, a cactus tail ending in a red flower bud, ribbed cactus legs.",
    "VoxelSize": 0.2,
    "Palette": {
        "Cactus": (92, 156, 66),
        "Rib": (58, 112, 46),
        "Spine": (250, 226, 120),
        "Flower": (214, 52, 52),
        "FlowerDark": (160, 30, 40),
        "Mane": (204, 106, 36),
        "ManeDark": (156, 70, 26),
        "Face": (220, 164, 96),
        "FaceDark": (150, 96, 50),
        "Muzzle": (242, 218, 176),
        "Nose": (90, 52, 44),
        "Amber": (250, 190, 60),
        "Eye": (30, 22, 20),
        "Paw": (176, 196, 104),
    },
    "Parts": {"Legs": legs, "Body": body, "Arms": arms, "Head": head},
}
