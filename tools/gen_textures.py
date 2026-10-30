#!/usr/bin/env python3
"""Generates the original, tileable PBR texture sets used by THE TIDE REMEMBERS.

Every texture is procedural (numpy), so there are no third-party licensing
concerns. Each set gets an albedo (with baked cavity/AO), a normal map and a
roughness map, 1024x1024 and seamlessly tileable.
Run:  python3 tools/gen_textures.py            (all sets)
      python3 tools/gen_textures.py bark slate (selected sets)
"""
import os
import sys
import numpy as np
from PIL import Image

N = 1024
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "textures")
YY, XX = np.mgrid[0:N, 0:N] / N


# --------------------------------------------------------------------------- primitives
def value_noise(res, seed, res_y=None):
    """Tileable value noise, quintic interpolation. res_y != res gives stretched noise."""
    ry = res_y or res
    r = np.random.default_rng(seed)
    grid = r.random((ry, res))

    def axis(n):
        t = np.arange(N) * n / N
        i0 = np.floor(t).astype(int)
        f = t - i0
        return i0, (i0 + 1) % n, f * f * f * (f * (f * 6 - 15) + 10)
    x0, x1, fx = axis(res)
    y0, y1, fy = axis(ry)
    a, b = grid[np.ix_(y0, x0)], grid[np.ix_(y0, x1)]
    c, d = grid[np.ix_(y1, x0)], grid[np.ix_(y1, x1)]
    fx, fy = fx[None, :], fy[:, None]
    return (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy


def fbm(base=4, octaves=6, gain=0.5, seed=0):
    r = np.random.default_rng(seed)
    out, amp, total, res = np.zeros((N, N)), 1.0, 0.0, base
    for _ in range(octaves):
        if res > N // 2:
            break
        out += amp * value_noise(res, int(r.integers(1 << 30)))
        total += amp
        amp *= gain
        res *= 2
    return out / total


def ridged(base, octaves, seed):
    return 1.0 - np.abs(fbm(base, octaves, 0.5, seed) * 2 - 1)


def sample(field, x, y):
    """Bilinear wrap-around sample of `field` at fractional texel coords."""
    x0 = np.floor(x).astype(int)
    y0 = np.floor(y).astype(int)
    fx, fy = x - x0, y - y0
    x0 %= N
    y0 %= N
    x1, y1 = (x0 + 1) % N, (y0 + 1) % N
    return (field[y0, x0] * (1 - fx) + field[y0, x1] * fx) * (1 - fy) + (field[y1, x0] * (1 - fx) + field[y1, x1] * fx) * fy


def warp(field, amount, base=4, seed=0):
    dx = (fbm(base, 4, 0.5, seed) - 0.5) * amount * N
    dy = (fbm(base, 4, 0.5, seed + 1) - 0.5) * amount * N
    ys, xs = np.mgrid[0:N, 0:N].astype(float)
    return sample(field, xs + dx, ys + dy)


def blur(img, sigma):
    """Periodic gaussian blur (FFT)."""
    f = np.fft.fftfreq(N)
    g = np.exp(-2 * (np.pi * sigma) ** 2 * (f[:, None] ** 2 + f[None, :] ** 2))
    return np.real(np.fft.ifft2(np.fft.fft2(img) * g))


def voronoi(cells_x, cells_y=None, jitter=0.9, seed=0):
    """Periodic Voronoi. Returns (F1, F2, cell id) in cell units."""
    cells_y = cells_y or cells_x
    r = np.random.default_rng(seed)
    pts = r.random((cells_y, cells_x, 2)) * jitter + (1 - jitter) * 0.5
    ids = r.random((cells_y, cells_x))
    gx = XX * cells_x
    gy = YY * cells_y
    cx, cy = np.floor(gx).astype(int), np.floor(gy).astype(int)
    f1 = np.full((N, N), 9.0)
    f2 = np.full((N, N), 9.0)
    cid = np.zeros((N, N))
    for oy in (-1, 0, 1):
        for ox in (-1, 0, 1):
            nx, ny = cx + ox, cy + oy
            p = pts[ny % cells_y, nx % cells_x]
            d = np.hypot(nx + p[..., 0] - gx, ny + p[..., 1] - gy)
            closer = d < f1
            f2 = np.where(closer, f1, np.minimum(f2, d))
            cid = np.where(closer, ids[ny % cells_y, nx % cells_x], cid)
            f1 = np.where(closer, d, f1)
    return f1, f2, cid


def norm01(a):
    a = a - a.min()
    return a / max(a.max(), 1e-6)


def colorize(t, stops):
    pos = np.array([s[0] for s in stops])
    cols = np.array([s[1] for s in stops], dtype=float)
    return np.stack([np.interp(t, pos, cols[:, c]) for c in range(3)], -1)


def mix(a, b, t):
    t = np.asarray(t)
    if t.ndim == 2 and a.ndim == 3:
        t = t[..., None]
    return a * (1 - t) + b * t


def streaks(seed, density=0.5, length=0.35):
    """Vertical run-off stains (water, rust) that drip downward."""
    seeds = np.clip((value_noise(48, seed) - (1 - density * 0.6)) * 6, 0, 1)
    seeds = seeds * (value_noise(8, seed + 1) > 0.45)
    out = np.zeros((N, N))
    acc = seeds.copy()
    step = max(1, int(length * N / 40))
    for i in range(40):
        acc = np.roll(acc, step, 0) * 0.93
        out = np.maximum(out, acc)
    return blur(out, 1.5)


def cavity(h, sigma=6, strength=2.5):
    """Baked ambient occlusion: darken where the surface is below its surroundings."""
    return np.clip(1.0 - (blur(h, sigma) - h) * strength, 0.35, 1.0)


def normal_from_height(h, strength):
    s = strength * N / 512.0
    dx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * s
    dy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * s
    n = np.stack([-dx, dy, np.ones_like(h)], -1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    return n * 0.5 + 0.5


def save(name, albedo, height, rough, nstrength=4.0, ao=True, ao_sigma=6, ao_k=2.5):
    rough = np.broadcast_to(np.asarray(rough, dtype=float), height.shape)
    if ao:
        albedo = albedo * cavity(height, ao_sigma, ao_k)[..., None]
    os.makedirs(OUT, exist_ok=True)
    Image.fromarray((np.clip(albedo, 0, 1) * 255).astype(np.uint8)).save(f"{OUT}/{name}_albedo.png")
    Image.fromarray((normal_from_height(height, nstrength) * 255).astype(np.uint8)).save(f"{OUT}/{name}_normal.png")
    Image.fromarray((np.clip(rough, 0, 1) * 255).astype(np.uint8), "L").save(f"{OUT}/{name}_rough.png")
    print("wrote", name)


# --------------------------------------------------------------------------- materials
def planks(name, light, dark, boards=6, seed=1, paint=None):
    r = np.random.default_rng(seed)
    board = np.floor(YY * boards).astype(int) % boards
    within = (YY * boards) % 1.0
    offs = r.random(boards)
    tint = r.uniform(0.82, 1.12, boards)
    # long grain: warped stripes running along x
    grain_base = fbm(3, 6, 0.55, seed)
    grain = np.sin((YY * boards * 22 + grain_base * 9 + value_noise(4, seed + 3) * 3) * np.pi * 2) * 0.5 + 0.5
    grain = warp(grain, 0.03, 6, seed + 4)
    fine = fbm(64, 3, 0.5, seed + 5)
    # knots: ring patterns around a few points
    knots = np.zeros((N, N))
    for _ in range(9):
        kx, ky = r.random(), r.random()
        dx = (XX - kx + 0.5) % 1.0 - 0.5
        dy = ((YY - ky + 0.5) % 1.0 - 0.5) * 3.0
        d = np.hypot(dx, dy) * 40
        knots += np.exp(-d * d * 0.6) * (0.6 + 0.4 * np.sin(d * 6))
    t = np.clip(grain * 0.55 + fine * 0.25 + knots * 0.5, 0, 1)
    alb = colorize(t, [(0, dark), (0.55, tuple((np.array(dark) + np.array(light)) / 2)), (1, light)])
    alb *= tint[board][..., None]
    # board seams and staggered butt joints, with nail heads
    seam = np.abs(within - 0.5) > 0.475
    joint_x = (XX + offs[board]) % 1.0
    butt = np.abs(joint_x - 0.5) > 0.4975
    gaps = (seam | butt).astype(float)
    # nail heads either side of each butt joint
    nails = ((np.abs(joint_x - 0.5) > 0.485) & (np.abs(within - 0.5) < 0.035)).astype(float)
    weather = fbm(2, 5, 0.5, seed + 9)
    alb = mix(alb, alb.mean(-1, keepdims=True) * np.array([1.0, 1.0, 1.02]), np.clip(weather - 0.3, 0, 1) * 0.6)
    if paint is not None:
        chip = np.clip((fbm(6, 6, 0.55, seed + 11) - 0.62) * 6, 0, 1)
        alb = mix(np.ones_like(alb) * np.array(paint) * (0.9 + 0.1 * fine[..., None]), alb, chip)
    alb = mix(alb, np.array([0.03, 0.03, 0.03]), gaps * 0.85)
    alb = mix(alb, np.array([0.12, 0.08, 0.06]), nails)
    h = t * 0.25 + grain * 0.1 - gaps * 1.0 - (within - 0.5) ** 2 * 0.6 + nails * 0.2
    rough = 0.55 + 0.35 * (1 - weather) - gaps * 0.2
    save(name, alb, h, rough, 3.0)


def ashlar(name, base, seed=2, rows=8, mortar=(0.17, 0.16, 0.14), whitewash=None):
    """Cut-stone masonry: rows of blocks with recessed mortar."""
    r = np.random.default_rng(seed)
    row = np.floor(YY * rows).astype(int)
    within_y = (YY * rows) % 1.0
    blocks_per_row = 4
    offset = r.random(rows)
    bx = (XX + offset[row]) * blocks_per_row
    # irregular block widths via a warped coordinate
    bx = bx + (value_noise(4, seed) - 0.5) * 0.6
    within_x = bx % 1.0
    block_id = (np.floor(bx).astype(int) % blocks_per_row) + row * blocks_per_row
    ids = r.random(rows * blocks_per_row + 8)
    tone = ids[block_id]
    mx = np.minimum(within_x, 1 - within_x) * (N / blocks_per_row)
    my = np.minimum(within_y, 1 - within_y) * (N / rows)
    edge = np.minimum(mx, my)
    mortar_m = np.clip(1.0 - (edge - 3.0) / 2.0, 0, 1)
    bevel = np.clip(edge / 14.0, 0, 1)
    surf = fbm(8, 6, 0.5, seed + 1)
    pits = (fbm(64, 2, 0.5, seed + 2) > 0.72) * 0.4
    chips = np.clip((fbm(16, 4, 0.5, seed + 3) - 0.66) * 5, 0, 1) * (1 - bevel)
    stone = np.ones((N, N, 3)) * np.array(base)
    stone *= (0.78 + 0.42 * tone)[..., None] * (0.85 + 0.3 * surf)[..., None]
    lichen = np.clip((fbm(4, 5, 0.5, seed + 4) - 0.6) * 5, 0, 1)
    stone = mix(stone, np.array([0.33, 0.36, 0.25]), lichen * 0.5)
    alb = mix(stone, np.array(mortar), mortar_m)
    h = bevel * 0.6 + surf * 0.25 - pits * 0.2 - chips * 0.4 - mortar_m * 0.3
    rough = 0.75 + 0.2 * surf - lichen * 0.1
    if whitewash is not None:
        wash = np.clip((fbm(4, 6, 0.55, seed + 5) - 0.22) * 6, 0, 1) * (1 - mortar_m * 0.35)
        stain = streaks(seed + 6, 0.6, 0.5)
        ww = np.ones((N, N, 3)) * np.array(whitewash) * (0.92 + 0.08 * surf)[..., None]
        ww = mix(ww, ww * np.array([0.72, 0.66, 0.55]), np.clip(stain, 0, 1) * 0.7)
        alb = mix(alb, ww, wash)
        h = h * (1 - wash * 0.5) + wash * 0.05
        rough = rough * (1 - wash) + 0.85 * wash
    save(name, alb, h, rough, 5.0, ao_sigma=4, ao_k=3.0)


def rock(name, stops, seed=3, strata=0.0, cracks=True, streak=0.0, rough_base=0.6):
    h = fbm(4, 8, 0.55, seed)
    h = warp(h, 0.08, 3, seed + 1)
    rid = ridged(6, 6, seed + 2)
    t = norm01(h * 0.6 + rid * 0.4)
    if strata > 0:
        bands = np.sin((YY * 14 + warp(fbm(2, 4, 0.5, seed + 3), 0.05, 3, seed + 4) * 4) * np.pi * 2) * 0.5 + 0.5
        t = norm01(t * (1 - strata) + bands * strata)
    alb = colorize(t, stops)
    hh = t.copy()
    if cracks:
        f1, f2, _ = voronoi(7, seed=seed + 5)
        crack = np.clip(1 - (f2 - f1) * 32, 0, 1) * np.clip((fbm(6, 4, 0.5, seed + 6) - 0.52) * 6, 0, 1)
        alb = mix(alb, alb * 0.3, crack)
        hh -= crack * 0.5
    if streak > 0:
        s = fbm(3, 5, 0.5, seed + 7)
        mineral = np.clip((np.sin((XX * 3 + s * 2.5) * np.pi * 2) - 0.86) * 7, 0, 1) * streak
        alb = mix(alb, np.array([0.17, 0.24, 0.22]), mineral)
    wet = fbm(2, 4, 0.5, seed + 8)
    rough = rough_base + 0.3 * wet - 0.25 * (1 - t)
    save(name, alb, hh, rough, 6.0)


def concrete(name, base, seed=4, formwork=True):
    fine = fbm(32, 5, 0.45, seed)
    big = fbm(3, 5, 0.5, seed + 1)
    t = norm01(fine * 0.6 + big * 0.4)
    alb = np.ones((N, N, 3)) * np.array(base) * (0.82 + 0.3 * t)[..., None]
    f1, _, cid = voronoi(90, seed=seed + 2)
    agg = (f1 < 0.18) & (cid > 0.6)
    alb[agg] *= 0.75
    pores = fbm(128, 2, 0.5, seed + 3) > 0.75
    alb[pores] *= 0.6
    stain = streaks(seed + 4, 0.7, 0.6)
    alb = mix(alb, alb * np.array([0.62, 0.6, 0.55]), np.clip(stain, 0, 1) * 0.8)
    seam = np.zeros((N, N))
    if formwork:
        seam = (np.abs((YY * 3) % 1.0 - 0.5) > 0.497).astype(float)
        alb = mix(alb, alb * 0.6, seam)
    h = t * 0.3 - agg * 0.1 - pores * 0.2 - seam * 0.3
    save(name, alb, h, 0.8 + 0.15 * t, 2.5)


def metal(name, paint, seed=5, panels=2):
    base_rust = fbm(4, 8, 0.55, seed)
    rust = np.clip((base_rust - 0.55) * 3.5, 0, 1)
    run = streaks(seed + 1, 0.8, 0.7)
    rust = np.clip(rust + run * 0.55, 0, 1)
    rcol = colorize(fbm(24, 5, 0.5, seed + 2), [(0, (0.14, 0.06, 0.03)), (0.5, (0.32, 0.15, 0.06)), (1, (0.45, 0.27, 0.12))])
    fine = fbm(32, 4, 0.5, seed + 3)
    pcol = np.ones((N, N, 3)) * np.array(paint) * (0.85 + 0.2 * fine)[..., None]
    # paint chips with bare metal halo
    chip = np.clip((fbm(12, 6, 0.55, seed + 4) - 0.6) * 8, 0, 1)
    bare = np.clip((fbm(12, 6, 0.55, seed + 4) - 0.55) * 8, 0, 1) - chip
    alb = mix(pcol, np.array([0.35, 0.35, 0.34]), np.clip(bare, 0, 1) * 0.7)
    alb = mix(alb, rcol, np.clip(rust + chip * 0.8, 0, 1))
    seam = (np.abs((XX * panels) % 1.0 - 0.5) > 0.494) | (np.abs((YY * panels) % 1.0 - 0.5) > 0.494)
    # a column of rivets beside each vertical seam
    rivet = (np.hypot((((XX * panels) % 1.0) - 0.04) * N / panels, (((YY * panels * 8) % 1.0) - 0.5) * N / (panels * 8)) < 5).astype(float)
    alb = mix(alb, alb * 0.35, seam.astype(float))
    h = rust * 0.3 + chip * -0.15 + fine * 0.05 - seam * 0.5 + rivet * 0.4
    rough = 0.4 + rust * 0.55 + chip * 0.1
    save(name, alb, h, rough, 3.0)


def grass(name, seed=6):
    # blades: short directional strokes from anisotropic noise
    strokes = np.zeros((N, N))
    r = np.random.default_rng(seed)
    for k in range(5):
        n = value_noise(256, seed + k)
        n = blur(n, 0.7)
        sheared = np.roll(n, int(r.integers(0, N)), 1)
        for s in range(6):
            sheared = np.maximum(sheared, np.roll(sheared, 1, 0) * 0.92)
        strokes += sheared
    strokes = norm01(strokes)
    clump = fbm(6, 5, 0.5, seed + 10)
    t = norm01(strokes * 0.6 + clump * 0.4)
    alb = colorize(t, [(0, (0.06, 0.075, 0.05)), (0.35, (0.13, 0.17, 0.1)), (0.7, (0.22, 0.26, 0.16)), (1, (0.38, 0.38, 0.27))])
    dry = np.clip((fbm(3, 5, 0.5, seed + 11) - 0.55) * 3, 0, 1)
    alb = mix(alb, alb.mean(-1, keepdims=True) * np.array([1.25, 1.1, 0.8]), dry * 0.6)
    soil = np.clip((fbm(4, 6, 0.5, seed + 12) - 0.62) * 5, 0, 1)
    alb = mix(alb, np.array([0.12, 0.1, 0.08]) * (0.8 + 0.4 * strokes[..., None]), soil)
    save(name, alb, t * 0.8 - soil * 0.2, 0.85 - 0.25 * t, 3.0)


def pebbles(name, stops, cells=26, seed=7, sand=(0.18, 0.17, 0.15)):
    f1, f2, cid = voronoi(cells, seed=seed)
    edge = np.clip((f2 - f1) * 4.0, 0, 1)
    dome = np.sqrt(np.clip(edge, 0, 1))
    stone = colorize(cid, stops) * (0.8 + 0.3 * fbm(32, 3, 0.5, seed + 1))[..., None]
    gap = edge < 0.08
    alb = mix(stone, np.array(sand) * (0.8 + 0.3 * fbm(64, 2, 0.5, seed + 2))[..., None], gap.astype(float))
    h = dome * 0.8 + fbm(32, 3, 0.5, seed + 3) * 0.1
    save(name, alb, h, 0.35 + 0.45 * (1 - dome), 5.0, ao_sigma=3, ao_k=3.0)


def wallpaper(name, seed=8):
    # faded damask: mirrored motif from noise, repeating 6x8
    tile_x = (XX * 6) % 1.0
    tile_y = (YY * 8) % 1.0
    m = np.abs(tile_x - 0.5) * 2
    motif = np.sin(m * 7 + np.sin(tile_y * np.pi * 2) * 2.5) * np.sin(tile_y * np.pi * 4 + m * 3)
    motif = (motif > 0.55).astype(float)
    stripes = (np.sin(XX * np.pi * 2 * 24) * 0.5 + 0.5) ** 6
    base = np.ones((N, N, 3)) * np.array([0.38, 0.4, 0.34])
    alb = base * (0.94 + 0.08 * stripes)[..., None]
    alb = mix(alb, alb * np.array([0.82, 0.8, 0.86]), motif * 0.6)
    damp = np.clip((fbm(2, 6, 0.5, seed) - 0.5) * 3 + (YY - 0.55) * 1.6, 0, 1)
    alb = mix(alb, np.array([0.17, 0.15, 0.09]), damp * 0.6)
    run = streaks(seed + 1, 0.4, 0.5)
    alb = mix(alb, alb * np.array([0.75, 0.68, 0.55]), np.clip(run, 0, 1) * 0.5)
    peel = np.clip((fbm(6, 6, 0.5, seed + 2) - 0.7) * 8, 0, 1)
    alb = mix(alb, np.array([0.55, 0.52, 0.45]), peel)
    save(name, alb, peel * 0.4 + damp * 0.05, 0.8 - damp * 0.2, 2.0)


def shingles(name, base=(0.13, 0.13, 0.14), rows=12, seed=9, cols=7):
    r = np.random.default_rng(seed)
    row = np.floor(YY * rows).astype(int)
    shift = (row % 2) * 0.5 / cols
    within = (YY * rows) % 1.0
    cx = (XX + shift) * cols + (value_noise(16, seed) - 0.5) * 0.15
    col = np.floor(cx).astype(int) % cols
    tint = r.uniform(0.7, 1.15, (rows, cols))[row % rows, col]
    tex = fbm(24, 4, 0.5, seed + 1)
    alb = np.ones((N, N, 3)) * np.array(base) * tint[..., None] * (0.85 + 0.3 * tex)[..., None]
    edge = (np.abs(cx % 1.0 - 0.5) > 0.47) | (within < 0.06)
    lip = np.clip(1 - within * 2.5, 0, 1)
    moss = np.clip((fbm(3, 6, 0.5, seed + 2) - 0.58) * 5, 0, 1) * np.clip(within * 2, 0, 1)
    alb = mix(alb, np.array([0.17, 0.22, 0.11]), moss)
    alb[edge] *= 0.35
    h = within * 0.6 - edge * 0.4 + tex * 0.1 + moss * 0.1
    save(name, alb, h, 0.6 + 0.3 * moss - lip * 0.1, 4.0)


def rope(name, seed=10):
    strands = np.sin((XX * 8 + YY * 24) * np.pi * 2) * 0.5 + 0.5
    fibres = np.sin((XX * 90 + YY * 270 + fbm(16, 3, 0.5, seed) * 6) * np.pi * 2) * 0.5 + 0.5
    t = norm01(strands * 0.65 + fibres * 0.2 + fbm(32, 4, 0.5, seed + 1) * 0.15)
    alb = colorize(t, [(0, (0.025, 0.03, 0.025)), (0.6, (0.09, 0.09, 0.075)), (1, (0.19, 0.18, 0.14))])
    slime = np.clip((fbm(4, 5, 0.5, seed + 2) - 0.48) * 3, 0, 1)
    alb = mix(alb, np.array([0.04, 0.08, 0.07]), slime * 0.5)
    save(name, alb, t, 0.22 + 0.45 * (1 - slime), 5.0)


def sand(name, seed=11):
    ripples = np.sin((YY * 16 + warp(fbm(3, 4, 0.5, seed), 0.1, 3, seed + 1) * 3) * np.pi * 2) * 0.5 + 0.5
    grains = fbm(128, 2, 0.5, seed + 2)
    t = norm01(ripples * 0.45 + grains * 0.35 + fbm(8, 4, 0.5, seed + 3) * 0.2)
    alb = colorize(t, [(0, (0.1, 0.095, 0.08)), (1, (0.26, 0.24, 0.19))])
    shell = (fbm(96, 2, 0.5, seed + 4) > 0.8)
    alb[shell] = alb[shell] * 1.6
    puddle = np.clip((fbm(3, 5, 0.5, seed + 5) - 0.6) * 6, 0, 1)
    alb = mix(alb, alb * 0.6, puddle)
    save(name, alb, t * (1 - puddle) * 0.6, 0.55 - puddle * 0.45 + 0.2 * grains, 2.5)


def bark(name, seed=12):
    fiss = np.zeros((N, N))
    amp = 1.0
    for k, (rx, ry) in enumerate([(12, 2), (24, 4), (48, 8), (96, 12)]):
        fiss += amp * (1 - np.abs(value_noise(rx, seed + k, ry) * 2 - 1))
        amp *= 0.5
    fiss = warp(norm01(fiss), 0.015, 6, seed + 1)
    ridges = fbm(16, 5, 0.5, seed + 2)
    t = norm01(fiss ** 2.2 * 0.8 + ridges * 0.2)
    alb = colorize(t, [(0, (0.03, 0.025, 0.02)), (0.5, (0.12, 0.1, 0.08)), (1, (0.25, 0.22, 0.18))])
    lichen = np.clip((fbm(5, 5, 0.5, seed + 3) - 0.62) * 6, 0, 1) * (t > 0.5)
    alb = mix(alb, np.array([0.36, 0.4, 0.3]), lichen * 0.7)
    save(name, alb, t, 0.8 + 0.15 * (1 - t), 7.0)


def pine(name, seed=13):
    needles = np.zeros((N, N))
    for k in range(4):
        n = value_noise(200, seed + k)
        for s in range(5):
            n = np.maximum(n, np.roll(np.roll(n, 1, 0), 1 if k % 2 else -1, 1) * 0.9)
        needles += n
    needles = norm01(needles)
    clumps = fbm(6, 5, 0.5, seed + 10)
    t = norm01(needles * 0.6 + clumps * 0.4)
    alb = colorize(t, [(0, (0.015, 0.025, 0.02)), (0.5, (0.05, 0.08, 0.055)), (1, (0.13, 0.17, 0.11))])
    save(name, alb, t, 0.75, 4.0)


def skin(name, seed=14):
    """Leathery, wrinkled grey-brown hide with dark veins (the Kell creature)."""
    f1, f2, _ = voronoi(46, seed=seed)
    wrinkles = np.clip((f2 - f1) * 2.0, 0, 1) * 0.5 + 0.5
    fine = ridged(64, 3, seed + 1)
    veins = np.clip(1 - np.abs(warp(fbm(5, 5, 0.5, seed + 2), 0.05, 4, seed + 3) - 0.5) * 30, 0, 1)
    t = norm01(wrinkles * 0.25 + fine * 0.3 + fbm(6, 6, 0.5, seed + 4) * 0.45)
    alb = colorize(t, [(0, (0.035, 0.03, 0.03)), (0.6, (0.11, 0.09, 0.085)), (1, (0.21, 0.17, 0.15))])
    alb = mix(alb, np.array([0.18, 0.05, 0.05]), veins * 0.5)
    blotch = np.clip((fbm(4, 5, 0.5, seed + 5) - 0.55) * 4, 0, 1)
    alb = mix(alb, alb * np.array([1.3, 1.0, 0.95]), blotch * 0.4)
    save(name, alb, t - veins * 0.1, 0.45 + 0.35 * t, 4.0)


def membrane(name, seed=15):
    veins = np.zeros((N, N))
    for k in range(3):
        v = np.clip(1 - np.abs(warp(fbm(3 + k, 5, 0.5, seed + k), 0.06, 3, seed + 10 + k) - 0.5) * 25, 0, 1)
        veins = np.maximum(veins, v)
    thin = fbm(8, 5, 0.5, seed + 20)
    alb = colorize(thin, [(0, (0.09, 0.03, 0.03)), (1, (0.22, 0.09, 0.08))])
    alb = mix(alb, np.array([0.05, 0.015, 0.015]), veins * 0.8)
    save(name, alb, veins * 0.3 + thin * 0.1, 0.4, 3.0, ao=False)


def moss(name, seed=16):
    t = norm01(fbm(16, 6, 0.6, seed) * 0.6 + fbm(64, 3, 0.5, seed + 1) * 0.4)
    alb = colorize(t, [(0, (0.03, 0.05, 0.02)), (0.6, (0.1, 0.16, 0.06)), (1, (0.22, 0.28, 0.12))])
    save(name, alb, t, 0.9, 3.0)


SETS = {
    "wood_planks": lambda: planks("wood_planks", (0.42, 0.39, 0.34), (0.11, 0.09, 0.075), 6, 11),
    "wood_dark": lambda: planks("wood_dark", (0.32, 0.23, 0.16), (0.07, 0.05, 0.035), 8, 21),
    "wood_painted": lambda: planks("wood_painted", (0.4, 0.37, 0.32), (0.1, 0.08, 0.07), 7, 31, paint=(0.55, 0.57, 0.55)),
    "stone_wet": lambda: rock("stone_wet", [(0, (0.025, 0.03, 0.035)), (0.5, (0.1, 0.105, 0.11)), (1, (0.23, 0.24, 0.24))], 31),
    "rock_cave": lambda: rock("rock_cave", [(0, (0.02, 0.022, 0.025)), (0.6, (0.09, 0.088, 0.083)), (1, (0.2, 0.19, 0.17))], 41, strata=0.35, streak=0.8, rough_base=0.4),
    "cliff": lambda: rock("cliff", [(0, (0.05, 0.055, 0.06)), (0.5, (0.16, 0.16, 0.16)), (1, (0.3, 0.3, 0.29))], 51, strata=0.25, rough_base=0.75),
    "concrete": lambda: concrete("concrete", (0.3, 0.3, 0.28), 61),
    "plaster_white": lambda: concrete("plaster_white", (0.58, 0.57, 0.53), 62, formwork=False),
    "metal_rust": lambda: metal("metal_rust", (0.22, 0.24, 0.23), 71),
    "metal_green": lambda: metal("metal_green", (0.17, 0.26, 0.22), 72),
    "metal_red": lambda: metal("metal_red", (0.45, 0.09, 0.07), 73),
    "grass_coastal": lambda: grass("grass_coastal", 81),
    "gravel": lambda: pebbles("gravel", [(0, (0.08, 0.08, 0.08)), (0.5, (0.2, 0.2, 0.19)), (1, (0.36, 0.35, 0.32))], 40, 91),
    "cobble": lambda: pebbles("cobble", [(0, (0.12, 0.12, 0.12)), (1, (0.3, 0.29, 0.27))], 9, 92, sand=(0.08, 0.08, 0.07)),
    "wallpaper": lambda: wallpaper("wallpaper", 101),
    "roof": lambda: shingles("roof", (0.13, 0.13, 0.14), 12, 111),
    "slate": lambda: shingles("slate", (0.09, 0.1, 0.12), 16, 112, cols=9),
    "rope": lambda: rope("rope", 121),
    "sand_wet": lambda: sand("sand_wet", 131),
    "stone_blocks": lambda: ashlar("stone_blocks", (0.24, 0.24, 0.23), 141, 8),
    "whitewash": lambda: ashlar("whitewash", (0.3, 0.3, 0.28), 142, 10, whitewash=(0.78, 0.77, 0.72)),
    "bark": lambda: bark("bark", 151),
    "pine": lambda: pine("pine", 161),
    "skin": lambda: skin("skin", 171),
    "membrane": lambda: membrane("membrane", 181),
    "moss": lambda: moss("moss", 191),
}

if __name__ == "__main__":
    names = sys.argv[1:] or list(SETS)
    for n in names:
        SETS[n]()
