extends Control
## 숲 섬(3D)은 계속 떠 있고, 그 위에 화면(2D UI)만 바꿔 끼운다.

@onready var _world: ForestView = $World
@onready var _screen_root: Control = $ScreenRoot


func _ready() -> void:
	theme = Style.make_theme()
	Game.screen_changed.connect(_show)
	Game.season_changed.connect(_world.set_season)
	Game.turn_requested.connect(_world.turn)
	Game.goto(&"title")


func _show(screen: StringName, scene: PackedScene) -> void:
	for child in _screen_root.get_children():
		child.queue_free()
	_world.set_mode(ForestView.Mode.ORBIT if screen in [&"title", &"run_end"] else ForestView.Mode.FIXED)
	_screen_root.add_child(scene.instantiate())
