#!/usr/bin/env python3
"""UI ikonları, grid karoları, çevre ve efekt parçalarını referans sayfadan
(art_source/full_asset_reference_08.png) gerçek alfa kanallı ayrı PNG olarak çıkarır.
Ayrıca prosedürel arka plan, uygulama ikonu ve mağaza görsellerini üretir.
Kullanım: python3 tools/make_ui_assets.py
"""
from __future__ import annotations
import os, sys, math, json
import numpy as np, cv2
from PIL import Image, ImageDraw, ImageFilter
from scipy import ndimage as ndi

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))
from segment import grad  # noqa: E402

SHEET = os.path.join(ROOT, "art_source", "full_asset_reference_08.png")

# ad: (klasör, kutu x0,y0,x1,y1, hedef boyut, eşik)
ITEMS = {
    # UI ikonları
    "coin": ("ui", (1084, 272, 1156, 342), 128, 30),
    "gem": ("ui", (1160, 272, 1230, 342), 128, 30),
    "heart": ("ui", (1232, 272, 1302, 342), 128, 30),
    "gear": ("ui", (1305, 272, 1372, 342), 128, 30),
    "trophy": ("ui", (1376, 270, 1449, 342), 128, 30),
    "star": ("ui", (1447, 270, 1521, 342), 128, 30),
    "shield_badge": ("ui", (1081, 341, 1151, 412), 128, 30),
    "alert": ("ui", (1157, 341, 1227, 412), 128, 30),
    "check": ("ui", (1231, 341, 1301, 412), 128, 30),
    "pause": ("ui", (1305, 341, 1375, 412), 128, 30),
    "play": ("ui", (1379, 341, 1449, 412), 128, 30),
    "info": ("ui", (1450, 341, 1520, 412), 128, 30),
    "fiber": ("ui", (64, 276, 160, 360), 128, 30),
    "glucose": ("ui", (190, 276, 290, 362), 128, 55),
    "prebiotic": ("ui", (315, 276, 420, 360), 128, 30),
    "nutrient_drop": ("ui", (495, 278, 580, 362), 128, 55),
    "growth_boost": ("ui", (604, 278, 695, 360), 128, 30),
    "shield": ("ui", (714, 274, 806, 364), 128, 30),
    "healing": ("ui", (820, 280, 905, 360), 128, 30),
    "energy": ("ui", (930, 274, 1014, 364), 128, 30),
    "gift": ("ui", (896, 646, 1020, 736), 192, 45),
    "gut": ("ui", (1135, 650, 1255, 742), 192, 30),
    "crown": ("ui", (1128, 900, 1226, 990), 160, 40),
    "dna": ("ui", (1368, 895, 1420, 995), 128, 30),
    # karolar
    "tile_pink": ("environment", (30, 450, 135, 556), 160, 26),
    "tile_green": ("environment", (140, 450, 245, 556), 160, 26),
    "tile_orange": ("environment", (250, 450, 355, 556), 160, 26),
    "tile_purple": ("environment", (360, 450, 465, 556), 160, 26),
    "tile_blue": ("environment", (470, 450, 575, 556), 160, 26),
    "tile_block": ("environment", (594, 452, 686, 534), 160, 26),
    "tile_boost": ("environment", (694, 452, 786, 534), 160, 26),
    "tile_heal": ("environment", (792, 452, 884, 534), 160, 26),
    "tile_danger": ("environment", (891, 452, 983, 534), 160, 26),
    # çevre parçaları
    "coral_pink": ("environment", (1010, 455, 1160, 560), 256, 26),
    "tubes_green": ("environment", (1160, 455, 1285, 560), 256, 26),
    "coral_purple": ("environment", (1280, 445, 1392, 560), 256, 26),
    "plants": ("environment", (855, 890, 1005, 1010), 256, 26),
    # efektler
    "bubble": ("vfx", (1383, 615, 1430, 666), 96, 30),
}


def extract(img, box, T, size):
    x0, y0, x1, y1 = box
    pad = 6
    c = img[y0 - pad:y1 + pad, x0 - pad:x1 + pad]
    G = grad(c, 0.8)
    E = cv2.dilate((G > T).astype(np.uint8), np.ones((3, 3), np.uint8), iterations=1) > 0
    lab, n = ndi.label(~E)
    border = set(np.unique(np.r_[lab[0], lab[-1], lab[:, 0], lab[:, -1]])) - {0}
    bg = np.isin(lab, list(border))
    bg = (cv2.dilate(bg.astype(np.uint8), np.ones((3, 3), np.uint8)) > 0) & ~(G > T)
    fg = ~bg
    fg = cv2.morphologyEx(fg.astype(np.uint8), cv2.MORPH_OPEN, np.ones((3, 3), np.uint8)) > 0
    lab, n = ndi.label(fg)
    if n > 1:
        sz = ndi.sum(fg, lab, range(1, n + 1))
        keep = np.zeros_like(fg)
        big = sz.max()
        for i, s in enumerate(sz):  # ana parça + ona yakın büyüklükteki parçalar (ör. kabarcık grubu)
            if s >= big * 0.18:
                keep |= lab == i + 1
        fg = keep
    fg = ndi.binary_fill_holes(fg)
    a = np.clip(cv2.GaussianBlur(cv2.erode(fg.astype(np.float32), np.ones((2, 2), np.uint8)), (0, 0), 0.6), 0, 1)
    rgb = cv2.cvtColor(c, cv2.COLOR_BGR2RGB)
    rgba = np.dstack([rgb, (a * 255).astype(np.uint8)])
    rgba[rgba[:, :, 3] == 0, :3] = 0
    im = Image.fromarray(rgba, "RGBA")
    bb = im.getbbox()
    im = im.crop(bb)
    s = 0.9 * size / max(im.size)
    im = im.resize((max(1, round(im.width * s)), max(1, round(im.height * s))), Image.LANCZOS)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.alpha_composite(im, ((size - im.width) // 2, (size - im.height) // 2))
    return out


# ---------- prosedürel arka plan ----------
def gut_background(w, h, dark: bool, seed=7):
    rng = np.random.default_rng(seed)
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    if dark:
        top, bot = np.array([46, 14, 38]), np.array([18, 8, 26])
        blob_cols = [(120, 30, 70), (90, 24, 90), (140, 40, 60)]
    else:
        top, bot = np.array([255, 170, 160]), np.array([236, 104, 118])
        blob_cols = [(255, 200, 190), (250, 140, 150), (255, 220, 210)]
    t = (yy / h)[..., None]
    img = top * (1 - t) + bot * t
    canvas = Image.fromarray(img.astype(np.uint8), "RGB").convert("RGBA")
    layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    # bağırsak kıvrımları (villus): yan yana yumuşak tümsekler
    for row in range(9):
        y = h * (0.05 + row * 0.12) + rng.uniform(-20, 20)
        col = blob_cols[row % 3]
        x = -40.0
        while x < w + 40:
            r = rng.uniform(55, 95)
            d.ellipse([x - r, y - r * 0.8, x + r, y + r * 0.8], fill=col + (60,))
            x += r * 1.3
    layer = layer.filter(ImageFilter.GaussianBlur(18))
    canvas.alpha_composite(layer)
    # parlak kabarcıklar
    hl = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(hl)
    for _ in range(26):
        x, y, r = rng.uniform(0, w), rng.uniform(0, h), rng.uniform(5, 22)
        a = 70 if dark else 110
        d.ellipse([x - r, y - r, x + r, y + r], outline=(255, 255, 255, a), width=2)
        d.ellipse([x - r * .45, y - r * .55, x - r * .05, y - r * .15], fill=(255, 255, 255, a))
    hl = hl.filter(ImageFilter.GaussianBlur(1.2))
    canvas.alpha_composite(hl)
    # kenar vinyeti
    v = np.clip(((xx - w / 2) / (w / 2)) ** 2 + ((yy - h / 2) / (h / 1.6)) ** 2, 0, 1)
    vig = Image.fromarray((v * (120 if dark else 70)).astype(np.uint8), "L")
    black = Image.new("RGBA", (w, h), (20, 0, 10, 255)); black.putalpha(vig)
    canvas.alpha_composite(black)
    return canvas.convert("RGB")


def app_icon(char_path, size, bg=True, safe=1.0):
    spr = Image.open(char_path).convert("RGBA")
    spr = spr.crop(spr.getbbox())
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    if bg:
        out = icon_background(size)
    s = safe * 0.78 * size / max(spr.size)
    spr = spr.resize((round(spr.width * s), round(spr.height * s)), Image.LANCZOS)
    # yumuşak gölge
    sh = Image.new("RGBA", out.size, (0, 0, 0, 0))
    m = spr.split()[3].point(lambda v: v * 0.45)
    blk = Image.new("RGBA", spr.size, (40, 0, 30, 255)); blk.putalpha(m)
    sh.alpha_composite(blk, ((size - spr.width) // 2, (size - spr.height) // 2 + size // 40))
    sh = sh.filter(ImageFilter.GaussianBlur(size / 60))
    out.alpha_composite(sh)
    out.alpha_composite(spr, ((size - spr.width) // 2, (size - spr.height) // 2))
    return out


def icon_background(size):
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32) / size
    r = np.sqrt((xx - 0.42) ** 2 + (yy - 0.35) ** 2)
    c1, c2 = np.array([255, 150, 170]), np.array([214, 46, 100])
    t = np.clip(r / 0.85, 0, 1)[..., None]
    img = c1 * (1 - t) + c2 * t
    im = Image.fromarray(img.astype(np.uint8), "RGB").convert("RGBA")
    d = ImageDraw.Draw(im)
    for (x, y, rr) in [(0.16, 0.2, 0.05), (0.85, 0.18, 0.035), (0.82, 0.82, 0.06), (0.14, 0.8, 0.03)]:
        d.ellipse([(x - rr) * size, (y - rr) * size, (x + rr) * size, (y + rr) * size], outline=(255, 235, 240, 150), width=max(1, size // 160))
    return im


def monochrome(img: Image.Image) -> Image.Image:
    a = img.split()[3]
    out = Image.new("RGBA", img.size, (255, 255, 255, 0)); out.putalpha(a)
    return out


def vfx_procedural(d):
    """Parıltı, artı, kalp ve darbe efektleri - şeffaf arka planlı, halesiz."""
    from make_characters import sparkle, heart, burst
    os.makedirs(d, exist_ok=True)
    S = 128 * 4
    def save(fn, draw, glow=3):
        L = Image.new("RGBA", (S, S), (0, 0, 0, 0)); dr = ImageDraw.Draw(L); draw(dr)
        g = L.filter(ImageFilter.GaussianBlur(glow * 4)); g.alpha_composite(L)
        g.resize((128, 128), Image.LANCZOS).save(os.path.join(d, fn))
    save("sparkle.png", lambda dr: sparkle(dr, S / 2, S / 2, S * 0.42))
    save("heart.png", lambda dr: heart(dr, S / 2, S / 2, S * 0.36))
    save("hit.png", lambda dr: (burst(dr, S / 2, S / 2, S * 0.45, (255, 250, 225, 255)), burst(dr, S / 2, S / 2, S * 0.24, (255, 190, 70, 255))))
    def plus(dr):
        w = S * 0.16
        dr.rounded_rectangle([S / 2 - w, S * 0.14, S / 2 + w, S * 0.86], radius=w * 0.6, fill=(80, 220, 110, 255))
        dr.rounded_rectangle([S * 0.14, S / 2 - w, S * 0.86, S / 2 + w], radius=w * 0.6, fill=(80, 220, 110, 255))
        dr.rounded_rectangle([S / 2 - w * .55, S * 0.2, S / 2 - w * .05, S * 0.45], radius=w * 0.3, fill=(200, 255, 210, 200))
    save("plus.png", plus, glow=2)


def main():
    img = cv2.imread(SHEET)
    manifest = {}
    for name, (folder, box, size, T) in ITEMS.items():
        im = extract(img, box, T, size)
        d = os.path.join(ROOT, "assets", folder)
        os.makedirs(d, exist_ok=True)
        p = os.path.join(d, f"{name}.png")
        im.save(p, optimize=True)
        manifest[name] = (folder, size)
    env = os.path.join(ROOT, "assets", "environment")
    gut_background(720, 1600, False).save(os.path.join(env, "gut_bg_light.jpg"), quality=88)
    gut_background(720, 1600, True).save(os.path.join(env, "gut_bg_dark.jpg"), quality=88)
    # uygulama ikonları
    lacto = os.path.join(ROOT, "assets", "characters", "source_1024", "lactobacillus.png")
    icons = os.path.join(ROOT, "assets", "icons")
    os.makedirs(icons, exist_ok=True)
    app_icon(lacto, 192).save(os.path.join(icons, "icon_192.png"))
    app_icon(lacto, 512).convert("RGB").save(os.path.join(ROOT, "store", "icon_512.png"))
    # adaptif ikon: 432 tuval, güvenli alan ~%61 (264px)
    fg = app_icon(lacto, 432, bg=False, safe=0.70)
    fg.save(os.path.join(icons, "adaptive_foreground_432.png"))
    icon_background(432).convert("RGB").save(os.path.join(icons, "adaptive_background_432.png"))
    monochrome(fg).save(os.path.join(icons, "adaptive_monochrome_432.png"))
    app_icon(lacto, 256, bg=False, safe=1.0).save(os.path.join(icons, "splash_icon.png"))
    vfx_procedural(os.path.join(ROOT, "assets", "vfx"))
    json.dump(manifest, open(os.path.join(ROOT, "tools", "ui_items.json"), "w"), indent=1)
    print("ok", len(manifest))


if __name__ == "__main__":
    os.makedirs(os.path.join(ROOT, "store"), exist_ok=True)
    main()
