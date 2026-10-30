#!/usr/bin/env python3
"""Old sepia photographs for the houses, each with a 'haunted' twin that the
photo shader bleeds through now and then (faces gone hollow, someone extra
standing behind them, sea water rising in the frame).
Run: python3 tools/gen_photos.py   -> assets/textures/photos/<kind>.png, <kind>_h.png
"""
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "textures", "photos")
rng = np.random.default_rng(9)


def canvas(w, h, sky=200, ground=120, horizon=0.55):
    a = np.zeros((h, w), float)
    hz = int(h * horizon)
    a[:hz] = np.linspace(sky, sky - 40, hz)[:, None]
    a[hz:] = np.linspace(ground, ground - 50, h - hz)[:, None]
    return Image.fromarray(a.astype(np.uint8), "L")


def person(d, x, base, s=1.0, shade=55, hat=False, dress=False, child=False):
    s = s * (0.62 if child else 1.0)
    hw, hh = 13 * s, 16 * s
    top = base - 150 * s
    sh = top + 2 * hh + 4 * s
    d.rectangle([x - hw * 0.35, top + hh * 1.6, x + hw * 0.35, sh + 2], fill=shade + 95)        # neck
    d.ellipse([x - hw, top, x + hw, top + 2 * hh], fill=shade + 125)              # face
    d.chord([x - hw * 1.05, top - 3, x + hw * 1.05, top + hh * 0.9], 180, 360, fill=shade - 10)   # hair
    for ex in (-0.38, 0.38):                                                        # eyes, nose, mouth
        d.ellipse([x + ex * hw - hw * 0.14, top + hh * 0.85, x + ex * hw + hw * 0.14, top + hh * 1.05], fill=shade + 30)
    d.line([(x, top + hh * 1.05), (x, top + hh * 1.35)], fill=shade + 80, width=max(1, int(s)))
    d.line([(x - hw * 0.3, top + hh * 1.55), (x + hw * 0.3, top + hh * 1.55)], fill=shade + 50, width=max(1, int(s)))
    if hat:
        d.rectangle([x - hw * 1.5, top - 2, x + hw * 1.5, top + 3], fill=shade - 20)
        d.rectangle([x - hw * 0.9, top - 14 * s, x + hw * 0.9, top], fill=shade - 20)
    d.ellipse([x - 26 * s, sh - 4 * s, x + 26 * s, sh + 22 * s], fill=shade + (10 if dress else 0))   # shoulders
    if dress:
        d.polygon([(x - 18 * s, sh), (x + 18 * s, sh), (x + 34 * s, base), (x - 34 * s, base)], fill=shade + 10)
    else:
        d.polygon([(x - 26 * s, sh + 8 * s), (x + 26 * s, sh + 8 * s), (x + 20 * s, base - 55 * s), (x - 20 * s, base - 55 * s)], fill=shade)
        d.polygon([(x - 6 * s, sh + 2 * s), (x + 6 * s, sh + 2 * s), (x, sh + 30 * s)], fill=shade + 110)   # shirt collar
        d.rectangle([x - 18 * s, base - 55 * s, x - 3 * s, base], fill=shade - 15)
        d.rectangle([x + 3 * s, base - 55 * s, x + 18 * s, base], fill=shade - 15)
    return (x, top + hh, hw)


def hollow(d, face, deep=False):
    x, y, r = face
    d.ellipse([x - r, y - r * 1.05, x + r, y + r * 1.05], fill=30 if deep else 70)
    for ex in (-0.4, 0.4):
        d.ellipse([x + ex * r - r * 0.22, y - r * 0.25, x + ex * r + r * 0.22, y + r * 0.15], fill=5)
    d.ellipse([x - r * 0.25, y + r * 0.35, x + r * 0.25, y + r * 0.75], fill=8)


def tall_figure(d, x, base, h):
    d.polygon([(x - 16, base - h + 30), (x + 16, base - h + 30), (x + 26, base), (x - 26, base)], fill=22)
    d.ellipse([x - 13, base - h, x + 13, base - h + 34], fill=18)
    for k in range(6):                                                              # dripping rope
        xx = x - 20 + k * 8
        d.line([(xx, base - h * 0.6), (xx + rng.integers(-4, 5), base)], fill=12, width=2)


def age(img, water=False):
    a = np.asarray(img, float)
    h, w = a.shape
    if water:
        line = int(h * 0.62)
        a[line:] = a[line:] * 0.45 + 30
        a[line - 3:line + 2] += 25
    a = a + rng.normal(0, 9, a.shape)
    yy, xx = np.mgrid[0:h, 0:w]
    v = ((xx - w / 2) / (w / 2)) ** 2 + ((yy - h / 2) / (h / 2)) ** 2
    a = a * (1.0 - 0.45 * np.clip(v, 0, 1.3))
    for _ in range(5):                                                              # scratches
        x0 = rng.integers(0, w)
        y0 = rng.integers(0, h // 2)
        a[y0:y0 + rng.integers(h // 4, h), max(x0 - 1, 0):x0] += rng.uniform(10, 30)
    for _ in range(40):                                                             # dust
        y0, x0 = rng.integers(0, h), rng.integers(0, w)
        a[max(y0 - 1, 0):y0 + 1, max(x0 - 1, 0):x0 + 1] = rng.choice([10, 235])
    a = np.clip(a, 0, 255)
    img = Image.fromarray(a.astype(np.uint8), "L").filter(ImageFilter.GaussianBlur(0.9))
    a = np.asarray(img, float) / 255.0
    rgb = np.stack([a * 1.0 + 0.04, a * 0.86 + 0.02, a * 0.66], -1)                # sepia
    return Image.fromarray((np.clip(rgb, 0, 1) * 255).astype(np.uint8), "RGB")


def scene(kind, haunted):
    if kind == "family":            # three on the slipway, the sea behind
        img = canvas(320, 240, 205, 140, 0.5)
        d = ImageDraw.Draw(img)
        d.rectangle([0, 120, 320, 160], fill=150)
        faces = [person(d, 100, 225, 0.95, hat=True), person(d, 160, 225, 0.9, dress=True), person(d, 210, 225, child=True, shade=60)]
        if haunted:
            for f in faces:
                hollow(d, f)
            tall_figure(d, 262, 225, 205)
        return img, haunted
    if kind == "portrait":          # Ines Halloran
        img = canvas(240, 300, 150, 150, 1.0)
        d = ImageDraw.Draw(img)
        f = person(d, 120, 330, 1.6, dress=True, shade=50)
        if haunted:
            hollow(d, f, True)
        return img, haunted
    if kind == "child":             # Nell
        img = canvas(240, 300, 170, 170, 1.0)
        d = ImageDraw.Draw(img)
        f = person(d, 120, 320, 2.5, dress=True, child=True, shade=60)
        if haunted:
            hollow(d, f)
            d.rectangle([0, 250, 240, 300], fill=40)
        return img, haunted
    if kind == "crew":              # the Pelagic team in front of the light
        img = canvas(320, 240, 190, 120, 0.62)
        d = ImageDraw.Draw(img)
        d.rectangle([150, 20, 172, 150], fill=215)
        d.polygon([(146, 20), (176, 20), (161, 6)], fill=90)
        faces = [person(d, 40 + i * 48, 228, 0.8, hat=(i % 2 == 0), shade=50 + i * 3) for i in range(6)]
        for i, f in enumerate(faces):
            if haunted or i != 4:
                x, y, r = f
                d.line([(x - r, y - r), (x + r, y + r)], fill=230, width=3)        # scratched out
                d.line([(x + r, y - r), (x - r, y + r)], fill=230, width=3)
        return img, False
    if kind == "lighthouse":
        img = canvas(320, 240, 185, 95, 0.66)
        d = ImageDraw.Draw(img)
        d.polygon([(140, 40), (180, 40), (188, 160), (132, 160)], fill=220)
        d.rectangle([146, 24, 174, 40], fill=60)
        d.polygon([(0, 160), (320, 160), (320, 240), (0, 240)], fill=80)
        if haunted:
            d.polygon([(174, 32), (320, 10), (320, 54)], fill=240)                # the beam, turned on you
            for i in range(9):
                person(d, 30 + i * 33, 205 + (i % 2) * 6, 0.35, shade=20)        # people on the shore, facing it
        return img, haunted
    if kind == "couple":            # a wedding on the church steps
        img = canvas(240, 300, 165, 120, 0.7)
        d = ImageDraw.Draw(img)
        d.rectangle([0, 210, 240, 300], fill=130)
        f1 = person(d, 90, 290, 1.25, hat=True, shade=45)
        f2 = person(d, 150, 290, 1.2, dress=True, shade=90)
        if haunted:
            hollow(d, f1)
            hollow(d, f2)
        return img, haunted
    raise ValueError(kind)


def main():
    os.makedirs(OUT, exist_ok=True)
    for kind in ["family", "portrait", "child", "crew", "lighthouse", "couple"]:
        for haunted in (False, True):
            img, water = scene(kind, haunted)
            age(img, water=water and kind in ("family", "child")).save(os.path.join(OUT, kind + ("_h" if haunted else "") + ".png"))
            print("photo", kind, haunted)


if __name__ == "__main__":
    main()
