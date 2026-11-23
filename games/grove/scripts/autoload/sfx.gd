extends Node
## 효과음(Kenney CC0). 끄기 설정은 user://settings.cfg에 남는다.

const SETTINGS := "user://settings.cfg"
const SOUNDS := {
	&"click": preload("res://assets/sfx/click.ogg"),
	&"place": preload("res://assets/sfx/place.ogg"),
	&"chime": preload("res://assets/sfx/chime.ogg"),
}

## 계절 숲 소리(3-2, tools/art_bake/ambience.py로 합성). 바뀔 때 앞뒤 계절이 겹쳐 넘어간다.
const AMBIENCE: Array[AudioStream] = [
	preload("res://assets/sfx/amb_spring.ogg"),
	preload("res://assets/sfx/amb_summer.ogg"),
	preload("res://assets/sfx/amb_autumn.ogg"),
	preload("res://assets/sfx/amb_winter.ogg"),
]
const AMBIENCE_DB := -14.0
const AMBIENCE_FADE := 2.5

var muted := false
var ambience_season := -1
var _rng := RandomNumberGenerator.new()
var _amb: AudioStreamPlayer


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


## 계절 숲 소리를 바꾼다. 앞 소리는 서서히 줄고 새 소리가 겹쳐 올라온다.
func ambience(season: int) -> void:
	if season == ambience_season:
		return
	ambience_season = season
	var old := _amb
	if old:
		var out := create_tween()
		out.tween_property(old, ^"volume_db", -60.0, AMBIENCE_FADE)
		out.tween_callback(old.queue_free)
	var stream: AudioStreamOggVorbis = AMBIENCE[season].duplicate()
	stream.loop = true
	_amb = AudioStreamPlayer.new()
	_amb.stream = stream
	_amb.volume_db = -60.0
	_amb.stream_paused = muted
	add_child(_amb)
	_amb.play()
	create_tween().tween_property(_amb, ^"volume_db", AMBIENCE_DB, AMBIENCE_FADE)


func set_muted(on: bool) -> void:
	muted = on
	if _amb:
		_amb.stream_paused = on
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS)
	cfg.set_value("audio", "muted", on)
	cfg.save(SETTINGS)
