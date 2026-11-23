class_name Score
extends RefCounted
## 계절 끝 점수(규칙 1-2): 숲 전체 나무·이웃 점수 + 굴 1장당 1. 정령 배수는 1-3(Run)에서.
## 규칙 말(Cards.TREES/SPECIES의 score):
##   flat = n                     그냥 n
##   per_here = n                 이 나무에 붙은 이웃 1마리마다 n
##   per_kind = 종류, pts         숲의 그 종류 이웃 1마리마다 pts
##   per_species = 종, pts        숲의 그 종 1마리마다 pts
##   per_side = 자리, pts         숲의 그 자리 이웃 1마리마다 pts
##   distinct_kind = 종류, pts    숲의 그 종류 이웃 종 가짓수마다 pts
##   full = n                     4방향이 다 찬 나무 1그루마다 n
##   tree_kinds = k, pts          숲의 나무 종류가 k가지 이상이면 pts
##   late, early                  가을·겨울(계절 2~3)이면 late, 아니면 early
##   set = [..]                   같은 종 n그루(마리)면 표[n]을 한 번(첫 장에)
##   spread = [..]                이 종이 붙은 나무 종류 가짓수 n → 표[n]을 한 번
##   most, other                  숲에서 가장 많은(동률 포함) 나무 종이면 most
##   at_least = k, each, other    같은 종이 k 이상이면 장마다 each, 아니면 other
##   same_tree = 종류, pts, other 같은 나무에 그 종류 이웃이 있으면 pts
##   on = [나무 종], pts, other   붙은 나무가 그중 하나면 pts

const LATE_FROM := 2


static func count(forest: Forest, season := 0) -> ScoreLog:
	var log := ScoreLog.new()
	var c := _census(forest)
	var once := {}
	for p in forest.trees:
		var t: Dictionary = forest.trees[p]
		if t.kind == Forest.SAPLING:
			continue
		var rule: Dictionary = Cards.TREES[t.kind].score
		var pts := _eval(rule, t.kind, c.trees, p, forest, c, season, once)
		log.add({card = t.card.id, plot = p, side = &"", what = t.kind, pts = pts, rule = rule.keys()[0]})
	for n in forest.neighbors():
		var rule: Dictionary = Cards.SPECIES[n.species].score
		var pts := _eval(rule, n.species, c.species, n.plot, forest, c, season, once)
		log.add({card = n.card.id, plot = n.plot, side = n.side, what = n.species, pts = pts, rule = rule.keys()[0]})
	log.add_cave(forest.cave.size())
	return log


## 숲 세기: 나무 종별 그루, 이웃 종별·종류별·자리별 마리
static func _census(forest: Forest) -> Dictionary:
	var c := {trees = {}, species = {}, kinds = {}, sides = {}, full = 0}
	for p in forest.trees:
		var k: StringName = forest.trees[p].kind
		if k != Forest.SAPLING:
			c.trees[k] = c.trees.get(k, 0) + 1
		if forest.is_complete(p):
			c.full += 1
	for n in forest.neighbors():
		var kind: StringName = Cards.SPECIES[n.species].kind
		c.species[n.species] = c.species.get(n.species, 0) + 1
		c.kinds[kind] = c.kinds.get(kind, 0) + 1
		c.sides[n.side] = c.sides.get(n.side, 0) + 1
	return c


static func _eval(r: Dictionary, what: StringName, same: Dictionary, plot: int, forest: Forest, c: Dictionary, season: int, once: Dictionary) -> int:
	if r.has("flat"):
		return r.flat
	if r.has("per_here"):
		var n := 0
		for s in Forest.SIDES:
			n += forest.occupants(plot, s).size()
		return n * r.per_here
	if r.has("per_kind"):
		return c.kinds.get(r.per_kind, 0) * r.pts
	if r.has("per_species"):
		return c.species.get(r.per_species, 0) * r.pts
	if r.has("per_side"):
		return c.sides.get(r.per_side, 0) * r.pts
	if r.has("distinct_kind"):
		var n := 0
		for s in c.species:
			if Cards.SPECIES[s].kind == r.distinct_kind:
				n += 1
		return n * r.pts
	if r.has("full"):
		return c.full * r.full
	if r.has("tree_kinds"):
		return r.pts if c.trees.size() >= r.tree_kinds else 0
	if r.has("late"):
		return r.late if season >= LATE_FROM else r.early
	if r.has("set"):
		if once.has(what):
			return 0
		once[what] = true
		return r.set[mini(same.get(what, 0), r.set.size() - 1)]
	if r.has("spread"):
		if once.has(what):
			return 0
		once[what] = true
		var kinds := {}
		for n in forest.neighbors():
			if n.species == what:
				kinds[forest.kind_at(n.plot)] = true
		return r.spread[mini(kinds.size(), r.spread.size() - 1)]
	if r.has("most"):
		var top := 0
		for k in c.trees:
			top = maxi(top, c.trees[k])
		return r.most if same.get(what, 0) >= top else r.other
	if r.has("at_least"):
		return r.each if same.get(what, 0) >= r.at_least else r.get("other", 0)
	if r.has("same_tree"):
		for s in Forest.SIDES:
			for o in forest.occupants(plot, s):
				if Cards.SPECIES[o.species].kind == r.same_tree:
					return r.pts
		return r.other
	if r.has("on"):
		return r.pts if forest.kind_at(plot) in r.on else r.other
	push_error("Score: unknown rule %s" % r)
	return 0
