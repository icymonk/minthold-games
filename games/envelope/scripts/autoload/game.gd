extends Node
## 화면 전환과 현재 판 설정을 관리한다.

signal screen_changed(scene: PackedScene)

const SCREENS := {
	&"title": preload("res://scenes/screens/title.tscn"),
	&"table": preload("res://scenes/screens/table.tscn"),
}
const MIN_PLAYERS := 3
const MAX_PLAYERS := 6

const SETTINGS := "user://settings.cfg"

var players := 5
var settings_path := SETTINGS
var seen_intro := false
var run_seed := 0
var rng: RngStreams


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	seen_intro = cfg.load(settings_path) == OK and cfg.get_value("play", "seen_intro", false)


func mark_intro_seen() -> void:
	seen_intro = true
	var cfg := ConfigFile.new()
	cfg.load(settings_path)
	cfg.set_value("play", "seen_intro", true)
	cfg.save(settings_path)


func start_match(seed_value: int = -1) -> void:
	run_seed = seed_value if seed_value >= 0 else randi()
	rng = RngStreams.new(run_seed)
	goto(&"table")


func set_players(n: int) -> void:
	players = clampi(n, MIN_PLAYERS, MAX_PLAYERS)


func goto(screen: StringName) -> void:
	screen_changed.emit(SCREENS[screen])
