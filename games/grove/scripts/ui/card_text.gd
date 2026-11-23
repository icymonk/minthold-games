class_name CardText
extends RefCounted
## 카드 글: 비용·효과·보너스·점수 규칙(Cards의 데이터)을 사람이 읽는 말로 바꾼다.

const GIVES: Array[StringName] = [&"draw", &"pick", &"cave"]


static func def_of(kind: StringName) -> Dictionary:
	return Cards.TREES.get(kind, Cards.SPECIES.get(kind, {}))


static func name_of(kind: StringName) -> String:
	return _t("KIND_%s" % String(kind).to_upper())


static func group_of(group: StringName) -> String:
	return _t("GROUP_%s" % String(group).to_upper())


static func side_of(side: StringName) -> String:
	return _t("SIDE_%s" % String(side).to_upper())


## {draw = 1, pick = 1} → "덱에서 1장, 공터에서 1장" (short: "덱+1 공터+1")
static func gives(give: Dictionary, short := false) -> String:
	var parts: Array[String] = []
	for k in GIVES:
		if give.has(k):
			parts.append(_t("GIVE_%s%s" % [String(k).to_upper(), "_S" if short else ""]) % give[k])
	return (" " if short else ", ").join(parts)


static func hook(kind: StringName) -> String:
	var h: Dictionary = def_of(kind).get("hook", {})
	if h.is_empty():
		return ""
	if h.on == &"plant":
		return _t("HOOK_PLANT") % gives(h.give)
	return _t("HOOK_PLACE") % [side_of(h.side), gives(h.give)]


## 점수 규칙 한 줄
static func rule(kind: StringName) -> String:
	var d := def_of(kind)
	var r: Dictionary = d.get("score", {})
	if r.has("kind_set"):
		return _t("RULE_KIND_SET") % [group_of(d.kind), _table(r.kind_set)]
	if r.has("distinct_at_least"):
		return _t("RULE_DISTINCT_AT_LEAST") % [group_of(d.kind), r.distinct_at_least, r.each, r.get("other", 0)]
	if r.has("at_least"):
		return _t("RULE_AT_LEAST") % [r.at_least, r.each, r.get("other", 0)]
	if r.has("tree_kinds"):
		return _t("RULE_TREE_KINDS") % [r.tree_kinds, r.pts]
	if r.has("late"):
		return _t("RULE_LATE") % [r.late, r.early]
	if r.has("set"):
		return _t("RULE_SET") % _table(r.set)
	if r.has("spread"):
		return _t("RULE_SPREAD") % _table(r.spread)
	if r.has("most"):
		return _t("RULE_MOST") % [r.most, r.get("other", 0)]
	if r.has("same_tree"):
		return _t("RULE_SAME_TREE") % [group_of(r.same_tree), r.pts, r.get("other", 0)]
	if r.has("on"):
		return _t("RULE_ON") % [_names(r.on), r.pts, r.get("other", 0)]
	if r.has("per_kind"):
		return _t("RULE_PER") % [group_of(r.per_kind), r.pts]
	if r.has("per_species"):
		return _t("RULE_PER") % [name_of(r.per_species), r.pts]
	if r.has("per_tree_kind"):
		return _t("RULE_PER") % [name_of(r.per_tree_kind), r.pts]
	if r.has("per_side"):
		return _t("RULE_PER_SIDE") % [side_of(r.per_side), r.pts]
	if r.has("distinct_kind"):
		return _t("RULE_DISTINCT_KIND") % [group_of(r.distinct_kind), r.pts]
	if r.has("full"):
		return _t("RULE_FULL") % r.full
	if r.has("per_tree"):
		return _t("RULE_PER_TREE") % r.per_tree
	if r.has("kinds_of_trees"):
		return _t("RULE_KINDS_OF_TREES") % r.kinds_of_trees
	if r.has("per_cave"):
		return _t("RULE_PER_CAVE") % r.per_cave
	if r.has("per_here"):
		return _t("RULE_PER_HERE") % r.per_here
	return _t("RULE_FLAT") % r.get("flat", 0)


## 카드 위 작은 표시: [{text, tone}] tone = effect | bonus | hook
static func chips(kind: StringName) -> Array[Dictionary]:
	var d := def_of(kind)
	var out: Array[Dictionary] = []
	if not d.get("effect", {}).is_empty():
		out.append({text = gives(d.effect, true), tone = &"effect"})
	if not d.get("bonus", {}).is_empty():
		out.append({text = "★ " + gives(d.bonus, true), tone = &"bonus"})
	if d.has("hook"):
		out.append({text = "∞ " + gives(d.hook.give, true), tone = &"hook"})
	return out


static func _table(t: Array) -> String:
	var out: Array[String] = []
	for i in range(1, t.size()):
		out.append("%d→%d" % [i, t[i]])
	return " ".join(out)


static func _names(list: Array) -> String:
	var out: Array[String] = []
	for k in list:
		out.append(name_of(k))
	return "·".join(out)


static func _t(key: String) -> String:
	return TranslationServer.translate(key)
