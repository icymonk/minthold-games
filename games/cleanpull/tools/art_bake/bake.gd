extends SceneTree
## Kenney 3D 모델(CC0)을 옆에서 정사영으로 찍어 2D 그림으로 굽는다.
## 사용: godot --rendering-driver opengl3 --path . -s bake.gd -- <출력 폴더>

const PX_PER_M := 900.0
const DISHES := {
	"plate": "food/plate-dinner",
	"soup_bowl": "food/bowl-soup",
	"mug": "food/mug",
	"wine_glass": "food/glass-wine",
	"wine_bottle": "food/wine-red",
	"cake": "food/cake",
	"jelly": "food/pudding",
	"vase": "furniture/pottedPlant",
}

var _out: String


func _init() -> void:
	_out = OS.get_cmdline_user_args()[0]
	await process_frame
	for name: String in DISHES:
		await _bake_side(DISHES[name], name, 0.0)
	await _bake_side("furniture/chair", "chair", 90.0)
	await _bake_room()
	quit()


func _load(path: String) -> Node3D:
	var file := "res://models/%s.glb" % path
	if not ResourceLoader.exists(file):
		file = "res://models/%s.gltf" % path
	return load(file).instantiate()


func _studio(size: Vector2i) -> SubViewport:
	var vp := SubViewport.new()
	vp.size = size
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-35, -25, 0)
	key.light_color = Color("#ffe2b8")
	key.light_energy = 1.15
	vp.add_child(key)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.78, 0.75)
	env.ambient_light_energy = 0.75
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	return vp


func _shoot(vp: SubViewport) -> Image:
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	vp.queue_free()
	return img


## 살짝 위(10도)에서 본 옆모습. 그릇 윗면이 조금 보이게 한다.
func _bake_side(model: String, name: String, yaw: float) -> void:
	var vp := _studio(Vector2i(1600, 1600))
	var n := _load(model)
	n.rotation_degrees.y = yaw
	vp.add_child(n)
	if name == "wine_glass":
		_glassify(n)
	await process_frame
	var box := _aabb(n)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = maxf(box.size.x, box.size.y) * 1.3
	cam.rotation_degrees.x = -10
	cam.position = box.get_center() + Vector3(0, sin(deg_to_rad(10)), cos(deg_to_rad(10))) * 20
	vp.add_child(cam)
	var img: Image = await _shoot(vp)
	img = img.get_region(img.get_used_rect())
	if img.get_width() > 512:
		img.resize(512, int(512.0 * img.get_height() / img.get_width()), Image.INTERPOLATE_LANCZOS)
	img.save_png(_out.path_join("%s.png" % name))


## 유리 재질이 검게 나와서 밝은 반투명 유리로 바꾼다.
func _glassify(n: Node) -> void:
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.86, 0.93, 1.0, 0.55)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.1
	glass.rim_enabled = true
	glass.rim = 0.6
	for m: MeshInstance3D in n.find_children("*", "MeshInstance3D", true, false):
		m.material_override = glass


## 저녁 식당 배경: 벽, 창문, 스탠드, 화분, 따뜻한 조명.
func _bake_room() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(1920, 1080)
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var probe := _load("furniture/wall")
	vp.add_child(probe)
	await process_frame
	var h := _aabb(probe).size.y
	probe.queue_free()
	var x := -6
	for kind: String in ["wall", "wall", "wallWindow", "wall", "wallWindow", "wall", "wallWindow", "wall", "wallWindow", "wall", "wall", "wall"]:
		var w := _load("furniture/" + kind)
		w.position = Vector3(x, 0, -1.2)
		vp.add_child(w)
		x += 1
	for i in range(-5, 5):
		for j in range(-2, 3):
			var f := _load("furniture/floorFull")
			f.position = Vector3(i, 0, j - 0.2)
			vp.add_child(f)
	for spec: Array in [["lampSquareFloor", -2.8], ["pottedPlant", -2.2], ["bookcaseOpenLow", 1.4], ["lampRoundFloor", 2.8], ["plantSmall2", 2.2]]:
		var p := _load("furniture/" + spec[0])
		p.position = Vector3(spec[1], 0, -1.0)
		vp.add_child(p)
	var cam := Camera3D.new()
	cam.fov = 40
	cam.position = Vector3(0, h * 0.42, -1.2 + h * 2.6)
	cam.rotation_degrees = Vector3(-6, 0, 0)
	vp.add_child(cam)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-30, 20, 0)
	key.light_color = Color("#ffb070")
	key.light_energy = 0.35
	vp.add_child(key)
	for at: Vector3 in [Vector3(-2.8, h * 0.6, -0.8), Vector3(2.8, h * 0.6, -0.8), Vector3(0, h, 0.5)]:
		var lamp := OmniLight3D.new()
		lamp.position = at
		lamp.light_color = Color("#ffbf73")
		lamp.light_energy = 0.9
		lamp.omni_range = h * 2.0
		vp.add_child(lamp)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#1a1020")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#6a4a5a")
	env.ambient_light_energy = 0.35
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	var img: Image = await _shoot(vp)
	img.convert(Image.FORMAT_RGB8)
	img.save_jpg(_out.path_join("room.jpg"), 0.9)


func _aabb(n: Node) -> AABB:
	var out := AABB()
	var first := true
	for m: MeshInstance3D in n.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = m.global_transform * m.get_aabb()
		out = b if first else out.merge(b)
		first = false
	return out
