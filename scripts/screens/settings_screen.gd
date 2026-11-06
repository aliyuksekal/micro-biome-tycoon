extends Control
## Ayarlar: dil, tema (açık/koyu/otomatik), ses, müzik, titreşim, gizlilik, sıfırlama.

const PRIVACY_URL := "https://aliyuksekal.github.io/gizlilik/micro-biome-tycoon-gizlilik.html"

var main


func build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var root := UiTheme.vbox(12)
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	root.add_child(_header(I18n.t("settings")))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var col := UiTheme.vbox(16)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(col)
	# Dil
	var lang_box := _section(col, I18n.t("language"), "info")
	var lg := GridContainer.new()
	lg.columns = 2
	lg.add_theme_constant_override("h_separation", 10)
	lg.add_theme_constant_override("v_separation", 10)
	var cur_lang: String = str(Settings.get_value("language"))
	var opts: Array[String] = ["auto"]
	opts.append_array(I18n.LANGS)
	for code in opts:
		var txt: String = I18n.t("lang_auto") if code == "auto" else str(I18n.LANG_NAMES[code])
		var b := UiTheme.button(txt, "primary" if code == cur_lang else "gray", "", 76, 26)
		b.name = "Lang_" + code
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_set_lang.bind(code))
		lg.add_child(b)
	lang_box.add_child(lg)
	# Tema
	var th_box := _section(col, I18n.t("theme"), "star")
	var th := UiTheme.hbox(10)
	var cur_theme: String = str(Settings.get_value("theme"))
	for mode in ["auto", "light", "dark"]:
		var b := UiTheme.button(I18n.t("theme_" + mode), "primary" if mode == cur_theme else "gray", "", 76, 26)
		b.name = "Theme_" + mode
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_set_theme.bind(mode))
		th.add_child(b)
	th_box.add_child(th)
	# Ses / titreşim
	var snd := _section(col, I18n.t("sound"), "heart")
	snd.add_child(_toggle(I18n.t("sound"), "sfx"))
	snd.add_child(_toggle(I18n.t("music"), "music"))
	snd.add_child(_toggle(I18n.t("vibration"), "vibration"))
	# Diğer
	var other := _section(col, I18n.t("about"), "shield_badge")
	var how := UiTheme.button(I18n.t("how_to_play"), "blue", "info", 84, 26)
	how.pressed.connect(func() -> void: main.show_screen("intro"))
	other.add_child(how)
	var pv := UiTheme.button(I18n.t("privacy"), "purple", "shield_badge", 84, 26)
	pv.pressed.connect(func() -> void: OS.shell_open(PRIVACY_URL))
	other.add_child(pv)
	var rs := UiTheme.button(I18n.t("reset"), "red", "alert", 84, 26)
	rs.name = "ResetButton"
	rs.pressed.connect(_ask_reset)
	other.add_child(rs)
	col.add_child(UiTheme.spacer(20))


func _header(text: String) -> Control:
	var h := UiTheme.hbox(12)
	var back := UiTheme.button(I18n.t("back"), "gray", "", 76, 24)
	back.name = "BackButton"
	back.pressed.connect(func() -> void: main.back_from_settings())
	h.add_child(back)
	var t := UiTheme.title(text, 48, Color.WHITE, Color("6a1fb0"), 12)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(t)
	h.add_child(UiTheme.spacer(0))
	var dummy := Control.new()
	dummy.custom_minimum_size = Vector2(back.get_combined_minimum_size().x, 0)
	h.add_child(dummy)
	return h


func _section(parent: Control, title_text: String, icon_name: String) -> VBoxContainer:
	var pc := UiTheme.panel("panel", 26, 20)
	var v := UiTheme.vbox(12)
	pc.add_child(v)
	var hr := UiTheme.hbox(10)
	hr.add_child(UiTheme.icon(icon_name, 40))
	hr.add_child(UiTheme.label(title_text, 30, "text", HORIZONTAL_ALIGNMENT_LEFT))
	v.add_child(hr)
	parent.add_child(pc)
	return v


func _toggle(text: String, key: String) -> CheckButton:
	var cb := CheckButton.new()
	cb.text = text
	cb.name = "Toggle_" + key
	cb.button_pressed = Settings.flag(key)
	cb.custom_minimum_size = Vector2(0, 64)
	cb.focus_mode = Control.FOCUS_NONE
	cb.toggled.connect(func(on: bool) -> void: Settings.set_value(key, on))
	return cb


func _set_lang(code: String) -> void:
	Settings.set_value("language", code)
	main.show_screen("settings", true)


func _set_theme(mode: String) -> void:
	Settings.set_value("theme", mode)


func _ask_reset() -> void:
	main.confirm(I18n.t("reset_q"), I18n.t("reset_yes"), "red", _do_reset)


func _do_reset() -> void:
	Game.reset_all()
	main.show_toast(I18n.t("reset_done"))


func on_back() -> bool:
	main.back_from_settings()
	return true
