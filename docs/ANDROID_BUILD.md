# Android derleme (GitHub Actions)

İş akışı: `.github/workflows/android.yml`. Tetikleyiciler: `main` dalına gönderim veya **Actions → Run workflow**.

1. Godot 4.7.2 + dışa aktarma şablonları indirilir (önbellekli).
2. Android SDK: platform 36, build-tools 36.1.0, NDK 29.0.14206865, CMake 3.22.1. JDK 17.
3. Nunito fontu indirilir (OFL).
4. Gradle şablonu `android/build` içine açılır; `tools/patch_gradle.py` ile R8 (minify) açılır, `android_overrides/proguard-godot.pro` kopyalanır.
5. Sürüm kodu = çalıştırma numarası + 10; sürüm adı = `1.0.<çalıştırma>`.
6. `godot --headless --import`, ardından `godot --headless -- --selftest` (başarısızsa derleme durur).
7. `xvfb-run godot --rendering-driver opengl3 --resolution 1080x1920 -- --screenshots=...`
8. İmza: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` gizli değerleri varsa kalıcı anahtar kullanılır, yoksa geçici anahtar üretilir (bu durumda Play'e yüklenmez).
9. `--export-release "Android AAB"` ve `"Android APK"`.
10. Doğrulama: `aapt2 dump badging` (targetSdk 36), `apksigner verify`, `zipalign -c -P 16`, `jarsigner -verify`.
11. Çıktılar: GitHub Release + Actions yapıtı. Ekran görüntüleri ve günlükler ayrıca `ci-artifacts` dalına yazılır.

## Yerelde (bilgisayar varsa)
```
godot --headless --path . --import
godot --headless --path . -- --selftest
GODOT_ANDROID_KEYSTORE_RELEASE_PATH=... GODOT_ANDROID_KEYSTORE_RELEASE_USER=upload GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=... \
  godot --headless --path . --export-release "Android AAB" build/micro-biome-tycoon.aab
```
Beklenen: `SELFTEST PASS` ve `build/` altında imzalı AAB.

## Asset'leri yeniden üretmek
```
python3 tools/make_characters.py && python3 tools/make_ui_assets.py && python3 tools/make_audio.py
python3 tools/make_manifest.py && python3 tools/make_store_assets.py
```
