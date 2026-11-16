extends Node
## 화면 전환과 현재 판 설정을 관리한다.

signal screen_changed(scene: PackedScene)

enum Role { CHIEF, STAFF }

const SCREENS := {
	&"title": preload("res://scenes/screens/title.tscn"),
	&"table": preload("res://scenes/screens/table.tscn"),
}

var role := Role.CHIEF
var run_seed := 0
var rng: RngStreams


func start_match(seed_value: int = -1) -> void:
	run_seed = seed_value if seed_value >= 0 else randi()
	rng = RngStreams.new(run_seed)
	goto(&"table")


func toggle_role() -> void:
	role = Role.STAFF if role == Role.CHIEF else Role.CHIEF


func goto(screen: StringName) -> void:
	screen_changed.emit(SCREENS[screen])
