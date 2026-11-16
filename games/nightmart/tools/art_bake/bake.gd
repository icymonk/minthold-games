extends SceneTree
## Kenney Food Kit 3D 모델(CC0)을 같은 각도·조명으로 찍어 상품 그림으로 굽는다.
## 사용: godot --rendering-driver opengl3 --path . -s bake.gd -- <출력 폴더>

const SIZE := 384
## 코너별 상품 13개. 순서는 가격(1~13) 순서다. 게임 쪽 Art.PRODUCTS와 같아야 한다.
const PRODUCTS := {
	"meal": ["rice-ball", "sandwich", "sub", "hot-dog", "corn-dog", "burger", "burger-cheese", "dim-sum", "maki-salmon", "chinese", "bowl-broth", "styrofoam-dinner", "pizza"],
	"snack": ["lollypop", "candy-bar", "chocolate", "cookie", "cookie-chocolate", "popsicle", "donut", "donut-sprinkles", "croissant", "muffin", "cupcake", "ice-cream-cup", "ice-cream"],
	"drink": ["can", "soda-can", "carton-small", "carton", "soda-bottle", "soda", "cup-tea", "cup-coffee", "frappe", "glass", "cocktail", "wine-white", "wine-red"],
	"goods": ["chopstick", "utensil-spoon", "bag-flat", "bag", "shaker-salt", "soy", "bottle-ketchup", "honey", "peanut-butter", "bottle-oil", "pepper-mill", "pot", "frying-pan"],
}

var _out: String


func _init() -> void:
	_out = OS.get_cmdline_user_args()[0]
	await process_frame
	for corner: String in PRODUCTS:
		DirAccess.make_dir_recursive_absolute(_out.path_join(corner))
		for model: String in PRODUCTS[corner]:
			await _bake(model, _out.path_join("%s/%s.png" % [corner, model]))
	quit()


## 모든 상품을 같은 3/4 각도(위 28도, 옆 30도)에서 정사영으로 찍는다.
func _bake(model: String, path: String) -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(1024, 1024)
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-50, -35, 0)
	key.light_color = Color("#f4fbff")
	key.light_energy = 1.1
	vp.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-20, 150, 0)
	rim.light_color = Color("#7fe8c0")
	rim.light_energy = 0.45
	vp.add_child(rim)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.82, 0.86, 0.95)
	env.ambient_light_energy = 0.7
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	var n: Node3D = load("res://models/food/%s.glb" % model).instantiate()
	n.rotation_degrees.y = 30
	vp.add_child(n)
	await process_frame
	var box := _aabb(n)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = box.get_longest_axis_size() * 1.5
	cam.rotation_degrees.x = -28
	cam.position = box.get_center() + Vector3(0, sin(deg_to_rad(28)), cos(deg_to_rad(28))) * 20
	vp.add_child(cam)
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	vp.queue_free()
	img = img.get_region(img.get_used_rect())
	var s := float(SIZE) / maxf(img.get_width(), img.get_height())
	img.resize(int(img.get_width() * s), int(img.get_height() * s), Image.INTERPOLATE_LANCZOS)
	img.save_png(path)


func _aabb(n: Node) -> AABB:
	var out := AABB()
	var first := true
	for m: MeshInstance3D in n.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = m.global_transform * m.get_aabb()
		out = b if first else out.merge(b)
		first = false
	return out
