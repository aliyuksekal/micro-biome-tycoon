extends Node
## Mağaza ekran görüntülerini üretir (CI'da xvfb + OpenGL ile).
## Çalıştırma: godot --rendering-driver opengl3 --resolution 1080x1920 -- --screenshots=/yol
## Ayrıca tüm ekranları gerçekten çizerek çalışma zamanı hatalarını yakalar.

var out_dir: String = ""
var main


func _ready() -> void:
	out_dir = str(get_meta("out", "user://shots"))
	DirAccess.make_dir_recursive_absolute(out_dir)
	main = get_parent()
	call_deferred("_run")


func _wait(frames: int = 8) -> void:
	for i in frames:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw


func _shot(file: String) -> void:
	await _wait(10)
	var img: Image = get_viewport().get_texture().get_image()
	var path: String = out_dir.path_join(file)
	var err: int = img.save_png(path)
	print("shot ", path, " ", img.get_size(), " err=", err)


func _demo_state() -> void:
	Game.reset_all()
	Game.unlocked.assign(["lactobacillus", "bifidobacterium", "streptococcus", "e_faecalis"])
	Game.nutrients = 1000000.0
	var plan: Array = [
		[1, 1, "lactobacillus", 2], [2, 1, "bifidobacterium", 1], [3, 1, "lactobacillus", 1],
		[0, 2, "streptococcus", 3], [1, 2, "lactobacillus", 1], [2, 3, "e_faecalis", 2],
		[3, 3, "bifidobacterium", 2], [1, 4, "lactobacillus", 1], [2, 4, "streptococcus", 1],
		[4, 2, "lactobacillus", 1], [0, 5, "bifidobacterium", 1], [3, 5, "lactobacillus", 4],
	]
	for p in plan:
		var i: int = Game.index_of(int(p[0]), int(p[1]))
		if Game.tiles[i] == "block":
			continue
		Game.place(i, str(p[2]))
		Game.cells[i]["level"] = int(p[3])
	var bad_plan: Array = [[4, 5, "pathogen"], [4, 6, "inflammatory"], [0, 0, "pathogen"]]
	for p in bad_plan:
		var i: int = Game.index_of(int(p[0]), int(p[1]))
		if Game.tiles[i] != "block" and str(Game.cells[i]["kind"]) == "":
			Game._spawn_bad(i, str(p[2]))
	Game.nutrients = 18450.0
	Game.fiber = 23
	Game.barrier = 82.0
	Game.lifetime_earned = 25000.0
	Game.best_score = 48200.0
	Game.boost_until = Game.now_unix() + 95.0
	Game.last_gift = Game.now_unix()
	Game.selected = "bifidobacterium"
	Game.has_save = true
	Game.run_reset.emit()


func _run() -> void:
	Game.running = false
	for lang in ["tr", "en"]:
		Settings.set_value("language", lang)
		Settings.set_value("theme", "light")
		_demo_state()
		main.show_screen("menu")
		await _shot("%s_01_menu.png" % lang)
		main.show_screen("game")
		Game.running = false
		await _shot("%s_02_game.png" % lang)
		var gs: Node = main.screen
		gs.call("open_ecosystem")
		await _shot("%s_03_ecosystem.png" % lang)
		main.close_all_modals()
		gs.call("open_upgrades")
		await _shot("%s_04_upgrades.png" % lang)
		main.close_all_modals()
		gs.call("_open_colony", Game.index_of(2, 3) if Game.is_good(str(Game.cells[Game.index_of(2, 3)]["kind"])) else Game.index_of(1, 1))
		await _shot("%s_05_colony.png" % lang)
		main.close_all_modals()
		main.show_screen("intro")
		await _shot("%s_06_intro.png" % lang)
		Settings.set_value("theme", "dark")
		main.show_screen("game")
		Game.running = false
		await _shot("%s_07_game_dark.png" % lang)
		main.show_screen("settings")
		await _shot("%s_08_settings_dark.png" % lang)
		main.show_screen("game")
		Game.running = false
		main.screen.call("_on_game_over")
		await _shot("%s_09_gameover_dark.png" % lang)
		main.close_all_modals()
	# tablet (yatay) görünüm
	Settings.set_value("language", "en")
	Settings.set_value("theme", "light")
	get_window().size = Vector2i(2560, 1600)
	await _wait(6)
	main.show_screen("game")
	Game.running = false
	await _shot("tablet_01_game_landscape.png")
	main.show_screen("menu")
	await _shot("tablet_02_menu_landscape.png")
	Settings.set_value("language", "auto")
	Settings.set_value("theme", "auto")
	Game.reset_all()
	print("SCREENSHOTS DONE")
	get_tree().quit(0)
