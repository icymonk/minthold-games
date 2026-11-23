class_name Fx
extends RefCounted
## 짧게 터지고 사라지는 3D 파티클(흙·잎·포자·꽃잎·반짝임).


static func burst(parent: Node3D, at: Vector3, colors: Array[Color], amount := 24, speed := 2.0, size := 0.06, gravity := -4.0) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 0.9
	p.amount = amount
	p.lifetime = 0.9
	p.position = at
	p.direction = Vector3.UP
	p.spread = 70.0
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.gravity = Vector3(0, gravity, 0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	var curve := Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0))
	p.scale_amount_curve = curve
	var g := Gradient.new()
	g.colors = PackedColorArray(colors)
	p.color_initial_ramp = g
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE * size
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mesh.material = mat
	p.mesh = mesh
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)
	return p


## 날아다니는 동안 뒤에 남는 반짝임. 끝나면 emitting=false 후 지운다.
static func trail(parent: Node3D, color: Color) -> CPUParticles3D:
	var p := burst(parent, Vector3(0, 0.2, 0), [color, Color(1, 1, 1, 0)], 30, 0.3, 0.05, 0.0)
	p.one_shot = false
	p.explosiveness = 0.0
	p.local_coords = false
	p.lifetime = 0.6
	return p


## 반투명한 미리 보기 모습으로 바꾼다.
static func ghostify(node: Node) -> void:
	var overlay := StandardMaterial3D.new()
	overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	overlay.albedo_color = Color(1.0, 0.86, 0.62, 0.22)
	overlay.no_depth_test = true
	for g: GeometryInstance3D in node.find_children("*", "GeometryInstance3D", true, false):
		g.transparency = 0.5
		g.material_overlay = overlay
		g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## 계절 소품(3-2): 섬 위로 늘 내리는 것 — 봄 꽃잎, 여름 반딧불, 가을 낙엽, 겨울 눈.
## [색들, 떨어지는 힘, 흔들림, 크기, 빛남]
const SEASON_PROPS := [
	[[Color("#FF9EC4"), Color("#FFD6E6")], -0.35, 0.6, 0.2, false],
	[[Color("#F4FF7A"), Color("#C8FF6A")], 0.0, 0.35, 0.08, true],
	[[Color("#F0802A"), Color("#D0401E"), Color("#F0C02A")], -0.5, 0.8, 0.22, false],
	[[Color("#FFFFFF"), Color("#E6F0FF")], -0.6, 0.25, 0.08, false],
]


static func season_props(season: int, radius: float) -> CPUParticles3D:
	var d: Array = SEASON_PROPS[season]
	var p := CPUParticles3D.new()
	p.name = "SeasonProps"
	p.amount = 160 if season != 1 else 80
	p.lifetime = 7.0
	p.preprocess = 7.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(radius, 0.4, radius)
	p.position.y = 5.5 if d[1] < 0.0 else 1.6
	p.direction = Vector3(1, 0, 0.3)
	p.spread = 180.0
	p.gravity = Vector3(0, d[1], 0)
	p.initial_velocity_min = 0.05
	p.initial_velocity_max = d[2]
	p.angular_velocity_min = -90.0
	p.angular_velocity_max = 90.0
	p.particle_flag_rotate_y = true
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.3
	var g := Gradient.new()
	g.colors = PackedColorArray(d[0])
	p.color_initial_ramp = g
	var mesh: Mesh
	if season == 1 or season == 3:
		var sphere := SphereMesh.new()
		sphere.radius = d[3]
		sphere.height = d[3] * 2.0
		sphere.radial_segments = 6
		sphere.rings = 3
		mesh = sphere
	else:
		var quad := QuadMesh.new()
		quad.size = Vector2(d[3] * 1.6, d[3])
		mesh = quad
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if d[4]:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.emission_enabled = true
		mat.emission = d[0][0]
		mat.emission_energy_multiplier = 6.0
	mesh.material = mat
	p.mesh = mesh
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if d[4]:
		# 반딧불은 깜빡인다
		var curve := Curve.new()
		curve.add_point(Vector2(0, 0))
		curve.add_point(Vector2(0.2, 1))
		curve.add_point(Vector2(0.5, 0.2))
		curve.add_point(Vector2(0.8, 1))
		curve.add_point(Vector2(1, 0))
		p.scale_amount_curve = curve
	return p


## 이웃끼리 반응(3-2): 점수가 오른 이웃 위로 반짝임이 튄다.
static func cheer(parent: Node3D, at: Vector3, color: Color) -> void:
	burst(parent, at + Vector3(0, 0.3, 0), [color.lightened(0.4), Color("#FFF4D6")], 16, 1.6, 0.05, -2.0)
