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
    solid = [s for s in shapes if not s.get("Carve") and not s.get("Paint")]
    lo = [math.floor(min(s["Min"][i] for s in solid)) for i in range(3)]
    hi = [math.ceil(max(s["Max"][i] for s in solid)) for i in range(3)]
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


def render_view(cells, colors, azimuth, elevation, scale, size):
    """One orthographic view. azimuth 0 = from the front (-Z), 90 = from the character's
    right (+X)."""
    a, e = math.radians(azimuth), math.radians(elevation)
    to_camera = norm((math.sin(a) * math.cos(e), math.sin(e), -math.cos(a) * math.cos(e)))
    right = norm(cross((0, 1, 0), to_camera))  # (from the front, the character's right is on screen left)
    up = cross(to_camera, right)
    light = norm((0.5, 1, -0.7))
    xs = [c[0] for c in cells]
    ys = [c[1] for c in cells]
    zs = [c[2] for c in cells]
    center = ((min(xs) + max(xs) + 1) / 2, (min(ys) + max(ys) + 1) / 2, (min(zs) + max(zs) + 1) / 2)
    image = Image.new("RGB", size, (150, 150, 162))
    draw = ImageDraw.Draw(image)

    def project(p):
        d = (p[0] - center[0], p[1] - center[1], p[2] - center[2])
        return (size[0] / 2 + dot(d, right) * scale, size[1] / 2 - dot(d, up) * scale)

    order = sorted(cells, key=lambda c: dot((c[0] + 0.5, c[1] + 0.5, c[2] + 0.5), to_camera))
    for cell in order:
        base = colors[cells[cell]]
        for normal, corners in FACES:
            if dot(normal, to_camera) <= 0:
                continue
            if (cell[0] + normal[0], cell[1] + normal[1], cell[2] + normal[2]) in cells:
                continue
            shade = 0.58 + 0.42 * max(0.0, dot(normal, light))
            fill = tuple(min(255, int(c * shade)) for c in base)
            edge = tuple(int(c * 0.82) for c in fill)
            points = [project((cell[0] + o[0], cell[1] + o[1], cell[2] + o[2])) for o in corners]
            draw.polygon(points, fill=fill, outline=edge)
    return image


def render(art, path):
    cells = {}
    for part in ("Legs", "Body", "Arms", "Head"):
        shapes = art["Parts"].get(part)
        if shapes:
            for cell, color in voxelize(shapes).items():
                cells[cell] = color
    colors = {key: tuple(value) for key, value in art["Palette"].items()}
    height = max(c[1] for c in cells) - min(c[1] for c in cells) + 1
    scale = 380 / max(height, 1)
    size = (380, 440)
    views = [render_view(cells, colors, az, 18, scale, size) for az in (-35, 0, 90, 150)]
    sheet = Image.new("RGB", (size[0] * len(views) + 10 * (len(views) - 1), size[1]), (120, 120, 132))
    for index, view in enumerate(views):
        sheet.paste(view, (index * (size[0] + 10), 0))
    sheet.save(path)
    return len(cells)


# Luau --------------------------------------------------------------------------------

def num(v):
    text = f"{v:.3f}".rstrip("0").rstrip(".")
    return "0" if text in ("-0", "") else text


def shape_luau(s):
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
    used = [n for n in ("box", "ball", "cylinder", "carve", "paint") if f"{n}(" in calls]
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
