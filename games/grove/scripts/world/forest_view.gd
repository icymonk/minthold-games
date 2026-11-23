class_name ForestView
extends Node3D
## 떠 있는 숲 섬(3D). 하늘·빛·섬·나무·풀·카메라를 만든다.
## 나무·풀·바위는 Quaternius Stylized Nature MegaKit(CC0) 모델에 공통 재질(nature.gdshader)을 씌운다.

enum Mode { ORBIT, FIXED }

const ISLAND_RADIUS := 6.4
const PLOT_SPACING := 3.0
const PITCH_DEG := 40.0
const DISTANCE := 34.0
const TURN_TIME := 0.5
## 계절별 [풀, 하늘 위, 지평선]: 봄 연두 → 여름 초록 → 가을 단풍 → 겨울 눈
const SEASONS := [
	[Color("#7DB24A"), Color("#8DB8D6"), Color("#F7CF97")],
	[Color("#5A8E3C"), Color("#6FA6D2"), Color("#F5D59C")],
	[Color("#B98A3E"), Color("#9186B8"), Color("#F3A65A")],
	[Color("#E6ECEE"), Color("#A3B5CC"), Color("#EBD8E2")],
]
## 계절별 [안개, 아래 먼 숲]
const DISTANCE_TINT := [
	[Color("#B3B580"), Color("#3D6338")],
	[Color("#A3AF78"), Color("#2F5530")],
	[Color("#C2A67A"), Color("#7A5A2E")],
	[Color("#CDD6DC"), Color("#AEBBBC")],
]
## 덤불·꽃·고사리 재질의 계절 색(겨울은 눈 덮인 색으로 다시 칠한다)
const PLANT_TINT := {
	&"Leaves": [Color.WHITE, Color("#D8E8C8"), Color("#F2C27A"), Color("#E4E9EA")],
	&"Leaves_TwistedTree": [Color.WHITE, Color("#D2E4C0"), Color("#E8A860"), Color("#E4E9EA")],
	&"Leaves_NormalTree": [Color.WHITE, Color("#D8E8C8"), Color("#EEB466"), Color("#E4E9EA")],
	&"Flowers": [Color.WHITE, Color.WHITE, Color("#F0D0A0"), Color("#EEF0F0")],
}
## 0-2 보기용 숲: 땅 자리 9칸 중 가운데를 빈 자리로 두고 8종을 심는다
const DEMO_FOREST: Array[StringName] = [
	&"fir", &"birch", &"oak", &"maple", &"", &"pine", &"linden", &"chestnut", &"beech",
]

var mode := Mode.ORBIT
## 90°씩 돌린 횟수(0~3)
var turn_step := 0

var _rig: Node3D
var _camera: Camera3D
var _island: Node3D
var _grass_mat: StandardMaterial3D
var _blades: ShaderMaterial
var _far: ShaderMaterial
var _trees: Array[ForestTree] = []
var _plot_glow: MeshInstance3D
var _season := 0
var _sky_mat: ProceduralSkyMaterial
var _env: Environment
var _rng := RandomNumberGenerator.new()
var _time := 0.0
var _yaw := 45.0
var _yaw_tween: Tween
var _season_tween: Tween


func _ready() -> void:
	_rng.seed = 20261123
	_build_environment()
	_build_island()
	_build_backdrop()
	plant_demo()
	_build_camera()
	set_season(0, false)


func _process(delta: float) -> void:
	_time += delta
	_island.position.y = sin(_time * 0.8) * 0.12
	if mode == Mode.ORBIT:
		_yaw = wrapf(_yaw + delta * 6.0, 0.0, 360.0)
	_rig.rotation_degrees.y = _yaw
	if _plot_glow:
		_plot_glow.scale = Vector3.ONE * (1.0 + sin(_time * 2.4) * 0.06)


## 땅 자리 9칸(3×3)의 섬 기준 위치. 0-2부터 나무를 여기에 심는다.
static func plot_positions() -> Array[Vector3]:
	var out: Array[Vector3] = []
	for z in range(-1, 2):
		for x in range(-1, 2):
			out.append(Vector3(x * PLOT_SPACING, 0.0, z * PLOT_SPACING))
	return out


func set_mode(m: Mode) -> void:
	mode = m
	if mode == Mode.FIXED:
		_tween_yaw(45.0 + turn_step * 90.0)


## dir: -1 왼쪽, +1 오른쪽으로 섬을 90° 돌려 본다.
func turn(dir: int) -> void:
	turn_step = posmod(turn_step + dir, 4)
	_tween_yaw(_yaw + dir * 90.0)


## 땅 자리 i에 나무를 심는다(빈 이름이면 비운다).
func plant(i: int, kind: StringName) -> ForestTree:
	if _trees[i]:
		_trees[i].queue_free()
		_trees[i] = null
	if kind == &"":
		return null
	var t := ForestTree.make(kind, _season)
	t.position = plot_positions()[i]
	t.rotation.y = _rng.randf_range(-0.6, 0.6)
	_island.add_child(t)
	_trees[i] = t
	return t


func plant_demo() -> void:
	for i in DEMO_FOREST.size():
		plant(i, DEMO_FOREST[i])


func tree_at(i: int) -> ForestTree:
	return _trees[i]


func set_season(i: int, animate := true) -> void:
	_season = i
	var c: Array = SEASONS[i]
	for t in _trees:
		if t:
			t.set_season(i, animate)
	if _season_tween:
		_season_tween.kill()
	if not animate or not is_inside_tree():
		_blades.set_shader_parameter(&"tint", c[0].lightened(0.1))
		_env.fog_light_color = DISTANCE_TINT[i][0]
		_far.set_shader_parameter(&"tint", DISTANCE_TINT[i][1])
		for key in PLANT_TINT:
			_plant_mat(key).set_shader_parameter(&"tint", PLANT_TINT[key][i])
			_plant_mat(key).set_shader_parameter(&"recolor", 0.85 if i == 3 else 0.0)
		_grass_mat.albedo_color = c[0]
		_sky_mat.sky_top_color = c[1]
		_sky_mat.sky_horizon_color = c[2]
		_sky_mat.ground_horizon_color = c[2]
		return
	_season_tween = create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	_season_tween.tween_property(_grass_mat, ^"albedo_color", c[0], 1.2)
	_season_tween.tween_property(_blades, ^"shader_parameter/tint", c[0].lightened(0.1), 1.2)
	_season_tween.tween_property(_env, ^"fog_light_color", DISTANCE_TINT[i][0], 1.2)
	_season_tween.tween_property(_far, ^"shader_parameter/tint", DISTANCE_TINT[i][1], 1.2)
	for key in PLANT_TINT:
		var m := _plant_mat(key)
		_season_tween.tween_property(m, ^"shader_parameter/tint", PLANT_TINT[key][i], 1.2)
		_season_tween.tween_property(m, ^"shader_parameter/recolor", 0.85 if i == 3 else 0.0, 1.2)
	_season_tween.tween_property(_sky_mat, ^"sky_top_color", c[1], 1.2)
	_season_tween.tween_property(_sky_mat, ^"sky_horizon_color", c[2], 1.2)
	_season_tween.tween_property(_sky_mat, ^"ground_horizon_color", c[2], 1.2)


func _plant_mat(key: StringName) -> ShaderMaterial:
	var src := StandardMaterial3D.new()
	src.resource_name = key
	return Nature.shared(src)


func grass_color() -> Color:
	return _grass_mat.albedo_color


func _tween_yaw(target: float) -> void:
	if _yaw_tween:
		_yaw_tween.kill()
	# 가장 가까운 쪽으로 돈다
	var from := _yaw
	target = from + wrapf(target - from, -180.0, 180.0)
	_yaw_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_yaw_tween.tween_property(self, ^"_yaw", target, TURN_TIME)


func _build_environment() -> void:
	_sky_mat = ProceduralSkyMaterial.new()
	_sky_mat.ground_bottom_color = Color("#2F4A35")
	_sky_mat.ground_curve = 0.08
	_sky_mat.sun_angle_max = 25.0
	_sky_mat.sun_curve = 0.08
	var sky := Sky.new()
	sky.sky_material = _sky_mat
	_env = Environment.new()
	_env.background_mode = Environment.BG_SKY
	_env.sky = sky
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	_env.ambient_light_energy = 0.75
	_env.ambient_light_sky_contribution = 0.7
	_env.ambient_light_color = Color("#FFE4C2")
	_env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_env.tonemap_white = 6.0
	_env.glow_enabled = true
	_env.glow_intensity = 0.55
	_env.glow_bloom = 0.08
	_env.ssao_enabled = true
	_env.ssao_intensity = 1.6
	_env.ssao_radius = 1.2
	_env.fog_enabled = true
	_env.fog_light_color = DISTANCE_TINT[0][0]
	_env.fog_density = 0.0045
	_env.fog_aerial_perspective = 0.4
	_env.fog_sky_affect = 0.0
	_env.adjustment_enabled = true
	_env.adjustment_saturation = 1.12
	_env.adjustment_contrast = 1.05
	var world := WorldEnvironment.new()
	world.environment = _env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color("#FFD29A")
	sun.light_energy = 1.7
	sun.shadow_enabled = true
	sun.shadow_blur = 1.5
	sun.directional_shadow_max_distance = 70.0
	sun.rotation_degrees = Vector3(-34.0, -40.0, 0.0)
	add_child(sun)
	# 그늘 쪽을 살짝 푸르게 채우는 빛
	var fill := DirectionalLight3D.new()
	fill.light_color = Color("#B9C8E8")
	fill.light_energy = 0.25
	fill.rotation_degrees = Vector3(-50.0, 140.0, 0.0)
	add_child(fill)


func _build_island() -> void:
	_island = Node3D.new()
	_island.name = "Island"
	add_child(_island)
	_grass_mat = _mat(SEASONS[0][0])
	# 풀 윗면 → 두꺼운 흙 절벽 → 아래로 뾰족한 바위
	_add_mesh(_island, _cylinder(ISLAND_RADIUS, ISLAND_RADIUS - 0.15, 0.4, 28, 0.08), _grass_mat, Vector3(0, -0.2, 0))
	_add_mesh(_island, _cylinder(ISLAND_RADIUS - 0.1, ISLAND_RADIUS - 0.7, 1.8, 24, 0.22), _mat(Color("#7A5132")), Vector3(0, -1.3, 0))
	_add_mesh(_island, _cylinder(ISLAND_RADIUS - 0.7, ISLAND_RADIUS - 2.4, 1.6, 18, 0.35), _mat(Color("#5E4634")), Vector3(0, -2.9, 0))
	_add_mesh(_island, _cylinder(ISLAND_RADIUS - 2.4, 0.4, 4.5, 12, 0.5), _mat(Color("#6A625A")), Vector3(0, -5.9, 0))
	# 절벽에 박힌 바위
	for i in 14:
		var a := TAU * (i + _rng.randf() * 0.6) / 14.0
		var rock := Nature.spawn("Rock_Medium_%d" % (i % 3 + 1))
		rock.position = Vector3(cos(a), 0, sin(a)) * (ISLAND_RADIUS - 0.9) + Vector3(0, _rng.randf_range(-3.0, -0.9), 0)
		rock.rotation.y = _rng.randf() * TAU
		rock.scale = Vector3.ONE * _rng.randf_range(0.45, 0.8)
		_island.add_child(rock)
	_trees.resize(plot_positions().size())
	_plot_glow = _add_mesh(_island, _ring_mesh(1.05, 1.25), _glow_mat(), plot_positions()[4] + Vector3(0, 0.03, 0))
	_plot_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_add_mesh(_island, _cylinder(0.95, 1.05, 0.08, 14, 0.03), _mat(Color("#6B4A2E")), plot_positions()[4] + Vector3(0, 0.02, 0))
	_blades = Nature.make(Nature.mesh_of("Grass_Common_Short").surface_get_material(0), SEASONS[0][0].lightened(0.1), 0.8)
	_scatter("Grass_Common_Short", 110, 0.35, 0.6, _blades)
	_scatter("Grass_Wispy_Short", 60, 0.3, 0.5, _blades)
	_scatter("Grass_Common_Tall", 30, 0.3, 0.45, _blades)
	_scatter("Clover_1", 30, 0.4, 0.6)
	_scatter("Pebble_Round_1", 24, 0.5, 0.9)
	_scatter("Pebble_Round_3", 18, 0.5, 0.9)
	var props := [
		["Flower_3_Group", 9, 0.35, 0.55], ["Flower_4_Group", 8, 0.3, 0.5],
		["Bush_Common_Flowers", 5, 0.45, 0.6], ["Bush_Common", 5, 0.45, 0.65],
		["Fern_1", 6, 0.35, 0.5], ["Mushroom_Common", 7, 0.5, 0.8], ["Rock_Medium_2", 3, 0.25, 0.4],
		["Plant_1", 5, 0.4, 0.6],
	]
	for p in props:
		for k in p[1]:
			var node := Nature.spawn(p[0])
			node.position = _free_spot(0.9)
			node.rotation.y = _rng.randf() * TAU
			node.scale = Vector3.ONE * _rng.randf_range(p[2], p[3])
			_island.add_child(node)


## 섬 아래 멀리 깔린 숲 바다와 구름. 안개에 묻혀 깊이감을 준다.
func _build_backdrop() -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(260, 260)
	ground.mesh = plane
	ground.material_override = _mat(Color("#35573A"))
	ground.position.y = -34.0
	add_child(ground)
	var far := Nature.make(StandardMaterial3D.new(), DISTANCE_TINT[0][1], 1.0)
	_far = far
	far.set_shader_parameter(&"albedo_tex", load("res://assets/models/nature/Leaves_NormalTree_C.png"))
	far.set_shader_parameter(&"sway", 0.3)
	for model in ["Pine_3", "CommonTree_1", "Pine_1", "CommonTree_3"]:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = _flatten(model)
		mm.instance_count = 140
		for k in mm.instance_count:
			var a := _rng.randf() * TAU
			var r := _rng.randf_range(14.0, 90.0)
			var s := _rng.randf_range(0.6, 1.0)
			mm.set_instance_transform(k, Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * s), Vector3(cos(a) * r, -34.0, sin(a) * r)))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = far
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)
	# 섬 아래 뭉게구름: 매끈한 공 몇 개를 겹친다
	var cloud := _mat(Color("#FFF3E2"))
	cloud.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	var puff := SphereMesh.new()
	puff.radial_segments = 16
	puff.rings = 8
	for i in 6:
		var a := TAU * i / 6.0 + _rng.randf()
		var at := Vector3(cos(a) * 11.0, _rng.randf_range(-10.0, -7.5), sin(a) * 11.0)
		for k in 4:
			var node := _add_mesh(self, puff, cloud, at + Vector3(_rng.randf_range(-1.6, 1.6), _rng.randf_range(-0.2, 0.3), _rng.randf_range(-1.0, 1.0)))
			node.scale = Vector3.ONE * _rng.randf_range(1.0, 1.8) * Vector3(1.3, 0.75, 1.0)
			node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# 해 질 녘 떠다니는 빛 알갱이
	var motes := CPUParticles3D.new()
	motes.amount = 60
	motes.lifetime = 6.0
	motes.preprocess = 6.0
	motes.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	motes.emission_box_extents = Vector3(ISLAND_RADIUS, 1.5, ISLAND_RADIUS)
	motes.position.y = 2.0
	motes.direction = Vector3.UP
	motes.spread = 60.0
	motes.gravity = Vector3.ZERO
	motes.initial_velocity_min = 0.05
	motes.initial_velocity_max = 0.25
	var dot := SphereMesh.new()
	dot.radius = 0.04
	dot.height = 0.08
	dot.radial_segments = 6
	dot.rings = 3
	dot.material = _glow_mat()
	motes.mesh = dot
	_island.add_child(motes)


## 겹쳐 그릴 때 쓰려고 모델의 모든 면을 한 메시로 합친다(재질은 면마다 유지).
func _flatten(model: String) -> Mesh:
	var node := Nature.spawn(model)
	var out := ArrayMesh.new()
	for mi: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		for s in mi.mesh.get_surface_count():
			out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mi.mesh.surface_get_arrays(s))
			out.surface_set_material(out.get_surface_count() - 1, mi.get_surface_override_material(s))
	node.free()
	return out


func _scatter(model: String, count: int, smin: float, smax: float, mat: Material = null) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _flatten(model)
	mm.instance_count = count
	for k in count:
		var b := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(smin, smax))
		mm.set_instance_transform(k, Transform3D(b, _free_spot(0.45)))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.name = model
	if mat:
		mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_island.add_child(mmi)


## 섬 위 임의 자리. 나무 줄기·가운데 빈 자리에서 clearance만큼 떨어진 곳.
func _free_spot(clearance: float) -> Vector3:
	var plots := plot_positions()
	for _try in 30:
		var a := _rng.randf() * TAU
		var r := sqrt(_rng.randf()) * (ISLAND_RADIUS - 0.5)
		var p := Vector3(cos(a) * r, 0.0, sin(a) * r)
		var ok := p.distance_to(plots[4]) > 1.3
		for q in plots:
			ok = ok and p.distance_to(q) > clearance
		if ok:
			return p
	return Vector3(ISLAND_RADIUS - 0.8, 0, 0)


func _ring_mesh(inner: float, outer: float) -> Mesh:
	var t := TorusMesh.new()
	t.inner_radius = inner
	t.outer_radius = outer
	t.rings = 32
	t.ring_segments = 6
	return t


func _glow_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color("#FFE7A0")
	m.emission_enabled = true
	m.emission = Color("#FFD06A")
	m.emission_energy_multiplier = 2.5
	return m


func _build_camera() -> void:
	_rig = Node3D.new()
	_rig.name = "CameraRig"
	add_child(_rig)
	_camera = Camera3D.new()
	_camera.fov = 25.0
	_camera.far = 200.0
	var pitch := deg_to_rad(PITCH_DEG)
	_camera.position = Vector3(0, sin(pitch) * DISTANCE, cos(pitch) * DISTANCE)
	_rig.add_child(_camera)
	_camera.look_at_from_position(_camera.position, Vector3(0, 0.6, 0))
	_camera.current = true
	# 데스크톱(Forward+)에서만 먼 곳을 흐려 미니어처처럼 보이게 한다
	var attrs := CameraAttributesPractical.new()
	attrs.dof_blur_far_enabled = true
	attrs.dof_blur_far_distance = 52.0
	attrs.dof_blur_far_transition = 25.0
	attrs.dof_blur_amount = 0.06
	_camera.attributes = attrs


func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.95
	return m


func _add_mesh(parent: Node3D, mesh: Mesh, mat: Material, at: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = at
	parent.add_child(mi)
	return mi


## 꼭짓점을 조금씩 흔든 각진 원기둥(평면 셰이딩 로우폴리).
func _cylinder(top: float, bottom: float, height: float, sides: int, jitter: float) -> Mesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = height
	m.radial_segments = sides
	m.rings = 1
	return _faceted(m, jitter)


func _rock(size: float) -> Mesh:
	var m := SphereMesh.new()
	m.radius = size
	m.height = size * 1.3
	m.radial_segments = 7
	m.rings = 4
	return _faceted(m, size * 0.25)


func _faceted(source: PrimitiveMesh, jitter: float) -> Mesh:
	var arrays := source.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var moved := {}
	for i in verts.size():
		var key := verts[i].snapped(Vector3.ONE * 0.001)
		if not moved.has(key):
			moved[key] = Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-0.5, 0.5), _rng.randf_range(-1, 1)) * jitter
		verts[i] += moved[key]
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = null
	arrays[Mesh.ARRAY_TANGENT] = null
	var base := ArrayMesh.new()
	base.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var st := SurfaceTool.new()
	st.create_from(base, 0)
	st.deindex()
	st.generate_normals()
	return st.commit()
