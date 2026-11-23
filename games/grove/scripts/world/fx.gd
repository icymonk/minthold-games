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
