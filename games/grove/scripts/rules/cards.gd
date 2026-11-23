class_name Cards
extends RefCounted
## 카드 데이터(규칙 1-1). 나무 카드 {id, tree, sym}, 이웃 카드 {id, halves = [a, b], axis, sym}.
## axis v는 위/아래 반쪽, h는 왼/오른 반쪽. sym은 카드 귀퉁이의 나무 색(보너스 조건).
## 효과·보너스 말: draw(덱에서 뽑기), pick(빈터에서 줍기), cave(덱 맨 위를 굴에 넣기).
## 점수 규칙 말은 Score에 적혀 있다.

const SIDES := {&"v": [&"Top", &"Bottom"], &"h": [&"Left", &"Right"]}

## 나무 8종: 비용, 심을 때 효과, 같은 색으로 냈을 때 보너스, 계절 끝 점수 규칙(Score)
const TREES := {
	&"oak": {cost = 2, effect = {}, bonus = {draw = 1}, score = {tree_kinds = 6, pts = 8}},
	&"birch": {cost = 0, effect = {draw = 1}, bonus = {}, score = {flat = 1}},
	&"pine": {cost = 1, effect = {}, bonus = {}, score = {per_here = 2}},
	&"fir": {cost = 2, effect = {}, bonus = {cave = 1}, score = {flat = 6}},
	&"maple": {cost = 2, effect = {}, bonus = {pick = 1}, score = {late = 7, early = 3}},
	&"chestnut": {cost = 1, effect = {}, bonus = {}, score = {set = [0, 1, 4, 8, 14, 20]}},
	&"linden": {cost = 1, effect = {}, bonus = {}, score = {most = 4, other = 1}},
	&"beech": {cost = 1, effect = {}, bonus = {}, score = {at_least = 3, each = 5}},
}
## 이웃 14종: 종류, 자리, 비용, 효과, 보너스, 점수. stack이면 한 자리에 여럿 겹친다.
## hook은 숲에 있는 동안 계속 걸리는 효과(버섯): 이후 그 자리에 낼 때마다 give.
## 키는 3D 모델(Dweller.KINDS)과 같다.
const SPECIES := {
	&"owl": {kind = &"bird", side = &"Top", cost = 2, effect = {}, bonus = {draw = 1}, score = {per_kind = &"paw", pts = 1}},
	&"finch": {kind = &"bird", side = &"Top", cost = 1, effect = {}, bonus = {pick = 1}, score = {same_tree = &"butterfly", pts = 5, other = 2}},
	&"bat": {kind = &"bat", side = &"Top", cost = 1, effect = {}, bonus = {draw = 1}, score = {at_least = 3, each = 5, other = 1}},
	&"butterfly": {kind = &"butterfly", side = &"Top", cost = 0, effect = {}, bonus = {}, score = {spread = [0, 3, 7, 12, 20, 32]}},
	&"bee": {kind = &"insect", side = &"Bottom", cost = 1, effect = {pick = 1}, bonus = {}, score = {per_species = &"flower", pts = 2}},
	&"mushroom": {kind = &"mushroom", side = &"Bottom", cost = 2, effect = {}, bonus = {}, score = {flat = 0}, hook = {on = &"place", side = &"Left", give = {draw = 1}}},
	&"flower": {kind = &"flower", side = &"Bottom", cost = 0, effect = {}, bonus = {}, score = {flat = 2}},
	&"mole": {kind = &"paw", side = &"Bottom", cost = 2, effect = {cave = 2}, bonus = {}, score = {per_side = &"Bottom", pts = 1}},
	&"axolotl": {kind = &"amphibian", side = &"Bottom", cost = 1, effect = {}, bonus = {draw = 2}, score = {on = [&"pine", &"fir"], pts = 5, other = 2}},
	&"fox": {kind = &"paw", side = &"Side", cost = 2, effect = {draw = 1}, bonus = {}, score = {per_species = &"hare", pts = 2}},
	&"goat": {kind = &"hoof", side = &"Side", cost = 3, effect = {}, bonus = {draw = 2}, score = {full = 4}},
	&"boar": {kind = &"hoof", side = &"Side", cost = 2, effect = {cave = 1}, bonus = {}, score = {on = [&"oak", &"chestnut", &"beech"], pts = 7, other = 2}},
	&"hare": {kind = &"paw", side = &"Side", cost = 0, effect = {}, bonus = {}, stack = true, score = {per_species = &"hare", pts = 1}},
	&"marmot": {kind = &"paw", side = &"Side", cost = 1, effect = {pick = 1}, bonus = {}, score = {distinct_kind = &"paw", pts = 2}},
}
## 시작 주머니 36장: 나무 12 + 이웃 24
const START_TREES := {&"oak": 2, &"birch": 2, &"pine": 1, &"fir": 2, &"maple": 1, &"chestnut": 2, &"linden": 1, &"beech": 1}
const START_PAIRS := [
	[&"owl", &"mushroom", &"v", &"oak"], [&"owl", &"flower", &"v", &"beech"], [&"finch", &"bee", &"v", &"linden"],
	[&"finch", &"axolotl", &"v", &"birch"], [&"bat", &"mole", &"v", &"fir"], [&"bat", &"mushroom", &"v", &"pine"],
	[&"butterfly", &"flower", &"v", &"maple"], [&"butterfly", &"bee", &"v", &"chestnut"], [&"owl", &"axolotl", &"v", &"oak"],
	[&"finch", &"mole", &"v", &"beech"], [&"butterfly", &"axolotl", &"v", &"linden"], [&"bat", &"flower", &"v", &"birch"],
	[&"fox", &"hare", &"h", &"oak"], [&"fox", &"marmot", &"h", &"fir"], [&"goat", &"boar", &"h", &"pine"],
	[&"goat", &"hare", &"h", &"maple"], [&"boar", &"marmot", &"h", &"chestnut"], [&"hare", &"hare", &"h", &"birch"],
	[&"marmot", &"fox", &"h", &"linden"], [&"boar", &"fox", &"h", &"beech"], [&"goat", &"marmot", &"h", &"oak"],
	[&"hare", &"boar", &"h", &"chestnut"], [&"fox", &"goat", &"h", &"maple"], [&"marmot", &"hare", &"h", &"fir"],
]


static func tree(id: int, kind: StringName) -> Dictionary:
	return {id = id, tree = kind, sym = kind}


static func pair(id: int, a: StringName, b: StringName, axis: StringName, sym: StringName) -> Dictionary:
	return {id = id, halves = [a, b], axis = axis, sym = sym}


static func start_bag() -> Array[Dictionary]:
	var bag: Array[Dictionary] = []
	for k in START_TREES:
		for i in START_TREES[k]:
			bag.append(tree(bag.size(), k))
	for p in START_PAIRS:
		bag.append(pair(bag.size(), p[0], p[1], p[2], p[3]))
	return bag


static func is_tree(card: Dictionary) -> bool:
	return card.has("tree")


static func side_of(card: Dictionary, half: int) -> StringName:
	return &"" if is_tree(card) else SIDES[card.axis][half]


static func kind_of(card: Dictionary, half: int) -> StringName:
	return card.tree if is_tree(card) else card.halves[half]


## 카드(반쪽)의 정의: 비용·효과·보너스
static func def_of(card: Dictionary, half: int) -> Dictionary:
	return TREES[card.tree] if is_tree(card) else SPECIES[card.halves[half]]


static func cost_of(card: Dictionary, half: int) -> int:
	return def_of(card, half).cost


## 종이 그 자리에 올 수 있는지(Side는 왼·오른 둘 다)
static func fits(species: StringName, side: StringName) -> bool:
	var s: StringName = SPECIES[species].side
	return s == side or (s == &"Side" and side in [&"Left", &"Right"])
