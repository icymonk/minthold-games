class_name Spirits
extends RefCounted
## 숲 정령(규칙 1-3·3-1, 유물 5칸, 30종). 계절 끝 점수 = (나무·이웃 + 굴) × (1 + 정령 배수 합).
## 배수 말: kinds + at_least + x(그 종류들 합이 at_least마리 이상이면 +x), distinct_kind + x(그 종류의 종 가짓수마다 +x),
##   sides + at_least + x(그 자리 이웃 합), per_tree_kinds(나무 종류마다), per_full(꽉 찬 나무마다), trees_at_least + x,
##   per_sapling(묘목마다), cave_step + x(굴 cave_step장마다), in_season + x(그 계절에만), always(늘)
## 규칙 말: wind_draw(첫 바람에 더 뽑기), ignore_winter, cave(굴 1장 점수), hand·clearing(한도 +), acorns(계절마다 +), start_draw(계절 시작에 더 받기)

const SLOTS := 5
const ALL := {
	&"firefly": {kinds = [&"butterfly", &"insect"], at_least = 5, x = 0.5},
	&"old_owl": {distinct_kind = &"bird", x = 0.1},
	&"wind_child": {wind_draw = 2},
	&"hibernating_bear": {ignore_winter = true},
	&"acorn_squirrel": {cave = 2},
	&"moth_queen": {kinds = [&"butterfly"], at_least = 3, x = 0.3},
	&"bat_lantern": {kinds = [&"bat"], at_least = 3, x = 0.4},
	&"stag_king": {kinds = [&"deer", &"hoof"], at_least = 3, x = 0.4},
	&"frog_choir": {kinds = [&"amphibian"], at_least = 3, x = 0.3},
	&"mushroom_sage": {kinds = [&"mushroom"], at_least = 2, x = 0.3},
	&"meadow_fairy": {kinds = [&"flower"], at_least = 4, x = 0.3},
	&"burrow_keeper": {kinds = [&"paw"], at_least = 5, x = 0.4},
	&"nectar_spirit": {kinds = [&"insect", &"flower"], at_least = 4, x = 0.3},
	&"sky_watcher": {sides = [&"Top"], at_least = 5, x = 0.3},
	&"root_weaver": {sides = [&"Bottom"], at_least = 5, x = 0.3},
	&"trail_guard": {sides = [&"Left", &"Right"], at_least = 6, x = 0.3},
	&"grove_mother": {per_tree_kinds = 0.05},
	&"full_moon": {per_full = 0.1},
	&"great_canopy": {trees_at_least = 12, x = 0.5},
	&"moss_hag": {per_sapling = 0.1},
	&"crow_collector": {cave_step = 5, x = 0.1},
	&"spring_breeze": {in_season = 0, x = 0.2},
	&"winter_wren": {in_season = 3, x = 0.3},
	&"dew_spirit": {always = 0.1},
	&"fox_trickster": {distinct_kind = &"paw", x = 0.1},
	&"rain_maker": {distinct_kind = &"amphibian", x = 0.15},
	&"seed_keeper": {start_draw = 2},
	&"deep_pocket": {hand = 2},
	&"still_air": {clearing = 3},
	&"acorn_cache": {acorns = 3},
}


static func mult(forest: Forest, owned: Array[StringName], season := 0) -> float:
	var m := 1.0
	var kinds := {}
	var species := {}
	var sides := {}
	for n in forest.neighbors():
		var k: StringName = Cards.SPECIES[n.species].kind
		kinds[k] = kinds.get(k, 0) + 1
		species[n.species] = k
		sides[n.side] = sides.get(n.side, 0) + 1
	var tree_kinds := {}
	var trees := 0
	var saplings := 0
	var full := 0
	for p in forest.trees:
		var t: StringName = forest.trees[p].kind
		if t == Forest.SAPLING:
			saplings += 1
		else:
			trees += 1
			tree_kinds[t] = true
		if forest.is_complete(p):
			full += 1
	for id in owned:
		var d: Dictionary = ALL[id]
		if d.has("kinds"):
			var n := 0
			for k in d.kinds:
				n += kinds.get(k, 0)
			m += d.x if n >= d.at_least else 0.0
		elif d.has("sides"):
			var n := 0
			for s in d.sides:
				n += sides.get(s, 0)
			m += d.x if n >= d.at_least else 0.0
		elif d.has("distinct_kind"):
			m += d.x * species.values().count(d.distinct_kind)
		elif d.has("per_tree_kinds"):
			m += d.per_tree_kinds * tree_kinds.size()
		elif d.has("per_full"):
			m += d.per_full * full
		elif d.has("trees_at_least"):
			m += d.x if trees >= d.trees_at_least else 0.0
		elif d.has("per_sapling"):
			m += d.per_sapling * saplings
		elif d.has("cave_step"):
			m += d.x * (forest.cave.size() / d.cave_step)
		elif d.has("in_season"):
			m += d.x if season == d.in_season else 0.0
		elif d.has("always"):
			m += d.always
	return m


static func value(owned: Array[StringName], key: String, default: Variant) -> Variant:
	for id in owned:
		if ALL[id].has(key):
			return ALL[id][key]
	return default
