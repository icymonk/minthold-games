extends Control

@onready var _screen_root: Control = $ScreenRoot


func _ready() -> void:
	theme = Style.make_theme()
	add_child(Backdrop.new())
	move_child(get_child(-1), 1)
	Game.screen_changed.connect(_show)
	Game.goto(&"title")


func _show(scene: PackedScene) -> void:
	for child in _screen_root.get_children():
		child.queue_free()
	_screen_root.add_child(scene.instantiate())
