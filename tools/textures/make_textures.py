"""
Makes the edition textures for the Clay Studio and Vinyl Collectibles (MaterialVariants,
see tools/SetupMaterials.luau). Pure Python + PIL (numpy runs out of memory here).

  python tools/textures/make_textures.py

PlayDough*: hand-pressed play-dough, tinted by each part's color: a light color map with
soft lumps and fingerprint patches, a normal map from the same height (so the dents
catch the light), and a fairly matte roughness with a waxy sheen. Tileable.
VinylGloss: a low, even roughness, so vinyl figures get crisp highlights without the
washed-out look Reflectance gives.
"""

import math
import random
from pathlib import Path

from PIL import Image

OUT = Path(__file__).parent
N = 512
rng = random.Random(7)


def tile_offset(a: float, b: float) -> float:
    """The shortest offset from b to a on a tile N wide (so patches wrap round)."""
    d = (a - b) % N
    return d - N if d > N / 2 else d


# soft lumps: a few waves with whole-number frequencies, so the tile repeats seamlessly
waves = []
for _ in range(7):
    kx, ky = rng.randint(-4, 4), rng.randint(-4, 4)
    if kx == 0 and ky == 0:
        kx = 1
    waves.append((kx, ky, rng.uniform(0, math.tau), rng.uniform(0.5, 1.0) / math.hypot(kx, ky)))


def make_noise(cells: int):
    """Smooth value noise on a `cells` grid that wraps round the tile (0..1)."""
    grid = [[rng.random() for _ in range(cells)] for _ in range(cells)]

    def at(x: float, y: float) -> float:
        gx, gy = x / N * cells, y / N * cells
        x0, y0 = int(gx) % cells, int(gy) % cells
        x1, y1 = (x0 + 1) % cells, (y0 + 1) % cells
        tx, ty = gx - int(gx), gy - int(gy)
        tx, ty = tx * tx * (3 - 2 * tx), ty * ty * (3 - 2 * ty)
        top = grid[y0][x0] + (grid[y0][x1] - grid[y0][x0]) * tx
        bottom = grid[y1][x0] + (grid[y1][x1] - grid[y1][x0]) * tx
        return top + (bottom - top) * ty

    return at


# and the dough's kneaded unevenness: blotchy dents and bumps at two sizes
kneads = [(make_noise(12), 1.4), (make_noise(28), 0.35)]

# fingerprints: patches of squashed rings, fading out at their rims
prints = []
for _ in range(7):
    prints.append(
        {
            "x": rng.uniform(0, N),
            "y": rng.uniform(0, N),
            "radius": rng.uniform(60, 100),
            "turn": rng.uniform(0, math.pi),
            "squash": rng.uniform(0.6, 0.8),
            "period": rng.uniform(9, 12),
            "wobble": rng.uniform(0, math.tau),
        }
    )

# smears: a few shallow swipes, like a thumb dragged across
swipes = []
for _ in range(4):
    swipes.append(
        {
            "x": rng.uniform(0, N),
            "y": rng.uniform(0, N),
            "turn": rng.uniform(0, math.pi),
            "length": rng.uniform(80, 140),
            "width": rng.uniform(10, 18),
        }
    )

height = [[0.0] * N for _ in range(N)]
ridges = [[0.0] * N for _ in range(N)]
for y in range(N):
    row, ridge_row = height[y], ridges[y]
    for x in range(N):
        h = 0.0
        for kx, ky, phase, amp in waves:
            h += amp * math.sin(math.tau * (kx * x + ky * y) / N + phase)
        h *= 0.5
        for noise, amp in kneads:
            h += amp * (noise(x, y) - 0.5)
        ridge = 0.0
        for p in prints:
            dx, dy = tile_offset(x, p["x"]), tile_offset(y, p["y"])
            if abs(dx) > p["radius"] or abs(dy) > p["radius"]:
                continue
            c, s = math.cos(p["turn"]), math.sin(p["turn"])
            u, v = (dx * c + dy * s) / p["squash"], -dx * s + dy * c
            r = math.hypot(u, v)
            if r < p["radius"]:
                fade = (1 - (r / p["radius"]) ** 2) ** 2
                # loops, not a target: the rings bulge on one side and pinch on the other
                angle = math.atan2(v, u)
                bent = r * (1 + 0.18 * math.sin(angle + p["wobble"]) + 0.08 * math.sin(2 * angle))
                ridge += fade * math.sin(math.tau * bent / p["period"])
        for w in swipes:
            dx, dy = tile_offset(x, w["x"]), tile_offset(y, w["y"])
            c, s = math.cos(w["turn"]), math.sin(w["turn"])
            along, across = dx * c + dy * s, -dx * s + dy * c
            if abs(along) < w["length"] / 2:
                fade = math.cos(math.pi * along / w["length"]) ** 2
                h -= 0.6 * fade * math.exp(-((across / w["width"]) ** 2))
        row[x] = h + 0.18 * ridge
        ridge_row[x] = ridge

color = Image.new("L", (N, N))
rough = Image.new("L", (N, N))
normal = Image.new("RGB", (N, N))
STRENGTH = 9.0
for y in range(N):
    for x in range(N):
        h, ridge = height[y][x], ridges[y][x]
        color.putpixel((x, y), max(0, min(255, round(236 + 18 * h - 16 * ridge))))
        rough.putpixel((x, y), max(0, min(255, round(150 + 18 * abs(ridge)))))
        gx = height[y][(x + 1) % N] - height[y][(x - 1) % N]
        gy = height[(y + 1) % N][x] - height[(y - 1) % N][x]
        nx, ny, nz = -gx * STRENGTH, gy * STRENGTH, 1.0  # OpenGL style: green is up
        length = math.sqrt(nx * nx + ny * ny + nz * nz)
        normal.putpixel(
            (x, y),
            tuple(round((n / length * 0.5 + 0.5) * 255) for n in (nx, ny, nz)),
        )

color.save(OUT / "PlayDoughColor.png")
rough.save(OUT / "PlayDoughRoughness.png")
normal.save(OUT / "PlayDoughNormal.png")
Image.new("L", (256, 256), 40).save(OUT / "VinylGlossRoughness.png")
print("made PlayDoughColor/Roughness/Normal and VinylGlossRoughness in", OUT)
