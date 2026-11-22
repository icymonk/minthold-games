class_name ForestView
extends Node3D
## 떠 있는 숲 섬(3D). 하늘·빛·섬·땅 자리·카메라를 코드로 만든다.
## 0-2에서 섬과 소품을 CC0 팩 모델로 바꾸고, 나무 씬(Socket 4개)을 땅 자리에 심는다.

enum Mode { ORBIT, FIXED }

const ISLAND_RADIUS := 6.4
const PLOT_SPACING := 3.0
const PITCH_DEG := 40.0
const DISTANCE := 40.0
const TURN_TIME := 0.5
## 계절별 [풀, 하늘 위, 지평선]: 봄 연두 → 여름 초록 → 가을 단풍 → 겨울 눈
const SEASONS := [
	[Color("#A8D672"), Color("#7FB3D9"), Color("#F6D9B0")],
	[Color("#6E9A4F"), Color("#5E9AD0"), Color("#F2E3B8")],
	[Color("#D98A3D"), Color("#8C7FB8"), Color("#F29E4C")],
	[Color("#E9EEF0"), Color("#9BB0C8"), Color("#E8D9E6")],
]

var mode := Mode.ORBIT
## 90°씩 돌린 횟수(0~3)
var turn_step := 0

var _rig: Node3D
var _camera: Camera3D
var _island: Node3D
var _grass_mat: StandardMaterial3D
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
	_build_camera()
	set_season(0, false)


func _process(delta: float) -> void:
	_time += delta
	_island.position.y = sin(_time * 0.8) * 0.12
	if mode == Mode.ORBIT:
		_yaw = wrapf(_yaw + delta * 6.0, 0.0, 360.0)
	_rig.rotation_degrees.y = _yaw


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


func set_season(i: int, animate := true) -> void:
	var c: Array = SEASONS[i]
	if _season_tween:
		_season_tween.kill()
	if not animate or not is_inside_tree():
		_grass_mat.albedo_color = c[0]
		_sky_mat.sky_top_color = c[1]
		_sky_mat.sky_horizon_color = c[2]
		_sky_mat.ground_horizon_color = c[2]
		return
	_season_tween = create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	_season_tween.tween_property(_grass_mat, ^"albedo_color", c[0], 1.2)
	_season_tween.tween_property(_sky_mat, ^"sky_top_color", c[1], 1.2)
	_season_tween.tween_property(_sky_mat, ^"sky_horizon_color", c[2], 1.2)
	_season_tween.tween_property(_sky_mat, ^"ground_horizon_color", c[2], 1.2)


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
	_sky_mat.ground_bottom_color = Style.FOREST
	_sky_mat.ground_curve = 0.12
	_sky_mat.sun_angle_max = 20.0
	var sky := Sky.new()
	sky.sky_material = _sky_mat
	_env = Environment.new()
	_env.background_mode = Environment.BG_SKY
	_env.sky = sky
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	_env.ambient_light_energy = 0.9
	_env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_env.glow_enabled = true
	_env.glow_intensity = 0.4
	_env.ssao_enabled = true
	_env.ssao_intensity = 1.2
	_env.fog_enabled = true
	_env.fog_light_color = Color("#F6D9B0")
	_env.fog_density = 0.004
	_env.fog_sky_affect = 0.0
	_env.adjustment_enabled = true
	_env.adjustment_saturation = 1.1
	var world := WorldEnvironment.new()
	world.environment = _env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color("#FFE2B8")
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 80.0
	sun.rotation_degrees = Vector3(-38.0, -30.0, 0.0)
	add_child(sun)


func _build_island() -> void:
	_island = Node3D.new()
	_island.name = "Island"
	add_child(_island)
	_grass_mat = _mat(SEASONS[0][0])
	# 풀 윗면 → 흙 띠 → 아래로 뾰족한 바위
	_add_mesh(_island, _cylinder(ISLAND_RADIUS, ISLAND_RADIUS - 0.3, 0.5, 16, 0.12), _grass_mat, Vector3(0, -0.25, 0))
	_add_mesh(_island, _cylinder(ISLAND_RADIUS - 0.3, ISLAND_RADIUS - 1.4, 1.2, 14, 0.2), _mat(Color("#7A5534")), Vector3(0, -1.1, 0))
	_add_mesh(_island, _cylinder(ISLAND_RADIUS - 1.4, 0.5, 5.0, 11, 0.45), _mat(Color("#6B6258")), Vector3(0, -4.2, 0))
	var soil := _mat(Color("#5A3E28"))
	for p in plot_positions():
		_add_mesh(_island, _cylinder(1.0, 1.1, 0.14, 10, 0.06), soil, p + Vector3(0, 0.06, 0))
	# 벌목 뒤 남은 그루터기와 바위(임시 소품, 0-2에서 팩 모델로)
	var bark := _mat(Color("#6E4B2E"))
	var ring := _mat(Color("#D8B98A"))
	var rock := _mat(Color("#8E8A80"))
	for i in 9:
		var a := TAU * (i + _rng.randf() * 0.5) / 9.0
		var r := _rng.randf_range(4.6, 5.6)
		var at := Vector3(cos(a) * r, 0.0, sin(a) * r)
		if i % 3 == 0:
			var h := _rng.randf_range(0.35, 0.6)
			_add_mesh(_island, _cylinder(0.32, 0.42, h, 8, 0.03), bark, at + Vector3(0, h / 2.0, 0))
			_add_mesh(_island, _cylinder(0.3, 0.3, 0.02, 8, 0.0), ring, at + Vector3(0, h + 0.01, 0))
		else:
			_add_mesh(_island, _rock(_rng.randf_range(0.25, 0.55)), rock, at + Vector3(0, 0.1, 0))
	var cloud := _mat(Color("#FFF8EE"))
	for i in 6:
		var a := TAU * i / 6.0 + _rng.randf()
		var node := _add_mesh(self, _rock(1.0), cloud, Vector3(cos(a) * 12.5, _rng.randf_range(-9.0, -6.0), sin(a) * 12.5))
		node.scale = Vector3(_rng.randf_range(1.2, 1.8), 0.5, _rng.randf_range(0.9, 1.3))
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


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
	_camera.look_at_from_position(_camera.position, Vector3(0, -0.8, 0))
	_camera.current = true


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
