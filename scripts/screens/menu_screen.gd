extends Control
## Ana menü: logo, maskotlar, oyna/devam, nasıl oynanır, ayarlar, hakkında.

var main


func build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var root := UiTheme.vbox(18)
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	root.add_child(UiTheme.spacer(10, true))
	# logo (metin olarak çizilir, görsele gömülmez)
	var logo := UiTheme.vbox(0)
	logo.add_child(UiTheme.title("Micro-Biome", 76, Color.WHITE, Color("6a1fb0"), 18))
	logo.add_child(UiTheme.title("Tycoon", 96, Color("ffd23f"), Color("b0420a"), 20))
	var tag := UiTheme.panel("panel", 30, 14)
	tag.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tag.add_child(UiTheme.label(I18n.t("tagline"), 26, "text"))
	logo.add_child(tag)
	root.add_child(logo)
	# maskotlar
	var row := UiTheme.hbox(0)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var ids: Array[String] = ["lactobacillus", "bifidobacterium", "streptococcus", "e_faecalis"]
	for k in ids.size():
		var p := UiTheme.portrait(ids[k], 150.0)
		row.add_child(p)
		_bob(p, k * 0.25)
	root.add_child(row)
	root.add_child(UiTheme.spacer(4, true))
	# düğmeler
	var col := UiTheme.vbox(16)
	col.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.custom_minimum_size = Vector2(minf(520.0, get_viewport_rect().size.x - 60.0), 0)
	var play_text: String = I18n.t("continue") if Game.has_save and Game.lifetime_earned > 0.0 else I18n.t("play")
	var play := UiTheme.button(play_text, "primary", "play", 110, 38)
	play.name = "PlayButton"
	play.pressed.connect(func() -> void: main.show_screen("game"))
	col.add_child(play)
	var how := UiTheme.button(I18n.t("how_to_play"), "blue", "info")
	how.pressed.connect(func() -> void: main.show_screen("intro"))
	col.add_child(how)
	var two := UiTheme.hbox(16)
	var st := UiTheme.button(I18n.t("settings"), "purple", "gear")
	st.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	st.pressed.connect(func() -> void: main.open_settings("menu"))
	two.add_child(st)
	var ab := UiTheme.button(I18n.t("about"), "orange", "star")
	ab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ab.pressed.connect(func() -> void: main.show_screen("about"))
	two.add_child(ab)
	col.add_child(two)
	root.add_child(col)
	var best := UiTheme.hbox(8)
	best.alignment = BoxContainer.ALIGNMENT_CENTER
	best.add_child(UiTheme.icon("trophy", 40))
	var bl := UiTheme.label(I18n.t("best_score", {"v": Game.fmt(Game.best_score)}), 26, "text")
	bl.add_theme_color_override("font_color", Color.WHITE)
	bl.add_theme_color_override("font_outline_color", Color("5a1240"))
	bl.add_theme_constant_override("outline_size", 8)
	best.add_child(bl)
	root.add_child(best)
	var ver := UiTheme.label(I18n.t("version", {"v": str(ProjectSettings.get_setting("application/config/version", "1.0.0"))}), 20, "text")
	ver.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	root.add_child(ver)
	root.add_child(UiTheme.spacer(8))


func _bob(c: Control, delay: float) -> void:
	c.pivot_offset = Vector2(75, 140)
	var tw := create_tween().set_loops()
	tw.tween_interval(delay)
	tw.tween_property(c, "scale", Vector2(1.04, 0.96), 0.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(c, "scale", Vector2(0.98, 1.03), 0.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(c, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_SINE)
