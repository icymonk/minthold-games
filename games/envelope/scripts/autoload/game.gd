extends Node
## 화면 전환과 현재 판 설정을 관리한다.

signal screen_changed(scene: PackedScene)

const SCREENS := {
	&"title": preload("res://scenes/screens/title.tscn"),
	&"table": preload("res://scenes/screens/table.tscn"),
	&"records": preload("res://scenes/screens/records.tscn"),
}
const MIN_PLAYERS := 3
const MAX_PLAYERS := 6

const SETTINGS := "user://settings.cfg"
const RECORDS := "user://records.cfg"

var players := 5
var settings_path := SETTINGS
var seen_intro := false
var records_path := RECORDS
var records := {}
## 진행 중인 리그. 한 판씩 할 때는 null.
var league: League
var run_seed := 0
var rng: RngStreams


func _ready() -> void:
	load_settings()
	load_records()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	seen_intro = cfg.load(settings_path) == OK and cfg.get_value("play", "seen_intro", false)


func mark_intro_seen() -> void:
	seen_intro = true
	var cfg := ConfigFile.new()
	cfg.load(settings_path)
	cfg.set_value("play", "seen_intro", true)
	cfg.save(settings_path)


func load_records() -> void:
	var cfg := ConfigFile.new()
	cfg.load(records_path)
	records = {
		plays = cfg.get_value("records", "plays", {}),
		wins = cfg.get_value("records", "wins", {}),
		best = cfg.get_value("records", "best", 0),
	}


## 끝난 판을 기록하고, 리그 중이면 이번 판 평판 점수를 돌려준다.
func record(r: Dictionary, seat: int) -> int:
	var role: int = r.roles[seat]
	if role >= 0:
		var key := String(Cards.DEFS[role].key)
		records.plays[key] = records.plays.get(key, 0) + 1
		if r.winners.has(seat):
			records.wins[key] = records.wins.get(key, 0) + 1
	var p := 0
	if league != null:
		p = league.add(r, seat)
		if league.done():
			records.best = maxi(records.best, league.total())
	var cfg := ConfigFile.new()
	cfg.set_value("records", "plays", records.plays)
	cfg.set_value("records", "wins", records.wins)
	cfg.set_value("records", "best", records.best)
	cfg.save(records_path)
	return p


func start_league() -> void:
	league = League.new()
	start_match()


func start_match(seed_value: int = -1) -> void:
	run_seed = seed_value if seed_value >= 0 else randi()
	rng = RngStreams.new(run_seed)
	goto(&"table")


func set_players(n: int) -> void:
	players = clampi(n, MIN_PLAYERS, MAX_PLAYERS)


func goto(screen: StringName) -> void:
	screen_changed.emit(SCREENS[screen])
