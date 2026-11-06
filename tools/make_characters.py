#!/usr/bin/env python3
"""Micro-Biome Tycoon - karakter sprite üretim hattı.

Referans kompozisyon sayfalarından (art_source/) her karakteri gerçek alfa
kanallı ayrı PNG olarak çıkarır, durum (idle/happy/eating/damaged) ve 4 karelik
idle animasyon sprite'larını üretir, kalite kontrol raporu yazar.

Kullanım:  python3 tools/make_characters.py
Gerekenler: Python 3.10+, numpy, opencv-python, scipy, Pillow
"""
from __future__ import annotations
import json, math, os, sys
import numpy as np
import cv2
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))
from segment import run as segment  # noqa: E402

SRC = os.path.join(ROOT, "art_source")
OUT = os.path.join(ROOT, "assets", "characters")
PIVOT = (0.5, 0.95)      # ayak tabanı: yatay orta, dikeyde %95
FILL = 0.84              # karakterin tuvaldeki en büyük boyutu

# kaynak sayfa, kırpma kutusu, eşik, temizlenecek kalıntı dikdörtgenleri,
# ağız merkezi (kesilmiş görsel koordinatı), yararlı mı
CHARS = {
    "lactobacillus":   dict(src="character_sheet_02.png", box=[40, 10, 420, 510],  mouth=(190, 237), good=True),
    "bifidobacterium": dict(src="character_sheet_02.png", box=[400, 0, 815, 525],  mouth=(217, 255), good=True,
                            erase=[(388, 110, 400, 200), (368, 196, 400, 248)]),
    "streptococcus":   dict(src="character_sheet_02.png", box=[814, 25, 1185, 512], mouth=(183, 200), good=True,
                            erase=[(0, 160, 24, 250), (36, 445, 84, 470)]),
    "e_faecalis":      dict(src="character_sheet_02.png", box=[1165, 45, 1532, 512], mouth=(160, 230), good=True),
    "pathogen":        dict(src="character_sheet_02.png", box=[0, 508, 545, 1024], mouth=(265, 300), good=False),
    "inflammatory":    dict(src="character_sheet_06.png", box=[585, 492, 1065, 1010], mouth=(243, 225), good=False),
    "c_difficile":     dict(src="character_sheet_02.png", box=[1088, 505, 1536, 1024], mouth=(230, 285), good=False),
}
T = 28


def cutout(name: str, cfg: dict) -> Image.Image:
    img = cv2.imread(os.path.join(SRC, cfg["src"]))
    crop, fg, _ = segment(img, cfg["box"], T)
    ys, xs = np.where(fg)
    y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    fg = fg[y0:y1, x0:x1].copy()
    crop = crop[y0:y1, x0:x1].copy()
    for (a, b, c, d) in cfg.get("erase", []):
        fg[b:d, a:c] = False
    # yalnızca en büyük bileşen
    from scipy import ndimage as ndi
    lab, n = ndi.label(fg)
    if n > 1:
        sz = ndi.sum(fg, lab, range(1, n + 1))
        fg = lab == (1 + int(np.argmax(sz)))
    # alfa: 1px içeri çek + yumuşak kenar
    a = cv2.erode(fg.astype(np.float32), np.ones((3, 3), np.uint8))
    a = np.clip(cv2.GaussianBlur(a, (0, 0), 0.8), 0, 1)
    a[a < 0.04] = 0
    # defringe: kenar bandındaki renkleri 3px içerideki renkle değiştir (arka plan parıltısı sızmasın)
    inner = cv2.erode(fg.astype(np.uint8), np.ones((7, 7), np.uint8)) > 0
    _, (iy, ix) = ndi.distance_transform_edt(~inner, return_indices=True)
    band = (a > 0) & ~inner
    rgb = cv2.cvtColor(crop, cv2.COLOR_BGR2RGB)
    fixed = rgb.copy()
    fixed[band] = (0.45 * rgb[band] + 0.55 * rgb[iy[band], ix[band]]).astype(np.uint8)
    rgba = np.dstack([fixed, (a * 255).astype(np.uint8)])
    rgba[rgba[:, :, 3] == 0, :3] = 0  # tamamen şeffaf pikselde renk kalıntısı bırakma
    return Image.fromarray(rgba, "RGBA")


def place(sprite: Image.Image, size: int, sx=1.0, sy=1.0, dx=0.0, dy=0.0, rot=0.0) -> tuple[Image.Image, float, tuple]:
    """Karakteri tuvale yerleştirir. Ayak tabanı pivot noktasına oturur."""
    w, h = sprite.size
    s = FILL * size / max(w, h)
    nw, nh = max(1, round(w * s * sx)), max(1, round(h * s * sy))
    spr = sprite.resize((nw, nh), Image.LANCZOS)
    if rot:
        spr = spr.rotate(rot, resample=Image.BICUBIC, expand=True)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    x = round(size * PIVOT[0] - spr.width / 2 + dx * size)
    y = round(size * PIVOT[1] - spr.height + dy * size)
    canvas.alpha_composite(spr, (x, y))
    return canvas, s, (x, y, nw, nh)


# ---------- efekt çizimleri (4x süper örnekleme) ----------
def _layer(size):
    return Image.new("RGBA", (size * 4, size * 4), (0, 0, 0, 0))


def _finish(layer, size, glow=0):
    if glow:
        g = layer.filter(ImageFilter.GaussianBlur(glow * 4))
        g.alpha_composite(layer)
        layer = g
    return layer.resize((size, size), Image.LANCZOS)


def sparkle(d: ImageDraw.ImageDraw, cx, cy, r, col=(255, 244, 170, 255)):
    pts = []
    for i in range(8):
        ang = i * math.pi / 4 - math.pi / 2
        rr = r if i % 2 == 0 else r * 0.28
        pts.append((cx + rr * math.cos(ang), cy + rr * math.sin(ang)))
    d.polygon(pts, fill=col)
    d.ellipse([cx - r * .18, cy - r * .18, cx + r * .18, cy + r * .18], fill=(255, 255, 255, 255))


def heart(d, cx, cy, r, col=(255, 92, 140, 255)):
    d.ellipse([cx - r, cy - r * .7, cx, cy + r * .3], fill=col)
    d.ellipse([cx, cy - r * .7, cx + r, cy + r * .3], fill=col)
    d.polygon([(cx - r * .97, cy - r * .05), (cx + r * .97, cy - r * .05), (cx, cy + r * 1.05)], fill=col)
    d.ellipse([cx - r * .7, cy - r * .5, cx - r * .35, cy - r * .2], fill=(255, 220, 232, 255))


def drop(d, cx, cy, r):
    """Altın besin damlası (glukoz)"""
    for i in range(12, 0, -1):
        t = i / 12
        col = (int(255), int(150 + 80 * (1 - t)), int(20 + 60 * (1 - t)), 255)
        rr = r * t
        d.ellipse([cx - rr, cy - rr + r * (1 - t) * .3, cx + rr, cy + rr + r * (1 - t) * .3], fill=col)
    d.polygon([(cx - r * .72, cy - r * .55), (cx + r * .72, cy - r * .55), (cx, cy - r * 1.9)], fill=(255, 176, 40, 255))
    d.ellipse([cx - r * .55, cy - r * .7, cx - r * .15, cy - r * .1], fill=(255, 250, 220, 235))


def burst(d, cx, cy, r, col=(255, 255, 255, 255)):
    pts = []
    for i in range(16):
        ang = i * math.pi / 8
        rr = r if i % 2 == 0 else r * .45
        pts.append((cx + rr * math.cos(ang), cy + rr * math.sin(ang)))
    d.polygon(pts, fill=col)


def sweat(d, cx, cy, r):
    d.ellipse([cx - r, cy - r * .2, cx + r, cy + r * 1.8], fill=(140, 215, 255, 255))
    d.polygon([(cx - r * .8, cy + r * .4), (cx + r * .8, cy + r * .4), (cx, cy - r * 1.2)], fill=(140, 215, 255, 255))
    d.ellipse([cx - r * .45, cy + r * .3, cx - r * .05, cy + r * .9], fill=(235, 250, 255, 255))


def tint(im: Image.Image, rgb, amount, dark=1.0) -> Image.Image:
    a = np.asarray(im).astype(np.float32)
    col = np.array(rgb, np.float32)
    a[:, :, :3] = (a[:, :, :3] * (1 - amount) + col * amount) * dark
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA")


def make_states(name, base: Image.Image, cfg, size=256):
    folder = os.path.join(OUT, name)
    os.makedirs(folder, exist_ok=True)
    files = {}
    # idle: 4 kare nefes alma (ayak sabit)
    for i in range(4):
        ph = math.sin(i * math.pi / 2)
        im, _, _ = place(base, size, sx=1 - 0.012 * ph, sy=1 + 0.024 * ph)
        p = os.path.join(folder, f"idle_{i}.png"); im.save(p, optimize=True); files[f"idle_{i}"] = p
    # happy
    im, s, (x, y, nw, nh) = place(base, size, sx=0.97, sy=1.04, dy=-0.035)
    fx = _layer(size); d = ImageDraw.Draw(fx)
    k = 4
    if cfg["good"]:
        sparkle(d, (x + nw * 0.02) * k, (y + nh * 0.12) * k, size * 0.07 * k)
        sparkle(d, (x + nw * 0.98) * k, (y + nh * 0.05) * k, size * 0.05 * k)
        heart(d, (x + nw * 0.93) * k, (y + nh * 0.40) * k, size * 0.045 * k)
    else:
        sparkle(d, (x + nw * 0.05) * k, (y + nh * 0.08) * k, size * 0.05 * k, col=(255, 120, 120, 255))
        sparkle(d, (x + nw * 0.95) * k, (y + nh * 0.12) * k, size * 0.06 * k, col=(255, 160, 90, 255))
    im.alpha_composite(_finish(fx, size, glow=3))
    p = os.path.join(folder, "happy.png"); im.save(p, optimize=True); files["happy"] = p
    # eating: hafif yassılma + ağız önünde besin damlası + kırıntılar
    sx, sy = 1.05, 0.95
    im, s, (x, y, nw, nh) = place(base, size, sx=sx, sy=sy)
    mx = x + cfg["mouth"][0] * s * sx
    my = y + cfg["mouth"][1] * s * sy
    fx = _layer(size); d = ImageDraw.Draw(fx)
    drop(d, (mx + size * 0.01) * k, (my + size * 0.02) * k, size * 0.06 * k)
    for (ox, oy, rr) in [(-0.07, 0.05, .010), (0.08, 0.07, .008), (-0.04, 0.10, .007), (0.06, 0.12, .006)]:
        cx, cy = (mx + ox * size) * k, (my + oy * size) * k
        d.ellipse([cx - rr * size * k, cy - rr * size * k, cx + rr * size * k, cy + rr * size * k], fill=(255, 196, 70, 255))
    im.alpha_composite(_finish(fx, size, glow=1))
    p = os.path.join(folder, "eating.png"); im.save(p, optimize=True); files["eating"] = p
    # damaged: kırmızı ton, eğilme, darbe yıldızı, ter damlası
    hurt = tint(base, (255, 40, 50), 0.32, 0.93)
    im, s, (x, y, nw, nh) = place(hurt, size, rot=-7, dx=-0.02)
    fx = _layer(size); d = ImageDraw.Draw(fx)
    burst(d, (x + nw * 0.92) * k, (y + nh * 0.18) * k, size * 0.075 * k, col=(255, 250, 225, 255))
    burst(d, (x + nw * 0.92) * k, (y + nh * 0.18) * k, size * 0.04 * k, col=(255, 200, 80, 255))
    sweat(d, (x + nw * 0.10) * k, (y + nh * 0.10) * k, size * 0.022 * k)
    im.alpha_composite(_finish(fx, size, glow=2))
    p = os.path.join(folder, "damaged.png"); im.save(p, optimize=True); files["damaged"] = p
    return files


def qc(path: str) -> dict:
    im = Image.open(path)
    a = np.asarray(im.convert("RGBA"))[:, :, 3]
    edge = np.r_[a[0], a[-1], a[:, 0], a[:, -1]]
    return dict(mode=im.mode, size=im.size, has_alpha=im.mode == "RGBA",
                transparent_ratio=round(float((a == 0).mean()), 3),
                touches_border=bool((edge > 8).any()),
                semi_transparent_px=int(((a > 0) & (a < 255)).sum()))


def main():
    os.makedirs(os.path.join(OUT, "source_1024"), exist_ok=True)
    report = {}
    for name, cfg in CHARS.items():
        base = cutout(name, cfg)
        hi, s1024, _ = place(base, 1024)
        hi.save(os.path.join(OUT, "source_1024", f"{name}.png"), optimize=True)
        lo, _, _ = place(base, 512)
        lo.save(os.path.join(OUT, f"{name}.png"), optimize=True)
        files = make_states(name, base, cfg)
        r = {"native_cutout_px": list(base.size), "upscale_1024": round(s1024, 2),
             "base_512": qc(os.path.join(OUT, f"{name}.png")),
             "source_1024": qc(os.path.join(OUT, "source_1024", f"{name}.png"))}
        r["states"] = {k: qc(v) for k, v in files.items()}
        report[name] = r
        print(name, base.size, "->", r["base_512"])
    with open(os.path.join(ROOT, "tools", "character_qc_report.json"), "w") as f:
        json.dump(report, f, indent=1)


if __name__ == "__main__":
    main()
