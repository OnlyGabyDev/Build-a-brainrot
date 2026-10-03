"""
Voxel art in Python, for brainrots designed outside Studio (art v2).

The same shape language and voxelization rules as Shared/VoxelArt.luau: a voxel is
filled when its center is inside a shape; later shapes paint over earlier ones, carve
shapes cut holes, paint shapes only recolor filled voxels; each part is voxelized on its
own. Units are voxels: X left/right (0 = the center line), Y up (0 = the ground), -Z the
front (the face). The character's own right hand is at +X.

An art spec lives in tools/art/<BrainrotId>.py and defines ART (see TungTungTungSahur):
    python tools/voxel_art.py TungTungTungSahur [preview.png]
renders four views (front 3/4, front, side, back 3/4) to the preview PNG (default: the
working directory) and writes sync/ReplicatedStorage/Shared/Art/<BrainrotId>.luau, so
edit the .py and regenerate rather than editing that .luau by hand.

Pure Python + PIL (numpy runs this machine out of memory).
"""

import importlib.util
import math
import os
import sys

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


# Shapes ---------------------------------------------------------------------------

def box(x0, y0, z0, x1, y1, z1, color):
    return {"Kind": "Box", "Color": color, "Min": (min(x0, x1), min(y0, y1), min(z0, z1)), "Max": (max(x0, x1), max(y0, y1), max(z0, z1))}


def ball(cx, cy, cz, rx, ry, rz, color):
    return {"Kind": "Ball", "Color": color, "Center": (cx, cy, cz), "Radius": (rx, ry, rz),
            "Min": (cx - rx, cy - ry, cz - rz), "Max": (cx + rx, cy + ry, cz + rz)}


def cylinder(cx, cz, rx, rz, y0, y1, color):
    return {"Kind": "Cylinder", "Color": color, "Center": (cx, 0, cz), "Radius": (rx, 0, rz),
            "Min": (cx - rx, min(y0, y1), cz - rz), "Max": (cx + rx, max(y0, y1), cz + rz)}


def solid(shape, cx, cy, cz, sx, sy, sz, color, rot=(0, 0, 0)):
    """One smooth part, not voxelized (VoxelArt.solid): "Block", "Wedge", "Ball" (keep it
    round: sx = sy = sz) or "Cylinder" (its axis is its X), centered at (cx, cy, cz),
    (sx, sy, sz) voxels big, turned rot = (rx, ry, rz) degrees (CFrame.Angles order). A
    wedge's slope faces its -Z and up; its tall end is at +Z."""
    c = (cx, cy, cz)
    return {"Kind": "Solid", "Color": color, "Min": c, "Max": c, "Center": c,
            "Solid": {"Shape": shape, "Size": (sx, sy, sz), "Rotation": tuple(rot)}}


def block(cx, cy, cz, sx, sy, sz, color, rot=(0, 0, 0)):
    return solid("Block", cx, cy, cz, sx, sy, sz, color, rot)


def wedge(cx, cy, cz, sx, sy, sz, color, rot=(0, 0, 0)):
    return solid("Wedge", cx, cy, cz, sx, sy, sz, color, rot)


def rod(a, b, thickness, color, shape="Block"):
    """A block (or a cylinder: shape="Cylinder") from point a to point b, `thickness`
    across: legs, antennae, whiskers at any angle."""
    d = [b[i] - a[i] for i in range(3)]
    length = math.sqrt(sum(v * v for v in d))
    dx, dy, dz = (v / length for v in d)
    rz = -math.degrees(math.asin(max(-1, min(1, dx))))
    rx = math.degrees(math.atan2(dz, dy))
    middle = [(a[i] + b[i]) / 2 for i in range(3)]
    if shape == "Cylinder":  # (a cylinder's axis is its X: turn it onto Y first)
        return solid("Cylinder", *middle, length, thickness, thickness, color, (rx, 0, rz - 90))
    return solid("Block", *middle, thickness, length, thickness, color, (rx, 0, rz))


def plate(cx, cy, cz, sx, sy, color, depth=0.4, rot=(0, 0, 0)):
    """A thin plate facing -Z (an eye, a mouth, a stripe on a solid's front)."""
    return solid("Block", cx, cy, cz, sx, sy, depth, color, rot)


def carve(shape):
    copy = dict(shape)
    copy["Carve"] = True
    return copy


def paint(shape):
    copy = dict(shape)
    copy["Paint"] = True
    return copy


def mirror(shape):
    copy = dict(shape)
    copy["Min"] = (-shape["Max"][0], shape["Min"][1], shape["Min"][2])
    copy["Max"] = (-shape["Min"][0], shape["Max"][1], shape["Max"][2])
    if "Center" in shape:
        c = shape["Center"]
        copy["Center"] = (-c[0], c[1], c[2])
    if "Solid" in shape:
        r = shape["Solid"]["Rotation"]
        copy["Solid"] = dict(shape["Solid"], Rotation=(r[0], -r[1], -r[2]))  # (X's turn stays)
    return copy


def both(*shapes):
    """The shapes plus their mirrors."""
    out = []
    for shape in shapes:
        out.append(shape)
        out.append(mirror(shape))
    return out


def chain(a, b, r0, r1, color, steps=None):
    """A tapering rod of balls from point a (radius r0) to point b (radius r1): for things
    at an angle (a bat, a tail), since cylinders only stand upright."""
    length = math.dist(a, b)
    steps = steps or max(2, int(length / 0.6))
    out = []
    for k in range(steps + 1):
        t = k / steps
        p = [a[i] + (b[i] - a[i]) * t for i in range(3)]
        r = r0 + (r1 - r0) * t
        out.append(ball(p[0], p[1], p[2], r, r, r, color))
    return out


def contains(shape, p):
    if shape["Kind"] == "Solid":
        return False
    lo, hi = shape["Min"], shape["Max"]
    for i in range(3):
        if p[i] < lo[i] or p[i] > hi[i]:
            return False
    kind = shape["Kind"]
    if kind == "Box":
        return True
    c, r = shape["Center"], shape["Radius"]
    dx, dz = (p[0] - c[0]) / r[0], (p[2] - c[2]) / r[2]
    if kind == "Cylinder":
        return dx * dx + dz * dz <= 1
    dy = (p[1] - c[1]) / r[1]
    return dx * dx + dy * dy + dz * dz <= 1


def voxelize(shapes):
    """{ (x, y, z): colorKey } in absolute voxel cells (a cell's center is at +0.5)."""
    filled = [s for s in shapes if not s.get("Carve") and not s.get("Paint") and s["Kind"] != "Solid"]
    if not filled:
        return {}
    lo = [math.floor(min(s["Min"][i] for s in filled)) for i in range(3)]
    hi = [math.ceil(max(s["Max"][i] for s in filled)) for i in range(3)]
    cells = {}
    for y in range(lo[1], hi[1]):
        for z in range(lo[2], hi[2]):
            for x in range(lo[0], hi[0]):
                p = (x + 0.5, y + 0.5, z + 0.5)
                color = None
                for s in shapes:
                    if contains(s, p):
                        if s.get("Carve"):
                            color = None
                        elif color is not None or not s.get("Paint"):
                            color = s["Color"]
                if color is not None:
                    cells[(x, y, z)] = color
    return cells


# Rendering --------------------------------------------------------------------------

FACES = [((1, 0, 0), [(1, 0, 0), (1, 1, 0), (1, 1, 1), (1, 0, 1)]),
         ((-1, 0, 0), [(0, 0, 0), (0, 0, 1), (0, 1, 1), (0, 1, 0)]),
         ((0, 1, 0), [(0, 1, 0), (0, 1, 1), (1, 1, 1), (1, 1, 0)]),
         ((0, -1, 0), [(0, 0, 0), (1, 0, 0), (1, 0, 1), (0, 0, 1)]),
         ((0, 0, 1), [(0, 0, 1), (1, 0, 1), (1, 1, 1), (0, 1, 1)]),
         ((0, 0, -1), [(0, 0, 0), (0, 1, 0), (1, 1, 0), (1, 0, 0)])]


def norm(v):
    m = math.sqrt(sum(c * c for c in v))
    return tuple(c / m for c in v)


def cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def dot(a, b):
    return sum(a[i] * b[i] for i in range(3))


def turn(v, rot):
    """v turned by CFrame.Angles(rx, ry, rz) (degrees): X(Y(Z(v)))."""
    rx, ry, rz = (math.radians(r) for r in rot)
    x, y, z = v
    x, y = x * math.cos(rz) - y * math.sin(rz), x * math.sin(rz) + y * math.cos(rz)
    x, z = x * math.cos(ry) + z * math.sin(ry), -x * math.sin(ry) + z * math.cos(ry)
    y, z = y * math.cos(rx) - z * math.sin(rx), y * math.sin(rx) + z * math.cos(rx)
    return (x, y, z)


def solid_polygons(shape):
    """The faces of a solid: [(points, normal)] in voxel space."""
    sol = shape["Solid"]
    hx, hy, hz = (v / 2 for v in sol["Size"])
    kind = sol["Shape"]
    local = []
    if kind == "Block":
        for axis in range(3):
            for sign in (-1, 1):
                normal = [0, 0, 0]
                normal[axis] = sign
                h = [hx, hy, hz]
                u, v = [i for i in range(3) if i != axis]
                pts = []
                for du, dv in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
                    q = [0, 0, 0]
                    q[axis] = sign * h[axis]
                    q[u] = du * h[u]
                    q[v] = dv * h[v]
                    pts.append(tuple(q))
                local.append((pts, tuple(normal)))
    elif kind == "Wedge":
        b0, b1, b2, b3 = (-hx, -hy, -hz), (hx, -hy, -hz), (hx, -hy, hz), (-hx, -hy, hz)
        t2, t3 = (hx, hy, hz), (-hx, hy, hz)
        slope = norm((0, hz, -hy)) if hy or hz else (0, 1, 0)
        local += [([b0, b1, b2, b3], (0, -1, 0)), ([b3, b2, t2, t3], (0, 0, 1)), ([b0, t3, t2, b1], slope),
                  ([b0, b3, t3], (-1, 0, 0)), ([b1, t2, b2], (1, 0, 0))]
    elif kind == "Ball":
        r = hx
        rows, cols = 6, 10
        for i in range(rows):
            for j in range(cols):
                pts = []
                for di, dj in ((0, 0), (0, 1), (1, 1), (1, 0)):
                    lat = math.pi * ((i + di) / rows - 0.5)
                    lon = 2 * math.pi * (j + dj) / cols
                    pts.append((r * math.cos(lat) * math.cos(lon), r * math.sin(lat), r * math.cos(lat) * math.sin(lon)))
                lat = math.pi * ((i + 0.5) / rows - 0.5)
                lon = 2 * math.pi * (j + 0.5) / cols
                local.append((pts, (math.cos(lat) * math.cos(lon), math.sin(lat), math.cos(lat) * math.sin(lon))))
    elif kind == "Cylinder":
        r = min(hy, hz)
        n = 12
        ring = [(math.cos(2 * math.pi * k / n) * r, math.sin(2 * math.pi * k / n) * r) for k in range(n)]
        for k in range(n):
            (y0, z0), (y1, z1) = ring[k], ring[(k + 1) % n]
            mid = 2 * math.pi * (k + 0.5) / n
            local.append(([(-hx, y0, z0), (hx, y0, z0), (hx, y1, z1), (-hx, y1, z1)], (0, math.cos(mid), math.sin(mid))))
        local.append(([(hx, y, z) for y, z in ring], (1, 0, 0)))
        local.append(([(-hx, y, z) for y, z in ring], (-1, 0, 0)))
    c = shape["Center"]
    out = []
    for pts, normal in local:
        world = [tuple(c[i] + q[i] for i in range(3)) for q in (turn(pt, sol["Rotation"]) for pt in pts)]
        out.append((world, turn(normal, sol["Rotation"])))
    return out


def tessellate(points, step=1.0):
    """Splits a face into pieces about `step` voxels across, so the painter's sort (by each
    piece's middle) works next to small details."""
    def lerp(a, b, t):
        return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))

    if len(points) == 4:
        a, b, c, d = points
        n = max(1, math.ceil(math.dist(a, b) / step))
        m = max(1, math.ceil(math.dist(a, d) / step))
        out = []
        for i in range(n):
            for j in range(m):
                def at(u, v):
                    return lerp(lerp(a, b, u), lerp(d, c, u), v)
                out.append([at(i / n, j / m), at((i + 1) / n, j / m), at((i + 1) / n, (j + 1) / m), at(i / n, (j + 1) / m)])
        return out
    # a triangle (or a fan of them round a polygon's middle), split in a barycentric grid
    if len(points) > 3:
        middle = tuple(sum(q[i] for q in points) / len(points) for i in range(3))
        out = []
        for k in range(len(points)):
            out += tessellate([middle, points[k], points[(k + 1) % len(points)]], step)
        return out
    a, b, c = points
    n = max(1, math.ceil(max(math.dist(a, b), math.dist(a, c)) / step))

    def bary(i, j):
        return tuple(a[k] + (b[k] - a[k]) * i / n + (c[k] - a[k]) * j / n for k in range(3))

    out = []
    for i in range(n):
        for j in range(n - i):
            out.append([bary(i, j), bary(i + 1, j), bary(i, j + 1)])
            if i + j + 1 < n:
                out.append([bary(i + 1, j), bary(i + 1, j + 1), bary(i, j + 1)])
    return out


def render_view(polygons, azimuth, elevation, scale, size, center):
    """One orthographic view of [(points, normal, color)]. azimuth 0 = from the front (-Z),
    90 = from the character's right (+X)."""
    a, e = math.radians(azimuth), math.radians(elevation)
    to_camera = norm((math.sin(a) * math.cos(e), math.sin(e), -math.cos(a) * math.cos(e)))
    right = norm(cross((0, 1, 0), to_camera))  # (from the front, the character's right is on screen left)
    up = cross(to_camera, right)
    light = norm((0.5, 1, -0.7))
    image = Image.new("RGB", size, (150, 150, 162))
    draw = ImageDraw.Draw(image)

    def project(p):
        d = (p[0] - center[0], p[1] - center[1], p[2] - center[2])
        return (size[0] / 2 + dot(d, right) * scale, size[1] / 2 - dot(d, up) * scale)

    visible = [poly for poly in polygons if dot(poly[1], to_camera) > 0]

    def depth(poly):
        pts = poly[0]
        mid = tuple(sum(q[i] for q in pts) / len(pts) for i in range(3))
        return dot(mid, to_camera)

    for points, normal, base, outlined in sorted(visible, key=depth):
        shade = 0.58 + 0.42 * max(0.0, dot(normal, light))
        fill = tuple(min(255, int(c * shade)) for c in base)
        draw.polygon([project(q) for q in points], fill=fill, outline=tuple(int(c * 0.85) for c in fill) if outlined else fill)
    return image


def render(art, path):
    colors = {key: tuple(value) for key, value in art["Palette"].items()}
    cells = {}
    polygons = []
    for part in ("Legs", "Body", "Arms", "Head"):
        shapes = art["Parts"].get(part) or []
        for cell, color in voxelize(shapes).items():
            cells[cell] = color
        for shape in shapes:
            if shape["Kind"] == "Solid":
                for points, normal in solid_polygons(shape):
                    for piece in tessellate(points):
                        polygons.append((piece, normal, colors[shape["Color"]], False))
    for cell, color in cells.items():
        for normal, corners in FACES:
            if (cell[0] + normal[0], cell[1] + normal[1], cell[2] + normal[2]) in cells:
                continue
            polygons.append(([(cell[0] + o[0], cell[1] + o[1], cell[2] + o[2]) for o in corners], normal, colors[color], True))
    points = [q for poly in polygons for q in poly[0]]
    lo = [min(q[i] for q in points) for i in range(3)]
    hi = [max(q[i] for q in points) for i in range(3)]
    center = tuple((lo[i] + hi[i]) / 2 for i in range(3))
    scale = 380 / max(hi[1] - lo[1], 1)
    size = (380, 440)
    views = [render_view(polygons, az, 18, scale, size, center) for az in (-35, 0, 90, 150)]
    sheet = Image.new("RGB", (size[0] * len(views) + 10 * (len(views) - 1), size[1]), (120, 120, 132))
    for index, view in enumerate(views):
        sheet.paste(view, (index * (size[0] + 10), 0))
    sheet.save(path)
    return len(cells) + sum(1 for part in art["Parts"].values() for s in part if s["Kind"] == "Solid")


# Luau --------------------------------------------------------------------------------

def num(v):
    text = f"{v:.3f}".rstrip("0").rstrip(".")
    return "0" if text in ("-0", "") else text


def shape_luau(s):
    if s["Kind"] == "Solid":
        sol = s["Solid"]
        values = (*s["Center"], *sol["Size"], *sol["Rotation"])
        return f'solid("{sol["Shape"]}", {", ".join(num(v) for v in values)}, "{s["Color"]}")'
    if s["Kind"] == "Box":
        call = f'box({", ".join(num(v) for v in (*s["Min"], *s["Max"]))}, "{s["Color"]}")'
    elif s["Kind"] == "Ball":
        call = f'ball({", ".join(num(v) for v in (*s["Center"], *s["Radius"]))}, "{s["Color"]}")'
    else:
        c, r = s["Center"], s["Radius"]
        call = f'cylinder({", ".join(num(v) for v in (c[0], c[2], r[0], r[2], s["Min"][1], s["Max"][1]))}, "{s["Color"]}")'
    if s.get("Carve"):
        call = f"carve({call})"
    if s.get("Paint"):
        call = f"paint({call})"
    return call


def emit(name, art, path):
    # declare only the constructors the shapes use (an unused local is a lint warning)
    calls = " ".join(shape_luau(s) for shapes in art["Parts"].values() for s in shapes)
    used = [n for n in ("box", "ball", "cylinder", "solid", "carve", "paint") if f"{n}(" in calls]
    lines = [f"-- {art['Comment']}", "--",
             f"-- Generated by tools/voxel_art.py from tools/art/{name}.py: edit that and regenerate.", "",
             "local V = require(script.Parent.Parent.VoxelArt)", "",
             f"local {', '.join(used)} = {', '.join('V.' + n for n in used)}", "",
             "return {", f"\tVoxelSize = {num(art['VoxelSize'])},", "\tPalette = {"]
    for key, value in art["Palette"].items():
        lines.append(f"\t\t{key} = Color3.fromRGB({value[0]}, {value[1]}, {value[2]}),")
    lines.append("\t},")
    if art.get("Materials"):
        lines.append("\tMaterials = {")
        for key, value in art["Materials"].items():
            lines.append(f"\t\t{key} = Enum.Material.{value},")
        lines.append("\t},")
    if art.get("Joints"):
        lines.append("\tJoints = {")
        for key, value in art["Joints"].items():
            lines.append(f"\t\t{key} = Vector3.new({', '.join(num(v) for v in value)}),")
        lines.append("\t},")
    lines.append("\tParts = {")
    for part in ("Legs", "Body", "Arms", "Head"):
        shapes = art["Parts"].get(part)
        if not shapes:
            continue
        lines.append(f"\t\t{part} = {{")
        for s in shapes:
            lines.append(f"\t\t\t{shape_luau(s)},")
        lines.append("\t\t},")
    lines.append("\t},")
    lines.append("}")
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines) + "\n")


def overlaps(art):
    """Cells claimed by two different parts (they flicker in game)."""
    seen, shared = {}, set()
    for part, shapes in art["Parts"].items():
        for cell in voxelize(shapes):
            if cell in seen and seen[cell] != part:
                shared.add(cell)
            seen[cell] = part
    return len(shared)


def main():
    name = sys.argv[1]
    preview = sys.argv[2] if len(sys.argv) > 2 else f"{name}_preview.png"
    spec = importlib.util.spec_from_file_location(name, os.path.join(ROOT, "tools", "art", f"{name}.py"))
    module = importlib.util.module_from_spec(spec)
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    spec.loader.exec_module(module)
    art = module.ART
    count = render(art, preview)
    emit(name, art, os.path.join(ROOT, "sync", "ReplicatedStorage", "Shared", "Art", f"{name}.luau"))
    print(f"{name}: {count} voxels, {overlaps(art)} cells shared between parts, preview {preview}")


if __name__ == "__main__":
    main()
