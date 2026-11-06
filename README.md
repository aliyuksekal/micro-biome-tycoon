# Micro-Biome Tycoon

Sevimli bağırsak mikrobiyomu temalı, Android için yerel (native) **Godot 4.7.2** boşta-tycoon oyunu. *Kur · Dengele · Büyüt.*

## İndir
**Releases** sayfasında her derlemede şu dosyalar bulunur:
- `micro-biome-tycoon.apk`: telefona doğrudan kurulum (arm64)
- `micro-biome-tycoon.aab`: Google Play Console'a yüklenecek paket
- `mapping.txt`, `native-debug-symbols.zip`: Play Console çökme raporları için

## Oyun
- 5×7 bağırsak ızgarası. Dost bakteriler (Lactobacillus, Bifidobacterium, Streptococcus, E. faecalis) yerleştirilir ve besin üretir.
- Patojen, İltihap ve C. difficile yayılır; onlara dokunarak yenilir. Bağırsak bariyeri sıfırlanırsa oyun biter.
- Çeşitlilik bonusu, verim ve şifa karoları, kayalar, 5 geliştirme dalı, koloni seviyeleri (lif ile besleme).
- Çevrimdışı kazanç (2–8 saat sınırlı, saat oynamalarına karşı korumalı) ve günlük hediye.
- Ekranlar: tanıtım, ana menü, oyun, ekosistem paneli, geliştirmeler, koloni bilgisi, çevrimdışı ödül, duraklat, oyun bitti, ayarlar, hakkında/lisanslar.
- 6 dil (TR, EN, RU, UZ, ZH, KO), açık/koyu/otomatik tema, ses/müzik/titreşim ayarı, Android geri tuşu, kenardan kenara ekran, tablet/yatay yerleşim.
- Reklam yok, veri toplanmaz, internet izni yok.

## Yapı
| Klasör | İçerik |
|---|---|
| `scripts/autoload/` | `game.gd` (model, 1 sn sabit adımlı simülasyon, atomik kayıt), `i18n.gd`, `settings.gd`, `assets.gd` (doku önbelleği), `sfx.gd`, `ui_theme.gd` |
| `scripts/screens/`, `scripts/ui/` | Kodla kurulan arayüz (ızgara düğüm havuzu, açılır pencereler) |
| `scripts/dev/` | `selftest.gd` (CI testleri), `screenshots.gd` (mağaza ekran görüntüleri) |
| `assets/` | `characters/`, `ui/`, `environment/`, `vfx/`, `audio/`, `icons/`, `asset_manifest.json` |
| `tools/` | Asset üretim betikleri (Python): karakter ayırma, UI, ses, manifest, mağaza görselleri, gradle yaması |
| `store/` | Play ikon, öne çıkan görsel, ekran görüntüleri, 6 dilde mağaza metinleri |
| `docs/` | `PLAY_CONSOLE.md`, `ANDROID_BUILD.md`, gizlilik politikası |

## Derleme ve test
Ayrıntılar `docs/ANDROID_BUILD.md` dosyasında. Kısaca: `main` dalına gönderim → GitHub Actions → içe aktarma → **otomatik testler (143 kontrol)** → OpenGL ile ekran görüntüleri → imzalı AAB + APK → doğrulama (hedef SDK 36, imza, 16 KB) → Release.

Ayrıca bkz. `ASSET_CREDITS.md` ve `KNOWN_LIMITATIONS.md`.
