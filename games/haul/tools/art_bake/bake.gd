extends SceneTree
## Kenney 3D 모델(CC0)을 정사영으로 찍어 2D 그림으로 굽는다.
## 사용: godot --rendering-driver opengl3 --path . -s bake.gd -- <출력 폴더>

## 1m당 픽셀. 게임에서는 절반 크기로 그린다.
const PX_PER_M := 690.0

var _out: String


func _init() -> void:
	_out = OS.get_cmdline_user_args()[0]
	await process_frame
	await _bake_truck()
	await _bake_wheel()
	await _bake_city()
	quit()


func _studio(size: Vector2i) -> SubViewport:
	var vp := SubViewport.new()
	vp.size = size
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, -30, 0)
	sun.light_energy = 1.1
	vp.add_child(sun)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.78, 0.9)
	env.ambient_light_energy = 0.8
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	return vp


func _side_camera(vp: SubViewport, center: Vector3) -> void:
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = vp.size.y / PX_PER_M
	cam.position = center + Vector3(0, 0, 20)
	vp.add_child(cam)


func _shoot(vp: SubViewport) -> Image:
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	vp.queue_free()
	return img


## 옆에서 본 배송 트럭. 운전석이 왼쪽을 보게 돌리고, 초록 짐칸 앞까지만 잘라 운전석만 남긴다.
func _bake_truck() -> void:
	var vp := _studio(Vector2i(2400, 1200))
	var truck: Node3D = load("res://models/car/delivery.glb").instantiate()
	truck.rotation_degrees.y = -90
	vp.add_child(truck)
	await process_frame
	_side_camera(vp, _aabb(truck).get_center())
	var img: Image = await _shoot(vp)
	img = img.get_region(img.get_used_rect())
	var cut := _first_green_column(img)
	img = img.get_region(Rect2i(0, 0, cut - 2, img.get_height()))
	img.save_png(_out.path_join("cab.png"))


func _first_green_column(img: Image) -> int:
	var y := img.get_height() / 3
	for x in img.get_width():
		var c := img.get_pixel(x, y)
		if c.a > 0.9 and c.g > c.r + 0.2 and c.g > c.b:
			return x
	return img.get_width()


func _bake_wheel() -> void:
	var vp := _studio(Vector2i(440, 440))
	var wheel: Node3D = load("res://models/car/wheel-truck.glb").instantiate()
	wheel.rotation_degrees.y = -90
	vp.add_child(wheel)
	await process_frame
	_side_camera(vp, _aabb(wheel).get_center())
	var img: Image = await _shoot(vp)
	img.get_region(img.get_used_rect()).save_png(_out.path_join("wheel.png"))


## 새벽 도시: 뒷줄 고층 건물, 앞줄 상가, 주황빛 지평선.
func _bake_city() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(1920, 1080)
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var tall := ["a", "b", "c", "d", "e"]
	var low := ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n"]
	var x := -16.0
	while x < 16.0:
		_place(vp, "building-skyscraper-%s" % tall[rng.randi() % tall.size()], Vector3(x, 0, -9 - rng.randf() * 3), 1.6)
		x += 2.2 + rng.randf() * 1.2
	x = -13.0
	while x < 13.0:
		_place(vp, "building-%s" % low[rng.randi() % low.size()], Vector3(x, 0, -3.5), 1.25)
		x += 1.45
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(80, 80)
	ground.mesh = plane
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color("#3b4157")
	ground.material_override = gm
	vp.add_child(ground)
	var cam := Camera3D.new()
	cam.fov = 38
	cam.position = Vector3(0, 0.6, 9)
	cam.rotation_degrees = Vector3(9, 0, 0)
	vp.add_child(cam)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-12, -60, 0)
	sun.light_color = Color("#ffa060")
	sun.light_energy = 0.7
	vp.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-50, 40, 0)
	fill.light_color = Color("#7c8cff")
	fill.light_energy = 0.35
	vp.add_child(fill)
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("#141a3a")
	sky_mat.sky_horizon_color = Color("#e98a6a")
	sky_mat.sky_curve = 0.18
	sky_mat.ground_horizon_color = Color("#e98a6a")
	sky_mat.ground_bottom_color = Color("#2a2f45")
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#5a64a8")
	env.ambient_light_energy = 0.5
	env.fog_enabled = true
	env.fog_light_color = Color("#6a6aa0")
	env.fog_density = 0.012
	env.fog_sky_affect = 0.0
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	var img: Image = await _shoot(vp)
	img.convert(Image.FORMAT_RGB8)
	img.save_jpg(_out.path_join("city.jpg"), 0.9)


func _place(vp: Node, model: String, at: Vector3, s: float) -> void:
	var b: Node3D = load("res://models/city/%s.glb" % model).instantiate()
	vp.add_child(b)
	b.position = at
	b.scale = Vector3.ONE * s


func _aabb(n: Node) -> AABB:
	var out := AABB()
	var first := true
	for m: MeshInstance3D in n.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = m.global_transform * m.get_aabb()
		out = b if first else out.merge(b)
		first = false
	return out
