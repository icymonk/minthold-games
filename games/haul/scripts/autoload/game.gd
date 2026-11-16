extends Node
## 화면 전환과 현재 판(근무 5일)을 관리한다.

signal screen_changed(scene: PackedScene)

const SCREENS := {
	&"title": preload("res://scenes/screens/title.tscn"),
	&"loading": preload("res://scenes/screens/loading.tscn"),
	&"shift": preload("res://scenes/screens/shift.tscn"),
}

const SETTINGS_PATH := "user://settings.cfg"
const SFX := {
	&"thud": preload("res://assets/sfx/thud.ogg"),
	&"pick": preload("res://assets/sfx/pick.ogg"),
	&"slide": preload("res://assets/sfx/slide.ogg"),
	&"error": preload("res://assets/sfx/error.ogg"),
	&"rotate": preload("res://assets/sfx/rotate.ogg"),
	&"chime": preload("res://assets/sfx/chime.ogg"),
	&"engine": preload("res://assets/sfx/engine.wav"),
}

var run_seed := 0
var rng: RngStreams
var shift: ShiftState
## 이번 상차가 첫 근무 연습인지.
var tutorial := false
var tutorial_done := false
var _players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		tutorial_done = cfg.get_value("progress", "tutorial_done", false)
	for i in 6:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)


func start_run(seed_value: int = -1) -> void:
	run_seed = seed_value if seed_value >= 0 else randi()
	rng = RngStreams.new(run_seed)
	tutorial = false
	shift = ShiftState.practice(rng.cargo)
	goto(&"loading")


func start_tutorial() -> void:
	run_seed = 0
	rng = RngStreams.new(run_seed)
	tutorial = true
	shift = LoadingGuide.tutorial_shift()
	goto(&"loading")


func finish_tutorial() -> void:
	tutorial_done = true
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("progress", "tutorial_done", true)
	cfg.save(SETTINGS_PATH)


func sfx(name: StringName, pitch := 1.0) -> void:
	for p in _players:
		if not p.playing:
			p.stream = SFX[name]
			p.pitch_scale = pitch
			p.play()
			return


func goto(screen: StringName) -> void:
	screen_changed.emit(SCREENS[screen])
