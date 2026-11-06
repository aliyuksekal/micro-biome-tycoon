extends Node
## Oyun modeli ve simülasyon. Simülasyon sabit 1 saniyelik adımlarla çalışır;
## her adımda yalnızca değişen hücreler için sinyal yayınlanır.
## Kayıt: sürümlü JSON, atomik yazma (.tmp -> yeniden adlandırma) ve .bak yedeği.

signal ticked
signal cell_changed(index: int)
signal cell_event(index: int, kind: String)
signal toast(text: String)
signal over
signal species_unlocked(id: String)
signal resources_changed
signal run_reset

const COLS := 5
const ROWS := 7
const SAVE_PATH := "user://save.json"
const BAK_PATH := "user://save.bak"
const TMP_PATH := "user://save.tmp"
const SAVE_VERSION := 1
const GIFT_COOLDOWN := 4.0 * 3600.0
const GIFT_BOOST := 120.0
const BASE_OFFLINE_HOURS := 2
const OFFLINE_EFFICIENCY := 0.5
const MAX_LEVEL := 5
const GRACE_SECONDS := 35.0
const MAX_BAD := 10

const GOOD: Array[String] = ["lactobacillus", "bifidobacterium", "streptococcus", "e_faecalis"]
const BAD: Array[String] = ["pathogen", "inflammatory", "c_difficile"]

const SPECIES := {
	"lactobacillus": {"cost": 15.0, "prod": 1.0, "unlock": 0.0, "hp": 20.0, "heal": 0.0},
	"bifidobacterium": {"cost": 120.0, "prod": 6.0, "unlock": 80.0, "hp": 30.0, "heal": 0.04},
	"streptococcus": {"cost": 650.0, "prod": 28.0, "unlock": 700.0, "hp": 40.0, "heal": 0.0, "attack": 1.5},
	"e_faecalis": {"cost": 3200.0, "prod": 110.0, "unlock": 4000.0, "hp": 60.0, "heal": 0.02, "shield": true},
	"pathogen": {"hp": 10.0, "drain": 0.22, "spread": 26.0, "reward": 1},
	"inflammatory": {"hp": 26.0, "drain": 0.40, "spread": 34.0, "reward": 3, "hurt": 1.2},
	"c_difficile": {"hp": 70.0, "drain": 0.70, "spread": 16.0, "reward": 8},
}

const UPGRADES := {
	"tap": {"base": 60.0, "mult": 2.1, "max": 25},
	"prod": {"base": 200.0, "mult": 2.3, "max": 30},
	"immune": {"base": 350.0, "mult": 2.5, "max": 20},
	"barrier": {"base": 400.0, "mult": 2.6, "max": 8},
	"offline": {"base": 500.0, "mult": 3.0, "max": 6},
}

# --- durum ---
var nutrients: float = 20.0
var fiber: int = 0
var barrier: float = 100.0
var run_earned: float = 0.0
var lifetime_earned: float = 0.0
var best_score: float = 0.0
var cells: Array[Dictionary] = []
var tiles: Array[String] = []
var upgrades: Dictionary = {}
var unlocked: Array[String] = ["lactobacillus"]
var seen_threats: Array[String] = []
var run_time: float = 0.0
var boost_until: float = 0.0
var last_gift: float = -GIFT_COOLDOWN
var last_active: float = 0.0
var rocks_cleared: int = 0
var spawn_timer: float = GRACE_SECONDS
var immune_timer: float = 5.0
var is_over: bool = false
var running: bool = false
var has_save: bool = false
var selected: String = "lactobacillus"
var pending_offline: Dictionary = {}
var last_defeat_fiber: int = 1

var rng := RandomNumberGenerator.new()
var _tick_timer: Timer
var _save_timer: Timer
var _dirty: bool = false
var _barrier_warned: bool = false
var _last_barrier_delta: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	rng.randomize()
	_tick_timer = Timer.new()
	_tick_timer.wait_time = 1.0
	_tick_timer.timeout.connect(_on_tick)
	add_child(_tick_timer)
	_tick_timer.start()
	_save_timer = Timer.new()
	_save_timer.wait_time = 15.0
	_save_timer.timeout.connect(_on_save_timer)
	add_child(_save_timer)
	_save_timer.start()
	for k in UPGRADES.keys():
		upgrades[k] = 0
	if not load_game():
		new_run(true)
	else:
		_compute_offline()


# ---------------- yardımcılar ----------------
static func now_unix() -> float:
	return Time.get_unix_time_from_system()


func index_of(x: int, y: int) -> int:
	return y * COLS + x


func neighbors(i: int) -> Array[int]:
	var out: Array[int] = []
	var x: int = i % COLS
	var y: int = int(i / COLS)
	if x > 0: out.append(i - 1)
	if x < COLS - 1: out.append(i + 1)
	if y > 0: out.append(i - COLS)
	if y < ROWS - 1: out.append(i + COLS)
	return out


func is_good(kind: String) -> bool:
	return kind in GOOD


func is_bad(kind: String) -> bool:
	return kind in BAD


func empty_cell() -> Dictionary:
	return {"kind": "", "level": 1, "hp": 0.0, "max_hp": 0.0, "spread": 0.0}


func is_shielded(i: int) -> bool:
	for n in neighbors(i):
		if str(cells[n]["kind"]) == "e_faecalis":
			return true
	return false


func count_of(kind: String) -> int:
	var n: int = 0
	for c in cells:
		if str(c["kind"]) == kind:
			n += 1
	return n


func good_count() -> int:
	var n: int = 0
	for c in cells:
		if is_good(str(c["kind"])):
			n += 1
	return n


func bad_count() -> int:
	var n: int = 0
	for c in cells:
		if is_bad(str(c["kind"])):
			n += 1
	return n


func diversity() -> int:
	var n: int = 0
	for g in GOOD:
		if count_of(g) > 0:
			n += 1
	return n


func diversity_mult() -> float:
	return 1.0 + 0.15 * maxi(0, diversity() - 1)


func boost_active() -> bool:
	return now_unix() < boost_until


func boost_remaining() -> float:
	return maxf(0.0, boost_until - now_unix())


func cell_production(i: int) -> float:
	var c: Dictionary = cells[i]
	var kind: String = str(c["kind"])
	if not is_good(kind):
		return 0.0
	var sp: Dictionary = SPECIES[kind]
	var v: float = float(sp["prod"]) * pow(1.6, int(c["level"]) - 1)
	if tiles[i] == "boost":
		v *= 2.0
	return v


func production_per_sec(include_boost: bool = true) -> float:
	var total: float = 0.0
	for i in cells.size():
		total += cell_production(i)
	total *= diversity_mult() * (1.0 + 0.15 * int(upgrades.get("prod", 0)))
	if include_boost and boost_active():
		total *= 2.0
	return total


func species_cost(kind: String) -> float:
	var sp: Dictionary = SPECIES[kind]
	return floor(float(sp["cost"]) * pow(1.18, count_of(kind)))


func upgrade_cost(id: String) -> float:
	var u: Dictionary = UPGRADES[id]
	return floor(float(u["base"]) * pow(float(u["mult"]), int(upgrades.get(id, 0))))


func upgrade_maxed(id: String) -> bool:
	var u: Dictionary = UPGRADES[id]
	return int(upgrades.get(id, 0)) >= int(u["max"])


func tap_damage() -> float:
	return 1.0 + int(upgrades.get("tap", 0))


func feed_cost(i: int) -> int:
	return int(cells[i]["level"]) * 2


func rock_cost() -> float:
	return 150.0 * pow(2.0, rocks_cleared)


func remove_refund(i: int) -> float:
	var kind: String = str(cells[i]["kind"])
	if not is_good(kind):
		return 0.0
	var sp: Dictionary = SPECIES[kind]
	return floor(float(sp["cost"]) * 0.4)


func offline_cap_hours() -> int:
	return BASE_OFFLINE_HOURS + int(upgrades.get("offline", 0))


func gift_remaining() -> float:
	var now: float = now_unix()
	if now < last_gift:  # saat geri alınmış: bekleme süresini şimdiden başlat
		last_gift = now
	return maxf(0.0, last_gift + GIFT_COOLDOWN - now)


func barrier_delta() -> float:
	return _last_barrier_delta


# ---------------- oyun akışı ----------------
func new_run(first: bool = false) -> void:
	nutrients = 20.0
	barrier = 100.0
	run_earned = 0.0
	run_time = 0.0
	spawn_timer = GRACE_SECONDS
	immune_timer = 5.0
	is_over = false
	rocks_cleared = 0
	seen_threats.clear()
	_barrier_warned = false
	cells.clear()
	for i in COLS * ROWS:
		cells.append(empty_cell())
	_make_tiles()
	if first:
		fiber = 0
	selected = "lactobacillus"
	_dirty = true
	run_reset.emit()
	resources_changed.emit()
	save_game()


func _make_tiles() -> void:
	tiles.clear()
	for i in COLS * ROWS:
		tiles.append("normal")
	var center: int = index_of(2, 3)
	var pool: Array[int] = []
	for i in COLS * ROWS:
		if i != center:
			pool.append(i)
	# karıştır
	for i in range(pool.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: int = pool[i]
		pool[i] = pool[j]
		pool[j] = tmp
	var plan: Array[String] = ["boost", "boost", "heal", "heal", "block", "block", "block"]
	for k in plan.size():
		tiles[pool[k]] = plan[k]


func start() -> void:
	running = true


func stop() -> void:
	running = false
	save_game()


func _on_tick() -> void:
	if running and not is_over:
		step(1.0)


func step(dt: float) -> void:
	var changed: Dictionary = {}
	run_time += dt
	# 1) üretim
	var prod: float = production_per_sec() * dt
	_earn(prod)
	# 2) iyi bakterilerin etkileri
	var heal: float = 0.0
	for i in cells.size():
		var c: Dictionary = cells[i]
		var kind: String = str(c["kind"])
		if is_good(kind):
			var sp: Dictionary = SPECIES[kind]
			heal += float(sp.get("heal", 0.0)) * int(c["level"])
			if tiles[i] == "heal":
				heal += 0.05
			if sp.has("attack"):
				for n in neighbors(i):
					if is_bad(str(cells[n]["kind"])):
						_damage(n, float(sp["attack"]) * int(c["level"]) * dt, changed, false)
	# 3) bağışıklık devriyesi
	var immune_lv: int = int(upgrades.get("immune", 0))
	if immune_lv > 0:
		immune_timer -= dt
		if immune_timer <= 0.0:
			immune_timer = 5.0
			for i in cells.size():
				if is_bad(str(cells[i]["kind"])):
					_damage(i, float(immune_lv), changed, false)
	# 4) kötü mikroplar: bariyer, yayılma, komşuya zarar
	var drain: float = 0.0
	var spreads: Array = []
	for i in cells.size():
		var c: Dictionary = cells[i]
		var kind: String = str(c["kind"])
		if not is_bad(kind):
			continue
		var sp: Dictionary = SPECIES[kind]
		drain += float(sp["drain"])
		if sp.has("hurt"):
			for n in neighbors(i):
				if is_good(str(cells[n]["kind"])):
					cells[n]["hp"] = float(cells[n]["hp"]) - float(sp["hurt"]) * dt
					changed[n] = true
					if float(cells[n]["hp"]) <= 0.0:
						cells[n] = empty_cell()
						cell_event.emit(n, "lost")
		c["spread"] = float(c["spread"]) - dt
		if float(c["spread"]) <= 0.0:
			c["spread"] = float(sp["spread"]) * rng.randf_range(0.8, 1.2)
			spreads.append([i, kind])
	for s in spreads:
		var src: int = s[0]
		var targets: Array[int] = []
		for n in neighbors(src):
			if str(cells[n]["kind"]) == "" and tiles[n] != "block" and not is_shielded(n):
				targets.append(n)
		if targets.size() > 0 and bad_count() < MAX_BAD:
			var t: int = targets[rng.randi_range(0, targets.size() - 1)]
			_spawn_bad(t, str(s[1]))
			changed[t] = true
			cell_event.emit(t, "spread")
	# 5) yeni tehdit doğması
	if good_count() > 0:
		spawn_timer -= dt
		if spawn_timer <= 0.0:
			spawn_timer = maxf(10.0, 32.0 - run_time / 60.0 * 1.5) * rng.randf_range(0.85, 1.15)
			_try_spawn(changed)
	# 6) bariyer
	var mitig: float = 1.0 - 0.1 * int(upgrades.get("barrier", 0))
	var base_regen: float = 0.03 if bad_count() == 0 else 0.0
	_last_barrier_delta = base_regen + heal - drain * mitig
	barrier = clampf(barrier + _last_barrier_delta * dt, 0.0, 100.0)
	if barrier < 25.0 and not _barrier_warned:
		_barrier_warned = true
		toast.emit(I18n.t("toast_barrier_low"))
		Sfx.play("alert")
	elif barrier > 40.0:
		_barrier_warned = false
	for k in changed.keys():
		cell_changed.emit(int(k))
	_dirty = true
	ticked.emit()
	resources_changed.emit()
	if barrier <= 0.0 and not is_over:
		_game_over()


func _earn(v: float) -> void:
	if v <= 0.0:
		return
	nutrients += v
	run_earned += v
	lifetime_earned += v
	for g in GOOD:
		if not (g in unlocked) and lifetime_earned >= float(SPECIES[g]["unlock"]):
			unlocked.append(g)
			species_unlocked.emit(g)
			toast.emit(I18n.t("toast_unlocked", {"v": I18n.t("sp_" + g)}))
			Sfx.play("levelup")


func _try_spawn(changed: Dictionary) -> void:
	if bad_count() >= MAX_BAD:
		return
	var free: Array[int] = []
	for i in cells.size():
		if str(cells[i]["kind"]) == "" and tiles[i] != "block" and not is_shielded(i):
			free.append(i)
	if free.is_empty():
		return
	var kind: String = "pathogen"
	var r: float = rng.randf()
	if (diversity() <= 1 and good_count() >= 6 and r < 0.25) or (run_time > 600.0 and r < 0.08):
		kind = "c_difficile"
	elif bad_count() >= 3 and r < 0.35:
		kind = "inflammatory"
	var t: int = free[rng.randi_range(0, free.size() - 1)]
	_spawn_bad(t, kind)
	changed[t] = true
	cell_event.emit(t, "spawn")
	if not (kind in seen_threats):
		seen_threats.append(kind)
		toast.emit(I18n.t("toast_threat", {"v": I18n.t("sp_" + kind)}))
		Sfx.play("alert")


func _spawn_bad(i: int, kind: String) -> void:
	var sp: Dictionary = SPECIES[kind]
	var hp: float = float(sp["hp"]) * (1.0 + run_time / 900.0)
	cells[i] = {"kind": kind, "level": 1, "hp": hp, "max_hp": hp, "spread": float(sp["spread"]) * rng.randf_range(0.9, 1.3)}


func _damage(i: int, dmg: float, changed: Dictionary, by_tap: bool) -> void:
	var c: Dictionary = cells[i]
	c["hp"] = float(c["hp"]) - dmg
	changed[i] = true
	if float(c["hp"]) <= 0.0:
		var kind: String = str(c["kind"])
		var sp: Dictionary = SPECIES[kind]
		var reward: float = maxf(5.0, production_per_sec(false) * 3.0) * int(sp["reward"])
		_earn(reward)
		fiber += int(sp["reward"])
		last_defeat_fiber = int(sp["reward"])
		cells[i] = empty_cell()
		cell_event.emit(i, "defeat")
	elif by_tap:
		cell_event.emit(i, "hit")


func _game_over() -> void:
	is_over = true
	running = false
	best_score = maxf(best_score, run_earned)
	save_game()
	over.emit()


# ---------------- oyuncu eylemleri ----------------
func can_place(i: int, kind: String) -> bool:
	return str(cells[i]["kind"]) == "" and tiles[i] != "block" and (kind in unlocked) and nutrients >= species_cost(kind)


func place(i: int, kind: String) -> bool:
	if not can_place(i, kind):
		return false
	nutrients -= species_cost(kind)
	var sp: Dictionary = SPECIES[kind]
	cells[i] = {"kind": kind, "level": 1, "hp": float(sp["hp"]), "max_hp": float(sp["hp"]), "spread": 0.0}
	_dirty = true
	cell_changed.emit(i)
	cell_event.emit(i, "place")
	resources_changed.emit()
	return true


func hit(i: int) -> void:
	if not is_bad(str(cells[i]["kind"])):
		return
	var changed: Dictionary = {}
	_damage(i, tap_damage(), changed, true)
	for k in changed.keys():
		cell_changed.emit(int(k))
	resources_changed.emit()


func feed(i: int) -> bool:
	var c: Dictionary = cells[i]
	if not is_good(str(c["kind"])) or int(c["level"]) >= MAX_LEVEL:
		return false
	var cost: int = feed_cost(i)
	if fiber < cost:
		return false
	fiber -= cost
	c["level"] = int(c["level"]) + 1
	c["max_hp"] = float(SPECIES[str(c["kind"])]["hp"]) * int(c["level"])
	c["hp"] = float(c["max_hp"])
	_dirty = true
	cell_changed.emit(i)
	cell_event.emit(i, "feed")
	resources_changed.emit()
	return true


func remove_colony(i: int) -> void:
	if not is_good(str(cells[i]["kind"])):
		return
	nutrients += remove_refund(i)
	cells[i] = empty_cell()
	_dirty = true
	cell_changed.emit(i)
	resources_changed.emit()


func clear_rock(i: int) -> bool:
	if tiles[i] != "block" or nutrients < rock_cost():
		return false
	nutrients -= rock_cost()
	rocks_cleared += 1
	tiles[i] = "normal"
	_dirty = true
	cell_changed.emit(i)
	resources_changed.emit()
	return true


func buy_upgrade(id: String) -> bool:
	if upgrade_maxed(id) or nutrients < upgrade_cost(id):
		return false
	nutrients -= upgrade_cost(id)
	upgrades[id] = int(upgrades.get(id, 0)) + 1
	_dirty = true
	resources_changed.emit()
	return true


func claim_gift() -> bool:
	if gift_remaining() > 0.0:
		return false
	last_gift = now_unix()
	boost_until = now_unix() + GIFT_BOOST
	fiber += 5
	_dirty = true
	resources_changed.emit()
	save_game()
	return true


func revive() -> void:
	nutrients = floor(nutrients * 0.5)
	barrier = 50.0
	for i in cells.size():
		if is_bad(str(cells[i]["kind"])):
			cells[i] = empty_cell()
			cell_changed.emit(i)
	is_over = false
	spawn_timer = GRACE_SECONDS
	_dirty = true
	resources_changed.emit()
	save_game()


func reset_all() -> void:
	for k in UPGRADES.keys():
		upgrades[k] = 0
	unlocked = ["lactobacillus"]
	lifetime_earned = 0.0
	best_score = 0.0
	fiber = 0
	last_gift = -GIFT_COOLDOWN
	boost_until = 0.0
	pending_offline = {}
	new_run(true)
	has_save = false


# ---------------- çevrimdışı ilerleme ----------------
func _compute_offline() -> void:
	var now: float = now_unix()
	var elapsed: float = now - last_active
	if elapsed < 0.0 or last_active <= 0.0:  # saat geri alınmış veya ilk açılış
		elapsed = 0.0
	var cap: float = offline_cap_hours() * 3600.0
	var counted: float = minf(elapsed, cap)
	var amount: float = floor(production_per_sec(false) * counted * OFFLINE_EFFICIENCY)
	last_active = now
	if elapsed >= 60.0 and amount >= 1.0 and not is_over:
		pending_offline = {"seconds": elapsed, "counted": counted, "amount": amount}


func claim_offline() -> float:
	if pending_offline.is_empty():
		return 0.0
	var a: float = float(pending_offline["amount"])
	_earn(a)
	pending_offline = {}
	_dirty = true
	resources_changed.emit()
	save_game()
	return a


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		save_game()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		_compute_offline()


# ---------------- kayıt ----------------
func to_dict() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"saved_at": now_unix(),
		"nutrients": nutrients, "fiber": fiber, "barrier": barrier,
		"run_earned": run_earned, "lifetime_earned": lifetime_earned, "best_score": best_score,
		"cells": cells, "tiles": tiles, "upgrades": upgrades, "unlocked": unlocked,
		"seen_threats": seen_threats, "run_time": run_time, "boost_until": boost_until,
		"last_gift": last_gift, "rocks_cleared": rocks_cleared, "spawn_timer": spawn_timer,
		"is_over": is_over, "selected": selected,
	}


func from_dict(d: Dictionary) -> bool:
	if int(d.get("version", 0)) < 1:
		return false
	var cl: Array = d.get("cells", [])
	var tl: Array = d.get("tiles", [])
	if cl.size() != COLS * ROWS or tl.size() != COLS * ROWS:
		return false
	cells.clear()
	for c in cl:
		if typeof(c) != TYPE_DICTIONARY:
			return false
		var e: Dictionary = empty_cell()
		var kind: String = str(c.get("kind", ""))
		if kind != "" and not SPECIES.has(kind):
			kind = ""
		e["kind"] = kind
		e["level"] = clampi(int(c.get("level", 1)), 1, MAX_LEVEL)
		e["hp"] = float(c.get("hp", 0.0))
		e["max_hp"] = float(c.get("max_hp", 0.0))
		e["spread"] = float(c.get("spread", 0.0))
		cells.append(e)
	tiles.clear()
	for t in tl:
		var ts: String = str(t)
		tiles.append(ts if ts in ["normal", "boost", "heal", "block"] else "normal")
	nutrients = maxf(0.0, float(d.get("nutrients", 20.0)))
	fiber = maxi(0, int(d.get("fiber", 0)))
	barrier = clampf(float(d.get("barrier", 100.0)), 0.0, 100.0)
	run_earned = float(d.get("run_earned", 0.0))
	lifetime_earned = float(d.get("lifetime_earned", 0.0))
	best_score = float(d.get("best_score", 0.0))
	var up: Dictionary = d.get("upgrades", {})
	for k in UPGRADES.keys():
		upgrades[k] = clampi(int(up.get(k, 0)), 0, int(UPGRADES[k]["max"]))
	unlocked.clear()
	for u in d.get("unlocked", ["lactobacillus"]):
		if str(u) in GOOD:
			unlocked.append(str(u))
	if not ("lactobacillus" in unlocked):
		unlocked.append("lactobacillus")
	seen_threats.clear()
	for s in d.get("seen_threats", []):
		seen_threats.append(str(s))
	run_time = float(d.get("run_time", 0.0))
	boost_until = float(d.get("boost_until", 0.0))
	last_gift = float(d.get("last_gift", -GIFT_COOLDOWN))
	rocks_cleared = int(d.get("rocks_cleared", 0))
	spawn_timer = float(d.get("spawn_timer", GRACE_SECONDS))
	is_over = bool(d.get("is_over", false))
	selected = str(d.get("selected", "lactobacillus"))
	if not (selected in unlocked):
		selected = "lactobacillus"
	last_active = float(d.get("saved_at", now_unix()))
	return true


func save_game() -> void:
	if cells.is_empty():
		return
	last_active = now_unix()
	var text: String = JSON.stringify(to_dict())
	var f := FileAccess.open(TMP_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Kayıt yazılamadı: %s" % FileAccess.get_open_error())
		return
	f.store_string(text)
	f.close()
	var g_save: String = ProjectSettings.globalize_path(SAVE_PATH)
	var g_bak: String = ProjectSettings.globalize_path(BAK_PATH)
	var g_tmp: String = ProjectSettings.globalize_path(TMP_PATH)
	if FileAccess.file_exists(SAVE_PATH):
		if FileAccess.file_exists(BAK_PATH):
			DirAccess.remove_absolute(g_bak)
		DirAccess.rename_absolute(g_save, g_bak)
	var err: int = DirAccess.rename_absolute(g_tmp, g_save)
	if err != OK:
		push_warning("Kayıt yeniden adlandırılamadı: %d" % err)
		return
	has_save = true
	_dirty = false


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var txt: String = f.get_as_text()
	f.close()
	var v: Variant = JSON.parse_string(txt)
	if typeof(v) == TYPE_DICTIONARY:
		return v
	return {}


func load_game() -> bool:
	for path in [SAVE_PATH, BAK_PATH]:
		var d: Dictionary = _read_json(path)
		if not d.is_empty() and from_dict(d):
			has_save = true
			return true
		elif FileAccess.file_exists(path):
			push_warning("Bozuk kayıt atlandı: " + path)
	return false


func _on_save_timer() -> void:
	if _dirty and running:
		save_game()


# ---------------- istatistik ----------------
func ecosystem_stats() -> Dictionary:
	var counts: Dictionary = {}
	var prod: Dictionary = {}
	for k in SPECIES.keys():
		counts[k] = 0
		prod[k] = 0.0
	for i in cells.size():
		var kind: String = str(cells[i]["kind"])
		if kind != "":
			counts[kind] = int(counts[kind]) + 1
			prod[kind] = float(prod[kind]) + cell_production(i)
	var total: int = 0
	for k in counts.keys():
		total += int(counts[k])
	return {"counts": counts, "prod": prod, "total": total}


# ---------------- biçimlendirme ----------------
static func fmt(v: float) -> String:
	var a: float = absf(v)
	var units: Array[String] = ["", "K", "M", "B", "T", "Qa", "Qi"]
	var u: int = 0
	while a >= 1000.0 and u < units.size() - 1:
		a /= 1000.0
		u += 1
	var sign_s: String = "-" if v < 0 else ""
	if u == 0:
		if a < 10.0 and a != floor(a):
			return sign_s + String.num(a, 1)
		return sign_s + str(int(floor(a)))
	if a < 10.0:
		return sign_s + String.num(a, 2) + units[u]
	if a < 100.0:
		return sign_s + String.num(a, 1) + units[u]
	return sign_s + str(int(floor(a))) + units[u]


func fmt_time(seconds: float) -> String:
	var s: int = int(seconds)
	var h: int = int(s / 3600)
	var m: int = int((s % 3600) / 60)
	var sec: int = s % 60
	if h > 0:
		return I18n.t("time_h", {"h": h, "m": m})
	if m > 0:
		return I18n.t("time_m", {"m": m, "s": sec})
	return I18n.t("time_s", {"s": sec})
