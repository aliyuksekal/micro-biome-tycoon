extends Control
## Oyun ekranı: üst HUD (besin, lif, bariyer), ızgara, tür seçme çubuğu ve eylem düğmeleri.
## Yatay ekran / tablette ızgara solda, paneller sağda gösterilir.

const GridView = preload("res://scripts/ui/grid_view.gd")

var main
var grid: GridView
var hud: Control
var bottom: Control
var _layout_box: BoxContainer
var _side: VBoxContainer
var _landscape: bool = false
var _nut_label: Label
var _rate_label: Label
var _fiber_label: Label
var _barrier_bar: ProgressBar
var _barrier_label: Label
var _boost_label: Label
var _species_btns: Dictionary = {}
var _species_grid: GridContainer
var _gift_btn: Button
var _open_panel: String = ""
var _panel_modal: Control
var _panel_refresh: Callable = Callable()


func build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	hud = _build_hud()
	grid = GridView.new()
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.custom_minimum_size = Vector2(300, 300)
	grid.tile_tapped.connect(_on_tile)
	bottom = _build_bottom()
	_side = UiTheme.vbox(12)
	_apply_layout(true)
	resized.connect(func() -> void: _apply_layout(false))
	Game.resources_changed.connect(_refresh_hud)
	Game.ticked.connect(_on_tick)
	Game.over.connect(_on_game_over)
	Game.species_unlocked.connect(func(_id: String) -> void: _refresh_species())
	Game.start()
	_refresh_hud()
	_refresh_species()
	if Game.is_over:
		call_deferred("_on_game_over")
	elif not Game.pending_offline.is_empty():
		call_deferred("_show_offline")


func on_leave() -> void:
	Game.stop()


func on_back() -> bool:
	_open_pause()
	return true


func _apply_layout(force: bool) -> void:
	var vs: Vector2 = size if size.x > 0 else get_viewport_rect().size
	var land: bool = vs.x > vs.y * 0.85
	if not force and land == _landscape:
		return
	_landscape = land
	for n in [hud, grid, bottom, _side]:
		if n.get_parent() != null:
			n.get_parent().remove_child(n)
	for c in _side.get_children():
		_side.remove_child(c)
		c.queue_free()
	if _layout_box != null:
		_layout_box.queue_free()
	if land:
		_layout_box = HBoxContainer.new()
		_layout_box.add_theme_constant_override("separation", 16)
		_layout_box.add_child(grid)
		_side.custom_minimum_size = Vector2(minf(560.0, vs.x * 0.44), 0)
		_side.add_child(hud)
		_side.add_child(UiTheme.spacer(4, true))
		_side.add_child(bottom)
		_layout_box.add_child(_side)
		_species_grid.columns = 2
	else:
		_layout_box = VBoxContainer.new()
		_layout_box.add_theme_constant_override("separation", 10)
		_layout_box.add_child(hud)
		_layout_box.add_child(grid)
		_layout_box.add_child(bottom)
		_species_grid.columns = 4
	_layout_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_layout_box)


# ---------------- HUD ----------------
func _build_hud() -> Control:
	var pc := UiTheme.panel("panel", 28, 14)
	var v := UiTheme.vbox(8)
	pc.add_child(v)
	var row := UiTheme.hbox(10)
	v.add_child(row)
	row.add_child(UiTheme.icon("coin", 52))
	var nv := UiTheme.vbox(0)
	_nut_label = UiTheme.label("0", 34, "text", HORIZONTAL_ALIGNMENT_LEFT)
	_rate_label = UiTheme.label("", 20, "text_dim", HORIZONTAL_ALIGNMENT_LEFT)
	nv.add_child(_nut_label)
	nv.add_child(_rate_label)
	nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(nv)
	row.add_child(UiTheme.icon("fiber", 46))
	_fiber_label = UiTheme.label("0", 32, "text", HORIZONTAL_ALIGNMENT_LEFT)
	_fiber_label.custom_minimum_size.x = 70
	row.add_child(_fiber_label)
	var pause := UiTheme.button("", "blue", "pause", 72, 20)
	pause.name = "PauseButton"
	pause.custom_minimum_size.x = 72
	pause.pressed.connect(_open_pause)
	row.add_child(pause)
	var brow := UiTheme.hbox(10)
	brow.add_child(UiTheme.icon("gut", 48))
	_barrier_bar = UiTheme.bar("good", 28)
	brow.add_child(_barrier_bar)
	_barrier_label = UiTheme.label("100%", 24, "text", HORIZONTAL_ALIGNMENT_RIGHT)
	_barrier_label.custom_minimum_size.x = 78
	brow.add_child(_barrier_label)
	v.add_child(brow)
	_boost_label = UiTheme.label("", 22, "text", HORIZONTAL_ALIGNMENT_CENTER)
	_boost_label.add_theme_color_override("font_color", UiTheme.c("gold").darkened(0.15) if not UiTheme.dark else UiTheme.c("gold"))
	_boost_label.visible = false
	v.add_child(_boost_label)
	return pc


func _refresh_hud() -> void:
	if _nut_label == null:
		return
	_nut_label.text = Game.fmt(Game.nutrients)
	_rate_label.text = I18n.t("nutrients") + " · " + I18n.t("per_sec", {"v": Game.fmt(Game.production_per_sec())})
	_fiber_label.text = str(Game.fiber)
	_barrier_bar.value = Game.barrier
	_barrier_label.text = "%d%%" % int(ceil(Game.barrier))
	var col: Color = UiTheme.c("good")
	if Game.barrier < 25.0:
		col = UiTheme.c("bad")
	elif Game.barrier < 55.0:
		col = UiTheme.c("orange")
	UiTheme.set_bar_color(_barrier_bar, col)
	_boost_label.visible = Game.boost_active()
	if _boost_label.visible:
		_boost_label.text = I18n.t("boost_active", {"v": Game.fmt_time(Game.boost_remaining())})
	_refresh_species_costs()
	if _gift_btn != null:
		_gift_btn.modulate = Color(1, 1, 1, 1) if Game.gift_remaining() <= 0.0 else Color(1, 1, 1, 0.75)


func _on_tick() -> void:
	if _panel_refresh.is_valid() and is_instance_valid(_panel_modal):
		_panel_refresh.call()


# ---------------- alt çubuk ----------------
func _build_bottom() -> Control:
	var v := UiTheme.vbox(10)
	_species_grid = GridContainer.new()
	_species_grid.columns = 4
	_species_grid.add_theme_constant_override("h_separation", 10)
	_species_grid.add_theme_constant_override("v_separation", 10)
	for id in Game.GOOD:
		var b := _species_card(id)
		_species_grid.add_child(b)
		_species_btns[id] = b
	v.add_child(_species_grid)
	var actions := UiTheme.hbox(10)
	var eco := UiTheme.button(I18n.t("ecosystem"), "purple", "dna", 84, 24)
	eco.name = "EcoButton"
	eco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	eco.pressed.connect(open_ecosystem)
	actions.add_child(eco)
	var up := UiTheme.button(I18n.t("upgrades"), "orange", "growth_boost", 84, 24)
	up.name = "UpgradeButton"
	up.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	up.pressed.connect(open_upgrades)
	actions.add_child(up)
	_gift_btn = UiTheme.button(I18n.t("gift"), "primary", "gift", 84, 24)
	_gift_btn.name = "GiftButton"
	_gift_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gift_btn.pressed.connect(open_gift)
	actions.add_child(_gift_btn)
	v.add_child(actions)
	return v


func _species_card(id: String) -> Button:
	var b := Button.new()
	b.toggle_mode = true
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(120, 150)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var normal := UiTheme.box(UiTheme.c("panel"), 20, UiTheme.c("border"), 3, 4, 6)
	var sel := UiTheme.box(UiTheme.c("panel2"), 20, UiTheme.c("primary"), 6, 6, 6)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", normal)
	b.add_theme_stylebox_override("pressed", sel)
	b.add_theme_stylebox_override("hover_pressed", sel)
	b.add_theme_stylebox_override("disabled", normal)
	var v := UiTheme.vbox(0)
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var img := UiTheme.portrait(id, 84)
	img.name = "Img"
	img.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(img)
	var nm := UiTheme.label(I18n.t("sp_" + id), 17, "text")
	nm.name = "Name"
	nm.clip_text = true
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(nm)
	var cost := UiTheme.hbox(4)
	cost.alignment = BoxContainer.ALIGNMENT_CENTER
	cost.add_child(UiTheme.icon("coin", 24))
	var cl := UiTheme.label("", 20, "text")
	cl.name = "Cost"
	cost.add_child(cl)
	cost.name = "CostRow"
	v.add_child(cost)
	b.add_child(v)
	b.pressed.connect(func() -> void: _select(id))
	return b


func _select(id: String) -> void:
	if not (id in Game.unlocked):
		main.show_toast(I18n.t("unlock_at", {"v": Game.fmt(float(Game.SPECIES[id]["unlock"]))}))
		_refresh_species()
		return
	Game.selected = id
	Sfx.play("tap")
	_refresh_species()


func _refresh_species() -> void:
	for id in _species_btns.keys():
		var b: Button = _species_btns[id]
		var unlocked: bool = id in Game.unlocked
		b.set_pressed_no_signal(unlocked and Game.selected == id)
		var img: TextureRect = b.find_child("Img", true, false) as TextureRect
		b.modulate = Color(1, 1, 1, 1) if unlocked else Color(0.55, 0.55, 0.6, 0.85)
		if img != null:
			img.modulate = Color(1, 1, 1, 1) if unlocked else Color(0.15, 0.15, 0.2, 1)
	_refresh_species_costs()


func _refresh_species_costs() -> void:
	for id in _species_btns.keys():
		var b: Button = _species_btns[id]
		var cl: Label = b.find_child("Cost", true, false) as Label
		if cl == null:
			continue
		if id in Game.unlocked:
			var cost: float = Game.species_cost(id)
			cl.text = Game.fmt(cost)
			cl.add_theme_color_override("font_color", UiTheme.c("text") if Game.nutrients >= cost else UiTheme.c("bad"))
		else:
			cl.text = I18n.t("locked")
			cl.add_theme_color_override("font_color", UiTheme.c("text_dim"))


# ---------------- karoya dokunma ----------------
func _on_tile(i: int) -> void:
	if Game.is_over:
		return
	var kind: String = str(Game.cells[i]["kind"])
	if Game.is_bad(kind):
		Game.hit(i)
		return
	if Game.is_good(kind):
		_open_colony(i)
		return
	if Game.tiles[i] == "block":
		_open_rock(i)
		return
	var sel: String = Game.selected
	if not (sel in Game.unlocked):
		main.show_toast(I18n.t("select_species"))
		return
	if Game.nutrients < Game.species_cost(sel):
		main.show_toast(I18n.t("not_enough"))
		Sfx.play("alert", -8.0)
		return
	Game.place(i, sel)
	if Game.tiles[i] == "boost":
		main.show_toast(I18n.t("tile_boost"))
	elif Game.tiles[i] == "heal":
		main.show_toast(I18n.t("tile_heal"))


func _open_colony(i: int) -> void:
	var c: Dictionary = Game.cells[i]
	var kind: String = str(c["kind"])
	var m = main.new_modal("", "")
	var p := UiTheme.portrait(kind, 220)
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	m.add(p)
	m.add(UiTheme.label(I18n.t("sp_" + kind), 38, "text"))
	m.add_text(I18n.t("d_" + kind))
	var info := UiTheme.label("", 26, "text", HORIZONTAL_ALIGNMENT_CENTER, true)
	m.add(info)
	var feed_btn: Button = m.add_button("", "primary", func() -> void: pass, "fiber", false)
	var rem_btn: Button = m.add_button("", "red", func() -> void: Game.remove_colony(i), "", true)
	m.add_button(I18n.t("close"), "gray", Callable())
	var refresh := func() -> void:
		var cc: Dictionary = Game.cells[i]
		if str(cc["kind"]) != kind:
			m.close()
			return
		var lvl: int = int(cc["level"])
		info.text = "%s\n%s\n%s" % [I18n.t("level", {"v": lvl}), I18n.t("production", {"v": I18n.t("per_sec", {"v": Game.fmt(Game.cell_production(i) * Game.diversity_mult())})}), I18n.t("health", {"v": "%d/%d" % [int(ceil(float(cc["hp"]))), int(float(cc["max_hp"]))]})]
		if lvl >= Game.MAX_LEVEL:
			feed_btn.text = I18n.t("max_level")
			feed_btn.disabled = true
		else:
			feed_btn.text = I18n.t("feed", {"v": Game.feed_cost(i)})
			feed_btn.disabled = Game.fiber < Game.feed_cost(i)
		rem_btn.text = I18n.t("remove", {"v": Game.fmt(Game.remove_refund(i))})
	var do_feed := func() -> void:
		if Game.feed(i):
			Sfx.play("levelup")
		else:
			main.show_toast(I18n.t("not_enough"))
		refresh.call()
	feed_btn.pressed.connect(do_feed)
	refresh.call()
	_track(m, "colony", refresh)


func _open_rock(i: int) -> void:
	var m = main.new_modal(I18n.t("rock"), "")
	var ic := TextureRect.new()
	ic.texture = Assets.env.get("tile_block", null)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.custom_minimum_size = Vector2(140, 140)
	m.add(ic)
	var do_clear := func() -> void:
		if Game.clear_rock(i):
			Sfx.play("coin")
		else:
			main.show_toast(I18n.t("not_enough"))
	var b: Button = m.add_button(I18n.t("clear_rock", {"v": Game.fmt(Game.rock_cost())}), "orange", do_clear, "coin")
	b.disabled = Game.nutrients < Game.rock_cost()
	m.add_button(I18n.t("close"), "gray", Callable())


func _track(m, name_: String, refresh: Callable) -> void:
	_open_panel = name_
	_panel_modal = m
	_panel_refresh = refresh
	var on_closed := func() -> void:
		if _panel_modal == m:
			_panel_modal = null
			_panel_refresh = Callable()
			_open_panel = ""
	m.closed.connect(on_closed)


# ---------------- paneller ----------------
func open_ecosystem() -> void:
	var m = main.new_modal(I18n.t("eco_title"), "dna", 660.0)
	var list := UiTheme.vbox(10)
	m.add(list)
	var extra := UiTheme.label("", 24, "text", HORIZONTAL_ALIGNMENT_CENTER, true)
	m.add(extra)
	m.add_button(I18n.t("close"), "gray", Callable())
	var rows: Dictionary = {}
	var section := func(title_key: String, ids: Array[String]) -> void:
		list.add_child(UiTheme.label(I18n.t(title_key), 26, "text_dim", HORIZONTAL_ALIGNMENT_LEFT))
		for id in ids:
			var r := UiTheme.hbox(10)
			r.add_child(UiTheme.portrait(id, 56))
			var nm := UiTheme.label(I18n.t("sp_" + id), 22, "text", HORIZONTAL_ALIGNMENT_LEFT)
			nm.custom_minimum_size.x = 170
			nm.clip_text = true
			r.add_child(nm)
			var pb := UiTheme.bar("good" if Game.is_good(id) else "bad", 20)
			r.add_child(pb)
			var pct := UiTheme.label("", 22, "text", HORIZONTAL_ALIGNMENT_RIGHT)
			pct.custom_minimum_size.x = 120
			r.add_child(pct)
			list.add_child(r)
			rows[id] = [pb, pct]
	section.call("friends", Game.GOOD)
	section.call("threats", Game.BAD)
	var refresh := func() -> void:
		var st: Dictionary = Game.ecosystem_stats()
		var total: int = maxi(1, int(st["total"]))
		for id in rows.keys():
			var n: int = int(st["counts"][id])
			var arr: Array = rows[id]
			var pb: ProgressBar = arr[0]
			var pct: Label = arr[1]
			pb.value = 100.0 * n / total
			pct.text = "%d · %d%%" % [n, int(round(100.0 * n / total))]
		var txt: String = I18n.t("diversity", {"v": String.num(Game.diversity_mult(), 2)})
		var d: float = Game.barrier_delta()
		txt += "\n" + I18n.t("barrier_trend", {"v": int(ceil(Game.barrier)), "t": ("+" if d >= 0 else "") + String.num(d, 2)})
		if Game.diversity() < 3:
			txt += "\n" + I18n.t("eco_tip_low")
		extra.text = txt
	refresh.call()
	_track(m, "eco", refresh)


func open_upgrades() -> void:
	var m = main.new_modal(I18n.t("upgrades"), "growth_boost", 660.0)
	var ids: Array[String] = ["tap", "prod", "immune", "barrier", "offline"]
	var icons := {"tap": "energy", "prod": "nutrient_drop", "immune": "shield", "barrier": "healing", "offline": "star"}
	var btns: Dictionary = {}
	for id in ids:
		var r := UiTheme.hbox(12)
		r.add_child(UiTheme.icon(str(icons[id]), 64))
		var tv := UiTheme.vbox(0)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var nm := UiTheme.label("", 24, "text", HORIZONTAL_ALIGNMENT_LEFT, true)
		tv.add_child(nm)
		tv.add_child(UiTheme.label(I18n.t("up_" + id + "_d"), 20, "text_dim", HORIZONTAL_ALIGNMENT_LEFT, true))
		r.add_child(tv)
		var b := UiTheme.button("", "primary", "", 76, 22)
		b.custom_minimum_size.x = 190
		b.name = "Buy_" + id
		var do_buy := func() -> void:
			if Game.buy_upgrade(id):
				Sfx.play("levelup")
			else:
				main.show_toast(I18n.t("not_enough"))
		b.pressed.connect(do_buy)
		r.add_child(b)
		m.add(r)
		btns[id] = [nm, b]
	m.add_button(I18n.t("close"), "gray", Callable())
	var refresh := func() -> void:
		for id in btns.keys():
			var arr: Array = btns[id]
			var nm: Label = arr[0]
			var b: Button = arr[1]
			nm.text = "%s  %s" % [I18n.t("up_" + id), I18n.t("lv_short", {"v": int(Game.upgrades.get(id, 0))})]
			if Game.upgrade_maxed(id):
				b.text = I18n.t("maxed")
				b.disabled = true
			else:
				b.text = Game.fmt(Game.upgrade_cost(id))
				b.disabled = Game.nutrients < Game.upgrade_cost(id)
	refresh.call()
	_track(m, "upgrades", refresh)
	Game.resources_changed.connect(refresh)
	m.closed.connect(func() -> void: Game.resources_changed.disconnect(refresh))


func open_gift() -> void:
	var m = main.new_modal(I18n.t("gift_title"), "gift")
	m.add_text(I18n.t("gift_body"), 28, "text")
	var do_claim := func() -> void:
		if Game.claim_gift():
			Sfx.play("gift")
			Sfx.vibrate(40)
			main.show_toast(I18n.t("boost_active", {"v": Game.fmt_time(Game.boost_remaining())}))
	var b: Button = m.add_button(I18n.t("gift_claim"), "primary", do_claim, "gift")
	var wait := UiTheme.label("", 24, "text_dim")
	m.add(wait)
	m.add_button(I18n.t("close"), "gray", Callable())
	var refresh := func() -> void:
		var r: float = Game.gift_remaining()
		b.disabled = r > 0.0
		wait.text = I18n.t("gift_wait", {"v": Game.fmt_time(r)}) if r > 0.0 else ""
	refresh.call()
	_track(m, "gift", refresh)


func _show_offline() -> void:
	if Game.pending_offline.is_empty():
		return
	var po: Dictionary = Game.pending_offline
	var m = main.new_modal(I18n.t("offline_title"), "crown")
	m.dismissible = false
	m.add_text(I18n.t("offline_body", {"t": Game.fmt_time(float(po["seconds"]))}), 28, "text")
	var row := UiTheme.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(UiTheme.icon("coin", 64))
	row.add_child(UiTheme.label("+" + Game.fmt(float(po["amount"])), 48, "text"))
	m.add(row)
	m.add_text(I18n.t("offline_cap", {"v": Game.offline_cap_hours()}), 22)
	var do_claim := func() -> void:
		Game.claim_offline()
		Sfx.play("coin")
	m.add_button(I18n.t("claim"), "primary", do_claim, "coin")


func _open_pause() -> void:
	if main.has_modal():
		return
	Game.running = false
	var m = main.new_modal(I18n.t("paused"), "pause")
	m.add_button(I18n.t("resume"), "primary", Callable(), "play")
	m.add_button(I18n.t("how_to_play"), "blue", func() -> void: main.show_screen("intro"), "info")
	m.add_button(I18n.t("settings"), "purple", func() -> void: main.open_settings("game"), "gear")
	m.add_button(I18n.t("main_menu"), "orange", func() -> void: main.show_screen("menu"), "star")
	var on_closed := func() -> void:
		if not Game.is_over and is_instance_valid(self) and main.screen == self:
			Game.running = true
	m.closed.connect(on_closed)


func _on_game_over() -> void:
	Sfx.play("gameover")
	Sfx.vibrate(80)
	main.close_all_modals()
	var m = main.new_modal(I18n.t("gameover_title"), "gut")
	m.dismissible = false
	m.add_text(I18n.t("gameover_body"), 26, "text")
	m.add(UiTheme.label(I18n.t("gameover_score", {"v": Game.fmt(Game.run_earned)}), 32, "text"))
	m.add(UiTheme.label(I18n.t("best_score", {"v": Game.fmt(Game.best_score)}), 24, "text_dim"))
	if Game.nutrients >= 10.0:
		var do_revive := func() -> void:
			Game.revive()
			Game.start()
		m.add_button(I18n.t("revive"), "blue", do_revive, "healing")
	var do_again := func() -> void:
		Game.new_run()
		Game.start()
	m.add_button(I18n.t("try_again"), "orange", do_again, "play")
	m.add_button(I18n.t("main_menu"), "gray", func() -> void: main.show_screen("menu"))
