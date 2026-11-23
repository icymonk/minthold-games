class_name Save
extends RefCounted
## 계절 사이 이어 하기(3-3): 오두막에 들어설 때와 오두막에서 고를 때마다 런 전체를 남긴다.
## 계절 한가운데는 남기지 않는다. 이어 하면 오두막에서 다시 시작한다.

const PATH := "user://run.save"
const VERSION := 1


static func to_dict(run: Run) -> Dictionary:
	var scores := []
	for s in run.scores:
		scores.append({lines = s.lines, cave = s.cave, base = s.base, mult = s.mult, total = s.total})
	return {
		v = VERSION, keeper = run.keeper, grade = run.grade, seed = run.rng.seed, state = run.rng.state, bag = run.bag,
		forest = {plots = run.forest.plots, trees = run.forest.trees, cave = run.forest.cave},
		spirits = run.spirits, acorns = run.acorns, events = run.events, season_index = run.season_index,
		scores = scores, offers = run.offers, lost = run.lost, done = run.done, next_id = run._next_id,
	}.duplicate(true)


static func from_dict(d: Dictionary) -> Run:
	if d.get("v", 0) != VERSION:
		return null
	var run := Run.new(d.seed, d.get("keeper", &"grandma"), d.get("grade", 0))
	run.rng.state = d.state
	run.bag.assign(d.bag)
	run.forest.plots = d.forest.plots
	run.forest.trees = d.forest.trees
	run.forest.cave.assign(d.forest.cave)
	run.spirits.assign(d.spirits)
	run.acorns = d.acorns
	run.events.assign(d.events)
	run.season_index = d.season_index
	for s: Dictionary in d.scores:
		var log := ScoreLog.new()
		log.lines.assign(s.lines)
		log.cave = s.cave
		log.base = s.base
		log.mult = s.mult
		log.total = s.total
		run.scores.append(log)
	run.offers.assign(d.offers)
	run.lost = d.lost
	run.done = d.done
	run._next_id = d.next_id
	return run


static func write(run: Run, path := PATH) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(var_to_str(to_dict(run)))


static func read(path := PATH) -> Run:
	if not FileAccess.file_exists(path):
		return null
	var d: Variant = str_to_var(FileAccess.get_file_as_string(path))
	return from_dict(d) if d is Dictionary else null


static func exists(path := PATH) -> bool:
	return FileAccess.file_exists(path)


static func clear(path := PATH) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
