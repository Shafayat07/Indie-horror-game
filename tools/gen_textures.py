#!/usr/bin/env python3
"""Generates the original, tileable PBR texture sets used by THE TIDE REMEMBERS.

Every texture is procedural (numpy noise), so there are no third-party licensing
concerns. Each material gets an albedo, a normal map and a roughness map.
Run:  python3 tools/gen_textures.py
"""
import os
import numpy as np
from PIL import Image

N = 512
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "textures")
rng = np.random.default_rng(1337)


def periodic_noise(res, size=N, seed=None):
    """Tileable value noise with smooth (cosine) interpolation."""
    r = np.random.default_rng(seed) if seed is not None else rng
    grid = r.random((res, res))
    t = np.arange(size) * res / size
    i0 = np.floor(t).astype(int)
    f = t - i0
    f = (1 - np.cos(f * np.pi)) * 0.5
    i1 = (i0 + 1) % res
    a = grid[np.ix_(i0, i0)]
    b = grid[np.ix_(i0, i1)]
    c = grid[np.ix_(i1, i0)]
    d = grid[np.ix_(i1, i1)]
    fx = f[None, :]
    fy = f[:, None]
    top = a * (1 - fx) + b * fx
    bot = c * (1 - fx) + d * fx
    return top * (1 - fy) + bot * fy


def fbm(base=4, octaves=6, gain=0.5, seed=None):
    r = np.random.default_rng(seed)
    out = np.zeros((N, N))
    amp, total = 1.0, 0.0
    res = base
    for _ in range(octaves):
        if res > N:
            break
        out += amp * periodic_noise(res, seed=int(r.integers(1 << 30)))
        total += amp
        amp *= gain
        res *= 2
    return out / total


def norm01(a):
    a = a - a.min()
    return a / max(a.max(), 1e-6)


def colorize(t, stops):
    """Map 0..1 field onto a list of (pos, (r,g,b)) colour stops."""
    pos = np.array([s[0] for s in stops])
    cols = np.array([s[1] for s in stops], dtype=float)
    out = np.zeros(t.shape + (3,))
    for ch in range(3):
        out[..., ch] = np.interp(t, pos, cols[:, ch])
    return out


def normal_from_height(h, strength=4.0):
    dx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * strength
    dy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * strength
    nz = np.ones_like(h)
    n = np.stack([-dx, dy, nz], -1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    return (n * 0.5 + 0.5)


def save(name, albedo, height, rough, nstrength=4.0):
    rough = np.broadcast_to(np.asarray(rough, dtype=float), height.shape)
    os.makedirs(OUT, exist_ok=True)
    Image.fromarray((np.clip(albedo, 0, 1) * 255).astype(np.uint8)).save(f"{OUT}/{name}_albedo.png")
    Image.fromarray((normal_from_height(height, nstrength) * 255).astype(np.uint8)).save(f"{OUT}/{name}_normal.png")
    Image.fromarray((np.clip(rough, 0, 1) * 255).astype(np.uint8), "L").save(f"{OUT}/{name}_rough.png")
    print("wrote", name)


yy, xx = np.mgrid[0:N, 0:N] / N


def planks(name, base_cols, boards=6, seed=1):
    r = np.random.default_rng(seed)
    board = np.floor(yy * boards).astype(int) % boards
    offsets = r.random(boards)
    tint = r.uniform(0.75, 1.15, boards)
    grain = periodic_noise(4, seed=seed) * 0.5 + fbm(8, 5, seed=seed + 1) * 0.5
    stretch = np.zeros((N, N))
    for b in range(boards):
        rows = board == b
        g = np.roll(fbm(2, 6, seed=seed + 10 + b), int(offsets[b] * N), 1)
        stretch[rows] = g[rows]
    # Long grain: sample noise stretched along x by using row-dominant waves
    lines = np.sin((yy * boards * 18 + stretch * 6) * np.pi * 2) * 0.5 + 0.5
    t = norm01(lines * 0.35 + stretch * 0.65)
    alb = colorize(t, base_cols)
    alb *= tint[board][..., None]
    # Seams between boards and a few cross butt-joints
    seam = np.abs((yy * boards) % 1.0 - 0.5) > 0.47
    butt = (np.abs(((xx + offsets[board]) * 1) % 1.0 - 0.5) > 0.497)
    gaps = seam | butt
    alb[gaps] *= 0.25
    wet = fbm(2, 4, seed=seed + 99)
    alb *= (0.8 + 0.25 * wet)[..., None]
    height = t * 0.3 - gaps * 1.0
    rough = 0.55 + 0.35 * (1 - wet) - gaps * 0.2
    save(name, alb, height, rough, 3.0)


def rock(name, stops, seed=2, cracks=True, rough_base=0.6, streaks=0.0):
    h = fbm(4, 7, 0.55, seed=seed)
    ridged = 1 - np.abs(fbm(6, 6, 0.5, seed=seed + 3) * 2 - 1)
    t = norm01(h * 0.6 + ridged * 0.4)
    alb = colorize(t, stops)
    if streaks > 0:
        s = fbm(3, 5, seed=seed + 7)
        mineral = np.clip((np.sin((xx * 3 + s * 2.5) * np.pi * 2) - 0.85) * 6, 0, 1) * streaks
        alb = alb * (1 - mineral[..., None]) + np.array([0.2, 0.26, 0.24]) * mineral[..., None]
    if cracks:
        c = np.abs(fbm(8, 4, seed=seed + 5) - 0.5) < 0.012
        alb[c] *= 0.35
        t = t - c * 0.3
    wet = fbm(2, 4, seed=seed + 9)
    rough = rough_base + 0.3 * wet - 0.25 * (1 - t)
    save(name, alb, t, rough, 6.0)


def concrete(name, stops, seed=3, stains=True):
    h = fbm(16, 6, 0.45, seed=seed) * 0.7 + fbm(4, 3, seed=seed + 1) * 0.3
    t = norm01(h)
    alb = colorize(t, stops)
    if stains:
        drip = fbm(3, 5, seed=seed + 2)
        streak = periodic_noise(32, seed=seed + 4)
        streak = np.repeat(streak[:1, :], N, 0) * (1 - yy) ** 0.5
        stain = np.clip(drip * 0.6 + streak * 0.5 - 0.35, 0, 1)
        alb *= (1 - 0.45 * stain)[..., None]
    pores = (fbm(64, 2, seed=seed + 3) > 0.78)
    alb[pores] *= 0.7
    rough = 0.75 + 0.2 * t
    save(name, alb, t - pores * 0.2, rough, 2.0)


def metal(name, paint, seed=4):
    rust_n = fbm(4, 7, 0.55, seed=seed)
    rust = np.clip((rust_n - 0.56) * 3, 0, 1) * 0.85
    rcol = colorize(fbm(16, 5, seed=seed + 1), [(0, (0.18, 0.08, 0.04)), (0.5, (0.3, 0.17, 0.09)), (1, (0.4, 0.26, 0.15))])
    pcol = np.ones((N, N, 3)) * np.array(paint) * (0.85 + 0.15 * fbm(8, 4, seed=seed + 2))[..., None]
    alb = pcol * (1 - rust[..., None]) + rcol * rust[..., None]
    # Rivet rows/panel seams
    seam = (np.abs((xx * 2) % 1.0 - 0.5) > 0.495) | (np.abs((yy * 2) % 1.0 - 0.5) > 0.495)
    alb[seam] *= 0.4
    h = rust * 0.4 + fbm(32, 3, seed=seed + 3) * 0.1 - seam * 0.5
    rough = 0.45 + rust * 0.5
    save(name, alb, h, rough, 3.0)


def grass(name, seed=5):
    base = fbm(8, 6, seed=seed)
    blades = periodic_noise(128, seed=seed + 1) * 0.5 + periodic_noise(64, seed=seed + 2) * 0.5
    t = norm01(base * 0.5 + blades * 0.5)
    alb = colorize(t, [(0, (0.08, 0.1, 0.07)), (0.4, (0.17, 0.21, 0.14)), (0.7, (0.25, 0.28, 0.18)), (1, (0.36, 0.36, 0.26))])
    dirt = np.clip((fbm(3, 5, seed=seed + 3) - 0.55) * 4, 0, 1)
    alb = alb * (1 - dirt[..., None]) + np.array([0.17, 0.14, 0.11]) * dirt[..., None]
    save(name, alb, t, 0.85 - 0.2 * t, 3.0)


def gravel(name, seed=6):
    cells = periodic_noise(48, seed=seed)
    pebbles = norm01(np.abs(np.sin(cells * 30)))
    t = norm01(pebbles * 0.5 + fbm(16, 4, seed=seed + 1) * 0.5)
    alb = colorize(t, [(0, (0.06, 0.06, 0.06)), (0.5, (0.17, 0.17, 0.16)), (1, (0.33, 0.32, 0.29))])
    save(name, alb, t, 0.35 + 0.4 * t, 5.0)


def wallpaper(name, seed=7):
    stripes = (np.sin(xx * np.pi * 2 * 12) * 0.5 + 0.5) ** 4
    flowers = (np.sin(xx * np.pi * 2 * 24) * np.sin(yy * np.pi * 2 * 16)) > 0.85
    base = np.array([0.36, 0.38, 0.33]) * np.ones((N, N, 3))
    alb = base * (0.9 + 0.12 * stripes)[..., None]
    alb[flowers] *= 0.82
    damp = np.clip((fbm(2, 6, seed=seed) - 0.5) * 3 + (yy - 0.5) * 1.5, 0, 1)
    alb = alb * (1 - 0.6 * damp[..., None]) + np.array([0.18, 0.16, 0.1]) * 0.6 * damp[..., None]
    peel = np.clip((fbm(6, 5, seed=seed + 1) - 0.68) * 8, 0, 1)
    alb = alb * (1 - peel[..., None]) + np.array([0.5, 0.48, 0.42]) * peel[..., None]
    save(name, alb, peel * 0.5 + damp * 0.1, 0.8 - damp * 0.2, 2.0)


def shingles(name, seed=8):
    rows = 10
    row = np.floor(yy * rows)
    shift = (row % 2) * 0.5 / 6
    col = np.floor((xx + shift) * 6)
    r = np.random.default_rng(seed)
    tint = r.uniform(0.7, 1.1, (rows, 7))[row.astype(int) % rows, col.astype(int) % 7]
    within = (yy * rows) % 1.0
    t = norm01(within * 0.7 + fbm(16, 4, seed=seed) * 0.3)
    alb = colorize(t, [(0, (0.05, 0.05, 0.06)), (1, (0.2, 0.2, 0.21))]) * tint[..., None]
    edge = (np.abs(((xx + shift) * 6) % 1.0 - 0.5) > 0.47) | (within < 0.05)
    alb[edge] *= 0.4
    moss = np.clip((fbm(3, 5, seed=seed + 1) - 0.6) * 5, 0, 1)
    alb = alb * (1 - moss[..., None]) + np.array([0.15, 0.2, 0.1]) * moss[..., None]
    save(name, alb, t - edge * 0.4, 0.7, 4.0)


def rope(name, seed=9):
    strands = np.sin((xx * 8 + yy * 24) * np.pi * 2) * 0.5 + 0.5
    fib = fbm(32, 4, seed=seed)
    t = norm01(strands * 0.7 + fib * 0.3)
    alb = colorize(t, [(0, (0.03, 0.035, 0.03)), (0.6, (0.1, 0.1, 0.085)), (1, (0.2, 0.19, 0.15))])
    slime = np.clip((fbm(4, 5, seed=seed + 1) - 0.5) * 3, 0, 1)
    alb = alb * (1 - 0.5 * slime[..., None]) + np.array([0.05, 0.09, 0.08]) * 0.5 * slime[..., None]
    save(name, alb, t, 0.25 + 0.4 * (1 - slime), 5.0)


def sand(name, seed=10):
    ripples = np.sin((yy * 14 + fbm(3, 4, seed=seed) * 2) * np.pi * 2) * 0.5 + 0.5
    t = norm01(ripples * 0.4 + fbm(32, 4, seed=seed + 1) * 0.6)
    alb = colorize(t, [(0, (0.12, 0.11, 0.09)), (1, (0.27, 0.25, 0.2))])
    save(name, alb, t, 0.3 + 0.3 * t, 2.5)


if __name__ == "__main__":
    planks("wood_planks", [(0, (0.12, 0.1, 0.08)), (0.5, (0.27, 0.24, 0.2)), (1, (0.4, 0.37, 0.32))], 6, 11)
    planks("wood_dark", [(0, (0.06, 0.04, 0.03)), (0.5, (0.15, 0.1, 0.07)), (1, (0.24, 0.17, 0.12))], 8, 21)
    rock("stone_wet", [(0, (0.03, 0.035, 0.04)), (0.5, (0.11, 0.115, 0.12)), (1, (0.24, 0.25, 0.25))], 31)
    rock("rock_cave", [(0, (0.02, 0.025, 0.028)), (0.6, (0.09, 0.09, 0.085)), (1, (0.2, 0.19, 0.17))], 41, streaks=0.8, rough_base=0.4)
    rock("cliff", [(0, (0.06, 0.065, 0.07)), (0.5, (0.17, 0.17, 0.17)), (1, (0.3, 0.3, 0.29))], 51, rough_base=0.75)
    concrete("concrete", [(0, (0.17, 0.17, 0.16)), (1, (0.36, 0.36, 0.34))], 61)
    concrete("plaster_white", [(0, (0.45, 0.45, 0.42)), (1, (0.62, 0.61, 0.57))], 62)
    metal("metal_rust", (0.22, 0.24, 0.23), 71)
    metal("metal_green", (0.17, 0.25, 0.22), 72)
    metal("metal_red", (0.42, 0.09, 0.07), 73)
    grass("grass_coastal", 81)
    gravel("gravel", 91)
    wallpaper("wallpaper", 101)
    shingles("roof", 111)
    rope("rope", 121)
    sand("sand_wet", 131)
