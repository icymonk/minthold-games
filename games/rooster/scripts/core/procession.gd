class_name Procession
extends RefCounted
## 밤마다 오는 백귀의 행렬. lanes[y]는 보따리 y줄로 들어오는 적 목록(앞이 먼저 싸운다).

const HP_GROWTH := 0.45
const ATK_GROWTH_EVERY := 2

var rule: StringName = &"none"
var time_limit := 60.0
var hp_scale := 1.0
var atk_bonus := 0
var lanes: Array = []


static func for_night(night: int, lane_count: int, rng: RandomNumberGenerator) -> Procession:
	var pr := Procession.new()
	pr.hp_scale = 1.0 + HP_GROWTH * (night - 1)
	pr.atk_bonus = (night - 1) / ATK_GROWTH_EVERY
	for i in lane_count:
		pr.lanes.append([])
	var pool: Array[StringName]
	var count: int
	match night:
		1:
			pool = [&"field_ghost"]
			count = 3
		2:
			pool = [&"field_ghost", &"ghost_fire"]
			count = 5
		3:
			pr.rule = &"reaper"
			pr.lanes[1].append(&"reaper")
			pool = [&"field_ghost", &"ghost_fire"]
			count = 4
		4, 5:
			pr.rule = &"plague"
			pool = [&"field_ghost", &"ghost_fire", &"shade", &"shade"]
			count = 5 + night
		6:
			pr.rule = &"hungry"
			pool = [&"ghost_fire", &"shade", &"shade", &"ox_brute"]
			count = 10
		_:
			pr.rule = &"leader"
			pr.time_limit = 45.0
			pr.lanes[lane_count / 2].append(&"leader")
			pool = [&"shade", &"ox_brute", &"ghost_fire"]
			count = 8
	for i in count:
		var shortest := 0
		for l in lane_count:
			if pr.lanes[l].size() < pr.lanes[shortest].size():
				shortest = l
		var lane := shortest if rng.randf() < 0.6 else rng.randi_range(0, lane_count - 1)
		pr.lanes[lane].append(pool[rng.randi_range(0, pool.size() - 1)])
	return pr
