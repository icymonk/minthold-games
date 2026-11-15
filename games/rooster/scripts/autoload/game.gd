extends Node
## 화면 전환과 현재 원정을 관리한다.

signal screen_changed(scene: PackedScene)

const SCREENS := {
	&"title": preload("res://scenes/screens/title.tscn"),
	&"night": preload("res://scenes/screens/night.tscn"),
	&"result": preload("res://scenes/screens/result.tscn"),
}

var run: RunState


func start_run(run_seed: int = -1) -> void:
	if run_seed < 0:
		run_seed = randi()
	run = RunState.new(run_seed)
	goto(&"night")


func goto(screen: StringName) -> void:
	screen_changed.emit(SCREENS[screen])
