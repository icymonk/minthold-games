class_name ForestTree
extends Node3D
## 숲 나무 한 그루. 생물이 붙는 자리(Socket) 4개를 갖는다.
## 자리는 나무의 자식이라 카메라를 돌려도 왼쪽/오른쪽이 나무 기준으로 그대로다.

const SOCKETS: Array[StringName] = [&"Top", &"Bottom", &"Left", &"Right"]
## 종 → 모델, 크기, 계절별 잎 색(봄·여름·가을·겨울), 줄기 색, 줄기 다시 칠하기
const SPECIES := {
	&"oak": {model = "CommonTree_2", scale = 0.56, bark = Color("#FFFFFF"), bark_recolor = 0.0,
		leaves = [Color("#8DBF4A"), Color("#4F8A3A"), Color("#C07A2E"), Color("#E4E6E2")]},
	&"birch": {model = "CommonTree_4", scale = 0.46, bark = Color("#F2EEE4"), bark_recolor = 1.0,
		leaves = [Color("#B8DA5E"), Color("#82B447"), Color("#EAC24A"), Color("#E9ECEA")]},
	&"pine": {model = "TwistedTree_1", scale = 0.2, bark = Color("#FFFFFF"), bark_recolor = 0.0,
		leaves = [Color("#5E8F4A"), Color("#3F6E3A"), Color("#4E7742"), Color("#C9D8D2")]},
	&"fir": {model = "Pine_3", scale = 0.6, bark = Color("#FFFFFF"), bark_recolor = 0.0,
		leaves = [Color("#4F8550"), Color("#2F5E3F"), Color("#37623F"), Color("#CFDDD8")]},
	&"maple": {model = "CommonTree_5", scale = 0.56, bark = Color("#FFFFFF"), bark_recolor = 0.0,
		leaves = [Color("#A3CF5C"), Color("#5E9A43"), Color("#DB4A2E"), Color("#ECE8E4")]},
	&"chestnut": {model = "CommonTree_1", scale = 0.58, bark = Color("#B08A6A"), bark_recolor = 0.0,
		leaves = [Color("#9CC657"), Color("#5A8F3C"), Color("#CC8B34"), Color("#E1DDD6")]},
	&"linden": {model = "CommonTree_3", scale = 0.46, bark = Color("#FFFFFF"), bark_recolor = 0.0,
		leaves = [Color("#B6D96A"), Color("#6AA548"), Color("#E5B43E"), Color("#E6E4DE")]},
	&"beech": {model = "CommonTree_2", scale = 0.5, bark = Color("#A9A59C"), bark_recolor = 0.85,
		leaves = [Color("#9DC25A"), Color("#4E8640"), Color("#C2622E"), Color("#E0DAD2")]},
}

var species: StringName
var _leaves: ShaderMaterial
var _markers: Array[Node3D] = []
var _ring: MeshInstance3D
var _tween: Tween


static func make(kind: StringName, season := 0) -> ForestTree:
	var t := ForestTree.new()
	t.species = kind
	t.name = String(kind).capitalize()
	t._build(season)
	return t


func socket(side: StringName) -> Marker3D:
	return get_node(NodePath(String(side))) as Marker3D


func set_season(i: int, animate := true) -> void:
	var c: Color = SPECIES[species].leaves[i]
	if _tween:
		_tween.kill()
	if not animate or not is_inside_tree():
		_leaves.set_shader_parameter(&"tint", c)
		return
	_tween = create_tween().set_trans(Tween.TRANS_SINE)
	_tween.tween_property(_leaves, ^"shader_parameter/tint", c, 1.2)


## 0-3에서 카드를 끌 때 붙일 자리를 보여 준다.
func show_sockets(on: bool) -> void:
	for m in _markers:
		m.visible = on


## 네 자리가 모두 차면 수관에 작은 빛 고리
func set_complete(on: bool) -> void:
	_ring.visible = on


func _build(season: int) -> void:
	var d: Dictionary = SPECIES[species]
	var src := Nature.scene(d.model).instantiate()
	var overrides := {}
	for mi: MeshInstance3D in src.find_children("*", "MeshInstance3D", true, false):
		for s in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(s)
			var key := StringName(mat.resource_name)
			if key.begins_with("Leaves"):
				_leaves = Nature.make(mat, d.leaves[season], 1.0)
				overrides[key] = _leaves
			elif d.bark_recolor > 0.0 or d.bark != Color.WHITE:
				overrides[key] = Nature.make(mat, d.bark, d.bark_recolor)
	src.free()
	var model := Nature.spawn(d.model, overrides)
	model.name = "Model"
	model.scale = Vector3.ONE * d.scale * 1.12
	add_child(model)
	var box := _bounds(model)
	var r := minf(box.size.x, box.size.z) * 0.5
	var top := box.end.y
	_add_socket(&"Top", Vector3(0, top * 0.86, 0), Vector3.UP)
	_add_socket(&"Bottom", Vector3(0, 0.05, r * 0.55), Vector3.DOWN)
	_add_socket(&"Left", Vector3(-r * 0.75, 0.05, 0), Vector3.LEFT)
	_add_socket(&"Right", Vector3(r * 0.75, 0.05, 0), Vector3.RIGHT)
	_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = r * 0.9
	torus.outer_radius = r * 1.0
	_ring.mesh = torus
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = Color("#FFE9A8")
	glow.emission_enabled = true
	glow.emission = Color("#FFD36B")
	glow.emission_energy_multiplier = 2.0
	_ring.material_override = glow
	_ring.position.y = top * 0.62
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ring.visible = false
	add_child(_ring)


func _add_socket(side: StringName, at: Vector3, dir: Vector3) -> void:
	var s := Marker3D.new()
	s.name = String(side)
	s.position = at
	add_child(s)
	# 잎 모양 방향 표시: 납작한 원뿔이 바깥쪽을 가리킨다
	var leaf := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.16
	cone.height = 0.36
	cone.radial_segments = 6
	cone.rings = 1
	leaf.mesh = cone
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color("#FFF1B8")
	leaf.material_override = mat
	leaf.scale = Vector3(1.0, 1.0, 0.35)
	if dir != Vector3.UP:
		leaf.basis = Basis(Quaternion(Vector3.UP, dir)) * Basis.from_scale(leaf.scale)
	leaf.position = dir * 0.3 + Vector3(0, 0.2 if dir != Vector3.UP else 0.0, 0)
	leaf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	leaf.visible = false
	s.add_child(leaf)
	_markers.append(leaf)


static func _bounds(node: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for mi: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = node.transform * (mi.transform * mi.get_aabb())
		box = b if first else box.merge(b)
		first = false
	return box
