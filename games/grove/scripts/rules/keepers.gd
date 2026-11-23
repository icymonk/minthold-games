class_name Keepers
extends RefCounted
## 숲지기 8명(4-1): 시작 주머니에 더하는 이웃 카드, 처음부터 함께하는 정령(자리 차지 안 함), 시작 도토리.
## 해금 조건은 기록(Records)에서 센다: runs(해 수)·finished(완주)·found(도감).

const ALL := {
	&"grandma": {pairs = [], spirit = &"", acorns = 0, unlock = {}},
	&"bird_doctor": {pairs = [[&"eagle", &"duck", &"v", &"oak"], [&"woodpecker", &"field_mouse", &"v", &"beech"], [&"jay", &"violet", &"v", &"oak"]], spirit = &"old_owl", acorns = 0, unlock = {runs = 1}},
	&"mushroom_grandpa": {pairs = [[&"owl", &"chanterelle", &"v", &"birch"], [&"finch", &"fly_agaric", &"v", &"fir"], [&"bat", &"chanterelle", &"v", &"pine"]], spirit = &"mushroom_sage", acorns = 0, unlock = {found = 12}},
	&"bat_keeper": {pairs = [[&"long_eared_bat", &"fern", &"v", &"fir"], [&"horseshoe_bat", &"mole", &"v", &"pine"], [&"bat", &"fern", &"v", &"linden"]], spirit = &"bat_lantern", acorns = 0, unlock = {finished = 1}},
	&"butterfly_girl": {pairs = [[&"swallowtail", &"violet", &"v", &"maple"], [&"morpho", &"flower", &"v", &"linden"], [&"peacock_butterfly", &"bee", &"v", &"chestnut"], [&"cabbage_white", &"violet", &"v", &"birch"]], spirit = &"moth_queen", acorns = 0, unlock = {found = 20}},
	&"ranger": {pairs = [[&"roe_deer", &"red_deer", &"h", &"oak"], [&"wolf", &"badger", &"h", &"fir"], [&"goat", &"roe_deer", &"h", &"pine"]], spirit = &"stag_king", acorns = 0, unlock = {finished = 2}},
	&"pond_keeper": {pairs = [[&"finch", &"newt", &"v", &"birch"], [&"owl", &"fire_salamander", &"v", &"beech"], [&"otter", &"crested_ibis", &"h", &"linden"]], spirit = &"frog_choir", acorns = 0, unlock = {found = 30}},
	&"acorn_merchant": {pairs = [], spirit = &"acorn_squirrel", acorns = 8, unlock = {finished = 3}},
}

## 숲 등급(4-1): 완주할 때마다 하나 더 열린다. 고른 등급까지의 어려움이 모두 쌓인다.
const GRADES := [
	{target = 1.1}, {clearing = -1}, {hand = -1}, {target = 1.2},
	{acorns = 0.75}, {winter_winds = -1}, {target = 1.35}, {acorns = 0.5},
]
const MAX_GRADE := 8


static func def_of(id: StringName) -> Dictionary:
	return ALL.get(id, ALL[&"grandma"])


static func unlocked(id: StringName, r: Records) -> bool:
	var u: Dictionary = def_of(id).unlock
	return r.runs >= u.get("runs", 0) and r.finished >= u.get("finished", 0) and r.found() >= u.get("found", 0)


## 등급 0~grade까지 쌓인 어려움
static func grade_mods(grade: int) -> Dictionary:
	var m := {target = 1.0, clearing = 0, hand = 0, acorns = 1.0, winter_winds = 0}
	for g in clampi(grade, 0, MAX_GRADE):
		var d: Dictionary = GRADES[g]
		m.target = maxf(m.target, d.get("target", 1.0))
		m.acorns = minf(m.acorns, d.get("acorns", 1.0))
		m.clearing += d.get("clearing", 0)
		m.hand += d.get("hand", 0)
		m.winter_winds += d.get("winter_winds", 0)
	return m
