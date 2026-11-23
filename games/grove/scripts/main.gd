extends Control
## 숲 섬(3D)은 계속 떠 있고, 그 위에 화면(2D UI)만 바꿔 끼운다.

@onready var _world: ForestView = $World
@onready var _screen_root: Control = $ScreenRoot

const MAX_3D_LINES := 1080.0
## 이만큼 끌어야 회전으로 본다(그냥 누르기와 구분)
const DRAG_START_PX := 6.0
const IDLE_FPS := 10

## F3: 프레임·그리기 호출 수 표시(웹 성능 확인용)
var _stats: Label


func _ready() -> void:
	theme = Style.make_theme()
	Game.screen_changed.connect(_show)
	Game.season_changed.connect(_world.set_season)
	Game.turn_requested.connect(_world.turn)
	Game.run_started.connect(_world.reset_plots)
	Game.run_started.connect(_world.plant_layout.bind(ForestView.EMPTY_FOREST))
	Game.plots_changed.connect(_world.open_plots)
	Game.run_restored.connect(_world.rebuild)
	Game.goto(&"title")
	get_window().size_changed.connect(_fit_3d)
	_fit_3d()


## 레티나·4K 화면에서 3D를 화면 해상도 그대로 그리면 너무 무겁다: 3D는 최대 1080줄로 그리고 늘린다.
func _fit_3d() -> void:
	var h := float(get_window().size.y)
	get_viewport().scaling_3d_scale = clampf(MAX_3D_LINES / maxf(h, 1.0), 0.5, 1.0)


## 창이 뒤로 가면 거의 멈춘다(노트북 팬·배터리).
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		Engine.max_fps = IDLE_FPS
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		Engine.max_fps = ProjectSettings.get_setting("application/run/max_fps", 60)


func _show(screen: StringName, scene: PackedScene) -> void:
	for child in _screen_root.get_children():
		child.queue_free()
	_world.set_mode(ForestView.Mode.ORBIT if screen in [&"title", &"run_end"] else ForestView.Mode.FIXED)
	_screen_root.add_child(scene.instantiate())


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.keycode == KEY_F3:
		if not _stats:
			_stats = Label.new()
			_stats.position = Vector2(24, 1000)
			add_child(_stats)
		else:
			_stats.visible = not _stats.visible


func _process(_delta: float) -> void:
	if _stats and _stats.visible:
		_stats.text = "FPS %d · 3D %d%% · draw %d · tris %dk" % [
			Engine.get_frames_per_second(),
			int(get_viewport().scaling_3d_scale * 100),
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME) / 1000,
		]


var _press := false
var _orbiting := false
var _press_x := 0.0


## 빈 곳(카드·버튼이 아닌 곳)을 왼쪽 버튼으로 끌면 섬이 돈다.
func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.button_index == MOUSE_BUTTON_LEFT:
		_press = mb.pressed
		_press_x = mb.position.x
		if not mb.pressed and _orbiting:
			_orbiting = false
			_world.end_drag_yaw()
			get_viewport().set_input_as_handled()
	var mm := event as InputEventMouseMotion
	if mm and _press and mm.button_mask & MOUSE_BUTTON_MASK_LEFT:
		if not _orbiting and absf(mm.position.x - _press_x) < DRAG_START_PX:
			return
		_orbiting = true
		_world.drag_yaw(mm.relative.x)
		get_viewport().set_input_as_handled()
