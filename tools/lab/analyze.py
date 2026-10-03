"""
Reads what tools/lab/lab.luau wrote (every part's path, shape, size, CFrame, color...)
and reports on it:

  python3 tools/lab/analyze.py counts parts.json [depth]
      parts per branch of the tree (Workspace.Tycoons.Plot1.Lines...), heaviest first,
      and the other instances (lights, particles, GUIs) by class
  python3 tools/lab/analyze.py zfight parts.json [path filter] [x1,y1,z1,x2,y2,z2]
      pairs of parts with faces in the same plane, facing the same way, overlapping:
      they flicker (z-fighting). Faces pressed flat against another part are ignored
      (hidden), and so are pairs of the same color and material (they can't show it).
      With a box (world studs), only pairs with a part whose middle is inside it (every
      part still counts for hiding faces).
  python3 tools/lab/analyze.py above parts.json
      parts in a room that reach above its ceiling (through the floor above)

Pure Python, no packages. Positions are in studs, world space.
"""

import json
import math
import sys
from collections import Counter, defaultdict

EPS_PLANE = 0.005  # faces this close are one plane (the game stacks layers 0.02 apart on purpose)
MIN_AREA = 0.02  # square studs of overlap worth reporting


def load(path):
    with open(path, encoding="utf-8") as handle:
        return json.load(handle)


# Geometry ------------------------------------------------------------------------------


def axes_of(cf):
    # CFrame components: x, y, z, then the rotation matrix row by row (R00 R01 R02 ...)
    x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf
    right = (r00, r10, r20)  # the part's X axis in world space (a column)
    up = (r01, r11, r21)
    back = (r02, r12, r22)
    return (x, y, z), right, up, back


def add(a, b):
    return (a[0] + b[0], a[1] + b[1], a[2] + b[2])


def scale(a, k):
    return (a[0] * k, a[1] * k, a[2] * k)


def dot(a, b):
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


def faces_of(part):
    """The flat faces of a part as (normal, polygon in world space)."""
    center, right, up, back = axes_of(part["CFrame"])
    sx, sy, sz = part["Size"]
    shape = part["Shape"]
    faces = []
    if part.get("Mesh") in ("Sphere",):
        return faces  # a sphere mesh has no flat faces
    if shape == "Ball":
        return faces
    if shape == "Cylinder":
        # the axis is the part's X; the ends are discs (as 16-gons) of the smaller of Y, Z
        radius = min(sy, sz) / 2
        for sign in (-1, 1):
            middle = add(center, scale(right, sign * sx / 2))
            polygon = []
            for k in range(16):
                angle = k / 16 * math.tau
                offset = add(scale(up, math.cos(angle) * radius), scale(back, math.sin(angle) * radius))
                polygon.append(add(middle, offset))
            faces.append((scale(right, sign), polygon))
        return faces
    hx, hy, hz = sx / 2, sy / 2, sz / 2

    def corner(a, b, c):
        return add(center, add(scale(right, a), add(scale(up, b), scale(back, c))))

    boxes = {
        (1, 0, 0): [corner(hx, -hy, -hz), corner(hx, hy, -hz), corner(hx, hy, hz), corner(hx, -hy, hz)],
        (-1, 0, 0): [corner(-hx, -hy, -hz), corner(-hx, -hy, hz), corner(-hx, hy, hz), corner(-hx, hy, -hz)],
        (0, 1, 0): [corner(-hx, hy, -hz), corner(-hx, hy, hz), corner(hx, hy, hz), corner(hx, hy, -hz)],
        (0, -1, 0): [corner(-hx, -hy, -hz), corner(hx, -hy, -hz), corner(hx, -hy, hz), corner(-hx, -hy, hz)],
        (0, 0, 1): [corner(-hx, -hy, hz), corner(hx, -hy, hz), corner(hx, hy, hz), corner(-hx, hy, hz)],
        (0, 0, -1): [corner(-hx, -hy, -hz), corner(-hx, hy, -hz), corner(hx, hy, -hz), corner(hx, -hy, -hz)],
    }
    if shape == "WedgePart":
        # a wedge's slope faces -Z and up: it has a bottom, a back (+Z) and two triangles
        boxes = {
            (0, -1, 0): boxes[(0, -1, 0)],
            (0, 0, 1): boxes[(0, 0, 1)],
            (1, 0, 0): [corner(hx, -hy, -hz), corner(hx, hy, hz), corner(hx, -hy, hz)],
            (-1, 0, 0): [corner(-hx, -hy, -hz), corner(-hx, -hy, hz), corner(-hx, hy, hz)],
        }
    elif shape != "Block":
        return faces  # meshes, corner wedges, trusses: skipped
    for local_normal, polygon in boxes.items():
        normal = add(scale(right, local_normal[0]), add(scale(up, local_normal[1]), scale(back, local_normal[2])))
        faces.append((normal, polygon))
    return faces


def plane_basis(normal):
    """Two unit vectors spanning the plane with this normal."""
    helper = (0, 1, 0) if abs(normal[1]) < 0.9 else (1, 0, 0)
    u = cross(helper, normal)
    length = math.sqrt(dot(u, u))
    u = scale(u, 1 / length)
    v = cross(normal, u)
    return u, v


def cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def to_2d(polygon, u, v):
    return [(dot(p, u), dot(p, v)) for p in polygon]


def area(polygon):
    total = 0.0
    for i in range(len(polygon)):
        x1, y1 = polygon[i]
        x2, y2 = polygon[(i + 1) % len(polygon)]
        total += x1 * y2 - x2 * y1
    return total / 2


def ccw(polygon):
    return polygon if area(polygon) >= 0 else list(reversed(polygon))


def clip(subject, clipper):
    """Sutherland-Hodgman: the part of convex `subject` inside convex `clipper` (both CCW)."""
    output = subject
    for i in range(len(clipper)):
        if not output:
            break
        a = clipper[i]
        b = clipper[(i + 1) % len(clipper)]

        def inside(p):
            return (b[0] - a[0]) * (p[1] - a[1]) - (b[1] - a[1]) * (p[0] - a[0]) >= -1e-9

        def meet(p, q):
            x1, y1, x2, y2 = a[0], a[1], b[0], b[1]
            x3, y3, x4, y4 = p[0], p[1], q[0], q[1]
            den = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4)
            if abs(den) < 1e-12:
                return q
            t = ((x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)) / den
            return (x1 + t * (x2 - x1), y1 + t * (y2 - y1))

        current, output = output, []
        for j in range(len(current)):
            p = current[j]
            q = current[(j + 1) % len(current)]
            if inside(q):
                if not inside(p):
                    output.append(meet(p, q))
                output.append(q)
            elif inside(p):
                output.append(meet(p, q))
    return output


def overlap_area(poly_a, poly_b, normal):
    u, v = plane_basis(normal)
    a = ccw(to_2d(poly_a, u, v))
    b = ccw(to_2d(poly_b, u, v))
    clipped = clip(a, b)
    if len(clipped) < 3:
        return 0.0, abs(area(a))
    return abs(area(clipped)), abs(area(a))


# Reports ---------------------------------------------------------------------------------


def counts(data, depth):
    parts = data["Parts"]
    branches = Counter()
    for part in parts:
        names = part["Path"].split(".")
        branches[".".join(names[:depth])] += 1
    print(f"{len(parts)} parts")
    for branch, count in branches.most_common(60):
        print(f"{count:7d}  {branch}")
    print("\nother instances:")
    for name, count in sorted(data["Others"].items(), key=lambda item: -item[1])[:30]:
        print(f"{count:7d}  {name}")
    print("\ntags (instances, parts they move):")
    for name, entry in sorted(data.get("Tags", {}).items(), key=lambda item: -item[1]["Parts"]):
        print(f"{entry['Count']:7d} {entry['Parts']:7d}  {name}")


def plane_key(normal, offset):
    # normals snapped to a grid, so parallel faces land together
    return (round(normal[0], 3), round(normal[1], 3), round(normal[2], 3), round(offset / EPS_PLANE))


def inside(part, box):
    if not box:
        return True
    x, y, z = part["CFrame"][:3]
    return box[0] <= x <= box[3] and box[1] <= y <= box[4] and box[2] <= z <= box[5]


def zfight(data, needle, box=None):
    parts = [p for p in data["Parts"] if needle in p["Path"] and p["Transparency"] < 0.98]
    buckets = defaultdict(list)
    for index, part in enumerate(parts):
        for normal, polygon in faces_of(part):
            offset = dot(normal, polygon[0])
            entry = (index, normal, offset, polygon)
            # a plane near a bucket's edge goes in both neighbours
            key = plane_key(normal, offset)
            buckets[key].append(entry)
            buckets[key[:3] + (key[3] + 1,)].append(entry)

    def hidden(index, normal, offset, polygon):
        """Pressed flat against an opaque part facing the other way (it can't be seen)."""
        opposite = scale(normal, -1)
        key = plane_key(opposite, -offset)
        covered = 0.0
        total = None
        for other_index, other_normal, other_offset, other_polygon in buckets.get(key, []):
            if other_index == index or abs(other_offset + offset) > EPS_PLANE or dot(other_normal, normal) > -0.999:
                continue
            if parts[other_index]["Transparency"] > 0.05:
                continue
            shared, own = overlap_area(polygon, other_polygon, normal)
            total = own
            covered += shared
        return total is not None and covered >= total * 0.95

    seen = set()
    findings = []
    for key, entries in buckets.items():
        if len(entries) < 2:
            continue
        for i in range(len(entries)):
            index_a, normal_a, offset_a, polygon_a = entries[i]
            for j in range(i + 1, len(entries)):
                index_b, normal_b, offset_b, polygon_b = entries[j]
                if index_a == index_b or dot(normal_a, normal_b) < 0.9999 or abs(offset_a - offset_b) > EPS_PLANE:
                    continue
                pair = (min(index_a, index_b), max(index_a, index_b), round(offset_a, 2), normal_a)
                if pair in seen:
                    continue
                seen.add(pair)
                a, b = parts[index_a], parts[index_b]
                if not (inside(a, box) or inside(b, box)):
                    continue
                if a["Color"] == b["Color"] and a["Material"] == b["Material"] and not a.get("Guis") and not b.get("Guis"):
                    continue
                shared, _ = overlap_area(polygon_a, polygon_b, normal_a)
                if shared < MIN_AREA:
                    continue
                if hidden(index_a, normal_a, offset_a, polygon_a) or hidden(index_b, normal_b, offset_b, polygon_b):
                    continue
                findings.append((shared, a, b, normal_a))
    findings.sort(key=lambda item: -item[0])
    print(f"{len(findings)} z-fighting pairs among {len(parts)} parts matching {needle!r}" + (f" in {box}" if box else ""))
    for shared, a, b, normal in findings[:200]:
        n = tuple(round(c, 2) for c in normal)
        print(f"{shared:8.2f} sq studs  facing {n}\n    {a['Path']}  [{a['Shape']} {a['Material']} {a['Color']} at {a['CFrame'][:3]}]\n    {b['Path']}  [{b['Shape']} {b['Material']} {b['Color']} at {b['CFrame'][:3]}]")


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        return
    command, path = sys.argv[1], sys.argv[2]
    data = load(path)
    if command == "counts":
        counts(data, int(sys.argv[3]) if len(sys.argv) > 3 else 4)
    elif command == "zfight":
        box = [float(v) for v in sys.argv[4].split(",")] if len(sys.argv) > 4 else None
        zfight(data, sys.argv[3] if len(sys.argv) > 3 else "", box)
    else:
        print(__doc__)


if __name__ == "__main__":
    main()
