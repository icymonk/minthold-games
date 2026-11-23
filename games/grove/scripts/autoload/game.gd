extends Node
## 화면 전환과 지금 런(Run). 규칙은 scripts/rules가 정하고, 여기서는 화면 순서만 정한다.

signal screen_changed(screen: StringName, scene: PackedScene)
signal season_changed(season: int)
signal turn_requested(dir: int)
signal winds_changed(winds: int)
## 새 한 해: 숲을 처음 모습으로 되돌린다
signal run_started
## 땅 자리 수가 바뀌었다(오두막 땅 넓히기)
signal plots_changed(plots: int)

const SCREENS := {
	&"title": preload("res://scenes/screens/title.tscn"),
	&"season": preload("res://scenes/screens/season.tscn"),
	&"cabin": preload("res://scenes/screens/cabin.tscn"),
	&"run_end": preload("res://scenes/screens/run_end.tscn"),
}
const SEASON_KEYS: Array[String] = ["SEASON_SPRING", "SEASON_SUMMER", "SEASON_AUTUMN", "SEASON_WINTER"]
## 계절 목표 점수(기획서 2.2 초기값)
const GOALS: Array[int] = [40, 110, 220, 380]
const WINDS_PER_SEASON := Season.WINDS

var season := 0
var winds := 0
var screen: StringName = &""
var run: Run
## 방금 끝난 계절 점수
var last_score: ScoreLog


func start_run(seed_value := -1) -> void:
	run = Run.new(seed_value if seed_value >= 0 else randi())
	run.begin()
	run_started.emit()
	_set_season(0)
	goto(&"season")


## 계절 끝: 점수를 세고(목표 비교·도토리·보상) 기록을 돌려준다. 화면은 연출 뒤 after_season()을 부른다.
func finish_season() -> ScoreLog:
	last_score = run.finish()
	return last_score


## 오두막: 보상 하나 고르기 / 가게에서 사기. 땅이 넓어지면 숲 화면에 알린다.
func take_reward(i: int, ids: Array[int] = []) -> bool:
	var ok := run.take(i, ids)
	plots_changed.emit(run.forest.plots)
	return ok


func buy(item: Dictionary, ids: Array[int] = []) -> bool:
	var ok := run.buy(item, ids)
	if ok and item.t == &"land":
		plots_changed.emit(run.forest.plots)
	return ok


func after_season() -> void:
	goto(&"run_end" if run.lost or run.done else &"cabin")


func goto(to: StringName) -> void:
	screen = to
	screen_changed.emit(to, SCREENS[to])


## 계절 덱에서 바람이 떴다(화면이 SeasonLog를 보고 부른다)
func wind_seen(n: int) -> void:
	winds = n
	winds_changed.emit(winds)


func next_season() -> void:
	run.begin()
	_set_season(run.season_index)
	goto(&"season")


func season_name(i: int = season) -> String:
	return tr(SEASON_KEYS[i])


func _set_season(i: int) -> void:
	season = i
	winds = 0
	Sfx.ambience(i)
	season_changed.emit(season)
