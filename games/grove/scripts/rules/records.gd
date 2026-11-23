class_name Records
extends RefCounted
## 기록과 숲 도감(3-3). 숲에 한 번이라도 들인 나무·이웃이 도감에 열린다.

const PATH := "user://records.cfg"

var runs := 0
var finished := 0
## 한 해 네 계절 점수 합의 최고
var best_year := 0
var best_season: Array[int] = [0, 0, 0, 0]
## 종 → 숲에 들인 횟수(계절 끝 숲 기준)
var seen := {}
## 완주한 가장 높은 숲 등급(-1: 아직 없음)
var best_grade := -1
## 내 숲 앨범: [{file, year, keeper, grade, finished, date}]
var album: Array[Dictionary] = []
const ALBUM_MAX := 24


static func all_kinds() -> Array[StringName]:
	var out: Array[StringName] = []
	out.assign(Cards.TREES.keys() + Cards.SPECIES.keys())
	return out


static func load_file(path := PATH) -> Records:
	var r := Records.new()
	var cfg := ConfigFile.new()
	if cfg.load(path) == OK:
		r.runs = cfg.get_value("runs", "count", 0)
		r.finished = cfg.get_value("runs", "finished", 0)
		r.best_year = cfg.get_value("runs", "best_year", 0)
		r.best_season.assign(cfg.get_value("runs", "best_season", [0, 0, 0, 0]))
		r.seen = cfg.get_value("codex", "seen", {})
		r.best_grade = cfg.get_value("runs", "best_grade", -1)
		r.album.assign(cfg.get_value("album", "entries", []))
	return r


func save(path := PATH) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("runs", "count", runs)
	cfg.set_value("runs", "finished", finished)
	cfg.set_value("runs", "best_year", best_year)
	cfg.set_value("runs", "best_season", best_season)
	cfg.set_value("codex", "seen", seen)
	cfg.set_value("runs", "best_grade", best_grade)
	cfg.set_value("album", "entries", album)
	cfg.save(path)


## 계절 끝: 계절 최고 점수와 숲에 있는 종을 남긴다. 새로 열린 종을 돌려준다.
func note_season(i: int, log: ScoreLog, forest: Forest) -> Array[StringName]:
	best_season[i] = maxi(best_season[i], log.total)
	var fresh: Array[StringName] = []
	for plot in forest.trees:
		var t: Dictionary = forest.trees[plot]
		var kinds: Array[StringName] = []
		if t.kind != Forest.SAPLING:
			kinds.append(t.kind)
		for side in t.sides:
			for o: Dictionary in t.sides[side]:
				kinds.append(o.species)
		for k in kinds:
			if not seen.has(k):
				fresh.append(k)
			seen[k] = seen.get(k, 0) + 1
	return fresh


func note_run(run: Run) -> void:
	runs += 1
	if run.done and not run.lost:
		finished += 1
		best_grade = maxi(best_grade, run.grade)
	var year := 0
	for s in run.scores:
		year += s.total
	best_year = maxi(best_year, year)


func found() -> int:
	return all_kinds().filter(func(k: StringName) -> bool: return seen.has(k)).size()


## 고를 수 있는 가장 높은 숲 등급
func open_grade() -> int:
	return mini(best_grade + 1, Keepers.MAX_GRADE)


## 앨범에 한 장 더한다. 가득 차면 가장 오래된 사진을 지운다.
func add_photo(entry: Dictionary) -> void:
	album.append(entry)
	while album.size() > ALBUM_MAX:
		var old: Dictionary = album.pop_front()
		if FileAccess.file_exists(old.file):
			DirAccess.remove_absolute(old.file)
