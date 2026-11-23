class_name Dweller
extends Node3D
## 나무 자리(Socket)에 붙는 이웃 하나. 종마다 모델·크기·붙는 자리·등장 연출이 다르다.
## 동물은 Gobkit Free Animal Pack(CC0), 버섯·풀꽃은 Quaternius 숲 팩, 나비는 코드로 만든다.

enum Entrance { TREE, FLY, FLUTTER, WALK, POP, HOP }

const DIR := "res://assets/models/animals/%s.glb"
## 모델 하나에 애니메이션이 한 줄로 구워진 팩(24fps): 쉬기 0~29, 걷기 90~119 프레임
const SEGMENTS := {&"idle": Vector2(0.0, 1.2), &"walk": Vector2(3.75, 4.95)}
## 종 → 모델, 크기, 붙을 수 있는 자리, 등장 연출, 높이(초상 찍기·자리 맞추기), 카드 색
const KINDS := {
	&"tawny_owl": {model = "Owl", scale = 0.24, sides = [&"Top"], entrance = Entrance.FLY, height = 0.96, color = Color("#C9825A")},
	&"goshawk": {model = "StellersSeaEagle", scale = 0.25, tint = Color("#A0A8B0"), sides = [&"Top"], entrance = Entrance.FLY, height = 1.0, color = Color("#7A8490")},
	&"woodpecker": {model = "Quail", scale = 0.2, tint = Color("#F09080"), sides = [&"Top"], entrance = Entrance.FLY, height = 0.88, color = Color("#C8483A")},
	&"chaffinch": {model = "GouldianFinch", scale = 0.208, tint = Color("#E8A880"), sides = [&"Top"], entrance = Entrance.FLY, height = 0.88, color = Color("#C87A5A")},
	&"bullfinch": {model = "GouldianFinch", scale = 0.208, tint = Color("#F07060"), sides = [&"Top"], entrance = Entrance.FLY, height = 0.88, color = Color("#D85A4A")},
	&"jay": {model = "Quail", scale = 0.2, tint = Color("#9AB8F0"), sides = [&"Top"], entrance = Entrance.FLY, height = 0.88, color = Color("#5A86C8")},
	&"red_squirrel": {model = "Red", scale = 0.0026, tint = Color("#E07040"), sides = [&"Top"], entrance = Entrance.HOP, height = 0.9, color = Color("#C8643A")},
	&"camberwell_beauty": {model = "", scale = 1.5, sides = [&"Top"], entrance = Entrance.FLUTTER, height = 0.65, color = Color("#6A3A5A")},
	&"large_tortoiseshell": {model = "", scale = 1.5, sides = [&"Top"], entrance = Entrance.FLUTTER, height = 0.65, color = Color("#E0803A")},
	&"peacock_butterfly": {model = "", scale = 1.5, sides = [&"Top"], entrance = Entrance.FLUTTER, height = 0.65, color = Color("#C8483A")},
	&"purple_emperor": {model = "", scale = 1.5, sides = [&"Top"], entrance = Entrance.FLUTTER, height = 0.65, color = Color("#6A5AC8")},
	&"fritillary": {model = "", scale = 1.5, sides = [&"Top"], entrance = Entrance.FLUTTER, height = 0.65, color = Color("#F2A43A")},
	&"moss": {model = "Clover_1", scale = 0.9, tint = Color("#7AB04A"), sides = [&"Bottom"], entrance = Entrance.POP, height = 0.6, color = Color("#6E9A4F")},
	&"wood_ant": {model = "Bee", scale = 0.192, tint = Color("#8A4A30"), sides = [&"Bottom"], entrance = Entrance.WALK, height = 0.72, color = Color("#8A4A30")},
	&"stag_beetle": {model = "Bee", scale = 0.192, tint = Color("#6A4A30"), sides = [&"Bottom"], entrance = Entrance.WALK, height = 0.72, color = Color("#5A3A28")},
	&"fire_salamander": {model = "Axolotl", scale = 0.21, tint = Color("#7A6A60"), sides = [&"Bottom"], entrance = Entrance.HOP, height = 0.72, color = Color("#E8B020")},
	&"pond_turtle": {model = "Axolotl", scale = 0.2, tint = Color("#506850"), sides = [&"Bottom"], entrance = Entrance.HOP, height = 0.72, color = Color("#506850")},
	&"tree_frog": {model = "Axolotl", scale = 0.2, tint = Color("#90F070"), sides = [&"Bottom"], entrance = Entrance.HOP, height = 0.72, color = Color("#6AC850")},
	&"hedgehog": {model = "Mole", scale = 0.224, tint = Color("#B09070"), sides = [&"Bottom"], entrance = Entrance.WALK, height = 0.8, color = Color("#9A7A5A")},
	&"toad": {model = "Axolotl", scale = 0.2, tint = Color("#A08060"), sides = [&"Bottom"], entrance = Entrance.HOP, height = 0.72, color = Color("#8A7050"), stack = true},
	&"fern": {model = "Fern_1", scale = 0.45, sides = [&"Bottom"], entrance = Entrance.POP, height = 0.8, color = Color("#5A9A4A")},
	&"wild_strawberry": {model = "Bush_Common_Flowers", scale = 0.5, tint = Color("#F06060"), sides = [&"Bottom"], entrance = Entrance.POP, height = 0.8, color = Color("#D84A4A")},
	&"blackberry": {model = "Bush_Common_Flowers", scale = 0.5, tint = Color("#7A4A8A"), sides = [&"Bottom"], entrance = Entrance.POP, height = 0.8, color = Color("#5A3A6A")},
	&"firefly": {model = "Bee", scale = 0.192, tint = Color("#F0F070"), sides = [&"Bottom"], entrance = Entrance.FLUTTER, height = 0.72, color = Color("#C8C040")},
	&"chanterelle": {model = "Mushroom_Common", scale = 0.8, tint = Color("#F2C14C"), frame = 1.7, sides = [&"Bottom"], entrance = Entrance.POP, height = 0.8, color = Color("#E8B040")},
	&"fly_agaric": {model = "Mushroom_Common", scale = 0.85, tint = Color("#F05A4A"), frame = 1.7, sides = [&"Bottom"], entrance = Entrance.POP, height = 0.8, color = Color("#D04030")},
	&"penny_bun": {model = "Mushroom_Common", scale = 0.8, tint = Color("#9A6A48"), frame = 1.7, sides = [&"Bottom"], entrance = Entrance.POP, height = 0.8, color = Color("#8A5A38")},
	&"parasol": {model = "Mushroom_Laetiporus", scale = 0.88, tint = Color("#E8DCC0"), frame = 1.7, sides = [&"Bottom"], entrance = Entrance.POP, height = 0.8, color = Color("#B8A888")},
	&"mole": {model = "Mole", scale = 0.224, sides = [&"Bottom"], entrance = Entrance.POP, height = 0.8, color = Color("#8C7F9A")},
	&"hare": {model = "Bunnykit", scale = 0.24, sides = [&"Left", &"Right"], entrance = Entrance.WALK, height = 0.96, color = Color("#C89A78"), stack = true},
	&"badger": {model = "TasmanianDevil", scale = 0.28, sides = [&"Left", &"Right"], entrance = Entrance.WALK, height = 1.0, color = Color("#6A6A6A")},
	&"fox": {model = "Dingo", scale = 0.32, sides = [&"Left", &"Right"], entrance = Entrance.WALK, height = 1.36, color = Color("#D9803A")},
	&"raccoon": {model = "Dingo", scale = 0.3, tint = Color("#8A8A90"), sides = [&"Left", &"Right"], entrance = Entrance.WALK, height = 1.2, color = Color("#7A7A80")},
	&"boar": {model = "Boar", scale = 0.32, sides = [&"Left", &"Right"], entrance = Entrance.WALK, height = 1.2, color = Color("#9A5A3A")},
	&"squeaker": {model = "Boar", scale = 0.22, tint = Color("#D8B090"), sides = [&"Left", &"Right"], entrance = Entrance.WALK, height = 0.9, color = Color("#B88A68")},
	&"roe_deer": {model = "Goat", scale = 0.32, tint = Color("#B88058"), sides = [&"Left", &"Right"], entrance = Entrance.WALK, height = 1.4, color = Color("#A87048")},
	&"red_deer": {model = "Goat", scale = 0.38, tint = Color("#905038"), sides = [&"Left", &"Right"], entrance = Entrance.WALK, height = 1.5, color = Color("#804030")},
	&"fallow_deer": {model = "Goat", scale = 0.34, tint = Color("#D8A060"), sides = [&"Left", &"Right"], entrance = Entrance.WALK, height = 1.44, color = Color("#C89050")},
	&"wolf": {model = "BlackWolf", scale = 0.34, sides = [&"Left", &"Right"], entrance = Entrance.WALK, height = 1.36, color = Color("#5A5A68")},
	&"lynx": {model = "Dingo", scale = 0.32, tint = Color("#C8A070"), sides = [&"Left", &"Right"], entrance = Entrance.WALK, height = 1.3, color = Color("#B89060")},
	&"brown_bear": {model = "SunBear", scale = 0.38, tint = Color("#A06038"), sides = [&"Left", &"Right"], entrance = Entrance.WALK, height = 1.5, color = Color("#8A5030")},
	&"marten": {model = "Marmot", scale = 0.256, tint = Color("#C8A040"), sides = [&"Left", &"Right"], entrance = Entrance.WALK, height = 0.96, color = Color("#A88030")},
	&"dormouse": {model = "Rat", scale = 0.18, tint = Color("#A89880"), sides = [&"Left", &"Right"], entrance = Entrance.WALK, height = 0.8, color = Color("#988870")},
	&"gnat": {model = "Bee", scale = 0.16, tint = Color("#808078"), sides = [&"Left", &"Right"], entrance = Entrance.FLUTTER, height = 0.72, color = Color("#707068")},
	&"carpenter_bee": {model = "Bee", scale = 0.2, tint = Color("#6A5AD0"), sides = [&"Left", &"Right"], entrance = Entrance.FLUTTER, height = 0.72, color = Color("#5A4AB0")},
	&"barbastelle_bat": {model = "Bat", scale = 0.00256, tint = Color("#5A5048"), sides = [&"Left", &"Right"], entrance = Entrance.FLY, height = 0.88, color = Color("#5A5048")},
	&"bechstein_bat": {model = "Bat", scale = 0.00256, tint = Color("#C08A50"), sides = [&"Left", &"Right"], entrance = Entrance.FLY, height = 0.88, color = Color("#A07840")},
	&"long_eared_bat": {model = "Bat", scale = 0.00256, tint = Color("#9A7060"), sides = [&"Left", &"Right"], entrance = Entrance.FLY, height = 0.88, color = Color("#8A6A4A")},
	&"horseshoe_bat": {model = "Bat", scale = 0.0028, tint = Color("#6A6A88"), sides = [&"Left", &"Right"], entrance = Entrance.FLY, height = 0.88, color = Color("#6A6A7A")},
}

var kind: StringName
var _body: Node3D
var _ap: AnimationPlayer
var _clip: StringName
var _seg := Vector2.ZERO
var _wings: Array[Node3D] = []
var _time := 0.0


static func make(k: StringName) -> Dweller:
	var d := Dweller.new()
	d.kind = k
	d.name = String(k).capitalize()
	d._build()
	return d


static func entrance_of(k: StringName) -> Entrance:
	return KINDS[k].entrance


func _build() -> void:
	var data: Dictionary = KINDS[kind]
	_body = Node3D.new()
	_body.name = "Body"
	add_child(_body)
	var model: Node3D
	if data.model == "":
		model = _butterfly()
	elif ResourceLoader.exists(DIR % data.model):
		model = load(DIR % data.model).instantiate()
	else:
		model = Nature.spawn(data.model)
	model.name = "Model"
	model.scale = Vector3.ONE * data.scale
	if data.has("tint"):
		_tint(model, data.tint)
	_body.add_child(model)
	_ap = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	play(&"idle")


## 같은 모델로 여러 종을 만든다: 재질 색에 tint를 곱한다(텍스처 색도 함께 바뀐다).
static func _tint(model: Node, tint: Color) -> void:
	for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		for i in mi.mesh.get_surface_count():
			var mat := mi.get_active_material(i)
			if mat is BaseMaterial3D:
				var m: BaseMaterial3D = mat.duplicate()
				m.albedo_color = m.albedo_color * tint
				mi.set_surface_override_material(i, m)
			elif mat is ShaderMaterial:
				var sm: ShaderMaterial = mat.duplicate()
				for key in [&"albedo", &"tint", &"color"]:
					if sm.get_shader_parameter(key) is Color:
						sm.set_shader_parameter(key, sm.get_shader_parameter(key) * tint)
				mi.set_surface_override_material(i, sm)


## 쉬기(idle)·걷기(walk). 한 줄로 구운 모델은 프레임 구간만 되풀이한다.
func play(state: StringName) -> void:
	if not _ap:
		return
	var list := _ap.get_animation_list()
	if list.is_empty():
		return
	if _ap.has_animation(state):
		_ap.get_animation(state).loop_mode = Animation.LOOP_LINEAR
		_clip = state
		_seg = Vector2.ZERO
		_ap.play(state, 0.2)
		return
	_clip = StringName(list[0])
	_seg = SEGMENTS.get(state, SEGMENTS.idle)
	if _ap.get_animation(_clip).length < _seg.y:
		_seg = Vector2.ZERO
	_ap.play(_clip)
	_ap.seek(_seg.x, true)


func _process(delta: float) -> void:
	_time += delta
	if _seg != Vector2.ZERO and _ap and _ap.is_playing() and _ap.current_animation_position >= _seg.y:
		_ap.seek(_seg.x, true)
	for i in _wings.size():
		_wings[i].rotation.z = (1.0 if i == 0 else -1.0) * (1.0 + sin(_time * 14.0) * 0.5)


## 둥지 자리에 오는 연출. away: 섬 가운데→나무 바깥쪽(전역, 수평), face: 다 와서 바라볼 방향(전역)
func enter(away: Vector3, face: Vector3) -> Tween:
	var end := position
	var tw := create_tween()
	match entrance_of(kind):
		Entrance.FLY:
			play(&"walk")
			var start := end + _to_local_dir(away * 7.0 + Vector3.UP * 5.0 + away.cross(Vector3.UP) * 2.0)
			var ctrl := (start + end) * 0.5 + Vector3.UP * 2.5
			tw.tween_method(_along.bind(start, ctrl, end), 0.0, 1.0, 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tw.tween_callback(_land.bind(face))
		Entrance.FLUTTER:
			var spark := Fx.trail(self, Color("#FFE7A0"))
			tw.tween_method(_spiral.bind(end), 0.0, 1.0, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tw.tween_callback(func() -> void: spark.emitting = false; spark.finished.connect(spark.queue_free))
			tw.tween_callback(_land.bind(face))
		Entrance.WALK:
			play(&"walk")
			var start := end + _to_local_dir(away * 5.0)
			position = start
			_face_local(end - start)
			tw.tween_property(self, ^"position", end, 1.6)
			tw.tween_callback(play.bind(&"idle"))
			tw.tween_callback(_face.bind(face))
			# 자리에 서서 둘러본다
			tw.tween_property(_body, ^"rotation:y", 0.6, 0.35).set_trans(Tween.TRANS_SINE)
			tw.tween_property(_body, ^"rotation:y", -0.6, 0.5).set_trans(Tween.TRANS_SINE)
			tw.tween_property(_body, ^"rotation:y", 0.0, 0.35).set_trans(Tween.TRANS_SINE)
		Entrance.POP:
			_body.scale = Vector3.ONE * 0.01
			_body.position.y = -0.3
			_face(face)
			tw.set_parallel()
			tw.tween_property(_body, ^"scale", Vector3.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(_body, ^"position:y", 0.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			Fx.burst(self, Vector3(0, 0.1, 0), [KINDS[kind].color.lightened(0.3), Color("#FFF4D6")], 26, 2.2, 0.05, -3.0)
		Entrance.HOP:
			var start := end + _to_local_dir(away * 2.4)
			position = start
			_face_local(end - start)
			for i in 3:
				var a := start.lerp(end, i / 3.0)
				var b := start.lerp(end, (i + 1) / 3.0)
				tw.tween_method(_hop.bind(a, b), 0.0, 1.0, 0.32)
				tw.tween_property(_body, ^"scale", Vector3(1.2, 0.8, 1.2), 0.06)
				tw.tween_property(_body, ^"scale", Vector3.ONE, 0.08)
			tw.tween_callback(_face.bind(face))
	return tw


func _to_local_dir(v: Vector3) -> Vector3:
	var p := get_parent() as Node3D
	return p.global_basis.inverse() * v if p and p.is_inside_tree() else v


func _along(t: float, a: Vector3, c: Vector3, b: Vector3) -> void:
	var p := a.lerp(c, t).lerp(c.lerp(b, t), t)
	if p.distance_to(position) > 0.001:
		_face_local(p - position)
	position = p


func _spiral(t: float, end: Vector3) -> void:
	var r := 1.6 * (1.0 - t)
	var ang := t * TAU * 2.2
	var p := end + Vector3(cos(ang) * r, 2.0 * (1.0 - t) + sin(ang * 3.0) * 0.15 * (1.0 - t), sin(ang) * r)
	_face_local(p - position)
	position = p


func _hop(t: float, a: Vector3, b: Vector3) -> void:
	position = a.lerp(b, t) + Vector3.UP * sin(t * PI) * 0.55


func _land(face: Vector3) -> void:
	play(&"idle")
	_face(face)
	var tw := create_tween()
	tw.tween_property(_body, ^"scale", Vector3(1.25, 0.75, 1.25), 0.08)
	tw.tween_property(_body, ^"scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## 모델 앞(+Z)이 전역 방향 dir(수평)을 보게 한다.
func _face(dir: Vector3) -> void:
	_face_local(_to_local_dir(dir))


func _face_local(dir: Vector3) -> void:
	dir.y = 0.0
	if dir.length() > 0.001:
		rotation.y = atan2(dir.x, dir.z)


## 코드로 만든 나비: 몸통 하나, 위·아래 둥근 날개 한 쌍씩이 팔랑인다.
func _butterfly() -> Node3D:
	var root := Node3D.new()
	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.03
	cap.height = 0.24
	body.mesh = cap
	body.rotation.x = PI / 2.0
	body.position.y = 0.22
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color("#3A2A22")
	body.material_override = dark
	root.add_child(body)
	var color: Color = KINDS[kind].color
	var lobe := SphereMesh.new()
	lobe.radius = 0.5
	lobe.height = 1.0
	lobe.radial_segments = 12
	lobe.rings = 6
	for side in [-1.0, 1.0]:
		var pivot := Node3D.new()
		pivot.position.y = 0.22
		root.add_child(pivot)
		# 위 날개는 크고 진하게, 아래 날개는 작고 밝게
		for w in [[Vector3(0.17, 0.0, 0.05), Vector3(0.28, 0.02, 0.22), color], [Vector3(0.12, 0.0, -0.09), Vector3(0.18, 0.02, 0.15), color.lightened(0.35)]]:
			var wing := MeshInstance3D.new()
			wing.mesh = lobe
			var m := StandardMaterial3D.new()
			m.albedo_color = w[2]
			m.emission_enabled = true
			m.emission = w[2]
			m.emission_energy_multiplier = 0.2
			wing.material_override = m
			wing.scale = w[1]
			wing.position = Vector3(side * w[0].x, w[0].y, w[0].z)
			pivot.add_child(wing)
		pivot.rotation.z = -side * 1.0
		_wings.append(pivot)
	return root
