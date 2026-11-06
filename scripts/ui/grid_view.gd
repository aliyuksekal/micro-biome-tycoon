extends Control
## Oyun ızgarası. 35 karo düğümü bir kez oluşturulur (havuz); yalnızca değişen karolar güncellenir.
## Karakter animasyonu: idle 4 kare (≈6 fps), olaylarda happy / eating / damaged durumuna kısa geçiş.

signal tile_tapped(index: int)

const TILE_TEX := {"normal": "tile_pink", "boost": "tile_boost", "heal": "tile_heal", "block": "tile_block"}
const FLOATERS := 10
const EFFECTS := 8

var tiles: Array[Control] = []
var tile_size: float = 100.0
var origin: Vector2 = Vector2.ZERO
var _frame: int = 0
var _anim_timer: Timer
var _floaters: Array[Label] = []
var _effects: Array[TextureRect] = []
var _fl_next: int = 0
var _fx_next: int = 0
var _prod_tick: int = 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	clip_contents = false
	for i in Game.COLS * Game.ROWS:
		tiles.append(_make_tile(i))
	for i in EFFECTS:
		var fx := TextureRect.new()
		fx.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fx.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fx.visible = false
		add_child(fx)
		_effects.append(fx)
	for i in FLOATERS:
		var l := Label.new()
		l.add_theme_font_size_override("font_size", 28)
		l.add_theme_color_override("font_color", Color.WHITE)
		l.add_theme_color_override("font_outline_color", Color("5a1240"))
		l.add_theme_constant_override("outline_size", 10)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.visible = false
		add_child(l)
		_floaters.append(l)
	_anim_timer = Timer.new()
	_anim_timer.wait_time = 0.16
	_anim_timer.timeout.connect(_on_anim)
	add_child(_anim_timer)
	_anim_timer.start()
	resized.connect(_layout)
	Game.cell_changed.connect(refresh_tile)
	Game.cell_event.connect(_on_event)
	Game.run_reset.connect(refresh_all)
	Game.ticked.connect(_on_tick)
	_layout()
	refresh_all()


func _make_tile(i: int) -> Control:
	var t := Control.new()
	t.mouse_filter = Control.MOUSE_FILTER_STOP
	var base := TextureRect.new()
	base.name = "Base"
	base.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	base.stretch_mode = TextureRect.STRETCH_SCALE
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.add_child(base)
	var spr := TextureRect.new()
	spr.name = "Sprite"
	spr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	spr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	spr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.add_child(spr)
	var hp := ProgressBar.new()
	hp.name = "Hp"
	hp.show_percentage = false
	hp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp.add_theme_stylebox_override("background", UiTheme.box(Color(0, 0, 0, 0.45), 6, Color(0, 0, 0, 0), 0, 0, 0))
	hp.add_theme_stylebox_override("fill", UiTheme.box(Color("ff4d5e"), 6, Color(0, 0, 0, 0), 0, 0, 0))
	t.add_child(hp)
	var lv := Label.new()
	lv.name = "Level"
	lv.add_theme_font_size_override("font_size", 20)
	lv.add_theme_color_override("font_color", Color.WHITE)
	lv.add_theme_color_override("font_outline_color", Color("3a1630"))
	lv.add_theme_constant_override("outline_size", 8)
	lv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.add_child(lv)
	t.set_meta("index", i)
	t.set_meta("phase", i % 4)
	t.set_meta("state", "")
	t.set_meta("state_until", 0)
	t.gui_input.connect(_on_tile_input.bind(i))
	add_child(t)
	return t


func _on_tile_input(ev: InputEvent, i: int) -> void:
	if ev is InputEventMouseButton:
		var mb: InputEventMouseButton = ev
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			accept_event()
			tile_tapped.emit(i)


func _layout() -> void:
	var avail: Vector2 = size
	tile_size = floorf(minf(avail.x / Game.COLS, avail.y / (Game.ROWS + 0.35)))
	tile_size = maxf(tile_size, 40.0)
	var grid_size := Vector2(tile_size * Game.COLS, tile_size * Game.ROWS)
	origin = Vector2(floorf((avail.x - grid_size.x) / 2.0), floorf((avail.y - grid_size.y) / 2.0 + tile_size * 0.15))
	for i in tiles.size():
		var t: Control = tiles[i]
		var x: int = i % Game.COLS
		var y: int = int(i / Game.COLS)
		t.position = origin + Vector2(x * tile_size, y * tile_size)
		t.size = Vector2(tile_size, tile_size)
		var base: TextureRect = t.get_node("Base")
		var pad: float = tile_size * 0.04
		base.position = Vector2(pad, pad)
		base.size = Vector2(tile_size - pad * 2, tile_size - pad * 2)
		var spr: TextureRect = t.get_node("Sprite")
		var s: float = tile_size * 1.22
		spr.size = Vector2(s, s)
		# pivot: ayak tabanı (0.5, 0.95) karonun alt-ortasına yakın oturur
		spr.position = Vector2((tile_size - s) / 2.0, tile_size * 0.94 - s * 0.95)
		spr.pivot_offset = Vector2(s * 0.5, s * 0.95)
		var hp: ProgressBar = t.get_node("Hp")
		hp.position = Vector2(tile_size * 0.15, tile_size * 0.86)
		hp.size = Vector2(tile_size * 0.7, maxf(6.0, tile_size * 0.08))
		var lv: Label = t.get_node("Level")
		lv.position = Vector2(tile_size * 0.06, tile_size * 0.0)
		lv.add_theme_font_size_override("font_size", int(clampf(tile_size * 0.2, 14, 26)))


func refresh_all() -> void:
	for i in tiles.size():
		refresh_tile(i)


func refresh_tile(i: int) -> void:
	if i < 0 or i >= tiles.size():
		return
	var t: Control = tiles[i]
	var c: Dictionary = Game.cells[i]
	var kind: String = str(c["kind"])
	var base: TextureRect = t.get_node("Base")
	base.texture = Assets.env.get(TILE_TEX.get(Game.tiles[i], "tile_pink"), null)
	base.modulate = UiTheme.c("tile_tint")
	var spr: TextureRect = t.get_node("Sprite")
	var hp: ProgressBar = t.get_node("Hp")
	var lv: Label = t.get_node("Level")
	if kind == "":
		spr.visible = false
		hp.visible = false
		lv.visible = false
		return
	spr.visible = true
	_apply_frame(t, kind)
	var mx: float = maxf(1.0, float(c["max_hp"]))
	hp.max_value = mx
	hp.value = float(c["hp"])
	hp.visible = Game.is_bad(kind) or float(c["hp"]) < mx - 0.01
	var lvl: int = int(c["level"])
	lv.visible = Game.is_good(kind) and lvl > 1
	lv.text = I18n.t("lv_short", {"v": lvl})


func _apply_frame(t: Control, kind: String) -> void:
	var spr: TextureRect = t.get_node("Sprite")
	var st: String = str(t.get_meta("state"))
	if st != "" and Time.get_ticks_msec() < int(t.get_meta("state_until")):
		spr.texture = Assets.char_tex(kind, st)
	else:
		t.set_meta("state", "")
		var f: int = (_frame + int(t.get_meta("phase"))) % 4
		spr.texture = Assets.char_tex(kind, "idle_%d" % f)


func _on_anim() -> void:
	_frame = (_frame + 1) % 4
	for i in tiles.size():
		var kind: String = str(Game.cells[i]["kind"])
		if kind != "":
			_apply_frame(tiles[i], kind)


func play_state(i: int, state: String, ms: int = 450) -> void:
	var t: Control = tiles[i]
	t.set_meta("state", state)
	t.set_meta("state_until", Time.get_ticks_msec() + ms)
	var kind: String = str(Game.cells[i]["kind"])
	if kind != "":
		_apply_frame(t, kind)
	var spr: TextureRect = t.get_node("Sprite")
	var tw := create_tween()
	match state:
		"damaged":
			tw.tween_property(spr, "rotation", -0.12, 0.05)
			tw.tween_property(spr, "rotation", 0.10, 0.07)
			tw.tween_property(spr, "rotation", 0.0, 0.06)
		"happy":
			tw.tween_property(spr, "scale", Vector2(0.94, 1.08), 0.09)
			tw.tween_property(spr, "scale", Vector2(1.04, 0.97), 0.09)
			tw.tween_property(spr, "scale", Vector2.ONE, 0.1)
		"eating":
			tw.tween_property(spr, "scale", Vector2(1.08, 0.92), 0.08)
			tw.tween_property(spr, "scale", Vector2(0.97, 1.03), 0.08)
			tw.tween_property(spr, "scale", Vector2(1.06, 0.94), 0.08)
			tw.tween_property(spr, "scale", Vector2.ONE, 0.1)
		_:
			tw.tween_property(spr, "scale", Vector2(1.12, 1.12), 0.08)
			tw.tween_property(spr, "scale", Vector2.ONE, 0.12)


func tile_center(i: int) -> Vector2:
	return tiles[i].position + Vector2(tile_size / 2.0, tile_size / 2.0)


func floater(i: int, text: String, color: Color = Color.WHITE) -> void:
	var l: Label = _floaters[_fl_next]
	_fl_next = (_fl_next + 1) % _floaters.size()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", int(clampf(tile_size * 0.28, 18, 34)))
	l.reset_size()
	l.visible = true
	l.modulate.a = 1.0
	var p0: Vector2 = tile_center(i) - Vector2(l.size.x / 2.0, tile_size * 0.6)
	l.position = p0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(l, "position", p0 - Vector2(0, tile_size * 0.6), 0.8).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.8).set_delay(0.25)
	tw.chain().tween_callback(func() -> void: l.visible = false)


func effect(i: int, fx_name: String, scale_f: float = 0.7) -> void:
	var fx: TextureRect = _effects[_fx_next]
	_fx_next = (_fx_next + 1) % _effects.size()
	fx.texture = Assets.vfx.get(fx_name, null)
	var s: float = tile_size * scale_f
	fx.size = Vector2(s, s)
	fx.pivot_offset = Vector2(s / 2.0, s / 2.0)
	fx.position = tile_center(i) - Vector2(s / 2.0, s * 0.7)
	fx.scale = Vector2(0.4, 0.4)
	fx.modulate.a = 1.0
	fx.visible = true
	var tw := create_tween().set_parallel(true)
	tw.tween_property(fx, "scale", Vector2(1.2, 1.2), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(fx, "modulate:a", 0.0, 0.3).set_delay(0.25)
	tw.chain().tween_callback(func() -> void: fx.visible = false)


func _on_event(i: int, kind: String) -> void:
	match kind:
		"hit":
			play_state(i, "damaged", 380)
			effect(i, "hit", 0.6)
			floater(i, "-" + Game.fmt(Game.tap_damage()), Color("ffe08a"))
			Sfx.play("hit")
			Sfx.vibrate(18)
		"defeat":
			effect(i, "sparkle", 0.9)
			floater(i, "+%d %s" % [Game.last_defeat_fiber, I18n.t("fiber")], Color("b8ff9a"))
			Sfx.play("defeat")
			Sfx.vibrate(35)
		"place":
			play_state(i, "happy", 600)
			effect(i, "sparkle", 0.8)
			Sfx.play("place")
		"feed":
			play_state(i, "eating", 700)
			effect(i, "heart", 0.6)
			Sfx.play("eat")
		"spawn", "spread":
			effect(i, "hit", 0.5)
		"lost":
			effect(i, "bubble", 0.7)
			Sfx.play("hit", -6.0)


func _on_tick() -> void:
	# her saniye bir koloni üzerinde üretim balonu (hafif, tek etiket)
	_prod_tick += 1
	var goods: Array[int] = []
	for i in Game.cells.size():
		if Game.is_good(str(Game.cells[i]["kind"])):
			goods.append(i)
	if goods.is_empty():
		return
	var i: int = goods[_prod_tick % goods.size()]
	var v: float = Game.cell_production(i) * Game.diversity_mult()
	if Game.boost_active():
		v *= 2.0
	floater(i, "+" + Game.fmt(v), Color("fff3b0"))
	if _prod_tick % 5 == 0:
		play_state(i, "happy", 500)
