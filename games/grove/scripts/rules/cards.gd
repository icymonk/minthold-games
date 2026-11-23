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
## 이웃 90종: 종류, 자리, 비용, 효과, 보너스, 점수. stack이면 한 자리에 여럿 겹친다.
## hook은 숲에 있는 동안 계속 걸리는 효과(버섯): 이후 그 자리에 낼 때마다 give.
## 키는 3D 모델(Dweller.KINDS)과 같다.
const SPECIES := {
	&"owl": {kind = &"bird", side = &"Top", cost = 2, effect = {}, bonus = {draw = 1}, score = {per_kind = &"paw", pts = 1}},
	&"finch": {kind = &"bird", side = &"Top", cost = 1, effect = {}, bonus = {pick = 1}, score = {same_tree = &"butterfly", pts = 5, other = 2}},
	&"bat": {kind = &"bat", side = &"Top", cost = 1, effect = {}, bonus = {draw = 1}, score = {distinct_at_least = 3, each = 5, other = 1}},
	&"butterfly": {kind = &"butterfly", side = &"Top", cost = 0, effect = {}, bonus = {}, score = {kind_set = BUTTERFLY_SET}},
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
	# 3-1: 26종 더(보상·가게로 들어온다)
	&"eagle": {kind = &"bird", side = &"Top", cost = 3, effect = {}, bonus = {draw = 2}, score = {flat = 8}},
	&"woodpecker": {kind = &"bird", side = &"Top", cost = 1, effect = {pick = 1}, bonus = {}, score = {per_tree = 1}},
	&"jay": {kind = &"bird", side = &"Top", cost = 2, effect = {}, bonus = {pick = 1}, score = {per_tree_kind = &"oak", pts = 3}},
	&"red_panda": {kind = &"paw", side = &"Top", cost = 1, effect = {pick = 1}, bonus = {}, score = {on = [&"maple", &"linden"], pts = 5, other = 2}},
	&"long_eared_bat": {kind = &"bat", side = &"Top", cost = 1, effect = {}, bonus = {draw = 1}, score = {distinct_at_least = 3, each = 5, other = 1}},
	&"horseshoe_bat": {kind = &"bat", side = &"Top", cost = 2, effect = {cave = 1}, bonus = {}, score = {distinct_at_least = 3, each = 5, other = 1}},
	&"swallowtail": {kind = &"butterfly", side = &"Top", cost = 0, effect = {}, bonus = {}, score = {kind_set = BUTTERFLY_SET}},
	&"morpho": {kind = &"butterfly", side = &"Top", cost = 1, effect = {}, bonus = {draw = 1}, score = {kind_set = BUTTERFLY_SET}},
	&"peacock_butterfly": {kind = &"butterfly", side = &"Top", cost = 0, effect = {}, bonus = {}, score = {kind_set = BUTTERFLY_SET}},
	&"cabbage_white": {kind = &"butterfly", side = &"Top", cost = 0, effect = {}, bonus = {}, score = {kind_set = BUTTERFLY_SET}},
	&"newt": {kind = &"amphibian", side = &"Bottom", cost = 1, effect = {}, bonus = {draw = 1}, score = {per_kind = &"amphibian", pts = 1}},
	&"fire_salamander": {kind = &"amphibian", side = &"Bottom", cost = 2, effect = {cave = 1}, bonus = {}, score = {flat = 4}},
	&"chanterelle": {kind = &"mushroom", side = &"Bottom", cost = 2, effect = {}, bonus = {}, score = {flat = 0}, hook = {on = &"place", side = &"Top", give = {draw = 1}}},
	&"fly_agaric": {kind = &"mushroom", side = &"Bottom", cost = 1, effect = {}, bonus = {}, score = {flat = 0}, hook = {on = &"plant", give = {draw = 1}}},
	&"violet": {kind = &"flower", side = &"Bottom", cost = 0, effect = {}, bonus = {}, score = {same_tree = &"butterfly", pts = 4, other = 1}},
	&"fern": {kind = &"flower", side = &"Bottom", cost = 0, effect = {}, bonus = {}, score = {on = [&"fir", &"pine"], pts = 4, other = 1}},
	&"field_mouse": {kind = &"paw", side = &"Bottom", cost = 0, effect = {pick = 1}, bonus = {}, score = {per_kind = &"mushroom", pts = 2}},
	&"badger": {kind = &"paw", side = &"Side", cost = 2, effect = {}, bonus = {cave = 1}, score = {per_side = &"Bottom", pts = 2}},
	&"wolf": {kind = &"paw", side = &"Side", cost = 3, effect = {draw = 1}, bonus = {}, score = {per_kind = &"deer", pts = 4}},
	&"moon_bear": {kind = &"paw", side = &"Side", cost = 3, effect = {cave = 2}, bonus = {}, score = {per_cave = 1}},
	&"roe_deer": {kind = &"deer", side = &"Side", cost = 2, effect = {}, bonus = {draw = 1}, score = {kinds_of_trees = 1}},
	&"red_deer": {kind = &"deer", side = &"Side", cost = 3, effect = {}, bonus = {draw = 2}, score = {per_kind = &"flower", pts = 2}},
	&"otter": {kind = &"paw", side = &"Side", cost = 2, effect = {}, bonus = {}, score = {per_kind = &"amphibian", pts = 2}},
	&"duck": {kind = &"bird", side = &"Bottom", cost = 1, effect = {draw = 1}, bonus = {}, score = {flat = 3}},
	&"quail": {kind = &"bird", side = &"Side", cost = 0, effect = {}, bonus = {}, score = {per_kind = &"bird", pts = 1}},
	&"crested_ibis": {kind = &"bird", side = &"Side", cost = 2, effect = {}, bonus = {}, score = {on = [&"pine"], pts = 8, other = 3}},
	# 4-2: 50종 더
	&"magpie": {kind = &"bird", side = &"Top", cost = 1, effect = {}, bonus = {pick = 1}, score = {per_tree_kind = &"pine", pts = 2}},
	&"crow": {kind = &"bird", side = &"Top", cost = 2, effect = {draw = 1}, bonus = {}, score = {per_cave = 1}},
	&"great_tit": {kind = &"bird", side = &"Top", cost = 0, effect = {}, bonus = {}, score = {same_tree = &"insect", pts = 4, other = 1}},
	&"nuthatch": {kind = &"bird", side = &"Top", cost = 1, effect = {}, bonus = {draw = 1}, score = {on = [&"oak", &"beech"], pts = 4, other = 1}},
	&"cuckoo": {kind = &"bird", side = &"Top", cost = 1, effect = {pick = 1}, bonus = {}, score = {late = 5, early = 1}},
	&"scops_owl": {kind = &"bird", side = &"Top", cost = 2, effect = {}, bonus = {draw = 1}, score = {per_kind = &"bat", pts = 2}},
	&"goshawk": {kind = &"bird", side = &"Top", cost = 3, effect = {draw = 1}, bonus = {}, score = {per_kind = &"paw", pts = 1}},
	&"noctule": {kind = &"bat", side = &"Top", cost = 1, effect = {}, bonus = {draw = 1}, score = {distinct_at_least = 3, each = 5, other = 1}},
	&"pipistrelle": {kind = &"bat", side = &"Top", cost = 0, effect = {}, bonus = {}, score = {distinct_at_least = 3, each = 5, other = 1}},
	&"purple_emperor": {kind = &"butterfly", side = &"Top", cost = 1, effect = {}, bonus = {pick = 1}, score = {kind_set = BUTTERFLY_SET}},
	&"sulphur": {kind = &"butterfly", side = &"Top", cost = 0, effect = {}, bonus = {}, score = {kind_set = BUTTERFLY_SET}},
	&"blue_copper": {kind = &"butterfly", side = &"Top", cost = 0, effect = {}, bonus = {}, score = {kind_set = BUTTERFLY_SET}},
	&"luna_moth": {kind = &"butterfly", side = &"Top", cost = 1, effect = {}, bonus = {draw = 1}, score = {kind_set = BUTTERFLY_SET}},
	&"flying_squirrel": {kind = &"paw", side = &"Top", cost = 1, effect = {}, bonus = {pick = 1}, score = {per_tree = 1}},
	&"red_squirrel": {kind = &"paw", side = &"Top", cost = 1, effect = {pick = 1}, bonus = {}, score = {per_tree_kind = &"chestnut", pts = 3}},
	&"cicada": {kind = &"insect", side = &"Top", cost = 0, effect = {}, bonus = {}, score = {late = 4, early = 0}},
	&"stag_beetle": {kind = &"insect", side = &"Top", cost = 2, effect = {}, bonus = {draw = 1}, score = {on = [&"oak"], pts = 7, other = 2}},
	&"firefly_bug": {kind = &"insect", side = &"Top", cost = 0, effect = {}, bonus = {}, score = {per_kind = &"insect", pts = 1}},
	&"ant": {kind = &"insect", side = &"Bottom", cost = 0, effect = {}, bonus = {}, stack = true, score = {per_species = &"ant", pts = 1}},
	&"ladybug": {kind = &"insect", side = &"Bottom", cost = 0, effect = {pick = 1}, bonus = {}, score = {flat = 2}},
	&"bumblebee": {kind = &"insect", side = &"Bottom", cost = 1, effect = {}, bonus = {}, score = {per_kind = &"flower", pts = 2}},
	&"shiitake": {kind = &"mushroom", side = &"Bottom", cost = 2, effect = {}, bonus = {}, score = {flat = 0}, hook = {on = &"place", side = &"Right", give = {draw = 1}}},
	&"oyster_mushroom": {kind = &"mushroom", side = &"Bottom", cost = 1, effect = {}, bonus = {}, score = {per_kind = &"mushroom", pts = 2}},
	&"puffball": {kind = &"mushroom", side = &"Bottom", cost = 0, effect = {}, bonus = {}, score = {flat = 3}},
	&"lingzhi": {kind = &"mushroom", side = &"Bottom", cost = 3, effect = {}, bonus = {}, score = {flat = 10}},
	&"azalea": {kind = &"flower", side = &"Bottom", cost = 1, effect = {}, bonus = {}, score = {late = 1, early = 6}},
	&"lily_of_valley": {kind = &"flower", side = &"Bottom", cost = 0, effect = {}, bonus = {}, score = {same_tree = &"insect", pts = 4, other = 1}},
	&"bellflower": {kind = &"flower", side = &"Bottom", cost = 0, effect = {}, bonus = {}, score = {on = [&"birch", &"linden"], pts = 4, other = 1}},
	&"clover": {kind = &"flower", side = &"Bottom", cost = 0, effect = {}, bonus = {}, score = {per_species = &"hare", pts = 2}},
	&"wild_ginseng": {kind = &"flower", side = &"Bottom", cost = 3, effect = {}, bonus = {}, score = {flat = 9}},
	&"hedgehog": {kind = &"paw", side = &"Bottom", cost = 1, effect = {}, bonus = {}, score = {per_kind = &"insect", pts = 2}},
	&"shrew": {kind = &"paw", side = &"Bottom", cost = 0, effect = {}, bonus = {draw = 1}, score = {flat = 2}},
	&"chipmunk": {kind = &"paw", side = &"Bottom", cost = 1, effect = {pick = 1}, bonus = {}, score = {per_tree_kind = &"chestnut", pts = 2}},
	&"tree_frog": {kind = &"amphibian", side = &"Bottom", cost = 0, effect = {}, bonus = {}, score = {per_kind = &"amphibian", pts = 1}},
	&"toad": {kind = &"amphibian", side = &"Bottom", cost = 1, effect = {}, bonus = {draw = 1}, score = {per_kind = &"insect", pts = 1}},
	&"pond_frog": {kind = &"amphibian", side = &"Bottom", cost = 1, effect = {}, bonus = {}, score = {on = [&"birch", &"linden"], pts = 5, other = 2}},
	&"pond_turtle": {kind = &"amphibian", side = &"Bottom", cost = 2, effect = {cave = 1}, bonus = {}, score = {flat = 5}},
	&"mandarin_duck": {kind = &"bird", side = &"Bottom", cost = 2, effect = {}, bonus = {draw = 1}, score = {per_kind = &"amphibian", pts = 2}},
	&"raccoon_dog": {kind = &"paw", side = &"Side", cost = 1, effect = {}, bonus = {}, score = {per_kind = &"mushroom", pts = 2}},
	&"weasel": {kind = &"paw", side = &"Side", cost = 1, effect = {draw = 1}, bonus = {}, score = {per_kind = &"bird", pts = 1}},
	&"marten": {kind = &"paw", side = &"Side", cost = 2, effect = {}, bonus = {pick = 1}, score = {per_kind = &"bird", pts = 1}},
	&"leopard_cat": {kind = &"paw", side = &"Side", cost = 2, effect = {}, bonus = {draw = 1}, score = {per_side = &"Bottom", pts = 1}},
	&"tiger": {kind = &"paw", side = &"Side", cost = 3, effect = {}, bonus = {draw = 2}, score = {per_kind = &"deer", pts = 4}},
	&"brown_bear": {kind = &"paw", side = &"Side", cost = 3, effect = {cave = 2}, bonus = {}, score = {per_kind = &"insect", pts = 3}},
	&"water_deer": {kind = &"deer", side = &"Side", cost = 1, effect = {}, bonus = {draw = 1}, score = {per_kind = &"flower", pts = 1}},
	&"musk_deer": {kind = &"deer", side = &"Side", cost = 2, effect = {}, bonus = {}, score = {on = [&"pine", &"fir"], pts = 7, other = 2}},
	&"goral": {kind = &"hoof", side = &"Side", cost = 2, effect = {}, bonus = {draw = 1}, score = {full = 3}},
	&"sika_deer": {kind = &"deer", side = &"Side", cost = 2, effect = {}, bonus = {pick = 1}, score = {kinds_of_trees = 1}},
	&"pheasant": {kind = &"bird", side = &"Side", cost = 1, effect = {}, bonus = {}, score = {per_kind = &"flower", pts = 1}},
	&"red_crowned_crane": {kind = &"bird", side = &"Side", cost = 3, effect = {}, bonus = {draw = 2}, score = {flat = 9}},
}
const BUTTERFLY_SET := [0, 3, 7, 12, 20, 32]
## 카드 꾸미기(오두막): 이슬 = 점수 +2, 금빛 잎 = 어느 나무 색으로도 셈
const DECOS: Array[StringName] = [&"dew", &"gold"]
const DEW_POINTS := 2
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
