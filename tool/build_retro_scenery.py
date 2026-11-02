"""Build optional procedural scenery previews without replacing game art.

Requires Pillow. Run: python tool/build_retro_scenery.py
The game scales these images with nearest-neighbor filtering.
"""

from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1] / "assets" / "images" / "terrain" / "generated"
ROOT.mkdir(parents=True, exist_ok=True)
RNG = random.Random(1993)


def battlefield() -> None:
    image = Image.new("RGB", (500, 310), "#253a23")
    draw = ImageDraw.Draw(image)
    grass = ["#293d27", "#30472a", "#354b2b", "#3b502d", "#405330"]
    for y in range(0, 310, 4):
        for x in range(0, 500, 4):
            draw.rectangle((x, y, x + 3, y + 3), fill=RNG.choice(grass))
            if RNG.random() < 0.29:
                draw.point((x + RNG.randrange(4), y + RNG.randrange(4)), fill="#4b5c32")

    # Irregular earth road. Its broad center keeps unit sprites readable.
    for x in range(500):
        center = 155 + round(3 * math.sin(x / 36))
        width = 37 + (x // 29 % 3) * 2 + RNG.randrange(-2, 3)
        draw.line((x, center - width - 3, x, center + width + 3), fill="#293b24")
        draw.line((x, center - width, x, center + width), fill=RNG.choice(["#695334", "#715a39", "#765f3d"]))
    for _ in range(5300):
        x = RNG.randrange(500)
        y = RNG.randrange(112, 200)
        if abs(y - (155 + round(3 * math.sin(x / 36)))) < 36:
            tone = RNG.choice(["#806843", "#8d734a", "#5e4a31", "#9a7b50", "#4f412e"])
            draw.rectangle((x, y, x + RNG.randrange(1, 4), y + RNG.randrange(1, 3)), fill=tone)

    # Stone foundations under the two keeps.
    for cx in (50, 450):
        draw.ellipse((cx - 44, 121, cx + 44, 189), fill="#342f2b")
        draw.ellipse((cx - 39, 125, cx + 39, 185), fill="#77705d")
        for _ in range(120):
            x = cx + RNG.randrange(-37, 38)
            y = 155 + RNG.randrange(-29, 30)
            if ((x - cx) / 39) ** 2 + ((y - 155) / 30) ** 2 < 1:
                draw.rectangle((x, y, x + 4, y + 2), fill=RNG.choice(["#8d826b", "#59594c", "#a09579"]))

    # Grass, flowers, rocks, and dead branches stay away from the road.
    for _ in range(750):
        x = RNG.randrange(8, 492)
        y = RNG.randrange(18, 293)
        if 105 < y < 205:
            continue
        tone = RNG.choice(["#5f7136", "#6d7b3e", "#8a844c", "#496532"])
        draw.line((x, y, x - 1, y - 3), fill=tone)
        draw.line((x, y, x + 1, y - 2), fill=tone)
    for _ in range(44):
        x = RNG.randrange(18, 482)
        y = RNG.choice([RNG.randrange(23, 102), RNG.randrange(208, 290)])
        draw.ellipse((x - 5, y - 2, x + 6, y + 3), fill="#1e2e1e")
        draw.polygon([(x - 5, y), (x - 1, y - 4), (x + 5, y - 3), (x + 7, y + 1)], fill="#666c57")
        draw.line((x - 3, y - 2, x + 3, y - 3), fill="#898771")

    # Dense tree line at the top and bottom makes a framed, old RTS map.
    for row, y in enumerate((-9, 3, 300, 316)):
        for x in range(-12 + row * 11, 520, 30):
            tx = x + RNG.randrange(-5, 6)
            ty = y + RNG.randrange(-5, 6)
            tree(draw, tx, ty, RNG.randrange(0, 3))
    for x, y in [(15, 50), (486, 56), (17, 257), (483, 249)]:
        tree(draw, x, y, 1)

    # Cracked stone slabs and signal braziers near the strongholds.
    for cx in (50, 450):
        for sy in (104, 205):
            draw.rectangle((cx - 7, sy, cx + 7, sy + 4), fill="#181c1a")
            draw.rectangle((cx - 5, sy - 10, cx + 5, sy), fill="#555950")
            draw.rectangle((cx - 2, sy - 13, cx + 2, sy - 6), fill="#d47332")
            draw.point((cx, sy - 15), fill="#f5bf61")
    # A candidate 360 × 180 canvas. The active battlefield.png is user art.
    image.resize((360, 180), Image.Resampling.NEAREST).save(ROOT / "battlefield.png")


def tree(draw: ImageDraw.ImageDraw, x: int, y: int, variant: int) -> None:
    draw.ellipse((x - 13, y + 7, x + 14, y + 14), fill="#1c2b1c")
    draw.rectangle((x - 3, y - 3, x + 3, y + 10), fill="#34291d")
    draw.rectangle((x - 1, y, x + 1, y + 7), fill="#665033")
    canopy = ["#1e3623", "#29452a", "#2d4b2d"][variant]
    draw.ellipse((x - 12, y - 14, x + 12, y + 7), fill="#15291d")
    draw.ellipse((x - 10, y - 15, x + 9, y + 2), fill=canopy)
    draw.ellipse((x - 5, y - 13, x + 8, y - 3), fill="#3b5b32")
    for dx, dy in [(-6, -7), (2, -11), (8, -2), (-3, 0)]:
        draw.rectangle((x + dx, y + dy, x + dx + 2, y + dy + 1), fill="#55703b")


def keep(name: str, accent: str, roof: str) -> None:
    image = Image.new("RGBA", (74, 88), (0, 0, 0, 0))
    d = ImageDraw.Draw(image)
    d.ellipse((5, 73, 69, 86), fill="#111714aa")
    d.rectangle((12, 28, 62, 78), fill="#191c1a")
    d.rectangle((15, 32, 59, 76), fill="#646359")
    # Mortar bands and uneven stone blocks.
    for y in range(36, 75, 8):
        d.line((15, y, 59, y), fill="#393c38", width=2)
        for x in range(20 + (y % 3) * 4, 57, 13):
            d.line((x, y, x, y + 6), fill="#444740", width=2)
    d.rectangle((13, 29, 61, 35), fill="#888778")
    d.polygon([(10, 29), (37, 8), (64, 29)], fill=roof)
    d.line((10, 29, 37, 8, 64, 29), fill="#1b1b1b", width=3)
    for x in (5, 55):
        d.rectangle((x, 18, x + 14, 77), fill="#252724")
        d.rectangle((x + 2, 20, x + 12, 75), fill="#77786b")
        for y in (27, 42, 56):
            d.line((x + 2, y, x + 12, y), fill="#434841", width=2)
        d.rectangle((x - 1, 16, x + 16, 22), fill="#a39a7e")
        for bx in (x - 1, x + 6, x + 13):
            d.rectangle((bx, 11, bx + 4, 17), fill="#aaa084")
        d.rectangle((x + 5, 27, x + 9, 38), fill="#191d1e")
        d.rectangle((x + 6, 28, x + 8, 34), fill="#c89955")
    d.rectangle((28, 54, 46, 78), fill="#171917")
    d.pieslice((28, 48, 46, 65), 180, 360, fill="#171917")
    for x in range(31, 46, 4):
        d.line((x, 55, x, 78), fill="#574e3c")
    d.rectangle((34, 66, 36, 70), fill="#d7ba68")
    # Faction banner and crest.
    d.line((37, 2, 37, 34), fill="#c9b88b", width=2)
    d.polygon([(38, 3), (55, 7), (52, 22), (38, 19)], fill=accent)
    d.rectangle((42, 9, 47, 12), fill="#e2c777")
    d.rectangle((44, 12, 46, 17), fill="#e2c777")
    d.rectangle((25, 39, 49, 51), fill="#272823")
    d.rectangle((27, 40, 47, 49), fill=accent)
    d.rectangle((34, 42, 40, 47), fill="#dec580")
    image.save(ROOT / f"keep_{name}.png")


if __name__ == "__main__":
    battlefield()
    keep("heretic", "#a95434", "#47372d")
    keep("hexen", "#466c9e", "#303b55")
    print(f"Built retro scenery in {ROOT}")
