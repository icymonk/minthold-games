extends Node
## 화면 전환과 현재 판(근무 5일)을 관리한다.

signal screen_changed(scene: PackedScene)

const SCREENS := {
	&"title": preload("res://scenes/screens/title.tscn"),
	&"loading": preload("res://scenes/screens/loading.tscn"),
	&"shift": preload("res://scenes/screens/shift.tscn"),
}

var run_seed := 0
var rng: RngStreams
var shift: ShiftState


func start_run(seed_value: int = -1) -> void:
	run_seed = seed_value if seed_value >= 0 else randi()
	rng = RngStreams.new(run_seed)
	shift = ShiftState.practice(rng.cargo)
	goto(&"loading")


func goto(screen: StringName) -> void:
	screen_changed.emit(SCREENS[screen])
