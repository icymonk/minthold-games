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
## 첫 판 안내: 본 안내 키, 끄기 여부. user://에 저장한다.
var tips_seen := {}
var tips_off := false

const PREFS := "user://desk.cfg"


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PREFS) == OK:
		tips_seen = cfg.get_value("tips", "seen", {})
		tips_off = cfg.get_value("tips", "off", false)


func mark_tip(key: StringName) -> void:
	tips_seen[key] = true
	_save_prefs()


func skip_tips() -> void:
	tips_off = true
	_save_prefs()


func _save_prefs() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("tips", "seen", tips_seen)
	cfg.set_value("tips", "off", tips_off)
	cfg.save(PREFS)


func start_match(seed_value: int = -1) -> void:
	run_seed = seed_value if seed_value >= 0 else randi()
	rng = RngStreams.new(run_seed)
	goto(&"table")


## 화면의 역할을 규칙 엔진의 쪽으로 바꾼다.
func side() -> int:
	return Match.Side.CHIEF if role == Role.CHIEF else Match.Side.STAFF


func toggle_role() -> void:
	role = Role.STAFF if role == Role.CHIEF else Role.CHIEF


func goto(screen: StringName) -> void:
	screen_changed.emit(SCREENS[screen])
