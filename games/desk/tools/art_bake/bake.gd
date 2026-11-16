extends SceneTree
## Kenney 가구 3D 모델(CC0)을 비스듬히 위에서 찍어 구역 그림으로 굽는다.
## 사용: godot --rendering-driver opengl3 --path . -s bake.gd -- <출력 폴더>

const SIZE := Vector2i(640, 640)

## 그림 이름 → [모델, 위치, y축 회전] 목록. 위치의 y가 "top"이면 앞 모델 윗면에 올린다.
const SCENES := {
	"zone_floor": [["desk", Vector3.ZERO, 0.0], ["computerScreen", Vector3(0.05, -1, -0.05), 0.0],
		["computerKeyboard", Vector3(0.1, -1, 0.12), 0.0], ["chairDesk", Vector3(0.42, 0, 0.32), 200.0]],
	"zone_building": [["kitchenBar", Vector3.ZERO, 0.0], ["kitchenCoffeeMachine", Vector3(0.1, -1, 0.0), 0.0],
		["stoolBar", Vector3(0.0, 0, 0.5), 0.0], ["stoolBar", Vector3(0.45, 0, 0.5), 0.0]],
	"zone_outside": [["bench", Vector3.ZERO, 0.0], ["pottedPlant", Vector3(-0.45, 0, 0.0), 0.0],
		["trashcan", Vector3(0.95, 0, 0.05), 0.0], ["plantSmall2", Vector3(-0.1, 0, 0.55), 0.0]],
	"empty_chair": [["chairDesk", Vector3.ZERO, 200.0]],
}

var _out: String


func _init() -> void:
	_out = OS.get_cmdline_user_args()[0]
	await process_frame
	for name in SCENES:
		await _bake(name, SCENES[name])
	quit()


func _bake(name: String, parts: Array) -> void:
	var vp := _studio()
	var set := Node3D.new()
	vp.add_child(set)
	var base: Node3D
	for p in parts:
		var n: Node3D = load("res://models/%s.glb" % p[0]).instantiate()
		var at: Vector3 = p[1]
		n.rotation_degrees.y = p[2]
		set.add_child(n)
		await process_frame
		var own := _aabb(n)
		if at.y < 0 and base != null:
			var b := _aabb(base)
			at = Vector3(b.position.x + at.x, b.end.y, b.position.z + at.z)
		n.position = at - Vector3(own.position.x, own.position.y, own.position.z) if at.y > 0 else at
		if base == null:
			base = n
	var box := _aabb(set)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = box.size.length() * 1.05
	var dir := Vector3(1, 0.9, 1.25).normalized()
	cam.position = box.get_center() + dir * 20
	vp.add_child(cam)
	cam.look_at(box.get_center())
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	vp.queue_free()
	img = img.get_region(img.get_used_rect())
	img.save_png(_out.path_join(name + ".png"))


func _studio() -> SubViewport:
	var vp := SubViewport.new()
	vp.size = SIZE
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.light_energy = 1.3
	vp.add_child(sun)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.95, 0.9, 0.85)
	env.ambient_light_energy = 0.45
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	return vp


func _aabb(n: Node) -> AABB:
	var out := AABB()
	var first := true
	for m in n.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = m.global_transform * m.get_aabb()
		out = b if first else out.merge(b)
		first = false
	return out
