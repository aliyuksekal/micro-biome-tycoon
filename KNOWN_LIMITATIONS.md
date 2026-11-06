# Bilinen sınırlamalar / doğrulanmamış konular

Bu liste dürüst bir durum raporudur. Aşağıdakiler **gerçek cihazda test edilmedi**.

1. **Gerçek cihaz testi yapılmadı.** Oyun CI'da Linux üzerinde iki şekilde çalıştırıldı: başsız (headless) olarak 143 otomatik kontrolle ve gerçek OpenGL çizimiyle ekran görüntüsü alınarak. Dokunma hissi, titreşim, ses, performans ve pil tüketimi Android cihazda denenmeli.
2. **Çince ve Korece yazı.** Bu karakterler için ayrı font paketlenmedi; Android'in sistem fontlarına geri düşülüyor. Linux CI'da bu harfler kare göründü. Telefonda dil düğmelerinin ve metinlerin doğru göründüğü kontrol edilmeli. Sorun olursa Noto Sans CJK alt kümesi eklenmeli (~5–10 MB).
3. **Kenardan kenara / çentik boşluğu** `DisplayServer.get_display_safe_area()` ile hesaplanıyor. Farklı çentik tiplerinde görsel kontrol gerekli.
4. **Karakter sprite'ları** referans sayfalardan otomatik kesildi (her karakter tek pozdan). `source_1024` dosyaları yaklaşık 2 kat büyütüldü, yani gerçek 1024 detay içermiyor. Oyunda 256 px kullanılıyor. Bazı kenarlarda hafif parıltı kalıntısı olabilir.
5. **Durum animasyonları** (happy/eating/damaged) tek pozun dönüştürülmesi ve efekt eklenmesiyle yapıldı; karaktere özel yeni çizim değiller.
6. **Reklam yok.** Pakette istenen "Reklam izle" yerine Play politikasıyla çelişmeyen "Günlük hediye" (4 saatte bir, 2 dk ×2 üretim + 5 lif) var.
7. **Çevrimdışı kazanç** cihaz saatine dayanır. Saatin geri alınması ödül vermez; ileri alınması en fazla sınır süresi kadar (2–8 saat) ödül verir. Sunucu doğrulaması yok.
8. **APK boyutu** yaklaşık 80 MB (arm64, sıkıştırılmamış motor kitaplığı; 16 KB hizalama için gerekli). Play'den indirme boyutu daha küçük olur.
9. **Native debug symbols** dosyası çok büyük (~570 MB). Play Console bunu kabul etmezse yüklemek zorunlu değildir; yalnızca motor çökme raporlarını okunur yapar.
10. **Gizlilik politikası** `docs/micro-biome-tycoon-gizlilik.html` dosyasında. Bağlantının çalışması için `aliyuksekal/gizlilik` deposuna konması gerekiyor.
