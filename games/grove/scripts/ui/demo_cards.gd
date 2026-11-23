class_name DemoCards
extends RefCounted
## 0-3 연출 확인용 샘플 카드(규칙·비용·점수 없음). 1-1부터 규칙 엔진의 카드 데이터로 바뀐다.
## 나무 카드: {tree}. 이웃 카드: {halves = [a, b], axis} — axis v는 위/아래, h는 왼/오른 반쪽.

const SIDES := {&"v": [&"Top", &"Bottom"], &"h": [&"Left", &"Right"]}


static func tree(kind: StringName) -> Dictionary:
	return {tree = kind}


static func pair(a: StringName, b: StringName, axis: StringName) -> Dictionary:
	return {halves = [a, b], axis = axis}


static func is_tree(card: Dictionary) -> bool:
	return card.has("tree")


static func side_of(card: Dictionary, half: int) -> StringName:
	return &"" if is_tree(card) else SIDES[card.axis][half]


static func kind_of(card: Dictionary, half: int) -> StringName:
	return card.tree if is_tree(card) else card.halves[half]


## 처음 손패: 나무 2장, 위/아래 2장, 왼/오른 1장 — 여섯 가지 등장을 바로 볼 수 있게 고른다.
static func starting_hand() -> Array[Dictionary]:
	return [
		tree(&"linden"), pair(&"owl", &"mushroom", &"v"), pair(&"fox", &"hare", &"h"),
		pair(&"butterfly", &"axolotl", &"v"), tree(&"chestnut"),
	]


static func deal(rng: RandomNumberGenerator) -> Dictionary:
	if rng.randf() < 0.2:
		var trees := ForestTree.SPECIES.keys()
		return tree(trees[rng.randi() % trees.size()])
	var axis: StringName = &"v" if rng.randf() < 0.55 else &"h"
	var halves: Array[StringName] = []
	for side in SIDES[axis]:
		var fits := Dweller.KINDS.keys().filter(func(k: StringName) -> bool: return side in Dweller.KINDS[k].sides)
		fits = fits.filter(func(k: StringName) -> bool: return not k in halves)
		halves.append(fits[rng.randi() % fits.size()])
	return pair(halves[0], halves[1], axis)
