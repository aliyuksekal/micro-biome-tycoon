extends Control
## Hakkında: kurgu/sağlık uyarısı, veri politikası, geliştirici, lisanslar.

const CONTACT := "mailto:matali.truz@gmail.com"

var main


func build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var root := UiTheme.vbox(12)
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var h := UiTheme.hbox(12)
	var back := UiTheme.button(I18n.t("back"), "gray", "", 76, 24)
	back.name = "BackButton"
	back.pressed.connect(func() -> void: main.show_screen("menu"))
	h.add_child(back)
	var t := UiTheme.title(I18n.t("about"), 48, Color.WHITE, Color("6a1fb0"), 12)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(t)
	var dummy := Control.new()
	dummy.custom_minimum_size = Vector2(back.get_combined_minimum_size().x, 0)
	h.add_child(dummy)
	root.add_child(h)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var col := UiTheme.vbox(16)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(col)
	var pc := UiTheme.panel("panel", 28, 24)
	var v := UiTheme.vbox(16)
	pc.add_child(v)
	col.add_child(pc)
	var row := UiTheme.hbox(0)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for id in ["lactobacillus", "pathogen", "e_faecalis"]:
		row.add_child(UiTheme.portrait(id, 130))
	v.add_child(row)
	v.add_child(UiTheme.label(I18n.t("app_title"), 40, "text"))
	v.add_child(UiTheme.label(I18n.t("version", {"v": str(ProjectSettings.get_setting("application/config/version", "1.0.0"))}), 22, "text_dim"))
	v.add_child(UiTheme.label(I18n.t("about_body"), 25, "text", HORIZONTAL_ALIGNMENT_CENTER, true))
	v.add_child(UiTheme.label(I18n.t("about_data"), 25, "text_dim", HORIZONTAL_ALIGNMENT_CENTER, true))
	v.add_child(UiTheme.label(I18n.t("developer"), 26, "text"))
	var mail := UiTheme.button(I18n.t("contact") + ": matali.truz@gmail.com", "blue", "info", 80, 22)
	mail.pressed.connect(func() -> void: OS.shell_open(CONTACT))
	v.add_child(mail)
	var pv := UiTheme.button(I18n.t("privacy"), "purple", "shield_badge", 80, 24)
	pv.pressed.connect(func() -> void: OS.shell_open("https://aliyuksekal.github.io/gizlilik/micro-biome-tycoon-gizlilik.html"))
	v.add_child(pv)
	var lic := UiTheme.button("Open source licenses", "gray", "", 72, 22)
	lic.name = "LicensesButton"
	lic.pressed.connect(_show_licenses)
	v.add_child(lic)
	v.add_child(UiTheme.label(I18n.t("engine"), 20, "text_dim"))
	col.add_child(UiTheme.spacer(20))


func _show_licenses() -> void:
	var m = main.new_modal("Licenses", "", 680.0)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, minf(820.0, get_viewport_rect().size.y * 0.6))
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var l := UiTheme.label("", 16, "text_dim", HORIZONTAL_ALIGNMENT_LEFT, true)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var txt := "Godot Engine — MIT License\n\n" + Engine.get_license_text()
	txt += "\n\nNunito font — SIL Open Font License 1.1, Copyright The Nunito Project Authors."
	txt += "\n\nCharacter artwork: original concept art supplied by the developer (matali)."
	l.text = txt
	sc.add_child(l)
	m.add(sc)
	m.add_button(I18n.t("close"), "gray", Callable())
