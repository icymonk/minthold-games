class_name Cards
extends RefCounted
## 카드 데이터: 원작(Forest Shuffle) 기본판의 카드 목록·비용·효과·보너스·점수를 따른다. 글은 새로 썼다.
## 나무 카드 {id, tree, sym}, 이웃 카드 {id, halves = [a, b], axis, syms = [a 색, b 색]}.
## axis v는 위/아래 반쪽, h는 왼/오른 반쪽. sym은 카드 귀퉁이의 나무 색(보너스 조건).
## 효과·보너스 말: draw(덱에서 뽑기), pick(공터에서 줍기), cave(덱 맨 위를 굴에 넣기), again(한 번 더),
## free = 상징(그 상징 카드 1장을 공짜로, 효과·보너스 없이), free_all = 상징(그 상징 카드를 몇 장이든 공짜로),
## more(카드를 몇 장이든 비용을 내고 더 내기), draw_per = 종·상징(숲에 있는 수만큼 뽑기),
## clear_to_cave(공터 카드를 모두 굴로), stash(손패를 몇 장이든 굴에 넣고 그만큼 뽑기), boost(이 나무가 한 그루 더로 셈).
## 점수 규칙 말은 Score에 적혀 있다.

const SIDES := {&"v": [&"Top", &"Bottom"], &"h": [&"Left", &"Right"]}

## 나무 8종(원작 기본판): 비용, 심을 때 효과, 같은 색으로 냈을 때 보너스, 계절 끝 점수 규칙(Score)
const TREES := {
	&"linden": {cost = 1, effect = {}, bonus = {}, score = {most = 3, other = 1}},
	&"oak": {cost = 2, effect = {}, bonus = {again = true}, score = {tree_kinds = 8, pts = 10}},
	&"fir": {cost = 2, effect = {}, bonus = {free = &"paw"}, score = {per_here = 2}},
	&"birch": {cost = 0, effect = {draw = 1}, bonus = {}, score = {flat = 1}},
	&"beech": {cost = 1, effect = {draw = 1}, bonus = {}, score = {at_least = 4, each = 5}},
	&"maple": {cost = 2, effect = {}, bonus = {}, score = {per_tree = 1}},
	&"pine": {cost = 2, effect = {}, bonus = {again = true}, score = {flat = 5}},
	&"chestnut": {cost = 1, effect = {}, bonus = {}, score = {set = [0, 1, 4, 9, 16, 25, 36, 49]}},
}
## 이웃 49종(원작 기본판): 종류, 상징(tags: 점수·효과가 세는 그림), 자리, 비용, 효과, 보너스, 점수.
## stack: 한 자리에 같은 종이 겹친다(true = 여럿, 숫자 = 그 수까지). hook: 숲에 있는 동안 걸리는 효과(버섯).
## 키는 3D 모델(Dweller.KINDS)과 같다.
const SPECIES := {
	&"tawny_owl": {kind = &"bird", side = &"Top", cost = 2, effect = {draw = 1}, bonus = {draw = 2}, score = {flat = 5}},
	&"goshawk": {kind = &"bird", side = &"Top", cost = 2, effect = {}, bonus = {}, score = {per_kind = &"bird", pts = 3}},
	&"woodpecker": {kind = &"bird", side = &"Top", cost = 1, effect = {draw = 1}, bonus = {}, score = {trees_at_least = 8, pts = 10}},
	&"chaffinch": {kind = &"bird", side = &"Top", cost = 1, effect = {}, bonus = {}, score = {on = [&"beech"], pts = 5, other = 0}},
	&"bullfinch": {kind = &"bird", side = &"Top", cost = 1, effect = {}, bonus = {}, score = {per_kind = &"insect", pts = 2}},
	&"jay": {kind = &"bird", side = &"Top", cost = 1, effect = {again = true}, bonus = {}, score = {flat = 3}},
	&"red_squirrel": {kind = &"paw", side = &"Top", cost = 0, effect = {}, bonus = {}, score = {on = [&"oak"], pts = 5, other = 0}},
	&"camberwell_beauty": {kind = &"butterfly", tags = [&"butterfly", &"insect"], side = &"Top", cost = 0, effect = {}, bonus = {}, score = {butterfly_sets = BUTTERFLY_SETS}},
	&"large_tortoiseshell": {kind = &"butterfly", tags = [&"butterfly", &"insect"], side = &"Top", cost = 0, effect = {}, bonus = {}, score = {butterfly_sets = BUTTERFLY_SETS}},
	&"peacock_butterfly": {kind = &"butterfly", tags = [&"butterfly", &"insect"], side = &"Top", cost = 0, effect = {}, bonus = {}, score = {butterfly_sets = BUTTERFLY_SETS}},
	&"purple_emperor": {kind = &"butterfly", tags = [&"butterfly", &"insect"], side = &"Top", cost = 0, effect = {}, bonus = {}, score = {butterfly_sets = BUTTERFLY_SETS}},
	&"fritillary": {kind = &"butterfly", tags = [&"butterfly", &"insect"], side = &"Top", cost = 0, effect = {}, bonus = {}, score = {butterfly_sets = BUTTERFLY_SETS}},
	&"moss": {kind = &"flower", side = &"Bottom", cost = 0, effect = {}, bonus = {}, score = {trees_at_least = 10, pts = 10}},
	&"wood_ant": {kind = &"insect", side = &"Bottom", cost = 1, effect = {}, bonus = {}, score = {per_side = &"Bottom", pts = 2}},
	&"stag_beetle": {kind = &"insect", side = &"Bottom", cost = 2, effect = {}, bonus = {free = &"bird"}, score = {per_kind = &"paw", pts = 1}},
	&"fire_salamander": {kind = &"amphibian", side = &"Bottom", cost = 1, effect = {}, bonus = {free = &"paw"}, score = {set = [0, 5, 15, 25]}},
	&"pond_turtle": {kind = &"amphibian", side = &"Bottom", cost = 2, effect = {draw = 1}, bonus = {}, score = {flat = 5}},
	&"tree_frog": {kind = &"amphibian", side = &"Bottom", cost = 0, effect = {}, bonus = {}, score = {per_species = &"gnat", pts = 5}},
	&"hedgehog": {kind = &"paw", side = &"Bottom", cost = 1, effect = {}, bonus = {draw = 1}, score = {per_kind = &"butterfly", pts = 2}},
	&"toad": {kind = &"amphibian", side = &"Bottom", cost = 0, effect = {}, bonus = {}, stack = 2, score = {pair = 5}},
	&"fern": {kind = &"flower", side = &"Bottom", cost = 1, effect = {draw = 1}, bonus = {}, score = {per_kind = &"amphibian", pts = 6}},
	&"wild_strawberry": {kind = &"flower", side = &"Bottom", cost = 0, effect = {}, bonus = {}, score = {tree_kinds = 8, pts = 10}},
	&"blackberry": {kind = &"flower", side = &"Bottom", cost = 0, effect = {}, bonus = {}, score = {per_kind = &"flower", pts = 2}},
	&"firefly": {kind = &"insect", side = &"Bottom", cost = 0, effect = {}, bonus = {}, score = {set = [0, 0, 10, 15, 20]}},
	&"chanterelle": {kind = &"mushroom", side = &"Bottom", cost = 2, effect = {}, bonus = {}, hook = {on = &"plant", give = {draw = 1}}, score = {flat = 0}},
	&"fly_agaric": {kind = &"mushroom", side = &"Bottom", cost = 2, effect = {}, bonus = {}, hook = {on = &"place", tag = &"paw", give = {draw = 1}}, score = {flat = 0}},
	&"penny_bun": {kind = &"mushroom", side = &"Bottom", cost = 2, effect = {}, bonus = {}, hook = {on = &"place", side = &"Top", give = {draw = 1}}, score = {flat = 0}},
	&"parasol": {kind = &"mushroom", side = &"Bottom", cost = 2, effect = {}, bonus = {}, hook = {on = &"place", side = &"Bottom", give = {draw = 1}}, score = {flat = 0}},
	&"mole": {kind = &"paw", side = &"Bottom", cost = 2, effect = {more = true}, bonus = {}, score = {flat = 0}},
	&"hare": {kind = &"paw", side = &"Side", cost = 0, effect = {}, bonus = {}, stack = true, score = {per_species = &"hare", pts = 1}},
	&"badger": {kind = &"paw", side = &"Side", cost = 1, effect = {}, bonus = {free = &"paw"}, score = {flat = 2}},
	&"fox": {kind = &"paw", side = &"Side", cost = 2, effect = {draw_per = &"hare"}, bonus = {}, score = {per_species = &"hare", pts = 2}},
	&"raccoon": {kind = &"paw", side = &"Side", cost = 1, effect = {stash = true}, bonus = {}, score = {flat = 0}},
	&"boar": {kind = &"hoof", side = &"Side", cost = 2, effect = {}, bonus = {}, score = {with = &"squeaker", pts = 10, other = 0}},
	&"squeaker": {kind = &"hoof", side = &"Side", cost = 0, effect = {}, bonus = {}, score = {flat = 1}},
	&"roe_deer": {kind = &"deer", tags = [&"deer", &"hoof"], side = &"Side", cost = 2, effect = {}, bonus = {draw = 1}, score = {per_sym = 3}},
	&"red_deer": {kind = &"deer", tags = [&"deer", &"hoof"], side = &"Side", cost = 2, effect = {}, bonus = {free = &"deer"}, score = {per_kind = [&"tree", &"flower"], pts = 1}},
	&"fallow_deer": {kind = &"deer", tags = [&"deer", &"hoof"], side = &"Side", cost = 2, effect = {}, bonus = {draw = 2}, score = {per_kind = &"hoof", pts = 3}},
	&"wolf": {kind = &"paw", side = &"Side", cost = 3, effect = {draw_per = &"deer"}, bonus = {again = true}, score = {per_kind = &"deer", pts = 5}},
	&"lynx": {kind = &"paw", side = &"Side", cost = 1, effect = {}, bonus = {}, score = {with = &"roe_deer", pts = 10, other = 0}},
	&"brown_bear": {kind = &"paw", side = &"Side", cost = 3, effect = {clear_to_cave = true}, bonus = {draw = 1, again = true}, score = {flat = 0}},
	&"marten": {kind = &"paw", side = &"Side", cost = 1, effect = {draw = 1}, bonus = {}, score = {full = 5}},
	&"dormouse": {kind = &"paw", side = &"Side", cost = 1, effect = {}, bonus = {}, score = {same_tree = &"bat", pts = 15, other = 0}},
	&"gnat": {kind = &"insect", side = &"Side", cost = 0, effect = {free_all = &"bat"}, bonus = {}, score = {per_kind = &"bat", pts = 1}},
	&"carpenter_bee": {kind = &"insect", side = &"Side", cost = 1, effect = {boost = true}, bonus = {}, score = {flat = 0}},
	&"barbastelle_bat": {kind = &"bat", side = &"Side", cost = 1, effect = {}, bonus = {}, score = {distinct_at_least = 3, each = 5, other = 0}},
	&"bechstein_bat": {kind = &"bat", side = &"Side", cost = 1, effect = {}, bonus = {}, score = {distinct_at_least = 3, each = 5, other = 0}},
	&"long_eared_bat": {kind = &"bat", side = &"Side", cost = 1, effect = {}, bonus = {}, score = {distinct_at_least = 3, each = 5, other = 0}},
	&"horseshoe_bat": {kind = &"bat", side = &"Side", cost = 1, effect = {}, bonus = {}, score = {distinct_at_least = 3, each = 5, other = 0}},
}
## 나비 묶음(서로 다른 나비 n종 한 묶음 → 표[n])
const BUTTERFLY_SETS := [0, 0, 3, 6, 12, 20, 35, 55, 80]
## 원작 기본판 덱: 나무 장수와 반쪽 카드 92장 [위·왼 종, 아래·오른 종, axis, 위·왼 나무 색, 아래·오른 나무 색]
const FULL_TREES := {&"linden": 9, &"oak": 7, &"fir": 6, &"birch": 10, &"beech": 10, &"maple": 6, &"pine": 7, &"chestnut": 11}
const FULL_PAIRS := [
	[&"hare", &"badger", &"h", &"linden", &"pine"],
	[&"hare", &"horseshoe_bat", &"h", &"oak", &"linden"],
	[&"hare", &"fox", &"h", &"fir", &"oak"],
	[&"raccoon", &"hare", &"h", &"pine", &"maple"],
	[&"boar", &"hare", &"h", &"maple", &"fir"],
	[&"long_eared_bat", &"hare", &"h", &"maple", &"linden"],
	[&"raccoon", &"roe_deer", &"h", &"fir", &"beech"],
	[&"long_eared_bat", &"badger", &"h", &"maple", &"pine"],
	[&"barbastelle_bat", &"boar", &"h", &"chestnut", &"oak"],
	[&"brown_bear", &"raccoon", &"h", &"linden", &"fir"],
	[&"marten", &"brown_bear", &"h", &"maple", &"chestnut"],
	[&"red_deer", &"brown_bear", &"h", &"linden", &"beech"],
	[&"barbastelle_bat", &"marten", &"h", &"fir", &"chestnut"],
	[&"lynx", &"hare", &"h", &"pine", &"birch"],
	[&"boar", &"marten", &"h", &"birch", &"oak"],
	[&"badger", &"gnat", &"h", &"chestnut", &"oak"],
	[&"fox", &"carpenter_bee", &"h", &"linden", &"pine"],
	[&"boar", &"roe_deer", &"h", &"maple", &"chestnut"],
	[&"fallow_deer", &"boar", &"h", &"linden", &"pine"],
	[&"fallow_deer", &"roe_deer", &"h", &"linden", &"birch"],
	[&"red_deer", &"fallow_deer", &"h", &"fir", &"maple"],
	[&"carpenter_bee", &"lynx", &"h", &"pine", &"beech"],
	[&"dormouse", &"barbastelle_bat", &"h", &"beech", &"oak"],
	[&"horseshoe_bat", &"dormouse", &"h", &"beech", &"pine"],
	[&"fox", &"wolf", &"h", &"linden", &"fir"],
	[&"dormouse", &"long_eared_bat", &"h", &"fir", &"beech"],
	[&"bechstein_bat", &"dormouse", &"h", &"beech", &"oak"],
	[&"gnat", &"carpenter_bee", &"h", &"birch", &"pine"],
	[&"wolf", &"gnat", &"h", &"pine", &"chestnut"],
	[&"roe_deer", &"squeaker", &"h", &"linden", &"maple"],
	[&"bechstein_bat", &"wolf", &"h", &"oak", &"fir"],
	[&"roe_deer", &"lynx", &"h", &"fir", &"linden"],
	[&"marten", &"bechstein_bat", &"h", &"beech", &"birch"],
	[&"hare", &"red_deer", &"h", &"beech", &"chestnut"],
	[&"wolf", &"horseshoe_bat", &"h", &"maple", &"linden"],
	[&"squeaker", &"red_deer", &"h", &"chestnut", &"oak"],
	[&"fox", &"squeaker", &"h", &"beech", &"oak"],
	[&"lynx", &"raccoon", &"h", &"pine", &"birch"],
	[&"squeaker", &"lynx", &"h", &"oak", &"fir"],
	[&"hare", &"marten", &"h", &"birch", &"chestnut"],
	[&"lynx", &"fox", &"h", &"chestnut", &"pine"],
	[&"hare", &"red_deer", &"h", &"birch", &"chestnut"],
	[&"carpenter_bee", &"hare", &"h", &"fir", &"maple"],
	[&"badger", &"fallow_deer", &"h", &"chestnut", &"birch"],
	[&"goshawk", &"moss", &"v", &"pine", &"linden"],
	[&"woodpecker", &"wood_ant", &"v", &"linden", &"birch"],
	[&"chaffinch", &"wood_ant", &"v", &"birch", &"beech"],
	[&"tawny_owl", &"stag_beetle", &"v", &"beech", &"maple"],
	[&"fritillary", &"fire_salamander", &"v", &"oak", &"chestnut"],
	[&"purple_emperor", &"pond_turtle", &"v", &"chestnut", &"maple"],
	[&"camberwell_beauty", &"pond_turtle", &"v", &"maple", &"birch"],
	[&"large_tortoiseshell", &"fire_salamander", &"v", &"fir", &"pine"],
	[&"bullfinch", &"tree_frog", &"v", &"pine", &"linden"],
	[&"chaffinch", &"stag_beetle", &"v", &"maple", &"birch"],
	[&"goshawk", &"wood_ant", &"v", &"fir", &"beech"],
	[&"woodpecker", &"toad", &"v", &"linden", &"oak"],
	[&"jay", &"fern", &"v", &"birch", &"chestnut"],
	[&"tawny_owl", &"wild_strawberry", &"v", &"beech", &"maple"],
	[&"fritillary", &"blackberry", &"v", &"oak", &"fir"],
	[&"purple_emperor", &"moss", &"v", &"chestnut", &"pine"],
	[&"camberwell_beauty", &"firefly", &"v", &"maple", &"linden"],
	[&"large_tortoiseshell", &"blackberry", &"v", &"fir", &"birch"],
	[&"bullfinch", &"hedgehog", &"v", &"pine", &"beech"],
	[&"peacock_butterfly", &"hedgehog", &"v", &"fir", &"oak"],
	[&"red_squirrel", &"toad", &"v", &"pine", &"chestnut"],
	[&"red_squirrel", &"firefly", &"v", &"chestnut", &"maple"],
	[&"chaffinch", &"toad", &"v", &"beech", &"fir"],
	[&"jay", &"firefly", &"v", &"birch", &"pine"],
	[&"fritillary", &"moss", &"v", &"beech", &"linden"],
	[&"peacock_butterfly", &"chanterelle", &"v", &"oak", &"fir"],
	[&"peacock_butterfly", &"firefly", &"v", &"chestnut", &"beech"],
	[&"large_tortoiseshell", &"mole", &"v", &"maple", &"oak"],
	[&"goshawk", &"hedgehog", &"v", &"fir", &"chestnut"],
	[&"woodpecker", &"wild_strawberry", &"v", &"pine", &"maple"],
	[&"jay", &"fly_agaric", &"v", &"maple", &"fir"],
	[&"tawny_owl", &"penny_bun", &"v", &"birch", &"pine"],
	[&"red_squirrel", &"fire_salamander", &"v", &"beech", &"linden"],
	[&"purple_emperor", &"tree_frog", &"v", &"birch", &"oak"],
	[&"peacock_butterfly", &"toad", &"v", &"linden", &"beech"],
	[&"camberwell_beauty", &"tree_frog", &"v", &"birch", &"oak"],
	[&"bullfinch", &"parasol", &"v", &"pine", &"chestnut"],
	[&"goshawk", &"toad", &"v", &"oak", &"maple"],
	[&"jay", &"fern", &"v", &"chestnut", &"fir"],
	[&"tawny_owl", &"toad", &"v", &"maple", &"pine"],
	[&"bullfinch", &"fern", &"v", &"fir", &"linden"],
	[&"red_squirrel", &"wild_strawberry", &"v", &"oak", &"birch"],
	[&"fritillary", &"blackberry", &"v", &"oak", &"beech"],
	[&"purple_emperor", &"fly_agaric", &"v", &"linden", &"oak"],
	[&"camberwell_beauty", &"chanterelle", &"v", &"chestnut", &"birch"],
	[&"large_tortoiseshell", &"mole", &"v", &"beech", &"maple"],
	[&"chaffinch", &"parasol", &"v", &"maple", &"fir"],
	[&"woodpecker", &"penny_bun", &"v", &"linden", &"pine"],
]
## 카드 꾸미기(오두막): 이슬 = 점수 +2, 금빛 잎 = 어느 나무 색으로도 셈
const DECOS: Array[StringName] = [&"dew", &"gold"]
const DEW_POINTS := 2
## 시작 주머니 36장: 나무 12 + 원작 덱에서 고른 반쪽 카드 24(FULL_PAIRS 번호)
const START_TREES := {&"linden": 2, &"oak": 1, &"fir": 1, &"birch": 2, &"beech": 2, &"maple": 1, &"pine": 1, &"chestnut": 2}
const START_PAIRS := [0, 4, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56, 60, 64, 68, 72, 76, 80, 84, 88, 46]


static func tree(id: int, kind: StringName) -> Dictionary:
	return {id = id, tree = kind, sym = kind}


## 반쪽 카드: syms = 반쪽마다 귀퉁이 나무 색
static func pair(id: int, a: StringName, b: StringName, axis: StringName, syms: Array) -> Dictionary:
	return {id = id, halves = [a, b], axis = axis, syms = syms.duplicate()}


## FULL_PAIRS의 i번째 카드
static func full_pair(id: int, i: int) -> Dictionary:
	var p: Array = FULL_PAIRS[i]
	return pair(id, p[0], p[1], p[2], [p[3], p[4]])


## 카드(반쪽)의 나무 색
static func sym_of(card: Dictionary, half: int) -> StringName:
	return card.get("sym", &"") if not card.has("syms") else card.syms[half]


## 비용으로 낸 카드가 그 나무 색을 가졌는지(반쪽 카드는 두 색 중 하나, 금빛 잎은 아무 색)
static func has_sym(card: Dictionary, sym: StringName) -> bool:
	if card.get("deco", &"") == &"gold":
		return true
	return sym in card.syms if card.has("syms") else card.get("sym", &"") == sym


## 종이 가진 상징(나비는 곤충이기도, 사슴은 발굽 동물이기도). 나무는 tree.
static func tags_of(kind: StringName) -> Array:
	if TREES.has(kind):
		return [&"tree"]
	var d: Dictionary = SPECIES.get(kind, {})
	return d.get("tags", [d.get("kind", &"")])


## 숲에 붙은 이웃의 나무 색(card의 어느 반쪽인지 species로 찾는다)
static func placed_sym(card: Dictionary, species: StringName) -> StringName:
	if not card.has("syms"):
		return card.get("sym", &"")
	return card.syms[maxi(card.halves.find(species), 0)]


static func start_bag() -> Array[Dictionary]:
	var bag: Array[Dictionary] = []
	for k in START_TREES:
		for i in START_TREES[k]:
			bag.append(tree(bag.size(), k))
	for i in START_PAIRS:
		bag.append(full_pair(bag.size(), i))
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
