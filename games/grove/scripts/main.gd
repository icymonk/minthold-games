extends Control
## 숲 섬(3D)은 계속 떠 있고, 그 위에 화면(2D UI)만 바꿔 끼운다.

@onready var _world: ForestView = $World
@onready var _screen_root: Control = $ScreenRoot

## F3: 프레임·그리기 호출 수 표시(웹 성능 확인용)
var _stats: Label


func _ready() -> void:
	theme = Style.make_theme()
	Game.screen_changed.connect(_show)
	Game.season_changed.connect(_world.set_season)
	Game.turn_requested.connect(_world.turn)
	Game.run_started.connect(_world.plant_layout.bind(ForestView.EMPTY_FOREST))
	Game.goto(&"title")


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
		_stats.text = "FPS %d · draw %d · tris %dk" % [
			Engine.get_frames_per_second(),
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME) / 1000,
		]
