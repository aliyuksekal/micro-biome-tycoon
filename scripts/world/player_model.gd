extends Node3D
## Prosedürel 3D futbolcu / kaleci. Eklem hiyerarşisi + kodla animasyon.
## Model +Z yönüne bakar. Forma rengi/deseni shader ile boyanır (arma ve yazı yok).

const SHIRT_SHADER := """
shader_type spatial;
uniform vec3 ca : source_color = vec3(0.8, 0.1, 0.1);
uniform vec3 cb : source_color = vec3(1.0, 0.8, 0.1);
uniform vec3 trim : source_color = vec3(1.0);
uniform int pattern = 0;
uniform float stripes = 7.0;
varying vec3 lp;
void vertex() { lp = VERTEX; }
void fragment() {
	vec3 col;
	if (pattern == 0) {
		col = lp.x < 0.0 ? ca : cb;
	} else if (pattern == 1) {
		col = fract((lp.x + 1.0) * stripes) < 0.5 ? ca : cb;
	} else {
		col = ca;
	}
	// yaka ve kol ağzı şeridi
	float collar = smoothstep(0.26, 0.29, lp.y);
	col = mix(col, trim, collar);
	// kumaş dokusu
	float weave = 0.94 + 0.06 * sin(lp.x * 220.0) * sin(lp.y * 220.0);
	ALBEDO = col * weave;
	ROUGHNESS = 0.55;
	SPECULAR = 0.35;
	RIM = 0.25;
	RIM_TINT = 0.3;
}
"""

var is_keeper: bool = false
var state: String = "idle"
var t: float = 0.0
var state_t: float = 0.0
var skin: Color = Color("e0ac83")

var hips: Node3D
var torso: Node3D
var head: Node3D
var arm_l: Node3D
var arm_r: Node3D
var fore_l: Node3D
var fore_r: Node3D
var leg_l: Node3D
var leg_r: Node3D
var shin_l: Node3D
var shin_r: Node3D
var shirt_mat: ShaderMaterial
var sleeve_mat: ShaderMaterial
var shorts_mat: StandardMaterial3D
var socks_mat: StandardMaterial3D
var glove_mat: StandardMaterial3D
var hair_mat: StandardMaterial3D
var skin_mat: StandardMaterial3D
var dive_dir: Vector2 = Vector2.ZERO


func _init(keeper: bool = false, skin_color: Color = Color("e0ac83"), hair: Color = Color("2b1d14")) -> void:
	is_keeper = keeper
	skin = skin_color
	_build(hair)


func _m(c: Color, rough: float = 0.6) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m


func _capsule(r: float, h: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = r
	cm.height = maxf(h, r * 2.0)
	cm.radial_segments = 14
	cm.rings = 6
	mi.mesh = cm
	mi.material_override = mat
	return mi


func _sphere(r: float, mat: Material, hemi: bool = false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * (1.0 if hemi else 2.0)
	sm.is_hemisphere = hemi
	sm.radial_segments = 18
	sm.rings = 10
	mi.mesh = sm
	mi.material_override = mat
	return mi


func _limb(parent: Node3D, pos: Vector3, length: float, r: float, mat: Material) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = pos
	parent.add_child(pivot)
	var c := _capsule(r, length + r * 2.0, mat)
	c.position = Vector3(0, -length * 0.5, 0)
	pivot.add_child(c)
	return pivot


func _shader(code: String) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = code
	var m := ShaderMaterial.new()
	m.shader = sh
	return m


func _build(hair: Color) -> void:
	skin_mat = _m(skin, 0.7)
	hair_mat = _m(hair, 0.85)
	shirt_mat = _shader(SHIRT_SHADER)
	sleeve_mat = _shader(SHIRT_SHADER)
	shorts_mat = _m(Color.WHITE, 0.6)
	socks_mat = _m(Color.WHITE, 0.7)
	glove_mat = _m(Color("37e07a"), 0.5)
	var boot_mat := _m(Color("141820"), 0.35)
	hips = Node3D.new()
	hips.position = Vector3(0, 0.93, 0)
	add_child(hips)
	# şort
	var shorts := MeshInstance3D.new()
	var sc := CylinderMesh.new()
	sc.top_radius = 0.2
	sc.bottom_radius = 0.23
	sc.height = 0.24
	shorts.mesh = sc
	shorts.material_override = shorts_mat
	shorts.position = Vector3(0, -0.04, 0)
	shorts.scale = Vector3(1.15, 1, 0.8)
	hips.add_child(shorts)
	# gövde
	torso = Node3D.new()
	torso.position = Vector3(0, 0.06, 0)
	hips.add_child(torso)
	var chest := _capsule(0.2, 0.66, shirt_mat)
	chest.position = Vector3(0, 0.3, 0)
	chest.scale = Vector3(1.3, 1.0, 0.82)
	torso.add_child(chest)
	# baş
	head = Node3D.new()
	head.position = Vector3(0, 0.66, 0)
	torso.add_child(head)
	var neck := _capsule(0.06, 0.14, skin_mat)
	neck.position = Vector3(0, 0.0, 0)
	head.add_child(neck)
	var skull := _sphere(0.155, skin_mat)
	skull.position = Vector3(0, 0.15, 0.0)
	skull.scale = Vector3(0.95, 1.08, 1.0)
	head.add_child(skull)
	var hair_cap := _sphere(0.163, hair_mat, true)
	hair_cap.position = Vector3(0, 0.175, -0.012)
	hair_cap.rotation = Vector3(deg_to_rad(-12), 0, 0)
	head.add_child(hair_cap)
	var white := _m(Color.WHITE, 0.2)
	var black := _m(Color("101010"), 0.2)
	for sx in [-1.0, 1.0]:
		var eye := _sphere(0.03, white)
		eye.position = Vector3(sx * 0.055, 0.17, 0.135)
		head.add_child(eye)
		var pupil := _sphere(0.016, black)
		pupil.position = Vector3(sx * 0.055, 0.17, 0.162)
		head.add_child(pupil)
		var brow := MeshInstance3D.new()
		var bb := BoxMesh.new()
		bb.size = Vector3(0.05, 0.012, 0.012)
		brow.mesh = bb
		brow.material_override = hair_mat
		brow.position = Vector3(sx * 0.055, 0.215, 0.145)
		brow.rotation = Vector3(0, 0, sx * -0.15)
		head.add_child(brow)
		var ear := _sphere(0.035, skin_mat)
		ear.position = Vector3(sx * 0.15, 0.15, 0)
		ear.scale = Vector3(0.5, 1, 0.8)
		head.add_child(ear)
	var nose := _sphere(0.025, skin_mat)
	nose.position = Vector3(0, 0.14, 0.155)
	head.add_child(nose)
	var mouth := MeshInstance3D.new()
	var mb := BoxMesh.new()
	mb.size = Vector3(0.05, 0.01, 0.01)
	mouth.mesh = mb
	mouth.material_override = _m(Color("7a2e2e"), 0.5)
	mouth.position = Vector3(0, 0.085, 0.148)
	head.add_child(mouth)
	# kollar
	arm_l = _limb(torso, Vector3(-0.3, 0.52, 0), 0.3, 0.068, sleeve_mat)
	arm_r = _limb(torso, Vector3(0.3, 0.52, 0), 0.3, 0.068, sleeve_mat)
	fore_l = _limb(arm_l, Vector3(0, -0.3, 0), 0.27, 0.055, skin_mat)
	fore_r = _limb(arm_r, Vector3(0, -0.3, 0), 0.27, 0.055, skin_mat)
	for f in [fore_l, fore_r]:
		var hand := _sphere(0.085 if is_keeper else 0.055, glove_mat if is_keeper else skin_mat)
		hand.position = Vector3(0, -0.3, 0)
		hand.scale = Vector3(0.9, 1.1, 0.6)
		f.add_child(hand)
	# bacaklar
	leg_l = _limb(hips, Vector3(-0.11, -0.05, 0), 0.42, 0.085, skin_mat)
	leg_r = _limb(hips, Vector3(0.11, -0.05, 0), 0.42, 0.085, skin_mat)
	shin_l = _limb(leg_l, Vector3(0, -0.42, 0), 0.4, 0.07, socks_mat)
	shin_r = _limb(leg_r, Vector3(0, -0.42, 0), 0.4, 0.07, socks_mat)
	for s in [shin_l, shin_r]:
		var boot := MeshInstance3D.new()
		var bm := CapsuleMesh.new()
		bm.radius = 0.06
		bm.height = 0.24
		boot.mesh = bm
		boot.material_override = boot_mat
		boot.rotation = Vector3(PI / 2, 0, 0)
		boot.position = Vector3(0, -0.42, 0.05)
		s.add_child(boot)


func apply_kit(kit: Dictionary, keeper_color: Color = Color.BLACK) -> void:
	if is_keeper:
		for m in [shirt_mat, sleeve_mat]:
			m.set_shader_parameter("ca", keeper_color)
			m.set_shader_parameter("cb", keeper_color.darkened(0.15))
			m.set_shader_parameter("pattern", 2)
			m.set_shader_parameter("trim", keeper_color.lightened(0.4))
		shorts_mat.albedo_color = keeper_color.darkened(0.35)
		socks_mat.albedo_color = keeper_color
		glove_mat.albedo_color = Color("f4f4f4") if keeper_color.get_luminance() < 0.5 else Color("1a1a1a")
		return
	shirt_mat.set_shader_parameter("ca", kit["a"])
	shirt_mat.set_shader_parameter("cb", kit["b"])
	shirt_mat.set_shader_parameter("pattern", int(kit["pattern"]))
	shirt_mat.set_shader_parameter("trim", kit["trim"])
	# kollar: yarım yarım desende her kol kendi yarısının rengini alır
	sleeve_mat.set_shader_parameter("ca", kit["a"])
	sleeve_mat.set_shader_parameter("cb", kit["b"])
	sleeve_mat.set_shader_parameter("pattern", 2 if int(kit["pattern"]) == 0 else 1)
	sleeve_mat.set_shader_parameter("stripes", 12.0)
	sleeve_mat.set_shader_parameter("trim", kit["trim"])
	shorts_mat.albedo_color = kit["shorts"]
	socks_mat.albedo_color = kit["socks"]


func set_state(s: String) -> void:
	state = s
	state_t = 0.0


func _process(delta: float) -> void:
	t += delta
	state_t += delta
	match state:
		"idle":
			_pose_idle()
		"run":
			_pose_run(state_t * 9.0)
		"kick":
			_pose_kick(state_t)
		"celebrate":
			_pose_celebrate(state_t)
		"sad":
			_pose_sad()
		"keeper_ready":
			_pose_keeper_ready()
		"dive":
			_pose_dive()
		"keeper_celebrate":
			_pose_celebrate(state_t)


func _reset_pose() -> void:
	for n in [arm_l, arm_r, fore_l, fore_r, leg_l, leg_r, shin_l, shin_r, torso, head]:
		n.rotation = Vector3.ZERO
	hips.position = Vector3(0, 0.93, 0)
	hips.rotation = Vector3.ZERO


func _pose_idle() -> void:
	_reset_pose()
	var b: float = sin(t * 2.2)
	torso.rotation.x = 0.03 * b
	hips.position.y = 0.93 + 0.008 * b
	arm_l.rotation.z = -0.12
	arm_r.rotation.z = 0.12
	fore_l.rotation.x = -0.2
	fore_r.rotation.x = -0.2
	head.rotation.y = 0.12 * sin(t * 0.7)


func _pose_run(p: float) -> void:
	_reset_pose()
	var s: float = sin(p)
	leg_l.rotation.x = -0.75 * s
	leg_r.rotation.x = 0.75 * s
	shin_l.rotation.x = 0.9 * maxf(0.0, s)
	shin_r.rotation.x = 0.9 * maxf(0.0, -s)
	arm_l.rotation.x = 0.7 * s
	arm_r.rotation.x = -0.7 * s
	fore_l.rotation.x = -0.9
	fore_r.rotation.x = -0.9
	torso.rotation.x = -0.18
	hips.position.y = 0.93 + 0.04 * absf(cos(p))


func _pose_kick(k: float) -> void:
	_reset_pose()
	# 0-0.18: geri çekiş, 0.18-0.32: vuruş, sonrası takip
	var back: float = clampf(k / 0.18, 0.0, 1.0)
	var fwd: float = clampf((k - 0.18) / 0.14, 0.0, 1.0)
	leg_r.rotation.x = lerpf(0.0, 0.9, back) - fwd * 2.3
	shin_r.rotation.x = lerpf(0.0, 1.5, back) * (1.0 - fwd)
	leg_l.rotation.x = -0.15
	shin_l.rotation.x = 0.25
	arm_l.rotation.z = -0.9
	arm_r.rotation.z = 0.5
	arm_r.rotation.x = 0.4
	torso.rotation.x = -0.12 + fwd * 0.18
	torso.rotation.y = -0.2 * fwd


func _pose_celebrate(k: float) -> void:
	_reset_pose()
	var j: float = absf(sin(k * 6.0))
	hips.position.y = 0.93 + 0.22 * j
	arm_l.rotation.z = -2.6 + 0.2 * sin(k * 12.0)
	arm_r.rotation.z = 2.6 - 0.2 * sin(k * 12.0)
	fore_l.rotation.x = -0.3
	fore_r.rotation.x = -0.3
	leg_l.rotation.x = -0.3 * j
	shin_l.rotation.x = 0.8 * j
	shin_r.rotation.x = 0.4 * j
	head.rotation.x = -0.25


func _pose_sad() -> void:
	_reset_pose()
	head.rotation.x = 0.5
	torso.rotation.x = 0.25
	arm_l.rotation.z = -0.05
	arm_r.rotation.z = 0.05
	hips.position.y = 0.9


func _pose_keeper_ready() -> void:
	_reset_pose()
	var b: float = sin(t * 7.0)
	hips.position.y = 0.8 + 0.025 * absf(b)
	hips.position.x = 0.0
	leg_l.rotation.z = -0.28
	leg_r.rotation.z = 0.28
	leg_l.rotation.x = -0.35
	leg_r.rotation.x = -0.35
	shin_l.rotation.x = 0.7
	shin_r.rotation.x = 0.7
	torso.rotation.x = 0.25
	head.rotation.x = -0.25
	arm_l.rotation.z = -0.85
	arm_r.rotation.z = 0.85
	arm_l.rotation.x = -0.5
	arm_r.rotation.x = -0.5
	fore_l.rotation.x = -0.5
	fore_r.rotation.x = -0.5


func _pose_dive() -> void:
	_reset_pose()
	# kollar topa doğru uzanır, bacaklar birlikte
	var side: float = signf(dive_dir.x) if absf(dive_dir.x) > 0.3 else 0.0
	var up: float = clampf(dive_dir.y, 0.0, 1.0)
	arm_l.rotation.z = -2.7 if side <= 0.0 else -1.6
	arm_r.rotation.z = 2.7 if side >= 0.0 else 1.6
	arm_l.rotation.x = -0.4 - up * 0.3
	arm_r.rotation.x = -0.4 - up * 0.3
	leg_l.rotation.z = -0.12
	leg_r.rotation.z = 0.12
	shin_l.rotation.x = 0.35
	shin_r.rotation.x = 0.35
	head.rotation.z = -0.3 * side
