extends Node
## 화면 전환과 현재 판(투어 8무대)을 관리한다.

signal screen_changed(scene: PackedScene)

const SCREENS := {
	&"title": preload("res://scenes/screens/title.tscn"),
	&"tour": preload("res://scenes/screens/tour.tscn"),
}

var run_seed := 0
var rng: RngStreams


func start_run(seed_value: int = -1) -> void:
	run_seed = seed_value if seed_value >= 0 else randi()
	rng = RngStreams.new(run_seed)
	goto(&"tour")


func goto(screen: StringName) -> void:
	screen_changed.emit(SCREENS[screen])
