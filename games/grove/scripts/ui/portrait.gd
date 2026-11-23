class_name Portrait
extends SubViewport
## 카드 초상 굽기: 3D 모델을 숲과 같은 해·하늘빛으로 따로 찍어 2D 그림으로 남긴다(종마다 한 번).

const SIZE := 256
static var cache := {}

var _queue: Array[StringName] = []
var _waiting := {}
var _stage: Node3D
var _camera: Camera3D
var _busy := false


func _init() -> void:
	size = Vector2i(SIZE, SIZE)
	own_world_3d = true
	transparent_bg = true
	msaa_3d = Viewport.MSAA_4X
	render_target_update_mode = SubViewport.UPDATE_DISABLED


func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#FFE4C2")
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 6.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color("#FFD29A")
	sun.light_energy = 1.7
	sun.rotation_degrees = Vector3(-34.0, -20.0, 0.0)
	add_child(sun)
	_camera = Camera3D.new()
	_camera.fov = 25.0
	add_child(_camera)
	_stage = Node3D.new()
	add_child(_stage)


## kind의 초상을 done(texture)로 돌려준다. 이미 구웠으면 바로.
func request(kind: StringName, done: Callable) -> void:
	if cache.has(kind):
		done.call(cache[kind])
		return
	if not _waiting.has(kind):
		_waiting[kind] = []
		_queue.append(kind)
	_waiting[kind].append(done)
	if not _busy:
		_next()


func _next() -> void:
	if _queue.is_empty():
		_busy = false
		return
	_busy = true
	var kind: StringName = _queue.pop_front()
	for c in _stage.get_children():
		c.free()
	var h := 0.6
	if ForestTree.SPECIES.has(kind):
		var t := ForestTree.make(kind)
		_stage.add_child(t)
		h = t.socket(&"Top").position.y * 1.05
	else:
		var d := Dweller.make(kind)
		d.rotation.y = 0.5
		_stage.add_child(d)
		h = Dweller.KINDS[kind].height
	var aim := Vector3(0, h * 0.5, 0)
	var dist := h / tan(deg_to_rad(_camera.fov * 0.5)) * 0.62
	var dir := Vector3(0, sin(deg_to_rad(18.0)), cos(deg_to_rad(18.0)))
	_camera.look_at_from_position(aim + dir * dist, aim)
	render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_texture().get_image()
	var tex: Texture2D = ImageTexture.create_from_image(img) if img and not img.is_empty() else null
	if tex:
		cache[kind] = tex
	for done: Callable in _waiting.get(kind, []):
		if done.is_valid():
			done.call(tex)
	_waiting.erase(kind)
	_next()
