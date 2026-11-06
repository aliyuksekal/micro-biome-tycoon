#!/usr/bin/env python3
"""assets/asset_manifest.json dosyasını üretir: her asset için yol, tür, kaynak çözünürlük,
pivot, önerilen ekran boyutu, kullanım notu ve Godot içe aktarma ayarı."""
import json, os
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
A = os.path.join(ROOT, "assets")

CHARS = {
    "lactobacillus": ("good", "Parlak gök mavisi tombul kapsül gövde; başlangıç türü."),
    "bifidobacterium": ("good", "Mor, belirgin Y şeklinde gövde; bariyeri onarır."),
    "streptococcus": ("good", "Lime yeşili yuvarlak hücre zinciri; komşu mikroplara saldırır."),
    "e_faecalis": ("good", "Turkuaz yuvarlak hücre kümesi; komşu karoları korur."),
    "pathogen": ("bad", "Kırmızı dikenli küre; bariyeri yıpratır, yayılır."),
    "inflammatory": ("bad", "Mor/magenta düzensiz kabarcıklı gövde (Pathogen'den farklı siluet); komşu kolonilere zarar verir."),
    "c_difficile": ("bad", "Turuncu-kahverengi uzun oval gövde, nodüllü; güçlü tehdit."),
}
STATES = {
    "idle_0": "Idle animasyon karesi 1/4 (≈6 fps döngü)",
    "idle_1": "Idle animasyon karesi 2/4",
    "idle_2": "Idle animasyon karesi 3/4",
    "idle_3": "Idle animasyon karesi 4/4",
    "happy": "Mutlu: yerleştirme/üretim anı (parıltı efektli)",
    "eating": "Yemek yiyor: besleme anı (besin damlası efektli)",
    "damaged": "Hasar aldı: dokunma/saldırı anı (kırmızı ton + darbe yıldızı)",
}
IMPORT_SPRITE = {"compress/mode": "Lossless", "mipmaps/generate": True, "texture_filter": "linear_with_mipmaps",
                 "note": "Küçük ölçekte (96-160 px) bulanıklık olmaması için kayıpsız + mipmap."}
IMPORT_UI = {"compress/mode": "Lossless", "mipmaps/generate": True, "texture_filter": "linear_with_mipmaps"}
IMPORT_BG = {"compress/mode": "Lossy (JPG kaynak)", "mipmaps/generate": True}


def size_of(p):
    with Image.open(p) as im:
        return list(im.size), im.mode


def rel(p):
    return os.path.relpath(p, ROOT).replace(os.sep, "/")


def main():
    items = []
    for cid, (side, note) in CHARS.items():
        base = os.path.join(A, "characters", f"{cid}.png")
        s, mode = size_of(base)
        items.append({"id": f"character.{cid}", "path": rel(base), "res_path": "res://" + rel(base), "type": "character_portrait",
                      "side": side, "source_resolution": s, "color_mode": mode, "pivot": [0.5, 0.95],
                      "recommended_display_px": [96, 160], "usage": "Menü, tanıtım, bilgi pencereleri. " + note, "import": IMPORT_SPRITE})
        hi = os.path.join(A, "characters", "source_1024", f"{cid}.png")
        s, mode = size_of(hi)
        items.append({"id": f"character.{cid}.source_1024", "path": rel(hi), "type": "character_source", "side": side,
                      "source_resolution": s, "color_mode": mode, "pivot": [0.5, 0.95], "exported_in_game": False,
                      "usage": "Yüksek çözünürlüklü kaynak (mağaza görselleri, ikon). Oyuna dahil edilmez. Not: referans kesitinden ~2x büyütülmüştür.",
                      "import": None})
        for st, desc in STATES.items():
            p = os.path.join(A, "characters", cid, f"{st}.png")
            s, mode = size_of(p)
            items.append({"id": f"character.{cid}.{st}", "path": rel(p), "res_path": "res://" + rel(p), "type": "character_state",
                          "side": side, "state": st, "source_resolution": s, "color_mode": mode, "pivot": [0.5, 0.95],
                          "recommended_display_px": [96, 160], "usage": desc, "import": IMPORT_SPRITE})
    for folder, typ in [("ui", "ui_icon"), ("environment", "environment"), ("vfx", "vfx"), ("icons", "launcher_icon")]:
        d = os.path.join(A, folder)
        for fn in sorted(os.listdir(d)):
            if not fn.lower().endswith((".png", ".jpg")):
                continue
            p = os.path.join(d, fn)
            s, mode = size_of(p)
            t = typ
            disp = [32, 72]
            imp = IMPORT_UI
            pivot = [0.5, 0.5]
            if fn.startswith("tile_"):
                t, disp = "grid_tile", [80, 140]
            elif fn.startswith("gut_bg"):
                t, disp, imp = "background", "fullscreen (cover)", IMPORT_BG
            elif folder == "environment":
                disp = [80, 200]
            elif folder == "icons":
                disp, imp = "launcher", None
            items.append({"id": f"{folder}.{os.path.splitext(fn)[0]}", "path": rel(p), "res_path": "res://" + rel(p), "type": t,
                          "source_resolution": s, "color_mode": mode, "pivot": pivot, "recommended_display_px": disp,
                          "usage": "", "import": imp})
    audio = os.path.join(A, "audio")
    for fn in sorted(os.listdir(audio)):
        if fn.endswith(".wav"):
            items.append({"id": "audio." + fn[:-4], "path": rel(os.path.join(audio, fn)), "type": "music" if "music" in fn else "sfx",
                          "format": "WAV 22050 Hz mono 16-bit", "usage": "Prosedürel üretildi (tools/make_audio.py)"})
    manifest = {
        "project": "Micro-Biome Tycoon",
        "generated_by": "tools/make_manifest.py",
        "conventions": {
            "pivot": "Normalize (x, y); karakterlerde ayak tabanı (0.5, 0.95).",
            "atlas": "Atlas kullanılmıyor; her kare ayrı PNG. Godot yükleme sırasında tümünü bir kez önbelleğe alır (scripts/autoload/assets.gd).",
            "animation": "idle_0..3 döngü ≈6 fps (0.16 s/kare); happy/eating/damaged olaylarda 0.4-0.7 s gösterilir, ardından idle'a dönülür.",
            "runtime_sprite_size": "Durum sprite'ları 256x256 (ekranda 96-160 px). Portreler 512x512.",
            "text_in_images": "Görsellerde metin yok; tüm metinler Godot UI ile çizilir.",
        },
        "assets": items,
    }
    with open(os.path.join(A, "asset_manifest.json"), "w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=1)
    print(len(items), "asset")


if __name__ == "__main__":
    main()
