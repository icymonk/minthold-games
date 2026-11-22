extends Node
## 효과음(Kenney CC0). 끄기 설정은 user://settings.cfg에 남는다.

const SETTINGS := "user://settings.cfg"
const SOUNDS := {
	&"click": preload("res://assets/sfx/click.ogg"),
	&"place": preload("res://assets/sfx/place.ogg"),
	&"chime": preload("res://assets/sfx/chime.ogg"),
}

var muted := false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS) == OK:
		muted = cfg.get_value("audio", "muted", false)


func play(key: StringName, volume := 1.0, pitch := 1.0) -> void:
	if muted:
		return
	var player := AudioStreamPlayer.new()
	player.stream = SOUNDS[key]
	player.volume_db = linear_to_db(volume)
	player.pitch_scale = pitch * _rng.randf_range(0.95, 1.05)
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()


func set_muted(on: bool) -> void:
	muted = on
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS)
	cfg.set_value("audio", "muted", on)
	cfg.save(SETTINGS)
