extends Control
## İlk açılış tanıtımı (4 sayfa). Kaydırma veya düğmelerle ilerler.

var main
var page: int = 0
var _card: VBoxContainer
var _dots: HBoxContainer
var _next: Button
var _drag_start: Vector2 = Vector2.ZERO

const PAGES := [
	{"t": "intro1_t", "b": "intro1_b", "chars": ["lactobacillus", "bifidobacterium"]},
	{"t": "intro2_t", "b": "intro2_b", "chars": ["streptococcus"], "icon": "coin"},
	{"t": "intro3_t", "b": "intro3_b", "chars": ["pathogen"], "icon": "fiber"},
	{"t": "intro4_t", "b": "intro4_b", "chars": ["e_faecalis", "inflammatory"], "icon": "shield"},
]


func build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var root := UiTheme.vbox(18)
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var top := UiTheme.hbox(0)
	top.add_child(UiTheme.hspacer())
	var skip := UiTheme.button(I18n.t("skip"), "gray", "", 72, 24)
	skip.name = "SkipButton"
	skip.pressed.connect(_finish)
	top.add_child(skip)
	root.add_child(top)
	root.add_child(UiTheme.spacer(4, true))
	var panel := UiTheme.panel("panel", 36, 28)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.custom_minimum_size = Vector2(minf(600.0, get_viewport_rect().size.x - 40.0), 640)
	_card = UiTheme.vbox(18)
	panel.add_child(_card)
	root.add_child(panel)
	_dots = UiTheme.hbox(12)
	_dots.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(_dots)
	_next = UiTheme.button(I18n.t("next"), "primary", "play", 104, 34)
	_next.name = "NextButton"
	_next.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_next.custom_minimum_size.x = 420
	_next.pressed.connect(next_page)
	root.add_child(_next)
	root.add_child(UiTheme.spacer(16, true))
	_show()


func _show() -> void:
	for c in _card.get_children():
		c.queue_free()
	var pg: Dictionary = PAGES[page]
	var row := UiTheme.hbox(0)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for id in pg["chars"]:
		row.add_child(UiTheme.portrait(str(id), 230.0 if pg["chars"].size() == 1 else 200.0))
	_card.add_child(row)
	if pg.has("icon"):
		var ic := UiTheme.icon(str(pg["icon"]), 70)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_card.add_child(ic)
	_card.add_child(UiTheme.label(I18n.t(str(pg["t"])), 38, "text", HORIZONTAL_ALIGNMENT_CENTER, true))
	_card.add_child(UiTheme.label(I18n.t(str(pg["b"])), 28, "text_dim", HORIZONTAL_ALIGNMENT_CENTER, true))
	for c in _dots.get_children():
		c.queue_free()
	for i in PAGES.size():
		var d := Panel.new()
		d.custom_minimum_size = Vector2(36 if i == page else 16, 16)
		d.add_theme_stylebox_override("panel", UiTheme.box(Color.WHITE if i == page else Color(1, 1, 1, 0.5), 8))
		_dots.add_child(d)
	_next.text = I18n.t("start") if page == PAGES.size() - 1 else I18n.t("next")


func next_page() -> void:
	if page >= PAGES.size() - 1:
		_finish()
		return
	page += 1
	_show()


func prev_page() -> void:
	if page > 0:
		page -= 1
		_show()


func _finish() -> void:
	Settings.set_value("intro_seen", true)
	main.show_screen("menu")


func _gui_input(ev: InputEvent) -> void:
	var mb := ev as InputEventMouseButton
	if mb == null or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if mb.pressed:
		_drag_start = mb.position
	else:
		var dx: float = mb.position.x - _drag_start.x
		if dx < -90.0:
			next_page()
		elif dx > 90.0:
			prev_page()


func on_back() -> bool:
	if page > 0:
		prev_page()
		return true
	return false
