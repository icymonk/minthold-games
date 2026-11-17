extends Node
## 화면 전환과 지금 런의 seed를 관리한다.

signal screen_changed(scene: PackedScene)

const SCREENS := {
	&"title": preload("res://scenes/screens/title.tscn"),
	&"map": preload("res://scenes/screens/map.tscn"),
	&"counter": preload("res://scenes/screens/counter.tscn"),
	&"shop": preload("res://scenes/screens/shop.tscn"),
	&"run_end": preload("res://scenes/screens/run_end.tscn"),
}

var run_seed := 0
var rng: RngStreams
var run: Run


func start_run(seed_value: int) -> void:
	run_seed = seed_value
	rng = RngStreams.new(run_seed)
	run = Run.new(run_seed)
	goto(&"map")


func goto(screen: StringName) -> void:
	screen_changed.emit(SCREENS[screen])
