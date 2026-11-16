extends Node
## 화면 전환과 현재 판 설정을 관리한다.

signal screen_changed(scene: PackedScene)

const SCREENS := {
	&"title": preload("res://scenes/screens/title.tscn"),
	&"table": preload("res://scenes/screens/table.tscn"),
}
const MIN_PLAYERS := 3
const MAX_PLAYERS := 6

var players := 5
var run_seed := 0
var rng: RngStreams


func start_match(seed_value: int = -1) -> void:
	run_seed = seed_value if seed_value >= 0 else randi()
	rng = RngStreams.new(run_seed)
	goto(&"table")


func set_players(n: int) -> void:
	players = clampi(n, MIN_PLAYERS, MAX_PLAYERS)


func goto(screen: StringName) -> void:
	screen_changed.emit(SCREENS[screen])
