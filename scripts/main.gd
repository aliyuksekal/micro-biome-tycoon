extends Control
## Ekran yöneticisi: arka plan, güvenli alan (kenardan kenara ekran), ekran geçişleri,
## açılır pencere yığını, bildirim balonu ve Android geri tuşu.

const Modal = preload("res://scripts/ui/modal.gd")
const SCREENS := {
	"intro": preload("res://scripts/screens/intro_screen.gd"),
	"menu": preload("res://scripts/screens/menu_screen.gd"),
	"game": preload("res://scripts/screens/game_screen.gd"),
	"settings": preload("res://scripts/screens/settings_screen.gd"),
	"about": preload("res://scripts/screens/about_screen.gd"),
}

var bg: TextureRect
var frame: MarginContainer
var modal_layer: Control
var toast_layer: Control
var screen: Control
var screen_name: String = ""
var _return_to: String = "menu"
var _toast_panel: PanelContainer
var _toast_label: Label
var _toast_tween: Tween


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.theme
	bg = TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	frame = MarginContainer.new()
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(frame)
	modal_layer = Control.new()
	modal_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(modal_layer)
	toast_layer = Control.new()
	toast_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	toast_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(toast_layer)
	_build_toast()
	_apply_bg()
	get_viewport().size_changed.connect(_update_safe_area)
	UiTheme.theme_changed.connect(_on_theme_changed)
	I18n.language_changed.connect(_rebuild_screen)
	Game.toast.connect(show_toast)
	_update_safe_area()
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for a in args:
		if a == "--selftest":
			var T = load("res://scripts/dev/selftest.gd")
			add_child(T.new())
			return
		if a.begins_with("--screenshots"):
			var S = load("res://scripts/dev/screenshots.gd")
			var n: Node = S.new()
			n.set_meta("out", a.get_slice("=", 1))
			add_child(n)
			return
	if not Settings.flag("intro_seen"):
		show_screen("intro")
	else:
		show_screen("menu")


func _apply_bg() -> void:
	bg.texture = Assets.bg_dark if UiTheme.dark else Assets.bg_light


func _on_theme_changed() -> void:
	theme = UiTheme.theme
	_apply_bg()
	_build_toast()
	_rebuild_screen()


func _rebuild_screen() -> void:
	if screen_name != "":
		show_screen(screen_name, true)


func _update_safe_area() -> void:
	## Kenardan kenara çizimde sistem çubukları ve çentik için güvenli alan boşluğu bırakır.
	var win: Vector2i = DisplayServer.window_get_size()
	var vp: Vector2 = get_viewport_rect().size
	var top := 0.0
	var bottom := 0.0
	var left := 0.0
	var right := 0.0
	if win.x > 0 and win.y > 0 and OS.has_feature("mobile"):
		var safe: Rect2i = DisplayServer.get_display_safe_area()
		var sx: float = vp.x / float(win.x)
		var sy: float = vp.y / float(win.y)
		top = safe.position.y * sy
		left = safe.position.x * sx
		right = maxf(0.0, (win.x - safe.end.x) * sx)
		bottom = maxf(0.0, (win.y - safe.end.y) * sy)
	frame.add_theme_constant_override("margin_top", int(top) + 8)
	frame.add_theme_constant_override("margin_bottom", int(bottom) + 8)
	frame.add_theme_constant_override("margin_left", int(left) + 12)
	frame.add_theme_constant_override("margin_right", int(right) + 12)


func show_screen(name_: String, rebuild: bool = false) -> void:
	if not SCREENS.has(name_):
		return
	if screen != null:
		if screen.has_method("on_leave"):
			screen.call("on_leave")
		screen.queue_free()
		screen = null
	close_all_modals()
	var Scr = SCREENS[name_]
	screen = Scr.new()
	screen.set("main", self)
	screen_name = name_
	frame.add_child(screen)
	if screen.has_method("build"):
		screen.call("build")
	if not rebuild:
		screen.modulate.a = 0.0
		create_tween().tween_property(screen, "modulate:a", 1.0, 0.18)


func open_settings(from: String) -> void:
	_return_to = from
	show_screen("settings")


func back_from_settings() -> void:
	show_screen(_return_to if _return_to != "settings" else "menu")


# ---------------- açılır pencereler ----------------
func new_modal(title_text: String = "", icon_name: String = "", max_width: float = 620.0) -> Control:
	var m = Modal.new()
	modal_layer.add_child(m)
	m.setup(title_text, icon_name, max_width)
	return m


func top_modal() -> Control:
	for i in range(modal_layer.get_child_count() - 1, -1, -1):
		var c: Node = modal_layer.get_child(i)
		if not c.is_queued_for_deletion() and not bool(c.get("_closing")):
			return c as Control
	return null


func has_modal() -> bool:
	return top_modal() != null


func close_all_modals() -> void:
	for c in modal_layer.get_children():
		if c.has_method("close"):
			c.call("close")
		else:
			c.queue_free()


func confirm(question: String, yes_text: String, yes_variant: String, on_yes: Callable) -> void:
	var m = new_modal(question, "alert")
	m.add_button(yes_text, yes_variant, on_yes)
	m.add_button(I18n.t("cancel"), "gray", Callable())


# ---------------- bildirim balonu ----------------
func _build_toast() -> void:
	if _toast_panel != null:
		_toast_panel.queue_free()
	_toast_panel = UiTheme.panel("panel", 40, 18)
	_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_label = UiTheme.label("", 26, "text")
	_toast_panel.add_child(_toast_label)
	_toast_panel.visible = false
	toast_layer.add_child(_toast_panel)


func show_toast(text: String) -> void:
	_toast_label.text = text
	_toast_panel.visible = true
	_toast_panel.reset_size()
	var vp: Vector2 = get_viewport_rect().size
	var top: float = float(frame.get_theme_constant("margin_top"))
	_toast_panel.position = Vector2((vp.x - _toast_panel.size.x) / 2.0, top + 150.0)
	_toast_panel.modulate.a = 0.0
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast_panel, "modulate:a", 1.0, 0.15)
	_toast_tween.tween_interval(1.8)
	_toast_tween.tween_property(_toast_panel, "modulate:a", 0.0, 0.3)
	_toast_tween.tween_callback(func() -> void: _toast_panel.visible = false)


# ---------------- Android geri tuşu ----------------
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		handle_back()


func _unhandled_input(ev: InputEvent) -> void:
	var k := ev as InputEventKey
	if k != null and k.pressed and not k.echo and k.keycode == KEY_ESCAPE:
		handle_back()


func _quit_game() -> void:
	Game.save_game()
	get_tree().quit()


func handle_back() -> void:
	var m: Control = top_modal()
	if m != null:
		if bool(m.get("dismissible")):
			m.call("close")
		return
	if screen != null and screen.has_method("on_back") and bool(screen.call("on_back")):
		return
	match screen_name:
		"menu":
			confirm(I18n.t("exit_q"), I18n.t("exit"), "red", _quit_game)
		"settings":
			back_from_settings()
		_:
			show_screen("menu")
