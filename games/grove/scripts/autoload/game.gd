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
## 이어 하기: 남긴 숲을 다시 세운다
signal run_restored(forest: Forest)

const SCREENS := {
	&"title": preload("res://scenes/screens/title.tscn"),
	&"season": preload("res://scenes/screens/season.tscn"),
	&"cabin": preload("res://scenes/screens/cabin.tscn"),
	&"run_end": preload("res://scenes/screens/run_end.tscn"),
	&"codex": preload("res://scenes/screens/codex.tscn"),
	&"setup": preload("res://scenes/screens/setup.tscn"),
	&"album": preload("res://scenes/screens/album.tscn"),
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
## 방금 끝난 계절에 도감에 새로 열린 종
var fresh: Array[StringName] = []
var records := Records.load_file()
## 테스트는 다른 곳에 남긴다
var save_path := Save.PATH
var records_path := Records.PATH
var album_dir := "user://album"
## 새 런에서 고른 숲지기·숲 등급(준비 화면)
var keeper: StringName = &"grandma"
var grade := 0
## 런이 막 끝나서 앨범 사진을 찍을 차례
var photo_pending := false


func start_run(seed_value := -1) -> void:
	run = Run.new(seed_value if seed_value >= 0 else randi(), keeper, grade)
	Save.clear(save_path)
	run.begin()
	run_started.emit()
	_set_season(0)
	goto(&"season")


## 계절 끝: 점수를 세고(목표 비교·도토리·보상) 기록을 돌려준다. 화면은 연출 뒤 after_season()을 부른다.
func finish_season() -> ScoreLog:
	var i := run.season_index
	last_score = run.finish()
	fresh = records.note_season(i, last_score, run.forest)
	records.save(records_path)
	return last_score


## 오두막에서 이어 하기
func continue_run() -> bool:
	var saved := Save.read(save_path)
	if not saved:
		return false
	run = saved
	last_score = run.scores.back() if not run.scores.is_empty() else null
	fresh = []
	run_restored.emit(run.forest)
	_set_season(run.season_index - 1)
	goto(&"cabin")
	return true


func can_continue() -> bool:
	return Save.exists(save_path)


## 오두막: 보상 하나 고르기 / 가게에서 사기. 땅이 넓어지면 숲 화면에 알린다.
func take_reward(i: int, ids: Array[int] = []) -> bool:
	var ok := run.take(i, ids)
	plots_changed.emit(run.forest.plots)
	if ok:
		Save.write(run, save_path)
	return ok


func buy(item: Dictionary, ids: Array[int] = []) -> bool:
	var ok := run.buy(item, ids)
	if ok and item.t == &"land":
		plots_changed.emit(run.forest.plots)
	if ok:
		Save.write(run, save_path)
	return ok


func after_season() -> void:
	if run.lost or run.done:
		records.note_run(run)
		records.save(records_path)
		photo_pending = true
		Save.clear(save_path)
		goto(&"run_end")
	else:
		Save.write(run, save_path)
		goto(&"cabin")


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


## 런 끝 숲 사진을 앨범에 남긴다(4-1)
func save_photo(img: Image) -> void:
	photo_pending = false
	if run == null or img == null or img.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(album_dir)
	var file := "%s/%d_%d.png" % [album_dir, int(Time.get_unix_time_from_system()), records.album.size()]
	if img.save_png(file) != OK:
		return
	var year := 0
	for s in run.scores:
		year += s.total
	records.add_photo({file = file, year = year, keeper = run.keeper, grade = run.grade, finished = run.done and not run.lost, date = Time.get_date_string_from_system()})
	records.save(records_path)
