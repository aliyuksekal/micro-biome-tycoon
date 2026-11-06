extends Node
## CI'da çalışan otomatik testler: oyun mantığı, kayıt/yükleme, çevrimdışı sınır,
## bozuk kayıt kurtarma, tüm ekran/pencere/dil/tema kombinasyonları.
## Çalıştırma: godot --headless -- --selftest   (çıkış kodu 0 = başarılı)

var fails: Array[String] = []
var checks: int = 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("  ok  ", what)
	else:
		print("  FAIL ", what)
		fails.append(what)


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== SELFTEST başladı ===")
	var main = get_parent()
	Game.running = false
	# 1) kaynaklar
	check(I18n.missing_report().is_empty(), "tüm çeviriler 6 dilde mevcut: %s" % str(I18n.missing_report()))
	check(Assets.missing.is_empty(), "tüm dokular yüklendi: %s" % str(Assets.missing))
	for id in Assets.CHAR_IDS:
		for st in Assets.STATES:
			var tx: Texture2D = Assets.char_tex(id, st)
			check(tx != null and tx.get_width() == 256, "sprite %s/%s 256px" % [id, st])
	# 2) temel mantık
	Game.reset_all()
	check(is_equal_approx(Game.nutrients, 20.0), "yeni oyunda 20 besin")
	var center: int = Game.index_of(2, 3)
	check(Game.tiles[center] == "normal", "orta karo normal")
	check(Game.place(center, "lactobacillus"), "lactobacillus yerleştirildi")
	check(not Game.place(center, "lactobacillus"), "dolu karoya yerleştirilemez")
	var n0: float = Game.nutrients
	for k in 10:
		Game.step(1.0)
	check(Game.nutrients > n0, "üretim besin kazandırıyor")
	check(Game.production_per_sec() > 0.0, "üretim > 0")
	check(not Game.place(Game.index_of(0, 0), "e_faecalis"), "kilitli tür yerleştirilemez")
	# 3) patojen ve dokunma
	var free_i: int = -1
	for i in Game.cells.size():
		if str(Game.cells[i]["kind"]) == "" and Game.tiles[i] != "block":
			free_i = i
			break
	Game._spawn_bad(free_i, "pathogen")
	var fiber0: int = Game.fiber
	for k in 200:
		if str(Game.cells[free_i]["kind"]) != "pathogen":
			break
		Game.hit(free_i)
	check(str(Game.cells[free_i]["kind"]) == "", "patojen dokunarak yenildi")
	check(Game.fiber > fiber0, "patojen yenince lif kazanıldı")
	# 4) besleme ve geliştirme
	Game.fiber = 100
	check(Game.feed(center), "koloni beslendi")
	check(int(Game.cells[center]["level"]) == 2, "seviye 2 oldu")
	Game.nutrients = 1.0e9
	for id in Game.UPGRADES.keys():
		check(Game.buy_upgrade(id), "geliştirme alındı: " + id)
	check(Game.offline_cap_hours() == 3, "çevrimdışı sınır 3 saat")
	# 5) hediye
	Game.last_gift = Game.now_unix() - Game.GIFT_COOLDOWN - 1.0
	check(Game.claim_gift(), "hediye alındı")
	check(Game.boost_active(), "x2 aktif")
	check(not Game.claim_gift(), "hediye bekleme süresinde tekrar alınamaz")
	Game.last_gift = Game.now_unix() + 99999.0  # saat geri alınmış gibi
	check(Game.gift_remaining() <= Game.GIFT_COOLDOWN + 1.0, "saat geri alınınca bekleme makul kalır")
	# 6) çevrimdışı
	Game.last_active = Game.now_unix() - 50.0 * 3600.0
	Game._compute_offline()
	check(not Game.pending_offline.is_empty(), "çevrimdışı ödül hesaplandı")
	if not Game.pending_offline.is_empty():
		check(float(Game.pending_offline["counted"]) <= Game.offline_cap_hours() * 3600.0 + 0.1, "çevrimdışı süre sınırlandı")
	Game.pending_offline = {}
	Game.last_active = Game.now_unix() + 10000.0
	Game._compute_offline()
	check(Game.pending_offline.is_empty(), "negatif süre (saat geri) ödül vermez")
	# 7) kayıt / yükleme / bozuk kayıt
	Game.nutrients = 4321.0
	Game.save_game()
	Game.save_game()  # .bak da oluşsun
	Game.nutrients = 1.0
	check(Game.load_game(), "kayıt yüklendi")
	check(is_equal_approx(Game.nutrients, 4321.0), "besin kayıttan geri geldi")
	var f := FileAccess.open(Game.SAVE_PATH, FileAccess.WRITE)
	f.store_string("{bozuk json")
	f.close()
	check(Game.load_game(), "bozuk kayıtta yedekten yüklendi")
	# 8) uzun simülasyon
	Game.reset_all()
	Game.unlocked.assign(["lactobacillus", "bifidobacterium", "streptococcus", "e_faecalis"])
	Game.nutrients = 50000.0
	var placed: int = 0
	for i in Game.cells.size():
		if Game.tiles[i] != "block" and placed < 12:
			Game.place(i, Game.GOOD[placed % 4])
			placed += 1
	for k in 1500:
		Game.step(1.0)
		if k % 7 == 0:
			for i in Game.cells.size():
				if Game.is_bad(str(Game.cells[i]["kind"])):
					Game.hit(i)
					break
		if Game.is_over:
			Game.revive()
	check(is_finite(Game.nutrients) and Game.nutrients >= 0.0, "1500 adım sonra besin geçerli")
	check(Game.barrier >= 0.0 and Game.barrier <= 100.0, "bariyer 0-100 aralığında")
	# 9) oyun bitti
	Game.barrier = 0.4
	for i in Game.cells.size():
		if str(Game.cells[i]["kind"]) == "" and Game.tiles[i] != "block":
			Game._spawn_bad(i, "c_difficile")
	Game.step(1.0)
	check(Game.is_over, "bariyer bitince oyun biter")
	Game.revive()
	check(not Game.is_over and Game.barrier > 0.0, "kurtarma çalışır")
	# 10) arayüz: tüm ekranlar, diller ve temalar
	for theme_mode in ["light", "dark"]:
		Settings.set_value("theme", theme_mode)
		for lang in I18n.LANGS:
			Settings.set_value("language", lang)
			for scr in ["intro", "menu", "game", "settings", "about"]:
				main.show_screen(scr)
				await get_tree().process_frame
				check(main.screen != null and main.screen_name == scr, "ekran %s (%s/%s)" % [scr, lang, theme_mode])
			main.show_screen("game")
			await get_tree().process_frame
			var gs: Node = main.screen
			gs.call("open_ecosystem")
			await get_tree().process_frame
			main.close_all_modals()
			gs.call("open_upgrades")
			await get_tree().process_frame
			main.close_all_modals()
			gs.call("open_gift")
			await get_tree().process_frame
			main.close_all_modals()
			gs.call("_open_pause")
			await get_tree().process_frame
			main.handle_back()
			await get_tree().process_frame
			for i in Game.cells.size():
				if Game.is_good(str(Game.cells[i]["kind"])):
					gs.call("_open_colony", i)
					break
			await get_tree().process_frame
			main.close_all_modals()
			gs.call("_on_game_over")
			await get_tree().process_frame
			main.close_all_modals()
			await get_tree().create_timer(0.2).timeout
	# yatay düzen
	get_window().size = Vector2i(1600, 1000)
	await get_tree().process_frame
	await get_tree().process_frame
	check(main.screen != null, "yatay ekranda oyun ekranı çalışıyor")
	Settings.set_value("theme", "auto")
	Settings.set_value("language", "auto")
	Game.reset_all()
	print("=== SELFTEST %d kontrol, %d hata ===" % [checks, fails.size()])
	if fails.is_empty():
		print("SELFTEST PASS")
		get_tree().quit(0)
	else:
		for x in fails:
			print("HATA: ", x)
		print("SELFTEST FAIL")
		get_tree().quit(1)
