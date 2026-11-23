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
	return r


func save(path := PATH) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("runs", "count", runs)
	cfg.set_value("runs", "finished", finished)
	cfg.set_value("runs", "best_year", best_year)
	cfg.set_value("runs", "best_season", best_season)
	cfg.set_value("codex", "seen", seen)
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
	var year := 0
	for s in run.scores:
		year += s.total
	best_year = maxi(best_year, year)


func found() -> int:
	return all_kinds().filter(func(k: StringName) -> bool: return seen.has(k)).size()
