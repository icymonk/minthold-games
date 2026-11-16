extends Node
## 화면 전환과 현재 판 설정을 관리한다.

signal screen_changed(scene: PackedScene)

enum Role { CHIEF, STAFF }

const SCREENS := {
	&"title": preload("res://scenes/screens/title.tscn"),
	&"table": preload("res://scenes/screens/table.tscn"),
}

var role := Role.CHIEF
var level := Bot.Level.NORMAL
## 사건 카드(선택 규칙) 켜기.
var events := false
var run_seed := 0
## 이번 판에 사건 카드를 켤지(한 주의 금요일은 늘 켬).
var match_events := false
## 진행 중인 한 주. 한 판만 둘 때는 null.
var week: Week = null
var stats := Stats.new()
var rng: RngStreams
## 첫 판 안내: 본 안내 키, 끄기 여부. user://에 저장한다.
var tips_seen := {}
var tips_off := false

const PREFS := "user://desk.cfg"
const SFX := {
	&"tick": preload("res://assets/sfx/tick.ogg"),
	&"place": preload("res://assets/sfx/place.ogg"),
	&"draw": preload("res://assets/sfx/draw.ogg"),
	&"flip": preload("res://assets/sfx/flip.ogg"),
	&"step": preload("res://assets/sfx/step.ogg"),
	&"ping": preload("res://assets/sfx/ping.ogg"),
	&"miss": preload("res://assets/sfx/miss.ogg"),
	&"stamp": preload("res://assets/sfx/stamp.ogg"),
}

var muted := false
## 마지막으로 낸 효과음 이름(테스트용, 최근 것부터 몇 개만).
var played: Array[StringName] = []
var _players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PREFS) == OK:
		tips_seen = cfg.get_value("tips", "seen", {})
		tips_off = cfg.get_value("tips", "off", false)
		muted = cfg.get_value("sound", "muted", false)
		events = cfg.get_value("match", "events", false)
		stats = Stats.from_dict(cfg.get_value("record", "stats", {}))
		var w: Dictionary = cfg.get_value("record", "week", {})
		week = null if w.is_empty() else Week.from_dict(w)
		level = clampi(cfg.get_value("match", "level", Bot.Level.NORMAL), Bot.Level.EASY, Bot.Level.HARD) as Bot.Level
	for i in 6:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)


func sfx(name: StringName, delay := 0.0) -> void:
	played.push_front(name)
	played.resize(mini(played.size(), 8))
	if muted:
		return
	if delay > 0.0:
		get_tree().create_timer(delay).timeout.connect(sfx_now.bind(name))
	else:
		sfx_now(name)


func sfx_now(name: StringName) -> void:
	for p in _players:
		if not p.playing:
			p.stream = SFX[name]
			p.pitch_scale = randf_range(0.95, 1.05)
			p.play()
			return


func toggle_mute() -> void:
	muted = not muted
	_save_prefs()


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
	cfg.set_value("sound", "muted", muted)
	cfg.set_value("match", "level", level)
	cfg.set_value("match", "events", events)
	cfg.set_value("record", "stats", stats.to_dict())
	cfg.set_value("record", "week", {} if week == null else week.to_dict())
	cfg.save(PREFS)


## 한 판만 둔다(진행 중인 한 주는 그대로 남는다).
func start_match(seed_value: int = -1) -> void:
	in_week = false
	_play(seed_value if seed_value >= 0 else randi(), events)


## 이번 판이 한 주의 하루인지.
var in_week := false


func start_week(seed_value: int = -1) -> void:
	week = Week.start(seed_value if seed_value >= 0 else randi(), side(), level, events)
	_save_prefs()
	play_day()


## 진행 중인 한 주의 오늘 판을 둔다.
func play_day() -> void:
	if week == null or week.is_done():
		return
	in_week = true
	role = Role.CHIEF if week.side == Match.Side.CHIEF else Role.STAFF
	level = week.level
	_play(week.day_seed(), week.events_on())


func can_continue_week() -> bool:
	return week != null and not week.is_done()


## 판이 끝나면 한 번 부른다. 기록과 한 주 진행을 저장한다.
func finish_match(m: Match) -> void:
	stats.add(m, side())
	if in_week and week != null and not week.is_done():
		week.record(m.winner == side())
		if week.is_done():
			stats.add_week(week)
	_save_prefs()


func _play(s: int, ev: bool) -> void:
	run_seed = s
	match_events = ev
	rng = RngStreams.new(run_seed)
	goto(&"table")


## 화면의 역할을 규칙 엔진의 쪽으로 바꾼다.
func side() -> int:
	return Match.Side.CHIEF if role == Role.CHIEF else Match.Side.STAFF


func cycle_level() -> void:
	level = ((level + 1) % Bot.Level.size()) as Bot.Level
	_save_prefs()


func toggle_events() -> void:
	events = not events
	_save_prefs()


func toggle_role() -> void:
	role = Role.STAFF if role == Role.CHIEF else Role.CHIEF


func goto(screen: StringName) -> void:
	screen_changed.emit(SCREENS[screen])
