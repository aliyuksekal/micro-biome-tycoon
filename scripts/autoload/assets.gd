extends Node
## Tüm dokular oyun başında bir kez yüklenir ve önbellekte tutulur.
## Oyun sırasında dosyadan tekrar yükleme yapılmaz.

const CHAR_IDS: Array[String] = ["lactobacillus", "bifidobacterium", "streptococcus", "e_faecalis", "pathogen", "inflammatory", "c_difficile"]
const STATES: Array[String] = ["idle_0", "idle_1", "idle_2", "idle_3", "happy", "eating", "damaged"]
const UI_ICONS: Array[String] = ["coin", "gem", "heart", "gear", "trophy", "star", "shield_badge", "alert", "check", "pause", "play", "info", "fiber", "glucose", "prebiotic", "nutrient_drop", "growth_boost", "shield", "healing", "energy", "gift", "gut", "crown", "dna"]
const ENV: Array[String] = ["tile_pink", "tile_green", "tile_orange", "tile_purple", "tile_blue", "tile_block", "tile_boost", "tile_heal", "tile_danger", "coral_pink", "tubes_green", "coral_purple", "plants"]
const VFX: Array[String] = ["sparkle", "bubble", "plus", "heart", "hit"]

var chars: Dictionary = {}      # id -> {state -> Texture2D}
var portraits: Dictionary = {}  # id -> 512px Texture2D
var ui: Dictionary = {}
var env: Dictionary = {}
var vfx: Dictionary = {}
var bg_light: Texture2D
var bg_dark: Texture2D
var font: Font
var missing: Array[String] = []


func _ready() -> void:
	for id in CHAR_IDS:
		var states: Dictionary = {}
		for s in STATES:
			states[s] = _tex("res://assets/characters/%s/%s.png" % [id, s])
		chars[id] = states
		portraits[id] = _tex("res://assets/characters/%s.png" % id)
	for n in UI_ICONS:
		ui[n] = _tex("res://assets/ui/%s.png" % n)
	for n in ENV:
		env[n] = _tex("res://assets/environment/%s.png" % n)
	for n in VFX:
		vfx[n] = _tex("res://assets/vfx/%s.png" % n)
	bg_light = _tex("res://assets/environment/gut_bg_light.jpg")
	bg_dark = _tex("res://assets/environment/gut_bg_dark.jpg")
	font = _make_font()


func _tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var t: Texture2D = load(path) as Texture2D
		if t != null:
			return t
	missing.append(path)
	push_warning("Eksik doku: " + path)
	return PlaceholderTexture2D.new()


func char_tex(id: String, state: String) -> Texture2D:
	var d: Dictionary = chars.get(id, {})
	return d.get(state, null)


func _make_font() -> Font:
	# Nunito (OFL) derleme sırasında indirilir; yoksa motorun varsayılan fontu kullanılır.
	# Çince/Korece gibi eksik glifler için sistem fontlarına geri dönülür.
	var sys := SystemFont.new()
	sys.font_names = PackedStringArray(["Noto Sans CJK SC", "Noto Sans CJK KR", "Noto Sans", "Roboto", "sans-serif"])
	var path := "res://assets/fonts/Nunito.ttf"
	if ResourceLoader.exists(path):
		var f: FontFile = load(path) as FontFile
		if f != null:
			var v := FontVariation.new()
			v.base_font = f
			var ts: TextServer = TextServerManager.get_primary_interface()
			v.variation_opentype = {ts.name_to_tag("wght"): 800}
			var fb: Array[Font] = [sys]
			f.fallbacks = fb
			return v
	return sys
