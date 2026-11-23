extends Node
## 화면 전환과 지금 런(계절·계절 바람). 규칙 엔진(1단계)이 붙기 전 뼈대.

signal screen_changed(screen: StringName, scene: PackedScene)
signal season_changed(season: int)
signal turn_requested(dir: int)
signal winds_changed(winds: int)
## 새 한 해: 숲을 처음 모습으로 되돌린다
signal run_started

const SCREENS := {
	&"title": preload("res://scenes/screens/title.tscn"),
	&"season": preload("res://scenes/screens/season.tscn"),
	&"cabin": preload("res://scenes/screens/cabin.tscn"),
	&"run_end": preload("res://scenes/screens/run_end.tscn"),
}
const SEASON_KEYS: Array[String] = ["SEASON_SPRING", "SEASON_SUMMER", "SEASON_AUTUMN", "SEASON_WINTER"]
## 계절 목표 점수(기획서 2.2 초기값)
const GOALS: Array[int] = [40, 110, 220, 380]
const WINDS_PER_SEASON := 3

var season := 0
var winds := 0
var screen: StringName = &""


func start_run() -> void:
	run_started.emit()
	_set_season(0)
	goto(&"season")


func goto(to: StringName) -> void:
	screen = to
	screen_changed.emit(to, SCREENS[to])


## 계절 바람 1장. 3장째면 계절이 끝나 오두막(겨울이면 런 끝)으로 간다.
func blow_wind() -> void:
	winds += 1
	winds_changed.emit(winds)
	if winds >= WINDS_PER_SEASON:
		goto(&"run_end" if season == SEASON_KEYS.size() - 1 else &"cabin")


func next_season() -> void:
	_set_season(season + 1)
	goto(&"season")


func season_name(i: int = season) -> String:
	return tr(SEASON_KEYS[i])


func _set_season(i: int) -> void:
	season = i
	winds = 0
	season_changed.emit(season)
