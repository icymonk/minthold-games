class_name Score
extends RefCounted
## 계절 끝 점수(규칙 1-2): 숲 전체 나무·이웃 점수 + 굴 1장당 1. 정령 배수는 Run이 곱한다.
## mods(계절 사건·정령): {score = [{side?, kind?, x}], cave = 굴 1장 점수}. 이웃 줄마다 맞는 x를 곱한다(내림).
## 규칙 말(Cards.TREES/SPECIES의 score):
##   flat = n                     그냥 n
##   per_here = n                 이 나무에 붙은 이웃 1마리마다 n
##   per_kind = 상징(또는 [상징..]), pts  숲에서 그 상징을 가진 카드 1장마다 pts(tree = 나무)
##   trees_at_least = k, pts      숲에 나무가 k그루 이상이면 pts
##   with = 종, pts, other        숲에 그 종이 하나라도 있으면 pts
##   pair = n                     같은 자리에 같은 종이 둘 이상 겹쳐 있으면 n
##   per_sym = n                  숲에서 이 반쪽과 같은 나무 색 카드 1장마다 n
##   butterfly_sets = [..]        나비를 서로 다른 종끼리 묶어 묶음마다 표[종 수](모든 나비에 한 번)
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
##   kind_set = [..]              같은 종류(예: 나비)의 서로 다른 종 n가지 → 표[n]을 종류마다 한 번
##   distinct_at_least = k, each, other  같은 종류의 서로 다른 종이 k가지 이상이면 마리마다 each
##   per_tree = n                 나무(묘목 빼고) 1그루마다 n
##   per_tree_kind = 나무, pts    그 나무 1그루마다 pts
##   kinds_of_trees = n           나무 종류 가짓수마다 n
##   per_cave = n                 굴 카드 1장마다 n
## 카드 꾸미기 이슬(deco = dew)은 그 줄에 +2.

const LATE_FROM := 2


static func count(forest: Forest, season := 0, mods := {}) -> ScoreLog:
	var log := ScoreLog.new()
	var c := _census(forest)
	c.rivals = mods.get("rivals", {})
	var once := {}
	for p in forest.trees:
		var t: Dictionary = forest.trees[p]
		if t.kind == Forest.SAPLING:
			continue
		var rule: Dictionary = Cards.TREES[t.kind].score
		var pts := _eval(rule, t.kind, c.trees, p, forest, c, season, once, t.kind) + _deco(t.card)
		log.add({card = t.card.id, plot = p, side = &"", what = t.kind, pts = pts, rule = rule.keys()[0]})
	for n in forest.neighbors():
		var rule: Dictionary = Cards.SPECIES[n.species].score
		var pts := _eval(rule, n.species, c.species, n.plot, forest, c, season, once, Cards.placed_sym(n.card, n.species))
		for m: Dictionary in mods.get("score", []):
			if m.get("side", n.side) == n.side and m.get("kind", Cards.SPECIES[n.species].kind) == Cards.SPECIES[n.species].kind:
				pts = int(pts * m.x)
		pts += _deco(n.card)
		log.add({card = n.card.id, plot = n.plot, side = n.side, what = n.species, pts = pts, rule = rule.keys()[0]})
	log.add_cave(forest.cave.size(), mods.get("cave", 1))
	return log


## 여러 명 한 판: 다른 숲들 중 가장 많은 나무 그루(종별·전체). mods.rivals로 넘기면
## 피나무(most)는 다른 숲과, 오색딱따구리(trees_at_least)는 다른 숲의 나무 수와 비교한다(동률이면 받는다).
static func rivals(others: Array) -> Dictionary:
	var out := {trees = {}, count = 0}
	for f: Forest in others:
		var c := _census(f)
		out.count = maxi(out.count, c.count)
		for k in c.trees:
			out.trees[k] = maxi(out.trees.get(k, 0), c.trees[k])
	return out


static func _deco(card: Dictionary) -> int:
	return Cards.DEW_POINTS if card.get("deco", &"") == &"dew" else 0


## 숲 세기: 나무 종별 그루, 이웃 종별·종류별·자리별 마리
static func _census(forest: Forest) -> Dictionary:
	var c := {trees = {}, species = {}, kinds = {}, sides = {}, syms = {}, full = 0, count = 0}
	for p in forest.trees:
		var k: StringName = forest.trees[p].kind
		if k != Forest.SAPLING:
			c.trees[k] = c.trees.get(k, 0) + 1
			c.count += 1
			c.syms[k] = c.syms.get(k, 0) + 1
		if forest.is_complete(p):
			c.full += 1
	c.kinds[&"tree"] = c.count
	for n in forest.neighbors():
		c.species[n.species] = c.species.get(n.species, 0) + 1
		for tag: StringName in Cards.tags_of(n.species):
			c.kinds[tag] = c.kinds.get(tag, 0) + 1
		c.sides[n.side] = c.sides.get(n.side, 0) + 1
		var sym := Cards.placed_sym(n.card, n.species)
		c.syms[sym] = c.syms.get(sym, 0) + 1
		# 어리호박벌: 붙은 나무가 그 종 한 그루 더로 셈
		if Cards.SPECIES[n.species].effect.get("boost", false) and forest.kind_at(n.plot) != Forest.SAPLING:
			c.trees[forest.kind_at(n.plot)] = c.trees.get(forest.kind_at(n.plot), 0) + 1
	return c


## 그 종류 이웃의 서로 다른 종 가짓수
static func _distinct(c: Dictionary, kind: StringName) -> int:
	var n := 0
	for s in c.species:
		if Cards.SPECIES[s].kind == kind:
			n += 1
	return n


static func _eval(r: Dictionary, what: StringName, same: Dictionary, plot: int, forest: Forest, c: Dictionary, season: int, once: Dictionary, sym: StringName = &"") -> int:
	if r.has("flat"):
		return r.flat
	if r.has("kind_set"):
		var kind: StringName = Cards.SPECIES[what].kind
		if once.has(kind):
			return 0
		once[kind] = true
		return r.kind_set[mini(_distinct(c, kind), r.kind_set.size() - 1)]
	if r.has("distinct_at_least"):
		return r.each if _distinct(c, Cards.SPECIES[what].kind) >= r.distinct_at_least else r.other
	if r.has("per_tree"):
		var n := 0
		for k in c.trees:
			n += c.trees[k]
		return n * r.per_tree
	if r.has("per_tree_kind"):
		return c.trees.get(r.per_tree_kind, 0) * r.pts
	if r.has("kinds_of_trees"):
		return c.trees.size() * r.kinds_of_trees
	if r.has("per_cave"):
		return forest.cave.size() * r.per_cave
	if r.has("per_here"):
		var n := 0
		for s in Forest.SIDES:
			n += forest.occupants(plot, s).size()
		return n * r.per_here
	if r.has("per_kind"):
		var tags: Array = r.per_kind if r.per_kind is Array else [r.per_kind]
		var n := 0
		for t in tags:
			n += c.kinds.get(t, 0)
		return n * r.pts
	if r.has("trees_at_least"):
		if not c.rivals.is_empty():
			return r.pts if c.count >= c.rivals.count else 0
		return r.pts if c.count >= r.trees_at_least else 0
	if r.has("with"):
		return r.pts if c.species.get(r.with, 0) > 0 else r.get("other", 0)
	if r.has("pair"):
		var mates := 0
		for s in Forest.SIDES:
			for o in forest.occupants(plot, s):
				if o.species == what:
					mates += 1
		return r.pair if mates >= 2 else 0
	if r.has("per_sym"):
		return c.syms.get(sym, 0) * r.per_sym
	if r.has("butterfly_sets"):
		if once.has(&"butterfly_sets"):
			return 0
		once[&"butterfly_sets"] = true
		var left := {}
		for sp in c.species:
			if &"butterfly" in Cards.tags_of(sp):
				left[sp] = c.species[sp]
		var total := 0
		while not left.is_empty():
			total += r.butterfly_sets[mini(left.size(), r.butterfly_sets.size() - 1)]
			for sp in left.keys():
				left[sp] -= 1
				if left[sp] <= 0:
					left.erase(sp)
		return total
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
	if r.has("most") and not c.rivals.is_empty():
		return r.most if same.get(what, 0) >= c.rivals.trees.get(what, 0) else r.other
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
