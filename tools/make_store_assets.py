#!/usr/bin/env python3
"""Play Store görselleri: öne çıkan görsel (1024x500) ve uygulama ikonu (512x512).
Ekran görüntüleri CI'da oyunun kendisinden alınır (scripts/dev/screenshots.gd)."""
import os
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CH = os.path.join(ROOT, "assets", "characters", "source_1024")
OUT = os.path.join(ROOT, "store")
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"


def load(cid, h):
    im = Image.open(os.path.join(CH, f"{cid}.png")).convert("RGBA")
    im = im.crop(im.getbbox())
    s = h / im.height
    return im.resize((round(im.width * s), round(im.height * s)), Image.LANCZOS)


def shadow(canvas, im, x, y, blur=10, alpha=0.35):
    a = im.split()[3].point(lambda v: int(v * alpha))
    sh = Image.new("RGBA", im.size, (60, 0, 40, 255)); sh.putalpha(a)
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    layer.alpha_composite(sh, (x, y + 10))
    canvas.alpha_composite(layer.filter(ImageFilter.GaussianBlur(blur)))


def text_outline(d, xy, txt, font, fill, outline, width):
    d.text(xy, txt, font=font, fill=fill, stroke_width=width, stroke_fill=outline)


def feature_graphic():
    W, H = 1024, 500
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    t = np.clip((xx / W) * 0.6 + (yy / H) * 0.4, 0, 1)[..., None]
    c1, c2 = np.array([255, 196, 206]), np.array([214, 60, 118])
    bg = Image.fromarray((c1 * (1 - t) + c2 * t).astype(np.uint8), "RGB").convert("RGBA")
    d = ImageDraw.Draw(bg)
    rng = np.random.default_rng(3)
    for _ in range(18):
        x, y, r = rng.uniform(0, W), rng.uniform(0, H), rng.uniform(6, 26)
        d.ellipse([x - r, y - r, x + r, y + r], outline=(255, 255, 255, 120), width=3)
    # karakterler
    cast = [("pathogen", 170, 955, 30), ("e_faecalis", 250, 905, 230), ("bifidobacterium", 290, 790, 190),
            ("lactobacillus", 300, 665, 180), ("streptococcus", 235, 550, 255)]
    for cid, h, cx, top in cast:
        im = load(cid, h)
        x, y = cx - im.width // 2, top
        shadow(bg, im, x, y)
        bg.alpha_composite(im, (x, y))
    d = ImageDraw.Draw(bg)
    f1 = ImageFont.truetype(FONT, 66)
    f2 = ImageFont.truetype(FONT, 84)
    f3 = ImageFont.truetype(FONT, 30)
    text_outline(d, (40, 70), "Micro-Biome", f1, (255, 255, 255), (106, 31, 176), 9)
    text_outline(d, (40, 150), "Tycoon", f2, (255, 210, 63), (176, 66, 10), 10)
    d.rounded_rectangle([44, 268, 468, 318], radius=24, fill=(255, 255, 255, 235))
    d.text((64, 276), "Build · Balance · Thrive", font=f3, fill=(122, 29, 79))
    bg.convert("RGB").save(os.path.join(OUT, "feature_graphic_1024x500.png"))


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    feature_graphic()
    print("ok")
