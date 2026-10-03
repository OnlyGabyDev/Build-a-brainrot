"""
Renders parts from a lab dump (tools/lab/lab.luau) to a PNG, four views (front 3/4,
front, side, back 3/4) like tools/voxel_art.py's previews, so builds can be looked at
without Studio:

  python3 tools/lab/render.py parts.json "<path filter>" out.png [more filters...]

Every filter renders as its own row (e.g. two mixed brainrots from the "mixes"
scenario: "Mixes.FrigoCamelo|Head|ChimpanziniBananini." and "Mixes.FrigoCamelo|Own|").
Blocks, wedges, balls and cylinders; no textures, decals or GUIs. Needs PIL.
"""

import json
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from voxel_art import render_view, solid_polygons, tessellate  # noqa: E402

VIEWS = (-35, 0, 90, 150)
SIZE = (380, 440)


def polygons_of(part):
    """The part's faces in world space: [(points, normal, color, outlined)]."""
    x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = part["CFrame"]
    shape = {"Center": (0, 0, 0), "Solid": {"Shape": part["Shape"] if part["Shape"] in ("Block", "Ball", "Cylinder") else "Wedge" if part["Shape"] == "WedgePart" else "Block",
                                          "Size": tuple(part["Size"]), "Rotation": (0, 0, 0)}}

    def world(v):
        return (x + r00 * v[0] + r01 * v[1] + r02 * v[2], y + r10 * v[0] + r11 * v[1] + r12 * v[2], z + r20 * v[0] + r21 * v[1] + r22 * v[2])

    def direction(v):
        return (r00 * v[0] + r01 * v[1] + r02 * v[2], r10 * v[0] + r11 * v[1] + r12 * v[2], r20 * v[0] + r21 * v[1] + r22 * v[2])

    out = []
    for points, normal in solid_polygons(shape):
        for piece in tessellate([world(p) for p in points], step=0.4):
            out.append((piece, direction(normal), tuple(part["Color"]), True))
    return out


def render_row(parts):
    polygons = [poly for part in parts if part.get("Transparency", 0) < 0.95 for poly in polygons_of(part)]
    points = [q for poly in polygons for q in poly[0]]
    lo = [min(q[i] for q in points) for i in range(3)]
    hi = [max(q[i] for q in points) for i in range(3)]
    center = tuple((lo[i] + hi[i]) / 2 for i in range(3))
    scale = 340 / max(hi[1] - lo[1], hi[0] - lo[0], hi[2] - lo[2], 0.1)
    return [render_view(polygons, azimuth, 18, scale, SIZE, center) for azimuth in VIEWS]


def main():
    if len(sys.argv) < 4:
        print(__doc__)
        return
    with open(sys.argv[1], encoding="utf-8") as handle:
        data = json.load(handle)
    rows = []
    for needle in sys.argv[3:]:
        parts = [part for part in data["Parts"] if needle in part["Path"]]
        if not parts:
            print(f"nothing matches {needle!r}")
            continue
        rows.append(render_row(parts))
    if not rows:
        return
    width = SIZE[0] * len(VIEWS) + 10 * (len(VIEWS) - 1)
    sheet = Image.new("RGB", (width, SIZE[1] * len(rows) + 10 * (len(rows) - 1)), (120, 120, 132))
    for r, views in enumerate(rows):
        for c, view in enumerate(views):
            sheet.paste(view, (c * (SIZE[0] + 10), r * (SIZE[1] + 10)))
    sheet.save(sys.argv[2])
    print(f"wrote {sys.argv[2]} ({len(rows)} row(s))")


if __name__ == "__main__":
    main()
