class_name Synergy
extends RefCounted
## 보따리 안의 계열 시너지와 맞닿음 효과를 계산한다. 전투와 장터 화면이 같은 결과를 쓴다.

const THRESHOLDS: Array[int] = [2, 4]

## 맞닿은 두 계열 사이의 효과. to 계열 요괴가 from 계열 이웃 하나마다 받는다(최대 2번).
const LINKS := [
	{"id": &"forge", "from": &"fire", "to": &"metal", "atk": 1, "hp": 0},
	{"id": &"steam", "from": &"water", "to": &"fire", "atk": -1, "hp": 0},
	{"id": &"valley", "from": &"water", "to": &"mountain", "atk": 0, "hp": 2},
	{"id": &"solace", "from": &"divine", "to": &"grudge", "atk": 0, "hp": 2},
]
const LINK_MAX := 2


## 계열별 보따리 안 요괴 수.
static func counts(bag: Bag) -> Dictionary:
	var out := {}
	for f in YokaiDb.FAMILIES:
		out[f] = 0
	for p in bag.pieces:
		out[p.family()] += 1
	return out


## 계열별 시너지 단계(0, 1, 2).
static func levels(bag: Bag) -> Dictionary:
	var out := {}
	var c := counts(bag)
	for f in c:
		var lv := 0
		for th in THRESHOLDS:
			if c[f] >= th:
				lv += 1
		out[f] = lv
	return out


## 조각마다 전투 시작 전에 더해지는 공격·체력과 그 이유.
## {piece_id: {"atk": int, "hp": int, "interval": float, "why": Array[StringName]}}
static func bonuses(bag: Bag) -> Dictionary:
	var lv := levels(bag)
	var out := {}
	for p in bag.pieces:
		var b := {"atk": 0, "hp": 0, "interval": 1.0, "why": []}
		var f := p.family()
		match f:
			&"fire":
				if lv[f] >= 1:
					b["atk"] += 1
			&"water":
				if lv[f] >= 1:
					b["hp"] += 3
			&"metal":
				if lv[f] >= 1:
					b["hp"] += 3
				if lv[f] >= 2:
					b["atk"] += 1
			&"mountain":
				if lv[f] >= 1:
					b["atk"] += 1
				if lv[f] >= 2:
					b["interval"] = 0.8
		if lv[f] >= 1:
			b["why"].append(f)
		var neighbors := bag.neighbors(p)
		for link in LINKS:
			if f != link["to"]:
				continue
			var n := 0
			for o in neighbors:
				if o.family() == link["from"]:
					n += 1
			n = mini(n, LINK_MAX)
			if n > 0:
				b["atk"] += link["atk"] * n
				b["hp"] += link["hp"] * n
				b["why"].append(link["id"])
		out[p.id] = b
	return out
